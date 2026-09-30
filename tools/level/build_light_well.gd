class_name BuildLightWell
extends RefCounted

## The north side of the catwalk's light well, one floor up (Level B): where the
## water comes from, and where it was shut off.
##
## A ledge runs along the well's north wall, reached by a plank footbridge off
## the catwalk. On it: Mrs. Fong's door (a radio behind it), and the flat next
## door, chained shut; its family has already been rehoused. A service ledge
## turns north past its side to the back of its kitchen, whose window only shows
## from the east or west. The pump sits on the well floor. The blue branch
## leaves the landing, crosses the well beside an old dead line, and runs along
## the north wall behind three air-conditioners, past Mrs. Fong's tap, into the
## empty flat, fading from blue to bare grey as it goes. Inside, three valves.
##
## Permanent: it is there on every day. Only the people change.

const Y := LevelBuilder.LEVEL_B
const BLUE := Color("2f74c0")
const GREY := Color("8a8c86")
const P := "Structure/LevelB/LightWellNorth"
const PU := "Furniture/Unit"

# the rooms: Mrs. Fong's, and the empty flat
const FONG := [12.0, 17.6, -21.5, -17.6]
const UNIT := [18.0, 24.0, -21.5, -17.6]
const LEDGE_Z := [-17.3, -16.3]            # between the rooms' south walls and the well
const BRIDGE_X := [17.2, 18.2]
const SERVICE := [24.3, 25.2, -20.8, -17.3]
const WINDOW_Z := [-19.6, -18.8]
const PIPE_Y := Y + 2.45                    # the branch's height along the north wall
const PIPE_Z := -17.15                      # a hand's breadth off the wall
# the valve manifold, inside the flat on its south wall
const VALVE_X := [20.6, 21.4, 22.2]
const MANIFOLD_Y := Y + 1.25
const MANIFOLD_Z := -21.3


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	_ledge(b)
	_footbridge(b)
	_rooms(b)
	_pump(b)
	_pipes(b)
	_air_conditioners(b)
	_unit_inside(b)


# ----------------------------------------------------------------------------- walking


static func _ledge(b: LevelBuilder) -> void:
	# the ledge: a concrete slab cantilevered off the north wall, on steel brackets
	b.add_floor(12.0, SERVICE[1], LEDGE_Z[0], LEDGE_Z[1], Y, "northLedge")
	b.box(12.0, SERVICE[1], Y - 0.25, Y, LEDGE_Z[0], LEDGE_Z[1], c8(0x7e7a70), {"band": 1.0, "surface": "concrete", "parent": P, "name": "LedgeSlab"})
	var bx := 12.6
	while bx < SERVICE[1]:
		b.box(bx, bx + 0.06, Y - 0.85, Y - 0.25, LEDGE_Z[0], LEDGE_Z[0] + 0.06, c8(0x4a4a48), {"band": 1.0, "surface": "rust", "parent": P, "name": "Bracket"})
		b.cylinder(Vector3(bx + 0.03, Y - 0.82, LEDGE_Z[0] + 0.05), Vector3(bx + 0.03, Y - 0.27, LEDGE_Z[1] - 0.05), 0.025,
			b.surface("rust"), {"parent": P, "name": "BracketStrut", "tint": c8(0x4a4a48), "band": 1.0})
		bx += 1.6
	# the rail on the well side, open where the footbridge lands and where Mrs. Wong's wall takes over
	for span in [[12.0, BRIDGE_X[0]], [BRIDGE_X[1], 23.7]]:
		_rail_x(b, span[0], span[1], LEDGE_Z[1] - 0.03, P)
	# and across its west end, past Mrs. Fong's door, where it stops over the well's corner
	_rail_z(b, LEDGE_Z[0], LEDGE_Z[1], 12.03, P)
	# the service ledge round the side of the empty flat, to the back of its kitchen
	b.add_floor(SERVICE[0], SERVICE[1], SERVICE[2], SERVICE[3], Y, "serviceLedge")
	b.box(SERVICE[0], SERVICE[1], Y - 0.25, Y, SERVICE[2], SERVICE[3], c8(0x7e7a70), {"band": 1.0, "surface": "concrete", "parent": P, "name": "LedgeSlab"})
	_rail_z(b, SERVICE[2], LEDGE_Z[1], SERVICE[1] - 0.03, P)
	_rail_x(b, SERVICE[0], SERVICE[1], SERVICE[2] + 0.03, P)
	b.ref("unitWindowOutside", Vector3(24.75, Y, -19.2))
	b.ref("chainedDoor", Vector3(20.9, Y, -16.8))
	b.ref("fongDoor", Vector3(14.8, Y, -16.8))
	b.ref("northLedge", Vector3(15.0, Y, -16.8))


