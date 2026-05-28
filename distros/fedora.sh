#!/usr/bin/env bash
# distros/fedora.sh — Fedora bootstrap via dnf --installroot
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

# Debian arch → RPM arch
_fedora_arch() {
  case "${ARCH}" in
    amd64)   echo "x86_64" ;;
    arm64)   echo "aarch64" ;;
    armhf)   echo "armhfp" ;;
    ppc64el) echo "ppc64le" ;;
    s390x)   echo "s390x" ;;
    i386)    echo "i686" ;;
    *)       echo "${ARCH}" ;;
  esac
}

_fedora_kernel() {
  # All Fedora arches use the same package name
  echo "kernel"
}

do_bootstrap() {
  info "Bootstrapping Fedora ${RELEASE}/${ARCH} via dnf --installroot"
  local rpm_arch
  rpm_arch="$(_fedora_arch)"

  if ! command -v dnf &>/dev/null; then
    apt-get install -y --no-install-recommends dnf 2>/dev/null || \
      die "dnf not available — install it or run on a Fedora/RHEL host"
  fi

  dnf \
    --installroot="${ROOTFS}" \
    --releasever="${RELEASE}" \
    --forcearch="${rpm_arch}" \
    install -y \
    fedora-release bash coreutils glibc-minimal-langpack

  dnf \
    --installroot="${ROOTFS}" \
    --releasever="${RELEASE}" \
    --forcearch="${rpm_arch}" \
    makecache
}

install_stage3_packages() {
  dnf install -y \
    gcc gcc-c++ binutils make cmake ninja-build \
    autoconf automake libtool pkgconf \
    bison flex patch \
    python3 python3-pip python3-setuptools \
    golang \
    git curl wget \
    ca-certificates sudo \
    util-linux xz zstd \
    dosfstools \
    kernel kernel-devel kernel-headers \
    dracut \
    squashfs-tools xorriso syslinux mtools
  dnf clean all
}
