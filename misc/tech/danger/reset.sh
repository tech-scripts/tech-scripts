#!/bin/bash

# Функция для удаления директорий
delete_directories() {
    echo "Удаление директорий..."
    sudo rm -rf /tmp/tech-scripts /etc/tech-scripts /usr/local/tech-scripts /usr/local/bin/tech
    echo "Директории успешно удалены."
}

# Ловушка для прерывания скрипта
cleanup() {
    echo "Скрипт прерван! Удаление отменено."
    exit 1
}

# Устанавливаем ловушки для сигналов SIGINT (Ctrl+C), SIGTSTP (Ctrl+Z) и SIGTERM
trap cleanup SIGINT SIGTSTP SIGTERM

# Отображение диалога с активной кнопкой "ОК"
dialog --yesno "Вы точно хотите удалить все файлы tech-scripts?" 10 50

# Проверка результата диалога
if [ $? -eq 0 ]; then
    # Если пользователь нажал "ОК", начинаем таймер с прогрессом
    {
        for i in {0..100}; do
            echo "XXX"
            echo "$i"  # Прогресс от 0% до 100%
            echo "Вы еще можете отменить это (Ctrl + C)"
            echo "XXX"
            sleep 0.1  # Пауза 0.1 секунды для плавного увеличения
        done
    } | dialog --title "Подтверждение удаления" --gauge "Вы еще можете отменить это (Ctrl + C)" 10 50 0

    # После завершения таймера вызываем функцию удаления директорий
    delete_directories
else
    # Если пользователь нажал "Отмена"
    echo "Удаление отменено."
fi
