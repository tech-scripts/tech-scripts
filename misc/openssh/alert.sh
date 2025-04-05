#!/bin/bash

CONFIG_DIR="/etc/tech-scripts"
SCRIPT_DIR="/usr/local/tech-scripts"
CONFIG_FILE="$CONFIG_DIR/alert.conf"
LANG_FILE="/etc/tech-scripts/choose.conf"
LANGUAGE=$(grep -E '^lang:' "$LANG_FILE" | cut -d':' -f2 | xargs)
if [ -f "$LANG_FILE" ]; then
    source "$LANG_FILE"
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
    fi
else
    echo "Ошибка: Файл языка не найден."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "$MSG_INSTALL_JQ"
    sudo apt update && sudo apt install -y jq
fi

if [ ! -f "$CONFIG_FILE" ]; then
    read -p "$MSG_BOT_TOKEN" TELEGRAM_BOT_TOKEN
    read -p "$MSG_CHAT_ID" TELEGRAM_CHAT_ID
    echo "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" > "$CONFIG_FILE"
    echo "TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"

    echo "$MSG_CREATE_SCRIPT"
    sudo mkdir -p "$SCRIPT_DIR"
    sudo bash -c "cat > $SCRIPT_DIR/alert.sh" <<'EOF'
#!/bin/bash

CONFIG_FILE="/etc/tech-scripts/alert.conf"
LANG_FILE="/etc/tech-scripts/choose.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Ошибка: Конфигурационный файл не найден."
    exit 1
fi

if [ -f "$LANG_FILE" ]; then
    source "$LANG_FILE"
    if [[ "$lang" == "Русский" ]]; then
        MSG_FAILED="🚨 Неудачная попытка входа 🚨"
        MSG_SUCCESS="✅ Успешный вход ✅"
        MSG_CLOSED="❌ Отмененная попытка входа ❌"
        MSG_ERROR="Ошибка при отправке сообщения"
        MSG_SENT="Сообщение успешно отправлено."
    else
        MSG_FAILED="🚨 Failed login attempt 🚨"
        MSG_SUCCESS="✅ Successful login ✅"
        MSG_CLOSED="❌ Cancelled login attempt ❌"
        MSG_ERROR="Error sending message"
        MSG_SENT="Message sent successfully."
    fi
else
    echo "Ошибка: Файл языка не найден."
    exit 1
fi

send_telegram_message() {
    local message="$1"
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}"
        2>&1)

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
        message="$MSG_FAILED\nПользователь: $user\nIP: $ip"
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Accepted password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message="$MSG_SUCCESS\nПользователь: $user\nIP: $ip"
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Connection closed"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'user \K\w+')
        message="$MSG_CLOSED\nПользователь: $user\nIP: $ip"
        send_telegram_message "$message"
    fi
done
EOF

    sudo chmod +x "$SCRIPT_DIR/alert.sh"

    echo "$MSG_ADD_AUTOSTART"
    sudo bash -c "cat > /etc/systemd/system/ssh.alert.service" <<EOF
[Unit]
Description=SSH Alert Monitor
After=network.target

[Service]
ExecStart=$SCRIPT_DIR/alert.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ssh.alert.service
    sudo systemctl start ssh.alert.service

    echo "$MSG_SUCCESS_INSTALL"
    echo "$MSG_SCRIPT_LOCATION"
else
    if [ -f "/etc/systemd/system/ssh.alert.service" ]; then
        if systemctl is-active --quiet ssh.alert.service; then
            echo "$MSG_ALREADY_INSTALLED"
            read -p "$MSG_REMOVE_CHOICE" REMOVE_CHOICE
            if [ "$REMOVE_CHOICE" = "y" ]; then
                sudo systemctl stop ssh.alert.service
                sudo systemctl disable ssh.alert.service
                sudo rm /etc/systemd/system/ssh.alert.service
                sudo systemctl daemon-reload
                echo "$MSG_REMOVED"
            else
                echo "$MSG_CANCELED"
            fi
        else
            read -p "$MSG_START_CHOICE" START_CHOICE
            if [ "$START_CHOICE" = "y" ]; then
                sudo systemctl start ssh.alert.service
                echo "$MSG_STARTED"
            else
                echo "$MSG_NOT_STARTED"
            fi
        fi
    else
        echo "$MSG_SERVICE_MISSING"
        read -p "$MSG_CREATE_CHOICE" CREATE_CHOICE
        if [ "$CREATE_CHOICE" = "y" ]; then
            sudo bash -c "cat > /etc/systemd/system/ssh.alert.service" <<EOF
[Unit]
Description=SSH Alert Monitor
After=network.target

[Service]
ExecStart=$SCRIPT_DIR/alert.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
            sudo systemctl daemon-reload
            sudo systemctl enable ssh.alert.service
            sudo systemctl start ssh.alert.service
            echo "$MSG_SERVICE_CREATED"
        else
            echo "$MSG_SERVICE_CANCELED"
        fi
    fi
fi
