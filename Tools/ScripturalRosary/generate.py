#!/usr/bin/env python3
"""Generate app/Data/ScripturalRosaryData.swift from the Original
Douay-Rheims Bible API (https://thedouayrheims.com — CC0).

The verse *selections* are curated here, in REFERENCES: for each mystery,
a walk through the scene in Scripture, one verse per Hail Mary bead
(ten per mystery; seven per sorrow for the Seven Sorrows chaplet, which
prays seven Hail Marys per sorrow). Mysteries with little direct
narrative (the Assumption, the Coronation) use the verses the Church's
own liturgy has always read of Our Lady — Canticles, the Psalms,
Judith, Ecclesiasticus, the Apocalypse.

Usage:
    python3 generate.py            # downloads books into cache/, writes the Swift file
    python3 generate.py --check    # regenerate and diff against the checked-in file

Book JSONs are cached in cache/ (gitignored); delete it to re-download.
"""

import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
CACHE = TOOL_DIR / "cache"
OUTPUT = TOOL_DIR.parent.parent / "app" / "Data" / "ScripturalRosaryData.swift"
BASE_URL = "https://thedouayrheims.com/data/odr"

# Slug -> the name a reference line prints. Douay-Rheims names throughout.
BOOK_NAMES = {
    "matthew": "Matthew",
    "mark": "Mark",
    "luke": "Luke",
    "john": "John",
    "acts": "Acts",
    "romans": "Romans",
    "1-corinthians": "1 Corinthians",
    "1-peter": "1 Peter",
    "2-peter": "2 Peter",
    "apocalypse": "Apocalypse",
    "psalms": "Psalm",
    "proverbs": "Proverbs",
    "canticle-of-canticles": "Canticles",
    "wisdom": "Wisdom",
    "ecclesiasticus": "Ecclesiasticus",
    "isaie": "Isaias",
    "lamentations": "Lamentations",
    "judith": "Judith",
    "james": "James",
    "zacharias": "Zacharias",
}

