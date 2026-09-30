class_name BuildSideQuests
extends RefCounted

## What the optional quests need in the level, each kept to the day it's on
## (ChapterProps) so the main story's routes are the same without them.
##
##   OQ01, Mr. Kwok's back page: a neighbour's little balcony in the light
##   well's corner, off a door halfway up the stairs by Lau's, under a striped
##   awning; from the catwalk the page seems to lie on the awning (Chapter 2).
##   OQ04, the last mahjong tile: the crack at the foot of the alcove's wall,
##   and where it comes out in the lane, behind a stack of crates (Chapter 2).
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
	_well_balcony(b)
	_mahjong_crack(b)


# ----------------------------------------------------------------------------- OQ01, Mr. Kwok's back page


const WELL_BALC := [10.8, 13.4, -14.9, -14.15]
const WELL_BALC_Y := 1.75


static func _well_balcony(b: LevelBuilder) -> void:
	var Y := WELL_BALC_Y
	var P := "Structure/LightWell/Balcony"
	var o := {"band": 0.0, "parent": P}
	# a short slab out of the wall under the landing, into the well's corner
	b.add_floor(WELL_BALC[0], WELL_BALC[1], WELL_BALC[2], WELL_BALC[3], Y, "wellBalcony")
	b.box(WELL_BALC[0], WELL_BALC[1], Y - 0.2, Y, WELL_BALC[2], WELL_BALC[3], c8(0x7e7a70), o.merged({"surface": "concrete", "name": "Slab"}))
	for bx in [11.9, 13.0]:
		b.box(bx, bx + 0.06, Y - 0.7, Y - 0.2, WELL_BALC[2] + 0.05, WELL_BALC[2] + 0.11, c8(0x4a4a48), o.merged({"surface": "rust", "name": "Bracket"}))
	var rail := c8(0x6a7a70)
	b.box(WELL_BALC[1] - 0.05, WELL_BALC[1], Y, Y + 0.95, WELL_BALC[2], WELL_BALC[3], rail, o.merged({"surface": "metal", "name": "Rail"}))
	b.box(12.0, WELL_BALC[1], Y + 0.9, Y + 0.95, WELL_BALC[3] - 0.05, WELL_BALC[3], rail, o.merged({"surface": "metal", "name": "Rail"}))
	for px in [12.0, 12.7, 13.35]:
		b.box(px, px + 0.05, Y, Y + 0.95, WELL_BALC[3] - 0.05, WELL_BALC[3], rail, o.merged({"surface": "metal", "name": "RailPost"}))
	# a pot and a stool: somebody sits out here
	PropKit.stool(b, 12.4, -14.7, Y, c8(0x4f7f70), P, 0.4)
	# the striped awning over it, sloping out into the well
	var aw := b.box(12.0, 13.95, Y + 1.25, Y + 1.29, WELL_BALC[2] - 0.25, WELL_BALC[3] + 0.25, c8(0x3f7a5a),
		o.merged({"surface": "fabric", "name": "Awning"}))
	aw.rotation.z = -0.28
	for k in 4:
		var z0 := WELL_BALC[2] - 0.25 + k * 0.35
		var st := b.box(12.0, 13.95, Y + 1.29, Y + 1.3, z0, z0 + 0.17, c8(0xe8e2d0), o.merged({"surface": "fabric", "name": "AwningStripe", "cast_shadow": false}))
		st.rotation.z = -0.28
	# the door onto it, halfway up the stairs to Lau's landing
	b.box(10.44, 10.5, Y, Y + 2.0, -14.85, -14.2, c8(0x4f6a5a), {"band": 0.0, "surface": "wood", "parent": P, "name": "BalconyDoor"})
	b.box(10.42, 10.44, Y + 0.95, Y + 1.05, -14.35, -14.25, c8(0xc9a55a), {"band": 0.0, "surface": "metal", "parent": P, "name": "BalconyDoorHandle", "cast_shadow": false})
	b.ref("wellBalconyDoor", Vector3(9.95, A, -12.35))
	b.ref("wellBalcony", Vector3(11.3, Y, -14.5))
	b.ref("awningSeen", Vector3(13.2, LevelBuilder.LEVEL_B, -12.7))
	# today: Mr. Kwok's back page, blown down onto it
	var pg := b.box(12.75, 13.15, Y + 0.005, Y + 0.012, -14.75, -14.45, c8(0xe6e0cc), {"band": 0.0, "surface": "grain", "parent": "ChapterProps/Ch2/KwokPage", "name": "Page", "cast_shadow": false})
	pg.rotation.y = 0.35
	b.ref("kwokPage", Vector3(12.8, Y, -14.55))


# ----------------------------------------------------------------------------- OQ04, the last mahjong tile


static func _mahjong_crack(b: LevelBuilder) -> void:
	# the crack at the foot of the alcove's back wall, a finger wide
	b.box(-3.0, -2.6, A, A + 0.03, 3.97, 4.0, c8(0x141210), {"band": 0.0, "surface": "concrete", "parent": "Structure/LevelA/Alcove", "name": "Crack", "cast_shadow": false})
	b.ref("tileCrack", Vector3(-2.8, A, 3.4))
	# where it comes out, low on the lane's wall: a hole, and behind the crates stacked against it
	b.box(-3.0, -2.6, A, A + 0.18, 4.3, 4.32, c8(0x141210), {"band": 0.0, "surface": "concrete", "parent": "Structure/Workshop/Lane", "name": "CrackHole", "cast_shadow": false})
	var C := "ChapterProps/Ch2/LaneCrates"
	for spec in [[-3.5, -2.9, 0.0, 0.34], [-2.85, -2.25, 0.0, 0.34], [-3.45, -2.95, 0.34, 0.68], [-2.8, -2.3, 0.34, 0.68], [-3.2, -2.6, 0.68, 1.02]]:
		b.box(spec[0], spec[1], A + spec[2], A + spec[3] - 0.02, 4.4, 4.85, c8(0x3f6fa8) if int(spec[2] * 10) % 2 == 0 else c8(0xc9463a),
			{"band": 0.0, "surface": "grain", "parent": C, "name": "Crate"})
	b.add_obstacle(-3.5, -2.25, 4.35, 4.9, A, "laneCrates", "chapter:Ch2")
	b.box(-2.86, -2.74, A, A + 0.05, 4.32, 4.4, c8(0xece6d4), {"band": 0.0, "surface": "grain", "parent": "ChapterProps/Ch2/LostTile", "name": "Tile", "cast_shadow": false})
	b.ref("tileHole", Vector3(-2.8, A, 5.2))


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
