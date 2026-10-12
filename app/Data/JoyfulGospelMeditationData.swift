//
//  JoyfulGospelMeditationData.swift
//  Lumen Viae
//
//  A bundled Gospel set for the Joyful Mysteries: the passage of St. Luke
//  each mystery is drawn from, whole, in the Douay-Rheims translation
//  (Challoner's revision, Project Gutenberg #8300). It is here so that a
//  Rosary with no signal and nothing downloaded still has a reading at
//  every decade, and so the Gospel filter on the mysteries' page is never
//  empty. Negative IDs, so it can never collide with a server-assigned set.
//

import Foundation

enum JoyfulGospelMeditationData {

    /// Sentinel ID for the bundled set — negative so it never collides
    /// with a server-assigned meditation set ID.
    static let setID = -2

    static let name = "The Gospel"
    static let category = "joyful"
    static let description = "The Gospel of St. Luke, read whole at each mystery, in the Douay-Rheims translation."
    static let labels = ["Scriptural"]

    /// Summary row for the meditation picker.
    static let summary = MeditationSetSummary(
        id: setID,
        name: name,
        category: category,
        description: description,
        labels: labels
    )

    /// The full set used by the prayer flow.
    static let set = MeditationSet(
        id: setID,
        name: name,
        category: category,
        description: description,
        labels: labels,
        meditations: meditations
    )

    // MARK: - Meditations

