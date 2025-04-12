#!/bin/bash

delete_directories() {
    echo "Удаление директорий..."
    sudo rm -rf /tmp/tech-scripts /etc/tech-scripts /usr/local/tech-scripts /usr/local/bin/tech
    echo "Директории успешно удалены."
}

cleanup() {
    echo "Скрипт прерван! Удаление отменено."
    exit 1
}

# Устанавливаем обработчик сигналов
trap cleanup SIGINT SIGTSTP SIGTERM

if whiptail --title "Подтверждение удаления" --yesno "Вы точно хотите удалить все файлы tech-scripts?" 10 50; then
    {
        for i in {0..100}; do
            echo "XXX"
            echo "$i"
            echo "XXX"
            sleep 0.1
        done
    } | whiptail --title "Подтверждение удаления" --gauge "Вы еще можете отменить это (Ctrl + C)" 10 50 0 &
    
    GAUGE_PID=$!

    # Ожидание завершения whiptail
    wait $GAUGE_PID

    # Проверка, был ли whiptail прерван
    if [ $? -ne 0 ]; then
        cleanup
    fi

    # Удаляем директории после завершения прогресса
    delete_directories
else
    echo "Удаление отменено."
fi
