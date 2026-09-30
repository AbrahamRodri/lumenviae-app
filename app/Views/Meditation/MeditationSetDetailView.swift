//
//  MeditationSetDetailView.swift
//  Lumen Viae
//
//  One meditation set, confirmed before it is prayed.
//
//  The Rosary's own page (`RosaryConfirmPage`), shared with the
//  Scriptural Rosary and the Holy Rosary: the set's painting dissolving
//  into the page, its mysteries as the kicker, its name in Cinzel and a
//  line from its description, then YOUR ROSARY TODAY — Audio, Counting
//  while the voice reads the meditation alone, and the voice and its
//  speed — over PRAY.
//
//  Past the choices, a ruled ledger of short sections named in gold
//  down the left margin: the rest of what the set is, the meditations it
//  holds, whose voice they are, whether it's saved on the device, and
//  the first meditation behind a quiet line for anyone who wants to hear
//  that voice before committing to five of it. The page's first screen
//  is the confirmation; the ledger is there for whoever scrolls.
//
//  One gold act at the foot begins the Rosary, and nothing rides under
//  it — no count, and never a duration. A Rosary is not a podcast.
//
//  The full set loads behind the page so the button is instant. The
//  list comes from bundled data until it lands, so the page is never a
//  blank waiting on a cold server. The painting is the set's own when
//  the API carries one, and the category's otherwise — `SetArtworkView`
//  decides, cropped around the point its curator chose.
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
        RosaryConfirmPage(
            kicker: viewModel.category.map { "The \($0.devotionTitle)" } ?? "The Rosary",
            title: viewModel.name,
            subtitle: viewModel.subtitle,
            prayEnabled: viewModel.hasMeditations,
            preparing: isPreparingToPray && viewModel.fullSet == nil ? "Preparing the meditations" : nil,
            onBack: { router.pop() },
            onPray: pray
        ) {
            SetArtworkView(
                setId: viewModel.summary.id,
                artwork: viewModel.artwork,
                category: viewModel.category
            )
        } choices: {
            RosaryChoicesSection(form: .meditation, category: viewModel.category)
        } ledger: {
            sections
                .animation(Motion.crossfade, value: viewModel.isLoading)
                .animation(Motion.crossfade, value: showsPreview)
        }
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
            Text("The server may still be waking up — it can take a few seconds. Downloading offline content in Settings keeps every meditation available without a connection.")
        }
    }

    // MARK: - The Ledger

    /// Short sections down the page, each named in the left margin and
    /// ruled off from the one above.
    private var sections: some View {
        VStack(spacing: 0) {
            if let about = viewModel.about {
                SetSection(label: "About\nthis set") {
                    ReadingText(text: about, size: 16)
                }
            }

            if !viewModel.entryTitles.isEmpty {
                SetSection(label: "The\nmeditations") { meditationList }
            }

            if viewModel.hasAttribution {
                SetSection(label: "From") { attribution }
            }

            // The painting's credit, the way a museum plate carries one —
            // small, and only when the painting came with one
            if let credit = viewModel.artworkCredit {
                SetSection(label: "The\npainting") {
                    Text(credit)
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            offlineSection

            firstMeditationSection
        }
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
                // One slot for the four states, so save → saving → saved
                // crossfade over one another instead of the row being
                // torn down and rebuilt
                ZStack(alignment: .topLeading) {
                    switch state {
                    case .available:
                        offlineButton(
                            title: "Save on this device",
                            icon: "ph-download-simple",
                            color: AppColors.gold
                        )
                        .transition(.opacity)

                    case .saving(let fraction):
                        savingIndicator(fraction: fraction)
                            .transition(.opacity)

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
                        .transition(.opacity)

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
                        .transition(.opacity)
                    }
                }
                .animation(Motion.crossfade, value: Self.offlineStage(of: state))
            }
        }
    }

    /// Which of the four the offline row is in, ignoring how far along
    /// a save is — the bar animates its own progress
    private static func offlineStage(of state: OfflineContentService.SetOfflineState) -> Int {
        switch state {
        case .available: return 0
        case .saving: return 1
        case .saved: return 2
        case .failed: return 3
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
            .animation(Motion.ease(0.3), value: fraction)
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

                // The line and the meditation share one slot: opening is
                // the text rising in over the line as the page makes room
                ZStack(alignment: .topLeading) {
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
                    .transition(.opacity.combined(with: .offset(y: -8)))
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
                    .transition(.opacity)
                }
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
            .frame(height: AppLine.hairline)
    }

    // MARK: - Pray

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

/// One entry in a title page's ledger: a hairline, the section's name
/// set in gold caps down the left margin, and its content beside it.
/// Shared with the Scriptural Rosary's page, which is set the same way.
///
/// The two columns fold into one under the accessibility text sizes — a
/// 74pt margin that has grown to fit 30pt caps leaves nothing for the
/// reading beside it.
struct SetSection<Content: View>: View {

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
                .frame(height: AppLine.hairline)

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
    .environment(UserSettings.shared)
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
    .environment(UserSettings.shared)
}
