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
    title_update="Обновление команды"
    msg_update="Команда tech уже существует. Хотите обновить её?"
    msg_updated="Команда tech успешно обновлена!"
    unknown_command="Неизвестная команда: \$1"
    usage="Использование: tech [lxc|vm|ssh alert|...]"
else
    title_add="Quick access"
    msg_add="Do you want to add the tech command for quick access?"
    title_remove="Remove command"
    msg_remove="The tech command already exists. Do you want to remove it?"
    msg_removed="The tech command has been successfully removed!"
    msg_add_canceled="Adding a command has been canceled!"
    msg_remove_canceled="The removal of the command has been canceled!"
    title_update="Update command"
    msg_update="The tech command already exists. Do you want to update it?"
    msg_updated="The tech command has been successfully updated!"
    unknown_command="Unknown command: \$1"
    usage="Usage: tech [lxc|vm|ssh alert|...]"
fi

TECH_SCRIPT=$(cat <<EOF
#!/bin/bash

REPO_URL="https://github.com/tech-scripts/linux.git"
CLONE_DIR="/tmp/tech-scripts"

unknown_command="$unknown_command"
usage="$usage"

run_script() {
    local script_dir="\$1"
    local script_name="\$2"
    rm -rf "/tmp/tech-scripts"
    git clone --depth 1 "\$REPO_URL" "\$CLONE_DIR"
    cd "\$CLONE_DIR/\$script_dir"
    chmod +x "\$script_name"
    ./"\$script_name"
}

if [ \$# -eq 0 ]; then
    bash -c "\$(curl -sL https://raw.githubusercontent.com/tech-scripts/linux/refs/heads/main/misc/start.sh)"
    exit 0
fi

combined_args="\$*"

case "\$combined_args" in
    lxc)
        run_script "proxmox" "lxc.sh"
        ;;
    vm)
        run_script "proxmox" "vm.sh"
        ;;
    "ssh alert")
        run_script "ssh" "alert.sh"
        ;;
    *)
        echo " "
        echo "\$unknown_command"
        echo "\$usage"
        echo " "
        exit 1
        ;;
esac
EOF
)

if [ -f /usr/local/bin/tech ]; then
    whiptail --title "$title_update" --yesno "$msg_update" 10 40
    if [ $? -eq 0 ]; then
        $SUDO rm /usr/local/bin/tech
        $SUDO tee /usr/local/bin/tech > /dev/null <<< "$TECH_SCRIPT"
        $SUDO chmod +x /usr/local/bin/tech
        echo " "
        echo "$msg_updated"
        echo " "
    else
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
    fi
else
    whiptail --title "$title_add" --yesno "$msg_add" 10 40
    if [ $? -eq 0 ]; then
        $SUDO tee /usr/local/bin/tech > /dev/null <<< "$TECH_SCRIPT"
        $SUDO chmod +x /usr/local/bin/tech
    else
        clear
        echo " "
        echo "$msg_add_canceled"
        echo " "
    fi
fi
