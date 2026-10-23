//
//  MyPlaylistEditor.swift
//  Lumen Viae
//
//  A playlist of the reader's, made or changed: its name, its image, and
//  its prayers in the order they are prayed, dragged by the handle to
//  reorder and swiped away. Add Prayers opens the book and the reader's
//  own (`MyPrayersPrayerPicker`); a prayer can be written from here too.
//

import SwiftUI

struct MyPlaylistEditor: View {

    /// The playlist being changed, or nil for a new one
    let existing: PrayerPlaylist?

    @Environment(\.dismiss) private var dismiss

    private let store = MyPrayersStore.shared

    @State private var name = ""
    @State private var art: String?
    @State private var items: [Item] = []
    @State private var choosingArt = false
    @State private var addingPrayers = false
    @State private var writingPrayer = false
    @State private var confirmingDelete = false

    /// One place in the playlist. Its own id, since a prayer may stand
    /// twice (the Sign of the Cross opens and closes)
    struct Item: Identifiable, Hashable {
        let id = UUID()
        let prayerID: String
    }

    init(existing: PrayerPlaylist? = nil) {
        self.existing = existing
    }

    private var hasNoName: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                SheetHeader(kicker: "My Playlists", title: existing == nil ? "New Playlist" : "Edit Playlist") {
                    HStack(spacing: 4) {
                        SheetHeaderAction(title: "Cancel") { dismiss() }
                        SheetHeaderAction(title: "Save", action: save)
                            .disabled(hasNoName)
                            .opacity(hasNoName ? 0.35 : 1)
                    }
                }

