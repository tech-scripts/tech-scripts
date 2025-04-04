#!/bin/bash

SUDO=$(command -v sudo)
REPO_URL="https://github.com/tech-scripts/linux.git"
CLONE_DIR="/tmp/tech-scripts/misc"
CONFIG_FILE="/etc/tech-scripts/choose.conf"
EXCLUDE_FILES=("LICENCE" "*.tmp")

install_dependencies() {
    $SUDO apt-get update
    $SUDO apt-get install -y dialog git
}

[ -d "$CLONE_DIR" ] && rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR" || { echo "Ошибка: Не удалось клонировать репозиторий!"; exit 1; }
cd "$CLONE_DIR/misc" || { echo "Ошибка: Не удалось перейти в директорию $CLONE_DIR/misc."; exit 1; }

# Проверка конфигурационного файла
if [ ! -f "$CONFIG_FILE" ]; then
    CHOOSE_SCRIPT="/tmp/tech-scripts/choose.sh"
    [ -f "$CHOOSE_SCRIPT" ] && { chmod +x "$CHOOSE_SCRIPT"; "$CHOOSE_SCRIPT"; } || exit 1
fi

# Определение языка
LANGUAGE=$(grep -E '^lang:' "$CONFIG_FILE" | cut -d':' -f2 | xargs)
if [[ "$LANGUAGE" == "Русский" ]]; then
    MSG_INSTALL_PROMPT="Установить необходимые пакеты? (y/n): "
    MSG_NO_SCRIPTS="Нет доступных скриптов или директорий!"
    MSG_CANCELLED="Выбор отменен!"
    MSG_BACK="назад"
    MSG_SELECT="Выберите опцию:"
else
    MSG_INSTALL_PROMPT="Install necessary packages? (y/n): "
    MSG_NO_SCRIPTS="No available scripts or directories!"
    MSG_CANCELLED="Selection cancelled!"
    MSG_BACK="back"
    MSG_SELECT="Select an option:"
fi


if ! command -v dialog &> /dev/null || ! command -v git &> /dev/null; then
    read -p "$MSG_INSTALL_PROMPT" choice
    [[ "$choice" == [Yy] ]] && install_dependencies || exit 1
fi


show_menu() {
    while true; do
        SCRIPTS=($(find . -maxdepth 1 -type f -name "*.sh" ! -name "${EXCLUDE_FILES[@]}"))
        DIRECTORIES=($(find . -maxdepth 1 -type d ! -name "."))
        CHOICES=()

        for DIR in "${DIRECTORIES[@]}"; do CHOICES+=("$DIR" "directory"); done
        for SCRIPT in "${SCRIPTS[@]}"; do CHOICES+=("$SCRIPT" "script"); done
        [ "$CURRENT_DIR" != "$CLONE_DIR/misc" ] && CHOICES+=("$MSG_BACK" "option")

        [ ${#CHOICES[@]} -eq 0 ] && { echo "$MSG_NO_SCRIPTS"; exit 0; }

        SELECTED_ITEM=$(dialog --title "$CURRENT_DIR" --menu "$MSG_SELECT" 15 50 10 "${CHOICES[@]}" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && { echo "$MSG_CANCELLED"; exit 0; }

        if [ "$SELECTED_ITEM" == "$MSG_BACK" ]; then
            [ ${#DIR_STACK[@]} -gt 0 ] && { cd "${DIR_STACK[-1]}"; CURRENT_DIR="${DIR_STACK[-1]}"; DIR_STACK=("${DIR_STACK[@]:0:${#DIR_STACK[@]}-1}"); }
        elif [ -d "$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")
            CURRENT_DIR="$CURRENT_DIR/$SELECTED_ITEM"
            cd "$CURRENT_DIR"
        else
            [ -f "$SELECTED_ITEM" ] && { chmod +x "$SELECTED_ITEM"; ./"$SELECTED_ITEM"; exit 0; }
        fi
    done
}


CURRENT_DIR="$CLONE_DIR/misc"
DIR_STACK=()


show_menu
