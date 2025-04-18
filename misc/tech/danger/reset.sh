#!/bin/bash

SUDO=$(command -v sudo)

source /tmp/tech-scripts/misc/localization.sh 

whiptail --title "$TITLE_DANGER" --yesno "$MESSAGE_DANGER" --yes-button "$YES" --no-button "$NO" 10 60

if [ $? -eq 0 ]; then
    echo "$DELETING"
    $SUDO rm -rf /tmp/tech-scripts /etc/tech-scripts /usr/local/tech-scripts /usr/local/bin/tech
    echo "$DELETED"
else
    exit 0
fi
