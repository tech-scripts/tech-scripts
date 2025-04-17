#!/bin/bash

SUDO=$(command -v sudo)
SCRIPT_DIR="/usr/local/tech-scripts"
CONFIG_FILE="/etc/tech-scripts/alert.conf"
LANG_CONF=$(grep '^lang:' /etc/tech-scripts/choose.conf 2>/dev/null | cut -d' ' -f2)

if [[ "$LANG_CONF" == "Русский" ]]; then
    MSG_INSTALL_JQ="Установка jq..."
    MSG_BOT_TOKEN="Введите токен вашего Telegram-бота: "
    MSG_CHAT_ID="Введите ваш chat_id в Telegram: "
    MSG_CREATE_SCRIPT="Создание скрипта в $SCRIPT_DIR/alert.sh..."
    MSG_ADD_AUTOSTART="Добавление в автозапуск..."
    MSG_SUCCESS_INSTALL="Скрипт успешно установлен и добавлен в автозапуск!"
    MSG_SCRIPT_LOCATION="Скрипт расположен в: $SCRIPT_DIR/alert.sh"
    MSG_SERVICE_LOCATION="Сервис скрипта расположен в: /etc/systemd/system/ssh.alert.service"
    MSG_CONFIG_LOCATION="Конфиг скрипта расположен в: $CONFIG_FILE"
    MSG_ALREADY_INSTALLED="Скрипт уже установлен и запущен!"
    MSG_REMOVE_CHOICE="Хотите удалить ssh.alert из автозапуска?"
    MSG_REMOVED="ssh.alert удален из автозапуска!"
    MSG_START_CHOICE="Скрипт уже установлен. Хотите запустить его сейчас?"
    MSG_STARTED="Скрипт запущен!"
    MSG_NOT_STARTED="Скрипт не запущен!"
    MSG_SERVICE_MISSING="Скрипт уже установлен, но сервис ssh.alert.service не найден!"
    MSG_CREATE_CHOICE="Хотите создать и запустить сервис?"
    MSG_SERVICE_CREATED="Сервис создан и запущен!"
    MSG_REMOVE_CONFIG="Хотите удалить конфигурационный файл $CONFIG_FILE?"
    MSG_REMOVE_SCRIPT="Хотите удалить скрипт $SCRIPT_DIR/alert.sh?"
    MSG_UPDATE_SCRIPT="Вы хотите обновить скрипт?"
    MSG_UPDATE_SUCCESS="Скрипт успешно обновлен!"
    MSG_CREATE_ALERT="Хотите ли вы создать оповещение о входах по SSH через Telegram?"
    MSG_CONFIG_EXISTS="Конфигурационный файл уже существует. Пропускаем создание!"
    MSG_TEST_MESSAGE="✅ Вы успешно настроили систему оповещений о входах по SSH ✅"
    MSG_TEST_FAILED="Не удалось отправить тестовое сообщение. Проверьте токен и chat_id!"
