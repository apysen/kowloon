class_name PropKit
extends RefCounted

## Furniture and fittings built from parts, so they read as objects in the
## HD-2D close-up instead of coloured boxes. Collision is never added here:
## the room builders add the same footprints the slice used, so play is
## unchanged.

static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func table(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, col: Color, parent: String, top_surface := "wood") -> void:
	var t := 0.05
	b.box(x0, x1, y + h - t, y + h, z0, z1, col, {"surface": top_surface, "parent": parent, "name": "TableTop"})
	var leg := 0.06
	for x in [x0 + 0.04, x1 - 0.04 - leg]:
		for z in [z0 + 0.04, z1 - 0.04 - leg]:
			b.box(x, x + leg, y, y + h - t, z, z + leg, col.darkened(0.2), {"surface": "wood", "parent": parent, "name": "Leg"})
	b.box(x0 + 0.06, x1 - 0.06, y + h - t - 0.08, y + h - t, z0 + 0.06, z0 + 0.1, col.darkened(0.25), {"surface": "wood", "parent": parent, "name": "Apron"})
	b.box(x0 + 0.06, x1 - 0.06, y + h - t - 0.08, y + h - t, z1 - 0.1, z1 - 0.06, col.darkened(0.25), {"surface": "wood", "parent": parent, "name": "Apron"})


static func stool(b: LevelBuilder, x: float, z: float, y: float, col: Color, parent: String, h := 0.45) -> void:
	b.box(x - 0.17, x + 0.17, y + h - 0.04, y + h, z - 0.17, z + 0.17, col, {"surface": "grain", "parent": parent, "name": "StoolSeat"})
	for dx in [-0.13, 0.1]:
		for dz in [-0.13, 0.1]:
			b.box(x + dx, x + dx + 0.03, y, y + h - 0.04, z + dz, z + dz + 0.03, col.darkened(0.2), {"surface": "grain", "parent": parent, "name": "StoolLeg"})


static func bed(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, frame: Color, sheet: Color, parent: String, pillow_at_x0 := true) -> void:
	b.box(x0, x1, y, y + 0.35, z0, z1, frame, {"surface": "wood", "parent": parent, "name": "BedFrame"})
	b.box(x0 + 0.04, x1 - 0.04, y + 0.35, y + 0.55, z0 + 0.04, z1 - 0.04, sheet, {"surface": "fabric", "parent": parent, "name": "Mattress"})
	var px0 := x0 + 0.1 if pillow_at_x0 else x1 - 0.5
	b.box(px0, px0 + 0.4, y + 0.55, y + 0.66, z0 + 0.15, z1 - 0.15, c8(0xf0ebdf), {"surface": "fabric", "parent": parent, "name": "Pillow"})
	var bx0 := x0 + 0.6 if pillow_at_x0 else x0 + 0.06
	var bx1 := x1 - 0.06 if pillow_at_x0 else x1 - 0.6
	b.box(bx0, bx1, y + 0.55, y + 0.62, z0 + 0.02, z1 - 0.02, c8(0x6f7d62).lerp(sheet, 0.2), {"surface": "fabric", "parent": parent, "name": "Blanket"})
	# headboard
	var hx := x0 if pillow_at_x0 else x1 - 0.06
	b.box(hx, hx + 0.06, y, y + 0.95, z0, z1, frame.darkened(0.1), {"surface": "wood", "parent": parent, "name": "Headboard"})


static func shelf(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, col: Color, parent: String, shelves := 3) -> void:
	b.box(x0, x1, y, y + h, z0, z0 + 0.03, col.darkened(0.15), {"surface": "wood", "parent": parent, "name": "ShelfBack"})
	for side in [x0, x1 - 0.04]:
		b.box(side, side + 0.04, y, y + h, z0, z1, col, {"surface": "wood", "parent": parent, "name": "ShelfSide"})
	for i in shelves + 1:
		var yy := y + 0.05 + (h - 0.1) * i / shelves
		b.box(x0, x1, yy, yy + 0.03, z0, z1, col, {"surface": "wood", "parent": parent, "name": "ShelfBoard"})
		if i < shelves:
			# jars, tins and bundles on each shelf
			var x := x0 + 0.08
			while x < x1 - 0.14:
				var w := 0.06 + b.rand.randf() * 0.1
				var hh := 0.08 + b.rand.randf() * 0.18
				var c: Variant = [c8(0xa8453a), c8(0xe0c060), c8(0x4f7fb0), c8(0xe8e2d0), c8(0x6f7d62), c8(0x8a5a3a)][b.rand.randi() % 6]
				b.box(x, x + w, yy + 0.03, yy + 0.03 + hh, z0 + 0.05, minf(z1 - 0.03, z0 + 0.05 + w), c, {"surface": "grain", "parent": parent, "name": "Item", "cast_shadow": false})
				x += w + 0.02 + b.rand.randf() * 0.06


