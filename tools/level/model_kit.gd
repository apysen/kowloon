class_name ModelKit
extends RefCounted

## Modelled shapes for props, so nothing up close is a raw box or tube:
##
##   rbox     a box with rounded edges and corners (boards, cases, cabinets)
##   cushion  a soft rounded box that bellies out on top (mattresses, pillows)
##   lathe    a profile turned round the y axis (cups, bowls, woks, bottles, bulbs)
##   tube     a round section swept along a path, bends rounded (pipes, handles, hoses, wire)
##   slab     a polygon extruded and its edges softened (blades, shaped panels)
##   drape    a hanging sheet in soft folds (curtains, cloths)
##
## The world's surfaces are mapped triplanar in world space, so these meshes
## take wood, metal, fabric and the rest with a tint like any box. Each mesh
## is cached by its parameters and saved under assets/meshes/kit, so the
## level scene refers to it instead of carrying a copy per instance.

const DIR := "res://assets/meshes/kit"

static var _cache := {}
static var _cleared := false


# ----------------------------------------------------------------------------- placing


## Place a mesh: `pos` is its origin (meshes here are built centred, except
## lathes and slabs, which stand on y = 0), `basis` its turn.
static func place(b: LevelBuilder, mesh: Mesh, pos: Vector3, surface: String, tint: Color, opts := {}) -> MeshInstance3D:
	var o := opts.duplicate()
	o["tint"] = tint
	return b.piece(mesh, pos, b.surface(surface), o)


## A rounded box between two corners, axis-aligned, the drop-in for b.box().
static func box(b: LevelBuilder, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, tint: Color, opts := {}) -> MeshInstance3D:
	var size := Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0))
	var r: float = opts.get("radius", minf(0.012, size[_min_axis(size)] * 0.3))
	var o := opts.duplicate()
	o.erase("radius")
	var surface: String = o.get("surface", "grain")
	o.erase("surface")
	o["band"] = opts.get("band", b.band_of(minf(y0, y1) + 0.5))
	return place(b, rbox(size, r), Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5), surface, tint, o)


static func _min_axis(v: Vector3) -> int:
	return 0 if v.x <= v.y and v.x <= v.z else (1 if v.y <= v.z else 2)


# ----------------------------------------------------------------------------- cache


static func _cached(key: String, build: Callable) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	if not _cleared:
		# a fresh bake: drop the meshes the last one saved, so none go stale
		_cleared = true
		var abs := ProjectSettings.globalize_path(DIR)
		DirAccess.make_dir_recursive_absolute(abs)
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(abs.path_join(f))
	var m: ArrayMesh = build.call()
	var path := "%s/%s.res" % [DIR, key.md5_text().substr(0, 16)]
	ResourceSaver.save(m, path, ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_COMPRESS)
	_cache[key] = m
	return m


static func _q(v: float) -> String:
	return "%.4f" % v


# ----------------------------------------------------------------------------- rounded box and cushion


## Sample lines across one axis of a rounded box: the flat run between
## `n` steps round each edge, plus `inner` evenly spaced lines through the
## middle (a cushion needs them to belly out).
static func _samples(half: float, r: float, n: int, inner := 0) -> PackedFloat32Array:
	var core := half - r
	var out: Array[float] = []
	for k in range(n, 0, -1):
		var off := r * tan(k * PI * 0.25 / n)
		out.append(-core - off)
		out.append(core + off)
	out.append(-core)
	out.append(core)
	for k in range(1, inner + 1):
		out.append(-core + 2.0 * core * k / (inner + 1))
	out.sort()
	return PackedFloat32Array(out)


static func rbox(size: Vector3, r: float, segs := 3) -> ArrayMesh:
	r = clampf(r, 0.0005, size[_min_axis(size)] * 0.5 - 0.0002)
	var key := "rbox_%s_%s_%s_%s_%d" % [_q(size.x), _q(size.y), _q(size.z), _q(r), segs]
	return _cached(key, func() -> ArrayMesh: return _soft_box(size, r, segs, 0.0, 0.0, 0))


