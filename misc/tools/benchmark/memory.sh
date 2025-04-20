#!/bin/bash

source /tmp/tech-scripts/misc/localization.sh

show_progress() {
    (
        for i in {1..100}; do
            sleep 0.1
            echo $i
        done
    ) | whiptail --title "$PROGRESS_TITLE" --gauge " " 6 60 0
}

whiptail --title "$MEMORY_TEST_TITLE" --yesno "$MEMORY_TEST_QUESTION" 10 60
if [ $? -eq 0 ]; then
  show_progress &
  
  output=$(sysbench memory --memory-block-size=1K --memory-oper=write --time=10 run)
  wait
  
  total_time=$(echo "$output" | grep "total time:" | awk '{print $3}')
  total_events=$(echo "$output" | grep "total number of events:" | awk '{print $5}')
  
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
else
  exit 0
fi
