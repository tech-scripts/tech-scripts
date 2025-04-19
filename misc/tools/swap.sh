#!/bin/bash

CONFIG_DIR="/etc/tech-scripts"
CONFIG_FILE="$CONFIG_DIR/choose.conf"
SWAP_CONFIG="$CONFIG_DIR/swap.conf"

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
            ;;
        *)
            INVALID_SIZE="Invalid input. Please enter size in format like 8G or 512M."
            ENTER_SIZE="Enter ZRAM size (e.g., 8G, 512M):"
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
            ;;
    esac
}

is_valid_size() {
    [[ "$1" =~ ^[0-9]+[GgMmKk]$ ]]
}

check_active_swap() {
    [ -f /proc/swaps ] && [ "$(wc -l < /proc/swaps)" -gt 1 ]
}

check_zswap_support() {
    [ -d /sys/module/zswap ] && [ -f /sys/module/zswap/parameters/enabled ]
}

disable_swap() {
    $SUDO swapoff -a 2>/dev/null
    if lsmod | grep -q zram; then
        $SUDO modprobe -r zram 2>/dev/null
    fi
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
    if ! modprobe -n zram >/dev/null 2>&1; then
        whiptail --msgbox "ZRAM не поддерживается вашим ядром" 8 50
        return 1
    fi

    while true; do
        ZRAM_SIZE=$(whiptail --inputbox "$ENTER_SIZE" 10 50 "4G" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && return 1
        
        is_valid_size "$ZRAM_SIZE" && break
        whiptail --msgbox "$INVALID_SIZE" 8 50
    done

    disable_swap

    $SUDO modprobe zram num_devices=1 || {
        whiptail --msgbox "Ошибка загрузки модуля zram" 8 50
        return 1
    }

    echo "$ZRAM_SIZE" | $SUDO tee /sys/block/zram0/disksize >/dev/null 2>&1 || {
        whiptail --msgbox "Ошибка настройки размера ZRAM" 8 50
        $SUDO modprobe -r zram
        return 1
    }

    $SUDO mkswap /dev/zram0 >/dev/null 2>&1 || {
        whiptail --msgbox "Ошибка создания swap на ZRAM" 8 50
        $SUDO modprobe -r zram
        return 1
    }

    $SUDO swapon /dev/zram0 || {
        whiptail --msgbox "Ошибка активации ZRAM swap" 8 50
        $SUDO modprobe -r zram
        return 1
    }

    echo "ZRAM_SIZE=$ZRAM_SIZE" | $SUDO tee "$SWAP_CONFIG" >/dev/null
    whiptail --msgbox "$ZRAM_SETUP" 8 50
}

setup_swapfile() {
    while true; do
        SWAP_SIZE=$(whiptail --inputbox "$SWAP_SIZE_PROMPT" 10 50 "4G" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && return 1
        
        is_valid_size "$SWAP_SIZE" && break
        whiptail --msgbox "$INVALID_SIZE" 8 50
    done

    disable_swap
    $SUDO rm -f /swapfile

    if ! $SUDO fallocate -l "$SWAP_SIZE" /swapfile; then
        whiptail --msgbox "Ошибка создания swap-файла" 8 50
        return 1
    fi

    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile >/dev/null 2>&1 || {
        whiptail --msgbox "Ошибка инициализации swap" 8 50
        return 1
    }

    $SUDO swapon /swapfile || {
        whiptail --msgbox "Ошибка активации swap" 8 50
        return 1
    }

    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" | $SUDO tee -a /etc/fstab >/dev/null
    whiptail --msgbox "$SWAP_SETUP" 8 50
}

setup_zswap() {
    if ! [ -d /sys/module/zswap ]; then
        whiptail --msgbox "ZSWAP не поддерживается вашим ядром." 8 50
        return 1
    fi

    disable_swap

    echo 1 | $SUDO tee /sys/module/zswap/parameters/enabled > /dev/null

    if [ -f /sys/module/zswap/parameters/compressor ]; then
        echo "lz4" | $SUDO tee /sys/module/zswap/parameters/compressor >/dev/null 2>&1 || {
            echo "zswap: не удалось установить lz4 compressor" >&2
        }
    fi

    if [ -f /sys/module/zswap/parameters/zpool ]; then
        echo "zsmalloc" | $SUDO tee /sys/module/zswap/parameters/zpool >/dev/null 2>&1 || {
            echo "zswap: zsmalloc zpool не поддерживается" >&2
        }
    fi

    {
        echo "options zswap enabled=1"
        echo "options zswap compressor=lz4"
        echo "options zswap zpool=zsmalloc"
    } | $SUDO tee /etc/modprobe.d/zswap.conf > /dev/null

    whiptail --msgbox "ZSWAP успешно настроен." 8 50
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
            *) exit 0 ;;
        esac
    done
}

init_language

if check_active_swap; then
    whiptail --yesno "$DISABLE_SWAP_PROMPT" 10 50 && disable_swap
fi

main_menu
