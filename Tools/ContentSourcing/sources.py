#!/usr/bin/env python3
"""The content-sourcing record, written once here and rendered by
build_manifest.py into manifest.json and MANIFEST.md. Edit this file, not
those two.

Every entry has a `status`:

  unverified   named here, but no licence page has been read: a work
               identified from the image, or a candidate for an open slot
  verified     fetch.py read the licence on the source page (Commons' file
               page, or Verbum Gloriae's licence page and the chant's own
               page) and it is on the allowed list
  flagged      a licence that cannot be established, or one known not to
               be open

Nothing unverified is merged into the app. This round was done with the
network policy refusing every source host, so everything below starts
unverified; fetch.py takes each entry the rest of the way.
"""

PD_ART = {
    "licence": "Public domain (PD-Art: faithful 2D reproduction of a work whose author died more than 100 years ago)",
    "licence_url": "https://commons.wikimedia.org/wiki/Commons:Reuse_of_PD-Art_photographs",
    "attribution": None,
}
CC0_MET = {
    "licence": "CC0 1.0 (The Met Open Access)",
    "licence_url": "https://www.metmuseum.org/about-the-met/policies-and-documents/open-access",
    "attribution": None,
}
CC0_AIC = {
    "licence": "CC0 1.0 (Art Institute of Chicago open access)",
    "licence_url": "https://www.artic.edu/open-access/open-access-images",
    "attribution": None,
}
VG = {
    "licence": "Verbum Gloriae copyleft (CC BY-SA 4.0 terms without the attribution requirement; ShareAlike)",
    "licence_url": "https://www.verbumgloriae.es/licencia-copyleft/",
    "attribution": "Recordings and scores: Verbum Gloriae (verbumgloriae.es), copyleft",
    "creator": "Verbum Gloriae",
}

# --------------------------------------------------------------- new paintings
# Each slot names a first choice and an alternate. `commons_search` is what
# fetch.py searches Commons for; it shows every hit with its licence and size
# so the right file is picked by eye, and `commons_file` is then filled in.

