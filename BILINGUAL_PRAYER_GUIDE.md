# Bilingual Prayer System - Usage Guide

## Overview

The new bilingual prayer system eliminates code duplication by storing each prayer **once** with both English and Latin versions, then dynamically generating the display format based on user preferences.

## Key Benefits

1. **No Duplication**: Each prayer is defined only once, not 4 times
2. **Maintainability**: Update a prayer in one place, not four
3. **Consistency**: Impossible to have mismatched translations
4. **Extensibility**: Easy to add more languages in the future
5. **Reusability**: Can be used for any bilingual content (Rosary prayers, consecration prayers, etc.)

## File Structure

```
app/Data/
├── BilingualPrayer.swift          # Core reusable models
├── TrueDevotionPrayers.swift      # Prayer definitions using bilingual models
└── TrueDevotionData.swift         # Main data file (uses bilingual prayers)
```

## How It Works

### 1. Define Prayer Once

```swift
BilingualPrayer(
    title: "Totus Tuus",
    content: BilingualText(
        english: "I am all Yours, and all that I have is Yours...",
        latin: "Totus Tuus ego sum, et omnia mea Tua sunt..."
    )
)
```

### 2. Format Automatically

The `BilingualText.formatted(for:)` method automatically generates the correct format:

- **English only**: Returns just the English text
- **Latin only**: Returns just the Latin text
- **Latin & English**: Returns `Latin text|||English text` for each line
- **English & Latin**: Returns `English text|||Latin text` for each line

### 3. Display with Existing Views

The existing `DevotionItemView` in TrueDevotionView.swift already knows how to parse the `|||` separator and format bilingual text with proper styling.

## Usage Example

### Define a Section of Bilingual Prayers

```swift
let prayers = BilingualSection(
    title: "Morning Prayers",
    icon: "sun.max.fill",
    items: [
        BilingualPrayer(
            title: "Morning Offering",
            content: BilingualText(
                english: "O Jesus, through the Immaculate Heart of Mary...",
                latin: "O Jesu, per Cor Mariae Immaculatum..."
            )
        ),
        BilingualPrayer(
            title: "Angelus",
            content: BilingualText(
                english: """
The Angel of the Lord declared unto Mary.
And she conceived of the Holy Spirit.
""",
                latin: """
Angelus Domini nuntiavit Mariae.
Et concepit de Spiritu Sancto.
"""
            )
        )
    ]
)
```

### Convert to DevotionSection for Display

```swift
// In your view or data provider:
let devotionSection = prayers.toDevotionSection(for: userSettings.prayerLanguage)
```

That's it! The section is now ready to display with the existing UI.

## Multi-line Prayers

For prayers with multiple lines, ensure both languages have the **same number of lines**:

```swift
BilingualText(
    english: """
Line 1 in English
Line 2 in English
Line 3 in English
""",
    latin: """
Line 1 in Latin
Line 2 in Latin
Line 3 in Latin
"""
)
```

The system will automatically pair them line-by-line with the `|||` separator.

## Extending the System

### Add More Languages

To support additional languages, extend the `BilingualText` struct:

```swift
struct BilingualText {
    let english: String
    let latin: String
    let spanish: String?  // Optional Spanish translation
    let french: String?   // Optional French translation
}
```

### Use for Other Content

This system works for **any** bilingual content:

```swift
// Rosary mysteries
let mysteries = BilingualSection(...)

// Consecration prayers
let consecrationPrayers = BilingualSection(...)

// Scripture meditations
let scriptureReflections = BilingualSection(...)
```

## Migration Notes

The old `ejaculatoryPrayersEnglish`, `ejaculatoryPrayersLatin`, `ejaculatoryPrayersBoth`, and `ejaculatoryPrayersLatinUnderEnglish` sections in TrueDevotionData.swift can now be **deleted**. They are replaced by:

```swift
static func allSections(prayerLanguage: PrayerLanguage) -> [DevotionSection] {
    let prayerSection = TrueDevotionPrayers.prayers.toDevotionSection(for: prayerLanguage)
    return [keyPrinciples, marksOfTrueDevotion, benefits, prayerSection, spirit]
}
```

This reduces ~400 lines of duplicated code to ~100 lines of efficient, reusable code.

## Before vs After

### Before (Old System)
```
TrueDevotionData.swift: 650 lines
- ejaculatoryPrayersEnglish: 10 prayers × 15 lines = 150 lines
- ejaculatoryPrayersLatin: 10 prayers × 15 lines = 150 lines
- ejaculatoryPrayersBoth: 10 prayers × 15 lines = 150 lines
- ejaculatoryPrayersLatinUnderEnglish: 10 prayers × 15 lines = 150 lines
Total prayer code: ~600 lines
```

### After (New System)
```
BilingualPrayer.swift: 110 lines (reusable!)
TrueDevotionPrayers.swift: 140 lines (all 10 prayers defined once)
TrueDevotionData.swift: 300 lines (prayers section removed)
Total prayer code: ~250 lines
```

**Savings: ~350 lines, 58% reduction!**

## Testing Checklist

After switching to the new system:

- [ ] English-only mode displays English prayers correctly
- [ ] Latin-only mode displays Latin prayers correctly
- [ ] "Latin & English" mode shows Latin primary, English secondary
- [ ] "English & Latin" mode shows English primary, Latin secondary
- [ ] Multi-line prayers align correctly line-by-line
- [ ] Visual hierarchy (16pt primary, 13pt italic secondary) works
- [ ] Settings changes immediately update the displayed prayers
