//
//  PrayerBookDay2.swift
//  Lumen Viae
//
//  More prayers for the day and the home, for the Church and the world,
//  for the dead, and more short prayers.
//  Sources: The Roman Missal (1962), its collects and orations
//  The Roman Breviary, the Itinerarium (English: our own literal rendering)
//  The Roman Ritual, the visitation of the sick
//  The Raccolta (1910 English edition and earlier)
//  Pope Leo XIII's prayer for the family (English: our own rendering from the Italian)
//  John Henry Newman, Meditations and Devotions (1893); "Lead, Kindly Light" (1833)
//  Archbishop John Carroll, Prayer for Government (1791)
//  St Faustina Kowalska, Diary (English: our own literal rendering from the Polish)
//  The Douay-Rheims Bible and the Vulgate
//

import Foundation

extension PrayerBookTexts {

    static let day2: [BookPrayer] = [
        BookPrayer(
            id: "actiones_nostras",
            title: "Before Work",
            latinTitle: "Actiones nostras",
            origin: "The Roman Missal and Breviary",
            note: "Said before beginning any work or study, giving it to God from its first moment to its end.",
            english: """
Direct, we beseech Thee, O Lord, all our actions by Thy holy inspirations, and carry them on by Thy gracious assistance, that every prayer and work of ours may always begin from Thee, and through Thee be happily ended. Through Christ our Lord. Amen.
""",
            latin: """
Actiones nostras, quæsumus, Domine, aspirando præveni et adiuvando prosequere: ut cuncta nostra oratio et operatio a te semper incipiat, et per te coepta finiatur. Per Christum Dominum nostrum. Amen.
"""
        ),
        BookPrayer(
            id: "prayer_for_travel",
            title: "Before a Journey",
            latinTitle: "Itinerarium",
            origin: "The Roman Breviary · the Itinerarium",
            note: "Part of the Breviary's prayers for those setting out on a journey, said before leaving.",
            english: """
In the way of peace and prosperity may the almighty and merciful Lord direct us: and may the Angel Raphael accompany us on the way, that we may return home in peace, in safety and in joy.

℣. Save Thy servants.
℟. Who hope in Thee, O my God.
℣. Send us help, O Lord, from the sanctuary.
℟. And defend us out of Sion.
℣. Be unto us, O Lord, a tower of strength.
℟. From the face of the enemy.
℣. Show us, O Lord, Thy ways.
℟. And teach us Thy paths.
℣. God hath given His angels charge over thee.
℟. To keep thee in all thy ways.
℣. O Lord, hear my prayer.
℟. And let my cry come unto Thee.

[Let us pray.]

O God, Who didst make the children of Israel to walk dry-shod through the midst of the sea, and Who didst open to the three Wise Men the way to Thee by the guiding of a star: grant us, we beseech Thee, a prosperous journey and a peaceful time; that, with Thy holy Angel for our companion, we may happily come to the place to which we go, and at the last to the haven of everlasting salvation.

Be present, we beseech Thee, O Lord, to our supplications, and dispose the way of Thy servants in the prosperity of Thy salvation; that amid all the changes of this way and of this life, we may ever be protected by Thy help. Through our Lord Jesus Christ, Thy Son, Who liveth and reigneth with Thee in the unity of the Holy Spirit, God, world without end.
℟. Amen.

℣. Let us go forth in peace.
℟. In the name of the Lord. Amen.
""",
            latin: """
In viam pacis et prosperitatis dirigat nos omnipotens et misericors Dominus: et Angelus Raphael comitetur nobiscum in via, ut cum pace, salute et gaudio revertamur ad propria.

℣. Salvos fac servos tuos.
℟. Deus meus, sperantes in te.
℣. Mitte nobis, Domine, auxilium de sancto.
℟. Et de Sion tuere nos.
℣. Esto nobis, Domine, turris fortitudinis.
℟. A facie inimici.
℣. Vias tuas, Domine, demonstra nobis.
℟. Et semitas tuas edoce nos.
℣. Angelis suis Deus mandavit de te.
℟. Ut custodiant te in omnibus viis tuis.
℣. Domine, exaudi orationem meam.
℟. Et clamor meus ad te veniat.

[Oremus.]

Deus, qui filios Israel per maris medium sicco vestigio ire fecisti, quique tribus Magis iter ad te stella duce pandisti: tribue nobis, quæsumus, iter prosperum, tempusque tranquillum; ut, Angelo tuo sancto comite, ad eum, quo pergimus, locum, ac demum ad æternæ salutis portum pervenire feliciter valeamus.

Adesto, quæsumus, Domine, supplicationibus nostris: et viam famulorum tuorum in salutis tuæ prosperitate dispone; ut inter omnes viæ et vitæ huius varietates, tuo semper protegamur auxilio. Per Dominum nostrum Iesum Christum, Filium tuum, qui tecum vivit et regnat in unitate Spiritus Sancti, Deus, per omnia sæcula sæculorum.
℟. Amen.

℣. Procedamus in pace.
℟. In nomine Domini. Amen.
"""
        ),
        BookPrayer(
            id: "prayer_for_family",
            title: "For the Family",
            latinTitle: nil,
            origin: "Pope Leo XIII · the Raccolta",
            note: "Said by the household together, commending the home to God as the house of Nazareth was His.",
            english: """
O God of goodness and mercy, to Thy fatherly protection we commend our family, our household, and all that is ours. We give all into Thy love and keeping: fill this house with Thy blessings, as Thou didst fill the holy house of Nazareth with Thy presence. Keep far from us, before all else, the stain of sin; and do Thou alone reign among us by Thy law, by Thy holy love, and by the practice of every Christian virtue. May each of us obey Thee, love Thee, and follow in his own life Thy example, and that of Mary, Thy Mother and ours, and of St Joseph, Thy faithful guardian.

Keep us and our house from every evil and misfortune; yet grant that we may be ever resigned to Thy holy will, even in the sorrows it shall please Thee to send us. Give us all the grace to live in perfect peace with one another and in charity toward our neighbour, and grant that each of us may so live as to receive the comfort of Thy holy Sacraments at the hour of death. O Jesus, bless us and keep us.

O Mary, Mother of grace and mercy, defend us from the evil spirit, reconcile us to thy Son, and commend us to Him, that we may be made worthy of His promises.

St Joseph, foster-father of our Saviour, guardian of His holy Mother, head of the Holy Family, pray for us, bless us, and defend our home at all times.

Bless this house, O God the Father, Who didst create us; O God the Son, Who didst suffer for us upon the Cross; O God the Holy Spirit, Who didst sanctify us in Baptism. May the one God in three Persons keep our bodies, purify our minds, direct our hearts, and bring us all to everlasting life. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "parents_for_children",
            title: "A Parent's Prayer for Their Children",
            latinTitle: nil,
            origin: "The prayer books of the 19th century",
            note: "Said by a father or mother for the children God has given them.",
            english: """
O heavenly Father, I commend my children unto Thee. Be Thou their God and Father, and mercifully supply whatever is lacking in me through frailty or negligence. Strengthen them to overcome the corruptions of the world, whether from within or without, and deliver them from the secret snares of the enemy. Pour Thy grace into their hearts, and confirm and multiply in them the gifts of Thy Holy Spirit, that they may daily grow in grace and in the knowledge of our Lord Jesus Christ; and so, faithfully serving Thee here, may come to rejoice in Thy presence hereafter. Through the same Christ our Lord. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "prayer_for_the_sick",
            title: "For the Sick",
            latinTitle: "Respice, Domine",
            origin: "The Roman Ritual · the visitation of the sick",
            note: "The Ritual's prayer over one who is ill, said for the sick at home or in hospital.",
            english: """
Look down, O Lord, upon Thy servant, who labours under bodily infirmity, and refresh the soul which Thou hast created; that, being bettered by Thy chastisements, he may know himself saved by Thy healing. Through Christ our Lord. Amen.
""",
            latin: """
Respice, Domine, famulum tuum in infirmitate sui corporis laborantem, et animam refove, quam creasti: ut castigationibus emendatus, se continuo sentiat tua medicina salvatum. Per Christum Dominum nostrum. Amen.
"""
        ),
        BookPrayer(
            id: "happy_death",
            title: "For a Happy Death",
            latinTitle: nil,
            origin: "St John Henry Newman · Meditations and Devotions, 1893",
            note: "Said for the grace to die well, in the Church and with her Sacraments.",
            english: """
O my Lord and Saviour, support me in my last hour in the strong arms of Thy Sacraments, and by the fresh fragrance of Thy consolations. Let the absolving words be said over me, and the holy oil sign and seal me, and Thy own Body be my food, and Thy Blood my sprinkling; and let my sweet Mother, Mary, breathe on me, and my Angel whisper peace to me, and my glorious Saints smile upon me; that in them all, and through them all, I may receive the gift of perseverance, and die, as I desire to live, in Thy faith, in Thy Church, in Thy service, and in Thy love. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "newman_definite_service",
            title: "Some Definite Service",
            latinTitle: nil,
            origin: "St John Henry Newman · Meditations and Devotions, 1893",
            note: "A meditation to pray over when a life's purpose is hidden, trusting that God knows what He is about.",
            english: """
God has created me to do Him some definite service; He has committed some work to me which He has not committed to another. I have my mission. I may never know it in this life, but I shall be told it in the next.

I am a link in a chain, a bond of connexion between persons. He has not created me for naught. I shall do good, I shall do His work; I shall be an angel of peace, a preacher of truth in my own place, while not intending it, if I do but keep His commandments and serve Him in my calling.

Therefore I will trust Him. Whatever, wherever I am, I can never be thrown away. If I am in sickness, my sickness may serve Him; in perplexity, my perplexity may serve Him; if I am in sorrow, my sorrow may serve Him. My sickness, or perplexity, or sorrow may be necessary causes of some great end, which is quite beyond us. He does nothing in vain; He may prolong my life, He may shorten it; He knows what He is about. He may take away my friends, He may throw me among strangers, He may make me feel desolate, make my spirits sink, hide the future from me; still He knows what He is about.
""",
            latin: nil
        ),
        BookPrayer(
            id: "lead_kindly_light",
            title: "Lead, Kindly Light",
            latinTitle: nil,
            origin: "St John Henry Newman · 1833",
            note: "Written at sea becalmed on the way home from Italy; prayed in darkness and uncertainty, asking only for the next step.",
            english: """
Lead, Kindly Light, amid the encircling gloom,
Lead Thou me on!
The night is dark, and I am far from home;
Lead Thou me on!
Keep Thou my feet; I do not ask to see
The distant scene; one step enough for me.

I was not ever thus, nor prayed that Thou
Shouldst lead me on;
I loved to choose and see my path; but now
Lead Thou me on!
I loved the garish day, and, spite of fears,
Pride ruled my will: remember not past years.

So long Thy power hath blest me, sure it still
Will lead me on,
O'er moor and fen, o'er crag and torrent, till
The night is gone,
And with the morn those angel faces smile,
Which I have loved long since, and lost awhile.
""",
            latin: nil
        ),
        BookPrayer(
            id: "prayer_for_priests",
            title: "For Priests",
            latinTitle: "Omnipotens sempiterne Deus, cuius Spiritu",
            origin: "The Roman Missal · Good Friday and the orations for various needs",
            note: "The Church's prayer for all her orders, her bishops, priests and deacons first, that each may serve God faithfully.",
            english: """
[Let us pray.]

Almighty and everlasting God, by Whose Spirit the whole body of the Church is sanctified and governed: hear our supplications for all its orders, that by the gift of Thy grace Thou mayest be faithfully served by every rank of them. Through our Lord Jesus Christ, Thy Son, Who liveth and reigneth with Thee in the unity of the same Holy Spirit, God, world without end.

℟. Amen.
""",
            latin: """
[Oremus.]

Omnipotens sempiterne Deus, cuius Spiritu totum corpus Ecclesiæ sanctificatur et regitur: exaudi nos pro universis ordinibus supplicantes; ut gratiæ tuæ munere, ab omnibus tibi gradibus fideliter serviatur. Per Dominum nostrum Iesum Christum, Filium tuum, qui tecum vivit et regnat in unitate eiusdem Spiritus Sancti, Deus, per omnia sæcula sæculorum.

℟. Amen.
"""
        ),
        BookPrayer(
            id: "prayer_for_our_country",
            title: "For Our Country",
            latinTitle: nil,
            origin: "Archbishop John Carroll · 1791",
            note: "The first bishop of the United States wrote it for his people; given here are its prayers for those who govern and for the nation, without the paragraphs for the Church and the dead.",
            english: """
We pray Thee, O God of might, wisdom, and justice, through Whom authority is rightly administered, laws are enacted, and judgment decreed, assist with Thy Holy Spirit of counsel and fortitude the President of these United States, that his administration may be conducted in righteousness, and be eminently useful to Thy people over whom he presides; by encouraging due respect for virtue and religion; by a faithful execution of the laws in justice and mercy; and by restraining vice and immorality.

Let the light of Thy divine wisdom direct the deliberations of Congress, and shine forth in all the proceedings and laws framed for our rule and government, so that they may tend to the preservation of peace, the promotion of national happiness, the increase of industry, sobriety, and useful knowledge; and may perpetuate to us the blessing of equal liberty.

We pray for his excellency, the governor of this state, for the members of the assembly, for all judges, magistrates, and other officers who are appointed to guard our political welfare, that they may be enabled, by Thy powerful protection, to discharge the duties of their respective stations with honesty and ability.

We recommend likewise, to Thy unbounded mercy, all our brethren and fellow citizens throughout the United States, that they may be blessed in the knowledge and sanctified in the observance of Thy most holy law; that they may be preserved in union, and in that peace which the world cannot give; and after enjoying the blessings of this life, be admitted to those which are eternal. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "da_pacem",
            title: "For Peace",
            latinTitle: "Da pacem, Domine",
            origin: "The Roman Missal and Breviary · the antiphon and collect for peace",
            note: "Said in time of war and unrest, and whenever the world's peace is threatened.",
            english: """
Give peace, O Lord, in our days, for there is none other that fighteth for us, but only Thou, our God.

℣. Let peace be in Thy strength.
℟. And abundance in Thy towers.

[Let us pray.]

O God, from Whom are holy desires, right counsels and just works: give unto Thy servants that peace which the world cannot give; that our hearts may be set to obey Thy commandments, and that, the fear of enemies being taken away, our times, by Thy protection, may be peaceful. Through our Lord Jesus Christ, Thy Son, Who liveth and reigneth with Thee in the unity of the Holy Spirit, God, world without end.

℟. Amen.
""",
            latin: """
Da pacem, Domine, in diebus nostris, quia non est alius qui pugnet pro nobis, nisi tu, Deus noster.

℣. Fiat pax in virtute tua.
℟. Et abundantia in turribus tuis.

[Oremus.]

Deus, a quo sancta desideria, recta consilia et iusta sunt opera: da servis tuis illam, quam mundus dare non potest, pacem; ut et corda nostra mandatis tuis dedita, et, hostium sublata formidine, tempora sint tua protectione tranquilla. Per Dominum nostrum Iesum Christum, Filium tuum, qui tecum vivit et regnat in unitate Spiritus Sancti, Deus, per omnia sæcula sæculorum.

℟. Amen.
"""
        ),
        BookPrayer(
            id: "conversion_of_sinners",
            title: "For the Conversion of Sinners",
            latinTitle: nil,
            origin: "The Raccolta · Pope Pius IX",
            note: "An offering of Christ's Passion and Our Lady's sorrows, for sinners and for the whole Church.",
            english: """
Eternal Father, we offer Thee the Blood, the Passion and the Death of Jesus Christ, the sorrows of Mary most holy and of St Joseph, in satisfaction for our sins, in relief of the holy souls in Purgatory, for the needs of our holy Mother the Church, and for the conversion of sinners. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "deceased_parents",
            title: "For One's Father and Mother Who Have Died",
            latinTitle: "Deus, qui nos patrem et matrem",
            origin: "The Roman Missal · the collect for deceased parents",
            note: "The Missal's prayer for a son or daughter whose parents have gone before them.",
            english: """
[Let us pray.]

O God, Who hast commanded us to honour our father and our mother: in Thy mercy have pity on the souls of my father and mother, and forgive them their sins; and make me to see them again in the joy of everlasting light. Through Christ our Lord.

℟. Amen.
""",
            latin: """
[Oremus.]

Deus, qui nos patrem et matrem honorare præcepisti: miserere clementer animabus patris et matris meæ, eorumque peccata dimitte; meque eos in æternæ claritatis gaudio fac videre. Per Christum Dominum nostrum.

℟. Amen.
"""
        ),
        BookPrayer(
            id: "my_god_and_my_all",
            title: "My God and My All",
            latinTitle: "Deus meus et omnia",
            origin: "St Francis of Assisi · 13th century",
            note: "St Francis's prayer, said over and over through a whole night, in a breath at any hour.",
            english: """
My God and my all.
""",
            latin: """
Deus meus et omnia.
"""
        ),
        BookPrayer(
            id: "my_lord_and_my_god",
            title: "My Lord and My God",
            latinTitle: "Dominus meus et Deus meus",
            origin: "St Thomas the Apostle · John 20:28",
            note: "St Thomas's words to the risen Christ, said in silence at the elevation of the Host at Mass.",
            english: """
My Lord and my God.
""",
            latin: """
Dominus meus et Deus meus.
"""
        ),
        BookPrayer(
            id: "jesus_i_trust_in_thee",
            title: "Jesus, I Trust in Thee",
            latinTitle: nil,
            origin: "St Faustina Kowalska · 1931",
            note: "The words Our Lord asked to be written beneath His image of Divine Mercy.",
            english: """
Jesus, I trust in Thee.
""",
            latin: nil
        ),
        BookPrayer(
            id: "sacred_heart_trust",
            title: "Most Sacred Heart of Jesus",
            latinTitle: nil,
            origin: "The Raccolta",
            note: "Said in any trouble, and often through June, the month of the Sacred Heart.",
            english: """
Most Sacred Heart of Jesus, I place all my trust in Thee.
""",
            latin: nil
        ),
        BookPrayer(
            id: "o_sacrament_most_holy",
            title: "O Sacrament Most Holy",
            latinTitle: nil,
            origin: "The Raccolta",
            note: "Said before the Blessed Sacrament, on entering a church or passing one.",
            english: """
O Sacrament most holy, O Sacrament divine,
all praise and all thanksgiving be every moment Thine.
""",
            latin: nil
        ),
        BookPrayer(
            id: "jmj_heart_and_soul",
            title: "Jesus, Mary and Joseph, I Give You My Heart",
            latinTitle: nil,
            origin: "The Raccolta · Pope Pius VII, 1807",
            note: "Three short prayers for a good death, said each day and at the last.",
            english: """
Jesus, Mary and Joseph, I give you my heart and my soul.
Jesus, Mary and Joseph, assist me in my last agony.
Jesus, Mary and Joseph, may I breathe forth my soul in peace with you.
""",
            latin: nil
        ),
        BookPrayer(
            id: "my_jesus_i_love_thee",
            title: "My Jesus, I Love Thee",
            latinTitle: nil,
            origin: "Traditional",
            note: "A short act of love, said in a breath at any moment of the day.",
            english: """
My Jesus, I love Thee above all things.
""",
            latin: nil
        ),
        BookPrayer(
            id: "holy_spirit_enlighten",
            title: "Holy Spirit, Spirit of Truth",
            latinTitle: nil,
            origin: "The Raccolta",
            note: "Said for light, and for the unity of all peoples in the faith.",
            english: """
Holy Spirit, Spirit of truth, come into our hearts; shed the brightness of Thy light on all nations, that they may be of one faith and pleasing to God.
""",
            latin: nil
        ),
        BookPrayer(
            id: "st_joseph_pray",
            title: "St Joseph, Pray for Us",
            latinTitle: "Sancte Ioseph, ora pro nobis",
            origin: "Traditional",
            note: "Said in any need, and especially on Wednesdays and through March.",
            english: """
St Joseph, pray for us.
""",
            latin: """
Sancte Ioseph, ora pro nobis.
"""
        ),
    ]
}
