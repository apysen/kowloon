class_name PropKit
extends RefCounted

## Furniture and fittings, modelled: rounded timber, soft bedding, turned
## crockery and bent pipe (ModelKit), so they hold up when the camera comes
## in close. Collision is never added here, except where noted: the room
## builders add the same footprints the slice used, so play is unchanged.

static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


## A rounded box between two corners (ModelKit.box), with the parent and name.
static func _bx(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, col: Color, o: Dictionary) -> MeshInstance3D:
	return ModelKit.box(b, x0, x1, y0, y1, z0, z1, col, o)


## A modelled mesh placed with a surface and a tint.
static func _put(b: LevelBuilder, mesh: Mesh, pos: Vector3, surface: String, tint: Color, parent: String, part: String, extra := {}) -> MeshInstance3D:
	var o := {"parent": parent, "name": part}
	o.merge(extra, true)
	return ModelKit.place(b, mesh, pos, surface, tint, o)


static func _o(parent: String, band: float, part_name: String, surface := "metal", extra := {}) -> Dictionary:
	var d := {"surface": surface, "parent": parent, "name": part_name}
	if band >= 0.0:
		d["band"] = band
	d.merge(extra, true)
	return d


## A small, stable variety for dressing that must not draw on the level's
## random stream (drawing more would move everything placed after it).
static func _rng(p: Vector3) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%.2f,%.2f,%.2f" % [p.x, p.y, p.z])
	return r


# ----------------------------------------------------------------------------- tables and seats


## A timber table: a thick top with softened edges overhanging an apron
## frame, four legs tapering a little to the floor, and a stretcher low down
## between each pair of legs at the ends.
static func table(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, col: Color, parent: String, top_surface := "timber") -> void:
	var t := 0.05
	_bx(b, x0, x1, y + h - t, y + h, z0, z1, col, {"surface": top_surface, "parent": parent, "name": "TableTop", "radius": 0.014})
	var leg := 0.06
	var under := y + h - t
	var legs: Array[Vector2] = []
	for x in [x0 + 0.04, x1 - 0.04 - leg]:
		for z in [z0 + 0.04, z1 - 0.04 - leg]:
			legs.append(Vector2(x + leg * 0.5, z + leg * 0.5))
	for p in legs:
		_bx(b, p.x - leg * 0.5, p.x + leg * 0.5, y, under, p.y - leg * 0.5, p.y + leg * 0.5, col.darkened(0.2), {"surface": "timber", "parent": parent, "name": "Leg", "radius": 0.008})
	# the apron: all four sides, set in from the top's edge
	var ac := col.darkened(0.25)
	for z in [z0 + 0.06, z1 - 0.1]:
		_bx(b, x0 + 0.07, x1 - 0.07, under - 0.08, under, z, z + 0.03, ac, {"surface": "timber", "parent": parent, "name": "Apron", "radius": 0.006})
	for x in [x0 + 0.06, x1 - 0.09]:
		_bx(b, x, x + 0.03, under - 0.08, under, z0 + 0.1, z1 - 0.1, ac, {"surface": "timber", "parent": parent, "name": "Apron", "radius": 0.006})
	# the stretchers, a hand's height off the floor
	for x in [x0 + 0.07, x1 - 0.07 - 0.04]:
		_bx(b, x, x + 0.03, y + 0.12, y + 0.15, z0 + 0.07, z1 - 0.07, ac, {"surface": "timber", "parent": parent, "name": "Stretcher", "radius": 0.006, "cast_shadow": false})


## A square timber stool: a seat with a rounded edge, four legs splayed a
## little, and a ring of rungs.
static func stool(b: LevelBuilder, x: float, z: float, y: float, col: Color, parent: String, h := 0.45) -> void:
	_bx(b, x - 0.17, x + 0.17, y + h - 0.04, y + h, z - 0.17, z + 0.17, col, {"surface": "grain", "parent": parent, "name": "StoolSeat", "radius": 0.016})
	var lc := col.darkened(0.2)
	var top := y + h - 0.04
	for dx in [-1.0, 1.0]:
		for dz in [-1.0, 1.0]:
			var foot := Vector3(x + dx * 0.135, y, z + dz * 0.135)
			var head := Vector3(x + dx * 0.115, top, z + dz * 0.115)
			_put(b, ModelKit.tube([foot - Vector3(x, y, z), head - Vector3(x, y, z)], 0.016, 0.0, 8), Vector3(x, y, z), "grain", lc, parent, "StoolLeg")
	var ry := y + 0.16
	var ring := []
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
		ring.append(Vector3(c.x * 0.128, 0, c.y * 0.128))
	_put(b, ModelKit.tube(ring, 0.009, 0.0, 6), Vector3(x, ry, z), "grain", lc, parent, "StoolRung", {"cast_shadow": false})


# ----------------------------------------------------------------------------- beds


## A bed: a timber frame on legs with a carton pushed under it, a soft
## mattress, a pillow, a blanket over the foot with its top turned back,
## and a headboard of posts and a panel.
static func bed(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, frame: Color, sheet: Color, parent: String, pillow_at_x0 := true) -> void:
	# the rails, and a leg at each corner
	_bx(b, x0, x1, y + 0.2, y + 0.35, z0, z0 + 0.05, frame, {"surface": "timber", "parent": parent, "name": "BedFrame", "radius": 0.01})
	_bx(b, x0, x1, y + 0.2, y + 0.35, z1 - 0.05, z1, frame, {"surface": "timber", "parent": parent, "name": "BedFrame", "radius": 0.01})
	_bx(b, x0, x0 + 0.05, y + 0.2, y + 0.35, z0 + 0.05, z1 - 0.05, frame, {"surface": "timber", "parent": parent, "name": "BedFrame", "radius": 0.01})
	_bx(b, x1 - 0.05, x1, y + 0.2, y + 0.35, z0 + 0.05, z1 - 0.05, frame, {"surface": "timber", "parent": parent, "name": "BedFrame", "radius": 0.01})
	_bx(b, x0 + 0.05, x1 - 0.05, y + 0.3, y + 0.33, z0 + 0.05, z1 - 0.05, frame.darkened(0.3), {"surface": "timber", "parent": parent, "name": "BedBoards", "radius": 0.004, "cast_shadow": false})
	for x in [x0, x1 - 0.06]:
		for z in [z0, z1 - 0.06]:
			_bx(b, x, x + 0.06, y, y + 0.2, z, z + 0.06, frame.darkened(0.15), {"surface": "timber", "parent": parent, "name": "BedLeg", "radius": 0.008})
	# what lives under a bed: a carton, and an enamel basin
	var r := _rng(Vector3(x0, y, z0))
	var ux := (x0 + x1) * 0.5 + r.randf_range(-0.2, 0.2)
	cardboard(b, ux - 0.25, ux + 0.2, y, y + 0.18, z0 + 0.1, z0 + 0.1 + minf(0.4, (z1 - z0) * 0.45), c8(0xa8834f), parent, "")
	var bx := x1 - 0.4 if pillow_at_x0 else x0 + 0.4
	_put(b, _basin(0.13, 0.065), Vector3(bx, y, z1 - 0.18), "glaze", c8(0xe8e4d6), parent, "Basin")
	# the mattress, soft, with the sheet over it
	var mat := Vector3(x1 - x0 - 0.08, 0.2, z1 - z0 - 0.08)
	_put(b, ModelKit.cushion(mat, 0.05, 0.012, 0.008), Vector3((x0 + x1) * 0.5, y + 0.45, (z0 + z1) * 0.5), "fabric", sheet, parent, "Mattress")
	var px0 := x0 + 0.1 if pillow_at_x0 else x1 - 0.5
	_put(b, ModelKit.cushion(Vector3(0.4, 0.09, z1 - z0 - 0.3), 0.04, 0.035, 0.01), Vector3(px0 + 0.2, y + 0.6, (z0 + z1) * 0.5), "fabric", c8(0xf0ebdf), parent, "Pillow")
	# the blanket over the foot, hanging a little down both sides, its top turned back
	var bx0 := x0 + 0.6 if pillow_at_x0 else x0 + 0.04
	var bx1 := x1 - 0.04 if pillow_at_x0 else x1 - 0.6
	var bcol := c8(0x6f7d62).lerp(sheet, 0.2)
	# (it stays inside the frame's footprint: beds stand against walls)
	_put(b, ModelKit.cushion(Vector3(bx1 - bx0, 0.05, z1 - z0 - 0.02), 0.025, 0.008, 0.0), Vector3((bx0 + bx1) * 0.5, y + 0.565, (z0 + z1) * 0.5), "fabric", bcol, parent, "Blanket")
	for s in [-1.0, 1.0]:
		var zz: float = (z1 - 0.025) if s > 0 else (z0 + 0.025)
		_bx(b, bx0, bx1, y + 0.4, y + 0.56, zz - 0.012, zz + 0.012, bcol.darkened(0.08), {"surface": "fabric", "parent": parent, "name": "BlanketSide", "radius": 0.01, "cast_shadow": false})
	var turn := bx0 if pillow_at_x0 else bx1 - 0.16
	_put(b, ModelKit.cushion(Vector3(0.16, 0.035, z1 - z0 + 0.02), 0.016, 0.01, 0.0), Vector3(turn + 0.08, y + 0.6, (z0 + z1) * 0.5), "fabric", bcol.lightened(0.06), parent, "BlanketFold", {"cast_shadow": false})
	# the headboard: two posts with turned tops, a panel, a top rail
	var hx := x0 if pillow_at_x0 else x1 - 0.06
	for z in [z0, z1 - 0.06]:
		_bx(b, hx, hx + 0.06, y, y + 0.95, z, z + 0.06, frame.darkened(0.1), {"surface": "timber", "parent": parent, "name": "Headboard", "radius": 0.01})
		_put(b, _finial(0.032), Vector3(hx + 0.03, y + 0.95, z + 0.03), "timber", frame.darkened(0.1), parent, "Finial")
	_bx(b, hx + 0.012, hx + 0.048, y + 0.35, y + 0.82, z0 + 0.06, z1 - 0.06, frame.darkened(0.2), {"surface": "timber", "parent": parent, "name": "HeadPanel", "radius": 0.006})
	_bx(b, hx - 0.005, hx + 0.065, y + 0.82, y + 0.88, z0 + 0.04, z1 - 0.04, frame.darkened(0.05), {"surface": "timber", "parent": parent, "name": "HeadRail", "radius": 0.012})


