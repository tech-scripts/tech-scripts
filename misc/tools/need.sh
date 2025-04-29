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

choice=$(whiptail --title "Выбор проверки модулей" --menu "Выберите, какие модули проверить:" 15 60 4 \
"1" "Docker" \
"2" "Podman" \
"3" "LXC" \
"4" "Все" 3>&1 1>&2 2>&3)

case $choice in
    1)
        mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat")
        optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown")
        echo -e "\nПроверка модулей для Docker:"
        ;;
    2)
        mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat" "cgroup" "namespace")
        optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown")
        echo -e "\nПроверка модулей для Podman:"
        ;;
    3)
        mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat" "cgroup" "namespace")
        optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown")
        echo -e "\nПроверка модулей для LXC:"
        ;;
    4)
        echo -e "\nПроверка всех модулей:"
        mandatory_modules=("overlay" "br_netfilter" "ip_tables" "ip6_tables" "nf_nat" "cgroup" "namespace")
        optional_modules=("fuse" "nfs" "cifs" "seccomp" "audit" "lockdown")
        ;;
    *)
        echo "Неверный выбор."
        exit 1
        ;;
esac

echo -e "\nОбязательные модули:"
for module in "${mandatory_modules[@]}"; do
    case $module in
        "overlay")
            check_module "overlay" "OverlayFS" "/sys/module/overlay"
            ;;
        "br_netfilter")
            check_module "br_netfilter" "br_netfilter" "/sys/module/br_netfilter"
            ;;
        "ip_tables")
            check_module "ip_tables" "ip_tables" "/sys/module/ip_tables"
            ;;
        "ip6_tables")
            check_module "ip6_tables" "ip6_tables" "/sys/module/ip6_tables"
            ;;
        "nf_nat")
            check_module "nf_nat" "nf_nat" "/sys/module/nf_nat"
            ;;
        "cgroup")
            check_module "cgroup" "cgroups" "/proc/cgroups"
            ;;
        "namespace")
            check_module "namespace" "Namespaces" "/proc/self/ns"
            ;;
    esac
done

echo -e "\nНеобязательные модули:"
for module in "${optional_modules[@]}"; do
    case $module in
        "fuse")
            check_module "fuse" "FUSE" "/sys/fs/fuse"
            ;;
        "nfs")
            check_module "nfs" "NFS" "/proc/fs/nfsd"
            ;;
        "cifs")
            check_module "cifs" "SMB/KIFC" "/proc/fs/cifs"
            ;;
        "seccomp")
            check_module "seccomp" "Seccomp" "/proc/sys/kernel/seccomp"
            ;;
        "audit")
            check_module "audit" "Kernel Auditing" "/proc/sys/kernel/audit"
            ;;
        "lockdown")
            check_module "lockdown" "Kernel Lockdown" "/proc/sys/kernel/lockdown"
            ;;
    esac
done

if [[ "$choice" == "4" ]]; then
    echo -e "\nСистемные модули"
    check_module "overlay" "OverlayFS" "/sys/module/overlay"
    check_module "br_netfilter" "br_netfilter" "/sys/module/br_netfilter"
    check_module "ip_tables" "ip_tables" "/sys/module/ip_tables"
    check_module "ip6_tables" "ip6_tables" "/sys/module/ip6_tables"
    check_module "nf_nat" "nf_nat" "/sys/module/nf_nat"

    echo -e "\nФайловые системы"
    check_module "fuse" "FUSE" "/sys/fs/fuse"
    check_module "nfs" "NFS" "/proc/fs/nfsd"
    check_module "cifs" "SMB/KIFC" "/proc/fs/cifs"

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
