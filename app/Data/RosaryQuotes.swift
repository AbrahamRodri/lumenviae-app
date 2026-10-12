//
//  RosaryQuotes.swift
//  Lumen Viae
//
//  The daily quotation on the home screen — Scripture, the saints and
//  the popes on Mary, the Rosary and prayer. One is shown per day,
//  chosen by day of the year.
//
//  Attribution rules: name the person as the Church now names them (St.,
//  Bl., Ven.), and cite the work only where the line is genuinely traceable
//  to it. Several of the most-circulated Rosary quotations have traditional
//  rather than documented attributions; those carry the name alone rather
//  than a source we cannot stand behind.
//
//  Every line is in the public domain. The editions quoted are the ones
//  the app bundles or the Spiritual Reading shelf fetches, so a reader
//  can find the line in its book: the Douay-Rheims Bible; Faber's 1862
//  True Devotion (Resources/TrueDevotionBook.json); The Glories of Mary
//  in the 1852 Dunigan translation (Gutenberg #72411); Maxims and
//  Counsels of St. Francis de Sales in Ella McMahon's 1884 translation
//  (Gutenberg #73661), cited by maxim number; The Imitation of Christ in
//  Benham's translation (Gutenberg #1653); Pusey's Confessions
//  (Gutenberg #3296); Taylor's Story of a Soul (Gutenberg #16772);
//  Newman's Meditations and Devotions (Longmans, 1893); Longfellow's
//  Dante (1867) and his rendering of St. Teresa's bookmark (1877). The
//  copyrighted lines that stood here until October 2026 — Escrivá,
//  Sr. Lucia, Fr. Peyton — were taken out; Sheen's line stays, his work
//  having been checked and found out of copyright (Oct 2026).
//  Tools/ContentSourcing/MANIFEST.md records the sources.
//

import Foundation

struct RosaryQuote: Hashable {
    let text: String
    let author: String

    /// The work it comes from, where it can be cited with confidence.
    var source: String? = nil
}

enum RosaryQuotes {

