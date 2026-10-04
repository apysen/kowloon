class_name BuildWayOut
extends RefCounted

## Chapter 7, The Way Out: the last day, and the ways to the yamen from memory.
##
## The flat nearly empty: Grandfather's chair, one suitcase, one box, the
## paler squares where things hung. Three ways to the yamen's courtyard: the
## lane (as in Chapter 4); along the hall, past Kwok's shut stall, and through
## the side passage just after it into the strip beside the yamen hall (shut on
## every other day); or down from the roof by Mr. Ng's old ladder into the same
## strip. The way out is the yamen's mouth, onto Lung Chun Road.
##
## No random draws here.

const A := LevelBuilder.LEVEL_A
const R := LevelBuilder.LEVEL_ROOF
const PASSAGE := [4.0, 5.5, -7.5, -6.5]      # off the corridor, just past Kwok's stall
const STRIP := [5.5, 6.45, -7.5, -2.2]       # beside the yamen hall, down into the courtyard
const C7 := "ChapterProps/Ch7"


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	_flat(b)
	_kwoks_turn(b)
	_ng_ladder(b)
	b.ref("exitLine", Vector3(8.6, A, 5.5))
	b.ref("yamenSeat", Vector3(9.0, A, 0.6))


static func _flat(b: LevelBuilder) -> void:
	var G := C7 + "/Flat"
	# his chair, where it always was
	var wood := c8(0x6b4a30)
	var cx := -12.8
	var cz := -0.15
	ObjectKit.chair(b, cx, cz, A, Vector3(1, 0, 0), wood, G, {"band": 0.0})
	b.add_obstacle(cx - 0.3, cx + 0.3, cz - 0.3, cz + 0.3, A, "gfChair", "chapter:Ch7")
	# one suitcase by the door, one box
	# a hard case stood on its end, its handle on top, straps buckled round it
	ModelKit.box(b, -7.2, -6.5, A, A + 0.62, 0.7, 0.95, c8(0x5a3a2a), {"band": 0.0, "surface": "grain", "parent": G, "name": "Suitcase", "radius": 0.03})
	ModelKit.box(b, -7.202, -6.498, A, A + 0.62, 0.818, 0.832, c8(0x3a2418), {"band": 0.0, "surface": "grain", "parent": G, "name": "SuitcaseSeam", "radius": 0.004, "cast_shadow": false})
	for sx in [-7.05, -6.65]:
		ModelKit.box(b, sx - 0.02, sx + 0.02, A - 0.002, A + 0.622, 0.698, 0.952, c8(0x8a6a48), {"band": 0.0, "surface": "fabric", "parent": G, "name": "Strap", "radius": 0.004, "cast_shadow": false})
	ModelKit.place(b, ModelKit.tube([Vector3(-0.07, 0, 0), Vector3(-0.06, 0.045, 0), Vector3(0.06, 0.045, 0), Vector3(0.07, 0, 0)], 0.011, 0.025, 8), Vector3(-6.85, A + 0.62, 0.825), "fabric", c8(0x2a2a2a),
		{"band": 0.0, "parent": G, "name": "Handle", "cast_shadow": false})
	b.add_obstacle(-7.25, -6.45, 0.65, 1.0, A, "suitcase", "chapter:Ch7")
	PropKit.cardboard(b, -10.2, -9.5, A, A + 0.55, 3.2, 3.9, c8(0xa8834f), G, "s")
	b.add_obstacle(-10.2, -9.5, 3.2, 3.9, A, "lastBox", "chapter:Ch7")
	# where things hung: the photograph, the calendar, the clock; the shelf's shadow
	var pale := c8(0xb4b196)
	for m in [[-10.78, -10.32, 1.42, 1.78], [-9.44, -8.96, 1.44, 2.16], [-8.62, -8.28, 2.48, 2.87]]:
		b.box(m[0], m[1], A + m[2], A + m[3], -3.995, -3.985, pale, {"band": 0.0, "surface": "plaster", "parent": G, "name": "Mark", "cast_shadow": false})
	b.box(-13.995, -13.985, A, A + 1.5, -2.2, -0.4, pale, {"band": 0.0, "surface": "plaster", "parent": G, "name": "Mark", "cast_shadow": false})
	b.ref("suitcase", Vector3(-7.4, A, 1.3))


