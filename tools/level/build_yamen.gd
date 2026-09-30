class_name BuildYamen
extends RefCounted

## The yamen: the one old building the City grew up around, and the open
## ground in front of it. A low Qing hall with a tiled roof and two iron
## cannons from when this was a fort; for years now the old people's home.
## After the lanes, the only place where the sun reaches the ground.
##
## It lies east of the lane behind Chiu's workshop, through the lane's gate
## (locked until Chapter 4). On its east side the buildings pressed against it
## hold the way Mr. Cheng's plan can't show: the storage room (whose door is
## too narrow for a cabinet), a gap between two walls, a shared landing whose
## stair seems to end at a wall, the old classroom upstairs, its balcony door
## with a folding leaf, and the balcony's stair back down into the courtyard.
##
## Permanent: it is there every day.

const A := LevelBuilder.LEVEL_A
const B := LevelBuilder.LEVEL_B
const COURT := [6.0, 15.5, -3.0, 4.3]       # the courtyard, open to the sky
const MOUTH := [6.0, 11.0, 4.3, 6.0]        # where the lane comes in
const LANE_EXT := [1.9, 6.0, 4.3, 6.0]      # the lane, on past its gate
const HALL := [6.5, 13.7, -6.5, -3.4]       # the yamen hall's footprint
const HALL_FRONT := -4.2                    # its front wall; a veranda before it
const STORE := [14.0, 17.0, -6.5, -3.5]     # the storage room, where the cabinet is
const GAP := [17.3, 18.1, -6.5, -1.0]       # the service space between two walls
const LANDING := [15.8, 18.1, -1.0, 3.0]    # the shared landing and its stair
const STAIR_X := [16.4, 17.6]
const TOP := [16.0, 18.1, 0.6, 4.3]         # the stair's head, on Level B
const CLASS := [11.0, 15.7, 0.8, 4.3]       # the old classroom, on Level B
const BALC := [11.0, 15.7, -0.4, 0.5]       # its balcony over the courtyard
const REAR_X := [8.6, 11.0]                 # the balcony's stair down
const P := "Structure/Yamen"
const PF := "Furniture/Yamen"


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	_courtyard(b)
	_hall(b)
	_store(b)
	_landing(b)
	_classroom(b)
	_balcony(b)
	_chapter_bits(b)


# ----------------------------------------------------------------------------- the open ground


