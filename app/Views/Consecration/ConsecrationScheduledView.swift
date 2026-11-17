//
//  ConsecrationScheduledView.swift
//  Lumen Viae
//
//  The tab's page for a consecration chosen ahead of its feast, until
//  its Day 1 comes: the road ahead (design's option C, Abraham's pick,
//  17 Nov 2026). The feast is the title over its date, and the five
//  parts of the preparation stand on one gold line, each with the date
//  it begins. Nothing on the page is a button: the book and the way back
//  to the feasts stand in the ··· menu. No day of it is open yet
//  (`ConsecrationProgress.hasBegun`), and on Day 1 the tab turns to the
//  day's own page by itself.
//

import SwiftUI

struct ConsecrationScheduledView: View {

    /// Day 1, at the start of its day
    let start: Date

    @Binding var path: [ConsecrationRoute]

    @Environment(ConsecrationViewModel.self) private var viewModel

    /// The day the Spanish beta strip was last closed (`SpanishBeta`)
    @AppStorage(SpanishBeta.closedOnKey) private var spanishStripClosedOn = ""

    /// The feast the 33 days end on: Consecration Day
    private var feast: MarianFeastDay? {
        MarianFeastDay.feast(endingPreparationFrom: start)
    }

    private var feastDate: Date {
        Calendar.current.date(byAdding: .day, value: 33, to: start) ?? start
    }

