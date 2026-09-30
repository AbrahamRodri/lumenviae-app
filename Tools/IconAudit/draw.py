#!/usr/bin/env python3
"""The lv-* glyphs drawn for the icon audit (Sept 2026).

Each glyph is written as an SVG on a 24x24 viewBox, stroked at 1.5 with
round caps and joins, to sit beside the ch-* glyphs (Christicons, 1.5).
Small solid dots (beads, stars in a crown) are filled circles; nothing
else is filled. Every glyph renders as a template through AppIcon, so
the colour here is only a placeholder.

    python3 Tools/IconAudit/draw.py            # every glyph, into the asset catalog
    python3 Tools/IconAudit/draw.py lv-rose    # just the one
    python3 Tools/IconAudit/draw.py --candidates  # glyphs under review, to candidates/

Edit a glyph here and rerun; never hand-edit the installed SVG.
"""

import json
import math
import re
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ICONS = os.path.join(HERE, "..", "..", "app", "Assets.xcassets", "Icons")

STROKE = 'stroke="#000000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"'


def f(x):
    """A coordinate, trimmed: 12.0 -> 12, 3.456 -> 3.46."""
    s = f"{x:.2f}".rstrip("0").rstrip(".")
    return "0" if s == "-0" else s


def svg(*parts):
    body = "\n  ".join(parts)
    return (
        '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" '
        'xmlns="http://www.w3.org/2000/svg">\n  ' + body + "\n</svg>\n"
    )


def path(d):
    return f'<path d="{d}" {STROKE}/>'


def dot(x, y, r):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="#000000"/>'


def ring(x, y, r):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" {STROKE}/>'


def arc_points(cx, cy, r, a0, a1, n):
    """Points on a circle from angle a0 to a1 (degrees, 0 = east, y down)."""
    return [
        (cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / (n - 1))),
         cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / (n - 1))))
        for i in range(n)
    ]


def arc_d(cx, cy, r, a0, a1):
    """An SVG arc from angle a0 to a1, drawn clockwise (y down)."""
    x0, y0 = cx + r * math.cos(math.radians(a0)), cy + r * math.sin(math.radians(a0))
    x1, y1 = cx + r * math.cos(math.radians(a1)), cy + r * math.sin(math.radians(a1))
    large = 1 if ((a1 - a0) % 360) > 180 else 0
    return f"M{f(x0)} {f(y0)}A{f(r)} {f(r)} 0 {large} 1 {f(x1)} {f(y1)}"


def transformed(d, scale, dx, dy):
    """An absolute M/L/C path, scaled and moved: used to set a Christicons
    drawing (the dove, the star) inside a composition of our own."""
    nums = re.findall(r"-?\d*\.?\d+", d)
    cmds = re.findall(r"[MLC]", d)
    assert not re.search(r"[HVSQTAZhvsqtaz]", d), "only absolute M, L and C"
    out, i = [], 0
    for token in re.findall(r"[MLC][^MLC]*", d):
        pairs = len(re.findall(r"-?\d*\.?\d+", token[1:])) // 2
        coords = []
        for _ in range(pairs):
            x, y = float(nums[i]), float(nums[i + 1])
            coords.append(f"{f(x * scale + dx)} {f(y * scale + dy)}")
            i += 2
        out.append(token[0] + " ".join(coords))
    return "".join(out)


