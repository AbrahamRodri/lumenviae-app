# Lumen Viae

> *"Light of the Way"* — a Catholic Rosary meditation and prayer companion for iOS.

Lumen Viae guides you through the Rosary with meditations drawn from the saints,
keeps the days you pray, and carries a small library of Catholic devotion around
it: the 33-day consecration to Mary, the 1962 Missal and the Divine Office, and a
shelf of spiritual classics. It is built for the quiet: dark, gold-lit, and free
of anything that hurries you.

---

## What the app does

### Pray the Rosary

Pick a set of mysteries — Joyful, Sorrowful, Glorious, Luminous, or the Seven
Sorrows of Mary — then a meditation to pray them with. Home proposes the day's
mysteries on the traditional schedule, Sunday following the season. The raised
**Pray** button runs your chosen act in one tap (today's Rosary unless you pick
another); press and hold it for a tray of the devotions you keep.

The player sets each mystery under its painting, the meditation narrated in a
choice of voices, with a text-only reader a tap away. The whole Rosary hangs as
one strand of beads at the right edge: swipe down a bead at a time, and the
decade turns on its own at the next Our Father. On each mystery the strand opens
once the meditation has been heard. With the **Bead counter** off, the player is
a decade-at-a-time screen with arrows, for a hand that keeps its own count. The
Seven Sorrows chaplet is seven sorrows of seven Hail Marys, without the Fatima
Prayer. An unfinished Rosary is offered back on home at the bead where it stopped.

**Pray aloud** (off by default) says every prayer aloud and moves the beads with
the voice, in the meditation's player and the Scriptural Rosary, so the Rosary
can be prayed with the phone in a pocket. Its recordings are fetched in your
voice and kept; the prayers for the Holy Father, the Memorare and the St. Michael
prayer can follow the closing prayer.

### The Scriptural Rosary

A devotion of its own: a verse of the Douay-Rheims for every Hail Mary, all 249
verses bundled in the app, each set beside the same strand of beads the player
hangs. **The Rosary Aloud** prays on the same screens, every prayer said by the
voice and set in full on its bead.

### Choose your meditations

Meditation sets come from the Lumen Viae API, shown as a gallery or a ruled list,
filtered by label (Contemplative, Saints, Reflections, Intentions, Scriptural),
pinned to the top at will, and each opened on a title page before it is prayed.
Authors include St. Alphonsus Liguori, St. John Henry Newman, Bl. Anne Catherine
Emmerich, Ven. Fulton J. Sheen, and others.

### 33-Day Consecration to Mary

A guided preparation after the method of St. Louis de Montfort. Choose a Marian
feast, and the app counts back 33 days of preparation ending on its eve, leaving
the act of consecration for the feast itself. Each day has readings from
Scripture, the *Imitation of Christ* and *True Devotion*, the prayers of its
period (in English, Latin, or both), and a journal prompt. The Veni Creator, the
Ave Maris Stella and the Magnificat have chant recordings.

### Home, Explore, and the Chapel

Home holds the day's mysteries, a grid of the Joyful, Sorrowful and Glorious
Mysteries and the Seven Sorrows (the Luminous under View All), and **Today's
Prayer**: the Total Consecration, then the day's feast over the Mass and the
Office. Settings and About stand in the masthead; the search glass opens
**Explore**, which browses the devotions and the library and searches mysteries,
library pages, short readings and every meditation set at once.

**The Chapel** tab is a page you arrange in place: the next act of your rule of
prayer at the top, then tiles to reorder, set full or half width, or put away in
a tray — **Today** (the rule), **Prayer Streak**, **Consecration**, **Reading**,
**Chant**, **Reflections**, **Liturgy** and **Library**. Long-press to arrange.

### The Mass and the Office

The **Daily Missal** gives the 1962 propers for any day, in Latin, English, or
both, with the whole Ordinary laid through them or the propers alone, from the
Missale Meum API. The **Divine Office** is the Breviarium Romanum under the 1960
rubrics, eight hours, opening on the hour it is now; its texts come from the
app's own `/office` API, which assembles them from a self-hosted Divinum Officium
engine. Both keep the days they fetch and fetch the coming days ahead.

### Spiritual reading

