# Project Kowloon
## Vertical Slice Implementation Guide

**Working Title:** Project Kowloon  
**Prototype Platform:** HTML / CSS / JavaScript / Three.js  
**Prototype Scope:** Approximately 15 minutes  
**Development Goal:** Prove the game's central mechanics, navigation language, social quest structure, and emotional tone before committing to full production.

---

# 1. Game Overview

## Genre

**2.5D Atmospheric Exploration Puzzle Platformer / Slice-of-Life Narrative Game**

Project Kowloon is a slow-paced exploration game set during the final period of Hong Kong's Kowloon Walled City.

The player explores an extremely dense, vertically layered neighborhood through a fixed orthographic camera. The city appears almost flat from any single angle, but the player can rotate the camera in 90-degree increments to reveal passages, align environmental structures, expose hidden routes, and understand how the architecture fits together.

The game contains no traditional combat system.

Its central activities are:

- exploring the Walled City
- learning how its spaces connect
- helping residents with interconnected everyday problems
- photographing people and places before they disappear
- gradually understanding the community through its routines
- navigating with environmental landmarks instead of a conventional minimap

The city itself should feel like the game's primary character.

At the beginning, Kowloon feels overwhelming and unreadable.

By the end, the player should understand it intimately.

---

# 2. Core Premise

The game takes place during the final weeks before the residents of the Kowloon Walled City must leave.

The player controls **Mei**, a teenager who has lived inside the city her entire life with her family.

Her family has already received notice that they will soon have to relocate.

Mei's grandfather gives her an old instant camera.

He does not ask her to document history.

He simply tells her:

> "You'll forget what things looked like."

That sentence establishes the emotional purpose of the game.

Mei begins photographing the people and places around her, not because she believes they are historically important, but because they are part of her life.

The player gradually builds a scrapbook containing:

- photographs
- names
- occupations
- locations
- historical context
- Mei's handwritten memories

The scrapbook is not intended to function like a checklist.

It represents Mei's attempt to preserve a home that cannot be saved.

---

# 3. Narrative Goal

The narrative goal of Project Kowloon is not to tell a story about saving the Walled City.

The player cannot stop the relocation.

The player cannot prevent demolition.

There is no hidden route to a "good ending" where Kowloon survives.

The central emotional arc is instead:

> **Learning how a seemingly impossible city fits together just as the community that made it function is being pulled apart.**

The game begins with the player seeing Kowloon as:

- confusing
- claustrophobic
- chaotic
- visually overwhelming
- difficult to navigate

Over time, those same spaces become recognizable.

The player begins to understand:

- which stairwell leads to which roof
- where certain families live
- which pipes lead toward major landmarks
- where the dentist works
- where laundry is normally hung
- where the pigeons are kept
- how residents depend on one another
- how small actions in one part of the neighborhood affect another

The city slowly transforms from a maze into a home.

At the same time, that home begins disappearing.

Residents leave.

Businesses close.

Rooms become empty.

Routes change.

Sounds vanish.

The final emotional objective is for the player to walk through an environment they once found confusing and realize that they now know exactly where they are, but almost nobody remains.

---

# 4. Thematic Goal

The perspective mechanic should reinforce the game's theme.

Mechanically:

> The player cannot understand Kowloon from one angle.

Narratively:

> The player cannot understand a community from one perspective.

Rotating the world reveals connections that were always there but were difficult to perceive.

The same should be true of the residents.

A person who initially appears to be a simple shopkeeper, dentist, factory worker, pigeon keeper, or neighbor gradually becomes connected to many other people in the neighborhood.

The player's growing understanding of physical space should mirror their growing understanding of the community.

---

# 5. Player Fantasy

The player fantasy is not power.

It is familiarity.

The player should gradually experience the transformation from:

> "Where am I?"

to:

> "I know this place."

Early in the game, the player follows environmental guidance carefully.

Later, they navigate from memory.

The ideal player experience is reaching a point where they can think:

> "The dentist is behind this building. If I take the blue pipe to the stairwell, go up two floors, rotate east, and cross the catwalk, I'll reach the roof."

That growing spatial literacy is one of the game's primary forms of progression.

---

# 6. Core Design Pillars

## 6.1 Perspective as Navigation

The world is real 3D geometry viewed through an orthographic camera.

The player rotates the camera by fixed 90-degree increments.

Rotation reveals:

- hidden corridors
- shafts
- stairways
- passages between buildings
- environmental alignment puzzles
- new relationships between spaces

The player should think about how the city is assembled rather than performing difficult platforming.

---

## 6.2 Community as Progression

Most obstacles should not be solved with keys, switches, or combat.

They should frequently be solved by understanding people.

A blocked walkway might exist because someone hung wet fabric across it.

The fabric cannot move until their child returns.

The child is helping another resident.

That resident has a problem of their own.

Solving one issue causes multiple parts of the neighborhood to change.

---

## 6.3 Photography as Preservation

The camera is not a scoring mechanic.

The player should not receive ratings for composition.

Photographs represent memory.