static func _courtyard(b: LevelBuilder) -> void:
	b.add_floor(LANE_EXT[0], LANE_EXT[1], LANE_EXT[2], LANE_EXT[3], A, "yamenLane")
	b.add_floor(COURT[0], COURT[1], COURT[2], COURT[3], A, "yamen")
	b.add_floor(MOUTH[0], MOUTH[1], MOUTH[2], MOUTH[3], A, "yamenMouth")
	var stone := c8(0xa8a293)
	b.box(LANE_EXT[0], LANE_EXT[1], A - 0.3, A, LANE_EXT[2], LANE_EXT[3], c8(0x4e4a44), {"band": 0.0, "surface": "concrete", "parent": P, "name": "LaneFloor"})
	b.box(COURT[0], COURT[1], A - 0.3, A, COURT[2], COURT[3], stone, {"band": 0.0, "surface": "concrete", "parent": P, "name": "Paving", "is_floor": true})
	b.box(MOUTH[0], MOUTH[1], A - 0.3, A, MOUTH[2], MOUTH[3], stone, {"band": 0.0, "surface": "concrete", "parent": P, "name": "Paving", "is_floor": true})
	# the flagstones' joints, and a drain down the middle
	var jz: float = COURT[2] + 1.2
	while jz < MOUTH[3]:
		b.box(COURT[0], COURT[1] if jz < COURT[3] else MOUTH[1], A, A + 0.004, jz, jz + 0.03, stone.darkened(0.2), {"band": 0.0, "surface": "concrete", "parent": P, "name": "Joint", "cast_shadow": false})
		jz += 1.2
	b.box(9.9, 10.3, A, A + 0.008, -2.6, 5.8, c8(0x3a3a36), {"band": 0.0, "surface": "metal", "parent": P, "name": "Drain", "cast_shadow": false})
	# the two old cannons before the hall, from when the City was a fort
	# (lying side-on to the hall, muzzles outward, so their shape reads from the front)
	for cx in [7.4, 12.8]:
		var out := -1.0 if cx < 10.0 else 1.0
		b.box(cx - 0.75, cx + 0.75, A, A + 0.3, -2.7, -2.0, c8(0x8e887a), {"band": 0.0, "surface": "concrete", "parent": P, "name": "CannonPlinth", "collide": true, "collide_y": A})
		b.cylinder(Vector3(cx - out * 0.55, A + 0.5, -2.35), Vector3(cx + out * 0.7, A + 0.47, -2.35), 0.15, b.surface("rust"), {"parent": P, "name": "Cannon", "tint": c8(0x2e2c2a), "band": 0.0, "segments": 14})
		b.cylinder(Vector3(cx + out * 0.66, A + 0.47, -2.35), Vector3(cx + out * 0.74, A + 0.47, -2.35), 0.18, b.surface("rust"), {"parent": P, "name": "Muzzle", "tint": c8(0x2a2826), "band": 0.0, "segments": 14})
		b.piece(PropKit._sphere(0.19), Vector3(cx - out * 0.58, A + 0.5, -2.35), b.surface("rust"), {"parent": P, "name": "CannonBreech", "tint": c8(0x2e2c2a), "band": 0.0})
		for wz in [-2.6, -2.1]:
			b.box(cx - 0.22, cx + 0.22, A + 0.3, A + 0.42, wz - 0.03, wz + 0.03, c8(0x5a4632), {"band": 0.0, "surface": "wood", "parent": P, "name": "CannonChock", "cast_shadow": false})
	b.ref("cannons", Vector3(7.4, A, -1.6))
	# a tree in a raised bed, the only one Mei knows: the old people sit under it
	b.box(6.3, 7.7, A, A + 0.45, 0.9, 2.3, c8(0x8e887a), {"band": 0.0, "surface": "concrete", "parent": P, "name": "TreeBed", "collide": true, "collide_y": A})
	b.box(6.4, 7.6, A + 0.45, A + 0.47, 1.0, 2.2, c8(0x4a3a2a), {"band": 0.0, "surface": "grain", "parent": P, "name": "Soil", "cast_shadow": false})
	b.cylinder(Vector3(7.0, A + 0.45, 1.6), Vector3(6.9, A + 2.6, 1.6), 0.12, b.surface("wood"), {"parent": P, "name": "Trunk", "tint": c8(0x5a4632), "band": 0.0})
	for leaf in [[Vector3(6.9, A + 3.0, 1.6), 0.9], [Vector3(6.5, A + 2.7, 1.2), 0.6], [Vector3(7.4, A + 2.8, 1.9), 0.65], [Vector3(7.0, A + 3.4, 1.9), 0.55]]:
		b.piece(PropKit._sphere(leaf[1]), leaf[0], b.surface("fabric"), {"parent": P, "name": "Leaves", "tint": c8(0x4f6a3a), "band": 0.0, "fadeable": true})
	b.ref("yamenTree", Vector3(8.2, A, 1.6))
	# folding chairs by the tree, where the old people sit
	for ch in [[8.1, 1.1], [8.2, 2.2]]:
		PropKit.stool(b, ch[0], ch[1], A, c8(0x3f6fa8), PF, 0.42)
	b.ref("yamenCourt", Vector3(9.0, A, 1.0))
	b.ref("yamenLane", Vector3(4.0, A, 5.1))
	b.ref("loadingArea", Vector3(7.4, A, 3.4))


# ----------------------------------------------------------------------------- the hall


