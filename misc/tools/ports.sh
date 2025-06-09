#!/bin/bash

function get_process_list() {
  ss -tulnp | awk '
    NR>1 {
      match($0, /pid=([0-9]+)/, pidm);
      pid=pidm[1];
      if (pid != "") {
        match($0, /([0-9]+):([0-9]+)/, addr);
        port=addr[2];
        user=system("ps -o user= -p " pid);
        print user, port;
      }
    }
  ' | sort -u
}

mapfile -t entries < <(get_process_list)

if [ ${#entries[@]} -eq 0 ]; then
  whiptail --msgbox "Слушающих процессов на портах не найдено." 8 50
  exit 0
fi

declare -A user_process_count
declare -A user_ports

for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  port=$(echo "$line" | awk '{print $2}')
  user_process_count["$user"]=$((user_process_count["$user"] + 1))
  user_ports["$user"]+="$port "
done

sorted_users=($(for u in "${!user_process_count[@]}"; do echo "$u ${user_process_count[$u]}"; done | sort -k2,2n | awk '{print $1}'))

whiptail_list=()
for user in "${sorted_users[@]}"; do
  ports="${user_ports[$user]}"
  whiptail_list+=("$user" "$ports")
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "Пользователь (порты):" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus -ne 0 ]; then
  echo "Отмена пользователем."
  exit 0
fi

chosen_user=$CHOICE
chosen_entry=""
for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
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
