# Tools

The scripts that build, check and generate Lumen Viae. Start with
`Tools/dev`: it is the one door to the everyday tasks, and the other
tools are listed beneath it.

```bash
Tools/dev help      # every command
Tools/dev doctor    # is this Mac ready to build?
Tools/dev check     # lint, gen-check, build and test, with a summary
```

All Python here is Python 3 with the standard library unless a tool says
otherwise. Run everything from the repository root.

## Tools/dev

| Command | What it does |
|---|---|
| `doctor [--backend]` | Checks Xcode (26 or later), Swift, python3, the simulator runtime, the scheme, and the lint self-test. `--backend` also probes the server's `GET /healthz` (local `PORT`, or 8080, and production). This only reports and never fails. The backend's own `./dev.sh doctor` checks the server in full. |
| `build` | Builds the app for the tools' own simulator, one architecture, without booting it. |
| `test [-only appTests/Suite]` | Runs `appTests` on the tools' own simulator. |
| `run [--show]` | Builds, installs and launches the app on that simulator; `--show` brings Simulator.app forward. |
| `sim [udid\|boot\|shutdown\|erase\|delete]` | The tools' own simulator. |
| `clean` | Removes `.build/`. |
| `lint …` | The CLAUDE.md rules over `app/` (below). |
| `gen-check …` | Generated files against their generators (below). |
| `check` | lint, lint self-test, gen-check, build and test, then a summary. |
| `hooks install\|uninstall\|status` | The opt-in git hooks (below). |

**The tools' own simulator.** `test` and `run` use a simulator named
"LumenViae Dev", created on first use (an iPhone 17 Pro on the newest iOS
runtime; `LUMEN_VIAE_SIM_NAME` and `LUMEN_VIAE_SIM_DEVICE` change either).
They never use the booted simulator, because other Claude sessions and the
live Simulator panel drive that one.

**Build products** go to `.build/DerivedData` in each checkout, and each
xcodebuild log goes to `.build/logs/<step>.log`. This keeps two worktrees
from sharing DerivedData. When a step fails, its errors and the log's tail
are printed, and the full log stays on disk.

## Checks

### Tools/Lint — the CLAUDE.md rules

```bash
Tools/dev lint                     # all of app/
Tools/dev lint app/Views/Foo.swift # only these files
Tools/dev lint --all               # baselined errors too
Tools/dev lint --list-rules
Tools/dev lint --self-test         # every rule against its fixtures
Tools/dev lint --update-baseline   # after a rule is added, or a hit accepted
```

Output is `path:line: rule-id message`. Lint only reads the source.

| Rule | Severity | From CLAUDE.md |
|---|---|---|
| `no-hex-color` | error | A hex belongs in a theme's palette (`Theme.swift`) or, when the colour belongs to a thing, in `FixedColors.swift`. |
| `hairline-half-point` | error | Every hairline is `AppLine.hairline`. Never use `lineWidth: 0.5` or a 0.5pt frame. |
| `icon-through-appicon` | error | `ph-`/`ch-`/`lv-` glyphs are drawn through `AppIcon`, never `Image("ph-…")`. |
| `font-through-appfonts` | error | Faces go through `AppFonts`, never `Font.custom` at a call site. |
| `sheet-background` | error | Every `.sheet` carries `.presentationBackground(AppColors.background)`, or `.sheetGround()`. |
| `sheet-type-cap` | error | Every `.sheet` and `.fullScreenCover` carries `.dynamicTypeSize(...DynamicTypeSize.appMaximum)`. |
| `system-symbol-glyph` | warning | SF Symbols are allowed only where the system's vocabulary is the point. |
| `nav-bar-hidden` | warning | A page that hides the system bar must draw its own Back in every branch. |

The sheet rules follow the content into the type it presents, the view
property it names, and helpers such as `sheetGround()`. `#Preview` blocks
and system controllers (the mail composer) are left out. A rule that
cannot be precise is a warning, and warnings never fail a run.

**The baseline** (`Tools/Lint/baseline.json`) holds the errors that stood
when a rule came in. Each entry is keyed by rule, file and a hash of the
matched line, so edits elsewhere in a file do not disturb it. A baselined
error is not printed and does not fail a run; a new one does. Fix a
baselined line and it drops out of the count, and the next
`--update-baseline` removes its entry.

