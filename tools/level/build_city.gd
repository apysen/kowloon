class_name BuildCity
extends RefCounted

## Everything around the route: the Walled City's solid mass, its roofscape,
## the tenements across the road, and the horizon.
##
## Period reference, 1992: the City is a single block of 300-odd buildings
## grown into each other, ten to fourteen storeys, capped by the Kai Tak
## height limit into a rough plateau of roofs. Windows wear steel cages; air
## conditioners and laundry poles hang off every face that sees daylight. The
## roofs are where people go for air: aerials by the hundred, water tanks,
## pigeon lofts, washing, children watching the jets come in low overhead.
## Across the road stand Kowloon City's tenements, lower, with balconies.
## North are the hills and Lion Rock; west, the red-and-white checkerboard
## pilots turned on; south-east, Kai Tak's runway running into the harbour.

const FACADES := ["facade_a", "facade_b", "facade_c", "facade_d"]
const FACADE_TINTS := [0x8f8a80, 0x7f817a, 0x8a8472, 0x958a7a, 0x7d8580, 0x8a7d70, 0x9a927f, 0x857a70]
const EXTRAS := ["ext_auntie_laundry", "ext_birdcage_man", "ext_smoker", "ext_plant_lady", "ext_kid_red",
	"ext_kid_yellow", "ext_student", "ext_fan_woman", "ext_labourer", "ext_grandma_black",
	"ext_taichi", "ext_sweeper", "ext_eater", "ext_reader"]

static var _windows: Dictionary = {}
static var _mesh_cache: Dictionary = {}


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	filler(b)
	BuildWalledCity.build(b)
	shop_signs(b)
	cables(b)
	tenements(b)
	horizon(b)
	plane(b)


# ----------------------------------------------------------------------------- facade windows


