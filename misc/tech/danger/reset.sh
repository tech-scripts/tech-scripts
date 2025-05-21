#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

whiptail --title "$TITLE_DANGER" --yesno "$MESSAGE_DANGER" 10 60

if [ $? -eq 0 ]; then
    show_inscription
    $SUDO rm -rf $BASIC_DIRECTORY
    hash -r
    echo ""
    complete_remove
    echo ""
else
    exit 0
fi
