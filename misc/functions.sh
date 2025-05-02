#!/usr/bin/env bash

change_directory_permissions() {
    [ -n "$BASIC_DIRECTORY" ] && IFS=' ' read -r -a directories <<< "$BASIC_DIRECTORY"

    for dir in "${directories[@]}"; do
        [ -d "$dir" ] && [ "$(stat -c "%a" "$dir")" != "$ACCESS" ] && $SUDO chmod -R "$ACCESS" "$dir"
    done
}
