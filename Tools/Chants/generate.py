#!/usr/bin/env python3
"""Build the Chant Library from Verbum Gloriae (https://www.verbumgloriae.es).

Every recording and score here is the work of Verbum Gloriae, a Spanish
apostolate of Gregorian chant, published under its copyleft licence
(https://www.verbumgloriae.es/licencia-copyleft/): free to copy, adapt and
use for any purpose, commercial included, with no attribution required,
on the one condition that an adaptation is shared under the same licence.
What this script writes into the app is such an adaptation — the Ogg
recordings re-encoded as AAC, the SVG scores split into two layers and
recoloured by the app — so it carries the same licence, and the app says
so wherever a chant plays.

The selection is curated in chants.json. For each chant this script:

  1. reads the chant's page (cached in cache/pages/) for its recording
     and the SVG scores whose alt text begins "Partitura";
  2. downloads them (cache/files/);
  3. re-encodes the recording as mono HE-AAC at 32 kbps
     (app/Resources/Chants/<id>.m4a) — ffmpeg decodes the Ogg, Apple's
     afconvert encodes. Four hours of chant ship in the app, so the rate
     is the one Apple's own tools use for a single voice;
  4. rewrites each SVG score as the ordered drawing operations the app
     replays on a Canvas (app/Resources/Chants/Scores/<name>.lvscore,
     raw DEFLATE): fills in ink and in red, the white shapes that erase,
     and the few stroked lines — so the app draws the notes in its cream
     and the initials in its rubric red, sharp at any zoom. Asset
     catalogs store SVG uncompressed (110 scores came to 30 MB) and
     CoreSVG would not read every one; this is about a fifth of that;
  5. writes app/Data/ChantCatalogData.swift, with each chant's timed lines
     where Tools/ChantLines/<chant id>.json holds them (see LINES below).

Usage:
    python3 generate.py            # fetch what is missing, build, write
    FFMPEG=/path/to/ffmpeg python3 generate.py
    python3 generate.py --keep-assets

Requires ffmpeg (brew install ffmpeg, or set FFMPEG) and macOS's afconvert.

A recording already in the app is kept as it is — delete it to take a
new one — so its source is neither fetched nor encoded, and ffmpeg is
needed only for a chant that has none.

--keep-assets rebuilds the catalog alone — titles, captions, the order of
the shelves — from the chant pages, reusing the scores already in the
app as well: nothing is downloaded but the pages, nothing is re-encoded
or redrawn, and neither ffmpeg nor the cache of source files is needed. A
score the app does not already hold is left out, as a score the site no
longer serves is.
--lines-only folds the line files into the Swift already written,
touching nothing else: no page is read and no file is fetched, so a
chant's lines can be added with no network, no ffmpeg and no cache.

LINES. Tools/ChantLines/<chant id>.json holds one chant's sung lines,
derived from its bundled recording and checked line by line before the
file is added — every file in the folder is taken as shippable:

    { "id": "salve_regina_simple", "part": null,
      "method": "silencedetect + text alignment",
      "lines": [ { "latin": "Salve, Regína, mater misericórdiæ,",
                   "english": "Hail, holy Queen, Mother of mercy,",
                   "start": 0.0, "end": 7.4 } ] }

The file's name is the chant's id (an "id" inside that names no chant is
let pass, the name ruling). Times are seconds into the chant's .m4a.
"part" is null for the whole recording, or the index of the score part
the lines are engraved on; a line may carry its own. A file that does
not hold together — a line ending before it starts, lines out of order or overlapping,
a line past the recording's end, a part the score lacks — stops the
build. A chant with no file has no lines, and the app steps it by ten
seconds and repeats it whole.

Never hand-edit the generated Swift; edit chants.json and rerun.
"""

import html
import json
import os
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