    private var daysUntilStart: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: start)
        ).day ?? 0
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    titleBlock
                        .padding(.top, 236)
                        .devotionalEntrance()

                    road
                        .padding(.top, 34)
                        .devotionalEntrance(delay: 0.08)

                    Text("Day 1 opens here on \(Self.dayAndDate(start)).", comment: "Consecration, scheduled page: the quiet line at the foot saying when the first day's prayers open, like Day 1 opens here on Saturday, January 9.")
                        .font(AppFonts.italicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .devotionalEntrance(delay: 0.16)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                // The painting rides with the page, behind the title
                .background(alignment: .top) {
                    plate
                }
                // Clear of the tab bar
                .padding(.bottom, 120)
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea(edges: .top)

            moreMenu
                .padding(.trailing, 14)
                // Under the Spanish beta strip, which the tab's own
                // navigation stack does not count in its safe area
                .padding(.top, 2 + (SpanishBeta.showsStrip(closedOn: spanishStripClosedOn) ? SpanishBetaStrip.height : 0))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Painting

    /// The Coronation, the picture of Consecration Day itself: the page
    /// looks to where the road ends
    private var plate: some View {
        CachedAssetImage(ConsecrationPhase.consecrationDay.heroImageName, focal: UnitPoint(x: 0.5, y: 0.25))
            .frame(maxWidth: .infinity)
            .frame(height: 380)
            .clipped()
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.4), location: 0),
                        .init(color: .black.opacity(0), location: 0.3),
                        .init(color: AppColors.background.opacity(0.75), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.55),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - More

    /// The two doors the page once showed as gold links: the book the
    /// consecration comes from, and the way back to the feasts
    private var moreMenu: some View {
        Menu {
            Button {
                path.append(.trueDevotionReader)
            } label: {
                Label(
                    String(localized: "Read True Devotion to Mary", comment: "Consecration, scheduled page: menu item opening Montfort's book True Devotion to Mary"),
                    systemImage: "book"
                )
            }

            Button {
                // Nothing is lost: no day of it has been prayed
                withAnimation(Motion.crossfade) {
                    viewModel.abandonConsecration()
                }
            } label: {
                Label(
                    String(localized: "Choose another feast", comment: "Consecration, scheduled page: menu item that lets go of the chosen feast to choose another"),
                    systemImage: "calendar"
                )
            }
        } label: {
            AppIcon("ph-dots-three", size: 18)
                .foregroundColor(.white)
                .padding(13)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
        }
        .accessibilityLabel(Text("More options", comment: "Consecration, scheduled page: VoiceOver name of the round button that opens the menu"))
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Your Consecration to Mary", comment: "Consecration, scheduled page: kicker over the chosen feast's name while the preparation has not begun").uppercased())
                .font(AppFonts.labelFont(12))
                .tracking(3.5)
                .foregroundColor(AppColors.gold)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

            // The feast's name, or the date when the day chosen has none
            Text(feast?.name ?? Self.fullDate(feastDate))
                .font(AppFonts.headlineFont(28))
                .foregroundColor(AppColors.cream)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
                .accessibilityAddTraits(.isHeader)

            if feast != nil {
                Text(Self.fullDate(feastDate))
                    .font(AppFonts.italicFont(19))
                    .foregroundColor(AppColors.accentSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The road

    private var road: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(roadLabel.uppercased())
                .font(AppFonts.labelFont(11))
                .tracking(3)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 22)

            ForEach(Array(ConsecrationPhase.allCases.enumerated()), id: \.element) { index, phase in
                roadRow(phase, isLast: index == ConsecrationPhase.allCases.count - 1)
            }
        }
    }

    private var roadLabel: String {
        daysUntilStart <= 1
            ? String(localized: "The road there · begins tomorrow", comment: "Consecration, scheduled page: small capitals over the five parts of the preparation, when Day 1 is tomorrow")
            : String(localized: "The road there · begins in \(daysUntilStart) days", comment: "Consecration, scheduled page: small capitals over the five parts of the preparation, like The road there · begins in 53 days")
    }

    /// One part of the preparation: a ring on the gold line, the date it
    /// begins, its name and how long it is. Not a door.
    private func roadRow(_ phase: ConsecrationPhase, isLast: Bool) -> some View {
        let begins = Calendar.current.date(byAdding: .day, value: phase.dayRange.lowerBound - 1, to: start) ?? start

        return HStack(alignment: .top, spacing: 0) {
            // The ring, and the line on to the next
            VStack(spacing: 0) {
                ZStack {
                    if isLast {
                        Circle()
                            .fill(AppColors.gold)
                            .frame(width: 13, height: 13)
                            .shadow(color: AppColors.gold.opacity(0.7), radius: 6)
                    } else {
                        Circle()
                            .stroke(AppColors.gold, lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                    }
                }
                .frame(width: 14, height: 14)
                .padding(.top, 5)

                if !isLast {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.55))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 14)

            Text(begins.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                .font(AppFonts.labelFont(11))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 72, alignment: .leading)
                .padding(.leading, 18)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(isLast ? phase.displayName : phase.subtitle)
                    .font(AppFonts.bodyFont(19))
                    .foregroundColor(isLast ? AppColors.goldLight : AppColors.cream)
                    .fixedSize(horizontal: false, vertical: true)

                if let note = Self.note(for: phase, feast: feast) {
                    Text(note)
                        .font(AppFonts.italicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, isLast ? 0 : 24)

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Words

    /// How long a part is, or the feast Consecration Day falls on
    static func note(for phase: ConsecrationPhase, feast: MarianFeastDay?) -> String? {
        switch phase {
        case .preparatory:
            return String(localized: "Twelve days", comment: "Consecration, scheduled page: how long the first part of the preparation is, under its name")
        case .knowledgeOfSelf, .knowledgeOfMary, .knowledgeOfJesus:
            return String(localized: "A week", comment: "Consecration, scheduled page: how long one of the three weeks of the preparation is, under its name")
        case .consecrationDay:
            guard let feast else { return nil }
            return String(localized: "The feast of \(feast.name)", comment: "Consecration, scheduled page: under Consecration Day, the feast it falls on, like The feast of Our Lady of Lourdes")
        }
    }

    /// "Thursday, February 11, 2027": the consecration's date in full
    static func fullDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    /// "Saturday, January 9"
    static func dayAndDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationScheduledView(
            start: Calendar.current.date(byAdding: .day, value: 12, to: Calendar.current.startOfDay(for: .now))!,
            path: .constant([])
        )
        .environment(ConsecrationViewModel())
    }
}
