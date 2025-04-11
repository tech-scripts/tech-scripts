#!/bin/bash

SUDO=$(command -v sudo)

CONFIG_DIR="/etc/tech-scripts"
SCRIPT_DIR="/usr/local/tech-scripts"
CONFIG_FILE="$CONFIG_DIR/alert.conf"
LANG_FILE="/etc/tech-scripts/choose.conf"
LANGUAGE=$(grep -E '^lang:' "$LANG_FILE" | cut -d':' -f2 | xargs)
CONTINUE="true"

if [[ "$LANGUAGE" == "Русский" ]]; then
    MSG_INSTALL_JQ="Установка jq..."
    MSG_BOT_TOKEN="Введите токен вашего Telegram-бота: "
    MSG_CHAT_ID="Введите ваш chat_id в Telegram: "
    MSG_CREATE_SCRIPT="Создание скрипта в $SCRIPT_DIR/alert.sh..."
    MSG_ADD_AUTOSTART="Добавление в автозапуск..."
    MSG_SUCCESS_INSTALL="Скрипт успешно установлен и добавлен в автозапуск."
    MSG_SCRIPT_LOCATION="Скрипт расположен в $SCRIPT_DIR/alert.sh"
    MSG_ALREADY_INSTALLED="Скрипт уже установлен и запущен."
    MSG_REMOVE_CHOICE="Хотите удалить ssh.alert из автозапуска? (y/n): "
    MSG_REMOVED="ssh.alert удален из автозапуска."
    MSG_CANCELED="Удаление отменено."
    MSG_START_CHOICE="Скрипт уже установлен. Хотите запустить его сейчас? (y/n): "
    MSG_STARTED="Скрипт запущен."
    MSG_NOT_STARTED="Скрипт не запущен."
    MSG_SERVICE_MISSING="Скрипт уже установлен, но сервис ssh.alert.service не найден."
    MSG_CREATE_CHOICE="Хотите создать и запустить сервис? (y/n): "
    MSG_SERVICE_CREATED="Сервис создан и запущен."
    MSG_SERVICE_CANCELED="Создание сервиса отменено."
    MSG_REMOVE_CONFIG="Хотите удалить конфигурационный файл $CONFIG_FILE? (y/n): "
    MSG_REMOVE_SCRIPT="Хотите удалить скрипт $SCRIPT_DIR/alert.sh? (y/n): "
    MSG_UPDATE_SCRIPT="Вы хотите обновить скрипт?"
    MSG_UPDATE_CANCELED="Обновление конфигурации отменено!"
    MSG_UPDATE_SUCCESS="Скрипт успешно обновлен!"
    MSG_CREATE_ALERT="Хотите ли вы создать оповещение о входах по SSH через Telegram?"
    MSG_CONFIG_EXISTS="Конфигурационный файл уже существует. Пропускаем создание."
else
    MSG_INSTALL_JQ="Installing jq..."
    MSG_BOT_TOKEN="Enter your Telegram bot token: "
    MSG_CHAT_ID="Enter your Telegram chat_id: "
    MSG_CREATE_SCRIPT="Creating script in $SCRIPT_DIR/alert.sh..."
    MSG_ADD_AUTOSTART="Adding to autostart..."
    MSG_SUCCESS_INSTALL="Script successfully installed and added to autostart."
    MSG_SCRIPT_LOCATION="Script is located in $SCRIPT_DIR/alert.sh"
    MSG_ALREADY_INSTALLED="Script is already installed and running."
    MSG_REMOVE_CHOICE="Do you want to remove ssh.alert from autostart? (y/n): "
    MSG_REMOVED="ssh.alert removed from autostart."
    MSG_CANCELED="Removal canceled."
    MSG_START_CHOICE="Script is already installed. Do you want to start it now? (y/n): "
    MSG_STARTED="Script started."
    MSG_NOT_STARTED="Script not started."
    MSG_SERVICE_MISSING="Script is already installed, but ssh.alert.service is missing."
    MSG_CREATE_CHOICE="Do you want to create and start the service? (y/n): "
    MSG_SERVICE_CREATED="Service created and started."
    MSG_SERVICE_CANCELED="Service creation canceled."
    MSG_REMOVE_CONFIG="Do you want to remove the configuration file $CONFIG_FILE? (y/n): "
    MSG_REMOVE_SCRIPT="Do you want to remove the script $SCRIPT_DIR/alert.sh? (y/n): "
    MSG_UPDATE_SCRIPT="Do you want to update the script?"
    MSG_UPDATE_CANCELED="Configuration update canceled!"
    MSG_UPDATE_SUCCESS="Script successfully updated!"
    MSG_CREATE_ALERT="Do you want to create an SSH login alert via Telegram?"
    MSG_CONFIG_EXISTS="Configuration file already exists. Skipping creation."
fi

show_message() {
    local msg="$1"
    whiptail --msgbox "$msg" 10 50
}

