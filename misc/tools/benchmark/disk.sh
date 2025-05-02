#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$(pwd)

source $USER_DIR/etc/tech-scripts/source.sh

disk_choices=()
system_disk=$(df / | awk 'NR==2 {print $1}' | sed 's|/dev/||' | sed 's/[0-9]*$//')
home_path="$HOME"
disk_choices+=("$system_disk" "$home_path")

while IFS= read -r line; do
    device=$(echo "$line" | awk '{print $1}' | sed 's|/dev/||' | sed 's/[0-9]*$//')
    mount_point=$(echo "$line" | awk '{print $6}')
    
    if [[ -n "$mount_point" && "$mount_point" != "/boot" && "$mount_point" != "/boot/efi" && "$mount_point" != "[SWAP]" && "$mount_point" != "/" && ! "$device" =~ zram ]]; then
        if [[ "$device" != "$system_disk" ]]; then
            disk_choices+=("$device" "$mount_point")
        fi
    fi
done < <(df -h --output=source,target | tail -n +2)

if [ ${#disk_choices[@]} -eq 0 ]; then
    echo "$MSG_NO_MOUNTS_DISK"
    exit 1
fi

menu_items=()
for ((i=0; i<${#disk_choices[@]}; i+=2)); do
    menu_items+=("${disk_choices[i]}" "${disk_choices[i+1]}")
done

selected_disk=$(whiptail --title "$MSG_SELECT_DISK" --menu "" 15 60 4 "${menu_items[@]}" 3>&1 1>&2 2>&3)

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
write_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$MSG_FAILED_DISK")

output=$(dd if="$temp_file" of=/dev/null bs="$FILE_SIZE" count=1 iflag=direct 2>&1)
read_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
read_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$MSG_FAILED_DISK")

echo ""
echo -e "$MSG_SELECTED_DIR_DISK \e[38;2;160;160;160m$selected_mount_point\e[0m"
echo ""
echo -e "$MSG_SPEED_WRITE_DISK $(echo "$write_speed" | sed 's/[0-9]\+/\\e[38;2;160;160;160m&\\e[0m/g')"
echo -e "$MSG_TIME_WRITE_DISK $(echo "$write_time" | sed 's/[0-9]\+/\\e[38;2;160;160;160m&\\e[0m/g')"
echo ""
echo -e "$MSG_SPEED_READ_DISK $(echo "$read_speed" | sed 's/[0-9]\+/\\e[38;2;160;160;160m&\\e[0m/g')"
echo -e "$MSG_TIME_READ_DISK $(echo "$read_time" | sed 's/[0-9]\+/\\e[38;2;160;160;160m&\\e[0m/g')"
echo ""

rm -f "$temp_file"
