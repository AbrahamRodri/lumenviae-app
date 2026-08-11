# Lumen Viae

> *"Light of the Way"* — a Catholic Rosary meditation and prayer companion for iOS.

Lumen Viae guides you through the Rosary with meditations drawn from the saints,
tracks the days you pray, and carries a small library of Marian devotion. It is
built for the quiet: dark, gold-lit, and free of anything that hurries you.

---

## What the app does

### Pray the Rosary

Pick a set of mysteries — Joyful, Sorrowful, Glorious, Luminous, or the Seven
Sorrows of Mary — then choose how you want to meditate on them. The home screen
proposes the day's mysteries on the traditional schedule, and the raised **Pray**
button in the tab bar starts that Rosary in one tap.

Each decade shows the mystery, its scripture, and the meditation text, with
optional narrated audio. Bead progress is tracked as you go, and an unfinished
Rosary is offered back to you on the home screen so you can resume where you
stopped.

### Choose your meditations

Meditation sets come from the Lumen Viae API and are browsed by label —
Contemplative, Saints, Reflections, Intentions, Scriptural. Filter chips combine,
and any set can be favorited to pin it to the top of the picker. Authors include
St. Louis de Montfort, St. Alphonsus Liguori, Bl. Anne Catherine Emmerich,
Ven. Fulton J. Sheen, and others.

### 33-Day Consecration to Mary

A full guided preparation for Marian consecration after the method of
St. Louis de Montfort: choose a Marian feast day to consecrate on, and the app
counts back 33 days and walks you through each one — the day's scripture, a
reading from *True Devotion* or the *Imitation of Christ*, the prayers of the
phase (in English, Latin, or both), and a journal prompt. Chant audio is
available for the consecration prayers.

### Read *True Devotion to Mary*

The complete text of St. Louis de Montfort's *True Devotion to Mary* (Faber's
1862 translation, public domain), chaptered, with reading progress kept per
chapter.

### Journal

Reflections written after a Rosary or a consecration day are kept on device,
searchable, and editable. Entries can be tied to the mystery you were praying or
written free-standing.

### Progress

Prayer streaks and history, reached from the flame in the home header. Streak
design is deliberately non-punitive: milestones are framed as devotional
structures (novenas, octaves) rather than scores, and nothing in the app shames a
missed day.

### Resource library

Reached from the menu:

- **How to Pray the Rosary** — a step-by-step guide, the full text of every
  Rosary prayer in English and Latin, and St. Louis de Montfort's methods.
- **Finding the Mysteries in Scripture** — a key verse and fruit for each mystery.
- **Marian Theology Library** — the four Marian dogmas, Mary in Scripture,
  approved apparitions, the Marian saints, the Rosary through history, and the
  titles of Our Lady.
- **St. Carlo Acutis** — a digital altar.

### Making it yours

- **Three themes** — Marian Blue, Midnight, Candlelit — applied live across the app.
- **Four app icons.**
- **Prayer language** — English, Latin, or bilingual in either order.
- **Text size**, and an image-free prayer mode.
- **Daily reminders** with a choice of bundled bells, at a time you pick. The
  reminder copy follows what you said drew you to the Rosary (see
  `app/Data/ReminderMessages.swift`) and never mentions streaks or implies you
  are behind.
- **Offline downloads** — every meditation set and audio file saved to disk, so
  the whole app prays without a connection.

---

## Architecture

SwiftUI throughout, no UIKit views. iOS 17.0 minimum. The module compiles with
Swift's default `@MainActor` isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
and approachable concurrency enabled, so types are main-actor isolated unless
marked otherwise — API models carry `nonisolated` Codable conformances because
offline reads decode them off the main actor.

```
app/
├── appApp.swift              @main entry
├── ContentView.swift         Root: tab switch + NavigationStack
├── Constants.swift           Strings, Color(hex:)
├── Navigation/               AppRouter, AppRoute
├── Models/                   API models, SwiftData models, enums
├── ViewModels/               @Observable view models
├── Views/
│   ├── Home/ Meditation/ Prayer/ Journal/ Progress/ Account/
│   ├── Consecration/         33-day preparation
│   ├── TrueDevotion/         Book reader
│   ├── Resources/            Guides and libraries
│   ├── Onboarding/           7-slide first run
│   └── Launch/
├── Components/               Tab bar, cards, header, menu
├── DesignSystem/             Theme, Typography, AppIcon, Motion, SacredComponents
├── Data/                     Bundled content (prayers, consecration days, quotes)
├── Services/                 API, audio, caching, storage, settings, offline
└── Resources/                Fonts, True Devotion JSON
```

### Where the data lives

**From the API** (`https://lumenviae.fly.dev/api`) — mysteries, meditation sets
and their text, meditation audio URLs, consecration chant audio. A companion
Phoenix web app owns this content so it can be updated without an app release.

**Bundled in the app** — Rosary prayer texts, the 33 consecration days, the
*True Devotion* book, the Marian library, the daily quotes. This content is
doctrinal and stable; it does not belong behind a network call.

**On device** — settings (`UserDefaults`), prayer sessions and journal entries
(SwiftData), favorites, reading progress, and the offline content cache
(Application Support, excluded from iCloud backup).

### Notable services

| Service | Responsibility |
|---|---|
| `APIService` | HTTP client for the Lumen Viae API |
| `AudioService` | Narration and chant playback |
| `OfflineContentService` | User-initiated download of all text and audio |
| `MeditationCacheService` | In-session caching of fetched sets |
| `PrayerHistoryService` | Streaks and prayer history |
| `PrayerResumeService` | The unfinished-Rosary handoff |
| `ScheduleService` | Which mysteries belong to today |
| `UserSettings` | Preferences and daily reminder scheduling |
| `TrueDevotionLibrary` | Loads and indexes the bundled book |

---

## Building

Open `app.xcodeproj` in Xcode and run the `app` scheme. No package manager, no
generated files, no secrets — the API is public and read-only.

The project uses Xcode's file-system-synchronized groups, so new `.swift` files
under `app/` are picked up automatically; there is nothing to add to the project
file.

---

## Design system

| Token | Value |
|---|---|
| Gold | `#d4af37` |
| Gold light | `#e8c547` |
| Cream | `#f5f0e1` |
| Secondary text | `#a0a0b0` |

Backgrounds and card colors come from the active theme rather than fixed hexes —
read them from `AppColors`, never hardcode. Type is Cinzel for display and
EB Garamond for reading, wrapped by `AppFonts`; icons are Phosphor (`ph-*`) and a
set of custom Catholic glyphs (`ch-*`) in the asset catalog, drawn through
`AppIcon`.

---

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — working reference for AI assistants and contributors
- [`ARCHITECTURE_DIAGRAM.md`](ARCHITECTURE_DIAGRAM.md) — consecration feature data flow
- [`BILINGUAL_PRAYER_GUIDE.md`](BILINGUAL_PRAYER_GUIDE.md) — how bilingual prayer text is authored
- [`ROSARY_RESEARCH_NOTES.md`](ROSARY_RESEARCH_NOTES.md) / [`GUIDED_ROSARY_NOTES.md`](GUIDED_ROSARY_NOTES.md) — research behind the content
- [`Tools/TrueDevotion/README.md`](Tools/TrueDevotion/README.md) — the book text pipeline

---

*Ad Majorem Dei Gloriam*
