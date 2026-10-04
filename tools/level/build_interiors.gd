class_name BuildInteriors
extends RefCounted

## The route itself: Mei's flat, the hall, the hidden corridor, Lau's clinic,
## the stairs, Level B, the airshaft and the roof. Positions, openings and
## collision footprints are the Three.js slice's, so every puzzle plays the
## same; the dressing on top is new.

static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	# the street under everything, so the city never floats over a void
	b.box(-170, 95, -0.9, -0.35, -90, 80, c8(0x5a5650), {"band": 0.0, "surface": "concrete", "parent": "Structure/Street",
		"name": "Street", "cast_shadow": false})
	lighting(b)
	level_a(b)
	level_b(b)
	BuildLightWell.build(b)
	BuildWorkshop.build(b)
	BuildYamen.build(b)
	airshaft(b)
	chapter_props(b)
	BuildQuietRooms.build(b)
	BuildSideQuests.build(b)
	BuildLastRoof.build(b)
	BuildWayOut.build(b)
	roof(b)
	pipes(b)
	characters(b)


# ----------------------------------------------------------------------------- lighting


static func lighting(b: LevelBuilder) -> void:
	var A := LevelBuilder.LEVEL_A
	var B := LevelBuilder.LEVEL_B
	b.lamp(Vector3(-10, 3.4, -0.5), c8(0xffc47e), 5.76, 11.0, {"name": "ApartmentBulb", "shadow": true})
	b.lamp(Vector3(-2, 3.6, 0), c8(0xe6f0ff), 4.32, 10.0, {"name": "HallTube", "shadow": true})
	b.lamp(Vector3(-2, 3.4, 2.6), c8(0xffd08a), 3.24, 7.0, {"name": "MahjongLamp"})
	b.lamp(Vector3(3, 3.4, -5), c8(0xffd9a0), 3.60, 9.0, {"name": "CorridorBulb", "shadow": true})
	b.lamp(Vector3(4, 3.6, -12), c8(0xdcf7ec), 5.76, 12.0, {"name": "ClinicTubes", "shadow": true})
	b.lamp(Vector3(9.3, 3.5, -13.5), c8(0xffe0b0), 2.52, 7.0, {"name": "StairwellBulb"})
	b.lamp(Vector3(3, B + 3.4, -12), c8(0xffd39a), 3.96, 11.0, {"name": "CorridorBBulb", "shadow": true})
	b.lamp(Vector3(-5, B + 3.4, -12.5), c8(0xffbf7a), 5.04, 12.0, {"name": "ChanLamp", "shadow": true})
	b.lamp(Vector3(10, B + 3.4, -13), c8(0xfff0d0), 2.88, 7.0, {"name": "LandingBulb"})
	b.lamp(Vector3(-5, B + 5.0, -18.5), c8(0xbfd6ff), 3.24, 10.0, {"name": "AirshaftSkylight"})
	b.lamp(Vector3(27.5, B + 3.4, -12), c8(0xffc07a), 5.04, 12.0, {"name": "WongLamp", "shadow": true})
	b.lamp(Vector3(30.3, B + 1.6, -15.2), c8(0xff4a3a), 1.80, 4.0, {"name": "WongAltarLamp"})
	b.lamp(Vector3(18, B + 3.0, -12), c8(0xfff3d6), 2.52, 9.0, {"name": "CatwalkLamp"})
	b.lamp(Vector3(-12.8, A + 1.5, -1), c8(0xff5a3a), 1.26, 3.5, {"name": "FamilyAltarLamp"})


# ----------------------------------------------------------------------------- Level A


