//
//  PrayerTrackMenu.swift
//  Lumen Viae
//
//  The overflow menu carried by both prayer surfaces — the ⋯ in the
//  player's bottom bar, and the ⋯ on the reader's mini player.
//
//  One definition, two placements: what you can do with a meditation
//  shouldn't depend on which surface you happen to be looking at, and
//  the two lists differ only where the surfaces do (the reader can be
//  expanded; the player is already expanded).
//
//  Presented as a tray of the app's own making rather than a system
//  menu. A `Menu` renders in the platform's grey vocabulary — system
//  font, system chrome, system separators — which lands on a gold-and-
//  candlelight prayer screen as a piece of another app.
//

import SwiftUI

// MARK: - Actions

/// Everything the tray needs about the meditation on screen, assembled
/// once by the prayer view.
struct PrayerTrackActions {

    let meditationId: Int

    /// The presigned narration URL, when there is narration. Presigned
    /// links last about a day, so the tray saves the one already in hand
    /// rather than resolving a fresh one.
    let audioURL: String?

    /// What Share hands off.
    let shareText: String

    /// Prefills the subject line so support knows which meditation the
    /// note is about without asking.
    let feedbackSubject: String

    let onAddReflection: () -> Void
    let onEndSession: () -> Void

    /// A mailto for the feedback row. Nil only if the subject cannot be
    /// escaped, which no real title does.
    var feedbackURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Constants.supportEmail
        components.queryItems = [URLQueryItem(name: "subject", value: feedbackSubject)]
        return components.url
    }
}

// MARK: - Placement

enum PrayerTrackPlacement {
    /// The player's ⋯, in the bottom bar
    case player
    /// The reader's ⋯, on the mini player
    case reader(onExpand: () -> Void)
}

/// Height for the tray's detent, so it never opens with a field of empty
/// card under the last row. Counts the same list the tray draws — a row
/// added or hidden in one place would otherwise clip silently in the
/// other.
func prayerTrayHeight(for placement: PrayerTrackPlacement, actions: PrayerTrackActions) -> CGFloat {
    CGFloat(PrayerTrackTray.rows(for: placement, actions: actions).count)
        * PrayerTrackTray.rowHeight + PrayerTrackTray.topPadding + PrayerTrackTray.bottomPadding
}

// MARK: - Tray

struct PrayerTrackTray: View {

    let actions: PrayerTrackActions
    let placement: PrayerTrackPlacement

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    /// The act to run once this tray has finished leaving, handed to the
    /// host that owns the sheet.
    @Binding var pendingHandoff: (() -> Void)?

    static let rowHeight: CGFloat = 56

    /// Room above the first row, for the drag indicator.
    static let topPadding: CGFloat = 26

    /// Slack under the last row, so it clears the home indicator.
    static let bottomPadding: CGFloat = 20

    /// The acts this tray offers, in order. The single source for both
    /// what is drawn and how tall the sheet opens.
    static func rows(
        for placement: PrayerTrackPlacement,
        actions: PrayerTrackActions
    ) -> [Row] {
        switch placement {
        case .player:
            // A meditation with no narration should not offer to
            // download silence
            return actions.audioURL == nil
                ? [.reflection, .feedback, .share]
                : [.reflection, .download, .feedback, .share]
        case .reader:
            return [.share, .expand, .end]
        }
    }

    enum Row {
        case reflection, download, feedback, share, expand, end
    }

    private var offline: OfflineContentService { .shared }

    private var isDownloading: Bool {
        offline.downloadingAudioIds.contains(actions.meditationId)
    }

    /// Read from the service rather than kept alongside it, so wiping the
    /// library from Account settles this row too.
    private var isSaved: Bool {
        offline.hasLocalAudio(meditationId: actions.meditationId)
    }

