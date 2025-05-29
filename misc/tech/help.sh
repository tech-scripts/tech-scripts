#!/usr/bin/env bash

RED="\e[31;1m"
GREEN="\e[32m"
WHITE="\e[97m"
BLUE="\e[34;1m"
BOLD="\e[1m"
RESET="\e[0m"

echo -e "${BOLD}${BLUE}Core Commands${RESET}"
echo -e "  ${GREEN}Open Menu:${RESET}               ${WHITE}tech menu${RESET}"
echo -e "  ${GREEN}Update Scripts:${RESET}          ${WHITE}tech update${RESET}"
echo -e "  ${GREEN}Edit Config:${RESET}             ${WHITE}tech config${RESET}"
echo ""

echo -e "${BOLD}${BLUE}Stress Testing${RESET}"
echo -e "  ${GREEN}CPU Stress Test:${RESET}         ${WHITE}tech cpu${RESET}"
echo -e "  ${GREEN}Disk Stress Test:${RESET}        ${WHITE}tech disk${RESET}"
echo -e "  ${GREEN}Memory Stress Test:${RESET}      ${WHITE}tech memory${RESET}"
echo ""

echo -e "${BOLD}${BLUE}System Optimization${RESET}"
echo -e "  ${GREEN}Configure Swap:${RESET}          ${WHITE}tech swap${RESET}"
echo -e "  ${GREEN}Customize GRUB:${RESET}          ${WHITE}tech grub${RESET}"
echo -e "  ${GREEN}Add Startup Script:${RESET}      ${WHITE}tech startup${RESET}"
echo ""

echo -e "${BOLD}${BLUE}Automation${RESET}"
echo -e "  ${GREEN}Auto Update:${RESET}             ${WHITE}tech autoupdate${RESET}"
echo -e "  ${GREEN}Monitor System:${RESET}          ${WHITE}tech system${RESET}"
echo ""

echo -e "${BOLD}${BLUE}Security${RESET}"
echo -e "  ${GREEN}SSH Notifications:${RESET}       ${WHITE}tech ssh${RESET}"
echo -e "  ${GREEN}Kernel Modules Check:${RESET}     ${WHITE}tech kernel${RESET}"
echo ""

echo -e "${BOLD}${BLUE}LXC and VM Management${RESET}"
echo -e "  ${GREEN}Manage LXC Containers:${RESET}   ${WHITE}tech lxc${RESET}"
echo -e "  ${GREEN}Manage Virtual Machines:${RESET} ${WHITE}tech vm${RESET}"
echo ""