static func _finial(r: float) -> ArrayMesh:
	return ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(r * 0.7, 0), Vector2(r * 0.55, r * 0.4), Vector2(r * 0.9, r * 0.9),
		Vector2(r * 0.7, r * 1.5), Vector2(r * 0.3, r * 1.8), Vector2(0, r * 1.9)]), 12)


## An enamel basin: a shallow bowl with a rolled rim, on y = 0.
static func _basin(r: float, h: float) -> ArrayMesh:
	return ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(r * 0.6, 0), Vector2(r * 0.95, h * 0.85), Vector2(r, h), Vector2(r * 1.06, h),
		Vector2(r * 1.06, h * 0.9), Vector2(r * 0.97, h * 0.92), Vector2(r * 0.6, h * 0.08), Vector2(0, h * 0.08)]), 20)


# ----------------------------------------------------------------------------- shelves


## Open shelves against a wall at z0 (depth along z), loaded with jars,
## tins, bottles, boxes and bundled papers.
static func shelf(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, col: Color, parent: String, shelves := 3) -> void:
	_shelf(b, x0, x1, z0, z1, y, h, col, parent, shelves, false)


## A shelf whose back is against a west wall (depth along x).
static func shelf_z(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, col: Color, parent: String, shelves := 3) -> void:
	_shelf(b, x0, x1, z0, z1, y, h, col, parent, shelves, true)


static func _shelf(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, col: Color, parent: String, shelves: int, along_z: bool) -> void:
	var o := func(part: String, r := 0.006) -> Dictionary:
		return {"surface": "timber", "parent": parent, "name": part, "radius": r}
	if along_z:
		_bx(b, x0, x0 + 0.03, y, y + h, z0, z1, col.darkened(0.15), o.call("ShelfBack", 0.004))
		for side in [z0, z1 - 0.04]:
			_bx(b, x0, x1, y, y + h, side, side + 0.04, col, o.call("ShelfSide"))
	else:
		_bx(b, x0, x1, y, y + h, z0, z0 + 0.03, col.darkened(0.15), o.call("ShelfBack", 0.004))
		for side in [x0, x1 - 0.04]:
			_bx(b, side, side + 0.04, y, y + h, z0, z1, col, o.call("ShelfSide"))
	var palette := [c8(0xa8453a), c8(0xe0c060), c8(0x4f7fb0), c8(0xe8e2d0), c8(0x6f7d62), c8(0x8a5a3a)]
	for i in shelves + 1:
		var yy := y + 0.05 + (h - 0.1) * i / shelves
		_bx(b, x0 + (0.0 if along_z else 0.035), x1 - (0.0 if along_z else 0.035), yy, yy + 0.03, z0 + (0.035 if along_z else 0.0), z1 - (0.035 if along_z else 0.0), col, o.call("ShelfBoard", 0.008))
		if i == shelves:
			continue
		var lo := (z0 if along_z else x0) + 0.08
		var hi := (z1 if along_z else x1) - 0.14
		var a := lo
		while a < hi:
			# the same draws from the level's stream as ever, so nothing after moves
			var w := 0.06 + b.rand.randf() * 0.1
			var hh := 0.08 + b.rand.randf() * 0.18
			var c: Color = palette[b.rand.randi() % 6]
			var depth := minf((x1 - x0 if along_z else z1 - z0) - 0.08, w)
			var foot := Vector3(x0 + 0.05 + depth * 0.5, yy + 0.03, a + w * 0.5) if along_z else Vector3(a + w * 0.5, yy + 0.03, z0 + 0.05 + depth * 0.5)
			_shelf_item(b, foot, w, depth, hh, c, parent, along_z)
			a += w + 0.02 + b.rand.randf() * 0.06


## One thing on a shelf, standing on `foot`, about w wide, d deep, h tall.
static func _shelf_item(b: LevelBuilder, foot: Vector3, w: float, d: float, h: float, c: Color, parent: String, along_z: bool) -> void:
	var r := _rng(foot)
	var rad := minf(w, d) * 0.5
	var o := {"cast_shadow": false}
	match r.randi() % 5:
		0:
			# a glass jar of something dried, its lid screwed on
			_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(rad, 0), Vector2(rad, h * 0.8), Vector2(rad * 0.8, h * 0.88), Vector2(0, h * 0.88)], rad * 0.25), 16),
				foot, "grain", c.lerp(c8(0xc8b890), 0.5), parent, "Jar", o)
			_put(b, ModelKit.puck(rad * 0.84, h * 0.12, 0.003, 16), foot + Vector3(0, h * 0.88, 0), "metal", c8(0xb8392e), parent, "JarLid", o)
		1:
			# a tin with a pressed lid
			_put(b, ModelKit.puck(rad, h * 0.94, 0.004, 18), foot, "metal", c, parent, "Tin", o)
			_put(b, ModelKit.puck(rad * 1.03, h * 0.08, 0.003, 18), foot + Vector3(0, h * 0.92, 0), "metal", c.darkened(0.2), parent, "TinLid", o)
		2:
			# a bottle: soy, oil, medicine wine
			var bh := maxf(h, 0.14)
			_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(rad * 0.8, 0), Vector2(rad * 0.8, bh * 0.6), Vector2(rad * 0.3, bh * 0.8),
				Vector2(rad * 0.25, bh * 0.95), Vector2(0, bh * 0.95)], rad * 0.3), 14), foot, "grain", c.darkened(0.35), parent, "Bottle", o)
			_put(b, ModelKit.puck(rad * 0.3, bh * 0.07, 0.002, 10), foot + Vector3(0, bh * 0.93, 0), "metal", c8(0xd8b040), parent, "BottleCap", o)
		3:
			# a pasteboard box
			var size := Vector3(d, h, w) if along_z else Vector3(w, h, d)
			_put(b, ModelKit.rbox(size, 0.004), foot + Vector3(0, h * 0.5, 0), "grain", c, parent, "Item", o)
		_:
			# papers and books, bundled with string
			var n := 2 + r.randi() % 3
			var hy := 0.0
			for k in n:
				var th := h / n
				var size := Vector3(d * 0.95, th * 0.9, w * r.randf_range(0.85, 1.0)) if along_z else Vector3(w * r.randf_range(0.85, 1.0), th * 0.9, d * 0.95)
				_put(b, ModelKit.rbox(size, 0.003), foot + Vector3(r.randf_range(-0.005, 0.005), hy + th * 0.45, r.randf_range(-0.005, 0.005)), "grain",
					[c, c8(0xe8e2d0), c.lightened(0.2)][k % 3], parent, "Item", o)
				hy += th


# ----------------------------------------------------------------------------- cartons


