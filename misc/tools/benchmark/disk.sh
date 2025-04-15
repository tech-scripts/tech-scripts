#!/bin/bash

measure_write_speed() {
    local temp_file="$1/testfile"
    echo "Измерение скорости записи на $1..."
    output=$(dd if=/dev/zero of="$temp_file" bs=1G count=1 oflag=direct 2>&1)
    
    write_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
    
    if echo "$output" | grep -q 'MB/s'; then
        write_speed=$(echo "$output" | grep -o '[0-9.]* MB/s' | head -n 1)
    elif echo "$output" | grep -q 'GB/s'; then
        write_speed=$(echo "$output" | grep -o '[0-9.]* GB/s' | head -n 1)
    else
        write_speed="Не удалось измерить скорость"
    fi

    echo "Скорость записи: $write_speed, Время записи: $write_time"
}

measure_read_speed() {
    local temp_file="$1/testfile"
    echo "Создание тестового файла для чтения..."
    dd if=/dev/zero of="$temp_file" bs=1G count=1 oflag=direct > /dev/null 2>&1
    echo "Измерение скорости чтения на $1..."
    output=$(dd if="$temp_file" of=/dev/null bs=1G count=1 iflag=direct 2>&1)
    
    read_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
    
    if echo "$output" | grep -q 'MB/s'; then
        read_speed=$(echo "$output" | grep -o '[0-9.]* MB/s' | head -n 1)
    elif echo "$output" | grep -q 'GB/s'; then
        read_speed=$(echo "$output" | grep -o '[0-9.]* GB/s' | head -n 1)
    else
        read_speed="Не удалось измерить скорость"
    fi

    echo "Скорость чтения: $read_speed, Время чтения: $read_time"
    rm -f "$temp_file"
}

if whiptail --title "Замер диска" --yesno "Вы хотите сделать замер диска?" 10 60; then
    disks=("$HOME" "/mnt" "/media")
    disk_choices=()

    for dir in "${disks[@]}"; do
        if [ -d "$dir" ]; then
            disk_choices+=("$dir" "$dir")
        fi
        for disk in "$dir"/*; do
            if [ -d "$disk" ]; then
                disk_choices+=("$disk" "$disk")
            fi
        done
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
