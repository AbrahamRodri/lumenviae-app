# True Devotion text pipeline

The full text of St. Louis de Montfort's *True Devotion to the Blessed Virgin*,
in Fr. Faber's 1862 translation, as bundled with the app.

```
chapters/*.txt   ← source of truth (proofread), edit these
build_book.py    → app/Resources/TrueDevotionBook.json  (generated, never hand-edit)
verify_book.py   → VERIFICATION.md                      (generated)
```

## Why the text is bundled rather than served from the API

Unlike meditations, this is a fixed public-domain book: it does not change, it is
the same for every user, and it has to be readable during prayer with no network.
It is versioned here so corrections go through review like any other change.

## Making a correction

Edit the relevant `chapters/<id>.txt`, then:

```bash
python3 Tools/TrueDevotion/build_book.py
python3 Tools/TrueDevotion/verify_book.py
```

`build_book.py` refuses to write if a chapter file is missing or empty, or if a
printed page's running head survives in a paragraph (`PAGE-HEAD`). Characters
that look like scan damage are only flagged: it prints each one as `SUSPECT`
for a person to check, and writes the JSON regardless. See
[VERIFICATION.md](VERIFICATION.md) for the per-chapter proofing checklist and
the readings still in doubt.

## Two things that must not change

Chapter ids (the `.txt` filenames, listed in `build_book.py`) and paragraph order
within a chapter are both persisted on every reader's device: in their saved
place, and in their marks, which are stored as `chapterID:paragraph` pairs
(`TrueDevotionReadingProgress`). Renaming a chapter or inserting a paragraph
mid-file silently moves people's saved places and marks alike. Appending to the
end of a chapter is safe.

## Format

Paragraphs are separated by a blank line. A line starting with `## ` is a
subheading. Everything else is body text.
