#!/bin/bash

source /tmp/tech-scripts/misc/localization.sh
source /tmp/tech-scripts/misc/variables.sh

[ ! -d "/etc/tech-scripts" ] && $SUDO mkdir -p /etc/tech-scripts
[ ! -f "/etc/tech-scripts/choose.conf" ] && $SUDO touch /etc/tech-scripts/choose.conf

EDITOR=$(whiptail --title "$TITLE_EDITOR" --menu "$MSG_EDITOR" 12 40 3 \
    1 "nano" \
    2 "vim" \
    3 "Custom" \
    3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    exit 1
fi

case $EDITOR in
    1) editor="nano" ;;
    2) editor="vim" ;;
    3)
        editor=$(whiptail --title "$TITLE_CUSTOM_EDITOR" --inputbox "$MSG_CUSTOM_EDITOR" 10 40 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            exit 1
        fi
        ;;
    *) 
        echo " "
        echo "$MSG_INVALID_EDITOR"
        echo " "
        exit 1
        ;;
esac

if ! grep -q '^lang:' /etc/tech-scripts/choose.conf; then
    echo "lang: English" | $SUDO tee /etc/tech-scripts/choose.conf > /dev/null
fi

if grep -q '^editor:' /etc/tech-scripts/choose.conf; then
    $SUDO sed -i "s/^editor:.*/editor: $editor/" /etc/tech-scripts/choose.conf
else
    $SUDO sed -i "1a editor: $editor" /etc/tech-scripts/choose.conf
fi

echo " "
echo "$MSG_SUCCESS_EDITOR $editor"
echo " "
