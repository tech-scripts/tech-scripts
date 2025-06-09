#!/bin/bash

function get_process_list() {
  ss -tulnp | awk '
    NR>1 {
      local_addr=$5;
      match(local_addr, /.*:([0-9]+)/, portm);
      port=portm[1];
      match($0, /pid=([0-9]+)/, pidm);
      pid=pidm[1];
      if (pid != "") {
        print port, pid;
      }
    }
  ' | sort -u | while read port pid; do
    if [ -d "/proc/$pid" ]; then
      user=$(ps -o user= -p $pid)
      user=$(echo $user)
      echo "$port $user $pid"
    fi
  done
}

mapfile -t entries < <(get_process_list)

if [ ${#entries[@]} -eq 0 ]; then
  whiptail --msgbox "Слушающих процессов на портах не найдено." 8 50
  exit 0
fi

declare -A port_users
declare -A user_port_pid

for line in "${entries[@]}"; do
  port=$(echo "$line" | awk '{print $1}')
  user=$(echo "$line" | awk '{print $2}')
  pid=$(echo "$line" | awk '{print $3}')
  port_users["$port"]+="$user "
  user_port_pid["$user|$port"]=$pid
done

# Уникальные пользователи на порты
for port in "${!port_users[@]}"; do
  users="${port_users[$port]}"
  unique_users=$(echo $users | tr ' ' '\n' | sort -u | tr '\n' ' ')
  port_users[$port]=$unique_users
done

declare -A port_usercount
for port in "${!port_users[@]}"; do
  count=$(echo "${port_users[$port]}" | wc -w)
  port_usercount[$port]=$count
done

sorted_ports=($(for p in "${!port_usercount[@]}"; do echo "$p ${port_usercount[$p]}"; done | sort -k2,2n | awk '{print $1}'))

whiptail_list=()
for port in "${sorted_ports[@]}"; do
  users=(${port_users[$port]})
  for user in "${users[@]}"; do
    whiptail_list+=("$user" "$port")
  done
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "Пользователь (порт):" 20 60 15 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  echo "Отмена пользователем."
  exit 0
fi

chosen_user=$CHOICE
chosen_port=""
for key in "${!user_port_pid[@]}"; do
  IFS='|' read -r u p <<< "$key"
  if [ "$u" == "$chosen_user" ]; then
    chosen_port=$p
    break
  fi
done

pid_to_kill=${user_port_pid["$chosen_user|$chosen_port"]}

if [ -z "$pid_to_kill" ]; then
  whiptail --msgbox "Ошибка: не удалось определить PID выбранного процесса." 8 50
  exit 1
fi

whiptail --yesno "Завершить процесс PID $pid_to_kill, принадлежащий пользователю $chosen_user, порт $chosen_port?" 8 60
if [ $? -eq 0 ]; then
  kill "$pid_to_kill" 2>/dev/null && \
  whiptail --msgbox "Процесс $pid_to_kill успешно завершён." 8 50 || \
  whiptail --msgbox "Не удалось завершить процесс $pid_to_kill." 8 50
else
  whiptail --msgbox "Завершение процесса отменено." 8 50
fi

exit 0