## A cardboard carton: softened corners, the lid flaps' seam, packing tape
## over the lid and down the face, and on the `label_side` face a marker
## note of what's inside.
static func cardboard(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, col: Color, parent: String, label_side := "s") -> void:
	_bx(b, x0, x1, y0, y1, z0, z1, col, {"surface": "grain", "parent": parent, "name": "Carton", "radius": 0.008})
	var cx := (x0 + x1) * 0.5
	# the seam between the flaps, a dark line across the lid
	_bx(b, x0 + 0.01, x1 - 0.01, y1 - 0.002, y1 + 0.0015, (z0 + z1) * 0.5 - 0.002, (z0 + z1) * 0.5 + 0.002, col.darkened(0.45), {"surface": "grain", "parent": parent, "name": "Seam", "radius": 0.0008, "cast_shadow": false})
	# packing tape over the lid and down the faces
	var tape := c8(0xd8cfa8)
	_bx(b, cx - 0.05, cx + 0.05, y1, y1 + 0.003, z0 - 0.002, z1 + 0.002, tape, {"surface": "grain", "parent": parent, "name": "Tape", "radius": 0.001, "cast_shadow": false})
	_bx(b, cx - 0.05, cx + 0.05, y1 - 0.12, y1 + 0.002, z1, z1 + 0.003, tape, {"surface": "grain", "parent": parent, "name": "Tape", "radius": 0.001, "cast_shadow": false})
	_bx(b, cx - 0.05, cx + 0.05, y1 - 0.12, y1 + 0.002, z0 - 0.003, z0, tape, {"surface": "grain", "parent": parent, "name": "Tape", "radius": 0.001, "cast_shadow": false})
	if label_side == "":
		return
	var r := _rng(Vector3(x0, y0, z0))
	var tex := "res://assets/textures/props/carton_label_%d.png" % (1 + r.randi() % 4)
	var lw := minf(0.3, (x1 - x0) * 0.42)
	var size := Vector2(lw, lw * 0.66)
	var ly := y0 + (y1 - y0) * 0.45
	var lx := x0 + 0.04 + lw * 0.5
	if label_side == "s":
		b.card(tex, Vector3(lx, ly, z1 + 0.002), size, Vector3(0, 0, 1), {"parent": parent, "name": "Marker"})
	elif label_side == "n":
		b.card(tex, Vector3(x1 - 0.04 - lw * 0.5, ly, z0 - 0.002), size, Vector3(0, 0, -1), {"parent": parent, "name": "Marker"})


# ----------------------------------------------------------------------------- the fan


## A standing fan whose head blows toward `face` (flat, in x/z): a weighted
## round base, a chrome pole, a rounded motor, a wire guard and three
## pitched blades on a hub.
static func fan(b: LevelBuilder, x: float, z: float, y: float, parent: String, face := Vector3(0, 0, 1)) -> Node3D:
	var dir := Vector3(face.x, 0, face.z).normalized()
	var yaw := atan2(dir.x, dir.z)
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.19, 0), Vector2(0.19, 0.015), Vector2(0.12, 0.05), Vector2(0.04, 0.06), Vector2(0, 0.06)], 0.012), 28),
		Vector3(x, y, z), "metal", c8(0x3d4a52), parent, "FanBase")
	_put(b, ModelKit.tube([Vector3(0, 0.05, 0), Vector3(0, 1.17, 0)], 0.016, 0.0, 12), Vector3(x, y, z), "metal", c8(0x9aa4a8), parent, "FanPole")
	_put(b, ModelKit.puck(0.03, 0.05, 0.006, 14), Vector3(x, y + 1.1, z), "metal", c8(0x5a7a80), parent, "FanCollar")
	# the head turns on the pole: motor behind, guard and blades in front
	var head := Node3D.new()
	head.name = "FanHead"
	head.position = Vector3(x, y, z)
	head.rotation.y = yaw
	b.attach(head, b.group(parent))
	b.tag(head, b.band_of(y + 0.5))
	# the motor: a rounded can lying along the head's z, a vent ring at its back
	var can := ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, -0.12), Vector2(0.075, -0.12), Vector2(0.095, -0.06), Vector2(0.095, 0.06), Vector2(0.06, 0.09), Vector2(0, 0.09)], 0.025), 20)
	var motor := ModelKit.place(b, can, Vector3(0, 1.25, -0.06), "metal", c8(0x5a7a80), {"parent_node": head, "name": "FanMotor", "rotation": Vector3(PI / 2, 0, 0)})
	motor.remove_meta("band")
	var knob := ModelKit.place(b, ModelKit.puck(0.012, 0.03, 0.004, 10), Vector3(0, 1.335, -0.1), "metal", c8(0xe8e4d8), {"parent_node": head, "name": "FanKnob"})
	knob.remove_meta("band")
	var front := Vector3(x, y + 1.25, z) + dir * 0.1
	var cage := ModelKit.place(b, _guard(0.33), front, "metal", c8(0x7da0a8), {"parent": parent, "name": "FanGuard", "rotation": Vector3(0, yaw, 0), "cast_shadow": false})
	b.tag(cage, b.band_of(y + 0.5))
	var rotor := Node3D.new()
	rotor.name = "FanRotor"
	rotor.position = front
	rotor.rotation.y = yaw        # it spins about its own z, so the blades turn in the guard
	b.attach(rotor, b.group(parent))
	b.tag(rotor, b.band_of(y + 0.5))
	var hub := ModelKit.place(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, -0.03), Vector2(0.045, -0.03), Vector2(0.045, 0.0), Vector2(0.02, 0.025), Vector2(0, 0.03)], 0.01), 16),
		Vector3.ZERO, "metal", c8(0xc8d4d4), {"parent_node": rotor, "name": "FanHub", "rotation": Vector3(PI / 2, 0, 0)})
	hub.remove_meta("band")
	var blade_shape := PackedVector2Array([Vector2(-0.025, 0.03), Vector2(0.025, 0.03), Vector2(0.075, 0.14), Vector2(0.08, 0.22), Vector2(0.05, 0.27),
		Vector2(0.0, 0.285), Vector2(-0.05, 0.27), Vector2(-0.075, 0.2), Vector2(-0.06, 0.12)])
	var blade_mesh := ModelKit.slab(blade_shape, 0.006, 0.0015)
	for i in 3:
		var pivot := Node3D.new()
		pivot.name = "BladeArm"
		pivot.rotation.z = TAU * i / 3.0
		b.attach(pivot, rotor)
		# each blade pitched about its own length, so it scoops the air
		var blade := ModelKit.place(b, blade_mesh, Vector3.ZERO, "metal", c8(0x9ab8bc), {"parent_node": pivot, "name": "Blade", "rotation": Vector3(0, 0.38, 0)})
		blade.remove_meta("band")
	return rotor


