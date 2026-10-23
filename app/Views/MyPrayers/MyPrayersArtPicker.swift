//
//  MyPrayersArtPicker.swift
//  Lumen Viae
//
//  The image a prayer or playlist of the reader's hangs: one of the
//  app's paintings, in a grid under the parts of the faith they show, or
//  a photo from the reader's library (`PhotosPicker`, which runs out of
//  the app's process and asks for no access to the library). A photo is
//  scaled down and kept beside the reader's prayers (`UserPhotoStore`).
//

import PhotosUI
import SwiftUI

// MARK: - The paintings

/// The paintings of the catalog a reader may choose, by the part of the
/// faith they show. Every name is checked against the catalog in the
/// tests (`MyPrayersTests`).
enum MyPrayersPaintings {

    struct Group: Identifiable {
        let title: String
        let assets: [String]
        var id: String { title }
    }

    static let groups: [Group] = [
        Group(
            title: "Our Lady",
            assets: [
                "mary_virgin_in_prayer", "mary_sistine_madonna", "mary_immaculate_conception", "mary_mother_of_mercy",
                "mary_mount_carmel", "mary_of_the_snows", "mary_mater_dolorosa", "feast_annunciation",
                "feast_our_lady_of_the_rosary", "prayer_holy_family",
            ]),
        Group(
            title: "Our Lord",
            assets: [
                "jesus_light_of_the_world", "jesus_good_shepherd", "jesus_holy_name", "jesus_anima_christi",
                "jesus_eucharist_saviour", "jesus_precious_blood", "jesus_healing_blind", "jesus_washing_feet",
                "children_blessed", "christ_and_the_adulteress", "communion_of_apostles", "crucifixion_mond",
                "last_supper_juanes", "mass_lamb_of_god", "order_raising_of_lazarus", "prayer_healing_sick",
                "prayer_supper_emmaus", "tribute_money", "last_judgment",
            ]),
        Group(
            title: "Saints and Angels",
            assets: [
                "devotion_st_joseph", "saint_joseph_carpenter", "devotion_guardian_angels", "prayer_tobias_angel",
                "saint_michael", "devotion_holy_trinity", "feast_all_saints", "devotion_holy_souls", "carlo_acutis",
                "saint_ignatius", "saint_francis_desert", "saint_anthony", "saint_benedict", "saint_thomas_aquinas",
                "saint_jude", "saint_peter_tears", "saint_paul_conversion", "saint_matthew_calling",
                "saint_john_baptist_birth", "saint_teresa_purgatory", "saint_gertrude", "saint_bonaventure",
                "saint_ambrose", "saint_jerome_penitent", "apostles_calling_duccio", "psalm_king_david",
            ]),
        Group(
            title: "The Mysteries",
            assets: [
                "joyful_annunciation", "joyful_visitation", "joyful_nativity", "joyful_presentation", "joyful_finding",
                "luminous_baptism", "luminous_cana", "luminous_proclamation", "luminous_transfiguration",
                "luminous_eucharist", "sorrowful_agony", "sorrowful_scourging", "sorrowful_crowning",
                "sorrowful_carrying", "sorrowful_crucifixion", "glorious_resurrection", "glorious_ascension",
                "glorious_pentecost", "glorious_assumption", "glorious_coronation", "easter_appears_to_mary",
                "easter_holy_women", "easter_noli_me_tangere", "easter_saint_thomas", "seven_sorrows_simeon",
                "seven_sorrows_flight", "seven_sorrows_finding", "seven_sorrows_meeting", "seven_sorrows_calvary",
                "seven_sorrows_descent", "seven_sorrows_pieta", "seven_sorrows_burial",
            ]),
        Group(
            title: "Hours, Seasons and Feasts",
            assets: [
                "hour_morning", "hour_night", "season_advent", "season_lent", "advent_isaiah", "shepherds_annunciation",
                "christmas_shepherds", "pentecost_maino", "feast_christ_the_king", "topic_daily_prayers",
                "topic_first_prayers", "topic_short_prayers", "topic_holy_mass", "topic_blessed_sacrament",
                "topic_confession", "topic_holy_trinity", "topic_our_lord", "topic_thanksgiving",
                "topic_for_the_living",
                "topic_needs", "topic_sick_dying", "topic_feasts_seasons", "virtue_faith_isaac", "virtue_hope_dove",
                "virtue_charity_samaritan",
            ]),
    ]

