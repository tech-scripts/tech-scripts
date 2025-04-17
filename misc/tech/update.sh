#!/bin/bash

cat << 'EOF' > /tmp/update.sh
#!/bin/bash

rm -rf /tmp/tech-scripts
git clone --depth 1 https://github.com/tech-scripts/linux.git /tmp/tech-scripts
rm -rf /usr/local/bin/tech
cd "/tmp/tech-scripts/misc/tech"
chmod +x tech.sh
./tech.sh
echo ""
echo "Обновление завершено!"
echo ""
EOF

chmod +x /tmp/update.sh
/tmp/update.sh
rm -f /tmp/update.sh
