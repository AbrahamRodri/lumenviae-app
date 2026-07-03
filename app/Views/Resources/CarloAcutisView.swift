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

                    altarSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                    bioSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                    quotesSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                    prayerSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
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
            Image(systemName: "laptopcomputer")
                .font(.system(size: 36))
                .foregroundColor(AppColors.gold)
                .padding(.top, 24)

            Text("St. Carlo Acutis")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)

            Text("1991 – 2006 • The First Millennial Saint")
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.gold.opacity(0.8))

            Divider()
                .background(AppColors.gold.opacity(0.3))
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
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

                        Image(systemName: "flame.fill")
                            .font(.system(size: flameFlicker ? 34 : 30))
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
                        Image(systemName: "flame")
                            .font(.system(size: 30))
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
                            Image(systemName: "flame.fill")
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFonts.headlineFont(16))
                .foregroundColor(AppColors.cream)

            Text(text)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - Quotes

    private let quotes: [String] = [
        "The Eucharist is my highway to heaven.",
        "All people are born as originals, but many die as photocopies.",
        "To always be close to Jesus, that's my life plan.",
        "Our aim has to be the infinite and not the finite. The infinite is our homeland. We have always been expected in Heaven.",
        "Sadness is looking at ourselves; happiness is looking towards God.",
        "The Virgin Mary is the only woman in my life."
    ]

    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("IN HIS WORDS")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(spacing: 12) {
                ForEach(quotes, id: \.self) { quote in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\u{275D}")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.gold.opacity(0.6))

                        Text(quote)
                            .font(AppFonts.italicFont(15))
                            .foregroundColor(AppColors.cream.opacity(0.9))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(AppColors.cardBackground.opacity(0.6))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Prayer

    private var prayerSection: some View {
        VStack(spacing: 16) {
            Text("PRAYER FOR HIS INTERCESSION")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            Text("""
O God, who gave to the young Carlo Acutis a heart aflame with love for the Holy Eucharist, grant, we pray, that through his intercession we too may seek You above all things, live as originals and not photocopies, and one day share with him the joy of Your kingdom. Through Christ our Lord. Amen.

St. Carlo Acutis, pray for us.
""")
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        CarloAcutisView()
    }
}
