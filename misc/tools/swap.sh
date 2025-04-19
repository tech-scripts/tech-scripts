#!/bin/bash

CONFIG_DIR="/etc/tech-scripts"
CONFIG_FILE="$CONFIG_DIR/choose.conf"
ZRAM_CONFIG="$CONFIG_DIR/swap.conf"

[ "$(id -u)" -eq 0 ] || SUDO=$(command -v sudo)

$SUDO mkdir -p "$CONFIG_DIR"

init_language() {
    if [ -f "$CONFIG_FILE" ]; then
        LANGUAGE=$(grep '^lang:' "$CONFIG_FILE" | cut -d' ' -f2)
    else
        LANGUAGE="English"
    fi

    case "$LANGUAGE" in
        "Русский")
            INVALID_SIZE="Некорректный ввод. Введите размер в формате, например, 8G или 512M."
            ENTER_SIZE="Введите размер ZRAM (например, 8G, 512M):"
            ZRAM_REMOVED="Настройки ZRAM удалены."
            ZSWAP_ENABLED="ZSWAP включен."
            SWAP_SETUP="SWAP настроен на размер $SWAP_SIZE."
            CHOOSE_MEMORY="Выберите тип памяти:"
            ZRAM_OPTION="ZRAM (сжатый swap в памяти)"
            SWAP_OPTION="Обычный SWAP (на диске)"
            ZSWAP_OPTION="ZSWAP (автоматическая компрессия)"
            ZSWAP_NOT_SUPPORTED="ZSWAP не поддерживается вашим ядром."
            DISABLE_SWAP_PROMPT="Обнаружены активные swap-устройства. Отключить их перед настройкой?"
            SWAP_SIZE_PROMPT="Введите размер SWAP (например, 8G):"
            ZRAM_SETUP="ZRAM настроен на размер $ZRAM_SIZE."
            CURRENT_SETTINGS="Текущие настройки:"
            NO_ACTIVE_SWAP="Активные swap-устройства не обнаружены."
            FUNCTION_NOT_AVAILABLE="Функция недоступна в текущей системе."
            ;;
        *)
            INVALID_SIZE="Invalid input. Please enter size in format like 8G or 512M."
            ENTER_SIZE="Enter ZRAM size (e.g., 8G, 512M):"
            ZRAM_REMOVED="ZRAM settings removed."
            ZSWAP_ENABLED="ZSWAP enabled."
            SWAP_SETUP="SWAP set with size $SWAP_SIZE."
            CHOOSE_MEMORY="Choose memory type:"
            ZRAM_OPTION="ZRAM (compressed in-memory swap)"
            SWAP_OPTION="Regular SWAP (on disk)"
            ZSWAP_OPTION="ZSWAP (automatic compression)"
            ZSWAP_NOT_SUPPORTED="ZSWAP is not supported by your kernel."
            DISABLE_SWAP_PROMPT="Active swap devices found. Disable them before setup?"
            SWAP_SIZE_PROMPT="Enter SWAP size (e.g., 8G):"
            ZRAM_SETUP="ZRAM set with size $ZRAM_SIZE."
            CURRENT_SETTINGS="Current settings:"
            NO_ACTIVE_SWAP="No active swap devices found."
            FUNCTION_NOT_AVAILABLE="Function not available on this system."
            ;;
    esac
}

is_valid_size() {
    [[ "$1" =~ ^[0-9]+[GgMmKk]$ ]]
}

check_active_swap() {
    [ -f /proc/swaps ] && [ "$(wc -l < /proc/swaps)" -gt 1 ]
}

check_active_zram() {
    grep -q 'zram' /proc/swaps
}

check_zswap_support() {
    [ -d /sys/module/zswap ] && [ -f /sys/module/zswap/parameters/enabled ]
}

disable_all_swap() {
    $SUDO swapoff -a 2>/dev/null
    if check_active_zram; then
        $SUDO modprobe -r zram 2>/dev/null
    fi
    return 0
}

show_current_settings() {
    local active_swaps=$(swapon --show=name,type,size,used 2>/dev/null)
    if [ -z "$active_swaps" ]; then
        whiptail --msgbox "$NO_ACTIVE_SWAP" 8 50
    else
        whiptail --msgbox --title "$CURRENT_SETTINGS" "$active_swaps" 15 50
    fi
}

