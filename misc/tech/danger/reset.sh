#!/usr/bin/env bash

[ -n "$PREFIX" ] && USER_DIR="$PREFIX" || USER_DIR=""

source $USER_DIR/opt/tech-scripts/source.sh

whiptail --title "$TITLE_DANGER" --yesno "$MESSAGE_DANGER" 10 60

if [ $? -eq 0 ]; then
    show_inscription
    $SUDO rm -rf $BASIC_DIRECTORY
    hash -d tech &>/dev/null
    echo ""
    complete_remove
    echo ""
else
    exit 0
fi