# key ("<category>_<order>") -> [(slug, chapter, verse), ...]
# A 4-tuple (slug, chapter, first, last) joins consecutive verses into
# one bead, for the places where the edition's verse break would leave
# a bead hanging mid-sentence.
# Ten per mystery; seven per sorrow. Order within a list is bead order.
REFERENCES = {
    # ── Joyful ────────────────────────────────────────────────────────
    "joyful_1": [  # The Annunciation — Luke 1
        ("luke", 1, 26), ("luke", 1, 27), ("luke", 1, 28), ("luke", 1, 30),
        ("luke", 1, 31), ("luke", 1, 32), ("luke", 1, 34), ("luke", 1, 35),
        ("luke", 1, 37), ("luke", 1, 38),
    ],
    "joyful_2": [  # The Visitation — Luke 1
        ("luke", 1, 39), ("luke", 1, 41), ("luke", 1, 42), ("luke", 1, 43),
        ("luke", 1, 44), ("luke", 1, 45), ("luke", 1, 46), ("luke", 1, 47),
        ("luke", 1, 48), ("luke", 1, 49),
    ],
    "joyful_3": [  # The Nativity — Luke 2
        ("luke", 2, 1), ("luke", 2, 4), ("luke", 2, 6), ("luke", 2, 7),
        ("luke", 2, 8), ("luke", 2, 9), ("luke", 2, 10), ("luke", 2, 11),
        ("luke", 2, 14), ("luke", 2, 19),
    ],
    "joyful_4": [  # The Presentation — Luke 2
        ("luke", 2, 22), ("luke", 2, 25), ("luke", 2, 26), ("luke", 2, 27),
        ("luke", 2, 28), ("luke", 2, 29), ("luke", 2, 30), ("luke", 2, 32),
        ("luke", 2, 34), ("luke", 2, 35),
    ],
    "joyful_5": [  # The Finding in the Temple — Luke 2
        ("luke", 2, 42), ("luke", 2, 43), ("luke", 2, 45), ("luke", 2, 46),
        ("luke", 2, 47), ("luke", 2, 48), ("luke", 2, 49), ("luke", 2, 50),
        ("luke", 2, 51), ("luke", 2, 52),
    ],

    # ── Sorrowful ─────────────────────────────────────────────────────
    "sorrowful_1": [  # The Agony in the Garden — Matthew 26, Luke 22
        ("matthew", 26, 36), ("matthew", 26, 37), ("matthew", 26, 38),
        ("matthew", 26, 39), ("matthew", 26, 40), ("matthew", 26, 41),
        ("matthew", 26, 42), ("luke", 22, 43), ("luke", 22, 44),
        ("matthew", 26, 46),
    ],
    "sorrowful_2": [  # The Scourging — the trial, then the Prophet
        ("luke", 23, 4), ("luke", 23, 16), ("matthew", 27, 24),
        ("matthew", 27, 26), ("isaie", 53, 3), ("isaie", 53, 4),
        ("isaie", 53, 5), ("isaie", 53, 6), ("isaie", 53, 7),
        ("1-peter", 2, 24),
    ],
    "sorrowful_3": [  # The Crowning with Thorns — Matthew 27, John 19
        ("matthew", 27, 27), ("matthew", 27, 28), ("matthew", 27, 29),
        ("matthew", 27, 30), ("isaie", 50, 6), ("john", 19, 5),
        ("john", 19, 6), ("john", 19, 14), ("john", 19, 15),
        ("matthew", 27, 31),
    ],
    "sorrowful_4": [  # The Carrying of the Cross — John 19, Luke 23
        ("john", 19, 16), ("john", 19, 17), ("luke", 23, 26),
        ("luke", 23, 27), ("luke", 23, 28), ("luke", 23, 31),
        ("lamentations", 1, 12), ("luke", 9, 23), ("matthew", 11, 29),
        ("matthew", 11, 30),
    ],
    "sorrowful_5": [  # The Crucifixion — Luke 23, John 19, Matthew 27
        ("luke", 23, 33), ("luke", 23, 34), ("luke", 23, 42),
        ("luke", 23, 43), ("john", 19, 26), ("john", 19, 27),
        ("matthew", 27, 46), ("john", 19, 28), ("john", 19, 30),
        ("luke", 23, 46),
    ],

    # ── Glorious ──────────────────────────────────────────────────────
    "glorious_1": [  # The Resurrection
        ("matthew", 28, 1), ("matthew", 28, 2), ("matthew", 28, 5),
        ("matthew", 28, 6), ("luke", 24, 5), ("john", 20, 16),
        ("john", 20, 19), ("john", 20, 27), ("john", 20, 29),
        ("romans", 6, 9),
    ],
    "glorious_2": [  # The Ascension
        ("john", 14, 2), ("john", 14, 3), ("matthew", 28, 18),
        ("matthew", 28, 19), ("matthew", 28, 20), ("mark", 16, 15),
        ("acts", 1, 9), ("acts", 1, 10), ("acts", 1, 11),
        ("mark", 16, 19),
    ],
    "glorious_3": [  # The Descent of the Holy Ghost
        ("john", 14, 16), ("john", 14, 26), ("acts", 1, 14),
        ("acts", 2, 1), ("acts", 2, 2), ("acts", 2, 3),
        ("acts", 2, 4), ("acts", 2, 38), ("acts", 2, 41),
        ("romans", 5, 5),
    ],
    "glorious_4": [  # The Assumption — the liturgy's own verses of Mary
        ("canticle-of-canticles", 2, 10), ("canticle-of-canticles", 2, 11),
        ("canticle-of-canticles", 2, 12), ("canticle-of-canticles", 4, 7),
        ("psalms", 131, 8), ("judith", 13, 23), ("luke", 1, 48),
        ("luke", 1, 49), ("1-corinthians", 15, 54), ("apocalypse", 21, 4),
    ],
    "glorious_5": [  # The Coronation
        ("apocalypse", 12, 1), ("canticle-of-canticles", 4, 8),
        ("psalms", 44, 11), ("psalms", 44, 12), ("judith", 15, 10),
        ("ecclesiasticus", 24, 17), ("ecclesiasticus", 24, 24),
        ("proverbs", 8, 35), ("luke", 1, 52), ("james", 1, 12),
    ],

    # ── Luminous ──────────────────────────────────────────────────────
    "luminous_1": [  # The Baptism in the Jordan
        ("matthew", 3, 13), ("matthew", 3, 14), ("matthew", 3, 15),
        ("matthew", 3, 16), ("matthew", 3, 17), ("john", 1, 29),
        ("john", 1, 32), ("isaie", 42, 1), ("john", 3, 5),
        ("acts", 10, 38),
    ],
    "luminous_2": [  # The Wedding at Cana — John 2
        ("john", 2, 1), ("john", 2, 2), ("john", 2, 3), ("john", 2, 4),
        ("john", 2, 5), ("john", 2, 6), ("john", 2, 7), ("john", 2, 8),
        ("john", 2, 9, 10), ("john", 2, 11),
    ],
    "luminous_3": [  # The Proclamation of the Kingdom
        ("mark", 1, 14), ("mark", 1, 15), ("matthew", 5, 3),
        ("matthew", 5, 8), ("matthew", 6, 33), ("matthew", 13, 44),
        ("matthew", 11, 28), ("luke", 17, 21), ("john", 8, 12),
        ("matthew", 9, 35),
    ],
    "luminous_4": [  # The Transfiguration — Matthew 17, Luke 9
        ("matthew", 17, 1), ("matthew", 17, 2), ("luke", 9, 30),
        ("luke", 9, 31), ("matthew", 17, 4), ("matthew", 17, 5),
        ("matthew", 17, 6), ("matthew", 17, 7), ("2-peter", 1, 17),
        ("john", 1, 14),
    ],
    "luminous_5": [  # The Institution of the Eucharist
        ("john", 13, 1), ("john", 6, 35), ("john", 6, 51),
        ("john", 6, 55), ("john", 6, 57), ("matthew", 26, 26),
        ("matthew", 26, 27), ("matthew", 26, 28), ("luke", 22, 19),
        ("1-corinthians", 11, 26),
    ],

    # ── Seven Sorrows (seven Hail Marys per sorrow) ───────────────────
    "seven_sorrows_1": [  # The Prophecy of Simeon — Luke 2
        ("luke", 2, 25), ("luke", 2, 26), ("luke", 2, 27),
        ("luke", 2, 28, 29), ("luke", 2, 33), ("luke", 2, 34),
        ("luke", 2, 35),
    ],
    "seven_sorrows_2": [  # The Flight into Egypt — Matthew 2
        ("matthew", 2, 13), ("matthew", 2, 14), ("matthew", 2, 15),
        ("matthew", 2, 16), ("matthew", 2, 18), ("matthew", 2, 19, 20),
        ("matthew", 2, 21),
    ],
    "seven_sorrows_3": [  # The Loss of Jesus in the Temple — Luke 2
        ("luke", 2, 43), ("luke", 2, 44), ("luke", 2, 45),
        ("luke", 2, 46), ("luke", 2, 48), ("luke", 2, 49),
        ("luke", 2, 51),
    ],
    "seven_sorrows_4": [  # Mary Meets Jesus Carrying the Cross
        ("luke", 23, 26), ("luke", 23, 27), ("luke", 23, 28),
        ("lamentations", 1, 12), ("lamentations", 1, 16),
        ("lamentations", 2, 13), ("isaie", 53, 4),
    ],
    "seven_sorrows_5": [  # The Crucifixion — John 19
        ("john", 19, 18), ("john", 19, 25), ("john", 19, 26),
        ("john", 19, 27), ("john", 19, 28), ("john", 19, 30),
        ("luke", 23, 46),
    ],
    "seven_sorrows_6": [  # Jesus Taken Down from the Cross
        ("john", 19, 33), ("john", 19, 34), ("john", 19, 37),
        ("john", 19, 38), ("john", 19, 39), ("zacharias", 12, 10),
        ("lamentations", 2, 11),
    ],
    "seven_sorrows_7": [  # The Burial of Jesus
        ("john", 19, 40), ("john", 19, 41), ("john", 19, 42),
        ("matthew", 27, 60), ("matthew", 27, 61), ("luke", 23, 55),
        ("luke", 23, 56),
    ],
}


