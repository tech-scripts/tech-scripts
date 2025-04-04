#!/bin/bash

SUDO=$(command -v sudo)

install_dependencies() {
    $SUDO apt-get update
    $SUDO apt-get install -y dialog git
}

REPO_URL="https://github.com/tech-scripts/linux.git"
CLONE_DIR="/tmp/tech-scripts"

[ -d "$CLONE_DIR" ] && rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"
cd "$CLONE_DIR" || exit 1

echo "1"
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
echo "2"
LANGUAGE=$(grep -E '^lang:' "$CONFIG_FILE" | cut -d':' -f2 | xargs)
if [[ "$LANGUAGE" == "Русский" ]]; then
    MSG_INSTALL_PROMPT="Установить необходимые пакеты? (y/n): "
    MSG_NO_SCRIPTS="Нет доступных скриптов или директорий."
    MSG_CANCELLED="Выбор отменен."
    MSG_BACK="назад"
    MSG_SELECT="Выберите опцию:"
    MSG_CLONE_ERROR="Ошибка: Не удалось клонировать репозиторий."
    MSG_CD_ERROR="Ошибка: Не удалось перейти в директорию."
else
    MSG_INSTALL_PROMPT="Install necessary packages? (y/n): "
    MSG_NO_SCRIPTS="No available scripts or directories."
    MSG_CANCELLED="Selection cancelled."
    MSG_BACK="back"
    MSG_SELECT="Select an option:"
    MSG_CLONE_ERROR="Error: Failed to clone the repository."
    MSG_CD_ERROR="Error: Failed to change directory."
fi
echo "3"
if ! command -v dialog &> /dev/null || ! command -v git &> /dev/null; then
    read -p "$MSG_INSTALL_PROMPT" choice
    [[ "$choice" == [Yy] ]] && install_dependencies || exit 1
fi



DIR_STACK=()
CURRENT_DIR="$CLONE_DIR"
EXCLUDE_FILES=("start.sh" "*.tmp")
echo "4"
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
            CHOICES+=("$DIR" "directory")
        done

        if [ ${#SCRIPTS[@]} -gt 0 ]; then
            for SCRIPT in "${SCRIPTS[@]}"; do
                CHOICES+=("$SCRIPT" "script")
            done
        fi

        [ "$CURRENT_DIR" != "$CLONE_DIR" ] && CHOICES+=("$MSG_BACK" "option")

        [ ${#CHOICES[@]} -eq 0 ] && { echo "$MSG_NO_SCRIPTS"; exit 0; }

        MSG_TITLE="$CURRENT_DIR"
        SELECTED_ITEM=$(dialog --title "$MSG_TITLE" --menu "$MSG_SELECT" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && exit 0

        if [ "$SELECTED_ITEM" == "$MSG_BACK" ]; then
            if [ ${#DIR_STACK[@]} -gt 0 ]; then
                cd "${DIR_STACK[-1]}"
                CURRENT_DIR="${DIR_STACK[-1]}"
                DIR_STACK=("${DIR_STACK[@]:0:${#DIR_STACK[@]}-1}")
            fi
        elif [ -d "$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")
            CURRENT_DIR="$CURRENT_DIR/$SELECTED_ITEM"
            cd "$CURRENT_DIR" || exit 1
        else
            if [ -f "$SELECTED_ITEM" ]; then
                chmod +x "$SELECTED_ITEM"
                ./"$SELECTED_ITEM"
                exit 0
            fi
        fi
    done
}
echo "5"
show_menu
echo "6"
