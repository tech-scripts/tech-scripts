#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

install_npm() {
    if command -v apt &>/dev/null; then
        $SUDO apt update && $SUDO apt install -y npm
    elif command -v yum &>/dev/null; then
        $SUDO yum install -y npm
    elif command -v dnf &>/dev/null; then
        $SUDO dnf install -y npm
    elif command -v zypper &>/dev/null; then
        $SUDO zypper install -y npm
    elif command -v pacman &>/dev/null; then
        $SUDO pacman -S --noconfirm npm
    elif command -v apk &>/dev/null; then
        $SUDO apk add npm
    elif command -v brew &>/dev/null; then
        brew install npm
    else
        echo "$PACKAGE_MANAGER_ERROR"
        exit 1
    fi
}

if ! command -v sysbench &>/dev/null; then
    if whiptail --title "$INSTALL_TITLE" --yesno "$INSTALL_QUESTION" 10 60; then
        install_npm
        cd $USER_DIR/tmp
        git clone https://github.com/akopytov/sysbench.git
        cd sysbench
        ./autogen.sh
        ./configure
        make -j$(nproc)
        $SUDO make install
        cd ..
        $SUDO rm -rf sysbench
    else
        exit 1
    fi
fi

command -v sysbench &> /dev/null || { echo ""; echo "$SYSBENCH_NOT_FOUND"; echo ""; exit 1; }

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
  echo -e "Total operations: \e[38;2;160;160;160m$total_events\e[0m (\e[38;2;160;160;160m$operations_per_second\e[0m per second)"
  echo ""
  echo -e "\e[38;2;160;160;160m$data_transferred_miB\e[0m MiB transferred (\e[38;2;160;160;160m$data_transferred_rate\e[0m MiB/sec)"
  echo ""
  echo "General statistics:"
  echo -e "    Total time:                          $(echo "$total_time" | sed 's/[0-9]\+/\\e[38;2;160;160;160m&\\e[0m/g')"
  echo -e "    Total number of events:              \e[38;2;160;160;160m$total_events\e[0m"
  echo ""
else
  exit 0
fi
