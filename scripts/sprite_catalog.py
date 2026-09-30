"""The cast: palettes, looks and animations, assembled from the hand-drawn parts.

This decides *which* hand-drawn parts make each frame and where they sit;
every pixel operation (palette swap, outlining, compositing, layers, tags,
export) happens in Aseprite, in tools/aseprite/build_characters.lua.

Run from the project root:  python scripts/sprite_catalog.py
Writes assets/sprites/aseprite/build/doll.json. Then run the Lua builder
through Aseprite (see tools/aseprite/README.md).
"""

from __future__ import annotations

import colorsys
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sprite_parts as P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites", "aseprite", "build")

VIEWS = ("front", "back", "side")

# ============================================================================= palettes


def _hex(rgb):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(c)))) for c in rgb)


def _parse(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def ramp(base: str):
    """Four tones: highlight, base, shade, deep. Highlights lean warm and a
    touch less saturated; shadows lean cool and a touch more saturated, the
    way the game's light (warm lamps, cool bounce) falls on them."""
    r, g, b = (c / 255 for c in _parse(base))
    h, s, v = colorsys.rgb_to_hsv(r, g, b)

    def toward(hh, target, amt):
        d = ((target - hh + 0.5) % 1.0) - 0.5
        return (hh + d * amt) % 1.0

    lift = 0.10 if v > 0.25 else 0.14
    hi = colorsys.hsv_to_rgb(toward(h, 0.12, 0.10), max(0, s * 0.9), min(1, v + lift))
    mid = colorsys.hsv_to_rgb(toward(h, 0.70, 0.05), min(1, s * 1.05 + 0.02), v * 0.80)
    deep = colorsys.hsv_to_rgb(toward(h, 0.72, 0.10), min(1, s * 1.1 + 0.05), v * 0.58)
    return [_hex([c * 255 for c in hi]), base, _hex([c * 255 for c in mid]), _hex([c * 255 for c in deep])]


REGIONS = {"skin": "SskK", "hair": "HhjJ", "top": "TtuU", "bottom": "BbnN", "shoes": "FfgG", "accent": "AaqQ"}


def palette(look: dict) -> dict:
    pal = {}
    for region, syms in REGIONS.items():
        base = look.get(region)
        if region == "accent":
            base = look.get("coat") or look.get("accent") or look["top"]
        if base is None:
            base = "#000000"
        for sym, col in zip(syms, ramp(base)):
            pal[sym] = col
    pal["e"] = look.get("eye", "#261812")
    pal["w"] = ramp(look["skin"])[0]
    pal["m"] = ramp(look["skin"])[3]
    pal["r"] = look.get("blush") or look["skin"]
    return pal


# ============================================================================= props
#
# Props are fill grids in tones 1-6 with their own colours.

PROPS = {
    "strap_front": {"part": (12, 18, ["4.....", ".4....", "..4...", "...4..", "....4.", ".....4"]), "outline": False,
                    "colors": {"4": "#3a2618"}},
    "strap_back": {"part": (13, 18, [".....4", "....4.", "...4..", "..4...", ".4....", "4....."]), "outline": False,
                   "colors": {"4": "#3a2618"}},
    "strap_side": {"part": (15, 18, ["4", "4", "4", "4", "4", "4"]), "outline": False, "colors": {"4": "#3a2618"}},
    "camera_chest": {"part": (17, 23, [
        "111125",
        "124432",
        "146432",
        "233333",
    ]), "colors": {"1": "#6c5a5f", "2": "#383039", "3": "#1a1519", "4": "#0d0a0e", "5": "#d4503f", "6": "#8fa6c4"}},
    "camera_chest_side": {"part": (19, 23, ["125", "234", "234", "333"]),
                          "colors": {"1": "#6c5a5f", "2": "#383039", "3": "#1a1519", "4": "#0d0a0e", "5": "#d4503f"}},
    "camera_face": {"part": (12, 9, [
        "1111125",
        "1244432",
        "1246432",
        "1244432",
        "2333333",
    ]), "colors": {"1": "#6c5a5f", "2": "#383039", "3": "#1a1519", "4": "#0d0a0e", "5": "#d4503f", "6": "#8fa6c4"}},
    "camera_face_side": {"part": (19, 10, ["1125", "2344", "2364", "3333"]),
                         "colors": {"1": "#6c5a5f", "2": "#383039", "3": "#1a1519", "4": "#0d0a0e", "5": "#d4503f", "6": "#8fa6c4"}},
    "cane_front": {"part": (24, 27, ["22"] + ["1."] * 17 + ["3."]), "colors": {"1": "#7a5431", "2": "#5e3f24", "3": "#3a2818"}},
    "cane_side": {"part": (21, 28, ["22"] + ["1."] * 16 + ["3."]), "colors": {"1": "#7a5431", "2": "#5e3f24", "3": "#3a2818"}},
    "newspaper_front": {"part": (10, 24, [
        "11111111112",
        "15551111112",
        "11111111112",
        "13333133312",
        "11111111112",
        "13331333312",
        "11111111112",
        "22222222222",
    ]), "colors": {"1": "#eee7d4", "2": "#cbc2ab", "3": "#8a8478", "5": "#b3443a"}},
    "newspaper_front_turn": {"part": (10, 24, [
        "11111222222",
        "15551222222",
        "11111222222",
        "13333233332",
        "11111222222",
        "13331233332",
        "11111222222",
        "22222222222",
    ]), "colors": {"1": "#eee7d4", "2": "#cbc2ab", "3": "#8a8478", "5": "#b3443a"}},
    "newspaper_side": {"part": (20, 23, ["12", "52", "12", "32", "12", "32", "12", "22"]),
                       "colors": {"1": "#eee7d4", "2": "#cbc2ab", "3": "#8a8478", "5": "#b3443a"}},
    "newspaper_back": {"part": (9, 24, ["2222222222222", "2222222222222", "2222222222222"]), "colors": {"2": "#cbc2ab"}},
    # Mr. Cheng's plan: a blueprint held open, white lines on blue
    "plan_front": {"part": (10, 24, [
        "11111111112",
        "13331333112",
        "13111113112",
        "13331113112",
        "11131333112",
        "13331111112",
        "11111111112",
        "22222222222",
    ]), "colors": {"1": "#3f6f9e", "2": "#2a4e74", "3": "#dce6ee"}},
    "plan_side": {"part": (20, 23, ["12", "32", "12", "32", "12", "32", "12", "22"]),
                  "colors": {"1": "#3f6f9e", "2": "#2a4e74", "3": "#dce6ee"}},
    "plan_back": {"part": (9, 24, ["2222222222222", "2222222222222", "2222222222222"]), "colors": {"2": "#2a4e74"}},
    # Mrs. Cheung's address book, open in her hands
    "address_book_front": {"part": (13, 25, ["1222221", "1233321", "1222221", "1111111"]), "outline": True,
                           "colors": {"1": "#8a2a24", "2": "#efe6d0", "3": "#4a4a6a"}},
    "address_book_side": {"part": (19, 25, ["21", "31", "21"]), "outline": True,
                          "colors": {"1": "#8a2a24", "2": "#efe6d0", "3": "#4a4a6a"}},
    "box_front": {"part": (10, 23, [
        "111111111112",
        "122222222223",
        "555555555553",
        "122222222223",
        "126662222223",
        "122222222223",
        "133333333334",
    ]), "colors": {"1": "#caa06a", "2": "#b28452", "3": "#8a6238", "4": "#6a4a2a", "5": "#dccca4", "6": "#3a2a1a"}},
    "box_side": {"part": (17, 22, [
        "11111112",
        "12222223",
        "55555553",
        "12222223",
        "12222223",
        "13333334",
    ]), "colors": {"1": "#caa06a", "2": "#b28452", "3": "#8a6238", "4": "#6a4a2a", "5": "#dccca4"}},
    "box_back": {"part": (6, 23, ["11111111111111111112", "12222222222222222223", "13333333333333333334"]),
                 "colors": {"1": "#caa06a", "2": "#b28452", "3": "#8a6238", "4": "#6a4a2a"}},
    "bundle_front": {"part": (11, 25, [
        "1111111112",
        "2222222223",
        "3333333334",
        "5555555556",
        "6666666666",
    ]), "colors": {"1": "#6f98c8", "2": "#3f6fa8", "3": "#e0bf72", "4": "#b0904c", "5": "#c26a5e", "6": "#8e4a40"}},
    "bundle_side": {"part": (17, 24, [
        "1111112",
        "2222223",
        "3333334",
        "5555556",
        "6666666",
    ]), "colors": {"1": "#6f98c8", "2": "#3f6fa8", "3": "#e0bf72", "4": "#b0904c", "5": "#c26a5e", "6": "#8e4a40"}},
    "bundle_back": {"part": (10, 16, ["1111111111112", "2222222222223"]), "colors": {"1": "#6f98c8", "2": "#3f6fa8", "3": "#294f7c"}},
    # the Chan boy's folded washing, held against his chest: blue, gold and red
    # cloths stacked, his hands on the sides of the pile
    "bundle_child_front": {"part": (10, 31, [
        ".111111112.",
        "73333333347",
        "85555555568",
        ".666666666.",
    ]), "colors": {"1": "#7aa2d0", "2": "#3f6fa8", "3": "#e6c47a", "4": "#b8964e", "5": "#c8705f",
                   "6": "#8e4a40", "7": "#e8bc94", "8": "#ba8a6f"}},
    "bundle_child_side": {"part": (17, 31, [
        "11112",
        "33334",
        "55556",
        "66666",
    ]), "colors": {"1": "#7aa2d0", "2": "#3f6fa8", "3": "#e6c47a", "4": "#b8964e", "5": "#c8705f", "6": "#8e4a40"}},
    "bundle_child_back": {"part": (8, 31, [
        "111111111111112",
        "333333333333334",
        "555555555555556",
    ]), "colors": {"1": "#7aa2d0", "2": "#3f6fa8", "3": "#e6c47a", "4": "#b8964e", "5": "#c8705f", "6": "#8e4a40"}},
    "tray_front": {"part": (13, 23, ["6.5.6.", "111111", "222222"]),
                   "colors": {"1": "#dfe3e6", "2": "#9aa2a8", "5": "#e9ecf0", "6": "#b8c2ca"}},
    "tray_side": {"part": (19, 23, ["5.6", "111", "222"]), "colors": {"1": "#dfe3e6", "2": "#9aa2a8", "5": "#e9ecf0", "6": "#b8c2ca"}},
    # Mum wrapping a bowl in newspaper for the boxes: the sheet folded round
    # it, then one more corner tucked over the top
    "wrap_front_a": {"part": (12, 24, [".11112.", "1333112", "1111112", ".22222."]),
                     "colors": {"1": "#eee7d4", "2": "#cbc2ab", "3": "#8a8478"}},
    "wrap_front_b": {"part": (12, 23, ["...12..", ".11112.", "1133312", "1111112", ".22222."]),
                     "colors": {"1": "#eee7d4", "2": "#cbc2ab", "3": "#8a8478"}},
    "wrap_side": {"part": (19, 24, ["112", "332", "222"]), "colors": {"1": "#eee7d4", "2": "#cbc2ab", "3": "#8a8478"}},
    "cloth_fold_a": {"part": (12, 24, ["11111112", "22222223", "33333334"]),
                     "colors": {"1": "#e9d9b8", "2": "#d6c29c", "3": "#b8a27c", "4": "#8e7a58"}},
    "cloth_fold_b": {"part": (13, 22, ["111112", "122223", "122223", "133334"]),
                     "colors": {"1": "#e9d9b8", "2": "#d6c29c", "3": "#b8a27c", "4": "#8e7a58"}},
    "cloth_fold_side": {"part": (18, 24, ["1112", "2223", "3334"]),
                        "colors": {"1": "#e9d9b8", "2": "#d6c29c", "3": "#b8a27c", "4": "#8e7a58"}},
    # Mrs. Chan wringing out a blue cloth over her basin: the twisted rope held
    # between both hands, the wet end hanging from the middle, water dripping
    "wring_front_a": {"part": (12, 24, [
        "112211221",
        "221122112",
        "...123...",
        "...123...",
        "....23...",
        "....3....",
    ]), "colors": {"1": "#7aa2d0", "2": "#3f6fa8", "3": "#294f7c"}},
    "wring_front_b": {"part": (12, 24, [
        "211221122",
        "122112211",
        "...123...",
        "....123..",
        "....123..",
        ".....3...",
    ]), "colors": {"1": "#7aa2d0", "2": "#3f6fa8", "3": "#294f7c"}},
    "wring_side_a": {"part": (18, 24, ["1221", "2112", ".12.", ".23.", "..3."]),
                     "colors": {"1": "#7aa2d0", "2": "#3f6fa8", "3": "#294f7c"}},
    "wring_side_b": {"part": (18, 24, ["2112", "1221", ".12.", "..23", "..3."]),
                     "colors": {"1": "#7aa2d0", "2": "#3f6fa8", "3": "#294f7c"}},
    "drip_front_a": {"part": (16, 32, ["4", ".", "4"]), "colors": {"4": "#cfe4f0"}},
    "drip_front_b": {"part": (17, 34, ["4"]), "colors": {"4": "#cfe4f0"}},
    "drip_side_a": {"part": (20, 31, ["4", ".", "4"]), "colors": {"4": "#cfe4f0"}},
    "drip_side_b": {"part": (20, 33, ["4"]), "colors": {"4": "#cfe4f0"}},
    "birdcage_front": {"part": (21, 29, [
        "..44..",
        ".1111.",
        "2.2.2.",
        "2.2.2.",
        "2.562.",
        "2.2.2.",
        "333333",
    ]), "outline": True, "colors": {"1": "#d8b877", "2": "#c9a66a", "3": "#8a6a3a", "4": "#5a4428", "5": "#e0c040", "6": "#6a8a40"}},
    "birdcage_front_hop": {"part": (21, 29, [
        "..44..",
        ".1111.",
        "2.2.2.",
        "2.562.",
        "2.2.2.",
        "2.2.2.",
        "333333",
    ]), "outline": True, "colors": {"1": "#d8b877", "2": "#c9a66a", "3": "#8a6a3a", "4": "#5a4428", "5": "#e0c040", "6": "#6a8a40"}},
    "cigarette_side": {"part": (20, 15, ["1112"]), "outline": False, "colors": {"1": "#f0ebe0", "2": "#ff8a40"}},
    "cigarette_front": {"part": (16, 14, ["112"]), "outline": False, "colors": {"1": "#f0ebe0", "2": "#ff8a40"}},
    "smoke_a": {"part": (21, 9, [".1", "1.", ".1", "..", "1."]), "outline": False, "colors": {"1": "#d8d8d4"}},
    "smoke_b": {"part": (22, 8, ["1.", ".1", "1.", ".1"]), "outline": False, "colors": {"1": "#e4e4e0"}},
    "can_side": {"part": (19, 25, ["....5", "1113.", "12223", "12223", "3333."]),
                 "colors": {"1": "#a8bcc4", "2": "#8aa0a8", "3": "#5f7680", "5": "#8aa0a8"}},
    "can_pour": {"part": (19, 25, ["1113....", "122235..", "12223.6.", "3333...6"]), "outline": True,
                 "colors": {"1": "#a8bcc4", "2": "#8aa0a8", "3": "#5f7680", "5": "#8aa0a8", "6": "#a8d8ff"}},
    # Wai's seat: the plank Mrs. Chan lends, across two bricks
    "plank_seat_back": {"part": (7, 41, ["111111111111111111", "222222222222222222", ".33............33."]),
                        "colors": {"1": "#a8845a", "2": "#7a5a3a", "3": "#b8603a"}},
    "plank_seat_side_back": {"part": (9, 41, ["1111111111", "2222222222", ".33....33."]),
                             "colors": {"1": "#a8845a", "2": "#7a5a3a", "3": "#b8603a"}},
    # an empty plastic fish crate carried against the chest
    "crate_front": {"part": (9, 22, ["11111111111111", "12.2.2.2.2.2.1", "12.2.2.2.2.2.1", "11111111111111", "33333333333333"]),
                    "colors": {"1": "#3f6fa8", "2": "#2f5a8e", "3": "#294f7c"}},
    "crate_side": {"part": (17, 22, ["111111", "12.2.1", "12.2.1", "111111", "333333"]),
                   "colors": {"1": "#3f6fa8", "2": "#2f5a8e", "3": "#294f7c"}},
    "crate_back": {"part": (7, 20, ["111111111111111111", "333333333333333333"]), "colors": {"1": "#3f6fa8", "3": "#294f7c"}},
    # Uncle Chiu's hands: a ball of paste, and the marker he writes on crates with
    "paste_ball": {"part": (14, 24, [".11.", "1112", ".22."]), "colors": {"1": "#f0ebe0", "2": "#cfc8b8"}},
    "marker": {"part": (22, 22, ["11", "12"]), "outline": True, "colors": {"1": "#1c1c1c", "2": "#c9463a"}},
    # the watering can hanging from her hand by its handle (front view), and
    # tipped with water running out
    "can_front": {"part": (15, 25, ["...44.", "..4..4", "111113", "122223", "122223", "333333"]),
                  "colors": {"1": "#a8bcc4", "2": "#8aa0a8", "3": "#5f7680", "4": "#4a5a60"}},
    "can_front_pour": {"part": (15, 25, ["...44.", "..4..4", "111113", "122223", "122223", "333333", ".6..6.", "6..6..", ".6...6"]),
                       "colors": {"1": "#a8bcc4", "2": "#8aa0a8", "3": "#5f7680", "4": "#4a5a60", "6": "#a8d8ff"}},
    # a paper folding fan, open, held by the cheek and swung to and fro
    "fan_a": {"part": (17, 9, [".212121", "1212121", ".21212.", "..121..", "..12...", "..3...."]),
              "colors": {"1": "#f0e6c8", "2": "#b8453a", "3": "#5a3a24"}},
    "fan_b": {"part": (18, 10, ["...2121", "..12121", ".21212.", ".212...", ".21....", ".3....."]),
              "colors": {"1": "#f0e6c8", "2": "#b8453a", "3": "#5a3a24"}},
    "fan_side_a": {"part": (20, 11, ["11", "21", "12", "21", "1.", "3."]), "colors": {"1": "#f0e6c8", "2": "#b8453a", "3": "#5a3a24"}},
    "fan_side_b": {"part": (20, 11, [".1", ".2", "12", "21", "2.", "3."]), "colors": {"1": "#f0e6c8", "2": "#b8453a", "3": "#5a3a24"}},
    # the cigarette at the lips (hand up) and held at the chest (hand down)
    "cig_mouth_front": {"part": (15, 14, ["112"]), "outline": False, "colors": {"1": "#f0ebe0", "2": "#ff8a40"}},
    "cig_mouth_glow": {"part": (15, 14, ["113"]), "outline": False, "colors": {"1": "#f0ebe0", "3": "#ffcf70"}},
    "cig_hand_front": {"part": (15, 23, ["211"]), "outline": False, "colors": {"1": "#f0ebe0", "2": "#ff8a40"}},
    "cig_mouth_side": {"part": (20, 15, ["1112"]), "outline": False, "colors": {"1": "#f0ebe0", "2": "#ff8a40"}},
    "cig_mouth_side_glow": {"part": (20, 15, ["1113"]), "outline": False, "colors": {"1": "#f0ebe0", "3": "#ffcf70"}},
    "cig_hand_side": {"part": (21, 22, ["1112"]), "outline": False, "colors": {"1": "#f0ebe0", "2": "#ff8a40"}},
    "puff_front": {"part": (11, 11, ["..11", ".1.1", "1..."]), "outline": False, "colors": {"1": "#e4e4e0"}},
    "puff_side": {"part": (23, 13, ["11..", "1.11", "..1."]), "outline": False, "colors": {"1": "#e4e4e0"}},
    "wisp_front": {"part": (14, 17, [".1", "1.", ".1", "1."]), "outline": False, "colors": {"1": "#d8d8d4"}},
    "wisp_side": {"part": (25, 17, ["1.", ".1", "1.", ".1"]), "outline": False, "colors": {"1": "#d8d8d4"}},
    # a rice bowl in the other hand, and chopsticks
    "bowl_front": {"part": (10, 21, ["..44..", "111111", "222222", ".2222.", "..33.."]),
                   "colors": {"1": "#5a7aa8", "2": "#eeeae0", "3": "#b8b4a8", "4": "#fbf8f0"}},
    "bowl_side": {"part": (19, 20, [".44.", "1111", "2222", ".22."]),
                  "colors": {"1": "#5a7aa8", "2": "#eeeae0", "4": "#fbf8f0"}},
    "chop_mouth_front": {"part": (15, 13, ["1..", ".1.", "..1"]), "outline": False, "colors": {"1": "#c9a55a"}},
    "chop_bowl_front": {"part": (13, 20, ["1....", ".1...", "..1..", "...1.", "....1"]), "outline": False, "colors": {"1": "#c9a55a"}},
    "chop_mouth_side": {"part": (20, 14, ["11", ".1"]), "outline": False, "colors": {"1": "#c9a55a"}},
    "chop_bowl_side": {"part": (20, 18, ["1.", "11", ".1"]), "outline": False, "colors": {"1": "#c9a55a"}},
    "cleaver_up": {"part": (21, 8, ["1111", "1112", "..3."]), "colors": {"1": "#e0e4e6", "2": "#9aa2a8", "3": "#5a3a24"}},
    "cleaver_down": {"part": (21, 24, ["3...", ".111", ".112"]), "colors": {"1": "#e0e4e6", "2": "#9aa2a8", "3": "#5a3a24"}},
    "cleaver_front": {"part": (14, 22, ["1111", "1112", ".3.."]), "colors": {"1": "#e0e4e6", "2": "#9aa2a8", "3": "#5a3a24"}},
    "screwdriver": {"part": (16, 32, ["1112"]), "outline": True, "colors": {"1": "#c9463a", "2": "#b8c0c8"}},
    # held up to a pipe overhead, the blade on the pipe, the handle in his fist
    "screwdriver_up_front": {"part": (22, 1, ["2", "2", "2", "2", "1", "1", "1"]), "outline": True, "colors": {"1": "#c9463a", "2": "#b8c0c8"}},
    "screwdriver_up_side": {"part": (25, 1, ["2", "2", "2", "2", "1", "1", "1"]), "outline": True, "colors": {"1": "#c9463a", "2": "#b8c0c8"}},
    # water off wet hands, and a bowl being washed
    "wash_drops_a": {"part": (13, 26, ["1...1", "..1..", "1...."]), "outline": False, "colors": {"1": "#a8d8ff"}},
    "wash_drops_b": {"part": (13, 26, [".1...", "1..1.", "....1"]), "outline": False, "colors": {"1": "#a8d8ff"}},
    "wash_drops_side": {"part": (19, 26, ["1.", ".1", "1."]), "outline": False, "colors": {"1": "#a8d8ff"}},
    "red_bowl_front": {"part": (12, 21, ["122221", "122221", ".3333."]), "colors": {"1": "#d8483a", "2": "#f0ebe0", "3": "#9a2a22"}},
    "red_bowl_tilt": {"part": (12, 21, [".12222", "122221", "33333."]), "colors": {"1": "#d8483a", "2": "#f0ebe0", "3": "#9a2a22"}},
    "red_bowl_side": {"part": (19, 21, ["122", "333"]), "colors": {"1": "#d8483a", "2": "#f0ebe0", "3": "#9a2a22"}},
    "grains": {"part": (21, 32, ["1...", "..1.", ".1..", "...1"]), "outline": False, "colors": {"1": "#e8d890"}},
    "pigeon_hand": {"part": (22, 3, [".11.", "1112", ".333"]), "colors": {"1": "#9aa0a8", "2": "#d08a60", "3": "#6f747c"}},
    # a knee-high wooden stool: the seat right under the thighs of LEGS_SEATED
    # (rows 35-36), the legs down to the floor row (44), where standing feet end
    "stool_front": {"part": (9, 37, ["11111111111112", "22222222222223"] + [".3..........3."] * 6),
                    "colors": {"1": "#8a6a48", "2": "#6b4a30", "3": "#4a3222"}},
    "stool_side": {"part": (11, 37, ["11111112", "22222223"] + [".3....3."] * 6),
                   "colors": {"1": "#8a6a48", "2": "#6b4a30", "3": "#4a3222"}},
}

# ============================================================================= looks

def _stick(x0, y0, x1, y1, head_w=6):
    """A broom: the handle a line from (x0, y0) to (x1, y1), its head at the foot."""
    n = max(abs(x1 - x0), abs(y1 - y0))
    pts = {(round(x0 + (x1 - x0) * t / n), round(y0 + (y1 - y0) * t / n)) for t in range(n + 1)}
    for dx in range(-head_w // 2, head_w - head_w // 2):
        pts.add((x1 + dx, y1 + 1))
        pts.add((x1 + dx, y1 + 2))
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    ox, oy = min(xs), min(ys)
    rows = []
    for y in range(oy, max(ys) + 1):
        row = ""
        for x in range(ox, max(xs) + 1):
            if (x, y) in pts:
                row += "2" if y > y1 else "1"
            else:
                row += "."
        rows.append(row)
    return (ox, oy, rows)


BROOM_COLORS = {"1": "#8a6a48", "2": "#c9a55a"}
PROPS.update({
    "broom_front_a": {"part": _stick(18, 24, 13, 41), "colors": BROOM_COLORS},
    "broom_front_b": {"part": _stick(18, 24, 21, 41), "colors": BROOM_COLORS},
    "broom_side_a": {"part": _stick(21, 23, 25, 41), "colors": BROOM_COLORS},
    "broom_side_b": {"part": _stick(21, 23, 20, 41), "colors": BROOM_COLORS},
})


LOOKS = {
    # --- the people Mei knows
    "mei": dict(top="#e0823a", bottom="#2e3a4a", shoes="#7a2a24", skin="#e8bc94", hair="#231814", hair_style="bob",
                accent="#f1e6cf", collar=True, blush="#ea9c82", sleeves=4, prop="camera"),
    "mum": dict(top="#23706e", bottom="#6b5846", shoes="#2a2420", skin="#e2b48c", hair="#35251f", hair_style="perm",
                accent="#d8cfb8", collar=True, sleeves=4),
    # Ah Kit, Mei's closest friend
    "kit": dict(top="#d8506e", bottom="#34496e", shoes="#e8e4da", skin="#e8bc94", hair="#1c1414", hair_style="ponytail",
                blush="#ea9c82", sleeves=3, accent="#f1e6cf", collar=True),
    # the workshop's two hands: a woman in a white cap and a man in a vest, both aproned
    "ws_hand_a": dict(top="#e8e2d2", bottom="#3a3a44", shoes="#2e4a36", skin="#e2b48c", hair="#e8e4da", hair_style="bun",
                      apron=True, accent="#7a8a8a", sleeves=4),
    "ws_hand_b": dict(top="#5a6a5a", bottom="#333333", shoes="#2e4a36", skin="#c89a74", hair="#1a1a1a", hair_style="short",
                      apron=True, accent="#7a8a8a", sleeves=0),
    # Uncle Chiu, Kit's uncle: a singlet, a rubber apron, boots
    "chiu": dict(top="#eeeae0", bottom="#3a3a44", shoes="#2e4a36", skin="#d8a882", hair="#2a2420", hair_style="short",
                 apron=True, accent="#5a6a72", sleeves=0),
    "grandfather": dict(top="#dccfae", bottom="#4a4436", shoes="#3a3028", skin="#d6a882", hair="#cfccc3", hair_style="bald",
                        build="elder", sleeves=0, prop="cane"),
    "lau": dict(top="#5f9a62", bottom="#33383a", shoes="#2a2420", skin="#e2b48c", hair="#1f1d1c", hair_style="short",
                glasses=True, coat="#eef1ea", sleeves=10),
    "chan": dict(top="#7d5aa0", bottom="#3a2f45", shoes="#2a2026", skin="#e2b48c", hair="#201a1a", hair_style="bun",
                 accent="#cdbd9e", apron=True, sleeves=9, pattern="floral", pattern_col="#b99ad0"),
    "son": dict(top="#3f78c0", bottom="#2a2a2a", shoes="#dcd8cc", skin="#e8bc94", hair="#161414", hair_style="short",
                build="child", blush="#e8a088", legs="shorts", sleeves=3, pattern="stripe", pattern_col="#e8e4da"),
    "ng": dict(top="#7a5a3c", bottom="#3b3024", shoes="#2a2018", skin="#d8a882", hair="#6a6660", hair_style="cap",
               accent="#4a5a48", belt="#2a2018", build="elder", sleeves=9),
    "wong": dict(top="#d98aa3", bottom="#4d3a42", shoes="#2a2026", skin="#dcb08e", hair="#d6d3cc", hair_style="bun",
                 build="elder", sleeves=9, pattern="floral", pattern_col="#f0c2cf"),
    # --- neighbours on the route
    "chopper": dict(top="#6f7d74", bottom="#333333", shoes="#2a2420", skin="#e2b48c", hair="#222222", hair_style="bun",
                    accent="#bdb6a4", apron=True, sleeves=4),
    "child": dict(top="#b0443a", bottom="#333333", shoes="#cdc9b8", skin="#e8bc94", hair="#121212", hair_style="short",
                  build="child", blush="#e8a088", legs="shorts", sleeves=3),
    "fanman": dict(top="#5b6b7a", bottom="#2d2d2d", shoes="#2a2420", skin="#d8a882", hair="#333333", hair_style="cap",
                   accent="#8a3a30", sleeves=4),
    "worker": dict(top="#e8e2d2", bottom="#3a3a3a", shoes="#2a2420", skin="#c89a74", hair="#222222", hair_style="short",
                   sleeves=0, prop="box"),
    "mahjong1": dict(top="#8c6d5a", bottom="#333333", shoes="#2a2420", skin="#d6a882", hair="#9a9892", hair_style="bald",
                     build="elder", sleeves=4),
    "mahjong2": dict(top="#56707c", bottom="#333333", shoes="#2a2420", skin="#e2b48c", hair="#222222", hair_style="perm",
                     sleeves=4, pattern="check", pattern_col="#7b95a0"),
    "mahjong3": dict(top="#9a8f6a", bottom="#333333", shoes="#2a2420", skin="#e2b48c", hair="#444444", hair_style="short",
                     sleeves=4, glasses=True),
    "shopkeeper": dict(top="#6a5d7a", bottom="#333333", shoes="#2a2420", skin="#d6a882", hair="#9a968f", hair_style="grey",
                       glasses=True, sleeves=4, build="elder", prop="newspaper"),
    # --- the city around them
    "ext_auntie_laundry": dict(top="#c9463a", bottom="#2d2d34", shoes="#2a2420", skin="#e2b48c", hair="#1a1414",
                               hair_style="perm", sleeves=4, pattern="floral", pattern_col="#e8a09a"),
    "ext_birdcage_man": dict(top="#e6e2d6", bottom="#4a4a46", shoes="#2a2420", skin="#d6a882", hair="#bcb8b0",
                             hair_style="grey", build="elder", sleeves=0, prop="birdcage"),
    "ext_smoker": dict(top="#e8e4da", bottom="#3a3a44", shoes="#2a2420", skin="#d8a882", hair="#161616",
                       hair_style="short", sleeves=0),
    "ext_plant_lady": dict(top="#6f8a5a", bottom="#3a3530", shoes="#2a2420", skin="#e2b48c", hair="#2a2020",
                           hair_style="bun", sleeves=4, build="elder"),
    "ext_kid_red": dict(top="#d85a3a", bottom="#2a3a5a", shoes="#e0dccc", skin="#e8bc94", hair="#111111",
                        hair_style="short", build="child", legs="shorts", blush="#e8a088", sleeves=3),
    "ext_kid_yellow": dict(top="#e3b845", bottom="#3a3a3a", shoes="#8a3a30", skin="#e8bc94", hair="#111111",
                           hair_style="ponytail", build="child", legs="skirt", blush="#e8a088", sleeves=3),
    "ext_student": dict(top="#eef0ec", bottom="#2b3550", shoes="#2a2420", skin="#e8bc94", hair="#161214",
                        hair_style="ponytail", sleeves=4, accent="#2b3550", collar=True, legs="skirt"),
    "ext_fan_woman": dict(top="#4f7fa0", bottom="#2f2f38", shoes="#2a2420", skin="#e2b48c", hair="#1e1a1a",
                          hair_style="bob", sleeves=4, pattern="floral", pattern_col="#8fb5cc"),
    "ext_labourer": dict(top="#3d5a78", bottom="#3a3a36", shoes="#2a2420", skin="#c8966e", hair="#1a1a1a",
                         hair_style="short", sleeves=10),
    "ext_taichi": dict(top="#e8e4da", bottom="#3a3a44", shoes="#2a2420", skin="#d6a882", hair="#cfccc3",
                       hair_style="grey", build="elder", sleeves=10),
    "ext_sweeper": dict(top="#8a6a8a", bottom="#2d2d34", shoes="#2a2420", skin="#e2b48c", hair="#1a1414",
                        hair_style="bun", sleeves=4, apron=True, accent="#cdbd9e"),
    "ext_eater": dict(top="#e8e2d2", bottom="#3a3530", shoes="#2a2420", skin="#d8a882", hair="#161616",
                      hair_style="short", sleeves=0),
    "ext_reader": dict(top="#5a6a5a", bottom="#333333", shoes="#2a2420", skin="#d6a882", hair="#9a968f",
                       hair_style="grey", glasses=True, sleeves=4, build="elder"),
    # --- Chapter 4, the yamen
    # Mrs. Cheung, who has lived in the yamen's old people's home for years
    "cheung": dict(top="#4a5a7a", bottom="#3a3438", shoes="#2a2026", skin="#dcb08e", hair="#cfcac2", hair_style="bun",
                   build="elder", glasses=True, sleeves=9, pattern="check", pattern_col="#5f7090"),
    # Mr. Cheng of the housing department: a pressed shirt, a plan
    "cheng": dict(top="#e8ecf0", bottom="#4a4e58", shoes="#2a2420", skin="#e2b48c", hair="#1a1414", hair_style="short",
                  sleeves=4, collar=True, accent="#cfd4da", glasses=True),
    "mover_a": dict(top="#e8e2d2", bottom="#4a4a44", shoes="#2a2420", skin="#c8966e", hair="#1a1a1a", hair_style="short",
                    sleeves=0, prop="box"),
    "mover_b": dict(top="#c9a55a", bottom="#3a3a36", shoes="#2a2420", skin="#c89a74", hair="#222222", hair_style="short",
                    sleeves=4),
    "ext_grandma_black": dict(top="#2e2e36", bottom="#2a2a30", shoes="#1e1a1a", skin="#dcb08e", hair="#d3cec6",
                              hair_style="bun", build="elder", sleeves=9),
}

# ============================================================================= assembly


class Frame:
    def __init__(self, duration):
        self.duration = duration
        self.placements = []

    def add(self, part, layer, dx=0, dy=0, **kw):
        x, y, rows = part
        self.placements.append(dict(x=x + dx, y=y + dy, rows=rows, layer=layer, **kw))


def build_parts(look):
    child = look.get("build") == "child"
    return {
        "head_dy": P.CHILD_HEAD_OFFSET[1] if child else (1 if look.get("build") == "elder" else 0),
        "torso": P.CHILD_TORSO if child else P.TORSO,
        "neck": P.CHILD_NECK if child else P.NECK,
        "arms": P.CHILD_ARMS if child else P.ARMS,
        "legs_front": P.CHILD_LEGS_FRONT_IDLE if child else P.LEGS_FRONT_IDLE,
        "legs_back": P.CHILD_LEGS_BACK_IDLE if child else P.LEGS_BACK_IDLE,
        "lift": P.child_front_lift if child else P.front_lift,
        "side_walk": P.CHILD_SIDE_WALK if child else P.SIDE_WALK,
        "side_idle": P.CHILD_SIDE_IDLE if child else P.SIDE_IDLE,
        "pelvis": P.CHILD_PELVIS if child else P.PELVIS,
        "shorts_y": 40 if child else 36,
        "skirt_y": 38 if child else 32,
        "body_dy": 10 if child else 0,   # props and overlays drawn for adults shift down for children
    }


def mirror_arm(arm, frame_w=32):
    """A right arm flipped to the left side, relit from the upper left: each
    row's first pixel takes the highlight and the rest the base tone."""
    x, y, rows = arm["part"]
    w = len(rows[0])
    out = []
    for r in rows:
        m = list(r[::-1])
        idx = [i for i, c in enumerate(m) if c != "."]
        for n, i in enumerate(idx):
            m[i] = "S" if n == 0 else "s"
        if len(idx) >= 3:
            m[idx[-1]] = "k"
        out.append("".join(m))
    sx, sy = arm["shoulder"]
    return {"part": (frame_w - x - w, y, out), "shoulder": (frame_w - 1 - sx, sy)}


def arm_variant(bp, side, suffix):
    key = f"front_{side}{suffix}"
    if key in bp["arms"]:
        return bp["arms"][key]
    other = "r" if side == "l" else "l"
    src = bp["arms"].get(f"front_{other}{suffix}")
    if src is None:
        return bp["arms"][f"front_{side}"]
    return mirror_arm(src)


def shift_part(part, dx=0, dy=0):
    x, y, rows = part
    return (x + dx, y + dy, rows)


def legs_common(look):
    kw = {}
    if look.get("legs") == "shorts":
        kw["shorts_y"] = build_parts(look)["shorts_y"]
    if look.get("legs") == "skirt":
        kw["skirt_y"] = build_parts(look)["skirt_y"]
    return kw


def add_upper(fr: Frame, look, view, bp, bob=0, arms=("mid", "mid"), blink=False, mouth=False,
              far_arm=None, stoop=0, props=(), hide_arms=False, seated_dy=0):
    """Neck, torso, clothing overlays, arms, head, hair and props for one frame."""
    dy = bob + seated_dy
    elder = look.get("build") == "elder"
    child = look.get("build") == "child"
    odx = 0 if child else 0
    ody = bp["body_dy"]
    sleeve = look.get("sleeves", 4)
    sleeve_region = "accent" if look.get("coat") else "top"
    pattern = {"pattern": look["pattern"], "pattern_col": look["pattern_col"]} if look.get("pattern") else {}
    lean = 1 if (elder and view == "side") else 0

    # far arm (side view) sits behind the body
    if view == "side" and far_arm and not hide_arms:
        a = bp["arms"][far_arm]
        fr.add(a["part"], "Far Arm", dx=lean, dy=dy, tone="far", sleeve=_sleeve(a, sleeve, sleeve_region, lean, dy), **pattern)

    fr.add(bp["torso"][view], "Body", dx=lean, dy=dy, **pattern)
    if look.get("collar"):
        fr.add(shift_part(P.COLLAR[view], odx, ody), "Body", dx=lean, dy=dy, outline=False)
    if look.get("apron"):
        if view in P.APRON:
            fr.add(shift_part(P.APRON[view], 0, ody), "Body", dx=lean, dy=dy)
            fr.add(shift_part(P.APRON_STRAPS[view], 0, ody), "Body", dx=lean, dy=dy, outline=False)
    if look.get("coat"):
        if view == "front":
            fr.add(P.COAT["front_l"], "Body", dy=dy, coat=True)
            fr.add(P.COAT["front_r"], "Body", dy=dy, coat=True)
        else:
            fr.add(P.COAT[view], "Body", dx=lean, dy=dy, coat=True)
    if look.get("belt"):
        fr.add(shift_part(P.BELT[view], 0, ody), "Body", dx=lean, dy=dy, outline=False)

    head_dy = bp["head_dy"] + dy
    head_dx = lean
    if not hide_arms:
        if view in ("front", "back"):
            l, r = arms
            al = arm_variant(bp, "l", l)
            ar = arm_variant(bp, "r", r)
            if view == "back":
                # seen from behind, the character's right arm is on the viewer's right;
                # forearms held out in front are hidden by the body, so only the
                # upper arm shows
                rb = "_back" if r == "_hold" else r
                lb = "_back" if l == "_hold" else l
                al, ar = arm_variant(bp, "l", rb), arm_variant(bp, "r", lb)
            fr.add(al["part"], "Arms", dy=dy, sleeve=_sleeve(al, sleeve, sleeve_region, 0, dy), **pattern)
            fr.add(ar["part"], "Arms", dy=dy, sleeve=_sleeve(ar, sleeve, sleeve_region, 0, dy), **pattern)

    head = P.HEAD[view]
    hx, hy, hrows = head
    fr.add((hx, hy, hrows), "Head", dx=head_dx, dy=head_dy, blink=blink and view != "back", mouth=mouth and view != "back",
           glasses=bool(look.get("glasses")) and view != "back", no_blush=not look.get("blush"), view=view)
    # the neck, after the head, so it cuts through the chin and shoulder outlines
    fr.add(bp["neck"][view], "Head", dx=head_dx, dy=dy, outline=False)
    style = look["hair_style"]
    hair = P.HAIR[style]
    hdx, hdy, hrows2 = hair[view]
    fr.add((hx + hdx, hy + hdy, hrows2), "Hair", dx=head_dx, dy=head_dy, cap=style == "cap")
    if style == "bun" and view == "back":
        bdx, bdy, brows = hair["bun_back"]
        fr.add((hx + bdx, hy + bdy, brows), "Hair", dx=head_dx, dy=head_dy)
    if style == "ponytail" and view == "back":
        tdx, tdy, trows = hair["tail_back"]
        fr.add((hx + tdx, hy + tdy, trows), "Hair", dx=head_dx, dy=head_dy)

    if view == "side" and not hide_arms:
        a = bp["arms"][arms[0]]
        fr.add(a["part"], "Arms", dx=lean, dy=dy, sleeve=_sleeve(a, sleeve, sleeve_region, lean, dy), **pattern)

    for pr in props:
        name, pdx, pdy = (pr + (0, 0))[:3] if isinstance(pr, tuple) else (pr, 0, 0)
        spec = PROPS[name]
        layer = "Prop Back" if name.endswith("_back") and not name.startswith("strap") else "Prop"
        part = spec["part"]
        if view == "back" and not name.endswith("_back") and not name.startswith("stool"):
            # a prop drawn for the front view is held in the other hand when
            # seen from behind: mirror it (and its grid) across the frame
            px, py, prows = part
            w = len(prows[0])
            part = (32 - px - w, py, [r[::-1] for r in prows])
        fr.add(part, layer, dx=pdx + (lean if view == "side" else 0), dy=pdy + dy + (ody if child and not name.startswith("stool") and "_child" not in name else 0),
               colors=spec["colors"], outline=spec.get("outline", True), prop=True)


def _sleeve(arm, length, region, dx, dy):
    sx, sy = arm["shoulder"]
    return {"x": sx + dx, "y": sy + dy, "len": length, "region": region}


def add_legs(fr: Frame, look, view, bp, kind="idle", frame=0, swap=False):
    kw = legs_common(look)
    if kind == "seated_child":
        # on a plank laid across two bricks, the plank behind the legs
        plank = PROPS["plank_seat_side_back" if view == "side" else "plank_seat_back"]
        fr.add(plank["part"], "Prop Back", colors=plank["colors"], outline=True, prop=True)
        fr.add(P.CHILD_LEGS_SEATED[view], "Legs", **kw)
        return
    if kind == "seated":
        # the stool goes in with the legs, behind them: it stays on the floor
        # while the body breathes, and never shifts with the seated pose
        stool = PROPS["stool_side" if view == "side" else "stool_front"]
        fr.add(stool["part"], "Prop Back", colors=stool["colors"], outline=True, prop=True)
        fr.add(P.LEGS_SEATED[view], "Legs", **kw)
        return
    if kind == "crouch":
        fr.add(P.LEGS_CROUCH[view], "Legs", **kw)
        return
    if view == "side":
        pose = bp["side_idle"] if kind == "idle" else bp["side_walk"][frame]
        near, far = ("b", "a") if swap else ("a", "b")
        fr.add(pose[far], "Legs", tone="far", **kw)
        fr.add(bp["pelvis"]["side"], "Legs", outline=True, **kw)
        fr.add(pose[near], "Legs", **kw)
        if look.get("legs") == "skirt":
            fr.add(shift_part(P.SKIRT["side"], 0, bp["body_dy"] - (2 if look.get("build") == "child" else 0)), "Legs")
        return
    legs = bp["legs_front"] if view == "front" else bp["legs_back"]
    skirt = look.get("legs") == "skirt"
    if kind == "lift_l1":
        legs = bp["lift"](legs, "left", 1)
    elif kind == "lift_l2":
        legs = bp["lift"](legs, "left", 2)
    elif kind == "lift_r1":
        legs = bp["lift"](legs, "right", 1)
    elif kind == "lift_r2":
        legs = bp["lift"](legs, "right", 2)
    fr.add(legs, "Legs", **kw)
    if skirt:
        fr.add(shift_part(P.SKIRT[view], 0, bp["body_dy"] - (2 if look.get("build") == "child" else 0)), "Legs")


# ----------------------------------------------------------------------------- standard animations


def anim_idle(look, view, bp, extra_props=(), arms=("", ""), side_arm="side_mid", legs="idle", seated_dy=0, tag="idle"):
    frames = []
    for i, dn in enumerate([0, 0, 1, 1]):
        fr = Frame(300 if i in (0, 2) else 420)
        add_legs(fr, look, view, bp, legs)
        add_upper(fr, look, view, bp, bob=dn, arms=(arms if view != "side" else (side_arm, side_arm)),
                  far_arm=side_arm, blink=(i == 3), props=extra_props, seated_dy=seated_dy)
        frames.append(fr)
    return tag, frames


def anim_walk(look, view, bp, props=(), hold=False, tag="walk"):
    frames = []
    legs_seq = ["idle", "lift_l1", "lift_l2", "idle", "lift_r1", "lift_r2"]
    bob = [1, 0, 0, 1, 0, 0]
    front_arms = [("", ""), ("_back", "_fwd"), ("_back", "_fwd"), ("", ""), ("_fwd", "_back"), ("_fwd", "_back")]
    near = ["side_back2", "side_back1", "side_mid", "side_fwd2", "side_fwd1", "side_mid"]
    far = ["side_fwd2", "side_fwd1", "side_mid", "side_back2", "side_back1", "side_mid"]
    for i in range(6):
        fr = Frame(100)
        if view == "side":
            add_legs(fr, look, view, bp, "walk", i % 3, swap=i >= 3)
            b = bp["side_walk"][i % 3]["bob"]
            arm = "side_hold" if hold else near[i]
            add_upper(fr, look, view, bp, bob=b, arms=(arm, arm), far_arm=None if hold else far[i], props=props)
        else:
            add_legs(fr, look, view, bp, legs_seq[i])
            arms = ("_hold", "_hold") if hold else front_arms[i]
            add_upper(fr, look, view, bp, bob=bob[i], arms=arms, props=props)
        frames.append(fr)
    return tag, frames


def anim_talk(look, view, bp, props=(), legs="idle", seated_dy=0, arms=("", "")):
    frames = []
    for i in range(4):
        fr = Frame(160)
        add_legs(fr, look, view, bp, legs)
        a = arms if view != "side" else ("side_mid", "side_mid")
        if i == 3 and arms == ("", ""):
            a = ("", "_fwd") if view != "side" else ("side_fwd1", "side_fwd1")
        add_upper(fr, look, view, bp, bob=0, arms=a, far_arm="side_mid", mouth=(i % 2 == 1), props=props, seated_dy=seated_dy)
        frames.append(fr)
    return "talk", frames


def default_props(look, view, state=0):
    pr = look.get("prop")
    if pr == "camera":
        return ([{"front": "strap_front", "back": "strap_back"}[view]] if view != "side" else []) + \
            ([{"front": "camera_chest", "side": "camera_chest_side"}[view]] if view != "back" else [])
    if pr == "cane":
        return [{"front": "cane_front", "back": "cane_front", "side": "cane_side"}[view]]
    if pr == "box":
        return [{"front": "box_front", "back": "box_back", "side": "box_side"}[view]]
    if pr == "newspaper":
        return []
    if pr == "birdcage":
        return [{"front": "birdcage_front_hop" if state else "birdcage_front", "back": "birdcage_front", "side": "birdcage_front"}[view]]
    return []


def holds_prop(look):
    return look.get("prop") in ("box",)


def character(name, look):
    bp = build_parts(look)
    tags = []
    seated = name.startswith("mahjong") or name == "grandfather"
    for view in VIEWS:
        props = default_props(look, view)
        hold = holds_prop(look)
        arms_idle = ("_hold", "_hold") if hold else ("", "")
        side_idle_arm = "side_hold" if hold else "side_mid"
        tags.append((view, *anim_idle(look, view, bp, props, arms=arms_idle, side_arm=side_idle_arm)))
        tags.append((view, *anim_walk(look, view, bp, props, hold=hold)))
        tags.append((view, *anim_talk(look, view, bp, props, arms=arms_idle)))
        for tag, frames in specials(name, look, view, bp):
            tags.append((view, tag, frames))
    return tags


def specials(name, look, view, bp):
    """Character-specific actions."""
    out = []
    side = view == "side"

    def fr_with(legs="idle", arms=("", ""), side_arm="side_mid", far="side_mid", bob=0, props=(), blink=False,
                duration=160, seated_dy=0, hide_arms=False, mouth=False):
        f = Frame(duration)
        add_legs(f, look, view, bp, legs)
        add_upper(f, look, view, bp, bob=bob, arms=(side_arm, side_arm) if side else arms, far_arm=far, props=props,
                  blink=blink, seated_dy=seated_dy, hide_arms=hide_arms, mouth=mouth)
        return f

    strap = {"front": ["strap_front"], "back": ["strap_back"], "side": []}[view]
    if name == "mei":
        cam = {"front": ["camera_face"], "back": [], "side": ["camera_face_side"]}[view]
        out.append(("camera", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", props=strap + ["camera_chest" if view == "front" else ("camera_chest_side" if side else "strap_back")], duration=120),
            fr_with(arms=("_camera", "_camera"), side_arm="side_camera", props=strap + cam, duration=160),
            fr_with(arms=("_camera", "_camera"), side_arm="side_camera", props=strap + cam, duration=600),
        ]))
        climb = []
        for i, (legs, arms, sa) in enumerate([("lift_l2", ("_up", ""), "side_up"), ("idle", ("_up", "_up"), "side_fwd2"),
                                              ("lift_r2", ("", "_up"), "side_up"), ("idle", ("_up", "_up"), "side_fwd2")]):
            climb.append(fr_with(legs=legs if not side else ("walk" if False else "idle"), arms=arms, side_arm=sa, far="side_up",
                                 props=strap, duration=140, bob=0 if i % 2 == 0 else -1 if False else 0))
        out.append(("climb", climb))
        out.append(("reach", [
            fr_with(arms=("", "_up"), side_arm="side_up", props=strap, duration=200),
            fr_with(arms=("", "_up"), side_arm="side_up", props=strap, duration=400, bob=1),
        ]))
    if name == "son":
        bundle = {"front": ["bundle_child_front"], "back": ["bundle_child_back"], "side": ["bundle_child_side"]}[view]
        t, frames = anim_walk(look, view, bp, bundle, hold=True, tag="carry")
        out.append((t, frames))
        t, frames = anim_idle(look, view, bp, bundle, arms=("_hold", "_hold"), side_arm="side_hold", tag="carry_idle")
        out.append((t, frames))
        out.append(("work", [
            fr_with(arms=("_up", "_up"), side_arm="side_up", far="side_up", duration=220),
            fr_with(arms=("_up", "_up"), side_arm="side_up", far="side_up", bob=1, duration=220),
            fr_with(arms=("_up", ""), side_arm="side_up", far="side_fwd2", duration=220),
            fr_with(arms=("_up", "_up"), side_arm="side_up", far="side_up", bob=1, duration=220),
        ]))
    if name == "chopper":
        if side:
            out.append(("work", [
                fr_with(side_arm="side_chop_up", far="side_hold", props=["cleaver_up"], duration=160),
                fr_with(side_arm="side_chop_down", far="side_hold", props=["cleaver_down"], duration=120, bob=1),
                fr_with(side_arm="side_chop_up", far="side_hold", props=["cleaver_up"], duration=160),
                fr_with(side_arm="side_chop_down", far="side_hold", props=["cleaver_down"], duration=120, bob=1),
            ]))
        else:
            out.append(("work", [
                fr_with(arms=("_hold", "_hold"), props=["cleaver_front"] if view == "front" else [], duration=160),
                fr_with(arms=("_hold", "_hold"), props=[("cleaver_front", 0, 2)] if view == "front" else [], duration=120, bob=1),
            ]))
    if name.startswith("mahjong"):
        out.append(("sit", [fr_with(legs="seated", seated_dy=5, blink=(i == 3), bob=(1 if i in (1, 2) else 0), duration=380) for i in range(4)]))
        out.append(("work", [
            fr_with(legs="seated", seated_dy=5, arms=("_hold", "_hold"), side_arm="side_hold", duration=260),
            fr_with(legs="seated", seated_dy=5, arms=("_hold", ""), side_arm="side_fwd1", duration=200),
            fr_with(legs="seated", seated_dy=5, arms=("_hold", "_hold"), side_arm="side_hold", bob=1, duration=260),
            fr_with(legs="seated", seated_dy=5, arms=("", "_hold"), side_arm="side_fwd2", blink=True, duration=200),
        ]))
    if name == "grandfather":
        out.append(("sit", [fr_with(legs="seated", seated_dy=5, blink=(i == 3), bob=(1 if i in (1, 2) else 0), duration=420) for i in range(4)]))
    if name == "fanman":
        # up on a stool, the screwdriver's blade to the pipe overhead: listening to the water in it
        sd = {"front": ["screwdriver_up_front"], "back": [], "side": ["screwdriver_up_side"]}[view]
        out.append(("listen", [
            fr_with(arms=("", "_up"), side_arm="side_up_high", props=sd, duration=900),
            fr_with(arms=("", "_up"), side_arm="side_up_high", props=sd, blink=True, duration=300),
            fr_with(arms=("", "_up"), side_arm="side_up_high", props=sd, bob=1, duration=1100),
        ]))
        # washing the grease off his hands
        da = {"front": ["wash_drops_a"], "back": [], "side": ["wash_drops_side"]}[view]
        db = {"front": ["wash_drops_b"], "back": [], "side": []}[view]
        out.append(("wash", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=da, duration=260),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=db, bob=1, duration=260),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=da, duration=260),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=db, bob=1, blink=True, duration=300),
        ]))
        out.append(("work", [
            fr_with(legs="crouch", seated_dy=7, arms=("_hold", "_hold"), side_arm="side_hold", props=["screwdriver"] if view == "front" else [], duration=240),
            fr_with(legs="crouch", seated_dy=7, arms=("_hold", ""), side_arm="side_fwd1", duration=200),
            fr_with(legs="crouch", seated_dy=7, arms=("_hold", "_hold"), side_arm="side_hold", bob=1, props=["screwdriver"] if view == "front" else [], duration=240),
            fr_with(legs="crouch", seated_dy=7, arms=("_hold", "_hold"), side_arm="side_hold", blink=True, duration=300),
        ]))
    if name == "worker":
        out.append(("work", anim_idle(look, view, bp, default_props(look, view), arms=("_hold", "_hold"), side_arm="side_hold")[1]))
    if name in ("shopkeeper", "ext_reader"):
        paper = {"front": "newspaper_front", "back": "newspaper_back", "side": "newspaper_side"}[view]
        turn = {"front": "newspaper_front_turn", "back": "newspaper_back", "side": "newspaper_side"}[view]
        out.append(("work", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=[paper], duration=900),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=[paper], bob=1, duration=700),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=[turn], duration=300),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=[paper], blink=True, duration=900),
        ]))
    if name == "lau":
        tray = {"front": ["tray_front"], "back": [], "side": ["tray_side"]}[view]
        out.append(("work", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=tray, duration=500),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=tray, bob=1, duration=400),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=tray, duration=500),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=tray, blink=True, duration=300),
        ]))
    if name == "mum":
        # washing the red bowl under the tap
        ba = {"front": ["red_bowl_front", "wash_drops_a"], "back": [], "side": ["red_bowl_side", "wash_drops_side"]}[view]
        bb = {"front": ["red_bowl_tilt", "wash_drops_b"], "back": [], "side": ["red_bowl_side"]}[view]
        out.append(("wash", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=ba, duration=380),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=bb, bob=1, duration=320),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=ba, duration=380),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=bb, blink=True, duration=320),
        ]))
        wa = {"front": ["wrap_front_a"], "back": [], "side": ["wrap_side"]}[view]
        wb = {"front": ["wrap_front_b"], "back": [], "side": ["wrap_side"]}[view]
        out.append(("work", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wa, duration=420),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wb, bob=1, duration=320),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wa, duration=420),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wa, blink=True, duration=300),
        ]))
    if name == "kit":
        cr = {"front": ["crate_front"], "back": ["crate_back"], "side": ["crate_side"]}[view]
        t, frames = anim_walk(look, view, bp, cr, hold=True, tag="carry")
        out.append((t, frames))
        t, frames = anim_idle(look, view, bp, cr, arms=("_hold", "_hold"), side_arm="side_hold", tag="carry_idle")
        out.append((t, frames))
        # cranking the winch
        out.append(("work", [
            fr_with(arms=("_fwd", "_hold"), side_arm="side_fwd2", far="side_hold", duration=220),
            fr_with(arms=("_hold", "_fwd"), side_arm="side_fwd1", far="side_fwd2", bob=1, duration=220),
            fr_with(arms=("_fwd", "_hold"), side_arm="side_fwd2", far="side_hold", duration=220),
            fr_with(arms=("_hold", "_fwd"), side_arm="side_fwd1", far="side_fwd2", bob=1, blink=True, duration=220),
        ]))
    if name in ("chiu", "ws_hand_a", "ws_hand_b"):
        pb = {"front": ["paste_ball"], "back": [], "side": []}[view]
        # rolling fish balls between his palms, over the bowl
        out.append(("work", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=pb, duration=200),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=pb, bob=1, duration=180),
            fr_with(arms=("_hold", ""), side_arm="side_fwd1", far="side_hold", duration=220),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=pb, blink=True, duration=200),
        ]))
        mk = {"front": ["marker"], "back": [], "side": []}[view]
        out.append(("write", [
            fr_with(arms=("", "_fwd"), side_arm="side_fwd2", props=mk, duration=300),
            fr_with(arms=("", "_fwd"), side_arm="side_fwd1", props=mk, bob=1, duration=300),
        ]))
    if name == "son":
        # sitting on the plank, not about to get up
        out.append(("sit", [fr_with(legs="seated_child", seated_dy=3, blink=(i == 3), bob=(1 if i in (1, 2) else 0), duration=400) for i in range(4)]))
    if name == "chan":
        # wringing out the washing over the basin: the twist turns one way, then
        # the other, and water runs out of the hanging end
        if view == "back":
            wa, wb, da, db = [], [], [], []
        else:
            wa, wb = ["wring_%s_a" % view], ["wring_%s_b" % view]
            da, db = ["drip_%s_a" % view], ["drip_%s_b" % view]
        out.append(("work", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wa, duration=280),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wb + da, bob=1, duration=280),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wa + db, duration=280),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wb, bob=1, blink=True, duration=320),
        ]))
    if name == "ng":
        out.append(("work", [
            fr_with(arms=("", "_hold"), side_arm="side_hold", duration=260),
            fr_with(arms=("", "_fwd"), side_arm="side_fwd2", props=["grains"] if side else [], duration=180),
            fr_with(arms=("", "_hold"), side_arm="side_fwd1", props=["grains"] if side else [], duration=220),
            fr_with(arms=("", "_hold"), side_arm="side_hold", blink=True, duration=300),
        ]))
        out.append(("proud", [
            fr_with(arms=("", "_up"), side_arm="side_up", props=["pigeon_hand"] if view == "front" else [], duration=500),
            fr_with(arms=("", "_up"), side_arm="side_up", props=["pigeon_hand"] if view == "front" else [], bob=1, duration=500),
        ]))
    if name == "ext_auntie_laundry":
        out.append(("work", [
            fr_with(arms=("_up", "_up"), side_arm="side_up", far="side_up", duration=300),
            fr_with(arms=("_up", "_up"), side_arm="side_up", far="side_up", bob=1, duration=300),
            fr_with(arms=("", "_up"), side_arm="side_fwd2", far="side_up", duration=300),
            fr_with(arms=("_up", "_up"), side_arm="side_up", far="side_up", blink=True, duration=300),
        ]))
    if name == "ext_birdcage_man":
        out.append(("work", [
            fr_with(arms=("", "_fwd"), props=default_props(look, view, 0), duration=500),
            fr_with(arms=("", "_fwd"), props=default_props(look, view, 1), duration=300),
            fr_with(arms=("", "_fwd"), props=default_props(look, view, 0), bob=1, duration=500),
            fr_with(arms=("", "_fwd"), props=default_props(look, view, 1), blink=True, duration=300),
        ]))
    if name == "ext_smoker":
        if view == "front":
            out.append(("work", [
                fr_with(arms=("", "_mouth"), props=["cig_mouth_front"], duration=700),
                fr_with(arms=("", "_mouth"), props=["cig_mouth_glow"], duration=500),
                fr_with(arms=("", "_hold"), props=["cig_hand_front", "puff_front"], bob=1, duration=700),
                fr_with(arms=("", "_hold"), props=["cig_hand_front", "wisp_front"], blink=True, duration=1100),
            ]))
        elif side:
            out.append(("work", [
                fr_with(side_arm="side_mouth", props=["cig_mouth_side"], duration=700),
                fr_with(side_arm="side_mouth", props=["cig_mouth_side_glow"], duration=500),
                fr_with(side_arm="side_hold", props=["cig_hand_side", "puff_side"], bob=1, duration=700),
                fr_with(side_arm="side_hold", props=["cig_hand_side", "wisp_side"], blink=True, duration=1100),
            ]))
        else:
            out.append(("work", [
                fr_with(arms=("", "_mouth"), duration=1200),
                fr_with(arms=("", "_hold"), props=["smoke_b"], bob=1, duration=1800),
            ]))
    if name == "ext_plant_lady":
        can = {"front": ["can_front"], "back": [], "side": ["can_side"]}[view]
        pour = {"front": ["can_front_pour"], "back": [], "side": ["can_pour"]}[view]
        out.append(("work", [
            fr_with(arms=("", "_hold"), side_arm="side_hold", props=can, duration=400),
            fr_with(arms=("", "_hold"), side_arm="side_hold", props=pour, bob=1, duration=500),
            fr_with(arms=("", "_hold"), side_arm="side_hold", props=pour, bob=1, duration=500),
            fr_with(arms=("", "_hold"), side_arm="side_hold", props=can, blink=True, duration=400),
        ]))
    if name == "ext_fan_woman":
        fa = {"front": ["fan_a"], "back": [], "side": ["fan_side_a"]}[view]
        fb = {"front": ["fan_b"], "back": [], "side": ["fan_side_b"]}[view]
        out.append(("work", [
            fr_with(arms=("", "_mouth"), side_arm="side_mouth", props=fa, duration=180),
            fr_with(arms=("", "_mouth"), side_arm="side_mouth", props=fb, duration=180),
            fr_with(arms=("", "_mouth"), side_arm="side_mouth", props=fa, duration=180),
            fr_with(arms=("", "_mouth"), side_arm="side_mouth", props=fb, blink=True, duration=180),
        ]))
    if name == "ext_taichi":
        # slow, both arms drifting through the form, the weight shifting
        out.append(("work", [
            fr_with(arms=("_fwd", "_fwd"), side_arm="side_fwd2", far="side_fwd2", duration=700),
            fr_with(arms=("_up", "_fwd"), side_arm="side_up", far="side_fwd1", bob=1, duration=700),
            fr_with(legs="lift_l1" if not side else "idle", arms=("_fwd", "_up"), side_arm="side_fwd1", far="side_up", duration=700),
            fr_with(arms=("", "_fwd"), side_arm="side_fwd2", far="side_mid", bob=1, blink=True, duration=700),
        ]))
    if name == "ext_sweeper":
        ba = {"front": ["broom_front_a"], "back": [], "side": ["broom_side_a"]}[view]
        bb = {"front": ["broom_front_b"], "back": [], "side": ["broom_side_b"]}[view]
        out.append(("work", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=ba, duration=260),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=bb, bob=1, duration=260),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=ba, duration=260),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=bb, bob=1, blink=True, duration=260),
        ]))
    if name == "ext_eater":
        # the bowl in one hand; the chopsticks go from the bowl to the mouth
        if view == "front":
            out.append(("work", [
                fr_with(arms=("_hold", "_hold"), props=["bowl_front", "chop_bowl_front"], duration=500),
                fr_with(arms=("_hold", "_mouth"), props=["bowl_front", "chop_mouth_front"], duration=450),
                fr_with(arms=("_hold", "_mouth"), props=["bowl_front", "chop_mouth_front"], bob=1, duration=350),
                fr_with(arms=("_hold", "_hold"), props=["bowl_front", "chop_bowl_front"], blink=True, duration=600),
            ]))
        elif side:
            out.append(("work", [
                fr_with(side_arm="side_hold", far="side_hold", props=["bowl_side", "chop_bowl_side"], duration=500),
                fr_with(side_arm="side_mouth", far="side_hold", props=["bowl_side", "chop_mouth_side"], duration=450),
                fr_with(side_arm="side_mouth", far="side_hold", props=["bowl_side", "chop_mouth_side"], bob=1, duration=350),
                fr_with(side_arm="side_hold", far="side_hold", props=["bowl_side", "chop_bowl_side"], blink=True, duration=600),
            ]))
        else:
            out.append(("work", [fr_with(arms=("_hold", "_hold"), duration=900), fr_with(arms=("_hold", "_mouth"), bob=1, duration=700)]))
    if name in ("ext_kid_red", "ext_kid_yellow"):
        jump = []
        for i, up in enumerate([0, -2, -3, -1]):
            f = Frame(110)
            f_legs_dy = up
            add_legs(f, look, view, bp, "idle" if up == 0 else "lift_l1")
            for pl in f.placements:
                pl["y"] += f_legs_dy
            if side:
                arms = ("side_up", "side_up") if up < -1 else ("side_mid", "side_mid")
            else:
                arms = ("_up", "_up") if up < -1 else ("", "")
            add_upper(f, look, view, bp, bob=up, arms=arms, far_arm="side_up" if up < -1 else "side_mid")
            if side:
                f.placements = [p for p in f.placements]
            jump.append(f)
        out.append(("work", jump))
        out.append(("point", [
            fr_with(arms=("", "_point"), side_arm="side_up", duration=600),
            fr_with(arms=("", "_point"), side_arm="side_up", bob=1, duration=600),
        ]))
    if name == "cheung":
        # at her folding table with the address book: sitting, and writing in it
        bk = {"front": ["address_book_front"], "back": [], "side": ["address_book_side"]}[view]
        out.append(("sit", [fr_with(legs="seated", seated_dy=5, arms=("_hold", "_hold"), side_arm="side_hold", props=bk,
                                    blink=(i == 3), bob=(1 if i in (1, 2) else 0), duration=420) for i in range(4)]))
        out.append(("write", [
            fr_with(legs="seated", seated_dy=5, arms=("_hold", "_fwd"), side_arm="side_fwd1", far="side_hold", props=bk, duration=320),
            fr_with(legs="seated", seated_dy=5, arms=("_hold", "_fwd"), side_arm="side_fwd2", far="side_hold", props=bk, bob=1, duration=320),
            fr_with(legs="seated", seated_dy=5, arms=("_hold", "_hold"), side_arm="side_hold", props=bk, blink=True, duration=500),
        ]))
    if name == "cheng":
        pl = {"front": "plan_front", "back": "plan_back", "side": "plan_side"}[view]
        out.append(("work", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=[pl], duration=900),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=[pl], bob=1, duration=700),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=[pl], blink=True, duration=900),
        ]))
    if name == "mover_a":
        out.append(("work", anim_idle(look, view, bp, default_props(look, view), arms=("_hold", "_hold"), side_arm="side_hold")[1]))
    if name == "mover_b":
        # labelling the furniture with a marker
        mk = {"front": ["marker"], "back": [], "side": []}[view]
        out.append(("work", [
            fr_with(arms=("", "_fwd"), side_arm="side_fwd2", props=mk, duration=300),
            fr_with(arms=("", "_fwd"), side_arm="side_fwd1", props=mk, bob=1, duration=300),
            fr_with(arms=("", "_fwd"), side_arm="side_fwd2", props=mk, blink=True, duration=400),
        ]))
    if name == "wong":
        # wrapping a cup in newspaper
        wa = {"front": ["wrap_front_a"], "back": [], "side": ["wrap_side"]}[view]
        wb = {"front": ["wrap_front_b"], "back": [], "side": ["wrap_side"]}[view]
        out.append(("work", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wa, duration=460),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wb, bob=1, duration=360),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=wa, blink=True, duration=460),
        ]))
    if name == "kit":
        ba = {"front": ["broom_front_a"], "back": [], "side": ["broom_side_a"]}[view]
        bb = {"front": ["broom_front_b"], "back": [], "side": ["broom_side_b"]}[view]
        out.append(("sweep", [
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=ba, duration=300),
            fr_with(arms=("_hold", "_hold"), side_arm="side_hold", far="side_hold", props=bb, bob=1, duration=300),
        ]))
    if name == "chan":
        # up at the drying frame, working the poles loose
        out.append(("reach", [
            fr_with(arms=("_up", "_up"), side_arm="side_up", far="side_up", duration=300),
            fr_with(arms=("_up", "_up"), side_arm="side_up", far="side_up", bob=1, duration=300),
            fr_with(arms=("_up", ""), side_arm="side_up", far="side_fwd2", duration=300),
        ]))
    if name in ("ext_student", "ext_labourer", "ext_grandma_black"):
        out.append(("work", anim_idle(look, view, bp)[1]))
    return out


