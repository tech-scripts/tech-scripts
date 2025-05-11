#!/bin/bash

GREEN="\\e[32m"
RED="\\e[31m"
YELLOW="\\e[33m"
RESET="\\e[0m"

CHECK_MARK="✓"
CROSS_MARK="✗"
QUESTION_MARK="?"

categories=(
  "1. Сетевые модули и подключение к сети: netfilter ip_tables bridge 8021q macvlan vxlan ath9k iwlwifi wpa_supplicant ethdev macsec"
  "2. Файловые системы: ext4 btrfs xfs nfs fuse zfs"
  "3. Драйверы устройств и поддержка оборудования: usbcore ahci sd_mod i2c spi pwm gpio hwmon"
  "4. Безопасность: selinux dm_crypt audit keyring"
  "5. Виртуализация: kvm vhost virtio virtio_net virtio_blk"
  "6. Контейнеризация: cgroups namespaces seccomp overlayfs apparmor aufs fuse configfs tmpfs devtmpfs udev sysfs"
  "7. Аудио: snd_hda_intel snd_usb_audio snd_pcm snd_seq snd_seq"
  "8. Графика: amdgpu radeon fbdev drm i915 nouveau"
  "9. Системы хранения, протоколы и поддержка RAID: scsi_mod nvme fiberchannel iscsi_tcp rdma md_mod dm_raid dm_mod autofs loop"
  "10. Системная шина: platform pci pci_hotplug acpi"
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
