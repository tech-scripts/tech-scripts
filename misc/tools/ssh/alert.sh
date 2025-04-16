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
    MSG_TEST_MESSAGE="Тестовое сообщение: Вы успешно настроили оповещения SSH!"
    MSG_TEST_SUCCESS="Тестовое сообщение успешно отправлено."
    MSG_TEST_FAILED="Не удалось отправить тестовое сообщение. Проверьте токен и chat_id."
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
    MSG_TEST_MESSAGE="Test message: You have successfully configured SSH alerts!"
    MSG_TEST_SUCCESS="Test message sent successfully."
    MSG_TEST_FAILED="Failed to send test message. Please check your token and chat_id."
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
    local token=$1
    local chat_id=$2
    local message=$3
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${chat_id}" \
        --data-urlencode "text=${message}" 2>&1)

    if echo "$response" | grep -q '"ok":true'; then
        return 0
    else
        return 1
    fi
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
    }
fi

if [ -f "$CONFIG_FILE" ]; then
    yes_no_box "Удаление конфигурации" "$MSG_REMOVE_CONFIG" && {
        $SUDO rm -f "$CONFIG_FILE"
        echo "$MSG_REMOVED"
        CONTINUE="false"
    } || {
        echo "$MSG_CANCELED"
    }
fi

if [ -f "$SCRIPT_DIR/alert.sh" ]; then
    yes_no_box "Удаление скрипта" "$MSG_REMOVE_SCRIPT" && {
        $SUDO rm -f "$SCRIPT_DIR/alert.sh"
        echo "$MSG_REMOVED"
        CONTINUE="false"
    } || {
        echo "$MSG_CANCELED"
    }
fi

if [ -f "/etc/systemd/system/ssh.alert.service" ]; then
    yes_no_box "Удаление сервиса" "$MSG_REMOVE_CHOICE" && {
        $SUDO systemctl stop ssh.alert.service
        $SUDO systemctl disable ssh.alert.service
        $SUDO rm -f /etc/systemd/system/ssh.alert.service
        $SUDO systemctl daemon-reload
        echo "$MSG_REMOVED"
        CONTINUE="false"
    } || {
        echo "$MSG_CANCELED"
    }
fi

install_jq

[ "$CONTINUE" = "false" ] && exit 1

if yes_no_box "Создание оповещения" "$MSG_CREATE_ALERT"; then
    if [ -f "$CONFIG_FILE" ]; then
        echo "$MSG_CONFIG_EXISTS"
    else
        while true; do
            TELEGRAM_BOT_TOKEN=$(input_box "Telegram Bot Token" "$MSG_BOT_TOKEN")
            TELEGRAM_CHAT_ID=$(input_box "Telegram Chat ID" "$MSG_CHAT_ID")

            if send_test_message "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$MSG_TEST_MESSAGE"; then
                show_message "$MSG_TEST_SUCCESS"
                break
            else
                show_message "$MSG_TEST_FAILED"
            fi
        done

        $SUDO mkdir -p "/etc/tech-scripts"
        $SUDO tee "$CONFIG_FILE" >/dev/null <<EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
EOF

        $SUDO chmod 600 "$CONFIG_FILE"
        create_ssh_alert_script
        create_ssh_alert_service
        show_message "$MSG_SUCCESS_INSTALL"
        echo "$MSG_SCRIPT_LOCATION"
    fi
fi
