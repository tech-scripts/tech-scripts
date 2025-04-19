#!/bin/bash

language=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [ "$language" == "Русский" ]; then
  title="стресс-тест памяти"
  question="вы хотите выполнить стресс-тест памяти?"
else
  title="memory stress test"
  question="do you want to perform a memory stress test?"
fi

show_progress() {
    (
        for i in {1..100}; do
            sleep 0.1
            echo $i
        done
    ) | whiptail --title "Прогресс выполнения" --gauge " " 6 60 0
}

whiptail --title "$title" --yesno "$question" 10 60
if [ $? -eq 0 ]; then
  show_progress &
  sysbench --test=memory --memory-block-size=1K --memory-oper=write --time=10 run > /tmp/sysbench_memory_test.txt
  wait
  total_time=$(grep "total time:" /tmp/sysbench_memory_test.txt | awk '{print $3}')
  total_events=$(grep "total number of events:" /tmp/sysbench_memory_test.txt | awk '{print $5}')
  
  operations_per_second=$(awk "BEGIN {printf \"%.2f\", $total_events / $total_time}")
  total_data_transferred=$((total_events * 1))
  data_transferred_miB=$((total_data_transferred / 1024))
  data_transferred_rate=$(awk "BEGIN {printf \"%.2f\", $data_transferred_miB / $total_time}")
  
  echo ""
  echo "Total operations: $total_events ($operations_per_second per second)"
  echo ""
  echo "$data_transferred_miB MiB transferred ($data_transferred_rate MiB/sec)"
  echo ""
  echo "General statistics:"
  echo "    Total time:                          $total_time"
  echo "    Total number of events:              $total_events"
  echo ""
  
  rm -f /tmp/sysbench_memory_test.txt
else
  exit 0
fi
