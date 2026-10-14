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

A document that does not hold together (an id twice, a chapter or group
naming what the document lacks, a chant with no file) is refused.
"""
import json
import pathlib
import subprocess
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
SEED = ROOT / "app" / "Resources" / "Library"
NAMES = {"prayer_book": ("prayer-book", "version,updated_at,prayers,chapters"),
         "chant_library": ("chant-library", "version,updated_at,groups,chants")}


def api_checkout() -> pathlib.Path:
    """priv/library of the API repository beside this one (a worktree's
    common checkout counts)."""
    common = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--path-format=absolute", "--git-common-dir"],
                            capture_output=True, text=True).stdout.strip()
    for base in [ROOT.parent, pathlib.Path(common).parent.parent if common else None]:
        if base and (base / "api" / "priv" / "library").is_dir():
            return base / "api" / "priv" / "library"
    sys.exit("no API checkout beside this one: pass --from <api>/priv/library")


def problem(name: str, doc: dict):
    if name == "prayer_book":
        ids = [p["id"] for p in doc.get("prayers", [])]
        if not ids or len(ids) != len(set(ids)):
            return "no prayers, or a prayer id twice"
        for c in doc.get("chapters", []):
            named = c["prayer_ids"] + [i for s in c.get("sections", []) for i in s["prayer_ids"]]
            missing = [i for i in named if i not in set(ids)]
            if missing:
                return f"{c['id']} names {missing[0]}"
        return None if doc.get("chapters") else "no chapters"
    ids = [c["id"] for c in doc.get("chants", [])]
    if not ids or len(ids) != len(set(ids)):
        return "no chants, or a chant id twice"
    for g in doc.get("groups", []):
        for p in g["parts"]:
            missing = [i for i in p["chant_ids"] if i not in set(ids)]
            if missing:
                return f"{g['id']} names {missing[0]}"
    for c in doc["chants"]:
        if not c["audio"].get("url") or any(not s.get("url") for s in c["score"]):
            return f"{c['id']} has a file with no URL"
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
    if "--live" in args:
        i = args.index("--live")
        base = args[i + 1] if i + 1 < len(args) and not args[i + 1].startswith("--") else "https://lumenviae.fly.dev/api"
        docs = {name: live(base.rstrip("/"), name) for name in NAMES}
    else:
        source = pathlib.Path(args[args.index("--from") + 1]) if "--from" in args else api_checkout()
        docs = {name: json.loads((source / f"{name}.json").read_text("utf-8")) for name in NAMES}

    stale = []
    for name, doc in docs.items():
        bad = problem(name, doc)
        if bad:
            sys.exit(f"{name}: {bad}; nothing copied")
        dest = SEED / f"{name}.json"
        current = json.loads(dest.read_text("utf-8")) if dest.exists() else None
        if current != doc:
            stale.append(name)
        if "--check" not in args:
            dest.write_text(json.dumps(doc, ensure_ascii=False, indent=2, sort_keys=True) + "\n", "utf-8")
            print(f"{name}: {'updated' if name in stale else 'unchanged'} ({dest.relative_to(ROOT)})")
    if "--check" in args:
        if stale:
            sys.exit(f"the app's copy differs from the server's: {', '.join(stale)} (Tools/dev library-seed)")
        print("the app's copies match the server's")


if __name__ == "__main__":
    main()
