#!/bin/bash

LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$LANGUAGE" == "Русский" ]; then
  TITLE="Стресс-тест памяти"
  QUESTION="Вы хотите выполнить стресс-тест памяти?"
  RUNNING="Запуск стресс-теста памяти на 10 секунд..."
  RESULTS="Результаты теста памяти:"
else
  TITLE="Memory Stress Test"
  QUESTION="Do you want to perform a memory stress test?"
  RUNNING="Running memory stress test for 10 seconds..."
  RESULTS="Memory test results:"
fi

whiptail --title "$TITLE" --yesno "$QUESTION" 10 60
if [ $? -eq 0 ]; then
  echo "$RUNNING"
  sysbench --test=memory --memory-block-size=1K --memory-oper=write --time=10 run > /tmp/sysbench_memory_test.txt
  echo "$RESULTS"
  echo "------------------------"
  grep -E "total time:|total number of events:|min:|avg:|max:|95th percentile:" /tmp/sysbench_memory_test.txt
  rm -f /tmp/sysbench_memory_test.txt
else
  exit 0
fi
