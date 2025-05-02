#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$(pwd)

source $USER_DIR/etc/tech-scripts/source.sh

ACCESS_LEVEL=$(whiptail --title "$ACCESS_TITLE" --menu "$ACCESS_MENU_TEXT" 12 40 4 \
"1" "$ACCESS_OPTION1" \
"2" "$ACCESS_OPTION2" \
"3" "$ACCESS_OPTION3" \
"4" "$ACCESS_OPTION4" 3>&1 1>&2 2>&3)

[ $? != 0 ] && exit 1

case $ACCESS_LEVEL in
    1) ACCESS_VALUE=755 ;;
    2) ACCESS_VALUE=700 ;;
    3) ACCESS_VALUE=770 ;;
    4) ACCESS_VALUE=777 ;;
    *) exit 1 ;;
esac

sed -i "2s/.*/access: $ACCESS_VALUE/" "$CONFIG_FILE"

BASIC_DIRECTORY=$(echo "$BASIC_DIRECTORY" | tr -s ' ')

[ -n "$BASIC_DIRECTORY" ] && IFS=' ' read -r -a directories <<< "$BASIC_DIRECTORY"

for dir in "${directories[@]}"; do
    [ -d "$dir" ] && [ "$(stat -c "%a" "$dir")" != "$ACCESS" ] && $SUDO chmod -R "$ACCESS" "$dir"
done

echo ""
echo "$ACCESS_SET_TEXT $ACCESS_VALUE"
echo ""
