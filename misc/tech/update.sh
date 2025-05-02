#!/usr/bin/env bash

cat << 'EOF' > /tmp/update.sh
#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$(pwd)

source $USER_DIR/etc/tech-scripts/source.sh

cd $USER_DIR/tmp
$SUDO rm -rf /tmp/tech-scripts
git clone --depth 1 https://github.com/tech-scripts/tech-scripts.git $USER_DIR/tmp/tech-scripts
$SUDO rm -rf /usr/local/bin/tech
cd $USER_DIR/tmp/tech-scripts/misc/tech
chmod +x tech.sh
./tech.sh
$SUDO cp -f $USER_DIR/tmp/tech-scripts/misc/localization.sh $USER_DIR/etc/tech-scripts/
$SUDO cp -f $USER_DIR/tmp/tech-scripts/misc/variables.sh $USER_DIR/etc/tech-scripts/
$SUDO cp -f $USER_DIR/tmp/tech-scripts/misc/functions.sh $USER_DIR/etc/tech-scripts/
$SUDO cp -f $USER_DIR/tmp/tech-scripts/misc/source.sh $USER_DIR/etc/tech-scripts/
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
rm -f /tmp/update.sh