static func windows_of(facade: String) -> Array:
	if _windows.has(facade):
		return _windows[facade]
	var f := FileAccess.open("res://assets/textures/surfaces/%s.json" % facade, FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	_windows[facade] = d.windows
	return d.windows


## World-space window rectangles on one face of a block, from the facade
## texture's window list and the block's uv offset, so 3D cages line up with
## the painted windows exactly.
## face: "n","s","e","w". Returns [{u0, u1, y0, y1, lit}] with u along the face.
static func face_windows(facade: String, off: Vector2, face: String, a0: float, a1: float, y0: float, y1: float) -> Array:
	var out := []
	var W := 6.0
	var H := 5.0
	var wins := windows_of(facade)
	# texture u = sgn * world_u / W + off.x ; v = -y / H + off.y
	var sgn := 1.0
	match face:
		"n": sgn = 1.0      # uv_z.x = -x * sign(n.z), n.z = -1  ->  +x
		"s": sgn = -1.0     # n.z = +1  ->  -x
		"e": sgn = 1.0      # uv_x.x = z * sign(n.x), n.x = +1  ->  +z
		"w": sgn = -1.0
	var ku0 := floori((minf(sgn * a0, sgn * a1) / W + off.x)) - 1
	var ku1 := ceili((maxf(sgn * a0, sgn * a1) / W + off.x)) + 1
	var kv0 := floori(-y1 / H + off.y) - 1
	var kv1 := ceili(-y0 / H + off.y) + 1
	for ku in range(ku0, ku1 + 1):
		for kv in range(kv0, kv1 + 1):
			for w in wins:
				# texture metres (from the tile's top-left) -> world
				var tu0: float = (ku + float(w.x0) / W - off.x) * W * sgn
				var tu1: float = (ku + float(w.x1) / W - off.x) * W * sgn
				var top_m: float = H - float(w.y1)
				var bot_m: float = H - float(w.y0)
				var wy_top := -((kv + top_m / H) - off.y) * H
				var wy_bot := -((kv + bot_m / H) - off.y) * H
				var u0 := minf(tu0, tu1)
				var u1 := maxf(tu0, tu1)
				if u0 < minf(a0, a1) + 0.15 or u1 > maxf(a0, a1) - 0.15:
					continue
				if wy_bot < y0 + 0.3 or wy_top > y1 - 0.3:
					continue
				out.append({"u0": u0, "u1": u1, "y0": wy_bot, "y1": wy_top, "lit": w.lit})
	return out


# ----------------------------------------------------------------------------- merged meshes


static func merged(key: String, boxes: Array) -> ArrayMesh:
	## Parts merged into one mesh. Each is a box, [center, size], built with
	## its edges rounded off; or a round rod, [from, to, radius].
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in boxes:
		if part.size() == 3:
			_append_rod(st, part[0], part[1], part[2])
			continue
		var size: Vector3 = part[1]
		var r := clampf(minf(size.x, minf(size.y, size.z)) * 0.25, 0.002, 0.012)
		st.append_from(_soft(size, r), 0, Transform3D(Basis.IDENTITY, part[0]))
	var m := st.commit()
	_mesh_cache[key] = m
	return m


## A rounded box mesh, one bevel step: cheap enough for the city's thousands.
static func _soft(size: Vector3, r: float) -> ArrayMesh:
	var key := "soft_%.3f_%.3f_%.3f_%.4f" % [size.x, size.y, size.z, r]
	if not _mesh_cache.has(key):
		_mesh_cache[key] = ModelKit._soft_box(size, r, 1, 0.0, 0.0, 0)
	return _mesh_cache[key]


## A six-sided rod from a to c, its ends capped.
static func _append_rod(st: SurfaceTool, a: Vector3, c: Vector3, r: float) -> void:
	var len := a.distance_to(c)
	var key := "rod_%.3f_%.4f" % [len, r]
	if not _mesh_cache.has(key):
		var cm := CylinderMesh.new()
		cm.top_radius = r
		cm.bottom_radius = r
		cm.height = len
		cm.radial_segments = 6
		cm.rings = 1
		_mesh_cache[key] = cm
	st.append_from(_mesh_cache[key], 0, Transform3D(FixtureKit._along(c - a), (a + c) * 0.5))


## A sheet of corrugated iron, `w` across x and `d` along z, its ridges
## running along z, laid flat at y = 0 (centred).
static func corrugated(w: float, d: float, pitch := 0.07, depth := 0.018) -> ArrayMesh:
	var key := "corr_%.2f_%.2f" % [w, d]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := maxi(4, int(w / pitch * 4))
	for i in n:
		var x0 := -w / 2 + w * i / n
		var x1 := -w / 2 + w * (i + 1) / n
		var y0 := sin(x0 / pitch * TAU) * depth * 0.5
		var y1 := sin(x1 / pitch * TAU) * depth * 0.5
		var n0 := Vector3(-cos(x0 / pitch * TAU) * depth * PI / pitch, 1, 0).normalized()
		var n1 := Vector3(-cos(x1 / pitch * TAU) * depth * PI / pitch, 1, 0).normalized()
		for side in [1.0, -1.0]:
			var q := [Vector3(x0, y0, -d / 2), Vector3(x1, y1, -d / 2), Vector3(x1, y1, d / 2), Vector3(x0, y0, d / 2)]
			var nn := [n0 * side, n1 * side, n1 * side, n0 * side]
			var order := [0, 2, 1, 0, 3, 2] if side > 0 else [0, 1, 2, 0, 2, 3]
			for k in order:
				st.set_normal(nn[k])
				st.set_uv(Vector2(q[k].x, q[k].z))
				st.add_vertex(q[k] + Vector3(0, -0.002 if side < 0 else 0.0, 0))
	var m := st.commit()
	_mesh_cache[key] = m
	return m


## A window cage in local space: x across the window, y up, z out from the wall.
static func cage_mesh(w: float, h: float, depth: float, bars: int, variant: int) -> ArrayMesh:
	var key := "cage_%.2f_%.2f_%.2f_%d_%d" % [w, h, depth, bars, variant]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var boxes := []
	var t := 0.035
	# a frame of square tube, the floor tray inside it, a lid on top
	boxes.append([Vector3(0, 0, depth / 2), Vector3(w, t * 1.5, depth)])
	boxes.append([Vector3(0, h, depth / 2), Vector3(w + t, t, depth + t)])
	for x in [-w / 2, w / 2]:
		boxes.append([Vector3(x, h / 2, depth), Vector3(t, h, t)])
		boxes.append([Vector3(x, 0.05, depth / 2), Vector3(t, 0.1, depth)])
	boxes.append([Vector3(0, 0.05, depth), Vector3(w, 0.1, t * 0.6)])
	# round bars, front and sides
	for k in range(1, bars):
		var x := -w / 2 + w * k / bars
		boxes.append([Vector3(x, 0.1, depth), Vector3(x, h, depth), 0.009])
	for k in 3:
		var z := depth * (k + 0.5) / 3.0
		for x in [-w / 2, w / 2]:
			boxes.append([Vector3(x, 0.1, z), Vector3(x, h, z), 0.009])
	# flat rails across the bars; variant 1 adds a scroll of bent bar in the middle
	var rails := 2 if variant == 0 else 3
	for k in rails:
		var y := h * (k + 1) / (rails + 1.0)
		boxes.append([Vector3(0, y, depth), Vector3(w, t * 0.6, t * 0.6)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(merged(key + "_frame", boxes), 0, Transform3D.IDENTITY)
	if variant == 1:
		for k in 2:
			var cx := -w / 4 + k * w / 2
			var ring := []
			for j in 13:
				var a := TAU * j / 12
				ring.append(Vector3(cx + cos(a) * 0.09, h * 0.5 + sin(a) * 0.09, depth))
			for j in 12:
				_append_rod(st, ring[j], ring[j + 1], 0.007)
	if variant == 2:
		# a canopy of corrugated sheet over the cage, tipped to shed the rain
		st.append_from(corrugated(w + 0.12, depth + 0.2), 0, Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, h + 0.06, depth / 2 + 0.06)))
	var m := st.commit()
	_mesh_cache[key] = m
	return m


static func ac_mesh() -> ArrayMesh:
	var parts := [
		[Vector3(0, 0.2, 0.22), Vector3(0.62, 0.4, 0.44)],
		[Vector3(0, -0.02, 0.22), Vector3(0.66, 0.03, 0.5)],      # bracket shelf
	]
	# the louvred front, and the slots down its sides
	for k in 6:
		parts.append([Vector3(0, 0.06 + k * 0.055, 0.445), Vector3(0.54, 0.018, 0.02)])
	for s in [-1.0, 1.0]:
		for k in 4:
			parts.append([Vector3(s * 0.312, 0.1 + k * 0.07, 0.22), Vector3(0.008, 0.02, 0.32)])
		# angle brackets: an arm out from the wall and a strut up from below it
		parts.append([Vector3(s * 0.25, -0.03, 0.0), Vector3(s * 0.25, -0.03, 0.47), 0.012])
		parts.append([Vector3(s * 0.25, -0.32, 0.0), Vector3(s * 0.25, -0.03, 0.4), 0.011])
	parts.append([Vector3(0.2, 0.0, 0.42), Vector3(0.24, -0.35, 0.46), 0.006])   # the drip pipe
	return merged("ac2", parts)


static func pole_mesh(len: float) -> ArrayMesh:
	return merged("pole2_%.2f" % len, [[Vector3(0, 0, 0), Vector3(0, 0, len), 0.02], [Vector3(0, 0, len - 0.02), Vector3(0, 0, len + 0.01), 0.026]])


static func multimesh(b: LevelBuilder, mesh: Mesh, xforms: Array, mat: Material, tint: Color, parent: Node3D, mname: String, shadows := true) -> MultiMeshInstance3D:
	if xforms.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = mname
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.set_instance_shader_parameter("tint", tint)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.attach(mmi, parent)
	return mmi


## Transform that puts a local window-space mesh on a face at (u, y).
static func face_xform(face: String, plane: float, u: float, y: float) -> Transform3D:
	match face:
		"s":
			return Transform3D(Basis.IDENTITY, Vector3(u, y, plane))
		"n":
			return Transform3D(Basis(Vector3.UP, PI), Vector3(u, y, plane))
		"e":
			return Transform3D(Basis(Vector3.UP, PI / 2), Vector3(plane, y, u))
		_:
			return Transform3D(Basis(Vector3.UP, -PI / 2), Vector3(plane, y, u))


# ----------------------------------------------------------------------------- the city block


static func filler(b: LevelBuilder) -> void:
	var X0 := -22.0
	var X1 := 38.0
	var Z0 := -30.0
	var Z1 := 8.0
	var G := LevelBuilder.GRID
	var cols := int((X1 - X0) / G)
	var rows := int((Z1 - Z0) / G)
	var bands := [
		{"band": 0.0, "y0": 0.0, "y1": 4.8},
		{"band": 1.0, "y0": 4.8, "y1": 9.0},
		{"band": 1.5, "y0": 9.0, "y1": -1.0},
	]
	var voids := [
		{"x0": 11.5, "x1": 24.5, "z0": -17.0, "z1": -7.0, "bands": [0.0, 1.0, 1.5]},   # catwalk light well
		{"x0": -7.0, "x1": -3.0, "z0": -21.0, "z1": -16.0, "bands": [1.0, 1.5]},        # airshaft
		{"x0": -10.0, "x1": 12.0, "z0": -24.0, "z1": -6.0, "bands": [1.5]},             # under the roof slab
		{"x0": -8.0, "x1": 2.0, "z0": 4.0, "z1": 6.0, "bands": [0.0, 1.0, 1.5]},         # the slot behind Chiu's workshop
		{"x0": -8.0, "x1": 0.0, "z0": 0.0, "z1": 8.0, "bands": [1.5]},                  # over the workshop and the balcony
		{"x0": 2.0, "x1": 7.0, "z0": 4.0, "z1": 6.0, "bands": [0.0, 1.0, 1.5]},          # the lane, on past its gate
		{"x0": 6.0, "x1": 16.0, "z0": -6.0, "z1": 0.8, "bands": [0.0, 1.0, 1.5]},        # the yamen: its hall and courtyard, open to the sky
		{"x0": 6.0, "x1": 11.0, "z0": 0.8, "z1": 6.0, "bands": [0.0, 1.0, 1.5]},         # the courtyard's mouth
		{"x0": 16.0, "x1": 18.2, "z0": 0.4, "z1": 3.0, "bands": [1.0]},                  # headroom over the yamen stair
		{"x0": -8.4, "x1": -5.3, "z0": -6.2, "z1": 0.0, "bands": [1.5]},                 # Wai's shortcut: the low roof and the balcony over it
	]
	var overlaps := func(ax0: float, ax1: float, az0: float, az1: float, r: Dictionary) -> bool:
		return ax0 < r.x1 - 0.01 and ax1 > r.x0 + 0.01 and az0 < r.z1 - 0.01 and az1 > r.z0 + 0.01

	for band in bands:
		var grid := []
		for i in cols:
			var colv := []
			for j in rows:
				var x0 := X0 + i * G
				var z0 := Z0 + j * G
				var free := true
				for f in b.data.floors:
					var fb := 0.0 if f.y < 2 else (1.0 if f.y < 9 else 2.0)
					var blocks: bool = (fb == 1.0 and f.name == "Airshaft") if band.band == 1.5 else fb == band.band
					if blocks and overlaps.call(x0, x0 + G, z0, z0 + G, f):
						free = false
						break
				if free:
					for v in voids:
						if band.band in v.bands and overlaps.call(x0, x0 + G, z0, z0 + G, v):
							free = false
							break
				colv.append(free)
			grid.append(colv)
		# greedy merge into chunky blocks (up to 3x3 cells) for variety
		for j in rows:
			for i in cols:
				if not grid[i][j]:
					continue
				var max_w := 1 + b.rand.randi() % 3
				var max_d := 1 + b.rand.randi() % 3
				var w := 1
				while w < max_w and i + w < cols and grid[i + w][j]:
					w += 1
				var d := 1
				var ok := true
				while ok and d < max_d and j + d < rows:
					for k in w:
						if not grid[i + k][j + d]:
							ok = false
							break
					if ok:
						d += 1
				for a in w:
					for c in d:
						grid[i + a][j + c] = false
				var inset := 0.35
				var bx0 := X0 + i * G + inset
				var bx1 := X0 + (i + w) * G - inset
				var bz0 := Z0 + j * G + inset
				var bz1 := Z0 + (j + d) * G - inset
				var y1: float = band.y1
				if y1 < 0:
					# the roofscape: a rough plateau, lower right next to Mei's roof
					var near_roof := bx1 > -12.5 and bx0 < 14.5 and bz1 > -26.5 and bz0 < -3.5
					y1 = (10.2 + b.rand.randf() * 2.4) if near_roof else (10.5 + b.rand.randf() * 5.5)
				_block(b, {"x0": bx0, "x1": bx1, "z0": bz0, "z1": bz1, "y0": band.y0, "y1": y1, "band": band.band})
	# dress the blocks once they all exist (dressing checks its neighbours)
	for blk in b.filler_blocks:
		_dress_block(b, blk)
		if blk.band == 1.5:
			_roof_life(b, blk)


static func _block(b: LevelBuilder, blk: Dictionary) -> void:
	var facade: String = FACADES[b.rand.randi() % FACADES.size()]
	# uv offsets snap to whole window bays so dressing can find the windows
	var off := Vector2(float(b.rand.randi() % 6) / 6.0, float(b.rand.randi() % 2) / 2.0)
	# Carry the horizontal facade phase around three consecutive corners.  A
	# rectangular block whose perimeter is not an exact six-metre texture repeat
	# must have one seam; put that seam on its north-west corner, away from the
	# workshop-roof view, rather than letting every visible corner jump.
	var repeat_w := 6.0
	var face_u := {
		"n": 0.0,
		"e": fposmod((float(blk.x1) - float(blk.z0)) / repeat_w, 1.0),
	}
	face_u["s"] = fposmod(float(face_u.e) + (float(blk.x1) + float(blk.z1)) / repeat_w, 1.0)
	face_u["w"] = fposmod(float(face_u.s) + (float(blk.z1) - float(blk.x0)) / repeat_w, 1.0)
	var tint := c8(FACADE_TINTS[b.rand.randi() % FACADE_TINTS.size()])
	var n := b.filler_blocks.size()
	var m := b.box(blk.x0, blk.x1, blk.y0, blk.y1, blk.z0, blk.z1, tint,
		{"fadeable": true, "band": blk.band, "surface": facade, "top": "tar", "uv_offset": off, "filler": true,
		"parent": "City/Blocks", "name": "Block%03d" % n})
	# lit windows vary per building
	m.set_instance_shader_parameter("emission_scale", 0.6 + b.rand.randf() * 0.8)
	m.set_instance_shader_parameter("side_u_offset", Vector4(face_u.e, face_u.w, face_u.s, face_u.n))
	blk["facade"] = facade
	blk["off"] = off
	blk["face_u"] = face_u
	blk["tint"] = tint
	blk["node"] = m
	b.filler_blocks.append(blk)


## Is the strip `depth` metres out from a face clear of other blocks and floors?
static func _face_open(b: LevelBuilder, blk: Dictionary, face: String, depth: float) -> bool:
	var x0: float = blk.x0
	var x1: float = blk.x1
	var z0: float = blk.z0
	var z1: float = blk.z1
	match face:
		"n":
			z1 = z0
			z0 = z0 - depth
		"s":
			z0 = z1
			z1 = z1 + depth
		"e":
			x0 = x1
			x1 = x1 + depth
		"w":
			x1 = x0
			x0 = x0 - depth
	for o in b.filler_blocks:
		if o == blk:
			continue
		if o.y1 < blk.y0 + 0.5 or o.y0 > blk.y1 - 0.5:
			continue
		if x0 < o.x1 and x1 > o.x0 and z0 < o.z1 and z1 > o.z0:
			return false
	for f in b.data.floors:
		var fy: float = f.y
		if fy < blk.y0 - 0.5 or fy > blk.y1:
			continue
		if x0 < f.x1 + 0.6 and x1 > f.x0 - 0.6 and z0 < f.z1 + 0.6 and z1 > f.z0 - 0.6:
			return false
	return true


static func _dress_block(b: LevelBuilder, blk: Dictionary) -> void:
	var node: MeshInstance3D = blk.node
	var cages := []
	var cages_alt := []
	var acs := []
	var poles := []
	var faces := {"s": [blk.z1, blk.x0, blk.x1], "n": [blk.z0, blk.x0, blk.x1], "e": [blk.x1, blk.z0, blk.z1], "w": [blk.x0, blk.z0, blk.z1]}
	var local := Transform3D(Basis.IDENTITY, -node.position)
	for face in faces:
		if not _face_open(b, blk, face, 1.2):
			continue
		var f: Array = faces[face]
		var face_off: Vector2 = blk.off + Vector2(float(blk.face_u.get(face, 0.0)), 0.0)
		var wins := face_windows(blk.facade, face_off, face, f[1], f[2], blk.y0, blk.y1)
		for w in wins:
			var u: float = (w.u0 + w.u1) * 0.5
			var ww: float = w.u1 - w.u0 + 0.2
			var r := b.rand.randf()
			if r < 0.72:
				var xf := face_xform(face, f[0], u, w.y0 - 0.08)
				var mesh := cage_mesh(snappedf(ww, 0.05), snappedf(w.y1 - w.y0 + 0.2, 0.05), 0.42, 8, b.rand.randi() % 3)
				(cages if b.rand.randf() < 0.6 else cages_alt).append([mesh, local * xf])
			if b.rand.randf() < 0.45:
				var ax := u + (b.rand.randf() - 0.5) * 0.6
				acs.append(local * face_xform(face, f[0], ax, w.y0 - 0.75))
			if b.rand.randf() < 0.3:
				poles.append([local * face_xform(face, f[0], u - ww * 0.3, w.y0 + 0.05), local * face_xform(face, f[0], u + ww * 0.3, w.y0 + 0.05), face, f[0], u, w.y0])
	# cages come in a few sizes; group per mesh for MultiMesh
	var by_mesh := {}
	for c in cages + cages_alt:
		by_mesh.get_or_add(c[0], []).append(c[1])
	var metal := b.surface("metal")
	var i := 0
	for mesh in by_mesh:
		var col := c8(0x47443e) if i % 2 == 0 else c8(0x6a5a48)
		multimesh(b, mesh, by_mesh[mesh], metal, col, node, "Cages%d" % i)
		i += 1
	multimesh(b, ac_mesh(), acs, metal, c8(0xc8c6be), node, "AirCons")
	# laundry poles with clothes
	var pole_x := []
	var cloth_x := []
	for p in poles:
		pole_x.append(p[0])
		pole_x.append(p[1])
		var face: String = p[2]
		for k in 2 + b.rand.randi() % 3:
			var du := (k - 1.0) * 0.28
			var xf: Transform3D = local * face_xform(face, p[3], p[4] + du, p[5] - 0.45)
			xf = xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.55 + b.rand.randf() * 0.15))
			cloth_x.append(xf)
	multimesh(b, pole_mesh(0.9), pole_x, metal, c8(0x5a5a55), node, "Poles", false)
	if not cloth_x.is_empty():
		var cm := merged("cloth", [[Vector3(0, 0.22, 0), Vector3(0.24, 0.44, 0.02)]])
		var fab := b.surface("fabric")
		# split into a few colour groups
		var groups := [[], [], [], []]
		for k in cloth_x.size():
			groups[b.rand.randi() % 4].append(cloth_x[k])
		var cols := [c8(0xc9463a), c8(0x3f6fa8), c8(0xe8e2d4), c8(0xd8b040)]
		for g in 4:
			multimesh(b, cm, groups[g], fab, cols[g], node, "Laundry%d" % g, false)


