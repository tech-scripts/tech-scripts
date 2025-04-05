#!/bin/bash

SUDO=$(command -v sudo)

if [ ! -d "/etc/tech-scripts" ]; then
    $SUDO mkdir -p /etc/tech-scripts
fi

if [ ! -f "/etc/tech-scripts/choose.conf" ]; then
    $SUDO touch /etc/tech-scripts/choose.conf
fi

LANGUAGE=$(dialog --title "Language Selection" --menu "Choose language:" 10 40 2 \
    1 "English" \
    2 "Русский" \
    3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    echo "Selection canceled!"
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
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo "lang: $lang" | $SUDO tee /etc/tech-scripts/choose.conf > /dev/null
