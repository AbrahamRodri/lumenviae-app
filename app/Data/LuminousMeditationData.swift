//
//  LuminousMeditationData.swift
//  Lumen Viae
//
//  A bundled "Traditional Meditations" set for the Luminous Mysteries.
//  The backend has no luminous content yet, so this local set keeps the
//  picker and prayer flow working. It uses negative IDs so it can never
//  collide with server-assigned sets; when luminous sets land in the API,
//  this file can be removed and the picker will simply show them instead.
//

import Foundation

enum LuminousMeditationData {

    /// Sentinel ID for the bundled set — negative so it never collides
    /// with a server-assigned meditation set ID.
    static let setID = -1

    /// Summary row for the meditation picker.
    static let summary = MeditationSetSummary(
        id: setID,
        name: "Traditional Meditations",
        category: "luminous",
        description: "Classic meditations on the Mysteries of Light.",
        labels: ["Contemplative"]
    )

    /// The full set used by the prayer flow.
    static let set = MeditationSet(
        id: setID,
        name: "Traditional Meditations",
        category: "luminous",
        description: "Classic meditations on the Mysteries of Light.",
        labels: ["Contemplative"],
        meditations: meditations
    )

    // MARK: - Meditations

    private static let meditations: [Meditation] = [
        Meditation(
            id: -101,
            title: nil,
            content: """
At the banks of the Jordan, the sinless One goes down into the water among sinners. John hesitates — "I ought to be baptized by thee, and comest thou to me?" — yet Jesus insists, taking the lowest place so that every place might be made holy.

As He rises from the river, the heavens are opened: the Spirit descends as a dove, and the Father's voice is heard — "This is my beloved Son, in whom I am well pleased." Here the hidden life of Nazareth ends and the work of our redemption begins in the open.

In your own baptism those same words were spoken over you. Ask, in this decade, for a heart open to the Holy Spirit — docile, listening, ready to be led wherever the Father wills.
""",
            author: "Traditional",
            source: nil,
            audioUrl: nil,
            mystery: MysteryData.luminous[0]
        ),
        Meditation(
            id: -102,
            title: nil,
            content: """
At a village wedding the wine runs out, and it is Mary who notices before anyone else. She does not command her Son; she simply tells Him the need — "They have no wine" — and then turns to the servants with the last recorded words she speaks in Scripture: "Whatsoever he shall say to you, do ye."

Jesus has the jars filled with plain water, and the water blushes into wine — the first of His signs, worked at His Mother's quiet asking, before His hour had yet come.

Bring your own empty jars to this decade: the needs you carry, the joy that has run short. Ask for the grace to go to Jesus through Mary, and to do whatever He tells you.
""",
            author: "Traditional",
            source: nil,
            audioUrl: nil,
            mystery: MysteryData.luminous[1]
        ),
        Meditation(
            id: -103,
            title: nil,
            content: """
"The time is accomplished, and the kingdom of God is at hand: repent, and believe the gospel." With these words Jesus walks the roads of Galilee — healing the sick, forgiving sinners, calling ordinary men from their nets to become fishers of men.

The kingdom He proclaims is not a place on any map. It begins wherever a heart turns back to God: in the publican who beats his breast, in Zacchaeus who climbs down from his tree, in the woman forgiven much who loves much.

He proclaims it still, and to you. Ask in this decade for true repentance — the honest turning of your heart — and for trust in the mercy of God, who never tires of forgiving.
""",
            author: "Traditional",
            source: nil,
            audioUrl: nil,
            mystery: MysteryData.luminous[2]
        ),
        Meditation(
            id: -104,
            title: nil,
            content: """
Jesus leads Peter, James, and John up a high mountain apart. There He is transfigured before them: His face shines like the sun, His garments become white as light, and Moses and Elias appear speaking with Him — the Law and the Prophets bearing witness to their Lord.

From the bright cloud the Father speaks: "This is my beloved Son... hear ye him." Peter, overwhelmed, wants to build tents and stay; but the vision is given not as a resting place — it is strength for the road to Jerusalem, and the Cross.

The glory you glimpse in prayer is given for the same reason. Ask in this decade for the desire for holiness: to become, little by little, what you behold.
""",
            author: "Traditional",
            source: nil,
            audioUrl: nil,
            mystery: MysteryData.luminous[3]
        ),
        Meditation(
            id: -105,
            title: nil,
            content: """
On the night before He suffered, Jesus took bread into His holy and venerable hands, blessed it, broke it, and gave it to His disciples: "Take ye, and eat. This is my body." Then the chalice: "This is my blood of the new testament, which shall be shed for many unto remission of sins."

Knowing He was about to die, He found the way to remain: not a memory, not a symbol only, but Himself — Body, Blood, Soul, and Divinity — left to His Church until the end of the world, in the hands of every priest and on the tongue of every communicant.

Every Mass places you in that upper room. Ask in this decade for love of the Blessed Sacrament — for the faith to adore, and the hunger to receive Him worthily.
""",
            author: "Traditional",
            source: nil,
            audioUrl: nil,
            mystery: MysteryData.luminous[4]
        )
    ]
}
