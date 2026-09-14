# Lumen Viae - AI Reference Guide

> "Light of the Way" - A Catholic Rosary meditation and prayer companion app

## App Overview

Lumen Viae is an iOS app built with SwiftUI that guides users through praying the Rosary with meditations, scripture, and tracking. The app has an elegant, dark theme with gold accents inspired by traditional Catholic aesthetics.

## Core User Flow

```
Home Screen
    │
    ├── Featured card: today's mysteries ("Pray with a Meditation")
    │   └── Goes to: Select Meditation View
    │       (its quiet line, "The Scriptural Rosary", goes to that title page)
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
    │   On the beads (default): one strand at the right edge, swipe down
    │   a bead at a time, the mystery turns on its own. Off the beads
    │   (Settings → Prayer Experience): arrows and a swipe between
    │   mysteries, no strand.
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

4. **Scriptural Rosary** - A scripture verse for each bead (not just each mystery). This is a more intensive, slower form of prayer. **Built** as a devotion of its own rather than a meditation type or a setting: its own title page and prayer screen, reached from Explore, the Pray tray, and In Scripture (see the Built list below). The meditation's player prays on the same strand, without the verses.

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

The home header is the wordmark framed by the app's chrome:
**ph-faders → Settings** and **ph-info → About** together on the left,
the search glass alone on the right. No flame — the streak lives in the Chapel's own Prayer Streak
tile, whose kicker carries the Prayer Record link (with Settings →
Devotion, the only doors to the Progress page). Settings and About sat
in the Chapel's day strip until that strip was left to read the
liturgical day alone: app-level chrome on a page-level strip was
findable only by whoever thought to look there. The masthead is now the
**only** door to either — the Chapel's foot used to name them in words
as well, and that duplicate was removed; the foot is the arrange
control and the imprint, nothing else.

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
(Mt 7:7), the five devotions as a ruled ledger with the Scriptural
Rosary's door beneath them, the library shelf —
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
order): **Today** (the rule as a ledger, and the picker itself — the
focus block above it carried a "CHOOSE ANOTHER" jump down to this tile
and no longer does, since the ledger is a scroll away on the same page;
manual acts toggle on tap,
watched acts open themselves; Rosary/chaplet/consecration check from
real data, Mass/Office by hand, reset each morning), **Consecration**
(de Montfort's four preparations as a segmented path, tracks weighted
12/7/7/7 days), **Reading** (the open book + "also reading" spines),
**Library** (Explore's three sections over Augustine's colophon, so one
vocabulary names one set of doors: **The Liturgy** — Missal and
Breviary — and **Spiritual Reading** — True Devotion and the shelf —
stand as the two leaves of an open book hinged on the gold fold, and
**The Study** — How to Pray, In Scripture, the Marian Library, Carlo
Acutis — is a ruled two-column index at the foot. A heading on this
tile must be true of every door beneath it: How to Pray and In Scripture
once sat under The Liturgy, then the books sat under The Study, and each
made a heading a lie. "Reading" was the obvious name for the books and
the wrong one, since Spiritual Reading is a door inside it. The half
tile keeps the two liturgical books and makes "6 more on the shelf" a
door to Explore rather than a note), **Chant** (the app's three chant recordings —
Veni Creator, Ave Maris Stella, Magnificat — through the shared
AudioService; the ⋯ opens the chant sheet), **Reflections** (latest
journal entry under an illuminated versal), **Prayer Streak** (the
flame; stands directly under Today, because a record of days prayed
belongs beside the day it records and onboarding's closing line promises
it is being kept; tapping it opens the Prayer Record). Three visual
registers, deliberately: frameless (Today, Consecration, Library,
Chant), outlined (Reading, Reflections, Flame at 20pt radius), and no
filled card surfaces on the page — `surface-card` only in the tray and
chant sheet. The default order alternates the two — Today, Streak,
Consecration, Reading, Chant, Reflections, Library — so no two
hairline sections run together and no two cards stack; the live
sections lead and the Library, the page's index of doors, stands last,
its colophon the right last line before the foot's imprint. The day
strip wraps a long feast to a second line rather than cutting it
mid-word, and the flame card's week rides on its kicker line so the
streak's own name never has to.

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
  default; the app's first face is the one most users read), Pray on
  the Beads (the meditation player's strand; see the Core prayer flow)
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
│   ├── RosaryStrand          # + BeadPosition — the whole Rosary as one string
│   ├── Consecration{Day,Phase,Prayer,Progress}
│   ├── TrueDevotionBook, TrueDevotionReadingProgress
│   ├── LibraryBook           # + catalog entry, parsing rules, LibriVox models
│   ├── BookReadingProgress                  (SwiftData)
│   ├── PrayerShortcut                       # + MeWidget — personalization vocab
│   └── StreakMilestone, MarianFeastDay, BilingualConsecrationPrayer
├── ViewModels/               # @Observable
│   ├── HomeViewModel, MeditationSelectionViewModel, MeditationSetDetailViewModel
│   ├── PrayerSessionViewModel, ScripturalRosaryViewModel, ConsecrationViewModel
│   └── TrueDevotionReaderViewModel
├── Views/
│   ├── Home/ Prayer/ Journal/ Progress/ Account/
│   ├── Scriptural/           # ScripturalRosaryView (the title page),
│   │                         # ScripturalRosaryPrayerView (the prayer)
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
│                             # StreakWidget, PrayerPaintingStage (the player's
│                             # ground), RosaryStrandView, BeadStatusRow
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

  **The bead is the unit** (the "Bead-First Rosary Prayer Flow" handoff).
  The whole Rosary hangs as one strand at the right edge of the player
  (`RosaryStrandView`, hung by `.rosaryStrand(_:)` at the same place on
  both players): prayed beads run off below the hand, the bead under the
  hand rests at the window's middle, and the beads to come descend from
  above, Our Father beads larger and carrying their numeral so the next
  decade is seen approaching. It is a readout, never tappable. Swipe
  **down** for the next bead, up for the one before; the decade turns
  on its own when the next Our Father arrives (medium haptic; a bead is
  `.selection`), and there are no arrows between mysteries and no
  horizontal swipe — nothing but the beads moves the Rosary forward.
  The meditation belongs to the Our Father bead (heard or read there);
  the ten Hail Marys are prayed with only the count beside you, in
  `BeadStatusRow` — OUR FATHER · a cue ("Listen to the meditation, then
  swipe down for the first Hail Mary") — which also taps forward and
  holds back, and is what the reader carries in place of the strand.
  The Glory Be has no bead of its own: it is drawn on the next decade's
  Our Father bead, and after the last decade on one final bead labelled
  GLORY BE · AMEN, where the cue gives way to the AMEN button. A swipe
  never finishes a Rosary. The arithmetic — decade length, a bead's
  linear index, labels, numerals — is `Models/RosaryStrand.swift`, used
  by both view models; `BeadPosition` (mystery + bead) is what the one
  haptic keys on, so a step across a decade's end ticks once.

  **The beads are optional on the meditation's player**
  (`userSettings.prayOnBeads`, on by default; Settings → Prayer
  Experience → "Pray on the Beads", and the player's ⚙ playback sheet
  so it can be changed mid-Rosary). Off, the player is the
  decade-at-a-time screen it was for a hand that keeps its own count:
  the mystery strand in the header, arrows flanking the transport (→
  becomes the AMEN check on the last mystery), a horizontal swipe
  between mysteries (live in the reader too, which has no arrows), the
  one-time `PrayerSwipeHint`, and no strand or bead row. The Scriptural
  Rosary is a verse per bead and has no other way to be prayed, so the
  setting does not reach it. Resume keeps `(mysteryIndex, beadIndex)`
  (`InProgressPrayer.beadIndex`, optional for older snapshots).
  The painting, its frost and its scrim are `PrayerPaintingStage`,
  shared with the Scriptural Rosary, which uses its `.veiled` style.
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
  as a devotion of its own (`Views/Scriptural/`). It was a Prayer
  Experience toggle that grew a verse band on the meditation's player;
  that put two readings on one screen, and a person who wanted the
  Gospel on the beads had to find a switch in Settings to get it. Now
  it has its own doors and its own two screens, and the toggle is gone.

  **Doors:** THE SCRIPTURAL ROSARY, the quiet line under PRAY WITH A
  MEDITATION on the home page's featured card (the button was "Begin
  the Rosary" until this line stood under it, and then two lines said
  "Rosary" without saying how they differed; each now names what will
  be on the beads, and the Chapel's focus block says the same words for
  the same act; the line opens the title page with the day's mysteries
  chosen — named, because an earlier "Or pray it in Scripture" read as
  a footnote to the button). The card itself is TODAY'S MYSTERIES over
  the devotion's name — it used to headline the first of the five
  mysteries with its passage, which made one decade the subject of a
  button that prays all of them — and nothing stands between the title
  and the button; the row beneath the five mysteries
  on Explore (and typed search); the `PrayerShortcut.scripturalRosary`
  act — Pray tray, quick tap, Rule of Prayer, the Chapel's focus — which
  goes straight to the day's mysteries the way Today's Rosary does; and
  "Or pray the Scriptural Rosary" inside In Scripture's how-to card. The
  act stands second in the tray by default, and a tray saved before it
  existed is given it once, under Today's Rosary
  (`userSettings.prayTrayOfferedScriptural`) — a devotion that is only
  in Explore is one nobody finds, which is how the home link and the
  tray row came to be. The Chapel's rule
  counts it by name (`ScripturalRosaryViewModel.devotionName`, which is
  what `PrayerSession.meditationType` records); it also counts as the
  day's Rosary, since it is one.

  **`ScripturalRosaryView`** is the title page, set like a meditation
  set's: kicker, ornament, name, the chosen mysteries' painting in the
  arch, then a ledger — About, The mysteries (the picker: a bead per
  set, today's marked TODAY and chosen to begin with, nothing
  remembered), The first decade (the first mystery and its first
  verse), From (Douay-Rheims) — and PRAY alone at the foot on
  `PrayFootScrim`. `SetSection` and the scrim are shared with the set
  detail rather than copied.

  **`ScripturalRosaryPrayerView`** is the handoff's 3a: the mystery's
  painting edge to edge under a veil (`PrayerPaintingStage(style:
  .veiled)` — 55% opacity, a gradient darkest at head and foot, lifted
  with the chrome), the verse standing in the middle of it on the left
  (kicker of two lines, the verse in italic at the reading size + 3,
  citation · bead count, the cue), and the same strand the meditation's
  player hangs at the right edge (`RosaryStrandView`). Positions run
  Our Father → ten Hail Marys → Glory Be: the Our Father bead announces
  the mystery (its description, passage and fruit), each Hail Mary
  carries its verse, and the decade prayed the column reads the
  doxology (Latin when Latin alone is the prayer language) under GLORY
  BE · DECADE COMPLETE, with the next mystery named in the cue. **Swipe
  down for the next bead, up for the one before; the decade turns on
  its own** — there are no arrows and no swipe between mysteries. An
  earlier draft walked the beads with two arrows, and before that a
  gold disc stood between them; both are gone, and must not come back:
  nothing but the beads moves the Rosary forward. The column still taps
  forward and long-presses back (VoiceOver cannot swipe), and the one
  haptic keys on `beadPosition`. The header is × · SCRIPTURAL ROSARY ·
  Aa (`ReaderTextOptionsSheet` without its narration section); the foot
  is the still mystery strand over "FIRST OF FIVE MYSTERIES" and the ⋯
  tray with no download row. The handoff drew a play disc in that foot
  because it was made against the verse-band-on-the-player snapshot;
  this devotion has no narration, so there is none. On the last bead
  the cue gives way to AMEN; no narration, no reader, no audio session;
  completion records locally through `CompletedPrayer` (the completion
  screen takes that value now, not a set) and never posts to the API.
  An interrupted one resumes from Home's card (`InProgressPrayer.kind`),
  on its own screen, at its bead.

  The 249 verses are **bundled** (`Data/ScripturalRosaryData.swift`,
  keyed `"<category>_<order>"` like MysteryData's fruits) — prayer must
  never need a signal. The file is GENERATED by
  `Tools/ScripturalRosary/generate.py` from the Original Douay-Rheims
  API (thedouayrheims.com, CC0): the curated verse references live in
  the script; edit there and rerun, never hand-edit the Swift.
  Narrative mysteries walk their Gospel scene; the Assumption and
  Coronation use the liturgy's own typology (Canticles, Psalms, Judith,
  Ecclesiasticus, the Apocalypse).
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
  on blank lines, `─────` rules become ornament dividers, a paragraph opening
  `# ` is the reading's own title — set in the display face, never as a first
  sentence, and never given the versal, which falls to the prose beneath it —
  optional drop cap)
  or `PrayerText` (verse/stanza text, including the `|||` bilingual line-pair
  format) in `DesignSystem/ReadingText.swift`. Spacing comes from
  `ReadingTypography` and scales with the font size — don't hand-roll
  `lineSpacing` magic numbers on reading surfaces. Reading blocks are 15–16pt
  minimum in cards, 17–18pt in immersive readers; tap targets stay ≥44pt.
