//
//  ChantSetBuilding.swift
//  Lumen Viae
//
//  The pieces the sheets that build a sung set share: a chant or a set
//  as a row with its painting, the ring at its edge that adds it, the
//  book's sections under their paintings, and the short names the
//  picker's strip of sections gives them.
//

import SwiftUI

// MARK: - ChantAddRing

/// The ring at a row's trailing edge: a plus while the chant is not in the
/// set, and once it is, how many times ("×2"), lit. A tap always adds it
/// again, so the ring never shows a check, which would read as a toggle
/// that takes it out.
struct ChantAddRing: View {
    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(count > 0 ? AppColors.gold.opacity(0.16) : Color.clear)
            Circle()
                .strokeBorder(
                    count > 0 ? AppColors.gold : AppColors.gold.opacity(0.32),
                    lineWidth: AppLine.hairline
                )
            if count > 0 {
                Text("×\(count)")
                    .font(AppFonts.labelFont(10))
                    .foregroundColor(AppColors.goldLight)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            } else {
                AppIcon("ph-plus", size: 13)
                    .foregroundColor(AppColors.gold)
            }
        }
        .frame(width: 32, height: 32)
        .animation(Motion.settle, value: count)
        .accessibilityHidden(true)
    }

    /// What VoiceOver hears of the ring's state
    static func spoken(_ count: Int) -> String? {
        switch count {
        case 0: return nil
        case 1: return "In the set"
        case 2: return "In the set twice"
        default: return "In the set \(count) times"
        }
    }
}

// MARK: - ChantAddRow

/// A chant in the picker: its painting, its names, its length, and the ring
/// that adds it. The whole row is the tap.
struct ChantAddRow: View {
    let chant: Chant
    let count: Int
    let add: () -> Void

    var body: some View {
        Button(action: add) {
            HStack(spacing: 12) {
                ChantThumbnail(name: ChantCatalog.painting(for: chant), size: 44, radius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(chant.latinTitle)
                        .font(AppFonts.readingFont(16.5))
                        .foregroundColor(count > 0 ? AppColors.goldLight : AppColors.cream)
                        .lineLimit(1)
                    Text(chant.settingMidLine.map { "\(chant.englishTitle) · \($0)" } ?? chant.englishTitle)
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(chant.durationLabel)
                    .font(AppFonts.readingFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
                    .monospacedDigit()

                ChantAddRing(count: count)
            }
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                [chant.spokenName, chant.settingMidLine, ChantPlayer.spoken(chant.duration), ChantAddRing.spoken(count)]
                    .compactMap { $0 }
                    .joined(separator: ", ")
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            ChantRule(opacity: 0.12)
                .padding(.leading, SheetMetrics.gutter + 56)
        }
        .accessibilityHint(count > 0 ? "Adds it again at the end of the set" : "Adds it to the end of the set")
    }
}

// MARK: - ChantSectionBand

/// A section of the book under its painting: a short band dissolving into
/// the page, the section's name standing on its foot.
struct ChantSectionBand: View {
    let group: ChantGroup

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ChantPainting(name: group.painting, height: 64, dissolveFrom: 0.1)
                .opacity(0.75)

            Text(group.title)
                .font(AppFonts.titleFont(16))
                .foregroundColor(AppColors.cream)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.6), radius: 6)
                .padding(.horizontal, SheetMetrics.gutter)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .bottomLeading)
        .padding(.top, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(group.title)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - ChantHeadPainting

/// A painting hung at the head of a sheet, cut about the point that holds
/// its faces, darkened under the sheet's chrome and dissolving to clear at
/// its foot, so the title beneath stands on the page.
struct ChantHeadPainting: View {
    let name: String
    var height: CGFloat = 150
    var focal = UnitPoint(x: 0.5, y: 0.3)

    var body: some View {
        CachedAssetImage(name, focal: focal)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .top) {
                // So the sheet's drag indicator and CANCEL read over it
                LinearGradient(colors: [.black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: height * 0.45)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.35),
                        .init(color: .black.opacity(0.35), location: 0.7),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityHidden(true)
    }
}

// MARK: - ChantSetRow

/// A set of the reader's own, for a chant to be put in: its painting, its
/// name, what it holds, and the ring that says whether the chant is in it.
struct ChantSetRow: View {
    let set: ChantSet
    /// How many times the chant being added is already in the set
    let count: Int
    let add: () -> Void

    var body: some View {
        Button(action: add) {
            HStack(spacing: 12) {
                ChantThumbnail(name: set.painting, size: 44, radius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(set.name)
                        .font(AppFonts.readingFont(16.5))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                    Text(set.summary)
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                ChantAddRing(count: count)
            }
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                [set.name, set.summary, ChantAddRing.spoken(count)].compactMap { $0 }.joined(separator: ", ")
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            ChantRule(opacity: 0.12)
                .padding(.leading, SheetMetrics.gutter + 56)
        }
        .accessibilityHint("Adds the chant to the end of this set")
    }
}

// MARK: - Paintings and short names

extension ChantGroup {
    /// The painting the section hangs: the curation's for it
    var painting: String {
        ChantLibraryData.groupPaintings[id] ?? "glorious_coronation"
    }

    /// The section's name in the picker's strip, where the book's whole
    /// title has no room
    var shortTitle: String {
        switch id {
        case "asperges": return "Asperges"
        case "mass": return "Mass"
        case "creed": return "Creed"
        case "sequences": return "Sequences"
        case "requiem": return "For the Dead"
        case "hymns": return "Hymns"
        case "ourLady": return "Our Lady"
        case "seasons": return "Seasons"
        case "canticles": return "Canticles"
        case "litanies": return "Litanies"
        case "benediction": return "Benediction"
        case "rosary": return "Rosary"
        default: return title
        }
    }
}

extension ChantSet {
    /// The painting a set wears while it holds no chant, as on its page
    static let emptyPainting = "glorious_coronation"

    /// The painting the set wears: its first chant's, as on its own page,
    /// or the Coronation while it holds none
    var painting: String {
        items.lazy.compactMap(\.chant).first.map { ChantCatalog.painting(for: $0) } ?? Self.emptyPainting
    }

    /// How many times `chantID` is sung in the set, its repeats included
    func count(of chantID: String) -> Int {
        items.reduce(0) { total, item in
            if case .chant(let id, let times) = item.kind, id == chantID { return total + max(1, times) }
            return total
        }
    }

    /// The foot of the picker: "2 chants in the set · 5 min"
    var tally: String {
        guard chantCount > 0 else { return "Nothing in the set yet" }
        let chants = chantCount == 1 ? "1 chant in the set" : "\(chantCount) chants in the set"
        let minutes = Int((duration / 60).rounded())
        return minutes > 0 ? "\(chants) · \(minutes) min" : chants
    }
}
