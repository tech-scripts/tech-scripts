#!/bin/bash

lang=$(grep 'lang:' /etc/tech-scripts/choose.conf | awk '{print $2}')
if [ "$lang" == "Русский" ]; then
    msg_measure="Вы хотите сделать замер диска?"
    msg_select="Выберите диск для замера:"
    msg_exit="Выход из программы."
    msg_write="Измерение скорости записи на"
    msg_read="Измерение скорости чтения на"
    msg_speed_write="Скорость записи:"
    msg_speed_read="Скорость чтения:"
    msg_time_write="Время записи:"
    msg_time_read="Время чтения:"
    msg_failed="Не удалось измерить скорость"
else
    msg_measure="Do you want to measure disk speed?"
    msg_select="Select a disk to measure:"
    msg_exit="Exiting the program."
    msg_write="Measuring write speed on"
    msg_read="Measuring read speed on"
    msg_speed_write="Write speed:"
    msg_speed_read="Read speed:"
    msg_time_write="Write time:"
    msg_time_read="Read time:"
    msg_failed="Failed to measure speed"
fi

if whiptail --title "Disk Measurement" --yesno "$msg_measure" 10 60; then
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

    selected_disk=$(whiptail --title "Disk Selection" --menu "$msg_select" 15 60 4 "${disk_choices[@]}" 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
        temp_file="$selected_disk/testfile"
        echo ""
        echo "$msg_write $selected_disk..."
        output=$(dd if=/dev/zero of="$temp_file" bs=1G count=1 oflag=direct 2>&1)
        write_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
        if echo "$output" | grep -q 'MB/s'; then
            write_speed=$(echo "$output" | grep -o '[0-9.]* MB/s' | head -n 1)
        elif echo "$output" | grep -q 'GB/s'; then
            write_speed=$(echo "$output" | grep -o '[0-9.]* GB/s' | head -n 1)
        else
            write_speed="$msg_failed"
        fi
        echo "$msg_read $selected_disk..."
        output=$(dd if="$temp_file" of=/dev/null bs=1G count=1 iflag=direct 2>&1)
        read_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
        if echo "$output" | grep -q 'MB/s'; then
            read_speed=$(echo "$output" | grep -o '[0-9.]* MB/s' | head -n 1)
        elif echo "$output" | grep -q 'GB/s'; then
            read_speed=$(echo "$output" | grep -o '[0-9.]* GB/s' | head -n 1)
        else
            read_speed="$msg_failed"
        fi
        echo ""
        echo "$msg_speed_write $write_speed"
        echo "$msg_time_write $write_time"
        echo ""
        echo "$msg_speed_read $read_speed"
        echo "$msg_time_read $read_time"
        echo ""
        rm -f "$temp_file"
    else
        echo "$msg_exit"
    fi
else
    echo "$msg_exit"
fi
