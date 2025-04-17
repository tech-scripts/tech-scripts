#!/bin/bash

whiptail --title "Стресс-тест процессора" --yesno "Вы хотите выполнить стресс-тест процессора?" 10 60

if [ $?q 0 ]; then
    echo "Запуск теста на одно ядро..."
    single_core_result=$(sysbench cpu --time=5 --threads=1 run)
    echo "Запуск теста на все ядра..."
    multi_core_result=$(sysbench cpu --time=5 --threads=$(nproc) run)
    echo ""
    echo "Single core"
    echo ""
    echo "CPU speed:"
    echo "\e[37m$(echo "$single_core_result" | grep "events per second:")\e[0m"
    echo ""
    echo "General statistics:"
    echo "\e[37m$(echo "$single_core_result" | grep -E "total time:|total number of events:")\e[0m"
    echo ""
    echo "Multi core"
    echo ""
    echo "CPU speed:"
    echo "\e[37m$(echo "$multi_core_result" | grep "events per second:")\e[0m"
    echo ""
    echo "General statistics:"
    echo "\e[37m$(echo "$multi_core_result" | grep -E "total time:|total number of events:")\e[0m"
    echo ""
else
    echo "Стресс-тест отменен."
fi
