//
//  MysteriesInScriptureData.swift
//  Lumen Viae
//
//  For Finding the Mysteries in Scripture: the one verse to carry into
//  each decade, and the seven graces of the Seven Sorrows. The passage
//  itself — ten verses to a mystery, seven to a sorrow — is the
//  Scriptural Rosary's (`ScripturalRosaryData`), so both pages read the
//  same Gospel.
//

import Foundation

enum MysteriesInScriptureData {

    /// A short key verse for each mystery, keyed by "<category>_<order>".
    /// Douay-Rheims translation.
    static let keyVerses: [String: String] = [
        // Joyful
        "joyful_1": "Behold thou shalt conceive in thy womb, and shalt bring forth a son; and thou shalt call his name Jesus. — Luke 1:31",
        "joyful_2": "Blessed art thou among women, and blessed is the fruit of thy womb. — Luke 1:42",
        "joyful_3": "And she brought forth her firstborn son, and wrapped him up in swaddling clothes, and laid him in a manger. — Luke 2:7",
        "joyful_4": "Now thou dost dismiss thy servant, O Lord, according to thy word in peace; because my eyes have seen thy salvation. — Luke 2:29-30",
        "joyful_5": "Did you not know, that I must be about my father's business? — Luke 2:49",

        // Sorrowful
        "sorrowful_1": "My Father, if it be possible, let this chalice pass from me. Nevertheless not as I will, but as thou wilt. — Matthew 26:39",
        "sorrowful_2": "Then therefore, Pilate took Jesus, and scourged him. — John 19:1",
        "sorrowful_3": "And platting a crown of thorns, they put it upon his head. — Matthew 27:29",
        "sorrowful_4": "And bearing his own cross, he went forth to that place which is called Calvary. — John 19:17",
        "sorrowful_5": "Father, into thy hands I commend my spirit. — Luke 23:46",

        // Glorious
        "glorious_1": "He is not here, for he is risen, as he said. — Matthew 28:6",
        "glorious_2": "And the Lord Jesus, after he had spoken to them, was taken up into heaven, and sitteth on the right hand of God. — Mark 16:19",
        "glorious_3": "And they were all filled with the Holy Ghost, and they began to speak with divers tongues. — Acts 2:4",
        "glorious_4": "He that is mighty hath done great things to me; and holy is his name. — Luke 1:49",
        "glorious_5": "And a great sign appeared in heaven: A woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars. — Apocalypse 12:1",

        // Luminous
        "luminous_1": "This is my beloved Son, in whom I am well pleased. — Matthew 3:17",
        "luminous_2": "Whatsoever he shall say to you, do ye. — John 2:5",
        "luminous_3": "The time is accomplished, and the kingdom of God is at hand: repent, and believe the gospel. — Mark 1:15",
        "luminous_4": "And he was transfigured before them. And his face did shine as the sun. — Matthew 17:2",
        "luminous_5": "Take ye, and eat. This is my body. — Matthew 26:26",

        // Seven Sorrows
        "seven_sorrows_1": "And thy own soul a sword shall pierce, that, out of many hearts, thoughts may be revealed. — Luke 2:35",
        "seven_sorrows_2": "Arise, and take the child and his mother, and fly into Egypt. — Matthew 2:13",
        "seven_sorrows_3": "Son, why hast thou done so to us? behold thy father and I have sought thee sorrowing. — Luke 2:48",
        "seven_sorrows_4": "And there followed him a great multitude of people, and of women, who bewailed and lamented him. — Luke 23:27",
        "seven_sorrows_5": "Now there stood by the cross of Jesus, his mother. — John 19:25",
        "seven_sorrows_6": "Joseph of Arimathea... came and took away the body of Jesus. — John 19:38",
        "seven_sorrows_7": "Now there was in the place where he was crucified, a garden; and in the garden a new sepulchre... There, therefore, they laid Jesus. — John 19:41-42"
    ]

    /// The key verse split from its citation: ("Behold thou shalt…", "Luke 1:31")
    static func keyVerse(_ key: String) -> (text: String, citation: String)? {
        guard let line = keyVerses[key] else { return nil }
        let parts = line.components(separatedBy: " \u{2014} ")
        guard parts.count >= 2 else { return (line, "") }
        return (parts.dropLast().joined(separator: " \u{2014} "), parts.last ?? "")
    }

    /// The seven graces Our Lady promises, by the tradition handed down
    /// through St. Bridget of Sweden, to those who honour her sorrows daily
    static let sevenGraces: [String] = [
        "Peace in their families.",
        "Enlightenment about the divine mysteries.",
        "Consolation in their pains, and her companionship in their work.",
        "Whatever they ask, so long as it accords with God's will and the good of their souls.",
        "Defence in their spiritual battles, and protection at every instant of their lives.",
        "Visible help at the moment of death — they will see the face of their Mother.",
        "Her Son's mercy for those who spread this devotion, that they may be brought from this life to eternal happiness."
    ]
}
