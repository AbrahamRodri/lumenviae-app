//
//  MarianLibraryView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  MARIAN THEOLOGY LIBRARY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A reference library on the Blessed Virgin Mary: the four Marian dogmas,
//  Mary in Scripture, approved apparitions, and the witness of the Marian
//  saints in their own words.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - MarianLibraryView

struct MarianLibraryView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var expandedSections: Set<String> = []

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

                    VStack(spacing: 14) {
                        ForEach(Self.sections) { section in
                            sectionCard(section)
                        }
                    }
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
            AppIcon("ph-heart-fill", size: 36)
                .foregroundColor(AppColors.gold)
                .padding(.top, 24)

            Text("Marian Theology Library")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text("De Maria Numquam Satis")
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
        Text("\u{201C}Of Mary, there is never enough.\u{201D} Everything the Church teaches about Mary points to her Son: each dogma safeguards a truth about Christ, each apparition calls the world back to Him, and each Marian saint found in her the surest way to Him. Explore the Church's rich teaching below.")
            .font(AppFonts.bodyFont(15))
            .foregroundColor(AppColors.cream.opacity(0.9))
            .lineSpacing(5)
    }

    // MARK: - Section Model

    struct LibrarySection: Identifiable {
        let id: String
        let icon: String
        let title: String
        let subtitle: String
        let entries: [LibraryEntry]
    }

    struct LibraryEntry: Identifiable {
        var id: String { title }
        let title: String
        let detail: String
        let text: String
    }

    // MARK: - Content

    static let sections: [LibrarySection] = [
        LibrarySection(
            id: "dogmas",
            icon: "ph-crown-fill",
            title: "The Four Marian Dogmas",
            subtitle: "What the Church solemnly teaches",
            entries: [
                LibraryEntry(
                    title: "Mother of God (Theotokos)",
                    detail: "Council of Ephesus, A.D. 431",
                    text: "Mary is truly the Mother of God, because the Son she conceived and bore is truly God. The Council of Ephesus defended this title against Nestorius: the child of Mary is one divine Person, the eternal Word. Every other Marian truth flows from this one. As St. Louis de Montfort writes, God the Son \u{201C}became man for our salvation, but in Mary and by Mary.\u{201D}"
                ),
                LibraryEntry(
                    title: "Perpetual Virginity",
                    detail: "Lateran Council, A.D. 649",
                    text: "Mary was a virgin before, during, and after the birth of Christ — Semper Virgo, ever-virgin. Her virginity is the sign of her total, undivided gift of self to God, and of the divine origin of her Son. The Fathers of the Church saw it prefigured in the burning bush and the closed gate of Ezekiel's temple."
                ),
                LibraryEntry(
                    title: "The Immaculate Conception",
                    detail: "Bl. Pius IX, Ineffabilis Deus, 1854",
                    text: "From the first instant of her conception, Mary was preserved free from all stain of original sin, by a singular grace of God and in view of the merits of Jesus Christ. She is the New Eve, full of grace. Four years after the definition, Our Lady confirmed it at Lourdes, telling St. Bernadette: \u{201C}I am the Immaculate Conception.\u{201D}"
                ),
                LibraryEntry(
                    title: "The Assumption",
                    detail: "Ven. Pius XII, Munificentissimus Deus, 1950",
                    text: "When the course of her earthly life was finished, Mary was assumed body and soul into heavenly glory. She already shares fully in her Son's Resurrection, anticipating what is promised to all the members of His Body. Assumed into heaven, she is crowned Queen of heaven and earth — the mystery contemplated in the fifth Glorious Mystery."
                )
            ]
        ),
        LibrarySection(
            id: "scripture",
            icon: "ch-bible",
            title: "Mary in Scripture",
            subtitle: "From Genesis to the Apocalypse",
            entries: [
                LibraryEntry(
                    title: "The New Eve",
                    detail: "Genesis 3:15",
                    text: "\u{201C}I will put enmities between thee and the woman, and thy seed and her seed: she shall crush thy head.\u{201D} The Fathers called this the Protoevangelium — the first gospel. Where Eve's disobedience helped bring death, Mary's obedient \u{201C}fiat\u{201D} helped bring Life. St. Irenaeus wrote in the second century: \u{201C}The knot of Eve's disobedience was untied by Mary's obedience.\u{201D}"
                ),
                LibraryEntry(
                    title: "The Ark of the Covenant",
                    detail: "2 Kings 6 & Luke 1:39-56",
                    text: "St. Luke deliberately echoes David's journey with the Ark in his account of the Visitation: the Ark went up to the hill country of Judah, David danced before it, and it remained three months in the house of Obededom. Mary goes to the hill country, John leaps in Elizabeth's womb, and she stays three months. The Ark carried the Law, the manna, and Aaron's rod; Mary carried the Lawgiver, the Bread of Life, and the eternal High Priest."
                ),
                LibraryEntry(
                    title: "The Queen Mother",
                    detail: "3 Kings 2:19 & Apocalypse 12:1",
                    text: "In the kingdom of David, the queen was not the king's wife but his mother — the Gebirah — who sat enthroned at his right hand and interceded for the people. Solomon told Bathsheba: \u{201C}Ask, my mother, for I must not turn away thy face.\u{201D} Christ, Son of David, honors His mother the same way. St. John sees her in heaven: \u{201C}a woman clothed with the sun... and on her head a crown of twelve stars.\u{201D}"
                ),
                LibraryEntry(
                    title: "The Wedding at Cana",
                    detail: "John 2:1-11",
                    text: "Mary's intercession obtains Christ's first miracle, and her last recorded words in Scripture are a rule of life for every Christian: \u{201C}Whatsoever he shall say to you, do ye.\u{201D} At Cana as at Calvary, Jesus calls her \u{201C}Woman\u{201D} — the Woman of Genesis 3:15, the New Eve, mother of all the living."
                ),
                LibraryEntry(
                    title: "Behold Thy Mother",
                    detail: "John 19:26-27",
                    text: "From the Cross, Jesus gave His mother to the beloved disciple: \u{201C}Behold thy mother. And from that hour, the disciple took her to his own.\u{201D} The Church has always read this as a gift to every disciple. Consecration to Mary is simply taking her into our own home, as St. John did."
                )
            ]
        ),
        LibrarySection(
            id: "apparitions",
            icon: "ph-sun",
            title: "Approved Apparitions",
            subtitle: "When Heaven visited earth",
            entries: [
                LibraryEntry(
                    title: "Our Lady of Guadalupe",
                    detail: "Mexico, 1531 — St. Juan Diego",
                    text: "Appearing as a young mestiza woman on Tepeyac hill, Our Lady left her image miraculously imprinted on Juan Diego's tilma, which remains intact to this day. \u{201C}Am I not here, I who am your Mother?\u{201D} she asked him. Within a decade, millions of Aztecs entered the Church. She is Patroness of the Americas and of the unborn."
                ),
                LibraryEntry(
                    title: "The Miraculous Medal",
                    detail: "Paris, 1830 — St. Catherine Labouré",
                    text: "In the chapel of the Rue du Bac, Our Lady showed St. Catherine the design of a medal with the prayer: \u{201C}O Mary, conceived without sin, pray for us who have recourse to thee.\u{201D} The graces attached to the medal were so abundant that the faithful named it \u{201C}miraculous.\u{201D} It prepared the world for the dogma of the Immaculate Conception."
                ),
                LibraryEntry(
                    title: "Our Lady of Lourdes",
                    detail: "France, 1858 — St. Bernadette Soubirous",
                    text: "In eighteen apparitions at the grotto of Massabielle, Our Lady called for penance and prayer for sinners, and a spring of healing water broke forth at her word. Asked her name, she replied: \u{201C}I am the Immaculate Conception.\u{201D} Lourdes remains one of the great places of pilgrimage and healing in the world."
                ),
                LibraryEntry(
                    title: "Our Lady of Knock",
                    detail: "Ireland, 1879",
                    text: "On a rainy August evening, Our Lady appeared in silence at the gable of the parish church, with St. Joseph, St. John the Evangelist, and the Lamb of God upon an altar surrounded by angels. Fifteen villagers watched and prayed the Rosary for two hours. The silent apparition speaks of the Eucharist: Mary always stands beside the Lamb."
                ),
                LibraryEntry(
                    title: "Our Lady of Fatima",
                    detail: "Portugal, 1917 — Sts. Jacinta & Francisco, Ven. Lucia",
                    text: "Appearing to three shepherd children six times, Our Lady asked for the daily Rosary, penance for sinners, and devotion to her Immaculate Heart. On October 13, some 70,000 people witnessed the Miracle of the Sun. \u{201C}My Immaculate Heart will triumph,\u{201D} she promised."
                ),
                LibraryEntry(
                    title: "Beauraing & Banneux",
                    detail: "Belgium, 1932-1933",
                    text: "At Beauraing, Our Lady with the golden heart appeared thirty-three times to five children, asking: \u{201C}Do you love my Son? Do you love me? Then sacrifice yourself for me.\u{201D} Weeks later at Banneux, she appeared to Mariette Beco as the Virgin of the Poor, leading the child to a spring \u{201C}reserved for all nations — to relieve the sick.\u{201D}"
                )
            ]
        ),
        LibrarySection(
            id: "saints",
            icon: "ph-users-three",
            title: "The Marian Saints",
            subtitle: "In their own words",
            entries: [
                LibraryEntry(
                    title: "St. Bernard of Clairvaux",
                    detail: "1090-1153 — Doctor of the Church",
                    text: "\u{201C}In dangers, in doubts, in difficulties, think of Mary, call upon Mary... If you follow her, you cannot go astray; if you pray to her, you cannot despair; if you think of her, you cannot err. If she holds you, you cannot fall; if she protects you, you need not fear; if she guides you, you will never tire.\u{201D} — Homily in Praise of the Virgin Mother"
                ),
                LibraryEntry(
                    title: "St. Dominic",
                    detail: "1170-1221 — Founder of the Order of Preachers",
                    text: "\u{201C}Arm yourself with prayer rather than a sword; wear humility rather than fine clothes.\u{201D} Tradition, handed down through Bl. Alan de la Roche, holds that Our Lady gave St. Dominic the Rosary around 1214 as the weapon against the Albigensian heresy: where preaching alone had failed, her Psalter — 150 Hail Marys echoing the 150 Psalms — converted thousands. His Order of Preachers has carried the Rosary to the world ever since."
                ),
                LibraryEntry(
                    title: "St. Louis de Montfort",
                    detail: "1673-1716 — Apostle of Total Consecration",
                    text: "\u{201C}The more one is consecrated to Mary, the more one is consecrated to Jesus... She is the safest, easiest, shortest and most perfect way of approaching Jesus.\u{201D} His True Devotion to Mary, written around 1712 and hidden for over a century, teaches the total consecration practiced in this app's 33-day preparation."
                ),
                LibraryEntry(
                    title: "St. Alphonsus Liguori",
                    detail: "1696-1787 — Doctor of the Church",
                    text: "\u{201C}Mary being in heaven nearer to God and more united to Him, knows our miseries better, compassionates them more, and can more efficaciously help us.\u{201D} His book The Glories of Mary remains one of the greatest works ever written on Our Lady — a verse-by-verse meditation on the Hail, Holy Queen."
                ),
                LibraryEntry(
                    title: "St. Maximilian Kolbe",
                    detail: "1894-1941 — Martyr of Auschwitz",
                    text: "\u{201C}Never be afraid of loving the Blessed Virgin too much. You can never love her more than Jesus did.\u{201D} Founder of the Militia Immaculatae, he gave his life in exchange for a fellow prisoner at Auschwitz, dying with the Immaculata's name on his lips."
                ),
                LibraryEntry(
                    title: "St. John Paul II",
                    detail: "1920-2005 — Totus Tuus",
                    text: "His papal motto, Totus Tuus — \u{201C}totally yours\u{201D} — was taken directly from St. Louis de Montfort's formula of consecration. \u{201C}The Rosary is my favorite prayer,\u{201D} he said. In Rosarium Virginis Mariae (2002) he gave the Church the Luminous Mysteries, and in Redemptoris Mater he presented Mary as the model of the Church's pilgrimage of faith."
                ),
                LibraryEntry(
                    title: "St. Padre Pio",
                    detail: "1887-1968 — Stigmatist of San Giovanni Rotondo",
                    text: "\u{201C}The Rosary is the weapon for these times.\u{201D} He prayed it almost without ceasing, calling his beads \u{201C}the weapon\u{201D} and Our Lady \u{201C}the little Madonna.\u{201D} His last words counseled: \u{201C}Love Our Lady and make her loved; always recite the Rosary.\u{201D}"
                )
            ]
        ),
        LibrarySection(
            id: "titles",
            icon: "ph-star-fill",
            title: "Titles of Our Lady",
            subtitle: "From the Litany of Loreto",
            entries: [
                LibraryEntry(
                    title: "Mystical Rose",
                    detail: "Rosa Mystica",
                    text: "Mary is the flower of humanity, the rose without thorns — conceived without sin. As the rose is the queen of flowers, she is the Queen of all creatures, and the beauty of her holiness draws souls to the fragrance of Christ."
                ),
                LibraryEntry(
                    title: "Tower of David",
                    detail: "Turris Davidica",
                    text: "The tower of David was hung with a thousand shields for the defense of Jerusalem. Mary is the Church's defense: invincible in faith, terrible to the powers of darkness. \u{201C}Terrible as an army set in array\u{201D} (Canticles 6:3)."
                ),
                LibraryEntry(
                    title: "Morning Star",
                    detail: "Stella Matutina",
                    text: "The morning star rises before the sun and announces the day. Mary rose before Christ, the Sun of Justice, and her appearing announced the dawn of salvation. Sailors steered by the star of the sea — Ave Maris Stella — and souls steer to Christ by her."
                ),
                LibraryEntry(
                    title: "Gate of Heaven",
                    detail: "Janua Caeli",
                    text: "Through Mary, God came down to us; through Mary, we ascend to God. St. Louis de Montfort calls her the Eastern Gate through which the High Priest entered the world — and the gate through which He will come again."
                ),
                LibraryEntry(
                    title: "Queen of Peace",
                    detail: "Regina Pacis",
                    text: "Added to the Litany by Benedict XV amid the First World War, this title invokes Mary as mother of the Prince of Peace. Where her Rosary is prayed, hearts are pacified, families are healed, and nations find concord."
                )
            ]
        )
    ]

    // MARK: - Section Card

    private func sectionCard(_ section: LibrarySection) -> some View {
        let isExpanded = expandedSections.contains(section.id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    AppIcon(section.icon, size: 18)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(AppFonts.headlineFont(17))
                            .foregroundColor(AppColors.cream)

                        Text(section.subtitle)
                            .font(AppFonts.italicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    AppIcon("ph-caret-down", size: 13)
                        .foregroundColor(AppColors.gold)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(section.entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.title)
                                .font(AppFonts.headlineFont(15))
                                .foregroundColor(AppColors.gold)

                            Text(entry.detail)
                                .font(AppFonts.bodyFont(11))
                                .tracking(1)
                                .foregroundColor(AppColors.textSecondary)

                            Text(entry.text)
                                .font(AppFonts.bodyFont(14))
                                .foregroundColor(AppColors.cream.opacity(0.88))
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(isExpanded ? 0.35 : 0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MarianLibraryView()
    }
}
