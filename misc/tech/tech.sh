#!/bin/bash

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

TECH_SCRIPT=$(cat <<EOF
#!/bin/bash

SUDO=$(command -v sudo)

[ ! -d "/tmp/tech-scripts" ] && cd /tmp && git clone --depth 1 https://github.com/tech-scripts/tech-scripts.git /tmp/tech-scripts

$SUDO cp -f /tmp/tech-scripts/misc/localization.sh /etc/tech-scripts/
$SUDO cp -f /tmp/tech-scripts/misc/variables.sh /etc/tech-scripts/

source /etc/tech-scripts/localization.sh
source /etc/tech-scripts/variables.sh

BASIC_DIRECTORY=$(echo "$BASIC_DIRECTORY" | tr -s ' ')

if [ -n "$BASIC_DIRECTORY" ]; then
    echo "Processing BASIC_DIRECTORY: '$BASIC_DIRECTORY'"
    IFS=' ' read -r -a directories <<< "$BASIC_DIRECTORY"

    for dir in "${directories[@]}"; do
        if [ -n "$dir" ]; then
            echo "Checking directory: '$dir'"
            if [ -d "$dir" ]; then
                echo "Directory exists: '$dir'"
                current_access=$(stat -c "%a" "$dir")
                echo "Current access for '$dir': $current_access"
                if [ "$current_access" != "$ACCESS" ]; then
                    echo "Changing access for '$dir' to $ACCESS"
                    $SUDO chmod "$ACCESS" "$dir"
                else
                    echo "Access for '$dir' is already set to $ACCESS"
                fi
            else
                echo "Directory does not exist: '$dir'"
            fi
        else
            echo "Empty directory name encountered, skipping."
        fi
    done
else
    echo "BASIC_DIRECTORY variable is empty. Skipping execution."
fi

run_script() {
    local script_dir="\$1"
    local script_name="\$2"
    cd "\$CLONE_DIR_TECH/misc/\$script_dir"
    chmod +x "\$script_name"
    ./"\$script_name"
}

if [ \$# -eq 0 ]; then
    cd /tmp/tech-scripts/misc
    chmod +x start.sh
    ./start.sh
    exit 0
fi

combined_args="\$*"

case "\$combined_args" in
    "update") run_script "tech" "update.sh" ;;
    "lxc") run_script "proxmox" "lxc.sh" ;;
    "vm") run_script "proxmox" "vm.sh" ;;
    "disk") run_script "tools/benchmark" "disk.sh" ;;
    "cpu") run_script "tools/benchmark" "cpu.sh" ;;
    "memory") run_script "tools/benchmark" "memory.sh" ;;
    "autoupdate") run_script "tools" "autoupdate.sh" ;;
    "grub") run_script "tools" "grub.sh" ;;
    "need") run_script "tools" "need.sh" ;;
    "ssh") run_script "tools" "ssh.sh" ;;
    "startup") run_script "tools" "startup.sh" ;;
    "swap") run_script "tools" "swap.sh" ;;
    "system") run_script "tools" "system.sh" ;;
    "config") run_script "tools" "config.sh" ;;
    *) echo ""; echo "$UNKNOWN_COMMAND_TECH \$1"; echo "$USAGE_TECH"; echo ""; exit 1 ;;
esac
EOF
)

if [ -f /usr/local/bin/tech ]; then
    whiptail --title "$TITLE_UPDATE_TECH" --yesno "$MSG_UPDATE_TECH" 10 40
    if [ $? -eq 0 ]; then
        $SUDO rm /usr/local/bin/tech
        $SUDO tee /usr/local/bin/tech > /dev/null <<< "$TECH_SCRIPT"
        $SUDO chmod +x /usr/local/bin/tech
        echo " "
        echo "$MSG_UPDATED_TECH"
        echo " "
    else
        whiptail --title "$TITLE_REMOVE_TECH" --yesno "$MSG_REMOVE_TECH" 10 40
        if [ $? -eq 0 ]; then
            $SUDO rm /usr/local/bin/tech
            echo " "
            echo "$MSG_REMOVED_TECH"
            echo " "
        else
            exit 0
        fi
    fi
else
    $SUDO tee /usr/local/bin/tech > /dev/null <<< "$TECH_SCRIPT"
    $SUDO chmod +x /usr/local/bin/tech
fi
