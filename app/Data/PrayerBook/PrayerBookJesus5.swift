//
//  PrayerBookJesus5.swift
//  Lumen Viae
//
//  The Prayer Book's chapter of Jesus: prayers of self-giving and trust, for peace, generosity, abandonment, calm and the spreading of His light.
//  Sources: "Belle prière à faire pendant la messe", La Clochette (Paris, December 1912), anonymous; English: our own literal rendering from the French of La Clochette
//  The prayer for generosity, attributed to St Ignatius of Loyola, in its French form ("Seigneur Jésus, apprenez-nous à être généreux…"), as the French Scouts prayed it from the 1920s; English: our own literal rendering from the French
//  St Charles de Foucauld, his meditation of 1896 on Luke 23:46, from which the prayer of abandonment ("Mon Père, je m'abandonne à vous…") is drawn; English: our own literal rendering from the French of Foucauld
//  St Teresa of Ávila, the lines found in her breviary ("Nada te turbe, nada te espante…"); English: our own literal rendering from the Spanish of St Teresa
//  St John Henry Newman, Meditations and Devotions (London, 1893), "Jesus the Light of the Soul", in the shortened form the Missionaries of Charity pray after Communion; English: rendered fresh from Newman's text in that adapted form, not copied from any printed version of the adaptation
//

import Foundation

extension PrayerBookTexts {

    static let jesus5: [BookPrayer] = [
        BookPrayer(
            id: "peace_prayer",
            title: "The Peace Prayer",
            latinTitle: nil,
            origin: "Anonymous · 1912, long attributed to St Francis of Assisi",
            note: "Said to ask that one's whole life be made a channel of God's peace to others.",
            english: """
Lord, make me an instrument of Thy peace.

Where there is hatred, let me bring love;
where there is offence, let me bring pardon;
where there is discord, let me bring union;
where there is error, let me bring truth;
where there is doubt, let me bring faith;
where there is despair, let me bring hope;
where there is darkness, let me bring Thy light;
where there is sadness, let me bring joy.

O Master, grant that I may seek not so much
to be consoled as to console,
to be understood as to understand,
to be loved as to love.

For it is in giving that we receive,
in forgetting ourselves that we find,
in pardoning that we are pardoned,
and in dying that we rise again to eternal life. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "generosity_ignatius",
            title: "Prayer for Generosity",
            latinTitle: nil,
            origin: "Attributed to St Ignatius of Loyola · in its French form, 20th century",
            note: "Said to ask for a heart that gives itself to God's service without counting the cost.",
            english: """
Lord Jesus, teach us to be generous;
to serve Thee as Thou deservest;
to give without counting;
to fight without heeding the wounds;
to labour without seeking rest;
to spend ourselves without looking for any other reward
than to know that we are doing Thy holy will. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "abandonment_foucauld",
            title: "Prayer of Abandonment",
            latinTitle: nil,
            origin: "St Charles de Foucauld · 1896",
            note: "Drawn from his meditation on Our Lord's last words on the Cross, and said to give oneself wholly into the Father's hands.",
            english: """
My Father, I abandon myself to Thee;
do with me what Thou wilt.
Whatever Thou mayest do with me, I thank Thee.
I am ready for all, I accept all.
Let only Thy will be done in me and in all Thy creatures;
I desire nothing else, my God.

Into Thy hands I commend my soul;
I give it to Thee, my God,
with all the love of my heart,
because I love Thee,
and because for me it is a need of love to give myself,
to put myself into Thy hands without measure,
with boundless confidence,
for Thou art my Father. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "nada_te_turbe",
            title: "Let Nothing Disturb Thee",
            latinTitle: nil,
            origin: "St Teresa of Ávila · 16th century",
            note: "Found written in her breviary after her death, and said in any trouble of mind.",
            english: """
Let nothing disturb thee,
let nothing affright thee;
all things are passing,
God never changes.
Patience obtains all things.
Whoever has God
wants for nothing:
God alone suffices.
""",
            latin: nil
        ),
        BookPrayer(
            id: "radiating_christ",
            title: "Prayer for Radiating Christ",
            latinTitle: nil,
            origin: "After St John Henry Newman · 19th century, as the Missionaries of Charity pray it",
            note: "Said after Holy Communion, asking that Christ may shine through one's life to everyone one meets.",
            english: """
Dear Jesus, help me to carry Thy fragrance wherever I go.

Fill my soul with Thy spirit and Thy life. Enter into my whole being and take hold of it so wholly that my life may be only a shining of Thine.

Shine through me, and dwell in me so, that every soul I come near may feel Thy presence in mine. Let them look up and see no longer me, but only Jesus.

Stay with me, and then I shall begin to shine as Thou shinest, so to shine as to be a light to others. The light, O Jesus, will be all from Thee; none of it will be mine. It will be Thou shining on others through me.

Let me thus praise Thee in the way Thou lovest best, by shining on those around me. Let me preach Thee without preaching, not by words but by my example, by the drawing power and the sympathy of what I do, by the plain fullness of the love my heart bears for Thee. Amen.
""",
            latin: nil
        ),
    ]
}
