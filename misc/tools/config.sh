#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR="tech-scripts"

source $USER_DIR/etc/tech-scripts/source.sh

get_relative_path() {
    local full_path="$1"
    local base_path="$2"
    local relative_path="${full_path#$base_path/}"
    [ -z "$relative_path" ] && echo " " || echo "$relative_path"
}

process_directory() {
    local dir="$1"
    for FILE in "$dir"/*; do
        if [[ -e "$FILE" ]]; then
            if [ -f "$FILE" ]; then
                SCRIPTS+=("$FILE")
            elif [ -d "$FILE" ]; then
                DIRECTORIES+=("$FILE")
            fi
        fi
    done
}

show_menu() {
    while true; do
        SCRIPTS=()
        DIRECTORIES=()
        CHOICES=()
        DISPLAY_NAMES=()

        case "$CURRENT_DIR" in
            /)
                DIRECTORIES=("/etc" "/opt" "/var" "/usr" "/home" "/root" "/tmp")
                ;;
            /etc)
                SCRIPTS=("/etc/fstab" "/etc/passwd" "/etc/ssh" "/etc/apt" "/etc/tech-scripts")
                ;;
            /usr)
                DIRECTORIES=("/usr/local" "/usr/share" "/usr/local/etc" "/usr/local/tech-scripts")
                ;;
            /var)
                DIRECTORIES=("/var/lib/docker" "/var/www/html")
                ;;
            *)
                process_directory "$CURRENT_DIR"
                ;;
        esac

        for DIR in "${DIRECTORIES[@]}"; do
            DIR_NAME=$(basename "$DIR")
            CHOICES+=("$DIR")
            DISPLAY_NAMES+=("$DIR_NAME $DIRECTORY_FORMAT")
        done

        if [ ${#SCRIPTS[@]} -gt 0 ]; then
            for SCRIPT in "${SCRIPTS[@]}"; do
                SCRIPT_NAME=$(basename "$SCRIPT")
                CHOICES+=("$SCRIPT")
                DISPLAY_NAMES+=("$SCRIPT_NAME $CONFIG_FORAMT")
            done
        fi

        [ "$CURRENT_DIR" != "$USER_DIR/" ] && { CHOICES+=("$MSG_BACK"); DISPLAY_NAMES+=("$MSG_BACK $OPTION_FORMAT"); }

        [ ${#CHOICES[@]} -eq 0 ] && { echo "$MSG_NO_SCRIPTS"; exit 0; }

        WHIPTAIL_MENU=()
        for DISPLAY_NAME in "${DISPLAY_NAMES[@]}"; do
            WHIPTAIL_MENU+=("$DISPLAY_NAME" "")
        done

        RELATIVE_PATH=$(get_relative_path "$CURRENT_DIR" "/")
        SELECTED_ITEM=$(whiptail --title "$MSG_SELECT" --menu "$RELATIVE_PATH" 12 40 4 "${WHIPTAIL_MENU[@]}" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            exit 0
        fi

        SELECTED_INDEX=$(printf '%s\n' "${DISPLAY_NAMES[@]}" | grep -n "^$SELECTED_ITEM" | cut -d: -f1)
        SELECTED_INDEX=$((SELECTED_INDEX - 1))

        SELECTED_ITEM="${CHOICES[$SELECTED_INDEX]}"

        if [ "$SELECTED_ITEM" == "$MSG_BACK" ]; then
            if [ ${#DIR_STACK[@]} -gt 0 ]; then
                cd "${DIR_STACK[-1]}" || { echo "$MSG_CD_ERROR"; exit 1; }
                CURRENT_DIR="${DIR_STACK[-1]}"
                DIR_STACK=("${DIR_STACK[@]:0:${#DIR_STACK[@]}-1}")
            fi
        elif [ -d "$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")
            CURRENT_DIR="$SELECTED_ITEM"
            cd "$CURRENT_DIR" || { echo "$MSG_CD_ERROR"; exit 1; }
        else
            if [ -f "$SELECTED_ITEM" ]; then
                $EDITOR "$SELECTED_ITEM"
                whiptail --yesno "$CONTINUE_CONFIG" 8 40
                if [ $? -ne 0 ]; then
                    exit 0
                fi
            fi
        fi
    done
}
DIR_STACK=()
CURRENT_DIR="$USER_DIR/"
cd "$CURRENT_DIR" || { echo "$MSG_CD_ERROR"; exit 1; }

show_menu
