#!/bin/bash

# Colors
RED="\033[01;31m"      # Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings
BLUE="\033[01;34m"     # Information
BOLD="\033[01;01m"     # Highlight
NORMAL="\033[00m"      # Normal


# Check if run as root
if [ "$EUID" -ne 0 ]
    then echo -e "${RED}[!]${NORMAL} Please run as root"
    exit 1
fi
    echo -e " ${BLUE}[*]${RESET} ${BOLD}Starting Kali Linux setup script...${RESET}"
    sleep 2s

# Installing essentials packages
echo -e "\n\n ${GREEN}[+]${NORMAL} Installing ${GREEN}tools${NORMAL}"
sudo apt-get -y install wget gpg python3-pip linux-headers-generic terminator 

echo -e "\n\n ${GREEN}[+]${NORMAL} Installing ${GREEN}VMWare Tools${NORMAL}"
sudo apt-get -y install open-vm-tools-desktop

# Web
sudo apt-get -y install gobuster seclists

# Reverse/Pwn
sudo apt-get -y install imhex rizin-cutter apktool ghidra python3-pwntools bpython gdb radare2
bash -c "$(curl -fsSL https://gef.blah.cat/sh)" #gef

# Stego
sudo apt-get -y install steghide stegcracker audacity

# Install VS Code
echo -e "\n\n ${GREEN}[+]${NORMAL} Installing ${GREEN}Visual Studio Code${NORMAL}"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg


# NetworkMiner
echo -e "\n\n ${GREEN}[+]${NORMAL} Installing ${GREEN}NetworkMiner${NORMAL}"
sudo apt-get -y install mono-devel
wget https://www.netresec.com/?download=NetworkMiner -O /tmp/NetworkMiner.zip
sudo unzip /tmp/NetworkMiner.zip -d /opt/
cd /opt/NetworkMiner*
sudo chmod +x NetworkMiner.exe
sudo chmod -R go+w AssembledFiles/
sudo chmod -R go+w Captures/


# Unzipping Rockyou
echo -e "\n\n ${GREEN}[+]${NORMAL} Unzipping ${GREEN}rockyou.txt.gz${NORMAL}"
sudo gunzip /usr/share/wordlists/rockyou.txt.gz

# Getting linpeas
echo -e "\n\n ${GREEN}[+]${NORMAL} Downloading ${GREEN}linpeas.sh${NORMAL}"
wget https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -O /vagrant/linpeas.sh

# Apply changes
echo -e "\n\n ${GREEN}[+]${NORMAL} ${GREEN}Rebooting${NORMAL}"
sudo reboot