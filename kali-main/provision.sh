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

# Parameters default values
keyboard=""
timezone=""

# Set parameters
while [ $# -gt 0 ]; do
    case "$1" in
        --keyboard=*)
            keyboard="${1#*=}"
            ;;
        --timezone=*)
            timezone="${1#*=}"
            ;;
        *)
            echo -e "${RED}[!]${NORMAL} Invalid argument" 1>&2
            exit 1
    esac
    shift
done

# Check parameters
if [[ -n "${timezone}" && ! -f "/usr/share/zoneinfo/${timezone}" ]]; then
    echo -e ' '${RED}'[!]'${NORMAL}" Timezone '${timezone}' is not supported" 1>&2
    exit 1
elif [[ -n "${keyboard}" && -e /usr/share/X11/xkb/rules/xorg.lst ]]; then
    if ! $(grep -q " ${keyboard} " /usr/share/X11/xkb/rules/xorg.lst); then
        echo -e ' '${RED}'[!]'${NORMAL}" Keyboard layout '${keyboard}' is not supported"  1>&2
        exit 1
    fi
fi

echo -e "\n\n ${GREEN}[+]${NORMAL} Adding ${GREEN}Kali Linux${NORMAL} repositories"
echo "deb http://http.kali.org/kali kali-last-snapshot main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list

# Update and upgrade packages
echo -e "\n\n ${GREEN}[+]${NORMAL} Packages ${GREEN}update${NORMAL}"
sudo apt-get update
echo -e "\n\n ${GREEN}[+]${NORMAL} Packages ${GREEN}upgrade${NORMAL}"
sudo apt-get upgrade -y

# Change keyboard layout
if [[ -n "${keyboard}" ]]; then
    echo -e "\n\n ${GREEN}[+]${NORMAL} Updating ${GREEN}location information${NORMAL} ~ keyboard layout (${BOLD}${keyboard}${NORMAL})"
    geoip_keyboard=$(curl -s http://ifconfig.io/country_code | tr '[:upper:]' '[:lower:]')
    [ "${geoip_keyboard}" != "${keyboard}" ] \
        && echo -e " ${YELLOW}[i]${NORMAL} Keyboard layout (${BOLD}${keyboard}${NORMAL}) doesn't match what's been detected via GeoIP (${BOLD}${geoip_keyboard}${NORMAL})"
    file=/etc/default/keyboard; #[ -e "${file}" ] && cp -n $file{,.bkup}
    sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="'${keyboard}'"/' "${file}"
else
    echo -e "\n\n ${YELLOW}[i]${NORMAL} ${YELLOW}Skipping keyboard layout${NORMAL} (missing: '$0 ${BOLD}--keyboard <value>${NORMAL}')..." 1>&2
fi

# Change timezone
if [[ -n "${timezone}" ]]; then
    echo -e "\n\n ${GREEN}[+]${NORMAL} Updating ${GREEN}location information${NORMAL} ~ time zone (${BOLD}${timezone}${NORMAL})"
    echo "${timezone}" > /etc/timezone
    ln -sf "/usr/share/zoneinfo/$(cat /etc/timezone)" /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata
else
    echo -e "\n\n ${YELLOW}[i]${NORMAL} ${YELLOW}Skipping time zone${NORMAL} (missing: '$0 ${BOLD}--timezone <value>${NORMAL}')" 1>&2
fi


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
sudo reboot