#!/usr/bin/env python3
"""The icon audit's contact sheet: every glyph the audit changes, the
current one beside the proposed one, at 16 and 24pt, in gold and cream on
the app's ground (#0A0A15), with the reason for the change.

    python3 Tools/IconAudit/make_sheet.py

Reads the glyphs from the asset catalog, so it must run before the old
assets are removed (or keep them in Tools/IconAudit/retired/). Writes
contact-sheet.html and, through headless Chrome, contact-sheet.png.
"""

import glob
import html
import os
import re
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ICONS = os.path.join(HERE, "..", "..", "app", "Assets.xcassets", "Icons")
RETIRED = os.path.join(HERE, "retired")
APP_ICON = os.path.normpath(os.path.join(HERE, "..", "..", "app", "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png"))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# (place, current, proposed, reason)
SECTIONS = [
    ("The Rosary and its mysteries", [
        ("The Rosary · 28 places, the launch screen at 88pt", "ch-rosary", "lv-rosary",
         "A ring over a cross is the sign for female (♀), and at 16pt it read as that. Beads, medal, pendant and crucifix read as a rosary."),
        ("Joyful Mysteries", "ph-star", "lv-star",
         "A rating star. Now the Star of Bethlehem, with its long lower ray. The drawing is Christicons' star with its four short rays left off; with them it read as a sparkle."),
        ("Sorrowful Mysteries", "ch-crown-of-thorns", "lv-crown-of-thorns",
         "A ring with eight spokes read as a sun, a gear or a virus. Now a plaited ring with thorns, as the Arma Christi draw it."),
        ("Glorious Mysteries", "ph-sun-horizon", "lv-banner",
         "A weather-app sunrise. Now the Resurrection banner (the vexillum) that the risen Christ carries."),
        ("Luminous Mysteries", "ph-sparkle", "lv-jordan",
         "Sparkle means “new” or “AI”. Now the dove over the Jordan, the first Mystery of Light: the Holy Ghost's dove (ch-dove), set over the river. There is no older emblem, since the set dates from 2002."),
        ("Seven Sorrows", "ch-sorrowful-heart", "lv-pierced-heart",
         "The only solid devotional glyph, and heavier than the rest. Now a stroked heart pierced by Simeon's sword (Lk 2:35)."),
    ]),
    ("The Prayer Book's chapters", [
        ("I · The First Prayers, and every “a prayer” / Pray aloud mark", "ph-hands-praying", "ch-praying-hands",
         "Two drawings of praying hands in two weights. One is kept, the Prayer Book's own."),
        ("III · Our Lord", "ch-crown-of-thorns", "ch-chi-rho",
         "It shared the Sorrowful Mysteries' glyph. Now the Chi-Rho, Christ's own monogram."),
        ("V · The Holy Ghost", "ph-bird", "ch-dove",
         "A songbird. Now the dove."),
        ("VI · Angels and Saints; the Marian Saints; saints' doors; the Saints kind", "ph-user", "lv-saint",
         "The account avatar. Now a saint under a halo."),
        ("VII · Through the Day (Per Diem)", "ph-sun-horizon", "lv-hourglass",
         "A sunrise. Now the day's hours as they pass. Nothing is timed or counted."),
        ("VIII · Penance; Before and After Confession; Carlo's confession", "ph-chat-teardrop-text", "ch-keys",
         "Feedback's chat bubble. Now the keys of absolution (Jn 20:23), the Sacrament's traditional sign."),
        ("XI · The Litanies", "ph-list", "lv-procession-cross",
         "This was the ☰ menu glyph. Litanies were first sung in procession, behind this cross (the Greater Litany, the Rogation Days)."),
        ("XII · Short Prayers (Iaculatoriæ)", "ph-sparkle", "lv-dart",
         "Sparkle. Iaculatoriæ are prayers “darted out” (Augustine, Ep. 130), which is where the Latin name comes from."),
    ]),
    ("The hours: Prayer Book orders, Pray tray, Rule of Prayer", [
        ("Morning Prayers", "ph-sun-horizon", "lv-rooster",
         "A weather-app sunrise. Now the cock of Lauds: Ambrose's Aeterne rerum Conditor, “gallo canente spes redit”."),
        ("The Angelus, its bell setting, the pray-along bell, the Church Bells sound", "ph-bell", "lv-bell",
         "It was the same bell as Daily Reminders, one row above it in Settings. Now a church bell on its yoke, the “Gabriel's bell” the Angelus rang. The Altar Bell sound keeps the hand bell."),
        ("Night Prayers (Preces Vespertinæ)", "ph-moon-stars", "lv-lamp",
         "On an iPhone a moon means Do Not Disturb. Now the lamp lit at evening: Vespers was the lucernarium, the lighting of the lamps."),
        ("At Table", "ph-leaf", "ch-bread",
         "A leaf. Now the loaf."),
    ]),
    ("The Marian Library's shelves (and the doors to their readings)", [
        ("The Four Marian Dogmas · Immaculate Conception doors", "ph-star-fill", "lv-twelve-stars",
         "A rating star. Now the crown of twelve stars (Apoc 12:1), the Church's image of the Immaculate Conception and the Assumption."),
        ("Approved Apparitions · Lourdes, Fatima doors", "ph-sun", "lv-rose",
         "A weather sun. Now the rose: the roses of Guadalupe, the golden roses at her feet at Lourdes, the Rosa mystica."),
        ("Titles of Our Lady · Help of Christians door", "ph-star", "lv-stella-maris",
         "A rating star, the same as the Joyful Mysteries'. Now Stella Maris, the Star of the Sea, her oldest title: the Joyful star, set over the waves."),
    ]),
    ("Milestones and the celebration card", [
        ("A Faithful Week (7 days)", "ph-sun", "ph-number-circle-seven",
         "A sun. Now the count, like Triduum ③ and Novena ⑨ beside it."),
        ("54-Day Novena", "ph-medal", "lv-rosary",
         "A prize ribbon, which is gamification. Now the Rosary this novena is prayed on."),
        ("Hundredfold (100 days) · True Devotion's “Benefits”", "ph-leaf", "lv-wheat",
         "A leaf. Now the grain that bore fruit a hundredfold (Mt 13:8)."),
        ("A Year of Grace (365 days)", "ph-sparkle", "ch-chi-rho",
         "Sparkle. Now Christ's monogram, for “the acceptable year of the Lord” (Lk 4:19)."),
        ("MILESTONE REACHED flourishes", "ph-sparkle-fill", "lv-lozenge",
         "Sparkles. Now the diamond studs of the app's ornament rule: an ornament, not a sign."),
    ]),
    ("Elsewhere", [
        ("Carlo Acutis · his guardian angel", "ph-sparkle", "ch-angel",
         "Sparkle. Now the angel's wing."),
        ("Prayer page · Learn it by heart", "ph-sparkle", "ph-heart",
         "Sparkle. Now the heart, which is what “by heart” means."),
        ("Settings · Appearance", "ph-sparkle", "ph-palette",
         "Sparkle. Now the palette, the system's word for how the app looks."),
        ("Send Feedback · An idea", "ph-sparkle", "ph-lightbulb",
         "Sparkle. Now the lightbulb."),
    ]),
]

