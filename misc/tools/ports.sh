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
  whiptail --msgbox "No listening processes found on ports." 8 50
  exit 0
fi

# Group by port with set of unique users per port to count users per port
declare -A port_users
declare -A port_user_pids

for line in "${entries[@]}"; do
  user=$(echo "$line" | awk '{print $1}')
  port=$(echo "$line" | awk '{print $2}')
  pid=$(echo "$line" | awk '{print $3}')
  key="$port|$user|$pid"
  # Accumulate users per port (avoid duplicates)
  # Compose a string of users per port separated by space (use associative array keys as unique set)
  port_users["$port"]+="$user "
  # Store pid per user+port key for lookup later
  port_user_pids["$port|$user"]=$pid
done

# Remove duplicate users in port_users entries
for port in "${!port_users[@]}"; do
  users="${port_users[$port]}"
  # unique users string
  unique_users=$(echo $users | tr ' ' '\n' | sort -u | tr '\n' ' ')
  port_users[$port]=$unique_users
done

# Create array of ports sorted by ascending number of unique users
declare -A port_usercount
for port in "${!port_users[@]}"; do
  usercount=$(echo "${port_users[$port]}" | wc -w)
  port_usercount[$port]=$usercount
done

# Sort ports by user count ascending (bash sort)
sorted_ports=($(for p in "${!port_usercount[@]}"; do echo "$p ${port_usercount[$p]}"; done | sort -k2,2n | awk '{print $1}'))

# Build whiptail menu list in sorted order (user as tag, port as item)
whiptail_list=()
for port in "${sorted_ports[@]}"; do
  users=(${port_users[$port]})
  for user in "${users[@]}"; do
    pid=${port_user_pids["$port|$user"]}
    # To avoid duplicate menu entries if user appears multiple times, we'll just add each user once per port.
    whiptail_list+=("$user" "$port")
  done
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
  port=$(echo "$line" | awk '{print $2}')
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
