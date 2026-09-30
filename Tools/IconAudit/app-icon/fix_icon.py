#!/usr/bin/env python3
"""Mend the app icon's painting (Sept 2026), non-destructively.

The source is original-1024.png beside this script, the icon as it
shipped. Two things are mended and nothing else is touched:

1. The frame. The artwork carried its own rounded rim and dark corners
   inside the square, so on a phone the system's mask drew a second rim
   around the first. The rim and the dark outside it are replaced by the
   painting itself, so the painted ground runs to all four edges: mirrored
   out along the sides, the bottom and the corners (radially at the
   corners, and sheared along the sides so no cloud sits beside its own
   reflection), and carried outward across the top centre, where the
   halo's ring meets the old rim and a mirror doubled it, by
   frequency-selective reconstruction. The foot of the rosary's crucifix,
   which stood on the rim at the bottom, keeps its own tip, and the ground
   beneath it is borrowed from beside it.

2. The Marian monogram. As painted, the M's two diagonals crossed into an
   X beneath the cross, and the cross's stem ran down past the bar into
   the letter. The Miraculous Medal's monogram is an M with a bar through
   it and a cross rising from the bar. So the X's lower legs and the stem
   below the bar are painted out, the burst's rays reconstructed across
   the gaps (the letter's own strokes hidden from the reconstruction, so
   no gold bleeds into the ground), the diagonals end in the M's own
   point, and the bar is carried across the letter using its own painted
   profile, taken from either side, so the cross stands on it. The thin
   inner strokes that rise to the M's two peaks are the letter's own and
   stay; they now meet the cross's foot on the bar.

The crown was counted and left alone: it shows twelve stars (the top one,
five up the left and six down the right, the left's sixth behind the
veil).

    python3 -m venv /tmp/iconenv
    /tmp/iconenv/bin/pip install numpy pillow opencv-contrib-python-headless
    /tmp/iconenv/bin/python Tools/IconAudit/app-icon/fix_icon.py

(The contrib build is the one with cv2.xphoto, the reconstruction.)

Writes the app's icon (Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png)
from the original, the same image every time; make_before_after.py lays the
two out for review.
"""

import math
import os

import cv2
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "original-1024.png")
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "..", "app", "Assets.xcassets",
                                   "AppIcon.appiconset", "AppIcon-1024.png"))

rng = np.random.default_rng(1531)  # Guadalupe; any fixed seed will do


# MARK: - The frame

# The rim's centre line, measured from the source: 21 from the left, 1001.5
# on the right, 8 from the top, 1019.5 at the bottom. A dark shadow runs
# just inside it, so the mirror is taken 10 inside, clear of both.
LEFT, RIGHT, TOP, BOTTOM = 31.5, 990.5, 19.5, 1009.5
INSET = 10.5


def rim_points(lum, centre, angles):
    """The rim's brightest point along rays from a corner's centre."""
    cx, cy = centre
    pts = []
    for a in angles:
        best, bestr = -1, None
        for r in np.arange(150, 290, 0.5):
            x, y = cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a))
            if not (0 <= x < 1023 and 0 <= y < 1023):
                break
            v = cv2.getRectSubPix(lum, (1, 1), (x, y))[0, 0]
            if v > best:
                best, bestr = v, r
        pts.append((cx + bestr * math.cos(math.radians(a)), cy + bestr * math.sin(math.radians(a))))
    return np.array(pts)


def fit_circle(pts):
    x, y = pts[:, 0], pts[:, 1]
    A = np.c_[2 * x, 2 * y, np.ones_like(x)]
    b = x ** 2 + y ** 2
    cx, cy, c = np.linalg.lstsq(A, b, rcond=None)[0]
    return cx, cy, math.sqrt(c + cx ** 2 + cy ** 2)


def corners(lum):
    """Each corner's rim as a circle, fitted to the rim itself."""
    guesses = {
        "tl": ((21 + 228, 8 + 228), range(190, 261, 5)),
        "tr": ((1001.5 - 228, 8 + 228), range(280, 351, 5)),
        "bl": ((21 + 228, 1019.5 - 228), range(100, 171, 5)),
        "br": ((1001.5 - 228, 1019.5 - 228), range(10, 81, 5)),
    }
    fitted = {}
    for name, (centre, angles) in guesses.items():
        fitted[name] = fit_circle(rim_points(lum, centre, angles))
    return fitted


def outside_mask(shape, circles):
    """What lies outside the painting: the straight bands beyond each side,
    and beyond each corner's arc, all taken as far inside the rim."""
    h, w = shape
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    outside = (xs < LEFT) | (xs > RIGHT) | (ys < TOP) | (ys > BOTTOM)
    for name, (cx, cy, r) in circles.items():
        zone = (xs < cx if name[1] == "l" else xs > cx) & (ys < cy if name[0] == "t" else ys > cy)
        rr = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2)
        outside = np.where(zone, rr > r - INSET, outside)
    return outside


