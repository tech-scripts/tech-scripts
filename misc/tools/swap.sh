#!/bin/bash

SUDO=$(command -v sudo || echo "")
CONFIG_FILE="/etc/tech-scripts/choose.conf"
ZRAM_CONFIG="/etc/tech-scripts/swap.conf"
LANGUAGE=$(grep '^lang:' "$CONFIG_FILE" | cut -d' ' -f2)

if [ "$LANGUAGE" = "Русский" ]; then
    INVALID_SIZE="Некорректный ввод. Введите размер в формате, например, 8G или 512M."
    ENTER_SIZE="Введите размер ZRAM (например, 8G, 512M):"
    REMOVE_ZRAM="Удалить настройки ZRAM?"
    ZRAM_REMOVED="Настройки ZRAM удалены."
    ZSWAP_ENABLED="ZSWAP включен."
    SWAP_SETUP="SWAP настроен на размер $SWAP_SIZE."
    CHOOSE_MEMORY="Выберите тип памяти:"
    ZRAM_OPTION="ZRAM"
    SWAP_OPTION="SWAP"
    ZSWAP_OPTION="ZSWAP (автоматически)"
    ZSWAP_NOT_SUPPORTED="ZSWAP не поддерживается вашим ядром."
    DISABLE_SWAP_PROMPT="Отключить активную подкачку для продолжения?"
    SWAP_SIZE_PROMPT="Введите размер SWAP (например, 8G):"
    ZRAM_SETUP="ZRAM настроен на размер $ZRAM_SIZE."
    ADD_AUTOSTART="Добавить настройки в автозапуск через systemd?"
    AUTOSTART_ADDED="Настройки добавлены в автозапуск."
    AUTOSTART_SKIPPED="Автозапуск не настроен."
    REMOVE_AUTOSTART="Обнаружены настройки автозапуска. Хотите удалить их?"
    AUTOSTART_REMOVED="Настройки автозапуска удалены."
else
    INVALID_SIZE="Invalid input. Please enter size in format like 8G or 512M."
    ENTER_SIZE="Enter ZRAM size (e.g., 8G, 512M):"
    REMOVE_ZRAM="Remove ZRAM settings?"
    ZRAM_REMOVED="ZRAM settings removed."
    ZSWAP_ENABLED="ZSWAP enabled."
    SWAP_SETUP="SWAP set up with size $SWAP_SIZE."
    CHOOSE_MEMORY="Choose memory type:"
    ZRAM_OPTION="ZRAM"
    SWAP_OPTION="SWAP"
    ZSWAP_OPTION="ZSWAP (automatic)"
    ZSWAP_NOT_SUPPORTED="ZSWAP is not supported by your kernel."
    z="Disable active paging to continue?"
    SWAP_SIZE_PROMPT="Enter SWAP size (e.g., 8G):"
    ZRAM_SETUP="ZRAM set up with size $ZRAM_SIZE."
    ADD_AUTOSTART="Add settings to autostart via systemd?"
    AUTOSTART_ADDED="Settings added to autostart."
    AUTOSTART_SKIPPED="Autostart not configured."
    REMOVE_AUTOSTART="Autostart settings found. Do you want to remove them?"
    AUTOSTART_REMOVED="Autostart settings removed."
fi

is_valid_size() {
    [[ $1 =~ ^[0-9]+[GgMm]$ ]]
}

close() {
    exit 0
}

check_active_swap() {
    swapon --show | grep -q '/'
}

check_active_zram() {
    lsblk | grep -q zram
}

check_active_zswap() {
    if [ -d /sys/module/zswap ]; then
        if [ -f /sys/module/zswap/parameters/enabled ]; then
            ZSWAP_ENABLED=$(cat /sys/module/zswap/parameters/enabled 2>/dev/null)
            if [[ "$ZSWAP_ENABLED" =~ ^[0-1]$ ]]; then
                return 0
            fi
        fi
    fi
    return 1
}

check_zswap_support() {
    if [ -d /sys/module/zswap ]; then
        return 0
    else
        return 1
    fi
}

add_to_autostart() {
    local service_name=$1
    local exec_start=$2

    if whiptail --yesno "$ADD_AUTOSTART" 10 40; then
        SERVICE_FILE="/etc/systemd/system/$service_name.service"
        $SUDO tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=$service_name Setup Script
After=network.target

[Service]
Type=simple
ExecStart=$exec_start
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable "$service_name.service"
        $SUDO systemctl start "$service_name.service"
        echo "$AUTOSTART_ADDED"
    else
        echo "$AUTOSTART_SKIPPED"
    fi
}

remove_autostart() {
    local service_name=$1

    if systemctl is-enabled "$service_name.service" &>/dev/null; then
        if whiptail --yesno "$REMOVE_AUTOSTART" 10 40; then
            $SUDO systemctl stop "$service_name.service"
            $SUDO systemctl disable "$service_name.service"
            $SUDO rm -f "/etc/systemd/system/$service_name.service"
            $SUDO systemctl daemon-reload
            echo "$AUTOSTART_REMOVED"
        fi
    fi
}

