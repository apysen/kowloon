class_name ObjectKit
extends RefCounted

## Everyday things, modelled: crockery and flasks, slippers and coats,
## padlocks and taps, a dentist's chair, a sewing machine, a cannon. Each
## takes the place of a box or a cylinder that only stood in for it, and
## keeps that stand-in's name, so quests and tests find it as before.

static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func _put(b: LevelBuilder, mesh: Mesh, pos: Vector3, surface: String, tint: Color, parent: String, part: String, extra := {}) -> MeshInstance3D:
	var o := {"parent": parent, "name": part}
	o.merge(extra, true)
	return ModelKit.place(b, mesh, pos, surface, tint, o)


static func _yaw(dir: Vector3) -> float:
	return atan2(dir.x, dir.z)


# ----------------------------------------------------------------------------- crockery


## A rice bowl standing on `base`, r its rim radius; `filled` heaps rice in it.
static func rice_bowl(b: LevelBuilder, base: Vector3, r: float, col: Color, parent: String, part := "RiceBowl", filled := false, extra := {}) -> MeshInstance3D:
	var mi := _put(b, PropKit._rice_bowl(r), base, "glaze", col, parent, part, extra)
	# a blue band under the rim, the common pattern
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(r * 0.955, r * 0.85 * 0.86), Vector2(r * 0.99, r * 0.85 * 0.95)]), 24), base, "glaze", c8(0x3a5a9a), parent, part + "Band", {"cast_shadow": false}.merged(extra))
	if filled:
		_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, r * 0.6), Vector2(r * 0.9, r * 0.66), Vector2(r * 0.6, r * 0.85), Vector2(0, r * 0.95)]), 20), base, "fabric", c8(0xf2efe6), parent, part + "Rice", {"cast_shadow": false}.merged(extra))
	return mi


## A pair of chopsticks laid side by side from `a` along `dir`.
static func chopsticks(b: LevelBuilder, a: Vector3, dir: Vector3, length: float, col: Color, parent: String, extra := {}) -> void:
	var d := dir.normalized()
	var side := d.cross(Vector3.UP).normalized()
	var stick := ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.0035, 0), Vector2(0.0022, length), Vector2(0, length)]), 6)
	for s in [-1.0, 1.0]:
		var basis := Basis.looking_at(d, Vector3.UP) * Basis(Vector3.RIGHT, -PI / 2)
		_put(b, stick, a + side * s * 0.007 + Vector3(0, 0.0035, 0), "timber", col, parent, "Chopsticks", {"basis": basis, "cast_shadow": false}.merged(extra))


## A small plate or saucer, r across, on `base`.
static func plate(b: LevelBuilder, base: Vector3, r: float, col: Color, parent: String, part := "Plate", extra := {}) -> MeshInstance3D:
	return _put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0.003), Vector2(r * 0.55, 0.003), Vector2(r * 0.55, 0), Vector2(r * 0.62, 0), Vector2(r * 0.7, 0.008),
		Vector2(r, 0.016), Vector2(r * 0.97, 0.019), Vector2(r * 0.68, 0.011), Vector2(0, 0.009)]), 28), base, "glaze", col, parent, part, extra)


## A teacup with a handle (or a handleless Chinese cup with `handle` false), tea in it.
static func cup(b: LevelBuilder, base: Vector3, r: float, h: float, col: Color, parent: String, part := "Cup", handle := true, facing := Vector3(1, 0, 0), extra := {}) -> MeshInstance3D:
	var mi := _put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0.004), Vector2(r * 0.6, 0.004), Vector2(r * 0.6, 0), Vector2(r * 0.7, 0), Vector2(r * 0.9, h * 0.3),
		Vector2(r, h), Vector2(r * 0.92, h), Vector2(r * 0.82, h * 0.3), Vector2(0, h * 0.1)]), 24), base, "glaze", col, parent, part, extra)
	_put(b, ModelKit.puck(r * 0.88, 0.002, 0.0005, 20), base + Vector3(0, h * 0.78, 0), "fabric", c8(0x7a4a1c), parent, part + "Tea", {"cast_shadow": false}.merged(extra))
	if handle:
		var f := Vector3(facing.x, 0, facing.z).normalized()
		var arc := []
		for k in 9:
			var a := PI * k / 8
			arc.append(f * (r * 0.92 + sin(a) * r * 0.55) + Vector3(0, h * 0.78 - (1 - cos(a)) * h * 0.28, 0))
		_put(b, ModelKit.tube(arc, r * 0.12, 0.0, 6), base, "glaze", col, parent, part + "Handle", {"cast_shadow": false}.merged(extra))
	return mi


## The Chinese vacuum flask on every table: a tin body printed with flowers,
## a chrome shoulder and foot, a cup-cap, a wire handle on one side.
static func thermos(b: LevelBuilder, base: Vector3, r: float, h: float, col: Color, parent: String, part := "Thermos", extra := {}) -> MeshInstance3D:
	var mi := _put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0.0), Vector2(r, 0.0), Vector2(r, h * 0.78), Vector2(r * 0.72, h * 0.86), Vector2(0, h * 0.86)], r * 0.25), 24),
		base, "metal", col, parent, part, extra)
	# chrome foot ring and shoulder collar
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(r * 1.03, 0.0), Vector2(r * 1.03, h * 0.07), Vector2(r * 0.99, h * 0.075)]), 24), base, "metal", c8(0xd8dcdc), parent, part + "Foot", {"cast_shadow": false}.merged(extra))
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(r * 0.74, h * 0.84), Vector2(r * 0.76, h * 0.88), Vector2(r * 0.56, h * 0.9)]), 20), base, "metal", c8(0xd8dcdc), parent, part + "Collar", {"cast_shadow": false}.merged(extra))
	# the cap, which is also the cup
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, h * 0.88), Vector2(r * 0.56, h * 0.88), Vector2(r * 0.6, h), Vector2(0, h)], r * 0.08), 20), base, "metal", col.darkened(0.25), parent, part + "Cap", extra)
	# the printed tin band of peonies wrapped round the middle
	var band := CylinderMesh.new()
	band.top_radius = r * 1.004
	band.bottom_radius = r * 1.004
	band.height = h * 0.3
	band.radial_segments = 32
	band.rings = 1
	band.cap_top = false
	band.cap_bottom = false
	b.piece(band, base + Vector3(0, h * 0.42, 0), b.card_material("res://assets/textures/props/thermos_band.png"), {"parent": parent, "name": part + "Band", "cast_shadow": false}.merged(extra))
	# the handle: a wire loop down one side
	var hz := Vector3(1, 0, 0)
	_put(b, ModelKit.tube([hz * r * 0.98 + Vector3(0, h * 0.72, 0), hz * r * 1.35 + Vector3(0, h * 0.66, 0), hz * r * 1.35 + Vector3(0, h * 0.25, 0), hz * r * 0.98 + Vector3(0, h * 0.18, 0)], r * 0.06, r * 0.3, 6),
		base, "metal", c8(0x9aa0a0), parent, part + "Handle", {"cast_shadow": false}.merged(extra))
	return mi


