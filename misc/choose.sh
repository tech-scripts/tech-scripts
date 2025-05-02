#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

for script in $USER_DIR/tmp/tech-scripts/misc/tech/{tech,lang,access,editor}.sh; do
    chmod +x "$script" && "$script"
done
