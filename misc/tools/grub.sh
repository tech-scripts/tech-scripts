#!/bin/bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

is_number() {
    [[ $1 =~ ^[0-9]+$ ]]
}

while true; do
    delay=$(whiptail --inputbox "$ERROR_MSG_NUMBER_GRUB" 0 0 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && exit 1
    if is_number "$delay"; then
        if whiptail --yesno "$(printf "$CONFIRM_PROMPT_GRUB" "$delay")" 7 40; then
            break
        fi
    else
        whiptail --msgbox "$ERROR_MSG_GRUB" 7 40
    fi
done

$SUDO sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$delay/" /etc/default/grub
$SUDO update-grub
echo "$(printf "$SUCCESS_MSG_GRUB" "$delay")"
