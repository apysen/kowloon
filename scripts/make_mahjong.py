"""Paint the mahjong tile faces: one atlas of carved, painted ivory faces.

A Hong Kong set of the eighties: bone-white faces on a jade back, every
mark cut into the face and filled with paint. Each mark is a mask; the
mask is painted, its cut wall shades the top-left edge of the recess, and
the same masks become a height field for the normal map, so the lamp over
the alcove catches the engraving.

The atlas is COLS x ROWS cells, in FACES order (tools/level/mahjong_kit.gd
reads the same order). The last two cells are plain swatches for the
ivory and jade body.

Run from the project root:  python scripts/make_mahjong.py
Writes assets/textures/props/mahjong_atlas.png and mahjong_atlas_n.png
"""

from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "textures", "props")

COLS, ROWS = 8, 5
CELL_W, CELL_H = 256, 336
PAD = 12
CW, CH = CELL_W - 2 * PAD, CELL_H - 2 * PAD  # the face proper: 232 x 312
SS = 3  # supersampling while painting
W, H = CW * SS, CH * SS

FACES = (
    [f"dot_{n}" for n in range(1, 10)]
    + [f"bamboo_{n}" for n in range(1, 10)]
    + [f"character_{n}" for n in range(1, 10)]
    + ["east", "south", "west", "north", "red_dragon", "green_dragon", "white_dragon"]
    + ["flower_plum", "flower_orchid", "flower_chrysanthemum", "flower_bamboo"]
    + ["ivory", "jade"]
)
assert len(FACES) == COLS * ROWS

# the paints: a little dulled and warm, as enamel goes after years of hands
IVORY = np.array([238, 231, 212]) / 255
IVORY_EDGE = np.array([226, 214, 186]) / 255
JADE = np.array([38, 112, 86]) / 255
BLUE = np.array([28, 72, 138]) / 255
NAVY = np.array([24, 38, 72]) / 255
RED = np.array([196, 42, 38]) / 255
GREEN = np.array([30, 116, 70]) / 255
PINK = np.array([214, 92, 118]) / 255
GOLD = np.array([214, 160, 40]) / 255
PURPLE = np.array([112, 64, 140]) / 255
BROWN = np.array([96, 62, 38]) / 255

KAI = os.path.join(ROOT, "tools", "fonts", "src", "LXGWWenKaiTC-Regular.ttf")
SERIF = os.path.join(ROOT, "assets", "fonts", "NotoSerifTC.ttf")
FONT = KAI if os.path.exists(KAI) else SERIF

rng = np.random.default_rng(1987)


# ----------------------------------------------------------------------------- masks


def canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("L", (W, H), 0)
    return im, ImageDraw.Draw(im)


def arr(im: Image.Image) -> np.ndarray:
    return np.asarray(im, dtype=np.float32) / 255


def u(x: float) -> float:
    """Face units: 0..1 across the face's width, mapped to pixels."""
    return x * W


def v(y: float) -> float:
    return y * H


def circle(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill=255) -> None:
    d.ellipse([u(cx) - u(r), v(cy) - u(r), u(cx) + u(r), v(cy) + u(r)], fill=fill)


def glyph(ch: str, cx: float, cy: float, size: float, stretch=1.0) -> np.ndarray:
    """A character centred at (cx, cy), `size` as a fraction of the face width."""
    px = int(u(size))
    font = ImageFont.truetype(FONT, px)
    tmp = Image.new("L", (px * 2, px * 2), 0)
    td = ImageDraw.Draw(tmp)
    td.text((px, px), ch, font=font, fill=255, anchor="mm")
    box = tmp.getbbox()
    tmp = tmp.crop(box)
    if stretch != 1.0:
        tmp = tmp.resize((tmp.width, int(tmp.height * stretch)), Image.LANCZOS)
    im, _ = canvas()
    im.paste(tmp, (int(u(cx) - tmp.width / 2), int(v(cy) - tmp.height / 2)))
    return arr(im)


