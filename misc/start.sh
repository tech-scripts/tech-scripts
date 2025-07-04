#!/usr/bin/env bash

[ "${HOME##*/}" = ".suroot" ] && export HOME="${HOME%/*}"

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

SUDO=$(env | grep -qi TERMUX && echo "" || command -v sudo 2>/dev/null)
CLONE_DIR="$USER_DIR/tmp/tech-scripts/misc"
CONFIG_DIR="$USER_DIR/etc/tech-scripts/choose.conf"

[ ! -f "$CONFIG_DIR" ] && RESULT="true" || RESULT="false"

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

update_packages() {
    if command -v pkg &>/dev/null; then
        pkg update
    elif command -v brew &>/dev/null; then
        brew update
    elif command -v apk &>/dev/null; then
        $SUDO apk update
    elif command -v apt &>/dev/null; then
        $SUDO apt update
    elif command -v yum &>/dev/null; then
        $SUDO yum update
    elif command -v dnf &>/dev/null; then
        $SUDO dnf makecache
    elif command -v zypper &>/dev/null; then
        $SUDO zypper refresh
    elif command -v pacman &>/dev/null; then
        $SUDO pacman -Sy
    else
        echo "The package manager could not be identified. Cannot update packages!"
        exit 1
    fi
}

package_exists() {
    local package=$1
    local found_packages

    if command -v pkg &>/dev/null; then
        found_packages=$(pkg search "$package" 2>/dev/null)
    elif command -v brew &>/dev/null; then
        found_packages=$(brew search "$package" 2>/dev/null)
    elif command -v apk &>/dev/null; then
        found_packages=$(apk search "$package" 2>/dev/null)
    elif command -v apt &>/dev/null; then
        found_packages=$(apt-cache search "$package" 2>/dev/null)
    elif command -v yum &>/dev/null; then
        found_packages=$(yum list available "$package" 2>/dev/null)
    elif command -v dnf &>/dev/null; then
        found_packages=$(dnf list available "$package" 2>/dev/null)
    elif command -v zypper &>/dev/null; then
        found_packages=$(zypper se "$package" 2>/dev/null)
    elif command -v pacman &>/dev/null; then
        found_packages=$(pacman -Ss "$package" 2>/dev/null)
    else
        return 1
    fi

    if echo "$found_packages" | grep -q "$package"; then
        return 0
    else
        return 1
    fi
}

install_package() {
    local package=$1
    local install_cmd=""
    if command -v pkg &>/dev/null; then
        install_cmd="pkg install -y"
    elif command -v brew &>/dev/null; then
        install_cmd="brew install"
    elif command -v apk &>/dev/null; then
        install_cmd="$SUDO apk add"
    elif command -v apt &>/dev/null; then
        install_cmd="$SUDO apt install -y"
    elif command -v yum &>/dev/null; then
        install_cmd="$SUDO yum install -y"
    elif command -v dnf &>/dev/null; then
        install_cmd="$SUDO dnf install -y"
    elif command -v zypper &>/dev/null; then
        install_cmd="$SUDO zypper install -y"
    elif command -v pacman &>/dev/null; then
        install_cmd="$SUDO pacman -S --noconfirm"
    else
        echo "The package manager could not be identified. Cannot install $package!"
        exit 1
    fi
    eval "$install_cmd \"$package\""
}

manage_packages() {
    required_packages=(git)
    optional_packages_1=(newt whiptail)
    optional_packages_2=(curl wget)
    optional_packages_3=(nano vim)

    any_installed() {
        local -n arr=$1
        for pkg in "${arr[@]}"; do
            if command -v "$pkg" &>/dev/null; then
                return 0
            fi
        done
        return 1
    }

    all_required_installed=true
    for pkg in "${required_packages[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            all_required_installed=false
            break
        fi
    done

    optional_installed=false
    for optional_group in optional_packages_1 optional_packages_2 optional_packages_3; do
        if any_installed "$optional_group"; then
            optional_installed=true
            break
        fi
    done

    if [ "$all_required_installed" = false ] || [ "$optional_installed" = false ]; then
        update_packages
    fi

    for pkg in "${required_packages[@]}"; do
        if ! command -v "$pkg" &>/dev/null && package_exists "$pkg"; then
            install_package "$pkg"
        fi
    done

    install_optional_group() {
        local -n arr=$1
        local installed_count=0
        for pkg in "${arr[@]}"; do
            if command -v "$pkg" &>/dev/null; then
                ((installed_count++))
            fi
        done

        if (( installed_count == 0 )); then
            for pkg in "${arr[@]}"; do
                if package_exists "$pkg"; then
                    install_package "$pkg"
                fi
            done
        fi
    }

    install_optional_group optional_packages_1
    install_optional_group optional_packages_2
    install_optional_group optional_packages_3
}


if [ ! -f "$USER_DIR/etc/tech-scripts/choose.conf" ]; then
    show_inscription
    manage_packages
fi

[ ! -d "$USER_DIR/tmp" ] && $SUDO mkdir -p "$USER_DIR/tmp"
[ ! -d "$USER_DIR/etc" ] && $SUDO mkdir -p "$USER_DIR/etc"
[ ! -d "$USER_DIR/usr" ] && $SUDO mkdir -p "$USER_DIR/usr"

[ ! -d "$USER_DIR/tmp/tech-scripts" ] && cd $USER_DIR/tmp && git clone --depth 1 https://github.com/tech-scripts/tech-scripts.git

[ ! -d "$USER_DIR/etc/tech-scripts" ] && $SUDO mkdir -p "$USER_DIR/etc/tech-scripts"
[ ! -d "$USER_DIR/usr/local/tech-scripts" ] && $SUDO mkdir -p "$USER_DIR/usr/local/tech-scripts"
[ ! -d "$USER_DIR/usr/local/bin" ] && $SUDO mkdir -p "$USER_DIR/usr/local/bin"

TARGET_DIR="$USER_DIR/etc/tech-scripts/"
FILES=("localization.sh" "variables.sh" "functions.sh" "source.sh")

for file in "${FILES[@]}"; do
    cp -f "$USER_DIR/tmp/tech-scripts/misc/$file" "$TARGET_DIR" > /dev/null 2>&1 || $SUDO cp -f "$USER_DIR/tmp/tech-scripts/misc/$file" "$TARGET_DIR" > /dev/null 2>&1
done

cd "$CLONE_DIR"

if [ ! -f "$USER_DIR/etc/tech-scripts/choose.conf" ]; then
    $SUDO touch $USER_DIR/etc/tech-scripts/choose.conf
    {
        echo "lang: English"
        echo "access: 755"
        echo "editor: nano"
        echo "hide: true"
    } | $SUDO tee -a $USER_DIR/etc/tech-scripts/choose.conf > /dev/null
    $SUDO chmod +x "choose.sh"
    ./choose.sh
fi

source $USER_DIR/etc/tech-scripts/source.sh

BASIC_DIRECTORY=$(echo "$BASIC_DIRECTORY" | tr -s ' ')

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

echo ""
[ "$RESULT" == "true" ] && complete_install || complete_repair
echo ""
