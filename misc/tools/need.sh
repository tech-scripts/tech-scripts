#!/bin/bash

check_module_and_access() {
    local name="$1"
    local display_name="$2"
    local path="$3"
    local module_dir="/lib/modules/$(uname -r)/kernel/$name"
    local access_status="✓"

    if [ ! -e "$path" ]; then
        access_status="✗"
    fi

    if [[ "$name" != "" && ! $(lsmod | grep "$name") ]]; then
        access_status="✗"
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
check_module_and_access "overlay" "overlay" "/sys/module/overlay"
check_module_and_access "br_netfilter" "br_netfilter" "/sys/module/br_netfilter"
check_module_and_access "ip_tables" "ip_tables" "/sys/module/ip_tables"
check_module_and_access "ip6_tables" "ip6_tables" "/sys/module/ip6_tables"
check_module_and_access "nf_nat" "nf_nat" "/sys/module/nf_nat"
check_module_and_access "cgroup" "cgroup" "/sys/module/cgroup"
check_module_and_access "fuse" "FUSE" "/sys/fs/fuse"
check_module_and_access "keyctl" "Keyctl" "/proc/keys"
check_module_and_access "nfs" "NFS" "/proc/fs/nfs"
check_module_and_access "smb" "SMB/KIFC" "/proc/fs/smb"

echo -e "\nПроверка параметров ядра:"
check_module_and_access "cgroups" "cgroups" "/proc/cgroups"
check_module_and_access "mount" "mount namespaces" "/proc/self/mountinfo"
check_module_and_access "capabilities" "capabilities" "/proc/sys/kernel/cap_last"
check_module_and_access "hostname" "UTS namespace" "/proc/sys/kernel/hostname"
check_module_and_access "ip_forward" "Network namespaces" "/proc/sys/net/ipv4/ip_forward"
check_module_and_access "keys" "Keyrings" "/proc/sys/kernel/keys"
check_module_and_access "shmmax" "Shared Memory" "/proc/sys/kernel/shmmax"
check_module_and_access "msgmax" "Message Queues" "/proc/sys/kernel/msgmax"
check_module_and_access "sem" "Semaphores" "/proc/sys/kernel/sem"

echo -e "\nПроверка файловых систем:"
check_module_and_access "cgroup" "cgroups v2" "/sys/fs/cgroup"
check_module_and_access "overlayfs" "OverlayFS" "/sys/fs/overlayfs"

echo -e "\nПроверка настроек безопасности:"
check_module_and_access "audit" "Kernel Auditing" "/proc/sys/kernel/audit"
check_module_and_access "lockdown" "Kernel Lockdown" "/proc/sys/kernel/lockdown"

echo -e "\nПроверка завершена."
