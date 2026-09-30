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


# ----------------------------------------------------------------------------- the water (Chapter 2)


def _motor(secs, f_from, f_to, level_from, level_to):
    """An electric pump motor: a hum with its harmonics and a whine, the speed
    and loudness gliding between two settings."""
    t = t_axis(secs)
    f = np.interp(t, [0, secs], [f_from, f_to])
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.25 * np.sin(3 * ph) + 0.12 * np.sin(7 * ph)
    x = x + 0.25 * biquad(rng.standard_normal(len(t)), "band", 1200, 3)
    return x * np.interp(t, [0, secs], [level_from, level_to])


def pump():
    # starting: the motor winding up, catching
    up = _motor(1.6, 20, 50, 0.0, 1.0)
    save("pump_start", up * env(len(up), 0.02, 0.1), 0.55)
    # stalling: it labours, a clunk, and winds down
    down = _motor(1.8, 50, 12, 1.0, 0.0)
    down[:int(0.08 * SR)] += click(160, 0.08, 1.5) * 3
    save("pump_stall", down, 0.55)
    # running steadily, looped
    run = _motor(4.0, 50, 50, 1.0, 1.0)
    save("pump_run", loop_crossfade(run, 0.5), 0.4)


def knock():
    """The pipe knocking as the pump pushes against a shut valve: a dull metal
    thud with a short ring."""
    for k in range(3):
        n = int(0.35 * SR)
        thud = click(140 + k * 25, 0.35, 1.2) * 2
        ring = tone(520 + k * 60, 0.35, "sine", attack=0.001) * 0.35
        save(f"knock_{k}", (thud + ring) * env(n, 0.001, 0.2), 0.7)


def valve():
    """A stiff valve wheel turning: metal squeal and grind."""
    t = t_axis(0.9)
    f = 900 + 140 * np.sin(2 * np.pi * 5 * t)
    ph = 2 * np.pi * np.cumsum(f) / SR
    squeal = np.sin(ph) * (0.4 + 0.6 * (np.sin(2 * np.pi * 3 * t) > 0))
    grind = biquad(rng.standard_normal(len(t)), "band", 2600, 2) * 0.6
    save("valve", (squeal * 0.5 + grind) * env(len(t), 0.03, 0.2), 0.45)


def _water(secs, lo, hi, gain_curve):
    x = rng.standard_normal(int(secs * SR))
    x = biquad(biquad(x, "high", lo), "low", hi)
    return x * gain_curve(t_axis(secs))


def water():
    # water let loose somewhere upstairs: a burst, then spattering
    save("splash", _water(1.6, 500, 7000, lambda t: np.exp(-2.2 * t) + 0.25 * (t < 1.2)), 0.7)
    # the old sink coughing up rust: gulps of air, then a brown spurt
    gulps = np.zeros(int(1.6 * SR))
    for k, at in enumerate([0.0, 0.35, 0.62, 0.9]):
        g = tone(120 + 30 * k, 0.22, "sine", glide=-0.8, attack=0.005) * 1.4
        i = int(at * SR)
        gulps[i:i + len(g)] += g[:len(gulps) - i]
    spurt = _water(1.6, 300, 3000, lambda t: np.clip((t - 1.0) * 3, 0, 1) * np.exp(-2.5 * np.clip(t - 1.0, 0, None)))
    save("sink_cough", gulps + spurt, 0.6)
    # water back in the pipes: a rising rush
    save("water_rush", _water(2.4, 200, 2400, lambda t: np.clip(t / 0.8, 0, 1) * np.exp(-0.6 * np.clip(t - 0.8, 0, None))), 0.6)
    # a basin filling under a tap, looped
    fill = _water(3.0, 900, 5000, lambda t: 0.8 + 0.2 * np.sin(2 * np.pi * 0.7 * t))
    save("tap_run", loop_crossfade(fill, 0.4), 0.35)
    # a kettle beginning to sing
    t = t_axis(2.2)
    sing = np.sin(2 * np.pi * np.cumsum(np.interp(t, [0, 2.2], [1800, 2300])) / SR) * np.clip((t - 0.8) / 1.0, 0, 1)
    save("kettle", sing * 0.4 + _water(2.2, 1500, 6000, lambda t: 0.3 * np.ones_like(t)), 0.35)
    # a cistern flushing, and refilling
    save("flush", _water(2.8, 150, 2000, lambda t: np.exp(-1.5 * t) + 0.3 * np.exp(-0.5 * np.clip(t - 1.2, 0, None)) * (t > 1.2)), 0.6)


# ----------------------------------------------------------------------------- the workshop (Chapter 3)