def shifted(m: np.ndarray, dx: int, dy: int) -> np.ndarray:
    out = np.zeros_like(m)
    h, w = m.shape
    out[max(dy, 0):h + min(dy, 0), max(dx, 0):w + min(dx, 0)] = m[max(-dy, 0):h + min(-dy, 0), max(-dx, 0):w + min(-dx, 0)]
    return out


def blur(m: np.ndarray, r: float) -> np.ndarray:
    im = Image.fromarray((np.clip(m, 0, 1) * 255).astype(np.uint8))
    return arr(im.filter(ImageFilter.GaussianBlur(r)))


# ----------------------------------------------------------------------------- a face being painted


class Face:
    def __init__(self) -> None:
        self.layers: list[tuple[np.ndarray, np.ndarray]] = []

    def paint(self, mask: np.ndarray, color: np.ndarray) -> None:
        self.layers.append((np.clip(mask, 0, 1), color))

    def render(self) -> tuple[np.ndarray, np.ndarray]:
        """Albedo (H, W, 3) and height (H, W), both at the painting size."""
        y, x = np.mgrid[0:H, 0:W].astype(np.float32)
        # the bone: warmer and a touch darker towards the rounded edge,
        # with the faint banding of the material
        ex = np.minimum(x, W - 1 - x) / (W * 0.5)
        ey = np.minimum(y, H - 1 - y) / (H * 0.5)
        edge = np.clip(1 - np.minimum(ex, ey) * 6, 0, 1) ** 2
        grain = blur(rng.random((H, W)).astype(np.float32), 6) - 0.5
        bands = np.sin((y + 40 * np.sin(x / W * 3.1)) / H * 38) * 0.004
        alb = IVORY[None, None, :] * (1 - edge[..., None]) + IVORY_EDGE[None, None, :] * edge[..., None]
        alb = alb * (1 + grain[..., None] * 0.05 + bands[..., None])
        cut = np.zeros((H, W), np.float32)
        for mask, color in self.layers:
            # enamel worn a little unevenly
            wear = 1 + (blur(rng.random((H, W)).astype(np.float32), 10) - 0.5) * 0.12
            alb = alb * (1 - mask[..., None]) + (color[None, None, :] * wear[..., None]) * mask[..., None]
            cut = np.maximum(cut, mask)
        # the cut wall: light falls from the upper left, so the recess is
        # shaded just inside its upper-left rim and caught on its lower-right
        s = 2 * SS
        shade = cut * blur(1 - shifted(cut, s, s), 1.5 * SS)
        catch = cut * blur(1 - shifted(cut, -s, -s), 1.5 * SS)
        alb = alb * (1 - shade[..., None] * 0.42) * (1 + catch[..., None] * 0.10)
        # a faint grey of old handling around every cut
        rim = np.clip(blur(cut, 3 * SS) - cut, 0, 1)
        alb = alb * (1 - rim[..., None] * 0.10)
        height = 1 - blur(cut, 0.8 * SS)
        return np.clip(alb, 0, 1), height


# ----------------------------------------------------------------------------- dots


def dot(f: Face, cx: float, cy: float, r: float, color: np.ndarray) -> None:
    """One coin: a ring of the colour, a scalloped ring inside, a pip."""
    im, d = canvas()
    circle(d, cx, cy, r)
    circle(d, cx, cy, r * 0.74, fill=0)
    circle(d, cx, cy, r * 0.22)
    outer = arr(im)
    im, d = canvas()
    for k in range(8):
        a = k * math.pi / 4
        circle(d, cx + math.cos(a) * r * 0.48, cy + math.sin(a) * r * 0.48 * W / H, r * 0.13)
    petals = arr(im)
    f.paint(outer, color)
    f.paint(petals, color * 0.8 + RED * 0.2 if color is not RED else GREEN)