else
    MSG_INSTALL_JQ="Installing jq..."
    MSG_BOT_TOKEN="Enter your Telegram bot token: "
    MSG_CHAT_ID="Enter your Telegram chat_id: "
    MSG_CREATE_SCRIPT="Creating script in $SCRIPT_DIR/alert.sh..."
    MSG_ADD_AUTOSTART="Adding to autostart..."
    MSG_SUCCESS_INSTALL="Script successfully installed and added to autostart!"
    MSG_SCRIPT_LOCATION="The script is located in: $SCRIPT_DIR/alert.sh"
    MSG_SERVICE_LOCATION="The script service is located in: /etc/systemd/system/ssh.alert.service"
    MSG_CONFIG_LOCATION="The script config is located in: $CONFIG_FILE"
    MSG_ALREADY_INSTALLED="Script is already installed and running!"
    MSG_REMOVE_CHOICE="Do you want to remove ssh.alert from autostart?"
    MSG_REMOVED="ssh.alert removed from autostart!"
    MSG_START_CHOICE="Script is already installed. Do you want to start it now?"
    MSG_STARTED="Script started!"
    MSG_NOT_STARTED="Script not started!"
    MSG_SERVICE_MISSING="Script is already installed, but ssh.alert.service is missing!"
    MSG_CREATE_CHOICE="Do you want to create and start the service?"
    MSG_SERVICE_CREATED="Service created and started!"
    MSG_REMOVE_CONFIG="Do you want to remove the configuration file $CONFIG_FILE?"
    MSG_REMOVE_SCRIPT="Do you want to remove the script $SCRIPT_DIR/alert.sh?"
    MSG_UPDATE_SCRIPT="Do you want to update the script?"
    MSG_UPDATE_SUCCESS="Script successfully updated!"
    MSG_CREATE_ALERT="Do you want to create an SSH login alert via Telegram?"
    MSG_CONFIG_EXISTS="Configuration file already exists. Skipping creation!"
    MSG_TEST_MESSAGE="✅ You have successfully set up an SSH login notification system ✅"
    MSG_TEST_FAILED="Failed to send test message. Please check your token and chat_id!"
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
    local thread_id=$3
    local message=$4
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${chat_id}" \
        ${thread_id:+-d reply_to_message_id="${thread_id}"} \
        -d disable_notification=true \
        -d protect_content=true \
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
    MSG_ERROR="Ошибка при отправке сообщения"
    MSG_SENT="Сообщение успешно отправлено."
    MSG_SETTINGS="⚙️ Настройки уведомлений ⚙️"
    MSG_ENABLE="✅ Включить"
    MSG_DISABLE="❌ Отключить"
else
    MSG_FAILED="🚨 Failed login attempt 🚨"
    MSG_SUCCESS="✅ Successful login ✅"
    MSG_CLOSED="❌ Cancelled login attempt ❌"
    MSG_ERROR="Error sending message"
    MSG_SENT="Message sent successfully."
    MSG_SETTINGS="⚙️ Notification Settings ⚙️"
    MSG_ENABLE="✅ Enable"
    MSG_DISABLE="❌ Disable"
fi

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
        echo "$MSG_SENT"
        sleep 0.5
    else
        echo "$MSG_ERROR: $response" >&2
    fi
}

send_telegram_menu() {
    local chat_id="$1"
    local message="$2"
    local keyboard="$3"
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${chat_id}" \
        -d text="${message}" \
        -d reply_markup="${keyboard}" 2>&1)
        
    if echo "$response" | grep -q '"ok":true'; then
        echo "$MSG_SENT"
    else
        echo "$MSG_ERROR: $response" >&2
    fi
}

handle_callback_query() {
    local callback_data="$1"
    local chat_id="$2"
    local message_id="$3"

    case "$callback_data" in
        "enable_failed")
            send_telegram_message "$chat_id" "Уведомления о неудачных попытках входа включены."
            ;;
        "disable_failed")
            send_telegram_message "$chat_id" "Уведомления о неудачных попытках входа отключены."
            ;;
        *)
            send_telegram_message "$chat_id" "Неизвестная команда."
            ;;
    esac
}

