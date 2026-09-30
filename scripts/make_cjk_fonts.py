"""The Chinese fonts: only the characters the game actually uses.

Every string lives in data/i18n/strings.csv. This cuts the Traditional
Chinese faces down to the characters in it (plus ASCII and CJK punctuation),
so the build carries a few hundred kilobytes instead of tens of megabytes.

  * Noto Sans TC (Regular, Medium, Bold): the fallback behind IBM Plex for
    every interface font
  * LXGW WenKai TC: the fallback behind Caveat, for Mei's handwriting in the
    scrapbook, and Mum's marker on the packing box

Both are SIL Open Font License; the licences are copied next to the fonts.
The full source fonts are downloaded once into tools/fonts/src (ignored by
git and by Godot).

Run from the project root after changing any Chinese text:
    python scripts/make_cjk_fonts.py
"""

from __future__ import annotations

import csv
import os
import urllib.request

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "tools", "fonts", "src")
OUT = os.path.join(ROOT, "assets", "fonts", "cjk")
STRINGS = os.path.join(ROOT, "data", "i18n", "strings.csv")

SOURCES = {
    "NotoSansTC.ttf": "https://github.com/google/fonts/raw/main/ofl/notosanstc/NotoSansTC%5Bwght%5D.ttf",
    "NotoSansTC-OFL.txt": "https://github.com/google/fonts/raw/main/ofl/notosanstc/OFL.txt",
    "LXGWWenKaiTC-Regular.ttf": "https://github.com/lxgw/LxgwWenkaiTC/releases/download/v1.522/LXGWWenKaiTC-Regular.ttf",
    "LXGWWenKaiTC-OFL.txt": "https://raw.githubusercontent.com/lxgw/LxgwWenkaiTC/main/OFL.txt",
}

# drawn into textures rather than read from the string table (scripts/make_props.py)
EXTRA = "新屋"
PUNCTUATION = "，。、；：？！「」『』（）《》〈〉——⋯…・　·—–‘’“”●‹›"


def fetch() -> None:
    os.makedirs(SRC, exist_ok=True)
    marker = os.path.join(SRC, ".gdignore")
    if not os.path.exists(marker):
        open(marker, "w").close()
    for name, url in SOURCES.items():
        path = os.path.join(SRC, name)
        if not os.path.exists(path):
            print("downloading", name)
            urllib.request.urlretrieve(url, path)


def characters() -> str:
    chars = set(chr(c) for c in range(0x20, 0x7F))
    chars.update(PUNCTUATION)
    chars.update(EXTRA)
    with open(STRINGS, encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh):
            chars.update(row["zh_HK"].replace("\\n", ""))
    return "".join(sorted(chars))


def cut(font: TTFont, text: str, path: str) -> None:
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    opts.hinting = False
    sub = subset.Subsetter(opts)
    sub.populate(text=text)
    sub.subset(font)
    font.save(path)
    print("wrote %s (%d KB)" % (os.path.relpath(path, ROOT), os.path.getsize(path) // 1024))


def main() -> None:
    fetch()
    os.makedirs(OUT, exist_ok=True)
    text = characters()
    for weight, name in [(400, "Regular"), (500, "Medium"), (700, "Bold")]:
        vf = TTFont(os.path.join(SRC, "NotoSansTC.ttf"))
        static = instancer.instantiateVariableFont(vf, {"wght": weight}, updateFontNames=True)
        cut(static, text, os.path.join(OUT, "NotoSansTC-%s.ttf" % name))
    cut(TTFont(os.path.join(SRC, "LXGWWenKaiTC-Regular.ttf")), text, os.path.join(OUT, "LXGWWenKaiTC-Regular.ttf"))
    for lic in ("NotoSansTC-OFL.txt", "LXGWWenKaiTC-OFL.txt"):
        with open(os.path.join(SRC, lic), encoding="utf-8") as src, open(os.path.join(OUT, lic), "w", encoding="utf-8") as dst:
            dst.write(src.read())
    print("%d characters" % len(text))


if __name__ == "__main__":
    main()
