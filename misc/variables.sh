#!/bin/bash

SUDO=$(command -v sudo)
LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)
EDITOR=$(grep '^editor:' /etc/tech-scripts/choose.conf | cut -d ' ' -f 2)
CONFIG_FILE="/etc/tech-scripts/choose.conf"
SCRIPT_DIR_SSH="/usr/local/tech-scripts"
CONFIG_FILE_SSH="/etc/tech-scripts/alert.conf"
AUTOSTART_SCRIPT="/usr/local/tech-scripts/autostart.sh"
SERVICE_FILE="/etc/systemd/system/autostart.service"
SERVICE_NAME="autostart.service"
