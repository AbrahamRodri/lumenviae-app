//
//  PrayerOrderView.swift
//  Lumen Viae
//
//  An order of prayer's own page — Morning Prayers, Before Confession —
//  set like a title page: when it is prayed, its name, what it is, and
//  its prayers as a numbered ledger, each a door to its own page. At the
//  foot, how it will be prayed (aloud in the chosen voice, or in
//  silence) as one quiet line over PRAY, the page's one gold act.
//

import SwiftUI

struct PrayerOrderView: View {

    let orderID: String

    @Environment(AppRouter.self) private var router

    private var store = PrayerBookStore.shared
    private var voices = NarrationVoiceCatalog.shared

    @State private var now = Date()
    @State private var footHeight: CGFloat = 0

    init(orderID: String) {
        self.orderID = orderID
    }

    private var order: PrayerOrder? { PrayerBook.order(orderID) }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appGradient.ignoresSafeArea()

            if let order {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header(order)
                            .padding(.horizontal, 28)
                            .padding(.top, 8)
                            .devotionalEntrance()

                        ledger(order)
                            .padding(.horizontal, 20)
                            .padding(.top, 28)
                            .devotionalEntrance(delay: 0.06)

                        if let season = seasonNote(order) {
                            Text(season)
                                .font(AppFonts.readingItalicFont(14))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 32)
                                .padding(.top, 18)
                        }

                        // Room to scroll the last prayer clear of the
                        // foot, measured: at the larger text sizes the
                        // foot outgrows a fixed 240 and hid the last row
                        Color.clear.frame(height: max(240, footHeight))
                    }
                }
                .topChromeFade()

                foot(order)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footHeight = $0 }
            }
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
            // Prayers is a tab, and the door to it clears the stack it is
            // opened from. Opened from the tab itself, Back already goes
            // there without losing the way back, so the door stands down
            if router.selectedTab != .prayers {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { router.push(.prayerBook) } label: {
                        AppIcon("ch-praying-hands", size: 18)
                            .foregroundColor(AppColors.gold)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Prayers")
                }
            }
        }
        .onAppear { now = Date() }
    }

    private func header(_ order: PrayerOrder) -> some View {
        let offered = store.wasOffered(order.id, on: now)
        return VStack(spacing: 12) {
            Text(order.occasion.uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            AppIcon(order.icon, size: 30)
                .foregroundColor(AppColors.goldLight)
                .shadow(color: AppColors.gold.opacity(0.45), radius: 10)

            Text(order.title(on: now))
                .font(AppFonts.titleFont(29))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            Text(order.latinTitle)
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.65))

            OrnamentDivider()
                .frame(width: 150)
                .padding(.vertical, 2)

            Text(order.detail)
                .font(AppFonts.readingItalicFont(15.5))
                .foregroundColor(AppColors.cream.opacity(0.82))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if offered {
                HStack(spacing: 6) {
                    AppIcon("ph-seal-check-fill", size: 12)
                    Text("PRAYED TODAY")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                }
                .foregroundColor(AppColors.gold)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func ledger(_ order: PrayerOrder) -> some View {
        let prayers = order.prayers(on: now)
        return VStack(alignment: .leading, spacing: 4) {
            Text(prayers.count == 1 ? "THE PRAYER" : "THE \(prayers.count) PRAYERS, IN ORDER")
                .font(AppFonts.labelFont(8.5))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .padding(.leading, 2)

            VStack(spacing: 0) {
                ForEach(Array(prayers.enumerated()), id: \.element.id) { i, prayer in
                    BookPrayerRow(prayer: prayer, number: i + 1, showsRule: i < prayers.count - 1) {
                        router.push(.devotionPrayer(id: prayer.id))
                    }
                }
            }
        }
    }

    /// Why the order holds what it holds today, where the season decides
    private func seasonNote(_ order: PrayerOrder) -> String? {
        switch order.id {
        case PrayerBook.nightOrderID:
            // The season named as it is written, never lowered: lowered,
            // it once read "trinity Sunday" and "eastertide"
            let antiphon = PrayerBook.antiphon(on: now)
            return "Night Prayers end with this season's song to Mary, \(antiphon.name) (\(antiphon.latinName)), sung at night from \(antiphon.season)."
        case PrayerBook.angelusOrderID where PrayerBook.isEastertide(now):
            return "From Easter to Pentecost, Queen of Heaven (Regina Cæli) is said instead of the Angelus."
        default:
            return nil
        }
    }

    // MARK: - Foot

    private func foot(_ order: PrayerOrder) -> some View {
        VStack(spacing: 10) {
            // A real switch, answering a tap anywhere on the line — a
            // line of small capitals alone reads as a label nobody knows
            // to tap
            Button {
                withAnimation(Motion.settle) { store.praysAloud.toggle() }
            } label: {
                HStack(spacing: 12) {
                    AppIcon(store.praysAloud ? "ph-speaker-high-fill" : "ph-speaker-high", size: 15)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Pray aloud")
                            .font(AppFonts.bodyFont(15.5))
                            .foregroundColor(AppColors.cream)
                        Text(store.praysAloud
                             ? "Read to you in the \(voices.chosenVoice.name.lowercased()) voice"
                             : "The prayers on the page, in silence")
                            .font(AppFonts.readingItalicFont(12.5))
                            .foregroundColor(AppColors.textSecondary)
                            .contentTransition(.opacity)
                    }
                    Spacer(minLength: 8)
                    Toggle("", isOn: .constant(store.praysAloud))
                        .labelsHidden()
                        .tint(AppColors.gold)
                        .allowsHitTesting(false)
                }
                .padding(.horizontal, 4)
                .frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pray aloud")
            .accessibilityValue(store.praysAloud ? "On" : "Off")
            .accessibilityAddTraits(.isButton)

            GoldCTAButton(title: "Pray", glyph: .play) {
                // The switch stands just above PRAY, so what it shows is
                // the reader's answer; the pray-along screen won't ask
                store.chooseAloud(store.praysAloud)
                router.push(.prayAlong(.order(order, on: now)))
            }
        }
        .padding(.horizontal, 24)
        // Clear of the ground's fade, so the ledger never reads through
        // the switch
        .padding(.top, 92)
        .padding(.bottom, 20)
        .background(PrayFootGround())
    }
}

#Preview {
    NavigationStack {
        PrayerOrderView(orderID: "before_confession")
            .environment(AppRouter())
    }
}
