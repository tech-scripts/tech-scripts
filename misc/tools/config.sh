SUDO=$(command -v sudo)
DIR_STACK=()
EDITOR=$(grep '^editor:' /etc/tech-scripts/choose.conf | cut -d ' ' -f 2)
EXCLUDE_FILES=("start.sh" "choose.sh" "localization.sh" "*.tmp")
CONFIG_FILE="/etc/tech-scripts/choose.conf"

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

        case "$CURRENT_DIR" in
            /)
                DIRECTORIES=("etc" "opt" "var" "usr" "home" "root" "tmp")
                ;;
            /tmp|/root|/home)
                for FILE in "$CURRENT_DIR"/*; do
                    FILE_NAME=$(basename "$FILE")
                    [[ " ${EXCLUDE_FILES[@]} " =~ " $FILE_NAME " ]] && continue
                    if [ -f "$FILE" ]; then
                        SCRIPTS+=("$FILE_NAME")
                    elif [ -d "$FILE" ]; then
                        DIRECTORIES+=("$FILE_NAME")
                    fi
                done
                ;;
            *)
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
        elif [ -d "$CURRENT_DIR/$SELECTED_ITEM" ]; then
            DIR_STACK+=("$CURRENT_DIR")
            CURRENT_DIR="$CURRENT_DIR/$SELECTED_ITEM"
            cd "$CURRENT_DIR" || { echo "$MSG_CD_ERROR"; exit 1; }
        else
            if [ -f "$CURRENT_DIR/$SELECTED_ITEM" ]; then
                $EDITOR "$CURRENT_DIR/$SELECTED_ITEM"
                exit 0
            fi
        fi
    done
}

CURRENT_DIR="/"
cd "$CURRENT_DIR" || { echo "$MSG_CD_ERROR"; exit 1; }
show_menu
