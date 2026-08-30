//
//  MysteriesInScriptureView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  FINDING THE MYSTERIES IN SCRIPTURE
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Shows where each mystery of the Rosary (and the Seven Sorrows) is found
//  in Sacred Scripture, with a key verse for meditation and the traditional
//  fruit (grace) of each mystery. Mystery names, descriptions, and references
//  come from MysteryData; the key verses are provided here (Douay-Rheims).
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - MysteriesInScriptureView

struct MysteriesInScriptureView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: MysteryCategory = .joyful
    @State private var expandedMysteries: Set<Int> = []

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .devotionalEntrance()

                    introduction
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .devotionalEntrance(delay: 0.08)

                    howToUseCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .devotionalEntrance(delay: 0.16)

                    categoryPicker
                        .padding(.bottom, 24)
                        .devotionalEntrance(delay: 0.24)

                    mysteriesList
                        .padding(.horizontal, 20)

                    if selectedCategory == .sevenSorrows {
                        sevenGracesCard
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                    }

                    Spacer()
                        .frame(height: 48)
                }
            }
            .topChromeFade()
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
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            AppIcon("ch-bible", size: 38)
                .foregroundColor(AppColors.gold)
                .breathingGlow(AppColors.gold)
                .padding(.top, 24)

            Text("The Mysteries in Scripture")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text("Praying the Rosary with the Word of God")
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.gold.opacity(0.8))

            OrnamentDivider()
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Introduction

    private var introduction: some View {
        DropCapText(
            text: "Every mystery of the Rosary is drawn from the pages of Sacred Scripture. Reading the passage before praying a decade — even a single verse — anchors the meditation in the Gospel itself. Below you will find where each mystery lives in the Bible, with a key verse to carry into prayer and the traditional fruit — the particular grace — to ask for.",
            bodySize: 15
        )
    }

    // MARK: - How to Use

    private var howToUseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BEFORE EACH DECADE")
                .font(AppFonts.labelFont(10))
                .tracking(3)
                .foregroundColor(AppColors.gold.opacity(0.7))

            howToStep(number: "I", text: "Read the verse slowly — let one word or phrase settle.")
            howToStep(number: "II", text: "Picture the scene, and place yourself within it beside Mary.")
            howToStep(number: "III", text: "Ask for the fruit of the mystery, then begin the decade.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 0.5)
        )
        .overlay(OrnateCornersOverlay(inset: 8, length: 12, opacity: 0.4))
    }

    private func howToStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(AppFonts.titleFont(13))
                .foregroundColor(AppColors.gold)
                .frame(width: 20, alignment: .center)

            Text(text)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .lineSpacing(ReadingTypography.lineSpacing(for: 14))
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MysteryCategory.allCategories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                            expandedMysteries.removeAll()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            AppIcon(category.iconName, size: 13)
                                .foregroundColor(
                                    selectedCategory == category
                                        ? AppColors.background
                                        : AppColors.gold
                                )

                            Text(category.displayName)
                                .font(AppFonts.bodyFont(14))
                                .foregroundColor(
                                    selectedCategory == category
                                        ? AppColors.background
                                        : AppColors.cream
                                )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    selectedCategory == category
                                        ? AppColors.gold
                                        : AppColors.cardBackground
                                )
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(SacredCardButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Mysteries List

    private var mysteriesList: some View {
        VStack(spacing: 14) {
            ForEach(Array(MysteryData.mysteries(for: selectedCategory).enumerated()), id: \.element.id) { index, mystery in
                mysteryCard(mystery)
                    .devotionalEntrance(delay: Double(index) * 0.05, drift: 10)
            }
        }
        .id(selectedCategory)
    }

    private func mysteryCard(_ mystery: Mystery) -> some View {
        let isExpanded = expandedMysteries.contains(mystery.id)
        let key = "\(mystery.category)_\(mystery.order)"

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedMysteries.remove(mystery.id)
                    } else {
                        expandedMysteries.insert(mystery.id)
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(mystery.ordinalName) \(selectedCategory == .sevenSorrows ? "Sorrow" : "Mystery")".uppercased())
                                .font(AppFonts.bodyFont(10))
                                .tracking(2)
                                .foregroundColor(AppColors.gold.opacity(0.7))

                            Text(mystery.name)
                                .font(AppFonts.headlineFont(18))
                                .foregroundColor(AppColors.cream)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        AppIcon("ph-caret-down", size: 13)
                            .foregroundColor(AppColors.gold)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .padding(.top, 4)
                    }

                    HStack(spacing: 8) {
                        // Scripture reference chip
                        if let reference = mystery.scriptureReference {
                            HStack(spacing: 5) {
                                AppIcon("ph-book", size: 10)
                                Text(reference)
                                    .font(AppFonts.bodyFont(11))
                                    .tracking(0.5)
                            }
                            .foregroundColor(AppColors.gold)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(AppColors.gold.opacity(0.1))
                            )
                        }

                        // Fruit chip
                        if let fruit = MysteryData.traditionalFruits[key] {
                            HStack(spacing: 5) {
                                AppIcon("ph-leaf", size: 10)
                                Text(fruit)
                                    .font(AppFonts.bodyFont(11))
                                    .tracking(0.5)
                                    .lineLimit(1)
                            }
                            .foregroundColor(AppColors.cream.opacity(0.8))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(AppColors.cream.opacity(0.06))
                            )
                        }
                    }
                }
                .padding(18)
            }
            .buttonStyle(SacredCardButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    if let description = mystery.description {
                        Text(description)
                            .font(AppFonts.bodyFont(15))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                    }

                    if let verse = Self.keyVerses[key] {
                        Text("\u{201C}\(verse)\u{201D}")
                            .font(AppFonts.readingItalicFont(15))
                            .foregroundColor(AppColors.cream.opacity(0.9))
                            .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                            .padding(.leading, 14)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(AppColors.gold.opacity(0.4))
                                    .frame(width: 2)
                            }
                    }

                    if let fruit = MysteryData.traditionalFruits[key] {
                        Text("Ask for: \(fruit.lowercased())")
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.gold.opacity(0.85))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(isExpanded ? 0.35 : 0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Seven Graces

    /// The seven graces Our Lady promises (through St. Bridget of Sweden)
    /// to those who daily honor her by meditating on her Seven Sorrows.
    private var sevenGracesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AppIcon("ch-sacred-heart", size: 18)
                    .foregroundColor(AppColors.gold)

                Text("The Seven Graces")
                    .font(AppFonts.headlineFont(17))
                    .foregroundColor(AppColors.cream)
            }

            Text("By tradition handed down through St. Bridget of Sweden, Our Lady promises seven graces to souls who honor her daily by meditating on her tears and sorrows:")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(ReadingTypography.lineSpacing(for: 14))

            VStack(alignment: .leading, spacing: 10) {
                graceRow(1, "Peace in their families.")
                graceRow(2, "Enlightenment about the divine mysteries.")
                graceRow(3, "Consolation in their pains, and her companionship in their work.")
                graceRow(4, "Whatever they ask, so long as it accords with God's will and the good of their souls.")
                graceRow(5, "Defense in their spiritual battles and protection at every instant of their lives.")
                graceRow(6, "Visible help at the moment of death — they will see the face of their Mother.")
                graceRow(7, "Her Son's mercy for those who spread this devotion, that they may be brought from this life to eternal happiness.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppColors.cardBackground.opacity(0.7))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5)
        )
        .overlay(OrnateCornersOverlay(inset: 8, length: 12, opacity: 0.4))
    }

    private func graceRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(AppFonts.titleFont(13))
                .foregroundColor(AppColors.gold)
                .frame(width: 16, alignment: .center)

            Text(text)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .lineSpacing(ReadingTypography.lineSpacing(for: 14))
        }
    }

    // MARK: - Key Verses

    /// A short key verse for each mystery, keyed by "<category>_<order>".
    /// Douay-Rheims translation.
    private static let keyVerses: [String: String] = [
        // Joyful
        "joyful_1": "Behold thou shalt conceive in thy womb, and shalt bring forth a son; and thou shalt call his name Jesus. — Luke 1:31",
        "joyful_2": "Blessed art thou among women, and blessed is the fruit of thy womb. — Luke 1:42",
        "joyful_3": "And she brought forth her firstborn son, and wrapped him up in swaddling clothes, and laid him in a manger. — Luke 2:7",
        "joyful_4": "Now thou dost dismiss thy servant, O Lord, according to thy word in peace; because my eyes have seen thy salvation. — Luke 2:29-30",
        "joyful_5": "Did you not know, that I must be about my father's business? — Luke 2:49",

        // Sorrowful
        "sorrowful_1": "My Father, if it be possible, let this chalice pass from me. Nevertheless not as I will, but as thou wilt. — Matthew 26:39",
        "sorrowful_2": "Then therefore, Pilate took Jesus, and scourged him. — John 19:1",
        "sorrowful_3": "And platting a crown of thorns, they put it upon his head. — Matthew 27:29",
        "sorrowful_4": "And bearing his own cross, he went forth to that place which is called Calvary. — John 19:17",
        "sorrowful_5": "Father, into thy hands I commend my spirit. — Luke 23:46",

        // Glorious
        "glorious_1": "He is not here, for he is risen, as he said. — Matthew 28:6",
        "glorious_2": "And the Lord Jesus, after he had spoken to them, was taken up into heaven, and sitteth on the right hand of God. — Mark 16:19",
        "glorious_3": "And they were all filled with the Holy Ghost, and they began to speak with divers tongues. — Acts 2:4",
        "glorious_4": "He that is mighty hath done great things to me; and holy is his name. — Luke 1:49",
        "glorious_5": "And a great sign appeared in heaven: A woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars. — Apocalypse 12:1",

        // Luminous
        "luminous_1": "This is my beloved Son, in whom I am well pleased. — Matthew 3:17",
        "luminous_2": "Whatsoever he shall say to you, do ye. — John 2:5",
        "luminous_3": "The time is accomplished, and the kingdom of God is at hand: repent, and believe the gospel. — Mark 1:15",
        "luminous_4": "And he was transfigured before them. And his face did shine as the sun. — Matthew 17:2",
        "luminous_5": "Take ye, and eat. This is my body. — Matthew 26:26",

        // Seven Sorrows
        "seven_sorrows_1": "And thy own soul a sword shall pierce, that, out of many hearts, thoughts may be revealed. — Luke 2:35",
        "seven_sorrows_2": "Arise, and take the child and his mother, and fly into Egypt. — Matthew 2:13",
        "seven_sorrows_3": "Son, why hast thou done so to us? behold thy father and I have sought thee sorrowing. — Luke 2:48",
        "seven_sorrows_4": "And there followed him a great multitude of people, and of women, who bewailed and lamented him. — Luke 23:27",
        "seven_sorrows_5": "Now there stood by the cross of Jesus, his mother. — John 19:25",
        "seven_sorrows_6": "Joseph of Arimathea... came and took away the body of Jesus. — John 19:38",
        "seven_sorrows_7": "Now there was in the place where he was crucified, a garden; and in the garden a new sepulchre... There, therefore, they laid Jesus. — John 19:41-42"
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MysteriesInScriptureView()
    }
}