def dots(n: int) -> Face:
    f = Face()
    if n == 1:
        # the great coin: green petals round a red and blue medallion
        im, d = canvas()
        for k in range(16):
            a = k * math.pi / 8
            circle(d, 0.5 + math.cos(a) * 0.33, 0.5 + math.sin(a) * 0.33 * W / H, 0.075)
        circle(d, 0.5, 0.5, 0.33, fill=0)
        f.paint(arr(im), GREEN)
        im, d = canvas()
        circle(d, 0.5, 0.5, 0.29)
        circle(d, 0.5, 0.5, 0.235, fill=0)
        f.paint(arr(im), BLUE)
        im, d = canvas()
        circle(d, 0.5, 0.5, 0.2)
        circle(d, 0.5, 0.5, 0.15, fill=0)
        for k in range(12):
            a = k * math.pi / 6 + 0.26
            circle(d, 0.5 + math.cos(a) * 0.11, 0.5 + math.sin(a) * 0.11 * W / H, 0.03)
        f.paint(arr(im), RED)
        im, d = canvas()
        circle(d, 0.5, 0.5, 0.06)
        circle(d, 0.5, 0.5, 0.025, fill=0)
        f.paint(arr(im), BLUE)
        return f
    r = {2: 0.17, 3: 0.15, 4: 0.15, 5: 0.13, 6: 0.13, 7: 0.115, 8: 0.115, 9: 0.115}[n]
    L, C, Rt = 0.29, 0.5, 0.71
    spots: list[tuple[float, float, np.ndarray]] = {
        2: [(C, 0.28, GREEN), (C, 0.72, BLUE)],
        3: [(0.27, 0.22, BLUE), (C, 0.5, RED), (0.73, 0.78, GREEN)],
        4: [(L, 0.3, BLUE), (Rt, 0.3, GREEN), (L, 0.7, GREEN), (Rt, 0.7, BLUE)],
        5: [(0.28, 0.24, BLUE), (0.72, 0.24, GREEN), (C, 0.5, RED), (0.28, 0.76, GREEN), (0.72, 0.76, BLUE)],
        6: [(L, 0.2, GREEN), (Rt, 0.2, GREEN), (L, 0.52, RED), (Rt, 0.52, RED), (L, 0.8, RED), (Rt, 0.8, RED)],
        7: [(0.24, 0.13, GREEN), (C, 0.23, GREEN), (0.76, 0.33, GREEN),
            (L, 0.6, RED), (Rt, 0.6, RED), (L, 0.85, RED), (Rt, 0.85, RED)],
        8: [(L, y, BLUE) for y in (0.14, 0.38, 0.62, 0.86)] + [(Rt, y, BLUE) for y in (0.14, 0.38, 0.62, 0.86)],
        9: [(x, 0.2, BLUE) for x in (0.2, C, 0.8)] + [(x, 0.5, RED) for x in (0.2, C, 0.8)] + [(x, 0.8, GREEN) for x in (0.2, C, 0.8)],
    }[n]
    for x, y, col in spots:
        dot(f, x, y, r, col)
    return f


# ----------------------------------------------------------------------------- bamboo


def stick(d: ImageDraw.ImageDraw, cx: float, cy: float, length: float, width: float) -> None:
    """One bamboo stalk: two segments, swollen at the knots, split down the middle."""
    top, bot = cy - length / 2, cy + length / 2
    hw = width / 2
    for (a, b) in ((top, cy - 0.006), (cy + 0.006, bot)):
        d.rounded_rectangle([u(cx - hw * 0.8), v(a), u(cx + hw * 0.8), v(b)], radius=u(hw * 0.4), fill=255)
    for k in (top, cy, bot):
        d.ellipse([u(cx - hw), v(k) - u(hw * 0.42), u(cx + hw), v(k) + u(hw * 0.42)], fill=255)
    # the pale line down each segment
    for a, b in ((top + 0.035, cy - 0.04), (cy + 0.04, bot - 0.035)):
        if b > a:
            d.line([u(cx), v(a), u(cx), v(b)], fill=0, width=max(1, int(u(width * 0.07))))