## An aluminium cooking pot with two handles and a lid.
static func pot(b: LevelBuilder, base: Vector3, r: float, h: float, col: Color, parent: String, part := "Pot", extra := {}) -> MeshInstance3D:
	var mi := _put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(r * 0.96, 0), Vector2(r, h * 0.92), Vector2(r * 1.04, h), Vector2(r * 0.97, h), Vector2(r * 0.93, h * 0.1), Vector2(0, h * 0.06)], 0.01), 28),
		base, "metal", col, parent, part, extra)
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(r * 1.02, 0), Vector2(r * 0.8, h * 0.12), Vector2(r * 0.2, h * 0.16), Vector2(0, h * 0.17)]), 28), base + Vector3(0, h * 0.98, 0), "metal", col.lightened(0.08), parent, part + "Lid", extra)
	_put(b, ModelKit.tube([Vector3(-0.025, 0, 0), Vector3(-0.02, 0.025, 0), Vector3(0.02, 0.025, 0), Vector3(0.025, 0, 0)], 0.006, 0.01, 6), base + Vector3(0, h * 1.14, 0), "grain", c8(0x2a2420), parent, part + "Knob", extra)
	for s in [-1.0, 1.0]:
		_put(b, ModelKit.tube([Vector3(s * r * 0.98, h * 0.8, -0.03), Vector3(s * (r + 0.035), h * 0.82, -0.03), Vector3(s * (r + 0.035), h * 0.82, 0.03), Vector3(s * r * 0.98, h * 0.8, 0.03)], 0.006, 0.012, 6),
			base, "metal", col.darkened(0.15), parent, part + "Handle", {"cast_shadow": false}.merged(extra))
	return mi


# ----------------------------------------------------------------------------- clothes and the door


## A pair of plastic slippers in the footprint (x0..x1, z0..z1), toes toward `toward`.
static func slippers(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, col: Color, parent: String, toward := Vector3(1, 0, 0)) -> void:
	var c := Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5)
	var f := Vector3(toward.x, 0, toward.z).normalized()
	var side := f.cross(Vector3.UP).normalized()
	var length := minf(0.26, maxf(x1 - x0, z1 - z0) * 0.9)
	# the sole: a footprint, wider at the ball, round at the heel
	var sole := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24
		var t := sin(a)                     # -1 heel .. 1 toe
		var w := 0.038 + 0.012 * (t + 1) * 0.5
		sole.append(Vector2(cos(a) * w, t * length * 0.5))
	var sole_mesh := ModelKit.slab(sole, 0.018, 0.004)
	var strap := ModelKit.tube([Vector3(-0.042, 0.009, 0), Vector3(-0.034, 0.035, 0), Vector3(0.034, 0.035, 0), Vector3(0.042, 0.009, 0)], 0.016, 0.02, 8, false)
	for k in 2:
		var s := -1.0 if k == 0 else 1.0
		var at := c + side * s * 0.06 + f * (0.015 if k == 0 else -0.01)
		var yaw := _yaw(f) + (0.08 if k == 0 else -0.12)
		# lay the slab down: its y (heel to toe) along the floor, its depth up
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI / 2)
		_put(b, sole_mesh, at + Vector3(0, 0.009, 0), "grain", col, parent, "Slippers", {"basis": basis, "cast_shadow": false})
		_put(b, strap, at + f * length * 0.12, "grain", col.lightened(0.15), parent, "SlipperStrap", {"rotation": Vector3(0, yaw - PI / 2, 0), "cast_shadow": false})


## A coat hung by its loop from a hook on a wall at x = wall_x, facing +x or -x.
static func coat(b: LevelBuilder, wall_x: float, out: float, y_top: float, y_bot: float, z0: float, z1: float, col: Color, parent: String) -> void:
	var w := absf(z1 - z0)
	var h := y_top - y_bot
	var cz := (z0 + z1) * 0.5
	# hung from its loop the shoulders drop, the body hangs straight, the hem flares a little
	var shape := PackedVector2Array([Vector2(-0.03, 0.0), Vector2(0.03, 0.0), Vector2(w * 0.45, -0.07), Vector2(w * 0.5, -0.14), Vector2(w * 0.46, -h * 0.5),
		Vector2(w * 0.54, -h), Vector2(-w * 0.54, -h), Vector2(-w * 0.46, -h * 0.5), Vector2(-w * 0.5, -0.14), Vector2(-w * 0.45, -0.07)])
	var face := Basis(Vector3.UP, PI / 2 if out > 0 else -PI / 2)
	var at := Vector3(wall_x + out * 0.035, y_top - 0.02, cz)
	_put(b, ModelKit.slab(shape, 0.05, 0.016), at, "fabric", col, parent, "Coat", {"basis": face})
	# the collar turned down, the lapels
	var collar := PackedVector2Array([Vector2(-0.07, 0.0), Vector2(0.07, 0.0), Vector2(0.09, -0.06), Vector2(0.03, -0.16), Vector2(0.0, -0.1), Vector2(-0.03, -0.16), Vector2(-0.09, -0.06)])
	_put(b, ModelKit.slab(collar, 0.014, 0.004), at + Vector3(out * 0.03, -0.01, 0), "fabric", col.darkened(0.15), parent, "CoatCollar", {"basis": face, "cast_shadow": false})
	# buttons down the front
	for k in 4:
		_put(b, ModelKit.puck(0.011, 0.006, 0.002, 10), at + Vector3(out * 0.027, -0.24 - k * h * 0.17, 0.0), "grain", c8(0x2a2420), parent, "CoatButton", {"rotation": Vector3(0, 0, -PI / 2 * out), "cast_shadow": false})
	# the sleeves fall straight down the sides, a little in front
	for s in [-1.0, 1.0]:
		_put(b, ModelKit.tube([Vector3(0, 0, 0), Vector3(0, -h * 0.3, s * 0.01), Vector3(out * 0.01, -h * 0.66, 0.0)], 0.038, 0.12, 12), at + Vector3(out * 0.03, -0.1, s * w * 0.38),
			"fabric", col.darkened(0.06), parent, "CoatSleeve")
	# a pocket flap
	_put(b, ModelKit.rbox(Vector3(0.01, 0.03, w * 0.3), 0.004), at + Vector3(out * 0.027, -h * 0.6, -w * 0.18), "fabric", col.darkened(0.12), parent, "CoatPocket", {"cast_shadow": false})
	_put(b, ModelKit.tube([Vector3(0, 0, -0.03), Vector3(0, 0.03, 0), Vector3(0, 0, 0.03)], 0.004, 0.01, 5), Vector3(wall_x + out * 0.03, y_top, cz), "metal", c8(0x8a8a86), parent, "Hook", {"cast_shadow": false})


## A cloth shoulder bag hanging flat against a wall at x = wall_x by its strap.
static func bag(b: LevelBuilder, wall_x: float, out: float, y0: float, y1: float, z0: float, z1: float, col: Color, parent: String) -> void:
	var w := absf(z1 - z0)
	var hgt := (y1 - y0) * 0.6
	_put(b, ModelKit.cushion(Vector3(0.08, hgt, w), 0.03, 0.0, 0.015), Vector3(wall_x + out * 0.045, y0 + hgt * 0.5, (z0 + z1) * 0.5), "fabric", col, parent, "Bag")
	_put(b, ModelKit.rbox(Vector3(0.02, hgt * 0.45, w * 1.02), 0.008), Vector3(wall_x + out * 0.088, y0 + hgt * 0.75, (z0 + z1) * 0.5), "fabric", col.darkened(0.12), parent, "BagFlap")
	_put(b, ModelKit.tube([Vector3(0, hgt, -w * 0.42), Vector3(0, y1 - y0 - 0.02, -0.02), Vector3(0, y1 - y0 - 0.02, 0.02), Vector3(0, hgt, w * 0.42)], 0.008, 0.03, 6),
		Vector3(wall_x + out * 0.03, y0, (z0 + z1) * 0.5), "fabric", col.darkened(0.25), parent, "BagStrap", {"cast_shadow": false})


