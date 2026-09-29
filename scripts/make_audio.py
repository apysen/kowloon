"""Render the slice's soundscape to WAV files.

The Three.js slice synthesised all of its sound live in WebAudio; these are the
same recipes rendered offline for Godot: two ambient beds (the building's hum,
the wind on the roof), the places you hear before you see them (Grandfather's
radio, Lau's drill, the mahjong table, chopping, drips, a neighbour's TV, the
pigeons, children somewhere below), and the one-shots (shutter, chime,
footsteps, creak, flutter, dialogue blip, and the jet on its approach to Kai Tak).

Run from the project root:  python scripts/make_audio.py
Writes assets/audio/*.wav (mono, 44.1 kHz, 16-bit).
"""

from __future__ import annotations

import os
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
SR = 44100
rng = np.random.default_rng(1993)


def t_axis(secs):
    return np.arange(int(secs * SR)) / SR


def save(name, x, peak=0.8):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
    print("wrote", name)


def env(n, attack, release, curve=2.0):
    e = np.ones(n)
    a = int(attack * SR)
    r = int(release * SR)
    if a:
        e[:a] = np.linspace(0, 1, a) ** curve
    if r:
        e[-r:] *= np.linspace(1, 0, r) ** curve
    return e


def biquad(x, kind, f0, q=0.707):
    """RBJ biquad filter."""
    w0 = 2 * np.pi * f0 / SR
    alpha = np.sin(w0) / (2 * q)
    c = np.cos(w0)
    if kind == "low":
        b = [(1 - c) / 2, 1 - c, (1 - c) / 2]
        a = [1 + alpha, -2 * c, 1 - alpha]
    elif kind == "high":
        b = [(1 + c) / 2, -(1 + c), (1 + c) / 2]
        a = [1 + alpha, -2 * c, 1 - alpha]
    else:  # band
        b = [alpha, 0, -alpha]
        a = [1 + alpha, -2 * c, 1 - alpha]
    b = np.array(b) / a[0]
    a = np.array(a) / a[0]
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i in range(len(x)):
        xi = x[i]
        yi = b[0] * xi + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2
        x2, x1 = x1, xi
        y2, y1 = y1, yi
        y[i] = yi
    return y


