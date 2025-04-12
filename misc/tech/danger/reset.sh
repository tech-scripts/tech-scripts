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

trap cleanup SIGINT SIGTERM

# Запрос подтверждения удаления
if whiptail --title "Подтверждение удаления" --yesno "Вы точно хотите удалить все файлы tech-scripts?" 10 50; then
    {
        for i in {0..100}; do
            echo "XXX"
            echo "$i"
            echo "XXX"
            sleep 0.1
        done
    } | whiptail --title "Подтверждение удаления" --gauge "Вы еще можете отменить это (Ctrl + C)" 10 50 0 &
    
    GAUGE_PID=$!  # Сохраняем PID процесса whiptail

    # Ожидаем завершения процесса whiptail
    while kill -0 $GAUGE_PID 2>/dev/null; do
        sleep 1
    done

    # После завершения gauge, выполняем удаление директорий
    delete_directories
else
    echo "Удаление отменено."
fi
