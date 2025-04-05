#!/bin/bash

SUDO=$(command -v sudo)

# Создание директории и файла конфигурации, если они не существуют
if [ ! -d "/etc/tech-scripts" ]; then
    $SUDO mkdir -p /etc/tech-scripts
fi

if [ ! -f "/etc/tech-scripts/editor.conf" ]; then
    $SUDO touch /etc/tech-scripts/editor.conf
fi

# Выбор текстового редактора
EDITOR=$(dialog --title "Text Editor Selection" --menu "Choose your preferred text editor:" 12 40 3 \
    1 "nano" \
    2 "vim" \
    3 "Custom" \
    3>&1 1>&2 2>&3)

# Выход, если выбор отменен
if [ $? -ne 0 ]; then
    echo "Selection canceled!"
    exit 1
fi

# Установка выбранного редактора
case $EDITOR in
    1)
        editor="nano"
        ;;
    2)
        editor="vim"
        ;;
    3)
        # Запрос пользовательского редактора
        editor=$(dialog --title "Custom Editor" --inputbox "Enter the command for your custom text editor:" 10 40 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Custom editor input canceled!"
            exit 1
        fi
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo "editor: $editor" | $SUDO tee /etc/tech-scripts/editor.conf > /dev/null

echo "Text editor set to: $editor"