static func _kwoks_turn(b: LevelBuilder) -> void:
	var P := "Structure/LevelA/KwoksTurn"
	var wall := c8(0x77705e)
	var o := {"band": 0.0, "surface": "plaster", "parent": P, "fadeable": true}
	b.add_floor(PASSAGE[0], PASSAGE[1], PASSAGE[2], PASSAGE[3], A, "kwoksTurn")
	b.add_floor(STRIP[0], STRIP[1], STRIP[2], STRIP[3], A, "hallStrip")
	b.box(PASSAGE[0] + 0.3, STRIP[1], A - 0.3, A, PASSAGE[2], PASSAGE[3], c8(0x4a463e), {"band": 0.0, "surface": "concrete", "parent": P, "name": "Floor", "is_floor": true})
	b.box(STRIP[0], STRIP[1], A - 0.3, A, PASSAGE[3], -3.0, c8(0x4e4a42), {"band": 0.0, "surface": "concrete", "parent": P, "name": "Floor", "is_floor": true})
	# its walls: north, the passage's south side, and the strip's west side
	b.box(PASSAGE[0] + 0.3, STRIP[1], A, A + 4.2, PASSAGE[2] - 0.3, PASSAGE[2], wall, o.merged({"name": "WallN"}))
	b.box(PASSAGE[0] + 0.3, STRIP[0], A, A + 4.2, PASSAGE[3], PASSAGE[3] + 0.3, wall, o.merged({"name": "WallS"}))
	# the strip's west side is the next building's wall, all the way up to the roofs
	b.box(STRIP[0] - 0.3, STRIP[0], A, R + 0.9, PASSAGE[3], STRIP[3], wall, o.merged({"name": "WallW"}))
	PropKit.bulb(b, Vector3(5.0, A + 2.9, -7.0), A + 4.2, P)
	b.ref("kwoksTurn", Vector3(4.6, A, -7.0))
	# shut on every other day: a steel door across it from the corridor
	var D := "ChapterProps/Ch1-6/KwoksTurnDoor"
	BuildInteriors.panel_door_z(b, PASSAGE[2], PASSAGE[3], A, 2.3, PASSAGE[0] - 0.02, c8(0x5a6a60), D, 0.0, "SideDoor")
	b.add_obstacle(PASSAGE[0], PASSAGE[0] + 0.35, PASSAGE[2], PASSAGE[3], A, "kwoksTurnShut", "chapter:Ch1-6")
	# and from the courtyard, the strip's mouth closed off with a stack of the yamen's chairs
	var S := "ChapterProps/Ch1-6/StripStack"
	for k in 4:
		# folding chairs, folded flat and stacked on their sides
		var y0 := A + k * 0.3
		ModelKit.box(b, STRIP[0] + 0.05, STRIP[1] - 0.05, y0 + 0.02, y0 + 0.26, -3.6, -3.1, c8(0x3f6fa8), {"band": 0.0, "surface": "metal", "parent": S, "name": "StackedChair", "radius": 0.02})
		for z in [-3.58, -3.12]:
			ModelKit.box(b, STRIP[0] + 0.03, STRIP[1] - 0.03, y0, y0 + 0.28, z - 0.012, z + 0.012, c8(0x5a5a58), {"band": 0.0, "surface": "metal", "parent": S, "name": "ChairFrame", "radius": 0.01})
	b.add_obstacle(STRIP[0], STRIP[1], -3.7, -3.0, A, "stripStack", "chapter:Ch1-6")


static func _ng_ladder(b: LevelBuilder) -> void:
	# Mr. Ng's way down to the yamen when the birds were young: a steel ladder
	# fixed to the building's south face, from the roof to the strip
	var L := C7 + "/NgLadder"
	var steel := c8(0x3a3a38)
	var face := STRIP[0]
	for lz in [-6.4, -6.0]:
		b.box(face, face + 0.04, A + 0.2, R + 1.1, lz - 0.02, lz + 0.02, steel, {"band": 0.0, "surface": "rust", "parent": L, "name": "LadderRail"})
	var ry := A + 0.4
	while ry < R + 1.0:
		b.box(face + 0.005, face + 0.035, ry, ry + 0.03, -6.4, -6.0, steel, {"band": 0.0, "surface": "rust", "parent": L, "name": "Rung", "cast_shadow": false})
		ry += 0.35
	b.ref("ngLadderFoot", Vector3(5.85, A, -5.8))
	b.ref("ngLadderTop", Vector3(5.6, R, -6.8))
