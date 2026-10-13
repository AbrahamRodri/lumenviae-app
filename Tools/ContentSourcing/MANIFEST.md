# Content sourcing manifest

**On the Mac, in one sitting** (from the repo root):

```sh
cd Tools/ContentSourcing && pip3 install pillow && python3 fetch.py && python3 merge_chants.py && cd ../Chants && python3 generate.py && cd ../ContentSourcing && python3 build_manifest.py
```

1. `python3 fetch.py`: fetches every unverified painting and chant in manifest.json, reads each licence page, writes the new imagesets, and records what it read in fetched.json. Idempotent; any licence off the allowed list fails loudly and the run exits 1, with nothing failed written to the app. Fix a failed painting with `python3 fetch.py --search <imageset>`, then `python3 fetch.py --take <imageset> "File:…"`.
2. `python3 merge_chants.py`: appends the verified chant candidates to Tools/Chants/chants.json (`--dry-run` first to see them). Unverified ones are left out.
3. `cd ../Chants && python3 generate.py`: needs `brew install ffmpeg` and macOS's afconvert; encodes only the new recordings.
4. `python3 build_manifest.py`: records the real encoded sizes in the manifest.

Generated from `sources.py` by `build_manifest.py`; edit there. Machine-readable: `manifest.json`.

**Status:** `unverified` means named here, but no licence page has been read yet; `verified` means fetch.py read the licence on the source page and it is on the allowed list; `flagged` means the licence cannot be established. This round's session could reach no source host, so everything starts unverified.

## New paintings

