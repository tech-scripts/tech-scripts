#!/bin/bash

SUDO=$(command -v sudo)

if [ ! -d "/etc/tech-scripts" ]; then
    $SUDO mkdir -p /etc/tech-scripts
fi

if [ ! -f "/etc/tech-scripts/choose.conf" ]; then
    $SUDO touch /etc/tech-scripts/choose.conf
fi

LANGUAGE=$(whiptail --title "Language Selection" --menu "Choose language:" 10 40 2 \
    1 "English" \
    2 "Русский" \
    3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    echo " "
    echo "Selection canceled!"
    echo " "
    exit 1
fi

case $LANGUAGE in
    1)
        lang="English"
        ;;
    2)
        lang="Русский"
        ;;
    *)
        echo " "
        echo "Invalid choice!"
        echo " "
        exit 1
        ;;
esac

# Создаем временный файл
temp_file=$(mktemp)

# Добавляем строку с lang: в первую строку
echo "lang: $lang" > "$temp_file"

# Добавляем остальное содержимое файла, если оно есть
$SUDO grep -v "^lang:" /etc/tech-scripts/choose.conf >> "$temp_file"

# Перемещаем временный файл в основной
$SUDO mv "$temp_file" /etc/tech-scripts/choose.conf

if [ "$lang" = "Русский" ]; then
    echo " "
    echo "Язык установлен: $lang"
    echo " "
else
    echo " "
    echo "Language set to: $lang"
    echo " "
fi
