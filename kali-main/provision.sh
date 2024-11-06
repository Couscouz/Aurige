#!/bin/bash

source ../.conf


# Check if run as root
if [ "$EUID" -ne 0 ]
    then echo -e "${RED}[!]${NORMAL} Please run as root"
    exit 1
fi
    echo -e " ${BLUE}[*]${RESET} ${BOLD}Starting Kali Linux setup script...${RESET}"
    sleep 2s

# Installing essentials packages
echo -e "\n\n ${GREEN}[+]${NORMAL} Installing ${GREEN}tools${NORMAL}"
sudo apt-get -y install wget gpg python3-pip bpython terminator seclists gobuster


# Install VS Code
echo -e "\n\n ${GREEN}[+]${NORMAL} Installing ${GREEN}Visual Studio Code${NORMAL}"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg

# Unzipping Rockyou
echo -e "\n\n ${GREEN}[+]${NORMAL} Unzipping ${GREEN}rockyou${NORMAL}"
sudo gunzip /usr/share/wordlists/rockyou.txt.gz

# Apply changes
echo -e "\n\n ${GREEN}[+]${NORMAL} ${GREEN}Rebooting${NORMAL}"
sudo reboot