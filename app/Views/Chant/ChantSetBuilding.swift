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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    .font(AppFonts.labelFont(12))
                    .foregroundColor(AppColors.goldLight)
                    .monospacedDigit()
                    .contentTransition(.chantCount(reduceMotion: reduceMotion))
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
                // So the sheet's drag indicator reads over it
                LinearGradient(colors: [.black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: height * 0.45)
            }
            .overlay(alignment: .topTrailing) {
                // A pool of shade where CANCEL stands
                RadialGradient(
                    colors: [.black.opacity(0.75), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 140
                )
                .frame(width: 200, height: height * 0.8)
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
                    Text(detail)
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
                [set.name, holds, ChantAddRing.spoken(count)].compactMap { $0 }.joined(separator: ", ")
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            ChantRule(opacity: 0.12)
                .padding(.leading, SheetMetrics.gutter + 56)
        }
        .accessibilityHint("Adds the chant to the end of this set")
    }

    /// What the set holds, counted as the picker's foot counts it, every
    /// repeat included: "4 chants · 23 min", or as its page says when it
    /// holds no chant
    private var holds: String {
        self.set.sungCount == 0 ? "Nothing in it yet" : ChantSetCard.summary(count: set.sungCount, duration: set.duration)
    }

    /// The line under the set's name, short enough to stand on one line:
    /// "Already in it · 4 chants · 23 min"
    private var detail: String {
        count > 0 ? "Already in it · \(holds)" : holds
    }
}

// MARK: - Paintings and short names

extension ChantGroup {
    /// The painting the section hangs in the picker. The curation gives
    /// the Mass's sections all the Last Supper and Our Lady's all the
    /// Coronation, which stacked in one list read as the same band again;
    /// a neighbour takes a painting of its own subject instead: the
    /// Baptism for the holy water, the Trinity for the Creed, the
    /// Visitation for Mary's Magnificat, All Saints for the litanies.
    var painting: String {
        switch id {
        case "asperges":  return "luminous_baptism"
        case "creed":     return "devotion_holy_trinity"
        case "canticles": return "joyful_visitation"
        case "litanies":  return "feast_all_saints"
        default:          return ChantLibraryData.groupPaintings[id] ?? ChantSet.emptyPainting
        }
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
    /// The painting a set wears while it holds no chant, as on its page:
    /// Our Lady in glory, as over the library's hymns to her
    static let emptyPainting = "mary_sistine_madonna"

    /// The painting the set wears: its first chant's, as on its own page,
    /// or Our Lady in glory while it holds none
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

    /// How many chants are sung in the set, each repeat counted, as the
    /// picker's rings count them
    var sungCount: Int {
        items.reduce(0) { total, item in
            if case .chant(_, let times) = item.kind { return total + max(1, times) }
            return total
        }
    }

    /// The foot of the picker, counting what the rings count: "In the set:
    /// 3 chants · 7 min", in the words of the library's set cards
    var tally: String {
        guard sungCount > 0 else { return "Nothing in the set yet" }
        return "In the set: " + ChantSetCard.summary(count: sungCount, duration: duration)
    }
}
