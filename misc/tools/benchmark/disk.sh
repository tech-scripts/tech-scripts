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
    local_dir="локальная директория"
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
while IFS= read -r line; do
    mount_point=$(echo "$line" | awk '{print $1}')
    device=$(echo "$line" | awk '{print $2}')
    
    # Фильтрация для исключения /boot, [SWAP] и /
    if [[ "$mount_point" != "/boot" && "$mount_point" != "/" && "$mount_point" != "[SWAP]" && -n "$mount_point" ]]; then
        # Определяем имя диска и путь
        if [[ "$mount_point" == "$HOME" ]]; then
            disk_choices+=("$device" "$local_dir")
        else
            disk_choices+=("$device" "$mount_point")
        fi
    fi
done < <(lsblk -o MOUNTPOINT,NAME -n -l | grep -v '^\s*$')

# Проверяем, что в списке есть элементы
if [ ${#disk_choices[@]} -eq 0 ]; then
    echo "Нет доступных точек монтирования для выбора."
    exit 1
fi

# Форматируем вывод для whiptail
formatted_choices=()
for ((i=0; i<${#disk_choices[@]}; i+=2)); do
    formatted_choices+=("${disk_choices[i]} ${disk_choices[i+1]}")
done

selected_disk=$(whiptail --title "$msg_select" --menu "" 15 60 4 "${formatted_choices[@]}" 3>&1 1>&2 2>&3)

if [ -z "$selected_disk" ]; then
    exit 0
fi

temp_file="$selected_disk/testfile"

output=$(dd if=/dev/zero of="$temp_file" bs="$FILE_SIZE" count=1 oflag=direct 2>&1)
write_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
write_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$msg_failed")

output=$(dd if="$temp_file" of=/dev/null bs="$FILE_SIZE" count=1 iflag=direct 2>&1)
read_time=$(echo "$output" | grep -o '[0-9.]* s' | head -n 1)
read_speed=$(echo "$output" | grep -o '[0-9.]* [MG]B/s' | head -n 1 || echo "$msg_failed")

echo ""
echo "$msg_selected_dir $selected_disk"
echo ""
echo "$msg_speed_write $write_speed"
echo "$msg_time_write $write_time"
echo ""
echo "$msg_speed_read $read_speed"
echo "$msg_time_read $read_time"
echo ""

rm -f "$temp_file"
