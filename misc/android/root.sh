#!/usr/bin/env bash

# Проверка зависимостей
check_dependencies() {
    if ! command -v whiptail &> /dev/null; then
        echo "Установите whiptail: pkg install whiptail"
        exit 1
    fi
    if ! command -v tsu &> /dev/null; then
        echo "Установите tsu: pkg install tsu"
        exit 1
    fi
}

# Проверка root-прав
check_root() {
    [ "$(id -u)" = "0" ]
}

# Проверка состояния SELinux
check_selinux() {
    getenforce 2>/dev/null || echo "Disabled"
}

# Проверка состояния загрузчика
check_bootloader() {
    if [ -d /sys/block/bootdevice ]; then
        echo "Unlocked"
    else
        echo "Locked"
    fi
}

# Получение версии ядра в hex
get_kernel_hex() {
    uname -r | awk -F. '{ printf "0x%x%02x%02x", $1, $2, $3 }'
}

# Получение информации о рут-доступе
get_root_info() {
    if check_root; then
        echo "Root доступ: Active (UID 0)"
        if [ -f /system/xbin/su ]; then
            echo "Root менеджер: SuperSU"
        elif [ -f /system/bin/magisk ]; then
            echo "Root менеджер: Magisk"
        else
            echo "Root менеджер: Unknown"
        fi
    else
        echo "Root доступ: Not available"
    fi
}

# Функция ремаунта и получения root-оболочки
root_shell() {
    if ! check_root; then
        if ! tsu -c "mount -o remount,rw /system && echo 'Файловая система перемонтирована в RW'"; then
            whiptail --title "Ошибка" --msgbox "Не удалось получить root-доступ!" 10 50
            return 1
        fi
    fi
    
    # Ремаунт всех разделов в RW
    mount -o remount,rw / 2>/dev/null
    mount -o remount,rw /system 2>/dev/null
    mount -o remount,rw /data 2>/dev/null
    mount -o remount,rw /vendor 2>/dev/null
    
    # Запуск интерактивной оболочки
    clear
    echo "────────────────────────────────────────────"
    echo " ВЫ ВОШЛИ В ПРИВИЛЕГИРОВАННУЮ ОБОЛОЧКУ"
    echo " Все файловые системы перемонтированы в RW"
    echo "────────────────────────────────────────────"
    echo " Доступные команды:"
    echo " • edit - редактор системных файлов"
    echo " • remount - перемонтировать разделы"
    echo " • exit - вернуться в меню"
    echo "────────────────────────────────────────────"
    
    while true; do
        read -p "root-shell # " cmd
        case $cmd in
            edit)
                file=$(whiptail --title "Редактор системных файлов" --inputbox "Введите путь к файлу:" 10 60 3>&1 1>&2 2>&3)
                [ -n "$file" ] && nano "$file"
                ;;
            remount)
                whiptail --title "Ремаунт разделов" --msgbox "Перемонтирую все разделы в RW..." 10 40
                mount -o remount,rw / 2>/dev/null
                mount -o remount,rw /system 2>/dev/null
                mount -o remount,rw /data 2>/dev/null
                mount -o remount,rw /vendor 2>/dev/null
                ;;
            exit)
                return 0
                ;;
            *)
                eval "$cmd"
                ;;
        esac
    done
}

# Удаление приложений
remove_apps() {
    while true; do
        choice=$(whiptail --title "Удаление приложений" --menu "Выберите действие:" 15 50 4 \
            "1" "Удалить системное приложение" \
            "2" "Удалить пользовательское приложение" \
            "3" "Список приложений" \
            "4" "Назад" 3>&1 1>&2 2>&3)
        
        case $choice in
            1)
                apps=$(pm list packages -s | cut -d: -f2)
                app=$(whiptail --title "Системные приложения" --inputbox "Введите имя пакета:" 10 60 3>&1 1>&2 2>&3)
                [ -n "$app" ] && pm uninstall -k --user 0 "$app"
                ;;
            2)
                apps=$(pm list packages -3 | cut -d: -f2)
                app=$(whiptail --title "Пользовательские приложения" --inputbox "Введите имя пакета:" 10 60 3>&1 1>&2 2>&3)
                [ -n "$app" ] && pm uninstall "$app"
                ;;
            3)
                whiptail --title "Список приложений" --scrolltext --msgbox "$(pm list packages -s | sed 's/package://' && echo '\n\nПользовательские:\n' && pm list packages -3 | sed 's/package://')" 20 60
                ;;
            4)
                return 0
                ;;
        esac
    done
}

# Меню информации о системе
system_info_menu() {
    local info=""
    info+="KernelPatch версия: 0x$(get_kernel_hex)\n"
    info+="Ядро: $(uname -r)\n"
    info+="Архитектура: $(uname -m)\n\n"
    info+="$(get_root_info)\n"
    info+="SELinux: $(check_selinux)\n"
    info+="Загрузчик: $(check_bootloader)\n"
    info+="Память: $(free -m | awk '/Mem/{print $2}') MB\n"
    info+="Хранилище: $(df -h / | awk 'NR==2{print $4}') свободно\n\n"
    info+="$(uname -a)"
    
    whiptail --title "Информация о системе" --msgbox "$info" 20 70
}