static func _footbridge(b: LevelBuilder) -> void:
	## Planks laid across two steel stringers, a rail each side: the way people
	## on this side have crossed the well for years.
	var x0: float = BRIDGE_X[0]
	var x1: float = BRIDGE_X[1]
	var z0: float = LEDGE_Z[1]
	var z1 := -13.0
	b.add_floor(x0, x1, z0, z1, Y, "footbridge")
	var PB := P + "/Footbridge"
	for sx in [x0 + 0.08, x1 - 0.16]:
		b.box(sx, sx + 0.08, Y - 0.22, Y - 0.06, z0 - 0.2, z1 + 0.2, c8(0x4a4a48), {"band": 1.0, "surface": "rust", "parent": PB, "name": "Stringer"})
	var z := z0
	var k := 0
	while z < z1 - 0.01:
		var w := minf(0.24, z1 - z)
		var tone := c8(0x8a6a48).darkened(0.08 * (k % 3))
		b.box(x0, x1, Y - 0.06, Y, z + 0.01, z + w - 0.01, tone, {"band": 1.0, "surface": "wood", "parent": PB, "name": "Plank"})
		z += w
		k += 1
	for rx in [x0 + 0.02, x1 - 0.02]:
		_rail_z(b, z0, z1, rx, PB)
	b.ref("footbridge", Vector3((x0 + x1) / 2, Y, (z0 + z1) / 2))


## A painted steel rail along x (posts, top rail, mid rail) at z.
static func _rail_x(b: LevelBuilder, x0: float, x1: float, z: float, parent: String) -> void:
	var col := c8(0x4f7a5a)
	b.box(x0, x1, Y + 0.93, Y + 1.0, z - 0.03, z + 0.03, col, {"band": 1.0, "fadeable": true, "surface": "metal", "parent": parent, "name": "Rail"})
	b.box(x0, x1, Y + 0.45, Y + 0.49, z - 0.02, z + 0.02, col, {"band": 1.0, "fadeable": true, "surface": "metal", "parent": parent, "name": "MidRail"})
	var n := maxi(1, roundi((x1 - x0) / 1.0))
	for i in n + 1:
		var px := x0 + (x1 - x0) * i / n
		b.box(px - 0.03, px + 0.03, Y, Y + 1.0, z - 0.03, z + 0.03, col, {"band": 1.0, "fadeable": true, "surface": "metal", "parent": parent, "name": "Post"})


static func _rail_z(b: LevelBuilder, z0: float, z1: float, x: float, parent: String) -> void:
	var col := c8(0x4f7a5a)
	b.box(x - 0.03, x + 0.03, Y + 0.93, Y + 1.0, z0, z1, col, {"band": 1.0, "fadeable": true, "surface": "metal", "parent": parent, "name": "Rail"})
	b.box(x - 0.02, x + 0.02, Y + 0.45, Y + 0.49, z0, z1, col, {"band": 1.0, "fadeable": true, "surface": "metal", "parent": parent, "name": "MidRail"})
	var n := maxi(1, roundi(absf(z1 - z0) / 1.0))
	for i in n + 1:
		var pz := z0 + (z1 - z0) * i / n
		b.box(x - 0.03, x + 0.03, Y, Y + 1.0, pz - 0.03, pz + 0.03, col, {"band": 1.0, "fadeable": true, "surface": "metal", "parent": parent, "name": "Post"})


# ----------------------------------------------------------------------------- the two flats