static func _hall(b: LevelBuilder) -> void:
	var brick := c8(0x8a8c88)
	var o := {"band": 0.0, "surface": "concrete", "parent": P + "/Hall"}
	var x0: float = HALL[0]
	var x1: float = HALL[1]
	var z0: float = HALL[2]
	var h := 3.2
	# grey brick walls: back, sides, and the front set back behind a veranda
	b.box(x0, x1, A, A + h, z0, z0 + 0.3, brick, o.merged({"name": "HallWall"}))
	for sx in [[x0, x0 + 0.3], [x1 - 0.3, x1]]:
		b.box(sx[0], sx[1], A, A + h, z0, HALL[3], brick, o.merged({"name": "HallWall", "fadeable": true}))
	var fz: float = HALL_FRONT
	var door := [9.6, 10.6]
	for seg in [[x0 + 0.3, door[0]], [door[1], x1 - 0.3]]:
		b.box(seg[0], seg[1], A, A + h, fz - 0.3, fz, brick, o.merged({"name": "HallFront"}))
	b.box(door[0], door[1], A + 2.4, A + h, fz - 0.3, fz, brick, o.merged({"name": "HallFront"}))
	# (the door opening's head is filled in below, over the doors)
	b.add_obstacle(x0, x1, z0, fz, A, "yamenHall")
	# the double doors, red, shut; a plaque over them
	for dx in [[door[0], 10.1], [10.1, door[1]]]:
		b.box(dx[0] + 0.02, dx[1] - 0.02, A, A + 2.3, fz - 0.2, fz - 0.14, c8(0x8a2a24), o.merged({"surface": "wood", "name": "HallDoor"}))
		b.box(dx[0] + 0.12, dx[1] - 0.12, A + 0.3, A + 2.0, fz - 0.14, fz - 0.12, c8(0x9a3a2e), o.merged({"surface": "wood", "name": "HallDoorPanel", "cast_shadow": false}))
	b.box(door[0], door[1], A + 2.3, A + 2.4, fz - 0.3, fz, brick, o.merged({"name": "HallFront"}))
	b.card("res://assets/textures/props/plaque_yamen.png", Vector3(10.1, A + 2.64, fz + 0.01), Vector2(1.5, 0.46), Vector3(0, 0, 1), {"parent": P + "/Hall", "name": "Plaque", "band": 0.0})
	# lattice windows either side
	for wx in [[7.4, 8.8], [11.4, 12.8]]:
		b.box(wx[0], wx[1], A + 1.0, A + 2.2, fz + 0.0, fz + 0.02, c8(0x2a2622), o.merged({"surface": "wood", "name": "Window", "cast_shadow": false}))
		var lx: float = wx[0] + 0.23
		while lx < wx[1] - 0.1:
			b.box(lx, lx + 0.04, A + 1.0, A + 2.2, fz + 0.02, fz + 0.05, c8(0x6a4a30), o.merged({"surface": "wood", "name": "Lattice", "cast_shadow": false}))
			lx += 0.23
		for ly in [A + 1.4, A + 1.8]:
			b.box(wx[0], wx[1], ly, ly + 0.04, fz + 0.02, fz + 0.05, c8(0x6a4a30), o.merged({"surface": "wood", "name": "Lattice", "cast_shadow": false}))
	# the moving notice pasted up beside the door
	b.card("res://assets/textures/props/notice_clearance.png", Vector3(9.15, A + 1.5, fz + 0.01), Vector2(0.4, 0.52), Vector3(0, 0, 1), {"parent": P + "/Hall", "name": "Notice", "band": 0.0})
	# the veranda: a stone step along its edge, four red columns holding the eaves
	b.box(x0 + 0.3, x1 - 0.3, A, A + 0.06, fz, HALL[3], c8(0x9a9486), o.merged({"name": "Veranda", "cast_shadow": false}))
	for cx in [7.1, 8.9, 11.3, 13.1]:
		b.cylinder(Vector3(cx, A, -3.55), Vector3(cx, A + h, -3.55), 0.12, b.surface("wood"), {"parent": P + "/Hall", "name": "Column", "tint": c8(0x9a3a2e), "band": 0.0, "fadeable": true})
		b.add_obstacle(cx - 0.14, cx + 0.14, -3.7, -3.4, A, "column")
	b.box(x0, x1, A + h - 0.25, A + h, -3.7, -3.4, c8(0x5a3a2a), o.merged({"surface": "wood", "name": "Beam", "fadeable": true}))
	# the roof: two pitches of grey barrel tiles, rows of them running down to
	# the eaves, a ridge along the top with its ends turned up
	var rise := 1.5
	var eave_f := -2.8
	var eave_b := z0 - 0.4
	var rz := (eave_f + eave_b) * 0.5
	var ry := A + h + rise
	var slate := c8(0x5d6260)
	for slope in [[eave_f, 1.0], [eave_b, -1.0]]:
		var ez: float = slope[0]
		var sg: float = slope[1]
		var run := absf(rz - ez)
		var span := sqrt(run * run + rise * rise)
		var ang := atan2(rise, run) * sg
		var cz := (ez + rz) * 0.5
		var cy := A + h + rise * 0.5
		var pitch := b.box(x0 - 0.45, x1 + 0.45, cy - 0.05, cy + 0.05, cz - span * 0.5, cz + span * 0.5, slate,
			o.merged({"surface": "concrete", "name": "RoofPitch", "fadeable": true}))
		pitch.rotation.x = ang
		# the tile rows: half-round, dark, one every hand's width
		var tx := x0 - 0.35
		while tx < x1 + 0.4:
			b.cylinder(Vector3(tx, A + h + 0.07, ez), Vector3(tx, ry + 0.02, rz), 0.055, b.surface("concrete"),
				{"parent": P + "/Hall", "name": "TileRow", "tint": c8(0x464a49), "band": 0.0, "fadeable": true, "cast_shadow": false, "segments": 6})
			tx += 0.26
		# a line of round end-tiles along the eave
		b.box(x0 - 0.45, x1 + 0.45, A + h - 0.02, A + h + 0.08, ez - 0.06 * sg, ez + 0.06 * sg, c8(0x3e4241), o.merged({"surface": "concrete", "name": "EaveTiles", "fadeable": true}))
	b.box(x0 - 0.5, x1 + 0.5, ry - 0.06, ry + 0.14, rz - 0.13, rz + 0.13, c8(0x3e4040), o.merged({"surface": "concrete", "name": "Ridge", "fadeable": true}))
	for ex in [x0 - 0.5, x1 + 0.4]:
		b.box(ex, ex + 0.1, ry + 0.1, ry + 0.38, rz - 0.1, rz + 0.1, c8(0x3e4040), o.merged({"surface": "concrete", "name": "RidgeEnd", "fadeable": true}))
	# gable ends: brick triangles under the pitches
	for gx in [x0, x1 - 0.3]:
		var gable := PrismMesh.new()
		gable.size = Vector3(absf(eave_f - eave_b) - 0.3, rise, 0.3)
		b.piece(gable, Vector3(gx + 0.15, A + h + rise * 0.5, rz), b.surface("concrete"),
			{"parent": P + "/Hall", "name": "Gable", "tint": brick, "band": 0.0, "rotation": Vector3(0, PI / 2, 0), "fadeable": true})
	b.ref("hallDoor", Vector3(10.1, A, -3.2))


