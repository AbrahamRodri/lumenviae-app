//
//  MeditationReaderView.swift
//  Lumen Viae
//
//  The reader: the meditation given the whole screen, with the narration
//  condensed to a pill at its foot.
//
//  It opens over the player rather than replacing it, so the audio never
//  stops to change surfaces — closing the reader puts the full transport
//  back exactly where it was — by the ×, the pill, or pulling the page
//  down. The header holds still, and a focus band keeps the eye on the
//  lines being read, dissolving the text before it reaches the title.
//

import SwiftUI

struct MeditationReaderView: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let meditation: Meditation

    /// "The Fourth Joyful Mystery" — where the Rosary stands
    let mysteryKicker: String

    /// The painting the player is showing, for the mini player's thumbnail
    let painting: PrayerPainting?
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

    /// What the floating header takes up, measured rather than assumed:
    /// how tall it stands, and where its foot falls on the screen.
    ///
    /// The page's resting top and the focus band both hang off this
    /// rather than off fixed numbers, so a title that wraps to two lines
    /// carries the whole reading down with it — the text still begins
    /// its own distance below the ornament, the dissolve still finishes
    /// clear of the title's words, and the band is the same on every
    /// size of phone.
    @State private var headerMetrics = HeaderMetrics()

    /// How far the page has been pulled down toward the player, following
    /// the finger. Stays wherever the finger left it when a pull closes
    /// the reader, so the player's slide-away picks up from there instead
    /// of snapping back to the top first.
    @State private var pullOffset: CGFloat = 0

    /// Whether the pull underway is allowed to move the page. Decided
    /// once, from the first movement, and held for the rest of the
    /// gesture: a pull that begins sideways belongs to the player's
    /// swipe between mysteries, and one that begins on the text only
    /// counts if the page was resting at its top.
    @State private var pullArmed: Bool?

    var body: some View {
        ZStack {
            readerScroll

            VStack(spacing: 0) {
                header
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()

                // Band and pill measured together: the scroll clears the
                // whole foot, so a long verse can't hide the last lines
                // of the meditation behind it.
                VStack(spacing: 0) {
                    // The Scriptural Rosary rides here too. The view
                    // model owns the decision, so the reader shows
                    // exactly what the painting shows — the setting is
                    // not a feature of one surface.
                    if let verse = viewModel.currentScripturalVerse {
                        ScripturalVerseBand(
                            verse: verse,
                            beadIndex: viewModel.currentBeadIndex,
                            beadCount: viewModel.scripturalVerses.count,
                            size: userSettings.meditationFontSize - 1,
                            onAdvance: { viewModel.advanceBead() },
                            onRetreat: { viewModel.retreatBead() }
                        )
                        .padding(.horizontal, 18)
                        .padding(.bottom, 14)
                        .sensoryFeedback(.selection, trigger: verse)
                    }

                    MiniPlayerPill(
                        title: meditation.displayTitle,
                        painting: painting,
                        viewModel: viewModel,
                        onExpand: onClose,
                        onShowTray: { activeSheet = .tray }
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
                }
                // Only where there is a verse to protect: the pill alone
                // has always floated over the scrolling text, and it
                // reads fine. A verse does not — two texts through each
                // other are worse than either — so the band stands on the
                // page's own colour, with a short ramp above it that
                // dissolves the meditation's last line into the page.
                .background(alignment: .top) {
                    if viewModel.currentScripturalVerse != nil {
                        VStack(spacing: 0) {
                            LinearGradient(
                                gradient: .smoothFade(to: AppColors.background, from: 0),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)

                            AppColors.background
                        }
                        .padding(.top, -30)
                        .ignoresSafeArea(edges: .bottom)
                    }
                }
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
        // The page follows a downward pull; the player shows beneath
        .offset(y: pullOffset)
        .onPreferenceChange(PillHeightKey.self) { pillHeight = $0 }
        .onPreferenceChange(HeaderMetricsKey.self) { headerMetrics = $0 }
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

    // MARK: - Pull to Close

    /// How far down a pull has to travel before letting go closes the
    /// reader — or, flicked, how far it would have travelled.
    private static let closePullDistance: CGFloat = 120
    private static let closeFlickDistance: CGFloat = 280

    /// A pull let go short of the threshold settles back into place.
    private static let settleMotion = Animation.spring(response: 0.34, dampingFraction: 0.86)

    /// Pulling the page down toward the player, the way a sheet is sent
    /// away. From the header it always counts; from the text (`fromText`)
    /// only when the page was resting at its top, so a pull anywhere
    /// lower is just the scroll it has always been.
    ///
    /// Closing is handed to the player, which animates the reader the
    /// rest of the way off; the page stays where the finger left it so
    /// that slide picks up mid-air. A gesture is a shortcut, never the
    /// only way — the × and the pill still close the reader.
    private func pullToClose(fromText: Bool) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                if pullArmed == nil {
                    let t = value.translation
                    // Downward and mostly vertical, or it is the player's
                    // swipe between mysteries and not ours to move
                    guard t.height > 0, t.height > abs(t.width) * 1.2 else {
                        pullArmed = false
                        return
                    }
                    pullArmed = fromText ? reader.isAtTop : true
                }
                guard pullArmed == true else { return }
                pullOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                defer { pullArmed = nil }
                guard pullArmed == true else { return }
                let pulled = value.translation.height
                let flung = value.predictedEndTranslation.height
                if pulled > Self.closePullDistance || flung > Self.closeFlickDistance {
                    onClose()
                } else {
                    withAnimation(Self.settleMotion) { pullOffset = 0 }
                }
            }
    }

    /// True while a pull has taken hold of the page; the scroll view
    /// stands aside so the text isn't also rubber-banding under the
    /// finger.
    private var pulling: Bool { pullArmed == true && pullOffset > 0 }

    // MARK: - Header

    /// Close on the left, text options on the right, and between them the
    /// page's own name — set the way this app sets a reading everywhere
    /// else: gold kicker, serif title, ornament beneath.
    ///
    /// No artwork here. The painting is the player's; the reader is the
    /// text, and a thumbnail at the head of it is a second thing to look
    /// at where there should be one.
    ///
    /// The header keeps its shape while reading; the page dissolves as it
    /// scrolls up beneath it (see `focusBand`) rather than the title
    /// shrinking to make room.
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
            .padding(.top, 6)
            .padding(.bottom, 22)
        }
        .padding(.top, 10)
        // The whole band is a handle, not just the glyphs in it
        .contentShape(Rectangle())
        .gesture(pullToClose(fromText: false))
        .measuringHeader()
    }

    // MARK: - The Page

    /// Clear space between the header's foot and the first line of the
    /// reading. Held constant however tall the header stands, so a title
    /// of two lines pushes the page down rather than crowding it.
    private static let pageGap: CGFloat = 40

    /// Room the page leaves for the header before the first measurement
    /// lands — a one-line title's worth.
    private static let headerInset: CGFloat = 196

    /// Where the reading begins, measured from the top of the scroll
    /// view. The header shares that top edge, so its own height is the
    /// whole of the inset.
    private var pageTopInset: CGFloat {
        headerMetrics.height > 0 ? headerMetrics.height + Self.pageGap : Self.headerInset
    }

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
                .padding(.top, pageTopInset)
                .padding(.bottom, pillHeight + 90)
                // A new decade is a new page: re-identifying the content
                // is what returns the reader to the top of it
                .id(viewModel.currentMysteryIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: viewModel.currentMysteryIndex)
                // The iOS 17 scroll-offset path; see `onReaderPageOffsetChange`
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
            .scrollDisabled(pulling)
            // Alongside the scroll, not instead of it: the gesture decides
            // from its first movement whether this pull is the page's
            .simultaneousGesture(pullToClose(fromText: true))
            .mask(focusBand)
            .onReaderPageOffsetChange { reader.handleScroll(to: $0) }
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
            GeometryReader { geometry in
                let height = max(geometry.size.height, 1)
                // The header's foot in the band's own space — or, before
                // the first measurement lands, where a one-line header
                // would put it
                let foot = headerMetrics.foot > 0
                    ? headerMetrics.foot - geometry.frame(in: .global).minY
                    : height * 0.25

                LinearGradient(
                    stops: Self.focusStops(headerFoot: foot, height: height),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    /// The band's stops, hung from the header's foot. Nothing is left of
    /// the text 44pt above that foot — which is under the ornament, below
    /// the title's last line, so the words of the title are never read
    /// through whatever is scrolling past them, however many lines they
    /// run to. The ramp finishes 24pt below the foot, and the page at
    /// rest begins further down still (`pageGap`), so the first line
    /// never arrives already faded. The other end of the band, where the
    /// page dims behind the mini player, keeps to fractions of the screen.
    private static func focusStops(headerFoot: CGFloat, height: CGFloat) -> [Gradient.Stop] {
        let top = 0.72
        func at(_ y: CGFloat) -> CGFloat { min(max(y / height, 0), top) }
        return [
            .init(color: .black.opacity(0), location: 0),
            .init(color: .black.opacity(0), location: at(headerFoot - 44)),
            .init(color: .black.opacity(0.45), location: at(headerFoot - 10)),
            .init(color: .black, location: at(headerFoot + 24)),
            .init(color: .black, location: top),
            .init(color: .black.opacity(0.30), location: 0.86),
            .init(color: .black.opacity(0), location: 0.94)
        ]
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
    let painting: PrayerPainting?
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
                    if let painting {
                        FocalFill(image: painting.image, intrinsicSize: painting.intrinsicSize, focal: painting.focal)
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

/// How tall the reader's header stands, and where its bottom edge falls
/// in screen points.
nonisolated private struct HeaderMetrics: Equatable {
    var height: CGFloat = 0
    var foot: CGFloat = 0
}

nonisolated private struct HeaderMetricsKey: PreferenceKey {
    static var defaultValue: HeaderMetrics { HeaderMetrics() }

    /// Keeps the one real measurement rather than the last one seen. The
    /// header is a middle child of the reader's stack, and the siblings
    /// after it — the mini player — answer with the empty default; a
    /// last-one-wins reduce lets that default overwrite the header and
    /// leaves everything hung off it stuck on its fallback.
    static func reduce(value: inout HeaderMetrics, nextValue: () -> HeaderMetrics) {
        let next = nextValue()
        if next.height > 0 { value = next }
    }
}

private extension View {

    /// Reports this view's height and its bottom edge in screen points —
    /// the header, for everything hung beneath it.
    func measuringHeader() -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: HeaderMetricsKey.self,
                    value: HeaderMetrics(
                        height: geometry.size.height,
                        foot: geometry.frame(in: .global).maxY
                    )
                )
            }
        )
    }

    /// Reports where the page's top edge stands against the scroll
    /// view's: 0 at rest, falling negative as reading scrolls down.
    ///
    /// Read off the scroll geometry itself where that API exists. The
    /// older way — a `GeometryReader` behind the page measuring its
    /// frame in the scroll view's named coordinate space — stopped
    /// updating during scrolls on iOS 26, which silently froze
    /// follow-along's sense of the reader's hand. It stays as the path
    /// for iOS 17, where it still works.
    @ViewBuilder
    func onReaderPageOffsetChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18, *) {
            onScrollGeometryChange(for: CGFloat.self) { geometry in
                -(geometry.contentOffset.y + geometry.contentInsets.top)
            } action: { _, offset in
                action(offset)
            }
        } else {
            onPreferenceChange(ReaderPageOffsetKey.self, perform: action)
        }
    }
}

