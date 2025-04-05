#!/bin/bash

LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d':' -f2 | tr -d ' ')

if [ "$LANG_CONF" = "Русский" ]; then
    DIALOG_NOT_FOUND="Утилита dialog не установлена. Установите её с помощью команды: sudo apt install dialog"
    PCT_NOT_FOUND="Утилита pct не найдена. Убедитесь, что Proxmox установлен."
    NO_CONTAINERS="Нет доступных LXC-контейнеров!"
    SELECT_CONTAINER="Выберите контейнер"
    SELECT_ACTION="Выберите действие"
    PRIVILEGED="Контейнер теперь привилегированный."
    UNPRIVILEGED="Контейнер теперь непривилегированный."
    LOCKED="Контейнер заблокирован."
    UNLOCKED="Контейнер разблокирован."
else
    DIALOG_NOT_FOUND="Utility dialog not found. Install it with: sudo apt install dialog"
    PCT_NOT_FOUND="Utility pct not found. Make sure Proxmox is installed."
    NO_CONTAINERS="No available LXC containers!"
    SELECT_CONTAINER="Select container"
    SELECT_ACTION="Select action"
    PRIVILEGED="Container is now privileged."
    UNPRIVILEGED="Container is now unprivileged."
    LOCKED="Container is locked."
    UNLOCKED="Container is unlocked."
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

selected_container_id=$(dialog --title "$SELECT_CONTAINER" --menu "$SELECT_CONTAINER:" 15 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

exit_status=$?
if [ $exit_status != 0 ]; then
    clear
    exit
fi

action=$(dialog --title "$SELECT_ACTION" --menu "$( [ "$LANG_CONF" = "Русский" ] && echo "Что вы хотите сделать с контейнером $selected_container_id?" || echo "What do you want to do with container $selected_container_id?")" 15 50 6 \
1 "$( [ "$LANG_CONF" = "Русский" ] && echo "Сделать привилегированным" || echo "Make privileged")" \
2 "$( [ "$LANG_CONF" = "Русский" ] && echo "Сделать непривилегированным" || echo "Make unprivileged")" \
3 "$( [ "$LANG_CONF" = "Русский" ] && echo "Заблокировать" || echo "Lock")" \
4 "$( [ "$LANG_CONF" = "Русский" ] && echo "Разблокировать" || echo "Unlock")" 3>&1 1>&2 2>&3)

exit_status=$?
if [ $exit_status != 0 ]; then
    clear
    exit
fi

case $action in
    1)
        pct set $selected_container_id -privileged 1
        dialog --msgbox "$PRIVILEGED" 5 40
        ;;
    2)
        pct set $selected_container_id -privileged 0
        dialog --msgbox "$UNPRIVILEGED" 5 40
        ;;
    3)
        pct lock $selected_container_id
        dialog --msgbox "$LOCKED" 5 40
        ;;
    4)
        pct unlock $selected_container_id
        dialog --msgbox "$UNLOCKED" 5 40
        ;;
esac
