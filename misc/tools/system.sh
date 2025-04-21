#!/bin/bash

LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANGUAGE" = "Русский" ]; then
    ERROR_SYSTEM="ОШИБКА"
    INSTALL_SYSTEM="УСТАНОВИТЕ lm-sensors:\nsudo apt install lm-sensors"
    SYSTEM_INFO_SYSTEM="ИНФОРМАЦИЯ О СИСТЕМЕ"
    DISK_INFO_SYSTEM="ИНФОРМАЦИЯ О ДИСКАХ"
    NETWORK_INFO_SYSTEM="ИНФОРМАЦИЯ О СЕТИ"
    TEMPERATURE_SYSTEM="ТЕМПЕРАТУРЫ (sensors)"
    HOST_SYSTEM="ХОСТ"
    KERNEL_SYSTEM="ЯДРО"
    UPTIME_SYSTEM="ВРЕМЯ РАБОТЫ"
    PACKAGES_SYSTEM="ПАКЕТЫ"
    SHELL_SYSTEM="ОБОЛОЧКА"
    RESOLUTION_SYSTEM="РАЗРЕШЕНИЕ"
    TERMINAL_SYSTEM="ТЕРМИНАЛ"
    CPU_SYSTEM="ПРОЦЕССОР"
    GPU_SYSTEM="ВИДЕОКАРТА"
    MEMORY_SYSTEM="ПАМЯТЬ"
    BATTERY_SYSTEM="БАТАРЕЯ"
    UNKNOWN_SYSTEM="НЕИЗВЕСТНО"
    UNAVAILABLE_SYSTEM="НЕДОСТУПНО"
else
    ERROR_SYSTEM="ERROR"
    INSTALL_SYSTEM="INSTALL lm-sensors:\nsudo apt install lm-sensors"
    SYSTEM_INFO_SYSTEM="SYSTEM INFORMATION"
    DISK_INFO_SYSTEM="DISK INFORMATION"
    NETWORK_INFO_SYSTEM="NETWORK INFORMATION"
    TEMPERATURE_SYSTEM="TEMPERATURES (sensors)"
    HOST_SYSTEM="HOST"
    KERNEL_SYSTEM="KERNEL"
    UPTIME_SYSTEM="UPTIME"
    PACKAGES_SYSTEM="PACKAGES"
    SHELL_SYSTEM="SHELL"
    RESOLUTION_SYSTEM="RESOLUTION"
    TERMINAL_SYSTEM="TERMINAL"
    CPU_SYSTEM="CPU"
    GPU_SYSTEM="GPU"
    MEMORY_SYSTEM="MEMORY"
    BATTERY_SYSTEM="BATTERY"
    UNKNOWN_SYSTEM="UNKNOWN"
    UNAVAILABLE_SYSTEM="UNAVAILABLE"
fi

show_temperature_info_SYSTEM() {
    if ! command -v sensors &>/dev/null; then
        whiptail --title "$ERROR_SYSTEM" --msgbox "$INSTALL_SYSTEM" 15 60
        return 1
    fi
    SENSORS_DATA=$(sensors)
    whiptail --title "$TEMPERATURE_SYSTEM" --scrolltext --msgbox "$SENSORS_DATA" 15 60
}

