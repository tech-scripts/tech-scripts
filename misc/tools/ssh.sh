#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

show_message() {
    whiptail --msgbox "$1" 10 50
}

input_box() {
    exec 3>&1
    local result=$(whiptail --title "$1" --inputbox "$2" 10 60 3>&1 1>&2 2>&3)
    exec 3>&-
    echo "$result"
}

yes_no_box() {
    whiptail --yesno "$2" 10 50
    return $?
}

send_test_message() {
    local token=$1
    local chat_id=$2
    local thread_id=$3
    local message=$4
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${chat_id}" \
        ${thread_id:+-d reply_to_message_id="${thread_id}"} \
        --data-urlencode "text=${message}" 2>&1)
    if echo "$response" | grep -q '"ok":true'; then
        return 0
    else
        return 1
    fi
}

detect_init_system() {
    if [ -d /run/systemd/system ]; then
        echo "systemd"
    elif [ -x /sbin/openrc-run ]; then
        echo "openrc"
    elif [ -x /usr/bin/runsvdir ]; then
        echo "runit"
    elif [ -x /usr/bin/s6-svscan ]; then
        echo "s6"
    elif [ -x /usr/bin/dinit ]; then
        echo "dinit"
    else
        echo "$INIT_SYSTEM_NOT_FOUND"
    fi
}

create_systemd_service() {
    $SUDO tee "/etc/systemd/system/ssh.alert.service" >/dev/null <<EOF
[Unit]
Description=SSH Alert
After=network.target

[Service]
ExecStart=$SCRIPT_DIR_SSH/alert.sh
Restart=always
User=root
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=ssh-alert-monitor

[Install]
WantedBy=multi-user.target
EOF
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now ssh.alert.service
}

create_openrc_service() {
    $SUDO tee "/etc/init.d/ssh-alert" >/dev/null <<EOF
#!/sbin/openrc-run
command="$SCRIPT_DIR_SSH/alert.sh"
command_background=true
pidfile="/run/ssh-alert.pid"
name="SSH Alert"
description="Monitors SSH login attempts"

depend() {
    need net
    after net
}

start() {
    ebegin "Starting \$name"
    start-stop-daemon --start --background --make-pidfile --pidfile \$pidfile --exec \$command
    eend \$?
}

stop() {
    ebegin "Stopping \$name"
    start-stop-daemon --stop --pidfile \$pidfile
    eend \$?
}
EOF
    $SUDO chmod +x /etc/init.d/ssh-alert
    $SUDO rc-update add ssh-alert default
    $SUDO rc-service ssh-alert start
}

create_runit_service() {
    $SUDO mkdir -p /etc/sv/ssh-alert
    $SUDO tee "/etc/sv/ssh-alert/run" >/dev/null <<EOF
#!/bin/sh
exec $SCRIPT_DIR_SSH/alert.sh
EOF
    $SUDO chmod +x /etc/sv/ssh-alert/run
    $SUDO ln -s /etc/sv/ssh-alert /var/service/
}

create_s6_service() {
    $SUDO mkdir -p /etc/s6/sv/ssh-alert
    $SUDO tee "/etc/s6/sv/ssh-alert/run" >/dev/null <<EOF
#!/bin/sh
exec $SCRIPT_DIR_SSH/alert.sh
EOF
    $SUDO chmod +x /etc/s6/sv/ssh-alert/run
    $SUDO s6-svscanctl -a /etc/s6/sv
}

create_dinit_service() {
    $SUDO tee "/etc/dinit.d/ssh-alert" >/dev/null <<EOF
type = process
command = "$SCRIPT_DIR_SSH/alert.sh"
restart = true
EOF
    $SUDO dinitctl enable ssh-alert
    $SUDO dinitctl start ssh-alert
}

create_init_service() {
    local init_system=$(detect_init_system)
    case $init_system in
        systemd) create_systemd_service ;;
        openrc) create_openrc_service ;;
        runit) create_runit_service ;;
        s6) create_s6_service ;;
        dinit) create_dinit_service ;;
        *) echo "$UNSUPPORTED_INIT_SYSTEM"; exit 1 ;;
    esac
}

