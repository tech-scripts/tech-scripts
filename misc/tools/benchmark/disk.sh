#!/bin/bash

measure_write_speed() {
    local disk=$1
    echo "Измерение скорости записи на диск $disk..."
    if ! touch "$disk/testfile" 2>/dev/null; then
        echo "Ошибка: Невозможно создать файл в $disk. Проверьте права доступа."
        return
    fi
    write_speed=$(dd if=/dev/zero of="$disk/testfile" bs=1G count=1 oflag=direct 2>&1 | grep -oP '\d+\.\d+ [GM]B/s')
    if [ -z "$write_speed" ]; then
        echo "Ошибка при измерении скорости записи."
    else
        echo "Скорость записи: $write_speed"
    fi
    rm -f "$disk/testfile"
}

measure_read_speed() {
    local disk=$1
    echo "Измерение скорости чтения с диска $disk..."
    if [ ! -f "$disk/testfile" ]; then
        echo "Ошибка: Тестовый файл не найден в $disk."
        return
    fi
    read_speed=$(dd if="$disk/testfile" of=/dev/null bs=1G iflag=direct 2>&1 | grep -oP '\d+\.\d+ [GM]B/s')
    if [ -z "$read_speed" ]; then
        echo "Ошибка при измерении скорости чтения."
    else
        echo "Скорость чтения: $read_speed"
    fi
}

if whiptail --title "Замер диска" --yesno "Хотите сделать замер диска?" 10 60; then
    current_disk="$HOME"
    disks=$(df -h --output=target | tail -n +2 | grep -vE '^(/dev|/run|/sys|/proc|/tmp|/var)')
    disks="Текущий диск ($current_disk)\n$disks"

    # Преобразуем список дисков в массив
    mapfile -t disk_array <<< "$(echo -e "$disks")"

    # Формируем список для whiptail
    whiptail_list=()
    for i in "${!disk_array[@]}"; do
        whiptail_list+=("$((i+1))" "${disk_array[$i]}")
    done

    selected_index=$(whiptail --title "Выбор диска" --menu "Выберите диск для замера:" 15 60 4 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_index" ]; then
        whiptail --title "Ошибка" --msgbox "Диск не выбран." 10 60
        exit 1
    fi

    # Получаем выбранный диск по индексу
    selected_disk="${disk_array[$((selected_index-1))]}"

    # Если выбран "Текущий диск", используем $HOME
    if [[ "$selected_disk" == "Текущий диск ($current_disk)" ]]; then
        selected_disk="$current_disk"
    fi

    echo "Выбранный диск: $selected_disk"  # Отладочное сообщение

    # Проверка доступности диска
    if [ ! -d "$selected_disk" ]; then
        whiptail --title "Ошибка" --msgbox "Директория $selected_disk недоступна." 10 60
        exit 1
    fi

    # Проверка прав доступа
    if ! touch "$selected_disk/testfile" 2>/dev/null; then
        whiptail --title "Ошибка" --msgbox "Нет прав на запись в $selected_disk." 10 60
        exit 1
    fi
    rm -f "$selected_disk/testfile"

    measure_write_speed "$selected_disk"
    measure_read_speed "$selected_disk"

    whiptail --title "Результаты" --msgbox "С
