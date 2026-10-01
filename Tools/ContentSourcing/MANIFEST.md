# Content sourcing manifest

Generated from `sources.py` by `build_manifest.py`; edit there. Machine-readable: `manifest.json`.

**Status this round:** the session's network policy refused every source host (verbumgloriae.es, commons.wikimedia.org, upload.wikimedia.org, the Met's, AIC's and other museum APIs), so nothing is downloaded and no licence page has been read. Every entry is `candidate` or `identified`. `fetch.py` resolves each against Commons, reads the licence there, writes the imagesets, and records what it found; then rerun `build_manifest.py`. Run it here once the hosts are allowed, or on the Mac.

## New paintings

| Imageset | Slot | Work | Creator | Date | Collection | Licence | Status |
|---|---|---|---|---|---|---|---|
| `season_advent` | (a) Advent: Chant Year/Learn boards, 'Learn Rorate Cæli before Advent' card; Year board's Advent season | The Immaculate Conception of Los Venerables | Bartolomé Esteban Murillo (1617–1682) | c. 1678 | Museo del Prado, Madrid | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `devotion_holy_trinity` | (b) Sunday · the Holy Trinity: Chant Main board, weekday devotions strip | The Holy Trinity | Jusepe de Ribera (1591–1652) | c. 1635 | Museo del Prado, Madrid | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `devotion_holy_souls` | (c) Monday · the Holy Souls; Occasions 'For Those Who Have Died'; Year board All Souls (Nov 2) | The Day of the Dead (Le Jour des morts) | William-Adolphe Bouguereau (1825–1905) | 1859 | Musée des Beaux-Arts de Bordeaux | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `devotion_guardian_angels` | (d) Tuesday · the Holy Angels: Chant Main board, weekday devotions strip | The Guardian Angel | Pietro da Cortona (1596–1669) | 1656 | Galleria Nazionale d'Arte Antica (Palazzo Barberini), Rome | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `devotion_st_joseph` | (e) Wednesday · St Joseph: Chant Main board, weekday devotions strip | Saint Joseph and the Christ Child | Guido Reni (1575–1642) | c. 1640 | Museum of Fine Arts, Houston | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `feast_our_lady_of_the_rosary` | (f) October / Our Lady of the Rosary (Oct 7): Chant Main 'Month of the Holy Rosary' card, Year 'Feast days ahead', Occasions 'A Sung Rosary' | Madonna of the Rosary | Caravaggio (1571–1610) | 1607 | Kunsthistorisches Museum, Vienna | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `feast_christ_the_king` | (g) Christ the King (last Sunday of October): Chant Year 'Feast days ahead' (Christus Vincit) | Christ Triumphant over Sin and Death | Peter Paul Rubens (1577–1640) | c. 1615–22 | Rubens workshop picture; several versions (e.g. Rubenshuis, Antwerp) — pick the version Commons tags PD-Art | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `feast_all_saints` | (g) All Saints (Nov 1): Chant Year 'Feast days ahead' (Litaniæ Sanctorum) | Adoration of the Trinity (The Landauer Altarpiece) | Albrecht Dürer (1471–1528) | 1511 | Kunsthistorisches Museum, Vienna | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `hour_morning` | (h) Prayer Book 'Pray Now' hero for Morning Prayers (On rising) | The Song of the Lark | Jules Breton (1827–1906) | 1884 | Art Institute of Chicago | CC0 1.0 (Art Institute of Chicago open access) | candidate |
| `hour_night` | (h) Prayer Book 'Pray Now' hero for Night Prayers (Before sleep); Chapel's Prayer Book tile at night | The Penitent Magdalen | Georges de La Tour (1593–1652) | c. 1640 | The Metropolitan Museum of Art | CC0 1.0 (The Met Open Access) | candidate |
| `occasion_before_bed` | (i) Chant Occasions 'Before Bed' (Compline chants) | Reuse hour_night (no separate file proposed) | — | — | — | — | candidate |
| `occasion_before_work` | (i) Chant Occasions 'Before Work or Study' (Veni Creator, Veni Sancte reple) | The Apotheosis of Saint Thomas Aquinas | Francisco de Zurbarán (1598–1664) | 1631 | Museo de Bellas Artes de Sevilla | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `occasion_visit_blessed_sacrament` | (i) Chant Occasions 'Visiting the Blessed Sacrament'; Prayer Book 'A Visit to the Blessed Sacrament' | Disputation of the Holy Sacrament (Disputa) | Raphael (1483–1520) | 1509–10 | Stanza della Segnatura, Vatican | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `occasion_confession` | (i) Prayer Book occasions 'Before / After Confession' | Confession (from The Seven Sacraments) | Giuseppe Maria Crespi (1665–1747) | c. 1712 | Gemäldegalerie Alte Meister, Dresden | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |
| `occasion_mass` | (i) Prayer Book occasions 'At Mass' (Before Mass, After Communion); Chant Mass Ordinary if added | The Mass at Bolsena | Raphael (1483–1520) | 1512 | Stanza di Eliodoro, Vatican | Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago) | candidate |

