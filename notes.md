
reference script
```bash
#!/bin/bash

# Debian i3wm and Greeter Installation Script
# This script installs i3 window manager and lightdm greeter on a fresh Debian system

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function for step messages
step_msg() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function for info messages
info_msg() {
    echo -e "${YELLOW}[i] $1${NC}"
}

# Function for error messages
error_msg() {
    echo -e "${RED}[!] $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error_msg "This script must be run as root"
    info_msg "Try: sudo bash $0"
    exit 1
fi

# Update package lists
step_msg "Updating package lists..."
apt update

# Install essential packages
step_msg "Installing essential packages..."
apt install -y \
    xorg \
    xinit \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings

# Install i3wm and related packages
step_msg "Installing i3 window manager and related tools..."
apt install -y \
    i3 \
    i3status \
    i3lock \
    dunst \
    suckless-tools \
    rofi \
    feh \
    compton \
    arandr \
    lxappearance \
    thunar \
    thunar-archive-plugin \
    thunar-media-tags-plugin \
    thunar-volman \
    policykit-1-gnome \
    network-manager \
    network-manager-gnome \
    pulseaudio \
    pavucontrol \
    xbacklight \
    rxvt-unicode \
    alacritty \
    scrot \
    fonts-font-awesome \
    fonts-noto \
    fonts-liberation

# Install common tools and applications

