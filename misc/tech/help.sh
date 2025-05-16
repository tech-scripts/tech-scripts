#!/usr/bin/env bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

echo -e "${BOLD}${CYAN}Core Commands${RESET}"
echo -e "  ${YELLOW}Open Menu:${RESET}            tech menu"
echo -e "  ${YELLOW}Update Scripts:${RESET}       tech update"
echo -e "  ${YELLOW}Edit Config:${RESET}          tech config"
echo ""

echo -e "${BOLD}${CYAN}Stress Testing${RESET}"
echo -e "  ${YELLOW}CPU Stress Test:${RESET}      tech cpu"
echo -e "  ${YELLOW}Disk Stress Test:${RESET}     tech disk"
echo -e "  ${YELLOW}Memory Stress Test:${RESET}   tech memory"
echo ""

echo -e "${BOLD}${CYAN}System Optimization${RESET}"
echo -e "  ${YELLOW}Configure Swap:${RESET}       tech swap"
echo -e "  ${YELLOW}Customize GRUB:${RESET}       tech grub"
echo -e "  ${YELLOW}Add Startup Script:${RESET}    tech startup"
echo ""

echo -e "${BOLD}${CYAN}Automation${RESET}"
echo -e "  ${YELLOW}Auto Update:${RESET}           tech autoupdate"
echo -e "  ${YELLOW}Monitor System:${RESET}        tech system"
echo ""

echo -e "${BOLD}${CYAN}Security${RESET}"
echo -e "  ${YELLOW}SSH Notifications:${RESET}     tech ssh"
echo -e "  ${YELLOW}Kernel Module Check:${RESET}   tech modules"
echo ""

echo -e "${BOLD}${CYAN}LXC and VM Management${RESET}"
echo -e "  ${YELLOW}Manage LXC Containers:${RESET}   tech lxc"
echo -e "  ${YELLOW}Manage Virtual Machines:${RESET} tech vm"
echo ""
