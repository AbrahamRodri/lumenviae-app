# Lumen Viae - AI Reference Guide

> "Light of the Way" - A Catholic Rosary meditation and prayer companion app

## App Overview

Lumen Viae is an iOS app built with SwiftUI that guides users through praying the Rosary with meditations, scripture, and tracking. The app has an elegant, dark theme with gold accents inspired by traditional Catholic aesthetics.

## Core User Flow

```
Home Screen
    │
    ├── Featured Mystery Card ("Begin Prayer")
    │   └── Goes to: Select Meditation View
    │
    └── Sacred Mysteries Grid (Joyful, Sorrowful, Glorious, Luminous)
        └── Tap any mystery card
            │
            ▼
Select Meditation View (the shelf)
    │
    ├── Gallery of tiles (default) or ruled list (remembered), pinned sets on top
    ├── Funnel button → "Kind of meditation" tray (label chips from the API)
    └── Tap a set
        │
        ▼
Meditation Set Detail (set like a title page, not a product listing)
    │
    ├── Labels kicker, ornament, name in Cinzel, painting in a lancet arch
    ├── A ruled ledger of sections, each named in the left margin:
    │   About this set · The meditations (numbered) · From (author, source)
    ├── The first meditation in full, behind a quiet disclosure
    └── "PRAY" (the screen's one gold act) — nothing set beneath it,
        and never an estimated duration
        │
        ▼
Prayer Flow (5 Mysteries/Decades)
    │
    ├── 1st Mystery → 2nd Mystery → 3rd Mystery → 4th Mystery → 5th Mystery
    │   (Each mystery: Meditation + 10 Hail Marys + Glory Be)
    │
    ▼
Completion Screen
    │
    └── Journal Entry (Optional)
        │
        ▼
Return to Home
```

## The Rosary Structure

### Mystery Types & Schedule

**Default Schedule (Traditional):**

| Day | Mystery Type | Theme |
|-----|--------------|-------|
| Sunday | By season — Joyful in Advent, Sorrowful in Lent, Glorious otherwise | |
| Monday | Joyful | Christ's Early Life |
| Tuesday | Sorrowful | Christ's Passion |
| Wednesday | Glorious | Resurrection & Glory |
| Thursday | Joyful | Christ's Early Life |
| Friday | Sorrowful | Christ's Passion |
| Saturday | Glorious | Resurrection & Glory |

> **Note:** This is the traditional pre-2002 schedule. The Luminous Mysteries (added by Pope John Paul II) are available in the app but not part of the default daily rotation. Users can always manually select Luminous from the Sacred Mysteries grid.
>
> `ScheduleService` computes the seasons on device (Easter by Meeus/Jones/Butcher; Lent = Ash Wednesday up to Easter; Advent = the Sunday on or after Nov 27 through Dec 24) and is kept **identical to the server's `LumenViae.LiturgicalCalendar`** — Christmastide and Eastertide deliberately count as "ordinary" for this rule on both sides. Change the two together, along with the `days_prayed` rows and the site copy.

**Stretch Goals:**
- [ ] Setting to enable "Modern Schedule" (Thursday = Luminous)
- [ ] Feast-day overrides on top of the seasonal Sundays

### The Five Mysteries in Each Set

**Joyful Mysteries:**
1. The Annunciation
2. The Visitation
3. The Nativity
4. The Presentation
5. Finding Jesus in the Temple

**Sorrowful Mysteries:**
1. The Agony in the Garden
2. The Scourging at the Pillar
3. The Crowning with Thorns
4. The Carrying of the Cross
5. The Crucifixion

**Glorious Mysteries:**
1. The Resurrection
2. The Ascension
3. The Descent of the Holy Spirit
4. The Assumption of Mary
5. The Coronation of Mary

**Luminous Mysteries** *(Available, not in default rotation):*
1. The Baptism in the Jordan
2. The Wedding at Cana
3. The Proclamation of the Kingdom
4. The Transfiguration
5. The Institution of the Eucharist

**Seven Sorrows of Mary** (Special devotion):
1. The Prophecy of Simeon
2. The Flight into Egypt
3. The Loss of Jesus in the Temple
4. Mary Meets Jesus Carrying the Cross
5. The Crucifixion
6. Jesus Taken Down from the Cross
7. The Burial of Jesus

### Meditation Types

**Primary Focus:**

1. **Standard Meditations** - General meditations on the mystery itself. Reflects on the scene, its meaning, and the virtue/fruit to cultivate. This is the default experience.

