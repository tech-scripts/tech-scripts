#!/bin/bash

show_temperature_info() {
    TEMP_INFO=""
    
    if command -v sensors &>/dev/null; then
        SENSORS_OUTPUT=$(sensors)
        
        # CPU Temperature (k10temp)
        CPU_TEMP=$(echo "$SENSORS_OUTPUT" | grep -A1 "k10temp" | grep "temp1" | awk '{print $2}' | tr -d '+°C')
        [ -n "$CPU_TEMP" ] && TEMP_INFO+="Температура CPU: ${CPU_TEMP}°C\n"
        
        # GPU Temperature (AMD)
        GPU_TEMP=$(echo "$SENSORS_OUTPUT" | grep -A1 "radeon" | grep "temp1" | awk '{printf "%.1f", $2}' | tr -d '+°C')
        if [ "$GPU_TEMP" != "N/A" ]; then
            [ -n "$GPU_TEMP" ] && TEMP_INFO+="Температура GPU: ${GPU_TEMP}°C\n"
        fi
        
        # System Temperature (acpitz)
        SYS_TEMP=$(echo "$SENSORS_OUTPUT" | grep -A1 "acpitz" | grep "temp1" | awk '{print $2}' | tr -d '+°C')
        [ -n "$SYS_TEMP" ] && TEMP_INFO+="Температура системы: ${SYS_TEMP}°C\n"
    fi
    
    # Alternative CPU temperature from thermal zones
    if [ -f /sys/class/thermal/thermal_zone*/temp ]; then
        for temp_file in /sys/class/thermal/thermal_zone*/temp; do
            temp=$(cat "$temp_file")
            temp=$((temp/1000))
            type=$(cat "${temp_file%/*}/type")
            if [[ "$type" == "x86_pkg_temp" || "$type" == "k10temp" ]]; then
                TEMP_INFO+="Температура CPU (ядро): ${temp}°C\n"
            fi
        done
    fi
    
    if [ -z "$TEMP_INFO" ]; then
        TEMP_INFO="Информация о температуре недоступна\nПопробуйте установить:\n- lm-sensors\n- nvidia-smi (для NVIDIA GPU)"
    fi
    
    whiptail --title "Температура" --scrolltext --msgbox "$TEMP_INFO" 20 70
}