CI_DOVE = ("M21.3719 15.6309C20.2684 16.956 18.8367 17.9393 17.2334 18.473C15.6301 19.0067 13.917 19.0704 12.2814 18.6571"
           "C10.6457 18.2438 9.15055 17.3694 7.95934 16.1295C6.76812 14.8896 5.92673 13.332 5.52719 11.627"
           "M21.2184 15.6492C19.954 15.9891 18.6333 16.0659 17.338 15.8749C16.0427 15.6839 14.8003 15.2292 13.6877 14.539"
           "M9.10234 10.4595C10.1705 8.26299 12.0379 6.55788 14.3223 5.69336C16.6066 4.82884 19.1351 4.87032 21.3899 5.80932"
           "M17.0459 10.7604C17.0589 11.692 16.7246 12.595 16.1082 13.2936C15.4918 13.9922 14.6374 14.4363 13.7115 14.5395"
           "M17.0539 10.76C17.0185 10.0973 17.1067 9.43344 17.3124 8.81304C17.5181 8.19263 17.8367 7.62996 18.2468 7.16271"
           "C18.6569 6.69546 19.149 6.33442 19.6902 6.10377C20.2315 5.87312 20.8093 5.77819 21.385 5.82533"
           "M2.61014 9.67504C3.25471 9.54767 3.92316 9.68176 4.47004 10.0481C5.01691 10.4145 5.39796 10.9836 5.53027 11.6314"
           "M2.61548 9.66784C2.80683 9.18255 3.11992 8.75471 3.5246 8.42553C3.92927 8.09635 4.41189 7.87692 4.92597 7.78838"
           "C5.44005 7.69983 5.96827 7.74516 6.45976 7.91998C6.95124 8.09481 7.38942 8.39325 7.7321 8.78656"
           "M7.72977 8.78461L9.07743 10.4877")

# Christicons' star, its four short diagonal rays left off: with them it
# read at 16pt as the sparkle it replaces
CI_STAR = ("M14.0578 7.88444L12 2.73999L9.94225 7.88444L4.79779 9.94228"
           "L9.94225 12L12 21.26L14.0578 12L19.2023 9.94228L14.0578 7.88444")

WAVES_HIGH = ("M3.5 17.4C5 16.3 6.5 16.3 8 17.4C9.5 18.5 11 18.5 12.5 17.4"
              "C14 16.3 15.5 16.3 17 17.4C18.1 18.2 19.3 18.4 20.5 17.8")
WAVES_LOW = ("M6.5 20.9C8 19.8 9.5 19.8 11 20.9C12.5 22 14 22 15.5 20.9"
             "C16.4 20.2 17.3 20 18.2 20.2")


# MARK: - The Rosary

def rosary():
    """The loop of beads, the centre medal, one bead of the pendant and
    the crucifix. The loop narrows to the medal, as a rosary hangs, and is
    drawn as beads rather than a line: a ring over a cross is the sign
    for "female", and ch-rosary read as that at 16pt."""
    parts = []

    def loop(t):
        # A drop: full width at the shoulders, drawn in to the medal
        w = 6.7 * math.sin(t) * (0.78 + 0.22 * math.cos(t))
        return 12 + w, 8.1 - 6.0 * math.cos(t)

    # Sample the loop finely, then set beads at equal arc length,
    # leaving the medal its own room at the foot
    samples = [loop(math.pi * 0.2 + (math.pi * 1.6) * i / 2000) for i in range(2001)]
    lengths = [0.0]
    for (x0, y0), (x1, y1) in zip(samples, samples[1:]):
        lengths.append(lengths[-1] + math.hypot(x1 - x0, y1 - y0))
    total = lengths[-1]
    beads = 11
    for k in range(beads):
        target = total * k / (beads - 1)
        i = min(range(len(lengths)), key=lambda j: abs(lengths[j] - target))
        parts.append(dot(*samples[i], 1.05))

    parts.append(ring(12, 15.0, 1.25))          # the centre medal
    parts.append(dot(12, 18.0, 1.05))          # the pendant's bead
    parts.append(path("M12 19.9V23M10.4 21.1H13.6"))  # the crucifix
    return svg(*parts)


# MARK: - The Sorrowful Mysteries

