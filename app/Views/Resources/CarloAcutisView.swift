//
//  CarloAcutisView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  ST. CARLO ACUTIS - DIGITAL ALTAR
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A digital altar for St. Carlo Acutis, the first millennial saint:
//  - His life and witness
//  - His words
//  - A votive candle the user can light with a prayer intention
//    (stored locally via AppStorage)
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI
import UIKit

// MARK: - CarloAcutisView

struct CarloAcutisView: View {

    @Environment(\.dismiss) private var dismiss

    // Votive candle state, persisted locally
    @AppStorage("carloAltar.candleLitAt") private var candleLitAt: Double = 0
    @AppStorage("carloAltar.intention") private var intention: String = ""

    @State private var draftIntention: String = ""
    @State private var flameFlicker: Bool = false
    @FocusState private var intentionFocused: Bool

    /// A candle stays lit for 24 hours
    private var isCandleLit: Bool {
        guard candleLitAt > 0 else { return false }
        let litDate = Date(timeIntervalSince1970: candleLitAt)
        return Date().timeIntervalSince(litDate) < 24 * 60 * 60
    }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .devotionalEntrance()

                    altarSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .devotionalEntrance(delay: 0.08)

                    bioSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .devotionalEntrance(delay: 0.16)

                    devotionsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .devotionalEntrance(delay: 0.24)

                    quotesSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .devotionalEntrance(delay: 0.3)

