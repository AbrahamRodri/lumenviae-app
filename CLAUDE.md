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
four — Progress is reached from the Chapel's flame tile (and Settings) instead,
to keep the bar from crowding the raised Pray button.

| Tab | In the bar | Purpose |
|-----|-----------|---------|
| Home | Yes | Search bar → Explore, today's mysteries, mystery grid, Today's Prayer, the reading shelf, quote |
| Consecrate | Yes | The 33-day preparation for Marian consecration |
| Journal | Yes | Reflections, searchable, stored on device |
| Progress | No — via Chapel | Streaks, prayer history, milestones ("Prayer Record") |
| Chapel | Yes | My Chapel — the user's arrangeable page (Settings and About live in the home masthead) |

The **Pray** button raised over the bar runs the user's chosen quick act
(today's Rosary by default), and **press-and-hold** opens a tray of their
chosen devotions (`PrayShortcutTray`). The bar's Pray gap is a fifth
equal slot, so the four labels keep one rhythm.

The home header is the wordmark framed by the app's chrome: the search
glass on the left, **ph-faders → Settings** and **ph-info → About** on
the right. No flame — the streak lives in the Chapel's own Prayer Streak
tile, whose kicker carries the Prayer Record link (with Settings →
Devotion, the only doors to the Progress page). Settings and About sat
in the Chapel's day strip until that strip was left to read the
liturgical day alone: app-level chrome on a page-level strip was
findable only by whoever thought to look there. The Chapel's foot still
names both in words.

**Today's Prayer** (`Components/TodaysPrayerSection.swift`) stands
between the Sacred Mysteries grid and the reading shelf: a header line,
the feast with its class and vestment dot, then three ruled rows on the
bare page — no card, no panel, no fill. The Mass, the Divine Office,
and the Total Consecration, given equal standing. It is named for the
user's prayer and **not** "Today in the Church", because the
consecration is a private devotion and not a liturgical observance;
`TodayInChurch` (the observable) still supplies the day and is shared
with the Chapel's day strip. Every row has the same four parts —
medallion, name, one plain line, the row's own live fact, chevron — so
the eye reads down the column of facts: the day's silk as a 4×24 bar,
the hour that is passing as a lit dot and NOW, the day of the
preparation over a 46pt hair. Row 3 before any consecration is begun
keeps its place, its icon and its weight and offers BEGIN — **no state
in this section may shame the user**: no "0 days", no "missed", no
empty track. The block replaced a shelf of three bound volumes whose
third spine opened True Devotion when no consecration was under way;
that book is now reached from Explore and the Chapel's Library tile.

The search glass pushes `AppRoute.explore`
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
apply `navigationBarHidden` to them). The exceptions are the pages
whose chrome is their own: the Daily Missal and the Office's hour
reader, whose collapsing headers carry their back button, and the two
**chapter readers** (Spiritual Reading and True Devotion), which
withdraw their chrome as the page moves and carry a floating
`ReaderBackCapsule` instead. Their title pages — the shelf, a book
page, True Devotion's own, the Office's ledger of hours — keep the
system bar and the gold Back like everything else; only the reading
surface hides it.

A page that hides the system bar hides the back-swipe with it, so it
owes a way out from **every** branch it can draw, not just the loaded
one. A spinner or an "unavailable" message with no Back is a screen
only a force-quit leaves; both readers had one, and both now carry the
capsule in those branches too. Sheets are reserved for tasks and
trays: the Pray tray, the two editors, pickers, and the journal editor.
The tab bar lays its four labels out content-sized with even gaps (not
equal cells), padded clear of the raised Pray medallion.

> Journal is **not** blocked on the API. Entries are a local SwiftData model
> (`Models/JournalEntry.swift`); nothing is sent to the server.

### The Chapel Tab

