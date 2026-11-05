//
//  BeginnerRosaryView.swift
//  Lumen Viae
//
//  The simple Rosary's beginner's path (the One Rosary beta): someone
//  who said in onboarding that they came to learn the Rosary begins on
//  St. Alphonsus Liguori's meditations for the day's mysteries, with the
//  helps on — one plain line on each step saying what to pray and which
//  bead the hand is on (`RosaryHelps`). The set's own page says so before
//  PRAY, with a plain way to say no and choose for oneself.
//
//  Abraham, 5 Nov 2026: "audio rosary should just be say no meditation
//  on the select screen and the default for new is st alphonsus
//  meditations with the helps".
//

import SwiftUI

struct BeginnerRosaryView: View {
    let category: MysteryCategory

    @Environment(AppRouter.self) private var router
    @State private var summary: MeditationSetSummary?

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()
            if let summary {
                MeditationSetDetailView(summary: summary, beginner: true) {
                    // No: the day's mysteries' page, to choose another way
                    router.pop()
                    router.navigateToMeditationSelection(category: category)
                }
                .transition(.opacity)
            } else {
                ProgressView()
                    .tint(AppColors.gold)
            }
        }
        .animation(Motion.crossfade, value: summary?.id)
        .navigationBarHidden(true)
        .task {
            guard summary == nil else { return }
            let served = (try? await APIService.shared.fetchMeditationSets(category: category)) ?? []
            summary = SimpleRosary.beginnerSet(from: served + BundledMeditationSets.summaries(for: category))
            // Nothing at all to pray with: the mysteries' page instead
            if summary == nil {
                router.pop()
                router.navigateToMeditationSelection(category: category)
            }
        }
    }
}
