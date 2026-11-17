//
//  MeditationSetDetailView.swift
//  Lumen Viae
//
//  One meditation set, confirmed before it is prayed.
//
//  The Rosary's own page (`RosaryConfirmPage`), shared with the
//  Scriptural Rosary and the Holy Rosary: the set's painting dissolving
//  into the page, its mysteries as the kicker, its name in Cinzel and a
//  line from its description, then YOUR ROSARY TODAY — the voice and its
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

    /// The simple Rosary's beginner's path: the page says so over the
    /// choices, offers a way to say no, and PRAY begins with the helps on
    private let beginner: Bool
    private let onDecline: (() -> Void)?

    init(summary: MeditationSetSummary, beginner: Bool = false, onDecline: (() -> Void)? = nil) {
        self._viewModel = State(initialValue: MeditationSetDetailViewModel(summary: summary))
        self.beginner = beginner
        self.onDecline = onDecline
    }

    /// Preview/testing entry point with a pre-configured view model
    init(viewModel: MeditationSetDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self.beginner = false
        self.onDecline = nil
    }

    var body: some View {
        RosaryConfirmPage(
            kicker: viewModel.category.map { String(
                localized: "The \($0.devotionTitle)",
                comment: "A meditation set's page: small capitals over the set's name, the mysteries it belongs to, like The Joyful Mysteries"
            ) } ?? String(
                localized: "The Rosary",
                comment: "A meditation set's page: small capitals over the set's name when its mysteries are not known"
            ),
            title: viewModel.name,
            // One line: the book the meditations are from, the page's
            // "From" moved up (Abraham, 17 Nov 2026: "the from is kind of
            // important"); the description, the list of the mysteries and
            // the painting's credit leave the page (the credit stays on
            // Sources)
            subtitle: viewModel.sourceTitle.map { source in
                String(localized: "From \(source)", comment: "A meditation set's page: the one line under its name, the book its meditations are from")
            } ?? viewModel.subtitle,
            prayEnabled: viewModel.hasMeditations,
            preparing: isPreparingToPray && viewModel.fullSet == nil ? String(
                localized: "Preparing the meditations",
                comment: "A meditation set's page: shown on the Pray button while the set is still loading after Pray was tapped"
            ) : nil,
            prompt: beginner ? RosaryConfirmPrompt(
                text: String(
                    localized: "New to the Rosary? Pray it with St. Alphonsus's meditations, and a line on each step tells you what to pray and which bead you are on.",
                    comment: "Simple Rosary, the beginner's path: the line over a meditation set's choices for someone who came to learn the Rosary"),
                decline: String(
                    localized: "No thanks, I'll choose",
                    comment: "Simple Rosary, the beginner's path: the quiet button that declines and opens the day's mysteries' page"),
                onDecline: { onDecline?() }
            ) : nil,
            footLink: viewModel.previewText == nil ? nil : RosaryConfirmFootLink(
                title: String(
                    localized: "Read the first meditation",
                    comment: "A meditation set's page: button that unfolds the first meditation's text"),
                action: { showsPreview = true }),
            onBack: { router.pop() },
            onPray: pray
        ) {
            SetArtworkView(
                setId: viewModel.summary.id,
                artwork: viewModel.artwork,
                category: viewModel.category
            )
        } choices: {
            SetSettingsCard(category: viewModel.category, offline: viewModel.offlineState) {
                Task { await viewModel.toggleOfflineCopy() }
            }
            .animation(Motion.crossfade, value: viewModel.offlineState == nil)
        } ledger: {
            loadNotes
        }
        .sheet(isPresented: $showsPreview) {
            firstMeditationSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .sheetGround()
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
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
            Text("We couldn't reach the meditations. Try again in a few seconds. To pray without a connection, open Settings and choose Save for Offline.")
        }
    }

    // MARK: - Under the card

    /// Only what the page must say about loading: a set that would not
    /// load, with Try again, or one that has nothing to open
    @ViewBuilder
    private var loadNotes: some View {
        if viewModel.loadFailed {
            VStack(spacing: 10) {
                Text("Couldn't load these meditations. Check your connection and try again.")
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                QuietGoldButton(
                    title: String(
                        localized: "Try again",
                        comment: "A meditation set's page: button that tries the download or the load again"
                    ),
                    leadingIcon: "ph-arrow-counter-clockwise",
                    leadingIconSize: 11,
                    size: 10,
                    color: AppColors.gold
                ) {
                    Task { await viewModel.load() }
                }
            }
        } else if viewModel.fullSet != nil, viewModel.previewText == nil {
            Text("These meditations aren't available yet.")
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    /// The first meditation in full, behind the quiet link under PRAY
    private var firstMeditationSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SheetHeader(
                    kicker: String(localized: "The first meditation", comment: "A meditation set's page: the kicker over the first meditation, read in a sheet"),
                    title: viewModel.previewSubject
                ) {
                    SheetHeaderAction(title: String(localized: "Done", comment: "Sheet header button that closes the sheet")) {
                        showsPreview = false
                    }
                }
                if let previewText = viewModel.previewText {
                    ReadingText(text: previewText, size: 17)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, SheetMetrics.gutter)
                    MeditationLanguageNote(meditation: viewModel.firstMeditation)
                        .padding(.horizontal, SheetMetrics.gutter)
                }
            }
            .padding(.bottom, 32)
        }
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
                router.navigateToPrayerSession(meditationSet: fullSet, showsHelps: beginner)
            } catch {
                guard router.generation == generation else { return }
                showsLoadFailure = true
            }
        }
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
