//
//  ChapelLiturgyTests.swift
//  Lumen Viae Tests
//
//  The Chapel's Liturgy tile names the day's Mass as a missal's index
//  does, by the first words of its Introit: the marks printed before the
//  text taken off, cut at the first stop, no more than three words, and
//  never ending on a small word that leaves the sentence hanging.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ChapelLiturgyTests {

    @Test func stopsBeforeAPrepositionOrConjunction() {
        #expect(TodayInChurch.incipit(of: "Gaudeámus omnes in Dómino, diem festum celebrántes") == "Gaudeámus omnes")
        #expect(TodayInChurch.incipit(of: "Dum clamárem ad Dóminum, exaudívit vocem meam") == "Dum clamárem")
        #expect(TodayInChurch.incipit(of: "Dóminus dixit ad me: Fílius meus es tu") == "Dóminus dixit")
    }

    @Test func keepsASmallWordInsideTheIncipit() {
        #expect(TodayInChurch.incipit(of: "Gaudéte in Dómino semper") == "Gaudéte in Dómino")
        #expect(TodayInChurch.incipit(of: "In médio Ecclésiæ apéruit os ejus") == "In médio Ecclésiæ")
    }

    @Test func knowsASmallWordWhateverItsCaseOrAccent() {
        #expect(TodayInChurch.incipit(of: "Gaudeámus omnes IN Dómino") == "Gaudeámus omnes")
        #expect(TodayInChurch.incipit(of: "Exaltáta est súper cælos") == "Exaltáta est")
    }

    @Test func takesOffTheMarksBeforeTheText() {
        #expect(TodayInChurch.incipit(of: "℣. Gaudeámus omnes in Dómino") == "Gaudeámus omnes")
        #expect(TodayInChurch.incipit(of: "Ant. Introíbo ad altáre Dei") == "Introíbo ad altáre")
    }

    @Test func cutsAtTheFirstStop() {
        #expect(TodayInChurch.incipit(of: "Exsúrge, quare obdórmis, Dómine?") == "Exsúrge")
    }

    @Test func keepsAtLeastOneWord() {
        #expect(TodayInChurch.incipit(of: "In") == "In")
        #expect(TodayInChurch.incipit(of: "   ") == nil)
    }
}