input_box() {
    local title="$1"
    local prompt="$2"
    whiptail --inputbox "$prompt" 10 50 2> /tmp/input.txt
    cat /tmp/input.txt
}

yes_no_box() {
    local title="$1"
    local prompt="$2"
    whiptail --yesno "$prompt" 10 50
    return $?
}

create_ssh_alert_service() {
    if [ ! -f "/etc/systemd/system/ssh.alert.service" ]; then
        $SUDO bash -c "cat > /etc/systemd/system/ssh.alert.service" <<EOF
[Unit]
Description=SSH Alert
After=network.target

[Service]
ExecStart=/usr/local/tech-scripts/alert.sh
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
        $SUDO systemctl enable ssh.alert.service
        $SUDO systemctl start ssh.alert.service
    fi
}

create_ssh_alert_script() {
    if [ ! -f "$SCRIPT_DIR/alert.sh" ]; then
        $SUDO mkdir -p "$SCRIPT_DIR"
        $SUDO bash -c "cat > $SCRIPT_DIR/alert.sh" <<'EOF'
#!/bin/bash

CONFIG_FILE="/etc/tech-scripts/alert.conf"
LANG_FILE="/etc/tech-scripts/choose.conf"

LANGUAGE=$(grep -E '^lang:' "$LANG_FILE" | cut -d':' -f2 | xargs)
source "$CONFIG_FILE"

if [[ "$LANGUAGE" == "Русский" ]]; then
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
        echo "$MSG_ERROR: $response"
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
    fi
}

if [ -f "$CONFIG_FILE" ]; then
    yes_no_box "Обновление скрипта" "$MSG_UPDATE_SCRIPT"
    response=$?
    if [ $response -eq 0 ]; then
        $SUDO rm "$SCRIPT_DIR/alert.sh"
        $SUDO systemctl stop ssh.alert.service
        $SUDO systemctl disable ssh.alert.service
        $SUDO rm /etc/systemd/system/ssh.alert.service
        $SUDO systemctl daemon-reload
        create_ssh_alert_script
        create_ssh_alert_service
        show_message "$MSG_UPDATE_SUCCESS"
        exit 0
    else
        show_message "$MSG_UPDATE_CANCELED"
        exit 1
    fi
fi

if [ -f "$CONFIG_FILE" ]; then
    yes_no_box "Удаление конфигурации" "$MSG_REMOVE_CONFIG"
    response=$?
    if [ $response -eq 0 ]; then
        $SUDO rm "$CONFIG_FILE"
        echo "$MSG_REMOVED"
        CONTINUE="false"
    else
        echo "$MSG_CANCELED"
    fi
fi

if [ -f "$SCRIPT_DIR/alert.sh" ]; then
    yes_no_box "Удаление скрипта" "$MSG_REMOVE_SCRIPT"
    response=$?
    if [ $response -eq 0 ]; then
        $SUDO rm "$SCRIPT_DIR/alert.sh"
        echo "$MSG_REMOVED"
        CONTINUE="false"
    else
        echo "$MSG_CANCELED"
    fi
fi

if [ -f "/etc/systemd/system/ssh.alert.service" ]; then
    yes_no_box "Удаление сервиса" "$MSG_REMOVE_CHOICE"
    response=$?
    if [ $response -eq 0 ]; then
        $SUDO systemctl stop ssh.alert.service
        $SUDO systemctl disable ssh.alert.service
        $SUDO rm /etc/systemd/system/ssh.alert.service
        $SUDO systemctl daemon-reload
        echo "$MSG_REMOVED"
        CONTINUE="false"
    else
        echo "$MSG_CANCELED"
    fi
fi

if ! command -v jq &> /dev/null; then
    show_message "$MSG_INSTALL_JQ"
    yes_no_box "Установка jq" "Хотите установить jq?"
    response=$?
    if [[ $response -eq 0 ]]; then
        $SUDO apt update && $SUDO apt install -y jq
    else
        echo "Установка jq отменена."
    fi
fi

if [ "$CONTINUE" = "false" ]; then
    exit 1
fi

yes_no_box "Создание оповещения" "$MSG_CREATE_ALERT"
response=$?

if [ $response -eq 0 ]; then
    if [ -f "$CONFIG_FILE" ]; then
        CONTINUE="false"
    else
        TELEGRAM_BOT_TOKEN=$(input_box "Telegram Bot Token" "$MSG_BOT_TOKEN")
        TELEGRAM_CHAT_ID=$(input_box "Telegram Chat ID" "$MSG_CHAT_ID")
        echo "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" > "$CONFIG_FILE"
        echo "TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID" >> "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
    fi

    if [ "$CONTINUE" = "false" ]; then
        echo "$MSG_CONFIG_EXISTS"
    else
        create_ssh_alert_script
        create_ssh_alert_service
        echo "$MSG_SUCCESS_INSTALL"
        echo "$MSG_SCRIPT_LOCATION"
    fi
else
    echo ""
fi
