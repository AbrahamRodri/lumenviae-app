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
    /// links last about a day, so the tray saves the one the player is
    /// holding — refreshed already if the set's own had expired — rather
    /// than resolving another.
    let audioURL: String?

    /// The voice `audioURL` is in, so a download is saved under the
    /// voice it really is rather than the one the person asked for
    /// (which a meditation may not have been recorded in).
    let voice: String

    /// What Share hands off.
    let shareText: String

    /// Names the meditation on screen inside the feedback form, so a
    /// note about it never has to describe which one it was.
    let feedbackContext: FeedbackContext

    let onAddReflection: () -> Void
    let onGiveFeedback: () -> Void
    let onEndSession: () -> Void
}

// MARK: - Placement

enum PrayerTrackPlacement {
    /// The player's ⋯, in the bottom bar
    case player
    /// The reader's ⋯, on the mini player
    case reader(onExpand: () -> Void)
}

// MARK: - Tray

/// The tray opens as tall as it measures (`fittedSheetDetent`), so it
/// never stands on a field of empty ground under its last row, and never
/// cuts one off — its hosts set no detent of their own.
struct PrayerTrackTray: View {

    let actions: PrayerTrackActions
    let placement: PrayerTrackPlacement

    @Environment(\.dismiss) private var dismiss

    /// The act to run once this tray has finished leaving, handed to the
    /// host that owns the sheet.
    @Binding var pendingHandoff: (() -> Void)?

    static let rowHeight: CGFloat = SheetMetrics.rowMinHeight

    /// Slack under the last row, so it clears the home indicator.
    static let bottomPadding: CGFloat = 20

    /// A first guess at the tray's height, for the frame before it has
    /// been measured: a header, the rows, and the slack under them
    private static func estimatedHeight(rows: Int) -> CGFloat {
        100 + CGFloat(rows) * rowHeight + bottomPadding
    }

    /// The acts this tray offers, in order.
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
        offline.isDownloadingAudio(meditationId: actions.meditationId, voice: actions.voice)
    }

    /// Read from the service rather than kept alongside it, so wiping the
    /// library from Account settles this row too.
    private var isSaved: Bool {
        offline.hasLocalAudio(meditationId: actions.meditationId, voice: actions.voice)
    }

    var body: some View {
        let rows = Self.rows(for: placement, actions: actions)

        VStack(spacing: 0) {
            // The set over the meditation the acts are about, free to wrap.
            // The sheet measures what it holds, so a meditation's longer
            // name ("The Descent of the Holy Spirit upon the Apostles") is
            // set in full; it was once shrunk and cut to fit a header of
            // counted height.
            SheetHeader(
                kicker: actions.feedbackContext.setName,
                title: actions.feedbackContext.meditationTitle
            )

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                view(for: row, showsDivider: index < rows.count - 1)
            }
        }
        .padding(.bottom, Self.bottomPadding)
        .fittedSheetDetent(estimate: Self.estimatedHeight(rows: rows.count))
        .sheetGround()
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
            // Handed off like the reflection editor: the form is another
            // sheet, and presenting into this one's dismissal drops it.
            TrayRow(icon: "ph-chat-teardrop-text", title: "Give feedback", showsDivider: showsDivider) {
                handoff(actions.onGiveFeedback)
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
                offline.removeAudio(meditationId: actions.meditationId, voice: actions.voice)
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
                        voice: actions.voice,
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

/// One act in the tray, as a sheet's ruled row.
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
        .buttonStyle(SacredCardButtonStyle())
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
        // Acts, not doors: nothing stands at the trailing edge
        SheetRow(title, icon: icon, accessory: .none, showsDivider: showsDivider)
            .frame(height: PrayerTrackTray.rowHeight)
    }
}

// MARK: - Preview

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        PrayerTrackTray(
            actions: PrayerTrackActions(
                meditationId: 1,
                audioURL: "https://example.com/a.mp3",
                voice: "female",
                shareText: "",
                feedbackContext: FeedbackContext(
                    meditationTitle: "The Descent of the Holy Spirit upon the Apostles",
                    setName: "Meditations of St. Alphonsus"
                ),
                onAddReflection: {},
                onGiveFeedback: {},
                onEndSession: {}
            ),
            placement: .player,
            pendingHandoff: .constant(nil)
        )
    }
}
