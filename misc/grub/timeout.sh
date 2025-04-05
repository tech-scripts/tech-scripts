#!/bin/bash

SUDO=$(command -v sudo)

is_number() {
    [[ $1 =~ ^[0-9]+$ ]]
}

LANG=$(grep 'lang:' /etc/tech-scripts/choose.conf | awk '{print $2}')

if [[ $LANG == "Русский" ]]; then
    MSG_INPUT="Введите количество секунд для задержки перед запуском:"
    MSG_CANCEL="Отмена. Скрипт завершен."
    MSG_CONFIRM="Вы ввели: %d секунд. Это правильно?"
    MSG_ERROR="Ошибка: Введите целое число."
    MSG_SUCCESS="Задержка перед запуском установлена на %d секунд. Конфигурация GRUB обновлена."
else
    MSG_INPUT="Enter the number of seconds to delay before startup:"
    MSG_CANCEL="Cancelled. Script terminated."
    MSG_CONFIRM="You entered: %d seconds. Is this correct?"
    MSG_ERROR="Error: Please enter a whole number."
    MSG_SUCCESS="Startup delay set to %d seconds. GRUB configuration updated."
fi

while true; do
    delay=$(dialog --stdout --inputbox "$MSG_INPUT" 0 0)
    [ $? -ne 0 ] && echo "$MSG_CANCEL" && exit 1
    if is_number "$delay"; then
        dialog --yesno "$(printf "$MSG_CONFIRM" "$delay")" 6 40
        [ $? -eq 0 ] && break
    else
        dialog --msgbox "$MSG_ERROR" 6 40
    fi
done

$SUDO sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$delay/" /etc/default/grub
$SUDO update-grub
dialog --msgbox "$(printf "$MSG_SUCCESS" "$delay")" 8 50
