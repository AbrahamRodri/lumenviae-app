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
    └── Sacred Mysteries Grid (Joyful, Sorrowful, Glorious, Seven Sorrows;
        its VIEW ALL page adds Luminous)
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
    ├── Header: Back · pin
    ├── Labels kicker, ornament, name in Cinzel, painting in a lancet arch
    ├── A ruled ledger of sections, each named in the left margin:
    │   About this set · The meditations (numbered) · From (author, source)
    ├── The first meditation in full, behind a quiet disclosure
    ├── HOW YOU'LL PRAY — one quiet ruled line naming what is set
    │   (voice · speed · aloud · beads), opening the choices in a sheet
    └── "PRAY" (the screen's one gold act) — nothing set beneath it,
        and never an estimated duration
        │
        ▼
Prayer Flow (5 Mysteries/Decades)
    │
    ├── 1st Mystery → 2nd Mystery → 3rd Mystery → 4th Mystery → 5th Mystery
    │   (Each mystery: Meditation + 10 Hail Marys + Glory Be; the Seven
    │   Sorrows chaplet is seven sorrows of seven Hail Marys each)
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

> **Note:** This is the traditional pre-2002 schedule. The Luminous Mysteries (added by Pope John Paul II) are available in the app but not part of the default daily rotation. Users can always choose Luminous from the grid's VIEW ALL page or from Explore.
>
> `ScheduleService` computes the seasons on device (Easter by Meeus/Jones/Butcher; Lent = Ash Wednesday up to Easter; Advent = the Sunday on or after Nov 27 through Dec 24) and is kept **identical to the server's `LumenViae.LiturgicalCalendar`** — Christmastide and Eastertide deliberately count as "ordinary" for this rule on both sides. Change the two together, along with the site copy (the web app's home, dashboard and category pages) and the day names the app shows (`MysteryCategory.daysPrayed`, `MysteryData`'s per-mystery `daysPrayed`). The server's `mysteries.days_prayed` column is not read by the app, and as of Sept 2026 it (and `priv/repo/seeds.exs`) still carries older, non-traditional days — fix it there before anything shows it.

### The Mysteries of Each Set

These are the app's own names (`Data/MysteryData.swift`). The server's
`mysteries.name` words five of them differently — The Coronation of Mary,
The Baptism of Jesus, and the fourth to seventh Sorrows (Mary Meets Jesus
on the Way to Calvary · Jesus Dies on the Cross · Mary Receives the Dead
Body of Jesus in Her Arms · Jesus is Placed in the Tomb) — and a CSV import
must match the **server's** names exactly.

**Joyful Mysteries:**
1. The Annunciation
2. The Visitation
3. The Nativity
4. The Presentation
5. The Finding in the Temple

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
4. The Assumption
5. The Coronation

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

### Kinds of Meditation

There is no "type" field and no default kind. A meditation set is a
server-authored set of five (seven for the Sorrows) carrying `labels`
from the web app's vocabulary (`LumenViae.Rosary.Labels`): Considerations
(shown as **Reflections**), Contemplative, Saints, Scriptural, Intentions —
see Content Requirements below. As of Sept 2026 the Saints sets are
Liguori, Ignatius, Chrysostom, Newman, Augustine and Aquinas, beside
Sheen, Emmerich, Agreda, Faber, Guéranger and the Servants of Mary; **no
set carries Intentions yet** — vocation sets ("As a Father", "In Times of
Suffering") are a content goal, not something to build UI for. The quick
act's "today's Rosary" picks one of the day's sets at random.

The **Scriptural Rosary** — a verse for every Hail Mary — is not a kind of
meditation but a devotion of its own, with its own title page and prayer
screen (see the Built list below). The meditation's player prays on the
same strand, without the verses.

## App Tabs

`AppTab` (in `Components/CustomTabBar.swift`) has five cases, but the bar shows
four — Progress is reached from the Chapel's flame tile, Settings → Devotion
and Explore's search instead, to keep the bar from crowding the raised Pray
button.

| Tab | In the bar | Purpose |
|-----|-----------|---------|
| Home | Yes | Search glass → Explore, today's mysteries, mystery grid, Today's Prayer, the reading shelf, quote |
| Consecrate | Yes | The 33-day preparation for Marian consecration |
| Journal | Yes | Reflections, searchable, stored on device |
| Progress | No — via Chapel | Streaks, prayer history, milestones ("Prayer Record") |
| Chapel | Yes | My Chapel — the user's arrangeable page (Settings and About live in the home masthead) |

The **Pray** button raised over the bar runs the user's chosen quick act
(today's Rosary by default), and **press-and-hold** opens a tray of their
chosen devotions (`PrayShortcutTray`).

The home header is the wordmark framed by the app's chrome:
**ph-faders → Settings** and **ph-info → About** together on the left,
the search glass alone on the right. No flame — the streak lives in the Chapel's own Prayer Streak
tile, which opens the Prayer Record (its foot act says so; Settings →
Devotion is the other standing door to the Progress page, and Explore's
search finds it as "Prayer Record"). The masthead is the **only** door
to Settings and About — not the Chapel's day strip, which reads the
liturgical day alone, and not the Chapel's foot, which is the arrange
control and the imprint, nothing else.

**Today's Prayer** (`Components/TodaysPrayerSection.swift`) stands
between the Sacred Mysteries grid and the reading shelf: a section heading in the home page's own voice ("Today's Prayer" in
Cinzel 19, the date where the other sections keep their link), the Total Consecration first, under the section's name, then the feast as a subsection
of it — its name in small engraved capitals with a hairline beside it
running to the edge, the way a card names one of its parts — heading the Mass and
the Office. Set large in the reading italic, the feast read as a second
section title. The preparation
is the user's own devotion, kept whatever day it is, and no part of the
Church's calendar, so it stands apart from the feast and above it. Three ruled rows on the bare page — no card,
no panel, no fill. The Mass, the Divine Office,
and the Total Consecration, given equal standing. It is named for the
user's prayer and **not** "Today in the Church", because the
consecration is a private devotion and not a liturgical observance;
`TodayInChurch` (the observable) still supplies the day and is shared
with the Chapel's day strip. Every row has the same parts — the door's
own glyph (`ch-altar`, `ph-clock`, `ch-consecration`, the same as on
every other surface), name, the row's own live fact, chevron — so the
eye reads down the column of facts: the day's class and colour in words beside its silk, a 4×24 bar
("II CLASS · RED", which once stood under the feast as a caption to
the whole section), the
hour it is as a lit dot and its name (TERCE), the day of the
preparation over a 46pt hair. There is no line under the names: a plain
sentence under each once said what the row was, and the section took
longer to read for it. The consecration row, before any consecration is
begun, keeps its place, its icon and its weight and offers BEGIN — **no state
in this section may shame the user**: no "0 days", no "missed", no
empty track. True Devotion is reached from Explore and the Chapel's
Library tile, not from here.

The search glass pushes `AppRoute.explore`
(`Views/Home/ExploreView.swift`): at rest it browses — an epigraph
(Mt 7:7), the five devotions as a ruled ledger with the Scriptural
Rosary's door beneath them and a quiet "New to the Rosary? · How to
Pray" door under that (How to Pray was the fourth item of The Study at
the foot of the page, where a newcomer never reached it); then The
Liturgy (Missal | Office), the Spiritual Reading shelf, and The Study's
ruled index — and typing searches mysteries, library doors, library readings and
meditation sets at once. The set index is fetched quietly for search but deliberately
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
surface hides it. Also drawing their own chrome (bar hidden, Back on
the page): the meditation shelf and a set's title page, the Scriptural
Rosary's title page, the Guided Rosary, and the prayer and completion
screens. A page may hide the bar only if it draws its own Back in every
branch. Not every push is an `AppRoute`: True Devotion's chapters are
closure `NavigationLink`s and the Office's hours a
`navigationDestination(item:)`.

A page that hides the system bar hides the back-swipe with it, so it
owes a way out from **every** branch it can draw, not just the loaded
one. A spinner or an "unavailable" message with no Back is a screen
only a force-quit leaves; both readers had one, and both now carry the
capsule in those branches too. Sheets are for tasks, trays and short
asides — the Pray tray, the editors, pickers, the journal editor, How
you'll pray, the calendars, reading options, the chant sheet, and
About's three short texts; a destination with onward doors of its own
is pushed.
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
movement) — on the page, on a tile that opens on a tap, or on the
quiet parts of a tile full of doors — the coach ribbon's "Show me" (one-time,
`userSettings.chapelCoached`), or the foot's "Arrange this page" all
enter arrange mode: tiles sway ±0.5°, gain a ✕ badge at the corner of their shell, the tab
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
order; a tile newer than a stored layout is inserted in its default
place, not appended): **Today** (the rule as a ledger, and the picker
itself — the focus block above it carried a "CHOOSE ANOTHER" jump down
to this tile and no longer does, since the ledger is a scroll away on
the same page; it opens on one italic line saying what a rule is, and
every row shows at its trailing edge what a tap does — OFFERED with the
seal, BEGIN › / CONTINUE › until then, every act on the rule being one the
app watches finish (the row marked by hand went out with the acts that
needed it); the Rosary, the Scriptural Rosary, the
chaplet and the consecration day check from real data, reset each
morning; the half is a figure "2 / 4" over a row
of tappable cells), **Consecration** (de Montfort's four preparations
as a segmented road, tracks weighted 12/7/7/7 days, the day's own
title as the foot note), **Reading** (the open book with the author
over the title, the other books under way standing as spines beside
it — tap a spine, or swipe the face, to bring that book forward; the
tile is not one door, because made one, every spine opened the book in
front of it and the rest could not be reached; the half's cover carries its ribbon and diamond; empty,
the shelf's cloths and "Tolle, lege"), **Liturgy** (the Missal
and the Breviary as a diptych, each leaf a door, over the day's feast;
split out of the Library so one heading is true of everything beneath
it; a layout saved before it existed seats it beside the Library, at
the Library's width, and on the page only if the Library is —
`ChapelPlacement.completing`, which the Me migration shares), **Library** (six doors in two columns — True Devotion, Spiritual
Reading, the Marian Library | How to Pray, In Scripture, Carlo Acutis —
over Augustine's line and THE SHELF; the half keeps the first two and
makes FOUR MORE a door to Explore), **Chant** (the app's three chant
recordings — Veni Creator, Ave Maris Stella, Magnificat — through the
shared AudioService; the elapsed time rides the kicker at full width
and the transport row at half, said once either way; ALL CHANTS opens
the chant sheet), **Reflections** (latest journal entry under an
illuminated versal, or its gilded opening mark when it opens on a
quotation (`VersalCut.opensOnQuotation`: a lone apostrophe, 'Tis, is
no quotation), or beside a rule of gold fading down when it opens on
no letter; a passage kept from a book is quoted without its citation,
and any other entry is the journal's `previewText`, newlines flattened), **Prayer Streak** (the
flame; stands directly under Today, because a record of days prayed
belongs beside the day it records and onboarding's closing line promises
it is being kept; the kicker says "Lit today" or "Not yet today", never
"missed"; the streak's figure is captioned "In a row" and the week is
drawn beneath it as a small Sunday-to-Saturday calendar, each day's
initial over its bead and today ringed — "This week" under the figure
with bare dots beside it read as one confused count; the whole tile
opens the Prayer Record).

