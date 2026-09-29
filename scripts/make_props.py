"""Paint the small textures the world uses: signs, notices, calendars, sky.

Period detail is the point. The slice is set in 1992, the last months before
residents left Kowloon Walled City: dentists' boards crowd the street face,
shopfronts carry painted boards and a few lightboxes, the hall has the
Housing Department's clearance notice pasted up, and every flat has a
calendar for the year.

Run from the project root:  python scripts/make_props.py
Writes assets/textures/props/*.png
"""

from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "textures", "props")
FONTS = os.path.join(ROOT, "assets", "fonts")
os.makedirs(OUT, exist_ok=True)


def cjk(size, weight=700):
    f = ImageFont.truetype(os.path.join(FONTS, "NotoSerifTC.ttf"), size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


def latin(size, bold=False):
    name = "IBMPlexSansCondensed-SemiBold.ttf" if bold else "IBMPlexSansCondensed-Medium.ttf"
    return ImageFont.truetype(os.path.join(FONTS, name), size)


def rng(seed):
    return np.random.default_rng(seed)


def weather(img: Image.Image, seed: int, amount=0.35, streaks=True):
    """Grime, fading and water streaks over a painted sign."""
    g = rng(seed)
    a = np.asarray(img.convert("RGBA")).astype(float) / 255
    h, w = a.shape[:2]
    noise = g.random((h // 8 + 2, w // 8 + 2))
    noise = np.kron(noise, np.ones((8, 8)))[:h, :w]
    noise = np.asarray(Image.fromarray((noise * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))) / 255
    fadev = 1 - amount * 0.35 * noise
    a[..., :3] *= fadev[..., None]
    if streaks:
        for _ in range(int(w / 18)):
            x = int(g.random() * w)
            ln = int(h * (0.3 + g.random() * 0.7))
            wd = 1 + int(g.random() * 3)
            t = np.linspace(1, 0, ln)[:, None, None]
            a[:ln, x:x + wd, :3] *= (1 - amount * 0.4 * t)
    grad = np.linspace(0, 1, h)[:, None]
    a[..., :3] *= (1 - amount * 0.3 * grad)[..., None]
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA")


def save(img, name):
    img.save(os.path.join(OUT, name + ".png"), optimize=True)
    print("wrote", name)


# ----------------------------------------------------------------------------- simple maps


def contact_shadow():
    s = 128
    y, x = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    d = np.sqrt(x * x + y * y)
    a = np.clip(1 - d, 0, 1) ** 1.6
    img = np.zeros((s, s, 4))
    img[..., 3] = a * 0.85
    save(Image.fromarray((img * 255).astype(np.uint8), "RGBA"), "contact_shadow")


def soft_dot():
    s = 64
    y, x = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    a = np.clip(1 - np.sqrt(x * x + y * y), 0, 1) ** 2
    img = np.ones((s, s, 4))
    img[..., 3] = a
    save(Image.fromarray((img * 255).astype(np.uint8), "RGBA"), "soft_dot")


def light_shaft():
    """A vertical beam: bright at the source, fading down, soft at the sides."""
    w, h = 128, 256
    y, x = np.mgrid[0:h, 0:w]
    u = x / (w - 1) * 2 - 1
    v = y / (h - 1)
    side = np.clip(1 - np.abs(u), 0, 1) ** 1.5
    along = (1 - v) ** 1.2 * np.clip(v * 8, 0, 1)
    g = rng(5)
    streak = np.kron(g.random((1, 16)), np.ones((h, 8)))[:, :w]
    streak = 0.75 + 0.25 * np.asarray(Image.fromarray((streak * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))) / 255
    a = side * along * streak
    img = np.ones((h, w, 4))
    img[..., 3] = a
    save(Image.fromarray((img * 255).astype(np.uint8), "RGBA"), "light_shaft")


def blob_puddle():
    s = 256
    g = rng(9)
    n = g.random((s // 16, s // 16))
    n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((s, s), Image.BICUBIC)) / 255
    y, x = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    d = np.sqrt(x * x + y * y)
    a = np.clip((1 - d) * 1.6 + (n - 0.5) * 0.8, 0, 1)
    a = (a > 0.35).astype(float) * 0.9
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2))) / 255
    img = np.zeros((s, s, 4))
    img[..., :3] = [0.12, 0.14, 0.16]
    img[..., 3] = a * 0.6
    save(Image.fromarray((img * 255).astype(np.uint8), "RGBA"), "puddle")


def stain_decal(seed, name, col=(60, 45, 30)):
    s = 256
    g = rng(seed)
    n = g.random((s // 8, s // 8))
    n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((s, s), Image.BICUBIC)) / 255
    y, x = np.mgrid[0:s, 0:s] / (s - 1) * 2 - 1
    d = np.sqrt(x * x * 0.7 + y * y)
    a = np.clip((1 - d) * 1.3 + (n - 0.5), 0, 1) ** 1.5
    img = np.zeros((s, s, 4))
    img[..., 0], img[..., 1], img[..., 2] = col[0] / 255, col[1] / 255, col[2] / 255
    img[..., 3] = a * 0.55
    save(Image.fromarray((img * 255).astype(np.uint8), "RGBA"), name)


# ----------------------------------------------------------------------------- signage


def board(lines, size, bg, fg, seed, border=True, sub=None, vertical=False):
    """A painted shop board: big Chinese characters, optional English line."""
    w, h = size
    img = Image.new("RGBA", (w, h), bg)
    d = ImageDraw.Draw(img)
    if border:
        d.rectangle([6, 6, w - 7, h - 7], outline=fg, width=5)
    if vertical:
        chars = list(lines)
        cs = int(min(w * 0.7, (h - 30) / len(chars)))
        f = cjk(cs)
        for i, ch in enumerate(chars):
            y = 15 + (h - 30) * (i + 0.5) / len(chars)
            d.text((w / 2, y), ch, font=f, fill=fg, anchor="mm")
    else:
        f = cjk(int(h * (0.46 if sub else 0.6)))
        d.text((w / 2, h * (0.4 if sub else 0.5)), lines, font=f, fill=fg, anchor="mm")
        if sub:
            d.text((w / 2, h * 0.8), sub, font=latin(int(h * 0.15), True), fill=fg, anchor="mm")
    return weather(img, seed)


def neon(text, color, seed, size=(96, 320)):
    """A vertical lightbox/neon sign: glowing strokes on a dark box, plus the
    emission map the world shader lights it with."""
    w, h = size
    base = Image.new("RGBA", (w, h), (22, 14, 18, 255))
    d = ImageDraw.Draw(base)
    chars = list(text)
    cs = int(min(w * 0.64, (h - 40) / len(chars) * 0.86))
    f = cjk(cs)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.rectangle([7, 7, w - 8, h - 8], outline=color, width=5)
    for i, ch in enumerate(chars):
        y = 20 + (h - 40) * (i + 0.5) / len(chars)
        gd.text((w / 2, y), ch, font=f, fill=color, anchor="mm")
    blur = glow.filter(ImageFilter.GaussianBlur(7))
    base.alpha_composite(blur)
    base.alpha_composite(blur)
    core = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(core)
    cd.rectangle([7, 7, w - 8, h - 8], outline=(255, 245, 240, 255), width=2)
    for i, ch in enumerate(chars):
        y = 20 + (h - 40) * (i + 0.5) / len(chars)
        cd.text((w / 2, y), ch, font=f, fill=(255, 246, 240, 255), anchor="mm")
    base.alpha_composite(glow)
    base.alpha_composite(core.filter(ImageFilter.GaussianBlur(0.6)))
    return base


def signs():
    save(board("劉牙科", (512, 256), (168, 69, 58, 255), (243, 230, 200, 255), 1, sub="LAU DENTAL"), "sign_lau_dental")
    save(board("閒人免進", (256, 128), (242, 238, 228, 255), (176, 48, 42, 255), 2, sub="STAFF ONLY"), "sign_staff_only")
    save(board("陳記", (256, 128), (74, 90, 58, 255), (240, 226, 190, 255), 3, sub="TAILOR"), "sign_tailor")
    # the dentists' wall: the Walled City's street face was famous for them
    dent = [("牙科", "#f3e6c8", "#1f4f8a"), ("鑲牙", "#fff2d8", "#a8453a"), ("牙醫", "#1c1c1c", "#f0d040"),
            ("脫牙", "#f3f3f0", "#2a6a4a"), ("口腔", "#fff0e0", "#7a2a5a"), ("牙科醫生", "#f3e6c8", "#a8453a")]
    for i, (t, fg, bg) in enumerate(dent):
        img = board(t, (96, 320), bg, fg, 20 + i, vertical=True)
        save(img, f"sign_dentist_{i}")
    shops = [("茶餐廳", "#ffb040"), ("理髮", "#40d8ff"), ("五金", "#ff60c0"), ("麵家", "#ffd040"),
             ("藥房", "#60ff90"), ("士多", "#ff7040"), ("鐘錶", "#80a0ff"), ("裁縫", "#ff4a8a"),
             ("當", "#ffb040"), ("涼茶", "#40ffd0"), ("酒家", "#ff5040"), ("魚蛋", "#ffd060")]
    for i, (t, c) in enumerate(shops):
        rgb = tuple(int(c[k:k + 2], 16) for k in (1, 3, 5)) + (255,)
        save(neon(t, rgb, 40 + i), f"neon_{i}")


def stair_sign():
    """A painted stair marker, as on every HK tenement landing: the floor
    characters and a fat red arrow pointing down the flight."""
    w, h = 192, 256
    img = Image.new("RGBA", (w, h), (238, 232, 214, 255))
    d = ImageDraw.Draw(img)
    red = (178, 44, 38, 255)
    d.rectangle([6, 6, w - 7, h - 7], outline=red, width=5)
    d.text((w / 2, 58), "落樓", font=cjk(62), fill=red, anchor="mm")
    d.polygon([(w / 2 - 22, 108), (w / 2 + 22, 108), (w / 2 + 22, 168), (w / 2 + 50, 168),
               (w / 2, 222), (w / 2 - 50, 168), (w / 2 - 22, 168)], fill=red)
    d.text((w / 2, 240), "1/F", font=latin(22, True), fill=(40, 36, 32, 255), anchor="mm")
    return weather(img, 44, 0.4)


def clearance_notice():
    """The Housing Department's clearance notice, pasted in the hall."""
    w, h = 384, 512
    img = Image.new("RGBA", (w, h), (238, 232, 214, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([10, 10, w - 11, h - 11], outline=(40, 40, 40, 255), width=2)
    d.text((w / 2, 50), "九龍城寨清拆", font=cjk(40), fill=(20, 20, 20, 255), anchor="mm")
    d.text((w / 2, 92), "KOWLOON WALLED CITY CLEARANCE", font=latin(18, True), fill=(20, 20, 20, 255), anchor="mm")
    d.line([30, 115, w - 30, 115], fill=(40, 40, 40, 255), width=2)
    f = cjk(19, 500)
    body = ["居民須於指定日期前遷出", "有關安置及補償事宜", "請向房屋署查詢", "", "Residents must vacate by the",
            "date specified. For rehousing and", "compensation, contact the", "Housing Department."]
    y = 150
    for ln in body:
        if not ln:
            y += 16
            continue
        font = f if any(ord(ch) > 0x2E80 for ch in ln) else latin(17)
        d.text((w / 2, y), ln, font=font, fill=(40, 36, 30, 255), anchor="mm")
        y += 30
    d.text((w / 2 - 70, h - 60), "房屋署", font=cjk(18, 600), fill=(40, 36, 30, 255), anchor="mm")
    d.text((w / 2 + 40, h - 60), "HOUSING DEPARTMENT", font=latin(16, True), fill=(40, 36, 30, 255), anchor="mm")
    d.text((w / 2, h - 34), "一九九二年", font=cjk(18, 500), fill=(40, 36, 30, 255), anchor="mm")
    img = weather(img, 61, 0.55)
    # torn corner
    a = np.asarray(img).copy()
    for yy in range(40):
        a[yy, w - 40 + yy:, 3] = 0
    save(Image.fromarray(a, "RGBA"), "notice_clearance")


def calendar():
    """A 1992 wall calendar, the kind every flat had from a shop or a bank."""
    w, h = 256, 384
    img = Image.new("RGBA", (w, h), (246, 240, 226, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w, 150], fill=(176, 48, 42, 255))
    d.text((w / 2, 60), "壬申年", font=cjk(46), fill=(250, 220, 120, 255), anchor="mm")
    d.text((w / 2, 118), "1992", font=latin(34, True), fill=(250, 236, 200, 255), anchor="mm")
    d.text((w / 2, 180), "十月", font=cjk(30), fill=(40, 30, 26, 255), anchor="mm")
    cols = 7
    for i in range(31):
        r, c = divmod(i + 4, cols)
        x = 22 + c * 32
        y = 215 + r * 30
        col = (176, 48, 42, 255) if c == 0 else (40, 30, 26, 255)
        d.text((x, y), str(i + 1), font=latin(18, True), fill=col, anchor="mm")
    save(weather(img, 70, 0.3, streaks=False), "calendar_1992")


def certificate():
    w, h = 256, 192
    img = Image.new("RGBA", (w, h), (106, 74, 42, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([12, 12, w - 13, h - 13], fill=(242, 236, 216, 255))
    d.text((w / 2, 50), "執業證書", font=cjk(28), fill=(60, 40, 30, 255), anchor="mm")
    for k in range(4):
        d.line([40, 90 + k * 18, w - 40, 90 + k * 18], fill=(150, 140, 120, 255), width=2)
    d.ellipse([w - 70, h - 70, w - 34, h - 34], fill=(180, 50, 40, 255))
    save(weather(img, 80, 0.3, streaks=False), "certificate")


def posters():
    """Film and opera posters, and a faded political bill, on corridor walls."""
    specs = [("粵劇", "CANTONESE OPERA", (150, 40, 40), (240, 210, 120)),
             ("雀館", "", (40, 80, 60), (240, 230, 200)),
             ("旺舖出租", "", (230, 220, 200), (180, 40, 40)),
             ("電器維修", "REPAIRS", (40, 60, 110), (240, 230, 200))]
    for i, (t, sub, bg, fg) in enumerate(specs):
        w, h = 256, 360
        img = Image.new("RGBA", (w, h), bg + (255,))
        d = ImageDraw.Draw(img)
        d.text((w / 2, h * 0.35), t, font=cjk(int(w * 0.9 / max(2, len(t)))), fill=fg + (255,), anchor="mm")
        if sub:
            d.text((w / 2, h * 0.62), sub, font=latin(22, True), fill=fg + (255,), anchor="mm")
        d.rectangle([20, h * 0.72, w - 20, h * 0.9], outline=fg + (255,), width=3)
        save(weather(img, 90 + i, 0.6), f"poster_{i}")


def mailboxes():
    w, h = 256, 256
    img = Image.new("RGBA", (w, h), (70, 100, 90, 255))
    d = ImageDraw.Draw(img)
    for r in range(4):
        for c in range(4):
            x0, y0 = 10 + c * 60, 10 + r * 60
            d.rectangle([x0, y0, x0 + 54, y0 + 54], fill=(92, 128, 116, 255), outline=(40, 60, 50, 255), width=2)
            d.rectangle([x0 + 10, y0 + 10, x0 + 44, y0 + 16], fill=(30, 30, 30, 255))
            d.text((x0 + 27, y0 + 36), f"{r + 1}{'ABCD'[c]}", font=latin(14, True), fill=(230, 230, 220, 255), anchor="mm")
    save(weather(img, 95, 0.5), "mailboxes")


# ----------------------------------------------------------------------------- sky


def sky_panorama():
    """Golden-hour sky over Kowloon: 360 degrees, clouds lit from the west."""
    w, h = 2048, 1024
    y = np.linspace(0, 1, h)[:, None]
    x = np.linspace(0, 1, w)[None, :]
    top = np.array([0.30, 0.50, 0.76])
    mid = np.array([0.93, 0.80, 0.66])
    low = np.array([0.83, 0.56, 0.44])
    horizon = 0.5
    t = np.clip((horizon - y) / horizon, 0, 1)
    col = mid + (top - mid) * (t ** 0.7)[..., None]
    below = np.clip((y - horizon) / (1 - horizon), 0, 1)
    col = np.where((y > horizon)[..., None], mid + (low - mid) * (below ** 0.5)[..., None], col)
    col = np.broadcast_to(col, (h, w, 3)).copy()
    # sun glow toward the west (u ~ 0.75 in Godot's panorama is -X)
    sun_u, sun_v = 0.72, 0.43
    du = np.minimum(np.abs(x - sun_u), 1 - np.abs(x - sun_u)) * 2
    dv = (y - sun_v)
    dist = np.sqrt((du * 1.6) ** 2 + dv ** 2)
    glow = np.exp(-dist * 7.0)[..., None]
    col = col + glow * np.array([0.55, 0.36, 0.18]) + np.exp(-dist * 60.0)[..., None] * np.array([1.0, 0.9, 0.7])
    # clouds: layered periodic noise, stretched along the horizon
    g = rng(12)

    def pnoise(cells_x, cells_y, seed):
        gg = rng(seed)
        n = gg.random((cells_y, cells_x))
        n = np.concatenate([n, n[:, :1]], 1)
        im = Image.fromarray((n * 255).astype(np.uint8)).resize((w + w // cells_x, h), Image.BICUBIC)
        return np.asarray(im)[:, :w] / 255

    c = pnoise(10, 5, 1) * 0.55 + pnoise(28, 12, 2) * 0.3 + pnoise(90, 40, 3) * 0.15
    band = np.exp(-((y - 0.3) / 0.16) ** 2) + 0.7 * np.exp(-((y - 0.45) / 0.04) ** 2)
    cover = np.clip((c - 0.46) * 2.6, 0, 1) ** 0.8 * band
    cloud_lit = np.array([1.0, 0.86, 0.72]) * (0.85 + 0.4 * glow[..., 0:1])
    cloud_shadow = np.array([0.62, 0.58, 0.66])
    shade = np.clip(pnoise(64, 28, 4) * 1.2 - 0.1, 0, 1)[..., None]
    cloud = cloud_shadow + (cloud_lit - cloud_shadow) * shade
    col = col * (1 - cover[..., None] * 0.85) + cloud * cover[..., None] * 0.85
    col = np.clip(col, 0, 1)
    img = Image.fromarray((col * 255).astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(2.0))
    img.save(os.path.join(OUT, "sky_golden.png"))
    print("wrote sky_golden")


def lion_rock():
    """Distant hills north of Kowloon City, Lion Rock's crouching profile among them."""
    w, h = 2048, 384
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    g = rng(21)
    xs = np.linspace(0, w, 200)
    base = h * 0.7 - 60 * np.sin(xs / w * math.pi * 3 + 1) - 40 * np.sin(xs / w * math.pi * 7)
    # Lion Rock: a rounded head, a dip, a long back
    lion = np.where((xs > w * 0.38) & (xs < w * 0.62),
                    -np.exp(-((xs - w * 0.44) / (w * 0.035)) ** 2) * 150 - np.exp(-((xs - w * 0.53) / (w * 0.07)) ** 2) * 110, 0)
    far = base + lion + g.random(200) * 6
    pts = [(0, h)] + list(zip(xs, far)) + [(w, h)]
    d.polygon(pts, fill=(118, 140, 150, 255))
    near = h * 0.85 - 30 * np.sin(xs / w * math.pi * 5 + 2) + g.random(200) * 4
    pts = [(0, h)] + list(zip(xs, near)) + [(w, h)]
    d.polygon(pts, fill=(96, 120, 116, 255))
    img = img.filter(ImageFilter.GaussianBlur(1.2))
    save(img, "hills_north")


def checkerboard_hill():
    """The red-and-white checkerboard on the hill west of the city, the marker
    pilots turned on for the final approach into Kai Tak."""
    w, h = 256, 256
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    n = 6
    s = w // n
    for r in range(n):
        for c in range(n):
            col = (200, 70, 40, 255) if (r + c) % 2 == 0 else (240, 236, 226, 255)
            d.rectangle([c * s, r * s, c * s + s - 1, r * s + s - 1], fill=col)
    save(weather(img, 33, 0.3, streaks=False), "checkerboard")


def paper():
    """Scrapbook paper: warm, fibrous, slightly foxed."""
    w = h = 512
    g = rng(40)
    n = g.random((h, w))
    n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1))) / 255
    big = g.random((16, 16))
    big = np.asarray(Image.fromarray((big * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)) / 255
    base = np.array([0.94, 0.90, 0.82])
    col = base[None, None] * (0.94 + 0.06 * n[..., None]) * (0.95 + 0.05 * big[..., None])
    fox = (g.random((h, w)) > 0.9993).astype(float)
    fox = np.asarray(Image.fromarray((fox * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))) / 255
    col = col * (1 - fox[..., None] * 0.5 * np.array([0.3, 0.5, 0.8]))
    Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "paper.png"))
    print("wrote paper")


def tape():
    w, h = 128, 40
    g = rng(41)
    a = np.ones((h, w, 4))
    a[..., :3] = [0.93, 0.89, 0.72]
    a[..., 3] = 0.72 + 0.1 * g.random((h, w))
    for x in range(w):
        for y in range(h):
            if (x < 4 and (y // 3) % 2) or (x > w - 5 and (y // 3 + 1) % 2):
                a[y, x, 3] = 0
    save(Image.fromarray((a * 255).astype(np.uint8), "RGBA"), "tape")


if __name__ == "__main__":
    contact_shadow()
    soft_dot()
    light_shaft()
    blob_puddle()
    stain_decal(51, "stain_a")
    stain_decal(52, "stain_b", (40, 50, 40))
    signs()
    save(stair_sign(), "sign_stairs_down")
    clearance_notice()
    calendar()
    certificate()
    posters()
    mailboxes()
    sky_panorama()
    lion_rock()
    checkerboard_hill()
    paper()
    tape()
