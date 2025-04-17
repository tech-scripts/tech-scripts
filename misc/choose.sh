#!/bin/bash

SCRIPT_DIR="/tmp/tech-scripts/misc/tech"
cd "$SCRIPT_DIR" || exit 1

if [ -f "lang.sh" ]; then
    chmod +x "lang.sh"
    ./"lang.sh"
fi

for SCRIPT in *.sh; do
    [ "$SCRIPT" = "lang.sh" ] && continue
    [ "$SCRIPT" = "update.sh" ] && continue
    [ -f "$SCRIPT" ] || continue
    chmod +x "$SCRIPT"
    ./"$SCRIPT"
done
