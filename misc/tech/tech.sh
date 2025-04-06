#!/bin/bash

SUDO=$(command -v sudo)

lang=$(grep -E '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$lang" == "Русский" ]; then
    title_add="Быстрый доступ"
    msg_add="Хотите добавить команду tech для быстрого доступа?"
    title_remove="Удаление команды"
    msg_remove="Команда tech уже существует. Хотите удалить её?"
    msg_removed="Команда tech успешно удалена."
    msg_canceled="Действие отменено."
else
    title_add="Quick access"
    msg_add="Do you want to add the tech command for quick access?"
    title_remove="Remove command"
    msg_remove="The tech command already exists. Do you want to remove it?"
    msg_removed="The tech command has been successfully removed."
    msg_canceled="Action canceled."
fi

if [ -f /usr/local/bin/tech ]; then

    dialog --title "$title_remove" --yesno "$msg_remove" 10 40
    if [ $? -eq 0 ]; then
        $SUDO rm /usr/local/bin/tech
        echo "$msg_removed"
    else
        echo "$msg_canceled"
    fi
else
    # Если файл не существует, предлагаем создать его
    dialog --title "$title_add" --yesno "$msg_add" 10 40
    if [ $? -eq 0 ]; then
        $SUDO tee /usr/local/bin/tech > /dev/null << 'EOF'
#!/bin/bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/tech-scripts/linux/refs/heads/main/misc/start.sh)"
EOF
        $SUDO chmod +x /usr/local/bin/tech
    else
        echo "$msg_canceled"
    fi
fi
