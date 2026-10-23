//
//  MyPrayersView.swift
//  Lumen Viae
//
//  My Prayers: the reader's playlists and the prayers they wrote, kept
//  on the device. Reached from the My Prayers shelf on the Prayers tab
//  (`MyPrayersShelf`). A playlist opens its own page (`MyPlaylistView`),
//  where PRAY says its prayers one after another on the pray-along
//  screen; a prayer of the reader's is prayed alone, and its pencil
//  opens it to be changed.
//

import SwiftUI

// MARK: - The page

struct MyPrayersView: View {

    @Environment(AppRouter.self) private var router

    private let store = MyPrayersStore.shared

    @State private var newPlaylist = false
    @State private var newPrayer = false
    @State private var editing: CustomPrayer?

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Text("My Prayers")
                        .font(AppFonts.titleFont(28))
                        .foregroundColor(AppColors.cream)
                        .accessibilityAddTraits(.isHeader)

                    playlists
                    prayers
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 56)
            }
            .topChromeFade(height: 24, inset: 14)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                GoldBackButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("New Playlist", systemImage: "list.bullet") { newPlaylist = true }
                    Button("New Prayer", systemImage: "square.and.pencil") { newPrayer = true }
                } label: {
                    AppIcon("ph-plus", size: 18)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Add")
            }
        }
        .sheet(isPresented: $newPlaylist) {
            MyPlaylistEditor().myPrayersSheet()
        }
        .sheet(isPresented: $newPrayer) {
            MyPrayerEditor().myPrayersSheet()
        }
        .sheet(item: $editing) { prayer in
            MyPrayerEditor(existing: prayer).myPrayersSheet()
        }
    }

    // MARK: Playlists

    private var playlists: some View {
        VStack(alignment: .leading, spacing: 10) {
            PrayersShelfHeading(title: "Playlists")
            if store.playlists.isEmpty {
                MyPrayersInvite(
                    line: "Gather the prayers you say together, in your order, and pray them one after another.",
                    action: "NEW PLAYLIST"
                ) { newPlaylist = true }
            } else {
                VStack(spacing: 10) {
                    ForEach(store.playlists) { playlist in
                        MyPlaylistCard(playlist: playlist) {
                            router.push(.myPlaylist(id: playlist.id))
                        } pray: {
                            router.push(.prayAlong(.playlist(playlist)))
                        }
                    }
                }
            }
        }
    }

    // MARK: Prayers

    private var prayers: some View {
        VStack(alignment: .leading, spacing: 6) {
            PrayersShelfHeading(title: "Prayers I Wrote")
            if store.prayers.isEmpty {
                MyPrayersInvite(
                    line: "Write a prayer of your own, or one your family says in its own words.",
                    action: "NEW PRAYER"
                ) { newPrayer = true }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.prayers.enumerated()), id: \.element.id) { i, prayer in
                        HStack(spacing: 0) {
                            PrayersPictureRow(
                                prayer: prayer.bookPrayer,
                                painting: .prayer(prayer.prayerID),
                                note: firstLine(of: prayer.text),
                                showsRule: i < store.prayers.count - 1
                            ) {
                                router.push(.devotionPrayer(id: prayer.prayerID))
                            }
                            Button {
                                editing = prayer
                            } label: {
                                AppIcon("ph-pencil-simple", size: 15)
                                    .foregroundColor(AppColors.gold)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(QuietGlyphButtonStyle())
                            .accessibilityLabel("Edit \(prayer.bookPrayer.title)")
                        }
                    }
                }
            }
        }
    }

    private func firstLine(of text: String) -> String? {
        let line = text.split(whereSeparator: \.isNewline).first.map(String.init)?
            .trimmingCharacters(in: .whitespaces)
        return line?.isEmpty == false ? line : nil
    }
}

// MARK: - A playlist's card

/// A playlist as a wide card: its image, its name, how many prayers, and
/// PRAY. The card opens the playlist's page; PRAY begins it.
struct MyPlaylistCard: View {
    let playlist: PrayerPlaylist
    let open: () -> Void
    let pray: () -> Void

    var body: some View {
        let count = MyPrayersStore.shared.resolvedPrayers(of: playlist).count

        ZStack(alignment: .bottomTrailing) {
            Button(action: open) {
                HStack(spacing: 14) {
                    PrayersPaintingThumb(
                        painting: MyPlaylistView.painting(of: playlist), width: 92, height: 92, radius: 12)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("PLAYLIST")
                            .font(AppFonts.labelFont(9))
                            .tracking(2.2)
                            .foregroundColor(AppColors.gold)
                        Text(playlist.displayName)
                            .font(AppFonts.titleFont(18))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(PrayerBookView.prayerCount(count))
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline)
                )
                .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(SacredCardButtonStyle(scales: false))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(playlist.displayName), playlist, \(PrayerBookView.prayerCount(count))")
            .accessibilityHint("Shows its prayers")
            .accessibilityAddTraits(.isButton)

            if count > 0 {
                PrayersPrayButton(title: "PRAY", spoken: "Pray \(playlist.displayName)", action: pray)
                    .padding(.trailing, 14)
                    .padding(.bottom, 6)
            }
        }
    }
}

// MARK: - An empty shelf

/// What an empty shelf of the reader's says: one line, and the way to
/// begin it
struct MyPrayersInvite: View {
    let line: String
    let action: String
    let perform: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(line)
                .font(AppFonts.readingItalicFont(15.5))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: perform) {
                HStack(spacing: 8) {
                    AppIcon("ph-plus", size: 12)
                    Text(action)
                        .font(AppFonts.labelFont(9.5))
                        .tracking(2)
                }
                .foregroundColor(AppColors.gold)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.cardBackground))
    }
}

// MARK: - The shelf on the Prayers tab

/// My Prayers on the Prayers tab, under the shortcuts: the reader's
/// playlists as wide cards with PRAY, SEE ALL to the page. Before there
/// are any, one line and the way to make the first.
struct MyPrayersShelf: View {
    @Environment(AppRouter.self) private var router

    private let store = MyPrayersStore.shared

    @State private var newPlaylist = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PrayersShelfHeading(title: "My Prayers") {
                router.push(.myPrayers)
            }
            if store.playlists.isEmpty {
                MyPrayersInvite(
                    line: "Make a playlist of the prayers you say together, with your own words and pictures.",
                    action: "NEW PLAYLIST"
                ) { newPlaylist = true }
            } else {
                VStack(spacing: 10) {
                    ForEach(store.playlists.prefix(3)) { playlist in
                        MyPlaylistCard(playlist: playlist) {
                            router.push(.myPlaylist(id: playlist.id))
                        } pray: {
                            router.push(.prayAlong(.playlist(playlist)))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $newPlaylist) {
            MyPlaylistEditor().myPrayersSheet()
        }
    }
}
