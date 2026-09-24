//
//  SpokenRosaryNotice.swift
//  Lumen Viae
//
//  Why the Rosary is not being said aloud when it was asked to be, and
//  the one thing that puts it right, laid out where the transport would
//  be. The words say what is wrong in plain terms; the remedy is a
//  control, not an instruction: a Try Again for a connection that has
//  come back, and the voices themselves for a voice that has not been
//  recorded yet — choosing another begins the Rosary in it.
//
//  Shared by the meditation's player and the Scriptural Rosary, so the
//  same trouble looks the same wherever it is met.
//

import SwiftUI

struct SpokenRosaryNotice: View {

    let failure: SpokenRosaryPlayer.Failure
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.gold)
                    .accessibilityHidden(true)

                Text(failure.message)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

            switch failure {
            case .offline:
                GoldCTAButton(
                    title: "Try again",
                    fill: .outline,
                    prominence: .inline,
                    trailingIcon: "ph-arrow-counter-clockwise",
                    fullWidth: false,
                    action: onRetry
                )
                .accessibilityHint("Downloads the prayers so they can be said aloud")

            case .notRecorded:
                // Choosing another voice is what the view answers to:
                // the Rosary begins again in it
                NarrationVoiceChoice(height: 34)
                    .frame(maxWidth: 260)
            }
        }
        .padding(.horizontal, 30)
        .accessibilityElement(children: .contain)
    }

    private var icon: String {
        switch failure {
        case .offline: return "wifi.slash"
        case .notRecorded: return "waveform"
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        SpokenRosaryNotice(failure: .offline) {}
        SpokenRosaryNotice(failure: .notRecorded) {}
    }
    .padding(.vertical, 40)
    .background(AppColors.background)
}
