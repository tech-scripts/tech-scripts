#!/bin/bash

SUDO=$(command -v sudo || echo "")

lang=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$lang" == "Русский" ]; then
    title="Обновление системы"
    question="Вы хотите запустить обновление системы?"
    updating="Обновление системы..."
    completed="Обновление завершено!"
    cancelled="Обновление отменено!"
else
    title="System Update"
    question="Do you want to start the system update?"
    updating="Updating the system..."
    completed="Update completed!"
    cancelled="Update cancelled!"
fi

if (whiptail --title "$title" --yesno "$question" 10 60); then
    echo " "
    echo "$updating"
    echo " "
    $SUDO apt update
    $SUDO apt full-upgrade -y
    $SUDO apt autoremove -y
    echo " "
    echo "$completed"
    echo " "
else
    echo " "
    echo "$cancelled"
    echo " "
fi
