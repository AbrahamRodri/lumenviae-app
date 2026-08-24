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

    @MainActor
    func load() async {
        guard proper == nil else { return }

        let day = MissalAPIService.dayString(for: .now)

        if let stored = diskCache.loadProper(for: day)?.first {
            proper = stored
            return
        }

        guard let fetched = try? await api.fetchPropers(day: day), !fetched.isEmpty else { return }

        diskCache.saveProper(fetched, for: day)
        proper = fetched.first
    }
}

// MARK: - TodayInChurchSection

/// "Today": the feast at the head of the card, and the day's three
/// books standing on a shelf beneath it. Unlike every other card in
/// the app on purpose — this one is furniture, not a ledger.
struct TodayInChurchSection: View {

    let today: TodayInChurch

    @Environment(AppRouter.self) private var router

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    private var activeConsecration: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TODAY")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Spacer()

                Text(dateLine)
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(today.title)
                .font(AppFonts.headlineFont(24))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)
                .id(today.title)
                .transition(.opacity)

            if let meta = today.meta {
                Text(meta)
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.gold.opacity(0.85))
                    .transition(.opacity)
            }

            bookshelf
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 30)
        .background(AppColors.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 0.5)
        )
        .animation(.easeOut(duration: 0.35), value: today.title)
        .accessibilityElement(children: .contain)
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

    private var bookshelf: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 14) {
                BookSpine(
                    title: "The Mass",
                    foot: "Missale",
                    spine: Color(hex: "4a2430"),
                    // The missal wears the day's ribbon
                    ribbon: today.vestment?.swatch ?? AppColors.gold.opacity(0.6),
                    ribbonX: -20,
                    height: 225
                ) {
                    router.push(.missal)
                }

                BookSpine(
                    title: "The Office",
                    foot: presentHourName,
                    spine: Color(hex: "191922"),
                    ribbon: nil,
                    ribbonX: 0,
                    height: 205
                ) {
                    router.push(.office)
                }

                // Mid-consecration, the blue book is the user's own copy
                // — footed with their day, opening their preparation.
                // Otherwise it is Montfort's, opening the reader.
                BookSpine(
                    title: "True Devotion",
                    foot: activeConsecration.map { "Day \(min($0.currentDayNumber, 33))" } ?? "The Book",
                    spine: Color(hex: "2e3d66"),
                    ribbon: AppColors.goldLight,
                    ribbonX: 20,
                    height: 195
                ) {
                    if activeConsecration != nil {
                        router.selectedTab = .consecration
                    } else {
                        router.push(.trueDevotion)
                    }
                }
            }

            // The board they stand on — lit along its front edge so it
            // reads as wood, not shadow
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "1d1727"))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                }
                .frame(height: 10)
                .padding(.horizontal, 10)
                .shadow(color: .black.opacity(0.55), radius: 10, y: 8)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: 330)
    }
}

// MARK: - BookSpine

/// One standing volume: gold rules at head and tail, the title down the
/// spine, a raised hinge band, and a small foot label — with an optional
/// ribbon showing above the pages.
private struct BookSpine: View {

    let title: String
    let foot: String
    let spine: Color
    let ribbon: Color?
    let ribbonX: CGFloat
    let height: CGFloat
    let action: () -> Void

    /// Vertical room left for the rotated title once the rules, hinge,
    /// and foot compartment have taken theirs.
    private var titleArea: CGFloat {
        height - 98
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                rules
                    .padding(.top, 13)

                // The title down the spine. Constrained to the title
                // area BEFORE rotation, so a long name scales to fit
                // instead of running over the rules and the foot.
                Text(title.uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(3.5)
                    .foregroundColor(AppColors.goldLight.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: max(40, titleArea - 10))
                    .rotationEffect(.degrees(90))
                    .frame(maxWidth: .infinity)
                    .frame(height: titleArea)

                // The hinge band above the tail compartment
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .frame(height: 4)

                ZStack {
                    Text(foot.uppercased())
                        .font(AppFonts.labelFont(8))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.65))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 48)
                        .rotationEffect(.degrees(90))
                }
                .frame(height: 58)

                rules
                    .padding(.bottom, 13)
            }
            .frame(width: 86, height: height)
            .background(
                ZStack {
                    spine
                    // The spine's rounding: lit at the fore-edge,
                    // falling into shadow at the hinge
                    LinearGradient(
                        colors: [
                            .white.opacity(0.12),
                            .clear,
                            .black.opacity(0.22)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            )
            .cornerRadius(5)
            .overlay(alignment: .top) {
                if let ribbon {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(ribbon)
                        .frame(width: 8, height: 20)
                        .offset(x: ribbonX, y: -12)
                        .accessibilityHidden(true)
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(foot)")
    }

    /// The pair of gilt rules struck across the spine's head and tail
    private var rules: some View {
        VStack(spacing: 3) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.55))
                .frame(height: 1)
            Rectangle()
                .fill(AppColors.gold.opacity(0.55))
                .frame(height: 1)
        }
        .padding(.horizontal, 13)
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
