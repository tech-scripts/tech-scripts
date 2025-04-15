#!/bin/bash

measure_write_speed() {
    local disk=$1
    echo "Измерение скорости записи на диск $disk..."
    write_speed=$(dd if=/dev/zero of=$disk/testfile bs=1G count=1 oflag=direct 2>&1 | grep -oP '\d+\.\d+ [GM]B/s')
    echo "Скорость записи: $write_speed"
    rm -f $disk/testfile
}

measure_read_speed() {
    local disk=$1
    echo "Измерение скорости чтения с диска $disk..."
    read_speed=$(dd if=$disk/testfile of=/dev/null bs=1G iflag=direct 2>&1 | grep -oP '\d+\.\d+ [GM]B/s')
    echo "Скорость чтения: $read_speed"
}

if whiptail --title "Замер диска" --yesno "Хотите сделать замер диска?" 10 60; then
    current_disk="$HOME"
    whiptail --title "Текущий диск" --msgbox "Текущий диск для замера: $current_disk" 10 60

    measure_write_speed "$current_disk"
    measure_read_speed "$current_disk"

    whiptail --title "Результаты" --msgbox "Скорость записи: $write_speed\nСкорость чтения: $read_speed" 12 60
else
    whiptail --title "Отмена" --msgbox "Замер диска отменен." 10 60
fi
