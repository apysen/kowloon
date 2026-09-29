# Project Kowloon

Kowloon Walled City, 1992: the last weeks before the move. Mei's grandfather needs his medicine taken to Mrs. Wong, and gives her his old instant camera: *"You'll forget what things looked like."*

This repository holds the Godot build of the vertical slice, **The Blue Pipe** (about fifteen minutes). It's HD-2D: hand-pixelled characters in a lit, textured 3D diorama, seen through an orthographic camera you turn in quarter steps.

- `docs/Project_Kowloon_Vertical_Slice_Implementation_Guide.md` is the design guide.
- `docs/STATE_OF_THE_GAME.md` describes what is built and how, as of now.
- `project-kowloon/project-kowloon/` is the original Three.js prototype. The Godot build follows its routes, puzzles and timing exactly.

## Run it

Open the folder in **Godot 4.7** (Forward+) and press Play, or:

```sh
godot --path .
```

| Key | Action |
|---|---|
| WASD / arrows | Move (camera-relative: W is always into the screen) |
| Q / E | Turn the view 90° |
| F | Interact / advance dialogue |
| Space | Advance dialogue, take a photo, keep the Polaroid |
| C | Raise / lower the camera (WASD frames the shot) |
| Tab | Scrapbook |
| Esc | Close the camera or scrapbook; otherwise pause (volume, graphics, quit to title) |
| G | Graphics: full / fast |
| F1 or ` | Debug overlay. While it's open: 1–6 teleport, F2 / ] next stage, F3 / [ previous |

## How it looks the way it does

- **Characters** are pixel art authored in **Aseprite**. Each has front, back and side views with idle, walk, talk and their own actions (climbing, carrying, chopping, reading, feeding pigeons…). They stand on camera-facing cards that are lit by the scene and cast silhouette shadows toward the sun.
- **No clipping.** Every fragment of a character card writes the depth of one anchor point, so a character sorts as a single object: wholly in front of a wall or wholly behind it, never sliced. Mei's footprint keeps her centre clear of walls, and a warm silhouette shows her through anything that hides her.
- **Environments** use one world-space triplanar shader over an HD surface library (plaster, glazed tile, mosaic, terrazzo, timber, board-formed concrete, bitumen, rusted and painted metal, fabric, tower-block facades with lit windows), tinted per piece.
- **The city** is laid out from the 1985 Kai Fong Association map: the 210 × 120 m plot, its named alleys, the yamen at the centre, and the boundary roads (see `docs/STATE_OF_THE_GAME.md`). It is the whole Walled City block with 3D window cages, air conditioners and laundry on every face that sees daylight. The rooftop plateau has aerials, tanks, huts, pigeon lofts, washing, plants and people. The Kowloon City tenements across the road have their balconies (every one different). The horizon has Lion Rock, the Kai Tak checkerboard hill and the runway.
- **Lighting and finish:** warm lamps, fluorescent tubes, depth fog, SSAO/SSIL, glow, golden-hour sun on the roof, then a tilt-shift and film grade over the top.

## Rebuilding assets

All generated assets are committed. Rebuild only what you change:

| What | Command |
|---|---|
| Surface textures | `python scripts/make_textures.py` |
| Signs, notices, sky, UI paper | `python scripts/make_props.py` |
| Soundscape (WAV) | `python scripts/make_audio.py` |
| Characters, pigeon, plants | `python scripts/sprite_catalog.py`, then run `tools/aseprite/build_characters.lua` in Aseprite |
| Level (`scenes/slice/level.tscn`) | `godot --headless --path . --script res://tools/level/bake_level.gd` |
| Scenes and UI theme | `godot --headless --path . --script res://tools/scenes/build_scenes.gd` |

To run the character build in Aseprite, use the aseprite MCP's `run_lua_script` with `dofile("…/tools/aseprite/build_characters.lua")`, or run `aseprite -b --script tools/aseprite/build_characters.lua`. Set `ONLY = "mei"` first to rebuild one character. The `.aseprite` files in `assets/sprites/aseprite/` are the editable source: layers (Legs, Body, Arms, Head, Hair, Prop), one tag per animation and view (`walk_side`), and frame durations. The body parts are hand-pixelled grids in `scripts/sprite_parts.py`. The catalog decides which parts make each frame, and all pixel work (palette swap, outlines, compositing, export) happens in Aseprite.

## Checks

```sh
godot --path . --script res://tests/integration/playthrough.gd     # plays the slice start to ending
godot --path . --script res://tests/performance/fps_probe.gd       # frame rate at the heaviest spots
godot --path . --script res://tools/capture/capture.gd -- <dir> "name:x,y,z:dir:stage[:action]"   # screenshots
```

## Layout

Organised the way *Sporekeeper* is: scenes hold nodes, `src/core/` holds all the code in layers, there are no autoloads, and one root coordinates components under `GameplayComponents`.

```
scenes/app/            title screen (main scene)
scenes/slice/          slice.tscn (SliceRoot) and the baked level.tscn
scenes/ui/             hud, dialogue, photo (viewfinder, polaroid), scrapbook, menus, debug
scenes/characters/     resident.tscn
src/core/models/       quest stages, dialogue catalog, residents, sprite sheets, level data, surfaces
src/core/rules/        walk space (collision), view maths, perspective rules
src/core/nodes/        slice root, world, player, camera, characters, quests, dialogue,
                       interaction, photography, scrapbook, audio, ui
tools/                 level bake, scene builder, Aseprite build, capture
scripts/               texture, prop, audio and sprite-catalog generators
tests/                 playthrough, performance
```
