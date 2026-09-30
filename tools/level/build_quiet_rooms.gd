class_name BuildQuietRooms
extends RefCounted

## Chapter 5, Rooms Going Quiet: what has gone, and what is left where it was.
##
## The footbridge over the light well is taken away. Behind the stairwell at
## the foot of Lau's stairs, a metal shop that was always shuttered stands open
## and empty, a pegboard of painted tool shapes across it; behind the pegboard,
## where the shop's old sign used to lean, a narrow stair climbs to a door at
## the west end of the ledge, beside Mrs. Fong's. Her door is open on an empty
## room with a chalked address. Lau's clinic keeps its tubes, one box and the
## marks; Mrs. Wong's room keeps its table; the mahjong table is folded against
## the alcove wall; Mr. Kwok's shutter is down. Over the catwalk, the Chans'
## line is empty but for its pegs.
##
## The shells (the back shop, the stair, the stair head) are there on every
## day, shut until Chapter 5. Everything else sits under ChapterProps: Ch5 for
## the day's own things, Ch5-7 for what stays gone. No random draws here: the
## city after it is generated from the same numbers as before.

const A := LevelBuilder.LEVEL_A
const B := LevelBuilder.LEVEL_B

# the back shop, behind the stairwell's north wall (Level A)
const SHOP := [8.0, 11.0, -17.3, -15.3]
const SHOP_DOOR := [8.15, 9.35]
# its narrow stair along the north wall, rising east to the stair head
const STAIR_Z := [-17.3, -16.65]
const STAIR_X := [8.55, 10.95]
# the pegboard partition in front of it, open at its east end
const PEG_Z := -16.6
const PEG_X := [8.0, 10.3]
# the stair head (Level B), and its door onto the ledge's west end
const HEAD := [10.4, 11.7, -17.3, -15.3]
const HEAD_DOOR := [-17.3, -16.3]

const C5 := "ChapterProps/Ch5"
const C57 := "ChapterProps/Ch5-7"
const C14 := "ChapterProps/Ch1-4"


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	_back_shop(b)
	_stair_head(b)
	_footbridge_gone(b)
	_clothesline(b)
	_lau(b)
	_wong(b)
	_fong(b)
	_alcove(b)
	_kwok(b)
	_flat(b)


# ----------------------------------------------------------------------------- the back shop and its stair


