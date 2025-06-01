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
copy_files
change_directory_permissions
$SUDO hash -d tech
echo ""
if [ "$LANGUAGE" ]; then
echo "Обновление завершено!"
else
echo "Update completed!"
fi
echo ""
EOF
chmod 777 $USER_DIR/tmp/update.sh
$USER_DIR/tmp/update.sh
$SUDO rm -f /tmp/update.sh
