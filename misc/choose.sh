#!/bin/bash

SCRIPT_DIR="/tmp/tech-scripts/misc/tech"
cd "$SCRIPT_DIR" || exit 1

[ -f "lang.sh" ] && chmod +x "lang.sh" && ./lang.sh

shopt -s nullglob
for SCRIPT in *.sh; do
    [[ "$SCRIPT" == "lang.sh" || "$SCRIPT" == "update.sh" ]] && continue
    chmod +x "$SCRIPT" && ./"$SCRIPT"
done
