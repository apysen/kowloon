"""Adds new words to the game: conversations into the dialogue catalog, and
every line and label into data/i18n/strings.csv (English and Chinese side by
side). Existing keys can be rewritten in place.

    python scripts/add_text.py path/to/words.py

The words file defines SCENES (a list of (id, lines), each line a tuple of
speaker, English, Chinese and optionally an event), STRINGS (a list of (key,
English, Chinese)), and optionally REPLACE (the same, for keys already in the
table). Run scripts/make_cjk_fonts.py afterwards if the Chinese is new, and
reimport in Godot so the .translation files follow.
"""

from __future__ import annotations

import csv
import importlib.util
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STRINGS_CSV = os.path.join(ROOT, "data", "i18n", "strings.csv")
CATALOG = os.path.join(ROOT, "src", "core", "models", "dialogue", "dialogue_catalog.gd")


def load(path: str):
    spec = importlib.util.spec_from_file_location("words", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return getattr(mod, "SCENES", []), getattr(mod, "STRINGS", []), getattr(mod, "REPLACE", [])


def main(path: str) -> None:
    scenes, strings, replace = load(path)
    raw = io.open(STRINGS_CSV, encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in raw else "\n"
    rows = list(csv.reader(io.StringIO(raw)))
    index = {r[0]: i for i, r in enumerate(rows) if r}
    for key, en, zh in replace:
        assert key in index, f"nothing to replace: {key}"
        rows[index[key]] = [key, en, zh]
    new = []
    for sid, lines in scenes:
        for i, ln in enumerate(lines):
            new.append([f"dlg.{sid}.{i + 1:02d}", ln[1], ln[2]])
    new += [list(s) for s in strings]
    for r in new:
        assert r[0] not in index, f"already in the table: {r[0]}"
    out = io.StringIO()
    w = csv.writer(out, lineterminator=nl)
    for r in rows + new:
        w.writerow(r)
    io.open(STRINGS_CSV, "w", encoding="utf-8", newline="").write(out.getvalue())

    if scenes:
        src = io.open(CATALOG, encoding="utf-8", newline="").read()
        nl = "\r\n" if "\r\n" in src else "\n"
        block = []
        for sid, lines in scenes:
            assert f'"{sid}": [' not in src, f"conversation exists: {sid}"
            block.append(f'\t"{sid}": [')
            for i, ln in enumerate(lines):
                ev = f', "event": "{ln[3]}"' if len(ln) > 3 else ""
                block.append(f'\t\t{{"speaker": "{ln[0]}", "text": "dlg.{sid}.{i + 1:02d}"{ev}}},')
            block.append("\t],")
        end = nl + "}" + nl + nl + nl + "static func lines("
        assert src.count(end) == 1
        src = src.replace(end, nl + nl.join(block) + end)
        io.open(CATALOG, "w", encoding="utf-8", newline="").write(src)
    print(f"{len(new)} new strings, {len(replace)} rewritten, {len(scenes)} conversations")


if __name__ == "__main__":
    main(sys.argv[1])
