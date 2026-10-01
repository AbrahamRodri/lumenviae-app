#!/usr/bin/env python3
"""Render sources.py into manifest.json, MANIFEST.md and chant_candidates.json.

    python3 build_manifest.py

fetch.py writes what it learns (resolved file URLs, licences read off the
source page, sizes) to fetched.json; this script folds that in, so rerun it
after every fetch.
"""

import json
from pathlib import Path

import sources as S

HERE = Path(__file__).resolve().parent
BYTES_PER_SECOND = 59 * 1024 * 1024 / (4 * 3600)  # the bundle's mono HE-AAC 32 kbps, measured


def fetched() -> dict:
    p = HERE / "fetched.json"
    return json.loads(p.read_text()) if p.exists() else {}


def build():
    got = fetched()
    pictures = []
    for p in S.PAINTINGS:
        e = dict(kind="painting", status="candidate", file_url=None, commons_file=None,
                 width=None, height=None, bytes=None, **p)
        e.update(got.get(p["imageset"], {}))
        pictures.append(e)

    existing = []
    for name, work, creator, date, collection, confidence in S.EXISTING:
        e = dict(kind="painting", imageset=name, status="identified", identification_confidence=confidence,
                 work=work, creator=creator, date=date, collection=collection,
                 source_page=None, file_url=None, **S.PD_ART)
        if creator is None:
            e.update(licence="Probably public domain (old master), unconfirmed until the work is identified",
                     licence_url=None)
        e.update(got.get(name, {}))
        existing.append(e)
    carlo = dict(kind="photograph", **S.CARLO)

    chants = []
    for c in S.CHANTS:
        est = c["est_seconds"]
        chants.append(dict(kind="chant", id=c["entry"]["id"], tier=c["tier"], status="candidate",
                           source_page=c["source"], creator=S.VG["creator"], licence=S.VG["licence"],
                           licence_url=S.VG["licence_url"], attribution=S.VG["attribution"],
                           estimated_seconds=est, estimated_bytes=round(est * BYTES_PER_SECOND),
                           size_is_estimate=True, note=c.get("note"), **got.get(c["entry"]["id"], {})))

    manifest = {
        "_about": "Content sourced for Lumen Viae (branch claude/content-sourcing). Generated from sources.py by build_manifest.py; do not hand-edit.",
        "new_paintings": pictures,
        "existing_paintings": existing,
        "flagged": [carlo],
        "chants": chants,
        "chants_not_found": [dict(latin=a, tier=t, slot=s, finding=f) for a, t, s, f in S.NOT_FOUND],
        "fallback_sources": [dict(name=n, url=u, note=x) for n, u, x in S.FALLBACK_SOURCES],
    }
    (HERE / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")

    candidates = {
        "_about": "Proposed additions to Tools/Chants/chants.json, in its exact schema. Copy `groups` into its groups and `chants` into its chants, then run generate.py on a Mac. Entries whose audio/scores read TODO need the file names fetch.py --chants prints.",
        "groups": S.CHANT_GROUPS_TO_ADD,
        "chants": [c["entry"] for c in S.CHANTS],
    }
    (HERE / "chant_candidates.json").write_text(json.dumps(candidates, ensure_ascii=False, indent=2) + "\n")

    (HERE / "MANIFEST.md").write_text(markdown(manifest))


def cell(v):
    return "—" if v in (None, "") else str(v).replace("|", "\\|").replace("\n", " ")


def markdown(m) -> str:
    out = ["# Content sourcing manifest", "",
           "Generated from `sources.py` by `build_manifest.py`; edit there. Machine-readable: `manifest.json`.", "",
           "**Status this round:** the session's network policy refused every source host (verbumgloriae.es, "
           "commons.wikimedia.org, upload.wikimedia.org, the Met's, AIC's and other museum APIs), so nothing is downloaded "
           "and no licence page has been read. Every entry is `candidate` or `identified`. `fetch.py` resolves each "
           "against Commons, reads the licence there, writes the imagesets, and records what it found; then rerun "
           "`build_manifest.py`. Run it here once the hosts are allowed, or on the Mac.", "",
           "## New paintings", "",
           "| Imageset | Slot | Work | Creator | Date | Collection | Licence | Status |",
           "|---|---|---|---|---|---|---|---|"]
    for p in m["new_paintings"]:
        out.append("| `{}` | {} | {} | {} | {} | {} | {} | {} |".format(
            p["imageset"], cell(p["slot"]), cell(p["work"]), cell(p["creator"]), cell(p["date"]),
            cell(p["collection"]), cell(p["licence"]), p["status"]))
    out += ["", "Alternates and reasons:", ""]
    for p in m["new_paintings"]:
        out.append(f"- `{p['imageset']}`: {cell(p['why'])}" + (f" *Alternate:* {p['alternate']}." if p.get("alternate") else ""))
    out += ["", "Target format: 1600 px on the long edge, progressive JPEG, 300–800 KB; one 1x image per imageset like the existing ones.", "",
            "## Existing paintings: provenance", "",
            "Identified by eye from the bundled images. `high` = recognisable work; `medium` = likely; `low` = subject only. "
            "All are pre-1910 old masters, so PD-Art is expected; confirm each with `fetch.py --provenance`.", "",
            "| Imageset | Work | Creator | Date | Collection | Confidence |", "|---|---|---|---|---|---|"]
    for e in m["existing_paintings"]:
        out.append("| `{}` | {} | {} | {} | {} | {} |".format(e["imageset"], cell(e["work"]), cell(e["creator"]),
                                                          cell(e["date"]), cell(e["collection"]), e["identification_confidence"]))
    out += ["", "## Flagged", ""]
    for f in m["flagged"]:
        out += [f"- **`{f['imageset']}`**: {f['work']}. Creator: {f['creator']}. Licence: {f['licence']}.", "", f"  {f['note']}", ""]
    out += ["## Chant candidates (Verbum Gloriae)", "",
            f"Licence for all: {S.VG['licence']} — {S.VG['licence_url']}. Sizes are estimates at the bundle's measured "
            "rate (59 MB / 4 h ≈ 4.3 KB/s) until generate.py encodes them.", "",
            "| id | Tier | Page | Est. length | Est. size | Note |", "|---|---|---|---|---|---|"]
    total = 0
    for c in m["chants"]:
        total += c["estimated_bytes"]
        out.append("| `{}` | {} | {} | {}:{:02d} | {:.1f} MB | {} |".format(
            c["id"], c["tier"], c["source_page"], c["estimated_seconds"] // 60, c["estimated_seconds"] % 60,
            c["estimated_bytes"] / 1048576, cell(c["note"])))
    out += ["", f"Estimated growth if all are taken: {total / 1048576:.1f} MB of audio (plus scores, ~60 KB each).", "",
            "## Asked for, not on Verbum Gloriae", "", "| Chant | Tier | Slot | Finding |", "|---|---|---|---|"]
    for n in m["chants_not_found"]:
        out.append(f"| {n['latin']} | {n['tier']} | {n['slot']} | {cell(n['finding'])} |")
    out += ["", "Fallbacks (to list for the manager, not to stage):", ""]
    for f in m["fallback_sources"]:
        out.append(f"- [{f['name']}]({f['url']}): {f['note']}")
    out += ["", "## Integrating the chants", "",
            "1. Copy `chant_candidates.json`'s groups and chants into `Tools/Chants/chants.json` (the Chant session owns that file).",
            "2. Fill any `TODO` audio/scores selectors from `python3 fetch.py --chants`.",
            "3. On a Mac: `brew install ffmpeg`, then `cd Tools/Chants && python3 generate.py`. HE-AAC needs afconvert; "
            "Linux ffmpeg 6.1 has only the LC `aac` encoder (no libfdk_aac), so it cannot match the bundle.", ""]
    return "\n".join(out)


if __name__ == "__main__":
    build()