## Rooftop life on the plateau: aerials, tanks, huts, lofts, washing, people.
static func _roof_life(b: LevelBuilder, blk: Dictionary) -> void:
	var y: float = blk.y1
	var x0: float = blk.x0
	var x1: float = blk.x1
	var z0: float = blk.z0
	var z1: float = blk.z1
	var w := x1 - x0
	var d := z1 - z0
	var P := "City/Roofscape"
	# a parapet lip, set a centimetre in from the building's edge so its outer
	# face never lies in the same plane as the facade below it
	var e := 0.01
	b.box(x0 + e, x1 - e, y, y + 0.35, z0 + e, z0 + 0.12, c8(0x8a867c), {"band": 1.5, "surface": "concrete", "parent": P, "name": "Lip"})
	b.box(x0 + e, x1 - e, y, y + 0.35, z1 - 0.12, z1 - e, c8(0x8a867c), {"band": 1.5, "surface": "concrete", "parent": P, "name": "Lip"})
	b.box(x0 + e, x0 + 0.12, y, y + 0.35, z0 + e, z1 - e, c8(0x8a867c), {"band": 1.5, "surface": "concrete", "parent": P, "name": "Lip"})
	b.box(x1 - 0.12, x1 - e, y, y + 0.35, z0 + e, z1 - e, c8(0x8a867c), {"band": 1.5, "surface": "concrete", "parent": P, "name": "Lip"})
	var n_aerials := 1 + b.rand.randi() % 3
	for k in n_aerials:
		BuildInteriors._aerial(b, Vector3(x0 + 0.3 + b.rand.randf() * (w - 0.6), y, z0 + 0.3 + b.rand.randf() * (d - 0.6)), 1.8 + b.rand.randf() * 2.6, P + "/Aerials", 1.5)
	var r := b.rand.randf()
	if r < 0.22 and w > 1.8 and d > 1.8:
		# a rooftop hut: someone's extra room, corrugated roof
		var hx := x0 + 0.2
		var hz := z0 + 0.2
		var hw := minf(w - 0.4, 1.6 + b.rand.randf())
		var hd := minf(d - 0.4, 1.4 + b.rand.randf())
		b.box(hx, hx + hw, y, y + 2.1, hz, hz + hd, c8(0xb8b0a0).lerp(c8(0x8a8a7a), b.rand.randf()), {"band": 1.5, "surface": "plaster", "parent": P, "name": "Hut"})
		# a corrugated roof tipped to drain off the back, held down by a timber batten
		b.piece(corrugated(hw + 0.24, hd + 0.24), Vector3(hx + hw * 0.5, y + 2.16, hz + hd * 0.5), b.surface("rust"),
			{"band": 1.5, "parent": P, "name": "HutRoof", "tint": c8(0x9aa0a0), "rotation": Vector3(-0.07, 0, 0)})
		b.box(hx - 0.1, hx + hw + 0.1, y + 2.17, y + 2.22, hz + hd * 0.5 - 0.03, hz + hd * 0.5 + 0.03, c8(0x6b4a30), {"band": 1.5, "surface": "timber", "parent": P, "name": "HutBatten"})
		# the door: a painted plank leaf in a frame, a knob, a step of brick
		var dx0 := hx + hw * 0.3
		b.box(dx0, dx0 + 0.7, y, y + 1.9, hz + hd, hz + hd + 0.03, c8(0x5a6a7a), {"band": 1.5, "surface": "metal", "parent": P, "name": "HutDoor"})
		for fx in [[dx0 - 0.06, dx0], [dx0 + 0.7, dx0 + 0.76]]:
			b.box(fx[0], fx[1], y, y + 1.96, hz + hd, hz + hd + 0.05, c8(0x4a4038), {"band": 1.5, "surface": "timber", "parent": P, "name": "DoorFrame"})
		b.box(dx0 - 0.06, dx0 + 0.76, y + 1.9, y + 1.96, hz + hd, hz + hd + 0.05, c8(0x4a4038), {"band": 1.5, "surface": "timber", "parent": P, "name": "DoorFrame"})
		FixtureKit.knob(b, Vector3(dx0 + 0.6, y + 1.0, hz + hd + 0.03), Vector3(0, 0, 1), {"parent": P, "band": 1.5})
		# a small barred window beside it
		if hw > 1.5:
			var wx := dx0 + 0.95
			b.box(wx, wx + 0.5, y + 1.1, y + 1.6, hz + hd, hz + hd + 0.01, c8(0x2a2a28), {"band": 1.5, "material": b.glass(true), "parent": P, "name": "HutWindow"})
			for k in 5:
				b.cylinder(Vector3(wx + 0.05 + k * 0.1, y + 1.1, hz + hd + 0.04), Vector3(wx + 0.05 + k * 0.1, y + 1.6, hz + hd + 0.04), 0.008, b.surface("metal"),
					{"band": 1.5, "parent": P, "name": "HutBar", "tint": c8(0x3a3a38), "segments": 6, "cast_shadow": false})
	elif r < 0.4:
		# a water tank on a stand
		var tx := x0 + w * 0.5
		var tz := z0 + d * 0.5
		# the riveted tank on its braced stand, shared with the walled city's roofs
		b.piece(BuildWalledCity._tank_mesh(), Vector3(tx, y, tz), b.surface("rust"), {"band": 1.5, "parent": P, "name": "Tank", "tint": c8(0xa0a8a8)})
	elif r < 0.52 and w > 2.0:
		# a pigeon loft
		b.box(x0 + 0.3, x0 + 1.9, y, y + 1.3, z0 + 0.3, z0 + 1.2, c8(0x6b4a30), {"band": 1.5, "surface": "timber", "parent": P, "name": "Loft"})
		b.piece(corrugated(1.7, 1.0), Vector3(x0 + 1.1, y + 1.34, z0 + 0.75), b.surface("rust"), {"band": 1.5, "parent": P, "name": "LoftRoof", "tint": c8(0x9aa0a0), "rotation": Vector3(0.06, 0, 0)})
		# the slatted front the birds look out through, and a landing board
		for k in 9:
			var sx := x0 + 0.38 + k * 0.18
			b.box(sx, sx + 0.04, y + 0.3, y + 1.22, z0 + 1.2, z0 + 1.23, c8(0x5a3a22), {"band": 1.5, "surface": "timber", "parent": P, "name": "LoftSlat", "cast_shadow": false})
		b.box(x0 + 0.35, x0 + 1.85, y + 0.26, y + 0.3, z0 + 1.2, z0 + 1.42, c8(0x7a5a3a), {"band": 1.5, "surface": "timber", "parent": P, "name": "LandingBoard"})
	if b.rand.randf() < 0.45:
		# washing on a line between two poles
		var lx0 := x0 + 0.25
		var lx1 := x1 - 0.25
		var lz := z0 + d * (0.3 + b.rand.randf() * 0.4)
		for px in [lx0 + 0.025, lx1 - 0.025]:
			b.cylinder(Vector3(px, y, lz + 0.025), Vector3(px, y + 1.9, lz + 0.025), 0.022, b.surface("metal"), {"band": 1.5, "parent": P, "name": "LinePost", "tint": c8(0x5a5a55), "segments": 8})
		b.cylinder(Vector3(lx0 + 0.025, y + 1.86, lz + 0.025), Vector3(lx1 - 0.025, y + 1.86, lz + 0.025), 0.004, b.surface("grain"), {"band": 1.5, "parent": P, "name": "Line", "tint": c8(0x2a2a2a), "segments": 5, "cast_shadow": false})
		var cols := [c8(0xe8e2d4), c8(0xc9463a), c8(0x3f6fa8), c8(0xd8b040), c8(0x6f8a5a), c8(0xe0a0b0)]
		var cx := lx0 + 0.2
		while cx < lx1 - 0.4:
			var cw := 0.3 + b.rand.randf() * 0.35
			var ch := 0.4 + b.rand.randf() * 0.5
			var cloth := b.box(cx, cx + cw, y + 1.85 - ch, y + 1.85, lz - 0.01, lz + 0.01, cols[b.rand.randi() % cols.size()],
				{"band": 1.5, "surface": "fabric", "parent": P, "name": "Washing"})
			cloth.set_meta("cloth", true)
			cx += cw + 0.08
	# potted plants and polystyrene boxes of spring onions
	var kinds := ["aspidistra", "onions", "chilli", "onions"]
	for k in b.rand.randi() % 3:
		var px := x0 + 0.35 + b.rand.randf() * maxf(0.1, w - 0.7)
		var pz := z0 + 0.35 + b.rand.randf() * maxf(0.1, d - 0.7)
		BuildInteriors.plant(b, kinds[b.rand.randi() % kinds.size()], Vector3(px, y, pz), P + "/Plants", 1.5)
	# people up for the air
	if b.rand.randf() < 0.3:
		var who: String = EXTRAS[b.rand.randi() % EXTRAS.size()]
		var anim := "work"
		if who.begins_with("ext_kid") and b.rand.randf() < 0.5:
			anim = "point"
		var pos := Vector3(x0 + 0.5 + b.rand.randf() * maxf(0.1, w - 1.0), y, z0 + 0.5 + b.rand.randf() * maxf(0.1, d - 1.0))
		var res := b.resident("roof_%s_%d" % [who, b.filler_blocks.find(blk)], who, pos,
			{"anim": anim, "collide": false, "story": false, "parent": "City/People",
			"facing": Vector3(b.rand.randf() - 0.5, 0, b.rand.randf() - 0.5).normalized()})
		b.tag(res, 1.5)


