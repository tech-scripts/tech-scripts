#!/bin/bash

trap 'echo "$CANCEL_MSG"; exit 0' SIGINT
SUDO=$(command -v sudo || echo "")
CONFIG_FILE="/etc/tech-scripts/choose.conf"
ZRAM_CONFIG="/etc/MootComb/zram_config.conf"

if [ -f "$CONFIG_FILE" ]; then
    LANG_CONF=$(grep '^lang:' "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ')
else
    LANG_CONF="English"
fi

if [ "$LANG_CONF" = "Русский" ]; then
    CANCEL_MSG="Вы прервали выполнение скрипта."
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
    SWAP_PARTITION_FOUND="Обнаружен раздел подкачки. Подкачка не поддерживается на системе с существующим разделом подкачки."
    ACTIVE_SWAP_FOUND="Обнаружена активная подкачка. Пожалуйста, отключите её перед настройкой новой."
    ACTIVE_ZRAM_FOUND="Обнаружена активная ZRAM. Пожалуйста, отключите её перед настройкой новой."
    ACTIVE_ZSWAP_FOUND="Обнаружена активная ZSWAP. Пожалуйста, отключите её перед настройкой новой."
else
    CANCEL_MSG="Script execution interrupted."
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
    SWAP_PARTITION_FOUND="Swap partition found. Swap is not supported on a system with an existing swap partition."
    ACTIVE_SWAP_FOUND="Active swap found. Please disable it before setting up a new one."
    ACTIVE_ZRAM_FOUND="Active ZRAM found. Please disable it before setting up a new one."
    ACTIVE_ZSWAP_FOUND="Active ZSWAP found. Please disable it before setting up a new one."
fi

install_dialog() {
    $SUDO apt update && $SUDO apt install -y dialog || { echo "Error installing dialog."; exit 1; }
}

if ! command -v dialog &> /dev/null; then
    echo "dialog not found. Installing..."
    install_dialog
fi

is_valid_size() {
    [[ $1 =~ ^[0-9]+[GgMm]$ ]]
}

close() {
    echo "$CANCEL_MSG"
    exit 0
}

check_active_swap() {
    if swapon --show | grep -q '/'; then
        echo "$ACTIVE_SWAP_FOUND"
        exit 1
    fi
}

check_active_zram() {
    if lsblk | grep -q zram; then
        echo "$ACTIVE_ZRAM_FOUND"
        exit 1
    fi
}

check_active_zswap() {
    if [ -d /sys/module/zswap ]; then
        if [ "$(cat /sys/module/zswap/parameters/enabled)" -eq 1 ]; then
            echo "$ACTIVE_ZSWAP_FOUND"
            exit 1
        fi
    fi
}

check_swap_partition() {
    if [ "$(lsblk -o TYPE | grep -c 'part')" -gt 0 ]; then
        echo "$SWAP_PARTITION_FOUND"
        exit 1
    fi
}

check_active_swap
check_active_zram
check_active_zswap
check_swap_partition

dialog --menu "$CHOOSE_MEMORY" 10 40 3 \
1 "$ZRAM_OPTION" \
2 "$SWAP_OPTION" \
3 "$ZSWAP_OPTION" 2> /tmp/memory_choice

MEMORY_CHOICE=$(< /tmp/memory_choice)

case $MEMORY_CHOICE in
    1)
        while true; do
            dialog --inputbox "$ENTER_SIZE" 8 40 2> /tmp/zram_size
            if [ $? -ne 0 ]; then close; fi
            ZRAM_SIZE=$(< /tmp/zram_size)
            if is_valid_size "$ZRAM_SIZE"; then break; else dialog --msgbox "$INVALID_SIZE" 6 50; fi
        done

        if [ -f "$ZRAM_CONFIG" ]; then
            source "$ZRAM_CONFIG"
            if dialog --yesno "$REMOVE_ZRAM" 7 40; then
                $SUDO rm -f "$ZRAM_CONFIG"
                echo "$ZRAM_REMOVED"
                $SUDO swapoff /dev/zram0 2>/dev/null
                $SUDO modprobe -r zram 2>/dev/null
            else
                close
            fi
        fi

        $SUDO modprobe zram
        echo $ZRAM_SIZE | $SUDO tee /sys/block/zram0/disksize > /dev/null
        $SUDO mkswap /dev/zram0
        $SUDO swapon /dev/zram0
        echo "ZRAM настроен на размер $ZRAM_SIZE."
        echo "ZRAM_SIZE=$ZRAM_SIZE" | $SUDO tee $ZRAM_CONFIG > /dev/null
        ;;

    2)
        dialog --inputbox "Введите размер SWAP (например, 2G):" 8 40 2> /tmp/swap_size
        SWAP_SIZE=$(< /tmp/swap_size)
        if is_valid_size "$SWAP_SIZE"; then
            $SUDO fallocate -l $SWAP_SIZE /swapfile
            $SUDO chmod 600 /swapfile
            $SUDO mkswap /swapfile
            $SUDO swapon /swapfile
            echo "/swapfile none swap sw 0 0" | $SUDO tee -a /etc/fstab > /dev/null
            echo "$SWAP_SETUP"
        else
            dialog --msgbox "$INVALID_SIZE" 6 50
        fi
        ;;

    3)
        if [ -d /sys/module/zswap ]; then
            echo 1 | $SUDO tee /sys/module/zswap/parameters/enabled > /dev/null
            echo "z3fold" | $SUDO tee /sys/module/zswap/parameters/zpool > /dev/null
            echo "lzo" | $SUDO tee /sys/module/zswap/parameters/compressor > /dev/null
            echo "$ZSWAP_ENABLED"
        else
            echo "$ZSWAP_NOT_SUPPORTED"
        fi
        ;;
esac

rm -f /tmp/memory_choice /tmp/zram_size /tmp/swap_size
