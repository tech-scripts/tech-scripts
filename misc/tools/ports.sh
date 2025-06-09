#!/bin/bash

function get_process_list() {

  ss -tulnp | awk '
    NR>1 {
      # example line formats:
      # tcp   LISTEN 0      128    127.0.0.1:8000       0.0.0.0:*    users:(("php",pid=1234,fd=4))
      proto=$1;
      state=$2;
      local_addr=$5;
      match(local_addr, /.*:([0-9]+)/, portm);
      port=portm[1];
      # extract pid and command from "users:(("cmd",pid=1234,fd=3))"
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
      echo "$port \"$user\" $pid"
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
  port=$(echo "$line" | awk '{print $1}')
  user=$(echo "$line" | awk '{print $2}')
  user_display=$user
  whiptail_list+=("$port" "$user_display")
done

CHOICE=$(whiptail --title "Select process to kill by port" --menu "Choose port (User shown):" 20 60 10 "${whiptail_list[@]}" 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus -ne 0 ]; then
  echo "User cancelled."
  exit 0
fi

chosen_port=$CHOICE
chosen_entry=""
for line in "${entries[@]}"; do
  port=$(echo "$line" | awk '{print $1}')
  if [ "$port" == "$chosen_port" ]; then
    chosen_entry="$line"
    break
  fi
done

pid_to_kill=$(echo "$chosen_entry" | awk '{print $3}')

if [ -z "$pid_to_kill" ]; then
  whiptail --msgbox "Error: Could not find PID for selected port." 8 50
  exit 1
fi

if (whiptail --title "Confirm kill" --yesno "Kill process PID $pid_to_kill listening on port $chosen_port?" 8 60) then
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
