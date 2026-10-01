//
//  ChantComponents.swift
//  Lumen Viae
//
//  The pieces every chant surface shares: the score drawn on the dark
//  page, the play disc, the scrubber, and the credit the recordings carry.
//
//  The scores are Verbum Gloriae's engravings, redrawn by the app from
//  the operations Tools/Chants recorded — the notes in the page's cream
//  and the initials in the missal's rubric red, as the text of every
//  prayer is. Printed black on white they would be the one bright slab
//  on a dark app.
//

import SwiftUI

// MARK: - ChantScoreImage

/// One engraved part of a score, drawn on the page: the ink in cream, the
/// initials in rubric red, vector at any width (`ChantScoreDrawing`).
struct ChantScoreImage: View {
    let part: ChantScorePart

    @State private var drawing: ChantScoreDrawing?

    init(part: ChantScorePart) {
        self.part = part
        // A score already read is drawn at once, never faded in again
        _drawing = State(initialValue: ChantScoreStore.shared.cached(part.file))
    }

    var body: some View {
        Canvas { context, size in
            guard let drawing else { return }
            let scale = size.width / drawing.bounds.width
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -drawing.bounds.minX, y: -drawing.bounds.minY)

            let ink = AppColors.cream.opacity(0.94)
            let red = Rubric.red
            for operation in drawing.operations {
                switch operation {
                case .fill(let path, let which):
                    context.fill(Path(path), with: .color(which == .ink ? ink : red))
                case .erase(let path):
                    // A white shape in the engraving: it clears what lies
                    // under it, so the page shows through
                    context.blendMode = .destinationOut
                    context.fill(Path(path), with: .color(.black))
                    context.blendMode = .normal
                case .stroke(let path, let which, let width):
                    context.stroke(Path(path), with: .color(which == .ink ? ink : red), lineWidth: width)
                }
            }
        }
        .aspectRatio(part.aspectRatio, contentMode: .fit)
        .opacity(drawing == nil ? 0 : 1)
        .animation(Motion.crossfade, value: drawing == nil)
        .task(id: part.file) {
            if drawing == nil {
                drawing = await ChantScoreStore.shared.load(part.file)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Score: \(part.caption)")
        .accessibilityAddTraits(.isImage)
    }
}

// MARK: - ChantScoreView

/// A place on a score that survives its being laid out at another width:
/// a part, and a point on that part's engraving as a fraction of it. The
/// captions between the parts keep their height at any zoom, so a point
/// on the whole score does not scale with it; a point on one engraving
/// does.
struct ChantScoreMark: Equatable {
    let part: Int
    let unit: UnitPoint
}

/// Every part of a chant's score in order, each named when there is
/// more than one (the hymn, then its versicle, then its collect).
struct ChantScoreView: View {
    let parts: [ChantScorePart]
    var spacing: CGFloat = 26

    /// For the enlarged score: where each part's engraving stands, in the
    /// score's own coordinates (`space`); a mark to scroll to; and word
    /// that the mark stands where the score is now laid out
    var onPartFrame: ((Int, CGRect) -> Void)?
    var mark: ChantScoreMark?
    var onMarkPlaced: (() -> Void)?

    static let space = "ChantScoreView.space"
    static let markID = "ChantScoreView.mark"

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                VStack(alignment: .leading, spacing: 10) {
                    if parts.count > 1 {
                        Text(part.caption.uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(2)
                            .foregroundColor(AppColors.gold.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ChantScoreImage(part: part)
                        .overlay {
                            if let mark, mark.part == index {
                                GeometryReader { geometry in
                                    Color.clear
                                        .frame(width: 1, height: 1)
                                        .id(Self.markID)
                                        .onGeometryChange(for: CGRect.self) { geometry in
                                            geometry.frame(in: .named(Self.space))
                                        } action: { _ in
                                            onMarkPlaced?()
                                        }
                                        .position(
                                            x: mark.unit.x * geometry.size.width,
                                            y: mark.unit.y * geometry.size.height
                                        )
                                }
                                .accessibilityHidden(true)
                            }
                        }
                        .onGeometryChange(for: CGRect.self) { geometry in
                            geometry.frame(in: .named(Self.space))
                        } action: { frame in
                            onPartFrame?(index, frame)
                        }
                }
            }
        }
        .coordinateSpace(.named(Self.space))
    }
}

// MARK: - ChantPlayDisc

/// The round play control: a dark disc lit through a gold rim, the one
/// shape the app gives to a play control that is not a page's act.
struct ChantPlayDisc: View {
    let isPlaying: Bool
    let isLoading: Bool
    var size: CGFloat = 46
    var label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                Circle()
                    .strokeBorder(AppColors.goldLight, lineWidth: 1)

