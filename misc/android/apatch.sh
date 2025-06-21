#!/bin/bash

# Настройки SuperCall
__NR_supercall=223  # Проверьте в /proc/kallsyms
SUPERCALL_HELLO=0
SUPERCALL_HELLO_MAGIC=88158

# Проверка зависимостей
check_deps() {
    if ! command -v whiptail >/dev/null; then
        echo "Установите whiptail: pkg install whiptail"
        exit 1
    fi
}

# Метод 1: Через busybox (надежный)
supercall_busybox() {
    local key="$1"
    local cmd="$2"
    local ver_and_cmd=$(( (0x000a05 << 32) | (0x1158 << 16) | (cmd & 0xFFFF) ))
    
    busybox syscall $__NR_supercall "$key" "$ver_and_cmd" "${3:-0}" "${4:-0}"
}

# Метод 2: Через прямой вызов (для старых ядер)
supercall_direct() {
    local key="$1"
    local cmd="$2"
    local ver_and_cmd=$(( (0x000a05 << 32) | (0x1158 << 16) | (cmd & 0xFFFF) ))
    
    # Используем echo + dd для передачи в /dev/mem
    {
        printf "%s\0" "$key"  # Ключ с нуль-терминатором
        printf "%016x" "$ver_and_cmd" | xxd -r -p
        printf "%016x" "${3:-0}" | xxd -r -p
    } > /proc/self/mem 2>/dev/null
    
    echo $?
}

# Метод 3: Через временный бинарник (самый надежный)
compile_supercall_helper() {
    cat > /tmp/supercall_helper.c <<'EOF'
#include <unistd.h>
#include <sys/syscall.h>
#include <string.h>

long supercall(const char *key, unsigned cmd, unsigned arg1, unsigned arg2) {
    unsigned long ver_and_cmd = (0x000a05ULL << 32) | (0x1158 << 16) | (cmd & 0xFFFF);
    return syscall(223, key, ver_and_cmd, arg1, arg2);
}
EOF

    gcc -O2 -static /tmp/supercall_helper.c -o /tmp/supercall_helper
    chmod +x /tmp/supercall_helper
}

# Автовыбор метода вызова
supercall() {
    local key="$1" cmd="$2"
    
    # 1. Пробуем busybox
    if command -v busybox >/dev/null; then
        result=$(supercall_busybox "$key" "$cmd" "${3:-0}" "${4:-0}")
        [ "$result" -ne -1 ] && echo "$result" && return 0
    fi
    
    # 2. Пробуем временный бинарник
    if [ ! -f /tmp/supercall_helper ]; then
        compile_supercall_helper
    fi
    if [ -f /tmp/supercall_helper ]; then
        result=$(/tmp/supercall_helper "$key" "$cmd" "${3:-0}" "${4:-0}")
        [ "$result" -ne -1 ] && echo "$result" && return 0
    fi
    
    # 3. Пробуем прямой метод
    supercall_direct "$key" "$cmd" "${3:-0}" "${4:-0}"
}

# Проверка ключа (3 попытки)
check_key() {
    local key
    for i in {1..3}; do
        key=$(whiptail --passwordbox "Введите суперключ APatch/KSU (попытка $i/3):" 10 50 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && exit 1
        
        result=$(supercall "$key" $SUPERCALL_HELLO)
        if [ "$result" -eq "$SUPERCALL_HELLO_MAGIC" ]; then
            return 0
        else
            whiptail --msgbox "Неверный ключ или SuperCall недоступен (код $result)" 10 50
        fi
    done
    return 1
}

# Главное меню
show_menu() {
    local key="$1"
    while true; do
        choice=$(whiptail --menu "APatch/KSU Manager" 15 50 5 \
            "1" "Проверить привилегии" \
            "2" "Получить root" \
            "3" "Загрузить модуль" \
            "4" "Управление ключами" \
            "5" "Выход" 3>&1 1>&2 2>&3)
        
        case "$choice" in
            1)
                id_info=$(id)
                kpatch_ver=$(supercall "$key" 2)  # KERNELPATCH_VER
                whiptail --msgbox "Текущие права:\n$id_info\n\nKernelPatch: $kpatch_ver" 15 50
                ;;
            2)
                result=$(supercall "$key" 4 "uid=0,gid=0,context=u:r:kernel:s0")
                [ "$result" -eq 0 ] && \
                    whiptail --msgbox "SUCCESS! Получены root-права" 10 40 || \
                    whiptail --msgbox "Ошибка $result при получении root" 10 50
                ;;
            3)
                path=$(whiptail --inputbox "Путь к модулю (.ko):" 10 50 3>&1 1>&2 2>&3)
                [ -n "$path" ] && {
                    result=$(supercall "$key" 15 "$path" "")  # KPM_LOAD
                    whiptail --msgbox "Результат загрузки: $result" 10 50
                }
                ;;
            4)
                new_key=$(whiptail --passwordbox "Новый суперключ:" 10 50 3>&1 1>&2 2>&3)
                [ -n "$new_key" ] && {
                    result=$(supercall "$key" 22 "$new_key")  # SKEY_SET
                    whiptail --msgbox "Результат смены ключа: $result" 10 50
                }
                ;;
            5)
                exit 0
                ;;
        esac
    done
}

# Точка входа
check_deps
check_key && show_menu "$key" || \
    whiptail --msgbox "Доступ запрещен. Проверьте APatch/KSU и ключ!" 10 50
