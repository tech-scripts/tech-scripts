#!/bin/bash

LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d':' -f2 | tr -d ' ')

if [ "$LANG_CONF" = "Русский" ]; then
    PCT_NOT_FOUND="Утилита pct не найдена! Убедитесь, что Proxmox установлен."
    DIALOG_NOT_FOUND="Утилита dialog не найдена! Убедитесь, что dialog установлен."
    NO_CONTAINERS="Нет доступных LXC контейнеров!"
    SELECT_CONTAINER="Выберите LXC контейнер"
    CONFIG_NOT_FOUND="Конфигурационный файл не найден!"
else
    PCT_NOT_FOUND="Utility pct not found! Make sure Proxmox is installed."
    DIALOG_NOT_FOUND="Utility dialog not found! Make sure dialog is installed."
    NO_CONTAINERS="No available LXC containers!"
    SELECT_CONTAINER="Select LXC container"
    CONFIG_NOT_FOUND="Configuration file not found!"
fi

if ! command -v pct &> /dev/null; then
    echo "$PCT_NOT_FOUND"
    exit 1
fi

if ! command -v dialog &> /dev/null; then
    echo "$DIALOG_NOT_FOUND"
    exit 1
fi

containers=$(pct list | awk 'NR>1 {print $1, $3}')

if [ -z "$containers" ]; then
    dialog --msgbox "$NO_CONTAINERS" 5 40
    exit 1
fi

options=()
while read -r container_id container_name; do
    options+=("$container_id" "$container_name")
done <<< "$containers"

selected_container_id=$(dialog --title "$SELECT_CONTAINER" --menu "Выберите контейнер для редактирования:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

exit_status=$?
if [ $exit_status != 0 ]; then
    clear
    exit
fi

config_file="/etc/pve/lxc/$selected_container_id.conf"
if [ -f "$config_file" ]; then
    nano "$config_file"
else
    dialog --msgbox "$CONFIG_NOT_FOUND" 5 40
fi