def mirrored(img, circles):
    """The painting mirrored out across its edge: straight across each
    side, radially across each corner's arc."""
    h, w = img.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    # A plain mirror sets every cloud on the edge beside its own reflection
    # and reads as an inkblot; sheared as it goes out, the reflection slides
    # along the edge, still meeting the painting exactly at the fold
    k = 0.9
    mapx = np.where(xs < LEFT, 2 * LEFT - xs, np.where(xs > RIGHT, 2 * RIGHT - xs, xs))
    mapy = np.where(ys < TOP, 2 * TOP - ys, np.where(ys > BOTTOM, 2 * BOTTOM - ys, ys))
    mapy = mapy + np.where(xs < LEFT, k * (LEFT - xs), 0) - np.where(xs > RIGHT, k * (xs - RIGHT), 0)
    mapx = mapx - np.where(ys > BOTTOM, k * (ys - BOTTOM), 0)
    for name, (cx, cy, r) in circles.items():
        rb = r - INSET
        zone = (xs < cx if name[1] == "l" else xs > cx) & (ys < cy if name[0] == "t" else ys > cy)
        dx, dy = xs - cx, ys - cy
        rr = np.sqrt(dx ** 2 + dy ** 2) + 1e-6
        scale = np.where(rr > rb, (2 * rb - rr) / rr, 1.0)
        mapx = np.where(zone, cx + dx * scale, mapx)
        mapy = np.where(zone, cy + dy * scale, mapy)
    return cv2.remap(img, mapx.astype(np.float32), mapy.astype(np.float32), cv2.INTER_LINEAR,
                     borderMode=cv2.BORDER_REFLECT)


def fill_frame(img):
    lum = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY).astype(np.float32)
    circles = corners(lum)
    h, w = lum.shape
    outside = outside_mask((h, w), circles)

    # The crucifix's foot stood on the rim: its tip is the painting's own
    tip = np.zeros((h, w), bool)
    tip[int(BOTTOM):1017, 498:527] = img[int(BOTTOM):1017, 498:527].astype(np.float32).mean(axis=2) > 45
    outside &= ~tip

    # Mirrored out across the rim, the sides' clouds and the dark ground
    # keep their grain, and the corners (which the system's mask takes
    # away) are painted ground rather than a flat fill
    filled = np.where(outside[..., None], mirrored(img, circles), img)

    # Across the top the halo's inner ring runs just under the rim, and
    # mirrored it came back as a second arc, every ray folding into a
    # herringbone along the seam. There the ground is carried up by
    # frequency-selective reconstruction instead, which runs the rays on
    # outward, and eased into the mirrored ground on either side
    x0, x1, y1 = 180, 844, 140
    crop = img[:y1, x0:x1].copy()
    known = np.where(outside[:y1, x0:x1], 0, 255).astype(np.uint8)
    healed = np.zeros_like(crop)
    cv2.xphoto.inpaint(crop, known, healed, cv2.xphoto.INPAINT_FSR_BEST)
    ramp = np.clip(np.minimum(np.arange(x1 - x0) - 40, (x1 - x0 - 1 - 40) - np.arange(x1 - x0)) / 60, 0, 1)
    top = outside[:y1, x0:x1][..., None] * ramp[None, :, None]
    filled[:y1, x0:x1] = (filled[:y1, x0:x1] * (1 - top) + healed * top).astype(np.uint8)

    # Beneath the crucifix's foot the ground is the band's own, from
    # either side: mirrored or rebuilt, the foot's gold ran on downward
    x0, x1, gap = 478, 548, 70
    under = np.zeros((h, w), bool)
    under[int(BOTTOM):, x0:x1] = True
    under &= outside
    uy, ux = np.nonzero(under)
    beside = np.where(ux < 513, ux - gap, ux + gap)
    patch = filled.copy()
    patch[uy, ux] = filled[uy, beside]
    fade = cv2.GaussianBlur(under.astype(np.float32), (0, 0), 1.5)[..., None]
    fade = np.maximum(fade, under[..., None].astype(np.float32) * 0.85)
    filled = (filled * (1 - fade) + patch * fade).astype(np.uint8)
    filled[tip] = img[tip]

    # Soften the mirror's fold a hair so it never reads as a line
    soft = cv2.GaussianBlur(filled, (0, 0), 0.6)
    seam = cv2.GaussianBlur(outside.astype(np.float32), (0, 0), 1.2)
    edge = (seam > 0.05) & (seam < 0.95)
    filled[edge] = soft[edge]
    return filled, circles


# MARK: - The monogram

def stroke(shape, pts, half):
    """A painted stroke's footprint, along its measured centre line."""
    m = np.zeros(shape, np.uint8)
    cv2.polylines(m, [np.round(np.array(pts) * 4).astype(np.int32)], False, 255,
                  thickness=int(round(half * 2)), lineType=cv2.LINE_AA, shift=2)
    return m > 96


