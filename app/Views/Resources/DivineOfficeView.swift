//
//  DivineOfficeView.swift
//  Lumen Viae
//
//  The Divine Office: the pre-Vatican II Breviarium Romanum under the
//  1960 rubrics, served by the Lumen Viae API from the Divinum Officium
//  engine.
//
//  The screen has one purpose — get the reader into the hour that is
//  current, in one tap — so the page opens on that hour: its own
//  painting run up under the bar and dissolving into the page, as an
//  order of prayer's page opens, NOW · UNTIL NOON over its name, and one
//  inline gold PRAY. The day's feast follows, then the eight hours,
//  grouped the way a breviary groups them and strung on one strand of
//  light, each bead in the colour of its own time of day.
//
//  It once opened on a sentence saying what the Office is, set the hour
//  now in a 212-point lit lancet arch with a full-width gold act, gave
//  every hour a second line of when it is said beside its Church name,
//  and closed on a paragraph of provenance (the "hours page polish",
//  Oct 2026).
//
//  English in the chrome. The engine answers in Latin ("III. classis",
//  "S. Josephi Calasanctii Confessoris") and Latin belongs in the prayer
//  text, not above it, so the rank is mapped client-side.
//
//  Nothing here waits on the network: the hours are the hours, and the
//  hour now is read from the clock. Only the day's feast travels, and
//  when it cannot be reached the page says so quietly and leaves every
//  hour tappable.
//

import SwiftUI

