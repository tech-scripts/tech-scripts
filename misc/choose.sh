#!/usr/bin/env bash

[ -n "$PREFIX" ] && USER_DIR="$PREFIX" || USER_DIR=""

for script in $USER_DIR/tmp/tech-scripts/misc/tech/{tech,lang,access,editor,hide}.sh; do
    chmod +x "$script" && "$script"
done
