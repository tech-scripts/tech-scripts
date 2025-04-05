#!/bin/bash

# Проверка языка
LANG_FILE="/etc/tech-scripts/choose.conf"
if grep -q "lang: Русский" "$LANG_FILE"; then
    MSG_CHOOSE="Выберите, чем управлять:"
    MSG_LXC="LXC контейнеры"
    MSG_VM="VM машины"
    MSG_ID="Введите ID:"
    MSG_NAME="Введите название:"
    MSG_ACTION="Выберите действие:"
    MSG_START="Включение"
    MSG_STOP="Выключение"
    MSG_RESTART="Перезагрузка"
    MSG_CONFIG="Открытие конфигурационного файла"
    MSG_DELETE="Удаление (с подтверждением)"
    MSG_PRIVILEGES="Выдача привилегий"
    MSG_CONFIRM_DELETE="Вы уверены, что хотите удалить?"
    MSG_INVALID_ID="Неверный ID."
    MSG_EXIT="Выход"
else
    MSG_CHOOSE="Choose what to manage:"
    MSG_LXC="LXC containers"
    MSG_VM="VM machines"
    MSG_ID="Enter ID:"
    MSG_NAME="Enter name:"
    MSG_ACTION="Choose action:"
    MSG_START="Start"
    MSG_STOP="Stop"
    MSG_RESTART="Restart"
    MSG_CONFIG="Open configuration file"
    MSG_DELETE="Delete (with confirmation)"
    MSG_PRIVILEGES="Grant privileges"
    MSG_CONFIRM_DELETE="Are you sure you want to delete?"
    MSG_INVALID_ID="Invalid ID."
    MSG_EXIT="Exit"
fi

# Выбор управления
CHOICE=$(dialog --title "$MSG_CHOOSE" --menu "$MSG_CHOOSE" 15 50 2 \
1 "$MSG_LXC" \
2 "$MSG_VM" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    exit 1
fi

# Ввод ID и имени
ID=$(dialog --inputbox "$MSG_ID" 8 40 3>&1 1>&2 2>&3)
if [ $? -ne 0 ]; then
    exit 1
fi

NAME=$(dialog --inputbox "$MSG_NAME" 8 40 3>&1 1>&2 2>&3)
if [ $? -ne 0 ]; then
    exit 1
fi

# Выбор действия
ACTION=$(dialog --title "$MSG_ACTION" --menu "$MSG_ACTION" 15 50 5 \
1 "$MSG_START" \
2 "$MSG_STOP" \
3 "$MSG_RESTART" \
4 "$MSG_CONFIG" \
5 "$MSG_DELETE" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    exit 1
fi

# Функция для выполнения действий
perform_action() {
    case $1 in
        1) # Включение
            if [ "$CHOICE" -eq 1 ]; then
                pct start "$ID"
            else
                qm start "$ID"
            fi
            ;;
        2) # Выключение
            if [ "$CHOICE" -eq 1 ]; then
                pct stop "$ID"
            else
                qm stop "$ID"
            fi
            ;;
        3) # Перезагрузка
            if [ "$CHOICE" -eq 1 ]; then
                pct reboot "$ID"
            else
                qm reboot "$ID"
            fi
            ;;
        4) # Открытие конфигурационного файла
            if [ "$CHOICE" -eq 1 ]; then
                nano /etc/pve/lxc/"$ID".conf
            else
                nano /etc/pve/qemu-server/"$ID".conf
            fi
            ;;
        5) # Удаление
            if dialog --yesno "$MSG_CONFIRM_DELETE" 7 60; then
                if [ "$CHOICE" -eq 1 ]; then
                    pct stop "$ID"
                    pct destroy "$ID"
                else
                    qm stop "$ID"
                    qm del "$ID"
                fi
            fi
            ;;
    esac
}

# Выполнение действия
perform_action "$ACTION"

# Если выбраны VM, выдача привилегий
if [ "$CHOICE" -eq 2 ]; then
    PRIVILEGE_ACTION=$(dialog --title "$MSG_PRIVILEGES" --menu "$MSG_PRIVILEGES" 15 50 3 \
    1 "Забрать привилегии" \
    2 "Сброс" \
    3 "Защита" 3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        exit 1
    fi

    case $PRIVILEGE_ACTION in
        1) # Забрать привилегии
            # Здесь вы можете добавить логику для забирания привилегий
            # Например, если у вас есть конкретные привилегии, которые нужно удалить
            # qm set "$ID" --deleteprivileges
            dialog --msgbox "Привилегии забраны." 6 30
            ;;
        2) # Сброс
            # Здесь вы можете добавить логику для сброса привилегий
            # qm resetprivileges "$ID"
            dialog --msgbox "Привилегии сброшены." 6 30
            ;;
        3) # Защита
            # Здесь вы можете добавить логику для защиты
            # qm set "$ID" --protection 1
            dialog --msgbox "Виртуальная машина защищена." 6 30
            ;;
    esac
fi

# Завершение скрипта
dialog --msgbox "$MSG_EXIT" 6 30
exit 0
