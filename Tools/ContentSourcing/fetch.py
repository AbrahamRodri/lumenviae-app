#!/usr/bin/env python3
"""Fetch and verify the content proposed in sources.py.

Needs network access to commons.wikimedia.org, upload.wikimedia.org and
www.verbumgloriae.es, plus Pillow (pip install pillow).

    python3 fetch.py --search                 # every open painting slot: Commons hits with licence and size
    python3 fetch.py --search season_advent   # one slot
    python3 fetch.py --take season_advent "File:Some painting.jpg"
                                              # download, check the licence, write the imageset
    python3 fetch.py --provenance             # match each bundled painting to a Commons file
    python3 fetch.py --chants                 # list the recordings and scores on each candidate's VG page

--take refuses a file unless Commons' own licence metadata says public
domain, CC0, CC BY or CC BY-SA, and records what it read in fetched.json.
Rerun build_manifest.py afterwards. It never touches an existing imageset.
"""

import io
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

import sources as S

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent.parent / "app" / "Assets.xcassets"
API = "https://commons.wikimedia.org/w/api.php"
UA = {"User-Agent": "LumenViaeContentSourcing/1.0 (https://github.com/abrahamrodri/lumenviae-app)"}
LONG_EDGE = 1600
TARGET = (300 * 1024, 800 * 1024)
ACCEPT = re.compile(r"^(public domain|pd|cc0|cc[- ]by(-sa)?[- ]?\d)", re.I)
REJECT = re.compile(r"\b(nc|nd)\b|noncommercial|noderiv", re.I)


def get(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return r.read()


def api(**params) -> dict:
    params.update(format="json", formatversion="2")
    return json.loads(get(API + "?" + urllib.parse.urlencode(params)))


def imageinfo(titles) -> list:
    pages = api(action="query", prop="imageinfo", titles="|".join(titles),
                iiprop="url|size|extmetadata|mime")["query"]["pages"]
    out = []
    for p in pages:
        if "imageinfo" not in p:
            continue
        ii = p["imageinfo"][0]
        md = {k: re.sub("<[^>]+>", "", v.get("value", "")).strip() for k, v in ii.get("extmetadata", {}).items()}
        out.append(dict(title=p["title"], url=ii["url"], page=ii.get("descriptionurl"), width=ii["width"],
                        height=ii["height"], mime=ii.get("mime"), licence=md.get("LicenseShortName", ""),
                        licence_url=md.get("LicenseUrl"), artist=md.get("Artist"), date=md.get("DateTimeOriginal"),
                        credit=md.get("Credit"), attribution_required=md.get("AttributionRequired")))
    return out


def search(query: str, limit=8) -> list:
    hits = api(action="query", list="search", srsearch=f"{query} filetype:bitmap", srnamespace=6,
               srlimit=limit)["query"]["search"]
    return imageinfo([h["title"] for h in hits]) if hits else []


def licence_ok(info: dict) -> bool:
    lic = info["licence"]
    return bool(ACCEPT.search(lic)) and not REJECT.search(lic)


def show(infos):
    for i in infos:
        mark = "OK " if licence_ok(i) else "-- "
        print(f"  {mark}{i['width']}×{i['height']}  {i['licence'] or '?':18}  {i['title']}")


def encode(data: bytes) -> bytes:
    from PIL import Image
    im = Image.open(io.BytesIO(data)).convert("RGB")
    im.thumbnail((LONG_EDGE, LONG_EDGE), Image.LANCZOS)
    best = None
    for q in (88, 84, 80, 76, 72, 68):
        buf = io.BytesIO()
        im.save(buf, "JPEG", quality=q, progressive=True, optimize=True)
        best = buf.getvalue()
        if len(best) <= TARGET[1]:
            break
    return best


def write_imageset(name: str, jpeg: bytes):
    d = ASSETS / f"{name}.imageset"
    if d.exists():
        sys.exit(f"{name}.imageset already exists; never replaced")
    d.mkdir()
    (d / f"{name}.jpg").write_bytes(jpeg)
    (d / "Contents.json").write_text(json.dumps({
        "images": [{"filename": f"{name}.jpg", "idiom": "universal", "scale": "1x"},
                   {"idiom": "universal", "scale": "2x"}, {"idiom": "universal", "scale": "3x"}],
        "info": {"author": "xcode", "version": 1}}, indent=2).replace('": ', '" : ') + "\n")


def record(key: str, values: dict):
    p = HERE / "fetched.json"
    data = json.loads(p.read_text()) if p.exists() else {}
    data.setdefault(key, {}).update(values)
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def take(name: str, title: str):
    info = imageinfo([title])
    if not info:
        sys.exit(f"no such file: {title}")
    info = info[0]
    if not licence_ok(info):
        sys.exit(f"refused: licence '{info['licence']}' on {info['page']}")
    jpeg = encode(get(info["url"]))
    write_imageset(name, jpeg)
    attribution = None
    if re.search("cc[- ]by", info["licence"], re.I):
        attribution = f"{info['artist']}, {info['licence']}, via Wikimedia Commons ({info['page']})"
    record(name, dict(status="verified", commons_file=info["title"], source_page=info["page"], file_url=info["url"],
                      licence=info["licence"], licence_url=info["licence_url"] or S.PD_ART["licence_url"],
                      attribution=attribution, width=info["width"], height=info["height"], bytes=len(jpeg)))
    print(f"{name}: {info['title']} ({info['licence']}) → {len(jpeg) // 1024} KB")


def chant_files():
    for c in S.CHANTS:
        e = c["entry"]
        page = e.get("page") or f"project/{e['slug']}"
        slug = page.rsplit("/", 1)[-1]
        kind = "pages" if e.get("page") else "project"
        try:
            found = json.loads(get(f"https://www.verbumgloriae.es/wp-json/wp/v2/{kind}?slug={slug}"))
            text = found[0]["content"]["rendered"] if found else get(f"https://www.verbumgloriae.es/{page}/").decode()
        except Exception as err:  # noqa: BLE001 - report and go on
            print(f"{e['id']}: {err}")
            continue
        audio = sorted(set(re.findall(r'uploads/([^"?\s\'»]+\.(?:ogg|mp3|m4a))', text)))
        scores = sorted(set(re.findall(r'([^/"»\s]+\.svg)[»"][^>\]]*?alt=[»"]Partitura', text)))
        print(f"{e['id']} ({page}):\n  audio:  {audio}\n  scores: {scores}")


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
    elif argv[0] == "--search":
        names = argv[1:] or [p["imageset"] for p in S.PAINTINGS if p.get("commons_search")]
        for p in S.PAINTINGS:
            if p["imageset"] in names and p.get("commons_search"):
                print(f"{p['imageset']}: {p['work']} — {p['creator']}")
                show(search(p["commons_search"]))
    elif argv[0] == "--take" and len(argv) == 3:
        take(argv[1], argv[2])
    elif argv[0] == "--provenance":
        for name, work, creator, *_ in S.EXISTING:
            print(f"{name}: {work} — {creator or '?'}")
            show(search(f"{work} {creator or ''}", limit=4))
    elif argv[0] == "--chants":
        chant_files()
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
