#!/usr/bin/env bash

# exit on error, unset var, or pipeline failure
set -euo pipefail

# colors (ANSI-C quoting embeds a real escape byte so these also work
# with plain `cat`, not just `echo -e`)
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
NC=$'\033[0m' # No Color

# step messages
step_msg() {
    echo -e "${GREEN}[*] $1${NC}"
}

# info messages
info_msg() {
    echo -e "${YELLOW}[i] $1${NC}"
}

# error messages
error_msg() {
    echo -e "${RED}[!] $1${NC}"
}

# append a line to a file (as root) if it isn't already there
add_line_once() {
    local file="$1"
    local line="$2"
    if ! sudo grep -qxF "$line" "$file" 2>/dev/null; then
        echo "$line" | sudo tee -a "$file" >/dev/null
    fi
}

# this script calls sudo itself where needed; running it as root breaks
# per-user installs (pipx, ~/.bashrc, etc. would target root's home instead)
if [ "$EUID" -eq 0 ]; then
    error_msg "Do not run this script as root or with sudo"
    info_msg "Run it as your normal user: bash $0"
    exit 1
fi

# get the CPU arch
step_msg "Getting CPU Arch..."
ARCH="$(uname -m)"
info_msg "CPU is $ARCH"

case "$ARCH" in
    x86_64)
        NVIM_ARCH="x86_64"
        GO_ARCH="amd64"
        NODE_ARCH="x64"
        ;;
    aarch64|arm64)
        NVIM_ARCH="arm64"
        GO_ARCH="arm64"
        NODE_ARCH="arm64"
        ;;
    *)
        error_msg "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# update package lists
step_msg "Updating package lists..."
sudo apt update -qq

# installing X11
step_msg "Installing X11 display server..."
sudo apt install -y -qq \
    xorg \
    xinit

# installing LightDM
step_msg "Installing LightDM display manager..."
sudo apt install -y -qq \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings

# installing i3wm
step_msg "Installing i3wm and wm tools..."
sudo apt install -y -qq \
    i3 \
    terminator \
    rofi \
    thunar \
    thunar-archive-plugin \
    thunar-media-tags-plugin \
    open-vm-tools-desktop \
    polybar \
    papirus-icon-theme \
    lxappearance \
    network-manager \
    network-manager-applet \
    pulseaudio \
    pavucontrol \
    qt5-gtk-platformtheme \
    qt6-gtk-platformtheme

# preseed wireshark's debconf question so it doesn't prompt to allow
# non-root packet capture; usermod -aG wireshark below grants the access
step_msg "Preseeding wireshark non-root capture answer..."
echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections

# installing essentials tools
step_msg "Installing essential tools..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y -qq \
    curl \
    wget \
    zip \
    unzip \
    7zip \
    tree \
    fzf \
    jq \
    btop \
    eza \
    bat \
    git \
    eog \
    mpv \
    evince \
    xclip \
    build-essential \
    chromium \
    wireshark \
    tcpdump \
    gdb \
    binutils \
    binwalk \
    xxd \
    pipx \
    openjdk-21-jdk \
    proxychains4 \
    nmap \
    socat \
    ffuf \
    hping3 \
    gobuster \
    dirb \
    hydra \
    hashcat \
    john \
    cewl

# Fixing Network Manager
step_msg "Fixing Network Manager config..."
sudo sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf

# installing agave nerd font
step_msg "Installing Agave Nerd Font..."
sudo unzip -o ./assets/font/Agave.zip -d /usr/share/fonts/truetype/Agave

# installing fallback fonts so Pango has coverage for glyphs Agave lacks
# (CJK, emoji, extended symbols) instead of rendering blank/tofu boxes
step_msg "Installing fallback fonts for broader Unicode coverage..."
sudo apt install -y -qq \
    fonts-noto-core \
    fonts-noto-color-emoji

sudo fc-cache -f

# installing TokyoNight GTK theme
step_msg "Installing TokyoNight GTK themes..."
sudo unzip -o ./assets/theme/TokyoNight.zip -d /usr/share/themes

# installing neovim
step_msg "Installing neovim..."
if ! NVIM_VERSION="$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" | grep -oP '"tag_name":\s*"\K[^"]+')" || [[ -z "$NVIM_VERSION" ]]; then
    error_msg "Failed to get latest neovim version"
    exit 1
fi
info_msg "Latest neovim version: $NVIM_VERSION"