Alternates and reasons:

- `season_advent`: Rorate cæli desuper — the heavens dropping down the Just One; Advent's Marian expectation, in the bundle's Spanish Baroque register (cf. the Velázquez Coronation). *Alternate:* Philippe de Champaigne, The Annunciation (c. 1644) (The Met, CC0 if open access) — if a scene rather than an icon is wanted.
- `devotion_holy_trinity`: The Throne of Grace (the Father holding the dead Son, the Dove above) — tenebrist palette that sits beside the Caravaggio Entombment and Velázquez Crucifixion. *Alternate:* Guido Reni, The Holy Trinity (1625–26), Santissima Trinità dei Pellegrini, Rome.
- `devotion_holy_souls`: Two women in mourning at a grave on All Souls' Day; by the painter of the bundle's Pietà and Flagellation, so the two read as one hand. *Alternate:* Ludovico Carracci, An Angel Frees the Souls of Purgatory (c. 1610), Pinacoteca Vaticana.
- `devotion_guardian_angels`: The guardian angel leading a child by the hand, pointing to heaven: Tuesday's devotion exactly, Roman Baroque. *Alternate:* Domenico Fetti, The Guardian Angel (c. 1615), Musée du Louvre.
- `devotion_st_joseph`: Half-length Joseph holding the Child: an icon of the saint that crops well to a tile. *Alternate:* Bartolomé Esteban Murillo, Saint Joseph with the Infant Jesus (c. 1665–66), Museo de Bellas Artes de Sevilla.
- `feast_our_lady_of_the_rosary`: St Dominic giving out rosaries at Our Lady's command — the feast's own subject, by the painter of the bundle's Entombment. *Alternate:* Bartolomé Esteban Murillo, The Virgin of the Rosary (c. 1650–55), Museo del Prado.
- `feast_christ_the_king`: The risen Christ enthroned over death, Flemish Baroque beside the bundle's Rubens Descent and Van Dyck Crowning. *Alternate:* Hans Memling, Christ Surrounded by Musician Angels (c. 1480s), KMSKA Antwerp — earlier style, but the kingship is explicit.
- `feast_all_saints`: The communion of saints, every state of the Church adoring the Trinity: All Saints in one picture; also a second choice for the Trinity slot. *Alternate:* Fra Angelico, The Forerunners of Christ with Saints and Martyrs (c. 1423–24), National Gallery, London.
- `hour_morning`: A field-worker stopping at sunrise — the day offered at its start; 19th-c. academic like the Hofmann and Bouguereau already bundled. AIC publishes it CC0. *Alternate:* Jean-François Millet, The Angelus (1857–59), Musée d'Orsay — but that is the evening Angelus.
- `hour_night`: Prayer by a single candle at night — the examination of conscience before sleep. The Met's open-access image is CC0. *Alternate:* Georges de La Tour, The Magdalen with the Smoking Flame (c. 1640), LACMA.
- `occasion_before_bed`: Same subject as Night Prayers; an alias saves ~500 KB. If a distinct picture is wanted: Gerrit van Honthorst / Jan Lievens candlelight devotional scenes.
- `occasion_before_work`: The patron of students under the Dove — study begun by asking the Holy Ghost; Spanish Golden Age. *Alternate:* Georges de La Tour, Saint Joseph the Carpenter (c. 1642), Musée du Louvre — work rather than study.
- `occasion_visit_blessed_sacrament`: The Host in the monstrance on the altar, heaven open above it; the bundle already holds Raphael's Transfiguration. Wide — crop to the altar. *Alternate:* Reuse luminous_eucharist (already Benediction's picture in the Occasions board).
- `occasion_confession`: A penitent at the grille of the confessional — the sacrament itself, in warm Bolognese chiaroscuro. *Alternate:* Pietro Longhi, The Confession (c. 1750), Gallerie dell'Accademia / Uffizi.
- `occasion_mass`: A priest at the altar at the elevation; Raphael again, and a crop of the altar reads at tile size. *Alternate:* Giuseppe Maria Crespi, Communion (from The Seven Sacraments), Dresden.

