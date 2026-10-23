//
//  MyPlaylistView.swift
//  Lumen Viae
//
//  One playlist of the reader's on its own page: its image at the head,
//  its name, PRAY, and its prayers in order, each a row with its own
//  painting. A row begins the playlist from that prayer. EDIT opens the
//  playlist's editor (`MyPlaylistEditor`).
//

import SwiftUI

struct MyPlaylistView: View {

    let playlistID: UUID

    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    private let store = MyPrayersStore.shared

    @State private var editing = false

    /// The image a playlist hangs: the one chosen, else its first
    /// prayer's painting
    static func painting(of playlist: PrayerPlaylist) -> PrayerBookPainting {
        if let art = playlist.art { return .chosen(art, caption: playlist.displayName) }
        return .prayer(playlist.prayerIDs.first ?? "")
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let playlist = store.playlist(playlistID) {
                page(playlist)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                GoldBackButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = true
                } label: {
                    Text("EDIT")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Edit playlist")
            }
        }
        // Deleted from its editor: once the sheet is down, the page goes
        // too, with nothing left to show
        .sheet(isPresented: $editing, onDismiss: {
            if store.playlist(playlistID) == nil { dismiss() }
        }) {
            MyPlaylistEditor(existing: store.playlist(playlistID)).myPrayersSheet()
        }
    }

    private func page(_ playlist: PrayerPlaylist) -> some View {
        let prayers = store.resolvedPrayers(of: playlist)

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                GeometryReader { proxy in
                    PrayersPaintingThumb(
                        painting: Self.painting(of: playlist),
                        width: proxy.size.width, height: 260, radius: 18
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                    )
                }
                .frame(height: 260)

                Text("PLAYLIST · \(PrayerBookView.prayerCount(prayers.count).uppercased())")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold)
                    .padding(.top, 18)

                Text(playlist.displayName)
                    .font(AppFonts.titleFont(28))
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 4)

                if !prayers.isEmpty {
                    PrayersPrayButton(title: "PRAY", spoken: "Pray \(playlist.displayName)") {
                        router.push(.prayAlong(.playlist(playlist)))
                    }
                    .padding(.top, 10)
                }

                VStack(spacing: 0) {
                    if prayers.isEmpty {
                        MyPrayersInvite(line: "This playlist has no prayers yet.", action: "ADD PRAYERS") {
                            editing = true
                        }
                    }
                    ForEach(Array(prayers.enumerated()), id: \.offset) { i, prayer in
                        PrayersPictureRow(
                            prayer: prayer,
                            painting: .prayer(prayer.id),
                            note: nil,
                            showsRule: i < prayers.count - 1
                        ) {
                            router.push(.prayAlong(.playlist(playlist, startingAt: i)))
                        }
                    }
                }
                .padding(.top, 22)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 56)
        }
    }
}
