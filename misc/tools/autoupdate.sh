#!/bin/bash

SUDO=$(command -v sudo || echo "")
LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANGUAGE" == "Русский" ]; then
    title="Обновление системы"
    question="Вы хотите запустить обновление системы?"
    updating="Обновление системы..."
    completed="Обновление завершено!"
    error="Пакетный менеджер не найден. Обновление отменено!"
else
    title="System Update"
    question="Do you want to start the system update?"
    updating="Updating the system..."
    completed="Update completed!"
    error="The package manager was not found. The update has been canceled!"
fi

if (whiptail --title "$title" --yesno "$question" 10 60); then
    echo " "
    echo "$updating"
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
        echo "$error"
        exit 1
    fi
    echo " "
    echo "$completed"
    echo " "
else
    echo ""
fi
