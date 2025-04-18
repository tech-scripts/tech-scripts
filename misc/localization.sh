#!/bin/bash

LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [[ "$LANGUAGE" == "Русский" ]]; then
    MSG_NO_SCRIPTS="Нет доступных скриптов или директорий!"
    MSG_CANCELLED="Выбор отменен!"
    MSG_BACK="назад"
    MSG_SELECT="Выберите опцию"
    MSG_CD_ERROR="Ошибка: Не удалось перейти в директорию!"
    DIRECTORY_FORMAT="директория"
    SCRIPT_FORMAT="скрипт"
    OPTION_FORMAT="опция"
else
    MSG_NO_SCRIPTS="No available scripts or directories!"
    MSG_CANCELLED="Selection cancelled!"
    MSG_BACK="back"
    MSG_SELECT="Select an option"
    MSG_CD_ERROR="Error: Failed to change directory!"
    DIRECTORY_FORMAT="directory"
    SCRIPT_FORMAT="script"
    OPTION_FORMAT="option"
fi
