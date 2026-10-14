//
//  ChantRows.swift
//  Lumen Viae
//
//  A chant as a row of the library, what a tap on one does, and the
//  menu a hold on one opens.
//

import SwiftUI

// MARK: - ChantTap

/// What a tap on a chant does wherever one is listed: the row, the card
/// or the name opens the chant's page, and only the small round play
/// disc beside it plays it where it stands. A set's own disc plays the
/// whole set; a chant listed on a set opens that chant. A search hit on
/// a line opens the chant and does not start it. The library's pages,
/// Explore, the Chapel's tile, the mini player and a prayer's "Hear it
/// sung" all keep to this; the home page once let a hit in the words
/// begin singing, and listed a set's chants with no door at all.
enum ChantTap {
    /// Where a tap on a listed chant goes
    static func route(to chant: Chant) -> AppRoute {
        .chant(id: chant.id)
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
                label: chant.spokenNameAndSetting
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
            .accessibilityLabel("\(chant.latinTitle), \(subtitle), \(chant.spokenLength)")
            .accessibilityHint("Opens the chant with its sheet music")
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
        if let setting = chant.settingMidLine {
            return "\(chant.englishTitle) · \(setting)"
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

// MARK: - Spoken rows

extension Chant {
    /// How long its recording plays, said in words and rounded as its
    /// label is, so VoiceOver says 1 minute 37 seconds beside "1:37"
    var spokenLength: String {
        ChantPlayer.spoken(duration.rounded())
    }

    /// A chant in a set as VoiceOver says it: "Ave Maria, 10 times, Hail
    /// Mary, 3 minutes 20 seconds"
    func spokenEntry(times: Int, duration: TimeInterval) -> String {
        let name = times > 1 ? "\(latinTitle), \(times) times" : latinTitle
        // Rounded as the lengths beside it are shown
        return "\(name), \(englishTitle), \(ChantPlayer.spoken(duration.rounded()))"
    }
}