static func _rooms(b: LevelBuilder) -> void:
	b.room({"x0": FONG[0], "x1": FONG[1], "z0": FONG[2], "z1": FONG[3], "y": Y, "name": "Fong", "id": "fong",
		"wall": c8(0x9a8e7a), "floor": c8(0x5a4c3c), "parent": "Structure/LevelB"})
	# the flat next door: its back kitchen window a gap in the east wall
	b.room({"x0": UNIT[0], "x1": UNIT[1], "z0": UNIT[2], "z1": UNIT[3], "y": Y, "name": "Unit", "id": "unit",
		"wall": c8(0x8c8878), "floor": c8(0x4e4840), "open": {"e": [WINDOW_Z]}, "lintel": false, "parent": "Structure/LevelB"})
	var face: float = LEDGE_Z[0]        # the outer face of both flats' south walls
	# Mrs. Fong's door: shut, a radio playing low behind it
	BuildInteriors.panel_door(b, 14.3, 15.3, Y, 2.2, face, c8(0x8a4a3a), P, 1.0, "FongDoor", true)
	b.card("res://assets/textures/props/poster_1.png", Vector3(16.2, Y + 1.55, face), Vector2(0.36, 0.5), Vector3(0, 0, 1), {"parent": P, "name": "FongDoorGod", "band": 1.0, "fadeable": true})
	b.box(15.45, 15.75, Y + 1.3, Y + 1.5, face, face + 0.06, c8(0xc9463a), {"band": 1.0, "fadeable": true, "surface": "grain", "parent": P, "name": "FongMailSlot"})
	# the empty flat's door: a chain through the handle to a staple in the wall, a padlock, and the notice
	BuildInteriors.panel_door(b, 20.4, 21.4, Y, 2.2, face, c8(0x6a7a70), P, 1.0, "UnitDoor", true)
	# ...and the same door from inside the flat, on the wall's inner face
	BuildInteriors.panel_door(b, 20.4, 21.4, Y, 2.2, UNIT[3], c8(0x6a7a70), P, 1.0, "UnitDoorInside", true, true, "unit")
	var chain := c8(0x8a8a86)
	var pts := [Vector3(21.2, Y + 1.12, face + 0.13), Vector3(21.55, Y + 1.0, face + 0.1), Vector3(21.75, Y + 1.08, face + 0.03)]
	for i in pts.size() - 1:
		b.cylinder(pts[i], pts[i + 1], 0.018, b.surface("metal"), {"parent": P, "name": "Chain", "tint": chain, "band": 1.0, "cast_shadow": false, "fadeable": true})
	b.box(21.7, 21.8, Y + 1.02, Y + 1.14, face, face + 0.05, chain, {"band": 1.0, "fadeable": true, "surface": "metal", "parent": P, "name": "Staple"})
	b.box(21.5, 21.62, Y + 0.84, Y + 0.98, face + 0.08, face + 0.13, c8(0xc9a55a), {"band": 1.0, "fadeable": true, "surface": "metal", "parent": P, "name": "Padlock"})
	b.card("res://assets/textures/props/notice_rehoused.png", Vector3(20.9, Y + 1.62, face + 0.05), Vector2(0.5, 0.64), Vector3(0, 0, 1), {"parent": P, "name": "RehousedNotice", "band": 1.0, "fadeable": true})
	# the back kitchen window: a sill across the gap, a frame, and one casement swung open
	var wx: float = UNIT[1] + 0.15
	var wz0: float = WINDOW_Z[0]
	var wz1: float = WINDOW_Z[1]
	b.box(UNIT[1], UNIT[1] + 0.3, Y, Y + 0.95, wz0, wz1, c8(0x8c8878), {"band": 1.0, "surface": "plaster", "parent": P, "name": "WindowWall", "fadeable": true, "room": "unit"})
	b.box(UNIT[1] - 0.02, UNIT[1] + 0.4, Y + 0.95, Y + 1.0, wz0 - 0.05, wz1 + 0.05, c8(0x9a9a92), {"band": 1.0, "surface": "concrete", "parent": P, "name": "Sill"})
	b.box(UNIT[1], UNIT[1] + 0.3, Y + 2.05, Y + 4.2, wz0, wz1, c8(0x8c8878), {"band": 1.0, "surface": "plaster", "parent": P, "name": "WindowWall", "fadeable": true, "room": "unit"})
	for zz in [wz0, wz1 - 0.05]:
		b.box(UNIT[1] + 0.2, UNIT[1] + 0.3, Y + 1.0, Y + 2.05, zz, zz + 0.05, c8(0x3f5a4a), {"band": 1.0, "surface": "wood", "parent": P, "name": "WindowFrame"})
	b.box(UNIT[1] + 0.2, UNIT[1] + 0.3, Y + 2.0, Y + 2.05, wz0, wz1, c8(0x3f5a4a), {"band": 1.0, "surface": "wood", "parent": P, "name": "WindowFrame"})
	# the casement, hinged at the south jamb and swung out onto the ledge
	var hinge := Node3D.new()
	hinge.name = "Casement"
	hinge.position = Vector3(UNIT[1] + 0.3, Y + 1.0, wz1)
	hinge.rotation.y = deg_to_rad(-65)
	b.attach(hinge, b.group(P))
	b.tag(hinge, 1.0)
	for part in [[0.0, 0.8, 0.0, 0.05], [0.0, 0.8, 1.0, 1.05], [0.0, 0.05, 0.0, 1.05], [0.75, 0.8, 0.0, 1.05]]:
		var m := b.box(-0.03, 0.03, part[2], part[3], -part[1], -part[0], c8(0x3f5a4a), {"surface": "wood", "parent_node": hinge, "name": "CasementFrame"})
		m.remove_meta("band")
	var glass := b.box(-0.01, 0.01, 0.05, 1.0, -0.75, -0.05, c8(0x9ab8bc), {"surface": "metal", "parent_node": hinge, "name": "Pane", "cast_shadow": false})
	glass.remove_meta("band")
	b.ref("unitWindow", Vector3(wx, Y + 1.4, (wz0 + wz1) / 2))


