//
//  MarianLibraryView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  THE MARIAN LIBRARY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A reference library on Our Lady, laid out the way each of its shelves
//  is best browsed rather than as one list:
//
//  - The Marian year leads: the next feast of Our Lady as a feature, in
//    its painting, and the whole year beneath it as a strip of dates —
//    touching a date features that feast.
//  - The four dogmas stand as four numbered tiles in Marian blue.
//  - Mary in Scripture is a thread from Genesis to the Apocalypse.
//  - The apparitions are cards led by their year, swiped through.
//  - The saints are a chronology: each life a bar across nine centuries,
//    so Bernard and Kolbe are seen where they stand in time.
//  - The Rosary's history is a short chronicle in four chapters.
//  - Her titles are set as a litany, and lead to the Litany itself.
//
//  Every entry opens its reading (`LibraryReadingView`). Content lives in
//  `Data/MarianLibraryData.swift`.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - MarianLibraryView

struct MarianLibraryView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    /// The feast shown in the feature — the next one until another date
    /// is touched
    @State private var featured: KeptFeast? = MarianLibraryData.nextFeast()

    /// The year from the next feast onward, wrapping at December
    private let year: [KeptFeast] = MarianLibraryData.feasts.sorted {
        ($0.nextDate() ?? .distantFuture) < ($1.nextDate() ?? .distantFuture)
    }

    private static let marianBlue = Color(hex: "2e3d66")

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    masthead
                        .padding(.horizontal, 24)
                        .devotionalEntrance()

                    if let featured {
                        feastFeature(featured)
                            .padding(.horizontal, 20)
                            .padding(.top, 22)
                            .devotionalEntrance(delay: 0.06)
                    }

                    yearStrip
                        .padding(.top, 16)
                        .devotionalEntrance(delay: 0.1)

                    shelfHeading(MarianLibraryData.dogmas)
                    dogmaGrid

                    shelfHeading(MarianLibraryData.scripture)
                    scriptureThread

                    shelfHeading(MarianLibraryData.apparitions)
                    apparitionCards

                    shelfHeading(MarianLibraryData.saints)
                    saintsChronology

                    shelfHeading(MarianLibraryData.rosary)
                    rosaryChronicle

                    shelfHeading(MarianLibraryData.titles)
                    titlesLitany

                    Color.clear.frame(height: 56)
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

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DE MARIA NUMQUAM SATIS")
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            Text("The Marian Library")
                .font(AppFonts.titleFont(31))
                .foregroundColor(AppColors.cream)
                .minimumScaleFactor(0.7)

            Text("Of Mary, there is never enough. Her feasts, her dogmas, her appearings, and the saints who loved her.")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    // MARK: - The Marian Year

    /// The featured feast, in its painting: its date, its name, how soon,
    /// and its doors — the day's Mass, and the library's reading of it.
    private func feastFeature(_ feast: KeptFeast) -> some View {
        let date = feast.nextDate()
        let isToday = feast.isToday()
        let reading = MarianLibraryData.reading(for: feast)
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return ZStack(alignment: .bottomLeading) {
            CachedAssetImage(MarianLibraryData.painting(for: feast), focal: UnitPoint(x: 0.5, y: 0.3))
                .id(feast.name)
                .transition(.opacity)

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.05), location: 0),
                    .init(color: .black.opacity(0.35), location: 0.45),
                    .init(color: .black.opacity(0.88), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(isToday ? "TODAY · A FEAST OF OUR LADY" : whenLabel(date))
                    .font(AppFonts.labelFont(9))
                    .tracking(2.4)
                    .foregroundColor(AppColors.goldLight)

                Text(feast.name)
                    .font(AppFonts.titleFont(26))
                    .foregroundColor(.white)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(feast.keptBy.map { "\(feast.dateLabel) · kept in \($0)" } ?? feast.dateLabel)
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(.white.opacity(0.8))

                // Side by side where they fit; a reading with a long name
                // ("READ · BEHOLD THY MOTHER") sets them one above the other
                // rather than squeezing either
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        featureActs(feast, date: date, isToday: isToday, reading: reading)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        featureActs(feast, date: date, isToday: isToday, reading: reading)
                    }
                }
                .padding(.top, 6)
            }
            .padding(20)
            .id("text-\(feast.name)")
            .transition(.opacity)
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .clipShape(shape)
        .overlay(shape.strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
        .animation(Motion.crossfade, value: feast.name)
        .accessibilityElement(children: .contain)
    }

    private func whenLabel(_ date: Date?) -> String {
        guard let date else { return "A FEAST OF OUR LADY" }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: date).day ?? 0
        switch days {
        case 1: return "TOMORROW"
        case 2...45: return "IN \(days) DAYS"
        default: return "COMING IN \(Self.month.string(from: date).uppercased())"
        }
    }

    private static let month: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    /// The day's Mass, and the library's reading of the feast — named for
    /// where it leads when the reading stands under another name
    @ViewBuilder
    private func featureActs(_ feast: KeptFeast, date: Date?, isToday: Bool, reading: (id: String, name: String?)?) -> some View {
        if feast.inMissal, let date {
            featureButton(isToday ? "Today's Mass" : "The day's Mass", icon: "ch-altar", filled: true) {
                router.push(.missalDay(date))
            }
        }
        if let reading {
            featureButton(reading.name.map { "Read · \($0)" } ?? "Read", icon: "ph-book-open", filled: false) {
                router.push(.libraryReading(id: reading.id))
            }
        }
    }

    private func featureButton(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                AppIcon(icon, size: 13)
                Text(title.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(1.8)
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundColor(filled ? AppColors.background : AppColors.goldLight)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(
                Capsule().fill(filled ? AppColors.goldLight : Color.black.opacity(0.35))
            )
            .overlay(Capsule().strokeBorder(AppColors.goldLight.opacity(filled ? 0 : 0.6), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
    }

    /// Every feast of Our Lady from the next onward, a date to a tile.
    /// Touching one features it above. The chosen tile is ringed, not
    /// filled: the feature's Mass stands just above it as the page's one
    /// gold act, and two gold fills a few points apart read as two.
    private var yearStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(year, id: \.self) { feast in
                    let chosen = feast == featured

                    Button {
                        withAnimation(Motion.crossfade) { featured = feast }
                    } label: {
                        VStack(spacing: 4) {
                            Text(Self.monthLabel(feast))
                                .font(AppFonts.labelFont(8.5))
                                .tracking(1.6)
                                .foregroundColor(chosen ? AppColors.goldLight : AppColors.gold.opacity(0.8))

                            Text("\(feast.day)")
                                .font(AppFonts.titleFont(28))
                                .foregroundColor(chosen ? AppColors.goldLight : AppColors.cream)

                            // Two lines, a touch smaller before it would
                            // cut a name: "Most Holy Rosary", whole
                            Text(Self.shortName(feast))
                                .font(AppFonts.readingItalicFont(11.5))
                                .foregroundColor(chosen ? AppColors.cream : AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .frame(height: 34, alignment: .top)
                        }
                        .padding(.horizontal, 6)
                        .frame(width: 100, height: 118)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(chosen ? AppColors.gold.opacity(0.12) : AppColors.cardBackground.opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    chosen ? AppColors.goldLight.opacity(0.85) : AppColors.gold.opacity(0.2),
                                    lineWidth: chosen ? 1 : AppLine.hairline
                                )
                        )
                    }
                    .buttonStyle(SacredCardButtonStyle())
                    .accessibilityLabel("\(feast.name), \(feast.dateLabel)")
                    .accessibilityAddTraits(chosen ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private static func monthLabel(_ feast: KeptFeast) -> String {
        let symbols = Calendar.current.shortMonthSymbols
        return symbols.indices.contains(feast.month - 1) ? symbols[feast.month - 1].uppercased() : ""
    }

    /// "The Most Holy Rosary" → "Most Holy Rosary"
    private static func shortName(_ feast: KeptFeast) -> String {
        feast.name.hasPrefix("The ") ? String(feast.name.dropFirst(4)) : feast.name
    }

    // MARK: - Shelf Heading

    private func shelfHeading(_ shelf: ReadingShelf) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                AppIcon(shelf.icon, size: 15)
                    .foregroundColor(AppColors.gold)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold.opacity(0.35), AppColors.gold.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: AppLine.hairline)
            }

            Text(shelf.title)
                .font(AppFonts.titleFont(22))
                .foregroundColor(AppColors.cream)
                .padding(.top, 6)

            Text(shelf.subtitle)
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .padding(.bottom, 18)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - The Dogmas

    /// Four tiles in Marian blue, each led by its numeral
    private var dogmaGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(Array(MarianLibraryData.dogmas.entries.enumerated()), id: \.element.id) { index, entry in
                Button {
                    router.push(.libraryReading(id: entry.id))
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(ReadingShelf.numeral(index + 1))
                            .font(AppFonts.titleFont(34))
                            .foregroundColor(AppColors.goldLight)

                        Spacer(minLength: 8)

                        Text(entry.title)
                            .font(AppFonts.titleFont(16))
                            .foregroundColor(AppColors.cream)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(Self.dogmaDate(entry))
                            .font(AppFonts.readingItalicFont(12.5))
                            .foregroundColor(AppColors.cream.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 134, alignment: .topLeading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Self.marianBlue, Self.marianBlue.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("\(entry.title). \(entry.detail)")
            }
        }
        .padding(.horizontal, 20)
    }

    /// "Theotokos · Council of Ephesus, A.D. 431" → "Council of Ephesus, A.D. 431"
    private static func dogmaDate(_ entry: LibraryReading) -> String {
        entry.detail.components(separatedBy: " · ").last ?? entry.detail
    }

    // MARK: - Mary in Scripture

    /// A thread down the page from Genesis to the Apocalypse, each
    /// reading a knot on it under its citation
    private var scriptureThread: some View {
        let entries = MarianLibraryData.scripture.entries

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                Button {
                    router.push(.libraryReading(id: entry.id))
                } label: {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(entry.detail.uppercased())
                                .font(AppFonts.labelFont(8.5))
                                .tracking(1.6)
                                .foregroundColor(AppColors.gold.opacity(0.85))

                            HStack(alignment: .firstTextBaseline) {
                                Text(entry.title)
                                    .font(AppFonts.readingFont(18))
                                    .foregroundColor(AppColors.cream)

                                Spacer(minLength: 8)

                                AppIcon("ph-caret-right", size: 10)
                                    .foregroundColor(AppColors.gold.opacity(0.5))
                            }

                            if let quote = entry.quote {
                                Text(quote.text)
                                    .font(AppFonts.readingItalicFont(14.5))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineSpacing(3)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.bottom, 26)

                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 28)
                    .background(alignment: .topLeading) {
                        ZStack(alignment: .top) {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.3))
                                .frame(width: 1)
                                .padding(.top, index == 0 ? 6 : 0)
                                .frame(maxHeight: index == entries.count - 1 ? 6 : .infinity, alignment: .top)

                            Circle()
                                .fill(AppColors.background)
                                .overlay(Circle().strokeBorder(AppColors.goldLight, lineWidth: 1.2))
                                .frame(width: 11, height: 11)
                        }
                        .frame(width: 11)
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - The Apparitions

    /// Cards led by their year, swiped through in the order Heaven came
    private var apparitionCards: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MarianLibraryData.apparitions.entries) { entry in
                        apparitionCard(entry)
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)

            if let footnote = MarianLibraryData.apparitions.footnote {
                Text(footnote)
                    .font(AppFonts.readingItalicFont(13))
                    .foregroundColor(AppColors.gold.opacity(0.6))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }
        }
    }

    private func apparitionCard(_ entry: LibraryReading) -> some View {
        let place = Self.placeAndYear(entry.detail)
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return Button {
            router.push(.libraryReading(id: entry.id))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(place.year)
                    .font(AppFonts.titleFont(place.year.count > 4 ? 26 : 38))
                    .foregroundColor(AppColors.goldLight)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(place.place.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .padding(.top, 2)

                Spacer(minLength: 12)

                Text(entry.title)
                    .font(AppFonts.titleFont(17))
                    .foregroundColor(AppColors.cream)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let witness = place.witness {
                    Text(witness)
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            .frame(width: 176, height: 184, alignment: .topLeading)
            .padding(18)
            .background(
                shape.fill(
                    LinearGradient(
                        colors: [AppColors.cardBackground, AppColors.cardBackground.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .overlay(shape.strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline))
            .contentShape(shape)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("\(entry.title), \(entry.detail)")
    }

    /// "France, 1858 · St. Bernadette Soubirous" → ("France", "1858", "St. Bernadette Soubirous")
    private static func placeAndYear(_ detail: String) -> (place: String, year: String, witness: String?) {
        let parts = detail.components(separatedBy: " · ")
        let head = parts[0].components(separatedBy: ", ")
        let year = head.count > 1 ? head.last ?? "" : ""
        let place = head.count > 1 ? head.dropLast().joined(separator: ", ") : head[0]
        return (place, year, parts.count > 1 ? parts[1] : nil)
    }

    // MARK: - The Saints

    /// Each saint's life as a bar across the centuries, so the whole
    /// tradition is seen at once and each in its place
    private var saintsChronology: some View {
        let lower = 1050.0
        let upper = 2030.0

        return VStack(alignment: .leading, spacing: 0) {
            // The century rule
            GeometryReader { geometry in
                ForEach([1100, 1300, 1500, 1700, 1900], id: \.self) { century in
                    let x = (Double(century) - lower) / (upper - lower) * geometry.size.width

                    Text(verbatim: "\(century)")
                        .font(AppFonts.labelFont(8))
                        .foregroundColor(AppColors.textSecondary.opacity(0.7))
                        .position(x: x, y: 6)
                }
            }
            .frame(height: 14)
            .padding(.bottom, 8)

            ForEach(MarianLibraryData.saints.entries) { entry in
                let span = Self.lifespan(entry.detail)

                Button {
                    router.push(.libraryReading(id: entry.id))
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(entry.title)
                                .font(AppFonts.readingFont(17))
                                .foregroundColor(AppColors.cream)

                            Spacer(minLength: 8)

                            AppIcon("ph-caret-right", size: 10)
                                .foregroundColor(AppColors.gold.opacity(0.5))
                        }

                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let start = (span.start - lower) / (upper - lower) * width
                            let end = (span.end - lower) / (upper - lower) * width

                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(AppColors.gold.opacity(0.14))
                                    .frame(height: AppLine.hairline)

                                Capsule()
                                    .fill(AppColors.goldGradient)
                                    .frame(width: max(6, end - start), height: 5)
                                    .offset(x: start)
                            }
                            .frame(height: 8)
                        }
                        .frame(height: 8)

                        Text(entry.detail)
                            .font(AppFonts.readingItalicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, 24)
    }

    /// "1090–1153 · Doctor of the Church" → (1090, 1153)
    private static func lifespan(_ detail: String) -> (start: Double, end: Double) {
        let years = detail.components(separatedBy: " · ")[0]
            .components(separatedBy: CharacterSet(charactersIn: "\u{2013}-"))
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard years.count == 2 else { return (1900, 2000) }
        return (years[0], years[1])
    }

    // MARK: - The Rosary Through History

    private var rosaryChronicle: some View {
        let entries = MarianLibraryData.rosary.entries

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                Button {
                    router.push(.libraryReading(id: entry.id))
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text(ReadingShelf.numeral(index + 1))
                            .font(AppFonts.titleFont(20))
                            .foregroundColor(AppColors.gold)
                            .frame(width: 34, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title)
                                .font(AppFonts.readingFont(17))
                                .foregroundColor(AppColors.cream)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(entry.detail)
                                .font(AppFonts.readingItalicFont(13))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer(minLength: 8)

                        AppIcon("ph-caret-right", size: 10)
                            .foregroundColor(AppColors.gold.opacity(0.5))
                    }
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                    .overlay(alignment: .bottom) {
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.14))
                                .frame(height: AppLine.hairline)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Her Titles

    /// Set as a litany is set: the Latin title, the English beneath, one
    /// to a line, down the middle of the page — and then the Litany.
    private var titlesLitany: some View {
        VStack(spacing: 22) {
            ForEach(MarianLibraryData.titles.entries) { entry in
                Button {
                    router.push(.libraryReading(id: entry.id))
                } label: {
                    VStack(spacing: 5) {
                        Text(entry.detail.components(separatedBy: " · ")[0])
                            .font(AppFonts.readingItalicFont(21))
                            .foregroundColor(AppColors.goldLight)

                        // The English title carries the row's quiet caret,
                        // centred with it, so the litany still reads as a
                        // litany and each line as a door
                        HStack(spacing: 6) {
                            Text(entry.title.uppercased())
                                .font(AppFonts.labelFont(9.5))
                                .tracking(2.4)
                                .foregroundColor(AppColors.cream.opacity(0.8))

                            AppIcon("ph-caret-right", size: 8)
                                .foregroundColor(AppColors.gold.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }

            Text("\u{2726}")
                .font(.system(size: 10))
                .foregroundColor(AppColors.gold.opacity(0.6))

            VStack(spacing: 10) {
                prayerDoor("Pray the Litany of Loreto", id: "litany_loreto")
                HStack(spacing: 10) {
                    prayerDoor("Ave Maris Stella", id: "ave_maris_stella")
                    prayerDoor("The Magnificat", id: "magnificat")
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func prayerDoor(_ title: String, id: String) -> some View {
        Button {
            router.push(.devotionPrayer(id: id))
        } label: {
            HStack(spacing: 8) {
                AppIcon("ph-hands-praying", size: 13)
                Text(title.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(1.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(AppColors.goldLight)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.45), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
    }
}

// MARK: - LedgerDoorRow

/// One row of the library's ledger: a name in the reading face, its
/// italic line beneath, and a caret — a door to a page.
struct LedgerDoorRow: View {
    let title: String
    let note: String?
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                if let icon {
                    AppIcon(icon, size: 16)
                        .foregroundColor(AppColors.gold.opacity(0.85))
                        .frame(width: 20)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)

                    if let note, !note.isEmpty {
                        Text(note)
                            .font(AppFonts.readingItalicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 11)
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MarianLibraryView()
            .environment(AppRouter())
    }
}
