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

    # Ожидание завершения прогресс-бара или отмены
    wait $GAUGE_PID

    # Если прогресс-бар завершился успешно (не отменен), удаляем директории
    if [ $? -eq 0 ]; then
        delete_directories
    else
        cleanup
    fi
else
    echo "Удаление отменено."
fi