## A fan's wire guard in the x/y plane, facing z: rims front and back, a
## ring at the centre, spokes between them bowing forward.
static func _guard(r: float) -> ArrayMesh:
	var key_parts := []
	var paths: Array = []
	for ring in [[r, 0.0], [r * 0.62, 0.03], [r * 0.2, 0.045]]:
		var pts := []
		for k in 33:
			var a := TAU * k / 32
			pts.append(Vector3(cos(a) * ring[0], sin(a) * ring[0], ring[1]))
		paths.append(pts)
	for k in 16:
		var a := TAU * k / 16
		paths.append([Vector3(cos(a) * r, sin(a) * r, 0.0), Vector3(cos(a) * r * 0.62, sin(a) * r * 0.62, 0.03), Vector3(cos(a) * r * 0.2, sin(a) * r * 0.2, 0.045)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in paths:
		st.append_from(ModelKit.tube(p, 0.0035 if p.size() < 5 else 0.005, 0.0, 5, false), 0, Transform3D.IDENTITY)
	return st.commit()


# ----------------------------------------------------------------------------- small appliances, the altar, lights


static func radio(b: LevelBuilder, x0: float, x1: float, y0: float, z0: float, z1: float, parent: String) -> MeshInstance3D:
	var body := _bx(b, x0, x1, y0, y0 + 0.3, z0, z1, c8(0x7a2e22), {"surface": "timber", "parent": parent, "name": "Radio", "radius": 0.03})
	# the speaker cloth in a bezel, the tuning window, two knobs, a carry handle
	_bx(b, x1 - 0.004, x1 + 0.006, y0 + 0.05, y0 + 0.25, z0 + 0.05, (z0 + z1) * 0.5 + 0.01, c8(0xc9a55a), {"surface": "metal", "parent": parent, "name": "Bezel", "radius": 0.004, "cast_shadow": false})
	_bx(b, x1 + 0.002, x1 + 0.008, y0 + 0.06, y0 + 0.24, z0 + 0.06, (z0 + z1) * 0.5, c8(0xc8b890), {"surface": "fabric", "parent": parent, "name": "Grille", "radius": 0.003, "cast_shadow": false})
	_bx(b, x1 - 0.002, x1 + 0.01, y0 + 0.17, y0 + 0.23, (z0 + z1) * 0.5 + 0.04, z1 - 0.04, c8(0xe8d8a0), {"surface": "metal", "parent": parent, "name": "Dial", "radius": 0.004, "cast_shadow": false})
	for k in 2:
		var kz := (z0 + z1) * 0.5 + 0.07 + k * 0.1
		_put(b, ModelKit.puck(0.022, 0.02, 0.005, 16), Vector3(x1, y0 + 0.09, kz), "grain", c8(0x2a2420), parent, "Knob", {"rotation": Vector3(0, 0, -PI / 2), "cast_shadow": false})
	_put(b, ModelKit.tube([Vector3(0, 0, -0.1), Vector3(0, 0.06, -0.08), Vector3(0, 0.06, 0.08), Vector3(0, 0, 0.1)], 0.009, 0.03, 8),
		Vector3((x0 + x1) * 0.5, y0 + 0.3, (z0 + z1) * 0.5), "grain", c8(0x2a2420), parent, "Handle")
	_put(b, ModelKit.tube([Vector3(x0 + 0.1, y0 + 0.3, z1 - 0.1), Vector3(x0 + 0.3, y0 + 0.75, z1 - 0.2)], 0.004, 0.0, 6), Vector3.ZERO, "metal", c8(0xcccccc), parent, "Aerial")
	b.piece(_sphere(0.008), Vector3(x0 + 0.3, y0 + 0.75, z1 - 0.2), b.surface("metal"), {"parent": parent, "name": "AerialTip", "tint": c8(0xcccccc)})
	return body


static func altar(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, parent: String, facing_x := 1.0) -> void:
	_bx(b, x0, x1, y0, y1, z0, z1, c8(0xa8453a), {"surface": "timber", "parent": parent, "name": "Altar", "radius": 0.012})
	_bx(b, x0 - 0.01, x1 + 0.01, y1, y1 + 0.03, z0 - 0.02, z1 + 0.02, c8(0x7a2e22), {"surface": "timber", "parent": parent, "name": "AltarLip", "radius": 0.01})
	# a gold line round the front, the way the shrines were painted
	var fx := x1 + 0.001 if facing_x > 0 else x0 - 0.004
	_bx(b, fx, fx + 0.003, y0 + 0.04, y1 - 0.04, z0 + 0.04, z1 - 0.04, c8(0xd8b040), {"surface": "metal", "parent": parent, "name": "AltarTrim", "radius": 0.001, "cast_shadow": false})
	var cx := x1 - 0.08 if facing_x > 0 else x0 + 0.08
	var mz := (z0 + z1) * 0.5
	# the red lamp, a little tulip of glass on a stem
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.025, 0), Vector2(0.008, 0.02), Vector2(0.008, 0.11), Vector2(0, 0.11)]), 12),
		Vector3(cx, y1 + 0.03, mz + 0.09), "metal", c8(0xc9a55a), parent, "LampStem")
	b.piece(ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.03, 0.01), Vector2(0.048, 0.05), Vector2(0.04, 0.08), Vector2(0, 0.075)]), 16),
		Vector3(cx, y1 + 0.14, mz + 0.09), b.emissive(c8(0xff4a2a), 4.0), {"parent": parent, "name": "RedLamp", "cast_shadow": false})
	# the censer: a brass bowl on three feet, full of ash
	var censer := Vector3(cx, y1 + 0.03, mz)
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0.015), Vector2(0.04, 0.015), Vector2(0.062, 0.05), Vector2(0.058, 0.09), Vector2(0.066, 0.1),
		Vector2(0.06, 0.104), Vector2(0, 0.104)], 0.008), 20), censer, "metal", c8(0xc9a55a), parent, "Censer")
	for k in 3:
		var a := TAU * k / 3 + 0.5
		_put(b, ModelKit.tube([Vector3(cos(a) * 0.035, 0.0, sin(a) * 0.035), Vector3(cos(a) * 0.03, 0.025, sin(a) * 0.03)], 0.006, 0.0, 6), censer, "metal", c8(0xa88a40), parent, "CenserFoot", {"cast_shadow": false})
	_put(b, ModelKit.puck(0.055, 0.004, 0.002, 18), censer + Vector3(0, 0.098, 0), "concrete", c8(0x9a9690), parent, "Ash", {"cast_shadow": false})
	for i in 3:
		var z := mz - 0.02 + i * 0.02
		var lean := (i - 1) * 0.012
		_put(b, ModelKit.tube([Vector3(cx, y1 + 0.13, z), Vector3(cx + lean * 0.3, y1 + 0.36, z + lean)], 0.0025, 0.0, 5), Vector3.ZERO, "grain", c8(0xb04030), parent, "Incense", {"cast_shadow": false})
		b.piece(_sphere(0.006), Vector3(cx + lean * 0.3, y1 + 0.363, z + lean), b.emissive(c8(0xff7a30), 6.0), {"parent": parent, "name": "Ember", "cast_shadow": false})


static func tube_light(b: LevelBuilder, a: Vector3, bb: Vector3, ceiling: float, parent: String,
		tint := Color(0.9, 0.97, 1.0)) -> void:
	## A suspended fluorescent batten: two short stems connect its housing to the
	## ceiling so the fixture never reads as floating below the slab.
	var fixture := {"parent": parent, "ceiling_mounted": true, "cast_shadow": false}
	var mid := (a + bb) * 0.5
	var along := (bb - a)
	var len := along.length()
	var x_axis := absf(along.x) > absf(along.z)
	var hw := len * 0.5
	if x_axis:
		_bx(b, mid.x - hw, mid.x + hw, mid.y, mid.y + 0.05, mid.z - 0.05, mid.z + 0.05, c8(0xe8e8e0), fixture.merged({"surface": "metal", "name": "Batten", "radius": 0.012}))
	else:
		_bx(b, mid.x - 0.05, mid.x + 0.05, mid.y, mid.y + 0.05, mid.z - hw, mid.z + hw, c8(0xe8e8e0), fixture.merged({"surface": "metal", "name": "Batten", "radius": 0.012}))
	var dir := along.normalized()
	b.cylinder(a + Vector3(0, -0.025, 0) + dir * 0.03, bb + Vector3(0, -0.025, 0) - dir * 0.03, 0.02, b.emissive(tint, 5.0), fixture.merged({"name": "Tube", "segments": 16}))
	# the tube's end caps in their sockets
	for end in [[a, dir], [bb, -dir]]:
		ModelKit.place(b, ModelKit.tube([Vector3.ZERO, (end[1] as Vector3) * 0.03], 0.022, 0.0, 12), (end[0] as Vector3) + Vector3(0, -0.025, 0), "metal", c8(0xd8d8d0), fixture.merged({"name": "TubeCap"}))
	var housing_top := mid.y + 0.05
	if ceiling > housing_top + 0.01:
		for t in [0.18, 0.82]:
			var mount := a.lerp(bb, t)
			b.cylinder(Vector3(mount.x, housing_top, mount.z), Vector3(mount.x, ceiling, mount.z), 0.012,
				b.surface("metal"), fixture.merged({"name": "BattenMount", "tint": c8(0x6a6a68)}))


static func bulb(b: LevelBuilder, pos: Vector3, ceiling: float, parent: String, col := Color(1.0, 0.8, 0.5)) -> void:
	## A bare bulb hanging on its flex from a bakelite rose: a pear of glass
	## under a brass cap in a black lampholder.
	var fixture := {"parent": parent, "ceiling_mounted": true, "cast_shadow": false}
	_put(b, ModelKit.tube([Vector3(pos.x, ceiling, pos.z), pos + Vector3(0, 0.12, 0)], 0.004, 0.0, 6), Vector3.ZERO, "grain", c8(0x222222), parent, "Flex", fixture)
	_put(b, ModelKit.puck(0.035, 0.022, 0.008, 16), Vector3(pos.x, ceiling - 0.022, pos.z), "grain", c8(0x2a2622), parent, "CeilingRose", fixture)
	b.piece(ModelKit.lathe(PackedVector2Array([Vector2(0, -0.055), Vector2(0.022, -0.05), Vector2(0.04, -0.03), Vector2(0.05, 0.0), Vector2(0.042, 0.03),
		Vector2(0.02, 0.05), Vector2(0.016, 0.06), Vector2(0, 0.06)]), 16), pos, b.emissive(col, 6.0), fixture.merged({"name": "Bulb"}))
	_put(b, ModelKit.puck(0.016, 0.02, 0.003, 12), pos + Vector3(0, 0.055, 0), "metal", c8(0xc9a55a), parent, "BulbCap", fixture)
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.024, 0), Vector2(0.026, 0.04), Vector2(0.014, 0.065), Vector2(0, 0.065)], 0.006), 14),
		pos + Vector3(0, 0.07, 0), "metal", c8(0x2a2a2a), parent, "Socket", fixture)


