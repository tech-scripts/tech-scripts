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
        else
            TEMP_INFO=$(echo "$TEMP_INFO" | sed \
                -e 's/Composite/Температура NVMe/' \
                -e 's/edge/Температура GPU/' \
                -e 's/Tctl/Температура процессора/')
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
    echo "=========================================="
    echo "Информация о безопасности:"

    UFW_STATUS=$(sudo ufw status 2>/dev/null || echo "UFW не установлен или не настроен.")
    echo "Статус брандмауэра (UFW):"
    echo "$UFW_STATUS"
    echo ""

    if command -v sestatus &>/dev/null; then
        SELINUX_STATUS=$(sestatus | grep "SELinux status")
    else
        SELINUX_STATUS="SELinux не установлен."
    fi
    echo "Статус SELinux:"
    echo "$SELINUX_STATUS"
    echo ""

    if command -v apparmor_status &>/dev/null; then
        APPARMOR_STATUS=$(apparmor_status)
    else
        APPARMOR_STATUS="AppArmor не установлен."
    fi
    echo "Статус AppArmor:"
    echo "$APPARMOR_STATUS"
    echo ""

    echo "Проверка обновлений безопасности:"
    if command -v apt &>/dev/null; then
        SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security)
        if [ -z "$SECURITY_UPDATES" ]; then
            echo "Нет доступных обновлений безопасности."
        else
            echo "Доступные обновления безопасности:"
            echo "$SECURITY_UPDATES"
        fi
    elif command -v yum &>/dev/null; then
        SECURITY_UPDATES=$(yum check-update --security)
        echo "$SECURITY_UPDATES"
    else
        echo "Не удалось проверить обновления безопасности."
    fi
    echo ""

    echo "Активные пользователи:"
    who
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
