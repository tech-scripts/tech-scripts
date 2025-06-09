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
      echo "$user $port $pid"
    fi
  done
}

process_list=()
mapfile -t entries < <(get_process_list)

if [ ${#entries[@]} -eq 0 ]; then
  whiptail --msgbox "Слушающих процессов на портах не найдено." 8 50
  exit 0
fi

declare -A port_users
declare -A port_user_pids

for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  port=$(echo "$line" | awk '{print $2}')
  pid=$(echo "$line" | awk '{print $3}')
  port_users["$port"]+="$user "
  port_user_pids["$port|$user"]=$pid
done

# Уникальные пользователи для каждого порта
for port in "${!port_users[@]}"; do
  users="${port_users[$port]}"
  unique_users=$(echo $users | tr ' ' '\n' | sort -u | tr '\n' ' ')
  port_users[$port]=$unique_users
done

declare -A port_usercount
for port in "${!port_users[@]}"; do
  usercount=$(echo "${port_users[$port]}" | wc -w)
  port_usercount[$port]=$usercount
done

# Сортируем порты по возрастанию количества уникальных пользователей
sorted_ports=($(for p in "${!port_usercount[@]}"; do echo "$p ${port_usercount[$p]}"; done | sort -k2,2n | awk '{print $1}'))

whiptail_list=()
for port in "${sorted_ports[@]}"; do
  users=(${port_users[$port]})
  for user in "${users[@]}"; do
    whiptail_list+=("$user" "$port")
  done
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "Пользователь (порт):" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus -ne 0 ]; then
  echo "Отмена пользователем."
  exit 0
fi

chosen_user=$CHOICE
chosen_entry=""
for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  port=$(echo "$line" | awk '{print $2}')
  if [ "$user" == "$chosen_user" ]; then
    chosen_entry="$line"
    break
  fi
done

pid_to_kill=$(echo "$chosen_entry" | awk '{print $3}')

if [ -z "$pid_to_kill" ]; then
  whiptail --msgbox "Ошибка: Не удалось определить PID выбранного процесса." 8 50
  exit 1
fi

if (whiptail --title "Подтверждение" --yesno "Завершить процесс PID $pid_to_kill, принадлежащий пользователю $chosen_user?" 8 60) then
  kill "$pid_to_kill" 2>/dev/null
  if [ $? -eq 0 ]; then
    whiptail --msgbox "Процесс $pid_to_kill успешно завершён." 8 50
  else
    whiptail --msgbox "Не удалось завершить процесс $pid_to_kill." 8 50
  fi
else
  whiptail --msgbox "Завершение процесса отменено." 8 50
fi

exit 0