static func ac_unit(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, parent: String, band := -1.0, fadeable := false) -> void:
	var o := {"surface": "metal", "parent": parent, "name": "AirCon", "fadeable": fadeable, "radius": 0.025}
	if band >= 0:
		o["band"] = band
	_bx(b, x0, x1, y0, y1, z0, z1, c8(0xc8c6be), o)
	# louvres along the top of every face: a box seen from any side reads as a unit
	var lo := o.duplicate()
	lo["radius"] = 0.004
	lo["name"] = "Louvre"
	lo["cast_shadow"] = false
	for k in 4:
		var ly := y1 - 0.05 - k * 0.035
		if ly - 0.012 < y0 + 0.04:
			break
		_bx(b, x0 + 0.04, x1 - 0.04, ly - 0.012, ly, z0 - 0.006, z1 + 0.006, c8(0xa8a69e), lo)
		_bx(b, x0 - 0.006, x1 + 0.006, ly - 0.012, ly, z0 + 0.04, z1 - 0.04, c8(0xa8a69e), lo)
	# a condenser big enough to stand on a roof blows upward through fans in round guards
	var w := x1 - x0
	var d := z1 - z0
	if w > 1.0 and d > 0.8:
		var r := minf(d * 0.4, 0.42)
		var fans := maxi(1, int(w / (2.2 * r)))
		for k in fans:
			var c := Vector3(x0 + w * (k + 0.5) / fans, y1 + 0.03, (z0 + z1) * 0.5)
			var go := {"parent": parent, "name": "FanGuard", "rotation": Vector3(-PI / 2, 0, 0), "cast_shadow": false}
			if band >= 0:
				go["band"] = band
			ModelKit.place(b, _guard(r), c, "metal", c8(0x5a5a58), go)
			var so := go.duplicate()
			so.erase("rotation")
			so["name"] = "FanShroud"
			ModelKit.place(b, ModelKit.puck(r * 1.05, 0.03, 0.01, 28), c - Vector3(0, 0.03, 0), "metal", c8(0x2a2a2a), so)


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2
	s.radial_segments = 16
	s.rings = 8
	return s


# ----------------------------------------------------------------------------- one room, lived in
#
# A Walled City home was usually one room of twenty-odd square metres for a
# whole family: they slept in bunks and on a cockloft, cooked at a counter in
# a corner, and kept everything else in boxes. Toilets were mostly shared, a
# cubicle off the corridor; some flats squeezed a squat pan behind a curtain.


## A small pipe through the given points, bent smoothly at every corner, with
## a collar at each bend where the lengths were joined.
static func pipe_run(b: LevelBuilder, pts: Array, r: float, col: Color, parent: String, band: float, pipe_name := "Pipe", fadeable := false) -> void:
	var clean := []
	for p in pts:
		if clean.is_empty() or (clean[-1] as Vector3).distance_to(p) > 0.005:
			clean.append(p)
	if clean.size() < 2:
		return
	var origin: Vector3 = clean[0]
	var local := []
	for p in clean:
		local.append(p - origin)
	ModelKit.place(b, ModelKit.tube(local, r, r * 2.5, 10), origin, "metal", col, {"parent": parent, "name": pipe_name, "band": band, "fadeable": fadeable})
	for i in range(1, clean.size() - 1):
		var d: Vector3 = (clean[i + 1] - clean[i]).normalized()
		var at: Vector3 = clean[i] + d * r * 3.2
		ModelKit.place(b, ModelKit.tube([-d * r * 0.6, d * r * 0.6], r * 1.25, 0.0, 10), at, "metal", col.darkened(0.1),
			{"parent": parent, "name": pipe_name + "Collar", "band": band, "cast_shadow": false, "fadeable": fadeable})