# ----------------------------------------------------------------------------- the cabinet's way


static func _store(b: LevelBuilder) -> void:
	b.room({"x0": STORE[0], "x1": STORE[1], "z0": STORE[2], "z1": STORE[3], "y": A, "h": 3.4, "name": "YamenStore", "id": "yamenstore",
		"wall": c8(0x9a9282), "floor": c8(0x5a544a), "open": {"s": [[14.3, 15.0]], "e": [[-6.3, -5.6]]}, "parent": "Structure/LevelA"})
	# the door onto the courtyard: one leaf, a man's width, not a cabinet's
	b.add_floor(14.3, 15.0, STORE[3] - 0.1, COURT[2] + 0.1, A, "storeDoor")
	b.ref("storeDoor", Vector3(14.65, A, -2.6))
	# shelves along the back, sacks and boxes, a stack of folding chairs
	PropKit.shelf(b, 14.1, 15.9, -6.45, -6.05, A, 2.0, c8(0x6b4a30), PF + "/Store", 3)
	b.add_obstacle(14.1, 15.9, -6.45, -6.05, A, "storeShelf")
	PropKit.cardboard(b, 14.1, 14.9, A, A + 0.6, -5.2, -4.4, c8(0xa8834f), PF + "/Store")
	b.add_obstacle(14.1, 14.9, -5.2, -4.4, A, "storeBoxes")
	for k in 5:
		b.box(16.3, 16.9, A + k * 0.06, A + k * 0.06 + 0.04, -4.4, -3.7, c8(0x3f6fa8), {"surface": "metal", "parent": PF + "/Store", "name": "FoldedChair"})
	# the side way out, behind the shelves, into the space between the walls
	b.add_floor(16.9, 17.4, -6.3, -5.6, A, "sideGap")
	b.add_obstacle(16.95, 17.35, -6.3, -5.6, A, "sideGap", "way:sidegap")
	b.ref("sideGap", Vector3(16.6, A, -5.95))
	PropKit.bulb(b, Vector3(15.5, A + 2.8, -5.0), A + 3.4, PF + "/Store")
	# the gap itself: a strip of concrete between two walls, pipes and meters on them
	b.add_floor(GAP[0], GAP[1], GAP[2], GAP[3], A, "serviceGap")
	var o := {"band": 0.0, "surface": "plaster", "parent": P + "/Gap", "fadeable": true}
	b.box(GAP[0], GAP[1], A - 0.3, A, GAP[2], GAP[3], c8(0x4e4a44), {"band": 0.0, "surface": "concrete", "parent": P + "/Gap", "name": "GapFloor"})
	b.box(GAP[1], GAP[1] + 0.3, A, A + 4.2, GAP[2] - 0.3, LANDING[3] + 0.3, c8(0x8a8272), o.merged({"name": "GapWall"}))
	b.box(GAP[0], GAP[1], A, A + 4.2, GAP[2] - 0.3, GAP[2], c8(0x8a8272), o.merged({"name": "GapWall"}))
	PropKit.pipe_run(b, [Vector3(18.0, A + 3.8, -6.3), Vector3(18.0, A + 3.8, -1.2), Vector3(18.0, A + 0.3, -1.2)], 0.04, c8(0x8a8c86), P + "/Gap", 0.0, "GapPipe", true)
	for mz in [-5.0, -3.2]:
		b.box(18.0, 18.1, A + 1.5, A + 1.8, mz, mz + 0.25, c8(0x5a5a58), {"band": 0.0, "surface": "metal", "parent": P + "/Gap", "name": "Meter", "fadeable": true})


