[update-readmes]   Mode: rewrite — migrating to template structure...
# linux-distro-stage3

[![Built with Ona](https://ona.com/build-with-ona.svg)](https://app.ona.com/#https://github.com/Interested-Deving-1896/linux-distro-stage3)

<!-- AI:start:what-it-does -->
_Description pending._
<!-- AI:end:what-it-does -->

## Architecture

<!-- AI:start:architecture -->
_Architecture documentation pending._
<!-- AI:end:architecture -->

## Install

<!-- Add installation instructions here. This section is yours — the AI will not modify it. -->

```bash
git clone https://github.com/Interested-Deving-1896/linux-distro-stage3.git
cd linux-distro-stage3
```

## Usage


```bash
# Build Debian trixie for amd64 (native)
sudo ./build.sh --distro debian --release trixie --arch amd64

# Build Alpine 3.21 for arm64 (cross via QEMU)
sudo ./build.sh --distro alpine --release 3.21 --arch arm64

# Build Devuan excalibur for riscv64
sudo ./build.sh --distro devuan --release excalibur --arch riscv64
```

Output: `{distro}_stage3_{release}_{arch}_{date}.tar.gz`

### Requirements

- Root access
- 10 GB free disk space per build
- `curl`, `git`, `xz-utils`, `zstd`
- For cross-arch: `qemu-user-static`, `binfmt-support`
- Distro-specific: `debootstrap` (Debian/Ubuntu/Devuan), `pacstrap` (Arch), `dnf` (Fedora), `apk` (Alpine), `xbps-install` (Void), `zypper` (openSUSE)

## Configuration

<!-- Document configuration options here. This section is yours — the AI will not modify it. -->

## CI

<!-- AI:start:ci -->
_CI documentation pending._
<!-- AI:end:ci -->

## Mirror chain

<!-- AI:start:mirror-chain -->
This repo is maintained in [`Interested-Deving-1896/linux-distro-stage3`](https://github.com/Interested-Deving-1896/linux-distro-stage3) and mirrored through:

```
Interested-Deving-1896/linux-distro-stage3  ──►  OpenOS-Project-OSP/linux-distro-stage3  ──►  OpenOS-Project-Ecosystem-OOC/linux-distro-stage3
```

Changes flow downstream automatically via the hourly mirror chain in
[`fork-sync-all`](https://github.com/Interested-Deving-1896/fork-sync-all).
Direct commits to OSP or OOC are detected and opened as PRs back to `Interested-Deving-1896`.
<!-- AI:end:mirror-chain -->

## Contributors

<!-- AI:start:contributors -->
_Contributors pending._
<!-- AI:end:contributors -->

## Origins

<!-- AI:start:origins -->
_Original project — no upstream fork._
<!-- AI:end:origins -->

## Resources

<!-- AI:start:resources -->
_No additional resource files found._
<!-- AI:end:resources -->

## License

<!-- AI:start:license -->
[GPL-3.0](https://github.com/Interested-Deving-1896/linux-distro-stage3/blob/main/LICENSE) © 2026 [Interested-Deving-1896](https://github.com/Interested-Deving-1896)
<!-- AI:end:license -->
