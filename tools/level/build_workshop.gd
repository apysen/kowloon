class_name BuildWorkshop
extends RefCounted

## Uncle Chiu's fish-ball workshop, one floor up over the hall and the mahjong
## alcove, and the old way its crates went down to the lane.
##
## A second stair climbs from the hall to a small landing and the workshop's
## door. Inside: two steel worktables, tubs of paste, bowls, a steamer, a wall
## fan, the stacked crates, and in the ceiling a hatch with a hoist beam over it
## and a ladder up. Crates used to go up: onto the workshop's flat roof, across
## the slot between the buildings on a plank, along the neighbours' balcony
## (past their big signboard, hinged to the wall) to a loading platform that
## hangs from a pulley on a gallows arm, and down the slot to the lane at the
## bottom, which runs out to the street. The slot is open to the sky.
##
## Permanent: it is there every day. Only Chapter 3 opens the workshop's door.

const A := LevelBuilder.LEVEL_A
const B := LevelBuilder.LEVEL_B
const WS := [-7.0, 0.0, 0.0, 4.0]          # the workshop, on Level B
const WS_H := 4.0
const ROOF_Y := B + WS_H + 0.25              # the top of its lid, walked on
const SLOT_Z := [4.0, 6.0]                   # the slot between the buildings
const BALCONY := [-7.0, 0.0, 6.0, 7.0]       # the neighbours' balcony, across it
const PLANK_X := [-3.1, -2.2]                # where the plank goes across
const SIGN_X := -4.2                         # the signboard, across the balcony
const PLATFORM := Vector3(-6.4, ROOF_Y, 5.0)  # the loading platform, over the slot
const PLATFORM_PARKED := Vector3(-6.4, ROOF_Y, 3.35) # resting safely on the workshop roof
const LANE := [-5.7, 2.0, 4.3, 6.0]          # the lane at the bottom of the slot
const P := "Structure/Workshop"
const PW := "Furniture/Workshop"


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	_stairs(b)
	_workshop(b)
	_roof(b)
	_lane(b)
	_balcony(b)
	_chapter_bits(b)


## What is only there some days: the door shut before the last batch; the
## people of Chapter 3.
static func _chapter_bits(b: LevelBuilder) -> void:
	# Chapters 1-2: the workshop's door is shut (no reason to go in)
	BuildInteriors.panel_door_z(b, 1.6, 2.8, B, 2.3, 0.02, c8(0x6f7a6a), "ChapterProps/Ch1-2", 1.0, "WorkshopDoor")
	b.add_obstacle(-0.1, 0.35, 1.6, 2.8, B, "workshopShut", "chapter:Ch1-2")
	# Chapter 3's people
	var C3 := "ChapterProps/Ch3"
	# Kit: here for the last batch, and back in Chapter 4 for the workshop's keys
	b.resident("kit", "kit", Vector3(1.6, A, 0.2), {"facing": Vector3(-1, 0, 0), "parent": "ChapterProps/Ch3-4"})
	b.resident("chiu", "chiu", Vector3(-4.6, B, 1.95), {"anim": "work", "facing": Vector3(0, 0, -1), "parent": C3})
	b.resident("hand_a", "ws_hand_a", Vector3(-5.5, B, 1.95), {"anim": "work", "facing": Vector3(0, 0, 1), "parent": C3})
	b.resident("hand_b", "ws_hand_b", Vector3(-4.0, B, 3.45), {"anim": "work", "facing": Vector3(-1, 0, -0.3), "parent": C3})
	b.resident("porter", "ext_labourer", Vector3(-4.2, A, 5.1), {"facing": Vector3(-1, 0, 0), "parent": C3})


# ----------------------------------------------------------------------------- the second stair


