#!/bin/bash

trap 'echo -e "$CANCEL_MSG"; exit 0' SIGINT
SUDO=$(command -v sudo || echo "")
ZRAM_CONFIG="/etc/tech-scripts/zram_config.conf"
ZRAM_SETUP_SCRIPT="/usr/local/tech-scripts/zram_setup.sh"
SYSTEMD_SERVICE="/etc/systemd/system/zram_setup.service"

LANG_CONF=""
[ -f /etc/tech-scripts/choose.conf ] && LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d':' -f2 | tr -d ' ')

if [ "$LANG_CONF" = "Русский" ]; then
    CANCEL_MSG="Вы прервали выполнение скрипта."
    DIALOG_INSTALL_ERROR="Ошибка установки dialog."
    DIALOG_MANUAL_INSTALL="Установите dialog вручную."
    INVALID_SIZE="Некорректный ввод. Введите размер в формате, например, 8G или 512M."
    ZRAM_SETTINGS="Текущие настройки ZRAM:\n\nРазмер: $ZRAM_SIZE\nАвтозапуск: $(if [ "$ADD_TO_AUTOSTART" -eq 0 ]; then echo "Включен"; else echo "Выключен"; fi)"
    REMOVE_ZRAM="Удалить настройки ZRAM?"
    ZRAM_REMOVED="Настройки ZRAM удалены."
    ZRAM_SESSION_REMOVED="ZRAM удален из текущего сеанса."
    SCRIPT_REMOVED="Временный скрипт ZRAM удален."
    AUTOSTART_REMOVED="ZRAM удален из автозапуска."
    ENTER_SIZE="Введите размер ZRAM (например, 8G, 512M):"
    ADD_AUTOSTART="Добавить ZRAM в автозапуск?"
    CONFIRM_SETTINGS="Текущие настройки ZRAM:\n\nРазмер: $ZRAM_SIZE\nАвтозапуск: $(if [ $ADD_TO_AUTOSTART -eq 0 ]; then echo "Включен"; else echo "Выключен"; fi)\n\nВыполнить скрипт?"
    ZRAM_SETUP="Настройка ZRAM..."
    CHOOSE_MEMORY="Выберите тип памяти:"
    ZRAM_OPTION="ZRAM"
    SWAP_OPTION="SWAP"
    ZSWAP_OPTION="ZSWAP"
else
    CANCEL_MSG="Script execution interrupted."
    DIALOG_INSTALL_ERROR="Error installing dialog."
    DIALOG_MANUAL_INSTALL="Please install dialog manually."
    INVALID_SIZE="Invalid input. Please enter size in format like 8G or 512M."
    ZRAM_SETTINGS="Current ZRAM settings:\n\nSize: $ZRAM_SIZE\nAutostart: $(if [ "$ADD_TO_AUTOSTART" -eq 0 ]; then echo "Enabled"; else echo "Disabled"; fi)"
    REMOVE_ZRAM="Remove ZRAM settings?"
    ZRAM_REMOVED="ZRAM settings removed."
    ZRAM_SESSION_REMOVED="ZRAM removed from current session."
    SCRIPT_REMOVED="Temporary ZRAM script removed."
    AUTOSTART_REMOVED="ZRAM removed from autostart."
    ENTER_SIZE="Enter ZRAM size (e.g., 8G, 512M):"
    ADD_AUTOSTART="Add ZRAM to autostart?"
    CONFIRM_SETTINGS="Current ZRAM settings:\n\nSize: $ZRAM_SIZE\nAutostart: $(if [ $ADD_TO_AUTOSTART -eq 0 ]; then echo "Enabled"; else echo "Disabled"; fi)\n\nRun script?"
    ZRAM_SETUP="Setting up ZRAM..."
    CHOOSE_MEMORY="Choose memory type:"
    ZRAM_OPTION="ZRAM"
    SWAP_OPTION="SWAP"
    ZSWAP_OPTION="ZSWAP"
fi

install_dialog() {
    $SUDO apt update && $SUDO apt install -y dialog || { echo "$DIALOG_INSTALL_ERROR"; exit 1; }
}

if ! command -v dialog &> /dev/null; then
    echo "dialog not found. Installing..."
    install_dialog
