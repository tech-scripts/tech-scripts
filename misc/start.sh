#!/bin/bash

SUDO=$(command -v sudo)
CLONE_DIR="/tmp/tech-scripts/misc"

install_packages() {
    for package in git whiptail; do
        command -v $package &>/dev/null && continue
        if command -v apt &>/dev/null; then
            $SUDO apt update && $SUDO apt install -y $package
        elif command -v yum &>/dev/null; then
            $SUDO yum install -y $package
        elif command -v dnf &>/dev/null; then
            $SUDO dnf install -y $package
        elif command -v zypper &>/dev/null; then
            $SUDO zypper install -y $package
        elif command -v pacman &>/dev/null; then
            $SUDO pacman -S --noconfirm $package
        elif command -v apk &>/dev/null; then
            $SUDO apk add $package
        elif command -v brew &>/dev/null; then
            brew install $package
        else
            echo "Не удалось определить пакетный менеджер. Установите $package вручную!"
            exit 1
        fi
    done
}

install_packages

[ ! -d "/tmp/tech-scripts" ] && cd /tmp && git clone --depth 1 https://github.com/tech-scripts/linux.git /tmp/tech-scripts

cd /tmp/tech-scripts/misc

DIR_STACK=()
CURRENT_DIR="$CLONE_DIR"
EXCLUDE_FILES=("start.sh" "choose.sh" "localization.sh" "*.tmp")
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

source /tmp/tech-scripts/misc/localization.sh 

get_relative_path() {
    local full_path="$1"
    local base_path="$2"
    local relative_path="${full_path#$base_path/}"
    [ -z "$relative_path" ] && echo " " || echo "$relative_path"
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

        RELATIVE_PATH=$(get_relative_path "$CURRENT_DIR" "$CLONE_DIR")
        SELECTED_ITEM=$(whiptail --title "$MSG_SELECT" --menu "$RELATIVE_PATH" 12 40 4 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

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
