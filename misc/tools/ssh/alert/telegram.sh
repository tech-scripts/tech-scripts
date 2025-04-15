#!/bin/bash

SUDO=$(command -v sudo)
SCRIPT_DIR="/usr/local/tech-scripts"
CONFIG_FILE="/etc/tech-scripts/alert.conf"
LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d' ' -f2)
CONTINUE="true"

export TERM=xterm
export NCURSES_NO_UTF8_ACS=1

if [[ "$LANG_CONF" == "Русский" ]]; then
    MSG_INSTALL_JQ="Установка jq..."
    MSG_BOT_TOKEN="Введите токен вашего Telegram-бота: "
    MSG_CHAT_ID="Введите ваш chat_id в Telegram: "
    MSG_TEST_SENDING="Отправка тестового сообщения..."
    MSG_TEST_SUCCESS="✅ Тестовое сообщение успешно отправлено!"
    MSG_TEST_FAILED="❌ Ошибка отправки сообщения! Проверьте токен и chat_id"
    MSG_RETRY="Повторить ввод данных?"
    MSG_SUCCESS_INSTALL="Скрипт успешно установлен и добавлен в автозапуск."
    MSG_SCRIPT_LOCATION="Скрипт расположен в $SCRIPT_DIR/alert.sh"
    MSG_CONFIG_EXISTS="Конфигурационный файл уже существует. Пропускаем создание."
else
    MSG_INSTALL_JQ="Installing jq..."
    MSG_BOT_TOKEN="Enter your Telegram bot token: "
    MSG_CHAT_ID="Enter your Telegram chat_id: "
    MSG_TEST_SENDING="Sending test message..."
    MSG_TEST_SUCCESS="✅ Test message sent successfully!"
    MSG_TEST_FAILED="❌ Failed to send message! Check token and chat_id"
    MSG_RETRY="Retry entering data?"
    MSG_SUCCESS_INSTALL="Script successfully installed and added to autostart."
    MSG_SCRIPT_LOCATION="Script is located in $SCRIPT_DIR/alert.sh"
    MSG_CONFIG_EXISTS="Configuration file already exists. Skipping creation."
fi

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
    local token="$1"
    local chat_id="$2"
    
    show_message "$MSG_TEST_SENDING"
    
    local response=$(curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${chat_id}" \
        -d text="Test message from setup script" 2>/dev/null)
        
    if echo "$response" | grep -q '"ok":true'; then
        show_message "$MSG_TEST_SUCCESS"
        return 0
    else
        show_message "$MSG_TEST_FAILED"
        return 1
    fi
}

get_telegram_credentials() {
    while true; do
        local token=$(input_box "Telegram Bot Token" "$MSG_BOT_TOKEN")
        local chat_id=$(input_box "Telegram Chat ID" "$MSG_CHAT_ID")
        
        if send_test_message "$token" "$chat_id"; then
            echo "$token"
            echo "$chat_id"
            return 0
        fi
        
        yes_no_box "$MSG_RETRY" "$MSG_RETRY" || return 1
    done
}

create_ssh_alert_service() {
    [ -f "/etc/systemd/system/ssh.alert.service" ] && return
    
    $SUDO tee "/etc/systemd/system/ssh.alert.service" >/dev/null <<EOF
[Unit]
Description=SSH Alert
After=network.target

[Service]
ExecStart=$SCRIPT_DIR/alert.sh
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

create_ssh_alert_script() {
    [ -f "$SCRIPT_DIR/alert.sh" ] && return
    
    $SUDO mkdir -p "$SCRIPT_DIR"
    $SUDO tee "$SCRIPT_DIR/alert.sh" >/dev/null <<'EOF'
#!/bin/bash

CONFIG_FILE="/etc/tech-scripts/alert.conf"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d' ' -f2)

if [[ "$LANG_CONF" == "Русский" ]]; then
    MSG_FAILED="🚨 Неудачная попытка входа 🚨"
    MSG_SUCCESS="✅ Успешный вход ✅"
    MSG_CLOSED="❌ Отмененная попытка входа ❌"
    MSG_INVALID_USER="🚨 Неудачная попытка входа 🚨"
    MSG_ERROR="Ошибка при отправке сообщения"
    MSG_SENT="Сообщение успешно отправлено."
else
    MSG_FAILED="🚨 Failed login attempt 🚨"
    MSG_SUCCESS="✅ Successful login ✅"
    MSG_CLOSED="❌ Cancelled login attempt ❌"
    MSG_INVALID_USER="🚨 Failed login attempt 🚨"
    MSG_ERROR="Error sending message"
    MSG_SENT="Message sent successfully."
fi

send_telegram_message() {
    local message="$1"
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${message}" 2>&1)

    if echo "$response" | grep -q '"ok":true'; then
        echo "$MSG_SENT"
    else
        echo "$MSG_ERROR: $response" >&2
    fi
}

journalctl -f -u ssh | while read -r line; do
    if echo "$line" | grep -q "sshd.*Failed password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message=$(echo -e "${MSG_FAILED}\nТип подключения: пароль\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Accepted password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message=$(echo -e "${MSG_SUCCESS}\nТип подключения: пароль\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Connection closed"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'user \K\w+')
        message=$(echo -e "${MSG_CLOSED}\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Invalid user"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'Invalid user \K\w+')
        message=$(echo -e "${MSG_INVALID_USER}\nТип подключения: пароль\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Accepted publickey"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message=$(echo -e "${MSG_SUCCESS}\nТип подключения: ключ ssh\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    fi
done
EOF

    $SUDO chmod +x "$SCRIPT_DIR/alert.sh"
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
        echo "Не удалось определить пакетный менеджер. Установите jq вручную." >&2
        exit 1
    fi
}

if [ -f "$CONFIG_FILE" ]; then
    yes_no_box "Обновление скрипта" "$MSG_UPDATE_SCRIPT" && {
        $SUDO rm -f "$SCRIPT_DIR/alert.sh"
        create_ssh_alert_script
        $SUDO systemctl daemon-reload
        show_message "$MSG_UPDATE_SUCCESS"
        exit 0
    } || {
        show_message "$MSG_UPDATE_CANCELED"
        exit 0
    }
fi

install_jq

if [ -f "$CONFIG_FILE" ]; then
    show_message "$MSG_CONFIG_EXISTS"
else
    credentials=$(get_telegram_credentials)
    if [ $? -eq 0 ]; then
        token=$(echo "$credentials" | head -n 1)
        chat_id=$(echo "$credentials" | tail -n 1)
        
        $SUDO mkdir -p "/etc/tech-scripts"
        $SUDO tee "$CONFIG_FILE" >/dev/null <<EOF
TELEGRAM_BOT_TOKEN=$token
TELEGRAM_CHAT_ID=$chat_id
EOF
        
        $SUDO chmod 600 "$CONFIG_FILE"
        create_ssh_alert_script
        create_ssh_alert_service
        show_message "$MSG_SUCCESS_INSTALL"
        echo "$MSG_SCRIPT_LOCATION"
    else
        show_message "Настройка отменена"
        exit 1
    fi
fi
