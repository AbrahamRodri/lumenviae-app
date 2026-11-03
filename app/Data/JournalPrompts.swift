//
//  JournalPrompts.swift
//  Lumen Viae
//
//  Three questions to start a first reflection, tied to the mysteries
//  of the day. The journal's empty page once said only that it was
//  empty; a question is a door. Each prompt is one plain question about
//  one scene, in the words the app uses for that scene elsewhere, and
//  none of them assumes the reader has prayed today.
//

import Foundation

enum JournalPrompts {

    /// The three starter questions for a set of mysteries.
    static func prompts(for category: MysteryCategory) -> [String] {
        switch category {
        case .joyful:
            return [
                String(localized: "What did Mary say yes to today?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "Where did you find Jesus after looking for Him?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "What is the good news you were given this week?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title")
            ]
        case .sorrowful:
            return [
                String(localized: "What is the cup you would rather not drink?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "Who helped you carry something this week?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "What did you stand by, as Mary stood by the cross?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title")
            ]
        case .glorious:
            return [
                String(localized: "What rose again in your life, after you thought it was over?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "Where did you feel the Holy Ghost give you words?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "What do you hope for, with Mary, in heaven?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title")
            ]
        case .luminous:
            return [
                String(localized: "What are the empty jars you would bring to Cana?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "Where did you hear the Father say you are His?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "When was the last time you were fed at Mass?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title")
            ]
        case .sevenSorrows:
            return [
                String(localized: "What sword has pierced your own heart?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "Whom did you meet on the way to Calvary this week?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title"),
                String(localized: "What have you had to lay in the tomb and leave with God?", comment: "Journal, empty page: a starter question on today's mysteries; tapped, it begins a reflection with the question as its title")
            ]
        }
    }

    /// Today's three, for the mysteries the schedule gives today.
    static var today: [String] {
        prompts(for: ScheduleService.categoryForToday())
    }
}