PAINTINGS = [
    dict(imageset="season_advent", slot="(a) Advent: Chant Year/Learn boards, 'Learn Rorate Cæli before Advent' card; Year board's Advent season",
         features=["Chant Library: Year, Schola"],
         work="The Immaculate Conception of Los Venerables", creator="Bartolomé Esteban Murillo (1617–1682)", date="c. 1678",
         collection="Museo del Prado, Madrid", source_page="https://www.museodelprado.es/en/the-collection",
         commons_search="Murillo Immaculate Conception of Los Venerables Prado",
         why="Rorate cæli desuper — the heavens dropping down the Just One; Advent's Marian expectation, in the bundle's Spanish Baroque register (cf. the Velázquez Coronation).",
         alternate="Philippe de Champaigne, The Annunciation (c. 1644) (The Met, CC0 if open access) — if a scene rather than an icon is wanted",
         **PD_ART),
    dict(imageset="devotion_holy_trinity", slot="(b) Sunday · the Holy Trinity: Chant Main board, weekday devotions strip",
         features=["Chant Library: Main"],
         work="The Holy Trinity", creator="Jusepe de Ribera (1591–1652)", date="c. 1635",
         collection="Real Monasterio de San Lorenzo de El Escorial (a variant of the Prado's picture)",
         source_page="https://www.patrimonionacional.es/",
         commons_search="José de Ribera Santísima Trinidad",
         why="The Throne of Grace (the Father holding the dead Son, the Dove above) — tenebrist palette that sits beside the Caravaggio Entombment and Velázquez Crucifixion.",
         alternate="Guido Reni, The Holy Trinity (1625–26), Santissima Trinità dei Pellegrini, Rome",
         # The scan takes in the gilt frame's inner edge on all four sides
         crop=(0.014, 0.014, 0.016, 0.008),
         **PD_ART),
    dict(imageset="devotion_holy_souls", slot="(c) Monday · the Holy Souls; Occasions 'For Those Who Have Died'; Year board All Souls (Nov 2)",
         features=["Chant Library: Main, Occasions, Year", "Prayer Book: For the Holy Souls"],
         work="The Day of the Dead (Le Jour des morts)", creator="William-Adolphe Bouguereau (1825–1905)", date="1859",
         collection="Musée des Beaux-Arts de Bordeaux", source_page="https://www.musba-bordeaux.fr/",
         commons_search="Bouguereau Le jour des morts 1859",
         why="Two women in mourning at a grave on All Souls' Day; by the painter of the bundle's Pietà and Flagellation, so the two read as one hand.",
         alternate="Ludovico Carracci, An Angel Frees the Souls of Purgatory (c. 1610), Pinacoteca Vaticana",
         **PD_ART),
    dict(imageset="devotion_guardian_angels", slot="(d) Tuesday · the Holy Angels: Chant Main board, weekday devotions strip",
         features=["Chant Library: Main", "Prayer Book: Angels and Saints"],
         work="The Guardian Angel", creator="Bernardo Strozzi (1581–1644)", date=None,
         collection="Museum of Fine Arts, Houston (76.256)", source_page="https://www.mfah.org/art/detail/3618",
         commons_search="Bernardo Strozzi Guardian Angel Houston",
         why="The guardian angel standing over a child, arms open to keep her: Tuesday's devotion exactly, Genoese Baroque beside the bundle's Caravaggio and Van Dyck. Undated in the museum's record.",
         alternate="Pietro da Cortona, The Guardian Angel (1656), Galleria Nazionale d'Arte Antica, Rome — the first choice, but Commons holds it only at 694×1100",
         **PD_ART),
    dict(imageset="devotion_st_joseph", slot="(e) Wednesday · St Joseph: Chant Main board, weekday devotions strip",
         features=["Chant Library: Main"],
         work="Saint Joseph and the Christ Child", creator="Guido Reni (1575–1642)", date="c. 1640",
         collection="Museum of Fine Arts, Houston", source_page="https://emuseum.mfah.org/",
         commons_search="Guido Reni Saint Joseph Christ Child Houston",
         why="Half-length Joseph holding the Child: an icon of the saint that crops well to a tile.",
         alternate="Bartolomé Esteban Murillo, Saint Joseph with the Infant Jesus (c. 1665–66), Museo de Bellas Artes de Sevilla",
         **PD_ART),
    dict(imageset="feast_our_lady_of_the_rosary", slot="(f) October / Our Lady of the Rosary (Oct 7): Chant Main 'Month of the Holy Rosary' card, Year 'Feast days ahead', Occasions 'A Sung Rosary'",
         features=["Chant Library: Main, Year, Occasions"],
         work="Madonna of the Rosary", creator="Caravaggio (1571–1610)", date="1607",
         collection="Kunsthistorisches Museum, Vienna", source_page="https://www.khm.at/en/",
         commons_search="Caravaggio Madonna of the Rosary Kunsthistorisches",
         why="St Dominic giving out rosaries at Our Lady's command — the feast's own subject, by the painter of the bundle's Entombment.",
         alternate="Bartolomé Esteban Murillo, The Virgin of the Rosary (c. 1650–55), Museo del Prado",
         **PD_ART),
    dict(imageset="feast_christ_the_king", slot="(g) Christ the King (last Sunday of October): Chant Year 'Feast days ahead' (Christus Vincit)",
         features=["Chant Library: Year"],
         work="Christ Triumphant over Sin and Death", creator="Peter Paul Rubens (1577–1640)", date="c. 1615–22",
         collection="Rubens workshop picture; several versions (e.g. Rubenshuis, Antwerp) — pick the version Commons tags PD-Art",
         source_page=None,
         commons_search="Rubens Christ triumphant over sin and death",
         why="The risen Christ enthroned over death, Flemish Baroque beside the bundle's Rubens Descent and Van Dyck Crowning.",
         alternate="Hans Memling, Christ Surrounded by Musician Angels (c. 1480s), KMSKA Antwerp — earlier style, but the kingship is explicit",
         **PD_ART),
    dict(imageset="feast_all_saints", slot="(g) All Saints (Nov 1): Chant Year 'Feast days ahead' (Litaniæ Sanctorum)",
         features=["Chant Library: Year", "Prayer Book: Angels and Saints"],
         work="Adoration of the Trinity (The Landauer Altarpiece)", creator="Albrecht Dürer (1471–1528)", date="1511",
         collection="Kunsthistorisches Museum, Vienna", source_page="https://www.khm.at/en/",
         commons_search="Dürer Landauer Altarpiece Adoration of the Trinity",
         why="The communion of saints, every state of the Church adoring the Trinity: All Saints in one picture; also a second choice for the Trinity slot.",
         alternate="Fra Angelico, The Forerunners of Christ with Saints and Martyrs (c. 1423–24), National Gallery, London",
         **PD_ART),
    dict(imageset="hour_morning", slot="(h) Prayer Book 'Pray Now' hero for Morning Prayers (On rising)",
         features=["Prayer Book: Combined-Today, DirectionA/B"],
         work="The Song of the Lark", creator="Jules Breton (1827–1906)", date="1884",
         collection="Art Institute of Chicago", source_page="https://www.artic.edu/artworks/94841/the-song-of-the-lark",
         commons_search="Jules Breton The Song of the Lark Art Institute",
         why="A field-worker stopping at sunrise — the day offered at its start; 19th-c. academic like the Hofmann and Bouguereau already bundled. AIC publishes it CC0.",
         alternate="Jean-François Millet, The Angelus (1857–59), Musée d'Orsay — but that is the evening Angelus",
         **CC0_AIC),
    dict(imageset="hour_night", slot="(h) Prayer Book 'Pray Now' hero for Night Prayers (Before sleep); Chapel's Prayer Book tile at night",
         features=["Prayer Book: Combined-Today", "Chapel: Prayer Book tile"],
         work="The Penitent Magdalen", creator="Georges de La Tour (1593–1652)", date="c. 1640",
         collection="The Metropolitan Museum of Art", source_page="https://www.metmuseum.org/art/collection/search/436838",
         commons_search="Georges de La Tour Penitent Magdalen Metropolitan",
         why="Prayer by a single candle at night — the examination of conscience before sleep. The Met's open-access image is CC0.",
         alternate="Georges de La Tour, The Magdalen with the Smoking Flame (c. 1640), LACMA",
         **CC0_MET),
    dict(imageset="occasion_before_bed", slot="(i) Chant Occasions 'Before Bed' (Compline chants)",
         features=["Chant Library: Occasions"],
         work="Reuse hour_night (no separate file proposed)", creator=None, date=None, collection=None, source_page=None,
         commons_search=None,
         why="Same subject as Night Prayers; an alias saves ~500 KB. If a distinct picture is wanted: Gerrit van Honthorst / Jan Lievens candlelight devotional scenes.",
         alternate=None, licence=None, licence_url=None, attribution=None, alias_of="hour_night"),
]

