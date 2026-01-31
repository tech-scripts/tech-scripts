#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/opt/tech-scripts/source.sh

function get_process_list() {
    ss -tulnp | awk 'NR>1 {
        if (match($5, /.*:([0-9]+)/)) {
            portm = substr($5, RSTART, RLENGTH)
            port = substr(portm, match(portm, /[0-9]+/))
        }
        if (match($0, /pid=([0-9]+)/)) {
            pidm = substr($0, RSTART, RLENGTH)
            pid = substr(pidm, match(pidm, /[0-9]+/))
        }
        if (pid != "") {
            print port, pid;
        }
    }' | sort -u | while read port pid; do
        if [ -d "/proc/$pid" ]; then
            user=$(ps -o user= -p $pid | xargs)
            process_name=$(ps -o comm= -p $pid | xargs)
            echo "$user $process_name $port $pid"
        fi
    done
}

mapfile -t entries < <(get_process_list)

if [ ${#entries[@]} -eq 0 ]; then
    echo "$MSG_NO_PROCESSES"
    exit 0
fi

declare -A user_ports user_port_count

for line in "${entries[@]}"; do
    read user process_name port pid <<< "$line"
    user_ports["$user"]+="$process_name:$port "
    user_port_count["$user"]=$((user_port_count["$user"] + 1))
done

sorted_users=($(for u in "${!user_port_count[@]}"; do echo "$u ${user_port_count[$u]}"; done | sort -k2,2n | awk '{print $1}'))

whiptail_list=()
index=1
for user in "${sorted_users[@]}"; do
    ports="${user_ports[$user]}"
    for entry in $ports; do
        process_name=$(echo "$entry" | cut -d':' -f1)
        port=$(echo "$entry" | cut -d':' -f2)
        pid=$(echo "${entries[@]}" | grep "$user $process_name $port" | awk '{print $4}')
        whiptail_list+=("$index. $user ($process_name)" "$port")
        index=$((index + 1))
    done
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