fi

is_valid_zram_size() {
    [[ $1 =~ ^[0-9]+[GgMm]$ ]] || [[ $1 =~ ^[0-9]+[GgMm][Bb]$ ]]
}

close() {
    echo "$CANCEL_MSG"
    exit 0
}

dialog --menu "$CHOOSE_MEMORY" 10 40 3 \
1 "$ZRAM_OPTION" \
2 "$SWAP_OPTION" \
3 "$ZSWAP_OPTION" 2> /tmp/memory_choice

MEMORY_CHOICE=$(< /tmp/memory_choice)

case $MEMORY_CHOICE in
    1)
        if [ -f "$ZRAM_CONFIG" ]; then
            source "$ZRAM_CONFIG"
            dialog --msgbox "$ZRAM_SETTINGS" 10 50
            if dialog --yesno "$REMOVE_ZRAM" 7 40; then
                $SUDO rm -f "$ZRAM_CONFIG"
                echo "$ZRAM_REMOVED"
                if [ -e /dev/zram0 ]; then
                    $SUDO swapoff /dev/zram0
                    $SUDO modprobe -r zram
                    echo "$ZRAM_SESSION_REMOVED"
                fi
                if [ -f "$ZRAM_SETUP_SCRIPT" ]; then
                    $SUDO rm -f "$ZRAM_SETUP_SCRIPT"
                    echo "$SCRIPT_REMOVED"
                fi
                if [ -f "$SYSTEMD_SERVICE" ]; then
                    $SUDO systemctl stop zram_setup.service
                    $SUDO systemctl disable zram_setup.service
                    $SUDO rm -f "$SYSTEMD_SERVICE"
                    $SUDO systemctl daemon-reload
                    echo "$AUTOSTART_REMOVED"
                fi
            else
                close
            fi
        fi

        while true; do
            dialog --inputbox "$ENTER_SIZE" 8 40 2> /tmp/zram_size
            if [ $? -ne 0 ]; then
                close
            fi
            ZRAM_SIZE=$(< /tmp/zram_size)
            if is_valid_zram_size "$ZRAM_SIZE"; then
                break
            else
                dialog --msgbox "$INVALID_SIZE" 6 50
            fi
        done

        dialog --yesno "$ADD_AUTOSTART" 7 40
        ADD_TO_AUTOSTART=$?

        dialog --yesno "$CONFIRM_SETTINGS" 10 50
        RUN_SCRIPT=$?

        if [ $RUN_SCRIPT -eq 0 ]; then
            echo "$ZRAM_SETUP"
            $SUDO modprobe zram
            echo $ZRAM_SIZE | $SUDO tee /sys/block/zram0/disksize > /dev/null
            $SUDO mkswap /dev/zram0
            $SUDO swapon /dev/zram0

            if [ $ADD_TO_AUTOSTART -eq 0 ]; then
                echo -e "ZRAM_SIZE=$ZRAM_SIZE\nADD_TO_AUTOSTART=$ADD_TO_AUTOSTART" | $SUDO tee $ZRAM_CONFIG > /dev/null
                echo -e "[Unit]\nDescription=ZRAM Setup\n\n[Service]\nType=oneshot\nExecStart=$ZRAM_SETUP_SCRIPT\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target" | $SUDO tee "$SYSTEMD_SERVICE" > /dev/null
                echo -e "#!/bin/bash\n\nmodprobe zram\nZRAM_SIZE=\$(grep ZRAM_SIZE $ZRAM_CONFIG | cut -d'=' -f2)\necho \$ZRAM_SIZE > /sys/block/zram0/disksize\nmkswap /dev/zram0\nswapon /dev/zram0" | $SUDO tee "$ZRAM_SETUP_SCRIPT" > /dev/null
                $SUDO chmod +x "$ZRAM_SETUP_SCRIPT"
                $SUDO systemctl enable zram_setup.service
            fi
            exit 0
        else
            close
        fi
        ;;
    2)
        echo "SWAP setup not implemented yet."
        ;;
    3)
        echo "ZSWAP setup not implemented yet."
        ;;
esac

rm -f /tmp/memory_choice /tmp/zram_size
