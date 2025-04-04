#!/bin/bash

# Проверяем, существует ли директория /etc/mootcomb
if [ ! -d "/etc/tech-scripts" ]; then
    sudo mkdir -p /etc/tech-scripts
fi

# Проверяем, существует ли файл choose.conf
if [ ! -f "/etc/MootComb/choose.conf" ]; then
    sudo touch /etc/tech-scripts/choose.conf
fi

# Используем dialog для выбора языка
LANGUAGE=$(dialog --title "Выбор языка" --menu "Выберите язык:" 10 40 2 \
    1 "English" \
    2 "Русский" \
    3>&1 1>&2 2>&3)

# Проверяем, был ли сделан выбор
if [ $? -ne 0 ]; then
    echo "Выбор отменен!"
    exit 1
fi

# Определяем выбранный язык
case $LANGUAGE in
    1)
        lang="English"
        ;;
    2)
        lang="Русский"
        ;;
    *)
        echo "Неверный выбор!"
        exit 1
        ;;
esac

# Записываем выбранный язык в файл
echo "lang: $lang" | sudo tee /etc/tech-scripts/choose.conf > /dev/null

# Сообщаем пользователю о результате
# dialog --msgbox "Выбранный язык: $lang\nЯзык записан в /etc/mootcomb/choose.conf" 10 50
