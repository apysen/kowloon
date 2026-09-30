# Localization

The game ships in English (`en`) and Traditional Chinese for Hong Kong (`zh_HK`).

## Where the text lives

Every string a player can see is a row in `data/i18n/strings.csv`: a key, the English, the Chinese. Code and scenes only ever hold keys (`dlg.lau_intro.03`, `pause.resume`, `verb.look`). Godot imports the CSV into `strings.en.translation` and `strings.zh_HK.translation`.

| Prefix | What |
|---|---|
| `dlg.<conversation>.<nn>` | dialogue lines, in the order `DialogueCatalog` lists them |
| `speaker.<id>` | names on the dialogue tag (`speaker.grandfather` → 公公) |
| `obj.*` | objectives and their hints (`QuestStage.OBJECTIVES`) |
| `res.<id>.<field>` | scrapbook entries (`ResidentCatalog`) |
| `env.*`, `verb.*`, `notice.*`, `hint.*` | looks, interaction verbs, notices, tutorial hints |
| `camera.*`, `scrapbook.*`, `pause.*`, `title.*`, `ending.*`, `ui.*` | interface |

## Voice

- Spoken lines are written Cantonese (唔、咗、嘅、喺、啲), the way these people spoke.
- Narration, objectives and the interface are standard written Chinese.
- Quotes use 「」. Ellipses use ⋯⋯.
- Grandfather is **公公**, Mum's father, as Chapter 1 now establishes. Keep the names in the `speaker.*` rows consistent everywhere.

## Rules

- **No text in code.** Pass a key. Plain `Label` and `Button` text can be the key itself: Godot translates it and updates it when the language changes. Text that is formatted or built into BBCode (keycaps) goes through `tr()`, and is drawn again on `NOTIFICATION_TRANSLATION_CHANGED` (see `Hud`, `PauseMenu`, `TitleScreen`).
- **No gluing.** Whole sentences with named placeholders: `"{occupation} — {location}"`, `"pages {from}–{to} of {total}"`, filled with `tr(key).format({...})`. The Chinese can reorder them.
- **Keycaps.** Write keys as `[F]` in both languages. `UIStyle.keycaps` draws them and keeps each key on the same line as its word.
- **Room to grow.** Wrapped labels use `AUTOWRAP_WORD_SMART`. Chinese can break between any two characters, so give a short line enough width to stay on one line, or put a `\n` in the translation at a natural pause (see `scrapbook.quote`).
- **Text in textures.** In-world signage is bilingual Hong Kong signage and stays as it is. A texture that is only English, like Mum's NEW FLAT carton, gets a `_zh` twin and a remap in `project.godot` (`locale/translation_remaps`).

## Adding or changing text

1. Add or edit the row in `data/i18n/strings.csv`, English and Chinese together.
2. If the Chinese uses new characters: `python scripts/make_cjk_fonts.py`. The Chinese fonts are cut down to the characters in the table.
3. Check everything:

   ```
   godot --headless --path . --script res://tests/localization/strings_check.gd
   ```

   This fails on:
   - a missing key or a blank Chinese entry
   - mismatched `{placeholders}` or `[keycaps]` between the languages
   - a character missing from the fonts
   - English prose left in a script
4. To play or capture in one language: `KOWLOON_LOCALE=zh_HK` (or `en`) overrides the saved choice.

## Fonts

IBM Plex and Caveat have no Chinese. `LocaleSettings.setup()` gives each a Chinese fallback:

- Noto Sans TC behind the interface fonts
- LXGW WenKai TC behind Caveat, for Mei's handwriting in the scrapbook

Both are SIL OFL. Their licences sit next to them in `assets/fonts/cjk/`. `scripts/make_cjk_fonts.py` downloads the full source fonts once into `tools/fonts/src/`, which git and Godot both ignore.

## Choosing the language

On first run the game follows the system language: any Chinese locale gets `zh_HK`. After that, the Language button on the title screen or in the pause menu switches it live and remembers the choice in `user://settings.cfg`.

The debug overlay (F1) stays in English.