# ----------------------------------------------------------------------------- signs and cables


static func shop_signs(b: LevelBuilder) -> void:
	## Lightboxes and painted boards on faces that look onto the walkways.
	var candidates := b.filler_blocks.filter(func(blk): return (blk.band == 0.0 or blk.band == 1.0) and blk.x1 > -16 and blk.x0 < 32 and blk.z1 > -26 and blk.z0 < 6)
	var placed := 0
	var i := 0
	while i < candidates.size() and placed < 22:
		var blk: Dictionary = candidates[(i * 7) % candidates.size()]
		i += 3
		var dentist := placed % 3 == 0
		var tex := "res://assets/textures/props/%s.png" % (("sign_dentist_%d" % (placed % 6)) if dentist else ("neon_%d" % (placed % 12)))
		var h := 1.5 + b.rand.randf() * 0.7
		var y: float = blk.y0 + 1.2 + b.rand.randf() * maxf(0.1, (blk.y1 - blk.y0) - h - 1.4)
		var face_south := b.rand.randf() < 0.6
		var pos: Vector3
		var normal: Vector3
		if face_south:
			pos = Vector3(blk.x0 + 0.4 + b.rand.randf() * maxf(0.1, blk.x1 - blk.x0 - 0.8), y + h / 2, blk.z1 + 0.35)
			normal = Vector3(1, 0, 0)
		else:
			pos = Vector3(blk.x1 + 0.35, y + h / 2, blk.z0 + 0.4 + b.rand.randf() * maxf(0.1, blk.z1 - blk.z0 - 0.8))
			normal = Vector3(0, 0, 1)
		# never into a room or through a neighbour: try the other face, else leave it bare
		# (the same random draws either way, so the rest of the city doesn't shift)
		if not _sign_clear(b, blk, pos, h, face_south):
			face_south = not face_south
			if face_south:
				pos = Vector3((blk.x0 + blk.x1) / 2, y + h / 2, blk.z1 + 0.35)
				normal = Vector3(1, 0, 0)
			else:
				pos = Vector3(blk.x1 + 0.35, y + h / 2, (blk.z0 + blk.z1) / 2)
				normal = Vector3(0, 0, 1)
			if not _sign_clear(b, blk, pos, h, face_south):
				placed += 1
				continue
		var node: MeshInstance3D = blk.node
		var holder := Node3D.new()
		holder.name = "Sign%d" % placed
		b.attach(holder, node)
		# a two-sided sign box sticking out from the wall, readable from both ways
		var box := b.box(pos.x - 0.03, pos.x + 0.03, pos.y - h / 2, pos.y + h / 2, pos.z - 0.25, pos.z + 0.25, c8(0x201418),
			{"surface": "metal", "parent_node": holder, "name": "SignBox"}) if face_south else \
			b.box(pos.x - 0.25, pos.x + 0.25, pos.y - h / 2, pos.y + h / 2, pos.z - 0.03, pos.z + 0.03, c8(0x201418),
			{"surface": "metal", "parent_node": holder, "name": "SignBox"})
		b._localize(box, node)
		for sgn in [-1.0, 1.0]:
			var c := b.card(tex, pos - node.position + normal * sgn * 0.035, Vector2(0.5, h), normal * sgn,
				{"parent_node": holder, "untagged": true, "name": "SignFace", "emission": 0.0 if dentist else 1.6, "unshaded": false})
			c.position = pos - node.position + normal * sgn * 0.035
		var br := b.box(pos.x - 0.03, pos.x + 0.03, pos.y + h / 2 - 0.1, pos.y + h / 2 - 0.04, pos.z - 0.35, pos.z + 0.05,
			c8(0x333333), {"surface": "metal", "parent_node": holder, "name": "Bracket"})
		b._localize(br, node)
		placed += 1