    static let all: [RosaryQuote] = [

        // MARK: On the Rosary

        RosaryQuote(
            text: "The Rosary is the most beautiful and the most rich in graces of all prayers; it is the prayer that touches most the Heart of the Mother of God.",
            author: "St. Pius X"
        ),
        RosaryQuote(
            text: "Give me an army saying the Rosary and I will conquer the world.",
            author: "Bl. Pius IX"
        ),
        RosaryQuote(
            text: "The Rosary is a powerful weapon to put the demons to flight.",
            author: "St. Padre Pio"
        ),
        RosaryQuote(
            text: "Never will anyone who says his Rosary every day be led astray.",
            author: "Bl. Alan de la Roche"
        ),
        RosaryQuote(
            text: "The Rosary is the scourge of the devil.",
            author: "Pope Adrian VI"
        ),
        RosaryQuote(
            text: "Say the Rosary every day to obtain peace for the world.",
            author: "Our Lady of Fatima"
        ),
        RosaryQuote(
            text: "The holy Rosary is the storehouse of countless blessings.",
            author: "Bl. Alan de la Roche"
        ),
        RosaryQuote(
            text: "I am the Lady of the Rosary. Continue to pray the Rosary every day.",
            author: "Our Lady of Fatima",
            source: "October 13, 1917"
        ),
        RosaryQuote(
            text: "When the Rosary is said well, it gives Jesus and Mary more glory and is more meritorious than any other prayer.",
            author: "St. Louis de Montfort",
            source: "The Secret of the Rosary"
        ),
        RosaryQuote(
            text: "If you say the Rosary faithfully until death, I do assure you that you shall receive a never-fading crown of glory.",
            author: "St. Louis de Montfort",
            source: "The Secret of the Rosary"
        ),
        RosaryQuote(
            text: "Recite your Rosary with faith, with humility, with confidence, and with perseverance.",
            author: "St. Louis de Montfort",
            source: "The Secret of the Rosary"
        ),
        RosaryQuote(
            text: "Love the Madonna and pray the Rosary, for her Rosary is the weapon against the evils of the world today.",
            author: "St. Padre Pio"
        ),
        RosaryQuote(
            text: "The Rosary is the weapon for these times.",
            author: "St. Padre Pio"
        ),
        RosaryQuote(
            text: "The Rosary is the book of the blind, where souls see and there enact the greatest drama of love the world has ever known.",
            author: "Ven. Fulton J. Sheen",
            source: "The World's First Love"
        ),
        RosaryQuote(
            text: "The greatest method of praying is to pray the Rosary.",
            author: "St. Francis de Sales"
        ),
        RosaryQuote(
            text: "Among all the devotions approved by the Church, none has been so favored by so many miracles as the devotion of the Most Holy Rosary.",
            author: "Bl. Pius IX"
        ),
        RosaryQuote(
            text: "The Rosary is the most excellent form of prayer and the most efficacious means of attaining eternal life.",
            author: "Pope Leo XIII"
        ),
        RosaryQuote(
            text:
                "It has always been the habit of Catholics in danger and in troublous times to fly for refuge to Mary, and to seek for peace in her maternal goodness.",
            author: "Pope Leo XIII",
            source: "Supremi Apostolatus, 1883"
        ),
        RosaryQuote(
            text:
                "Heretics still learn and say the Our Father, but not the Hail Mary, nor the Rosary. That is their horror.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text:
                "Sometimes when I am in such a state of spiritual dryness that not a single good thought occurs to me, I say very slowly the Our Father or the Hail Mary, and these prayers suffice to take me out of myself.",
            author: "St. Thérèse of Lisieux",
            source: "The Story of a Soul"
        ),

        // MARK: Scripture (Douay-Rheims)

        RosaryQuote(
            text: "Hail, full of grace, the Lord is with thee: blessed art thou among women.",
            author: "The Angel Gabriel",
            source: "Luke 1:28"
        ),
        RosaryQuote(
            text: "Fear not, Mary, for thou hast found grace with God.",
            author: "The Angel Gabriel",
            source: "Luke 1:30"
        ),
        RosaryQuote(
            text: "Because no word shall be impossible with God.",
            author: "The Angel Gabriel",
            source: "Luke 1:37"
        ),
        RosaryQuote(
            text: "Behold the handmaid of the Lord: be it done to me according to thy word.",
            author: "The Blessed Virgin Mary",
            source: "Luke 1:38"
        ),
        RosaryQuote(
            text: "Blessed art thou among women and blessed is the fruit of thy womb.",
            author: "St. Elizabeth",
            source: "Luke 1:42"
        ),
        RosaryQuote(
            text:
                "Blessed art thou that hast believed, because those things shall be accomplished that were spoken to thee by the Lord.",
            author: "St. Elizabeth",
            source: "Luke 1:45"
        ),
        RosaryQuote(
            text: "My soul doth magnify the Lord. And my spirit hath rejoiced in God my Saviour.",
            author: "The Blessed Virgin Mary",
            source: "Luke 1:46-47"
        ),
        RosaryQuote(
            text:
                "Because he hath regarded the humility of his handmaid: for behold from henceforth all generations shall call me blessed.",
            author: "The Blessed Virgin Mary",
            source: "Luke 1:48"
        ),
        RosaryQuote(
            text: "But Mary kept all these words, pondering them in her heart.",
            author: "The Gospel of St. Luke",
            source: "Luke 2:19"
        ),
        RosaryQuote(
            text: "Whatsoever he shall say to you, do ye.",
            author: "The Blessed Virgin Mary, at Cana",
            source: "John 2:5"
        ),
        RosaryQuote(
            text: "Now there stood by the cross of Jesus, his mother.",
            author: "The Gospel of St. John",
            source: "John 19:25"
        ),
        RosaryQuote(
            text: "Woman, behold thy son. After that, he saith to the disciple: Behold thy mother.",
            author: "Jesus, from the Cross",
            source: "John 19:26-27"
        ),
        RosaryQuote(
            text:
                "A great sign appeared in heaven: A woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.",
            author: "The Apocalypse of St. John",
            source: "Apocalypse 12:1"
        ),
        RosaryQuote(
            text: "I am the mother of fair love, and of fear, and of knowledge, and of holy hope.",
            author: "Ecclesiasticus, read of Mary",
            source: "Ecclesiasticus 24:24"
        ),
        RosaryQuote(
            text: "Thou art the glory of Jerusalem, thou art the joy of Israel, thou art the honour of our people.",
            author: "The Book of Judith, read of Mary",
            source: "Judith 15:10"
        ),
        RosaryQuote(
            text: "Ask, and it shall be given you: seek, and you shall find: knock, and it shall be opened to you.",
            author: "Jesus",
            source: "Luke 11:9"
        ),
        RosaryQuote(
            text: "Come to me all you that labor and are burdened, and I will refresh you.",
            author: "Jesus",
            source: "Matthew 11:28"
        ),
        RosaryQuote(
            text:
                "Take up my yoke upon you, and learn of me, because I am meek, and humble of heart: and you shall find rest to your souls.",
            author: "Jesus",
            source: "Matthew 11:29"
        ),
        RosaryQuote(
            text:
                "Peace I leave with you: my peace I give unto you: not as the world giveth, do I give unto you. Let not your heart be troubled: nor let it be afraid.",
            author: "Jesus",
            source: "John 14:27"
        ),
        RosaryQuote(
            text: "But one thing is necessary. Mary hath chosen the best part, which shall not be taken away from her.",
            author: "Jesus",
            source: "Luke 10:42"
        ),
        RosaryQuote(
            text: "Be still and see that I am God.",
            author: "The Psalms",
            source: "Psalm 45:11"
        ),
        RosaryQuote(
            text: "Rejoice in the Lord always: again, I say, rejoice.",
            author: "St. Paul",
            source: "Philippians 4:4"
        ),
        RosaryQuote(
            text: "Pray without ceasing.",
            author: "St. Paul",
            source: "1 Thessalonians 5:17"
        ),

        // MARK: The Church's prayers

        RosaryQuote(
            text: "We fly to thy protection, O holy Mother of God.",
            author: "The oldest known prayer to Mary",
            source: "Sub tuum praesidium, 3rd century"
        ),
        RosaryQuote(
            text: "Hail, holy Queen, Mother of mercy, our life, our sweetness, and our hope.",
            author: "The Salve Regina",
            source: "11th century"
        ),
        RosaryQuote(
            text:
                "Never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession was left unaided.",
            author: "The Memorare"
        ),

        // MARK: St. Louis de Montfort, True Devotion (Faber's translation)

        RosaryQuote(
            text:
                "It is by the most holy Virgin Mary that Jesus has come into the world, and it is also by her that He has to reign in the world.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text: "Where Mary is, there the evil spirit is not.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text:
                "One of the most infallible marks we can have of our being conducted by the good Spirit is our being very devout to Mary, our thinking often of her, and our speaking often of her.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text:
                "As respiration is a certain sign the body is not dead, the frequent thought and loving invocation of Mary is a certain sign the soul is not dead by sin.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text:
                "This devotion is an easy, short, perfect, and secure way of arriving at union with our Lord, in which the perfection of a Christian consists.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text: "All our perfection consists in being conformed, united, and consecrated to Jesus Christ.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text:
                "To do all our actions by Mary, with Mary, in Mary, and for Mary; so that we may do them all the more perfectly by Jesus, with Jesus, in Jesus, and for Jesus.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text:
                "When Mary has struck her roots in a soul, she produces there marvels of grace, which she alone can produce.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text: "God, then, wishes to reveal and discover Mary, the masterpiece of His hands, in these latter times.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text:
                "O, how strong and mighty we are with Jesus Christ, when we are armed with the worthy merits and intercession of the Mother of God.",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),
        RosaryQuote(
            text: "Glory to Jesus in Mary! Glory to Mary in Jesus! Glory to God Alone!",
            author: "St. Louis de Montfort",
            source: "True Devotion to Mary"
        ),

        // MARK: St. Alphonsus Liguori, The Glories of Mary

        RosaryQuote(
            text:
                "Mary is the treasurer of all the divine graces. Therefore he who desires graces should have recourse to Mary; and he who has recourse to Mary, should be secure of obtaining the graces he wishes.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text:
                "It is impossible that a servant of Mary who faithfully honors her and recommends himself to her should be lost.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text: "Oh, what a signal mark of predestination have the servants of Mary!",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text:
                "She is truly our mother, not according to the flesh, but the spiritual mother of our souls and of our salvation.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text:
                "Mary assured St. Bridget that she was mother not only of the just and innocent, but also of sinners, provided they wish to amend.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text:
                "When a sinner becomes penitent, and throws himself at her feet, he finds this good mother of mercy more ready to embrace and aid him than any earthly mother could be.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text: "No sinner need ever fear that he shall be rejected by Mary, if he has recourse to her mercy.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text:
                "Mary is that happy ark in which he who takes refuge will never suffer the shipwreck of eternal ruin.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text: "Mary, through the love she bears to all, seeks to make devotion to her prevail in all hearts.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text:
                "Too happy are the servants of this most kind mother, since not only in this world they are aided by her, but also in purgatory they are assisted and consoled by her protection.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text:
                "As it is easy to find and draw water from a great fountain, so it is easy to find graces and eternal salvation by going to Mary.",
            author: "St. Alphonsus Liguori",
            source: "The Glories of Mary"
        ),
        RosaryQuote(
            text: "This perseverance is daily to be sought, that it may be daily obtained.",
            author: "St. Robert Bellarmine",
            source: "quoted in The Glories of Mary"
        ),
        RosaryQuote(
            text: "Oh Mary, may my heart never cease to love thee nor my tongue to praise thee.",
            author: "St. Bonaventure",
            source: "quoted in The Glories of Mary"
        ),
        RosaryQuote(
            text: "In thee I have placed the hope of my whole heart.",
            author: "St. John Damascene",
            source: "quoted in The Glories of Mary"
        ),

        // MARK: The Fathers and Doctors

        RosaryQuote(
            text:
                "In dangers, in doubts, in difficulties, think of Mary, call upon Mary. Let not her name depart from thy lips, never suffer it to leave thy heart.",
            author: "St. Bernard of Clairvaux",
            source: "Homily on the Missus est"
        ),
        RosaryQuote(
            text:
                "Following her, thou strayest not; invoking her, thou despairest not; thinking of her, thou wanderest not.",
            author: "St. Bernard of Clairvaux",
            source: "Homily on the Missus est"
        ),
        RosaryQuote(
            text: "Look at the star, call upon Mary.",
            author: "St. Bernard of Clairvaux",
            source: "Homily on the Missus est"
        ),
        RosaryQuote(
            text:
                "If thou wouldest not be overwhelmed by the tempest, keep thine eyes fixed upon this star's clear shining.",
            author: "St. Bernard of Clairvaux",
            source: "Homily on the Missus est"
        ),
        RosaryQuote(
            text:
                "Let the soul of Mary be in each of you to magnify the Lord, and the spirit of Mary be in each of you to rejoice in God.",
            author: "St. Ambrose",
            source: "Commentary on St. Luke"
        ),
        RosaryQuote(
            text: "The knot of Eve's disobedience was loosed by the obedience of Mary.",
            author: "St. Irenaeus",
            source: "Against Heresies"
        ),
        RosaryQuote(
            text: "Thou hast made us for Thyself, and our heart is restless, until it repose in Thee.",
            author: "St. Augustine",
            source: "The Confessions"
        ),
        RosaryQuote(
            text: "Too late loved I Thee, O Thou Beauty of ancient days, yet ever new! too late I loved Thee!",
            author: "St. Augustine",
            source: "The Confessions"
        ),

        // MARK: The Imitation of Christ

        RosaryQuote(
            text:
                "Love is a great thing, a good above all others, which alone maketh every heavy burden light, and equaliseth every inequality.",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),
        RosaryQuote(
            text:
                "If thou knewest the whole Bible, and the sayings of all the philosophers, what should all this profit thee without the love and grace of God?",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),
        RosaryQuote(
            text:
                "It is not deep words that make a man holy and upright; it is a good life which maketh a man dear to God.",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),
        RosaryQuote(
            text: "I had rather feel contrition than be skilful in the definition thereof.",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),
        RosaryQuote(
            text: "First keep thyself in peace, and then shalt thou be able to be a peacemaker towards others.",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),
        RosaryQuote(
            text: "A peaceable man doth more good than a well-learned.",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),
        RosaryQuote(
            text:
                "Turn thee with all thine heart to the Lord and forsake this miserable world, and thou shalt find rest unto thy soul.",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),
        RosaryQuote(
            text: "Keep thine heart free, and lifted up towards God, for here have we no continuing city.",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),
        RosaryQuote(
            text: "No man can stand, unless with all his heart he will humble himself for God's sake.",
            author: "Thomas à Kempis",
            source: "The Imitation of Christ"
        ),

        // MARK: St. Francis de Sales, Maxims and Counsels

        RosaryQuote(
            text:
                "Keep yourself faithfully in the presence of God; avoid hurry and anxiety, for there are no greater obstacles to our progress in perfection.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 1"
        ),
        RosaryQuote(
            text:
                "Have no care for the morrow; think only of doing well to-day, and when to-morrow shall have become to-day then we shall think about it.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 6"
        ),
        RosaryQuote(
            text:
                "God has preserved you so far; only keep yourself faithful to the law of his providence and He will assist you at all times, and where you cannot walk He will carry you.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 23"
        ),
        RosaryQuote(
            text: "The child can never perish who remains in the arms of a Father who is almighty.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 25"
        ),
        RosaryQuote(
            text:
                "Plant in your heart Jesus Christ Crucified, and all the crosses of this world will seem to you like roses.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 31"
        ),
        RosaryQuote(
            text: "We must lose everything rather than courage, confidence, and good-will.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 58"
        ),
        RosaryQuote(
            text:
                "Fear not; you are walking upon the sea, amid the winds and the waves, but it is with Jesus. If fear seizes you, cry loudly, \u{201C}Lord, save me!\u{201D} He will stretch forth his hand to you; clasp it firmly and go joyfully on.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 82"
        ),
        RosaryQuote(
            text:
                "Go joyously and with a light heart as far as you can, and if you cannot always go joyously, go always courageously and confidently.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 93"
        ),
        RosaryQuote(
            text:
                "Frequently during the day cast your heart, your mind, and your care upon God with great confidence, saying, \u{201C}I am thine, save me.\u{201D}",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 96"
        ),
        RosaryQuote(
            text:
                "Let us be what we are, and be that well, in order that we may honour the Master Workman who has made us.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 104"
        ),
        RosaryQuote(
            text:
                "Let us keep on in the low valleys of the small and humble virtues. I love these three little virtues: gentleness of heart, firmness of mind, and simplicity of life.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 119"
        ),
        RosaryQuote(
            text: "When we pray it is well to think that there is no one in the world but God.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 144"
        ),
        RosaryQuote(
            text:
                "The great secret in prayer is simply to follow the attractions of the heart. We must go on in good faith and with pure intention to reach God, to love Him, and unite ourselves to Him. True love has little method.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 145"
        ),
        RosaryQuote(
            text:
                "When your heart is distracted in prayer, bring it gently back to the point from which it has wandered, and lay it tenderly at the feet of its Master. If you do but this your hour will be well employed.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 147"
        ),
        RosaryQuote(
            text:
                "If we can speak to our Lord in prayer let us speak to Him, praise Him, listen to Him. If we cannot speak because we are spiritually hoarse, let us stay nevertheless and make Him a reverence.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 148"
        ),
        RosaryQuote(
            text:
                "Let us always keep on; however slow our progress we are getting over a great deal of the road. God wishes that our misery should be the throne of his mercy.",
            author: "St. Francis de Sales",
            source: "Maxims and Counsels, 173"
        ),

        // MARK: Newman, Meditations and Devotions

        RosaryQuote(
            text:
                "God has created me to do Him some definite service; He has committed some work to me which He has not committed to another. I have my mission.",
            author: "St. John Henry Newman",
            source: "Meditations and Devotions"
        ),
        RosaryQuote(
            text:
                "He has not created me for naught. I shall do good, I shall do His work; I shall be an angel of peace, a preacher of truth in my own place, while not intending it, if I do but keep His commandments and serve Him in my calling.",
            author: "St. John Henry Newman",
            source: "Meditations and Devotions"
        ),
        RosaryQuote(
            text: "Therefore I will trust Him. Whatever, wherever I am, I can never be thrown away.",
            author: "St. John Henry Newman",
            source: "Meditations and Devotions"
        ),
        RosaryQuote(
            text:
                "Mary is called by the holy Fathers a second and a better Eve, as having taken that first step in the salvation of mankind which Eve took in its ruin.",
            author: "St. John Henry Newman",
            source: "Meditations and Devotions"
        ),
        RosaryQuote(
            text: "Lead, kindly Light, amid the encircling gloom, lead Thou me on.",
            author: "St. John Henry Newman",
            source: "The Pillar of the Cloud, 1833"
        ),

        // MARK: Other saints and poets

        RosaryQuote(
            text:
                "With me prayer is an uplifting of the heart; a glance towards heaven; a cry of gratitude and love, uttered equally in sorrow and in joy.",
            author: "St. Thérèse of Lisieux",
            source: "The Story of a Soul"
        ),
        RosaryQuote(
            text: "Let nothing disturb thee; nothing affright thee; all things are passing; God never changeth.",
            author: "St. Teresa of Ávila",
            source: "her bookmark, tr. Longfellow"
        ),
        RosaryQuote(
            text:
                "Patient endurance attaineth to all things; who God possesseth in nothing is wanting; alone God sufficeth.",
            author: "St. Teresa of Ávila",
            source: "her bookmark, tr. Longfellow"
        ),
        RosaryQuote(
            text:
                "Thou Virgin Mother, daughter of thy Son, humble and high beyond all other creature, the limit fixed of the eternal counsel.",
            author: "Dante",
            source: "Paradiso XXXIII, tr. Longfellow"
        ),
        RosaryQuote(
            text:
                "Not only thy benignity gives succour to him who asketh it, but oftentimes forerunneth of its own accord the asking.",
            author: "Dante",
            source: "Paradiso XXXIII, tr. Longfellow"
        ),
        RosaryQuote(
            text: "Mother of mercy, day by day my love of thee grows more and more.",
            author: "Fr. Frederick Faber",
            source: "hymn, 1849"
        ),
        RosaryQuote(
            text: "Faith of our fathers, holy faith! We will be true to thee till death.",
            author: "Fr. Frederick Faber",
            source: "Faith of Our Fathers, 1849"
        )
    ]

    /// Today's quote. Day-of-year rather than random so the home screen is
    /// steady through the day and everyone praying today shares the same line.
    static var today: RosaryQuote {
        quote(offset: 0)
    }

    /// The quote for the completion screen, drawn half the catalog away from
    /// the home screen's so a single session never shows the same line twice.
    static var afterPraying: RosaryQuote {
        quote(offset: all.count / 2)
    }

    private static func quote(offset: Int) -> RosaryQuote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return all[(dayOfYear + offset) % all.count]
    }
}
