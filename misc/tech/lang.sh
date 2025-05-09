#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

SUDO=$(env | grep -qi TERMUX && echo "" || command -v sudo 2>/dev/null)

LANGUAGE=$(whiptail --title "Language Selection" --menu "" 12 40 2 \
    1 "English" \
    2 "Русский" \
    3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    exit 1
fi

case $LANGUAGE in
    1)
        lang="English"
        ;;
    2)
        lang="Русский"
        ;;
    *)
        exit 1
        ;;
esac

CONFIG_FILE="$USER_DIR/etc/tech-scripts/choose.conf"

[ -w "$CONFIG_FILE" ] && sed -i "1s/.*/lang: $lang/" "$CONFIG_FILE" || $SUDO sed -i "1s/.*/lang: $lang/" "$CONFIG_FILE"

if [ "$lang" = "Русский" ]; then
    echo " "
    echo "Язык установлен: $lang"
    echo " "
else
    echo " "
    echo "Language set to: $lang"
    echo " "
fi
