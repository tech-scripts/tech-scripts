#!/bin/bash

SUDO=$(command -v sudo || echo "")
AUTOSTART_SCRIPT="/usr/local/tech-scripts/autostart.sh"
SERVICE_FILE="/etc/systemd/system/autostart.service"
SERVICE_NAME="autostart.service"

LANG_CONF=""
[ -f /etc/tech-scripts/choose.conf ] && LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d':' -f2 | tr -d ' ')

if [ "$LANG_CONF" = "Русский" ]; then
    EDIT_MSG="Хотите открыть $AUTOSTART_SCRIPT для редактирования? (y/n): "
    EDITOR_MSG="Выберите редактор (nano/vim): "
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
    EDIT_MSG="Do you want to open $AUTOSTART_SCRIPT for editing? (y/n): "
    EDITOR_MSG="Choose an editor (nano/vim): "
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
    read -p "$EDIT_MSG" OPEN_SCRIPT
    if [[ "$OPEN_SCRIPT" == "y" || "$OPEN_SCRIPT" == "Y" ]]; then
        while true; do
            read -p "$EDITOR_MSG" EDITOR
            if [[ "$EDITOR" == "nano" ]]; then
                $SUDO nano "$AUTOSTART_SCRIPT"
                break
            elif [[ "$EDITOR" == "vim" ]]; then
                $SUDO vim "$AUTOSTART_SCRIPT"
                break
            else
                echo "$INVALID_EDITOR"
            fi
        done
    fi
    echo -e "\n$SCRIPT_LOCATION"
}

if systemctl list-units --full --all | grep -q "$SERVICE_NAME"; then
    echo "$SERVICE_EXISTS"
    read -p "$REMOVE_SERVICE_MSG" REMOVE_SERVICE
    if [[ "$REMOVE_SERVICE" == "y" || "$REMOVE_SERVICE" == "Y" ]]; then
        $SUDO systemctl stop "$SERVICE_NAME"
        $SUDO systemctl disable "$SERVICE_NAME"
        if $SUDO rm "$SERVICE_FILE"; then
            echo "$SERVICE_REMOVED"
            exit 0
        else
            echo "$SERVICE_REMOVE_ERROR"
        fi
        $SUDO systemctl daemon-reload
    else
        echo -e "\n"
        edit
        exit 0
    fi
fi

if ! $SUDO mkdir -p /usr/local/tech-scripts; then
    echo "$DIR_ERROR"
    exit 1
fi

{
    echo "#!/bin/sh"
    echo "# Systemd service is located at $SERVICE_FILE"
    echo "echo 'Autostart script executed!'"
    echo "exit 0"
} | $SUDO tee "$AUTOSTART_SCRIPT" > /dev/null

if [ $? -ne 0 ]; then
    echo "$SCRIPT_ERROR"
    exit 1
fi

if ! $SUDO chmod +x "$AUTOSTART_SCRIPT"; then
    echo "$CHMOD_ERROR"
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
    echo "$SERVICE_CREATE_ERROR"
    exit 1
fi

if ! $SUDO systemctl enable "$SERVICE_NAME"; then
    echo "$ENABLE_ERROR"
    exit 1
fi

if ! $SUDO systemctl start "$SERVICE_NAME"; then
    echo "$START_ERROR"
    exit 1
fi

edit
