//
//  ConsecrationReadingSheet.swift
//  Lumen Viae
//
//  The day's spiritual reading, set as a page rather than a screen: a
//  bare top bar, the day's theme under an ornament rule, the text at
//  reading size with an illuminated initial, and one gold act at the
//  foot that carries the user into the prayers.
//
//  Opened from BEGIN TODAY'S PRAYER and from READ IN FULL — both land
//  here, so the reading is always where the day starts.
//

import SwiftUI

struct ConsecrationReadingSheet: View {

    // MARK: - Properties

    let dayNumber: Int

    /// Continues into the day's prayers. The overview owns the push, so
    /// the sheet never touches the navigation path itself.
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings

    /// The reading now open, by `order`
    @State private var currentReading: Int?

    private var day: ConsecrationDay? {
        ConsecrationData.day(dayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                // The day's frame stays put; the readings turn beneath it.
                header
                    .padding(.horizontal, 26)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                let readings = day?.readings ?? []

                // Each reading is its own page. A day that opens on Luke
                // and closes on Montfort is two texts, so it is two pages
                // — not one scroll with a rule buried somewhere down it.
                if readings.count > 1 {
                    TabView(selection: $currentReading) {
                        ForEach(readings) { reading in
                            readingPage(reading).tag(reading.order)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    pageControl(readings)
                } else if let only = readings.first {
                    readingPage(only)
                }

                footer
            }
        }
        .devotionalEntrance(drift: 18)
        .onAppear {
            if currentReading == nil { currentReading = day?.readings.first?.order }
        }
    }

    // MARK: - Reading Page

    /// One reading, top to bottom: what it is, who wrote it, then the text
    /// at reading size with its own illuminated initial.
    private func readingPage(_ reading: ConsecrationReading) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reading.title.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)

                    if let source = reading.source {
                        Text(source)
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ReadingText(
                    text: reading.text,
                    size: settings.meditationFontSize,
                    showsDropCap: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 36)
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)
        }
    }

    /// Which reading is open, and the way to the others
    private func pageControl(_ readings: [ConsecrationReading]) -> some View {
        let current = currentReading ?? readings.first?.order ?? 1

        return HStack(spacing: 0) {
            ForEach(readings) { reading in
                let isCurrent = reading.order == current

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentReading = reading.order
                    }
                } label: {
                    Capsule()
                        .fill(isCurrent ? AppColors.gold : AppColors.cream.opacity(0.22))
                        .frame(width: isCurrent ? 18 : 6, height: 4)
                        .frame(width: 34, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("Reading \(reading.order) of \(readings.count), \(reading.title)")
                .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
            }

            Spacer(minLength: 8)

            Text("\(current) of \(readings.count)")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 26)
        .animation(.easeOut(duration: 0.2), value: current)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            PrayerHeaderButton(icon: "ph-x", size: 16, label: "Close the reading") {
                dismiss()
            }

            Spacer()

            Text(dayLabel)
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.cream.opacity(0.85))

            Spacer()

            // Balances the close button so the label stays centered
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var dayLabel: String {
        guard let phase else { return "DAY \(dayNumber)" }
        if phase == .consecrationDay { return "CONSECRATION DAY" }
        return "DAY \(dayNumber) · \(phase.displayName.uppercased())"
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text((phase?.subtitle ?? "").uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)

            Text(day?.title ?? "")
                .font(AppFonts.headlineFont(25))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            OrnamentDivider(showsCross: false)
                .frame(width: 150)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    /// The page dissolves into the act rather than stopping against it.
    private var footer: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [AppColors.background.opacity(0), AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .allowsHitTesting(false)

            GoldCTAButton(title: "Continue to prayers", showsCross: false, action: onContinue)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .background(AppColors.background)
        }
    }
}

// MARK: - Preview

#Preview {
    ConsecrationReadingSheet(dayNumber: 33, onContinue: {})
        .environment(UserSettings.shared)
}
