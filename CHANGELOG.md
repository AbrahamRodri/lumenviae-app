# Changelog

All notable changes to Lumen Viae, newest first. Versions are the App Store
marketing versions; a `x.y.z` is not a semantic-versioning promise, since
nothing here is a published API.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
with [Common Changelog](https://common-changelog.org/)'s two refinements:
entries are written in the imperative and carry a commit reference, and a
change that was made and then undone inside the same release is not listed
at all — only the net difference from the version before it.

## 4.0 - Unreleased

The Rosary can be said aloud, the Church's common prayers and her chant
gained books of their own, and How to Pray became a course.

### Added

- Pray the whole Rosary aloud (`UserSettings.prayAloud`, "Pray aloud", off
  by default): in the meditation's player and the Scriptural Rosary every
  prayer, announcement and, in the Scriptural Rosary, each bead's verse is
  said in the chosen narration voice, the beads move with the voice, and
  the pendant stands in for the painting during the opening and closing
  prayers. The voice holds the beads through the opening prayers, and a
  swipe, a tap or the rotor steps those prayers one at a time. Recordings
  come from `GET /api/rosary/audio` and are kept on the device per voice
  (abebfed, b184716, b3aa390, d3ae343, 0e556d3)
- Add the Rosary Aloud, the spoken Rosary with neither meditations nor
  verses: its own title page, a door beside the Scriptural Rosary's on the
  home page and in Explore, and a place on the Pray button and the Rule of
  Prayer. Every prayer's words are set as it is said, the Creed and the
  Hail, Holy Queen among them (abebfed, b3aa390)
- Pray the Seven Sorrows as the traditional Servite chaplet when said
  aloud: the Sign of the Cross and the Act of Contrition; for each sorrow
  an Our Father, seven Hail Marys and a Glory Be, with no Fatima Prayer;
  three Hail Marys in honor of Our Lady's tears, the chaplet's closing
  prayer and the Sign of the Cross. The chaplet's Glory Be bead no longer
  names the Fatima Prayer, and the Scriptural Rosary's chaplet no longer
  shows it (abebfed)
- Add optional closing prayers for the four Rosaries, each a setting in
  Settings and on a set's page, said aloud after the closing prayer when
  every prayer is, in this order: an Our Father, Hail Mary and Glory Be
  for the Holy Father's intentions, the Memorare, and the Prayer to Saint
  Michael (abebfed, b3aa390)
- Add the Act of Contrition, the chaplet's closing prayer, the Memorare and
  the Prayer to Saint Michael, in English and Latin, to the bundled prayers
  (abebfed, cbe263d)
- Download the spoken Rosary's recordings in the chosen voice with the
  offline library, and a set's spoken prayers when the set is saved from
  its page, so the first Rosary said aloud needs no connection (abebfed,
  b3aa390)
- Resume an interrupted spoken Rosary on the prayer it stopped at, not
  only at its bead (abebfed)
- Report `prayed_aloud` with each completion (abebfed)
- Teach the Rosary in How to Pray as a course for someone who has never
  prayed it: a drawn rosary whose beads light in the order they are
  prayed; three lessons on pages of their own — the beads and the order,
  the prayers, the mysteries — marked when opened and never scored; and
  Your First Rosary, a guided Rosary of 75 steps with every prayer in
  full, whose Amen counts as the day's Rosary. Explore gains a "New to the
  Rosary?" door to it (abebfed)
- Keep a Prayer Book of the Church's common prayers, bundled so they pray
  with no signal: 66 new texts beside the Rosary's and the consecration's
  in twelve chapters, English always and Latin paired line for line where
  the Church prays in Latin, and eleven orders of prayer said together,
  from Morning Prayers to In Time of Trouble. The book opens on the order
  for the hour; the Angelus becomes the Regina Caeli in Eastertide, and
  Night Prayers close on the season's antiphon of Our Lady (e118f0f,
  8d28837, d9200c5)
