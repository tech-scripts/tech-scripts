#!/bin/bash

function get_process_list() {
  ss -tulnp | awk '
    NR>1 {
      proto=$1;
      state=$2;
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
  whiptail --msgbox "No listening processes found on ports." 8 50
  exit 0
fi

whiptail_list=()
for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  port=$(echo "$line" | awk '{print $2}')
  whiptail_list+=("$user" "$port")
done

CHOICE=$(whiptail --title "Select process to kill by port" --menu "Choose user (port shown):" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus -ne 0 ]; then
  echo "User cancelled."
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
  whiptail --msgbox "Error: Could not find PID for selected user." 8 50
  exit 1
fi

if (whiptail --title "Confirm kill" --yesno "Kill process PID $pid_to_kill owned by $chosen_user?" 8 60) then
  kill "$pid_to_kill" 2>/dev/null
  if [ $? -eq 0 ]; then
    whiptail --msgbox "Process $pid_to_kill killed successfully." 8 50
  else
    whiptail --msgbox "Failed to kill process $pid_to_kill." 8 50
  fi
else
  whiptail --msgbox "Kill cancelled." 8 50
fi

exit 0