Important residents receive scrapbook entries containing both historical context and Mei's personal observations.

Example:

**Mr. Lau**  
Dentist  
Third Floor

> His new clinic will have windows.

The personal note is often more important than the factual description.

---

## 6.4 Environmental Navigation

The game should avoid a traditional minimap whenever possible.

Players navigate using:

- colored pipes
- signs
- recognizable businesses
- ambient sounds
- major stairwells
- rooftop landmarks
- lighting
- remembered routes

The city becomes easier to navigate because the player learns it.

---

## 6.5 Inevitability

The demolition and relocation are not conventional threats to defeat.

They are inevitable.

This should create a bittersweet atmosphere rather than a heroic one.

The player's goal is to understand, remember, and participate in the community while it still exists.

---

# 7. Vertical Slice Purpose

The HTML vertical slice is not intended to be a miniature version of the finished game.

It is a focused prototype designed to answer five questions:

1. Is moving through an orthographic 3D Kowloon environment enjoyable?
2. Does rotating the world by 90 degrees create understandable spatial puzzles?
3. Can players navigate using environmental clues instead of a minimap?
4. Does the resident quest chain make the city feel socially interconnected?
5. Do the camera and scrapbook mechanics create emotional investment?

Everything that does not help answer one of those questions should be postponed.

---

# 8. Vertical Slice Story

The slice is approximately 15 minutes long.

Its working title is:

## The Blue Pipe

The player begins in Mei's apartment.

Her grandfather asks her to deliver medicine to Mrs. Wong.

He tells her:

> "Follow the blue pipe. When you reach Lau's place, go up."

The route becomes the player's first lesson in navigating Kowloon.

The full sequence is:

```text
Apartment
→ Blue Pipe
→ First Perspective Puzzle
→ Dentist
→ Mr. Lau Photograph
→ Blocked Catwalk
→ Mrs. Chan
→ Search for Chan's Son
→ Airshaft Perspective Puzzle
→ Rooftop
→ Mr. Ng
→ Pigeon Interaction
→ Mr. Ng Photograph
→ Fabric Moves
→ Catwalk Reopens
→ Mrs. Wong
→ Return Home
→ Packing Boxes
→ Ending
```

---

# 9. Vertical Slice Emotional Arc

The slice should create a miniature version of the full game's emotional structure.

## Beginning

Kowloon feels confusing.

The player needs explicit instructions.

## Middle

The player begins understanding how spaces connect.

Resident problems overlap.

## Rooftop

The environment suddenly opens.

The player sees the city from a completely different emotional and visual perspective.

## Return

Previously confusing routes feel familiar.

## Ending

The player notices that Mei's family is already packing.

The larger loss becomes personal.

---

# 10. Recommended Technology

Use:

- HTML
- CSS
- JavaScript
- Three.js

Three.js handles:

- orthographic rendering
- 3D geometry
- camera rotation
- raycasting
- primitive environment construction
- sprites
- lighting
- fog

HTML and CSS handle:

- dialogue UI
- objective UI
- scrapbook
- photograph overlays
- fades
- ending screens

Do not use React initially.

Do not use a physics engine initially.

Do not use a complicated build system initially.

Do not begin with Blender assets.

The prototype should first succeed using primitive geometry.

---

# 11. Development Environment

Recommended tools:

- VS Code
- Python
- Chrome or Firefox

Suggested folder structure:

```text
project-kowloon/
│
├── index.html
├── css/
│   └── style.css
│
├── js/
│   ├── main.js
│   ├── world.js
│   ├── player.js
│   ├── camera.js
│   ├── collision.js
│   ├── interaction.js
│   ├── dialogue.js
│   ├── quests.js
│   ├── scrapbook.js
│   ├── photography.js
│   ├── audio.js
│   ├── gameState.js
│   └── data/
│       ├── residents.js
│       ├── dialogueData.js
│       └── questData.js
│
├── assets/
│   ├── sprites/
│   ├── textures/
│   ├── photos/
│   ├── ui/
│   └── audio/
│
└── README.md
```

Run locally using:

```bash
python -m http.server 8000
```

Then visit:

```text
http://localhost:8000
```

---

# 12. Basic HTML Shell

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <title>Project Kowloon Prototype</title>

    <link rel="stylesheet" href="./css/style.css">

    <script type="importmap">
    {
        "imports": {
            "three": "https://cdn.jsdelivr.net/npm/three@0.186.0/build/three.module.js"
        }
    }
    </script>
</head>

<body>

    <div id="game-container"></div>

    <div id="hud">
        <div id="objective"></div>
        <div id="interaction-prompt"></div>
    </div>

    <div id="dialogue-box" class="hidden">
        <div id="speaker-name"></div>
        <div id="dialogue-text"></div>
    </div>

    <div id="photo-overlay" class="hidden">
        <div id="viewfinder"></div>
    </div>

    <div id="scrapbook" class="hidden"></div>

    <div id="fade-screen"></div>

    <script
        type="module"
        src="./js/main.js">
    </script>

