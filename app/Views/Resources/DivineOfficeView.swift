//
//  DivineOfficeView.swift
//  Lumen Viae
//
//  The Divine Office: the pre-Vatican II Breviarium Romanum under the
//  1960 rubrics, served by the Lumen Viae API from the Divinum Officium
//  engine. A day is stepped like turning pages — the same navigator as
//  the missal — and its eight canonical hours wait in a ruled ledger,
//  each named in English with the breviary's own name and its
//  traditional time beside it.
//
//  The ledger never waits on the network: the hours are the hours. Only
//  the day's calendar line travels, and when it cannot be reached the
//  page says so quietly and leaves every hour tappable.
//

import SwiftUI

struct DivineOfficeView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = OfficeViewModel()
    @State private var openHour: CanonicalHour?
    @State private var showCalendar = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            content
        }
        .navigationBarBackButtonHidden(true)
        // The bar's controls stand on the masthead's own surface, as on
        // the missal — no floating glass capsules where the leaf runs up
        // behind them.
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .navigationBarLeading) { backButton }
                    .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .principal) { bookName }
                    .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigationBarLeading) { backButton }

                ToolbarItem(placement: .principal) { bookName }
            }
        }
        .sheet(isPresented: $showCalendar) {
            OfficeCalendarSheet { chosen in
                Task { await viewModel.jump(to: chosen) }
            }
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(item: $openHour) { hour in
            OfficeHourView(viewModel: viewModel, hour: hour)
        }
        .task {
            await viewModel.load()
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
            .font(AppFonts.labelFont(10))
            .tracking(2.5)
            .foregroundColor(AppColors.gold.opacity(0.7))
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                // The leaf runs edge to edge; only the ledger below it
                // keeps the page margin.
                OrdoMasthead(
                    dateLabel: viewModel.dateLabel,
                    isToday: viewModel.isToday,
                    onStep: { days in Task { await viewModel.step(by: days) } },
                    onCalendar: { showCalendar = true },
                    onToday: { Task { await viewModel.goToToday() } }
                ) {
                    mastheadFeast
                }
                .padding(.bottom, 24)

                hoursLedger
                    .padding(.horizontal, 24)

                endBlock
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Day Header

    /// What stands on the leaf: the day's place in the calendar, once
    /// known. Loading and failure live inside the same object, so the
    /// ledger below never moves while the day travels.
    @ViewBuilder
    private var mastheadFeast: some View {
        VStack(spacing: 9) {
            if let day = viewModel.day {
                if let tempora = day.detail?.text {
                    Text(tempora.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let celebration = day.celebration {
                    Text(celebration.title)
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let rank = celebration.rank {
                        Text(rank.uppercased())
                            .font(AppFonts.labelFont(10))
                            .tracking(2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                if let note = day.note {
                    Text(note)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
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
    }

    // MARK: - Hours Ledger

    /// The eight canonical hours as the arc of a day. Each row carries a
    /// sky mark — a small disc in the colour of its own hour, night
    /// through dawn through noon and back to night — so the ledger reads
    /// as time, not as eight identical lines. On today's page the
    /// present hour's mark is ringed and lit.
    private var hoursLedger: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(CanonicalHour.allCases) { hour in
                hourRow(hour)

                if hour != CanonicalHour.allCases.last {
                    // The rule stops short of the sky marks, so the
                    // column of discs reads as one strand
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.1))
                        .frame(height: 0.5)
                        .padding(.leading, 34)
                }
            }
        }
    }

    private func hourRow(_ hour: CanonicalHour) -> some View {
        let isPresent = viewModel.presentHour == hour

        return Button {
            openHour = hour
        } label: {
            HStack(spacing: 16) {
                skyMark(for: hour, lit: isPresent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(hour.label)
                        .font(AppFonts.headlineFont(17))
                        .foregroundColor(AppColors.cream.opacity(isPresent ? 1 : 0.85))

                    Text("\(hour.latinName) · \(hour.timeOfDay)")
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 8)

                if isPresent {
                    Text("NOW")
                        .font(AppFonts.labelFont(8))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.85))
                }

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.vertical, 13)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(isPresent ? "\(hour.label), the present hour" : hour.label)
    }

    /// The hour's place in the sky: its own colour, ringed in gold and
    /// glowing when it is the hour being prayed now.
    private func skyMark(for hour: CanonicalHour, lit: Bool) -> some View {
        ZStack {
            Circle()
                .fill(hour.skyColor.opacity(lit ? 1 : 0.8))
                .frame(width: 10, height: 10)

            if lit {
                Circle()
                    .strokeBorder(AppColors.goldLight, lineWidth: 1)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 18, height: 18)
        .shadow(color: lit ? AppColors.gold.opacity(0.5) : .clear, radius: 4)
        .accessibilityHidden(true)
    }

    // MARK: - End Block

    private var endBlock: some View {
        VStack(spacing: 16) {
            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 24)

            Text("Breviarium Romanum 1962 · texts served by The Divinum Officium Project")
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Sky colours

/// Each hour's place in the day, said as a colour — night indigo for
/// Matins, dawn rose for Lauds, the sun's gold through the day hours,
/// dusk violet for Vespers, and night again at Compline. A display
/// concern, so it lives with the page rather than in the model. The
/// swatches are muted to sit on the dark ground, like the vestment
/// swatches — a mark, not a flag.
private extension CanonicalHour {
    var skyColor: Color {
        switch self {
        case .matins:   return Color(hex: "#454568")  // deep night
        case .lauds:    return Color(hex: "#a06b7a")  // first light
        case .prime:    return Color(hex: "#c99a5e")  // early sun
        case .terce:    return Color(hex: "#d9b96a")  // morning gold
        case .sext:     return Color(hex: "#e3cf8a")  // noon
        case .nones:    return Color(hex: "#c98d56")  // afternoon amber
        case .vespers:  return Color(hex: "#8a6b9e")  // dusk violet
        case .compline: return Color(hex: "#3a3a5e")  // night
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