| Imageset | Slot | Work | Creator | Date | Collection | Licence | Status |
|---|---|---|---|---|---|---|---|
| `season_advent` | (a) Advent: Chant Year/Learn boards, 'Learn Rorate Cæli before Advent' card; Year board's Advent season | The Immaculate Conception of Los Venerables | Bartolomé Esteban Murillo (1617–1682) | c. 1678 | Museo del Prado, Madrid | Public domain | verified |
| `devotion_holy_trinity` | (b) Sunday · the Holy Trinity: Chant Main board, weekday devotions strip | The Holy Trinity | Jusepe de Ribera (1591–1652) | c. 1635 | Real Monasterio de San Lorenzo de El Escorial (a variant of the Prado's picture) | Public domain | verified |
| `devotion_holy_souls` | (c) Monday · the Holy Souls; Occasions 'For Those Who Have Died'; Year board All Souls (Nov 2) | The Day of the Dead (Le Jour des morts) | William-Adolphe Bouguereau (1825–1905) | 1859 | Musée des Beaux-Arts de Bordeaux | Public domain | verified |
| `devotion_guardian_angels` | (d) Tuesday · the Holy Angels: Chant Main board, weekday devotions strip | The Guardian Angel | Bernardo Strozzi (1581–1644) | — | Museum of Fine Arts, Houston (76.256) | Public domain | verified |
| `devotion_st_joseph` | (e) Wednesday · St Joseph: Chant Main board, weekday devotions strip | Saint Joseph and the Christ Child | Guido Reni (1575–1642) | c. 1640 | Museum of Fine Arts, Houston | Public domain | verified |
| `feast_our_lady_of_the_rosary` | (f) October / Our Lady of the Rosary (Oct 7): Chant Main 'Month of the Holy Rosary' card, Year 'Feast days ahead', Occasions 'A Sung Rosary' | Madonna of the Rosary | Caravaggio (1571–1610) | 1607 | Kunsthistorisches Museum, Vienna | Public domain | verified |
| `feast_christ_the_king` | (g) Christ the King (last Sunday of October): Chant Year 'Feast days ahead' (Christus Vincit) | Christ Triumphant over Sin and Death | Peter Paul Rubens (1577–1640) | c. 1615–22 | Rubens workshop picture, of which there are several versions (Rubenshuis, Antwerp among them) | Public domain | verified |
| `feast_all_saints` | (g) All Saints (Nov 1): Chant Year 'Feast days ahead' (Litaniæ Sanctorum) | Adoration of the Trinity (The Landauer Altarpiece) | Albrecht Dürer (1471–1528) | 1511 | Kunsthistorisches Museum, Vienna | Public domain | verified |
| `hour_morning` | (h) Prayer Book 'Pray Now' hero for Morning Prayers (On rising) | The Song of the Lark | Jules Breton (1827–1906) | 1884 | Art Institute of Chicago | Public domain | verified |
| `hour_night` | (h) Prayer Book 'Pray Now' hero for Night Prayers (Before sleep); Chapel's Prayer Book tile at night | The Penitent Magdalen | Georges de La Tour (1593–1652) | c. 1640 | The Metropolitan Museum of Art | CC0 | verified |
| `occasion_before_bed` | (i) Chant Occasions 'Before Bed' (Compline chants) | Reuse hour_night (no separate file proposed) | — | — | — | — | unverified |
| `seven_sorrows_finding` | The third sorrow, the loss of Jesus in the Temple (it borrowed joyful_finding) | The Finding of the Saviour in the Temple | William Holman Hunt (1827–1910) | 1854–60 | Birmingham Museum and Art Gallery | Public domain | verified |
| `seven_sorrows_calvary` | The fifth sorrow, Mary at the foot of the Cross (it borrowed sorrowful_crucifixion) | Crucifixion Diptych | Rogier van der Weyden (c. 1399–1464) | c. 1460 | Philadelphia Museum of Art | Public domain | verified |
| `topic_first_prayers` | Prayer Book topic: The First Prayers | The Education of the Virgin | Bartolomé Esteban Murillo (1617–1682) | c. 1641 | Museo del Prado, Madrid | Public domain | verified |
| `topic_daily_prayers` | Prayer Book topic: Daily Prayers | The Angelus | Jean-François Millet (1814–1875) | 1857–59 | Musée d'Orsay, Paris | Public domain | verified |
| `topic_short_prayers` | Prayer Book topic: Short Prayers | Saint Francis in Meditation | Francisco de Zurbarán (1598–1664) | 1635–39 | The National Gallery, London | Public domain | verified |
| `topic_confession` | Prayer Book topic: Confession | The Return of the Prodigal Son | Rembrandt van Rijn (1606–1669) | c. 1668 | The Hermitage, Saint Petersburg | Public domain | verified |
| `topic_holy_mass` | Prayer Book topic: Holy Mass and Communion | The Mass at Bolsena | Raphael (1483–1520) | 1512–14 | Stanza di Eliodoro, Vatican | Public domain | verified |
| `topic_blessed_sacrament` | Prayer Book topic: The Blessed Sacrament | The Disputation of the Holy Sacrament | Raphael (1483–1520) | 1509–10 | Stanza della Segnatura, Vatican | Public domain | verified |
| `topic_holy_trinity` | Prayer Book topic: The Holy Trinity and the Holy Spirit | The Holy Trinity | El Greco (1541–1614) | 1577–79 | Museo del Prado, Madrid | Public domain | verified |
| `topic_our_lord` | Prayer Book topic: Our Lord | The Sacred Heart of Jesus | Pompeo Batoni (1708–1787) | 1767 | Church of the Gesù, Rome | CC0 | verified |
| `topic_feasts_seasons` | Prayer Book topic: Feasts and Seasons | Adoration of the Magi | Gentile da Fabriano (c. 1370–1427) | 1423 | Uffizi, Florence | Public domain | verified |
| `topic_for_the_living` | Prayer Book topic: For the Church and the Living | The Delivery of the Keys | Pietro Perugino (c. 1446–1523) | 1481–82 | Sistine Chapel, Vatican | Public domain | verified |
| `topic_sick_dying` | Prayer Book topic: The Sick and the Dying | The Death of Saint Joseph | Carlo Maratta (1625–1713) | c. 1676 | Kunsthistorisches Museum, Vienna | Public domain | verified |
| `topic_needs` | Prayer Book topic: In Time of Need | The Storm on the Sea of Galilee | Rembrandt van Rijn (1606–1669) | 1633 | Isabella Stewart Gardner Museum, Boston | Public domain | verified |
| `topic_thanksgiving` | Prayer Book topic: Thanksgiving | Madonna of the Magnificat | Sandro Botticelli (c. 1445–1510) | c. 1483 | Uffizi, Florence | Public domain | verified |

Alternates and reasons:

- `season_advent`: Rorate cæli desuper — the heavens dropping down the Just One; Advent's Marian expectation, in the bundle's Spanish Baroque register (cf. the Velázquez Coronation). *Alternate:* Philippe de Champaigne, The Annunciation (c. 1644) (The Met, CC0 if open access) — if a scene rather than an icon is wanted.
- `devotion_holy_trinity`: The Throne of Grace (the Father holding the dead Son, the Dove above) — tenebrist palette that sits beside the Caravaggio Entombment and Velázquez Crucifixion. *Alternate:* Guido Reni, The Holy Trinity (1625–26), Santissima Trinità dei Pellegrini, Rome.
- `devotion_holy_souls`: Two women in mourning at a grave on All Souls' Day; by the painter of the bundle's Pietà and Flagellation, so the two read as one hand. *Alternate:* Ludovico Carracci, An Angel Frees the Souls of Purgatory (c. 1610), Pinacoteca Vaticana.
- `devotion_guardian_angels`: The guardian angel standing over a child, arms open to keep her: Tuesday's devotion exactly, Genoese Baroque beside the bundle's Caravaggio and Van Dyck. Undated in the museum's record. *Alternate:* Pietro da Cortona, The Guardian Angel (1656), Galleria Nazionale d'Arte Antica, Rome — the first choice, but Commons holds it only at 694×1100.
- `devotion_st_joseph`: Half-length Joseph holding the Child: an icon of the saint that crops well to a tile. *Alternate:* Bartolomé Esteban Murillo, Saint Joseph with the Infant Jesus (c. 1665–66), Museo de Bellas Artes de Sevilla.
- `feast_our_lady_of_the_rosary`: St Dominic giving out rosaries at Our Lady's command — the feast's own subject, by the painter of the bundle's Entombment. *Alternate:* Bartolomé Esteban Murillo, The Virgin of the Rosary (c. 1650–55), Museo del Prado.
- `feast_christ_the_king`: The risen Christ enthroned over death, Flemish Baroque beside the bundle's Rubens Descent and Van Dyck Crowning. *Alternate:* Hans Memling, Christ Surrounded by Musician Angels (c. 1480s), KMSKA Antwerp — earlier style, but the kingship is explicit.
- `feast_all_saints`: The communion of saints, every state of the Church adoring the Trinity: All Saints in one picture; also a second choice for the Trinity slot. *Alternate:* Fra Angelico, The Forerunners of Christ with Saints and Martyrs (c. 1423–24), National Gallery, London.
- `hour_morning`: A field-worker stopping at sunrise — the day offered at its start; 19th-c. academic like the Hofmann and Bouguereau already bundled. AIC publishes it CC0. *Alternate:* Jean-François Millet, The Angelus (1857–59), Musée d'Orsay — but that is the evening Angelus.
- `hour_night`: Prayer by a single candle at night — the examination of conscience before sleep. The Met's open-access image is CC0. *Alternate:* Georges de La Tour, The Magdalen with the Smoking Flame (c. 1640), LACMA.
- `occasion_before_bed`: Same subject as Night Prayers; an alias saves ~500 KB. If a distinct picture is wanted: Gerrit van Honthorst / Jan Lievens candlelight devotional scenes.
- `seven_sorrows_finding`: Mary's own part in the scene: she has found Him and holds Him, where Veronese's Christ among the Doctors (joyful_finding) shows the boy teaching and no mother.
- `seven_sorrows_calvary`: Mary swooning into St John's arms beside the Cross: the sorrow is hers, where Velázquez's Christ Crucified (sorrowful_crucifixion) shows Him alone. Commons holds the diptych at 1195×1128, below the 1600 target, so it is pinned.
- `topic_first_prayers`: St Anne teaching her daughter at her knee: the prayers learned first, from a mother.
- `topic_daily_prayers`: Two field-workers stopping at the bell: the day kept by its prayers.
- `topic_short_prayers`: A single upturned face and a word of prayer: a breath of prayer said in passing.
- `topic_confession`: The son kneeling and the father's hands on his back: the mercy confession asks for.
- `topic_holy_mass`: A priest at the altar raising the Host: the Mass itself.
- `topic_blessed_sacrament`: The Host in its monstrance on the altar, heaven and earth gathered round it: adoration.
- `topic_holy_trinity`: The Father holding the Son, the Dove above them: the Trinity and the Holy Spirit in one picture.
- `topic_our_lord`: Christ showing His Heart: the devotions to Our Lord the book gathers, the Sacred Heart first among them.
- `topic_feasts_seasons`: The Epiphany, the first feast the book keeps, in gold.
- `topic_for_the_living`: Christ giving St Peter the keys: prayer for the Pope and the Church first among prayers for the living.
- `topic_sick_dying`: St Joseph dying in the arms of Jesus and Mary, the patron of a happy death. *Alternate:* Carl Bloch, Christ Healing the Sick at Bethesda (1883), but Commons holds it only at 600 px.
- `topic_needs`: Lord, save us, we perish: the prayer of anyone in need.
- `topic_thanksgiving`: Mary writing her Magnificat: the Church's song of thanks, beside the Te Deum and the Benedictus.

Target format: 1600 px on the long edge, progressive JPEG, 300–800 KB; one 1x image per imageset like the existing ones.

## Unused candidates

No design draws these slots now; kept in case a later one does. fetch.py does not take them.

- `occasion_before_work`: The Apotheosis of Saint Thomas Aquinas, Francisco de Zurbarán (1598–1664) (1631), Museo de Bellas Artes de Sevilla. The patron of students under the Dove — study begun by asking the Holy Ghost; Spanish Golden Age. *Alternate:* Georges de La Tour, Saint Joseph the Carpenter (c. 1642), Musée du Louvre — work rather than study.
- `occasion_visit_blessed_sacrament`: Disputation of the Holy Sacrament (Disputa), Raphael (1483–1520) (1509–10), Stanza della Segnatura, Vatican. The Host in the monstrance on the altar, heaven open above it; the bundle already holds Raphael's Transfiguration. Wide — crop to the altar. *Alternate:* Reuse luminous_eucharist (already Benediction's picture in the Occasions board).
- `occasion_confession`: Confession (from The Seven Sacraments), Giuseppe Maria Crespi (1665–1747) (c. 1712), Gemäldegalerie Alte Meister, Dresden. A penitent at the grille of the confessional — the sacrament itself, in warm Bolognese chiaroscuro. *Alternate:* Pietro Longhi, The Confession (c. 1750), Gallerie dell'Accademia / Uffizi.
- `occasion_mass`: The Mass at Bolsena, Raphael (1483–1520) (1512), Stanza di Eliodoro, Vatican. A priest at the altar at the elevation; Raphael again, and a crop of the altar reads at tile size. *Alternate:* Giuseppe Maria Crespi, Communion (from The Seven Sacraments), Dresden.

