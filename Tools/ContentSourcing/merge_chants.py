#!/usr/bin/env python3
"""Append the verified chant candidates to Tools/Chants/chants.json.

    python3 merge_chants.py            # merge
    python3 merge_chants.py --dry-run  # show what would be added

Only entries chant_candidates.json marks `verified` (fetch.py read the
chant's page and Verbum Gloriae's licence page) are taken; the rest are
listed and left out. Idempotent: an id or group already in chants.json is
skipped. chants.json keeps its own layout — one entry per line, the chants
grouped by shelf with a blank line between shelves — so each new chant is
inserted as a line after the last chant of its shelf, and a new shelf's
group after the last group, its chants at the end. Nothing else in the
file is touched. Run Tools/Chants/generate.py afterwards.
"""

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CHANTS_JSON = HERE.parent / "Chants" / "chants.json"


def line(obj: dict) -> str:
    return "    " + json.dumps(obj, ensure_ascii=False)


def main(dry: bool) -> int:
    cand = json.loads((HERE / "chant_candidates.json").read_text("utf-8"))
    text = CHANTS_JSON.read_text("utf-8")
    current = json.loads(text)
    have_ids = {c["id"] for c in current["chants"]}
    have_groups = {g["id"] for g in current["groups"]}

    take, left = [], []
    for c in cand["chants"]:
        if c["id"] in have_ids:
            continue
        status = cand["status"].get(c["id"])
        if status != "verified" or "TODO" in json.dumps(c):
            left.append(f"{c['id']} ({status})")
        else:
            take.append(c)
    groups = [g for g in cand["groups"] if g["id"] not in have_groups and any(c["group"] == g["id"] for c in take)]
    for c in take:
        if c["group"] not in have_groups and c["group"] not in {g["id"] for g in groups}:
            sys.exit(f"{c['id']}: unknown group {c['group']}")

    lines = text.split("\n")

    def last_index(pred):
        idx = [i for i, l in enumerate(lines) if pred(l.strip())]
        return idx[-1] if idx else None

    def insert_after(i: int, new: str):
        # A line without a trailing comma is its array's last element: the
        # new line takes that place, and the old one gains the comma
        if lines[i].rstrip().endswith(","):
            lines.insert(i + 1, new + ",")
        else:
            lines[i] = lines[i].rstrip() + ","
            lines.insert(i + 1, new)

    for g in groups:
        i = last_index(lambda l: l.startswith('{"id"') and '"title"' in l and '"slug"' not in l)
        insert_after(i, line(g))
    for c in take:
        i = last_index(lambda l, gid=c["group"]: l.startswith('{"id"') and f'"group": "{gid}"' in l)
        if i is None:  # a new shelf: after the last chant, set off by a blank line
            i = last_index(lambda l: l.startswith('{"id"') and '"slug"' in l)
            lines[i] = lines[i].rstrip().rstrip(",") + ","
            lines.insert(i + 1, "")
            lines.insert(i + 2, line(c))
            continue
        insert_after(i, line(c))

    new_text = "\n".join(lines)
    merged = json.loads(new_text)  # must still parse, with every id once
    ids = [c["id"] for c in merged["chants"]]
    assert len(ids) == len(set(ids)), "duplicate ids after merge"

    for c in take:
        print(f"+ {c['id']} ({c['group']})")
    for g in groups:
        print(f"+ group {g['id']}")
    for l in left:
        print(f"  left out, not verified: {l}")
    if not take:
        print("Nothing new to merge.")
    if not dry and take:
        CHANTS_JSON.write_text(new_text, "utf-8")
        print(f"Wrote {CHANTS_JSON}. Next: cd Tools/Chants && python3 generate.py")
    return 0


if __name__ == "__main__":
    sys.exit(main("--dry-run" in sys.argv[1:]))