</body>
</html>
```

Pin the Three.js version rather than automatically loading the newest release.

---

# 13. Core Game Architecture

Avoid placing the entire prototype inside `main.js`.

Suggested architecture:

```text
main.js
  │
  ├── World
  ├── Player
  ├── CameraController
  ├── InteractionSystem
  ├── QuestManager
  ├── DialogueManager
  ├── PhotographySystem
  └── ScrapbookManager
```

Main game loop:

```javascript
function animate(time) {
    requestAnimationFrame(animate);

    const delta = clock.getDelta();

    player.update(delta);
    cameraController.update(delta);
    interactionSystem.update(delta);

    renderer.render(scene, camera);
}
```

Individual systems should own their own logic.

---

# 14. Global Game State

Create one centralized state object.

```javascript
export const GameState = {
    chapter: 0,

    objective: "deliverMedicine",

    cameraDirection: 0,

    controlsLocked: false,

    flags: {
        receivedCamera: false,
        photographedLau: false,
        metChan: false,
        foundChanSon: false,
        helpedNg: false,
        fabricMoved: false,
        deliveredMedicine: false,
        returnedHome: false
    },

    scrapbook: [],

    dialogueHistory: []
};
```

Do not scatter important quest state across unrelated scripts.

---

# 15. World Coordinate System

Use standard Three.js orientation:

```text
X = left/right
Y = vertical
Z = forward/back
```

Build environment pieces on a grid.

Example:

```javascript
const GRID = 2;
```

Possible position:

```javascript
{
    x: 4 * GRID,
    y: 2 * GRID,
    z: -3 * GRID
}
```

The grid makes perspective puzzles easier to reason about.

---

# 16. Graybox World Construction

Create buildings using primitive boxes.

```javascript
import * as THREE from "three";

export function createBlock({
    x,
    y,
    z,
    width,
    height,
    depth,
    color = 0x777777
}) {

    const geometry = new THREE.BoxGeometry(
        width,
        height,
        depth
    );

    const material = new THREE.MeshStandardMaterial({
        color
    });

    const mesh = new THREE.Mesh(
        geometry,
        material
    );

    mesh.position.set(x, y, z);

    return mesh;
}
```

Example:

```javascript
scene.add(createBlock({
    x: 0,
    y: 2,
    z: 0,
    width: 8,
    height: 4,
    depth: 6,
    color: 0x555555
}));
```

Start with gray geometry.

Do not start with final environment art.

---

# 17. Vertical Slice Layout

Suggested logical layout:

```text
                       ROOFTOP
                   ┌─────────────┐
                   │   Mr. Ng    │
                   │   Pigeons   │
                   └─────┬───────┘
                         │
                    AIRSHAFT
                    PUZZLE
                         │
                         │
APARTMENT ─ HALL ─ DENTIST ─ CATWALK ─ MRS. WONG
                         │        X
                         │      FABRIC
                         │
                    MRS. CHAN
```

The actual 3D map should overlap much more aggressively.

The player should repeatedly pass through roughly the same footprint at different elevations.

That creates density without requiring a huge environment.

---

# 18. Player Representation

Initially use:

- capsule
- rectangular prism
- simple billboard

Example:

```javascript
const geometry =
    new THREE.CapsuleGeometry(0.3, 0.8, 4, 8);

const material =
    new THREE.MeshStandardMaterial({
        color: 0xffaa66
    });

playerMesh =
    new THREE.Mesh(geometry, material);
```

Do not create final character art yet.

---

# 19. Controls

Recommended prototype controls:

```text
WASD / Arrow Keys = move
Q = rotate perspective left
E = rotate perspective right
F = interact
C = camera
Tab = scrapbook
Escape = close UI
```

Do not implement precision platforming initially.

---

# 20. Player Movement

Basic movement:

```javascript
const move = new THREE.Vector3();

if (keys["KeyW"]) move.z -= 1;
if (keys["KeyS"]) move.z += 1;
if (keys["KeyA"]) move.x -= 1;
if (keys["KeyD"]) move.x += 1;

move.normalize();
move.multiplyScalar(speed * delta);

player.position.add(move);
```

This should later be transformed relative to camera orientation.

---

# 21. Camera-Relative Movement

W should always mean "move deeper into the screen."

Rotate the movement vector by the current camera angle.

Conceptually:

```javascript
move.applyAxisAngle(
    new THREE.Vector3(0, 1, 0),
    cameraRotation
);
```

Players should not need to mentally remap controls after camera rotation.

---

# 22. Orthographic Camera

```javascript
const aspect =
    window.innerWidth / window.innerHeight;

const viewSize = 10;

const camera =
    new THREE.OrthographicCamera(
        -viewSize * aspect,
         viewSize * aspect,
         viewSize,
        -viewSize,
        0.1,
        100
    );
