#!/bin/bash

SUDO=$(command -v sudo)

LANG_CONF=$(grep -E '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANG_CONF" == "Русский" ]; then
    title_add="Быстрый доступ"
    msg_add="Хотите добавить команду tech для быстрого доступа?"
    title_remove="Удаление команды"
    msg_remove="Команда tech уже существует. Хотите удалить её?"
    msg_removed="Команда tech успешно удалена!"
    msg_add_canceled="Добавление команды отменено!"
    msg_remove_canceled="Удаление команды отменено!"
else
    title_add="Quick access"
    msg_add="Do you want to add the tech command for quick access?"
    title_remove="Remove command"
    msg_remove="The tech command already exists. Do you want to remove it?"
    msg_removed="The tech command has been successfully removed!"
    msg_add_canceled="Adding a command has been canceled!"
    msg_remove_canceled="The removal of the team has been canceled!"
fi

if [ -f /usr/local/bin/tech ]; then
    whiptail --title "$title_remove" --yesno "$msg_remove" 10 40
    if [ $? -eq 0 ]; then
        $SUDO rm /usr/local/bin/tech
        echo " "
        echo "$msg_removed"
        echo " "
    else
        echo " "
        echo "$msg_remove_canceled"
        echo " "
    fi
else
    whiptail --title "$title_add" --yesno "$msg_add" 10 40
    if [ $? -eq 0 ]; then
        $SUDO tee /usr/local/bin/tech > /dev/null << 'EOF'
#!/bin/bash

REPO_URL="https://github.com/tech-scripts/linux.git"
CLONE_DIR="/tmp/tech-scripts/misc"
LANG_CONF=$(grep -E '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANG_CONF" == "Русский" ]; then
    error_delete="Ошибка: не удалось удалить $CLONE_DIR"
    error_clone="Ошибка: не удалось клонировать репозиторий"
    error_cd="Ошибка: не удалось перейти в $CLONE_DIR/$1"
    error_chmod="Ошибка: не удалось сделать $1 исполняемым"
    unknown_command="Неизвестная команда: $1"
    usage="Использование: tech [lxc|vm|ssh]"
else
    error_delete="Error: failed to delete $CLONE_DIR"
    error_clone="Error: failed to clone repository"
    error_cd="Error: failed to cd into $CLONE_DIR/$1"
    error_chmod="Error: failed to make $1 executable"
    unknown_command="Unknown command: $1"
    usage="Usage: tech [lxc|vm|ssh]"
fi

run_script() {
    local script_dir="$1"
    local script_name="$2"
    rm -rf "$CLONE_DIR" || { whiptail --msgbox "$error_delete" 10 50; exit 1; }
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR" || { whiptail --msgbox "$error_clone" 10 50; exit 1; }
    cd "$CLONE_DIR/$script_dir" || { whiptail --msgbox "$(echo "$error_cd" | sed "s/\$1/$script_dir/")" 10 50; exit 1; }
    chmod +x "$script_name" || { whiptail --msgbox "$(echo "$error_chmod" | sed "s/\$1/$script_name/")" 10 50; exit 1; }
    ./"$script_name"
}

if [ $# -eq 0 ]; then
    bash -c "$(curl -sL https://raw.githubusercontent.com/tech-scripts/linux/refs/heads/main/misc/start.sh)"
    exit 0
fi

case "$1" in
    lxc)
        run_script "proxmox" "lxc.sh"
        ;;
    vm)
        run_script "proxmox" "vm.sh"
        ;;
    ssh)
        run_script "ssh" "alert.sh"
        ;;
    *)
        whiptail --msgbox "$(echo "$unknown_command" | sed "s/\$1/$1/")" 10 50
        whiptail --msgbox "$usage" 10 50
        exit 1
        ;;
esac
EOF
        $SUDO chmod +x /usr/local/bin/tech
    else
        clear
        echo " "
        echo "$msg_add_canceled"
        echo " "
    fi
fi
