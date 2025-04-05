#!/bin/bash

SUDO=$(command -v sudo)

lang=$(grep -E '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$lang" == "Русский" ]; then
    title_add="Добавление команды tech"
    msg_add="Хотите добавить команду tech для быстрого доступа?"
    msg_success="Команда tech успешно добавлена!"
    msg_cancel="Добавление команды tech отменено."
else
    title_add="Adding tech command"
    msg_add="Do you want to add the tech command for quick access?"
    msg_success="Tech command has been successfully added!"
    msg_cancel="Adding tech command has been canceled."
fi

dialog --title "$title_add" --yesno "$msg_add" 10 40

if [ $? -eq 0 ]; then
    $SUDO tee /usr/local/bin/tech > /dev/null << 'EOF'
#!/bin/bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/tech-scripts/linux/refs/heads/main/misc/start.sh)"
EOF
    $SUDO chmod +x /usr/local/bin/tech
    dialog --title "$title_add" --msgbox "$msg_success" 10 40
else
    dialog --title "$title_add" --msgbox "$msg_cancel" 10 40
fi