def crown_of_thorns():
    """A plaited ring seen a little from above, as the Arma Christi draw
    it, with thorns standing out from it. The old glyph was a ring with
    eight spokes, and read as a sun or a gear."""
    cx, cy, rx, ry = 12, 12.4, 8.4, 4.6
    parts = []
    for phase in (0, math.pi):
        pts = []
        for i in range(0, 145):
            t = 2 * math.pi * i / 144
            k = 0.9 * math.sin(5 * t + phase)
            pts.append((cx + (rx + k) * math.cos(t), cy + (ry + k * 0.8) * math.sin(t)))
        parts.append(path("M" + " L".join(f"{f(x)} {f(y)}" for x, y in pts) + "Z"))
    thorns = []
    for deg, lean in ((205, -30), (250, -20), (292, 20), (335, 30), (40, 25), (140, -25)):
        t = math.radians(deg)
        x, y = cx + (rx + 0.6) * math.cos(t), cy + (ry + 0.6) * math.sin(t)
        nx, ny = math.cos(t) / rx, math.sin(t) / ry
        n = math.hypot(nx, ny)
        a = math.atan2(ny / n, nx / n) + math.radians(lean)
        thorns.append(f"M{f(x)} {f(y)}L{f(x + 2.3 * math.cos(a))} {f(y + 2.3 * math.sin(a))}")
    parts.append(path("".join(thorns)))
    return svg(*parts)


# MARK: - The Seven Sorrows

HEART = ("M11 8.6C9.9 7.1 8.7 6.3 7.2 6.3C4.8 6.3 3 8.2 3 10.7"
         "C3 14.8 7.9 18.3 11 20.3C14.1 18.3 19 14.8 19 10.7"
         "C19 8.2 17.2 6.3 14.8 6.3C13.3 6.3 12.1 7.1 11 8.6Z")


def pierced_heart():
    """Our Lady's heart pierced by Simeon's sword (Lk 2:35), stroked like
    every glyph beside it. The old one was a solid heart, the only filled
    devotional glyph on the page, and stood heavier than the rest."""
    return svg(
        path(HEART),
        # The sword: pommel, grip, cross-guard and a blade through the heart
        path("M21.4 2.6L19.7 4.3M18.3 2.9L21.1 5.7M19.7 4.3L5.3 18.7"),
    )


# MARK: - The Hours of the Prayer Book

def rooster():
    """The cock of Lauds: Ambrose's Aeterne rerum Conditor, sung at
    morning, is about its crowing ("gallo canente spes redit"), and
    Prudentius's Ales diei nuntius hails it as the herald of the day."""
    return svg(
        # Comb and head, beak, wattle
        path("M13.9 5.2C13.6 3.9 14.7 3.1 15.5 3.9C15.9 3 17.3 3.1 17.3 4.3"
             "C18.2 4.1 18.8 5.1 18.1 5.8"),
        path("M18.1 5.8L20.3 7.1L18.2 7.8"),
        path("M17.6 8.2C17.9 9.2 17.5 10 16.8 10"),
        # Neck, breast and belly, round to the tail
        path("M18.2 7.8C18.2 9.6 18.8 11.6 18.3 13.4C17.6 15.7 15.3 16.9 12.6 16.9"
             "C10.4 16.9 8.4 16 6.8 14.4"),
        # Head and back, down into the tail
        path("M13.9 5.2C12.9 6.2 13 8.2 13.6 9.8C12.8 10.8 11.4 11.1 10.1 10.7"),
        # The sickle feathers of the tail
        path("M10.1 10.7C8.6 7.5 6.2 5.6 3.6 5.4C3.4 8.9 4.6 12.4 6.8 14.4"),
        path("M9.8 13.4C8.7 11.3 7.2 10 5.5 9.5"),
        # Legs and feet
        path("M11.7 16.9L11.2 20.6M14.3 16.7L14.8 20.6M9.7 20.6H12.3M13.7 20.6H16.3"),
    )


