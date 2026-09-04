# Ultimate Debian i3 Set Up
## About
This is an install script for the ultimate debian set up
## Features
- i3wm on X11/LightDM, with a dark TokyoNight GTK theme and Papirus-Dark
  icons forced system-wide (greeter, GTK2/3 apps, and Qt apps such as
  Wireshark)
- Agave Nerd Font, with Noto fallback fonts for broader Unicode coverage
- Essential CLI tools plus common security/networking tools (Wireshark,
  nmap, gobuster, hashcat, impacket, etc.)
- Latest neovim, Rust, Go, and Node.js installed from upstream
- `please` (aliases to `sudo`) and `ll` (aliases to `eza`) added to `~/.bashrc`
## Getting Started
### Prerequisites
You will need a base install of Debian 13
### Installation
1. Clone the repo
```sh
git clone https://github.com/shelldrake/i3SetUp.git
```
2. cd into the directory
```sh
cd dirname
```
3. Run the install script as your normal user (not root/sudo — the script
   calls `sudo` itself where needed)
```sh
bash install.sh
```

