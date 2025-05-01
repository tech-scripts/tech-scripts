#!/bin/bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

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

write_output=$(sysbench fileio --file-total-size=10G --file-test-mode=write --time=10 run)
write_time=$(echo "$write_output" | grep 'total time:' | awk '{print $3}')
write_speed=$(echo "$write_output" | grep 'transferred' | awk '{print $3, $4}')

read_output=$(sysbench fileio --file-total-size=10G --file-test-mode=read --time=10 run)
read_time=$(echo "$read_output" | grep 'total time:' | awk '{print $3}')
read_speed=$(echo "$read_output" | grep 'transferred' | awk '{print $3, $4}')

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
