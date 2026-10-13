//
//  PrayerBookSavedView.swift
//  Lumen Viae
//
//  Saved: the prayers the reader has kept with the bookmark at the head
//  of a prayer's page, opened from the Saved shortcut at the top of
//  Prayers (the "Saved and Prayer Orders" design, option A, Oct 2026).
//  The kept prayers lead, two to a row, each under its own painting with
//  the ribbon it was kept with hung from the painting's head. Empty, the
//  page hangs the Saved shortcut's own painting, says once how a prayer
//  comes to stand here, and offers the prayers everyone knows to begin
//  with. It once said how to save on every visit, over small outlined
//  cards with no painting, three to a row.
//

import SwiftUI

struct PrayerBookSavedView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize

    private let store: PrayerBookStore

    init(store: PrayerBookStore = .shared) {
        self.store = store
    }

    var body: some View {
        let kept = store.keptPrayers

        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Saved")
                            .font(AppFonts.titleFont(28))
                            .foregroundColor(AppColors.cream)
                            .accessibilityAddTraits(.isHeader)
                        Spacer(minLength: 8)
                        if !kept.isEmpty {
                            Text(PrayerBookView.prayerCount(kept.count))
                                .font(AppFonts.readingItalicFont(14))
                                .foregroundColor(AppColors.textSecondary)
                                .contentTransition(.numericText())
                        }
                    }

                    if kept.isEmpty {
                        SavedEmptyShelf {
                            router.push(.prayerBookChapter(id: "first"))
                        }
                        .transition(.opacity)
                    } else {
                        // Two to a row, as the Prayers page's shortcuts stand;
                        // one at the accessibility sizes, where half the
                        // glass cuts a long name short
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
                                count: typeSize >= .accessibility1 ? 1 : 2
                            ),
                            alignment: .leading,
                            spacing: 18
                        ) {
                            ForEach(kept) { prayer in
                                SavedPaintedCard(prayer: prayer, store: store) {
                                    router.push(.devotionPrayer(id: prayer.id))
                                }
                                .transition(.opacity)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 56)
                .animation(Motion.crossfade, value: store.ribbons)
            }
            // The scroll begins under the bar, so a short dissolve is
            // enough; the full one held the title a band's depth below
            // Back, over bare page, on a page meant to open on paintings
            .topChromeFade(height: 24, inset: 14)
        }
        .navigationBarBackButtonHidden(true)
        // The page's own title stands just under the bar, not under the
        // empty band a large title would keep
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { router.pop() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
    }
}

// MARK: - A kept prayer

/// A kept prayer under its painting: the painting cut 4:5 with the ribbon
/// hung from its head, then the prayer's name and the topic it belongs
/// to. The name takes the lines it needs, up to three, at its own size.
private struct SavedPaintedCard: View {
    let prayer: BookPrayer
    let store: PrayerBookStore
    let action: () -> Void

    var body: some View {
        let topic = PrayerBook.homeChapter(of: prayer.id)
        let painting = SavedPrayerPainting.of(prayer.id)

        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Color.clear
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .overlay(CachedAssetImage(painting.resolvedAsset, focal: painting.focal))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                    )
                    // The ribbon the prayer was kept with, hung from the
                    // painting's head as it hangs from the prayer's page
                    .overlay(alignment: .topTrailing) {
                        RibbonMark(kept: true, width: 11, restLength: 30, keptLength: 38)
                            .padding(.trailing, 12)
                            .offset(y: -1)
                    }
                    .padding(.bottom, 6)

                Text(prayer.listTitle)
                    .font(AppFonts.readingFont(16.5))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let topic {
                    Text(topic.title)
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .contextMenu {
            Button {
                withAnimation(Motion.crossfade) { store.toggleRibbon(prayer.id) }
            } label: {
                Label("Remove from Saved", systemImage: "minus.circle")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel([prayer.listTitle, topic?.title].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Remove from Saved") {
            withAnimation(Motion.crossfade) { store.toggleRibbon(prayer.id) }
        }
    }
}

/// The painting a kept prayer stands under: the scene it speaks of where
/// the book names one (the Annunciation for the Hail Mary), else its
/// topic's painting, so a shelf of prayers from different topics is not
/// one painting over and over
enum SavedPrayerPainting {

    static func of(_ prayerID: String) -> PrayerBookPainting {
        if let scene = scene(of: prayerID) { return scene }
        if let topic = PrayerBook.homeChapter(of: prayerID) { return PrayerBookPainting.topic(topic) }
        return PrayerBookPainting.prayer(prayerID)
    }

    /// The scene the book hangs on a prayer of its own, or nil where it
    /// names none. These are the prayers `PrayerBookPainting.prayer`
    /// gives a scene of their own; every other prayer it gives one
    /// painting, which here would hang over half the shelf.
    static func scene(of prayerID: String) -> PrayerBookPainting? {
        scened.contains(prayerID) ? PrayerBookPainting.prayer(prayerID) : nil
    }

    /// Held to `PrayerBookPainting.prayer` by `SavedPrayerPaintingTests`
    static let scened: Set<String> = [
        "our_father", "hail_mary", "glory_be", "apostles_creed", "memorare", "litany_loreto"
    ]
}

// MARK: - Nothing saved yet

/// The page with nothing on it yet: the Saved shortcut's painting
/// dissolving into the page (with no ribbon, which on this page always
/// means a prayer is kept), one sentence
/// saying how a prayer comes here, and the First Prayers as a painted
/// door to begin with
private struct SavedEmptyShelf: View {
    let openFirstPrayers: () -> Void

    var body: some View {
        let painting = PrayerBookPainting.saved
        let first = PrayerBook.chapter("first")

        VStack(alignment: .leading, spacing: 0) {
            CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipped()
                // Dissolves to clear at both edges, so the page's own
                // gradient shows through rather than a slab of one colour
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.14),
                            .init(color: .black, location: 0.45),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.horizontal, -20)
                .accessibilityHidden(true)

            Text("Tap the bookmark at the top of any prayer, and it will wait for you here.")
                .font(AppFonts.readingItalicFont(17))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.top, -30)

            if let first {
                Text("To begin")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundColor(AppColors.gold)
                    .padding(.top, 26)
                    .padding(.bottom, 10)
                    .accessibilityAddTraits(.isHeader)

                SavedBeginBanner(
                    title: first.title,
                    note: "The first prayers to keep close",
                    painting: PrayerBookPainting.topic(first),
                    action: openFirstPrayers
                )
            }
        }
    }
}

/// A door set as a painted banner, the painting dimmed toward its
/// leading edge where the name stands
private struct SavedBeginBanner: View {
    let title: String
    let note: String
    let painting: PrayerBookPainting
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.titleFont(17))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.leading)
                Text(note)
                    .font(AppFonts.readingItalicFont(13.5))
                    .foregroundColor(AppColors.cream.opacity(0.75))
                    .multilineTextAlignment(.leading)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .bottomLeading)
            .background {
                CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                    .overlay(
                        LinearGradient(
                            stops: [
                                .init(color: AppColors.background.opacity(0.92), location: 0),
                                .init(color: AppColors.background.opacity(0.55), location: 0.6),
                                .init(color: AppColors.background.opacity(0.1), location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(note)")
        .accessibilityAddTraits(.isButton)
    }
}