- **Prayers are set in a prayer-book grammar** that `PrayerText` reads from
  the text itself (`PrayerMarkup`, same file), so a prayer is written the way
  a printed book prints it and never as a wall of text: ℣ ℟ ✠ in rubric red
  (`Rubric.red`, the missal's vestment red, shared with the missal and the
  Office); a litany states its response once at the head of each group after
  its ℟ — "Holy Mary, ℟. pray for us." — and every invocation beneath answers
  it, the invocations one to a line and the response stepped back into
  italic; a canticle's verses are pointed at the mediant with ` * ` (the
  asterisk red, the verse broken there, the second half hung in); a line in
  [square brackets] is a rubric ("[Let us pray.]"); a stanza of one long line
  is prose, takes the reading face, and the first such paragraph can open on
  a versal (`showsDropCap`); a stanza of short lines is verse at the tighter
  quote leading. The consecration's prayers (`Data/BilingualConsecrationPrayers.swift`,
  `Data/ConsecrationData.swift`) are written in it, with the Liber's accents
  on the Latin. The English and Latin of a bilingual prayer pair **line for
  line, blank lines included**, or the bilingual modes fall back to two
  blocks. The Litany of the Holy Ghost, Montfort's two prayers and the Act of
  Consecration exist in English alone — no Latin has been invented for them,
  and none should be.