```

Use a slight downward angle.

Suggested vertical viewing angle:

```text
25° to 35°
```

The camera should remain readable rather than highly isometric.

---

# 23. Fixed Perspective Rotation

Allow only four orientations.

```javascript
const orientations = [
    0,
    Math.PI / 2,
    Math.PI,
    Math.PI * 1.5
];
```

Do not use free camera rotation.

---

# 24. Smooth 90-Degree Rotation

```javascript
function rotateRight() {

    if (rotating) return;

    rotating = true;

    targetRotation += Math.PI / 2;
}
```

Update:

```javascript
currentRotation =
    THREE.MathUtils.lerp(
        currentRotation,
        targetRotation,
        0.12
    );
```

Finish:

```javascript
if (
    Math.abs(
        currentRotation - targetRotation
    ) < 0.001
) {
    currentRotation = targetRotation;
    rotating = false;
}
```

Target duration:

```text
300 to 450 ms
```

---

# 25. Lock Movement During Rotation

During prototype development:

```javascript
GameState.controlsLocked = true;
```

Unlock after rotation completes.

This prevents collision and readability problems.

---

# 26. Perspective Puzzle Types

## Type A: Hidden Spatial Route

The route physically exists.

Rotation makes it visible.

This teaches the camera mechanic.

Example:

```text
Front View

████████

Looks blocked


Side View

██      ██
   PATH
```

## Type B: Perspective Alignment

Objects at different depths visually align from one orientation.

Example:

```text
Laundry Pole
+
Old Sign
+
AC Platform
+
Ladder
```

When viewed correctly, they form a route.

Use Type B sparingly.

The airshaft should be the main example in this slice.

---

# 27. Simplified Perspective Collision

Do not build mathematically perfect impossible geometry.

Activate authored traversal elements based on perspective.

Example:

```javascript
function updatePerspectivePlatforms(direction) {

    airshaftPlatform.visible =
        direction === 2;

    airshaftPlatform.userData.collidable =
        direction === 2;
}
```

This is acceptable for prototyping.

The goal is to prove the mechanic is fun.

---

# 28. Collision

Use simple bounding boxes.

```javascript
THREE.Box3
```

Obstacle:

```javascript
const box =
    new THREE.Box3().setFromObject(mesh);
```

Before moving:

```javascript
const proposedPosition =
    player.position.clone().add(move);
```

Test for intersection.

Cancel movement when blocked.

A full physics engine is unnecessary.

---

# 29. Vertical Movement

Avoid full jumping physics.

Use floor levels and authored climbing transitions.

Possible variable:

```javascript
currentFloorY
```

Ladders can move the player between known points.

```javascript
player.position.y = rooftopHeight;
```

Animate transitions if desired.

---

# 30. Interaction System

Use a common interactable structure.

```javascript
{
    id: "lau_dentist",

    position: new THREE.Vector3(...),

    interactionRadius: 1.5,

    canInteract: () => true,

    interact: () =>
        startDialogue("lau_intro")
}
```

Distance test:

```javascript
const distance =
    player.position.distanceTo(
        interactable.position
    );
```

If close:

```text
[F] Talk
```

---

# 31. Interaction Priority

If multiple objects are nearby:

1. NPC dialogue
2. quest object
3. environmental description
4. decorative interaction

Only one prompt should appear.

---

# 32. Dialogue System

Use data-driven dialogue.

```javascript
export const DialogueData = {

    grandfather_intro: [
        {
            speaker: "Grandfather",
            text: "Take this to Mrs. Wong."
        },

        {
            speaker: "Mei",
            text: "Again?"
        },

        {
            speaker: "Grandfather",
            text:
                "Follow the blue pipe. " +
                "When you reach Lau's place, go up."
        }
    ]
};
```

Dialogue should:

1. lock controls
2. show speaker
3. show text
4. advance on Space or click
5. run optional callbacks
6. unlock controls

---

# 33. Dialogue UI

Simple prototype presentation:

```text
┌────────────────────────────────────────┐

 MR. LAU

 "Apparently I'm getting a real
  office after this."

                               [SPACE]

└────────────────────────────────────────┘
```

Do not add portraits until needed.

---

# 34. Environmental Navigation

The blue pipe is the player's first navigation tool.

Create it physically in the world.

It should:

- begin near Mei's apartment
- travel through corridors
- disappear behind geometry
- reappear near Lau's clinic
- continue upward

Do not add floating waypoint arrows.

---

# 35. Objective UI

Objectives should remind rather than solve.

Good:

```text
Bring Grandfather's medicine to Mrs. Wong.
```

Context hint:

```text
Grandfather said to follow the blue pipe.
```

After Lau:

```text
Find a way upstairs.
```

Avoid exact distances or map markers.

---

# 36. First Perspective Puzzle

The blue pipe appears to lead into a dead end.

Prompt:

```text
[E] Rotate Perspective
```

The player rotates.

A narrow corridor becomes visible.

The tutorial prompt disappears permanently.

This should demonstrate the game's central mechanic almost immediately.

---

# 37. Mr. Lau Sequence

The player reaches the dentist.

Lau is already packing some equipment.

His dialogue casually introduces relocation.

Example:

```text
Mei:
You're packing already?

Lau:
Your mother hasn't started?

Mei:
She says she has.

