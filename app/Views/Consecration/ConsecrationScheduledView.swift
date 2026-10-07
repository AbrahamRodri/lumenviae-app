//
//  ConsecrationScheduledView.swift
//  Lumen Viae
//
//  The tab's page for a consecration chosen ahead of its feast, until
//  its Day 1 comes: when the 33 days begin, the feast they end on, the
//  book to read while waiting, and a way to choose another feast. No day
//  of it is open yet (`ConsecrationProgress.hasBegun`), and on Day 1 the
//  tab turns to the day's own page by itself.
//

import SwiftUI

struct ConsecrationScheduledView: View {

    /// Day 1, at the start of its day
    let start: Date

    @Binding var path: [ConsecrationRoute]

    @Environment(ConsecrationViewModel.self) private var viewModel

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
        ZStack(alignment: .top) {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    titleBlock
                        .padding(.top, 220)
                        .padding(.horizontal, 28)
                        .devotionalEntrance()

                    datesCard
                        .padding(.top, 26)
                        .padding(.horizontal, 20)
                        .devotionalEntrance(delay: 0.08)

                    doors
                        .padding(.top, 22)
                        .devotionalEntrance(delay: 0.16)
                }
                .frame(maxWidth: .infinity)
                // The painting rides with the page, behind the title
                .background(alignment: .top) {
                    plate
                }
                // Clear of the tab bar
                .padding(.bottom, 120)
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Painting

    /// The Annunciation, as on the introduction's second page: the yes
    /// a consecration to Mary renews
    private var plate: some View {
        CachedAssetImage("joyful_annunciation", focal: UnitPoint(x: 0.5, y: 0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 360)
            .clipped()
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.45), location: 0),
                        .init(color: .black.opacity(0), location: 0.35),
                        .init(color: AppColors.background.opacity(0.7), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.45),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(spacing: 12) {
            ConsecrationIntroKicker(text: "Consecration to Mary")
                .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

            Text(daysUntilStart == 1
                 ? "Your 33 days begin tomorrow"
                 : "Your 33 days begin \(ConsecrationDateSelectionView.longDate(start, weekday: true))")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
                .accessibilityAddTraits(.isHeader)

            Text("The first day's prayers open then. Nothing is asked of you before it.")
                .font(AppFonts.italicFont(17))
                .foregroundColor(AppColors.accentSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Dates

    private var datesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            dateRow(
                label: "DAY 1",
                date: ConsecrationDateSelectionView.longDate(start, weekday: true),
                note: ConsecrationDateSelectionView.countdown(daysUntilStart)
            )

            ConsecrationIntroRule()
                .padding(.vertical, 14)

            dateRow(
                label: "CONSECRATION DAY",
                date: ConsecrationDateSelectionView.longDate(feastDate, weekday: true),
                note: feast?.name
            )
        }
        .sacredCard(padding: 18, elevated: true)
    }

    private func dateRow(label: String, date: String, note: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.labelFont(10.5))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            Text(date)
                .font(AppFonts.bodyFont(17))
                .foregroundColor(AppColors.cream)

            if let note {
                Text(note)
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Doors

    /// Two quiet doors: the book the consecration comes from, which
    /// Montfort asks to be read, and the way back to the feasts. Nothing
    /// here is the page's gold act, since there is nothing yet to pray.
    private var doors: some View {
        VStack(spacing: 4) {
            QuietGoldButton(
                title: "Read True Devotion to Mary",
                leadingIcon: "ph-book-open",
                size: 11
            ) {
                path.append(.trueDevotionReader)
            }
            .frame(minHeight: 44)
            .accessibilityHint("The book this consecration comes from")

            QuietGoldButton(
                title: "Choose another feast",
                size: 10,
                color: AppColors.textSecondary
            ) {
                // Nothing is lost: no day of it has been prayed
                withAnimation(Motion.crossfade) {
                    viewModel.abandonConsecration()
                }
            }
            .frame(minHeight: 44)
        }
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
