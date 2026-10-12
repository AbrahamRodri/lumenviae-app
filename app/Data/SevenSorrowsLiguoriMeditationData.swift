//
//  SevenSorrowsLiguoriMeditationData.swift
//  Lumen Viae
//
//  A bundled set for the Seven Sorrows, cut from St. Alphonsus Liguori's
//  Reflections on Each of the Seven Dolors of Mary in The Glories of Mary
//  (the 1852 Dunigan translation, Project Gutenberg #72411), the book the
//  Spiritual Reading shelf carries whole. Each meditation is the opening
//  of its reflection, verbatim, with the edition's footnote marks taken
//  out. Negative IDs, so it can never collide with a server-assigned set.
//

import Foundation

enum SevenSorrowsLiguoriMeditationData {

    /// Sentinel ID for the bundled set — negative so it never collides
    /// with a server-assigned meditation set ID.
    static let setID = -5

    static let name = "St. Alphonsus Liguori"
    static let category = "seven_sorrows"
    static let description = "St. Alphonsus Liguori's reflections on each of the seven sorrows of Mary, from The Glories of Mary, in the 1852 English translation."
    static let labels = ["Considerations"]

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
            id: -501,
            title: nil,
            content: """
In this valley of tears, every man is born to weep, and every one must suffer those afflictions that daily befall him. But how much more miserable would life be, if every one knew also the future evils which are to afflict him! Too unhappy would he be, says Seneca, whose fate was such. The Lord exercises this compassion towards us, namely, that he does not make known to us the crosses that await us; that if we are to suffer them, at least we may suffer them only once. But he did not exercise this compassion with Mary, who, because God wished her to be queen of dolors, and in all things like his Son, had to see always before her eyes, and to suffer continually all the sorrows that awaited her; and those were the sufferings of the passion and death of her beloved Jesus. For St. Simeon in the temple, after having received the divine child in his arms, predicted to her that this child was to be the mark for all the opposition and persecution of men: “Set for a sign which shall be contradicted;” and that therefore the sword of sorrow should pierce her soul: “And thy own soul a sword shall pierce.”

The holy Virgin herself said to St. Matilda, that at this announcement of St. Simeon all her joy was changed into sorrow. For, as it was revealed to St. Theresa, the blessed mother, although she knew before this that the life of her Son would be sacrificed for the salvation of the world, yet she then learned more particularly and distinctly the sufferings and cruel death that awaited her poor Son. She knew that he would be contradicted in all things. Contradicted in doctrine; for instead of being believed, he would be esteemed a blasphemer for teaching that he was the Son of God, as the impious Caiaphas declared him to be, saying: “He hath blasphemed, he is guilty of death.” Contradicted in his reputation, for he was noble, of royal lineage, and was despised as a peasant: “Is not this the carpenter’s son?” “Is not this the carpenter, the son of Mary?” He was wisdom itself, and was treated as an ignorant man: “How doth this man know letters, having never learned?” As a false prophet: “And they blindfolded him and smote his face ... saying: Prophesy who is this that struck thee.” He was treated as a madman: “He is mad, why hear you him?” As a wine-bibber, a glutton, and a friend of sinners: “Behold a man that is a glutton, and a drinker of wine, a friend of publicans and sinners.” As a sorcerer: “By the prince of devils he casteth out devils.” As a heretic and possessed person: “Do we not say well of thee, that thou art a Samaritan, and hast a devil?” In a word, Jesus was considered as so bad and notorious a man, that no trial was necessary to condemn him, as the Jews said to Pilate: “If he were not a malefactor, we would not have delivered him up to thee.” He was contradicted in his soul, for even his eternal Father, in order to give place to the divine justice, contradicted him by not wishing to hear him when he prayed to him, saying: “Father, if it be possible, let this chalice pass from me;” and abandoned him to fear, weariness, and sadness, so that our afflicted Lord said: “My soul is sorrowful even unto death.” His interior suffering even caused him to sweat blood. Contradicted and persecuted, in a word, in his body and his life, for he was tortured in all his sacred members: in his hands, in his feet, in his face, in his head, in his whole body, till, drained to the last drop of his blood, he died an ignominious death on the cross.
""",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary, on the First Dolor",
            audioUrl: nil,
            mystery: MysteryData.sevenSorrows[0]
        ),
        Meditation(
            id: -502,
            title: nil,
            content: """
As the stag, wounded by an arrow, carries the pain with him wherever he goes, because he carries with him the arrow that has wounded him; thus the divine mother, after the prophecy of St. Simeon, as we saw in our consideration of the first grief, always carried her sorrow with her by the continual remembrance of the passion of her Son. Ailgrin, explaining this passage of the Canticles, “The hairs of thy head as the purple of the king bound in the channel,” says: These hairs of Mary were her continual thoughts of the passion of Jesus, which kept always before her eyes the blood which was one day to flow from his wounds. Thy mind, oh Mary, and thy thoughts tinged in the blood of the passion of our Lord, were always moved with sorrow as if they actually saw the blood flowing from his wounds. Thus her Son himself was that arrow in the heart of Mary, who, the more worthy of love he showed himself to her, always wounded her the more with the sorrowful thought that she should lose him by so cruel a death. Let us now pass to the consideration of the second sword of sorrow which wounded Mary, in the flight of her infant Jesus into Egypt from the persecution of Herod.

Herod having heard that the expected Messiah was born, foolishly feared that the new-born King would deprive him of his kingdom. Hence St. Fulgentius, reproving him for his folly, thus says: “Why, oh Herod, art thou thus disturbed? This King who is born has not come to conquer kings by arms, but to subjugate them, in a wonderful manner, by his death.” The impious Herod, therefore, waited to learn from the holy magi where the King was born, that he might take from him his life; but finding himself deceived by the magi, he ordered all the infants that could be found in the neighborhood of Bethlehem to be put to death. But an angel appeared in a dream to St. Joseph, and said to him: “Arise, and take the child and his mother, and fly into Egypt.” According to Gerson, immediately, on that very night, Joseph made this command known to Mary; and taking the infant Jesus, they commenced their journey, as it seems clearly from the Gospel itself: “Who arose and took the child and his mother by night, and retired into Egypt.” Oh God, as blessed Albertus Magnus says in the name of Mary, must he, then, who came to save men flee from men? “Debet fugere qui salvator est mundi?” And then the afflicted Mary knew that already the prophecy of Simeon, regarding her Son, was beginning to be verified: “He is set for a sign which shall be contradicted.” Seeing that scarcely is he born, when he is persecuted to death. What suffering it must have been to the heart of Mary, writes St. John Chrysostom, to hear the tidings of that cruel exile of herself with her Son! Flee from thy friends to strangers, from the holy temple of the only true God, to the temples of demons. What greater tribulation than that a new-born child, clinging to its mother’s bosom, should be forced to fly with the mother herself!
""",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary, on the Second Dolor",
            audioUrl: nil,
            mystery: MysteryData.sevenSorrows[1]
        ),
        Meditation(
            id: -503,
            title: nil,
            content: """
St. James the Apostle has said, that our perfection consists in the virtue of patience. “And patience hath a perfect work, that you may be perfect and entire, failing in nothing.” The Lord having then given us the Virgin Mary as an example of perfection, it was necessary that she should be laden with sorrows, that in her we might admire and imitate her heroic patience. The dolor that we are this day to consider is one of the greatest which our divine mother suffered during her life, namely, the loss of her Son in the temple. He who is born blind is little sensible of the pain of being deprived of the light of day; but to him who has once had sight and enjoyed the light, it is a great sorrow to find himself deprived of it by blindness. And thus it is with those unhappy souls who, being blinded by the mire of this earth, have but little knowledge of God, and therefore scarcely feel pain at not finding him. On the contrary, the man who, illuminated with celestial light, has been made worthy to find by love the sweet presence of the highest good, oh God, how he mourns when he finds himself deprived of it! From this we can judge how painful must have been to Mary, who was accustomed to enjoy constantly the sweet presence of Jesus, that third sword which wounded her, when she lost him in Jerusalem, and was separated from him for three days.

In the second chapter of St. Luke we read that the blessed Virgin, being accustomed to visit the temple every year at the paschal season, with Joseph her spouse and Jesus, once went when he was about twelve years old, and Jesus remained in Jerusalem, though she was not aware of it, for she thought he was in company with others. When she reached Nazareth she inquired for her Son, and not finding him there, she returned immediately to Jerusalem to seek him, but did not succeed until after three days. Now let us imagine what distress that afflicted mother must have experienced in those three days in which she was searching everywhere for her Son, with the spouse in the Canticles: “Have you seen him whom my soul loveth?” But she could hear no tidings of him. Oh, with how much greater tenderness must Mary, overcome with fatigue, and yet not having found her beloved Son, have repeated those words of Ruben, concerning his brother Joseph: The boy doth not appear, and whither shall I go? “Puer non comparet, et ego quo ibo?” My Jesus doth not appear, and I know not what to do that I may find him; but where shall I go without my treasure? Weeping continually, she repeated during these three days with David: “My tears have been my bread day and night, whilst it is said to me daily, Where is thy God?” Wherefore Pelbart with reason says, that during those nights the afflicted mother had no rest, but wept and prayed without ceasing to God, that he would enable her to find her Son. And, according to St. Bernard, often during that time did she repeat to her Son himself the words of the spouse: “Show me where thou feedest, where thou liest in the mid-day, lest I begin to wander.” My Son, tell me where thou art, that I may no longer wander, seeking thee in vain.
""",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary, on the Third Dolor",
            audioUrl: nil,
            mystery: MysteryData.sevenSorrows[2]
        ),
        Meditation(
            id: -504,
            title: nil,
            content: """
St. Bernardine says, that to form an idea of the grief of Mary in losing her Jesus by death, it is necessary to consider the love that this mother bore to this her Son. All mothers feel the sufferings of their children as their own. Hence the woman of Chanaan, when she prayed the Saviour to deliver her daughter from the devil that tormented her, said to him, that he should have pity on the mother rather than on the daughter: “Have mercy on me, oh Lord, thou son of David, my daughter is grievously troubled by a devil.” But what mother ever loved a child so much as Mary loved Jesus? He was her only child, reared amidst so many troubles and pains; a most amiable child, and most loving to his mother; a Son, who was at the same time her Son and her God; who came on earth to kindle in the hearts of all the holy fire of divine love, as he himself declared: “I am come to cast fire on the earth, and what will I but that it be kindled?” Let us consider how he must have inflamed that pure heart of his holy mother, so free from every earthly affection. In a word, the blessed Virgin herself said to St. Bridget, that through love her heart and the heart of her Son was one: “Unum erat cor meum, et cor filii mei.” That blending of handmaid and mother, of Son and God, kindled in the heart of Mary a fire composed of a thousand flames. But afterwards, at the time of the passion, this flame of love was changed into a sea of sorrow. Hence St. Bernardine says: All the sorrows of the world united would not be equal to the sorrow of the glorious Mary. Yes, because this mother, as St. Lawrence Justinian writes: The more tenderly she loved, was the more deeply wounded. The greater the tenderness with which she loved him, the greater was her grief at the sight of his sufferings, especially when she met her Son, after he had already been condemned, going to death at the place of punishment, bearing the cross. And this is the fourth sword of sorrow which to-day we have to consider.

The blessed Virgin revealed to St. Bridget, that at the time when the passion of our Lord was drawing nigh, her eyes were always filled with tears, as she thought of her beloved Son whom she was about to lose on this earth. Therefore, as she also said, a cold sweat covered her body from the fear that seized her at that prospect of approaching suffering. Behold, the appointed day at length arrived, and Jesus came in tears to take leave of his mother before he went to death. St. Bonaventure, contemplating Mary on that night, says: Thou didst spend it without sleep, and while others slept, thou didst remain watching. Morning having arrived, the disciples of Jesus Christ came to this afflicted mother, one, to bring her this tidings, another, that; but all tidings of sorrow, for in her were then verified the words of Jeremias: “Weeping, she hath wept in the night, and her tears are on her cheeks; there is none to comfort her of all them that were dear to her.” One came to relate to her the cruel treatment of her Son in the house of Caiphas; another, the insults received by him from Herod. Finally, for I omit all the rest to come to my point, St. John came, and announced to Mary that the most unjust Pilate had already condemned him to death upon the cross. I say the most unjust, for, as St. Leo remarks, this unjust judge condemned him to death with the same lips with which he had pronounced him innocent. Ah, sorrowful mother, said St. John to her, thy Son has already been condemned to death, he is already on his way, bearing himself his cross on his way to Calvary, as he afterwards related in his Gospel: “And bearing his own cross, he went forth to that place which is called Calvary.” Come, if thou dost desire to see him, and bid him a last farewell in some of the streets through which he is to pass.
""",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary, on the Fourth Dolor",
            audioUrl: nil,
            mystery: MysteryData.sevenSorrows[3]
        ),
        Meditation(
            id: -505,
            title: nil,
            content: """
And now we have to admire a new sort of martyrdom, a mother condemned to see an innocent son, whom she loved with all the affection of her heart, put to death before her eyes, by the most barbarous tortures. There stood by the cross of Jesus his mother: “Stabat autem juxta crucem mater ejus.” There is nothing more to be said, says St. John, of the martyrdom of Mary: behold her at the foot of the cross, looking on her dying Son, and then see if there is grief like her grief. Let us stop then also to-day on Calvary, to consider this fifth sword that pierced the heart of Mary, namely, the death of Jesus.

As soon as our afflicted Redeemer had ascended the hill of Calvary, the executioners stripped him of his garments, and piercing his sacred hands and feet with nails, not sharp, but blunt: “Non acutis, sed obtusis;” as St. Bernard says, and to torture him more, they fastened him to the cross. When they had crucified him, they planted the cross, and thus left him to die. The executioners abandon him, but Mary does not abandon him. She then draws nearer to the cross, in order to assist at his death. “I did not leave him,” thus the blessed Virgin revealed to St. Bridget, “and stood nearer to his cross.” But what did it avail, oh Lady, says St. Bonaventure, to go to Calvary to witness there the death of this Son? Shame should have prevented thee, for his disgrace was also thine, because thou wast his mother; or, at least, the horror of such a crime as that of seeing a God crucified by his own creatures, should have prevented thee. But the saint himself answers: Thy heart did not consider the horror, but the suffering: “Non considerabat cor tuum horrorem, sed dolorem.” Ah, thy heart did not then care for its own sorrow, but for the suffering and death of thy dear Son; and therefore thou thyself didst wish to be near him, at least to compassionate him. Ah, true mother! says William the Abbot, loving mother! for not even the terror of death could separate thee from thy beloved Son. But, oh God, what a spectacle of sorrow, to see this Son then in agony upon the cross, and under the cross this mother in agony, who was suffering all the pain that her Son was suffering! Behold the words in which Mary revealed to St. Bridget the pitiable state of her dying Son, as she saw him on the cross: “My dear Jesus was on the cross in grief and in agony; his eyes were sunken, half closed, and lifeless; the lips hanging, and the mouth open; the cheeks hollow, and attached to the teeth; the face lengthened, the nose sharp, the countenance sad; the head had fallen upon his breast, the hair black with blood, the stomach collapsed, the arms and legs stiff, and the whole body covered with wounds and blood.”
""",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary, on the Fifth Dolor",
            audioUrl: nil,
            mystery: MysteryData.sevenSorrows[4]
        ),
        Meditation(
            id: -506,
            title: nil,
            content: """
“Oh, all ye that pass by the way attend, and see if there be any sorrow like to my sorrow.” Devout souls, listen to what the sorrowful Mary says to you to-day: My beloved children, I do not wish you to console me; no, for my heart can never again be consoled on this earth after the death of my dear Jesus. If you wish to please me, this I ask of you, turn to me and see if there has ever been in the world a grief like mine, when I saw him who was all my love torn from me so cruelly. But, oh Lady, since thou dost not wish to be consoled, and hast such a thirst for suffering, I must say to thee that thy sorrows have not ended with the death of thy Son. To-day thou wilt be pierced by another sword of sorrow, when thou shalt see a cruel lance piercing the side of this thy Son, already dead, and shalt receive him in thy arms after he is taken from the cross. And now we are to consider to-day the sixth dolor which afflicted this sorrowful mother. Attend and weep. Hitherto the dolors of Mary tortured her one by one, but to-day they are all united to assail her.

To make known to a mother that her child is dead, is sufficient to kindle her whole soul with love for the lost one. Some persons, in order to lighten their grief, will remind mothers whose children have died, of the displeasure they have once caused them. But if I, oh my queen, should wish to lighten thy sorrow for the death of Jesus in this way, what displeasure has he ever caused thee, that I could recall to thy mind? Ah, no; he always loved thee, obeyed thee, and respected thee. Now thou hast lost him, and who can describe thy sorrow? Do thou who hast felt it explain it. A devout author says, that when our Redeemer was dead, the heart of the great mother was first engaged in accompanying the most holy soul of the Son, and presenting it to the eternal Father. I present thee, oh my God, Mary must then have said, the immaculate soul of thy and my Son, which has been obedient to thee even unto death: receive it, then, in thy arms. Thy justice is now satisfied, thy will accomplished; behold, the great sacrifice to thy eternal glory is consummated. And then turning to the lifeless members of her Jesus: Oh wounds, she said, oh loving wounds, I adore you, I rejoice with you, since through you salvation has been given to the world. You shall remain open in the body of my Son, to be the refuge of those who will have recourse to you. Oh how many, through you, shall receive the pardon of their sins, and then through you shall be inflamed to love the Sovereign Good!
""",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary, on the Sixth Dolor",
            audioUrl: nil,
            mystery: MysteryData.sevenSorrows[5]
        ),
        Meditation(
            id: -507,
            title: nil,
            content: """
When a mother is by the side of a suffering and dying child, she no doubt then feels and suffers all his pains; but when the afflicted child is really dead and about to be buried, and the sorrowful mother takes her last leave of him, oh God! the thought that she is to see him no more is a sorrow that exceeds all other sorrows. Behold, the last sword of sorrow which we are to consider, when Mary, after being present at the death of her Son upon the cross, after having embraced his lifeless body, was finally to leave him in the sepulchre, never more to enjoy his beloved presence.

But that we may better understand this last dolor, let us return to Calvary, again to look upon the afflicted mother, who still holds, clasped in her arms, the lifeless body of her Son. Oh my Son, she seems then to continue to say in the words of Job, my Son, thou art changed to be cruel towards me: “Mutatus es mihi in crudelem.” Yes, for all thy beauty, grace, virtue, and loveliness, all the signs of special love thou hast shown me, the peculiar favors thou hast bestowed on me, are all changed into so many darts of sorrow, which the more they have inflamed my love for thee, so much the more cause me cruelly to feel the pain of having lost thee. Ah, my beloved Son, in losing thee I have lost all. Thus St. Bernard speaks in her name: Oh truly begotten of God, thou wast to me a father, a son, a spouse; thou wast my life! Now I am deprived of my father, my spouse, and my Son, for with my Son whom I have lost, I lose all things.
""",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary, on the Seventh Dolor",
            audioUrl: nil,
            mystery: MysteryData.sevenSorrows[6]
        )
    ]
}
