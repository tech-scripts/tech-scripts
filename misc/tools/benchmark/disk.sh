#!/bin/bash

block_size="1G"
lang=$(grep 'lang:' /etc/tech-scripts/choose.conf | awk '{print $2}')

if [ "$lang" == "Русский" ]; then
    msg_measure="Вы хотите сделать замер диска?"
    msg_select="Выберите диск для замера:"
    msg_write="Измерение скорости записи в"
    msg_read="Измерение скорости чтения в"
    msg_speed_write="Скорость записи:"
    msg_speed_read="Скорость чтения:"
    msg_time_write="Время записи:"
    msg_time_read="Время чтения:"
    msg_failed="Не удалось измерить скорость"
    title_disk_selection="Выбор диска"
    title_disk_measurement="Замер диска"
    local_disk="локальный диск"
    connected_disk="подключенный диск"
else
    msg_measure="Do you want to measure disk speed?"
    msg_select="Select a disk to measure:"
    msg_write="Measuring write speed in"
    msg_read="Measuring read speed in"
    msg_speed_write="Write speed:"
    msg_speed_read="Read speed:"
    msg_time_write="Write time:"
    msg_time_read="Read time:"
    msg_failed="Failed to measure speed"
    title_disk_selection="Disk Selection"
    title_disk_measurement="Disk Measurement"
    local_disk="local Disk"
    connected_disk="connected Disk"
fi

if whiptail --title "$title_disk_measurement" --yesno "$msg_measure" 10 60; then
    disk_choices=("$HOME" "$local_disk")
    for dir in "/mnt" "/media"; do
        if [ -d "$dir" ]; then
            for disk in "$dir"/*; do
                if [ -d "$disk" ]; then
                    disk_choices+=("$disk" "$connected_disk")
                fi
            done
        fi
    done

    selected_disk=$(whiptail --title "$title_disk_selection" --menu "$msg_select" 15 60 4 "${disk_choices[@]}" 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
        temp_file="$selected_disk/testfile"
        output=$(dd if=/dev/zero of="$temp_file" bs="$block_size" count=1 oflag=direct 2>&1)
        echo ""
        write_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
        write_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$msg_failed")
        output=$(dd if="$temp_file" of=/dev/null bs="$block_size" count=1 iflag=direct 2>&1)
        read_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
        read_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$msg_failed")
        echo ""
        echo "$msg_speed_write $write_speed"
        echo "$msg_time_write $write_time"
        echo ""
        echo "$msg_speed_read $read_speed"
        echo "$msg_time_read $read_time"
        echo ""
        rm -f "$temp_file"
    fi
fi
