class_name PlantKit
extends RefCounted

## Potted plants, modelled like the rest of the City (only people and animals
## are pixel art): an aspidistra in a terracotta pot, spring onions in a
## polystyrene fish box, a chilli bush in an old enamel basin.
##
## Each kind is a few shared meshes, one per colour (pot, soil, leaves, fruit),
## built once and placed with a turn that comes from where the pot stands.

static var _cache: Dictionary = {}

const TERRACOTTA := Color("b8653e")
const SOIL := Color("3a2a1e")
const LEAF := Color("5f9a3e")
const LEAF_DARK := Color("3f7a32")
const ONION := Color("8cc05a")
const POLYSTYRENE := Color("e6e8e4")
const ENAMEL := Color("eeece4")
const ENAMEL_RIM := Color("3a5a8a")
const CHILLI := Color("c8321f")


static func place(b: LevelBuilder, kind: String, pos: Vector3, parent: String, band: float) -> Node3D:
	var yaw := fposmod(pos.x * 7.13 + pos.z * 3.71, TAU)
	var first: Node3D = null
	for part: Array in parts(kind):
		var mi := b.piece(part[1], pos, b.surface(part[2]), {"rotation": Vector3(0, yaw, 0), "tint": part[3], "band": band,
			"parent": parent, "name": "Plant" + String(part[0]), "cast_shadow": part[0] != "Soil"})
		if first == null:
			first = mi
	return first


## [name, mesh, surface, tint] for each colour of a kind of plant.
static func parts(kind: String) -> Array:
	if not _cache.has(kind):
		match kind:
			"aspidistra":
				_cache[kind] = _aspidistra()
			"onions":
				_cache[kind] = _onions()
			"chilli":
				_cache[kind] = _chilli()
			_:
				push_error("no plant called " + kind)
				_cache[kind] = []
	return _cache[kind]


# ----------------------------------------------------------------------------- the three plants


## Broad arching leaves in a clay pot.
static func _aspidistra() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var pot := SurfaceTool.new()
	pot.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cyl(pot, Vector3(0, 0.12, 0), 0.24, 0.12, 0.155, 12)       # the pot, narrowing to its foot
	_cyl(pot, Vector3(0, 0.245, 0), 0.05, 0.172, 0.172, 12)     # its rolled rim
	var soil := SurfaceTool.new()
	soil.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cyl(soil, Vector3(0, 0.262, 0), 0.012, 0.15, 0.15, 12)
	var light := SurfaceTool.new()
	light.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := SurfaceTool.new()
	dark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 13
	for i in n:
		var phi := TAU * i / n + rng.randf_range(-0.2, 0.2)
		var length := rng.randf_range(0.36, 0.56)
		var lean := rng.randf_range(0.12, 0.55)
		var base := Vector3(cos(phi), 0, sin(phi)) * 0.04 + Vector3(0, 0.26, 0)
		_arched_leaf(light if i % 3 != 0 else dark, base, phi, lean, length, rng.randf_range(0.07, 0.09))
	return [["Pot", pot.commit(), "plaster", TERRACOTTA], ["Soil", soil.commit(), "tar", SOIL],
		["Leaves", light.commit(), "grain", LEAF], ["LeavesDark", dark.commit(), "grain", LEAF_DARK]]


## A white polystyrene fish box, planted thick with spring onions.
static func _onions() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var box := SurfaceTool.new()
	box.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(box, Vector3(0, 0.1, 0), Vector3(0.58, 0.2, 0.32))
	var soil := SurfaceTool.new()
	soil.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(soil, Vector3(0, 0.196, 0), Vector3(0.53, 0.012, 0.27))
	var stalks := SurfaceTool.new()
	stalks.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 3:
		for col in 10:
			var base := Vector3(-0.23 + col * 0.051 + rng.randf_range(-0.012, 0.012), 0.2, -0.09 + row * 0.09 + rng.randf_range(-0.015, 0.015))
			var h := rng.randf_range(0.2, 0.36)
			var tilt := Vector3(rng.randf_range(-0.14, 0.14), 1.0, rng.randf_range(-0.14, 0.14)).normalized()
			_rod(stalks, base, base + tilt * h, 0.009, 0.004, 5)
	return [["Box", box.commit(), "plaster", POLYSTYRENE], ["Soil", soil.commit(), "tar", SOIL],
		["Stalks", stalks.commit(), "grain", ONION]]