static func level_a(b: LevelBuilder) -> void:
	var Y := LevelBuilder.LEVEL_A
	var P := "Furniture/Apartment"
	# nearly all of it gone by the last day (Chapter 7: BuildQuietRooms._last_day)
	var P6 := "ChapterProps/Ch1-6/Apartment"

	# Mei's flat: a single room, three generations, and today, boxes
	b.room({"x0": -14, "x1": -6, "z0": -4, "z1": 4, "y": Y, "name": "Apartment", "id": "apartment",
		"floor_surface": "wood", "wall": c8(0x9a977a), "floor": c8(0x6b5a45),
		"open": {"e": [[-1, 1]]}, "parent": "Structure/LevelA"})
	# three generations, one room: Grandfather below, Mei on the top bunk, a
	# curtain drawn back at the head; Mum sleeps up on the cockloft
	PropKit.bed(b, -14, -12, 1.8, 4, Y, c8(0x8a6f5a), c8(0xd8d0bd), P6)
	b.add_obstacle(-14, -12, 1.8, 4, Y, "bed", "chapter:Ch1-6")
	PropKit.bunk_top(b, -14, -12, 1.8, 4, Y, c8(0x8a6f5a), c8(0xe4dccb), c8(0x6f5a8a), P6)
	PropKit.curtain(b, 1.85, 2.4, Y + 0.3, Y + 1.3, -11.93, "z", c8(0xa8453a), P6)
	b.box(-12.0, -11.93, Y + 1.3, Y + 1.33, 1.82, 3.48, c8(0x5a4a3a), {"surface": "metal", "parent": P6, "name": "CurtainRail", "cast_shadow": false})
	PropKit.table(b, -12.2, -10.8, -1.2, 0.2, Y, 0.8, c8(0x6b4a30), P6)
	b.add_obstacle(-12.2, -10.8, -1.2, 0.2, Y, "table", "chapter:Ch1-6")
	for i in 3:   # rice bowls and chopsticks
		var x := -11.9 + i * 0.3
		ObjectKit.rice_bowl(b, Vector3(x + 0.08, Y + 0.8, -0.72), 0.062, c8(0xe8e2d0), P6)
		ObjectKit.chopsticks(b, Vector3(x + 0.01, Y + 0.8, -0.54), Vector3(1, 0, 0.08), 0.22, c8(0xc9a55a), P6)
	ObjectKit.thermos(b, Vector3(-11.15, Y + 0.8, -0.075), 0.06, 0.3, c8(0x4f7f70), P6)
	PropKit.stool(b, -11.5, 0.6, Y, c8(0xc9463a), P6)
	# where Mei sits to eat the rice Mum saved her: the end of Chapter 1. The bowl
	# at her place by the red stool, a plate over it to keep it warm, chopsticks beside
	ObjectKit.rice_bowl(b, Vector3(-11.5, Y + 0.8, -0.02), 0.07, c8(0xe8e2d0), "ChapterProps/Ch1/Rice", "SavedRice", true)
	# the plate laid upside down over it, as a lid
	ObjectKit.plate(b, Vector3(-11.5, Y + 0.8 + 0.07 * 0.85 + 0.019, -0.02), 0.1, c8(0xdfe4e2), "ChapterProps/Ch1/Rice", "RicePlate", {"rotation": Vector3(PI, 0, 0)})
	ObjectKit.chopsticks(b, Vector3(-11.35, Y + 0.8, -0.13), Vector3(0, 0, 1), 0.23, c8(0xc9a55a), "ChapterProps/Ch1/Rice")
	b.ref("rice", Vector3(-11.5, Y, 0.9))
	PropKit.stool(b, -10.3, -0.5, Y, c8(0x3f6fa8), P6)
	PropKit.shelf_z(b, -14, -13.4, -2.2, -0.4, Y, 1.5, c8(0x5d4632), P6)
	b.add_obstacle(-14, -13.4, -2.2, -0.4, Y, "shelf", "chapter:Ch1-6")
	var radio := PropKit.radio(b, -13.95, -13.45, Y + 1.5, -1.8, -0.9, P6)
	radio.name = "Radio"
	PropKit.altar(b, -13.95, -13.6, Y + 1.2, Y + 1.25, -1.2, -1.0, P6)
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(-9.2, Y + 1.8, -4.0), Vector2(0.45, 0.68), Vector3(0, 0, 1),
		{"parent": P6, "name": "Calendar", "band": 0.0})
	# turned on Grandfather in his chair
	var rotor := PropKit.fan(b, -7.0, 3.2, Y, P, Vector3(-12.8, Y, -0.15) - Vector3(-7.0, Y, 3.2))
	rotor.reparent(b.group("Special"), false)
	b._own(rotor)
	rotor.name = "Fan"
	PropKit.bulb(b, Vector3(-10, Y + 3.3, -0.5), Y + 4.2, P)
	# a birdcage hanging by the window, an old clock, slippers by the door
	ObjectKit.slippers(b, -6.9, -6.6, -0.8, -0.4, Y, c8(0x3f6fa8), P6, Vector3(-1, 0, 0))
	ObjectKit.slippers(b, -6.9, -6.6, 0.4, 0.8, Y, c8(0xa8453a), P6, Vector3(-1, 0, 0.2))
	ObjectKit.wall_clock(b, Vector3(-8.45, Y + 2.67, -3.94), Vector3(0, 0, 1), 0.16, c8(0x6b4a30), P6)

	# Packing boxes, present from the very first frame. Against the back wall,
	# behind Grandfather's chair.
	var bc := c8(0xa8834f)
	PropKit.cardboard(b, -13.9, -12.7, Y, Y + 0.8, -3.95, -3.1, bc, P6)
	b.add_obstacle(-13.9, -12.7, -3.95, -3.1, Y, "boxes", "chapter:Ch1-6")
	PropKit.cardboard(b, -12.6, -11.5, Y, Y + 0.7, -3.95, -3.2, c8(0x9c7a48), P6)
	b.add_obstacle(-12.6, -11.5, -3.95, -3.2, Y, "boxes2", "chapter:Ch1-6")
	PropKit.cardboard(b, -13.7, -12.9, Y + 0.8, Y + 1.4, -3.9, -3.2, c8(0xb08c58), P6)
	# one more by the door, its label on the side you only see once you turn round
	PropKit.cardboard(b, -6.7, -6.05, Y, Y + 0.6, 1.3, 2.2, c8(0xa07d4a), P6, "")
	b.add_obstacle(-6.7, -6.05, 1.3, 2.2, Y, "boxes3", "chapter:Ch1-6")
	b.card("res://assets/textures/props/carton_new_flat.png", Vector3(-6.7, Y + 0.32, 1.75), Vector2(0.8, 0.4), Vector3(-1, 0, 0),
		{"parent": P6, "name": "NewFlatLabel", "band": 0.0})
	# the cockloft over the boxes: Mum's bedding, and the cases already packed
	PropKit.cockloft(b, -14, -11.2, -4, -2.6, Y, 2.3, P)

	# the kitchen: a counter under the calendar, the tap fed from the blue pipe
	# where it comes into the flat
	PropKit.kitchen_counter(b, -9.7, -7.9, -3.99, -3.4, Y, P, "n")
	var water := c8(0x9aa0a4)
	PropKit.pipe_run(b, [Vector3(-7.2, 3.6, -3.7), Vector3(-7.2, 3.6, -3.92), Vector3(-8.0, 3.6, -3.92), Vector3(-8.0, 1.22, -3.92),
		Vector3(-8.0, 1.22, -3.74)], 0.018, water, P, 0.0, "TapPipe")
	for clip in [Vector3(-7.6, 3.6, 0), Vector3(-8.0, 2.4, 0)]:
		b.box(clip.x - 0.02, clip.x + 0.02, clip.y - 0.03, clip.y + 0.03, -4.0, -3.9, c8(0x5a5a58), {"surface": "metal", "parent": P, "name": "PipeClip", "cast_shadow": false})
	ObjectKit.tap(b, Vector3(-8.0, 1.24, -3.72), Vector3(0, 0, 1), c8(0xc9463a), P)

	# and in the corner past it, behind a curtain: a squat toilet, its cistern
	# fed from the same pipe
	PropKit.squat_toilet(b, -6.75, -3.99, Y, P, Vector3(-7.2, 3.45, -3.7))
	b.box(-7.47, -6.0, Y + 2.02, Y + 2.05, -2.87, -2.84, c8(0x5a4a3a), {"surface": "metal", "parent": P, "name": "CurtainRail", "cast_shadow": false})
	b.box(-7.47, -7.44, Y + 2.02, Y + 2.05, -4.0, -2.84, c8(0x5a4a3a), {"surface": "metal", "parent": P, "name": "CurtainRail", "cast_shadow": false})
	PropKit.curtain(b, -7.44, -6.82, Y + 0.12, Y + 2.02, -2.855, "x", c8(0x6f8ab0), P)
	PropKit.curtain(b, -3.97, -2.87, Y + 0.12, Y + 2.02, -7.455, "z", c8(0x6f8ab0), P)
	var ring := ModelKit.tube(PropKit._oval(0.022, 0.022, 14), 0.0035, 0.0, 6, false)
	for ring_x in [-7.4, -7.2, -7.0, -6.84]:
		ModelKit.place(b, ring, Vector3(ring_x, Y + 2.035, -2.8575), "metal", c8(0x8a8a86), {"parent": P, "name": "CurtainRing", "rotation": Vector3(0, PI / 2, 0), "cast_shadow": false})
	b.add_obstacle(-7.45, -6.05, -4, -2.85, Y, "toiletNook")

	# coats and a bag on hooks by the door
	b.box(-6.08, -6.03, Y + 1.74, Y + 1.78, -2.6, -1.35, c8(0x5a4a3a), {"surface": "wood", "parent": P6, "name": "HookRail", "cast_shadow": false})
	ObjectKit.coat(b, -6.03, -1.0, Y + 1.74, Y + 0.95, -2.5, -2.02, c8(0x4f5a70), P6)
	ObjectKit.bag(b, -6.03, -1.0, Y + 1.25, Y + 1.74, -1.88, -1.5, c8(0x8a6a48), P6)

	# Grandfather's old photograph, framed on the back wall
	b.box(-10.76, -10.34, Y + 1.44, Y + 1.76, -3.99, -3.96, c8(0x4a3322), {"surface": "wood", "parent": P6, "name": "PhotoFrame"})
	b.card("res://assets/textures/props/old_photo.png", Vector3(-10.55, Y + 1.6, -3.96), Vector2(0.34, 0.262), Vector3(0, 0, 1),
		{"parent": P6, "name": "OldPhoto", "band": 0.0})
	b.ref("boxes", Vector3(-12.3, 0, -2.6))
	b.ref("radio", Vector3(-13.2, 0, -1.3))
	b.ref("oldPhoto", Vector3(-10.55, 0, -3.3))

	# The hall. It ends at a wall with an old service door set in it. The door
	# faces back down the hall, so from the starting view it's edge-on and can't
	# be seen; from the west it's plain as day.
	b.room({"x0": -6, "x1": 2, "z0": -1, "z1": 1, "y": Y, "name": "Hall", "wall": c8(0x7c7f74), "floor": c8(0x4e4a44),
		"open": {"s": [[-4, 0], [0.3, 1.7]], "e": [[-0.7, 0.7]]}, "skip": ["w"], "parent": "Structure/LevelA",
		"dado": "mosaic", "dado_color": c8(0xa9c0b8)})
	b.door({"id": "serviceDoor", "x": 2.15, "z": 0.0, "y": Y, "normal": Vector3(-1, 0, 0), "width": 1.4,
		"color": c8(0x7a93a0), "band": 0.0, "room": "corridor", "light_spill": true})
	var PH := "Furniture/Hall"
	b.box(-5.8, -5.2, Y, Y + 0.5, 0.45, 0.95, c8(0x5c6b4a), {"surface": "grain", "parent": PH, "name": "BucketCrate"})
	PropKit.bucket(b, Vector3(-5.6, Y + 0.5, 0.65), 0.14, 0.28, c8(0xc9463a), PH, 0.0)
	b.box(-0.95, -0.35, Y, Y + 0.05, 0.45, 0.95, c8(0x3d4a52), {"surface": "metal", "parent": PH, "name": "FanPartsTray"})
	b.cylinder(Vector3(-0.8, Y + 0.1, 0.7), Vector3(-0.8, Y + 0.14, 0.7), 0.16, b.surface("metal"), {"parent": PH, "name": "FanGrille", "tint": c8(0x5a6a72)})
	b.box(-0.6, -0.42, Y + 0.05, Y + 0.14, 0.55, 0.85, c8(0x2e3438), {"surface": "metal", "parent": PH, "name": "FanMotor"})
	# A shallow steel cabinet ties the painted mailbox faces back to the wall.
	# The old card by itself read as a poster hovering in the corridor.
	b.box(-5.29, -4.31, Y + 1.01, Y + 1.99, -0.97, -0.86, c8(0x355d55), {"surface": "metal", "parent": PH, "name": "MailboxCabinet"})
	b.box(-5.33, -4.27, Y + 0.98, Y + 1.03, -0.99, -0.84, c8(0x28463f), {"surface": "metal", "parent": PH, "name": "MailboxMount"})
	b.box(-5.33, -4.27, Y + 1.97, Y + 2.02, -0.99, -0.84, c8(0x28463f), {"surface": "metal", "parent": PH, "name": "MailboxMount"})
	b.card("res://assets/textures/props/mailboxes.png", Vector3(-4.8, Y + 1.5, -0.85), Vector2(0.9, 0.9), Vector3(0, 0, 1), {"parent": PH, "name": "Mailboxes", "band": 0.0})
	b.card("res://assets/textures/props/notice_clearance.png", Vector3(-2.6, Y + 1.75, -0.85), Vector2(0.55, 0.73), Vector3(0, 0, 1), {"parent": PH, "name": "ClearanceNotice", "band": 0.0})
	b.card("res://assets/textures/props/poster_2.png", Vector3(-1.2, Y + 1.7, -0.85), Vector2(0.45, 0.63), Vector3(0, 0, 1), {"parent": PH, "name": "ShopToLet", "band": 0.0})
	PropKit.tube_light(b, Vector3(-3.0, Y + 3.9, 0), Vector3(-1.8, Y + 3.9, 0), Y + 4.2, PH)
	# wiring stapled along the hall ceiling, and an electricity meter box
	b.box(-5.5, -4.9, Y + 2.3, Y + 2.9, -0.86, -0.8, c8(0x55605a), {"surface": "metal", "parent": PH, "name": "MeterBox"})
	for k in 3:
		b.cylinder(Vector3(-6, Y + 3.7 + k * 0.06, -0.8), Vector3(2, Y + 3.7 + k * 0.06, -0.8), 0.012, b.surface("grain"),
			{"parent": PH, "name": "Wire", "tint": c8(0x1c1c1e), "cast_shadow": false, "ceiling_mounted": true})

	# Mahjong alcove
	b.room({"x0": -4, "x1": 0, "z0": 1, "z1": 4, "y": Y, "name": "Alcove", "wall": c8(0x8a7a62), "floor": c8(0x5a4c3c),
		"skip": ["n"], "open": {"s": [[-1.1, -0.2]]}, "parent": "Structure/LevelA"})
	var PA := "Furniture/Alcove"
	# the game and the chopping block are packed away by Chapter 5 (BuildQuietRooms)
	var PA4 := "ChapterProps/Ch1-4/Alcove"
	b.box(-2.8, -1.2, Y + 0.7, Y + 0.75, 2.0, 3.3, c8(0x2e5a3a), {"surface": "fabric", "parent": PA4, "name": "MahjongCloth"})
	PropKit.table(b, -2.8, -1.2, 2.0, 3.3, Y, 0.7, c8(0x5a3a26), PA4)
	b.add_obstacle(-2.8, -1.2, 2.0, 3.3, Y, "mahjong", "chapter:Ch1-4")
	_mahjong_game(b, Vector3(-2.0, Y + 0.752, 2.65), PA4 + "/Game")
	for cup in [Vector3(-2.62, Y + 0.75, 3.14), Vector3(-1.36, Y + 0.75, 2.17)]:
		_tea_cup(b, cup, PA4)
	PropKit.table(b, -3.95, -3.3, 2.5, 3.5, Y, 0.8, c8(0x6b4a30), PA4)
	b.add_obstacle(-3.95, -3.3, 2.5, 3.5, Y, "chopping", "chapter:Ch1-4")
	ObjectKit.chopping_block(b, Vector3(-3.64, Y + 0.8, 2.95), 0.24, 0.1, PA4)
	ObjectKit.greens(b, Vector3(-3.85, Y + 0.8, 3.36), Vector3(1, 0, 0.1), PA4)
	ObjectKit.cleaver(b, Vector3(-3.6, Y + 0.9, 2.92), Vector3(0.2, 0, 1), PA4)
	b.card("res://assets/textures/props/poster_1.png", Vector3(-2.0, Y + 1.9, 3.85), Vector2(0.5, 0.7), Vector3(0, 0, -1), {"parent": PA, "name": "MahjongPoster", "band": 0.0})
	PropKit.bulb(b, Vector3(-2, Y + 2.9, 2.6), Y + 4.2, PA)

	# Hidden corridor to Lau's
	b.room({"x0": 2, "x1": 4, "z0": -9, "z1": 1, "y": Y, "name": "Corridor", "wall": c8(0x77705e), "floor": c8(0x4a463e),
		"id": "corridor", "open": {"w": [[-6, -4], [-1.3, 1.3]], "e": [BuildWayOut.PASSAGE.slice(2, 4)]}, "skip": ["n"], "parent": "Structure/LevelA",
		"dado": "mosaic", "dado_color": c8(0xc9b89a)})
	b.room({"x0": 0, "x1": 2, "z0": -6, "z1": -4, "y": Y, "name": "Stall", "wall": c8(0x6a6a55), "floor": c8(0x4a463e),
		"skip": ["e"], "id": "corridor", "parent": "Structure/LevelA", "no_fade": true})
	var PS := "Furniture/Stall"
	b.box(1.3, 1.7, Y, Y + 1.0, -5.9, -4.1, c8(0x7a5c3a), {"surface": "wood", "parent": PS, "name": "Counter"})
	b.add_obstacle(1.3, 1.7, -5.9, -4.1, Y, "counter")
	b.box(0.05, 0.5, Y, Y + 2.2, -5.9, -4.1, c8(0x5a4a38), {"surface": "wood", "parent": PS, "name": "MagazineRack"})
	var mags := [c8(0xc94f3f), c8(0xe0c060), c8(0x4f7fb0), c8(0xe8e2d0), c8(0x6f9a5a), c8(0xd87a9a)]
	for i in 4:
		for k in 5:
			var z0 := -5.85 + k * 0.34
			b.box(0.5, 0.54, Y + 0.5 + i * 0.4, Y + 0.82 + i * 0.4, z0, z0 + 0.28, mags[(i * 5 + k) % 6],
				{"surface": "fabric", "parent": PS, "name": "Magazine", "cast_shadow": false})
	for k in 6:
		b.box(1.32, 1.68, Y + 1.0 + k * 0.012, Y + 1.012 + k * 0.012, -5.5 + k * 0.05, -5.1 + k * 0.05, c8(0xebe4d2),
			{"surface": "fabric", "parent": PS, "name": "Newspaper", "cast_shadow": false})
	PropKit.bulb(b, Vector3(3, Y + 3.2, -5), Y + 4.2, "Furniture/Corridor")
	b.card("res://assets/textures/props/poster_3.png", Vector3(3.85, Y + 1.7, -2.5), Vector2(0.45, 0.63), Vector3(-1, 0, 0), {"parent": "Furniture/Corridor", "name": "RepairsPoster", "band": 0.0})

	# Lau's clinic
	b.room({"x0": 0, "x1": 8, "z0": -15, "z1": -9, "y": Y, "name": "Clinic", "id": "clinic", "wall_surface": "tiles",
		"floor_surface": "floor", "wall": c8(0x9fc3b2), "floor": c8(0xc9d2c8), "open": {"s": [[2, 4]], "e": [[-15, -12]]},
		"parent": "Structure/LevelA"})
	var PC := "Furniture/Clinic"
	# (the chair, its lamp and the trolley are gone by Chapter 4)
	var PC3 := "ChapterProps/Ch1-3/Clinic"
	# (his certificate, calendar, drawers and most of the boxes: gone by Chapter 5)
	var PC4 := "ChapterProps/Ch1-4/Clinic"
	# the dental chair: base, seat, back, arms, footrest
	ObjectKit.dental_chair(b, 4.3, 5.8, -13.3, -11.7, Y, PC3)
	b.add_obstacle(4.3, 5.8, -13.3, -11.7, Y, "chair", "chapter:Ch1-3")
	ObjectKit.dental_lamp(b, Vector3(5.95, Y, -13.45), Y + 2.1, Vector3(5.3, Y + 1.92, -12.3), PC3)
	# A wheeled instrument trolley, kept clear of the fitted drawer cabinet.
	# These used to intersect and read as one unexplained stepped white object.
	var trolley_x0 := 5.15
	var trolley_x1 := 5.72
	var trolley_z0 := -14.82
	var trolley_z1 := -14.28
	for tx in [trolley_x0 + 0.05, trolley_x1 - 0.05]:
		for tz in [trolley_z0 + 0.05, trolley_z1 - 0.05]:
			b.cylinder(Vector3(tx, Y + 0.08, tz), Vector3(tx, Y + 0.82, tz), 0.018, b.surface("metal"), {"parent": PC3, "name": "TrolleyLeg", "tint": c8(0xaeb3b0)})
			b.cylinder(Vector3(tx, Y + 0.055, tz), Vector3(tx, Y + 0.055, tz + 0.055), 0.035, b.surface("metal"), {"parent": PC3, "name": "TrolleyCaster", "tint": c8(0x343838)})
	b.box(trolley_x0, trolley_x1, Y + 0.76, Y + 0.82, trolley_z0, trolley_z1, c8(0xdcdcd4), {"surface": "metal", "parent": PC3, "name": "TrolleyShelf"})
	b.box(trolley_x0 - 0.03, trolley_x1 + 0.03, Y + 0.86, Y + 0.91, trolley_z0 - 0.03, trolley_z1 + 0.03, c8(0xe8e8df), {"surface": "metal", "parent": PC3, "name": "InstrumentTray"})
	b.add_obstacle(trolley_x0, trolley_x1, trolley_z0, trolley_z1, Y, "trolley", "chapter:Ch1-3")
	for i in 5:
		# probes and mirrors: a slim handle, a fine bent tip
		var ix := 5.225 + i * 0.09
		var tip := Vector3(0.012 * (i % 3 - 1), 0.0, 0.03 if i % 2 == 0 else 0.0)
		ModelKit.place(b, ModelKit.tube([Vector3(0, 0, -0.15), Vector3(0, 0, 0.1), Vector3(0, 0, 0.14) + tip], 0.0045, 0.01, 6), Vector3(ix, Y + 0.915, -14.55), "metal", c8(0xd8dce0),
			{"parent": PC3, "name": "Instrument", "cast_shadow": false})
		if i == 2:
			ModelKit.place(b, ModelKit.puck(0.011, 0.002, 0.0008, 12), Vector3(ix, Y + 0.912, -14.39), "glaze", c8(0xc8d8e0), {"parent": PC3, "name": "Mirror", "cast_shadow": false})
	# Enamel dental storage: one cupboard and a bank of four unmistakable drawers.
	b.box(5.9, 7.3, Y, Y + 1.27, -15, -14.45, c8(0xd7ddd8), {"surface": "metal", "parent": PC4, "name": "DentalCabinet"})
	b.box(5.86, 7.34, Y + 1.27, Y + 1.34, -15.03, -14.4, c8(0xeff0e8), {"surface": "metal", "parent": PC4, "name": "CabinetCounter"})
	b.add_obstacle(5.9, 7.3, -15, -14.4, Y, "cabinet", "chapter:Ch1-4")
	# Left cupboard door, hinge pins, and a proper pull.
	b.box(5.98, 6.52, Y + 0.1, Y + 1.19, -14.44, -14.37, c8(0xe4e7df), {"surface": "metal", "parent": PC4, "name": "CupboardDoor", "cast_shadow": false})
	for hinge_y in [Y + 0.28, Y + 1.0]:
		b.box(5.97, 6.01, hinge_y - 0.05, hinge_y + 0.05, -14.4, -14.37, c8(0x747c7b), {"surface": "metal", "parent": PC4, "name": "CabinetHinge", "cast_shadow": false})
	b.box(6.38, 6.45, Y + 0.58, Y + 0.72, -14.355, -14.32, c8(0x687170), {"surface": "metal", "parent": PC4, "name": "CupboardHandle", "cast_shadow": false})
	for i in 4:
		var drawer_y := Y + 0.12 + i * 0.28
		b.box(6.59, 7.21, drawer_y, drawer_y + 0.23, -14.44, -14.37, c8(0xe6e8e1), {"surface": "metal", "parent": PC4, "name": "DrawerFront", "cast_shadow": false})
		b.box(6.8, 7.0, drawer_y + 0.1, drawer_y + 0.13, -14.355, -14.32, c8(0x687170), {"surface": "metal", "parent": PC4, "name": "DrawerHandle", "cast_shadow": false})
	ObjectKit.spittoon(b, Vector3(6.05, Y, -11.45), 0.75, PC3)
	PropKit.cardboard(b, 0.2, 1.6, Y, Y + 0.7, -14.8, -13.4, c8(0xa8834f), PC)
	b.add_obstacle(0.2, 1.6, -14.8, -13.4, Y, "clinicBoxes")
	PropKit.cardboard(b, 0.3, 1.4, Y + 0.7, Y + 1.2, -14.6, -13.7, c8(0x9c7a48), PC4)
	PropKit.cardboard(b, 0.2, 1.3, Y, Y + 0.6, -10.8, -9.3, c8(0xa8834f), PC4)
	b.add_obstacle(0.2, 1.3, -10.8, -9.3, Y, "clinicBoxes2", "chapter:Ch1-4")
	b.card("res://assets/textures/props/certificate.png", Vector3(0.05, Y + 1.7, -12.0), Vector2(0.9, 0.68), Vector3(1, 0, 0), {"parent": PC4, "name": "Certificate", "band": 0.0})
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(7.95, Y + 1.8, -10.4), Vector2(0.4, 0.6), Vector3(-1, 0, 0), {"parent": PC4, "name": "Calendar", "band": 0.0})
	PropKit.tube_light(b, Vector3(3.2, Y + 3.9, -12), Vector3(4.8, Y + 3.9, -12), Y + 4.2, PC)
	PropKit.tube_light(b, Vector3(3.2, Y + 3.9, -10.6), Vector3(4.8, Y + 3.9, -10.6), Y + 4.2, PC)

	# The hanging vertical sign: a landmark over the rooftops of Level A (taken down
	# with him by Chapter 5; its bracket stays).
	var sign := b.card("res://assets/textures/props/sign_lau_dental.png", Vector3(3, Y + 5.3, -8.6), Vector2(2.4, 1.2), Vector3(0, 0, 1),
		{"parent": "ChapterProps/Ch1-4/LauSign", "name": "LauSign", "band": 0.0, "emission": 0.25, "fadeable": true})
	sign.name = "LauSign"
	# it hangs right over the clinic door: once Mei is inside, it fades like a wall
	b.box(1.75, 4.25, Y + 4.65, Y + 5.95, -8.8, -8.66, c8(0x5a2a22), {"band": 0.0, "surface": "wood", "parent": "ChapterProps/Ch1-4/LauSign", "name": "SignBoard", "fadeable": true})
	b.box(2.9, 3.1, Y + 4.2, Y + 4.7, -8.8, -8.7, c8(0x333333), {"band": 0.0, "surface": "metal", "parent": "Dressing/LauSign", "name": "SignBracket", "fadeable": true})
	b.ref("lauSign", Vector3(3, 0, -8.2))

	# Stairwell
	b.room({"x0": 8, "x1": 10.5, "z0": -15, "z1": -12, "y": Y, "name": "Stairwell", "id": "clinic",
		"wall": c8(0x6d6a60), "floor": c8(0x4a463e), "skip": ["w"], "open": {"n": [BuildQuietRooms.SHOP_DOOR]},
		"parent": "Structure/LevelA", "wall_surface": "concrete"})
	for i in 6:
		b.box(9.9, 10.5, Y, Y + 0.35 * (i + 1), -12.3 - i * 0.45, -12.75 - i * 0.45, c8(0x5d5a52), {"surface": "concrete", "parent": "Structure/LevelA/Stairwell", "name": "Step"})
		b.box(9.88, 10.5, Y + 0.35 * (i + 1) - 0.03, Y + 0.35 * (i + 1) + 0.003, -12.3 - i * 0.45, -12.36 - i * 0.45, c8(0x8a8a80), {"surface": "metal", "parent": "Structure/LevelA/Stairwell", "name": "Nosing", "cast_shadow": false})
	# The railing follows the office-side edge of the flight and stops before the
	# doorway at the upper landing. Its posts terminate on tread tops, making it
	# part of the stair rather than a diagonal bar attached across the door wall.
	var stair_rail_x := 9.94
	b.cylinder(Vector3(stair_rail_x, Y + 1.18, -12.38), Vector3(stair_rail_x, Y + 2.83, -14.52), 0.025, b.surface("metal"), {"parent": "Structure/LevelA/Stairwell", "name": "Handrail", "tint": c8(0x6a5a48)})
	for post in [
		Vector3(stair_rail_x, Y + 0.35, -12.48),
		Vector3(stair_rail_x, Y + 1.05, -13.38),
		Vector3(stair_rail_x, Y + 1.75, -14.28),
	]:
		var rail_y: float = Y + 1.18 + (post.z + 12.38) / -2.14 * 1.65
		b.cylinder(post, Vector3(post.x, rail_y, post.z), 0.018, b.surface("metal"), {"parent": "Structure/LevelA/Stairwell", "name": "RailPost", "tint": c8(0x6a5a48)})
		b.box(post.x - 0.055, post.x + 0.055, post.y - 0.015, post.y + 0.02, post.z - 0.055, post.z + 0.055, c8(0x59534a), {"surface": "metal", "parent": "Structure/LevelA/Stairwell", "name": "RailFoot", "cast_shadow": false})
	# the flight is walkable: its height is each tread's at the tread's middle
	# (0.35 up per 0.45 along), reaching 2.1 at the wall. It runs a little wider
	# than the steps, under the handrail, so Mei's footprint fits on it. Below
	# the first step, a low obstacle keeps anyone on the floor out of the steps'
	# solid sides (it reaches only those below 0.2: anyone on the flight is above it)
	b.add_flight(9.75, 10.5, -15.0, -12.3, "z", -12.3, Y + 0.175, -0.35 / 0.45, Y, Y + 2.1, "stairsA")
	b.add_obstacle(9.9, 10.5, -15.0, -12.75, Y - 0.8, "stairsASides")
	# where the flight meets the wall: "Go upstairs" from the top step
	b.ref("stairsUpA", Vector3(10.15, Y + 2.0, -14.62))

	# The ground under the catwalk light well: other people's rubbish
	b.box(11, 25, -0.3, 0, -17, -7, c8(0x3a3833), {"band": 0.0, "surface": "concrete", "parent": "Structure/LightWell", "name": "WellFloor"})
	for i in 14:
		var x := 12 + b.rand.randf() * 11
		var z := -16 + b.rand.randf() * 8
		var h := 0.3 + b.rand.randf() * 0.9
		var col: Color = [c8(0x5a4a38), c8(0x6f7d62), c8(0x3d4a52), c8(0x8a5a3a), c8(0xa8834f)][i % 5]
		var s: String = ["grain", "rust", "metal", "wood", "grain"][i % 5]
		b.box(x, x + 0.6 + b.rand.randf(), 0, h, z, z + 0.5 + b.rand.randf(), col, {"band": 0.0, "surface": s, "parent": "Structure/LightWell", "name": "Rubbish"})


