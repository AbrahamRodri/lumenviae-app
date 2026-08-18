//
//  HowToPrayRosaryView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  HOW TO PRAY THE ROSARY - BEGINNER'S GUIDE
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A step-by-step guide to praying the Rosary, with the full text of each
//  prayer in expandable cards. Reached from the menu.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - HowToPrayRosaryView

struct HowToPrayRosaryView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings
    @State private var expandedPrayers: Set<String> = []

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
                        .padding(.bottom, 28)
                        .devotionalEntrance(delay: 0.08)

                    stepsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .devotionalEntrance(delay: 0.16)

                    prayersSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 44)
                        .devotionalEntrance(delay: 0.24)

                    montfortSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                        .devotionalEntrance(delay: 0.3)
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
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            AppIcon("ch-rosary", size: 38)
                .foregroundColor(AppColors.gold)
                .breathingGlow(AppColors.gold)
                .padding(.top, 24)

            Text("How to Pray the Rosary")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text("A Step-by-Step Guide")
                .font(AppFonts.italicFont(16))
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
            text: "The Rosary is a Scripture-based prayer in which we meditate on the great mysteries of the life of Jesus and Mary while praying familiar vocal prayers. The repetition is not the point — it is the quiet rhythm that frees the heart to contemplate. It is the whole Gospel in miniature: with Mary, we look upon the face of Christ.",
            bodySize: 15
        )
    }

    // MARK: - Steps

    private struct RosaryStep: Identifiable {
        let id: Int
        let title: String
        let detail: String
    }

    private let steps: [RosaryStep] = [
        RosaryStep(id: 1, title: "Make the Sign of the Cross", detail: "Holding the crucifix, begin: In the name of the Father, and of the Son, and of the Holy Spirit. Amen."),
        RosaryStep(id: 2, title: "Pray the Apostles' Creed", detail: "Still holding the crucifix, profess the faith of the Church."),
        RosaryStep(id: 3, title: "Pray one Our Father", detail: "On the first large bead."),
        RosaryStep(id: 4, title: "Pray three Hail Marys", detail: "On the three small beads — traditionally offered for an increase in faith, hope, and charity."),
        RosaryStep(id: 5, title: "Pray the Glory Be", detail: "On the next large bead."),
        RosaryStep(id: 6, title: "Announce the first mystery", detail: "Name the mystery (e.g., \"The First Joyful Mystery: The Annunciation\"), pause to picture the scene, then pray one Our Father."),
        RosaryStep(id: 7, title: "Pray ten Hail Marys", detail: "On the ten small beads of the decade, while meditating on the mystery. Let the scene stay before your mind's eye."),
        RosaryStep(id: 8, title: "Close the decade", detail: "Pray the Glory Be, then the Fatima Prayer (\"O my Jesus...\"), recommended by Our Lady at Fatima."),
        RosaryStep(id: 9, title: "Repeat for all five mysteries", detail: "Announce each new mystery, then pray the Our Father, ten Hail Marys, Glory Be, and Fatima Prayer."),
        RosaryStep(id: 10, title: "Conclude", detail: "Pray the Hail, Holy Queen and the closing prayer, then finish with the Sign of the Cross.")
    ]

    /// Which step is currently highlighted on the strand (tap to move).
    @State private var activeStep: Int = 1

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THE STEPS")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(spacing: 0) {
                ForEach(steps) { step in
                    stepRow(step)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
            )

            Text("Tap a step to follow along as you learn — the strand keeps your place.")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    /// One step on the strand: a bead joined to its neighbors by a fine
    /// gold chain. Beads already prayed glow; the active bead breathes.
    private func stepRow(_ step: RosaryStep) -> some View {
        let isActive = step.id == activeStep
        let isDone = step.id < activeStep

        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                activeStep = step.id
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                // Bead (the connecting chain is drawn as the row background)
                ZStack {
                    if isDone {
                        Circle()
                            .fill(AppColors.goldGradient)
                            .frame(width: 26, height: 26)
                            .shadow(color: AppColors.gold.opacity(0.5), radius: 3)
                    } else {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle()
                                    .fill(isActive ? AppColors.gold.opacity(0.25) : .clear)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isActive ? AppColors.goldLight : AppColors.gold.opacity(0.5),
                                        lineWidth: isActive ? 1.5 : 1
                                    )
                            )
                    }

                    Text("\(step.id)")
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(isDone ? AppColors.background : AppColors.gold)
                }
                .breathingGlow(
                    AppColors.gold,
                    radius: isActive ? 8 : 0,
                    dimOpacity: isActive ? 0.3 : 0,
                    brightOpacity: isActive ? 0.7 : 0
                )
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 5) {
                    Text(step.title)
                        .font(AppFonts.headlineFont(15))
                        .foregroundColor(isActive ? AppColors.gold : AppColors.cream)

                    Text(step.detail)
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(ReadingTypography.lineSpacing(for: 14))
                }
                .padding(.vertical, 10)

                Spacer(minLength: 0)
            }
            .background(alignment: .topLeading) {
                // The chain: a fine gold line running through the bead
                // centers (bead center sits 21pt below the row top).
                Rectangle()
                    .fill(AppColors.gold.opacity(0.25))
                    .frame(width: 1)
                    .frame(maxHeight: step.id == steps.count ? 21 : .infinity)
                    .padding(.leading, 12.5)
                    .padding(.top, step.id == 1 ? 21 : 0)
            }
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    // MARK: - Prayers

    private struct RosaryPrayer: Identifiable {
        let id: String
        let title: String
        let latinTitle: String
        let content: BilingualText
    }

    private let prayers: [RosaryPrayer] = [
        RosaryPrayer(
            id: "sign_of_cross",
            title: "The Sign of the Cross",
            latinTitle: "Signum Crucis",
            content: BilingualText(
                english: "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
                latin: "In nomine Patris, et Filii, et Spiritus Sancti. Amen."
            )
        ),
        RosaryPrayer(
            id: "apostles_creed",
            title: "The Apostles' Creed",
            latinTitle: "Symbolum Apostolorum",
            content: BilingualText(
                english: """
I believe in God, the Father almighty, Creator of heaven and earth,
and in Jesus Christ, His only Son, our Lord,
who was conceived by the Holy Spirit, born of the Virgin Mary,
suffered under Pontius Pilate, was crucified, died and was buried;
He descended into hell;
on the third day He rose again from the dead;
He ascended into heaven, and is seated at the right hand of God the Father almighty;
from there He will come to judge the living and the dead.
I believe in the Holy Spirit,
the holy catholic Church, the communion of saints,
the forgiveness of sins, the resurrection of the body,
and life everlasting. Amen.
""",
                latin: """
Credo in Deum Patrem omnipotentem, Creatorem caeli et terrae,
et in Iesum Christum, Filium eius unicum, Dominum nostrum,
qui conceptus est de Spiritu Sancto, natus ex Maria Virgine,
passus sub Pontio Pilato, crucifixus, mortuus, et sepultus;
descendit ad inferos;
tertia die resurrexit a mortuis;
ascendit ad caelos, sedet ad dexteram Dei Patris omnipotentis;
inde venturus est iudicare vivos et mortuos.
Credo in Spiritum Sanctum,
sanctam Ecclesiam catholicam, sanctorum communionem,
remissionem peccatorum, carnis resurrectionem,
vitam aeternam. Amen.
"""
            )
        ),
        RosaryPrayer(
            id: "our_father",
            title: "The Our Father",
            latinTitle: "Pater Noster",
            content: BilingualText(
                english: """
Our Father, who art in heaven,
hallowed be Thy name;
Thy kingdom come;
Thy will be done on earth as it is in heaven.
Give us this day our daily bread;
and forgive us our trespasses
as we forgive those who trespass against us;
and lead us not into temptation,
but deliver us from evil. Amen.
""",
                latin: """
Pater noster, qui es in caelis,
sanctificetur nomen tuum;
adveniat regnum tuum;
fiat voluntas tua, sicut in caelo et in terra.
Panem nostrum quotidianum da nobis hodie;
et dimitte nobis debita nostra,
sicut et nos dimittimus debitoribus nostris;
et ne nos inducas in tentationem,
sed libera nos a malo. Amen.
"""
            )
        ),
        RosaryPrayer(
            id: "hail_mary",
            title: "The Hail Mary",
            latinTitle: "Ave Maria",
            content: BilingualText(
                english: """
Hail Mary, full of grace, the Lord is with thee;
blessed art thou among women,
and blessed is the fruit of thy womb, Jesus.
Holy Mary, Mother of God,
pray for us sinners,
now and at the hour of our death. Amen.
""",
                latin: """
Ave Maria, gratia plena, Dominus tecum;
benedicta tu in mulieribus,
et benedictus fructus ventris tui, Iesus.
Sancta Maria, Mater Dei,
ora pro nobis peccatoribus,
nunc et in hora mortis nostrae. Amen.
"""
            )
        ),
        RosaryPrayer(
            id: "glory_be",
            title: "The Glory Be",
            latinTitle: "Gloria Patri",
            content: BilingualText(
                english: """
Glory be to the Father, and to the Son, and to the Holy Spirit.
As it was in the beginning, is now, and ever shall be,
world without end. Amen.
""",
                latin: """
Gloria Patri, et Filio, et Spiritui Sancto.
Sicut erat in principio, et nunc, et semper,
et in saecula saeculorum. Amen.
"""
            )
        ),
        RosaryPrayer(
            id: "fatima_prayer",
            title: "The Fatima Prayer",
            latinTitle: "Oratio Fatimae",
            content: BilingualText(
                english: """
O my Jesus, forgive us our sins,
save us from the fires of hell,
and lead all souls to heaven,
especially those in most need of Thy mercy. Amen.
""",
                latin: """
Domine Iesu, dimitte nobis debita nostra,
salva nos ab igne inferiori,
perduc in caelum omnes animas,
praesertim eas, quae misericordiae tuae maxime indigent. Amen.
"""
            )
        ),
        RosaryPrayer(
            id: "hail_holy_queen",
            title: "Hail, Holy Queen",
            latinTitle: "Salve Regina",
            content: BilingualText(
                english: """
Hail, holy Queen, Mother of mercy,
our life, our sweetness and our hope.
To thee do we cry, poor banished children of Eve.
To thee do we send up our sighs,
mourning and weeping in this valley of tears.
Turn, then, most gracious advocate,
thine eyes of mercy toward us,
and after this, our exile, show unto us the blessed fruit of thy womb, Jesus.
O clement, O loving, O sweet Virgin Mary.
Pray for us, O holy Mother of God,
that we may be made worthy of the promises of Christ.
""",
                latin: """
Salve, Regina, Mater misericordiae,
vita, dulcedo, et spes nostra, salve.
Ad te clamamus, exsules filii Hevae.
Ad te suspiramus,
gementes et flentes in hac lacrimarum valle.
Eia ergo, advocata nostra,
illos tuos misericordes oculos ad nos converte,
et Iesum, benedictum fructum ventris tui, nobis post hoc exsilium ostende.
O clemens, O pia, O dulcis Virgo Maria.
Ora pro nobis, sancta Dei Genetrix,
ut digni efficiamur promissionibus Christi.
"""
            )
        ),
        RosaryPrayer(
            id: "closing_prayer",
            title: "Closing Prayer",
            latinTitle: "Oratio",
            content: BilingualText(
                english: """
Let us pray.
O God, whose only-begotten Son,
by His life, death and resurrection,
has purchased for us the rewards of eternal life;
grant, we beseech Thee,
that meditating upon these mysteries of the most holy Rosary of the Blessed Virgin Mary,
we may imitate what they contain
and obtain what they promise,
through the same Christ our Lord. Amen.
""",
                latin: """
Oremus.
Deus, cuius Unigenitus
per vitam, mortem et resurrectionem suam
nobis salutis aeternae praemia comparavit;
concede, quaesumus,
ut haec mysteria sacratissimo beatae Mariae Virginis Rosario recolentes,
et imitemur quod continent,
et quod promittunt assequamur.
Per eundem Christum Dominum nostrum. Amen.
"""
            )
        )
    ]

    private var prayersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THE PRAYERS")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(spacing: 12) {
                ForEach(prayers) { prayer in
                    prayerCard(prayer)
                }
            }
        }
    }

    private func prayerCard(_ prayer: RosaryPrayer) -> some View {
        let isExpanded = expandedPrayers.contains(prayer.id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedPrayers.remove(prayer.id)
                    } else {
                        expandedPrayers.insert(prayer.id)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prayer.title)
                            .font(AppFonts.headlineFont(16))
                            .foregroundColor(AppColors.cream)

                        Text(prayer.latinTitle)
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.gold.opacity(0.7))
                    }

                    Spacer()

                    AppIcon("ph-caret-down", size: 13)
                        .foregroundColor(AppColors.gold)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }

            if isExpanded {
                prayerContent(prayer)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(isExpanded ? 0.35 : 0.15), lineWidth: 0.5)
        )
    }

    /// Renders the prayer body in the user's preferred prayer language
    /// through the shared prayer typography — verse lines, stanza air,
    /// and the second language in quiet italic beneath its line.
    private func prayerContent(_ prayer: RosaryPrayer) -> some View {
        PrayerText(
            content: prayer.content.formatted(for: settings.prayerLanguage),
            size: 16
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The Montfort Methods

    @State private var expandedMethods: Set<String> = []

    /// A petition (or Hail Mary clause) tied to one mystery.
    private struct MontfortLine: Identifiable {
        var id: String { mystery }
        let mystery: String
        let text: String
    }

    private struct MontfortGroup: Identifiable {
        var id: String { title }
        let title: String
        let lines: [MontfortLine]
    }

    /// The graces St. Louis asks for in his first method — one per decade.
    private static let montfortPetitions: [MontfortGroup] = [
        MontfortGroup(title: "JOYFUL", lines: [
            MontfortLine(mystery: "The Annunciation", text: "a profound humility"),
            MontfortLine(mystery: "The Visitation", text: "charity towards our neighbor"),
            MontfortLine(mystery: "The Nativity", text: "detachment from the things of the world and love of poverty"),
            MontfortLine(mystery: "The Presentation", text: "purity of body and soul"),
            MontfortLine(mystery: "The Finding in the Temple", text: "true wisdom")
        ]),
        MontfortGroup(title: "SORROWFUL", lines: [
            MontfortLine(mystery: "The Agony in the Garden", text: "contrition for our sins"),
            MontfortLine(mystery: "The Scourging", text: "mortification of our senses"),
            MontfortLine(mystery: "The Crowning with Thorns", text: "contempt of the world"),
            MontfortLine(mystery: "The Carrying of the Cross", text: "patience in bearing our crosses"),
            MontfortLine(mystery: "The Crucifixion", text: "horror of sin, love of the Cross, and the grace of a holy death")
        ]),
        MontfortGroup(title: "GLORIOUS", lines: [
            MontfortLine(mystery: "The Resurrection", text: "a lively faith"),
            MontfortLine(mystery: "The Ascension", text: "a firm hope and a longing for heaven"),
            MontfortLine(mystery: "The Descent of the Holy Spirit", text: "the coming of the Holy Spirit into our souls"),
            MontfortLine(mystery: "The Assumption", text: "a tender devotion to Mary"),
            MontfortLine(mystery: "The Coronation", text: "perseverance in grace and a crown of glory")
        ])
    ]

    /// The clauses of Montfort's shorter method — a word recalling the
    /// mystery, spoken within each Hail Mary after the name of Jesus.
    private static let montfortClauses: [MontfortGroup] = [
        MontfortGroup(title: "JOYFUL", lines: [
            MontfortLine(mystery: "The Annunciation", text: "Jesus becoming man"),
            MontfortLine(mystery: "The Visitation", text: "Jesus sanctifying"),
            MontfortLine(mystery: "The Nativity", text: "Jesus born in poverty"),
            MontfortLine(mystery: "The Presentation", text: "Jesus sacrificed"),
            MontfortLine(mystery: "The Finding in the Temple", text: "Jesus holy of holies")
        ]),
        MontfortGroup(title: "SORROWFUL", lines: [
            MontfortLine(mystery: "The Agony in the Garden", text: "Jesus in His agony"),
            MontfortLine(mystery: "The Scourging", text: "Jesus scourged"),
            MontfortLine(mystery: "The Crowning with Thorns", text: "Jesus crowned with thorns"),
            MontfortLine(mystery: "The Carrying of the Cross", text: "Jesus carrying His cross"),
            MontfortLine(mystery: "The Crucifixion", text: "Jesus crucified")
        ]),
        MontfortGroup(title: "GLORIOUS", lines: [
            MontfortLine(mystery: "The Resurrection", text: "Jesus risen from the dead"),
            MontfortLine(mystery: "The Ascension", text: "Jesus ascending to heaven"),
            MontfortLine(mystery: "The Descent of the Holy Spirit", text: "Jesus filling thee with the Holy Spirit"),
            MontfortLine(mystery: "The Assumption", text: "Jesus raising thee up"),
            MontfortLine(mystery: "The Coronation", text: "Jesus crowning thee")
        ])
    ]

    private var montfortSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("THE MONTFORT METHODS")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            Text("St. Louis de Montfort, the great apostle of the Rosary, left several methods for praying it more fruitfully. Each uses the same beads and prayers — what changes is how deeply the mystery enters each prayer. He composed them for the fifteen traditional mysteries; the same spirit extends naturally to the Luminous Mysteries.")
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .lineSpacing(ReadingTypography.lineSpacing(for: 15))

            VStack(spacing: 14) {
                methodCard(
                    id: "offering",
                    title: "Offer Each Decade",
                    subtitle: "His first method",
                    intro: "Before each decade, offer it to Jesus in honor of the mystery and ask, through Mary, for its particular grace. For example, before the first Joyful Mystery:",
                    example: "\u{201C}We offer Thee, O Lord Jesus, this first decade in honour of Thy Incarnation, and we ask of Thee, through this mystery and through the intercession of Thy most holy Mother, a profound humility. Amen.\u{201D}",
                    outro: "And after the decade: \u{201C}May the grace of the mystery of the Incarnation come down into our souls. Amen.\u{201D} The grace to ask for in each decade:",
                    groups: Self.montfortPetitions,
                    lineStyle: .petition
                )

                methodCard(
                    id: "clauses",
                    title: "A Word Within Each Hail Mary",
                    subtitle: "His shorter method",
                    intro: "Keep the mystery present by adding a brief clause after the name of Jesus in every Hail Mary of the decade:",
                    example: "\u{201C}...and blessed is the fruit of thy womb, Jesus — becoming man. Holy Mary, Mother of God...\u{201D}",
                    outro: "The clause for each mystery:",
                    groups: Self.montfortClauses,
                    lineStyle: .clause
                )

                sayingItWellCard
            }
        }
    }

    private enum MontfortLineStyle {
        case petition
        case clause
    }

    /// One mystery and its grace set as a single running line —
    /// "The Annunciation — a profound humility" — so long names wrap
    /// naturally instead of stacking inside a cramped fixed column.
    private func petitionLine(_ line: MontfortLine, style: MontfortLineStyle) -> some View {
        let grace = style == .clause
            ? Text("\u{201C}\(line.text)\u{201D}").font(AppFonts.italicFont(14))
            : Text(line.text).font(AppFonts.bodyFont(14))

        return (
            Text(line.mystery)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
            + Text(" — ")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.gold.opacity(0.6))
            + grace
                .foregroundColor(AppColors.cream.opacity(0.92))
        )
        .lineSpacing(ReadingTypography.lineSpacing(for: 14))
        .fixedSize(horizontal: false, vertical: true)
    }

    private func methodCard(
        id: String,
        title: String,
        subtitle: String,
        intro: String,
        example: String,
        outro: String,
        groups: [MontfortGroup],
        lineStyle: MontfortLineStyle
    ) -> some View {
        let isExpanded = expandedMethods.contains(id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedMethods.remove(id)
                    } else {
                        expandedMethods.insert(id)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppFonts.headlineFont(16))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.leading)

                        Text(subtitle)
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.gold.opacity(0.7))
                    }

                    Spacer()

                    AppIcon("ph-caret-down", size: 13)
                        .foregroundColor(AppColors.gold)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(SacredCardButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Text(intro)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .lineSpacing(ReadingTypography.lineSpacing(for: 15))

                    Text(example)
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.gold.opacity(0.9))
                        .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                        .padding(.leading, 14)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.4))
                                .frame(width: 2)
                        }

                    Text(outro)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .lineSpacing(ReadingTypography.lineSpacing(for: 15))

                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.title)
                                .font(AppFonts.labelFont(10))
                                .tracking(2)
                                .foregroundColor(AppColors.gold.opacity(0.7))
                                .padding(.top, 6)

                            ForEach(group.lines) { line in
                                petitionLine(line, style: lineStyle)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(isExpanded ? 0.35 : 0.15), lineWidth: 0.5)
        )
    }

    private var sayingItWellCard: some View {
        let id = "well"
        let isExpanded = expandedMethods.contains(id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedMethods.remove(id)
                    } else {
                        expandedMethods.insert(id)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saying It Well")
                            .font(AppFonts.headlineFont(16))
                            .foregroundColor(AppColors.cream)

                        Text("From The Secret of the Rosary")
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.gold.opacity(0.7))
                    }

                    Spacer()

                    AppIcon("ph-caret-down", size: 13)
                        .foregroundColor(AppColors.gold)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(SacredCardButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Text("\u{201C}The Rosary without meditation on the sacred mysteries of our salvation would almost be a body without a soul.\u{201D}")
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.gold.opacity(0.9))
                        .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                        .padding(.leading, 14)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(AppColors.gold.opacity(0.4))
                                .frame(width: 2)
                        }

                    montfortCounsel(
                        title: "Begin with purity of intention",
                        text: "Offer the Rosary for a definite grace or intention, in union with Jesus praying in you."
                    )
                    montfortCounsel(
                        title: "Picture the scene",
                        text: "Before each decade, pause and place the mystery before your mind's eye — the stable, the garden, the empty tomb — and stay in it while you pray."
                    )
                    montfortCounsel(
                        title: "Pray without rushing",
                        text: "Montfort counsels deliberate pauses within the prayers themselves. A slower, attentive Rosary is worth more than several hurried ones."
                    )
                    montfortCounsel(
                        title: "Fight distractions gently",
                        text: "Distractions will come; do not be discouraged or give up. Simply return to the mystery each time you notice you have wandered — that quiet return is itself a prayer."
                    )
                    montfortCounsel(
                        title: "Persevere in dryness",
                        text: "The Rosary prayed faithfully when it feels dry and unrewarding is especially pleasing to God — fidelity, not feeling, is the measure."
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(isExpanded ? 0.35 : 0.15), lineWidth: 0.5)
        )
    }

    private func montfortCounsel(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.semiboldBodyFont(15))
                .foregroundColor(AppColors.cream)

            Text(text)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(ReadingTypography.lineSpacing(for: 14))
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        HowToPrayRosaryView()
            .environment(UserSettings.shared)
    }
}
