//
//  DivineOfficeView.swift
//  Lumen Viae
//
//  The Divine Office: the pre-Vatican II Breviarium Romanum under the
//  1960 rubrics, served by the Lumen Viae API from the Divinum Officium
//  engine.
//
//  The screen has one purpose — get the reader into the hour that is
//  current, in one tap — so the hour it is now is lifted out of the
//  eight and set in a lit lancet arch with the page's single gold act
//  beneath it. Every other card in the app is a 16pt rectangle; making
//  this one an arch means the eye lands on it before reading a word.
//
//  The eight still stand below, grouped the way a breviary groups them
//  and strung on one strand of light, each bead in the colour of its own
//  time of day — the strand runs dark through bright and back to dark
//  over the course of a day.
//
//  English in the chrome. The engine answers in Latin ("III. classis",
//  "S. Josephi Calasanctii Confessoris") and Latin belongs in the prayer
//  text, not above it, so the rank is mapped client-side.
//
//  Nothing here waits on the network: the hours are the hours, and the
//  arch's choice of hour is read from the clock. Only the day's feast
//  travels, and when it cannot be reached the page says so quietly and
//  leaves every hour tappable.
//

import SwiftUI

struct DivineOfficeView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel = OfficeViewModel()
    @State private var openHour: CanonicalHour?
    @State private var showCalendar = false

    private var clock = CanonicalClock.shared

    /// Whether the three group headings render. With them off the eight
    /// read as one continuous strand.
    private let showHourGroups = true

    // MARK: - Groups

    /// The hours as a breviary groups them
    private struct HourGroup: Identifiable {
        let heading: String
        let hours: [CanonicalHour]
        var id: String { heading }
    }

    private static let groups: [HourGroup] = [
        HourGroup(heading: "THE NIGHT AND THE DAWN", hours: [.matins, .lauds]),
        HourGroup(heading: "THE LITTLE HOURS", hours: [.prime, .terce, .sext, .nones]),
        HourGroup(heading: "EVENING AND NIGHT", hours: [.vespers, .compline])
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            content
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .navigationBarLeading) { backButton }
                    .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .principal) { bookName }
                    .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .navigationBarTrailing) { calendarButton }
                    .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigationBarLeading) { backButton }

                ToolbarItem(placement: .principal) { bookName }

                ToolbarItem(placement: .navigationBarTrailing) { calendarButton }
            }
        }
        .sheet(isPresented: $showCalendar) {
            OfficeCalendarSheet { chosen in
                Task { await viewModel.jump(to: chosen) }
            }
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(22)
        }
        .navigationDestination(item: $openHour) { hour in
            OfficeHourView(viewModel: viewModel, hour: hour)
        }
        .task {
            await viewModel.load()
        }
        // The hour's own timer may have slept through a suspension, and
        // the arch must be right the instant the page is seen.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { clock.refresh() }
        }
    }

    // MARK: - Bar

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 6) {
                AppIcon("ph-caret-left", size: 14)
                // Not "Menu": the Office is reached from home, the
                // Library card, Explore, and the Pray tray.
                Text("Back")
                    .font(AppFonts.bodyFont(16))
            }
            .foregroundColor(AppColors.gold)
        }
    }

    /// The book's name in the bar's dead centre — the page below opens
    /// straight onto the day's leaf, as the missal does.
    private var bookName: some View {
        Text("THE DIVINE OFFICE")
            .font(AppFonts.labelFont(10.5))
            .tracking(2.5)
            .foregroundColor(AppColors.gold.opacity(0.75))
    }

    /// The only day-switching control on the screen. An earlier draft
    /// also carried a `‹ Thursday, 27 August ›` stepper with a TODAY
    /// caption; it was cut, because this button already does that job
    /// and the stepper cost most of the first screenful. The landing
    /// shows today; the sheet is how you go elsewhere.
    private var calendarButton: some View {
        Button {
            showCalendar = true
        } label: {
            AppIcon("ph-calendar-dots", size: 17)
                .foregroundColor(AppColors.gold)
                .frame(width: 44, height: 44, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Choose a day")
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                feastPlate
                    .padding(.horizontal, 24)
                    .devotionalEntrance(delay: 0.04)

                theHourNow
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                    .devotionalEntrance(delay: 0.12)

                hourGroups
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                colophon
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                    .devotionalEntrance(delay: 0.36)
            }
            .padding(.bottom, 44)
        }
        // The arch carries the page's one gold shape, and without this
        // it travels up through the bar and sits lit behind the status
        // bar. The same dissolve every other pushed page uses, at the
        // same depth: a shallower inset leaves the feast at rest
        // *inside* the band, ghosting before anyone has scrolled — the
        // failure the modifier's own inset exists to prevent.
        .topChromeFade()
    }

    // MARK: - Feast Plate

    /// The day, named in English and centred. Loading and failure live
    /// in the same place, so the arch below never moves while the day
    /// travels.
    @ViewBuilder
    private var feastPlate: some View {
        VStack(spacing: 6) {
            if let feast = viewModel.feastTitle {
                Text(feast)
                    .font(AppFonts.headlineFont(21))
                    .lineSpacing(21 * 0.25)
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let line = dayClassLine(viewModel.day?.celebration?.rank) {
                    HStack(spacing: 9) {
                        if let vestment = viewModel.vestment {
                            Circle()
                                .fill(vestment.swatch)
                                .frame(width: 6, height: 6)
                                .shadow(color: vestment.swatch.opacity(0.45), radius: 1.5)
                        }

                        Text(line)
                            .font(AppFonts.labelFont(9.5))
                            .tracking(2.2)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            } else if viewModel.isLoadingDay {
                ProgressView()
                    .tint(AppColors.gold)
                    .padding(.vertical, 14)
            } else if viewModel.dayUnavailable {
                VStack(spacing: 8) {
                    Text("The day's feast could not be reached.")
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)

                    QuietGoldButton(
                        title: "Try again",
                        leadingIcon: "ph-arrow-counter-clockwise",
                        leadingIconSize: 10,
                        size: 10
                    ) {
                        Task { await viewModel.retryDay() }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.35), value: viewModel.feastTitle)
    }

    /// "THIRD CLASS  ·  WHITE" — whichever parts the day carries. The
    /// office names no colour of its own; the missal's propers for the
    /// same date supply it when they can be reached.
    private func dayClassLine(_ rank: String?) -> String? {
        let parts = [
            OfficeRank(rank).englishLabel,
            viewModel.vestment?.name
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ").uppercased()
    }

    // MARK: - The Hour Now

    /// The screen's one lit element, and its whole purpose.
    ///
    /// Deliberately not a card. One ornament per idea, so it carries no
    /// corner ticks, no second border, and no divider inside it — the
    /// arch itself is the ornament.
    private var theHourNow: some View {
        let hour = clock.hour

        return ZStack {
            arch
                .overlay {
                    GothicArchShape(riseRatio: Self.archRise)
                        .strokeBorder(AppColors.gold.opacity(0.42), lineWidth: 1)
                }

            VStack(spacing: 0) {
                HStack(spacing: 9) {
                    LitHourDot(size: 8, box: 14, glow: 5)

                    Text("THE HOUR NOW")
                        .font(AppFonts.labelFont(9.5))
                        .tracking(2.8)
                        .foregroundColor(AppColors.gold.opacity(0.92))
                }

                Text(hour.label)
                    .font(AppFonts.headlineFont(34))
                    .foregroundColor(AppColors.cream)
                    .padding(.top, 9)
                    .id(hour)
                    .transition(.opacity)

                // Why this hour is the one being prayed, and when it
                // lapses
                Text("\(hour.timeOfDay)  ·  \(hour.lapses)")
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.accentSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 3)

                Spacer(minLength: 12)

                GoldCTAButton(title: "Pray \(hour.label)", showsCross: false) {
                    openHour = hour
                }
            }
            .padding(.top, 26)
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .frame(height: 212)
        .animation(.easeOut(duration: 0.4), value: hour)
        .accessibilityElement(children: .contain)
    }

    /// 44 on a 354pt plate — a shallower lancet than the featured card's
    /// 0.34, so the arch reads as a plate rather than a window.
    private static let archRise: CGFloat = 44 / 354

    /// The plate: the card surface under a gold sheen, its halo following
    /// the arch silhouette rather than a rectangle. Steady — the arch's
    /// glow does not breathe; only the lit NOW mark may.
    private var arch: some View {
        GothicArchShape(riseRatio: Self.archRise)
            .fill(AppColors.cardBackground)
            .overlay {
                GothicArchShape(riseRatio: Self.archRise)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: AppColors.gold.opacity(0.14), location: 0),
                                .init(color: AppColors.gold.opacity(0.035), location: 0.48),
                                .init(color: AppColors.gold.opacity(0.012), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .haloGlow(AppColors.gold, radius: 24, intensity: 0.157)
    }

    // MARK: - The Eight Hours

    private var hourGroups: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.groups.enumerated()), id: \.element.id) { index, group in
                if showHourGroups {
                    groupHeading(group.heading)
                }

                strand(group.hours)
                    .devotionalEntrance(delay: 0.2 + Double(index) * 0.08)
            }
        }
    }

    private func groupHeading(_ title: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(AppFonts.labelFont(9))
                .tracking(2.6)
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .fixedSize()

            LinearGradient(
                colors: [AppColors.gold.opacity(0.2), AppColors.gold.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .padding(.top, 22)
        .padding(.bottom, 4)
    }

    /// One group's hours, threaded on a single line of light. The line
    /// stops short of the first and last beads so the strand reads as
    /// hanging between them rather than running off the page.
    private func strand(_ hours: [CanonicalHour]) -> some View {
        VStack(spacing: 0) {
            ForEach(hours) { hour in
                hourRow(hour)
            }
        }
        .background {
            // Threaded behind the beads, stopping short of the first and
            // last so the strand hangs between them rather than running
            // off the page.
            Rectangle()
                .fill(AppColors.gold.opacity(0.14))
                .frame(width: 1)
                .padding(.vertical, 26)
                .padding(.leading, 8.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .accessibilityHidden(true)
        }
    }

    private func hourRow(_ hour: CanonicalHour) -> some View {
        let isPresent = viewModel.presentHour == hour

        return Button {
            openHour = hour
        } label: {
            HStack(spacing: 16) {
                bead(for: hour, lit: isPresent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(hour.label)
                        .font(AppFonts.headlineFont(16.5))
                        .foregroundColor(AppColors.cream.opacity(0.9))

                    Text(hour.timeOfDay)
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 8)

                if isPresent {
                    Text("NOW")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.85))
                }

                AppIcon("ph-caret-right", size: 11)
                    .foregroundColor(AppColors.gold.opacity(0.45))
            }
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(isPresent ? "\(hour.label), the hour now" : hour.label)
    }

    /// The hour's place in the day, said as a colour, punching a hole in
    /// the strand it hangs on. Ringed and lit when it is the hour being
    /// prayed now.
    private func bead(for hour: CanonicalHour, lit: Bool) -> some View {
        ZStack {
            Circle()
                .fill(hour.skyColor)
                .frame(width: 9, height: 9)
                .background {
                    Circle()
                        .fill(AppColors.background)
                        .frame(width: 15, height: 15)
                }

            if lit {
                Circle()
                    .strokeBorder(AppColors.goldLight, lineWidth: 1)
                    .frame(width: 17, height: 17)
                    .shadow(color: AppColors.gold.opacity(0.5), radius: 2.5)
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }

    // MARK: - Colophon

    private var colophon: some View {
        VStack(spacing: 16) {
            OrnamentDivider()
                .padding(.horizontal, 30)

            Text("Breviarium Romanum 1962 · texts served by The Divinum Officium Project")
                .font(AppFonts.bodyFont(11))
                .lineSpacing(11 * 0.5)
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DivineOfficeView()
    }
    .environment(UserSettings.shared)
}
