#!/bin/bash

LANG_FILE="/etc/tech-scripts/choose.conf"
source $LANG_FILE

if [[ $lang == "Русский" ]]; then
    MSG_WELCOME="Добро пожаловать в управление Proxmox"
    MSG_CHOICE="Выберите тип управления:"
    MSG_TYPE_LXC="LXC"
    MSG_TYPE_VM="VM"
    MSG_ID="Введите ID:"
    MSG_NAME="Введите название:"
    MSG_ACTION="Выберите действие:"
    MSG_CONFIRM_DELETE="Вы уверены, что хотите удалить"
    MSG_SUCCESS="Успешно выполнено"
    MSG_ERROR="Ошибка"
    MSG_PRIVILEGES="Выберите привилегии для VM:"
else
    MSG_WELCOME="Welcome to Proxmox management"
    MSG_CHOICE="Choose management type:"
    MSG_TYPE_LXC="LXC"
    MSG_TYPE_VM="VM"
    MSG_ID="Enter the ID:"
    MSG_NAME="Enter the name:"
    MSG_ACTION="Choose an action:"
    MSG_CONFIRM_DELETE="Are you sure you want to delete"
    MSG_SUCCESS="Successfully executed"
    MSG_ERROR="Error"
    MSG_PRIVILEGES="Select privileges for the VM:"
fi

dialog --title "$MSG_WELCOME" --msgbox "$MSG_CHOICE" 10 30

MANAGE_TYPE=$(dialog --menu "$MSG_CHOICE" 15 50 2 \
    1 "$MSG_TYPE_LXC" \
    2 "$MSG_TYPE_VM" 3>&1 1>&2 2>&3)

ID=$(dialog --inputbox "$MSG_ID" 8 40 3>&1 1>&2 2>&3)
NAME=$(dialog --inputbox "$MSG_NAME" 8 40 3>&1 1>&2 2>&3)

while true; do
    ACTION=$(dialog --menu "$MSG_ACTION" 15 50 6 \
    1 "Включить" \
    2 "Выключить" \
    3 "Перезагрузить" \
    4 "Открыть конфигурационный файл" \
    5 "Удалить" \
    6 "Выход" 3>&1 1>&2 2>&3)

    case $ACTION in
        1)
            if [[ $MANAGE_TYPE == 1 ]]; then
                pct start $ID && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            else
                qm start $ID && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            fi
            ;;
        2)
            if [[ $MANAGE_TYPE == 1 ]]; then
                pct stop $ID && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            else
                qm stop $ID && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            fi
            ;;
        3)
            if [[ $MANAGE_TYPE == 1 ]]; then
                pct reboot $ID && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            else
                qm reboot $ID && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            fi
            ;;
        4)
            if [[ $MANAGE_TYPE == 1 ]]; then
                nano /etc/pve/lxc/$ID.conf
            else
                nano /etc/pve/qemu-server/$ID.conf
            fi
            ;;
        5)
            if dialog --yesno "$MSG_CONFIRM_DELETE $NAME?" 7 60; then
                if [[ $MANAGE_TYPE == 1 ]]; then
                    pct stop $ID
                    pct destroy $ID && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                else
                    qm stop $ID
                    qm del $ID && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                fi
            fi
            ;;
        6)
            break
            ;;
        *)
            dialog --msgbox "$MSG_ERROR" 5 30
            ;;
    esac
done