## A cement counter against a wall with a two-ring gas stove and a wok, a
## rice cooker, a kettle and a stack of bowls; a gas bottle on the floor at
## its far end. `wall` is the side it stands against: "n" (its length along x,
## the wall at z0) or "e" (its length along z, the wall at x1).
static func kitchen_counter(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, parent: String, wall := "n", band := -1.0) -> void:
	var top := y + 0.8
	_bx(b, x0, x1, y + 0.08, top - 0.04, z0, z1, c8(0x8e8a80), _o(parent, band, "Counter", "concrete", {"radius": 0.01}))
	if wall == "n":
		_bx(b, x0 + 0.03, x1 - 0.03, y, y + 0.08, z0, z1 - 0.05, c8(0x4a4640), _o(parent, band, "Plinth", "concrete", {"radius": 0.006}))
		for k in 2:
			var cx0 := x0 + 0.06 + (x1 - x0 - 0.12) * k / 2.0
			var cx1 := cx0 + (x1 - x0 - 0.12) / 2.0 - 0.04
			_bx(b, cx0, cx1, y + 0.14, top - 0.12, z1, z1 + 0.018, c8(0x6f8a7a), _o(parent, band, "CupboardDoor", "grain", {"cast_shadow": false, "radius": 0.006}))
			_bx(b, cx0 + 0.045, cx1 - 0.045, y + 0.185, top - 0.165, z1 + 0.012, z1 + 0.024, c8(0x7a9686), _o(parent, band, "DoorPanel", "grain", {"cast_shadow": false, "radius": 0.008}))
			_put(b, ModelKit.puck(0.016, 0.022, 0.005, 12), Vector3(cx1 - 0.025, y + 0.53, z1 + 0.018), "metal", c8(0x3a3028), parent, "CupboardKnob", {"rotation": Vector3(PI / 2, 0, 0), "cast_shadow": false})
	else:
		_bx(b, x0 + 0.05, x1, y, y + 0.08, z0 + 0.03, z1 - 0.03, c8(0x4a4640), _o(parent, band, "Plinth", "concrete", {"radius": 0.006}))
		for k in 2:
			var cz0 := z0 + 0.06 + (z1 - z0 - 0.12) * k / 2.0
			var cz1 := cz0 + (z1 - z0 - 0.12) / 2.0 - 0.04
			_bx(b, x0 - 0.018, x0, y + 0.14, top - 0.12, cz0, cz1, c8(0x6f8a7a), _o(parent, band, "CupboardDoor", "grain", {"cast_shadow": false, "radius": 0.006}))
			_bx(b, x0 - 0.024, x0 - 0.012, y + 0.185, top - 0.165, cz0 + 0.045, cz1 - 0.045, c8(0x7a9686), _o(parent, band, "DoorPanel", "grain", {"cast_shadow": false, "radius": 0.008}))
			_put(b, ModelKit.puck(0.016, 0.022, 0.005, 12), Vector3(x0 - 0.018, y + 0.53, cz1 - 0.025), "metal", c8(0x3a3028), parent, "CupboardKnob", {"rotation": Vector3(0, 0, PI / 2), "cast_shadow": false})
	_bx(b, x0 - 0.02, x1 + 0.02, top - 0.04, top, z0 - 0.02, z1 + 0.02, c8(0xd8d4c8), _o(parent, band, "CounterTop", "tiles", {"radius": 0.008}))
	b.add_obstacle(x0, x1, z0, z1, y, "counter")
	var along_x := wall == "n"
	var depth := (z1 - z0) if along_x else (x1 - x0)
	var lo := x0 if along_x else z0
	var hi := x1 if along_x else z1
	var bd := band if band >= 0.0 else b.band_of(top)
	var pb := {"band": bd}
	# the stove: an enamelled two-ring burner, a pan grate on each ring, two taps on its front
	var sc := _along(along_x, lo + (hi - lo) * 0.55, top, x1, z0, depth * 0.5)
	var half := Vector3(0.28, 0, 0.17) if along_x else Vector3(0.17, 0, 0.28)
	_bx(b, sc.x - half.x, sc.x + half.x, top, top + 0.09, sc.z - half.z, sc.z + half.z, c8(0x2a2a2a), _o(parent, band, "Stove", "metal", {"radius": 0.014}))
	var out := Vector3(0, 0, 1) if along_x else Vector3(-1, 0, 0)
	var side := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	for s in [-1.0, 1.0]:
		var rc: Vector3 = sc + side * 0.13 * s
		_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.07, 0), Vector2(0.07, 0.012), Vector2(0.045, 0.02), Vector2(0.045, 0.028), Vector2(0, 0.028)], 0.004), 20),
			rc + Vector3(0, 0.09, 0), "metal", c8(0x4a4a48), parent, "Burner", pb)
		_put(b, ModelKit.tube(_circle(0.085, 20), 0.005, 0.0, 6, false), rc + Vector3(0, 0.125, 0), "metal", c8(0x1e1e1e), parent, "Grate", pb.merged({"cast_shadow": false}))
		for k in 4:
			var a := TAU * k / 4 + PI / 4
			_put(b, ModelKit.tube([Vector3(cos(a) * 0.04, 0.125, sin(a) * 0.04), Vector3(cos(a) * 0.09, 0.125, sin(a) * 0.09), Vector3(cos(a) * 0.09, 0.09, sin(a) * 0.09)], 0.005, 0.006, 5),
				rc, "metal", c8(0x1e1e1e), parent, "Grate", pb.merged({"cast_shadow": false}))
		var tap: Vector3 = sc + side * 0.13 * s + out * (half.z if along_x else half.x)
		_put(b, ModelKit.puck(0.018, 0.025, 0.006, 12), tap + Vector3(0, 0.045, 0), "grain", c8(0xd8d4c8), parent, "StoveTap",
			pb.merged({"rotation": Vector3(PI / 2, 0, 0) if along_x else Vector3(0, 0, PI / 2), "cast_shadow": false}))
	# the wok on the left ring: thin, black, a long wooden handle and a loop opposite
	var wc := sc - side * 0.13
	var wok_profile := PackedVector2Array([Vector2(0, 0), Vector2(0.06, 0.004), Vector2(0.12, 0.025), Vector2(0.17, 0.065), Vector2(0.19, 0.095),
		Vector2(0.183, 0.096), Vector2(0.163, 0.068), Vector2(0.115, 0.03), Vector2(0.058, 0.01), Vector2(0, 0.006)])
	_put(b, ModelKit.lathe(wok_profile, 28), wc + Vector3(0, 0.13, 0), "metal", c8(0x2e2c2a), parent, "Wok", pb)
	_put(b, ModelKit.tube([side * -0.18 + Vector3(0, 0.215, 0), side * -0.3 + Vector3(0, 0.235, 0), side * -0.42 + Vector3(0, 0.25, 0)], 0.014, 0.02, 10),
		wc, "timber", c8(0x6b4a30), parent, "WokHandle", pb)
	_put(b, ModelKit.tube([side * 0.17 + out * 0.035 + Vector3(0, 0.22, 0), side * 0.23 + out * 0.02 + Vector3(0, 0.225, 0), side * 0.23 - out * 0.02 + Vector3(0, 0.225, 0), side * 0.17 - out * 0.035 + Vector3(0, 0.22, 0)], 0.005, 0.012, 6),
		wc, "metal", c8(0x2e2c2a), parent, "WokEar", pb.merged({"cast_shadow": false}))
	# the rice cooker, white, a domed lid, a red light on its face
	var rc2 := _along(along_x, lo + (hi - lo) * 0.15, top, x1, z0, depth * 0.5)
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.11, 0), Vector2(0.125, 0.03), Vector2(0.125, 0.19), Vector2(0.115, 0.205), Vector2(0, 0.205)], 0.02), 28),
		rc2, "glaze", c8(0xeceae2), parent, "RiceCooker", pb)
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.112, 0), Vector2(0.105, 0.02), Vector2(0.075, 0.042), Vector2(0, 0.05)]), 28),
		rc2 + Vector3(0, 0.2, 0), "grain", c8(0xd8d6ce), parent, "RiceCookerLid", pb)
	_put(b, ModelKit.tube([side * -0.03 + Vector3(0, 0.25, 0), side * -0.025 + Vector3(0, 0.27, 0), side * 0.025 + Vector3(0, 0.27, 0), side * 0.03 + Vector3(0, 0.25, 0)], 0.007, 0.008, 8),
		rc2, "grain", c8(0x3a3a3a), parent, "RiceCookerKnob", pb.merged({"cast_shadow": false}))
	for s in [-1.0, 1.0]:
		_put(b, ModelKit.tube([side * s * 0.12 + Vector3(0, 0.15, 0), side * s * 0.15 + Vector3(0, 0.155, 0), side * s * 0.15 + Vector3(0, 0.175, 0), side * s * 0.12 + Vector3(0, 0.18, 0)], 0.008, 0.008, 8),
			rc2, "grain", c8(0x3a3a3a), parent, "RiceCookerHandle", pb.merged({"cast_shadow": false}))
	b.piece(_sphere(0.011), rc2 + out * 0.126 + Vector3(0, 0.07, 0), b.emissive(c8(0xe03a2a), 2.5), {"parent": parent, "name": "RiceCookerLight", "band": bd, "cast_shadow": false})
	# the kettle: an aluminium dome with a curved spout and a wire handle
	var kc := _along(along_x, lo + (hi - lo) * 0.9, top, x1, z0, depth * 0.45)
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.085, 0), Vector2(0.09, 0.06), Vector2(0.07, 0.13), Vector2(0.04, 0.155), Vector2(0, 0.155)], 0.025), 24),
		kc, "metal", c8(0xb8bcc0), parent, "Kettle", pb)
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.042, 0), Vector2(0.03, 0.02), Vector2(0.008, 0.025), Vector2(0.012, 0.045), Vector2(0, 0.048)], 0.005), 16),
		kc + Vector3(0, 0.15, 0), "metal", c8(0x9aa0a4), parent, "KettleLid", pb)
	_put(b, ModelKit.tube([side * 0.07 + Vector3(0, 0.04, 0), side * 0.12 + Vector3(0, 0.08, 0), side * 0.14 + Vector3(0, 0.14, 0), side * 0.165 + Vector3(0, 0.155, 0)], 0.011, 0.04, 10),
		kc, "metal", c8(0xb8bcc0), parent, "KettleSpout", pb)
	_put(b, ModelKit.tube([side * -0.055 + Vector3(0, 0.12, 0), side * -0.05 + Vector3(0, 0.22, 0), side * 0.05 + Vector3(0, 0.22, 0), side * 0.055 + Vector3(0, 0.12, 0)], 0.006, 0.035, 8),
		kc, "grain", c8(0x2a2420), parent, "KettleHandle", pb.merged({"cast_shadow": false}))
	# rice bowls stacked to drain, rims and feet
	var bc := _along(along_x, lo + (hi - lo) * 0.32, top, x1, z0, depth * 0.35)
	var bowl := _rice_bowl(0.065)
	for k in 3:
		_put(b, bowl, bc + Vector3(0, 0.026 * k, 0), "glaze", [c8(0xe8e4d8), c8(0x5a7aa8), c8(0xe8e4d8)][k], parent, "Bowl", pb)
	# the gas bottle, on the floor just past the far end: foot ring, body, shoulder, guard collar, valve
	var gb := _along(along_x, hi + 0.2, y, x1, z0, depth * 0.5)
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0.02), Vector2(0.13, 0.02), Vector2(0.15, 0.06), Vector2(0.15, 0.48), Vector2(0.12, 0.56), Vector2(0.05, 0.6), Vector2(0, 0.6)], 0.03), 28),
		gb, "metal", c8(0xb8392e), parent, "GasBottle", pb)
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0.12, 0), Vector2(0.135, 0), Vector2(0.135, 0.04), Vector2(0.12, 0.04)]), 28), gb, "metal", c8(0x8a2a22), parent, "GasBottleFoot", pb)
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0.075, 0), Vector2(0.085, 0), Vector2(0.085, 0.09), Vector2(0.075, 0.09)]), 20), gb + Vector3(0, 0.57, 0), "metal", c8(0x8a2a22), parent, "GasBottleTop", pb)
	var valve := gb + Vector3(0, 0.62, 0)
	_put(b, ModelKit.puck(0.022, 0.05, 0.004, 12), gb + Vector3(0, 0.58, 0), "metal", c8(0xc9a55a), parent, "GasValve", pb)
	_put(b, ModelKit.puck(0.03, 0.012, 0.004, 12), gb + Vector3(0, 0.64, 0), "metal", c8(0x2a2a2a), parent, "GasValveWheel", pb)
	# the hose: from the valve, drooping, into the counter's end face under the stove
	var end_face := Vector3(hi, y + 0.55, z0 + depth * 0.3) if along_x else Vector3(x1 - depth * 0.3, y + 0.55, hi)
	var hose := []
	for k in 9:
		var t := k / 8.0
		hose.append(valve.lerp(end_face, t) + Vector3(0, -0.16 * sin(t * PI), 0) - valve)
	_put(b, ModelKit.tube(hose, 0.011, 0.0, 8), valve, "grain", c8(0xd8a030), parent, "GasHose", pb.merged({"cast_shadow": false}))
	b.add_obstacle(gb.x - 0.16, gb.x + 0.16, gb.z - 0.16, gb.z + 0.16, y, "gasBottle")


static func _circle(r: float, n: int) -> Array:
	var pts := []
	for k in n + 1:
		var a := TAU * k / n
		pts.append(Vector3(cos(a) * r, 0, sin(a) * r))
	return pts


## A rice bowl of radius r: a foot ring, a flared body, a thin rim, on y = 0.
static func _rice_bowl(r: float) -> ArrayMesh:
	var h := r * 0.85
	return ModelKit.lathe(PackedVector2Array([Vector2(0, 0.004), Vector2(r * 0.42, 0.004), Vector2(r * 0.42, 0), Vector2(r * 0.5, 0), Vector2(r * 0.52, h * 0.12),
		Vector2(r * 0.85, h * 0.45), Vector2(r, h), Vector2(r * 0.94, h), Vector2(r * 0.8, h * 0.5), Vector2(r * 0.45, h * 0.2), Vector2(0, h * 0.18)]), 24)