static func shelf_z(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, col: Color, parent: String, shelves := 3) -> void:
	## A shelf whose back is against a west wall (depth along x).
	b.box(x0, x0 + 0.03, y, y + h, z0, z1, col.darkened(0.15), {"surface": "wood", "parent": parent, "name": "ShelfBack"})
	for side in [z0, z1 - 0.04]:
		b.box(x0, x1, y, y + h, side, side + 0.04, col, {"surface": "wood", "parent": parent, "name": "ShelfSide"})
	for i in shelves + 1:
		var yy := y + 0.05 + (h - 0.1) * i / shelves
		b.box(x0, x1, yy, yy + 0.03, z0, z1, col, {"surface": "wood", "parent": parent, "name": "ShelfBoard"})
		if i < shelves:
			var z := z0 + 0.08
			while z < z1 - 0.14:
				var w := 0.06 + b.rand.randf() * 0.1
				var hh := 0.08 + b.rand.randf() * 0.18
				var c: Variant = [c8(0xa8453a), c8(0xe0c060), c8(0x4f7fb0), c8(0xe8e2d0), c8(0x6f7d62), c8(0x8a5a3a)][b.rand.randi() % 6]
				b.box(x0 + 0.05, minf(x1 - 0.03, x0 + 0.05 + w), yy + 0.03, yy + 0.03 + hh, z, z + w, c, {"surface": "grain", "parent": parent, "name": "Item", "cast_shadow": false})
				z += w + 0.02 + b.rand.randf() * 0.06


static func cardboard(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, col: Color, parent: String, label_side := "s") -> void:
	b.box(x0, x1, y0, y1, z0, z1, col, {"surface": "grain", "parent": parent, "name": "Carton"})
	# packing tape over the lid and down the faces
	var tape := c8(0xd8cfa8)
	var cx := (x0 + x1) * 0.5
	b.box(cx - 0.05, cx + 0.05, y1, y1 + 0.004, z0 - 0.003, z1 + 0.003, tape, {"surface": "grain", "parent": parent, "name": "Tape", "cast_shadow": false})
	b.box(cx - 0.05, cx + 0.05, y1 - 0.12, y1, z1, z1 + 0.004, tape, {"surface": "grain", "parent": parent, "name": "Tape", "cast_shadow": false})
	if label_side == "s":
		b.box(x0 + 0.1, x0 + 0.34, y0 + 0.2, y0 + 0.34, z1, z1 + 0.004, c8(0x3a2a1a), {"surface": "grain", "parent": parent, "name": "Marker", "cast_shadow": false})


## A standing fan whose head blows toward `face` (flat, in x/z).
static func fan(b: LevelBuilder, x: float, z: float, y: float, parent: String, face := Vector3(0, 0, 1)) -> Node3D:
	var metal := b.surface("metal")
	var dir := Vector3(face.x, 0, face.z).normalized()
	var yaw := atan2(dir.x, dir.z)
	b.box(x - 0.2, x + 0.2, y, y + 0.05, z - 0.2, z + 0.2, c8(0x3d4a52), {"surface": "metal", "parent": parent, "name": "FanBase"})
	b.box(x - 0.025, x + 0.025, y + 0.05, y + 1.2, z - 0.025, z + 0.025, c8(0x444444), {"surface": "metal", "parent": parent, "name": "FanPole"})
	# the head turns on the pole: motor behind, guard and blades in front
	var head := Node3D.new()
	head.name = "FanHead"
	head.position = Vector3(x, y, z)
	head.rotation.y = yaw
	b.attach(head, b.group(parent))
	b.tag(head, b.band_of(y + 0.5))
	var motor := b.box(-0.1, 0.1, 1.14, 1.32, -0.14, 0.06, c8(0x5a7a80), {"surface": "metal", "parent_node": head, "name": "FanMotor"})
	motor.remove_meta("band")
	var front := Vector3(x, y + 1.25, z) + dir * 0.1
	var cage := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.3
	tm.outer_radius = 0.33
	cage.mesh = tm
	cage.name = "FanGuard"
	cage.material_override = metal
	cage.set_instance_shader_parameter("tint", c8(0x7da0a8))
	cage.rotation = Vector3(PI / 2, yaw, 0)
	cage.position = front
	b.attach(cage, b.group(parent))
	b.tag(cage, b.band_of(y + 0.5))
	var rotor := Node3D.new()
	rotor.name = "FanRotor"
	rotor.position = front
	rotor.rotation.y = yaw        # it spins about its own z, so the blades turn in the guard
	b.attach(rotor, b.group(parent))
	b.tag(rotor, b.band_of(y + 0.5))
	for i in 3:
		var pivot := Node3D.new()
		pivot.name = "BladeArm"
		pivot.rotation.z = TAU * i / 3.0
		b.attach(pivot, rotor)
		var blade := b.box(-0.04, 0.04, 0.02, 0.27, -0.01, 0.01, c8(0x9ab8bc), {"surface": "metal", "parent_node": pivot, "name": "Blade"})
		blade.remove_meta("band")
	return rotor


