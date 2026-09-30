#!/usr/bin/env python3
"""Candidates for the Today's Mysteries row's glyph, shown in the Pray tray.

The row (PrayerShortcut.chooseMeditation) wears ph-book-open, which the
Spiritual Reading door and the Journal tab wear too. This lays the tray
out as SheetRow draws it (16pt glyph at gold 60% in a 22pt slot, EB
Garamond Medium 16 over MediumItalic 13, a 24pt gutter, 52pt rows, the
caret at gold 40%), in the app's own fonts and the Candlelit palette, once
with each glyph:

    now  ph-book-open
    A    the day's own mysteries' emblem (MysteryCategory.iconName)
    B    lv-triptych, a new drawing (Tools/IconAudit/candidates/)

A was chosen (Sept 30): PrayerShortcut.icon(today:) returns the day's
category's iconName for this act. B stays drawn, as a candidate, so this
sheet can be made again.

    python3 Tools/IconAudit/draw.py --candidates
    python3 Tools/IconAudit/todays_mysteries.py

Writes todays-mysteries-candidates.html and .png beside this script.
"""

import glob
import html
import os
import re
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
ICONS = os.path.join(ROOT, "app", "Assets.xcassets", "Icons")
FONTS = os.path.join(ROOT, "app", "Resources", "Fonts")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


def glyph(name):
    hits = glob.glob(os.path.join(ICONS, f"{name}.imageset", "*.svg")) \
        or glob.glob(os.path.join(HERE, "candidates", f"{name}.svg"))
    s = open(hits[0]).read()
    s = re.sub(r"#000000|currentColor", "currentColor", s)
    return re.sub(r'\s(width|height)="\d+"', "", s, count=2)


def tray(day, mysteries, candidate, caption):
    rows = [
        ("lv-rosary", "Today's Rosary", f"{mysteries} · meditation aloud", True),
        ("ch-bible", "The Scriptural Rosary", f"{mysteries} · a verse for every bead", False),
        ("ph-speaker-high", "The Holy Rosary", f"{mysteries} · every prayer aloud", False),
        (candidate, "Today's Mysteries", "Every way to pray them", False),
        ("lv-bell", "The Angelus", "At six, noon and six, when the bell rings", False),
        ("ch-altar", "The Mass", "Today's propers · 1962 Missal", False),
        ("ph-clock", "The Divine Office", "The canonical hours · 1962 Breviary", False),
    ]
    body = []
    for icon, title, detail, lit in rows:
        mark = " mark" if title == "Today's Mysteries" else ""
        trailing = '<span class="quick">QUICK TAP</span>' if lit else f'<span class="caret">{glyph("ph-caret-right")}</span>'
        body.append(
            f'<div class="row{" lit" if lit else ""}{mark}"><span class="g">{glyph(icon)}</span>'
            f'<span class="t"><span class="title">{html.escape(title)}</span>'
            f'<span class="detail">{html.escape(detail)}</span></span>{trailing}</div>'
        )
    return (
        f'<div class="col"><div class="cap">{caption}</div><div class="phone">'
        f'<div class="grab"></div><div class="kicker">{day}</div><div class="head">Your Devotions</div>'
        + "".join(body) + '<div class="edit">EDIT THIS MENU</div></div></div>'
    )