RETIRING = [
    ("ph-sun-horizon", "no place left"), ("ph-sun", "no place left"), ("ph-sparkle", "no place left"),
    ("ph-sparkle-fill", "no place left"), ("ph-star", "no place left"), ("ph-star-fill", "no place left"),
    ("ph-medal", "no place left"), ("ph-leaf", "no place left"), ("ph-user", "no place left"),
    ("ph-hands-praying", "no place left"), ("ch-rosary", "no place left"),
    ("ch-crown-of-thorns", "no place left"), ("ch-sorrowful-heart", "no place left"),
    ("lv-chalice", "unused before the audit"), ("ph-crown-fill", "unused before the audit"),
    ("ph-heart-fill", "unused before the audit"),
]

KEPT_FOR_CHROME = [
    ("ph-bird", "the Birdsong reminder sound"), ("ph-moon-stars", "the reader's sleep timer"),
    ("ph-list", "the ☰ contents button"), ("ph-chat-teardrop-text", "Send Feedback"),
    ("ph-bell", "Daily Reminders"),
]


def glyph(name):
    """A glyph's SVG, from the catalog or, once retired, from retired/."""
    hits = glob.glob(os.path.join(ICONS, f"{name}.imageset", "*.svg")) \
        or glob.glob(os.path.join(RETIRED, f"{name}.svg"))
    if not hits:
        raise SystemExit(f"missing glyph {name}")
    s = open(hits[0]).read()
    s = re.sub(r"#000000|#000\b|currentColor", "currentColor", s)
    return re.sub(r'\s(width|height)="\d+"', "", s, count=2)


def swatch(name):
    g = glyph(name)
    return (
        f'<div class="sw"><span class="g16 gold">{g}</span><span class="g24 gold">{g}</span>'
        f'<span class="g16 cream">{g}</span><span class="g24 cream">{g}</span></div>'
        f'<div class="nm">{html.escape(name)}</div>'
    )