Lau:
Then she hasn't.
```

Lau asks for a photograph.

This introduces photography.

---

# 38. Camera Mode

Press:

```text
C
```

Effects:

- movement locks
- normal HUD fades
- viewfinder appears
- photographable targets become detectable

Keep camera mode simple.

No complex zoom system is required yet.

---

# 39. Photograph Detection

Raycast from screen center.

```javascript
const raycaster = new THREE.Raycaster();

raycaster.setFromCamera(
    new THREE.Vector2(0, 0),
    camera
);
```

If a valid subject is centered:

```text
[SPACE] Take Photo
```

---

# 40. Fake Polaroid Effect

Do not create live screenshots initially.

When taking a picture:

1. flash screen white
2. play shutter audio
3. briefly freeze
4. show predetermined Polaroid art
5. slowly reveal image
6. unlock scrapbook entry

Example file:

```text
assets/photos/lau-placeholder.png
```

---

# 41. Scrapbook Data

```javascript
export const Residents = {

    lau: {
        name: "Mr. Lau",
        occupation: "Dentist",
        location:
            "Third Floor, Lung Chun Road",

        note:
            "His new clinic will have windows.",

        photo:
            "./assets/photos/lau-placeholder.png"
    },

    ng: {
        name: "Mr. Ng",
        occupation: "Pigeon Keeper",

        note:
            "Mr. Ng says they know the way home " +
            "better than people do.",

        photo:
            "./assets/photos/ng-placeholder.png"
    }
};
```

Unlock:

```javascript
GameState.scrapbook.push("lau");
```

---

# 42. Scrapbook UI

Open with:

```text
Tab
```

Example:

```text
PROJECT KOWLOON

┌───────────────────────────┐
│        [ PHOTO ]          │
│                           │
│ MR. LAU                   │
│ Dentist                   │
│ Third Floor               │
│                           │
│ "His new clinic will      │
│  have windows."           │
└───────────────────────────┘
```

Do not show completion percentages.

Do not make the scrapbook feel like a collectible checklist.

---

# 43. Blocked Catwalk

The player tries to continue toward Mrs. Wong.

Wet fabric blocks the route.

Interaction:

```text
Wet fabric blocks the walkway.
```

Camera rotation should not solve this problem.

This establishes:

> Perspective solves spatial problems. People solve social problems.

---

# 44. Mrs. Chan Quest

Example dialogue:

```text
Mei:
Can you move these?

Mrs. Chan:
And let them mildew?

Mrs. Chan:
My boy was supposed to carry them upstairs.
I haven't seen him all afternoon.
```

Quest state:

```javascript
GameState.objective = "findChanSon";
GameState.flags.metChan = true;
```

Hint:

```text
"He's probably gone up to the roof again."
```

No waypoint appears.

---

# 45. Airshaft Perspective Puzzle

The player reaches a vertical airshaft.

Objects exist at different depths:

- old ladder
- AC unit
- laundry pole
- shop sign
- maintenance platform

From most directions they appear disconnected.

From one angle they align.

For example:

```javascript
cameraDirection === 2
```

activates the traversal arrangement.

Avoid magical visual effects.

A subtle sound or slight material change is enough.

---

# 46. Airshaft Traversal

Do not implement precision jumping.

Use predefined climb nodes.

```javascript
const climbNodes = [
    pointA,
    pointB,
    pointC,
    rooftopEntrance
];
```

Interaction:

```text
[F] Climb
```

Animate the player between nodes.

This proves the puzzle without building a full platformer.

---

# 47. Rooftop Reveal

When the player reaches the roof:

1. interior ambience fades
2. wind fades in
3. lighting brightens
4. sky becomes dominant
5. camera pulls back slightly
6. UI remains quiet
7. player receives a few seconds with no dialogue

The contrast should be dramatic.

Interior:

```text
dark
compressed
mechanical
warm artificial light
crowded
```

Rooftop:

```text
bright
open
windy
blue sky
pigeons
distant city
```

This should be the visual centerpiece of the slice.

---

# 48. Kai Tak Plane

Use a simple placeholder model.

Trigger one flyover on first rooftop entry.

```javascript
if (!planeSequencePlayed) {
    playPlaneSequence();
}
```

Simple motion:

```javascript
plane.position.x += speed * delta;
```

Audio should sell the moment more than geometry.

---

# 49. Mrs. Chan's Son

The player finds him near Mr. Ng.

He cannot leave immediately because Ng needs help with a pigeon.

This creates a simple dependency:

```text
Mrs. Chan
    ↓
Her Son
    ↓
Mr. Ng
```

This demonstrates how residents affect one another.

---

# 50. Mr. Ng Interaction

One pigeon is inaccessible.

Perspective rotation aligns a route.

Interaction:

```text
[F] Guide pigeon
```

No actual bird AI is needed.

Once completed:

```javascript
GameState.flags.helpedNg = true;
```

Animate the pigeon returning to the cage.

---

# 51. Mr. Ng Photograph

After the interaction:

```text
Mei:
Can I take one?

Ng:
Of me?

