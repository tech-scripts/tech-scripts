#!/usr/bin/env bash

change_directory_permissions() {
    [ -n "$BASIC_DIRECTORY" ] && IFS=' ' read -r -a directories <<< "$BASIC_DIRECTORY"

    for dir in "${directories[@]}"; do
        if [ -n "$dir" ] && [ -d "$dir" ]; then
            if [ "$(stat -c "%a" "$dir")" != "$ACCESS" ]; then
                echo "$ACCESS $dir"
                $SUDO chmod -R "$ACCESS" "$dir"
            fi
        fi
    done
}
