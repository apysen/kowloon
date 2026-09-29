# Project Kowloon
## Full Narrative Implementation Specification

**Working title:** Project Kowloon  
**Current build basis:** Godot 4.7 vertical slice, *The Blue Pipe*  
**Narrative span:** The final 30 days before Mei's family leaves the Kowloon Walled City  
**Target full-game length:** Approximately 5 to 7 hours  
**Structure:** Linear narrative, spatial freedom, optional resident stories  
**Primary narrative systems:** Perspective rotation, social quest chains, photography, scrapbook, environmental state change, remembered navigation

---

# 0. Purpose of This Document

This is the production-facing narrative specification for expanding *The Blue Pipe* into the complete game.

It is intended to map directly onto the current Godot architecture:

- quest stages and story state
- dialogue catalog
- resident data
- interaction director
- photography and scrapbook systems
- world state and cutaway logic
- level bake references
- scripted integration tests

Every major sequence below defines:

1. narrative purpose
2. scene IDs
3. player objective
4. NPC placement
5. exact or near-final dialogue
6. perspective puzzle logic
7. required world-state changes
8. scrapbook changes
9. setup and payoff flags
10. completion conditions
11. optional interactions
12. testable implementation notes

The document assumes the current vertical slice remains the mechanical and tonal foundation.

---

# 1. Canon and Historical Grounding

## 1.1 Current game canon

The existing vertical slice is canon.

It establishes:

- Mei lives with her family in the Kowloon Walled City in 1992.
- Her family is already preparing to relocate.
- Grandfather gives Mei an old instant camera.
- His reason is simple: "You'll forget what things looked like."
- Mei can rotate her view in 90-degree increments.
- Perspective reveals physical relationships that are difficult to perceive from one angle.
- Social problems are solved through residents rather than through abstract keys or switches.
- Photography is preservation, not scoring.
- The scrapbook is personal rather than completionist.
- The first completed journey is from Grandfather's flat to Mrs. Wong and back.
- Mr. Lau, Mrs. Chan, Wai, Mr. Ng, Mrs. Wong, Mr. Kwok, and the repairman already exist in the playable world.
- Chapter 1 ends with the packing boxes and the card: **30 DAYS UNTIL WE LEAVE**.

## 1.2 Historical substrate

The game is historical fiction.

The following broad elements are historically grounded and can be used freely as environmental or occupational substrate:

- extremely dense mixed residential and commercial occupation
- improvised and resident-shaped internal spaces
- narrow alleys and difficult navigation
- unlicensed dental clinics
- small manufacturing workshops
- food manufacturing
- rooftop social and practical life
- low-flying Kai Tak aircraft
- ongoing relocation and clearance activity during the final years
- residents with different and conflicting attitudes toward leaving

Named story characters, their family histories, specific conversations, quests, and the exact arrangement of their homes and businesses are fictional unless explicitly documented elsewhere in the project.

Do not present a fictional resident as a real historical person.

## 1.3 Historical tone rule

Do not reduce Kowloon to either:

- a romantic lost paradise
- a lawless horror attraction

The game should allow both statements to be true:

- living there could be difficult, crowded, improvised, dark, and inconvenient
- it could still be home, familiar, socially rich, and worth grieving

---

# 2. Narrative North Star

## 2.1 Dramatic question

**Can Mei learn how to say goodbye to a place without treating goodbye as the same thing as forgetting it?**

## 2.2 Controlling idea

**A home survives through the people who carry it with them, even when the place itself cannot remain.**

## 2.3 Counter-premise

**If something is going to disappear anyway, holding onto it only makes leaving harder.**

No character should fully represent the "correct" answer.

Grandfather, Mum, Kit, Lau, Chan, Ng, Wong, Ho, Cheung, and Cheng should embody different responses to the same approaching loss.

## 2.4 Player fantasy

The fantasy is not power.

It is familiarity.

The intended progression is:

> Where am I?

to:

> I know this place.

The final mechanical proof is that the player can navigate a changed, partially emptied City without a waypoint.

---

# 3. Mei's Character Arc

## State A: Familiar but inattentive

Mei already knows her neighborhood physically, but she treats most of its details as ordinary background.

Grandfather gives her the camera.

She begins looking.

## State B: Curious observer

Photography makes her notice people and routines she previously took for granted.

The scrapbook is playful.

Her notes are dry and funny.

## State C: Recorder

People begin leaving.

The camera becomes more important.

Mei begins recording places because she is afraid they will vanish.

## State D: Preserver

She begins behaving as though a photograph can keep a moment from ending.

The player should feel a slight shift from curiosity to compulsion without turning this into a mental-health story.

## State E: Participant

Mei realizes that preserving a moment and participating in it are not the same thing.

On the final rooftop evening, she chooses not to photograph an available moment.

## State F: Carried memory

Grandfather photographs Mei.

For the first time, Mei is the subject rather than the recorder.

She understands that she was part of the City too.

---

# 4. Global Narrative State

Recommended high-level state object:

```gdscript
class_name NarrativeState

var chapter: int = 1
var day_countdown: int = 30
var main_stage: StringName
var optional_flags: Dictionary = {}
var resident_states: Dictionary = {}
var location_states: Dictionary = {}
var scrapbook_entries: Dictionary = {}
var setup_flags: Dictionary = {}
var inventory_story_items: Array[StringName] = []
```

## 4.1 Chapter IDs

```text
CH01_BLUE_PIPE
CH02_WATER_LINE
CH03_LAST_BATCH
CH04_THREE_ADDRESSES
CH05_ROOMS_GOING_QUIET
CH06_LAST_ROOF
CH07_WAY_OUT
```

## 4.2 Countdown values

```text
Chapter 1: 30 days
Chapter 2: 24 days
Chapter 3: 18 days
Chapter 4: 12 days
Chapter 5: 6 days
Chapter 6: 1 day
Chapter 7: 0 days
```

Do not simulate all thirty days.

Each chapter is a selected day.

## 4.3 Resident state model

Suggested values:

```text
PRESENT_NORMAL
PRESENT_PACKING
PRESENT_MOVING
MOVED
RETURNED_VISIT
ABSENT_TEMPORARY
```

Do not merely hide residents.

Each `MOVED` state must be paired with an environmental state.

Example:

```text
lau = MOVED
lau_clinic = EMPTY_WITH_BUSINESS_CARD
lau_drill_audio = OFF
lau_fluorescent = ON
```

---

# 5. Core Cast Bible

# 5.1 Mei

**Age:** approximately 15  
**Role:** player character  
**Want:** to keep her familiar world from slipping away unnoticed  
**Need:** to understand that remembering is not the same as preventing change  
**Voice:** dry, practical, mildly sarcastic, rarely poetic

Voice rules:

- short sentences
- questions when genuinely curious
- jokes under pressure
- never delivers the theme
- does not narrate obvious emotions

Example:

```text
Grandfather:
Take the camera.

Mei:
I'm delivering medicine.

Grandfather:
The camera won't make it heavier.

Mei:
It absolutely will.
```

---

# 5.2 Grandfather

**Role:** emotional anchor and first guide  
**Want:** to leave without admitting how much leaving hurts  
**Need:** to let Mei carry part of the memory he has carried alone  
**Voice:** practical directions, deliberate understatement, teasing deflection

Navigation language:

- "Follow the blue pipe."
- "Turn after the place that smells like sesame oil."
- "Go up where the fan rattles."

He should use formal street names less often than younger or official characters.

---

# 5.3 Mum

**Role:** strongest counter-premise  
**Want:** to complete the move and get the family settled safely  
**Need:** to let Mei see that readiness to leave is not indifference  
**Voice:** efficient, tired, funny when annoyed

She is genuinely pleased by:

- reliable water
- a lift
- windows
- legal utilities
- more space

The story must respect this.

---

# 5.4 Ah Kit

**Role:** Mei's closest friend and peer counterpoint  
**Want:** to move and begin the next part of life  
**Need:** to maintain connection without pretending nothing changes  
**Voice:** quick, teasing, less sentimental than Mei

Kit moves before Mei and later returns for the last rooftop evening.

---

# 5.5 Mr. Lau

**Role:** continuity from Chapter 1, evidence that leaving can improve parts of life  
**Want:** to reopen his clinic elsewhere  
**Need:** confidence that his patients will still find him

Payoff:

His new clinic does have windows.

---

# 5.6 Mrs. Chan

**Role:** practical adult who wants uncertainty finished  
**Want:** to get her household moved  
**Need:** very little arc; she provides texture and a grounded attitude

She is mostly relieved.

---

# 5.7 Wai Chan