    private static let meditations: [Meditation] = [
        Meditation(
            id: -201,
            title: nil,
            content: """
And in the sixth month, the angel Gabriel was sent from God into a city of Galilee, called Nazareth, To a virgin espoused to a man whose name was Joseph, of the house of David: and the virgin's name was Mary. And the angel being come in, said unto her: Hail, full of grace, the Lord is with thee: blessed art thou among women. Who having heard, was troubled at his saying and thought with herself what manner of salutation this should be. And the angel said to her: Fear not, Mary, for thou hast found grace with God. Behold thou shalt conceive in thy womb and shalt bring forth a son: and thou shalt call his name Jesus. He shall be great and shall be called the Son of the Most High. And the Lord God shall give unto him the throne of David his father: and he shall reign in the house of Jacob for ever. And of his kingdom there shall be no end. And Mary said to the angel: How shall this be done, because I know not man? And the angel answering, said to her: The Holy Ghost shall come upon thee and the power of the Most High shall overshadow thee. And therefore also the Holy which shall be born of thee shall be called the Son of God. And behold thy cousin Elizabeth, she also hath conceived a son in her old age: and this is the sixth month with her that is called barren. Because no word shall be impossible with God. And Mary said: Behold the handmaid of the Lord: be it done to me according to thy word. And the angel departed from her.
""",
            author: "Douay-Rheims Bible",
            source: "Luke 1:26-38",
            audioUrl: nil,
            mystery: MysteryData.joyful[0]
        ),
        Meditation(
            id: -202,
            title: nil,
            content: """
And Mary rising up in those days, went into the hill country with haste into a city of Juda. And she entered into the house of Zachary and saluted Elizabeth. And it came to pass that when Elizabeth heard the salutation of Mary, the infant leaped in her womb. And Elizabeth was filled with the Holy Ghost. And she cried out with a loud voice and said: Blessed art thou among women and blessed is the fruit of thy womb. And whence is this to me that the mother of my Lord should come to me? For behold as soon as the voice of thy salutation sounded in my ears, the infant in my womb leaped for joy. And blessed art thou that hast believed, because those things shall be accomplished that were spoken to thee by the Lord. And Mary said: My soul doth magnify the Lord. And my spirit hath rejoiced in God my Saviour. Because he hath regarded the humility of his handmaid: for behold from henceforth all generations shall call me blessed. Because he that is mighty hath done great things to me: and holy is his name. And his mercy is from generation unto generations, to them that fear him. He hath shewed might in his arm: he hath scattered the proud in the conceit of their heart. He hath put down the mighty from their seat and hath exalted the humble. He hath filled the hungry with good things: and the rich he hath sent empty away. He hath received Israel his servant, being mindful of his mercy. As he spoke to our fathers: to Abraham and to his seed for ever. And Mary abode with her about three months. And she returned to her own house.
""",
            author: "Douay-Rheims Bible",
            source: "Luke 1:39-56",
            audioUrl: nil,
            mystery: MysteryData.joyful[1]
        ),
        Meditation(
            id: -203,
            title: nil,
            content: """
And it came to pass that in those days there went out a decree from Caesar Augustus that the whole world should be enrolled. This enrolling was first made by Cyrinus, the governor of Syria. And all went to be enrolled, every one into his own city. And Joseph also went up from Galilee, out of the city of Nazareth, into Judea, to the city of David, which is called Bethlehem: because he was of the house and family of David. To be enrolled with Mary his espoused wife, who was with child. And it came to pass that when they were there, her days were accomplished that she should be delivered. And she brought forth her first born son and wrapped him up in swaddling clothes and laid him in a manger: because there was no room for them in the inn. And there were in the same country shepherds watching and keeping the night watches over their flock. And behold an angel of the Lord stood by them and the brightness of God shone round about them: and they feared with a great fear. And the angel said to them: Fear not; for, behold, I bring you good tidings of great joy that shall be to all the people: For, this day is born to you a Saviour, who is Christ the Lord, in the city of David. And this shall be a sign unto you. You shall find the infant wrapped in swaddling clothes and laid in a manger. And suddenly there was with the angel a multitude of the heavenly army, praising God and saying: Glory to God in the highest: and on earth peace to men of good will. And it came to pass, after the angels departed from them into heaven, the shepherds said one to another: Let us go over to Bethlehem and let us see this word that is come to pass, which the Lord hath shewed to us. And they came with haste: and they found Mary and Joseph, and the infant lying in the manger. And seeing, they understood of the word that had been spoken to them concerning this child. And all that heard wondered: and at those things that were told them by the shepherds. But Mary kept all these words, pondering them in her heart. And the shepherds returned, glorifying and praising God for all the things they had heard and seen, as it was told unto them.
""",
            author: "Douay-Rheims Bible",
            source: "Luke 2:1-20",
            audioUrl: nil,
            mystery: MysteryData.joyful[2]
        ),
        Meditation(
            id: -204,
            title: nil,
            content: """
And after the days of her purification, according to the law of Moses, were accomplished, they carried him to Jerusalem, to present him to the Lord: As it is written in the law of the Lord: Every male opening the womb shall be called holy to the Lord: And to offer a sacrifice, according as it is written in the law of the Lord, a pair of turtledoves or two young pigeons: And behold there was a man in Jerusalem named Simeon: and this man was just and devout, waiting for the consolation of Israel. And the Holy Ghost was in him. And he had received an answer from the Holy Ghost, that he should not see death before he had seen the Christ of the Lord. And he came by the Spirit into the temple. And when his parents brought in the child Jesus, to do for him according to the custom of the law, He also took him into his arms and blessed God and said Now thou dost dismiss thy servant, O Lord, according to thy word in peace: Because my eyes have seen thy salvation, Which thou hast prepared before the face of all peoples: A light to the revelation of the Gentiles and the glory of thy people Israel. And his father and mother were wondering at those things which were spoken concerning him. And Simeon blessed them and said to Mary his mother: Behold this child is set for the fall and for the resurrection of many in Israel and for a sign which shall be contradicted. And thy own soul a sword shall pierce, that, out of many hearts thoughts may be revealed.
""",
            author: "Douay-Rheims Bible",
            source: "Luke 2:22-35",
            audioUrl: nil,
            mystery: MysteryData.joyful[3]
        ),
        Meditation(
            id: -205,
            title: nil,
            content: """
And his parents went every year to Jerusalem, at the solemn day of the pasch. And when he was twelve years old, they going up into Jerusalem, according to the custom of the feast, And having fulfilled the days, when they returned, the child Jesus remained in Jerusalem. And his parents knew it not. And thinking that he was in the company, they came a day's journey and sought him among their kinsfolks and acquaintance. And not finding him, they returned into Jerusalem, seeking him. And it came to pass, that, after three days, they found him in the temple, sitting in the midst of the doctors, hearing them and asking them questions. And all that heard him were astonished at his wisdom and his answers. And seeing him, they wondered. And his mother said to him: Son, why hast thou done so to us? Behold thy father and I have sought thee sorrowing. And he said to them: How is it that you sought me? Did you not know that I must be about my father's business? And they understood not the word that he spoke unto them. And he went down with them and came to Nazareth and was subject to them. And his mother kept all these words in her heart. And Jesus advanced in wisdom and age and grace with God and men.
""",
            author: "Douay-Rheims Bible",
            source: "Luke 2:41-52",
            audioUrl: nil,
            mystery: MysteryData.joyful[4]
        )
    ]
}