static func radio(b: LevelBuilder, x0: float, x1: float, y0: float, z0: float, z1: float, parent: String) -> MeshInstance3D:
	var body := b.box(x0, x1, y0, y0 + 0.3, z0, z1, c8(0x7a2e22), {"surface": "wood", "parent": parent, "name": "Radio"})
	b.box(x1, x1 + 0.005, y0 + 0.06, y0 + 0.24, z0 + 0.06, (z0 + z1) * 0.5, c8(0xc8b890), {"surface": "fabric", "parent": parent, "name": "Grille", "cast_shadow": false})
	b.box(x1, x1 + 0.02, y0 + 0.12, y0 + 0.18, z1 - 0.2, z1 - 0.12, c8(0xe8d8a0), {"surface": "metal", "parent": parent, "name": "Dial", "cast_shadow": false})
	b.cylinder(Vector3(x0 + 0.1, y0 + 0.3, z1 - 0.1), Vector3(x0 + 0.3, y0 + 0.75, z1 - 0.2), 0.006, b.surface("metal"), {"parent": parent, "name": "Aerial", "tint": c8(0xcccccc)})
	return body


static func altar(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, parent: String, facing_x := 1.0) -> void:
	b.box(x0, x1, y0, y1, z0, z1, c8(0xa8453a), {"surface": "wood", "parent": parent, "name": "Altar"})
	b.box(x0, x1, y1, y1 + 0.03, z0 - 0.02, z1 + 0.02, c8(0x7a2e22), {"surface": "wood", "parent": parent, "name": "AltarLip"})
	var cx := x1 - 0.08 if facing_x > 0 else x0 + 0.08
	b.piece(_sphere(0.045), Vector3(cx, y1 + 0.2, (z0 + z1) * 0.5), b.emissive(c8(0xff4a2a), 4.0), {"parent": parent, "name": "RedLamp", "cast_shadow": false})
	b.box(cx - 0.05, cx + 0.05, y1 + 0.03, y1 + 0.13, (z0 + z1) * 0.5 - 0.06, (z0 + z1) * 0.5 + 0.06, c8(0xc9a55a), {"surface": "metal", "parent": parent, "name": "Censer"})
	for i in 3:
		var z := (z0 + z1) * 0.5 - 0.02 + i * 0.02
		b.box(cx - 0.004, cx + 0.004, y1 + 0.13, y1 + 0.36, z, z + 0.008, c8(0xb04030), {"surface": "grain", "parent": parent, "name": "Incense", "cast_shadow": false})
		b.piece(_sphere(0.008), Vector3(cx, y1 + 0.365, z + 0.004), b.emissive(c8(0xff7a30), 6.0), {"parent": parent, "name": "Ember", "cast_shadow": false})


static func tube_light(b: LevelBuilder, a: Vector3, bb: Vector3, parent: String, tint := Color(0.9, 0.97, 1.0)) -> void:
	## A bare fluorescent batten: a white housing with a glowing tube under it.
	var mid := (a + bb) * 0.5
	var along := (bb - a)
	var len := along.length()
	var x_axis := absf(along.x) > absf(along.z)
	var hw := len * 0.5
	if x_axis:
		b.box(mid.x - hw, mid.x + hw, mid.y, mid.y + 0.05, mid.z - 0.05, mid.z + 0.05, c8(0xe8e8e0), {"surface": "metal", "parent": parent, "name": "Batten", "cast_shadow": false})
	else:
		b.box(mid.x - 0.05, mid.x + 0.05, mid.y, mid.y + 0.05, mid.z - hw, mid.z + hw, c8(0xe8e8e0), {"surface": "metal", "parent": parent, "name": "Batten", "cast_shadow": false})
	b.cylinder(a + Vector3(0, -0.025, 0), bb + Vector3(0, -0.025, 0), 0.02, b.emissive(tint, 5.0), {"parent": parent, "name": "Tube", "cast_shadow": false})


