#!/bin/bash

CONFIG_DIR="/etc/tech-scripts"
CONFIG_FILE="$CONFIG_DIR/choose.conf"
ZRAM_CONFIG="$CONFIG_DIR/swap.conf"
LOG_FILE="/var/log/tech-scripts.log"

[ "$(id -u)" -eq 0 ] || SUDO=$(command -v sudo)

$SUDO mkdir -p "$CONFIG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %T') - $1" | $SUDO tee -a "$LOG_FILE" >/dev/null
}

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
            REMOVE_ZRAM="Удалить текущие настройки ZRAM?"
            ZRAM_REMOVED="Настройки ZRAM удалены."
            ZSWAP_ENABLED="ZSWAP включен."
            SWAP_SETUP="SWAP настроен на размер $SWAP_SIZE."
            CHOOSE_MEMORY="Выберите тип памяти:"
            ZRAM_OPTION="ZRAM (сжатый swap в памяти)"
            SWAP_OPTION="Обычный SWAP (на диске)"
            ZSWAP_OPTION="ZSWAP (автоматическая компрессия)"
            ZSWAP_NOT_SUPPORTED="ZSWAP не поддерживается вашим ядром."
            DISABLE_SWAP_PROMPT="Обнаружены активные swap-устройства. Нужно отключить их для продолжения. Продолжить?"
            SWAP_SIZE_PROMPT="Введите размер SWAP (например, 8G):"
            ZRAM_SETUP="ZRAM настроен на размер $ZRAM_SIZE."
            ADD_AUTOSTART="Добавить настройки в автозагрузку?"
            AUTOSTART_ADDED="Настройки добавлены в автозагрузку."
            AUTOSTART_SKIPPED="Автозагрузка не настроена."
            REMOVE_AUTOSTART="Обнаружены настройки автозагрузки. Удалить их?"
            AUTOSTART_REMOVED="Настройки автозагрузки удалены."
            CURRENT_SETTINGS="Текущие настройки:"
            NO_ACTIVE_SWAP="Активные swap-устройства не обнаружены."
            ;;
        *)
            INVALID_SIZE="Invalid input. Please enter size in format like 8G or 512M."
            ENTER_SIZE="Enter ZRAM size (e.g., 8G, 512M):"
            REMOVE_ZRAM="Remove current ZRAM settings?"
            ZRAM_REMOVED="ZRAM settings removed."
            ZSWAP_ENABLED="ZSWAP enabled."
            SWAP_SETUP="SWAP set with size $SWAP_SIZE."
            CHOOSE_MEMORY="Choose memory type:"
            ZRAM_OPTION="ZRAM (compressed in-memory swap)"
            SWAP_OPTION="Regular SWAP (on disk)"
            ZSWAP_OPTION="ZSWAP (automatic compression)"
            ZSWAP_NOT_SUPPORTED="ZSWAP is not supported by your kernel."
            DISABLE_SWAP_PROMPT="Active swap devices found. Need to disable them to continue. Proceed?"
            SWAP_SIZE_PROMPT="Enter SWAP size (e.g., 8G):"
            ZRAM_SETUP="ZRAM set with size $ZRAM_SIZE."
            ADD_AUTOSTART="Add to autostart?"
            AUTOSTART_ADDED="Settings added to autostart."
            AUTOSTART_SKIPPED="Autostart not configured."
            REMOVE_AUTOSTART="Found autostart settings. Remove them?"
            AUTOSTART_REMOVED="Autostart settings removed."
            CURRENT_SETTINGS="Current settings:"
            NO_ACTIVE_SWAP="No active swap devices found."
            ;;
    esac
}

is_valid_size() {
    [[ $1 =~ ^[0-9]+[GgMmKk]$ ]] && return 0
    return 1
}

to_bytes() {
    local size=$1
    local unit=${size: -1}
    local num=${size%?}

    case "$unit" in
        G|g) echo $((num * 1024 * 1024 * 1024));;
        M|m) echo $((num * 1024 * 1024));;
        K|k) echo $((num * 1024));;
        *)   echo "$num";;
    esac
}

