# Chant lines

The words of each chant in the Chant Library, line by line, with the
second each line begins and ends in the bundled recording — what the
library's line controls draw on (Line 2 of 9, the previous and next line,
repeat this line, Take turns, a lyric found "at 8:40").

One file per chant, `<chant id>.json`, as Tools/Chants reads it:

```json
{ "id": "salve_regina_simple", "part": null,
  "method": "breaths by loudness (under -18 dB for 0.3 s, ...) + text alignment; Whisper: 15 of 19 breaks heard",
  "lines": [ { "latin": "Salve, Regína, Mater misericórdiæ:",
               "english": "Hail, holy Queen, Mother of mercy,",
               "start": 0.41, "end": 11.79 }, … ] }
```

`part` is always null: every file covers the whole recording, the
antiphon, its versicle and its collect alike, in the order they are sung.
Times are seconds from the start of `app/Resources/Chants/<id>.m4a`.

A line may carry a `"part"` of its own, the score part (0-based, in the
order `ChantCatalogData.swift` lists them) its words are engraved on — the
Pange Lingua's hymn, versicle and collect are three parts, and O Oriens's
antiphon, Magnificat and antiphon again are three. A source that gives its
lines parts writes `part N` on a line of its own before the lines engraved
on part N, and `build` stops if a part is not one of the chant's.

**A chant has a file here only when it passed every check below.** The
Chant Library ships whatever is in this folder, so a chant that would not
line up is left out rather than guessed at; the ones left out are listed
at the end.

## How a chant is made

1. **The words, as sung** (`src/<id>.txt`). The Latin is read off the
   chant's own score (`python3 lines.py score <part>` renders a part of
   `app/Resources/Chants/Scores` as a PNG), so it is the text the cantor
   sings — the Liber's accents, its spelling (*Jesu*, *cujus*, *Génitrix*),
   every verse the recording holds — with the score's syllable hyphens
   closed up. It is broken into lines where the cantor breathes, which is
   nearly always at one of the score's bars. The English is the app's own
   wherever the prayer is in the Prayer Book or the Rosary's prayers
   (joined by `prayers` in Tools/Chants/chants.json), redistributed over
   the Latin's lines; otherwise a plain, literal rendering.

2. **The breaths** (`lines.py`). The recording is measured as RMS
   loudness in 40 ms frames every 20 ms, relative to its own loud singing
   (the 90th percentile frame), so one threshold serves a close recording
   and a reverberant one. A breath is `gap` seconds or more under `noise`
   dB; a phrase shorter than `merge` seconds joins the neighbour it is
   nearer to. Each chant's three numbers stand at the head of its source
   file. (ffmpeg's `silencedetect` was the first tool tried; it measures
   peaks rather than loudness and split the reverberant recordings
   unevenly.)

3. **The checks.** A chant is written only when
   - the recording has exactly as many phrases as the text has lines, and
   - every line lasts between 1.5 and 25 seconds, and
   - Whisper (small, multilingual, in Latin) hears no line's words in a
     neighbouring line's phrase: each phrase is transcribed on its own,
     the transcripts are aligned with the text letter by letter, and an
     exact run of four letters or more that lands on the wrong side of a
     break fails the chant. Whisper mishears sung Latin freely, so a
     garbled phrase proves nothing either way; the method field says how
     many breaks it did hear in the right place ("15 of 19 breaks heard").
     The check catches a single word moved across a break. A word heard
     seven times or more running is Whisper looping ("yār yār yār …" over
     a whole verse of the Te Matrem), not the cantor — the most any chant
     here sings in a row is six Alleluias — and is cut back to two before
     the alignment, or the loop drags the letters after it out of place.

   A line starts 0.15 s before its sound is found, so it does not clip
   its first consonant, and ends where its sound has died away (under
   -28 dB for a tenth of a second, and at least 0.3 s after the breath
   was found): a held last note fades well below the breath threshold
   while it is still heard, and cut at the threshold, a repeated line
   lost it. A line never runs into the next line's lead-in. The 25 s
   limit is on the singing; a fading last note can carry a line a
   little past it.

   Where the cantor breathes inside a line the text cannot honestly part
   (inside one word's melisma, or where Whisper heard too little to say
   which word the breath fell after), the source writes `~` under the
   line, and the line runs over both phrases.

## Running it

```sh
pip install numpy soundfile rapidfuzz            # always
pip install sherpa-onnx cairosvg                 # Whisper's check; score PNGs
# Whisper small, int8 (sherpa-onnx's export), into cache/models:
curl -L https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-small.tar.bz2 \
  | tar xj -C cache/models

python3 lines.py probe salve_regina_simple                # phrases + what Whisper hears
python3 lines.py probe salve_regina_simple --noise -18 --gap 0.3
python3 lines.py build                                    # every src/*.txt
python3 lines.py build salve_regina_simple alma_redemptoris
```

`build` writes `<id>.json` for every chant that passes and removes the
json of one that no longer does. Without the Whisper model it still
checks counts and lengths, and says "unheard" in the method field; the
files here were all built with it. ffmpeg decodes the recordings.
`cache/` (gitignored) holds the decoded audio, Whisper's transcripts and
rendered scores.

To change a chant's words, edit its `src/<id>.txt` and rebuild it. If a
recording is replaced, rebuild everything: the times belong to the file.

Whisper divides the machine's cores among the runs of the script going at
once; `WHISPER_THREADS=n` sets the number itself.

## Left out

None. All 76 chants in Tools/Chants/chants.json passed (2,452 lines). If a
recording or a score changes and a chant stops passing, `build` removes its
json, and it belongs in this list with the reason.