static func _stairs(b: LevelBuilder) -> void:
	# at the foot, off the hall's south side
	b.room({"x0": 0, "x1": 2, "z0": 1, "z1": 4, "y": A, "name": "StairsC", "wall": c8(0x6d6a60), "floor": c8(0x4a463e),
		"skip": ["n", "w"], "parent": "Structure/LevelA", "wall_surface": "concrete"})
	var SP := P + "/StairsC"
	for i in 9:
		var top := A + 0.45 * (i + 1)
		var sz := 1.7 + i * 0.26
		b.box(0.15, 1.85, top - 0.45, top, sz, minf(sz + 0.28, 4.0), c8(0x5d5a52), {"surface": "concrete", "parent": SP, "name": "Step", "band": 0.0})
		# Lift the stripe just above the concrete; coplanar faces depth-fight and
		# made apparently random nosings disappear from the stairwell view.
		b.box(0.15, 1.85, top - 0.03, top + 0.003, sz, sz + 0.05, c8(0xd8b23a), {"surface": "metal", "parent": SP, "name": "Nosing", "cast_shadow": false, "band": 0.0})
	b.add_obstacle(0.1, 1.9, 1.7, 4.0, A, "stairsC")
	b.cylinder(Vector3(1.9, A + 1.0, 1.6), Vector3(1.9, A + 4.2, 3.9), 0.025, b.surface("metal"), {"parent": SP, "name": "Handrail", "tint": c8(0x6a5a48), "band": 0.0})
	b.card("res://assets/textures/props/sign_stairs_down.png", Vector3(1.97, A + 1.6, 1.4), Vector2(0.45, 0.6), Vector3(-1, 0, 0), {"parent": SP, "name": "StairSign", "band": 0.0})
	PropKit.bulb(b, Vector3(1.0, A + 3.4, 1.5), A + 4.2, SP)
	b.ref("stairsCUp", Vector3(1.0, A, 1.4))
	# at the top: a small landing and the workshop's door
	b.room({"x0": 0, "x1": 2, "z0": 1, "z1": 4, "y": B, "name": "LandingC", "wall": c8(0x7a7466), "floor": c8(0x4e4a42),
		"open": {"w": [[1.6, 2.8]]}, "parent": "Structure/LevelB", "wall_surface": "concrete", "floor_hole": [0.15, 1.85, 3.0, 4.0]})
	var LP := P + "/LandingC"
	# the head of the flight, open on the landing's side: steps start at the hole's
	# edge (z 3) and drop away south, over the flight that climbs up beneath them
	# (no deeper than 0.75: the stair room's ceiling below is at 4.2)
	for i in 4:
		var top := B - 0.17 * (i + 1)
		var z0 := 3.0 + 0.25 * i
		b.box(0.15, 1.85, B - 0.75, top, z0, z0 + 0.25, c8(0x5d5a52), {"surface": "concrete", "parent": LP, "name": "Step", "band": 1.0})
		b.box(0.15, 1.85, top - 0.03, top + 0.002, z0, z0 + 0.05, c8(0xd8b23a), {"surface": "metal", "parent": LP, "name": "Nosing", "cast_shadow": false, "band": 1.0})
	b.box(0.15, 1.85, B - 0.04, B + 0.01, 2.97, 3.03, c8(0xd8b23a), {"surface": "metal", "parent": LP, "name": "Lip", "cast_shadow": false, "band": 1.0})
	b.cylinder(Vector3(1.93, B + 0.9, 2.9), Vector3(1.93, B + 0.9 - 0.68, 3.95), 0.022, b.surface("metal"), {"parent": LP, "name": "Handrail", "tint": c8(0x6a5a48), "band": 1.0})
	b.box(0.15, 1.85, B - 2.0, B - 1.8, 3.0, 4.0, c8(0x2a2826), {"surface": "concrete", "parent": LP, "name": "Below", "band": 1.0})
	b.add_obstacle(0.15, 1.85, 3.0, 4.0, B, "stairsCHole")
	PropKit.bulb(b, Vector3(1.0, B + 3.2, 1.8), B + 4.2, LP)
	b.card("res://assets/textures/props/sign_chiu.png", Vector3(0.03, B + 3.0, 2.2), Vector2(0.9, 0.3), Vector3(1, 0, 0), {"parent": LP, "name": "ChiuSign", "band": 1.0})
	b.ref("stairsCDown", Vector3(1.0, B, 2.5))
	b.ref("landingC", Vector3(1.0, B, 1.8))


# ----------------------------------------------------------------------------- the workshop