                    prayerSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                        .devotionalEntrance(delay: 0.36)
                }
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
            flameFlicker = true
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            carloPortrait
                .haloGlow(AppColors.gold, radius: 14, intensity: 0.35)
                .padding(.top, 24)

            Text("St. Carlo Acutis")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)

            Text("1991 – 2006 • The First Millennial Saint")
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.gold.opacity(0.8))

            OrnamentDivider()
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
    }

    /// Prefers the real photograph when a `carlo_acutis` image is present
    /// in the asset catalog, framed in gold like a devotional portrait;
    /// otherwise falls back to the drawn medallion.
    @ViewBuilder
    private var carloPortrait: some View {
        if UIImage(named: "carlo_acutis") != nil {
            Image("carlo_acutis")
                .resizable()
                .scaledToFit()
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.gold.opacity(0.7), lineWidth: 1.5)
                )
                .accessibilityLabel("Photograph of St. Carlo Acutis")
        } else {
            StCarloIcon(size: 100)
        }
    }

    // MARK: - Altar (Votive Candle)

    private var altarSection: some View {
        VStack(spacing: 20) {
            Text("DIGITAL ALTAR")
                .font(AppFonts.bodyFont(12))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            // Candle
            VStack(spacing: 0) {
                // Flame
                ZStack {
                    if isCandleLit {
                        // Glow
                        Circle()
                            .fill(AppColors.goldLight.opacity(0.25))
                            .frame(width: flameFlicker ? 64 : 52, height: flameFlicker ? 64 : 52)
                            .blur(radius: 12)

                        // A votive candle, not the streak flame — the
                        // flame glyph stays exclusive to prayer streaks
                        AppIcon("ch-candle", size: 36)
                            .scaleEffect(flameFlicker ? 1.07 : 0.94)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.goldLight, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .animation(
                                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                                value: flameFlicker
                            )
                    } else {
                        AppIcon("ch-candle", size: 34)
                            .foregroundColor(AppColors.textSecondary.opacity(0.4))
                    }
                }
                .frame(height: 64)

                // Candle body
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.cream.opacity(0.9), AppColors.cream.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, height: 90)
            }

            if isCandleLit {
                VStack(spacing: 8) {
                    Text("Your candle is lit")
                        .font(AppFonts.italicFont(15))
                        .foregroundColor(AppColors.gold)

                    if !intention.isEmpty {
                        Text("\u{201C}\(intention)\u{201D}")
                            .font(AppFonts.bodyFont(14))
                            .foregroundColor(AppColors.cream.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    Text("St. Carlo Acutis, pray for this intention.")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                VStack(spacing: 12) {
                    TextField(
                        "",
                        text: $draftIntention,
                        prompt: Text("Your prayer intention (optional)")
                            .font(AppFonts.bodyFont(14))
                            .foregroundColor(AppColors.textSecondary),
                        axis: .vertical
                    )
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.cream)
                    .focused($intentionFocused)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.background.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 1)
                            )
                    )

                    Button {
                        intention = draftIntention.trimmingCharacters(in: .whitespacesAndNewlines)
                        candleLitAt = Date().timeIntervalSince1970
                        intentionFocused = false
                    } label: {
                        HStack(spacing: 8) {
                            AppIcon("ch-candle", size: 15)
                            Text("Light a Candle")
                                .font(AppFonts.headlineFont(15))
                        }
                        .foregroundColor(AppColors.background)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.gold, AppColors.goldLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }

                    Text("Your candle burns for 24 hours. The intention stays on your device.")
                        .font(AppFonts.bodyFont(11))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Biography

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HIS LIFE")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(alignment: .leading, spacing: 14) {
                bioBlock(
                    title: "An Ordinary Boy",
                    text: "Carlo Acutis was born in London on May 3, 1991, and grew up in Milan, Italy. He loved soccer, video games, and computer programming — an entirely ordinary teenager, with one extraordinary secret: from the day of his First Communion he never missed daily Mass. \u{201C}The Eucharist,\u{201D} he said, \u{201C}is my highway to heaven.\u{201D}"
                )

                bioBlock(
                    title: "God's Programmer",
                    text: "Self-taught in web design, Carlo spent two and a half years building an online exhibition cataloguing the Church's Eucharistic miracles — over one hundred and thirty of them, from Lanciano to Buenos Aires. The exhibition has since traveled to thousands of parishes on five continents. He used his screen time for heaven."
                )

                bioBlock(
                    title: "The Offering",
                    text: "In October 2006, Carlo was diagnosed with acute leukemia. He offered his sufferings for the Pope and for the Church, saying: \u{201C}I am happy to die because I have lived my life without wasting even a minute of it on anything unpleasing to God.\u{201D} He died on October 12, 2006, at fifteen years old, and was buried in Assisi in jeans and sneakers."
                )

                bioBlock(
                    title: "The First Millennial Saint",
                    text: "Carlo was beatified in Assisi on October 10, 2020, and canonized by Pope Leo XIV on September 7, 2025 — the first saint who grew up with the internet. His body rests in the Sanctuary of the Spoliation in Assisi, visible to pilgrims through a glass tomb. His feast day is October 12."
                )
            }
        }
    }

    private func bioBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.headlineFont(16))
                .foregroundColor(AppColors.cream)

            ReadingText(
                text: text,
                size: 16,
                textColor: AppColors.cream.opacity(0.88)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - His Devotions

    private var devotionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HIS DEVOTIONS")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(spacing: 12) {
                devotionCard(
                    icon: "ch-monstrance",
                    title: "Daily Mass & Adoration",
                    text: "From his First Communion at age seven, Carlo never missed daily Mass, and he made time for Eucharistic adoration before or after it. \u{201C}When we face the sun we get a tan,\u{201D} he said, \u{201C}but when we stand before Jesus in the Eucharist we become saints.\u{201D}"
                )

                devotionCard(
                    icon: "ch-rosary",
                    title: "The Daily Rosary",
                    text: "Every day Carlo kept what he called his appointment with Our Lady. He called the Rosary \u{201C}the shortest ladder to climb to heaven\u{201D} — and this app's daily Rosary is a way to climb it with him."
                )

                devotionCard(
                    icon: "ph-hands-praying",
                    title: "Weekly Confession",
                    text: "Carlo went to confession every week. Like a hot-air balloon that rises by dropping small weights, he explained, the soul rises to God by letting go of even venial sins."
                )
            }
        }
    }

    private func devotionCard(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.gold.opacity(0.12))
                    .frame(width: 42, height: 42)
                AppIcon(icon, size: 20)
                    .foregroundColor(AppColors.gold)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.cream)

                Text(text)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.88))
                    .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Quotes

    private let quotes: [String] = [
        "The Eucharist is my highway to heaven.",
        "All people are born as originals, but many die as photocopies.",
        "To always be close to Jesus, that's my life plan.",
        "Our aim has to be the infinite and not the finite. The infinite is our homeland. We have always been expected in Heaven.",
        "Sadness is looking at ourselves; happiness is looking towards God.",
        "The Virgin Mary is the only woman in my life.",
        "The Rosary is the shortest ladder to climb to heaven.",
        "Continuously ask your guardian angel for help. Your guardian angel has to become your best friend."
    ]

    @State private var quoteIndex: Int = 0

    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("IN HIS WORDS")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(spacing: 14) {
                TabView(selection: $quoteIndex) {
                    ForEach(Array(quotes.enumerated()), id: \.offset) { index, quote in
                        VStack(spacing: 12) {
                            Text("\u{275D}")
                                .font(.system(size: 26))
                                .foregroundColor(AppColors.gold.opacity(0.6))

                            Text(quote)
                                .font(AppFonts.readingItalicFont(17))
                                .foregroundColor(AppColors.cream)
                                .multilineTextAlignment(.center)
                                .lineSpacing(7)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 200)
                .background(AppColors.cardBackground.opacity(0.6))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 0.5)
                )
                .overlay(OrnateCornersOverlay(inset: 8, length: 12, opacity: 0.35))

                // Custom gold page dots
                HStack(spacing: 6) {
                    ForEach(0..<quotes.count, id: \.self) { i in
                        Circle()
                            .fill(i == quoteIndex ? AppColors.gold : AppColors.gold.opacity(0.25))
                            .frame(width: 5, height: 5)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: quoteIndex)
            }

            Text("Swipe to read more")
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Prayer

    private var prayerSection: some View {
        VStack(spacing: 16) {
            Text("PRAYER FOR HIS INTERCESSION")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            ReadingText(
                text: """
O God, who gave to the young Carlo Acutis a heart aflame with love for the Holy Eucharist, grant, we pray, that through his intercession we too may seek You above all things, live as originals and not photocopies, and one day share with him the joy of Your kingdom. Through Christ our Lord. Amen.

St. Carlo Acutis, pray for us.
""",
                size: 16,
                textColor: AppColors.cream.opacity(0.92),
                alignment: .center
            )
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
                        )
                )
        }
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