## A soft box: rounded by `r`, its top bellied up by `puff` and its sides
## bowed out by `bulge` in the middle (mattress, pillow, bedding, sacks).
static func cushion(size: Vector3, r: float, puff: float, bulge := 0.0) -> ArrayMesh:
	r = clampf(r, 0.001, size[_min_axis(size)] * 0.5 - 0.0002)
	var key := "cushion_%s_%s_%s_%s_%s_%s" % [_q(size.x), _q(size.y), _q(size.z), _q(r), _q(puff), _q(bulge)]
	return _cached(key, func() -> ArrayMesh: return _soft_box(size, r, 3, puff, bulge, 5))


static func _soft_box(size: Vector3, r: float, segs: int, puff: float, bulge: float, inner: int) -> ArrayMesh:
	var h := size * 0.5
	var core := h - Vector3.ONE * r
	var samples := [_samples(h.x, r, segs, inner), _samples(h.y, r, segs, mini(inner, 2)), _samples(h.z, r, segs, inner)]
	var soft := puff != 0.0 or bulge != 0.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in 3:
		var ua := (axis + 1) % 3
		var va := (axis + 2) % 3
		for sgn in [-1.0, 1.0]:
			var outward := Vector3.ZERO
			outward[axis] = sgn
			var us: PackedFloat32Array = samples[ua]
			var vs: PackedFloat32Array = samples[va]
			for i in us.size() - 1:
				for j in vs.size() - 1:
					var quad: Array[Vector3] = []
					var norms: Array[Vector3] = []
					for c in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
						var p := Vector3.ZERO
						p[axis] = sgn * h[axis]
						p[ua] = us[c[0]]
						p[va] = vs[c[1]]
						var k := p.clamp(-core, core)
						var d := p - k
						var n := outward
						if d.length() > 0.000001:
							n = d.normalized()
							p = k + n * r
						if soft:
							p = _puff(p, h, puff, bulge)
						quad.append(p)
						norms.append(n)
					_emit_quad(st, quad, norms, outward, not soft)
	if soft:
		st.generate_normals()
	st.index()
	return st.commit()


static func _puff(p: Vector3, h: Vector3, puff: float, bulge: float) -> Vector3:
	var fx := 1.0 - pow(clampf(p.x / h.x, -1, 1), 2)
	var fz := 1.0 - pow(clampf(p.z / h.z, -1, 1), 2)
	var fy := clampf((p.y / h.y + 1.0) * 0.5, 0, 1)
	var q := p
	q.y += puff * fx * fz * fy
	var side := 1.0 - pow(clampf(p.y / h.y, -1, 1), 2)
	q.x += signf(p.x) * bulge * side * fz
	q.z += signf(p.z) * bulge * side * fx
	return q


## Two triangles, wound so they face `outward` (clockwise seen from outside
## is a front face in Godot). With `normals`, the given normals are set.
static func _emit_quad(st: SurfaceTool, q: Array[Vector3], n: Array[Vector3], outward: Vector3, normals := true) -> void:
	var order := [0, 1, 2, 0, 2, 3]
	if (q[1] - q[0]).cross(q[2] - q[0]).dot(outward) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for k in order:
		if normals:
			st.set_normal(n[k])
		st.set_uv(Vector2(q[k].x + q[k].z, q[k].y))
		st.add_vertex(q[k])


# ----------------------------------------------------------------------------- lathe


## Turn a profile round the y axis. `profile` runs from the bottom centre
## out and up as (radius, y) points; a profile that comes back in and down
## (a cup's inside) gives a vessel with a wall. Corners sharper than about
## 35 degrees stay crisp; gentler ones are smoothed. `squash` scales x and z
## apart (an oval bowl, a squat pan).
static func lathe(profile: PackedVector2Array, segments := 24, squash := Vector2.ONE) -> ArrayMesh:
	var key := "lathe_%d_%s_%s" % [segments, _q(squash.x), _q(squash.y)]
	for p in profile:
		key += "_" + _q(p.x) + "," + _q(p.y)
	return _cached(key, func() -> ArrayMesh: return _lathe(profile, segments, squash))


