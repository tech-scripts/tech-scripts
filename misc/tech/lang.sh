#!/usr/bin/env bash

SUDO=$(command -v sudo)

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

sed -i "1s/.*/lang: $lang/" /etc/tech-scripts/choose.conf

if [ "$lang" = "Русский" ]; then
    echo " "
    echo "Язык установлен: $lang"
    echo " "
else
    echo " "
    echo "Language set to: $lang"
    echo " "
fi
