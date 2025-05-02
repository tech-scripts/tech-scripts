#!/bin/bash

# Цветовые коды для вывода
GREEN="\\e[32m"
RED="\\e[31m"
RESET="\\e[0m"

# Символы для статуса
CHECK_MARK="✓"
CROSS_MARK="✗"

# Определение ассоциативного массива, где ключ - категория, значение - строка с модулями
declare -A categories=(
  ["1. Сетевые модули"]="netfilter ip_tables bridge 8021q macvlan vxlan"
  ["2. Файловые системы"]="ext4 btrfs xfs nfs fuse overlayfs"
  ["3. Драйверы устройств"]="usbcore ahci nouveau radeon sd_mod virtio_blk"
  ["4. Безопасность"]="selinux apparmor dm_crypt audit seccomp keyring"
  ["5. Управление памятью"]="zswap hugetlbfs swap transparent_hugepage memcg"
  ["6. Энергетическая эффективность"]="cpufreq cpuidle suspend intel_pstate"
  ["7. Виртуализация"]="kvm vhost virtio virtio_net virtio_blk"
  ["8. Мониторинг и диагностика"]="ftrace perf debugfs kprobes tracepoints"
  ["9. Поддержка оборудования"]="i2c spi pwm gpio hwmon"
  ["10. Общие модули"]="configfs tmpfs devtmpfs udev sysfs"
  ["11. Аудио"]="snd_hda_intel snd_usb_audio snd_pcm snd_seq"
  ["12. Графика"]="fbdev drm i915 radeon"
  ["13. Поддержка RAID"]="md_mod dm_raid raid1 raid5 raid6"
  ["14. Подключение к сети"]="ath9k iwlwifi wpa_supplicant ethdev macsec"
  ["15. Поддержка Bluetooth"]="bluetooth btusb btrtl btqca btintel"
  ["16. Поддержка контейнеров и изоляции"]="cgroup namespaces seccomp overlayfs apparmor"
  ["17. Системы хранения и протоколы"]="scsi_mod nvme fiberchannel iscsi_tcp rdma"
  ["18. Системная шина"]="pci pci_hotplug platform usbcore acpi"
  ["19. Управление системными вызовами и журналами"]="syscalls syslog journald klogd auditd"
  ["20. Временные и системные часы"]="rtc timekeeping ntp hpet"
  ["21. Другие важные модули"]="dm_mod loop autofs seccomp"
)

check_module() {
  local mod=$1

  if lsmod | grep -qw "^${mod}"; then
    echo -e "  ${GREEN}${CHECK_MARK}${RESET} ${mod} (загружен)"
    return
  fi

  if find /lib/modules/$(uname -r) -type f -name "${mod}.ko*" -print -quit | grep -q .; then
    echo -e "  ${GREEN}${CHECK_MARK}${RESET} ${mod} (доступен, но не загружен)"
  else
    echo -e "  ${RED}${CROSS_MARK}${RESET} ${mod} (не доступен)"
  fi
}

echo -e "Проверка модулей ядра и их статуса:\n"

for category in "${!categories[@]}"; do
  echo -e "\e[1m${category}:\e[0m"
  mods=${categories[$category]}
  for mod in $mods; do
    check_module "$mod"
  done
  echo
done