// MARK: - ReaderScrollModel

/// Reading bookkeeping: where the page stands, whether the reader's own
/// hand moved it lately, and how far the narration has carried it.
///
/// A model rather than view state because the scroll offset arrives on
/// every frame of every scroll. As `@State` each of those writes
/// invalidated the whole reader — re-splitting the meditation and
/// rebuilding the page — to move numbers nothing in the body reads.
/// Nothing here is observed; the view reads it only from gesture and
/// narration callbacks.
@Observable
final class ReaderScrollModel {

    /// True while the page rests at its top — the one place a downward
    /// pull on the text means "back to the player" rather than "scroll".
    @ObservationIgnored private(set) var isAtTop = true

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
        isAtTop = true
        lastOffset = 0
        lastManualScrollAt = .distantPast
        lastAutoScrollAt = .distantPast
        followTarget = 0
        needsBaseline = true
    }

    /// The reader moved the page themselves. Following stands aside for
    /// a few seconds afterwards.
    ///
    /// The offset-based path below serves a reader that reports its
    /// scroll position; a reader driven by `scrollPosition(id:)` has no
    /// offset to report and says so directly.
    func noteManualMove() {
        lastManualScrollAt = Date()
    }

    /// Any movement not caused by a recent follow-along animation counts
    /// as the reader's own scroll and pauses following.
    func handleScroll(to offset: CGFloat) {
        // At rest the page's top sits at 0; scrolled into, it goes
        // negative. A hair of slack so a settled page counts as at top.
        isAtTop = offset >= -1

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
