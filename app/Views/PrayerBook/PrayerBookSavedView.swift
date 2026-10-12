//
//  PrayerBookSavedView.swift
//  Lumen Viae
//
//  Saved: the prayers the reader has kept with the bookmark at the head
//  of a prayer's page, opened from the Saved shortcut at the top of
//  Prayers. Empty, it says how a prayer comes to stand here, and offers
//  the prayers everyone knows to begin with.
//

import SwiftUI

struct PrayerBookSavedView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize

    private var store = PrayerBookStore.shared

    init() {}

    var body: some View {
        let kept = store.keptPrayers
        let columns = typeSize >= .xLarge ? 2 : 3

        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Saved")
                            .font(AppFonts.titleFont(28))
                            .foregroundColor(AppColors.cream)
                            .accessibilityAddTraits(.isHeader)
                        Text("To save a prayer here, tap the bookmark at the top of its page.")
                            .font(AppFonts.readingItalicFont(15))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if kept.isEmpty {
                        PrayersLedgerRow(title: "The First Prayers", note: "The first prayers to keep close") {
                            router.push(.prayerBookChapter(id: "first"))
                        }
                    } else {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
                                count: columns
                            ),
                            alignment: .leading,
                            spacing: 10
                        ) {
                            ForEach(kept) { prayer in
                                SavedPrayerCard(prayer: prayer) {
                                    router.push(.devotionPrayer(id: prayer.id))
                                }
                                .transition(.opacity)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 56)
                .animation(Motion.crossfade, value: store.ribbons)
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
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
