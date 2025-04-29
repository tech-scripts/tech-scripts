#!/bin/bash

check_module() {
    if lsmod | grep "$1" &> /dev/null; then
        echo -e "\e[32m$1 ✓\e[0m"
    else
        echo -e "\e[31m$1 ✗\e[0m"
    fi
}

check_proc() {
    if [ -e "$1" ]; then
        echo -e "\e[32m$2 ✓\e[0m"
    else
        echo -e "\e[31m$2 ✗\e[0m"
    fi
}

echo "Проверка модулей ядра:"
check_module "overlay"
check_module "br_netfilter"
check_module "ip_tables"
check_module "ip6_tables"
check_module "nf_nat"
check_module "cgroup"

echo -e "\nПроверка параметров ядра:"
check_proc "/proc/cgroups" "cgroups"
check_proc "/proc/self/mountinfo" "mount namespaces"
check_proc "/proc/sys/kernel/cap_last" "capabilities"
check_proc "/proc/sys/kernel/hostname" "UTS namespace"
check_proc "/proc/sys/net/ipv4/ip_forward" "Network namespaces"
check_proc "/proc/sys/kernel/keys" "Keyrings"
check_proc "/proc/sys/kernel/shmmax" "Shared Memory"
check_proc "/proc/sys/kernel/msgmax" "Message Queues"
check_proc "/proc/sys/kernel/sem" "Semaphores"

echo -e "\nПроверка файловых систем:"
check_proc "/sys/fs/cgroup" "cgroups v2"
check_proc "/sys/fs/overlayfs" "OverlayFS"
check_proc "/sys/fs/fuse" "FUSE"

echo -e "\nПроверка настроек безопасности:"
check_proc "/proc/sys/kernel/audit" "Kernel Auditing"
check_proc "/proc/sys/kernel/lockdown" "Kernel Lockdown"

echo -e "\nПроверка завершена."
