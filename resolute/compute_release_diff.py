#!/usr/bin/env python3
"""
compute_release_diff.py

Download two snapshot tarballs from GitHub Releases and produce a human-readable
diff of apt, pip, and forest packages across all image variants (base/robot/rt).

Usage:
    python compute_release_diff.py <url_old> <url_new>
"""

import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

def parse_apt(text: str) -> dict[str, str]:
    """Parse 'package=version' lines into {package: version}."""
    result = {}
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        if "=" in line:
            pkg, _, ver = line.partition("=")
            result[pkg.strip()] = ver.strip()
    return result


def parse_pip(text: str) -> dict[str, str]:
    """Parse 'package==version' lines (pip freeze format) into {package: version}."""
    result = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "==" in line:
            pkg, _, ver = line.partition("==")
            result[pkg.strip().lower()] = ver.strip()
        elif " @ " in line:
            # editable / URL installs: keep as-is with empty version marker
            pkg = line.split(" @ ")[0].strip().lower()
            result[pkg] = line.split(" @ ", 1)[1].strip()
    return result


def parse_forest(text: str) -> dict[str, str]:
    """Parse 'package: commit_hash' lines into {package: hash}."""
    result = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "not found" in line.lower():
            continue
        if ":" in line:
            pkg, _, val = line.partition(":")
            result[pkg.strip()] = val.strip()
    return result


# ---------------------------------------------------------------------------
# Diff helpers
# ---------------------------------------------------------------------------

def diff_packages(
    old: dict[str, str],
    new: dict[str, str],
) -> tuple[dict, dict, dict]:
    """
    Return (added, removed, changed) dictionaries.
    added:   {pkg: new_version}
    removed: {pkg: old_version}
    changed: {pkg: (old_version, new_version)}
    """
    added = {p: v for p, v in new.items() if p not in old}
    removed = {p: v for p, v in old.items() if p not in new}
    changed = {
        p: (old[p], new[p])
        for p in old
        if p in new and old[p] != new[p]
    }
    return added, removed, changed


# ---------------------------------------------------------------------------
# Download / extract helpers
# ---------------------------------------------------------------------------

def download_and_extract(url_or_path: str, dest: Path) -> None:
    """Download a .tar.gz from *url_or_path* (HTTP URL or local path) and extract into *dest*."""
    local = Path(url_or_path)
    if local.exists():
        print(f"  Extracting local file {url_or_path} ...", flush=True)
        with tarfile.open(local, "r:gz") as tf:
            tf.extractall(dest)
        return

    print(f"  Downloading {url_or_path} ...", flush=True)
    with urllib.request.urlopen(url_or_path) as resp:
        data = resp.read()
    print(f"  Downloaded {len(data) // 1024} KiB, extracting...", flush=True)
    with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as tmp:
        tmp.write(data)
        tmp_path = Path(tmp.name)
    with tarfile.open(tmp_path, "r:gz") as tf:
        tf.extractall(dest)
    tmp_path.unlink()


def read_snapshot(root: Path) -> dict[str, dict[str, dict[str, str]]]:
    """
    Walk the extracted snapshot directory and return a nested dict:
        {variant: {manager: {package: version}}}
    where variant in {base, robot, rt} and manager in {apt, pip, forest}.
    """
    snapshot: dict[str, dict[str, dict[str, str]]] = {}
    for variant_dir in sorted(root.iterdir()):
        if not variant_dir.is_dir():
            continue
        variant = variant_dir.name
        snapshot[variant] = {}

        apt_file = variant_dir / "apt.txt"
        if apt_file.exists():
            snapshot[variant]["apt"] = parse_apt(apt_file.read_text())

        pip_file = variant_dir / "pip.txt"
        if pip_file.exists():
            snapshot[variant]["pip"] = parse_pip(pip_file.read_text())

        forest_file = variant_dir / "forest.lock"
        if forest_file.exists():
            snapshot[variant]["forest"] = parse_forest(forest_file.read_text())

    return snapshot


# ---------------------------------------------------------------------------
# Report formatting
# ---------------------------------------------------------------------------

