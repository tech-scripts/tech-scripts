#!/bin/bash

set -e

log() {
    echo ">>> $1"
}

error_exit() {
    echo "Ошибка: $1"
    exit 1
}

log "Установка необходимых пакетов..."
pkg install -y git build-essential golang make libseccomp libseccomp-static || error_exit "Не удалось установить необходимые пакеты."

log "Клонирование репозитория Termux..."
cd ~
[ ! -d termux-packages ] && git clone https://github.com/termux/termux-packages.git || error_exit "Не удалось клонировать репозиторий."
cd termux-packages

log "Создание скрипта сборки libc++..."
cat > packages/libc++/build.sh << 'EOF'
TERMUX_PKG_HOMEPAGE=https://libcxx.llvm.org/
TERMUX_PKG_DESCRIPTION="C++ Standard Library"
TERMUX_PKG_LICENSE=NCSA
TERMUX_PKG_MAINTAINER=@termux
TERMUX_PKG_VERSION=27b
TERMUX_PKG_SRCURL=https://dl.google.com/android/repository/android-ndk-r27b-linux.zip
TERMUX_PKG_SHA256=33e16af1a6bbabe12cad54b2117085c07eab7e4fa67cdd831805f0e94fd826c1
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_make_install() {
    mkdir -p $TERMUX_PREFIX/lib
    cp ./toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
        $TERMUX_PREFIX/lib/
}
EOF

log "Сборка libc++..."
./build-package.sh packages/libc++ || error_exit "Не удалось собрать libc++."

log "Создание скрипта сборки runc..."
cat > root-packages/runc/build.sh << 'EOF'
TERMUX_PKG_HOMEPAGE=https://www.opencontainers.org/
TERMUX_PKG_DESCRIPTION="A tool for spawning and running containers according to the OCI specification"
TERMUX_PKG_LICENSE=Apache-2.0
TERMUX_PKG_MAINTAINER=@termux
TERMUX_PKG_VERSION=1.1.15
TERMUX_PKG_SRCURL=https://github.com/opencontainers/runc/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=8446718a107f3e437bc33a4c9b89b94cb24ae58ed0a49d08cd83ac7d39980860
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_DEPENDS="libseccomp"
TERMUX_PKG_BUILD_DEPENDS="libseccomp-static"

termux_step_make() {
    export GOPATH=$HOME/go
    export CGO_ENABLED=1
    export CGO_LDFLAGS="-L$TERMUX_PREFIX/lib -lseccomp"
    export CGO_CFLAGS="-I$TERMUX_PREFIX/include"
    
    make BUILDTAGS="seccomp" \
        EXTRA_FLAGS="-buildmode=pie" \
        EXTRA_LDFLAGS="" \
        EXTRA_CFLAGS=""
}

termux_step_make_install() {
    install -Dm755 runc $TERMUX_PREFIX/bin/runc
}
EOF

log "Сборка runc..."
rm -rf /data/data/com.termux/files/home/.termux-build/runc
./build-package.sh root-packages/runc || error_exit "Не удалось собрать runc."

log "Настройка блокировки версии..."
mkdir -p $PREFIX/etc/apt/preferences.d
cat > $PREFIX/etc/apt/preferences.d/runc << 'EOF'
Package: runc
Pin: version 1.1.15
Pin-Priority: 1001

Package: runc
Pin: version *
Pin-Priority: -1
EOF

log "Проверка установки..."
if [ -f "$PREFIX/bin/runc" ]; then
    echo "Установка успешна!"
    echo "Версия runc:"
    runc --version
else
    error_exit "Установка runc не удалась!"
fi

log "Обновление списка пакетов..."
apt update || error_exit "Не удалось обновить список пакетов."

log "Проверка политики runc..."
apt policy runc || error_exit "Не удалось проверить политику runc."

log "Установка Docker..."
pkg install docker || error_exit "Не удалось установить Docker."

log "Настройка конфигурации Docker..."
mkdir -p $PREFIX/etc/docker
cat > $PREFIX/etc/docker/daemon.json << 'EOF'
{
    "data-root": "/data/docker/lib/docker",
    "exec-root": "/data/docker/run/docker",
    "pidfile": "/data/docker/run/docker.pid",
    "hosts": [
        "unix:///data/docker/run/docker.sock"
    ],
    "storage-driver": "overlay2"
}
EOF

log "Создание скрипта для запуска Docker daemon..."
cat > $PREFIX/bin/dockerd << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

export PATH="${PATH}:/system/xbin:/system/bin"
opts='rw,nosuid,nodev,noexec,relatime'
cgroups='blkio cpu cpuacct cpuset devices freezer memory pids schedtune'

# Попытка смонтировать корневой каталог cgroup
if ! mountpoint -q /sys/fs/cgroup 2>/dev/null; then
  mkdir -p /sys/fs/cgroup
  mount -t tmpfs -o "${opts}" cgroup_root /sys/fs/cgroup || exit
fi

# Запуск Docker daemon
$PREFIX/bin/dockerd-dev $@
EOF

chmod +x $PREFIX/bin/dockerd || error_exit "Не удалось сделать скрипт dockerd исполняемым."

log "Запуск Docker daemon..."
sudo dockerd --iptables=false &>/dev/null & || error_exit "Не удалось запустить Docker daemon."

log "Docker установлен и запущен. Проверка работы Docker..."
sudo docker run hello-world || error_exit "Не удалось запустить тестовый контейнер hello-world."

log "Установка завершена успешно! Вы можете использовать Docker на вашем Android устройстве."
