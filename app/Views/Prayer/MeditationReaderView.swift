//
//  MeditationReaderView.swift
//  Lumen Viae
//
//  The reader: the meditation given the whole screen, with the narration
//  condensed to a pill at its foot.
//
//  It opens over the player rather than replacing it, so the audio never
//  stops to change surfaces — closing the reader puts the full transport
//  back exactly where it was. The header collapses as reading gets
//  underway, and a focus band keeps the eye on the lines being read.
//

import SwiftUI

struct MeditationReaderView: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let meditation: Meditation

    /// "The Fourth Joyful Mystery" — where the Rosary stands
    let mysteryKicker: String

    let artworkAsset: String?
    let viewModel: PrayerSessionViewModel

    /// Everything the overflow menus need, assembled by the player so
    /// both surfaces offer the same acts.
    let actions: PrayerTrackActions

    /// Back to the player. Never ends the session.
    let onClose: () -> Void

    @State private var reader = ReaderScrollModel()
    /// The one sheet the reader presents at a time — same rule the
    /// player follows, and for the same reason.
    @State private var activeSheet: ReaderSheet?

    /// An act the ⋯ tray asked for, run once the tray is actually gone.
    /// Sequenced on `onDismiss` rather than a timer: presenting into a
    /// dismissal drops the new presentation.
    @State private var pendingHandoff: (() -> Void)?

    /// Measured height of the mini player, so the last paragraph can
    /// scroll clear of it instead of resting under it.
    @State private var pillHeight: CGFloat = 0

    var body: some View {
        ZStack {
            readerScroll

            VStack(spacing: 0) {
                header
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                MiniPlayerPill(
                    title: meditation.displayTitle,
                    artworkAsset: artworkAsset,
                    viewModel: viewModel,
                    onExpand: onClose,
                    onShowTray: { activeSheet = .tray }
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: PillHeightKey.self, value: geo.size.height)
                    }
                )
            }
        }
        // Behind the stack rather than inside it: a sibling that ignores
        // the safe area takes the safe area away from the rest, and the
        // mini player has to clear the home indicator
        .background(AppColors.appGradient.ignoresSafeArea())
        .onPreferenceChange(PillHeightKey.self) { pillHeight = $0 }
        .sheet(item: $activeSheet, onDismiss: runPendingHandoff) { sheet in
            switch sheet {
            case .textOptions:
                ReaderTextOptionsSheet()
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)

            case .tray:
                let placement = PrayerTrackPlacement.reader(onExpand: onClose)
                PrayerTrackTray(
                    actions: actions,
                    placement: placement,
                    pendingHandoff: $pendingHandoff
                )
                    .presentationDetents([
                        .height(prayerTrayHeight(for: placement, actions: actions))
                    ])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.cardBackground)
            }
        }
    }

    /// Runs whatever the tray handed over, exactly once.
    private func runPendingHandoff() {
        let action = pendingHandoff
        pendingHandoff = nil
        action?()
    }

    // MARK: - Header

    /// Close on the left, text options on the right, and between them the
    /// page's own name — set the way this app sets a reading everywhere
    /// else: gold kicker, serif title, ornament beneath.
    ///
    /// No artwork here. The painting is the player's; the reader is the
    /// text, and a thumbnail at the head of it is a second thing to look
    /// at where there should be one.
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                ReaderChromeButton(icon: "ph-x", size: 16, label: "Close the reader", action: onClose)
                Spacer()
                ReaderChromeButton(icon: "ph-text-aa", size: 18, label: "Text options") {
                    activeSheet = .textOptions
                }
            }
            .padding(.horizontal, 10)

            if reader.collapsed {
                // Reading is underway: the name shrinks to a rule of small
                // caps, the way the prayer flow has always kept its place
                Text(meditation.displayTitle.uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(2)
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .lineLimit(1)
                    .padding(.horizontal, 64)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            } else {
                VStack(spacing: 10) {
                    Text(mysteryKicker.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(3)
                        .foregroundColor(AppColors.gold)
                        .multilineTextAlignment(.center)

                    Text(meditation.displayTitle)
                        .font(AppFonts.headlineFont(25))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 28)

                    OrnamentDivider(showsCross: false)
                        .frame(width: 150)
                        .padding(.top, 4)
                }
                .padding(.top, 2)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .padding(.top, 6)
        .animation(.easeInOut(duration: 0.28), value: reader.collapsed)
    }

    // MARK: - The Page

    /// Room the page leaves for the floating header at rest.
    ///
    /// Deliberately not tied to `collapsed`: shrinking it on collapse
    /// moves the content up, the scroll watcher reads that movement as
    /// the reader scrolling back up, and the header expands again on the
    /// same frame. Only the header resizes; the page keeps its place.
    private static let headerInset: CGFloat = 196

    private var readerScroll: some View {
        let fontSize = userSettings.meditationFontSize
        // Split once per pass: this walks the whole meditation body, and
        // the reader re-renders on scroll, on the pill's height, and on
        // every sheet.
        let paragraphs = ReadingText.paragraphs(of: meditation.content)
        let count = paragraphs.count

        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(
                    alignment: .leading,
                    spacing: ReadingTypography.paragraphSpacing(for: fontSize)
                ) {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                        ReadingText(
                            text: paragraph,
                            size: fontSize,
                            showsDropCap: index == 0,
                            textColor: AppColors.cream.opacity(0.94)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("para-\(index)")
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, Self.headerInset)
                .padding(.bottom, pillHeight + 90)
                // A new decade is a new page: re-identifying the content
                // is what returns the reader to the top of it
                .id(viewModel.currentMysteryIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: viewModel.currentMysteryIndex)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ReaderPageOffsetKey.self,
                            value: geo.frame(in: .named("readerPage")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "readerPage")
            .mask(focusBand)
            .onPreferenceChange(ReaderPageOffsetKey.self) { reader.handleScroll(to: $0) }
            // Fresh mystery, fresh reading state — expanded header, and
            // follow-along no longer standing aside for a scroll the
            // reader made on the decade before
            .onChange(of: viewModel.currentMysteryIndex) { reader.reset() }
            .overlay(alignment: .top) {
                ReaderNarrationWatcher(
                    viewModel: viewModel,
                    reader: reader,
                    paragraphCount: count,
                    autoScroll: userSettings.readerAutoScroll,
                    proxy: proxy
                )
            }
        }
    }

    /// The lines you are on are lit; the page dims away above and below
    /// them. Text dissolves before it can reach the header or the pill,
    /// so neither needs a slab behind it.
    ///
    /// Skipped entirely when the reader has asked the system to reduce
    /// transparency — the effect is atmosphere, and atmosphere must not
    /// be the reason someone cannot read the page.
    @ViewBuilder
    private var focusBand: some View {
        if reduceTransparency {
            Rectangle().fill(.black)
        } else {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0), location: 0),
                    // The ramp has to be finished by the time the page
                    // begins, or the first line arrives already faded —
                    // these track the header's foot, not a comfortable
                    // distance below it
                    .init(color: .black.opacity(0), location: reader.collapsed ? 0.11 : 0.20),
                    .init(color: .black.opacity(0.45), location: reader.collapsed ? 0.15 : 0.245),
                    .init(color: .black, location: reader.collapsed ? 0.19 : 0.285),
                    .init(color: .black, location: 0.72),
                    .init(color: .black.opacity(0.30), location: 0.86),
                    .init(color: .black.opacity(0), location: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.28), value: reader.collapsed)
        }
    }
}

