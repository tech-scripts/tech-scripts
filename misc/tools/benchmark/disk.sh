#!/bin/bash

FILE_SIZE="1G"
LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANGUAGE" == "Русский" ]; then
    msg_select="Выберите директорию"
    msg_speed_write="Скорость записи:"
    msg_speed_read="Скорость чтения:"
    msg_time_write="Время записи:"
    msg_time_read="Время чтения:"
    msg_failed="Не удалось измерить скорость"
    local_dir="домашняя директория"
    remote_dir="удаленная директория"
    msg_selected_dir="Выбранная директория:"
else
    msg_select="Select a directory"
    msg_speed_write="Write speed:"
    msg_speed_read="Read speed:"
    msg_time_write="Write time:"
    msg_time_read="Read time:"
    msg_failed="Failed to measure speed"
    local_dir="local directory"
    remote_dir="remote directory"
    msg_selected_dir="Selected directory:"
fi

disk_choices=()

root_device=$(df / | awk 'NR==2 {print $1}')
root_disk=$(echo "$root_device" | sed 's|/dev/||' | sed 's/p[0-9]*$//')
disk_choices+=("$root_disk" "/")

while IFS= read -r line; do
    device=$(echo "$line" | awk '{print $1}' | sed 's|/dev/||' | sed 's/p[0-9]*$//')
    mount_point=$(echo "$line" | awk '{print $2}')
    
    if [[ -n "$mount_point" && "$mount_point" != "/boot/efi" && "$mount_point" != "[SWAP]" ]]; then
        if [[ "$device" != "$root_disk" ]]; then
            disk_choices+=("$device" "$mount_point")
        fi
    fi
done < <(lsblk -o NAME,MOUNTPOINT -n -l | grep -v '^\s*$' | grep -v '^/')

if [ ${#disk_choices[@]} -eq 0 ]; then
    echo "Нет доступных точек монтирования для выбора."
    exit 1
fi

menu_items=()
for ((i=0; i<${#disk_choices[@]}; i+=2)); do
    menu_items+=("${disk_choices[i]}" "${disk_choices[i+1]}")
done

selected_disk=$(whiptail --title "$msg_select" --menu "" 15 60 4 "${menu_items[@]}" 3>&1 1>&2 2>&3)

if [ -z "$selected_disk" ]; then
    exit 0
fi

selected_mount_point=""
for ((i=0; i<${#disk_choices[@]}; i+=2)); do
    if [[ "${disk_choices[i]}" == "$selected_disk" ]]; then
        selected_mount_point="${disk_choices[i+1]}"
        break
    fi
done

temp_file="$selected_mount_point/testfile"

output=$(dd if=/dev/zero of="$temp_file" bs="$FILE_SIZE" count=1 oflag=direct 2>&1)
write_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
write_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$msg_failed")

output=$(dd if="$temp_file" of=/dev/null bs="$FILE_SIZE" count=1 iflag=direct 2>&1)
read_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
read_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$msg_failed")

echo ""
echo "$msg_selected_dir $selected_mount_point"
echo ""
echo "$msg_speed_write $write_speed"
echo "$msg_time_write $write_time"
echo ""
echo "$msg_speed_read $read_speed"
echo "$msg_time_read $read_time"
echo ""

rm -f "$temp_file"