**Adding a rule:** write a function in `lint.py` with `@rule(id, severity,
summary)`. Add `fixtures/<id>/hit.swift` (at least one finding) and
`fixtures/<id>/clean.swift` (none), then run `--self-test`. A rule with no
fixtures fails the self-test.

### Tools/GenCheck — generated files

```bash
Tools/dev gen-check            # offline
Tools/dev gen-check --online   # let a generator that needs the network fetch
Tools/dev gen-check --only chants
Tools/dev gen-check --list
```

Each generator runs in a scratch copy of the files it reads, never in the
repository. Its outputs are then compared with the checked-in files. The
working tree is left byte-identical, and the run checks this with
`git status --porcelain` before and after. A stale output is listed with
the command that regenerates it. A generator whose cache is absent
reports `skipped (no cache)` and does not fail the run.

| Name | Checks | Offline? |
|---|---|---|
| `prayer-book` | `Tools/PrayerBook/prayer_book.json` | yes |
| `chants` | `app/Data/ChantCatalogData.swift`: words and timed lines (`--text-only`, `--lines-only`) | yes |
| `true-devotion` | `app/Resources/TrueDevotionBook.json`, `Tools/TrueDevotion/VERIFICATION.md` | yes |
| `icons` | the `lv-*` imagesets `draw.py` writes | yes |
| `scriptural-rosary` | `app/Data/ScripturalRosaryData.swift`, `scriptural_rosary.json` | only with `Tools/ScripturalRosary/cache/` |

### Git hooks (opt-in)

`Tools/dev hooks install` sets `core.hooksPath` to `Tools/hooks`, and
`Tools/dev hooks uninstall` removes it. Nothing installs them
automatically. `core.hooksPath` is repository config, so it applies to
every worktree of this clone.

- **pre-commit:** lints the staged Swift files under `app/` (new errors
  fail the commit). Runs gen-check when a generator, its inputs or its
  outputs are staged.
- **commit-msg:** refuses a message with a `Co-Authored-By:` or
  `Generated with` line, since commits here carry no AI attribution.

Skip a hook once with `git commit --no-verify`.

## Generators

Each writes files the app ships. Never hand-edit the outputs. Edit the
generator's input and rerun it. `Tools/dev gen-check` reports when they
have drifted apart.

| Tool | Input | Writes | Notes |
|---|---|---|---|
| `Chants/generate.py` | `Chants/chants.json`, `ChantLines/*.json`, Verbum Gloriae | `app/Resources/Chants/`, `app/Data/ChantCatalogData.swift` | `--text-only`, `--lines-only` and `--keep-assets` need no encoding. A new recording needs ffmpeg and afconvert. |
| `ChantLines/lines.py` | `ChantLines/src/<id>.txt`, the recordings | `ChantLines/<id>.json` | Times each line of a chant. See `ChantLines/README.md`. |
| `PrayerBook/export.py` | `app/Data/PrayerBook/`, consecration and Rosary prayers | `PrayerBook/prayer_book.json` | The server records the Prayer Book from this file. Copy it to the server's `priv/rosary_audio/`. `--check` reports a stale file. |
| `ScripturalRosary/generate.py` | the curated references in the script, the Douay-Rheims API | `app/Data/ScripturalRosaryData.swift`, `scriptural_rosary.json` | `--check`. The server reads the JSON. |
| `TrueDevotion/build_book.py`, `verify_book.py` | `TrueDevotion/chapters/*.txt` | `app/Resources/TrueDevotionBook.json`, `VERIFICATION.md` | See `TrueDevotion/README.md`. Append paragraphs and never insert them, because readers' marks are keyed by index. |
| `IconAudit/draw.py` | the drawings in the script | `app/Assets.xcassets/Icons/lv-*` | `make_sheet.py` renders the contact sheet. `app-icon/fix_icon.py` writes the app icon. |
| `ContentSourcing/` | `sources.py` | paintings, chant candidates, `MANIFEST.md` | Fetches and verifies licences. See `MANIFEST.md`. Needs Pillow. |

## Other tools

| Tool | What it is for |
|---|---|
| `MotionSheet/sheet.swift` | Lays a simulator recording out as a contact sheet of timestamped frames, to judge an animation. See `MotionSheet/README.md`. |

## Claude sessions

A session working in this repo should:

- run `Tools/dev check` (or at least `lint` and `gen-check`) before
  proposing a commit
- run tests with `Tools/dev test`, so they use the tools' own simulator,
  never the booted one
- fix a new lint error rather than baseline it; baseline only when a rule
  is introduced
