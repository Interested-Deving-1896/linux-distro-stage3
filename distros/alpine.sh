#!/usr/bin/env bash
# distros/alpine.sh — Alpine Linux bootstrap via apk-static
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

ALPINE_MIRROR="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"

# Debian arch → Alpine arch
_alpine_arch() {
  case "${ARCH}" in
    amd64)   echo "x86_64" ;;
    arm64)   echo "aarch64" ;;
    armhf)   echo "armhf" ;;
    riscv64) echo "riscv64" ;;
    ppc64el) echo "ppc64le" ;;
    s390x)   echo "s390x" ;;
    loong64) echo "loongarch64" ;;
    i386)    echo "x86" ;;
    *)       echo "${ARCH}" ;;
  esac
}

# Normalise release: "3.20" → "v3.20", "edge" → "edge"
_alpine_branch() {
  case "${RELEASE}" in
    edge) echo "edge" ;;
    v*)   echo "${RELEASE}" ;;
    *)    echo "v${RELEASE}" ;;
  esac
}

# Alpine arch → kernel package name
_alpine_kernel() {
  case "${ARCH}" in
    amd64|i386) echo "linux-lts" ;;
    arm64)      echo "linux-lts" ;;
    armhf)      echo "linux-rpi" ;;
    riscv64)    echo "linux-lts" ;;
    ppc64el)    echo "linux-lts" ;;
    s390x)      echo "linux-lts" ;;
    loong64)    echo "linux-lts" ;;
    *)          echo "linux-lts" ;;
  esac
}

do_bootstrap() {
  info "Bootstrapping Alpine $(_alpine_branch)/${ARCH} via apk-static"
  local alpine_arch branch
  alpine_arch="$(_alpine_arch)"
  branch="$(_alpine_branch)"

  local repo_url="${ALPINE_MIRROR}/${branch}/main/${alpine_arch}"
  local apk_pkg
  apk_pkg=$(curl -sL "${repo_url}/" \
    | grep -oP 'apk-tools-static-[^"]+\.apk' | sort -V | tail -1)
  [[ -n "${apk_pkg}" ]] || die "Cannot find apk-tools-static for ${alpine_arch}"

  curl -sL "${repo_url}/${apk_pkg}" -o /tmp/apk-tools-static.apk
  tar -xzf /tmp/apk-tools-static.apk -C /tmp sbin/apk.static
  rm -f /tmp/apk-tools-static.apk

  mkdir -p "${ROOTFS}/etc/apk"
  printf '%s\n' \
    "${ALPINE_MIRROR}/${branch}/main" \
    "${ALPINE_MIRROR}/${branch}/community" \
    > "${ROOTFS}/etc/apk/repositories"

  /tmp/sbin/apk.static \
    -X "${ALPINE_MIRROR}/${branch}/main" \
    -U --allow-untrusted \
    --root "${ROOTFS}" \
    --arch "${alpine_arch}" \
    --initdb \
    add alpine-base

  rm -f /tmp/sbin/apk.static
}

install_stage3_packages() {
  apk update
  apk add --no-cache \
    gcc g++ binutils make cmake samurai \
    autoconf automake libtool pkgconf \
    bison flex patch \
    python3 py3-pip py3-setuptools \
    go \
    git curl wget \
    ca-certificates sudo \
    util-linux xz zstd \
    dosfstools \
    "$(_alpine_kernel)" linux-headers \
    mkinitfs \
    squashfs-tools xorriso syslinux mtools
}
