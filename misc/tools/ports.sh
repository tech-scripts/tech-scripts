#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/opt/tech-scripts/source.sh

function get_process_list() {
    ss -tlnp 2>/dev/null | awk '
    NR>1 {
        # 5-е поле содержит адрес:порт или просто *
        local_info = $5
        
        # Извлекаем порт (после последнего двоеточия)
        port = local_info
        if (local_info ~ /:/) {
            # Разделяем по двоеточиям
            n = split(local_info, parts, ":")
            port = parts[n]
        }
        
        # Игнорируем если порт = * (не конкретный порт)
        if (port == "*") {
            next
        }
        
        # Извлекаем PID
        pid = ""
        if (match($0, /pid=([0-9]+)/)) {
            pid = substr($0, RSTART+4, RLENGTH-4)
        }
        
        if (pid != "" && port != "") {
            # Уникальная комбинация порт:pid
            key = port ":" pid
            if (!seen[key]++) {
                print port, pid
            }
        }
    }' | while read port pid; do
        if [ -d "/proc/$pid" ]; then
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

# Сортируем по порту для удобства
IFS=$'\n' sorted_entries=($(sort -k3 -n <<<"${entries[*]}"))
unset IFS

whiptail_list=()
for i in "${!sorted_entries[@]}"; do
    read user process_name port pid <<< "${sorted_entries[$i]}"
    whiptail_list+=("$((i+1)). $user ($process_name)" "$port")
done

CHOICE=$(whiptail --title "$TITLE" --menu "$MENU_HEADER" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)
[ $? -ne 0 ] && exit 0

selected_index=$(echo "$CHOICE" | cut -d'.' -f1)
chosen_entry="${sorted_entries[$((selected_index - 1))]}"
read user process_name port_to_kill pid_to_kill <<< "$chosen_entry"

[ -z "$pid_to_kill" ] && echo "$(printf "$MSG_ERROR_PID" "$port_to_kill")" && exit 1

if whiptail --title "$TITLE_DANGER" --yesno "$(printf "$MSG_CONFIRM" "$pid_to_kill" "$port_to_kill")" 8 60; then
    kill "$pid_to_kill" 2>/dev/null && exit 0
    whiptail --msgbox "$(printf "$MSG_KILL_FAILED" "$pid_to_kill" "$port_to_kill")" 8 50
fi