    static var all: [String] { groups.flatMap(\.assets) }
}

// MARK: - The row in an editor

/// The image row of an editor: the chosen image, small, its name, and a
/// tap to change it
struct MyPrayersArtRow: View {
    let art: String?
    let fallback: PrayerBookPainting
    let choose: () -> Void

    var body: some View {
        Button(action: choose) {
            HStack(spacing: 14) {
                PrayersPaintingThumb(
                    painting: art.map { PrayerBookPainting.chosen($0, caption: "") } ?? fallback,
                    width: 64, height: 64, radius: 10
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
                )
                VStack(alignment: .leading, spacing: 2) {
                    MyPrayersLabel("Image")
                    Text(description)
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.cream)
                }
                Spacer(minLength: 8)
                Text("CHANGE")
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Image, \(description)")
        .accessibilityHint("Choose a painting or a photo")
    }

    private var description: String {
        guard let art else { return "The book's own" }
        return UserPhotoStore.isPhoto(art) ? "Your photo" : "A painting"
    }
}

// MARK: - The picker

struct MyPrayersArtPicker: View {

    /// The image chosen now, nil for the book's own
    let current: String?
    let choose: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var savingPhoto = false
    @State private var photoFailed = false

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                SheetHeader(kicker: "Image", title: "Choose an Image") {
                    SheetHeaderAction(title: "Done") { dismiss() }
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        photoButton
                        if photoFailed {
                            Text("That photo could not be read. Try another.")
                                .font(AppFonts.readingItalicFont(14))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        if current != nil {
                            Button {
                                pick(nil)
                            } label: {
                                Text("USE THE BOOK'S OWN PAINTINGS")
                                    .font(AppFonts.labelFont(9.5))
                                    .tracking(2)
                                    .foregroundColor(AppColors.gold)
                                    .frame(minHeight: 44)
                            }
                            .buttonStyle(QuietGlyphButtonStyle())
                        }

                        ForEach(MyPrayersPaintings.groups) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                PrayersShelfHeading(title: group.title)
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(group.assets, id: \.self) { asset in
                                        paintingCell(asset)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await savePhoto(item) }
        }
    }

    private var photoButton: some View {
        PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
            HStack(spacing: 12) {
                AppIcon("ph-image", size: 18)
                    .foregroundColor(AppColors.gold)
                Text(savingPhoto ? "Saving your photo…" : "Choose from Photos")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)
                Spacer()
                if savingPhoto {
                    ProgressView().tint(AppColors.gold)
                } else if let current, UserPhotoStore.isPhoto(current) {
                    AppIcon("ph-check", size: 14)
                        .foregroundColor(AppColors.gold)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.cardBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
            )
        }
        .disabled(savingPhoto)
    }

    private func paintingCell(_ asset: String) -> some View {
        let chosen = current == asset
        return Button {
            pick(asset)
        } label: {
            GeometryReader { proxy in
                PrayersPaintingThumb(
                    painting: PrayerBookPainting(asset: asset, caption: ""),
                    width: proxy.size.width, height: proxy.size.width, radius: 10
                )
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        chosen ? AppColors.gold : AppColors.gold.opacity(0.2), lineWidth: chosen ? 2 : AppLine.hairline)
            )
            .overlay(alignment: .topTrailing) {
                if chosen {
                    AppIcon("ph-check-circle-fill", size: 18)
                        .foregroundColor(AppColors.gold)
                        .padding(6)
                }
            }
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(chosen ? "Painting, chosen" : "Painting")
    }

    private func pick(_ art: String?) {
        choose(art)
        dismiss()
    }

    private func savePhoto(_ item: PhotosPickerItem) async {
        savingPhoto = true
        photoFailed = false
        defer { savingPhoto = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                photoFailed = true
                return
            }
            let name = try await Task.detached { try UserPhotoStore.save(data) }.value
            pick(name)
        } catch {
            photoFailed = true
        }
    }
}
