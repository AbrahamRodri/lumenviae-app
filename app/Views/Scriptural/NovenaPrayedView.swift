//
//  NovenaPrayedView.swift
//  app
//
//  "Day 4 prayed": where a novena day prayed in the Rosary ends (design
//  plan, round 1 and the continuous day, frame f-c8). The painting in
//  full, the nine dashes with this day gold, when the next day falls and
//  the mysteries it prays, the reminder's time, and DONE. No streak, no
//  sound, nothing to do but go. The Rosary is recorded in the Prayer
//  Record as every Rosary is.
//

import SwiftData
import SwiftUI

struct NovenaPrayedView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let completed: CompletedPrayer
    let prayed: NovenaPrayed

    @State private var hasRecorded = false
    /// The day's dash fills a beat after arrival, the one motion here
    @State private var showsDay = false

    private var progress: NovenaProgress? { NovenaStore.shared.progress[prayed.novenaID] }

    private var isLast: Bool {
        guard let progress else { return prayed.dayNumber == prayed.length }
        return progress.prayed.count >= progress.length
    }

    private var days: NovenaDays {
        var prayedDays = progress?.prayed ?? [prayed.dayNumber]
        if !showsDay { prayedDays.remove(prayed.dayNumber) }
        return NovenaDays(length: prayed.length, prayed: prayedDays, here: prayed.dayNumber, open: [])
    }

    private var title: String {
        isLast
            ? String(localized: "Nine days prayed", comment: "Novena, after its last day is prayed: the title")
            : String(localized: "Day \(prayed.dayNumber) prayed", comment: "Novena, after a day is prayed in the Rosary: the title")
    }

    private var painting: String {
        completed.category?.cardImageName ?? "sorrowful_agony"
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                AppColors.background.ignoresSafeArea()
                Image(painting)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height * 0.68 + proxy.safeAreaInsets.top)
                    .clipped()
                    .mask(
                        LinearGradient(
                            stops: [.init(color: .black, location: 0.7), .init(color: .clear, location: 1)],
                            startPoint: .top, endPoint: .bottom)
                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(edges: .top)
                    .accessibilityHidden(true)

                VStack(spacing: 14) {
                    Spacer(minLength: 0)
                    NovenaDashes(days: days)
                    Text(title)
                        .font(AppFonts.titleFont(30))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: 6) {
                        if !isLast, let line = progress?.nextDayLine(after: prayed.dayNumber) {
                            Text(line)
                        }
                        if !isLast, let reminder = progress?.reminderLine {
                            Text(reminder)
                        }
                    }
                    .font(AppFonts.italicFont(17))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 24).frame(maxHeight: 120)

                    GoldCTAButton(
                        title: String(localized: "Done", comment: "Novena, after a day is prayed: the gold button that leaves"),
                        fill: .solid,
                        action: done
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .frame(height: proxy.size.height * 0.5)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            record()
            withAnimation(reduceMotion ? Motion.crossfade : Motion.settle.delay(0.4)) { showsDay = true }
            let count = progress?.prayed.count ?? prayed.dayNumber
            AccessibilityNotification.Announcement(
                String(localized: "\(title). \(count) of \(prayed.length) days prayed.", comment: "Novena, after a day is prayed: what VoiceOver says on arrival, like Day 4 prayed. 4 of 9 days prayed.")
            ).post()
        }
    }

    private func done() {
        router.popToRoot()
    }

    /// The Rosary prayed in the day counts in the Prayer Record, as every
    /// Rosary does
    private func record() {
        guard !hasRecorded, let category = completed.category else { return }
        PrayerHistoryService(modelContext: modelContext).recordSession(
            category: category,
            durationSeconds: completed.durationSeconds,
            meditationType: completed.devotionName
        )
        hasRecorded = true
    }
}
