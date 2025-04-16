#!/bin/bash

get_system_info() {
    OS=$(lsb_release -d | cut -f2)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p)
    HOSTNAME=$(hostname)
    CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    MEMORY=$(free -h | grep "Mem:" | awk '{print $2}')
    DISK=$(df -h / | grep "/" | awk '{print $2}')
    IP=$(hostname -I | awk '{print $1}')

    TEMP_INFO=$(sensors | grep -E 'Core|Package|temp' | awk '{print $1 ": " $2}')
    
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