                // Play, pause and the spinner crossfade over one another
                // rather than swapping under the thumb: three branches
                // sharing one slot, as the tile's own disc drew them
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(AppColors.goldLight)
                            .scaleEffect(0.8)
                            .transition(.opacity)
                    } else if isPlaying {
                        AppIcon("ph-pause-fill", size: size * 0.32)
                            .foregroundColor(AppColors.goldLight)
                            .transition(.opacity)
                    } else {
                        AppIcon("ph-play-fill", size: size * 0.32)
                            .foregroundColor(AppColors.goldLight)
                            .transition(.opacity)
                    }
                }
                .animation(Motion.crossfade, value: isLoading)
                .animation(Motion.crossfade, value: isPlaying)
            }
            .frame(width: size, height: size)
            .shadow(color: AppColors.gold.opacity(0.3), radius: size * 0.2)
            // Drawn at its size, answering to 44 whatever that is
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(
            isLoading ? "Loading \(label)"
                : isPlaying ? "Pause \(label)" : "Play \(label)"
        )
    }
}

// MARK: - ChantScrubber

/// A gold hairline the finger can drag along — the consecration
/// transport's scrubber, at the weight of a rule. VoiceOver hears where it
/// stands as time, "1 minute 5 seconds of 3 minutes 20 seconds", and
/// moves it ten seconds at a swipe.
struct ChantScrubber: View {
    let progress: Double
    /// The recording's length, in seconds
    let duration: Double
    let isEnabled: Bool
    let onSeek: (Double) -> Void

    /// How far a swipe up or down moves the chant
    private static let step: Double = 10

    @State private var dragging: Double?

    private var shown: Double { dragging ?? progress }

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.cream.opacity(0.14))
                    .frame(height: 3)
                Capsule()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: max(width * shown, 3), height: 3)
                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: 11, height: 11)
                    .offset(x: (width - 11) * shown)
                    .opacity(isEnabled ? 1 : 0.4)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else { return }
                        dragging = min(max(value.location.x / width, 0), 1)
                    }
                    .onEnded { _ in
                        if let dragging { onSeek(dragging) }
                        dragging = nil
                    }
            )
        }
        .frame(height: 24)
        .accessibilityElement()
        .accessibilityLabel("Position in the chant")
        .accessibilityValue("\(ChantPlayer.spoken(shown * duration)) of \(ChantPlayer.spoken(duration))")
        .accessibilityAdjustableAction { direction in
            guard isEnabled, duration > 0 else { return }
            let step = Self.step / duration
            switch direction {
            case .increment: onSeek(min(1, progress + step))
            case .decrement: onSeek(max(0, progress - step))
            @unknown default: break
            }
        }
    }
}

// MARK: - ChantCredit