show_system_info() {
    if [ -f /etc/os-release ]; then
        OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    else
        OS="Недоступно"
    fi
    
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p | sed 's/up //')
    PACKAGES=$( (dpkg --list 2>/dev/null || rpm -qa 2>/dev/null) | wc -l)
    SHELL=$(basename "$SHELL")
    RESOLUTION=$(xrandr --current 2>/dev/null | grep '*' | awk '{print $1}')
    TERMINAL=$(basename "$(ps -o comm= -p "$(($(ps -o ppid= -p "$(($(ps -o sid= -p "$$")))")))")")
    CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    MEMORY=$(free -h | grep "Mem:" | awk '{print $3 "/" $2}')
    GPU=$(lspci | grep -i vga | cut -d':' -f3 | xargs)
    
    BATTERY_INFO=""
    if [ -d /sys/class/power_supply ]; then
        for battery in /sys/class/power_supply/*; do
            if [ -e "$battery/capacity" ]; then
                capacity=$(cat "$battery/capacity")
                status=$(cat "$battery/status" 2>/dev/null || echo "Неизвестно")
                BATTERY_INFO+="Батарея $(basename $battery): $capacity% ($status)\n"
            fi
        done
    fi

    MESSAGE="
\"$USER@$HOSTNAME\"
------------
OS: $OS
Host: $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "Недоступно")
Kernel: $KERNEL
Uptime: $UPTIME
Packages: $PACKAGES
Shell: $SHELL $BASH_VERSION
"
    [ -n "$RESOLUTION" ] && MESSAGE+="Resolution: $RESOLUTION\n"
    MESSAGE+="Terminal: $TERMINAL\n"
    MESSAGE+="CPU: $CPU\n"
    MESSAGE+="GPU: $GPU\n"
    MESSAGE+="Memory: $MEMORY\n"
    [ -n "$BATTERY_INFO" ] && MESSAGE+="\n$BATTERY_INFO"
    MESSAGE=$(echo "$MESSAGE" | sed '/^[[:space:]]*$/d')
    whiptail --title "Информация о системе" --scrolltext --msgbox "$MESSAGE" 20 70
}

show_disk_info() {
    DISK_INFO=$(df -h)
    MESSAGE="
Информация о дисках:
$DISK_INFO
"
    whiptail --title "Информация о дисках" --scrolltext --msgbox "$MESSAGE" 20 70
}

show_network_info() {
    NETWORK_INFO=""
    INTERFACES=$(ip -o link show | awk '{print $2}' | sed 's/://')
    
    for interface in $INTERFACES; do
        [ "$interface" = "lo" ] && continue
        
        IP=$(ip -o addr show dev "$interface" | awk '/inet / {print $4}' | cut -d'/' -f1 | tr '\n' ', ' | sed 's/, $//')
        MAC=$(ip -o link show dev "$interface" | awk '{print $17}')
        SPEED=$(cat /sys/class/net/$interface/speed 2>/dev/null)
        STATUS=$(cat /sys/class/net/$interface/operstate 2>/dev/null)
        
        if [ -n "$IP" ] || [ -n "$MAC" ]; then
            NETWORK_INFO+="Интерфейс: $interface\n"
            NETWORK_INFO+="Статус: ${STATUS:-неизвестно}\n"
            [ -n "$SPEED" ] && NETWORK_INFO+="Скорость: ${SPEED}Mbps\n"
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
    
    whiptail --title "Сеть" --scrolltext --msgbox "$NETWORK_INFO" 20 70
}

show_security_info() {
    if [ -d /sys/firmware/efi ]; then
        UEFI_STATUS="UEFI включен"
    else
        UEFI_STATUS="UEFI отключен (используется Legacy BIOS)"
    fi
    
    if command -v tpm2_getcap &>/dev/null; then
        TPM_STATUS=$(tpm2_getcap properties-fixed 2>/dev/null | grep "TPM2_PT_FAMILY_INDICATOR" | awk '{print $2}')
        if [ "$TPM_STATUS" = "TPM2" ]; then
            TPM_STATUS="TPM 2.0 доступен"
        else
            TPM_STATUS="TPM 2.0 недоступен"
        fi
    else
        TPM_STATUS="TPM 2.0 недоступен (установите tpm2-tools)"
    fi
    
    if command -v ufw &>/dev/null; then
        UFW_STATUS=$(sudo ufw status | grep -v 'Status: inactive')
        [ -z "$UFW_STATUS" ] && UFW_STATUS="UFW неактивен" || UFW_STATUS="UFW активен"
    elif command -v firewall-cmd &>/dev/null; then
        UFW_STATUS=$(sudo firewall-cmd --state 2>/dev/null || echo "FirewallD неактивен")
    else
        UFW_STATUS="Брандмауэр не обнаружен"
    fi
    
    if command -v sestatus &>/dev/null; then
        SELINUX_STATUS=$(sestatus | grep "SELinux status" | cut -d':' -f2 | xargs)
    else
        SELINUX_STATUS="SELinux не установлен"
    fi
    
    if command -v apparmor_status &>/dev/null; then
        APPARMOR_STATUS=$(apparmor_status | grep -E 'profiles|processes')
        if echo "$APPARMOR_STATUS" | grep -q "0 profiles are loaded"; then
            APPARMOR_STATUS="AppArmor неактивен"
        else
            APPARMOR_STATUS="AppArmor активен"
        fi
    else
        APPARMOR_STATUS="AppArmor не установлен"
    fi
    
    if command -v clamscan &>/dev/null; then
        ANTIVIRUS_STATUS="ClamAV установлен"
    elif command -v sophos &>/dev/null; then
        ANTIVIRUS_STATUS="Sophos установлен"
    else
        ANTIVIRUS_STATUS="Антивирус не обнаружен"
    fi
    
    if lsblk -o NAME,FSTYPE | grep -q "crypt"; then
        DISK_ENCRYPTION="Шифрование дисков включено"
    else
        DISK_ENCRYPTION="Шифрование дисков отключено"
    fi
    
    MESSAGE="
Статус UEFI:               $UEFI_STATUS
Статус TPM 2.0:            $TPM_STATUS
Статус брандмауэра:        $UFW_STATUS
Статус SELinux:            $SELINUX_STATUS
Статус AppArmor:           $APPARMOR_STATUS
Статус антивируса:         $ANTIVIRUS_STATUS
Статус шифрования дисков:  $DISK_ENCRYPTION
"
    whiptail --title "Информация о безопасности" --scrolltext --msgbox "$MESSAGE" 20 70
}

main_menu() {
    while true; do
        OPTION=$(whiptail --title "Главное меню" --menu "Выберите опцию:" 15 60 5 \
            "1" "Информация о системе" \
            "2" "Температура" \
            "3" "Информация о дисках" \
            "4" "Сеть" \
            "5" "Безопасность" \
            "0" "Выход" 3>&1 1>&2 2>&3)
        
        case $OPTION in
            1) show_system_info ;;
            2) show_temperature_info ;;
            3) show_disk_info ;;
            4) show_network_info ;;
            5) show_security_info ;;
            *) exit 0 ;;
        esac
    done
}

main_menu
