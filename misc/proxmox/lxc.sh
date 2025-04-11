#!/bin/bash

CONFIG_FILE="/etc/tech-scripts/choose.conf"

LANG_CONF=$(grep '^lang:' "$CONFIG_FILE" | cut -d' ' -f2)
EDITOR=$(grep '^editor:' "$CONFIG_FILE" | cut -d ' ' -f 2)

if [ "$LANG_CONF" = "Русский" ]; then
    PCT_NOT_FOUND="Утилита pct не найдена. Убедитесь, что Proxmox установлен."
    NO_CONTAINERS="Нет доступных LXC-контейнеров!"
    SELECT_CONTAINER="Выберите контейнер"
    SELECT_ACTION="Выберите действие"
    MSG_CONFIRM_DELETE="Вы уверены, что хотите удалить"
    MSG_SUCCESS="Успешно выполнено"
    MSG_ERROR="Ошибка"
    MSG_LOCK="Контейнер заблокирован"
    MSG_UNLOCK="Контейнер разблокирован"
    CONTINUE="Продолжить работу с текущим контейнером?"
else
    PCT_NOT_FOUND="Utility pct not found. Make sure Proxmox is installed."
    NO_CONTAINERS="No available LXC containers!"
    SELECT_CONTAINER="Select container"
    SELECT_ACTION="Select action"
    MSG_CONFIRM_DELETE="Are you sure you want to delete"
    MSG_SUCCESS="Successfully executed"
    MSG_ERROR="Error"
    MSG_LOCK="Container locked"
    MSG_UNLOCK="Container unlocked"
    CONTINUE="Continue working with the current container?"
fi

if ! command -v pct &> /dev/null; then
    echo "$PCT_NOT_FOUND"
    exit 1
fi

get_containers() {
    if [ -z "$CACHED_CONTAINERS" ]; then
        CACHED_CONTAINERS=$(pct list | awk 'NR>1 {print $1, $3}')
    fi
    echo "$CACHED_CONTAINERS"
}

show_message() {
    local msg="$1"
    whiptail --msgbox "$msg" 7 30
}

while true; do
    containers=$(get_containers)

    if [ -z "$containers" ]; then
        show_message "$NO_CONTAINERS"
        exit 1
    fi

    options=()
    while read -r container_id container_name; do
        options+=("$container_id" "$container_name")
    done <<< "$containers"

    selected_container_id=$(whiptail --title "$SELECT_CONTAINER" --menu "" 15 50 8 "${options[@]}" 3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
        reset
        exit
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
                10 "Выход" 3>&1 1>&2 2>&3)
        else
            ACTION=$(whiptail --title "$SELECT_ACTION" --menu "$SELECT_ACTION" 15 50 8 \
                1 "Start" \
                2 "Stop" \
                3 "Reboot" \
                4 "Open configuration file" \
                5 "Destroy" \
                6 "Unlock" \
                7 "Suspend" \
                8 "Resume" \
                9 "Console" \
                10 "Exit" 3>&1 1>&2 2>&3)
        fi

        if [ $? != 0 ]; then
            break
        fi

        case $ACTION in
            1) pct start "$selected_container_id" && show_message "$MSG_SUCCESS" || show_message "$MSG_ERROR: Не удалось запустить контейнер" ;;
            2) pct stop "$selected_container_id" && show_message "$MSG_SUCCESS" || show_message "$MSG_ERROR: Не удалось остановить контейнер" ;;
            3) pct reboot "$selected_container_id" && show_message "$MSG_SUCCESS" || show_message "$MSG_ERROR: Не удалось перезагрузить контейнер" ;;
            4) $EDITOR "/etc/pve/lxc/$selected_container_id.conf" ;;
            5)
                if whiptail --yesno "$MSG_CONFIRM_DELETE $selected_container_id?" 7 60; then
                    pct stop "$selected_container_id"
                    pct destroy "$selected_container_id" && show_message "$MSG_SUCCESS" || show_message "$MSG_ERROR: Не удалось удалить контейнер"
                fi
                ;;
            6) pct unlock "$selected_container_id" && show_message "$MSG_LOCK" || show_message "$MSG_ERROR: Не удалось разблокировать контейнер" ;;
            7) pct suspend "$selected_container_id" && show_message "$MSG_UNLOCK" || show_message "$MSG_ERROR: Не удалось усыпить контейнер" ;;
            8) pct resume "$selected_container_id" && show_message "$MSG_UNLOCK" || show_message "$MSG_ERROR: Не удалось разбудить контейнер" ;;
            9) pct console "$selected_container_id" && show_message "$MSG_UNLOCK" || show_message "$MSG_ERROR: Не удалось открыть консоль" ;;
            10) reset; exit 0 ;;
            *) show_message "$MSG_ERROR" ;;
        esac

        if ! whiptail --title "" --yesno "$CONTINUE" 7 40; then
            break
        fi
    done
done