- **The versal (`DropCapText`) is laid over a first-line indent**, never set
  in the first line's text box: Cinzel's descent at 1.6× the body is twice
  EB Garamond's, and in the line it opened a hole under the first line of
  every reading that opened on one. The indent is a single space kerned to
  the measured width of the letter, and the initial's baseline sits on the
  first line's.

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

### Motion

`DesignSystem/Motion.swift` holds the app's named motions — the `Motion`
enum — and every call site should reach for one before writing a
duration: `beadSlide` and `beadSettle` (the strand), `words` (a bead's
name, verse or cue changing), `decadeTurn` (painting, kicker and title
crossfading to the next mystery), `chrome`, `panel` (a reader or tray
arriving), `settle` (a press or toggle landing), `crossfade` (content
changing in place), and `ease(_:)`/`travel(_:)` — the design system's
cubic-bezier curves the missal and office readers use. Springs settle
and never bounce; the two press styles (`SacredCardButtonStyle`,
`GoldCTAButtonStyle`) share one beat, and bare glyphs — the header's
glass, a month arrow, a tab — take `QuietGlyphButtonStyle` so no chrome
tap feels dead.

Three rules, learned the hard way:

- **Words that change crossfade in place.** A `Text` whose value changes
  gets `.contentTransition(.opacity)` (or `.numericText()` for a count,
  which rolls its digits) under an `.animation(Motion.crossfade, value:)`.
  Re-identifying a block with `.id()` to fade it is wrong inside a
  `VStack`: the old and new blocks are laid out *together* for the
  length of the transition, and the foot stands twice as tall for half
  a second.
