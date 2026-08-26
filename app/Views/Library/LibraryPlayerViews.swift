//
//  LibraryPlayerViews.swift
//  Lumen Viae
//
//  The shelf's transport, drawn in the app's own hand: a gold hairline
//  with a small bead, a single filled gold circle for the play control,
//  and tracked engraved caps for everything that is a label. The same
//  vocabulary the consecration chant bar uses, with the two things a
//  spoken book needs that a chant does not — a way to step back fifteen
//  seconds when a sentence is missed, and a way to stop.
//
//  The sleep timer is the one control here whose whole purpose is to
//  help the reader put the book down. It defaults to the end of the
//  reading, because that is what someone praying at night actually
//  wants, and it fades rather than cutting the voice off.
//

import SwiftUI

// MARK: - Transport

/// Position, the two times, and the controls — the recording's own bar.
struct LibraryTransportBar: View {

    let session: LibraryListeningSession

    /// What is sounding, named above the bar. The player sheet names it
    /// in its own header instead, and turns this off.
    let trackTitle: String
    var showsTitle: Bool = true

    /// Where the reader is taken to see the whole ledger, when this bar
    /// is standing somewhere else (the reader's foot). Nil on the book
    /// page, where the ledger is already below it.
    var onOpenLedger: (() -> Void)? = nil

    /// Where the thumb is while a drag runs, so the playhead doesn't
    /// fight the time observer under the reader's finger
    @State private var scrubbing: Double?

    private var isReady: Bool { session.duration > 0 }

    private var displayedTime: Double { scrubbing ?? session.currentTime }

    private var progress: Double {
        guard session.duration > 0 else { return 0 }
        return min(max(displayedTime / session.duration, 0), 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            if showsTitle { title }

            scrubber

            HStack {
                Text(LibraryListeningSession.time(displayedTime))
                Spacer()
                // The remaining time is the scrubber telling the truth
                // about the file, not a prediction about the reader.
                Text("−" + LibraryListeningSession.time(max(session.duration - displayedTime, 0)))
            }
            .font(AppFonts.labelFont(9))
            .tracking(1.5)
            .foregroundColor(AppColors.textSecondary)
            .monospacedDigit()

            controls
        }
    }

    private var title: some View {
        HStack(spacing: 8) {
            Text(trackTitle)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream)
                .lineLimit(1)

            Spacer(minLength: 4)

            if let onOpenLedger {
                Button(action: onOpenLedger) {
                    AppIcon("ph-list", size: 13)
                        .foregroundColor(AppColors.gold.opacity(0.75))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("All the readings")
            }
        }
    }

    // MARK: Scrubber