remove_init_service() {
    local init_system=$(detect_init_system)
    case $init_system in
        systemd) 
            $SUDO systemctl stop ssh.alert.service
            $SUDO systemctl disable ssh.alert.service
            $SUDO rm -f /etc/systemd/system/ssh.alert.service
            $SUDO systemctl daemon-reload
            ;;
        openrc)
            $SUDO rc-service ssh-alert stop
            $SUDO rc-update del ssh-alert
            $SUDO rm -f /etc/init.d/ssh-alert
            ;;
        runit)
            $SUDO rm -f /var/service/ssh-alert
            $SUDO rm -rf /etc/sv/ssh-alert
            ;;
        s6)
            $SUDO s6-svc -d /etc/s6/sv/ssh-alert
            $SUDO rm -rf /etc/s6/sv/ssh-alert
            $SUDO s6-svscanctl -a /etc/s6/sv
            ;;
        dinit)
            $SUDO dinitctl stop ssh-alert
            $SUDO dinitctl disable ssh-alert
            $SUDO rm -f /etc/dinit.d/ssh-alert
            ;;
    esac
}

create_ssh_alert_script() {
    [ -f "$SCRIPT_DIR_SSH/alert.sh" ] && return
    $SUDO mkdir -p "$SCRIPT_DIR_SSH"
    $SUDO tee "$SCRIPT_DIR_SSH/alert.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

[ -f "$CONFIG_FILE_SSH" ] && source "$CONFIG_FILE_SSH"

send_telegram_message() {
    local message="$1"
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        ${TELEGRAM_THREAD_ID:+-d reply_to_message_id="${TELEGRAM_THREAD_ID}"} \
        -d disable_notification="${SEND_SILENT}" \
        ${PROTECT_CONTENT:+-d protect_content=true} \
        --data-urlencode "text=${message}" 2>&1)
        
    if echo "$response" | grep -q '"ok":true'; then
        echo "$SENT_SSH"
    else
        echo "$ERROR_SSH: $response" >&2
    fi
}