# ----------------------------------------------------------------------------- the pump, the pipes


static func _pump(b: LevelBuilder) -> void:
	## On the well floor in the north-west corner: the building's pump, a motor
	## on a concrete plinth under a tin hood, lifting water from the well pipe.
	var PP := "Structure/LightWell/Pump"
	b.box(12.1, 13.4, 0.0, 0.25, -16.9, -15.9, c8(0x7a766c), {"band": 0.0, "surface": "concrete", "parent": PP, "name": "Plinth"})
	b.cylinder(Vector3(12.45, 0.55, -16.4), Vector3(13.05, 0.55, -16.4), 0.22, b.surface("metal"), {"parent": PP, "name": "Motor", "tint": c8(0x3f6a5a), "band": 0.0})
	b.cylinder(Vector3(13.05, 0.55, -16.4), Vector3(13.2, 0.55, -16.4), 0.14, b.surface("metal"), {"parent": PP, "name": "PumpHead", "tint": c8(0x5a5a58), "band": 0.0})
	b.box(12.3, 13.3, 0.25, 0.3, -16.7, -16.1, c8(0x4a4a48), {"band": 0.0, "surface": "metal", "parent": PP, "name": "Mount"})
	b.box(12.0, 13.5, 0.95, 1.0, -17.0, -15.8, c8(0x9aa0a0), {"band": 0.0, "surface": "rust", "parent": PP, "name": "Hood"})
	for hx in [12.05, 13.4]:
		b.box(hx, hx + 0.05, 0.25, 0.95, -16.95, -16.9, c8(0x4a4a48), {"band": 0.0, "surface": "rust", "parent": PP, "name": "HoodPost"})
	# the well pipe down into the ground, and the cable to its switch on the wall
	PropKit.pipe_run(b, [Vector3(13.2, 0.55, -16.4), Vector3(13.55, 0.55, -16.4), Vector3(13.55, -0.3, -16.4)], 0.06, GREY, PP, 0.0, "WellPipe")
	b.cylinder(Vector3(12.45, 0.7, -16.55), Vector3(12.2, 2.2, -16.95), 0.012, b.surface("grain"), {"parent": PP, "name": "Cable", "tint": c8(0x1c1c1e), "band": 0.0, "cast_shadow": false})
	b.box(12.1, 12.35, 2.1, 2.45, -17.0, -16.92, c8(0x5a6a72), {"band": 0.0, "surface": "metal", "parent": PP, "name": "SwitchBox"})
	b.ref("pump", Vector3(12.7, 0.6, -16.4))