static func _lathe(profile: PackedVector2Array, segments: int, squash: Vector2) -> ArrayMesh:
	var n := profile.size()
	# each segment's outward normal in the (r, y) plane
	var seg_n: Array[Vector2] = []
	for i in n - 1:
		var d := profile[i + 1] - profile[i]
		seg_n.append(Vector2(d.y, -d.x).normalized() if d.length() > 0.0 else Vector2.RIGHT)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n - 1:
		var a := profile[i]
		var c := profile[i + 1]
		if a.distance_to(c) < 0.00001:
			continue
		var na := seg_n[i]
		var nc := seg_n[i]
		if i > 0 and seg_n[i - 1].dot(seg_n[i]) > 0.82:
			na = (seg_n[i - 1] + seg_n[i]).normalized()
		if i < n - 2 and seg_n[i + 1].dot(seg_n[i]) > 0.82:
			nc = (seg_n[i + 1] + seg_n[i]).normalized()
		for s in segments:
			var t0 := TAU * s / segments
			var t1 := TAU * (s + 1) / segments
			var q: Array[Vector3] = [_ring(a, t0, squash), _ring(a, t1, squash), _ring(c, t1, squash), _ring(c, t0, squash)]
			var nn: Array[Vector3] = [_ring_n(na, t0, squash), _ring_n(na, t1, squash), _ring_n(nc, t1, squash), _ring_n(nc, t0, squash)]
			var mid := (nn[0] + nn[2]).normalized()
			if q[0].distance_to(q[1]) < 0.000001:
				# a point on the axis: one triangle
				_emit_tri(st, [q[0], q[2], q[3]], [nn[0], nn[2], nn[3]], mid)
			elif q[2].distance_to(q[3]) < 0.000001:
				_emit_tri(st, [q[0], q[1], q[2]], [nn[0], nn[1], nn[2]], mid)
			else:
				_emit_quad(st, q, nn, mid)
	st.index()
	return st.commit()


static func _ring(p: Vector2, t: float, sq: Vector2) -> Vector3:
	return Vector3(cos(t) * p.x * sq.x, p.y, sin(t) * p.x * sq.y)


static func _ring_n(n: Vector2, t: float, sq: Vector2) -> Vector3:
	return Vector3(cos(t) * n.x / sq.x, n.y, sin(t) * n.x / sq.y).normalized()


static func _emit_tri(st: SurfaceTool, q: Array, n: Array, outward: Vector3) -> void:
	var order := [0, 1, 2]
	if ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(outward) > 0.0:
		order = [0, 2, 1]
	for k in order:
		st.set_normal(n[k])
		st.set_uv(Vector2(q[k].x + q[k].z, q[k].y))
		st.add_vertex(q[k])


## A rounded profile helper: a cylinder of radius r and height h with its
## top and bottom edges rounded by e. Solid, stands on y = 0.
static func puck(r: float, h: float, e := 0.004, segments := 24) -> ArrayMesh:
	return lathe(rounded_profile([Vector2(0, 0), Vector2(r, 0), Vector2(r, h), Vector2(0, h)], e), segments)


## Round the inner corners of a lathe profile by e (each corner becomes a
## short arc), leaving the end points where they are.
static func rounded_profile(pts: Array, e: float, steps := 3) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(pts[0])
	for i in range(1, pts.size() - 1):
		var p: Vector2 = pts[i]
		var a: Vector2 = (pts[i - 1] - p)
		var c: Vector2 = (pts[i + 1] - p)
		var ee := minf(e, minf(a.length(), c.length()) * 0.45)
		var p0 := p + a.normalized() * ee
		var p1 := p + c.normalized() * ee
		for k in steps + 1:
			var t := float(k) / steps
			# a quadratic through the corner: close to an arc for right angles
			out.append(p0.lerp(p, t).lerp(p.lerp(p1, t), t))
	out.append(pts[pts.size() - 1])
	return out


# ----------------------------------------------------------------------------- tube


