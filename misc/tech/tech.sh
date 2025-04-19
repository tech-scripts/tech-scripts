#!/bin/bash

SUDO=$(command -v sudo)
LANG_CONF=$(grep -E '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANG_CONF" == "Русский" ]; then
    title_add="Быстрый доступ"
    msg_add="Хотите добавить команду tech для быстрого доступа?"
    title_remove="Удаление команды"
    msg_remove="Команда tech уже существует. Хотите удалить её?"
    msg_removed="Команда tech успешно удалена!"
    title_update="Обновление команды"
    msg_update="Команда tech уже существует. Хотите обновить её?"
    msg_updated="Команда tech успешно обновлена!"
    msg_add_complete="Команда tech успешно добавлена!"
    unknown_command="Неизвестная команда: \$1"
    usage="Использование: tech [lxc|vm|ssh alert|...]"
else
    title_add="Quick access"
    msg_add="Do you want to add the tech command for quick access?"
    title_remove="Remove command"
    msg_remove="The tech command already exists. Do you want to remove it?"
    msg_removed="The tech command has been successfully removed!"
    title_update="Update command"
    msg_update="The tech command already exists. Do you want to update it?"
    msg_updated="The tech command has been successfully updated!"
    msg_add_complete="The tech command has been successfully added!"
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
    cd "\$CLONE_DIR/misc/\$script_dir"
    chmod +x "\$script_name"
    ./"\$script_name"
}

if [ \$# -eq 0 ]; then
    cd /tmp/tech-scripts/misc
    chmod +x start.sh
    ./start.sh
    exit 0
fi

combined_args="\$*"

case "\$combined_args" in
    "update")
        run_script "tech" "update.sh"
        ;;
    "lxc")
        run_script "proxmox" "lxc.sh"
        ;;
    "vm")
        run_script "proxmox" "vm.sh"
        ;;
    "disk")
        run_script "tools/benchmark" "disk.sh"
        ;;
    "cpu")
        run_script "tools/benchmark" "cpu.sh"
        ;;
    "memory")
        run_script "tools/benchmark" "memory.sh"
        ;;
    "autoupdate")
        run_script "tools" "autoupdate.sh"
        ;;
    "grub")
        run_script "tools" "grub.sh"
        ;;
    "ssh")
        run_script "tools" "ssh.sh"
        ;;
    "startup")
        run_script "tools" "startup.sh"
        ;;
    "swap")
        run_script "tools" "swap.sh"
        ;;
    "system")
        run_script "tools" "system.sh"
        ;;
    "test")
         run_script "tools" "test.sh"
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
            exit 0
        fi
    fi
else
    $SUDO tee /usr/local/bin/tech > /dev/null <<< "$TECH_SCRIPT"
    $SUDO chmod +x /usr/local/bin/tech
fi
