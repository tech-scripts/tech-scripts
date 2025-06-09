#!/bin/bash

get_process_list() {
  ss -tulnp | awk '
    NR>1 && /users:/ {
      split($5, addr, ":")
      port=addr[length(addr)]
      userfield=""
      for(i=6;i<=NF;i++) userfield=userfield $i " "
      if (match(userfield, /users:\$\$\"([^"]+)\",pid=([0-9]+)/, m)) {
        procname = m[1]
        pid=m[2]
      } else {
        procname = "unknown"
        pid = ""
      }
      command = "ps -o user= -p " pid
      command | getline username
      close(command)
      if (username != "" && pid != "") {
        print username, procname, port, pid
      }
    }
  ' | sort -u
}

mapfile -t entries < <(get_process_list)

if [ ${#entries[@]} -eq 0 ]; then
  whiptail --msgbox "Слушающих процессов на портах не найдено." 8 50
  exit 0
fi

whiptail_list=()
for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  proc=$(echo "$line" | awk '{print $2}')
  port=$(echo "$line" | awk '{print $3}')
  whiptail_list+=("$user ($proc)" "$port")
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "Пользователь (процесс): Порт" 20 70 15 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  echo "Отмена пользователем."
  exit 0
fi

chosen_user=$(echo "$CHOICE" | awk -F' \\$' '{print $1}')
chosen_proc=$(echo "$CHOICE" | awk -F'[()]' '{print $2}')

chosen_entry=""
for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  proc=$(echo "$line" | awk '{print $2}')
  if [[ "$user" == "$chosen_user" && "$proc" == "$chosen_proc" ]]; then
    chosen_entry="$line"
    break
  fi
done

pid_to_kill=$(echo "$chosen_entry" | awk '{print $4}')

if [ -z "$pid_to_kill" ]; then
  whiptail --msgbox "Ошибка: Не удалось определить PID выбранного процесса." 8 50
  exit 1
fi

if (whiptail --title "Подтверждение" --yesno "Завершить процесс PID $pid_to_kill, принадлежащий пользователю $chosen_user ($chosen_proc)?" 8 60); then
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