// MARK: - Reader Chrome Button

/// A quiet glyph button: the whole prayer flow's chrome, from the
/// reader's header to the player's utility row to the sheets' close
/// buttons. Unlike `PrayerHeaderButton` these sit on the page rather
/// than over artwork, so they carry no dark scrim — a disc here would
/// read as a blister on a plain background.
///
/// Only the tint varies between them, so it is a parameter and the 44pt
/// hit target is written once.
struct ReaderChromeButton: View {
    let icon: String
    var size: CGFloat = 16
    var tint: Color = AppColors.cream.opacity(0.85)
    var label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon(icon, size: size)
                .foregroundColor(tint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - Mini Player

/// The narration, condensed: the artwork small, the title, and the one
/// control that matters while reading.
struct MiniPlayerPill: View {

    let title: String
    let artworkAsset: String?
    let viewModel: PrayerSessionViewModel

    /// Back to the full transport.
    let onExpand: () -> Void

    /// Asks the reader to open the ⋯ tray — presentation belongs to the
    /// one view that owns a sheet, not to the pill.
    let onShowTray: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // The artwork and the name are the way back up, the way they
            // are in every mini player — the controls beside them keep
            // their own hit areas
            Button(action: onExpand) {
                HStack(spacing: 12) {
                    if let artworkAsset {
                        CachedAssetImage(artworkAsset)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Text(title)
                        .font(AppFonts.semiboldBodyFont(14))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)

                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to the player")

            if viewModel.currentMeditation?.hasAudio == true {
                Button {
                    viewModel.isPlaying.toggle()
                } label: {
                    Group {
                        if viewModel.isLoadingAudio {
                            ProgressView().tint(AppColors.gold)
                        } else {
                            AppIcon(viewModel.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 17)
                                .foregroundColor(AppColors.gold)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
            }

            Button(action: onShowTray) {
                AppIcon("ph-dots-three", size: 20)
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardElevated)
                .shadow(color: .black.opacity(0.35), radius: 14, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.gold.opacity(0.14), lineWidth: 0.5)
        )
        // The pill is chrome for the page behind it, not a list of
        // separate landmarks to swipe through
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Narration")
    }
}

// MARK: - ReaderSheet

/// What the reader can put over itself. One case at a time.
private enum ReaderSheet: String, Identifiable {
    case textOptions
    case tray

    var id: String { rawValue }
}

// MARK: - Text Options

/// How the page reads: how big, and whether it turns itself.
struct ReaderTextOptionsSheet: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = userSettings

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Text")
                    .font(AppFonts.headlineFont(20))
                    .foregroundColor(AppColors.cream)
                Spacer()
                ReaderChromeButton(
                    icon: "ph-x",
                    size: 15,
                    tint: AppColors.textSecondary,
                    label: "Close",
                    action: dismiss.callAsFunction
                )
            }
            .padding(.leading, 24)
            .padding(.trailing, 10)
            .padding(.top, 14)

            VStack(alignment: .leading, spacing: 10) {
                Text("SIZE")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)

                HStack(spacing: 14) {
                    Text("A")
                        .font(AppFonts.readingFont(13))
                        .foregroundColor(AppColors.textSecondary)

                    Slider(value: $settings.textSizeScale, in: 0...1)
                        .tint(AppColors.gold)
                        .accessibilityLabel("Text size")

                    Text("A")
                        .font(AppFonts.readingFont(24))
                        .foregroundColor(AppColors.cream)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            VStack(alignment: .leading, spacing: 10) {
                Text("WHILE LISTENING")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)

                ToggleRow(
                    icon: "ph-text-align-left",
                    title: "Follow the narration",
                    subtitle: "The page keeps pace with the voice",
                    isOn: $settings.readerAutoScroll
                )
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColors.cardBackground)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background.ignoresSafeArea())
    }
}

// MARK: - Narration Watcher

/// Keeps the page in step with the voice.
///
/// Reads `currentTime` in its own body on purpose: observed from the
/// reader, the twice-a-second tick would make the whole page a
/// dependency of the clock. Here it invalidates a zero-size view, and
/// writes outward only when the paragraph actually changes.
private struct ReaderNarrationWatcher: View {

