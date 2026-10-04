"""Marker-pen labels for the cartons: what's in the box, in a hurried hand.

Black marker on transparent card, one PNG per label, read by PropKit.cardboard.
Run from the project root:  python scripts/make_prop_labels.py
"""

from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "textures", "props")
KAI = os.path.join(ROOT, "tools", "fonts", "src", "LXGWWenKaiTC-Regular.ttf")
FONT = KAI if os.path.exists(KAI) else os.path.join(ROOT, "assets", "fonts", "NotoSerifTC.ttf")

# (file, text, a second line or ""): clothes, bowls and dishes, books, odds and ends
LABELS = [
    ("carton_label_1", "衣服", "冬"),
    ("carton_label_2", "碗碟", "小心"),
    ("carton_label_3", "書", ""),
    ("carton_label_4", "雜物", "陳"),
]

W, H = 384, 256


def main() -> None:
    rng = np.random.default_rng(7)
    for name, text, second in LABELS:
        im = Image.new("L", (W * 2, H * 2), 0)
        d = ImageDraw.Draw(im)
        font = ImageFont.truetype(FONT, 230 if len(text) < 2 else 190)
        d.text((W * 0.95, H * 0.85), text, font=font, fill=255, anchor="mm", stroke_width=9, stroke_fill=255)
        if second:
            small = ImageFont.truetype(FONT, 110)
            d.text((W * 1.62, H * 1.6), second, font=small, fill=255, anchor="mm", stroke_width=5, stroke_fill=255)
        # an underline, quick and a little uphill
        d.line([(W * 0.3, H * 1.42), (W * 1.3, H * 1.34)], fill=255, width=14)
        im = im.rotate(float(rng.uniform(-6, 6)), resample=Image.BICUBIC, center=(W, H))
        im = im.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.6))
        a = np.asarray(im, np.float32) / 255
        # marker soaks into card unevenly
        a *= 0.82 + 0.18 * rng.random(a.shape)
        rgba = np.zeros((H, W, 4), np.uint8)
        rgba[..., 0:3] = (28, 24, 22)
        rgba[..., 3] = (np.clip(a, 0, 1) * 255).astype(np.uint8)
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, name + ".png"))
    print(f"wrote {len(LABELS)} carton labels")
    clock_face()
    thermos_band()
    bamboo_weave()


def clock_face() -> None:
    """An old wall clock's dial: cream, aged at the rim, Arabic numerals, a
    maker's name in Chinese under the twelve, minute ticks."""
    import math
    S = 1024
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = S / 2
    d.ellipse([8, 8, S - 8, S - 8], fill=(236, 226, 200, 255))
    # the rim yellowed
    for k in range(40):
        a = int(70 * (1 - k / 40))
        d.ellipse([8 + k, 8 + k, S - 8 - k, S - 8 - k], outline=(170, 140, 90, a), width=1)
    for m in range(60):
        a = math.radians(m * 6)
        r0 = c - 40 - (22 if m % 5 == 0 else 10)
        r1 = c - 40
        w = 7 if m % 5 == 0 else 3
        d.line([(c + math.sin(a) * r0, c - math.cos(a) * r0), (c + math.sin(a) * r1, c - math.cos(a) * r1)], fill=(30, 26, 22, 255), width=w)
    font = ImageFont.truetype(FONT, 92)
    for h in range(1, 13):
        a = math.radians(h * 30)
        r = c - 140
        d.text((c + math.sin(a) * r, c - math.cos(a) * r), str(h), font=font, fill=(30, 26, 22, 255), anchor="mm")
    small = ImageFont.truetype(FONT, 54)
    d.text((c, c - 190), "寶時", font=small, fill=(150, 40, 34, 255), anchor="mm")
    d.text((c, c + 200), "香港製造", font=ImageFont.truetype(FONT, 34), fill=(60, 52, 44, 255), anchor="mm")
    im.save(os.path.join(OUT, "clock_face.png"))
    print("wrote clock_face.png")


def thermos_band() -> None:
    """The printed tin band round a vacuum flask: peonies and leaves on cream,
    gold lines top and bottom. Wraps once round the flask (u = angle)."""
    import math
    W2, H2 = 2048, 384
    im = Image.new("RGB", (W2, H2), (236, 222, 190))
    d = ImageDraw.Draw(im)
    rng = np.random.default_rng(11)
    for y in (18, H2 - 30):
        d.rectangle([0, y, W2, y + 12], fill=(200, 160, 60))
    # leaves first, then the flowers over them; spaced so the wrap meets itself
    n = 6
    for k in range(n):
        cx = (k + 0.5) * W2 / n
        cy = H2 / 2 + rng.uniform(-20, 20)
        for j in range(5):
            a = rng.uniform(0, math.tau)
            lx, ly = cx + math.cos(a) * 95, cy + math.sin(a) * 60
            d.ellipse([lx - 46, ly - 20, lx + 46, ly + 20], fill=(58, 112, 64))
        col = [(196, 52, 60), (224, 110, 140)][k % 2]
        for j in range(9):
            a = j / 9 * math.tau
            px, py = cx + math.cos(a) * 44, cy + math.sin(a) * 44
            d.ellipse([px - 40, py - 40, px + 40, py + 40], fill=col)
        d.ellipse([cx - 36, cy - 36, cx + 36, cy + 36], fill=tuple(int(c * 0.82) for c in col))
        d.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=(230, 190, 70))
    im = im.filter(ImageFilter.GaussianBlur(1.0))
    im.save(os.path.join(OUT, "thermos_band.png"))
    print("wrote thermos_band.png")


def bamboo_weave() -> None:
    """Split bamboo woven over-and-under, for steamer baskets: wraps once
    round a basket (u) and spans its height (v)."""
    W2, H2 = 2048, 256
    yy, xx = np.mgrid[0:H2, 0:W2].astype(np.float32)
    rng = np.random.default_rng(5)
    cell = 32.0
    cx = (xx // cell).astype(int)
    cy = (yy // cell).astype(int)
    over = (cx + cy) % 2 == 0
    # within each cell, three strips running one way or the other
    u = np.where(over, (yy % cell) / cell, (xx % cell) / cell)
    strip = np.abs(np.sin(u * np.pi * 3)) ** 0.4
    base = np.array([214, 178, 112], np.float32) / 255
    tone = 0.82 + 0.18 * strip
    jitter = rng.random((H2 // 32 + 1, W2 // 32 + 1)).astype(np.float32)
    tone *= 0.92 + 0.08 * jitter[cy, cx]
    shade = np.where(over, 1.0, 0.86)
    img = base[None, None, :] * (tone * shade)[..., None]
    # the gaps between strips
    edge = np.minimum(xx % cell, yy % cell)
    img *= np.where(edge < 1.5, 0.55, 1.0)[..., None]
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, "bamboo_weave.png"))
    print("wrote bamboo_weave.png")


if __name__ == "__main__":
    main()