**Role:** Mrs. Chan's son  
**Want:** excitement, shortcuts, rooftop freedom  
**Need:** to say goodbye without treating it as solemn

Wai should make some of the most emotional environmental changes feel casual.

---

# 5.8 Mr. Ng

**Role:** pigeon keeper, recurring metaphor without becoming a metaphor machine  
**Want:** to relocate his birds safely  
**Need:** to accept that a new roof has to become familiar

Key payoff:

```text
Mei:
You said they know the way home.

Ng:
They know this one.

Ng:
We'll teach them another.
```

---

# 5.9 Mrs. Wong

**Role:** Grandfather's oldest argumentative friend  
**Want:** to leave on her own terms  
**Need:** none stated directly

Her relationship with Grandfather is expressed almost entirely through insult, implication, and old habits.

---

# 5.10 Mr. Kwok

**Role:** newspaper stall owner and human landmark  
**Want:** to keep his routine until the last practical day  
**Narrative function:** his absence makes navigation emotionally unfamiliar

Progression:

```text
Turn after Kwok.
```

becomes:

```text
Turn where Kwok used to be.
```

---

# 5.11 Mr. Ho

**Role:** fan and appliance repairman  
**Want:** to keep things functioning until there is nobody left to use them  
**Need:** no grand arc  
**Voice:** dry, technical only in the practical sense, complains as affection

Important concept:

He does not "own" the utility system.

He knows it because someone had to.

---

# 5.12 Uncle Chiu

**Role:** small food-workshop owner  
**Want:** to finish the final production run in this location  
**Need:** to separate the business from the building

Suggested workshop: fish-ball production.

Do not claim the specific character is historical.

---

# 5.13 Mrs. Cheung

**Role:** elderly resident associated with the yamen old people's centre  
**Want:** to collect forwarding addresses  
**Need:** to preserve connections, not places

She introduces the scrapbook's `AFTER` layer.

---

# 5.14 Mr. Cheng

**Role:** clearance official  
**Want:** to complete difficult relocation work without becoming a cartoon villain  
**Need:** to understand resident geography that plans cannot capture

He must never be the antagonist.

He embodies a different perspective.

---

# 6. Chapter Overview

| Chapter | Countdown | Core theme | Main puzzle language | Major world change |
|---|---:|---|---|---|
| 1. The Blue Pipe | 30 | Learning to look | Occlusion, basic spatial reveal | Packing becomes visible |
| 2. The Water Line | 24 | Nothing works alone | Connection tracing | Water restored, then future shutdown foreshadowed |
| 3. Last Batch | 18 | Work makes place | Vertical logistics | Workshops begin closing |
| 4. Three Addresses | 12 | People continue elsewhere | Map versus lived route | `AFTER` scrapbook section unlocked |
| 5. Rooms Going Quiet | 6 | Absence changes space | Negative-space navigation | Multiple residents gone |
| 6. The Last Roof | 1 | Being present | Multi-roof circuit tracing | Final communal evening |
| 7. The Way Out | 0 | Carrying memory | Mastery, then anti-puzzle | Mei leaves |

---

# 7. CHAPTER 1
# THE BLUE PIPE
## 30 DAYS UNTIL WE LEAVE

The current vertical slice remains canon and should be preserved.

## CH01_S00_TITLE

**Player control:** none  
**NPCs:** none  
**Purpose:** establish title and existing rooftop visual identity

Transition to apartment.

---

## CH01_S01_GRANDFATHER_FLAT

**Objective:** Receive medicine.  
**NPCs:** Grandfather  
**Required props:** medicine, camera, packing boxes, old photograph

Core dialogue remains current.

Add only these seeds:

### Inspectable old photograph

Before camera handoff:

```text
[LOOK]

An old photograph.

Mei:
You look weird.

Grandfather:
I was young.

Mei:
That's what I said.
```

Do not yet identify everyone in it.

Flag:

```text
setup_old_photo_seen = true
```

### New-address box

A box in the background may be readable only if the player deliberately faces it.

Label:

```text
NEW FLAT
```

No commentary.

---

## CH01_S02_PERSPECTIVE_TUTORIAL

Keep current self-turn and Q/E teaching.

Design rule:

The first rotation should feel like revelation, not spectacle.

---

## CH01_S03_SERVICE_DOOR

Keep current dead-end reveal.

Puzzle family:

**Occlusion puzzle**

Nothing moves because the camera turns.

The camera reveals the service door.

---

## CH01_S04_LAU_CLINIC

Keep Mr. Lau's scene and photograph.

Add one optional line if the player talks again after the photo:

```text
Lau:
New place has windows.

Mei:
You keep saying that.

Lau:
You don't work under fluorescent tubes all day.
```

Flag:

```text
setup_lau_windows = true
```

---

## CH01_S05_CATWALK_BLOCKED

Keep current wet washing.

Narrative rule established:

**Perspective solves spatial problems. People solve social problems.**

---

## CH01_S06_MRS_CHAN

Keep current wringing animation and quest.

---

## CH01_S07_AIRSHAFT

Keep current crate-behind-fridge perspective puzzle.

Puzzle family:

**Occlusion plus access**

---

## CH01_S08_ROOF

Keep Wai, Mr. Ng, lost pigeon, and water-tank reveal.

---

## CH01_S09_NG_PHOTO

Keep aircraft-timed photograph.

Flag:

```text
setup_ng_home_line = true
```

Scrapbook:

```text
MR. NG
Pigeon keeper

Mr. Ng says they know the way home better than people do.
```

---

## CH01_S10_WASHING_MOVES

Keep physical movement of same fabric to the roof.

World-state principle:

Never make resolved story objects disappear without explanation.

---

## CH01_S11_MRS_WONG

Keep:

```text
Mrs. Wong:
Tell him I'm not leaving before he does.

Mei:
What does that mean?

Mrs. Wong:
He'll know.
```

Flag:

```text
setup_wong_bet = true
```

---

## CH01_S12_RETURN_HOME

No teleport.

The player proves first-stage spatial memory.

---

## CH01_S13_END

Packing boxes are now emotionally legible.

Add:

```text
Grandfather:
Two already?

Mei:
You gave me a camera.

Grandfather:
I didn't tell you to use it.

Mei:
That's generally what cameras are for.
```

Fade.

```text
30 DAYS UNTIL WE LEAVE
```

---

# 8. CHAPTER 2
# THE WATER LINE
## 24 DAYS UNTIL WE LEAVE

## Chapter purpose

Expand Kowloon from a set of rooms into a system.

The player should leave this chapter thinking:

**The City functions because many people know partial pieces of how it works.**

---

## CH02_S00_COLD_OPEN

**Location:** Mei's apartment  
**NPCs:** Mei, Grandfather, Mum  
**Audio:** water pump tries to engage, stalls, engages, stalls

Mum is packing dishes.

Dialogue:

```text
[PUMP STARTS]
[PUMP STOPS]

Grandfather:
That's not right.

Mum:
Wonderful.

Mei:
What?

Mum:
No water.

Grandfather:
Pump's trying.

Mum:
Very considerate of it.
```

Objective:

```text
Find Mr. Ho.
```

NPC placement:

- Grandfather seated
- Mum beside open kitchen boxes
- red bowl visible and usable
- radio still present
- more boxes than Chapter 1

Setup:

```text
setup_red_bowl = true
```

---

## CH02_S01_FIND_HO

**Location:** lower corridor near repair stall  
**NPCs:** Mr. Ho, two ambient residents

Ho is listening to a pipe with the handle of a screwdriver.

Dialogue:

```text
Mei:
Grandpa says the pump sounds wrong.

Ho:
Pump sounds fine.

Mei:
We don't have water.

Ho:
Exactly.

Mei:
That doesn't sound fine.

Ho:
Pump is working. Water isn't getting where it's going.

Mei:
Why?

Ho:
Someone shut something.

Mei:
Who?

Ho:
If I knew that, this would be a shorter conversation.
```

Ho points upward.

```text
Ho:
Blue branch. Follow it until it stops being blue.

Mei:
Why does it stop being blue?

Ho:
Paint ran out.
```

Objective:

```text
Trace the water line.
```

---

# 9. CH02 Perspective Puzzle
# FOLLOW THE WATER

## Puzzle concept

A multi-stage connection puzzle.

The camera does not alter the pipe network.

It reveals which pipes connect.

## Required geometry

At minimum:

- three visually overlapping vertical pipe runs
- one light-well crossing
- two air-conditioning cages
- one abandoned unit
- one shared kitchen opening
- one service ledge
- three valves
- one audible pipe branch

## CH02_P01_PIPE_IDENTIFICATION

From the default view, blue pipe A and faded blue pipe B appear to intersect.