    var body: some View {
        let rows = Self.rows(for: placement, actions: actions)

        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                view(for: row, showsDivider: index < rows.count - 1)
            }
        }
        .padding(.top, Self.topPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.cardBackground.ignoresSafeArea())
    }

    // MARK: - Rows

    @ViewBuilder
    private func view(for row: Row, showsDivider: Bool) -> some View {
        switch row {
        case .reflection:
            TrayRow(icon: "ph-note-pencil", title: "Add a reflection", showsDivider: showsDivider) {
                handoff(actions.onAddReflection)
            }

        case .download:
            downloadRow(showsDivider: showsDivider)

        case .feedback:
            TrayRow(icon: "ph-chat-teardrop-text", title: "Give feedback", showsDivider: showsDivider) {
                guard let url = actions.feedbackURL else { return }
                dismiss()
                openURL(url)
            }

        case .share:
            // The one row that is a ShareLink rather than a button, so
            // the system share sheet gets its own presentation over the
            // tray.
            ShareLink(item: actions.shareText) {
                TrayRowLabel(icon: "ph-export", title: "Share", showsDivider: showsDivider)
            }
            .buttonStyle(.plain)

        case .expand:
            if case .reader(let onExpand) = placement {
                TrayRow(icon: "ph-caret-up", title: "Expand player", showsDivider: showsDivider) {
                    handoff(onExpand)
                }
            }

        case .end:
            TrayRow(icon: "ph-x", title: "End prayer", showsDivider: showsDivider) {
                handoff(actions.onEndSession)
            }
        }
    }

    /// Save the narration for a Rosary prayed without a signal.
    @ViewBuilder
    private func downloadRow(showsDivider: Bool) -> some View {
        if isSaved {
            TrayRow(icon: "ph-trash", title: "Remove download", showsDivider: showsDivider) {
                offline.removeAudio(meditationId: actions.meditationId)
                dismiss()
            }
        } else if let audioURL = actions.audioURL {
            TrayRow(
                icon: "ph-download-simple",
                title: isDownloading ? "Downloading…" : "Download audio",
                showsDivider: showsDivider,
                isEnabled: !isDownloading
            ) {
                Task {
                    await offline.downloadAudio(
                        meditationId: actions.meditationId,
                        from: audioURL
                    )
                }
            }
        }
    }

    /// Hands an act that puts something else on screen — another sheet,
    /// or the whole screen going away — to the host, which runs it from
    /// the sheet's `onDismiss`. Presenting into a dismissal drops the new
    /// presentation, and waiting out a guessed animation duration missed
    /// it whenever the real one differed: a taller detent, or Reduce
    /// Motion cutting it short.
    private func handoff(_ action: @escaping () -> Void) {
        pendingHandoff = action
        dismiss()
    }
}

// MARK: - Tray Row

/// One act in the tray: a gold glyph, the name of the act, and a
/// hairline under it in the same gold the rest of the app rules with.
private struct TrayRow: View {

    let icon: String
    let title: String
    var showsDivider: Bool = true
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TrayRowLabel(icon: icon, title: title, showsDivider: showsDivider)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

private struct TrayRowLabel: View {

    let icon: String
    let title: String

    /// The last row in a tray carries no rule — a hairline hanging under
    /// the final act reads as a row that failed to load
    var showsDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                AppIcon(icon, size: 20)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 24)

                Text(title)
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: PrayerTrackTray.rowHeight)
            .contentShape(Rectangle())

            if showsDivider {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.10))
                    .frame(height: 0.5)
                    .padding(.leading, 64)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        PrayerTrackTray(
            actions: PrayerTrackActions(
                meditationId: 1,
                audioURL: "https://example.com/a.mp3",
                shareText: "",
                feedbackSubject: "",
                onAddReflection: {},
                onEndSession: {}
            ),
            placement: .player,
            pendingHandoff: .constant(nil)
        )
        .presentationDetents([.height(270)])
        .presentationBackground(AppColors.cardBackground)
    }
}