sudo mkdir -p "/opt/nvim/${NVIM_VERSION}"
sudo curl -fLso "/opt/nvim/${NVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz" "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz"
sudo tar xf "/opt/nvim/${NVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz" -C "/opt/nvim/${NVIM_VERSION}"
sudo ln -sf "/opt/nvim/${NVIM_VERSION}/nvim-linux-${NVIM_ARCH}/bin/nvim" /usr/bin/vim

# installing impacket
step_msg "Installing impacket..."
pipx install impacket

# installing Burp Suite Community Edition (installer URL always resolves to latest release)
step_msg "Installing Burp Suite Community Edition..."
curl -fLso /tmp/burpsuite_community_linux.sh "https://portswigger.net/burp/releases/download?product=community&type=Linux"
chmod +x /tmp/burpsuite_community_linux.sh
sudo /tmp/burpsuite_community_linux.sh -q -dir /opt/burpsuite

# force Burp's dark theme via its documented config-overlay mechanism
# (--user-config-file layers this JSON on top of normal settings on every launch)
step_msg "Configuring Burp Suite to start in dark mode..."
cat << 'EOF' | sudo tee /opt/burpsuite/dark-theme.json >/dev/null
{
    "user_options": {
        "display": {
            "user_interface": {
                "look_and_feel": "Dark"
            }
        }
    }
}
EOF
sudo tee /usr/local/bin/burpsuite >/dev/null << 'EOF'
#!/usr/bin/env bash
exec /opt/burpsuite/BurpSuiteCommunity --user-config-file=/opt/burpsuite/dark-theme.json "$@"
EOF
sudo chmod +x /usr/local/bin/burpsuite

