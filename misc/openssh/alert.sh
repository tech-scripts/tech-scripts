#!/bin/bash

# Установка jq, если он не установлен
if ! command -v jq &> /dev/null; then
    echo "Установка jq..."
    sudo apt update && sudo apt install -y jq
fi

# Путь к скрипту
SCRIPT_PATH="/usr/local/tech-scripts/alert.sh"

# Проверка, запущен ли скрипт впервые
if [ ! -f "$SCRIPT_PATH" ]; then
    # Запрос токена бота и chat_id
    read -p "Введите токен вашего Telegram-бота: " TELEGRAM_BOT_TOKEN
    read -p "Введите ваш chat_id в Telegram: " TELEGRAM_CHAT_ID

    # Перемещение скрипта в /usr/local/tech-scripts/
    echo "Перемещение скрипта в $SCRIPT_PATH..."
    sudo mkdir -p /usr/local/tech-scripts/
    sudo cp "$0" "$SCRIPT_PATH"
    sudo chmod +x "$SCRIPT_PATH"

    # Добавление в автозапуск
    echo "Добавление в автозапуск..."
    sudo bash -c "cat > /etc/systemd/system/ssh.alert.service" <<EOF
[Unit]
Description=SSH Alert Monitor
After=network.target

[Service]
ExecStart=$SCRIPT_PATH
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ssh.alert.service
    sudo systemctl start ssh.alert.service

    echo "Скрипт успешно установлен и добавлен в автозапуск."
    echo "Скрипт расположен в $SCRIPT_PATH."
else
    # Если скрипт уже установлен, предложить удалить из автозапуска
    echo "Скрипт уже установлен и расположен в $SCRIPT_PATH."
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
fi

# Основной код мониторинга SSH
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"

send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" > /dev/null
}

journalctl -f -u ssh | while read -r line; do
    if echo "$line" | grep -q "sshd.*Failed password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message="🚨 Неудачная попытка входа 🚨
        Пользователь: $user
        IP: $ip"
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Accepted password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message="✅ Успешный вход ✅
        Пользователь: $user
        IP: $ip"
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Connection closed"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'user \K\w+')
        message="❌ Отмененная попытка входа ❌
        Пользователь: $user
        IP: $ip"
        send_telegram_message "$message"
    fi
done
