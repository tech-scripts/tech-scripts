#!/bin/bash

CONFIG_DIR="/etc/tech-scripts"
SCRIPT_DIR="/usr/local/tech-scripts"
CONFIG_FILE="$CONFIG_DIR/alert.conf"
LANG_FILE="/etc/tech-scripts/choose.conf"
LANGUAGE=$(grep -E '^lang:' "$LANG_FILE" | cut -d':' -f2 | xargs)

# Установка текстовых сообщений
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
fi

if [ -f "$CONFIG_FILE" ]; then
    read -p "Вы хотите обноваить скрипт? (y/n): " answer
    if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
        sudo rm "$SCRIPT_DIR/alert.sh"
        echo "Старый скрипт удален."
        sudo systemctl stop ssh.alert.service
        sudo systemctl disable ssh.alert.service
        sudo rm /etc/systemd/system/ssh.alert.service
        sudo systemctl daemon-reload
        echo "Сервис ssh.alert.service удален."
        echo "Скрипт успешно обновлен!"
        exit 0
    else
        echo "Обновление конфигурации отменено."
else

# Проверка и удаление конфигурационного файла
if [ -f "$CONFIG_FILE" ]; then
    read -p "$MSG_REMOVE_CONFIG" REMOVE_CONFIG
    if [ "$REMOVE_CONFIG" = "y" ]; then
        sudo rm "$CONFIG_FILE"
        echo "$MSG_REMOVED"
    else
        echo "$MSG_CANCELED"
    fi
fi

# Проверка и удаление скрипта
if [ -f "$SCRIPT_DIR/alert.sh" ]; then
    read -p "$MSG_REMOVE_SCRIPT" REMOVE_SCRIPT
    if [ "$REMOVE_SCRIPT" = "y" ]; then
        sudo rm "$SCRIPT_DIR/alert.sh"
        echo "$MSG_REMOVED"
    else
        echo "$MSG_CANCELED"
    fi
fi

# Проверка и удаление сервиса
if [ -f "/etc/systemd/system/ssh.alert.service" ]; then
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
fi

# Установка jq, если он не установлен
if ! command -v jq &> /dev/null; then
    echo "$MSG_INSTALL_JQ"
    sudo apt update && sudo apt install -y jq
fi

# Проверка наличия конфигурационного файла
if [ ! -f "$CONFIG_FILE" ]; then
    # Создание конфигурационного файла
    read -p "$MSG_BOT_TOKEN" TELEGRAM_BOT_TOKEN
    read -p "$MSG_CHAT_ID" TELEGRAM_CHAT_ID
    echo "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" > "$CONFIG_FILE"
    echo "TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
else
    echo "Конфигурационный файл $CONFIG_FILE уже существует. Пропускаем создание."
fi

# Проверка наличия скрипта
if [ ! -f "$SCRIPT_DIR/alert.sh" ]; then
    # Создание скрипта
    echo "$MSG_CREATE_SCRIPT"
    sudo mkdir -p "$SCRIPT_DIR"
    sudo bash -c "cat > $SCRIPT_DIR/alert.sh" <<'EOF'
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
        message=$(echo -e "${MSG_FAILED}\nТип подключения: Пароль\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Accepted password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message=$(echo -e "${MSG_SUCCESS}\nТип подключения: Пароль\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Connection closed"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'user \K\w+')
        message=$(echo -e "${MSG_CLOSED}\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Invalid user"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'Invalid user \K\w+')
        message=$(echo -e "${MSG_INVALID_USER}\nТип подключения: Пароль\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Accepted publickey"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'for \K\w+')
        message=$(echo -e "${MSG_SUCCESS}\nТип подключения: Ключ SSH\nПользователь: ${user}\nIP: ${ip}")
        send_telegram_message "$message"
    fi
done
EOF

    # Установка прав на выполнение скрипта
    sudo chmod +x "$SCRIPT_DIR/alert.sh"
else
    echo "Скрипт $SCRIPT_DIR/alert.sh уже существует. Пропускаем создание."
fi

# Проверка и удаление сервиса
if [ -f "/etc/systemd/system/ssh.alert.service" ]; then
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
fi

# Проверка наличия systemd сервиса
if [ ! -f "/etc/systemd/system/ssh.alert.service" ]; then
    # Создание systemd сервиса
    echo "$MSG_ADD_AUTOSTART"
    sudo bash -c "cat > /etc/systemd/system/ssh.alert.service" <<EOF
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
    # Перезагрузка конфигурации systemd
    sudo systemctl daemon-reload
    sudo systemctl enable ssh.alert.service
    sudo systemctl start ssh.alert.service
else
    echo "Сервис ssh.alert.service уже существует. Пропускаем создание."
fi

echo "$MSG_SUCCESS_INSTALL"
echo "$MSG_SCRIPT_LOCATION"
