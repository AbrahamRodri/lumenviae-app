//
//  MeditationSetDetailView.swift
//  Lumen Viae
//
//  One meditation set, read before it is prayed.
//
//  The page is set like a title page rather than a product listing: the
//  labels as a kicker, an ornament, the set's name in Cinzel, and the
//  painting under it in a lancet arch — the frontispiece. Beneath that,
//  a ruled ledger of short sections, each named in gold down the left
//  margin: what the set is, the meditations it holds, whose voice they
//  are, and whether it's saved on the device. The first one waits behind
//  a quiet line for anyone who wants to hear that voice before
//  committing to five of it.
//
//  One gold act at the foot begins the Rosary, and nothing rides under
//  it — no count, and never a duration. A Rosary is not a podcast.
//
//  The full set loads behind the page so the button is instant. The
//  list comes from bundled data until it lands, so the page is never a
//  blank waiting on a cold server. The frontispiece is the set's own
//  painting when the API carries one, and the category's otherwise —
//  `SetArtworkView` decides, cropped around the point its curator chose.
//

import SwiftUI

struct MeditationSetDetailView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: MeditationSetDetailViewModel

    /// True from a "Pray" tap until the set is in hand — the preparing
    /// overlay shows only if the load is still running at that point
    @State private var isPreparingToPray = false

    /// The set failed to load when the user asked to pray with it
    @State private var showsLoadFailure = false

    /// Whether the first meditation is open on the page. Closed by
    /// default: the page's job is to let you begin, not to detain you.
    @State private var showsPreview = false

    init(summary: MeditationSetSummary) {
        self._viewModel = State(initialValue: MeditationSetDetailViewModel(summary: summary))
    }

    /// Preview/testing entry point with a pre-configured view model
    init(viewModel: MeditationSetDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.appGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        titling
                            .devotionalEntrance()

                        frontispiece(width: artworkWidth(for: geometry))
                            .padding(.top, 26)
                            .devotionalEntrance(delay: 0.08)

                        sections
                            .padding(.top, 34)
                            .devotionalEntrance(delay: 0.16)
                    }
                    // Clears the header chrome above and the fixed act below
                    .padding(.top, 62)
                    .padding(.bottom, 200)
                }
                .animation(.easeOut(duration: 0.3), value: viewModel.isLoading)
                .animation(.easeOut(duration: 0.25), value: showsPreview)
                // Scrolled content softens away behind the back and pin
                // rather than running under them at full strength.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.075),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // The one act, fixed at the foot
                VStack {
                    Spacer()
                    prayFoot
                }

                // Sits under the header buttons: Back stays reachable while
                // the set is fetched, so a cold server never traps the user
                // here for the length of a timeout.
                if isPreparingToPray && viewModel.fullSet == nil {
                    preparingOverlay
                        .transition(.opacity)
                }

                headerChrome
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
        // The set failed to load when the user asked to pray with it (cold
        // server or offline): offer a retry instead of silently
        // substituting content.
        .alert("Couldn't load these meditations", isPresented: $showsLoadFailure) {
            Button("Try Again") {
                // Let the alert finish dismissing before a retry can fail
                // and ask to present it again — a binding re-toggled
                // mid-dismissal is not reliably honored.
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    pray()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The server may still be waking up — it can take a few seconds. Downloading offline content in Account keeps every meditation available without a connection.")
        }
    }

    // MARK: - Chrome

    private var headerChrome: some View {
        VStack {
            HStack {
                PrayerHeaderButton(icon: "ph-caret-left", size: 16, label: "Back") {
                    router.pop()
                }

                Spacer()

                PrayerHeaderButton(
                    icon: viewModel.isPinned ? "ph-push-pin-fill" : "ph-push-pin",
                    size: 16,
                    label: viewModel.isPinned ? "Unpin these meditations" : "Pin these meditations to the top",
                    tint: viewModel.isPinned ? AppColors.gold : .white
                ) {
                    withAnimation(.easeOut(duration: 0.2)) { viewModel.togglePin() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Titling

    /// Kicker, ornament, name — the title page, centered and quiet.
    private var titling: some View {
        VStack(spacing: 16) {
            if !viewModel.labels.isEmpty {
                Text(MeditationLabel.displayLine(viewModel.labels))
                    .font(AppFonts.labelFont(9.5))
                    .tracking(3)
                    .foregroundColor(AppColors.gold)
                    .multilineTextAlignment(.center)
            }

            OrnamentDivider()
                .frame(width: 150)

            Text(viewModel.name)
                .font(AppFonts.titleFont(29))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Frontispiece

    /// A little over half the width, so the painting sits inside the page
    /// as a plate rather than taking it over; capped so an iPad doesn't
    /// blow it up to a poster.
    private func artworkWidth(for geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width * 0.56, 260)
    }

    /// The painting in a lancet arch, unframed — the shape is the frame.
    /// Proportioned as a cathedral window: a little taller than it is
    /// wide, so the arch reads as an arch and not as a rounded box.
    ///
    /// The set's own painting when it has one, cropped around the point
    /// its curator chose; the category's otherwise. A painting that came
    /// with a credit carries it beneath the plate, the way a museum plate
    /// does — small, and only when there is one.
    private func frontispiece(width: CGFloat) -> some View {
        let arch = GothicArchShape(riseRatio: 0.34)

        return VStack(spacing: 12) {
            arch
                .fill(AppColors.cardBackground)
                .frame(width: width, height: width * 1.22)
                .overlay(
                    SetArtworkView(
                        setId: viewModel.summary.id,
                        artwork: viewModel.artwork,
                        category: viewModel.category
                    )
                )
                .clipShape(arch)

            if let credit = viewModel.artworkCredit {
                Text(credit)
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)
            }
        }
    }

    // MARK: - The Ledger

    /// Short sections down the page, each named in the left margin and
    /// ruled off from the one above.
    private var sections: some View {
        VStack(spacing: 0) {
            if let description = viewModel.description {
                SetSection(label: "About\nthis set") {
                    ReadingText(text: description, size: 16)
                }
            }

            if !viewModel.entryTitles.isEmpty {
                SetSection(label: "The\nmeditations") { meditationList }
            }

            if viewModel.hasAttribution {
                SetSection(label: "From") { attribution }
            }

            offlineSection

            firstMeditationSection
        }
        .padding(.horizontal, 24)
    }

    /// The meditations this set holds, numbered the way a missal numbers
    /// them, with the devotion's own place in the week beneath.
    private var meditationList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(viewModel.entryTitles.enumerated()), id: \.offset) { index, title in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(Self.numeral(index + 1))
                        .font(AppFonts.labelFont(10))
                        .tracking(1)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                        .frame(width: 22, alignment: .leading)

                    Text(title)
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let context = viewModel.contextLine {
                Text(context)
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// The voice and the book behind the meditations — the thing a
    /// reader most wants to know about a set named for a saint, and the
    /// one piece the API already carried that the page never said.
    private var attribution: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let source = viewModel.sourceTitle {
                Text(source)
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let author = viewModel.authorName {
                Text(author)
                    .font(AppFonts.readingFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Offline

    /// Save this one set — its text and every narration — so it can be
    /// prayed with no connection.
    ///
    /// Account downloads the whole library at once, which is the right
    /// default and the wrong thing to ask of someone who wants one set
    /// before a flight. This is the same files by the same route, scoped
    /// to the set in front of you. It appears only once the set has
    /// loaded: what a set weighs offline depends on the narrations it
    /// carries, and until they're known the page can't honestly offer it.
    @ViewBuilder
    private var offlineSection: some View {
        if let state = viewModel.offlineState {
            SetSection(label: "Offline") {
                switch state {
                case .available:
                    offlineButton(
                        title: "Save on this device",
                        icon: "ph-download-simple",
                        color: AppColors.gold
                    )

                case .saving(let fraction):
                    savingIndicator(fraction: fraction)

                case .saved:
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            AppIcon("ph-check-circle", size: 14)
                                .foregroundColor(AppColors.gold.opacity(0.8))

                            Text("Saved on this device")
                                .font(AppFonts.readingFont(15))
                                .foregroundColor(AppColors.cream.opacity(0.92))
                        }

                        offlineButton(
                            title: "Remove",
                            icon: "ph-trash",
                            color: AppColors.textSecondary
                        )
                    }

                case .failed:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Some of it didn't come down. What finished was kept.")
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        offlineButton(
                            title: "Try again",
                            icon: "ph-arrow-counter-clockwise",
                            color: AppColors.gold
                        )
                    }
                }
            }
        }
    }

    /// The button keeps its 44pt target but gives its padding back to the
    /// section, so an "Offline" row doesn't stand twice as tall as the
    /// ones above it.
    private func offlineButton(title: String, icon: String, color: Color) -> some View {
        QuietGoldButton(
            title: title,
            leadingIcon: icon,
            leadingIconSize: 13,
            size: 10,
            color: color,
            horizontalPadding: 0
        ) {
            Task { await viewModel.toggleOfflineCopy() }
        }
        .padding(.vertical, -10)
    }

    /// A fine gold rule filling left to right — the same restraint as the
    /// bead strand, without pretending a file transfer is a devotion.
    private func savingIndicator(fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SAVING")
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.8))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.gold.opacity(0.15))

                    Capsule()
                        .fill(AppColors.goldGradient)
                        .frame(width: max(2, geometry.size.width * fraction))
                }
            }
            .frame(height: 2)
            .animation(.easeOut(duration: 0.3), value: fraction)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Saving on this device, \(Int(fraction * 100)) percent")
    }

    // MARK: - The First Meditation

    /// One of the five, in full, behind a line you have to ask for.
    ///
    /// It used to sit open at the foot of the page, which meant the act
    /// was always a long scroll away and the page read as an article
    /// rather than a threshold. Closed, the page ends where the button
    /// is; opened, the whole meditation is there — never a clamped
    /// excerpt fading out mid-thought.
    @ViewBuilder
    private var firstMeditationSection: some View {
        if let previewText = viewModel.previewText {
            VStack(alignment: .leading, spacing: 0) {
                sectionRule

                if showsPreview {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("The first meditation  ·  \(viewModel.previewSubject)")
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ReadingText(text: previewText, size: 17)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        QuietGoldButton(
                            title: "Close",
                            leadingIcon: "ph-caret-up",
                            leadingIconSize: 10,
                            size: 10,
                            color: AppColors.gold.opacity(0.75),
                            horizontalPadding: 0
                        ) {
                            showsPreview = false
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                } else {
                    QuietGoldButton(
                        title: "Read the first meditation",
                        leadingIcon: "ph-book-open",
                        leadingIconSize: 12,
                        trailingIcon: "ph-caret-down",
                        size: 10,
                        color: AppColors.gold,
                        horizontalPadding: 0
                    ) {
                        showsPreview = true
                    }
                    .padding(.vertical, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if viewModel.loadFailed {
            VStack(spacing: 10) {
                sectionRule

                Text("Couldn't load these meditations. The server may still be waking up.")
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                QuietGoldButton(
                    title: "Try again",
                    leadingIcon: "ph-arrow-counter-clockwise",
                    leadingIconSize: 11,
                    size: 10,
                    color: AppColors.gold
                ) {
                    Task { await viewModel.load() }
                }
            }
        } else if viewModel.fullSet != nil {
            // Loaded, but nothing to open: no meditations, or an empty first
            // one. Say so — and the act below stays quiet.
            VStack(spacing: 0) {
                sectionRule

                Text("These meditations aren't available yet.")
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
            }
        }
        // Still loading: nothing here. The sections above are already
        // readable from bundled data, so a spinner would be the only
        // restless thing on a page that is otherwise complete.
    }

    private var sectionRule: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.18))
            .frame(height: 0.5)
    }

    // MARK: - Pray

    /// The act, alone. Nothing is set beneath it — a count or a running
    /// time there turns the page's one invitation into a label on a
    /// product.
    private var prayFoot: some View {
        GoldCTAButton(title: "Pray", showsCross: false) {
            pray()
        }
        .disabled(!viewModel.hasMeditations)
        .padding(.horizontal, 32)
        .padding(.top, 96)
        .padding(.bottom, 22)
        .background(
            // The scrim under the act must have no findable edge.
            //
            // Two things give one away. A short ramp shows the eye where
            // it starts, so this one runs the full height of the band in
            // many stops rather than three. And a scrim tinted with
            // `background` lightens the page it covers here — the app
            // gradient is already running down toward `backgroundDeep`
            // by the foot of the screen — which reads as a band. Tinting
            // it in `backgroundDeep` instead only ever deepens, and lands
            // on exactly the color the page itself ends on.
            LinearGradient(
                stops: [
                    .init(color: AppColors.backgroundDeep.opacity(0), location: 0),
                    .init(color: AppColors.backgroundDeep.opacity(0.04), location: 0.12),
                    .init(color: AppColors.backgroundDeep.opacity(0.14), location: 0.24),
                    .init(color: AppColors.backgroundDeep.opacity(0.32), location: 0.36),
                    .init(color: AppColors.backgroundDeep.opacity(0.56), location: 0.47),
                    .init(color: AppColors.backgroundDeep.opacity(0.78), location: 0.57),
                    .init(color: AppColors.backgroundDeep.opacity(0.93), location: 0.67),
                    .init(color: AppColors.backgroundDeep, location: 0.78),
                    .init(color: AppColors.backgroundDeep, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            // The fade is ground for the button, not a control: drags that
            // begin in it must still scroll the page beneath.
            .allowsHitTesting(false)
        )
    }

    private var preparingOverlay: some View {
        AppColors.background.opacity(0.72)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(AppColors.gold)

                    Text("PREPARING THE MEDITATIONS")
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5)
                )
            )
    }

    /// Starts the Rosary with this set. If the full set is still loading,
    /// waits on that same load; a cold server can answer long after the
    /// user gave up and navigated away, so the generation token guards
    /// against a stale response mutating the stack.
    private func pray() {
        guard !isPreparingToPray else { return }
        isPreparingToPray = true
        let generation = router.generation

        Task {
            defer { isPreparingToPray = false }
            do {
                let fullSet = try await viewModel.resolve()
                guard router.generation == generation else { return }
                router.navigateToPrayerSession(meditationSet: fullSet)
            } catch {
                guard router.generation == generation else { return }
                showsLoadFailure = true
            }
        }
    }

    /// Roman numerals for the mystery list. Never needs past seven.
    private static func numeral(_ n: Int) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        return n >= 1 && n <= numerals.count ? numerals[n - 1] : "\(n)"
    }
}

// MARK: - SetSection

/// One entry in the page's ledger: a hairline, the section's name set in
/// gold caps down the left margin, and its content beside it.
///
/// The two columns fold into one under the accessibility text sizes — a
/// 74pt margin that has grown to fit 30pt caps leaves nothing for the
/// reading beside it.
private struct SetSection<Content: View>: View {

    let label: String
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Wide enough for the longest label the page sets — "MEDITATIONS"
    /// tracked out — so no margin label ever breaks mid-word.
    @ScaledMetric(relativeTo: .caption) private var labelWidth: CGFloat = 94

    private var isStacked: Bool { dynamicTypeSize >= .accessibility1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.18))
                .frame(height: 0.5)

            Group {
                if isStacked {
                    VStack(alignment: .leading, spacing: 12) {
                        marginLabel
                        content
                    }
                } else {
                    HStack(alignment: .top, spacing: 14) {
                        marginLabel
                            .frame(width: labelWidth, alignment: .leading)

                        content
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.vertical, 26)
        }
    }

    private var marginLabel: some View {
        Text(label.uppercased())
            .font(AppFonts.labelFont(8.5))
            .tracking(1.6)
            .lineSpacing(4)
            .foregroundColor(AppColors.gold)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Previews

#Preview("Loaded set") {
    let summary = MeditationSetSummary(
        id: 27,
        name: "Blessed Fulton J. Sheen",
        category: "sorrowful",
        description: "Meditations on the Sorrowful Mysteries from Bishop Fulton J. Sheen",
        labels: ["Considerations"],
        author: "Bishop Fulton J. Sheen",
        source: "The Fifteen Mysteries of the Rosary"
    )
    let meditation = Meditation(
        id: 126,
        title: nil,
        content: "As a kind person in the face of pain seeks to relieve the sufferings of his friend, so does moral kindness in the face of evil take on the punishment which evil deserves. Every mother would willingly, if she could, bear the aches of her child.",
        author: "Bishop Fulton J. Sheen",
        source: "The Fifteen Mysteries of the Rosary",
        audioUrl: nil,
        mystery: MysteryData.sorrowful[0]
    )
    let set = MeditationSet(
        id: 27,
        name: summary.name,
        category: "sorrowful",
        description: summary.description,
        labels: summary.labels,
        meditations: [meditation]
    )

    return MeditationSetDetailView(
        viewModel: MeditationSetDetailViewModel(
            summary: summary,
            favorites: FavoritesService(previewFavorites: [27]),
            preloadedSet: set
        )
    )
    .environment(AppRouter())
}

#Preview("Live API") {
    MeditationSetDetailView(
        summary: MeditationSetSummary(
            id: 42,
            name: "Blessed Anne Catherine Emmerich",
            category: "joyful",
            description: "Verbatim passages from the visions of Blessed Anne Catherine Emmerich on the Joyful Mysteries.",
            labels: ["Contemplative"]
        )
    )
    .environment(AppRouter())
}
