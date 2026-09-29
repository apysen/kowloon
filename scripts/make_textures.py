"""Paint the HD surface library the world shader samples.

Every surface is a tileable set of maps built from a height field, so the
albedo, the normal map and the roughness all agree about where the grout,
the grain and the grime are. Albedos stay light and mostly neutral: the level
tints each piece through the `tint` instance uniform, the same way the
Three.js slice tinted its canvas textures by object colour.

Run from the project root:  python scripts/make_textures.py
Writes assets/textures/surfaces/<name>_{albedo,normal,rough[,emission]}.png
"""

from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "textures", "surfaces")
N = 1024


# ----------------------------------------------------------------------------- noise


def rng(seed: int) -> np.random.Generator:
    return np.random.default_rng(seed)


def spectral(shape, beta: float, seed: int, stretch=(1.0, 1.0), lo: float = 1.0, hi: float | None = None):
    """Periodic fractal noise: white noise shaped by a 1/f^beta spectrum.

    Periodic by construction, so every map tiles. `stretch` squashes the
    spectrum along an axis for grain, brush strokes and streaks.
    """
    h, w = shape
    g = rng(seed)
    white = g.standard_normal((h, w))
    fy = np.fft.fftfreq(h)[:, None] * h / stretch[1]
    fx = np.fft.fftfreq(w)[None, :] * w / stretch[0]
    f = np.sqrt(fx * fx + fy * fy)
    f[0, 0] = 1.0
    amp = 1.0 / np.power(f, beta)
    amp[f < lo] = 0.0
    if hi is not None:
        amp[f > hi] = 0.0
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * amp))
    return norm(out)


def norm(a):
    a = a - a.min()
    m = a.max()
    return a / m if m > 0 else a


def smooth(a, lo, hi):
    t = np.clip((a - lo) / (hi - lo), 0, 1)
    return t * t * (3 - 2 * t)


def blur(a, sigma: float):
    """Periodic gaussian blur through the FFT (keeps tiling intact)."""
    h, w = a.shape[:2]
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.fftfreq(w)[None, :]
    k = np.exp(-2 * (math.pi ** 2) * (sigma ** 2) * (fx * fx + fy * fy))
    if a.ndim == 2:
        return np.real(np.fft.ifft2(np.fft.fft2(a) * k))
    return np.stack([np.real(np.fft.ifft2(np.fft.fft2(a[..., c]) * k)) for c in range(a.shape[2])], -1)


def worley(shape, count: int, seed: int):
    """Periodic cellular noise. Returns (F1, F2, cell index) in pixel units."""
    h, w = shape
    g = rng(seed)
    pts = g.random((count, 2)) * [w, h]
    tree = cKDTree(pts, boxsize=[w, h])
    yy, xx = np.mgrid[0:h, 0:w]
    q = np.stack([xx.ravel() + 0.5, yy.ravel() + 0.5], -1)
    d, i = tree.query(q, k=2)
    return d[:, 0].reshape(h, w), d[:, 1].reshape(h, w), i[:, 0].reshape(h, w)


def cracks(shape, seed: int, count: int = 40, width: float = 1.2, coverage: float = 0.35):
    """Hairline cracks along cell borders, broken up by a mask."""
    f1, f2, _ = worley(shape, count, seed)
    edge = 1.0 - smooth(f2 - f1, 0, width)
    mask = smooth(spectral(shape, 1.6, seed + 1), 1 - coverage, 1 - coverage + 0.12)
    return edge * mask


def normal_map(height, strength: float):
    """OpenGL-convention normal map (green up), which is what Godot expects."""
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 0.5 * strength
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 0.5 * strength
    nx, ny, nz = -dx, dy, np.ones_like(height)
    l = np.sqrt(nx * nx + ny * ny + nz * nz)
    n = np.stack([nx / l, ny / l, nz / l], -1)
    return (n * 0.5 + 0.5)


