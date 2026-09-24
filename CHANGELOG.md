# Changelog

All notable changes to Lumen Viae, newest first. Versions are the App Store
marketing versions; a `x.y.z` is not a semantic-versioning promise, since
nothing here is a published API.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
with [Common Changelog](https://common-changelog.org/)'s two refinements:
entries are written in the imperative and carry a commit reference, and a
change that was made and then undone inside the same release is not listed
at all — only the net difference from the version before it.

## Unreleased

### Added

- Pray the whole Rosary aloud (`UserSettings.prayAloud`, "Pray aloud", off
  by default): in the meditation's player and the Scriptural Rosary every
  prayer, announcement and, in the Scriptural Rosary, each bead's verse is
  said in the chosen narration voice, the beads move with the voice, and
  the pendant stands in for the painting during the opening and closing
  prayers. Recordings come from `GET /api/rosary/audio` and are kept on the
  device per voice
- Pray the Seven Sorrows as the traditional Servite chaplet when said
  aloud: the Sign of the Cross and the Act of Contrition; for each sorrow
  an Our Father, seven Hail Marys and a Glory Be, with no Fatima Prayer;
  three Hail Marys in honor of Our Lady's tears, the chaplet's closing
  prayer and the Sign of the Cross. The chaplet's Glory Be bead no longer
  names the Fatima Prayer, and the Scriptural Rosary's chaplet no longer
  shows it
- Add optional closing prayers for the four Rosaries, each a setting in
  Settings and on a set's page, said after the closing prayer in this
  order: an Our Father, Hail Mary and Glory Be for the Holy Father's
  intentions, the Memorare, and the Prayer to Saint Michael
- Add the Act of Contrition, the chaplet's closing prayer, the Memorare and
  the Prayer to Saint Michael, in English and Latin, to the bundled prayers
- Download the spoken Rosary's recordings in the chosen voice with the
  offline library, so the first Rosary said aloud needs no connection
- Resume an interrupted spoken Rosary on the prayer it stopped at, not
  only at its bead
- Report `prayed_aloud` with each completion

### Changed

- Reuse the spoken Rosary's saved manifest while its signed links live, and
  fetch a new one before downloading once they have expired; offline, say
  the Rosary from the recordings already on disk

## 2.0 - 2026-08-19

The prayer flow became two surfaces, the meditation picker became a shelf
with a page of its own, and meditation sets gained their own sacred art.

### Added

- Rebuild the meditation picker as a shelf: a funnel button discloses the
  "Kind of meditation" tray, the shelf reads as a gallery of tiles or a
  ruled list (remembered between visits), and pinned sets lift to the top
  of both readings (636b28c)
- Add a set's own page between the shelf and the Rosary — set like a title
  page, with the labels, the name, the painting in a lancet arch, a ruled
  ledger of sections, and one gold PRAY. The full set loads behind the page
  so the button is instant (636b28c, 52f6b7d)
- Draw each meditation set under its own painting, from the API's
  `image_*` block: on the shelf's tiles and rows and on the set's page. A
  set without one is read by title rather than under a stand-in (52f6b7d,
  6f11682, bdfda7c)
- Add `FocalFill`, one crop rule that fills any frame around a curator's
  focal point, so bundled and API paintings obey the same formula as the
  admin preview (52f6b7d)
- Add `MeditationReaderView`: the meditation text on its own page over the
  player, with a mini player and an optional follow-along that keeps pace
  with the narration (4564ef0)
- Keep narration playing when the phone locks, and carry the whole Rosary
  from the Lock Screen and AirPods — play, pause, and moving between
  mysteries (fb9a810)
- Give the 33-day consecration the same hands-off prayer: a Now Playing
  claim, Lock Screen artwork, day-scoped track navigation, and a player
  that survives the step between prayers (fb9a810)
- Add narration speed, 0.75x to 2x, persisted and adjustable from the Lock
  Screen (fb9a810)
- Add an overflow tray to both prayer surfaces, including saving one
  meditation's narration for a Rosary prayed without a signal (4564ef0)
- Show a swipe hint on a first Rosary, once and never again (4564ef0)
- Save or remove a single meditation set, with its painting, from the set's
  own page; downloaded paintings are keyed by content hash, so a library
  saved before paintings existed is not made stale (52f6b7d)

### Changed

- Split the prayer screen into a player and a reader sharing one narration,
  from a single 1,500-line view. Moving between them never interrupts the
  voice (4564ef0)
- Pray the traditional week: Saturday is Glorious, and Sunday follows the
  season — Joyful in Advent, Sorrowful in Lent, Glorious otherwise —
  computed on device and kept identical to the server's calendar (52f6b7d)
- Reserve a meditation set's painting for the shelf and the set's page. The
  player, the reader's pill and the Lock Screen always show the current
  mystery's own image, so the three can never disagree (759cda4)
- Hold the reader's header still while reading, and let the focus band
  hung from the title's last line dissolve the text instead (f424b05)
- Smooth the foot of the prayer artwork so a bright-footed painting no
  longer ends on a visible line, and composite the artwork layer before
  its transition so a mystery switch fades as one picture (30b16d1)
- Name the devotion from one place, so the picker, the set page, the
  prayer screen and the resume card agree that the chaplet is "The First
  Sorrow of Mary" (636b28c)
- Derive every reading surface's leading from `ReadingTypography` rather
  than hardcoded values (593c3f7)
- Follow the device's locale and 24-hour setting in the reminder time
  label (593c3f7)

### Removed

- Remove the sleep timer. The meditation's own narration never advances on
  its own, so it already rests at the end of every mystery, and "stop after
  this" could only suppress a carry-over — too thin a job for a control on a
  prayer screen. (The spoken Rosary, added later, does advance on its own;
  it ends at the last Amen and is paused like any other audio) (c2adebe)

### Fixed

- Ship the audio background mode. `INFOPLIST_KEY_UIBackgroundModes` is not
  a key Xcode recognizes, so it was dropped in silence and never reached
  the binary — every build since it was added had shipped without it,
  confirmed against the Release archives. It now lives in a real partial
  Info.plist that Xcode merges (fb9a810)
- Reconcile `isPlaying` against the player's `timeControlStatus`, so the
  transport and the Lock Screen stop claiming to play over silence after a
  system-side stop; surface buffering instead of a frozen ring, pin a
  stalled scrubber at rate 0, retry session activation off the main actor
  when a just-ended call still holds it, and rebuild after a
  media-services reset (fb9a810)
- Carry an owner token on track navigation, so a headphone press can no
  longer advance a Rosary the user had already left, and a step change
  cannot let a stale presigned chant land over the prayer on screen
  (fb9a810)
- Step press-and-hold seek with `seek()` rather than by assigning a rate:
  the assets are MP3, which cannot fast-reverse, and a non-zero rate is
  itself a command to play (fb9a810)
- Scope consecration journal entries to their `ConsecrationProgress`, so a
  second consecration no longer opens — and overwrites — the first one's
  reflection for the same day. Existing entries are backfilled by matching
  each to the consecration whose 34-day window contains it (593c3f7)
- Read prayer days once instead of issuing a SwiftData fetch per day: a
  365-day streak was 365 queries, and the home screen asked for it twice
  per render through a service it rebuilt on every access (593c3f7)
- Store the three theme palettes as constants. `AppTheme.palette` was
  computed, so every one of ~950 `AppColors` reads parsed ten hex strings
  (593c3f7)
- Mark the offline download `@concurrent`. It claimed to run off the main
  actor, but `nonisolated async` inherits the caller's isolation under
  approachable concurrency, so the whole download ran on the main thread
  (593c3f7)
- Keep the 2 Hz narration clock out of the prayer screen's body, which had
  made the whole screen — blurred artwork and all — a dependency of the
  playback timer (4564ef0)
- Reuse the download service's tuned session instead of building and
  leaking a fresh `URLSession` per saved track (4564ef0)
- Revive the reader's scroll tracking, dead on iOS 26, so pull-to-close
  and follow-along work again (f424b05)
- Call `PrayerPainting.bundled` through a closure rather than a bare method
  reference: the module is MainActor by default, so the reference was a
  main-actor function value handed to a nonisolated generic (bdfda7c)

## 1.0.1 - 2026-08-18

### Changed

- Bump the marketing version so the build clears App Store validation. No
  user-facing change (bb72c6d)

## 1.0

First release.