# No design draws occasion art (the Prayer Book's occasions are ruled rows
# with glyphs; the Chant Library's featured occasion is the bundled
# Institution of the Eucharist). Kept for a later design; fetch.py never
# takes these.
UNUSED = [
    dict(imageset="occasion_before_work", slot="(i) Chant Occasions 'Before Work or Study' (Veni Creator, Veni Sancte reple)",
         features=["Chant Library: Occasions"],
         work="The Apotheosis of Saint Thomas Aquinas", creator="Francisco de Zurbarán (1598–1664)", date="1631",
         collection="Museo de Bellas Artes de Sevilla", source_page="https://www.museosdeandalucia.es/web/museodebellasartesdesevilla",
         commons_search="Zurbarán Apotheosis of Saint Thomas Aquinas",
         why="The patron of students under the Dove — study begun by asking the Holy Ghost; Spanish Golden Age.",
         alternate="Georges de La Tour, Saint Joseph the Carpenter (c. 1642), Musée du Louvre — work rather than study",
         **PD_ART),
    dict(imageset="occasion_visit_blessed_sacrament", slot="(i) Chant Occasions 'Visiting the Blessed Sacrament'; Prayer Book 'A Visit to the Blessed Sacrament'",
         features=["Chant Library: Occasions", "Prayer Book: Occasions"],
         work="Disputation of the Holy Sacrament (Disputa)", creator="Raphael (1483–1520)", date="1509–10",
         collection="Stanza della Segnatura, Vatican", source_page="https://www.museivaticani.va/",
         commons_search="Raphael Disputation of the Holy Sacrament",
         why="The Host in the monstrance on the altar, heaven open above it; the bundle already holds Raphael's Transfiguration. Wide — crop to the altar.",
         alternate="Reuse luminous_eucharist (already Benediction's picture in the Occasions board)",
         **PD_ART),
    dict(imageset="occasion_confession", slot="(i) Prayer Book occasions 'Before / After Confession'",
         features=["Prayer Book: Occasions"],
         work="Confession (from The Seven Sacraments)", creator="Giuseppe Maria Crespi (1665–1747)", date="c. 1712",
         collection="Gemäldegalerie Alte Meister, Dresden", source_page="https://skd-online-collection.skd.museum/",
         commons_search="Giuseppe Maria Crespi Confession Seven Sacraments Dresden",
         why="A penitent at the grille of the confessional — the sacrament itself, in warm Bolognese chiaroscuro.",
         alternate="Pietro Longhi, The Confession (c. 1750), Gallerie dell'Accademia / Uffizi",
         **PD_ART),
    dict(imageset="occasion_mass", slot="(i) Prayer Book occasions 'At Mass' (Before Mass, After Communion); Chant Mass Ordinary if added",
         features=["Prayer Book: Occasions", "Chant Library (Tier 2 Mass Ordinary)"],
         work="The Mass at Bolsena", creator="Raphael (1483–1520)", date="1512",
         collection="Stanza di Eliodoro, Vatican", source_page="https://www.museivaticani.va/",
         commons_search="Raphael Mass at Bolsena",
         why="A priest at the altar at the elevation; Raphael again, and a crop of the altar reads at tile size.",
         alternate="Giuseppe Maria Crespi, Communion (from The Seven Sacraments), Dresden",
         **PD_ART),
]