    /// A gold hairline with a small gold bead. The system `Slider` puts a
    /// large white capsule on the page — the one foreign shape in the
    /// whole shelf — and its thumb can't be restyled.
    private var scrubber: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let bead: CGFloat = 11

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.cream.opacity(0.14))
                    .frame(height: 3)

                Capsule()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: max(width * progress, 3), height: 3)

                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: bead, height: bead)
                    .offset(x: (width - bead) * progress)
                    .opacity(isReady ? 1 : 0.4)
            }
            .frame(height: 22)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isReady else { return }
                        scrubbing = min(max(value.location.x / width, 0), 1) * session.duration
                    }
                    .onEnded { _ in
                        if let target = scrubbing { session.seek(to: target) }
                        scrubbing = nil
                    }
            )
        }
        .frame(height: 22)
        .accessibilityElement()
        .accessibilityLabel("Position in this reading")
        .accessibilityValue(
            "\(LibraryListeningSession.time(displayedTime)) of \(LibraryListeningSession.time(session.duration))"
        )
        .accessibilityAdjustableAction { direction in
            guard isReady else { return }
            switch direction {
            case .increment: session.seek(to: min(session.duration, session.currentTime + 15))
            case .decrement: session.seek(to: max(0, session.currentTime - 15))
            @unknown default: break
            }
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 22) {
            Spacer(minLength: 0)

            stepButton(back: true)
            skipButton(back: true)
            playButton
            skipButton(back: false)
            stepButton(back: false)

            Spacer(minLength: 0)
        }
    }

    private var playButton: some View {
        Button(action: { session.togglePlayPause() }) {
            ZStack {
                Circle()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: 44, height: 44)

                if session.isLoading {
                    SwiftUI.ProgressView()
                        .controlSize(.small)
                        .tint(AppColors.background)
                } else {
                    AppIcon(session.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 16)
                        .foregroundColor(AppColors.background)
                }
            }
            .frame(width: 52, height: 52)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .disabled(session.isLoading)
        .accessibilityLabel(
            session.isLoading ? "Loading the reading"
                              : (session.isPlaying ? "Pause the reading" : "Play the reading")
        )
    }

    /// Fifteen seconds — the same number the prayer flow uses, so a
    /// thumb only ever learns one.
    private func skipButton(back: Bool) -> some View {
        Button(action: { session.skip(by: back ? -15 : 15) }) {
            ZStack {
                AppIcon("ph-arrow-counter-clockwise", size: 20)
                    // The catalog carries only the counter-clockwise
                    // arrow; forward is its mirror, which is exactly what
                    // the glyph means.
                    .scaleEffect(x: back ? 1 : -1, y: 1)

                Text("15")
                    .font(AppFonts.labelFont(7))
                    .offset(y: 1)
            }
            .foregroundColor(AppColors.gold)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(back ? "Back fifteen seconds" : "Forward fifteen seconds")
    }

    @ViewBuilder
    private func stepButton(back: Bool) -> some View {
        let enabled = back ? (session.trackIndex ?? 0) > 0
                           : (session.trackIndex ?? 0) + 1 < session.sections.count

        Button(action: { session.step(by: back ? -1 : 1) }) {
            AppIcon("ph-skip-forward-fill", size: 13)
                .scaleEffect(x: back ? -1 : 1, y: 1)
                .foregroundColor(AppColors.gold.opacity(enabled ? 0.8 : 0.25))
                .frame(width: 40, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(back ? "Previous reading" : "Next reading")
    }
}

// MARK: - Listen options

/// The two quiet controls that ride in the LISTEN header: how fast the
/// voice reads, and when it should stop.
struct LibraryListenOptions: View {

    let session: LibraryListeningSession

    /// One tray at a time, carried as a value. Two chained
    /// `.sheet(isPresented:)` modifiers on one view is the shape that
    /// already produced an empty sheet elsewhere in this feature, and
    /// these are now raised from inside another sheet.
    @State private var tray: Tray?

    private enum Tray: String, Identifiable {
        case sleep, rate
        var id: String { rawValue }
    }

    var body: some View {
        HStack(spacing: 4) {
            Button(action: { tray = .rate }) {
                Text(Self.rateLabel(session.playbackRate))
                    .font(AppFonts.labelFont(10))
                    .tracking(1.2)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .frame(minWidth: 32, minHeight: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reading speed, \(Self.rateLabel(session.playbackRate))")

            Button(action: { tray = .sleep }) {
                HStack(spacing: 5) {
                    AppIcon("ph-moon-stars", size: 14)
                        .foregroundColor(
                            session.sleepTimer == nil
                                ? AppColors.gold.opacity(0.6)
                                : AppColors.goldLight
                        )

                    if let label = sleepLabel {
                        Text(label)
                            .font(AppFonts.labelFont(9))
                            .tracking(1)
                            .foregroundColor(AppColors.goldLight)
                            .monospacedDigit()
                    }
                }
                .frame(minWidth: 36, minHeight: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(sleepAccessibilityLabel)
        }
        .sheet(item: $tray) { which in
            switch which {
            case .sleep:
                LibrarySleepSheet(session: session)
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
            case .rate:
                LibraryRateSheet(session: session)
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    /// What the armed timer is waiting for, short enough for a header.
    private var sleepLabel: String? {
        switch session.sleepTimer {
        case .none: return nil
        case .endOfTrack: return "END"
        case .after:
            guard let left = session.sleepRemaining else { return nil }
            let minutes = (left + 59) / 60
            return "\(minutes)m"
        }
    }

    private var sleepAccessibilityLabel: String {
        switch session.sleepTimer {
        case .none: return "Sleep timer, off"
        case .endOfTrack: return "Sleep timer, stopping at the end of this reading"
        case .after:
            let minutes = ((session.sleepRemaining ?? 0) + 59) / 60
            return "Sleep timer, \(minutes) minutes left"
        }
    }

    static func rateLabel(_ rate: Double) -> String {
        rate == rate.rounded() ? "\(Int(rate))×" : String(format: "%g×", rate)
    }
}

// MARK: - Sleep sheet

/// A ruled ledger, not a row of chips — and the first line is the one a
/// person praying at night actually wants.
struct LibrarySleepSheet: View {

    let session: LibraryListeningSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LibraryTraySheet(
            title: "Stop the reading",
            note: "The voice withdraws rather than being cut off."
        ) {
            row(
                title: "At the end of this reading",
                isOn: session.sleepTimer == .endOfTrack
            ) { session.setSleepTimer(.endOfTrack); dismiss() }

            ForEach([15, 30, 60], id: \.self) { minutes in
                row(
                    title: minutes == 60 ? "In an hour" : "In \(minutes) minutes",
                    isOn: session.sleepTimer == .after(minutes: minutes)
                ) { session.setSleepTimer(.after(minutes: minutes)); dismiss() }
            }

            if session.sleepTimer != nil {
                row(title: "Let it run on", isOn: false) {
                    session.setSleepTimer(nil)
                    dismiss()
                }
            }
        }
    }

    private func row(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        LibraryTrayRow(title: title, isOn: isOn, action: action)
    }
}

// MARK: - Rate sheet

struct LibraryRateSheet: View {

    let session: LibraryListeningSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LibraryTraySheet(
            title: "Reading speed",
            note: "LibriVox readers are volunteers, and they read at their own pace."
        ) {
            ForEach(AudioService.supportedRates, id: \.self) { rate in
                LibraryTrayRow(
                    title: LibraryListenOptions.rateLabel(rate),
                    isOn: session.playbackRate == rate
                ) {
                    session.setRate(rate)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Tray furniture

/// The shared shape of the shelf's small trays: a kicker, a rule, ruled
/// rows, and one quiet line of explanation at the foot.
struct LibraryTraySheet<Content: View>: View {

    let title: String
    var note: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(title.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.2))
                    .frame(height: 0.5)

                content

                if let note {
                    Text(note)
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct LibraryTrayRow: View {

    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(isOn ? AppColors.goldLight : AppColors.cream)

                    Spacer(minLength: 8)

                    if isOn {
                        AppIcon("ph-check", size: 13)
                            .foregroundColor(AppColors.goldLight)
                    }
                }
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(height: 0.5)
        }
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

// MARK: - Mini player

/// What the recording looks like from inside a chapter: the reading's
/// name, the one control that matters while reading, and the way to the
/// full transport.
struct LibraryMiniPlayer: View {

    let session: LibraryListeningSession
    let title: String
    let onExpand: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onExpand) {
                HStack(spacing: 10) {
                    AppIcon("ph-speaker-high", size: 14)
                        .foregroundColor(AppColors.gold)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)

                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("The reading: \(title). Opens the player.")

            Button(action: { session.skip(by: -15) }) {
                ZStack {
                    AppIcon("ph-arrow-counter-clockwise", size: 17)
                    Text("15").font(AppFonts.labelFont(6)).offset(y: 1)
                }
                .foregroundColor(AppColors.gold)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back fifteen seconds")

            Button(action: { session.togglePlayPause() }) {
                Group {
                    if session.isLoading {
                        SwiftUI.ProgressView().tint(AppColors.gold)
                    } else {
                        AppIcon(session.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 16)
                            .foregroundColor(AppColors.gold)
                    }
                }
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(session.isPlaying ? "Pause" : "Play")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardElevated)
                .shadow(color: .black.opacity(0.35), radius: 14, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.gold.opacity(0.14), lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
    }
}


// MARK: - The player

/// The reading, in full: what is sounding, where it has got to, and the
/// two settings that belong to a spoken book — how fast the voice reads,
/// and when it should stop.
///
/// Raised from the mini player on either surface, so the book page and
/// the reader open the same thing. There is no LISTEN section anywhere
/// any more: the contents ledger *is* the recording's ledger, and this
/// is its transport.
struct LibraryPlayerSheet: View {

    let session: LibraryListeningSession

    @Environment(\.dismiss) private var dismiss

    private var section: LibriVoxSection? {
        guard let index = session.trackIndex,
              session.sections.indices.contains(index) else { return nil }
        return session.sections[index]
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("THE READING")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                if let info = session.info {
                    HStack(alignment: .center, spacing: 14) {
                        BookCover(info: info, isLettered: false)
                            .frame(width: 46)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(section?.title ?? info.title)
                                .font(AppFonts.headlineFont(16))
                                .foregroundColor(AppColors.cream)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(info.author)
                                .font(AppFonts.italicFont(13))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 18)
                }

                LibraryTransportBar(session: session, trackTitle: "", showsTitle: false)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(height: 0.5)
                    .padding(.top, 20)

                HStack {
                    Text("HOW IT READS")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.6))

                    Spacer()

                    LibraryListenOptions(session: session)
                }
                .padding(.top, 12)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
        }
    }
}
