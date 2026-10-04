class_name FixtureKit
extends RefCounted

## The building's fittings, modelled: water pipes that bend instead of
## meeting at a ball, joined at flanges and held by clamps; tubular steel
## railings on posts with foot plates; door hardware.

static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


# ----------------------------------------------------------------------------- pipes


## A pipe through `points`. Each straight is its own piece (so a run through
## several storeys fades band by band), each corner a swept bend, each joint
## a bolted flange, and along the straights clamps every couple of metres
## (none inside `exclusions`, where the pipe crosses open space).
static func pipe(b: LevelBuilder, points: Array, col: Color, radius: float, band: float, parent: String, exclusions: Array[AABB] = []) -> void:
	var bend := radius * 2.2
	var n := points.size()
	var ins: Array[Vector3] = []   # where each straight starts and ends, short of the bends
	for i in n - 1:
		var a: Vector3 = points[i]
		var c: Vector3 = points[i + 1]
		var d := (c - a).normalized()
		var len := a.distance_to(c)
		var cut := minf(bend, len * 0.45)
		ins.append(a + d * (cut if i > 0 else 0.0))
		ins.append(c - d * (cut if i < n - 2 else 0.0))
	for i in n - 1:
		var a: Vector3 = ins[i * 2]
		var c: Vector3 = ins[i * 2 + 1]
		var bd := band if band >= 0.0 else b.band_of(minf((points[i] as Vector3).y, (points[i + 1] as Vector3).y))
		if a.distance_to(c) > 0.002:
			ModelKit.place(b, ModelKit.tube([Vector3.ZERO, c - a], radius, 0.0, 14, false), a, "metal", col, {"parent": parent, "name": "PipeRun", "band": bd})
		var d := (c - a).normalized()
		# flanged joints where the lengths were bolted together
		var len := a.distance_to(c)
		var joints := int(len / 3.0)
		for k in joints:
			var p := a.lerp(c, (k + 1.0) / (joints + 1.0))
			_flange(b, p, d, radius, col, parent, bd)
		_clamps(b, a, c, radius, parent, bd, exclusions)
		# the bend into the next straight
		if i < n - 2:
			var corner: Vector3 = points[i + 1]
			var next_a: Vector3 = ins[(i + 1) * 2]
			ModelKit.place(b, ModelKit.tube([c - corner, Vector3.ZERO, next_a - corner], radius, bend, 14, false), corner, "metal", col,
				{"parent": parent, "name": "Collar", "band": bd})
	# capped ends
	for e in [[ins[0], (ins[1] - ins[0]).normalized()], [ins[ins.size() - 1], (ins[ins.size() - 2] - ins[ins.size() - 1]).normalized()]]:
		var p: Vector3 = e[0]
		var d: Vector3 = e[1]
		ModelKit.place(b, ModelKit.tube([-d * 0.02, d * 0.03], radius * 1.18, 0.0, 14), p, "metal", col.darkened(0.12),
			{"parent": parent, "name": "PipeEnd", "band": band if band >= 0.0 else b.band_of(p.y)})


static func _flange(b: LevelBuilder, p: Vector3, d: Vector3, radius: float, col: Color, parent: String, band: float) -> void:
	var basis := _along(d)
	ModelKit.place(b, ModelKit.puck(radius * 1.55, radius * 0.35, radius * 0.08, 28), p - d * radius * 0.175, "metal", col.darkened(0.08),
		{"parent": parent, "name": "Flange", "band": band, "basis": basis, "cast_shadow": false})
	for k in 6:
		var a := TAU * k / 6
		var off := (basis.x * cos(a) + basis.z * sin(a)) * radius * 1.3
		b.piece(PropKit._sphere(radius * 0.13), p + off, b.surface("metal"), {"parent": parent, "name": "Bolt", "tint": c8(0x5a5a58), "band": band, "cast_shadow": false})


## A pipe clamp: a strap round the pipe with a lug on each side, and a rod up
## (or across) to whatever it hangs from.
static func _clamps(b: LevelBuilder, a: Vector3, c: Vector3, radius: float, parent: String, band: float, exclusions: Array[AABB]) -> void:
	var n := int(a.distance_to(c) / 1.8)
	var d := (c - a).normalized()
	for k in n:
		var p := a.lerp(c, (k + 0.5) / maxf(1, n))
		var skip := false
		for bounds in exclusions:
			if bounds.has_point(p):
				skip = true
				break
		if skip:
			continue
		var basis := _along(d)
		var ring := []
		for j in 25:
			var t := TAU * j / 24
			ring.append(basis.x * cos(t) * radius * 1.08 + basis.z * sin(t) * radius * 1.08)
		ModelKit.place(b, ModelKit.tube(ring, radius * 0.1, 0.0, 6, false), p, "metal", c8(0x3a3a3a), {"parent": parent, "name": "Bracket", "band": band, "cast_shadow": false})
		# the hanger: up to the ceiling for a level run, back to the wall for a riser
		var up := Vector3.UP if absf(d.y) < 0.5 else basis.x
		ModelKit.place(b, ModelKit.tube([up * radius * 1.1, up * (radius * 1.1 + 0.12)], radius * 0.12, 0.0, 6), p, "metal", c8(0x3a3a3a),
			{"parent": parent, "name": "Bracket", "band": band, "cast_shadow": false})
		ModelKit.place(b, ModelKit.rbox(Vector3(0.06, 0.012, 0.06), 0.003), p + up * (radius * 1.1 + 0.12), "metal", c8(0x3a3a3a),
			{"parent": parent, "name": "Bracket", "band": band, "cast_shadow": false, "basis": Basis(Vector3.UP.cross(up).normalized(), Vector3.UP.angle_to(up)) if absf(up.y) < 0.99 else Basis.IDENTITY})


