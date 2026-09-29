//
//  ChantScoreSheet.swift
//  Lumen Viae
//
//  A chant's score, large: the whole of it at the width of the glass, a
//  pinch (or a double tap) to bring a phrase closer, and the transport
//  kept at the foot so the score can be followed while the chant sounds.
//  A sheet, not a page: it is the score of the page it opens from, with
//  nowhere else to go.
//

import SwiftUI

struct ChantScoreSheet: View {

    let chant: Chant

    /// Off where the page beneath has its own transport sounding the chant
    /// (a consecration day), so the sheet never takes the player from it
    var showsTransport = true

    @Environment(\.dismiss) private var dismiss

    private var player = ChantPlayer.shared

    /// How much closer than the width of the glass: 1 to 3
    @State private var zoom: CGFloat = 1
    @State private var zoomAtGestureStart: CGFloat = 1

    init(chant: Chant, showsTransport: Bool = true) {
        self.chant = chant
        self.showsTransport = showsTransport
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: "The score", title: chant.fullTitle) {
                SheetHeaderAction(title: "Done") { dismiss() }
            }

            GeometryReader { geo in
                ScrollView([.vertical, .horizontal], showsIndicators: false) {
                    ChantScoreView(parts: chant.score, spacing: 30)
                        .frame(width: (geo.size.width - 32) * zoom)
                        .padding(16)
                        .padding(.bottom, 24)
                }
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            zoom = min(max(zoomAtGestureStart * value.magnification, 1), 3)
                        }
                        .onEnded { _ in
                            zoomAtGestureStart = zoom
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(Motion.settle) {
                        zoom = zoom > 1.2 ? 1 : 2
                        zoomAtGestureStart = zoom
                    }
                }
                .accessibilityHint("Pinch or double tap to bring the score closer")
            }

            if showsTransport {
                footTransport
            }
        }
        .sheetGround()
        .presentationDetents([.large])
    }

    /// Play, pause and the time, under a hairline — the score stays the
    /// sheet's subject
    private var footTransport: some View {
        let holds = player.holds(chant)
        return VStack(spacing: 10) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.18))
                .frame(height: AppLine.hairline)

            HStack(spacing: 14) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying(chant),
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 40,
                    label: chant.latinTitle
                ) {
                    player.toggle(chant)
                }

                ChantScrubber(progress: holds ? player.progress : 0, isEnabled: holds) { fraction in
                    player.seek(toFraction: fraction)
                }

                Text(holds ? ChantPlayer.clock(player.currentTime) : chant.durationLabel)
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary)
                    .monospacedDigit()
                    .frame(minWidth: 36, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
}
