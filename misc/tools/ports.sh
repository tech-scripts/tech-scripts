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
declare -A pid_map
declare -a extra_info

for line in "${entries[@]}"; do
  read user process_name port pid <<< "$line"
  user_ports["$user"]+="$process_name:$port "
  user_port_count["$user"]=$((user_port_count["$user"] + 1))
  pid_map["$pid"]="$user $process_name $port"
  extra_info+=("$line")
done

sorted_users=($(for u in "${!user_port_count[@]}"; do echo "$u ${user_port_count[$u]}"; done | sort -k2,2n | awk '{print $1}'))

whiptail_list=()
for user in "${sorted_users[@]}"; do
  ports="${user_ports[$user]}"
  for entry in $ports; do
    process_name=$(echo "$entry" | cut -d':' -f1)
    port=$(echo "$entry" | cut -d':' -f2)
    for pid in "${!pid_map[@]}"; do
      info=${pid_map[$pid]}
      if [[ $info == "$user $process_name $port" ]]; then
        whiptail_list+=("$pid ($user $process_name)" "$port")
      fi
    done
  done
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "             PID (пользователь процесс) порт:" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  exit 0
fi

pid_to_kill=$CHOICE
info=${pid_map[$pid_to_kill]}
read chosen_user chosen_process chosen_port <<< "$info"

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
