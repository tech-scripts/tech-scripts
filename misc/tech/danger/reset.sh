#!/bin/bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

whiptail --title "$TITLE_DANGER" --yesno "$MESSAGE_DANGER" 10 60

if [ $? -eq 0 ]; then
    $SUDO rm -rf "$BASIC_DIRECTORY"
    echo ""
    echo "$DELETED $BASIC_DIRECTORY $SUDO"
    echo ""
else
    exit 0
fi