def load_book(slug: str) -> dict:
    """One book of the Douay-Rheims, from cache/ or the API.

    The download lands in a temp file and is parsed before it replaces
    the cached one, so an interrupted run — or a captive portal serving
    a 200 of HTML — cannot leave a half-written file that every later
    run reuses and dies on with a JSONDecodeError naming no path.

    Encodings are explicit everywhere: the source carries "Caesar" as
    "Cesar" with an ash, and Python's text I/O otherwise follows the
    locale, which mangles it silently under a Latin-1 LANG.
    """
    CACHE.mkdir(exist_ok=True)
    path = CACHE / f"{slug}.json"
    if not path.exists():
        url = f"{BASE_URL}/{slug}.json"
        print(f"  downloading {url}")
        tmp = path.with_suffix(".json.part")
        with urllib.request.urlopen(url, timeout=30) as resp:
            tmp.write_bytes(resp.read())
        try:
            json.loads(tmp.read_text(encoding="utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            tmp.unlink(missing_ok=True)
            raise SystemExit(f"{url}: not JSON ({error})")
        tmp.replace(path)
    return json.loads(path.read_text(encoding="utf-8"))


def clean(text: str) -> str:
    """Reading text, not an apparatus: strip the edition's footnote and
    marginal-note markers, its HTML, and normalize the ampersands. A
    bead stands alone, so its first letter is capitalized even where
    the verse break falls mid-sentence."""
    text = re.sub(r"\[\d+\]", "", text)        # footnote refs: [1]
    text = re.sub(r"\([a-z]{1,2}\)", "", text)  # marginal letters: (a)
    text = re.sub(r"<[^>]+>", "", text)         # any markup
    text = text.replace("&amp;", "&").replace("&", "and")
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"\s+([,.;:?!])", r"\1", text)  # space left by a marker
    return text


def verse_text(books: dict, slug: str, chapter: int, first: int,
               last: int | None = None) -> str:
    book = books[slug]
    for ch in book["chapters"]:
        if ch["chapter"] == chapter:
            wanted = range(first, (last or first) + 1)
            texts = [clean(v["text"]) for v in ch["verses"] if v["verse"] in wanted]
            if len(texts) == len(wanted):
                # A verse that follows a full stop opens a sentence.
                for i in range(1, len(texts)):
                    if texts[i - 1].rstrip()[-1:] in ".?!" and texts[i][:1].islower():
                        texts[i] = texts[i][0].upper() + texts[i][1:]
                joined = " ".join(texts)
                # A bead stands alone, so it opens with a capital even
                # where the edition's verse break fell mid-sentence.
                if joined and joined[0].islower():
                    joined = joined[0].upper() + joined[1:]
                return joined
    raise SystemExit(f"MISSING: {slug} {chapter}:{first}-{last or first}")


def swift_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def generate() -> str:
    slugs = {ref[0] for refs in REFERENCES.values() for ref in refs}
    books = {slug: load_book(slug) for slug in sorted(slugs)}

    lines = []
    lines.append("//")
    lines.append("//  ScripturalRosaryData.swift")
    lines.append("//  Lumen Viae")
    lines.append("//")
    lines.append("//  GENERATED by Tools/ScripturalRosary/generate.py — edit the")
    lines.append("//  curated references there and regenerate; never by hand here.")
    lines.append("//")
    lines.append("//  A scripture verse for every bead: the Scriptural Rosary walks")
    lines.append("//  each mystery through the sacred page itself, one verse per")
    lines.append("//  Hail Mary. Text is the Douay-Rheims (public domain, CC0 via")
    lines.append("//  thedouayrheims.com), bundled so prayer never needs a signal.")
    lines.append("//")
    lines.append("")
    lines.append("import Foundation")
    lines.append("")
    lines.append("// MARK: - ScripturalVerse")
    lines.append("")
    lines.append("/// One verse of Scripture prayed on one bead.")
    lines.append("struct ScripturalVerse: Hashable {")
    lines.append("    /// Douay-Rheims citation, e.g. \"Luke 1:28\"")
    lines.append("    let reference: String")
    lines.append("    /// The verse itself, Douay-Rheims text")
    lines.append("    let text: String")
    lines.append("}")
    lines.append("")
    lines.append("// MARK: - ScripturalRosaryData")
    lines.append("")
    lines.append("/// Verse-per-bead sets keyed \"<category>_<order>\", the same key")
    lines.append("/// MysteryData uses for its fruits. Ten verses per mystery; seven")
    lines.append("/// per sorrow of the Seven Sorrows chaplet.")
    lines.append("enum ScripturalRosaryData {")
    lines.append("")
    lines.append("    /// Verses for one mystery, in bead order — nil when no set")
    lines.append("    /// has been curated for the key, and the prayer screen simply")
    lines.append("    /// stays as it was.")
    lines.append("    static func verses(category: String, order: Int) -> [ScripturalVerse]? {")
    lines.append("        all[\"\\(category)_\\(order)\"]")
    lines.append("    }")
    lines.append("")
    lines.append("    static let all: [String: [ScripturalVerse]] = [")

    for key in REFERENCES:
        refs = REFERENCES[key]
        lines.append(f'        "{key}": [')
        for entry in refs:
            slug, ch, first = entry[0], entry[1], entry[2]
            last = entry[3] if len(entry) == 4 else None
            span = f"{first}-{last}" if last else f"{first}"
            ref = f"{BOOK_NAMES[slug]} {ch}:{span}"
            text = verse_text(books, slug, ch, first, last)
            lines.append(
                f'            ScripturalVerse(reference: "{ref}", '
                f'text: "{swift_escape(text)}"),'
            )
        lines.append("        ],")

    lines.append("    ]")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="regenerate and diff against the checked-in file")
    args = parser.parse_args()

    output = generate()
    counts = {k: len(v) for k, v in REFERENCES.items()}
    total = sum(counts.values())
    print(f"{len(REFERENCES)} mysteries, {total} verses")

    for key, n in counts.items():
        expected = 7 if key.startswith("seven_sorrows") else 10
        if n != expected:
            raise SystemExit(f"{key}: {n} verses, expected {expected}")

    if args.check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current != output:
            raise SystemExit(f"{OUTPUT} is stale — rerun generate.py")
        print("up to date")
        return

    OUTPUT.write_text(output, encoding="utf-8")
    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    main()