# Управление модулями ядра
modules_menu() {
    while true; do
        choice=$(whiptail --title "Управление модулями ядра" --menu "Выберите действие:" 15 50 5 \
            "1" "Загрузить модуль" \
            "2" "Выгрузить модуль" \
            "3" "Список модулей" \
            "4" "Автозагрузка модуля" \
            "5" "Назад" 3>&1 1>&2 2>&3)
        
        case $choice in
            1)
                path=$(whiptail --title "Загрузка модуля" --inputbox "Введите путь к модулю:" 10 60 3>&1 1>&2 2>&3)
                [ -n "$path" ] && insmod "$path" 
                whiptail --title "Результат" --msgbox "Код операции: $?" 10 40
                ;;
            2)
                name=$(whiptail --title "Выгрузка модуля" --inputbox "Введите имя модуля:" 10 60 3>&1 1>&2 2>&3)
                [ -n "$name" ] && rmmod "$name" 
                whiptail --title "Результат" --msgbox "Код операции: $?" 10 40
                ;;
            3)
                whiptail --title "Список модулей" --scrolltext --msgbox "$(lsmod)" 20 60
                ;;
            4)
                name=$(whiptail --title "Автозагрузка модуля" --inputbox "Имя модуля для автозагрузки:" 10 60 3>&1 1>&2 2>&3)
                [ -n "$name" ] && echo "$name" >> /etc/modules
                whiptail --title "Результат" --msgbox "Модуль $name добавлен в автозагрузку" 10 40
                ;;
            5)
                return 0
                ;;
        esac
    done
}

# Главное меню
main_menu() {
    while true; do
        local root_status
        check_root && root_status="(ROOT)" || root_status=""
        
        choice=$(whiptail --title "Kernel Manager $root_status" --menu "Выберите действие:" 19 60 10 \
            "1" "Информация о системе" \
            "2" "ROOT оболочка + RW доступ" \
            "3" "Управление модулями ядра" \
            "4" "Удаление приложений" \
            "5" "Просмотр логов ядра" \
            "6" "Сетевые настройки" \
            "7" "Управление процессами" \
            "8" "Настройки безопасности" \
            "9" "Обновить ядро" \
            "0" "Выход" 3>&1 1>&2 2>&3)
        
        case $choice in
            1) system_info_menu ;;
            2) root_shell ;;
            3) modules_menu ;;
            4) 
                if check_root; then
                    remove_apps 
                else
                    whiptail --title "Ошибка" --msgbox "Требуются root-права!" 10 50
                fi
                ;;
            5)
                whiptail --title "Логи ядра" --scrolltext --textbox /proc/kmsg 20 80
                ;;
            6)
                whiptail --title "Сетевые настройки" --scrolltext --msgbox "$(ip addr show && echo -e "\n\nМаршруты:\n$(ip route)" && echo -e "\n\nПорты:\n$(netstat -tuln)")" 25 80
                ;;
            7)
                whiptail --title "Управление процессами" --scrolltext --msgbox "$(ps aux)" 25 80
                ;;
            8)
                selinux_choice=$(whiptail --title "Настройки SELinux" --menu "Текущий режим: $(check_selinux)" 15 50 4 \
                    "1" "Переключить в Enforcing" \
                    "2" "Переключить в Permissive" \
                    "3" "Назад" 3>&1 1>&2 2>&3)
                
                case $selinux_choice in
                    1) setenforce 1 ;;
                    2) setenforce 0 ;;
                esac
                ;;
            9)
                kernel_url=$(whiptail --title "Обновление ядра" --inputbox "Введите URL ядра:" 10 60 3>&1 1>&2 2>&3)
                if [ -n "$kernel_url" ]; then
                    whiptail --title "Обновление" --msgbox "Загрузка и установка ядра..." 10 50
                    wget "$kernel_url" -O /tmp/kernel.zip
                    unzip /tmp/kernel.zip -d /tmp
                    dd if=/tmp/kernel.img of=/dev/block/bootdevice/by-name/boot
                    whiptail --title "Готово" --msgbox "Ядро успешно обновлено! Перезагрузите устройство." 10 50
                fi
                ;;
            0)
                exit 0
                ;;
        esac
    done
}

# Инициализация
check_dependencies
clear
echo "────────────────────────────────────────────"
echo " Kernel Manager v2.0 | Android Linux Tool"
echo "────────────────────────────────────────────"
echo " • Root доступ: $(check_root && echo 'Да' || echo 'Нет')"
echo " • SELinux: $(check_selinux)"
echo " • Загрузчик: $(check_bootloader)"
echo "────────────────────────────────────────────"

# Проверка root-прав при запуске
if ! check_root; then
    if whiptail --title "Root доступ" --yesno "Root доступ не обнаружен. Попытаться получить?" 10 50; then
        if ! tsu -c "echo 'Root получен!'"; then
            whiptail --title "Ошибка" --msgbox "Не удалось получить root-доступ. Некоторые функции будут ограничены." 10 50
        fi
    fi
fi

# Запуск главного меню
main_menu