def lamp():
    """The lamp lit at evening: Vespers was the lucernarium, the lighting
    of the lamps, and its psalm the evening sacrifice of Ps 140. The
    Prayer Book's Night Prayers are its Preces Vespertinæ."""
    return svg(
        # A clay lamp: round body, the nozzle drawn out to the right
        path("M3.5 15.6C3.5 13.6 6.1 12.3 9.4 12.3C11.6 12.3 13.4 12.8 14.7 13.6"
             "L17.8 13.6C19 13.6 19.3 15.2 18.2 15.7L15.1 17"
             "C13.8 18 11.8 18.8 9.4 18.8C6.1 18.8 3.5 17.6 3.5 15.6Z"),
        # The filling hole, and the foot
        path("M7.9 15.1H10.9"),
        path("M7.2 18.6L6.9 20.3H11.9L11.6 18.6"),
        # The flame, standing up from the nozzle
        path("M17.9 11.6C16.5 10.4 16.5 8.2 18.1 5.6C19.7 8.2 19.7 10.4 18.3 11.6Z"),
    )


def bell():
    """A church bell hung from its yoke: the Angelus bell, which medieval
    founders cast in Gabriel's name. The yoke is what keeps it from being
    read as a notification's bell, which the Daily Reminders row wears."""
    return svg(
        path("M5.5 3.3H18.5M12 3.3V5.2"),
        path("M8.5 8.5C8.5 6.6 10 5.2 12 5.2C14 5.2 15.5 6.6 15.5 8.5"
             "C15.5 12 16 14.3 17.6 16C18.4 16.8 19 17.4 19.3 18.2H4.7"
             "C5 17.4 5.6 16.8 6.4 16C8 14.3 8.5 12 8.5 8.5Z"),
        ring(12, 20.3, 1.1),
    )


# MARK: - The Glorious and Luminous Mysteries

def banner():
    """The Resurrection banner, the vexillum the risen Christ carries: a
    staff and a swallow-tailed pennant bearing the cross."""
    return svg(
        path("M6.2 21.5V2.8"),
        path("M6.2 4.6H19.4L16.6 8.6L19.4 12.6H6.2"),
        path("M11.9 6.5V10.7M9.8 8.6H14"),
    )


def jordan():
    """The dove over the waters of the Jordan: the Baptism of the Lord,
    the first of the Mysteries of Light. The dove is the one the Holy
    Ghost's chapter wears (ch-dove), made smaller and set over the river,
    so the two read as one sign."""
    return svg(
        path(transformed(CI_DOVE, 0.74, 3.1, -0.4)),
        path(WAVES_HIGH),
        path(WAVES_LOW),
    )


# MARK: - Our Lady

def star():
    """The Star of Bethlehem, for the Joyful Mysteries: Christicons' star
    with its long lower ray, the four short rays left off."""
    return svg(path(CI_STAR + "Z"))


def wheat():
    """An ear of wheat: the seed that fell on good ground and brought
    forth a hundredfold (Mt 13:8), and the fruits of a devotion."""
    grains = []
    for i, y in enumerate((14.2, 10.9, 7.6)):
        grains.append(f"M12 {f(y + 2.2)}C10.1 {f(y + 1.9)} 9.1 {f(y + 0.4)} 9.2 {f(y - 1.6)}"
                      f"C10.9 {f(y - 1.3)} 11.9 {f(y)} 12 {f(y + 2.2)}")
        grains.append(f"M12 {f(y + 2.2)}C13.9 {f(y + 1.9)} 14.9 {f(y + 0.4)} 14.8 {f(y - 1.6)}"
                      f"C13.1 {f(y - 1.3)} 12.1 {f(y)} 12 {f(y + 2.2)}")
    return svg(
        path("M12 21.5V9.8"),
        path("".join(grains)),
        path("M12 6.6C11 5.6 11 4 12 2.5C13 4 13 5.6 12 6.6Z"),
    )


