#!/bin/bash

# Parameters default values
KEYBOARD="fr"
TIMEZONE="Europe/Paris"
wallpaper_path="/tmp/resources/wallpaper.jpg"

# Colors
RED="\033[01;31m"      # Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings
BLUE="\033[01;34m"     # Information
BOLD="\033[01;01m"     # Highlight
NORMAL="\033[00m"      # Normal



# Check parameters
if [[ -n "${TIMEZONE}" && ! -f "/usr/share/zoneinfo/${TIMEZONE}" ]]; then
    echo -e ' '${RED}'[!]'${NORMAL}" Timezone '${TIMEZONE}' is not supported" 1>&2
    exit 1
elif [[ -n "${KEYBOARD}" && -e /usr/share/X11/xkb/rules/xorg.lst ]]; then
    if ! $(grep -q " ${KEYBOARD} " /usr/share/X11/xkb/rules/xorg.lst); then
        echo -e ' '${RED}'[!]'${NORMAL}" Keyboard layout '${KEYBOARD}' is not supported"  1>&2
        exit 1
    fi
fi

echo -e "\n\n ${GREEN}[+]${NORMAL} Adding ${GREEN}Kali Linux${NORMAL} repositories"
echo "deb http://http.kali.org/kali kali-last-snapshot main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list

# Update and upgrade packages
echo -e "\n\n ${GREEN}[+]${NORMAL} Packages ${GREEN}update${NORMAL}"
sudo apt-get update
#echo -e "\n\n ${GREEN}[+]${NORMAL} Packages ${GREEN}upgrade${NORMAL}"
#sudo apt-get upgrade -y

sudo mkdir /vagrant

# Change keyboard layout
if [[ -n "${KEYBOARD}" ]]; then
    echo -e "\n\n ${GREEN}[+]${NORMAL} Updating ${GREEN}location information${NORMAL} ~ keyboard layout (${BOLD}${KEYBOARD}${NORMAL})"
    geoip_keyboard=$(curl -s http://ifconfig.io/country_code | tr '[:upper:]' '[:lower:]')
    [ "${geoip_keyboard}" != "${KEYBOARD}" ] \
        && echo -e " ${YELLOW}[i]${NORMAL} Keyboard layout (${BOLD}${KEYBOARD}${NORMAL}) doesn't match what's been detected via GeoIP (${BOLD}${geoip_keyboard}${NORMAL})"
    file=/etc/default/keyboard; #[ -e "${file}" ] && cp -n $file{,.bkup}
    sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="'${KEYBOARD}'"/' "${file}"
else
    echo -e "\n\n ${YELLOW}[i]${NORMAL} ${YELLOW}Skipping keyboard layout${NORMAL} (missing: '$0 ${BOLD}--keyboard <value>${NORMAL}')..." 1>&2
fi

# Change timezone
if [[ -n "${TIMEZONE}" ]]; then
    echo -e "\n\n ${GREEN}[+]${NORMAL} Updating ${GREEN}location information${NORMAL} ~ time zone (${BOLD}${TIMEZONE}${NORMAL})"
    echo "${TIMEZONE}" > /etc/timezone
    ln -sf "/usr/share/zoneinfo/$(cat /etc/timezone)" /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata
else
    echo -e "\n\n ${YELLOW}[i]${NORMAL} ${YELLOW}Skipping time zone${NORMAL} (missing: '$0 ${BOLD}--timezone <value>${NORMAL}')" 1>&2
fi

# Set Wallpaper
if [ -e "${wallpaper_path}" ]; then
  echo -e "\n\n ${GREEN}[+]${NORMAL} Changing ${GREEN}wallpaper${NORMAL} (${BOLD}${wallpaper_path}${NORMAL})"
  echo "later"
else
  echo -e "\n\n ${YELLOW}[i]${NORMAL} ${YELLOW}Skipping wallpaper change${NORMAL} (missing: '$0 ${BOLD}/tmp/resources/wallpaper.jpg${NORMAL}')" 1>&2
fi