def format_section(
    title: str,
    added: dict,
    removed: dict,
    changed: dict,
) -> list[str]:
    lines: list[str] = []
    if not added and not removed and not changed:
        lines.append(f"  {title}: no changes")
        return lines

    lines.append(f"  {title}:")

    if added:
        lines.append(f"    + Added ({len(added)}):")
        for pkg in sorted(added):
            lines.append(f"        {pkg}  →  {added[pkg]}")

    if removed:
        lines.append(f"    - Removed ({len(removed)}):")
        for pkg in sorted(removed):
            lines.append(f"        {pkg}  {removed[pkg]}")

    if changed:
        lines.append(f"    ~ Changed ({len(changed)}):")
        for pkg in sorted(changed):
            old_v, new_v = changed[pkg]
            lines.append(f"        {pkg}  {old_v}  →  {new_v}")

    return lines


def print_diff(
    old_snap: dict[str, dict[str, dict[str, str]]],
    new_snap: dict[str, dict[str, dict[str, str]]],
    old_label: str,
    new_label: str,
) -> None:
    managers = ["apt", "pip", "forest"]
    manager_parsers = {"apt": "APT packages", "pip": "Pip packages", "forest": "Forest packages"}
    variants = sorted(set(old_snap) | set(new_snap))

    print()
    print("=" * 72)
    print(f"  Snapshot diff")
    print(f"    OLD: {old_label}")
    print(f"    NEW: {new_label}")
    print("=" * 72)

    for variant in variants:
        print()
        print(f"┌─ Variant: {variant} " + "─" * max(0, 60 - len(variant)))

        old_v = old_snap.get(variant, {})
        new_v = new_snap.get(variant, {})

        any_change = False
        for mgr in managers:
            old_pkgs = old_v.get(mgr, {})
            new_pkgs = new_v.get(mgr, {})
            if not old_pkgs and not new_pkgs:
                continue
            added, removed, changed = diff_packages(old_pkgs, new_pkgs)
            section_lines = format_section(manager_parsers[mgr], added, removed, changed)
            for l in section_lines:
                print(l)
            if added or removed or changed:
                any_change = True

        if not any_change:
            print("  (no changes)")

    print()
    print("=" * 72)


# ---------------------------------------------------------------------------
# Summary statistics
# ---------------------------------------------------------------------------

def print_summary(
    old_snap: dict,
    new_snap: dict,
) -> None:
    print()
    print("Summary statistics:")
    variants = sorted(set(old_snap) | set(new_snap))
    for variant in variants:
        old_v = old_snap.get(variant, {})
        new_v = new_snap.get(variant, {})
        row_parts = []
        for mgr in ["apt", "pip", "forest"]:
            old_pkgs = old_v.get(mgr, {})
            new_pkgs = new_v.get(mgr, {})
            if not old_pkgs and not new_pkgs:
                continue
            added, removed, changed = diff_packages(old_pkgs, new_pkgs)
            row_parts.append(
                f"{mgr}: +{len(added)}/-{len(removed)}/~{len(changed)}"
            )
        print(f"  {variant:10s}  " + "   ".join(row_parts))
    print()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def label_from_url(url: str) -> str:
    return url.split("/")[-1].replace(".tar.gz", "")


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: compute_release_diff.py <url_old> <url_new>")
        sys.exit(1)

    url_old, url_new = sys.argv[1], sys.argv[2]
    old_label = label_from_url(url_old)
    new_label = label_from_url(url_new)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        old_dir = tmp_path / "old"
        new_dir = tmp_path / "new"
        old_dir.mkdir()
        new_dir.mkdir()

        print(f"Fetching OLD snapshot: {old_label}")
        download_and_extract(url_old, old_dir)

        print(f"Fetching NEW snapshot: {new_label}")
        download_and_extract(url_new, new_dir)

        # The tarball may place files inside a single top-level directory.
        # Detect and unwrap that if present.
        def unwrap(d: Path) -> Path:
            children = [c for c in d.iterdir()]
            if len(children) == 1 and children[0].is_dir():
                return children[0]
            return d

        old_root = unwrap(old_dir)
        new_root = unwrap(new_dir)

        print("Parsing snapshots...", flush=True)
        old_snap = read_snapshot(old_root)
        new_snap = read_snapshot(new_root)

    print_diff(old_snap, new_snap, old_label, new_label)
    print_summary(old_snap, new_snap)


if __name__ == "__main__":
    main()
