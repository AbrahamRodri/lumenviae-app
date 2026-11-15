//
//  PrayerPageTests.swift
//  appTests
//
//  The prayer-book page's rules (PrayerPage): ℣ and ℟ in their column,
//  the marks between parts, headings, the prayers said as marks, the
//  intention pause, the collect block and the litany's groups.
//

import Testing

@testable import app

@MainActor
struct PrayerPageTests {

    private func page(_ text: String) -> PrayerPage {
        PrayerPage(stanzas: PrayAlongView.stanzas(text))
    }

    private let hailMary = """
        Hail Mary, full of grace, the Lord is with thee;
        blessed art thou among women,
        and blessed is the fruit of thy womb, Jesus.
        Holy Mary, Mother of God,
        pray for us sinners,
        now and at the hour of our death. Amen.
        """

    @Test func versiclesAndResponsesTakeTheirColumn() {
        let p = page("℣. The Angel of the Lord declared unto Mary.\n℟. And she conceived of the Holy Ghost.")
        #expect(
            p.sections == [
                .stanza(
                    .init(
                        index: 0,
                        parts: [
                            .lines([
                                .versicle("The Angel of the Lord declared unto Mary."),
                                .response("And she conceived of the Holy Ghost."),
                            ])
                        ]), opensPart: false)
            ])
    }

    @Test func theAngelusIsMarkedBetweenItsPartsAndKeepsEveryHailMary() {
        let text = """
            ℣. The Angel of the Lord declared unto Mary.
            ℟. And she conceived of the Holy Ghost.

            \(hailMary)

            ℣. Behold the handmaid of the Lord.
            ℟. Be it done unto me according to thy word.

            \(hailMary)
            """
        let p = page(text)
        #expect(p.sections.map(\.opensPart) == [false, false, true, false])
        // The Hail Mary is printed in full, both times, as it always was
        #expect(p.sections[1].stanzas[0].parts == [.classic(hailMary)])
        #expect(p.sections[3].stanzas[0].parts == [.classic(hailMary)])
    }

    @Test func aDirectionNamingPrayersBecomesMarks() {
        let p = page("[Our Father, Hail Mary, Glory Be.]")
        #expect(
            p.sections[0].stanzas[0].parts == [
                .said([
                    .init(name: "Our Father", prayerID: "our_father"),
                    .init(name: "Hail Mary", prayerID: "hail_mary"),
                    .init(name: "Glory Be", prayerID: "glory_be"),
                ])
            ])
        #expect(PrayerPage.saidPrayers(in: "Our Father. Hail Mary.")?.map(\.prayerID) == ["our_father", "hail_mary"])
        #expect(PrayerPage.saidPrayers(in: "Hail, Holy Queen.")?.map(\.prayerID) == ["hail_holy_queen"])
        // Anything more than names stays a direction
        #expect(PrayerPage.saidPrayers(in: "Hail Mary, three times; Glory be, once.") == nil)
    }

    @Test func theRequestIsAPause() {
        #expect(page("[Here name your request.]").sections[0].stanzas[0].parts == [.intention])
        #expect(PrayerPage.isIntention("Here name the favour asked."))
        #expect(!PrayerPage.isIntention("Here all kneel."))
        #expect(PrayerPage.isIntention("Here make your request."))
        #expect(PrayerPage.isIntention("Aquí nombra tu petición."))
        #expect(PrayerPage.isIntention("Aquí se pide la gracia que se desea alcanzar."))
        #expect(!PrayerPage.isIntention("Aquí todos se arrodillan."))
    }

    @Test func partsAreHeadingsWithTheirReference() {
        #expect(
            PrayerPage.heading("The first shedding of His Blood: the Circumcision. Luke 2:21.")
                == .heading(title: "The first shedding of His Blood: the Circumcision", reference: "Luke 2:21"))
        #expect(PrayerPage.heading("The First Day.") == .heading(title: "The First Day", reference: nil))
        #expect(PrayerPage.heading("Primer día.") == .heading(title: "Primer día", reference: nil))
        #expect(
            PrayerPage.heading("The Precepts of the Church")
                == .heading(title: "The Precepts of the Church", reference: nil))
        // A direction is not a heading
        #expect(PrayerPage.heading("Go, and say your penance.") == nil)
        #expect(PrayerPage.heading("Kneel, and make the Sign of the Cross.") == nil)
    }

    @Test func aLongOpeningDirectionIsTheIntro() {
        let words =
            "A devotion long attributed to St. Bridget of Sweden: each day, seven Our Fathers and seven Hail Marys."
        #expect(page("[\(words)]\n\nOur Father.").sections[0].stanzas[0].parts == [.intro(words)])
    }

    @Test func theCollectIsOneBlock() {
        let text = """
            ℣. Pray for us, O holy Mother of God.
            ℟. That we may be made worthy of the promises of Christ.

            [Let us pray.]

            Pour forth, we beseech Thee, O Lord,
            Thy grace into our hearts. Amen.
            """
        let p = page(text)
        #expect(p.sections.count == 1)
        guard case .collect(let stanzas, _) = p.sections[0] else {
            Issue.record("expected a collect")
            return
        }
        #expect(stanzas.map(\.index) == [0, 1, 2])
        #expect(stanzas[1].parts == [.letUsPray("Let us pray")])
        #expect(
            stanzas[2].parts == [
                .paragraph("Pour forth, we beseech Thee, O Lord, Thy grace into our hearts."),
                .lines([.response("Amen.")]),
            ])
    }

    @Test func aCollectInOneStanza() {
        let text = """
            Pray for us, O most sorrowful Virgin,
            that we may be made worthy of the promises of Christ.
            [Let us pray.]
            Lord Jesus, we now implore,
            world without end. Amen.
            """
        guard case .collect(let stanzas, _) = page(text).sections[0] else {
            Issue.record("expected a collect")
            return
        }
        #expect(
            stanzas[0].parts == [
                .lines([
                    .verse("Pray for us, O most sorrowful Virgin,"),
                    .verse("that we may be made worthy of the promises of Christ."),
                ]),
                .letUsPray("Let us pray"),
                .paragraph("Lord Jesus, we now implore, world without end."),
                .lines([.response("Amen.")]),
            ])
    }

    @Test func aLitanyGroupAnswersOnce() {
        let text = "Holy Mary, ℟. pray for us.\nHoly Mother of God,\nHoly Virgin of virgins,"
        let p = page(text)
        #expect(
            p.sections[0].stanzas[0].parts == [
                .litanyGroup(
                    invocations: ["Holy Mary,", "Holy Mother of God,", "Holy Virgin of virgins,"],
                    response: "pray for us.")
            ])
        #expect(p.hasLitanyGroups)
    }

    @Test func pairedLanguagesAreSetAsBefore() {
        let text = "℣. Ora pro nobis. ||| Pray for us.\n℟. Ut digni efficiamur. ||| That we may be made worthy."
        #expect(page(text).sections[0].stanzas[0].parts == [.classic(text)])
    }

    @Test func everyStanzaKeepsItsIndex() {
        let text = "℣. A.\n℟. B.\n\n\(hailMary)\n\n[Our Father.]\n\n[Let us pray.]\n\nPrayer. Amen."
        let indices = page(text).sections.flatMap(\.stanzas).map(\.index)
        #expect(indices == Array(0..<PrayAlongView.stanzas(text).count))
    }
}
