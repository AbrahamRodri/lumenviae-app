# Lumen Viae - AI Reference Guide

> "Light of the Way" - A Catholic Rosary meditation and prayer companion app

## App Overview

Lumen Viae is an iOS app built with SwiftUI that guides users through praying the Rosary with meditations, scripture, and tracking. The app has an elegant, dark theme with gold accents inspired by traditional Catholic aesthetics.

## Core User Flow

```
Home Screen
    │
    ├── Featured card: today's mysteries ("Pray the Rosary", a chevron)
    │   └── Goes to: that day's mysteries' page
    │
    └── Sacred Mysteries Grid (the week's sets, then the Seven Sorrows:
        Joyful, Sorrowful, Glorious on Traditional, with Luminous after
        Glorious on Modern; VIEW ALL always lists all five)
        └── Tap any mystery card
            │
            ▼
The mysteries' page (SelectMeditationView) — one Rosary, three forms
    │
    ├── WAYS TO PRAY: The Scriptural Rosary · The Rosary Said Aloud, each
    │   opening its own page with these mysteries chosen
    ├── MEDITATIONS ("a short reading on each mystery"): gallery of tiles
    │   (default) or ruled list (remembered), pinned sets on top, the
    │   funnel → "Kind of meditation" tray
    └── Tap a set
        │
        ▼
The Rosary's own page (RosaryConfirmPage — a set's, the Scriptural
Rosary's and the Rosary Said Aloud's are the same page)
    │
    ├── The painting dissolving into the page, Back over it
    ├── Kicker, name in Cinzel, one italic line
    ├── YOUR ROSARY TODAY
    │   ├── Audio: Meditation Only | Whole Rosary (Read in Silence in the
    │   │   Scriptural Rosary; none in the Rosary Said Aloud, always aloud)
    │   ├── Counting: On My Rosary | On the Screen — only while the Whole
    │   │   Rosary is not chosen
    │   └── Rows: Mysteries (not for a set), Voice & speed (not while
    │       the Scriptural Rosary is read in silence)
    ├── Past the choices, a ledger for whoever scrolls (a set's meditations,
    │   source, offline copy, first meditation)
    └── "PRAY" (the screen's one gold act) — nothing set beneath it,
        and never an estimated duration
        │
        ▼
Prayer Flow (5 Mysteries/Decades)
    │
    ├── 1st Mystery → 2nd Mystery → 3rd Mystery → 4th Mystery → 5th Mystery
    │   (Each mystery: Meditation + 10 Hail Marys + Glory Be; the Seven
    │   Sorrows chaplet is seven sorrows of seven Hail Marys each)
    │   On the Screen (Counting's default): one strand at the right edge,
    │   swipe down a bead at a time, the mystery turns on its own. On My
    │   Rosary: arrows and a swipe between mysteries, no strand. With the
    │   Whole Rosary the voice moves the beads on the screen.
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

**The two schedules** (Settings → Devotion → Daily Mysteries; Traditional unless chosen):

| Day | Traditional (default) | Modern (RVM 38, 2002) |
|-----|-----------------------|-----------------------|
| Sunday | By season — Joyful in Advent, Sorrowful in Lent, Glorious otherwise | The same |
| Monday | Joyful | Joyful |
| Tuesday | Sorrowful | Sorrowful |
| Wednesday | Glorious | Glorious |
| Thursday | Joyful | **Luminous** |
| Friday | Sorrowful | Sorrowful |
| Saturday | Glorious | **Joyful** |

> **Note:** Traditional is the pre-2002 schedule and the default; no install's day changes unless its user chooses Modern. The home grid shows the sets the week prays (`ScheduleService.weekCategories`, derived from the weekday rule, in the week's order from Monday) and then the Seven Sorrows: on Traditional that is the 2×2 of Joyful, Sorrowful, Glorious and the Sorrows, as it always was; on Modern the Luminous stand after the Glorious, the week's four Rosaries form the square, and the Seven Sorrows, a chaplet rather than one of the week's sets, span the row beneath them (an odd count gives its last card the whole row, never a half-width card beside an empty cell). `HomeViewModel.allCategories` is read fresh like `todaysCategory`, so the grid follows a change of schedule the moment Settings is left. The Luminous Mysteries are always available from the grid's VIEW ALL page or from Explore. **Modern keeps the seasonal Sunday:** RVM 38 gives Sunday to the Glorious but leaves room for the liturgical season, and with the custom kept the two schedules differ only on Thursday and Saturday, which is how the sheet describes them. The choice is `UserSettings.mysteryScheduleRaw` (`MysterySchedule`, raw values `traditional`/`modern`), read by `ScheduleService.category(for:)` as a default argument, so every surface that names or opens "today's mysteries" follows it without passing it along. **It is a per-user client preference:** the server's `LiturgicalCalendar` and the web copy keep the traditional schedule and are not changed by it. A debug build can be launched on another day with `SIMCTL_CHILD_LUMEN_VIAE_TODAY=2026-10-01` (`ScheduleService.today`).
>
> `ScheduleService` computes the seasons on device (Easter by Meeus/Jones/Butcher; Lent = Ash Wednesday up to Easter; Advent = the Sunday on or after Nov 27 through Dec 24) and its **Traditional** schedule is kept **identical to the server's `LumenViae.LiturgicalCalendar`** — Christmastide and Eastertide deliberately count as "ordinary" for this rule on both sides. Change the two together, along with the site copy (the web app's home, dashboard and category pages). The day names the app shows (`MysteryCategory.daysPrayed`, and `Mystery.daysPrayed`, which reads it) are computed from the rule by `ScheduleService.daysPrayed`, so they follow whichever schedule is chosen; `MysteryData` no longer carries them. The server's `mysteries.days_prayed` column is not decoded by the app, and as of Sept 2026 it (and `priv/repo/seeds.exs`) still carries older, non-traditional days — fix it there before anything shows it.
>
> `ScheduleService` also gives Septuagesima, Pentecost and Trinity Sunday (`septuagesima(year:)`, `pentecost(year:)`, `trinitySunday(year:)`), which the Chant Library's wheel cuts its six seasons at (`ChantYear`: Advent, Christmas to Septuagesima, Lent, Easter, Pentecost's octave, after Pentecost). **Those six are for display only** and decide nothing about which mysteries are prayed: that stays `season(for:)`'s Advent, Lent and ordinary, as the server reckons them.

### The Prayer Day

**Everything prayed is counted on one day, and it turns at four in the
morning, not at midnight** (`Models/PrayerDay.swift`, built on
`PrayerBook.dayBeginsAtHour`, the one constant). Night Prayers and a
late Rosary belong to the evening they close: said at half past twelve,
both count for the day before, and the day that follows still asks for
its own. The Rosary's history had turned at midnight and the Prayer
Book's offered at four, so a Rosary and Night Prayers said together
after midnight landed on two days, and the Chapel showed one offered
and the other not.

The prayer day decides the history and the streak
(`PrayerHistoryService`: `sessions(on:)` is the prayer day an instant
falls in, `sessions(onPrayerDay:)` a day by its date), the Prayer
Record's calendar, week row and TODAY, the Chapel's Today tile, focus
and flame ("Prayed today", the week's ring), `StreakWidget`, milestones,
the Pray button's Continue (`InProgressPrayer.isContinued`), and the
Prayer Book's offered (`PrayerBookStore`). A prayer day is named by its
calendar date's midnight — 12:30 AM on a Wednesday is Tuesday's, named
Tuesday 00:00 — so it drops into a calendar grid and a `Set<Date>`;
`PrayerDay.interval(of:)` runs from four to four, 23 hours when the
clocks spring forward within it and 25 when they fall back, and the turn
is read off the wall clock, so both changes leave it at four. Sessions
are stored with the moment they ended, as they always were, and counted
into days on read: nothing stored changes, and past history is recounted
by the rule. `PrayerDayClock` holds today's prayer day as
`CanonicalClock` holds the hour — asleep to the next turn, refreshed on
foreground — and the Chapel and the Prayer Record read it, so they roll
over at four while they are open; home's hour row already redraws at
four on `PrayerBookHourSchedule`.

**What the Church's calendar decides stays on the calendar day:** which
mysteries are today's (so a Rosary begun at 12:30 AM on a Wednesday
prays Wednesday's mysteries and counts for Tuesday), the Missal's and
the Office's dates, the liturgical seasons and feasts (the Chapel's day
strip, which at 1 AM names the new day's feast over a Chapel still
counting the evening's prayers), the consecration's day numbering, the
journal's TODAY, and the day's reading measure (`ReadingDayMeter`),
which is reading rather than prayer. The Rosary's resume and the guided
Rosary's kept place expire after 24 hours, not at a day's turn, and are
unchanged.

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
(shown as **Reflections**), Contemplative (shown as **Inside the
Scene**, the title onboarding's Kinds of Meditation gives it), Saints,
Scriptural (shown as **Gospel**), Intentions —
see Content Requirements below. As of Sept 2026 the Saints sets are
Liguori, Ignatius, Chrysostom, Newman, Augustine and Aquinas, beside
Sheen, Emmerich, Agreda, Faber and Guéranger. **No
set carries Intentions**: the backend's curation guide
(`docs/MEDITATION_CURATION_GUIDE.md`) admits only verbatim text from
public-domain editions, so originally written vocation sets ("As a
Father", "In Times of Suffering") are not planned — don't build UI that
waits for them. The quick act's "today's Rosary" picks one of the day's
sets at random.

The Rosary is **one prayer in three forms**, chosen on each mysteries'
page: with a meditation set, as **the Scriptural Rosary** — a verse for
every Hail Mary, no meditation — or as **the Rosary Said Aloud**, every
prayer said aloud with no readings between (it was the Rosary Aloud,
then the Holy Rosary, which a newcomer could not tell from the Rosary;
the mysteries' page lists it as "The Rosary Said Aloud · Every prayer,
no readings", under WAYS TO PRAY). Every page reads its name from
`ScripturalRosaryViewModel.displayName` (`holyRosaryName`). The forms are
`RosaryForm` (`Models/RosaryForm.swift`); the Scriptural Rosary is not a
kind of meditation, and the filter's "Scriptural" label reads as
**Gospel** so that one thing on the page is called Scriptural. The app
once looked as though it held four Rosaries — Pray with a Meditation, the
Scriptural Rosary, the Rosary Aloud, and an "Every prayer aloud" switch
that quietly made a fourth of the first — each with its own door in a
different place.

## App Tabs

`AppTab` (in `Components/CustomTabBar.swift`) has six cases, but the bar shows
four — Progress is reached from the Chapel's flame tile, Settings → Devotion
and Explore's search instead, to keep the bar from crowding the raised Pray
button, and the Journal, which gave its place to Prayers, from the Chapel's
Reflections tile, Explore's search, and the completion screen's Write a
Reflection.

| Tab | In the bar | Purpose |
|-----|-----------|---------|
| Home | Yes | Search glass → Explore, today's mysteries, mystery grid, Today's Prayer, the reading shelf, quote |
| Consecrate | Yes | The 33-day preparation for Marian consecration |
| Prayers | Yes | The Prayer Book: Today, Occasions, All Prayers, and a search over them (see The Prayer Book below) |
| Journal | No — via Chapel | Reflections, searchable, stored on device |
| Progress | No — via Chapel | Streaks, prayer history, milestones ("Prayer Record") |
| Chapel | Yes | My Chapel — the user's arrangeable page (Settings and About live in the home masthead) |

The **Pray** button raised over the bar runs the user's chosen quick act
(today's Rosary by default), and **press-and-hold** opens a tray of their
chosen devotions (`PrayShortcutTray`).

**An unfinished Rosary is taken up, never begun again over.** The Pray
button's tap, its tray, and the Chapel's focus and Today rows continue a
Rosary of their act's form left off today where it stopped
(`InProgressPrayer.isContinued(by:)`: a meditation set of any mysteries
is Today's Rosary's, the chaplet's is Seven Sorrows', the Scriptural and
Holy Rosaries are their own). They once began another, and its first
save erased the place unasked. The tray's row says where ("Continue at
the Third Joyful Mystery"); the Chapel's focus says "You stopped at
the…" over CONTINUE THE ROSARY, and its Today row CONTINUE. "Today" is
the prayer day (see The Prayer Day): a Rosary left at half past eleven
is still taken up at half past twelve, and one left before the day
turned at four is not (Home's card still offers it until it expires),
and a Rosary of another form is left for Home's card. Every
door, Home's card included, resumes through `AppRouter.resume`; if a
meditation set cannot be loaded, the act begins as it always has.

The home header is the wordmark framed by the app's chrome:
**ph-faders → Settings** and **ph-info → About** together on the left,
the search glass alone on the right. No flame — the streak lives in the Chapel's own Prayer Streak
tile, which opens the Prayer Record (the whole tile is its door; Settings →
Devotion is the other standing door to the Progress page, and Explore's
search finds it as "Prayer Record"). The masthead is the **only** door
to Settings and About — not the Chapel's day strip, which reads the
liturgical day and carries only the journal's pencil, and not the Chapel's foot, which is the arrange
control and the imprint, nothing else.

**Today's Prayer** (`Components/TodaysPrayerSection.swift`) stands
between the Sacred Mysteries grid and the reading shelf: a section heading in the home page's own voice ("Today's Prayer" in
Cinzel 19, the date where the other sections keep their link), the Total Consecration first, under the section's name, then the feast as a subsection
of it — its name in small engraved capitals with a hairline beside it
running to the edge, the way a card names one of its parts — heading the Mass and
the Office. Set large in the reading italic, the feast read as a second
section title. The preparation
is the user's own devotion, kept whatever day it is, and no part of the
Church's calendar, so it stands apart from the feast and above it. Beside
it, and for the same reason, stands **the hour's prayers**: the Prayer
Book's order for the hour it is (Morning Prayers until eleven, the
Angelus until eight, Night Prayers after), its fact ON RISING · AT NOON
· AT SIX · BEFORE SLEEP, or OFFERED once prayed to its Amen — never
"missed"; it opens the Prayer Book, which opens on that same order.
Four ruled rows on the bare page — no card,
no panel, no fill. The Mass, the Divine Office,
the Total Consecration and the hour's prayers, given equal standing. It is named for the
user's prayer and **not** "Today in the Church", because the
consecration is a private devotion and not a liturgical observance;
`TodayInChurch` (the observable) still supplies the day and is shared
with the Chapel's day strip. Every row has the same parts — the door's
own glyph (`ch-altar`, `ph-clock`, `ch-consecration`, the hour's order's own, the same as on
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
empty track. True Devotion is reached from the reading shelf below, Explore and the Chapel's
Library tile, not from here.

The search glass pushes `AppRoute.explore`
(`Views/Home/ExploreView.swift`): at rest it browses — an epigraph
(Mt 7:7), the five devotions as painted banners, each opening its mysteries'
page, where the Rosary's three forms stand (the Scriptural Rosary and
the Rosary Aloud once had banners of their own beneath the five, as
though they were other devotions; typed search still finds both, and
opens the day's mysteries' page), and a quiet "New to the Rosary? · How to
Pray" door under that (How to Pray was the fourth item of The Study at
the foot of the page, where a newcomer never reached it); then the
Prayer Book, Sung Prayer (tonight's antiphon of Our Lady, played where
it stands, over the door to the Chant Library), The
Liturgy (Missal | Office), the Spiritual Reading shelf, and The Study's
ruled index — and typing searches mysteries, library doors, library readings,
chants, the Prayer Book's orders and prayers, and meditation sets at once
(a set by the label the shelf shows as well as the one the server
stores, so "gospel" finds the Scriptural sets). The set index is fetched quietly for search but deliberately
never listed on the browse page, and the field is deliberately not
auto-focused: the page is a place first, a search second. The real
search field lives on Explore, not on home.

**Pages push, tasks sheet.** Content destinations — the Missal, the
Office, True Devotion, Spiritual Reading (the shelf, its books, their
chapters), How to Pray, In Scripture, the Marian Library,
Carlo Acutis, the Chant Library and a chant's page, Settings, Explore — are `AppRoute` cases that slide in
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
the page): the mysteries' page and the Rosary's own page in its three forms
(`RosaryConfirmPage`: a set's, the Scriptural Rosary's, the Holy
Rosary's), the Guided Rosary, the Prayer Book's pray-along, and the prayer and completion
screens. A page may hide the bar only if it draws its own Back in every
branch. Not every push is an `AppRoute`: True Devotion's chapters are
closure `NavigationLink`s, the Office's hours a
`navigationDestination(item:)`, and the Missal's Ordo page a `navigationDestination(isPresented:)`.

A page that hides the system bar hides the back-swipe with it, so it
owes a way out from **every** branch it can draw, not just the loaded
one. A spinner or an "unavailable" message with no Back is a screen
only a force-quit leaves; both readers had one, and both now carry the
capsule in those branches too. Sheets are for tasks, trays and short
asides — the Pray tray, the editors, pickers, the journal editor, How
you'll pray, the calendars, reading options, a chant's score, and
About's three short texts; a destination with onward doors of its own
is pushed.
The tab bar lays its four labels out content-sized with even gaps (not
equal cells), padded clear of the raised Pray medallion.

> Journal is **not** blocked on the API. Entries are a local SwiftData model
> (`Models/JournalEntry.swift`); nothing is sent to the server.

### The Chapel Tab

The old Me/Account tab slot, rebuilt as **My Chapel**
(`Views/Chapel/MyChapelView.swift`, from the "My Chapel" design
handoff; its sections redrawn by the "Chapel Redesign" handoff, Oct
2026): a page the user arranges **in place** — no customize sheet.
Two ideas drive it: a single focus at the top (the first unoffered act
on the rule, set large with the page's one gold CTA, advancing on its
own as acts are offered — derived, never stored; the rule all offered,
it reads ALL PRAYED TODAY over "Thanks be to God", true at any hour,
where "Rest now" once sent someone who had prayed by half past six back
to bed), and an arrangeable
grid of sections below. Long-press 450ms anywhere (cancelled by >8pt of
movement) — on the page, on a tile that opens on a tap, or on the
quiet parts of a tile full of doors — the coach ribbon's "Show me" (one-time,
`userSettings.chapelCoached`), or the foot's ARRANGE THIS PAGE all
enter arrange mode, drawn from the Arrange board of the earlier
"Chapel Page Redesign" draft, since the Chapel Redesign draws none:
the page's head (the day strip, the focus and its gold act) crossfades
to a REARRANGE head with DONE — the page's one gold act while
arranging — over one line saying how ("Drag a section by its handle to
move it. Tap one to make it full or half." — in words, since the
fonts carry no ⠿), held at the top of the glass over the
page's deep ground, opaque behind every word and fading only in a band
beneath them, so a scrolled row never shows through the line (the scroll keeps its room, and drops the band's
32pt inset while arranging so the rows begin under the head, not fifty
points below it), since DONE is the only way out while the tab bar is
gone, and read first by VoiceOver; the page scrolls back to the top, and
every section folds to a 58pt row (`ChapelArrangeRow`: a grip, its
name, FULL in a capsule at full width or HALF under the name at half,
and a ✕ laid over its trailing edge above the carry gesture,
`ChapelHideButton`), so most of the page fits the glass and the rest
is a short scroll, begun anywhere: a row is carried by its grip alone,
at once (a 44pt hit area of its own, the full height of the row), and
the rest of the row answers only to a tap, so a swipe begun on a row
scrolls the list; the scroll stands still while a row is carried. The
whole row once carried at the first touch, and a swipe meant to scroll
moved a section to the top; then a hold anywhere on it carried it
(a 0.28s long press sequenced before a drag, laid beside the scroll),
and the scroll's pan never began from a row at all — a long press and
then a drag inside a ScrollView is not to be relied on, so it must not
come back. On a 6.1" phone the last rows of nine stand under the tray
until scrolled to. A mode's
drawing gives way to the other's at once while the arriving one fades
in (`MyChapelView.modeSwap`): a full tile and its row crossfading in
one slot held the tile's height until the fade had ended, and the page
then jumped. The tab bar yields to a tray of HIDDEN SECTIONS
(`ChapelTray`, chips in a `ChapelChipFlow`; `router.chapelArranging` is
how ContentView knows), whose measured height the page's foot keeps
clear of, however many sections it holds.
A row is carried (it lifts with a light tick, MOVING, 318 wide, level
with the column and following the finger up and down, leaning up to
±9° into the travel — centred on the finger, a row lifted by its grip
hung half off the glass; a dashed slot opens at the landing, LET GO TO
PLACE IT HERE),
tapped to switch between its section's **two authored layouts** (full
`span 2` / half `span 1` — each a different drawing, never the full
squeezed), or hidden; a chip is tapped back onto the page's end or
dragged to a place of its own. VoiceOver, which cannot drag, has each
row's moves as actions — Make half or full width, Move up, Move down,
Hide — and a chip's double-tap puts its section back. Nothing is
deleted: the tray always holds what's off the page, and a stowed flame
keeps counting. The tiles once swayed ±0.5° in arrange mode, wore a ✕
badge at their shell's corner, and were carried at full size down a
page three thousand points long; the folded rows replaced all three.
Reduce Motion drops the lifted row's lean and the slot's growth, and
the change of mode is a fade alone (`MyChapelView.modeChange`, and
`beginChapelArranging(reduceMotion:)`, which every hold passes): the
tiles do not fold nor the rows slide to their places, and the tray
fades in rather than rising.

Above the grid, fixed: a day strip (liturgical-colour diamond from the
missal vestment + weekday · feast via `TodayInChurch`) and the focus
block. The strip carries no app chrome — it reads the day, and the room
that buys is what lets a long feast set in full — with one exception at
its right: the journal's pencil, a 40pt gold-ringed circle answering to
44, which opens `JournalEntryEditorView(isMidPrayer: false)` as the
Journal does ("New reflection" to VoiceOver), under the sheet grammar's
header: the date over NEW REFLECTION (REFLECTION when one is edited,
DURING PRAYER over it from a mystery being prayed), CANCEL and SAVE
beside them, SAVE dimmed until something is written. With the Journal off the
tab bar, a new reflection needs a door that is always on the page, and
the Reflections tile can be put away; the Chapel is where reflections
are kept, and the Reflections tile still opens the whole journal
(`switchTo(.journal)`). Tiles (vocabulary `Models/ChapelTile.swift`;
layout persists as `userSettings.chapelLayout`, validated against known
ids on decode, with a one-time migration from the old `meWidgets`
order; a tile newer than a stored layout is inserted in its default
place, not appended; the redesign added, renamed and removed none, so
every stored layout reads as it did): **Today** (the rule as a string
of beads on a raised card lit from its corner — the page's only card
with a halo, since it is the working list and the picker itself; the
focus block above it carried a "CHOOSE ANOTHER" jump down to this tile
and no longer does, since the ledger is a scroll away on the same
page; one bead to an act on a gold thread, gold once prayed, the next
ringed and lit on a wash of gold with its name a size larger, the rest
an empty ring; every row shows at its trailing edge what a tap does —
PRAYED with the seal, BEGIN › / CONTINUE › until then, every act on
the rule being one the app watches finish (the row marked by hand went
out with the acts that needed it); the Rosary, the Scriptural Rosary,
the Rosary Said Aloud, the Seven Sorrows and the consecration day check from real
data, and the Prayer Book's three orders from their Amen
(`PrayerBookStore.wasOffered`), reset when the prayer day turns at four
in the morning (the consecration day by its own numbering, on the
calendar); "3 of 5 prayed" in the ruled foot; the half is a figure
"2 / 4" over a row of tappable cells; the tile once opened on an italic
line saying what a rule is, which the beads and their BEGIN now say),
**Consecration** (the preparation's own painting —
`ConsecrationPhase.heroImageName`, the one its day page opens on, chosen
in one place, `ChapelConsecrationTile.paintingName`, so a painting made
for the tile is a one-line change — run to the card's edges under a
scrim, the day as a figure "Day 14 / 33"
over the day's own title on its floor, CONTINUE beside it, and de
Montfort's four preparations as a segmented road along the floor,
tracks weighted 12/7/7/7 days; the half counts "14 / 33" over the
preparation's name; made, "Consecrated" with its date; not begun,
"Consecration to Mary" over the Annunciation), **Prayers**
(`ChapelPrayerBookTile`, the Prayer Book under the name its tab
carries: a leaf darkening down the card, the order for
the hour it is set large and centred with its one line, a door to the
book, over an outlined PRAY — outlined because the page's one filled
gold act is the focus block's — and the day's three hours ruled off
along the floor, each its bead (gold once prayed, ringed while it is
the hour's), its name — MORNING, NOON or EVENING, NIGHT, the Prayers
page's own stations (`PrayerBook.hourName`) — and where it stands —
"Prayed", "Now", or when it is said, never "missed" — and each a door
that prays its own order; the Angelus counts as prayed for the bell
being kept, as on the Prayers page (`PrayerBook.isOfferedNow`), so
one said at noon leaves EVENING to pray, where the Today tile counts
it once a day; the station it is rides the title line, turning on the
book's own schedule; the half is the hour's order over the three beads, each with
its hour's own glyph (`lv-rooster`, `lv-bell`, `lv-lamp`) in place of
its name, which had no room — MORNING and ANGELUS shrank to two sizes
beside NIGHT, and the Regina Cæli could not be set — and the whole tile
prays it; its line under the order is the Prayers page's own
sentence for the hour, `PrayerBook.daySummary(of:on:)`, which Pray Now
sets too, so the tile and the page never say what one order is in two
ways; the reader's ribbons stand under Saved on Prayers' Today, no
longer here), **Reading** (the open book standing on a shelf
with the author and the place beside it — "St. Thérèse · Chapter IV" —
and the other books under way standing as spines beside it: tap a
spine, or swipe the face, to bring that book forward; the tile is not
one door, because made one, every spine opened the book in front of it
and the rest could not be reached; "2 more books started" rides the title
line; the half stands the book over its title; empty, the books'
cloths over "Take up and read · choose a book" and ALL BOOKS; no bar of the book read — the board drew
one, and a share of a book is a judgement of the reader the shelf
never makes), **Today in the Church** ("The Church" at half, where
the whole name has no room; on the deep ground, the date on a
calendar leaf beside the feast with its rank — "Lesser Feast"
(`rankLabel`), the vestment's diamond before it, the colour said to
VoiceOver alone (`TodayInChurch.spokenMeta`, "Lesser Feast, white
vestments") — over a ledger of the Church's two books for the
day: THE MASS, Today's Mass over the first words of the day's entrance
chant ("Entrance chant: Gaudeámus omnes"), in Latin, read from the
missal's proper — no more than
three, and never ending on a word that leaves it hanging
(`TodayInChurch.incipit(of:)`, "Gaudeámus omnes", not "Gaudeámus omnes
in"; `appTests/ChapelLiturgyTests.swift`) — and HOURS OF PRAYER by
the hour it is now in plain words over its Church name
(`CanonicalHour.plainName` over `label`: "Evening Prayer" over
"Vespers, the hour now"), from `CanonicalClock` — the
board said the next
hour, but the Office opens on the present one; until the propers are
known the leaf names "The Mass of the Day" and the Mass row "Prayers
and readings for today"; no bare "1962" stands on the title line; the
page loads the day again when it comes back to the
foreground, refreshing `CanonicalClock` first as every page that shows
the hour must, and at every turn of the canonical hour, midnight included,
and `TodayInChurch` lets go of the last day's feast before it looks for
the new one's, and sets no feast fetched for a day that has ended while
it was asked, so a Chapel left open overnight — even offline — never
sets today's date beside yesterday's feast; split out of the Library so one heading is true of everything
beneath it; a layout saved before it existed seats it beside the
Library, at the Library's width, and on the page only if the Library
is — `ChapelPlacement.completing`, which the Me migration shares; the
half is the date and the feast over two doors), **Library** (bound
like a book, a second rule inside its edge: BOOKS — True Devotion,
Spiritual Reading, the Marian Library — and GUIDES — How to Pray, In
Scripture, Carlo Acutis — as a ruled index of doors, each name over a
line saying what it holds, with no glyphs, over Augustine's line; the
half keeps the three books and makes SEE MORE a door to Explore),
**Chant** (the Chant Library's player on cloth: the chant it last sang,
or tonight's song to Mary until it has sung one, which the title
line says — its disc plays it ("Play Hail, Holy Queen (Salve Regina)"
to VoiceOver), its name, the Latin over the English and the setting
as the library sets one mid-line (`Chant.settingMidLine`, "Hail, Holy
Queen · simple melody"), opens the chant's page, and BROWSE CHANTS (BROWSE at half) opens the
library; beneath, a staff of
square notes in one fixed contour, the same for every chant and never
lit by the voice — the app holds no pitches, so it is a picture of
chant and must never pass for this chant's melody, whose score is a tap
away — with a gold playhead, the only thing on it that moves; the staff
is a view of its own that reads the player, so the player's ticks
redraw it and not the tile. The elapsed time is said nowhere on screen
but by the playhead, at both widths, and to VoiceOver on the staff, as
words ("Sung so far, 1 minute 5 seconds of 3 minutes 20 seconds"); the
clock once rode the title line and redrew the whole tile every second),
**Reflections**
(on the quote ground, the latest journal entry in the upright medium
face under an illuminated versal, or its gilded opening mark when it
opens on a quotation (`VersalCut.opensOnQuotation`: a lone apostrophe,
'Tis, is no quotation), or beside a rule of gold fading down when it
opens on no letter; a passage kept from a book is quoted without its
citation, and any other entry is the journal's `previewText`, newlines
flattened; when it was written rides the title line — "Today",
"Yesterday", the weekday through the week, then the date, turning at
midnight while the page is open (the tile reads `CanonicalClock`, whose
Matins begins at midnight, since the journal's day is the calendar's) — and OPEN
THE JOURNAL the foot; at half the day is the foot's note), **Prayer
Streak** (the flame as an ember in the dark; stands directly under
Today, because a record of days prayed belongs beside the day it
records and onboarding's closing line promises it is being kept; the
title line says "Prayed today" or "Not yet today", never "missed", and the
ember burns quieter until the day is lit; the figure reads "12 days in
a row" beside the ember, over the next milestone as an invitation, and
the week is drawn beneath as a small Sunday-to-Saturday calendar, each
day's initial over its bead and today ringed — "This week" under the
figure with bare dots beside it once read as one confused count; the
half centres the ember over "12 days" with the week as seven beads on
its floor — the one centred half; the whole tile opens the Prayer Record
at both widths, and has no foot. To VoiceOver it is one sentence in the
screen's words — "12 days in a row, not yet today. This week, prayed
Sunday, Monday and Tuesday. Next, 54 days, a Rosary novena, 1 day
away. Opens the Prayer Record." — the days prayed by name, never a count out of seven, which
read midweek as a shortfall).

**Each section its own object** (the "Chapel Redesign" handoff,
`ChapelTileFrame` in `Views/Chapel/ChapelTiles.swift`): a card at a
16pt corner cut from the section's own ground (`ChapelSurface`) — the
rule lit on `cardElevated`, the flame's ember on `backgroundDeep`, the
consecration's painting, the Prayers tile's leaf from `cardElevated`
down to `backgroundDeep`, the shelf and the chant on `cardBackground`,
the journal on `quoteBackground`, the liturgy on `backgroundDeep`, the
library on `cardBackground` with an inset rule — and an
`AppLine.hairline` edge at the ground's own strength (`gold@0.18`
on the deep liturgy to `gold@0.42` on the lit rule). The tile names
itself on its own first line, inside the card: the name in Cinzel at 17
(15 at half) in cream, an italic note at 13.5 on the right, or the
rule's EDIT (`onEdit`, the list's edit control where a list's is looked
for; as a foot act it read as one more BEGIN row). Padding 18/18/6 at
full and 16/14/4 at half; then the body; then what the tile pins to
its floor (`floor`: the week under the flame, the hours under the
Prayer Book, the road under the consecration's day, the liturgy's
doors), after a Spacer; then the foot, ruled off at `gold@0.16` unless
the body ends on a line of its own (the reading shelf) — full: an
italic note at 13 left, the gold text act right (`labelFont 10`,
tracking 2, caret 9, 44pt tall); half: the act alone, left-aligned, or
the note where the tile has no act (the Reflections half, whose whole
card opens the journal through `switchTo(.journal)`). The
grid's rows **stretch** (`ChapelGridLayout` gives every tile in a row
the row's height, and the card fills it), so two halves always end on
the same line and share their first; two full rows stand 20 apart, a
row of halves 18 from its neighbours (`ChapelGridLayout.halfRowGap`), and
a pair of halves 12 apart; 10 every way while arranged. The card is one door (`onTap` — a tap
and a hold as two gestures rather than a Button, so a hold that
arranges the page never also opens the tile on release) except where
the body has doors of its own — the Today rows and cells, the Reading
tile's face and spines, Today in the Church's rows, the Library's doors, the
chant's play disc and name, the Prayers tile's order, PRAY and hours at
full width — where only the foot's act, if any, is a control
(`onAct`). A card that is one door keeps its title's heading trait,
so VoiceOver's rotor still walks the page section by section; the
consecration reads "Consecration to Mary, day 14 of 33, Humble
Subjection. Continue." The Library's half ends on SEE MORE, a door to Explore,
where the three guides it leaves out stand. The page before this drew one anatomy for every tile (the
"Chapel Tiles" handoff): a kicker with a glyph on the page above a
hairline shell with no fill, and the rule "no filled card surfaces on
the page"; any tile sat well beside any other, and none could be told
apart at a glance. The redesign deliberately replaces that anatomy and
that rule. Filled surfaces are allowed on the Chapel in exactly these
places: each tile's own card, on the ground its `ChapelSurface` names;
the folded rows, the lifted row and the landing slot of arrange mode;
the hidden-sections tray and its chips; and the chant's play disc. The
page itself — the day strip, the focus block, the foot — stands on the
bare page gradient, and kickers above the card must not come back. Only the rule's card wears a halo; the chant keeps
the Chant Library's own disc (`ChantPlayDisc`, dark with a gold rim)
rather than the board's gold one, since the page's one filled gold act
is the focus block's, as the Prayers tile's PRAY is outlined. Halves
lead with a figure or a headline, left-aligned — but the streak's,
centred under its ember as drawn. The foot of the page is ARRANGE THIS
PAGE in an outlined capsule — the 2×2 arrange mark, not the board's
faders, which are Settings' door — over "Or press and hold anywhere."
and the imprint, which the board leaves off and the page keeps. The
default order is Today, Streak, Consecration, Prayers, Reading,
Chant, Reflections, Today in the Church, Library: the live sections lead, and the
two indexes of doors stand last, the Library's colophon the right last
line before the foot. The day strip wraps a long feast to a second
line rather than cutting it mid-word.

**The Chapel's words** (the plain-language rulings, Oct 2026): what
the code calls the rule the reader sees as **daily prayers** ("Daily
Prayers" in the editor and Settings, whose lead says once that the
saints called it a rule of prayer); a finished act is **PRAYED**, never
OFFERED ("3 of 5 prayed", "Prayed today"; "offer" stays only where it
means offering to God, as in the Morning Offering); the streak's figure
is "N days in a row", "1 day so far", or "Pray today to begin", and a
milestone leads with its number ("9 days · a novena",
`StreakMilestone.title`; the completion card sets `name`, "9 days",
over a blessing that says what the Church calls it). The forms are
named as everywhere else — the Rosary Said Aloud, the Seven Sorrows of
Mary, Consecration to Mary, Queen of Heaven (Regina Cæli) in
Eastertide — and the focus block's gold act names the prayer without
repeating the title over it (the three forms' act is PRAY THE ROSARY
or CONTINUE THE ROSARY, the consecration's OPEN DAY 14), so every act
fits its button on one line at `.xLarge`. Words another area owns are
read from it, never written again here: the hours' plain names
(`CanonicalHour.plainName`), the rank (`rankLabel`), the vestment
(`MissalVestment.plainName`) and the day (`TodayInChurch`) are the
liturgy's; when each of the book's three orders is said
(`PrayerOrder.occasion`), the season's song to Mary
(`MarianAntiphon.name`) and the Angelus's Eastertide name
(`PrayerOrder.title(on:)`, which the Pray tray and the rule read
through `PrayerShortcut.angelusTitle`) are the Prayers page's; a
chant's setting mid-line (`Chant.settingMidLine`) is the library's. The journal's things
are reflections, never entries; a new one's title starts empty under
"Title (optional)", and one with no title reads "Reflection". The
words "Arrange" and "Rearrange" stay.

**The rule's vocabulary** (`PrayerShortcut.isRuleEligible`): the
Rosary, the Scriptural Rosary, the Rosary Said Aloud and the Seven
Sorrows of Mary can be chosen, and the Prayer Book's three orders of the day — Morning Prayers,
the Angelus, Night Prayers — which the pray-along screen marks offered
at their Amen (`PrayerBookStore.wasOffered`), so the Chapel can ask
about them honestly. The Holy Rosary is still recorded under its old
name, "The Rosary Aloud" (`ScripturalRosaryViewModel.aloudDevotionName`),
since the Prayer Record holds days prayed under it and the rule matches
by it. "A
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
never seen, and merging Today in the Church into Library at half width is a
different page from the one drawn.

The rule's *membership* is edited in `RuleEditorSheet` (Settings →
Devotion → Daily Prayers, and the EDIT on the Today tile's title line);
`PrayButtonEditorSheet` (quick tap + hold menu) still opens from the
Pray tray's "Edit this menu" row. The one-motion acts remain
`PrayerShortcut`. Prayer Record's standing doors are the flame tile and
Settings → Devotion (Explore's search also finds it). The old Me page
(`MeView`, `MeWidgets`, `MePageEditorSheet`) and `Components/MenuView.swift`
were retired in `9be67c6`, with the Me-only API they kept alive
(`isRuleChecked`/`setRuleChecked`). What outlived them is live:
`Views/Me/` holds the rule editor (`MeCustomizeSheet.swift`, still named
for the page), `PrayButtonEditorSheet` and `PrayShortcutTray`, and
`MeWidget` is kept only for the Chapel's one-time migration. The old
page's reference is git (`ed21006^`); research behind the original design: "The
Oratory Brief" artifact.

### Settings & About Screens

Split in two, each behind its own glyph in the home masthead, so the
informational pages are never the settings page's attic:

**`AccountView`** (`AppRoute.settings`, the home masthead's **ph-faders**) — the
app-wide toggles and choices (the readers keep their own — the Missal's
and the Office's Aa sheets, the reading goal on a book's page), set in
the Chapel's own voice: a Cinzel plate
("Settings / Choose how the app looks, sounds and reminds you."), then
outlined sections with
glyph-led kickers (`AccountSection` — no filled card surfaces, same as
the page they serve):

- **Appearance** — theme (re-themes live). An **App Icon** section (the
  primary + three alternates) is built but switched off
  (`AppIconPickerRows.isEnabled = false`), and `appApp` puts any
  alternate back to the primary at launch until it returns.
- **Prayer Experience** — text size, prayer language (English by
  default; the app's first face is the one most users read), the
  narration voice (`NarrationVoiceRow`, the server's list; the same
  choice stands in the player's playback sheet), then Audio and
  Counting — the Rosary's two choices, each a pill of its two named options
  over a line saying what the chosen one does
  (`RosaryChoiceSettingsRow`, the same pill as a Rosary's own page). They
  keep the rows the Bead counter and Pray aloud switches stood in; a
  switch could say only on or off, not which of two ways. Audio comes
  first, as on the Rosary's own page, since it decides whether Counting
  is offered at all; Counting once came first, in the switches' order.
  Counting stands dimmed under the Whole Rosary, saying why: the voice
  moves the beads on the screen then. Beneath them stands the
  **Prayers** row (the Prayer Book's, named as its tab is), In Silence |
  Aloud, in the same row and pill
  (`PrayerBookAudio`), which sets `PrayerBookStore.praysAloud`. It is
  kept apart from Audio on purpose: the Rosary's choice decides whether
  the voice leads every prayer or reads the meditation alone, the
  book's whether it speaks at all. Until the reader answers, the pill
  shows the default, Aloud, and its line says the book will ask.
  Drawing the row answers nothing; a tap on either segment does, the lit
  one too
- **After the Rosary** — the prayers after the Rosary (For the Pope's
  intentions, Memorare, Saint Michael), under their own heading and the Voice & speed sheet's
  note: they are said aloud after the closing prayer, and only when
  every prayer is — nothing else reads them. Set as three more switches
  among the ways of praying, they read as prayers added to every
  Rosary, and a silent Rosary never said them
- **Devotion** — Daily Prayers (→ `RuleEditorSheet`), Prayer Record,
  Daily Mysteries (Traditional | Modern → `MysteryScheduleSheet`, the row
  under Daily Prayers), Daily Reminders (toggle, time, sound), The Angelus Bell, What Brings
  You to the Rosary (decides the reminder copy pool)
- **Offline** — download every meditation set and audio file

**`AboutView`** (`AppRoute.about`, the home masthead's **ph-info**) — the app's
colophon: the wordmark as masthead, then About Lumen Viae, Privacy
Policy, Help & Support, Send Feedback, and the footer (version, "For
the greater glory of God", the Ad Majorem Dei Gloriam in English). **App Introduction** — which re-runs onboarding —
stands above Privacy Policy behind `#if DEBUG`: it is for development,
since a reader has seen the introduction and needs no door back to it.
It runs in a **`fullScreenCover`**, never a sheet; onboarding is the
app's first face, and a sheet's inset top, rounded rim and drag-away
made the re-run a panel over the settings instead of the screen a new
reader meets. The sheets
it presents still live in AccountView.swift (the feedback form in FeedbackView.swift) alongside the shared row
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
│   ├── RosaryForm            # + RosaryChoice, RosaryInfoRow — one Rosary in three forms
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
│   ├── PrayerShortcut                       # + MeWidget (read only by the Chapel's migration)
│   ├── PrayerBook            # BookPrayer, chapters, orders of prayer, seasons
│   ├── PrayerDay             # The prayer day, turning at four: what counts as today for everything prayed
│   ├── Chant                 # Chant, ChantScorePart, ChantGroup, ChantCatalog
│   ├── ChantScoreDrawing     # A score's drawing, read from .lvscore; SVG path data
│   └── StreakMilestone, MarianFeastDay, BilingualConsecrationPrayer
├── ViewModels/               # @Observable
│   ├── HomeViewModel, MeditationSelectionViewModel, MeditationSetDetailViewModel
│   ├── PrayerSessionViewModel, ScripturalRosaryViewModel, ConsecrationViewModel
│   ├── MissalViewModel, OfficeViewModel
│   └── TrueDevotionReaderViewModel
├── Views/
│   ├── Home/ Prayer/ Journal/ Progress/ Account/
│   ├── Scriptural/           # ScripturalRosaryView (the Scriptural and Holy Rosaries' page),
│   │                         # ScripturalRosaryPrayerView (the prayer)
│   ├── Chapel/               # MyChapelView (the tab), ChapelGrid (arrange
│   │                         # machinery), ChapelTiles, ChapelPrayerBookTile
│   ├── Chant/                # ChantLibraryView, ChantView (a chant's page),
│   │                         # ChantScoreSheet, ChantComponents
│   ├── Me/                   # What outlived the retired Me page: MeCustomizeSheet's
│   │                         # RuleEditorSheet + editor furniture,
│   │                         # PrayButtonEditorSheet, PrayShortcutTray
│   ├── Meditation/           # SelectMeditationView (the mysteries' page), MeditationSetDetailView,
│   │                         # RosaryConfirmPage (the Rosary's own page:
│   │                         # YOUR ROSARY TODAY, the choices, the rows),
│   │                         # BeadSwitch (+ SetupTogglePill)
│   ├── Consecration/         # 33-day preparation (own NavigationStack)
│   ├── TrueDevotionView      # True Devotion's title page (at the Views/ root)
│   ├── TrueDevotion/         # Its contents page and chapter reader
│   ├── Library/              # Spiritual Reading shelf, book page, chapter
│   │                         # reader, contents sheet, transport
│   ├── PrayerBook/           # The Prayer Book: Prayers (the tab's page,
│   │                         # + PrayersComponents, PrayerBookPaintings),
│   │                         # chapter, order page, prayer page,
│   │                         # pray-along, learn by heart
│   ├── Resources/            # How to Pray (+ RosaryLessonView, GuidedRosaryView),
│   │                         # Marian Library, In Scripture, Carlo Acutis,
│   │                         # LibraryReadingView, the Missal and the Office
│   │                         # (+ LiturgicalMonthGrid, the month grid both
│   │                         # calendars draw)
│   ├── Onboarding/           # 9-slide first run (8 said aloud) + RosaryMethodsView
│   ├── WhatsNew/ FirstUseTour/ # the two first looks, once each
│   └── Launch/
├── Components/               # CustomTabBar, HeaderView, MysteryCard, QuoteSection,
│                             # MeditationSetTile (+Row), StreakWidget,
│                             # TodaysPrayerSection + TodayInChurch, SetArtworkView,
│                             # BookCover, QuotedPassageText, PrayerPainting(Stage)
│                             # (the player's ground), RosaryStrandView,
│                             # BeadStatusRow (the reader's), RosaryDiagram,
│                             # PendantCrossView, OrdoMasthead
├── DesignSystem/             # Theme, Typography, AppIcon, Motion,
│                             # CallToAction (GoldCTAButton, QuietGoldButton,
│                             # PrayFootScrim + PrayFootGround, the Prayer
│                             # Book's), SheetChrome, FocalFill,
│                             # FixedColors (the colours a thing wears),
│                             # SacredComponents (OrnamentDivider, DropCapText…),
│                             # ReadingText (ReadingTypography, ReadingText, PrayerText)
├── Data/                     # Bundled content, not code-adjacent constants
│   ├── ConsecrationData, BilingualConsecrationPrayers, BilingualPrayer
│   ├── MysteryData, LuminousMeditationData, TrueDevotionData/Prayers
│   ├── ScripturalRosaryData  # GENERATED by Tools/ScripturalRosary — 249 Douay verses
│   ├── ChantCatalogData      # GENERATED by Tools/Chants — the 76 chants
│   ├── LibraryCatalog        # Spiritual Reading shelf: sources + cutting rules
│   ├── MissalOrderData       # The Mass's sections: names, postures, tiers, day rules
│   ├── ReminderMessages      # Notification copy pools
│   ├── RosaryQuotes          # Daily quotation catalog
│   ├── RosaryPrayers         # The Rosary's prayers + DevotionPrayers lookup
│   ├── PrayerBook/           # The Prayer Book's texts (PrayerBookTexts), by chapter
│   └── MarianLibraryData, CarloAcutisData, HowToPrayData,
│       MysteriesInScriptureData   # The resource pages' content
├── Services/
│   ├── APIService            # HTTP client (https://lumenviae.fly.dev/api)
│   ├── AudioService          # Narration and chant playback
│   ├── AudioClaim            # Who holds the player: one claim at a time
│   ├── ChantPlayer           # The Chant Library's hold on it, above the views
│   ├── SpokenRosaryPlayer    # The whole Rosary said aloud, above AudioService
│   ├── RosaryAudioPack       # The spoken Rosary's recordings, fetched and kept
│   ├── PrayerBookStore       # Ribbons, by heart, orders offered, aloud, the Angelus bell
│   ├── PrayerBookAudio       # PrayAlongVoice (the book said aloud), AngelusBellSound
│   ├── OfflineContentService # Full offline download of text + audio
│   ├── NarrationVoiceCatalog # The server's voices, kept in UserDefaults
│   ├── MeditationCacheService, ImageCacheService, ArtworkCache
│   ├── MissalAPIService, MissalCacheService   # Missale Meum, cached on disk
│   ├── OfficeAPIService, OfficeCacheService   # Our /office API, cached on disk
│   ├── CanonicalClock        # Which canonical hour it is now
│   ├── PrayerDayClock        # Today's prayer day, rolling over at four, for the pages that show it
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
                              # Tools/TrueDevotion), the four reminder sounds,
                              # Chants/ (GENERATED by Tools/Chants: <id>.m4a
                              # and Scores/<name>.lvscore)
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
  the artwork cache all do, and so does a chant score's read from disk).