static func _back_shop(b: LevelBuilder) -> void:
	var P := "Structure/LevelA/BackShop"
	# the stairwell's north wall is its south wall (with the doorway in it)
	b.room({"x0": SHOP[0], "x1": SHOP[1], "z0": SHOP[2], "z1": SHOP[3], "y": A, "h": 4.6, "name": "BackShop", "id": "backshop",
		"wall": c8(0x6f6a5e), "floor": c8(0x4a4640), "skip": ["s"], "parent": "Structure/LevelA", "wall_surface": "concrete",
		"floor_surface": "concrete"})
	b.add_floor(SHOP_DOOR[0], SHOP_DOOR[1], SHOP[3], -15.0, A, "backShopDoor")
	b.ref("backShopDoor", Vector3((SHOP_DOOR[0] + SHOP_DOOR[1]) / 2, A, -14.6))
	b.ref("backShop", Vector3(9.3, A, -15.9))

	# the narrow stair: steep steel treads on a stringer, up through the ceiling
	var steps := 12
	var run := (STAIR_X[1] - STAIR_X[0]) / steps
	var rise := (B - A) / steps
	for i in steps:
		var x0 := STAIR_X[0] + run * i
		var top := A + rise * (i + 1)
		b.box(x0, x0 + run + 0.04, top - 0.05, top, STAIR_Z[0] + 0.05, STAIR_Z[1] - 0.05, c8(0x5a5e5c),
			{"band": 0.0, "surface": "metal", "parent": P + "/Stair", "name": "Tread"})
		b.box(x0 + run - 0.01, x0 + run + 0.04, top - 0.05, top, STAIR_Z[0] + 0.05, STAIR_Z[1] - 0.05, c8(0xc9a23a),
			{"band": 0.0, "surface": "metal", "parent": P + "/Stair", "name": "Nosing", "cast_shadow": false})
	b.cylinder(Vector3(STAIR_X[0], A + 0.05, STAIR_Z[1] - 0.04), Vector3(STAIR_X[1], B, STAIR_Z[1] - 0.04), 0.035, b.surface("rust"),
		{"parent": P + "/Stair", "name": "Stringer", "tint": c8(0x3a3a38), "band": 0.0})
	b.cylinder(Vector3(STAIR_X[0], A + 0.95, STAIR_Z[1] - 0.02), Vector3(STAIR_X[1], B + 0.9, STAIR_Z[1] - 0.02), 0.02, b.surface("metal"),
		{"parent": P + "/Stair", "name": "Handrail", "tint": c8(0x4f7a5a), "band": 0.0})
	b.add_obstacle(STAIR_X[0] - 0.1, SHOP[1], STAIR_Z[0], STAIR_Z[1] + 0.05, A, "backStair")
	b.ref("backStairFoot", Vector3(10.6, A, -16.35))

	# the pegboard across the shop, floor to ceiling: from the front it hides
	# the stair completely; from either side the slot at its east end shows
	var board := c8(0x8a7a5c)
	b.box(PEG_X[0], PEG_X[1], A, A + 4.6, PEG_Z - 0.03, PEG_Z + 0.03, board,
		{"band": 0.0, "surface": "wood", "parent": P, "name": "Pegboard"})
	b.add_obstacle(PEG_X[0], PEG_X[1], PEG_Z - 0.05, PEG_Z + 0.08, A, "pegboard")
	# where each tool hung, its shape painted round it, so it went back in the same place
	var paint := c8(0xd8d2c0)
	var shapes := [[8.3, 8.36, 1.2, 1.75], [8.5, 8.9, 1.62, 1.68], [8.72, 8.77, 1.3, 1.62], [9.05, 9.1, 1.05, 1.7],
		[9.3, 9.8, 1.9, 1.96], [9.45, 9.5, 1.45, 1.9], [9.95, 10.0, 1.1, 1.8], [8.3, 8.8, 0.9, 0.96], [9.3, 9.36, 0.85, 1.3]]
	for sh in shapes:
		b.box(sh[0], sh[1], A + sh[2], A + sh[3], PEG_Z + 0.03, PEG_Z + 0.035, paint,
			{"band": 0.0, "surface": "grain", "parent": C57 + "/BackShop", "name": "ToolShape", "cast_shadow": false})
	# ...and on the other days, the tools themselves
	var steel := c8(0x6a6e70)
	for sh in shapes:
		b.box(sh[0] - 0.01, sh[1] + 0.01, A + sh[2] - 0.01, A + sh[3] + 0.01, PEG_Z + 0.03, PEG_Z + 0.06, steel,
			{"band": 0.0, "surface": "metal", "parent": C14 + "/BackShop", "name": "Tool", "cast_shadow": false})
	# the old shop sign, leaning across the slot where the stair goes up (gone by Chapter 5)
	var lean := b.box(10.35, 10.95, A, A + 2.3, PEG_Z - 0.04, PEG_Z + 0.02, c8(0x7a2e26),
		{"band": 0.0, "surface": "wood", "parent": C14 + "/BackShop", "name": "OldSign"})
	lean.rotation.x = -0.12
	b.add_obstacle(10.3, SHOP[1], PEG_Z - 0.3, PEG_Z + 0.1, A, "oldSign", "chapter:Ch1-4")

	# empty now: pale oblongs where the benches stood, oil in the grain, a bulb
	for mark in [[8.1, 9.9, -16.5, -15.85], [10.05, 10.9, -16.0, -15.4]]:
		b.box(mark[0], mark[1], A + 0.002, A + 0.006, mark[2], mark[3], c8(0x6a665a),
			{"band": 0.0, "surface": "concrete", "parent": C57 + "/BackShop", "name": "BenchMark", "cast_shadow": false})
	b.box(8.4, 9.2, A + 0.006, A + 0.01, -16.3, -15.9, Color.WHITE,
		{"material": _stain(b), "parent": C57 + "/BackShop", "name": "OilStain", "cast_shadow": false, "band": 0.0})
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(8.02, A + 1.8, -15.9), Vector2(0.36, 0.54), Vector3(1, 0, 0),
		{"parent": C57 + "/BackShop", "name": "Calendar", "band": 0.0})
	PropKit.bulb(b, Vector3(9.4, A + 3.4, -15.9), A + 4.6, P)

	# the stairwell side: a steel shutter down over the doorway on every day
	# until Chapter 5; then rolled up into its box, the padlock hanging open
	var face := -14.97
	var SH := C14 + "/BackShopShutter"
	b.box(SHOP_DOOR[0] - 0.05, SHOP_DOOR[1] + 0.05, A, A + 2.6, face - 0.02, face + 0.02, c8(0x7a8078),
		{"band": 0.0, "surface": "metal", "parent": SH, "name": "Shutter"})
	var sy := 0.2
	while sy < 2.55:
		b.box(SHOP_DOOR[0] - 0.05, SHOP_DOOR[1] + 0.05, A + sy, A + sy + 0.02, face + 0.02, face + 0.03, c8(0x5a605a),
			{"band": 0.0, "surface": "metal", "parent": SH, "name": "Slat", "cast_shadow": false})
		sy += 0.16
	b.box(SHOP_DOOR[0] - 0.05, SHOP_DOOR[1] + 0.05, A, A + 0.1, face + 0.02, face + 0.05, c8(0x4a4e4a),
		{"band": 0.0, "surface": "metal", "parent": SH, "name": "BottomBar"})
	b.box(8.7, 8.82, A + 0.12, A + 0.26, face + 0.05, face + 0.09, c8(0xc9a55a), {"band": 0.0, "surface": "metal", "parent": SH, "name": "Padlock"})
	b.add_obstacle(SHOP_DOOR[0], SHOP_DOOR[1], SHOP[3], -14.9, A, "backShopShut", "chapter:Ch1-4")
	var RO := C57 + "/BackShopShutter"
	b.box(SHOP_DOOR[0] - 0.1, SHOP_DOOR[1] + 0.1, A + 2.45, A + 2.72, face - 0.02, face + 0.2, c8(0x6a706a),
		{"band": 0.0, "surface": "metal", "parent": RO, "name": "ShutterBox"})
	b.box(SHOP_DOOR[0] - 0.05, SHOP_DOOR[1] + 0.05, A + 2.38, A + 2.45, face + 0.02, face + 0.06, c8(0x4a4e4a),
		{"band": 0.0, "surface": "metal", "parent": RO, "name": "BottomBar"})
	b.box(8.72, 8.8, A + 2.2, A + 2.36, face + 0.06, face + 0.1, c8(0xc9a55a), {"band": 0.0, "surface": "metal", "parent": RO, "name": "Padlock"})


