#!/usr/bin/env bash
# build.sh — build a minimal Linux stage3 tarball for any distro + arch
#
# Usage:
#   sudo ./build.sh --distro debian  --release trixie    --arch amd64
#   sudo ./build.sh --distro alpine  --release 3.21      --arch arm64
#   sudo ./build.sh --distro arch    --release rolling   --arch riscv64
#
# Output: {distro}_stage3_{release}_{arch}_{YYYYMMDD}.tar.gz
#
# Supported distros: debian ubuntu devuan arch fedora alpine void opensuse gentoo
# Supported arches:  amd64 arm64 armhf riscv64 ppc64el s390x loong64 i386
#
# Cross-arch builds use QEMU binfmt_misc (installed automatically on Debian/Ubuntu hosts).
# Native builds skip QEMU entirely.

set -euo pipefail

# ── defaults ──────────────────────────────────────────────────────────────────
DISTRO="${DISTRO:-debian}"
RELEASE="${RELEASE:-trixie}"
ARCH="${ARCH:-amd64}"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}"
JOBS="${JOBS:-$(nproc)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="${SCRIPT_DIR}/rootfs"

# ── argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --distro)   DISTRO="$2";      shift 2 ;;
    --release)  RELEASE="$2";     shift 2 ;;
    --arch)     ARCH="$2";        shift 2 ;;
    --output)   OUTPUT_DIR="$2";  shift 2 ;;
    --jobs)     JOBS="$2";        shift 2 ;;
    --rootfs)   ROOTFS="$2";      shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

export DISTRO RELEASE ARCH ROOTFS JOBS

# ── validation ────────────────────────────────────────────────────────────────
SUPPORTED_DISTROS=(debian ubuntu devuan arch fedora alpine void opensuse gentoo)
SUPPORTED_ARCHES=(amd64 arm64 armhf riscv64 ppc64el s390x loong64 i386)

_in_list() { local v="$1"; shift; for x in "$@"; do [[ "$x" == "$v" ]] && return 0; done; return 1; }

_in_list "$DISTRO" "${SUPPORTED_DISTROS[@]}" || {
  echo "Unsupported distro: ${DISTRO}. Supported: ${SUPPORTED_DISTROS[*]}" >&2; exit 1
}
_in_list "$ARCH" "${SUPPORTED_ARCHES[@]}" || {
  echo "Unsupported arch: ${ARCH}. Supported: ${SUPPORTED_ARCHES[*]}" >&2; exit 1
}
[[ $EUID -eq 0 ]] || { echo "Must run as root (sudo ./build.sh ...)" >&2; exit 1; }

# ── helpers ───────────────────────────────────────────────────────────────────
info() { echo "[stage3] $*"; }
die()  { echo "[stage3] ERROR: $*" >&2; exit 1; }

cleanup() {
  for mnt in proc sys dev/pts dev; do
    mountpoint -q "${ROOTFS}/${mnt}" 2>/dev/null && umount -l "${ROOTFS}/${mnt}" || true
  done
}
trap cleanup EXIT

# ── QEMU cross-arch setup ─────────────────────────────────────────────────────
# Map Debian arch names → uname -m values
declare -A ARCH_TO_UNAME=(
  [amd64]=x86_64   [arm64]=aarch64  [armhf]=armv7l
  [riscv64]=riscv64 [ppc64el]=ppc64le [s390x]=s390x
  [loong64]=loongarch64 [i386]=i686
)
TARGET_UNAME="${ARCH_TO_UNAME[$ARCH]:-$ARCH}"
HOST_UNAME="$(uname -m)"

# Map uname -m → QEMU binary suffix
declare -A UNAME_TO_QEMU=(
  [aarch64]=aarch64  [armv7l]=arm    [armv7h]=arm
  [riscv64]=riscv64  [ppc64le]=ppc64le [s390x]=s390x
  [loongarch64]=loongarch64 [i686]=i386
)
QEMU_SUFFIX="${UNAME_TO_QEMU[$TARGET_UNAME]:-}"