static func _pipes(b: LevelBuilder) -> void:
	# the blue branch: off the landing's blue pipe, out over the catwalk, across
	# the well to the north wall, and along it into the empty flat, its paint
	# fading the further it goes from anyone who repaints it
	var bend := Vector3(13.0, PIPE_Y, -12.85)
	var run := [Vector3(10.2, Y + 3.3, -12.85), Vector3(13.0, Y + 3.3, -12.85), bend, Vector3(13.0, PIPE_Y, PIPE_Z),
		Vector3(22.8, PIPE_Y, PIPE_Z), Vector3(22.8, PIPE_Y, -17.7)]
	var total := 0.0
	for i in run.size() - 1:
		total += (run[i] as Vector3).distance_to(run[i + 1])
	var along := 0.0
	var PB := "Pipes/Branch"
	for i in run.size() - 1:
		var a: Vector3 = run[i]
		var c: Vector3 = run[i + 1]
		var steps := maxi(1, ceili(a.distance_to(c) / 1.2))
		for k in steps:
			var p0 := a.lerp(c, float(k) / steps)
			var p1 := a.lerp(c, float(k + 1) / steps)
			var t := clampf((along + a.distance_to(p0) - 5.0) / (total - 7.0), 0.0, 1.0)
			b.cylinder(p0, p1, 0.08, b.surface("metal"), {"parent": PB, "name": "BranchRun", "tint": BLUE.lerp(GREY, t), "band": 1.0, "segments": 12, "fadeable": p0.z < -16.0 and p1.z < -16.0})
		along += a.distance_to(c)
		if i > 0:
			b.piece(PropKit._sphere(0.1), a, b.surface("metal"), {"parent": PB, "name": "BranchElbow", "tint": BLUE.lerp(GREY, clampf((along - 5.0) / (total - 7.0), 0.0, 1.0)), "band": 1.0})
	# the clamp that marks it, and brackets holding it to the wall
	b.cylinder(Vector3(13.0, PIPE_Y, -14.55), Vector3(13.0, PIPE_Y, -14.45), 0.11, b.surface("metal"), {"parent": PB, "name": "Clamp", "tint": c8(0xc9a55a), "band": 1.0})
	b.box(12.96, 13.04, PIPE_Y + 0.1, PIPE_Y + 0.14, -14.56, -14.44, c8(0xc9a55a), {"band": 1.0, "surface": "metal", "parent": PB, "name": "ClampBolt", "cast_shadow": false})
	var wx := 14.0
	while wx < 22.5:
		b.box(wx - 0.03, wx + 0.03, PIPE_Y - 0.12, PIPE_Y + 0.12, LEDGE_Z[0], PIPE_Z + 0.04, c8(0x4a4a48), {"band": 1.0, "fadeable": true, "surface": "metal", "parent": PB, "name": "PipeBracket", "cast_shadow": false})
		wx += 1.9
	b.ref("branchCrossing", Vector3(13.0, Y, -12.2))
	b.ref("knock", Vector3(13.0, PIPE_Y, -14.5))
	# the old line beside it: the same blue once, faded nearly white, turning down
	# the well to a capped stub. Nothing has run through it for years.
	var old := Color("9ab4c8")
	PropKit.pipe_run(b, [Vector3(10.4, Y + 2.9, -12.55), Vector3(13.55, Y + 2.9, -12.55), Vector3(13.55, 0.6, -12.55)], 0.075, old, "Pipes/OldLine", 1.0, "OldLine")
	b.cylinder(Vector3(13.55, 0.6, -12.55), Vector3(13.55, 0.5, -12.55), 0.1, b.surface("rust"), {"parent": "Pipes/OldLine", "name": "Cap", "tint": c8(0x6a5a48), "band": 0.0})
	# the riser from the pump, up the well's corner to the branch
	PropKit.pipe_run(b, [Vector3(12.45, 0.8, -16.55), Vector3(12.45, 1.2, -16.55), Vector3(12.45, 1.2, PIPE_Z), Vector3(12.45, PIPE_Y, PIPE_Z),
		Vector3(13.0, PIPE_Y, PIPE_Z)], 0.07, GREY, "Pipes/Riser", 0.0, "Riser")
	# Mrs. Fong's tap: a branch off it behind the second air-conditioner, into her wall
	PropKit.pipe_run(b, [Vector3(15.9, PIPE_Y, PIPE_Z), Vector3(15.9, PIPE_Y - 0.35, PIPE_Z), Vector3(15.9, PIPE_Y - 0.35, LEDGE_Z[0] - 0.05)],
		0.04, GREY, "Pipes/FongTap", 1.0, "FongTap", true)
	b.cylinder(Vector3(15.9, PIPE_Y - 0.2, PIPE_Z), Vector3(15.9, PIPE_Y - 0.2, PIPE_Z + 0.08), 0.07, b.surface("metal"), {"parent": "Pipes/FongTap", "name": "FongStopcock", "tint": c8(0xb8392e), "band": 1.0, "fadeable": true})