setup_zram() {
    if ! modprobe -n zram; then
        whiptail --msgbox "$FUNCTION_NOT_AVAILABLE" 8 50
        return 1
    fi

    while true; do
        ZRAM_SIZE=$(whiptail --inputbox "$ENTER_SIZE" 10 50 "4G" 3>&1 1>&2 2>&3)
        [! "$?" -eq 0 ] && return 1
        
        is_valid_size "$ZRAM_SIZE" && break
        whiptail --msgbox "$INVALID_SIZE" 8 50
    done

    disable_all_swap

    $SUDO modprobe zram num_devices=1 || {
        whiptail --msgbox "Не удалось загрузить модуль zram" 8 50
        return 1
    }

    echo "$ZRAM_SIZE" | $SUDO tee /sys/block/zram0/disksize >/dev/null 2>&1 || {
        whiptail --msgbox "Не удалось установить размер ZRAM" 8 50
        return 1
    }

    $SUDO mkswap /dev/zram0 >/dev/null || {
        whiptail --msgbox "Не удалось создать swap на ZRAM устройстве" 8 50
        return 1
    }

    $SUDO swapon /dev/zram0 || {
        whiptail --msgbox "Не удалось активировать ZRAM swap" 8 50
        return 1
    }

    echo "ZRAM_SIZE=$ZRAM_SIZE" | $SUDO tee "$ZRAM_CONFIG" >/dev/null
    whiptail --msgbox "$ZRAM_SETUP" 8 50
    return 0
}

setup_swapfile() {
    while true; do
        SWAP_SIZE=$(whiptail --inputbox "$SWAP_SIZE_PROMPT" 10 50 "4G" 3>&1 1>&2 2>&3)
        [! "$?" -eq 0 ] && return 1
        
        is_valid_size "$SWAP_SIZE" && break
        whiptail --msgbox "$INVALID_SIZE" 8 50
    done

    disable_all_swap
    $SUDO rm -f /swapfile

    if ! $SUDO fallocate -l "$SWAP_SIZE" /swapfile; then
        whiptail --msgbox "Не удалось создать swap-файл" 8 50
        return 1
    fi

    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile >/dev/null || {
        whiptail --msgbox "Не удалось инициализировать swap" 8 50
        return 1
    }

    $SUDO swapon /swapfile || {
        whiptail --msgbox "Не удалось активировать swap" 8 50
        return 1
    }

    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" | $SUDO tee -a /etc/fstab >/dev/null
    whiptail --msgbox "$SWAP_SETUP" 8 50
    return 0
}

setup_zswap() {
    if ! check_zswap_support; then
        whiptail --msgbox "$ZSWAP_NOT_SUPPORTED" 8 50
        return 1
    fi

    disable_all_swap
    
    echo 1 | $SUDO tee /sys/module/zswap/parameters/enabled >/dev/null 2>&1
    
    if [ -f /sys/module/zswap/parameters/compressor ]; then
        echo "lz4" | $SUDO tee /sys/module/zswap/parameters/compressor >/dev/null 2>&1
    fi
    
    if [ -f /sys/module/zswap/parameters/zpool ]; then
        echo "z3fold" | $SUDO tee /sys/module/zswap/parameters/zpool >/dev/null 2>&1
    fi
    
    whiptail --msgbox "$ZSWAP_ENABLED" 8 50
    return 0
}

main_menu() {
    while true; do
        choice=$(whiptail --title "$CHOOSE_MEMORY" --menu "" 15 50 4 \
            "1" "$ZRAM_OPTION" \
            "2" "$SWAP_OPTION" \
            "3" "$ZSWAP_OPTION" \
            "4" "$CURRENT_SETTINGS" 3>&1 1>&2 2>&3)

        case $? in
            0)
                case "$choice" in
                    1) setup_zram ;;
                    2) setup_swapfile ;;
                    3) setup_zswap ;;
                    4) show_current_settings ;;
                esac
                ;;
            *) return ;;
        esac
    done
}

init_language

if check_active_swap; then
    whiptail --yesno "$DISABLE_SWAP_PROMPT" 10 50 && disable_all_swap
fi

main_menu