TOOL = Path(__file__).resolve().parent
ROOT = TOOL.parent.parent
CACHE = TOOL / "cache"
AUDIO_OUT = ROOT / "app" / "Resources" / "Chants"
SCORES_OUT = ROOT / "app" / "Resources" / "Chants" / "Scores"
SWIFT_OUT = ROOT / "app" / "Data" / "ChantCatalogData.swift"
LINES_DIR = ROOT / "Tools" / "ChantLines"
SITE = "https://www.verbumgloriae.es"
UA = {"User-Agent": "Mozilla/5.0 (Macintosh) LumenViae/1.0 (chant library build)"}
CODEC = "aach"      # HE-AAC: built for one voice at a low rate
BITRATE = 32000
SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

FFMPEG = os.environ.get("FFMPEG") or shutil.which("ffmpeg")


def fetch(url: str, dest: Path) -> Path:
    if dest.exists() and dest.stat().st_size > 0:
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    # curl rather than urllib: the site's server stalls urllib's reads
    part = dest.with_suffix(dest.suffix + ".part")
    subprocess.run(["curl", "-sSfL", "--retry", "3", "-m", "300", "-A", UA["User-Agent"],
                    "-o", str(part), url], check=True)
    part.rename(dest)
    return dest


def page_url(entry: dict) -> str:
    if entry.get("page"):
        return f"{SITE}/{entry['page']}/"
    return f"{SITE}/project/{entry['slug']}/"


def page_html(entry: dict) -> str:
    key = (entry.get("page") or f"project/{entry['slug']}").replace("/", "_")
    text = fetch(page_url(entry), CACHE / "pages" / f"{key}.html").read_text("utf-8", "replace")
    if "Partitura" in text:
        return text
    # Since September 2026 the site serves its chant pages with the header
    # alone; WordPress's REST API still returns each page's content, as the
    # page builder's shortcodes, with the same files and the same alt text
    kind, slug = ("pages", entry["page"].rsplit("/", 1)[-1]) if entry.get("page") else ("project", entry["slug"])
    api = f"{SITE}/wp-json/wp/v2/{kind}?slug={slug}"
    found = json.loads(fetch(api, CACHE / "pages" / f"{key}.json").read_text("utf-8"))
    if not found:
        sys.exit(f"{entry['id']}: no page at {page_url(entry)} or {api}")
    return found[0]["content"]["rendered"]


def find_audio(entry: dict, text: str) -> str:
    urls = []
    for u in re.findall(r'https?://(?:www\.)?verbumgloriae\.es/wp-content/uploads/[^"?\s\']+\.(?:ogg|mp3|m4a)', text):
        if u not in urls:
            urls.append(u)
    want = entry.get("audio")
    if want:
        urls = [u for u in urls if u.endswith("/" + want) or u.endswith(want)]
    if not urls:
        sys.exit(f"{entry['id']}: no recording on {page_url(entry)}")
    return urls[0]


def find_scores(entry: dict, text: str) -> list:
    """(url, caption) for every score on the page, in page order, once each."""
    found, seen = [], set()
    images = re.compile(
        r'<img[^>]*src="([^"]+\.svg)"[^>]*alt="([^"]*)"'
        # The same image as a builder shortcode, its quotes typeset as »
        r'|et_pb_image src=»([^»\s]+\.svg)» alt=»(.*?)»(?=\s[a-z_]+=|\])')
    for m in images.finditer(text):
        url = m.group(1) or m.group(3)
        alt = html.unescape(m.group(2) if m.group(1) else m.group(4)).strip()
        if not alt.lower().startswith("partitura") or url in seen:
            continue
        seen.add(url)
        found.append((url, alt))
    want = entry.get("scores")
    if want:
        by_name = {u.rsplit("/", 1)[1]: (u, a) for u, a in found}
        missing = [w for w in want if w not in by_name]
        if missing:
            sys.exit(f"{entry['id']}: scores not on page: {missing}")
        found = [by_name[w] for w in want]
    if not found:
        sys.exit(f"{entry['id']}: no score on {page_url(entry)}")
    return found


