#!/bin/bash

SUDO=$(command -v sudo || echo "")

AUTOSTART_SCRIPT="/usr/local/tech-scripts/autostart.sh"
SERVICE_FILE="/etc/systemd/system/autostart.service"
SERVICE_NAME="autostart.service"

LANG_CONF=""
[ -f /etc/tech-scripts/choose.conf ] && LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d':' -f2 | tr -d ' ')
EDITOR=$(grep '^editor:' /etc/tech-scripts/choose.conf | cut -d ' ' -f 2)

if [ "$LANG_CONF" = "Русский" ]; then
    INSTALL_MSG="Хотите установить скрипт автозапуска? (y/n): "
    EDIT_MSG="Хотите открыть $AUTOSTART_SCRIPT для редактирования? (y/n): "
    INVALID_EDITOR="Неверный выбор редактора. Пожалуйста, выберите nano или vim."
    SCRIPT_LOCATION="Скрипт autostart.sh расположен по адресу: $AUTOSTART_SCRIPT"
    SERVICE_EXISTS="Служба $SERVICE_NAME уже существует."
    REMOVE_SERVICE_MSG="Хотите удалить авто запуск $SERVICE_NAME? (y/n): "
    SERVICE_REMOVED="Служба $SERVICE_NAME успешно удалена."
    SERVICE_REMOVE_ERROR="Ошибка: не удалось удалить службу $SERVICE_NAME."
    DIR_ERROR="Ошибка: не удалось создать директорию /usr/local/tech-scripts"
    SCRIPT_ERROR="Ошибка: не удалось создать файл $AUTOSTART_SCRIPT."
    CHMOD_ERROR="Ошибка: не удалось сделать файл $AUTOSTART_SCRIPT исполняемым."
    SERVICE_CREATE_ERROR="Ошибка: не удалось создать файл службы $SERVICE_FILE."
    ENABLE_ERROR="Ошибка: не удалось активировать службу $SERVICE_NAME."
    START_ERROR="Ошибка: не удалось запустить службу $SERVICE_NAME."
else
    INSTALL_MSG="Do you want to install the autostart script? (y/n): "
    EDIT_MSG="Do you want to open $AUTOSTART_SCRIPT for editing? (y/n): "
    INVALID_EDITOR="Invalid editor choice. Please choose nano or vim."
    SCRIPT_LOCATION="The autostart.sh script is located at: $AUTOSTART_SCRIPT"
    SERVICE_EXISTS="Service $SERVICE_NAME already exists."
    REMOVE_SERVICE_MSG="Do you want to remove autostart for $SERVICE_NAME? (y/n): "
    SERVICE_REMOVED="Service $SERVICE_NAME successfully removed."
    SERVICE_REMOVE_ERROR="Error: Failed to remove service $SERVICE_NAME."
    DIR_ERROR="Error: Failed to create directory /usr/local/tech-scripts"
    SCRIPT_ERROR="Error: Failed to create file $AUTOSTART_SCRIPT."
    CHMOD_ERROR="Error: Failed to make $AUTOSTART_SCRIPT executable."
    SERVICE_CREATE_ERROR="Error: Failed to create service file $SERVICE_FILE."
    ENABLE_ERROR="Error: Failed to enable service $SERVICE_NAME."
    START_ERROR="Error: Failed to start service $SERVICE_NAME."
fi

edit() {
    if whiptail --yesno "$EDIT_MSG" 8 50; then
        if command -v "$EDITOR" &> /dev/null; then
            $SUDO "$EDITOR" "$AUTOSTART_SCRIPT"
        else
            whiptail --msgbox "$INVALID_EDITOR" 8 50
        fi
    fi
    whiptail --msgbox "$SCRIPT_LOCATION" 8 50
}

if systemctl list-units --full --all | grep -q "$SERVICE_NAME"; then
    echo ""
    if whiptail --yesno "$REMOVE_SERVICE_MSG" 8 50; then
        $SUDO systemctl stop "$SERVICE_NAME"
        $SUDO systemctl disable "$SERVICE_NAME"
        if $SUDO rm "$SERVICE_FILE"; then
            whiptail --msgbox "$SERVICE_REMOVED" 8 50
            exit 0
        else
            whiptail --msgbox "$SERVICE_REMOVE_ERROR" 8 50
            exit 0
        fi
        $SUDO systemctl daemon-reload
    else
        edit
    fi
else
    if ! whiptail --yesno "$INSTALL_MSG" 10 50; then
        exit 1
    fi
fi

if ! $SUDO mkdir -p /usr/local/tech-scripts; then
    whiptail --msgbox "$DIR_ERROR" 8 50
    exit 1
fi

{
    echo "#!/bin/sh"
    echo "# Systemd service is located at $SERVICE_FILE"
    echo "echo 'Autostart script executed!'"
    echo "exit 0"
} | $SUDO tee "$AUTOSTART_SCRIPT" > /dev/null

if [ $? -ne 0 ]; then
    whiptail --msgbox "$SCRIPT_ERROR" 8 50
    exit 1
fi

if ! $SUDO chmod +x "$AUTOSTART_SCRIPT"; then
    whiptail --msgbox "$CHMOD_ERROR" 8 50
    exit 1
fi

{
    echo "[Unit]"
    echo "Description=Autostart Script"
    echo ""
    echo "[Service]"
    echo "ExecStart=$AUTOSTART_SCRIPT"
    echo "Type=oneshot"
    echo "RemainAfterExit=yes"
    echo ""
    echo "[Install]"
    echo "WantedBy=multi-user.target"
} | $SUDO tee "$SERVICE_FILE" > /dev/null

if [ $? -ne 0 ]; then
    whiptail --msgbox "$SERVICE_CREATE_ERROR" 8 50
    exit 1
fi

if ! $SUDO systemctl enable "$SERVICE_NAME"; then
    whiptail --msgbox "$ENABLE_ERROR" 8 50
    exit 1
fi

if ! $SUDO systemctl start "$SERVICE_NAME"; then
    whiptail --msgbox "$START_ERROR" 8 50
    exit 1
fi

edit
