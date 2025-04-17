#!/bin/bash

whiptail --title "Стресс-тест процессора" --yesno "Вы хотите выполнить стресс-тест процессора?" 10 60

if [ $? -eq 0 ]; then
    echo "Запуск теста на одно ядро..."
    single_core_result=$(sysbench cpu --threads=1 run)
    echo "Запуск теста на все ядра..."
    multi_core_result=$(sysbench cpu --threads=$(nproc) run)

    echo "Single Core Results:"
    echo "$single_core_result"
    echo "Multi Core Results:"
    echo "$multi_core_result"
else
    echo "Стресс-тест отменен."
fi
