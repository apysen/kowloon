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


static func fan(b: LevelBuilder, x: float, z: float, y: float, parent: String) -> Node3D:
	var metal := b.surface("metal")
	b.box(x - 0.2, x + 0.2, y, y + 0.05, z - 0.2, z + 0.2, c8(0x3d4a52), {"surface": "metal", "parent": parent, "name": "FanBase"})
	b.box(x - 0.025, x + 0.025, y + 0.05, y + 1.2, z - 0.025, z + 0.025, c8(0x444444), {"surface": "metal", "parent": parent, "name": "FanPole"})
	b.box(x - 0.1, x + 0.1, y + 1.14, y + 1.32, z - 0.14, z + 0.06, c8(0x5a7a80), {"surface": "metal", "parent": parent, "name": "FanMotor"})
	var cage := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.3
	tm.outer_radius = 0.33
	cage.mesh = tm
	cage.name = "FanGuard"
	cage.material_override = metal
	cage.set_instance_shader_parameter("tint", c8(0x7da0a8))
	cage.rotation = Vector3(PI / 2, 0, 0)
	cage.position = Vector3(x, y + 1.25, z + 0.1)
	b.attach(cage, b.group(parent))
	b.tag(cage, b.band_of(y + 0.5))
	var rotor := Node3D.new()
	rotor.name = "FanRotor"
	rotor.position = Vector3(x, y + 1.25, z + 0.1)
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