Target format: 1600 px on the long edge, progressive JPEG, 300–800 KB; one 1x image per imageset like the existing ones.

## Existing paintings: provenance

Identified by eye from the bundled images. `high` = recognisable work; `medium` = likely; `low` = subject only. All are pre-1910 old masters, so PD-Art is expected; confirm each with `fetch.py --provenance`.

| Imageset | Work | Creator | Date | Collection | Confidence |
|---|---|---|---|---|---|
| `glorious_coronation` | The Coronation of the Virgin | Diego Velázquez | 1635–36 | Museo del Prado | high |
| `sorrowful_crucifixion` | Christ Crucified | Diego Velázquez | c. 1632 | Museo del Prado | high |
| `sorrowful_crowning` | The Crowning with Thorns | Anthony van Dyck | 1618–20 | Museo del Prado | high |
| `sorrowful_agony` | Christ in Gethsemane | Heinrich Hofmann (d. 1911) | 1886 | Riverside Church, New York | high |
| `sorrowful_scourging` | The Flagellation of Our Lord Jesus Christ | William-Adolphe Bouguereau (d. 1905) | 1880 | Cathédrale Saint-Louis, La Rochelle | high |
| `seven_sorrows_pieta` | Pietà | William-Adolphe Bouguereau (d. 1905) | 1876 | Private collection | high |
| `seven_sorrows_burial` | The Entombment of Christ | Caravaggio | 1603–04 | Pinacoteca Vaticana | high |
| `luminous_transfiguration` | The Transfiguration | Raphael | 1516–20 | Pinacoteca Vaticana | high |
| `luminous_proclamation` | The Sermon on the Mount | Carl Heinrich Bloch (d. 1890) | 1877 | Museum of National History, Frederiksborg Castle | high |
| `seven_sorrows_meeting` | Christ Falls on the Way to Calvary (Lo Spasimo di Sicilia) | Raphael | c. 1516 | Museo del Prado | high |
| `seven_sorrows_descent` | The Descent from the Cross | Peter Paul Rubens | 1612–14 | Cathedral of Our Lady, Antwerp | medium |
| `seven_sorrows_simeon` | Simeon's Song of Praise | Rembrandt | 1631 | Mauritshuis, The Hague | medium |
| `luminous_eucharist` | The Last Supper | Juan de Juanes | c. 1562 | Museo del Prado | medium |
| `joyful_presentation` | The Presentation in the Temple | Simon Vouet | 1641 | Musée du Louvre | medium |
| `seven_sorrows_flight` | The Flight into Egypt | Bartolomé Esteban Murillo | 1647–50 | Detroit Institute of Arts | medium |
| `luminous_baptism` | The Baptism of Christ | Guido Reni | c. 1623 | Kunsthistorisches Museum, Vienna | medium |
| `joyful_annunciation` | The Annunciation | Paolo de Matteis | 1712 | Saint Louis Art Museum | medium |
| `joyful_finding` | Christ among the Doctors | Paolo Veronese | c. 1558 | Museo del Prado | medium |
| `glorious_resurrection` | The Resurrection (French Baroque; artist unconfirmed) | — | — | — | low |
| `glorious_ascension` | The Ascension (17th-c. Italian/French; artist unconfirmed) | — | — | — | low |
| `glorious_assumption` | The Assumption of the Virgin (18th-c. Italian; artist unconfirmed) | — | — | — | low |
| `glorious_pentecost` | Pentecost (artist unconfirmed) | — | — | — | low |
| `joyful_nativity` | The Adoration of the Shepherds, night scene (artist unconfirmed) | — | — | — | low |
| `joyful_visitation` | The Visitation (artist unconfirmed) | — | — | — | low |
| `luminous_cana` | The Wedding at Cana (artist unconfirmed) | — | — | — | low |
| `sorrowful_carrying` | Christ Carrying the Cross (Flemish Baroque; artist unconfirmed) | — | — | — | low |

