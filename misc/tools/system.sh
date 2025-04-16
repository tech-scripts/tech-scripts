#!/bin/bash

show_system_info() {
    OS=$(lsb_release -d | cut -f2)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p)
    HOSTNAME=$(hostname)
    CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    MEMORY=$(free -h | grep "Mem:" | awk '{print $2}')
    DISK=$(df -h / | grep "/" | awk '{print $2}')
    IP=$(hostname -I | awk '{print $1}')

    echo "=========================================="
    echo "Информация о системе:"
    echo "ОС: $OS"
    echo "Ядро: $KERNEL"
    echo "Время работы: $UPTIME"
    echo "Имя хоста: $HOSTNAME"
    echo "Процессор: $CPU"
    echo "Оперативная память: $MEMORY"
    echo "Диск: $DISK"
    echo "IP-адрес: $IP"
    echo "=========================================="
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

    echo "=========================================="
    echo "Температура:"
    echo "$TEMP_INFO"
    echo "=========================================="
}

show_disk_info() {
    DISK_INFO=$(df -h)
    echo "=========================================="
    echo "Информация о дисках:"
    echo "$DISK_INFO"
    echo "=========================================="
}

show_security_info() {
    SECURITY_INFO=$(sudo ufw status 2>/dev/null || echo "UFW не установлен или не настроен.")
    echo "=========================================="
    echo "Информация о безопасности:"
    echo "$SECURITY_INFO"
    echo "=========================================="
}

main_menu() {
    while true; do
        echo "=========================================="
        echo "Главное меню:"
        echo "1. Информация о системе"
        echo "2. Температура"
        echo "3. Информация о дисках"
        echo "4. Безопасность"
        echo "5. Выход"
        echo "=========================================="
        read -p "Выберите опцию (1-5): " OPTION

        case $OPTION in
            1) show_system_info ;;
            2) show_temperature_info ;;
            3) show_disk_info ;;
            4) show_security_info ;;
            5) exit 0 ;;
            *) echo "Неверный выбор. Пожалуйста, попробуйте снова." ;;
        esac

        read -p "Нажмите Enter, чтобы продолжить..."
    done
}

main_menu
