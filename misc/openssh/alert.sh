#!/bin/bash

CONFIG_DIR="/etc/tech-scripts"
SCRIPT_DIR="/usr/local/tech-scripts"
CONFIG_FILE="$CONFIG_DIR/alert.conf"
LANG_FILE="$CONFIG_DIR/choose.conf"

if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt update && sudo apt install -y jq
fi

if [ ! -f "$CONFIG_FILE" ]; then
    read -p "Введите токен вашего Telegram-бота: " TELEGRAM_BOT_TOKEN
    read -p "Введите ваш chat_id в Telegram: " TELEGRAM_CHAT_ID
    echo "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" > "$CONFIG_FILE"
    echo "TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"

    echo "Создание скрипта в $SCRIPT_DIR/alert.sh..."
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
        -d text="${message}" 2>&1)

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

    echo "Добавление в автозапуск..."
    sudo bash -c "cat > /etc/systemd/system/ssh.alert.service" <<EOF
[Unit]
Description=SSH Alert Monitor
After=network.target

[Service]
ExecStart=$SCRIPT_DIR/alert.sh
Restart=always
User =root

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ssh.alert.service
    sudo systemctl start ssh.alert.service
    echo "Скрипт успешно установлен и добавлен в автозапуск."
    echo "Скрипт расположен в $SCRIPT_DIR/alert.sh"
else
    if [ -f "/etc/systemd/system/ssh.alert.service" ]; then
        if systemctl is-active --quiet ssh.alert.service; then
            echo "Скрипт уже установлен и запущен."
            read -p "Хотите удалить ssh.alert из автозапуска? (y/n): " REMOVE_CHOICE
            if [ "$REMOVE_CHOICE" = "y" ]; then
                sudo systemctl stop ssh.alert.service
                sudo systemctl disable ssh.alert.service
                sudo rm /etc/systemd/system/ssh.alert.service
                sudo systemctl daemon-reload
                echo "ssh.alert удален из автозапуска."
            else
                echo "Удаление отменено."
            fi
        else
            read -p "Скрипт уже установлен. Хотите запустить его сейчас? (y/n): " START_CHOICE
            if [ "$START_CHOICE" = "y" ]; then
                sudo systemctl start ssh.alert.service
                echo "Скрипт запущен."
            else
                echo "Скрипт не запущен."
            fi
        fi
    else
        echo "Скрипт уже установлен, но сервис ssh.alert.service не найден."
        read -p "Хотите создать и запустить сервис? (y/n): " CREATE_CHOICE
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
            echo "Сервис создан и запущен."
        else
            echo "Создание сервиса отменено."
        fi
    fi
fi
