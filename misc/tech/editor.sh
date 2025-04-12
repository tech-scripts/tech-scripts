#!/bin/bash

SUDO=$(command -v sudo)

LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d' ' -f2)

if [ "$LANG_CONF" = "Русский" ]; then
    TITLE_EDITOR="Выбор текстового редактора"
    MSG_EDITOR="Выберите предпочитаемый текстовый редактор:"
    TITLE_CUSTOM="Пользовательский редактор"
    MSG_CUSTOM="Введите команду для вашего текстового редактора:"
    MSG_CANCEL="Выбор отменен!"
    MSG_CUSTOM_CANCEL="Ввод пользовательского редактора отменен!"
    MSG_INVALID="Неверный выбор!"
    MSG_SUCCESS="Текстовый редактор установлен:"
else
    TITLE_EDITOR="Text Editor Selection"
    MSG_EDITOR="Choose your preferred text editor:"
    TITLE_CUSTOM="Custom Editor"
    MSG_CUSTOM="Enter the command for your custom text editor:"
    MSG_CANCEL="Selection canceled!"
    MSG_CUSTOM_CANCEL="Custom editor input canceled!"
    MSG_INVALID="Invalid choice!"
    MSG_SUCCESS="Text editor set to:"
fi

[ ! -d "/etc/tech-scripts" ] && $SUDO mkdir -p /etc/tech-scripts
[ ! -f "/etc/tech-scripts/editor.conf" ] && $SUDO touch /etc/tech-scripts/editor.conf

EDITOR=$(whiptail --title "$TITLE_EDITOR" --menu "$MSG_EDITOR" 12 40 3 \
    1 "nano" \
    2 "vim" \
    3 "Custom" \
    3>&1 1>&2 2>&3)

[ $? -ne 0 ] && { echo " "; echo "$MSG_CANCEL"; echo " "; exit 1; }

case $EDITOR in
    1) editor="nano" ;;
    2) editor="vim" ;;
    3)
        editor=$(whiptail --title "$TITLE_CUSTOM" --inputbox "$MSG_CUSTOM" 10 40 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && { echo "$MSG_CUSTOM_CANCEL"; exit 1; }
        ;;
    *) echo " "; echo "$MSG_INVALID"; echo " "; exit 1 ;;
esac

echo "editor: $editor" | $SUDO tee -a /etc/tech-scripts/choose.conf > /dev/null
echo " "
echo "$MSG_SUCCESS $editor"
echo " "