## A brass padlock hanging at `center`, its face toward `facing`.
static func padlock(b: LevelBuilder, center: Vector3, facing: Vector3, parent: String, size := 1.0, extra := {}) -> MeshInstance3D:
	var f := Vector3(facing.x, 0, facing.z).normalized()
	var yaw := _yaw(f)
	var body := _put(b, ModelKit.rbox(Vector3(0.1, 0.085, 0.032) * size, 0.012 * size), center, "metal", c8(0xc9a55a), parent, "Padlock", {"rotation": Vector3(0, yaw, 0)}.merged(extra))
	var shackle := []
	for k in 11:
		var a := PI * k / 10
		shackle.append(Vector3(-cos(a) * 0.033, 0.03 + sin(a) * 0.045, 0) * size)
	_put(b, ModelKit.tube(shackle, 0.0075 * size, 0.0, 8), center, "metal", c8(0xc8ccc8), parent, "Shackle", {"rotation": Vector3(0, yaw, 0), "cast_shadow": false}.merged(extra))
	_put(b, ModelKit.puck(0.009 * size, 0.003, 0.001, 10), center + f * 0.016 * size + Vector3(0, -0.012, 0) * size, "metal", c8(0x2a2620), parent, "Keyhole", {"basis": Basis.looking_at(-f, Vector3.UP) * Basis(Vector3.RIGHT, PI / 2), "cast_shadow": false}.merged(extra))
	return body


## A brass pillar tap on a wall-pipe end: the body, a cross handle on top, a
## spout curving down. `at` is the body's top; `spout_dir` its way out.
static func tap(b: LevelBuilder, at: Vector3, spout_dir: Vector3, handle_col: Color, parent: String, extra := {}) -> void:
	var d := Vector3(spout_dir.x, 0, spout_dir.z).normalized()
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, -0.08), Vector2(0.024, -0.08), Vector2(0.03, -0.05), Vector2(0.022, -0.02), Vector2(0.014, 0.0), Vector2(0, 0.0)], 0.006), 14),
		at, "metal", c8(0xb8a060), parent, "Tap", extra)
	_put(b, ModelKit.tube([Vector3(0, -0.05, 0), d * 0.05 + Vector3(0, -0.05, 0), d * 0.075 + Vector3(0, -0.075, 0), d * 0.075 + Vector3(0, -0.1, 0)], 0.009, 0.015, 8), at, "metal", c8(0xb8a060), parent, "TapSpout", {"cast_shadow": false}.merged(extra))
	_put(b, ModelKit.puck(0.006, 0.02, 0.002, 8), at, "metal", c8(0xb8a060), parent, "TapSpindle", {"cast_shadow": false}.merged(extra))
	for k in 2:
		var a := PI / 2 * k
		var arm := Vector3(cos(a), 0, sin(a)) * 0.032
		_put(b, ModelKit.tube([-arm, arm], 0.006, 0.0, 6), at + Vector3(0, 0.022, 0), "metal", handle_col, parent, "TapHandle", {"cast_shadow": false}.merged(extra))


## A round wall clock on a wall, its face toward `facing`.
static func wall_clock(b: LevelBuilder, center: Vector3, facing: Vector3, r: float, col: Color, parent: String) -> void:
	var f := Vector3(facing.x, 0, facing.z).normalized()
	var stand := Basis.looking_at(-f, Vector3.UP) * Basis(Vector3.RIGHT, PI / 2)
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(r, 0), Vector2(r * 1.02, 0.03), Vector2(r * 0.9, 0.045), Vector2(r * 0.88, 0.03), Vector2(0, 0.03)], 0.008), 32),
		center - f * 0.045, "timber", col, parent, "Clock", {"basis": stand})
	b.card("res://assets/textures/props/clock_face.png", center - f * 0.013, Vector2(r * 1.76, r * 1.76), f, {"parent": parent, "name": "ClockFace", "band": 0.0})
	# the hands: ten past ten, the way clocks are always photographed, and this one stopped
	for hand in [[0.55, -1.0 / 3.0], [0.8, 1.0 / 3.0]]:
		var a: float = hand[1] * PI
		var tip: Vector3 = Vector3(0, cos(a), 0) * r * hand[0] + Vector3.UP.cross(f).normalized() * sin(a) * r * hand[0]
		_put(b, ModelKit.tube([Vector3.ZERO, tip], 0.004, 0.0, 5), center + f * 0.003, "metal", c8(0x1a1a1a), parent, "ClockHand", {"cast_shadow": false})
	_put(b, ModelKit.puck(0.008, 0.006, 0.002, 10), center - f * 0.004, "metal", c8(0xc9a55a), parent, "ClockPin", {"basis": stand, "cast_shadow": false})


# ----------------------------------------------------------------------------- kitchen and work


## A round chopping block, a section of tree with its bark on, at `base`.
static func chopping_block(b: LevelBuilder, base: Vector3, r: float, h: float, parent: String) -> void:
	_put(b, ModelKit.puck(r, h, 0.006, 28), base, "timber", c8(0xc9a270), parent, "ChoppingBlock")
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(r * 1.02, 0.004), Vector2(r * 1.05, h * 0.5), Vector2(r * 1.02, h - 0.004)]), 28), base, "concrete", c8(0x5a3e28), parent, "Bark", {"cast_shadow": false})
	# the top worn into a dish, scored by years of the cleaver
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, h + 0.0005), Vector2(r * 0.85, h + 0.0005)]), 28), base, "timber", c8(0xb08a5a), parent, "BlockTop", {"cast_shadow": false})


## A Chinese cleaver lying flat: a broad steel blade and a round wooden handle.
static func cleaver(b: LevelBuilder, base: Vector3, toward: Vector3, parent: String) -> void:
	var f := Vector3(toward.x, 0, toward.z).normalized()
	var yaw := _yaw(f)
	var blade := ModelKit.slab(PackedVector2Array([Vector2(-0.05, -0.1), Vector2(0.05, -0.1), Vector2(0.052, 0.09), Vector2(0.04, 0.1), Vector2(-0.05, 0.1)]), 0.004, 0.0012)
	var lay := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI / 2)
	_put(b, blade, base + Vector3(0, 0.003, 0), "metal", c8(0x8a9094), parent, "Cleaver", {"basis": lay, "cast_shadow": false})
	# the honed edge, bright along the blade's foot
	_put(b, ModelKit.rbox(Vector3(0.004, 0.0045, 0.19), 0.001), base + Vector3(0, 0.003, 0) + Vector3.UP.cross(f).normalized() * 0.05, "metal", c8(0xe8ecec), parent, "CleaverEdge",
		{"rotation": Vector3(0, yaw, 0), "cast_shadow": false})
	_put(b, ModelKit.tube([Vector3.ZERO, f * 0.12], 0.013, 0.0, 10), base + Vector3(0, 0.013, 0) - f * 0.1 + f.cross(Vector3.UP) * 0.0, "timber", c8(0x4a2a18), parent, "CleaverHandle")