Four public-domain classics — *The Imitation of Christ*, *The Story of a Soul*,
the *Confessions* and *The Dolorous Passion* — are fetched from Project Gutenberg
the first time each is opened, cut into chapters on device, and kept. Three have
LibriVox recordings matched to their chapters, which can be saved for listening
offline. A passage can be kept as a note in the journal or marked as a place to
come back to. The complete *True Devotion to Mary* (Faber's 1862 translation) is
bundled, with your place and your marks kept.

### Journal and Progress

The journal keeps reflections after a Rosary or a consecration day, notes from a
book, and free-standing entries: searchable, editable, and on device only. The
Prayer Record keeps streaks, history and milestones, reached from the Chapel's
Prayer Streak tile, Settings → Devotion, and Explore. Milestones follow the
Church's devotional structures rather than scores — Triduum (3 days), A Faithful
Week (7), Novena (9), Consecration (33), 54-Day Novena, Hundredfold (100), A Year
of Grace (365) — and nothing in the app shames a missed day.

### Resource library

Reached from Explore and the Chapel's Library tile; each short reading opens as a
page of its own, leading on to a feast, a prayer, or the next reading.

- **How to Pray the Rosary** — a course for someone who has never prayed it:
  three lessons (the beads and the order, the prayers, the mysteries), then *Your
  First Rosary*, a guided Rosary with every prayer in full.
- **Finding the Mysteries in Scripture** — each mystery's passage and key verse.
- **The Marian Library** — the next feast of Our Lady, the four Marian dogmas,
  Mary in Scripture, approved apparitions, the Marian saints, the Rosary through
  history, and the titles of Our Lady.
- **St. Carlo Acutis** — his life, his rule of life, and a votive candle.
- **The Devotion in Summary** — a digest of *True Devotion*.

### Making it yours

- **Three themes** — Marian Blue, Midnight, Candlelit (the default) — applied live.
- **Prayer language** — English, Latin, or bilingual in either order.
- **Text size** for the app, with separate sizes for the liturgy and the shelf.
- **Daily reminders** with a choice of bundled sounds, at a time you pick. The
  copy follows what you said drew you to the Rosary
  (`app/Data/ReminderMessages.swift`) and never mentions streaks.
- **Offline downloads** — every meditation set with its painting and narration,
  the consecration chants, and the spoken Rosary's recordings. With them and the
  bundled prayers, verses and books, the Rosary prays without a connection; the
  Missal, the Office and the shelf keep whatever they have fetched.

---

## Architecture

SwiftUI throughout; the one UIKit view is the system mail composer behind Send
Feedback. iOS 17.0 minimum. The module compiles with default `@MainActor`
isolation and approachable concurrency, so types are main-actor isolated unless
marked otherwise; API models carry `nonisolated` Codable conformances because
offline reads decode them off the main actor.

```
app/
├── appApp.swift              @main entry, SwiftData container
├── ContentView.swift         Root: tab switch + NavigationStack
├── Navigation/ ViewModels/   AppRouter and AppRoute; @Observable view models
├── Models/                   API and SwiftData models, the strand, the spoken
│                             script, Chapel tiles, library readings
├── Views/
│   ├── Home/                 Home, Explore, all mysteries
│   ├── Meditation/ Prayer/   The shelf, a set's title page, the player
│   ├── Scriptural/           The Scriptural Rosary (and the Rosary Aloud)
│   ├── Chapel/               The arrangeable page and its tiles
│   ├── Consecration/         33-day preparation (its own NavigationStack)
│   ├── TrueDevotion/         Book reader
│   ├── Library/              Spiritual Reading: shelf, book, chapter reader
│   ├── Resources/            How to Pray, the guided Rosary, In Scripture, the
│   │                         Marian Library, Carlo Acutis, the Missal, the Office
│   ├── Journal/ Progress/ Account/ Onboarding/ Launch/
│   └── Me/                   Legacy, unreachable (its editors and tray still used)
├── Components/               Tab bar, header, cards, the bead strand
├── DesignSystem/             Theme, Typography, AppIcon, Motion, ReadingText
├── Data/                     Bundled prayers, mysteries, verses, consecration
├── Services/                 API clients, audio, caches, offline, settings
└── Resources/                Fonts, True Devotion JSON, reminder sounds
```

### Where the data lives

**The Lumen Viae API** (`https://lumenviae.fly.dev/api`) is a companion Phoenix
app that owns the meditation content, so it can change without an app release:

| Endpoint | For |
|---|---|
| `GET /meditation-sets?category=` | The sets for one set of mysteries |
| `GET /meditation-sets/:id` | A full set: meditations, painting, narration links |
| `GET /meditations/:id/audio` | A freshly signed narration link (`?voice=`) |
| `GET /voices` | The narration voices, default first |
| `GET /prayers/:id/audio` | A consecration chant |
| `GET /rosary/audio` | The spoken Rosary's recordings for one voice |
| `GET /office/…` | A day, an hour, or a month of the Divine Office |
| `POST /completions` | An anonymous note that a Rosary was finished |

**Elsewhere** — the Missal from the Missale Meum API, the shelf's texts from
Project Gutenberg and its recordings from LibriVox. The Scriptural Rosary's
verses came from thedouayrheims.com at generation time; the app never calls it.

**Bundled** — every Rosary prayer in English and Latin, the mysteries themselves
(names, scripture, descriptions and fruits, in `Data/MysteryData.swift`; the app
does not fetch them), the Scriptural Rosary's verses, the 33 days of preparation
and the day of consecration, *True Devotion*, the resource pages and the quotes.

**On device** — SwiftData holds prayer sessions, journal entries, consecration
progress, and reading progress in *True Devotion* and the shelf. `UserDefaults`
holds settings, pinned sets and the unfinished-Rosary snapshot. Application
Support holds the offline sets, narration and paintings, the Missal, Office and
Library caches, and the spoken Rosary's recordings, all excluded from backup.

### Notable services

| Service | Responsibility |
|---|---|
| `APIService` | HTTP client for the Lumen Viae API |
| `AudioService` | Narration and chant playback, Lock Screen and AirPods |
| `SpokenRosaryPlayer` | Prays the Rosary aloud, moving the beads with the voice |
| `RosaryAudioPack` | The spoken Rosary's recordings, fetched per voice and kept |
| `NarrationVoiceCatalog` | The server's narration voices and the one chosen |
| `OfflineContentService` | User-initiated download of sets, paintings and audio |
| `MeditationCacheService` | Prefetches the day's sets so Pray starts at once |
| `MissalAPIService`, `MissalCacheService` | The Missale Meum client and its cache |
| `OfficeAPIService`, `OfficeCacheService` | The `/office` client and its cache |
| `CanonicalClock` | Which canonical hour it is now |
| `LibraryService` | Gutenberg texts and LibriVox track lists (with the other `Library*` services: parsing, track mapping, playback, progress, downloads) |
| `PrayerHistoryService`, `PrayerResumeService` | Streaks and history; the unfinished-Rosary handoff |
| `ScheduleService` | Which mysteries belong to today |
| `UserSettings` | Preferences and daily reminder scheduling |
| `TrueDevotionLibrary` | Loads and indexes the bundled book |

---

## Building

Requires Xcode 26 or later. Open `app.xcodeproj` and run the `app` scheme; the
deployment target is iOS 17.0. No package manager, no secrets, and nothing is
generated at build time — `Data/ScripturalRosaryData.swift` and
`Resources/TrueDevotionBook.json` are generated by the scripts in `Tools/` and
checked in. New `.swift` files under `app/` are picked up by Xcode's
file-system-synchronized groups; there is nothing to add to the project file.

The API is public. The app's only write is the anonymous completion, which
carries the set and whether it was prayed aloud, and no identifier. A debug build
can be pointed at another server with the `LUMEN_VIAE_API_BASE_URL` environment
variable.

---

## Design system

Every colour, gold included, comes from the active theme through `AppColors`;
never hardcode a hex. The main tokens (full palettes in
`app/DesignSystem/Theme.swift`):

| Token | Marian Blue | Midnight | Candlelit (default) |
|---|---|---|---|
| Background | `#0D1730` | `#131324` | `#0A0A15` |
| Card | `#17284E` | `#1F1F38` | `#151521` |
| Gold | `#D9B84A` | `#D4AF37` | `#E3BC5B` |
| Gold light | `#E9CC6E` | `#E8C547` | `#F3D89A` |
| Cream | `#F4EFE2` | `#F5F0E1` | `#F6F1E4` |
| Secondary text | `#93A5C8` | `#9C9CB5` | `#8B8BA5` |

Type is Cinzel for display and EB Garamond for reading, wrapped by `AppFonts`;
long text goes through `ReadingText` and `PrayerText`. Icons are Phosphor
(`ph-*`) and the app's own devotional glyphs (`ch-*`, `lv-*`) in the asset
catalog, drawn through `AppIcon`.

---

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — working reference for AI assistants and contributors
- [`CHANGELOG.md`](CHANGELOG.md) — what changed in each release
- [`GUIDED_ROSARY_NOTES.md`](GUIDED_ROSARY_NOTES.md) — design notes for the guided and spoken Rosary modes
- [`ROSARY_RESEARCH_NOTES.md`](ROSARY_RESEARCH_NOTES.md) — user research on Rosary apps and praying the Rosary
- [`Tools/TrueDevotion/`](Tools/TrueDevotion/README.md) — the *True Devotion* text pipeline
- [`Tools/ScripturalRosary/`](Tools/ScripturalRosary/generate.py) — generates the Scriptural Rosary's verses
- [`Tools/MotionSheet/`](Tools/MotionSheet/README.md) — a simulator recording as a contact sheet, for judging motion

---

*Ad Majorem Dei Gloriam*
