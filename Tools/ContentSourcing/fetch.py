#!/usr/bin/env python3
"""Fetch and verify everything manifest.json proposes, in one run.

    pip3 install pillow && python3 fetch.py

Standard library and Pillow only; chant pages are read with
Tools/Chants/generate.py's own functions (and curl, as it uses), into its
cache, so the generator run that follows downloads nothing twice.

What it does, for every entry still `unverified` in manifest.json:

  paintings  resolves the slot to a Wikimedia Commons file — `commons_file`
             if sources.py pins one, else the largest search hit whose
             title names the painter — reads that file page's licence, and
             writes app/Assets.xcassets/<imageset>.imageset (1600 px long
             edge, progressive JPEG, 300–800 KB)
  chants     reads Verbum Gloriae's licence page once, then each chant's
             page, and resolves the exact recording and score file names
             (by `audio_match`/`scores_match` where one page holds several)

and records what it read in fetched.json, then rebuilds the manifests.

It is idempotent: a verified entry is skipped, and an imageset already on
disk is never touched. A licence not on the allowed list (public domain,
CC0, CC BY, CC BY-SA; for chants, Verbum Gloriae's copyleft) is a failure,
not a skip: every failure is listed at the end and the exit status is 1.

Other modes:
    python3 fetch.py --search [imageset]   show Commons hits for a slot, with licences
    python3 fetch.py --take <imageset> "File:…"   pin and take a particular file
    python3 fetch.py --provenance          look up the bundled paintings on Commons
    python3 fetch.py --retake <imageset>   take a bundled painting again at full size,
                                           from the file its provenance matched exactly
"""

import io
import json
import re
import sys
import unicodedata
import urllib.parse
import urllib.request
from pathlib import Path

import build_manifest
import sources as S

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
ASSETS = ROOT / "app" / "Assets.xcassets"
FETCHED = HERE / "fetched.json"
API = "https://commons.wikimedia.org/w/api.php"
UA = {"User-Agent": "LumenViaeContentSourcing/1.0 (https://github.com/abrahamrodri/lumenviae-app)"}
LONG_EDGE = 1600
MAX_BYTES = 800 * 1024
MIN_LONG_EDGE = 1200
ACCEPT = re.compile(r"^(public domain|pd\b|pd-|cc0|cc[- ]by(-sa)?[- ]?\d)", re.I)
REJECT = re.compile(r"\b(nc|nd)\b|noncommercial|noderiv", re.I)
VG_LICENCE = "https://www.verbumgloriae.es/licencia-copyleft/"

sys.path.insert(0, str(ROOT / "Tools" / "Chants"))


# ------------------------------------------------------------------ helpers

def get(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120) as r:
        return r.read()


def api(**params) -> dict:
    params.update(format="json", formatversion="2")
    return json.loads(get(API + "?" + urllib.parse.urlencode(params)))