def main():
    rows = []
    for title, items in SECTIONS:
        rows.append(f'<h2>{html.escape(title)}</h2>')
        for place, cur, new, why in items:
            rows.append(
                '<div class="row">'
                f'<div class="place"><div class="pl">{html.escape(place)}</div><div class="why">{html.escape(why)}</div></div>'
                f'<div class="col">{swatch(cur)}</div><div class="arrow">→</div><div class="col">{swatch(new)}</div>'
                '</div>'
            )
    retiring = "".join(
        f'<div class="chip"><span class="g24 gold">{glyph(n)}</span><div class="nm">{n}</div><div class="why">{why}</div></div>'
        for n, why in RETIRING
    )
    kept = "".join(
        f'<div class="chip"><span class="g24 gold">{glyph(n)}</span><div class="nm">{n}</div><div class="why">{why}</div></div>'
        for n, why in KEPT_FOR_CHROME
    )
    page = f"""<!doctype html><html><head><meta charset="utf-8"><style>
body{{background:#0A0A15;color:#F6F1E4;font:13px -apple-system,Helvetica,sans-serif;margin:0;padding:28px 36px 40px;width:1128px}}
h1{{font:600 22px Georgia,serif;color:#E3BC5B;letter-spacing:.06em;margin:0 0 4px}}
.lede{{color:#8B8BA5;margin:0 0 14px;max-width:900px;line-height:1.45}}
.key{{color:#8B8BA5;font-size:12px;margin-bottom:6px}}
h2{{font:600 13px Georgia,serif;color:#E3BC5B;letter-spacing:.14em;text-transform:uppercase;margin:22px 0 6px;padding-bottom:6px;border-bottom:1px solid rgba(227,188,91,.24)}}
.row{{display:grid;grid-template-columns:1fr 170px 26px 170px;align-items:center;gap:14px;padding:9px 0;border-bottom:1px solid rgba(227,188,91,.08)}}
.pl{{color:#F6F1E4;font-size:13.5px}} .why{{color:#8B8BA5;font-size:12px;line-height:1.4;margin-top:3px}}
.col{{display:flex;flex-direction:column;align-items:flex-start;gap:4px}}
.sw{{display:flex;align-items:center;gap:14px}} .nm{{color:#8B8BA5;font:11px Menlo,monospace}}
.arrow{{color:#E3BC5B;font-size:18px;text-align:center}}
.g16 svg{{width:16px;height:16px;display:block}} .g24 svg{{width:24px;height:24px;display:block}}
.gold{{color:#E3BC5B}} .cream{{color:#F6F1E4}}
.chips{{display:grid;grid-template-columns:repeat(4,1fr);gap:10px 18px;margin-top:8px}}
.chip{{display:grid;grid-template-columns:30px 1fr;column-gap:8px;align-items:center}} .chip .why{{grid-column:2;margin:0}}
.appicon{{display:grid;grid-template-columns:180px 1fr;gap:22px;align-items:start;margin-top:10px}}
.appicon img{{width:180px;height:180px;border-radius:40px}}
.appicon li{{color:#F6F1E4;margin:0 0 8px;line-height:1.45}} .appicon li span{{color:#8B8BA5}}
</style></head><body>
<h1>Lumen Viae · Icon audit</h1>
<p class="lede">Each row shows the glyph now in use and the one proposed, at 16 and 24pt, in gold and in cream on the app's ground. New drawings are <b>lv-*</b>, stroked at 1.5 to match the ch-* glyphs beside them. <b>ch-*</b> are Christicons (free for commercial use and modification, but not to be redistributed as a set). <b>ph-*</b> are Phosphor Light (MIT).</p>
<div class="key">Order in each group: 16 gold · 24 gold · 16 cream · 24 cream</div>
{''.join(rows)}
<h2>Retired: removed from the asset catalog</h2>
<div class="chips">{retiring}</div>
<h2>Kept, for their plain uses (their devotional uses are replaced above)</h2>
<div class="chips">{kept}</div>
<h2>The app icon: proposals only, nothing changed</h2>
<div class="appicon"><img src="file://{APP_ICON}"><ul>
<li>Remove the baked-in rounded frame and the dark corners. <span>iOS masks the icon's corners itself, so the artwork draws a second, inner rim inside the system's.</span></li>
<li>Draw the monogram correctly. <span>The M's legs cross into an X under the cross. The Miraculous Medal's monogram is an M with a bar and a cross rising from it, which is what ch-consecration draws.</span></li>
<li>Count the crown to exactly twelve stars (Apoc 12:1).</li>
<li>The three alternate icons are switched off. If they come back, drop their scattered “twinkle” stars, which are the same vocabulary as the sparkles retired above.</li>
<li>Keep the wordmark. <span>It is set in Cinzel as type, with no glyph in it.</span></li>
</ul></div>
</body></html>"""
    out_html = os.path.join(HERE, "contact-sheet.html")
    with open(out_html, "w") as fh:
        fh.write(page)
    height = 200 + sum(58 + 62 * len(items) for _, items in SECTIONS) + 380 + 330
    subprocess.run([
        CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=2",
        f"--screenshot={os.path.join(HERE, 'contact-sheet.png')}", f"--window-size=1200,{height}",
        f"file://{out_html}",
    ], check=True, stderr=subprocess.DEVNULL)
    print(os.path.join(HERE, "contact-sheet.png"))


if __name__ == "__main__":
    main()