    let viewModel: PrayerSessionViewModel
    let reader: ReaderScrollModel
    let paragraphCount: Int
    let autoScroll: Bool
    let proxy: ScrollViewProxy

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: viewModel.currentTime) { _, time in
                guard viewModel.isPlaying, viewModel.totalDuration > 0, paragraphCount > 0 else { return }

                // Without per-word timings the mapping is proportional —
                // paragraph N of M at N/M of the audio — which tracks
                // spoken pace closely enough.
                let fraction = min(max(time / viewModel.totalDuration, 0), 1)

                guard autoScroll,
                      let target = reader.paragraphToFollow(
                          fraction: fraction,
                          paragraphCount: paragraphCount
                      ) else { return }

                withAnimation(.easeInOut(duration: 1.2)) {
                    proxy.scrollTo("para-\(target)", anchor: UnitPoint(x: 0.5, y: 0.32))
                }
            }
    }
}

// MARK: - Preference Keys

nonisolated private struct ReaderPageOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - ReaderScrollModel

/// Reading bookkeeping: whether the header has collapsed, and how far
/// the narration has carried the page.
///
/// A model rather than view state because the scroll offset arrives on
/// every frame of every scroll. As `@State` each of those writes
/// invalidated the whole reader — re-splitting the meditation and
/// rebuilding the page — to move numbers nothing in the body reads.
/// Here only `collapsed` is observed, so only a real collapse redraws.
@Observable
final class ReaderScrollModel {

