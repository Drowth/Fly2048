"""Bump the ## Interface lines in Fly2048's TOC files to the live game builds.

Blizzard publishes every product's live version on its public patch service,
for example 12.1.5.65000 for Retail. The TOC Interface number is that version
packed as major*10000 + minor*100 + patch, so 12.1.5 becomes 120105.

Each fetched build replaces the existing number with the same major version
that is closest to it (so Classic Era 1.15 and WoW Forever 1.60 stay apart),
or is added when nothing matches. A product that cannot be fetched leaves its
number alone, so a network failure never strips a flavour from a TOC.

Usage: python tools/update_interface.py [--check]
  --check  exit 1 if any TOC is out of date, without writing.
"""

from __future__ import annotations

import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCH_URL = "https://us.version.battle.net/v2/products/{product}/versions"
PREFERRED_REGIONS = ("us", "eu", "kr", "tw", "cn")

# TOC file -> Blizzard product codes whose live builds it should load on.
TARGETS = {
    "Fly2048/Fly2048_Mainline.toc": ["wow", "wowf"],
    "Fly2048/Fly2048_Forever.toc": ["wowf"],
    "Fly2048/Fly2048.toc": [
        "wow_classic",        # current progression Classic
        "wow_classic_titan",  # Titan-Reforged Classic
        "wow_anniversary",    # Classic Anniversary realms
        "wow_classic_era",    # Classic Era / Hardcore
        "wowf",               # WoW Forever (1.60.x, Mainline API)
    ],
}

INTERFACE_RE = re.compile(r"^## Interface:\s*(.*?)\s*$", re.MULTILINE)


def version_to_interface(version: str) -> int:
    major, minor, patch = (int(p) for p in version.split(".")[:3])
    return major * 10000 + minor * 100 + patch


def parse_versions(text: str) -> str | None:
    """Return the VersionsName of the preferred region from a patch-service table."""
    header, rows = None, {}
    for line in text.splitlines():
        if not line or line.startswith("##"):
            continue
        cells = line.split("|")
        if header is None:
            header = [c.split("!")[0].lower() for c in cells]
            continue
        row = dict(zip(header, cells))
        if row.get("region") and row.get("versionsname"):
            rows[row["region"]] = row["versionsname"]
    for region in PREFERRED_REGIONS:
        if region in rows:
            return rows[region]
    return next(iter(rows.values()), None)


def fetch_interface(product: str) -> int | None:
    try:
        with urllib.request.urlopen(PATCH_URL.format(product=product), timeout=20) as resp:
            version = parse_versions(resp.read().decode("utf-8", "replace"))
    except Exception as exc:  # network errors, 404 for retired products
        print(f"  {product}: skipped ({exc})")
        return None
    if not version:
        print(f"  {product}: skipped (no version listed)")
        return None
    value = version_to_interface(version)
    print(f"  {product}: {version} -> {value}")
    return value


def merge(existing: list[int], fetched: list[int]) -> list[int]:
    result = list(existing)
    free = set(range(len(result)))
    for n in sorted(set(fetched)):
        same_major = [i for i in free if result[i] // 10000 == n // 10000]
        if same_major:
            i = min(same_major, key=lambda i: abs(result[i] - n))
            result[i] = n
            free.discard(i)
        else:
            result.append(n)
    return sorted(set(result), reverse=True)


def update_toc(text: str, fetched: list[int]) -> str:
    match = INTERFACE_RE.search(text)
    if not match:
        raise ValueError("no ## Interface line")
    existing = [int(n) for n in re.findall(r"\d+", match.group(1))]
    line = "## Interface: " + ", ".join(str(n) for n in merge(existing, fetched))
    return text[: match.start()] + line + text[match.end():]


def main(argv: list[str]) -> int:
    check = "--check" in argv
    stale = False
    for rel, products in TARGETS.items():
        path = ROOT / rel
        print(rel)
        fetched = [v for v in (fetch_interface(p) for p in products) if v]
        raw = path.read_bytes().decode("utf-8")
        new = update_toc(raw, fetched)
        if new != raw:
            stale = True
            print(f"  updated: {INTERFACE_RE.search(new).group(0)}")
            if not check:
                path.write_bytes(new.encode("utf-8"))
    if check and stale:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