static func _air_conditioners(b: LevelBuilder) -> void:
	## Three window units on brackets on the north wall, standing off it so the
	## branch runs behind them: from the well they hide where it goes.
	var face: float = LEDGE_Z[0]
	var PA := P + "/AirCon"
	for x in [14.0, 15.5, 19.1]:
		var x1: float = x + 0.8
		var y0 := Y + 2.1
		var z0 := face + 0.28
		b.box(x, x1, y0, y0 + 0.72, z0, z0 + 0.55, c8(0xc8c6be), {"band": 1.0, "fadeable": true, "surface": "metal", "parent": PA, "name": "AirCon"})
		for k in 6:
			b.box(x + 0.06, x1 - 0.06, y0 + 0.08 + k * 0.1, y0 + 0.11 + k * 0.1, z0 + 0.55, z0 + 0.57, c8(0x8a8a84), {"band": 1.0, "fadeable": true, "surface": "metal", "parent": PA, "name": "Grille", "cast_shadow": false})
		for bx in [x + 0.1, x1 - 0.14]:
			b.box(bx, bx + 0.04, y0 - 0.06, y0, face, z0 + 0.5, c8(0x4a4a48), {"band": 1.0, "fadeable": true, "surface": "rust", "parent": PA, "name": "AirConBracket"})
			b.cylinder(Vector3(bx + 0.02, y0 - 0.45, face + 0.02), Vector3(bx + 0.02, y0 - 0.04, z0 + 0.45), 0.018, b.surface("rust"), {"parent": PA, "name": "AirConStrut", "tint": c8(0x4a4a48), "band": 1.0, "fadeable": true})
		# the drip tray and its rust stain down the wall
		b.box(x + 0.2, x1 - 0.2, y0 - 0.05, y0, z0 + 0.4, z0 + 0.58, c8(0x5a5a58), {"band": 1.0, "fadeable": true, "surface": "metal", "parent": PA, "name": "DripTray", "cast_shadow": false})


# ----------------------------------------------------------------------------- inside the empty flat