# ------------------------------------------------- provenance of what's bundled
# Identified from the images themselves (contact sheet, Sept 2026), then
# each bundled image compared with the Commons files of its work (Sept 30):
# aspect ratio, and the correlation of the two at 32x32 in grayscale, with
# every uncertain pair checked by eye. `confirmed` means that comparison
# found the work; PROVENANCE below names the file.

EXISTING = [
    ("glorious_coronation", "The Coronation of the Virgin", "Diego Velázquez", "1635–36", "Museo del Prado", "confirmed"),
    ("sorrowful_crucifixion", "Christ Crucified", "Diego Velázquez", "c. 1632", "Museo del Prado", "confirmed"),
    ("sorrowful_crowning", "The Crowning with Thorns", "Anthony van Dyck", "1618–20", "Museo del Prado", "confirmed"),
    ("sorrowful_agony", "Christ in Gethsemane", "Heinrich Hofmann (d. 1911)", "1886", "Riverside Church, New York", "confirmed"),
    ("sorrowful_scourging", "The Flagellation of Our Lord Jesus Christ", "William-Adolphe Bouguereau (d. 1905)", "1880", "Cathédrale Saint-Louis, La Rochelle", "confirmed"),
    ("seven_sorrows_pieta", "Pietà", "William-Adolphe Bouguereau (d. 1905)", "1876", "Private collection", "confirmed"),
    ("seven_sorrows_burial", "The Entombment of Christ", "Caravaggio", "1603–04", "Pinacoteca Vaticana", "confirmed"),
    ("luminous_transfiguration", "The Transfiguration", "Raphael", "1516–20", "Pinacoteca Vaticana", "confirmed"),
    ("luminous_proclamation", "The Sermon on the Mount", "Carl Heinrich Bloch (d. 1890)", "1877", "Museum of National History, Frederiksborg Castle", "confirmed"),
    ("seven_sorrows_meeting", "Christ Falls on the Way to Calvary (Lo Spasimo di Sicilia)", "Raphael", "c. 1516", "Museo del Prado", "confirmed"),
    ("seven_sorrows_descent", "The Descent from the Cross", "Peter Paul Rubens", "1612–14", "Cathedral of Our Lady, Antwerp", "confirmed"),
    ("seven_sorrows_simeon", "Simeon's Song of Praise", "Rembrandt", "1631", "Mauritshuis, The Hague", "confirmed"),
    ("luminous_eucharist", "The Last Supper", "Juan de Juanes", "c. 1562", "Museo del Prado", "confirmed"),
    ("joyful_presentation", "The Presentation in the Temple", "Simon Vouet", "1641", "Musée du Louvre", "confirmed"),
    ("seven_sorrows_flight", "The Flight into Egypt", "Bartolomé Esteban Murillo", "1647–50", "Musei di Strada Nuova (Palazzo Bianco), Genoa", "confirmed"),
    ("luminous_baptism", "The Baptism of Christ", "Guido Reni", "c. 1623", "Kunsthistorisches Museum, Vienna", "confirmed"),
    ("joyful_annunciation", "The Annunciation", "Paolo de Matteis", "1712", "Saint Louis Art Museum", "confirmed"),
    ("joyful_finding", "Christ among the Doctors", "Paolo Veronese", "c. 1558", "Museo del Prado", "confirmed"),
    ("joyful_visitation", "The Visitation", "Raphael and workshop (Giulio Romano)", "c. 1517", "Museo del Prado", "confirmed"),  # signed RAPHAEL URBINAS at the foot
    ("luminous_cana", "The Marriage Feast at Cana", "Bartolomé Esteban Murillo", "c. 1672", "Barber Institute of Fine Arts, Birmingham", "confirmed"),
    ("sorrowful_carrying", "Christ Carrying the Cross", "Anthony van Dyck", "1617–18", "Sint-Pauluskerk, Antwerp", "confirmed"),
    ("glorious_resurrection", "The Resurrection of Christ", "Noël Coypel", "1700", "unconfirmed (French royal commission)", "confirmed"),
    # Once thought Maíno's; set beside the Prado's Maíno it is another
    # picture (landscape, Mary seated at the centre), so its painter is unknown
    ("glorious_pentecost", "Pentecost (not Maíno's: the Prado's Maíno is a different composition)", None, None, None, "ask Abraham"),
    ("glorious_ascension", "The Ascension (Spanish or Flemish Baroque, 17th c.)", None, None, None, "ask Abraham"),
    ("glorious_assumption", "The Assumption of the Virgin (Neapolitan/Roman, 18th c., in the manner of Giaquinto or Solimena)", None, None, None, "ask Abraham"),
    ("joyful_nativity", "The Adoration of the Shepherds, night scene with putti (Italian Baroque, in the manner of Guido Reni)", None, None, None, "ask Abraham"),
]

