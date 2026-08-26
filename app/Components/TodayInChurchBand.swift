//
//  TodayInChurchBand.swift
//  Lumen Viae
//
//  "Today" — the Church's day as a shelf of books, closing the home
//  page: the feast and its rank up top, and beneath them the day's
//  three volumes standing on a board — the Missal, the Breviary, and
//  True Devotion. Each spine is a door, and each carries the day on
//  itself: the Mass book wears the vestment colour as its ribbon, the
//  Office is footed with the present canonical hour, and True Devotion
//  shows the consecration day when one is under way.
//

import SwiftUI
import SwiftData

// MARK: - TodayInChurch

/// Today's celebration, loaded once for the home screen.
///
/// Deliberately not `MissalViewModel`: that one owns a reader — stepping
/// days, retry copy, a week of prefetch — and the home screen wants one
/// fact. A stored day is read first and answers instantly, because the
/// propers for a date never change once published.
///
/// Every failure is silent. This is the app's most important screen, and
/// a third-party outage must never make it look broken — the band simply
/// keeps its plain title and the Mass stays one tap away.
@Observable
final class TodayInChurch {

    private(set) var proper: MissalProper?

    private let api = MissalAPIService.shared
    private let diskCache = MissalCacheService.shared

    /// The feast, once known. Until then the band names the thing itself.
    var title: String {
        proper?.info.title ?? "The Mass of the Day"
    }

    /// "Double of the II Class · Red", whichever parts the day carries
    var meta: String? {
        let parts = [proper?.info.rankLabel, vestment?.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }

    var vestment: MissalVestment? {
        proper?.info.colors?.first.flatMap { MissalVestment(rawValue: $0) }
    }

    /// The day the loaded proper belongs to, so a band that was correct
    /// last night can tell that it no longer is.
    private var loadedDay: String?

    @MainActor
    func load() async {
        let day = MissalAPIService.dayString(for: .now)
        // Keyed on the day rather than on "have we loaded": Home is the
        // launch tab and does not rebuild on foreground, so an app left
        // open overnight kept yesterday's feast, rank, and vestment
        // colour on screen while THE MASS opened the right one.
        guard proper == nil || loadedDay != day else { return }

        if let stored = diskCache.loadProper(for: day)?.first {
            proper = stored
            loadedDay = day
            return
        }

        guard let fetched = try? await api.fetchPropers(day: day), !fetched.isEmpty else { return }

        diskCache.saveProper(fetched, for: day)
        proper = fetched.first
        loadedDay = day
    }
}

// MARK: - TodayInChurchSection

/// "Today in the Church": the day named in type, and beneath it the
/// three books drawn as bound volumes standing spine-out on a shelf —
/// the Missal, the Breviary, and True Devotion, each spine a door and
/// each carrying its own live state at the tail. Built to the shelf
/// handoff (variant 2A), but backgroundless: no card, no border — the
/// shelf stands directly on the page like the rest of home.
struct TodayInChurchSection: View {

    let today: TodayInChurch

    @Environment(AppRouter.self) private var router

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    private var activeConsecration: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 22)