Rotate 90 degrees.

Their depth separation becomes obvious.

Correct branch has:

- a small clamp
- audible knocking synchronized with pump
- paint fading near ceiling

No objective marker on the pipe.

Optional Mei line after two incorrect rotations:

```text
Mei:
Blue until it isn't. Very helpful.
```

Completion flag:

```text
water_trace_1 = true
```

---

## CH02_P02_LIGHT_WELL

The correct pipe crosses behind three AC units.

From west:

It appears to enter Mrs. Fong's room.

From north:

The player sees the pipe pass behind the exterior wall and continue toward an abandoned unit.

Puzzle family:

**Connection**

Completion:

```text
water_trace_2 = true
```

---

## CH02_P03_ABANDONED_UNIT_ACCESS

Front door chained.

Interaction:

```text
The door is chained from the outside.
```

No key quest.

Rotate east.

Reveal a shared kitchen window and narrow service ledge.

The player enters from the back.

Puzzle family:

**Access**

---

## CH02_P04_VALVES

Three valves.

Each pipe can be traced only by rotating between two views.

Wrong valve A:

A shower of water is heard elsewhere.

```text
Resident, distant:
HEY!
```

Ho, through wall:

```text
Ho:
Not that one.
```

Valve resets automatically.

Wrong valve B:

Old sink coughs brown water.

Mei:

```text
No.
```

Correct valve:

Pipe shudders.

Global water audio returns in layers.

---

## CH02_S02_WATER_RETURNS

Do not cut immediately.

Let the player walk back through the building while hearing:

- basin filling
- kettle
- pipe vibration
- someone flushing
- Mrs. Chan calling to Wai
- water hitting metal

At Ho:

```text
Mei:
Fixed.

Ho:
For now.

Mei:
That's encouraging.

Ho:
They'll shut this riser when Cheung's floor goes.

Mei:
When?

Ho:
Next week. Maybe.

Mei:
So we'll do this again.

Ho:
No.

[beat]

Ho:
Won't be anybody here.
```

This is the scene outcome.

The player solved the physical problem.

The larger problem remains inevitable.

---

## CH02_S03_HO_PHOTO

Photo becomes available while Ho washes grease from his hands.

If player frames him:

```text
Ho:
What?

Mei:
Nothing.

Ho:
That thing has a flash.

Mei:
Then don't blink.
```

Scrapbook:

```text
MR. HO
Repairs things

He says nobody built the water system. Everybody did.
```

Later addendum in Chapter 5:

```text
The pipes were still there after the water stopped.
```

---

## CH02_S04_MUM_AFTER

Back home.

Water runs.

Mum is washing the red bowl.

Dialogue:

```text
Mum:
Thank Ho.

Mei:
I helped.

Mum:
Then thank yourself quietly.

Mei:
You're welcome.

Mum:
I was talking to the bowl.
```

Optional inspect new-flat brochure:

```text
Mei:
"Reliable running water."

Mum:
Luxury.

Grandfather:
Marketing.
```

End chapter.

```text
24 DAYS UNTIL WE LEAVE
```

World changes after fade:

- first distant unit becomes empty
- one TV audio source removed
- one corridor stack of boxes appears
- packing density in Mei apartment increases slightly

---

# 10. CHAPTER 3
# LAST BATCH
## 18 DAYS UNTIL WE LEAVE

## Chapter purpose

Show the City as a place of work.

Make community cooperation function like machinery.

Introduce Kit fully.

---

## CH03_S00_OPEN

**Location:** corridor outside Mei's flat

New repeated industrial sound:

```text
THUMP
THUMP
THUMP
```

Mei exits.

Kit appears carrying an empty plastic crate.

```text
Kit:
There you are.

Mei:
I live here.

Kit:
Not for long.

Mei:
You came all the way over to be annoying?

Kit:
Uncle needs hands.

Mei:
He has hands.

Kit:
Useful ones.
```

Objective:

```text
Go with Kit.
```

---

## CH03_S01_CHIU_WORKSHOP

Environment:

- cramped food-production room
- steam
- bowls
- tubs
- wet floor
- packed crates
- loud fan
- repetitive work animation

Uncle Chiu:

```text
Chiu:
Don't stand there.

Mei moves.

Chiu:
Not there either.

Kit:
This is how he welcomes people.

Chiu:
Final shipment. Stair's blocked. Loading route's half gone.

Mei:
What do you need me to do?

Chiu:
Find me a way from here to the street that does not involve lifting twelve crates down seven flights by hand.

Kit:
He means please.

Chiu:
I do not.
```

Objective:

```text
Rebuild the loading route.
```

---

# 11. CH03 Perspective Puzzle
# THE VERTICAL FACTORY

## Core concept

The player reconstructs a vertical logistics path through:

- balconies
- hoists
- a pulley
- a removable signboard
- two workshop roofs
- a loading platform
- a shared staircase

The route is never visible from one angle.

## Required social dependencies

The route cannot be solved only by geometry.

Needed components:

- rope from Mr. Ng
- plank from Mrs. Chan
- pulley knowledge from Mr. Ho
- Kit operating lower platform

This is deliberate.

Perspective identifies what is possible.

Relationships make it usable.

---

## CH03_P01_FIND_THE_OLD_ROUTE

Chiu points to a ceiling opening.

```text
Chiu:
Crates used to go up.

Mei:
Why up if the street is down?

Chiu:
Because down was worse.
```

Player traces old rope marks.

Rotate south.

Reveal pulley above neighboring balcony.

Flag:

```text
factory_route_pulley_found = true
```

---

## CH03_P02_NG_ROPE

Mr. Ng on roof.

```text
Mei:
Do you have rope?

Ng:
Everyone has rope.

Mei:
Can I have yours?

Ng:
Then I won't.
```

Beat.

He hands it over.

```text
Ng:
Bring it back.

Mei:
We're leaving.

Ng:
Then bring it back quickly.
```

Inventory:

```text
story_item_rope
```

---

## CH03_P03_CHAN_PLANK

Mrs. Chan packing.

Wai sits on plank.

```text
Mei:
Can I borrow that?

Wai:
I'm using it.

Mei:
For what?

Wai:
Sitting.

Mrs. Chan:
Get up.
```

Inventory:

```text
story_item_plank
```

World seed:

Some laundry already boxed.

---

## CH03_P04_HO_PULLEY

Ho inspects pulley.

```text
Ho:
It'll hold.

Mei:
How do you know?

Ho:
Because it hasn't fallen yet.

Mei:
That is not reassuring.

Ho:
Neither is gravity.
```

Flag:

```text
pulley_safe = true
```

---

## CH03_P05_ROUTE_ALIGNMENT

Physical arrangement:

1. Workshop hoist raises crate.
2. Player rotates to see neighboring balcony.
3. Plank bridges short gap after Mei places it.
4. Signboard blocks crate path.
5. Rotate to reveal sign hinges accessible from rear.
6. Interact to fold sign inward.
7. Crate transfers to loading platform.
8. Kit lowers it.
9. Workers carry it to street.

No magical alignment snapping.

Objects move because residents reposition them.

Camera rotation reveals where they must go.

---

## CH03_S02_FINAL_CRATE

The last crate reaches street level.

Chiu writes destination.

```text
Mei:
You're keeping the name?

Chiu:
Why wouldn't I?

Mei:
Different place.

Chiu:
Same fish balls.

Kit:
Better drains.

Chiu:
Traitor.

Kit:
I'm telling the truth.
```

Photo opportunity:

Workers around final worktable before cleanup.

Do not pose everyone.

One person should be looking away.

Scrapbook:

```text
CHIU'S WORKSHOP
Food workshop

Kit's uncle says the new place has proper drains.
Kit says this is the first sensible thing he has ever said.
```

---

## CH03_S03_KIT_KEY

Later, quiet elevated landing.

Kit shows new-flat key.

```text
Kit:
Lift goes all the way up.

Mei:
Sounds exhausting.

Kit:
You press a button.

Mei:
Exactly. What do you do while it's moving?

Kit:
Stand there.

Mei:
Awful.

Kit:
We get our own toilet.

Mei:
Fine. You win.
```

Beat.

```text
Kit:
You know you can come over.

Mei:
I know.

Kit:
You keep saying that like I'm moving to Canada.
```

Mei does not answer immediately.

```text
Mei:
What block?

Kit:
Seven.

Mei:
See? Already sounds far away.
```

Setup:

```text
setup_kit_address = true
setup_mei_fears_disconnection = true
```

End:

```text
18 DAYS UNTIL WE LEAVE
```

World-state changes:

