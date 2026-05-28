#!/usr/bin/env bash
# distros/gentoo.sh — Gentoo bootstrap via official stage3 tarball
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

GENTOO_MIRROR="${GENTOO_MIRROR:-https://distfiles.gentoo.org}"
GENTOO_PROFILE="${GENTOO_PROFILE:-openrc}"   # openrc | systemd | musl

# Debian arch → Gentoo arch path
_gentoo_arch() {
  case "${ARCH}" in
    amd64)   echo "amd64" ;;
    arm64)   echo "arm64" ;;
    armhf)   echo "arm" ;;
    riscv64) echo "riscv" ;;
    ppc64el) echo "ppc64" ;;
    s390x)   echo "s390" ;;
    loong64) echo "loong" ;;
    i386)    echo "x86" ;;
    *)       echo "${ARCH}" ;;
  esac
}

# Gentoo arch → stage3 subarch string used in tarball filenames
_gentoo_subarch() {
  case "${ARCH}" in
    amd64)   echo "amd64" ;;
    arm64)   echo "arm64" ;;
    armhf)   echo "armv7a" ;;
    riscv64) echo "rv64_lp64d" ;;
    ppc64el) echo "ppc64le" ;;
    s390x)   echo "s390x" ;;
    loong64) echo "loong64" ;;
    i386)    echo "x86" ;;
    *)       echo "${ARCH}" ;;
  esac
}

do_bootstrap() {
  info "Bootstrapping Gentoo (${GENTOO_PROFILE})/${ARCH} via official stage3 tarball"
  local gentoo_arch subarch
  gentoo_arch="$(_gentoo_arch)"
  subarch="$(_gentoo_subarch)"

  local autobuilds="${GENTOO_MIRROR}/releases/${gentoo_arch}/autobuilds"
  local latest_file

  case "${GENTOO_PROFILE}" in
    openrc)  latest_file="latest-stage3-${subarch}-openrc.txt" ;;
    systemd) latest_file="latest-stage3-${subarch}-systemd.txt" ;;
    musl)    latest_file="latest-stage3-${subarch}-musl.txt" ;;
    *)       latest_file="latest-stage3-${subarch}-openrc.txt" ;;
  esac

  local latest_txt tarball_path tarball_url tarball
  latest_txt=$(curl -sL "${autobuilds}/${latest_file}") || \
    die "Cannot fetch ${autobuilds}/${latest_file}"

  tarball_path=$(echo "${latest_txt}" | grep -v '^#' | grep '\.tar\.' | head -1 | awk '{print $1}')
  [[ -n "${tarball_path}" ]] || die "Cannot parse stage3 path from ${latest_file}"

  tarball_url="${autobuilds}/${tarball_path}"
  tarball="/tmp/gentoo-stage3.tar.xz"

  info "Fetching ${tarball_url}"
  curl -L "${tarball_url}" -o "${tarball}"

  info "Extracting Gentoo stage3..."
  tar xpf "${tarball}" \
    --xattrs-include='*.*' \
    --numeric-owner \
    -C "${ROOTFS}"
  rm -f "${tarball}"

  # Portage config
  mkdir -p "${ROOTFS}/etc/portage"
  echo "GENTOO_MIRRORS=\"${GENTOO_MIRROR}\"" >> "${ROOTFS}/etc/portage/make.conf"
  echo "MAKEOPTS=\"-j${JOBS}\"" >> "${ROOTFS}/etc/portage/make.conf"
}

install_stage3_packages() {
  emerge-webrsync

  emerge --noreplace --quiet \
    sys-devel/gcc sys-devel/binutils \
    dev-build/make dev-build/cmake dev-build/ninja \
    sys-devel/autoconf sys-devel/automake dev-build/libtool dev-util/pkgconf \
    sys-devel/bison sys-devel/flex sys-devel/patch \
    dev-lang/python dev-python/pip \
    dev-lang/go \
    dev-vcs/git net-misc/curl net-misc/wget \
    app-misc/ca-certificates app-admin/sudo \
    sys-apps/util-linux app-arch/xz-utils app-arch/zstd \
    sys-fs/dosfstools \
    sys-kernel/gentoo-kernel-bin sys-kernel/linux-headers \
    sys-kernel/dracut \
    sys-fs/squashfs-tools dev-libs/libisoburn sys-boot/syslinux sys-fs/mtools

  emerge --depclean --quiet
}