## Is a sign box, sticking out from `blk` at `pos`, clear of every closed room
## (with its walls) and every other building?
static func _sign_clear(b: LevelBuilder, blk: Dictionary, pos: Vector3, h: float, face_south: bool) -> bool:
	var ext := Vector3(0.05, h / 2, 0.35) if face_south else Vector3(0.35, h / 2, 0.05)
	var lo := pos - ext
	var hi := pos + ext
	for room in b.data.closed_rooms:
		var ry: float = room.y
		if hi.y < ry or lo.y > ry + 4.5:
			continue
		for r in room.rects:
			if lo.x < r[1] + 0.35 and hi.x > r[0] - 0.35 and lo.z < r[3] + 0.35 and hi.z > r[2] - 0.35:
				return false
	for o in b.filler_blocks:
		if o == blk or hi.y < o.y0 or lo.y > o.y1:
			continue
		if lo.x < o.x1 and hi.x > o.x0 and lo.z < o.z1 and hi.z > o.z0:
			return false
	return true


static func cables(b: LevelBuilder) -> void:
	## Overhead cables strung between buildings, sagging.
	var tops := b.filler_blocks.filter(func(blk): return blk.band == 1.5 or blk.band == 1.0)
	if tops.is_empty():
		return
	var mat := b.surface("grain")
	for i in 44:
		var a: Dictionary = tops[(i * 13) % tops.size()]
		var c: Dictionary = tops[(i * 29 + 7) % tops.size()]
		var pa := Vector3(a.x0 + 0.2, a.y1 - 0.2, (a.z0 + a.z1) / 2)
		var pb := Vector3(c.x1 - 0.2, c.y1 - 0.2, (c.z0 + c.z1) / 2)
		var dist := pa.distance_to(pb)
		if dist > 14 or dist < 3:
			continue
		var sag := 0.6 + dist * 0.06
		var prev := pa
		var band := b.band_of(minf(pa.y, pb.y) - 1)
		for k in range(1, 7):
			var t := k / 6.0
			var p := pa.lerp(pb, t)
			p.y -= sag * 4 * t * (1 - t)
			b.cylinder(prev, p, 0.02, mat, {"parent": "City/Cables", "name": "Cable", "tint": c8(0x1c1c1e), "band": band, "cast_shadow": false, "segments": 4})
			prev = p