static func _stair_head(b: LevelBuilder) -> void:
	var P := "Structure/LevelB/StairHead"
	# a box of a room behind the landing's north wall: the stair comes up through
	# its floor, and its door opens onto the ledge beside Mrs. Fong's
	b.room({"x0": HEAD[0], "x1": HEAD[1], "z0": HEAD[2], "z1": HEAD[3], "y": B, "name": "StairHead", "id": "stairhead",
		"wall": c8(0x74705f), "floor": c8(0x4e4a42), "skip": ["s", "n"], "open": {"e": [HEAD_DOOR]}, "parent": "Structure/LevelB",
		"wall_surface": "concrete", "floor_hole": [HEAD[0], STAIR_X[1] + 0.02, HEAD[2], STAIR_Z[1]]})
	# its north wall stops short of Mrs. Fong's, whose own wall carries on from there
	b.box(HEAD[0] - 0.3, HEAD[1], B, B + 4.2, HEAD[2] - 0.3, HEAD[2], c8(0x74705f),
		{"band": 1.0, "surface": "concrete", "parent": P, "name": "WallN", "fadeable": true, "room": "stairhead"})
	b.add_obstacle(HEAD[0], STAIR_X[1] + 0.05, HEAD[2], STAIR_Z[1] + 0.05, B, "stairHeadHole")
	# a rail round the top of the flight
	var rail := c8(0x4f7a5a)
	b.box(HEAD[0], STAIR_X[1] + 0.05, B + 0.93, B + 1.0, STAIR_Z[1] + 0.02, STAIR_Z[1] + 0.08, rail,
		{"band": 1.0, "surface": "metal", "parent": P, "name": "Rail"})
	b.box(STAIR_X[1] + 0.02, STAIR_X[1] + 0.08, B, B + 1.0, STAIR_Z[1] + 0.02, STAIR_Z[1] + 0.08, rail,
		{"band": 1.0, "surface": "metal", "parent": P, "name": "RailPost"})
	PropKit.bulb(b, Vector3(11.1, B + 3.0, -16.3), B + 4.2, P)
	# the step out onto the ledge
	b.add_floor(HEAD[1], 12.0, HEAD_DOOR[0], HEAD_DOOR[1], B, "stairHeadDoor")
	b.ref("backStairTop", Vector3(11.25, B, -16.75))
	# the door: shut (and the ledge's rail across it) until Chapter 5, then left open
	BuildInteriors.panel_door_z(b, HEAD_DOOR[0], HEAD_DOOR[1], B, 2.3, HEAD[1] + 0.2, c8(0x5a6a60), C14 + "/StairHeadDoor", 1.0, "StairHeadDoor")
	b.add_obstacle(HEAD[1], 12.0, HEAD_DOOR[0], HEAD_DOOR[1], B, "stairHeadShut", "chapter:Ch1-4")
	# open: swung out on its north hinges, flat against the outside of Mrs. Fong's wall
	b.box(12.0, 13.0, B, B + 2.3, HEAD_DOOR[0] + 0.02, HEAD_DOOR[0] + 0.06, c8(0x5a6a60),
		{"band": 1.0, "surface": "metal", "parent": C57 + "/StairHeadDoor", "name": "Leaf", "fadeable": true})