check_active_swap() {
    local count=0
    if [ -f /proc/swaps ] && [ $(wc -l < /proc/swaps) -gt 1 ]; then
        count=$(($(wc -l < /proc/swaps) - 1))
    fi
    [ $count -gt 0 ] && return 0 || return 1
}

check_active_zram() {
    grep -q 'zram' /proc/swaps && return 0 || return 1
}

check_zswap_support() {
    [ -d /sys/module/zswap ] && return 0 || return 1
}

disable_all_swap() {
    log "Disabling all swap devices"
    if check_active_swap; then
        $SUDO swapoff -a && $SUDO sync
        if check_active_zram; then
            $SUDO modprobe -r zram
        fi
        return 0
    fi
    return 1
}

show_current_settings() {
    local active_swaps=$(swapon --show=name,type,size | tail -n +2)
    if [ -z "$active_swaps" ]; then
        whiptail --msgbox "$NO_ACTIVE_SWAP" 8 50
    else
        whiptail --msgbox --title "$CURRENT_SETTINGS" "$active_swaps" 15 50
    fi
}

setup_zram() {
    local ZRAM_SIZE
    local RAM_SIZE_BYTES=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') * 1024))
    
    while true; do
        ZRAM_SIZE=$(whiptail --inputbox "$ENTER_SIZE\n(Рекомендуется не более 50% от RAM)" 12 50 "4G" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && return 1
        
        if is_valid_size "$ZRAM_SIZE"; then
            local zram_bytes=$(to_bytes "$ZRAM_SIZE")
            if [ $zram_bytes -gt $((RAM_SIZE_BYTES + RAM_SIZE_BYTES / 4)) ]; then
                whiptail --msgbox "Размер ZRAM слишком большой для вашей системы. Доступно RAM: $((RAM_SIZE_BYTES / 1024 / 1024))G" 10 50
                continue
            fi
            break
        else
            whiptail --msgbox "$INVALID_SIZE" 8 50
        fi
    done

    disable_all_swap
    
    $SUDO modprobe zram num_devices=1
    if [ $? -ne 0 ]; then
        whiptail --msgbox "Не удалось загрузить модуль zram" 8 50
        return 1
    fi
    
    echo "$ZRAM_SIZE" | $SUDO tee /sys/block/zram0/disksize > /dev/null || {
        whiptail --msgbox "Не удалось установить размер ZRAM" 8 50
        return 1
    }
    
    $SUDO mkswap /dev/zram0 || {
        whiptail --msgbox "Не удалось создать swap на ZRAM устройстве" 8 50
        return 1
    }
    
    $SUDO swapon /dev/zram0 -p 32767 || {
        whiptail --msgbox "Не удалось активировать ZRAM swap" 8 50
        return 1
    }
    
    echo "ZRAM_SIZE=$ZRAM_SIZE" | $SUDO tee "$ZRAM_CONFIG" > /dev/null
    
    if whiptail --yesno "$ADD_AUTOSTART" 8 50; then
        $SUDO tee /etc/systemd/system/zram-setup.service > /dev/null <<EOF
[Unit]
Description=ZRAM Setup
Before=swap.target
[Service]
Type=oneshot
ExecStart=/usr/bin/bash -c 'modprobe zram && echo $ZRAM_SIZE > /sys/block/zram0/disksize && mkswap /dev/zram0 && swapon /dev/zram0 -p 32767'
RemainAfterExit=true
[Install]
WantedBy=multi-user.target
EOF
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable zram-setup.service
    fi
    
    whiptail --msgbox "$ZRAM_SETUP" 8 50
    return 0
}

setup_swapfile() {
    local SWAP_SIZE
    local DISK_SPACE_AVAIL=$($SUDO df -k --output=avail / | tail -1)
    local DISK_SPACE_NEEDED
    
    while true; do
        SWAP_SIZE=$(whiptail --inputbox "$SWAP_SIZE_PROMPT" 10 50 "4G" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && return 1
        
        if is_valid_size "$SWAP_SIZE"; then
            DISK_SPACE_NEEDED=$(to_bytes "$SWAP_SIZE")
            DISK_SPACE_NEEDED=$((DISK_SPACE_NEEDED / 1024))
            
            if [ $DISK_SPACE_NEEDED -gt $DISK_SPACE_AVAIL ]; then
                whiptail --msgbox "Недостаточно места на диске. Доступно: $((DISK_SPACE_AVAIL / 1024 / 1024))G" 10 50
                continue
            fi
            break
        else
            whiptail --msgbox "$INVALID_SIZE" 8 50
        fi
    done

    disable_all_swap
    
    $SUDO rm -f /swapfile
    
    if ! $SUDO fallocate -l "$SWAP_SIZE" /swapfile; then
        whiptail --msgbox "Не удалось создать файл подкачки" 8 50
        return 1
    fi
    
    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile || {
        whiptail --msgbox "Не удалось создать swap на файле" 8 50
        return 1
    }
    
    $SUDO swapon /swapfile || {
        whiptail --msgbox "Не удалось активировать файл подкачки" 8 50
        return 1
    }
    
    $SUDO grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" | $SUDO tee -a /etc/fstab > /dev/null
    
    if [ "$SWAP_SIZE" != "${SWAP_SIZE//G/}" ]; then
        $SUDO sysctl vm.swappiness=60
        echo "vm.swappiness=60" | $SUDO tee /etc/sysctl.d/99-swap.conf > /dev/null
    fi
    
    whiptail --msgbox "$SWAP_SETUP" 8 50
    return 0
}

setup_zswap() {
    if ! check_zswap_support; then
        whiptail --msgbox "$ZSWAP_NOT_SUPPORTED" 8 50
        return 1
    fi
    
    disable_all_swap
    
    echo 1 | $SUDO tee /sys/module/zswap/parameters/enabled > /dev/null
    
    if [ -f /sys/module/zswap/parameters/compressor ]; then
        echo "lz4" | $SUDO tee /sys/module/zswap/parameters/compressor > /dev/null
    fi
    
    if [ -f /sys/module/zswap/parameters/zpool ]; then
        echo "z3fold" | $SUDO tee /sys/module/zswap/parameters/zpool > /dev/null
    fi
    
    PERSISTENT_CONF="options zswap enabled=1"
    
    if [ -f /sys/module/zswap/parameters/compressor ]; then
        PERSISTENT_CONF="$PERSISTENT_CONF\noptions zswap compressor=lz4"
    fi
    
    if [ -f /sys/module/zswap/parameters/zpool ]; then
        PERSISTENT_CONF="$PERSISTENT_CONF\noptions zswap zpool=z3fold"
    fi
    
    echo -e "$PERSISTENT_CONF" | $SUDO tee /etc/modprobe.d/zswap.conf > /dev/null
    
    whiptail --msgbox "$ZSWAP_ENABLED" 8 50
    return 0
}

main_menu() {
    while true; do
        choice=$(whiptail --menu "$CHOOSE_MEMORY" 15 50 4 \
            1 "$ZRAM_OPTION" \
            2 "$SWAP_OPTION" \
            3 "$ZSWAP_OPTION" \
            4 "Показать текущие настройки" 3>&1 1>&2 2>&3)
        
        [ $? -ne 0 ] && exit 0
        
        case $choice in
            1) setup_zram ;;
            2) setup_swapfile ;;
            3) setup_zswap ;;
            4) show_current_settings ;;
        esac
    done
}

init_language

if check_active_swap; then
    if whiptail --yesno "$DISABLE_SWAP_PROMPT" 10 50; then
        disable_all_swap
    else
        exit 0
    fi
fi

main_menu