- Pray an order with the book one prayer at a time, aloud in the chosen
  narration voice or in silence — asked once, before it makes any sound.
  An order prayed to its Amen is offered for the book's day, which turns
  at four in the morning; a prayer can be kept with a ribbon or learned by
  heart in four steps, never scored; and the Angelus bell can ring at six,
  noon and six (e118f0f, 6fe2db8, 8d28837, d9200c5)
- Stand the Prayer Book in the app: the hour's prayers in Today's Prayer
  on home, a section and prayer search in Explore, a Prayer Book tile in
  the Chapel, Morning Prayers, the Angelus and Night Prayers on the Rule of
  Prayer, the Angelus in the Pray tray, its recordings in the offline
  download, and every door to a prayer opening that prayer's page in the
  book (e118f0f, d9200c5)
- Add the Chant Library: 64 chants sung and engraved by Verbum Gloriae and
  shared under their copyleft licence, bundled so they sound with no
  signal, on twelve shelves that open on tonight's antiphon of Our Lady.
  Each chant has a page with SLOW, REPEAT and FROM THE TOP for learning it,
  its score drawn in the page's cream with red initials, a zoomable
  full-screen score, the prayer in words and its other settings. It opens
  from the Chapel's Chant tile, Explore's Sung Prayer and "Sing it in
  chant" on a Prayer Book page (7b7e89d, 48d1cad, 75c91ec)
- Offer the modern schedule of mysteries in Settings → Devotion → Daily
  Mysteries: the Luminous on Thursday and the Joyful on Saturday, the
  seasonal Sunday kept. Each set's days are named from the schedule
  chosen, and the traditional schedule stays the default (4948edd,
  b75378c)
- Add a unit-test target, `appTests`, run from the shared `app` scheme,
  with tests of the strand's arithmetic and of the seasons the Sundays
  follow (1bbafe6)

### Changed

- Give the Prayer Book a tab of its own, Prayers, in the Journal's place
  in the bar: the search at the head of the page, then Today (the prayer
  for the hour over its painting, Our Lady's prayers led by the season's
  antiphon, and the prayers kept with a ribbon), Occasions chosen by where
  you are, and All Prayers by topic in plain words; every door to the
  book turns to the tab
- Open the Journal from the Chapel's Reflections tile, from Explore's
  search, and from the screen after a Rosary, which asks what stayed with
  you in the prayer
- Say the Prayers tab in plain words: prayers known by a Latin name
  carry an English title (I Confess, Down in Adoration Falling, Queen of
  Heaven), the season's antiphon is the season's song to Mary, a prayer
  done reads Prayed, the ribbon's words are Save and Saved, the hours read
  On waking, At noon, At 6 PM and At bedtime, centuries are written as
  numbers, and every Church word in a prayer's notes is explained where
  it stands
