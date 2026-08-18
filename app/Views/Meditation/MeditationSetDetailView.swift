//
//  MeditationSetDetailView.swift
//  Lumen Viae
//
//  One meditation set, read before it is prayed.
//
//  Deliberately simple — the API says little about a set beyond its
//  name, its labels and a description, so that is what the page says:
//  the painting full-bleed from the top of the screen, the name, the
//  description, the opening of the first mystery as a taste of the
//  voice, and one gold act at the foot that begins the Rosary with these
//  meditations.
//
//  The full set loads behind the page so the button is instant. Until
//  the API carries artwork per set, the hero borrows the category's own
//  painting.
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
                        hero(height: heroHeight(for: geometry))
                            .devotionalEntrance()

                        VStack(spacing: 28) {
                            if let description = viewModel.description {
                                aboutCard(description)
                                    .padding(.horizontal, 20)
                            }

                            opening
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 20)
                        .devotionalEntrance(delay: 0.1)
                    }
                    // Just enough for the last card to clear the fixed button
                    // when scrolled to the end — no dead scroll past it.
                    .padding(.bottom, 92)
                }
                .animation(.easeOut(duration: 0.3), value: viewModel.isLoading)
                // The painting begins at the very top of the screen, behind
                // the status bar, the way the prayer screen's artwork does.
                .ignoresSafeArea(edges: .top)

                // The one act, fixed at the foot
                VStack {
                    Spacer()
                    prayButton
                }

                // Sits under the header buttons: Back stays reachable while
                // the set is fetched, so a cold server never traps the user
                // here for the length of a timeout.
                if isPreparingToPray && viewModel.fullSet == nil {
                    preparingOverlay
                        .transition(.opacity)
                }

                // Back and pin over the art
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

    /// Half the screen, so a small phone still shows the description
    /// under the fold; capped so a tall one doesn't stretch the painting.
    private func heroHeight(for geometry: GeometryProxy) -> CGFloat {
        min(470, max(300, (geometry.size.height + geometry.safeAreaInsets.top) * 0.49))
    }

    // MARK: - Hero

    /// The painting, full-bleed from the top of the screen, settling into
    /// the page through one gradient — the prayer screen's own language,
    /// not the home card's arch.
    private func hero(height: CGFloat) -> some View {
        Color.clear
            .frame(height: height)
            .overlay(
                CachedAssetImage(viewModel.artworkName)
                    .aspectRatio(contentMode: .fill),
                alignment: viewModel.artworkAlignment
            )
            .clipped()
            // Clear through the top half, gathering under the title and
            // landing exactly on the page color at the foot, so the
            // painting ends without an edge.
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: AppColors.background.opacity(0.35), location: 0.5),
                        .init(color: AppColors.background.opacity(0.85), location: 0.8),
                        .init(color: AppColors.background, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            )
            .overlay(alignment: .bottom) { heroContent }
    }

    private var heroContent: some View {
        VStack(spacing: 11) {
            if !viewModel.labels.isEmpty {
                Text(MeditationLabel.displayLine(viewModel.labels))
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)
                    .multilineTextAlignment(.center)
            }

            Text(viewModel.name)
                .font(AppFonts.headlineFont(24))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .minimumScaleFactor(0.8)

            if let context = viewModel.contextLine {
                Text(context)
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.accentSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }

    // MARK: - About

    /// The set's own words for itself, in a section of its own: spaced
    /// like a card and ruled like one, but with no fill — a plain outline
    /// on the page, so it reads as a place rather than a slab.
    private func aboutCard(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeading("About these meditations")

            ReadingText(text: description, size: 17)
        }
        .sacredCard(filled: false)
    }

    // MARK: - The Opening

    /// The first meditation, whole, under a heading that says what it is.
    ///
    /// It used to be a clamped excerpt with a drop cap under an ornament,
    /// a kicker and a mystery name — three headings for four fading
    /// lines, which read as the meditation itself cut off mid-thought
    /// rather than as a sample of the set. Now the heading names it a
    /// preview and the meditation runs its full length, so the page
    /// scrolls you through one of the five before you commit to all of
    /// them.
    @ViewBuilder
    private var opening: some View {
        if let previewText = viewModel.previewText {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PREVIEW")
                        .font(AppFonts.labelFont(9))
                        .tracking(3)
                        .foregroundColor(AppColors.gold)

                    Text("The first meditation · \(viewModel.previewSubject)")
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ReadingText(text: previewText, size: 17)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if viewModel.loadFailed {
            VStack(spacing: 10) {
                Text("Couldn't load these meditations. The server may still be waking up.")
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

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
            .padding(.top, 8)
        } else if viewModel.fullSet != nil {
            // Loaded, but nothing to open: no meditations, or an empty first
            // one. Say so — and the button below stays quiet.
            Text("These meditations aren't available yet.")
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        } else {
            ProgressView()
                .tint(AppColors.gold)
                .padding(.top, 12)
        }
    }

    // MARK: - Pray

    private var prayButton: some View {
        GoldCTAButton(title: "Pray with these meditations") {
            pray()
        }
        .disabled(!viewModel.hasMeditations)
        .padding(.horizontal, 20)
        .padding(.top, 44)
        .padding(.bottom, 12)
        .background(
            // Opaque under the button and through the home-indicator band,
            // so scrolled text never shows beneath the act.
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: AppColors.background.opacity(0.9), location: 0.4),
                    .init(color: AppColors.backgroundDeep, location: 0.72),
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
}

// MARK: - Previews

#Preview("Loaded set") {
    let summary = MeditationSetSummary(
        id: 27,
        name: "Blessed Fulton J. Sheen",
        category: "sorrowful",
        description: "Meditations on the Sorrowful Mysteries from Bishop Fulton J. Sheen",
        labels: ["Considerations"]
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
