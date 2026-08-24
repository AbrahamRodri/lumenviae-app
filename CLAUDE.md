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

**Secondary (Stretch Goal):**

4. **Scriptural Rosary** - A scripture verse for each bead (not just each mystery). This is a more intensive, slower form of prayer. Lower priority for initial release.

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
(`Views/Home/ExploreView.swift`): browse (mysteries / library / all
meditation sets fetched per category) or search all three at once — the
real search field lives on Explore, not on home.

**Pages push, tasks sheet.** Content destinations — the Missal, the
Office, True Devotion, How to Pray, In Scripture, the Marian Library,
Carlo Acutis, Settings, Explore — are `AppRoute` cases that slide in
from the right; each draws its own gold Back in its toolbar (so never
apply `navigationBarHidden` to them). Sheets are reserved for tasks and
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
(a two-column shelf: Missal, Office, True Devotion, How to Pray, In
Scripture, Marian Library, Carlo Acutis, Sacred Record — a one-time
migration inserts it for pages saved before it existed),
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
│   ├── ReminderMessages      # Notification copy pools
│   └── RosaryQuotes          # Daily quotation catalog
├── Services/
│   ├── APIService            # HTTP client (https://lumenviae.fly.dev/api)
│   ├── AudioService          # Narration and chant playback
│   ├── OfflineContentService # Full offline download of text + audio
│   ├── MeditationCacheService, ImageCacheService
│   ├── PrayerHistoryService, PrayerResumeService, ScheduleService
│   ├── FavoritesService, MeditationSetResolver, TrueDevotionLibrary
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
  size; the Me tab's arrangeable "My Oratory" page (widgets, rule of prayer,
  intentions, display name) and the configurable Pray button (quick act +
  press-and-hold tray), all stored in UserDefaults via `UserSettings`.
- **Onboarding** — eight slides, skippable, re-runnable from Account.
- **Daily Missal** — the 1962 propers for any day plus the Ordo Missae, in the
  resources menu. Served live by the third-party Missale Meum API
  (`https://www.missalemeum.com/en/api/v5`, MIT, free to use) through
  `MissalAPIService` — deliberately a separate client from `APIService` so a
  third-party outage never looks like a Lumen Viae failure. Texts arrive as
  `[english, latin]` pairs whose line counts align (both sides keep Divinum
  Officium's line structure), so bilingual reading offers two layouts —
  interlinear line pairs like the prayers, or side-by-side columns like a
  printed hand missal — chosen in a forced first-open sheet and changed any
  time from the Aa text options (`MissalLayout` in `UserSettings`). The
  `|||` format is still not used here; pairing happens in the missal views.
  Citations (`*Ps 138:17*`) and the ℣ ℟ ☩ marks are set in rubric red, and
  the Introit, readings, and Canon open with a gold drop cap. Every fetched
  day is cached in Application Support/Missal (excluded from backup) via
  `MissalCacheService`, and after the first load the coming week, the Ordo,
  and the year's calendar are prefetched quietly — a chapel with no signal
  still gets the right page; days more than 30 back are pruned. The date in
  the header opens `MissalCalendarSheet`: the next 35 days of the 1962
  calendar (feast, class, vestment color, commemorations) plus a date-picker
  jump. Commemorations also appear under the feast header, as a printed
  missal notes them.
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

### Not built yet

- Scriptural Rosary (a verse per bead rather than per mystery)
- A Divine Office version/language setting (Monastic, Dominican, and the
  other rubrical versions the API's `/office/versions` already serves) —
  `OfficeAPIService.version`/`.language` are the seam
- Auto-scrolling meditation text synced to audio
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
