#!/bin/bash

# Функция для удаления директорий
delete_directories() {
    echo "Удаление директорий..."
    sudo rm -rf /tmp/tech-scripts /etc/tech-scripts /usr/local/tech-scripts /usr/local/bin/tech
    echo "Директории успешно удалены."
}

# Отображение диалога с блокировкой кнопки "ОК" на 10 секунд
{
    for i in {10..1}; do
        echo "XXX"
        echo "Ожидание $i секунд..."
        echo "XXX"
        echo "Вы точно хотите удалить все файлы tech-scripts?"
        sleep 1
    done
} | dialog --title "Подтверждение удаления" --gauge "Подождите 10 секунд..." 10 50 0

# Отображение диалога с активной кнопкой "ОК"
dialog --yesno "Вы точно хотите удалить все файлы tech-scripts?" 10 50

# Проверка результата диалога
if [ $? -eq 0 ]; then
    # Если пользователь нажал "ОК"
    delete_directories
else
    # Если пользователь нажал "Отмена"
    echo "Удаление отменено."
fi
