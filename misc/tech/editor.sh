#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$(pwd)

source $USER_DIR/etc/tech-scripts/source.sh

[ ! -d "$USER_DIR/etc/tech-scripts" ] && $SUDO mkdir -p $USER_DIR/etc/tech-scripts
[ ! -f "$USER_DIR/etc/tech-scripts/choose.conf" ] && $SUDO touch $USER_DIR/etc/tech-scripts/choose.conf

EDITOR=$(whiptail --title "$TITLE_EDITOR" --menu "" 12 40 3 \
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
        editor=$(whiptail --title "$TITLE_CUSTOM_EDITOR" --inputbox "$MSG_CUSTOM_EDITOR" 12 40 3>&1 1>&2 2>&3)
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

sed -i "3s/.*/editor: $editor/" $USER_DIR/etc/tech-scripts/choose.conf

echo " "
echo "$MSG_SUCCESS_EDITOR $editor"
echo " "
