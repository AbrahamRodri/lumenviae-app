#!/usr/bin/env python3
"""Line-by-line words and timings for the Chant Library's recordings.

Each chant's text, as the cantor sings it, is curated in src/<id>.txt: one
line per breath, the Latin as the score prints it (the Liber's accents)
beside its English. This script finds the breaths in the recording (its
loudness, frame by frame), lays the lines over them one to one, checks
them, and writes <id>.json beside this file, which Tools/Chants reads.

A chant is written only when the recording's phrases line up with the
text's lines one to one: the same count, and every line between
MIN_LINE and MAX_LINE seconds long. With a Whisper model at hand (see
README.md) every line is also heard: Whisper transcribes each phrase in
Latin, the transcripts are aligned with the text letter by letter, and
a breath that falls where the text says another line has already begun
fails the chant.

    python3 lines.py probe <id> [--noise -35] [--gap 0.4] [--merge 1.5]
        The phrases found, their lengths and what Whisper hears in each:
        the curator's view while writing src/<id>.txt.
    python3 lines.py build [<id> ...]       (no id: every src/*.txt)
        Check each chant and write <id>.json; remove the json of a
        chant that no longer passes.
    python3 lines.py score <part> [...]
        Render a score part (app/Resources/Chants/Scores/<part>.lvscore)
        as cache/scores/<part>.png, to read the words and the bars from.

src/<id>.txt holds settings, a blank line, then the lines:

    noise -20        a breath is quieter than this, in dB below the loud singing
    gap 0.4          the shortest silence that is a breath, in seconds
    merge 1.5        a phrase shorter than this joins the neighbour it is
                     nearer to (a last syllable sung after a pause)

    Salve, Regína, Mater misericórdiæ: | Hail, holy Queen, Mother of mercy,

A line reading `part N` gives the lines below it the score part they are
engraved on (N counts from 0, in ChantCatalogData's order); a file that
uses it must give every line one. A line of its own reading `~` carries the line above it over one more
phrase: for a breath the cantor takes inside a line where the text is not
sure enough to be parted (a breath inside one word's melisma, say). `#`
begins a comment.
"""

import json
import os
import re
import subprocess
import sys
import unicodedata
import zlib
from pathlib import Path

TOOL = Path(__file__).resolve().parent
ROOT = TOOL.parent.parent
SRC = TOOL / "src"
CACHE = TOOL / "cache"
AUDIO = ROOT / "app" / "Resources" / "Chants"
SCORES = AUDIO / "Scores"
CHANTS = ROOT / "Tools" / "Chants" / "chants.json"
WHISPER = Path(os.environ.get("WHISPER_DIR", CACHE / "models" / "sherpa-onnx-whisper-small"))

MIN_LINE = 1.5      # seconds: shorter is a fragment, not a line
MAX_LINE = 25.0     # seconds: longer is two lines the breath did not part
LEAD_IN = 0.15      # a line starts this much before its sound is detected
TAIL = 0.3          # and ends at least this much after it
FADE = -28.0        # dB under the loud singing where a held note has died away
DEFAULTS = {"noise": -20.0, "gap": 0.3, "merge": 1.5}


# ---------------------------------------------------------------- audio

def wav_of(chant: str) -> Path:
    """The recording as 16 kHz mono PCM, which both ffmpeg's filter and
    Whisper read."""
    src = AUDIO / f"{chant}.m4a"
    if not src.exists():
        sys.exit(f"{chant}: no recording at {src}")
    out = CACHE / "wav" / f"{chant}.wav"
    if not out.exists() or out.stat().st_mtime < src.stat().st_mtime:
        out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
                        "-ac", "1", "-ar", "16000", str(out)], check=True)
    return out


def duration_of(wav: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                          "-of", "default=nw=1:nk=1", str(wav)], capture_output=True, text=True)
    return float(out.stdout.strip())


def loudness(chant: str) -> tuple:
    """The recording's level, frame by frame: RMS over 40 ms every 20 ms,
    in dB relative to its loud singing (the 90th percentile frame), so
    one threshold serves a close recording and a distant one alike."""
    import numpy as np
    import soundfile as sf
    audio, rate = sf.read(str(wav_of(chant)), dtype="float32")
    hop = int(rate * FRAME)
    frames = np.lib.stride_tricks.sliding_window_view(audio, 2 * hop)[::hop]
    db = 20 * np.log10(np.sqrt((frames ** 2).mean(axis=1)) + 1e-9)
    return db - np.percentile(db, 90), len(audio) / rate


