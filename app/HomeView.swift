//
//  HomeView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Main home screen showing today's mystery and quick access to all mysteries.
//  Structured for future API integration - uses mock data for now.

import SwiftUI

// MARK: - Mock Data Models (Will be replaced by API models)

/// Represents a type of mystery (Joyful, Sorrowful, etc.)
struct MysteryType: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
    let mysteries: [Mystery]
}

/// Represents a single mystery within a type
struct Mystery: Identifiable {
    let id = UUID()
    let ordinal: Int  // 1-5
    let title: String
    let scriptureQuote: String
    let scriptureReference: String
    let imageURL: String?
}

/// Traditional rosary schedule (pre-2002, without Luminous in rotation)
enum DayOfWeek: Int, CaseIterable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var mysteryType: String {
        switch self {
        case .sunday, .wednesday, .saturday : return "glorious"
        case .monday, .thursday: return "joyful"
        case .tuesday, .friday: return "sorrowful"
        }
    }
}

// MARK: - Mock Data

/// Mock data that simulates API response
struct MockData {
    static let mysteryTypes: [MysteryType] = [
        MysteryType(
            name: "Joyful",
            subtitle: "The Incarnation",
            iconName: "star.fill",
            gradientColors: [Color(hex: "3d3522"), Color(hex: "2a2518")],
            mysteries: [
                Mystery(ordinal: 1, title: "The Annunciation", scriptureQuote: "Hail, full of grace, the Lord is with you.", scriptureReference: "Luke 1:28", imageURL: nil),
                Mystery(ordinal: 2, title: "The Visitation", scriptureQuote: "Blessed are you among women, and blessed is the fruit of your womb.", scriptureReference: "Luke 1:42", imageURL: nil),
                Mystery(ordinal: 3, title: "The Nativity", scriptureQuote: "She gave birth to her firstborn son and wrapped him in swaddling clothes.", scriptureReference: "Luke 2:7", imageURL: nil),
                Mystery(ordinal: 4, title: "The Presentation", scriptureQuote: "A light for revelation to the Gentiles, and glory for your people Israel.", scriptureReference: "Luke 2:32", imageURL: nil),
                Mystery(ordinal: 5, title: "Finding Jesus in the Temple", scriptureQuote: "Did you not know that I must be in my Father's house?", scriptureReference: "Luke 2:49", imageURL: nil)
            ]
        ),
        MysteryType(
            name: "Sorrowful",
            subtitle: "The Passion",
            iconName: "cross.fill",
            gradientColors: [Color(hex: "3a2530"), Color(hex: "2a1520")],
            mysteries: [
                Mystery(ordinal: 1, title: "The Agony in the Garden", scriptureQuote: "Father, if you are willing, take this cup from me; yet not my will, but yours be done.", scriptureReference: "Luke 22:42", imageURL: "https://upload.wikimedia.org/wikipedia/commons/6/68/Christ_in_Gethsemane.jpg"),
                Mystery(ordinal: 2, title: "The Scourging at the Pillar", scriptureQuote: "By his wounds we are healed.", scriptureReference: "Isaiah 53:5", imageURL: nil),
                Mystery(ordinal: 3, title: "The Crowning with Thorns", scriptureQuote: "They wove a crown of thorns and placed it on his head.", scriptureReference: "Matthew 27:29", imageURL: nil),
                Mystery(ordinal: 4, title: "The Carrying of the Cross", scriptureQuote: "Whoever wishes to follow me must deny himself, take up his cross, and follow me.", scriptureReference: "Matthew 16:24", imageURL: nil),
                Mystery(ordinal: 5, title: "The Crucifixion", scriptureQuote: "Father, into your hands I commend my spirit.", scriptureReference: "Luke 23:46", imageURL: nil)
            ]
        ),
        MysteryType(
            name: "Glorious",
            subtitle: "The Resurrection",
            iconName: "sunrise.fill",
            gradientColors: [Color(hex: "2a3a4a"), Color(hex: "1a2a3a")],
            mysteries: [
                Mystery(ordinal: 1, title: "The Resurrection", scriptureQuote: "He is not here; he has risen, just as he said.", scriptureReference: "Matthew 28:6", imageURL: nil),
                Mystery(ordinal: 2, title: "The Ascension", scriptureQuote: "He was taken up before their very eyes, and a cloud hid him from their sight.", scriptureReference: "Acts 1:9", imageURL: nil),
                Mystery(ordinal: 3, title: "The Descent of the Holy Spirit", scriptureQuote: "They were all filled with the Holy Spirit.", scriptureReference: "Acts 2:4", imageURL: nil),
                Mystery(ordinal: 4, title: "The Assumption of Mary", scriptureQuote: "Blessed are you among women.", scriptureReference: "Luke 1:42", imageURL: nil),
                Mystery(ordinal: 5, title: "The Coronation of Mary", scriptureQuote: "A great sign appeared in heaven: a woman clothed with the sun.", scriptureReference: "Revelation 12:1", imageURL: nil)
            ]
        ),
        MysteryType(
            name: "Luminous",
            subtitle: "The Light",
            iconName: "light.max",
            gradientColors: [Color(hex: "4a3a2a"), Color(hex: "3a2a1a")],
            mysteries: [
                Mystery(ordinal: 1, title: "The Baptism in the Jordan", scriptureQuote: "This is my beloved Son, with whom I am well pleased.", scriptureReference: "Matthew 3:17", imageURL: nil),
                Mystery(ordinal: 2, title: "The Wedding at Cana", scriptureQuote: "Do whatever he tells you.", scriptureReference: "John 2:5", imageURL: nil),
                Mystery(ordinal: 3, title: "The Proclamation of the Kingdom", scriptureQuote: "Repent, for the kingdom of heaven is at hand.", scriptureReference: "Matthew 4:17", imageURL: nil),
                Mystery(ordinal: 4, title: "The Transfiguration", scriptureQuote: "His face shone like the sun, and his clothes became white as light.", scriptureReference: "Matthew 17:2", imageURL: nil),
                Mystery(ordinal: 5, title: "The Institution of the Eucharist", scriptureQuote: "This is my body, which is given for you.", scriptureReference: "Luke 22:19", imageURL: nil)
            ]
        )
    ]