## A bunch of choi sum: stems, leaves, a few yellow flowers.
static func greens(b: LevelBuilder, base: Vector3, toward: Vector3, parent: String) -> void:
	var f := Vector3(toward.x, 0, toward.z).normalized()
	var side := f.cross(Vector3.UP).normalized()
	var r := PropKit._rng(base)
	var outline := PackedVector2Array()
	for k in 21:
		var t := float(k) / 20.0                       # base 0 .. tip 1
		outline.append(Vector2(sin(t * PI) * 0.034 * (1.0 - t * 0.35), t * 0.16))
	for k in range(19, 0, -1):
		var t := float(k) / 20.0
		outline.append(Vector2(-sin(t * PI) * 0.034 * (1.0 - t * 0.35), t * 0.16))
	var leaf := ModelKit.slab(outline, 0.003, 0.001)
	for k in 6:
		var off := side * r.randf_range(-0.03, 0.03) + Vector3(0, 0.008 + k * 0.004, 0)
		var dir := (f + side * r.randf_range(-0.15, 0.15)).normalized()
		_put(b, ModelKit.tube([Vector3.ZERO, dir * 0.12], 0.006, 0.0, 6), base + off, "fabric", c8(0xb8d0a0), parent, "Greens")
		var lay := Basis(Vector3.UP, _yaw(dir)) * Basis(Vector3.RIGHT, PI / 2 - 0.15)
		_put(b, leaf, base + off + dir * 0.1 + Vector3(0, 0.006, 0), "fabric", c8(0x4f8a3a).lerp(c8(0x6fa04a), r.randf()), parent, "Leaf", {"basis": lay})
		_put(b, ModelKit.tube([Vector3.ZERO, Vector3(0, 0, 0.1)], 0.0015, 0.0, 4), base + off + dir * 0.12 + Vector3(0, 0.009, 0), "fabric", c8(0xd8e8c0), parent, "Midrib",
			{"rotation": Vector3(0, _yaw(dir), 0), "cast_shadow": false})
		if k % 2 == 0:
			for j in 3:
				b.piece(PropKit._sphere(0.006), base + off + dir * (0.24 + j * 0.008) + side * (j - 1) * 0.008 + Vector3(0, 0.012, 0), b.surface("fabric"), {"parent": parent, "name": "Flower", "tint": c8(0xe8c840), "cast_shadow": false})
	# the bunch tied with a red rubber band round the stems
	_put(b, ModelKit.tube(PropKit._oval(0.04, 0.02, 14), 0.003, 0.0, 5, false), base + f * 0.05 + Vector3(0, 0.016, 0), "grain", c8(0xc0392b), parent, "Band",
		{"basis": Basis(Vector3.UP, _yaw(f)), "cast_shadow": false})


## A stack of bamboo steamer baskets with a domed lid, on `base`.
static func steamer(b: LevelBuilder, base: Vector3, r: float, tiers: int, parent: String, part := "Steamer") -> void:
	var weave := b.card_material("res://assets/textures/props/bamboo_weave.png")
	var wall := CylinderMesh.new()
	wall.top_radius = r
	wall.bottom_radius = r
	wall.height = 0.1
	wall.radial_segments = 40
	wall.rings = 1
	wall.cap_top = false
	wall.cap_bottom = false
	# the inside of the basket: the slatted floor
	var floor_ := ModelKit.lathe(PackedVector2Array([Vector2(0, 0.01), Vector2(r * 0.97, 0.01)]), 32)
	var rim := ModelKit.lathe(ModelKit.rounded_profile([Vector2(r * 0.96, 0.0), Vector2(r * 1.03, 0.0), Vector2(r * 1.03, 0.022), Vector2(r * 0.96, 0.022)], 0.006), 40)
	for k in tiers:
		var y0 := base + Vector3(0, k * 0.13, 0)
		b.piece(wall, y0 + Vector3(0, 0.065, 0), weave, {"parent": parent, "name": part})
		_put(b, floor_, y0, "timber", c8(0xb8945a), parent, part + "Floor", {"cast_shadow": false})
		_put(b, rim, y0, "timber", c8(0x8a6a3a), parent, part + "Band")
		_put(b, rim, y0 + Vector3(0, 0.108, 0), "timber", c8(0x8a6a3a), parent, part + "Band")
	var top := base + Vector3(0, tiers * 0.13, 0)
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(r * 1.04, 0), Vector2(r * 0.98, 0.04), Vector2(r * 0.6, 0.075), Vector2(0, 0.085)]), 40), top, "fabric", c8(0xc9a55a), parent, part + "Lid")
	_put(b, rim, top, "timber", c8(0x8a6a3a), parent, part + "Band")
	_put(b, ModelKit.tube([Vector3(-0.04, 0.083, 0), Vector3(-0.03, 0.105, 0), Vector3(0.03, 0.105, 0), Vector3(0.04, 0.083, 0)], 0.006, 0.01, 6), top, "timber", c8(0x8a6a3a), parent, part + "Knob")


## An oil drum, ribbed, its lid rim rolled, a bung in the top.
static func oil_drum(b: LevelBuilder, base: Vector3, r: float, h: float, col: Color, parent: String, extra := {}) -> void:
	var prof := PackedVector2Array([Vector2(0, 0.01), Vector2(r * 0.97, 0.01), Vector2(r, 0.0), Vector2(r * 1.02, 0.02), Vector2(r, 0.04)])
	for rib in [0.33, 0.66]:
		prof.append(Vector2(r, h * rib - 0.025))
		prof.append(Vector2(r * 1.025, h * rib))
		prof.append(Vector2(r, h * rib + 0.025))
	prof.append_array(PackedVector2Array([Vector2(r, h - 0.04), Vector2(r * 1.02, h - 0.02), Vector2(r, h), Vector2(r * 0.97, h - 0.01), Vector2(0, h - 0.01)]))
	_put(b, ModelKit.lathe(prof, 32), base, "rust", col, parent, "OilDrum", extra)
	_put(b, ModelKit.puck(0.03, 0.012, 0.003, 12), base + Vector3(r * 0.55, h - 0.01, 0), "metal", col.darkened(0.3), parent, "Bung", {"cast_shadow": false}.merged(extra))


## A wide plastic tub on `base`, its rim rolled, `fill` (0..1) of something in it.
static func tub(b: LevelBuilder, base: Vector3, r: float, h: float, col: Color, fill_col: Color, fill: float, parent: String, part := "Tub", fill_part := "Paste") -> void:
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(r * 0.82, 0), Vector2(r, h), Vector2(r * 1.05, h), Vector2(r * 1.05, h - 0.02), Vector2(r * 0.97, h - 0.015),
		Vector2(r * 0.8, 0.012), Vector2(0, 0.012)]), 32), base, "grain", col, parent, part)
	var fy := 0.012 + (h - 0.03) * fill
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, fy + 0.01), Vector2(r * (0.8 + 0.17 * fill) * 0.99, fy)]), 28), base, "fabric", fill_col, parent, fill_part, {"cast_shadow": false})


# ----------------------------------------------------------------------------- furniture pieces


