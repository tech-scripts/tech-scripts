#!/bin/bash

SUDO=$(command -v sudo || echo "")
LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANGUAGE" == "Русский" ]; then
    TITLE_AUTOUPDATE="Обновление системы"
    QUESTION_AUTOUPDATE="Вы хотите запустить обновление системы?"
    UPDATING_AUTOUPDATE="Обновление системы..."
    COMPLETE_AUTOUPDATE="Обновление завершено!"
    ERROR_AUTOUPDATE="Пакетный менеджер не найден. Обновление отменено!"
else
    TITLE_AUTOUPDATE="System Update"
    QUESTION_AUTOUPDATE="Do you want to start the system update?"
    UPDATING_AUTOUPDATE="Updating the system..."
    COMPLETE_AUTOUPDATE="Update completed!"
    ERROR_AUTOUPDATE="The package manager was not found. The update has been canceled!"
fi

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
    echo ""
fi