# ============================================================================= pigeon


PIGEON_FRAMES = {
    # 16 x 16, facing right; tones 1..4 body greys, 5 iridescent neck, 6 beak/feet
    "idle": [
        ["................", "................", "................", "................",
         "..........1111..", ".........111748.", ".........1115...", "....11111155....",
         "...1122222225...", "..33122222223...", "..3.1222222333..", ".....33333333...",
         "......6...6.....", "......6...6.....", "................", "................"],
        ["................", "................", "................", "................",
         "................", "..........1111..", ".........111748.", "....1111111555..",
         "...1122222225...", "..33122222223...", "..3.1222222333..", ".....33333333...",
         "......6...6.....", "......6...6.....", "................", "................"],
    ],
    "peck": [
        ["................", "................", "................", "................",
         "................", "................", "................", "....1111111.....",
         "...11222222211..", "..331222222215..", "..3.12222222557.", ".....333333314..",
         "......6...6..8..", "......6...6.....", "................", "................"],
    ],
    "fly": [
        ["................", "................", "....3...........", ".....33.........",
         "......333.......", ".......3311111..", ".....11222211748", "...3312222225...",
         "..3..33333333...", "................", "................", "................",
         "................", "................", "................", "................"],
        ["................", "................", "................", "................",
         "................", "..........1111..", ".....11122211748", "...33122222225..",
         "..3.33333333....", "......333.......", "................", "................",
         "................", "................", "................", "................"],
        ["................", "................", "................", "................",
         "................", "..........1111..", ".....11122211748", "...33122222225..",
         "..3..333333333..", ".........333....", "..........33....", "...........3....",
         "................", "................", "................", "................"],
    ],
}
# 4 the pale cere over the beak, 7 the eye, 8 the beak
PIGEON_COLORS = {"1": "#a6aab2", "2": "#8d9199", "3": "#5f636b", "4": "#e6e2da", "5": "#5d8a7a", "6": "#d08a60",
                 "7": "#1c1a1e", "8": "#4e4a50"}



