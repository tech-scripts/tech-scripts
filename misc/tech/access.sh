#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

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

CONFIG_FILE="$USER_DIR/etc/tech-scripts/choose.conf"

[ -w "$CONFIG_FILE" ] && sed -i "3s/.*/access: $ACCESS_VALUE/" "$CONFIG_FILE" || $SUDO sed -i "3s/.*/access: $ACCESS_VALUE/" "$CONFIG_FILE"

change_directory_permissions

echo ""
echo "$ACCESS_SET_TEXT $ACCESS_VALUE"
echo ""
