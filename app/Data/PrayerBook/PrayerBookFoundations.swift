//
//  PrayerBookFoundations.swift
//  Lumen Viae
//
//  The Prayer Book's first prayers, its prayers of penance and
//  Confession, for the faithful departed, and for the Church.
//

import Foundation

extension PrayerBookTexts {

    static let foundations: [BookPrayer] = [
        BookPrayer(
            id: "nicene_creed",
            title: "The Nicene Creed",
            latinTitle: "Symbolum Nicænum",
            origin: "Council of Constantinople · 381",
            note: "Said at Mass after the Gospel on Sundays and the greater feasts.",
            english: """
I believe in one God, the Father almighty, Maker of heaven and earth,
and of all things visible and invisible.

And in one Lord Jesus Christ, the only-begotten Son of God,
born of the Father before all ages;
God of God, Light of Light, true God of true God;
begotten, not made; of one substance with the Father; by whom all things were made.
Who for us men and for our salvation came down from heaven.

[Here all genuflect.]
And became incarnate by the Holy Ghost of the Virgin Mary: and was made man.
He was crucified also for us, suffered under Pontius Pilate, and was buried.
And the third day He rose again according to the Scriptures.
And He ascended into heaven, and sitteth at the right hand of the Father.
And He shall come again with glory to judge the living and the dead;
of whose kingdom there shall be no end.

And in the Holy Ghost, the Lord and Giver of life,
who proceedeth from the Father and the Son;
who together with the Father and the Son is adored and glorified;
who spoke by the Prophets.
And one holy, catholic and apostolic Church.
I confess one baptism for the remission of sins.
And I look for the resurrection of the dead,
and the life of the world to come. Amen.
""",
            latin: """
Credo in unum Deum, Patrem omnipotentem, factorem caeli et terrae,
visibilium omnium et invisibilium.

Et in unum Dominum Iesum Christum, Filium Dei unigenitum.
Et ex Patre natum ante omnia saecula.
Deum de Deo, lumen de lumine, Deum verum de Deo vero.
Genitum, non factum, consubstantialem Patri: per quem omnia facta sunt.
Qui propter nos homines et propter nostram salutem descendit de caelis.

[Hic genuflectitur.]
Et incarnatus est de Spiritu Sancto ex Maria Virgine: et homo factus est.
Crucifixus etiam pro nobis: sub Pontio Pilato passus, et sepultus est.
Et resurrexit tertia die, secundum Scripturas.
Et ascendit in caelum: sedet ad dexteram Patris.
Et iterum venturus est cum gloria iudicare vivos et mortuos:
cuius regni non erit finis.

Et in Spiritum Sanctum, Dominum et vivificantem:
qui ex Patre Filioque procedit.
Qui cum Patre et Filio simul adoratur et conglorificatur:
qui locutus est per Prophetas.
Et unam, sanctam, catholicam et apostolicam Ecclesiam.
Confiteor unum baptisma in remissionem peccatorum.
Et exspecto resurrectionem mortuorum.
Et vitam venturi saeculi. Amen.
"""
        ),
        BookPrayer(
            id: "act_of_faith",
            title: "The Act of Faith",
            latinTitle: "Actus Fidei",
            origin: "The Raccolta, an old Vatican prayer book",
            note: "Made on waking and at night, with the Acts of Hope and Charity.",
            english: """
O Lord God, I firmly believe and profess
each and every truth which the holy Catholic Church proposes,
because Thou, O God, hast revealed them all,
who art the eternal Truth and Wisdom,
who canst neither deceive nor be deceived.
In this faith I am resolved to live and die. Amen.
""",
            latin: """
Domine Deus, firma fide credo et confiteor
omnia et singula quae sancta Ecclesia Catholica proponit,
quia tu, Deus, ea omnia revelasti,
qui es aeterna veritas et sapientia,
quae nec fallere nec falli potest.
In hac fide vivere et mori statuo. Amen.
"""
        ),
        BookPrayer(
            id: "act_of_hope",
            title: "The Act of Hope",
            latinTitle: "Actus Spei",
            origin: "The Raccolta, an old Vatican prayer book",
            note: "Made on waking and at night, after the Act of Faith.",
            english: """
O Lord God, I hope by Thy grace for the pardon of all my sins,
and after this life to gain eternal happiness,
because Thou hast promised it,
who art infinitely powerful, faithful, kind and merciful.
In this hope I am resolved to live and die. Amen.
""",
            latin: """
Domine Deus, spero per gratiam tuam remissionem omnium peccatorum,
et post hanc vitam aeternam felicitatem me esse consecuturum,
quia tu promisisti,
qui es infinite potens, fidelis, benignus et misericors.
In hac spe vivere et mori statuo. Amen.
"""
        ),
        BookPrayer(
            id: "act_of_charity",
            title: "The Act of Charity",
            latinTitle: "Actus Caritatis",
            origin: "The Raccolta, an old Vatican prayer book",
            note: "Made on waking and at night, after the Acts of Faith and Hope.",
            english: """
O Lord God, I love Thee above all things,
and my neighbour for Thy sake,
because Thou art the highest, infinite and most perfect Good,
worthy of all love.
In this love I am resolved to live and die. Amen.
""",
            latin: """
Domine Deus, amo te super omnia,
et proximum meum propter te,
quia tu es summum, infinitum et perfectissimum bonum,
omni dilectione dignum.
In hac caritate vivere et mori statuo. Amen.
"""
        ),
        BookPrayer(
            id: "confiteor",
            title: "I Confess",
            latinTitle: "Confiteor",
            origin: "The Mass",
            note: "Said before Confession and in night prayers, striking the breast at the words of fault.",
            english: """
I confess to almighty God,
to blessed Mary ever Virgin,
to blessed Michael the Archangel,
to blessed John the Baptist,
to the holy Apostles Peter and Paul,
and to all the Saints,
that I have sinned exceedingly in thought, word and deed:

[Strike the breast three times.]
through my fault, through my fault, through my most grievous fault.

Therefore I beseech blessed Mary ever Virgin,
blessed Michael the Archangel,
blessed John the Baptist,
the holy Apostles Peter and Paul,
and all the Saints,
to pray to the Lord our God for me. Amen.
""",
            latin: """
Confiteor Deo omnipotenti,
beatae Mariae semper Virgini,
beato Michaeli Archangelo,
beato Ioanni Baptistae,
sanctis Apostolis Petro et Paulo,
et omnibus Sanctis,
quia peccavi nimis cogitatione, verbo et opere:

[Percutit sibi pectus ter.]
mea culpa, mea culpa, mea maxima culpa.

Ideo precor beatam Mariam semper Virginem,
beatum Michaelem Archangelum,
beatum Ioannem Baptistam,
sanctos Apostolos Petrum et Paulum,
et omnes Sanctos,
orare pro me ad Dominum Deum nostrum. Amen.
"""
        ),
        BookPrayer(
            id: "before_confession",
            title: "Prayer before Confession",
            latinTitle: nil,
            origin: "Traditional",
            note: "Said on coming to Confession, before the examination of conscience.",
            english: """
Receive my confession, O most loving and gracious Lord Jesus Christ, only hope for the salvation of my soul. Grant to me true contrition of soul, so that day and night I may by penance make satisfaction for my many sins.

Saviour of the world, O good Jesus, who didst give Thyself to the death of the Cross to save sinners, look upon me, most wretched of all sinners; have pity on me, and give me the light to know my sins, true sorrow for them, and a firm purpose of never committing them again. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "the_confession",
            title: "Making Your Confession",
            latinTitle: nil,
            origin: "The Sacrament of Confession",
            note: "What is said in the confessional, from the Sign of the Cross to the prayers the priest gives you (your penance).",
            english: """
[Kneel, and make the Sign of the Cross.]

Bless me, Father, for I have sinned.
It has been [time] since my last confession.

[Confess your sins plainly: every mortal sin in its kind and number, as nearly as you can, and any venial sins you wish. Then say:]

For these and all the sins of my past life, especially for [a sin], I am heartily sorry.

[Listen to the priest's counsel and to the penance he gives. When he asks, say the Act of Contrition.]

[The priest gives the absolution. Answer:]
℟. Amen.

[The priest may dismiss you, saying:]
℣. Give thanks to the Lord, for He is good.
℟. For His mercy endureth for ever.

[Go, and say your penance.]
""",
            latin: nil
        ),
        BookPrayer(
            id: "after_confession",
            title: "Thanksgiving after Confession",
            latinTitle: nil,
            origin: "Traditional",
            note: "Said after leaving the confessional, once you have said the prayers the priest gave you (your penance).",
            english: """
[If the penance given is a prayer, say it first, before anything else.]

O almighty and most merciful God, who, according to the multitude of Thy mercies, hast vouchsafed once more to receive me, after so many times going astray from Thee, and to admit me to the grace of reconciliation: I give Thee thanks with all the powers of my soul for this and for all the mercies, graces and blessings Thou hast bestowed upon me; and prostrating myself at Thy sacred feet, I offer myself to be henceforth for ever Thine.

Let nothing in life or death ever separate me from Thee. I renounce with my whole soul all my treasons against Thee, and all the sins of my past life; I renew the promises made for me in Baptism, and from this moment I dedicate myself for ever to Thy love and service.

Grant that for the time to come I may abhor sin more than death itself, and avoid all such occasions and companies as have unhappily brought me to it. This I resolve to do by the aid of Thy divine grace, without which I can do nothing. Supply by Thy mercy whatever has been wanting in this my confession, and give me grace to be now and always a true penitent. Through Jesus Christ our Lord. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "requiem_aeternam",
            title: "Eternal Rest",
            latinTitle: "Requiem æternam",
            origin: "The Mass · 4 Esdras 2:34–35",
            note: "Said for the dead, and at the end of grace after meals.",
            english: """
℣. Eternal rest grant unto them, O Lord.
℟. And let perpetual light shine upon them.
℣. May they rest in peace.
℟. Amen.
""",
            latin: """
℣. Requiem aeternam dona eis, Domine.
℟. Et lux perpetua luceat eis.
℣. Requiescant in pace.
℟. Amen.
"""
        ),
        BookPrayer(
            id: "fidelium_deus",
            title: "For All the Faithful Departed",
            latinTitle: "Fidelium, Deus",
            origin: "The Mass",
            note: "The Church's prayer for all who have died, said after Psalm 129, Out of the Depths.",
            english: """
[Let us pray.]
O God, the Creator and Redeemer of all the faithful,
grant to the souls of Thy servants departed the remission of all their sins,
that through pious supplications they may obtain the pardon which they have always desired.
Who livest and reignest world without end. Amen.
""",
            latin: """
[Oremus.]
Fidelium, Deus, omnium Conditor et Redemptor,
animabus famulorum famularumque tuarum remissionem cunctorum tribue peccatorum,
ut indulgentiam, quam semper optaverunt, piis supplicationibus consequantur.
Qui vivis et regnas in saecula saeculorum. Amen.
"""
        ),
        BookPrayer(
            id: "prayer_for_the_pope",
            title: "Prayer for the Pope",
            latinTitle: "Oremus pro Pontifice",
            origin: "The Mass · Psalm 40:3",
            note: "Said for the Pope by name, at Benediction (adoration of the Host, ending in a blessing) and in private prayer.",
            english: """
℣. Let us pray for our Pope N.
℟. The Lord preserve him, and give him life, and make him blessed upon the earth, and deliver him not up to the will of his enemies.

[Let us pray.]
O God, the Shepherd and Ruler of all the faithful,
look mercifully upon Thy servant N., whom Thou hast set over Thy Church as its chief shepherd;
grant him, we beseech Thee, by word and example to profit those over whom he is set,
that together with the flock committed to him he may come to life everlasting.
Through Christ our Lord. Amen.
""",
            latin: """
℣. Oremus pro Pontifice nostro N.
℟. Dominus conservet eum, et vivificet eum, et beatum faciat eum in terra, et non tradat eum in animam inimicorum eius.

[Oremus.]
Deus, omnium fidelium pastor et rector,
famulum tuum N., quem pastorem Ecclesiae tuae praeesse voluisti, propitius respice:
da ei, quaesumus, verbo et exemplo, quibus praeest, proficere,
ut ad vitam, una cum grege sibi credito, perveniat sempiternam.
Per Christum Dominum nostrum. Amen.
"""
        ),
        BookPrayer(
            id: "de_profundis",
            title: "Psalm 129 · Out of the Depths",
            latinTitle: "De profundis",
            origin: "Psalm 129 · Douay-Rheims",
            note: "The sixth of the seven psalms of sorrow for sin, said above all for those who have died.",
            english: """
Out of the depths I have cried to Thee, O Lord: * Lord, hear my voice.
Let Thy ears be attentive * to the voice of my supplication.
If Thou, O Lord, wilt mark iniquities: * Lord, who shall stand it?
For with Thee there is merciful forgiveness: * and by reason of Thy law, I have waited for Thee, O Lord.

My soul hath relied on His word: * my soul hath hoped in the Lord.
From the morning watch even until night, * let Israel hope in the Lord.
Because with the Lord there is mercy: * and with Him plentiful redemption.
And He shall redeem Israel * from all his iniquities.

℣. Eternal rest grant unto them, O Lord.
℟. And let perpetual light shine upon them.
""",
            latin: """
De profundis clamavi ad te, Domine: * Domine, exaudi vocem meam.
Fiant aures tuae intendentes * in vocem deprecationis meae.
Si iniquitates observaveris, Domine: * Domine, quis sustinebit?
Quia apud te propitiatio est: * et propter legem tuam sustinui te, Domine.

Sustinuit anima mea in verbo eius: * speravit anima mea in Domino.
A custodia matutina usque ad noctem: * speret Israel in Domino.
Quia apud Dominum misericordia: * et copiosa apud eum redemptio.
Et ipse redimet Israel * ex omnibus iniquitatibus eius.

℣. Requiem aeternam dona eis, Domine.
℟. Et lux perpetua luceat eis.
"""
        ),
        BookPrayer(
            id: "beati_quorum",
            title: "Psalm 31 · Blessed Are They",
            latinTitle: "Beati quorum",
            origin: "Psalm 31 · Douay-Rheims",
            note: "The second of the seven psalms of sorrow for sin, often given by the priest as your penance after Confession.",
            english: """
Blessed are they whose iniquities are forgiven: * and whose sins are covered.
Blessed is the man to whom the Lord hath not imputed sin, * and in whose spirit there is no guile.
Because I was silent my bones grew old, * whilst I cried out all the day long.
For day and night Thy hand was heavy upon me: * I am turned in my anguish, whilst the thorn is fastened.

I have acknowledged my sin to Thee: * and my injustice I have not concealed.
I said, I will confess against myself my injustice to the Lord: * and Thou hast forgiven the wickedness of my sin.
For this shall every one that is holy pray to Thee, * in a seasonable time.
And yet in a flood of many waters, * they shall not come nigh unto him.

Thou art my refuge from the trouble which hath encompassed me: * my joy, deliver me from them that surround me.
I will give thee understanding, and I will instruct thee in this way in which thou shalt go: * I will fix my eyes upon thee.
Do not become like the horse and the mule, * who have no understanding.
With bit and bridle bind fast their jaws, * who come not near unto thee.

Many are the scourges of the sinner, * but mercy shall encompass him that hopeth in the Lord.
Be glad in the Lord, and rejoice, ye just, * and glory, all ye right of heart.

Glory be to the Father, and to the Son, * and to the Holy Ghost.
As it was in the beginning, is now, and ever shall be, * world without end. Amen.
""",
            latin: """
Beati quorum remissae sunt iniquitates: * et quorum tecta sunt peccata.
Beatus vir, cui non imputavit Dominus peccatum, * nec est in spiritu eius dolus.
Quoniam tacui, inveteraverunt ossa mea, * dum clamarem tota die.
Quoniam die ac nocte gravata est super me manus tua: * conversus sum in aerumna mea, dum configitur spina.

Delictum meum cognitum tibi feci: * et iniustitiam meam non abscondi.
Dixi: Confitebor adversum me iniustitiam meam Domino: * et tu remisisti impietatem peccati mei.
Pro hac orabit ad te omnis sanctus, * in tempore opportuno.
Verumtamen in diluvio aquarum multarum, * ad eum non approximabunt.

Tu es refugium meum a tribulatione, quae circumdedit me: * exsultatio mea, erue me a circumdantibus me.
Intellectum tibi dabo, et instruam te in via hac, qua gradieris: * firmabo super te oculos meos.
Nolite fieri sicut equus et mulus, * quibus non est intellectus.
In camo et freno maxillas eorum constringe, * qui non approximant ad te.

Multa flagella peccatoris, * sperantem autem in Domino misericordia circumdabit.
Laetamini in Domino et exsultate, iusti, * et gloriamini, omnes recti corde.

Gloria Patri, et Filio, * et Spiritui Sancto.
Sicut erat in principio, et nunc, et semper, * et in saecula saeculorum. Amen.
"""
        ),
        BookPrayer(
            id: "miserere",
            title: "Psalm 50 · Have Mercy on Me",
            latinTitle: "Miserere",
            origin: "Psalm 50 · Douay-Rheims",
            note: "The fourth of the seven psalms of sorrow for sin: David's prayer for mercy after his sin.",
            english: """
Have mercy on me, O God, * according to Thy great mercy.
And according to the multitude of Thy tender mercies * blot out my iniquity.
Wash me yet more from my iniquity, * and cleanse me from my sin.
For I know my iniquity, * and my sin is always before me.

To Thee only have I sinned, and have done evil before Thee: * that Thou mayst be justified in Thy words, and mayst overcome when Thou art judged.
For behold I was conceived in iniquities: * and in sins did my mother conceive me.
For behold Thou hast loved truth: * the uncertain and hidden things of Thy wisdom Thou hast made manifest to me.
Thou shalt sprinkle me with hyssop, and I shall be cleansed: * Thou shalt wash me, and I shall be made whiter than snow.

To my hearing Thou shalt give joy and gladness: * and the bones that have been humbled shall rejoice.
Turn away Thy face from my sins, * and blot out all my iniquities.
Create a clean heart in me, O God: * and renew a right spirit within my bowels.
Cast me not away from Thy face: * and take not Thy holy spirit from me.

Restore unto me the joy of Thy salvation, * and strengthen me with a perfect spirit.
I will teach the unjust Thy ways: * and the wicked shall be converted to Thee.
Deliver me from blood, O God, Thou God of my salvation: * and my tongue shall extol Thy justice.
O Lord, Thou wilt open my lips: * and my mouth shall declare Thy praise.

For if Thou hadst desired sacrifice, I would indeed have given it: * with burnt offerings Thou wilt not be delighted.
A sacrifice to God is an afflicted spirit: * a contrite and humbled heart, O God, Thou wilt not despise.
Deal favourably, O Lord, in Thy good will with Sion: * that the walls of Jerusalem may be built up.
Then shalt Thou accept the sacrifice of justice, oblations and whole burnt offerings: * then shall they lay calves upon Thy altar.

Glory be to the Father, and to the Son, * and to the Holy Ghost.
As it was in the beginning, is now, and ever shall be, * world without end. Amen.
""",
            latin: """
Miserere mei, Deus, * secundum magnam misericordiam tuam.
Et secundum multitudinem miserationum tuarum, * dele iniquitatem meam.
Amplius lava me ab iniquitate mea: * et a peccato meo munda me.
Quoniam iniquitatem meam ego cognosco: * et peccatum meum contra me est semper.

Tibi soli peccavi, et malum coram te feci: * ut iustificeris in sermonibus tuis, et vincas cum iudicaris.
Ecce enim in iniquitatibus conceptus sum: * et in peccatis concepit me mater mea.
Ecce enim veritatem dilexisti: * incerta et occulta sapientiae tuae manifestasti mihi.
Asperges me hyssopo, et mundabor: * lavabis me, et super nivem dealbabor.

Auditui meo dabis gaudium et laetitiam: * et exsultabunt ossa humiliata.
Averte faciem tuam a peccatis meis: * et omnes iniquitates meas dele.
Cor mundum crea in me, Deus: * et spiritum rectum innova in visceribus meis.
Ne proiicias me a facie tua: * et spiritum sanctum tuum ne auferas a me.

Redde mihi laetitiam salutaris tui: * et spiritu principali confirma me.
Docebo iniquos vias tuas: * et impii ad te convertentur.
Libera me de sanguinibus, Deus, Deus salutis meae: * et exsultabit lingua mea iustitiam tuam.
Domine, labia mea aperies: * et os meum annuntiabit laudem tuam.

Quoniam si voluisses sacrificium, dedissem utique: * holocaustis non delectaberis.
Sacrificium Deo spiritus contribulatus: * cor contritum, et humiliatum, Deus, non despicies.
Benigne fac, Domine, in bona voluntate tua Sion: * ut aedificentur muri Ierusalem.
Tunc acceptabis sacrificium iustitiae, oblationes, et holocausta: * tunc imponent super altare tuum vitulos.

Gloria Patri, et Filio, * et Spiritui Sancto.
Sicut erat in principio, et nunc, et semper, * et in saecula saeculorum. Amen.
"""
        ),
        BookPrayer(
            id: "examination_of_conscience",
            title: "Examination of Conscience",
            latinTitle: nil,
            origin: "After the Ten Commandments",
            note: "Read slowly before Confession; pause where a question touches you.",
            english: """
[Ask the Holy Ghost for light, then go slowly; pause where a question touches you.]

[I. I am the Lord thy God; thou shalt not have strange gods before Me.]
Have I neglected my daily prayers, or said them without attention?
Have I doubted or denied a truth of the faith, or put my faith in danger by what I read or the company I keep?
Have I sought help from fortune-tellers, horoscopes, charms or the occult?
Have I despaired of God's mercy, or presumed upon it in order to sin?
Have I received a sacrament unworthily, or treated holy things with irreverence?

[II. Thou shalt not take the name of the Lord thy God in vain.]
Have I used the name of God, of Jesus, or of the Saints carelessly or in anger?
Have I cursed, or spoken with contempt of God, of the Church, or of holy things?
Have I sworn an oath falsely, or without need?
Have I broken a vow or a promise made to God?

[III. Remember thou keep holy the Sabbath day.]
Have I missed Mass on a Sunday or holyday of obligation through my own fault?
Have I come late or left early without good reason, or been wilfully distracted at Mass?
Have I done unnecessary servile work on Sunday, or kept others from keeping it holy?

[IV. Honour thy father and thy mother.]
Have I been disrespectful or disobedient to my parents, or neglected them in their need?
Have I failed to teach my children the faith, or to give them a good example?
Have I failed in my duties to my husband or wife, or to those in my care?
Have I disobeyed lawful authority, or neglected my duties as a citizen?

[V. Thou shalt not kill.]
Have I nursed anger, hatred or a desire for revenge, or refused to forgive?
Have I injured anyone in body, or had any part in an abortion?
Have I harmed my own life or health by excess in drink or drugs, or by recklessness?
Have I led another into sin by my words or my example?

[VI. Thou shalt not commit adultery.]
Have I committed impure acts, alone or with another?
Have I looked at, read or watched what is impure?
Have I been unfaithful to my husband or wife, or frustrated the purpose of marriage?
Have I put myself needlessly in the occasion of impurity?

[VII. Thou shalt not steal.]
Have I stolen, or kept what belongs to another?
Have I cheated anyone, or damaged another's property?
Have I failed to pay my debts, or to give honest work for my wage?
Have I neglected to make restitution where I owe it?
Have I refused help to the poor when I was able to give it?

[VIII. Thou shalt not bear false witness against thy neighbour.]
Have I lied?
Have I made known another's faults without need?
Have I harmed anyone's good name by saying what is untrue?
Have I judged others rashly, or betrayed a secret entrusted to me?

[IX. Thou shalt not covet thy neighbour's wife.]
Have I consented to impure thoughts or desires, or taken pleasure in them?
Have I desired another's husband or wife?
Have I been careless in guarding my eyes and my imagination?

[X. Thou shalt not covet thy neighbour's goods.]
Have I envied what others have?
Have I desired to have unjustly what belongs to another?
Have I set my heart on money and possessions more than on God?

[The Precepts of the Church]
Have I kept the days of fasting and abstinence?
Have I confessed at least once a year, and received Holy Communion in the Easter time?
Have I helped to support the Church according to my means?
Have I kept the laws of the Church concerning marriage?

[The Seven Capital Sins]
Pride: have I thought too well of myself, or looked down on others?
Covetousness: have I loved money and things too much?
Lust: have I given way to impurity in thought, word or deed?
Anger: have I lost my temper, or kept up resentment?
Gluttony: have I eaten or drunk to excess?
Envy: have I been saddened by another's good?
Sloth: have I been idle in my duties, or in the service of God?

[Then make an act of contrition, and resolve by God's grace to sin no more.]
""",
            latin: nil
        ),
        BookPrayer(
            id: "te_deum",
            title: "We Praise Thee, O God",
            latinTitle: "Te Deum",
            origin: "The Hours of Prayer · 4th century",
            note: "Sung at the end of the Church's Night Vigil (Matins) on Sundays and feast days, and to thank God for a great gift.",
            english: """
We praise Thee, O God: we acknowledge Thee to be the Lord.
Thee, the eternal Father, all the earth doth worship.
To Thee all the Angels, to Thee the heavens and all the Powers,
to Thee the Cherubim and Seraphim cry out with unceasing voice:
Holy, Holy, Holy, Lord God of hosts.
The heavens and the earth are full of the majesty of Thy glory.

Thee the glorious choir of the Apostles,
Thee the praiseworthy company of the Prophets,
Thee the white-robed army of Martyrs doth praise.
Thee the holy Church throughout the whole world doth confess:
the Father of boundless majesty;
Thine adorable, true and only Son;
and the Holy Ghost, the Paraclete.

Thou, O Christ, art the King of glory.
Thou art the everlasting Son of the Father.
Thou, when Thou wouldst take manhood upon Thee to set man free, didst not shrink from the Virgin's womb.
Thou, having overcome the sting of death, didst open the kingdom of heaven to them that believe.
Thou sittest at the right hand of God, in the glory of the Father.
Thou art believed to be the Judge who shall come.

[Here all kneel.]
We beseech Thee, therefore, come to the help of Thy servants, whom Thou hast redeemed with Thy precious blood.
Make them to be numbered with Thy Saints in glory everlasting.

Save Thy people, O Lord, and bless Thine inheritance.
Rule them, and lift them up for ever.
Every day we bless Thee.
And we praise Thy name for ever, and for ever and ever.
Deign, O Lord, to keep us this day without sin.
Have mercy on us, O Lord, have mercy on us.
Let Thy mercy, O Lord, be upon us, as we have hoped in Thee.
In Thee, O Lord, have I hoped: let me not be confounded for ever.
""",
            latin: """
Te Deum laudamus: te Dominum confitemur.
Te aeternum Patrem omnis terra veneratur.
Tibi omnes Angeli, tibi caeli et universae Potestates,
Tibi Cherubim et Seraphim incessabili voce proclamant:
Sanctus, Sanctus, Sanctus Dominus Deus Sabaoth.
Pleni sunt caeli et terra maiestatis gloriae tuae.

Te gloriosus Apostolorum chorus,
Te Prophetarum laudabilis numerus,
Te Martyrum candidatus laudat exercitus.
Te per orbem terrarum sancta confitetur Ecclesia,
Patrem immensae maiestatis;
Venerandum tuum verum et unicum Filium;
Sanctum quoque Paraclitum Spiritum.

Tu Rex gloriae, Christe.
Tu Patris sempiternus es Filius.
Tu ad liberandum suscepturus hominem, non horruisti Virginis uterum.
Tu, devicto mortis aculeo, aperuisti credentibus regna caelorum.
Tu ad dexteram Dei sedes, in gloria Patris.
Iudex crederis esse venturus.

[Hic genuflectitur.]
Te ergo quaesumus, tuis famulis subveni, quos pretioso sanguine redemisti.
Aeterna fac cum Sanctis tuis in gloria numerari.

Salvum fac populum tuum, Domine, et benedic hereditati tuae.
Et rege eos, et extolle illos usque in aeternum.
Per singulos dies benedicimus te.
Et laudamus nomen tuum in saeculum, et in saeculum saeculi.
Dignare, Domine, die isto sine peccato nos custodire.
Miserere nostri, Domine, miserere nostri.
Fiat misericordia tua, Domine, super nos, quemadmodum speravimus in te.
In te, Domine, speravi: non confundar in aeternum.
"""
        )
    ]
}
