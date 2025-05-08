#!/usr/bin/env bash

change_directory_permissions() {
    [ -n "$BASIC_DIRECTORY" ] && IFS=' ' read -r -a directories <<< "$BASIC_DIRECTORY"

    getent group tech > /dev/null 2>&1 || { command -v groupadd > /dev/null 2>&1 && $SUDO groupadd tech; }

    for dir in "${directories[@]}"; do
        [ -n "$dir" ] && [ -e "$dir" ] || continue
        if [ "$(stat -c "%a" "$dir")" != "$ACCESS" ] || [ "$(stat -c "%G" "$dir")" != "tech" ]; then
            CMD="chmod -R $ACCESS $dir; getent group tech > /dev/null 2>&1 && chgrp -R tech $dir"
            if ! chgrp -R tech "$dir" 2>/dev/null; then
                $SUDO bash -c "$CMD"
            else
                bash -c "$CMD"
            fi
        fi
    done
}
