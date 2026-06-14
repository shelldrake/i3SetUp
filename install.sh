#!/usr/bin/env bash

# exit on error
set -e

# colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# check if running as root
if [ "$EUID" -ne 0 ]; then
    error_msg "This script must be run as root"
    info_msg "Try: sudo bash $0"
    exit 1
fi

# update package lists
step_msg "Updating package lists..."
apt update -qq

# installing X11
step_msg "Installing X11 display server..."
apt install -y -qq \
    xorg \
    xinit

# installing LightDM
step_msg "Installing LightDM display manager..."
apt install -y -qq \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings

# installing i3wm
step_msg "Installing i3wm and wm tools..."
apt install -y -qq \
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
    pavucontrol

# installing essentials tools
step_msg "Installing essential tools..."
apt install -y -qq \
    curl \
    wget \
    zip \
    unzip \
    7zip \
    tree \
    fzf \
    btop \
    git \
    eog \
    mpv \
    evince \
    xclip \
    build-essential \
    chromium


# Fixing Network Manager
step_msg "Fixing Network Manager config..."
sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf

# installing agave nerd font
step_msg "Installing Agave Nerd Font..."
unzip ./assets/font/Agave.zip -d /usr/share/fonts/truetype/Agave
fc-cache

# installing TokyoNight GTK theme
step_msg "Installing TokyoNight GTK themes..."
unzip ./assets/theme/TokyoNight.zip -d /usr/share/themes

# installing wireshark
step_msg "Installing wireshark and adding user to group..."
apt install -y wireshark
usermod -aG wireshark $USER

# installing tcpdump
step_msg "Installing tcpdump and adding user to group..."
apt install -y tcpdump
usermod -aG tcpdump $USER

# installing neovim
step_msg "Installing neovim v0.12.2..."
mkdir -p /opt/nvim/0.12.2
curl -Lso /opt/nvim/0.12.2/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/download/v0.12.2/nvim-linux-x86_64.tar.gz
tar xf /opt/nvim/0.12.2/nvim-linux-x86_64.tar.gz -C /opt/nvim/0.12.2
ln -s /opt/nvim/0.12.2/bin/nvim /usr/bin/vim

# adding wallpaper and user avatar
step_msg "Adding wallpaper and user avatar..."
mkdir -p /usr/share/avatar
cp ./assets/avatar.png /usr/share/avatar/
chmod 644 /usr/share/avatar/avatar.png
cp ./assets/wallpaper.png /usr/share/wallpapers/wallpaper.png
chmod 644 /usr/share/wallpapers/wallpaper.png

# copy dot files to skel and user profiles
step_msg "Adding dot files to user home and skel file..."
mkdir -p $HOME/.config
cp -r ./assets/config/* $HOME/.config
mkdir -p /etc/skel/.config
cp -r ./assets/config/* /etc/skel/.config

# adding lightDM greeter config
step_msg "Adding lightDM greeter config..."
cp ./assets/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf

# enabling lightDM service
step_msg "Enabling lightDM service..."
systemctl enable lightdm

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

3. First time you log in to i3, you'll be asked to generate a config file
   Select "Yes" and choose your mod key (Alt or Super/Windows key)

4. Common i3 keyboard shortcuts:
   • ${YELLOW}$mod+Enter${NC}: Open terminal
   • ${YELLOW}$mod+space${NC}: Open application launcher (rofi)
   • ${YELLOW}$mod+q${NC}: Close current window
   • ${YELLOW}$mod+Shift+e${NC}: Exit i3
   • ${YELLOW}$mod+Shift+r${NC}: Restart i3
   • ${YELLOW}$mod+Shift+c${NC}: Reload i3 configuration
   • ${YELLOW}$mod+numbers${NC}: Switch to workspace
   • ${YELLOW}$mod+Shift+numbers${NC}: Move window to workspace

5. For additional configuration, edit ~/.config/i3/config

EOF
