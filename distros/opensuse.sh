#!/usr/bin/env bash
# distros/opensuse.sh — openSUSE bootstrap via zypper --root
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

OPENSUSE_MIRROR="${OPENSUSE_MIRROR:-https://download.opensuse.org}"

# Debian arch → openSUSE arch
_suse_arch() {
  case "${ARCH}" in
    amd64)   echo "x86_64" ;;
    arm64)   echo "aarch64" ;;
    armhf)   echo "armv7hl" ;;
    ppc64el) echo "ppc64le" ;;
    s390x)   echo "s390x" ;;
    i386)    echo "i586" ;;
    *)       echo "${ARCH}" ;;
  esac
}

_suse_repo_url() {
  case "${RELEASE}" in
    tumbleweed|tw) echo "${OPENSUSE_MIRROR}/tumbleweed/repo/oss" ;;
    *)             echo "${OPENSUSE_MIRROR}/distribution/leap/${RELEASE}/repo/oss" ;;
  esac
}

do_bootstrap() {
  info "Bootstrapping openSUSE ${RELEASE}/${ARCH} via zypper --root"

  if ! command -v zypper &>/dev/null; then
    apt-get install -y --no-install-recommends zypper 2>/dev/null || \
      die "zypper not available — install it or run on an openSUSE host"
  fi

  local repo_url
  repo_url="$(_suse_repo_url)"

  zypper --root "${ROOTFS}" --non-interactive \
    addrepo --no-gpgcheck "${repo_url}" oss

  zypper --root "${ROOTFS}" --non-interactive \
    install -y --no-recommends \
    patterns-base-base bash coreutils glibc
}

install_stage3_packages() {
  zypper --non-interactive install -y --no-recommends \
    gcc gcc-c++ binutils make cmake ninja \
    autoconf automake libtool pkg-config \
    bison flex patch \
    python3 python3-pip python3-setuptools \
    go \
    git curl wget \
    ca-certificates sudo \
    util-linux xz zstd \
    dosfstools \
    kernel-default kernel-default-devel \
    dracut \
    squashfs xorriso syslinux mtools
  zypper clean --all
}