## A round section swept along `path`. Each bend is rounded with radius
## `bend` (0 for a sharp mitre). Open ends are capped unless `caps` is false.
static func tube(path: Array, radius: float, bend := 0.0, segments := 10, caps := true) -> ArrayMesh:
	var key := "tube_%s_%s_%d_%s" % [_q(radius), _q(bend), segments, caps]
	for p in path:
		key += "_%s,%s,%s" % [_q(p.x), _q(p.y), _q(p.z)]
	return _cached(key, func() -> ArrayMesh: return _tube(path, radius, bend, segments, caps))


static func _fillet(path: Array, bend: float) -> Array[Vector3]:
	var out: Array[Vector3] = [path[0]]
	for i in range(1, path.size() - 1):
		var p: Vector3 = path[i]
		var a: Vector3 = path[i - 1] - p
		var c: Vector3 = path[i + 1] - p
		var e := minf(bend, minf(a.length(), c.length()) * 0.45)
		if e <= 0.0 or absf(a.normalized().dot(c.normalized())) > 0.999:
			out.append(p)
			continue
		var p0 := p + a.normalized() * e
		var p1 := p + c.normalized() * e
		for k in 7:
			var t := k / 6.0
			out.append(p0.lerp(p, t).lerp(p.lerp(p1, t), t))
	out.append(path[path.size() - 1])
	return out