# ----------------------------------------------------------------------------- the footbridge, gone


static func _footbridge_gone(b: LevelBuilder) -> void:
	var bx: Array = BuildLightWell.BRIDGE_X
	var near := -13.0
	var far: float = BuildLightWell.LEDGE_Z[1]
	var G := C57 + "/FootbridgeGone"
	# the stringers cut off at each edge with a torch, the stubs left in the brackets
	for sx in [bx[0] + 0.08, bx[1] - 0.16]:
		b.box(sx, sx + 0.08, B - 0.22, B - 0.06, near - 0.18, near + 0.02, c8(0x4a4a48), {"band": 1.0, "surface": "rust", "parent": G, "name": "Stub"})
		b.box(sx, sx + 0.08, B - 0.22, B - 0.06, far - 0.02, far + 0.16, c8(0x4a4a48), {"band": 1.0, "surface": "rust", "parent": G, "name": "Stub"})
	# a batten nailed across each gap in the rails
	for z in [near - 0.05, far + 0.05]:
		b.box(bx[0] - 0.1, bx[1] + 0.1, B + 0.9, B + 0.98, z - 0.02, z + 0.02, c8(0x8a6a48), {"band": 1.0, "surface": "wood", "parent": G, "name": "Batten"})
		b.box(bx[0] - 0.1, bx[1] + 0.1, B + 0.45, B + 0.52, z - 0.02, z + 0.02, c8(0x7a5c3e), {"band": 1.0, "surface": "wood", "parent": G, "name": "Batten"})
	b.ref("footbridgeGap", Vector3((bx[0] + bx[1]) / 2, B, near + 0.45))


# ----------------------------------------------------------------------------- the Chans' line