def bird(f: Face) -> None:
    """One of bamboo: the sparrow on its stalk, tail fanned."""
    im, d = canvas()
    # tail feathers, fanned down to the left
    for k, col in enumerate((GREEN, BLUE, RED, GREEN, BLUE)):
        im, d = canvas()
        a = math.radians(200 + k * 14)
        x0, y0 = 0.46, 0.62
        x1, y1 = x0 + math.cos(a) * 0.36, y0 - math.sin(a) * 0.36 * W / H
        d.line([u(x0), v(y0), u(x1), v(y1)], fill=255, width=int(u(0.05)))
        circle(d, x1, y1, 0.045)
        f.paint(arr(im), col)
    # the perch
    im, d = canvas()
    stick(d, 0.5, 0.86, 0.2, 0.09)
    f.paint(arr(im), GREEN)
    # the body: a plump teardrop
    im, d = canvas()
    d.ellipse([u(0.3), v(0.38), u(0.74), v(0.72)], fill=255)
    d.polygon([(u(0.34), v(0.62)), (u(0.5), v(0.72)), (u(0.2), v(0.78))], fill=255)
    f.paint(arr(im), RED)
    # the breast and wing
    im, d = canvas()
    d.ellipse([u(0.5), v(0.44), u(0.72), v(0.66)], fill=255)
    f.paint(arr(im), GOLD)
    im, d = canvas()
    d.chord([u(0.3), v(0.42), u(0.62), v(0.7)], 120, 300, fill=255)
    for k in range(3):
        d.arc([u(0.32 + k * 0.03), v(0.46 + k * 0.03), u(0.6), v(0.68)], 150, 290, fill=0, width=int(u(0.012)))
    f.paint(arr(im), BLUE)
    # the head, the crest, the beak, the eye
    im, d = canvas()
    circle(d, 0.66, 0.32, 0.12)
    for k in range(3):
        d.line([u(0.62), v(0.24), u(0.5 + k * 0.06), v(0.1 + k * 0.01)], fill=255, width=int(u(0.03)))
        circle(d, 0.5 + k * 0.06, 0.1 + k * 0.01, 0.025)
    f.paint(arr(im), GREEN)
    im, d = canvas()
    d.polygon([(u(0.76), v(0.29)), (u(0.92), v(0.33)), (u(0.76), v(0.37))], fill=255)
    f.paint(arr(im), GOLD * 0.9)
    im, d = canvas()
    circle(d, 0.69, 0.3, 0.032)
    f.paint(arr(im), NAVY)


def bamboos(n: int) -> Face:
    f = Face()
    if n == 1:
        bird(f)
        return f
    L, C, Rt = 0.24, 0.5, 0.76
    # (x, y, colour) of each stalk, the length for the tile
    layout = {
        2: [(C, 0.27, BLUE), (C, 0.73, GREEN)],
        3: [(C, 0.27, GREEN), (0.32, 0.73, GREEN), (0.68, 0.73, BLUE)],
        4: [(0.32, 0.27, BLUE), (0.68, 0.27, GREEN), (0.32, 0.73, GREEN), (0.68, 0.73, BLUE)],
        5: [(0.22, 0.27, GREEN), (0.78, 0.27, BLUE), (C, 0.5, RED), (0.22, 0.73, BLUE), (0.78, 0.73, GREEN)],
        6: [(x, 0.27, GREEN) for x in (L, C, Rt)] + [(x, 0.73, BLUE) for x in (L, C, Rt)],
        7: [(C, 0.18, RED)] + [(x, 0.5, GREEN) for x in (L, C, Rt)] + [(x, 0.83, GREEN) for x in (L, C, Rt)],
        8: [],
        9: [(x, y, RED if x == C else (GREEN if y != 0.5 else BLUE)) for y in (0.18, 0.5, 0.82) for x in (L, C, Rt)],
    }[n]
    length = 0.38 if n <= 6 else 0.25
    width = 0.15 if n <= 5 else 0.13
    for x, y, col in layout:
        im, d = canvas()
        stick(d, x, y, length, width)
        f.paint(arr(im), col)
    if n == 8:
        # the eight: two Ms, the middle stalks leaning together
        for row, y in enumerate((0.27, 0.73)):
            col = GREEN if row == 0 else BLUE
            for x, ang in ((0.17, 0), (0.83, 0), (0.37, 24), (0.63, -24)):
                im, d = canvas()
                stick(d, x, y, 0.38, 0.12)
                if ang:
                    im = im.rotate(ang, center=(u(x), v(y)), resample=Image.BICUBIC)
                f.paint(arr(im), col if ang == 0 else GREEN * 0.5 + col * 0.5)
    return f


