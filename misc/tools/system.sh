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

    MESSAGE="
ОС:                     $OS
Ядро:                   $KERNEL
Время работы:           $UPTIME
Имя хоста:              $HOSTNAME
Процессор:              $CPU
Оперативная память:     $MEMORY
Диск:                   $DISK
IP-адрес:               $IP
"

    whiptail --title "Информация о системе" --scrolltext --msgbox "$MESSAGE" 15 60
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

    MESSAGE="
$TEMP_INFO
"

    whiptail --title "Температура" --scrolltext --msgbox "$MESSAGE" 15 60
}

show_disk_info() {
    DISK_INFO=$(df -h)
    MESSAGE="
Информация о дисках:

$DISK_INFO
"

    whiptail --title "Информация о дисках" --scrolltext --msgbox "$MESSAGE" 15 60
}

show_network_info() {
    NETWORK_INFO=$(ip -o addr show | awk '{print $2, $4}' | while read -r interface ip; do
        MAC=$(ip -o link show dev "$interface" | awk '{print $17}')
        echo "Интерфейс: $interface"
        echo "IP: $ip"
        if [ -n "$MAC" ]; then
            echo "MAC: $MAC"
        fi
        echo ""
    done)

    if [ -z "$NETWORK_INFO" ]; then
        NETWORK_INFO="Информация о сетевых адаптерах недоступна."
    fi

    MESSAGE="
Информация о сетевых адаптерах:

$NETWORK_INFO
"

    whiptail --title "Сеть" --scrolltext --msgbox "$MESSAGE" 15 60
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

    UFW_STATUS=$(sudo ufw status 2>/dev/null || echo "UFW не установлен или не настроен.")
    SELINUX_STATUS=$(command -v sestatus &>/dev/null && sestatus | grep "SELinux status" || echo "SELinux не установлен.")

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
    else
        ANTIVIRUS_STATUS="Антивирус не установлен"
    fi

    if lsblk -o NAME,FSTYPE | grep -q "crypt"; then
        DISK_ENCRYPTION="Шифрование дисков включено"
    else
        DISK_ENCRYPTION="Шифрование дисков отключено"
    fi

    MESSAGE="
Статус UEFI:                $UEFI_STATUS
Статус TPM 2.0:             $TPM_STATUS
Статус брандмауэра (UFW):    $UFW_STATUS
Статус SELinux:             $SELINUX_STATUS
Статус AppArmor:            $APPARMOR_STATUS
Статус антивируса:          $ANTIVIRUS_STATUS
Статус шифрования дисков:    $DISK_ENCRYPTION
"

    whiptail --title "Информация о безопасности" --scrolltext --msgbox "$MESSAGE" 15 60
}

main_menu() {
    while true; do
        OPTION=$(whiptail --title "Главное меню" --menu "Выберите опцию:" 15 60 5 \
            "1" "Информация о системе" \
            "2" "Температура" \
            "3" "Информация о дисках" \
            "4" "Сеть" \
            "5" "Безопасность" 3>&1 1>&2 2>&3)

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
