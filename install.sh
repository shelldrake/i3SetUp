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
    info_msg "Try: sudo $0"
    exit 1
fi

# update package lists
step_msg "Updating package lists..."
apt update



