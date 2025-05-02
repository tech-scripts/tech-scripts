#!/usr/bin/env bash

USER_DIR=$( [ -w /tmp ] && echo "" || echo "$HOME" )
source "$USER_DIR/etc/tech-scripts/source.sh"

check_module() {
    local name="$1"
    local display_name="$2"
    local path="$3"
    local module_dir="/lib/modules/$(uname -r)/kernel/$name"
    local access_status="✗"

    if lsmod | grep -q "$name" || [ -d "$module_dir" ] && [ -r "$module_dir" ] && [ -w "$module_dir" ] && [ -x "$module_dir" ] || modprobe "$name" &> /dev/null; then
        access_status="✓"
    fi

    [ -e "$path" ] && access_status="✓"
    results+=("$display_name: ")
}

choice=$(whiptail --title "$NEED_TITLE" --menu "$NEED_MENU_TITLE" 12 40 4 \
"1" "Docker" \
"2" "Podman" \
"3" "LXC" \
"4" "$NEED_ALL" 3>&1 1>&2 2>&3)

case $choice in
    1) mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat"); optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown"); echo -e "\n$NEED_CHECKING_MODULES Docker:" ;;
    2) mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat" "cgroup" "namespace"); optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown"); echo -e "\n$NEED_CHECKING_MODULES Podman:" ;;
    3) mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat" "cgroup" "namespace"); optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown"); echo -e "\n$NEED_CHECKING_MODULES LXC:" ;;
    4) echo -e "\n$NEED_CHECKING_MODULES Все:" ;;
    *) exit 1 ;;
esac

results=()

echo -e "\nСистемные модули"
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

echo -e "\nФайловые системы"
for module in "${optional_modules[@]}"; do
    case $module in
        "fuse") check_module "fuse" "FUSE" "/sys/fs/fuse" ;;
        "nfs") check_module "nfs" "NFS" "/proc/fs/nfsd" ;;
        "cifs") check_module "cifs" "SMB/KIFC" "/proc/fs/cifs" ;;
    esac
done

if [[ "$choice" == "4" ]]; then
    echo -e "\nСетевые модули"
    check_module "ip_forward" "Network namespaces" "/proc/sys/net/ipv4/ip_forward"
    check_module "capabilities" "Capabilities" "/proc/sys/kernel/cap_last_cap"

    echo -e "\nIPC (Межпроцессное взаимодействие)"
    check_module "shmmax" "Shared Memory" "/proc/sys/kernel/shmmax"
    check_module "msgmax" "Message Queues" "/proc/sys/kernel/msgmax"
    check_module "sem" "Semaphores" "/proc/sys/kernel/sem"

    echo -e "\nБезопасность"
    check_module "audit" "Kernel Auditing" "/proc/sys/kernel/audit"
    check_module "lockdown" "Kernel Lockdown" "/proc/sys/kernel/lockdown"
    check_module "cgroups" "cgroups" "/proc/cgroups"

    echo -e "\nУникальные идентификаторы"
    check_module "hostname" "UTS namespace" "/proc/sys/kernel/hostname"
    check_module "keys" "Keyrings" "/proc/sys/kernel/keys"
fi

echo -e "\nРезультаты проверки модулей:"
for result in "${results[@]}"; do
    if [[ "$result" == *"✓"* ]]; then
        echo -e "\e[37m$result \e[32m✓\e[0m"
    else
        echo -e "\e[37m$result \e[31m✗\e[0m"
    fi
done
