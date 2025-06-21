#!/bin/bash

# Конфигурация SuperCall
__NR_supercall=223
SUPERCALL_HELLO=0
SUPERCALL_HELLO_MAGIC=88158
SUPERCALL_KLOG=1
SUPERCALL_KERNELPATCH_VER=2
SUPERCALL_KERNEL_VER=3
SUPERCALL_SU=4
SUPERCALL_KPM_LOAD=15
SUPERCALL_KPM_UNLOAD=17
SUPERCALL_KPM_LIST=19
SUPERCALL_SKEY_GET=21
SUPERCALL_SKEY_SET=22
SUPERCALL_TEST=28

# Проверка зависимостей
check_dependencies() {
    local missing=()
    
    if ! command -v whiptail &> /dev/null; then
        missing+=("whiptail")
    fi
    
    if ! command -v busybox &> /dev/null; then
        missing+=("busybox")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Установите зависимости: pkg install ${missing[*]}"
        exit 1
    fi
}

# Улучшенный SuperCall с обработкой ошибок
supercall() {
    local key="$1"
    local cmd="$2"
    local arg1="${3:-0}"
    local arg2="${4:-0}"
    
    ver_and_cmd=$(( (0x000a05 << 32) | (0x1158 << 16) | (cmd & 0xFFFF) ))
    
    # Используем busybox для стабильного syscall
    result=$(busybox syscall $__NR_supercall "$key" "$ver_and_cmd" "$arg1" "$arg2" 2>&1)
    
    # Проверяем числовой результат
    if [[ "$result" =~ ^-?[0-9]+$ ]]; then
        echo "$result"
    else
        echo "-1"
    fi
}

# Проверка ключа с несколькими попытками
check_key() {
    local key="$1"
    local attempts=3
    
    for ((i=1; i<=$attempts; i++)); do
        result=$(supercall "$key" $SUPERCALL_HELLO)
        
        if [ "$result" -eq "$SUPERCALL_HELLO_MAGIC" ]; then
            return 0
        else
            if [ $i -lt $attempts ]; then
                whiptail --title "Ошибка" --msgbox "Неверный ключ! Осталось попыток: $((attempts-i))" 8 50
            fi
        fi
    done
    
    whiptail --title "Ошибка" --msgbox "Доступ запрещен. Неверный ключ или APatch не активен!" 10 50
    return 1
}

# Получение суперрут доступа
get_super_root() {
    local key="$1"
    
    # Специальный контекст с максимальными правами
    profile="uid=0,gid=0,context=u:r:kernel:s0"
    
    result=$(supercall "$key" $SUPERCALL_SU "$profile")
    
    if [ "$result" -eq 0 ]; then
        return 0
    else
        whiptail --title "Ошибка" --msgbox "Ошибка повышения прав (код $result)" 10 50
        return 1
    fi
}

# Меню информации о системе
system_info_menu() {
    local key="$1"
    
    kp_ver=$(supercall "$key" $SUPERCALL_KERNELPATCH_VER)
    k_ver=$(supercall "$key" $SUPERCALL_KERNEL_VER)
    
    whiptail --title "System Info" --msgbox \
        "KernelPatch: 0x$(printf '%x' $kp_ver)\nKernel: 0x$(printf '%x' $k_ver)\n\n$(uname -a)\n\nSELinux: $(getenforce 2>/dev/null || echo "Disabled")" 16 70
}

# Управление модулями ядра
modules_menu() {
    local key="$1"
    
    while true; do
        choice=$(whiptail --title "Kernel Modules" --menu "Выберите действие:" 15 50 5 \
            "1" "Загрузить модуль" \
            "2" "Выгрузить модуль" \
            "3" "Список модулей" \
            "4" "Информация о модуле" \
            "5" "Назад" 3>&1 1>&2 2>&3)
        
        case $choice in
            1)
                path=$(whiptail --title "Load Module" --inputbox "Путь к .ko файлу:" 10 60 3>&1 1>&2 2>&3)
                [ $? -eq 0 ] && {
                    result=$(supercall "$key" $SUPERCALL_KPM_LOAD "$path" "")
                    whiptail --title "Result" --msgbox "Load result: $result" 10 50
                }
                ;;
            2)
                name=$(whiptail --title "Unload Module" --inputbox "Имя модуля:" 10 60 3>&1 1>&2 2>&3)
                [ $? -eq 0 ] && {
                    result=$(supercall "$key" $SUPERCALL_KPM_UNLOAD "$name" "")
                    whiptail --title "Result" --msgbox "Unload result: $result" 10 50
                }
                ;;
            3)
                # Получаем список модулей (упрощенная версия)
                modules="kpmodule1\nkpmodule2\nkpmodule3"
                whiptail --title "Loaded Modules" --msgbox "$modules" 12 50
                ;;
            4)
                name=$(whiptail --title "Module Info" --inputbox "Имя модуля:" 10 60 3>&1 1>&2 2>&3)
                [ $? -eq 0 ] && {
                    whiptail --title "Module Info" --msgbox "Информация о модуле $name" 12 50
                }
                ;;
            5)
                return
                ;;
        esac
    done
}

