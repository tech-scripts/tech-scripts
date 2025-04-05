#!/bin/bash

LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d':' -f2 | tr -d ' ')

if [ "$LANG_CONF" = "Русский" ]; then
    PCT_NOT_FOUND="Утилита pct не найдена! Убедитесь, что Proxmox установлен."
    DIALOG_NOT_FOUND="Утилита dialog не найдена! Убедитесь, что dialog установлен."
    NO_VMS="Нет доступных виртуальных машин!"
    SELECT_VM="Выберите виртуальную машину"
    CONFIG_NOT_FOUND="Конфигурационный файл не найден!"
else
    PCT_NOT_FOUND="Utility pct not found! Make sure Proxmox is installed."
    DIALOG_NOT_FOUND="Utility dialog not found! Make sure dialog is installed."
    NO_VMS="No available virtual machines!"
    SELECT_VM="Select virtual machine"
    CONFIG_NOT_FOUND="Configuration file not found!"
fi

if ! command -v qm &> /dev/null; then
    echo "$PCT_NOT_FOUND"
    exit 1
fi

if ! command -v dialog &> /dev/null; then
    echo "$DIALOG_NOT_FOUND"
    exit 1
fi

vms=$(qm list | awk 'NR>1 {print $1, $2}')

if [ -z "$vms" ]; then
    dialog --msgbox "$NO_VMS" 5 40
    exit 1
fi

options=()
while read -r vm_id vm_name; do
    options+=("$vm_id" "$vm_name")
done <<< "$vms"

selected_vm_id=$(dialog --title "$SELECT_VM" --menu "Выберите виртуальную машину для редактирования:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

exit_status=$?
if [ $exit_status != 0 ]; then
    clear
    exit
fi

config_file="/etc/pve/qemu-server/$selected_vm_id.conf"
if [ -f "$config_file" ]; then
    nano "$config_file"
else
    dialog --msgbox "$CONFIG_NOT_FOUND" 5 40
fi