The old Me/Account tab slot, rebuilt as **My Chapel**
(`Views/Chapel/MyChapelView.swift`, from the "My Chapel" design
handoff): a page the user arranges **in place** — no customize sheet.
Two ideas drive it: a single focus at the top (the first unoffered act
on the rule, set large with the page's one gold CTA, advancing on its
own as acts are offered — derived, never stored), and an arrangeable
tile grid below. Long-press 450ms anywhere (cancelled by >8pt of
movement), the coach ribbon's "Show me" (one-time,
`userSettings.chapelCoached`), or the foot's "Arrange this page" all
enter arrange mode: tiles sway ±0.5°, gain a ✕ badge (in the row gap
above for frameless tiles, at the corner for outlined ones), the tab
bar yields to a tray (`router.chapelArranging` is how ContentView
knows), and tiles can be dragged (a ghost leans up to ±9° into the
travel; a dashed slot opens at the landing), tapped to switch between
their **two authored layouts** (full `span 2` / half `span 1` — each a
different drawing, never the full squeezed), or put away. Nothing is
deleted: the tray always holds what's off the page, and a stowed flame
keeps counting. All ambient motion quiets under Reduce Motion.

Above the grid, fixed: a day strip (liturgical-colour diamond from the
missal vestment + weekday · feast via `TodayInChurch`) and the focus
block. The strip carries no app chrome — it reads the day, and the room
that buys is what lets a long feast set in full. Tiles (vocabulary `Models/ChapelTile.swift`;
layout persists as `userSettings.chapelLayout`, validated against known
ids on decode, with a one-time migration from the old `meWidgets`
order): **Today** (the rule as a ledger — the "Something else" escape
scrolls to it, the ledger *is* the picker; manual acts toggle on tap,
watched acts open themselves; Rosary/chaplet/consecration check from
real data, Mass/Office by hand, reset each morning), **Consecration**
(de Montfort's four preparations as a segmented path, tracks weighted
12/7/7/7 days), **Reading** (the open book + "also reading" spines),
**Library** (an open-book spread: liturgy leaf, reading leaf,
Augustine's colophon), **Chant** (the app's three chant recordings —
Veni Creator, Ave Maris Stella, Magnificat — through the shared
AudioService; the ⋯ opens the chant sheet), **Reflections** (latest
journal entry under an illuminated versal), **Prayer Streak** (the
flame; stands directly under Today, because a record of days prayed
belongs beside the day it records and onboarding's closing line promises
it is being kept; tapping it opens the Prayer Record). Three visual
registers, deliberately: frameless (Today, Consecration, Library,
Chant), outlined (Reading, Reflections, Flame at 20pt radius), and no
filled card surfaces on the page — `surface-card` only in the tray and
chant sheet.

The rule's *membership* is edited in `RuleEditorSheet` (Settings →
Devotion → Rule of Prayer, and the Chapel's empty-rule invitations);
`PrayButtonEditorSheet` (quick tap + hold menu) still opens from the
Pray tray's "Edit this menu" row. The one-motion acts remain
`PrayerShortcut`. Prayer Record's standing doors are the flame tile and
Settings → Devotion. The old Me page (`Views/Me/MeView.swift`,
`MeWidgets.swift`, `MePageEditorSheet`) is no longer reachable and kept
only as reference, like `MenuView`; research behind the original design:
"The Oratory Brief" artifact.

### Settings & About Screens

Split in two, each behind its own door in the Chapel day strip, so the
informational pages are never the settings page's attic:

