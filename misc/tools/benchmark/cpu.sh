#!/bin/bash

source /tmp/tech-scripts/misc/localization.sh
source /tmp/tech-scripts/misc/variables.sh

install_sysbench() {
    if command -v apt &>/dev/null; then
        curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | $SUDO bash
        $SUDO apt update && $SUDO apt install -y sysbench
    elif command -v yum &>/dev/null; then
        curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | $SUDO bash
        $SUDO yum install -y sysbench
    elif command -v dnf &>/dev/null; then
        curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | $SUDO bash
        $SUDO dnf install -y sysbench
    elif command -v zypper &>/dev/null; then
        $SUDO zypper install -y sysbench
    elif command -v pacman &>/dev/null; then
        $SUDO pacman -S --noconfirm sysbench
    elif command -v apk &>/dev/null; then
        $SUDO apk add sysbench
    elif command -v brew &>/dev/null; then
        brew install sysbench
    else
        echo "$PACKAGE_MANAGER_ERROR"
        exit 1
    fi
}

if ! command -v sysbench &>/dev/null; then
    if whiptail --title "$INSTALL_TITLE" --yesno "$INSTALL_QUESTION" 10 60; then
        install_sysbench
    else
        exit 0
    fi
fi

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
