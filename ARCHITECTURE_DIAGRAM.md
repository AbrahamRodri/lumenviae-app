# Consecration to Mary - Architecture & Data Flow

## App Navigation Structure

```
┌─────────────────────────────────────────────────────────────┐
│                        ContentView                          │
│  @State var selectedTab: AppTab                             │
│  @State var consecrationViewModel: ConsecrationViewModel    │
└──────────────┬──────────────────────────────────────────────┘
               │
               └─→ .environment(consecrationViewModel)
                   |
                   ├─→ Switch selectedTab
                   │   ├─ .home           → HomeView
                   │   ├─ .consecration   → DailyConsecrationView 👈
                   │   ├─ .journal        → JournalView
                   │   ├─ .progress       → PrayerProgressView
                   │   └─ .account        → AccountView
                   │
                   └─→ CustomTabBar (5 tabs)
                       ├─ Home
                       ├─ Consecration ❤️ (NEW)
                       ├─ Journal
                       ├─ Progress
                       └─ Account
```

## Daily Consecration View Flow

```
┌─────────────────────────────────────────────────────────────┐
│              DailyConsecrationView                          │
│  @Environment(ConsecrationViewModel.self)                   │
└──────────────┬──────────────────────────────────────────────┘
               │
               ├─→ Check: viewModel.isActive ?
               │   
               ├─ NO (Not Started)
               │   └─→ Show: "Begin Your Consecration"
               │       └─→ Button: "Start Now"
               │           └─→ Opens ConsecrationGuideView (sheet)
               │
               └─ YES (Started)
                   └─→ DailyHeaderView
                   │   ├─ Day X of 33
                   │   ├─ X days remaining
                   │   └─ Consecration date
                   │
                   ├─→ ProgressCardView
                   │   ├─ Phase indicator
                   │   └─ Progress bar (gold gradient)
                   │
                   ├─→ Day Focus Card
                   │   ├─ Day number
                   │   ├─ Focus area
                   │   └─ Title
                   │
                   ├─→ Prayers Section
                   │   └─→ For each prayer today:
                   │       ├─ Prayer name
                   │       ├─ Duration (3 min)
                   │       └─ [Expand/Collapse] → Full text
                   │
                   ├─→ Reading Section
                   │   └─ Daily reading assignment
                   │
                   ├─→ Reflection Section
                   │   └─ Personal reflection prompt
                   │
                   └─→ (If Day 33)
                       └─ CompletionCardView
                           ├─ Congratulations message
                           └─ Next steps guidance
```

## View Model - Data & Logic

```
┌─────────────────────────────────────────────────────────────┐
│          ConsecrationViewModel (@Observable)               │
├─────────────────────────────────────────────────────────────┤
│ STORED STATE:                                               │
│   var isActive: Bool                                        │
│   var selectedFeastDay: MarianFeastDay                     │
│   var startDate: Date                                       │
│   var consecrationDate: Date?                              │
│                                                             │
│ COMPUTED (Auto-Updated):                                    │
│   var daysCompleted: Int {                                  │
│     return Days from startDate to today                     │
│   }                                                          │
│   var daysRemaining: Int { 33 - daysCompleted }            │
│   var progressPercentage: Double {                          │
│     return Double(daysCompleted) / 33.0                    │
│   }                                                          │
│   var currentPhase: Int {                                   │
│     if daysCompleted <= 12 { return 1 }                    │
│     if daysCompleted <= 19 { return 2 }                    │
│     if daysCompleted <= 26 { return 3 }                    │
│     return 4                                                │
│   }                                                          │
│   var currentConsecrationDay: ConsecrationDay? {           │
│     return sampleConsecrationGuide                         │
│       .phases                                               │
│       .flatMap { $0.days }                                 │
│       .first { $0.dayNumber == daysCompleted }            │
│   }                                                          │
│                                                             │
│ METHODS:                                                    │
│   func startConsecration(...)                              │
│   func resetConsecration()                                 │
│   func saveConsecrationData()                              │
│   func loadConsecrationData()                              │
│   func getPhase(for:) -> ConsecrationPhase?               │
└─────────────────────────────────────────────────────────────┘
```

## Data Persistence Flow