static func _clothesline(b: LevelBuilder) -> void:
	var L := C5 + "/ChansLine"
	var x := 16.0
	var y := B + 2.6
	# the poles at either rail, and the line between them, empty
	for z in [-13.05, -10.95]:
		b.box(x - 0.03, x + 0.03, B + 1.0, y + 0.1, z - 0.03, z + 0.03, c8(0x9a8a60), {"band": 1.0, "surface": "wood", "parent": L, "name": "Pole"})
	b.box(x - 0.015, x + 0.015, y, y + 0.03, -13.05, -10.95, c8(0x222222), {"band": 1.0, "surface": "grain", "parent": L, "name": "Line", "cast_shadow": false})
	# the pegs still on it where the washing was, each a pair of little jaws
	var pegs := [-12.72, -12.5, -12.08, -11.86, -11.46, -11.22]
	for pz in pegs:
		b.box(x - 0.02, x + 0.02, y - 0.07, y + 0.04, pz - 0.012, pz + 0.012, c8(0xd8b04a), {"band": 1.0, "surface": "wood", "parent": L, "name": "Peg", "cast_shadow": false})
	# one more, loose: it falls
	var loose := Node3D.new()
	loose.name = "LoosePeg"
	loose.position = Vector3(x, y - 0.015, -12.28)
	b.attach(loose, b.group(L))
	b.tag(loose, 1.0, false, {"dynamic": true})
	var jaw := b.box(-0.02, 0.02, -0.055, 0.055, -0.012, 0.012, c8(0xd8b04a), {"surface": "wood", "parent_node": loose, "name": "Peg", "cast_shadow": false})
	jaw.remove_meta("band")
	# the frame half taken down: the crossbar off, laid along the grating
	b.box(14.6, 16.8, B + 0.0, B + 0.05, -11.25, -11.2, c8(0x9a8a60), {"band": 1.0, "surface": "wood", "parent": L, "name": "Crossbar"})
	b.ref("chansLine", Vector3(x, B, -12.0))


# ----------------------------------------------------------------------------- Lau's, Wong's, Fong's


static func _lau(b: LevelBuilder) -> void:
	var G := C57 + "/Clinic"
	# a paler square on the tiles where his certificate hung, and one where the calendar was
	b.box(0.0, 0.012, A + 1.32, A + 2.06, -12.48, -11.52, c8(0xc8dccf), {"band": 0.0, "surface": "tiles", "parent": G, "name": "PaleSquare", "cast_shadow": false})
	b.box(7.988, 8.0, A + 1.46, A + 2.14, -10.62, -10.18, c8(0xc8dccf), {"band": 0.0, "surface": "tiles", "parent": G, "name": "PaleSquare", "cast_shadow": false})
	# the tape still on the wall inside the door where his card was
	for tx in [1.56, 1.84]:
		b.box(tx - 0.03, tx + 0.03, A + 1.52, A + 1.56, -9.02, -9.01, c8(0xe8dca8), {"band": 0.0, "surface": "grain", "parent": G, "name": "Tape", "cast_shadow": false})
	# one wire, cut, hanging from the ceiling where the chair's lamp was fed
	b.cylinder(Vector3(5.5, A + 4.15, -12.6), Vector3(5.45, A + 3.3, -12.55), 0.008, b.surface("grain"),
		{"parent": G, "name": "Wire", "tint": c8(0x1c1c1e), "band": 0.0, "cast_shadow": false})
	b.ref("lauPale", Vector3(0.9, A, -12.0))


static func _wong(b: LevelBuilder) -> void:
	var G := C57 + "/Wong"
	# the bed stripped to its boards
	b.box(28.6, 31, B, B + 0.35, -9.8, -8, c8(0x8a6f5a), {"band": 1.0, "surface": "wood", "parent": G, "name": "BedFrame"})
	var sz := -9.7
	while sz < -8.1:
		b.box(28.7, 30.9, B + 0.35, B + 0.38, sz, sz + 0.2, c8(0xa08466), {"band": 1.0, "surface": "wood", "parent": G, "name": "BedBoard", "cast_shadow": false})
		sz += 0.26
	b.box(30.94, 31, B, B + 0.95, -9.8, -8, c8(0x8a6f5a).darkened(0.1), {"band": 1.0, "surface": "wood", "parent": G, "name": "Headboard"})
	# where the altar stood: the wall behind it clean, and smoke-dark round it
	b.box(29.85, 30.95, B + 0.2, B + 1.35, -15.99, -15.97, c8(0xc0a8a2), {"band": 1.0, "surface": "plaster", "parent": G, "name": "AltarMark", "cast_shadow": false})
	# on the table: an envelope (today), and later the bowl Mei brings back
	var env := b.box(25.3, 25.62, B + 0.5, B + 0.506, -15.05, -14.85, c8(0xf0e8d4), {"band": 1.0, "surface": "grain", "parent": C5 + "/WongNote", "name": "Envelope"})
	env.rotation.y = 0.2
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.09
	bowl.bottom_radius = 0.055
	bowl.height = 0.07
	bowl.radial_segments = 16
	b.piece(bowl, Vector3(25.85, B + 0.535, -15.1), b.surface("grain"), {"parent": C5 + "/WongBowl", "name": "Bowl", "tint": c8(0xe6ecef), "band": 1.0})
	b.ref("wongTable", Vector3(25.6, B, -14.0))


