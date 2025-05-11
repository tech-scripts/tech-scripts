#!/bin/bash

GREEN="\\e[32m"
RED="\\e[31m"
YELLOW="\\e[33m"
RESET="\\e[0m"

CHECK_MARK="✓"
CROSS_MARK="✗"
QUESTION_MARK="?"

categories=(
  "1. Сетевые модули: netfilter ip_tables bridge 8021q macvlan vxlan"
  "2. Файловые системы: ext4 btrfs xfs nfs fuse zfs"
  "3. Драйверы устройств: usbcore ahci nouveau radeon sd_mod"
  "4. Безопасность: selinux dm_crypt audit seccomp keyring"
  "5. Виртуализация: kvm vhost virtio virtio_net virtio_blk"
  "6. Поддержка оборудования: i2c spi pwm gpio hwmon"
  "7. Общие модули: configfs tmpfs devtmpfs udev sysfs"
  "8. Аудио: snd_hda_intel snd_usb_audio snd_pcm snd_seq"
  "9. Графика: fbdev drm i915 amdgpu"
  "10. Поддержка RAID: md_mod dm_raid raid1 raid5 raid6"
  "11. Подключение к сети: ath9k iwlwifi wpa_supplicant ethdev macsec"
  "12. Поддержка Bluetooth: bluetooth btusb btrtl btqca btintel"
  "13. Контейнеризация и изоляция: cgroups namespaces seccomp overlayfs apparmor aufs fuse"
  "14. Системы хранения и протоколы: scsi_mod nvme fiberchannel iscsi_tcp rdma"
  "15. Системная шина: pci pci_hotplug platform acpi"
  "16. Другие важные модули: dm_mod loop autofs"
)

check_module() {
  local mod=$1

  if command -v lsmod &>/dev/null && lsmod | grep -qw "^${mod}" &>/dev/null; then
    echo -e "  ${GREEN}${CHECK_MARK}${RESET} ${mod} (загружен)"
    return
  fi

  if grep -qw "^${mod}" /proc/modules 2>/dev/null; then
    echo -e "  ${GREEN}${CHECK_MARK}${RESET} ${mod} (загружен)"
    return
  fi

  if modinfo "$mod" &>/dev/null; then
    echo -e "  ${GREEN}${CHECK_MARK}${RESET} ${mod} (доступен, но не загружен)"
    return
  fi

  if [ -d "/lib/modules/$(uname -r)" ]; then
    if find /lib/modules/$(uname -r) -type f -name "${mod}.ko*" -print -quit | grep -q . &>/dev/null; then
      echo -e "  ${YELLOW}${QUESTION_MARK}${RESET} ${mod} (файл модуля найден, но modinfo не подтвердил)"
      return
    fi
  fi

  if modprobe -n -v "$mod" &>/dev/null; then
    echo -e "  ${YELLOW}${QUESTION_MARK}${RESET} ${mod} (модуль можно загрузить)"
    return
  fi

  if dmesg 2>/dev/null | grep -i "$mod" &>/dev/null; then
    echo -e "  \${YELLOW}\${QUESTION_MARK}\${RESET} \${mod} (модуль упоминался в dmesg)"
    return
  fi

  if [ -f "/etc/modules-load.d/${mod}.conf" ]; then
    echo -e "  ${YELLOW}${QUESTION_MARK}${RESET} ${mod} (запланирован для загрузки при старте)"
    return
  fi

  echo -e "  ${RED}${CROSS_MARK}${RESET} ${mod} (не доступен)"
}

echo ""
echo -e "Проверка модулей ядра и их статуса:\n"

for category in "${categories[@]}"; do
  cat_name=$(echo "$category" | cut -d':' -f1)
  mods=$(echo "$category" | cut -d':' -f2)

  echo -e "\e[1m${cat_name}:\e[0m"
  for mod in $mods; do
    check_module "$mod"
  done
  echo
done