def workshop():
    # fish paste thrown down on a steel table and beaten: a wet, heavy thump
    for k in range(3):
        n = int(0.4 * SR)
        body = click(90 + k * 18, 0.4, 0.9) * 3
        slap = biquad(rng.standard_normal(n), "band", 1400 + k * 200, 1.5) * np.exp(-np.linspace(0, 30, n)) * 1.2
        save(f"thump_{k}", (body + slap) * env(n, 0.001, 0.25), 0.8)
    # the steamer's hiss, looped
    hiss = biquad(biquad(rng.standard_normal(4 * SR), "high", 3000), "low", 9000)
    hiss = hiss * (0.8 + 0.2 * np.sin(2 * np.pi * 0.4 * t_axis(4)))
    save("steam_loop", loop_crossfade(hiss, 0.5), 0.3)
    # a winch paying out: ratchet clicks, slowing
    x = np.zeros(int(1.4 * SR))
    at = 0.0
    gap = 0.07
    while at < 1.3:
        c = click(3200, 0.03, 4) * 1.5 + click(900, 0.03, 2)
        i = int(at * SR)
        x[i:i + len(c)] += c[:len(x) - i]
        at += gap
        gap *= 1.06
    save("ratchet", x, 0.6)
    # a crate set down on boards
    n = int(0.35 * SR)
    knock_ = np.pad(click(700, 0.1, 2) * 0.6, (0, n - int(0.1 * SR)))
    save("crate_down", (click(160, 0.35, 1.0) * 2 + knock_[:n]) * env(n, 0.001, 0.2), 0.7)


# ----------------------------------------------------------------------------- chapter 4: the yamen


def yamen():
    """Open ground after the lanes: a wide, soft air with the traffic outside
    the walls, and sparrows in the one tree. A tape gun and a heavy cabinet
    set down, for the movers."""
    secs = 18
    t = t_axis(secs)
    n = rng.standard_normal(len(t))
    air = (fast_lowpass(n, 1400) - fast_lowpass(n, 300)) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.07 * t))
    x = air * 0.8 + fast_lowpass(brown(len(t)), 160) * 0.45
    # sparrows: short bright chirps in little runs
    for k in range(26):
        at = rng.uniform(0.2, secs - 0.6)
        for j in range(int(rng.integers(2, 5))):
            f0 = rng.uniform(3600, 5200)
            c = tone(f0, 0.05, "sine", glide=rng.uniform(-0.3, 0.3), attack=0.004)
            i = int((at + j * rng.uniform(0.07, 0.12)) * SR)
            if i + len(c) < len(x):
                x[i:i + len(c)] += c * rng.uniform(0.08, 0.18)
    save("yamen_air", loop_crossfade(x, 1.2), 0.5)
    # the movers' tape gun
    tt = t_axis(0.5)
    rip = rng.standard_normal(len(tt)) * (0.6 + 0.4 * np.sin(2 * np.pi * 90 * tt)) * env(len(tt), 0.01, 0.1)
    save("tape_gun", biquad(rip, "bandpass", 2400, 1.2), 0.45)
    # a cabinet set down on flagstones
    n2 = int(0.5 * SR)
    knock_ = np.pad(click(420, 0.12, 2) * 0.5, (int(0.03 * SR), n2))[:n2]
    thud = click(95, 0.5, 0.9)[:n2] * 2.2 + knock_
    save("cabinet_down", thud[:n2] * env(n2, 0.002, 0.3), 0.75)


# ----------------------------------------------------------------------------- chapter 5: rooms going quiet


def quiet_rooms():
    """What is left to hear. Water in the pipes: a low steady hum with a slow
    swell, faint trickle over it (the building's pipes still full everywhere
    but one wing). A wooden peg falling on steel grating. A mahjong tile let
    fall into a biscuit tin. An envelope opened and a note unfolded."""
    secs = 10
    t = t_axis(secs)
    hum = fast_lowpass(brown(len(t)), 120) * 0.9
    hum += 0.05 * np.sin(2 * np.pi * 61 * t) + 0.02 * np.sin(2 * np.pi * 122 * t + 0.4)
    trickle = biquad(biquad(rng.standard_normal(len(t)), "high", 1400), "low", 4200)
    trickle *= 0.08 * (0.6 + 0.4 * np.sin(2 * np.pi * 0.31 * t) * np.sin(2 * np.pi * 0.07 * t + 1.3))
    save("pipe_hum", loop_crossfade((hum + trickle) * (1 + 0.1 * np.sin(2 * np.pi * 0.13 * t)), 1.0), 0.5)
    # the peg: a small hard tick, then a second, smaller bounce
    n = int(0.5 * SR)
    x = np.zeros(n)
    for at, g in [(0.0, 1.0), (0.13, 0.45), (0.21, 0.18)]:
        c = click(2600, 0.05, 3) * g + click(900, 0.05, 2) * g * 0.5
        i = int(at * SR)
        x[i:i + len(c)] += c[:n - i]
    save("peg_drop", x, 0.5)
    # a tile into a tin: a bright clink with a tinny ring
    n = int(0.6 * SR)
    ring = sum(tone(f, 0.6, "sine", attack=0.001) * a for f, a in [(1860, 0.5), (2710, 0.35), (4130, 0.2)])
    ring = ring[:n] * np.exp(-np.linspace(0, 9, n))
    tick = np.pad(click(3200, 0.03, 3), (0, n))[:n]
    save("tile_tin", tick + ring, 0.55)
    # paper: an envelope torn along its flap, a sheet unfolded
    tt = t_axis(0.9)
    tear = rng.standard_normal(len(tt)) * (0.5 + 0.5 * (rng.random(len(tt)) > 0.97))
    tear = biquad(tear, "band", 3200, 0.9) * env(len(tt), 0.02, 0.3)
    save("paper", tear, 0.35)


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
    pump()
    knock()
    valve()
    water()
    workshop()
    yamen()
    quiet_rooms()
