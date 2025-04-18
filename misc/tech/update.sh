#!/bin/bash

cat << 'EOF' > /tmp/update.sh
#!/bin/bash

SUDO=$(command -v sudo)
LANGUAGE=$(grep '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2)

cd /tmp
rm -rf /tmp/tech-scripts
git clone --depth 1 https://github.com/tech-scripts/linux.git /tmp/tech-scripts
$SUDO rm -rf /usr/local/bin/tech
cd "/tmp/tech-scripts/misc/tech"
chmod +x tech.sh
./tech.sh
echo ""
if [ "LANGUAGE" ]; then
echo "Обновление завершено!"
else
echo "Update completed!"
fi
echo ""
EOF

chmod +x /tmp/update.sh
/tmp/update.sh
rm -f /tmp/update.sh
