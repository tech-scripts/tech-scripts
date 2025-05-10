#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

HIDE_LEVEL=$(whiptail --title "$HIDE_TITLE" --menu "$HIDE_MENU_TEXT" 12 40 4 \
"1" "$HIDE_OPTION1" \
"2" "$HIDE_OPTION2" 3>&1 1>&2 2>&3)

[ $? != 0 ] && exit 1

case $HIDE_LEVEL in
    1) HIDE_VALUE=true ;;
    2) HIDE_VALUE=false ;;
    *) exit 1 ;;
esac

CONFIG_FILE="$USER_DIR/etc/tech-scripts/choose.conf"

[ -w "$CONFIG_FILE" ] && sed -i "4s/.*/hide: $HIDE_VALUE/" "$CONFIG_FILE" || $SUDO sed -i "4s/.*/hide: $HIDE_VALUE/" "$CONFIG_FILE"

echo ""
echo "$HIDE_SET_TEXT $HIDE_VALUE"
echo ""