create_settings_menu() {
    local chat_id="$1"
    local keyboard=$(cat <<EOF
{
    "inline_keyboard": [
        [{"text": "Уведомления о неудачных попытках", "callback_data": "toggle_failed"}],
        [{"text": "Уведомления об успешных попытках", "callback_data": "toggle_success"}],
        [{"text": "Уведомления о закрытых соединениях", "callback_data": "toggle_closed"}]
    ]
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
        message=$(echo -e "${MSG_CLOSED}\nПользователь: ${user}")
        send_telegram_message "$message"
    elif echo "$line" | grep -q "sshd.*Invalid user"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9.]+')
        user=$(echo "$line" | grep -oP 'Invalid user \K\w+')
        message=$(echo -e "${MSG_FAILED}\nТип подключения: пароль\nПользователь: ${user}\nIP: ${ip}")
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
        echo "Не удалось определить пакетный менеджер. Установите jq вручную!" >&2
        exit 1
    fi
}

if [ -f "$CONFIG_FILE" ]; then
    yes_no_box "Обновление скрипта" "$MSG_UPDATE_SCRIPT" && {
        $SUDO rm -f "$SCRIPT_DIR/alert.sh"
        create_ssh_alert_script
        $SUDO systemctl daemon-reload
        echo ""
        echo "$MSG_UPDATE_SUCCESS"
        echo ""
        exit 0
    } || {
        :
    }
fi

if [ -f "$CONFIG_FILE" ] || [ -f "$SCRIPT_DIR/alert.sh" ] || [ -f "/etc/systemd/system/ssh.alert.service" ]; then
    if yes_no_box "Удаление" "Хотите удалить конфигурацию, скрипт и сервис ssh.alert?"; then
        [ -f "$CONFIG_FILE" ] && $SUDO rm -f "$CONFIG_FILE" && echo "" && echo "Конфиг удален: $CONFIG_FILE"
        [ -f "$SCRIPT_DIR/alert.sh" ] && $SUDO rm -f "$SCRIPT_DIR/alert.sh" && echo "Скрипт удален: $SCRIPT_DIR/alert.sh"
        if [ -f "/etc/systemd/system/ssh.alert.service" ]; then
            $SUDO rm -f /etc/systemd/system/ssh.alert.service
            $SUDO systemctl daemon-reload
            echo "Сервис удален: /etc/systemd/system/ssh.alert.service"
            echo ""
            exit 0
        fi
        :
    else
        exit 0
    fi
fi

install_jq

if yes_no_box "Создание оповещения" "$MSG_CREATE_ALERT"; then
    if [ -f "$CONFIG_FILE" ]; then
        echo "$MSG_CONFIG_EXISTS"
    else
        while true; do
            TELEGRAM_BOT_TOKEN=$(input_box "Telegram Bot Token" "$MSG_BOT_TOKEN")
            [ -z "$TELEGRAM_BOT_TOKEN" ] && { exit; }

            TELEGRAM_CHAT_ID=$(input_box "Telegram Chat ID" "$MSG_CHAT_ID")
            [ -z "$TELEGRAM_CHAT_ID" ] && { exit; }
            
            TELEGRAM_THREAD_ID=$(input_box "Telegram Thread ID" "Введите ID цепочки сообщений (необязательно):")
            
            if send_test_message "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$TELEGRAM_THREAD_ID" "$MSG_TEST_MESSAGE"; then
                if yes_no_box "Отправлять без звука?" "Хотите отправлять сообщения без звука?"; then
                    SEND_SILENT=true
                else
                    SEND_SILENT=false
                fi
                
                if yes_no_box "Запретить пересылку?" "Хотите запретить пересылку сообщений?"; then
                    PROTECT_CONTENT=true
                else
                    PROTECT_CONTENT=false
                fi
                
                break
            else
                show_message "$MSG_TEST_FAILED"
            fi
        done

        $SUDO mkdir -p "/etc/tech-scripts"
        $SUDO tee "$CONFIG_FILE" >/dev/null <<EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
TELEGRAM_THREAD_ID=$TELEGRAM_THREAD_ID
SEND_SILENT=$SEND_SILENT
PROTECT_CONTENT=$PROTECT_CONTENT
EOF
        $SUDO chmod 600 "$CONFIG_FILE"
        create_ssh_alert_script
        create_ssh_alert_service
        show_message "$MSG_SUCCESS_INSTALL"
        echo ""
        echo "$MSG_SERVICE_LOCATION"
        echo "$MSG_CONFIG_LOCATION"
        echo "$MSG_SCRIPT_LOCATION"
        echo ""
    fi
fi