## Existing paintings: provenance

Identified by eye from the bundled images, then each compared with the Commons files of its work (aspect ratio, and the correlation of the two images at 32×32; the uncertain ones by eye). `confirmed` = the comparison found the work. Match `exact` = the bundled image is that file or a resize of it, so its source and licence are known (status `verified`); `same work` = a crop or another scan of the same picture, which PD-Art covers, though the file it came from is not proven.

| Imageset | Work | Creator | Date | Collection | Confidence | Commons file | Licence | Match | Bundled | Note |
|---|---|---|---|---|---|---|---|---|---|---|
| `glorious_coronation` | The Coronation of the Virgin | Diego Velázquez | 1635–36 | Museo del Prado | confirmed | File:Diego Velázquez - Coronation of the Virgin - Prado.jpg | Public domain | exact (1.0) | 1202×1600 | Taken again at 1600 px from this file (fetch.py --retake); it was bundled at 640×852. |
| `sorrowful_crucifixion` | Christ Crucified | Diego Velázquez | c. 1632 | Museo del Prado | confirmed | File:Cristo crucificado.jpg | Public domain | exact (1.0) | 2046×3051 | — |
| `sorrowful_crowning` | The Crowning with Thorns | Anthony van Dyck | 1618–20 | Museo del Prado | confirmed | File:Anthonis van Dyck 004.jpg | Public domain | exact (1.0) | 2362×2705 | — |
| `sorrowful_agony` | Christ in Gethsemane | Heinrich Hofmann (d. 1911) | 1886 | Riverside Church, New York | confirmed | File:Christ in Gethsemane.jpg | Public domain | exact (1.0) | 960×1346 | Bundled at 960×1346; the file is 1141×1600. |
| `sorrowful_scourging` | The Flagellation of Our Lord Jesus Christ | William-Adolphe Bouguereau (d. 1905) | 1880 | Cathédrale Saint-Louis, La Rochelle | confirmed | File:William-Adolphe Bouguereau (1825-1905) - The Flagellation of Our Lord Jesus Christ (1880).jpg | Public domain | exact (1.0) | 1118×1600 | Taken again at 1600 px from this file (fetch.py --retake); it was bundled at 499×714. |
| `seven_sorrows_pieta` | Pietà | William-Adolphe Bouguereau (d. 1905) | 1876 | Private collection | confirmed | File:William-Adolphe Bouguereau (1825-1905) - Pieta (1876).jpg | Public domain | exact (1.0) | 1920×3015 | — |
| `seven_sorrows_burial` | The Entombment of Christ | Caravaggio | 1603–04 | Pinacoteca Vaticana | confirmed | File:The Entombment of Christ-Caravaggio (c.1602-3).jpg | Public domain | exact (1.0) | 1920×2852 | — |
| `luminous_transfiguration` | The Transfiguration | Raphael | 1516–20 | Pinacoteca Vaticana | confirmed | File:Transfiguration Raphael.jpg | Public domain | exact (1.0) | 1067×1608 | — |
| `luminous_proclamation` | The Sermon on the Mount | Carl Heinrich Bloch (d. 1890) | 1877 | Museum of National History, Frederiksborg Castle | confirmed | File:Bloch-SermonOnTheMount.jpg | Public domain | exact (1.0) | 1377×1545 | — |
| `seven_sorrows_meeting` | Christ Falls on the Way to Calvary (Lo Spasimo di Sicilia) | Raphael | c. 1516 | Museo del Prado | confirmed | File:Christ Falling on the Way to Calvary - Raphael.jpg | Public domain | exact (1.0) | 1920×2663 | — |
| `seven_sorrows_descent` | The Descent from the Cross | Peter Paul Rubens | 1612–14 | Cathedral of Our Lady, Antwerp | confirmed | File:Peter Paul Rubens - Descent from the Cross - WGA20212 (cropped).jpg | Public domain | same work (0.94) | 1689×2248 | A crop of the Antwerp triptych's central panel, which this file cuts from the Web Gallery of Art's whole triptych. |
| `seven_sorrows_simeon` | Simeon's Song of Praise | Rembrandt | 1631 | Mauritshuis, The Hague | confirmed | File:Simeon in the temple, by Rembrandt van Rijn.jpg | Public domain | exact (0.999) | 1920×2473 | — |
| `luminous_eucharist` | The Last Supper | Juan de Juanes | c. 1562 | Museo del Prado | confirmed | File:The Last Supper by Vicente Juan Macip.jpg | Public domain | same work (0.967) | 1517×998 | A crop of this scan or of another of the same picture. |
| `joyful_presentation` | The Presentation in the Temple | Simon Vouet | 1641 | Musée du Louvre | confirmed | File:Simon Vouet - Presentation in the Temple - WGA25366.jpg | Public domain | exact (1.0) | 800×1302 | — |
| `seven_sorrows_flight` | The Flight into Egypt | Bartolomé Esteban Murillo | 1647–50 | Musei di Strada Nuova (Palazzo Bianco), Genoa | confirmed | File:Bartolomé Esteban Murillo - The Flight into Egypt - Google Art Project.jpg | Public domain | exact (1.0) | 1920×2465 | The Genoa picture (Musei di Strada Nuova), not Detroit's as first thought. |
| `luminous_baptism` | The Baptism of Christ | Guido Reni | c. 1623 | Kunsthistorisches Museum, Vienna | confirmed | File:Guido Reni - The Baptism of Christ - Google Art Project.jpg | Public domain | exact (1.0) | 1920×2727 | — |
| `joyful_annunciation` | The Annunciation | Paolo de Matteis | 1712 | Saint Louis Art Museum | confirmed | File:Paolo de Matteis - The Annunciation - 69-1973 - Saint Louis Art Museum.jpg | Public domain | same work (0.928) | 4351×5077 | The bundled image is larger than any Commons file of the work: another scan, most likely the museum's own. |
| `joyful_finding` | Christ among the Doctors | Paolo Veronese | c. 1558 | Museo del Prado | confirmed | File:Disputa con los doctores (El Veronés) grande.jpg | Public domain | exact (0.996) | 3051×1667 | — |
| `joyful_visitation` | The Visitation | Raphael and workshop (Giulio Romano) | c. 1517 | Museo del Prado | confirmed | File:Visitación de Rafael.jpg | Public domain | exact (1.0) | 1157×1600 | fetch.py --provenance's search finds only 'Raphael - The visitation.jpg' (520×719), a weak match; the bundled file is this one, the same size to the pixel, found by comparing the images. |
| `luminous_cana` | The Marriage Feast at Cana | Bartolomé Esteban Murillo | c. 1672 | Barber Institute of Fine Arts, Birmingham | confirmed | File:The Barber Institute of Fine Arts - Bartolomé Esteban Murillo - The Marriage Feast at CanaFXD.jpg | Public domain | same work (0.965) | 1920×1407 | A crop of this scan. |
| `sorrowful_carrying` | Christ Carrying the Cross | Anthony van Dyck | 1617–18 | Sint-Pauluskerk, Antwerp | confirmed | File:Anthony van Dyck - Jesus Christ bearing the Cross.jpg | Public domain | exact (1.0) | 1218×1600 | Sint-Pauluskerk's own photograph. Taken again at 1600 px from this file (fetch.py --retake); it was bundled at 960×1261. |
| `glorious_resurrection` | The Resurrection of Christ | Noël Coypel | 1700 | unconfirmed (French royal commission) | confirmed | File:Noël Coypel - Resurrection of Christ (large version).jpg | Public domain | same work (0.782) | 566×732 | Commons holds the work only small (638×900 at most); the bundled image is a crop of it, the same composition by eye, and the smallest painting in the bundle. |
| `glorious_pentecost` | Pentecost | — | — | — | ask Abraham | — | — | — | — | — |
| `glorious_ascension` | The Ascension | Francisco Camilo (1615–1673) | 1651 | Museo del Prado, Madrid (Google Art Project scan) | confirmed | File:Francisco Camilo - Ascension - Google Art Project.jpg | Public domain | same work (None) | 672×1024 | The same picture by eye, figure for figure (the signature at the lower left reads F. CAMILO); the Commons file is the Google Art Project scan at 3474×5293. |
| `glorious_assumption` | The Assumption of the Virgin | Corrado Giaquinto (1703–1766) | — | Private collection (Sotheby's, New York, 2013, lot 76) | confirmed | File:CORRADO GIAQUINTO MOLFETTA 1703 - 1766 NAPLES ASSUMPTION OF THE VIRGIN.jpg | Public domain | same work (None) | 800×1245 | The same picture by eye: the Virgin's raised arm, the two angels on the cloud, the apostle with the staff at the tomb. Commons' file is the auction-house photograph (1286×2000). |
| `joyful_nativity` | The Adoration of the Shepherds | Guido Reni (1575–1642) | c. 1640 | National Gallery, London | confirmed | File:The Adoration of the Shepherds by Guido Reni.jpg | Public domain | same work (None) | 711×1080 | The National Gallery's picture, the same to the angels' scroll; Commons holds it at 3953×6000. |

**For Abraham:** where did these come from? `glorious_pentecost`. The subject and school are clear but not the painter, so their licence can't be confirmed yet.

## Texts

Every text the app bundles or fetches that is not its own writing, with the edition it is taken from (`sources.py`, `TEXTS`; build_credits.py renders the same list into the app's Sources & Credits page).

| Work | Maker and edition | Where in the app | Source | Licence |
|---|---|---|---|---|
| The Holy Bible | Douay-Rheims translation, Bishop Challoner's revision (1749–52) | The Scriptural Rosary's verses, the consecration's readings, the Gospel meditation sets and the daily quotations | Project Gutenberg #8300 and the Original Douay-Rheims API (thedouayrheims.com) | Public domain |
| True Devotion to the Blessed Virgin Mary | St. Louis de Montfort, translated by Frederick William Faber (1862; twelfth London edition, 1904) | Bundled whole, and read in the consecration | Resources/TrueDevotionBook.json, from the 1904 printing | Public domain |
| The Imitation of Christ | Thomas à Kempis, translated by William Benham | On the Spiritual Reading shelf, in the consecration's readings and the daily quotations | Project Gutenberg #1653 | Public domain |
| The Story of a Soul | St. Thérèse of Lisieux, translated by Thomas N. Taylor (1912) | On the Spiritual Reading shelf | Project Gutenberg #16772; read by Susan Morin for LibriVox (8021) | Public domain |
| The Confessions | St. Augustine, translated by E. B. Pusey | On the Spiritual Reading shelf | Project Gutenberg #3296; read for LibriVox (2601) | Public domain |
| The Dolorous Passion of Our Lord Jesus Christ | Anne Catherine Emmerich, Burns & Lambert's English (1862) | Cut into the bundled Sorrowful meditations | Project Gutenberg #10866 | Public domain |
| The Glories of Mary | St. Alphonsus Liguori, the Dunigan translation (New York, 1852) | On the Spiritual Reading shelf, cut into the bundled Seven Sorrows meditations, and in the daily quotations | Project Gutenberg #72411; read by Ann Boulais for LibriVox (8533) from the 1888 Kenedy printing of the same translation | Public domain |
| The Practice of the Presence of God | Brother Lawrence of the Resurrection, the Fleming H. Revell edition (1895) | On the Spiritual Reading shelf | Project Gutenberg #13871; read by Kirsten Ferreri for LibriVox (564) | Public domain |
| Maxims and Counsels of St. Francis de Sales for Every Day of the Year | translated by Ella McMahon (1884) | In the daily quotations | Project Gutenberg #73661 | Public domain |
| Meditations and Devotions | John Henry Newman (Longmans, 1893) | In the daily quotations | Internet Archive (a2514634smrn00newmuoft) | Public domain |
| The Divine Comedy | Dante, translated by Henry Wadsworth Longfellow (1867) | In the daily quotations | Paradiso XXXIII | Public domain |
| The Roman Missal of 1962 | the Missale Meum project | Today's Mass, fetched when opened | missalemeum.com, MIT licence | MIT |
| The Roman Breviary of 1962 | The Divinum Officium Project | The Hours of Prayer, fetched when opened | divinumofficium.com, by way of Lumen Viae's own server | Free to use, with the project's credit |
| Gregorian chant: recordings and scores | Verbum Gloriae (verbumgloriae.es) | The Chant Library's 104 recordings and their scores | verbumgloriae.es, copyleft licence | Copyleft (share alike, no attribution required) |
| Prayers of the Church | the 1910 Raccolta, the Roman Ritual and Missal, and the app's own literal renderings from the Latin | The Prayer Book | Public-domain editions, named in each file of Data/PrayerBook | Public domain |
| Cinzel and EB Garamond | Natanael Gama; Georg Duffner and Octavio Pardo | The app's type | Google Fonts | SIL Open Font License 1.1 |
| Phosphor Icons and Christicons | Phosphor (Helena Zhang and Tobias Fried); Christicons | The app's glyphs, beside those drawn for it | phosphoricons.com (MIT); christicons.com (free for commercial use) | MIT; free for commercial use |

## Flagged

- **`carlo_acutis`**: Photograph of Carlo Acutis (head and shoulders, red polo, mountains behind). Creator: Unknown; the widely circulated family photograph (c. 2005–06). Licence: Not established — almost certainly in copyright (a modern photograph; the Acutis family / Associazione Amici di Carlo Acutis control the official images).

  Used in CarloAcutisView (CachedAssetImage("carlo_acutis")). Do not ship without permission. Replacement options, in order: (1) written permission from the Associazione Carlo Acutis (carloacutis.com) for this photograph; (2) a freely licensed photograph on Commons (fetch.py --search 'Carlo Acutis' lists any, with licence; as of the last check most Commons images of him were deleted as non-free, so expect none); (3) no photograph: the page draws the votive candle or a monogram instead. A painted 'old master' image cannot exist for a saint who died in 2006, so the brief's 'same style' replacement is not possible here.

## Chant candidates (Verbum Gloriae)

Licence for all: Verbum Gloriae copyleft (CC BY-SA 4.0 terms without the attribution requirement; ShareAlike) — https://www.verbumgloriae.es/licencia-copyleft/. Sizes are estimates at the bundle's measured rate (59 MB / 4 h ≈ 4.3 KB/s) until generate.py encodes them.

| id | Tier | Status | Page | Est. length | Size | Note |
|---|---|---|---|---|---|---|
| `pange_lingua` | 1 | verified | https://www.verbumgloriae.es/project/pange-lingua/ | 4:30 | 1.08 MB | — |
| `vidi_aquam` | 1 | verified | https://www.verbumgloriae.es/project/vidi-aquam/ | 2:30 | 0.81 MB | — |
| `kyrie_de_angelis` | 2 | verified | https://www.verbumgloriae.es/project/misa-viii-de-angelis/ | 1:30 | 0.59 MB | One of four parts on the Misa VIII page; fetch.py picks its files by the name pattern 'kyrie'. |
| `gloria_de_angelis` | 2 | verified | https://www.verbumgloriae.es/project/misa-viii-de-angelis/ | 3:00 | 0.64 MB | One of four parts on the Misa VIII page; fetch.py picks its files by the name pattern 'gloria'. |
| `sanctus_de_angelis` | 2 | verified | https://www.verbumgloriae.es/project/misa-viii-de-angelis/ | 1:00 | 0.36 MB | One of four parts on the Misa VIII page; fetch.py picks its files by the name pattern 'sanctus'. |
| `agnus_de_angelis` | 2 | verified | https://www.verbumgloriae.es/project/misa-viii-de-angelis/ | 1:00 | 0.30 MB | One of four parts on the Misa VIII page; fetch.py picks its files by the name pattern 'agnus'. |
| `credo_iii` | 2 | verified | https://www.verbumgloriae.es/project/credo-iii/ | 5:30 | 1.06 MB | — |
| `audi_benigne` | 3 | verified | https://www.verbumgloriae.es/project/audi-benigne-conditor/ | 3:00 | 0.53 MB | — |
| `o_vos_omnes` | 3 | verified | https://www.verbumgloriae.es/cantos/santo-rosario/misterios-dolorosos/ | 1:30 | 0.43 MB | The page holds the whole sung Sorrowful Rosary; fetch.py picks this antiphon's files by the pattern 'vos-omnes'. |
| `ad_regias` | extra | verified | https://www.verbumgloriae.es/project/ad-regias-agni-dapes/ | 3:20 | 0.86 MB | An Eastertide hymn while Haec Dies is missing; there is also an 'otro tono' page. |
| `te_matrem` | extra | verified | https://www.verbumgloriae.es/project/te-matrem-laudamus/ | 4:00 | 1.38 MB | — |
| `o_oriens_magnificat` | extra | verified | https://www.verbumgloriae.es/project/o-oriens-et-magnificat/ | 5:30 | 0.92 MB | — |

Growth if all are taken: 9.0 MB of audio, on top of the bundle's ~59 MB (plus scores, ~60 KB each).

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

## Other voices: for Abraham's review

Not staged: this round takes Verbum Gloriae's single cantor only. Once Commons is readable, the recordings found for the missing chants (the Trinity, the Angels, Compline, Requiem, Passion, Christmas, Haec Dies) are listed here with link, performer and licence, for Abraham to decide. Not yet searched: Commons was unreachable.


## Why the chants need the Mac

The bundle's recordings are mono HE-AAC, encoded by macOS's afconvert. Linux ffmpeg 6.1 has only the LC `aac` encoder (no libfdk_aac), so generate.py cannot match the bundle there. Tools/Chants/ belongs to the Chant session: merge_chants.py only appends verified entries to chants.json, in its own layout.
