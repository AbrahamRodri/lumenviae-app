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
| `topic_confession` | Prayer Book topic: Confession; the After Confession order | The Return of the Prodigal Son | Rembrandt van Rijn (1606–1669) | c. 1668 | The Hermitage, Saint Petersburg | Public domain | verified |
| `topic_holy_mass` | Prayer Book topic: Holy Mass and Communion | The Mass at Bolsena | Raphael (1483–1520) | 1512–14 | Stanza di Eliodoro, Vatican | Public domain | verified |
| `topic_blessed_sacrament` | Prayer Book topic: The Blessed Sacrament | The Disputation of the Holy Sacrament | Raphael (1483–1520) | 1509–10 | Stanza della Segnatura, Vatican | Public domain | verified |
| `topic_holy_trinity` | Prayer Book topic: The Holy Trinity and the Holy Spirit | The Holy Trinity | El Greco (1541–1614) | 1577–79 | Museo del Prado, Madrid | Public domain | verified |
| `topic_our_lord` | Prayer Book topic: Our Lord | The Sacred Heart of Jesus | Pompeo Batoni (1708–1787) | 1767 | Church of the Gesù, Rome | CC0 | verified |
| `topic_feasts_seasons` | Prayer Book topic: Feasts and Seasons | Adoration of the Magi | Gentile da Fabriano (c. 1370–1427) | 1423 | Uffizi, Florence | Public domain | verified |
| `topic_for_the_living` | Prayer Book topic: For the Church and the Living | The Delivery of the Keys | Pietro Perugino (c. 1446–1523) | 1481–82 | Sistine Chapel, Vatican | Public domain | verified |
| `topic_sick_dying` | Prayer Book topic: The Sick and the Dying | The Death of Saint Joseph | Carlo Maratta (1625–1713) | c. 1676 | Kunsthistorisches Museum, Vienna | Public domain | verified |
| `topic_needs` | Prayer Book topic: In Time of Need | The Storm on the Sea of Galilee | Rembrandt van Rijn (1606–1669) | 1633 | Isabella Stewart Gardner Museum, Boston | Public domain | verified |
| `topic_thanksgiving` | Prayer Book topic: Thanksgiving | Madonna of the Magnificat | Sandro Botticelli (c. 1445–1510) | c. 1483 | Uffizi, Florence | Public domain | verified |
| `mary_immaculate_conception` | The Immaculate Conception: Thou Art All Fair, Inviolate, O Mary Conceived without Sin, Lourdes; the feast on Dec 8; the Marian Library's Immaculate Conception, Lourdes and Guadalupe | The Immaculate Conception | Giovanni Battista Tiepolo (1696–1770) | 1767–69 | Museo del Prado, Madrid | Public domain | verified |
| `mary_mater_dolorosa` | Our Lady of Sorrows: her prayer, litany and closing prayer; the feast on Sept 15; the Marian Library's Seven Sorrows | Mater Dolorosa | Carlo Dolci (1616–1687) | c. 1655 | National Museum of Western Art, Tokyo | Public domain | verified |
| `mary_virgin_in_prayer` | Our Lady at prayer: To the Heart of Mary, My Queen My Mother, the Three Hail Marys, To Our Lady after Communion; Saved; the Marian Library's Immaculate Heart | The Virgin in Prayer | Giovanni Battista Salvi da Sassoferrato (1609–1685) | 1640–50 | The National Gallery, London | Public domain | verified |
| `mary_sistine_madonna` | Our Lady in glory: the Chant Library's hymns to Our Lady (Daily Daily Sing to Mary, O Glorious Virgin, We Praise Thee as Mother, the Saturday Ave Maris Stella), Saturday's devotion, Songs to Mary; the Marian Library's Holy Name of Mary | The Sistine Madonna | Raphael (1483–1520) | 1512–13 | Gemäldegalerie Alte Meister, Dresden | Public domain | verified |
| `mary_mother_of_mercy` | Under her mantle: We Fly to Thy Patronage, Hail Mother of Mercy, Mary Help of Christians, Perpetual Help; the Before Bed occasion | Madonna della Misericordia (Polyptych of the Misericordia) | Piero della Francesca (c. 1415–1492) | 1445–62 | Museo Civico, Sansepolcro | Public domain | verified |
| `mary_mount_carmel` | Our Lady of Mount Carmel: Flower of Carmel, her prayer, the feast on July 16, the Marian Library | Madonna del Carmine Giving the Scapular to St Simon Stock | Painter in the manner of Arcangelo Salimbeni | 1535 | Pieve della Santissima Annunziata, Montisi | Public domain | verified |
| `mary_of_the_snows` | The Marian Library's Our Lady of the Snows (Aug 5) | The Dream of the Patrician | Bartolomé Esteban Murillo (1617–1682) | 1664–65 | Museo del Prado, Madrid | Public domain | verified |
| `feast_annunciation` | The Annunciation feast (Mar 25), the Ave Maria antiphon, Whom Earth and Sea and Stars, the feast-day Ave Maris Stella; the Marian Library's Annunciation | The Annunciation | Fra Angelico (c. 1395–1455) | 1425–26 | Museo del Prado, Madrid | Public domain | verified |
| `jesus_holy_name` | The Holy Name: its litany (prayer and chant), Jesus the Very Thought of Thee, the Jesus Prayer, the Golden Arrow; the feast and the month of January | The Adoration of the Name of Jesus | El Greco (1541–1614) | 1578–80 | The National Gallery, London | Public domain | verified |
| `jesus_precious_blood` | The Precious Blood: its litany and offering, Hail Wounds of Christ, the feast on July 1 and its month | The Blood of the Redeemer | Giovanni Bellini (c. 1430–1516) | c. 1465 | The National Gallery, London | Public domain | verified |
| `jesus_anima_christi` | Soul of Christ (prayer and chant) | Christ Embracing St Bernard | Francisco Ribalta (1565–1628) | 1625–27 | Museo del Prado, Madrid | Public domain | verified |
| `jesus_eucharist_saviour` | Jesus in the Host: Hail True Body, I Adore Thee Devoutly, Bread of Angels, Behold the Bread of Angels, O Sacred Banquet, Lord I Am Not Worthy, Spiritual Communion; A Visit to Jesus in Church | The Saviour | Juan de Juanes (c. 1507–1579) | c. 1545–50 | Museo del Prado, Madrid | Public domain | verified |
| `jesus_good_shepherd` | Prayer to the Infant Jesus of Prague | The Good Shepherd | Bartolomé Esteban Murillo (1617–1682) | c. 1660 | Museo del Prado, Madrid | Public domain | verified |
| `season_lent` | Lent: the season, Hear Us O Lord, O Kind Creator, Spare O Lord, In the Midst of Life | Christ in the Wilderness | Moretto da Brescia (c. 1498–1554) | c. 1515–20 | The Metropolitan Museum of Art, New York | CC0 | verified |
| `psalm_king_david` | The psalms: Have Mercy on Me (Miserere), Blessed Are They (Psalm 31), Thou Shalt Sprinkle Me (Asperges, from Psalm 50); the Chant Library's psalm kind and Learned | King David Playing the Harp | Gerard van Honthorst (1592–1656) | 1622 | Centraal Museum, Utrecht | Public domain | verified |
| `easter_noli_me_tangere` | Easter Sunday and its sequence, Praises to the Paschal Victim | Noli Me Tangere | Correggio (1489–1534) | c. 1525 | Museo del Prado, Madrid | Public domain | verified |
| `easter_saint_thomas` | O Sons and Daughters; My Lord and My God | The Incredulity of Saint Thomas | Caravaggio (1571–1610) | 1601–02 | Sanssouci Picture Gallery, Potsdam | Public domain | verified |
| `easter_holy_women` | The Dawn Is Reddening the Sky; Hail Festive Day | The Holy Women at the Tomb | William-Adolphe Bouguereau (1825–1905) | 1890 | Royal Museum of Fine Arts, Antwerp | Public domain | verified |
| `easter_appears_to_mary` | Queen of Heaven, Rejoice (the prayer, both chants, the Angelus in Eastertide); With Joy in One Accord | Christ Appearing to His Mother | Juan de Flandes (c. 1465–1519) | c. 1496 | The Metropolitan Museum of Art, New York | CC0 | verified |
| `mass_lamb_of_god` | Lamb of God (both Masses); At the Lamb's High Feast | The Adoration of the Mystic Lamb (Ghent Altarpiece, central panel) | Hubert and Jan van Eyck (d. 1426 and 1441) | 1432 | St Bavo's Cathedral, Ghent | Public domain | verified |
| `advent_isaiah` | Advent's prophecies: Drop Down Dew (Rorate), O Come O Come Emmanuel, the seven O antiphons and their days, Creator of the Stars of Night, Hark a Clear Voice; the seasonal section | The Prophet Isaiah (Sistine Chapel ceiling) | Michelangelo (1475–1564) | 1508–12 | Sistine Chapel, Vatican | Public domain | verified |
| `christmas_shepherds` | O Come All Ye Faithful; Christmas Day | The Adoration of the Shepherds | Gerard van Honthorst (1592–1656) | 1622 | Wallraf-Richartz-Museum, Cologne | Public domain | verified |
| `saint_john_baptist_birth` | The Birth of St John the Baptist (June 24) and its hymn, That Thy Servants May Sing; the Canticle of Zachary | The Birth of St John the Baptist | Artemisia Gentileschi (1593–1654) | c. 1635 | Museo del Prado, Madrid | Public domain | verified |
| `saint_michael` | St Michael: his prayer, his chant, his feast (Sept 29) | Saint Michael Vanquishing Satan (Le Grand Saint Michel) | Raphael (1483–1520) | 1518 | Musée du Louvre, Paris | Public domain | verified |
| `saint_joseph_carpenter` | To St Joseph, Model of Workers; Before Work; the Before Work or Study occasion | Saint Joseph the Carpenter | Georges de La Tour (1593–1652) | c. 1642 | Musée du Louvre, Paris | Public domain | verified |
| `saint_anthony` | Prayer to St Anthony | Saint Anthony of Padua | Francisco de Zurbarán (1598–1664) | 1627–30 | Museu de Arte de São Paulo | Public domain | verified |
| `saint_thomas_aquinas` | St Thomas Aquinas's prayers before study, before Mass and after Mass | Saint Thomas Aquinas (from the Demidoff Altarpiece) | Carlo Crivelli (c. 1430–1495) | 1476 | The National Gallery, London | Public domain | verified |
| `saint_paul_conversion` | For the Conversion of Sinners | The Conversion on the Way to Damascus | Caravaggio (1571–1610) | 1600–01 | Santa Maria del Popolo, Rome | Public domain | verified |
| `last_judgment` | Day of Wrath (Dies Irae) | The Last Judgement | Fra Angelico (c. 1395–1455) | 1435–40 | Gemäldegalerie, Berlin | Public domain | verified |
| `prayer_holy_family` | For the Family, A Parent's Prayer, Jesus Mary and Joseph (both), Visit This House | The Holy Family with a Little Bird | Bartolomé Esteban Murillo (1617–1682) | c. 1650 | Museo del Prado, Madrid | Public domain | verified |
| `prayer_tobias_angel` | Before a Journey | Tobias and the Angel | Workshop of Andrea del Verrocchio | c. 1470–75 | The National Gallery, London | Public domain | verified |
| `prayer_healing_sick` | For the Sick; Prayer to St Peregrine | Christ Healing the Paralytic at the Pool of Bethesda | Bartolomé Esteban Murillo (1617–1682) | 1667–70 | The National Gallery, London | Public domain | verified |
| `prayer_supper_emmaus` | Grace before and after Meals; the At Meals order on Explore | Supper at Emmaus | Caravaggio (1571–1610) | 1601 | The National Gallery, London | Public domain | verified |
| `virtue_faith_isaac` | Prayers: The Act of Faith | The Sacrifice of Isaac | Caravaggio (1571–1610) | c. 1603 | Uffizi, Florence | Public domain | verified |
| `virtue_hope_dove` | Prayers: The Act of Hope | The Return of the Dove to the Ark | John Everett Millais (1829–1896) | 1851 | Ashmolean Museum, Oxford | Public domain | verified |
| `virtue_charity_samaritan` | Prayers: The Act of Charity | The Good Samaritan | Jacopo Bassano (c. 1510–1592) | c. 1562–63 | The National Gallery, London | Public domain | verified |
| `jesus_light_of_the_world` | Prayers: Act of Consecration to the Sacred Heart | The Light of the World | William Holman Hunt (1827–1910) | 1851–53 | Keble College, Oxford | Public domain | verified |
| `saint_matthew_calling` | Prayers: Some Definite Service (Newman) | The Calling of Saint Matthew | Caravaggio (1571–1610) | 1599–1600 | San Luigi dei Francesi, Rome | Public domain | verified |
| `jesus_washing_feet` | Prayers: Jesus Meek and Humble of Heart; Litany of Humility | Jesus Washing Peter's Feet | Ford Madox Brown (1821–1893) | 1852–56 | Tate Britain, London | Public domain | verified |
| `saint_francis_desert` | Prayers: My God and My All; the Peace Prayer | Saint Francis in the Desert | Giovanni Bellini (c. 1430–1516) | c. 1476–78 | The Frick Collection, New York | Public domain | verified |
| `saint_ambrose` | Prayers: Prayer of St Ambrose before Mass | Saint Ambrose | Giovanni di Paolo (c. 1398–1482) | 1465–70 | The Metropolitan Museum of Art, New York | CC0 | verified |
| `saint_bonaventure` | Prayers: Prayer of St Bonaventure after Mass (Transfige) | The Prayer of Saint Bonaventure about the Selection of the New Pope | Francisco de Zurbarán (1598–1664) | 1628–29 | Gemäldegalerie Alte Meister, Dresden | Public domain | verified |
| `saint_peter_tears` | Prayers: Prayer before Confession; the Before Confession order | Saint Peter in Tears | El Greco (1541–1614) | c. 1587–96 | Bowes Museum (Google Art Project) | Public domain | verified |
| `christ_and_the_adulteress` | Prayers: Making Your Confession | Christ and the Woman Taken in Adultery | Lorenzo Lotto (c. 1480–1556) | 1546–55 | Museo Antico Tesoro della Santa Casa, Loreto | Public domain | verified |
| `saint_jerome_penitent` | Prayers: I Confess (Confiteor) | Saint Jerome | Jusepe de Ribera (1591–1652) | 1640s | Cleveland Museum of Art | Public domain | verified |
| `communion_of_apostles` | Prayers: Act of Spiritual Communion | The Communion of the Apostles | Joos van Wassenhove (c. 1410–c. 1480) | 1473–74 | Galleria Nazionale delle Marche, Urbino | CC0 | verified |
| `last_supper_juanes` | Prayers: O Sacred Banquet | The Last Supper | Juan de Juanes (c. 1507–1579) | c. 1562 | Museo del Prado, Madrid | Public domain | verified |
| `pentecost_maino` | Prayers: Come, Creator Spirit; The Secret of Sanctity | Pentecost | Juan Bautista Maíno (1581–1649) | 1620–25 | Museo del Prado, Madrid | Public domain | verified |
| `jesus_healing_blind` | Prayers: The Jesus Prayer; My Jesus, Mercy | Christ Healing the Blind | El Greco (1541–1614) | c. 1570 | The Metropolitan Museum of Art, New York | CC0 | verified |
| `crucifixion_mond` | Prayers: Offering of the Precious Blood; the Chaplet of Divine Mercy | The Mond Crucifixion | Raphael (1483–1520) | c. 1502–03 | The National Gallery, London | Public domain | verified |
| `children_blessed` | Prayers: A Parent's Prayer for Their Children | Christ Blessing the Children | Lucas Cranach the Elder (1472–1553) | after 1537 | Statens Museum for Kunst, Copenhagen | Public domain | verified |
| `tribute_money` | Prayers: For Our Country | The Tribute Money | Titian (c. 1488–1576) | c. 1560–68 | The National Gallery, London | Public domain | verified |
| `shepherds_annunciation` | Prayers: For Peace (Da Pacem) | The Annunciation to the Shepherds | Jacopo Bassano (c. 1510–1592) | c. 1555–60 | National Gallery of Art, Washington | CC0 | verified |
| `saint_gertrude` | Prayers: St Gertrude's Offering for the Holy Souls | Saint Gertrude | Miguel Cabrera (1695–1768) | 18th century | Dallas Museum of Art | Public domain | verified |
| `saint_teresa_purgatory` | Prayers: Let Nothing Disturb Thee; For All the Faithful Departed | Saint Teresa of Ávila Interceding for Souls in Purgatory | Peter Paul Rubens (1577–1640) | c. 1630 | The Metropolitan Museum of Art, New York | CC0 | verified |
| `saint_ignatius` | Prayers: Take, O Lord, and Receive; Prayer for Generosity | Saint Ignatius of Loyola | Peter Paul Rubens (1577–1640) | 1610–12 | Norton Simon Museum, Pasadena | Public domain | verified |
| `apostles_calling_duccio` | Prayers: Prayer of St Richard of Chichester | The Calling of the Apostles Peter and Andrew | Duccio di Buoninsegna (c. 1255–1319) | 1308–11 | National Gallery of Art, Washington | CC0 | verified |
| `saint_jude` | Prayers: Prayer to St Jude | Saint Jude Thaddeus | El Greco (1541–1614) | c. 1610–14 | Museo del Greco, Toledo (Google Art Project) | Public domain | verified |
| `saint_benedict` | Prayers: The Verses of the St Benedict Medal | Saint Benedict Blessing the Bread | Juan Rizi (1600–1681) | c. 1655 | Museo del Prado, Madrid | Public domain | verified |
| `order_raising_of_lazarus` | Prayers: the For Those Who Have Died order | The Raising of Lazarus | Sebastiano del Piombo (c. 1485–1547) | 1517–19 | The National Gallery, London | Public domain | verified |

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
- `mary_immaculate_conception`: Our Lady standing on the moon and the serpent, the Dove above: the Tota pulchra's subject, and the name she gave herself at Lourdes. A second Immaculata, so the Our Lady topic's Murillo is not hung on every Marian prayer.
- `mary_mater_dolorosa`: Our Lady alone in her grief, hands clasped, in the blue the app's Marian pages wear. The oval's painted ground is cut away. *Alternate:* Titian, Mater Dolorosa with her Hands Apart (1554), Museo del Prado.
- `mary_virgin_in_prayer`: Mary herself praying, eyes lowered: the prayers that give oneself to her heart, and the shelf of prayers a reader keeps.
- `mary_sistine_madonna`: Our Lady coming down through the clouds with her Son: the hymns sung to her in heaven, where the Coronation had stood for all of them.
- `mary_mother_of_mercy`: Our Lady sheltering the faithful under her cloak: the Sub tuum's 'we fly to thy patronage', and the night put under her protection. *Alternate:* Domenico Ghirlandaio, Madonna della Misericordia (Ognissanti), on Commons only under CC BY.
- `mary_mount_carmel`: Our Lady giving the scapular to St Simon Stock, the souls in Purgatory below: the feast's own scene. Its arched frame is cut away. *Alternate:* Tiepolo's ceiling at the Scuola dei Carmini, Venice, whose photographs are not plainly public domain.
- `mary_of_the_snows`: Our Lady appearing to the sleeping patrician John to ask for the church that became St Mary Major: the feast's own story. The lunette's gilt corners are cut away.
- `feast_annunciation`: Gabriel's Ave in gold and blue: the feast and the hymns that sing it, kept apart from the Joyful Mysteries' own Annunciation.
- `jesus_holy_name`: Heaven, earth and hell kneeling to the Name, IHS, in the sky: 'that at the name of Jesus every knee should bow'.
- `jesus_precious_blood`: An angel catching the blood from Christ's side in a chalice: the devotion itself.
- `jesus_anima_christi`: Christ leaning down from the Cross to hold the monk: 'within Thy wounds hide me; suffer me not to be separated from Thee'.
- `jesus_eucharist_saviour`: Christ holding up the Host over the chalice, looking out at the one who kneels: Ave verum corpus, and the visit before the tabernacle.
- `jesus_good_shepherd`: The Child Jesus with a lamb: the devotion to the Infant, in a painting rather than the crowned statue.
- `season_lent`: Christ's forty days among the beasts, angels coming to Him: the fast every Lenten hymn keeps. The Met's open-access image is CC0.
- `psalm_king_david`: The psalmist singing, eyes raised: David's Miserere and the chants learned by heart.
- `easter_noli_me_tangere`: 'Tell us, Mary, what thou sawest on the way': the Victimae paschali asks Magdalen, and this is what she saw.
- `easter_saint_thomas`: O filii et filiae tells of Thomas's hand in the wound, and 'My Lord and my God' are his words.
- `easter_holy_women`: The women at the empty tomb at dawn and the angel telling them He is risen: Aurora caelum purpurat's own verses. By the painter of the bundle's Pietà.
- `easter_appears_to_mary`: The risen Christ coming first to His Mother: 'Queen of Heaven, rejoice, for He whom thou didst merit to bear is risen'. The panel's frame is cut away; CC0 from the Met.
- `mass_lamb_of_god`: The Lamb on the altar, its blood flowing into the chalice, the angels and saints adoring: Agnus Dei, and the Lamb's high feast.
- `advent_isaiah`: Rorate caeli and every O antiphon are Isaiah's words; the prophet turning from his book at a call. The painted architecture round him is cut away.
- `christmas_shepherds`: 'Venite adoremus': the shepherds come in from the night to the Child, who is the light of the picture. *Alternate:* Murillo, The Adoration of the Shepherds (c. 1650), Museo del Prado.
- `saint_john_baptist_birth`: The newborn John washed by the women while Zachary writes his name: the feast, the hymn for it, and the Benedictus Zachary then sang.
- `saint_michael`: 'Defend us in battle': the archangel with his lance over the fallen angel. *Alternate:* Guido Reni, St Michael the Archangel (1635), Santa Maria della Concezione, Rome.
- `saint_joseph_carpenter`: Joseph at his beam by the light of the Child's candle: work offered and begun in His presence.
- `saint_anthony`: The saint kneeling as the Child appears above him, his book and lily beside him: the saint the prayer asks, in Zurbarán's quiet dark.
- `saint_thomas_aquinas`: The Angelic Doctor holding the Church and his open book, the sun of wisdom on his breast: the man whose prayers these are. *Alternate:* Zurbarán, The Apotheosis of St Thomas Aquinas (1631), Seville, on Commons only at 2024 px in a scan cut to the faces, or under CC BY-SA.
- `saint_paul_conversion`: Saul thrown down by the light: the conversion the prayer asks for others.
- `last_judgment`: Christ in judgement among the saints, the blessed and the lost on either side: the Dies irae's own vision. *Alternate:* Rogier van der Weyden, the Beaune Altarpiece (1443–51).
- `prayer_holy_family`: Joseph, Mary and the Child at home, at work and at play: the household these prayers are for.
- `prayer_tobias_angel`: Raphael walking beside the young Tobias on his road: the traveller's prayer for an angel's company.
- `prayer_healing_sick`: Christ bending to the sick man who had no one to help him: the prayer for the sick, where the Death of St Joseph heads the topic.
- `prayer_supper_emmaus`: Christ blessing the bread at table, and the two knowing Him: grace at a meal.
- `virtue_faith_isaac`: Abraham, the father of faith, obeying to the last: the act of faith set as Scripture first sets it.
- `virtue_hope_dove`: Noah's daughters holding the dove come back with the olive leaf: hope of what is promised. The arched top is cut away.
- `virtue_charity_samaritan`: Love of neighbour as Christ told it: the Samaritan lifting the wounded man.
- `jesus_light_of_the_world`: Christ knocking at the door of the heart with His lamp: 'Behold, I stand at the gate and knock'; the heart given to Him.
- `saint_matthew_calling`: Christ pointing at the tax collector at his table: each called to a service of his own.
- `jesus_washing_feet`: The Lord kneeling at Peter's feet: 'learn of me, because I am meek and humble of heart'.
- `saint_francis_desert`: Francis stepping out into the light with open arms: 'Deus meus et omnia', the prayer that is his.
- `saint_ambrose`: The bishop of Milan in his mitre with his book: the saint whose prayer it is. CC0 from the Met.
- `saint_bonaventure`: The Seraphic Doctor kneeling in prayer, an angel above him: the saint whose prayer it is.
- `saint_peter_tears`: Peter weeping for his denial, the keys at his belt: sorrow for sin before the sacrament.
- `christ_and_the_adulteress`: 'Neither will I condemn thee. Go, and now sin no more': the words the penitent comes to hear. An autograph replica of the Louvre picture.
- `saint_jerome_penitent`: The penitent saint with the cross and the skull: 'through my fault, through my fault'.
- `communion_of_apostles`: Christ Himself giving the Host to the kneeling apostles: the communion the prayer longs for.
- `last_supper_juanes`: Christ raising the Host at the table: 'O sacred banquet, in which Christ is received'. The gilt frame is cut away.
- `pentecost_maino`: The Dove over Our Lady and the Apostles, the flames on their heads: a second Pentecost so the Holy Spirit's prayers do not stand under one picture.
- `jesus_healing_blind`: 'Jesus, Son of David, have mercy on me': the blind man's cry, which the Jesus Prayer repeats. CC0 from the Met.
- `crucifixion_mond`: Angels catching the blood and water from Christ's wounds in chalices: the offering of the Precious Blood, and the mercy the chaplet asks. The arched top's corners are cut away.
- `children_blessed`: Mothers bringing their children to be blessed: 'Suffer the little children to come unto me'.
- `tribute_money`: 'Render to Caesar the things that are Caesar's, and to God the things that are God's': the prayer for one's country and its rulers.
- `shepherds_annunciation`: The angel over the shepherds at night: 'on earth peace to men of good will'. CC0 from the National Gallery of Art.
- `saint_gertrude`: The saint with the Child in her heart and her book: the woman whose offering it is.
- `saint_teresa_purgatory`: Teresa kneeling before Christ as souls rise from Purgatory: her own 'Nada te turbe', and the prayer for all the faithful departed. CC0 from the Met.
- `saint_ignatius`: The saint in his vestments, eyes raised, hand on the book of the Society: the Suscipe and the prayer for generosity are his.
- `apostles_calling_duccio`: Christ calling the fishermen from their boat: 'to follow Thee more nearly'. CC0 from the National Gallery of Art.
- `saint_jude`: The apostle with his halberd: the saint the prayer asks.
- `saint_benedict`: Benedict blessing the poisoned bread, the miracle the medal's 'drink thou thy own poison' remembers.
- `order_raising_of_lazarus`: "I am the resurrection and the life": the hope the prayers for the dead are said in, apart from the topic's Day of the Dead.

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
| `glorious_resurrection` | The Resurrection of Christ | Noël Coypel | 1700 | — | confirmed | File:Noël Coypel - Resurrection of Christ (large version).jpg | Public domain | same work (0.782) | 566×732 | Commons holds the work only small (638×900 at most); the bundled image is a crop of it, the same composition by eye, and the smallest painting in the bundle. |
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
| Prayers of the Church | the 1910 Raccolta, the Roman Ritual and Missal, and the app's own literal renderings from the Latin | The Prayer Book | Public-domain editions, named in the Prayer Book's source notes | Public domain |
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