# installing Ghidra
step_msg "Installing Ghidra..."
if ! GHIDRA_URL="$(curl -fsSL "https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest" | grep -oP '"browser_download_url":\s*"\K[^"]+\.zip')" || [[ -z "$GHIDRA_URL" ]]; then
    error_msg "Failed to get latest Ghidra release"
    exit 1
fi
GHIDRA_VERSION="$(basename "$GHIDRA_URL" .zip)"
info_msg "Latest Ghidra version: $GHIDRA_VERSION"

curl -fLso /tmp/ghidra.zip "$GHIDRA_URL"
sudo mkdir -p /opt/ghidra
sudo unzip -qo /tmp/ghidra.zip -d /opt/ghidra
sudo ln -sf "/opt/ghidra/${GHIDRA_VERSION}/ghidraRun" /usr/local/bin/ghidra

# force Ghidra's built-in Flat Dark theme via its supported launch.properties
# VMARGS mechanism (sets the "Theme" system property, which Preferences reads
# before falling back to the saved per-user theme choice)
step_msg "Configuring Ghidra to start in dark mode..."
echo "VMARGS=-DTheme=Class:generic.theme.builtin.FlatDarkTheme" | sudo tee -a "/opt/ghidra/${GHIDRA_VERSION}/support/launch.properties" >/dev/null

# installing rust
step_msg "Installing Rust..."
curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default

# install go
step_msg "Installing Go..."
if ! GOLATEST="$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)" || [[ -z "$GOLATEST" ]]; then
    error_msg "Failed to get latest Go version"
    exit 1
fi
info_msg "Latest Go version: $GOLATEST"

curl -fLso /tmp/go.tar.gz "https://go.dev/dl/${GOLATEST}.linux-${GO_ARCH}.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -xzf /tmp/go.tar.gz -C /usr/local
add_line_once /etc/skel/.bashrc 'export PATH=$PATH:/usr/local/go/bin'
add_line_once /etc/skel/.bashrc 'alias please="sudo"'
add_line_once /etc/skel/.bashrc 'alias ll="eza --icons --git -la"'
add_line_once /etc/skel/.bashrc 'alias bat="batcat"'

# install node
step_msg "Installing Node.js..."
if ! NODE_VERSION="$(curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version')" || [[ -z "$NODE_VERSION" || "$NODE_VERSION" == "null" ]]; then
    error_msg "Failed to get latest Node.js LTS version"
    exit 1
fi
info_msg "Latest Node.js LTS version: $NODE_VERSION"

curl -fLso /tmp/node.tar.xz "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
sudo tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner

# adding wallpaper and user avatar
step_msg "Adding wallpaper and user avatar..."
sudo mkdir -p /usr/share/avatar
sudo cp ./assets/avatar.png /usr/share/avatar/
sudo chmod 644 /usr/share/avatar/avatar.png
sudo mkdir -p /usr/share/wallpapers
sudo cp ./assets/wallpaper.png /usr/share/wallpapers/wallpaper.png
sudo chmod 644 /usr/share/wallpapers/wallpaper.png

# copy dot files to skel
step_msg "Adding dot files to skel file..."
sudo mkdir -p /etc/skel/.config
sudo cp -r ./assets/config/* /etc/skel/.config
sudo cp ./assets/xsessionrc /etc/skel/.xsessionrc
sudo cp ./assets/gtkrc-2.0 /etc/skel/.gtkrc-2.0

# copy dot files to all existing users, adding them to wireshark and tcpdump
# group, and installing GEF (GDB Enhanced Features)
step_msg "Adding dot files to all users, adding users to wireshark and tcpdump group, and installing GEF..."
shopt -s nullglob
for user_home in /home/*/; do
    user_home="${user_home%/}"
    username="${user_home##*/}"
    getent passwd "$username" >/dev/null 2>&1 || continue
    dest="$user_home/.config"
    sudo mkdir -p "$dest"
    sudo cp -r /etc/skel/.config/* "$dest"
    sudo chown -R "$username:$(id -gn "$username")" "$dest"
    add_line_once "$user_home/.bashrc" 'export PATH=$PATH:/usr/local/go/bin'
    add_line_once "$user_home/.bashrc" 'alias please="sudo"'
    add_line_once "$user_home/.bashrc" 'alias ll="eza"'
    add_line_once "$user_home/.bashrc" 'alias bat="batcat"'
    sudo chown "$username:$(id -gn "$username")" "$user_home/.bashrc"
    sudo cp /etc/skel/.xsessionrc "$user_home/.xsessionrc"
    sudo chown "$username:$(id -gn "$username")" "$user_home/.xsessionrc"
    sudo cp /etc/skel/.gtkrc-2.0 "$user_home/.gtkrc-2.0"
    sudo chown "$username:$(id -gn "$username")" "$user_home/.gtkrc-2.0"
    sudo usermod -aG wireshark "$username"
    sudo usermod -aG tcpdump "$username"
    # GEF installs into this user's home (~/.gdbinit, ~/.gef-<version>.py),
    # so it must run as that user rather than root
    sudo -u "$username" -H bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
done
shopt -u nullglob

# adding lightDM greeter config
step_msg "Adding lightDM greeter config..."
sudo cp ./assets/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf

# enabling lightDM service
step_msg "Enabling lightDM service..."
sudo systemctl enable lightdm

# Final message
info_msg "Installation completed successfully!"
info_msg "You can now reboot your system and log in using LightDM greeter and i3wm"
info_msg "Use 'sudo reboot' to restart your system"

# Add instructions for post-installation setup
cat << EOF

${YELLOW}=== POST-INSTALLATION INSTRUCTIONS ===${NC}

1. Reboot your system:
   $ sudo reboot

2. At the LightDM login screen, select "i3" as your session type

3. A config file is already in place (mod key is Super/Windows key), so
   i3 will not prompt you to generate one on first login

4. Common i3 keyboard shortcuts:
   • ${YELLOW}\$mod+Enter${NC}: Open terminal
   • ${YELLOW}\$mod+space${NC}: Open application launcher (rofi)
   • ${YELLOW}\$mod+q${NC}: Close current window
   • ${YELLOW}\$mod+Shift+e${NC}: Exit i3
   • ${YELLOW}\$mod+Shift+r${NC}: Restart i3
   • ${YELLOW}\$mod+Shift+c${NC}: Reload i3 configuration
   • ${YELLOW}\$mod+numbers${NC}: Switch to workspace
   • ${YELLOW}\$mod+Shift+numbers${NC}: Move window to workspace

5. For additional configuration, edit ~/.config/i3/config

6. Security tools installed: wireshark and tcpdump can capture packets as
   a non-root user (no setup needed), Burp Suite Community Edition is
   available via the ${YELLOW}burpsuite${NC} command, Ghidra is available
   via the ${YELLOW}ghidra${NC} command, and ${YELLOW}gdb${NC} starts with
   GEF (GDB Enhanced Features) loaded automatically

7. Shell conveniences already in your ~/.bashrc:
   • ${YELLOW}ll${NC}   -> eza --icons --git -la
   • ${YELLOW}bat${NC}  -> batcat
   • ${YELLOW}please${NC} -> sudo

EOF