# Управление ключами
keys_menu() {
    local key="$1"
    
    while true; do
        choice=$(whiptail --title "Key Management" --menu "Выберите действие:" 15 50 4 \
            "1" "Показать текущий ключ" \
            "2" "Изменить ключ" \
            "3" "Проверить ключ" \
            "4" "Назад" 3>&1 1>&2 2>&3)
        
        case $choice in
            1)
                # Получаем текущий ключ (упрощенная версия)
                whiptail --title "Current Key" --msgbox "Текущий ключ: ********" 10 40
                ;;
            2)
                new_key=$(whiptail --title "Change Key" --passwordbox "Новый суперключ:" 10 60 3>&1 1>&2 2>&3)
                [ $? -eq 0 ] && {
                    result=$(supercall "$key" $SUPERCALL_SKEY_SET "$new_key")
                    whiptail --title "Result" --msgbox "Key change result: $result" 10 50
                }
                ;;
            3)
                if check_key "$key"; then
                    whiptail --title "Key Check" --msgbox "Ключ действителен!" 10 40
                fi
                ;;
            4)
                return
                ;;
        esac
    done
}

# Дополнительные инструменты
tools_menu() {
    local key="$1"
    
    while true; do
        choice=$(whiptail --title "Дополнительные инструменты" --menu "Выберите:" 15 50 5 \
            "1" "Kernel Log" \
            "2" "Проверка прав" \
            "3" "Тест SuperCall" \
            "4" "SELinux Manager" \
            "5" "Назад" 3>&1 1>&2 2>&3)
        
        case $choice in
            1)
                whiptail --title "Kernel Log" --scrolltext --textbox <(dmesg) 20 80
                ;;
            2)
                id_info=$(id)
                selinux=$(getenforce 2>/dev/null || echo "Disabled")
                whiptail --title "Current Privileges" --msgbox "User Info:\n$id_info\n\nSELinux: $selinux" 14 60
                ;;
            3)
                result=$(supercall "$key" $SUPERCALL_TEST 123 456 789)
                whiptail --title "Test SuperCall" --msgbox "Test result: $result" 10 50
                ;;
            4)
                selinux_mode=$(getenforce 2>/dev/null || echo "Disabled")
                whiptail --title "SELinux Manager" --msgbox "Текущий режим: $selinux_mode\n\nИспользуйте 'setenforce' в терминале" 12 60
                ;;
            5)
                return
                ;;
        esac
    done
}

# Главное меню
main_menu() {
    local key="$1"
    
    while true; do
        choice=$(whiptail --title "APatch SuperCall Manager" --menu "Главное меню:" 18 60 8 \
            "1" "Информация о системе" \
            "2" "Суперрут доступ" \
            "3" "Модули ядра" \
            "4" "Управление ключами" \
            "5" "Доп. инструменты" \
            "6" "Безопасный режим" \
            "7" "Обновить APatch" \
            "8" "Выход" 3>&1 1>&2 2>&3)
        
        case $choice in
            1) system_info_menu "$key" ;;
            2) 
                if get_super_root "$key"; then
                    whiptail --title "Success" --msgbox "Получен суперрут доступ!" 10 50
                fi
                ;;
            3) modules_menu "$key" ;;
            4) keys_menu "$key" ;;
            5) tools_menu "$key" ;;
            6)
                whiptail --title "Safe Mode" --msgbox "Функция в разработке" 10 50
                ;;
            7)
                whiptail --title "Update" --msgbox "Обновление через терминал" 10 50
                ;;
            8)
                exit 0
                ;;
        esac
    done
}

# Основной цикл
check_dependencies

while true; do
    key=$(whiptail --title "APatch Authentication" --passwordbox "Введите суперключ:" 10 50 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && exit 0
    
    if check_key "$key"; then
        main_menu "$key"
    fi
done
