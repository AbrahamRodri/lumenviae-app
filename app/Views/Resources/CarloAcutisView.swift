//
//  CarloAcutisView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  ST. CARLO ACUTIS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A saint's page, built around a young man rather than a doctrine:
//
//  - His photograph, full-bleed, dissolving into the page, his name set
//    over it.
//  - A saying for today — one of his, the same all day — with another a
//    tap away.
//  - His life as a dated timeline, 1991 to his canonisation in 2025, each
//    moment opening its chapter (`CarloAcutisData.life`).
//  - Live a day as he did: his rule — daily Mass, Adoration, the
//    Rosary, weekly Confession, his guardian angel — each with the door
//    to keep it with him today.
//  - The shrine at the foot: a votive candle for an intention (kept on
//    the device for a day, and put out whenever the reader wishes), the
//    prayer for his intercession, and where and when he is kept. The
//    candle is the page's one gold act; the rule's acts are quiet.
//
//  Content lives in `Data/CarloAcutisData.swift`.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI
import UIKit

// MARK: - CarloAcutisView

struct CarloAcutisView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Votive candle state, persisted locally
    @AppStorage("carloAltar.candleLitAt") private var candleLitAt: Double = 0
    @AppStorage("carloAltar.intention") private var intention: String = ""

    @State private var draftIntention: String = ""
    @State private var flameFlicker: Bool = false
    @FocusState private var intentionFocused: Bool

    @State private var sayingIndex = CarloAcutisData.sayingOfTheDay()

    /// A candle stays lit for 24 hours
    private var isCandleLit: Bool {
        guard candleLitAt > 0 else { return false }
        let litDate = Date(timeIntervalSince1970: candleLitAt)
        return Date().timeIntervalSince(litDate) < 24 * 60 * 60
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                AppColors.appGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero(width: geometry.size.width, topInset: geometry.safeAreaInsets.top)

                        sayingForToday
                            .padding(.horizontal, 30)
                            .padding(.top, 8)
                            .devotionalEntrance(delay: 0.1)

                        sectionTitle("His Life", kicker: "London · Milan · Assisi")
                        lifeTimeline
                            .padding(.horizontal, 24)

                        sectionTitle("Live a Day as He Did", kicker: "His rule of life")
                        ruleOfLife
                            .padding(.horizontal, 20)

                        sectionTitle("The Shrine", kicker: "A candle, a prayer")
                        shrine
                            .padding(.horizontal, 20)
                            .padding(.bottom, 56)
                    }
                }
                .ignoresSafeArea(edges: .top)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
        .onAppear {
            draftIntention = intention
        }
    }

    // MARK: - Hero

    /// His photograph edge to edge, dissolving into the page — never onto
    /// a flat band — with his name over its foot
    private func hero(width: CGFloat, topInset: CGFloat) -> some View {
        let height = min(width * 1.2, 520) + topInset

        return ZStack(alignment: .bottomLeading) {
            Group {
                if UIImage(named: "carlo_acutis") != nil {
                    CachedAssetImage("carlo_acutis", focal: UnitPoint(x: 0.5, y: 0.25))
                } else {
                    StCarloIcon(size: width * 0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: width, height: height)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.55),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityLabel("Photograph of St. Carlo Acutis")

            VStack(alignment: .leading, spacing: 8) {
                Text("SAINT · 1991 \u{2013} 2006")
                    .font(AppFonts.labelFont(10))
                    .tracking(3)
                    .foregroundColor(AppColors.goldLight)

                Text("Carlo Acutis")
                    .font(AppFonts.titleFont(40))
                    .foregroundColor(AppColors.cream)
                    .shadow(color: .black.opacity(0.6), radius: 10, y: 2)

                Text("The first saint of the millennial generation · feast, \(CarloAcutisData.feast.dateLabel)")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .devotionalEntrance(delay: 0.05)
        }
        .frame(width: width, height: height)
    }

    // MARK: - A Saying for Today

    private var sayingForToday: some View {
        VStack(spacing: 14) {
            Text("A SAYING FOR TODAY")
                .font(AppFonts.labelFont(9))
                .tracking(2.6)
                .foregroundColor(AppColors.gold.opacity(0.8))

            ZStack {
                Text("\u{201C}\(CarloAcutisData.sayings[sayingIndex])\u{201D}")
                    .font(AppFonts.readingItalicFont(22))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(sayingIndex)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .animation(Motion.crossfade, value: sayingIndex)

            QuietGoldButton(
                title: "Another",
                leadingIcon: "ph-arrow-counter-clockwise",
                leadingIconSize: 10,
                size: 9.5
            ) {
                sayingIndex = (sayingIndex + 1) % CarloAcutisData.sayings.count
            }
        }
    }

    // MARK: - Section Titles

    private func sectionTitle(_ title: String, kicker: String) -> some View {
        VStack(spacing: 8) {
            OrnamentDivider()
                .frame(width: 120)
                .padding(.bottom, 10)

            Text(kicker.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2.6)
                .foregroundColor(AppColors.gold.opacity(0.8))

            Text(title)
                .font(AppFonts.titleFont(25))
                .foregroundColor(AppColors.cream)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 52)
        .padding(.bottom, 24)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - His Life

    /// The years down the left in Cinzel, the moments beside them, one
    /// gold line binding them
    private var lifeTimeline: some View {
        let moments = CarloAcutisData.timeline

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(moments.enumerated()), id: \.offset) { index, moment in
                Button {
                    router.push(.libraryReading(id: moment.readingID))
                } label: {
                    HStack(alignment: .top, spacing: 14) {
                        Text(moment.year)
                            .font(AppFonts.titleFont(moment.year.count > 4 ? 13 : 19))
                            .foregroundColor(moment.year == "2025" ? AppColors.goldLight : AppColors.gold)
                            .frame(width: 58, alignment: .trailing)
                            .padding(.top, moment.year.count > 4 ? 4 : 0)

                        ZStack(alignment: .top) {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.3))
                                .frame(width: 1)
                                .padding(.top, index == 0 ? 8 : 0)
                                .frame(maxHeight: index == moments.count - 1 ? 8 : .infinity, alignment: .top)

                            Circle()
                                .fill(moment.year == "2025" ? AppColors.goldLight : AppColors.background)
                                .overlay(Circle().strokeBorder(AppColors.goldLight, lineWidth: 1.2))
                                .frame(width: 11, height: 11)
                                .padding(.top, 5)
                        }
                        .frame(width: 11)
                        .frame(maxHeight: .infinity, alignment: .top)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(moment.title)
                                    .font(AppFonts.readingFont(18))
                                    .foregroundColor(AppColors.cream)

                                Spacer(minLength: 8)

                                AppIcon("ph-caret-right", size: 10)
                                    .foregroundColor(AppColors.gold.opacity(0.5))
                            }

                            Text(moment.line)
                                .font(AppFonts.readingItalicFont(14))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 24)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    // MARK: - His Rule of Life

    /// His habits as one card — each with how often he kept it, and,
    /// where the app holds it, the act to keep it with him today
    private var ruleOfLife: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return VStack(spacing: 0) {
            ForEach(Array(CarloAcutisData.rule.enumerated()), id: \.offset) { index, habit in
                HStack(spacing: 14) {
                    Button {
                        router.push(.libraryReading(id: habit.readingID))
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.gold.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                AppIcon(habit.icon, size: 20)
                                    .foregroundColor(AppColors.goldLight)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(habit.often.uppercased())
                                    .font(AppFonts.labelFont(8.5))
                                    .tracking(1.8)
                                    .foregroundColor(AppColors.gold.opacity(0.8))

                                Text(habit.name)
                                    .font(AppFonts.readingFont(17))
                                    .foregroundColor(AppColors.cream)
                            }

                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)

                    if let act = habit.act, let title = habit.actTitle {
                        // Quiet, not filled: the candle below is the
                        // page's one gold act
                        QuietGoldButton(
                            title: title,
                            trailingIcon: "ph-caret-right",
                            size: 9.5,
                            tracking: 1.6,
                            horizontalPadding: 0
                        ) {
                            router.run(act)
                        }
                        .fixedSize()
                    } else {
                        AppIcon("ph-caret-right", size: 11)
                            .foregroundColor(AppColors.gold.opacity(0.5))
                    }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    if index < CarloAcutisData.rule.count - 1 {
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.12))
                            .frame(height: AppLine.hairline)
                            .padding(.leading, 58)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            shape.fill(
                LinearGradient(
                    colors: [AppColors.cardBackground.opacity(0.9), AppColors.cardBackground.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .overlay(shape.strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
    }

    // MARK: - The Shrine

    /// The candle, lit or waiting, in its own warm light; the line to
    /// write an intention on; the prayer; and his feast and tomb
    private var shrine: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)

        return VStack(spacing: 22) {
            candle
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text(isCandleLit ? "Your candle is lit" : "Light a candle")
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(isCandleLit ? AppColors.goldLight : AppColors.cream)
                    .contentTransition(.opacity)

                Text(isCandleLit ? "St. Carlo Acutis, pray for this intention." : "For an intention of your own. It burns for a day, and stays on your device.")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }

            ZStack {
                if isCandleLit {
                    VStack(spacing: 6) {
                        if !intention.isEmpty {
                            Text("\u{201C}\(intention)\u{201D}")
                                .font(AppFonts.readingItalicFont(17))
                                .foregroundColor(AppColors.cream.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Puts the candle out and gives the line back with
                        // the intention still on it, so to change it is
                        // to put it out, rewrite it, and light it again
                        QuietGoldButton(title: "Put out", size: 9.5, horizontalPadding: 0) {
                            withAnimation(Motion.crossfade) {
                                draftIntention = intention
                                candleLitAt = 0
                            }
                        }
                    }
                    .transition(.opacity)
                } else {
                    VStack(spacing: 16) {
                        VStack(spacing: 6) {
                            TextField(
                                "",
                                text: $draftIntention,
                                prompt: Text("Your intention (optional)")
                                    .font(AppFonts.readingItalicFont(16))
                                    .foregroundColor(AppColors.textSecondary.opacity(0.8)),
                                axis: .vertical
                            )
                            .font(AppFonts.readingFont(16))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.center)
                            .tint(AppColors.gold)
                            .focused($intentionFocused)
                            .lineLimit(1...4)

                            Rectangle()
                                .fill(AppColors.gold.opacity(intentionFocused ? 0.5 : 0.25))
                                .frame(height: AppLine.hairline)
                        }

                        GoldCTAButton(title: "Light the candle", fullWidth: false) {
                            withAnimation(Motion.crossfade) {
                                intention = draftIntention.trimmingCharacters(in: .whitespacesAndNewlines)
                                candleLitAt = Date().timeIntervalSince1970
                            }
                            intentionFocused = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(Motion.crossfade, value: isCandleLit)

            Rectangle()
                .fill(AppColors.gold.opacity(0.18))
                .frame(height: AppLine.hairline)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text("A PRAYER FOR HIS INTERCESSION")
                    .font(AppFonts.labelFont(9))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                PrayerText(
                    content: CarloAcutisData.prayer,
                    size: max(16, settings.meditationFontSize - 3),
                    alignment: .leading
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                AppIcon("ch-church", size: 14)
                    .foregroundColor(AppColors.gold)
                Text("His feast day is \(CarloAcutisData.feast.dateLabel), the day he died. His tomb is in the Sanctuary of the Spoliation, Assisi.")
                    .font(AppFonts.readingItalicFont(13.5))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
        }
        .padding(22)
        .background(
            ZStack {
                shape.fill(AppColors.cardBackground.opacity(0.45))
                shape.fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(isCandleLit ? 0.16 : 0.05), .clear],
                        center: UnitPoint(x: 0.5, y: 0.12),
                        startRadius: 4,
                        endRadius: 260
                    )
                )
            }
        )
        .overlay(shape.strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
    }

    /// A taper with its flame, lit or cold
    private var candle: some View {
        VStack(spacing: 2) {
            ZStack {
                if isCandleLit {
                    Circle()
                        .fill(AppColors.goldLight.opacity(0.25))
                        .frame(width: flameFlicker ? 74 : 60, height: flameFlicker ? 74 : 60)
                        .blur(radius: 14)

                    // A votive candle, not the streak flame — the flame
                    // glyph stays exclusive to prayer streaks
                    AppIcon("ch-candle", size: 36)
                        .scaleEffect(flameFlicker ? 1.06 : 0.95)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.goldLight, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        // Started whenever the flame is drawn — on arriving
                        // at a lit candle, and on lighting one here — and
                        // stilled with it, so a relit candle flickers again
                        .onAppear { flameFlicker = !reduceMotion }
                        .onDisappear { flameFlicker = false }
                } else {
                    AppIcon("ch-candle", size: 34)
                        .foregroundColor(AppColors.textSecondary.opacity(0.4))
                }
            }
            .frame(width: 80, height: 70)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: flameFlicker
            )

            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [AppColors.cream.opacity(0.9), AppColors.cream.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 38, height: 84)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - StCarloIcon

/// A flat vector medallion of St. Carlo Acutis: gold halo, dark hair,
/// and his iconic red polo, drawn entirely in SwiftUI so it tints and
/// scales like the rest of the icon set. Deliberately simple and
/// dignified — an icon, not a caricature.
struct StCarloIcon: View {

    var size: CGFloat = 96

    // Palette
    private let skin = Color(hex: "EAC0A2")
    private let hair = Color(hex: "4A3222")
    private let polo = Color(hex: "A93B32")
    private let poloDark = Color(hex: "8E2F28")

    var body: some View {
        ZStack {
            // Medallion ground
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.cardBackground, AppColors.background],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.6
                    )
                )

            // Halo — behind the head, ahead of the ground
            Circle()
                .strokeBorder(AppColors.goldLight.opacity(0.9), lineWidth: size * 0.025)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(y: -size * 0.16)
                .haloGlow(AppColors.gold, radius: size * 0.05, intensity: 0.5)

            // Shoulders — his red polo
            RoundedRectangle(cornerRadius: size * 0.16)
                .fill(polo)
                .frame(width: size * 0.6, height: size * 0.44)
                .offset(y: size * 0.36)

            // Collar
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(poloDark)
                .frame(width: size * 0.1, height: size * 0.05)
                .rotationEffect(.degrees(24))
                .offset(x: -size * 0.055, y: size * 0.185)
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(poloDark)
                .frame(width: size * 0.1, height: size * 0.05)
                .rotationEffect(.degrees(-24))
                .offset(x: size * 0.055, y: size * 0.185)

            // Neck
            Rectangle()
                .fill(skin)
                .frame(width: size * 0.1, height: size * 0.08)
                .offset(y: size * 0.14)

            // Hair (back) — slightly larger than the face, so a dark
            // rim shows at the crown and temples
            Ellipse()
                .fill(hair)
                .frame(width: size * 0.34, height: size * 0.36)
                .offset(y: -size * 0.14)

            // Face
            Ellipse()
                .fill(skin)
                .frame(width: size * 0.29, height: size * 0.31)
                .offset(y: -size * 0.115)

            // Fringe across the forehead
            Ellipse()
                .fill(hair)
                .frame(width: size * 0.3, height: size * 0.13)
                .offset(y: -size * 0.235)

            // Eyes
            Capsule()
                .fill(hair)
                .frame(width: size * 0.026, height: size * 0.04)
                .offset(x: -size * 0.06, y: -size * 0.12)
            Capsule()
                .fill(hair)
                .frame(width: size * 0.026, height: size * 0.04)
                .offset(x: size * 0.06, y: -size * 0.12)

            // A gentle smile
            SmileShape()
                .stroke(hair, style: StrokeStyle(lineWidth: size * 0.014, lineCap: .round))
                .frame(width: size * 0.09, height: size * 0.036)
                .offset(y: -size * 0.045)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(AppColors.gold.opacity(0.8), lineWidth: 1.5)
        )
        .accessibilityLabel("Icon of St. Carlo Acutis")
    }
}

/// A shallow upward arc used for the smile.
private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height)
        )
        return p
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CarloAcutisView()
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}

#Preview("St. Carlo icon") {
    HStack(spacing: 24) {
        StCarloIcon(size: 64)
        StCarloIcon(size: 96)
        StCarloIcon(size: 128)
    }
    .padding(40)
    .background(AppColors.background)
}