static func _tube(path: Array, radius: float, bend: float, segments: int, caps: bool) -> ArrayMesh:
	var pts := _fillet(path, bend)
	var n := pts.size()
	var tangents: Array[Vector3] = []
	for i in n:
		var t := Vector3.ZERO
		if i > 0:
			t += (pts[i] - pts[i - 1]).normalized()
		if i < n - 1:
			t += (pts[i + 1] - pts[i]).normalized()
		tangents.append(t.normalized())
	# parallel-transported frames, so the tube never twists
	var up := Vector3.UP if absf(tangents[0].dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var side := tangents[0].cross(up).normalized()
	var rings: Array = []
	for i in n:
		if i > 0:
			var axis := tangents[i - 1].cross(tangents[i])
			if axis.length() > 0.00001:
				side = side.rotated(axis.normalized(), tangents[i - 1].signed_angle_to(tangents[i], axis.normalized()))
		var other := tangents[i].cross(side).normalized()
		var ring: Array[Vector3] = []
		for s in segments:
			var t := TAU * s / segments
			ring.append(side * cos(t) + other * sin(t))
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n - 1:
		for s in segments:
			var s1 := (s + 1) % segments
			var dirs: Array[Vector3] = [rings[i][s], rings[i][s1], rings[i + 1][s1], rings[i + 1][s]]
			var q: Array[Vector3] = [pts[i] + dirs[0] * radius, pts[i] + dirs[1] * radius, pts[i + 1] + dirs[2] * radius, pts[i + 1] + dirs[3] * radius]
			_emit_quad(st, q, dirs, (dirs[0] + dirs[2]).normalized())
	if caps:
		for end in [0, n - 1]:
			var out := -tangents[0] if end == 0 else tangents[n - 1]
			for s in segments:
				var s1 := (s + 1) % segments
				_emit_tri(st, [pts[end], pts[end] + rings[end][s] * radius, pts[end] + rings[end][s1] * radius], [out, out, out], out)
	st.index()
	return st.commit()


# ----------------------------------------------------------------------------- slab


## A flat shape: `poly` (in x/y) extruded `depth` along z, centred on z = 0,
## its rim softened with a small chamfer so it catches light.
static func slab(poly: PackedVector2Array, depth: float, chamfer := 0.0) -> ArrayMesh:
	var key := "slab_%s_%s" % [_q(depth), _q(chamfer)]
	for p in poly:
		key += "_" + _q(p.x) + "," + _q(p.y)
	return _cached(key, func() -> ArrayMesh: return _slab(poly, depth, chamfer))


static func _slab(poly: PackedVector2Array, depth: float, chamfer: float) -> ArrayMesh:
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
	var inner := poly
	if chamfer > 0.0:
		# each corner moved in along its bisector, so the rim keeps the
		# outline's own vertex order (counter-clockwise: inward is the left)
		inner = PackedVector2Array()
		var m0 := poly.size()
		for i in m0:
			var e0 := (poly[i] - poly[(i - 1 + m0) % m0]).normalized()
			var e1 := (poly[(i + 1) % m0] - poly[i]).normalized()
			var n0 := Vector2(-e0.y, e0.x)
			var n1 := Vector2(-e1.y, e1.x)
			var bis := (n0 + n1).normalized()
			inner.append(poly[i] + bis * chamfer / maxf(0.3, bis.dot(n1)))
	var hz := depth * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := Geometry2D.triangulate_polygon(inner)
	for face in [1.0, -1.0]:
		var nrm := Vector3(0, 0, face)
		for t in range(0, tris.size(), 3):
			var q := [Vector3(inner[tris[t]].x, inner[tris[t]].y, hz * face), Vector3(inner[tris[t + 1]].x, inner[tris[t + 1]].y, hz * face),
				Vector3(inner[tris[t + 2]].x, inner[tris[t + 2]].y, hz * face)]
			_emit_tri(st, q, [nrm, nrm, nrm], nrm)
	var m := poly.size()
	for i in m:
		var j := (i + 1) % m
		var e := poly[j] - poly[i]
		var out2 := Vector2(e.y, -e.x).normalized()
		if Geometry2D.is_polygon_clockwise(poly):
			out2 = -out2
		var out := Vector3(out2.x, out2.y, 0)
		var zc := hz - chamfer
		var q: Array[Vector3] = [Vector3(poly[i].x, poly[i].y, -zc), Vector3(poly[j].x, poly[j].y, -zc), Vector3(poly[j].x, poly[j].y, zc), Vector3(poly[i].x, poly[i].y, zc)]
		_emit_quad(st, q, [out, out, out, out], out)
		if chamfer > 0.0:
			for face in [1.0, -1.0]:
				var n2 := (out + Vector3(0, 0, face)).normalized()
				var c: Array[Vector3] = [Vector3(poly[i].x, poly[i].y, zc * face), Vector3(poly[j].x, poly[j].y, zc * face),
					Vector3(inner[j].x, inner[j].y, hz * face), Vector3(inner[i].x, inner[i].y, hz * face)]
				_emit_quad(st, c, [n2, n2, n2, n2], n2)
	st.index()
	return st.commit()


# ----------------------------------------------------------------------------- drape


## A hanging sheet in soft folds, `width` along x, hanging `height` down
## from y = 0, `folds` waves deep `depth`, its hem swinging a little. The
## folds are sharper at the top where it is gathered and loosen toward the
## hem. Thickness `thick` gives it two sides and an edge.
static func drape(width: float, height: float, folds: int, depth: float, thick := 0.006, gather := 0.0) -> ArrayMesh:
	var key := "drape_%s_%s_%d_%s_%s_%s" % [_q(width), _q(height), folds, _q(depth), _q(thick), _q(gather)]
	return _cached(key, func() -> ArrayMesh: return _drape(width, height, folds, depth, thick, gather))


static func _drape(width: float, height: float, folds: int, depth: float, thick: float, gather: float) -> ArrayMesh:
	var nx := folds * 8
	var ny := 10
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var surf := func(u: float, v: float) -> Vector3:
		# u across 0..1, v down 0..1
		var x := (u - 0.5) * width * (1.0 - gather * (1.0 - v))
		var amp := depth * (0.65 + 0.35 * v)
		var z := sin(u * folds * TAU) * amp + sin(u * folds * 0.5 * TAU + 1.3) * amp * 0.25 * v
		return Vector3(x, -v * height + sin(u * 17.0) * 0.004 * v, z)
	for side in [1.0, -1.0]:
		for i in nx:
			for j in ny:
				var q: Array[Vector3] = []
				for c in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
					var p: Vector3 = surf.call(float(c[0]) / nx, float(c[1]) / ny)
					q.append(p + Vector3(0, 0, thick * 0.5 * side))
				var outward: Vector3 = (q[1] - q[0]).cross(q[3] - q[0]).normalized() * side
				if outward.z * side < 0.0:
					outward = -outward
				_emit_quad(st, q, [], outward, false)
	st.generate_normals()
	st.index()
	return st.commit()