## A point `a` along a counter's length, `d` out from its wall, at height y.
static func _along(along_x: bool, a: float, y: float, x1: float, z0: float, d: float) -> Vector3:
	return Vector3(a, y, z0 + d) if along_x else Vector3(x1 - d, y, a)


## An upper bunk over a bed (x0..x1, z0..z1): corner posts, a deck with its
## own mattress and blanket, a guard rail, and a ladder at the foot on the x1 side.
static func bunk_top(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, frame: Color, sheet: Color, blanket: Color, parent: String) -> void:
	var post := 0.07
	var wood := func(part: String, r := 0.01, shadow := true) -> Dictionary:
		return {"surface": "timber", "parent": parent, "name": part, "radius": r, "cast_shadow": shadow}
	for x in [x0 + 0.02, x1 - post - 0.02]:
		for z in [z0 + 0.02, z1 - post - 0.02]:
			_bx(b, x, x + post, y, y + 1.95, z, z + post, frame, wood.call("BunkPost", 0.012))
			_put(b, _finial(0.03), Vector3(x + post * 0.5, y + 1.95, z + post * 0.5), "timber", frame, parent, "Finial")
	var deck := y + 1.35
	_bx(b, x0, x1, deck, deck + 0.08, z0, z1, frame, wood.call("BunkDeck", 0.012))
	_put(b, ModelKit.cushion(Vector3(x1 - x0 - 0.1, 0.14, z1 - z0 - 0.1), 0.04, 0.01, 0.006), Vector3((x0 + x1) * 0.5, deck + 0.15, (z0 + z1) * 0.5), "fabric", sheet, parent, "BunkMattress")
	_put(b, ModelKit.cushion(Vector3(x1 - x0 - 0.06, 0.05, z1 - z0 - 0.62), 0.022, 0.01, 0.0), Vector3((x0 + x1) * 0.5, deck + 0.245, (z0 + 0.6 + z1 - 0.06) * 0.5), "fabric", blanket, parent, "BunkBlanket")
	_put(b, ModelKit.cushion(Vector3(x1 - x0 - 0.6, 0.08, 0.38), 0.035, 0.03, 0.008), Vector3((x0 + x1) * 0.5, deck + 0.27, z0 + 0.31), "fabric", c8(0xf0ebdf), parent, "BunkPillow")
	# the guard rail on the open side: from the head post to the ladder's near
	# stile, joined into both, with a stub down to the deck at each end
	var lz := z1 - 0.5
	_bx(b, x1 - 0.02, x1 + 0.05, deck + 0.35, deck + 0.42, z0 + 0.02, lz + 0.05, frame, wood.call("BunkRail"))
	_bx(b, x1 - 0.02, x1 + 0.05, deck + 0.08, deck + 0.35, z0 + 0.02, z0 + 0.09, frame, wood.call("BunkRailPost"))
	# the deck's edge board along the open side, carrying the rail's foot
	_bx(b, x1 - 0.02, x1 + 0.05, deck - 0.02, deck + 0.1, z0, z1, frame.darkened(0.1), wood.call("BunkSideBoard", 0.008))
	for dz in [0.0, 0.38]:
		_bx(b, x1, x1 + 0.05, y, deck + 0.42, lz + dz, lz + dz + 0.05, frame, wood.call("LadderRail"))
	for k in 4:
		var ry := y + 0.35 + k * 0.33
		_put(b, ModelKit.tube([Vector3(0, 0, 0), Vector3(0, 0, 0.33)], 0.017, 0.0, 10), Vector3(x1 + 0.025, ry + 0.02, lz + 0.05), "timber", frame.darkened(0.15), parent, "LadderRung", {"cast_shadow": false})


## A cockloft: a timber platform high in a corner (x0..x1, against the wall
## at z0), carried on two posts at its front edge (z1), with bedding rolls and
## cases up on it and a ladder leaning up to it at the x1 end.
static func cockloft(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, h: float, parent: String) -> void:
	var wood := c8(0x6b4a30)
	_bx(b, x0, x1, y + h, y + h + 0.08, z0, z1, wood, {"surface": "timber", "parent": parent, "name": "LoftDeck", "radius": 0.01})
	_bx(b, x0, x1, y + h - 0.12, y + h, z1 - 0.1, z1, wood.darkened(0.15), {"surface": "timber", "parent": parent, "name": "LoftBeam", "radius": 0.01})
	for x in [x0 + 0.05, x1 - 0.13]:
		_bx(b, x, x + 0.08, y, y + h, z1 - 0.1, z1 - 0.02, wood.darkened(0.1), {"surface": "timber", "parent": parent, "name": "LoftPost", "radius": 0.012})
		# a knee brace from post to beam
		_put(b, ModelKit.rbox(Vector3(0.05, 0.36, 0.05), 0.008), Vector3(x + 0.04 + (0.12 if x < (x0 + x1) * 0.5 else -0.12), y + h - 0.2, z1 - 0.06), "timber", wood.darkened(0.15), parent, "LoftBrace",
			{"rotation": Vector3(0, 0, -0.75 if x < (x0 + x1) * 0.5 else 0.75)})
		b.add_obstacle(x, x + 0.08, z1 - 0.1, z1 - 0.02, y, "loftPost")
	var top := y + h + 0.08
	_bedding_roll(b, Vector3(x0 + 0.3, top + 0.13, z0 + 0.35), Vector3(x0 + 1.3, top + 0.13, z0 + 0.35), 0.13, c8(0x8a5a6a), parent)
	_bedding_roll(b, Vector3(x0 + 0.3, top + 0.12, z0 + 0.72), Vector3(x0 + 1.2, top + 0.12, z0 + 0.72), 0.12, c8(0x5a7ab0), parent)
	suitcase(b, x1 - 1.1, x1 - 0.35, top, top + 0.22, z0 + 0.1, z0 + 0.6, c8(0x7a4a36), parent)
	_put(b, ModelKit.cushion(Vector3(0.55, 0.16, 0.4), 0.05, 0.02, 0.02), Vector3(x1 - 0.725, top + 0.3, z0 + 0.35), "fabric", c8(0x3f5a6f), parent, "Case")
	for dx in [0.0, 0.34]:
		b.cylinder(Vector3(x1 - 0.5 + dx, y, z1 + 0.35), Vector3(x1 - 0.5 + dx, top + 0.3, z1 - 0.05), 0.022, b.surface("timber"), {"parent": parent, "name": "LoftLadder", "tint": wood, "segments": 12})
	for k in 5:
		var t := (k + 1) / 6.0
		var ly := y + (top + 0.3 - y) * t
		var lz := z1 + 0.35 - 0.4 * t
		b.cylinder(Vector3(x1 - 0.5, ly, lz), Vector3(x1 - 0.16, ly, lz), 0.016, b.surface("timber"), {"parent": parent, "name": "LoftRung", "tint": wood.darkened(0.1), "cast_shadow": false, "segments": 12})
	b.add_obstacle(x1 - 0.55, x1 - 0.1, z1 - 0.05, z1 + 0.4, y, "loftLadder")


## A quilt rolled up and tied twice with cloth strips.
static func _bedding_roll(b: LevelBuilder, a: Vector3, c: Vector3, r: float, col: Color, parent: String) -> void:
	var mid := (a + c) * 0.5
	var half := (c - a) * 0.5
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, -half.length()), Vector2(r, -half.length()), Vector2(r * 1.04, 0), Vector2(r, half.length()), Vector2(0, half.length())], r * 0.5), 20),
		mid, "fabric", col, parent, "BeddingRoll", {"basis": Basis(Vector3.FORWARD, -PI / 2) if absf(half.x) > absf(half.z) else Basis(Vector3.RIGHT, PI / 2)})
	for t in [-0.55, 0.55]:
		var at: Vector3 = mid + half * t
		var ring := []
		for k in 17:
			var ang := TAU * k / 16
			ring.append((Vector3(0, cos(ang), sin(ang)) if absf(half.x) > absf(half.z) else Vector3(cos(ang), sin(ang), 0)) * (r * 1.02))
		_put(b, ModelKit.tube(ring, 0.008, 0.0, 6, false), at, "fabric", col.darkened(0.35), parent, "Tie", {"cast_shadow": false})


