#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

detect_init_system() {
    if systemctl --version &> /dev/null; then
        echo "systemd"
    elif openrc-init --version &> /dev/null; then
        echo "openrc"
    elif runit-init --version &> /dev/null; then
        echo "runit"
    elif s6-svscan --version &> /dev/null; then
        echo "s6"
    elif dinit --version &> /dev/null; then
        echo "dinit"
    else
        echo "unknown"
    fi
}

INIT_SYSTEM=$(detect_init_system)

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

remove_service() {
    case $INIT_SYSTEM in
        systemd)
            $SUDO systemctl stop "$SERVICE_NAME"
            $SUDO systemctl disable "$SERVICE_NAME"
            $SUDO rm "$SERVICE_FILE"
            $SUDO systemctl daemon-reload
            ;;
        openrc)
            $SUDO rc-service "$SERVICE_NAME" stop
            $SUDO rc-update del "$SERVICE_NAME"
            $SUDO rm "$SERVICE_FILE"
            ;;
        runit)
            $SUDO sv down "$SERVICE_NAME"
            $SUDO rm -rf /etc/sv/"$SERVICE_NAME"
            $SUDO rm -rf /var/service/"$SERVICE_NAME"
            ;;
        s6)
            $SUDO s6-svc -d /etc/s6/"$SERVICE_NAME"
            $SUDO rm -rf /etc/s6/"$SERVICE_NAME"
            ;;
        dinit)
            $SUDO dinitctl stop "$SERVICE_NAME"
            $SUDO rm -rf /etc/dinit.d/"$SERVICE_NAME"
            ;;
        *)
            whiptail --msgbox "$SERVICE_REMOVE_ERROR" 8 50
            exit 1
            ;;
    esac
    whiptail --msgbox "$SERVICE_REMOVED" 8 50
    exit 0
}

if [ "$INIT_SYSTEM" == "unknown" ]; then
    whiptail --msgbox "$INIT_SYSTEM_UNSUPPORTED" 8 50
    exit 1
fi

case $INIT_SYSTEM in
    systemd)
        if systemctl list-units --full --all | grep -q "$SERVICE_NAME"; then
            if whiptail --yesno "$REMOVE_SERVICE_MSG" 8 50; then
                remove_service
            else
                edit
            fi
        fi
        ;;
    openrc)
        if rc-update show | grep -q "$SERVICE_NAME"; then
            if whiptail --yesno "$REMOVE_SERVICE_MSG" 8 50; then
                remove_service
            else
                edit
            fi
        fi
        ;;
    runit)
        if [ -d /var/service/"$SERVICE_NAME" ]; then
            if whiptail --yesno "$REMOVE_SERVICE_MSG" 8 50; then
                remove_service
            else
                edit
            fi
        fi
        ;;
    s6)
        if [ -d /etc/s6/"$SERVICE_NAME" ]; then
            if whiptail --yesno "$REMOVE_SERVICE_MSG" 8 50; then
                remove_service
            else
                edit
            fi
        fi
        ;;
    dinit)
        if dinitctl list | grep -q "$SERVICE_NAME"; then
            if whiptail --yesno "$REMOVE_SERVICE_MSG" 8 50; then
                remove_service
            else
                edit
            fi
        fi
        ;;
esac

if ! whiptail --yesno "$INSTALL_MSG" 10 50; then
    exit 1
fi

if ! $SUDO mkdir -p /usr/local/tech-scripts; then
    whiptail --msgbox "$DIR_ERROR" 8 50
    exit 1
fi

{
    echo "#!/usr/bin/env bash"
    echo "# Service is located at $SERVICE_FILE"
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

case $INIT_SYSTEM in
    systemd)
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
        $SUDO systemctl enable "$SERVICE_NAME"
        $SUDO systemctl start "$SERVICE_NAME"
        ;;
    openrc)
        {
            echo "#!/sbin/openrc-run"
            echo "command=\"$AUTOSTART_SCRIPT\""
            echo "command_args=\"\""
            echo "depend() {"
            echo "    need localmount"
            echo "}"
        } | $SUDO tee "$SERVICE_FILE" > /dev/null
        $SUDO chmod +x "$SERVICE_FILE"
        $SUDO rc-update add "$SERVICE_NAME"
        $SUDO rc-service "$SERVICE_NAME" start
        ;;
    runit)
        $SUDO mkdir -p /etc/sv/"$SERVICE_NAME"
        {
            echo "#!/bin/sh"
            echo "exec $AUTOSTART_SCRIPT"
        } | $SUDO tee /etc/sv/"$SERVICE_NAME"/run > /dev/null
        $SUDO chmod +x /etc/sv/"$SERVICE_NAME"/run
        $SUDO ln -s /etc/sv/"$SERVICE_NAME" /var/service/
        ;;
    s6)
        $SUDO mkdir -p /etc/s6/"$SERVICE_NAME"
        {
            echo "#!/bin/sh"
            echo "exec $AUTOSTART_SCRIPT"
        } | $SUDO tee /etc/s6/"$SERVICE_NAME"/run > /dev/null
        $SUDO chmod +x /etc/s6/"$SERVICE_NAME"/run
        $SUDO s6-svscanctl -a /etc/s6
        ;;
    dinit)
        {
            echo "type = process"
            echo "command = $AUTOSTART_SCRIPT"
        } | $SUDO tee /etc/dinit.d/"$SERVICE_NAME" > /dev/null
        $SUDO dinitctl enable "$SERVICE_NAME"
        $SUDO dinitctl start "$SERVICE_NAME"
        ;;
esac

if [ $? -ne 0 ]; then
    whiptail --msgbox "$SERVICE_CREATE_ERROR" 8 50
    exit 1
fi

edit