# ----------------------------------------------------------------------------- across the road


static func tenements(b: LevelBuilder) -> void:
	## Kowloon City's tenements across the road from the City, balconies facing it.
	## Only seen from the roof (band 1.5).
	## Across the boundary roads of the 1985 plot (see BuildWalledCity.CITY).
	## The north and east rows, nearest Mei's roof, carry the full balconies.
	var C: Dictionary = BuildWalledCity.CITY
	var rings := [
		# Tung Tau Tsuen Road, north: faces south toward the City
		{"axis": "x", "from": float(C.x0) - 20.0, "to": float(C.x1) + 20.0, "line": float(C.z0) - 11.0, "depth": 7.0, "face": "s", "dense": true},
		# Carpenter Road, south: faces north
		{"axis": "x", "from": float(C.x0) - 20.0, "to": float(C.x1) + 20.0, "line": float(C.z1) + 9.0, "depth": 7.0, "face": "n", "dense": false},
		# Sai Tau Tsuen Road, west: faces east
		{"axis": "z", "from": float(C.z0) - 4.0, "to": float(C.z1) + 4.0, "line": float(C.x0) - 9.0, "depth": 7.0, "face": "e", "dense": false},
		# Tung Tsing Road, east: faces west
		{"axis": "z", "from": float(C.z0) - 4.0, "to": float(C.z1) + 4.0, "line": float(C.x1) + 11.0, "depth": 7.0, "face": "w", "dense": true},
	]
	for ring in rings:
		var u: float = ring.from
		while u < ring.to:
			var width := 4.0 + b.rand.randf() * 4.0
			var height := 9.0 + b.rand.randf() * 7.0
			_tenement(b, ring, u, u + width, height)
			u += width + 0.2


static func _tenement(b: LevelBuilder, ring: Dictionary, u0: float, u1: float, height: float) -> void:
	var line: float = ring.line
	var depth: float = ring.depth
	var face: String = ring.face
	var x0: float
	var x1: float
	var z0: float
	var z1: float
	if ring.axis == "x":
		x0 = u0
		x1 = u1
		z0 = line if face == "n" else line - depth
		z1 = z0 + depth
	else:
		z0 = u0
		z1 = u1
		x0 = line if face == "w" else line - depth
		x1 = x0 + depth
	var facade: String = FACADES[b.rand.randi() % FACADES.size()]
	var off := Vector2(float(b.rand.randi() % 6) / 6.0, float(b.rand.randi() % 2) / 2.0)
	var tint := c8(FACADE_TINTS[b.rand.randi() % FACADE_TINTS.size()]).lightened(0.05)
	var m := b.box(x0, x1, -1.0, height, z0, z1, tint, {"band": 1.5, "surface": facade, "top": "tar", "uv_offset": off,
		"parent": "City/Tenements", "name": "Tenement", "cast_shadow": true})
	m.set_instance_shader_parameter("emission_scale", 0.5 + b.rand.randf() * 0.8)
	# the face toward the City: storeys of balconies, every one different
	var plane := z1 if face == "s" else (z0 if face == "n" else (x1 if face == "e" else x0))
	var a0 := x0 if ring.axis == "x" else z0
	var a1 := x1 if ring.axis == "x" else z1
	var storey := 2.5
	var y := 2.5
	var P := "City/Balconies"
	var dense: bool = ring.get("dense", true)
	while y < height - 2.0:
		var u := a0 + 0.4
		while u < a1 - 1.6:
			var bw := 1.6 + b.rand.randf() * 0.9
			if u + bw > a1 - 0.3:
				break
			if b.rand.randf() < (0.85 if dense else 0.3):
				_balcony(b, face, plane, u, u + bw, y, P, dense)
			u += bw + 0.3
		y += storey
	# rooftop: aerials and a water tank, sometimes a kid watching planes
	var rtop := height
	for k in 1 + b.rand.randi() % 3:
		BuildInteriors._aerial(b, Vector3(x0 + 0.5 + b.rand.randf() * (x1 - x0 - 1), rtop, z0 + 0.5 + b.rand.randf() * (z1 - z0 - 1)), 1.5 + b.rand.randf() * 2.5, "City/TenementRoofs", 1.5)
	if b.rand.randf() < 0.25:
		var who: String = ["ext_kid_red", "ext_kid_yellow", "ext_birdcage_man", "ext_auntie_laundry"][b.rand.randi() % 4]
		var pos := Vector3(lerpf(x0, x1, 0.3 + b.rand.randf() * 0.4), rtop, lerpf(z0, z1, 0.3 + b.rand.randf() * 0.4))
		var res := b.resident("tenement_roof_%d" % b.rand.randi(), who, pos, {"anim": "point" if who.begins_with("ext_kid") else "work",
			"collide": false, "story": false, "parent": "City/People", "facing": _face_normal(face)})
		b.tag(res, 1.5)


static func _face_normal(face: String) -> Vector3:
	match face:
		"s": return Vector3(0, 0, 1)
		"n": return Vector3(0, 0, -1)
		"e": return Vector3(1, 0, 0)
	return Vector3(-1, 0, 0)