def color(hexstr: str):
    hexstr = hexstr.lstrip("#")
    return np.array([int(hexstr[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def lerp(a, b, t):
    t = np.asarray(t)
    if t.ndim == 2:
        t = t[..., None]
    return a + (b - a) * t


def save(name: str, albedo, height, strength, rough, emission=None):
    os.makedirs(OUT, exist_ok=True)
    def img(a, mode="RGB"):
        a = np.clip(a, 0, 1)
        return Image.fromarray((a * 255 + 0.5).astype(np.uint8), mode)
    img(albedo).save(os.path.join(OUT, f"{name}_albedo.png"), optimize=True)
    img(normal_map(height, strength)).save(os.path.join(OUT, f"{name}_normal.png"), optimize=True)
    img(np.clip(rough, 0, 1), "L").save(os.path.join(OUT, f"{name}_rough.png"), optimize=True)
    if emission is not None:
        img(emission).save(os.path.join(OUT, f"{name}_emission.png"), optimize=True)
    print("wrote", name)


# ----------------------------------------------------------------------------- shared layers


def grime_streaks(shape, seed, strength=0.35):
    """Water streaks running down a wall, heaviest at the top of each run."""
    h, w = shape
    streak = spectral(shape, 1.2, seed, stretch=(1.0, 14.0))
    streak = smooth(streak, 0.55, 0.9)
    fade = spectral(shape, 2.2, seed + 7)
    return streak * (0.35 + 0.65 * fade) * strength


def dirt(shape, seed, scale_beta=2.0):
    return spectral(shape, scale_beta, seed)


# ----------------------------------------------------------------------------- surfaces


def plaster():
    """Painted plaster, the walls of every flat: brushed, stained, peeling."""
    s = (N, N)
    base = color("#ece7dc")
    under = color("#b3aa9c")
    undulate = spectral(s, 2.4, 11)
    brush = spectral(s, 1.1, 12, stretch=(6.0, 1.0), lo=4)
    peel_src = spectral(s, 1.7, 13, lo=3) * 0.75 + spectral(s, 1.1, 18, lo=12) * 0.25
    peel_mask = smooth(peel_src, 0.80, 0.815)
    peel_edge = smooth(peel_src, 0.785, 0.80) - peel_mask
    crack = cracks(s, 14, 30, 1.0, 0.28)
    streak = grime_streaks(s, 15, 0.30)
    blotch = smooth(dirt(s, 16), 0.55, 0.95)
    speck = rng(17).random(s)

    height = undulate * 0.8 + brush * 0.25 - peel_mask * 1.6 + peel_edge * 0.6 - crack * 0.9
    alb = lerp(base, under, peel_mask * 0.85)
    alb = lerp(alb, color("#7a6a55"), peel_edge * 0.55)
    alb = lerp(alb, color("#8c7c66"), streak)
    alb = lerp(alb, color("#a89880"), blotch * 0.35)
    alb = lerp(alb, color("#4a3e32"), crack * 0.8)
    alb = alb * (0.94 + 0.06 * brush[..., None])
    alb = lerp(alb, color("#5c5046"), (speck > 0.9985).astype(float) * 0.6)
    rough = 0.82 + 0.1 * undulate - 0.08 * streak
    save("plaster", alb, height, 6.0, rough)


def tiles():
    """Glazed ceramic wall tiles (the clinic): 10 cm squares, 1 m per repeat."""
    s = (N, N)
    n = 10
    cell = N / n
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    tx, ty = xx % cell, yy % cell
    ix, iy = (xx // cell).astype(int), (yy // cell).astype(int)
    edge = np.minimum(np.minimum(tx, cell - tx), np.minimum(ty, cell - ty))
    grout = 1.0 - smooth(edge, 2.0, 3.6)
    bevel = smooth(edge, 2.0, 9.0)
    g = rng(21)
    per = g.random((n, n))
    shade = per[iy, ix]
    chips = (g.random((n, n)) < 0.08)[iy, ix] * smooth(spectral(s, 1.4, 22), 0.82, 0.86)
    craze = cracks(s, 23, 90, 0.8, 0.22)
    grime = smooth(dirt(s, 24), 0.4, 1.0)
    wave = spectral(s, 2.8, 25) * 0.35

    alb = np.ones((N, N, 3)) * color("#f1f3ee")
    alb = alb * (0.93 + 0.07 * shade[..., None])
    alb = lerp(alb, color("#cfd3cb"), 1 - bevel)
    alb = lerp(alb, color("#8a8a80"), grout)
    alb = lerp(alb, color("#6d6558"), grout * grime * 0.8)
    alb = lerp(alb, color("#a49c8e"), chips)
    alb = lerp(alb, color("#8c8478"), craze * 0.5)
    height = bevel * 1.0 + wave - chips * 0.6 - craze * 0.2
    rough = 0.16 + 0.12 * shade + grout * 0.7 + chips * 0.5 + grime * 0.08
    save("tiles", alb, height, 9.0, rough)


def mosaic():
    """Small square mosaic tiles, the lower walls of Hong Kong corridors."""
    s = (N, N)
    n = 40
    cell = N / n
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    tx, ty = xx % cell, yy % cell
    ix, iy = (xx // cell).astype(int), (yy // cell).astype(int)
    edge = np.minimum(np.minimum(tx, cell - tx), np.minimum(ty, cell - ty))
    grout = 1.0 - smooth(edge, 0.8, 2.0)
    bevel = smooth(edge, 0.8, 4.0)
    g = rng(31)
    per = g.random((n, n))[iy, ix]
    grime = smooth(dirt(s, 32), 0.35, 1.0)
    alb = np.ones((N, N, 3)) * color("#eef0ea")
    alb = alb * (0.86 + 0.14 * per[..., None])
    alb = lerp(alb, color("#7d7a70"), grout)
    alb = lerp(alb, color("#7a6e5e"), grime * 0.45)
    height = bevel
    rough = 0.25 + 0.2 * per + grout * 0.6
    save("mosaic", alb, height, 5.0, rough)


def floor():
    """Worn terrazzo in 50 cm cement tiles, scuffed where people walk."""
    s = (N, N)
    n = 4
    cell = N / n
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    tx, ty = xx % cell, yy % cell
    ix, iy = (xx // cell).astype(int), (yy // cell).astype(int)
    edge = np.minimum(np.minimum(tx, cell - tx), np.minimum(ty, cell - ty))
    seam = 1.0 - smooth(edge, 1.0, 3.0)
    g = rng(41)
    per = g.random((n, n))[iy, ix]

    f1, f2, idx = worley(s, 5200, 42)
    chip = smooth(f2 - f1, 0.6, 2.2) * (f1 < 3.2 + 2.2 * rng(43).random(5200)[idx])
    chipcol = rng(44).random(5200)[idx]
    wear = smooth(spectral(s, 2.2, 45), 0.3, 1.0)
    alb = np.ones((N, N, 3)) * color("#d9d2c4")
    alb = alb * (0.9 + 0.1 * per[..., None])
    palette = [color("#6b645b"), color("#f3eee4"), color("#a0664a"), color("#4f5a55"), color("#c8b89c")]
    for k, c in enumerate(palette):
        m = chip * ((chipcol * len(palette)).astype(int) == k)
        alb = lerp(alb, c, m * 0.9)
    alb = lerp(alb, color("#6e665a"), seam * 0.8)
    alb = lerp(alb, color("#8a8070"), wear * 0.28)
    height = -seam * 0.8 + spectral(s, 2.6, 46) * 0.3 + chip * 0.08
    rough = 0.48 + 0.25 * wear + seam * 0.3 - chip * 0.1
    save("floor", alb, height, 4.0, rough)


def wood():
    """Varnished floorboards, 12 cm planks running along U."""
    s = (N, N)
    planks = 16
    ph = N / planks
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    row = (yy // ph).astype(int)
    g = rng(51)
    offs = g.random(planks) * N
    lengths = (0.45 + g.random(planks) * 0.5) * N
    tone = g.random(planks)
    local_x = (xx + offs[row]) % lengths[row]
    butt = 1.0 - smooth(np.minimum(local_x, lengths[row] - local_x), 0.5, 2.0)
    ty = yy % ph
    gap = 1.0 - smooth(np.minimum(ty, ph - ty), 0.6, 2.2)

    warp = spectral(s, 2.2, 52) * 18
    grain = np.sin((yy + warp + row * 37.0) * 0.9 + spectral(s, 1.4, 53, stretch=(24, 1)) * 10) * 0.5 + 0.5
    fine = spectral(s, 1.0, 54, stretch=(30, 1), lo=6)
    knots_f1, _, _ = worley(s, 18, 55)
    knot = 1.0 - smooth(knots_f1, 3, 9)

    light = color("#d9b58c")
    dark = color("#8f6440")
    alb = lerp(dark, light, (0.55 * grain + 0.45 * fine) * (0.7 + 0.3 * tone[row]))
    alb = alb * (0.85 + 0.15 * tone[row][..., None])
    alb = lerp(alb, color("#4a2c18"), knot * 0.8)
    alb = lerp(alb, color("#2e1c10"), np.maximum(gap, butt) * 0.85)
    wear = smooth(spectral(s, 2.0, 56), 0.45, 1.0)
    alb = lerp(alb, color("#c8a47e"), wear * 0.18)
    height = fine * 0.25 + grain * 0.12 - np.maximum(gap, butt) * 1.0 - knot * 0.15
    rough = 0.42 + 0.3 * wear + 0.1 * fine + np.maximum(gap, butt) * 0.4
    save("wood", alb, height, 5.0, rough)


def concrete():
    """Board-formed concrete: plank impressions, pores, stains and cracks."""
    s = (N, N)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    boards = 8
    bh = N / boards
    ty = yy % bh
    seam = 1.0 - smooth(np.minimum(ty, bh - ty), 0.8, 3.0)
    g = rng(61)
    tone = g.random(boards)[(yy // bh).astype(int)]
    grainb = spectral(s, 1.2, 62, stretch=(18, 1), lo=3)
    f1, _, _ = worley(s, 2600, 63)
    pore = 1.0 - smooth(f1, 0.5, 1.6)
    pore *= rng(64).random(s) > 0.45
    crack = cracks(s, 65, 26, 1.2, 0.4)
    streak = grime_streaks(s, 66, 0.4)
    blot = smooth(dirt(s, 67), 0.45, 1.0)

    alb = np.ones((N, N, 3)) * color("#cfcbc2")
    alb = alb * (0.9 + 0.08 * tone[..., None] + 0.05 * grainb[..., None])
    alb = lerp(alb, color("#8d877c"), blot * 0.45)
    alb = lerp(alb, color("#6f665a"), streak)
    alb = lerp(alb, color("#5a554e"), seam * 0.5)
    alb = lerp(alb, color("#3c3833"), pore * 0.7)
    alb = lerp(alb, color("#3a342e"), crack * 0.85)
    height = grainb * 0.35 + tone * 0.2 - seam * 0.9 - pore * 0.6 - crack * 1.0 + spectral(s, 2.4, 68) * 0.5
    rough = 0.86 + 0.08 * blot
    save("concrete", alb, height, 6.0, rough)


def tar():
    """Rolled bitumen roofing with gravel, patches and dried puddles."""
    s = (N, N)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    strips = 2
    sw = N / strips
    sx = xx % sw
    lap = 1.0 - smooth(np.minimum(sx, sw - sx), 1.0, 6.0)
    f1, f2, idx = worley(s, 9000, 71)
    grav = smooth(f2 - f1, 0.4, 2.5) * (f1 < 2.8)
    gcol = rng(72).random(9000)[idx]
    patch = smooth(spectral(s, 1.8, 73, lo=3), 0.74, 0.76)
    puddle = smooth(spectral(s, 2.6, 74), 0.7, 0.82)
    blister = smooth(spectral(s, 1.6, 75), 0.8, 0.9)

    alb = np.ones((N, N, 3)) * color("#a7a397")
    alb = lerp(alb, color("#6d6a62"), spectral(s, 2.0, 76) * 0.5)
    alb = lerp(alb, color("#e2ded2"), grav * (gcol > 0.55) * 0.7)
    alb = lerp(alb, color("#4c4a45"), grav * (gcol <= 0.55) * 0.6)
    alb = lerp(alb, color("#5f5c55"), patch * 0.6)
    alb = lerp(alb, color("#7d8286"), puddle * 0.35)
    alb = lerp(alb, color("#3f3c37"), lap * 0.55)
    height = grav * 0.5 + blister * 0.6 - patch * 0.2 + lap * 0.8 + spectral(s, 2.2, 77) * 0.4
    rough = 0.9 - puddle * 0.45 - patch * 0.1
    save("tar", alb, height, 4.0, rough)


def rust():
    """Corrugated sheet metal gone to rust (the tank, hut roofs, shacks)."""
    s = (N, N)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    corr = np.sin(xx / N * 2 * math.pi * 16) * 0.5 + 0.5
    rustmask = smooth(spectral(s, 1.9, 81) * 0.7 + grime_streaks(s, 82, 1.0) * 0.6, 0.45, 0.8)
    pits = (1.0 - smooth(worley(s, 3000, 83)[0], 0.4, 1.6)) * rustmask
    paint = color("#dfe3de")
    alb = lerp(paint, color("#c6cbc6"), 1 - corr)
    alb = lerp(alb, color("#9a5230"), rustmask * 0.9)
    alb = lerp(alb, color("#5e2c16"), pits * 0.8)
    alb = lerp(alb, color("#c47a42"), smooth(spectral(s, 1.2, 84), 0.7, 0.9) * rustmask * 0.6)
    height = corr * 1.2 + rustmask * 0.15 - pits * 0.4
    rough = 0.45 + rustmask * 0.5
    save("rust", alb, height, 10.0, rough)


def metal():
    """Painted steel for doors, frames and railings, chipped to rust at the wear."""
    s = (N, N)
    chip_src = spectral(s, 1.5, 91, lo=4) * 0.7 + spectral(s, 1.0, 96, lo=20) * 0.3
    chip = smooth(chip_src, 0.8, 0.81)
    chip_edge = smooth(chip_src, 0.785, 0.8) - chip
    orange = smooth(spectral(s, 1.4, 92), 0.6, 0.85)
    streak = grime_streaks(s, 93, 0.35)
    alb = np.ones((N, N, 3)) * color("#e8eae6")
    alb = alb * (0.95 + 0.05 * spectral(s, 2.4, 94)[..., None])
    alb = lerp(alb, color("#6b3a22"), chip * (0.6 + 0.4 * orange))
    alb = lerp(alb, color("#9b8c7a"), chip_edge * 0.5)
    alb = lerp(alb, color("#7a6a58"), streak)
    height = -chip * 0.5 + chip_edge * 0.2 + spectral(s, 2.8, 95) * 0.2
    rough = 0.38 + chip * 0.5 + streak * 0.2
    save("metal", alb, height, 4.0, rough)


def fabric():
    """Plain cotton weave, with a little wrinkle."""
    s = (N, N)
    yy, xx = np.mgrid[0:N, 0:N].astype(float)
    wx = np.sin(xx * math.pi / 3.0) * 0.5 + 0.5
    wy = np.sin(yy * math.pi / 3.0) * 0.5 + 0.5
    weave = np.where(((xx // 3 + yy // 3) % 2) == 0, wx, wy)
    wrinkle = spectral(s, 2.2, 101, stretch=(1, 3))
    slub = spectral(s, 1.0, 102, stretch=(40, 1), lo=8)
    alb = np.ones((N, N, 3)) * color("#f4f1ea")
    alb = alb * (0.9 + 0.06 * weave[..., None] + 0.04 * slub[..., None])
    alb = alb * (0.92 + 0.08 * wrinkle[..., None])
    height = weave * 0.3 + wrinkle * 1.5
    rough = 0.95 - 0.05 * weave
    save("fabric", alb, height, 3.0, rough)


def grain():
    """The generic prop surface: faintly mottled, lightly scuffed."""
    s = (N, N)
    mott = spectral(s, 2.0, 111)
    fine = spectral(s, 1.0, 112, lo=10)
    scuff = smooth(spectral(s, 1.3, 113, stretch=(8, 1)), 0.72, 0.85)
    streak = grime_streaks(s, 114, 0.18)
    alb = np.ones((N, N, 3)) * color("#ebe7df")
    alb = alb * (0.9 + 0.07 * mott[..., None] + 0.03 * fine[..., None])
    alb = lerp(alb, color("#c9c1b4"), scuff * 0.4)
    alb = lerp(alb, color("#8a7c68"), streak)
    height = mott * 0.5 + fine * 0.3 - scuff * 0.3
    rough = 0.7 + 0.15 * mott
    save("grain", alb, height, 3.0, rough)


# ----------------------------------------------------------------------------- facades


def draw_rect(a, x0, y0, x1, y1, value):
    x0, x1 = int(round(x0)), int(round(x1))
    y0, y1 = int(round(y0)), int(round(y1))
    a[max(0, y0):max(0, y1), max(0, x0):max(0, x1)] = value


FACADE_W_M = 6.0      # metres per horizontal repeat
FACADE_H_M = 5.0      # metres per vertical repeat (two storeys)


def facade(name, seed, style, painted_cages):
    """A slab of Walled City tower block: 6 m wide, two 2.5 m storeys tall.

    Three bays per storey. Windows are sliding aluminium or old steel frames,
    some frosted, some lit (emission map) with the clutter of a flat behind
    them. Walls are grey render or faded mosaic cladding, streaked black under
    every sill. Near buildings get their cages, air conditioners and balconies
    as real geometry, placed from the window list written next to the maps;
    `painted_cages` paints them flat for the far skyline instead.
    """
    import json
    W = 1024
    H = int(round(W * FACADE_H_M / FACADE_W_M))
    ppm = W / FACADE_W_M
    g = rng(seed)
    s = (H, W)
    yy, xx = np.mgrid[0:H, 0:W].astype(float)

    blot = smooth(spectral(s, 2.1, seed + 1), 0.4, 1.0)
    fine = spectral(s, 1.1, seed + 2, lo=6)
    alb = np.ones(s + (3,)) * color("#c4beb1")
    alb = alb * (0.9 + 0.1 * fine[..., None])
    alb = lerp(alb, color("#8a8274"), blot * 0.45)
    height = fine * 0.3 + spectral(s, 2.4, seed + 3) * 0.4
    rough = np.full(s, 0.88)
    emis = np.zeros((H, W, 3))

    if style in ("tile", "mixed"):
        clad_col = color(["#b9c6c0", "#c9b89a", "#b7a9a6", "#a9b6c4", "#d0c7ae"][seed % 5])
        cell = 0.05 * ppm
        m = ((xx % cell) < 1.3) | ((yy % cell) < 1.3)
        per = rng(seed + 9).random((int(H / cell) + 2, int(W / cell) + 2))
        tone = per[(yy // cell).astype(int), (xx // cell).astype(int)]
        clad = np.ones(s + (3,)) * clad_col * (0.9 + 0.12 * tone[..., None])
        clad = lerp(clad, color("#77736a"), m.astype(float) * 0.55)
        region = np.ones(s)
        if style == "mixed":
            region = (yy > H * 0.5).astype(float)          # tiled lower storey only
        loss = smooth(spectral(s, 1.8, seed + 10, lo=3), 0.78, 0.8)   # fallen tiles
        region = region * (1 - loss)
        alb = lerp(alb, clad, region * 0.92)
        height = height + region * (~m) * 0.25 - loss * 0.3
        rough = rough - region * 0.45 * (~m)

    for _ in range(3):   # repair patches in fresher render
        px, py = g.random() * W, g.random() * H
        pw, ph_ = (0.4 + g.random() * 0.9) * ppm, (0.3 + g.random() * 0.6) * ppm
        draw_rect(alb, px, py, px + pw, py + ph_, color("#d2cdc2") * (0.95 + 0.05 * g.random()))

    windows = []
    storey = H / 2
    bay = W / 3
    for j in range(2):
        slab = (j + 1) * storey
        draw_rect(alb, 0, slab - 0.12 * ppm, W, slab, color("#6d675d"))
        draw_rect(height, 0, slab - 0.12 * ppm, W, slab, 1.4)
        for i in range(3):
            kind = g.random()
            ww = (1.05 + g.random() * 0.35) * ppm
            wh = (1.0 + g.random() * 0.2) * ppm
            cx = i * bay + bay * 0.5 + (g.random() - 0.5) * 0.3 * ppm
            wx0, wx1 = cx - ww / 2, cx + ww / 2
            wy0 = j * storey + 0.55 * ppm
            wy1 = wy0 + wh
            lit = g.random() < 0.3
            fluoro = g.random() < 0.55
            windows.append({
                "x0": wx0 / ppm, "x1": wx1 / ppm,
                "y0": (H - wy1) / ppm, "y1": (H - wy0) / ppm,   # metres, bottom-up
                "lit": bool(lit), "storey": 1 - j, "bay": i,
            })
            draw_rect(height, wx0 - 6, wy0 - 6, wx1 + 6, wy1 + 6, -0.4)
            draw_rect(height, wx0, wy0, wx1, wy1, -1.6)
            draw_rect(alb, wx0 - 8, wy1, wx1 + 8, wy1 + 0.07 * ppm, color("#9c968a"))
            draw_rect(height, wx0 - 8, wy1, wx1 + 8, wy1 + 0.07 * ppm, 1.0)
            for sx in (wx0 - 6, wx1 + 2):   # grime running down from the sill
                run = (0.6 + g.random() * 1.1) * ppm
                t = np.clip((yy - wy1) / run, 0, 1)
                band_ = (np.abs(xx - sx) < 3 + 5 * t) & (yy > wy1) & (yy < wy1 + run)
                alb = lerp(alb, color("#3c352c"), band_ * (1 - t) * 0.55)
            panes = 2 if kind < 0.5 else 4
            if lit:
                glow = color("#e9f4ea") if fluoro else color("#ffcf8a")
                draw_rect(alb, wx0, wy0, wx1, wy1, glow * 0.85)
                draw_rect(emis, wx0, wy0, wx1, wy1, glow)
                inner = g.integers(4)
                if inner == 0:
                    for k in range(3):
                        y = wy0 + (k + 1) * wh / 4
                        draw_rect(alb, wx0, y, wx1, y + 5, color("#4a3a2c"))
                        draw_rect(emis, wx0, y, wx1, y + 5, glow * 0.15)
                elif inner == 1:
                    for k in range(4):
                        x = wx0 + 8 + k * ww / 4
                        c = color(["#a8534a", "#3f6fa8", "#e8e2d4", "#6f7d62"][g.integers(4)])
                        draw_rect(alb, x, wy0 + 6, x + ww / 6, wy0 + wh * (0.45 + g.random() * 0.2), c * 0.7)
                        draw_rect(emis, x, wy0 + 6, x + ww / 6, wy0 + wh * 0.6, glow * 0.25)
                else:
                    cw_ = ww * (0.25 + g.random() * 0.3)
                    curtain = color(["#8a5a3a", "#6f7d62", "#a8534a", "#c9a55a", "#d8c9a8"][g.integers(5)])
                    cx0 = wx0 if g.random() < 0.5 else wx1 - cw_
                    folds = (np.sin((xx - cx0) * 0.35) * 0.5 + 0.5)
                    region = (xx >= cx0) & (xx < cx0 + cw_) & (yy >= wy0) & (yy < wy1)
                    alb = lerp(alb, curtain * 0.9, region * (0.8 + 0.2 * folds))
                    emis = lerp(emis, glow * 0.4 * curtain, region.astype(float))
            else:
                frosted = g.random() < 0.3
                glass = color("#9fb2ad") if frosted else (color("#26303a") if g.random() < 0.5 else color("#3a4650"))
                draw_rect(alb, wx0, wy0, wx1, wy1, glass)
                if not frosted:   # sky caught in the glass
                    t = np.clip((yy - wy0) / wh, 0, 1)
                    region = (xx >= wx0) & (xx < wx1) & (yy >= wy0) & (yy < wy1)
                    alb = lerp(alb, color("#8397a8"), region * (1 - t) * 0.45)
            rough[int(wy0):int(wy1), int(wx0):int(wx1)] = 0.1
            frame = color("#b9bcb8") if kind < 0.6 else color("#3e4a44")
            for k in range(panes + 1):
                x = wx0 + (wx1 - wx0) * k / panes
                draw_rect(alb, x - 3, wy0, x + 3, wy1, frame)
                draw_rect(height, x - 3, wy0, x + 3, wy1, -0.6)
                draw_rect(emis, x - 3, wy0, x + 3, wy1, 0)
            for y in (wy0, (wy0 + wy1) / 2 if kind > 0.8 else None, wy1 - 5):
                if y is None:
                    continue
                draw_rect(alb, wx0, y, wx1, y + 5, frame)
                draw_rect(emis, wx0, y, wx1, y + 5, 0)
            if painted_cages and g.random() < 0.8:
                c0, c1 = wx0 - 14, wx1 + 14
                r0, r1 = wy0 - 12, wy1 + 20
                cage = color("#47443e") if g.random() < 0.6 else color("#6a5a48")
                bars = 8 + int(g.integers(4))
                for k in range(bars + 1):
                    x = c0 + (c1 - c0) * k / bars
                    draw_rect(alb, x - 2, r0, x + 2, r1, cage)
                    draw_rect(height, x - 2, r0, x + 2, r1, 1.8)
                    draw_rect(emis, x - 2, r0, x + 2, r1, 0)
                for y in (r0, (r0 + r1) / 2, r1 - 5):
                    draw_rect(alb, c0, y, c1, y + 5, cage)
                    draw_rect(height, c0, y, c1, y + 5, 2.0)
                    draw_rect(emis, c0, y, c1, y + 5, 0)
                if g.random() < 0.5:
                    ax0 = cx - 0.3 * ppm
                    draw_rect(alb, ax0, r1, ax0 + 0.6 * ppm, r1 + 0.4 * ppm, color("#d4d2ca"))
                    draw_rect(height, ax0, r1, ax0 + 0.6 * ppm, r1 + 0.4 * ppm, 2.4)

    px = g.random() * W   # a drainpipe, and wiring stapled along the wall
    draw_rect(alb, px, 0, px + 0.1 * ppm, H, color("#5e5850"))
    draw_rect(height, px, 0, px + 0.1 * ppm, H, 1.6)
    draw_rect(emis, px, 0, px + 0.1 * ppm, H, 0)
    for _ in range(3):
        y = g.random() * H
        draw_rect(alb, 0, y, W, y + 3, color("#2a2826"))
        draw_rect(emis, 0, y, W, y + 3, 0)
    streak = grime_streaks(s, seed + 5, 0.5)
    lit_mask = emis.sum(-1) > 0.05
    alb = lerp(alb, color("#4e463c"), streak * (~lit_mask))
    height = blur(height, 0.8)
    save(name, alb, height, 3.0, rough, emis)
    with open(os.path.join(OUT, f"{name}.json"), "w") as f:
        json.dump({"width_m": FACADE_W_M, "height_m": FACADE_H_M, "windows": windows}, f, indent=1)


def concrete_base(s, seed):
    blot = smooth(spectral(s, 2.1, seed + 1), 0.4, 1.0)
    fine = spectral(s, 1.1, seed + 2, lo=6)
    alb = np.ones(s + (3,)) * color("#c9c3b6")
    alb = alb * (0.9 + 0.1 * fine[..., None])
    alb = lerp(alb, color("#8a8274"), blot * 0.5)
    height = fine * 0.3 + spectral(s, 2.4, seed + 3) * 0.4
    return alb, height


# ----------------------------------------------------------------------------- main


SURFACES = {
    "plaster": plaster,
    "tiles": tiles,
    "mosaic": mosaic,
    "floor": floor,
    "wood": wood,
    "concrete": concrete,
    "tar": tar,
    "rust": rust,
    "metal": metal,
    "fabric": fabric,
    "grain": grain,
    "facade_a": lambda: facade("facade_a", 201, "plain", False),
    "facade_b": lambda: facade("facade_b", 202, "tile", False),
    "facade_c": lambda: facade("facade_c", 203, "mixed", False),
    "facade_d": lambda: facade("facade_d", 204, "tile", False),
    "facade_far": lambda: facade("facade_far", 205, "mixed", True),
}


if __name__ == "__main__":
    wanted = sys.argv[1:] or list(SURFACES)
    for name in wanted:
        SURFACES[name]()
