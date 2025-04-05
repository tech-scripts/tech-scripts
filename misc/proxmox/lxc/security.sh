#!/bin/bash

LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d':' -f2 | tr -d ' ')
LANG_FILE="/etc/tech-scripts/choose.conf"
source $LANG_FILE

if [ "$LANG_CONF" = "Русский" ]; then
    DIALOG_NOT_FOUND="Утилита dialog не установлена. Установите её с помощью команды: sudo apt install dialog"
    PCT_NOT_FOUND="Утилита pct не найдена. Убедитесь, что Proxmox установлен."
    NO_CONTAINERS="Нет доступных LXC-контейнеров!"
    SELECT_CONTAINER="Выберите контейнер"
    SELECT_ACTION="Выберите действие"
    MSG_WELCOME="Добро пожаловать в управление Proxmox"
    MSG_CHOICE="Выберите тип управления:"
    MSG_TYPE_LXC="LXC"
    MSG_TYPE_VM="VM"
    MSG_ID="Введите ID:"
    MSG_NAME="Введите название:"
    MSG_CONFIRM_DELETE="Вы уверены, что хотите удалить"
    MSG_SUCCESS="Успешно выполнено"
    MSG_ERROR="Ошибка"
else
    DIALOG_NOT_FOUND="Utility dialog not found. Install it with: sudo apt install dialog"
    PCT_NOT_FOUND="Utility pct not found. Make sure Proxmox is installed."
    NO_CONTAINERS="No available LXC containers!"
    SELECT_CONTAINER="Select container"
    SELECT_ACTION="Select action"
    MSG_WELCOME="Welcome to Proxmox management"
    MSG_CHOICE="Choose management type:"
    MSG_TYPE_LXC="LXC"
    MSG_TYPE_VM="VM"
    MSG_ID="Enter the ID:"
    MSG_NAME="Enter the name:"
    MSG_CONFIRM_DELETE="Are you sure you want to delete"
    MSG_SUCCESS="Successfully executed"
    MSG_ERROR="Error"
fi

if ! command -v dialog &> /dev/null; then
    echo "$DIALOG_NOT_FOUND"
    exit 1
fi

if ! command -v pct &> /dev/null; then
    echo "$PCT_NOT_FOUND"
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

dialog --title "$MSG_WELCOME" --msgbox "$MSG_CHOICE" 10 30

selected_container_id=$(dialog --title "$SELECT_CONTAINER" --menu "$SELECT_CONTAINER:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

if [ $? != 0 ]; then
    clear
    exit
fi

ID=$(dialog --inputbox "$MSG_ID" 8 40 3>&1 1>&2 2>&3)
NAME=$(dialog --inputbox "$MSG_NAME" 8 40 3>&1 1>&2 2>&3)

MANAGE_TYPE=$(dialog --menu "$MSG_CHOICE" 15 50 2 \
    1 "$MSG_TYPE_LXC" \
    2 "$MSG_TYPE_VM" 3>&1 1>&2 2>&3)

if [ $? != 0 ]; then
    clear
    exit
fi

while true; do
    ACTION=$(dialog --title "$SELECT_ACTION" --menu "$SELECT_ACTION" 15 50 5 \
        1 "Включить" \
        2 "Выключить" \
        3 "Перезагрузить" \
        4 "Открыть конфигурационный файл" \
        5 "Удалить" \
        6 "Выход" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        clear
        exit
    fi

    case $ACTION in
        1)
            if [[ $MANAGE_TYPE == 1 ]]; then
                pct start "$selected_container_id" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            else
                qm start "$ID" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            fi
            ;;
        2)
            if [[ $MANAGE_TYPE == 1 ]]; then
                pct stop "$selected_container_id" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            else
                qm stop "$ID" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            fi
            ;;
        3)
            if [[ $MANAGE_TYPE == 1 ]]; then
                pct reboot "$selected_container_id" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            else
                qm reboot "$ID" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
            fi
            ;;
        4)
            if [[ $MANAGE_TYPE == 1 ]]; then
                nano "/etc/pve/lxc/$selected_container_id.conf"
            else
                nano "/etc/pve/qemu-server/$ID.conf"
            fi
            ;;
        5)
            if dialog --yesno "$MSG_CONFIRM_DELETE $NAME?" 7 60; then
                if [[ $MANAGE_TYPE == 1 ]]; then
                    pct stop "$selected_container_id"
                    pct destroy "$selected_container_id" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                else
                    qm stop "$ID"
                    qm del "$ID" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                fi
            fi
            ;;
        6)
            clear
            exit 0
            ;;
        *)
            dialog --msgbox "$MSG_ERROR" 5 30
            ;;
    esac

    if dialog --title "Продолжить?" --yesno "$CONTINUE" 5 40; then
        continue
    else
        clear
        exit 0
    fi
done