- Chiu workshop begins dismantling
- one neighboring workshop closes completely
- hammering audio removed next chapter
- crate route remains physically altered

---

# 12. CHAPTER 4
# THREE ADDRESSES
## 12 DAYS UNTIL WE LEAVE

## Chapter purpose

Turn the story from preservation of the past toward continuity into the future.

Introduce the yamen as a major navigational and emotional landmark.

Introduce Mr. Cheng without villain framing.

---

## CH04_S00_YAMEN_ARRIVAL

The player reaches the central open space.

Design requirement:

After hours of tight interiors, this should feel physically strange.

Sound opens up.

Sunlight reaches ground.

NPCs:

- Mrs. Cheung
- two elderly residents
- Mr. Cheng
- movers
- ambient residents

Mrs. Cheung is guarding a small address book while movers label furniture.

```text
Cheung:
Mei.

Mei:
You need something?

Cheung:
Three things.

Mei:
That's suspiciously specific.

Cheung:
Lau. Chan. Your friend Kit.

Mei:
What about them?

Cheung:
Where they're going.

Mei:
You don't know?

Cheung:
That is why I am asking.
```

Objective:

```text
Find three new addresses.
```

---

## CH04_S01_CHENG_PLAN

Nearby, movers cannot remove a cabinet.

Cheng holds a plan.

```text
Cheng:
Room C-714.

Mei:
Where's that?

Cheng:
Seventh floor.

Mei:
Of which building?

Cheng:
Block C.

Mei:
There isn't a Block C.

Cheng:
There is on the plan.

Mei:
Can the plan show me where?

[Cheng looks at it]

Cheng:
No.
```

Secondary required quest merges into main progression.

Objective addendum:

```text
Help find a route for the cabinet.
```

---

# 13. CH04 Perspective Puzzle
# THE OFFICIAL ROUTE

## Concept

The official diagram says two spaces connect.

The lived building has changed around that logic.

The player discovers a valid path through spaces whose current relationships are only legible through perspective.

## Geometry

Cabinet starts:

```text
Yamen storage room
```

Target:

```text
courtyard loading area
```

Actual route:

```text
storage room
-> side passage
-> shared landing
-> former classroom
-> open balcony
-> rear stairs
-> courtyard
```

## Puzzle beats

### CH04_P01_FALSE_ADJACENCY

From default view, storage room and corridor appear adjacent.

Rotate.

A narrow service space lies between.

Player locates side opening.

### CH04_P02_DEAD_STAIR

Stair appears to terminate at a wall.

Rotate east.

Reveal continuation into neighboring structure.

### CH04_P03_BALCONY_CLEARANCE

Cabinet cannot turn through doorway in one orientation.

Player walks around.

From rear, folding panel is visible.

Interact.

Panel opens.

Movers continue.

### CH04_P04_EXIT

Cabinet emerges into courtyard.

Cheng:

```text
Cheng:
That isn't on the plan.

Mei:
No.

Cheng:
How do people know?

Mei:
You know once somebody shows you.
```

Flag:

```text
theme_line_somebody_shows_you = true
cheng_respect_mei = true
```

No music swell.

---

# 14. CH04 Address Quest

## CH04_A01_LAU

Lau clinic is nearly empty.

Chair gone.

Tools mostly boxed.

Sign remains.

Business card taped inside door.

Player can take it.

Text:

```text
LAU DENTAL
NEW ADDRESS
[fictional district address to be finalized]
```

If Lau is still present:

```text
Mei:
Mrs. Cheung wants your address.

Lau:
Already popular.

Mei:
She wants to know where everyone went.

Lau:
Tell her there are windows.
```

Inventory:

```text
address_lau
```

Payoff:

```text
payoff_lau_windows_partial = true
```

---

## CH04_A02_CHAN

Mrs. Chan and Wai dismantling rooftop drying frame.

Dialogue:

```text
Mei:
Mrs. Cheung wants your new address.

Chan:
Good. Tell her there are lifts.

Mei:
Everyone keeps telling me about lifts.

Chan:
You'll understand when you're old.

Wai:
You say that every time stairs are involved.
```

Inventory:

```text
address_chan
```

Environmental seed:

One empty clothesline section.

---

## CH04_A03_KIT

Kit writes address.

```text
Kit:
Don't lose it.

Mei:
I have a scrapbook.

Kit:
That's exactly why I'm worried.

Mei:
What is that supposed to mean?

Kit:
You put things somewhere safe and then spend twenty minutes looking for the safe place.
```

Inventory:

```text
address_kit
```

Optional:

```text
Mei:
How's the lift?

Kit:
Boring.

Mei:
Good.
```

---

## CH04_S02_RETURN_TO_CHEUNG

Mrs. Cheung copies all three addresses.

```text
Mei:
That's it?

Cheung:
That's three.

Mei:
What about everyone else?

Cheung:
I'll get them.
```

Cheung closes book.

Then:

```text
Cheung:
Knowing where someone lived is useful.

Mei:
Was useful.

Cheung:
Knowing where they went is better.
```

This is as close as Cheung should come to stating theme.

Unlock scrapbook section:

```text
AFTER
```

UI behavior:

Existing entries may now gain a forwarding field.

No percentage.

Example:

```text
MR. LAU

Then:
Third Floor, Lung Chun Road

After:
New clinic address received from his business card
```

End:

```text
12 DAYS UNTIL WE LEAVE
```

World-state transition:

- Kit family = MOVED
- Lau = MOVING
- Chan = MOVING
- one yamen room emptied
- more labels and moving activity
- some corridors visually clearer

---

# 15. CHAPTER 5
# ROOMS GOING QUIET
## 6 DAYS UNTIL WE LEAVE

## Chapter purpose

Make absence mechanically legible.

This is the emotional low point.

Do not make it melodramatic.

The City should simply sound wrong.

---

## CH05_S00_SILENCE

Start in apartment.

Do not immediately show text.

Ambient differences:

Removed:

- dental drill
- factory pounding
- one television
- one child loop
- Chan laundry conversation

Retained:

- pipe hum
- distant traffic
- intermittent footsteps
- pigeons farther away

Mum has a small open box of borrowed items.

```text
Mum:
These need to go back.

Mei:
Now?

Mum:
When were you planning to do it?

Mei:
What are they?

Mum:
Things that aren't ours.
```

Story items:

- folding stool
- screwdriver
- birdseed tin
- bowl
- single mahjong tile

Objective:

```text
Return what we borrowed.
```

---

# 16. CH05 Perspective Puzzle
# NEGATIVE SPACE

## Principle

Earlier puzzles are hard because the City contains too much.

This one is hard because familiar things are missing.

## Required world changes

- plank bridge removed
- one stall shuttered
- boxes removed from previously blocked hall
- signboard removed
- one workshop fully empty
- one previously hidden side door now obvious
- old route interrupted

## Puzzle sequence

### CH05_P01_OLD_ROUTE_FAILS

Player approaches a familiar crossing.

Bridge is gone.

No prompt beyond:

```text
The plank is gone.
```

### CH05_P02_EMPTY_WORKSHOP

Rotate.

A workshop that used to be visually sealed is now empty and its far opening is visible.

The player walks through what used to be somebody's workspace.

### CH05_P03_REAR_STAIR

Without the old sign, a narrow stair can be seen.

Player uses it to reconnect with familiar corridor.

This puzzle should be solvable quickly by a player who has learned the rotation language.

Its difficulty is emotional disorientation.

---

# 17. CH05 Return Items

The order is flexible.

## CH05_R01_SCREWDRIVER_TO_HO

Ho still present, packing tools.

```text
Mei:
Mum says this is yours.

Ho:
Was.

Mei:
You don't want it?

Ho:
Bought another one.

Mei:
Then why did we have it for three years?

Ho:
Your grandfather borrows permanently.
```

Ho takes it anyway.

---

## CH05_R02_BIRDSEED_TO_NG

Ng packing cages.

```text
Mei:
This yours?

Ng:
Probably.

Mei:
That's confidence.

Ng:
Birdseed is birdseed.
```

If Chapter 1 pigeon photo exists:

```text
Ng:
You still have that picture?

Mei:
Yeah.

Ng:
Good.
```

No further explanation.

---

## CH05_R03_STOOL

Owner already moved.

Door open.

Room empty except forwarding chalk mark.

Interaction:

```text
Nobody is here.
```

Mei leaves stool folded beside wall.

Flag:

```text
returned_stool_to_empty_room = true
```

This should be the first return that cannot be completed socially.

---

## CH05_R04_MAHJONG_TILE

Mahjong group reduced from four to two residents packing.

```text
Resident:
Where did you find that?

Mei:
Grandpa's drawer.

Resident:
Of course.
```

