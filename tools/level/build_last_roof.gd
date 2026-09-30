class_name BuildLastRoof
extends RefCounted

## Chapter 6, The Last Roof: the evening everyone left comes up anyway.
##
## Folding chairs not worth moving, a table of leftover food, a thermos, Mr.
## Ng's cages, Mr. Ho's toolbox, the drying frames taken down. Three strings of
## bulbs: over the gathering, from the stair hut round by the mast and the
## tank, and over Mr. Ng's old corner, each with its own light. And the
## extension leads they hang from, run the way Ho ran them: into the stair hut
## and out of its back; across another lead that drops over the parapet; up a
## pole to the mast's board; round behind the tank and under the coop's frame
## to the last board, by the spot where Mei photographed Mr. Ng on the first day.
##
## Everything here is under ChapterProps/Ch6. No random draws.

const R := LevelBuilder.LEVEL_ROOF
const G := "ChapterProps/Ch6"
const SECTIONS := ["Gathering", "North", "NgCorner"]

# the bulb strings, as runs of points (each string hangs between them)
const STRINGS := {
	"Gathering": [Vector3(-7.4, R + 2.5, -9.4), Vector3(-4.2, R + 2.3, -12.9), Vector3(-1.8, R + 2.6, -13.5), Vector3(3.6, R + 2.4, -12.8), Vector3(8.75, R + 2.5, -13.2)],
	"North": [Vector3(10.2, R + 2.75, -15.05), Vector3(11.25, R + 3.3, -21.1), Vector3(6.5, R + 2.65, -21.35)],
	"NgCorner": [Vector3(5.06, R + 2.2, -21.5), Vector3(4.6, R + 2.5, -17.6), Vector3(1.2, R + 2.5, -18.1), Vector3(0.95, R + 2.2, -21.5)],
}
const LIGHTS := {
	"Gathering": Vector3(-3.0, R + 2.2, -11.4),
	"North": Vector3(9.6, R + 2.5, -18.2),
	"NgCorner": Vector3(3.0, R + 2.2, -19.2),
}


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	_gathering(b)
	_bulbs(b)
	_leads(b)
	# Kit, back for the evening, and Mr. Kwok with the day's paper
	b.resident("kit", "kit", Vector3(-3.8, R, -10.6), {"facing": Vector3(-0.5, 0, -1), "parent": G})


