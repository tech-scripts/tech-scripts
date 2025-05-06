#!/usr/bin/env bash
echo "start"
BASIC_DIRECTORY=$(echo "$BASIC_DIRECTORY" | tr -s ' ')

[ -n "$BASIC_DIRECTORY" ] && IFS=' ' read -r -a directories <<< "$BASIC_DIRECTORY"

for dir in "${directories[@]}"; do
    [ -d "$dir" ] && [ "$(stat -c "%a" "$dir")" != "$ACCESS" ] && echo "$ACCESS $dir"
done
echo "done"
