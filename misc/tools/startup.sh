#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

edit() {
    whiptail --yesno "$EDIT_MSG" 8 50 && {
        command -v "$EDITOR" &>/dev/null && $SUDO "$EDITOR" "$AUTOSTART_SCRIPT" || whiptail --msgbox "$INVALID_EDITOR" 8 50
    }
    whiptail --msgbox "$SCRIPT_LOCATION" 8 50
    exit 0
}

create_systemd_service() {
    $SUDO tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=Autostart Script
ExecStart=$AUTOSTART_SCRIPT
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
}

create_openrc_service() {
    $SUDO tee "$SERVICE_FILE" >/dev/null <<EOF
#!/sbin/openrc-run
command=$AUTOSTART_SCRIPT
command_background
description="Autostart Script"
EOF
}

create_runit_service() {
    $SUDO mkdir -p "/etc/sv/$SERVICE_NAME"
    $SUDO tee "/etc/sv/$SERVICE_NAME/run" >/dev/null <<EOF
#!/bin/sh
exec $AUTOSTART_SCRIPT
EOF
    $SUDO chmod +x "/etc/sv/$SERVICE_NAME/run"
}

create_s6_service() {
    $SUDO mkdir -p "/etc/s6/sv/$SERVICE_NAME"
    $SUDO tee "/etc/s6/sv/$SERVICE_NAME/run" >/dev/null <<EOF
#!/bin/sh
exec $AUTOSTART_SCRIPT
EOF
    $SUDO chmod +x "/etc/s6/sv/$SERVICE_NAME/run"
}

create_dinit_service() {
    $SUDO tee "$SERVICE_FILE" >/dev/null <<EOF
service $SERVICE_NAME {
    exec = "$AUTOSTART_SCRIPT"
}
EOF
}

enable_service() {
    case $1 in
        systemd)
            $SUDO systemctl enable --now "$SERVICE_NAME" || return 1
            ;;
        openrc)
            $SUDO chmod +x "$SERVICE_FILE"
            $SUDO rc-update add "$SERVICE_NAME" default || return 1
            $SUDO rc-service "$SERVICE_NAME" start || return 1
            ;;
        runit)
            $SUDO ln -s "/etc/sv/$SERVICE_NAME" "/var/service/" || return 1
            ;;
        s6)
            $SUDO s6-svscanctl -a "/etc/s6/sv" || return 1
            ;;
        dinit)
            $SUDO dinitctl enable "$SERVICE_NAME" || return 1
            $SUDO dinitctl start "$SERVICE_NAME" || return 1
            ;;
    esac
    return 0
}

remove_service() {
    case $1 in
        systemd)
            $SUDO systemctl stop "$SERVICE_NAME"
            $SUDO systemctl disable "$SERVICE_NAME"
            $SUDO rm -f "$SERVICE_FILE"
            $SUDO systemctl daemon-reload
            ;;
        openrc)
            $SUDO rc-service "$SERVICE_NAME" stop
            $SUDO rc-update del "$SERVICE_NAME"
            $SUDO rm -f "$SERVICE_FILE"
            ;;
        runit)
            $SUDO rm -f "/var/service/$SERVICE_NAME"
            $SUDO rm -rf "/etc/sv/$SERVICE_NAME"
            ;;
        s6)
            $SUDO rm -rf "/etc/s6/sv/$SERVICE_NAME"
            $SUDO s6-svscanctl -a "/etc/s6/sv"
            ;;
        dinit)
            $SUDO dinitctl stop "$SERVICE_NAME"
            $SUDO dinitctl disable "$SERVICE_NAME"
            $SUDO rm -f "$SERVICE_FILE"
            ;;
    esac
}

detect_init() {
    if command -v systemctl &>/dev/null; then echo "systemd"
    elif command -v rc-update &>/dev/null; then echo "openrc"
    elif command -v runsvdir &>/dev/null; then echo "runit"
    elif command -v s6-svscan &>/dev/null; then echo "s6"
    elif command -v dinit &>/dev/null; then echo "dinit"
    else echo "unknown"; fi
}

init_system=$(detect_init)

if [ "$init_system" = "systemd" ] && systemctl list-units --full --all | grep -q "$SERVICE_NAME"; then
    whiptail --yesno "$REMOVE_SERVICE_MSG" 8 50 && {
        remove_service "$init_system"
        whiptail --msgbox "$SERVICE_REMOVED" 8 50
        exit 0
    } || edit
fi

whiptail --yesno "$INSTALL_MSG" 10 50 || exit 1

$SUDO mkdir -p /usr/local/tech-scripts || {
    whiptail --msgbox "$DIR_ERROR" 8 50
    exit 1
}

$SUDO tee "$AUTOSTART_SCRIPT" >/dev/null <<EOF
#!/usr/bin/env bash
# Autostart script executed!
echo 'Autostart script executed!'
exit 0
EOF

$SUDO chmod +x "$AUTOSTART_SCRIPT" || {
    whiptail --msgbox "$CHMOD_ERROR" 8 50
    exit 1
}

case $init_system in
    systemd) 
        create_systemd_service
        SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
        ;;
    openrc) 
        create_openrc_service
        SERVICE_FILE="/etc/init.d/$SERVICE_NAME"
        ;;
    runit) 
        create_runit_service
        SERVICE_FILE="/etc/sv/$SERVICE_NAME/run"
        ;;
    s6) 
        create_s6_service
        SERVICE_FILE="/etc/s6/sv/$SERVICE_NAME/run"
        ;;
    dinit) 
        create_dinit_service
        SERVICE_FILE="/etc/dinit.d/$SERVICE_NAME"
        ;;
    *)
        whiptail --msgbox "$INIT_SYSTEM_NOT_FOUND" 8 50
        exit 1
        ;;
esac

enable_service "$init_system" || {
    whiptail --msgbox "$START_ERROR" 8 50
    exit 1
}

edit
