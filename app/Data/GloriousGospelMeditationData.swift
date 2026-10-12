//
//  GloriousGospelMeditationData.swift
//  Lumen Viae
//
//  A bundled Gospel set for the Glorious Mysteries: the Resurrection, the
//  Ascension and Pentecost as St. Matthew and the Acts tell them, and for
//  the Assumption and the Coronation the passages the Church's liturgy
//  reads of Mary (the woman clothed with the sun, Judith's blessing, the
//  Canticle's "Arise, my love", the queen at the King's right hand), all
//  in the Douay-Rheims translation (Project Gutenberg #8300). Negative
//  IDs, so it can never collide with a server-assigned set.
//

import Foundation

enum GloriousGospelMeditationData {

    /// Sentinel ID for the bundled set — negative so it never collides
    /// with a server-assigned meditation set ID.
    static let setID = -4

    static let name = "The Gospel"
    static let category = "glorious"
    static let description = "The Gospel and the Acts of the Apostles at each mystery, and the Scriptures the Church reads of Mary's Assumption and crowning, in the Douay-Rheims translation."
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
            id: -401,
            title: nil,
            content: """
And in the end of the sabbath, when it began to dawn towards the first day of the week, came Mary Magdalen and the other Mary, to see the sepulchre. And behold there was a great earthquake. For an angel of the Lord descended from heaven and coming rolled back the stone and sat upon it. And his countenance was as lightning and his raiment as snow. And for fear of him, the guards were struck with terror and became as dead men. And the angel answering, said to the women: Fear not you: for I know that you seek Jesus who was crucified. He is not here. For he is risen, as he said. Come, and see the place where the Lord was laid. And going quickly, tell ye his disciples that he is risen. And behold he will go before you into Galilee. There you shall see him. Lo, I have foretold it to you. And they went out quickly from the sepulchre with fear and great joy, running to tell his disciples. And behold, Jesus met them, saying: All hail. But they came up and took hold of his feet and adored him. Then Jesus said to them: Fear not. Go, tell my brethren that they go into Galilee. There they shall see me.
""",
            author: "Douay-Rheims Bible",
            source: "Matthew 28:1-10",
            audioUrl: nil,
            mystery: MysteryData.glorious[0]
        ),
        Meditation(
            id: -402,
            title: nil,
            content: """
They therefore who were come together, asked him, saying: Lord, wilt thou at this time restore again the kingdom of Israel? But he said to them: It is not for you to know the time or moments, which the Father hath put in his own power: But you shall receive the power of the Holy Ghost coming upon you, and you shall be witnesses unto me in Jerusalem, and in all Judea, and Samaria, and even to the uttermost part of the earth. And when he had said these things, while they looked on, he was raised up: and a cloud received him out of their sight. And while they were beholding him going up to heaven, behold two men stood by them in white garments. Who also said: Ye men of Galilee, why stand you looking up to heaven? This Jesus who is taken up from you into heaven, shall so come as you have seen him going into heaven.
""",
            author: "Douay-Rheims Bible",
            source: "Acts 1:6-11",
            audioUrl: nil,
            mystery: MysteryData.glorious[1]
        ),
        Meditation(
            id: -403,
            title: nil,
            content: """
And when the days of the Pentecost were accomplished, they were all together in one place: And suddenly there came a sound from heaven, as of a mighty wind coming: and it filled the whole house where they were sitting. And there appeared to them parted tongues, as it were of fire: and it sat upon every one of them. And they were all filled with the Holy Ghost: and they began to speak with divers tongues, according as the Holy Ghost gave them to speak. Now there were dwelling at Jerusalem, Jews, devout men, out of every nation under heaven. And when this was noised abroad, the multitude came together, and were confounded in mind, because that every man heard them speak in his own tongue. And they were all amazed, and wondered, saying: Behold, are not all these that speak Galilean? And how have we heard, every man our own tongue wherein we were born? Parthians and Medes and Elamites and inhabitants of Mesopotamia, Judea, and Cappadocia, Pontus and Asia, Phrygia and Pamphylia, Egypt and the parts of Libya about Cyrene, and strangers of Rome, Jews also, and proselytes, Cretes, and Arabians: we have heard them speak in our own tongues the wonderful works of God.
""",
            author: "Douay-Rheims Bible",
            source: "Acts 2:1-11",
            audioUrl: nil,
            mystery: MysteryData.glorious[2]
        ),
        Meditation(
            id: -404,
            title: nil,
            content: """
And the temple of God was opened in heaven: and the ark of his testament was seen in his temple. And there were lightnings and voices and an earthquake and great hail.

And a great sign appeared in heaven: A woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.

And when she was come out to him, they all blessed her with one voice, saying: Thou art the glory of Jerusalem, thou art the joy of Israel, thou art the honour of our people: For thou hast done manfully, and thy heart has been strengthened, because thou hast loved chastity, and after thy husband hast not known any other: therefore also the hand of the Lord hath strengthened thee, and therefore thou shalt be blessed for ever.

Behold my beloved speaketh to me: Arise, make haste, my love, my dove, my beautiful one, and come. For winter is now past, the rain is over and gone. The flowers have appeared in our land, the time of pruning is come: the voice of the turtle is heard in our land: The fig tree hath put forth her green figs: the vines in flower yield their sweet smell. Arise, my love, my beautiful one, and come: My dove in the clefts of the rock, in the hollow places of the wall, shew me thy face, let thy voice sound in my ears: for thy voice is sweet, and thy face comely.
""",
            author: "Douay-Rheims Bible",
            source: "Apocalypse 11:19; 12:1; Judith 15:10-11; Canticle of Canticles 2:10-14",
            audioUrl: nil,
            mystery: MysteryData.glorious[3]
        ),
        Meditation(
            id: -405,
            title: nil,
            content: """
The daughters of kings have delighted thee in thy glory. The queen stood on thy right hand, in gilded clothing; surrounded with variety. Hearken, O daughter, and see, and incline thy ear: and forget thy people and thy father's house. And the king shall greatly desire thy beauty; for he is the Lord thy God, and him they shall adore. And the daughters of Tyre with gifts, yea, all the rich among the people, shall entreat thy countenance. All the glory of the king's daughter is within in golden borders, Clothed round about with varieties. After her shall virgins be brought to the king: her neighbours shall be brought to thee. They shall be brought with gladness and rejoicing: they shall be brought into the temple of the king.

I am the mother of fair love, and of fear, and of knowledge, and of holy hope. In me is all grace of the way and of the truth, in me is all hope of life and of virtue. Come over to me, all ye that desire me, and be filled with my fruits. For my spirit is sweet above honey, and my inheritance above honey and the honeycomb. My memory is unto everlasting generations. They that eat me, shall yet hunger: and they that drink me, shall yet thirst. He that hearkeneth to me, shall not be confounded: and they that work by me, shall not sin. They that explain me shall have life everlasting.
""",
            author: "Douay-Rheims Bible",
            source: "Psalm 44:10-16; Ecclesiasticus 24:24-31",
            audioUrl: nil,
            mystery: MysteryData.glorious[4]
        )
    ]
}
