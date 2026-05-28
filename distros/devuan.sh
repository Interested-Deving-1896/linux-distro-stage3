#!/usr/bin/env bash
# distros/devuan.sh — Devuan bootstrap (systemd-free Debian fork)
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

DEVUAN_MIRROR="${DEVUAN_MIRROR:-http://deb.devuan.org/merged}"

_devuan_kernel() {
  case "${ARCH}" in
    amd64)   echo "linux-image-amd64" ;;
    arm64)   echo "linux-image-arm64" ;;
    armhf)   echo "linux-image-armmp-lpae" ;;
    riscv64) echo "linux-image-riscv64" ;;
    ppc64el) echo "linux-image-powerpc64le" ;;
    i386)    echo "linux-image-686-pae" ;;
    *)       echo "linux-image-${ARCH}" ;;
  esac
}

do_bootstrap() {
  info "Bootstrapping Devuan ${RELEASE}/${ARCH} via debootstrap"
  apt-get install -y --no-install-recommends debootstrap 2>/dev/null || true

  # Fetch Devuan keyring so debootstrap can verify signatures
  local keyring_url="${DEVUAN_MIRROR}/pool/main/d/devuan-keyring"
  local keyring_deb
  keyring_deb=$(curl -sL "${keyring_url}/" \
    | grep -oP 'devuan-keyring_[^"]+\.deb' | sort -V | tail -1)
  if [[ -n "${keyring_deb}" ]]; then
    curl -sL "${keyring_url}/${keyring_deb}" -o /tmp/devuan-keyring.deb
    dpkg -i /tmp/devuan-keyring.deb 2>/dev/null || true
    rm -f /tmp/devuan-keyring.deb
  fi

  debootstrap \
    --arch="${ARCH}" \
    --variant=minbase \
    --include=ca-certificates \
    "${RELEASE}" \
    "${ROOTFS}" \
    "${DEVUAN_MIRROR}"
}

install_stage3_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq

  apt-get install -y --no-install-recommends \
    build-essential gcc g++ binutils make cmake ninja-build \
    autoconf automake libtool pkg-config \
    bison flex patch \
    python3 python3-pip python3-setuptools \
    golang-go \
    git curl wget \
    ca-certificates sudo \
    util-linux xz-utils zstd dosfstools \
    sysvinit-core

  local kpkg
  kpkg="$(_devuan_kernel)"
  apt-get install -y --no-install-recommends "${kpkg}" 2>/dev/null || true

  apt-get install -y --no-install-recommends \
    initramfs-tools live-boot live-boot-initramfs-tools \
    squashfs-tools xorriso isolinux syslinux-common mtools 2>/dev/null || true

  apt-get clean
  rm -rf /var/lib/apt/lists/*
}
