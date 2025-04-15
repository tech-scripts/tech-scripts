#!/bin/bash

block_size="3G"
lang=$(grep 'lang:' /etc/tech-scripts/choose.conf | awk '{print $2}')

if [ "$lang" == "Русский" ]; then
    msg_select="Выберите диск"
    msg_speed_write="Скорость записи:"
    msg_speed_read="Скорость чтения:"
    msg_time_write="Время записи:"
    msg_time_read="Время чтения:"
    msg_failed="Не удалось измерить скорость"
    local_disk="локальный диск"
    connected_disk="подключенный диск"
    msg_selected_disk="Выбранный диск:"
else
    msg_select="Select a disk"
    msg_speed_write="Write speed:"
    msg_speed_read="Read speed:"
    msg_time_write="Write time:"
    msg_time_read="Read time:"
    msg_failed="Failed to measure speed"
    local_disk="local Disk"
    connected_disk="connected Disk"
    msg_selected_disk="Selected disk:"
fi

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

selected_disk=$(whiptail --title "$msg_select" --menu "$msg_select" 15 60 4 "${disk_choices[@]}" 3>&1 1>&2 2>&3)

temp_file="$selected_disk/testfile"
output=$(dd if=/dev/zero of="$temp_file" bs="$block_size" count=1 oflag=direct 2>&1)
write_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
write_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$msg_failed")
output=$(dd if="$temp_file" of=/dev/null bs="$block_size" count=1 iflag=direct 2>&1)
read_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
read_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$msg_failed")
echo ""
echo "$msg_selected_disk $selected_disk"
echo ""
echo "$msg_speed_write $write_speed"
echo "$msg_time_write $write_time"
echo ""
echo "$msg_speed_read $read_speed"
echo "$msg_time_read $read_time"
echo ""
rm -f "$temp_file"