## A hard suitcase: rounded shell, a lid seam, a leather handle, two latches.
## Its handle and latches are on the +z face.
static func suitcase(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, col: Color, parent: String) -> void:
	_bx(b, x0, x1, y0, y1, z0, z1, col, {"surface": "timber", "parent": parent, "name": "Suitcase", "radius": 0.025})
	var my := (y0 + y1) * 0.5
	_bx(b, x0 - 0.002, x1 + 0.002, my - 0.006, my + 0.006, z0 - 0.002, z1 + 0.002, col.darkened(0.35), {"surface": "grain", "parent": parent, "name": "SuitcaseSeam", "radius": 0.004, "cast_shadow": false})
	var cx := (x0 + x1) * 0.5
	_put(b, ModelKit.tube([Vector3(-0.07, 0, 0), Vector3(-0.06, 0.04, 0), Vector3(0.06, 0.04, 0), Vector3(0.07, 0, 0)], 0.01, 0.025, 8), Vector3(cx, my, z1 + 0.012), "fabric", c8(0x3a2418), parent, "SuitcaseHandle")
	for s in [-1.0, 1.0]:
		_bx(b, cx + s * 0.16 - 0.02, cx + s * 0.16 + 0.02, my - 0.015, my + 0.02, z1, z1 + 0.008, c8(0xc9b070), {"surface": "metal", "parent": parent, "name": "Latch", "radius": 0.003, "cast_shadow": false})


## A squat toilet against the wall at z = `wall_z` (the pan runs out from it
## toward +z): the white pan and its foot treads, a high cistern with a flush
## pipe and pull chain fed from `feed` (a point on a water pipe), and a bucket
## and scoop for when the cistern runs dry.
static func squat_toilet(b: LevelBuilder, x: float, wall_z: float, y: float, parent: String, feed: Vector3, band := -1.0) -> void:
	var bd := band if band >= 0.0 else b.band_of(y + 0.5)
	var pb := {"band": bd}
	var z0 := wall_z + 0.18
	_bx(b, x - 0.22, x + 0.22, y, y + 0.04, z0, z0 + 0.62, c8(0xf2f0ea), _o(parent, band, "Pan", "glaze", {"radius": 0.015}))
	# the bowl, an oval sunk into the pan, dark with its water
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(1.0, 0), Vector2(1.0, 0.004), Vector2(0, 0.004)]), 28, Vector2(0.12, 0.19)),
		Vector3(x, y + 0.038, z0 + 0.27), "glaze", c8(0xb8c4c4), parent, "PanBowl", pb.merged({"cast_shadow": false}))
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(1.0, 0), Vector2(1.0, 0.004), Vector2(0, 0.004)]), 28, Vector2(0.06, 0.09)),
		Vector3(x, y + 0.04, z0 + 0.22), "glaze", c8(0x6a8088), parent, "PanWater", pb.merged({"cast_shadow": false}))
	# the treads: ribbed, to stand on
	for s in [-1.0, 1.0]:
		for k in 4:
			var tz := z0 + 0.3 + k * 0.055
			_bx(b, x + 0.16 * s - 0.05, x + 0.16 * s + 0.05, y + 0.04, y + 0.052, tz, tz + 0.035, c8(0xd8d6ce), _o(parent, band, "FootTread", "glaze", {"cast_shadow": false, "radius": 0.005}))
	var cy := y + 1.95
	_bx(b, x - 0.2, x + 0.2, cy, cy + 0.26, wall_z + 0.02, wall_z + 0.18, c8(0xe8e6de), _o(parent, band, "Cistern", "glaze", {"radius": 0.018}))
	# the flush pipe down the wall, bending out into the back of the pan
	pipe_run(b, [Vector3(x, cy, wall_z + 0.1), Vector3(x, y + 0.1, wall_z + 0.1), Vector3(x, y + 0.1, z0 + 0.02)], 0.022, c8(0xb8bcc0), parent, bd, "FlushPipe")
	# the pan's hood at the wall end
	_bx(b, x - 0.11, x + 0.11, y + 0.04, y + 0.12, z0, z0 + 0.1, c8(0xf2f0ea), _o(parent, band, "PanHood", "glaze", {"radius": 0.03}))
	# the cistern's lid and a bracket under it
	_bx(b, x - 0.21, x + 0.21, cy + 0.26, cy + 0.28, wall_z + 0.01, wall_z + 0.19, c8(0xd8d6ce), _o(parent, band, "CisternLid", "glaze", {"radius": 0.008}))
	for s in [-1.0, 1.0]:
		_put(b, ModelKit.slab(PackedVector2Array([Vector2(0, 0), Vector2(0.14, 0), Vector2(0.14, 0.02), Vector2(0.02, 0.12), Vector2(0, 0.12)]), 0.025, 0.003),
			Vector3(x + 0.15 * s, cy - 0.12, wall_z), "metal", c8(0x5a5a58), parent, "CisternBracket", pb.merged({"rotation": Vector3(0, -PI / 2, 0), "cast_shadow": false}))
	# the pull chain, link by link, and its wooden handle
	var link := ModelKit.tube(_oval(0.009, 0.016, 12), 0.0018, 0.0, 5, false)
	for k in 30:
		_put(b, link, Vector3(x + 0.16, cy - 0.013 - k * 0.023, wall_z + 0.17), "metal", c8(0x8a8a86), parent, "PullChain", pb.merged({"cast_shadow": false, "rotation": Vector3(PI / 2, (k % 2) * PI / 2, 0)}))
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.014, 0), Vector2(0.02, 0.04), Vector2(0.014, 0.08), Vector2(0, 0.08)], 0.008), 12),
		Vector3(x + 0.16, cy - 0.78, wall_z + 0.17), "timber", c8(0x3a2a1a), parent, "PullHandle", pb)
	# water in: from the pipe, back to the wall, along it, and down into the cistern
	var inlet := Vector3(x - 0.14, cy + 0.26, wall_z + 0.1)
	pipe_run(b, [feed, Vector3(feed.x, feed.y, inlet.z), Vector3(inlet.x, feed.y, inlet.z), inlet], 0.018, c8(0x9aa0a4), parent, bd, "FeedPipe")
	var bx := x + 0.42
	bucket(b, Vector3(bx, y, z0 + 0.2), 0.14, 0.3, c8(0xc9463a), parent, bd)
	# the scoop, resting across the rim
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.045, 0), Vector2(0.05, 0.06), Vector2(0.046, 0.06), Vector2(0.041, 0.004), Vector2(0, 0.004)]), 16),
		Vector3(bx + 0.02, y + 0.255, z0 + 0.2), "grain", c8(0x3f6fa8), parent, "Scoop", pb)
	_put(b, ModelKit.tube([Vector3(bx + 0.06, y + 0.3, z0 + 0.2), Vector3(bx + 0.2, y + 0.36, z0 + 0.2)], 0.01, 0.0, 8), Vector3.ZERO, "grain", c8(0x3f6fa8), parent, "ScoopHandle", pb)
	b.add_obstacle(bx - 0.15, bx + 0.15, z0 + 0.05, z0 + 0.35, y, "bucket")


## A bucket standing at `base`: tapered, a rolled rim, water a little under
## it, and a wire handle with a wooden grip laid down to one side.
static func bucket(b: LevelBuilder, base: Vector3, r: float, h: float, col: Color, parent: String, band: float) -> void:
	var pb := {"band": band}
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(r * 0.8, 0), Vector2(r, h), Vector2(r * 1.05, h), Vector2(r * 1.05, h - 0.01),
		Vector2(r * 0.97, h - 0.008), Vector2(r * 0.77, 0.01), Vector2(0, 0.01)]), 28), base, "grain", col, parent, "Bucket", pb)
	_put(b, ModelKit.puck(r * 0.92, 0.004, 0.001, 28), base + Vector3(0, h - 0.045, 0), "grain", c8(0x7fa0b8), parent, "BucketWater", pb.merged({"cast_shadow": false}))
	var arc := []
	for k in 13:
		var a := PI * k / 12
		arc.append(Vector3(-cos(a) * r * 1.02, h - 0.03 + sin(a) * r * 0.35, sin(a) * r * 0.6))
	_put(b, ModelKit.tube(arc, 0.0035, 0.0, 5, false), base, "metal", c8(0x8a8a86), parent, "BucketHandle", pb.merged({"cast_shadow": false}))


static func _oval(rx: float, ry: float, n: int) -> Array:
	var pts := []
	for k in n + 1:
		var a := TAU * k / n
		pts.append(Vector3(cos(a) * rx, sin(a) * ry, 0))
	return pts


## A hanging curtain, gathered into soft folds, hung from a0 to a1 along x
## (axis "x", in the plane z = fixed) or along z (axis "z", x = fixed).
static func curtain(b: LevelBuilder, a0: float, a1: float, y0: float, y1: float, fixed: float, axis: String, col: Color, parent: String) -> void:
	var width := absf(a1 - a0)
	var folds := maxi(2, roundi(width / 0.16))
	var mesh := ModelKit.drape(width, y1 - y0, folds, 0.018, 0.006)
	var mid := (a0 + a1) * 0.5
	var pos := Vector3(mid, y1, fixed) if axis == "x" else Vector3(fixed, y1, mid)
	ModelKit.place(b, mesh, pos, "fabric", col, {"parent": parent, "name": "CurtainFold", "rotation": Vector3(0, 0.0 if axis == "x" else PI / 2, 0)})