[Plane approaches]

Ng:
Get the birds in it.
```

Switch into camera mode.

Use a predetermined rooftop photograph for the prototype.

Scrapbook note:

> Mr. Ng says they know the way home better than people do.

---

# 52. World State Change

After Ng's scene:

```javascript
GameState.flags.helpedNg = true;
```

Chan's son leaves the rooftop.

The fabric moves.

```javascript
if (GameState.flags.helpedNg) {
    moveFabricToRooftop();
}
```

The same fabric should physically appear on the rooftop afterward.

Do not simply delete it.

This creates spatial continuity.

---

# 53. Catwalk Reopens

Back downstairs, the route is now clear.

```javascript
GameState.flags.fabricMoved = true;
```

Disable the fabric collision.

Do not display:

```text
QUEST COMPLETE
```

Let the player notice the environmental change.

---

# 54. Mrs. Wong

The player delivers the medicine.

```javascript
GameState.flags.deliveredMedicine = true;
```

Dialogue:

```text
Mrs. Wong:
Your grandfather sent this?

Mei:
Yeah.

Mrs. Wong:
Tell him I'm not leaving before he does.

Mei:
What does that mean?

Mrs. Wong:
He'll know.
```

Objective becomes:

```text
Return home.
```

---

# 55. Return Journey

Do not teleport the player.

Make them navigate back physically.

The return journey tests whether they have learned the space.

The player should now recognize:

- the catwalk
- Lau's clinic
- the blue pipe
- the original corridor
- the apartment route

This is one of the slice's most important design tests.

---

# 56. Apartment Ending

Grandfather avoids explaining Wong's comment.

The player regains control.

Packing boxes are visible behind him.

Important:

The boxes should have been present during the opening scene.

They were simply easy to overlook.

The goal is for the player to realize:

> The family is already preparing to leave.

The game should not announce this.

---

# 57. Ending

Fade to black.

Display:

```text
30 DAYS UNTIL WE LEAVE
```

Then:

```text
PROJECT KOWLOON
```

Then optionally:

```text
VERTICAL SLICE COMPLETE
```

Avoid collectible statistics.

---

# 58. Quest State Machine

Use explicit states.

```javascript
export const QuestStage = {
    START: 0,
    MEDICINE_RECEIVED: 1,
    REACHED_LAU: 2,
    LAU_PHOTO: 3,
    CATWALK_BLOCKED: 4,
    MET_CHAN: 5,
    SEARCHING_FOR_SON: 6,
    FOUND_SON: 7,
    HELPED_NG: 8,
    FABRIC_MOVED: 9,
    MEDICINE_DELIVERED: 10,
    RETURNED_HOME: 11,
    COMPLETE: 12
};
```

For this prototype:

**Linear narrative, spatial freedom.**

Do not build branching quest logic yet.

---

# 59. Ambient NPCs

Add approximately five to eight low-cost background characters.

Examples:

- woman chopping vegetables
- child sitting on stairs
- fan repairman
- factory worker carrying boxes
- residents playing mahjong
- shopkeeper reading a newspaper

Each needs very little functionality.

Possible lines:

```text
"Watch the pipe."

"Your grandfather looking for you?"

"Don't run on the stairs."
```

These make the city feel larger than it is.

---

# 60. Billboard Characters

Three.js sprites face the camera automatically.

```javascript
const texture =
    textureLoader.load("./assets/sprites/lau.png");

const material =
    new THREE.SpriteMaterial({
        map: texture,
        transparent: true
    });

const sprite =
    new THREE.Sprite(material);

sprite.scale.set(1, 2, 1);
```

This matches the intended 2D-character / 3D-world style.

---

# 61. Temporary Character Art

Initially use colors.

Example:

```text
Mei          orange
Grandfather  beige
Lau          green
Chan         purple
Chan's son   blue
Ng           brown
Wong         pink
```

Then move to silhouettes.

Then real sprite art.

---

# 62. Lighting

Start with:

```text
AmbientLight
DirectionalLight
```

Interior:

- lower ambient light
- localized artificial lighting

Rooftop:

- brighter ambient light
- stronger directional light
- clearer sky

Do not begin with elaborate neon.

---

# 63. Fog

Example:

```javascript
scene.fog =
    new THREE.Fog(
        0x22252a,
        12,
        35
    );