setup_qemu() {
  # Same arch or x86_64 host running i686 target — no QEMU needed
  if [[ "$TARGET_UNAME" == "$HOST_UNAME" ]] || \
     [[ "$HOST_UNAME" == "x86_64" && "$TARGET_UNAME" == "i686" ]]; then
    info "Native build — skipping QEMU"
    return 0
  fi

  [[ -n "$QEMU_SUFFIX" ]] || die "No QEMU mapping for target arch ${ARCH} (uname: ${TARGET_UNAME})"

  info "Cross-arch build: host=${HOST_UNAME} target=${ARCH} — setting up QEMU"

  if ! command -v "qemu-${QEMU_SUFFIX}-static" &>/dev/null; then
    if command -v apt-get &>/dev/null; then
      apt-get install -y --no-install-recommends qemu-user-static binfmt-support
    elif command -v dnf &>/dev/null; then
      dnf install -y qemu-user-static
    elif command -v pacman &>/dev/null; then
      pacman -S --noconfirm qemu-user-static
    else
      die "Cannot install qemu-user-static — install it manually"
    fi
  fi

  # Register binfmt handlers
  if command -v update-binfmts &>/dev/null; then
    update-binfmts --enable
  elif systemctl is-active systemd-binfmt &>/dev/null 2>&1; then
    systemctl restart systemd-binfmt
  fi

  info "QEMU binfmt registered for ${ARCH}"
}

inject_qemu() {
  [[ -n "$QEMU_SUFFIX" ]] || return 0
  [[ "$TARGET_UNAME" == "$HOST_UNAME" ]] && return 0
  [[ "$HOST_UNAME" == "x86_64" && "$TARGET_UNAME" == "i686" ]] && return 0

  local qemu_bin="/usr/bin/qemu-${QEMU_SUFFIX}-static"
  [[ -f "$qemu_bin" ]] || return 0
  mkdir -p "${ROOTFS}/usr/bin"
  cp "$qemu_bin" "${ROOTFS}/usr/bin/"
  info "Injected ${qemu_bin} into rootfs"
}

remove_qemu() {
  rm -f "${ROOTFS}/usr/bin/qemu-"*"-static"
}

# ── pseudo-fs mounts ──────────────────────────────────────────────────────────
mount_pseudo() {
  mkdir -p "${ROOTFS}"/{proc,sys,dev,dev/pts}
  mount -t proc  none          "${ROOTFS}/proc"
  mount --bind   /sys          "${ROOTFS}/sys"  && mount --make-slave "${ROOTFS}/sys"
  mount --bind   /dev          "${ROOTFS}/dev"  && mount --make-slave "${ROOTFS}/dev"
  mount --bind   /dev/pts      "${ROOTFS}/dev/pts" && mount --make-slave "${ROOTFS}/dev/pts"
}

# ── distro dispatch ───────────────────────────────────────────────────────────
load_distro() {
  local script="${SCRIPT_DIR}/distros/${DISTRO}.sh"
  [[ -f "$script" ]] || die "No bootstrap script for distro: ${DISTRO}"
  # shellcheck source=/dev/null
  source "$script"
}

# ── main ──────────────────────────────────────────────────────────────────────
info "Building ${DISTRO}/${RELEASE}/${ARCH} stage3"
info "  ROOTFS:     ${ROOTFS}"
info "  OUTPUT_DIR: ${OUTPUT_DIR}"
info "  JOBS:       ${JOBS}"

rm -rf "${ROOTFS}"
mkdir -p "${ROOTFS}" "${OUTPUT_DIR}"

load_distro
setup_qemu

# Bootstrap the rootfs
info "=== Bootstrap ==="
do_bootstrap

# Inject QEMU binary for cross-arch chroot operations
inject_qemu

# Inject resolv.conf
echo 'nameserver 1.1.1.1' > "${ROOTFS}/etc/resolv.conf"

# Mount pseudo-filesystems and install packages
info "=== Install packages ==="
mount_pseudo
chroot "${ROOTFS}" bash -c "$(declare -f install_stage3_packages _debian_kernel _ubuntu_kernel _devuan_kernel _alpine_arch _alpine_branch _alpine_kernel _void_arch _void_repo _void_kernel _suse_arch _suse_repo_url _fedora_arch _fedora_kernel _gentoo_arch _gentoo_subarch 2>/dev/null); install_stage3_packages"
cleanup

# Remove QEMU binary and resolv.conf from final tarball
remove_qemu
rm -f "${ROOTFS}/etc/resolv.conf"

# Package
info "=== Package ==="
local_date=$(date +"%Y%m%d")
tarball="${OUTPUT_DIR}/${DISTRO}_stage3_${RELEASE}_${ARCH}_${local_date}.tar.gz"
tar --numeric-owner -czf "${tarball}" -C "${ROOTFS}" .
sha256sum "${tarball}" > "${tarball}.sha256"

info "Done: ${tarball} ($(du -sh "${tarball}" | cut -f1))"
