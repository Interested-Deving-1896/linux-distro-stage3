#!/usr/bin/env bash
# distros/ubuntu.sh — Ubuntu bootstrap
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

# amd64/i386 use main archive; everything else uses ports
case "${ARCH}" in
  amd64|i386) UBUNTU_MIRROR="${UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu}" ;;
  *)          UBUNTU_MIRROR="${UBUNTU_MIRROR:-http://ports.ubuntu.com/ubuntu-ports}" ;;
esac

_ubuntu_kernel() {
  case "${ARCH}" in
    amd64)   echo "linux-image-generic" ;;
    arm64)   echo "linux-image-generic" ;;
    armhf)   echo "linux-image-generic-lpae" ;;
    riscv64) echo "linux-image-generic" ;;
    ppc64el) echo "linux-image-generic" ;;
    s390x)   echo "linux-image-generic" ;;
    i386)    echo "linux-image-generic" ;;
    *)       echo "linux-image-generic" ;;
  esac
}

do_bootstrap() {
  info "Bootstrapping Ubuntu ${RELEASE}/${ARCH} via debootstrap"
  apt-get install -y --no-install-recommends debootstrap 2>/dev/null || true

  debootstrap \
    --arch="${ARCH}" \
    --variant=minbase \
    --include=ca-certificates \
    "${RELEASE}" \
    "${ROOTFS}" \
    "${UBUNTU_MIRROR}"
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

  local kpkg
  kpkg="$(_ubuntu_kernel)"
  apt-get install -y --no-install-recommends "${kpkg}" 2>/dev/null || true

  apt-get install -y --no-install-recommends \
    initramfs-tools casper \
    squashfs-tools xorriso isolinux syslinux-common mtools 2>/dev/null || true

  apt-get clean
  rm -rf /var/lib/apt/lists/*
}