# The Commons file each confirmed painting matches, its licence as read on
# that file page, and how close the match is. `exact`: the bundled image is
# that file or a resize of it (correlation 0.996 or more, same aspect), so
# its source and licence are both known. `same work`: the bundled image is a
# crop or another scan of the same picture (checked by eye); PD-Art covers
# any faithful reproduction of it, but the file it came from is not proven.
PROVENANCE = {
    "glorious_coronation": dict(commons_file="File:Diego Velázquez - Coronation of the Virgin - Prado.jpg", licence="Public domain",
                                match="exact", score=1.0, bundled="640×852",
                                note="Bundled at 640×852, under a third of the file's 2292×3051."),
    "sorrowful_crucifixion": dict(commons_file="File:Cristo crucificado.jpg", licence="Public domain",
                                  match="exact", score=1.0, bundled="2046×3051"),
    "sorrowful_crowning": dict(commons_file="File:Anthonis van Dyck 004.jpg", licence="Public domain",
                               match="exact", score=1.0, bundled="2362×2705"),
    "sorrowful_agony": dict(commons_file="File:Christ in Gethsemane.jpg", licence="Public domain",
                            match="exact", score=1.0, bundled="960×1346",
                            note="Bundled at 960×1346; the file is 1141×1600."),
    "sorrowful_scourging": dict(commons_file="File:William-Adolphe Bouguereau (1825-1905) - The Flagellation of Our Lord Jesus Christ (1880).jpg",
                                licence="Public domain", match="exact", score=1.0, bundled="499×714",
                                note="Bundled at 499×714; the file is 2136×3056."),
    "seven_sorrows_pieta": dict(commons_file="File:William-Adolphe Bouguereau (1825-1905) - Pieta (1876).jpg", licence="Public domain",
                                match="exact", score=1.0, bundled="1920×3015"),
    "seven_sorrows_burial": dict(commons_file="File:The Entombment of Christ-Caravaggio (c.1602-3).jpg", licence="Public domain",
                                 match="exact", score=1.0, bundled="1920×2852"),
    "luminous_transfiguration": dict(commons_file="File:Transfiguration Raphael.jpg", licence="Public domain",
                                     match="exact", score=1.0, bundled="1067×1608"),
    "luminous_proclamation": dict(commons_file="File:Bloch-SermonOnTheMount.jpg", licence="Public domain",
                                  match="exact", score=1.0, bundled="1377×1545"),
    "seven_sorrows_meeting": dict(commons_file="File:Christ Falling on the Way to Calvary - Raphael.jpg", licence="Public domain",
                                  match="exact", score=1.0, bundled="1920×2663"),
    "seven_sorrows_descent": dict(commons_file="File:Peter Paul Rubens - Descent from the Cross - WGA20212 (cropped).jpg", licence="Public domain",
                                  match="same work", score=0.94, bundled="1689×2248",
                                  note="A crop of the Antwerp triptych's central panel, which this file cuts from the Web Gallery of Art's whole triptych."),
    "seven_sorrows_simeon": dict(commons_file="File:Simeon in the temple, by Rembrandt van Rijn.jpg", licence="Public domain",
                                 match="exact", score=0.999, bundled="1920×2473"),
    "luminous_eucharist": dict(commons_file="File:The Last Supper by Vicente Juan Macip.jpg", licence="Public domain",
                               match="same work", score=0.967, bundled="1517×998",
                               note="A crop of this scan or of another of the same picture."),
    "joyful_presentation": dict(commons_file="File:Simon Vouet - Presentation in the Temple - WGA25366.jpg", licence="Public domain",
                                match="exact", score=1.0, bundled="800×1302"),
    "seven_sorrows_flight": dict(commons_file="File:Bartolomé Esteban Murillo - The Flight into Egypt - Google Art Project.jpg", licence="Public domain",
                                 match="exact", score=1.0, bundled="1920×2465",
                                 note="The Genoa picture (Musei di Strada Nuova), not Detroit's as first thought."),
    "luminous_baptism": dict(commons_file="File:Guido Reni - The Baptism of Christ - Google Art Project.jpg", licence="Public domain",
                             match="exact", score=1.0, bundled="1920×2727"),
    "joyful_annunciation": dict(commons_file="File:Paolo de Matteis - The Annunciation - 69-1973 - Saint Louis Art Museum.jpg", licence="Public domain",
                                match="same work", score=0.928, bundled="4351×5077",
                                note="The bundled image is larger than any Commons file of the work: another scan, most likely the museum's own."),
    "joyful_finding": dict(commons_file="File:Disputa con los doctores (El Veronés) grande.jpg", licence="Public domain",
                           match="exact", score=0.996, bundled="3051×1667"),
    "joyful_visitation": dict(commons_file="File:Visitación de Rafael.jpg", licence="Public domain",
                              match="exact", score=1.0, bundled="1157×1600",
                              note="fetch.py --provenance's search finds only 'Raphael - The visitation.jpg' (520×719), a weak match; "
                                   "the bundled file is this one, the same size to the pixel, found by comparing the images."),
    "luminous_cana": dict(commons_file="File:The Barber Institute of Fine Arts - Bartolomé Esteban Murillo - The Marriage Feast at CanaFXD.jpg",
                          licence="Public domain", match="same work", score=0.965, bundled="1920×1407",
                          note="A crop of this scan."),
    "sorrowful_carrying": dict(commons_file="File:Anthony van Dyck - Jesus Christ bearing the Cross.jpg", licence="Public domain",
                               match="exact", score=1.0, bundled="960×1261",
                               note="Bundled at 960×1261; the file, Sint-Pauluskerk's own photograph, is 3349×4399."),
    "glorious_resurrection": dict(commons_file="File:Noël Coypel - Resurrection of Christ (large version).jpg", licence="Public domain",
                                  match="same work", score=0.782, bundled="566×732",
                                  note="Commons holds the work only small (638×900 at most); the bundled image is a crop of it, "
                                       "the same composition by eye, and the smallest painting in the bundle."),
}