ICONS = {
    # speak with someone
    "talk": ([
        "................",
        "..111111111111..",
        ".12222222222223.",
        ".12222222222223.",
        ".12242242242223.",
        ".12222222222223.",
        ".12222222222223.",
        "..233333333333..",
        "....233.........",
        "....23..........",
        "....3...........",
        "................",
    ], {"1": "#ffffff", "2": "#f2ead8", "3": "#b8ac94", "4": "#3a2a20"}),
    # look at something
    "look": ([
        "................",
        "................",
        "......1111......",
        "....11222211....",
        "..112224442211..",
        ".12222444442223.",
        ".12222445442223.",
        "..322224442223..",
        "....33222233....",
        "......3333......",
        "................",
        "................",
    ], {"1": "#ffffff", "2": "#f2ead8", "3": "#b8ac94", "4": "#2a3a5a", "5": "#ffffff"}),
    # use: doors, stairs, the crate, the ladder. A true circle, 12 across and
    # 12 down (rows 4 8 10 10 12 12 12 12 10 10 8 4), lit rim above, shade below.
    "use": ([
        "......1111......",
        "....11222211....",
        "...1222442221...",
        "...1224444223...",
        "..122444444223..",
        "..122224422223..",
        "..122224422223..",
        "..322224422223..",
        "...3222442223...",
        "...3322442233...",
        "....33222233....",
        "......3333......",
    ], {"1": "#f8d890", "2": "#e8b04a", "3": "#a8782a", "4": "#2a2018"}),
}


