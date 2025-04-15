#!/bin/bash

CONFIG_FILE="/etc/tech-scripts/choose.conf"

LANG_CONF=$(grep '^lang:' "$CONFIG_FILE" | cut -d' ' -f2)
EDITOR=$(grep '^editor:' "$CONFIG_FILE" | cut -d ' ' -f 2)

if [ "$LANG_CONF" = "Русский" ]; then
    PCT_NOT_FOUND="Утилита pct не найдена. Убедитесь, что Proxmox установлен!"
    NO_CONTAINERS="Нет доступных LXC-контейнеров!"
    SELECT_CONTAINER="Выберите контейнер"
    SELECT_ACTION="Выберите действие"
    MSG_CONFIRM_DELETE="Вы уверены, что хотите удалить"
    MSG_ERROR="Ошибка"
    CONTINUE="Продолжить работу с текущим контейнером?"
else
    PCT_NOT_FOUND="Utility pct not found. Make sure Proxmox is installed!"
    NO_CONTAINERS="No available LXC containers!"
    SELECT_CONTAINER="Select container"
    SELECT_ACTION="Select action"
    MSG_CONFIRM_DELETE="Are you sure you want to delete"
    MSG_ERROR="Error"
    CONTINUE="Continue working with the current container?"
fi

if ! command -v pct &> /dev/null; then
    echo "$PCT_NOT_FOUND"
    exit 1
fi

declare -a CONTAINERS_CACHE

get_containers() {
    if [ ${#CONTAINERS_CACHE[@]} -eq 0 ]; then
        while read -r container_id container_name; do
            CONTAINERS_CACHE+=("$container_id" "$container_name")
        done < <(pct list | awk 'NR>1 {print $1, $3}' | sort -n)
    fi
}

show_message() {
    local msg="$1"
    whiptail --msgbox "$msg" 7 30
}

while true; do
    get_containers

    if [ ${#CONTAINERS_CACHE[@]} -eq 0 ]; then
        show_message "$NO_CONTAINERS"
        exit 1
    fi

    selected_container_id=$(whiptail --title "$SELECT_CONTAINER" --menu "" 15 50 8 "${CONTAINERS_CACHE[@]}" 3>&1 1>&2 2>&3)
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
                5 "Уничтожить" \
                6 "Разблокировать" \
                7 "Усыпить" \
                8 "Разбудить" \
                9 "Консоль" \
                10 "Назад" 3>&1 1>&2 2>&3)
        else
            ACTION=$(whiptail --title "$SELECT_ACTION" --menu "$SELECT_ACTION" 15 50 8 \
                1 "Start" \
                2 "Stop" \
                3 "Reboot" \
                4 "Open configuration file" \
                5 "Terminate" \
                6 "Unlock" \
                7 "Suspend" \
                8 "Resume" \
                9 "Console" \
                10 "Back" 3>&1 1>&2 2>&3)
        fi

        if [ $? != 0 ]; then
            exit 0
        fi

        case $ACTION in
            1) pct start "$selected_container_id" ;;
            2) pct stop "$selected_container_id" ;;
            3) pct reboot "$selected_container_id" ;;
            4) $EDITOR "/etc/pve/lxc/$selected_container_id.conf" ;;
            5)
                if whiptail --yesno "$MSG_CONFIRM_DELETE $selected_container_id?" 7 60; then
                    pct stop "$selected_container_id"
                    pct destroy "$selected_container_id"
                fi
                ;;
            6) pct unlock "$selected_container_id" ;;
            7) pct enter "$selected_container_id" ;;
            8) pct resume "$selected_container_id" ;;
            9) pct console "$selected_container_id" ;;
            10) break ;;
            *) show_message "$MSG_ERROR" ;;
        esac

        if ! whiptail --title "$SELECT_ACTION" --yesno "$CONTINUE" 7 50; then
            break
        fi
    done
done