They laugh.

One puts it into a tin with the rest.

---

# 18. CH05 Lau's Empty Clinic

Required traversal passes near Lau.

Clinic state:

```text
EMPTY_WITH_CARD_MARK
```

Props removed:

- chair
- tray
- most boxes
- personal items

Remain:

- fluorescent light
- wall discoloration
- one wire
- pale rectangle where object hung

Interaction:

```text
A pale square marks where something used to hang.
```

If photographed:

Allow photo, but no yellow subject lock.

Scrapbook environment page:

```text
LAU'S OLD CLINIC

No caption initially.
```

Later Mei note:

```text
I walked past the stairs twice before I remembered he wasn't there.
```

---

# 19. CH05 Mrs. Chan's Walkway

State:

- no laundry
- empty clips
- basin removed
- frame partly dismantled

Scripted micro-event:

One peg falls due to wind.

No interaction.

No music cue.

Do not underline it.

---

# 20. CH05 Mrs. Wong's Room

Mei arrives with bowl.

Door open.

Mrs. Wong gone.

Her daughter collected her early.

Room state:

- chair removed
- bed stripped
- one small table
- envelope

Envelope label:

```text
FOR THE OLD FOOL
```

Text:

```text
You lose.

I left first.

It counts even if my daughter dragged me.

Don't argue.
```

Quest item:

```text
wong_note
```

The bowl is left on table.

---

## CH05_S02_GRANDFATHER_NOTE

Mei returns.

Hands note to Grandfather.

He reads.

Long pause.

```text
Grandfather:
Cheat.

Mei:
You said you didn't know what she meant.

Grandfather:
I didn't say that.

Mei:
You absolutely did.

Grandfather:
Memory is unreliable.
```

He folds the note.

Important animation:

He puts it in his pocket, not into a moving box.

Flag:

```text
payoff_wong_bet = true
grandfather_keeps_note = true
```

---

# 21. CH05 Optional Empty-Room Photograph

If player raises camera in Wong's room:

- no yellow viewfinder
- shutter still works
- no quest reward
- scrapbook adds page only if taken

Caption added later:

```text
MRS. WONG'S ROOM

She told me not to make a fuss when she left.
She wasn't even there to stop me.
```

If not photographed:

No blank collectible icon.

No penalty.

---

# 22. CH05 Mother and Daughter Argument

Trigger:

After note scene and at least three returned items.

Mei returns.

The red bowl is gone from visible shelf.

```text
Mei:
Where's the red bowl?

Mum:
Packed.

Mei:
I was using it.

Mum:
For what?

Mei:
It was there.

Mum:
It is still there. In a box.

Mei:
Every time I come back, something's gone.

Mum:
Mei.

Mei:
Can you stop for one day?

Mum:
We have six days.

Mei:
I know.

Mum:
Then what are you asking me to do?

Mei:
Stop making it disappear before it disappears.

Mum:
I'm putting bowls in newspaper.

Mei:
I know what you're doing.

Mum:
I don't think you do.
```

Pause.

Mum sits.

```text
Mum:
I lived here too.
```

End scene.

No hug.

No apology dialogue.

Control returns.

Flag:

```text
mei_mum_argument = true
mei_understands_mum_partial = true
```

---

## CH05 End state

```text
6 DAYS UNTIL WE LEAVE
```

World transitions:

- Wong = MOVED
- Chan = MOVED
- Wai = MOVED
- Lau = MOVED
- Chiu = MOVED
- Kwok = PRESENT_PACKING
- Ng = PRESENT_MOVING
- Ho = PRESENT_MOVING
- Cheung = MOVING
- ambient population reduced significantly

---

# 23. CHAPTER 6
# THE LAST ROOF
## 1 DAY UNTIL WE LEAVE

## Chapter purpose

Return warmth after Chapter 5.

Show that endings contain ordinary life.

Complete Mei's shift from recorder to participant.

---

## CH06_S00_EVENING

No formal party.

Remaining residents naturally gather.

Props:

- folding chairs not worth moving
- leftover food
- thermos
- bird cages
- tool boxes
- dismantled laundry frames

Residents present:

- Grandfather
- Mum
- Mei
- Kit, returned visit
- Mr. Ho
- Mr. Ng
- Mr. Kwok optionally
- a few ambient residents

Lighting:

Golden hour into evening.

---

## CH06_S01_LIGHTS_FAIL

Rooftop bulbs go out.

```text
Resident:
Ho!

Ho:
I took the line down.

Grandfather:
Put it back.

Ho:
We're leaving.

Grandfather:
We haven't left.

Ho:
Apparently electricity observes technicalities.
```

Ho looks at Mei.

```text
Ho:
You remember how to follow a wire?

Mei:
Unfortunately.
```

Objective:

```text
Reconnect the roof lights.
```

---

# 24. CH06 Perspective Puzzle
# THE LAST CIRCUIT

## Puzzle principle

A larger cousin of *Follow the Water*.

The player now understands the language, so complexity can increase without more tutorial text.

## Geometry

At least three roofs.

Visible elements:

- strings of bulbs
- extension lines
- water tanks
- cage frames
- roof huts
- antenna poles
- laundry remnants
- plug boards

## Electrical safety fiction rule

Mei does not repair live wiring.

She only routes and connects unplugged extension leads under Ho's direction.

## Puzzle sequence

### CH06_P01_LINE_A

From north view, line enters a rooftop hut.

Rotate east.

See it leave from rear opening.

### CH06_P02_FALSE_CROSSING

Two cables visually overlap.

From south view, player sees one passes overhead and the other descends.

Only one reaches correct plug board.

### CH06_P03_TANK_ROUTE

Cable disappears behind water tank.

Rotate twice while walking around it.

Reveal cable looped under pigeon-frame support.

### CH06_P04_FINAL_PLUG

Final plug powers lights over Chapter 1 Mr. Ng photo spot.

On connection:

Lights turn on sequentially across roofs.

No giant musical triumph.

Residents clap once or tease Ho.

```text
Ho:
Don't encourage her.
```

Flag:

```text
roof_lights_restored = true
```

---

# 25. CH06 Optional Rooftop Conversations

All should be available after lights.

No quest icons.

## Ng

```text
Mei:
Will they know the new roof?

Ng:
No.

Mei:
You said they know their way home.

Ng:
They know this one.

[Ng checks cage]

Ng:
We'll teach them another.
```

Payoff:

```text
payoff_ng_home_line = true
```

---

## Ho

```text
Ho:
New building has management.

Mei:
Good.

Ho:
Terrible.

Mei:
You won't have to fix everything.

Ho:
Exactly.
```

---

## Mum and Grandfather

```text
Mum:
The lift works.

Grandfather:
So I've heard.

Mum:
You'll like it.

Grandfather:
I don't like things because they're convenient.

Mum:
You like television.

Grandfather:
That's different.
```

---

## Kit

```text
Kit:
I got lost going home yesterday.

Mei:
Already?

Kit:
Everything looks the same.

Mei:
Good.

Kit:
You're enjoying this.

Mei:
A little.
```

Optional follow-up:

```text
Kit:
You still coming over?

Mei:
Yeah.

Kit:
That sounded almost convincing.

Mei:
I'll bring a map.

Kit:
Of my estate?

Mei:
For me.
```

---

## Kwok

If present:

```text
Kwok:
Newspaper delivery starts at seven.

Mei:
You already arranged it?

Kwok:
Of course.

Mei:
You don't even know the new neighbors.

Kwok:
They read, don't they?
```

This keeps future life concrete.

---

# 26. CH06 The Old Photograph

After at least two rooftop conversations.

Grandfather hands Mei the old photograph seeded in Chapter 1.

Photo content:

- young Grandfather
- young Mrs. Wong
- several residents
- one of Mei's parents as a child
- recognizable blue pipe in background
- one unknown photographer absent from image

Dialogue:

```text
Mei:
You had a camera?

Grandfather:
For a while.

Mei:
What happened to it?

[Mei looks at the camera around her neck]

Mei:
Oh.
```

She studies photograph.

```text
Mei:
Who took this?

Grandfather:
Someone who left.

Mei:
Who?

Grandfather:
I don't remember.
```

No score.

No music sting.

Flag:

```text
payoff_old_photo_camera = true
unknown_photographer_forgotten = true
```

Scrapbook receives scanned old photo on a separate family page.

Caption:

```text
Grandpa, Mrs. Wong, Mum, and people he says I should know.
He does not remember who took it.
```

---

# 27. CH06 The Moment Mei Does Not Photograph

Trigger late in evening.

Residents are laughing over something ordinary.

Suggested beat:

