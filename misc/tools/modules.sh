#!/usr/bin/env bash

# Determine user directory based on write access to /tmp
USER_DIR=$( [ -w /tmp ] && echo "" || echo "$HOME" )

# Source external script
source "$USER_DIR/etc/tech-scripts/source.sh"

# Function to check if a module is loaded or accessible
check_module() {
    local name="$1"
    local display_name="$2"
    local path="$3"
    local module_dir="/lib/modules/$(uname -r)/kernel/$name"
    local access_status="✗"

    # Check if the module is loaded or accessible
    if lsmod | grep -q "$name" || [ -d "$module_dir" ] && [ -r "$module_dir" ] && [ -w "$module_dir" ] && [ -x "$module_dir" ] || modprobe "$name" &> /dev/null; then
        access_status="✓"
    fi

    # Check if the path exists
    [ -e "$path" ] && access_status="✓"

    results+=("$display_name: $access_status")
}

# Display menu and get user choice
choice=$(whiptail --title "$NEED_TITLE" --menu "$NEED_MENU_TITLE" 12 40 4 \
"1" "Docker" \
"2" "Podman" \
"3" "LXC" \
"4" "$NEED_ALL" 3>&1 1>&2 2>&3)

# Define mandatory and optional modules based on user choice
case $choice in
    1) mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat"); optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown"); echo -e "\n$NEED_CHECKING_MODULES Docker:" ;;
    2) mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat" "cgroup" "namespace"); optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown"); echo -e "\n$NEED_CHECKING_MODULES Podman:" ;;
    3) mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat" "cgroup" "namespace"); optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown"); echo -e "\n$NEED_CHECKING_MODULES LXC:" ;;
    4) echo -e "\n$NEED_CHECKING_MODULES Все:" ;;
    *) exit 1 ;;
esac

results=()

# Display results
echo -e "\n$NEED_SYSTEM_MODULES"
for module in "${mandatory_modules[@]}"; do
    case $module in
        "overlay") check_module "overlay" "OverlayFS" "/sys/module/overlay" ;;
        "br_netfilter") check_module "br_netfilter" "br_netfilter" "/sys/module/br_netfilter" ;;
        "ip_tables") check_module "ip_tables" "ip_tables" "/sys/module/ip_tables" ;;
        "ip6_tables") check_module "ip6_tables" "ip6_tables" "/sys/module/ip6_tables" ;;
        "nf_nat") check_module "nf_nat" "nf_nat" "/sys/module/nf_nat" ;;
        "cgroup") check_module "cgroup" "cgroups" "/proc/cgroups" ;;
        "namespace") check_module "namespace" "Namespaces" "/proc/self/ns" ;;
    esac
done

echo -e "\n$NEED_FILESYSTEMS"
for module in "${optional_modules[@]}"; do
    case $module in
        "fuse") check_module "fuse" "FUSE" "/sys/fs/fuse" ;;
        "nfs") check_module "nfs" "NFS" "/proc/fs/nfsd" ;;
        "cifs") check_module "cifs" "SMB/KIFC" "/proc/fs/cifs" ;;
    esac
done

echo -e "\n$NEED_NETWORK_MODULES"
check_module "ip_forward" "Network namespaces" "/proc/sys/net/ipv4/ip_forward"
check_module "capabilities" "Capabilities" "/proc/sys/kernel/cap_last_cap"

echo -e "\n$NEED_IPC"
check_module "shmmax" "Shared Memory" "/proc/sys/kernel/shmmax"
check_module "msgmax" "Message Queues" "/proc/sys/kernel/msgmax"
check_module "sem" "Semaphores" "/proc/sys/kernel/sem"

echo -e "\n$NEED_SECURITY"
check_module "audit" "Kernel Auditing" "/proc/sys/kernel/audit"
check_module "lockdown" "Kernel Lockdown" "/proc/sys/kernel/lockdown"
check_module "cgroups" "cgroups" "/proc/cgroups"

echo -e "\n$NEED_UNIQUE_IDS"
check_module "hostname" "UTS namespace" "/proc/sys/kernel/hostname"
check_module "keys" "Keyrings" "/proc/sys/kernel/keys"

# Display results without double checkmarks or crosses
echo -e "\nРезультаты проверки модулей:"
for result in "${results[@]}"; do
    if [[ "$result" == *"✓"* ]]; then
        echo -e "\e[37m$result \e[32m✓\e[0m"  # Green checkmark for success
    else
        echo -e "\e[37m$result \e[31m✗\e[0m"  # Red cross for failure
    fi
done