```
┌─────────────────────────────────────────────────────────────┐
│         Consecration Data Persistence                       │
└──────────────┬──────────────────────────────────────────────┘
               │
    START: User taps "Begin Now"
               │
               ├─→ ConsecrationStartView calls:
               │   viewModel.startConsecration(
               │     feastDay: .annunciation,
               │     startDate: Date()
               │   )
               │
               ├─→ ViewModel updates @Observable state
               │   ├─ isActive = true
               │   ├─ selectedFeastDay = .annunciation
               │   ├─ startDate = 2026-02-20
               │   ├─ consecrationDate = 2026-04-24
               │   └─ (computed properties auto-update)
               │
               ├─→ saveConsecrationData() called
               │   ├─ UserDefaults.set(true, "consecration_active")
               │   ├─ UserDefaults.set(Date(), "consecration_start")
               │   └─ UserDefaults.set("Annunciation", "consecration_feast")
               │
               ├─→ DailyConsecrationView @Environment updates
               │   └─ All observers refresh automatically
               │
               └─→ Show Day 1 prayers
                   │
                   │
    RESUME: App restarts
               │
               ├─→ DailyConsecrationView.onAppear
               │   └─→ viewModel.loadConsecrationData()
               │       │
               │       ├─ Read UserDefaults keys
               │       ├─ Restore isActive, startDate, selectedFeastDay
               │       ├─ Recalculate consecrationDate
               │       └─ Trigger computed property updates
               │
               └─→ Show same day's prayers
                   (State completely restored)
```

## Guide Start Flow

```
ConsecrationGuideView
    │
    ├─→ Feast Day Card
    │   └─→ Tap → FeastDaySelectionSheet (Modal)
    │       └─→ Choose from 5 feasts
    │           └─→ Selection saved to @State
    │               └─→ Back to guide (updates card)
    │
    ├─→ Phase Cards (Expandable)
    │   └─→ Tap → Expand
    │       └─→ See description
    │           └─→ "View Daily Prayers" link
    │               └─→ PhaseDetailView (NavigationLink)
    │                   └─→ See all 7-12 days
    │                       └─→ Expand each day
    │                           └─→ See prayers, reading, reflection
    │                               └─→ Back
    │
    ├─→ Post-Consecration Practices
    │   └─→ Display 4 practice cards
    │
    └─→ "Begin the 33-Day Journey" Button
        └─→ ConsecrationStartView (Modal)
            │
            ├─ Show selected feast + date
            ├─ Date picker for start date
            ├─ Timeline info
            ├─ Phase overview
            ├─ Reminders
            │
            └─→ "Begin Now" Button
                └─→ Calls: viewModel.startConsecration()
                    └─→ Saves state
                        └─→ Sheet dismisses
                            └─→ Back to daily view
                                └─→ Now shows Day 1!
```

## Daily Prayer Display Logic

```
┌──────────────────────────────┐
│  Today's Date = March 5      │
│  Start Date = March 1        │
└──────────────┬───────────────┘
               │
               ├─→ Calculate daysElapsed
               │   └─ Mar 5 - Mar 1 = 4 days
               │
               ├─→ Current day
               │   └─ 4 + 1 = Day 5
               │
               ├─→ Fetch from sample data
               │   └─ sampleConsecrationGuide
               │       .phases
               │       .flatMap { $0.days }
               │       .first { $0.dayNumber == 5 }
               │
               ├─→ Display Day 5 content:
               │   │
               │   ├─ Header: "Day 5 of 33"
               │   ├─ Remaining: "28 days"
               │   ├─ Progress: "15%"
               │   ├─ Phase: "1 - Emptying"
               │   │
               │   ├─ Focus: "Rejection of Satan"
               │   ├─ Title: "The Annunciation"
               │   │
               │   ├─ Prayers[0]: "Veni Creator"
               │   │   └─ Text: (3 minutes)
               │   ├─ Prayers[1]: "Ave Maris Stella"
               │   │   └─ Text: (3 minutes)
               │   │
               │   ├─ Reading: "Read from True Devotion..."
               │   └─ Reflection: "Reflect on how..."
               │
               └─→ Tomorrow: Auto shows Day 6 (no app change needed!)
                   (Because calculations are based on current device date)
```

## State Diagram