static func bulb(b: LevelBuilder, pos: Vector3, ceiling: float, parent: String, col := Color(1.0, 0.8, 0.5)) -> void:
	## A bare bulb hanging on its flex.
	b.cylinder(Vector3(pos.x, ceiling, pos.z), pos + Vector3(0, 0.08, 0), 0.006, b.surface("grain"), {"parent": parent, "name": "Flex", "tint": c8(0x222222), "cast_shadow": false})
	b.piece(_sphere(0.05), pos, b.emissive(col, 6.0), {"parent": parent, "name": "Bulb", "cast_shadow": false})
	b.box(pos.x - 0.03, pos.x + 0.03, pos.y + 0.04, pos.y + 0.1, pos.z - 0.03, pos.z + 0.03, c8(0x3a3a3a), {"surface": "metal", "parent": parent, "name": "Socket", "cast_shadow": false})


static func ac_unit(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, parent: String, band := -1.0, fadeable := false) -> void:
	var o := {"surface": "metal", "parent": parent, "name": "AirCon", "fadeable": fadeable}
	if band >= 0:
		o["band"] = band
	b.box(x0, x1, y0, y1, z0, z1, c8(0xc8c6be), o)


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2
	s.radial_segments = 12
	s.rings = 6
	return s


# ----------------------------------------------------------------------------- one room, lived in
#
# A Walled City home was usually one room of twenty-odd square metres for a
# whole family: they slept in bunks and on a cockloft, cooked at a counter in
# a corner, and kept everything else in boxes. Toilets were mostly shared, a
# cubicle off the corridor; some flats squeezed a squat pan behind a curtain.


## A small pipe through the given points, with a round elbow at every bend.
static func pipe_run(b: LevelBuilder, pts: Array, r: float, col: Color, parent: String, band: float, pipe_name := "Pipe", fadeable := false) -> void:
	for i in pts.size() - 1:
		if (pts[i] as Vector3).distance_to(pts[i + 1]) < 0.005:
			continue
		b.cylinder(pts[i], pts[i + 1], r, b.surface("metal"), {"parent": parent, "name": pipe_name, "tint": col, "band": band, "fadeable": fadeable})
	for i in range(1, pts.size() - 1):
		b.piece(_sphere(r * 1.25), pts[i], b.surface("metal"), {"parent": parent, "name": pipe_name + "Elbow", "tint": col, "band": band, "cast_shadow": false, "fadeable": fadeable})


static func _o(parent: String, band: float, part_name: String, surface := "metal", extra := {}) -> Dictionary:
	var d := {"surface": surface, "parent": parent, "name": part_name}
	if band >= 0.0:
		d["band"] = band
	d.merge(extra, true)
	return d