static func _fong(b: LevelBuilder) -> void:
	var G := C57 + "/Fong"
	var face: float = BuildLightWell.LEDGE_Z[0]
	var d: Array = BuildLightWell.FONG_DOOR
	# the door's frame, and the door swung back into the empty room
	var frame := c8(0x3a3028)
	for fx in [[d[0] - 0.07, d[0]], [d[1], d[1] + 0.07]]:
		b.box(fx[0], fx[1], B, B + 2.27, face, face + 0.08, frame, {"band": 1.0, "surface": "wood", "parent": G, "name": "DoorFrame", "fadeable": true})
	b.box(d[0] - 0.07, d[1] + 0.07, B + 2.2, B + 2.27, face, face + 0.08, frame, {"band": 1.0, "surface": "wood", "parent": G, "name": "DoorFrame", "fadeable": true})
	var hinge := Node3D.new()
	hinge.name = "FongDoorOpen"
	hinge.position = Vector3(d[0], B, BuildLightWell.FONG[3])
	hinge.rotation.y = deg_to_rad(100)
	b.attach(hinge, b.group(G))
	b.tag(hinge, 1.0)
	var leaf := b.box(0.0, 1.0, 0.0, 2.2, -0.04, 0.0, c8(0x8a4a3a), {"surface": "wood", "parent_node": hinge, "name": "Leaf"})
	leaf.remove_meta("band")
	# chalked on the wall outside, the way everyone did: who, and where to
	b.card("res://assets/textures/props/chalk_fong.png", Vector3(13.45, B + 1.45, face + 0.01), Vector2(0.9, 0.45), Vector3(0, 0, 1),
		{"parent": G, "name": "Chalk", "band": 1.0, "fadeable": true})
	b.ref("fongChalk", Vector3(13.45, B, -16.8))
	# inside: the clean square where a shrine hung, its nail still in the wall
	b.box(16.4, 17.0, B + 1.5, B + 2.2, -21.49, -21.47, c8(0xb0a48e), {"band": 1.0, "surface": "plaster", "parent": G, "name": "ShrineMark", "cast_shadow": false})
	b.box(16.68, 16.72, B + 2.1, B + 2.14, -21.47, -21.4, c8(0x3a3a38), {"band": 1.0, "surface": "metal", "parent": G, "name": "Nail", "cast_shadow": false})
	# the stool Mei brings back, folded against the wall inside the door (shown when she leaves it)
	var st := C5 + "/FongStool"
	var seat := b.box(13.55, 13.9, B + 0.02, B + 0.62, -17.66, -17.6, c8(0x3f6fa8), {"band": 1.0, "surface": "grain", "parent": st, "name": "StoolSeat"})
	seat.rotation.x = 0.12
	for lx in [13.58, 13.84]:
		b.box(lx, lx + 0.03, B, B + 0.58, -17.72, -17.69, c8(0x2f5a88), {"band": 1.0, "surface": "grain", "parent": st, "name": "StoolLeg"})
	b.ref("fongInside", Vector3(14.8, B, -18.4))


# ----------------------------------------------------------------------------- the alcove, the stall, the flat


static func _alcove(b: LevelBuilder) -> void:
	var G := C57 + "/Alcove"
	# the mahjong table folded flat and stood against the wall, its legs tucked in
	var top := b.box(-3.97, -3.9, A + 0.05, A + 1.35, 1.6, 2.9, c8(0x5a3a26), {"band": 0.0, "surface": "wood", "parent": G, "name": "FoldedTable"})
	top.rotation.z = -0.08
	b.box(-3.9, -3.86, A + 0.05, A + 1.3, 1.63, 2.87, c8(0x2e5a3a), {"band": 0.0, "surface": "fabric", "parent": G, "name": "FoldedCloth", "cast_shadow": false})
	b.add_obstacle(-4.0, -3.75, 1.55, 2.95, A, "foldedTable", "chapter:Ch5-7")
	# a carton with a biscuit tin on it: the tiles go in the tin
	PropKit.cardboard(b, -1.3, -0.7, A, A + 0.5, 3.2, 3.8, c8(0xa8834f), G, "s")
	b.add_obstacle(-1.3, -0.7, 3.2, 3.8, A, "alcoveBox", "chapter:Ch5-7")
	b.cylinder(Vector3(-1.0, A + 0.5, 3.5), Vector3(-1.0, A + 0.64, 3.5), 0.14, b.surface("metal"),
		{"parent": G, "name": "Tin", "tint": c8(0xb8392e), "band": 0.0})
	b.ref("mahjongTin", Vector3(-1.0, A, 3.0))