## Flagged

- **`carlo_acutis`**: Photograph of Carlo Acutis (head and shoulders, red polo, mountains behind). Creator: Unknown; the widely circulated family photograph (c. 2005–06). Licence: Not established — almost certainly in copyright (a modern photograph; the Acutis family / Associazione Amici di Carlo Acutis control the official images).

  Used in CarloAcutisView (CachedAssetImage("carlo_acutis")). Do not ship without permission. Replacement options, in order: (1) written permission from the Associazione Carlo Acutis (carloacutis.com) for this photograph; (2) a freely licensed photograph on Commons (fetch.py --search 'Carlo Acutis' lists any, with licence; as of the last check most Commons images of him were deleted as non-free, so expect none); (3) no photograph: the page draws the votive candle or a monogram instead. A painted 'old master' image cannot exist for a saint who died in 2006, so the brief's 'same style' replacement is not possible here.

## Chant candidates (Verbum Gloriae)

Licence for all: Verbum Gloriae copyleft (CC BY-SA 4.0 terms without the attribution requirement; ShareAlike) — https://www.verbumgloriae.es/licencia-copyleft/. Sizes are estimates at the bundle's measured rate (59 MB / 4 h ≈ 4.3 KB/s) until generate.py encodes them.

| id | Tier | Page | Est. length | Est. size | Note |
|---|---|---|---|---|---|
| `pange_lingua` | 1 | https://www.verbumgloriae.es/project/pange-lingua/ | 4:30 | 1.1 MB | — |
| `vidi_aquam` | 1 | https://www.verbumgloriae.es/project/vidi-aquam/ | 2:30 | 0.6 MB | — |
| `missa_de_angelis` | 2 | https://www.verbumgloriae.es/project/misa-viii-de-angelis/ | 10:00 | 2.5 MB | One page, likely four recordings (Kyrie, Gloria, Sanctus, Agnus Dei). If so, split into four entries with "page": "project/misa-viii-de-angelis" and an "audio"/"scores" selector each; fetch.py --chants lists the file names. |
| `credo_iii` | 2 | https://www.verbumgloriae.es/project/credo-iii/ | 5:30 | 1.4 MB | — |
| `audi_benigne` | 3 | https://www.verbumgloriae.es/project/audi-benigne-conditor/ | 3:00 | 0.7 MB | — |
| `o_vos_omnes` | 3 | https://www.verbumgloriae.es/cantos/santo-rosario/misterios-dolorosos/ | 1:30 | 0.4 MB | The page holds the whole sung Sorrowful Rosary; the search result names a score 'Partitura «O vos omnes»'. Fill audio/scores from fetch.py --chants. |
| `ad_regias` | extra | https://www.verbumgloriae.es/project/ad-regias-agni-dapes/ | 3:20 | 0.8 MB | An Eastertide hymn while Haec Dies is missing; there is also an 'otro tono' page. |
| `te_matrem` | extra | https://www.verbumgloriae.es/project/te-matrem-laudamus/ | 4:00 | 1.0 MB | — |
| `o_oriens_magnificat` | extra | https://www.verbumgloriae.es/project/o-oriens-et-magnificat/ | 5:30 | 1.4 MB | — |

