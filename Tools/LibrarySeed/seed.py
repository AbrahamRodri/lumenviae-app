#!/usr/bin/env python3
"""Copies the server's two library documents into the app as its seed.

The server keeps the Prayer Book's words and the chant library
(the API's priv/library/prayer_book.json and chant_library.json, served as
GET /api/v2/prayer-book and /api/v2/chant-library). The app ships a copy
of each (app/Resources/Library/), which it reads until the server gives
it a newer one. Run this after the server's documents change, so a new
install starts from them.

Usage (through Tools/dev library-seed):
    seed.py                  # from the API checkout beside this one
    seed.py --from DIR       # from DIR/prayer_book.json and DIR/chant_library.json
    seed.py --live [BASE]    # from the live API (default https://lumenviae.fly.dev/api),
                             # which also gives each its version
    seed.py --check          # exit 1 if the API checkout's files differ from the app's

Each copy is the server's file byte for byte with one line added, its
"version", the fingerprint the server serves (LumenViae.Rosary.Content
.version: SHA-256 of the sections as compact JSON with sorted keys, its
first 16 hex digits), so a phone with the shipped copy never fetches the
same document again. --check adds that line to the server's file and
compares the result with the app's copy.

A document the app would refuse is refused here too, with the app's own
checks (LibraryContent.swift, `problem`): an id twice, a chapter or group
naming what the document lacks, a chapter the app names missing, a prayer
with no words, a chant in no known group, or a file that is not an https
URL with a 64-digit lowercase hex SHA-256.
"""
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
SEED = ROOT / "app" / "Resources" / "Library"
NAMES = {"prayer_book": ("prayer-book", "version,updated_at,prayers,chapters"),
         "chant_library": ("chant-library", "version,updated_at,groups,chants")}
SECTIONS = {"prayer_book": ["prayers", "chapters"], "chant_library": ["groups", "chants"]}


def version(name: str, doc: dict) -> str:
    """The server's fingerprint of a document's sections."""
    sections = {key: doc[key] for key in SECTIONS[name]}
    text = json.dumps(sections, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def with_version(name: str, raw: bytes, doc: dict) -> bytes:
    """The server's file with its version on the line after the brace."""
    assert raw.startswith(b"{\n"), f"{name}: expected the file to open on its own line"
    line = f'  "version": "{version(name, doc)}",\n'.encode("utf-8")
    return b"{\n" + line + raw[2:]


def api_checkout() -> pathlib.Path:
    """priv/library of the API repository beside this one (a worktree's
    common checkout counts), or LUMEN_VIAE_API_DIR's."""
    if os.environ.get("LUMEN_VIAE_API_DIR"):
        return pathlib.Path(os.environ["LUMEN_VIAE_API_DIR"]) / "priv" / "library"
    common = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--path-format=absolute", "--git-common-dir"],
                            capture_output=True, text=True).stdout.strip()
    for base in [ROOT.parent, pathlib.Path(common).parent.parent if common else None]:
        if base and (base / "api" / "priv" / "library").is_dir():
            return base / "api" / "priv" / "library"
    sys.exit("no API checkout beside this one: pass --from <api>/priv/library")


# The chapters the app names by id (PrayerBookDocument.namedChapterIDs)
NAMED_CHAPTERS = {
    "first", "day", "short", "mass", "penance", "sacrament", "holy_ghost", "our_lord", "our_lady",
    "st_joseph", "saints", "seasons", "thanks", "litanies", "church", "sick", "departed", "needs",
}
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def https(url) -> bool:
    parts = urllib.parse.urlparse(url or "")
    return parts.scheme == "https" and bool(parts.netloc)


def is_file(asset: dict) -> bool:
    return https(asset.get("url")) and bool(HEX64.match(asset.get("sha256") or ""))


def problem(name: str, doc: dict):
    """The app's own checks (LibraryContent.swift), so no seed is made that
    the app would refuse."""
    if name == "prayer_book":
        prayers, chapters = doc.get("prayers") or [], doc.get("chapters") or []
        if not prayers or not chapters:
            return "empty"
        ids = {p["id"] for p in prayers}
        if len(ids) != len(prayers):
            return "a prayer id twice"
        chapter_ids = {c["id"] for c in chapters}
        if len(chapter_ids) != len(chapters):
            return "a chapter id twice"
        missing = sorted(NAMED_CHAPTERS - chapter_ids)
        if missing:
            return f"no chapter {missing[0]}, which the app names"
        for c in chapters:
            named = c["prayer_ids"] + [i for s in c.get("sections") or [] for i in s["prayer_ids"]]
            lacking = [i for i in named if i not in ids]
            if lacking:
                return f"{c['id']} names {lacking[0]}, which the book lacks"
        empty = [p["id"] for p in prayers if not p.get("english")]
        return f"{empty[0]} has no words" if empty else None

    chants, groups = doc.get("chants") or [], doc.get("groups") or []
    if not chants or not groups:
        return "empty"
    ids = {c["id"] for c in chants}
    if len(ids) != len(chants):
        return "a chant id twice"
    group_ids = {g["id"] for g in groups}
    if len(group_ids) != len(groups):
        return "a group id twice"
    for g in groups:
        lacking = [i for p in g["parts"] for i in p["chant_ids"] if i not in ids]
        if lacking:
            return f"{g['id']} names {lacking[0]}, which the library lacks"
    for c in chants:
        if c["group_id"] not in group_ids:
            return f"{c['id']} is in no known group"
        if not is_file(c["audio"]):
            return f"{c['id']} has no recording"
        if any(not is_file(s) for s in c["score"]):
            return f"{c['id']} has a score page with no file"
        if not https(c.get("source_url")):
            return f"{c['id']} has no source page"
    return None


def live(base: str, name: str) -> dict:
    path, fields = NAMES[name]
    url = f"{base}/v2/{path}?fields%5B{name}%5D={fields}"
    request = urllib.request.Request(url, headers={"Accept": "application/vnd.api+json"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)["data"]["attributes"]


def main():
    args = sys.argv[1:]
    docs = {}
    raw = {}
    if "--live" in args:
        i = args.index("--live")
        base = args[i + 1] if i + 1 < len(args) and not args[i + 1].startswith("--") else "https://lumenviae.fly.dev/api"
        docs = {name: live(base.rstrip("/"), name) for name in NAMES}
    else:
        source = pathlib.Path(args[args.index("--from") + 1]) if "--from" in args else api_checkout()
        # Copied byte for byte, so the app's copy is the server's file
        raw = {name: (source / f"{name}.json").read_bytes() for name in NAMES}
        docs = {name: json.loads(data) for name, data in raw.items()}
        raw = {name: with_version(name, data, docs[name]) for name, data in raw.items()}

    stale = []
    for name, doc in docs.items():
        bad = problem(name, doc)
        if bad:
            sys.exit(f"{name}: {bad}; nothing copied")
        dest = SEED / f"{name}.json"
        data = raw.get(name) or (json.dumps(doc, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()
        if not dest.exists() or dest.read_bytes() != data:
            stale.append(name)
        if "--check" not in args:
            dest.write_bytes(data)
            print(f"{name}: {'updated' if name in stale else 'unchanged'} ({dest.relative_to(ROOT)})")
    if "--check" in args:
        if stale:
            sys.exit(f"the app's copy differs from the server's: {', '.join(stale)} (Tools/dev library-seed)")
        print("the app's copies match the server's")


if __name__ == "__main__":
    main()