# Spanish captions that name a part rather than quote it
CAPTION_WORDS = [
    (r"vers(o|ículo)s? y respuestas?", "Versicles and responses"),
    (r"oraci[oó]n", "Collect"),
    (r"primera jaculatoria", "First aspiration"),
    (r"segunda jaculatoria", "Second aspiration"),
    (r"primer misterio gozoso", "The first joyful mystery"),
]


def caption(alt: str, entry: dict) -> str:
    """The name a score part is shown under: the words it begins with, in
    Latin, and none of the site's own filing — no Spanish article or kind
    ("la secuencia", "himno"), no tone ("simple", "solemne"), no melody
    number ("Tantum ergo I"), no litany named again on its own page, and
    no editor's note."""
    quoted = re.search(r"«\s*(.+?)\s*»", alt)
    if quoted:
        text = quoted.group(1)
    else:
        text = re.sub(r"^Partitura\s+(de la|de los|de las|del|de)?\s*", "", alt, flags=re.I).strip()
        for pattern, english in CAPTION_WORDS:
            if re.search(pattern, text, re.I):
                return english
    text = re.sub(r"^(canto|himno|secuencia|antífona)\s+", "", text, flags=re.I)
    text = re.sub(r"\s+de las (Letanías|Litaniae)\b.*$", "", text, flags=re.I)
    text = re.sub(r"^(los )?Kyries\b", "Kyrie eleison", text)
    text = re.sub(r"\s+y los Kyries$", ", Kyrie eleison", text)
    text = re.sub(r",\s*corregida\b.*$", "", text, flags=re.I)
    text = re.sub(r"\s*\([^)]*\)$", "", text)
    text = re.sub(r"\s+(en tono\s+)?(simple|solemne)$", "", text, flags=re.I)
    text = re.sub(r"\s+(I|1)$", "", text)
    text = re.sub(r"^Oratio\s+", "Oremus. ", text)
    text = re.sub(r"^Oremus\.\s*", "Oremus. ", text)
    text = text.replace("...", "…")
    return text.strip().rstrip(".")


# ---------------------------------------------------------------- scores

def parse_css(svg: ET.Element) -> dict:
    rules = {}
    for style in svg.iter(f"{{{SVG_NS}}}style"):
        for sel, body in re.findall(r"([^{}]+)\{([^}]*)\}", style.text or ""):
            props = dict(
                (k.strip(), v.strip())
                for k, v in (p.split(":", 1) for p in body.split(";") if ":" in p)
            )
            for s in sel.split(","):
                s = s.strip()
                if s.startswith("."):
                    rules.setdefault(s[1:], {}).update(props)
    return rules


def props_of(el: ET.Element, css: dict) -> dict:
    props = {}
    for cls in (el.get("class") or "").split():
        props.update(css.get(cls, {}))
    for k in ("fill", "stroke", "stroke-width", "opacity", "fill-opacity"):
        if el.get(k) is not None:
            props[k] = el.get(k)
    for decl in (el.get("style") or "").split(";"):
        if ":" in decl:
            k, v = decl.split(":", 1)
            props[k.strip()] = v.strip()
    return props


def rgb(value: str):
    value = (value or "").strip().lower()
    named = {"red": (255, 0, 0), "black": (0, 0, 0), "white": (255, 255, 255), "none": None}
    if value in named:
        return named[value]
    m = re.fullmatch(r"#([0-9a-f]{3}|[0-9a-f]{6})", value)
    if m:
        h = m.group(1)
        if len(h) == 3:
            h = "".join(c * 2 for c in h)
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    m = re.fullmatch(r"rgb\((\d+),\s*(\d+),\s*(\d+)\)", value)
    if m:
        return tuple(int(x) for x in m.groups())
    return (0, 0, 0)


def is_red(c) -> bool:
    return c is not None and c[0] > 140 and c[1] < 110 and c[2] < 110


def is_white(c) -> bool:
    return c is not None and min(c) > 235


SHAPES = {"path", "rect", "polygon", "polyline", "circle", "ellipse", "line"}