static func _workshop(b: LevelBuilder) -> void:
	b.room({"x0": WS[0], "x1": WS[1], "z0": WS[2], "z1": WS[3], "y": B, "h": WS_H, "name": "Workshop", "id": "workshop",
		"wall": c8(0xb8b8a8), "floor": c8(0x6a7a78), "floor_surface": "tiles", "wall_surface": "tiles",
		"open": {"e": [[1.6, 2.8]]}, "parent": "Structure/LevelB"})
	# the door off the landing, stood open when there's work on
	b.ref("workshopDoor", Vector3(-0.5, B, 2.2))
	# (the work itself is gone after Chapter 3: tables, tubs, steamer, crates, fan)
	var PW3 := "ChapterProps/Ch1-3/Workshop"
	# two long steel worktables, and what's on them
	for tz in [0.7, 2.4]:
		PropKit.table(b, -6.3, -3.5, tz, tz + 0.8, B, 0.85, c8(0xa8aeb0), PW3, "metal")
		b.add_obstacle(-6.3, -3.5, tz, tz + 0.8, B, "worktable", "chapter:Ch1-3")
		for k in 5:
			var bx := -6.0 + k * 0.52
			ObjectKit.rice_bowl(b, Vector3(bx, B + 0.85, tz + 0.4), 0.14, [c8(0xe8e4d8), c8(0x5a7aa8)][k % 2], PW3, "Bowl")
			# fish balls, rolled and waiting
			for m in 3:
				b.piece(PropKit._sphere(0.028), Vector3(bx - 0.05 + m * 0.05, B + 0.9, tz + 0.4 + (m % 2) * 0.04), b.surface("glaze"), {"parent": PW3, "name": "FishBall", "tint": c8(0xf0ebe0), "cast_shadow": false})
	# tubs of paste on the floor, and a stack of empty tubs
	for tb in [[-6.7, 1.9], [-5.9, 1.9]]:
		ObjectKit.tub(b, Vector3(tb[0], B, tb[1]), 0.32, 0.55, c8(0x3f6fa8), c8(0xe0d8c4), 0.9, PW3)
		b.add_obstacle(tb[0] - 0.32, tb[0] + 0.32, tb[1] - 0.32, tb[1] + 0.32, B, "tub", "chapter:Ch1-3")
	# the steamer on its burner, in the corner
	b.box(-6.95, -6.25, B, B + 0.7, 3.2, 3.95, c8(0x8e8a80), {"surface": "concrete", "parent": PW3, "name": "BurnerStand"})
	b.add_obstacle(-6.95, -6.25, 3.2, 3.95, B, "burner", "chapter:Ch1-3")
	# the burner ring under it, then a wok of water, then the bamboo baskets
	ModelKit.place(b, ModelKit.tube(PropKit._circle(0.2, 24), 0.02, 0.0, 8, false), Vector3(-6.6, B + 0.72, 3.57), "metal", c8(0x2a2a2a), {"parent": PW3, "name": "Burner"})
	ModelKit.place(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.15, 0.01), Vector2(0.3, 0.07), Vector2(0.33, 0.1), Vector2(0.32, 0.1), Vector2(0.29, 0.075), Vector2(0.15, 0.02), Vector2(0, 0.012)]), 28),
		Vector3(-6.6, B + 0.7, 3.57), "metal", c8(0x2e2c2a), {"parent": PW3, "name": "SteamerWok"})
	ObjectKit.steamer(b, Vector3(-6.6, B + 0.78, 3.57), 0.28, 3, PW3)
	b.ref("steamer", Vector3(-6.6, B + 1.25, 3.57))
	# the crates for the last shipment, stacked by the door
	for i in 12:
		var cx := -1.35 + (i % 3) * 0.45
		var cz := 2.95 + ((i / 3) % 2) * 0.5
		var cy := B + (i / 6) * 0.34
		_crate(b, Vector3(cx, cy, cz), [c8(0x3f6fa8), c8(0xc9463a)][i % 2], PW3, "Crate")
	b.add_obstacle(-1.6, -0.05, 2.7, 3.95, B, "crateStack", "chapter:Ch1-3")
	# the wall fan, turned on the tables
	PropKit.fan(b, -3.1, 3.6, B, PW3, Vector3(-1, 0, -0.5))
	# the ladder up the north wall, to the hatch
	var lx := -1.8
	for rx in [lx - 0.22, lx + 0.18]:
		b.box(rx, rx + 0.05, B, B + WS_H, 0.04, 0.12, c8(0x5a5a58), {"surface": "metal", "parent": PW, "name": "LadderRail"})
	for k in 11:
		var ry := B + 0.3 + k * 0.35
		b.box(lx - 0.2, lx + 0.2, ry, ry + 0.03, 0.06, 0.1, c8(0x6a6a68), {"surface": "metal", "parent": PW, "name": "LadderRung", "cast_shadow": false})
	# the hatch, from below: a square of dark in the ceiling, and the hoist beam over the crate path
	b.box(-2.4, -1.2, B + WS_H - 0.02, B + WS_H, 0.15, 1.1, c8(0x1c1a18), {"surface": "wood", "parent": PW, "name": "HatchBelow", "cast_shadow": false, "ceiling_mounted": true})
	b.box(-3.0, -0.4, B + WS_H - 0.35, B + WS_H - 0.2, 0.55, 0.7, c8(0x4a4a48), {"surface": "rust", "parent": PW, "name": "HoistBeam", "ceiling_mounted": true})
	for hx in [-2.5, -0.9]:
		b.box(hx - 0.025, hx + 0.025, B + WS_H - 0.2, B + WS_H, 0.58, 0.67, c8(0x4a4a48), {"surface": "rust", "parent": PW, "name": "HoistMount", "ceiling_mounted": true})
	ObjectKit.chain(b, Vector3(-1.0, B + WS_H - 0.35, 0.62), Vector3(-1.0, B + 2.22, 0.62), 0.06, 0.005, c8(0x8a8a86), PW, "HoistChain", {"ceiling_mounted": true})
	# a forged hook with a swivel eye
	ModelKit.place(b, ModelKit.tube([Vector3(0, 0.0, 0), Vector3(0, -0.09, 0), Vector3(0.0, -0.15, 0.03), Vector3(0, -0.15, 0.07), Vector3(0, -0.11, 0.08)], 0.011, 0.03, 8), Vector3(-1.0, B + 2.22, 0.6),
		"metal", c8(0x4a4a48), {"parent": PW, "name": "Hook", "ceiling_mounted": true})
	b.ref("ladderBase", Vector3(lx, B, 0.7))
	b.ref("hoist", Vector3(-1.0, B, 0.62))
	# wet floor and a drain
	for pz in [1.7, 3.3]:
		b.box(-5.2, -4.3, B, B + 0.02, pz - 0.3, pz + 0.3, Color.WHITE, {"material": BuildInteriors._decal_mat(b, "puddle"), "parent": PW, "name": "Puddle", "cast_shadow": false})
	b.box(-3.3, -3.0, B, B + 0.012, 1.7, 2.0, c8(0x2a2a28), {"surface": "metal", "parent": PW, "name": "Drain", "cast_shadow": false})
	PropKit.tube_light(b, Vector3(-5.8, B + 3.7, 1.9), Vector3(-3.8, B + 3.7, 1.9), B + WS_H, PW)
	b.ref("chiu", Vector3(-4.9, B, 1.95))
	b.ref("workshopTable", Vector3(-4.9, B, 1.3))