FRAME = 0.02


def phrases(chant: str, noise: float, gap: float, merge: float) -> tuple:
    """The sounding stretches of the recording, as [start, end] pairs: a
    breath is `gap` seconds or more under `noise` dB (relative to the
    loud singing), and a stretch shorter than `merge` joins the
    neighbour across the shorter breath."""
    db, total = loudness(chant)
    quiet = db < noise
    sound, i, n = [], 0, len(quiet)
    start = None
    while i < n:
        if quiet[i]:
            j = i
            while j < n and quiet[j]:
                j += 1
            if (j - i) * FRAME >= gap or i == 0 or j == n:
                if start is not None:
                    sound.append([round(start * FRAME, 2), round(i * FRAME, 2)])
                start = None
            elif start is None:
                start = i
            i = j
        else:
            if start is None:
                start = i
            i += 1
    if start is not None:
        sound.append([round(start * FRAME, 2), round(total, 2)])
    sound = [s for s in sound if s[1] - s[0] >= 0.1]
    while len(sound) > 1:
        short = min(range(len(sound)), key=lambda i: sound[i][1] - sound[i][0])
        if sound[short][1] - sound[short][0] >= merge:
            break
        before = sound[short][0] - sound[short - 1][1] if short > 0 else float("inf")
        after = sound[short + 1][0] - sound[short][1] if short + 1 < len(sound) else float("inf")
        if before <= after:
            sound[short - 1][1] = sound[short][1]
        else:
            sound[short + 1][0] = sound[short][0]
        del sound[short]
    return sound, total


def padded(chant: str, sound: list, total: float) -> list:
    """Each phrase as a line's times. It starts LEAD_IN before its sound
    is found, and ends where its sound has died away, under FADE dB for
    a tenth of a second, at least TAIL after it is found to end: a breath
    is found at `noise`, but a held last note fades well below that
    while it is still heard, and cut there a repeated line loses it. A
    line never runs into the next one's lead-in."""
    db, _ = loudness(chant)
    out = []
    for i, (a, b) in enumerate(sound):
        floor = (sound[i - 1][1] + a) / 2 if i > 0 else 0.0
        start = max(floor, a - LEAD_IN)
        if i > 0:
            start = max(start, out[-1][1])
        limit = sound[i + 1][0] - LEAD_IN if i + 1 < len(sound) else total
        k = int(b / FRAME)
        while k < len(db) and k * FRAME < limit and not (db[k:k + 5] < FADE).all():
            k += 1
        stop = min(limit, max(b + TAIL, k * FRAME))
        out.append((round(start, 2), round(stop, 2)))
    return out


# ---------------------------------------------------------------- whisper

_recognizer = None


def hear(chant: str, sound: list) -> list:
    """What Whisper hears in each phrase, in Latin; None without a model.
    Cached by chant and phrase."""
    if not (WHISPER / "small-tokens.txt").exists():
        return None
    cache = CACHE / "asr" / f"{chant}.json"
    known = json.loads(cache.read_text()) if cache.exists() else {}
    keys = [f"{a:.2f}-{b:.2f}" for a, b in sound]
    todo = [k for k in keys if k not in known]
    if todo:
        global _recognizer
        import numpy as np
        import sherpa_onnx
        import soundfile as sf
        if _recognizer is None:
            m = str(WHISPER / "small-")
            _recognizer = sherpa_onnx.OfflineRecognizer.from_whisper(
                encoder=m + "encoder.int8.onnx", decoder=m + "decoder.int8.onnx",
                tokens=m + "tokens.txt", language="la", task="transcribe",
                num_threads=whisper_threads())
        audio, rate = sf.read(str(wav_of(chant)), dtype="float32")
        for k in todo:
            a, b = (float(x) for x in k.split("-"))
            words = []
            # Whisper hears 30 seconds at a time
            for c in np.arange(a, b, 28.0):
                stream = _recognizer.create_stream()
                stream.accept_waveform(rate, audio[int(max(0, c - 0.1) * rate):int(min(b, c + 28.0) * rate)])
                _recognizer.decode_stream(stream)
                words.append(stream.result.text.strip())
            known[k] = " ".join(w for w in words if w)
            # kept after every phrase, so a long recording interrupted
            # loses one phrase's work, not all of it
            cache.parent.mkdir(parents=True, exist_ok=True)
            part = cache.with_suffix(f".{os.getpid()}.part")
            part.write_text(json.dumps(known, ensure_ascii=False, indent=0))
            part.replace(cache)
    return [known[k] for k in keys]