ACTIVE_SWAP=0
ACTIVE_ZRAM=0
ACTIVE_ZSWAP=0

check_active_swap && ACTIVE_SWAP=1
check_active_zram && ACTIVE_ZRAM=1
check_active_zswap && ACTIVE_ZSWAP=1

if [ $ACTIVE_SWAP -eq 1 ] || [ $ACTIVE_ZRAM -eq 1 ] || [ $ACTIVE_ZSWAP -eq 1 ]; then
    if whiptail --yesno "$DISABLE_SWAP_PROMPT" 10 40; then
        [ $ACTIVE_SWAP -eq 1 ] && { $SUDO swapoff -a; }
        [ $ACTIVE_ZRAM -eq 1 ] && { $SUDO swapoff /dev/zram0; $SUDO modprobe -r zram; }
        [ $ACTIVE_ZSWAP -eq 1 ] && { echo 0 | $SUDO tee /sys/module/zswap/parameters/enabled > /dev/null; }
    else
        exit 0
    fi
fi

remove_autostart "zram-setup"
remove_autostart "swap-setup"
remove_autostart "zswap-setup"

whiptail --title "$CHOOSE_MEMORY" --menu "$CHOOSE_MEMORY" 10 40 3 \
1 "$ZRAM_OPTION" \
2 "$SWAP_OPTION" \
3 "$ZSWAP_OPTION" 2> /tmp/memory_choice

MEMORY_CHOICE=$(< /tmp/memory_choice)

case $MEMORY_CHOICE in
    1)
        while true; do
            ZRAM_SIZE=$(whiptail --inputbox "$ENTER_SIZE" 10 40 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && close
            if is_valid_size "$ZRAM_SIZE"; then
                break
            else
                whiptail --msgbox "$INVALID_SIZE" 10 50
            fi
        done

        if [ -f "$ZRAM_CONFIG" ]; then
            source "$ZRAM_CONFIG"
            if whiptail --yesno "$REMOVE_ZRAM" 10 40; then
                $SUDO rm -f "$ZRAM_CONFIG"
                echo "$ZRAM_REMOVED"
                $SUDO swapoff /dev/zram0 2>/dev/null
                $SUDO modprobe -r zram 2>/dev/null
            else
                close
            fi
        fi

        $SUDO modprobe zram
        echo "$ZRAM_SIZE" | $SUDO tee /sys/block/zram0/disksize > /dev/null
        $SUDO mkswap /dev/zram0
        $SUDO swapon /dev/zram0
        echo "$ZRAM_SETUP"
        echo "ZRAM_SIZE=$ZRAM_SIZE" | $SUDO tee "$ZRAM_CONFIG" > /dev/null
        add_to_autostart "zram-setup" "/bin/bash -c 'modprobe zram && echo $ZRAM_SIZE > /sys/block/zram0/disksize && mkswap /dev/zram0 && swapon /dev/zram0'"
        ;;

    2)
        SWAP_SIZE=$(whiptail --inputbox "$SWAP_SIZE_PROMPT" 10 40 3>&1 1>&2 2>&3)
        if is_valid_size "$SWAP_SIZE"; then
            $SUDO fallocate -l "$SWAP_SIZE" /swapfile
            $SUDO chmod 600 /swapfile
            $SUDO mkswap /swapfile
            $SUDO swapon /swapfile
            echo "/swapfile none swap sw 0 0" | $SUDO tee -a /etc/fstab > /dev/null
            echo "$SWAP_SETUP"
            add_to_autostart "swap-setup" "/bin/bash -c 'swapon /swapfile'"
        else
            whiptail --msgbox "$INVALID_SIZE" 8 50
        fi
        ;;

    3)
        if check_zswap_support; then
            echo 1 | $SUDO tee /sys/module/zswap/parameters/enabled > /dev/null
            
            if [ -f /sys/module/zswap/parameters/zpool ]; then
                echo "z3fold" | $SUDO tee /sys/module/zswap/parameters/zpool > /dev/null
            fi
            
            if [ -f /sys/module/zswap/parameters/compressor ]; then
                echo "lzo" | $SUDO tee /sys/module/zswap/parameters/compressor > /dev/null
            fi
            
            echo "$ZSWAP_ENABLED"
            add_to_autostart "zswap-setup" "/bin/bash -c 'echo 1 > /sys/module/zswap/parameters/enabled"
            
            if [ -f /sys/module/zswap/parameters/zpool ]; then
                echo " && echo z3fold > /sys/module/zswap/parameters/zpool"
            fi
            
            if [ -f /sys/module/zswap/parameters/compressor ]; then
                echo " && echo lzo > /sys/module/zswap/parameters/compressor"
            fi
            
            echo "'"
        else
            echo "$ZSWAP_NOT_SUPPORTED"
        fi
        ;;
esac

rm -f /tmp/memory_choice