- SwiftUI may read a `Layout`, a `LayoutValueKey`, or a value
  `onGeometryChange` measures off the main actor, so those types are marked
  `nonisolated` (`ChapelGridLayout`, `ChapelSpanKey`, `ChapelChipFlow`, the Prayer Book's
  `WordFlow`, onboarding's `WordsExtent`; the meditation shelf's
  `ChipFlowLayout` still lacks it);
  under default MainActor isolation a new one needs the same, and the
  Swift 5 mode below won't insist on it.
- The target is still in the **Swift 5 language mode** (`SWIFT_VERSION =
  5.0`, no `SWIFT_STRICT_CONCURRENCY`), so most data races are not
  diagnosed; don't read a clean build as proof of safety.

## Feature Status

### Built

- **Core prayer flow** — day-based mysteries, the mysteries' page (the
  Rosary's other two forms over the meditation sets: gallery or list, a
  filter tray of API labels, pinned sets on top), the Rosary's own page
  before prayer, decade-by-decade prayer screen with bead tracking,
  completion screen, and a resume card for an unfinished Rosary.

  **The bead is the unit** (the "Bead-First Rosary Prayer Flow" handoff).
  The whole Rosary hangs as one strand at the right edge of the player
  (`RosaryStrandView`, hung by `.rosaryStrand(_:)` at the same place on
  both players): prayed beads run off below the hand, the bead under the
  hand rests at the window's middle, and the beads to come descend from
  above, Our Father beads larger and carrying their number (1 to 5,
  1 to 7 in the chaplet; they were Roman numerals) so the next
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
  rolling as one fixed view while the rows slide beneath it, and
  growing no larger than `xLarge`, since the window is a fixed 150
  points and clips — at the app's `xxLarge` THE MEDITATION lost its T),
  and the Our Father beads carry only their numeral — the words "OUR FATHER"
  beside every one of them ran a hundred points into whatever stood to
  the strand's left. The player's foot — title, transport, utility row —
  changes nothing from bead to bead: a `BeadStatusRow` once stood there
  above the transport and re-wrapped its cue on every swipe, shoving the
  controls, and now the row is the reader's alone, which has no strand.
  **The beads unlock once the meditation has been heard.** The strand
  always hangs at the edge, but on a mystery's Our Father it is greyed,
  still and locked — a small drawn lock on the bead under the hand, and
  SWIPE AFTER / THE MEDITATION in place of the bead's name
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
  is offered — Counting, On My Rosary or On the Screen: on a Rosary's
  own page, in the playback sheet and in Settings from
  `RosaryChoice.counting`, and in onboarding's "Where Will You Count?"
  from its own copy of the same words; it had three names ("Pray on the
  Beads", "Bead counter" and the pill's ON THE BEADS) and none said what
  would appear. It is offered
  only while the voice reads the meditation alone: with the Whole Rosary
  the voice moves the beads on the screen whatever Counting says
  (`RosaryForm.countsOnScreen`, which both players read), so a counter
  switched off earlier cannot take the strand from a Rosary said aloud,
  where nothing would be left to change it back. When the voice cannot
  begin (`spokenFailure`: no recordings to be had, offline), the
  meditation's player counts as Counting says again (`aloud: prayAloud
  && viewModel.spokenFailure == nil`): the meditation is heard in its
  own narration, and a Rosary counted on one's own rosary is not handed a
  strand locked at every Our Father that no voice will move.
  `ToggleRow` answers a tap anywhere on the row, not only on its
  switch. The one-time `PrayerSwipeHint` ("Swipe down for the next
  bead") waits for the beads to unlock and for the voice to let go of
  the hand (`voiceHoldsHand`) — said aloud the beads count as unlocked
  from the first word, and the one showing was spent over the Sign of the
  Cross, across the pendant's foot, where a swipe does nothing — floating
  over the painting above
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

  **The beads are optional on both players** (`userSettings.prayOnBeads`,
  on by default: Counting, On the Screen).

  **The two choices that change the prayer are shown before PRAY; the
  rest are rows.** Every form of the Rosary is confirmed on one page
  (`RosaryConfirmPage`, the "Rosary ways to pray" handoff): the painting
  dissolving into the page, the name, then YOUR ROSARY TODAY — Audio
  (Meditation Only | Whole Rosary; Read in Silence in the Scriptural
  Rosary) and, while the voice reads the meditation alone, Counting (On My
  Rosary | On the Screen), each a pill of two named options
  (`RosaryChoicePill`, a segmented picker to VoiceOver) with a line
  beneath saying what the chosen one does, and under them ruled rows for
  what else is set: Mysteries (not for a set, which belongs to its
  mysteries; "Joyful · today", to a sheet of the five sets and the
  chaplet, where a tap chooses and closes) and Voice & speed ("Male · 1×",
  to a sheet holding the voice, the speed and, but for the chaplet, the
  prayers after the Rosary). The Scriptural Rosary read in silence has
  no Voice & speed row (`RosaryInfoRow.rows(for:aloud:)`): nothing is
  spoken, and the prayers after the Rosary are said only aloud. It comes
  back with the Whole Rosary. A set's page keeps the row in either mode,
  since its meditation is always read aloud, and so does the Rosary
  Said Aloud's. The Rosary Said Aloud offers no choice: its audio
  is a plain row, "Whole Rosary · pause anytime". The words for every
  option and note are `RosaryChoice`'s, read by the pages, Settings and
  the playback sheet; onboarding sets the same names and notes from its
  own copy (`OnboardingView`, the notes joined by a semicolon), so change
  the two together.

  This reverses a recorded decision. The choices once stood behind one
  quiet line — HOW YOU'LL PRAY over "Female voice · 1× · Every prayer
  aloud · On the beads" and a caret to a sheet — because open on the page
  they had been a filled card of capsules and switches, three of them
  gold, and the title page read as a settings form; the rule was "keep
  them in the sheet". What changed is how few there are: two choices,
  each a single pill, the rest in rows. The two change what praying is
  like, so they are seen where they apply rather than found after PRAY.
  What holds now is the reverse: the two choices stand on the page,
  everything else stays a row. A choice made here is the setting itself,
  and carries to the next Rosary and to every other place it is offered.

  A choice's arrival and departure are timed apart
  (`RosaryChoiceGroup.comingAndGoing`): Counting, leaving, is gone before
  the rows beneath close over its place, and arriving waits for them to
  make room; the Scriptural Rosary's Voice & speed row comes and goes on
  the same timing. As one plain fade on the rows' own 0.25s the rows slid
  through it while it was still half there. The pill itself passes its lit
  segment on `Motion.choice` (`ease(0.25)`, the design system's ease-out),
  with no spring, and a segment presses with `SacredCardButtonStyle`, a
  row's settle: as a bare glyph (`QuietGlyphButtonStyle`) half the pill
  dipped to 0.9 and faded, and read as a jolt under the thumb.

  A set's page puts its subtitle under the name only when its description
  opens on a sentence short enough to stand there
  (`MeditationSetDetailViewModel.subtitle(from:)` — its own splitter, since
  the system's sentence tokenizer ends sentences at "St." and "Fulton J.");
  the descriptions run to six lines, and six there pushed the choices
  under PRAY. The full description stands in the ledger below, unless the
  subtitle said all of it. The page's pin went with the design: sets are
  pinned on the shelf's tiles and rows. PRAY's foot turns solid faster
  than `PrayFootScrim`, the long scrim these pages once stood on, which
  now stands only in the Prayer Book's `PrayFootGround`: the ledger
  scrolls under this foot, and at that scrim's pace its lines read
  through beneath the button.

  The player's playback sheet (the faders) holds the same two choices
  beneath the voice and the speed, in the same order and words. At the
  accessibility text sizes it opens the whole glass high and scrolls
  (`PlaybackSettingsSheet.detents(for:)`) — at 530 points its rows stood
  crushed, one switch's name over the other's — and the voice capsules
  and the speed stop growing at `accessibility1` and shrink their words
  a little rather than cut "0.75×" to "0….".

  Counted on one's own rosary, the meditation's player is the
  decade-at-a-time screen it was for a hand that keeps its own count:
  the mystery strand in the header, arrows flanking the transport (→
  becomes the AMEN check on the last mystery), a horizontal swipe
  between mysteries (live in the reader too, which has no arrows), the
  one-time `PrayerSwipeHint`, and no strand or bead row. The bead never
  moves there, so the last bead, which brings back controls put away,
  never comes: they come back by themselves at the last mystery, where
  AMEN waits (on the Scriptural Rosary's screen too). The Scriptural
  Rosary is counted by hand too (below). Resume keeps `(mysteryIndex, beadIndex)`
  (`InProgressPrayer.beadIndex`, optional for older snapshots), once a
  bead or a decade has moved; counted by hand no bead moves on the first
  mystery to say the Rosary has begun, so it is kept for Home's card
  once it has been prayed a minute
  (`PrayerResumeService.firstMysteryBegunAfter`, which the Scriptural
  Rosary shares), and again when the phone locks or the Rosary is left
  after that. Opened and backed out of, it pins nothing, as on the beads.
  Said aloud the voice moves the beads on the screen, so this never
  applies while the voice holds the hand. It once could not be taken up
  again before the second mystery.
  The painting, its frost and its scrim are `PrayerPaintingStage`,
  shared with the Scriptural Rosary, which uses its `.veiled` style.
  A tap on the painting — or on the pendant, while the opening and
  closing prayers are said — puts the controls away and brings them
  back (on the meditation's player the pendant's tap, like the
  painting's, puts the one-time swipe hint away with them). To VoiceOver
  each is one button (`StageTapAccessibility`) whose double-tap runs that
  same tap: left to fall at the element's centre, it landed mid-glass,
  where the Scriptural Rosary's column moves the bead and the pendant's
  steps the prayer. The pendant's label says where the voice is on it
  ("The cross and first beads. The large bead"; the centrepiece is "The
  medal", since a newcomer knows neither "pendant" nor "centrepiece").
- **Audio** — narration for meditations, and chant from the Chant
  Library (below).

  **Narration comes in voices.** Each meditation carries `narrations`
  (`[Narration]`: a voice slug and a presigned URL, the server's default
  first) beside the legacy `audio_url`, which is the default voice's
  URL. The voices themselves come from `GET /api/voices`
  (`NarrationVoiceCatalog`, refreshed on foreground and kept in
  UserDefaults, with the built-in pair as the first-launch list), and
  the choice is `UserSettings.narrationVoiceSlug`, resolved through the
  catalog: a retired voice with a successor moves to it when the settings
  load (`NarrationVoice.successors`, the original male voice to Frederick),
  and only a withdrawn voice with none falls back to the default. The player
  reads the chosen voice at every load (`PrayerSessionViewModel.
  audioSource`), plays the meditation's default when it lacks the
  chosen one, refreshes links with `?voice=`, and reloads the mystery
  under the hand when the choice changes mid-Rosary. Offline files are
  `meditation_<id>_<voice>.mp3`; the library download saves one voice
  (the chosen one) per meditation, and a copy in another voice is
  played before silence when no link will.

  **Who holds the player is a claim** (`Services/AudioClaim.swift`).
  Every flow sounds through the one `AudioService`, and each used to
  decide for itself whether the player was still its own — from the file
  it loaded, the load generation it loaded under, and whether it held the
  Lock Screen arrows — and was never told when it had been displaced. A
  flow now asks `AudioService.claim(_:rate:ifIdle:onRevoked:)` for the
  player. One claim holds it at a time: a new claim, or an older flow's
  `loadAudio` or `setTrackNavigation`, ends the one before with notice
  (`onRevoked`), and a claim takes off the arrows an older flow left,
  which is how that flow learns it has lost the player
  (`isTrackNavigationOwner`). The flow loads, plays, seeks and reads
  through its claim, and once the item in the player is not the one it
  loaded (`holdsItem`) every act is a no-op and every readout is at rest,
  so no surface narrates or drives someone else's audio; two claims that
  load the same recording are two loads, the second from its top. A load
  whose claim ends while the recording is still arriving drops it rather
  than leave it in the player for nobody. A speed the claim borrowed
  (`AudioRatePolicy.borrowed`) comes back however the claim ends, unless
  another flow has borrowed one since. `ifIdle` declines while the
  player is in use (`AudioService.isInUse`): something playing, or a
  recording a phone call has stopped, which the player takes up again
  when the call ends. A recording paused by hand, still loading, or heard
  to its end counts as idle. Counted as idle through a call, a chant the
  library was singing was taken by a consecration day opened meanwhile,
  and never came back. The end of an item, or its failure, is
  told to the claim whose load put it in the player (`onFinish`,
  `onFail`), and only while that claim still holds it — told to whoever
  held the arrows, a chant's end once reached a flow that had taken them
  without loading anything. `release()` stops the claim's own item, or
  puts away the empty player its own `unload` left between steps, and
  gives the audio session back; a claim already ended releases nothing.
  Kept for the item alone, every consecration day whose chant was heard
  ended on a reading with the Veni Creator still on the Lock Screen over
  nothing, and the session held. The Chant Library and the consecration
  day hold claims. The prayer flow, the spoken Rosary, the reading shelf
  and the Prayer Book still use the older surface — owner tokens for the
  arrows (`setTrackNavigation(owner:)`),
  `setPlaybackRate(_:remember:borrower:)`, `currentURL` and
  `loadGeneration` — which keeps working beside claims until each moves.
  `appTests/AudioClaimTests.swift` covers how claims are given, ended
  and released, and the seam with the older surface, on a service of its
  own that keeps off the Lock Screen and the audio session
  (`AudioService(integratesWithSystem: false, defaults:)`) — though
  `play()` on it would still activate the session, so a test loads and
  plays only where it needs the wish to play (a chant stopped by a call),
  stopping in the same turn of the main actor, so nothing is heard.

  **The narration's speed is a slider** (`PlaybackSpeedChoice`, in the
  playback sheet and the Voice & speed sheet): 0.7× to 1.7×
  (`AudioService.rateRange` — slower the voice drags, faster the
  prayers run together) in twentieths, its value beside it
  ("1.15×"), a soft catch at 1× felt as a tick, and an outlined 1× at
  its far end as the way back, faded but never gone, so the track keeps
  its length under the thumb. The slider shows and sets the app's own
  speed (`AudioService.appRate`, `setAppRate`), never a speed a chant or
  a book borrowed, and the Voice & speed row on the Rosary's own page
  names the same speed: a drag is heard as it goes when something is playing at the
  app's speed (`previewAppRate`), and stored only when the finger lifts
  (`userSettings.narrationRate`); under a borrowed speed it is stored and
  not heard, and the loan plays on until it ends — a drag once retuned a
  slowed chant and cleared its loan, and the sheet named the chant's
  0.75× as the app's. What the slider sets once the finger
  is off it, as the thumb settles, is stored at once — taken as a drag,
  it was never kept, and the sheet named a speed the voice was not
  saying, with the 1× beside it seeming to do nothing; VoiceOver adjusts it a quarter at a
  step and reads "1.25 times". Five capsules stood there once, and a
  voice a little slow at 1× and a little quick at 1.25× had nothing
  between. `AudioService.resolvedRate` brings any speed into range and
  onto the twentieths wherever one is read or set — it used to turn
  anything off the preset list into 1× — and the remembered speed keeps
  to 0.7×–1.7×, while a speed borrowed with `remember: false` (a book on
  the Spiritual Reading shelf) may still reach the shelf's 2×. The Lock
  Screen and CarPlay, which draw their speed control from a list, and
  the shelf keep the presets (`supportedRates`); 2× chosen on the Lock
  Screen during a Rosary plays at 1.7×; chosen there while a book or a
  chant plays at a speed of its own, it is that flow's loan, never the
  app's — taken as the app's, a LibriVox reading set the Rosary's pace,
  and a book asked for at 2× played at 1.7×. The spoken Rosary's breaths
  between prayers are wall-clock pauses and do not follow the speed:
  a Hail Mary runs about 21 seconds at 0.7× and 8.6 at 1.7×, each with
  its 0.9-second breath, which is a twentieth of the prayer at the one
  end and a tenth at the other.
- **Persistence** — SwiftData holds prayer sessions, journal entries,
  consecration progress, and reading progress (True Devotion's and the
  shelf's) — the five `@Model`s registered in `appApp`; UserDefaults holds
  settings, favorites, the resume snapshot and small per-page marks
  (lessons opened, St. Carlo's candle).
- **Progress** — streaks, history, and milestones, reached from the
  Chapel's Prayer Streak tile, Settings → Devotion, and Explore's search.
- **Journal** — entries after a Rosary or consecration day, written
  freely from the Journal page, or kept from a book as a note; searchable,
  editable, and entirely on device. It has no place in the bar (Prayers
  took it): its main door is the completion screen — THE ROSARY IS
  OFFERED over Amen (THE SEVEN SORROWS ARE OFFERED for the chaplet;
  its streak chip reads "12 DAYS IN A ROW" or "1 DAY SO FAR" beside
  "12 ROSARIES PRAYED") —
  which asks "What stayed with you in this prayer?" over WRITE A
  REFLECTION, an outlined gold pill, and NOT NOW; once a reflection is
  kept (an entry written since the screen came up, so one opened and
  cancelled does not count) NOT NOW reads RETURN HOME, and both go home
  whatever tab the prayer began on. The screen scrolls only when it must,
  on a small phone at the largest text size on a milestone day. The page
  itself opens from the Chapel's Reflections tile
  (`router.switchTo(.journal)`) and Explore's search, which finds it by
  name and does not list it in The Study, as Progress does.
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
  St. Carlo's life, one of Montfort's methods, a beginner's question and a part of the
  Devotion in Summary are all `LibraryReading`s on `ReadingShelf`s
  (`Models/LibraryReading.swift`; `LibraryReadings.locate(id:)` is the
  one lookup), pushed as `.libraryReading(id:)` and drawn by
  `LibraryReadingView`: shelf and place as kicker ("WHERE MARY
  APPEARED · 4 OF 8"), the saying as a `QuotedPassageText`, prose
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
  reading it came from; on the Marian Library's and St. Carlo's shelves the
  last door leads home to the reading's own library. Explore's search finds readings by title or dating line,
  and by shelf only when nothing matches by name. A reading that only
  informs is a card; add a door.

  **How to Pray is a course for someone who has never prayed the
  Rosary.** Its front is a drawn rosary whose beads light in the order
  they are prayed, then the course as a path of three lessons, each its
  own page (`RosaryLessonView`, `.rosaryLesson(n)`, 0-based; a lesson opened is
  marked with a check, never scored): I The Beads and the Order, II The
  Prayers (cards with how often each is said and "Say it with me", a
  line at a time), III The Mysteries (painted cards, how to dwell on
  one, this week). Continue turns to the next lesson **in place**, the
  way a library reading steps along its shelf (`RosaryLessonView.
  turnPage`): the page fades out, the lesson is swapped with the scroll
  put back to the top unseen, it fades in, and the new lesson is marked
  opened (`.task(id: lesson)`). It once popped the lesson and pushed the
  next in one tick, and on a phone in the Light appearance the page that
  arrived kept a pale Back capsule and black status-bar text over the
  dark page for as long as it was open — don't bring the route swap
  back. (Before that, a swap without `.id(lesson)` updated the page
  still scrolled halfway down and never marked it; the destination
  keeps its `.id`.) Coming back from the guide, which hides the bar,
  left the front page's status bar black the same way, so both course
  pages pin `.toolbarColorScheme(.dark, for: .navigationBar)`. "Say it with me"
  brings the prayer's card up under the chrome as it shrinks to its
  first line (a long one, the Creed, once collapsed out from under the
  finger and left the next prayer in its place), and the veiled line is
  itself the way on — a tap reveals it, where the eye already is —
  beside Next line, which stays for VoiceOver and for anyone who looks
  for it. Choosing a later step in Lesson I's order brings it to the
  top the same way, since the open step's words fold away above it. In
  This week, TODAY stands under the day's name so today's
  set is never cut to "Sorrowful Myster…". The front page lights the
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
  completion screen, so it counts as the day's Rosary. With VoiceOver
  on, each step announces where it is as it arrives — the focus stays on
  Next, so a step once arrived in silence.

  **The guide keeps its place** (`GuidedRosary.Place`, UserDefaults
  `guidedRosary.place`, read through `@AppStorage`): a first Rosary is
  twenty minutes, and a call or a knock at the door — or the app closed
  — once meant the Sign of the Cross again, which the leave alert even
  said. It is kept from the Our Father on the first large bead, the step
  from which ✕ asks first (`firstKeptStep`), for a day as the Rosary's
  own resume is, with the seconds already prayed so the Prayer Record
  counts the praying and not the gap; it is let go at the Amen, on Begin
  again, when the hand comes back to the start, and when another
  Rosary is begun. It keeps the guide's length and the bead its step
  stood on (`Place.stepCount`, `Place.bead`, from `RosaryPart.key`), and
  is offered back only while both still match: a build that adds or
  moves a step would otherwise resume a kept place on another bead. A
  place kept before either was stored is offered while its step is in
  range. The welcome of the same mysteries says YOUR PLACE IS
  KEPT over a ruled row naming the part and the bead ("The First
  Sorrowful Mystery / The Agony in the Garden · 3 of 10"), the drawing
  lights that bead, and the foot is Begin again (in Back's slot) beside
  Continue — stacked, the quiet one over the act, where the largest text
  sizes will not fit them side by side. The course's last station and
  Lesson III's foot say the same and open those mysteries. A place in
  other mysteries is not offered on a welcome of these: the welcome
  says which mysteries will be prayed. It is not Home's resume card and
  must not become one — the guide is How to Pray's.

  Prayers get a page of their own through `.devotionPrayer(id:)`
  (`BookPrayerView`, the Prayer Book's page), found by `PrayerBook.prayer`, else `DevotionPrayers.find`, across the
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
  chosen voice, its painting, and the spoken Rosary's and the Prayer Book's recordings for that
  voice. A set saved from its own page takes the spoken prayers of its
  mysteries too, every prayer after the Rosary included
  (`OfflineContentService.spokenClips(for:)`): it once said "Saved on
  this device" and then, with the Whole Rosary chosen, would not begin on a plane.
- **Personalization** — three themes, prayer language, text
  size (app-wide, plus the missal's and the reading shelf's own); the Chapel
  tab's arrange-in-place page (tile order, full/half widths, the tray, rule
  of prayer) and the configurable Pray button (quick act +
  press-and-hold tray), all stored in UserDefaults via `UserSettings`.
  What brings the user to the Rosary is chosen in onboarding and Settings
  → Devotion. (The app-icon picker is built but switched off; see
  Settings.)
- **Onboarding** — nine slides (eight when the whole Rosary is said
  aloud), skippable, re-runnable from About in debug builds
  (`Views/Onboarding/OnboardingView.swift`). The order asks before it
  shows and gives before it asks: welcome → what brings you to the
  Rosary → **what you'll hear** (Meditation Only, the default, or Whole
  Rosary — `userSettings.prayAloud` — over a decade's four parts marked
  VOICE or YOU) → **where you'll count** (On the Screen, the default, or
  On My Rosary — `userSettings.prayOnBeads`, the choice Settings and the
  Rosary's pages call Counting), each shown working in one fixed slot: the players' own
  `RosaryStrandView` to swipe, or arrows stepping a mystery at a time →
  what the app holds for the reasons chosen → colors → language → a
  reminder with evening already chosen ("Remind Me at 8 PM"), which says
  before it is pressed that the iPhone will then ask → the Sign of the
  Cross, whose button takes the first step it names (today's Rosary, or
  How to Pray for someone learning) through `OnboardingFirstStep`. The
  two MAKE IT YOURS slides are the "Rosary ways to pray" handoff's, in
  its words, which the Rosary's pages and Settings share. The beads
  slide stands only with Meditation Only: with the whole Rosary aloud
  the voice moves the beads, so there is nothing to choose, and the
  first slide's kicker drops its "1 of 2". Every
  position — the strand of progress, the paintings, the ground under the
  words — is a place in `OnboardingStage.sequence`, never a slide's own
  number, and a painting is known by its slide, so the beads slide can
  come and go while the voice slide is read without a painting or a
  ground belonging to the wrong page. Every choice sits on one card
  (`OnboardingChoiceCard`: a radio where one choice excludes the
  others, a check for the reasons), and a lead whose words change with a
  choice holds the height of its longest sentence (`OnboardingLeadSlot`)
  so nothing beneath it moves. A reminder never asked about is left
  off: a first run that skips or swipes past the reminder slide turns
  `remindersEnabled` off while notifications are still undetermined, so
  Settings never shows a reminder switched on that cannot ring. The
  paintings hang in the top of the glass and dissolve to clear, so no
  word is set across a face.

  **The pages travel and nothing else does.** The painting and the dark
  ground under the words are one layer each, standing still while the
  slides pass over them, and both are drawn from where the pages
  actually stand (`OnboardingStage.progress`, in page units, measured
  off the scroll) rather than from the slide that has settled — so the
  painting crossfades under the thumb instead of after the swipe. The
  slides sit in a paging `ScrollView`, not a `TabView`, for that
  measurement, `.viewAligned(limitBehavior: .always)` so a flick can
  never skip a question, and the paintings are masked **once**
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
  beads slide, the tallest of them, could not be swiped off. The head
  keeps Skip's height after Skip has gone, or the strand rose as the
  last slide arrived. Slide titles are headings, and a slide a button
  turns to takes VoiceOver to its title (`focusRequest`); a turn made by
  the hand leaves VoiceOver where it is. The slides' staggered entrance
  drops its rise under Reduce Motion and keeps the fade.

  The copy
  is plain on purpose: say what a thing is before anything beautiful
  about it, the Church's own names in full (Total Consecration, *True
  Devotion to Mary*), Scripture from the Douay-Rheims with its
  numbering, and noon is the only reminder hour that claims the Angelus.
  Intention wording lives in `PrayerIntention.displayName`/`detail`;
  the raw values are what is stored and never change.
- **What's New and the first-use tour** — the two first looks, one for
  each kind of reader, each shown once, on the home page itself (never
  over a prayer, never while a page is pushed or a tray is up), decided
  in `ContentView.presentFirstLook`. **What's New**
  (`Views/WhatsNew/`) is for someone updating: `WhatsNewStore.
  decideAtLaunch()` runs in `appApp.init`, before the introduction can
  finish, and owes the notes only to an install that had already
  finished it and whose `whatsNew.lastVersionSeen` differs from the
  bundle's CFBundleShortVersionString — so a new install records its
  version and never sees them. The sheet is the sheet grammar: the
  version as kicker ("LUMEN VIAE 4.0") over "What's New", one ruled row
  per thing added — its own glyph and name, one plain line, a caret —
  each row a door that closes the sheet and pushes its page, and one
  gold Continue; it stands only as tall as its notes and Continue (a
  measured detent), not full height over an empty band. No counts, no
  durations, no marketing gloss. The version is marked seen the moment
  the sheet is shown. **To write the next version's notes**, add a
  `WhatsNewRelease` to `WhatsNewRelease.all` whose `version` is the new
  MARKETING_VERSION exactly ("4.1"); a version with no entry shows
  nothing (a point release included) and is still recorded as seen, and
  someone who skips a version sees only the notes of the one they
  arrive at. The 4.0 notes name what CHANGELOG.md's 4.0 section adds —
  Prayers (the Prayer Book, in the tab bar where the Journal was, its
  line saying the Journal now opens from the Chapel and after each
  Rosary, since every row is a door and the Journal is a tab, not a
  page; it turns to the Prayers tab), the Chant Library, the Rosary said aloud (with the
  speed slider; its row is "The Holy Rosary" and opens that form's own
  page on today's mysteries, `.rosaryAloud(today)`), and How to Pray
  with Your First Rosary — and not the
  Scriptural Rosary or the voices, which came in 3.0; if a named
  devotion is renamed or its route moves, change its row too. **The
  first-use tour** (`Views/FirstUseTour/`) is for a new reader: marked
  due (`firstUseTour.due`) when the introduction is first finished, and
  begun once home is reached — if the introduction's first step opened a
  prayer, or a prayer is still being fetched, it waits for the reader to
  come back; if anything pushes a page while it runs (a notification, a
  shortcut) it stands aside (`pause()`), still owed, and begins again
  from its first stop when home returns. Five coach marks over the real
  controls, one at a time: today's Rosary (the featured card), the Pray
  button (a tap and a hold), the Prayers tab, the Chapel tab, and
  Explore's glass. Each control reports where it
  stands with one appended modifier, `.firstUseTourStop(_:)` (HomeView,
  HeaderView, CustomTabBar); move a control and its stop follows it, and
  a stop scrolled off the glass keeps its card on the glass rather than
  sending it, and "Leave the tour", off the screen. The page is dimmed in
  the theme's deep ground with the control left in the light and ringed
  in gold, and hidden from VoiceOver while the tour runs; a small card
  beside it carries the tour's strand of beads, one or two plain
  sentences, a quiet NEXT (DONE on the last) and a quiet "Leave the
  tour"; its acts are never filled gold, because home keeps its own one.
  A tap elsewhere does nothing, so it cannot be lost by accident, and
  leaving or finishing ends it for good. The light travels from control
  to control (the step is taken in `withAnimation`: the implicit
  animation alone left the lit window jumping); under Reduce Motion one
  mark fades out and the next fades in. Chosen over a deck of cards
  before the app because tutorials read before the app is seen do not
  help people use it (NN/g, "Mobile Tutorials: Wasted Effort or
  Efficiency Boost?"), and help given on the control itself, one at a
  time, does (NN/g, "Instructional Overlays and Coach Marks"; Apple HIG,
  "Offering help").
- **Daily Missal** — titled "The Mass" in the app (the door "Today's
  Mass", "Daily Missal" its secondary name; the plain-language rulings
  are `copy-audit/GLOSSARY.md` on `claude/copy-audit`: plain titles first,
  the Church's names second, never a bare "1962"; the parts of the Mass
  named in English from `MissalOrderData`'s map, the day's rank as Great
  Feast / Feast / Lesser Feast / Weekday through `DayRank`, and a colour
  as "green vestments") — the 1962 propers for any day, reached from Today's
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
  so "Today's texts only" keeps the day's own Preface. The Aa
  sheet sets language (writes the app-wide prayer language), stacked or
  side-by-side bilingual layout (side-by-side forces Both), a
  text size slider for the liturgical books (15–21pt, `missalTextScale`,
  which the citations and the Office's hours follow too), posture
  cues, a Sung Mass toggle (the High Mass), and Contents: "Whole Mass" (default)
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
  only tier mark — nothing is dimmed. "Today's texts only" keeps the day's own
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
  raises the Order of Mass index sheet (the section being read lit and
  marked HERE, propers with their diamond, postures, tap to jump); the
  colophon ("THE MASS IS ENDED") links the full `OrdoMissaeView`. The date
  pill opens `MissalCalendarSheet`, a month grid — "AUGUST 2026", vestment dot per day from the year calendar,
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
- **Divine Office** — titled "Hours of Prayer" in the app, with "The
  Divine Office" its secondary name and one line saying what it is; each
  hour by `CanonicalHour.plainName` (Night Vigil, Dawn Prayer, Early
  Morning Prayer, Mid-Morning Prayer, Midday Prayer, Mid-Afternoon
  Prayer, Evening Prayer, Bedtime Prayer — never "Morning Prayer" or
  "Night Prayer", which are the Prayer Book's), `shortName` in tight
  places, the Church's name (`label`) small beneath — the pre-Vatican-II Breviarium Romanum (1960 rubrics,
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
  the page's one filled gold act ("Pray" and the hour's plain name, e.g. "Pray Bedtime Prayer"), and **no corner
  ticks, second border, or ornament divider inside it** — one ornament
  per idea. Its halo is steady; only the lit NOW mark may pulse.

  Beneath it the eight stand in three groups — the night and the dawn,
  through the day (the little hours), evening and night — each strung on one strand of
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
  on the scribe's `explicit`, said in English ("END OF DAWN PRAYER";
  it was "EXPLICIUNT LAUDES"), never on
  "Benedicamus Domino", which the Conclusio prints three lines above.

  `OfficeCalendarSheet` is the missal's month grid, and literally so:
  both sheets draw **`LiturgicalMonthGrid`** (the month in words beside the
  year — "AUGUST 2026", no longer in Roman numerals — chevrons, the weeks, the press-a-day-to-name-it readout) and supply
  only the three things that differ — the day's mark, what the day is
  called, and the offline row. They were two copies of the same four
  hundred lines, which is how the same defect came to be fixed twice.
  The office names no vestment colour, so each day is marked by
  **rank** instead (`OfficeRank`, parsed from "I. classis" and named in the
  Missal's words through `DayRank`), a gold dot
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

- **Scriptural Rosary** — a verse of Scripture for every Hail Mary bead:
  one of the Rosary's three forms (`Views/Scriptural/`). It was a Prayer
  Experience toggle that grew a verse band on the meditation's player;
  that put two readings on one screen. Then it became a devotion of its
  own, with doors of its own on home, in Explore and in the tray, and
  looked like a second Rosary beside the first. Now it stands where the
  Rosary is chosen.

  **Doors:** THE SCRIPTURAL ROSARY ("A Bible verse for every Hail
  Mary") under WAYS TO PRAY on every
  mysteries' page, opening its own page with those mysteries chosen;
  the `PrayerShortcut.scripturalRosary` act — Pray tray ("Joyful
  Mysteries · a verse for every bead"), quick tap, Daily Prayers, the
  Chapel's focus — which goes straight to the day's mysteries the way
  Today's Rosary does; "Pray the Scriptural Rosary" in In Scripture —
  its gold button and each passage page's row — straight to prayer in
  the set being read; How to Pray's Going Deeper tile; and typed search
  in Explore, which opens the day's mysteries' page. The home card's
  quiet line (THE SCRIPTURAL ROSARY · THE ROSARY ALOUD under PRAY WITH A
  MEDITATION) and Explore's two banners are gone: home shows one act,
  PRAY THE ROSARY, which opens the day's mysteries' page, where every
  form stands together. The card over it is TODAY'S MYSTERIES over the
  devotion's name — it once headlined the first of the five mysteries
  with its passage, which made one decade the subject of a button that
  prays all of them — and nothing stands between the title and the
  button. (The Chapel's focus block says Pray the Rosary too, but its
  act goes straight to a set's Rosary, where home's goes to the page.) A new install's tray has it third, under
  Today's Rosary and Today's Mysteries (`UserSettings.defaultPrayTray`,
  the "Rosary ways to pray" design's order), and a tray saved before it
  existed is given it once, under Today's Rosary
  (`userSettings.prayTrayOfferedScriptural`). An install keeps the tray
  it has: with none saved, it saves the default at launch, or, if its
  reader had finished the introduction before the change, the earlier
  order, this act second and Today's Mysteries fourth. The
  Chapel's rule counts it by name (`ScripturalRosaryViewModel.devotionName`,
  which is what `PrayerSession.meditationType` records); it also counts
  as the day's Rosary, since it is one.

  **`ScripturalRosaryView`** is the Rosary's own page
  (`RosaryConfirmPage`) for the Scriptural Rosary and the Rosary Said
  Aloud: A VERSE FOR EVERY BEAD / EVERY PRAYER, NO READINGS over the
  name and one
  line, the chosen mysteries' painting crossfading as the Mysteries row
  changes them (nothing remembered: tomorrow's page opens on tomorrow's
  mysteries), the choices, and past them a ledger — About, The first
  mystery (The first sorrow in the chaplet: the Scriptural Rosary's
  first mystery and its first verse), From. The Mysteries row opens a
  sheet of the five sets and the chaplet (`MysteriesChoiceSheet`,
  "Choose the Mysteries", over a line saying what they are), the
  chosen one lit and checked and today's
  marked TODAY; when today's are the chosen ones, as they usually are,
  the check takes the trailing edge and the line under the name says it
  instead ("Today · The Incarnation"). A tap chooses and closes. PRAY is
  guarded against a second push (`isOpening`, cleared when the page
  shows again), as the mysteries' page guards its sets, so a double tap
  before the push covers the page cannot open the Rosary twice. `SetSection`
  is shared with the set's page.

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
  Father (ASK FOR · HUMILITY, as In Scripture names it), a cue only
  where it is news — which is one view identified by
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
  before; the decade turns on its own** — on the beads there are no
  arrows and no swipe between mysteries (counted on one's own rosary,
  below, the mysteries have them). An earlier draft walked the beads with two
  arrows, and before that a gold disc stood between them; both are
  gone, and must not come back: nothing but the beads moves the Rosary
  forward. The column still taps forward and long-presses back
  (VoiceOver cannot swipe), and the one haptic keys on `beadPosition`.
  The header is × · SCRIPTURAL ROSARY · Aa (`ReaderTextOptionsSheet`
  without its narration section); the Rosary Said Aloud's header reads
  THE ROSARY SAID ALOUD. The foot is the still mystery strand over the mystery's
  ordinal name, a Whole Rosary switch (`SetupTogglePill`,
  `UserSettings.prayAloud`, named as the Audio choice names it; this
  screen has no playback sheet to put it in, and the Rosary Said Aloud,
  which has no such choice, has no switch) and the ⋯ tray with no download row.
  There is no meditation narration and no reader; said aloud, the spoken
  Rosary (see API Endpoints below) reads each verse before its Hail Mary,
  and a play disc and caption stand above the strand while it does.

  **Counted on one's own rosary** (Counting: On My Rosary, offered while
  the verses are read in silence), the strand is taken down and the
  screen moves a mystery at a time, as the meditation's player does off
  the beads. The column's head names what the hand counts — OUR FATHER ·
  TEN HAIL MARYS · GLORY BE (seven in a sorrow) — over the mystery's
  name, and beneath it the whole decade is set at once
  (`ScripturalRosaryViewModel.reading(bead:)`): the Our Father's
  announcement, a verse for each Hail Mary under the bead's own name,
  and the Glory Be with, but in the chaplet, the Fatima Prayer. It
  scrolls, dissolving at the foot, and crossfades whole when the mystery
  turns. Arrows flank the mysteries' beads at the foot, laid over them
  so the readout keeps its place (the last becomes AMEN's check), and a
  swipe left or right does what they do; a vertical drag is the decade's
  scroll. To VoiceOver the column carries Next mystery and Previous
  mystery, and on the last mystery the forward action is named "Amen —
  finish the Rosary": an action called Next mystery must not finish it.
  Counted by hand, no bead moves on the first mystery to say the Rosary
  has begun, so it is kept for Home's card once it has been prayed a
  minute (`PrayerResumeService.firstMysteryBegunAfter`, shared with the
  meditation's player), and again when the phone locks or
  the Rosary is left after that; opened and backed out of, it pins
  nothing, as on the screen. It once could not be taken up again before
  the second mystery. The Scriptural Rosary once counted only on the
  screen; its verses are as much for the hand that keeps its own count.

  **On the pendant a move is a prayer.** While the opening and closing
  prayers are said aloud there is no bead of the strand to move to, so
  the swipe, the column's tap and hold, and the rotor step the voice a
  prayer on or back (`ScripturalRosaryViewModel.stepSpokenPrayer`); a
  move back from the first bead goes into the opening prayers, and a
  move on from the last bead, while its Glory Be or Fatima Prayer is
  still being said, into the closing ones. The beads were once held
  still there, and the Creed — two minutes of every Rosary said aloud —
  could be neither passed over by someone who prays it daily nor said
  again after a knock at the door. The pendant hangs clear of the foot
  (`PendantStage(bottomLimit:)`, measured from the foot's top): placed
  by fractions of the glass alone, the cross's foot stood on the play
  disc. Through the closing prayers AMEN stands under the prayer's name,
  as it stood on the last bead; it once vanished for the Hail, Holy Queen
  and came back only after the last Amen.

  **The Rosary Said Aloud sets every prayer as it is said, the
  pendant's too.** It is this screen (`SpokenForm.plain`), and its column carries
  the prayer where the Scriptural Rosary's carries the verse. The Creed,
  the Hail, Holy Queen, the closing prayer and the prayers after the
  Rosary once showed only their names — the prayers someone learning by
  ear knows least. Now each is set like the decades' Our Father (where
  it stands, what it is, the words), with the pendant hung beside it in
  the strand's own place and at the strand's scale
  (`PendantStage(trailingColumn:)`); laid under the words, even dimmed,
  the cross ran through the Creed's lines. A rubric line ("[Let us
  pray.]") is set as a rubric, red and italic and out of its brackets,
  since the voice does not say it. The Rosary Said Aloud's prayers come down
  as far as they must to be on the page whole (`prayerMinimumScale`) —
  at 0.7 the Our Father was cut off at "who trespass a…" at the largest
  sizes — and the Creed closes its lines up as well once it cannot fit
  at the decades' leading. At the system's accessibility sizes the
  longest are still cut short: the column has fixed room and the swipe
  owns the vertical drag, so it cannot scroll.

  On the last bead the cue gives way to AMEN; completion records locally
  through `CompletedPrayer` (the completion screen takes that value now,
  not a set) and never posts to the API. An interrupted one resumes from
  Home's card (`InProgressPrayer.kind`), on its own screen, at its bead.
  The screens name the form by `ScripturalRosaryViewModel.displayName` —
  the header, the Lock Screen, a share, the resume card, the ⋯ tray and
  the feedback form say The Rosary Said Aloud (`holyRosaryName`, which
  keeps its old symbol) — while `CompletedPrayer` records
  `devotionName`, still "The Rosary Aloud" for this form (above, the
  rule's vocabulary). Home's card names a snapshot by its kind, never
  its stored name, so a card saved as "The Rosary Aloud" or "The Holy
  Rosary" comes back as the Rosary Said Aloud.

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
  reader is. A DEBUG-only log prints any
  chapter left unmapped — a volunteer re-cutting their ledger is the
  way this drifts.

  A book may also name the speed its reader is best heard at
  (`preferredRate` — Thérèse's is 1.5, because Susan Morin's reading runs
  thirteen hours and forty minutes). That is the shelf's opening offer;
  the reader's own choice per book is remembered and outranks it. It is
  kept apart from the app-wide narration speed —
  `AudioService.setPlaybackRate(_:remember:borrower:)`, lent to the
  session by its track-navigation token and given back the moment
  another flow takes the arrows (`setTrackNavigation`) or claims the
  player (`AudioClaim`; a claim with a pace of its own lends that one
  instead, and the app's comes back when it ends), or when the
  listening session stops (`restoreRememberedRate(from:)`, which leaves
  a speed some other flow has borrowed since) — so a slow LibriVox
  volunteer never sets the pace of a Rosary.

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
  paragraph and the capsule offers NOTE, BOOKMARK, SHARE.

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
  has no recording, so its act stays quiet rather than guessing — and
  neither True Devotion's contents nor the consecration day page print a
  reading time (both once did, words ÷ 200; removed Sept 2026).

  The one figure the shelf does keep is **the day's measure**
  (`ReadingDayMeter`, TODAY'S GOAL on a book's page and True Devotion's,
  chosen in `ReadingGoalSheet`): minutes with a book open, or a chapter a
  day, toward a goal the reader set — a dial for today only, reset
  silently each morning, never carried forward, chained into a streak or
  counted against anyone.

- **The Prayer Book** — the Church's common prayers, bundled, with a
  tab of its own, **Prayers**, in the Journal's old place in the bar (the
  "Prayer Book Rethink" design, its Combined boards). Every other door
  turns to that tab rather than pushing a second copy of the book (an
  order page's praying-hands door stands down when it was opened from
  the tab itself, where Back already goes there):
  home's hour row, Explore's section (titled Prayers) and search (which finds prayers by
  name, Latin name or words), the Chapel's Prayers tile, a prayer's
  order page and What's New all `push(.prayerBook)`, which
  `AppRouter.push` answers with `switchTo(.prayers)`. The Pray tray (the
  Angelus, offered once) and every existing door to a prayer
  (`.devotionPrayer(id:)` opens `BookPrayerView`) are unchanged.
  `Models/PrayerBook.swift` is the model: twelve **chapters**, named in
  plain words (Basic Prayers, Mary — twenty prayers — Jesus, the
  Eucharist, the Holy Spirit, Angels and Saints, Through the Day,
  Confession, For the Dead, the Church, Litanies, Short Prayers), each
  keeping its numeral and Latin title for its own page, a `topic` for
  search ("Prayers to Mary") and `searchWords` that include the names it
  once printed (Our Lady, the Holy Ghost, Penance, the Faithful
  Departed), so a reader who knew them still finds it; and eleven
  **orders of prayer** said together — Morning Prayers, the Angelus,
  Night Prayers, At Table, Before Mass, After Communion, Before
  Confession, After Confession, Visiting Jesus in Church (the visit to
  the Blessed Sacrament), For the Holy Souls, In Time of Trouble. The
  texts are `Data/PrayerBook/*.swift` (`PrayerBookTexts`), in
  `PrayerText`'s grammar, English always and Latin only where the Church
  prays in Latin, paired line for line; the Rosary's and the
  consecration's prayers are joined in by id (`BookPrayer.bundled`),
  never copied. Hymn translations are plain literal renderings, not
  Caswall or Hopkins.

  The book has one name wherever the reader sees one, **Prayers** —
  the tab, Explore's section, the pray-along's kicker over a single
  prayer, its question before it first speaks, the Settings row, the
  Lock Screen's album line, the offline download's stage, What's New's
  4.0 notes, which had not yet been shown to anyone — while types and
  files keep "PrayerBook".

  **Prayers** (`PrayerBookView(isTabRoot:)`, the tab's root; pushed it
  draws a Back, but nothing pushes it now) is a plain title, the search
  field at the head of the page — finding one prayer by name is the
  book's commonest errand, and the field once stood at the foot of a
  long page behind a toolbar glass that scrolled there — and three parts
  chosen on a bar beneath it (`PrayersSection`: TODAY · OCCASIONS · ALL
  PRAYERS), which take turns in one slot with the search's results.
  **Today** opens on the hour (`PrayerBook.dayOrder(at:)`): the Pray Now
  card, the order's painting (`PrayerBookPainting`) dissolving under its
  name and one italic line, a strip of MORNING · NOON · NIGHT at its
  foot (`PrayerHourStations`; the Angelus is EVENING from three until
  the day turns at four, when it is the six o'clock bell being kept),
  each saying where it stands —
  OFFERED, Now, or when it is said (`PrayerBook.standing`), never
  "missed" — and each a way to show that hour above (the choice let go
  when the hour turns and when the app comes back to the foreground),
  and the page's one gold act, PRAY THE ANGELUS (PRAY THE ANGELUS AGAIN
  once offered, so the button always names its prayer). The Angelus is
  offered for its bell, not its day (`PrayerBook.isOfferedNow`): the
  middle station is the noon and evening Angelus only
  (`PrayerBook.angelusBellKept`, which names the station and dates its
  OFFERED alike). Before eleven it is NOON, at noon, with the bell still
  to come, whether or not an Angelus was said at six; from eleven it is
  offered by an Angelus said since eleven, and from three until the day
  turns at four it is EVENING, offered by one said since three, so an
  evening Angelus never reads NOON, offered. The six o'clock morning bell
  has no station (MORNING is Morning Prayers'): an Angelus said then
  counts for the day wherever `wasOffered` is read, the Chapel's rule and
  home's hour row, but leaves the strip's NOON and PRAY THE ANGELUS
  (not AGAIN). That reads the
  moment an order was offered (`PrayerBookStore.lastOffered`, kept
  beside the day under its own key), while `wasOffered`, which the
  Chapel's rule reads, still counts an order once a prayer day. The
  card's line is the board's for the Angelus ("A short prayer to Mary
  said at morning, noon and evening.") and the Regina Cæli's own in
  Eastertide, and Night Prayers' names the antiphon the season sings —
  one pure function, `PrayerBook.daySummary(of:on:)` — and its painting
  crossfades in a
  slot of its own as the hour changes. The card is outlined, never
  filled, its halo the outline's. Then Prayers to Mary: the antiphon the
  season sings over the mystery it sings of (THIS SEASON) — left out in
  Eastertide while the Regina Cæli is already Pray Now's prayer — her
  three best-known prayers (`PrayerBook.bestKnownMarianIDs`) as ruled
  rows, and ALL 20 PRAYERS TO MARY; then Saved, the prayers kept with a
  ribbon as small outlined cards of one height the ribbon hangs from (a
  hold takes the ribbon out). Lists name a prayer as people say it
  (`BookPrayer.listTitle`: Hail Mary, Memorare, Litany of Loreto, St
  Michael); its own page keeps its full title. **Occasions** is where the reader is
  (`PrayerOccasionPlace`: At Mass, Confession, At Home, In Need, the last
  one chosen kept in `prayers.occasionPlace`), each place's orders as
  ruled rows with their glyph in a small outlined frame. **All Prayers**
  is the chapters by topic with their counts. **Searching**, the parts
  give way to "7 PRAYERS MATCH", said aloud to VoiceOver once the reader
  pauses, a card for a topic the words name
  (`PrayerBook.topics(matching:)`: every word searched must begin a word
  of the topic's names, the small words — "the", "prayers", "to" —
  counting for nothing, so "mary" finds Prayers to Mary and "hail mary"
  only the prayer), a card for an order of prayer they name
  (`PrayerBook.searchOrders`: "blessed sacrament" finds Visiting Jesus in
  Church), and the prayers found, each with its topic ("Mary · this
  season" for the season's antiphon). A prayer answers the same way
  (`PrayerBook.search`): every word searched begins a word of its title,
  Latin title or the other names it is looked for by
  (`BookPrayer.searchWords`: Salve Regina, Litany of Loreto), "st", "st."
  and "saint" read as one word (though a lone "st" searched also begins
  a word, so it finds the Stabat Mater beside the saints), æ and œ read
  as ae and oe ("regina caeli"), and a prayer whose text holds the whole
  search comes after the names. It once matched the whole search as one
  string, and "St Michael", "Loreto" and the field's own "St Joseph"
  found nothing. VoiceOver hears the topic and the orders found as well
  as the count of prayers, as the page sets them. Morning and Night Prayers
  have no mystery of their own: their cards name paintings
  (`hour_morning`, `hour_night`, names shared with the Chant Library's
  redesign, still being made) that are not yet in the catalog, and until
  they are hang the Presentation and Gethsemane
  (`PrayerBookPainting.resolvedAsset`, looked up once per name, since the
  image cache keeps no misses). Saved's cards and every surface
  on the page are outlined, never filled, where the design drew them
  filled; the ribbon is the prayer page's red silk, where the design
  drew it gold.

  The book's hour turns at four, eleven, three and eight
  (`PrayerBook.nextTurn`), none of them an hour of the Office, so the
  surfaces that name it — Prayers itself, home's hour row, the Chapel's
  Prayer Book tile — redraw on `PrayerBookHourSchedule` rather than on
  `CanonicalClock`, which slept through them and kept home on the
  Angelus until midnight. A chapter's foot turns to the next chapter in
  place, as a prayer's page steps along its chapter; it once popped and
  pushed a route in one tick, and the next chapter opened scrolled to
  wherever the last was left. The seasons are computed: the Angelus is
  the Regina Cæli from Easter to the Saturday after Pentecost, and Night
  Prayers close on the Marian antiphon the season sings
  (`PrayerBook.antiphon(on:)` — Alma Redemptoris, Ave Regina Cælorum,
  Regina Cæli, Salve Regina), which the Mary chapter marks OF THE SEASON.

  **Praying** is `PrayAlongView` (`.prayAlong(PrayAlongLaunch)`, a
  player: bar hidden, its own ×): one prayer at a time, a strand of beads
  for the order's prayers, aloud or in silence (`PrayerBookStore.
  praysAloud`, remembered). **The book asks before its first sound**
  (`PrayAloudChoiceSheet`, once, until `hasChosenAloud`): these are
  prayers for the pew, the tabernacle and the bedside, and it once began
  reading the examination of conscience aloud the moment PRAY was
  touched. It cannot be dragged away, so both answers must always be in
  reach: it scrolls, and would stand full height at the accessibility
  text sizes the app no longer reaches (held to 340 points there, its
  rows were drawn over each other). The
  order page's switch stands just above its PRAY, so
  praying from there answers the question with what the switch shows;
  afterwards the speaker at the head of the page owns the choice. The
  same choice stands in Settings → Prayer Experience as the Prayers
  row, and a choice made there answers the question before it is asked;
  it never follows the Rosary's Audio. Aloud,
  each prayer is the server's ElevenLabs
  recording in the chosen narration voice (below), the stanza being said
  lit and followed by proportion, the next prayer turning in after a
  breath; the Angelus rings `church_bell.caf` — aloud only, since in
  silence the book makes no sound at all. The page's words dissolve
  under its head and beads (`topChromeFade`, no inset) rather than being
  cut mid-line. An order prayed to its Amen is offered for the prayer
  day (see The Prayer Day), which turns at four in the morning
  (`PrayerBook.dayBeginsAtHour`) as the book's hours do, not at
  midnight: Night Prayers said at half past twelve are that night's,
  as a Rosary said beside them is, and the next evening still asks for
  its own.
  Nothing is carried forward. **Keeping**
  is a silk ribbon (`RibbonToggle`, `PrayerBookStore.ribbons`) — the
  kept prayers stand under Saved on Prayers' Today.
  **Learning** is `LearnByHeartSheet`: four steps (read, some hidden,
  first letters, by heart), in English or Latin, a hidden word shown by a
  touch, and at the end the reader's own BY HEART mark — never scored.
  **The Angelus bell** (Settings → Devotion) rings at 6, noon and 6
  (`PrayerBookStore.setAngelusBell`), and a tap on it opens the Angelus
  (`PrayerNotificationRouter`, which claims only its own notifications).

  **The recordings** are `LumenViae.Rosary.PrayerAudio`'s `book` kind,
  served by `GET /rosary/audio?include=book` and kept by
  `RosaryAudioPack` (`ClipID.book`) beside the spoken Rosary's; a prayer
  the Rosary also says plays its `prayers` recording, and a prayer not yet
  recorded in the chosen voice plays in the default voice
  (`PrayAlongVoice.prepare`), as a meditation does. The words reach
  the server as `Tools/PrayerBook/prayer_book.json`, written by
  `Tools/PrayerBook/export.py` (litany responses said after every
  invocation, marks and gestures silent) and copied verbatim to the
  server's `priv/rosary_audio/`: change a prayer, re-export, copy, record
  (`mix lumen_viae.generate_rosary_audio --kind book`) before deploying.
  The library download fetches the book's recordings too.

- **The Chant Library** — the Church's own songs, each with its
  recording and its score, bundled so they sound in a chapel with no
  signal: 76 chants in thirteen shelves (Our Lady, the Rosary and the
  Angelus, the Blessed Sacrament, the Holy Ghost, the Sacred Heart and
  the Holy Name, praise, the saints, the four seasons, the dead, and the
  Mass — the Ordinary of Mass VIII and Credo III). Doors:
  the Chapel's Chant tile, Explore (Sung Prayer, and search), and **"Sing
  it in chant"** on any Prayer Book page whose prayer has a chant (a
  quiet act under Learn it by heart).

  **The library has six ways in** (the "Chant Library Redesign" boards):
  `ChantLibraryView` (`.chantLibrary`) is a masthead — CHANT LIBRARY over
  the section's title, the ornament between them on Today's alone — over
  a strip of sections, the one chosen remembered (`chantLibrary.section`),
  its glass opening a search over the page, which stays beneath it hidden
  so Cancel comes back to the same section at the same place, and its
  bookmark the Saved section. The strip, Seasons' chips, the search's
  filters and Saved's shelf are `ChantSideScroll`s, which fade out at
  whichever edge has more to show (52 points, the Office rail's), and
  only while it has: cut by the glass with no sign, the strip's "SA…"
  read as a misprint. **Today**
  (`ChantTodaySection`): the day's four hours on the sun's arc
  (`ChantHour`, `ChantDayArc` — the Angelus at six and noon, the Regina
  Cæli in its place through Eastertide, the Magnificat at evening, the
  season's antiphon at night, turning on the Prayer Book's hours),
  tonight's antiphon in the board's lancet arch (`ArchHero`, 420 tall,
  the chant's own painting, else the night's) with its play the board's
  one gold act and a Simple | Solemn pill beneath (`ChantSettingPill`;
  the catalog's words, never the board's "Ornate"), the weekday's devotion
  (`ChantWeekday`) as a row of seven, the month's (`ChantMonth`, its
  feast named in a line, February left out for want of a chant; its
  kickers the board's FULL ROSARY and FEAST DAY CHANT), and CONTINUE
  LEARNING. The time Today shows is read in a view of its own
  (`ChantTonightTime`), as the chant page's transport is, so the board
  is not redrawn twice a second. **Seasons** (`ChantSeasonsSection`): the year as
  a wheel (`ChantYearWheel`, from `ChantYear`) — six seasons round the
  rim, Christmas running on to Septuagesima and Lent beginning there,
  Pentecost its octave; the four antiphons of Our Lady as a thread
  within, read a day at a time from `PrayerBook.antiphon(on:)` so the
  wheel and Night Prayers cannot disagree; today on the rim and the
  days to the next season in the middle — then the seasons as chips (a
  chip chosen scrolls to the middle, as far as the row's ends allow), the
  season's chants, the chant to learn before the next one comes, and the
  feasts ahead with theirs (`ChantFeast`, the 1962 dates; Christ the
  King the last Sunday of October; and, though no feast, the 21st of
  December's O Oriens, the fifth O antiphon; Holy Thursday's the Pange
  Lingua, sung as the Blessed Sacrament is carried to the altar of
  repose), each row its red day numeral, its
  names and the feast's painting as Coming Up hangs the season's (the
  chant's own where the feast has none). A thumbnail is cut about the
  point `ChantLibraryData.focalPoints` names for its painting, where the
  middle would lose its subject — the Father over the Son in the Trinity,
  the angel's face, Our Lady's in the Immaculate Conception. **Occasions**
  (`ChantOccasionsSection`): Benediction, a Visit, a Sung Rosary (53
  minutes, the Ave Maria fifty-three times), Before Bed, Before Work or
  Study, For Those Who Have Died — an index in red numerals over the
  chosen one's order of service, what happens between chants in red
  (`ChantRubricText`), each chant a bead that lights as the set is sung,
  Pause between chants, PLAY ALL, and the bookmark. Once the set is
  under way PLAY ALL is the set's own Pause and Resume
  (`ChantSetPlayButton`, Saved's PLAY THE SET too, through
  `ChantPlayer.pauseOrResume`, which holds a silence where a tap on the
  mini player passes over it), and so is the sounding bead; it once
  began the set again from its first chant (Today's weekday "Play all"
  answers the same way). The bookmark is a toggle:
  filled while the occasion is kept as a set of one's own
  (`ChantSet.occasionID`), a second tap letting that set go — never a
  second copy — but only while the set is still the occasion's own copy,
  its name and its chants and pauses in order
  (`ChantShelfStore.isUntouchedCopy`); where the occasion sings the
  season's antiphon of Our Lady, any of the four answers, so Before Bed
  kept in Advent with the Alma Redemptoris is still its own copy in Lent.
  A set a later build has written fields into is not taken for untouched.
  Any other kept set is let go only after Saved's own question before a
  delete (`toggleKeeping` answers `.askFirst`), its line true whatever
  made the set differ ("It is no longer quite the occasion's own
  order"), since a tap once threw away the reader's work, and a seasonal
  copy was once told it had been changed. Choosing an occasion, here or from Today's month, brings
  its order up the page; the tap once seemed to do nothing, the order
  opening below the fold. **Types** (`ChantTypesSection`): six lettered tiles
  (`ChantForm` — Short Chants for the antiphons, Hymns, Feast Poems for
  the sequences, Litanies, Psalms and Canticles, Everyday Prayers; 19,
  24, 7, 5, 4 and 17 — the Mass's parts among the everyday prayers, and
  the Te Matrem, the Te Deum's Marian echo in its form and its tone,
  beside it among the canticles), the kind's chants with their lengths
  drawn as rules (a kicker that says what one chant is, as Today's
  weekday card does, reads `Chant.kindName`: its kind's word, but
  Canticle for the Magnificat, the Te Deum and the Te Matrem, which
  stand under Psalms and Canticles beside the Miserere, a Psalm), and
  "Short on time?" (`ChantLength`, a minute and seven minutes the
  cuts). **Learn** (`ChantLearnSection`): the four steps, the season's
  chant to learn in time, and the course (`ChantLearningPath`: the
  Rosary's prayers, the antiphons of Our Lady, the hymns of adoration,
  then under "See more" the year, the longer chants and the Sung Mass),
  each chant showing the step
  it stands on, the one touched last with its CONTINUE in gold, the
  board's one gold act. **Saved** (`ChantSavedSection`): a shelf of spines
  (`ChantSpineCloth`) — Learned, Favourites, each set the reader made,
  and the dashed + after the last — standing side by side on a shelf
  that runs the gutter, the one chosen taller and lit, over the chants
  of the one chosen. A spine's title turns up it in an overlay, never
  in the spine's own stack: there, the line it was set on before
  turning widened every spine to a hundred points, a cover standing
  over its neighbours. A set's chants and pauses are moved and
  removed from the handle's menu, added from `ChantPickerSheet` and
  `ChantPauseSheet` (a note in red, silence if wanted; with none, its
  row says NOTE), shared as words and sung as one; then Recently played
  and the one setting, the Words (Latin and English, either alone). The
  offline sentence stands once, at the library's foot. A new set is
  named first (`ChantNewSetSheet`, from "Make your own set" and the
  shelf's +) and stands on the shelf only once made, or is begun with its
  first chant from Add to a Set: backing out leaves no empty spine. The
  Learned and Favourites spines carry a count only once there is
  something to count, to VoiceOver too, and the spine chosen does not
  grow under Reduce Motion. The curation — every chant's kind,
  seasons, feasts, weekdays, months, occasions with their rubrics,
  paths and paintings — is `Data/ChantLibraryData.swift`, hand-written;
  `ChantLibraryTests` fails if it names a chant the catalog lacks or
  leaves one without a kind. The counts the boards print are read from
  the data, never typed.

  **Nothing on the Learn and Saved boards counts against anyone**
  (`ChantShelfStore`, UserDefaults): a step is the learner's own to
  take, a chant is learned when they say so, practising a learned chant
  again never takes its mark away, and the boards show what has been
  done — "4 learned", "1 under way" — never "not started". The board's
  "59 not started" was left out for it. Opening a practice is not
  beginning: nothing is kept as under way until the learner takes a step
  in it, and a chant under way can be put down quietly (Stop Learning,
  in the chant page's ⋯ and any chant's held menu), after which nothing
  says it was begun. The store reads each list an entry at a time and
  keeps what it cannot read — an entry a later build wrote — writing it
  back beside the rest; data that is no list at all is set aside under
  its key's `.unreadable`, never written over. An entry it can read keeps
  the fields a later build gave it, a set's items' included: each
  entry's stored form is held by its key (`ShelfEntry`), and the fields
  this build does not know go back with it on every write. An entry gone
  from the list lets its stored form go, and `setStep` and `notePlayed`
  write their list once, so an entry updated in place keeps its fields
  and one put down and begun again inherits none.

  **The rubrics are set in `Rubric.text`** (`FixedColors`, a lighter red
  at 4.6:1 or more on every theme): the sentences of an order of
  service, the occasions' numerals, the kinds' counts, a set's pauses,
  the month card's kickers and the pause sheet's field. `Rubric.red`
  measures about 3.2:1 on the page, too faint to read instructions by,
  and stays for glyphs, marks and the score's initials. Every time the
  boards print is heard in words (`ChantPlayer.spoken`), never "0:21 of
  3:05".

  **Search** (`ChantSearchView`, `ChantSearch`) folds case, accents and
  the ligatures ("caeli" finds Cæli, the match underlined under the
  word as written): titles come back one result per work, its settings a
  pill, grouped in season now / any time / other times; Prayers finds
  the chant that sings a prayer by the Prayer Book's name for it; Words
  finds a line of what is sung — with its place in the recording only
  when the chant's lines are timed, and the setting it was sung in
  where the work has two ("Salve Regina · Solemn", to VoiceOver too),
  so the simple and the solemn never give rows that read alike.

  **The chant's page is Now Playing** (`ChantView`, `.chant(id:)`): the
  names (the setting after the English only where neither title says it,
  and mid-line in lower case but for a name, `Chant.settingMidLine`:
  "Lord, Have Mercy · Mass VIII", never "· mass viii", and Credo III
  never "The Nicene Creed · credo iii"), the score in a window (ENLARGE for `ChantScoreSheet`, in a
  foot of its own beneath the score's dissolve — laid over it, it was
  read through the last faded line), the
  line being sung with its English, the scrubber, five controls around
  the page's gold play — repeat, back, forward, speed (1× | ¾×) — and
  Take turns (two arrows passing, since nothing listens — it once wore a
  microphone), Words (`ChantWordsSheet`) and the sleep timer
  (`ChantSleepSheet`), "Learn this chant" at its head and Favourites and
  Add to a Set in its ⋯; beneath the fold the prayer in words, the other
  settings and the credit. The speed reads as the chant is sounding
  (`ChantPlayer.speed`), so one chosen on the Lock Screen shows as 1.5×.
  The score windows, here and in the practice, draw a part at its full
  width and cut it at the window's foot: fitted to the window, a tall
  score (the Magnificat) was drawn some 58 points wide. **Practice** (`ChantPracticeView`, full
  screen, its own ✕) learns a chant in four steps — Listen, Read along,
  Sing along (the cantor sings, then "Your turn"), On your own (you
  first, then the cantor) — with Repeat, Speed and Hide words (every
  other word, or all, cut to its first letter), ending on the learner's
  own "I know it by heart". The note beside its disc says what a tap
  does, "Tap to pause." while the chant sounds. Its ✕ gives back the
  pace and the Repeat it found, and stops the cantor only if the
  practice set it singing: a ¾× chosen to learn by once stayed on every
  chant after. A chant the practice loaded itself, sounded or not, it
  puts away (`relinquish`), a load still arriving included; one the
  library already held is paused where it was. Paused, a chant the
  practice had only loaded stood in the mini player at 0:00, over the
  foot of every page.

  **A chant steps by the line only when its lines are timed**
  (`Chant.lines`, `ChantLine`: Latin, a plain English line, start and end
  in the recording, and the score part it is engraved on). Line 2 of 9,
  back and on by the line, the line again, Take turns, the practice a
  line at a time and a Words hit's time all stand only then; every other
  chant steps by ten seconds (the system's ±10 glyphs), repeats whole,
  takes its words from the Prayer Book, and is practised whole. No
  timing is ever guessed. The lines come from
  `Tools/ChantLines/<chant id>.json`, derived from the bundled recording
  and checked before a file is added (its README says how), which the
  generator folds into `ChantCatalogData.swift` (below). As of Oct 2026
  64 of the 76 chants are timed, 2,203 lines in all (the twelve brought
  in that month are still to be timed) — each file covers its whole
  recording, the versicles, collects and repeats included, and its words
  follow the recording where it differs from the app's prayer text (the
  Litany of Loreto's later invocations, the 1909 Litany of St Joseph).
  The whole-chant ways stay for a chant added before its timings;
  `ChantLibraryTests` names the 64 timed today, so a new chant without
  lines fails nothing, and checks every timed chant's lines run in order
  within its recording. The player meets a line's end within
  a tenth of a second by carrying the clock forward between
  AudioService's half-second ticks.

  **What the library is singing stands at the foot of every section**
  (`ChantMiniPlayer`): painting, chant, where it stands ("Simple · 0:21 of
  3:05", "Benediction · 2 of 4", "Silence · 9:12 left", "Next: Tantum
  Ergo"), its pause, and a gold hairline of progress; a tap opens the
  chant — waiting between chants, the next one, whose page's play goes
  on with the set rather than sing the last again. Under Reduce Motion
  it fades in rather than rises. It is the one filled surface on the
  library's pages, because it floats over a page that scrolls beneath
  it: it stands in the page's bottom safe-area inset, so every section's
  scroll and the search's run on beneath it and bring their last row
  clear of it at its real height, where a fixed 112 points was a guess. The consecration day's transport plays the same bundled
  recording for its Veni Creator, Ave Maris Stella, Magnificat, litanies
  and Glory Be, with a SCORE door and the credit beneath it; it reads
  and drives the shared player only through its own claim, taken on a
  step with a chant. A step with none takes nothing, and the Lock Screen
  stays with whatever holds it (it once took the arrows there, over audio
  it had never loaded); a claim the day already holds from a step before
  keeps its arrows, so the day can still be stepped from the Lock Screen.
  It loads ahead only while the player is not in use (`ifIdle`) — a
  chant the library is singing, or one a phone call has stopped, keeps
  the player, and its Lock Screen arrows, until the day's own play is
  pressed, where loading ahead silenced it the moment the day opened; a
  chant left paused is taken. The day's chants are sung at 1×, as the
  Chant Library first plays them (`ConsecrationDayFlowView.chantRate`, a
  borrowed pace): a Rosary read at 1.5× has not chosen a speed for sung
  Latin, and the app's narration speed comes back untouched when the
  claim ends. Leaving the day releases it.

  **Everything is Verbum Gloriae's** (verbumgloriae.es), a Spanish
  apostolate of Gregorian chant: one cantor's voice, sung for learning,
  and engraved scores. **Licence:** their copyleft licence
  (verbumgloriae.es/licencia-copyleft), covering everything they publish
  on the site and their YouTube channel — share, adapt, any purpose,
  commercial included, *no attribution required*; the one condition is
  that an adaptation is shared under the same licence (their own
  gloss: CC "ShareAlike" 4.0 without BY). The app's files are
  adaptations — the Ogg recordings re-encoded as HE-AAC, the SVG scores
  rewritten as recolourable drawings — so they carry that licence, and
  `ChantCatalog.credit` says so on the chant page, the library, the
  consecration transport and the Lock Screen (its album line), with
  `licenceNote` beside it on the chant page and the library; the Chapel's
  Chant tile and Explore's Sung Prayer carry neither. Each chant's own
  source page is its `sourceURL`. Nothing else may be added to the library
  without the same record: the three chants the app sang before (Sept
  2026) were files on S3 with no licence — the Magnificat a YouTube
  download — and were disconnected for it. Older builds still ask for those
  files through `GET /prayers/:id/audio`, which the server now answers with
  410 Gone; this app calls no chant endpoint at all.

  **The files are GENERATED by `Tools/Chants/generate.py`** from the
  curated `Tools/Chants/chants.json` (which chants, their English titles
  and lines, the prayers each sings): recordings as `Resources/Chants/
  <id>.m4a` (mono HE-AAC 32 kbps — four and a half hours of chant ship
  in the app, about 68 MB), scores as `Resources/Chants/Scores/<name>.lvscore`, and
  `Data/ChantCatalogData.swift`, with each chant's timed lines from
  `Tools/ChantLines/` where it has a file — checked against the
  recording's length and the score's parts, a file that does not hold
  together stopping the build, and folded in alone, with no network,
  by `--lines-only`. Never hand-edit them; edit the JSON and
  rerun (ffmpeg and macOS's afconvert are needed only for a recording the
  app does not have yet: one already there is kept, its source neither
  fetched nor encoded). A change to titles or captions alone reruns with
  `--keep-assets`, which reuses the scores too and downloads only the
  chant pages. Since Sept 2026 the site serves those pages with the
  header alone, and the generator reads each page's content from
  WordPress's REST API instead — the page builder's shortcodes, with the
  same files and alt text, their quotes typeset (» at both ends, “ ”, and
  the inch mark ″ after a figure), which `plain_quotes` puts back as
  plain ones before an alt is read: read as they stood, the Memorare's
  alt ran on into the next attribute ("Memorare 1″ show_bottom_space=»off").
  A part's caption is the Latin words it begins with, stripped of the
  site's filing ("simple", "solemne", "la secuencia", a melody's "I", a
  Mass's number and name, a litany named again on its own page, an
  editor's note); a page that files its parts by number ("1 de la
  Antífona O Oriens y el Magnificat") has them named in chants.json
  (`captions`: O Oriens, Magnificat, O Oriens — the Magnificat's part is
  the image the site shares with O Sapientia's, the same tone II, as all
  seven O antiphons are). A caption still holding markup or filing stops
  the generator, and `ChantCatalogTests` fails if any comes back. **Scores are not asset
  catalog images**: the catalog stores SVG uncompressed (30 MB) and CoreSVG
  would not read every one, so the generator rewrites each SVG as its
  ordered drawing operations — fills in ink and red, the white shapes
  that erase, stroked staff lines — DEFLATE-compressed (7.6 MB), which
  `ChantScoreDrawing` reads (its own SVG path-data parser, arcs included)
  and `ChantScoreImage` replays on a Canvas: the notes in cream, the
  initials in `Rubric.red`, vector at any zoom. Parsed, the paths are kept
  in an NSCache of 32 scores (`ChantScoreStore`) that lets them go when
  memory runs short; held every one, they came to some 60 to 75 MB. A score with live text or
  transforms stops the generator rather than ship half-drawn (Maria Mater
  Gratiæ was left out for its live text; the Litany of Loreto's Easter
  collect is served by the site as a 404 and is skipped).

  **The enlarged score zooms about the phrase under the finger.** A pinch
  scales the drawing as the fingers move and lays the score out afresh at
  its new width when they lift, so the engraving is sharp again at the
  size it is read; a double tap animates the same way. Laid out afresh
  with nothing more, the score grew from its top-left corner and carried
  the phrase being read off the glass. The captions and the gaps between
  parts keep their height at any zoom, so a point on the whole score does
  not scale with it: the sheet keeps the part and the point on that
  part's engraving (`ChantScoreMark`) and scrolls it back under the finger
  once the mark reports where the new layout put it — scrolled any
  sooner, it landed on the old layout. Where the scroll view's edge holds
  the score back (always across, coming back to the width of the glass),
  the double tap's scaling is drawn about the point that brings the
  score to where it will rest, not the tapped one. The page's and the
  sheet's transports are views of their own (`NowPlayingTransport`,
  `ChantScoreSheetTransport`): read in the page's body, the progress they
  show twice a second re-evaluated the page, score and all, on every
  tick. The scrubber is heard as time ("1 minute 5 seconds of 3 minutes
  20 seconds"), ten seconds at a swipe.

  **`ChantPlayer`** (`Services/`) is the library's hold on the shared
  AudioService, above the views like `LibraryListeningSession`: one chant
  at a time for the tile, the library, the pages and the Lock Screen
  (whose arrows step through the library, or through the set being
  sung). It sings a set (`ChantQueue`: an occasion, a reader's set, a
  weekday's chants), keeping a set's silences and, with Pause between
  chants, waiting for a tap before the next; a chant chosen on its own
  puts the set down. It keeps the line clock (`lineEnd`: on, again,
  take turns, and practice's stop and your-turn-then-stop), the sleep
  timer (minutes, or the chant's end), and notes each chant sung for
  Recently played. A set's silence plays `Resources/chant_silence.m4a` —
  five seconds of silence, AAC, kept beside the other bundled sounds and
  not in `Resources/Chants`, which the generator owns — on a loop through
  the set's own claim for as long as the silence lasts: timed by the
  clock alone, it never ended on a locked phone, whose app iOS suspends
  with nothing sounding. The Lock Screen and the headphones reach the
  set's own pauses through the claim's `onTransport`: a pause holds a
  silence, a wait or the reader's turn with what is left of it, play
  goes on with the set, and headphones pulled out in a silence never let
  the next chant begin from the speaker. A set takes the player at the
  tap, and a silence that ends with another flow holding it ends the set
  rather than claim over it. An entry that loads the recording already
  in the player — the next Ave of a decade — begins it from its top; it
  once moved the count while the same Ave sang on. A pause asked for
  while a chant is still arriving — headphones pulled out as the set's
  next chant loads — is kept (`pauseAskedWhileLoading`), and the chant
  arrives held. Play from the Lock Screen during the reader's turn never
  starts the cantor over them: a turn keeping its time is going on, as a
  silence is. On screen it is drawn so (`chantGoesOn`, a chant sounding
  or its turn running): the chant page's gold play and the mini player's
  disc show pause through the turn, and a tap holds it, where they once
  showed play and a tap paused the turn unseen; a silence still shows
  play on the disc, since a tap there goes on to the next chant. A chant
  whose recording is missing takes a set's silence out of the player
  rather than leave it looping as if it were the chant. A chant chosen during a silence takes the Lock Screen
  straight from the silence; only a set that really ends clears it.
  Practising a chant, by the line or whole, puts down a set it was being
  sung in. The line clock and the reader's turn keep the speed sounding
  (`speed`). It holds the player by a
  claim (`AudioClaim`), taken at the tap, so another flow taking the
  player is never narrated as its own: the progress line and the pause
  glyph read the claim, and come to rest when it ends. The consecration
  day holds a claim of its own, and a recording the two share — the Veni
  Creator — is two loads, the second from its top. Decided by the file
  and the load generation, as it once was, a second load of the file
  already in the player was no new load, so both believed they held it
  and closing one silenced the other. Its practice pace is borrowed
  (`.borrowed(rate)`), never remembered as the app's narration speed,
  and comes back however the claim ends — `relinquish()`, or another
  flow taking the player. Repeat is the claim's `onFinish`, told only
  for the chant the library loaded, and only while its claim holds the
  player. Earlier builds
  saved the unlicensed chants offline as `prayer_<slug>.mp3`;
  `OfflineContentService.retireUnlicensedChants()` deletes them once at
  launch (`appApp.init`) and corrects the saved library's size.

### Not built yet

- A Divine Office version/language setting (Monastic, Dominican, and the
  other rubrical versions the API's `/office/versions` already serves) —
  `OfficeAPIService.version`/`.language` are the seam, and
  `OfficeCacheService`'s file names must gain the language
- Auto-scroll *synced* to audio, word by word. Both readers follow
  proportionally instead — the prayer reader and the Spiritual Reading
  reader — because neither the narration nor LibriVox carries timings
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

Every theme colour — gold included — comes from the active theme's
`ThemePalette` (`DesignSystem/Theme.swift`), read through `AppColors`;
never write a hex at a call site. Only `AppColors.textPrimary` (white) is
the same in every theme. A colour that belongs to a thing rather than to
the page — a vestment's dot, the sky at each hour of the Office, a set of
mysteries' card, a stage of the consecration, a book's cloth, St. Carlo's
portrait — is the same in every theme too, like `Rubric.red` and
`AppColors.marianBlue`, and is written once, named, in
`DesignSystem/FixedColors.swift`. Any other hex belongs to a theme's
palette, or is one of those two. There are three themes, and **new installs
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
  format) in `DesignSystem/ReadingText.swift`. Long-form reading —
  `ReadingText`, `PrayerText`, and the book readers' `ReaderProseParagraph`
  — takes its spacing from `ReadingTypography`, which scales with the font
  size; short blocks (a title, a card's blurb, a verse under a heading)
  set their own `lineSpacing`. Reading blocks are 15–16pt
  minimum in cards, 17–18pt in immersive readers; tap targets stay ≥44pt.
- **The text follows the phone's Larger Text up to `.xLarge` and no
  further.** Every `AppFonts` face is `Font.custom(_:size:)`, which
  scales with the body style, so the whole app grows with the phone's
  setting until the root's `.dynamicTypeSize(...DynamicTypeSize.appMaximum)`
  (`appApp`; the constant is in `DesignSystem/Typography.swift`) holds it.
  Past that the display type broke mid-word and the pages stopped reading
  as designed; `.xxLarge` was tried first and still cut the home page's
  Today's Prayer rows short. At every accessibility size (AX1–AX5) the app
  draws exactly as at `.xLarge`, so no layout is designed for those sizes:
  the `isAccessibilitySize` and `>= .accessibility1` branches that remain
  (the Chant Library, a set's ledger, the Prayer Book's grid and its
  aloud-or-silence sheet) are unreachable, kept only in case the cap is
  ever lifted. A sheet or a cover takes its text size from the phone, not
  from the view that presents it, so each one carries the same modifier on
  its content (see Lines and Edges). A book's cloth (`BookCover`) holds its
  lettering at Large, since the lettering is sized to the cloth. The
  readers' own Aa sizes are separate and stand on top of the phone's: the
  meditation text's 16–24, the missal's and the Office's 15–21, the
  shelf's 15–26.
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
(never `Image("ph-…")` at a call site) and all rendered as templates:

- **`ph-*`** are Phosphor Light (MIT), plus `ph-*-fill` for a selected
  tab: the app's chrome — carets, ×, search, transport, faders, the
  readers' controls — at the weight of 1.125 on a 24 grid.
- **`ch-*`** are the devotional glyphs, `stroke-width="1.5"`, round caps
  and joins, on a 24×24 viewBox. Most are Christicons (christicons.com,
  its licence page: free for commercial use and to modify, no
  attribution; never redistributed as a set, and never the primary
  element of a logo or brand mark — so never the app icon's subject).
  `ch-lily`, `ch-consecration`(`-fill`), `ch-sacred-heart` and
  `ch-window-fill` were drawn for this app and only share the prefix.
  The published set has 61 glyphs; the ones not vendored are worth
  checking before drawing a new one.
- **`lv-*`** are drawn for this app where no glyph with real meaning
  existed, at 1.5 to stand with the `ch-*` glyphs. All but
  `lv-breviary` are written by `Tools/IconAudit/draw.py` — edit a glyph
  there and rerun it, never the SVG. `lv-star` is Christicons' star with
  its four short rays left off (with them it read as a sparkle), and
  `lv-stella-maris` and `lv-jordan` set that star and Christicons' dove
  over the same waves.

The rule the icon audit (Sept 2026, `Tools/IconAudit/contact-sheet.png`)
holds every glyph to: one metaphor per concept, taken from the Church's
own iconography, legible at 12–16pt, the Chapel kickers' size. Never the
vocabulary of other apps standing in for a devotion — a sparkle ("new",
"AI"), a sun or sunrise (weather), a moon (Do Not Disturb), a rating
star, a prize medal or laurel (gamification), an account avatar, a chat
bubble, the ☰ list. Where no emblem is traditional (the Luminous
Mysteries date from 2002) take the first scene's. Known and unsettled:
Phosphor Light is a third lighter than the 1.5 glyphs, so a list that
mixes a Phosphor door (True Devotion's crown, the Office's clock, the
Chant's note, the scroll, the flame) with `ch-*` glyphs stands uneven.

The app icon (`AppIcon.appiconset/AppIcon-1024.png`) is a painting run
to all four edges, with no rim or dark corners of its own: iOS draws the
rounded mask, and a rim painted inside it read as a second frame. Its
monogram is the Miraculous Medal's, an M with a bar and a cross rising
from it (the M's legs once crossed into an X under the cross), and the
crown is twelve stars (Apoc 12:1). It is made from
`Tools/IconAudit/app-icon/original-1024.png` by `fix_icon.py`, which
writes the catalog's PNG; change the script and rerun it rather than
painting over the PNG.

SF Symbols appear only where the system's own vocabulary is the point —
the transport's ±10s skips (glyphs that carry a number), the spoken
Rosary's failure notice, the Prayer Record calendar's prayed-day marker,
swipe and menu actions (`Label(…, systemImage:)`) — never as a devotional
or door glyph. Note that `qlmanage` cannot preview these faithfully: it
renders a stroke-only SVG blank and *fills* path data meant to be
stroked, so check a new glyph in the running app, or render it in a
browser as `make_sheet.py` does.

A gold act's glyph names the act: `GoldCTAButton(glyph: .play)` for one
that begins a prayer, `.chevron` (trailing) for one that goes on to a
page, and a trailing check (`trailingIcon: "ph-check"`) for one that
completes something. Play leads the word at either prominence: the
guided Rosary's inline Begin and Continue once trailed theirs, the one
Begin in the course that did. A Latin cross once led
every page-level act and named nothing; the cross now stands on the tab
bar's Pray medallion alone. The `OrnamentDivider`'s centre cross is an
ornament, not a control, and stays; `lv-lozenge` is its diamond stud,
for a flourish set beside a word (MILESTONE REACHED), and means nothing.

One glyph per door. The same door wears the same icon everywhere it
appears:

- **Doors** — the Rosary `lv-rosary` (beads, medal and crucifix: a ring
  over a cross, as `ch-rosary` drew it, is the sign ♀); the Missal
  `ch-altar` on every surface (the Liturgy tile, which holds the Missal
  and the Office together, wears it too); the Office `ph-clock`; the
  Marian Library `ch-lily`; In Scripture `lv-breviary` (the Scriptural
  Rosary keeps `ch-bible`); the Prayer Book `ch-praying-hands`, the one
  praying-hands glyph (it also marks a prayer's door and Pray aloud, and
  is the Prayers tab's, lit in gold alone since no fill weight is drawn);
  the Consecration `ch-consecration` (the Marian monogram, a cross over
  an M; the crown is True Devotion's alone).
- **The mysteries** (`MysteryCategory.iconName`) — Joyful `lv-star`,
  the Star of Bethlehem; Sorrowful `lv-crown-of-thorns`, a plaited
  ring; Glorious `lv-banner`, the Resurrection's vexillum; Luminous
  `lv-jordan`, the dove over the Jordan; the Seven Sorrows
  `lv-pierced-heart`, Mary's heart pierced by Simeon's sword, wherever
  they appear.
- **The hours** — Morning Prayers `lv-rooster` (the cock of Lauds'
  hymn, *Aeterne rerum Conditor*), the Angelus `lv-bell` (a church bell
  on its yoke, as is the Church Bells sound; `ph-bell` is the Daily
  Reminders' notification bell and the Altar Bell sound), Night Prayers
  `lv-lamp` (Vespers was the *lucernarium*, the lighting of the lamps).
  The moon is left to the reader's sleep timer.
- **The Prayer Book's chapters** — Jesus `ch-chi-rho`, the Holy
  Spirit `ch-dove`, Angels and Saints `lv-saint` (every saint: the Marian
  Saints shelf, a saint's reading, the Saints kind of meditation),
  Through the Day `lv-hourglass`, Confession `ch-keys` (the keys of
  absolution; the confession orders and Carlo's confession too),
  Litanies `lv-procession-cross` (they were sung in procession), Short
  Prayers `lv-dart` (*iaculatoriæ*, prayers darted out).
- **The Marian Library's shelves**, whose glyph the doors to their
  readings wear — the dogmas `lv-twelve-stars` (Apoc 12:1), Scripture
  `ch-bible`, the apparitions `lv-rose`, the saints `lv-saint`, the
  Rosary `lv-rosary`, her titles `lv-stella-maris`.
- **Milestones** — a count is its numeral (③ ⑦ ⑨); a named devotion its
  sign (33 `ch-consecration`, 54 `lv-rosary`, 100 `lv-wheat`, 365
  `ch-chi-rho`). Never a prize medal.

A door's glyph may also mark content of its own kind inside a page,
never a different door: `ch-lily` is Mary's lily, so it also marks the
Memorare, Our Lady's Psalter and the Cana reading; `ph-clock` is the
hours, so it also marks the reminder's time. A glyph standing for a
devotion is the one that devotion's own iconography uses:
`ch-sacred-heart`, the heart aflame, marks the heart of the Marian
consecration — True Devotion's "The Spirit of This Devotion" and the
consecration onboarding's "The Gift".

Today's Mysteries (the Pray tray's row, `PrayerShortcut.chooseMeditation`)
is the one door whose glyph follows the day: it wears the day's own
mysteries' emblem (`MysteryCategory.iconName`, through
`PrayerShortcut.icon(today:)` and `ScheduleService.categoryForToday()`,
so the schedule and Sunday's season decide it, as they decide the row's
subtitle) — the banner on a Wednesday, the star on a Monday. The row
names those mysteries and opens their page. It wore `ph-book-open`, as
the "Rosary ways to pray" handoff specified, which Spiritual Reading's
door and the Journal also wear; a new fixed glyph, a triptych, was
drawn and passed over (`Tools/IconAudit/candidates/`). The Rosary's two
choices wear `ph-speaker-high` (Audio) and `lv-rosary` (Counting), from
`RosaryChoice`.

### Motion

`DesignSystem/Motion.swift` holds the app's named motions — the `Motion`
enum. A motion that recurs — a press, a crossfade, a panel arriving,
anything the prayer screens do — takes a named one; a choreographed
one-off sequence (onboarding's slides, the Chapel's arrange mode, the
completion screen's seal, a reader's fades) times itself with literal
curves, as about a hundred call sites do. The named motions:
`beadSlide` and `beadSettle` (the strand), `words` (a bead's
name, verse or cue changing), `decadeTurn` (painting, kicker and title
crossfading to the next mystery), `chrome`, `panel` (a reader or tray
arriving), `settle` (a press or toggle landing), `crossfade` (content
changing in place), `choice` (one of the Rosary's two choices changing —
the pill's lit segment, its note, a choice arriving or leaving beneath
another — `ease(0.25)`), and `ease(_:)`/`travel(_:)` — the design system's
cubic-bezier curves the missal and office readers use. Springs settle:
the named ones damp at 0.74–0.86 and any other at 0.7 or more, so they
barely overshoot. Only a celebration bounces — the milestone card and
the seal's check on the completion screen, the consecration's
completion, the streak widget's flame (damping 0.5–0.65); nothing a
person uses to pray does. The two press styles (`SacredCardButtonStyle`,
`GoldCTAButtonStyle`) share one beat, and bare glyphs — the header's
glass, a month arrow, a tab — take `QuietGlyphButtonStyle` so no chrome
tap feels dead. A segment of a Rosary choice's pill is not a bare
glyph: it takes `SacredCardButtonStyle`, since half the pill dipping to
0.9 read as a jolt under the thumb.

Four rules, learned the hard way:

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
bead's length, a third of that at either end of the Rosary), the Scriptural
Rosary's words dim as it goes, and on release the string slides the rest of
the way on `Motion.beadSlide` while the ring passes from the bead
leaving the hand to the one arriving — `RosaryBead` is one view whose
parts light and dim, never three views swapped. Let go short of a bead,
the string comes back on `beadSettle`. At a decade's turn the mystery's
name arrives from the side the string came from (`beadWordsArrival`, a keyframe nudge
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
  its sides. Never write `lineWidth: 0.5` or `frame(height: 0.5)` for a
  rule or a border. A stroke that is part of a *drawing* rather than a
  rule — the tooled frame on a book's cloth (`BookCover`), the pendant
  cross's metalwork (`PendantCrossView`), the rim of Explore's small
  arched paintings — is drawn at the weight the drawing needs (0.6–0.8).
- **A pushed page's scroll runs to the screen's foot.** `topChromeFade`
  (`DesignSystem/SacredComponents.swift`) dissolves the scroll under the
  Back capsule with a mask, and the mask ignores the bottom safe area:
  sized to the safe area, it once cut every page that uses it off in a
  hard line above the home indicator, a title or a gold button halved
  over a flat band.
- **Every `.sheet` carries `.presentationBackground(AppColors.background)`**. A sheet's own container is the
  system's white; the content's dark ground is clipped by the same
  rounded rim, and at that rim's anti-aliased edge the white shows
  through as a hairline around the top of every tray. The background
  goes on the sheet's content view, beside its detents.
- **Every `.sheet` and `.fullScreenCover` carries
  `.dynamicTypeSize(...DynamicTypeSize.appMaximum)`** on its content,
  beside its background. A presentation takes its text size from the
  phone rather than from the root, so without it a sheet opened at an
  accessibility size drew at AX5 over a page drawn at `.xLarge`.
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
  header only. The Missal's one-time layout question and the Prayer
  Book's question before it first speaks (`PrayAloudChoiceSheet`) keep
  their indicators hidden, because neither can be dragged away and a
  grabber would say it could.

### Visual Style
- Dark, contemplative theme on the page gradient (`AppColors.appGradient`)
- The app declares itself dark (`UIUserInterfaceStyle`, set as
  `INFOPLIST_KEY_UIUserInterfaceStyle = Dark` in the target's build
  settings), so the system's own chrome — the status bar, keyboards,
  alerts and dialogs, pickers and menus, a sheet's system parts, the
  launch screen — is dark whatever the phone's own appearance; all
  three themes are dark, and a phone set to Light once styled that
  chrome for a light app over dark pages
- Gold accents for sacred/important elements; one filled gold act per screen
- Ruled ledgers and 16pt hairline outlines at `gold@0.24` on the bare
  page — filled card surfaces only where a section above says so (the
  Chapel's sections, its arrange rows and tray — see The Chapel Tab —
  and the chant's play disc)
- Heroes and plates dissolve to clear, never to a flat slab
- Minimalist, distraction-free UI for prayer focus

## Technical Notes

- **Minimum iOS:** 17.0 (uses `@Observable`); newer APIs are gated behind
  `#available`. Building needs Xcode 26 (Swift 6.2 toolchain:
  `@concurrent`, approachable concurrency).
- **Framework:** SwiftUI throughout; the one UIKit view is the system mail
  composer (`MailComposeSheet` in the feedback form). UIKit is imported
  elsewhere only for values and services (`UIImage`, `UIApplication`,
  `UIPasteboard`, `UIFont`, `UIColor`, `UIDevice`, the image renderer), never a view.
- **State Management:** `@State`, `@Observable`, `@Environment`
- **Navigation:** `NavigationStack` driven by `AppRouter` (`path` + `AppRoute`).
  The consecration tab hosts its **own** stack as a sibling of the outer one —
  nesting it silently drops the outer stack's destination table. Don't
  "simplify" that.
- **Persistence:** SwiftData for prayer sessions, journal entries,
  consecration progress and reading progress; UserDefaults for settings,
  favorites and the resume snapshot; Application Support for offline
  content and the Missal, Office and Library caches.
- **Tests:** Swift Testing suites in `appTests/` (the `appTests` target: a
  synchronized group, hosted by the app, `@testable import app`), run from
  the shared `app` scheme — `xcodebuild test -project app.xcodeproj -scheme
  app -destination 'platform=iOS Simulator,id=<udid>'` on a simulator of
  your own. Pure logic only (the strand's arithmetic, the seasons, the
  chant catalog, the spoken script, the Prayer Book's line pairing); there
  is no UI-test target.

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
- The spoken Rosary's and the Prayer Book's recordings, per voice (`GET /rosary/audio`)
- The narration voices, the server's default first (`GET /voices`)

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
  Scripture, St. Carlo, the daily quotes, the Prayer Book's prayers
  (`Data/PrayerBook`)
- The Chant Library: 76 recordings and their scores (`Resources/Chants`,
  GENERATED by `Tools/Chants` from Verbum Gloriae, copyleft)

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
- **Separation of concerns:** Keep schedule/calendar logic in `ScheduleService`, which holds both weekly schedules and is the one place feast-day overrides would go.
- **Content-driven:** Mystery data (titles, scriptures, meditations) should be stored as data files, not hardcoded in views.

## Content Requirements

> **Note:** Meditation sets and their narration are managed in the web app and served by the API; everything under "Bundled in the app" above ships in the app, the chants included.

### Meditation Content Structure (from API)
- **Sets:** five meditations each (seven for the Seven Sorrows), in all
  five categories. As of Sept 2026 there are 23: Joyful 6, Sorrowful 5,
  Glorious 5, Luminous 4, Seven Sorrows 3.
- **Labels (live in API):** Each meditation set carries a `labels: [String]` array. The controlled vocabulary lives in the web app (`LumenViae.Rosary.Labels`) and is currently Intentions, Saints, Scriptural, Contemplative, Considerations. The iOS picker builds its multi-select filter chips from these and groups unfiltered browsing by each set's *first* label, so order labels primary-first. If a set arrives without `labels`, the picker gracefully falls back to a flat list. Favorites are on-device (not API).
- **Label wording is a display concern:** filtering and grouping match the raw API string, but the picker renders labels through `MeditationLabel.displayName` (`Models/MeditationSet.swift`). "Considerations" currently shows as **Reflections**, "Contemplative" as **Inside the Scene** (the bare adjective could not be told from Reflections), and "Scriptural" as **Gospel**, so that one thing on a mysteries' page is called Scriptural: the Scriptural Rosary above the sets. Rename in that map, not in the database; Explore's search matches both words.

### API Endpoints (as implemented in `APIService`)
```
GET /mysteries[?category=]              # Implemented but unused — mysteries are bundled
GET /meditation-sets?category=:category # [MeditationSetSummary] for a category
GET /meditation-sets/:id                # Full MeditationSet with meditations + audio_expires_at
GET /meditations/:id/audio[?voice=]     # Freshly signed narration URL + voice + expires_at
GET /voices                             # [NarrationVoice], default first
GET /rosary/audio[?voice=][&include=]   # Recorded prayers: the spoken Rosary's (prayers, announcements, verses) and the Prayer Book's (include=book)
POST /completions                       # { meditation_set_id, prayed_aloud } — a finished set's Rosary
```
**The completion is the app's one write, and it is not nothing.** When a
meditation set's Rosary is finished, `recordCompletion` posts the set id
and whether it was said aloud as the Whole Rosary (`prayed_aloud`; the
Privacy Policy says it in those words). The server stores it with the time, a
city/region/country looked up from the request's IP through a third-party
service, and the IP truncated to /24 — no account, device or install
identifier (the backend's `docs/COMPLETION_ANALYTICS.md`). The Scriptural
Rosary, the Rosary Said Aloud and the Guided Rosary never post, and the
Privacy Policy names all three. The privacy manifest
(`PrivacyInfo.xcprivacy`: Product Interaction and Coarse Location, not
linked, not tracking, for Analytics) and the in-app Privacy Policy
(`PrivacyPolicySheet` in `Views/Account/AccountView.swift`, "What Reaches
Us") say so, and App Store Connect's App Privacy answers must match them —
keep the three in step with any change to what is sent.
The spoken Rosary (`UserSettings.prayAloud` — Audio: Whole Rosary — off
by default, and always in the Rosary Said Aloud) says every prayer aloud and
moves the beads with the voice, in both the meditation's player and the
Scriptural Rosary's screen. `SpokenRosaryScript` (Models/SpokenRosary)
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
On the meditation's player prayed on the beads, the closing prayers are
said with the strand still hung, for its AMEN, so the stage is drawn wider
and moved left (`pendantShiftBesideStrand`) and the cross hangs in the
column the strand leaves - centred, its arms ran under the bead's name and
the AMEN - and the final bead is named CLOSING PRAYERS
(`PrayerSessionViewModel.spokenBeadLines`), where the Glory Be's name went
on through the Hail, Holy Queen. After the last Amen the pendant stays
(`SpokenRosaryPlayer.pendant` shows the script's last segment once
finished), so the Rosary ends on the cross it began on, AMEN beckoning and
the next-prayer button faded; the last mystery's painting once came back
under it. Until then the play button is ready whenever the Rosary is said
aloud (`NarrationPlayControl`): a prayer stepped to while paused, or the
Whole Rosary chosen mid-Rosary, has no recording loaded until play is pressed,
and gated on a track's length the button stood lit and did nothing. Under
VoiceOver the button reads the prayer being said, and a swipe up or down
on it steps a prayer, as the buttons beside it do; its fifteen seconds ran
a Hail Mary off its end while it played, and did nothing to be heard while
it was paused. The pendant is fitted above the foot, and gives up height at the
largest text sizes, where the prayer's name stood across the cross.
While the voice says the opening prayers, or waits on its recordings, it
holds the hand (`PrayerSessionViewModel.voiceHoldsHand`): the strand, the
reader's bead row, the rotor's bead actions and the decade arrows stand
still, and only the player's previous and next prayer buttons move the
Rosary - one tap on the reader's row once skipped the Creed, the first
mystery's announcement and its meditation, and the → arrow the whole first
decade. On arrival PRAY is the word to begin, and the voice begins;
chosen mid-Rosary from the playback sheet, the Whole Rosary carries on
only if the meditation was playing, and otherwise waits at the hand's
place for play, as a new voice does. The reader follows the voice only while it is on the
meditation (`isHearingMeditation`) - its page once ran top to bottom under
every Hail Mary, and back - and its bead row names what is said (OPENING
PRAYERS · The Apostles' Creed, THE MYSTERY, MEDITATION) with no cue to tap,
since the voice moves the beads.
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
`rosary_closing_prayer`, off by default and chosen in Settings (After the
Rosary) or in a Rosary's own page's Voice & speed sheet
(`UserSettings.prayForHolyFather`, `prayMemorare`,
`praySaintMichael`), always said in this order: for the Pope's
intentions (Our Father, Hail Mary, Glory Be, captioned "For the Pope's
intentions"; the switch's line says what the intentions are, and the
Memorare's quotes its first words), Memorare,
Saint Michael; never in the chaplet. `OfflineContentService.downloadAll`
also fills the pack for the chosen voice (`SpokenRosaryScript.everyClip()`),
best-effort, so the first spoken Rosary prays offline. The pack reuses its
saved manifest while the links have more than five minutes to live and
refetches before downloading once they do not; offline it says what is on
disk, and with nothing saved in the chosen voice it says the Rosary in a
voice it has (the default first) rather than not at all, as a meditation
saved in another voice plays before silence. A meditation that will not
load is given the silent player's two fallbacks before it is passed over
(`SpokenRosaryHost.spokenMeditationFallbackURL`): a fresh link, then a copy
saved in another voice. A recording broken off by an interruption is taken
back on its next play - to its first word when it is under a minute (a
prayer, a verse), five seconds otherwise - and resume after an interruption
reads whether playback is wanted now, so a recording heard to its end never
comes back. While the spoken Rosary owns track navigation it also takes
Lock Screen and headphone play and pause, and headphones pulled out
(`setTrackNavigation(onTransport:)`), and a stream that fails part-way is
passed over (`onFail`). A move of the hand, a prayer step or a Lock Screen
arrow while the voice goes on is said once, for the place it came to
(`SpokenRosaryPlayer.sayCurrentSoon`), and counts as the Rosary going on
from that moment, so a pause right after it holds; the recording it
replaces, still sounding while the next is found, is never taken as the
new prayer's end. Walked back across a decade's end - two moves in one
turn - the Glory Be was once cut off after a breath, and a meditation
stepped onto while its link was fetched was cut off two seconds in, when
the announcement before it ended. Resume keeps the script step (`SpokenStep` on `InProgressPrayer`,
kept current through `SpokenRosaryHost.spokenRosaryReached`), used only if
the rebuilt script still has that prayer at that place, and only while
the hand still stands on the mystery and bead the snapshot was saved at:
taken up after the hand had moved on (the Whole Rosary chosen later in
the Rosary), the voice would carry it back there. Completions post
`prayed_aloud` (`POST /completions`).
A debug build takes `LUMEN_VIAE_API_BASE_URL` to try an undeployed server;
it redirects `APIService` only, since `OfficeAPIService` hard-codes
production.
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
