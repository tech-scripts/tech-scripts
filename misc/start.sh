#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

SUDO=$(command -v sudo)
CURRENT_DIR=$(pwd)
CLONE_DIR="$USER_DIR/tmp/tech-scripts/misc"

install_package() {
    local package=$1
    if command -v apt &>/dev/null; then
        $SUDO apt update && $SUDO apt install -y "$package"
    elif command -v yum &>/dev/null; then
        $SUDO yum install -y "$package"
    elif command -v dnf &>/dev/null; then
        $SUDO dnf install -y "$package"
    elif command -v zypper &>/dev/null; then
        $SUDO zypper install -y "$package"
    elif command -v pacman &>/dev/null; then
        $SUDO pacman -S --noconfirm "$package"
    elif command -v apk &>/dev/null; then
        $SUDO apk add "$package"
    elif command -v brew &>/dev/null; then
        brew install "$package"
    else
        echo "The package manager could not be identified. Install $package manually!"
        exit 1
    fi
}

install_packages() {
    for package in git whiptail; do
        command -v "$package" &>/dev/null && continue
        
        if [ "$package" = "whiptail" ]; then
            install_package newt
        fi
        
        install_package "$package"
    done
}

install_packages

[ -n "$USER_DIR" ] && $SUDO mkdir -p "$USER_DIR"

[ ! -d "$USER_DIR/tmp" ] && $SUDO mkdir -p "$USER_DIR/tmp"
[ ! -d "$USER_DIR/etc" ] && $SUDO mkdir -p "$USER_DIR/etc"
[ ! -d "$USER_DIR/usr" ] && $SUDO mkdir -p "$USER_DIR/usr"

[ ! -d "$USER_DIR/tmp/tech-scripts" ] && cd $USER_DIR/tmp && git clone --depth 1 https://github.com/tech-scripts/tech-scripts.git

cd "$CURRENT_DIR"
cd $USER_DIR/tmp/tech-scripts/misc

[ ! -d "$USER_DIR/etc/tech-scripts" ] && $SUDO mkdir -p "$USER_DIR/etc/tech-scripts"
[ ! -d "$USER_DIR/usr/local/tech-scripts" ] && $SUDO mkdir -p "$USER_DIR/usr/local/tech-scripts"
[ ! -d "$USER_DIR/usr/local/bin" ] && $SUDO mkdir -p "$USER_DIR/usr/local/bin"

cp -f $USER_DIR/tmp/tech-scripts/misc/localization.sh $USER_DIR/etc/tech-scripts/
cp -f $USER_DIR/tmp/tech-scripts/misc/variables.sh $USER_DIR/etc/tech-scripts/
cp -f $USER_DIR/tmp/tech-scripts/misc/functions.sh $USER_DIR/etc/tech-scripts/
cp -f $USER_DIR/tmp/tech-scripts/misc/source.sh $USER_DIR/etc/tech-scripts/

if [ ! -f "$USER_DIR/etc/tech-scripts/choose.conf" ]; then
    $SUDO touch $USER_DIR/etc/tech-scripts/choose.conf
    {
        echo "lang: English"
        echo "access: 755"
        echo "editor: nano"
    } | $SUDO tee -a $USER_DIR/etc/tech-scripts/choose.conf > /dev/null
    $SUDO chmod +x "choose.sh"
    ./choose.sh
fi

DIR_STACK=()
CURRENT_DIR="$CLONE_DIR"
EXCLUDE_FILES=("start.sh" "choose.sh" "localization.sh" "variables.sh" "functions.sh" "source.sh" "*.tmp")

cd "$CURRENT_DIR"

source $USER_DIR/etc/tech-scripts/source.sh

BASIC_DIRECTORY=$(echo "$BASIC_DIRECTORY" | tr -s ' ')

[ -n "$BASIC_DIRECTORY" ] && IFS=' ' read -r -a directories <<< "$BASIC_DIRECTORY"

for dir in "${directories[@]}"; do
    [ -d "$dir" ] && [ "$(stat -c "%a" "$dir")" != "$ACCESS" ] && $SUDO chmod -R "$ACCESS" "$dir"
done

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