**One anatomy for every tile, at both spans** (the "Chapel Tiles"
handoff, `ChapelTileFrame` in `Views/Chapel/ChapelTiles.swift`): a
kicker on the page above the shell — 12pt glyph, Cinzel 10 tracked 2.5
at `gold@0.75`, a trailing italic note at 12 — the same sizes at both
spans so a pair of halves shares one title line (a half's label
truncates before its note does, and the flame's reads STREAK there);
one 16pt hairline shell at `gold@0.24`, no fill, no shadow, 14/16/6
padding at full and 12/14/4 at half (list-style bodies sit closer to
the top edge); the tile's body; and a foot pinned to the shell's floor
by a Spacer — full: italic note left, gold text act right (`labelFont
10`, tracking 2, caret 9, 44pt tall); half: the act alone, left-aligned,
drawn 32 tall and answering to 44. The grid's rows **stretch**
(`ChapelGridLayout` gives every tile in a row the row's height, and the
shell fills it), so two halves always end on the same line; the row gap
is 28, the column gap 16. Halves are left-aligned, never centred, and
lead with one figure — Cinzel 26 with the denominator at 15 in
`cream@0.45` ("12 days", "Day 14 / 33", "2 / 4") — or a headline at
14–15, then one italic line. Kicker, shell and foot are one door
(`onTap` — a tap and a hold as two gestures rather than a Button, so a
hold that arranges the page never also opens the tile on release)
except where the body has doors of its own — the Today rows
and cells, the Reading tile's face and spines, the Liturgy leaves, the
Library doors, the chant's play disc — where only the foot's act is a
control (`onAct`). The Today tile has no foot act at all; its EDIT rides
the kicker (`onEdit`), since a foot act there read as one more BEGIN
row. The ✕ badge hangs
at the shell's corner, below the kicker. The page once drew three
registers (ruled, outlined at 16, outlined at 20) with kickers on some
tiles and not others and centred halves beside left-aligned ones, and
the tiles fought; none of that may come back. No filled card surfaces
on the page — `AppColors.cardBackground` only in the tray, the chant
sheet, and the chant tile's play disc. The
default order is Today, Streak, Consecration, Reading, Chant,
Reflections, Liturgy, Library: the live sections lead, and the two
indexes of doors stand last, the Library's colophon the right last line
before the foot's imprint. The day strip wraps a long feast to a second
line rather than cutting it mid-word.

**The rule's vocabulary** (`PrayerShortcut.isRuleEligible`): the
Rosary, the Scriptural Rosary and Seven Sorrows can be chosen. "A
Meditation" was briefly eligible, marked by hand, and is not: browsing
the picker is a doorway to the Rosary, not a devotion beside it. **The Mass and the Office are
off the rule** until the app can keep a day's schedule for them — a
rule may only carry what the Chapel can ask about honestly; a stored
rule that names them keeps them on disk and passes over them on read.
**The Consecration is not chosen but never absent**: while a
preparation is under way `MyChapelView.resolvedActs` inserts it second,
under the rule's first act (the Rosary by default), and it leaves when the preparation is done. Two of
the handoff's recommendations are deliberately not built: hiding the
Consecration tile while the act is on the rule would mean its road was
never seen, and merging Liturgy into Library at half width is a
different page from the one drawn.

The rule's *membership* is edited in `RuleEditorSheet` (Settings →
Devotion → Rule of Prayer, and the EDIT on the Today tile's title line);
`PrayButtonEditorSheet` (quick tap + hold menu) still opens from the
Pray tray's "Edit this menu" row. The one-motion acts remain
`PrayerShortcut`. Prayer Record's standing doors are the flame tile and
Settings → Devotion (Explore's search also finds it). The old Me page
(`Views/Me/MeView.swift`, `MeWidgets.swift`, `MePageEditorSheet`) and
`Components/MenuView.swift` are unreachable — called only from their own
previews — but they still **compile and ship** (about 1,400 lines) and
keep Me-only API alive (`isRuleChecked`/`setRuleChecked`). They are not a
source of truth: a grep that lands in them (a `navigateToSettings()`, a
Prayer Record door) describes nothing a user can reach. The real
reference is git (`ed21006^`); research behind the original design: "The
Oratory Brief" artifact.

### Settings & About Screens

Split in two, each behind its own glyph in the home masthead, so the
informational pages are never the settings page's attic:

**`AccountView`** (`AppRoute.settings`, the home masthead's **ph-faders**) — the
app-wide toggles and choices (the readers keep their own — the Missal's
and the Office's Aa sheets, the reading goal on a book's page), set in
the Chapel's own voice: a Cinzel plate
("Settings / How your chapel is kept."), then outlined sections with
glyph-led kickers (`AccountSection` — no filled card surfaces, same as
the page they serve):

- **Appearance** — theme (re-themes live). An **App Icon** section (the
  primary + three alternates) is built but switched off
  (`AppIconPickerRows.isEnabled = false`), and `appApp` puts any
  alternate back to the primary at launch until it returns.
- **Prayer Experience** — text size, prayer language (English by
  default; the app's first face is the one most users read), the
  narration voice (`NarrationVoiceRow`, the server's list; the same
  choice stands in the player's playback sheet), Bead counter (the
  meditation player's strand; see the Core prayer flow), Pray aloud
  (the spoken Rosary), and the prayers after the Rosary (Holy Father,
  Memorare, St Michael)
- **Devotion** — Rule of Prayer (→ `RuleEditorSheet`), Prayer Record,
  Daily Reminders (toggle, time, sound), What Brings You to the Rosary (decides
  the reminder copy pool)
- **Offline** — download every meditation set and audio file

**`AboutView`** (`AppRoute.about`, the home masthead's **ph-info**) — the app's
colophon: the wordmark as masthead, then About Lumen Viae, Privacy
Policy, Help & Support, Send Feedback, and the footer (version, "Ad
Majorem Dei Gloriam"). **App Introduction** — which re-runs onboarding —
stands above Privacy Policy behind `#if DEBUG`: it is for development,
since a reader has seen the introduction and needs no door back to it.
It runs in a **`fullScreenCover`**, never a sheet; onboarding is the
app's first face, and a sheet's inset top, rounded rim and drag-away
made the re-run a panel over the settings instead of the screen a new
reader meets. The sheets
it presents still live in AccountView.swift alongside the shared row
components (`ActionRow`, `ToggleRow`, `AccountFooter`…).

## Architecture

```
app/
├── appApp.swift              # @main entry
├── ContentView.swift         # Tab switch + the app's NavigationStack
├── Constants.swift           # Strings, Color(hex:)
├── Navigation/
│   └── AppRouter.swift       # AppRoute, the navigation path, chapelArranging
│                             # (AppTab lives in Components/CustomTabBar)
├── Models/                   # API models, SwiftData models, enums
│   ├── Mystery, Meditation, MeditationSet, MysteryCategory, APIResponse
│   ├── JournalEntry, PrayerSession                       (SwiftData)
│   ├── ChapelTile            # + ChapelPlacement — the Chapel page's vocabulary
│   ├── RosaryStrand          # + BeadPosition — the whole Rosary as one string
│   ├── SpokenRosary, RosaryAudioManifest, NarrationVoice  # the Rosary said aloud
│   ├── GuidedRosary          # RosaryPart, RosaryMap, the 75-step first Rosary
│   ├── LibraryReading        # ReadingShelf, KeptFeast — short readings
│   ├── MissalProper, OfficeModels
│   ├── Consecration{Day,Phase,Prayer,Reading}
│   ├── ConsecrationProgress                               (SwiftData)
│   ├── TrueDevotionBook
│   ├── TrueDevotionReadingProgress                        (SwiftData)
│   ├── LibraryBook           # + catalog entry, parsing rules, LibriVox models
│   ├── BookReadingProgress                                (SwiftData)
│   ├── PrayerShortcut                       # + MeWidget — personalization vocab
│   └── StreakMilestone, MarianFeastDay, BilingualConsecrationPrayer
├── ViewModels/               # @Observable
│   ├── HomeViewModel, MeditationSelectionViewModel, MeditationSetDetailViewModel
│   ├── PrayerSessionViewModel, ScripturalRosaryViewModel, ConsecrationViewModel
│   ├── MissalViewModel, OfficeViewModel
│   └── TrueDevotionReaderViewModel
├── Views/
│   ├── Home/ Prayer/ Journal/ Progress/ Account/
│   ├── Scriptural/           # ScripturalRosaryView (the title page),
│   │                         # ScripturalRosaryPrayerView (the prayer)
│   ├── Chapel/               # MyChapelView (the tab), ChapelGrid (arrange
│   │                         # machinery), ChapelTiles, ChapelChant
│   ├── Me/                   # Legacy, unreachable but still compiled: MeView,
│   │                         # MeWidgets. Still live: MeCustomizeSheet's
│   │                         # RuleEditorSheet + editor furniture,
│   │                         # PrayButtonEditorSheet, PrayShortcutTray
│   ├── Meditation/           # SelectMeditationView (the shelf), MeditationSetDetailView,
│   │                         # RosarySetupCard (HOW YOU'LL PRAY)
│   ├── Consecration/         # 33-day preparation (own NavigationStack)
│   ├── TrueDevotionView      # True Devotion's title page (at the Views/ root)
│   ├── TrueDevotion/         # Its contents page and chapter reader
│   ├── Library/              # Spiritual Reading shelf, book page, chapter
│   │                         # reader, contents sheet, transport
│   ├── Resources/            # How to Pray (+ RosaryLessonView, GuidedRosaryView),
│   │                         # Marian Library, In Scripture, Carlo Acutis,
│   │                         # LibraryReadingView, the Missal and the Office
│   │                         # (+ LiturgicalMonthGrid, the month grid both
│   │                         # calendars draw)
│   ├── Onboarding/           # 8-slide first run + RosaryMethodsView
│   └── Launch/
├── Components/               # CustomTabBar, HeaderView, MysteryCard, QuoteSection,
│                             # MeditationSetTile (+Row), StreakWidget,
│                             # TodaysPrayerSection + TodayInChurch, SetArtworkView,
│                             # BookCover, QuotedPassageText, PrayerPainting(Stage)
│                             # (the player's ground), RosaryStrandView,
│                             # BeadStatusRow (the reader's), RosaryDiagram,
│                             # PendantCrossView, OrdoMasthead;
│                             # MenuView is legacy, unreachable
├── DesignSystem/             # Theme, Typography, AppIcon, Motion,
│                             # CallToAction (GoldCTAButton, QuietGoldButton,
│                             # PrayFootScrim), SheetChrome, FocalFill,
│                             # SacredComponents (OrnamentDivider, DropCapText…),
│                             # ReadingText (ReadingTypography, ReadingText, PrayerText)
├── Data/                     # Bundled content, not code-adjacent constants
│   ├── ConsecrationData, BilingualConsecrationPrayers, BilingualPrayer
│   ├── MysteryData, LuminousMeditationData, TrueDevotionData/Prayers
│   ├── ScripturalRosaryData  # GENERATED by Tools/ScripturalRosary — 249 Douay verses
│   ├── LibraryCatalog        # Spiritual Reading shelf: sources + cutting rules
│   ├── MissalOrderData       # The Mass's sections: names, postures, tiers, day rules
│   ├── ReminderMessages      # Notification copy pools
│   ├── RosaryQuotes          # Daily quotation catalog
│   ├── RosaryPrayers         # The Rosary's prayers + DevotionPrayers lookup
│   └── MarianLibraryData, CarloAcutisData, HowToPrayData,
│       MysteriesInScriptureData   # The resource pages' content
├── Services/
│   ├── APIService            # HTTP client (https://lumenviae.fly.dev/api)
│   ├── AudioService          # Narration and chant playback
│   ├── SpokenRosaryPlayer    # The whole Rosary said aloud, above AudioService
│   ├── RosaryAudioPack       # The spoken Rosary's recordings, fetched and kept
│   ├── OfflineContentService # Full offline download of text + audio
│   ├── NarrationVoiceCatalog # The server's voices, kept in UserDefaults
│   ├── MeditationCacheService, ImageCacheService, ArtworkCache
│   ├── MissalAPIService, MissalCacheService   # Missale Meum, cached on disk
│   ├── OfficeAPIService, OfficeCacheService   # Our /office API, cached on disk
│   ├── CanonicalClock        # Which canonical hour it is now
│   ├── PrayerHistoryService, PrayerResumeService, ScheduleService
│   ├── FavoritesService, MeditationSetResolver, TrueDevotionLibrary
│   ├── LibraryService        # Gutenberg text + LibriVox tracks, disk cache
│   ├── LibraryBookParser     # Cuts a Gutenberg edition into chapters
│   ├── LibraryTrackMap       # Ties LibriVox tracks to parsed chapters
│   ├── LibraryListeningSession # The shelf's one voice, above the views
│   ├── LibraryProgressStore  # Every read/write of a reading place
│   ├── LibraryAudioDownloads # Per-track offline recordings
│   ├── ReadingDayMeter       # The day's reading measure (TODAY'S GOAL)
│   ├── UserSettings          # Preferences + daily reminder scheduling
│   └── MockDataService       # Preview/fallback fixtures only
└── Resources/                # Fonts, TrueDevotionBook.json (GENERATED by
                              # Tools/TrueDevotion), the four reminder sounds
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
  Use `@concurrent` when work genuinely must run off it (the offline
  download, the library's parse and audio downloads, the rosary pack and
  the artwork cache all do).
- SwiftUI may read a `Layout`, a `LayoutValueKey`, or an animatable
  value off the main actor, so those types are marked `nonisolated`
  (`ChapelGridLayout`, `ChapelSpanKey`, onboarding's `WordsExtent`);
  under default MainActor isolation a new one needs the same, and the
  Swift 5 mode below won't insist on it.
- The target is still in the **Swift 5 language mode** (`SWIFT_VERSION =
  5.0`, no `SWIFT_STRICT_CONCURRENCY`), so most data races are not
  diagnosed; don't read a clean build as proof of safety.

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
  the ten Hail Marys (seven in a sorrow of the chaplet) are prayed with only the count beside you — beside
  the bead itself. The strand names the bead under the hand in its own
  margin at the window's middle (`RosaryStrandView.activeLabel`: OUR
  FATHER · HAIL MARY / 4 OF 10 · GLORY BE & / FATIMA PRAYER, the count
  rolling as one fixed view while the rows slide beneath it), and the
  Our Father beads carry only their numeral — the words "OUR FATHER"
  beside every one of them ran a hundred points into whatever stood to
  the strand's left. The player's foot — title, transport, utility row —
  changes nothing from bead to bead: a `BeadStatusRow` once stood there
  above the transport and re-wrapped its cue on every swipe, shoving the
  controls, and now the row is the reader's alone, which has no strand.
  **The beads unlock once the meditation has been heard.** The strand
  always hangs at the edge, but on a mystery's Our Father it is greyed,
  still and locked — a small drawn lock on the bead under the hand, and
  OPENS AFTER / THE MEDITATION in place of the bead's name
  (`RosaryStrandView.locked`) — until the narration plays to its end
  (`PrayerSessionViewModel.beadsUnlocked`, fed by AudioService's
  end-of-track callback, which in the prayer flow only ever notes this
  and never moves the Rosary on). Locked, a swipe only tugs the string
  and lets it back, and the rotor's bead actions do nothing; unlocking
  colours it where it hangs, with the decade ripple and a light tick. It
  unlocks at once where there is nothing to wait for — a meditation with
  no narration, narration that would not load, or a Rosary said aloud,
  whose voice moves the beads itself — and stays unlocked
  for the mystery once the hand has moved past the Our Father. The
  reader's bead row is never locked: reading the meditation is the other
  way of praying it. An earlier cut hid the strand until the meditation
  was heard, and switching the counter on mid-meditation then seemed to
  do nothing. The setting has one name and one explanation wherever it
  is offered — Settings, the playback sheet, the set's title page —
  `UserSettings.beadCounterTitle` ("Bead counter") and
  `beadCounterDetail(isOn:)`; it had three names and none said what would
  appear. `ToggleRow` answers a tap anywhere on the row, not only on its
  switch. The one-time `PrayerSwipeHint` ("Swipe down for the next
  bead") waits for the beads to unlock, floating over the painting above
  the controls so its coming and going moves nothing. The Glory Be has no bead of its own: it is drawn
  on the next decade's Our Father bead, and after the last decade on one
  final bead labelled AMEN, where the AMEN button hangs under the bead's
  name beside the strand (`rosaryStrand(onAmen:)`) — the one thing at
  the strand that takes a touch; the strand itself never does. A swipe
  never finishes a Rosary. A decade closes on the Glory Be and the
  Fatima Prayer together, as Our Lady asked, so the closing bead is
  named for both — except in the Seven Sorrows chaplet, whose sorrows
  close on the Glory Be alone (`RosaryStrand.saysFatimaPrayer`), and
  its bead says so. The strand's window keeps `trailingRoom` past the bead
  column for the ring's halo and the decade ripple, which the window's
  edge once cut in half. The arithmetic — decade length, a bead's linear
  index, labels, numerals — is `Models/RosaryStrand.swift`, used by both
  view models; `BeadPosition` (mystery + bead) is what the one haptic
  keys on, so a step across a decade's end ticks once.

  **The beads are optional on the meditation's player**
  (`userSettings.prayOnBeads`, on by default; Settings → Prayer
  Experience → "Bead counter", the player's playback sheet (the faders) so it
  can be changed mid-Rosary, and the set title page's HOW YOU'LL PRAY
  line, so it is chosen before PRAY; an earlier pill said ON THE BEADS
  in small capitals and read as a label nobody knew to tap).

  **How the Rosary is prayed is chosen on the title page as one line**
  (`RosarySetupCard`, also on the Scriptural Rosary's title page with
  `kind: .scriptural`): HOW YOU'LL PRAY over what is set in words —
  "Female voice · 1× · Every prayer aloud · On the beads" — and a caret
  to a sheet holding the voice, the speed, Pray aloud, the bead counter
  and the prayers after the Rosary. The choices once stood open on the
  page as a filled card of capsules and switches, three of them gold,
  laid over the painting above PRAY; the title page read as a settings
  form. Keep them in the sheet.

  With the bead counter off, the player is the
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

  **Narration comes in voices.** Each meditation carries `narrations`
  (`[Narration]`: a voice slug and a presigned URL, the server's default
  first) beside the legacy `audio_url`, which is the default voice's
  URL. The voices themselves come from `GET /api/voices`
  (`NarrationVoiceCatalog`, refreshed on foreground and kept in
  UserDefaults, with the built-in pair as the first-launch list), and
  the choice is `UserSettings.narrationVoiceSlug`, resolved through the
  catalog so a withdrawn voice falls back to the default. The player
  reads the chosen voice at every load (`PrayerSessionViewModel.
  audioSource`), plays the meditation's default when it lacks the
  chosen one, refreshes links with `?voice=`, and reloads the mystery
  under the hand when the choice changes mid-Rosary. Offline files are
  `meditation_<id>_<voice>.mp3`; the library download saves one voice
  (the chosen one) per meditation, and a copy in another voice is
  played before silence when no link will.
- **Persistence** — SwiftData holds prayer sessions, journal entries,
  consecration progress, and reading progress (True Devotion's and the
  shelf's) — the five `@Model`s registered in `appApp`; UserDefaults holds
  settings, favorites, the resume snapshot and small per-page marks
  (lessons opened, St. Carlo's candle).
- **Progress** — streaks, history, and milestones, reached from the
  Chapel's Prayer Streak tile, Settings → Devotion, and Explore's search.
- **Journal** — entries after a Rosary or consecration day, written
  freely from the Journal tab, or kept from a book as a note; searchable,
  editable, and entirely on device.
- **33-day Consecration** — feast-day selection, per-day scripture and reading,
  bilingual prayers, journal prompts, and a completion rite. The tab's day page
  (`ConsecrationDayOverviewView`) is a column of gold-hairline cards. **Your
  journey** is one of them: the road of the five periods across the top,
  each segment as long as its days (the day of consecration given the
  width of three) with the days kept filled in gold and today's period
  marked beneath, then one period at a time — its name, its title, "Days
  13–19 · 3 of 7 prayed", and its days seven to a row. It opens on the
  period of the day being read; the others are a tap away on the road or
  the arrows beside the name. It replaced five stacked rows on the bare
  page, which crowded it. **The book behind this consecration** is Montfort's
  own cloth (`BookCover` with `LibraryCatalog.trueDevotionDisplay`, the
  ribbon once reading is under way), its title and author, and OPEN THE
  BOOK / CONTINUE READING — never a percentage read, and never a Bible
  glyph, which named the wrong book.
- **True Devotion reader** — the full bundled book with per-chapter progress.
- **Resource library** — How to Pray the Rosary, Finding the Mysteries in
  Scripture, the Marian Library, St. Carlo Acutis, and The Devotion in
  Summary. **Each page is laid out for what it is, never from one
  template** (an earlier pass gave all five the same kicker-arch-ledger
  title page, and it fit none of them): the Marian Library is a
  library — the next feast featured in its painting over a strip of the
  year's dates, the dogmas as four Marian-blue tiles, Scripture as a
  thread, apparitions as year-led cards, the saints as a chronology of
  lifespans, the titles set as a litany; Carlo is a saint's page — his
  photograph full-bleed, a saying for today, his life as a dated
  timeline, his rule of life with the acts to keep it, the candle and
  prayer as a shrine; How to Pray is a course (below); In Scripture is a
  lectionary — pinned tabs per set, a card per mystery with its key
  verse readable without opening; the Devotion in Summary is a book
  digest — the cloth beside the title, the devotion in one sentence, a
  printed contents page with dot leaders, prayers and sayings as cards.
  They share the app's type, colour and ornament, not a layout. Every
  reading, entry, list and prayer lives in `Data/` (`MarianLibraryData`,
  `CarloAcutisData`, `HowToPrayData`, `MysteriesInScriptureData`,
  `TrueDevotionData.teaching`); a page's own framing copy — an intro,
  a lesson's connecting prose, a section's one-line gloss — still sits
  in its view.

  **Short readings are one type.** A Marian Library entry, a chapter of
  St. Carlo's life, one of Montfort's methods and a part of the
  Devotion in Summary are all `LibraryReading`s on `ReadingShelf`s
  (`Models/LibraryReading.swift`; `LibraryReadings.locate(id:)` is the
  one lookup), pushed as `.libraryReading(id:)` and drawn by
  `LibraryReadingView`: shelf and place as kicker ("APPROVED
  APPARITIONS · IV OF VIII"), the saying as a `QuotedPassageText`, prose
  on a versal, named `parts` and two-column `tables` where the content
  has them, then a ledger of doors — **Feast day** (`KeptFeast`; a feast
  on the universal 1962 calendar opens that day's Mass through
  `.missalDay(Date)`; one kept only locally, or a saint raised to the
  altars after 1962 — Kolbe, Padre Pio, Carlo — is named with a note and
  no door), **Pray** (mysteries, a bundled prayer, or a `PrayerShortcut`
  act) and **Read more**. The foot steps along the shelf in place, like the
  chapter readers: the page fades out, the reading is swapped and the
  scroll put back to the top unseen, and it fades in. It once scrolled
  to the top with the old reading still showing, so the old title
  flashed before the new one; and it once re-identified the page with
  `.id()` inside the ScrollView, laying the two out together. A Read more
  door to a reading on **another** shelf pushes, so Back returns to the
  reading it came from; the last door always leads home to the reading's
  own library. Explore's search finds readings by title or dating line,
  and by shelf only when nothing matches by name. A reading that only
  informs is a card; add a door.

  **How to Pray is a course for someone who has never prayed the
  Rosary.** Its front is a drawn rosary whose beads light in the order
  they are prayed, then the course as a path of three lessons, each its
  own page (`RosaryLessonView`, `.rosaryLesson(n)`, 0-based; a lesson opened is
  marked with a check, never scored): I The Beads and the Order, II The
  Prayers (cards with how often each is said and "Say it with me", a
  line at a time), III The Mysteries (painted cards, how to dwell on
  one, this week). Continue replaces one lesson with the next, and the
  destination carries `.id(lesson)`: without it SwiftUI updated the page
  in place, so the next lesson opened halfway down and its `onAppear`
  never ran, and it was never marked opened. The front page lights the
  first lesson not yet opened as NEXT. The path ends on **Your First Rosary**, the guided
  Rosary (`GuidedRosaryView`, `.guidedRosary(MysteryCategory)`); beneath it, Questions
  Beginners Ask (`HowToPrayData.questions`) and Montfort's counsel. The
  beads lesson draws a rosary (`Components/RosaryDiagram.swift`) whose
  parts light as they are named; the guide draws the same one with the
  bead under the fingers lit and the beads behind it gold. Both speak
  `RosaryPart` (`Models/GuidedRosary.swift`: `RosaryMap.traversal` is
  the order the fingers travel, `GuidedRosary.steps(for:)` the whole
  Rosary as 75 steps — where you are, what to do in plain words, every
  prayer in full, each mystery announced on its own step with painting
  and fruit). The guide moves by Back and Next buttons, never a gesture
  to discover, and its Amen records "A Guided Rosary" through the
  completion screen, so it counts as the day's Rosary.

  Prayers get a page of their own through `.devotionPrayer(id:)`
  (`DevotionPrayerView`), found by `DevotionPrayers.find` across the
  Rosary's prayers (`Data/RosaryPrayers.swift`, which How to Pray sets
  under each step of its bead chain) and the consecration's hymns and
  litanies. In Scripture's mysteries open `MysteryPassageView`
  (`.mysteryInScripture`), which sets the Scriptural Rosary's bundled
  Douay verses as running text, so both pages read one Gospel. The
  Marian Library opens on the next feast of Our Lady; St. Carlo's
  votive candle (a day, on device) stays, drawn on the bare page.
- **Reminders** — daily notification at a chosen time and sound, with copy drawn
  from the pool matching the user's stated intentions.
- **Offline** — user-initiated download of every set, its narration in the
  chosen voice, its painting, and the spoken Rosary's recordings for that
  voice.
- **Personalization** — three themes, prayer language, text
  size (app-wide, plus the missal's and the reading shelf's own); the Chapel
  tab's arrange-in-place page (tile order, full/half widths, the tray, rule
  of prayer) and the configurable Pray button (quick act +
  press-and-hold tray), all stored in UserDefaults via `UserSettings`.
  What brings the user to the Rosary is chosen in onboarding and Settings
  → Devotion. (The app-icon picker is built but switched off; see
  Settings.)
- **Onboarding** — eight slides, skippable, re-runnable from About in
  debug builds (`Views/Onboarding/OnboardingView.swift`). The order asks before it
  shows and gives before it asks: welcome → what brings you to the
  Rosary → on the beads or without them (`userSettings.prayOnBeads`,
  asked as "On the Beads" / "Without the Beads" — Settings calls the
  same switch the Bead counter), each shown working in one fixed
  slot: the players' own `RosaryStrandView` to swipe, or arrows stepping
  a mystery at a time → what the app holds for the reasons chosen →
  colors → language → a reminder with evening already chosen ("Remind
  Me at 8 PM") → the Sign of the Cross, whose button takes the first
  step it names (today's Rosary, or How to Pray for someone learning)
  through `OnboardingFirstStep`. The paintings hang in the top of the
  glass and dissolve to clear, so no word is set across a face.

  **The pages travel and nothing else does.** The painting and the dark
  ground under the words are one layer each, standing still while the
  slides pass over them, and both are drawn from where the pages
  actually stand (`OnboardingStage.progress`, in page units, measured
  off the scroll) rather than from the slide that has settled — so the
  painting crossfades under the thumb instead of after the swipe. The
  slides sit in a paging `ScrollView`, not a `TabView`, for that
  measurement, `.viewAligned(limitBehavior: .always)` so a flick can
  never skip a question, and the eight paintings are masked **once**
  over the pair being crossfaded, never one mask each, or the painting
  underneath reads through the dissolve and pops as it leaves. Skip is
  the one move that is not a scroll: six slides whipping past the eye
  is no transition, so the pages are put down and taken up on the other
  side while the paintings dissolve. The ground was once drawn behind
  each slide's own words, 60pt wider than the slide so it would have no
  edge; side by side during a swipe, two of them overlapped in the
  gutter and read as a black band between the slides. One ground,
  interpolated between the slide being left and the one arriving.
  `ViewThatFits`'s scrolling last resort takes
  `.scrollBounceBehavior(.basedOnSize)`: a scroll view with nothing to
  scroll still swallows the sideways drag that turns the page, and the
  beads slide, the tallest of the eight, could not be swiped off.

  The copy
  is plain on purpose: say what a thing is before anything beautiful
  about it, the Church's own names in full (Total Consecration, *True
  Devotion to Mary*), Scripture from the Douay-Rheims with its
  numbering, and noon is the only reminder hour that claims the Angelus.
  Intention wording lives in `PrayerIntention.displayName`/`detail`;
  the raw values are what is stored and never change.
- **Daily Missal** — the 1962 propers for any day, reached from Today's
  Prayer on home, Explore, the Chapel's Liturgy tile and the Pray tray
  (and on a given day through `.missalDay(Date)`), as one scroll surface
  under a single collapsing header. Served live by the third-party Missale Meum API
  (`https://www.missalemeum.com/en/api/v5`, MIT, free to use) through
  `MissalAPIService` — deliberately a separate client from `APIService` so a
  third-party outage never looks like a Lumen Viae failure. The header is
  the screen's own chrome — circular back / ☰ / Aa buttons with a date pill
  absolutely centred — so, like the Office's hour reader, it hides the
  system bar and carries its own Back in every branch. The date pill reads "MON · 14 SEP" and its slot is inset clear of
  the ☰/Aa pair on both sides — the long form ran under ☰. The day is
  stepped a page at a time: ‹ › ride at the foot of the feast plate
  with the vestment dot and class between them, and "Return to today"
  adds a line beneath only once the reader has wandered.
  Its feast plate is the title (and commemorations) over that one row —
  no temporal-line kicker, and no separate rubric row; the plate once
  stacked all four 18pt apart and stood a third of the first screen.
  It **collapses with the scroll itself** (`CollapsingReaderPlate`, shared
  with the Office): its height is the scroll offset point for point, so
  the rail rides on the reading's first line until the plate is gone,
  cut from the top as it passes under the chrome. The offset is measured
  by `onGeometryChange` in global coords (GeometryReader *preferences* do
  not fire during scrolls here) and kept in `ReaderScrollOffset`, an
  observable only the plate reads, so a scroll frame redraws the plate
  and not the Mass. It once collapsed on a threshold-triggered animation
  (96 down / 44 back): the text slid under a plate that stood still, then
  the rail leapt a plate's height while the plate's words hung fading
  behind it — never bring that back. Only the chrome's crossfade of the
  date pill into the feast's name keeps a threshold, with hysteresis
  (shown at half the plate, hidden again below three-tenths); a jump-to-section rail, a 1pt progress line,
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
  texts alone (body, rail, ☰ index, progress denominator). The first open
  asks, once, for the bilingual layout. Texts arrive as
  `[english, latin]` pairs whose line counts align, and pair line for line in
  the shared `MissalPassage*` views (also used by the Office and the Ordo
  page; the section list is built once per real change into `@State`, not
  derived in the body, which the scroll invalidates every frame); in stacked mode the translation is indented 20pt under its line.
  Citations (`*Ps 138:17*`) are small engraved caps in dim gold
  (`MissalReferenceText`); ℣ ℟ ✠ are rubricated in `Rubric.red`, the
  muted vestment red shared with every prayer (`MissalRubric.red` is only
  an alias); the sources' ☩ and bare `+` cross marks are
  normalised to the traditional ✠ in `missalLines`. The versal opens the
  day's Introit — the first proper, never the Ordinary before it, never
  in columns. Motion uses the design system's ease-out
  (cubic-bezier 0,0,0.58,1); the scroll offset is measured on the whole
  content column (a marker inside the LazyVStack gets released
  mid-scroll and goes stale) and section tops in content-space
  coordinates, which scrolling never moves. The ☰ button
  raises the Ordo Missæ index sheet (the section being read lit and
  marked HERE, propers with their diamond, postures, tap to jump); the
  colophon ("ITE, MISSA EST") links the full `OrdoMissaeView`. The date
  pill opens `MissalCalendarSheet`, a month grid — "AUGUST MMXXVI", vestment dot per day from the year calendar,
  today ringed in gold, month chevrons — over a feast readout naming
  whichever day is under the finger (today's until one is: pressing a day
  names it, lifting opens it), with an honest offline row
  beneath: how many of the month's days are cached, and SAVE to fetch the
  rest. Every fetched day is cached in Application Support/Missal (excluded
  from backup) via `MissalCacheService`, and after the first load today
  and the seven days after it, and the Ordo, are prefetched quietly — a
  chapel with no signal still gets the right page; the year's calendar is
  fetched (and kept on disk) the first time the calendar sheet opens; days
  more than 30 back are pruned.
- **Divine Office** — the pre-Vatican-II Breviarium Romanum (1960 rubrics,
  the 1962 books), reached from the Divine Office row of Today's Prayer,
  Explore, the Chapel's Liturgy tile and the Pray tray. Served by our own API's `/office/*` endpoints
  (`GET /office/:date`, `/office/:date/:hour`, `/office/calendar/:year/:month`,
  `/office/versions`), which the Phoenix app assembles from the Divinum
  Officium engine — in production a private, self-hosted Fly app
  (`lumenviae-office`, via `DIVINUM_OFFICIUM_BASE_URL`; see the backend's
  `docs/OFFICE_API.md`) — and parses into JSON. So `OfficeAPIService` is a
  separate client from `APIService`: an upstream engine outage
  (`office_unavailable`, retryable) must never look like the Rosary content
  failing. The version and language ride as explicit query params, pinned
  in `OfficeAPIService` (`rubrics-1960`, `english`) — a future version
  setting threads through there. Every cache file name
  (`OfficeCacheService`) carries the version but **not the language**:
  a language setting must add it there too, or English pages cached
  earlier will be served to someone who chose another language.

  **`DivineOfficeView` opens on the hour it is now.** The page has one
  purpose — the present hour reachable in one tap, and obvious at a
  glance which hour that is — so that hour is lifted out of the eight
  into a lit **lancet arch** (`GothicArchShape(riseRatio: 44/354)`, the
  shallower rise, with the app's standard two-shadow halo applied to the
  *shape* rather than a rounded rect). Every other hour on the page is a
  plain row on the strand, and the arch — a shallower rise than the home
  hero's `ArchHero` (0.34), so it reads as a plate, not a window — is why
  the eye lands there first. It carries
  the page's one filled gold act ("Pray" and the hour's name, e.g. "Pray Compline"), and **no corner
  ticks, second border, or ornament divider inside it** — one ornament
  per idea. Its halo is steady; only the lit NOW mark may pulse.

  Beneath it the eight stand in three groups — the night and the dawn,
  the little hours, evening and night — each strung on one strand of
  gold, each bead in its hour's own `skyColor`, so the strand runs dark
  through bright and back to dark over the day, the three groups under
  their headings (`showHourGroups` is a constant, always on).
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
  two-line plate collapses with the scroll, point for point, through the
  missal's `CollapsingReaderPlate` — no thresholds to tune to a plate's
  height, since the plate's own height is the whole travel. `OfficeReaderSection` cuts the
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
  both sheets draw **`LiturgicalMonthGrid`** (the month in words over the
  year in Roman numerals, chevrons, the weeks, the press-a-day-to-name-it readout) and supply
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
  "Pray the Scriptural Rosary" in In Scripture — its gold button and
  each passage page's row both go straight to prayer in the set being
  read (the row once opened the title page on today's set). The
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
  verse), From (Douay-Rheims) — and at the foot, on `PrayFootScrim`, the
  HOW YOU'LL PRAY line (`RosarySetupCard`) over PRAY. `SetSection` and the scrim are shared with the set
  detail rather than copied.

  **`ScripturalRosaryPrayerView`** is the handoff's 3a: the mystery's
  painting edge to edge under a veil (`PrayerPaintingStage(style:
  .veiled)` — 55% opacity, a gradient darkest at head and foot, lifted
  with the chrome), the reading as a column on the left, and the same
  strand the meditation's player hangs at the right edge
  (`RosaryStrandView`). **The column is anchored, and only its words
  change.** It hangs level with the first bead of the strand's window
  (`readingTop`, from `RosaryStrandView.windowTop`) and never moves: a
  head of the bead's name in small capitals (rolling) over the
  mystery's name in the display face with two lines' room kept whether
  it needs them or not, then one slot for the bead's words — the verse
  in the Medium face at the reading size + 1 (the italic thinned to
  hairlines over the painting), its citation, the fruit on an Our
  Father, a cue only where it is news — which is one view identified by
  the bead and **crossfades whole** over the one leaving, in a ZStack
  with nothing beneath it. An earlier draft centred the column on the
  glass and let each Text change under its own `contentTransition`: a
  longer verse pushed the whole column up, the lines re-wrapped
  mid-fade, and the words were unreadable for as long as the animation
  lasted. Where the Rosary stands is said once, under the mysteries'
  beads at the foot (THE FIRST JOYFUL MYSTERY), and the cue speaks only on the
  first bead of the Rosary and the decade prayed, where the next mystery
  is named so the turn is expected — a cue repeated fifty times is
  chrome. Positions run Our Father → ten Hail Marys (seven in a sorrow)
  → Glory Be: the Our
  Father bead announces the mystery (its description, passage and
  fruit), each Hail Mary carries its verse, and the decade prayed the
  column reads the doxology and then, except in the Seven Sorrows
  chaplet, the Fatima Prayer (Latin when Latin
  alone is the prayer language; `BeadReading.closingPrayer`) under GLORY
  BE & FATIMA PRAYER. **Swipe down for the next bead, up for the one
  before; the decade turns on its own** — there are no arrows and no
  swipe between mysteries. An earlier draft walked the beads with two
  arrows, and before that a gold disc stood between them; both are
  gone, and must not come back: nothing but the beads moves the Rosary
  forward. The column still taps forward and long-presses back
  (VoiceOver cannot swipe), and the one haptic keys on `beadPosition`.
  The header is × · SCRIPTURAL ROSARY · Aa (`ReaderTextOptionsSheet`
  without its narration section); the foot is the still mystery strand
  over the mystery's ordinal name, a Pray aloud pill
  (`UserSettings.prayAloud`) and the ⋯ tray with no download row. There
  is no meditation narration and no reader; said aloud, the spoken
  Rosary (see API Endpoints below) reads each verse before its Hail Mary,
  and a play disc and caption stand above the strand while it does. On
  the last bead the cue gives way to AMEN; completion records locally
  through `CompletedPrayer` (the completion screen takes that value now,
  not a set) and never posts to the API. An interrupted one resumes from
  Home's card (`InProgressPrayer.kind`), on its own screen, at its bead.

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
  reached from the home page's reading shelf, Explore, and the Chapel's
  Library and Reading tiles. Nothing is bundled: the
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
  chapter's foot (180 citations in the Imitation, 166 in the Story of a
  Soul, thirty-four in one chapter alone). `chapterTitles` supplies
  titles for an edition that prints none — Pusey's thirteen books; the
  rest (`partPattern`, `headingOverrides`, `titleRunsToBlankGap`,
  `minimumChapterLength`) are in the catalog beside them.
  Every one of these rides in `editionFingerprint`, so correcting one
  book retires that book's cached parse and no other's.

  The four books cut to: Imitation 115 units — 114 chapters under four
  part headers, plus the exhortation to Holy Communion that opens Book IV
  as a unit of its own; Story of a Soul the Prologue, chapters I–XI, and the
  Epilogue (13); Confessions 13 books; Dolorous Passion "To the
  Reader", nine Meditations, the Introduction, and chapters I–LXVI (77).

  **Audio is tied to the text** by `LibraryTrackMap`, from the catalog's
  `trackMapping`: `.sequential` where a recording gives each chapter its
  own file (Thérèse, Emmerich — 1:1, verified track for track; an
  `offset` covers front-matter tracks the text does not carry, and
  consecutive files a reader labelled "Part 1"/"Part 2" are gathered back
  into one reading),
  `.bookChapterRanges` where one file holds many (kept for such a
  recording, though none is offered now: the Imitation's LibriVox 575
  gathers ten chapters a file, so the Imitation has `librivoxID: nil` and
  no recording — restoring one means a per-chapter reading, not a
  remapping), `.bookSpans` where one book needs several files
  (Augustine, LibriVox 2601 — **the Pusey reading**, matching the text;
  the other complete Confessions is Outler's and must never be offered
  as the voice of this one). The alignment decides what the UI may
  claim: a track that reads one whole chapter offers HEAR THIS READ
  bare, one that holds more than this chapter adds "· from" and the
  chapter it starts at, rather than pretending the voice starts where the
  reader is. A DEBUG assertion prints any
  chapter left unmapped — a volunteer re-cutting their ledger is the
  way this drifts.

  A book may also name the speed its reader is best heard at
  (`preferredRate` — Thérèse's is 1.5, because Susan Morin's reading runs
  thirteen hours and forty minutes). That is the shelf's opening offer;
  the reader's own choice per book is remembered and outranks it. It is
  kept apart from the app-wide narration speed —
  `AudioService.setPlaybackRate(_:remember:)`, given back when the
  listening session stops (`AudioService.restoreRememberedRate()`) — so
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

  Reader: paragraphs drawn by `ReaderProseParagraph` (shared with True
  Devotion's chapter reader, not `ReadingText`) in `ReadingTypography`'s
  rhythm, sized from its own `readingTextScale` (15–26pt, the Aa), a
  versal initial (never on a paragraph that opens on a quotation mark —
  the book readers leave that one plain), a hairline place rule, "9 of 13", a ☰
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
  parsing it back apart meant an edited note lost its shape. On the
  journal's page and card the entry is taken apart again
  (`JournalEntry.keptPassage`, which falls back to the plain text if
  the reader has rewritten the passage) and the passage is set as a
  quotation (`Components/QuotedPassageText.swift`): the opening mark
  alone gilded, large in the display face and hung in the margin the
  way a pull quote's is, the words flush beside it in the italic, the
  citation under a dash without its rights note, and the reader's own
  words beneath as reading text — theirs is the paragraph that opens on
  the versal. `DropCapText` (under `ReadingText`, the journal and the
  missal) gilds the opening mark of any paragraph that begins on a
  quotation — a journal entry that opens on a saying — instead of hanging a
  small mark before a gilded letter, which fell one character too late
  and read as a misprint; `QuotedPassageText` is that same drawing in
  the italic, with a citation.

  A **mark** is a place and nothing else — no colour, no note, no
  count against the reader, and no review queue. It exists so a reader
  can walk back to a page that struck them. Marks are *not* a
  highlights library and must not grow into one.

  The two differ in durability, and honestly so: a mark on the shelf
  is a chapter and paragraph index, meaningful only inside one cutting
  of an edition, so `retire` lets marks go with the reading place when
  a catalog rule changes. True Devotion's marks are keyed
  `chapterID:paragraph` — stable only because its text is regenerated by
  appending, never by inserting a paragraph (see `Tools/TrueDevotion`);
  they are never retired. Journal notes hold the
  passage text itself and outlive every re-cut.

  Never a percentage, never a streak, never a count of chapters left
  unread. Time against a **recording** is allowed, because it is a
  fact about a file rather than a judgement of the reader — "2 h 5 m
  read · 7 h 26 m left in the book" is drawn only from tracks the
  alignment maps to a chapter, so a finished book really does reach
  zero. A words-per-minute estimate is never allowed: True Devotion
  has no recording, so its act stays quiet rather than guessing. (Two
  places still break this and are bugs, not precedents: True Devotion's
  contents ledger prints each chapter's `estimatedMinutes` as "N MIN",
  and the consecration day page prints a reading's "N min" — both
  words ÷ 200.)

  The one figure the shelf does keep is **the day's measure**
  (`ReadingDayMeter`, TODAY'S GOAL on a book's page and True Devotion's,
  chosen in `ReadingGoalSheet`): minutes with a book open, or a chapter a
  day, toward a goal the reader set — a dial for today only, reset
  silently each morning, never carried forward, chained into a streak or
  counted against anyone.

### Not built yet

- A Divine Office version/language setting (Monastic, Dominican, and the
  other rubrical versions the API's `/office/versions` already serves) —
  `OfficeAPIService.version`/`.language` are the seam, and
  `OfficeCacheService`'s file names must gain the language
- Auto-scroll *synced* to audio, word by word. Both readers follow
  proportionally instead — the prayer reader and the Spiritual Reading
  reader — because neither the narration nor LibriVox carries timings
- A setting to switch between the Traditional and Modern (Luminous Thursday)
  schedules — `ScheduleService` is the seam for it
- Feast-day overrides on the schedule (seasonal Sundays are built)
- Server-side sync of journal entries or progress. The journal, streaks,
  history and reading places live only on the device; the one thing sent
  is an anonymous completion when a meditation set's Rosary is finished
  (`POST /completions`, see API Endpoints)
- Per-meditation artwork (the API has set paintings only), and
  `intentions` on a set for the picker's deferred "Find a set for what you
  are praying for" row

## Design System

### Colors

Every colour — gold included — comes from the active theme's
`ThemePalette` (`DesignSystem/Theme.swift`), read through `AppColors`;
never write a hex at a call site. Only `AppColors.textPrimary` (white) is
the same in every theme. There are three themes, and **new installs
default to Candlelit**:

| Token | Candlelit (default) | Midnight | Marian Blue |
|-------|---------------------|----------|-------------|
| background | `#0A0A15` | `#131324` | `#0D1730` |
| card | `#151521` | `#1F1F38` | `#17284E` |
| gold | `#E3BC5B` | `#D4AF37` | `#D9B84A` |
| goldLight | `#F3D89A` | `#E8C547` | `#E9CC6E` |
| cream | `#F6F1E4` | `#F5F0E1` | `#F4EFE2` |
| textSecondary | `#8B8BA5` | `#9C9CB5` | `#93A5C8` |

### Typography
- **Display and headlines:** Cinzel (`AppFonts.titleFont` Regular,
  `headlineFont` SemiBold); small tracked capitals are Cinzel too
  (`labelFont`).
- **Body:** EB Garamond Medium (`bodyFont`; `semiboldBodyFont` for
  emphasis); **reading:** EB Garamond Regular (`readingFont`).
- **Quotes/Scripture:** EB Garamond MediumItalic (`italicFont`) or Italic
  (`readingItalicFont`).
- **Bundled fonts:** Cinzel (Regular, SemiBold) and EB Garamond
  (Regular, Medium, SemiBold, Italic, MediumItalic). Always go
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

### Icons

Three families in `Assets.xcassets/Icons`, all drawn through `AppIcon`
(never `Image(...)` at a call site) and all rendered as templates:
**`ph-*`** are Phosphor (light, plus `ph-*-fill`); **`ch-*`** are
Christicons, the devotional glyphs — `stroke-width="1.5"`, round caps and
joins, on a 24×24 viewBox, except the `-fill` variants and the two
filled hearts; and **`lv-*`** are drawn for this app (`lv-breviary`,
`lv-chalice`). A new stroked `ch-*` icon must be stroked at 1.5 or it
stands heavier than everything beside it. The `lv-*` glyphs were drawn
at 1.15 to sit level with Phosphor light (`AppIcon.swift` says so), but
`lv-breviary` has since been redrawn at 1.5 — settle which weight the
family keeps before drawing another. Note that `qlmanage` cannot preview these
faithfully: it renders a stroke-only SVG blank and *fills* path data
meant to be stroked, so check a new glyph in the running app.

A gold act's glyph names the act: `GoldCTAButton(glyph: .play)` for one
that begins a prayer, `.chevron` (trailing) for one that goes on to a
page, and a trailing check (`trailingIcon: "ph-check"`) for one that
completes something. A Latin cross once led
every page-level act and named nothing; the cross now stands on the tab
bar's Pray medallion alone. The `OrnamentDivider`'s centre cross is an
ornament, not a control, and stays.

One meaning per glyph. The same door wears the same icon everywhere it
appears — the Missal is `ch-altar` on every surface, the Office
`ph-clock`, the Marian Library `ch-lily`, In Scripture `lv-breviary`
(the Scriptural Rosary keeps `ch-bible`), the Marian dogmas
`ph-star-fill`, the saints `ph-user`, the Consecration
`ch-consecration` (the Marian monogram, a cross over an M; the crown is
True Devotion's alone) — and a glyph standing for a
devotion is the one that devotion's own iconography uses:
`ch-sacred-heart` is Christ's and belongs to the Sacred Heart alone,
while the Seven Sorrows take `ch-sorrowful-heart`, Mary's heart pierced
by Simeon's sword. (The code does not yet keep this everywhere: as of
Sept 2026 `ch-sacred-heart` marks True Devotion's "The Spirit of This
Devotion" and the consecration onboarding's "The Gift"; `ch-lily` also
marks the Memorare, Our Lady's Psalter and the Cana reading; `ph-clock`
also marks the reminder-time row. Fix those; don't copy them.)

### Motion

`DesignSystem/Motion.swift` holds the app's named motions — the `Motion`
enum — and a call site should reach for one before writing a duration
(about a hundred literal `.easeOut(duration:)`-style calls predate this
and remain, most in onboarding, the Chapel and the completion screen;
don't add to them): `beadSlide` and `beadSettle` (the strand), `words` (a bead's
name, verse or cue changing), `decadeTurn` (painting, kicker and title
crossfading to the next mystery), `chrome`, `panel` (a reader or tray
arriving), `settle` (a press or toggle landing), `crossfade` (content
changing in place), and `ease(_:)`/`travel(_:)` — the design system's
cubic-bezier curves the missal and office readers use. Springs settle
and barely overshoot (damping ≥ 0.74 — the milestone celebration's 0.5
"bounce" on the completion screen, the consecration completion and the
streak widget are the exceptions to fix, not follow); the two press styles (`SacredCardButtonStyle`,
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
  a second. The exception is a **block of several lines that changes
  wholesale** — a bead's verse — where `contentTransition` re-wraps the
  lines as they fade and nothing can be read until it is over: that
  block is one view identified by what it shows, crossfading inside a
  `ZStack` slot with nothing laid out beneath it, so its height can
  change without moving anything.
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
- **Reduce Motion is honoured** at every scripted sequence (the completion
  seal, the strand's descent) and every drift: scale, blur and offset
  fall away, timings shorten, crossfades remain. Direct manipulation —
  the strand following a finger — is not motion and stays. (The
  completion screen's `MilestoneCelebrationCard` still ignores Reduce
  Motion; it is the one to fix.)

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
  its sides. Never write a fractional literal line width —
  `lineWidth: 0.5`, `frame(height: 0.5)`, or the 0.6s and 0.8s that
  still survive in `BookCover`, `PendantCrossView` and `ExploreView`.
- **Every `.sheet` carries `.presentationBackground(AppColors.background)`**. A sheet's own container is the
  system's white; the content's dark ground is clipped by the same
  rounded rim, and at that rim's anti-aliased edge the white shows
  through as a hairline around the top of every tray. The background
  goes on the sheet's content view, beside its detents.
- **Every sheet is set in one grammar** (`DesignSystem/SheetChrome.swift`,
  taken from the consecration day's index, which read well where the
  others did not): `.sheetGround()` — the page gradient, the system drag
  indicator (never a grabber drawn by hand), and the background above —
  then `SheetHeader`, a gold kicker over the Cinzel title with room under
  the indicator (the kicker says where or when, the title what), then
  ruled `SheetRow`s: glyph, name, italic line, and at the trailing edge a
  caret, a check, a small tracked state (HERE, QUICK TAP, PLAYING) or the
  row's own control. The current or chosen row is lit on a faint wash of
  gold; no filled card stands around the rows. Groups take
  `SheetSectionLabel`, explanations `SheetNote`, header acts
  `SheetHeaderAction` (DONE, CLOSE, CANCEL — never a ✕ in a disc). A sheet
  that is something other than a list — the month grids, the journal and
  feedback forms, the reading and footnote pages, the share card, the
  now-playing transport — keeps its own body and takes the ground and the
  header only. The Missal's one-time layout question keeps its indicator
  hidden, because it cannot be dragged away and a grabber would say it
  could.

### Visual Style
- Dark, contemplative theme on the page gradient (`AppColors.appGradient`)
- Gold accents for sacred/important elements; one filled gold act per screen
- Ruled ledgers and 16pt hairline outlines at `gold@0.24` on the bare
  page — filled card surfaces only where a section above says so (the
  Chapel's tray, the chant sheet)
- Heroes and plates dissolve to clear, never to a flat slab
- Minimalist, distraction-free UI for prayer focus

## Technical Notes

- **Minimum iOS:** 17.0 (uses `@Observable`); newer APIs are gated behind
  `#available`. Building needs Xcode 26 (Swift 6.2 toolchain:
  `@concurrent`, approachable concurrency).
- **Framework:** SwiftUI throughout; the one UIKit view is the system mail
  composer (`MailComposeSheet` in the feedback form). UIKit is imported
  elsewhere only for `UIImage`, `UIApplication`, `UIPasteboard` and `UIFont`.
- **State Management:** `@State`, `@Observable`, `@Environment`
- **Navigation:** `NavigationStack` driven by `AppRouter` (`path` + `AppRoute`).
  The consecration tab hosts its **own** stack as a sibling of the outer one —
  nesting it silently drops the outer stack's destination table. Don't
  "simplify" that.
- **Persistence:** SwiftData for prayer sessions, journal entries,
  consecration progress and reading progress; UserDefaults for settings,
  favorites and the resume snapshot; Application Support for offline
  content and the Missal, Office and Library caches.

### Data Architecture

**From the API** (`https://lumenviae.fly.dev/api`):
- Meditation sets and their meditation text
- Set artwork: each set carries a flat `image_*` block — unsigned, immutable
  URL, a normalized focal point, pixel size, alt text, attribution — all null
  together when there is no painting. Read it through `SetArtwork`; draw it
  through `SetArtworkView` (the fallback chain: set painting → category
  painting) and `FocalFill` (one crop rule for every size)
- Meditation narration audio (presigned URLs, ~24h; the set says when they
  die in `audio_expires_at`, and `GET /meditations/:id/audio` re-signs one)
- Consecration chant audio (presigned per prayer)
- The spoken Rosary's clips, per voice (`GET /rosary/audio`)

**From other sources** (each through its own client, so their outages
never look like ours): the Missal from Missale Meum, the Office from our
`/office` API, the Spiritual Reading shelf from Project Gutenberg and
LibriVox.

**Bundled in the app** — doctrinal and stable, so it must work with no network:
- The mysteries themselves — names, scripture references, descriptions,
  fruits (`Data/MysteryData.swift`). The server has `GET /mysteries`, but
  the app does not call it.
- Every Rosary prayer, English and Latin (`Data/RosaryPrayers.swift`;
  `BilingualPrayer.swift` holds only the shared Glory Be and Fatima text)
- The 33 days of preparation, the day of consecration, and their prayers
  (`Data/ConsecrationData.swift`)
- *True Devotion to Mary* (`Resources/TrueDevotionBook.json`, GENERATED by
  `Tools/TrueDevotion` from Faber's 1862 translation — regenerate, never
  hand-edit, and never swap in the modern Montfort Fathers translation,
  which is still in copyright)
- The Scriptural Rosary's 249 verses, the Marian Library, How to Pray, In
  Scripture, St. Carlo, the daily quotes

**On device:**
- Preferences, favorites and the resume snapshot (UserDefaults)
- Prayer sessions, journal entries, consecration and reading progress
  (SwiftData). None of it is synced; the one thing that leaves the
  device is the anonymous completion below.
- Downloaded sets, audio, and set paintings (Application Support, excluded
  from iCloud backup). Paintings are `images/set_<id>_<hash>.jpg`, so a
  replaced painting is a missing file, never a HEAD; a library downloaded
  before paintings existed is not made stale — Download again fetches only
  what is absent

> A companion Phoenix web app owns the meditation content so it can be updated
> without an app release. Anything the user must be able to pray without a
> connection is bundled instead.

### Design Principles
- **Build for flexibility:** Even though Luminous mysteries aren't in the default schedule, data models and UI should support all five categories (the Seven Sorrows included) equally. Schedule logic should be configurable, not hardcoded.
- **Separation of concerns:** Keep schedule/calendar logic in `ScheduleService`, the one place a Modern schedule or feast-day overrides would go.
- **Content-driven:** Mystery data (titles, scriptures, meditations) should be stored as data files, not hardcoded in views.

## Content Requirements

> **Note:** Meditation sets, their narration and the chant are managed in the web app and served by the API; everything under "Bundled in the app" above ships in the app.

### Meditation Content Structure (from API)
- **Sets:** five meditations each (seven for the Seven Sorrows), in all
  five categories. As of Sept 2026 there are 25: Joyful 6, Sorrowful 5,
  Glorious 5, Luminous 4, Seven Sorrows 5.
- **Labels (live in API):** Each meditation set carries a `labels: [String]` array. The controlled vocabulary lives in the web app (`LumenViae.Rosary.Labels`) and is currently Intentions, Saints, Scriptural, Contemplative, Considerations. The iOS picker builds its multi-select filter chips from these and groups unfiltered browsing by each set's *first* label, so order labels primary-first. If a set arrives without `labels`, the picker gracefully falls back to a flat list. Favorites are on-device (not API).
- **Label wording is a display concern:** filtering and grouping match the raw API string, but the picker renders labels through `MeditationLabel.displayName` (`Models/MeditationSet.swift`). "Considerations" currently shows as **Reflections**. Rename in that map, not in the database.

### API Endpoints (as implemented in `APIService`)
```
GET /mysteries[?category=]              # Implemented but unused — mysteries are bundled
GET /meditation-sets?category=:category # [MeditationSetSummary] for a category
GET /meditation-sets/:id                # Full MeditationSet with meditations + audio_expires_at
GET /meditations/:id/audio[?voice=]     # Freshly signed narration URL + voice + expires_at
GET /voices                             # [NarrationVoice], default first
GET /prayers/:prayerId/audio            # Presigned chant URL for a consecration prayer
GET /rosary/audio[?voice=][&include=]   # The spoken Rosary: prayers, announcements, verses
POST /completions                       # { meditation_set_id, prayed_aloud } — a finished set's Rosary
```
**The completion is the app's one write, and it is not nothing.** When a
meditation set's Rosary is finished, `recordCompletion` posts the set id
and whether it was prayed aloud. The server stores it with the time, a
city/region/country looked up from the request's IP through a third-party
service, and the IP truncated to /24 — no account, device or install
identifier (the backend's `docs/COMPLETION_ANALYTICS.md`). The Scriptural
Rosary and the Guided Rosary never post. The privacy manifest
(`PrivacyInfo.xcprivacy`, "Nothing is collected") and the in-app privacy
text (prayer records "never leave your device") do not yet say this — keep
the three in step with any change to what is sent.
The spoken Rosary (`UserSettings.prayAloud`, off by default) says every
prayer aloud and moves the beads with the voice, in both the meditation's
player and the Scriptural Rosary. `SpokenRosaryScript` (Models/SpokenRosary)
builds the script, pure; `SpokenRosaryPlayer` walks it and takes track
navigation while it runs, so the screens' own narration loading stands
aside; `RosaryAudioPack` saves each voice's clips under
OfflineContent/rosary/<voice>/ by the server's hashed file names, so a
reworded prayer is a new file and the pack prays offline once fetched.
The words must stay the server's: the prayer text in `RosaryPrayers` is
copied in `LumenViae.Rosary.PrayerAudio`, and the verses reach the server
as `Tools/ScripturalRosary/scriptural_rosary.json` - change both together.
While the opening and closing prayers are said aloud, neither player borrows
the first mystery: `PendantStage` (Components/PendantCrossView) draws the
pendant in place of the painting - a worked budded cross, the large bead,
three small beads, the chain and the centrepiece, lit as the voice climbs
(`PendantPlace` on each script segment) - `PendantTitleBlock` names the
prayer in place of the mystery's title, and the decade strand comes in
with the first mystery. The Lock Screen shows the cross, rendered once.
The script's order is the server's (`PrayerAudio.script/3`), and the
recorded prayer ids are twelve: the Rosary's eight plus
`act_of_contrition`, `sorrows_closing_prayer`, `memorare` and
`st_michael_prayer`. The Seven Sorrows are the Servite chaplet: Sign of
the Cross and Act of Contrition; per sorrow the announcement ("The First
Sorrow of Mary: The Prophecy of Simeon"), meditation or verses, Our
Father, seven Hail Marys and a Glory Be with no Fatima Prayer (the strand's
Glory Be bead and the Scriptural Rosary say so on screen too); then three
Hail Marys "in honor of her tears", `sorrows_closing_prayer` and the Sign
of the Cross. The four Rosaries may add `RosaryClosingExtra`s after
`rosary_closing_prayer`, off by default and chosen in Settings or on a
set's page (`UserSettings.prayForHolyFather`, `prayMemorare`,
`praySaintMichael`), always said Holy Father (Our Father, Hail Mary,
Glory Be, captioned "For the intentions of the Holy Father"), Memorare,
Saint Michael; never in the chaplet. `OfflineContentService.downloadAll`
also fills the pack for the chosen voice (`SpokenRosaryScript.everyClip()`),
best-effort, so the first spoken Rosary prays offline. The pack reuses its
saved manifest while the links have more than five minutes to live and
refetches before downloading once they do not; offline it says what is on
disk. Resume keeps the script step (`SpokenStep` on `InProgressPrayer`,
kept current through `SpokenRosaryHost.spokenRosaryReached`), used only if
the rebuilt script still has that prayer at that place. Completions post
`prayed_aloud` (`POST /completions`).
A debug build takes `LUMEN_VIAE_API_BASE_URL` to try an undeployed server.
Meditation audio arrives as `narrations` (one per voice) plus the legacy
`audio_url` on each meditation; the prayer flow asks `/meditations/:id/audio`
for a fresh one only once the set's have expired or a load has failed. Errors come in one envelope,
`{ "error": { "code", "message", "details"? } }` — `APIService.send` decides on
the status code and carries `code` on `APIError.serverError`. There is no
journal endpoint and none is planned — journal entries are local.

## Glossary

- **Decade:** One Our Father + 10 Hail Marys + Glory Be and the Fatima Prayer (one mystery)
- **Mystery:** A scene from Jesus/Mary's life to meditate on
- **Rosary:** Full prayer = 5 decades (one set of mysteries)
- **Chaplet:** A devotion prayed on its own beads — here the Servite
  chaplet of the Seven Sorrows (seven sorrows of seven Hail Marys, no
  Fatima Prayer); not a shorter Rosary

## Git Commit Guidelines

**IMPORTANT**: Do NOT add AI co-author attribution to commits. All commits should be attributed to the human developer only.
