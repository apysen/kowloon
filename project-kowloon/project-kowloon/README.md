# Project Kowloon — Vertical Slice: *The Blue Pipe*

A playable HTML / CSS / JavaScript / Three.js prototype built from the
*Project Kowloon Vertical Slice Implementation Guide*. HD-2D presentation
(pixel-art characters in a lit, textured 3D diorama), procedural audio. About
15 minutes.

## Run it

```bash
python -m http.server 8000
```

Then open <http://localhost:8000>. Three.js r186 (pinned, `three@0.186.0`) loads
from jsDelivr through the import map in `index.html`, so the first load needs
an internet connection.

## Controls

| Key | Action |
|---|---|
| WASD / Arrows | Move (camera-relative; W is always "into the screen") |
| Q / E | Rotate perspective 90° |
| F | Interact / advance dialogue |
| Space | Advance dialogue, take photo, keep Polaroid |
| C | Raise / lower the camera (WASD frames the shot) |
| Tab | Scrapbook |
| Esc | Close UI |
| G | Graphics: full / fast (turns off shadows, bloom and depth of field) |
| F1 or ` | Debug overlay |

With the debug overlay open: `1`–`6` teleport (Apartment, Dentist, Mrs. Chan,
Airshaft, Rooftop, Mrs. Wong), `F2` / `]` advance quest stage, `F3` / `[` rewind.
The overlay also records the playtest timing marks from section 84.

## The route

Apartment → blue pipe → dead end (a service door you can only see by turning the
view) → Mr. Lau (photo) → stairs → blocked catwalk → Mrs. Chan → airshaft (find
handholds on three different walls) → rooftop reveal + Kai Tak flyover → Chan's
son → Mr. Ng → find the lost pigeon behind the water tank, then unpin the sheet
blocking her view of the coop → Ng photo → the Chan boy opens the stuck roof door,
takes the washing down in front of Mei and hangs it on the roof → catwalk clear →
Mrs. Wong → walk home → the boxes → ending.

## Perspective rules

Nothing appears or disappears when the view turns. Turning only changes what Mei
can see, and **she can only use what she has seen.**

- **Doors** are solid until discovered. A door is discovered when the camera looks
  at it face-on (not edge-on) with Mei nearby. The service door at the end of the
  hall faces back down the hall, so from the starting view it's edge-on. Clues: warm
  light spilling under it onto the hall floor, the blue pipe running into the wall
  above it, and Lau's drill.
- **Airshaft handholds** are each on a different wall: the ladder faces east, the
  shop sign faces west, the platform faces south. Mei can only climb once she has
  seen all three.
- **The pigeon** is really hidden behind the water tank (checked with a ray against
  the tank). Once found, the sheet between her and the coop is the problem to solve.
- **Closed rooms** keep a lid on and hide their furniture and people until Mei
  walks in. Their walls only fade where they stand directly in front of her.
- **Mei's silhouette** shows through anything that hides her.
- The camera sits lower than the guide suggests (18° instead of 25-35°) so walls
  hide more.
- Prompts use the same verb from every side. A soft chime plays when something is
  discovered.

## HD-2D look

- **Characters** are pixel art painted in code (`js/sprites.js`): 26×44 frames,
  four walk frames and two idle breathing frames, dark outline. They sit on
  billboards that receive light and cast real shadows.
- **Environments** use procedural textures with matching normal maps
  (`js/textures.js`): plaster, tiles, wood, concrete, tar, rust, fabric and a
  tower-block facade with lit windows, window cages, AC units and laundry.
  Textures are mapped at world scale so detail stays the same size everywhere.
- **Lighting**: a shadow-casting sun (golden hour on the roof), warm point lights
  in each room, neon signs, hanging cables, drifting dust, a gradient sky.
- **Post-processing** (`js/postfx.js`): bloom, tilt-shift depth of field (the
  diorama blur at the top and bottom of the screen), and a film grade with warm
  highlights, cool shadows, vignette and grain.
- Press **G** on slower machines. The setting is remembered.

## Code map (section 88)

```
js/main.js          scene, renderer, input, main loop
js/world.js         level, blue pipe, filler buildings, cutaway, lighting, dressing
js/player.js        movement, authored climb paths
js/camera.js        orthographic camera (18° pitch), fixed 90° rotation (380 ms ease)
js/collision.js     floor rectangles + box obstacles (no physics engine)
js/interaction.js   nearby interactable, priority NPC > quest > env > decor
js/dialogue.js      data-driven dialogue box
js/quests.js        quest state machine, discovery, story beats
js/photography.js   camera mode, centre raycast, Polaroid placeholders
js/scrapbook.js     scrapbook UI
js/audio.js         procedural ambience zones (WebAudio, no files)
js/sprites.js       pixel-art character painter, signs, neon
js/textures.js      procedural surface textures + normal maps
js/postfx.js        bloom, tilt-shift, colour grade
js/gameState.js     the single shared state object
js/debug.js         F1 overlay, teleports, stage controls
js/data/            residents, dialogue, objectives
```

## Prototype shortcuts worth knowing

- **All art is generated in code**, so the slice runs with no asset files.
  Hand-drawn sprite sheets can replace the painter in `js/sprites.js` (same
  frame layout: 6 frames in one row), and photographed or painted textures can
  replace `js/textures.js` surface by surface.
- **Levels are cut away**: geometry above Mei's floor is hidden, and anything
  standing between her and the camera fades.
- **Photos are predetermined.** Drop `assets/photos/lau-placeholder.png` or
  `ng-placeholder.png` in place and they replace the painted placeholders.
- **Deferred on purpose**: saves and the "Hold to Remember" hint (sections 68, 69).
