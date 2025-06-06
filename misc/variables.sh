#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

SUDO=$(env | grep -qi TERMUX && echo "" || command -v sudo 2>/dev/null)
CURRENT_DIR=$(pwd)
LANGUAGE=$(grep '^lang:' $USER_DIR/etc/tech-scripts/choose.conf | cut -d ' ' -f 2)
EDITOR=$(grep '^editor:' $USER_DIR/etc/tech-scripts/choose.conf | cut -d ' ' -f 2)
ACCESS=$(grep '^access:' $USER_DIR/etc/tech-scripts/choose.conf | cut -d ' ' -f 2)
HIDE=$(grep '^hide:' $USER_DIR/etc/tech-scripts/choose.conf | cut -d ' ' -f 2)
TECH_COMMAND_DIR=$(command -v tech >/dev/null && dirname "$(command -v tech)" || echo "$PATH" | cut -d ':' -f1)
CONFIG_FILE="$USER_DIR/etc/tech-scripts/choose.conf"
SCRIPT_DIR_SSH="$USER_DIR/usr/local/tech-scripts"
CONFIG_FILE_SSH="$USER_DIR/etc/tech-scripts/alert.conf"
AUTOSTART_SCRIPT="$USER_DIR/usr/local/tech-scripts/autostart.sh"
SERVICE_FILE="$USER_DIR/etc/systemd/system/autostart.service"
SERVICE_NAME="autostart.service"
CONFIG_DIR_SWAP="$USER_DIR/etc/tech-scripts"
CONFIG_FILE_SWAP="$CONFIG_DIR_SWAP/choose.conf"
SWAP_CONFIG_SWAP="$CONFIG_DIR_SWAP/swap.conf"
REPO_URL_TECH="https://github.com/tech-scripts/tech-scripts.git"
BASIC_DIRECTORY="$USER_DIR/tmp/tech-scripts $USER_DIR/etc/tech-scripts $USER_DIR/usr/local/tech-scripts $TECH_COMMAND_DIR/tech"
CLONE_DIR_TECH="$USER_DIR/tmp/tech-scripts"
FILE_SIZE="1G"
COLOR_GREEN="\e[38;5;50m"
COLOR_BLUE="\e[38;5;39m"
COLOR_RED="\e[38;5;196m"
COLOR_WHITE="\e[1;97m"
COLOR_GRAY="\e[38;5;245m"
COLOR_RESET="\e[0m"
