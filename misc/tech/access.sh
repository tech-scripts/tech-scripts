#!/bin/bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

ACCESS_LEVEL=$(whiptail --title "$ACCESS_TITLE" --menu "$ACCESS_MENU_TEXT" 12 40 4 \
"$ACCESS_OPTION1" \
"$ACCESS_OPTION2" \
"$ACCESS_OPTION3" \
"$ACCESS_OPTION4" 3>&1 1>&2 2>&3)

[ $? != 0 ] && exit 1

case $ACCESS_LEVEL in
    1) ACCESS_VALUE=755 ;;
    2) ACCESS_VALUE=700 ;;
    3) ACCESS_VALUE=770 ;;
    4) ACCESS_VALUE=777 ;;
    *) exit 1 ;;
esac

sed -i "2s/.*/access: $ACCESS_VALUE/" "$CONFIG_FILE"

echo ""
echo "$ACCESS_SET_TEXT $ACCESS_VALUE"
echo ""