Grandfather nearly drops a cup because Kit passes food behind him.

Ho complains about the lights.

Ng's pigeon flaps.

Kit laughs.

The camera interaction icon appears subtly.

The player raises camera.

For the first time:

Mei lowers it herself before the viewfinder fully settles.

No dialogue.

Control resumes after a short pause.

Important:

Do not make this a choice prompt.

Mei's arc owns this decision.

Flag:

```text
mei_chose_presence = true
```

This is a required story beat.

---

# 28. CH06 Optional Quest
# MR. NG'S LAST PIGEON

During packing, one pigeon escapes.

It hides in the same class of occluded space as Chapter 1.

No tutorial.

No hint for first 20 seconds.

The player should recognize the solution.

Rotate.

Pigeon visible behind familiar tank geometry.

After return:

```text
Ng:
You're getting good at this.

Mei:
She's predictable.

Ng:
So are you.
```

Flag:

```text
optional_ng_last_pigeon = true
```

This is a mechanical callback.

---

## CH06 end

Residents begin leaving roof one by one.

Do not stage farewells for all of them.

Some simply say:

```text
See you.
```

Not:

```text
Goodbye forever.
```

Fade.

```text
1 DAY UNTIL WE LEAVE
```

---

# 29. CHAPTER 7
# THE WAY OUT
## 0 DAYS UNTIL WE LEAVE

## Chapter purpose

Prove spatial mastery.

Resolve Grandfather and Mei.

Pay off the perspective mechanic with an unsolvable final framing problem.

---

## CH07_S00_EMPTY_APARTMENT

Apartment nearly empty.

Acoustics changed.

Remaining:

- Grandfather's chair
- one suitcase
- one box
- camera
- old marks on walls

Gone:

- red bowl
- radio
- most furniture
- decorations

Mum enters from hall.

```text
Mum:
Have you seen Grandpa?

Mei:
No.

Mum:
He was supposed to be downstairs.

Mei:
I'll find him.

Mum:
Mei.

[Mei stops]

Mum:
Don't take all day.

Mei:
We only have one.
```

Objective:

```text
Find Grandfather.
```

No waypoint.

No directional hint.

---

# 30. CH07 Final Navigation
# THE CITY FROM MEMORY

## Rules

- no objective arrow
- no quest trail
- no minimap
- no hint for at least several minutes
- multiple valid paths
- changed world geometry
- familiar landmarks remain in reduced form

Possible routes:

### Route A

```text
blue pipe
-> Lau's empty clinic
-> open former workshop
-> light well
-> yamen
```

### Route B

```text
service corridor
-> airshaft
-> rooftop
-> Ng's former stair
-> central courtyard
```

### Route C

```text
lower alley
-> former factory loading path
-> balcony stairs
-> yamen
```

The yamen is the destination.

The player should infer Grandfather might go somewhere central and familiar.

Optional environmental prompts should come from memory, not UI.

Example interactable blue pipe:

```text
The paint has chipped more near the bend.
```

No "Go this way."

---

# 31. CH07_S01_GRANDFATHER_YAMEN

Grandfather sits in courtyard.

Not hiding.

Not refusing.

Just sitting.

Mei approaches.

```text
Mei:
Mum's looking for you.

Grandfather:
I know.

Mei:
The truck's here.

Grandfather:
I know.
```

Mei sits.

No input prompt for several seconds.

Ambient City only.

Then:

```text
Grandfather:
Ready?

Mei:
No.

Grandfather:
Good.

[Mei looks at him]

Grandfather:
Me neither.
```

Grandfather stands.

Objective:

```text
Go home.
```

But the actual next sequence leads outward.

---

# 32. CH07_S02_FINAL_WALK

Grandfather follows Mei.

Do not pathfind him ahead of her.

He should walk half a step behind.

At one junction he turns wrong.

```text
Mei:
Not that way.

Grandfather:
I know.

Mei:
You're going the wrong way.

Grandfather:
I was checking.

Mei:
Checking what?

Grandfather:
If you knew.
```

Flag:

```text
payoff_grandfather_navigation = true
```

This completes the first blue-pipe lesson.

---

# 33. CH07 Last Perspective Puzzle
# IT DOESN'T FIT

At exit boundary.

Mei turns back.

Control returns.

Prompt is not "Solve puzzle."

Mei raises camera automatically after player looks back.

The City exceeds the viewfinder.

Player may rotate through four orientations.

Each direction reveals a different familiar set:

- roof tanks
- blue pipe block
- yamen roof
- sign corridor
- distant laundry frames
- surrounding roofs

No direction fits all of it.

After player rotates at least three distinct directions, or after a reasonable timeout:

```text
Mei:
It doesn't fit.

Grandfather:
What doesn't?

Mei:
All of it.

[Grandfather looks]

Grandfather:
Of course not.
```

Mei lowers camera.

Puzzle family:

**Anti-puzzle**

The game has taught that perspective reveals the missing answer.

Here there is no complete angle.

Completion condition:

Not spatial success.

Acceptance that no single framing contains the whole place.

Flag:

```text
payoff_perspective_theme = true
```

---

# 34. CH07 Final Photograph

Grandfather:

```text
Give me that.

Mei:
Why?

Grandfather:
Give it.
```

She hands him camera.

He gestures.

```text
Grandfather:
Stand there.

Mei:
Why?

Grandfather:
You've got everyone else.
```

Mei stands.

No pose menu.

No composition score.

Grandfather raises camera.

Flash.

White screen holds longer than previous photos.

Polaroid develops.

Scrapbook entry:

```text
MEI
```

No occupation.

No location.

Different handwriting:

```text
Knew every way home.
```

Flag:

```text
final_photo_mei = true
```

---

# 35. Ending

Black.

Text:

```text
WE LEFT.
```

Long pause.

Credits.

During credits:

Show only photographs actually taken during the playthrough.

Rules:

- no completion percentage
- no missing-slot silhouettes
- no "best ending"
- no score
- no collectible tally

If the player photographed Wong's empty room, it may appear.

If not, it does not.

The scrapbook is their version of the thirty days.

---

# 36. OPTIONAL QUEST CATALOG

# OQ01 MR. KWOK'S BACK PAGE

## Availability

Chapters 2 or 3.

## Setup

Wind blows newspaper page into light well.

Kwok:

```text
Kwok:
Get that.

Mei:
Yesterday's paper?

Kwok:
Still mine.
```

## Puzzle

From upper floor, page appears to rest on inaccessible awning.

Rotate.

Reveal it actually sits on lower balcony behind awning.

Access balcony through neighboring stair.

Puzzle family:

**Occlusion plus access**

## Return

```text
Kwok:
You went all that way for yesterday's paper?

Mei:
You asked me to.

Kwok:
I was testing you.

Mei:
For what?

Kwok:
Poor judgment.
```

## Late payoff

After Kwok leaves, one newspaper remains under shutter.

---

# OQ02 MRS. CHEUNG'S FAN

## Availability

Chapter 4 before address completion.

Fan stops.

Ho says motor is fine.

Cable runs through shared rooms.

## Puzzle

Trace extension cable.

Two cords overlap from default view.

Rotate to identify correct line.

Plug hidden behind stacked furniture visible from opposite side.

## Outcome

Fan resumes.

In Chapter 5, Cheung's room is empty and fan is off.

No special dialogue.

---

# OQ03 AUNTIE FONG'S SIGN

## Availability

Chapter 3 or 4.

Shop owner wants sign removed before move.

## Puzzle

Bolts accessible from two different balconies.

One balcony appears continuous from front.

Rotate.

Reveal narrow shaft separating them.

Player must find second access route.

## Outcome

Sign removed.

Later, blank wall becomes an intentionally weakened landmark.

---

# OQ04 THE LAST MAHJONG TILE

## Availability

Chapter 2 or 3.

Tile falls through wall gap.

Everyone accuses everyone.

## Puzzle

From room, tile appears unreachable.

Rotate from lower service corridor.

Reveal opening beneath gap.

Retrieve tile.

## Tone

Quest is deliberately elaborate for one tile.

## Late payoff

Table folded against wall in Chapter 5.

---

# OQ05 WAI'S SHORTCUT

## Availability

Chapter 3.

Wai claims a faster roof route.

No timer.

Goal is simply to discover route.

## Puzzle

Chain three perspective reveals:

1. hidden stair
2. rear balcony
3. roof bridge

## Payoff

In Chapter 5, bridge has been removed.

Gap remains.

No dialogue because Wai has moved.

---

# OQ06 THE LOST ADDRESS

## Availability

Chapter 4.

Resident needs sibling's block number.

Neighbor who knew has moved.

Kwok kept forwarding note.