2. **Saint Meditations** - Meditations composed by or attributed to specific saints. Each offers a unique spiritual lens:
   - St. Louis de Montfort (Marian consecration focus)
   - St. Alphonsus Liguori
   - St. John Paul II
   - Others as content is added

3. **Intentional Meditations** - Meditations on mysteries through a specific life lens or vocation. Examples:
   - "As a Father" - Joyful mysteries through the lens of fatherhood
   - "As a Mother" - Contemplating Mary's motherhood
   - "In Times of Suffering" - Sorrowful mysteries for those in hardship
   - "For Discernment" - Luminous mysteries for life decisions
   - "In Gratitude" - Glorious mysteries for thanksgiving

   > This allows the same mystery to speak to different life circumstances and vocations.

**Secondary:**

4. **Scriptural Rosary** - A scripture verse for each bead (not just each mystery). This is a more intensive, slower form of prayer. **Built** as a Prayer Experience setting rather than a meditation type: when on, the player carries a verse band (see the Built list below).

## App Tabs

`AppTab` (in `Components/CustomTabBar.swift`) has five cases, but the bar shows
four — Progress is reached from the streak flame in the home header instead, to
keep the bar from crowding the raised Pray button.

| Tab | In the bar | Purpose |
|-----|-----------|---------|
| Home | Yes | Search bar → Explore, today's mysteries, Today in the Church, mystery grid, quote |
| Consecrate | Yes | The 33-day preparation for Marian consecration |
| Journal | Yes | Reflections, searchable, stored on device |
| Progress | No — via Me | Streaks, prayer history, milestones ("Sacred Record") |
| Me | Yes | The user's own arrangeable page; settings pushed behind its gear |