def geometry(el: ET.Element) -> str:
    """The element's outline as SVG path data, whatever shape it was."""
    tag = el.tag.split("}")[-1]
    f = lambda k, d=0.0: float(el.get(k, d))
    if tag == "path":
        return el.get("d", "").strip()
    if tag == "rect":
        x, y, w, h = f("x"), f("y"), f("width"), f("height")
        return f"M{x},{y}h{w}v{h}h{-w}Z"
    if tag == "line":
        return f"M{f('x1')},{f('y1')}L{f('x2')},{f('y2')}"
    if tag in ("polygon", "polyline"):
        pts = re.split(r"[\s,]+", el.get("points", "").strip())
        pairs = [f"{pts[i]},{pts[i + 1]}" for i in range(0, len(pts) - 1, 2)]
        return "M" + "L".join(pairs) + ("Z" if tag == "polygon" else "")
    if tag in ("circle", "ellipse"):
        cx, cy = f("cx"), f("cy")
        rx = f("r") if tag == "circle" else f("rx")
        ry = f("r") if tag == "circle" else f("ry")
        return (f"M{cx - rx},{cy}a{rx},{ry} 0 1,0 {2 * rx},0"
                f"a{rx},{ry} 0 1,0 {-2 * rx},0Z")
    return ""


def score_ops(svg_path: Path) -> tuple:
    """The drawing as ordered operations, in the order the engraving lays
    them down, since a white shape erases only what came before it:

        I  fill in the ink          R  fill in the red
        W  erase (a white shape)    S<w> / T<w>  stroke in ink / red

    Consecutive operations of one kind are merged, their paths kept
    apart by `|` because each path's relative moves start from its own
    origin."""
    root = ET.parse(svg_path).getroot()
    css = parse_css(root)
    vb = [float(x) for x in re.split(r"[ ,]+", root.get("viewBox").strip())]
    ops = []

    def emit(kind: str, d: str):
        if ops and ops[-1][0] == kind:
            ops[-1][1].append(d)
        else:
            ops.append((kind, [d]))

    def walk(node: ET.Element, inherited: dict):
        mine = dict(inherited)
        mine.update(props_of(node, css))
        for child in node:
            tag = child.tag.split("}")[-1]
            if tag in ("style", "defs", "title", "desc", "metadata"):
                continue
            if tag == "g":
                if child.get("transform"):
                    sys.exit(f"{svg_path.name}: a transformed group, which the app cannot draw")
                walk(child, mine)
                continue
            if tag in ("text", "tspan"):
                sys.exit(f"{svg_path.name}: live text, which the app cannot draw")
            if tag not in SHAPES:
                continue
            if child.get("transform"):
                sys.exit(f"{svg_path.name}: a transformed {tag}, which the app cannot draw")
            p = dict(mine)
            p.update(props_of(child, css))
            d = geometry(child)
            if not d:
                continue
            fill = rgb(p.get("fill", "#000"))
            stroke = rgb(p["stroke"]) if p.get("stroke") else None
            width = float(re.sub(r"px$", "", p.get("stroke-width", "1")) or 1)
            if tag == "line" or (fill is None and stroke is not None):
                if stroke is None or is_white(stroke) or width <= 0:
                    continue
                emit(("T" if is_red(stroke) else "S") + f"{width:g}", d)
                continue
            if fill is None:
                continue
            emit("W" if is_white(fill) else "R" if is_red(fill) else "I", d)

    walk(root, {})
    lines = ["LVSCORE 1", " ".join(f"{v:g}" for v in vb)]
    lines += [kind + " " + "|".join(ds) for kind, ds in ops]
    text = "\n".join(lines) + "\n"
    return text, vb[2] / vb[3]


def score_name(url: str) -> str:
    stem = url.rsplit("/", 1)[1].rsplit(".", 1)[0]
    stem = re.sub(r"-web[0-9]?(-alt|-2)?$|-wb$", "", stem)
    return "chant-" + re.sub(r"[^a-z0-9]+", "-", stem.lower()).strip("-")


