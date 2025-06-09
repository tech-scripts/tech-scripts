#!/bin/bash

# Function to get list of listening processes with user, process name, port, and pid
get_process_list() {
  ss -tulnp | awk '
    NR>1 && /users:/ {
      # Extract port from Local Address:Port field (5th column)
      split($5, addr, ":")
      port=addr[length(addr)]

      # Extract user, process name, and pid from the users:(("proc",pid=xxx,...)) field (7th column or after - so join fields from 6th to NF)
      # Rebuild the users string (usually field 7 but spaces may cause shifting)
      userfield=""
      for(i=6;i<=NF;i++) userfield=userfield $i " "
      
      # Extract process name inside quotes after users:((
      if (match(userfield, /users:\$\$\"([^"]+)\",pid=([0-9]+)/, m)) {
        procname = m[1]
        pid=m[2]
      } else {
        procname = "unknown"
        pid = ""
      }

      # Get user name from /proc/[pid] if exists, else empty
      command = "ps -o user= -p " pid
      command | getline username
      close(command)
      
      if (username != "" && pid != "") {
        print username, procname, port, pid
      }
    }
  ' | sort -u
}

# Get process list into array
mapfile -t entries < <(get_process_list)

if [ ${#entries[@]} -eq 0 ]; then
  whiptail --msgbox "Слушающих процессов на портах не найдено." 8 50
  exit 0
fi

# Prepare whiptail menu options
whiptail_list=()
for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  proc=$(echo "$line" | awk '{print $2}')
  port=$(echo "$line" | awk '{print $3}')
  # Display as "user (proc)" port: to disambiguate
  whiptail_list+=("$user ($proc)" "$port")
done

# Show menu
CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "Пользователь (процесс): Порт" 20 70 15 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

# Check if user canceled
if [ $? -ne 0 ]; then
  echo "Отмена пользователем."
  exit 0
fi

# Extract selected user and process from choice (CHOICE format: user (proc))
chosen_user=$(echo "$CHOICE" | awk -F' \\$' '{print $1}')
chosen_proc=$(echo "$CHOICE" | awk -F'[()]' '{print $2}')

# Find the matching entry line
chosen_entry=""
for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  proc=$(echo "$line" | awk '{print $2}')
  if [[ "$user" == "$chosen_user" && "$proc" == "$chosen_proc" ]]; then
    chosen_entry="$line"
    break
  fi
done

# Extract PID for the chosen entry
pid_to_kill=$(echo "$chosen_entry" | awk '{print $4}')

if [ -z "$pid_to_kill" ]; then
  whiptail --msgbox "Ошибка: Не удалось определить PID выбранного процесса." 8 50
  exit 1
fi

# Confirm kill action
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
