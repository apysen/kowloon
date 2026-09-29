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
	b.box(-40, 60, -0.9, -0.35, -60, 30, c8(0x5a5650), {"band": 0.0, "surface": "concrete", "parent": "Structure/Street",
		"name": "Street", "cast_shadow": false})
	lighting(b)
	level_a(b)
	level_b(b)
	airshaft(b)
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

	# Mei's flat: a single room, three generations, and today, boxes
	b.room({"x0": -14, "x1": -6, "z0": -4, "z1": 4, "y": Y, "name": "Apartment", "id": "apartment",
		"floor_surface": "wood", "wall": c8(0x9a977a), "floor": c8(0x6b5a45),
		"open": {"e": [[-1, 1]]}, "parent": "Structure/LevelA"})
	PropKit.bed(b, -14, -12, 1.8, 4, Y, c8(0x8a6f5a), c8(0xd8d0bd), P)
	b.add_obstacle(-14, -12, 1.8, 4, Y, "bed")
	PropKit.table(b, -12.2, -10.8, -1.2, 0.2, Y, 0.8, c8(0x6b4a30), P)
	b.add_obstacle(-12.2, -10.8, -1.2, 0.2, Y, "table")
	for i in 3:   # rice bowls and chopsticks
		var x := -11.9 + i * 0.3
		b.box(x, x + 0.16, Y + 0.8, Y + 0.87, -0.8, -0.64, c8(0xe8e2d0), {"surface": "grain", "parent": P, "name": "RiceBowl"})
		b.box(x + 0.02, x + 0.14, Y + 0.87, Y + 0.875, -0.55, -0.53, c8(0xc9a55a), {"surface": "wood", "parent": P, "name": "Chopsticks", "cast_shadow": false})
	b.box(-11.3, -11.0, Y + 0.8, Y + 1.05, -0.2, 0.05, c8(0x4f7f70), {"surface": "metal", "parent": P, "name": "Thermos"})
	PropKit.stool(b, -11.5, 0.6, Y, c8(0xc9463a), P)
	PropKit.stool(b, -10.3, -0.5, Y, c8(0x3f6fa8), P)
	PropKit.shelf_z(b, -14, -13.4, -2.2, -0.4, Y, 1.5, c8(0x5d4632), P)
	b.add_obstacle(-14, -13.4, -2.2, -0.4, Y, "shelf")
	var radio := PropKit.radio(b, -13.95, -13.45, Y + 1.5, -1.8, -0.9, P)
	radio.name = "Radio"
	PropKit.altar(b, -13.95, -13.6, Y + 1.2, Y + 1.25, -1.2, -1.0, P)
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(-9.2, Y + 1.8, -4.0), Vector2(0.45, 0.68), Vector3(0, 0, 1),
		{"parent": P, "name": "Calendar", "band": 0.0})
	var rotor := PropKit.fan(b, -7.0, 3.2, Y, P)
	rotor.reparent(b.group("Special"), false)
	b._own(rotor)
	rotor.name = "Fan"
	PropKit.bulb(b, Vector3(-10, Y + 3.3, -0.5), Y + 4.2, P)
	# a birdcage hanging by the window, an old clock, slippers by the door
	b.box(-6.9, -6.6, Y, Y + 0.05, -0.8, -0.4, c8(0x3f6fa8), {"surface": "fabric", "parent": P, "name": "Slippers", "cast_shadow": false})
	b.box(-6.9, -6.6, Y, Y + 0.05, 0.4, 0.8, c8(0xa8453a), {"surface": "fabric", "parent": P, "name": "Slippers", "cast_shadow": false})
	b.box(-8.6, -8.3, Y + 2.5, Y + 2.85, -3.99, -3.9, c8(0x6b4a30), {"surface": "wood", "parent": P, "name": "Clock"})

	# Packing boxes, present from the very first frame. Against the back wall,
	# behind Grandfather's chair.
	var bc := c8(0xa8834f)
	PropKit.cardboard(b, -13.9, -12.7, Y, Y + 0.8, -3.95, -3.1, bc, P)
	b.add_obstacle(-13.9, -12.7, -3.95, -3.1, Y, "boxes")
	PropKit.cardboard(b, -12.6, -11.5, Y, Y + 0.7, -3.95, -3.2, c8(0x9c7a48), P)
	b.add_obstacle(-12.6, -11.5, -3.95, -3.2, Y, "boxes2")
	PropKit.cardboard(b, -13.7, -12.9, Y + 0.8, Y + 1.4, -3.9, -3.2, c8(0xb08c58), P)
	b.ref("boxes", Vector3(-12.3, 0, -2.6))
	b.ref("radio", Vector3(-13.2, 0, -1.3))
	# Grandfather's chair
	PropKit.stool(b, -12.8, -0.45, Y, c8(0x6b4a30), P, 0.42)

	# The hall. It ends at a wall with an old service door set in it. The door
	# faces back down the hall, so from the starting view it's edge-on and can't
	# be seen; from the west it's plain as day.
	b.room({"x0": -6, "x1": 2, "z0": -1, "z1": 1, "y": Y, "name": "Hall", "wall": c8(0x7c7f74), "floor": c8(0x4e4a44),
		"open": {"s": [[-4, 0]], "e": [[-0.7, 0.7]]}, "skip": ["w"], "parent": "Structure/LevelA",
		"dado": "mosaic", "dado_color": c8(0xa9c0b8)})
	b.door({"id": "serviceDoor", "x": 2.15, "z": 0.0, "y": Y, "normal": Vector3(-1, 0, 0), "width": 1.4,
		"color": c8(0x7a93a0), "band": 0.0, "room": "corridor", "light_spill": true})
	var PH := "Furniture/Hall"
	b.box(-5.8, -5.2, Y, Y + 0.5, 0.45, 0.95, c8(0x5c6b4a), {"surface": "grain", "parent": PH, "name": "BucketCrate"})
	b.box(-5.75, -5.45, Y + 0.5, Y + 0.8, 0.5, 0.8, c8(0xc9463a), {"surface": "grain", "parent": PH, "name": "Bucket"})
	b.box(-0.9, -0.3, Y, Y + 0.4, 0.5, 0.95, c8(0x3d4a52), {"surface": "metal", "parent": PH, "name": "FanParts"})
	b.card("res://assets/textures/props/mailboxes.png", Vector3(-4.8, Y + 1.5, -0.85), Vector2(0.9, 0.9), Vector3(0, 0, 1), {"parent": PH, "name": "Mailboxes", "band": 0.0})
	b.card("res://assets/textures/props/notice_clearance.png", Vector3(-2.6, Y + 1.75, -0.85), Vector2(0.55, 0.73), Vector3(0, 0, 1), {"parent": PH, "name": "ClearanceNotice", "band": 0.0})
	b.card("res://assets/textures/props/poster_2.png", Vector3(-1.2, Y + 1.7, -0.85), Vector2(0.45, 0.63), Vector3(0, 0, 1), {"parent": PH, "name": "ShopToLet", "band": 0.0})
	PropKit.tube_light(b, Vector3(-3.0, Y + 3.9, 0), Vector3(-1.8, Y + 3.9, 0), PH)
	# wiring stapled along the hall ceiling, and an electricity meter box
	b.box(-5.5, -4.9, Y + 2.3, Y + 2.9, -0.86, -0.8, c8(0x55605a), {"surface": "metal", "parent": PH, "name": "MeterBox"})
	for k in 3:
		b.cylinder(Vector3(-6, Y + 3.7 + k * 0.06, -0.8), Vector3(2, Y + 3.7 + k * 0.06, -0.8), 0.012, b.surface("grain"),
			{"parent": PH, "name": "Wire", "tint": c8(0x1c1c1e), "cast_shadow": false})

	# Mahjong alcove
	b.room({"x0": -4, "x1": 0, "z0": 1, "z1": 4, "y": Y, "name": "Alcove", "wall": c8(0x8a7a62), "floor": c8(0x5a4c3c),
		"skip": ["n"], "parent": "Structure/LevelA"})
	var PA := "Furniture/Alcove"
	b.box(-2.8, -1.2, Y + 0.7, Y + 0.75, 2.0, 3.3, c8(0x2e5a3a), {"surface": "fabric", "parent": PA, "name": "MahjongCloth"})
	PropKit.table(b, -2.8, -1.2, 2.0, 3.3, Y, 0.7, c8(0x5a3a26), PA)
	b.add_obstacle(-2.8, -1.2, 2.0, 3.3, Y, "mahjong")
	for i in 16:
		var x := -2.6 + (i % 8) * 0.16
		var z: float = 2.15 + floor(i / 8.0) * 0.95
		b.box(x, x + 0.12, Y + 0.75, Y + 0.84, z, z + 0.08, c8(0xece6d4), {"surface": "grain", "parent": PA, "name": "Tile", "cast_shadow": false})
		b.box(x, x + 0.12, Y + 0.75, Y + 0.77, z, z + 0.08, c8(0x3a7a4a), {"surface": "grain", "parent": PA, "name": "TileBack", "cast_shadow": false})
	b.box(-2.1, -1.9, Y + 0.75, Y + 0.95, 2.55, 2.75, c8(0xf2eee4), {"surface": "grain", "parent": PA, "name": "TeaCup"})
	PropKit.table(b, -3.95, -3.3, 2.5, 3.5, Y, 0.8, c8(0x6b4a30), PA)
	b.add_obstacle(-3.95, -3.3, 2.5, 3.5, Y, "chopping")
	b.box(-3.9, -3.4, Y + 0.8, Y + 0.87, 2.7, 3.2, c8(0xc9a270), {"surface": "wood", "parent": PA, "name": "ChoppingBlock"})
	b.box(-3.85, -3.6, Y + 0.87, Y + 0.95, 3.25, 3.45, c8(0x6f9a4a), {"surface": "grain", "parent": PA, "name": "Greens"})
	b.box(-3.7, -3.5, Y + 0.87, Y + 0.89, 2.8, 3.05, c8(0xd8dcd8), {"surface": "metal", "parent": PA, "name": "Cleaver", "cast_shadow": false})
	b.card("res://assets/textures/props/poster_1.png", Vector3(-2.0, Y + 1.9, 3.85), Vector2(0.5, 0.7), Vector3(0, 0, -1), {"parent": PA, "name": "MahjongPoster", "band": 0.0})
	PropKit.bulb(b, Vector3(-2, Y + 2.9, 2.6), Y + 4.2, PA)

	# Hidden corridor to Lau's
	b.room({"x0": 2, "x1": 4, "z0": -9, "z1": 1, "y": Y, "name": "Corridor", "wall": c8(0x77705e), "floor": c8(0x4a463e),
		"id": "corridor", "open": {"w": [[-6, -4], [-1.3, 1.3]]}, "skip": ["n"], "parent": "Structure/LevelA",
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
	# the dental chair: base, seat, back, arms, footrest
	b.box(4.6, 5.5, Y, Y + 0.35, -12.9, -12.1, c8(0xb8b6ac), {"surface": "metal", "parent": PC, "name": "ChairBase"})
	b.box(4.3, 5.8, Y + 0.35, Y + 0.6, -13.3, -11.7, c8(0xd8d6cc), {"surface": "metal", "parent": PC, "name": "ChairPlinth"})
	b.box(4.3, 4.7, Y + 0.6, Y + 1.5, -13.2, -11.8, c8(0x3f7a78), {"surface": "fabric", "parent": PC, "name": "ChairBack"})
	b.box(4.7, 5.8, Y + 0.6, Y + 0.8, -13.1, -11.9, c8(0x3f7a78), {"surface": "fabric", "parent": PC, "name": "ChairSeat"})
	b.box(4.3, 4.6, Y + 1.5, Y + 1.7, -12.75, -12.25, c8(0x3f7a78), {"surface": "fabric", "parent": PC, "name": "Headrest"})
	for z in [-13.3, -11.8]:
		b.box(4.7, 5.5, Y + 0.85, Y + 0.9, z, z + 0.1, c8(0xd8d6cc), {"surface": "metal", "parent": PC, "name": "ChairArm"})
	b.add_obstacle(4.3, 5.8, -13.3, -11.7, Y, "chair")
	b.box(5.9, 6.0, Y, Y + 2.2, -13.5, -13.4, c8(0x999999), {"surface": "metal", "parent": PC, "name": "LampPost"})
	b.box(5.2, 6.0, Y + 2.1, Y + 2.2, -13.5, -12.3, c8(0x999999), {"surface": "metal", "parent": PC, "name": "LampArm"})
	b.box(5.1, 5.5, Y + 1.9, Y + 2.1, -12.5, -12.1, c8(0xe8e4d8), {"surface": "metal", "parent": PC, "name": "LampHead"})
	b.box(5.14, 5.46, Y + 1.88, Y + 1.9, -12.46, -12.14, Color(1, 0.97, 0.85), {"material": b.emissive(Color(1, 0.97, 0.82), 6.0), "parent": PC, "name": "LampGlow"})
	# tray trolley with instruments, a cabinet of drawers, a spittoon
	b.box(6.4, 7.2, Y, Y + 0.9, -14.9, -14.3, c8(0xdcdcd4), {"surface": "metal", "parent": PC, "name": "Trolley"})
	b.add_obstacle(6.4, 7.2, -14.9, -14.3, Y, "trolley")
	for i in 5:
		b.box(6.5 + i * 0.13, 6.53 + i * 0.13, Y + 0.9, Y + 0.91, -14.8, -14.5, c8(0xd8dce0), {"surface": "metal", "parent": PC, "name": "Instrument", "cast_shadow": false})
	b.box(6.6, 8, Y, Y + 1.3, -15, -14.4, c8(0xe0e4de), {"surface": "metal", "parent": PC, "name": "Cabinet"})
	b.add_obstacle(6.6, 8, -15, -14.4, Y, "cabinet")
	for i in 4:
		b.box(6.7, 7.9, Y + 0.12 + i * 0.3, Y + 0.14 + i * 0.3, -14.39, -14.37, c8(0x8a9090), {"surface": "metal", "parent": PC, "name": "Drawer", "cast_shadow": false})
	b.box(5.9, 6.2, Y, Y + 0.75, -11.6, -11.3, c8(0xe8ece8), {"surface": "tiles", "parent": PC, "name": "Spittoon"})
	PropKit.cardboard(b, 0.2, 1.6, Y, Y + 0.7, -14.8, -13.4, c8(0xa8834f), PC)
	b.add_obstacle(0.2, 1.6, -14.8, -13.4, Y, "clinicBoxes")
	PropKit.cardboard(b, 0.3, 1.4, Y + 0.7, Y + 1.2, -14.6, -13.7, c8(0x9c7a48), PC)
	PropKit.cardboard(b, 0.2, 1.3, Y, Y + 0.6, -10.8, -9.3, c8(0xa8834f), PC)
	b.add_obstacle(0.2, 1.3, -10.8, -9.3, Y, "clinicBoxes2")
	b.card("res://assets/textures/props/certificate.png", Vector3(0.05, Y + 1.7, -12.0), Vector2(0.9, 0.68), Vector3(1, 0, 0), {"parent": PC, "name": "Certificate", "band": 0.0})
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(7.95, Y + 1.8, -10.4), Vector2(0.4, 0.6), Vector3(-1, 0, 0), {"parent": PC, "name": "Calendar", "band": 0.0})
	PropKit.tube_light(b, Vector3(3.2, Y + 3.9, -12), Vector3(4.8, Y + 3.9, -12), PC)
	PropKit.tube_light(b, Vector3(3.2, Y + 3.9, -10.6), Vector3(4.8, Y + 3.9, -10.6), PC)

	# The hanging vertical sign: a landmark over the rooftops of Level A.
	var sign := b.card("res://assets/textures/props/sign_lau_dental.png", Vector3(3, Y + 5.3, -8.6), Vector2(2.4, 1.2), Vector3(0, 0, 1),
		{"parent": "Dressing/LauSign", "name": "LauSign", "band": 0.0, "emission": 0.25})
	sign.name = "LauSign"
	b.box(1.75, 4.25, Y + 4.65, Y + 5.95, -8.8, -8.66, c8(0x5a2a22), {"band": 0.0, "surface": "wood", "parent": "Dressing/LauSign", "name": "SignBoard"})
	b.box(2.9, 3.1, Y + 4.2, Y + 4.7, -8.8, -8.7, c8(0x333333), {"band": 0.0, "surface": "metal", "parent": "Dressing/LauSign", "name": "SignBracket"})
	b.ref("lauSign", Vector3(3, 0, -8.2))

	# Stairwell
	b.room({"x0": 8, "x1": 10.5, "z0": -15, "z1": -12, "y": Y, "name": "Stairwell", "id": "clinic",
		"wall": c8(0x6d6a60), "floor": c8(0x4a463e), "skip": ["w"], "parent": "Structure/LevelA", "wall_surface": "concrete"})
	for i in 6:
		b.box(9.9, 10.5, Y, Y + 0.35 * (i + 1), -12.3 - i * 0.45, -12.75 - i * 0.45, c8(0x5d5a52), {"surface": "concrete", "parent": "Structure/LevelA/Stairwell", "name": "Step"})
		b.box(9.88, 10.5, Y + 0.35 * (i + 1) - 0.03, Y + 0.35 * (i + 1), -12.3 - i * 0.45, -12.36 - i * 0.45, c8(0x8a8a80), {"surface": "metal", "parent": "Structure/LevelA/Stairwell", "name": "Nosing", "cast_shadow": false})
	b.cylinder(Vector3(9.85, Y + 1.0, -12.2), Vector3(9.85, Y + 2.9, -15.0), 0.025, b.surface("metal"), {"parent": "Structure/LevelA/Stairwell", "name": "Handrail", "tint": c8(0x6a5a48)})
	b.ref("stairsUpA", Vector3(9.4, Y, -14.2))

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
	b.box(9.9, 10.9, Y, Y + 2.3, -15.05, -14.93, c8(0x6a3f2c), {"surface": "wood", "parent": "Structure/LevelB/Landing", "name": "RoofDoor"})
	b.box(9.82, 10.98, Y + 2.3, Y + 2.4, -15.06, -14.92, c8(0x3a3028), {"surface": "wood", "parent": "Structure/LevelB/Landing", "name": "RoofDoorHead"})
	b.box(10.7, 10.78, Y + 1.1, Y + 1.18, -14.93, -14.86, c8(0xc9a55a), {"surface": "metal", "parent": "Structure/LevelB/Landing", "name": "RoofDoorHandle"})
	b.ref("stairsDownB", Vector3(8.5, Y, -13.9))
	b.ref("roofDoorB", Vector3(10.4, Y, -14.4))
	# the flight down toward the clinic: steps dropping away from the landing,
	# their nosings painted safety yellow so the opening reads from any view
	var SP := "Structure/LevelB/Landing/StairsDown"
	for i in 6:
		var top := Y - 0.3 * (i + 1)
		var sz0 := -15.0 + 0.34 * i
		b.box(8.02, 8.93, top - 0.3, top, sz0, sz0 + 0.34, c8(0x6a665c), {"band": 1.0, "surface": "concrete", "parent": SP, "name": "Step"})
		b.box(8.02, 8.93, top - 0.035, top, sz0 + 0.28, sz0 + 0.34, c8(0xd8b23a), {"band": 1.0, "surface": "metal", "parent": SP, "name": "Nosing", "cast_shadow": false})
	b.box(8.0, 8.95, Y - 2.2, Y - 1.9, -15.0, -13.1, c8(0x2a2826), {"band": 1.0, "surface": "concrete", "parent": SP, "name": "Below"})
	# the lip of the opening, also painted, and light spilling up from the flight below
	b.box(8.0, 8.95, Y - 0.04, Y + 0.01, -13.16, -13.1, c8(0xd8b23a), {"band": 1.0, "surface": "metal", "parent": SP, "name": "Lip", "cast_shadow": false})
	b.box(8.95, 9.0, Y - 0.04, Y + 0.01, -15.0, -13.1, c8(0xd8b23a), {"band": 1.0, "surface": "metal", "parent": SP, "name": "Lip", "cast_shadow": false})
	PropKit.bulb(b, Vector3(8.48, Y - 0.9, -14.6), Y - 0.35, SP)
	# a painted green rail round the opening, with balusters, so it reads as a stairwell from every side
	var rail := c8(0x4f7a5a)
	for pz in [-13.1, -13.75, -14.4, -14.97]:
		b.box(8.96, 9.04, Y, Y + 1.0, pz - 0.04, pz + 0.04, rail, {"band": 1.0, "surface": "metal", "parent": SP, "name": "RailPost"})
	for px in [8.05, 8.5]:
		b.box(px - 0.04, px + 0.04, Y, Y + 1.0, -13.14, -13.06, rail, {"band": 1.0, "surface": "metal", "parent": SP, "name": "RailPost"})
	b.box(8.95, 9.05, Y + 0.93, Y + 1.0, -15.0, -13.05, rail, {"band": 1.0, "surface": "metal", "parent": SP, "name": "Rail"})
	b.box(8.0, 9.05, Y + 0.93, Y + 1.0, -13.15, -13.05, rail, {"band": 1.0, "surface": "metal", "parent": SP, "name": "Rail"})
	b.box(8.97, 9.03, Y + 0.45, Y + 0.5, -15.0, -13.07, rail, {"band": 1.0, "surface": "metal", "parent": SP, "name": "MidRail"})
	# the painted marker on the walls above the flight
	b.card("res://assets/textures/props/sign_stairs_down.png", Vector3(8.48, Y + 1.75, -14.94), Vector2(0.6, 0.8), Vector3(0, 0, 1), {"parent": SP, "name": "StairSign", "band": 1.0})
	b.card("res://assets/textures/props/sign_stairs_down.png", Vector3(8.06, Y + 1.75, -13.9), Vector2(0.6, 0.8), Vector3(1, 0, 0), {"parent": SP, "name": "StairSign", "band": 1.0})
	b.add_obstacle(8.0, 8.95, -15.0, -13.1, Y, "stairwell")
	PropKit.bulb(b, Vector3(10, Y + 3.2, -13), Y + 4.2, "Structure/LevelB/Landing")

	b.room({"x0": -2, "x1": 8, "z0": -13, "z1": -11, "y": Y, "name": "CorridorB", "wall": c8(0x807868), "floor": c8(0x4a4640),
		"skip": ["w", "e"], "parent": "Structure/LevelB", "dado": "mosaic", "dado_color": c8(0xb7a9a6)})
	var PB := "Furniture/CorridorB"
	PropKit.cardboard(b, 6.2, 7.6, Y, Y + 0.9, -12.95, -12.45, c8(0xa8834f), PB, "n")
	b.add_obstacle(6.2, 7.6, -12.95, -12.45, Y, "stackedBoxes")
	PropKit.cardboard(b, 6.4, 7.4, Y + 0.9, Y + 1.5, -12.9, -12.5, c8(0x9c7a48), PB, "n")
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
	b.box(-7.6, -7.0, Y + 0.85, Y + 1.05, -10.8, -10.5, c8(0x2a2a2a), {"surface": "metal", "parent": PCh, "name": "SewingMachine"})
	b.box(-7.5, -7.4, Y + 1.05, Y + 1.25, -10.8, -10.5, c8(0x2a2a2a), {"surface": "metal", "parent": PCh, "name": "MachineArm"})
	b.box(-7.5, -7.1, Y + 1.2, Y + 1.25, -10.8, -10.5, c8(0x2a2a2a), {"surface": "metal", "parent": PCh, "name": "MachineHead"})
	b.box(-7.28, -7.24, Y + 0.85, Y + 1.2, -10.6, -10.57, c8(0xc9a55a), {"surface": "metal", "parent": PCh, "name": "Needle", "cast_shadow": false})
	for i in 3:
		var z := -10.2 + i * 0.3
		b.cylinder(Vector3(-7.9, Y + 0.95, z), Vector3(-7.1, Y + 0.95, z), 0.1, b.surface("fabric"), {"parent": PCh, "name": "ClothBolt", "tint": [c8(0xa8534a), c8(0x3f6fa8), c8(0xe8d8b0)][i]})
	b.box(-4.2, -3.2, Y, Y + 0.5, -10.2, -9.2, c8(0x5f7a88), {"surface": "metal", "parent": PCh, "name": "Basin"})
	b.add_obstacle(-4.2, -3.2, -10.2, -9.2, Y, "basin")
	b.box(-4.1, -3.3, Y + 0.45, Y + 0.48, -10.1, -9.3, c8(0x7fa0b8), {"surface": "metal", "parent": PCh, "name": "Water", "cast_shadow": false})
	b.box(-8, -7.2, Y, Y + 1.8, -15.9, -14.2, c8(0x5d4632), {"surface": "wood", "parent": PCh, "name": "Cabinet"})
	b.add_obstacle(-8, -7.2, -15.9, -14.2, Y, "chanCabinet")
	PropKit.shelf(b, -3.9, -2.2, -15.9, -15.5, Y + 1.4, 1.2, c8(0x6b4a30), PCh, 2)
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(-2.05, Y + 1.9, -10.5), Vector2(0.4, 0.6), Vector3(-1, 0, 0), {"parent": PCh, "name": "Calendar", "band": 1.0})
	laundry_line(b, -7.8, -2.4, Y + 2.8, -14.6, "x", [c8(0xd8c4a0), c8(0x5a7ab0), c8(0xe8e2d4), c8(0xb0504a)], PCh)
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
		b.box(12, 24, Y + 0.95, Y + 1.02, z - 0.04, z + 0.04, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": PW, "name": "Rail"})
		b.box(12, 24, Y + 0.45, Y + 0.49, z - 0.02, z + 0.02, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": PW, "name": "MidRail"})
		var px := 12.0
		while px <= 24.01:
			b.box(px, px + 0.06, Y, Y + 1.0, z - 0.03, z + 0.03, c8(0x6a6e70), {"band": 1.0, "surface": "metal", "parent": PW, "name": "Post"})
			px += 1.0
	PropKit.bulb(b, Vector3(18, Y + 2.9, -11.2), Y + 3.6, PW)

	# The wet washing. The same object later hangs on the roof.
	var fabric := Node3D.new()
	fabric.name = "Fabric"
	fabric.position = Vector3(16, Y + 2.6, -12)
	b.attach(fabric, b.group("Special"))
	b.tag(fabric, 1.0, false, {"dynamic": true})
	var cols := [c8(0x3f6fa8), c8(0xc9a55a), c8(0xa8534a)]
	for i in 3:
		var cloth := b.box(-0.02, 0.02, -2.05, -0.05, -0.36, 0.36, cols[i], {"surface": "fabric", "parent_node": fabric, "name": "Cloth"})
		cloth.position = Vector3(0, -1.05, -0.78 + i * 0.78)
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
	PropKit.bed(b, 28.6, 31, -9.8, -8, Y, c8(0x8a6f5a), c8(0xe8dcc8), PWo, false)
	b.add_obstacle(28.6, 31, -9.8, -8, Y, "wongBed")
	PropKit.altar(b, 29.8, 31, Y, Y + 1.3, -16, -15, PWo, -1.0)
	b.add_obstacle(29.8, 31, -16, -15, Y, "wongAltar")
	PropKit.table(b, 25, 26.2, -15.6, -14.4, Y, 0.5, c8(0x6b4a30), PWo)
	b.add_obstacle(25, 26.2, -15.6, -14.4, Y, "wongTable")
	b.box(25.3, 25.6, Y + 0.5, Y + 0.8, -15.2, -14.9, c8(0x4f7f70), {"surface": "metal", "parent": PWo, "name": "Thermos"})
	b.box(25.7, 25.9, Y + 0.5, Y + 0.6, -15.0, -14.8, c8(0xf2eee4), {"surface": "grain", "parent": PWo, "name": "Cup"})
	b.box(24.1, 24.9, Y, Y + 2.0, -9.5, -8.1, c8(0x5d4632), {"surface": "wood", "parent": PWo, "name": "Wardrobe"})
	b.add_obstacle(24.1, 24.9, -9.5, -8.1, Y, "wardrobe")
	b.box(24.9, 24.92, Y + 0.2, Y + 1.8, -8.82, -8.78, c8(0x3a2a1a), {"surface": "wood", "parent": PWo, "name": "WardrobeSeam", "cast_shadow": false})
	PropKit.stool(b, 27.2, -14.3, Y, c8(0xc9463a), PWo)
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(27.5, Y + 1.9, -15.95), Vector2(0.4, 0.6), Vector3(0, 0, 1), {"parent": PWo, "name": "Calendar", "band": 1.0})
	PropKit.bulb(b, Vector3(27.5, Y + 3.2, -12), Y + 4.2, PWo)
	PropKit.fan(b, 30.3, -11.5, Y, PWo)


static func _decal_mat(b: LevelBuilder, tex: String) -> StandardMaterial3D:
	var m := b.card_material("res://assets/textures/props/%s.png" % tex)
	var d := m.duplicate() as StandardMaterial3D
	d.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d.roughness = 0.1
	d.metallic_specular = 0.8
	return d


static func laundry_line(b: LevelBuilder, a0: float, a1: float, y: float, fixed: float, axis: String, colors: Array, parent: String) -> void:
	var len := absf(a1 - a0)
	if axis == "x":
		b.box(a0, a1, y, y + 0.03, fixed - 0.015, fixed + 0.015, c8(0x222222), {"surface": "grain", "parent": parent, "name": "Line", "cast_shadow": false})
	else:
		b.box(fixed - 0.015, fixed + 0.015, y, y + 0.03, a0, a1, c8(0x222222), {"surface": "grain", "parent": parent, "name": "Line", "cast_shadow": false})
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


# ----------------------------------------------------------------------------- airshaft


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
	b.box(-3.95, -3.15, Y, Y + 1.7, -19.45, -18.75, c8(0xd8d8cc), {"band": 1.0, "surface": "metal", "parent": P, "name": "BrokenFridge"})
	b.box(-3.97, -3.13, Y + 1.1, Y + 1.14, -18.76, -18.7, c8(0x9aa0a0), {"band": 1.0, "surface": "metal", "parent": P, "name": "FridgeHandle", "cast_shadow": false})
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
	b.box(-3.05, -3.0, Y + 2.2, Y + 3.2, -17.8, -16.6, c8(0x3a4650), {"band": 1.0, "surface": "metal", "parent": P, "name": "Window"})

	b.ref("shaftBase", Vector3(-5, Y, -18.2))
	# onto the crate, straight up the ladder, over the rim onto the roof
	b.data.climb_nodes = [
		Vector3(-5.7, Y, -19.95),
		Vector3(-6.25, Y + 0.7, -19.95),
		Vector3(-6.55, Y + 0.7, -19.95),
		Vector3(-6.55, R + 0.4, -19.95),
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

	# stair hut with its door
	b.box(8.8, 11.6, Y, Y + 2.8, -15, -12.4, c8(0x7a7466), {"band": 2.0, "collide": true, "collide_y": Y, "fadeable": true,
		"surface": "plaster", "top": "tar", "parent": P, "name": "StairHut", "base_y": Y})
	b.box(9.9, 10.9, Y, Y + 2.2, -12.42, -12.3, c8(0x6a3f2c), {"band": 2.0, "surface": "wood", "parent": P, "name": "HutDoor"})
	b.box(8.7, 11.7, Y + 2.8, Y + 2.86, -15.1, -12.2, c8(0x9a9690), {"band": 2.0, "surface": "rust", "parent": P, "name": "HutRoof"})
	b.ref("roofDoorTop", Vector3(10.4, Y, -11.8))
	b.ref("shaftTop", Vector3(-7.8, Y, -19.95))

	# Mr. Ng's pigeon coop: a timber frame with wire mesh, perches inside
	var PC := "Structure/Roof/Coop"
	b.box(0.9, 5.1, Y + 2.2, Y + 2.35, -23.7, -21.5, c8(0x6b4a30), {"band": 2.0, "surface": "wood", "parent": PC, "name": "CoopRoof"})
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

	# water tank on legs
	for xz in [[8.1, -22.3], [10.2, -22.3], [8.1, -20.1], [10.2, -20.1]]:
		b.box(xz[0], xz[0] + 0.15, Y, Y + 2.2, xz[1], xz[1] + 0.15, c8(0x555555), {"band": 2.0, "surface": "rust", "parent": "Special/TankStand", "name": "TankLeg"})
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
	for z in [-23.8, -21.3]:
		b.box(6.45, 6.55, Y, Y + 2.7, z, z + 0.1, c8(0x5a5a55), {"band": 2.0, "surface": "metal", "parent": P, "name": "SheetPost"})
	b.box(6.48, 6.52, Y + 2.6, Y + 2.64, -23.8, -21.2, c8(0x222222), {"band": 2.0, "surface": "grain", "parent": P, "name": "SheetLine"})
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
	b.data.pigeon_path = [
		Vector3(9.2, Y + 2.56, -22.6),
		Vector3(8.2, Y + 3.4, -22.9),
		Vector3(6.5, Y + 3.6, -22.6),
		Vector3(4.6, Y + 2.8, -22.5),
		Vector3(3.2, Y + 0.25, -22.3),
	]

	# laundry lines (the washing arrives here later)
	for x in [-9.2, -2.2]:
		b.box(x, x + 0.12, Y, Y + 2.6, -8.6, -8.48, c8(0x5a5a55), {"band": 2.0, "surface": "metal", "parent": P, "name": "LinePost"})
	laundry_line(b, -9.2, -2.2, Y + 2.5, -8.54, "x", [c8(0xe8e2d4), c8(0x5a7ab0), c8(0xe8e2d4)], "Structure/Roof/Laundry")
	b.ref("roofFabricPos", Vector3(-5.2, Y + 2.5, -8.54))

	# roof clutter: a bench, pots of herbs and chillies, the AC housing, a
	# forest of TV aerials (every flat had its own)
	b.box(-9.6, -8.2, Y + 0.38, Y + 0.45, -12, -10.6, c8(0x6b4a30), {"band": 2.0, "surface": "wood", "parent": P, "name": "Bench"})
	for bx in [-9.5, -8.35]:
		b.box(bx, bx + 0.08, Y, Y + 0.38, -11.9, -10.7, c8(0x4a3222), {"band": 2.0, "surface": "wood", "parent": P, "name": "BenchLeg"})
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
	b.box(-1.8, -1.3, Y, Y + 0.3, -12.8, -12.4, c8(0xc9463a), {"band": 2.0, "surface": "grain", "parent": P, "name": "Crate"})
	b.box(-6.2, -6.1, Y, Y + 1.4, -6.35, -6.25, c8(0xc9a55a), {"band": 2.0, "surface": "wood", "parent": P, "name": "Broom"})


## A potted plant: a pixel-art card from the plants sheet (drawn in Aseprite).
static func plant(b: LevelBuilder, kind: String, pos: Vector3, parent: String, band: float) -> Node3D:
	var s := CharacterSprite.new()
	s.name = "Plant"
	s.sheet_id = "plants"
	s.anim = kind
	s.contact_shadow = true
	s.phase = b.rand.randf() * 2.0
	s.position = pos
	b.attach(s, b.group(parent))
	b.tag(s, band)
	return s


static func _aerial(b: LevelBuilder, base: Vector3, h: float, parent: String, band: float) -> void:
	## A TV aerial: a mast with two or three cross-arms and dipole elements.
	var col := c8(0x3a3a3a)
	b.box(base.x, base.x + 0.06, base.y, base.y + h, base.z, base.z + 0.06, col, {"band": band, "surface": "metal", "parent": parent, "name": "AerialMast"})
	var arms := 2 + b.rand.randi() % 2
	for k in arms:
		var y := base.y + h - 0.2 - k * 0.45
		var w := 0.7 - k * 0.12
		b.box(base.x - w, base.x + w + 0.06, y, y + 0.03, base.z + 0.01, base.z + 0.04, col, {"band": band, "surface": "metal", "parent": parent, "name": "AerialArm", "cast_shadow": false})
		for e in 4:
			var ex := base.x - w + e * (2 * w) / 3.0
			b.box(ex, ex + 0.02, y, y + 0.02, base.z - 0.25, base.z + 0.3, col, {"band": band, "surface": "metal", "parent": parent, "name": "Element", "cast_shadow": false})


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


static func pipe(b: LevelBuilder, points: Array, col: Color, radius := 0.12, band := -1.0, parent := "Pipes") -> void:
	var mat := b.surface("metal")
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var c: Vector3 = points[i + 1]
		var bd := band if band >= 0 else b.band_of(minf(a.y, c.y))
		b.cylinder(a, c, radius, mat, {"parent": parent, "name": "PipeRun", "tint": col, "band": bd, "segments": 12})
		var s := SphereMesh.new()
		s.radius = radius * 1.35
		s.height = radius * 2.7
		s.radial_segments = 12
		s.rings = 6
		b.piece(s, c, mat, {"parent": parent, "name": "Collar", "tint": col, "band": bd})
		# brackets every couple of metres along the run
		var n := int(a.distance_to(c) / 1.8)
		for k in n:
			var p := a.lerp(c, (k + 0.5) / maxf(1, n))
			b.box(p.x - radius * 1.5, p.x + radius * 1.5, p.y - radius * 1.5, p.y - radius * 1.2, p.z - radius * 1.5, p.z + radius * 1.5,
				c8(0x3a3a3a), {"surface": "metal", "parent": parent, "name": "Bracket", "band": bd, "cast_shadow": false})


static func pipes(b: LevelBuilder) -> void:
	var A := 3.3
	var B := 8.3
	# The blue pipe: Mei's first landmark. It disappears into the dead-end wall
	# and reappears down the hidden corridor, into Lau's, up the stairwell,
	# along Level B to Chan's, into the airshaft and up to the roof.
	var blue := [
		Vector3(-7.2, 4.4, -3.7), Vector3(-7.2, A, -3.7), Vector3(-7.2, A, -0.72), Vector3(2.6, A, -0.72),
		Vector3(2.6, A, -1.7), Vector3(2.3, A, -1.7), Vector3(2.3, A, -14.7), Vector3(10.2, A, -14.7),
		Vector3(10.2, B, -14.7), Vector3(10.2, B, -12.85), Vector3(-4.8, B, -12.85), Vector3(-4.8, B, -20.7),
		Vector3(-4.8, 14.2, -20.7), Vector3(-4.8, 14.2, -23.6),
	]
	pipe(b, blue, c8(0x2f74c0), 0.14, -1.0, "Pipes/BluePipe")
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
	b.resident("fanman", "fanman", Vector3(-1.4, A, 0.62), {"anim": "work", "facing": Vector3(0, 0, 1)})
	b.resident("shopkeeper", "shopkeeper", Vector3(0.7, A, -5.0), {"anim": "work", "facing": Vector3(1, 0, 0)})
	b.resident("worker", "worker", Vector3(3.0, B, -12.62), {"anim": "work", "facing": Vector3(0, 0, 1)})
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
