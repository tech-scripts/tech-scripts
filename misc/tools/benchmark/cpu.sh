#!/bin/bash

whiptail --title "Стресс-тест процессора" --yesno "Вы хотите выполнить стресс-тест процессора?" 10 60

if [ $? -eq 0 ]; then
    echo "Запуск теста на одно ядро..."
    single_core_result=$(sysbench cpu --threads=1 run)
    echo "Запуск теста на все ядра..."
    multi_core_result=$(sysbench cpu --threads=$(nproc) run)

    echo "CPU speed:"
    echo "$single_core_result" | grep "events per second:"
    echo ""
    echo "General statistics:"
    echo "$single_core_result" | grep -E "total time:|total number of events:"
    echo ""
    echo "CPU speed:"
    echo "$multi_core_result" | grep "events per second:"
    echo ""
    echo "General statistics:"
    echo "$multi_core_result" | grep -E "total time:|total number of events:"
else
    echo "Стресс-тест отменен."
fi
