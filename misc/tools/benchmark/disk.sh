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
    disks=$(df -h --output=target | tail -n +2 | grep -vE '^(/dev|/run|/sys|/proc|/tmp|/var)')
    disks="Текущий диск ($current_disk)\n$disks"

    selected_disk=$(whiptail --title "Выбор диска" --menu "Выберите диск для замера:" 15 60 4 $(echo -e "$disks" | awk '{print NR, $0}') 3>&1 1>&2 2>&3)

    if [ -z "$selected_disk" ]; then
        whiptail --title "Ошибка" --msgbox "Диск не выбран." 10 60
        exit 1
    fi

    if [[ "$selected_disk" == "Текущий диск ($current_disk)" ]]; then
        selected_disk="$current_disk"
    fi

    measure_write_speed "$selected_disk"
    measure_read_speed "$selected_disk"

    whiptail --title "Результаты" --msgbox "Скорость записи: $write_speed\nСкорость чтения: $read_speed" 12 60
else
    whiptail --title "Отмена" --msgbox "Замер диска отменен." 10 60
fi
