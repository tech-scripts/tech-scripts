#!/bin/bash

cat << 'EOF' > /tmp/update.sh
#!/bin/bash

cd /tmp
rm -rf /tmp/tech-scripts
git clone --depth 1 https://github.com/tech-scripts/linux.git /tmp/tech-scripts
rm -rf /usr/local/bin/tech
cd "/tmp/tech-scripts/misc/tech"
chmod +x tech.sh
./tech.sh
echo ""
if [ "grep -E '^lang:' /etc/tech-scripts/choose.conf | cut -d' ' -f2" = "Русский" ]; then
echo "Обновление завершено!"
else
echo "Update completed!"
fi
echo ""
EOF

chmod +x /tmp/update.sh
/tmp/update.sh
rm -f /tmp/update.sh
