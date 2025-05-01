#!/usr/bin/env bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

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
    GPU=$(lshw -C display 2>/dev/null | grep "product" | cut -d':' -f2 | sed 's/^ *//' || echo "$UNKNOWN_SYSTEM (lshw не установлено)")
    
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
$SHELL_SYSTEM: $SHELL $BASH_VERSION
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
    MESSAGE="$DISK_INFO"
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
            NETWORK_INFO+="$INTERFACE_SYSTEM: $interface\n"
            NETWORK_INFO+="$STATUS_SYSTEM: ${STATUS:-$UNKNOWN_SYSTEM}\n"
            [ -n "$IP" ] && NETWORK_INFO+="IP: $IP\n"
            [ -n "$MAC" ] && NETWORK_INFO+="MAC: $MAC\n"
            NETWORK_INFO+="\n"
        fi
    done
    
    if [ -z "$NETWORK_INFO" ]; then
        NETWORK_INFO="$NO_NETWORK_ADAPTERS_SYSTEM"
    fi
    
    if command -v curl &>/dev/null; then
        PUBLIC_IP=$(curl -s ifconfig.me)
        [ -n "$PUBLIC_IP" ] && NETWORK_INFO+="\n$PUBLIC_IP_SYSTEM: $PUBLIC_IP"
    fi
    
    whiptail --title "$NETWORK_INFO_SYSTEM" --scrolltext --msgbox "$NETWORK_INFO" 20 70
}

main_menu() {
    while true; do
        OPTION=$(whiptail --title "$MAIN_MENU_SYSTEM" --menu "$CHOOSE_OPTION_SYSTEM:" 15 60 5 \
            "1" "$SYSTEM_INFO_SYSTEM" \
            "2" "$TEMPERATURE_SYSTEM" \
            "3" "$DISK_INFO_SYSTEM" \
            "4" "$NETWORK_INFO_SYSTEM" 3>&1 1>&2 2>&3)
        
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
