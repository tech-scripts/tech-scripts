#!/bin/bash

LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

if [[ "$LANGUAGE" == "Русский" ]]; then
    MSG_NO_SCRIPTS="Нет доступных скриптов или директорий!"
    MSG_CANCELLED="Выбор отменен!"
    MSG_BACK="назад"
    MSG_SELECT="Выберите опцию"
    MSG_CD_ERROR="Ошибка: Не удалось перейти в директорию!"
    DIRECTORY_FORMAT="директория"
    SCRIPT_FORMAT="скрипт"
    OPTION_FORMAT="опция"

    QM_NOT_FOUND="Утилита qm не найдена. Убедитесь, что Proxmox установлен!"
    NO_VMS="Нет доступных виртуальных машин!"
    SELECT_VM="Выберите виртуальную машину"
    SELECT_ACTION="Выберите действие"
    MSG_CONFIRM_DELETE="Вы уверены, что хотите удалить"
    MSG_ERROR="Ошибка"
    CONTINUE_VM="Продолжить работу с текущей виртуальной машиной?"

    PCT_NOT_FOUND="Утилита pct не найдена. Убедитесь, что Proxmox установлен!"
    NO_CONTAINERS_LXC="Нет доступных LXC-контейнеров!"
    SELECT_CONTAINER="Выберите контейнер"
    CONTINUE_LXC="Продолжить работу с текущим контейнером?"
else
    MSG_NO_SCRIPTS="No available scripts or directories!"
    MSG_CANCELLED="Selection cancelled!"
    MSG_BACK="back"
    MSG_SELECT="Select an option"
    MSG_CD_ERROR="Error: Failed to change directory!"
    DIRECTORY_FORMAT="directory"
    SCRIPT_FORMAT="script"
    OPTION_FORMAT="option"

    QM_NOT_FOUND="Utility qm not found. Make sure Proxmox is installed!"
    NO_VMS="No available virtual machines!"
    SELECT_VM="Select virtual machine"
    SELECT_ACTION="Select action"
    MSG_CONFIRM_DELETE="Are you sure you want to delete"
    MSG_ERROR="Error"
    CONTINUE_VM="Continue working with the current virtual machine?"

    PCT_NOT_FOUND="Utility pct not found. Make sure Proxmox is installed!"
    NO_CONTAINERS_LXC="No available LXC containers!"
    SELECT_CONTAINER="Select container"
    CONTINUE_LXC="Continue working with the current container?"
fi
