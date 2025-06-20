#!/usr/bin/env bash

[ -w /tmp ] && USER_DIR="" || USER_DIR=$HOME

source $USER_DIR/etc/tech-scripts/source.sh

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

CHECK_MARK="✓"
CROSS_MARK="✗"
QUESTION_MARK="?"

if [ "$LANGUAGE" = "Русский" ]; then
  KERNEL_MODULES=(
    "1. Сетевые модули: netfilter ip_tables bridge 8021q macvlan vxlan ath9k iwlwifi wpa_supplicant ethdev macsec"
    "2. Файловые системы: ext4 btrfs xfs nfs"
    "3. Драйверы устройств: usbcore ahci sd_mod i2c spi pwm gpio hwmon"
    "4. Безопасность: selinux apparmor dm_crypt audit keyring"
    "5. Виртуализация: kvm vhost virtio virtio_net virtio_blk"
    "6. Контейнеризация: cgroups namespaces seccomp overlayfs aufs fuse configfs tmpfs devtmpfs udev sysfs cifs"
    "7. Аудио: snd_hda_intel snd_usb_audio snd_pcm snd_seq snd_seq"
    "8. Графика: amdgpu radeon fbdev drm i915 nouveau"
    "9. Системы хранения: scsi_mod nvme fiberchannel iscsi_tcp rdma md_mod dm_raid dm_mod autofs loop"
    "10. Системная шина: platform pci pci_hotplug acpi"
  )
else
  KERNEL_MODULES=(
    "1. Network modules: netfilter ip_tables bridge 8021q macvlan vxlan ath9k iwlwifi wpa_supplicant ethdev macsec"
    "2. Filesystems: ext4 btrfs xfs nfs"
    "3. Device drivers: usbcore ahci sd_mod i2c spi pwm gpio hwmon"
    "4. Security: selinux apparmor dm_crypt audit keyring"
    "5. Virtualization: kvm vhost virtio virtio_net virtio_blk"
    "6. Containerization: cgroups namespaces seccomp overlayfs aufs fuse configfs tmpfs devtmpfs udev sysfs cifs"
    "7. Audio: snd_hda_intel snd_usb_audio snd_pcm snd_seq snd_seq"
    "8. Graphics: amdgpu radeon fbdev drm i915 nouveau"
    "9. Storage systems: scsi_mod nvme fiberchannel iscsi_tcp rdma md_mod dm_raid dm_mod autofs loop"
    "10. System bus: platform pci pci_hotplug acpi"
  )
fi

check_module() {
  local mod=$1
  if command -v lsmod &>/dev/null && lsmod | grep -qw "^${mod}" &>/dev/null; then
    echo -e "  ${GREEN}${CHECK_MARK}${RESET} ${mod} ${KERNEL_MODULE_LOADED}"
    return
  fi
  if grep -qw "^${mod}" /proc/modules 2>/dev/null; then
    echo -e "  ${GREEN}${CHECK_MARK}${RESET} ${mod} ${KERNEL_MODULE_LOADED}"
    return
  fi
  if modinfo "$mod" &>/dev/null; then
    echo -e "  ${GREEN}${CHECK_MARK}${RESET} ${mod} ${KERNEL_MODULE_AVAILABLE}"
    return
  fi
  if [ -d "/lib/modules/$(uname -r)" ]; then
    if find /lib/modules/$(uname -r) -type f -name "${mod}.ko*" -print -quit | grep -q . &>/dev/null; then
      echo -e "  ${YELLOW}${QUESTION_MARK}${RESET} ${mod} ${KERNEL_MODULE_FILE_FOUND}"
      return
    fi
  fi
  if modprobe -n -v "$mod" &>/dev/null; then
    echo -e "  ${YELLOW}${QUESTION_MARK}${RESET} ${mod} ${KERNEL_MODULE_LOADABLE}"
    return
  fi
  if dmesg 2>/dev/null | grep -i "$mod" &>/dev/null; then
    echo -e "  ${YELLOW}${QUESTION_MARK}${RESET} ${mod} ${KERNEL_MODULE_MENTIONED}"
    return
  fi
  if [ -f "/etc/modules-load.d/${mod}.conf" ]; then
    echo -e "  ${YELLOW}${QUESTION_MARK}${RESET} ${mod} ${KERNEL_MODULE_SCHEDULED}"
    return
  fi
  echo -e "  ${RED}${CROSS_MARK}${RESET} ${mod} ${KERNEL_MODULE_NOT_AVAILABLE}"
}

echo ""
echo -e "${KERNEL_CHECK_MODULES}\n"

for category in "${KERNEL_MODULES[@]}"; do
  cat_name=$(echo "$category" | cut -d':' -f1)
  mods=$(echo "$category" | cut -d':' -f2)
  echo -e "\e[1m${cat_name}:\e[0m"
  for mod in $mods; do
    check_module "$mod"
  done
  echo ""
done
