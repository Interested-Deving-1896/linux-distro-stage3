#!/usr/bin/env bash
# distros/void.sh — Void Linux bootstrap via xbps-static
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

VOID_MIRROR="${VOID_MIRROR:-https://repo-default.voidlinux.org}"
VOID_LIBC="${VOID_LIBC:-glibc}"   # or musl

# Debian arch → Void arch
_void_arch() {
  case "${ARCH}" in
    amd64)   echo "x86_64" ;;
    arm64)   echo "aarch64" ;;
    armhf)   echo "armv7l" ;;
    ppc64el) echo "ppc64le" ;;
    i386)    echo "i686" ;;
    *)       echo "${ARCH}" ;;
  esac
}

_void_repo() {
  local void_arch="$1"
  if [[ "${VOID_LIBC}" == "musl" ]]; then
    echo "${VOID_MIRROR}/current/musl"
  else
    echo "${VOID_MIRROR}/current"
  fi
}

_void_kernel() {
  # Void uses linux-base meta-package; arch-specific kernels are pulled in
  echo "linux"
}

do_bootstrap() {
  info "Bootstrapping Void Linux (${VOID_LIBC})/${ARCH} via xbps-static"
  local void_arch repo
  void_arch="$(_void_arch)"
  repo="$(_void_repo "${void_arch}")"

  # Fetch xbps-static tarball
  local static_url="${VOID_MIRROR}/static"
  local xbps_tarball
  xbps_tarball=$(curl -sL "${static_url}/" \
    | grep -oP "xbps-static-[^\"]+\\.${void_arch}\\.tar\\.xz" | sort -V | tail -1)
  [[ -n "${xbps_tarball}" ]] || die "Cannot find xbps-static for ${void_arch}"

  curl -sL "${static_url}/${xbps_tarball}" -o /tmp/xbps-static.tar.xz
  tar -xJf /tmp/xbps-static.tar.xz -C /tmp
  rm -f /tmp/xbps-static.tar.xz

  local xbps_install
  xbps_install=$(find /tmp -name "xbps-install.static" 2>/dev/null | head -1)
  [[ -n "${xbps_install}" ]] || die "xbps-install.static not found after extraction"

  mkdir -p "${ROOTFS}/var/db/xbps/keys"

  "${xbps_install}" \
    -r "${ROOTFS}" \
    -R "${repo}" \
    --arch "${void_arch}" \
    -S \
    base-system

  rm -f "${xbps_install}"
}

install_stage3_packages() {
  xbps-install -Syu
  xbps-install -y \
    gcc binutils make cmake ninja \
    autoconf automake libtool pkg-config \
    bison flex patch \
    python3 python3-pip python3-setuptools \
    go \
    git curl wget \
    ca-certificates sudo \
    util-linux xz zstd \
    dosfstools \
    linux linux-headers \
    dracut \
    squashfs-tools libisoburn syslinux mtools
  xbps-remove -Oo
}
