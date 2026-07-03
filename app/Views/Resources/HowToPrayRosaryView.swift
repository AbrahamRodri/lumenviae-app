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

                    introduction
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    stepsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                    prayersSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                    scheduleSection
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
            AppIcon("ph-book", size: 36)
                .foregroundColor(AppColors.gold)
                .padding(.top, 24)

            Text("How to Pray the Rosary")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text("A Step-by-Step Guide")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.gold.opacity(0.8))

            Divider()
                .background(AppColors.gold.opacity(0.3))
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Introduction

    private var introduction: some View {
        Text("The Rosary is a Scripture-based prayer in which we meditate on the great mysteries of the life of Jesus and Mary while praying familiar vocal prayers. The repetition is not the point — it is the quiet rhythm that frees the heart to contemplate. As St. John Paul II wrote, the Rosary is \"a compendium of the Gospel\" in which, with Mary, we contemplate the face of Christ.")
            .font(AppFonts.bodyFont(15))
            .foregroundColor(AppColors.cream.opacity(0.9))
            .lineSpacing(5)
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
        RosaryStep(id: 5, title: "Pray the Glory Be", detail: "On the next large bead (or the space before it)."),
        RosaryStep(id: 6, title: "Announce the first mystery", detail: "Name the mystery (e.g., \"The First Joyful Mystery: The Annunciation\"), pause to picture the scene, then pray one Our Father."),
        RosaryStep(id: 7, title: "Pray ten Hail Marys", detail: "On the ten small beads of the decade, while meditating on the mystery. Let the scene stay before your mind's eye."),
        RosaryStep(id: 8, title: "Close the decade", detail: "Pray the Glory Be, and optionally the Fatima Prayer (\"O my Jesus...\")."),
        RosaryStep(id: 9, title: "Repeat for all five mysteries", detail: "Announce each new mystery, then pray the Our Father, ten Hail Marys, Glory Be, and Fatima Prayer."),
        RosaryStep(id: 10, title: "Conclude", detail: "Pray the Hail, Holy Queen and the closing prayer, then finish with the Sign of the Cross.")
    ]

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THE STEPS")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(spacing: 0) {
                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 14) {
                        // Number circle
                        ZStack {
                            Circle()
                                .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                                .frame(width: 28, height: 28)
                            Text("\(step.id)")
                                .font(AppFonts.bodyFont(13))
                                .foregroundColor(AppColors.gold)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(AppFonts.headlineFont(15))
                                .foregroundColor(AppColors.cream)

                            Text(step.detail)
                                .font(AppFonts.bodyFont(13))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(3)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)

                    if step.id != steps.last?.id {
                        Divider()
                            .background(AppColors.gold.opacity(0.15))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
            )
        }
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
and after this, our exile,
show unto us the blessed fruit of thy womb, Jesus.
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
et Iesum, benedictum fructum ventris tui,
nobis post hoc exsilium ostende.
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
that meditating upon these mysteries
of the most holy Rosary of the Blessed Virgin Mary,
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
ut haec mysteria
sacratissimo beatae Mariae Virginis Rosario recolentes,
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

    /// Renders the prayer body in the user's preferred prayer language.
    /// Bilingual modes show line pairs: primary language with the secondary
    /// language in italic gold beneath it (same format as TrueDevotionView).
    @ViewBuilder
    private func prayerContent(_ prayer: RosaryPrayer) -> some View {
        let formatted = prayer.content.formatted(for: settings.prayerLanguage)
        let lines = formatted.components(separatedBy: "\n")
        let isBilingual = settings.prayerLanguage == .both || settings.prayerLanguage == .latinUnderEnglish

        if isBilingual {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)

                    if trimmed.isEmpty {
                        Spacer()
                            .frame(height: 4)
                    } else if trimmed.contains("|||") {
                        let parts = trimmed.components(separatedBy: "|||")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(parts[0].trimmingCharacters(in: .whitespaces))
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(AppColors.cream)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            if parts.count >= 2 {
                                Text(parts[1].trimmingCharacters(in: .whitespaces))
                                    .font(AppFonts.italicFont(13))
                                    .foregroundColor(AppColors.gold.opacity(0.8))
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.bottom, 4)
                    } else {
                        Text(trimmed)
                            .font(AppFonts.bodyFont(15))
                            .foregroundColor(AppColors.cream.opacity(0.9))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        } else {
            Text(formatted)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MYSTERIES BY DAY")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(spacing: 0) {
                scheduleRow(day: "Sunday", mysteries: "Glorious")
                Divider().background(AppColors.gold.opacity(0.15))
                scheduleRow(day: "Monday", mysteries: "Joyful")
                Divider().background(AppColors.gold.opacity(0.15))
                scheduleRow(day: "Tuesday", mysteries: "Sorrowful")
                Divider().background(AppColors.gold.opacity(0.15))
                scheduleRow(day: "Wednesday", mysteries: "Glorious")
                Divider().background(AppColors.gold.opacity(0.15))
                scheduleRow(day: "Thursday", mysteries: "Joyful")
                Divider().background(AppColors.gold.opacity(0.15))
                scheduleRow(day: "Friday", mysteries: "Sorrowful")
                Divider().background(AppColors.gold.opacity(0.15))
                scheduleRow(day: "Saturday", mysteries: "Joyful")
            }
            .padding(.horizontal, 16)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
            )

            Text("This is the traditional schedule. The Luminous Mysteries, added by Pope St. John Paul II in 2002, may be prayed on Thursdays, and any set may be prayed on any day.")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
        }
    }

    private func scheduleRow(day: String, mysteries: String) -> some View {
        HStack {
            Text(day)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream)

            Spacer()

            Text(mysteries)
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.gold)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HowToPrayRosaryView()
            .environment(UserSettings.shared)
    }
}