static func _landing(b: LevelBuilder) -> void:
	b.room({"x0": LANDING[0], "x1": LANDING[1], "z0": LANDING[2], "z1": LANDING[3], "y": A, "name": "YamenLanding",
		"wall": c8(0x8a8272), "floor": c8(0x4e4a42), "open": {"n": [[GAP[0], GAP[1]]]}, "skip": ["e"],
		"parent": "Structure/LevelA", "wall_surface": "concrete"})
	var SP := P + "/Landing"
	# the stair, climbing south to the floor above
	for i in 9:
		var top := A + 0.5 * (i + 1)
		var sz := 0.8 + i * 0.245
		b.box(STAIR_X[0], STAIR_X[1], top - 0.5, top, sz, minf(sz + 0.28, LANDING[3]), c8(0x5d5a52), {"surface": "concrete", "parent": SP, "name": "Step", "band": 0.0})
		b.box(STAIR_X[0], STAIR_X[1], top - 0.03, top, sz, sz + 0.05, c8(0xd8b23a), {"surface": "metal", "parent": SP, "name": "Nosing", "cast_shadow": false, "band": 0.0})
	b.add_obstacle(STAIR_X[0] - 0.05, STAIR_X[1] + 0.05, 0.75, LANDING[3], A, "yamenStair")
	# letterboxes for the flats above, most of them taped shut
	b.card("res://assets/textures/props/mailboxes.png", Vector3(15.82, A + 1.4, -0.2), Vector2(1.0, 0.7), Vector3(1, 0, 0), {"parent": SP, "name": "Letterboxes", "band": 0.0})
	PropKit.bulb(b, Vector3(16.9, A + 3.4, -0.3), A + 4.2, SP)
	b.ref("yamenStairUp", Vector3(17.0, A, 0.3))
	# at the top: a strip of landing, a wall ahead, and (seen from the west) a way through into the next building
	b.room({"x0": TOP[0], "x1": TOP[1], "z0": TOP[2], "z1": TOP[3], "y": B, "name": "YamenTop",
		"wall": c8(0x8a8272), "floor": c8(0x4e4a42), "open": {"w": [[3.1, 3.9]]}, "lintel": true,
		"floor_hole": [STAIR_X[0], STAIR_X[1], TOP[2], 3.0], "parent": "Structure/LevelB", "wall_surface": "concrete"})
	b.add_obstacle(STAIR_X[0], STAIR_X[1], TOP[2], 3.0, B, "yamenStairHole")
	for px in [STAIR_X[0], (STAIR_X[0] + STAIR_X[1]) * 0.5, STAIR_X[1]]:
		b.box(px - 0.03, px + 0.03, B, B + 1.0, 2.94, 3.0, c8(0x4f7a5a), {"surface": "metal", "parent": P + "/Top", "name": "RailPost", "band": 1.0})
	b.box(STAIR_X[0], STAIR_X[1], B + 0.93, B + 1.0, 2.94, 3.0, c8(0x4f7a5a), {"surface": "metal", "parent": P + "/Top", "name": "Rail", "band": 1.0})
	PropKit.bulb(b, Vector3(17.0, B + 3.2, 3.6), B + 4.2, P + "/Top")
	b.ref("yamenStairDown", Vector3(17.0, B, 3.35))
	b.ref("yamenTop", Vector3(17.0, B, 3.6))
	b.add_floor(15.6, 16.1, 3.1, 3.9, B, "stairGap")
	b.add_obstacle(15.65, 16.05, 3.1, 3.9, B, "stairGap", "way:stairgap")


