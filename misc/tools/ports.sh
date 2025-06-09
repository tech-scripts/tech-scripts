#!/usr/bin/env bash

function get_process_list() {
  ss -tulnp | awk 'NR>1 {
    match($5, /.*:([0-9]+)/, portm);
    match($0, /pid=([0-9]+)/, pidm);
    if (pidm[1] != "") {
      print portm[1], pidm[1];
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
  echo "Слушающих процессов на портах не найдено!"
  exit 0
fi

declare -A user_ports
declare -A user_port_count

for line in "${entries[@]}"; do
  read user process_name port pid <<< "$line"
  user_ports["$user"]+="$process_name:$port "
  user_port_count["$user"]=$((user_port_count["$user"] + 1))
done

sorted_users=($(for u in "${!user_port_count[@]}"; do echo "$u ${user_port_count[$u]}"; done | sort -k2,2n | awk '{print $1}'))

whiptail_list=()
for index in "${!entries[@]}"; do
  line="${entries[$index]}"
  read user process_name port pid <<< "$line"
  unique_id="$index"
  whiptail_list+=("$unique_id" "$user ($process_name) - Порт: $port")
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "Пользователь Процесс Порт:" 20 70 15 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  exit 0
fi

chosen_id="$CHOICE"
chosen_entry="${entries[$chosen_id]}"

if [ -z "$chosen_entry" ]; then
  echo "Ошибка: Не удалось определить выбранный процесс!"
  exit 1
fi

read chosen_user chosen_process chosen_port pid_to_kill <<< "$chosen_entry"

if (whiptail --title "Подтверждение" --yesno "Завершить процесс PID $pid_to_kill, принадлежащий пользователю $chosen_user ($chosen_process) на порту $chosen_port?" 8 70); then
  kill "$pid_to_kill" 2>/dev/null
  if [ $? -eq 0 ]; then
    exit 0
  else
    whiptail --msgbox "Не удалось завершить процесс $pid_to_kill!" 8 50
  fi
else
  exit 0
fi