/// Who sang it, on what terms. The licence asks no attribution; the app
/// gives it, and says the adapted files are shared on the same terms,
/// which the licence does ask.
struct ChantCredit: View {
    var compact = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: compact ? .leading : .center, spacing: 8) {
            Text(ChantCatalog.credit)
                .font(AppFonts.readingItalicFont(compact ? 12.5 : 14))
                .foregroundColor(AppColors.cream.opacity(0.75))
                .multilineTextAlignment(compact ? .leading : .center)

            if !compact {
                Text(ChantCatalog.licenceNote)
                    .font(AppFonts.readingItalicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // One above the other under the accessibility sizes, where
                // side by side broke the site's name mid-word
                let links = dynamicTypeSize >= .accessibility1
                    ? AnyLayout(VStackLayout(spacing: 0))
                    : AnyLayout(HStackLayout(spacing: 18))
                links {
                    creditLink("VERBUMGLORIAE.ES", to: ChantCatalog.sourceSite)
                        .accessibilityLabel("Verbum Gloriae's website")
                    creditLink("THE LICENCE", to: ChantCatalog.licenceURL)
                        .accessibilityLabel("The licence")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)
    }

    private func creditLink(_ title: String, to url: URL) -> some View {
        Link(destination: url) {
            Text(title)
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(minHeight: 44)
        }
    }
}

// MARK: - ChantLibraryRow

/// A chant on its shelf: its disc to play it where it stands, then its
/// names, its length, and a caret to its page. Explore's Sung Prayer
/// sets the same row.
struct ChantLibraryRow: View {
    let chant: Chant
    let player: ChantPlayer
    /// The line under the names, when the board says something of its
    /// own there ("for Easter", "Corpus Christi")
    var note: String? = nil
    let open: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var sounding: Bool { player.isPlaying(chant) }

    /// Under the accessibility sizes the length leaves its column for a
    /// line under the names, which it squeezed until "Redemptoris" broke
    /// mid-word
    private var lengthBelow: Bool { dynamicTypeSize >= .accessibility1 }

    var body: some View {
        HStack(spacing: 12) {
            ChantPlayDisc(
                isPlaying: sounding,
                isLoading: player.current.id == chant.id && player.isLoading,
                size: 34,
                label: chant.latinTitle
            ) {
                player.toggle(chant)
            }

            Button(action: open) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(chant.latinTitle)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(sounding ? AppColors.goldLight : AppColors.cream.opacity(0.94))
                            .fixedSize(horizontal: false, vertical: true)
                            .animation(Motion.crossfade, value: sounding)

                        Text(subtitle)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if lengthBelow { length }
                    }

                    Spacer(minLength: 8)

                    if !lengthBelow { length }

                    AppIcon("ph-caret-right", size: 10)
                        .foregroundColor(AppColors.gold.opacity(0.45))
                }
                .padding(.vertical, 10)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(chant.latinTitle), \(subtitle), \(ChantPlayer.spoken(chant.duration))")
            .accessibilityHint("Opens the chant with its score")
            .accessibilityAddTraits(.isButton)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(height: AppLine.hairline)
        }
        .chantContextMenu(chant)
    }

    private var length: some View {
        Text(chant.durationLabel)
            .font(AppFonts.labelFont(9))
            .tracking(1)
            .foregroundColor(AppColors.textSecondary)
            .monospacedDigit()
            .lineLimit(1)
    }

    private var subtitle: String {
        if let note { return note }
        if let setting = chant.distinctSetting {
            return "\(chant.englishTitle) · \(setting.lowercased())"
        }
        return chant.englishTitle
    }
}

// MARK: - Context menu

extension View {
    /// A chant held down: keep it as a favourite, put it in a set, or stop
    /// learning it
    func chantContextMenu(_ chant: Chant) -> some View {
        modifier(ChantContextMenu(chant: chant))
    }
}

private struct ChantContextMenu: ViewModifier {
    let chant: Chant

    private var shelf = ChantShelfStore.shared

    init(chant: Chant) {
        self.chant = chant
    }

    func body(content: Content) -> some View {
        content.contextMenu {
            Button {
                shelf.toggleFavorite(chant.id)
            } label: {
                if shelf.isFavorite(chant.id) {
                    Label("Remove from Favourites", systemImage: "heart.slash")
                } else {
                    Label("Add to Favourites", systemImage: "heart")
                }
            }

            if !shelf.sets.isEmpty {
                Menu {
                    ForEach(shelf.sets) { set in
                        Button(set.name) {
                            shelf.addChant(chant.id, to: set.id)
                        }
                    }
                } label: {
                    Label("Add to a Set", systemImage: "text.badge.plus")
                }
            }

            // A chant under way can be put down quietly, and nothing then
            // says it was ever begun
            if shelf.step(of: chant.id) != nil {
                Button {
                    shelf.stopLearning(chant.id)
                } label: {
                    Label("Stop Learning", systemImage: "xmark.circle")
                }
            }
        }
    }
}

// MARK: - ChantSectionHeading

