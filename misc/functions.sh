#!/usr/bin/env bash

show_inscription() {
    clear
    cat <<"EOF"
    
  ______          __       _____           _       __      
 /_  __/__  _____/ /_     / ___/__________(_)___  / /______
  / / / _ \/ ___/ __ \    \__ \/ ___/ ___/ / __ \/ __/ ___/
 / / /  __/ /__/ / / /   ___/ / /__/ /  / / /_/ / /_(__  ) 
/_/  \___/\___/_/ /_/   /____/\___/_/  /_/ .___/\__/____/  
                                        /_/                

EOF
}


change_directory_permissions() {
    [ -n "$BASIC_DIRECTORY" ] && IFS=' ' read -r -a directories <<< "$BASIC_DIRECTORY"

    getent group tech > /dev/null 2>&1 || { command -v groupadd > /dev/null 2>&1 && $SUDO groupadd tech; }

    for dir in "${directories[@]}"; do
        [ -n "$dir" ] && [ -e "$dir" ] || continue
        if [ "$(stat -c "%a" "$dir")" != "$ACCESS" ] || [ "$(stat -c "%G" "$dir")" != "tech" ]; then
            CMD="chmod -R $ACCESS $dir; getent group tech > /dev/null 2>&1 && chgrp -R tech $dir"
            if ! chgrp -R tech "$dir" 2>/dev/null; then
                $SUDO bash -c "$CMD"
            else
                bash -c "$CMD"
            fi
        fi
    done
}

copy_files() {
    TARGET_DIR="$USER_DIR/etc/tech-scripts/"
    FILES=("localization.sh" "variables.sh" "functions.sh" "source.sh")

    for file in "${FILES[@]}"; do
        cp -f "$USER_DIR/tmp/tech-scripts/misc/$file" "$TARGET_DIR" > /dev/null 2>&1 || \
        $SUDO cp -f "$USER_DIR/tmp/tech-scripts/misc/$file" "$TARGET_DIR" > /dev/null 2>&1
    done
}

compete_install() {
    echo -e "${COLOR_GREEN}╔══════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_GREEN}║                                              ║${COLOR_RESET}"
    echo -e "${COLOR_GREEN}║      ${COLOR_RESET}${COLOR_WHITE}Вы успешно завершили установление!      ${COLOR_GREEN}║${COLOR_RESET}"
    echo -e "${COLOR_GREEN}║                                              ║${COLOR_RESET}"
    echo -e "${COLOR_GREEN}║        ${COLOR_RESET}${COLOR_WHITE}tech menu${COLOR_RESET} ${COLOR_GRAY}- ${COLOR_GREEN}Главное меню              ${COLOR_GREEN}║${COLOR_RESET}"
    echo -e "${COLOR_GREEN}║        ${COLOR_RESET}${COLOR_WHITE}tech help${COLOR_RESET} ${COLOR_GRAY}- ${COLOR_GREEN}Помощь по командам        ${COLOR_GREEN}║${COLOR_RESET}"
    echo -e "${COLOR_GREEN}║                                              ║${COLOR_RESET}"
    echo -e "${COLOR_GREEN}╚══════════════════════════════════════════════╝${COLOR_RESET}"
}

compete_repair() {
    echo -e "${COLOR_BLUE}╔══════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_BLUE}║                                              ║${COLOR_RESET}"
    echo -e "${COLOR_BLUE}║     ${COLOR_RESET}${COLOR_WHITE}Вы успешно завершили восстановление!     ${COLOR_BLUE}║${COLOR_RESET}"
    echo -e "${COLOR_BLUE}║                                              ║${COLOR_RESET}"
    echo -e "${COLOR_BLUE}║       ${COLOR_RESET}${COLOR_WHITE}tech menu${COLOR_RESET} ${COLOR_GRAY}- ${COLOR_BLUE}Главное меню               ${COLOR_BLUE}║${COLOR_RESET}"
    echo -e "${COLOR_BLUE}║       ${COLOR_RESET}${COLOR_WHITE}tech help${COLOR_RESET} ${COLOR_GRAY}- ${COLOR_BLUE}Помощь по командам         ${COLOR_BLUE}║${COLOR_RESET}"
    echo -e "${COLOR_BLUE}║                                              ║${COLOR_RESET}"
    echo -e "${COLOR_BLUE}╚══════════════════════════════════════════════╝${COLOR_RESET}"
}

compete_remove() {
    echo -e "${COLOR_RED}╔══════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_RED}║                                              ║${COLOR_RESET}"
    echo -e "${COLOR_RED}║        ${COLOR_RESET}${COLOR_WHITE}Вы успешно завершили удаление!        ${COLOR_RED}║${COLOR_RESET}"
    echo -e "${COLOR_RED}║                                              ║${COLOR_RESET}"
    echo -e "${COLOR_RED}╚══════════════════════════════════════════════╝${COLOR_RESET}"
}