## One balcony: a slab, a front of one of several kinds, and what the family
## keeps out there. Sometimes somebody is out on it.
static func _balcony(b: LevelBuilder, face: String, plane: float, u0: float, u1: float, y: float, parent: String, people := true) -> void:
	var n := _face_normal(face)
	var depth := 0.9
	var w := u1 - u0
	var holder := Node3D.new()
	holder.name = "Balcony"
	var um := (u0 + u1) * 0.5
	holder.transform = face_xform(face, plane, um, y)
	b.attach(holder, b.group(parent))
	b.tag(holder, 1.5)
	var lo := func(x0: float, x1: float, yy0: float, yy1: float, z0: float, z1: float, col: Color, surf: String, nm: String) -> MeshInstance3D:
		var mi := b.box(x0, x1, yy0, yy1, z0, z1, col, {"surface": surf, "parent_node": holder, "name": nm})
		mi.remove_meta("band")
		return mi
	# slab
	lo.call(-w / 2, w / 2, -0.12, 0.0, 0.0, depth, c8(0x9a958a), "concrete", "Slab")
	var kind := b.rand.randi() % 5
	var rail_col: Color = [c8(0x47443e), c8(0x3f6f6a), c8(0x6a5a48), c8(0x8a3a30)][b.rand.randi() % 4]
	match kind:
		0:
			# solid parapet clad in mosaic, a steel rail on top
			var clad: Color = [c8(0xb9c6c0), c8(0xc9b89a), c8(0xa9b6c4), c8(0xd0c7ae)][b.rand.randi() % 4]
			lo.call(-w / 2, w / 2, 0.0, 0.9, depth - 0.08, depth, clad, "mosaic", "Parapet")
			lo.call(-w / 2, -w / 2 + 0.08, 0.0, 0.9, 0.0, depth, clad, "mosaic", "Parapet")
			lo.call(w / 2 - 0.08, w / 2, 0.0, 0.9, 0.0, depth, clad, "mosaic", "Parapet")
			lo.call(-w / 2, w / 2, 0.9, 0.95, depth - 0.09, depth + 0.01, rail_col, "metal", "Rail")
		1:
			# ornamental grille: vertical bars with a diamond band
			lo.call(-w / 2, w / 2, 0.95, 1.0, depth - 0.03, depth, rail_col, "metal", "Rail")
			var k := 0
			var x := -w / 2
			while x <= w / 2:
				lo.call(x - 0.015, x + 0.015, 0.0, 0.95, depth - 0.03, depth, rail_col, "metal", "Bar")
				x += 0.12
				k += 1
			lo.call(-w / 2, w / 2, 0.45, 0.5, depth - 0.03, depth, rail_col, "metal", "Band")
		2:
			# fully caged in, floor to ceiling, like the City's windows
			var mesh := cage_mesh(snappedf(w, 0.05), 2.3, depth, int(w / 0.14), 1)
			var mi := MeshInstance3D.new()
			mi.name = "Cage"
			mi.mesh = mesh
			mi.material_override = b.surface("metal")
			mi.set_instance_shader_parameter("tint", rail_col)
			b.attach(mi, holder)
		3:
			# low wall with glass louvres above (an enclosed balcony)
			lo.call(-w / 2, w / 2, 0.0, 1.0, depth - 0.1, depth, c8(0xd8d0c0), "plaster", "Wall")
			var yy := 1.05
			while yy < 2.2:
				lo.call(-w / 2 + 0.05, w / 2 - 0.05, yy, yy + 0.1, depth - 0.06, depth - 0.02, c8(0x9fb2ad), "metal", "Louvre")
				yy += 0.16
		_:
			# plain tubular rail
			for yy in [0.5, 0.95]:
				lo.call(-w / 2, w / 2, yy, yy + 0.04, depth - 0.04, depth, rail_col, "metal", "Rail")
			var x2 := -w / 2
			while x2 <= w / 2:
				lo.call(x2 - 0.02, x2 + 0.02, 0.0, 0.98, depth - 0.04, depth, rail_col, "metal", "Post")
				x2 += 0.6
	# what lives out there
	if b.rand.randf() < 0.6:
		# a laundry pole poking out past the front, with clothes
		lo.call(-w / 2 + 0.2, -w / 2 + 0.24, 2.0, 2.04, 0.1, depth + 0.9, c8(0x5a5a55), "metal", "LaundryPole")
		var cols := [c8(0xe8e2d4), c8(0xc9463a), c8(0x3f6fa8), c8(0xd8b040), c8(0x6f8a5a)]
		for k in 2 + b.rand.randi() % 3:
			var z := depth + 0.15 + k * 0.22
			var ch := 0.35 + b.rand.randf() * 0.45
			var cl: MeshInstance3D = lo.call(-w / 2 + 0.05, -w / 2 + 0.4, 2.0 - ch, 2.0, z - 0.01, z + 0.01, cols[b.rand.randi() % cols.size()], "fabric", "Laundry")
			cl.set_meta("cloth", true)
	if b.rand.randf() < 0.55:
		for k in 1 + b.rand.randi() % 3:
			var px := -w / 2 + 0.15 + b.rand.randf() * (w - 0.5)
			lo.call(px, px + 0.28, 0.0, 0.26, depth - 0.4, depth - 0.12, [c8(0x8a5a3a), c8(0xa8453a), c8(0xe8e8e0)][k % 3], "grain", "Pot")
			lo.call(px + 0.03, px + 0.25, 0.26, 0.45 + b.rand.randf() * 0.4, depth - 0.37, depth - 0.15, c8(0x4f8a3a).lerp(c8(0x7aa04a), b.rand.randf()), "fabric", "Plant")
	if b.rand.randf() < 0.2:
		# a bird in a bamboo cage hung from the ceiling
		lo.call(-0.12, 0.12, 1.6, 1.9, depth - 0.3, depth - 0.1, c8(0xc9a66a), "wood", "Birdcage")
	if b.rand.randf() < 0.25:
		# the red glow of a door-god shrine
		var lamp := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.05
		s.height = 0.1
		lamp.mesh = s
		lamp.material_override = b.emissive(c8(0xff3a2a), 5.0)
		lamp.position = Vector3(w / 2 - 0.2, 0.35, 0.1)
		b.attach(lamp, holder)
	if b.rand.randf() < 0.3:
		# a fluorescent tube on the back wall, for evening
		var tube := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.018
		cm.bottom_radius = 0.018
		cm.height = 0.9
		tube.mesh = cm
		tube.material_override = b.emissive(Color(0.9, 1.0, 0.95), 4.0)
		tube.rotation = Vector3(0, 0, PI / 2)
		tube.position = Vector3(0, 2.2, 0.06)
		b.attach(tube, holder)
	if people and b.rand.randf() < 0.22:
		var who: String = EXTRAS[b.rand.randi() % EXTRAS.size()]
		var gp := holder.transform * Vector3(-w / 4 + b.rand.randf() * w / 2, 0.0, depth * 0.5)
		var res := b.resident("balcony_%s_%d" % [who, b.rand.randi()], who, gp,
			{"anim": "work", "collide": false, "story": false, "parent": "City/People", "facing": n})
		b.tag(res, 1.5)


# ----------------------------------------------------------------------------- horizon


static func horizon(b: LevelBuilder) -> void:
	var P := "City/Horizon"
	# the rest of Kowloon City: low detail, beyond the tenements round the plot
	var towers := []
	for i in 150:
		var ang := b.rand.randf() * TAU
		var r := 118 + b.rand.randf() * 70
		var x := -40 + cos(ang) * r * 1.2
		var z := -5 + sin(ang) * r
		if z > 60 and x > -40:
			continue          # the airport and the bay to the south-east stay open
		var w := 5 + b.rand.randf() * 9
		var d := 5 + b.rand.randf() * 9
		var h := 8 + b.rand.randf() * 22
		var col := c8([0x8a96a0, 0x96a0a4, 0x7d8a94, 0xa4a8a4, 0x9a9488][i % 5])
		var m := b.box(x, x + w, -2, h, z, z + d, col, {"band": 1.5, "surface": "facade_far", "top": "tar", "uv_random": true,
			"parent": P + "/Skyline", "name": "Distant", "cast_shadow": false})
		m.set_instance_shader_parameter("emission_scale", 0.4 + b.rand.randf() * 0.6)
		towers.append([x, w, z, d, h, col])
	_skyline_roofs(b, towers, P + "/Skyline")
	# a flat for the streets and the harbour so the distance is never a void
	b.box(-320, 320, -2.4, -2.0, -320, 320, c8(0x5f5a52), {"band": 1.5, "surface": "concrete", "parent": P, "name": "Ground", "cast_shadow": false})
	var water := StandardMaterial3D.new()
	water.albedo_color = c8(0x4a6a7a)
	water.roughness = 0.08
	water.metallic_specular = 0.9
	# Kowloon Bay, south-east, with Kai Tak's runway reaching into it
	b.box(20, 320, -2.2, -1.9, 150, 320, c8(0x4a6a7a), {"band": 1.5, "material": water, "parent": P, "name": "Harbour", "cast_shadow": false})
	b.box(40, 230, -1.9, -1.8, 158, 172, c8(0x6a6a66), {"band": 1.5, "surface": "concrete", "parent": P, "name": "Runway", "cast_shadow": false})
	for k in 40:
		var x := 44 + k * 4.6
		b.box(x, x + 2.0, -1.8, -1.78, 164.8, 165.2, c8(0xe8e8e0), {"band": 1.5, "material": b.emissive(Color(1, 0.98, 0.9), 1.5, false), "parent": P + "/Runway", "name": "Centreline", "cast_shadow": false})
	# hills to the north, Lion Rock among them
	var hills_mat := b.card_material("res://assets/textures/props/hills_north.png", 0.0, true)
	for k in 3:
		var q := QuadMesh.new()
		q.size = Vector2(420, 78)
		b.piece(q, Vector3(-150 + k * 190, 28, -236 - k * 6), hills_mat, {"band": 1.5, "parent": P, "name": "Hills", "cast_shadow": false})
	# the checkerboard on the hill to the west, where the jets turned in
	var hill := CylinderMesh.new()
	hill.top_radius = 8
	hill.bottom_radius = 34
	hill.height = 34
	hill.radial_segments = 14
	b.piece(hill, Vector3(-235, 14, -40), b.surface("concrete"), {"band": 1.5, "parent": P, "name": "CheckerboardHill", "tint": c8(0x6f8a66), "cast_shadow": false})
	b.card("res://assets/textures/props/checkerboard.png", Vector3(-215.5, 17, -40), Vector2(13, 13), Vector3(1, 0, 0),
		{"band": 1.5, "parent": P, "name": "Checkerboard", "unshaded": false})


