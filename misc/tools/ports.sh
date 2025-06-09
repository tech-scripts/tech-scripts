#!/bin/bash

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
  whiptail --msgbox "Слушающих процессов на портах не найдено." 8 50
  exit 0
fi

declare -A pid_info  # Store info for each pid

whiptail_list=()
for line in "${entries[@]}"; do
  read user process_name port pid <<< "$line"
  pid_info["$pid"]="$user $process_name $port"
  # PID as the tag, display user (process) : port
  whiptail_list+=("$pid" "$user ($process_name) : порт $port")
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "PID - Пользователь (процесс) : порт" 20 70 15 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  echo "Отмена пользователем."
  exit 0
fi

pid_to_kill="$CHOICE"
info="${pid_info[$pid_to_kill]}"

if [ -z "$info" ]; then
  whiptail --msgbox "Ошибка: Не удалось определить информацию для выбранного процесса." 8 60
  exit 1
fi

user=$(echo "$info" | awk '{print $1}')
process_name=$(echo "$info" | awk '{print $2}')
port=$(echo "$info" | awk '{print $3}')

if (whiptail --title "Подтверждение" --yesno "Завершить процесс PID $pid_to_kill, принадлежащий пользователю $user ($process_name), слушающий порт $port?" 8 70); then
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