```
                    ┌─────────────────────┐
                    │  Not Initialized    │
                    │  isActive = false   │
                    │  startDate = nil    │
                    └──────────┬──────────┘
                               │
                    (User taps "Start Now")
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Active Journey     │
                    │  isActive = true    │
                    │  startDate = Feb 20 │
                    │  selectedFeast = A  │
                    │  consecDate = Apr 2 │
                    └──────────┬──────────┘
                               │
                (App continues to track current date)
                               │
                    (Each day computed properties
                     automatically update based on
                     system date vs startDate)
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Day 1-32: Journey   │
                    │ Shows daily prayers │
                    │ Progress updated    │
                    └──────────┬──────────┘
                               │
                    (After 33 days pass)
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Day 33: Complete!   │
                    │ isComplete = true   │
                    │ Shows completion    │
                    │ card & next steps   │
                    └────────────────────┘
```

## Component Hierarchy

```
ContentView
├── ConsecrationViewModel (injected)
├── CustomTabBar
│   └── 5 TabBarItems
│       └── On tap: selectedTab = .consecration
│
├── DailyConsecrationView (when selectedTab == .consecration)
│   ├── if not isActive
│   │   └── "Begin" button → (sheet)
│   │       └── ConsecrationGuideView
│   │           ├── ConsecrationHeaderView
│   │           ├── FeastDaySelectionCard
│   │           │   └── .sheet(FeastDaySelectionSheet)
│   │           ├── OverviewCard
│   │           ├── PhaseCards (expandable)
│   │           │   └── NavigationLink → PhaseDetailView
│   │           │       └── DayCards (expandable)
│   │           │           └── PrayerItemViews
│   │           ├── PostConsecrationSection
│   │           └── "Begin the 33-Day Journey" button
│   │               └── .sheet(ConsecrationStartView)
│   │                   └── Calls viewModel.startConsecration()
│   │
│   └── if isActive
│       ├── DailyHeaderView
│       │   ├── Day counter
│       │   ├── Days remaining
│       │   └── Consecration date
│       ├── ProgressCardView
│       │   └── Progress bar + percentage
│       ├── Day Focus Card
│       ├── Prayers Section
│       │   └── DailyPrayerCards (expandable)
│       ├── Reading Section
│       ├── Reflection Section
│       └── (if complete) CompletionCardView
```

## File Dependencies

```
Models/
└── Consecration.swift
    ├── Exported: MarianFeastDay (enum)
    ├── Exported: ConsecrationGuide (struct)
    ├── Exported: ConsecrationPhase (struct)
    ├── Exported: ConsecrationDay (struct)
    ├── Exported: ConsecrationPrayer (struct)
    └── Exported: sampleConsecrationGuide (instance)

ViewModels/
└── ConsecrationViewModel.swift
    ├── Imports: Consecration
    ├── Exports: ConsecrationViewModel (class)
    └── Uses: UserDefaults, Calendar, Date

Views/
├── DailyConsecrationView.swift
│   ├── Imports: ConsecrationViewModel
│   ├── Imports: Devotion views
│   └── Exports: DailyConsecrationView (view)
│
└── Devotion/
    ├── ConsecrationGuideView.swift
    │   ├── Imports: Consecration
    │   ├── Imports: ConsecrationViewModel
    │   └── Exports: ConsecrationGuideView
    │
    ├── FeastDaySelectionSheet.swift
    │   ├── Imports: Consecration
    │   └── Exports: FeastDaySelectionSheet
    │
    ├── PhaseDetailView.swift
    │   ├── Imports: Consecration
    │   └── Exports: PhaseDetailView
    │
    └── ConsecrationStartView.swift
        ├── Imports: Consecration
        ├── Imports: ConsecrationViewModel
        └── Exports: ConsecrationStartView

Components/
└── CustomTabBar.swift
    ├── Exports: AppTab (enum with .consecration case)
    └── Exports: CustomTabBar

Root/
└── ContentView.swift
    ├── Imports: ConsecrationViewModel
    ├── Imports: All views
    └── Routing: selectedTab == .consecration → DailyConsecrationView
```

## Summary

The architecture is clean and modular:

1. **State Management**: ConsecrationViewModel (@Observable)
   - Centralized, reactive, persisted

2. **Views**: Separated by concern
   - Guide views (browsing)
   - Daily views (tracking)
   - Component views (reusable)

3. **Data**: Immutable structures
   - Models (Consecration.swift)
   - Sample data embedded
   - Easy to replace with API

4. **Navigation**: Tab-based + sheets/links
   - Consecration tab accessible from anywhere
   - Guide flow inside modal sheets
   - Clean navigation stack

5. **Persistence**: UserDefaults
   - Simple, reliable
   - Automatic on state change
   - Restored on app launch

This creates a complete, functional feature that "just works" from the user's perspective!