def whisper_threads() -> int:
    """WHISPER_THREADS, else the cores shared among the runs of this
    script going at once: two runs asking for every core each run slower
    than one after the other."""
    if os.environ.get("WHISPER_THREADS"):
        return int(os.environ["WHISPER_THREADS"])
    runs = 0
    for proc in Path("/proc").glob("[0-9]*"):
        try:
            argv = (proc / "cmdline").read_bytes().split(b"\0")
        except OSError:
            continue
        runs += any(a.endswith(b"lines.py") for a in argv[:2])
    return max(1, (os.cpu_count() or 4) // max(1, runs))


def key(text: str) -> str:
    """A rough sound of the words, for lining a transcript up with the
    text: no accents, case, spaces or punctuation; æ and œ as e, j and y
    as i, no h, ph as f, k and q as c, doubled letters single."""
    t = unicodedata.normalize("NFD", text.lower())
    t = "".join(c for c in t if not unicodedata.combining(c))
    t = t.replace("æ", "e").replace("œ", "e").replace("ae", "e").replace("oe", "e")
    t = t.replace("ph", "f").replace("j", "i").replace("y", "i").replace("h", "")
    t = t.replace("k", "c").replace("q", "c").replace("w", "v")
    t = re.sub(r"[^a-z]", "", t)
    return re.sub(r"(.)\1+", r"\1", t)


def unloop(heard: str) -> str:
    """A transcript with Whisper's repetition loops cut back: a word heard
    LOOP times or more running ("yār yār yār …" over a whole verse) is
    Whisper stuck, not the cantor, since the most any chant here sings a
    word in a row is six Alleluias (O Fílii). Two are kept, for a word the
    text repeats itself ("Virgo: Virgo:")."""
    runs = []
    for w in heard.split():
        if runs and key(w) == key(runs[-1][0]):
            runs[-1].append(w)
        else:
            runs.append([w])
    return " ".join(" ".join(r[:2] if len(r) >= LOOP else r) for r in runs)


def heard_breaks(lines: list, heard: list) -> list:
    """For every break between two lines, what the transcripts say of it:
    "wrong" when Whisper heard words of one line in the phrase the other
    was laid over, "heard" when it heard the end of the one line and the
    start of the next each in its own phrase, else None (it heard too
    little to tell). The transcripts are aligned with the text letter by
    letter (Levenshtein), and only runs of RUN letters or more that agree
    exactly count as heard, so a garbled phrase proves nothing either way."""
    from rapidfuzz.distance import Levenshtein
    text_keys = [key(l) for l in lines]
    heard_keys = [key(unloop(h)) for h in heard]
    T, A = "".join(text_keys), "".join(heard_keys)
    line_of = [i for i, k in enumerate(text_keys) for _ in k]
    phrase_of = [i for i, k in enumerate(heard_keys) for _ in k]
    starts, t = [], 0
    for k in text_keys:
        starts.append(t)
        t += len(k)
    starts.append(t)
    # Every letter of an exact run, cut where the run crosses a break of
    # either kind, as (text position, phrase heard there, piece length,
    # run length). A break is wrong on a piece of two letters or more cut
    # from a run of RUN or more: a piece of one proves nothing, since
    # Whisper often begins a phrase on an "n" the voice hummed before it.
    # A break is heard on pieces of three or more on both sides.
    matched = []
    for op in Levenshtein.opcodes(A, T):
        run = op.src_end - op.src_start
        if op.tag != "equal" or run < 3:
            continue
        piece = []
        for k in range(run + 1):
            here = None if k == run else (
                op.dest_start + k, phrase_of[op.src_start + k], line_of[op.dest_start + k])
            if piece and (here is None or here[1:] != piece[-1][1:]):
                matched += [(pos, ph, len(piece), run) for pos, ph, _ in piece]
                piece = []
            if here is not None:
                piece.append(here)
    def overlap(a: str, b: str) -> int:
        return max((n for n in range(1, min(len(a), len(b)) + 1) if a[-n:] == b[:n]), default=0)

    out = []
    for b in range(len(lines) - 1):
        cut = starts[b + 1]
        # Two cases prove nothing: lines of the same words either side (an
        # "ij." repeat, where an unheard twin lets the other's letters land
        # on either), and letters the one line ends on and the next begins
        # with ("Altíssimi | miserére": "mi" may be either side)
        same = text_keys[b] == text_keys[b + 1]
        shared = overlap(text_keys[b], text_keys[b + 1])
        wrong = not same and any(
            ((pos < cut - SLACK and ph > b) or (pos >= cut + SLACK and ph <= b))
            and not cut - shared <= pos < cut + shared
            for pos, ph, n, run in matched
            if n >= 2 and run >= RUN and (ph in (b, b + 1) or line_of[pos] in (b, b + 1)))
        before = any(ph == b and line_of[pos] == b and pos >= cut - NEAR
                     for pos, ph, n, _ in matched if n >= 3)
        after = any(ph == b + 1 and line_of[pos] == b + 1 and pos < cut + NEAR
                    for pos, ph, n, _ in matched if n >= 3)
        out.append("wrong" if wrong else "heard" if before and after else None)
    return out


RUN = 4         # letters in a row that must agree for a transcript to count
SLACK = 0       # letters a heard break may stray from the text's
NEAR = 14       # letters from the break within which an agreeing run confirms it
LOOP = 7        # one word heard this many times running is Whisper looping


# ---------------------------------------------------------------- text

def read_src(chant: str) -> tuple:
    path = SRC / f"{chant}.txt"
    settings, lines, body = dict(DEFAULTS), [], False
    for raw in path.read_text("utf-8").splitlines():
        line = raw.split("#", 1)[0].strip() if not body else raw.strip()
        if body and line.startswith("#"):
            continue
        if not line:
            body = body or bool(settings) and raw.strip() == ""
            continue
        if not body and re.fullmatch(r"[a-z]+\s+-?[\d.]+", line):
            k, v = line.split()
            if k not in DEFAULTS:
                sys.exit(f"{chant}: unknown setting {k}")
            settings[k] = float(v)
            continue
        body = True
        part = re.fullmatch(r"part\s+(\d+)", line)
        if part:
            settings["_part"] = int(part.group(1))
            settings["_parts"] = True
            continue
        if line == "~":
            if not lines:
                sys.exit(f"{chant}: ~ before any line")
            lines[-1][2] += 1
            continue
        if "|" not in line:
            sys.exit(f"{chant}: a line without its English: {line}")
        latin, english = (s.strip() for s in line.split("|", 1))
        lines.append([latin, english, 1, settings.get("_part")])
    return settings, lines


# ---------------------------------------------------------------- commands

def probe(chant: str, args: list):
    s = dict(DEFAULTS)
    for flag, k in (("--noise", "noise"), ("--gap", "gap"), ("--merge", "merge")):
        if flag in args:
            s[k] = float(args[args.index(flag) + 1])
    sound, total = phrases(chant, s["noise"], s["gap"], s["merge"])
    heard = hear(chant, sound) if "--no-asr" not in args else None
    print(f"{chant}: {len(sound)} phrases in {total:.1f}s  (noise {s['noise']:g} dB, gap {s['gap']:g}s, merge {s['merge']:g}s)")
    for i, (a, b) in enumerate(sound):
        flag = "" if MIN_LINE <= b - a <= MAX_LINE else "  <-- length"
        print(f"{i + 1:3d} {a:7.2f} {b:7.2f} {b - a:5.1f}s  {heard[i] if heard else ''}{flag}")


def check(chant: str) -> tuple:
    """(json, problems) for one chant."""
    settings, lines = read_src(chant)
    found, total = phrases(chant, settings["noise"], settings["gap"], settings["merge"])
    problems = []
    wanted = sum(l[2] for l in lines)
    if len(found) != wanted:
        problems.append(f"{len(found)} phrases in the recording, {wanted} in the text")
        return None, problems
    # a line written over several phrases (a "~" under it) takes them all
    sound, heard_found, k = [], hear(chant, found), 0
    heard = [] if heard_found is not None else None
    for _, _, span, _ in lines:
        sound.append([found[k][0], found[k + span - 1][1]])
        if heard is not None:
            heard.append(" ".join(heard_found[k:k + span]))
        k += span
    for i, (a, b) in enumerate(sound):
        if not MIN_LINE <= b - a <= MAX_LINE:
            problems.append(f"line {i + 1} is {b - a:.1f}s long: {lines[i][0]}")
    verified = "unheard"
    if heard is not None:
        breaks = heard_breaks([l[0] for l in lines], heard)
        for i, verdict in enumerate(breaks):
            if verdict == "wrong":
                problems.append(f"Whisper hears the break after line {i + 1} elsewhere:"
                                f" {lines[i][0]!r} / {lines[i + 1][0]!r}")
        verified = f"{breaks.count('heard')} of {len(breaks)} breaks heard"
    method = (f"breaths by loudness (under {settings['noise']:g} dB for {settings['gap']:g} s, "
              f"phrases under {settings['merge']:g} s merged) + text alignment; Whisper: {verified}")
    if settings.get("_parts"):
        count = score_parts(chant)
        for i, l in enumerate(lines):
            if l[3] is None:
                problems.append(f"line {i + 1} has no score part (a `part N` above it)")
            elif count is not None and not 0 <= l[3] < count:
                problems.append(f"line {i + 1} is on part {l[3]}, but the score has {count}")
    out = {"id": chant, "part": None, "method": method, "lines": [
        dict({"latin": la, "english": en, "start": a, "end": b},
             **({"part": part} if settings.get("_parts") else {}))
        for (la, en, _, part), (a, b) in zip(lines, padded(chant, sound, total))]}
    return out, problems


def score_parts(chant: str):
    """How many score parts the catalog gives the chant, or None."""
    catalog = ROOT / "app" / "Data" / "ChantCatalogData.swift"
    if not catalog.exists():
        return None
    m = re.search(r'^ {12}id: "' + re.escape(chant) + r'",(.*?)sourceURL', catalog.read_text("utf-8"), re.S | re.M)
    return len(re.findall(r"ChantScorePart\(", m.group(1))) if m else None


def build(chants: list):
    ids = {c["id"] for c in json.loads(CHANTS.read_text("utf-8"))["chants"]}
    chants = chants or sorted(p.stem for p in SRC.glob("*.txt"))
    failed = 0
    for chant in chants:
        if chant not in ids:
            sys.exit(f"{chant}: not a chant in {CHANTS}")
        out, problems = check(chant)
        dest = TOOL / f"{chant}.json"
        if problems:
            failed += 1
            dest.unlink(missing_ok=True)
            print(f"✗ {chant}")
            for p in problems:
                print(f"    {p}")
            continue
        dest.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", "utf-8")
        print(f"✓ {chant}: {len(out['lines'])} lines; {out['method'].split('Whisper: ')[1]}")
    if failed:
        sys.exit(f"{failed} chant(s) left out")


def score(names: list):
    import cairosvg
    for name in names:
        text = zlib.decompress((SCORES / f"{name}.lvscore").read_bytes(), -15).decode()
        rows = text.split("\n")
        paint = []
        for row in rows[2:]:
            if not row.strip():
                continue
            kind, data = row.split(" ", 1)
            for d in data.split("|"):
                if kind in ("I", "R", "W"):
                    fill = {"I": "#000", "R": "#c00", "W": "#fff"}[kind]
                    paint.append(f'<path d="{d}" fill="{fill}"/>')
                else:
                    stroke = "#000" if kind[0] == "S" else "#c00"
                    paint.append(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{kind[1:]}"/>')
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{rows[1]}">'
               f'<rect x="-1e5" y="-1e5" width="2e5" height="2e5" fill="#fff"/>{"".join(paint)}</svg>')
        out = CACHE / "scores" / f"{name}.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        cairosvg.svg2png(bytestring=svg.encode(), write_to=str(out), output_width=1600)
        print(out)


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in ("probe", "build", "score"):
        sys.exit(__doc__)
    cmd, rest = sys.argv[1], sys.argv[2:]
    if cmd == "probe":
        probe(rest[0], rest[1:])
    elif cmd == "build":
        build([r for r in rest if not r.startswith("-")])
    else:
        score(rest)