    /// Daily inspirational quotes (rotates)
    static let quotes: [(text: String, author: String)] = [
        ("The Rosary is the most beautiful and the most rich in graces of all prayers; it is the prayer that touches most the Heart of the Mother of God.", "St. Pius X"),
        ("Give me an army saying the Rosary and I will conquer the world.", "Bl. Pope Pius IX"),
        ("The Rosary is a powerful weapon to put the demons to flight.", "St. Padre Pio"),
        ("Never will anyone who says his Rosary every day be led astray.", "Bl. Alan de la Roche")
    ]
}

// MARK: - HomeView

struct HomeView: View {
    // Navigation callbacks (to be wired up)
    var onBeginPrayer: ((MysteryType, Mystery) -> Void)?
    var onSelectMystery: ((MysteryType) -> Void)?

    // Computed: Today's mystery type based on traditional schedule
    private var todaysMysteryType: MysteryType {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let day = DayOfWeek(rawValue: weekday) ?? .sunday
        let typeName = day.mysteryType

        return MockData.mysteryTypes.first { $0.name.lowercased() == typeName } ?? MockData.mysteryTypes[0]
    }

    // Computed: First mystery of today's set (featured on home)
    private var featuredMystery: Mystery {
        todaysMysteryType.mysteries.first ?? todaysMysteryType.mysteries[0]
    }

    // Computed: Today's quote (rotates by day of year)
    private var todaysQuote: (text: String, author: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % MockData.quotes.count
        return MockData.quotes[index]
    }

    // Computed: Day label (e.g., "WEDNESDAY PRAYER")
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()).uppercased() + " PRAYER"
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HeaderView()

                    // Day label
                    DayPrayerLabel(label: dayLabel)
                        .padding(.top, 16)

                    // Featured mystery card
                    FeaturedMysteryCard(
                        mysteryType: todaysMysteryType,
                        mystery: featuredMystery,
                        onBeginPrayer: {
                            onBeginPrayer?(todaysMysteryType, featuredMystery)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Sacred Mysteries grid
                    SacredMysteriesSection(
                        mysteryTypes: MockData.mysteryTypes,
                        onSelectMystery: { mysteryType in
                            onSelectMystery?(mysteryType)
                        }
                    )
                    .padding(.top, 32)

                    // Quote section
                    QuoteSection(
                        quote: todaysQuote.text,
                        author: todaysQuote.author
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Day Prayer Label

struct DayPrayerLabel: View {
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0), AppColors.gold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text(label)
                .font(AppFonts.bodyFont(12))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .fixedSize()

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.gold.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Featured Mystery Card

struct FeaturedMysteryCard: View {
    let mysteryType: MysteryType
    let mystery: Mystery
    var onBeginPrayer: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with optional image
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "2d3a4a"),
                            Color(hex: "1a2433"),
                            Color(hex: "0f1a26")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 380)
                .overlay(
                    Group {
                        if let imageURL = mystery.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                ProgressView().tint(AppColors.gold)
                            }
                            .clipped()
                        }
                    }
                )

            // Content overlay
            VStack(spacing: 16) {
                // Mystery type badge
                Text("\(mysteryType.name.uppercased()) MYSTERIES")
                    .font(AppFonts.bodyFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.goldLight)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppColors.background.opacity(0.8))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.goldLight.opacity(0.8), lineWidth: 0.5)
                    )

                // Mystery title
                Text(mystery.title)
                    .font(AppFonts.headlineFont(28))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)

                // Scripture quote
                Text("\"\(mystery.scriptureQuote)\"")
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)

                // Begin Prayer button
                Button(action: onBeginPrayer) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))

                        Text("BEGIN PRAYER")
                            .font(AppFonts.bodyFont(14))
                            .tracking(2)
                    }
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.goldLight)
                    .cornerRadius(30)
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        AppColors.background.opacity(0.7),
                        AppColors.background.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Sacred Mysteries Section

struct SacredMysteriesSection: View {
    let mysteryTypes: [MysteryType]
    var onSelectMystery: ((MysteryType) -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Sacred Mysteries")
                    .font(AppFonts.headlineFont(22))
                    .foregroundColor(AppColors.goldLight)

                Spacer()

                Button(action: {}) {
                    Text("VIEW ALL")
                        .font(AppFonts.bodyFont(12))
                        .tracking(1)
                        .foregroundColor(AppColors.gold)
                }
            }
            .padding(.horizontal, 20)

            // 2x2 Grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(mysteryTypes) { mysteryType in
                    MysteryCard(
                        title: mysteryType.name,
                        subtitle: mysteryType.subtitle,
                        imageName: mysteryType.iconName,
                        gradientColors: mysteryType.gradientColors
                    )
                    .onTapGesture {
                        onSelectMystery?(mysteryType)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