                List {
                    Section {
                        TextField("Family Morning Prayer", text: $name)
                            .font(AppFonts.readingFont(20))
                            .foregroundColor(AppColors.cream)
                            .tint(AppColors.gold)
                            .listRowBackground(AppColors.cardBackground)

                        MyPrayersArtRow(art: art, fallback: firstPainting) { choosingArt = true }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    } header: {
                        sectionLabel("Name and image")
                    }

                    Section {
                        if items.isEmpty {
                            Text("No prayers yet. Add the book's, or write your own.")
                                .font(AppFonts.readingItalicFont(15))
                                .foregroundColor(AppColors.textSecondary)
                                .listRowBackground(AppColors.cardBackground)
                        }
                        ForEach(items) { item in
                            itemRow(item)
                                .listRowBackground(AppColors.cardBackground)
                        }
                        .onMove { items.move(fromOffsets: $0, toOffset: $1) }
                        .onDelete { items.remove(atOffsets: $0) }

                        Button {
                            addingPrayers = true
                        } label: {
                            Label("Add Prayers", systemImage: "plus")
                                .font(AppFonts.bodyFont(16))
                                .foregroundColor(AppColors.gold)
                        }
                        .listRowBackground(AppColors.cardBackground)

                        Button {
                            writingPrayer = true
                        } label: {
                            Label("Write a New Prayer", systemImage: "square.and.pencil")
                                .font(AppFonts.bodyFont(16))
                                .foregroundColor(AppColors.gold)
                        }
                        .listRowBackground(AppColors.cardBackground)
                    } header: {
                        sectionLabel(items.isEmpty ? "Prayers" : "Prayers · \(items.count)")
                    } footer: {
                        if items.count > 1 {
                            Text("Drag to change the order. Swipe to take one out.")
                                .font(AppFonts.readingItalicFont(13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    if existing != nil {
                        Section {
                            Button(role: .destructive) {
                                confirmingDelete = true
                            } label: {
                                Text("Delete This Playlist")
                                    .font(AppFonts.bodyFont(16))
                            }
                            .listRowBackground(AppColors.cardBackground)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
        }
        .onAppear {
            guard let existing else { return }
            name = existing.name
            art = existing.art
            items = existing.prayerIDs.map { Item(prayerID: $0) }
        }
        .sheet(isPresented: $choosingArt) {
            MyPrayersArtPicker(current: art) { art = $0 }
                .myPrayersSheet()
        }
        .sheet(isPresented: $addingPrayers) {
            MyPrayersPrayerPicker { ids in
                items.append(contentsOf: ids.map { Item(prayerID: $0) })
            }
            .myPrayersSheet()
        }
        .sheet(isPresented: $writingPrayer) {
            MyPrayerEditor { prayer in
                items.append(Item(prayerID: prayer.prayerID))
            }
            .myPrayersSheet()
        }
        .confirmationDialog("Delete this playlist?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let existing { store.delete(existing) }
                dismiss()
            }
        } message: {
            Text("Its prayers stay in the book and in My Prayers.")
        }
    }

    /// The image the playlist hangs before one is chosen: its first
    /// prayer's
    private var firstPainting: PrayerBookPainting {
        PrayerBookPainting.prayer(items.first?.prayerID ?? "")
    }

    private func itemRow(_ item: Item) -> some View {
        let prayer = PrayAlongLaunch.resolve(item.prayerID)
        return HStack(spacing: 12) {
            PrayersPaintingThumb(painting: .prayer(item.prayerID), width: 40, height: 40, radius: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(prayer?.listTitle ?? "A prayer no longer kept")
                    .font(AppFonts.readingFont(17))
                    .foregroundColor(prayer == nil ? AppColors.textSecondary : AppColors.cream)
                    .lineLimit(1)
                if CustomPrayer.uuid(in: item.prayerID) != nil {
                    Text("Your own")
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        MyPrayersLabel(title)
    }

    private func save() {
        var playlist = existing ?? PrayerPlaylist(name: "")
        playlist.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        playlist.art = art
        playlist.prayerIDs = items.map(\.prayerID)
        store.save(playlist)
        dismiss()
    }
}

// MARK: - The prayer picker

/// The prayers a playlist can take: the reader's own first, then the
/// book's orders (all their prayers at once), then every prayer of the
/// book by name, with a search over them all. A tap adds; the count at
/// the head says how many will be added on Done.
struct MyPrayersPrayerPicker: View {

    let add: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss

    private let store = MyPrayersStore.shared

    @State private var picked: [String] = []
    @State private var query = ""

    private var bookPrayers: [BookPrayer] {
        PrayerBook.prayers.values.sorted {
            $0.listTitle.localizedCaseInsensitiveCompare($1.listTitle) == .orderedAscending
        }
    }

    private func matches(_ title: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty || title.localizedCaseInsensitiveContains(trimmed)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                SheetHeader(
                    kicker: picked.isEmpty ? "Add to playlist" : "\(PrayerBookView.prayerCount(picked.count)) to add",
                    title: "Add Prayers"
                ) {
                    HStack(spacing: 4) {
                        SheetHeaderAction(title: "Cancel") { dismiss() }
                        SheetHeaderAction(title: "Done") {
                            add(picked)
                            dismiss()
                        }
                    }
                }

                TextField("Find a prayer", text: $query)
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)
                    .tint(AppColors.gold)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AppColors.cardBackground))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)

                List {
                    let mine = store.prayers.filter { matches($0.bookPrayer.title) }
                    if !mine.isEmpty {
                        Section {
                            ForEach(mine) { prayer in
                                row(
                                    title: prayer.bookPrayer.title, note: "Your own",
                                    painting: .prayer(prayer.prayerID), ids: [prayer.prayerID])
                            }
                        } header: {
                            sectionLabel("My Prayers")
                        }
                    }

                    let orders = PrayerBook.orders.filter { matches($0.title) }
                    if !orders.isEmpty {
                        Section {
                            ForEach(orders) { order in
                                let ids = order.prayers().map(\.id)
                                row(
                                    title: order.title,
                                    note: "All \(PrayerBookView.prayerCount(ids.count))",
                                    painting: .order(order),
                                    ids: ids
                                )
                            }
                        } header: {
                            sectionLabel("Orders of prayer")
                        }
                    }

                    Section {
                        ForEach(bookPrayers.filter { matches($0.listTitle) || matches($0.title) }) { prayer in
                            row(title: prayer.listTitle, note: nil, painting: .prayer(prayer.id), ids: [prayer.id])
                        }
                    } header: {
                        sectionLabel("The Prayer Book")
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func row(title: String, note: String?, painting: PrayerBookPainting, ids: [String]) -> some View {
        let times = ids.count == 1 ? picked.filter { $0 == ids[0] }.count : 0
        return Button {
            picked.append(contentsOf: ids)
        } label: {
            HStack(spacing: 12) {
                PrayersPaintingThumb(painting: painting, width: 40, height: 40, radius: 7)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                    if let note {
                        Text(note)
                            .font(AppFonts.readingItalicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                if times > 0 {
                    Text(times == 1 ? "ADDED" : "ADDED ×\(times)")
                        .font(AppFonts.labelFont(9))
                        .tracking(1.6)
                        .foregroundColor(AppColors.gold)
                } else {
                    AppIcon("ph-plus", size: 14)
                        .foregroundColor(AppColors.gold)
                }
            }
            .contentShape(Rectangle())
        }
        .listRowBackground(AppColors.cardBackground)
        .accessibilityLabel(times > 0 ? "\(title), added" : title)
        .accessibilityHint("Adds to the playlist")
    }

    private func sectionLabel(_ title: String) -> some View {
        MyPrayersLabel(title)
    }
}

// MARK: - Sheet chrome

/// A field's or a group's name in the editors: NAME, WORDS, PRAYERS
struct MyPrayersLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(AppFonts.labelFont(9.5))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundColor(AppColors.gold)
    }
}

extension View {
    /// The editors' sheets, dressed as the app's other sheets are
    func myPrayersSheet() -> some View {
        presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColors.background)
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
    }
}