static func _kwok(b: LevelBuilder) -> void:
	var G := C57 + "/Stall"
	# Mr. Kwok's shutter down over the stall's front
	b.box(1.96, 2.0, A, A + 2.5, -6.0, -4.0, c8(0x7a8078), {"band": 0.0, "surface": "metal", "parent": G, "name": "Shutter"})
	var sy := 0.2
	while sy < 2.45:
		b.box(2.0, 2.01, A + sy, A + sy + 0.02, -6.0, -4.0, c8(0x5a605a), {"band": 0.0, "surface": "metal", "parent": G, "name": "Slat", "cast_shadow": false})
		sy += 0.16
	b.box(2.0, 2.04, A + 0.12, A + 0.26, -5.1, -4.98, c8(0xc9a55a), {"band": 0.0, "surface": "metal", "parent": G, "name": "Padlock"})
	b.add_obstacle(1.9, 2.05, -6.0, -4.0, A, "stallShut", "chapter:Ch5-7")
	b.ref("kwokPacking", Vector3(3.2, A, -6.5))


static func _flat(b: LevelBuilder) -> void:
	var G := C5 + "/Borrowed"
	# Mum's small open box of other people's things, on the floor by the table
	PropKit.cardboard(b, -10.9, -10.35, A, A + 0.36, -1.95, -1.45, c8(0xa8834f), G, "s")
	b.add_obstacle(-10.9, -10.35, -1.95, -1.45, A, "borrowedBox", "chapter:Ch5")
	var I := G + "/Items"
	# a folded stool standing up in it, a birdseed tin, the coiled rope, a bowl, a screwdriver, a tile
	b.box(-10.85, -10.8, A + 0.2, A + 0.62, -1.9, -1.55, c8(0x3f6fa8), {"band": 0.0, "surface": "grain", "parent": I, "name": "Stool"})
	b.cylinder(Vector3(-10.5, A + 0.2, -1.8), Vector3(-10.5, A + 0.46, -1.8), 0.07, b.surface("metal"), {"parent": I, "name": "SeedTin", "tint": c8(0xc9a55a), "band": 0.0})
	b.cylinder(Vector3(-10.62, A + 0.36, -1.58), Vector3(-10.62, A + 0.42, -1.58), 0.11, b.surface("fabric"), {"parent": I, "name": "Rope", "tint": c8(0xb09a6a), "band": 0.0})
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.075
	bowl.bottom_radius = 0.045
	bowl.height = 0.06
	bowl.radial_segments = 14
	b.piece(bowl, Vector3(-10.45, A + 0.39, -1.62), b.surface("grain"), {"parent": I, "name": "Bowl", "tint": c8(0xe6ecef), "band": 0.0})
	b.cylinder(Vector3(-10.75, A + 0.4, -1.7), Vector3(-10.58, A + 0.44, -1.86), 0.012, b.surface("metal"), {"parent": I, "name": "Screwdriver", "tint": c8(0xb8392e), "band": 0.0})
	b.box(-10.72, -10.66, A + 0.37, A + 0.41, -1.52, -1.48, c8(0xece6d4), {"band": 0.0, "surface": "grain", "parent": I, "name": "Tile", "cast_shadow": false})
	b.ref("borrowedBox", Vector3(-10.6, A, -1.1))


static func _stain(b: LevelBuilder) -> StandardMaterial3D:
	var m := b.card_material("res://assets/textures/props/stain_b.png")
	var d := m.duplicate() as StandardMaterial3D
	d.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return d