```

Interior fog can limit visibility and make the environment feel denser.

Reduce it dramatically on the rooftop.

---

# 64. Occlusion

Buildings may block the player from view.

For the prototype, fade obstructing geometry.

```javascript
material.opacity = 0.2;
material.transparent = true;
```

Use camera-to-player raycasts to detect occluders.

A sophisticated cutaway system can come later.

---

# 65. Audio Zones

Audio is critical.

## Apartment

- fan
- TV through wall
- cooking
- pipes

## Interior Corridor

- voices
- machinery
- water
- electrical hum
- footsteps

## Dentist

- dental drill
- radio
- metal tools

## Rooftop

- wind
- pigeons
- distant traffic
- aircraft
- children

Temporary royalty-free sound is sufficient.

---

# 66. Audio as Navigation

Important locations should be audible before visible.

Examples:

Dentist:

```text
dental drill
```

Rooftop:

```text
wind + pigeons
```

Home:

```text
Grandfather's radio
```

This helps the player navigate naturally.

---

# 67. Navigation Assistance

Do not implement the full glowing trail system initially.

First test:

- pipes
- environmental signage
- ambient audio
- dialogue hints
- recognizable spaces
- player memory

If playtesters become genuinely lost, add assistance later.

---

# 68. Optional Hint System

Possible fallback:

```text
Hold C to Remember
```

Briefly emphasize an environmental clue.

Examples:

- blue pipe pulses
- dentist sign gains contrast
- rooftop exit becomes easier to notice

Do not draw a complete route.

---

# 69. Save System

The first slice does not require saves.

If desired, use:

```javascript
localStorage
```

Example:

```javascript
localStorage.setItem(
    "kowloonSave",
    JSON.stringify(GameState)
);
```

Load:

```javascript
const save =
    localStorage.getItem("kowloonSave");

if (save) {
    Object.assign(
        GameState,
        JSON.parse(save)
    );
}
```

Do not build save slots yet.

---

# 70. Debug Overlay

Press:

```text
F1
```

Show:

```text
Player XYZ
Camera Direction
Quest Stage
Objective
Nearby Interactable
FPS
```

Example:

```text
X: 12.2
Y: 4
Z: -3.7

Camera: EAST
Quest: FIND_CHAN_SON
Interactable: none
FPS: 60
```

Build this early.

---

# 71. Debug Teleportation

Developer shortcuts:

```text
1 = Apartment
2 = Dentist
3 = Mrs. Chan
4 = Airshaft
5 = Rooftop
6 = Mrs. Wong
```

This dramatically speeds iteration.

---

# 72. Debug Quest Controls

Useful prototype commands:

```text
F2 = advance quest stage
F3 = rewind quest stage
```

Or create a tiny hidden developer panel.

---

# 73. Development Milestone 1

Build only:

- gray room
- gray corridor
- player capsule
- orthographic camera
- WASD movement
- Q/E rotation
- collision

Success condition:

Walking and rotating feels comfortable.

Do not proceed until this works.

---

# 74. Development Milestone 2

Build one perspective puzzle.

```text
corridor looks blocked
→ rotate
→ route appears
→ walk through
```

Success condition:

A new player understands what happened without explanation.

---

# 75. Development Milestone 3

Graybox the full level.

No NPCs.

No dialogue.

No final art.

Verify traversal:

```text
Apartment
→ Dentist
→ Chan
→ Airshaft
→ Rooftop
→ Catwalk
→ Wong
→ Apartment
```

Fix spatial readability now.

---

# 76. Development Milestone 4

Add primary residents:

- Grandfather
- Lau
- Chan
- Chan's son
- Ng
- Wong

Use colored rectangles.

Implement dialogue and quest progression.

---

# 77. Development Milestone 5

Implement:

- camera mode
- photography
- Lau photo
- Ng photo
- scrapbook

Success condition:

Players understand why Mei is photographing people.

---

# 78. Development Milestone 6

Add environmental storytelling:

- boxes
- dental equipment
- laundry
- pipes
- signs
- pigeons
- chairs
- fans
- workshop clutter

Continue using primitive geometry if needed.

---

# 79. Development Milestone 7

Add audio before final visuals.

Sound may contribute more to the sense of density than early art.

---

# 80. Development Milestone 8

Replace temporary NPC shapes with prototype sprites.

Suggested sizes:

```text
32x64
or
48x96
```

Possible animation:

```text
Idle: 2 frames
Working: 2 to 4 frames
Walking: 4 frames
```

Billboards remove the need for eight-direction sprites.

---

# 81. Development Milestone 9

Begin simple environment texturing.

Palette direction:

```text
concrete gray
dirty green
warm yellow
rust brown
faded red
pipe blue
fluorescent white
```

Avoid turning Kowloon into generic cyberpunk.

Density and human activity are more important than neon.

---

# 82. Development Milestone 10

Polish the rooftop.

Spend disproportionate effort here.

Improve:

- sky
- lighting
- wind
- pigeons
- plane
- cloth
- distant skyline
- audio transition

This is the likely trailer shot.

---

# 83. Playtesting Questions

Do not over-explain before testing.

Observe:

## Perspective

Does the player understand rotation?

## Navigation

Can they follow the blue pipe?

## Spatial Memory

Can they return home?

## Quest Logic

Do they understand why the fabric moved?

## Photography

Do they care about taking the photos?

## Scrapbook

Do they voluntarily open it?

## Rooftop

Do they stop and look around?

## Ending

Do they notice the boxes?

---

# 84. Timing Targets

Record:

```text
Apartment exit
First camera rotation
Lau reached
Chan reached
Rooftop reached
Wong reached
Home reached
```

Rough pacing:

```text
Apartment       1 to 2 min
Dentist         3 to 5 min
Chan            5 to 7 min
Airshaft        7 to 10 min
Rooftop         10 to 12 min
Wong            12 to 14 min
Ending          14 to 16 min
```

These are diagnostic targets, not hard limits.

---

# 85. Minimum Viable Prototype

Mechanical completion requires:

- player movement
- orthographic camera
- four camera orientations
- smooth camera rotation
- camera-relative controls
- collision
- apartment
- dentist
- Chan area
- airshaft
- rooftop
- catwalk
- Wong apartment
- blue pipe
- six main NPCs
- dialogue
- quest state
- fabric state change
- camera mode
- two photographs
- scrapbook
- ending

---

# 86. Features Explicitly Deferred

Do not add:

- combat
- procedural generation
- dynamic weather
- full day/night cycle
- hundreds of NPCs
- advanced schedules
- multiple endings
- branching conversation trees
- currency
- food systems
- crafting
- stealth
- parkour
- photo scoring
- relationship meters
- complex inventory
- procedural clutter
- advanced shaders
- realistic pigeon AI
- broad city districts

These can distract from validating the core concept.

---

# 87. Recommended Build Order

Build in this order:

```text
1. HTML shell
2. Three.js scene
3. Orthographic camera
4. Player movement
5. Camera-relative controls
6. 90° camera rotation
7. Collision
8. First perspective puzzle
9. Entire graybox map
10. Interaction system
11. Dialogue system
12. Quest state manager
13. Main NPCs
14. Chan → Son → Ng dependency
15. Fabric world-state change
16. Photography
17. Scrapbook
18. Full story progression
19. Ending
20. Debug tools
21. Audio
22. Temporary sprites
23. Basic textures
24. Lighting pass
25. Rooftop polish
26. Playtesting
27. Navigation fixes
28. Presentation polish
```

Do not begin with polished art.

---

# 88. Code Responsibility Map

```text
main.js
Scene creation and main loop

