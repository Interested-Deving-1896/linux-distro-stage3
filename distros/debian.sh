#!/usr/bin/env bash
# distros/debian.sh — Debian bootstrap
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

# Arch → kernel image package
_debian_kernel() {
  case "${ARCH}" in
    amd64)   echo "linux-image-amd64" ;;
    arm64)   echo "linux-image-arm64" ;;
    armhf)   echo "linux-image-armmp-lpae" ;;
    riscv64) echo "linux-image-riscv64" ;;
    ppc64el) echo "linux-image-powerpc64le" ;;
    s390x)   echo "linux-image-s390x" ;;
    loong64) echo "linux-image-loong64" ;;
    i386)    echo "linux-image-686-pae" ;;
    *)       echo "linux-image-${ARCH}" ;;
  esac
}

do_bootstrap() {
  info "Bootstrapping Debian ${RELEASE}/${ARCH} via debootstrap"
  apt-get install -y --no-install-recommends debootstrap 2>/dev/null || true

  debootstrap \
    --arch="${ARCH}" \
    --variant=minbase \
    --include=ca-certificates \
    "${RELEASE}" \
    "${ROOTFS}" \
    "${DEBIAN_MIRROR}"
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
    util-linux xz-utils zstd dosfstools

  # Kernel image — required for bootable naked ISOs
  local kpkg
  kpkg="$(_debian_kernel)"
  apt-get install -y --no-install-recommends "${kpkg}" 2>/dev/null || true

  # initramfs + live-boot for ISO assembly
  apt-get install -y --no-install-recommends \
    initramfs-tools live-boot live-boot-initramfs-tools \
    squashfs-tools xorriso isolinux syslinux-common mtools 2>/dev/null || true

  apt-get clean
  rm -rf /var/lib/apt/lists/*
}
