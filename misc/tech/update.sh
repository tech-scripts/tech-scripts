#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

cat << 'EOF' > $USER_DIR/tmp/update.sh
#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

cd $USER_DIR/tmp
$SUDO rm -rf $USER_DIR/tmp/tech-scripts
git clone --depth 1 https://github.com/tech-scripts/tech-scripts.git $USER_DIR/tmp/tech-scripts
$SUDO rm -rf $TECH_COMMAND_DIR/tech
cd $USER_DIR/tmp/tech-scripts/misc/tech
chmod +x tech.sh
./tech.sh

TARGET_DIR="$USER_DIR/etc/tech-scripts/"
FILES=("localization.sh" "variables.sh" "functions.sh" "source.sh")

for file in "${FILES[@]}"; do
    cp -f "$USER_DIR/tmp/tech-scripts/misc/$file" "$TARGET_DIR" > /dev/null 2>&1 || $SUDO cp -f "$USER_DIR/tmp/tech-scripts/misc/$file" "$TARGET_DIR" > /dev/null 2>&1
done

change_directory_permissions
echo ""
if [ "$LANGUAGE" ]; then
echo "Обновление завершено!"
else
echo "Update completed!"
fi
echo ""
EOF
chmod +x $USER_DIR/tmp/update.sh
$USER_DIR/tmp/update.sh
$SUDO rm -f /tmp/update.sh
