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
for user in "${sorted_users[@]}"; do
  ports="${user_ports[$user]}"
  for entry in $ports; do
    process_name=$(echo "$entry" | cut -d':' -f1)
    port=$(echo "$entry" | cut -d':' -f2)
    pid=$(echo "${entries[@]}" | grep "$user $process_name $port" | awk '{print $4}')
    whiptail_list+=("$user ($process_name)" "$port")
  done
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "             Пользователь (процесс) порт:" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  exit 0
fi

chosen_user=$(echo "$CHOICE" | awk -F ' ' '{print $1}' | sed 's/ (.*)//')
chosen_process=$(echo "$CHOICE" | awk -F ' ' '{print $2}' | sed 's/.*(//;s/)//')
chosen_port=$(echo "$CHOICE" | awk '{print $3}' | grep -o '[0-9]*')
chosen_entry=""

for line in "${entries[@]}"; do
  read user process_name port pid <<< "$line"
  if [[ "$pid" == "$pid_to_kill" ]]; then
    chosen_entry="$line"
    break
  fi
done

pid_to_kill=$(echo "$chosen_entry" | awk '{print $4}')

if [ -z "$pid_to_kill" ]; then
  echo "Ошибка: Не удалось определить PID выбранного процесса!"
  exit 1
fi

if (whiptail --title "Подтверждение" --yesno "Завершить процесс PID $pid_to_kill, принадлежащий пользователю $chosen_user ($chosen_process)?" 8 60); then
  kill "$pid_to_kill" 2>/dev/null
  if [ $? -eq 0 ]; then
    exit 0
  else
    whiptail --msgbox "Не удалось завершить процесс $pid_to_kill!" 8 50
  fi
else
  exit 0
fi