            shelf
        }
        .animation(.easeOut(duration: 0.35), value: today.title)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text("TODAY IN THE CHURCH")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.6)
                    .foregroundColor(AppColors.gold.opacity(0.78))

                Spacer()

                Text(dateLine)
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(today.title)
                .font(AppFonts.headlineFont(23))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)
                .id(today.title)
                .transition(.opacity)

            if let meta = today.meta {
                Text(meta)
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.accentSoft)
                    .transition(.opacity)
            }
        }
    }

    /// "MONDAY, AUGUST 24"
    private var dateLine: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
            .uppercased()
    }

    // MARK: - The shelf

    /// The present canonical hour foots the Office spine, the same fact
    /// the Office ledger marks with its gold dot.
    private var presentHourName: String {
        CanonicalHour.present(
            atClockHour: Calendar.current.component(.hour, from: Date())
        ).label
    }

    private var shelf: some View {
        VStack(spacing: -1) {
            // The books stand on the plank's hairline and paint above it
            HStack(alignment: .bottom, spacing: 7) {
                ShelfSpine(
                    title: ["THE MASS"],
                    tail: "MISSALE",
                    leather: Color(hex: "2B1016"),
                    width: 92, height: 248,
                    titleSize: 13.5, titleTracking: 3.4,
                    giltOpacity: (0.50, 0.24),
                    litStop: 0.13,
                    ruleInset: 9,
                    verticalPadding: (24, 22),
                    bandMargin: 10,
                    // The missal wears the day's silk in the vestment
                    // colour, standing above the head of the book
                    ribbon: RibbonSpec(
                        color: liturgicalRibbon,
                        size: CGSize(width: 6, height: 16),
                        edge: .leading, inset: 20, rise: 14
                    ),
                    accessibility: "The Mass, today's propers"
                ) {
                    router.push(.missal)
                }

                ShelfSpine(
                    title: ["THE OFFICE"],
                    tail: presentHourName.uppercased(),
                    leather: Color(hex: "14141C"),
                    width: 80, height: 232,
                    titleSize: 12.5, titleTracking: 3.2,
                    giltOpacity: (0.45, 0.22),
                    litStop: 0.11,
                    ruleInset: 9,
                    verticalPadding: (24, 22),
                    bandMargin: 10,
                    ribbon: nil,
                    accessibility: "The Office, \(presentHourName)"
                ) {
                    router.push(.office)
                }

                // Mid-consecration, the blue book is the user's own copy
                // — its tail carries their day, and it opens their
                // preparation. Otherwise it is Montfort's, and opens
                // the reader.
                ShelfSpine(
                    title: ["TRUE", "DEVOTION"],
                    tail: activeConsecration.map { "DAY \(min($0.currentDayNumber, 33))" } ?? "MONTFORT",
                    leather: Color(hex: "16244A"),
                    width: 72, height: 220,
                    titleSize: 11.5, titleTracking: 3.0,
                    giltOpacity: (0.45, 0.22),
                    litStop: 0.11,
                    ruleInset: 8,
                    verticalPadding: (22, 20),
                    bandMargin: 9,
                    ribbon: RibbonSpec(
                        color: AppColors.gold.opacity(0.8),
                        size: CGSize(width: 5, height: 14),
                        edge: .trailing, inset: 18, rise: 12
                    ),
                    accessibility: activeConsecration.map { "True Devotion, day \(min($0.currentDayNumber, 33))" } ?? "True Devotion, the book"
                ) {
                    if activeConsecration != nil {
                        router.selectedTab = .consecration
                    } else {
                        router.push(.trueDevotion)
                    }
                }
            }
            .zIndex(2)

            plank
                .zIndex(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    /// The liturgical colours are content, not accents: a small set of
    /// their own, deeper than the vestment swatches the calendar sheet
    /// uses, so the silk reads as cloth against the leather.
    private var liturgicalRibbon: Color {
        switch today.vestment {
        case .red:    return Color(hex: "8E1B28")
        case .white:  return Color(hex: "EFE6CE")
        case .green:  return Color(hex: "2E6B4A")
        case .violet: return Color(hex: "4B2E6B")
        case .rose:   return Color(hex: "B06A83")
        case .black:  return Color(hex: "1A1A22")
        case nil:     return AppColors.gold.opacity(0.8)
        }
    }

    private var plank: some View {
        VStack(spacing: 0) {
            // The lit top edge, fading out before either end
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: AppColors.gold.opacity(0.42), location: 0.22),
                    .init(color: AppColors.gold.opacity(0.42), location: 0.78),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            // The front face
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 3,
                bottomTrailingRadius: 3, topTrailingRadius: 0
            )
            .fill(
                LinearGradient(
                    colors: [Color(hex: "221A26"), Color(hex: "0F0B13")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 11)

            // The shadow it casts on the page
            LinearGradient(
                colors: [.black.opacity(0.55), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)
        }
        .frame(width: 302)
        .accessibilityHidden(true)
    }
}

// MARK: - ShelfSpine

/// The silk marker standing above a book's head.
private struct RibbonSpec {
    let color: Color
    let size: CGSize
    let edge: HorizontalAlignment
    let inset: CGFloat
    let rise: CGFloat
}

/// One bound volume, spine out: leather under cylindrical shading, gilt
/// double rules at head and tail, the title reading down the spine, a
/// raised band, and the book's live state as a tail imprint. Uneven
/// heights across the shelf are intentional — books on a real shelf do
/// not align at the top; they align at the plank.
private struct ShelfSpine: View {

    let title: [String]
    let tail: String
    let leather: Color
    let width: CGFloat
    let height: CGFloat
    let titleSize: CGFloat
    let titleTracking: CGFloat
    let giltOpacity: (Double, Double)
    /// The white stop of the cylindrical shading at the hinge edge
    let litStop: Double
    let ruleInset: CGFloat
    let verticalPadding: (top: CGFloat, bottom: CGFloat)
    let bandMargin: CGFloat
    let ribbon: RibbonSpec?
    let accessibility: String
    let action: () -> Void

    /// The tail compartment is content-sized: a longer imprint pushes
    /// its band higher up the spine, so the three ridges land at
    /// different heights across the shelf — books bound by different
    /// hands, not a printed row of tiles.
    private var tailBox: CGFloat {
        min(84, CGFloat(tail.count) * 10 + 12)
    }

    /// Vertical room for the title once padding, band, and tail have
    /// taken theirs.
    private var titleArea: CGFloat {
        height - verticalPadding.top - verticalPadding.bottom
            - 5 - bandMargin * 2 - tailBox
    }

    private var spineShape: UnevenRoundedRectangle {
        // Rounder at the fore-edge than the hinge, like a real binding
        UnevenRoundedRectangle(
            topLeadingRadius: 3, bottomLeadingRadius: 3,
            bottomTrailingRadius: 6, topTrailingRadius: 6
        )
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Title centred in the space above the band
                titleView
                    .frame(maxHeight: .infinity)

                raisedBand
                    .padding(.vertical, bandMargin)

                verticalText(
                    tail,
                    size: 9.5, tracking: 2.2,
                    color: AppColors.gold.opacity(0.72),
                    length: tailBox - 2
                )
                .frame(height: tailBox)
            }
            .padding(.top, verticalPadding.top)
            .padding(.bottom, verticalPadding.bottom)
            .frame(width: width, height: height)
            .background(leatherAndShading)
            .overlay(giltRules)
            .clipShape(spineShape)
            // The contact shadow where the book meets the plank
            .background(alignment: .bottom) {
                RadialGradient(
                    colors: [.black.opacity(0.6), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 12
                )
                .frame(width: width + 12, height: 12)
                .offset(y: 8)
            }
            // The head ribbon stands above the clip
            .overlay(alignment: ribbon?.edge == .leading ? .topLeading : .topTrailing) {
                if let ribbon {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 1, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 1
                    )
                    .fill(ribbon.color)
                    .frame(width: ribbon.size.width, height: ribbon.size.height)
                    .shadow(color: .black.opacity(0.5), radius: 2.5)
                    .offset(
                        x: ribbon.edge == .leading ? ribbon.inset : -ribbon.inset,
                        y: -ribbon.rise
                    )
                    .accessibilityHidden(true)
                }
            }
            .contentShape(spineShape)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(accessibility)
    }

    // MARK: Layers

    /// Leather under the cylindrical shading — the horizontal ramp is
    /// what makes the spine read as a round back rather than a tile.
    private var leatherAndShading: some View {
        ZStack {
            leather

            LinearGradient(
                stops: [
                    .init(color: .white.opacity(litStop), location: 0),
                    .init(color: .white.opacity(0.02), location: 0.18),
                    .init(color: .black.opacity(0.05), location: 0.62),
                    .init(color: .black.opacity(0.46), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    /// Double rules at the head, mirrored at the tail
    private var giltRules: some View {
        VStack(spacing: 0) {
            giltPair
                .padding(.top, 14)

            Spacer(minLength: 0)

            giltPair
                .padding(.bottom, 14)
        }
    }

    private var giltPair: some View {
        VStack(spacing: 3) {
            Rectangle()
                .fill(AppColors.gold.opacity(giltOpacity.0))
                .frame(height: 1)
            Rectangle()
                .fill(AppColors.gold.opacity(giltOpacity.1))
                .frame(height: 1)
        }
        .padding(.horizontal, ruleInset)
    }

    /// The raised band above the tail compartment
    private var raisedBand: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.white.opacity(0.11), .black.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 5)
    }

    /// One or two vertical columns. Reversed for layout: rotated spine
    /// columns are read with the head tilted right, which makes the
    /// RIGHT column the first line — so the title's first word takes
    /// the right column, and "TRUE / DEVOTION" reads as True Devotion,
    /// not Devotion True.
    private var titleView: some View {
        HStack(spacing: 2) {
            ForEach(title.reversed(), id: \.self) { column in
                verticalText(
                    column,
                    size: titleSize, tracking: titleTracking,
                    color: AppColors.goldLight,
                    length: titleArea - 6,
                    shadowed: true
                )
            }
        }
    }

    /// Text set down the spine: laid out horizontally, then turned to
    /// read top-to-bottom. Constrained BEFORE rotation so a long word
    /// scales to fit rather than running over the rules.
    private func verticalText(
        _ string: String,
        size: CGFloat,
        tracking: CGFloat,
        color: Color,
        length: CGFloat,
        shadowed: Bool = false
    ) -> some View {
        Text(string)
            .font(AppFonts.labelFont(size))
            .tracking(tracking)
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .shadow(
                color: .black.opacity(shadowed ? 0.5 : 0),
                radius: 0, y: 1
            )
            .frame(width: max(30, length))
            .rotationEffect(.degrees(90))
            .frame(width: size + 6, height: max(30, length))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.appGradient.ignoresSafeArea()

        TodayInChurchSection(today: TodayInChurch())
            .environment(AppRouter())
            .padding(.horizontal, 20)
    }
    .modelContainer(for: ConsecrationProgress.self, inMemory: true)
}
