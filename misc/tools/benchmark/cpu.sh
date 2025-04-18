#!/bin/bash

if ! command -v sysbench &>/dev/null; then
    whiptail --title "Установка sysbench" --yesno "sysbench не установлен. Хотите установить его?" 10 60
    if [ $? -eq 0 ]; then
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y sysbench
        elif command -v yum &>/dev/null; then
            sudo yum install -y sysbench
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y sysbench
        elif command -v zypper &>/dev/null; then
            sudo zypper install -y sysbench
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm sysbench
        elif command -v apk &>/dev/null; then
            sudo apk add sysbench
        elif command -v brew &>/dev/null; then
            brew install sysbench
        else
            echo "Не удалось определить пакетный менеджер. Установите sysbench вручную!"
            exit 1
        fi
    else
        exit 0
    fi
fi

whiptail --title "Стресс-тест процессора" --yesno "Вы хотите выполнить стресс-тест процессора?" 10 60

show_progress() {
    ( 
        for i in {1..100}; do
            sleep 0.1
            echo $i
        done
    ) | whiptail --title "Прогресс" --gauge "Пожалуйста, подождите..." 6 60 0
}

if [[ $? -eq 0 ]]; then
    show_progress &
    single_core_result=$(sysbench cpu --time=5 --threads=1 run)
    multi_core_result=$(sysbench cpu --time=5 --threads=$(nproc) run)
    wait
    echo ""
    echo "Single core"
    echo ""
    echo -e "CPU speed:"
    echo -e "$(echo "$single_core_result" | grep "events per second:" | sed -E 's/([0-9]+\.[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')"
    echo ""
    echo -e "General statistics:"
    echo -e "$(echo "$single_core_result" | grep -E "total time:|total number of events:" | sed -E 's/([0-9]+\.[0-9]+|[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')"
    echo ""
    echo "Multi core"
    echo ""
    echo -e "CPU speed:"
    echo -e "$(echo "$multi_core_result" | grep "events per second:" | sed -E 's/([0-9]+\.[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')"
    echo ""
    echo -e "General statistics:"
    echo -e "$(echo "$multi_core_result" | grep -E "total time:|total number of events:" | sed -E 's/([0-9]+\.[0-9]+|[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')"
    echo ""
else
    echo "Стресс-тест отменен."
fi