- **Exclusive branches share a slot.** Two views that replace each other
  (`if loading … else …`, a `switch` over states, browse ⇄ results) are
  wrapped in a `ZStack` with `.transition(.opacity)` on each branch and
  `.animation(…, value:)` on the stack, so they crossfade over each
  other. A `@ViewBuilder` branch that emits *several* views must be
  wrapped in its own `VStack` inside the slot, or the `ZStack` stacks
  its sections on top of one another (Explore did this once).
- **A tab turns through the ground, never across it.** `ContentView`'s
  `tabTurn` fades the leaving page out fast and the arriving page in a
  beat later (with a 6pt rise), over `AppColors.appGradient` laid
  *inside* the NavigationStack: while neither page is opaque the
  stack's own white background shows through, and a crossfade of two
  full pages ghosted one through the other. **Never fade a view that
  holds its own NavigationStack** — its white ground blends to grey;
  the Consecration tab arrives whole under a veil of the gradient that
  lifts (`consecrationArrivals`) instead.
- **Reduce Motion is honoured** at every scripted sequence (the Home
  header's streak intro, the completion badge) and every drift: scale,
  blur and offset fall away, timings shorten, crossfades remain. Direct
  manipulation — the strand following a finger — is not motion and
  stays.

The player's motion: the strand **follows the finger** while a swipe is
under way (`RosaryStrandView.follow`, a tanh curve reaching about one
bead's length, a third of that at either end of the Rosary), the words
under it dim as it goes, and on release the string slides the rest of
the way on `Motion.beadSlide` while the ring passes from the bead
leaving the hand to the one arriving — `RosaryBead` is one view whose
parts light and dim, never three views swapped. Let go short of a bead,
the string comes back on `beadSettle`. The new bead's words arrive from
the side the string came from (`beadWordsArrival`, a keyframe nudge
rather than a transition, so old and new words move the same way
whichever way the last move went). The decade turning — the one move
where the strand itself stays put, since the Glory Be is said on the
next decade's Our Father bead — sends a ripple out from the bead under
the hand (`DecadeTurnRipple`), and the strand is let down from above
when the screen opens.

**Verify motion with a recording, not screenshots**: `Tools/MotionSheet`
lays a simulator recording out as a contact sheet of timestamped frames.
Single screenshots run at three or four a second and miss a 0.3s
transition entirely.

### Lines and Edges

- **Every hairline is `AppLine.hairline`** (`DesignSystem/Theme.swift`):
  two device pixels, whatever the screen's scale. The app once drew its
  card borders and rules at `0.5` — a pixel and a half on a 3× screen,
  which can never sit on the pixel grid: it straddled two rows at half
  strength and swelled wherever a rounded corner's curve flattened into
  the edge, so a card's border read thick at its corners and faint along
  its sides. Never write `lineWidth: 0.5` or `frame(height: 0.5)`.
- **Every `.sheet` carries `.presentationBackground(AppColors.background)`**
  (the prayer trays use `cardBackground`). A sheet's own container is the
  system's white; the content's dark ground is clipped by the same
  rounded rim, and at that rim's anti-aliased edge the white shows
  through as a hairline around the top of every tray. The background
  goes on the sheet's content view, beside its detents.

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