## A basis whose y points along d (a puck or tube built up y then lies along d).
static func _along(d: Vector3) -> Basis:
	d = d.normalized()
	if absf(d.dot(Vector3.UP)) > 0.999:
		return Basis.IDENTITY if d.y > 0 else Basis(Vector3.RIGHT, PI)
	var axis := Vector3.UP.cross(d).normalized()
	return Basis(axis, Vector3.UP.angle_to(d))


# ----------------------------------------------------------------------------- railings


## A tubular steel railing from a to c (at floor level y): a top rail and a
## mid rail, posts about every metre on flat foot plates, the ends capped.
## The top rail is `height` up. Opts go to every piece (band, fadeable...).
static func railing(b: LevelBuilder, a: Vector3, c: Vector3, height: float, col: Color, parent: String, opts := {}) -> void:
	var o := {"parent": parent}
	o.merge(opts, true)
	var top := Vector3(0, height - 0.035, 0)
	var mid := Vector3(0, height * 0.47, 0)
	ModelKit.place(b, ModelKit.tube([Vector3.ZERO, c - a], 0.03, 0.0, 12), a + top, "metal", col, o.merged({"name": "Rail"}))
	ModelKit.place(b, ModelKit.tube([Vector3.ZERO, c - a], 0.018, 0.0, 10), a + mid, "metal", col, o.merged({"name": "MidRail", "cast_shadow": false}))
	var n := maxi(1, roundi(a.distance_to(c) / 1.0))
	var post := ModelKit.tube([Vector3.ZERO, top], 0.022, 0.0, 10, false)
	var foot := ModelKit.rbox(Vector3(0.09, 0.012, 0.09), 0.004)
	var cap := ModelKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.034, 0), Vector2(0.03, 0.02), Vector2(0.015, 0.035), Vector2(0, 0.038)]), 12)
	for i in n + 1:
		var p := a.lerp(c, float(i) / n)
		ModelKit.place(b, post, p, "metal", col, o.merged({"name": "Post"}))
		ModelKit.place(b, foot, p + Vector3(0, 0.006, 0), "metal", col.darkened(0.15), o.merged({"name": "PostFoot", "cast_shadow": false}))
		if i == 0 or i == n:
			ModelKit.place(b, cap, p + top, "metal", col, o.merged({"name": "PostCap"}))


# ----------------------------------------------------------------------------- door hardware


## A round brass door knob on a rosette, standing out from a door face along
## `out` at `at` (the face's surface point).
static func knob(b: LevelBuilder, at: Vector3, out: Vector3, opts: Dictionary) -> void:
	var basis := _along(out)
	ModelKit.place(b, ModelKit.puck(0.032, 0.008, 0.003, 18), at, "metal", c8(0xb8944a), opts.merged({"name": "Rosette", "basis": basis, "cast_shadow": false}))
	ModelKit.place(b, ModelKit.lathe(ModelKit.rounded_profile([Vector2(0, 0), Vector2(0.01, 0), Vector2(0.01, 0.035), Vector2(0.03, 0.05), Vector2(0.026, 0.07), Vector2(0, 0.072)], 0.006), 18),
		at, "metal", c8(0xc9a55a), opts.merged({"name": "Knob", "basis": basis}))


## A lever handle on a backplate with a keyhole: `at` on the door face, the
## lever reaching along `reach` (toward the hinge side), `out` off the face.
static func lever(b: LevelBuilder, at: Vector3, out: Vector3, reach: Vector3, opts: Dictionary) -> void:
	var basis := _along(out)
	var plate := Basis(reach.normalized(), Vector3.UP, out.normalized()).orthonormalized()
	ModelKit.place(b, ModelKit.rbox(Vector3(0.045, 0.2, 0.008), 0.006), at + Vector3(0, -0.04, 0) + out * 0.004, "metal", c8(0xb8944a),
		opts.merged({"name": "Backplate", "basis": plate, "cast_shadow": false}))
	ModelKit.place(b, ModelKit.puck(0.006, 0.003, 0.001, 10), at + Vector3(0, -0.1, 0) + out * 0.009, "metal", c8(0x1a1a1a), opts.merged({"name": "Keyhole", "basis": basis, "cast_shadow": false}))
	ModelKit.place(b, ModelKit.tube([Vector3.ZERO, out * 0.05, out * 0.06 + reach.normalized() * 0.11], 0.009, 0.02, 10), at, "metal", c8(0xc9a55a),
		opts.merged({"name": "Handle"}))


## A butt hinge on a door edge: two leaves and the knuckle between, `h` tall,
## the knuckle's axis vertical at `at`.
static func hinge(b: LevelBuilder, at: Vector3, h: float, opts: Dictionary) -> void:
	ModelKit.place(b, ModelKit.puck(0.011, h, 0.002, 10), at - Vector3(0, h * 0.5, 0), "metal", c8(0x2a2a2a), opts.merged({"name": "Hinge", "cast_shadow": false}))
	ModelKit.place(b, ModelKit.puck(0.006, 0.012, 0.002, 8), at + Vector3(0, h * 0.5, 0), "metal", c8(0x3a3a3a), opts.merged({"name": "HingePin", "cast_shadow": false}))
