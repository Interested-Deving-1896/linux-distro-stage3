#!/usr/bin/env bash
# distros/arch.sh — Arch Linux bootstrap
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

ARCH_MIRROR="${ARCH_MIRROR:-https://geo.mirror.pkgbuild.com}"

# Debian arch → Arch Linux arch name
_arch_native() {
  case "${ARCH}" in
    amd64)   echo "x86_64" ;;
    arm64)   echo "aarch64" ;;
    armhf)   echo "armv7h" ;;
    riscv64) echo "riscv64" ;;
    ppc64el) echo "powerpc64le" ;;
    i386)    echo "i686" ;;
    *)       echo "${ARCH}" ;;
  esac
}

do_bootstrap() {
  info "Bootstrapping Arch Linux (rolling)/${ARCH} via bootstrap tarball"
  local arch_arch
  arch_arch="$(_arch_native)"

  local tarball_url="${ARCH_MIRROR}/iso/latest/archlinux-bootstrap-${arch_arch}.tar.zst"
  local tarball="/tmp/arch-bootstrap-${arch_arch}.tar.zst"

  info "Fetching ${tarball_url}"
  curl -L "${tarball_url}" -o "${tarball}"
  tar --zstd --strip-components=1 -xf "${tarball}" -C "${ROOTFS}"
  rm -f "${tarball}"

  # Mirrorlist
  echo "Server = ${ARCH_MIRROR}/\$repo/os/\$arch" > "${ROOTFS}/etc/pacman.d/mirrorlist"

  # Bootstrap pacman DB
  chroot "${ROOTFS}" bash -c "
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Syu --noconfirm
  "
}

install_stage3_packages() {
  pacman -Syu --noconfirm
  pacman -S --noconfirm --needed \
    base base-devel \
    gcc binutils make cmake ninja \
    autoconf automake libtool pkgconf \
    bison flex patch \
    python python-pip python-setuptools \
    go \
    git curl wget \
    ca-certificates sudo \
    util-linux xz zstd \
    dosfstools \
    linux linux-headers \
    mkinitcpio \
    squashfs-tools libisoburn syslinux mtools
  pacman -Scc --noconfirm
}
