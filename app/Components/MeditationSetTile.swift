//
//  MeditationSetTile.swift
//  Lumen Viae
//
//  The two readings of a meditation set on the picker's shelf.
//
//  MeditationSetTile is the gallery reading: a half-width tile carrying
//  the set's name, its labels, and a pin — and, for a set that has one,
//  its own painting as the tile's ground, the way the home grid's cards
//  carry theirs. No glyph, and no stand-in art: a set without a painting
//  is read by title on a plain card, rather than under the category's
//  painting repeated down the shelf. MeditationSetRow is the same set with
//  the tile taken away: type only, ruled off from its neighbour, with a
//  small plate of the painting at its leading edge when there is one.
//  The picker's toggle picks between them.
//

import SwiftUI

// MARK: - Tile

struct MeditationSetTile: View {

    let title: String

    /// Descriptive labels, shown as one tracked line under the title
    var labels: [String] = []

    /// The set's own painting, when it has one. The API's id goes with
    /// it so an offline copy can be found.
    var setId: Int = 0
    var artwork: SetArtwork? = nil

    /// Pinned to the top of the picker. A pin, not a star: the list
    /// isn't rated, it's ordered — this set is the one you keep coming
    /// back to, so it sits where you can reach it.
    var isPinned: Bool = false
    var onTogglePin: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 10) {
                // The pin sits in the tile's corner but keeps a 44pt target,
                // pulled out over the card's own padding so it reads flush
                // and still takes a thumb.
                HStack {
                    Spacer()
                    if let onTogglePin {
                        Button(action: onTogglePin) {
                            AppIcon(isPinned ? "ph-push-pin-fill" : "ph-push-pin", size: 15)
                                .foregroundColor(
                                    isPinned ? AppColors.gold
                                        : artwork == nil ? AppColors.textSecondary.opacity(0.55)
                                        : AppColors.cream.opacity(0.8)
                                )
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPinned ? "Unpin this set" : "Pin this set to the top")
                        .padding(.top, -14)
                        .padding(.trailing, -14)
                    }
                }
                .frame(height: 20)

                Spacer(minLength: 0)

                Text(title)
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.cream)
                    .lineSpacing(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !labels.isEmpty {
                    Text(labelLine)
                        .font(AppFonts.labelFont(9.5))
                        .tracking(1.6)
                        .foregroundColor(artwork == nil ? AppColors.accentSoft : AppColors.cream.opacity(0.8))
                        .lineLimit(2)
                }
            }
            // Words over a painting get a breath of shadow, so a pale
            // passage behind them can't take the title away
            .shadow(color: .black.opacity(artwork == nil ? 0 : 0.55), radius: 4, y: 1)
            // A floor, not a ceiling: the tile grows with the text size
            // rather than letting a long title climb out of it.
            .frame(minHeight: 172, alignment: .bottomLeading)
            // The card's own fill would sit over anything laid behind it, so
            // a painted tile draws its ground here instead: the card fill,
            // the painting over it, and a scrim that gathers only under the
            // title — like the home grid's — so the painting stays clear
            // through the top of the tile where nothing needs to be read.
            // The card fill stays beneath so a painting that never arrives
            // leaves a plain tile, not a hole in the shelf.
            .sacredCard(padding: 14, filled: artwork == nil)
            .background {
                if let artwork {
                    ZStack {
                        AppColors.cardBackground
                        SetArtworkView(setId: setId, artwork: artwork, fallback: .nothing)
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.08), location: 0),
                                .init(color: .black.opacity(0.22), location: 0.45),
                                .init(color: .black.opacity(0.72), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .allowsHitTesting(false)
                }
            }
            // A pinned set carries a brighter rim, so the pinned ones read
            // as a group even once they're scrolled among the rest
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(isPinned ? 0.55 : 0), lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.25), value: isPinned)
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    private var labelLine: String { MeditationLabel.displayLine(labels) }
}

// MARK: - Row

/// The list reading of a set: type only, ruled off from its neighbour,
/// with the same pin the tile carries at the trailing edge.
struct MeditationSetRow: View {

    let title: String
    var labels: [String] = []

    /// The set's own painting, when it has one — a small plate at the
    /// leading edge. Rows without one keep to type.
    var setId: Int = 0
    var artwork: SetArtwork? = nil

    var isPinned: Bool = false
    var showsDivider: Bool = true
    var onTogglePin: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 0) {
                if showsDivider {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.15))
                        .frame(height: 0.5)
                }

                HStack(spacing: 14) {
                    if let artwork {
                        SetArtworkView(setId: setId, artwork: artwork, fallback: .nothing)
                            .background(AppColors.cardBackground)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5)
                            )
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(AppFonts.headlineFont(16))
                            .foregroundColor(AppColors.cream)
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.leading)

                        if !labels.isEmpty {
                            Text(MeditationLabel.displayLine(labels))
                                .font(AppFonts.labelFont(10))
                                .tracking(1.6)
                                .foregroundColor(AppColors.accentSoft)
                        }
                    }

                    Spacer(minLength: 0)

                    if let onTogglePin {
                        Button(action: onTogglePin) {
                            AppIcon(isPinned ? "ph-push-pin-fill" : "ph-push-pin", size: 14)
                                .foregroundColor(isPinned ? AppColors.gold : AppColors.textSecondary.opacity(0.55))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPinned ? "Unpin this set" : "Pin this set to the top")
                        // The row's own padding keeps its height; the
                        // target overhangs it invisibly.
                        .padding(.vertical, -15)
                    } else if isPinned {
                        AppIcon("ph-push-pin-fill", size: 12)
                            .foregroundColor(AppColors.gold.opacity(0.8))
                            .accessibilityLabel("Pinned")
                    }

                    AppIcon("ph-caret-right", size: 11)
                        .foregroundColor(AppColors.gold.opacity(0.5))
                }
                .padding(.vertical, 15)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(SacredCardButtonStyle())
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                MeditationSetTile(
                    title: "Blessed Fulton J. Sheen",
                    labels: ["Considerations"],
                    isPinned: true,
                    onTogglePin: {}
                )
                MeditationSetTile(
                    title: "Blessed Anne Catherine Emmerich",
                    labels: ["Saints", "Contemplative"],
                    onTogglePin: {}
                )
            }

            VStack(spacing: 0) {
                MeditationSetRow(title: "Blessed Fulton J. Sheen", labels: ["Considerations"], isPinned: true, showsDivider: false)
                MeditationSetRow(title: "St. Alphonsus Liguori - Short", labels: ["Saints", "Considerations"])
                MeditationSetRow(title: "Blessed Anne Catherine Emmerich", labels: ["Contemplative"])
            }
        }
        .padding(20)
    }
    .background(AppColors.background)
}