static func _gathering(b: LevelBuilder) -> void:
	var P := G + "/Gathering"
	# a folding table with what's left: a pot, bowls, a thermos, oranges
	PropKit.table(b, -5.3, -4.1, -12.1, -11.35, R, 0.72, c8(0x9a9aa0), P, "metal")
	b.add_obstacle(-5.3, -4.1, -12.1, -11.35, R, "partyTable", "chapter:Ch6")
	b.cylinder(Vector3(-4.95, R + 0.72, -11.7), Vector3(-4.95, R + 0.95, -11.7), 0.16, b.surface("metal"), {"parent": P, "name": "Pot", "tint": c8(0x8a9aa0), "band": 2.0})
	b.cylinder(Vector3(-4.45, R + 0.72, -11.9), Vector3(-4.45, R + 1.08, -11.9), 0.07, b.surface("metal"), {"parent": P, "name": "Thermos", "tint": c8(0xb8392e), "band": 2.0})
	for k in 3:
		b.box(-4.7 + k * 0.18, -4.58 + k * 0.18, R + 0.72, R + 0.78, -11.55, -11.43, c8(0xf2eee4), {"band": 2.0, "surface": "grain", "parent": P, "name": "Bowl", "cast_shadow": false})
	for k in 4:
		var o := b.box(-4.35 + (k % 2) * 0.09, -4.27 + (k % 2) * 0.09, R + 0.72, R + 0.8, -11.5 - (k / 2) * 0.09, -11.42 - (k / 2) * 0.09, c8(0xe0802a),
			{"band": 2.0, "surface": "grain", "parent": P, "name": "Orange", "cast_shadow": false})
		o.name = "Orange"
	# folding chairs nobody's taking: two open, three folded against the parapet
	for spec in [[-6.3, -12.6], [-2.9, -12.9]]:
		var cx: float = spec[0]
		var cz: float = spec[1]
		b.box(cx - 0.22, cx + 0.22, R + 0.44, R + 0.48, cz - 0.2, cz + 0.2, c8(0x3f6fa8), {"band": 2.0, "surface": "metal", "parent": P, "name": "ChairSeat"})
		b.box(cx - 0.22, cx + 0.22, R + 0.48, R + 0.95, cz + 0.17, cz + 0.2, c8(0x3f6fa8), {"band": 2.0, "surface": "metal", "parent": P, "name": "ChairBack"})
		for lx in [-0.2, 0.17]:
			b.box(cx + lx, cx + lx + 0.03, R, R + 0.44, cz - 0.18, cz + 0.18, c8(0x5a5a58), {"band": 2.0, "surface": "metal", "parent": P, "name": "ChairLeg", "cast_shadow": false})
	for k in 3:
		b.box(-9.9, -9.84, R, R + 0.9, -14.4 + k * 0.5, -13.95 + k * 0.5, c8(0x3f6fa8), {"band": 2.0, "surface": "metal", "parent": P, "name": "FoldedChair"})
	# Mr. Ho's toolbox, open; the drying frames down, poles laid by the posts
	b.box(-2.2, -1.7, R, R + 0.25, -12.3, -12.05, c8(0xb8392e), {"band": 2.0, "surface": "metal", "parent": P, "name": "Toolbox"})
	for k in 3:
		b.box(-8.8, -3.0, R, R + 0.05, -8.2 + k * 0.1, -8.15 + k * 0.1, c8(0x8a8a86), {"band": 2.0, "surface": "metal", "parent": P, "name": "FramePole"})
	# Mr. Ng's cages, stacked by the coop, one basket open
	for spec in [[6.0, -20.2, 0.0], [6.0, -20.2, 0.45], [5.4, -19.6, 0.0]]:
		b.box(spec[0] - 0.28, spec[0] + 0.28, R + spec[2], R + spec[2] + 0.42, spec[1] - 0.22, spec[1] + 0.22, c8(0xb09a6a),
			{"band": 2.0, "surface": "wood", "parent": P, "name": "Cage"})
	b.add_obstacle(5.1, 6.3, -20.45, -19.35, R, "cages", "chapter:Ch6")
	b.ref("partyTable", Vector3(-4.7, R, -10.9))


static func _bulbs(b: LevelBuilder) -> void:
	var wire := c8(0x1c1c1e)
	for sec in SECTIONS:
		var pts: Array = STRINGS[sec]
		var P: String = G + "/Bulbs/" + sec
		for i in pts.size() - 1:
			var a: Vector3 = pts[i]
			var c: Vector3 = pts[i + 1]
			# the flex sags between its ends; bulbs hang off it at arm's-length spacing
			var n := maxi(2, roundi(a.distance_to(c) / 0.9))
			var prev := a
			for k in range(1, n + 1):
				var t := float(k) / n
				var p := a.lerp(c, t) - Vector3(0, 0.35 * sin(PI * t), 0)
				b.cylinder(prev, p, 0.008, b.surface("grain"), {"parent": P, "name": "Flex", "tint": wire, "band": 2.0, "cast_shadow": false})
				if k < n:
					var bulb := MeshInstance3D.new()
					var sm := SphereMesh.new()
					sm.radius = 0.045
					sm.height = 0.1
					sm.radial_segments = 8
					sm.rings = 4
					bulb.mesh = sm
					bulb.name = "Bulb"
					bulb.position = p - Vector3(0, 0.07, 0)
					bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					bulb.material_override = b.emissive(Color(1.0, 0.84, 0.55), 3.0)
					b.attach(bulb, b.group(P))
					b.tag(bulb, 2.0)
				prev = p
		# the light the string throws, switched with it (no band: the roof keeps it)
		var lamp := OmniLight3D.new()
		lamp.name = "Glow"
		lamp.position = LIGHTS[sec]
		lamp.light_color = Color(1.0, 0.78, 0.46)
		lamp.light_energy = 1.6
		lamp.omni_range = 6.5
		lamp.shadow_enabled = false
		b.attach(lamp, b.group(P))
	# the poles the strings hang from where there's nothing else
	for pole in [Vector3(-7.4, R, -9.4), Vector3(-4.2, R, -12.9), Vector3(-1.8, R, -13.5), Vector3(3.6, R, -12.8), Vector3(4.6, R, -17.6), Vector3(1.2, R, -18.1)]:
		b.box(pole.x - 0.03, pole.x + 0.03, R, R + 2.7, pole.z - 0.03, pole.z + 0.03, c8(0x9a8a60), {"band": 2.0, "surface": "wood", "parent": G + "/Bulbs", "name": "Pole"})


