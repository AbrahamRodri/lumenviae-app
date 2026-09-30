#!/usr/bin/env python3
"""The app icon's before and after, for review.

    /tmp/iconenv/bin/python Tools/IconAudit/app-icon/make_before_after.py

Lays out original-1024.png beside the app's icon as fix_icon.py writes
it: the full art, the icon under the system's rounded mask at 180 and
60 points on a dark and a light home screen, the monogram at 3×, the
crown with its twelve stars numbered, and the edges where the frame was.
Writes Tools/IconAudit/app-icon-before-after.png through headless Chrome.
"""

import os
import subprocess
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "app-icon-before-after.png"))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# The crown's stars, left side up, the top, then the right side down
STARS = [(252, 375), (258, 282), (295, 200), (342, 139), (412, 100), (508, 78),
         (608, 100), (676, 140), (722, 202), (755, 285), (757, 375), (732, 465)]


def main():
    before = Image.open(os.path.join(HERE, "original-1024.png")).convert("RGB")
    after = Image.open(os.path.join(HERE, "..", "..", "..", "app", "Assets.xcassets",
                                    "AppIcon.appiconset", "AppIcon-1024.png")).convert("RGB")
    tmp = tempfile.mkdtemp()

    def save(img, name):
        path = os.path.join(tmp, name)
        img.save(path)
        return f"file://{path}"

    files = {}
    for tag, img in (("before", before), ("after", after)):
        files[f"{tag}-full"] = save(img, f"{tag}-full.png")
        for size in (180, 60):
            files[f"{tag}-{size}"] = save(img.resize((size, size), Image.LANCZOS), f"{tag}-{size}.png")
        files[f"{tag}-mono"] = save(img.crop((380, 590, 640, 900)).resize((780, 930), Image.LANCZOS), f"{tag}-mono.png")
        for key, box in (("top", (330, 0, 700, 60)), ("corner", (0, 0, 190, 190)), ("foot", (440, 960, 590, 1024))):
            scale = 2
            w, h = box[2] - box[0], box[3] - box[1]
            files[f"{tag}-{key}"] = save(img.crop(box).resize((w * scale, h * scale), Image.LANCZOS), f"{tag}-{key}.png")

    # The crown, numbered, and a check that its pixels were not touched
    crown_box = (220, 45, 800, 505)
    same = np.array_equal(np.asarray(before.crop(crown_box)), np.asarray(after.crop(crown_box)))
    crown = after.crop(crown_box).resize(((crown_box[2] - crown_box[0]) * 2, (crown_box[3] - crown_box[1]) * 2), Image.LANCZOS)
    d = ImageDraw.Draw(crown)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    for i, (x, y) in enumerate(STARS, 1):
        cx, cy = (x - crown_box[0]) * 2, (y - crown_box[1]) * 2
        d.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), outline=(90, 190, 255), width=3)
        d.text((cx + 26, cy - 30), str(i), fill=(90, 190, 255), font=font)
    files["crown"] = save(crown, "crown.png")

    def pair(key, note=""):
        return (f'<div class="pair"><figure><img src="{files["before-" + key]}"><figcaption>Before</figcaption></figure>'
                f'<figure><img src="{files["after-" + key]}"><figcaption>After{note}</figcaption></figure></div>')

    def homes(tag):
        cells = []
        for ground in ("dark", "light"):
            cells.append(f'<div class="home {ground}"><img class="i180" src="{files[tag + "-180"]}">'
                         f'<img class="i60" src="{files[tag + "-60"]}"></div>')
        return f'<figure>{"".join(cells)}<figcaption>{tag.capitalize()}</figcaption></figure>'

    crown_note = ("identical pixels before and after" if same else "CHANGED — check")
    page = f"""<!doctype html><html><head><meta charset="utf-8"><style>
body{{background:#0A0A15;color:#F6F1E4;font:15px -apple-system,sans-serif;margin:0;padding:32px 40px;width:2130px}}
h1{{font:600 30px Georgia,serif;color:#E3BC5B;letter-spacing:.05em;margin:0 0 8px}}
h2{{font:600 17px Georgia,serif;color:#E3BC5B;letter-spacing:.14em;text-transform:uppercase;margin:34px 0 12px;
   padding-bottom:8px;border-bottom:1px solid rgba(227,188,91,.24)}}
p{{color:#B9B9CC;line-height:1.5;max-width:2000px;margin:6px 0}} b{{color:#F6F1E4}}
.pair{{display:flex;gap:30px;align-items:flex-start}}
figure{{margin:0}} figcaption{{color:#8B8BA5;font-size:14px;margin-top:6px}}
.full img{{width:1024px;height:1024px;display:block}}
.homes{{display:flex;gap:40px}}
.home{{display:inline-flex;gap:40px;align-items:center;padding:30px 40px;border-radius:18px;margin-right:16px}}
.home.dark{{background:linear-gradient(135deg,#1d2433,#0e1118)}} .home.light{{background:linear-gradient(135deg,#dfe3ea,#b9c1cc)}}
.i180{{width:180px;height:180px}} .i60{{width:60px;height:60px}}
.i180,.i60{{border-radius:22.37%;corner-shape:squircle;box-shadow:0 2px 10px rgba(0,0,0,.35)}}
.crown img{{display:block}}
</style></head><body>
<h1>The app icon · before and after</h1>
<p><b>The frame.</b> The painting carried its own rounded rim and dark corners, so on a phone the system's mask drew a second rim around the first. The rim and the dark outside it are gone. The painting runs to all four edges: mirrored out along the sides, bottom and corners (sheared a little, so no cloud sits beside its own reflection), and carried outward across the top centre, where the halo's ring meets the old rim, by a reconstruction that runs its rays on. The crucifix's foot keeps its own tip.</p>
<p><b>The monogram.</b> The M's diagonals crossed into an X beneath the cross, and the cross's stem ran down past the bar into the letter. The X's lower legs and the stem below the bar are painted out: the burst's rays are reconstructed across the gaps. The diagonals now end in the M's own point, and the bar is carried across the letter from its own painted profile on either side, so the cross stands on it, as on the Miraculous Medal. Every stroke still in the letter is the painting's own gold.</p>
<p><b>The crown.</b> Counted and left alone: it shows twelve stars (numbered below: five up the left, the top, six down the right; the left's sixth is behind the veil). My earlier note to "count it to twelve" was an estimate I had not checked. The Virgin, the palette and the composition are untouched.</p>

<h2>The full art, 1024 × 1024</h2>
<div class="pair full"><figure><img src="{files['before-full']}"><figcaption>Before</figcaption></figure><figure><img src="{files['after-full']}"><figcaption>After</figcaption></figure></div>

<h2>On a home screen, under the system's mask, at 180 and 60</h2>
<div class="homes">{homes('before')}{homes('after')}</div>

<h2>The monogram at 3×</h2>
{pair('mono')}

<h2>The crown at 2×, its stars numbered · {crown_note}</h2>
<div class="crown"><img src="{files['crown']}"></div>

<h2>Where the frame was, at 2×: the top centre, the top-left corner, the crucifix's foot</h2>
{pair('top')}
<div style="height:18px"></div>
<div class="pair"><figure><img src="{files['before-corner']}"><figcaption>Before</figcaption></figure><figure><img src="{files['after-corner']}"><figcaption>After (the system's mask takes this corner away on a phone)</figcaption></figure>
<figure><img src="{files['before-foot']}"><figcaption>Before</figcaption></figure><figure><img src="{files['after-foot']}"><figcaption>After</figcaption></figure></div>
</body></html>"""
    html_path = os.path.join(tmp, "sheet.html")
    with open(html_path, "w") as fh:
        fh.write(page)
    height = 4400
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    f"--screenshot={OUT}", f"--window-size=2210,{height}", f"file://{html_path}"],
                   check=True, stderr=subprocess.DEVNULL)
    print(OUT, "crown", crown_note)


if __name__ == "__main__":
    main()