def icons():
    """Interaction icons shown over what Mei can use: a gentle two-frame bob."""
    tags = []
    for name, (grid, colors) in ICONS.items():
        rows = [r.ljust(16, ".")[:16] for r in grid] + ["." * 16] * (16 - len(grid))
        up = rows[1:] + ["." * 16]
        frames = []
        for g in (rows, up):
            fr = Frame(420)
            fr.add((0, 1, g), "Body", colors=colors, prop=True)
            frames.append(fr)
        tags.append(("front", name, frames))
    return tags


def pigeon():
    tags = []
    seqs = {"idle": [0, 1, 1, 0], "peck": [0, 0, 0, 0], "fly": [0, 1, 2, 1]}
    durs = {"idle": 300, "peck": 150, "fly": 80}
    for anim, seq in seqs.items():
        for view in VIEWS:
            frames = []
            for k, idx in enumerate(seq):
                fr = Frame(durs[anim])
                grid = PIGEON_FRAMES[anim][idx]
                if anim == "peck" and k in (0, 3):
                    grid = PIGEON_FRAMES["idle"][0]
                fr.add((0, 0, grid), "Body", colors=PIGEON_COLORS, prop=True)
                frames.append(fr)
            tags.append((view, anim, frames))
    return tags


# ============================================================================= output


