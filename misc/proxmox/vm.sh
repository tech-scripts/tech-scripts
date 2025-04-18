#!/bin/bash

CONFIG_FILE="/etc/tech-scripts/choose.conf"

LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)
EDITOR=$(grep '^editor:' "$CONFIG_FILE" | cut -d ' ' -f 2)

if [ "$LANGUAGE" = "Русский" ]; then
    QM_NOT_FOUND="Утилита qm не найдена. Убедитесь, что Proxmox установлен!"
    NO_VMS="Нет доступных виртуальных машин!"
    SELECT_VM="Выберите виртуальную машину"
    SELECT_ACTION="Выберите действие"
    MSG_CONFIRM_DELETE="Вы уверены, что хотите удалить"
    MSG_ERROR="Ошибка"
    CONTINUE="Продолжить работу с текущей виртуальной машиной?"
else
    QM_NOT_FOUND="Utility qm not found. Make sure Proxmox is installed!"
    NO_VMS="No available virtual machines!"
    SELECT_VM="Select virtual machine"
    SELECT_ACTION="Select action"
    MSG_CONFIRM_DELETE="Are you sure you want to delete"
    MSG_ERROR="Error"
    CONTINUE="Continue working with the current virtual machine?"
fi

if ! command -v qm &> /dev/null; then
    echo ""
    echo "$QM_NOT_FOUND"
    echo ""
    exit 1
fi

declare -a VMS_CACHE

get_vms() {
    if [ ${#VMS_CACHE[@]} -eq 0 ]; then
        while read -r vm_id vm_name; do
            VMS_CACHE+=("$vm_id" "$vm_name")
        done < <(qm list | awk 'NR>1 {print $1, $2}' | sort -n)
    fi
}

show_message() {
    local msg="$1"
    whiptail --msgbox "$msg" 7 30
}

while true; do
    get_vms

    if [ ${#VMS_CACHE[@]} -eq 0 ]; then
        echo ""
        echo "$NO_VMS"
        echo ""
        exit 1
    fi

    selected_vm_id=$(whiptail --title "$SELECT_VM" --menu "" 15 50 8 "${VMS_CACHE[@]}" 3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
        exit 0
    fi

    while true; do
        if [ "$LANG_CONF" = "Русский" ]; then
            ACTION=$(whiptail --title "$SELECT_ACTION" --menu "$SELECT_ACTION" 15 50 8 \
                1 "Включить" \
                2 "Выключить" \
                3 "Перезагрузить" \
                4 "Открыть конфигурационный файл" \
                5 "Удалить" \
                6 "Приостановить" \
                7 "Возобновить" \
                8 "Консоль" \
                9 "Назад" 3>&1 1>&2 2>&3)
        else
            ACTION=$(whiptail --title "$SELECT_ACTION" --menu "$SELECT_ACTION" 15 50 8 \
                1 "Start" \
                2 "Stop" \
                3 "Reboot" \
                4 "Open configuration file" \
                5 "Destroy" \
                6 "Suspend" \
                7 "Resume" \
                8 "Console" \
                9 "Back" 3>&1 1>&2 2>&3)
        fi

        if [ $? != 0 ]; then
            exit 0
        fi

        case $ACTION in
            1) qm start "$selected_vm_id" ;;
            2) qm stop "$selected_vm_id" ;;
            3) qm reboot "$selected_vm_id" ;;
            4) $EDITOR "/etc/pve/qemu-server/$selected_vm_id.conf" ;;
            5)
                if whiptail --yesno "$MSG_CONFIRM_DELETE $selected_vm_id?" 7 60; then
                    qm stop "$selected_vm_id"
                    qm destroy "$selected_vm_id"
                fi
                ;;
            6) qm suspend "$selected_vm_id" ;;
            7) qm resume "$selected_vm_id" ;;
            8) qm terminal "$selected_vm_id" ;;
            9) break ;;
            *) show_message "$MSG_ERROR" ;;
        esac

        if ! whiptail --title "$SELECT_ACTION" --yesno "$CONTINUE" 7 50; then
            break
        fi
    done
done
