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
Select Meditation View
    │
    ├── Traditional Meditations
    ├── St. Louis de Montfort
    └── Scriptural Rosary
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
| Sunday | Glorious | Resurrection & Glory |
| Monday | Joyful | Christ's Early Life |
| Tuesday | Sorrowful | Christ's Passion |
| Wednesday | Glorious | Resurrection & Glory |
| Thursday | Joyful | Christ's Early Life |
| Friday | Sorrowful | Christ's Passion |
| Saturday | Joyful | Christ's Early Life |

> **Note:** This is the traditional pre-2002 schedule. The Luminous Mysteries (added by Pope John Paul II) are available in the app but not part of the default daily rotation. Users can always manually select Luminous from the Sacred Mysteries grid.

**Stretch Goals:**
- [ ] Setting to enable "Modern Schedule" (Thursday = Luminous)
- [ ] Liturgical calendar integration (Sunday varies: Joyful during Advent/Christmas, Sorrowful during Lent, Glorious during Easter/Ordinary Time)

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
| Home | Yes | Today's mysteries, resume card, mystery grid, daily quote |
| Consecrate | Yes | The 33-day preparation for Marian consecration |
| Journal | Yes | Reflections, searchable, stored on device |
| Progress | No — home header flame | Streaks, prayer history, milestones |
| Account | Yes | Theme, app icon, prayer language, reminders, offline downloads |

The **Pray** button raised over the bar starts today's Rosary directly, resolving
the day's mysteries and a meditation set without going through the picker.

> Journal is **not** blocked on the API. Entries are a local SwiftData model
> (`Models/JournalEntry.swift`); nothing is sent to the server.

### Account Screen Structure

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
│   └── StreakMilestone, MarianFeastDay, BilingualConsecrationPrayer
├── ViewModels/               # @Observable
│   ├── HomeViewModel, MeditationSelectionViewModel
│   ├── PrayerSessionViewModel, ConsecrationViewModel
│   └── TrueDevotionReaderViewModel
├── Views/
│   ├── Home/ Meditation/ Prayer/ Journal/ Progress/ Account/
│   ├── Consecration/         # 33-day preparation (own NavigationStack)
│   ├── TrueDevotion/         # Book reader
│   ├── Resources/            # How to Pray, Marian Library, Scripture, Carlo Acutis
│   ├── Onboarding/           # 7-slide first run + RosaryMethodsView
│   └── Launch/
├── Components/               # CustomTabBar, HeaderView, MysteryCard,
│                             # QuoteSection, MeditationOptionCard, MenuView,
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

- **Core prayer flow** — day-based mysteries, meditation picker with label
  filtering and favorites, decade-by-decade prayer screen with bead tracking,
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
- **Personalization** — three themes, four app icons, prayer language, text size.
- **Onboarding** — seven slides, re-runnable from Account.

### Not built yet

- Scriptural Rosary (a verse per bead rather than per mystery)
- Auto-scrolling meditation text synced to audio
- Haptic feedback during prayer
- A setting to switch between the Traditional and Modern (Luminous Thursday)
  schedules — `ScheduleService` is the seam for it
- Liturgical calendar integration: seasonal Sundays, feast-day overrides
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
- Meditation narration audio (presigned URLs, ~24h)
- Consecration chant audio (presigned per prayer)

**Bundled in the app** — doctrinal and stable, so it must work with no network:
- Every Rosary prayer, English and Latin (`Data/BilingualPrayer.swift`)
- The 33 consecration days and their prayers (`Data/ConsecrationData.swift`)
- *True Devotion to Mary* (`Resources/TrueDevotionBook.json`)
- The Marian library, the how-to guide, the daily quotes

**On device:**
- Preferences (UserDefaults), favorites, reading progress
- Prayer sessions and journal entries (SwiftData) — never sent to the server
- Downloaded sets and audio (Application Support, excluded from iCloud backup)

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
GET /meditation-sets/:id                # Full MeditationSet with meditations
GET /prayers/:prayerId/audio            # Presigned chant URL for a consecration prayer
```
Meditation audio arrives as an `audio_url` on each meditation rather than from a
dedicated endpoint. There is no journal endpoint and none is planned — journal
entries are local.

## Glossary

- **Decade:** One Our Father + 10 Hail Marys + Glory Be (one mystery)
- **Mystery:** A scene from Jesus/Mary's life to meditate on
- **Rosary:** Full prayer = 5 decades (one set of mysteries)
- **Chaplet:** Shorter prayer devotion (like Seven Sorrows)

## Git Commit Guidelines

**IMPORTANT**: Do NOT add AI co-author attribution to commits. All commits should be attributed to the human developer only.