def stella_maris():
    """Stella Maris, the Star of the Sea: the oldest of Our Lady's titles
    and the hymn Ave maris stella. The Joyful Mysteries' star (ch-star),
    set over the waves."""
    return svg(
        path(transformed(CI_STAR, 0.66, 4.08, -0.9)),
        path(WAVES_HIGH),
        path(WAVES_LOW),
    )


def twelve_stars():
    """The crown of twelve stars (Apoc 12:1), the Woman's crown: the
    image the Church gives the Immaculate Conception and the Assumption,
    for the shelf of the four Marian dogmas."""
    parts = []
    for x, y in arc_points(12, 12, 8.2, -90, 240, 12):
        # A small four-rayed star at each place
        parts.append(path(f"M{f(x)} {f(y - 1.35)}V{f(y + 1.35)}M{f(x - 1.35)} {f(y)}H{f(x + 1.35)}"))
    return svg(*parts)


def rose():
    """The rose Our Lady wore and gave at her appearings (the roses of
    Guadalupe, the golden roses at her feet at Lourdes) and the Rosa
    mystica of her litany: for the shelf of the approved apparitions.
    Drawn as a bud wrapped in two petals: open, it read as a tulip, and
    face-on as any flower."""
    return svg(
        path("M12 2.8C14.2 3.2 15.2 5.4 14.7 7.6C14.4 9.2 13.2 10.2 12 10.2"
             "C10.8 10.2 9.6 9.2 9.3 7.6C8.8 5.4 9.8 3.2 12 2.8Z"),
        path("M9.4 6C7 6.7 6 9.2 7.1 11.3C8.1 13.2 9.9 13.9 12 13.9"
             "C14.1 13.9 15.9 13.2 16.9 11.3C18 9.2 17 6.7 14.6 6"),
        path("M10.2 5.9C11 5 12.8 5 13.7 6.1"),
        path("M12 13.9V21.4"),
        path("M12 18C10.7 16.1 8.6 15.3 6 15.7C6.9 18 9.1 19.1 12 18.6"),
    )


# MARK: - Angels and Saints

def saint():
    """A saint: head and shoulders under a halo. The generic "user" glyph
    stood for the saints until now, an account avatar. The halo is drawn
    as the ring over the head that everyone reads as a saint's; drawn as
    a disc behind the head, at 16pt it read as headphones."""
    return svg(
        path("M8.3 5C8.3 4.1 10 3.4 12 3.4C14 3.4 15.7 4.1 15.7 5C15.7 5.9 14 6.6 12 6.6C10 6.6 8.3 5.9 8.3 5Z"),
        ring(12, 11.1, 2.8),
        path("M5.2 21.2C5.4 17.9 8.3 16 12 16C15.7 16 18.6 17.9 18.8 21.2"),
    )


# MARK: - The Prayer Book's chapters

def response():
    """℟, the response: a litany is "titles called out one after another,
    and a response to every one", and the Prayer Book prints that
    response as ℟ in rubric red. The list glyph it wore is the ☰ menu."""
    return svg(
        path("M8 20.5V3.5H12.6C15.1 3.5 16.8 5.2 16.8 7.6C16.8 10 15.1 11.7 12.6 11.7H8"),
        path("M12.1 11.7L17.3 20.5"),
        path("M11.6 18.7L18.8 13.9"),
    )


def procession_cross():
    """The processional cross: the Litanies were first the Church's
    prayers in procession (the Greater Litany of St Mark's day, the
    Rogation Days), sung walking behind it. A cross on a long staff, with
    the knop the bearer's hands take."""
    return svg(
        path("M12 2.6V21.4"),
        path("M8.6 6H15.4"),
        ring(12, 13.2, 1.15),
        path("M9.8 21.4H14.2"),
    )


