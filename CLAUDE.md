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

| Tab | Purpose | Status | Priority |
|-----|---------|--------|----------|
| Home | Daily mystery, featured prayer, quick access | UI Complete | P0 |
| Journal | Reflection entries after prayer sessions | Not Started | P2 (blocked) |
| Progress | Prayer streaks, statistics, achievements | Not Started | P1 |
| Account | Preferences, audio settings, notifications | Design Complete | P1 |

> **Note:** Journal is blocked until the web app API supports journal entries. Focus on core prayer flow first, then progress/settings, then journal last.

### Account Screen Structure

**User Profile**
- Profile picture, name, membership status (Premium Member)

**Prayer Experience**
- Audio Auto-play (toggle)
- Gregorian Chant / Background ambiance (selection)
- Text Size (slider: small ↔ large)

**Devotion**
- Daily Reminders (toggle + time picker, e.g., "06:00 AM • Angelus")
- Language (selection: "Latin & English", etc.)

**About**
- About Lumen Viae
- Privacy Policy
- Help & Support

**Footer**
- App version (e.g., "Lumen Viae v1.0.0")
- Tagline: "Ad Majorem Dei Gloriam"

## Architecture

### Current Structure (UI Layer Only)

```
app/
├── appApp.swift              # App entry point (@main)
├── ContentView.swift         # Root view with tab navigation
├── HomeView.swift            # Main home screen
├── SelectMeditationView.swift # Meditation type selection
├── Constants.swift           # Colors, fonts, strings
└── Components/
    ├── CustomTabBar.swift
    ├── HeaderView.swift
    ├── MysteryCard.swift
    ├── QuoteSection.swift
    ├── MeditationOptionCard.swift
    └── StreakWidget.swift
```

### Recommended Architecture (To Implement)

```
app/
├── App/
│   └── appApp.swift
├── Models/
│   ├── Mystery.swift         # Mystery data model
│   ├── Prayer.swift          # Individual prayers (Our Father, Hail Mary, etc.)
│   ├── Meditation.swift      # Meditation content
│   ├── JournalEntry.swift    # User journal entries
│   └── UserProgress.swift    # Streaks, stats
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── PrayerViewModel.swift
│   ├── JournalViewModel.swift
│   └── ProgressViewModel.swift
├── Views/
│   ├── Home/
│   ├── Prayer/
│   ├── Journal/
│   ├── Progress/
│   └── Account/
├── Services/
│   ├── APIService.swift      # Fetch mysteries, meditations, audio from web API
│   ├── AudioService.swift    # Audio playback for guided prayers
│   ├── CacheService.swift    # Local caching for offline support
│   ├── StorageService.swift  # Local persistence (settings, progress)
│   └── NotificationService.swift
├── Components/
└── Resources/
    ├── Prayers/              # Prayer text content (JSON/plist)
    ├── Meditations/          # Meditation content per mystery
    └── Audio/                # Audio files for guided prayers
```

## Key Features to Implement

### Phase 1: Core Prayer Flow
- [ ] Data models for mysteries and prayers
- [ ] API service to fetch content from web backend
- [ ] HomeViewModel with dynamic day-based mystery
- [ ] Navigation from Home → Select Meditation → Prayer Flow
- [ ] Prayer screen with mystery display and bead tracking
- [ ] Completion screen

### Phase 2: Persistence & Progress
- [ ] Local caching for offline support
- [ ] Local storage for prayer history
- [ ] Streak tracking
- [ ] Progress statistics
- [ ] Progress tab UI

### Phase 3: Enhanced Experience
- [ ] Audio streaming/playback from API
- [ ] Auto-scrolling scripture text synced with audio (fade in/out, bottom-to-top)
- [ ] Notifications/reminders
- [ ] Account tab and preferences
- [ ] Haptic feedback during prayer

### Phase 4: Journal (After API Support)
- [ ] Journal entries (requires web API update first)
- [ ] Post-prayer reflection prompts
- [ ] Journal history view

### Stretch Goals: Resource Library
- [ ] Rosary how-to guide for beginners
- [ ] Scripture references for each mystery
- [ ] Saint quotes and reflections
- [ ] Marian library (apparitions, devotions, history)
- [ ] Feast day calendar

### Stretch Goals: Schedule & Liturgical
- [ ] User setting to switch between Traditional and Modern (Luminous) schedule
- [ ] Liturgical calendar API integration
- [ ] Dynamic Sunday mystery based on liturgical season
- [ ] Feast day overrides (e.g., Marian feasts suggest specific mysteries)

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
- **Custom fonts (to add):** Cinzel, Cormorant Garamond

### Visual Style
- Dark, contemplative theme
- Gold accents for sacred/important elements
- Rounded cards with subtle borders
- Gradient overlays for depth
- Minimalist, distraction-free UI for prayer focus

## Technical Notes

- **Minimum iOS:** 17.0 (uses `@Observable` macro)
- **Framework:** SwiftUI (no UIKit)
- **State Management:** SwiftUI's `@State`, `@Observable`, `@Environment`
- **Navigation:** Currently basic state-based; should migrate to `NavigationStack`
- **Persistence:** Local caching only; primary data from API

### Data Architecture

**Content comes from external API (web app backend):**
- Mystery data (titles, scriptures, descriptions)
- Meditation text content
- Audio files for guided prayers
- Saint information

**Local storage (on-device):**
- User preferences/settings
- Prayer streak & progress data
- Cached API responses for offline use
- Journal entries (future - when API supports it)

> **Note:** A companion web app exists with the content database. The iOS app will fetch content via API rather than bundling it locally. This allows content updates without app releases.

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

### Expected API Endpoints (coordinate with web app)
```
GET /mysteries                    # List all mystery types
GET /mysteries/:type              # Get mysteries for a type (joyful, sorrowful, etc.)
GET /mysteries/:type/:id          # Get single mystery with meditations
GET /meditations/:mysteryId       # Get available meditations for a mystery
GET /audio/:meditationId          # Stream audio for a meditation
POST /journal (future)            # Save journal entry
```

## Glossary

- **Decade:** One Our Father + 10 Hail Marys + Glory Be (one mystery)
- **Mystery:** A scene from Jesus/Mary's life to meditate on
- **Rosary:** Full prayer = 5 decades (one set of mysteries)
- **Chaplet:** Shorter prayer devotion (like Seven Sorrows)