journalctl -f -u ssh | while read -r line; do
    if echo "$line" | grep -q "sshd.*Failed password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message=$(echo -e "${FAILED_SSH}\n$HOST_NAME_MSG $HOST_NAME\n${CONNECTION_SSH} ${PASSWORD_SSH}\n${USER_SSH} ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Accepted password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message=$(echo -e "${SUCCESS_SSH}\n$HOST_NAME_MSG $HOST_NAME\n${CONNECTION_SSH} ${PASSWORD_SSH}\n${USER_SSH} ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Connection closed"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'user \K\w+')
        message=$(echo -e "${CLOSED_SSH}\n$HOST_NAME_MSG $HOST_NAME\n${USER_SSH} ${user}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Invalid user"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'Invalid user \K\w+')
        message=$(echo -e "${FAILED_SSH}\n$HOST_NAME_MSG $HOST_NAME\n${CONNECTION_SSH} ${PASSWORD_SSH}\n${USER_SSH} ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Accepted publickey"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message=$(echo -e "${SUCCESS_SSH}\n$HOST_NAME_MSG $HOST_NAME\n${CONNECTION_SSH} ${KEY_SSH}\n${USER_SSH} ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    fi
done
EOF

    $SUDO chmod +x "$SCRIPT_DIR_SSH/alert.sh"
}

install_jq() {
    command -v jq &>/dev/null && return
    
    if command -v apt &>/dev/null; then
        $SUDO apt update && $SUDO apt install -y jq
    elif command -v yum &>/dev/null; then
        $SUDO yum install -y jq
    elif command -v dnf &>/dev/null; then
        $SUDO dnf install -y jq
    elif command -v zypper &>/dev/null; then
        $SUDO zypper install -y jq
    elif command -v pacman &>/dev/null; then
        $SUDO pacman -S --noconfirm jq
    elif command -v apk &>/dev/null; then
        $SUDO apk add jq
    elif command -v brew &>/dev/null; then
        brew install jq
    else
        echo "$JQ_NOT_FOUND_SSH"
        exit 1
    fi
}

if [ -f "$CONFIG_FILE_SSH" ]; then
    yes_no_box "$SCRIPT_UPDATE_SSH" "$UPDATE_SCRIPT_SSH" && {
        $SUDO rm -f "$SCRIPT_DIR_SSH/alert.sh"
        create_ssh_alert_script
        remove_init_service
        create_init_service
        echo ""
        echo "$UPDATE_SUCCESS_SSH"
        echo ""
        exit 0
    } || {
        :
    }
fi

if [ -f "$CONFIG_FILE_SSH" ] || [ -f "$SCRIPT_DIR_SSH/alert.sh" ]; then
    if yes_no_box "$REMOVE_SSH" "$REMOVE_ALL_SSH"; then
        [ -f "$CONFIG_FILE_SSH" ] && $SUDO rm -f "$CONFIG_FILE_SSH" && echo "" && echo "$CONFIG_REMOVE_SSH $CONFIG_FILE_SSH"
        [ -f "$SCRIPT_DIR_SSH/alert.sh" ] && $SUDO rm -f "$SCRIPT_DIR_SSH/alert.sh" && echo "$SCRIPT_REMOVE_SSH $SCRIPT_DIR_SSH/alert.sh"
        remove_init_service
        echo "$SERVICE_REMOVED_SSH"
        echo ""
        exit 0
    else
        echo ""
        echo "$SERVICE_LOCATION_SSH"
        echo "$CONFIG_LOCATION_SSH $CONFIG_FILE_SSH"
        echo "$SCRIPT_LOCATION_SSH $SCRIPT_DIR_SSH/alert.sh"
        echo ""
        exit 0
    fi
fi

install_jq

if yes_no_box "$CREATE_NOTIFY_SSH" "$CREATE_ALERT_SSH"; then
    if [ -f "$CONFIG_FILE_SSH" ]; then
        echo "$CONFIG_EXISTS_SSH"
    else
        while true; do
            TELEGRAM_BOT_TOKEN=$(input_box "Telegram Bot Token" "$BOT_TOKEN_SSH")
            [ -z "$TELEGRAM_BOT_TOKEN" ] && { exit; }

            TELEGRAM_CHAT_ID=$(input_box "Telegram Chat ID" "$CHAT_ID_SSH")
            [ -z "$TELEGRAM_CHAT_ID" ] && { exit; }
            
            TELEGRAM_THREAD_ID=$(input_box "Telegram Thread ID" "$SUPER_GROUP_ID_SSH")
            
            if send_test_message "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$TELEGRAM_THREAD_ID" "$TEST_MESSAGE_SSH"; then
            
                HOST_NAME=$(input_box "Host Name" "$HOST_NAME_SSH")
                
                if yes_no_box "$SELECTION_MENU" "$PROHIBIT_SOUND_SSH"; then
                    SEND_SILENT=true
                else
                    SEND_SILENT=false
                fi
                
                if yes_no_box "$SELECTION_MENU" "$PROHIBIT_FORWARDING_SSH"; then
                    PROTECT_CONTENT=true
                else
                    PROTECT_CONTENT=false
                fi
                
                break
            else
                show_message "$TEST_FAILED_SSH"
            fi
        done

        $SUDO mkdir -p "/etc/tech-scripts"
        $SUDO tee "$CONFIG_FILE_SSH" >/dev/null <<EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
TELEGRAM_THREAD_ID=$TELEGRAM_THREAD_ID
HOST_NAME=$HOST_NAME
SEND_SILENT=$SEND_SILENT
PROTECT_CONTENT=$PROTECT_CONTENT
EOF
        $SUDO chmod 600 "$CONFIG_FILE_SSH"
        create_ssh_alert_script
        create_init_service
        show_message "$SUCCESS_INSTALL_SSH"
        echo ""
        echo "$SERVICE_LOCATION_SSH"
        echo "$CONFIG_LOCATION_SSH $CONFIG_FILE_SSH"
        echo "$SCRIPT_LOCATION_SSH $SCRIPT_DIR_SSH/alert.sh"
        echo ""
    fi
fi
