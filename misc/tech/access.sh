#!/bin/bash

CONFIG_FILE="/etc/tech-scripts/choose.conf"

ACCESS_LEVEL=$(whiptail --title "Выберите уровня доступа" --menu "" 12 40 4 \
"1" "По умолчанию (755)" \
"2" "Только владелец (700)" \
"3" "Владелец и группа (770)" \
"4" "Все (777)" 3>&1 1>&2 2>&3)

if [ $? != 0 ]; then
    exit 1
fi

case $ACCESS_LEVEL in
    1)
        ACCESS_VALUE=755
        ACCESS_TEXT="По умолчанию (755)"
        ;;
    2)
        ACCESS_VALUE=700
        ACCESS_TEXT="Только владелец (700)"
        ;;
    3)
        ACCESS_VALUE=770
        ACCESS_TEXT="Владелец и группа (770)"
        ;;
    4)
        ACCESS_VALUE=777
        ACCESS_TEXT="Все (777)"
        ;;
    *)
        exit 1
        ;;
esac

sed -i "2s/.*/access: $ACCESS_VALUE/" /etc/tech-scripts/choose.conf

echo ""
echo "Уровень доступа установлен: $ACCESS_TEXT"
echo ""