def write_score(name: str, text: str):
    """Raw DEFLATE, which Foundation's `.zlib` decompression reads."""
    SCORES_OUT.mkdir(parents=True, exist_ok=True)
    packer = zlib.compressobj(9, zlib.DEFLATED, -15)
    (SCORES_OUT / f"{name}.lvscore").write_bytes(packer.compress(text.encode("utf-8")) + packer.flush())


# ---------------------------------------------------------------- audio

def duration_of(recording: Path) -> float:
    info = subprocess.run(["afinfo", str(recording)], capture_output=True, text=True).stdout
    return float(re.search(r"estimated duration: ([\d.]+)", info).group(1))


def kept_aspect(name: str) -> float:
    """The width over the height of a score already written, read from
    its viewBox, as score_ops measured it."""
    packed = (SCORES_OUT / f"{name}.lvscore").read_bytes()
    text = zlib.decompress(packed, -15).decode("utf-8")
    vb = [float(x) for x in text.split("\n")[1].split()]
    return vb[2] / vb[3]


def encode(src: Path, dest: Path) -> float:
    if not FFMPEG:
        sys.exit("ffmpeg not found: brew install ffmpeg, or set FFMPEG")
    dest.parent.mkdir(parents=True, exist_ok=True)
    wav = CACHE / "wav" / (dest.stem + ".wav")
    wav.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
                        "-vn", "-ac", "1", "-ar", "44100", str(wav)], check=True)
        subprocess.run(["afconvert", "-f", "m4af", "-d", CODEC, "-b", str(BITRATE),
                        str(wav), str(dest)], check=True)
        wav.unlink(missing_ok=True)
    return duration_of(dest)


# ---------------------------------------------------------------- swift

