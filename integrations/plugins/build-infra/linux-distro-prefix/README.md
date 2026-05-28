# linux-distro-prefix integration

This plugin documents how [linux-distro-prefix](https://github.com/Interested-Deving-1896/linux-distro-prefix)
consumes stage3 tarballs produced by linux-distro-stage3.

## Relationship

```
linux-distro-stage3  -->  linux-distro-prefix  -->  penguins-eggs-prefix
  (stage3 tarballs)         (prefix tarballs)          (prefix + ISO tools)
```

linux-distro-prefix fetches stage3 tarballs from this repo's GitHub releases
to use as the bootstrap chroot base. The stage3 is not included in the output
prefix tarball — only the Gentoo prefix contents are packaged.

## CI schedule alignment

| Repo | Schedule | Rationale |
|------|----------|-----------|
| linux-distro-stage3 | Monthly, 1st | Produces stage3 tarballs |
| linux-distro-prefix | Monthly, 2nd | Consumes stage3, produces prefix tarballs |
| penguins-eggs-prefix | Monthly, 3rd | Consumes prefix tarballs, produces penguins-eggs prefix |

## Triggering a downstream prefix build

After a new linux-distro-stage3 release, trigger linux-distro-prefix manually:

1. Go to **linux-distro-prefix → Actions → Build linux-distro-prefix → Run workflow**
2. Leave distro/arch blank to build all tier-1 combinations
3. The workflow fetches the latest stage3 release automatically

## Pointing linux-distro-prefix at a specific stage3

Set `STAGE3_REPO` in the linux-distro-prefix workflow environment, or pass
`--stage3 /path/to/tarball.tar.gz` to `build.sh` locally.
