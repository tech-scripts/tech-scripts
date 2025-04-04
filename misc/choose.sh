#!/bin/bash

SCRIPT_DIR="/tmp/tech-scripts/tech"
cd "$SCRIPT_DIR" || exit 1

for SCRIPT in *.sh; do
    [ -f "$SCRIPT" ] || continue
    chmod +x "$SCRIPT"
    ./"$SCRIPT"
done
