#!/bin/bash

SUDO=$(command -v sudo)
LANG_CONF=""
[ -f /etc/tech-scripts/choose.conf ] && LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d':' -f2 | tr -d ' ')
if [ "$LANG_CONF" = "Русский" ]; then
    INPUT_MSG="Введите количество секунд для задержки перед запуском:"
    CANCEL_MSG="Отмена. Скрипт завершен."
    CONFIRM_PROMPT="Вы ввели: %s секунд. Это правильно?"
    ERROR_MSG="Ошибка: Введите целое число."
    SUCCESS_MSG="Задержка перед запуском установлена на %s секунд. Конфигурация GRUB обновлена."
    SED_INFO="Команда sed изменяет значение GRUB_TIMEOUT в файле /etc/default/grub на %s секунд."
else
    INPUT_MSG="Enter the number of seconds for the boot delay:"
    CANCEL_MSG="Cancelled. Script terminated."
    CONFIRM_PROMPT="You entered: %s seconds. Is this correct?"
    ERROR_MSG="Error: Please enter a whole number."
    SUCCESS_MSG="Boot delay set to %s seconds. GRUB configuration updated."
    SED_INFO="The sed command is updating the GRUB_TIMEOUT value in /etc/default/grub to %s seconds."
fi

is_number() {
    [[ $1 =~ ^[0-9]+$ ]]
}

while true; do
    delay=$(dialog --stdout --inputbox "$INPUT_MSG" 0 0)
    [ $? -ne 0 ] && echo "$CANCEL_MSG" && exit 1
    if is_number "$delay"; then
        dialog --yesno "$(printf "$CONFIRM_PROMPT" "$delay")" 6 40
        [ $? -eq 0 ] && break
    else
        dialog --msgbox "$ERROR_MSG" 6 40
    fi
done

$SUDO sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$delay/" /etc/default/grub
$SUDO update-grub
echo "$(printf "$SED_INFO" "$delay")"
#dialog --msgbox "$(printf "$SUCCESS_MSG" "$delay")" 8 50