## A plain timber chair: seat, a back of two rails on its rear posts, four
## legs and stretchers. It faces `facing`; (cx, cz) is the middle of the seat.
static func chair(b: LevelBuilder, cx: float, cz: float, y: float, facing: Vector3, col: Color, parent: String, extra := {}) -> void:
	var f := Vector3(facing.x, 0, facing.z).normalized()
	var root := Node3D.new()
	root.name = "Chair"
	root.position = Vector3(cx, y, cz)
	root.rotation.y = _yaw(f)
	b.attach(root, b.group(parent))
	b.tag(root, extra.get("band", b.band_of(y + 0.5)))
	var o := {"parent_node": root, "radius": 0.006}
	o.merge(extra, true)
	o.erase("band")
	var seat := 0.45
	ModelKit.box(b, -0.23, 0.23, seat - 0.035, seat, -0.22, 0.22, col, o.merged({"surface": "timber", "name": "ChairSeat", "radius": 0.012}))
	for sx in [-1.0, 1.0]:
		ModelKit.box(b, sx * 0.2 - 0.02, sx * 0.2 + 0.02, 0, seat - 0.035, 0.16, 0.2, col.darkened(0.2), o.merged({"surface": "timber", "name": "ChairLeg"}))
		ModelKit.box(b, sx * 0.2 - 0.02, sx * 0.2 + 0.02, 0, 1.0, -0.2, -0.16, col.darkened(0.15), o.merged({"surface": "timber", "name": "ChairBack"}))
		ModelKit.box(b, sx * 0.2 - 0.012, sx * 0.2 + 0.012, 0.12, 0.15, -0.16, 0.16, col.darkened(0.25), o.merged({"surface": "timber", "name": "Stretcher", "cast_shadow": false}))
	for ry in [0.68, 0.9]:
		ModelKit.box(b, -0.18, 0.18, ry, ry + 0.06, -0.195, -0.17, col.darkened(0.1), o.merged({"surface": "timber", "name": "ChairBack", "radius": 0.008}))
	ModelKit.box(b, -0.18, 0.18, 0.12, 0.15, 0.17, 0.19, col.darkened(0.25), o.merged({"surface": "timber", "name": "Stretcher", "cast_shadow": false}))


## A folding steel chair, painted, set up and facing `facing`.
static func folding_chair(b: LevelBuilder, cx: float, cz: float, y: float, facing: Vector3, col: Color, parent: String, band: float) -> void:
	var f := Vector3(facing.x, 0, facing.z).normalized()
	var root := Node3D.new()
	root.name = "FoldingChair"
	root.position = Vector3(cx, y, cz)
	root.rotation.y = _yaw(f)
	b.attach(root, b.group(parent))
	b.tag(root, band)
	var steel := c8(0x5a5a58)
	for sx in [-1.0, 1.0]:
		# the back legs run up into the back's frame; the front legs cross under the seat
		ModelKit.place(b, ModelKit.tube([Vector3(sx * 0.2, 0, -0.2), Vector3(sx * 0.2, 0.44, -0.17), Vector3(sx * 0.2, 0.95, -0.2)], 0.012, 0.05, 8), Vector3.ZERO, "metal", steel, {"parent_node": root, "name": "ChairLeg"})
		ModelKit.place(b, ModelKit.tube([Vector3(sx * 0.19, 0, 0.2), Vector3(sx * 0.19, 0.44, -0.05)], 0.011, 0.0, 8), Vector3.ZERO, "metal", steel, {"parent_node": root, "name": "ChairLeg", "cast_shadow": false})
		ModelKit.place(b, ModelKit.puck(0.016, 0.012, 0.004, 8), Vector3(sx * 0.2, 0, -0.2), "grain", c8(0x1a1a1a), {"parent_node": root, "name": "Foot", "cast_shadow": false})
		ModelKit.place(b, ModelKit.puck(0.016, 0.012, 0.004, 8), Vector3(sx * 0.19, 0, 0.2), "grain", c8(0x1a1a1a), {"parent_node": root, "name": "Foot", "cast_shadow": false})
	ModelKit.box(b, -0.22, 0.22, 0.44, 0.47, -0.2, 0.2, col, {"parent_node": root, "surface": "metal", "name": "ChairSeat", "radius": 0.012})
	ModelKit.box(b, -0.2, 0.2, 0.72, 0.93, -0.215, -0.19, col, {"parent_node": root, "surface": "metal", "name": "ChairBack", "radius": 0.01})


## A wardrobe: a carcass on short feet with a cornice, two panelled doors,
## brass handles and a mirror set in one. Its doors face `facing` (one of the
## four axis directions). The body box keeps `body_opts` (collision etc.).
static func wardrobe(b: LevelBuilder, x0: float, x1: float, y: float, h: float, z0: float, z1: float, facing: Vector3, col: Color, parent: String, body_opts := {}) -> void:
	var o := {"surface": "timber", "parent": parent, "name": "Wardrobe", "radius": 0.012}
	o.merge(body_opts, true)
	b.box(x0, x1, y + 0.08, y + h - 0.06, z0, z1, col, o)
	var bd: float = body_opts.get("band", b.band_of(y + 0.5))
	var po := {"parent": parent, "band": bd}
	ModelKit.box(b, x0 - 0.03, x1 + 0.03, y + h - 0.06, y + h, z0 - 0.03, z1 + 0.03, col.darkened(0.1), po.merged({"surface": "timber", "name": "Cornice", "radius": 0.012}))
	for fx in [x0 + 0.04, x1 - 0.1]:
		for fz in [z0 + 0.04, z1 - 0.1]:
			ModelKit.box(b, fx, fx + 0.06, y, y + 0.08, fz, fz + 0.06, col.darkened(0.25), po.merged({"surface": "timber", "name": "Foot", "radius": 0.01}))
	# the doors on the facing side
	var along_z := absf(facing.x) > 0.5
	var lo := z0 if along_z else x0
	var hi := z1 if along_z else x1
	var face := (x1 if facing.x > 0 else x0) if along_z else (z1 if facing.z > 0 else z0)
	var s := signf(facing.x if along_z else facing.z)
	var mid := (lo + hi) * 0.5
	for k in 2:
		var a := lo + 0.03 if k == 0 else mid + 0.006
		var c := mid - 0.006 if k == 0 else hi - 0.03
		var d0 := face
		var d1 := face + s * 0.02
		var door_box := [minf(d0, d1), maxf(d0, d1)]
		var panel_box := [minf(d1, d1 + s * 0.008), maxf(d1, d1 + s * 0.008)]
		if along_z:
			ModelKit.box(b, door_box[0], door_box[1], y + 0.14, y + h - 0.1, a, c, col.lightened(0.05), po.merged({"surface": "timber", "name": "WardrobeDoor", "radius": 0.006, "cast_shadow": false}))
		else:
			ModelKit.box(b, a, c, y + 0.14, y + h - 0.1, door_box[0], door_box[1], col.lightened(0.05), po.merged({"surface": "timber", "name": "WardrobeDoor", "radius": 0.006, "cast_shadow": false}))
		# a raised panel low, and high a mirror on the left door, a panel on the right
		for pnl in [[y + 0.22, y + h * 0.42], [y + h * 0.48, y + h - 0.18]]:
			var mirror: bool = k == 0 and pnl[0] > y + 0.3
			var pc := c8(0x6a7a80) if mirror else col.lightened(0.1)
			var surf := "glaze" if mirror else "timber"
			if along_z:
				ModelKit.box(b, panel_box[0], panel_box[1], pnl[0], pnl[1], a + 0.06, c - 0.06, pc, po.merged({"surface": surf, "name": "WardrobeMirror" if mirror else "WardrobePanel", "radius": 0.005, "cast_shadow": false}))
			else:
				ModelKit.box(b, a + 0.06, c - 0.06, pnl[0], pnl[1], panel_box[0], panel_box[1], pc, po.merged({"surface": surf, "name": "WardrobeMirror" if mirror else "WardrobePanel", "radius": 0.005, "cast_shadow": false}))
		var hp := mid - 0.04 if k == 0 else mid + 0.04
		var hpos := Vector3(face + s * 0.035, y + h * 0.5, hp) if along_z else Vector3(hp, y + h * 0.5, face + s * 0.035)
		_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, -0.04), Vector2(0.008, -0.04), Vector2(0.006, 0.04), Vector2(0, 0.04)], 0.004), 8), hpos, "metal", c8(0xc9a55a), parent, "WardrobeHandle", {"band": bd, "cast_shadow": false})


