#!/usr/bin/env python3
"""Build the bundled TrueDevotionBook.json from the proofread chapter files.

The chapter text in ./chapters is the source of truth. Edit those files, then
re-run this script — never hand-edit the generated JSON.

    python3 Tools/TrueDevotion/build_book.py

Exits non-zero without writing if a chapter is missing or a paragraph looks
like it still carries scan damage.
"""

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
CHAPTERS_DIR = os.path.join(HERE, 'chapters')
OUT = os.path.join(REPO, 'app', 'Resources', 'TrueDevotionBook.json')

BOOK = {
    'title': "True Devotion to the Blessed Virgin",
    'author': "St. Louis-Marie Grignion de Montfort",
    'translator': "Translated by Fr. Frederick William Faber, D.D. (1862)",
    'sourceNote': "From the twelfth London edition of 1904. This translation is in the public domain.",
    'parts': [
        {'number': 1, 'title': "Part I — On Devotion to Our Lady in General"},
        {'number': 2, 'title': "Part II — The Perfect Consecration to Jesus by Mary"},
    ],
}

# (file stem, part number, display title). Order here is reading order, and
# the stems are persisted in users' reading progress — never rename one.
CHAPTERS = [
    ('introduction',    0, "Introduction"),
    ('necessity',       1, "The Necessity of Devotion to Our Lady"),
    ('discernment',     1, "Five Fundamental Truths"),
    ('false-devotions', 1, "False Devotions to Our Lady"),
    ('characters',      1, "The Marks of True Devotion"),
    ('preliminary',     2, "Preliminary Observations"),
    ('consists',        2, "What Perfect Consecration Consists In"),
    ('motives',         2, "Motives for This Devotion"),
    ('figure',          2, "The Figure of Jacob and Rebecca"),
    ('effects',         2, "Wonderful Effects of This Devotion"),
    ('practices',       2, "Particular Practices"),
    ('communion',       2, "This Devotion at Holy Communion"),
    ('formula',         2, "The Act of Consecration"),
]

# Characters that survive from a bad scan but never occur in Faber's prose.
# Square brackets are excluded on purpose: Faber uses them for his own
# translator's interpolations, e.g. "[the history of Jacob and Esau]".
SCAN_DAMAGE = re.compile(r'[<>|@\\{}~^]|\s[a-z]\s[a-z]\s|\.\.\s')

# Running heads from the printed page, if any survived the cleanup pass.
PAGE_FURNITURE = re.compile(r'TRUE DEVOTION TO\b|THE BLESSED VIRGIN\.\s*\d|Digitized by')


def parse_chapter(text):
    """Split a chapter file into paragraphs. A line beginning '## ' is a
    subheading; blank lines separate paragraphs."""
    paragraphs = []
    for block in re.split(r'\n\s*\n', text):
        block = re.sub(r'\s+', ' ', block.strip())
        if not block:
            continue
        kind = 'text'
        if block.startswith('## '):
            kind = 'subheading'
            block = block[3:].strip()
        paragraphs.append({'id': len(paragraphs), 'kind': kind, 'text': block})
    return paragraphs


def main():
    book = dict(BOOK, chapters=[])
    problems = []

    for stem, part, title in CHAPTERS:
        path = os.path.join(CHAPTERS_DIR, f'{stem}.txt')
        if not os.path.exists(path):
            problems.append(f'MISSING: {path}')
            continue

        with open(path, encoding='utf-8') as f:
            paragraphs = parse_chapter(f.read().strip())

        if not paragraphs:
            problems.append(f'EMPTY: {stem}')
            continue

        for para in paragraphs:
            for pattern, label in ((SCAN_DAMAGE, 'SUSPECT'), (PAGE_FURNITURE, 'PAGE-HEAD')):
                for match in pattern.finditer(para['text']):
                    start, end = match.start(), match.end()
                    context = para['text'][max(0, start - 40):end + 40]
                    problems.append(f"{label} {stem}#{para['id']}: …{context}…")

        book['chapters'].append(
            {'id': stem, 'part': part, 'title': title, 'paragraphs': paragraphs}
        )

    words = sum(len(p['text'].split()) for c in book['chapters'] for p in c['paragraphs'])
    print(f"chapters={len(book['chapters'])} words={words}")

    for problem in problems:
        print(problem)
    print(f'{len(problems)} problems flagged')

    fatal = [p for p in problems if p.startswith(('MISSING', 'EMPTY', 'PAGE-HEAD'))]
    if fatal:
        print('NOT WRITING — structural problems above')
        return 1

    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(book, f, ensure_ascii=False, indent=1)
    print('wrote', os.path.relpath(OUT, REPO), os.path.getsize(OUT), 'bytes')
    return 0


if __name__ == '__main__':
    sys.exit(main())
