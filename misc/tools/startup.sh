#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

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

create_systemd_service() {
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
}

create_openrc_service() {
    {
        echo "#!/sbin/openrc-run"
        echo "command=$AUTOSTART_SCRIPT"
        echo "command_background"
        echo "description=\"Autostart Script\""
    } | $SUDO tee "$SERVICE_FILE" > /dev/null
}

create_runit_service() {
    {
        echo "#!/bin/sh"
        echo "exec $AUTOSTART_SCRIPT"
    } | $SUDO tee "$SERVICE_FILE" > /dev/null
}

create_s6_service() {
    {
        echo "#!/bin/sh"
        echo "exec $AUTOSTART_SCRIPT"
    } | $SUDO tee "$SERVICE_FILE" > /dev/null
}

create_dinit_service() {
    {
        echo "service $SERVICE_NAME {"
        echo "    exec = \"$AUTOSTART_SCRIPT\""
        echo "}"
    } | $SUDO tee "$SERVICE_FILE" > /dev/null
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
    echo "#!/usr/bin/env bash"
    echo "# Autostart script executed!"
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

if command -v systemctl &> /dev/null; then
    create_systemd_service
    if ! $SUDO systemctl enable "$SERVICE_NAME"; then
        whiptail --msgbox "$ENABLE_ERROR" 8 50
        exit 1
    fi
    if ! $SUDO systemctl start "$SERVICE_NAME"; then
        whiptail --msgbox "$START_ERROR" 8 50
        exit 1
    fi
elif command -v rc-update &> /dev/null; then
    create_openrc_service
    if ! $SUDO rc-update add "$SERVICE_NAME" default; then
        whiptail --msgbox "$ENABLE_ERROR" 8 50
        exit 1
    fi
    if ! $SUDO service "$SERVICE_NAME" start; then
        whiptail --msgbox "$START_ERROR" 8 50
        exit 1
    fi
elif command -v runit &> /dev/null; then
    create_runit_service
    if ! $SUDO mv "$SERVICE_FILE" /etc/service/; then
        whiptail --msgbox "$ENABLE_ERROR" 8 50
        exit 1
    fi
elif command -v s6 &> /dev/null; then
    create_s6_service
    if ! $SUDO mv "$SERVICE_FILE" /etc/s6/; then
        whiptail --msgbox "$ENABLE_ERROR" 8 50
        exit 1
    fi
elif command -v dinit &> /dev/null; then
    create_dinit_service
    if ! $SUDO mv "$SERVICE_FILE" /etc/dinit/; then
        whiptail --msgbox "$ENABLE_ERROR" 8 50
        exit 1
    fi
else
    whiptail --msgbox "$INIT_SYSTEM_NOT_FOUND" 8 50
    exit 1
fi

edit
