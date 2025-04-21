#!/bin/bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

if (whiptail --title "$TITLE_AUTOUPDATE" --yesno "$QUESTION_AUTOUPDATE" 10 60); then
    echo " "
    echo "$UPDATING_AUTOUPDATE"
    echo " "
    if command -v apt &> /dev/null; then
        $SUDO apt update && \
        $SUDO apt full-upgrade -y && \
        $SUDO apt autoremove -y
    elif command -v yum &> /dev/null; then
        $SUDO yum update -y && \
        $SUDO yum clean all
    elif command -v dnf &> /dev/null; then
        $SUDO dnf upgrade -y && \
        $SUDO dnf autoremove -y
    elif command -v zypper &> /dev/null; then
        $SUDO zypper refresh && \
        $SUDO zypper update -y
    elif command -v pacman &> /dev/null; then
        $SUDO pacman -Syu --noconfirm && \
        $SUDO pacman -Rns $(pacman -Qdtq) --noconfirm
    elif command -v apk &> /dev/null; then
        $SUDO apk update && \
        $SUDO apk upgrade
    elif command -v brew &> /dev/null; then
        brew update && \
        brew upgrade
    else
        echo "$ERROR_AUTOUPDATE"
        exit 1
    fi
    echo " "
    echo "$COMPLETE_AUTOUPDATE"
    echo " "
else
    exit 0
fi
