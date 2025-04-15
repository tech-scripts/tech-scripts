#!/bin/bash

measure_write_speed() {
    local temp_file="$1/testfile"
    echo "Измерение скорости записи на $1... файл $temp_file"
    write_speed=$(dd if=/dev/zero of="$temp_file" bs=1G count=1 oflag=direct 2>&1 | grep -o '[0-9.]* [A-Z]*' | head -n 1)
    echo "Скорость записи: $write_speed"
}

measure_read_speed() {
    local temp_file="$1/testfile"
    echo "Создание тестового файла для чтения..."
    dd if=/dev/zero of="$temp_file" bs=1G count=1 oflag=direct > /dev/null 2>&1
    echo "Измерение скорости чтения на $1..."
    read_speed=$(dd if="$temp_file" of=/dev/null bs=1G count=1 iflag=direct 2>&1 | grep -o '[0-9.]* [A-Z]*' | head -n 1)
    echo "Скорость чтения: $read_speed"
    rm -f "$temp_file"
}

if (whiptail --title "Замер диска" --yesno "Вы хотите сделать замер диска?" 10 60); then
    disks=("Домашняя директория" "$HOME" "/mnt" "/media")
    disk_choices=()

    for dir in "${disks[@]}"; do
        if [[ "$dir" == "Домашняя директория" ]]; then
            disk_choices+=("$HOME" "$dir")
        else
            for disk in "$dir"/*; do
                if [ -d "$disk" ]; then
                    disk_choices+=("$disk" "$disk")
                fi
            done
        fi
    done

    selected_disk=$(whiptail --title "Выбор диска" --menu "Выберите диск для замера:" 15 60 4 "${disk_choices[@]}" 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
        measure_write_speed "$selected_disk"
        measure_read_speed "$selected_disk"
    else
        echo "Выход из программы."
    fi
else
    echo "Выход из программы."
fi