**`AccountView`** (`AppRoute.settings`, the home masthead's **ph-faders**) — every
toggle and choice, set in the Chapel's own voice: a Cinzel plate
("Settings / How your chapel is kept."), then outlined sections with
glyph-led kickers (`AccountSection` — no filled card surfaces, same as
the page they serve):

- **Appearance** — theme (re-themes live), app icon (four alternates)
- **Prayer Experience** — text size, prayer language (English by
  default; the app's first face is the one most users read), Scriptural
  Rosary
- **Devotion** — Rule of Prayer (→ `RuleEditorSheet`), Prayer Record,
  Daily Reminders (toggle, time, sound), What Draws You Here (decides
  the reminder copy pool)
- **Offline** — download every meditation set and audio file

**`AboutView`** (`AppRoute.about`, the home masthead's **ph-info**) — the app's
colophon: the wordmark as masthead, then About Lumen Viae, App
Introduction (re-runs onboarding), Privacy Policy, Help & Support, Send
Feedback, and the footer (version, "Ad Majorem Dei Gloriam"). The sheets
it presents still live in AccountView.swift alongside the shared row
components (`ActionRow`, `ToggleRow`, `AccountFooter`…).

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
│   ├── ChapelTile            # + ChapelPlacement — the Chapel page's vocabulary
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
│   ├── Chapel/               # MyChapelView (the tab), ChapelGrid (arrange
│   │                         # machinery), ChapelTiles, ChapelChant
│   ├── Me/                   # Legacy (unreachable, reference only): MeView,
│   │                         # MeWidgets. Still live: MeCustomizeSheet's
│   │                         # RuleEditorSheet + editor furniture,
│   │                         # PrayButtonEditorSheet, PrayShortcutTray
│   ├── Meditation/           # SelectMeditationView (the shelf), MeditationSetDetailView
│   ├── Consecration/         # 33-day preparation (own NavigationStack)
│   ├── TrueDevotion/         # Book reader
│   ├── Library/              # Spiritual Reading shelf, book page, chapter
│   │                         # reader, contents sheet, transport
│   ├── Resources/            # How to Pray, Marian Library, Scripture, Carlo Acutis,
│   │                         # the Missal and the Office (+ LiturgicalMonthGrid,
│   │                         # the month grid both calendars draw)
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
  size (app-wide, plus the missal's and the reading shelf's own); the Chapel
  tab's arrange-in-place page (tile order, full/half widths, the tray, rule
  of prayer, intentions) and the configurable Pray button (quick act +
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
  text size slider for the liturgical books (15–21pt, `missalTextScale`,
  which the citations and the Office's hours follow too), posture
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
  version.

  **`DivineOfficeView` opens on the hour it is now.** The page has one
  purpose — the present hour reachable in one tap, and obvious at a
  glance which hour that is — so that hour is lifted out of the eight
  into a lit **lancet arch** (`GothicArchShape(riseRatio: 44/354)`, the
  shallower rise, with the app's standard two-shadow halo applied to the
  *shape* rather than a rounded rect). Every other card in the app is a
  16pt rectangle; the arch is why the eye lands there first. It carries
  the page's one filled gold act ("Pray Compline"), and **no corner
  ticks, second border, or ornament divider inside it** — one ornament
  per idea. Its halo is steady; only the lit NOW mark may pulse.

  Beneath it the eight stand in three groups — the night and the dawn,
  the little hours, evening and night — each strung on one strand of
  gold, each bead in its hour's own `skyColor`, so the strand runs dark
  through bright and back to dark over the day. Group headings ride
  behind `showHourGroups`; with them off the eight read as one strand.
  The bar carries Back, the book's name, and **`ph-calendar-dots` as the
  only day-switching control** — an earlier draft's
  `‹ Thursday, 27 August ›` stepper was cut for costing most of the
  first screenful, and must not come back. The ledger never waits on the
  network: the hours are the hours, and the arch's choice of hour is
  read from the clock.

  **English in the chrome, on both Office screens.** The engine answers
  in Latin — "III. classis", "S. Raymundi Nonnati Confessoris" — and
  Latin belongs in the prayer text, not above it. The class is mapped
  client-side (`OfficeRank.englishLabel`), and the feast name and the
  vestment colour, neither of which the breviary carries at all, are
  read from the **missal's** propers for the same date
  (`OfficeViewModel.missalDay`): the same 1962 calendar, already fetched
  and on disk. Silent and never awaited — with the missal unreachable
  the plate falls back to the breviary's own Latin and drops the colour.

  **`CanonicalClock`** (a `Services/` singleton) is the one place that
  says which hour it is now. It sleeps to each boundary rather than
  ticking, and refreshes on foreground; the home ledger's Office row,
  the arch, and the strand's NOW mark all read it, so they roll over
  together. `CanonicalHour.beginsAtClockHour` is the single boundary
  table — `present(atClockHour:)` and the arch's "until Sext at noon"
  are both derived from it, because written separately they agreed only
  by accident. Boundaries are fixed clock times, not solar hours.

  **`OfficeHourView` is the missal's reader.** It hides the system bar
  and carries the same chrome: Back / ☰ / Aa, a jump-to-section rail
  (faded 52pt at its right edge so it reads as scrollable), a 1pt
  progress line, and the active section spied from each section's
  reported top — the same `onGeometryChange` machinery, measured in the
  same content-space coordinates, for the same reasons.

  **The hour is named in the bar and nowhere else on the screen**, and
  the day is stated once beneath it, in two lines: the date with the
  day's class, then the feast. An earlier draft repeated the hour as a
  28pt heading under a bar already reading TERCE, carried the full Latin
  day-title, set a `TERTIA · III. CLASSIS` row, and hung a `‹ TODAY ›`
  stepper below all of it. All four are gone and must not come back —
  the chrome above the text is two lines and a rail, and the reading
  begins about a third of the way up the screen instead of halfway down.
  The date is kept *here* (unlike the landing) because the reader can be
  opened on another day and has no other way of saying which day's
  office you are in; it is a statement, not a control — **the day is
  chosen on the landing**, and the reader carries no calendar. The
  two-line plate still collapses, at 0.64 / 0.29 of **its own measured
  height** rather than the missal's fixed 96/44: on a 46pt plate a fixed
  96 left the text sliding under a plate that was still standing. `OfficeReaderSection` cuts the
  hour into addressable sections (`OfficeSectionView` draws one), so
  the ☰ index and the rail can name and reach them; an unnamed section
  is a continuation and is drawn but never listed. A jump to the
  **last** section anchors `.bottom`, not `.top`: the Conclusio is ten
  lines, cannot rise to the header, and a lazily built column answers
  that request by scrolling past its own end into blank.

  Its sheets are the missal's, minus what the breviary has no data
  for: `OfficeReadingSheet` (language, stacked/side-by-side, size) on
  `MissalSheetShell`/`MissalSheetChip` — no posture cues, no Ordinary
  scope, no High Mass — and `OfficeIndexSheet`, whose detent is
  computed from its own row count. The reading size is
  `missalTextScale`: the two are the same kind of page, and the sheet
  says so. Text still draws through
  `MissalPassageText`/`MissalPairedPassageText`/`MissalColumnPassageText`
  (the Latin and vernacular cells keep the engine's line structure, so
  they pair line for line). The versal opens the hour's first words
  **only when they are words** — an hour beginning "℣. Deus in
  adiutórium" would otherwise gild the versicle mark. The leaf closes
  on the scribe's `explicit` ("EXPLICIUNT LAUDES"), never on
  "Benedicamus Domino", which the Conclusio prints three lines above.

  `OfficeCalendarSheet` is the missal's month grid, and literally so:
  both sheets draw **`LiturgicalMonthGrid`** (roman-numeral month,
  chevrons, the weeks, the press-a-day-to-name-it readout) and supply
  only the three things that differ — the day's mark, what the day is
  called, and the offline row. They were two copies of the same four
  hundred lines, which is how the same defect came to be fixed twice.
  The office names no vestment colour, so each day is marked by
  **rank** instead (`OfficeRank`, parsed from "I. classis"), a gold dot
  that burns brighter for the greater feasts and not at all for a
  feria. A day counts as saved only when all eight of its hours are on
  disk — half a day is no use in a chapel with no signal.

  A month is recorded as loaded only once it has **arrived**: marking
  it before the fetch left a month that failed permanently blank, with
  every retry returning on the guard and nothing saying why. A month
  that cannot be reached says so and offers Try again. Stepping the
  month puts down any save in flight, and a download reports only while
  it still holds the token it started with.

  Hours and days cache in Application Support/Office via
  `OfficeCacheService`; after the first load, today's and tomorrow's
  hours are prefetched quietly and days more than 30 back are pruned.
  Every hour names its source — the texts are The Divinum Officium
  Project's work, and the footer credits it.

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
  own file (Thérèse, Emmerich — 1:1, verified track for track; an
  `offset` covers front-matter tracks the text does not carry, and
  consecutive files a reader labelled "Part 1"/"Part 2" are gathered back
  into one reading),
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

  A book may also name the speed its reader is best heard at
  (`preferredRate` — Thérèse's is 1.5, because Susan Morin's reading runs
  thirteen hours and forty minutes). That is the shelf's opening offer;
  the reader's own choice per book is remembered and outranks it. It is
  kept apart from the app-wide narration speed —
  `AudioService.setPlaybackRate(_:remember:)`, restored on `stop()` — so
  a slow LibriVox volunteer never sets the pace of a Rosary.

  The track ledger is cached under the **`librivoxID`**, not the edition
  fingerprint: swapping a recording has to retire the previous
  recording's ledger, and keyed on the edition it did not, so every
  chapter pointed at the wrong track.

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
  `.scrollPosition(id:)`, and follow-the-voice auto-scroll where the
  sounding track reads this whole chapter — `canFollowText` is the
  test, and it is false over a track holding ten chapters or a chapter
  split across five. The mapping is proportional (paragraph N of M at
  N/M of the reading), the same rule the prayer reader follows, since
  LibriVox gives no per-word timings. The page yields to the hand: any
  scroll the reader makes stops following for four seconds, and
  following's own travel is stamped so it is never mistaken for one.
  Its watcher is mounted in an overlay, never inside the lazy content —
  as the last child of the LazyVStack it would only be built once the
  reader had already scrolled past the whole chapter, so following
  would never start.
  Recordings can be saved per track (`LibraryAudioDownloads`, background
  URLSession) behind the missal's honest offline line — "1 of 13
  readings saved · 11 MB · about 188 MB more".

  **Two ways to keep a page, and they are not the same act.** Select a
  paragraph and the capsule offers NOTE, MARK, SHARE.

  A **note** is something the reader wrote, and the journal is still
  the app's one store for that — `keepAsReflection` composes the
  passage, its citation and the reader's own words into a
  `JournalEntry` carrying `bookID`. The three parts are stored as
  fields (`bookPassage`, `bookCitation`), not inferred by splitting
  the text: the text is what `JournalEntryEditorView` edits, and
  parsing it back apart meant an edited note lost its shape.

  A **mark** is a place and nothing else — no colour, no note, no
  count against the reader, and no review queue. It exists so a reader
  can walk back to a page that struck them. Marks are *not* a
  highlights library and must not grow into one.

  The two differ in durability, and honestly so: a mark on the shelf
  is a chapter and paragraph index, meaningful only inside one cutting
  of an edition, so `retire` lets marks go with the reading place when
  a catalog rule changes. True Devotion's marks are keyed by stable
  chapter slugs and never need retiring. Journal notes hold the
  passage text itself and outlive every re-cut.

  Never a percentage, never a streak, never a count of chapters left
  unread. Time against a **recording** is allowed, because it is a
  fact about a file rather than a judgement of the reader — "2 h 5 m
  read · 7 h 26 m left in the book" is drawn only from tracks the
  alignment maps to a chapter, so a finished book really does reach
  zero. A words-per-minute estimate is never allowed: True Devotion
  has no recording, so its act stays quiet rather than guessing.

### Not built yet

- A Divine Office version/language setting (Monastic, Dominican, and the
  other rubrical versions the API's `/office/versions` already serves) —
  `OfficeAPIService.version`/`.language` are the seam
- Auto-scroll *synced* to audio, word by word. Both readers follow
  proportionally instead — the prayer reader and the Spiritual Reading
  reader — because neither the narration nor LibriVox carries timings
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

### Icons

Two families in `Assets.xcassets/Icons`, both drawn through `AppIcon`
(never `Image(...)` at a call site) and both rendered as templates:
**`ph-*`** are Phosphor, and **`ch-*`** are the app's own devotional
glyphs — `stroke-width="1.5"`, round caps and joins, on a 24×24 viewBox.
A new `ch-*` icon must be stroked at that weight or it stands heavier
than everything beside it. Note that `qlmanage` cannot preview these
faithfully: it renders a stroke-only SVG blank and *fills* path data
meant to be stroked, so check a new glyph in the running app.

One meaning per glyph. The same door wears the same icon everywhere it
appears — the Missal is `ch-altar` on every surface, the Office
`ph-clock`, the Marian Library `ch-lily` — and a glyph standing for a
devotion is the one that devotion's own iconography uses:
`ch-sacred-heart` is Christ's and belongs to the Sacred Heart alone,
while the Seven Sorrows take `ch-sorrowful-heart`, Mary's heart pierced
by Simeon's sword.

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