## A dentist's chair: a chromed pedestal, an upholstered seat and back and
## headrest, arms, and a foot rest. (x0..x1, z0..z1) is its footprint, the
## back at x0 and the patient looking toward +x.
static func dental_chair(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, parent: String) -> void:
	var cz := (z0 + z1) * 0.5
	var w := z1 - z0
	var vinyl := c8(0x3f7a78)
	var chrome := c8(0xd8d6cc)
	var cx := (x0 + x1) * 0.5
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.36, 0), Vector2(0.36, 0.04), Vector2(0.12, 0.08), Vector2(0.09, 0.35), Vector2(0, 0.35)], 0.03), 32, Vector2(1.0, 0.85)),
		Vector3(cx + 0.05, y, cz), "metal", c8(0xb8b6ac), parent, "ChairBase")
	ModelKit.box(b, x0 + 0.15, x1 - 0.05, y + 0.35, y + 0.47, cz - 0.24, cz + 0.24, chrome, {"surface": "metal", "parent": parent, "name": "ChairPlinth", "radius": 0.03})
	# the seat running out into a foot rest, the back reclined, the headrest on a stem
	_put(b, ModelKit.cushion(Vector3(x1 - x0 - 0.38, 0.13, 0.56), 0.055, 0.02, 0.01), Vector3(x0 + 0.38 + (x1 - x0 - 0.38) * 0.5, y + 0.58, cz), "fabric", vinyl, parent, "ChairSeat")
	_put(b, ModelKit.cushion(Vector3(0.13, 0.9, 0.52), 0.055, 0.0, 0.012), Vector3(x0 + 0.3, y + 1.05, cz), "fabric", vinyl, parent, "ChairBack", {"rotation": Vector3(0, 0, 0.38)})
	_put(b, ModelKit.tube([Vector3(x0 + 0.14, y + 1.43, cz), Vector3(x0 + 0.08, y + 1.56, cz)], 0.015, 0.0, 8), Vector3.ZERO, "metal", chrome, parent, "HeadrestStem")
	_put(b, ModelKit.cushion(Vector3(0.11, 0.17, 0.3), 0.045, 0.0, 0.008), Vector3(x0 + 0.06, y + 1.6, cz), "fabric", vinyl, parent, "Headrest", {"rotation": Vector3(0, 0, 0.4)})
	for s in [-1.0, 1.0]:
		var az: float = cz + s * 0.33
		_put(b, ModelKit.tube([Vector3(x0 + 0.4, y + 0.6, az), Vector3(x0 + 0.42, y + 0.86, az), Vector3(x0 + 1.1, y + 0.86, az), Vector3(x0 + 1.12, y + 0.62, az)], 0.016, 0.05, 8),
			Vector3.ZERO, "metal", chrome, parent, "ChairArm")
		_put(b, ModelKit.cushion(Vector3(0.6, 0.04, 0.08), 0.018, 0.0, 0.0), Vector3(x0 + 0.76, y + 0.89, az), "fabric", vinyl.darkened(0.2), parent, "ArmPad")


## The dentist's lamp on its stand: a pole, a jointed arm, a reflector head
## with its glow, pointed down at `target`.
static func dental_lamp(b: LevelBuilder, foot: Vector3, top: float, head: Vector3, parent: String) -> void:
	var chrome := c8(0x9a9a98)
	_put(b, ModelKit.puck(0.2, 0.04, 0.012, 24), foot, "metal", c8(0x5a5a58), parent, "LampFoot")
	_put(b, ModelKit.tube([foot, Vector3(foot.x, top, foot.z)], 0.022, 0.0, 10), Vector3.ZERO, "metal", chrome, parent, "LampPost")
	var knee := Vector3((foot.x + head.x) * 0.5, top + 0.08, (foot.z + head.z) * 0.5)
	_put(b, ModelKit.tube([Vector3(foot.x, top, foot.z), knee, head + Vector3(0, 0.14, 0)], 0.016, 0.06, 8), Vector3.ZERO, "metal", chrome, parent, "LampArm")
	b.piece(PropKit._sphere(0.03), knee, b.surface("metal"), {"parent": parent, "name": "LampJoint", "tint": c8(0x5a5a58)})
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0.12), Vector2(0.05, 0.12), Vector2(0.17, 0.02), Vector2(0.2, 0.0), Vector2(0.19, -0.01), Vector2(0.16, 0.01), Vector2(0.04, 0.1), Vector2(0, 0.1)]), 28, Vector2(1.0, 0.7)),
		head, "metal", c8(0xe8e4d8), parent, "LampHead")
	b.piece(ModelKit.lathe(PackedVector2Array([Vector2(0, 0.012), Vector2(0.16, 0.012)]), 28, Vector2(1.0, 0.7)), head, b.emissive(Color(1, 0.97, 0.82), 6.0), {"parent": parent, "name": "LampGlow", "cast_shadow": false})


## A porcelain cuspidor on its stand, by the chair.
static func spittoon(b: LevelBuilder, base: Vector3, h: float, parent: String) -> void:
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.15, 0), Vector2(0.15, 0.03), Vector2(0.05, 0.06), Vector2(0.045, h - 0.15), Vector2(0, h - 0.15)], 0.02), 24),
		base, "metal", c8(0xc8ccc8), parent, "SpittoonStand")
	_put(b, ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.06, 0), Vector2(0.14, 0.1), Vector2(0.15, 0.15), Vector2(0.138, 0.15), Vector2(0.125, 0.11), Vector2(0.05, 0.03), Vector2(0.02, 0.025), Vector2(0, 0.025)]), 28),
		base + Vector3(0, h - 0.15, 0), "glaze", c8(0xe8ece8), parent, "Spittoon")
	# the water spout curling over the bowl
	_put(b, ModelKit.tube([Vector3(0.12, h - 0.05, 0), Vector3(0.12, h + 0.08, 0), Vector3(0.04, h + 0.1, 0), Vector3(0.0, h + 0.04, 0)], 0.008, 0.03, 8), base, "metal", c8(0xc8ccc8), parent, "SpittoonSpout", {"cast_shadow": false})