static func _run(b: LevelBuilder, pts: Array, parent: String, col: Color) -> void:
	for i in pts.size() - 1:
		b.cylinder(pts[i], pts[i + 1], 0.014, b.surface("grain"), {"parent": parent, "name": "Lead", "tint": col, "band": 2.0, "cast_shadow": false})


static func _board(b: LevelBuilder, at: Vector3, parent: String, board_name: String) -> void:
	b.box(at.x - 0.2, at.x + 0.2, R, R + 0.07, at.z - 0.08, at.z + 0.08, c8(0xe8e4d8), {"band": 2.0, "surface": "metal", "parent": parent, "name": board_name})
	for k in 3:
		b.box(at.x - 0.14 + k * 0.1, at.x - 0.1 + k * 0.1, R + 0.07, R + 0.075, at.z - 0.03, at.z + 0.03, c8(0x2a2a2a), {"band": 2.0, "surface": "metal", "parent": parent, "name": "Socket", "cast_shadow": false})


static func _leads(b: LevelBuilder) -> void:
	var P := G + "/Leads"
	var y := R + 0.03
	var orange := c8(0xc9702a)
	var black := c8(0x2a2a2a)
	# the gathering's string comes down the hut's south wall and in through a hole at its foot...
	_run(b, [Vector3(8.75, R + 2.5, -13.2), Vector3(9.25, R + 2.0, -12.37), Vector3(9.25, y, -12.37)], P, orange)
	b.box(9.15, 9.35, R, R + 0.12, -12.42, -12.38, c8(0x141210), {"band": 2.0, "surface": "concrete", "parent": P, "name": "Hole", "cast_shadow": false})
	# ...and out of a gap at the back, and north to where it crosses the other
	_run(b, [Vector3(9.7, y, -15.02), Vector3(9.7, y, -16.4), Vector3(9.25, y, -17.25)], P, orange)
	# the crossing: from the front the two lie one over the other
	# (the hut's lead goes on up a pole and over to the mast's board...)
	_run(b, [Vector3(9.25, y, -17.25), Vector3(9.2, y, -17.35), Vector3(10.85, R + 2.2, -17.5), Vector3(11.1, R + 2.0, -19.9), Vector3(11.0, y, -20.0)], P, orange)
	b.box(10.82, 10.88, R, R + 2.3, -17.53, -17.47, c8(0x9a8a60), {"band": 2.0, "surface": "wood", "parent": P, "name": "LeadPole"})
	# (...the other, from somewhere west, runs under it and drops over the east parapet)
	_run(b, [Vector3(7.2, y, -17.0), Vector3(9.2, y, -17.25), Vector3(12.0, R + 0.9, -17.4), Vector3(12.35, R - 1.8, -17.4)], P, black)
	_board(b, Vector3(11.3, R, -17.3), P, "WrongBoard")
	_board(b, Vector3(10.95, R, -20.1), P, "MastBoard")
	# the mast board's own lead, round behind the tank and under the coop's frame...
	_run(b, [Vector3(10.95, y, -20.2), Vector3(10.7, y, -22.7), Vector3(7.9, y, -22.8), Vector3(6.3, y, -21.4), Vector3(5.2, y, -21.3),
		Vector3(5.06, R + 0.25, -21.42), Vector3(4.9, y, -20.6), Vector3(4.45, y, -19.8)], P, orange)
	# ...to the last board, by Mr. Ng's old corner
	_board(b, Vector3(4.3, R, -19.75), P, "LastBoard")
	b.ref("hutLead", Vector3(9.25, R, -11.9))
	b.ref("hutSide", Vector3(10.2, R, -13.7))
	b.ref("leadsCross", Vector3(9.2, R, -17.0))
	b.ref("wrongBoard", Vector3(11.3, R, -17.0))
	b.ref("mastBoard", Vector3(10.95, R, -19.6))
	b.ref("lastBoard", Vector3(4.3, R, -19.3))