def hourglass():
    """An hourglass: Through the Day (Per Diem), the prayers of the day's
    hours, on rising, at table, at evening and at its end. Its sands mark
    time passing, not a duration: nothing is counted."""
    return svg(
        path("M6.5 3.2H17.5M6.5 20.8H17.5"),
        path("M8 3.2C8 7.6 10.2 9.6 12 12C13.8 9.6 16 7.6 16 3.2"),
        path("M8 20.8C8 16.4 10.2 14.4 12 12C13.8 14.4 16 16.4 16 20.8"),
        path("M9.8 18.6C10.6 17.4 11.3 16.8 12 16.8C12.7 16.8 13.4 17.4 14.2 18.6Z"),
    )


def dart():
    """A dart, fletched: the Short Prayers are the iaculatoriæ, prayers
    "darted out" (Augustine, Ep. 130, of the monks of Egypt), which is
    where the Latin name comes from."""
    return svg(
        # The shaft and a closed head
        path("M5.6 18.4L16.4 7.6"),
        path("M20.3 3.7L14.9 5.3L18.7 9.1Z"),
        # Two vanes of feather, swept back from the shaft's end
        path("M5.6 18.4L3.4 17.8L3.8 15.3L6.9 17.1"),
        path("M5.6 18.4L6.2 20.6L8.7 20.2L6.9 17.1"),
    )


def dial():
    """A church's scratch dial, the half-wheel cut into a south wall to
    mark the hours of prayer through the day: for the chapter Through the
    Day (Per Diem). Its lines run down from the gnomon's hole."""
    parts = [ring(12, 5.2, 1.0)]
    parts.append(path(arc_d(12, 5.2, 14.8, 0, 180).replace("A14.8 14.8", "A14.8 14.8")))
    return svg(*parts)


def dial_v2():
    cx, cy, r = 12, 6.2, 13.2
    spokes = []
    for deg in (180, 150, 120, 90, 60, 30, 0):
        a = math.radians(deg)
        x0, y0 = cx + 2.1 * math.cos(a), cy + 2.1 * math.sin(a)
        x1, y1 = cx + (r - 0.0) * math.cos(a), cy + (r - 0.0) * math.sin(a)
    # A half-wheel below the hole: the rim, and the hour lines within it
    rim = arc_d(cx, cy, 8.6, 0, 180)
    lines = []
    for deg in (30, 60, 90, 120, 150):
        a = math.radians(deg)
        lines.append(f"M{f(cx + 2.2 * math.cos(a))} {f(cy + 2.2 * math.sin(a))}"
                     f"L{f(cx + 8.6 * math.cos(a))} {f(cy + 8.6 * math.sin(a))}")
    return svg(
        ring(cx, cy, 1.0),
        path(f"M{f(cx - 8.6)} {f(cy)}H{f(cx + 8.6)}"),
        path(rim),
        path("".join(lines)),
    )


def neume():
    """Square notation on a four-line staff: a punctum and a podatus, the
    notes Gregorian chant is written in. The Chant Library wore the
    modern eighth note."""
    ys = (6, 10, 14, 18)
    staff = "".join(f"M3 {y}H21" for y in ys)
    return (
        '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" '
        'xmlns="http://www.w3.org/2000/svg">\n'
        f'  <path d="{staff}" stroke="#000000" stroke-width="0.9" stroke-linecap="round"/>\n'
        '  <path d="M6 12.2H9V15.8H6Z" fill="#000000"/>\n'
        '  <path d="M12.5 12.2H15.5V15.8H12.5ZM12.5 4.2H15.5V7.8H12.5Z" fill="#000000"/>\n'
        '  <path d="M15.5 6V14" stroke="#000000" stroke-width="1.5" stroke-linecap="round"/>\n'
        '</svg>\n'
    )


