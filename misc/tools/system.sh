#!/bin/bash

get_system_info() {
    if command -v lsb_release &>/dev/null; then
        OS=$(lsb_release -d | cut -f2)
    else
        OS=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
    fi

    KERNEL=$(uname -r)
    UPTIME=$(uptime -p)
    HOSTNAME=$(hostname)
    CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    MEMORY=$(free -h | grep "Mem:" | awk '{print $2}')
    DISK=$(df -h / | grep "/" | awk '{print $2}')
    IP=$(hostname -I | awk '{print $1}')

    if command -v sensors &>/dev/null; then
        TEMP_INFO=$(sensors | grep -E 'Core|Package|temp' | awk '{print $1 ": " $2}')
    else
        TEMP_INFO="Информация о температуре недоступна (установите lm-sensors)"
    fi

    MESSAGE="
Информация о системе:

ОС: $OS
Ядро: $KERNEL
Время работы: $UPTIME
Имя хоста: $HOSTNAME
Процессор: $CPU
Оперативная память: $MEMORY
Диск: $DISK
IP-адрес: $IP
Температура:
$TEMP_INFO
"

    whiptail --title "Информация о системе" --msgbox "$MESSAGE" 20 60
}

get_system_info
