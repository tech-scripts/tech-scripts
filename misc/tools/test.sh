#!/bin/bash

show_menu() {
    dialog --title "Выбор пункта" --menu "Выберите пункт:" 15 50 100 "${menu_items[@]}" 2>tempfile
    return_value=$?
    selected_item=$(<tempfile)
    rm tempfile
    return $return_value
}

mapfile -t menu_items < menu_items.txt

while true; do
    show_menu
    if [ $? -ne 0 ]; then
        break
    fi
    echo "Вы выбрали: $selected_item"
done