The **Pray** button raised over the bar runs the user's chosen quick act
(today's Rosary by default), and **press-and-hold** opens a tray of their
chosen devotions (`PrayShortcutTray`). The bar's Pray gap is a fifth
equal slot, so the four labels keep one rhythm.

The home header is the wordmark with a small search glass in the corner
— no menu button, no flame. The old menu's destinations live in the Me
page's **Library** card and on **Explore**; the streak lives in the Me
page's **Prayer Streak** card, whose kicker carries the Sacred Record
link (the only doors to the Progress page). **Today in the Church**
closes the home page below the daily quote as `TodayInChurchSection` —
an ordo leaf unlike other cards: the vestment colour as a full-width
band across the card top, date and feast centered, and a diptych foot
(THE MASS | THE OFFICE). The search glass pushes `AppRoute.explore`
(`Views/Home/ExploreView.swift`): at rest it browses — an epigraph
(Mt 7:7), the five devotions as a ruled ledger, the library shelf —
and typing searches mysteries, library doors, and meditation sets at
once. The set index is fetched quietly for search but deliberately
never listed on the browse page, and the field is deliberately not
auto-focused: the page is a place first, a search second. The real
search field lives on Explore, not on home.

**Pages push, tasks sheet.** Content destinations — the Missal, the
Office, True Devotion, Spiritual Reading (the shelf, its books, their
chapters), How to Pray, In Scripture, the Marian Library,
Carlo Acutis, Settings, Explore — are `AppRoute` cases that slide in
from the right; each draws its own gold Back in its toolbar (so never
apply `navigationBarHidden` to them). The one exception is the Daily
Missal, whose collapsing header is its own chrome, back button
included — it hides the system bar deliberately. Sheets are reserved for tasks and
trays: the Pray tray, the two editors, pickers, and the journal editor.
The tab bar lays its four labels out content-sized with even gaps (not
equal cells), padded clear of the raised Pray medallion.

> Journal is **not** blocked on the API. Entries are a local SwiftData model
> (`Models/JournalEntry.swift`); nothing is sent to the server.

### The Me Tab

The old Account tab slot: a compact name header ("Faithful Pilgrim"
until set, "Praying since…" from the first session, gear → Settings),
then **cards the user arranges themselves** — add, remove, drag to
reorder. Two separate editors, deliberately: `MePageEditorSheet` (name,
page cards, Rule of Prayer) from "Edit page" or the rule's Edit; and
`PrayButtonEditorSheet` (quick tap + hold menu, with a live preview of
the button naming both gestures) from the tray's "Edit this menu" row.
Removing a card hides a view, never data (a hidden streak keeps
counting). The section vocabulary is `MeWidget`; the one-motion acts are
`PrayerShortcut` (both in `Models/PrayerShortcut.swift`) — one enum
feeds the quick tap, the hold tray, and the Rule of Prayer.

Cards: **Rule of Prayer** (daily checklist — Rosary and consecration
check themselves from real data; the Mass and Office are checked by
hand, reset silently each morning, never carried over as failure),
**Prayer Streak** (removable per the no-guilt principle), **Library**
(a two-column shelf: Missal, Office, True Devotion, Spiritual Reading,
How to Pray, In Scripture, Marian Library, Carlo Acutis, Sacred Record — a one-time
migration inserts it for pages saved before it existed),
**Reading** (the book left face-down: its cloth, the chapter the eye
left, how far into the recording the voice left, and "Take it up" —
one book, the most recent, never a "currently reading" list; a one-time
migration inserts it beside Library),
**Consecration** (the page's one votive-washed card), **Reflections**
(journal entries set as quoted lines). Each card keeps the shared
silhouette but its own interior character. Research behind the design:
"The Oratory Brief" artifact. `MenuView` is no longer reachable and
kept only as reference.

### Settings Screen Structure

`AccountView`, now pushed from the Me page's gear (`AppRoute.settings`) —
its own screen sliding in from the right, custom back arrow, tab bar
hidden. Contents unchanged:

**Appearance**
- Theme (Marian Blue / Midnight / Candlelit) — re-themes the app live
- App icon (four alternates)

**Prayer Experience**
- Text Size (slider)
- Prayer Language (English / Latin / Latin & English / English & Latin)
- Prayer image mode

**Devotion**
- Daily Reminders (toggle, time picker, sound picker)
- What Draws You Here — the onboarding intentions, editable; decides which pool
  of reminder copy is used

**Offline**
- Download for Offline — every meditation set and audio file

**About**
- About Lumen Viae
- App Introduction (re-runs onboarding)
- Privacy Policy
- Help & Support

**Footer**
- App version, and the tagline "Ad Majorem Dei Gloriam"

## Architecture

```
app/
├── appApp.swift              # @main entry
├── ContentView.swift         # Tab switch + the app's NavigationStack
├── Constants.swift           # Strings, Color(hex:)
├── Navigation/
│   └── AppRouter.swift       # AppTab, AppRoute, navigation path
├── Models/                   # API models, SwiftData models, enums
│   ├── Mystery, Meditation, MeditationSet, MysteryCategory
│   ├── JournalEntry, PrayerSession          (SwiftData)
│   ├── Consecration{Day,Phase,Prayer,Progress}
│   ├── TrueDevotionBook, TrueDevotionReadingProgress
│   ├── LibraryBook           # + catalog entry, parsing rules, LibriVox models
│   ├── BookReadingProgress                  (SwiftData)
│   ├── PrayerShortcut                       # + MeWidget — personalization vocab
│   └── StreakMilestone, MarianFeastDay, BilingualConsecrationPrayer
├── ViewModels/               # @Observable
│   ├── HomeViewModel, MeditationSelectionViewModel, MeditationSetDetailViewModel
│   ├── PrayerSessionViewModel, ConsecrationViewModel
│   └── TrueDevotionReaderViewModel
├── Views/
│   ├── Home/ Prayer/ Journal/ Progress/ Account/
│   ├── Me/                   # MeView (My Oratory), MeWidgets,
│   │                         # MeCustomizeSheet, PrayShortcutTray
│   ├── Meditation/           # SelectMeditationView (the shelf), MeditationSetDetailView
│   ├── Consecration/         # 33-day preparation (own NavigationStack)
│   ├── TrueDevotion/         # Book reader
│   ├── Library/              # Spiritual Reading shelf, book page, chapter
│   │                         # reader, contents sheet, transport
│   ├── Resources/            # How to Pray, Marian Library, Scripture, Carlo Acutis
│   ├── Onboarding/           # 7-slide first run + RosaryMethodsView
│   └── Launch/
├── Components/               # CustomTabBar, HeaderView, MysteryCard,
│                             # QuoteSection, MeditationSetTile (+Row), MenuView,
│                             # StreakWidget
├── DesignSystem/             # Theme, Typography, AppIcon, Motion,
│                             # SacredComponents (OrnamentDivider, DropCapText…),
│                             # ReadingText (ReadingTypography, ReadingText, PrayerText)
├── Data/                     # Bundled content, not code-adjacent constants
│   ├── ConsecrationData, BilingualConsecrationPrayers, BilingualPrayer
│   ├── MysteryData, LuminousMeditationData, TrueDevotionData/Prayers
│   ├── ScripturalRosaryData  # GENERATED by Tools/ScripturalRosary — 249 Douay verses
│   ├── LibraryCatalog        # Spiritual Reading shelf: sources + cutting rules
│   ├── ReminderMessages      # Notification copy pools
│   └── RosaryQuotes          # Daily quotation catalog
├── Services/
│   ├── APIService            # HTTP client (https://lumenviae.fly.dev/api)
│   ├── AudioService          # Narration and chant playback
│   ├── OfflineContentService # Full offline download of text + audio
│   ├── MeditationCacheService, ImageCacheService
│   ├── PrayerHistoryService, PrayerResumeService, ScheduleService
│   ├── FavoritesService, MeditationSetResolver, TrueDevotionLibrary
│   ├── LibraryService        # Gutenberg text + LibriVox tracks, disk cache
│   ├── LibraryBookParser     # Cuts a Gutenberg edition into chapters
│   ├── LibraryTrackMap       # Ties LibriVox tracks to parsed chapters
│   ├── LibraryListeningSession # The shelf's one voice, above the views
│   ├── LibraryProgressStore  # Every read/write of a reading place
│   ├── LibraryAudioDownloads # Per-track offline recordings
│   ├── UserSettings          # Preferences + daily reminder scheduling
│   └── MockDataService       # Preview/fallback fixtures only
└── Resources/                # Fonts, TrueDevotionBook.json
```

### Concurrency

The target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and
`SWIFT_APPROACHABLE_CONCURRENCY = YES`. Consequences worth knowing before you
write concurrent code here:

- Every type is `@MainActor` unless it says otherwise. Pure data types that get
  decoded off the main actor need `nonisolated` on the conformance
  (`struct MeditationSet: nonisolated Codable`) or the whole type
  (`nonisolated struct TrueDevotionBook`).
- `nonisolated async` functions **inherit the caller's isolation** under
  approachable concurrency — they do not automatically leave the main actor.
  Use `@concurrent` when work genuinely must run off it.

## Feature Status

### Built

- **Core prayer flow** — day-based mysteries, meditation picker (gallery or
  list, a filter tray of API labels, pinned sets on top), a set detail step
  before prayer, decade-by-decade prayer screen with bead tracking,
  completion screen, and a resume card for an unfinished Rosary.
- **Audio** — narration for meditations and chant for consecration prayers.
- **Persistence** — prayer sessions and journal entries in SwiftData; settings,
  favorites, and reading progress in UserDefaults.
- **Progress** — streaks, history, and milestones, reached from the home
  header's flame.
- **Journal** — entries after a Rosary or consecration day; searchable, editable,
  and entirely on device.
- **33-day Consecration** — feast-day selection, per-day scripture and reading,
  bilingual prayers, journal prompts, and a completion rite.
- **True Devotion reader** — the full bundled book with per-chapter progress.
- **Resource library** — How to Pray the Rosary (with Montfort's methods),
  Finding the Mysteries in Scripture, the Marian Theology Library, and
  St. Carlo Acutis.
- **Reminders** — daily notification at a chosen time and sound, with copy drawn
  from the pool matching the user's stated intentions.
- **Offline** — user-initiated download of every set and audio file.
- **Personalization** — three themes, four app icons, prayer language, text
  size (app-wide, plus the missal's and the reading shelf's own); the Me tab's arrangeable "My Oratory" page (widgets, rule of prayer,
  intentions, display name) and the configurable Pray button (quick act +
  press-and-hold tray), all stored in UserDefaults via `UserSettings`.
- **Onboarding** — eight slides, skippable, re-runnable from Account.
- **Daily Missal** — the 1962 propers for any day, in the resources menu,
  as one scroll surface under a single collapsing header (the "App missal
  page revision" handoff). Served live by the third-party Missale Meum API
  (`https://www.missalemeum.com/en/api/v5`, MIT, free to use) through
  `MissalAPIService` — deliberately a separate client from `APIService` so a
  third-party outage never looks like a Lumen Viae failure. The header is
  the screen's own chrome — circular back / ☰ / Aa buttons with a date pill
  absolutely centred — so this is the one pushed page that hides the system
  bar. The day is still stepped a page at a time: ‹ › ride at the foot of
  the feast plate with TODAY between them, and "Return to today" takes
  that slot once the reader has wandered.
  Its feast plate (temporal line, title, vestment dot + class,
  commemorations, day navigator) collapses on scroll with hysteresis (96 down / 44 back,
  driven by `onGeometryChange` in global coords — GeometryReader
  *preferences* do not fire during scrolls here) and crossfades the date
  pill into the feast's name; a jump-to-section rail, a 1pt progress line,
  and optional posture cues (STAND · SIT · KNEEL) ride below, with the
  active section spied from each section's reported top. Section metadata —
  Latin/English names, posture, proper-vs-Ordinary tier — is bundled in
  `Data/MissalOrderData.swift`, keyed by the API's section ids; unknown
  sections (Candlemas rites, Holy Week) degrade to plain propers. The
  Ordinary is placed by **station** — propers and Ordinary parts share one
  ordered scale and are merged — rather than hung off named proper
  sections, so a day the API serves without a Prefatio still reaches its
  Sanctus (reading the Ordo's Common Preface in place of the day's) and
  one without a Communio still gets its Canon. A section's tier
  (`isProper`) decides only the diamond stud, never whether it is drawn,
  so "Propers only" keeps the day's own Preface. The Aa
  sheet sets language (writes the app-wide prayer language), stacked or
  side-by-side bilingual layout (side-by-side forces Both), a
  missal-specific text size slider (15–21pt, `missalTextScale`, which the
  citations follow too), posture
  cues, a High Mass toggle, and Contents: "With the Ordinary" (default)
  lays the **entire Ordinary** through the propers — Asperges (sung Sunday
  Mass) through the Last Gospel and the Leonine prayers — with the
  variable parts computed per day as best the data allows: Gloria falls
  away with violet/black/rose vestments, Credo belongs to Sundays and
  ranks I–II, Asperges and incensing to High Mass, the Leonine prayers to
  Low. The Ordo's Preface section is split so the day's own Preface
  stands between the Sursum Corda dialogue and the Sanctus; the Our
  Father carries its "Admonished by Thy saving precepts" introduction;
  the Offertory verse opens with the Ordinary's ℣ ℟ dialogue. The Ordo's
  single-sided rubric commentary and its "– Introit in today Mass –"
  placeholders are left out entirely. The propers' diamond stud is the
  only tier mark — nothing is dimmed. "Propers only" keeps the day's own
  texts alone (body, rail, ☰ index, progress denominator). The forced
  first-open layout question is unchanged. Texts arrive as
  `[english, latin]` pairs whose line counts align, pairing as before in
  the shared `MissalPassage*` views (also used by the Office and the Ordo
  page; the section list is built once per real change into `@State`, not
  derived in the body, which the scroll invalidates every frame); in stacked mode the translation is indented 20pt under its line.
  Citations (`*Ps 138:17*`) are small engraved caps in dim gold
  (`MissalReferenceText`); ℣ ℟ ✠ are rubric red (`MissalRubric.red`, the
  muted vestment red); the sources' ☩ and bare `+` cross marks are
  normalised to the traditional ✠ in `missalLines`. The versal opens the
  day's Introit — the first proper, never the Ordinary before it, never
  in columns. Motion uses the design system's ease-out
  (cubic-bezier 0,0,0.58,1); the scroll offset is measured on the whole
  content column (a marker inside the LazyVStack gets released
  mid-scroll and goes stale) and section tops in content-space
  coordinates, which scrolling never moves. The ☰ button
  raises the Ordo Missæ index sheet (active dot, proper diamonds, postures,
  tap to jump); the colophon ("ITE, MISSA EST") still links the full
  `OrdoMissaeView`. The date pill opens `MissalCalendarSheet`, now a month
  grid — "AUGUST MMXXVI", vestment dot per day from the year calendar,
  today ringed in gold, month chevrons — over a feast readout naming
  whichever day is under the finger (today's until one is: pressing a day
  names it, lifting opens it), with an honest offline row
  beneath: how many of the month's days are cached, and SAVE to fetch the
  rest. Every fetched day is cached in Application Support/Missal (excluded
  from backup) via `MissalCacheService`, and after the first load the
  coming week, the Ordo, and the year's calendar are prefetched quietly —
  a chapel with no signal still gets the right page; days more than 30 back
  are pruned.
- **Divine Office** — the pre-Vatican-II Breviarium Romanum (1960 rubrics,
  the 1962 books), in the resources menu and as "The Office" beside "The
  Mass" in the home band. Served by our own API's `/office/*` endpoints
  (`GET /office/:date`, `/office/:date/:hour`, `/office/calendar/:year/:month`,
  `/office/versions`), which the Phoenix app assembles from the Divinum
  Officium engine and parses into JSON — so `OfficeAPIService` is still a
  separate client from `APIService`: an upstream engine outage
  (`office_unavailable`, retryable) must never look like the Rosary content
  failing. The version and language ride as explicit query params, pinned
  in `OfficeAPIService` (`rubrics-1960`, `english`) — a future version
  setting threads through there, and every cache file name carries the
  version. `DivineOfficeView` steps days with the missal's navigator and
  lists the eight hours as a ruled ledger (bundled in `CanonicalHour` —
  the ledger never waits on the network; today's page marks the present
  hour with a gold dot); `OfficeHourView` reads one hour under the app's
  prayer language and the missal's two bilingual layouts, reusing
  `MissalPassageText`/`MissalPairedPassageText`/`MissalColumnPassageText`
  (the Latin and vernacular cells keep the engine's line structure, so
  they pair line for line), with prev/next hour at the foot of the page.
  Hours and days cache in Application Support/Office via
  `OfficeCacheService`; after the first load, today's and tomorrow's
  hours are prefetched quietly and days more than 30 back are pruned.
  `OfficeCalendarSheet` mirrors the missal's. Every hour names its source
  — the texts are The Divinum Officium Project's work, and the footer
  credits it.

- **Scriptural Rosary** — a verse of Scripture for every Hail Mary bead,
  behind a Prayer Experience toggle (off by default; the plain Rosary is
  the app's first face). When on, and when the mystery has a curated set,
  the player grows a verse band between the title and the transport: a
  10-bead strand (7 for the Seven Sorrows), the Douay-Rheims citation,
  and the verse on a gold rule — tap to pray the bead forward, long-press
  to step back; moving the mystery resets to the first bead (a `didSet`
  on `currentMysteryIndex`, so the Lock Screen path resets it too). The
  249 verses are **bundled** (`Data/ScripturalRosaryData.swift`, keyed
  `"<category>_<order>"` like MysteryData's fruits) — prayer must never
  need a signal. The file is GENERATED by `Tools/ScripturalRosary/generate.py`
  from the Original Douay-Rheims API (thedouayrheims.com, CC0): the
  curated verse references live in the script; edit there and rerun,
  never hand-edit the Swift. Narrative mysteries walk their Gospel scene;
  the Assumption and Coronation use the liturgy's own typology
  (Canticles, Psalms, Judith, Ecclesiasticus, the Apocalypse).
- **Spiritual Reading** — a curated shelf of public-domain classics
  (Imitation of Christ, Story of a Soul, Confessions, Dolorous Passion)
  reached from the Me Library card and Explore. Nothing is bundled: the
  text is fetched from Project Gutenberg the first time a book is opened,
  cut into chapters on device (`LibraryBookParser`, per-edition rules in
  `Data/LibraryCatalog.swift` — Gutenberg serves CRLF, the parser
  normalizes it), and cached in Application Support/Library with a
  versioned filename (`LibraryService`, a separate client per the
  third-party rule).

  **The cutting rules are checked against the real editions, chapter by
  chapter — do not change one without re-running it.** `startPattern`
  says where the book proper begins (without it, Taylor's contents page
  opens a false chapter that swallows the whole preface); `stopPattern`
  where it ends; `dropPattern` removes a printer's mark; `notePattern`
  names a footnote marker, and matched paragraphs are lifted out of the
  prose into `LibraryChapter.notes` and set as an apparatus at the
  chapter's foot (176 citations in the Imitation, 166 in the Story of a
  Soul, thirty-four in one chapter alone). `chapterTitles` supplies
  titles for an edition that prints none — Pusey's thirteen books.
  Every one of these rides in `editionFingerprint`, so correcting one
  book retires that book's cached parse and no other's.

  The four books cut to: Imitation 114 chapters under four part
  headers; Story of a Soul the Prologue, chapters I–XI, and the
  Epilogue (13); Confessions 13 books; Dolorous Passion "To the
  Reader", nine Meditations, the Introduction, and chapters I–LXVI (77).

  **Audio is tied to the text** by `LibraryTrackMap`, from the catalog's
  `trackMapping`: `.sequential` where a recording gives each chapter its
  own file (Thérèse, Emmerich — 1:1, verified track for track),
  `.bookChapterRanges` where one file holds many ("Book 3 - Chapters
  21-30", Kempis), `.bookSpans` where one book needs several files
  (Augustine, LibriVox 2601 — **the Pusey reading**, matching the text;
  the other complete Confessions is Outler's and must never be offered
  as the voice of this one). The alignment decides what the UI may
  claim: a track that reads one whole chapter offers "READ ALONG" bare,
  one that holds ten says "from Chapter XXI" rather than pretending the
  voice starts where the reader is. A DEBUG assertion prints any
  chapter left unmapped — a volunteer re-cutting their ledger is the
  way this drifts.

  `LibraryListeningSession` owns playback **above the views**: a screen
  counts itself in and out (`enterScreen`/`leaveScreen`), and the
  reading ends when the last library screen is gone — never on a single
  view's `onDisappear`, which fires for a push, doesn't fire when a
  screen is torn out from under a pushed one, and fires spuriously for a
  cancelled back-swipe. It holds the shared player with a token, so a
  Rosary that claims the player simply silences this session's readouts.

  `BookReadingProgress` keeps **both places** — the chapter and
  paragraph the eye left, and the track and second the voice left — plus
  the `editionFingerprint` the reading place was made against, so a rules
  change lets go of an index that no longer means what it meant. All
  reads and writes go through `LibraryProgressStore` (reading written
  straight through, listening throttled to 5s and forced on pause, track
  change, leaving, and backgrounding).

  Reader: `ReadingText` sizing from its own `readingTextScale` (15–26pt,
  the Aa), a versal initial, a hairline place rule, "9 of 13", a ☰
  contents sheet with search, prev/next stepping in place so a
  114-chapter book never stacks 114 screens, paragraph-level resume via
  `.scrollPosition(id:)`, long-press a paragraph to keep it as a
  Reflection (the journal is the app's one store for what a reader
  keeps — there is no highlights library), and follow-the-voice
  auto-scroll where the sounding track reads this whole chapter.
  Recordings can be saved per track (`LibraryAudioDownloads`, background
  URLSession) behind the missal's honest offline line — "1 of 13
  readings saved · 11 MB · about 188 MB more". Never a percentage, never
  a streak, never a count of what is unread.

### Not built yet

- A Divine Office version/language setting (Monastic, Dominican, and the
  other rubrical versions the API's `/office/versions` already serves) —
  `OfficeAPIService.version`/`.language` are the seam
- Auto-scrolling meditation text synced to audio (the Spiritual Reading
  reader has it; the prayer reader's is proportional too)
- Haptic feedback during prayer
- A setting to switch between the Traditional and Modern (Luminous Thursday)
  schedules — `ScheduleService` is the seam for it
- Feast-day overrides on the schedule (seasonal Sundays are built)
- Server-side sync of journal entries or progress (everything is local)

## Design System

### Colors
- **Background:** `#1a1a2e` (deep navy)
- **Card Background:** `#252542`
- **Gold:** `#d4af37` (primary accent)
- **Gold Light:** `#e8c547` (buttons, emphasis)
- **Cream:** `#f5f0e1` (text on dark)
- **Text Secondary:** `#a0a0b0`

### Typography
- **Headlines:** System serif, semibold
- **Body:** System serif, regular
- **Quotes/Scripture:** System serif, italic
- **Bundled fonts:** Cinzel (Regular, SemiBold) for display; EB Garamond
  (Regular, Medium, SemiBold, Italic, MediumItalic) for reading. Always go
  through `AppFonts` — never `Font.custom` at a call site.
- **Long-form text:** render through `ReadingText` (prose: paragraph splitting
  on blank lines, `─────` rules become ornament dividers, optional drop cap)
  or `PrayerText` (verse/stanza text, including the `|||` bilingual line-pair
  format) in `DesignSystem/ReadingText.swift`. Spacing comes from
  `ReadingTypography` and scales with the font size — don't hand-roll
  `lineSpacing` magic numbers on reading surfaces. Reading blocks are 15–16pt
  minimum in cards, 17–18pt in immersive readers; tap targets stay ≥44pt.

> Colors above are the Midnight theme's. Backgrounds and card fills come from
> the **active theme**, so read them from `AppColors`; only gold, gold light,
> cream, and secondary text are fixed across themes.

### Visual Style
- Dark, contemplative theme
- Gold accents for sacred/important elements
- Rounded cards with subtle borders
- Gradient overlays for depth
- Minimalist, distraction-free UI for prayer focus

## Technical Notes

- **Minimum iOS:** 17.0 (uses `@Observable` macro)
- **Framework:** SwiftUI (no UIKit views)
- **State Management:** `@State`, `@Observable`, `@Environment`
- **Navigation:** `NavigationStack` driven by `AppRouter` (`path` + `AppRoute`).
  The consecration tab hosts its **own** stack as a sibling of the outer one —
  nesting it silently drops the outer stack's destination table. Don't
  "simplify" that.
- **Persistence:** SwiftData for prayer sessions and journal entries;
  UserDefaults for settings; Application Support for offline content.

### Data Architecture

**From the API** (`https://lumenviae.fly.dev/api`):
- Mysteries (titles, scriptures, descriptions)
- Meditation sets and their meditation text
- Set artwork: each set carries a flat `image_*` block — unsigned, immutable
  URL, a normalized focal point, pixel size, alt text, attribution — all null
  together when there is no painting. Read it through `SetArtwork`; draw it
  through `SetArtworkView` (the fallback chain: set painting → category
  painting) and `FocalFill` (one crop rule for every size)
- Meditation narration audio (presigned URLs, ~24h; the set says when they
  die in `audio_expires_at`, and `GET /meditations/:id/audio` re-signs one)
- Consecration chant audio (presigned per prayer)

**Bundled in the app** — doctrinal and stable, so it must work with no network:
- Every Rosary prayer, English and Latin (`Data/BilingualPrayer.swift`)
- The 33 consecration days and their prayers (`Data/ConsecrationData.swift`)
- *True Devotion to Mary* (`Resources/TrueDevotionBook.json`)
- The Marian library, the how-to guide, the daily quotes

**On device:**
- Preferences (UserDefaults), favorites, reading progress
- Prayer sessions and journal entries (SwiftData) — never sent to the server
- Downloaded sets, audio, and set paintings (Application Support, excluded
  from iCloud backup). Paintings are `images/set_<id>_<hash>.jpg`, so a
  replaced painting is a missing file, never a HEAD; a library downloaded
  before paintings existed is not made stale — Download again fetches only
  what is absent

> A companion Phoenix web app owns the meditation content so it can be updated
> without an app release. Anything the user must be able to pray without a
> connection is bundled instead.

### Design Principles
- **Build for flexibility:** Even though Luminous mysteries aren't in the default schedule, data models and UI should support all 4 mystery types equally. Schedule logic should be configurable, not hardcoded.
- **Separation of concerns:** Keep schedule/calendar logic in a dedicated service so it can be swapped out for liturgical calendar integration later.
- **Content-driven:** Mystery data (titles, scriptures, meditations) should be stored as data files, not hardcoded in views.

## Content Requirements

> **Note:** All content is managed in the web app and served via API. This section documents the expected data structure for iOS model design.

### Per Mystery (from API)
- Title (e.g., "The Annunciation")
- Subtitle (e.g., "The Incarnation")
- Scripture reference (book, chapter, verse)
- Key scripture passage
- Associated virtue/fruit
- Image URL (optional)
- Audio URL (optional)

### Meditation Content Structure (from API)
- **Standard meditation:** 1 per mystery (20 total for 4 mystery types)
- **Saint meditations:** Variable per saint (aim for full sets of 5 per mystery type)
- **Intentional meditations:** Sets of 5 mysteries sharing a theme/intention
- **Labels (live in API):** Each meditation set carries a `labels: [String]` array. The controlled vocabulary lives in the web app (`LumenViae.Rosary.Labels`) and is currently Intentions, Saints, Scriptural, Contemplative, Considerations. The iOS picker builds its multi-select filter chips from these and groups unfiltered browsing by each set's *first* label, so order labels primary-first. If a set arrives without `labels`, the picker gracefully falls back to a flat list. Favorites are on-device (not API).
- **Label wording is a display concern:** filtering and grouping match the raw API string, but the picker renders labels through `MeditationLabel.displayName` (`Models/MeditationSet.swift`). "Considerations" currently shows as **Reflections**. Rename in that map, not in the database.

### API Endpoints (as implemented in `APIService`)
```
GET /mysteries[?category=]              # Mysteries, optionally by category
GET /meditation-sets?category=:category # [MeditationSetSummary] for a category
GET /meditation-sets/:id                # Full MeditationSet with meditations + audio_expires_at
GET /meditations/:id/audio              # Freshly signed narration URL + expires_at
GET /prayers/:prayerId/audio            # Presigned chant URL for a consecration prayer
```
Meditation audio arrives as an `audio_url` on each meditation; the prayer flow
asks `/meditations/:id/audio` for a fresh one only once the set's have expired
or a load has failed. Errors come in one envelope,
`{ "error": { "code", "message", "details"? } }` — `APIService.send` decides on
the status code and carries `code` on `APIError.serverError`. There is no
journal endpoint and none is planned — journal entries are local.

## Glossary

- **Decade:** One Our Father + 10 Hail Marys + Glory Be (one mystery)
- **Mystery:** A scene from Jesus/Mary's life to meditate on
- **Rosary:** Full prayer = 5 decades (one set of mysteries)
- **Chaplet:** Shorter prayer devotion (like Seven Sorrows)

## Git Commit Guidelines

**IMPORTANT**: Do NOT add AI co-author attribution to commits. All commits should be attributed to the human developer only.
