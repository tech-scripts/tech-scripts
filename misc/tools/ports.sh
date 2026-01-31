#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/opt/tech-scripts/source.sh

function get_process_list() {
    # Только TCP, только слушающие порты, без дубликатов
    ss -tlnp 2>/dev/null | awk '
    NR>1 {
        # Извлекаем порт из последней части адреса:порта
        split($5, a, ":")
        port = a[length(a)]
        
        # Извлекаем PID
        pid = ""
        if (match($0, /pid=([0-9]+)/)) {
            pid = substr($0, RSTART+4, RLENGTH-4)
        }
        
        if (pid != "" && port != "") {
            # Используем комбинацию порт:pid как ключ для уникальности
            key = port ":" pid
            if (!seen[key]++) {
                print port, pid
            }
        }
    }' | while read port pid; do
        if [ -d "/proc/$pid" ]; then
            # Быстро получаем информацию о процессе
            user=$(awk '/^Uid:/{print $2}' /proc/$pid/status 2>/dev/null | xargs id -nu 2>/dev/null || echo "unknown")
            process_name=$(cat /proc/$pid/comm 2>/dev/null | tr -d '\0' || echo "unknown")
            echo "$user $process_name $port $pid"
        fi
    done
}

mapfile -t entries < <(get_process_list)

if [ ${#entries[@]} -eq 0 ]; then
    echo "$MSG_NO_PROCESSES"
    exit 0
fi

# Создаем список для whiptail напрямую
whiptail_list=()
index=1
for line in "${entries[@]}"; do
    read user process_name port pid <<< "$line"
    whiptail_list+=("$index. $user ($process_name)" "$port")
    index=$((index + 1))
done

CHOICE=$(whiptail --title "$TITLE" --menu "$MENU_HEADER" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    exit 0
fi

selected_index=$(echo "$CHOICE" | awk '{print $1}' | cut -d'.' -f1)
chosen_entry="${entries[$((selected_index - 1))]}"

pid_to_kill=$(echo "$chosen_entry" | awk '{print $4}')
port_to_kill=$(echo "$chosen_entry" | awk '{print $3}')

if [ -z "$pid_to_kill" ]; then
    echo "$(printf "$MSG_ERROR_PID" "$port_to_kill")"
    exit 1
fi

if (whiptail --title "$TITLE_DANGER" --yesno "$(printf "$MSG_CONFIRM" "$pid_to_kill" "$port_to_kill")" 8 60); then
    kill "$pid_to_kill" 2>/dev/null
    if [ $? -eq 0 ]; then
        exit 0
    else
        whiptail --msgbox "$(printf "$MSG_KILL_FAILED" "$pid_to_kill" "$port_to_kill")" 8 50
    fi
fi
