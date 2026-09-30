class_name BuildSideQuests
extends RefCounted

## What the optional quests need in the level, each kept to the day it's on
## (ChapterProps) so the main story's routes are the same without them.
##
##   OQ03, Auntie Fong's sign: her old shop's board, strung across the slot
##   behind Chiu's workshop between the workshop's roof and the neighbours'
##   balcony, bolted at each end; the steel ladder up the lane's south wall
##   that is the other way onto the balcony; Mrs. Fong herself, out on her
##   ledge (Chapter 4). From Chapter 5 only the two posts are left.
##
## No random draws here: the city after it is generated from the same numbers.

const A := LevelBuilder.LEVEL_A
const R := BuildWorkshop.ROOF_Y

const SIGN_X := -1.2                   # where the board crosses the slot
const SIGN_Z := [4.1, 5.9]
const LADDER_X := [-0.45, -0.05]       # the fixed ladder up the lane's south wall


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	_fong_sign(b)


# ----------------------------------------------------------------------------- OQ03, Auntie Fong's sign


static func _fong_sign(b: LevelBuilder) -> void:
	var steel := c8(0x3a3a38)
	# the posts: one on the workshop roof's parapet, one on the balcony's edge.
	# They stay after the board has come down: a landmark with nothing on it.
	for g in ["ChapterProps/Ch1-4/FongSign", "ChapterProps/Ch5-7/FongSignPosts"]:
		for pz in [BuildWorkshop.WS[3] - 0.06, BuildWorkshop.BALCONY[2] + 0.02]:
			b.box(SIGN_X - 0.05, SIGN_X + 0.05, R, R + 1.65, pz - 0.05, pz + 0.05, steel, {"band": 1.0, "surface": "rust", "parent": g, "name": "SignPost"})
	# the board, painted both sides, bolted to each post top and bottom
	var G := "ChapterProps/Ch1-4/FongSign"
	b.box(SIGN_X - 0.03, SIGN_X + 0.03, R + 0.45, R + 1.5, SIGN_Z[0], SIGN_Z[1], c8(0x5a2a22), {"band": 1.0, "surface": "wood", "parent": G, "name": "SignBoard"})
	for sgn in [-1.0, 1.0]:
		b.card("res://assets/textures/props/sign_fong.png", Vector3(SIGN_X + sgn * 0.035, R + 0.975, (SIGN_Z[0] + SIGN_Z[1]) / 2), Vector2(1.72, 1.02), Vector3(sgn, 0, 0),
			{"parent": G, "name": "SignFace", "band": 1.0})
	for bz in [SIGN_Z[0] - 0.02, SIGN_Z[1] + 0.02]:
		for by in [R + 0.55, R + 1.35]:
			b.box(SIGN_X - 0.08, SIGN_X + 0.08, by, by + 0.08, bz - 0.04, bz + 0.04, c8(0xa8894a), {"band": 1.0, "surface": "metal", "parent": G, "name": "Bolt", "cast_shadow": false})
	b.ref("fongBoltRoof", Vector3(SIGN_X, R, 3.5))
	b.ref("fongBoltBalcony", Vector3(SIGN_X, R, 6.45))
	# once it's down (Chapter 4): leaning against the lane wall below, where it came to rest
	var D := "ChapterProps/Ch4/FongSignDown"
	var down := b.box(-2.3, -2.24, A, A + 1.05, 5.5, 5.95, c8(0x5a2a22), {"band": 0.0, "surface": "wood", "parent": D, "name": "SignBoard"})
	down.rotation.x = 0.0
	b.card("res://assets/textures/props/sign_fong.png", Vector3(-2.2, A + 0.52, 5.7), Vector2(0.9, 0.5), Vector3(1, 0, 0),
		{"parent": D, "name": "SignFace", "band": 0.0})
	b.box(-2.4, -0.6, A, A + 1.05, 5.94, 5.98, c8(0x5a2a22), {"band": 0.0, "surface": "wood", "parent": D, "name": "SignBack"})
	b.ref("fongSignDown", Vector3(-1.5, A, 5.2))

	# the fixed steel ladder up the lane's south wall to the balcony: its face is
	# only seen looking back from the north (from Chapter 4 on; before, it's
	# behind the neighbours' stacked crates, and nobody needs it)
	var L := "ChapterProps/Ch4-7/LaneLadder"
	var face := BuildWorkshop.BALCONY[2] - 0.05
	for lx in LADDER_X:
		b.box(lx - 0.02, lx + 0.02, A + 0.2, R + 1.0, face - 0.04, face, steel, {"band": 0.0, "surface": "rust", "parent": L, "name": "LadderRail"})
	var ry := A + 0.4
	while ry < R + 0.9:
		b.box(LADDER_X[0], LADDER_X[1], ry, ry + 0.03, face - 0.035, face - 0.005, steel, {"band": 0.0, "surface": "rust", "parent": L, "name": "Rung", "cast_shadow": false})
		ry += 0.3
	b.ref("laneLadder", Vector3((LADDER_X[0] + LADDER_X[1]) / 2, A, 5.55))
	b.ref("ladderTop", Vector3((LADDER_X[0] + LADDER_X[1]) / 2, R, 6.45))

	# Mrs. Fong, out on her ledge with her radio
	b.resident("fong", "ext_plant_lady", Vector3(13.4, LevelBuilder.LEVEL_B, -16.75), {"facing": Vector3(0.3, 0, 1), "parent": "ChapterProps/Ch4"})
