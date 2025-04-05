#!/bin/bash

LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d':' -f2 | tr -d ' ')
CONFIG_FILE="/etc/tech-scripts/choose.conf"

if [ -f "$CONFIG_FILE" ]; then
    LANG_CONF=$(grep '^lang:' "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ')
else
    LANG_CONF="English"
fi

if [ "$LANG_CONF" = "Русский" ]; then
    DIALOG_NOT_FOUND="Утилита dialog не установлена. Установите её с помощью команды: sudo apt install dialog"
    PCT_NOT_FOUND="Утилита pct не найдена. Убедитесь, что Proxmox установлен."
    NO_CONTAINERS="Нет доступных LXC-контейнеров!"
    SELECT_CONTAINER="Выберите контейнер"
    SELECT_ACTION="Выберите действие"
    MSG_CONFIRM_DELETE="Вы уверены, что хотите удалить"
    MSG_SUCCESS="Успешно выполнено"
    MSG_ERROR="Ошибка"
    MSG_LOCK="Контейнер заблокирован"
    MSG_UNLOCK="Контейнер разблокирован"
    CONTINUE="Продолжить?"
else
    DIALOG_NOT_FOUND="Utility dialog not found. Install it with: sudo apt install dialog"
    PCT_NOT_FOUND="Utility pct not found. Make sure Proxmox is installed."
    NO_CONTAINERS="No available LXC containers!"
    SELECT_CONTAINER="Select container"
    SELECT_ACTION="Select action"
    MSG_CONFIRM_DELETE="Are you sure you want to delete"
    MSG_SUCCESS="Successfully executed"
    MSG_ERROR="Error"
    MSG_LOCK="Container locked"
    MSG_UNLOCK="Container unlocked"
    CONTINUE="Continue?"
fi

# Проверка наличия утилиты dialog
if ! command -v dialog &> /dev/null; then
    echo "$DIALOG_NOT_FOUND"
    exit 1
fi

# Проверка наличия утилиты pct
if ! command -v pct &> /dev/null; then
    echo "$PCT_NOT_FOUND"
    exit 1
fi

# Основной цикл меню действий
while true; do
    # Получение списка контейнеров
    containers=$(pct list | awk 'NR>1 {print $1, $3}')

    # Проверка наличия контейнеров
    if [ -z "$containers" ]; then
        dialog --msgbox "$NO_CONTAINERS" 5 40
        exit 1
    fi

    # Формирование списка опций для выбора контейнера
    options=()
    while read -r container_id container_name; do
        options+=("$container_id" "$container_name")
    done <<< "$containers"

    # Основное меню действий
    while true; do
        selected_container_id=$(dialog --title "$SELECT_CONTAINER" --menu "$SELECT_CONTAINER:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)
        if [ $? != 0 ]; then
            clear
            exit
        fi
        
        if [ "$LANG_CONF" = "Русский" ]; then
            ACTION=$(dialog --title "$SELECT_ACTION" --menu "$SELECT_ACTION" 15 50 8 \
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
            ACTION=$(dialog --title "$SELECT_ACTION" --menu "$SELECT_ACTION" 15 50 8 \
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
            clear
            exit
        fi

        # Обработка выбранного действия
        case $ACTION in
            1)
                pct start "$selected_container_id" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                ;;
            2)
                pct stop "$selected_container_id" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                ;;
            3)
                pct reboot "$selected_container_id" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                ;;
            4)
                nano "/etc/pve/lxc/$selected_container_id.conf"
                ;;
            5)
                if dialog --yesno "$MSG_CONFIRM_DELETE $selected_container_id?" 7 60; then
                    pct stop "$selected_container_id"
                    pct destroy "$selected_container_id" && dialog --msgbox "$MSG_SUCCESS" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                fi
                ;;
            6)
                pct unlock "$selected_container_id" && dialog --msgbox "$MSG_LOCK" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                ;;
            7)
                pct suspend "$selected_container_id" && dialog --msgbox "$MSG_UNLOCK" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                ;;
            8)
                pct resume "$selected_container_id" && dialog --msgbox "$MSG_UNLOCK" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                ;;
            9)
                pct console "$selected_container_id" && dialog --msgbox "$MSG_UNLOCK" 5 30 || dialog --msgbox "$MSG_ERROR" 5 30
                ;;
            10)
                clear
                exit 0
                ;;
            *)
                dialog --msgbox "$MSG_ERROR" 5 30
                ;;
        esac

        # Запрос на продолжение
        if dialog --title "$CONTINUE" --yesno "$CONTINUE" 5 40; then
            continue
        else
            break
            exit 0
        fi
    done
done