static func _classroom(b: LevelBuilder) -> void:
	b.room({"x0": CLASS[0], "x1": CLASS[1], "z0": CLASS[2], "z1": CLASS[3], "y": B, "name": "Classroom", "id": "classroom",
		"wall": c8(0xc8c0a8), "floor": c8(0x7a5a3e), "floor_surface": "wood", "open": {"n": [[12.3, 13.8]]}, "skip": ["e"],
		"dado": "tiles", "dado_color": c8(0x9ab8a8), "parent": "Structure/LevelB"})
	var PK := PF + "/Classroom"
	# the blackboard on the west wall, the last thing written on it still there
	b.box(CLASS[0] + 0.0, CLASS[0] + 0.05, B + 0.9, B + 2.4, 1.6, 3.6, c8(0x5a4030), {"surface": "wood", "parent": PK, "name": "BoardFrame"})
	b.card("res://assets/textures/props/blackboard.png", Vector3(CLASS[0] + 0.06, B + 1.65, 2.6), Vector2(1.9, 0.95), Vector3(1, 0, 0), {"parent": PK, "name": "Blackboard", "band": 1.0})
	b.ref("blackboard", Vector3(CLASS[0] + 0.8, B, 2.6))
	# the desks: two rows left where they were, the rest pushed against the east end
	for dz in [1.6, 2.7]:
		for dx in [12.2, 13.3]:
			PropKit.table(b, dx, dx + 0.8, dz, dz + 0.45, B, 0.68, c8(0x8a6a48), PK)
			b.add_obstacle(dx, dx + 0.8, dz, dz + 0.45, B, "desk")
			PropKit.stool(b, dx + 0.4, dz + 0.72, B, c8(0x6b4a30), PK, 0.38)
	# the ones stacked against the way through to the stair: they shift when Mei finds it
	var stack := Node3D.new()
	stack.name = "DeskStack"
	stack.position = Vector3(15.25, B, 3.5)
	b.attach(stack, b.group("Special"))
	b.tag(stack, 1.0)
	for k in 2:
		var top := b.box(-0.4, 0.4, 0.62 + k * 0.7, 0.68 + k * 0.7, -0.45, 0.45, c8(0x8a6a48), {"surface": "wood", "parent_node": stack, "name": "StackedDesk"})
		top.remove_meta("band")
		for lx in [-0.36, 0.3]:
			for lz in [-0.4, 0.34]:
				var leg := b.box(lx, lx + 0.06, k * 0.7, k * 0.7 + 0.62, lz, lz + 0.06, c8(0x6b4a30), {"surface": "wood", "parent_node": stack, "name": "StackedLeg"})
				leg.remove_meta("band")
	b.add_obstacle(14.85, 15.65, 3.05, 3.95, B, "deskStack", "way:stairgap")
	b.card("res://assets/textures/props/poster_1.png", Vector3(14.0, B + 2.0, CLASS[3]), Vector2(0.5, 0.7), Vector3(0, 0, -1), {"parent": PK, "name": "Poster", "band": 1.0})
	PropKit.tube_light(b, Vector3(12.2, B + 3.7, 2.5), Vector3(14.4, B + 3.7, 2.5), PK)
	b.ref("classroom", Vector3(13.3, B, 2.2))
	# the balcony door: one leaf open to walk through, the other folded shut and bolted
	b.add_floor(12.3, 13.1, BALC[3] - 0.1, CLASS[2] + 0.1, B, "classDoor")
	var leaf := Node3D.new()
	leaf.name = "FoldPanel"
	leaf.position = Vector3(13.8, B, CLASS[2] - 0.15)
	b.attach(leaf, b.group("Special"))
	b.tag(leaf, 1.0, true)
	var board := b.box(-0.7, 0.0, 0.0, 2.2, -0.03, 0.03, c8(0x6a7a70), {"surface": "wood", "parent_node": leaf, "name": "Leaf"})
	board.remove_meta("band")
	for py in [0.3, 1.25]:
		var panel := b.box(-0.6, -0.1, py, py + 0.75, -0.05, -0.03, c8(0x7a8a80), {"surface": "wood", "parent_node": leaf, "name": "LeafPanel", "cast_shadow": false})
		panel.remove_meta("band")
	# the bolts are on the balcony side
	for by in [0.25, 1.95]:
		var bolt := b.box(-0.55, -0.35, by, by + 0.05, -0.08, -0.05, c8(0xc9a55a), {"surface": "metal", "parent_node": leaf, "name": "Bolt", "cast_shadow": false})
		bolt.remove_meta("band")
	b.ref("foldPanel", Vector3(13.45, B, 0.1))


static func _balcony(b: LevelBuilder) -> void:
	b.add_floor(BALC[0], BALC[1], BALC[2], BALC[3], B, "yamenBalcony")
	var o := {"band": 1.0, "fadeable": true, "parent": P + "/Balcony"}
	b.box(BALC[0], BALC[1], B - 0.22, B, BALC[2], BALC[3], c8(0x8e887a), o.merged({"surface": "concrete", "name": "BalconySlab"}))
	var rail := c8(0x4f7a5a)
	b.box(BALC[0] + 0.3, BALC[1], B + 0.93, B + 1.0, BALC[2], BALC[2] + 0.05, rail, o.merged({"surface": "metal", "name": "Rail"}))
	b.box(BALC[1] - 0.05, BALC[1], B + 0.93, B + 1.0, BALC[2], BALC[3], rail, o.merged({"surface": "metal", "name": "Rail"}))
	var px: float = BALC[0] + 0.3
	while px <= BALC[1]:
		b.box(px - 0.02, px + 0.02, B, B + 1.0, BALC[2], BALC[2] + 0.04, rail, o.merged({"surface": "metal", "name": "Baluster"}))
		px += 0.25
	# brackets under it, into the classroom wall
	var bx: float = BALC[0] + 0.4
	while bx < BALC[1]:
		b.cylinder(Vector3(bx, B - 0.9, BALC[3]), Vector3(bx, B - 0.22, BALC[2] + 0.1), 0.03, b.surface("rust"), {"parent": P + "/Balcony", "name": "Bracket", "tint": c8(0x4a4a48), "band": 1.0})
		bx += 1.4
	# the stair down to the courtyard, off the balcony's west end
	var n := 9
	for i in n:
		var x1: float = REAR_X[1] - i * (REAR_X[1] - REAR_X[0]) / n
		var top := B - (i + 1) * (B - A) / float(n + 1)
		b.box(x1 - (REAR_X[1] - REAR_X[0]) / n - 0.02, x1, top - 0.08, top, BALC[2] + 0.05, BALC[3] - 0.05, c8(0x7e7a70),
			{"band": 0.0 if top < 4.4 else 1.0, "surface": "concrete", "parent": P + "/RearStair", "name": "Step", "fadeable": true})
	b.cylinder(Vector3(REAR_X[0], A + 1.0, BALC[2] + 0.05), Vector3(REAR_X[1], B + 1.0, BALC[2] + 0.05), 0.025, b.surface("metal"),
		{"parent": P + "/RearStair", "name": "Handrail", "tint": rail, "band": 0.0, "fadeable": true})
	b.add_obstacle(REAR_X[0], REAR_X[1], BALC[2], BALC[3], A, "rearStair")
	b.ref("rearStairTop", Vector3(BALC[0] + 0.35, B, 0.05))
	b.ref("rearStairFoot", Vector3(REAR_X[0] - 0.4, A, 0.05))
	b.ref("yamenBalcony", Vector3(13.5, B, 0.05))


