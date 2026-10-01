//
//  ChantLibraryTests.swift
//  Lumen Viae Tests
//
//  The Chant Library's ways in: every chant has a kind, every id the
//  curation names is a chant the app carries, the year is cut into
//  seasons with no gap and no overlap, the feasts fall on their days,
//  an occasion unrolls to the chants it sings, the lines a chant may
//  carry gate what steps by the line, the search folds accents and
//  ligatures, and the reader's shelf keeps what they put on it.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ChantLibraryTests {

    private let calendar = Calendar.current

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // MARK: - The curation

    @Test func everyChantHasAKind() {
        for chant in ChantCatalog.all {
            #expect(ChantLibraryData.forms[chant.id] != nil, "\(chant.id) has no kind")
        }
        #expect(Set(ChantLibraryData.forms.keys).isSubset(of: Set(ChantCatalog.all.map(\.id))))
        let counted = ChantForm.allCases.reduce(0) { $0 + $1.chants.count }
        #expect(counted == ChantCatalog.all.count)
    }

    @Test func theKindsAreTheBoardsCounts() {
        #expect(ChantForm.shortChant.chants.count == 16)
        #expect(ChantForm.hymn.chants.count == 21)
        #expect(ChantForm.sequence.chants.count == 7)
        #expect(ChantForm.litany.chants.count == 5)
        #expect(ChantForm.psalm.chants.count == 3)
        #expect(ChantForm.everydayPrayer.chants.count == 12)
    }

    @Test func theLengthsAreTheBoardsCounts() {
        #expect(ChantLength.underAMinute.chants.count == 7)
        #expect(ChantLength.aFewMinutes.chants.count == 48)
        #expect(ChantLength.aLongWhile.chants.count == 9)
    }

    @Test func everyIdTheCurationNamesIsAChant() {
        var named: [String] = []
        named += ChantLibraryData.seasonChants.values.flatMap { $0 }
        named += ChantLibraryData.seasonSignatures.values
        named += ChantLibraryData.feasts.map(\.chantID)
        named += ChantLibraryData.weekdays.flatMap(\.chantIDs)
        named += ChantLibraryData.months.flatMap(\.chantIDs)
        named += ChantLibraryData.learningPaths.flatMap(\.chantIDs)
        named += Array(ChantLibraryData.paintings.keys)
        for block in ChantLibraryData.occasions.flatMap(\.blocks) {
            for step in block.steps {
                if case .chant(let id) = step.chant { named.append(id) }
            }
        }
        for id in named {
            #expect(ChantCatalog.chant(id) != nil, "\(id) is not in the catalog")
        }
        for month in ChantLibraryData.months {
            if let occasion = month.occasionID { #expect(ChantOccasion.occasion(occasion) != nil, "\(occasion)") }
            if let feast = month.feastID { #expect(ChantFeast.feast(feast) != nil, "\(feast)") }
        }
        #expect(Set(ChantLibraryData.weekdays.map(\.weekday)) == Set(1...7))
    }

    @Test func everyChantHasAPaintingInTheApp() {
        for chant in ChantCatalog.all {
            let name = ChantCatalog.painting(for: chant)
            #expect(ImageCacheService.shared.image(named: name) != nil, "\(chant.id): \(name)")
        }
        for occasion in ChantLibraryData.occasions {
            #expect(ImageCacheService.shared.image(named: occasion.painting) != nil, "\(occasion.id)")
        }
        // A painting asked for by subject draws its stand-in until its
        // imageset arrives, and never a blank
        var subjects = Array(ChantLibraryData.subjectPaintings.keys)
        subjects += ChantLibraryData.weekdays.map(\.painting)
        subjects += ChantSeason.allCases.map(\.painting)
        subjects += ChantLibraryData.feasts.compactMap(\.painting)
        for subject in subjects {
            let name = ChantCatalog.painting(subject: subject)
            #expect(ImageCacheService.shared.image(named: name) != nil, "\(subject) falls back to \(name)")
        }
    }

    @Test func everyWorkOfTonightHasItsLine() {
        for antiphon in MarianAntiphon.allCases {
            guard let chant = ChantCatalog.chants(forPrayer: antiphon.prayerID).first else { continue }
            #expect(ChantLibraryData.tonightLines[chant.workKey] != nil, "\(chant.workKey)")
        }
    }

    // MARK: - The year

    @Test func theSeasonsCutTheYearWithNoGap() {
        for year in [2025, 2026, 2027, 2031] {
            let church = ChantYear(containing: day(year, 6, 1))
            #expect(church.seasons.first?.start == church.start)
            #expect(church.seasons.last?.end == church.end)
            for (a, b) in zip(church.seasons, church.seasons.dropFirst()) {
                #expect(a.end == b.start, "\(year): \(a.value) ends where \(b.value) begins")
                #expect(a.start < a.end, "\(year): \(a.value) is empty")
            }
            #expect(church.antiphons.first?.start == church.start)
            #expect(church.antiphons.last?.end == church.end)
        }
    }

    @Test func theSeasonsFallWhereTheCalendarPutsThem() {
        #expect(ChantYear(containing: day(2026, 10, 1)).season(on: day(2026, 10, 1)) == .afterPentecost)
        #expect(ChantYear(containing: day(2026, 12, 1)).season(on: day(2026, 12, 1)) == .advent)
        #expect(ChantYear(containing: day(2026, 12, 25)).season(on: day(2026, 12, 25)) == .christmas)
        // Easter 2027 is 28 March: Septuagesima is 24 January
        #expect(ChantYear(containing: day(2027, 1, 23)).season(on: day(2027, 1, 23)) == .christmas)
        #expect(ChantYear(containing: day(2027, 1, 24)).season(on: day(2027, 1, 24)) == .lent)
        #expect(ChantYear(containing: day(2027, 3, 28)).season(on: day(2027, 3, 28)) == .easter)
        #expect(ChantYear(containing: day(2027, 5, 16)).season(on: day(2027, 5, 16)) == .pentecost)
        #expect(ChantYear(containing: day(2027, 5, 23)).season(on: day(2027, 5, 23)) == .afterPentecost)
    }

    @Test func theWheelsBoundariesAreTheSchedules() {
        // Easter 2027 is the 28th of March
        let monthAndDay: (Date?) -> [Int] = { date in
            guard let date else { return [] }
            return [self.calendar.component(.month, from: date), self.calendar.component(.day, from: date)]
        }
        #expect(monthAndDay(ScheduleService.septuagesima(year: 2027)) == [1, 24])
        #expect(monthAndDay(ScheduleService.pentecost(year: 2027)) == [5, 16])
        #expect(monthAndDay(ScheduleService.trinitySunday(year: 2027)) == [5, 23])
        let church = ChantYear(containing: day(2027, 3, 1))
        #expect(church.span(of: .lent)?.start == ScheduleService.septuagesima(year: 2027))
        #expect(church.span(of: .pentecost)?.start == ScheduleService.pentecost(year: 2027))
        #expect(church.span(of: .afterPentecost)?.start == ScheduleService.trinitySunday(year: 2027))
    }

    @Test func theWheelCountsTheDaysToAdvent() {
        let today = day(2026, 10, 1)
        let next = ChantYear(containing: today).daysUntilNextSeason(from: today)
        #expect(next.season == .advent)
        #expect(next.days == 59)
    }

    @Test func theAntiphonsChangeWhereThePrayerBookSays() {
        let church = ChantYear(containing: day(2027, 6, 1))
        for span in church.antiphons {
            #expect(PrayerBook.antiphon(on: span.start) == span.value)
            let lastDay = calendar.date(byAdding: .day, value: -1, to: span.end)!
            #expect(PrayerBook.antiphon(on: lastDay) == span.value)
        }
    }

    // MARK: - Feasts

    @Test func theFeastsAheadOfTheFirstOfOctober() {
        let ahead = ChantFeast.upcoming(from: day(2026, 10, 1), count: 4)
        #expect(ahead.map(\.feast.id) == ["rosary", "christ_the_king", "all_saints", "all_souls"])
        #expect(calendar.component(.day, from: ahead[1].date) == 25)
    }

    @Test func theMovableFeastsFallOnTheirDays() {
        let king = ChantFeast.feast("christ_the_king")!.date(in: 2027)!
        #expect(calendar.component(.weekday, from: king) == 1)
        #expect(calendar.component(.month, from: king) == 10)
        #expect(calendar.component(.day, from: king) >= 25)

        // 2027: the 3rd of January is a Sunday; 2023: no Sunday between the
        // 2nd and the 5th (the 1st and the 8th were), so the 2nd
        #expect(calendar.component(.day, from: ChantFeast.feast("holy_name")!.date(in: 2027)!) == 3)
        #expect(calendar.component(.day, from: ChantFeast.feast("holy_name")!.date(in: 2023)!) == 2)

        let corpus = ChantFeast.feast("corpus_christi")!.date(in: 2027)!
        #expect(calendar.component(.weekday, from: corpus) == 5)
    }

    // MARK: - Occasions

    @Test func aSungRosaryIsFiftyThreeMinutes() {
        let rosary = ChantOccasion.occasion("sung_rosary")!
        let minutes = rosary.duration() / 60
        #expect(minutes > 52 && minutes < 54)
        #expect(rosary.sequence().filter { $0.id == "ave_maria" }.count == 53)
    }

    @Test func benedictionIsItsFourChantsInOrder() {
        let benediction = ChantOccasion.occasion("benediction")!
        #expect(benediction.sequence().map(\.id) == ["o_salutaris", "tantum_ergo", "divine_praises", "adoremus"])
        #expect(ChantQueue.occasion(benediction).position == "1 of 4")
    }

    @Test func aQueueRemembersTheStepEachEntryCameFrom() {
        let rosary = ChantOccasion.occasion("sung_rosary")!
        let queue = ChantQueue.occasion(rosary)
        #expect(queue.entries.count == queue.origins.count)
        #expect(queue.entries.count == rosary.sequence().count)
        // The decade's Ave Maria is step 6, sung ten times in each of five
        // rounds; the page's step numbers are the queue's
        let numbers = ChantOccasionsSection.stepNumbers(of: rosary)
        #expect(numbers[2][1] == 6)
        #expect(queue.origins.filter { $0 == 6 }.count == 50)
        #expect(queue.source == "occasion:sung_rosary")
    }

    @Test func aSetUnrollsItsRepeatsAndKeepsItsSilences() {
        let set = ChantSet(name: "Test", items: [
            ChantSet.Item(kind: .pause(note: "Kneel.", seconds: 0)),
            ChantSet.Item(kind: .chant(id: "ave_maria", times: 3)),
            ChantSet.Item(kind: .pause(note: "Silent prayer", seconds: 600)),
            ChantSet.Item(kind: .chant(id: "gloria_patri", times: 1))
        ])
        let queue = ChantQueue.set(set)
        #expect(queue.entries.count == 5)
        #expect(queue.entries.compactMap(\.chant).count == 4)
        #expect(set.chantCount == 2)
        #expect(set.pauseCount == 2)
        #expect(set.summary.hasPrefix("2 chants and 2 pauses"))
    }

    // MARK: - Lines

    /// A chant given the lines a file in Tools/ChantLines would give it
    private func timed() -> Chant {
        var chant = ChantCatalog.chant("salve_regina_simple")!
        chant.lines = [
            ChantLine(latin: "Salve, Regína, mater misericórdiæ,", english: "Hail, holy Queen, Mother of mercy,", start: 0, end: 7.4),
            ChantLine(latin: "vita, dulcédo, et spes nostra, salve.", english: "our life, our sweetness and our hope, hail.", start: 7.9, end: 14.2),
            ChantLine(latin: "Ad te clamámus, éxsules fílii Hevæ.", english: "To thee do we cry, poor banished children of Eve.", start: 14.8, end: 21.0, part: 0)
        ]
        return chant
    }

    /// A chant whose lines have not been timed — a chant that arrives
    /// before its file in Tools/ChantLines — steps by no line and takes its
    /// words from the Prayer Book
    @Test func aChantWithoutLinesFallsBackToTheWholeChant() {
        var chant = ChantCatalog.chant("salve_regina_simple")!
        chant.lines = []
        #expect(!chant.hasLines)
        #expect(chant.lineIndex(at: 0) == nil)
        #expect(chant.lineIndex(at: 10) == nil)
        #expect(chant.bookPrayer != nil)
        #expect(chant.words?.latin == chant.bookPrayer?.latin)
        #expect(chant.words?.english == chant.bookPrayer?.english)
    }

    /// Every chant that has lines has them as the generator checked them:
    /// in order, none overlapping the one before, none starting before the
    /// recording or ending after it, each on a part its score has
    @Test func everyTimedChantsLinesHoldTogether() {
        for chant in ChantCatalog.all where chant.hasLines {
            var previousEnd: TimeInterval = 0
            for (index, line) in chant.lines.enumerated() {
                let place = "\(chant.id), line \(index + 1)"
                #expect(line.start >= 0, "\(place) starts before the recording")
                #expect(line.end > line.start, "\(place) ends before it starts")
                #expect(line.start >= previousEnd - 0.001, "\(place) overlaps the line before")
                if chant.duration > 0 {
                    #expect(line.end <= chant.duration + 0.5, "\(place) ends after the recording")
                }
                if let part = line.part {
                    #expect(chant.score.indices.contains(part), "\(place) names part \(part)")
                }
                #expect(!line.latin.isEmpty && !line.english.isEmpty, "\(place) has no words")
                previousEnd = line.end
            }
        }
    }

    /// The chants timed today, by name: a chant added later without its
    /// timings does not fail this, and one of these losing its lines does
    @Test func theTimedChantsKeepTheirLines() {
        let timed = [
            "adeste_fideles", "adoremus", "adoro_te", "alma_redemptoris",
            "angelus", "anima_christi", "attende_domine", "ave_maria",
            "ave_maria_antiphon", "ave_maris_stella", "ave_regina_simple",
            "ave_regina_solemn", "ave_verum", "christus_vincit", "cor_jesu",
            "creator_alme", "credo_in_deum", "dies_irae", "divine_praises",
            "ecce_panis", "flos_carmeli", "gloria_patri", "in_nomine_patris",
            "inviolata", "jesu_dulcis_memoria", "jesu_redemptor", "lauda_sion",
            "litany_holy_name", "litany_loreto", "litany_sacred_heart",
            "litany_saints", "litany_st_joseph", "magnificat", "memorare",
            "miserere", "o_filii", "o_gloriosa", "o_mi_jesu", "o_sacrum_convivium",
            "o_salutaris", "panis_angelicus", "parce_domine", "pater_noster",
            "puer_natus", "regina_caeli_simple", "regina_caeli_solemn",
            "rorate_caeli", "salve_mater", "salve_regina_simple",
            "salve_regina_solemn", "sancte_michael", "stabat_mater", "sub_tuum",
            "tantum_ergo", "te_deum", "te_joseph", "tota_pulchra", "ubi_caritas",
            "veni_creator", "veni_emmanuel", "veni_sancte_reple",
            "veni_sancte_spiritus", "vexilla_regis", "victimae_paschali"
        ]
        #expect(timed.count == 64)
        for id in timed {
            #expect(ChantCatalog.chant(id)?.hasLines == true, "\(id) has lost its lines")
        }
    }

    @Test func aTimedChantKnowsItsLine() {
        let chant = timed()
        #expect(chant.hasLines)
        #expect(chant.lineIndex(at: 0) == 0)
        #expect(chant.lineIndex(at: 3) == 0)
        // Between two lines, the one just sung
        #expect(chant.lineIndex(at: 7.6) == 0)
        #expect(chant.lineIndex(at: 8) == 1)
        #expect(chant.lineIndex(at: 30) == 2)
        #expect(abs(chant.lines[2].length - 6.2) < 0.0001)
        #expect(chant.words?.latin?.components(separatedBy: "\n").count == 3)
    }

    // MARK: - Search

    @Test func searchFoldsAccentsAndLigatures() {
        #expect(ChantSearch.fold("Cæli") == "caeli")
        #expect(ChantSearch.fold("Regína") == "regina")
        let works = ChantSearch.works(matching: "regina", where: { _ in true })
        let salve = works.first { $0.chants.first?.id == "salve_regina_simple" }
        #expect(salve?.chants.map(\.id) == ["salve_regina_simple", "salve_regina_solemn"])
        // The Rosary's Ave Maria and the Advent offertory share a name, not a work
        let ave = ChantSearch.works(matching: "ave maria", where: { _ in true })
        #expect(ave.count >= 2)
    }

    @Test func aMatchIsDrawnUnderTheWordsAsWritten() {
        let text = "Regina Cæli, Regina Angelorum"
        let found = ChantSearch.matches(in: text, needle: "caeli").map { String(text[$0]) }
        #expect(found == ["Cæli"])
        #expect(ChantSearch.matches(in: text, needle: "regina").count == 2)
    }

    @Test func aPrayerFindsTheChantThatSingsIt() {
        let works = ChantSearch.works(singingPrayerMatching: ChantSearch.fold("glory"), where: { _ in true })
        #expect(works.contains { $0.chants.contains { $0.id == "gloria_patri" } })
    }

    @Test func theWordsLoseTheirMarks() {
        #expect(ChantSearch.clean("℣. Ora pro nobis, sancta Dei Génitrix.") == "Ora pro nobis, sancta Dei Génitrix.")
        #expect(ChantSearch.clean("[Let us pray.]") == "")
    }

    // MARK: - The shelf

    private func store() -> ChantShelfStore {
        ChantShelfStore(defaults: UserDefaults(suiteName: "ChantLibraryTests.\(UUID().uuidString)")!)
    }

    @Test func aChantLearnedIsTheLearnersWord() {
        let shelf = store()
        #expect(shelf.step(of: "sub_tuum") == nil)
        shelf.begin("sub_tuum")
        #expect(shelf.step(of: "sub_tuum") == .listen)
        shelf.setStep(.singAlong, for: "sub_tuum")
        #expect(shelf.latestInProgress?.step == .singAlong)
        shelf.markLearned("sub_tuum")
        #expect(shelf.isLearned("sub_tuum"))
        #expect(shelf.step(of: "sub_tuum") == nil)
        // Practising it again is not unlearning it
        shelf.begin("sub_tuum")
        #expect(shelf.isLearned("sub_tuum"))
        shelf.unmarkLearned("sub_tuum")
        #expect(shelf.step(of: "sub_tuum") == .onYourOwn)
    }

    @Test func aSetIsKeptAndChanged() {
        let defaults = UserDefaults(suiteName: "ChantLibraryTests.\(UUID().uuidString)")!
        let shelf = ChantShelfStore(defaults: defaults)
        let set = shelf.newSet()
        #expect(set.name == "My set")
        #expect(shelf.newSet().name == "My set 2")
        shelf.addChant("adoro_te", to: set.id)
        shelf.addPause(note: "Silent prayer", seconds: 600, to: set.id)
        shelf.addChant("tantum_ergo", to: set.id)
        let tantum = shelf.set(set.id)!.items[2].id
        shelf.moveItem(tantum, by: -1, in: set.id)
        #expect(shelf.set(set.id)!.items[1].chant?.id == "tantum_ergo")
        shelf.toggleFavorite("adoro_te")

        // Read back by a store of its own
        let again = ChantShelfStore(defaults: defaults)
        #expect(again.set(set.id)?.items.count == 3)
        #expect(again.isFavorite("adoro_te"))
    }

    @Test func anOccasionKeptIsASetWithItsRubrics() {
        let shelf = store()
        let kept = shelf.saveOccasion(ChantOccasion.occasion("benediction")!)
        #expect(kept.chantCount == 4)
        #expect(kept.pauseCount == 4)
        #expect(ChantQueue.set(kept).entries.count == 4)
    }

    @Test func anOccasionIsKeptOnceAndLetGo() {
        let shelf = store()
        let benediction = ChantOccasion.occasion("benediction")!
        shelf.toggleKeeping(benediction)
        let kept = shelf.keptSet(of: benediction)
        #expect(kept != nil)
        // Kept already, it is not kept twice
        #expect(shelf.saveOccasion(benediction).id == kept?.id)
        #expect(shelf.sets.count == 1)
        shelf.toggleKeeping(benediction)
        #expect(shelf.keptSet(of: benediction) == nil)
        #expect(shelf.sets.isEmpty)
    }

    @Test func anOccasionKeptBeforeSetsSaidSoIsKnown() throws {
        let defaults = UserDefaults(suiteName: "ChantLibraryTests.\(UUID().uuidString)")!
        let benediction = ChantOccasion.occasion("benediction")!
        // Kept as an earlier build kept it, with no occasion named
        var older = ChantShelfStore(defaults: defaults).saveOccasion(benediction)
        older.occasionID = nil
        defaults.set(try JSONEncoder().encode([older]), forKey: "chantShelf.sets")

        let shelf = ChantShelfStore(defaults: defaults)
        #expect(shelf.keptSet(of: benediction)?.id == older.id)
        // A set of the reader's own that only shares an occasion's name is
        // not that occasion kept
        let visit = ChantOccasion.occasion("visit")!
        shelf.newSet(named: visit.title)
        #expect(shelf.keptSet(of: visit) == nil)
        shelf.toggleKeeping(benediction)
        #expect(shelf.sets.map(\.name) == [visit.title])
    }

    @Test func aNewSetIsNamedOrBegunWithItsChant() {
        let shelf = store()
        #expect(shelf.nextSetName == "My set")
        #expect(shelf.newSet(named: "  Holy hour ").name == "Holy hour")
        let begun = shelf.newSet(with: "adoro_te")
        #expect(begun.name == "My set")
        #expect(begun.items.first?.chant?.id == "adoro_te")
        #expect(shelf.newSet(named: "").name == "My set 2")
    }

    @Test func learningPutDownLeavesNoTrace() {
        let shelf = store()
        shelf.setStep(.readAlong, for: "sub_tuum")
        shelf.stopLearning("sub_tuum")
        #expect(shelf.step(of: "sub_tuum") == nil)
        #expect(shelf.latestInProgress == nil)
        #expect(shelf.inProgressCount == 0)
    }

    @Test func aShelfKeepsWhatItCannotRead() throws {
        let defaults = UserDefaults(suiteName: "ChantLibraryTests.\(UUID().uuidString)")!
        let good = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ChantSet(name: "Holy hour")))
        let stored: [Any] = [good, ["written": "by a later build"]]
        defaults.set(try JSONSerialization.data(withJSONObject: stored), forKey: "chantShelf.sets")

        let shelf = ChantShelfStore(defaults: defaults)
        #expect(shelf.sets.map(\.name) == ["Holy hour"])

        // A change writes the entry it could not read back beside the rest
        shelf.newSet(named: "Family prayer")
        let written = try #require(defaults.data(forKey: "chantShelf.sets"))
        let object = try JSONSerialization.jsonObject(with: written)
        let elements = try #require(object as? [Any])
        #expect(elements.count == 3)
        #expect(ChantShelfStore(defaults: defaults).sets.map(\.name) == ["Holy hour", "Family prayer"])
    }

    @Test func aShelfSetsAsideWhatIsNoListAtAll() {
        let defaults = UserDefaults(suiteName: "ChantLibraryTests.\(UUID().uuidString)")!
        let damaged = Data("not a list".utf8)
        defaults.set(damaged, forKey: "chantShelf.sets")
        let shelf = ChantShelfStore(defaults: defaults)
        #expect(shelf.sets.isEmpty)
        #expect(defaults.data(forKey: "chantShelf.sets.unreadable") == damaged)
    }

    @Test func theSpeedIsShownAsItSounds() {
        #expect(ChantPlayer.speedLabel(0.75) == "¾×")
        #expect(ChantPlayer.speedLabel(1) == "1×")
    }

    @Test func recentlyPlayedHoldsEachChantOnce() {
        let shelf = store()
        shelf.notePlayed("angelus")
        shelf.notePlayed("magnificat")
        shelf.notePlayed("angelus")
        #expect(shelf.recent.map(\.chantID) == ["angelus", "magnificat"])
    }

    // MARK: - The day

    @Test func theHoursTurnWhenThePrayerBooksDo() {
        for hour in 0..<24 {
            let now = day(2026, 10, 1, hour: hour)
            let next = day(2026, 10, 1, hour: hour).addingTimeInterval(3600)
            let chantTurns = ChantHour.present(at: now) != ChantHour.present(at: next)
            let bookTurns = PrayerBook.dayOrderMoment(at: now, short: true) != PrayerBook.dayOrderMoment(at: next, short: true)
            #expect(chantTurns == bookTurns, "at \(hour):00")
        }
    }

    @Test func theArcStandsTheHoursInTheirPlaces() {
        #expect(abs(ChantDayArc.position(of: day(2026, 10, 1, hour: 6)) - 0.125) < 0.001)
        #expect(abs(ChantDayArc.position(of: day(2026, 10, 1, hour: 12)) - 0.375) < 0.001)
        #expect(ChantDayArc.position(of: day(2026, 10, 1, hour: 4)) < 0.001)
        #expect(ChantHour.present(at: day(2026, 10, 1, hour: 21)) == .night)
        #expect(ChantHour.present(at: day(2026, 10, 1, hour: 2)) == .night)
        #expect(ChantHour.present(at: day(2026, 10, 1, hour: 7)) == .morning)
    }
}