/// A section of a library board: a small gold kicker over its title in
/// the display face, and a line of what it is. Left-aligned, as every
/// section beneath the masthead stands.
struct ChantSectionHeading: View {
    let kicker: String?
    let title: String
    var note: String? = nil
    var titleSize: CGFloat = 21

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let kicker {
                Text(kicker.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
            }
            Text(title)
                .font(AppFonts.titleFont(titleSize))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let note {
                Text(note)
                    .font(AppFonts.readingItalicFont(14.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ChantRule

/// The hairline under a section's heading, and between rows
struct ChantRule: View {
    var opacity: Double = 0.3

    var body: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(opacity))
            .frame(height: AppLine.hairline)
            .accessibilityHidden(true)
    }
}

// MARK: - ChantSettingPill

/// A work sung in more than one setting — the simple and the solemn Salve
/// Regina — as a pill of its settings, each with its length. A segmented
/// picker to VoiceOver.
struct ChantSettingPill: View {
    let settings: [Chant]
    let selected: String
    let choose: (Chant) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(settings) { chant in
                let lit = chant.id == selected
                Button {
                    choose(chant)
                } label: {
                    HStack(spacing: 6) {
                        Text(chant.settingName ?? chant.latinTitle)
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                            .lineLimit(1)
                        Text(chant.durationLabel)
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1)
                            .foregroundColor(AppColors.textSecondary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    // 38 inside a 3pt rim: the pill stands 44 tall, a
                    // finger's reach, as drawn
                    .frame(height: 38)
                    .background(Capsule().fill(lit ? AppColors.gold.opacity(0.16) : Color.clear))
                    .contentShape(Capsule())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("\(chant.settingName ?? chant.latinTitle), \(ChantPlayer.spoken(chant.duration))")
                .accessibilityAddTraits(lit ? [.isSelected] : [])
            }
        }
        .padding(3)
        .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
        .animation(Motion.choice, value: selected)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Setting")
    }
}

// MARK: - ChantPainting

/// A painting hung at the head of a card or a board, dissolving to clear
/// at its foot so the words beneath stand on the page, never on a slab.
struct ChantPainting: View {
    let name: String
    var height: CGFloat = 220
    /// How far down the painting the dissolve begins
    var dissolveFrom: CGFloat = 0.45

    var body: some View {
        CachedAssetImage(name, focal: .center)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: dissolveFrom),
                        .init(color: .black.opacity(0.35), location: (dissolveFrom + 1) / 2),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityHidden(true)
    }
}

// MARK: - ChantThumbnail

/// A painting as a small square, for a row or the mini player
struct ChantThumbnail: View {
    let name: String
    var size: CGFloat = 40
    var radius: CGFloat = 10
    /// Where the painting is cut; the curation's point for it
    /// (`ChantLibraryData.focalPoints`), else its middle
    var focal: UnitPoint? = nil

    var body: some View {
        CachedAssetImage(name, focal: focal ?? Self.focalPoint(for: name))
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
            )
            .accessibilityHidden(true)
    }

    static func focalPoint(for name: String) -> UnitPoint {
        guard let point = ChantLibraryData.focalPoints[name] else { return .center }
        return UnitPoint(x: point.x, y: point.y)
    }
}

// MARK: - ChantStepBeads

/// The four steps of learning a chant as four beads on a thread: those
/// taken in gold, the one under way ringed, the rest at rest.
struct ChantStepBeads: View {
    let step: ChantLearningStep?
    var learned = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ChantLearningStep.allCases) { each in
                let taken = learned || (step.map { each.rawValue < $0.rawValue } ?? false)
                let here = !learned && step == each
                ZStack {
                    Circle()
                        .fill(taken ? AppColors.gold : Color.clear)
                    Circle()
                        .strokeBorder(here ? AppColors.goldLight : AppColors.gold.opacity(taken ? 0 : 0.35),
                                      lineWidth: here ? 1.5 : 1)
                }
                .frame(width: here ? 13 : 9, height: here ? 13 : 9)
                .shadow(color: here ? AppColors.gold.opacity(0.4) : .clear, radius: 4)

                if each != .onYourOwn {
                    Rectangle()
                        .fill(AppColors.gold.opacity(taken ? 0.6 : 0.2))
                        .frame(width: 14, height: 1)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(learned ? "Learned" : step.map { "Step \($0.rawValue) of 4, \($0.title)" } ?? "Not begun")
    }
}

// MARK: - ChantFlowLayout

/// Lays its subviews out in rows, wrapping to the width it is given: the
/// Types board's chants under a minute, the search filters.
nonisolated struct ChantFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let arrangement = arrange(subviews, in: proposal.width ?? .infinity)
        if let width = proposal.width, width.isFinite {
            return CGSize(width: width, height: arrangement.size.height)
        }
        return arrangement.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews, in: proposal.width ?? bounds.width)
        for (subview, origin) in zip(subviews, arrangement.origins) {
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(_ subviews: Subviews, in width: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

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

    private var player = ChantPlayer.shared

    init(open: @escaping () -> Void) {
        self.open = open
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
                label: player.waitingForNext ? chant.latinTitle : title
            ) {
                player.togglePlayback()
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
        )
        .overlay(alignment: .bottomLeading) {
            GeometryReader { geo in
                Rectangle()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: geo.size.width * player.progress, height: 1.5)
                    .animation(.linear(duration: 0.5), value: player.progress)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
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
        if let silence = player.silence {
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
            Text(chant.settingName.map { "\($0) · \(time)" } ?? time)
                .accessibilityLabel([chant.settingName, player.spokenTimeLabel].compactMap { $0 }.joined(separator: ", "))
        } else {
            Text(chant.englishTitle)
        }
    }
}

// MARK: - Spoken rows

extension Chant {
    /// A chant in a set as VoiceOver says it: "Ave Maria, 10 times, Hail
    /// Mary, 3 minutes 20 seconds"
    func spokenEntry(times: Int, duration: TimeInterval) -> String {
        let name = times > 1 ? "\(latinTitle), \(times) times" : latinTitle
        return "\(name), \(englishTitle), \(ChantPlayer.spoken(duration))"
    }
}

// MARK: - ChantSetPlayButton

/// A set's one gold act: Play all until the set is under way, then the
/// set's own pause and resume. It once began the set again from its
/// first chant at every tap.
struct ChantSetPlayButton: View {
    let queue: ChantQueue
    let title: String

    private var player = ChantPlayer.shared

    init(queue: ChantQueue, title: String) {
        self.queue = queue
        self.title = title
    }

    var body: some View {
        let singing = player.isSinging(queue)
        // A chant on its way counts as going on, unless a pause was asked
        // for while it arrived
        let going = singing && player.isGoingOn
        let word = !singing ? title
            : player.waitingForNext ? "Go on"
            : going ? "Pause" : "Resume"
        GoldCTAButton(title: word, glyph: going ? .none : .play) {
            if singing {
                player.pauseOrResume()
            } else {
                player.play(queue)
            }
        }
    }
}

// MARK: - ChantRubricText

/// A note in red between chants, as a printed order of service sets what
/// happens between its texts
struct ChantRubricText: View {
    let text: String
    var size: CGFloat = 14.5

    var body: some View {
        Text(text)
            .font(AppFonts.readingItalicFont(size))
            .foregroundColor(Rubric.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Long dates

enum ChantDates {

    private static let ordinals = [
        "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth",
        "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth",
        "eighteenth", "nineteenth", "twentieth", "twenty-first", "twenty-second", "twenty-third",
        "twenty-fourth", "twenty-fifth", "twenty-sixth", "twenty-seventh", "twenty-eighth",
        "twenty-ninth", "thirtieth", "thirty-first"
    ]

    /// "Thursday, the first of October"
    static func spelled(_ date: Date, calendar: Calendar = .current) -> String {
        let weekday = calendar.component(.weekday, from: date)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let weekdays = calendar.standaloneWeekdaySymbols
        let months = calendar.standaloneMonthSymbols
        guard weekdays.indices.contains(weekday - 1),
              months.indices.contains(month - 1),
              ordinals.indices.contains(day - 1) else {
            return date.formatted(date: .complete, time: .omitted)
        }
        return "\(weekdays[weekday - 1]), the \(ordinals[day - 1]) of \(months[month - 1])"
    }

    /// "Wednesday, October 7"
    static func feastDay(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    /// "7" and "OCT"
    static func dayAndMonth(_ date: Date) -> (day: String, month: String) {
        (date.formatted(.dateTime.day()), date.formatted(.dateTime.month(.abbreviated)).uppercased())
    }
}

// MARK: - ChantGoldPlayButton

/// The board's one gold act when it is a chant to sing: a gold disc with
/// the play or pause glyph dark upon it, haloed. Tonight's antiphon, the
/// chant's own page.
struct ChantGoldPlayButton: View {
    let isPlaying: Bool
    let isLoading: Bool
    var size: CGFloat = 56
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.goldGradient)
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(AppColors.background)
                            .transition(.opacity)
                    } else if isPlaying {
                        AppIcon("ph-pause-fill", size: size * 0.34)
                            .transition(.opacity)
                    } else {
                        AppIcon("ph-play-fill", size: size * 0.34)
                            .offset(x: size * 0.03)
                            .transition(.opacity)
                    }
                }
                .foregroundColor(AppColors.background)
                .animation(Motion.crossfade, value: isLoading)
                .animation(Motion.crossfade, value: isPlaying)
            }
            .frame(width: size, height: size)
            .shadow(color: AppColors.gold.opacity(0.28), radius: 10)
            .shadow(color: AppColors.gold.opacity(0.14), radius: 22)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(isLoading ? "Loading \(label)" : isPlaying ? "Pause \(label)" : "Play \(label)")
    }
}

// MARK: - ChantShell

extension View {
    /// The library's outline: a 16pt hairline at gold@0.24 on the bare
    /// page, no fill
    func chantShell(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
            )
    }
}
