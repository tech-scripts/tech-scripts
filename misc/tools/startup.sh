#!/bin/bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

edit() {
    if whiptail --yesno "$EDIT_MSG" 8 50; then
        if command -v "$EDITOR" &> /dev/null; then
            $SUDO "$EDITOR" "$AUTOSTART_SCRIPT"
        else
            whiptail --msgbox "$INVALID_EDITOR" 8 50
        fi
    fi
    whiptail --msgbox "$SCRIPT_LOCATION" 8 50
    exit 0
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
