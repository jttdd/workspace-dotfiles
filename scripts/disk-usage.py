#!/usr/bin/env python3
"""Disk utilization analysis — shows where space is being used.

Usage: disk-usage.py [DIR] [DEPTH]
  DIR    directory to analyze (default: $HOME)
  DEPTH  how many levels to auto-expand large dirs (default: 3)
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

DU_TIMEOUT = 600


def human_size(kb: int) -> str:
    size = float(kb)
    for unit in ("K", "M", "G", "T"):
        if abs(size) < 1024:
            return f"{size:.1f}{unit}"
        size /= 1024
    return f"{size:.1f}P"


def du(path: str, max_depth: int = 1) -> list[tuple[int, str]]:
    """Run du and return [(size_kb, path)] sorted descending by size."""
    try:
        result = subprocess.run(
            ["du", "-k", "--max-depth", str(max_depth), path],
            capture_output=True, text=True, timeout=DU_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        print(f"  (timed out scanning {path})", file=sys.stderr)
        return []
    except FileNotFoundError:
        return []

    entries = []
    for line in result.stdout.strip().splitlines():
        parts = line.split("\t", 1)
        if len(parts) == 2:
            try:
                entries.append((int(parts[0]), parts[1]))
            except ValueError:
                continue
    entries.sort(key=lambda x: x[0], reverse=True)
    return entries


def bar(fraction: float, width: int = 30) -> str:
    filled = int(fraction * width)
    return f"[{'#' * filled}{'.' * (width - filled)}]"


def header(title: str):
    print(f"\n\033[1m{title}\033[0m")
    print("-" * 60)


def row(size_kb: int, label: str, total_kb: int = 0, indent: int = 0):
    prefix = "  " * indent
    pct = f"({size_kb * 100 // total_kb:3d}%)" if total_kb > 0 else ""
    print(f"  {prefix}{human_size(size_kb):>7s} {pct:>6s}  {label}")


def filesystem_summary():
    header("Filesystem")
    usage = shutil.disk_usage("/")
    used_pct = usage.used / usage.total
    print(f"  Total: {human_size(usage.total // 1024)}  "
          f"Used: {human_size(usage.used // 1024)}  "
          f"Free: {human_size(usage.free // 1024)}")
    print(f"  {bar(used_pct)} {used_pct:.0%}")


def show_level(path: str, total_kb: int, depth: int,
               max_entries: int = 15, min_expand_kb: int = 0,
               indent: int = 0):
    """Show one level of du output, recursing into large children."""
    entries = du(path, max_depth=1)
    if not entries:
        return

    children = [(s, p) for s, p in entries if p != path][:max_entries]
    for size_kb, child in children:
        name = os.path.basename(child) or child
        row(size_kb, name, total_kb=total_kb, indent=indent)
        if depth > 0 and size_kb >= min_expand_kb:
            show_level(child, total_kb, depth=depth - 1,
                       max_entries=5, min_expand_kb=min_expand_kb,
                       indent=indent + 1)


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else str(Path.home())
    max_depth = int(sys.argv[2]) if len(sys.argv) > 2 else 3

    filesystem_summary()

    # Single scan at depth 1 to get top-level sizes
    header(f"Scanning: {target}")
    entries = du(target, max_depth=1)
    if not entries:
        print("  (empty or inaccessible)")
        return

    total_kb = entries[0][0]
    children = [(s, p) for s, p in entries if p != target][:15]

    # Auto-expand threshold: >2% of total or >1G, whichever is larger
    min_expand = max(total_kb // 50, 1_048_576)

    for size_kb, path in children:
        name = os.path.basename(path) or path
        row(size_kb, name, total_kb=total_kb)
        if max_depth > 0 and size_kb >= min_expand:
            show_level(path, total_kb, depth=max_depth - 1,
                       max_entries=5, min_expand_kb=min_expand,
                       indent=1)


if __name__ == "__main__":
    main()