def mend_monogram(img):
    h, w = img.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    base = img.astype(np.float32)

    # The X's lower legs, traced row by row from the painted strokes:
    # each diagonal carried on past the other and down to a thin tail
    left_leg = [(504, 829), (499.5, 836), (496, 842), (492, 848), (487.5, 854), (480.5, 860),
                (475, 866), (467.5, 872), (458.5, 878), (450, 884), (443, 889)]
    right_leg = [(515, 829), (517.5, 836), (521.5, 842), (525.5, 848), (530, 854), (534.5, 860),
                 (542, 866), (548, 872), (557.5, 878), (566, 884), (573, 889)]
    # Wide enough to take the glow the painter laid about each leg, or a
    # halo of it stays behind and draws the X in outline
    leg_l = stroke((h, w), left_leg, 12) & (ys >= 829)
    leg_r = stroke((h, w), right_leg, 12) & (ys >= 829)
    erase = leg_l | leg_r

    # The diagonals end in the M's own point: from where they meet, the
    # outer edges are drawn in to a tip, as the upper halves already run
    lo = lambda y: 495 + (y - 812) * 0.85
    hi = lambda y: 521 - (y - 812) * 0.75
    tipzone = (ys >= 814) & (ys < 829) & (xs > 486) & (xs < 534)
    erase |= tipzone & ((xs < lo(ys)) | (xs > hi(ys)))

    # The cross's stem below the bar, and the ground about it, inside the V
    a_inner = lambda y: 487 + (y - 770) * 0.53   # the thick diagonals' inner edges
    d_inner = lambda y: 533 - (y - 770) * 0.57
    erase |= (ys >= 763) & (ys <= 806) & (xs > a_inner(ys) + 0.5) & (xs < d_inner(ys) - 0.5)

    # Never the rosary's crucifix just below, nor the M's feet
    erase &= ~((xs > 486) & (xs < 534) & (ys > 866))
    erase &= ys < 894

    mask = cv2.dilate(erase.astype(np.uint8) * 255, np.ones((3, 3), np.uint8))

    # The ground is reconstructed by frequency-selective reconstruction,
    # which carries the burst's fine rays on across a gap where a plain
    # inpaint leaves a smooth dark patch in the shape of what was taken.
    # The letter's own strokes about the gap are hidden from it too, or it
    # takes their gold into the ground; they are put back untouched after.
    # (The rays are gold as well, but thin: an opening that no thin line
    # survives keeps them in, as the ground's own light.)
    B, G, R = base[..., 0], base[..., 1], base[..., 2]
    gold = ((R > 80) & (R - B > 30)).astype(np.uint8) * 255
    gold = cv2.morphologyEx(gold, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)))
    gold = cv2.dilate(gold, np.ones((5, 5), np.uint8))
    near = cv2.dilate(mask, np.ones((41, 41), np.uint8))
    hidden = np.maximum(mask, gold & near)

    x0, y0, x1, y1 = 330, 640, 690, 960          # the work is done on this crop alone
    crop = img[y0:y1, x0:x1].copy()
    known = np.where(hidden[y0:y1, x0:x1] > 0, 0, 255).astype(np.uint8)
    healed = np.zeros_like(crop)
    cv2.xphoto.inpaint(crop, known, healed, cv2.xphoto.INPAINT_FSR_BEST)
    ground = img.copy()
    ground[y0:y1, x0:x1] = healed

    edge = cv2.GaussianBlur(mask.astype(np.float32) / 255, (0, 0), 1.0)[..., None]
    out = img.astype(np.float32) * (1 - edge) + ground.astype(np.float32) * edge

    # The bar, carried across the letter from its own painted rows on
    # either side (the dark line above it, the lit top, the gold body, the
    # shadow under it), passing in front of the diagonals and behind the
    # stems, as it does outside them; the cross now stands on it
    y0, y1 = 749, 769
    left = np.median(base[y0:y1, 385:426], axis=1)
    right = np.median(base[y0:y1, 596:636], axis=1)
    alpha = np.ones(y1 - y0, np.float32)
    alpha[0], alpha[-1] = 0.45, 0.45
    for x in range(448, 568):
        t = (x - 448) / (567 - 448)
        colour = left * (1 - t) + right * t
        grain = rng.normal(0, 1, (y1 - y0, 1)).astype(np.float32) * 3.0
        out[y0:y1, x] = out[y0:y1, x] * (1 - alpha[:, None]) + (colour + grain) * alpha[:, None]
    return np.clip(out, 0, 255).astype(np.uint8), mask


def main():
    img = cv2.imread(SRC)
    framed, circles = fill_frame(img)
    mended, _ = mend_monogram(framed)
    cv2.imwrite(OUT, mended)
    for name, (cx, cy, r) in circles.items():
        print(f"{name}: centre ({cx:.1f}, {cy:.1f}) radius {r:.1f}")
    print(OUT)


if __name__ == "__main__":
    main()
