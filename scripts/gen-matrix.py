#!/usr/bin/env python3
"""gen-matrix.py — generate GitHub Actions build matrix from config/matrix.yml

Usage:
  python3 scripts/gen-matrix.py [--distro DISTRO] [--arch ARCH]
                                 [--release RELEASE] [--tier 1|2|3]

Outputs JSON: {"include": [{distro, release, arch, tier}, ...]}
"""
import argparse
import json
import re
import sys
from pathlib import Path


def load_matrix_yaml(path: Path) -> dict:
    """Minimal YAML parser — handles the specific structure of config/matrix.yml."""
    text = path.read_text()

    # Try PyYAML first
    try:
        import yaml  # type: ignore
        return yaml.safe_load(text)
    except ImportError:
        pass

    # Fallback: hand-parse the matrix.yml structure
    # This is intentionally narrow — only handles what matrix.yml actually contains.
    result: dict = {"distros": {}}
    current_distro: str | None = None
    current_arch: str | None = None
    in_arches = False
    in_releases = False

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        stripped = line.lstrip()

        # Skip comments and blank lines
        if not stripped or stripped.startswith("#"):
            continue

        indent = len(line) - len(stripped)

        # Top-level distro key (indent=2, ends with colon)
        if indent == 2 and stripped.endswith(":") and not stripped.startswith("-"):
            current_distro = stripped[:-1]
            result["distros"][current_distro] = {
                "releases": [], "default_release": "", "arches": {}
            }
            in_arches = False
            in_releases = False
            current_arch = None
            continue

        if current_distro is None:
            continue

        d = result["distros"][current_distro]

        # releases: list
        if indent == 4 and stripped == "releases:":
            in_releases = True
            in_arches = False
            continue

        if in_releases and indent == 6 and stripped.startswith("- "):
            d["releases"].append(stripped[2:].strip('"'))
            continue

        # default_release:
        if indent == 4 and stripped.startswith("default_release:"):
            val = stripped.split(":", 1)[1].strip().strip('"')
            d["default_release"] = val
            in_releases = False
            continue

        # arches:
        if indent == 4 and stripped == "arches:":
            in_arches = True
            in_releases = False
            continue

        if not in_arches:
            continue

        # arch key (indent=6)
        if indent == 6 and stripped.endswith(":") and not stripped.startswith("-"):
            current_arch = stripped[:-1]
            d["arches"][current_arch] = {"tier": 1}
            continue

        # tier: N (indent=8)
        if indent == 8 and current_arch and stripped.startswith("tier:"):
            tier_val = stripped.split(":", 1)[1].strip()
            try:
                d["arches"][current_arch]["tier"] = int(tier_val)
            except ValueError:
                pass
            continue

    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--distro",  default="")
    parser.add_argument("--arch",    default="")
    parser.add_argument("--release", default="")
    parser.add_argument("--tier",    type=int, default=1)
    args = parser.parse_args()

    matrix_path = Path(__file__).parent.parent / "config" / "matrix.yml"
    config = load_matrix_yaml(matrix_path)

    includes = []

    for distro_name, distro_cfg in config["distros"].items():
        if args.distro and distro_name != args.distro:
            continue

        all_releases: list = distro_cfg["releases"]
        default_release: str = str(distro_cfg["default_release"])

        # Which releases to build
        if args.release:
            if args.release not in [str(r) for r in all_releases]:
                continue
            releases = [args.release]
        elif args.tier == 1:
            # Tier-1 runs: default release only
            releases = [default_release]
        else:
            releases = [str(r) for r in all_releases]

        for arch, arch_cfg in distro_cfg["arches"].items():
            if args.arch and arch != args.arch:
                continue

            tier = int(arch_cfg.get("tier", 1))
            if tier > args.tier:
                continue

            for release in releases:
                includes.append({
                    "distro":  distro_name,
                    "release": str(release),
                    "arch":    arch,
                    "tier":    tier,
                })

    print(json.dumps({"include": includes}))


if __name__ == "__main__":
    main()