static func _unit_inside(b: LevelBuilder) -> void:
	var x0: float = UNIT[0]
	var x1: float = UNIT[1]
	var z0: float = UNIT[2]
	var z1: float = UNIT[3]
	# the branch comes through the south wall, up, and across under the ceiling
	# to the manifold on the far (north) wall: three valves, each on its own pipe
	var mz := MANIFOLD_Z
	var ceil := Y + 3.75
	PropKit.pipe_run(b, [Vector3(22.8, PIPE_Y, -17.7), Vector3(22.8, PIPE_Y, -17.82), Vector3(22.8, ceil, -17.82), Vector3(22.8, ceil, mz),
		Vector3(22.8, MANIFOLD_Y, mz)], 0.07, GREY, PU, 1.0, "Inlet")
	b.cylinder(Vector3(20.3, MANIFOLD_Y, mz), Vector3(22.8, MANIFOLD_Y, mz), 0.07, b.surface("metal"), {"parent": PU, "name": "Manifold", "tint": GREY, "band": 1.0})
	for vx in VALVE_X:
		b.cylinder(Vector3(vx, MANIFOLD_Y, mz), Vector3(vx, MANIFOLD_Y + 0.35, mz), 0.05, b.surface("metal"), {"parent": PU, "name": "ValveBody", "tint": c8(0x7a6a50), "band": 1.0})
		# the handwheel, facing into the room
		var wheel := TorusMesh.new()
		wheel.inner_radius = 0.085
		wheel.outer_radius = 0.11
		wheel.rings = 16
		wheel.ring_segments = 6
		b.piece(wheel, Vector3(vx, MANIFOLD_Y + 0.2, mz + 0.12), b.surface("metal"), {"parent": PU, "name": "Handwheel", "tint": c8(0xb8392e), "band": 1.0, "rotation": Vector3(PI / 2, 0, 0)})
		b.cylinder(Vector3(vx, MANIFOLD_Y + 0.2, mz), Vector3(vx, MANIFOLD_Y + 0.2, mz + 0.12), 0.015, b.surface("metal"), {"parent": PU, "name": "Spindle", "tint": c8(0x5a5a58), "band": 1.0, "cast_shadow": false})
	# where each goes. From the front the first and the third look the same:
	# straight up. From the side, the first turns and runs off through the west
	# wall to the neighbour's; the third goes up through the ceiling, to the tank
	# on the roof. The second runs along the wall to this flat's own old sink.
	var top := Y + 4.15
	PropKit.pipe_run(b, [Vector3(VALVE_X[0], MANIFOLD_Y + 0.35, mz), Vector3(VALVE_X[0], Y + 3.3, mz), Vector3(VALVE_X[0], Y + 3.3, -19.4),
		Vector3(x0 + 0.02, Y + 3.3, -19.4)], 0.05, GREY, PU, 1.0, "ToNeighbour")
	PropKit.pipe_run(b, [Vector3(VALVE_X[1], MANIFOLD_Y + 0.35, mz), Vector3(VALVE_X[1], Y + 2.4, mz), Vector3(23.72, Y + 2.4, mz),
		Vector3(23.72, Y + 2.4, -20.2), Vector3(23.72, Y + 1.2, -20.2)], 0.045, GREY, PU, 1.0, "ToSink")
	# ...down to a brass bib tap over the sink, its spout turned into the basin
	b.cylinder(Vector3(23.72, Y + 1.22, -20.2), Vector3(23.72, Y + 1.08, -20.2), 0.05, b.surface("metal"), {"parent": PU, "name": "TapBody", "tint": c8(0xa8894a), "band": 1.0})
	b.cylinder(Vector3(23.72, Y + 1.1, -20.2), Vector3(23.6, Y + 1.06, -20.2), 0.022, b.surface("metal"), {"parent": PU, "name": "TapSpout", "tint": c8(0xa8894a), "band": 1.0, "cast_shadow": false})
	b.cylinder(Vector3(23.6, Y + 1.06, -20.2), Vector3(23.6, Y + 0.98, -20.2), 0.02, b.surface("metal"), {"parent": PU, "name": "TapSpout", "tint": c8(0xa8894a), "band": 1.0, "cast_shadow": false})
	b.box(23.69, 23.75, Y + 1.24, Y + 1.27, -20.3, -20.1, c8(0xb8392e), {"band": 1.0, "surface": "metal", "parent": PU, "name": "TapHandle", "cast_shadow": false})
	b.box(23.74, 23.8, Y + 1.1, Y + 1.3, -20.25, -20.15, c8(0x5a5a58), {"band": 1.0, "surface": "metal", "parent": PU, "name": "TapClip", "cast_shadow": false})
	PropKit.pipe_run(b, [Vector3(VALVE_X[2], MANIFOLD_Y + 0.35, mz), Vector3(VALVE_X[2], Y + 2.9, mz), Vector3(VALVE_X[2], Y + 2.9, -19.4),
		Vector3(VALVE_X[2], top, -19.4)], 0.06, GREY, PU, 1.0, "ToTank")
	b.box(VALVE_X[2] - 0.12, VALVE_X[2] + 0.12, top - 0.03, top, -19.52, -19.28, c8(0x5a5a58), {"band": 1.0, "surface": "metal", "parent": PU, "name": "CeilingCollar", "cast_shadow": false})
	b.box(x0, x0 + 0.03, Y + 3.18, Y + 3.42, -19.52, -19.28, c8(0x5a5a58), {"band": 1.0, "surface": "metal", "parent": PU, "name": "WallCollar", "cast_shadow": false})
	# the back kitchen, under the window: a cement counter and the old sink
	b.box(x1 - 0.62, x1, Y, Y + 0.82, -21.2, -20.0, c8(0x8e8a80), {"band": 1.0, "surface": "concrete", "parent": PU, "name": "Counter"})
	b.add_obstacle(x1 - 0.62, x1, -21.2, -20.0, Y, "unitCounter")
	b.box(x1 - 0.6, x1 - 0.05, Y + 0.6, Y + 0.84, -20.5, -19.95, c8(0xa8aaa4), {"band": 1.0, "surface": "metal", "parent": PU, "name": "Sink"})
	b.box(x1 - 0.55, x1 - 0.1, Y + 0.64, Y + 0.66, -20.45, -20.0, c8(0x5a5a58), {"band": 1.0, "surface": "metal", "parent": PU, "name": "SinkBasin", "cast_shadow": false})
	b.box(x1 - 0.66, x1, Y, Y + 0.6, -20.5, -19.95, c8(0x6a665c), {"band": 1.0, "surface": "concrete", "parent": PU, "name": "SinkStand"})
	b.add_obstacle(x1 - 0.66, x1, -20.5, -19.95, Y, "unitSink")
	b.ref("unitSink", Vector3(x1 - 0.32, Y + 0.66, -20.22))
	# what the family left: the marks of their furniture, a calendar, a stool, old papers
	var pale := c8(0xa8a494)
	b.box(18.4, 19.6, Y + 0.1, Y + 2.0, z0 + 0.0, z0 + 0.012, pale, {"band": 1.0, "surface": "plaster", "parent": PU, "name": "PaleMark", "cast_shadow": false})
	b.box(20.2, 21.8, Y + 0.1, Y + 0.95, z0, z0 + 0.012, pale, {"band": 1.0, "surface": "plaster", "parent": PU, "name": "PaleMark", "cast_shadow": false})
	b.box(22.2, 22.6, Y + 1.5, Y + 1.95, z0, z0 + 0.012, pale, {"band": 1.0, "surface": "plaster", "parent": PU, "name": "PaleMark", "cast_shadow": false})
	b.card("res://assets/textures/props/calendar_1992.png", Vector3(19.0, Y + 2.35, z0), Vector2(0.4, 0.6), Vector3(0, 0, 1), {"parent": PU, "name": "OldCalendar", "band": 1.0})
	var st := Node3D.new()
	st.name = "BrokenStool"
	st.position = Vector3(19.4, Y, -19.3)
	st.rotation = Vector3(0.0, 0.5, 1.35)
	b.attach(st, b.group(PU))
	b.tag(st, 1.0)
	var seat := b.box(-0.17, 0.17, -0.04, 0.0, -0.17, 0.17, c8(0x8a6a48), {"surface": "wood", "parent_node": st, "name": "Seat"})
	seat.remove_meta("band")
	for lg in [[-0.13, -0.13], [0.1, -0.13], [0.1, 0.1]]:
		var leg := b.box(lg[0], lg[0] + 0.03, -0.45, -0.04, lg[1], lg[1] + 0.03, c8(0x6b4a30), {"surface": "wood", "parent_node": st, "name": "Leg"})
		leg.remove_meta("band")
	for k in 4:
		var px := 18.6 + k * 0.9
		var pz := -20.6 + (k % 2) * 1.1
		b.box(px, px + 0.42, Y, Y + 0.008, pz, pz + 0.3, c8(0xe0d8c4).darkened(0.08 * k), {"band": 1.0, "surface": "grain", "parent": PU, "name": "OldNewspaper", "cast_shadow": false})
	# the chain, from inside: a loop of it showing through the gap under the door
	b.box(20.95, 21.35, Y, Y + 0.02, -17.76, -17.68, c8(0x8a8a86), {"band": 1.0, "surface": "metal", "parent": PU, "name": "ChainBelow", "cast_shadow": false})
	# a bare bulb on its flex, dead: the light is what comes through the window
	b.cylinder(Vector3(21.0, Y + 4.1, -19.4), Vector3(21.0, Y + 3.2, -19.4), 0.006, b.surface("grain"), {"parent": PU, "name": "Flex", "tint": c8(0x1c1c1e), "band": 1.0, "cast_shadow": false})
	b.piece(PropKit._sphere(0.05), Vector3(21.0, Y + 3.15, -19.4), b.surface("metal"), {"parent": PU, "name": "DeadBulb", "tint": c8(0xd8d4c8), "band": 1.0})
	b.lamp(Vector3(x1 - 0.6, Y + 1.6, -19.2), Color(0.95, 0.88, 0.75), 1.6, 5.5, {"name": "WindowLight"})
	b.ref("unitInside", Vector3(23.2, Y, -19.2))
	b.ref("unitValves", Vector3(21.4, Y, MANIFOLD_Z + 0.5))