# ----------------------------------------------------------------------------- characters and honours


NUMERALS = "一二三四五六七八九"


def character(n: int) -> Face:
    f = Face()
    f.paint(glyph(NUMERALS[n - 1], 0.5, 0.24, 0.5, stretch=0.9), NAVY)
    f.paint(glyph("萬", 0.5, 0.7, 0.7), RED)
    return f


def honour(ch: str, color: np.ndarray, size=0.95) -> Face:
    f = Face()
    f.paint(glyph(ch, 0.5, 0.5, size, stretch=1.08), color)
    return f


def white_dragon() -> Face:
    """白板: blank but for its frame, a double border in blue."""
    f = Face()
    im, d = canvas()
    for inset, wd in ((0.1, 0.035), (0.19, 0.016)):
        x0, y0 = u(inset), v(inset * W / H)
        d.rounded_rectangle([x0, y0, W - x0, H - y0], radius=u(0.04), outline=255, width=int(u(wd)))
    f.paint(arr(im), BLUE)
    return f


# ----------------------------------------------------------------------------- flowers


def blossom(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float, petals=5) -> None:
    for k in range(petals):
        a = k * 2 * math.pi / petals - math.pi / 2
        circle(d, cx + math.cos(a) * r * 0.55, cy + math.sin(a) * r * 0.55 * W / H, r * 0.5)


def flower(kind: str, n: int, ch: str) -> Face:
    f = Face()
    # the number, red, top left; the name, navy, top right
    f.paint(glyph(str(n), 0.17, 0.11, 0.2), RED)
    f.paint(glyph(ch, 0.8, 0.13, 0.26), NAVY)
    if kind == "plum":
        im, d = canvas()
        pts = [(0.2, 0.92), (0.38, 0.72), (0.34, 0.52), (0.55, 0.36), (0.7, 0.3)]
        d.line([(u(x), v(y)) for x, y in pts], fill=255, width=int(u(0.045)), joint="curve")
        d.line([(u(0.38), v(0.72)), (u(0.66), v(0.64))], fill=255, width=int(u(0.03)))
        f.paint(arr(im), BROWN)
        im, d = canvas()
        for x, y, r in ((0.55, 0.36, 0.1), (0.36, 0.53, 0.09), (0.67, 0.63, 0.1), (0.72, 0.28, 0.06), (0.28, 0.78, 0.06)):
            blossom(d, x, y, r)
        f.paint(arr(im), PINK)
        im, d = canvas()
        for x, y in ((0.55, 0.36), (0.36, 0.53), (0.67, 0.63)):
            circle(d, x, y, 0.025)
        f.paint(arr(im), GOLD)
    elif kind == "orchid":
        im, d = canvas()
        for x1, y1 in ((0.14, 0.4), (0.3, 0.3), (0.84, 0.46), (0.7, 0.32), (0.92, 0.7)):
            d.line([(u(0.5), v(0.9)), (u((0.5 + x1) / 2 + 0.04), v((0.9 + y1) / 2)), (u(x1), v(y1))],
                   fill=255, width=int(u(0.03)), joint="curve")
        f.paint(arr(im), GREEN)
        im, d = canvas()
        blossom(d, 0.46, 0.46, 0.13, petals=3)
        blossom(d, 0.62, 0.58, 0.1, petals=3)
        f.paint(arr(im), PURPLE)
        im, d = canvas()
        circle(d, 0.46, 0.46, 0.03)
        circle(d, 0.62, 0.58, 0.025)
        f.paint(arr(im), GOLD)
    elif kind == "chrysanthemum":
        im, d = canvas()
        d.line([(u(0.5), v(0.95)), (u(0.48), v(0.5))], fill=255, width=int(u(0.035)))
        for x, y in ((0.3, 0.72), (0.7, 0.66), (0.32, 0.58)):
            d.ellipse([u(x - 0.1), v(y) - u(0.05), u(x + 0.1), v(y) + u(0.05)], fill=255)
        f.paint(arr(im), GREEN)
        im, d = canvas()
        for k in range(16):
            a = k * math.pi / 8
            d.line([(u(0.48), v(0.42)), (u(0.48 + math.cos(a) * 0.24), v(0.42) + u(math.sin(a) * 0.24))],
                   fill=255, width=int(u(0.05)))
        f.paint(arr(im), GOLD)
        im, d = canvas()
        circle(d, 0.48, 0.42, 0.07)
        f.paint(arr(im), RED * 0.6 + GOLD * 0.4)
    elif kind == "bamboo":
        im, d = canvas()
        stick(d, 0.42, 0.42, 0.5, 0.1)
        stick(d, 0.42, 0.78, 0.22, 0.1)
        f.paint(arr(im), GREEN)
        im, d = canvas()
        for (x0, y0, x1, y1) in ((0.44, 0.3, 0.84, 0.22), (0.44, 0.32, 0.8, 0.38), (0.4, 0.55, 0.12, 0.48), (0.4, 0.57, 0.16, 0.66)):
            d.polygon([(u(x0), v(y0)), (u((x0 + x1) / 2), v((y0 + y1) / 2) - u(0.04)), (u(x1), v(y1)),
                       (u((x0 + x1) / 2), v((y0 + y1) / 2) + u(0.03))], fill=255)
        f.paint(arr(im), GREEN * 0.7 + BLUE * 0.3)
    return f