## A cement counter against a wall with a two-ring gas stove and a wok, a
## rice cooker, a kettle and a stack of bowls; a gas bottle on the floor at
## its far end. `wall` is the side it stands against: "n" (its length along x,
## the wall at z0) or "e" (its length along z, the wall at x1).
static func kitchen_counter(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, parent: String, wall := "n", band := -1.0) -> void:
	var top := y + 0.8
	b.box(x0, x1, y + 0.08, top - 0.04, z0, z1, c8(0x8e8a80), _o(parent, band, "Counter", "concrete"))
	if wall == "n":
		b.box(x0 + 0.03, x1 - 0.03, y, y + 0.08, z0, z1 - 0.05, c8(0x4a4640), _o(parent, band, "Plinth", "concrete"))
		for k in 2:
			var cx0 := x0 + 0.06 + (x1 - x0 - 0.12) * k / 2.0
			var cx1 := cx0 + (x1 - x0 - 0.12) / 2.0 - 0.04
			b.box(cx0, cx1, y + 0.14, top - 0.12, z1, z1 + 0.015, c8(0x6f8a7a), _o(parent, band, "CupboardDoor", "wood", {"cast_shadow": false}))
			b.box(cx1 - 0.08, cx1 - 0.05, y + 0.5, y + 0.56, z1 + 0.015, z1 + 0.03, c8(0x3a3028), _o(parent, band, "CupboardKnob", "metal", {"cast_shadow": false}))
	else:
		b.box(x0 + 0.05, x1, y, y + 0.08, z0 + 0.03, z1 - 0.03, c8(0x4a4640), _o(parent, band, "Plinth", "concrete"))
		for k in 2:
			var cz0 := z0 + 0.06 + (z1 - z0 - 0.12) * k / 2.0
			var cz1 := cz0 + (z1 - z0 - 0.12) / 2.0 - 0.04
			b.box(x0 - 0.015, x0, y + 0.14, top - 0.12, cz0, cz1, c8(0x6f8a7a), _o(parent, band, "CupboardDoor", "wood", {"cast_shadow": false}))
			b.box(x0 - 0.03, x0 - 0.015, y + 0.5, y + 0.56, cz1 - 0.08, cz1 - 0.05, c8(0x3a3028), _o(parent, band, "CupboardKnob", "metal", {"cast_shadow": false}))
	b.box(x0 - 0.02, x1 + 0.02, top - 0.04, top, z0 - 0.02, z1 + 0.02, c8(0xd8d4c8), _o(parent, band, "CounterTop", "tiles"))
	b.add_obstacle(x0, x1, z0, z1, y, "counter")
	var along_x := wall == "n"
	var depth := (z1 - z0) if along_x else (x1 - x0)
	var lo := x0 if along_x else z0
	var hi := x1 if along_x else z1
	var bd := band if band >= 0.0 else b.band_of(top)
	# the stove: a low black box with two rings, a wok on one
	var sc := _along(along_x, lo + (hi - lo) * 0.55, top, x1, z0, depth * 0.5)
	var half := Vector3(0.28, 0, 0.17) if along_x else Vector3(0.17, 0, 0.28)
	b.box(sc.x - half.x, sc.x + half.x, top, top + 0.09, sc.z - half.z, sc.z + half.z, c8(0x2a2a2a), _o(parent, band, "Stove"))
	for s in [-1.0, 1.0]:
		var rc := sc + (Vector3(0.13 * s, 0, 0) if along_x else Vector3(0, 0, 0.13 * s))
		b.cylinder(rc + Vector3(0, 0.09, 0), rc + Vector3(0, 0.11, 0), 0.07, b.surface("metal"), {"parent": parent, "name": "Burner", "tint": c8(0x4a4a48), "band": bd})
	var wc := sc + (Vector3(-0.13, 0, 0) if along_x else Vector3(0, 0, -0.13))
	var wok := CylinderMesh.new()
	wok.top_radius = 0.19
	wok.bottom_radius = 0.07
	wok.height = 0.09
	wok.radial_segments = 16
	b.piece(wok, wc + Vector3(0, 0.155, 0), b.surface("metal"), {"parent": parent, "name": "Wok", "tint": c8(0x2e2c2a), "band": bd})
	# the rice cooker, white
	var rc2 := _along(along_x, lo + (hi - lo) * 0.15, top, x1, z0, depth * 0.5)
	b.cylinder(rc2, rc2 + Vector3(0, 0.2, 0), 0.12, b.surface("grain"), {"parent": parent, "name": "RiceCooker", "tint": c8(0xeceae2), "band": bd})
	b.cylinder(rc2 + Vector3(0, 0.2, 0), rc2 + Vector3(0, 0.235, 0), 0.105, b.surface("grain"), {"parent": parent, "name": "RiceCookerLid", "tint": c8(0xd8d6ce), "band": bd})
	b.cylinder(rc2 + Vector3(0, 0.235, 0), rc2 + Vector3(0, 0.255, 0), 0.02, b.surface("grain"), {"parent": parent, "name": "RiceCookerKnob", "tint": c8(0x3a3a3a), "band": bd, "cast_shadow": false})
	var face := Vector3(0, 0, 0.121) if along_x else Vector3(-0.121, 0, 0)
	b.cylinder(rc2 + face + Vector3(0, 0.07, 0), rc2 + face * 1.06 + Vector3(0, 0.07, 0), 0.012, b.surface("grain"), {"parent": parent, "name": "RiceCookerLight", "tint": c8(0xe03a2a), "band": bd, "cast_shadow": false})
	# the kettle, and bowls stacked to drain
	var kc := _along(along_x, lo + (hi - lo) * 0.9, top, x1, z0, depth * 0.45)
	b.cylinder(kc, kc + Vector3(0, 0.15, 0), 0.075, b.surface("metal"), {"parent": parent, "name": "Kettle", "tint": c8(0xb8bcc0), "band": bd})
	b.cylinder(kc + Vector3(0, 0.15, 0), kc + Vector3(0, 0.17, 0), 0.04, b.surface("metal"), {"parent": parent, "name": "KettleLid", "tint": c8(0x9aa0a4), "band": bd})
	var spout := Vector3(0.1, 0, 0) if along_x else Vector3(0, 0, 0.1)
	b.cylinder(kc + Vector3(0, 0.06, 0) + spout * 0.6, kc + Vector3(0, 0.14, 0) + spout * 1.25, 0.013, b.surface("metal"), {"parent": parent, "name": "KettleSpout", "tint": c8(0xb8bcc0), "band": bd})
	var hk := Vector3(0, 0.17, 0)
	for seg in [[hk - spout * 0.45, hk - spout * 0.45 + Vector3(0, 0.07, 0)], [hk - spout * 0.45 + Vector3(0, 0.07, 0), hk + spout * 0.45 + Vector3(0, 0.07, 0)],
			[hk + spout * 0.45 + Vector3(0, 0.07, 0), hk + spout * 0.45]]:
		b.cylinder(kc + (seg[0] as Vector3), kc + (seg[1] as Vector3), 0.008, b.surface("grain"), {"parent": parent, "name": "KettleHandle", "tint": c8(0x2a2420), "band": bd, "cast_shadow": false})
	var bc := _along(along_x, lo + (hi - lo) * 0.32, top, x1, z0, depth * 0.35)
	for k in 3:
		b.cylinder(bc + Vector3(0, 0.035 * k, 0), bc + Vector3(0, 0.035 * k + 0.035, 0), 0.07 - k * 0.004, b.surface("grain"),
			{"parent": parent, "name": "Bowl", "tint": [c8(0xe8e4d8), c8(0x5a7aa8), c8(0xe8e4d8)][k], "band": bd})
	# the gas bottle, on the floor just past the far end
	var gb := _along(along_x, hi + 0.2, y, x1, z0, depth * 0.5)
	b.cylinder(gb, gb + Vector3(0, 0.5, 0), 0.15, b.surface("metal"), {"parent": parent, "name": "GasBottle", "tint": c8(0xb8392e), "band": bd})
	var shoulder := SphereMesh.new()
	shoulder.radius = 0.15
	shoulder.height = 0.14
	shoulder.radial_segments = 16
	shoulder.rings = 4
	b.piece(shoulder, gb + Vector3(0, 0.5, 0), b.surface("metal"), {"parent": parent, "name": "GasBottleTop", "tint": c8(0xb8392e), "band": bd})
	var valve := gb + Vector3(0, 0.62, 0)
	b.cylinder(gb + Vector3(0, 0.55, 0), valve, 0.03, b.surface("metal"), {"parent": parent, "name": "GasValve", "tint": c8(0xc9a55a), "band": bd})
	# the hose: from the valve, drooping, into the counter's end face under the stove
	var end_face := Vector3(hi, y + 0.55, z0 + depth * 0.3) if along_x else Vector3(x1 - depth * 0.3, y + 0.55, hi)
	var sag := (valve + end_face) * 0.5 + Vector3(0, -0.12, 0)
	for seg in [[valve, sag], [sag, end_face]]:
		b.cylinder(seg[0], seg[1], 0.012, b.surface("grain"), {"parent": parent, "name": "GasHose", "tint": c8(0xd8a030), "band": bd, "cast_shadow": false})
	b.add_obstacle(gb.x - 0.16, gb.x + 0.16, gb.z - 0.16, gb.z + 0.16, y, "gasBottle")


