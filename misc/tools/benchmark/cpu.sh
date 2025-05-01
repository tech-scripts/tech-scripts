#!/bin/bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

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
        cd /tmp
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

if whiptail --title "$CPU_TEST_TITLE" --yesno "$CPU_TEST_QUESTION" 10 60; then
    show_progress &
    single_core_result=$(sysbench cpu --time=5 --threads=1 run)
    multi_core_result=$(sysbench cpu --time=5 --threads=$(nproc) run)
    wait
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│                       Single core                        │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo -e "CPU speed:\n$(echo "$single_core_result" | grep "events per second:" | sed -E 's/([0-9]+\.[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')"
    echo ""
    echo -e "General statistics:\n$(echo "$single_core_result" | grep -E "total time:|total number of events:" | sed -E 's/([0-9]+\.[0-9]+|[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│                        Multi core                        │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo -e "CPU speed:\n$(echo "$multi_core_result" | grep "events per second:" | sed -E 's/([0-9]+\.[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')"
    echo ""
    echo -e "General statistics:\n$(echo "$multi_core_result" | grep -E "total time:|total number of events:" | sed -E 's/([0-9]+\.[0-9]+|[0-9]+)/\\e[38;2;160;160;160m\1\\e[0m/g')"
    echo ""
else
    exit 0
fi