His stall is shuttered.

## Puzzle

The stall never fades from the back.

Player must remember it can only be seen properly from open-front angle.

Rotate to sight note through front opening.

Retrieve note from accessible slot.

## Purpose

Turn a visual presentation rule into remembered gameplay knowledge.

---

# OQ07 NG'S LAST PIGEON

Defined in Chapter 6.

Purpose:

Mechanical callback to Chapter 1.

---

# 37. Puzzle Design Bible

## 37.1 Non-magical rule

Perspective rotation does not:

- create geometry
- teleport objects
- phase Mei through walls
- align disconnected objects through optical illusion as a supernatural mechanic
- cause impossible gravity changes

It changes what the player can perceive.

## 37.2 Puzzle families

### Occlusion

An object or route exists but is hidden.

Example: crate behind fridge.

### Connection

Two parts look unrelated until another angle reveals the connection.

Example: water pipe.

### Access

Destination is visible but entrance is hidden on another side.

Example: abandoned unit.

### Vertical

Connections between floors become legible only from certain views.

Example: factory loading route.

### Landmark

Player recognizes a known place from an unfamiliar orientation.

Example: Kwok stall.

### Change

Old spatial assumptions fail because the environment changed.

Example: negative-space chapter.

### Photography

The camera must frame a relationship or moment, not simply a portrait.

Example: Ng plus Kai Tak aircraft.

### Mastery

No explicit puzzle UI.

The player navigates through accumulated knowledge.

Example: final Grandfather search.

### Anti-puzzle

The player tries to solve framing through perspective, but no complete perspective exists.

Use exactly once.

Example: final City photograph.

---

# 38. World State Matrix

Legend:

```text
N = normal
P = packing
M = moving
E = empty
R = returned visit
```

| Character/location | Ch1 | Ch2 | Ch3 | Ch4 | Ch5 | Ch6 | Ch7 |
|---|---|---|---|---|---|---|---|
| Mei flat | N | P | P | P | P | P | E |
| Grandfather | N | N | N | N | N | N | yamen then exit |
| Mum | offscreen/light | N | N | N | N | N | moving truck |
| Lau | N | N | N | M | E | gone | gone |
| Chan | N | N | P | M | E | gone | gone |
| Wai | N | N | N | M | gone | optional visit only if desired | gone |
| Ng | N | N | N | N | M | M | gone |
| Ho | N | N | N | N | M | M | gone |
| Wong | N | N | N | N | E | gone | gone |
| Kwok | N | N | N | N | P | optional present | E |
| Kit | mention | N | N | moved/visit | moved | R | gone |
| Chiu workshop | absent | setup | N | P | E | E | E |
| Cheung | absent | mention | absent | N | M/E | gone | gone |
| yamen centre | ambient | ambient | ambient | active | sparse | sparse | near-empty |

---

# 39. Sound State Matrix

Sound should carry absence before dialogue does.

## Chapter 1

Dense baseline:

- radio
- TV
- dental drill/hum
- mahjong
- chopping
- water
- pigeons
- roof children
- traffic
- aircraft

## Chapter 2

Add:

- faulty pump
- pipe knocks
- restored water chorus

## Chapter 3

Add:

- workshop pounding
- bowls
- steam
- crate movement

## Chapter 4

Reduce:

- some residential loops

Add:

- movers
- courtyard openness
- paper and labels

## Chapter 5

Remove prominently:

- dental drill
- workshop pounding
- one TV
- Chan household loop
- several footsteps

The player should feel silence before identifying it.

## Chapter 6

Roof gathering temporarily restores social density.

## Chapter 7

Most interior loops removed.

Footsteps echo.

Outside traffic remains.

The world did not end.

Mei's relationship to it changed.

---

# 40. Scrapbook Implementation

## 40.1 Entry states

Suggested:

```text
LOCKED_NOT_SHOWN
KNOWN_NO_PHOTO
PHOTO_TAKEN
UPDATED
AFTER_INFO_ADDED
ENVIRONMENT_ONLY
```

Do not render locked empty slots to the player.

## 40.2 Early entry example

```text
MR. LAU
Dentist
Third Floor

His new clinic will have windows.
```

## 40.3 Mid-game update

```text
AFTER
New clinic address
```

## 40.4 Late update

```text
I walked past the old stairs twice before I remembered he wasn't there.
```

## 40.5 Ng

Initial:

```text
Mr. Ng says they know the way home better than people do.
```

Late:

```text
He says the pigeons know this roof.
They will have to learn another.
```

## 40.6 Ho

```text
He says nobody built the water system. Everybody did.
```

Late:

```text
The pipes were still there after the water stopped.
```

## 40.7 Kit

Photo not required.

Entry can exist through handwritten note:

```text
KIT

Block 7.
Lift.
Own toilet.
Apparently these are all reasons to abandon me.
```

Later:

```text
She got lost in the new estate before I did.
```

## 40.8 Mrs. Wong

If portrait never taken:

Do not force one.

Her entry can be note-based.

Late:

```text
She left first.
Grandpa says it was cheating.
```

## 40.9 Final Mei entry

Only created at ending.

```text
MEI

Knew every way home.
```

Handwriting is Grandfather's.

---

# 41. Setup and Payoff Ledger

| Setup flag | Setup | Payoff |
|---|---|---|
| `setup_old_photo_seen` | old photo in Ch1 | camera belonged to Grandfather in Ch6 |
| `setup_lau_windows` | Lau wants windows | new clinic card, later confirmation |
| `setup_ng_home_line` | pigeons know home | "They know this one" |
| `setup_wong_bet` | Wong refuses to leave first | note: "You lose" |
| `setup_red_bowl` | ordinary bowl in flat | argument when packed |
| `setup_kit_address` | Kit's move | address quest and return visit |
| `setup_blue_pipe` | navigation landmark | final route no longer depends on it |
| `setup_boxes` | easy-to-ignore packing | flat consumed by boxes |
| `setup_mei_photographs` | player repeatedly photographs | Mei lowers camera in Ch6 |
| `setup_mei_not_subject` | no photos of Mei | Grandfather takes final photo |
| `theme_rotation` | rotation reveals truth | final angle cannot reveal all |

---

# 42. Dialogue Rules

## 42.1 No theme speeches

Never write:

```text
This city will live forever in our memories.
```

Instead write practical conversation around loss.

## 42.2 Ordinary nouns are emotional

Use:

- bowl
- stool
- address
- key
- rope
- cage
- business card
- newspaper
- lift
- toilet
- window

These objects make the relocation concrete.

## 42.3 Residents should disagree

Do not harmonize everyone's attitude.

## 42.4 Use humor late

The game needs jokes most when the environment gets emptier.

Humor prevents sentimentality from becoming oppressive.

## 42.5 Mei does not narrate herself

No internal monologue unless the scrapbook requires a short handwritten note.

---

# 43. Main Quest State Suggestions

These are descriptive IDs, not mandatory enum names.

## Chapter 2

```text
CH02_START
CH02_FIND_HO
CH02_TRACE_PIPE_A
CH02_TRACE_LIGHTWELL
CH02_ENTER_ABANDONED_UNIT
CH02_OPEN_CORRECT_VALVE
CH02_WATER_RESTORED
CH02_HO_PHOTO_AVAILABLE
CH02_RETURN_HOME
CH02_COMPLETE
```

## Chapter 3

```text
CH03_START
CH03_REACH_WORKSHOP
CH03_FIND_LOADING_ROUTE
CH03_GET_ROPE
CH03_GET_PLANK
CH03_CHECK_PULLEY
CH03_BUILD_ROUTE
CH03_MOVE_FINAL_CRATE
CH03_KIT_SCENE
CH03_COMPLETE
```

## Chapter 4

```text
CH04_START
CH04_MEET_CHEUNG
CH04_MEET_CHENG
CH04_MOVE_CABINET
CH04_GET_LAU_ADDRESS
CH04_GET_CHAN_ADDRESS
CH04_GET_KIT_ADDRESS
CH04_RETURN_ADDRESSES
CH04_UNLOCK_AFTER
CH04_COMPLETE
```

## Chapter 5

```text
CH05_START
CH05_RETURN_ITEMS
CH05_DISCOVER_NEGATIVE_ROUTE
CH05_FIND_WONG_NOTE
CH05_GIVE_NOTE
CH05_MUM_ARGUMENT
CH05_COMPLETE
```

## Chapter 6

```text
CH06_START
CH06_LIGHTS_FAIL
CH06_TRACE_CIRCUIT
CH06_LIGHTS_RESTORED
CH06_ROOF_CONVERSATIONS
CH06_OLD_PHOTO
CH06_MEI_LOWERS_CAMERA
CH06_COMPLETE
```