## A point `a` along a counter's length, `d` out from its wall, at height y.
static func _along(along_x: bool, a: float, y: float, x1: float, z0: float, d: float) -> Vector3:
	return Vector3(a, y, z0 + d) if along_x else Vector3(x1 - d, y, a)


## An upper bunk over a bed (x0..x1, z0..z1): corner posts, a deck with its
## own mattress and blanket, a guard rail, and a ladder at the foot on the x1 side.
static func bunk_top(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, frame: Color, sheet: Color, blanket: Color, parent: String) -> void:
	var post := 0.07
	for x in [x0 + 0.02, x1 - post - 0.02]:
		for z in [z0 + 0.02, z1 - post - 0.02]:
			b.box(x, x + post, y, y + 1.95, z, z + post, frame, {"surface": "wood", "parent": parent, "name": "BunkPost"})
	var deck := y + 1.35
	b.box(x0, x1, deck, deck + 0.08, z0, z1, frame, {"surface": "wood", "parent": parent, "name": "BunkDeck"})
	b.box(x0 + 0.05, x1 - 0.05, deck + 0.08, deck + 0.22, z0 + 0.05, z1 - 0.05, sheet, {"surface": "fabric", "parent": parent, "name": "BunkMattress"})
	b.box(x0 + 0.05, x1 - 0.05, deck + 0.22, deck + 0.28, z0 + 0.6, z1 - 0.06, blanket, {"surface": "fabric", "parent": parent, "name": "BunkBlanket"})
	b.box(x0 + 0.3, x1 - 0.3, deck + 0.22, deck + 0.32, z0 + 0.12, z0 + 0.5, c8(0xf0ebdf), {"surface": "fabric", "parent": parent, "name": "BunkPillow"})
	# the guard rail on the open side: from the head post to the ladder's near
	# stile, joined into both, with a stub down to the deck at each end
	var lz := z1 - 0.5
	b.box(x1 - 0.02, x1 + 0.05, deck + 0.35, deck + 0.42, z0 + 0.02, lz + 0.05, frame, {"surface": "wood", "parent": parent, "name": "BunkRail"})
	b.box(x1 - 0.02, x1 + 0.05, deck + 0.08, deck + 0.35, z0 + 0.02, z0 + 0.09, frame, {"surface": "wood", "parent": parent, "name": "BunkRailPost"})
	# the deck's edge board along the open side, carrying the rail's foot
	b.box(x1 - 0.02, x1 + 0.05, deck - 0.02, deck + 0.1, z0, z1, frame.darkened(0.1), {"surface": "wood", "parent": parent, "name": "BunkSideBoard"})
	for dz in [0.0, 0.38]:
		b.box(x1, x1 + 0.05, y, deck + 0.42, lz + dz, lz + dz + 0.05, frame, {"surface": "wood", "parent": parent, "name": "LadderRail"})
	for k in 4:
		var ry := y + 0.35 + k * 0.33
		b.box(x1 + 0.005, x1 + 0.045, ry, ry + 0.04, lz + 0.05, lz + 0.38, frame.darkened(0.15), {"surface": "wood", "parent": parent, "name": "LadderRung", "cast_shadow": false})


