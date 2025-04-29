#!/bin/bash

check_module_and_access() {
    local name="$1"
    local path="$2"
    local module_dir="/lib/modules/$(uname -r)/kernel/$name"

    if [ -e "$path" ]; then
        echo -e "\e[32m\e[1m$path ✓\e[0m"
        
        if [[ "$name" == "overlay" || "$name" == "br_netfilter" || "$name" == "ip_tables" || "$name" == "ip6_tables" || "$name" == "nf_nat" || "$name" == "cgroup" ]]; then
            if lsmod | grep "$name" &> /dev/null; then
                echo -e "\e[32m\e[1m$name модуль загружен ✓\e[0m"
                
                if [ -d "$module_dir" ]; then
                    if [ -r "$module_dir" ] && [ -x "$module_dir" ]; then
                        echo -e "\e[32m\e[1mДоступ к $module_dir ✓\e[0m"
                    else
                        echo -e "\e[31m\e[1mДоступ к $module_dir ✗\e[0m"
                    fi
                else
                    echo -e "\e[31m\e[1mКаталог $module_dir не существует ✗\e[0m"
                fi
            else
                echo -e "\e[31m\e[1m$name модуль не загружен ✗\e[0m"
            fi
        fi
    else
        echo -e "\e[31m\e[1m$path ✗\e[0m"
    fi
}

echo "Проверка модулей ядра:"
check_module_and_access "overlay" "/sys/module/overlay"
check_module_and_access "br_netfilter" "/sys/module/br_netfilter"
check_module_and_access "ip_tables" "/sys/module/ip_tables"
check_module_and_access "ip6_tables" "/sys/module/ip6_tables"
check_module_and_access "nf_nat" "/sys/module/nf_nat"
check_module_and_access "cgroup" "/sys/module/cgroup"

echo -e "\nПроверка параметров ядра:"
check_module_and_access "" "/proc/cgroups"
check_module_and_access "" "/proc/self/mountinfo"
check_module_and_access "" "/proc/sys/kernel/cap_last"
check_module_and_access "" "/proc/sys/kernel/hostname"
check_module_and_access "" "/proc/sys/net/ipv4/ip_forward"
check_module_and_access "" "/proc/sys/kernel/keys"
check_module_and_access "" "/proc/sys/kernel/shmmax"
check_module_and_access "" "/proc/sys/kernel/msgmax"
check_module_and_access "" "/proc/sys/kernel/sem"

echo -e "\nПроверка файловых систем:"
check_module_and_access "" "/sys/fs/cgroup"
check_module_and_access "" "/sys/fs/overlayfs"
check_module_and_access "" "/sys/fs/fuse"

echo -e "\nПроверка настроек безопасности:"
check_module_and_access "" "/proc/sys/kernel/audit"
check_module_and_access "" "/proc/sys/kernel/lockdown"

echo -e "\nПроверка завершена."