## Chapter 7

```text
CH07_START
CH07_FIND_GRANDFATHER
CH07_YAMEN_SCENE
CH07_FINAL_WALK
CH07_CAMERA_ANTI_PUZZLE
CH07_FINAL_PHOTO
CH07_END
```

---

# 44. NPC Placement by Chapter

## Chapter 2

**Grandfather:** flat  
**Mum:** flat/kitchen packing  
**Ho:** repair stall, later valve area edge  
**Chan:** home/wash area  
**Wai:** moving between stairs and roof  
**Ng:** roof  
**Kwok:** stall  
**Lau:** clinic  
**Wong:** room  
**Kit:** optional ambient introduction near lower alley

## Chapter 3

**Kit:** workshop route throughout  
**Chiu:** workshop  
**Ho:** pulley checkpoint  
**Chan/Wai:** plank scene  
**Ng:** rope scene  
**Kwok:** stall  
**Grandfather/Mum:** flat secondary dialogue

## Chapter 4

**Cheung:** yamen  
**Cheng:** yamen/cabinet route  
**Lau:** clinic or absent briefly depending on order  
**Chan/Wai:** roof dismantling drying frame  
**Kit:** new-flat visit point or returning to old neighborhood for keys  
**Kwok:** stall  
**Ng/Ho:** ambient

## Chapter 5

**Mum:** flat  
**Grandfather:** flat  
**Ho:** packing stall  
**Ng:** cages  
**Wong:** gone  
**Lau:** gone  
**Chan/Wai:** gone  
**Kit:** gone  
**Kwok:** packing  
**Cheung:** moving or gone

## Chapter 6

Concentrate cast on roof to reduce implementation spread and maximize emotional density.

## Chapter 7

Almost everyone absent.

This is intentional.

---

# 45. Environmental Payoff Checklist

A resident may not transition to `MOVED` until at least one environment change exists.

## Lau

- chair gone
- tray gone
- drill audio off
- business card
- pale wall square

## Chan

- laundry gone
- pegs remain
- basin gone
- one peg falls

## Wai

- roof shortcut bridge removed later

## Wong

- chair gone
- daughter cleared most items
- note remains

## Ng

- cages removed after Ch6
- feathers remain
- roof feels wider

## Ho

- tool hooks empty
- cable partially removed

## Kwok

- shutter down
- newspaper scrap remains
- landmark weakened

## Chiu

- pounding gone
- floor dry
- empty hooks and work marks
- loading route remains

---

# 46. Camera and Photography Narrative Rules

## 46.1 Photo availability

Three classes:

```text
REQUIRED_STORY_PHOTO
OPTIONAL_SUBJECT_PHOTO
UNASSISTED_FREE_PHOTO
```

### Required

Use sparingly.

Examples:

- Lau in Chapter 1
- Ng aircraft photo in Chapter 1
- final Mei photo, not player-controlled

### Optional subject

Viewfinder turns yellow.

### Unassisted free photo

No yellow lock.

Examples:

- Wong's empty room
- Lau's empty clinic

These are about player interpretation.

## 46.2 No composition score

Never display:

- stars
- centering grade
- rarity
- monetary value
- "perfect shot"

## 46.3 Final inversion

For the entire game:

Mei operates camera.

At ending:

Grandfather operates camera.

This inversion is mandatory.

---

# 47. Perspective Difficulty Curve

## Chapter 1

Single reveal.

One hidden object at a time.

## Chapter 2

Trace one continuous system across several spaces.

## Chapter 3

Understand spatial route plus social dependencies.

## Chapter 4

Reconcile abstract plan with lived architecture.

## Chapter 5

Relearn changed familiar space.

## Chapter 6

Trace multiple crossing systems with minimal hints.

## Chapter 7

Navigate without a presented puzzle.

Then encounter one intentionally unsolvable framing problem.

---

# 48. Hint Philosophy

Hints should come from:

1. environmental sound
2. resident language
3. repeated landmark grammar
4. Mei's practical observation

Avoid floating arrows.

Example escalating hint for water puzzle:

### First

Ho:

```text
Blue branch. Follow it until it stops being blue.
```

### After delay

Pump knock emphasizes correct branch.

### After further delay

Mei:

```text
The knocking's on this side.
```

### Last resort

Ho calls from adjacent area:

```text
It crosses the light well.
```

No highlight trail.

---

# 49. Save and Chapter Resume Narrative Requirements

On chapter load:

World state must represent all previous departures and object changes.

Never reload a chapter with:

- returned laundry
- restored closed business
- resident back in old location unless `RETURNED_VISIT`
- old audio loop after source has moved
- removed bridge magically restored

A chapter resume test should validate critical continuity flags.

---

# 50. Integration Test Story Gates

## Chapter 2 test

Pass if:

- player can trace correct pipe
- wrong valves recover safely
- water audio state changes
- Ho final dialogue fires once
- scrapbook photo optionality works

## Chapter 3 test

Pass if:

- route cannot complete without rope, plank, pulley check
- camera rotations reveal intended depth relationships
- final crate moves continuously through route
- Kit scene unlocks after final crate

## Chapter 4 test

Pass if:

- cabinet path requires perspective understanding
- three addresses can be collected in any order
- `AFTER` section unlocks only after return to Cheung
- moved resident state persists

## Chapter 5 test

Pass if:

- old route is unavailable
- empty workshop route is available
- Wong note cannot be obtained before room state changes
- Mum argument only fires after required prerequisites
- optional empty-room photo never blocks progression

## Chapter 6 test

Pass if:

- line crossing cannot be solved from default view alone
- all required roof-light sections update
- old photo scene triggers
- camera-lowering story beat cannot be skipped
- optional pigeon quest remains optional

## Chapter 7 test

Pass if:

- at least two valid routes to yamen exist
- no waypoint appears
- Grandfather scene always reachable
- final camera sequence requires multiple perspective attempts
- ending creates Mei scrapbook entry
- credits reflect actual taken photos only

---

# 51. Pacing Targets

These are diagnostic, not hard caps.

| Chapter | Target |
|---|---:|
| The Blue Pipe | 15-20 min |
| The Water Line | 35-45 min |
| Last Batch | 45-55 min |
| Three Addresses | 45-60 min |
| Rooms Going Quiet | 45-60 min |
| The Last Roof | 35-50 min |
| The Way Out | 25-40 min |
| Optional quests and wandering | 60-120 min total |

Expected full-game range:

**Approximately 5 to 7 hours**

Do not pad to hit length.

---

# 52. Emotional Rhythm

Do not make each chapter sadder than the last.

## Chapter 1

Curiosity.

## Chapter 2

Busy, funny, communal.

## Chapter 3

Energetic and warm.

## Chapter 4

Reflective and forward-looking.

## Chapter 5

Quiet low point.

## Chapter 6

Warmest communal chapter.

## Chapter 7

Sparse, calm, final.

---

# 53. Things the Story Must Not Do

Do not:

- invent a villain responsible for clearance
- let Mei save the City
- create a "true ending" where relocation is prevented
- reduce residents to tragic victims
- make all residents oppose leaving
- make all officials cruel
- make photography a score chase
- turn historical suffering into horror spectacle
- make perspective rotation supernatural
- add a late twist that Grandfather is secretly dying just to increase sadness
- kill a major resident for emotional leverage
- show demolition as the emotional climax
- over-explain the final theme
- use a present-day epilogue unless the entire ending structure is reconsidered

---

# 54. Narrative Acceptance Test

The finished story succeeds if players can answer all of these without a lore screen:

1. Why did Grandfather give Mei the camera?
2. Why does Mum want to leave even though Kowloon is her home too?
3. What makes Kit excited?
4. What changes for Lau after he moves?
5. Why does Mrs. Cheung care about addresses?
6. Why is Wong's note funny to Grandfather?
7. What did Mei learn from Ng's pigeons?
8. Why does Mei lower the camera on the last roof?
9. Why does Grandfather photograph Mei?
10. Why can the final City photograph not be "solved"?

More importantly, players should be able to navigate at least one late-game route from memory.

Narrative and spatial mastery are the same arc.

---

# 55. Final Scene Summary

The complete game begins with:

```text
Follow the blue pipe.
```

It ends with Mei no longer needing directions.

The complete game begins with Grandfather warning:

```text
You'll forget what things looked like.
```

It ends with proof that no photograph could have contained everything anyway.

The camera preserves pieces.

The scrapbook preserves names.

Addresses preserve connections.

The player's own spatial memory preserves the shape of the City.

Grandfather preserves Mei.

That is the final narrative structure.