## A treadle sewing machine head on a table top: the bed, the pillar, the arm,
## the needle bar and presser foot, the balance wheel, gold lettering.
## (x0..x1) is its length, the wheel at x0; it stands on `y`, centred on cz.
static func sewing_machine(b: LevelBuilder, x0: float, x1: float, y: float, cz: float, parent: String) -> void:
	var black := c8(0x1e1e1e)
	var l := x1 - x0
	ModelKit.box(b, x0, x1, y, y + 0.045, cz - 0.15, cz + 0.15, black, {"surface": "metal", "parent": parent, "name": "SewingMachine", "radius": 0.02})
	ModelKit.box(b, x0 + 0.04, x0 + 0.16, y + 0.045, y + 0.3, cz - 0.07, cz + 0.07, black, {"surface": "metal", "parent": parent, "name": "MachineArm", "radius": 0.035})
	ModelKit.box(b, x0 + 0.04, x1 - 0.06, y + 0.24, y + 0.34, cz - 0.06, cz + 0.06, black, {"surface": "metal", "parent": parent, "name": "MachineHead", "radius": 0.04})
	ModelKit.box(b, x1 - 0.14, x1 - 0.04, y + 0.12, y + 0.34, cz - 0.055, cz + 0.055, black, {"surface": "metal", "parent": parent, "name": "MachineFace", "radius": 0.03})
	_put(b, ModelKit.tube([Vector3(x1 - 0.1, y + 0.13, cz + 0.02), Vector3(x1 - 0.1, y + 0.05, cz + 0.02)], 0.004, 0.0, 6), Vector3.ZERO, "metal", c8(0xc9a55a), parent, "Needle", {"cast_shadow": false})
	_put(b, ModelKit.rbox(Vector3(0.03, 0.006, 0.02), 0.002), Vector3(x1 - 0.1, y + 0.05, cz + 0.02), "metal", c8(0xc8ccc8), parent, "PresserFoot", {"cast_shadow": false})
	_put(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, -0.02), Vector2(0.075, -0.02), Vector2(0.075, 0.02), Vector2(0, 0.02)], 0.008), 24), Vector3(x0 + 0.02, y + 0.26, cz), "metal", c8(0x3a3a3a), parent, "BalanceWheel", {"rotation": Vector3(0, 0, PI / 2)})
	# the gold transfers along the arm
	for k in 3:
		_put(b, ModelKit.rbox(Vector3(0.05 + k * 0.01, 0.012, 0.002), 0.001), Vector3(x0 + 0.24 + k * 0.08 * l / 0.6, y + 0.29, cz + 0.061), "metal", c8(0xd8b040), parent, "Decal", {"cast_shadow": false})
	# a spool on its pin
	_put(b, ModelKit.puck(0.012, 0.03, 0.003, 10), Vector3(x0 + 0.3, y + 0.34, cz - 0.02), "fabric", c8(0xa8534a), parent, "Spool", {"cast_shadow": false})


## A cast-iron cannon barrel, breech knob to swelling muzzle, lying between
## `breech` and `muzzle` points.
static func cannon(b: LevelBuilder, breech: Vector3, muzzle: Vector3, r: float, col: Color, parent: String, band: float) -> MeshInstance3D:
	var l := breech.distance_to(muzzle)
	var prof := ModelKit.rounded_profile([Vector2(0, -r * 0.8), Vector2(r * 0.35, -r * 0.75), Vector2(r * 0.35, -r * 0.4), Vector2(r * 1.0, -r * 0.2), Vector2(r * 1.2, 0.0),
		Vector2(r * 1.2, l * 0.12), Vector2(r * 1.08, l * 0.13), Vector2(r * 1.02, l * 0.45), Vector2(r * 1.1, l * 0.46), Vector2(r * 1.1, l * 0.5), Vector2(r * 0.9, l * 0.52),
		Vector2(r * 0.82, l * 0.88), Vector2(r * 1.0, l * 0.95), Vector2(r * 1.05, l), Vector2(r * 0.55, l), Vector2(r * 0.5, l * 0.9), Vector2(0, l * 0.9)], r * 0.03, 2)
	var d := (muzzle - breech).normalized()
	var basis := Basis.IDENTITY
	if absf(d.dot(Vector3.UP)) < 0.999:
		var axis := Vector3.UP.cross(d).normalized()
		basis = Basis(axis, acos(clampf(Vector3.UP.dot(d), -1, 1)))
	var mi := _put(b, ModelKit.lathe(prof, 28), breech, "metal", col, parent, "Cannon", {"basis": basis, "band": band})
	# the trunnions either side at the balance point
	var side := d.cross(Vector3.UP).normalized()
	_put(b, ModelKit.tube([-side * r * 1.5, side * r * 1.5], r * 0.28, 0.0, 12), breech + d * l * 0.42, "metal", col, parent, "Trunnion", {"band": band})
	return mi