def main():
    week = [
        ("Mon", "lv-star"), ("Tue", "lv-crown-of-thorns"), ("Wed", "lv-banner"),
        ("Thu", "lv-star"), ("Fri", "lv-crown-of-thorns"), ("Sat", "lv-banner"),
        ("Sun", "lv-banner"),
    ]
    strip = "".join(f'<span class="day"><span class="g24">{glyph(g)}</span>{d}</span>' for d, g in week)
    columns = [
        tray("TUESDAY, SEPTEMBER 29", "Sorrowful Mysteries", "ph-book-open",
             "<b>Now</b> · ph-book-open<br><i>The same open book as the Spiritual Reading door and the Journal tab.</i>"),
        tray("TUESDAY, SEPTEMBER 29", "Sorrowful Mysteries", "lv-crown-of-thorns",
             "<b>A</b> · the day's own emblem, on a Tuesday<br><i>The row names today's mysteries and wears their sign.</i>"),
        tray("MONDAY, SEPTEMBER 28", "Joyful Mysteries", "lv-star",
             "<b>A</b> · the same row on a Monday<br><i>It changes with the day, as the row's subject does.</i>"),
        tray("TUESDAY, SEPTEMBER 29", "Sorrowful Mysteries", "lv-triptych",
             "<b>B</b> · lv-triptych, a new drawing<br><i>The mysteries as the Rosary's altarpieces painted them.</i>"),
    ]
    fonts = "".join(
        f"@font-face{{font-family:'{n}';src:url('file://{FONTS}/{f}')}}"
        for n, f in (("Cinzel", "Cinzel-Regular.ttf"), ("GaramondM", "EBGaramond-Medium.ttf"),
                     ("GaramondMI", "EBGaramond-MediumItalic.ttf"))
    )
    page = f"""<!doctype html><html><head><meta charset="utf-8"><style>{fonts}
body{{background:#050509;margin:0;padding:26px 30px 30px;color:#F6F1E4;font:13px -apple-system,sans-serif;width:1760px}}
h1{{font:400 22px Cinzel;color:#E3BC5B;letter-spacing:.08em;margin:0 0 6px}}
.lede{{color:#8B8BA5;max-width:1500px;line-height:1.45;margin:0 0 18px}}
.cols{{display:flex;gap:22px}}
.col{{width:402px}}
.cap{{color:#F6F1E4;font-size:13px;line-height:1.4;min-height:54px;margin-bottom:8px}} .cap i{{color:#8B8BA5}}
.phone{{background:linear-gradient(#15151f,#0A0A15 55%);border-radius:28px 28px 0 0;padding:10px 0 18px;overflow:hidden}}
.grab{{width:36px;height:5px;border-radius:3px;background:#3a3a44;margin:0 auto 18px}}
.kicker{{font:400 10px Cinzel;letter-spacing:2.5px;color:#E3BC5B;padding:0 24px}}
.head{{font:400 26px Cinzel;color:#F6F1E4;padding:4px 24px 14px;font-variant:small-caps}}
.row{{display:flex;align-items:center;gap:14px;padding:11px 24px;min-height:52px;box-sizing:border-box;position:relative}}
.row::after{{content:"";position:absolute;left:24px;right:24px;bottom:0;height:1px;background:rgba(227,188,91,.1)}}
.row.lit{{background:rgba(227,188,91,.07)}}
.row.mark{{outline:1px dashed rgba(120,190,255,.45);outline-offset:-3px}}
.g{{width:22px;display:flex;justify-content:center;color:rgba(227,188,91,.6)}} .g svg{{width:16px;height:16px}}
.lit .g,.lit .title{{color:#F3D89A}}
.t{{flex:1;display:flex;flex-direction:column;gap:3px}}
.title{{font:16px GaramondM;color:#F6F1E4}} .detail{{font:13px GaramondMI;color:#8B8BA5;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:290px}}
.caret{{color:rgba(227,188,91,.4)}} .caret svg{{width:10px;height:10px}}
.quick{{font:8px Cinzel;letter-spacing:1.5px;color:#F3D89A}}
.edit{{font:10px Cinzel;letter-spacing:2px;color:#E3BC5B;text-align:center;padding-top:16px}}
.week{{margin-top:18px;display:flex;gap:18px;align-items:center;color:#8B8BA5}}
.day{{display:flex;flex-direction:column;align-items:center;gap:4px;font-size:11px}}
.g24{{color:#E3BC5B}} .g24 svg{{width:24px;height:24px}}
.big{{display:flex;gap:40px;margin:14px 0 4px;align-items:flex-end}}
.big div{{display:flex;flex-direction:column;align-items:center;gap:6px;color:#8B8BA5;font-size:11px}}
.big svg{{width:48px;height:48px;color:#E3BC5B}}
</style></head><body>
<h1>Today's Mysteries · two glyphs for the Pray tray's row</h1>
<p class="lede">The row opens the day's mysteries' page, where the Rosary's forms are chosen. It wears <b>ph-book-open</b>, the same open book as the Spiritual Reading door and the Journal tab (CLAUDE.md lists it as a known clash). Each tray below is drawn at an iPhone's width, as <i>SheetRow</i> draws it: 16pt glyph in the app's gold at 60%, EB Garamond, the app's own spacing. The row in question is marked with a dashed outline.</p>
<div class="big"><div>{glyph('ph-book-open')}now</div><div>{glyph('lv-crown-of-thorns')}A (Tuesday)</div><div>{glyph('lv-star')}A (Monday)</div><div>{glyph('lv-triptych')}B</div></div>
<div class="cols">{''.join(columns)}</div>
<div class="week"><b style="color:#F6F1E4">A through the week (Traditional):</b>{strip}<span>· On Modern, Thursday takes the Jordan and Saturday the star; a Sunday follows the season, as the schedule does.</span></div>
</body></html>"""
    out_html = os.path.join(HERE, "todays-mysteries-candidates.html")
    with open(out_html, "w") as fh:
        fh.write(page)
    subprocess.run([
        CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=2",
        f"--screenshot={os.path.join(HERE, 'todays-mysteries-candidates.png')}", "--window-size=1820,930",
        f"file://{out_html}",
    ], check=True, stderr=subprocess.DEVNULL)
    print(os.path.join(HERE, "todays-mysteries-candidates.png"))


if __name__ == "__main__":
    main()
