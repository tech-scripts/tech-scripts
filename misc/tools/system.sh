#!/bin/bash

show_system_info() {
    OS=$(lsb_release -d | cut -f2)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p)
    HOSTNAME=$(hostname)
    CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    MEMORY=$(free -h | grep "Mem:" | awk '{print $2}')
    IP=$(hostname -I | awk '{print $1}')
    MESSAGE="
ОС: $OS
Ядро: $KERNEL
Время работы: $UPTIME
Имя хоста: $HOSTNAME
Процессор: $CPU
Оперативная память: $MEMORY
IP-адрес: $IP
"
    whiptail --title "Информация о системе" --msgbox "$MESSAGE" 15 60
}

show_temperature_info() {
    if command -v sensors &>/dev/null; then
        TEMP_INFO=$(sensors | grep -E 'Composite|edge|Tctl' | awk '{print $1 ": " $2}')
        if [ -z "$TEMP_INFO" ]; then
            TEMP_INFO="Информация о температуре недоступна (датчики не обнаружены)"
        fi
    else
        TEMP_INFO="Информация о температуре недоступна (установите lm-sensors)"
    fi

    MESSAGE="
$TEMP_INFO
"
    whiptail --title "Температура" --msgbox "$MESSAGE" 15 60
}

show_disk_info() {
    DISK_INFO=$(df -h)
    MESSAGE="
$DISK_INFO
"
    whiptail --title "Информация о дисках" --msgbox "$MESSAGE" 20 60
}

show_security_info() {
    SECURITY_INFO=$(sudo ufw status 2>/dev/null || echo "UFW не установлен или не настроен.")
    MESSAGE="
$SECURITY_INFO
"

    whiptail --title "Безопасность" --msgbox "$MESSAGE" 20 60
}

main_menu() {
    while true; do
        OPTION=$(whiptail --title "Главное меню" --menu "Выберите опцию:" 15 60 4 \
            "1" "Система" \
            "2" "Температура" \
            "3" "Диски" \
            "4" "Безопасность" \
            "5" "Выход" 3>&1 1>&2 2>&3)

        case $OPTION in
            1) show_system_info ;;
            2) show_temperature_info ;;
            3) show_disk_info ;;
            4) show_security_info ;;
            5) exit 0 ;;
            *) whiptail --title "Ошибка" --msgbox "Неверный выбор. Пожалуйста, попробуйте снова." 8 45 ;;
        esac
    done
}

main_menu