def export():
    os.makedirs(OUT, exist_ok=True)
    chars = {}
    for name, look in LOOKS.items():
        tags = character(name, look)
        chars[name] = {
            "size": [32, 48],
            "palette": palette(look),
            "look": {k: v for k, v in look.items() if isinstance(v, (str, int, float, bool))},
            "tags": [{"name": f"{t}_{v}", "anim": t, "view": v,
                      "frames": [{"duration": f.duration, "placements": f.placements} for f in frames]}
                     for (v, t, frames) in tags],
        }
    chars["pigeon"] = {
        "size": [16, 16],
        "palette": {},
        "look": {},
        "tags": [{"name": f"{t}_{v}", "anim": t, "view": v,
                  "frames": [{"duration": f.duration, "placements": f.placements} for f in frames]}
                 for (v, t, frames) in pigeon()],
    }
    chars["icons"] = {
        "size": [16, 16],
        "palette": {},
        "look": {},
        "tags": [{"name": f"{t}_{v}", "anim": t, "view": v,
                  "frames": [{"duration": f.duration, "placements": f.placements} for f in frames]}
                 for (v, t, frames) in icons()],
    }
    path = os.path.join(OUT, "doll.json")
    with open(path, "w") as fh:
        json.dump({"characters": chars}, fh)
    total = sum(len(t["frames"]) for c in chars.values() for t in c["tags"])
    print(f"wrote {path}: {len(chars)} characters, {total} frames")