world.js
Environment geometry

player.js
Movement and player state

camera.js
Orthographic camera and perspective rotation

collision.js
Bounding-box collision

interaction.js
Interaction detection

dialogue.js
Dialogue presentation

quests.js
Quest progression

photography.js
Camera mode and photo targets

scrapbook.js
Resident archive and scrapbook UI

gameState.js
Shared global state

audio.js
Ambient zones and transitions
```

---

# 89. Prototype Success Criteria

The prototype succeeds if a player says something close to:

> "At first I had no idea where anything was, but by the end I knew how that little neighborhood connected."

That is the primary success condition.

The second is:

> "I liked those people."

The third is:

> "I want to see more of this city."

If all three reactions occur while the game is still mostly gray boxes and placeholder sprites, the concept is working.

---

# 90. Transition to Godot

Do not assume the final game should remain in HTML.

After validating the slice, evaluate rebuilding it in Godot.

The conceptual mapping is straightforward:

```text
Three.js Scene
→ Godot Scene

Mesh
→ MeshInstance3D

Sprite
→ Sprite3D

GameState
→ Autoload Singleton

QuestManager
→ QuestManager Node

DialogueManager
→ Dialogue UI Scene

CameraController
→ Camera3D Script

Interactable
→ Area3D

HTML Scrapbook
→ Control UI

Box3 Collision
→ CollisionShape3D
```

The HTML prototype is still valuable even if none of its production code survives.

It validates:

- spatial design
- perspective rules
- navigation language
- pacing
- narrative structure
- quest dependencies
- photography
- emotional tone

---

# 91. The First Actual Build

Do not begin by building the full vertical slice.

Build:

```text
Mei
↓
Small hallway
↓
Fake dead end
↓
Rotate camera
↓
Hidden corridor
↓
Dentist room
```

No dialogue.

No photography.

No scrapbook.

No rooftop.

No story logic.

Only movement, rotation, and one spatial reveal.

If walking toward what appears to be a dead end, rotating the world, and discovering the hidden passage feels satisfying, continue.

If that ten-second interaction does not work, fix it before building anything else.

That interaction is the mechanical foundation of Project Kowloon.

---

# 92. Long-Term Narrative Direction

If the vertical slice succeeds, the full game should expand the same structure rather than dramatically broaden the mechanics.

The larger game can introduce:

- additional neighborhoods
- more resident relationships
- more perspective puzzles
- chapter-based time progression
- increasingly empty areas
- altered routes as residents leave
- businesses closing
- scrapbook growth
- environmental changes associated with relocation

The game's emotional escalation should come from the city changing, not from adding combat or traditional action systems.

---

# 93. Final Narrative Destination

The complete game should eventually return the player to spaces they know extremely well.

Near the ending, most residents have left.

The lights are quieter.

Shops are empty.

Machines have stopped.

Some routes are no longer useful.

The player walks through the same corridors where they once relied on pipes, voices, laundry, businesses, and neighbors to orient themselves.

Now they know every turn.

The city is finally easy to understand.

It is also gone.

The completed scrapbook becomes proof that the spaces were once full of people.

That contrast should be the emotional destination of Project Kowloon.