def swift_string(s):
    if s is None:
        return "nil"
    escaped = (s.replace("\\", "\\\\").replace('"', '\\"')
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t"))
    return '"' + escaped + '"'


# ---------------------------------------------------------------- lines

def read_lines(ids, durations, part_counts):
    """Every chant's lines from Tools/ChantLines, checked: {id: [line]}."""
    found = {}
    if not LINES_DIR.exists():
        return found
    for path in sorted(LINES_DIR.glob("*.json")):
        data = json.loads(path.read_text("utf-8"))
        chant = path.stem
        if chant not in ids:
            named = data.get("id")
            if named in ids:
                chant = named
            else:
                sys.exit(f"{path.name}: names no chant in chants.json")
        default_part = data.get("part")
        lines = data.get("lines") or []
        if not lines:
            sys.exit(f"{path.name}: no lines")
        previous_start = -1.0
        previous_end = 0.0
        checked = []
        for number, line in enumerate(lines, 1):
            where = f"{path.name}, line {number}"
            for key in ("latin", "english", "start", "end"):
                if key not in line:
                    sys.exit(f"{where}: no {key}")
            latin = str(line["latin"]).strip()
            english = str(line["english"]).strip()
            start = float(line["start"])
            end = float(line["end"])
            if not latin or not english:
                sys.exit(f"{where}: empty words")
            if any(ord(c) < 0x20 or ord(c) == 0x7f for c in latin + english):
                sys.exit(f"{where}: a control character in the words")
            if start < 0 or end <= start:
                sys.exit(f"{where}: ends at {end} before it starts at {start}")
            if start < previous_start:
                sys.exit(f"{where}: starts before the line above it")
            if start < previous_end - 0.001:
                sys.exit(f"{where}: starts at {start}, before the line above it ends at {previous_end}")
            limit = durations.get(chant)
            if limit is not None and end > limit + 0.5:
                sys.exit(f"{where}: ends at {end}, past the recording's {limit:.1f}s")
            part = line.get("part", default_part)
            if part is not None:
                part = int(part)
                count = part_counts.get(chant)
                if count is not None and not 0 <= part < count:
                    sys.exit(f"{where}: part {part}, but the score has {count}")
            previous_start = start
            previous_end = end
            checked.append(dict(latin=latin, english=english, start=start, end=end, part=part))
        found[chant] = checked
    return found


def swift_lines(lines):
    """The `lines:` argument of a Chant, as the generated file sets it."""
    out = ["            lines: ["]
    for l in lines:
        part = "" if l["part"] is None else f", part: {l['part']}"
        out.append(f"                ChantLine(latin: {swift_string(l['latin'])}, "
                   f"english: {swift_string(l['english'])}, "
                   f"start: {l['start']:.2f}, end: {l['end']:.2f}{part}),")
    out[-1] = out[-1].rstrip(",")
    out.append("            ]")
    return out


def fold_lines_into_swift(ids):
    """--lines-only: the line files written into the Swift as it stands."""
    text = SWIFT_OUT.read_text("utf-8")
    # A chant's own id stands alone on its line, twelve spaces in; a
    # shelf's is inside `ChantGroup(` and is never matched
    durations = {m.group(1): float(m.group(2)) for m in re.finditer(
        r'^            id: "([^"]+)",.*?duration: ([0-9.]+),', text, re.S | re.M)}
    part_counts = {}
    for block in re.finditer(r'^            id: "([^"]+)",(.*?)sourceURL:', text, re.S | re.M):
        part_counts[block.group(1)] = block.group(2).count("ChantScorePart(")
    found = read_lines(set(ids), durations, part_counts)

    out = []
    current = None
    skipping = False
    for raw in text.split("\n"):
        if skipping:
            if raw == "            ]":
                skipping = False
            continue
        m = re.match(r'            id: "([^"]+)",', raw)
        if m:
            current = m.group(1)
        if raw.startswith("            lines: ["):
            # Lines from an earlier fold: dropped, and the sourceURL above
            # them loses its comma again
            out[-1] = out[-1].rstrip(",")
            skipping = not raw.rstrip().endswith("]")
            continue
        if raw.startswith("            sourceURL:") and current in found:
            out.append(raw.rstrip(",") + ",")
            out.extend(swift_lines(found[current]))
            continue
        out.append(raw)
    SWIFT_OUT.write_text("\n".join(out), "utf-8")
    print(f"lines folded in for {len(found)} chant(s): {', '.join(sorted(found)) or 'none'}")


def main():
    manifest = json.loads((TOOL / "chants.json").read_text("utf-8"))
    chants = manifest["chants"]
    ids = [c["id"] for c in chants]
    if len(ids) != len(set(ids)):
        sys.exit("duplicate chant ids in chants.json")
    groups = {g["id"] for g in manifest["groups"]}
    keep = "--keep-assets" in sys.argv[1:]

    if "--lines-only" in sys.argv[1:]:
        fold_lines_into_swift(ids)
        return

    if not keep:
        if SCORES_OUT.exists():
            shutil.rmtree(SCORES_OUT)
        for stale in AUDIO_OUT.glob("*.m4a") if AUDIO_OUT.exists() else []:
            if stale.stem not in ids:
                stale.unlink()

    written_assets = {}
    built = []
    for entry in chants:
        if entry["group"] not in groups:
            sys.exit(f"{entry['id']}: unknown group {entry['group']}")
        text = page_html(entry)
        audio_url = find_audio(entry, text)
        recording = AUDIO_OUT / f"{entry['id']}.m4a"
        if recording.exists():
            duration = duration_of(recording)
        elif keep:
            sys.exit(f"{entry['id']}: no recording in the app to keep; run without --keep-assets")
        else:
            src = fetch(audio_url, CACHE / "files" / audio_url.split("/uploads/")[1])
            duration = encode(src, recording)

        parts = []
        for url, alt in find_scores(entry, text):
            name = score_name(url)
            if keep and name not in written_assets:
                if not (SCORES_OUT / f"{name}.lvscore").exists():
                    print(f"  ! {entry['id']}: score not in the app, left out: {url}")
                    continue
                written_assets[name] = kept_aspect(name)
            if name not in written_assets:
                try:
                    svg = fetch(url, CACHE / "files" / url.split("/uploads/")[1])
                except subprocess.CalledProcessError:
                    # The site links a few scores it no longer serves (the
                    # Litany of Loreto's Easter collect); the chant keeps
                    # the rest of its score
                    print(f"  ! {entry['id']}: score not served, skipped: {url}")
                    continue
                text_ops, aspect = score_ops(svg)
                write_score(name, text_ops)
                written_assets[name] = aspect
            parts.append(dict(file=name, caption=caption(alt, entry), aspect=written_assets[name]))
        built.append(dict(entry=entry, duration=duration, parts=parts, source=page_url(entry)))
        print(f"{entry['id']:24} {duration:6.1f}s  {len(parts)} score part(s)")

    timed = read_lines(
        set(ids),
        {b["entry"]["id"]: b["duration"] for b in built},
        {b["entry"]["id"]: len(b["parts"]) for b in built},
    )

    lines = [
        "//",
        "//  ChantCatalogData.swift",
        "//  Lumen Viae",
        "//",
        "//  GENERATED by Tools/Chants/generate.py from chants.json — edit the",
        "//  selection there and regenerate; never by hand here.",
        "//",
        "//  Recordings and scores: Verbum Gloriae (verbumgloriae.es), under",
        "//  their copyleft licence. The AAC files and recoloured scores bundled",
        "//  here are adaptations and carry the same licence.",
        "//",
        "",
        "import Foundation",
        "",
        "extension ChantCatalog {",
        "",
        "    static let groups: [ChantGroup] = [",
    ]
    for g in manifest["groups"]:
        lines.append(f"        ChantGroup(id: {swift_string(g['id'])}, title: {swift_string(g['title'])}, note: {swift_string(g.get('note'))}),")
    lines[-1] = lines[-1].rstrip(",")
    lines += ["    ]", "", "    static let all: [Chant] = ["]
    for b in built:
        e = b["entry"]
        lines.append("        Chant(")
        lines.append(f"            id: {swift_string(e['id'])},")
        lines.append(f"            groupID: {swift_string(e['group'])},")
        lines.append(f"            latinTitle: {swift_string(e['latin'])},")
        lines.append(f"            englishTitle: {swift_string(e['english'])},")
        lines.append(f"            setting: {swift_string(e.get('setting'))},")
        lines.append(f"            detail: {swift_string(e['detail'])},")
        lines.append(f"            prayerIDs: [{', '.join(swift_string(p) for p in e['prayers'])}],")
        lines.append(f"            duration: {b['duration']:.1f},")
        lines.append("            score: [")
        for p in b["parts"]:
            lines.append(f"                ChantScorePart(file: {swift_string(p['file'])}, "
                         f"caption: {swift_string(p['caption'])}, aspectRatio: {p['aspect']:.4f}),")
        lines[-1] = lines[-1].rstrip(",")
        lines.append("            ],")
        source = f"            sourceURL: URL(string: {swift_string(b['source'])})!"
        if e["id"] in timed:
            lines.append(source + ",")
            lines.extend(swift_lines(timed[e["id"]]))
        else:
            lines.append(source)
        lines.append("        ),")
    lines[-1] = lines[-1].rstrip(",")
    lines += ["    ]", "}", ""]
    SWIFT_OUT.write_text("\n".join(lines), "utf-8")

    audio_mb = sum(f.stat().st_size for f in AUDIO_OUT.glob("*.m4a")) / 1e6
    svg_mb = sum(f.stat().st_size for f in SCORES_OUT.glob("*.lvscore")) / 1e6
    minutes = sum(b["duration"] for b in built) / 60
    print(f"\n{len(built)} chants, {minutes:.0f} min: audio {audio_mb:.1f} MB, scores {svg_mb:.1f} MB "
          f"({len(written_assets)} scores), lines for {len(timed)}")


if __name__ == "__main__":
    main()
