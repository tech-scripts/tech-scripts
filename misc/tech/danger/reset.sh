#!/bin/bash

SUDO=$(command -v sudo)
LANG_CONF=$(grep -E '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [[ $LANG_CONF == "Русский" ]]; then
    TITLE="Подтверждение удаления"
    MESSAGE="Вы точно хотите удалить все файлы tech-scripts?"
    YES="Да"
    NO="Нет"
    DELETING="Удаление файлов..."
    DELETED="Файлы успешно удалены."
    CANCELLED="Удаление отменено."
else
    TITLE="Delete Confirmation"
    MESSAGE="Are you sure you want to delete all tech-scripts files?"
    YES="Yes"
    NO="No"
    DELETING="Deleting files..."
    DELETED="Files deleted successfully."
    CANCELLED="Deletion cancelled."
fi

whiptail --title "$TITLE" --yesno "$MESSAGE" --yes-button "$YES" --no-button "$NO" 10 60

if [ $? -eq 0 ]; then
    echo "$DELETING"
    $SUDO rm -rf /tmp/tech-scripts /etc/tech-scripts /usr/local/tech-scripts /usr/local/bin/tech
    echo "$DELETED"
else
    echo "$CANCELLED"
fi