## A cockloft: a timber platform high in a corner (x0..x1, against the wall
## at z0), carried on two posts at its front edge (z1), with bedding rolls and
## cases up on it and a ladder leaning up to it at the x1 end.
static func cockloft(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, parent: String) -> void:
	var wood := c8(0x6b4a30)
	b.box(x0, x1, y + h, y + h + 0.08, z0, z1, wood, {"surface": "wood", "parent": parent, "name": "LoftDeck"})
	b.box(x0, x1, y + h - 0.12, y + h, z1 - 0.1, z1, wood.darkened(0.15), {"surface": "wood", "parent": parent, "name": "LoftBeam"})
	for x in [x0 + 0.05, x1 - 0.13]:
		b.box(x, x + 0.08, y, y + h, z1 - 0.1, z1 - 0.02, wood.darkened(0.1), {"surface": "wood", "parent": parent, "name": "LoftPost"})
		b.add_obstacle(x, x + 0.08, z1 - 0.1, z1 - 0.02, y, "loftPost")
	var top := y + h + 0.08
	b.cylinder(Vector3(x0 + 0.3, top + 0.13, z0 + 0.35), Vector3(x0 + 1.3, top + 0.13, z0 + 0.35), 0.13, b.surface("fabric"), {"parent": parent, "name": "BeddingRoll", "tint": c8(0x8a5a6a)})
	b.cylinder(Vector3(x0 + 0.3, top + 0.12, z0 + 0.72), Vector3(x0 + 1.2, top + 0.12, z0 + 0.72), 0.12, b.surface("fabric"), {"parent": parent, "name": "BeddingRoll", "tint": c8(0x5a7ab0)})
	b.box(x1 - 1.1, x1 - 0.35, top, top + 0.22, z0 + 0.1, z0 + 0.6, c8(0x7a4a36), {"surface": "wood", "parent": parent, "name": "Suitcase"})
	b.box(x1 - 1.0, x1 - 0.45, top + 0.22, top + 0.4, z0 + 0.15, z0 + 0.55, c8(0x3f5a6f), {"surface": "fabric", "parent": parent, "name": "Case"})
	for dx in [0.0, 0.34]:
		b.cylinder(Vector3(x1 - 0.5 + dx, y, z1 + 0.35), Vector3(x1 - 0.5 + dx, top + 0.3, z1 - 0.05), 0.022, b.surface("wood"), {"parent": parent, "name": "LoftLadder", "tint": wood})
	for k in 5:
		var t := (k + 1) / 6.0
		var ly := y + (top + 0.3 - y) * t
		var lz := z1 + 0.35 - 0.4 * t
		b.cylinder(Vector3(x1 - 0.5, ly, lz), Vector3(x1 - 0.16, ly, lz), 0.016, b.surface("wood"), {"parent": parent, "name": "LoftRung", "tint": wood.darkened(0.1), "cast_shadow": false})
	b.add_obstacle(x1 - 0.55, x1 - 0.1, z1 - 0.05, z1 + 0.4, y, "loftLadder")