    /// True once reading has scrolled down far enough that the header
    /// gives way to its compact form
    var collapsed = false

    /// Last seen scroll offset, for scroll-direction detection
    @ObservationIgnored private var lastOffset: CGFloat = 0

    /// When the reader last moved the text themselves — follow-along
    /// stands aside for a few seconds after any manual scroll
    @ObservationIgnored private var lastManualScrollAt = Date.distantPast

    /// When follow-along last drove the scroll, so its own animated
    /// movement is never mistaken for the reader's hand
    @ObservationIgnored private var lastAutoScrollAt = Date.distantPast

    /// The paragraph follow-along last scrolled to
    @ObservationIgnored private var followTarget = 0

    /// The next offset report comes from a rebuilt page rather than the
    /// reader's hand: adopt it as the baseline instead of measuring the
    /// snap back to the top against the mystery just left — that jump
    /// reads as a manual scroll and mutes follow-along for four seconds
    /// at the start of every new decade.
    @ObservationIgnored private var needsBaseline = true

    /// A fresh mystery starts with fresh reading state.
    func reset() {
        collapsed = false
        lastOffset = 0
        lastManualScrollAt = .distantPast
        lastAutoScrollAt = .distantPast
        followTarget = 0
        needsBaseline = true
    }

    /// Collapse the header when scrolling down into the text; bring it
    /// back the moment the reader scrolls up, wherever they are. Any
    /// movement not caused by a recent follow-along animation counts as
    /// the reader's own scroll and pauses following.
    func handleScroll(to offset: CGFloat) {
        if needsBaseline {
            needsBaseline = false
            lastOffset = offset
            return
        }

        defer { lastOffset = offset }
        let delta = offset - lastOffset

        if abs(delta) > 2, Date().timeIntervalSince(lastAutoScrollAt) > 1.5 {
            lastManualScrollAt = Date()
        }

        if offset >= -40 || delta > 6 {
            if collapsed {
                withAnimation(.easeInOut(duration: 0.25)) { collapsed = false }
            }
        } else if delta < -6 {
            if !collapsed {
                withAnimation(.easeInOut(duration: 0.25)) { collapsed = true }
            }
        }
    }

    /// The paragraph the narration has reached, or nil when following
    /// should stand aside — the reader scrolled recently, or the page is
    /// already there.
    func paragraphToFollow(fraction: Double, paragraphCount: Int) -> Int? {
        guard paragraphCount > 0,
              Date().timeIntervalSince(lastManualScrollAt) > 4 else { return nil }

        let target = min(paragraphCount - 1, Int(fraction * Double(paragraphCount)))
        guard target != followTarget else { return nil }

        followTarget = target
        lastAutoScrollAt = Date()
        return target
    }
}

nonisolated private struct PillHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
