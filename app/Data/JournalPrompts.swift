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
                "What did Mary say yes to today?",
                "Where did you find Jesus after looking for Him?",
                "What is the good news you were given this week?",
            ]
        case .sorrowful:
            return [
                "What is the cup you would rather not drink?",
                "Who helped you carry something this week?",
                "What did you stand by, as Mary stood by the cross?",
            ]
        case .glorious:
            return [
                "What rose again in your life, after you thought it was over?",
                "Where did you feel the Holy Ghost give you words?",
                "What do you hope for, with Mary, in heaven?",
            ]
        case .luminous:
            return [
                "What are the empty jars you would bring to Cana?",
                "Where did you hear the Father say you are His?",
                "When was the last time you were fed at Mass?",
            ]
        case .sevenSorrows:
            return [
                "What sword has pierced your own heart?",
                "Whom did you meet on the way to Calvary this week?",
                "What have you had to lay in the tomb and leave with God?",
            ]
        }
    }

    /// Today's three, for the mysteries the schedule gives today.
    static var today: [String] {
        prompts(for: ScheduleService.categoryForToday())
    }
}
