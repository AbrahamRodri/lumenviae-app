#!/usr/bin/env python3
"""Exports the Prayer Book's prayers for the server to record.

The app owns the words (app/Data/PrayerBook/*.swift, and the consecration's
hymns and litanies in app/Data/BilingualConsecrationPrayers.swift). The
server records each prayer with ElevenLabs in every narration voice
(LumenViae.Rosary.PrayerAudio, kind `book`) from this export, so what is
heard is what is on the page. The Rosary's own prayers — the Our Father,
the Memorare — are left out: the server already records them as `prayers`,
and the app plays those recordings for the book too.

Each prayer's text is turned into what a narrator says:

- the book's marks go (℣ ℟ ✠, a canticle's mediant asterisk, "N." for a name)
- a litany's response, stated once at the head of its group, is said after
  every invocation beneath it, as a litany is prayed
- "[Let us pray.]" is said; so are the directions of the guided texts (the
  examens, making a confession), which are what those texts are for;
  gestures ("strike the breast", "here all genuflect") are not
- a prayer with seasonal alternatives (the Alma Redemptoris) is recorded
  with its first only
- stanzas stay apart (a blank line between them), which the server turns
  into a pause in each voice's own pause syntax

Usage:
    python3 Tools/PrayerBook/export.py            # writes Tools/PrayerBook/prayer_book.json
    python3 Tools/PrayerBook/export.py --check    # exits 1 if the file is stale

Copy the output to the server verbatim:
    cp Tools/PrayerBook/prayer_book.json ../../personal/lumenviae/priv/rosary_audio/prayer_book.json
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BOOK_DIR = ROOT / "app" / "Data" / "PrayerBook"
CONSECRATION = ROOT / "app" / "Data" / "BilingualConsecrationPrayers.swift"
ROSARY = ROOT / "app" / "Data" / "RosaryPrayers.swift"
OUT = pathlib.Path(__file__).resolve().parent / "prayer_book.json"

# The consecration's prayers the book carries (PrayerBook.bundled)
CONSECRATION_IDS = [
    "veni_creator", "ave_maris_stella", "magnificat",
    "litany_loreto", "litany_holy_name", "o_jesus_living_in_mary",
]

# Texts whose directions are the prayer: said aloud as guidance
GUIDED = {
    "examen", "examination_of_conscience", "the_confession",
    "after_confession", "three_hail_marys",
}

# Rubrics that open a seasonal alternative: the recording stops there
ALTERNATIVE = re.compile(r"^\[(From Christmas|A Nativitate)")

# Gestures and seasonal headings never said
SILENT = re.compile(r"^\[(Strike the breast|Here all|In Advent|Tempore|Hic |Percutit|At night)", re.I)

BLOCK = r'"""\n(.*?)\n\s*"""'


def book_entries():
    for path in sorted(BOOK_DIR.glob("*.swift")):
        src = path.read_text(encoding="utf-8")
        for body in re.findall(r"BookPrayer\(\s*\n(.*?)\n\s*\)(?=,?\s*\n\s*(?:BookPrayer\(|\]))", src, re.S):
            pid = re.search(r'\bid:\s*"([^"]+)"', body).group(1)
            title = re.search(r'\btitle:\s*"((?:[^"\\]|\\.)*)"', body).group(1)
            english = re.search(r"\benglish:\s*" + BLOCK, body, re.S).group(1)
            yield pid, title, english


def consecration_entries():
    src = CONSECRATION.read_text(encoding="utf-8")
    for pid in CONSECRATION_IDS:
        m = re.search(
            r'id:\s*"' + re.escape(pid) + r'".*?englishTitle:\s*"((?:[^"\\]|\\.)*)".*?englishContent:\s*' + BLOCK,
            src, re.S,
        )
        if not m:
            raise SystemExit(f"could not find {pid} in {CONSECRATION.name}")
        yield pid, m.group(1), m.group(2)


def rosary_ids():
    return set(re.findall(r'id:\s*"([a-z_]+)"', ROSARY.read_text(encoding="utf-8")))


def rubric_words(line):
    return line.strip()[1:-1].strip()


def is_rubric(line):
    s = line.strip()
    return s.startswith("[") and s.endswith("]")


def joined(invocation, response):
    """An invocation and its response as they are said: a comma between
    them, unless the invocation is a sentence of its own ("Christ, hear
    us." — "Christ, graciously hear us.")"""
    invocation = invocation.strip().rstrip(",;").strip()
    return f"{invocation} {response}" if invocation.endswith((".", "!", "?")) else f"{invocation}, {response}"


def clean(line):
    # A blank the reader fills — "It has been [time] since…" — is a pause
    line = re.sub(r"\s*\[[^\]]*\]\s*", " … ", line) if "[" in line else line
    line = line.replace("℣.", "").replace("℟.", "").replace("℣", "").replace("℟", "")
    line = line.replace("✠", "").replace(" * ", " ")
    line = re.sub(r"\s+N\.(?=,)", "", line)       # "Thy servant N., whom" -> "Thy servant, whom"
    line = re.sub(r"\s+N\.(?=\s|$)", ".", line)    # "our Pope N." -> "our Pope."
    line = re.sub(r"\.\.$", ".", line)
    line = re.sub(r"\s+([,.;:])", r"\1", line.replace(" … ", " …  "))
    return re.sub(r"\s{2,}", " ", line).strip()


def speech(pid, english):
    stanzas = []
    current = []
    response = None
    stopped = False

    def flush():
        nonlocal current, response
        if current:
            stanzas.append(" ".join(current))
        current = []
        response = None

    for raw in english.split("\n"):
        line = raw.strip()
        if not line:
            flush()
            continue
        if is_rubric(line):
            if ALTERNATIVE.match(line):
                stopped = True
                break
            words = rubric_words(line)
            if words.lower().rstrip(".") in ("let us pray", "oremus"):
                current.append("Let us pray.")
            elif pid in GUIDED and not SILENT.match(line):
                current.append(words if words.endswith((".", ":", "?")) else words + ".")
            continue
        if "℟." in line and not line.startswith("℟"):
            invocation, _, answer = line.partition("℟.")
            response = answer.strip()
            current.append(clean(joined(invocation, response)))
        elif response and not line.startswith(("℣", "℟")):
            current.append(clean(joined(line, response)))
        else:
            current.append(clean(line))
    flush()
    return "\n\n".join(s for s in stanzas if s)


def main():
    skip = rosary_ids()
    seen = set()
    prayers = []
    for pid, title, english in list(book_entries()) + list(consecration_entries()):
        if pid in skip or pid in seen:
            continue
        seen.add(pid)
        text = speech(pid, english)
        if not text:
            raise SystemExit(f"{pid}: nothing to say")
        prayers.append({"id": pid, "title": title.replace('\\"', '"'), "text": text})

    prayers.sort(key=lambda p: p["id"])
    data = {
        "generated_by": "Tools/PrayerBook/export.py (the Lumen Viae app)",
        "prayers": prayers,
    }
    out = json.dumps(data, ensure_ascii=False, indent=2) + "\n"

    if "--check" in sys.argv:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != out:
            print("prayer_book.json is stale: run Tools/PrayerBook/export.py")
            sys.exit(1)
        print("prayer_book.json is current")
        return

    OUT.write_text(out, encoding="utf-8")
    chars = sum(len(p["text"]) for p in prayers)
    print(f"{len(prayers)} prayers, {chars} characters -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