## The far towers' roofs against the sky: a parapet round each, a storey
## stepped back on some, and the tanks, stair huts and aerials every roof in
## Kowloon carried. Drawn as a few MultiMeshes, with their own random stream
## so nothing nearer moves.
static func _skyline_roofs(b: LevelBuilder, towers: Array, parent: String) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4471
	var holder := b.group(parent)
	var parapet := []
	var tanks := []
	var huts := []
	var aerials := []
	for t in towers:
		var x: float = t[0]
		var w: float = t[1]
		var z: float = t[2]
		var d: float = t[3]
		var h: float = t[4]
		var top := h
		if r.randf() < 0.45 and w > 7.0 and d > 7.0:
			# a storey set back from the street face
			var sx := x + w * r.randf_range(0.15, 0.35)
			var sz := z + d * r.randf_range(0.15, 0.35)
			var sw := w * r.randf_range(0.45, 0.6)
			var sd := d * r.randf_range(0.45, 0.6)
			var sh := r.randf_range(2.8, 6.0)
			var m := b.box(sx, sx + sw, h, h + sh, sz, sz + sd, (t[5] as Color).darkened(0.05), {"band": 1.5, "surface": "facade_far", "top": "tar", "uv_random": true,
				"parent": parent, "name": "DistantSetback", "cast_shadow": false})
			m.set_instance_shader_parameter("emission_scale", 0.3 + r.randf() * 0.5)
			parapet.append(Transform3D(Basis.IDENTITY.scaled(Vector3(sw, 1, sd)), Vector3(sx + sw * 0.5, h + sh, sz + sd * 0.5)))
		parapet.append(Transform3D(Basis.IDENTITY.scaled(Vector3(w, 1, d)), Vector3(x + w * 0.5, top, z + d * 0.5)))
		for k in r.randi_range(1, 3):
			var at := Vector3(x + r.randf_range(0.8, w - 0.8), top, z + r.randf_range(0.8, d - 0.8))
			match r.randi() % 3:
				0:
					tanks.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * 1.4), at))
				1:
					huts.append(Transform3D(Basis(Vector3.UP, r.randi_range(0, 3) * PI / 2), at))
				_:
					aerials.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), at))
	# a parapet in unit size, stretched per roof: 0.9 m high, 0.25 m thick at 10 m
	var ring := merged("skyline_parapet", [[Vector3(0, 0.45, 0.49), Vector3(1.0, 0.9, 0.02)], [Vector3(0, 0.45, -0.49), Vector3(1.0, 0.9, 0.02)],
		[Vector3(0.49, 0.45, 0), Vector3(0.02, 0.9, 1.0)], [Vector3(-0.49, 0.45, 0), Vector3(0.02, 0.9, 1.0)]])
	var hut := merged("skyline_hut", [[Vector3(0, 1.2, 0), Vector3(2.2, 2.4, 2.0)], [Vector3(0, 2.45, 0), Vector3(2.5, 0.1, 2.3)], [Vector3(0, 1.0, 1.01), Vector3(0.8, 2.0, 0.04)]])
	for mm in [multimesh(b, ring, parapet, b.surface("concrete"), c8(0x8a8a84), holder, "DistantParapets", false),
			multimesh(b, BuildWalledCity._tank_mesh(), tanks, b.surface("rust"), c8(0x9aa0a0), holder, "DistantTanks", false),
			multimesh(b, hut, huts, b.surface("plaster"), c8(0xa8a294), holder, "DistantHuts", false),
			multimesh(b, BuildWalledCity._aerial_mesh(3.2, 2), aerials, b.surface("metal"), c8(0x3a3a3a), holder, "DistantAerials", false)]:
		if mm:
			# on the skyline's band, so it shows and hides with the towers
			b.tag(mm, 1.5)


static func plane(b: LevelBuilder) -> void:
	## A four-engined airliner on the low approach over the city. Generic livery.
	var p := Node3D.new()
	p.name = "Plane"
	p.position = Vector3(-120, 21, -30)
	p.rotation.z = -0.06
	p.visible = false
	b.attach(p, b.group("Special"))
	var white := b.surface("metal")
	var add := func(mesh: Mesh, pos: Vector3, rot: Vector3, tint: Color, nm: String) -> void:
		var mi := MeshInstance3D.new()
		mi.name = nm
		mi.mesh = mesh
		mi.position = pos
		mi.rotation = rot
		mi.material_override = white
		mi.set_instance_shader_parameter("tint", tint)
		b.attach(mi, p)
	var body := CylinderMesh.new()
	body.top_radius = 1.2
	body.bottom_radius = 1.1
	body.height = 18
	body.radial_segments = 16
	add.call(body, Vector3.ZERO, Vector3(0, 0, PI / 2), c8(0xecece8), "Fuselage")
	var nose := SphereMesh.new()
	nose.radius = 1.2
	nose.height = 3.4
	add.call(nose, Vector3(9.0, 0.05, 0), Vector3.ZERO, c8(0xecece8), "Nose")
	var hump := SphereMesh.new()
	hump.radius = 1.0
	hump.height = 1.6
	add.call(hump, Vector3(6.0, 0.9, 0), Vector3(0, 0, 0), c8(0xecece8), "UpperDeck")
	var tailcone := CylinderMesh.new()
	tailcone.top_radius = 1.1
	tailcone.bottom_radius = 0.3
	tailcone.height = 4
	add.call(tailcone, Vector3(-10.8, 0.3, 0), Vector3(0, 0, -PI / 2 - 0.08), c8(0xecece8), "TailCone")
	var wing := BoxMesh.new()
	wing.size = Vector3(4.0, 0.25, 22)
	add.call(wing, Vector3(0.5, -0.4, 0), Vector3(0, 0.35, 0), c8(0xd8d8d4), "Wings")
	var fin := BoxMesh.new()
	fin.size = Vector3(3.2, 4.2, 0.25)
	add.call(fin, Vector3(-10.2, 2.6, 0), Vector3(0, 0, 0.35), c8(0xa8453a), "Fin")
	var stab := BoxMesh.new()
	stab.size = Vector3(2.2, 0.2, 8)
	add.call(stab, Vector3(-10.5, 0.6, 0), Vector3(0, 0.3, 0), c8(0xd0d0cc), "Stabiliser")
	var stripe := BoxMesh.new()
	stripe.size = Vector3(15, 0.25, 2.46)
	add.call(stripe, Vector3(-0.5, 0.1, 0), Vector3.ZERO, c8(0xa8453a), "Cheatline")
	for zz in [-4.0, -7.5, 4.0, 7.5]:
		var eng := CylinderMesh.new()
		eng.top_radius = 0.5
		eng.bottom_radius = 0.45
		eng.height = 2.4
		add.call(eng, Vector3(1.2 - absf(zz) * 0.3, -1.0, zz), Vector3(0, 0, PI / 2), c8(0xc8c8c4), "Engine")
	# landing lights, on for the approach
	for zz in [-2.0, 2.0]:
		var l := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.2
		s.height = 0.4
		l.mesh = s
		l.material_override = b.emissive(Color(1, 0.95, 0.8), 12.0)
		l.position = Vector3(2.0, -0.6, zz)
		b.attach(l, p)
