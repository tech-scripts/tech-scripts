#!/usr/bin/env bash

echo "========================================"
echo "         FRP WIPE SCRIPT                "
echo "========================================"

# Функция для основной работы
main_wipe() {
    echo "Running: Direct root mode"
    
    echo "[1/4] Removing FRP files..."
    rm -f /persist/property_persistent_space/*
    rm -f /frp/frp.bin 2>/dev/null
    rm -f /data/system/frp_secret 2>/dev/null
    rm -rf /persist/frp/ 2>/dev/null
    rm -rf /mnt/vendor/persist/frp/ 2>/dev/null
    rm -f /efs/recovery/frp.dat 2>/dev/null
    rm -f /efs/factoryapp/frp.dat 2>/dev/null
    rm -f /nvdata/frp/frp.dat 2>/dev/null
    rm -rf /vendor/frp/ 2>/dev/null
    rm -rf /persist/data/frp/ 2>/dev/null
    rm -rf /cust/frp/ 2>/dev/null
    rm -rf /metadata/frp/ 2>/dev/null
    rm -rf /product/frp/ 2>/dev/null
    rm -rf /system/frp/ 2>/dev/null
    rm -rf /odm/frp/ 2>/dev/null
    rm -rf /backup/frp/ 2>/dev/null
    rm -rf /cache/frp/ 2>/dev/null

    echo "[2/4] Clearing data partitions..."
    rm -rf /data/vendor_ce/0/frp/ 2>/dev/null
    rm -rf /data/system_ce/0/frp/ 2>/dev/null
    rm -rf /data/misc_ce/0/frp/ 2>/dev/null
    rm -rf /data/user_de/0/com.google.android.gms/frp/ 2>/dev/null
    rm -rf /data/data/com.google.android.gms/files/frp/ 2>/dev/null
    rm -f /data/system/users/0/accounts_ce.db* 2>/dev/null
    rm -f /data/system/users/0/settings_ce_global.xml 2>/dev/null

    echo "[3/4] Wiping FRP blocks..."
    dd if=/dev/zero of=/dev/block/bootdevice/by-name/frp bs=4096 count=1 2>/dev/null
    dd if=/dev/zero of=/dev/block/bootdevice/by-name/misc bs=4096 count=1 2>/dev/null
    dd if=/dev/zero of=/dev/block/bootdevice/by-name/PARAM bs=4096 count=1 2>/dev/null
    dd if=/dev/zero of=/dev/block/bootdevice/by-name/oppodycnv bs=4096 count=1 2>/dev/null
    dd if=/dev/zero of=/dev/block/platform/hi_mci.0/by-name/oeminfo bs=4096 count=1 2>/dev/null

    echo "[4/4] Clearing Google services..."
    content delete --uri content://settings/global --where "name='frp'" 2>/dev/null
    content delete --uri content://settings/secure --where "name='frp'" 2>/dev/null
    pm clear com.google.android.gms 2>/dev/null
    pm clear com.google.android.gsf 2>/dev/null

    echo -n 'cleared' > /persist/frp_flag 2>/dev/null

    echo "========================================"
    echo "    FRP WIPE COMPLETED SUCCESSFULLY!"
    echo "      Device will reboot in 3 seconds"
    echo "========================================"

    sleep 3
    reboot
}

# Если запущен с параметром "internal" - выполняем основную работу
if [ "$1" = "internal" ]; then
    main_wipe
    exit 0
fi

# Основное меню
show_menu() {
    echo "Select method:"
    echo "1 - Termux with su"
    echo "2 - Termux with tsu" 
    echo "3 - ADB root"
    echo "4 - ADB shell + su"
    echo "5 - Already root (direct)"
    echo "========================================"
    printf "Enter choice [1-5]: "
}

if [ -z "$1" ]; then
    show_menu
    read choice
else
    choice="$1"
fi

case $choice in
    1)
        echo "Running: Termux + su"
        # Копируем скрипт в временную директорию и запускаем
        cp "$0" /data/local/tmp/frp-wipe.sh 2>/dev/null || exit 1
        chmod 755 /data/local/tmp/frp-wipe.sh
        su -c "sh /data/local/tmp/frp-wipe.sh internal && rm -f /data/local/tmp/frp-wipe.sh"
        exit
        ;;
    2)
        echo "Running: Termux + tsu"
        cp "$0" /data/local/tmp/frp-wipe.sh 2>/dev/null || exit 1
        chmod 755 /data/local/tmp/frp-wipe.sh
        tsu -c "sh /data/local/tmp/frp-wipe.sh internal && rm -f /data/local/tmp/frp-wipe.sh"
        exit
        ;;
    3)
        echo "Running: ADB root"
        adb root
        # Копируем скрипт на устройство
        adb push "$0" /data/local/tmp/frp-wipe.sh
        adb shell "sh /data/local/tmp/frp-wipe.sh internal && rm -f /data/local/tmp/frp-wipe.sh"
        exit
        ;;
    4)
        echo "Running: ADB shell + su"
        # Копируем скрипт на устройство во временную директорию
        adb push "$0" /data/local/tmp/frp-wipe.sh
        # Запускаем с правами root и удаляем после выполнения
        adb shell "su -c 'sh /data/local/tmp/frp-wipe.sh internal && rm -f /data/local/tmp/frp-wipe.sh'"
        exit
        ;;
    5)
        echo "Running: Direct root mode"
        # Проверяем root и запускаем основную функцию
        if [ "$(whoami)" != "root" ]; then
            echo "ERROR: Need root access!"
            exit 1
        fi
        main_wipe
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac
