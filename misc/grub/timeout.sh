#!/bin/bash

SUDO=$(command -v sudo)
LANG_FILE="/etc/tech-scripts/choose.conf"
DIALOG="dialog --stdout"
DELAY=""

if grep -q "^lang: Русский" "$LANG_FILE"; then
    MSG_CANCEL="Отмена. Скрипт завершен."
    MSG_INPUT="Введите количество секунд для задержки перед запуском:"
    MSG_CONFIRM="Вы ввели: %s секунд. Это правильно?"
    MSG_ERROR="Ошибка: Введите целое число."
    MSG_SUCCESS="Задержка перед запуском установлена на %s секунд. Конфигурация GRUB обновлена."
else
    MSG_CANCEL="Cancelled. Script finished."
    MSG_INPUT="Enter the number of seconds for the delay before starting:"
    MSG_CONFIRM="You entered: %s seconds. Is this correct?"
    MSG_ERROR="Error: Please enter an integer."
    MSG_SUCCESS="Delay set to %s seconds. GRUB configuration updated."
fi

is_number() {
    [[ $1 =~ ^[0-9]+$ ]]
}

while true; do
    DELAY=$($DIALOG "$MSG_INPUT" 0 0)
    if [ $? -ne 0 ]; then
        echo "$MSG_CANCEL"
        exit 1
    fi

    if is_number "$DELAY"; then
        if $DIALOG --yesno "$(printf "$MSG_CONFIRM" "$DELAY")" 6 40; then
            break
        fi
    else
        $DIALOG --msgbox "$MSG_ERROR" 6 40
    fi
done

$SUDO sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$DELAY/" /etc/default/grub
$SUDO update-grub
$DIALOG --msgbox "$(printf "$MSG_SUCCESS" "$DELAY")" 8 50