- Say Home, Explore, the introduction, What's New and the first tour in
  plain words: the mysteries are explained once on each page ("scenes
  from the lives of Jesus and Mary") and their cards say what each set is
  about, Explore has a title and plain doors (Today's Mass, Hours of
  Prayer, Chant, Learn More, All books), the consecration is Consecration
  to Mary, the Rosary said aloud is The Rosary Said Aloud, and a prayer
  done reads Prayed
- Reuse the spoken Rosary's saved manifest while its signed links live, and
  fetch a new one before downloading once they have expired; offline, say
  the Rosary from the recordings already on disk (abebfed)
- Choose how the Rosary will be prayed from one line on a set's and the
  Scriptural Rosary's title pages — HOW YOU'LL PRAY, over what is set, in
  words — opening a sheet of the voice, the speed, Pray aloud, the bead
  counter and the closing prayers, where a card of capsules and switches
  once stood over the painting (abebfed)
- Lay the Marian Library, St. Carlo Acutis, In Scripture and The Devotion
  in Summary out each for what it is, their readings on pages of their own
  that open the feast's Mass, a prayer or the next reading, and that
  Explore's search finds; In Scripture sets each mystery's Gospel as
  running text from the Scriptural Rosary's Douay verses (abebfed)
- Sing the consecration day's Veni Creator, Ave Maris Stella and
  Magnificat from the Chant Library's bundled recordings, and its litanies
  and Glory Be too, with the score a tap away (7b7e89d, 48d1cad, 75c91ec)
- Offer Frederick as the male narration voice in place of the retired one,
  and carry a stored male choice to him; meditations saved offline in the
  old voice still play (6bff141)
- Stop estimating reading time: the consecration day page and True
  Devotion's contents no longer print minutes counted at 200 words a
  minute, and the consecration's introduction says what a day holds rather
  than "Ten to fifteen minutes a day" (abebfed, 75c91ec)
- Set the narration's speed on a slider, 0.7x to 1.7x in twentieths, in
  the playback sheet and the HOW YOU'LL PRAY sheet, where five fixed
  speeds stood; the Lock Screen keeps its presets (353eacc, d3ae343)
- Declare in the privacy manifest the completion the app sends — product
  interaction and a coarse location, not linked to the user and not used
  for tracking — and say plainly in the Privacy Policy what stays on the
  phone and what reaches the server (9491acb)
- Let the text follow the phone's Larger Text up to Extra Large and no
  further, in sheets as on pages, so no page is drawn past the size it was
  set for (4770587, b75378c)

### Removed

- Remove the three chant recordings earlier builds streamed and saved
  offline — the Veni Creator, Ave Maris Stella and Magnificat, files with
  no licence behind them — with the offline chant download. Copies already
  saved are deleted once at launch and the saved library's size corrected
  (7211d86, 7b7e89d)
- Remove the Me page the Chapel replaced (`MeView`, `MeWidgets`,
  `MenuView`), unreachable but still compiled and shipped, with the
  Me-only settings it kept alive (9be67c6)

### Fixed

- After a call, Siri or a navigation prompt, take a recording back so its
  words are heard whole — a prayer to its first word, a meditation or a
  chapter five seconds — and no longer start a meditation already heard to
  its end again while the beads are prayed (b3598d4)
- Hand the app's narration speed back as soon as another flow takes the
  player, so a Rosary begun while a book was being read aloud is no longer
  narrated at the book's pace until the shelf is left, and keep a speed
  chosen on the Lock Screen for a book or a chant as that flow's own
  (75c91ec, 0e556d3)
- Declare the app dark (`UIUserInterfaceStyle`), so the system's own
  chrome — the status bar, keyboards, alerts, pickers and menus, the launch
  screen — is dark whatever the phone's own appearance (186aecf)

## 3.0

The Account tab became the Chapel, a page arranged in place; the Daily
Missal, the Divine Office and a shelf of spiritual reading arrived; the
Scriptural Rosary became a devotion of its own; and the Rosary came to be
prayed a bead at a time.

### Added

- Replace the Account tab with My Chapel, a page arranged in place: a
  focus block that sets the first act of the rule not yet offered large,
  with the page's one gold act, and advances as acts are offered, over a
  grid of tiles — Today, Prayer Streak, Consecration, Reading, Chant,
  Reflections, Liturgy, Library — each drawn at two authored widths. A long
  press enters arrange mode, where tiles are dragged, resized or put away
  into a tray that never deletes (5ff954e, ed21006, ab6d153)
- Keep a rule of prayer — the Rosary, the Scriptural Rosary, the Seven
  Sorrows, and the consecration while a preparation is under way — each
  act checked from what was actually prayed and reset each morning. The
  raised Pray button runs a chosen quick act (today's Rosary by default),
  and a press and hold opens a tray of chosen devotions (5ff954e, ed21006)
- Add the Daily Missal: the 1962 propers for any day, from Missale Meum,
  as one scroll whose feast plate collapses with it point for point. The
  whole Ordinary is set through the propers, its variable parts following
  the day, with a High Mass toggle; English, Latin or both, stacked or
  side by side; posture cues, a jump rail, the Ordo's index, and a month
  calendar marking each day's vestment. Days are kept on disk and the week
  ahead fetched quietly, so the page opens with no signal (5ff954e,
  3c0d5f5, 0d2fc5f, ab6d153)
- Add the Divine Office, the 1960 Breviarium Romanum from our own `/office`
  API. It opens on the hour it is now, lit in an arch over the eight hours
  strung in three groups; each hour reads under the missal's chrome, with
  the class, feast and colour in English, taken from the missal for the
  same day; and a month calendar marks each day by rank and saves its
  hours for offline (5ff954e, 0d2fc5f, 18f0d1a, ab6d153)
- Set Today's Prayer on the home page: the Mass, the Divine Office and the
  Total Consecration as three ruled rows of equal standing, each with its
  live fact — the day's class and colour, the hour now passing, the day of
  the preparation, or BEGIN before one is begun (5ff954e, 3c0d5f5,
  18f0d1a)
- Add Explore behind the home page's search glass: the mysteries, the
  liturgy, the reading shelf and the study pages to browse, and one search
  across mysteries, library pages and meditation sets (5ff954e, 3c0d5f5)
- Add the Spiritual Reading shelf: The Imitation of Christ, Story of a
  Soul, the Confessions and The Dolorous Passion, fetched from Project
  Gutenberg on first open, cut into chapters on device with their
  footnotes set at each chapter's foot, and cached. The reader keeps its
  place to the paragraph, steps chapters in place from a contents sheet
  with search, and withdraws its tools as the page moves while Back stays
  in sight. The shelf stands on the home page, in Explore and in the
  Chapel (3c0d5f5, c7f2aa0, e41b89f, 32a73d7)
- Hear the shelf's books read from LibriVox, tied to the text chapter by
  chapter (the Imitation, whose recording gathers ten chapters to a file,
  offers none): a speed kept per book, apart from the Rosary's narration
  speed (Story of a Soul opens at 1.5x), a sleep timer that fades out, the
  page following the voice where a track reads one whole chapter,
  recordings saved per track for offline, and the place the voice left
  kept beside the eye's (c7f2aa0, e7b541b, 32a73d7, 0d2fc5f)
- Add the day's measure to the shelf and True Devotion: minutes with a
  book open or chapters read, toward a goal the reader sets, let go each
  morning and never chained into a streak (e41b89f, b55b46f)
- Select a paragraph in either book reader to keep it as a note in the
  journal, lay a mark on it, or share it with its citation. The journal
  sets a kept passage as a quotation above the reader's own words, and
  editing the note keeps its parts apart (e41b89f, 52b08c7, ab6d153)
- Add the Scriptural Rosary, a verse of Scripture for every Hail Mary, as a
  devotion of its own: a title page to choose the mysteries, a prayer
  screen setting each bead's verse beside the strand over the veiled
  painting, and doors on the home page, in Explore, on the Pray button and
  on the rule. Its 249 Douay-Rheims verses are bundled (3c0d5f5, a9b37a9)
- Hear the meditations in more than one voice, chosen in Settings or the
  player's playback sheet from the server's list (`GET /api/voices`). A
  meditation not recorded in that voice plays in its default, a change
  mid-Rosary reloads the mystery under the hand, and offline files are
  saved per voice, with earlier downloads renamed rather than orphaned
  (6d7c7f7)
- Ship a privacy manifest declaring the two required-reason APIs the app
  calls — its own `UserDefaults` (CA92.1) and file metadata in its own
  Application Support directory (C617.1) (4a707cc)

### Changed

- Pray the Rosary a bead at a time: the whole Rosary hangs as one strand at
  the player's right edge, a swipe down moves to the next bead and up to
  the one before, the decade turns on its own at the next Our Father, and
  the last bead carries AMEN. The strand unlocks once the mystery's
  meditation has been heard. With the Bead counter setting off, the player
  keeps its decade-at-a-time arrows instead; resume returns to the bead
  (a9b37a9, ab6d153)
- Open the home page on today's mysteries — PRAY WITH A MEDITATION, over a
  quiet line to the Scriptural Rosary — with the reading shelf beneath
  Today's Prayer, and Settings, About and the search glass in its
  masthead. The streak flame moves to the Chapel's Prayer Streak tile
  (32a73d7, ed21006, a9b37a9)
- Split Settings and About into pages of their own, and replace the prayer
  tray's bare `mailto:` with a feedback form, also in About, that asks what
  kind of note it is and sends through the system mail composer (5ff954e,
  ed21006)
- Push content destinations — the Missal, the Office, the reading shelf,
  How to Pray, the Marian Library and the rest — in from the right, each
  with its own Back over a dissolve the page scrolls under, rather than
  raising them from a menu sheet; sheets are kept for tasks and trays
  (5ff954e, ed21006)
- Set the consecration's prayers as a prayer book prints them: ℣ ℟ ✠ in
  rubric red, a litany's response stated once per group over invocations
  one to a line, the Magnificat pointed at the mediant, and Montfort's
  prose in shorter paragraphs under a versal. The Litany of Loreto, the
  Litany of the Holy Name and "O Jesus Living in Mary" gain their Latin,
  with the Liber's accents (a9b37a9)
- Lay the consecration's day page out as a column of cards, with the
  preparation's periods drawn as a road and the book behind the
  consecration shown in Montfort's own cloth (ab6d153)
- Open True Devotion's own text from its cover, name the page about it The
  Devotion in Summary, and give its reader the shelf's chrome, stepping
  and marks, with no minutes-read guess (32a73d7, e41b89f)
- Rebuild the introduction's eight slides: what brings the user to the
  Rosary, whether to pray on the beads (each way shown working), what the
  app holds for the reasons chosen, colours, language, a reminder with 8 PM
  already chosen, and the Sign of the Cross with a first step. The
  paintings crossfade under the thumb (5ff954e, ed21006, ab6d153)
- Set every sheet in one grammar: the page's ground, a gold kicker over a
  Cinzel title, ruled rows, and DONE or CLOSE in the header (ab6d153)
- Speak and mark plainly: the Sacred Record is the Prayer Record, prayers
  open in English by default rather than Latin and English together, each
  door wears one glyph wherever it appears, and the Seven Sorrows take
  Mary's heart pierced by Simeon's sword (`ch-sorrowful-heart`) in place of
  Christ's Sacred Heart (ed21006, ab6d153)

### Removed

- Remove the playback sheet's Background music section, a single dimmed
  "Coming soon" row (ed21006)
- Keep the App Introduction row to debug builds, where re-running it opens
  full screen rather than as a sheet (ab6d153)

### Fixed

- Hang the reader's dissolve from the title's real foot. The measurement
  never arrived, so the band fell back to a fixed fraction of the screen,
  and a two-line title was read straight through (6d8c2f8)
- Stop raising the notification prompt when an intention is chosen in the
  introduction, three slides before the reminder that explains it. The
  reminder slide asks for itself, and a refusal says so (ed21006)
- Show the app's own version in the settings footer, which read v1.0.0
  whatever the build (ed21006)
- Lay the versal over a first-line indent rather than in the first line's
  text box, where Cinzel's descent opened a hole under the first line of
  every reading that began on one (a9b37a9)
- Draw every hairline at two device pixels (`AppLine.hairline`). At 0.5pt
  a border straddled two pixel rows on a 3x screen, and read thick at a
  card's corners and faint along its sides (a9b37a9)
- Give every sheet the app's background, so the system's white no longer
  shows as a hairline around its top (a9b37a9, ab6d153)

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
