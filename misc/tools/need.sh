#!/bin/bash

check_module_and_access() {
    local name="$1"
    local display_name="$2"
    local path="$3"
    local module_dir="/lib/modules/$(uname -r)/kernel/$name"
    local access_status="✓"

    if [ ! -e "$path" ]; then
        access_status="✗"
    elif [[ "$name" == "overlay" || "$name" == "br_netfilter" || "$name" == "ip_tables" || "$name" == "ip6_tables" || "$name" == "nf_nat" || "$name" == "cgroup" ]]; then
        if ! lsmod | grep "$name" &> /dev/null; then
            access_status="✗"
        fi
    fi

    if [ -d "$module_dir" ]; then
        if [ ! -r "$module_dir" ] || [ ! -w "$module_dir" ] || [ ! -x "$module_dir" ]; then
            access_status="✗"
        fi
    fi

    local user_group=$(ls -ld "$path" | awk '{print $3":"$4}')
    if [[ "$user_group" != "root:root" ]]; then
        access_status="✗"
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

echo -e "\nПроверка параметров ядра:"
check_module_and_access "" "cgroups" "/proc/cgroups"
check_module_and_access "" "mount namespaces" "/proc/self/mountinfo"
check_module_and_access "" "capabilities" "/proc/sys/kernel/cap_last"
check_module_and_access "" "UTS namespace" "/proc/sys/kernel/hostname"
check_module_and_access "" "Network namespaces" "/proc/sys/net/ipv4/ip_forward"
check_module_and_access "" "Keyrings" "/proc/sys/kernel/keys"
check_module_and_access "" "Shared Memory" "/proc/sys/kernel/shmmax"
check_module_and_access "" "Message Queues" "/proc/sys/kernel/msgmax"
check_module_and_access "" "Semaphores" "/proc/sys/kernel/sem"

echo -e "\nПроверка файловых систем:"
check_module_and_access "" "cgroups v2" "/sys/fs/cgroup"
check_module_and_access "" "OverlayFS" "/sys/fs/overlayfs"
check_module_and_access "" "FUSE" "/sys/fs/fuse"

echo -e "\nПроверка настроек безопасности:"
check_module_and_access "" "Kernel Auditing" "/proc/sys/kernel/audit"
check_module_and_access "" "Kernel Lockdown" "/proc/sys/kernel/lockdown"

echo -e "\nПроверка завершена."
