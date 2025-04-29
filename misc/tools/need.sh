#!/bin/bash

check_module() {
    local name="$1"
    local display_name="$2"
    local path="$3"
    local module_dir="/lib/modules/$(uname -r)/kernel/$name"
    local access_status="✗"

    if lsmod | grep -q "$name"; then
        access_status="✓"
    elif [ -d "$module_dir" ]; then
        if [ -r "$module_dir" ] && [ -w "$module_dir" ] && [ -x "$module_dir" ]; then
            access_status="✓"
        fi
    else
        if modprobe "$name" &> /dev/null; then
            access_status="✓"
        fi
    fi

    if [ -e "$path" ]; then
        access_status="✓"
    fi

    if [[ "$access_status" == "✓" ]]; then
        echo -e "\e[32m\e[1m$display_name ✓\e[0m"
    else
        echo -e "\e[31m\e[1m$display_name ✗\e[0m"
    fi
}

echo -e "\nСистемные модули"
check_module "overlay" "overlay" "/sys/module/overlay"
check_module "br_netfilter" "br_netfilter" "/sys/module/br_netfilter"
check_module "ip_tables" "ip_tables" "/sys/module/ip_tables"
check_module "ip6_tables" "ip6_tables" "/sys/module/ip6_tables"
check_module "nf_nat" "nf_nat" "/sys/module/nf_nat"

echo -e "\nФайловые системы"
check_module "fuse" "FUSE" "/sys/fs/fuse"
check_module "nfs" "NFS" "/proc/fs/nfs"
check_module "cifs" "SMB/KIFC" "/proc/fs/smb"
check_module "overlayfs" "OverlayFS" "/sys/fs/overlayfs"

echo -e "\nСетевые модули"
check_module "ip_forward" "Network namespaces" "/proc/sys/net/ipv4/ip_forward"
check_module "capabilities" "capabilities" "/proc/sys/kernel/cap_last_cap"

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