# ----------------------------------------------------------------------------- Level B


static func level_b(b: LevelBuilder) -> void:
	var Y := LevelBuilder.LEVEL_B
	b.room({"x0": 8, "x1": 12, "z0": -15, "z1": -11, "y": Y, "name": "Landing", "wall": c8(0x7a7466), "floor": c8(0x4e4a42),
		"open": {"w": [[-13, -11]], "e": [[-13, -11]]}, "parent": "Structure/LevelB", "wall_surface": "concrete",
		"floor_hole": [8.0, 8.95, -15.0, -13.1]})
	# the roof door, drawn into the north wall (swollen shut in its frame)
	panel_door(b, 9.9, 10.9, Y, 2.3, -14.95, c8(0x56705f), "Structure/LevelB/Landing", -1.0, "RoofDoor")
	b.ref("stairsDownB", Vector3(8.5, Y, -13.9))
	b.ref("roofDoorB", Vector3(10.4, Y, -14.4))
	# the flight down toward the clinic: it starts at the landing's edge (z -13.1),
	# where Mei steps onto it, and drops south in solid concrete steps between the
	# shaft's walls to a half-landing where it turns out of sight, their nosings
	# painted safety yellow so it reads from any view. It stops 0.75 down: below
	# that is the ceiling of the stairwell on Level A
	var SP := "Structure/LevelB/Landing/StairsDown"
	for i in 4:
		var top := Y - 0.17 * (i + 1)
		var z1 := -13.1 - 0.27 * i
		var z0 := -15.0 if i == 3 else z1 - 0.27
		b.box(8.0, 8.95, Y - 0.75, top, z0, z1, c8(0x6a665c), {"band": 1.0, "surface": "concrete", "parent": SP, "name": "Step" if i < 3 else "HalfLanding"})
		b.box(8.0, 8.95, top - 0.03, top + 0.002, z1 - 0.05, z1, c8(0xd8b23a), {"band": 1.0, "surface": "metal", "parent": SP, "name": "Nosing", "cast_shadow": false})
	# the shaft's walls below the landing's floor, so it's a stairwell, not a hole
	b.box(7.9, 8.0, Y - 0.75, Y - 0.02, -15.05, -13.1, c8(0x5f5b52), {"band": 1.0, "surface": "concrete", "parent": SP, "name": "ShaftWall"})
	b.box(8.95, 9.05, Y - 0.75, Y - 0.04, -15.05, -13.1, c8(0x5f5b52), {"band": 1.0, "surface": "concrete", "parent": SP, "name": "ShaftWall"})
	b.box(7.9, 9.05, Y - 0.75, Y - 0.02, -15.1, -15.0, c8(0x5f5b52), {"band": 1.0, "surface": "concrete", "parent": SP, "name": "ShaftWall"})
	# a handrail on the west wall, falling with the flight
	b.cylinder(Vector3(8.07, Y + 0.9, -13.0), Vector3(8.07, Y + 0.9 - 0.68, -14.2), 0.022, b.surface("metal"), {"parent": SP, "name": "Handrail", "tint": c8(0x6a5a48), "band": 1.0})
	for hz in [-13.3, -14.0]:
		var hy: float = Y + 0.9 - 0.68 * (-13.0 - hz) / 1.2
		b.box(8.0, 8.08, hy - 0.08, hy - 0.02, hz - 0.015, hz + 0.015, c8(0x5a5a58), {"band": 1.0, "surface": "metal", "parent": SP, "name": "HandrailBracket", "cast_shadow": false})
	# the lip of the opening, also painted, and light spilling up from the flight below
	b.box(8.0, 8.95, Y - 0.04, Y + 0.01, -13.16, -13.1, c8(0xd8b23a), {"band": 1.0, "surface": "metal", "parent": SP, "name": "Lip", "cast_shadow": false})
	b.box(8.95, 9.0, Y - 0.04, Y + 0.01, -15.0, -13.1, c8(0xd8b23a), {"band": 1.0, "surface": "metal", "parent": SP, "name": "Lip", "cast_shadow": false})
	PropKit.bulb(b, Vector3(8.48, Y + 2.6, -14.3), Y + 4.2, SP)
	# a painted green rail along the landing's side of the drop only: the north
	# end, where the flight starts, is left open to walk onto
	var rail := c8(0x4f7a5a)
	for pz in [-13.1, -13.75, -14.4, -14.97]:
		b.box(8.96, 9.04, Y, Y + 1.0, pz - 0.04, pz + 0.04, rail, {"band": 1.0, "surface": "metal", "parent": SP, "name": "RailPost"})
	b.box(8.95, 9.05, Y + 0.93, Y + 1.0, -15.0, -13.05, rail, {"band": 1.0, "surface": "metal", "parent": SP, "name": "Rail"})
	b.box(8.97, 9.03, Y + 0.45, Y + 0.5, -15.0, -13.07, rail, {"band": 1.0, "surface": "metal", "parent": SP, "name": "MidRail"})
	# the painted marker on the walls above the flight
	b.card("res://assets/textures/props/sign_stairs_down.png", Vector3(8.48, Y + 1.75, -14.94), Vector2(0.6, 0.8), Vector3(0, 0, 1), {"parent": SP, "name": "StairSign", "band": 1.0})
	b.card("res://assets/textures/props/sign_stairs_down.png", Vector3(8.06, Y + 1.75, -13.9), Vector2(0.6, 0.8), Vector3(1, 0, 0), {"parent": SP, "name": "StairSign", "band": 1.0})
	b.add_obstacle(8.0, 8.95, -15.0, -13.1, Y, "stairwell")
	PropKit.bulb(b, Vector3(10, Y + 3.2, -13), Y + 4.2, "Structure/LevelB/Landing")

	b.room({"x0": -2, "x1": 8, "z0": -13, "z1": -11, "y": Y, "name": "CorridorB", "wall": c8(0x807868), "floor": c8(0x4a4640),
		"skip": ["w", "e"], "open": {"n": [[2.2, 3.0]]}, "parent": "Structure/LevelB", "dado": "mosaic", "dado_color": c8(0xb7a9a6)})
	# the floor's toilet: one tiled cubicle off the corridor, shared by every
	# household on it (Mrs. Chan's, Mrs. Wong's), its cistern on the blue pipe
	b.room({"x0": 1.8, "x1": 3.4, "z0": -14.7, "z1": -13, "y": Y, "name": "Toilet", "id": "toilet", "wall": c8(0xb8c4c0),
		"floor": c8(0x9aa8a8), "floor_surface": "tiles", "wall_surface": "tiles", "skip": ["s"],
		# Stop the tiled returns at the back of the corridor wall.  Letting their
		# end faces reach z=-13 made two vertical tile strips fight through the
		# otherwise solid plaster corridor face.
		"open": {"w": [[-13.3, -13.0]], "e": [[-13.3, -13.0]]}, "lintel": false,
		"parent": "Structure/LevelB"})
	var PT := "Furniture/Toilet"
	PropKit.squat_toilet(b, 2.6, -14.68, Y, PT, Vector3(2.9, Y + 3.3, -14.58), 1.0)
	b.cylinder(Vector3(2.9, Y + 3.3, -12.85), Vector3(2.9, Y + 3.3, -14.58), 0.018, b.surface("metal"), {"parent": PT, "name": "FeedPipe", "tint": c8(0x9aa0a4), "band": 1.0})
	PropKit.bulb(b, Vector3(2.6, Y + 3.1, -13.9), Y + 4.2, PT)
	# the door, left ajar into the cubicle
	var hinge := Node3D.new()
	hinge.name = "ToiletDoor"
	hinge.position = Vector3(2.2, Y, -13.0)
	hinge.rotation.y = deg_to_rad(70)
	b.attach(hinge, b.group(PT))
	# it stands in the doorway, so it's seen from the corridor: tagged with the room
	# so it isn't taken for the cubicle's contents (hidden until Mei is inside)
	b.tag(hinge, 1.0, false, {"room": "toilet"})
	var leaf := b.box(0.0, 0.78, 0.0, 2.05, -0.02, 0.02, c8(0x7a8a6a), {"surface": "metal", "parent_node": hinge, "name": "Leaf"})
	leaf.remove_meta("band")
	var knob := b.box(0.66, 0.72, 1.0, 1.06, 0.02, 0.06, c8(0xc9a55a), {"surface": "metal", "parent_node": hinge, "name": "Knob", "cast_shadow": false})
	knob.remove_meta("band")
	b.card("res://assets/textures/props/sign_toilet.png", Vector3(3.35, Y + 1.85, -13.14), Vector2(0.34, 0.24), Vector3(0, 0, 1), {"parent": "Furniture/CorridorB", "name": "ToiletSign", "band": 1.0})
	var PB := "Furniture/CorridorB"
	PropKit.cardboard(b, 6.2, 7.6, Y, Y + 0.9, -12.95, -12.45, c8(0xa8834f), "ChapterProps/Ch1-4/CorridorB", "n")
	b.add_obstacle(6.2, 7.6, -12.95, -12.45, Y, "stackedBoxes", "chapter:Ch1-4")
	PropKit.cardboard(b, 6.4, 7.4, Y + 0.9, Y + 1.5, -12.9, -12.5, c8(0x9c7a48), "ChapterProps/Ch1-4/CorridorB", "n")
	b.card("res://assets/textures/props/sign_tailor.png", Vector3(-0.8, Y + 3.1, -13.14), Vector2(1.4, 0.7), Vector3(0, 0, 1), {"parent": PB, "name": "TailorSign", "band": 1.0})
	b.card("res://assets/textures/props/poster_0.png", Vector3(1.8, Y + 1.8, -13.14), Vector2(0.5, 0.7), Vector3(0, 0, 1), {"parent": PB, "name": "OperaPoster", "band": 1.0})
	PropKit.bulb(b, Vector3(3, Y + 3.3, -12), Y + 4.2, PB)
	b.box(4.2, 4.8, Y, Y + 0.02, -12.2, -11.6, Color.WHITE, {"material": _decal_mat(b, "puddle"), "parent": PB, "name": "Puddle", "cast_shadow": false})

	# Mrs. Chan's room: tailoring and laundry
	b.room({"x0": -8, "x1": -2, "z0": -16, "z1": -9, "y": Y, "name": "Chan", "id": "chan", "wall": c8(0x8c8294), "floor": c8(0x5a4c4a),
		"open": {"e": [[-13, -11]], "n": [[-6, -4]]}, "parent": "Structure/LevelB"})
	var PCh := "Furniture/Chan"
	PropKit.table(b, -8, -6.6, -11.5, -9.2, Y, 0.85, c8(0x6b4a30), PCh)
	b.add_obstacle(-8, -6.6, -11.5, -9.2, Y, "sewingTable")
	# a treadle sewing machine, and bolts of cloth
	ObjectKit.sewing_machine(b, -7.6, -7.0, Y + 0.85, -10.65, PCh)
	for i in 3:
		# bolts of cloth wound on their cores
		var z := -10.2 + i * 0.3
		var col: Color = [c8(0xa8534a), c8(0x3f6fa8), c8(0xe8d8b0)][i]
		ModelKit.place(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, -0.4), Vector2(0.1, -0.4), Vector2(0.1, 0.4), Vector2(0, 0.4)], 0.02), 28), Vector3(-7.5, Y + 0.95, z), "fabric", col,
			{"parent": PCh, "name": "ClothBolt", "rotation": Vector3(0, 0, PI / 2)})
		ModelKit.place(b, ModelKit.puck(0.02, 0.81, 0.002, 10), Vector3(-7.905, Y + 0.95, z), "grain", c8(0xc8b890), {"parent": PCh, "name": "BoltCore", "rotation": Vector3(0, 0, -PI / 2), "cast_shadow": false})

	# the big zinc washtub, nearly full, a washboard leaning in it
	ObjectKit.tub(b, Vector3(-3.7, Y, -9.7), 0.48, 0.5, c8(0x5f7a88), c8(0x7fa0b8), 0.85, "ChapterProps/Ch1-4/Chan", "Basin", "Water")
	b.add_obstacle(-4.2, -3.2, -10.2, -9.2, Y, "basin", "chapter:Ch1-4")
	ModelKit.place(b, ModelKit.rbox(Vector3(0.36, 0.55, 0.02), 0.008), Vector3(-3.55, Y + 0.38, -9.6), "timber", c8(0xb89a70),
		{"parent": "ChapterProps/Ch1-4/Chan", "name": "Washboard", "rotation": Vector3(-0.35, 0.4, 0)})
	b.box(-8, -7.2, Y, Y + 1.8, -15.9, -14.2, c8(0x5d4632), {"surface": "wood", "parent": PCh, "name": "Cabinet"})
	b.add_obstacle(-8, -7.2, -15.9, -14.2, Y, "chanCabinet")
	# a bunk along the west wall: Mrs. Chan below, Wai on top
	b.box(-8, -7.05, Y, Y + 0.35, -14.1, -11.9, c8(0x6b4a30), {"surface": "timber", "parent": PCh, "name": "BedFrame"})
	ModelKit.place(b, ModelKit.cushion(Vector3(0.87, 0.15, 2.12), 0.045, 0.012, 0.006), Vector3(-7.525, Y + 0.425, -13.0), "fabric", c8(0xd8cfc0), {"parent": PCh, "name": "Mattress"})
	ModelKit.place(b, ModelKit.cushion(Vector3(0.9, 0.05, 1.54), 0.022, 0.008, 0.0), Vector3(-7.525, Y + 0.52, -12.73), "fabric", c8(0x7a5a8a), {"parent": PCh, "name": "Blanket"})
	ModelKit.place(b, ModelKit.cushion(Vector3(0.55, 0.09, 0.38), 0.035, 0.03, 0.008), Vector3(-7.525, Y + 0.55, -13.81), "fabric", c8(0xf0ebdf), {"parent": PCh, "name": "Pillow"})
	PropKit.bunk_top(b, -8, -7.05, -14.1, -11.9, Y, c8(0x6b4a30), c8(0xd8cfc0), c8(0x3f6fa8), PCh)
	b.add_obstacle(-8, -7.0, -14.1, -11.9, Y, "chanBunk")
	# cooking on the east wall, the kitchen god watching from above the stove
	PropKit.kitchen_counter(b, -2.6, -2.0, -15.4, -13.6, Y, PCh, "e")
	# the kitchen god: a red niche on the wall under a little roof, a ledge with
	# a cup of tea and three sticks of incense in a tin
	b.box(-2.1, -2.02, Y + 1.45, Y + 1.78, -14.85, -14.55, c8(0xb8392e), {"surface": "timber", "parent": PCh, "name": "KitchenGod"})
	ModelKit.box(b, -2.16, -2.0, Y + 1.78, Y + 1.81, -14.89, -14.51, c8(0x8a2a22), {"surface": "timber", "parent": PCh, "name": "KitchenGodRoof", "radius": 0.008})
	ModelKit.box(b, -2.11, -2.1, Y + 1.5, Y + 1.74, -14.82, -14.58, c8(0xe0b840), {"surface": "grain", "parent": PCh, "name": "KitchenGodPaper", "radius": 0.001, "cast_shadow": false})
	b.box(-2.2, -2.1, Y + 1.45, Y + 1.5, -14.8, -14.6, c8(0x8a2a22), {"surface": "timber", "parent": PCh, "name": "KitchenGodLedge", "cast_shadow": false})
	ObjectKit.cup(b, Vector3(-2.15, Y + 1.5, -14.65), 0.018, 0.025, c8(0xf2eee4), PCh, "Offering", false)
	ModelKit.place(b, ModelKit.puck(0.02, 0.035, 0.003, 14), Vector3(-2.15, Y + 1.5, -14.74), "metal", c8(0xc9a55a), {"parent": PCh, "name": "IncenseTin"})
	for k in 3:
		ModelKit.place(b, ModelKit.tube([Vector3.ZERO, Vector3(0, 0.15, (k - 1) * 0.012)], 0.0022, 0.0, 5), Vector3(-2.15, Y + 1.53, -14.74 + (k - 1) * 0.006), "grain", c8(0xc84a3a),
			{"parent": PCh, "name": "Incense", "cast_shadow": false})
	PropKit.shelf(b, -3.9, -2.2, -15.9, -15.5, Y + 1.4, 1.2, c8(0x6b4a30), PCh, 2)
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(-2.05, Y + 1.9, -10.5), Vector2(0.4, 0.6), Vector3(-1, 0, 0), {"parent": PCh, "name": "Calendar", "band": 1.0})
	# the line runs wall to wall; the washing starts past the cabinet (x -8 to -7.2), so nothing hangs through it
	laundry_line(b, -7.0, -2.4, Y + 2.8, -14.6, "x", [c8(0xd8c4a0), c8(0x5a7ab0), c8(0xe8e2d4), c8(0xb0504a)], "ChapterProps/Ch1-4/Chan", [-8.0, -2.0])
	PropKit.bulb(b, Vector3(-5, Y + 3.2, -12.5), Y + 4.2, PCh)

	# The catwalk: open-air, over the light well
	b.add_floor(12, 24, -13, -11, Y, "catwalk")
	var PW := "Structure/LevelB/Catwalk"
	b.box(12, 24, Y - 0.15, Y, -13, -11, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": PW, "name": "Grating"})
	var x := 12.5
	while x < 24:
		b.box(x, x + 0.08, Y - 1.2, Y - 0.15, -12.1, -11.9, c8(0x3a3a3a), {"band": 1.0, "surface": "rust", "parent": PW, "name": "Strut"})
		x += 1.5
	for z in [-13.05, -10.95]:
		# the north rail opens where the footbridge crosses to the ledge
		var spans := [[12.0, BuildLightWell.BRIDGE_X[0]], [BuildLightWell.BRIDGE_X[1], 24.0]] if z < -12 else [[12.0, 24.0]]
		for sp in spans:
			b.box(sp[0], sp[1], Y + 0.95, Y + 1.02, z - 0.04, z + 0.04, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": PW, "name": "Rail"})
			b.box(sp[0], sp[1], Y + 0.45, Y + 0.49, z - 0.02, z + 0.02, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": PW, "name": "MidRail"})
		var px := 12.0
		while px <= 24.01:
			var in_gap: bool = z < -12 and px > BuildLightWell.BRIDGE_X[0] - 0.1 and px < BuildLightWell.BRIDGE_X[1] + 0.05
			if not in_gap:
				b.box(px, px + 0.06, Y, Y + 1.0, z - 0.03, z + 0.03, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": PW, "name": "Post"})
			px += 1.0
		if z < -12:
			for bx in BuildLightWell.BRIDGE_X:
				b.box(bx - 0.03, bx + 0.03, Y, Y + 1.0, z - 0.03, z + 0.03, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": PW, "name": "Post"})
	PropKit.bulb(b, Vector3(18, Y + 2.9, -11.2), Y + 3.6, PW)

	# The wet washing. The same object later hangs on the roof.
	var fabric := Node3D.new()
	fabric.name = "Fabric"
	fabric.position = Vector3(16, Y + 2.6, -12)
	b.attach(fabric, b.group("Special"))
	b.tag(fabric, 1.0, false, {"dynamic": true})
	var cols := [c8(0x3f6fa8), c8(0xc9a55a), c8(0xa8534a)]
	# narrow enough that the outer two hang clear of the catwalk rails (1.05 out from the line's middle)
	for i in 3:
		var cloth := b.box(-0.02, 0.02, -2.05, -0.05, -0.22, 0.22, cols[i], {"surface": "fabric", "parent_node": fabric, "name": "Cloth"})
		cloth.position = Vector3(0, -1.05, -0.56 + i * 0.56)
		cloth.remove_meta("band")
		cloth.set_meta("cloth", true)
	var line := b.box(-0.02, 0.02, -0.02, 0.02, -1.2, 1.2, c8(0x222222), {"surface": "grain", "parent_node": fabric, "name": "Line"})
	line.remove_meta("band")
	b.add_obstacle(15.7, 16.3, -13, -11, Y, "fabric", "fabric")
	# drips under it
	b.box(15.4, 16.6, Y + 0.001, Y + 0.01, -12.9, -11.1, Color.WHITE, {"material": _decal_mat(b, "puddle"), "parent": "Special", "name": "FabricDrips", "cast_shadow": false})

	# the folded bundle the Chan boy carries between the catwalk and the roof
	var bundle := Node3D.new()
	bundle.name = "Bundle"
	b.attach(bundle, b.group("Special"))
	b.tag(bundle, 1.0, false, {"dynamic": true})
	for i in 3:
		var m := b.box(-0.31, 0.31, i * 0.1, i * 0.1 + 0.1, -0.21, 0.21, cols[i], {"surface": "fabric", "parent_node": bundle, "name": "Folded"})
		m.remove_meta("band")
	bundle.visible = false
	b.ref("fabricPos", Vector3(15.3, Y, -12))

	# Mrs. Wong
	b.room({"x0": 24, "x1": 31, "z0": -16, "z1": -8, "y": Y, "name": "Wong", "id": "wong", "floor_surface": "wood",
		"wall": c8(0xa38a86), "floor": c8(0x6b5244), "open": {"w": [[-13, -11]]}, "parent": "Structure/LevelB"})
	var PWo := "Furniture/Wong"
	# what her daughter takes when she comes for her early (Chapter 5)
	var PWo4 := "ChapterProps/Ch1-4/Wong"
	PropKit.bed(b, 28.6, 31, -9.8, -8, Y, c8(0x8a6f5a), c8(0xe8dcc8), PWo4, false)
	b.add_obstacle(28.6, 31, -9.8, -8, Y, "wongBed")
	PropKit.altar(b, 29.8, 31, Y, Y + 1.3, -16, -15, PWo4, -1.0)
	b.add_obstacle(29.8, 31, -16, -15, Y, "wongAltar", "chapter:Ch1-4")
	PropKit.table(b, 25, 26.2, -15.6, -14.4, Y, 0.5, c8(0x6b4a30), PWo)
	b.add_obstacle(25, 26.2, -15.6, -14.4, Y, "wongTable")
	ObjectKit.thermos(b, Vector3(25.45, Y + 0.5, -15.05), 0.06, 0.3, c8(0x4f7f70), PWo4)
	ObjectKit.cup(b, Vector3(25.8, Y + 0.5, -14.9), 0.04, 0.075, c8(0xf2eee4), PWo4, "Cup", true, Vector3(1, 0, 0.3))
	ObjectKit.wardrobe(b, 24.1, 24.9, Y, 2.0, -9.5, -8.1, Vector3(1, 0, 0), c8(0x5d4632), PWo)
	b.add_obstacle(24.1, 24.9, -9.5, -8.1, Y, "wardrobe")
	PropKit.stool(b, 27.2, -14.3, Y, c8(0xc9463a), PWo4)
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(27.5, Y + 1.9, -15.95), Vector2(0.4, 0.6), Vector3(0, 0, 1), {"parent": PWo, "name": "Calendar", "band": 1.0})
	PropKit.bulb(b, Vector3(27.5, Y + 3.2, -12), Y + 4.2, PWo)
	# her cooking corner under the calendar; the fan turned on her
	PropKit.kitchen_counter(b, 26.6, 28.5, -15.99, -15.4, Y, PWo, "n")
	PropKit.fan(b, 30.3, -11.5, Y, PWo4, Vector3(28.6, Y, -12.6) - Vector3(30.3, Y, -11.5))


static func _decal_mat(b: LevelBuilder, tex: String) -> StandardMaterial3D:
	var m := b.card_material("res://assets/textures/props/%s.png" % tex)
	var d := m.duplicate() as StandardMaterial3D
	d.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d.roughness = 0.1
	d.metallic_specular = 0.8
	return d


## Washing on a cord between a0 and a1. `walls`: [w0, w1] runs the cord on to
## hooks screwed into the walls there, with the washing still only over a0..a1.
static func laundry_line(b: LevelBuilder, a0: float, a1: float, y: float, fixed: float, axis: String, colors: Array, parent: String, walls := []) -> void:
	var len := absf(a1 - a0)
	var c0: float = walls[0] if walls.size() == 2 else a0
	var c1: float = walls[1] if walls.size() == 2 else a1
	if axis == "x":
		b.box(c0, c1, y, y + 0.03, fixed - 0.015, fixed + 0.015, c8(0x222222), {"surface": "grain", "parent": parent, "name": "Line", "cast_shadow": false})
	else:
		b.box(fixed - 0.015, fixed + 0.015, y, y + 0.03, c0, c1, c8(0x222222), {"surface": "grain", "parent": parent, "name": "Line", "cast_shadow": false})
	if walls.size() == 2:
		for wv in walls:
			# a hook: a plate on the wall and the eye the cord is tied through
			var d: float = 0.06 if wv == walls[0] else -0.06
			var lo := minf(wv, wv + d)
			var hi := maxf(wv, wv + d)
			if axis == "x":
				b.box(wv - 0.01, wv + 0.01, y - 0.06, y + 0.09, fixed - 0.05, fixed + 0.05, c8(0x5a5a58), {"surface": "metal", "parent": parent, "name": "LineHook", "cast_shadow": false})
				b.box(lo, hi, y - 0.02, y + 0.05, fixed - 0.025, fixed + 0.025, c8(0x5a5a58), {"surface": "metal", "parent": parent, "name": "LineHook", "cast_shadow": false})
			else:
				b.box(fixed - 0.05, fixed + 0.05, y - 0.06, y + 0.09, wv - 0.01, wv + 0.01, c8(0x5a5a58), {"surface": "metal", "parent": parent, "name": "LineHook", "cast_shadow": false})
				b.box(fixed - 0.025, fixed + 0.025, y - 0.02, y + 0.05, lo, hi, c8(0x5a5a58), {"surface": "metal", "parent": parent, "name": "LineHook", "cast_shadow": false})
	for i in colors.size():
		var t := (i + 0.5) / colors.size()
		var a := a0 + (a1 - a0) * t
		var h := 0.9 + b.rand.randf() * 0.7
		var w := len / colors.size() * 0.8
		var cloth: MeshInstance3D
		if axis == "x":
			cloth = b.box(a - w / 2, a + w / 2, y - h, y, fixed - 0.015, fixed + 0.015, colors[i], {"surface": "fabric", "parent": parent, "name": "Cloth", "band": b.band_of(y - h + 0.3)})
		else:
			cloth = b.box(fixed - 0.015, fixed + 0.015, y - h, y, a - w / 2, a + w / 2, colors[i], {"surface": "fabric", "parent": parent, "name": "Cloth", "band": b.band_of(y - h + 0.3)})
		cloth.set_meta("cloth", true)
		# pegs
		if axis == "x":
			b.box(a - w / 2 + 0.04, a - w / 2 + 0.07, y - 0.04, y + 0.04, fixed - 0.03, fixed + 0.03, c8(0xe0c060), {"surface": "wood", "parent": parent, "name": "Peg", "cast_shadow": false})


## A plywood tea chest: corners and edges bound in tin strip, a stencilled
## mark on its side. `opts` go to the body (collision and the like).
static func tea_chest(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, col: Color, parent: String, opts: Dictionary) -> void:
	var o := {"surface": "timber", "parent": parent, "name": "TeaChest"}
	o.merge(opts, true)
	b.box(x0, x1, y0, y1, z0, z1, col, o)
	var bd: float = opts.get("band", b.band_of(y0 + 0.5))
	var tin := c8(0xb8b4a8)
	var eo := {"surface": "metal", "parent": parent, "name": "TinStrip", "band": bd, "radius": 0.002, "cast_shadow": false}
	for x in [x0 - 0.004, x1 - 0.026]:
		for z in [z0 - 0.004, z1 - 0.026]:
			ModelKit.box(b, x, x + 0.03, y0, y1, z, z + 0.03, tin, eo)
	for y in [y0, y1 - 0.025]:
		ModelKit.box(b, x0 - 0.004, x1 + 0.004, y, y + 0.025, z1, z1 + 0.004, tin, eo)
		ModelKit.box(b, x0 - 0.004, x1 + 0.004, y, y + 0.025, z0 - 0.004, z0, tin, eo)
	b.card("res://assets/textures/props/carton_label_%d.png" % [2 if PropKit._rng(Vector3(x0, y0, z0)).randi() % 2 == 0 else 4],
		Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z1 + 0.005), Vector2((x1 - x0) * 0.6, (x1 - x0) * 0.4), Vector3(0, 0, 1),
		{"parent": parent, "name": "Stencil", "band": bd})


# ----------------------------------------------------------------------------- the mahjong game


## A hand in the middle of play, seen as it would be in the evening: each
## player's thirteen stood up and sorted, the wall two high and broken where
## the deal began, the discards face up in front of whoever threw them.
## `centre` is the middle of the cloth, on its surface.
static func _mahjong_game(b: LevelBuilder, centre: Vector3, parent: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1984
	var deck: Array[String] = []
	for k in MahjongKit.SUITED:
		for n in 4:
			deck.append(MahjongKit.FACES[k])
	for i in range(deck.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := deck[i]
		deck[i] = deck[j]
		deck[j] = t

	var pitch := MahjongKit.SIZE.x + 0.002
	var jitter := func(v: Vector3, amount: float) -> Vector3:
		return v.rotated(Vector3.UP, rng.randf_range(-amount, amount))
	# the seats: where each sits, measured out from the middle, and the way
	# along the table edge from their left hand to their right
	var seats := [
		{"out": Vector3(0, 0, -1), "hand": 0.58, "wall": 0.33, "discard": 0.2, "span": 15, "drawn": 6},  # the empty stool by the corridor
		{"out": Vector3(1, 0, 0), "hand": 0.73, "wall": 0.42, "discard": 0.25, "span": 11, "drawn": 0},  # mahjong2
		{"out": Vector3(0, 0, 1), "hand": 0.58, "wall": 0.33, "discard": 0.2, "span": 15, "drawn": 0},  # mahjong3
		{"out": Vector3(-1, 0, 0), "hand": 0.73, "wall": 0.42, "discard": 0.25, "span": 11, "drawn": 0},  # mahjong1
	]
	for s in 4:
		var seat: Dictionary = seats[s]
		var out: Vector3 = seat.out
		var along := Vector3.UP.cross(out)  # the player's right, looking in
		# the hand: thirteen, sorted the way a player sorts them, faces to the player
		var hand: Array[String] = []
		for n in 13:
			hand.append(deck.pop_back())
		hand.sort_custom(func(p: String, q: String) -> bool: return MahjongKit.FACES.find(p) < MahjongKit.FACES.find(q))
		for i in 13:
			var at: Vector3 = centre + out * seat.hand + along * (i - 6) * pitch
			at += out * rng.randf_range(-0.003, 0.003)
			MahjongKit.standing(b, hand[i], at, jitter.call(out, 0.03), parent, {"name": "Hand"})
		# the wall: face-down stacks two high, the near end drawn away
		var span: int = seat.span
		for i in range(seat.drawn, span):
			var at: Vector3 = centre + out * seat.wall + along * (i - (span - 1) * 0.5) * (pitch - 0.001)
			# the last stack on mahjong2's side is down to one: the replacement tile went
			var layers := 1 if s == 1 and i == span - 1 else 2
			for layer in layers:
				var lift := Vector3(0, layer * (MahjongKit.SIZE.z + 0.0004), 0)
				MahjongKit.lying(b, MahjongKit.FACES[rng.randi() % MahjongKit.SUITED], at + lift, jitter.call(out, 0.02), false, parent, {"name": "Wall"})
		# the discards: a row in front of their own wall, read from their seat
		var count := 6 if s % 2 == 0 else 5
		for i in count:
			var at: Vector3 = centre + out * seat.discard + along * (i - (count - 1) * 0.5) * (pitch + 0.002)
			at += Vector3(rng.randf_range(-0.004, 0.004), 0, rng.randf_range(-0.004, 0.004))
			MahjongKit.lying(b, deck.pop_back(), at, jitter.call(-out, 0.07), true, parent, {"name": "Discard"})


static func _tea_cup(b: LevelBuilder, base: Vector3, parent: String) -> void:
	var cup := CylinderMesh.new()
	cup.top_radius = 0.042
	cup.bottom_radius = 0.032
	cup.height = 0.075
	cup.radial_segments = 20
	cup.rings = 1
	b.piece(cup, base + Vector3(0, cup.height * 0.5, 0), b.surface("grain"), {"parent": parent, "name": "TeaCup", "tint": c8(0xf2eee4), "band": 0.0})
	# the tea, inside a thin white rim
	var tea := CylinderMesh.new()
	tea.top_radius = 0.036
	tea.bottom_radius = 0.036
	tea.height = 0.002
	tea.radial_segments = 20
	b.piece(tea, base + Vector3(0, cup.height + 0.0008, 0), b.surface("fabric"), {"parent": parent, "name": "Tea", "tint": c8(0x7a4a1c), "band": 0.0, "cast_shadow": false})


# ----------------------------------------------------------------------------- airshaft


# ----------------------------------------------------------------------------- only some days
#
# Under ChapterProps/Ch<first>-<last>: taken out of the level on the other days
# (SliceRoot), their obstacles keyed to the same span.


static func chapter_props(b: LevelBuilder) -> void:
	var A := LevelBuilder.LEVEL_A
	# Chapter 2: more boxes packed than a week ago, by the door and along the south wall
	var P2 := "ChapterProps/Ch2"
	var boxes := [[-9.6, -8.8, 3.3, 3.95, 0.7], [-9.5, -8.9, 3.35, 3.9, 0.55, 0.7], [-6.95, -6.2, 2.45, 3.25, 0.65],
		[-11.85, -11.15, 3.35, 3.95, 0.5]]
	for bx in boxes:
		var y0: float = A + (bx[5] if bx.size() > 5 else 0.0)
		PropKit.cardboard(b, bx[0], bx[1], y0, y0 + bx[4], bx[2], bx[3], c8(0xa8834f).lerp(c8(0x8a6a40), b.rand.randf()), P2, "n")
		if bx.size() <= 5:
			b.add_obstacle(bx[0], bx[1], bx[2], bx[3], A, "moreBoxes", "chapter:Ch2")
	# a tea chest of dishes wrapped in newspaper, open by the counter where Mum is packing
	tea_chest(b, -10.35, -9.8, A, A + 0.55, -3.3, -2.75, c8(0x8a6a48), P2, {})
	# dishes wrapped in newspaper, packed in to the top
	for k in 5:
		var wx := -10.22 + (k % 3) * 0.13
		var wz := -3.13 + (k / 3) * 0.2
		ModelKit.place(b, ModelKit.cushion(Vector3(0.13, 0.09, 0.13), 0.04, 0.015, 0.012), Vector3(wx, A + 0.53 + (k % 2) * 0.02, wz), "fabric", c8(0xe8e0cc).darkened(0.05 * (k % 3)),
			{"parent": P2, "name": "WrappedDishes", "rotation": Vector3(0.1 * (k % 2), k * 0.7, 0.08)})
	b.add_obstacle(-10.35, -9.8, -3.3, -2.75, A, "teaChest", "chapter:Ch2")
	# Mr. Ho's stool under the blue pipe in the hall, where he listens to it
	PropKit.stool(b, -3.0, -0.45, A, c8(0x3f6fa8), P2)
	b.ref("hoListen", Vector3(-3.0, A + 0.45, -0.45))
	b.ref("hoWash", Vector3(-5.1, A, 0.25))
	# Chapters 2-4: the red bowl on the counter, the everyday one; packed by Chapter 5
	ObjectKit.rice_bowl(b, Vector3(-9.1, A + 0.8, -3.49), 0.08, c8(0xc0392b), "ChapterProps/Ch2-4", "RedBowl")
	b.ref("redBowl", Vector3(-9.1, A, -2.95))
	# Chapters 2-6: the brochure for the new estate, on the table
	b.box(-11.95, -11.65, A + 0.8, A + 0.806, -0.95, -0.74, c8(0xf2eee4), {"surface": "grain", "parent": "ChapterProps/Ch2-6", "name": "Brochure"})
	b.box(-11.93, -11.67, A + 0.806, A + 0.808, -0.93, -0.84, c8(0x3f86d1), {"surface": "grain", "parent": "ChapterProps/Ch2-6", "name": "BrochureBand", "cast_shadow": false})
	b.ref("brochure", Vector3(-11.8, A, -0.85))


static func airshaft(b: LevelBuilder) -> void:
	## The way up is a ladder on the west wall that runs all the way to the roof,
	## but its bottom rungs have rusted away. An old crate sits in the far corner,
	## hidden behind a broken fridge from the way you walk in: turn the view to
	## find it, push it under the ladder, and climb.
	var Y := LevelBuilder.LEVEL_B
	var R := LevelBuilder.LEVEL_ROOF
	var P := "Structure/Airshaft"
	b.room({"x0": -7, "x1": -3, "z0": -21, "z1": -16, "y": Y, "name": "Airshaft", "wall_surface": "concrete", "floor_surface": "concrete",
		"wall": c8(0x6e716b), "floor": c8(0x3e403c), "h": 8.2, "skip": ["s"], "band": 1.0, "wall_band": 1.0, "parent": "Structure"})
	b.box(-6.6, -4.4, Y, Y + 0.02, -20.9, -20.5, c8(0x3a3a3a), {"band": 1.0, "surface": "rust", "parent": P, "name": "DrainGrate", "cast_shadow": false})
	b.box(-6.9, -3.1, Y + 0.001, Y + 0.01, -18.2, -17.0, Color.WHITE, {"material": _decal_mat(b, "puddle"), "parent": P, "name": "Puddle", "band": 1.0, "cast_shadow": false})

	# the ladder: from well above head height all the way to the roof rim
	var ladder := Node3D.new()
	ladder.name = "Ladder"
	b.attach(ladder, b.group("Special"))
	b.tag(ladder, 1.0)
	for z in [-20.28, -19.68]:
		var rail := b.box(-6.96, -6.86, Y + 1.75, R + 0.9, z, z + 0.08, c8(0x8a5a3a), {"surface": "rust", "parent_node": ladder, "name": "Rail"})
		rail.remove_meta("band")
		var stub := b.box(-6.96, -6.86, Y + 0.0, Y + 0.28, z, z + 0.08, c8(0x6a3a22), {"surface": "rust", "parent_node": ladder, "name": "RustedStub"})
		stub.remove_meta("band")
	var ry := Y + 1.95
	while ry < R + 0.7:
		var rung := b.box(-6.94, -6.86, ry, ry + 0.05, -20.26, -19.62, c8(0x8a5a3a), {"surface": "rust", "parent_node": ladder, "name": "Rung"})
		rung.remove_meta("band")
		ry += 0.35
	for k in 3:
		var bracket := b.box(-6.99, -6.86, Y + 2.5 + k * 2.4, Y + 2.56 + k * 2.4, -20.34, -19.56, c8(0x5a3a22), {"surface": "rust", "parent_node": ladder, "name": "WallBracket"})
		bracket.remove_meta("band")
	# the rungs that fell, lying where they landed
	b.box(-6.6, -5.9, Y, Y + 0.05, -18.2, -18.14, c8(0x6a3a22), {"band": 1.0, "surface": "rust", "parent": P, "name": "FallenRung", "cast_shadow": false})
	b.box(-5.6, -5.0, Y, Y + 0.05, -18.9, -18.84, c8(0x6a3a22), {"band": 1.0, "surface": "rust", "parent": P, "name": "FallenRung", "cast_shadow": false})

	# a broken fridge in the north-east corner, and the crate behind it
	# an old round-shouldered fridge on its feet, its door seal perished, its chrome handle dull
	ModelKit.place(b, ModelKit.rbox(Vector3(0.8, 1.65, 0.7), 0.08, 3), Vector3(-3.55, Y + 0.875, -19.1), "metal", c8(0xd8d8cc), {"band": 1.0, "parent": P, "name": "BrokenFridge"})
	ModelKit.box(b, -3.9, -3.2, Y + 1.25, Y + 1.27, -18.76, -18.74, c8(0x3a3a38), {"band": 1.0, "surface": "grain", "parent": P, "name": "DoorSeal", "radius": 0.006, "cast_shadow": false})
	ModelKit.place(b, ModelKit.tube([Vector3(0, 0, 0), Vector3(0, 0, 0.04), Vector3(0, 0.25, 0.04), Vector3(0, 0.25, 0)], 0.012, 0.02, 8), Vector3(-3.25, Y + 0.95, -18.75), "metal", c8(0xb8bcbc),
		{"band": 1.0, "parent": P, "name": "FridgeHandle", "cast_shadow": false})
	for fx in [-3.85, -3.25]:
		ModelKit.place(b, ModelKit.puck(0.03, 0.05, 0.008, 10), Vector3(fx, Y, -18.9), "grain", c8(0x2a2a2a), {"band": 1.0, "parent": P, "name": "FridgeFoot"})
	b.add_obstacle(-3.95, -3.15, -19.45, -18.75, Y, "fridge")
	b.ref("fridgeMin", Vector3(-3.95, Y, -19.45))
	b.ref("fridgeMax", Vector3(-3.15, Y + 1.7, -18.75))
	var crate := Node3D.new()
	crate.name = "Crate"
	crate.position = Vector3(-3.55, Y, -19.95)
	b.attach(crate, b.group("Special"))
	b.tag(crate, 1.0, false, {"dynamic": true})
	var cm := b.box(-0.35, 0.35, 0, 0.7, -0.35, 0.35, c8(0x9a7448), {"surface": "wood", "parent_node": crate, "name": "Box"})
	cm.remove_meta("band")
	for bx in [[-0.36, -0.33], [0.33, 0.36]]:
		for lvl in [[0.05, 0.12], [0.58, 0.65]]:
			var slat := b.box(bx[0], bx[1], lvl[0], lvl[1], -0.36, 0.36, c8(0x6a4a2a), {"surface": "wood", "parent_node": crate, "name": "Slat"})
			slat.remove_meta("band")
	var stencil := b.box(-0.2, 0.2, 0.25, 0.45, 0.351, 0.356, c8(0x3a2a1a), {"surface": "grain", "parent_node": crate, "name": "Stencil", "cast_shadow": false})
	stencil.remove_meta("band")
	b.add_obstacle(-3.9, -3.2, -20.3, -19.6, Y, "crate", "crate")
	b.ref("crateStart", Vector3(-3.55, Y, -19.95))
	b.ref("crateEnd", Vector3(-6.45, Y, -19.95))

	# the shaft's own clutter: the old shop sign, a laundry pole, an AC unit, a platform
	b.box(-4.7, -3.0, Y + 4.1, Y + 4.5, -19.8, -19.0, c8(0xa8534a), {"band": 1.0, "surface": "metal", "parent": P, "name": "OldShopSign"})
	b.box(-4.72, -4.68, Y + 4.12, Y + 4.48, -19.75, -19.05, c8(0xe8c070), {"band": 1.0, "material": b.emissive(c8(0xe8c070), 0.6, false), "parent": P, "name": "SignFace"})
	b.box(-6.8, -3, Y + 5.5, Y + 5.62, -17.3, -17.18, c8(0x7a7a70), {"band": 1.0, "surface": "metal", "parent": P, "name": "LaundryPole"})
	PropKit.ac_unit(b, -4.6, -3.4, Y + 2.1, Y + 2.8, -20.95, -20.1, P, 1.0)
	b.box(-4.5, -3.5, Y + 2.2, Y + 2.7, -20.12, -20.08, c8(0x555555), {"band": 1.0, "surface": "metal", "parent": P, "name": "ACGrille"})
	b.box(-5.2, -3.3, Y + 6.4, Y + 6.6, -20.95, -19.7, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": P, "name": "Platform"})
	for k in 4:
		b.cylinder(Vector3(-6.97, Y + 1 + k * 1.7, -16.2), Vector3(-6.97, Y + 1 + k * 1.7, -18.4), 0.015, b.surface("grain"), {"parent": P, "name": "Cable", "tint": c8(0x1c1c1e), "band": 1.0, "cast_shadow": false})
	# a neighbour's window onto the shaft: dark glass in a painted frame, a sill under it
	b.box(-3.03, -3.0, Y + 2.2, Y + 3.2, -17.8, -16.6, c8(0x3a4650), {"band": 1.0, "material": b.glass(true), "parent": P, "name": "Window"})
	for fz in [[-17.85, -17.8], [-16.6, -16.55], [-17.24, -17.18]]:
		b.box(-3.07, -3.0, Y + 2.15, Y + 3.25, fz[0], fz[1], c8(0x5a6a60), {"band": 1.0, "surface": "timber", "parent": P, "name": "WindowFrame"})
	for fy in [[Y + 2.15, Y + 2.2], [Y + 3.2, Y + 3.25], [Y + 2.68, Y + 2.72]]:
		b.box(-3.07, -3.0, fy[0], fy[1], -17.85, -16.55, c8(0x5a6a60), {"band": 1.0, "surface": "timber", "parent": P, "name": "WindowFrame"})
	b.box(-3.12, -3.0, Y + 2.1, Y + 2.15, -17.9, -16.5, c8(0x8a8a80), {"band": 1.0, "surface": "concrete", "parent": P, "name": "Sill"})

	b.ref("shaftBase", Vector3(-5, Y, -18.2))
	# onto the crate, straight up the ladder, over the rim onto the roof
	b.data.climb_nodes = [
		Vector3(-5.7, Y, -19.95),
		Vector3(-6.25, Y + 0.7, -19.95),
		Vector3(-6.68, Y + 0.7, -19.95),
		Vector3(-6.68, R + 0.4, -19.95),
		Vector3(-7.3, R + 0.45, -19.95),
		Vector3(-7.8, R, -19.95),
	]


# ----------------------------------------------------------------------------- roof


static func roof(b: LevelBuilder) -> void:
	var Y := LevelBuilder.LEVEL_ROOF
	var P := "Structure/Roof"
	var rects := [[-10, 12, -16, -6], [-10, -7, -24, -16], [-3, 12, -24, -16], [-7, -3, -24, -21]]
	for r in rects:
		b.add_floor(r[0], r[1], r[2], r[3], Y, "roof")
		b.box(r[0], r[1], Y - 0.5, Y, r[2], r[3], c8(0x9a968a), {"band": 2.0, "surface": "tar", "parent": P, "name": "RoofSlab"})
	# parapets, with a coping and the odd plant pot on them
	var pa := 0.9
	b.box(-10.3, 12.3, Y, Y + pa, -24.3, -24, c8(0x8d897f), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Parapet"})
	b.box(-10.3, 12.3, Y, Y + pa, -6, -5.7, c8(0x8d897f), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Parapet"})
	b.box(-10.3, -10, Y, Y + pa, -24, -6, c8(0x8d897f), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Parapet"})
	b.box(12, 12.3, Y, Y + pa, -24, -6, c8(0x8d897f), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Parapet"})
	b.box(-10.35, 12.35, Y + pa, Y + pa + 0.06, -24.35, -23.95, c8(0xa29e94), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Coping"})
	b.box(-10.35, 12.35, Y + pa, Y + pa + 0.06, -6.05, -5.65, c8(0xa29e94), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Coping"})
	# shaft rim
	b.box(-7.2, -2.8, Y, Y + 0.35, -21.2, -21, c8(0x6d6a60), {"band": 2.0, "surface": "concrete", "parent": P, "name": "ShaftRim"})
	b.box(-7.2, -7, Y, Y + 0.35, -21, -16, c8(0x6d6a60), {"band": 2.0, "surface": "concrete", "parent": P, "name": "ShaftRim"})
	b.box(-3, -2.8, Y, Y + 0.35, -21, -16, c8(0x6d6a60), {"band": 2.0, "surface": "concrete", "parent": P, "name": "ShaftRim"})

	# the stair hut and its door never fade: it's Mei's way back down, and the
	# roof's one landmark, so it stays solid wherever she stands up here
	b.box(8.8, 11.6, Y, Y + 2.8, -15, -12.4, c8(0x7a7466), {"band": 2.0, "collide": true, "collide_y": Y,
		"surface": "plaster", "top": "tar", "parent": P, "name": "StairHut", "base_y": Y})
	panel_door(b, 9.9, 10.9, Y, 2.2, -12.4, c8(0x56705f), P, 2.0, "HutDoor")
	b.piece(BuildCity.corrugated(3.1, 3.0), Vector3(10.2, Y + 2.86, -13.65), b.surface("rust"), {"band": 2.0, "parent": P, "name": "HutRoof", "tint": c8(0x9a9690), "rotation": Vector3(0.06, 0, 0)})
	b.box(8.75, 11.65, Y + 2.8, Y + 2.86, -15.05, -12.3, c8(0x7a7466), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Coping"})
	# a caged bulb over the door, its conduit down the wall, and a vent brick
	var lamp := Vector3(10.4, Y + 2.45, -12.33)
	ModelKit.place(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.07, 0), Vector2(0.06, 0.03), Vector2(0, 0.035)], 0.01), 16), lamp + Vector3(0, 0.08, 0), "metal", c8(0x3a4a3a),
		{"band": 2.0, "parent": P, "name": "HutLampHood", "rotation": Vector3(PI, 0, 0)})
	b.piece(PropKit._sphere(0.035), lamp, b.emissive(c8(0xffd890), 3.0), {"band": 2.0, "parent": P, "name": "HutLamp", "cast_shadow": false})
	ModelKit.place(b, ModelKit.tube([Vector3(0, 0.08, 0.0), Vector3(0, 0.08, -0.02), Vector3(0, 0.33, -0.02)], 0.012, 0.02, 6), lamp, "metal", c8(0x5a5a58), {"band": 2.0, "parent": P, "name": "Conduit", "cast_shadow": false})
	for k in 3:
		b.box(9.0 + k * 0.08, 9.05 + k * 0.08, Y + 2.3, Y + 2.55, -12.4, -12.37, c8(0x3a3632), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Vent", "cast_shadow": false})
	b.ref("roofDoorTop", Vector3(10.4, Y, -11.8))
	b.ref("shaftTop", Vector3(-7.8, Y, -19.95))

	# Mr. Ng's pigeon coop: a timber frame with wire mesh, perches inside
	var PC := "Structure/Roof/Coop"
	# the roof, laid round a small trap in it: Mr. Ng's birds come home through
	# the top, and a hinged flap drops shut behind them
	var roof_col := c8(0x6b4a30)
	var ro := {"band": 2.0, "surface": "wood", "parent": PC, "name": "CoopRoof"}
	b.box(0.9, 3.85, Y + 2.2, Y + 2.35, -23.7, -21.5, roof_col, ro)
	b.box(4.65, 5.1, Y + 2.2, Y + 2.35, -23.7, -21.5, roof_col, ro)
	b.box(3.85, 4.65, Y + 2.2, Y + 2.35, -23.7, -22.8, roof_col, ro)
	b.box(3.85, 4.65, Y + 2.2, Y + 2.35, -22.1, -21.5, roof_col, ro)
	# the flap: hinged along its west edge, lifted by a bird pushing up under it
	# or dropping onto it, and falling shut again with a clack
	var flap := Node3D.new()
	flap.name = "CoopFlap"
	flap.position = Vector3(3.85, Y + 2.35, -22.45)
	b.attach(flap, b.group("Special"))
	b.tag(flap, 2.0)
	var board := b.box(0.0, 0.8, -0.12, 0.0, -0.345, 0.345, c8(0x7a5638), {"surface": "wood", "parent_node": flap, "name": "FlapBoard"})
	board.remove_meta("band")
	for hz in [-0.24, 0.24]:
		var hinge := b.box(-0.03, 0.08, -0.01, 0.02, hz - 0.04, hz + 0.04, c8(0x5a5a55), {"surface": "metal", "parent_node": flap, "name": "Hinge", "cast_shadow": false})
		hinge.remove_meta("band")
	var knob := b.box(0.7, 0.76, 0.0, 0.04, -0.03, 0.03, c8(0x3a3a3a), {"surface": "metal", "parent_node": flap, "name": "Pull", "cast_shadow": false})
	knob.remove_meta("band")
	b.ref("coopHole", Vector3(4.25, Y + 2.35, -22.45))
	b.box(0.9, 5.1, Y, Y + 0.2, -23.7, -21.5, c8(0x6b4a30), {"band": 2.0, "surface": "wood", "parent": PC, "name": "CoopFloor"})
	for x in [0.95, 5.0]:
		for z in [-23.65, -21.55]:
			b.box(x, x + 0.12, Y, Y + 2.2, z - 0.06, z + 0.06, c8(0x5d4632), {"band": 2.0, "surface": "wood", "parent": PC, "name": "CoopPost"})
	var mesh_mat := _wire_mesh_material()
	for f in [[3.0, -21.5, 4.2, 2.0, 0.0], [3.0, -23.7, 4.2, 2.0, PI], [0.9, -22.6, 2.2, 2.0, -PI / 2], [5.1, -22.6, 2.2, 2.0, PI / 2]]:
		var q := QuadMesh.new()
		q.size = Vector2(f[2], f[3])
		b.piece(q, Vector3(f[0], Y + 1.2, f[1]), mesh_mat, {"band": 2.0, "parent": PC, "name": "WireMesh", "rotation": Vector3(0, f[4], 0)})
	for k in 2:
		b.box(1.1, 4.9, Y + 1.1 + k * 0.5, Y + 1.14 + k * 0.5, -23.2 + k * 0.4, -23.1 + k * 0.4, c8(0x8a6f5a), {"band": 2.0, "surface": "wood", "parent": PC, "name": "Perch"})
	b.add_obstacle(0.9, 5.1, -23.7, -21.5, Y, "coop")
	b.ref("coopPos", Vector3(3, Y + 0.3, -22.4))
	b.ref("coop", Vector3(3, Y, -21))

	# water tank on a stand: four legs carry a steel deck, and the tank sits on the deck
	var TS := {"band": 2.0, "surface": "rust", "parent": "Special/TankStand"}
	for xz in [[8.1, -22.3], [10.2, -22.3], [8.1, -20.1], [10.2, -20.1]]:
		b.box(xz[0], xz[0] + 0.15, Y, Y + 2.2, xz[1], xz[1] + 0.15, c8(0x555555), TS.merged({"name": "TankLeg"}))
	b.box(8.02, 10.43, Y + 2.08, Y + 2.2, -22.38, -19.97, c8(0x4f5250), TS.merged({"name": "TankDeck"}))
	for by in [Y + 0.9, Y + 1.9]:
		for z in [-22.3, -20.1]:
			b.box(8.1, 10.35, by, by + 0.07, z + 0.04, z + 0.11, c8(0x555555), TS.merged({"name": "TankBrace", "cast_shadow": false}))
		for x in [8.1, 10.2]:
			b.box(x + 0.04, x + 0.11, by, by + 0.07, -22.3, -19.95, c8(0x555555), TS.merged({"name": "TankBrace", "cast_shadow": false}))
	var cm := CylinderMesh.new()
	cm.top_radius = 1.25
	cm.bottom_radius = 1.25
	cm.height = 2.0
	cm.radial_segments = 28
	var tank := b.piece(cm, Vector3(9.2, Y + 3.2, -21.2), b.surface("rust"), {"band": 2.0, "parent": "Special", "name": "Tank", "tint": c8(0x9aa4a6)})
	var lid := CylinderMesh.new()
	lid.top_radius = 0.2
	lid.bottom_radius = 1.3
	lid.height = 0.3
	lid.radial_segments = 28
	b.piece(lid, Vector3(9.2, Y + 4.35, -21.2), b.surface("rust"), {"band": 2.0, "parent": "Special/TankStand", "name": "TankLid", "tint": c8(0x8a9496)})
	b.add_obstacle(8, 10.4, -22.4, -20, Y, "tank")
	# antenna mast
	b.box(11.2, 11.35, Y, Y + 5.6, -21.3, -21.15, c8(0x444444), {"band": 2.0, "surface": "metal", "parent": P, "name": "Mast"})
	b.box(11.25, 11.3, Y + 4.4, Y + 4.46, -22.6, -19.8, c8(0x444444), {"band": 2.0, "surface": "metal", "parent": P, "name": "Antenna"})
	b.box(11.25, 11.3, Y + 5.0, Y + 5.05, -22.2, -20.2, c8(0x444444), {"band": 2.0, "surface": "metal", "parent": P, "name": "Antenna"})
	# the lost pigeon's bracket on the far (north) side of the tank: from the
	# starting view the tank hides her completely
	b.box(8.9, 9.5, Y + 2.5, Y + 2.56, -22.75, -22.4, c8(0x444444), {"band": 2.0, "surface": "metal", "parent": "Special/TankStand", "name": "Bracket"})
	b.ref("tank", Vector3(9.2, Y, -21.2))

	# a bedsheet pegged out between the tank and the coop: from her perch it
	# hangs right across her view of home
	for z in [-23.65, -21.3]:
		b.box(6.45, 6.55, Y, Y + 2.7, z, z + 0.1, c8(0x5a5a55), {"band": 2.0, "surface": "metal", "parent": P, "name": "SheetPost"})
	b.box(6.48, 6.52, Y + 2.6, Y + 2.64, -23.65, -21.2, c8(0x222222), {"band": 2.0, "surface": "grain", "parent": P, "name": "SheetLine"})
	var sheet := Node3D.new()
	sheet.name = "Sheet"
	sheet.position = Vector3(6.5, Y + 2.6, -22.5)
	b.attach(sheet, b.group("Special"))
	b.tag(sheet, 2.0)
	var cloth := b.box(-0.015, 0.015, -2.0, 0.0, -1.1, 1.1, c8(0xece6d8), {"surface": "fabric", "parent_node": sheet, "name": "Cloth"})
	cloth.remove_meta("band")
	cloth.set_meta("cloth", true)
	b.add_obstacle(6.4, 6.6, -23.6, -21.4, Y, "sheet", "sheet")
	b.ref("sheetSpot", Vector3(7.0, Y, -21.0))
	# off the tank, round over the sheet, a hover over the trap, down through it
	# (clear of the perches) and onto the coop floor
	b.data.pigeon_path = [
		Vector3(9.2, Y + 2.56, -22.6),
		Vector3(8.2, Y + 3.4, -22.9),
		Vector3(6.5, Y + 3.6, -22.6),
		Vector3(5.3, Y + 3.2, -22.5),
		Vector3(4.3, Y + 2.95, -22.45),
		Vector3(4.25, Y + 1.8, -22.45),
		Vector3(3.6, Y + 0.7, -22.35),
		Vector3(3.2, Y + 0.25, -22.3),
	]

	# laundry lines (the washing arrives here later)
	for x in [-9.2, -2.2]:
		b.box(x, x + 0.12, Y, Y + 2.6, -8.6, -8.48, c8(0x5a5a55), {"band": 2.0, "surface": "metal", "parent": P, "name": "LinePost"})
	# the neighbours' washing fills only the west end: the east end is left
	# clear for the Chan boy's sheets, so nothing hangs in the same place
	b.box(-6.6, -2.2, Y + 2.5, Y + 2.53, -8.555, -8.525, c8(0x222222), {"surface": "grain", "parent": "Structure/Roof/Laundry", "name": "Line", "cast_shadow": false})
	laundry_line(b, -9.2, -6.6, Y + 2.5, -8.54, "x", [c8(0xe8e2d4), c8(0x5a7ab0)], "Structure/Roof/Laundry")
	b.ref("roofFabricPos", Vector3(-4.3, Y + 2.5, -8.54))

	# roof clutter: a bench, pots of herbs and chillies, the AC housing, a
	# forest of TV aerials (every flat had its own)
	ObjectKit.bench(b, -9.6, -8.2, -12, -10.6, Y, 0.45, c8(0x6b4a30), P, {"band": 2.0})
	b.add_obstacle(-9.6, -8.2, -12, -10.6, Y, "bench")
	var pots := [[0.25, -9.75, "aspidistra"], [1.25, -9.9, "chilli"], [-0.95, -9.55, "onions"], [2.45, -9.65, "aspidistra"],
		[-0.15, -6.95, "onions"], [0.85, -6.75, "chilli"], [-8.9, -12.4, "aspidistra"], [7.9, -9.6, "chilli"]]
	for i in pots.size():
		plant(b, String(pots[i][2]), Vector3(pots[i][0], Y, pots[i][1]), P + "/Pots", 2.0)
	PropKit.ac_unit(b, 4.5, 6.5, Y, Y + 0.9, -9, -7.2, P, 2.0)
	b.add_obstacle(4.5, 6.5, -9, -7.2, Y, "acHousing")
	for i in 16:
		var ax := -9.5 + b.rand.randf() * 21
		var az := -23.5 + b.rand.randf() * 17
		if ax > -7.5 and ax < -2.5 and az > -21.5 and az < -15.5:
			continue
		if absf(ax - 3) < 3 and az < -20:
			continue
		if ax > 8.5 and ax < 11.8 and az > -15.3 and az < -12.1:
			continue
		var h := 2.5 + b.rand.randf() * 3
		_aerial(b, Vector3(ax, Y, az), h, P + "/Aerials", 2.0)
	# a plastic crate, a broom, a folded chair: the roof is somebody's garden
	ObjectKit.plastic_crate(b, -1.8, -1.3, Y, Y + 0.3, -12.8, -12.4, c8(0xc9463a), P, "Crate", {"band": 2.0})
	# a broom of split bamboo, leaning on the wall, its head bound with wire
	ModelKit.place(b, ModelKit.tube([Vector3(0, 0.25, 0), Vector3(0.0, 1.4, -0.06)], 0.014, 0.0, 8), Vector3(-6.15, Y, -6.25), "timber", c8(0xc9a55a), {"band": 2.0, "parent": P, "name": "Broom"})
	ModelKit.place(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0.0), Vector2(0.09, 0.0), Vector2(0.05, 0.2), Vector2(0.02, 0.27), Vector2(0, 0.27)]), 12, Vector2(1.0, 0.45)),
		Vector3(-6.15, Y, -6.25), "fabric", c8(0xb89a5a), {"band": 2.0, "parent": P, "name": "BroomHead"})


## A potted plant, modelled (PlantKit): only people and animals are sprites.
static func plant(b: LevelBuilder, kind: String, pos: Vector3, parent: String, band: float) -> Node3D:
	# the plant sprites drew their sway phase here; the draw stays, so every
	# random choice the city makes after it (washing, aerials, people) stays put
	b.rand.randf()
	return PlantKit.place(b, kind, pos, parent, band)


static func _aerial(b: LevelBuilder, base: Vector3, h: float, parent: String, band: float) -> void:
	## A TV aerial: a mast with two or three cross-arms and dipole elements.
	var col := c8(0x3a3a3a)
	var m := base + Vector3(0.03, 0, 0.03)
	var mast := ModelKit.tube([Vector3.ZERO, Vector3(0, h, 0)], 0.024, 0.0, 8)
	ModelKit.place(b, mast, m, "metal", col, {"band": band, "parent": parent, "name": "AerialMast"})
	ModelKit.place(b, ModelKit.rbox(Vector3(0.14, 0.01, 0.14), 0.003), m + Vector3(0, 0.005, 0), "metal", col, {"band": band, "parent": parent, "name": "AerialFoot", "cast_shadow": false})
	var arms := 2 + b.rand.randi() % 2
	for k in arms:
		var y := base.y + h - 0.2 - k * 0.45
		var w := 0.7 - k * 0.12
		ModelKit.place(b, ModelKit.tube([Vector3(-w, 0, 0), Vector3(w, 0, 0)], 0.012, 0.0, 6), Vector3(m.x, y + 0.015, base.z + 0.025), "metal", col,
			{"band": band, "parent": parent, "name": "AerialArm", "cast_shadow": false})
		ModelKit.place(b, ModelKit.puck(0.034, 0.05, 0.004, 10), Vector3(m.x, y - 0.01, m.z), "metal", col.darkened(0.2), {"band": band, "parent": parent, "name": "AerialClamp", "cast_shadow": false})
		for e in 4:
			var ex := base.x - w + e * (2 * w) / 3.0 + 0.01
			ModelKit.place(b, ModelKit.tube([Vector3(0, 0, -0.25), Vector3(0, 0, 0.3)], 0.007, 0.0, 5), Vector3(ex, y + 0.01, base.z), "metal", col,
				{"band": band, "parent": parent, "name": "Element", "cast_shadow": false})


static func _wire_mesh_material() -> StandardMaterial3D:
	## Chicken wire: a procedural diamond mesh, alpha-scissored.
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 64:
		for k in 2:
			var y1 := posmod(i + k * 32, 64)
			var y2 := posmod(-i + k * 32, 64)
			img.set_pixel(i, y1, Color(0.62, 0.62, 0.58, 1))
			img.set_pixel(i, y2, Color(0.62, 0.62, 0.58, 1))
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.uv1_scale = Vector3(8, 4, 1)
	m.metallic = 0.4
	m.roughness = 0.6
	return m


# ----------------------------------------------------------------------------- pipes


## A panelled door set into a wall whose face is at z = `face`, opening to +z:
## a frame, the painted leaf with two raised panels, hinges, a handle and
## keyhole, and a kick plate worn at the foot.
static func panel_door(b: LevelBuilder, x0: float, x1: float, y: float, h: float, face: float, col: Color,
		parent: String, band: float, door_name: String, fadeable := false, back := false, room := "") -> void:
	## `back`: the same door seen from the other side of its wall, its face at
	## `face` looking toward -z (hinges and handle mirrored to match)
	_door_fades = fadeable
	_door_room = room
	var s := -1.0 if back else 1.0
	var zr := func(a: float, c: float) -> Array: return [minf(face + s * a, face + s * c), maxf(face + s * a, face + s * c)]
	# seen from behind, the hinge side is on the viewer's right
	var hinge_x := x1 - 0.05 if back else x0 - 0.02
	var hx := x0 + 0.14 if back else x1 - 0.14
	var frame := c8(0x3a3028)
	var fw := 0.07
	var z: Array = zr.call(0.0, 0.08)
	b.box(x0 - fw, x0, y, y + h + fw, z[0], z[1], frame, _door_part(parent, band, door_name + "Frame", {"surface": "wood"}))
	b.box(x1, x1 + fw, y, y + h + fw, z[0], z[1], frame, _door_part(parent, band, door_name + "Frame", {"surface": "wood"}))
	b.box(x0 - fw, x1 + fw, y + h, y + h + fw, z[0], z[1], frame, _door_part(parent, band, door_name + "Frame", {"surface": "wood"}))
	z = zr.call(0.0, 0.04)
	b.box(x0, x1, y, y + h, z[0], z[1], col, _door_part(parent, band, door_name, {}))
	var lit := col.lightened(0.12)
	var m := 0.14
	var mid := y + h * 0.52
	z = zr.call(0.04, 0.055)
	b.box(x0 + m, x1 - m, mid + 0.08, y + h - m, z[0], z[1], lit, _door_part(parent, band, door_name + "Panel", {"cast_shadow": false}))
	b.box(x0 + m, x1 - m, y + 0.3, mid - 0.08, z[0], z[1], lit, _door_part(parent, band, door_name + "Panel", {"cast_shadow": false}))
	z = zr.call(0.04, 0.05)
	b.box(x0 + 0.02, x1 - 0.02, y, y + 0.18, z[0], z[1], c8(0x6a6a64), _door_part(parent, band, door_name + "KickPlate", {"cast_shadow": false}))
	var ho := _door_part(parent, band, door_name + "Hinge", {"cast_shadow": false})
	ho.erase("surface")
	for hy in [y + 0.42, y + h - 0.38]:
		FixtureKit.hinge(b, Vector3(hinge_x + (0.06 if back else 0.02), hy, face + s * 0.045), 0.13, ho)
	var lo := _door_part(parent, band, door_name + "Handle", {})
	lo.erase("surface")
	FixtureKit.lever(b, Vector3(hx, y + 1.11, face + s * 0.042), Vector3(0, 0, s), Vector3(1 if back else -1, 0, 0), lo)


## A panelled door in a wall along z, its face at x = `face`, opening to +x:
## frame, leaf, two raised panels, hinges and a handle, as panel_door.
static func panel_door_z(b: LevelBuilder, z0: float, z1: float, y: float, h: float, face: float, col: Color,
		parent: String, band: float, door_name: String) -> void:
	var o := {"surface": "wood", "parent": parent, "band": band, "fadeable": true}
	var frame := c8(0x3a3028)
	var fw := 0.07
	b.box(face, face + 0.08, y, y + h + fw, z0 - fw, z0, frame, o.merged({"name": door_name + "Frame"}))
	b.box(face, face + 0.08, y, y + h + fw, z1, z1 + fw, frame, o.merged({"name": door_name + "Frame"}))
	b.box(face, face + 0.08, y + h, y + h + fw, z0 - fw, z1 + fw, frame, o.merged({"name": door_name + "Frame"}))
	b.box(face, face + 0.04, y, y + h, z0, z1, col, o.merged({"surface": "metal", "name": door_name}))
	var lit := col.lightened(0.12)
	var m := 0.14
	var mid := y + h * 0.52
	b.box(face + 0.04, face + 0.055, mid + 0.08, y + h - m, z0 + m, z1 - m, lit, o.merged({"surface": "metal", "name": door_name + "Panel", "cast_shadow": false}))
	b.box(face + 0.04, face + 0.055, y + 0.3, mid - 0.08, z0 + m, z1 - m, lit, o.merged({"surface": "metal", "name": door_name + "Panel", "cast_shadow": false}))
	var ho := {"parent": parent, "band": band, "fadeable": true}
	for hy in [y + 0.42, y + h - 0.38]:
		FixtureKit.hinge(b, Vector3(face + 0.045, hy, z0 + 0.01), 0.13, ho)
	FixtureKit.lever(b, Vector3(face + 0.042, y + 1.11, z1 - 0.14), Vector3(1, 0, 0), Vector3(0, 0, -1), ho)


static var _door_fades := false
static var _door_room := ""


static func _door_part(parent: String, band: float, part_name: String, extra: Dictionary) -> Dictionary:
	var d := {"surface": "metal", "parent": parent, "name": part_name, "fadeable": _door_fades}
	if band >= 0.0:
		d["band"] = band
	if _door_room != "":
		d["room"] = _door_room
	d.merge(extra, true)
	return d


static func pipe(b: LevelBuilder, points: Array, col: Color, radius := 0.12, band := -1.0, parent := "Pipes",
		bracket_exclusions: Array[AABB] = []) -> void:
	FixtureKit.pipe(b, points, col, radius, band, parent, bracket_exclusions)


static func pipes(b: LevelBuilder) -> void:
	var A := 3.3
	var B := 8.3
	# The blue pipe: Mei's first landmark. It disappears into the dead-end wall
	# and reappears down the hidden corridor, into Lau's, up the stairwell,
	# along Level B to Chan's, into the airshaft and up to the roof, where it
	# runs along the foot of the parapet and up into the water tank it feeds.
	var R := LevelBuilder.LEVEL_ROOF
	var blue := [
		Vector3(-7.2, 4.4, -3.7), Vector3(-7.2, A, -3.7), Vector3(-7.2, A, -0.72), Vector3(2.6, A, -0.72),
		Vector3(2.6, A, -1.7), Vector3(2.3, A, -1.7), Vector3(2.3, A, -14.7), Vector3(10.2, A, -14.7),
		Vector3(10.2, B, -14.7), Vector3(10.2, B, -12.85), Vector3(-4.8, B, -12.85), Vector3(-4.8, B, -20.7),
		Vector3(-4.8, R + 0.5, -20.7), Vector3(-4.8, R + 0.5, -21.6), Vector3(-4.8, R + 0.14, -21.6),
		Vector3(-4.8, R + 0.14, -23.9), Vector3(9.2, R + 0.14, -23.9), Vector3(9.2, R + 0.14, -21.2),
		Vector3(9.2, R + 2.25, -21.2),
	]
	# Brackets only read as supports where the pipe hugs a wall. In these rooms
	# the pipe crosses open space, so its auto-generated brackets looked like
	# floating shelves. Chan's east bound extends slightly past the wall to catch
	# the bracket whose centre sits on the doorway edge but projects into the room.
	var blue_bracket_exclusions: Array[AABB] = [
		AABB(Vector3(0.0, A - 0.5, -15.0), Vector3(10.5, 1.0, 6.0)),
		AABB(Vector3(8.0, B - 0.5, -15.0), Vector3(4.0, 1.0, 4.0)),
		AABB(Vector3(-8.0, B - 0.5, -16.0), Vector3(6.3, 1.0, 7.0)),
		AABB(Vector3(-7.0, B - 0.5, -21.0), Vector3(4.0, 1.0, 5.0)),
	]
	pipe(b, blue, c8(0x2f74c0), 0.14, -1.0, "Pipes/BluePipe", blue_bracket_exclusions)
	# secondary pipes for density
	pipe(b, [Vector3(-6, 3.8, 0.8), Vector3(4, 3.8, 0.8)], c8(0x8a5a3a), 0.08)
	pipe(b, [Vector3(-6, 3.95, -0.85), Vector3(4, 3.95, -0.85)], c8(0x6f7d62), 0.07)
	pipe(b, [Vector3(3.8, 3.6, -1), Vector3(3.8, 3.6, -9)], c8(0x9a4a3a), 0.07)
	pipe(b, [Vector3(0.2, 3.7, -9.2), Vector3(7.8, 3.7, -9.2)], c8(0x8a8c86), 0.06)
	pipe(b, [Vector3(-2, 8.6, -11.15), Vector3(8, 8.6, -11.15)], c8(0x8a5a3a), 0.08)
	pipe(b, [Vector3(12, 7.8, -13.3), Vector3(24, 7.8, -13.3)], c8(0x6f7d62), 0.1)
	pipe(b, [Vector3(12, 8.2, -10.7), Vector3(24, 8.2, -10.7)], c8(0x8a8c86), 0.07)
	pipe(b, [Vector3(-3.2, 5, -16.2), Vector3(-3.2, 13.5, -16.2)], c8(0x8a5a3a), 0.08, 1.0)


# ----------------------------------------------------------------------------- people


static func characters(b: LevelBuilder) -> void:
	var A := LevelBuilder.LEVEL_A
	var B := LevelBuilder.LEVEL_B
	var R := LevelBuilder.LEVEL_ROOF
	# the story residents
	b.resident("grandfather", "grandfather", Vector3(-12.8, A, -0.15), {"anim": "sit", "facing": Vector3(1, 0, 0.3)})
	# Mum, wrapping bowls in newspaper in front of the boxes; gone out by the time Mei is home
	b.resident("mum", "mum", Vector3(-12.4, A, -2.5), {"anim": "work", "facing": Vector3(0.4, 0, 1)})
	b.resident("lau", "lau", Vector3(6.2, A, -10.9), {"anim": "work", "facing": Vector3(-1, 0, 0)})
	b.resident("chan", "chan", Vector3(-3.4, B, -11.2), {"anim": "work", "facing": Vector3(0, 0, 1)})
	b.resident("son", "son", Vector3(0.2, R, -19.4), {"facing": Vector3(1, 0, 0)})
	b.resident("ng", "ng", Vector3(3.4, R, -20.6), {"anim": "work", "facing": Vector3(0, 0, -1)})
	b.resident("wong", "wong", Vector3(28.6, B, -12.6), {"facing": Vector3(-1, 0, 0)})
	# neighbours along the route
	b.resident("chopper", "chopper", Vector3(-3.4, A, 2.1), {"anim": "work", "facing": Vector3(0, 0, 1)})
	b.resident("mahjong1", "mahjong1", Vector3(-3.2, A, 2.7), {"anim": "work", "collide": false, "facing": Vector3(1, 0, 0)})
	b.resident("mahjong2", "mahjong2", Vector3(-0.8, A, 2.7), {"anim": "work", "collide": false, "facing": Vector3(-1, 0, 0)})
	b.resident("mahjong3", "mahjong3", Vector3(-2.0, A, 3.6), {"anim": "work", "collide": false, "facing": Vector3(0, 0, -1)})
	b.resident("fanman", "fanman", Vector3(-1.35, A, 0.72), {"anim": "work", "facing": Vector3(1, 0, 0)})
	b.resident("shopkeeper", "shopkeeper", Vector3(0.7, A, -5.0), {"anim": "work", "facing": Vector3(1, 0, 0)})
	b.resident("worker", "worker", Vector3(5.3, B, -12.62), {"anim": "work", "facing": Vector3(0, 0, 1)})
	b.resident("child", "child", Vector3(11.55, B, -14.5), {"facing": Vector3(-1, 0, 0.5)})

	# pigeons in and on the coop
	for i in 7:
		var p := Vector3(1.4 + (i % 4) * 1.0, R + (0.2 if i < 4 else 1.15), -22.9 + (i % 2) * 0.6)
		_pigeon(b, "Pigeon%d" % i, p)
	for i in 4:
		_pigeon(b, "ParapetPigeon%d" % i, Vector3(-1 + i * 1.3, R + 0.96, -23.95))
	var lost := _pigeon(b, "LostPigeon", Vector3(9.2, R + 2.56, -22.6))
	lost.reparent(b.group("Special"), false)
	b._own(lost)


static func _pigeon(b: LevelBuilder, pname: String, pos: Vector3) -> Node3D:
	var s := CharacterSprite.new()
	s.name = pname
	s.sheet_id = "pigeon"
	s.anim = "idle" if b.rand.randf() < 0.6 else "peck"
	s.facing = Vector3(1 if b.rand.randf() < 0.5 else -1, 0, 0)
	s.contact_shadow = false
	s.phase = b.rand.randf() * 4.0
	s.position = pos
	b.attach(s, b.group("Pigeons"))
	b.tag(s, 2.0)
	s.set_meta("pigeon", true)
	return s
