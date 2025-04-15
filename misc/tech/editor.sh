#!/bin/bash

SUDO=$(command -v sudo)

LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d' ' -f2)

if [ "$LANG_CONF" = "Русский" ]; then
    TITLE_EDITOR="Выбор текстового редактора"
    MSG_EDITOR="Выберите текстовый редактор:"
    TITLE_CUSTOM="Пользовательский редактор"
    MSG_CUSTOM="Введите команду вашего текстового редактора:"
    MSG_CUSTOM_CANCEL="Ввод пользовательского редактора отменен!"
    MSG_INVALID="Неверный выбор!"
    MSG_SUCCESS="Текстовый редактор установлен:"
else
    TITLE_EDITOR="Text Editor Selection"
    MSG_EDITOR="Choose your text editor:"
    TITLE_CUSTOM="Custom Editor"
    MSG_CUSTOM="Enter the command custom text editor:"
    MSG_CUSTOM_CANCEL="Custom editor input canceled!"
    MSG_INVALID="Invalid choice!"
    MSG_SUCCESS="Text editor set to:"
fi

[ ! -d "/etc/tech-scripts" ] && $SUDO mkdir -p /etc/tech-scripts
[ ! -f "/etc/tech-scripts/choose.conf" ] && $SUDO touch /etc/tech-scripts/choose.conf

EDITOR=$(whiptail --title "$TITLE_EDITOR" --menu "$MSG_EDITOR" 12 40 3 \
    1 "nano" \
    2 "vim" \
    3 "Custom" \
    3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    exit 1
fi

case $EDITOR in
    1) editor="nano" ;;
    2) editor="vim" ;;
    3)
        editor=$(whiptail --title "$TITLE_CUSTOM" --inputbox "$MSG_CUSTOM" 10 40 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "$MSG_CUSTOM_CANCEL"
            exit 1
        fi
        ;;
    *) 
        echo " "
        echo "$MSG_INVALID"
        echo " "
        exit 1
        ;;
esac

# Убедимся, что файл содержит хотя бы одну строку
if ! grep -q '^lang:' /etc/tech-scripts/choose.conf; then
    echo "lang: English" | $SUDO tee /etc/tech-scripts/choose.conf > /dev/null
fi

# Заменяем или добавляем строку с editor
if grep -q '^editor:' /etc/tech-scripts/choose.conf; then
    $SUDO sed -i "s/^editor:.*/editor: $editor/" /etc/tech-scripts/choose.conf
else
    $SUDO sed -i "1a editor: $editor" /etc/tech-scripts/choose.conf
fi

echo " "
echo "$MSG_SUCCESS $editor"
echo " "
