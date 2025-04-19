#!/bin/bash

language=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$language" == "Русский" ]; then
  title="стресс-тест памяти"
  question="вы хотите выполнить стресс-тест памяти?"
  running="запуск стресс-теста памяти на 10 секунд..."
  results="результаты теста памяти:"
else
  title="memory stress test"
  question="do you want to perform a memory stress test?"
  running="running memory stress test for 10 seconds..."
  results="memory test results:"
fi

whiptail --title "$title" --yesno "$question" 10 60
if [ $? -eq 0 ]; then
  echo "$running"
  
  sysbench --test=memory --memory-block-size=1K --memory-oper=write --time=10 run > /tmp/sysbench_memory_test.txt
  
  total_time=$(grep "total time:" /tmp/sysbench_memory_test.txt | awk '{print $3}')
  total_events=$(grep "total number of events:" /tmp/sysbench_memory_test.txt | awk '{print $5}')
  
  operations_per_second=$(awk "BEGIN {printf \"%.2f\", $total_events / $total_time}")
  total_data_transferred=$((total_events * 1)) # 1K = 1 MiB
  data_transferred_miB=$((total_data_transferred / 1024))
  data_transferred_rate=$(awk "BEGIN {printf \"%.2f\", $data_transferred_miB / $total_time}")

  echo "total operations: $total_events ($operations_per_second per second)"
  echo "$data_transferred_miB MiB transferred ($data_transferred_rate MiB/sec)"
  echo "general statistics:"
  echo "total time: $total_time"
  echo "total number of events: $total_events"

  rm -f /tmp/sysbench_memory_test.txt
else
  exit 0
fi