static func _crate(b: LevelBuilder, at: Vector3, col: Color, parent: String, crate_name: String) -> void:
	## A plastic fish crate: slatted sides, the rim darker.
	ObjectKit.plastic_crate(b, at.x - 0.2, at.x + 0.2, at.y, at.y + 0.31, at.z - 0.22, at.z + 0.22, col, parent, crate_name)


# ----------------------------------------------------------------------------- up top


static func _roof(b: LevelBuilder) -> void:
	var R := ROOF_Y
	b.add_floor(WS[0], WS[1], WS[2], WS[3], R, "workshopRoof")
	var o := {"band": 1.0, "fadeable": true, "parent": P + "/Roof"}
	# a low parapet round it, open where the plank lands
	for seg in [[WS[0], PLANK_X[0]], [PLANK_X[1], WS[1]]]:
		b.box(seg[0], seg[1], R, R + 0.4, WS[3] - 0.12, WS[3], c8(0x8a867c), o.merged({"surface": "concrete", "name": "Parapet"}))
	b.box(WS[0], WS[0] + 0.12, R, R + 0.4, WS[2], WS[3], c8(0x8a867c), o.merged({"surface": "concrete", "name": "Parapet"}))
	b.box(WS[0], WS[1], R, R + 0.4, WS[2], WS[2] + 0.12, c8(0x8a867c), o.merged({"surface": "concrete", "name": "Parapet"}))
	# the hatch and its cover, thrown back
	b.box(-2.45, -1.15, R, R + 0.12, 0.1, 1.15, c8(0x4a4a48), o.merged({"surface": "rust", "name": "HatchFrame"}))
	b.box(-2.35, -1.25, R + 0.12, R + 0.14, 0.2, 1.05, c8(0x1c1a18), o.merged({"surface": "wood", "name": "HatchDark", "cast_shadow": false}))
	var cover := Node3D.new()
	cover.name = "HatchCover"
	cover.position = Vector3(-2.45, R + 0.12, 0.62)
	cover.rotation.z = deg_to_rad(110)
	b.attach(cover, b.group(P + "/Roof"))
	b.tag(cover, 1.0, true)
	var lid := b.box(0.0, 1.3, -0.04, 0.0, -0.52, 0.52, c8(0x6a6a64), {"surface": "rust", "parent_node": cover, "name": "Cover"})
	lid.remove_meta("band")
	# a pot of spring onions, an aspidistra
	PlantKit.place(b, "onions", Vector3(-6.2, R, 0.7), P + "/Roof", 1.0)
	PlantKit.place(b, "aspidistra", Vector3(-0.6, R, 3.4), P + "/Roof", 1.0)
	# all of it is over the workshop's ceiling: none of it shows from inside
	_mark_above(b.group(P + "/Roof"), "workshop")
	b.ref("hatchTop", Vector3(-1.8, R, 1.6))
	b.ref("workshopRoof", Vector3(-3.5, R, 2.0))
	b.ref("plankGap", Vector3((PLANK_X[0] + PLANK_X[1]) / 2, R, SLOT_Z[0] - 0.4))
	# the plank's place across the slot: a floor, closed until the plank is laid
	b.add_floor(PLANK_X[0], PLANK_X[1], SLOT_Z[0], SLOT_Z[1], R, "plankWay")
	b.add_obstacle(PLANK_X[0] - 0.05, PLANK_X[1] + 0.05, SLOT_Z[0] + 0.15, SLOT_Z[1] - 0.15, R, "plankGap", "way:plank")


