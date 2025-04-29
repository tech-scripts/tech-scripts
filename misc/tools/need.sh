#!/bin/bash

check_module() {
    local name="$1"
    local display_name="$2"
    local path="$3"
    local module_dir="/lib/modules/$(uname -r)/kernel/$name"
    local access_status="✓"

    if [ ! -e "$path" ]; then
        access_status="✗"
    fi

    if [[ "$name" != "" ]]; then
        if ! modprobe "$name" &> /dev/null; then
            access_status="✗"
        fi
    fi

    if [[ "$name" == "cgroup" ]]; then
        if [ ! -d "/sys/fs/cgroup" ]; then
            access_status="✗"
        fi
    fi

    if [[ "$name" == "fuse" ]]; then
        if [ ! -d "/sys/fs/fuse" ]; then
            access_status="✗"
        fi
    fi

    if [[ "$name" == "keyring" ]]; then
        if [ ! -e "/proc/keys" ]; then
            access_status="✗"
        fi
    fi

    if [[ "$name" == "nfs" ]]; then
        if [ ! -d "/proc/fs/nfs" ]; then
            access_status="✗"
        fi
    fi

    if [[ "$name" == "cifs" ]]; then
        if [ ! -d "/proc/fs/smb" ]; then
            access_status="✗"
        fi
    fi

    if [ -d "$module_dir" ]; then
        if [ ! -r "$module_dir" ] || [ ! -w "$module_dir" ] || [ ! -x "$module_dir" ]; then
            access_status="✗"
        fi
    fi

    if [[ "$access_status" == "✓" ]]; then
        echo -e "\e[32m\e[1m$display_name ✓\e[0m"
    else
        echo -e "\e[31m\e[1m$display_name ✗\e[0m"
    fi
}

echo "Проверка модулей ядра:"
check_module "overlay" "overlay" "/sys/module/overlay"
check_module "br_netfilter" "br_netfilter" "/sys/module/br_netfilter"
check_module "ip_tables" "ip_tables" "/sys/module/ip_tables"
check_module "ip6_tables" "ip6_tables" "/sys/module/ip6_tables"
check_module "nf_nat" "nf_nat" "/sys/module/nf_nat"
check_module "cgroup" "cgroup" "/sys/module/cgroup"
check_module "fuse" "FUSE" "/sys/fs/fuse"
check_module "keyring" "Keyctl" "/proc/keys"
check_module "nfs" "NFS" "/proc/fs/nfs"
check_module "cifs" "SMB/KIFC" "/proc/fs/smb"

echo -e "\nПроверка параметров ядра:"
check_module "cgroups" "cgroups" "/proc/cgroups"
check_module "mount" "mount namespaces" "/proc/self/mountinfo"
check_module "capabilities" "capabilities" "/proc/sys/kernel/cap_last"
check_module "hostname" "UTS namespace" "/proc/sys/kernel/hostname"
check_module "ip_forward" "Network namespaces" "/proc/sys/net/ipv4/ip_forward"
check_module "keys" "Keyrings" "/proc/sys/kernel/keys"
check_module "shmmax" "Shared Memory" "/proc/sys/kernel/shmmax"
check_module "msgmax" "Message Queues" "/proc/sys/kernel/msgmax"
check_module "sem" "Semaphores" "/proc/sys/kernel/sem"

echo -e "\nПроверка файловых систем:"
check_module "cgroup" "cgroups v2" "/sys/fs/cgroup"
check_module "overlayfs" "OverlayFS" "/sys/fs/overlayfs"

echo -e "\nПроверка настроек безопасности:"
check_module "audit" "Kernel Auditing" "/proc/sys/kernel/audit"
check_module "lockdown" "Kernel Lockdown" "/proc/sys/kernel/lockdown"

echo -e "\nПроверка завершена."