CARLO = dict(
    imageset="carlo_acutis", status="flagged",
    work="Photograph of Carlo Acutis (head and shoulders, red polo, mountains behind)",
    creator="Unknown; the widely circulated family photograph (c. 2005–06)",
    licence="Not established — almost certainly in copyright (a modern photograph; the Acutis family / Associazione Amici di Carlo Acutis control the official images)",
    note="Used in CarloAcutisView (CachedAssetImage(\"carlo_acutis\")). Do not ship without permission. "
         "Replacement options, in order: (1) written permission from the Associazione Carlo Acutis (carloacutis.com) for this photograph; "
         "(2) a freely licensed photograph on Commons (fetch.py --search 'Carlo Acutis' lists any, with licence; as of the last check most Commons "
         "images of him were deleted as non-free, so expect none); (3) no photograph: the page draws the votive candle or a monogram instead. "
         "A painted 'old master' image cannot exist for a saint who died in 2006, so the brief's 'same style' replacement is not possible here.",
)

# Where Abraham found the four marked "ask Abraham" settles them; the rest
# are named in PROVENANCE.

# ------------------------------------------------------------------- chants
# VG pages confirmed to exist by search (titles and URLs seen in results).
# `audio`/`scores` selectors on shared pages are left for fetch.py --chants
# to list, since the page itself could not be read here.

CHANT_GROUPS_TO_ADD = [
    {"id": "mass", "title": "The Mass", "note": "The Ordinary, sung as on Sundays"},
]

