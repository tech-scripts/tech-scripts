#!/bin/bash

SUDO=$(command -v sudo)

REPO_URL="https://github.com/tech-scripts/linux.git"
CLONE_DIR="/tmp/tech-scripts/misc"

rm -rf /tmp/tech-scripts/misc
git clone --depth 1 "$REPO_URL" "/tmp/tech-scripts"
cd "$CLONE_DIR"

DIR_STACK=()
CURRENT_DIR="$CLONE_DIR"
EXCLUDE_FILES=("start.sh" "choose.sh" "*.tmp")
CONFIG_FILE="/etc/tech-scripts/choose.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    CHOOSE_SCRIPT="/tmp/tech-scripts/misc/choose.sh"
    if [ -f "$CHOOSE_SCRIPT" ]; then
        chmod +x "$CHOOSE_SCRIPT"
        "$CHOOSE_SCRIPT"
    else
        exit 1
    fi
fi

LANGUAGE=$(grep -E '^lang:' "$CONFIG_FILE" | cut -d':' -f2 | xargs)
if [[ "$LANGUAGE" == "Русский" ]]; then
    MSG_INSTALL_PROMPT="Установить необходимые пакеты? (y/n): "
    MSG_NO_SCRIPTS="Нет доступных скриптов или директорий!"
    MSG_CANCELLED="Выбор отменен!"
    MSG_BACK="назад"
    MSG_SELECT="Выберите опцию:"
    MSG_CD_ERROR="Ошибка: Не удалось перейти в директорию!"
    DIRECTORY_FORMAT="директория"
    SCRIPT_FORMAT="скрипт"
    OPTION_FORMAT="опция"
else
    MSG_INSTALL_PROMPT="Install necessary packages? (y/n): "
    MSG_NO_SCRIPTS="No available scripts or directories!"
    MSG_CANCELLED="Selection cancelled!"
    MSG_BACK="back"
    MSG_SELECT="Select an option:"
    MSG_CD_ERROR="Error: Failed to change directory!"
    DIRECTORY_FORMAT="directory"
    SCRIPT_FORMAT="script"
    OPTION_FORMAT="option"
fi

center_text() {
    local text="$1"
    local width=$(tput cols)  # Получаем ширину терминала
    local text_length=${#text}  # Длина текста
    local padding=$(( (width - text_length) / 2 ))  # Вычисляем количество пробелов
    printf "%${padding}s%s\n" "" "$text"  # Выводим текст с выравниванием
}

show_menu() {
    while true; do
        SCRIPTS=()
        DIRECTORIES=()
        CHOICES=()

        for FILE in *; do
            [[ " ${EXCLUDE_FILES[@]} " =~ " $FILE " ]] && continue
            if [ -f "$FILE" ] && [[ "$FILE" == *.sh ]]; then
                SCRIPTS+=("$FILE")
            elif [ -d "$FILE" ]; then
                DIRECTORIES+=("$FILE")
            fi
        done

        for DIR in "${DIRECTORIES[@]}"; do
            CHOICES+=("$DIR" "$DIRECTORY_FORMAT")
        done

        if [ ${#SCRIPTS[@]} -gt 0 ]; then
            for SCRIPT in "${SCRIPTS[@]}"; do
                CHOICES+=("$SCRIPT" "$SCRIPT_FORMAT")
            done
        fi

        [ "$CURRENT_DIR" != "$CLONE_DIR" ] && CHOICES+=("$MSG_BACK" "$OPTION_FORMAT")

        [ ${#CHOICES[@]} -eq 0 ] && { echo "$MSG_NO_SCRIPTS"; exit 0; }

        # Выводим заголовок по центру
        center_text "$CURRENT_DIR"
        SELECTED_ITEM=$(whiptail --clear --title "$MSG_SELECT" --menu "$CURRENT_DIR" 12 40 4 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            exit 0
        fi

        if [ "$SELECTED_ITEM" == "$MSG_BACK" ]; then
            if [ ${#DIR_STACK[@]} -gt 0 ]; then
                cd "${DIR_STACK[-1]}"
                CURRENT_DIR="${DIR_STACK[-1]}"
                DIR_STACK=("${DIR_STACK[@]:0:${#DIR_STACK[@]}-1}")
            fi
        elif [ -d "$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")
            CURRENT_DIR="$CURRENT_DIR/$SELECTED_ITEM"
            cd "$CURRENT_DIR" || { echo "$MSG_CD_ERROR"; exit 1; }
        else
            if [ -f "$SELECTED_ITEM" ]; then
                chmod +x "$SELECTED_ITEM"
                ./"$SELECTED_ITEM"
                exit 0
            fi
        fi
    done
}

show_menu
