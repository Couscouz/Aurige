#!/bin/bash

# Colors
RED="\033[01;31m"      # Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings
BLUE="\033[01;34m"     # Information
BOLD="\033[01;01m"     # Highlight
NORMAL="\033[00m"      # Normal

# Parameters default values
keyboard="fr"
timezone="Europe/Paris"

wallpaper_path="/tmp/resources/wallpaper.jpg"


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
#echo -e "\n\n ${GREEN}[+]${NORMAL} Packages ${GREEN}upgrade${NORMAL}"
#sudo apt-get upgrade -y

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

# Set Wallpaper
if [ -e "${wallpaper_path}" ]; then
  echo -e "\n\n ${GREEN}[+]${NORMAL} Changing ${GREEN}wallpaper${NORMAL} (${BOLD}${wallpaper_path}${NORMAL})"
  sudo ln -s ${wallpaper_path} /usr/share/desktop-base/kali-theme/login/background
else
  echo -e "\n\n ${YELLOW}[i]${NORMAL} ${YELLOW}Skipping wallpaper change${NORMAL} (missing: '$0 ${BOLD}/tmp/resources/wallpaper.jpg${NORMAL}')" 1>&2
fi