def fast_lowpass(x, f0):
    """One-pole lowpass (vectorised enough for long beds)."""
    k = 1 - np.exp(-2 * np.pi * f0 / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += k * (x[i] - acc)
        y[i] = acc
    return y


def brown(n):
    w = rng.standard_normal(n)
    b = np.cumsum(w)
    b -= np.convolve(b, np.ones(4410) / 4410, mode="same")
    return b / (np.max(np.abs(b)) or 1)


def loop_crossfade(x, secs=0.5):
    n = int(secs * SR)
    head = x[:n].copy()
    body = x[n:].copy()
    body[-n:] = body[-n:] * np.linspace(1, 0, n) + head * np.linspace(0, 1, n)
    return body


def tone(freq, secs, kind="sine", glide=0.0, attack=0.01):
    t = t_axis(secs)
    f = freq * (1 - glide * 0.5 * t / secs)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if kind == "sine":
        s = np.sin(ph)
    elif kind == "triangle":
        s = 2 / np.pi * np.arcsin(np.sin(ph))
    elif kind == "square":
        s = np.sign(np.sin(ph))
    else:
        s = 2 * ((ph / (2 * np.pi)) % 1) - 1
    e = np.exp(-4.5 * t / secs) * np.clip(t / attack, 0, 1)
    return s * e


def click(freq, secs=0.03, q=3.0):
    n = int(secs * SR)
    x = rng.standard_normal(n) * np.exp(-np.linspace(0, 8, n))
    return biquad(x, "band", freq, q)


# ----------------------------------------------------------------------------- beds


def interior_hum():
    secs = 12
    x = fast_lowpass(brown(secs * SR), 260) * 0.8
    t = t_axis(secs)
    x += 0.07 * np.sin(2 * np.pi * 50 * t) + 0.025 * np.sin(2 * np.pi * 100 * t + 0.3)
    # a distant fan's slow beat
    x *= 1 + 0.08 * np.sin(2 * np.pi * 0.21 * t)
    save("interior_hum", loop_crossfade(x, 1.0), 0.6)


def roof_wind():
    secs = 16
    t = t_axis(secs)
    n = rng.standard_normal(len(t))
    gust = 0.55 + 0.45 * np.sin(2 * np.pi * 0.12 * t) * np.sin(2 * np.pi * 0.047 * t + 1)
    lo = fast_lowpass(n, 900) - fast_lowpass(n, 250)
    x = lo * gust * 1.4
    x += fast_lowpass(brown(len(t)), 180) * 0.35      # traffic far below
    save("roof_wind", loop_crossfade(x, 1.5), 0.6)


# ----------------------------------------------------------------------------- places


def radio():
    """A tinny pentatonic tune through a small speaker, with hiss."""
    notes = [392, 440, 523, 587, 659, 587, 523, 440, 392, 330, 392, 440]
    step = 0.42
    total = step * len(notes) * 2
    out = np.zeros(int(total * SR) + SR)
    for k in range(len(notes) * 2):
        f = notes[k % len(notes)]
        s = tone(f, 0.38, "triangle") * 0.18
        if k % 3 == 0:
            s2 = tone(f / 2, 0.6, "sine") * 0.1
            i = int(k * step * SR)
            out[i:i + len(s2)] += s2
        i = int(k * step * SR)
        out[i:i + len(s)] += s
    out = out[:int(total * SR)]
    out = biquad(out, "band", 1300, 0.9) * 3.0
    out += biquad(rng.standard_normal(len(out)), "high", 3000) * 0.012
    save("radio_loop", out, 0.5)


def drill():
    """Lau's drill heard through the clinic wall: a low, soft motor hum with a
    gentle rise and fall, not a whine (the old high buzz was hard on the ears)."""
    for k in range(3):
        dur = 0.6 + k * 0.5
        t = t_axis(dur)
        f = 520 + 18 * np.sin(2 * np.pi * 7 * t) + rng.uniform(-30, 30)
        ph = 2 * np.pi * np.cumsum(f) / SR
        body = np.sin(ph) * 0.7 + np.sin(2 * ph) * 0.2 + np.sin(3 * ph) * 0.06
        x = fast_lowpass(body, 1400) * env(len(t), 0.08, 0.12)
        save(f"drill_{k}", x, 0.3)


def mahjong():
    for k in range(4):
        n = 1 + k % 3
        out = np.zeros(int(0.5 * SR))
        for j in range(n):
            c = click(2800 + rng.uniform(0, 1500), 0.025)
            i = int(j * 0.07 * SR)
            out[i:i + len(c)] += c * (0.8 + 0.2 * rng.random())
        save(f"mahjong_{k}", out, 0.7)


def chop():
    for k in range(3):
        c = click(900 + k * 80, 0.04, 1.5)
        body = tone(160 + k * 10, 0.06, "sine") * 0.4
        x = np.zeros(max(len(c), len(body)))
        x[:len(c)] += c
        x[:len(body)] += body
        save(f"chop_{k}", x, 0.7)


def drips():
    for k in range(3):
        x = tone(1400 + k * 260, 0.09, "sine", glide=0.6, attack=0.002)
        save(f"drip_{k}", x, 0.5)


def tv():
    """A neighbour's television through the wall: murmured voices, music."""
    secs = 10
    out = np.zeros(int(secs * SR))
    t = 0.0
    while t < secs - 0.4:
        d = 0.12 + rng.random() * 0.3
        s = tone(180 + rng.random() * 220, d, "square") * 0.05
        i = int(t * SR)
        out[i:i + len(s)] += s
        t += d * (0.6 + rng.random() * 0.8)
    out = biquad(out, "band", 700, 1.5) * 4
    save("tv_loop", loop_crossfade(out, 0.3), 0.35)


def coo():
    for k in range(3):
        secs = 0.6
        t = t_axis(secs)
        base = 260 + k * 25
        f = np.interp(t, [0, 0.15, 0.5, secs], [base, base * 1.25, base * 0.9, base * 0.85])
        ph = 2 * np.pi * np.cumsum(f) / SR
        am = 0.5 + 0.5 * np.sin(2 * np.pi * 28 * t)
        x = np.sin(ph) * am * env(len(t), 0.08, 0.1)
        save(f"coo_{k}", x, 0.5)


def kids():
    for k in range(2):
        base = 700 + k * 150
        out = np.zeros(int(0.6 * SR))
        for j in range(3):
            s = tone(base + j * 60, 0.12, "triangle")
            i = int(j * 0.14 * SR)
            out[i:i + len(s)] += s
        save(f"kids_{k}", out, 0.3)


# ----------------------------------------------------------------------------- one-shots


def shutter():
    out = np.zeros(int(0.7 * SR))
    for (f, d, at) in [(3000, 0.03, 0.0), (1800, 0.05, 0.06)]:
        c = click(f, d)
        i = int(at * SR)
        out[i:i + len(c)] += c
    w = tone(160, 0.5, "saw", glide=0.1) * 0.12      # the film motor whirring the print out
    i = int(0.15 * SR)
    out[i:i + len(w)] += biquad(w, "low", 900)
    save("shutter", out, 0.8)


def chime():
    a = tone(660, 0.9, "sine")
    b = tone(990, 1.1, "sine") * 0.6
    out = np.zeros(int(1.3 * SR))
    out[:len(a)] += a
    i = int(0.12 * SR)
    out[i:i + len(b)] += b
    save("chime", out, 0.5)


def footsteps():
    for k in range(4):
        c = click(350 + k * 35, 0.05, 1.2)
        body = tone(90, 0.05, "sine") * 0.5
        x = np.zeros(max(len(c), len(body)))
        x[:len(c)] += c
        x[:len(body)] += body
        save(f"step_{k}", x, 0.6)


def creak():
    t = t_axis(0.55)
    f = 140 * (1 - 0.2 * t / 0.55) + 8 * np.sin(2 * np.pi * 11 * t)
    ph = 2 * np.pi * np.cumsum(f) / SR
    saw = 2 * ((ph / (2 * np.pi)) % 1) - 1
    x = biquad(saw, "band", 600, 1.2) * env(len(t), 0.05, 0.15)
    save("creak", x, 0.5)


def flutter():
    out = np.zeros(int(1.0 * SR))
    for j in range(14):
        c = click(1200 + rng.uniform(0, 400), 0.03, 2)
        i = int(j * 0.05 * SR)
        out[i:i + len(c)] += c * (1 - j / 16)
    save("flutter", out, 0.6)


def blip():
    save("blip", tone(440, 0.06, "sine", attack=0.004), 0.35)


def click_ui():
    save("camera_up", click(2200, 0.02, 2) + np.pad(click(1400, 0.03, 2), (int(0.04 * SR), 0))[:int(0.02 * SR)], 0.5)


def album():
    """The scrapbook: a stiff album page turning, the cover opening, the book shut."""
    # a page: a soft swish of paper, rising and falling, with a crackle as it lifts and lands
    secs = 0.5
    n = int(secs * SR)
    swish = biquad(rng.standard_normal(n), "band", 2600, 0.6)
    t = t_axis(secs)
    shape = np.sin(np.pi * np.clip(t / secs, 0, 1)) ** 1.6
    x = swish * shape * 0.5
    for at in (0.03, 0.06, 0.41, 0.44):
        c = click(3000 + rng.uniform(-500, 500), 0.012, 1.5) * 0.35
        i = int(at * SR)
        x[i:i + len(c)] += c[:len(x) - i]
    save("page_flip", x, 0.45)
    # the cover: the board lifting off the pages, the spine giving a little
    secs = 0.7
    n = int(secs * SR)
    x = biquad(rng.standard_normal(n), "band", 1400, 0.7) * np.sin(np.pi * np.clip(t_axis(secs) / secs, 0, 1)) ** 2 * 0.35
    cr = biquad(tone(95, 0.25, "saw"), "band", 700, 2.0) * env(int(0.25 * SR), 0.03, 0.12) * 0.25
    x[:len(cr)] += cr
    thud = tone(70, 0.18, "sine") * env(int(0.18 * SR), 0.002, 0.15)
    i = int(0.55 * SR)
    x[i:i + len(thud)] += thud[:len(x) - i] * 0.8
    save("book_open", x, 0.5)
    # shut: a push of air and a soft thump of board on board
    secs = 0.5
    n = int(secs * SR)
    x = biquad(rng.standard_normal(n), "low", 900) * env(n, 0.2, 0.3) * 0.3
    thud = tone(62, 0.22, "sine") * env(int(0.22 * SR), 0.002, 0.2)
    knock = click(420, 0.04, 1.0) * 0.5
    thud[:len(knock)] += knock
    i = int(0.24 * SR)
    x[i:i + len(thud)] += thud[:len(x) - i]
    save("book_close", x, 0.6)
    # tape: pulled off the roll and pressed down
    secs = 0.22
    n = int(secs * SR)
    rip = biquad(rng.standard_normal(n), "high", 2200) * env(n, 0.005, 0.12, 1.2)
    grain = np.where(rng.random(n) > 0.985, rng.standard_normal(n) * 2.0, 0.0)
    x = rip * 0.5 + biquad(grain, "band", 3500, 1.0) * env(n, 0.0, 0.1)
    save("tape_press", x, 0.4)
    # a pen on paper: short scratchy strokes
    secs = 1.1
    n = int(secs * SR)
    t = t_axis(secs)
    strokes = (np.sin(2 * np.pi * 5.5 * t + 1.3 * np.sin(2 * np.pi * 1.7 * t)) > -0.2).astype(float)
    strokes = fast_lowpass(strokes, 40)
    x = biquad(rng.standard_normal(n), "band", 4200, 1.4) * strokes * env(n, 0.03, 0.1)
    save("pen_scribble", x, 0.28)


def plane():
    """A four-engined jet low over Kowloon City on its approach to Kai Tak."""
    secs = 7.5
    t = t_axis(secs)
    rise = np.interp(t, [0, 2.6, secs], [0.0, 1.0, 0.0]) ** 1.6
    cutoff = np.interp(t, [0, 2.6, secs], [200, 700, 150])
    roar = brown(len(t))
    # time-varying lowpass: process in blocks
    out = np.zeros_like(roar)
    blk = 2048
    acc = 0.0
    for s in range(0, len(t), blk):
        k = 1 - np.exp(-2 * np.pi * cutoff[s] / SR)
        for i in range(s, min(len(t), s + blk)):
            acc += k * (roar[i] - acc)
            out[i] = acc
    whine_f = np.interp(t, [0, secs], [900, 760])
    ph = 2 * np.pi * np.cumsum(whine_f) / SR
    whine = biquad(2 * ((ph / (2 * np.pi)) % 1) - 1, "band", 900, 4) * 0.08
    x = (out * 1.6 + whine) * rise
    save("plane", x, 0.9)


if __name__ == "__main__":
    interior_hum()
    roof_wind()
    radio()
    drill()
    mahjong()
    chop()
    drips()
    tv()
    coo()
    kids()
    shutter()
    chime()
    footsteps()
    creak()
    flutter()
    blip()
    click_ui()
    plane()
    album()
