#!/bin/bash

source /tmp/tech-scripts/misc/localization.sh
source /tmp/tech-scripts/misc/variables.sh

LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANGUAGE" = "Русский" ]; then
    TITLE_ADD_TECH="Быстрый доступ"
    MSG_ADD_TECH="Хотите добавить команду tech для быстрого доступа?"
    TITLE_REMOVE_TECH="Удаление команды"
    MSG_REMOVE_TECH="Команда tech уже существует. Хотите удалить её?"
    MSG_REMOVED_TECH="Команда tech успешно удалена!"
    TITLE_UPDATE_TECH="Обновление команды"
    MSG_UPDATE_TECH="Команда tech уже существует. Хотите обновить её?"
    MSG_UPDATED_TECH="Команда tech успешно обновлена!"
    UNKNOWN_COMMAND_TECH="Неизвестная команда: \$1"
    USAGE_TECH="Использование: tech [lxc|vm|ssh alert|...]"
else
    TITLE_ADD_TECH="Quick access"
    MSG_ADD_TECH="Do you want to add the tech command for quick access?"
    TITLE_REMOVE_TECH="Remove command"
    MSG_REMOVE_TECH="The tech command already exists. Do you want to remove it?"
    MSG_REMOVED_TECH="The tech command has been successfully removed!"
    TITLE_UPDATE_TECH="Update command"
    MSG_UPDATE_TECH="The tech command already exists. Do you want to update it?"
    MSG_UPDATED_TECH="The tech command has been successfully updated!"
    UNKNOWN_COMMAND_TECH="Unknown command: \$1"
    USAGE_TECH="Usage: tech [lxc|vm|ssh alert|...]"
fi

TECH_SCRIPT=$(cat <<EOF
#!/bin/bash

REPO_URL_TECH="https://github.com/tech-scripts/linux.git"
CLONE_DIR_TECH="/tmp/tech-scripts"

source /tmp/tech-scripts/misc/tech/tech.sh

run_script() {
    local script_dir="\$1"
    local script_name="\$2"
    cd "\$CLONE_DIR_TECH/misc/\$script_dir"
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
    "update") run_script "tech" "update.sh" ;;
    "lxc") run_script "proxmox" "lxc.sh" ;;
    "vm") run_script "proxmox" "vm.sh" ;;
    "disk") run_script "tools/benchmark" "disk.sh" ;;
    "cpu") run_script "tools/benchmark" "cpu.sh" ;;
    "memory") run_script "tools/benchmark" "memory.sh" ;;
    "autoupdate") run_script "tools" "autoupdate.sh" ;;
    "grub") run_script "tools" "grub.sh" ;;
    "ssh") run_script "tools" "ssh.sh" ;;
    "startup") run_script "tools" "startup.sh" ;;
    "swap") run_script "tools" "swap.sh" ;;
    "system") run_script "tools" "system.sh" ;;
    "config") run_script "tools" "config.sh" ;;
    *) echo " "; echo "\$UNKNOWN_COMMAND_TECH"; echo "\$USAGE_TECH"; echo " "; exit 1 ;;
esac
EOF
)

if [ -f /usr/local/bin/tech ]; then
    whiptail --title "$TITLE_UPDATE_TECH" --yesno "$MSG_UPDATE_TECH" 10 40
    if [ $? -eq 0 ]; then
        $SUDO rm /usr/local/bin/tech
        $SUDO tee /usr/local/bin/tech > /dev/null <<< "$TECH_SCRIPT"
        $SUDO chmod +x /usr/local/bin/tech
        echo " "
        echo "$MSG_UPDATED_TECH"
        echo " "
    else
        whiptail --title "$TITLE_REMOVE_TECH" --yesno "$MSG_REMOVE_TECH" 10 40
        if [ $? -eq 0 ]; then
            $SUDO rm /usr/local/bin/tech
            echo " "
            echo "$MSG_REMOVED_TECH"
            echo " "
        else
            exit 0
        fi
    fi
else
    $SUDO tee /usr/local/bin/tech > /dev/null <<< "$TECH_SCRIPT"
    $SUDO chmod +x /usr/local/bin/tech
fi