## A wheel for a cart: an iron tyre, a hub and spokes, axle along `axle`.
static func cart_wheel(b: LevelBuilder, center: Vector3, axle: Vector3, r: float, parent: String, extra := {}) -> void:
	var a := axle.normalized()
	var u := a.cross(Vector3.UP).normalized() if absf(a.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var v := a.cross(u).normalized()
	var ring := []
	for k in 33:
		var t := TAU * k / 32
		ring.append((u * cos(t) + v * sin(t)) * r)
	_put(b, ModelKit.tube(ring, r * 0.1, 0.0, 10, false), center, "grain", c8(0x1e1e1e), parent, "Wheel", extra)
	_put(b, ModelKit.tube(ring.map(func(p): return p * 0.8), r * 0.04, 0.0, 6, false), center, "rust", c8(0x6a5a48), parent, "Rim", {"cast_shadow": false}.merged(extra))
	_put(b, ModelKit.tube([-a * 0.05, a * 0.05], r * 0.18, 0.0, 12), center, "rust", c8(0x4a4a48), parent, "Hub", extra)
	for k in 6:
		var t := TAU * k / 6
		var dir := u * cos(t) + v * sin(t)
		_put(b, ModelKit.tube([dir * r * 0.15, dir * r * 0.8], r * 0.035, 0.0, 6), center, "rust", c8(0x6a5a48), parent, "Spoke", {"cast_shadow": false}.merged(extra))


## A plastic crate filling the box (x0..x1, y0..y1, z0..z1): open-slotted
## walls of ribs between three bands, a rolled rim (darker), a floor. `opts`
## go to the body (band, fadeable...).
static func plastic_crate(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, col: Color, parent: String, part := "Crate", opts := {}) -> void:
	var size := Vector3(x1 - x0, y1 - y0, z1 - z0)
	var key := "crate_%.2f_%.2f_%.2f" % [size.x, size.y, size.z]
	var h := size.y
	var parts := []
	var t := 0.012
	# the floor, the bands round the bottom and middle, the corner posts
	parts.append([Vector3(0, 0.008, 0), Vector3(size.x - 0.01, 0.016, size.z - 0.01)])
	for band in [[0.0, 0.04], [h * 0.48, h * 0.48 + 0.025]]:
		var by: float = (band[0] + band[1]) * 0.5
		var bh: float = band[1] - band[0]
		parts.append([Vector3(0, by, size.z * 0.5 - t * 0.5), Vector3(size.x, bh, t)])
		parts.append([Vector3(0, by, -size.z * 0.5 + t * 0.5), Vector3(size.x, bh, t)])
		parts.append([Vector3(size.x * 0.5 - t * 0.5, by, 0), Vector3(t, bh, size.z)])
		parts.append([Vector3(-size.x * 0.5 + t * 0.5, by, 0), Vector3(t, bh, size.z)])
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			parts.append([Vector3(sx * (size.x * 0.5 - 0.02), h * 0.5, sz * (size.z * 0.5 - 0.02)), Vector3(0.04, h, 0.04)])
	# the ribs, leaving the slots between
	var nx := maxi(2, int(size.x / 0.055))
	for k in range(1, nx):
		var x := -size.x * 0.5 + size.x * k / nx
		for sz in [-1.0, 1.0]:
			parts.append([Vector3(x, h * 0.5, sz * (size.z * 0.5 - t * 0.5)), Vector3(0.016, h, t)])
	var nz := maxi(2, int(size.z / 0.055))
	for k in range(1, nz):
		var z := -size.z * 0.5 + size.z * k / nz
		for sx in [-1.0, 1.0]:
			parts.append([Vector3(sx * (size.x * 0.5 - t * 0.5), h * 0.5, z), Vector3(t, h, 0.016)])
	var o := {"parent": parent, "name": part}
	o.merge(opts, true)
	var at := Vector3((x0 + x1) * 0.5, y0, (z0 + z1) * 0.5)
	b.piece(BuildCity.merged(key, parts), at, b.surface("grain"), o.merged({"tint": col}))
	# the rim, thicker and rolled outward, with hand holes cut in the short ends
	var rim := [[Vector3(0, h - 0.02, size.z * 0.5), Vector3(size.x + 0.02, 0.04, 0.025)], [Vector3(0, h - 0.02, -size.z * 0.5), Vector3(size.x + 0.02, 0.04, 0.025)],
		[Vector3(size.x * 0.5, h - 0.02, 0), Vector3(0.025, 0.04, size.z)], [Vector3(-size.x * 0.5, h - 0.02, 0), Vector3(0.025, 0.04, size.z)]]
	b.piece(BuildCity.merged(key + "_rim", rim), at, b.surface("grain"), o.merged({"tint": col.darkened(0.2), "name": part + "Rim", "cast_shadow": false}))


## A steel toolbox, its lid thrown open, the tray inside full of tools.
static func toolbox(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, col: Color, parent: String, extra := {}) -> void:
	var o := {"parent": parent}
	o.merge(extra, true)
	ModelKit.box(b, x0, x1, y0, y1 - 0.04, z0, z1, col, o.merged({"surface": "metal", "name": "Toolbox", "radius": 0.012}))
	# the lid stands open behind, on its hinge along the back edge
	var lid := ModelKit.rbox(Vector3(x1 - x0, 0.05, z1 - z0), 0.012)
	ModelKit.place(b, lid, Vector3((x0 + x1) * 0.5, y1 - 0.02 + (z1 - z0) * 0.5, z0 - 0.02), "metal", col, o.merged({"name": "ToolboxLid", "rotation": Vector3(PI / 2 - 0.25, 0, 0)}))
	ModelKit.place(b, ModelKit.tube([Vector3(-0.07, 0, 0), Vector3(-0.06, 0.035, 0), Vector3(0.06, 0.035, 0), Vector3(0.07, 0, 0)], 0.007, 0.015, 6),
		Vector3((x0 + x1) * 0.5, y1 - 0.02, z1 - 0.06), "metal", c8(0x2a2a2a), o.merged({"name": "ToolboxHandle", "cast_shadow": false}))
	# a spanner, a screwdriver, a hammer, lying in the tray
	var top := y1 - 0.04
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	ModelKit.place(b, ModelKit.tube([Vector3(-0.15, 0, 0), Vector3(0.12, 0, 0)], 0.008, 0.0, 6), Vector3(cx, top + 0.008, cz - 0.04), "metal", c8(0xb8bcc0), o.merged({"name": "Spanner", "cast_shadow": false}))
	ModelKit.place(b, ModelKit.tube(PropKit._oval(0.02, 0.02, 10), 0.006, 0.0, 5, false), Vector3(cx + 0.14, top + 0.008, cz - 0.04), "metal", c8(0xb8bcc0),
		o.merged({"name": "Spanner", "rotation": Vector3(PI / 2, 0, 0), "cast_shadow": false}))
	ModelKit.place(b, ModelKit.tube([Vector3(0, 0, -0.06), Vector3(0, 0, 0.04)], 0.012, 0.0, 8), Vector3(cx - 0.05, top + 0.012, cz + 0.04), "grain", c8(0xc9a530),
		o.merged({"name": "Screwdriver", "rotation": Vector3(0, 1.2, 0), "cast_shadow": false}))
	ModelKit.place(b, ModelKit.tube([Vector3(0, 0, 0.04), Vector3(0, 0, 0.12)], 0.003, 0.0, 6), Vector3(cx - 0.05, top + 0.012, cz + 0.04), "metal", c8(0xb8bcc0),
		o.merged({"name": "Screwdriver", "rotation": Vector3(0, 1.2, 0), "cast_shadow": false}))
	ModelKit.place(b, ModelKit.tube([Vector3(-0.1, 0, 0), Vector3(0.08, 0, 0)], 0.011, 0.0, 8), Vector3(cx + 0.06, top + 0.014, cz + 0.07), "timber", c8(0x8a6a48), o.merged({"name": "Hammer", "cast_shadow": false}))
	ModelKit.place(b, ModelKit.rbox(Vector3(0.03, 0.03, 0.1), 0.006), Vector3(cx + 0.15, top + 0.016, cz + 0.07), "metal", c8(0x3a3a3a), o.merged({"name": "Hammer", "cast_shadow": false}))


## A slatted timber bench: four seat slats on two trestle legs with a brace.
## (x0..x1 its length, z0..z1 its depth, seat at `seat` above y.)
static func bench(b: LevelBuilder, x0: float, x1: float, z0: float, z1: float, y: float, seat: float, col: Color, parent: String, extra := {}) -> void:
	var o := {"parent": parent, "surface": "timber"}
	o.merge(extra, true)
	var n := 4
	var w := (z1 - z0) / n
	for k in n:
		ModelKit.box(b, x0, x1, y + seat - 0.04, y + seat, z0 + k * w + 0.008, z0 + (k + 1) * w - 0.008, col, o.merged({"name": "Bench", "radius": 0.008}))
	for lx in [x0 + 0.1, x1 - 0.18]:
		ModelKit.box(b, lx, lx + 0.08, y, y + seat - 0.04, z0 + 0.06, z0 + 0.12, col.darkened(0.25), o.merged({"name": "BenchLeg"}))
		ModelKit.box(b, lx, lx + 0.08, y, y + seat - 0.04, z1 - 0.12, z1 - 0.06, col.darkened(0.25), o.merged({"name": "BenchLeg"}))
		ModelKit.box(b, lx, lx + 0.08, y + seat - 0.1, y + seat - 0.04, z0 + 0.04, z1 - 0.04, col.darkened(0.2), o.merged({"name": "BenchRail"}))
	ModelKit.box(b, x0 + 0.18, x1 - 0.18, y + 0.12, y + 0.17, (z0 + z1) * 0.5 - 0.03, (z0 + z1) * 0.5 + 0.03, col.darkened(0.25), o.merged({"name": "BenchBrace"}))


## A run of chain links from a to c, each link turned a quarter to the last.
static func chain(b: LevelBuilder, a: Vector3, c: Vector3, link_len: float, wire: float, col: Color, parent: String, part := "Chain", extra := {}) -> void:
	var d := c - a
	var n := maxi(1, int(d.length() / (link_len * 0.78)))
	var link := ModelKit.tube(PropKit._oval(link_len * 0.3, link_len * 0.5, 12), wire, 0.0, 5, false)
	var dir := d.normalized()
	var base_basis := Basis.IDENTITY
	if absf(dir.dot(Vector3.UP)) < 0.999:
		var axis := Vector3.UP.cross(dir).normalized()
		base_basis = Basis(axis, acos(clampf(Vector3.UP.dot(dir), -1, 1)))
	elif dir.y < 0:
		base_basis = Basis(Vector3.RIGHT, PI)
	for k in n:
		var t := (k + 0.5) / n
		var basis := base_basis * Basis(Vector3.UP, (k % 2) * PI / 2)
		_put(b, link, a + d * t, "metal", col, parent, part, {"basis": basis, "cast_shadow": false}.merged(extra))
