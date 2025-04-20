SUDO=$(command -v sudo)
DIR_STACK=()
EDITOR=$(grep '^editor:' /etc/tech-scripts/choose.conf | cut -d ' ' -f 2)
CONFIG_FILE="/etc/tech-scripts/choose.conf"

source /tmp/tech-scripts/misc/localization.sh

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

        case "$CURRENT_DIR" in
            /)
                DIRECTORIES=("/etc" "/opt" "/var" "/usr" "/home" "/root" "/tmp")
                ;;
            /etc)
                SCRIPTS=("/etc/fstab" "/etc/passwd" "/etc/ssh/sshd_config" "/etc/apt/sources.list")
                ;;
            /usr)
                DIRECTORIES=("/usr/local" "/usr/share")
                ;;
            /usr/local)
                DIRECTORIES=("/usr/local/etc")
                ;;
            /var)
                DIRECTORIES=("/var/lib/docker" "/var/www/html")
                ;;
            *)
                process_directory "$CURRENT_DIR"
                ;;
        esac

        for DIR in "${DIRECTORIES[@]}"; do
            CHOICES+=("$DIR" "$DIRECTORY_FORMAT")
        done

        if [ ${#SCRIPTS[@]} -gt 0 ]; then
            for SCRIPT in "${SCRIPTS[@]}"; do
                CHOICES+=("$SCRIPT" "$SCRIPT_FORMAT")
            done
        fi

        [ "$CURRENT_DIR" != "/" ] && CHOICES+=("$MSG_BACK" "$OPTION_FORMAT")

        [ ${#CHOICES[@]} -eq 0 ] && { echo "$MSG_NO_SCRIPTS"; exit 0; }

        RELATIVE_PATH=$(get_relative_path "$CURRENT_DIR" "/")
        SELECTED_ITEM=$(whiptail --title "$MSG_SELECT" --menu "$RELATIVE_PATH" 12 40 4 "${CHOICES[@]}" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            exit 0
        fi

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
                whiptail --yesno "Вы хотите продолжить?" 8 40
                if [ $? -ne 0 ]; then
                    exit 0
                fi
            fi
        fi
    done
}

CURRENT_DIR="/"
cd "$CURRENT_DIR" || { echo "$MSG_CD_ERROR"; exit 1; }
show_menu
