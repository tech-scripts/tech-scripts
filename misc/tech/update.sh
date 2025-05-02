#!/usr/bin/env bash

cat << 'EOF' > /tmp/update.sh
#!/usr/bin/env bash

SUDO=$(command -v sudo)
LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

cd /tmp
$SUDO rm -rf /tmp/tech-scripts
git clone --depth 1 https://github.com/tech-scripts/tech-scripts.git /tmp/tech-scripts
$SUDO rm -rf /usr/local/bin/tech
cd "/tmp/tech-scripts/misc/tech"
chmod +x tech.sh
./tech.sh
$SUDO cp -f /tmp/tech-scripts/misc/localization.sh /etc/tech-scripts/
$SUDO cp -f /tmp/tech-scripts/misc/variables.sh /etc/tech-scripts/
[ -n "\$BASIC_DIRECTORY" ] && IFS=' ' read -r -a directories <<< "\$BASIC_DIRECTORY"

for dir in "\${directories[@]}"; do
    [ -d "\$dir" ] && [ "\$(stat -c "%a" "\$dir")" != "\$ACCESS" ] && \$SUDO chmod -R "\$ACCESS" "\$dir"
done
echo ""
if [ "$LANGUAGE" ]; then
echo "Обновление завершено!"
else
echo "Update completed!"
fi
echo ""
EOF
chmod +x /tmp/update.sh
/tmp/update.sh
rm -f /tmp/update.sh