CHANTS = [
    # Tier 1 found on Verbum Gloriae
    dict(tier=1, found=True, entry={"id": "pange_lingua", "slug": "pange-lingua", "group": "sacrament", "latin": "Pange Lingua", "english": "Sing, My Tongue, the Saviour's Glory", "setting": None, "detail": "St Thomas Aquinas's hymn for Corpus Christi, whose last two verses are the Tantum Ergo", "prayers": []},
         source="https://www.verbumgloriae.es/project/pange-lingua/", est_seconds=270),
    dict(tier=1, found=True, entry={"id": "vidi_aquam", "slug": "vidi-aquam", "group": "easter", "latin": "Vidi Aquam", "english": "I Saw Water", "setting": None, "detail": "Sung at the sprinkling before Sunday Mass in Eastertide", "prayers": []},
         source="https://www.verbumgloriae.es/project/vidi-aquam/", est_seconds=150),
    # Tier 2
    dict(tier=2, found=True, entry={"id": "kyrie_de_angelis", "slug": "misa-viii-de-angelis", "page": "project/misa-viii-de-angelis", "group": "mass", "latin": "Kyrie", "english": "Lord, Have Mercy", "setting": "Mass VIII", "detail": "Mass VIII, the Missa de Angelis", "prayers": []},
         source="https://www.verbumgloriae.es/project/misa-viii-de-angelis/", est_seconds=90, audio_match="kyrie", scores_match="kyrie",
         note="One of four parts on the Misa VIII page; fetch.py picks its files by the name pattern 'kyrie'."),
    dict(tier=2, found=True, entry={"id": "gloria_de_angelis", "slug": "misa-viii-de-angelis", "page": "project/misa-viii-de-angelis", "group": "mass", "latin": "Gloria", "english": "Glory to God in the Highest", "setting": "Mass VIII", "detail": "Mass VIII, the Missa de Angelis", "prayers": []},
         source="https://www.verbumgloriae.es/project/misa-viii-de-angelis/", est_seconds=180, audio_match="gloria", scores_match="gloria",
         note="One of four parts on the Misa VIII page; fetch.py picks its files by the name pattern 'gloria'."),
    dict(tier=2, found=True, entry={"id": "sanctus_de_angelis", "slug": "misa-viii-de-angelis", "page": "project/misa-viii-de-angelis", "group": "mass", "latin": "Sanctus", "english": "Holy, Holy, Holy", "setting": "Mass VIII", "detail": "Mass VIII, the Missa de Angelis", "prayers": []},
         source="https://www.verbumgloriae.es/project/misa-viii-de-angelis/", est_seconds=60, audio_match="sanctus", scores_match="sanctus",
         note="One of four parts on the Misa VIII page; fetch.py picks its files by the name pattern 'sanctus'."),
    dict(tier=2, found=True, entry={"id": "agnus_de_angelis", "slug": "misa-viii-de-angelis", "page": "project/misa-viii-de-angelis", "group": "mass", "latin": "Agnus Dei", "english": "Lamb of God", "setting": "Mass VIII", "detail": "Mass VIII, the Missa de Angelis", "prayers": []},
         source="https://www.verbumgloriae.es/project/misa-viii-de-angelis/", est_seconds=60, audio_match="agnus", scores_match="agnus",
         note="One of four parts on the Misa VIII page; fetch.py picks its files by the name pattern 'agnus'."),
    dict(tier=2, found=True, entry={"id": "credo_iii", "slug": "credo-iii", "group": "mass", "latin": "Credo III", "english": "The Nicene Creed", "setting": "Credo III", "detail": "The Creed sung on Sundays and solemnities", "prayers": []},
         source="https://www.verbumgloriae.es/project/credo-iii/", est_seconds=330),
    # Tier 3 found
    dict(tier=3, found=True, entry={"id": "audi_benigne", "slug": "audi-benigne-conditor", "group": "lent", "latin": "Audi Benigne Conditor", "english": "O Kind Creator, Bow Thine Ear", "setting": None, "detail": "The Vespers hymn of Lent", "prayers": []},
         source="https://www.verbumgloriae.es/project/audi-benigne-conditor/", est_seconds=180),
    dict(tier=3, found=True, entry={"id": "o_vos_omnes", "slug": "misterios-dolorosos", "page": "cantos/santo-rosario/misterios-dolorosos", "group": "lent", "latin": "O Vos Omnes", "english": "O All Ye That Pass By", "setting": None, "detail": "Lamentations 1:12, sung in the Sorrowful Mysteries", "prayers": []},
         source="https://www.verbumgloriae.es/cantos/santo-rosario/misterios-dolorosos/", est_seconds=90, audio_match="vos[-_ ]?omnes", scores_match="vos[-_ ]?omnes",
         note="The page holds the whole sung Sorrowful Rosary; fetch.py picks this antiphon's files by the pattern 'vos-omnes'."),
    # Also on VG, not asked for but fitting slots the designs draw
    dict(tier="extra", found=True, entry={"id": "ad_regias", "slug": "ad-regias-agni-dapes", "group": "easter", "latin": "Ad Regias Agni Dapes", "english": "At the Lamb's High Feast", "setting": None, "detail": "The Vespers hymn of Eastertide", "prayers": []},
         source="https://www.verbumgloriae.es/project/ad-regias-agni-dapes/", est_seconds=200,
         note="An Eastertide hymn while Haec Dies is missing; there is also an 'otro tono' page."),
    dict(tier="extra", found=True, entry={"id": "te_matrem", "slug": "te-matrem-laudamus", "group": "ourLady", "latin": "Te Matrem Laudamus", "english": "We Praise Thee as Mother", "setting": None, "detail": "A Marian Te Deum", "prayers": []},
         source="https://www.verbumgloriae.es/project/te-matrem-laudamus/", est_seconds=240),
    dict(tier="extra", found=True, entry={"id": "o_oriens_magnificat", "slug": "o-oriens-et-magnificat", "group": "advent", "latin": "O Oriens", "english": "O Morning Star, with the Magnificat", "setting": None, "detail": "The O Antiphon of December 21, around Mary's song", "prayers": ["magnificat"]},
         source="https://www.verbumgloriae.es/project/o-oriens-et-magnificat/", est_seconds=330),
]