Estimated growth if all are taken: 9.8 MB of audio (plus scores, ~60 KB each).

## Asked for, not on Verbum Gloriae

| Chant | Tier | Slot | Finding |
|---|---|---|---|
| O Lux Beata Trinitas | 1 | Sunday · Trinity | Not a VG project page. VG's Compline/Breviarium books may carry it as PDF only (no recording). |
| Angele Dei / Custodes hominum | 1 | Tuesday · Holy Angels | None on VG. |
| Te Lucis Ante Terminum | 1 | Before Bed / Night | VG has it only inside the Compline book (https://www.verbumgloriae.es/recursos/completas/), a PDF with no recording found. |
| In Manus Tuas | 1 | Before Bed / Night | Same: in VG's Compline book only. |
| Nunc Dimittis | 1 | Before Bed / Night | Same: in VG's Compline book only. |
| Iam Lucis Orto Sidere | 1 | Morning | None on VG. |
| Requiem Æternam (Introit) | 1 | For the Dead | None on VG (only Dies Iræ and the Litany of Saints). |
| In Paradisum | 1 | For the Dead | None on VG (search returned 'Paradisi portae', a Marian antiphon, instead). |
| Lux Æterna | 1 | For the Dead | None on VG. |
| De Profundis (Ps 129) | 1 | For the Dead | None on VG as a project page. |
| Crux Fidelis / Pange Lingua Gloriosi Proelium | 1 | Passion / Friday | None on VG (Vexilla Regis is held). |
| Christus Factus Est | 1 | Passion / Friday | None on VG. |
| Popule Meus (Improperia) | 1 | Passion / Friday | None on VG. |
| Haec Dies | 1 | Easter | None on VG; Ad Regias Agni Dapes proposed as the Eastertide stand-in. |
| Puer Natus Est Nobis (Introit) | 1 | Christmas | None on VG (Puer Natus in Bethlehem is held). |
| Resonet in Laudibus | 1 | Christmas | None on VG. |
| Placare Christe Servulis | 3 | All Saints | None on VG. |
| O Sanctissima | 3 | Our Lady | None on VG. |
| Subvenite | 3 | For the Dead | None on VG. |
| Libera Me | 3 | For the Dead | None on VG. |
| Benedictus (canticle) | 3 | Morning | None on VG as a project page. |

Fallbacks (to list for the manager, not to stage):

- [Wikimedia Commons, Category:Gregorian chant (audio)](https://commons.wikimedia.org/wiki/Category:Gregorian_chant): Many PD/CC0/CC BY-SA Ogg recordings; mostly choirs or amateurs, so a different voice from VG's cantor. List for the manager; don't stage.
- [Musopen](https://musopen.org/): Public-domain recordings; little plainchant.
- [Internet Archive (78 rpm transfers)](https://archive.org/): US public domain only for recordings published before 1926 (as of 2026); the transfer itself may carry terms; other countries differ. Check each, and prefer Commons.

## Integrating the chants

1. Copy `chant_candidates.json`'s groups and chants into `Tools/Chants/chants.json` (the Chant session owns that file).
2. Fill any `TODO` audio/scores selectors from `python3 fetch.py --chants`.
3. On a Mac: `brew install ffmpeg`, then `cd Tools/Chants && python3 generate.py`. HE-AAC needs afconvert; Linux ffmpeg 6.1 has only the LC `aac` encoder (no libfdk_aac), so it cannot match the bundle.
