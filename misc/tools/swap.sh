#!/bin/bash

source /tmp/tech-scripts/misc/localization.sh
source /tmp/tech-scripts/misc/variables.sh

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
        whiptail --msgbox "$NO_ACTIVE_SWAP_SWAP" 8 50
    else
        whiptail --msgbox --title "$CURRENT_SETTINGS_SWAP" "$active_swaps" 15 50
    fi
}

setup_zram() {
    if ! modprobe -n zram >/dev/null 2>&1; then
        whiptail --msgbox "$ZSWAP_NOT_SUPPORTED_MSG_SWAP" 8 50
        return 1
    fi

    while true; do
        ZRAM_SIZE_SWAP=$(whiptail --inputbox "$ENTER_SIZE_SWAP" 10 50 "4G" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && return 1
        
        is_valid_size "$ZRAM_SIZE_SWAP" && break
        whiptail --msgbox "$INVALID_SIZE_SWAP" 8 50
    done

    disable_swap

    $SUDO modprobe zram num_devices=1 || {
        whiptail --msgbox "$ERROR_LOAD_ZRAM_SWAP" 8 50
        return 1
    }

    echo "$ZRAM_SIZE_SWAP" | $SUDO tee /sys/block/zram0/disksize >/dev/null 2>&1 || {
        whiptail --msgbox "$ERROR_CONFIG_ZRAM_SIZE_SWAP" 8 50
        $SUDO modprobe -r zram
        return 1
    }

    $SUDO mkswap /dev/zram0 >/dev/null 2>&1 || {
        whiptail --msgbox "$ERROR_CREATE_ZRAM_SWAP_SWAP" 8 50
        $SUDO modprobe -r zram
        return 1
    }

    $SUDO swapon /dev/zram0 || {
        whiptail --msgbox "$ERROR_ACTIVATE_ZRAM_SWAP" 8 50
        $SUDO modprobe -r zram
        return 1
    }

    echo "ZRAM_SIZE=$ZRAM_SIZE_SWAP" | $SUDO tee "$SWAP_CONFIG_SWAP" >/dev/null
    whiptail --msgbox "$ZRAM_SETUP_SWAP $ZRAM_SIZE_SWAP" 8 50
}

setup_swapfile() {
    while true; do
        SWAP_SIZE_SWAP=$(whiptail --inputbox "$SWAP_SIZE_PROMPT_SWAP" 10 50 "4G" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && return 1
        
        is_valid_size "$SWAP_SIZE_SWAP" && break
        whiptail --msgbox "$INVALID_SIZE_SWAP" 8 50
    done

    disable_swap
    $SUDO rm -f /swapfile

    if ! $SUDO fallocate -l "$SWAP_SIZE_SWAP" /swapfile; then
        whiptail --msgbox "$ERROR_CREATE_SWAPFILE_SWAP" 8 50
        return 1
    fi

    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile >/dev/null 2>&1 || {
        whiptail --msgbox "$ERROR_INIT_SWAP_SWAP" 8 50
        return 1
    }

    $SUDO swapon /swapfile || {
        whiptail --msgbox "$ERROR_ACTIVATE_SWAP_SWAP" 8 50
        return 1
    }

    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" | $SUDO tee -a /etc/fstab >/dev/null
    whiptail --msgbox "$SWAP_SETUP_SWAP $SWAP_SIZE_SWAP" 8 50
}

setup_zswap() {
    if ! [ -d /sys/module/zswap ]; then
        whiptail --msgbox "$ZSWAP_NOT_SUPPORTED_MSG_SWAP" 8 50
        return 1
    fi

    disable_swap

    echo 1 | $SUDO tee /sys/module/zswap/parameters/enabled > /dev/null

    if [ -f /sys/module/zswap/parameters/compressor ]; then
        echo "lz4" | $SUDO tee /sys/module/zswap/parameters/compressor >/dev/null 2>&1 || {
            echo "$ZSWAP_COMPRESSOR_ERROR_SWAP" >&2
        }
    fi

    if [ -f /sys/module/zswap/parameters/zpool ]; then
        echo "zsmalloc" | $SUDO tee /sys/module/zswap/parameters/zpool >/dev/null 2>&1 || {
            echo "$ZSWAP_ZPOOL_ERROR_SWAP" >&2
        }
    fi

    {
        echo "options zswap enabled=1"
        echo "options zswap compressor=lz4"
        echo "options zswap zpool=zsmalloc"
    } | $SUDO tee /etc/modprobe.d/zswap.conf > /dev/null

    if ! swapon --show | grep -q "/swapfile"; then
        $SUDO fallocate -l 2G /swapfile || {
            whiptail --msgbox "$ERROR_CREATE_SWAPFILE_SWAP" 8 50
            return 1
        }
        $SUDO chmod 600 /swapfile
        $SUDO mkswap /swapfile || {
            whiptail --msgbox "$ERROR_INIT_SWAP_SWAP" 8 50
            return 1
        }
        $SUDO swapon /swapfile || {
            whiptail --msgbox "$ERROR_ACTIVATE_SWAP_SWAP" 8 50
            return 1
        }
        echo "/swapfile none swap sw 0 0" | $SUDO tee -a /etc/fstab > /dev/null
    fi

    whiptail --msgbox "$ZSWAP_SUCCESS_SETUP_SWAP" 8 50
    check_zswap_status
    return 0
}

check_zswap_status() {
    echo "$CHECK_ACTIVE_SWAP_SWAP"
    swapon --show

    echo "$CHECK_ZSWAP_PARAMS_SWAP"
    echo "Enabled: $(cat /sys/module/zswap/parameters/enabled)"
    echo "Compressor: $(cat /sys/module/zswap/parameters/compressor)"
    echo "Zpool: $(cat /sys/module/zswap/parameters/zpool)"

    echo "$CHECK_ZSWAP_USAGE_SWAP"
    grep -i zswap /proc/meminfo
}

main_menu() {
    while true; do
        choice=$(whiptail --title "$CHOOSE_MEMORY_SWAP" --menu "" 15 50 4 \
            "1" "$ZRAM_OPTION_SWAP" \
            "2" "$SWAP_OPTION_SWAP" \
            "3" "$ZSWAP_OPTION_SWAP" \
            "4" "$CURRENT_SETTINGS_SWAP" 3>&1 1>&2 2>&3)

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

if check_active_swap; then
    whiptail --yesno "$DISABLE_SWAP_PROMPT_SWAP" 10 50 && disable_swap
fi

$SUDO mkdir -p "$CONFIG_DIR_SWAP"
main_menu