# Asked for, not found on VG by search. `fallback` is where to look next once
# the network allows; anything not a single cantor goes to the manager first.
NOT_FOUND = [
    ("O Lux Beata Trinitas", 1, "Sunday · Trinity", "Not a VG project page. VG's Compline/Breviarium books may carry it as PDF only (no recording)."),
    ("Angele Dei / Custodes hominum", 1, "Tuesday · Holy Angels", "None on VG."),
    ("Te Lucis Ante Terminum", 1, "Before Bed / Night", "VG has it only inside the Compline book (https://www.verbumgloriae.es/recursos/completas/), a PDF with no recording found."),
    ("In Manus Tuas", 1, "Before Bed / Night", "Same: in VG's Compline book only."),
    ("Nunc Dimittis", 1, "Before Bed / Night", "Same: in VG's Compline book only."),
    ("Iam Lucis Orto Sidere", 1, "Morning", "None on VG."),
    ("Requiem Æternam (Introit)", 1, "For the Dead", "None on VG (only Dies Iræ and the Litany of Saints)."),
    ("In Paradisum", 1, "For the Dead", "None on VG (search returned 'Paradisi portae', a Marian antiphon, instead)."),
    ("Lux Æterna", 1, "For the Dead", "None on VG."),
    ("De Profundis (Ps 129)", 1, "For the Dead", "None on VG as a project page."),
    ("Crux Fidelis / Pange Lingua Gloriosi Proelium", 1, "Passion / Friday", "None on VG (Vexilla Regis is held)."),
    ("Christus Factus Est", 1, "Passion / Friday", "None on VG."),
    ("Popule Meus (Improperia)", 1, "Passion / Friday", "None on VG."),
    ("Haec Dies", 1, "Easter", "None on VG; Ad Regias Agni Dapes proposed as the Eastertide stand-in."),
    ("Puer Natus Est Nobis (Introit)", 1, "Christmas", "None on VG (Puer Natus in Bethlehem is held)."),
    ("Resonet in Laudibus", 1, "Christmas", "None on VG."),
    ("Placare Christe Servulis", 3, "All Saints", "None on VG."),
    ("O Sanctissima", 3, "Our Lady", "None on VG."),
    ("Subvenite", 3, "For the Dead", "None on VG."),
    ("Libera Me", 3, "For the Dead", "None on VG."),
    ("Benedictus (canticle)", 3, "Morning", "None on VG as a project page."),
]

FALLBACK_SOURCES = [
    ("Wikimedia Commons, Category:Gregorian chant (audio)", "https://commons.wikimedia.org/wiki/Category:Gregorian_chant",
     "Many PD/CC0/CC BY-SA Ogg recordings; mostly choirs or amateurs, so a different voice from VG's cantor. List for the manager; don't stage."),
    ("Musopen", "https://musopen.org/", "Public-domain recordings; little plainchant."),
    ("Internet Archive (78 rpm transfers)", "https://archive.org/",
     "US public domain only for recordings published before 1926 (as of 2026); the transfer itself may carry terms; other countries differ. Check each, and prefer Commons."),
]
