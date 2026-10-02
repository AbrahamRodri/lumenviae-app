//
//  PrayerBookMary2.swift
//  Lumen Viae
//
//  More prayers to Our Lady: under her titles, to her Heart and her Sorrows, and two of her chants.
//  Sources: The Raccolta, Burns & Oates, 1910 (nos. 230, 232, 257, 269, 270)
//  The Servite Manual, as printed by EWTN (the Litany of Our Lady of Sorrows)
//  A traditional Lourdes prayer of the late 19th-century manuals
//  St John Bosco's prayer to Mary, Help of Christians, in its traditional English
//  The Liber Usualis and preces-latinae.org (the Latin of the Inviolata and the Salve Mater)
//  English of the Inviolata and the Salve Mater: our own literal rendering from the Latin
//

import Foundation

extension PrayerBookTexts {

    static let mary2: [BookPrayer] = [
        BookPrayer(
            id: "our_lady_of_good_counsel",
            title: "Prayer to Our Lady of Good Counsel",
            latinTitle: "Mater Boni Consilii",
            origin: "Pope Leo XIII · 1880 · The Raccolta",
            note: "Said when a choice must be made, and on her feast on April 26.",
            english: """
Most glorious Virgin, chosen by the Eternal Counsel to be the Mother of the Eternal Word made Man, treasure-house of divine graces and advocate of sinners; I, the most unworthy of thy servants, have recourse to thee, begging of thee to be my guide and counsellor in this vale of tears.

Obtain for me, through the most Precious Blood of thy Divine Son, forgiveness of my sins, and the salvation of my soul with all the means necessary to secure it. Obtain for Holy Church triumph over her enemies and the extension of the Kingdom of Jesus Christ over the whole earth. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "our_lady_of_lourdes",
            title: "Prayer to Our Lady of Lourdes",
            latinTitle: nil,
            origin: "A traditional prayer · late 19th century",
            note: "Said for the sick, and on her feast on February 11.",
            english: """
O ever Immaculate Virgin, Mother of mercy, health of the sick, refuge of sinners, comfort of the afflicted, thou knowest my wants, my troubles, my sufferings; deign to cast upon me a look of mercy.

By appearing in the grotto of Lourdes, thou wast pleased to make it a privileged sanctuary, whence thou dispensest thy favours; and already many sufferers have obtained the cure of their infirmities, both spiritual and corporal. I come, therefore, with the most unbounded confidence to implore thy maternal intercession.

Obtain, O loving Mother, the granting of my requests. Through gratitude for thy favours, I will endeavour to imitate thy virtues, that I may one day share thy glory. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "immaculate_heart",
            title: "Prayer to the Heart of Mary",
            latinTitle: nil,
            origin: "Pope Pius VII · 1816 · The Raccolta",
            note: "Said on the first Saturday of the month, and on the feast of her Immaculate Heart.",
            english: """
Heart of Mary, Mother of God and our Mother, Heart most amiable, on which the adorable Trinity ever gazes with complacency, worthy of all the veneration and tenderness of angels and of men; Heart most like the Heart of Jesus, whose most perfect image thou art; Heart full of goodness, ever compassionate towards our miseries; vouchsafe to thaw our icy hearts, that they may be wholly changed to the likeness of the Heart of Jesus.

Infuse into them the love of thy virtues, inflame them with that blessed fire with which thou dost ever burn. In thee let the Holy Church find safe shelter; protect it and be its sweet asylum, its tower of strength, impregnable against every inroad of its enemies. Be thou the road leading to Jesus; be thou the channel whereby we receive all graces needful for our salvation.

Be thou our help in need, our comfort in trouble, our strength in temptation, our refuge in persecution, our aid in all dangers; but especially in the last struggle of our life, at the moment of our death, when all hell shall be unchained against us to snatch away our souls.

In that dread moment, that hour so terrible, whereon our eternity depends, ah, then, most tender Virgin, make us feel how great is the tenderness of thy maternal Heart, and how mighty thy power with the Heart of Jesus, opening to us a safe refuge in the very fount of mercy itself, that so we too may join with thee in Paradise in blessing that same Heart of Jesus for ever and for ever. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "our_lady_of_sorrows",
            title: "Prayer to Our Lady of Sorrows",
            latinTitle: nil,
            origin: "Pope Pius VII · 1815 · The Raccolta",
            note: "Seven greetings of her sorrowing heart, each with a Hail Mary, said on Fridays and through September.",
            english: """
℣. O God, come to my assistance.
℟. O Lord, make haste to help me.

[Glory be to the Father.]

I compassionate thee, sorrowing Mary, in the affliction of thy tender heart at the prophecy of the holy old man Simeon. Dear Mother, by thy heart then so afflicted, obtain for me the virtue of humility and the gift of holy fear of God.

[Hail Mary.]

I compassionate thee, sorrowing Mary, in the anxiety which thy sensitive heart underwent in the flight and sojourn in Egypt. Dear Mother, by thy heart then made so anxious, obtain for me the virtue of liberality, especially towards the poor, and the gift of pity.

[Hail Mary.]

I compassionate thee, sorrowing Mary, in the trouble of thy anxious heart, when thou didst lose thy dear Son Jesus. Dear Mother, by thy heart then so troubled, obtain for me the virtue of holy chastity and the gift of knowledge.

[Hail Mary.]

I compassionate thee, sorrowing Mary, in the shock thy maternal heart underwent when Jesus met thee carrying His Cross. Dear Mother, by thy loving heart then so overwhelmed, obtain for me the virtue of patience and the gift of fortitude.

[Hail Mary.]

I compassionate thee, sorrowing Mary, in the martyrdom thy generous heart bore so nobly whilst thou didst stand by Jesus in His agony. Dear Mother, by thy heart then so martyred, obtain for me the virtue of temperance and the gift of counsel.

[Hail Mary.]

I compassionate thee, sorrowing Mary, in the wound of thy tender heart when the sacred Side of Jesus was pierced with the lance. Dear Mother, by thy heart then so transfixed, obtain for me the virtue of fraternal charity and the gift of understanding.

[Hail Mary.]

I compassionate thee, sorrowing Mary, in the pang felt by thy loving heart when the Body of Jesus was buried in the grave. Dear Mother, by all the bitterness of desolation thou didst then experience, obtain for me the virtue of diligence and the gift of wisdom.

[Hail Mary.]

℣. Pray for us, Virgin most sorrowful.
℟. That we may be made worthy of the promises of Christ.

[Let us pray.]

Grant, we beseech Thee, O Lord Jesus Christ, that the most blessed Virgin Mary, Thy Mother, may intercede for us before the throne of Thy mercy, now and at the hour of our death, whose most holy soul was transfixed with the sword of sorrow in the hour of Thine own Passion. Through Thee, Jesus Christ, Saviour of the world, Who livest and reignest world without end.

℟. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "litany_seven_sorrows",
            title: "Litany of Our Lady of Sorrows",
            latinTitle: nil,
            origin: "Pope Pius VII · 1815 · The Servite Manual",
            note: "Written by Pius VII while he was held captive by Napoleon, and said on Fridays and through September, the month of her Sorrows.",
            english: """
Lord, have mercy on us.
Christ, have mercy on us.
Lord, have mercy on us.
Christ, hear us. ℟. Christ, graciously hear us.

God the Father of Heaven, ℟. have mercy on us.
God the Son, Redeemer of the world,
God the Holy Spirit,
Holy Trinity, One God,

Holy Mary, Mother of God, ℟. pray for us.
Holy Virgin of virgins,
Mother of the Crucified,
Sorrowful Mother,
Mournful Mother,
Sighing Mother,
Afflicted Mother,
Forsaken Mother,
Desolate Mother,

Mother most sad, ℟. pray for us.
Mother set around with anguish,
Mother overwhelmed by grief,
Mother transfixed by a sword,
Mother crucified in thy heart,
Mother bereaved of thy Son,
Sighing Dove,
Mother of Dolours,

Fount of tears, ℟. pray for us.
Sea of bitterness,
Field of tribulation,
Mass of suffering,
Mirror of patience,
Rock of constancy,
Remedy in perplexity,
Joy of the afflicted,

Ark of the desolate, ℟. pray for us.
Refuge of the abandoned,
Shield of the oppressed,
Conqueror of the incredulous,
Solace of the wretched,
Medicine of the sick,
Help of the faint,
Strength of the weak,

Protectress of those who fight, ℟. pray for us.
Haven of the shipwrecked,
Calmer of tempests,
Companion of the sorrowful,
Retreat of those who groan,
Terror of the treacherous,

Standard-bearer of the Martyrs, ℟. pray for us.
Treasure of the Faithful,
Light of Confessors,
Pearl of Virgins,
Comfort of Widows,
Joy of all Saints,
Queen of thy Servants,
Holy Mary, who alone art unexampled,

Lamb of God, Who takest away the sins of the world, ℟. spare us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. graciously hear us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. have mercy on us.

℣. Pray for us, most Sorrowful Virgin,
℟. That we may be made worthy of the promises of Christ.

[Let us pray.]

O God, in Whose Passion, according to the prophecy of Simeon, a sword of grief pierced through the most sweet soul of Thy glorious Blessed Virgin Mother Mary: grant that we, who celebrate the memory of her Seven Sorrows, may obtain the happy effect of Thy Passion, Who livest and reignest world without end.

℟. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "mary_help_of_christians",
            title: "Prayer to Mary, Help of Christians",
            latinTitle: "Auxilium Christianorum",
            origin: "St John Bosco · 19th century",
            note: "St John Bosco's prayer to Our Lady under the title he gave his church in Turin, said on the 24th of each month and on her feast on May 24.",
            english: """
O Mary, powerful Virgin, thou art the mighty and glorious protector of the Church; thou art the marvellous help of Christians; thou art terrible as an army set in battle array; thou hast destroyed heresy in all the world.

In the midst of our anguish, our struggles and our distress, defend us from the power of the enemy, and at the hour of our death receive our souls in Paradise. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "our_lady_of_mount_carmel",
            title: "Prayer to Our Lady of Mount Carmel",
            latinTitle: nil,
            origin: "Pope Leo XIII · 1886 · The Raccolta",
            note: "Said by those who wear her scapular, and on her feast on July 16, with three Hail Marys and a Glory Be.",
            english: """
Most blessed Virgin Immaculate, the beauty and splendour of Carmel, thou who regardest with eyes of special love those who wear thy blessed habit, look kindly upon me and spread over me the mantle of thy maternal protection.

Strengthen my weakness with thy power, illuminate the darkness of my mind with thy wisdom, increase in me the virtues of Faith, Hope and Charity. Adorn my soul with such graces and virtues that it may be ever dear to thy divine Son and to thee.

Assist me in life, console me in death, with thy dear presence, and present me to the Holy Trinity as thy child and devoted servant, eternally to praise and bless thee in Paradise. Amen.

[Hail Mary, three times; Glory be, once.]
""",
            latin: nil
        ),
        BookPrayer(
            id: "inviolata",
            title: "Inviolate",
            latinTitle: "Inviolata",
            origin: "A Marian prose · 11th century",
            note: "An old chant of Our Lady's purity, sung at Benediction and on her feasts.",
            english: """
Inviolate, whole and chaste art thou, Mary,
who wast made the shining gate of heaven.
O loving Mother of Christ, most dear,
receive our devout proclamations of praise.
Devout hearts and lips now entreat thee
that our hearts and bodies may be pure.
By thy sweet-sounding prayers
grant us pardon for ever.
O kind one! O Queen! O Mary,
who alone hast remained inviolate.
""",
            latin: """
Inviolata, integra, et casta es, Maria,
quae es effecta fulgida caeli porta.
O Mater alma Christi carissima,
suscipe pia laudum praeconia.
Te nunc flagitant devota corda et ora,
nostra ut pura pectora sint et corpora.
Tua per precata dulcisona,
nobis concedas veniam per saecula.
O benigna! O Regina! O Maria,
quae sola inviolata permansisti.
"""
        ),
        BookPrayer(
            id: "salve_mater",
            title: "Hail, Mother of Mercy",
            latinTitle: "Salve Mater misericordiæ",
            origin: "A Marian hymn · 11th century",
            note: "A hymn long sung by the Carmelites, its greeting returning after every verse.",
            english: """
Hail, Mother of mercy,
Mother of God and Mother of pardon,
Mother of hope and Mother of grace,
Mother full of holy gladness.
O Mary!

Hail, glory of the human race,
hail, Virgin worthier than all the rest,
who surpassest all virgins
and sittest higher among those above.
O Mary!

Hail, happy Virgin who gavest birth:
for He Who sits at the Father's right hand,
ruling the heaven, the earth and the sky,
enclosed Himself within thy womb.
O Mary!

Be thou, Mother, our solace;
be thou, O Virgin, our joy;
and at the last, after this exile,
join us glad to the choirs of heaven.
O Mary!
""",
            latin: """
Salve, Mater misericordiae,
Mater Dei et Mater veniae,
Mater spei et Mater gratiae,
Mater plena sanctae laetitiae.
O Maria!

Salve, decus humani generis,
salve, Virgo dignior ceteris,
quae virgines omnes transgrederis
et altius sedes in superis.
O Maria!

Salve, felix Virgo puerpera:
nam qui sedet in Patris dextera,
caelum regens, terram et aethera,
intra tua se clausit viscera.
O Maria!

Esto, Mater, nostrum solatium;
nostrum esto, tu Virgo, gaudium;
et nos tandem post hoc exsilium
laetos iunge choris caelestium.
O Maria!
"""
        ),
    ]
}
