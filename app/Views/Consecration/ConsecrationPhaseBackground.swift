//
//  ConsecrationPhaseBackground.swift
//  Lumen Viae
//
//  Shared background for all consecration flow screens: the active
//  theme's gradient with the phase's tint layered on top, so the 33-day
//  journey visibly progresses, every theme keeps its own character, and
//  the background never jumps between screens of the same day.
//

import SwiftUI

struct ConsecrationPhaseBackground: View {
    let phase: ConsecrationPhase?

    var body: some View {
        ZStack {
            AppColors.appGradient

            if let phase {
                LinearGradient(
                    colors: phase.gradientColors.map { $0.opacity(0.55) },
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}