def fold(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFKD", s or "") if not unicodedata.combining(c)).lower()


def load_fetched() -> dict:
    return json.loads(FETCHED.read_text()) if FETCHED.exists() else {}


def record(key: str, values: dict):
    data = load_fetched()
    data.setdefault(key, {}).update(values)
    FETCHED.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


# ---------------------------------------------------------------- paintings

def imageinfo(titles) -> list:
    pages = api(action="query", prop="imageinfo", titles="|".join(titles),
                iiprop="url|size|extmetadata|mime")["query"]["pages"]
    out = []
    for p in pages:
        if "imageinfo" not in p:
            continue
        ii = p["imageinfo"][0]
        md = {k: re.sub("<[^>]+>", "", str(v.get("value", ""))).strip() for k, v in ii.get("extmetadata", {}).items()}
        out.append(dict(title=p["title"], url=ii["url"], page=ii.get("descriptionurl"), width=ii["width"],
                        height=ii["height"], mime=ii.get("mime"), licence=md.get("LicenseShortName", ""),
                        licence_url=md.get("LicenseUrl"), artist=md.get("Artist")))
    return out


def search(query: str, limit=10) -> list:
    hits = api(action="query", list="search", srsearch=query, srnamespace=6, srlimit=limit)["query"]["search"]
    return [i for i in imageinfo([h["title"] for h in hits]) if (i["mime"] or "").startswith("image/")] if hits else []


def licence_ok(info: dict) -> bool:
    return bool(ACCEPT.search(info["licence"])) and not REJECT.search(info["licence"])


def surname(creator: str) -> str:
    name = re.sub(r"\s*\(.*", "", creator or "").strip()
    return fold(name.split()[-1]) if name else ""


def choose(slot: dict) -> dict:
    """The pinned file, or the largest openly licensed hit naming the painter."""
    if slot.get("commons_file"):
        found = imageinfo([slot["commons_file"]])
        if not found:
            raise Failure(f"pinned file not on Commons: {slot['commons_file']}")
        return found[0]
    who = surname(slot["creator"])
    hits = search(slot["commons_search"])
    good = [h for h in hits if licence_ok(h) and who in fold(h["title"] + " " + (h["artist"] or ""))
            and max(h["width"], h["height"]) >= MIN_LONG_EDGE]
    if not good:
        listing = "; ".join(f"{h['title']} [{h['licence'] or '?'}, {h['width']}×{h['height']}]" for h in hits[:5])
        raise Failure(f"no openly licensed hit naming {who!r} at {MIN_LONG_EDGE}px+ — pin one with --take. Hits: {listing or 'none'}")
    return max(good, key=lambda h: h["width"] * h["height"])


def encode(data: bytes, crop=None) -> bytes:
    """`crop` is (left, top, right, bottom): the fraction of the source to trim
    from each edge, so a scan's frame can be left out at any source size."""
    from PIL import Image
    im = Image.open(io.BytesIO(data))
    im.draft("RGB", (LONG_EDGE * 2, LONG_EDGE * 2))
    im = im.convert("RGB")
    if crop:
        w, h = im.size
        left, top, right, bottom = crop
        im = im.crop((round(left * w), round(top * h), w - round(right * w), h - round(bottom * h)))
    im.thumbnail((LONG_EDGE, LONG_EDGE), Image.LANCZOS)
    best = b""
    for q in (88, 84, 80, 76, 72, 68):
        buf = io.BytesIO()
        im.save(buf, "JPEG", quality=q, progressive=True, optimize=True)
        best = buf.getvalue()
        if len(best) <= MAX_BYTES:
            break
    return best


def write_imageset(name: str, jpeg: bytes):
    d = ASSETS / f"{name}.imageset"
    d.mkdir()
    (d / f"{name}.jpg").write_bytes(jpeg)
    (d / "Contents.json").write_text(json.dumps({
        "images": [{"filename": f"{name}.jpg", "idiom": "universal", "scale": "1x"},
                   {"idiom": "universal", "scale": "2x"}, {"idiom": "universal", "scale": "3x"}],
        "info": {"author": "xcode", "version": 1}}, indent=2).replace('": ', '" : ') + "\n")


def take_painting(slot: dict, pinned: str = None):
    name = slot["imageset"]
    if (ASSETS / f"{name}.imageset").exists():
        raise Failure(f"{name}.imageset is already on disk but not recorded as verified; check it by hand")
    if pinned:
        slot = dict(slot, commons_file=pinned)
    info = choose(slot)
    if not licence_ok(info):
        raise Failure(f"licence '{info['licence'] or 'none stated'}' is not on the allowed list ({info['page']})")
    jpeg = encode(get(info["url"]), slot.get("crop"))
    write_imageset(name, jpeg)
    attribution = None
    if re.search(r"cc[- ]by", info["licence"], re.I):
        artist = re.sub(r"\s+", " ", info["artist"] or "Unknown")
        attribution = f"{artist}, {info['licence']}, via Wikimedia Commons ({info['page']})"
    record(name, dict(status="verified", commons_file=info["title"], source_page=info["page"], file_url=info["url"],
                      licence=info["licence"], licence_url=info["licence_url"] or S.PD_ART["licence_url"],
                      attribution=attribution, width=info["width"], height=info["height"], bytes=len(jpeg),
                      crop=slot.get("crop")))
    print(f"  ✓ {name}: {info['title']} [{info['licence']}] → {len(jpeg) // 1024} KB")


def retake_bundled(name: str):
    """Take a bundled painting again at full size, from the Commons file its
    provenance matched exactly, over the JPG already in its imageset. The
    imageset and its Contents.json stay as they are, and the aspect must
    not move, or the app's focal points would land elsewhere."""
    from PIL import Image
    prov = S.PROVENANCE.get(name)
    if not prov or prov["match"] != "exact":
        raise Failure("only a painting whose provenance match is exact can be taken again")
    d = ASSETS / f"{name}.imageset"
    contents = json.loads((d / "Contents.json").read_text())
    filename = next(i["filename"] for i in contents["images"] if i.get("filename"))
    if not filename.lower().endswith((".jpg", ".jpeg")):
        raise Failure(f"{filename} is not a JPEG; replace it by hand")
    ow, oh = Image.open(d / filename).size
    found = imageinfo([prov["commons_file"]])
    if not found:
        raise Failure(f"file not on Commons: {prov['commons_file']}")
    info = found[0]
    if not licence_ok(info):
        raise Failure(f"licence '{info['licence'] or 'none stated'}' is not on the allowed list ({info['page']})")
    drift = abs((info["width"] / info["height"]) / (ow / oh) - 1)
    if drift > 0.005:
        raise Failure(f"the file's aspect differs from the bundled {ow}×{oh} by {drift:.2%}; the focal points would move")
    jpeg = encode(get(info["url"]))
    nw, nh = Image.open(io.BytesIO(jpeg)).size
    (d / filename).write_bytes(jpeg)
    record(name, dict(status="verified", commons_file=info["title"], source_page=info["page"], file_url=info["url"],
                      licence=info["licence"], licence_url=info["licence_url"] or S.PD_ART["licence_url"],
                      width=info["width"], height=info["height"], bytes=len(jpeg), retaken_from=f"{ow}×{oh}"))
    print(f"  ✓ {name}: {ow}×{oh} → {nw}×{nh} from {info['title']} [{info['licence']}], {len(jpeg) // 1024} KB")


# ------------------------------------------------------------------- chants

def vg_licence_read() -> bool:
    """Read Verbum Gloriae's licence page and check it still says what the app relies on."""
    import generate as G
    try:
        text = G.page_html({"id": "licence", "page": "licencia-copyleft"})
    except SystemExit:
        text = get(VG_LICENCE).decode("utf-8", "replace")
    t = fold(text)
    return "copyleft" in t and ("comercial" in t or "commercial" in t)


def pick(names: list, pattern: str, what: str) -> list:
    if pattern:
        names = [n for n in names if re.search(pattern, n, re.I)]
    if not names:
        raise Failure(f"no {what} on the page" + (f" matching /{pattern}/" if pattern else ""))
    return names


def take_chant(c: dict):
    import generate as G
    entry = c["entry"]
    try:
        text = G.page_html(entry)
    except SystemExit as e:
        raise Failure(str(e))
    try:
        audio = G.find_audio({k: v for k, v in entry.items() if k != "audio"}, text) if not c.get("audio_match") else None
    except SystemExit as e:
        raise Failure(str(e))
    audio_names = sorted(set(re.findall(r"verbumgloriae\.es/wp-content/uploads/([^\"?\s'»]+\.(?:ogg|mp3|m4a))", text)))
    if c.get("audio_match"):
        audio_names = pick(audio_names, c["audio_match"], "recording")
        if len(audio_names) > 1:
            raise Failure(f"several recordings match /{c['audio_match']}/: {audio_names}")
        audio_sel = audio_names[0]
    elif len(audio_names) > 1:
        raise Failure(f"page has several recordings; add audio_match in sources.py: {audio_names}")
    else:
        audio_sel = None  # one recording: no selector, as chants.json does for single pages
    try:
        scores = [u.rsplit("/", 1)[1] for u, _ in G.find_scores({k: v for k, v in entry.items() if k != "scores"}, text)]
    except SystemExit as e:
        raise Failure(str(e))
    scores_sel = pick(scores, c["scores_match"], "score") if c.get("scores_match") else None
    # chants.json's own order: page, audio and scores follow the slug
    resolved = {k: entry[k] for k in ("id", "slug", "page") if k in entry}
    if audio_sel:
        resolved["audio"] = audio_sel
    if scores_sel:
        resolved["scores"] = scores_sel
    resolved.update({k: v for k, v in entry.items() if k not in resolved})
    record(entry["id"], dict(status="verified", resolved_entry=resolved, audio_files=[audio_sel] if audio_sel else
                             [audio.split("/uploads/")[1]] if audio else audio_names, score_files=scores_sel or scores,
                             licence_page_read=VG_LICENCE))
    print(f"  ✓ {entry['id']}: audio {audio_sel or 'the page’s one recording'}, {len(scores_sel or scores)} score(s)")


# --------------------------------------------------------------------- run

class Failure(Exception):
    pass


def run_all() -> int:
    manifest = json.loads((HERE / "manifest.json").read_text())
    done = load_fetched()
    failures = []

    print("Paintings")
    slots = {p["imageset"]: p for p in S.PAINTINGS}
    for p in manifest["new_paintings"]:
        name = p["imageset"]
        if p.get("alias_of") or done.get(name, {}).get("status") == "verified":
            continue
        try:
            take_painting(slots[name])
        except Failure as e:
            failures.append(f"{name}: {e}")
            print(f"  ✗ {name}: {e}")

    print("Chants")
    pending = [c for c in S.CHANTS if done.get(c["entry"]["id"], {}).get("status") != "verified"]
    if pending:
        if not vg_licence_read():
            failures.append(f"Verbum Gloriae's licence page ({VG_LICENCE}) no longer reads as copyleft for commercial use; no chant verified")
            print("  ✗ licence page check failed")
        else:
            for c in pending:
                try:
                    take_chant(c)
                except Failure as e:
                    failures.append(f"{c['entry']['id']}: {e}")
                    print(f"  ✗ {c['entry']['id']}: {e}")

    build_manifest.build()
    if failures:
        print(f"\n{len(failures)} FAILED — nothing failed was written to the app:")
        for f in failures:
            print("  - " + f)
        return 1
    print("\nAll verified. manifest.json, MANIFEST.md and chant_candidates.json rebuilt.")
    return 0


def main(argv):
    if not argv:
        sys.exit(run_all())
    if argv[0] in ("-h", "--help"):
        print(__doc__)
    elif argv[0] == "--search":
        for p in S.PAINTINGS:
            if p.get("commons_search") and (len(argv) == 1 or p["imageset"] in argv[1:]):
                print(f"{p['imageset']}: {p['work']} — {p['creator']}")
                for i in search(p["commons_search"]):
                    print(f"  {'OK' if licence_ok(i) else '--'} {i['width']}×{i['height']}  {i['licence'] or '?':18} {i['title']}")
    elif argv[0] == "--take" and len(argv) == 3:
        slot = next(p for p in S.PAINTINGS if p["imageset"] == argv[1])
        try:
            take_painting(slot, argv[2])
        except Failure as e:
            sys.exit(f"{argv[1]}: {e}")
        build_manifest.build()
    elif argv[0] == "--retake" and len(argv) == 2:
        try:
            retake_bundled(argv[1])
        except Failure as e:
            sys.exit(f"{argv[1]}: {e}")
        build_manifest.build()
    elif argv[0] == "--provenance":
        for name, work, creator, *_ in S.EXISTING:
            print(f"{name}: {work} — {creator or '?'}")
            # A parenthetical ("(d. 1911)", "(Lo Spasimo di Sicilia)") is a note
            # for the reader; left in the query, it matches nothing
            query = re.sub(r"\s*\([^)]*\)", "", f"{work} {creator or ''}").strip()
            for i in search(query, limit=4):
                print(f"  {'OK' if licence_ok(i) else '--'} {i['width']}×{i['height']}  {i['licence'] or '?':18} {i['title']}")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