## Out of sight while Mei is in `room_id` (things on its roof, or hanging
## level with it just outside).
static func _mark_above(n: Node, room_id: String) -> void:
	if n.has_meta("band"):
		n.set_meta("above_room", room_id)
	for c in n.get_children():
		_mark_above(c, room_id)


# ----------------------------------------------------------------------------- the lane at the bottom


static func _lane(b: LevelBuilder) -> void:
	# a narrow lane at the foot of the slot, through the alcove's back door,
	# out to the street past a steel gate
	b.add_floor(LANE[0], LANE[1], LANE[2], LANE[3], A, "lane")
	b.add_floor(-1.1, -0.2, 4.0, LANE[2], A, "laneDoor")
	b.box(LANE[0], LANE[1], A - 0.3, A, LANE[2], LANE[3], c8(0x4e4a44), {"band": 0.0, "surface": "concrete", "parent": P + "/Lane", "name": "LaneFloor"})
	b.box(LANE[0], LANE[1], A, A + 0.012, 5.3, 5.5, c8(0x2a2a28), {"band": 0.0, "surface": "metal", "parent": P + "/Lane", "name": "Gutter", "cast_shadow": false})
	# the gate at its east end, and the street's light through it
	# its frame: a post each side and a rail over the top
	for gz in [LANE[2], LANE[3] - 0.1]:
		b.box(1.82, 2.0, A, A + 2.7, gz, gz + 0.1, c8(0x3a3a38), {"band": 0.0, "surface": "metal", "parent": P + "/Lane", "name": "GateFrame"})
	b.box(1.82, 2.0, A + 2.6, A + 2.7, LANE[2], LANE[3], c8(0x3a3a38), {"band": 0.0, "surface": "metal", "parent": P + "/Lane", "name": "GateFrame"})
	# (its bars: BuildYamen, locked until Chapter 4)
	b.lamp(Vector3(1.6, A + 2.2, 5.1), Color(1.0, 0.86, 0.62), 1.4, 5.0, {"name": "StreetLight"})
	_lane_ends(b)
	b.ref("lane", Vector3(-1.0, A, 5.1))
	b.ref("laneGate", Vector3(1.5, A, 5.1))
	b.ref("platformBottom", Vector3(PLATFORM.x, A, PLATFORM.z))


