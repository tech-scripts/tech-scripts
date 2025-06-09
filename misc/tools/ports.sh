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
pid_array=()  # Separate array for PIDs

for user in "${sorted_users[@]}"; do
  ports="${user_ports[$user]}"
  for entry in $ports; do
    process_name=$(echo "$entry" | cut -d':' -f1)
    port=$(echo "$entry" | cut -d':' -f2)

    # Find the PID from entries matching user, process_name, and port
    for line in "${entries[@]}"; do
      read u p_name p_port p_pid <<< "$line"
      if [[ "$u" == "$user" && "$p_name" == "$process_name" && "$p_port" == "$port" ]]; then
        pid="$p_pid"
        break
      fi
    done

    whiptail_list+=("$user ($process_name)" "$port")
    pid_array+=("$pid")
  done
done

CHOICE=$(whiptail --title "Выберите процесс для завершения" --menu "             Пользователь (процесс) порт:" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  exit 0
fi

# Get the index of the chosen item in the menu
choice_index=-1
for i in "${!whiptail_list[@]}"; do
  if [[ "${whiptail_list[$i]}" == "$CHOICE" ]]; then
    # The labels and items alternate in whiptail_list: even indices are labels,
    # odd indices are ports. The choice value corresponds to the label, so i is the index of label.
    choice_index=$i
    break
  fi
done

if [ $choice_index -eq -1 ]; then
  echo "Ошибка: Выбранный процесс не найден в списке!"
  exit 1
fi

pid_to_kill="${pid_array[$choice_index]}"

# Retrieve user and process_name from chosen entry string (label)
chosen_label="${whiptail_list[$choice_index]}"
# Extract user (before space) and process name between parentheses
chosen_user=$(echo "$chosen_label" | awk '{print $1}')
chosen_process=$(echo "$chosen_label" | sed -E 's/.*\$(.*)\$/\1/')

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
