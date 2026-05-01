#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/opt/tech-scripts/source.sh

TECH_SCRIPT=$(cat <<'TECHSCRIPT'
#!/usr/bin/env bash

[ "${HOME##*/}" = ".suroot" ] && export HOME="${HOME%/*}"

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

SUDO=$(env | grep -qi TERMUX && echo "" || command -v sudo 2>/dev/null)

source $USER_DIR/opt/tech-scripts/source.sh

[ ! -d "$USER_DIR/tmp/tech-scripts" ] && cd $USER_DIR/tmp && git clone --depth 1 https://github.com/tech-scripts/tech-scripts.git && copy_files && change_directory_permissions

run_script() {
    local script_dir="$1"
    local script_name="$2"
    cd "$CLONE_DIR_TECH/misc/$script_dir"
    ./"$script_name"
}

if [ $# -eq 0 ]; then
    cd $USER_DIR/tmp/tech-scripts/misc/tech
    ./menu.sh
    exit 0
fi

combined_args="$*"

case "$combined_args" in
    "menu") run_script "tech" "menu.sh" ;;
    "help") run_script "tech" "help.sh" ;;
    "update") run_script "tech" "update.sh" ;;
    "apatch") run_script "android" "apatch.sh" ;;
    "lxc") run_script "proxmox" "lxc.sh" ;;
    "vm") run_script "proxmox" "vm.sh" ;;
    "disk") run_script "tools/benchmark" "disk.sh" ;;
    "cpu") run_script "tools/benchmark" "cpu.sh" ;;
    "memory") run_script "tools/benchmark" "memory.sh" ;;
    "autoupdate") run_script "tools" "autoupdate.sh" ;;
    "grub") run_script "tools" "grub.sh" ;;
    "kernel") run_script "tools" "kernel.sh" ;;
    "ports") run_script "tools" "ports.sh" ;;
    "root") run_script "tools" "root.sh" ;;
    "ssh") run_script "tools" "ssh.sh" ;;
    "startup") run_script "tools" "startup.sh" ;;
    "swap") run_script "tools" "swap.sh" ;;
    "system") run_script "tools" "system.sh" ;;
    "config") run_script "tools" "config.sh" ;;
    "wipe-frp") run_script "tools" "wipe-frp.sh" ;;
    *) echo ""; echo "$UNKNOWN_COMMAND_TECH $1"; echo "$USAGE_TECH"; echo ""; exit 1 ;;
esac
TECHSCRIPT
)

# Функция для бесшумного обновления (без диалогов)
force_update() {
    if [ -f "$TECH_COMMAND_DIR/tech" ]; then
        $SUDO rm -f "$TECH_COMMAND_DIR/tech"
    fi
    $SUDO tee "$TECH_COMMAND_DIR/tech" > /dev/null <<< "$TECH_SCRIPT"
    $SUDO chmod +x "$TECH_COMMAND_DIR/tech"
    hash -d tech &>/dev/null
    echo ""
    if [ -n "$LANGUAGE" ]; then
        echo "Обновление завершено!"
    else
        echo "Update completed!"
    fi
    echo ""
}

# Если скрипт вызван с --force-update - просто обновляем
if [ "$1" = "--force-update" ] || [ "$1" = "-f" ]; then
    force_update
    exit 0
fi

# Интерактивный режим с диалогами
if [ -f "$TECH_COMMAND_DIR/tech" ]; then
    # Проверяем наличие whiptail для GUI
    if command -v whiptail &>/dev/null; then
        whiptail --title "$TITLE_UPDATE_TECH" --yesno "$MSG_UPDATE_TECH" 10 40
        if [ $? -eq 0 ]; then
            force_update
        else
            whiptail --title "$TITLE_REMOVE_TECH" --yesno "$MSG_REMOVE_TECH" 10 40
            if [ $? -eq 0 ]; then
                $SUDO rm "$TECH_COMMAND_DIR/tech"
                hash -d tech &>/dev/null
                echo ""
                if [ -n "$LANGUAGE" ]; then
                    echo "Tech скрипт удален!"
                else
                    echo "Tech script removed!"
                fi
                echo ""
            else
                exit 0
            fi
        fi
    else
        # Если нет whiptail - используем текстовый режим
        echo ""
        if [ -n "$LANGUAGE" ]; then
            echo "Найдена существующая установка Tech."
            read -p "Обновить? (y/N): " -r REPLY
        else
            echo "Existing Tech installation found."
            read -p "Update? (y/N): " -r REPLY
        fi
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            force_update
        else
            if [ -n "$LANGUAGE" ]; then
                read -p "Удалить Tech? (y/N): " -r REPLY
            else
                read -p "Remove Tech? (y/N): " -r REPLY
            fi
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                $SUDO rm "$TECH_COMMAND_DIR/tech"
                hash -d tech &>/dev/null
                echo ""
                if [ -n "$LANGUAGE" ]; then
                    echo "Tech скрипт удален!"
                else
                    echo "Tech script removed!"
                fi
                echo ""
            else
                exit 0
            fi
        fi
    fi
else
    # Первая установка
    $SUDO tee "$TECH_COMMAND_DIR/tech" > /dev/null <<< "$TECH_SCRIPT"
    $SUDO chmod +x "$TECH_COMMAND_DIR/tech"
    hash -d tech &>/dev/null
    echo ""
    if [ -n "$LANGUAGE" ]; then
        echo "Tech успешно установлен!"
    else
        echo "Tech installed successfully!"
    fi
    echo ""
fi