# ----------------------------------------------------------------------------- only some days


static func _chapter_bits(b: LevelBuilder) -> void:
	# the cabinet for Room C-714, in the storage room until Chapter 4 takes it out
	var C14 := "ChapterProps/Ch1-4"
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.position = Vector3(15.6, A, -5.0)
	b.attach(cab, b.group(C14))
	b.tag(cab, 0.0)
	var wood := c8(0x6b4a30)
	var body := b.box(-0.55, 0.55, 0.0, 1.9, -0.3, 0.3, wood, {"surface": "wood", "parent_node": cab, "name": "CabinetBody"})
	body.remove_meta("band")
	for dx in [[-0.52, -0.01], [0.01, 0.52]]:
		var dr := b.box(dx[0], dx[1], 0.1, 1.8, 0.3, 0.33, wood.lightened(0.1), {"surface": "wood", "parent_node": cab, "name": "CabinetDoor", "cast_shadow": false})
		dr.remove_meta("band")
	var lbl := b.card("res://assets/textures/props/label_c714.png", Vector3(0, 1.3, 0.34), Vector2(0.32, 0.19), Vector3(0, 0, 1), {"parent_node": cab, "untagged": true, "name": "Label"})
	lbl.position = Vector3(0.25, 1.3, 0.34)
	b.add_obstacle(15.0, 16.2, -5.35, -4.65, A, "cabinet", "way:cabinet")
	b.ref("cabinet", Vector3(15.6, A, -4.3))

	# Chapter 4: the movers at work, Mrs. Cheung's things labelled in the courtyard
	var C4 := "ChapterProps/Ch4"
	PropKit.table(b, 9.0, 10.2, -1.2, -0.55, A, 0.72, c8(0x9a9aa0), C4, "metal")
	b.add_obstacle(9.0, 10.2, -1.2, -0.55, A, "cheungTable")
	b.box(9.8, 10.0, A + 0.72, A + 0.8, -0.95, -0.75, c8(0x3a3a4a), {"surface": "grain", "parent": C4, "name": "Teacup", "cast_shadow": false})
	# a wardrobe and her boxes, each with its label
	b.box(9.2, 10.2, A, A + 1.8, 3.2, 3.75, c8(0x7a5a3a), {"surface": "wood", "parent": C4, "name": "Wardrobe", "collide": true, "collide_y": A})
	b.card("res://assets/textures/props/label_c714.png", Vector3(9.7, A + 1.2, 3.76), Vector2(0.3, 0.18), Vector3(0, 0, 1), {"parent": C4, "name": "Label", "band": 0.0})
	PropKit.cardboard(b, 10.1, 10.9, A, A + 0.6, 4.6, 5.4, c8(0xa8834f), C4)
	PropKit.cardboard(b, 10.15, 10.8, A + 0.6, A + 1.05, 4.7, 5.3, c8(0x9c7a48), C4)
	b.add_obstacle(10.1, 10.9, 4.6, 5.4, A, "yamenBoxes")
	# the movers' handcart, waiting at the courtyard's mouth
	b.box(6.5, 7.9, A + 0.25, A + 0.32, 3.9, 4.6, c8(0x5a4a3a), {"surface": "wood", "parent": C4, "name": "Handcart", "collide": true, "collide_y": A})
	for wx in [6.7, 7.7]:
		b.cylinder(Vector3(wx, A + 0.2, 3.85), Vector3(wx, A + 0.2, 4.65), 0.2, b.surface("rust"), {"parent": C4, "name": "Wheel", "tint": c8(0x2a2a28), "band": 0.0})
	# the people: Mrs. Cheung at her table, Mr. Cheng with his plan, the movers at the storage room
	b.resident("cheung", "cheung", Vector3(9.6, A, -1.6), {"anim": "sit", "facing": Vector3(0, 0, 1), "parent": C4})
	b.resident("cheng", "cheng", Vector3(14.1, A, -2.3), {"anim": "work", "facing": Vector3(0, 0, 1), "parent": C4})
	b.resident("mover_a", "mover_a", Vector3(15.2, A, -1.8), {"anim": "work", "facing": Vector3(-1, 0, 0.3), "parent": C4})
	b.resident("mover_b", "mover_b", Vector3(9.7, A, 4.2), {"anim": "work", "facing": Vector3(0, 0, -1), "parent": C4})
	# and the old people who come out into the sun every morning
	b.resident("yamen_taichi", "ext_taichi", Vector3(12.0, A, -1.2), {"anim": "work", "facing": Vector3(0, 0, 1), "parent": C4})
	b.resident("yamen_bird", "ext_birdcage_man", Vector3(8.5, A, 1.65), {"facing": Vector3(0.3, 0, 1), "parent": C4})

	# elsewhere on the route, Chapter 4's moving
	var R := LevelBuilder.LEVEL_ROOF
	# Lau's clinic: the chair gone, a pale shape where it stood, the tools in boxes, his card inside the door
	b.box(4.3, 5.8, A, A + 0.004, -13.3, -11.7, c8(0xdfe6dc), {"surface": "floor", "parent": C4, "name": "ChairMark", "cast_shadow": false, "band": 0.0})
	PropKit.cardboard(b, 5.0, 5.8, A, A + 0.55, -14.7, -14.05, c8(0xa8834f), C4)
	PropKit.cardboard(b, 5.05, 5.75, A + 0.55, A + 0.95, -14.65, -14.1, c8(0x9c7a48), C4)
	b.add_obstacle(5.0, 5.8, -14.7, -14.05, A, "lauToolBoxes")
	b.card("res://assets/textures/props/card_lau.png", Vector3(1.7, A + 1.45, -9.02), Vector2(0.3, 0.18), Vector3(0, 0, -1), {"parent": C4, "name": "LauCard", "band": 0.0})
	b.ref("lauCard", Vector3(2.35, A, -9.5))
	b.ref("lauPacking", Vector3(4.8, A, -12.6))
	# the workshop, emptied: the tables' marks on the tiles, flattened cartons, one crate left
	for tz in [0.7, 2.4]:
		b.box(-6.3, -3.5, B, B + 0.004, tz, tz + 0.8, c8(0x7a8a88), {"surface": "tiles", "parent": C4, "name": "TableMark", "cast_shadow": false, "band": 1.0})
	b.box(-1.5, -0.3, B, B + 0.12, 3.1, 3.9, c8(0xa8834f), {"surface": "grain", "parent": C4, "name": "FlatCartons", "band": 1.0})
	b.box(-6.9, -6.5, B, B + 0.32, 3.3, 3.75, c8(0x3f6fa8), {"surface": "grain", "parent": C4, "name": "LastCrate", "band": 1.0})
	b.ref("kitWorkshop", Vector3(-3.4, B, 2.2))
	# Mrs. Wong's things, carried out onto the landing for her daughter to collect
	PropKit.cardboard(b, 11.3, 11.95, B, B + 0.6, -14.7, -14.1, c8(0xa8834f), C4)
	PropKit.cardboard(b, 11.35, 11.9, B + 0.6, B + 0.95, -14.6, -14.2, c8(0x9c7a48), C4)
	b.add_obstacle(11.3, 11.95, -14.7, -14.1, B, "wongBoxes")
	b.box(10.9, 11.3, B, B + 0.5, -13.6, -13.2, c8(0x6b4a30), {"surface": "wood", "parent": C4, "name": "TeaChest", "collide": true, "collide_y": B, "band": 1.0})
	b.ref("wongPacking", Vector3(11.3, B, -12.5))
	# the Chans' drying frame on the roof, half taken down: its poles laid on the roof
	for k in 3:
		b.box(-6.2, -3.0, R, R + 0.05, -10.4 + k * 0.12, -10.35 + k * 0.12, c8(0x8a8a86), {"surface": "metal", "parent": C4, "name": "FramePole", "band": 2.0})
	b.ref("chanRoof", Vector3(-4.4, R, -9.4))

	# the lane's gate: locked until Chapter 4, then left open
	var G13 := "ChapterProps/Ch1-3"
	var bar_z := 4.4
	while bar_z < 6.0:
		b.box(1.87, 1.93, A, A + 2.5, bar_z, bar_z + 0.03, c8(0x3a3a38), {"band": 0.0, "surface": "metal", "parent": G13, "name": "GateBar"})
		bar_z += 0.18
	b.add_obstacle(1.75, 2.05, 4.3, 6.0, A, "laneGateShut", "chapter:Ch1-3")
	var G47 := "ChapterProps/Ch4-7"
	# swung back against the lane's south wall
	for gx in [2.0, 2.3, 2.6, 2.9, 3.2, 3.5]:
		b.box(gx, gx + 0.03, A, A + 2.5, 5.86, 5.93, c8(0x3a3a38), {"band": 0.0, "surface": "metal", "parent": G47, "name": "GateBarOpen"})
	b.box(1.95, 3.55, A + 2.44, A + 2.5, 5.86, 5.93, c8(0x3a3a38), {"band": 0.0, "surface": "metal", "parent": G47, "name": "GateRail"})
	b.box(1.95, 3.55, A + 0.1, A + 0.16, 5.86, 5.93, c8(0x3a3a38), {"band": 0.0, "surface": "metal", "parent": G47, "name": "GateRail"})
