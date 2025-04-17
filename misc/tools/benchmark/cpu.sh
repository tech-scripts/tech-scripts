#!/bin/bash

whiptail --title "Стресс-тест процессора" --yesno "Вы хотите выполнить стресс-тест процессора?" 10 60

if [[ $? -eq 0 ]]; then
    echo "Запуск теста на одно ядро..."
    single_core_result=$(sysbench cpu --time=5 --threads=1 run)
    echo "Запуск теста на все ядра..."
    multi_core_result=$(sysbench cpu --time=5 --threads=$(nproc) run)
    echo ""
    echo "Single core"
    echo ""
    echo -e "CPU speed:"
    printf "$(echo "$single_core_result" | grep "events per second:" | sed -E 's/([0-9]+\.[0-9]+)/\\e[38;2;128;128;128m\1\\e[0m/g')\n"
    echo ""
    echo -e "General statistics:"
    printf "$(echo "$single_core_result" | grep -E "total time:|total number of events:" | sed -E 's/([0-9]+\.[0-9]+|[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')\n"
    echo ""
    echo "Multi core"
    echo ""
    echo -e "CPU speed:"
    printf "$(echo "$multi_core_result" | grep "events per second:" | sed -E 's/([0-9]+\.[0-9]+)/\\e[38;2;192;192;192m\1\\e[0m/g')\n"
    echo ""
    echo -e "General statistics:"
    printf "$(echo "$multi_core_result" | grep -E "total time:|total number of events:" | sed -E 's/([0-9]+\.[0-9]+|[0-9]+)/\\e[38;2;224;224;224m\1\\e[0m/g')\n"
    echo ""
else
    echo "Стресс-тест отменен."
fi
