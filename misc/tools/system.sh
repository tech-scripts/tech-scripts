#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

show_temperature_info() {
    if ! command -v sensors &>/dev/null; then
        whiptail --title "$ERROR" --msgbox "$INSTALL" 15 60
        return 1
    fi
    SENSORS_DATA=$(sensors)
    whiptail --title "$TEMPERATURE" --scrolltext --msgbox "$SENSORS_DATA" 15 60
}

show_system_info() {
    OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || echo "$UNAVAILABLE")
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p | sed 's/up //')
    PACKAGES=$(command -v dpkg &>/dev/null && dpkg --list 2>/dev/null | wc -l || command -v rpm &>/dev/null && rpm -qa 2>/dev/null | wc -l || command -v pacman &>/dev/null && pacman -Q 2>/dev/null | wc -l || command -v apk &>/dev/null && apk info | wc -l || command -v yum &>/dev/null && yum list installed 2>/dev/null | wc -l || command -v dnf &>/dev/null && dnf list installed 2>/dev/null | wc -l || command -v zypper &>/dev/null && zypper se --installed-only 2>/dev/null | wc -l || command -v brew &>/dev/null && brew list --versions | wc -l || command -v flatpak &>/dev/null && flatpak list | wc -l || command -v snap &>/dev/null && snap list | wc -l || echo 0)
    SHELL=$(basename "$SHELL")
    RESOLUTION=$(xrandr --current 2>/dev/null | grep '*' | awk '{print $1}')
    TERMINAL=$(basename "$(ps -o comm= -p "$(($(ps -o ppid= -p "$(($(ps -o sid= -p "$$")))")))")")
    CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^ *//')
    MEMORY=$(free -h | grep "Mem:" | awk '{print $3 "/" $2}')
    GPU=$(lshw -C display 2>/dev/null | grep "product" | cut -d':' -f2 | sed 's/^ *//' || echo "$UNKNOWN (lshw не установлено)")
    
    BATTERY_INFO=""
    if [ -d /sys/class/power_supply ]; then
        for battery in /sys/class/power_supply/*; do
            if [ -e "$battery/capacity" ]; then
                capacity=$(cat "$battery/capacity")
                status=$(cat "$battery/status" 2>/dev/null || echo "$UNKNOWN")
                BATTERY_INFO+="$BATTERY $(basename $battery): $capacity% ($status)\n"
            fi
        done
    fi

    MESSAGE="
\"$USER@$HOSTNAME\"
------------
OS: $OS
$HOST: $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "$UNAVAILABLE")
$KERNEL: $KERNEL
$UPTIME: $UPTIME
$PACKAGES: $PACKAGES
$SHELL: $SHELL $BASH_VERSION
"
    [ -n "$RESOLUTION" ] && MESSAGE+="$RESOLUTION: $RESOLUTION\n"
    MESSAGE+="$TERMINAL: $TERMINAL\n"
    MESSAGE+="$CPU: $CPU\n"
    MESSAGE+="$GPU: $GPU\n"
    MESSAGE+="$MEMORY: $MEMORY\n"
    [ -n "$BATTERY_INFO" ] && MESSAGE+="\n$BATTERY_INFO"
    MESSAGE=$(echo "$MESSAGE" | sed '/^[[:space:]]*$/d')
    whiptail --title "$SYSTEM_INFO" --scrolltext --msgbox "$MESSAGE" 20 70
}

show_disk_info() {
    DISK_INFO=$(df -h)
    MESSAGE="$DISK_INFO"
    whiptail --title "$DISK_INFO" --scrolltext --msgbox "$MESSAGE" 20 70
}

show_network_info() {
    NETWORK_INFO=""
    INTERFACES=$(ip -o link show | awk '{print $2}' | sed 's/://')
    
    for interface in $INTERFACES; do
        [ "$interface" = "lo" ] && continue
        
        IP=$(ip -o addr show dev "$interface" | awk '/inet / {print $4}' | cut -d'/' -f1 | tr '\n' ', ' | sed 's/, $//')
        MAC=$(ip -o link show dev "$interface" | awk '{print $17}')
        STATUS=$(cat /sys/class/net/$interface/operstate 2>/dev/null)
        
        if [ -n "$IP" ] || [ -n "$MAC" ]; then
            NETWORK_INFO+="$INTERFACE: $interface\n"
            NETWORK_INFO+="$STATUS: ${STATUS:-$UNKNOWN}\n"
            [ -n "$IP" ] && NETWORK_INFO+="IP: $IP\n"
            [ -n "$MAC" ] && NETWORK_INFO+="MAC: $MAC\n"
            NETWORK_INFO+="\n"
        fi
    done
    
    if [ -z "$NETWORK_INFO" ]; then
        NETWORK_INFO="$NO_NETWORK_ADAPTERS"
    fi
    
    if command -v curl &>/dev/null; then
        PUBLIC_IP=$(curl -s ifconfig.me)
        [ -n "$PUBLIC_IP" ] && NETWORK_INFO+="\n$PUBLIC_IP: $PUBLIC_IP"
    fi
    
    whiptail --title "$NETWORK_INFO" --scrolltext --msgbox "$NETWORK_INFO" 20 70
}

main_menu() {
    while true; do
        OPTION=$(whiptail --title "$MAIN_MENU" --menu "$CHOOSE_OPTION_SYSTEM:" 15 60 5 \
            "1" "$SYSTEM_INFO_SYSTEM" \
            "2" "$TEMPERATURE_SYSTEM" \
            "3" "$DISK_INFO_SYSTEM" \
            "4" "$NETWORK_INFO_SYSTEM" 3>&1 1>&2 2>&3)
        
        case $OPTION in
            1) show_system_info ;;
            2) show_temperature_info ;;
            3) show_disk_info ;;
            4) show_network_info ;;
            *) exit 0 ;;
        esac
    done
}

main_menu