## Where the lane's walkable ground stops, something real stops Mei: at the
## west end a corrugated sheet nailed across between the walls, crates and fish
## boxes stacked against it, a pot in front; in the gap in the north side, an old
## oil drum and a pot. (No random draws: the city after this is seeded.)
static func _lane_ends(b: LevelBuilder) -> void:
	var LP := P + "/Lane"
	var x0: float = LANE[0]
	# the sheet, its ribs, and the battens it's nailed to
	b.box(x0 - 0.42, x0 - 0.38, A, A + 2.2, LANE[2] - 0.1, LANE[3] + 0.1, c8(0x7a6a58), {"band": 0.0, "surface": "rust", "parent": LP, "name": "LaneSheet"})
	var rz: float = LANE[2]
	while rz < LANE[3]:
		b.box(x0 - 0.38, x0 - 0.35, A, A + 2.2, rz, rz + 0.04, c8(0x6a5c4c), {"band": 0.0, "surface": "rust", "parent": LP, "name": "LaneSheetRib", "cast_shadow": false})
		rz += 0.15
	for by in [A + 0.3, A + 1.9]:
		b.box(x0 - 0.35, x0 - 0.3, by, by + 0.08, LANE[2] - 0.1, LANE[3] + 0.1, c8(0x5a4632), {"band": 0.0, "surface": "wood", "parent": LP, "name": "LaneBatten"})
	# crates against it, three high, and polystyrene fish boxes beside
	var blue := c8(0x3f6fa8)
	var red := c8(0xc9463a)
	for c in [[4.35, 0, blue], [4.35, 1, red], [4.35, 2, blue], [4.85, 0, red], [4.85, 1, blue]]:
		var cy: float = A + int(c[1]) * 0.36
		ObjectKit.plastic_crate(b, x0 - 0.3, x0 + 0.22, cy, cy + 0.34, c[0], c[0] + 0.46, c[2], LP, "LaneEndCrate", {"band": 0.0})
	for k in 3:
		var fy := A + k * 0.25
		b.box(x0 - 0.3, x0 + 0.3, fy, fy + 0.24, 5.4, 5.95, c8(0xe6e8e4), {"band": 0.0, "surface": "plaster", "parent": LP, "name": "FishBox"})
	b.add_obstacle(x0 - 0.4, x0 + 0.3, LANE[2], LANE[3], A, "laneEnd")
	PlantKit.place(b, "aspidistra", Vector3(x0 + 0.55, A, 5.65), LP, 0.0)
	b.add_obstacle(x0 + 0.35, x0 + 0.75, 5.45, 5.85, A, "laneEndPot")
	# the gap in the north side: a drum, rusted, and a pot of chillies beside it
	ObjectKit.oil_drum(b, Vector3(-5.0, A, 4.02), 0.29, 0.88, c8(0x4a5a4a), LP, {"band": 0.0})
	PlantKit.place(b, "chilli", Vector3(-4.55, A, 4.15), LP, 0.0)
	b.add_obstacle(-5.3, -4.3, 3.7, 4.45, A, "laneGapDrum")


# ----------------------------------------------------------------------------- the neighbours' balcony