# ----------------------------------------------------------------------------- the atlas


def face_for(name: str) -> Face | None:
    kind, _, num = name.partition("_")
    if kind == "dot":
        return dots(int(num))
    if kind == "bamboo":
        return bamboos(int(num))
    if kind == "character":
        return character(int(num))
    honours = {"east": ("東", NAVY), "south": ("南", NAVY), "west": ("西", NAVY), "north": ("北", NAVY),
               "red_dragon": ("中", RED), "green_dragon": ("發", GREEN)}
    if name in honours:
        return honour(*honours[name], size=0.86)
    if name == "white_dragon":
        return white_dragon()
    flowers = {"flower_plum": ("plum", 1, "梅"), "flower_orchid": ("orchid", 2, "蘭"),
               "flower_chrysanthemum": ("chrysanthemum", 3, "菊"), "flower_bamboo": ("bamboo", 4, "竹")}
    if name in flowers:
        return flower(*flowers[name])
    return None


def height_to_normal(h: np.ndarray, strength: float) -> np.ndarray:
    gy, gx = np.gradient(h)
    n = np.stack([-gx * strength, gy * strength, np.ones_like(h)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def main() -> None:
    atlas = np.zeros((ROWS * CELL_H, COLS * CELL_W, 3), np.float32)
    normal = np.zeros_like(atlas)
    normal[..., :] = (0.5, 0.5, 1.0)
    for i, name in enumerate(FACES):
        cx, cy = (i % COLS) * CELL_W, (i // COLS) * CELL_H
        f = face_for(name)
        if f is None:
            # body swatches: flat colour, filling the whole cell
            atlas[cy:cy + CELL_H, cx:cx + CELL_W] = IVORY if name == "ivory" else JADE
            continue
        alb, height = f.render()
        small = Image.fromarray((alb * 255).astype(np.uint8)).resize((CW, CH), Image.LANCZOS)
        hs = Image.fromarray((height * 255).astype(np.uint8)).resize((CW, CH), Image.LANCZOS)
        a = np.asarray(small, np.float32) / 255
        nm = height_to_normal(np.asarray(hs, np.float32) / 255, 2.2)
        # the padding repeats the face's own edge, so mipmaps never pull in a neighbour
        a = np.pad(a, ((PAD, PAD), (PAD, PAD), (0, 0)), mode="edge")
        nm = np.pad(nm, ((PAD, PAD), (PAD, PAD), (0, 0)), mode="edge")
        atlas[cy:cy + CELL_H, cx:cx + CELL_W] = a
        normal[cy:cy + CELL_H, cx:cx + CELL_W] = nm
    Image.fromarray((np.clip(atlas, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, "mahjong_atlas.png"))
    Image.fromarray((np.clip(normal, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, "mahjong_atlas_n.png"))
    print(f"wrote mahjong_atlas.png and mahjong_atlas_n.png ({len(FACES)} cells)")


if __name__ == "__main__":
    main()