def validate():
    """Every grid row in a part must be the same width and use known symbols."""
    ok = set(".SskKHhjJTtuUBbnNFfgGAaqQewmr12345678")
    problems = 0

    def check(name, rows):
        nonlocal problems
        w = len(rows[0])
        for i, r in enumerate(rows):
            if len(r) != w:
                print(f"  {name}: row {i} is {len(r)} wide, expected {w}: '{r}'")
                problems += 1
            bad = set(r) - ok
            if bad:
                print(f"  {name}: row {i} has unknown symbols {bad}")
                problems += 1

    for mod_name in dir(P):
        obj = getattr(P, mod_name)
        _walk(mod_name, obj, check)
    for k, v in PROPS.items():
        check("prop " + k, v["part"][2])
    for k, frames in PIGEON_FRAMES.items():
        for i, g in enumerate(frames):
            check(f"pigeon {k}{i}", g)
    return problems


def _walk(name, obj, check):
    if isinstance(obj, tuple) and len(obj) == 3 and isinstance(obj[2], list) and obj[2] and isinstance(obj[2][0], str):
        check(name, obj[2])
    elif isinstance(obj, dict):
        for k, v in obj.items():
            _walk(f"{name}.{k}", v, check)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            _walk(f"{name}[{i}]", v, check)


if __name__ == "__main__":
    n = validate()
    if n:
        print(f"{n} problems in the part grids")
        sys.exit(1)
    export()