static func _balcony(b: LevelBuilder) -> void:
	var R := ROOF_Y
	var o := {"band": 1.0, "fadeable": true, "parent": P + "/Balcony"}
	b.add_floor(BALCONY[0], BALCONY[1], BALCONY[2], BALCONY[3], R, "neighbourBalcony")
	b.box(BALCONY[0], BALCONY[1], R - 0.25, R, BALCONY[2], BALCONY[3], c8(0x7e7a70), o.merged({"surface": "concrete", "name": "BalconySlab"}))
	# the neighbours' back wall, a shuttered window and a potted tree
	b.box(BALCONY[0], BALCONY[1], R, R + 2.9, BALCONY[3], BALCONY[3] + 0.3, c8(0x9a9282), o.merged({"surface": "plaster", "name": "BackWall"}))
	b.box(-1.8, -0.8, R + 1.0, R + 2.2, BALCONY[3] - 0.03, BALCONY[3], c8(0x5a7a6a), o.merged({"surface": "wood", "name": "Shutter"}))
	# Keep the ladder landing clear: at -0.6 this pot overlapped Mei as she
	# climbed up from the lane beside the mahjong exit.
	PlantKit.place(b, "aspidistra", Vector3(-1.3, R, 6.65), P + "/Balcony", 1.0)
	# a rail along the slot side, open where the plank arrives and where the platform is loaded
	for seg in [[-5.9, PLANK_X[0]], [PLANK_X[1], 0.0]]:
		b.box(seg[0], seg[1], R + 0.93, R + 1.0, BALCONY[2], BALCONY[2] + 0.05, c8(0x4f7a5a), o.merged({"surface": "metal", "name": "Rail"}))
		b.box(seg[0], seg[0] + 0.05, R, R + 1.0, BALCONY[2], BALCONY[2] + 0.05, c8(0x4f7a5a), o.merged({"surface": "metal", "name": "RailPost"}))
		b.box(seg[1] - 0.05, seg[1], R, R + 1.0, BALCONY[2], BALCONY[2] + 0.05, c8(0x4f7a5a), o.merged({"surface": "metal", "name": "RailPost"}))
	b.ref("balcony", Vector3(-2.65, R, 6.5))
	# the gallows arm out over the slot, the pulley on it, the platform hanging below
	var gx: float = PLATFORM.x
	b.box(gx - 0.06, gx + 0.06, R, R + 3.0, 6.35, 6.47, c8(0x3a3a38), o.merged({"surface": "rust", "name": "GallowsPost"}))
	b.box(gx - 0.05, gx + 0.05, R + 2.85, R + 2.97, PLATFORM.z - 0.1, 6.47, c8(0x3a3a38), o.merged({"surface": "rust", "name": "GallowsArm"}))
	# the sheave: a grooved iron wheel on its pin
	ModelKit.place(b, ModelKit.lathe(PackedVector2Array([Vector2(0, -0.05), Vector2(0.12, -0.05), Vector2(0.12, -0.035), Vector2(0.09, 0.0), Vector2(0.12, 0.035), Vector2(0.12, 0.05), Vector2(0, 0.05)]), 24),
		Vector3(gx, R + 2.72, PLATFORM.z), "metal", c8(0x8a6a48), {"parent": "Special/Pulley", "name": "PulleyWheel", "band": 1.0, "rotation": Vector3(0, 0, PI / 2)})
	b.box(gx - 0.07, gx + 0.07, R + 2.72, R + 2.87, PLATFORM.z - 0.03, PLATFORM.z + 0.03, c8(0x4a4a48), {"band": 1.0, "surface": "metal", "parent": "Special/Pulley", "name": "PulleyBlock"})
	b.ref("pulley", Vector3(gx, R + 2.72, PLATFORM.z))
	# the winch on the post, where Kit works it
	# the drum, flanged, with rope wound on it
	ModelKit.place(b, ModelKit.lathe(PackedVector2Array([Vector2(0, -0.2), Vector2(0.15, -0.2), Vector2(0.15, -0.18), Vector2(0.1, -0.18), Vector2(0.1, 0.18), Vector2(0.15, 0.18), Vector2(0.15, 0.2), Vector2(0, 0.2)]), 24),
		Vector3(gx, R + 0.95, 6.55), "metal", c8(0x5a5a58), {"parent": P + "/Balcony", "name": "WinchDrum", "band": 1.0, "fadeable": true, "rotation": Vector3(0, 0, PI / 2)})
	ModelKit.place(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, -0.17), Vector2(0.125, -0.17), Vector2(0.125, 0.12), Vector2(0, 0.12)], 0.015), 24),
		Vector3(gx, R + 0.95, 6.55), "fabric", c8(0xb09a6a), {"parent": P + "/Balcony", "name": "WinchRope", "band": 1.0, "fadeable": true, "rotation": Vector3(0, 0, PI / 2)})
	b.box(gx + 0.2, gx + 0.24, R + 0.95, R + 1.25, 6.52, 6.58, c8(0x3a3a38), o.merged({"surface": "metal", "name": "WinchHandle"}))
	b.ref("winch", Vector3(gx + 0.55, R, 6.5))
	# The platform starts parked on the workshop roof.  Chapter Three moves it
	# beneath the pulley only when Mei rigs the rope; before that, leaving it over
	# the open slot made the deck and its loose sling appear to float unsupported.
	var plat := Node3D.new()
	plat.name = "LoadingPlatform"
	plat.position = PLATFORM_PARKED
	b.attach(plat, b.group("Special"))
	b.tag(plat, 1.0)
	for k in 5:
		var sx := -0.45 + k * 0.2
		var slat := b.box(sx, sx + 0.16, -0.05, 0.0, -0.45, 0.45, c8(0x8a6a48), {"surface": "wood", "parent_node": plat, "name": "Slat"})
		slat.remove_meta("band")
	for cx in [-0.42, 0.42]:
		for cz in [-0.42, 0.42]:
			var ch := b.cylinder(Vector3(cx, 0.0, cz), Vector3(0.0, 1.2, 0.0), 0.008, b.surface("metal"), {"parent_node": plat, "name": "Chain", "tint": c8(0x8a8a86), "cast_shadow": false})
			ch.remove_meta("band")
			ch.visible = false
	b.add_floor(PLATFORM.x - 0.5, PLATFORM.x + 0.5, PLATFORM.z - 0.5, BALCONY[2], R, "platformWay")
	b.add_obstacle(PLATFORM.x - 0.55, PLATFORM.x + 0.55, PLATFORM.z - 0.55, BALCONY[2] - 0.05, R, "platform", "way:never")
	# the neighbours' signboard: a big painted board on a steel frame, hinged at
	# the wall and standing out across the balcony, right in the crates' way.
	# Its hinges are on the back, seen only from the west.
	var sign := Node3D.new()
	sign.name = "Signboard"
	sign.position = Vector3(SIGN_X, R, BALCONY[3])
	b.attach(sign, b.group("Special"))
	b.tag(sign, 1.0, true)
	# Leave a hand's width between the projecting board and the balcony rail.
	# It still blocks the route, but no longer passes through the green top rail.
	var board := b.box(-0.03, 0.03, 0.3, 2.3, -0.88, 0.0, c8(0x201418), {"surface": "metal", "parent_node": sign, "name": "SignBox"})
	board.remove_meta("band")
	for sgn in [-1.0, 1.0]:
		var face := b.card("res://assets/textures/props/sign_seafood.png", Vector3(sgn * 0.035, 1.3, -0.44), Vector2(0.83, 1.95), Vector3(sgn, 0, 0),
			{"parent_node": sign, "untagged": true, "name": "SignFace", "emission": 0.0})
		face.position = Vector3(sgn * 0.035, 1.3, -0.44)
	for hy in [0.55, 2.05]:
		var hinge := b.box(-0.09, -0.03, hy, hy + 0.14, -0.08, 0.0, c8(0xc9a55a), {"surface": "metal", "parent_node": sign, "name": "Hinge"})
		hinge.remove_meta("band")
	b.add_obstacle(SIGN_X - 0.1, SIGN_X + 0.1, BALCONY[2], BALCONY[3], R, "signboard", "way:sign")
	b.ref("signHinges", Vector3(SIGN_X - 0.5, R, 6.5))
	# from inside the workshop the balcony would hang in the air over its wall:
	# it goes with the roof while Mei is in there
	for n in [b.group(P + "/Balcony"), b.group("Special/Pulley"), plat, sign]:
		_mark_above(n, "workshop")