show_system_info_SYSTEM() {
    OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || echo "$UNAVAILABLE_SYSTEM")
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p | sed 's/up //')
    PACKAGES=$( (dpkg --list 2>/dev/null || rpm -qa 2>/dev/null) | wc -l)
    SHELL=$(basename "$SHELL")
    RESOLUTION=$(xrandr --current 2>/dev/null | grep '*' | awk '{print $1}')
    TERMINAL=$(basename "$(ps -o comm= -p "$(($(ps -o ppid= -p "$(($(ps -o sid= -p "$$")))")))")")
    CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^ *//')
    MEMORY=$(free -h | grep "Mem:" | awk '{print $3 "/" $2}')
    GPU=$(lspci | grep -i vga | cut -d':' -f3 | sed 's/^ *//' || echo "$UNKNOWN_SYSTEM (lspci не установлено)")
    
    BATTERY_INFO=""
    if [ -d /sys/class/power_supply ]; then
        for battery in /sys/class/power_supply/*; do
            if [ -e "$battery/capacity" ]; then
                capacity=$(cat "$battery/capacity")
                status=$(cat "$battery/status" 2>/dev/null || echo "$UNKNOWN_SYSTEM")
                BATTERY_INFO+="$BATTERY_SYSTEM $(basename $battery): $capacity% ($status)\n"
            fi
        done
    fi

    MESSAGE="
\"$USER@$HOSTNAME\"
------------
OS: $OS
$HOST_SYSTEM: $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "$UNAVAILABLE_SYSTEM")
$KERNEL_SYSTEM: $KERNEL
$UPTIME_SYSTEM: $UPTIME
$PACKAGES_SYSTEM: $PACKAGES
$SHELL_SYSTEM: $SHELL
$BASH_VERSION
"
    [ -n "$RESOLUTION_SYSTEM" ] && MESSAGE+="$RESOLUTION_SYSTEM: $RESOLUTION\n"
    MESSAGE+="$TERMINAL_SYSTEM: $TERMINAL\n"
    MESSAGE+="$CPU_SYSTEM: $CPU\n"
    MESSAGE+="$GPU_SYSTEM: $GPU\n"
    MESSAGE+="$MEMORY_SYSTEM: $MEMORY\n"
    [ -n "$BATTERY_INFO" ] && MESSAGE+="\n$BATTERY_INFO"
    MESSAGE=$(echo "$MESSAGE" | sed '/^[[:space:]]*$/d')
    whiptail --title "$SYSTEM_INFO_SYSTEM" --scrolltext --msgbox "$MESSAGE" 20 70
}

show_disk_info_SYSTEM() {
    DISK_INFO=$(df -h)
    MESSAGE="$DISK_INFO_SYSTEM:\n$DISK_INFO"
    whiptail --title "$DISK_INFO_SYSTEM" --scrolltext --msgbox "$MESSAGE" 20 70
}

show_network_info_SYSTEM() {
    NETWORK_INFO=""
    INTERFACES=$(ip -o link show | awk '{print $2}' | sed 's/://')
    
    for interface in $INTERFACES; do
        [ "$interface" = "lo" ] && continue
        
        IP=$(ip -o addr show dev "$interface" | awk '/inet / {print $4}' | cut -d'/' -f1 | tr '\n' ', ' | sed 's/, $//')
        MAC=$(ip -o link show dev "$interface" | awk '{print $17}')
        STATUS=$(cat /sys/class/net/$interface/operstate 2>/dev/null)
        
        if [ -n "$IP" ] || [ -n "$MAC" ]; then
            NETWORK_INFO+="Интерфейс: $interface\n"
            NETWORK_INFO+="Статус: ${STATUS:-$UNKNOWN_SYSTEM}\n"
            [ -n "$IP" ] && NETWORK_INFO+="IP: $IP\n"
            [ -n "$MAC" ] && NETWORK_INFO+="MAC: $MAC\n"
            NETWORK_INFO+="\n"
        fi
    done
    
    if [ -z "$NETWORK_INFO" ]; then
        NETWORK_INFO="Активные сетевые адаптеры не обнаружены"
    fi
    
    if command -v curl &>/dev/null; then
        PUBLIC_IP=$(curl -s ifconfig.me)
        [ -n "$PUBLIC_IP" ] && NETWORK_INFO+="\nПубличный IP: $PUBLIC_IP"
    fi
    
    whiptail --title "$NETWORK_INFO_SYSTEM" --scrolltext --msgbox "$NETWORK_INFO" 20 70
}

main_menu() {
    while true; do
        OPTION=$(whiptail --title "Главное меню" --menu "Выберите опцию:" 15 60 5 \
            "1" "$SYSTEM_INFO_SYSTEM" \
            "2" "$TEMPERATURE_SYSTEM" \
            "3" "$DISK_INFO_SYSTEM" \
            "4" "$NETWORK_INFO_SYSTEM" \
            "0" "Выход" 3>&1 1>&2 2>&3)
        
        case $OPTION in
            1) show_system_info_SYSTEM ;;
            2) show_temperature_info_SYSTEM ;;
            3) show_disk_info_SYSTEM ;;
            4) show_network_info_SYSTEM ;;
            *) exit 0 ;;
        esac
    done
}

main_menu
