#!/bin/bash

# Функция для удаления директорий
delete_directories() {
    echo "Удаление директорий..."
    sudo rm -rf /tmp/tech-scripts /etc/tech-scripts /usr/local/tech-scripts /usr/local/bin/tech
    echo "Директории успешно удалены!"
}

# Отображение диалога с таймером
dialog --timeout 10 --yesno "Вы точно хотите удалить все файлы tech-scripts?" 10 50

# Проверка результата диалога
if [ $? -eq 0 ]; then
    # Если пользователь нажал "ОК" или истек таймер
    delete_directories
else
    # Если пользователь нажал "Отмена"
    echo "Удаление отменено!"
fi
