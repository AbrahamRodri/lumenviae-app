//
//  SorrowfulEmmerichMeditationData.swift
//  Lumen Viae
//
//  A bundled set for the Sorrowful Mysteries, cut from The Dolorous
//  Passion of Our Lord Jesus Christ (Anne Catherine Emmerich, in the
//  Burns & Lambert English of 1862, Project Gutenberg #10866), the book
//  the Spiritual Reading shelf carries whole. Each meditation is a few
//  paragraphs of the chapter on its mystery, verbatim. Negative IDs, so
//  it can never collide with a server-assigned set.
//

import Foundation

enum SorrowfulEmmerichMeditationData {

    /// Sentinel ID for the bundled set — negative so it never collides
    /// with a server-assigned meditation set ID.
    static let setID = -3

    static let name = "Anne Catherine Emmerich"
    static let category = "sorrowful"
    static let description = "Scenes from The Dolorous Passion of Our Lord Jesus Christ, the visions of Anne Catherine Emmerich, in the 1862 English translation."
    static let labels = ["Contemplative"]

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
            id: -301,
            title: nil,
            content: """
His sorrow and anguish of soul continued to increase, and he was trembling all over when he entered the grotto to pray, like a wayworn traveller hurriedly seeking shelter from a sudden storm, but the awful visions pursued him even there, and became more and more clear and distinct. Alas! this small cavern appeared to contain the awful picture of all the sins which had been or were to be committed from the fall of Adam to the end of the world, and of the punishment which they deserved. It was here, on Mount Olivet, that Adam and Eve took refuge when drive out of Paradise to wander homeless on earth, and they had wept and bewailed themselves in this very grotto.

He fell on his face, overwhelmed with unspeakable sorrow, and all the sins of the world displayed themselves before him, under countless forms and in all their real deformity. He took them all upon himself, and in his prayer offered his own adorable Person to the justice of his Heavenly Father, in payment for so awful a debt. But Satan, who was enthroned amid all these horrors, and even filled with diabolical joy at the sight of them, let loose his fury against Jesus, and displayed before the eyes of his soul increasingly awful visions, at the same time addressing his adorable humanity in words such as these: 'Takest thou even this sin upon thyself? Art thou willing to bear its penalty? Art thou prepared to satisfy for all these sins?'

I saw Jesus still praying in the grotto, struggling against the repugnance to suffering which belonged to human nature, and abandoning himself wholly to the will of this Eternal Father. Here the abyss opened before him, and he had a vision of the first part of Limbo. He saw Adam and Eve, the patriarchs, prophets, and just men, the parents of his Mother, and John the Baptist, awaiting his arrival in the lower world with such intense longing, that the sight strengthened and gave fresh courage to his loving heart. His death was to open Heaven to these captives,--his death was to deliver them out of that prison in which they were languishing in eager hope! When Jesus had, with deep emotion, looked upon these saints of antiquity, angels presented to him all the bands of saints of future ages, who, joining their labours to the merits of his Passion, were, through him, to be united to his Heavenly Father. Most beautiful and consoling was this vision, in which he beheld the salvation and sanctification flowing forth in ceaseless streams from the fountain of redemption opened by his death.

Jesus having freely accepted the chalice of his sufferings, and received new strength, remained some minutes longer in the grotto, absorbed in calm meditation, and returning thanks to his Heavenly Father. He was still in deep affliction of spirit, but supernaturally comforted to such a degree as to be able to go to his disciples without tottering as he walked, or bending beneath the weight of his sufferings. His countenance was still pale and altered, but his step was firm and determined. He had wiped his face with a linen cloth, and rearranged his hair, which hung about his shoulders, matted together and damp with blood.
""",
            author: "Anne Catherine Emmerich",
            source: "The Dolorous Passion, Chapter I",
            audioUrl: nil,
            mystery: MysteryData.sorrowful[0]
        ),
        Meditation(
            id: -302,
            title: nil,
            content: """
Jesus trembled and shuddered as he stood before the pillar, and took off his garments as quickly as he could, but his hands were bloody and swollen. The only return he made when his brutal executioners struck and abused him was, to pray for them in the most touching manner: he turned his face once towards his Mother, who was standing overcome with grief; this look quite unnerved her: she fainted, and would have fallen, had not the holy women who were there supported her. Jesus put his arms round the pillar, and when his hands were thus raised, the archers fastened them to the iron ring which was at the top of the pillar; they then dragged his arms to such a height that his feet, which were tightly bound to the base of the pillar, scarcely touched the ground. Thus was the Holy of Holies violently stretched, without a particle of clothing, on a pillar used for the punishment of the greatest criminals; and then did two furious ruffians who were thirsting for his blood begin in the most barbarous manner to scourge his sacred body from head to foot. The whips or scourges which they first made use of appeared to me to be made of a species of flexible white wood, but perhaps they were composed of the sinews of the ox, or of strips of leather.

During the time of the scourging of our Lord, I saw weeping angels approach him many times; I likewise heard the prayers he constantly addressed to his Father for the pardon of our sins--prayers which never ceased during the whole time of the infliction of this cruel punishment. Whilst he lay bathed in his blood I saw an angel present to him a vase containing a bright-looking beverage which appeared to reinvigorate him in a certain degree. The archers soon returned, and after giving him some blows with their sticks, bade him rise and follow them. He raised himself with the greatest difficulty, as his trembling limbs could scarcely support the weight of this body; they did not give him sufficient time to put on his clothes, but threw his upper garment over his naked shoulders and led him from the pillar to the guardhouse, where he wiped the blood which trickled down his face with a corner of his garment. When he passed before the benches on which the High Priests were seated, they cried out, 'Put him to death! Crucify him! Crucify him!' and then turned away disdainfully. The executioners led him into the interior of the guardhouse, which was filled with slaves, archers, hodmen, and the very dregs of the people, but there were no soldiers.
""",
            author: "Anne Catherine Emmerich",
            source: "The Dolorous Passion, Chapter XXII",
            audioUrl: nil,
            mystery: MysteryData.sorrowful[1]
        ),
        Meditation(
            id: -303,
            title: nil,
            content: """
In the middle of the court there stood the fragment of a pillar, and on it was placed a very low stool which these cruel men maliciously covered with sharp flints and bits of broken potsherds. Then they tore off the garments of Jesus, thereby reopening all his wounds; threw over his shoulders an old scarlet mantle which barely reached his knees; dragged him to the seat prepared, and pushed him roughly down upon it, having first placed the crown of thorns upon his head. The crown of thorns was made of three branches plaited together, the greatest part of the thorns being purposely turned inwards so as to pierce our Lord's head. Having first placed these twisted branches on his forehead, they tied them tightly together at the back of his head, and no sooner was this accomplished to their satisfaction than they put a large reed into his hand, doing all with derisive gravity as if they were really crowning him king. They then seized the reed, and struck his head so violently that his eyes were filled with blood; they knelt before him, derided him, spat in his face, and buffeted him, saying at the same time, 'Hail, King of the Jews!' Then they threw down his stool, pulled him up again from the ground on which he had fallen, and reseated him with the greatest possible brutality.

It is quite impossible to describe the cruel outrages which were thought of and perpetrated by these monsters under human form. The sufferings of Jesus from thirst, caused by the fever which his wounds and sufferings had brought on, were intense. He trembled all over, his flesh was torn piecemeal, his tongue contracted, and the only refreshment he received was the blood which trickled from his head on to his parched lips. This shameful scene was protracted a full half-hour, and the Roman soldiers continued during the whole time to applaud and encourage the perpetration of still greater outrages.
""",
            author: "Anne Catherine Emmerich",
            source: "The Dolorous Passion, Chapter XXVI",
            audioUrl: nil,
            mystery: MysteryData.sorrowful[2]
        ),
        Meditation(
            id: -304,
            title: nil,
            content: """
When Pilate left the tribunal a portion of the soldiers followed him, and were drawn up in files before the palace; a few accompanying the criminals. Eight-and-twenty armed Pharisees came to the forum on horseback, in order to accompany Jesus to the place of execution, and among these were the six enemies of Jesus, who had assisted in arresting him in the Garden of Olives. The archers led Jesus into the middle of the court, the slaves threw down the cross at his feet, and the two arms were forthwith tied on to the centre piece. Jesus knelt down by its side, encircled it with his sacred arms, and kissed it three times, addressing, at the same time, a most touching prayer of thanksgiving to his Heavenly Father for that work of redemption which he had begun. It was the custom among pagans for the priest to embrace a new altar, and Jesus in like manner embraced his cross, that august altar on which the bloody and expiatory sacrifice was about to be offered. The archers soon made him rise, and then kneel down again, and almost without any assistance, place the heavy cross on his right shoulder, supporting its great weight with his right hand. I saw angels come to his assistance, otherwise he would have been unable even to raise it from the ground. Whilst he was on his knees, and still praying, the executioners put the arms of the crosses, which were a little curbed and not as yet fastened to the centre pieces, on the backs of the two thieves, and tied their hands tightly to them. The middle parts of the crosses were carried by slaves, as the transverse pieces were not to be fastened to them until just before the time of execution. The trumpet sounded to announce the departure of Pilate's horsemen, and one of the Pharisees belonging to the escort came up to Jesus, who was still kneeling, and said, 'Rise, we have had a sufficiency of thy fine speeches; rise and set off.' They pulled him roughly up, for he was totally unable to rise without assistance, and he then felt upon his shoulders the weight of that cross which we must carry after him, according to his true and holy command to follow him. Thus began that triumphant march of the King of Kings, a march so ignominious on earth, and so glorious in heaven.
""",
            author: "Anne Catherine Emmerich",
            source: "The Dolorous Passion, Chapter XXX",
            audioUrl: nil,
            mystery: MysteryData.sorrowful[3]
        ),
        Meditation(
            id: -305,
            title: nil,
            content: """
The hour of our Lord was at last come; his death-struggle had commenced; a cold sweat overspread every limb. John stood at the foot of the Cross, and wiped the feet of Jesus with his scapular. Magdalen was crouched to the ground in a perfect frenzy of grief behind the Cross. The Blessed Virgin stood between Jesus and the good thief, supported by Salome and Mary of Cleophas, with her eyes rivetted on the countenance of her dying Son. Jesus then said: 'It is consummated;' and, raising his head, cried out in a loud voice, 'Father, into thy hands I commend my spirit.' These words, which he uttered in a clear and thrilling tone, resounded through heaven and earth; and a moment after, he bowed down his head and gave up the ghost. I saw his soul, under the appearance of a bright meteor, penetrate the earth at the foot of the Cross. John and the holy women fell prostrate on the ground. The centurion Abenadar had kept his eyes steadfastly fixed on the disfigured countenance of our Lord, and was perfectly overwhelmed by all that had taken place. When our Lord pronounced his last words, before expiring, in a loud tone, the earth trembled, and the rock of Calvary burst asunder, forming a deep chasm between the Cross of our Lord and that of Gesmas. The voice of God--that solemn and terrible voice--had re-echoed through the whole universe; it had broken the solemn silence which then pervaded all nature. All was accomplished. The soul of our Lord had left his body: his last cry had filled every breast with terror. The convulsed earth had paid homage to its Creator: the sword of grief had pierced the hearts of those who loved him. This moment was the moment of grace for Abenadar: his horse trembled under him; his heart was touched; it was rent like the hard rock; he threw his lance to a distance, struck his breast, and cried out: 'Blessed be the Most High God, the God of Abraham, of Isaac, and of Jacob; indeed this Man was the Son of God!' His words convinced many among the soldiers, who followed his example, and were likewise converted.

What words can, alas, express the deep grief of the Blessed Virgin? Her eyes closed, a death-like tint overspread her countenance; unable to stand, she fell to the ground, but was soon lifted up, and supported by John, Magdalen, and the others. She looked once more upon her beloved Son--that Son whom she had conceived by the Holy Ghost, the flesh of her flesh, the bone of her bone, the heart of her heart--hanging on a cross between two thieves; crucified, dishonoured, contemned by those whom he came on earth to save; and well might she at this moment be termed 'the queen of martyrs.'
""",
            author: "Anne Catherine Emmerich",
            source: "The Dolorous Passion, Chapter XLV",
            audioUrl: nil,
            mystery: MysteryData.sorrowful[4]
        )
    ]
}