## A squat toilet against the wall at z = `wall_z` (the pan runs out from it
## toward +z): the white pan and its foot treads, a high cistern with a flush
## pipe and pull chain fed from `feed` (a point on a water pipe), and a bucket
## and scoop for when the cistern runs dry.
static func squat_toilet(b: LevelBuilder, x: float, wall_z: float, y: float, parent: String, feed: Vector3, band := -1.0) -> void:
	var bd := band if band >= 0.0 else b.band_of(y + 0.5)
	var z0 := wall_z + 0.18
	b.box(x - 0.22, x + 0.22, y, y + 0.04, z0, z0 + 0.62, c8(0xf2f0ea), _o(parent, band, "Pan", "grain"))
	b.box(x - 0.12, x + 0.12, y + 0.035, y + 0.042, z0 + 0.08, z0 + 0.46, c8(0x9ab0b8), _o(parent, band, "PanBowl", "grain", {"cast_shadow": false}))
	for s in [-1.0, 1.0]:
		b.box(x + 0.16 * s - 0.05, x + 0.16 * s + 0.05, y + 0.04, y + 0.055, z0 + 0.3, z0 + 0.52, c8(0xd8d6ce), _o(parent, band, "FootTread", "grain", {"cast_shadow": false}))
	var cy := y + 1.95
	b.box(x - 0.2, x + 0.2, cy, cy + 0.26, wall_z + 0.02, wall_z + 0.18, c8(0xe8e6de), _o(parent, band, "Cistern", "grain"))
	# the flush pipe down the wall, bending out into the back of the pan
	pipe_run(b, [Vector3(x, cy, wall_z + 0.1), Vector3(x, y + 0.1, wall_z + 0.1), Vector3(x, y + 0.1, z0 + 0.02)], 0.022, c8(0xb8bcc0), parent, bd, "FlushPipe")
	# the pan's hood at the wall end
	b.box(x - 0.11, x + 0.11, y + 0.04, y + 0.12, z0, z0 + 0.1, c8(0xf2f0ea), _o(parent, band, "PanHood", "grain"))
	# the cistern's lid and a bracket under it
	b.box(x - 0.21, x + 0.21, cy + 0.26, cy + 0.28, wall_z + 0.01, wall_z + 0.19, c8(0xd8d6ce), _o(parent, band, "CisternLid", "grain"))
	for s in [-1.0, 1.0]:
		b.box(x + 0.15 * s - 0.015, x + 0.15 * s + 0.015, cy - 0.12, cy, wall_z, wall_z + 0.14, c8(0x5a5a58), _o(parent, band, "CisternBracket", "metal", {"cast_shadow": false}))
	b.cylinder(Vector3(x + 0.16, cy, wall_z + 0.17), Vector3(x + 0.16, cy - 0.7, wall_z + 0.17), 0.006, b.surface("metal"), {"parent": parent, "name": "PullChain", "tint": c8(0x8a8a86), "cast_shadow": false, "band": bd})
	b.cylinder(Vector3(x + 0.16, cy - 0.7, wall_z + 0.17), Vector3(x + 0.16, cy - 0.78, wall_z + 0.17), 0.02, b.surface("wood"), {"parent": parent, "name": "PullHandle", "tint": c8(0x3a2a1a), "band": bd})
	# water in: from the pipe, back to the wall, along it, and down into the cistern
	var inlet := Vector3(x - 0.14, cy + 0.26, wall_z + 0.1)
	pipe_run(b, [feed, Vector3(feed.x, feed.y, inlet.z), Vector3(inlet.x, feed.y, inlet.z), inlet], 0.018, c8(0x9aa0a4), parent, bd, "FeedPipe")
	var bx := x + 0.42
	b.cylinder(Vector3(bx, y, z0 + 0.2), Vector3(bx, y + 0.3, z0 + 0.2), 0.14, b.surface("grain"), {"parent": parent, "name": "Bucket", "tint": c8(0xc9463a), "band": bd})
	b.cylinder(Vector3(bx, y + 0.26, z0 + 0.2), Vector3(bx, y + 0.27, z0 + 0.2), 0.125, b.surface("grain"), {"parent": parent, "name": "BucketWater", "tint": c8(0x7fa0b8), "cast_shadow": false, "band": bd})
	b.cylinder(Vector3(bx - 0.05, y + 0.27, z0 + 0.2), Vector3(bx + 0.18, y + 0.36, z0 + 0.2), 0.012, b.surface("grain"), {"parent": parent, "name": "ScoopHandle", "tint": c8(0x3f6fa8), "band": bd})
	b.add_obstacle(bx - 0.15, bx + 0.15, z0 + 0.05, z0 + 0.35, y, "bucket")


## A hanging curtain, gathered: narrow strips stepping in and out of the line
## it hangs on, shaded a touch darker in the folds. It runs from a0 to a1
## along x (axis "x", in the plane z = fixed) or along z (axis "z", x = fixed).
static func curtain(b: LevelBuilder, a0: float, a1: float, y0: float, y1: float, fixed: float, axis: String, col: Color, parent: String) -> void:
	var n := maxi(2, roundi(absf(a1 - a0) / 0.09))
	var w := (a1 - a0) / n
	for i in n:
		var a := a0 + w * i
		var off := 0.018 if i % 2 == 0 else -0.018
		var c := col if i % 2 == 0 else col.darkened(0.14)
		var lo := minf(a, a + w)
		var hi := maxf(a, a + w)
		if axis == "x":
			b.box(lo, hi, y0, y1, fixed + off - 0.008, fixed + off + 0.008, c, {"surface": "fabric", "parent": parent, "name": "CurtainFold"})
		else:
			b.box(fixed + off - 0.008, fixed + off + 0.008, y0, y1, lo, hi, c, {"surface": "fabric", "parent": parent, "name": "CurtainFold"})