struct DivineOfficeView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = OfficeViewModel()
    @State private var openHour: CanonicalHour?
    @State private var showCalendar = false

    /// Whether the page is scrolled far enough that its words travel
    /// under the bar. Measured as a flag, so a scroll redraws the page
    /// only when it flips, never frame by frame.
    @State private var wordsUnderBar = false

    private var clock = CanonicalClock.shared

    /// How tall the hour's painting stands at the head of the page, the
    /// status bar's height included — the order pages' height
    private static let heroHeight: CGFloat = 280

    // MARK: - Groups

    /// The hours as a breviary groups them
    private struct HourGroup: Identifiable {
        let heading: String
        let hours: [CanonicalHour]
        var id: String { heading }
    }

    private static let groups: [HourGroup] = [
        HourGroup(heading: "THE NIGHT AND THE DAWN", hours: [.matins, .lauds]),
        HourGroup(heading: "THROUGH THE DAY", hours: [.prime, .terce, .sext, .nones]),
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { GoldBackButton() }

            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .principal) { bookName }
                    .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .principal) { bookName }
            }

            ToolbarItem(placement: .navigationBarTrailing) { calendarButton }
        }
        .sheet(isPresented: $showCalendar) {
            OfficeCalendarSheet { chosen in
                Task { await viewModel.jump(to: chosen) }
            }
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColors.background)
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            .presentationCornerRadius(22)
        }
        .navigationDestination(item: $openHour) { hour in
            OfficeHourView(viewModel: viewModel, hour: hour)
        }
        .task {
            await viewModel.load()
        }
        // The hour's own timer may have slept through a suspension, and
        // the hour now must be right the instant the page is seen.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { clock.refresh() }
        }
    }

    // MARK: - Bar

    /// The book's name in the bar's dead centre, lifted off the painting
    /// beneath it
    private var bookName: some View {
        Text("HOURS OF PRAYER")
            .font(AppFonts.labelFont(10.5))
            .tracking(2.5)
            .foregroundColor(AppColors.gold)
            .shadow(color: AppColors.background.opacity(0.9), radius: 6)
            .accessibilityAddTraits(.isHeader)
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
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("Choose a day")
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                    .onGeometryChange(for: Bool.self) { proxy in
                        -proxy.frame(in: .global).minY > 70
                    } action: { under in
                        withAnimation(reduceMotion ? nil : Motion.crossfade) { wordsUnderBar = under }
                    }

                theHourNow
                    .padding(.horizontal, 20)
                    .padding(.top, -48)
                    .devotionalEntrance()

                feastPlate
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .devotionalEntrance(delay: 0.06)

                hourGroups
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                colophon
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
            }
            .padding(.bottom, 44)
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) { barVeil }
    }

    // MARK: - Head

    /// The hour now's own painting, run to the top of the glass and
    /// dissolving into the page beneath its name, never to a flat slab.
    /// It turns with the hour.
    private var hero: some View {
        let painting = PrayerBookPainting.office(clock.hour)
        return ZStack {
            CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                .id(painting.asset)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.heroHeight)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.5),
                    .init(color: .black.opacity(0.35), location: 0.8),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(reduceMotion ? nil : Motion.crossfade, value: painting.asset)
        .accessibilityHidden(true)
    }

    /// A veil under the status bar and the bar's controls: light over the
    /// painting at rest, and near opaque down past the bar once the page's
    /// words travel under it — the order pages' veil
    private var barVeil: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [AppColors.background.opacity(0.55), AppColors.background.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)

            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.99), location: 0),
                    .init(color: AppColors.background.opacity(0.99), location: 0.8),
                    .init(color: AppColors.background.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 172)
            .opacity(wordsUnderBar ? 1 : 0)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    // MARK: - The Hour Now

    /// The page's purpose: the hour it is now, laid over its painting's
    /// foot, with the page's one gold act at the inline size
    private var theHourNow: some View {
        let hour = clock.hour

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                LitHourDot(size: 7, box: 12, glow: 4)
                Text("NOW  ·  \(hour.lapses.uppercased())")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.4)
                    .foregroundColor(AppColors.gold)
                    .contentTransition(.opacity)
            }
            // Lifted off the painting's dissolve, where a light passage
            // of the painting can stand behind it
            .shadow(color: AppColors.background.opacity(0.9), radius: 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Now, \(hour.lapses)")

            Text(hour.plainName)
                .font(AppFonts.titleFont(29))
                .foregroundColor(AppColors.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.opacity)
                .accessibilityAddTraits(.isHeader)

            Text(hour.label)
                .font(AppFonts.readingItalicFont(14.5))
                .foregroundColor(AppColors.cream.opacity(0.55))
                .contentTransition(.opacity)

            GoldCTAButton(title: "Pray", prominence: .inline, glyph: .play, fullWidth: false) {
                openHour = hour
            }
            .accessibilityLabel("Pray \(hour.plainName)")
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : Motion.crossfade, value: hour)
    }

    // MARK: - Feast Plate

    /// The day, named in English. Loading and failure live in the same
    /// place, so the hours below never move while the day travels.
    @ViewBuilder
    private var feastPlate: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let feast = viewModel.feastTitle {
                Text(feast)
                    .font(AppFonts.headlineFont(17))
                    .lineSpacing(17 * 0.2)
                    .foregroundColor(AppColors.cream.opacity(0.9))
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
                    }
                }
            } else if viewModel.isLoadingDay {
                ProgressView()
                    .tint(AppColors.gold)
                    .padding(.vertical, 6)
            } else if viewModel.dayUnavailable {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The day's feast could not be reached.")
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)

                    QuietGoldButton(
                        title: "Try again",
                        leadingIcon: "ph-arrow-counter-clockwise",
                        leadingIconSize: 10,
                        size: 10,
                        horizontalPadding: 0
                    ) {
                        Task { await viewModel.retryDay() }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: viewModel.feastTitle)
    }

    /// "LESSER FEAST  ·  WHITE VESTMENTS" — whichever parts the day
    /// carries, in the Missal's own words. The office names no colour of
    /// its own; the missal's propers for the same date supply it when
    /// they can be reached.
    private func dayClassLine(_ rank: String?) -> String? {
        let parts = [
            OfficeRank(rank).plainLabel(title: viewModel.feastTitle),
            viewModel.vestment?.plainName
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ").uppercased()
    }

// MARK: - The Eight Hours

    private var hourGroups: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.groups.enumerated()), id: \.element.id) { index, group in
                groupHeading(group.heading)

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

                // The name over its Church name: when it is said is the
                // name itself and the heading above it
                VStack(alignment: .leading, spacing: 2) {
                    Text(hour.plainName)
                        .font(AppFonts.headlineFont(16.5))
                        .foregroundColor(AppColors.cream.opacity(0.9))

                    Text(hour.label)
                        .font(AppFonts.italicFont(12.5))
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
        .accessibilityLabel(isPresent
            ? "\(hour.plainName), \(hour.label), the prayer for now"
            : "\(hour.plainName), \(hour.label)")
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

    /// The texts' source, said once and short
    private var colophon: some View {
        Text(OfficeCredit.line)
            .font(AppFonts.bodyFont(11))
            .foregroundColor(AppColors.textSecondary.opacity(0.8))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DivineOfficeView()
    }
    .environment(UserSettings.shared)
}
