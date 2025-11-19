#!/usr/bin/env bash

echo "========================================"
echo "         FRP WIPE SCRIPT                "
echo "========================================"

check_root() {
    if [ "$(whoami)" != "root" ]; then
        echo "ERROR: Need root access!"
        echo "Please run with:"
        echo "  Termux: tsu OR su"
        echo "  ADB: adb root OR adb shell -> su"
        exit 1
    fi
}

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
        su -c "sh $0 root"
        exit
        ;;
    2)
        echo "Running: Termux + tsu"
        tsu -c "sh $0 root"
        exit
        ;;
    3)
        echo "Running: ADB root"
        adb root
        adb shell "sh $0 root"
        exit
        ;;
    4)
        echo "Running: ADB shell + su"
        adb shell "su -c 'sh $0 root'"
        exit
        ;;
    5)
        echo "Running: Direct root mode"
        check_root
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo "[1/4] Removing FRP files..."
rm -f /persist/property_persistent_space/*
rm -f /frp/frp.bin
rm -f /data/system/frp_secret
rm -f /persist/frp/
rm -f /mnt/vendor/persist/frp/
rm -f /efs/recovery/frp.dat
rm -f /efs/factoryapp/frp.dat
rm -f /nvdata/frp/frp.dat
rm -f /vendor/frp/
rm -f /persist/data/frp/
rm -f /cust/frp/
rm -f /metadata/frp/
rm -f /product/frp/
rm -f /system/frp/
rm -f /odm/frp/
rm -f /backup/frp/
rm -f /cache/frp/
rm -f /recovery/frp/

echo "[2/4] Clearing data partitions..."
rm -rf /data/vendor_ce/0/frp/
rm -rf /data/system_ce/0/frp/
rm -rf /data/misc_ce/0/frp/
rm -rf /data/user_de/0/com.google.android.gms/frp/
rm -rf /data/data/com.google.android.gms/files/frp/
rm -f /data/system/users/0/accounts_ce.db*
rm -f /data/system/users/0/settings_ce_global.xml

echo "[3/4] Wiping FRP blocks..."
dd if=/dev/zero of=/dev/block/bootdevice/by-name/frp bs=4096 2>/dev/null
dd if=/dev/zero of=/dev/block/bootdevice/by-name/misc bs=4096 2>/dev/null
dd if=/dev/zero of=/dev/block/bootdevice/by-name/PARAM bs=4096 2>/dev/null
dd if=/dev/zero of=/dev/block/bootdevice/by-name/oppodycnv bs=4096 2>/dev/null
dd if=/dev/zero of=/dev/block/platform/hi_mci.0/by-name/oeminfo bs=4096 2>/dev/null

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
