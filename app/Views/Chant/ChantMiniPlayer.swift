//
//  ChantMiniPlayer.swift
//  Lumen Viae
//
//  What the library is singing, standing at the foot of the whole app.
//

import SwiftUI

// MARK: - ChantMiniPlayer

/// What the library is singing, held at the foot of every board: the
/// painting, the chant and where it stands, and its pause. A tap opens
/// the chant's page. While a set waits between chants it names the next
/// and its button sings it; while a set keeps a silence it says so.
///
/// It is the one filled surface on the library's pages, because it
/// floats over a page that scrolls beneath it, as the tab bar does.
struct ChantMiniPlayer: View {

    let open: () -> Void
    /// Puts the chant away and the player with it, where the player
    /// stands over the whole app
    let close: (() -> Void)?

    private var player = ChantPlayer.shared

    init(open: @escaping () -> Void, close: (() -> Void)? = nil) {
        self.open = open
        self.close = close
    }

    /// What it names: the next chant while a set waits for it
    private var chant: Chant { player.shown }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: open) {
                HStack(spacing: 12) {
                    ChantThumbnail(name: ChantCatalog.painting(for: chant))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(AppFonts.readingFont(16))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(1)
                        subtitle
                            .font(AppFonts.readingItalicFont(12.5))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the chant")

            ChantPlayDisc(
                // A turn keeping its time draws as going on, and a tap holds
                // it; a silence does not, since a tap there goes on to the
                // next chant
                isPlaying: player.chantGoesOn && !player.waitingForNext,
                isLoading: player.isLoading,
                size: 36,
                label: player.waitingForNext ? chant.spokenName : title
            ) {
                player.togglePlayback()
            }

            if let close {
                Button(action: close) {
                    AppIcon("ph-x", size: 13)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Stop and close the player")
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 10)
        .padding(.trailing, close == nil ? 6 : 2)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
        )
        .overlay(alignment: .bottomLeading) {
            ChantMiniProgress(player: player)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.45), radius: 16, y: 6)
    }

    private var title: String {
        if let silence = player.silence { return silence.note.isEmpty ? "Silence" : silence.note }
        if player.waitingForNext { return "Next: \(chant.latinTitle)" }
        return chant.latinTitle
    }

    @ViewBuilder
    private var subtitle: some View {
        if let error = player.error {
            // The chant would not play: said here, wherever it was asked
            // for, and a tap on the disc tries again
            Text(error.message)
        } else if let silence = player.silence {
            if let endsAt = silence.endsAt {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let left = max(0, endsAt.timeIntervalSince(context.date))
                    Text("Silence · \(ChantPlayer.clock(left)) left")
                        .accessibilityLabel("Silence, \(ChantPlayer.spoken(left)) left")
                }
            } else {
                Text("Silence · paused, \(ChantPlayer.clock(silence.remaining)) left")
                    .accessibilityLabel("Silence, paused, \(ChantPlayer.spoken(silence.remaining)) left")
            }
        } else if player.waitingForNext, let queue = player.queue {
            Text("\(queue.title) · waiting for you")
        } else if let queue = player.queue {
            Text("\(queue.title) · \(queue.position)")
        } else if let time = player.timeLabel {
            // The English name beside the Latin title above, and the time
            // kept whole however long the name runs
            HStack(spacing: 0) {
                Text(chant.englishTitle)
                    .truncationMode(.tail)
                Text(" · \(time)")
                    .fixedSize()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([chant.englishTitle, player.spokenTimeLabel].compactMap { $0 }.joined(separator: ", "))
        } else {
            Text(chant.englishTitle)
        }
    }
}

// MARK: - ChantMiniProgress

/// The mini player's gold hairline of progress. The player reports its
/// time twice a second; between those readings the line is carried on at
/// the chant's pace (`ChantClock`), redrawn with the display while the
/// chant sounds and not at all while it rests, so it moves smoothly
/// rather than in half-second steps, and a seek jumps rather than sweeps.
/// A view of its own, so only the line redraws, never the player around it.
private struct ChantMiniProgress: View {
    let player: ChantPlayer

    @State private var clock = ChantClock()

    var body: some View {
        let sounding = player.isPlaying
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !sounding)) { context in
            GeometryReader { geo in
                Rectangle()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: geo.size.width * fraction(at: context.date), height: 1.5)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .onChange(of: Reading(time: player.currentTime, playing: sounding), initial: true) { _, reading in
            clock.observe(reading.time, playing: reading.playing, at: Date())
        }
    }

    private struct Reading: Equatable {
        let time: Double
        let playing: Bool
    }

    private func fraction(at date: Date) -> Double {
        guard player.ownsPlayback else { return 0 }
        let duration = player.duration
        guard duration > 0 else { return 0 }
        return min(1, max(0, clock.time(at: date, rate: player.speed) / duration))
    }
}
