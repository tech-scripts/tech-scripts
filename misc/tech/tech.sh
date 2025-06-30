#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

TECH_SCRIPT=$(cat <<EOF
#!/usr/bin/env bash

[ "\${HOME##*/}" = ".suroot" ] && export HOME="\${HOME%/*}"

[ -w /tmp ] && USER_DIR="" || USER_DIR=\$HOME

SUDO=\$(env | grep -qi TERMUX && echo "" || command -v sudo 2>/dev/null)

source \$USER_DIR/etc/tech-scripts/source.sh

[ ! -d "\$USER_DIR/tmp/tech-scripts" ] && cd \$USER_DIR/tmp && git clone --depth 1 https://github.com/tech-scripts/tech-scripts.git && copy_files && change_directory_permissions

run_script() {
    local script_dir="\$1"
    local script_name="\$2"
    cd "\$CLONE_DIR_TECH/misc/\$script_dir"
    ./"\$script_name"
}

if [ \$# -eq 0 ]; then
    cd \$USER_DIR/tmp/tech-scripts/misc/tech
    ./menu.sh
    exit 0
fi

combined_args="\$*"

case "\$combined_args" in
    "menu") run_script "tech" "menu.sh" ;;
    "help") run_script "tech" "help.sh" ;;
    "update") run_script "tech" "update.sh" ;;
    "apatch") run_script "android" "apatch.sh" ;;
    "lxc") run_script "proxmox" "lxc.sh" ;;
    "vm") run_script "proxmox" "vm.sh" ;;
    "disk") run_script "tools/benchmark" "disk.sh" ;;
    "cpu") run_script "tools/benchmark" "cpu.sh" ;;
    "memory") run_script "tools/benchmark" "memory.sh" ;;
    "autoupdate") run_script "tools" "autoupdate.sh" ;;
    "grub") run_script "tools" "grub.sh" ;;
    "kernel") run_script "tools" "kernel.sh" ;;
    "ports") run_script "tools" "ports.sh" ;;
    "root") run_script "tools" "root.sh" ;;
    "ssh") run_script "tools" "ssh.sh" ;;
    "startup") run_script "tools" "startup.sh" ;;
    "swap") run_script "tools" "swap.sh" ;;
    "system") run_script "tools" "system.sh" ;;
    "config") run_script "tools" "config.sh" ;;
    *) echo ""; echo "\$UNKNOWN_COMMAND_TECH \$1"; echo "\$USAGE_TECH"; echo ""; exit 1 ;;
esac
EOF
)

if [ -f $TECH_COMMAND_DIR/tech ]; then
    whiptail --title "$TITLE_UPDATE_TECH" --yesno "$MSG_UPDATE_TECH" 10 40
    if [ $? -eq 0 ]; then
        $SUDO rm $TECH_COMMAND_DIR/tech
        $SUDO tee $TECH_COMMAND_DIR/tech > /dev/null <<< "$TECH_SCRIPT"
        $SUDO chmod +x $TECH_COMMAND_DIR/tech
        hash -d tech &>/dev/null
        echo " "
        echo "$MSG_UPDATED_TECH"
        echo " "
    else
        whiptail --title "$TITLE_REMOVE_TECH" --yesno "$MSG_REMOVE_TECH" 10 40
        if [ $? -eq 0 ]; then
            $SUDO rm $TECH_COMMAND_DIR/tech
            hash -d tech &>/dev/null
            echo " "
            echo "$MSG_REMOVED_TECH"
            echo " "
        else
            exit 0
        fi
    fi
else
    $SUDO tee $TECH_COMMAND_DIR/tech > /dev/null <<< "$TECH_SCRIPT"
    $SUDO chmod +x $TECH_COMMAND_DIR/tech
    hash -d tech &>/dev/null
fi
