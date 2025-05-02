#!/bin/bash

# Цветовые коды для вывода
GREEN="\\e[32m"
RED="\\e[31m"
RESET="\\e[0m"

# Символы для статуса
CHECK_MARK="✓"
CROSS_MARK="✗"

# Массив модулей для проверки (пример из списка пользователя)
modules=(
  # Сетевые модули
  netfilter ip_tables bridge 8021q macvlan vxlan
  # Файловые системы
  ext4 btrfs xfs nfs fuse overlayfs
  # Драйверы устройств
  usbcore ahci nouveau radeon sd_mod virtio_blk
  # Безопасность
  selinux apparmor dm_crypt audit seccomp keyring
  # Управление памятью
  zswap hugetlbfs swap transparent_hugepage memcg
  # Энергетическая эффективность
  cpufreq cpuidle suspend intel_pstate
  # Виртуализация
  kvm vhost virtio virtio_net virtio_blk
  # Мониторинг и диагностика
  ftrace perf debugfs kprobes tracepoints
  # Поддержка оборудования
  i2c spi pwm gpio hwmon
  # Общие модули
  configfs tmpfs devtmpfs udev sysfs
  # Аудио
  snd_hda_intel snd_usb_audio snd_pcm snd_seq
  # Графика
  fbdev drm i915 radeon
  # Поддержка RAID
  md_mod dm_raid raid1 raid5 raid6
  # Подключение к сети
  ath9k iwlwifi wpa_supplicant ethdev macsec
  # Поддержка Bluetooth
  bluetooth btusb btrtl btqca btintel
  # Поддержка контейнеров и изоляции
  cgroup namespaces seccomp overlayfs apparmor
  # Системы хранения и протоколы
  scsi_mod nvme fiberchannel iscsi_tcp rdma
  # Системная шина
  pci pci_hotplug platform usbcore acpi
  # Управление системными вызовами и журналами
  syscalls syslog journald klogd auditd
  # Временные и системные часы
  rtc timekeeping ntp hpet
  # Другие важные модули
  dm_mod loop autofs seccomp
)

# Функция проверки модуля
check_module() {
  local mod=$1

  # Проверка, загружен ли модуль
  if lsmod | grep -qw "^${mod}"; then
    echo -e "${GREEN}${CHECK_MARK} ${mod}${RESET} (загружен)"
    return
  fi

  # Проверка, присутствует ли модуль в системе (наличие ko-файла)
  if find /lib/modules/$(uname -r) -type f -name "${mod}.ko*" -print -quit | grep -q .; then
    echo -e "${GREEN}${CHECK_MARK} ${mod}${RESET} (доступен, но не загружен)"
  else
    echo -e "${RED}${CROSS_MARK} ${mod}${RESET} (не доступен)"
  fi
}

echo "Проверка модулей ядра и их статуса:"
echo "-------------------------------"

for module in "${modules[@]}"; do
    check_module "$module"
done
