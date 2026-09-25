//
//  ChapelPrayerBookTile.swift
//  Lumen Viae
//
//  The Prayer Book on the Chapel page: the order for the hour it is —
//  Morning Prayers, the Angelus, Night Prayers — and the reader's own
//  ribbons, the prayers they keep close.
//
//  Full: the hour's order as a door to the book, the ribbons beneath it
//  as doors to their prayers, and PRAY in the foot for the hour's order
//  (the body has doors of its own, so only the foot's act is a control).
//  Half: the hour's order alone, one italic line, and the whole tile
//  prays it.
//

import SwiftUI

struct ChapelPrayerBookTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    private var store = PrayerBookStore.shared

    init(span: Int) {
        self.span = span
    }

    var body: some View {
        if span == 2 { full } else { half }
    }

    private var order: PrayerOrder { PrayerBook.dayOrder(at: Date()) }

    private var offered: Bool { store.wasOffered(order.id) }

    private func pray() {
        router.push(.prayAlong(.order(order)))
    }

    /// "At noon", or "Offered today" once it has been
    private var momentLine: String {
        offered ? "Offered today" : PrayerBook.dayOrderMoment(at: Date())
    }

    // MARK: Full

    private var full: some View {
        let kept = Array(store.keptPrayers.prefix(3))
        let more = store.keptPrayers.count - kept.count

        return ChapelTileFrame(
            tile: .prayers,
            span: 2,
            note: store.keptPrayers.isEmpty ? nil : "\(store.keptPrayers.count) kept",
            act: "Pray",
            onAct: pray
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Button { router.push(.prayerBook) } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: AppLine.hairline * 1.5)
                                .frame(width: 42, height: 42)
                            AppIcon(offered ? "ph-seal-check-fill" : order.icon, size: 18)
                                .foregroundColor(AppColors.gold)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(momentLine.uppercased())
                                .font(AppFonts.labelFont(8.5))
                                .tracking(2)
                                .foregroundColor(AppColors.gold.opacity(0.8))
                            Text(order.title(on: Date()))
                                .font(AppFonts.headlineFont(17))
                                .foregroundColor(AppColors.cream)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }

                        Spacer(minLength: 0)

                        AppIcon("ph-caret-right", size: 11)
                            .foregroundColor(AppColors.gold.opacity(0.5))
                    }
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(order.title(on: Date())), \(momentLine). Opens the Prayer Book.")

                if kept.isEmpty {
                    Text("Keep a prayer with its ribbon, and it stands here.")
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(kept) { prayer in
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.12))
                                .frame(height: AppLine.hairline)
                            Button {
                                router.push(.devotionPrayer(id: prayer.id))
                            } label: {
                                HStack(spacing: 12) {
                                    RibbonMark(kept: true, width: 7, restLength: 12, keptLength: 16)
                                        .frame(width: 20)
                                    Text(prayer.title)
                                        .font(AppFonts.readingFont(15.5))
                                        .foregroundColor(AppColors.cream.opacity(0.92))
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        if more > 0 {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.12))
                                .frame(height: AppLine.hairline)
                            Button { router.push(.prayerBook) } label: {
                                Text("And \(more) more in the book")
                                    .font(AppFonts.readingItalicFont(13.5))
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.bottom, 4)
        } footNote: {
            ChapelFootNote(order.prayers().count == 1 ? "One prayer" : "\(order.prayers().count) prayers together")
        }
    }

    // MARK: Half

    private var half: some View {
        ChapelTileFrame(
            tile: .prayers,
            span: 1,
            act: "Pray",
            onTap: pray,
            accessibilityLabel: "\(order.title(on: Date())), \(momentLine). Prays it."
        ) {
            VStack(alignment: .leading, spacing: 6) {
                AppIcon(offered ? "ph-seal-check-fill" : order.icon, size: 20)
                    .foregroundColor(AppColors.gold)
                    .padding(.bottom, 2)

                Text(order.title(on: Date()))
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                Text(momentLine)
                    .font(AppFonts.readingItalicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
