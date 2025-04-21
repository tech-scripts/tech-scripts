#!/bin/bash

SUDO=$(command -v sudo)
EDITOR=$(grep '^editor:' /etc/tech-scripts/choose.conf | cut -d ' ' -f 2)
CONFIG_FILE="/etc/tech-scripts/choose.conf"