def wreath():
    """A wreath of laurel, open at the top: the crown of life promised to
    the faithful (Apoc 2:10, Jas 1:12), for a year of daily prayer."""
    parts = [path(arc_d(12, 12, 8.2, 118, 250)), path(arc_d(12, 12, 8.2, 290, 422))]
    leaves = []
    for side in (-1, 1):
        for deg in (132, 162, 192, 222):
            t = math.radians(deg if side < 0 else 180 - deg)
            x, y = 12 + 8.2 * math.cos(t), 12 + 8.2 * math.sin(t)
            # A leaf leaning outward and up from the branch
            ox, oy = math.cos(t), math.sin(t)
            tx, ty = -math.sin(t) * side * -1, math.cos(t) * side * -1
            lx, ly = x + ox * 2.4 + tx * 1.3, y + oy * 2.4 + ty * 1.3
            leaves.append(f"M{f(x)} {f(y)}L{f(lx)} {f(ly)}")
    parts.append(path("".join(leaves)))
    return svg(*parts)


def lozenge():
    """The diamond stud of the app's ornament rule (OrnamentDivider), for
    the places that set an ornament beside a word rather than a sign."""
    return (
        '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" '
        'xmlns="http://www.w3.org/2000/svg">\n'
        '  <path d="M12 6.5L17.5 12L12 17.5L6.5 12Z" fill="#000000"/>\n'
        '</svg>\n'
    )


def triptych():
    """An altarpiece of three lancet panels on a base, the centre one
    taller: the mysteries as they were painted for the Rosary's altars,
    and as the mysteries' page lays them out. A candidate for Today's
    Mysteries, not chosen: the row wears the day's own emblem instead."""
    return svg(
        path("M3.6 19V12.8C3.6 11.3 4.5 10.1 6 9.2C7.5 10.1 8.4 11.3 8.4 12.8V19Z"),
        path("M9.6 19V9C9.6 7.1 10.6 5.7 12 4.5C13.4 5.7 14.4 7.1 14.4 9V19Z"),
        path("M15.6 19V12.8C15.6 11.3 16.5 10.1 18 9.2C19.5 10.1 20.4 11.3 20.4 12.8V19Z"),
        path("M2.6 21.2H21.4"),
    )


# Drawn for review and not installed until one is chosen
CANDIDATES = {
    "lv-triptych": triptych,
}


GLYPHS = {
    "lv-rosary": rosary,
    "lv-crown-of-thorns": crown_of_thorns,
    "lv-pierced-heart": pierced_heart,
    "lv-rooster": rooster,
    "lv-lamp": lamp,
    "lv-bell": bell,
    "lv-banner": banner,
    "lv-jordan": jordan,
    "lv-star": star,
    "lv-wheat": wheat,
    "lv-stella-maris": stella_maris,
    "lv-twelve-stars": twelve_stars,
    "lv-rose": rose,
    "lv-saint": saint,
    "lv-procession-cross": procession_cross,
    "lv-dart": dart,
    "lv-hourglass": hourglass,
    "lv-lozenge": lozenge,
}


def install(name, text):
    folder = os.path.join(ICONS, f"{name}.imageset")
    os.makedirs(folder, exist_ok=True)
    for old in os.listdir(folder):
        if old.endswith(".svg"):
            os.remove(os.path.join(folder, old))
    with open(os.path.join(folder, f"{name}.svg"), "w") as fh:
        fh.write(text)
    contents = {
        "images": [{"filename": f"{name}.svg", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {
            "preserves-vector-representation": True,
            "template-rendering-intent": "template",
        },
    }
    with open(os.path.join(folder, "Contents.json"), "w") as fh:
        json.dump(contents, fh, indent=2)
        fh.write("\n")


def main():
    if "--candidates" in sys.argv:
        folder = os.path.join(HERE, "candidates")
        os.makedirs(folder, exist_ok=True)
        for name, draw in CANDIDATES.items():
            with open(os.path.join(folder, f"{name}.svg"), "w") as fh:
                fh.write(draw())
        print(f"{len(CANDIDATES)} candidates")
        return
    only = sys.argv[1:]
    for name, draw in GLYPHS.items():
        if not only or name in only:
            install(name, draw())
    print(f"{len(only) or len(GLYPHS)} glyphs")


if __name__ == "__main__":
    main()