## A round chilli bush in an enamel basin: green, with a few red chillies.
static func _chilli() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	var basin := SurfaceTool.new()
	basin.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cyl(basin, Vector3(0, 0.065, 0), 0.13, 0.235, 0.165, 16)
	var rim := SurfaceTool.new()
	rim.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := TorusMesh.new()          # the blue enamel edge, a ring round the lip
	ring.inner_radius = 0.222
	ring.outer_radius = 0.248
	ring.rings = 16
	ring.ring_segments = 6
	rim.append_from(ring, 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.13, 0)))
	var soil := SurfaceTool.new()
	soil.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cyl(soil, Vector3(0, 0.125, 0), 0.01, 0.22, 0.22, 16)
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centre := Vector3(0, 0.34, 0)
	_rod(leaves, Vector3(0, 0.12, 0), centre, 0.016, 0.012, 5)       # the stem
	var n := 60
	for i in n:
		# spread evenly over the dome (a Fibonacci sphere, the underside squashed)
		var y := 1.0 - 1.7 * (i + 0.5) / n
		var r := sqrt(maxf(0.0, 1.0 - y * y))
		var a := i * 2.39996
		var p := Vector3(cos(a) * r, y * 0.8, sin(a) * r) * 0.2 + centre
		var out := (p - centre).normalized()
		_leaf(leaves, p, out, rng.randf_range(0.075, 0.1), rng.randf_range(0.035, 0.05), rng.randf() * TAU)
	var fruit := SurfaceTool.new()
	fruit.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in [0.3, 1.7, 2.9, 4.2, 5.4]:
		var p := centre + Vector3(cos(a) * 0.19, rng.randf_range(-0.06, 0.06), sin(a) * 0.19)
		_rod(fruit, p, p + Vector3(cos(a) * 0.02, -0.075, sin(a) * 0.02), 0.013, 0.0, 6)   # hanging, pointed
	return [["Basin", basin.commit(), "metal", ENAMEL], ["Rim", rim.commit(), "metal", ENAMEL_RIM],
		["Soil", soil.commit(), "tar", SOIL], ["Leaves", leaves.commit(), "grain", LEAF], ["Chillies", fruit.commit(), "grain", CHILLI]]


# ----------------------------------------------------------------------------- shapes


## A long leaf from `base`, leaning out toward azimuth `phi` and arching over
## as it goes: two flattened ellipsoids, the second bent further out.
static func _arched_leaf(st: SurfaceTool, base: Vector3, phi: float, lean: float, length: float, width: float) -> void:
	var out := Vector3(cos(phi), 0, sin(phi))
	var d1 := (Vector3.UP * cos(lean) + out * sin(lean)).normalized()
	var mid := base + d1 * length * 0.5
	var d2 := (Vector3.UP * cos(lean + 0.75) + out * sin(lean + 0.75)).normalized()
	var across := Vector3(-sin(phi), 0, cos(phi))
	_ellipsoid(st, base + d1 * length * 0.27, d1, across, Vector3(width, length * 0.58, 0.012))
	_ellipsoid(st, mid + d2 * length * 0.22, d2, across, Vector3(width * 0.85, length * 0.5, 0.012))


## A small leaf lying on the bush, facing `out`, turned by `spin`.
static func _leaf(st: SurfaceTool, at: Vector3, out: Vector3, length: float, width: float, spin: float) -> void:
	var t := out.cross(Vector3.UP)
	if t.length() < 0.01:
		t = Vector3.RIGHT
	t = t.normalized().rotated(out, spin)
	_ellipsoid(st, at, t, t.cross(out).normalized(), Vector3(width, length, 0.01))


## A unit sphere stretched along `along` (size.y), across `across` (size.x), thin (size.z).
static func _ellipsoid(st: SurfaceTool, at: Vector3, along: Vector3, across: Vector3, size: Vector3) -> void:
	var y := along.normalized()
	var x := across.normalized()
	var z := x.cross(y).normalized()
	x = y.cross(z).normalized()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 8
	s.rings = 4
	st.append_from(s, 0, Transform3D(Basis(x * size.x, y * size.y, z * size.z), at))


## A rod from a to b, tapering from r0 to r1 (r1 = 0 comes to a point).
static func _rod(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, sides: int) -> void:
	var dir := b - a
	var c := CylinderMesh.new()
	c.height = dir.length()
	c.bottom_radius = r0
	c.top_radius = r1
	c.radial_segments = sides
	c.rings = 1
	var y := dir.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	st.append_from(c, 0, Transform3D(Basis(x, y, z), (a + b) * 0.5))


static func _cyl(st: SurfaceTool, at: Vector3, h: float, top: float, bottom: float, sides: int) -> void:
	var c := CylinderMesh.new()
	c.height = h
	c.top_radius = top
	c.bottom_radius = bottom
	c.radial_segments = sides
	c.rings = 1
	st.append_from(c, 0, Transform3D(Basis.IDENTITY, at))


static func _box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var m := BoxMesh.new()
	m.size = size
	st.append_from(m, 0, Transform3D(Basis.IDENTITY, at))
