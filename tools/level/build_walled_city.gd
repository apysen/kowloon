class_name BuildWalledCity
extends RefCounted

## The Walled City laid out after the 1985 Kai Fong Association survey map.
##
## The City filled the old fort's plot, about 210 m east-west by 120 m
## north-south: a single mass of some 350 buildings, grown into each other and
## capped at thirteen or fourteen storeys by the Kai Tak approach, into a rough
## plateau of roofs. It was cut through not by roads but by alleys, most one to
## two metres wide, following the lines of the old fort:
##
##   north-south  Sai Shing Road (西城路) on the old west wall; Tai Ching Street
##                (大井街), named for the Big Well; Lo Yan Street (老人街), up
##                from Lung Chun Road to the yamen; Kwong Ming Street (光明街);
##                Lung Shing Road (龍城路), parallel to Tung Tsing Road, its north
##                mouth facing Tung Tau Tsuen Road; Yi Hok Lane (義學巷).
##   east-west    Lung Chun Road (龍津道), laid in 1951 along the base of the old
##                south wall; Lung Chun Street (龍津路), the ancient street on the
##                line of the gates, and its back street (龍津後街); Tin Hau
##                Temple Street (天后廟街) and She Kung Street (社公街) in the north.
##
## At the centre, the yamen (衙門), the 1847 magistrate's office, by then an
## old people's home: low grey halls in a courtyard, the one place in the City
## sunlight reached the ground. Outside the plot ran Tung Tau Tsuen Road (north,
## where the dentists' signs crowded the frontage), Tung Tsing Road (east),
## Carpenter Road (south) and Sai Tau Tsuen Road (west).
##
## Game axes: +x east, -z north, 1 unit = 1 m. Mei's building, with the route
## through it, stands east of the yamen between Kwong Ming Street and Lung Shing
## Road; build_city.gd's filler details that part, band by band. Everything
## else is seen only from the roof, so it is built for that view: merged masses,
## multimeshed cages and aerials, a handful of people.

## The plot of the City.
const CITY := {"x0": -145.0, "x1": 65.0, "z0": -65.0, "z1": 55.0}
## Mei's building and its neighbours, detailed by BuildCity.filler.
const NEAR := {"x0": -22.0, "x1": 38.0, "z0": -30.0, "z1": 8.0}
## The yamen's courtyard, open to the sky.
const YAMEN_COURT := {"x0": -54.0, "x1": -30.0, "z0": -16.0, "z1": 6.0}

## Alleys and streets, from the 1985 map (x0, x1, z0, z1).
const STREETS := [
	{"name": "Sai Shing Road", "zh": "西城路", "x0": -140.0, "x1": -137.8, "z0": -65.0, "z1": 55.0},
	{"name": "Tai Ching Street", "zh": "大井街", "x0": -92.0, "x1": -90.2, "z0": -65.0, "z1": 46.5},
	{"name": "Yi Hok Lane", "zh": "義學巷", "x0": -65.0, "x1": -63.8, "z0": -30.0, "z1": 18.0},
	{"name": "Lo Yan Street", "zh": "老人街", "x0": -41.0, "x1": -39.2, "z0": 6.0, "z1": 46.5},
	{"name": "Kwong Ming Street", "zh": "光明街", "x0": -26.5, "x1": -24.7, "z0": -65.0, "z1": 46.5},
	{"name": "Lung Shing Road", "zh": "龍城路", "x0": 48.0, "x1": 50.4, "z0": -65.0, "z1": 46.5},
	{"name": "Lung Chun Road", "zh": "龍津道", "x0": -145.0, "x1": 65.0, "z0": 43.0, "z1": 46.5},
	{"name": "Lung Chun Street", "zh": "龍津路", "x0": -145.0, "x1": 65.0, "z0": 18.0, "z1": 20.0},
	{"name": "Lung Chun Back Street", "zh": "龍津後街", "x0": -120.0, "x1": -26.5, "z0": 28.0, "z1": 29.4},
	{"name": "Tin Hau Temple Street", "zh": "天后廟街", "x0": -24.7, "x1": 65.0, "z0": -46.0, "z1": -44.4},
	{"name": "She Kung Street", "zh": "社公街", "x0": -137.8, "x1": -26.5, "z0": -40.0, "z1": -38.6},
	{"name": "Cheung On Lane", "zh": "長安里", "x0": -120.0, "x1": -92.0, "z0": -25.0, "z1": -23.8},
	{"name": "Cheung Hing Lane", "zh": "長興里", "x0": 38.0, "x1": 65.0, "z0": 30.0, "z1": 31.2},
]

const GROUND := -0.4
const ROOF_P := "City/WalledCity"

# occupancy at 1 m: -1 open (street, court, outside), -2 Mei's quarter, >= 0 plot index
static var _occ: PackedInt32Array
static var _nx := 0
static var _nz := 0


static func c8(hex: int) -> Color:
	return LevelBuilder.c8(hex)


static func build(b: LevelBuilder) -> void:
	var plots := _plots(b)
	_mass(b, plots)
	_dress(b, plots)
	_roofs(b, plots)
	_yamen(b)
	_dentists(b, plots)


# ----------------------------------------------------------------------------- occupancy


static func _cell(i: int, j: int) -> int:
	if i < 0 or j < 0 or i >= _nx or j >= _nz:
		return -1
	return _occ[j * _nx + i]


static func _open_at(x: float, z: float) -> bool:
	return _cell(floori(x - float(CITY.x0)), floori(z - float(CITY.z0))) == -1


static func _inside(x0: float, x1: float, z0: float, z1: float, r: Dictionary) -> bool:
	return x0 < float(r.x1) - 0.01 and x1 > float(r.x0) + 0.01 and z0 < float(r.z1) - 0.01 and z1 > float(r.z0) + 0.01


## Lay the plots: every metre of the City not an alley, the courtyard or Mei's
## quarter belongs to a building. Buildings are grown greedily, three to nine
## metres a side, so they butt up against each other the way the City's did.
static func _plots(b: LevelBuilder) -> Array[Dictionary]:
	var streets := _jogged(b)
	_nx = int(CITY.x1 - CITY.x0)
	_nz = int(CITY.z1 - CITY.z0)
	_occ = PackedInt32Array()
	_occ.resize(_nx * _nz)
	for j in _nz:
		for i in _nx:
			var x: float = float(CITY.x0) + i + 0.5
			var z: float = float(CITY.z0) + j + 0.5
			var v := -3
			if _inside(x - 0.5, x + 0.5, z - 0.5, z + 0.5, NEAR):
				v = -2
			elif _inside(x - 0.5, x + 0.5, z - 0.5, z + 0.5, YAMEN_COURT):
				v = -1
			else:
				for s in streets:
					if x > float(s.x0) and x < float(s.x1) and z > float(s.z0) and z < float(s.z1):
						v = -1
						break
			_occ[j * _nx + i] = v
	var plots: Array[Dictionary] = []
	for j in _nz:
		for i in _nx:
			if _occ[j * _nx + i] != -3:
				continue
			var want_w := 3 + b.rand.randi() % 7
			var want_d := 3 + b.rand.randi() % 7
			var w := 1
			while w < want_w and i + w < _nx and _occ[j * _nx + i + w] == -3:
				w += 1
			var d := 1
			var ok := true
			while ok and d < want_d and j + d < _nz:
				for k in w:
					if _occ[(j + d) * _nx + i + k] != -3:
						ok = false
						break
				if ok:
					d += 1
			var idx := plots.size()
			for c in d:
				for a in w:
					_occ[(j + c) * _nx + i + a] = idx
			var h := 10.6 + b.rand.randf() * 5.2
			if b.rand.randf() < 0.07:
				h = 4.5 + b.rand.randf() * 3.5      # an old low house, not yet rebuilt
			var px: float = float(CITY.x0) + i
			var pz: float = float(CITY.z0) + j
			plots.append({"x0": px, "x1": px + w, "z0": pz, "z1": pz + d, "h": h,
				"style": b.rand.randi() % 32})
	return plots


## No alley in the City ran true: buildings rebuilt one at a time pushed the
## lines about. Each street is cut into lengths of 12 to 30 m, and each length
## is nudged sideways by up to a metre (overlapping its neighbours, so the
## alley stays passable, with the kink opened across both lines).
static func _jogged(b: LevelBuilder) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in STREETS:
		var x0: float = s.x0
		var x1: float = s.x1
		var z0: float = s.z0
		var z1: float = s.z1
		var along_z := (z1 - z0) > (x1 - x0)
		var a := z0 if along_z else x0
		var end := z1 if along_z else x1
		var width := (x1 - x0) if along_z else (z1 - z0)
		var shift := 0.0
		var first := true
		while a < end - 0.01:
			var seg := minf(end, a + 12.0 + b.rand.randf() * 18.0)
			if end - seg < 6.0:
				seg = end
			var prev := shift
			if not first and seg < end and width >= 1.7:
				shift = clampf(prev + float(b.rand.randi() % 3 - 1), -1.0, 1.0)
			if along_z:
				out.append({"x0": x0 + shift, "x1": x1 + shift, "z0": a, "z1": seg})
				if shift != prev:
					# the kink: open across both lines for a couple of metres
					out.append({"x0": x0 + minf(prev, shift), "x1": x1 + maxf(prev, shift), "z0": a - 1.0, "z1": a + 1.0})
			else:
				out.append({"x0": a, "x1": seg, "z0": z0 + shift, "z1": z1 + shift})
				if shift != prev:
					out.append({"x0": a - 1.0, "x1": a + 1.0, "z0": z0 + minf(prev, shift), "z1": z1 + maxf(prev, shift)})
			first = false
			a = seg
	return out


# ----------------------------------------------------------------------------- the mass


## All the buildings, merged by facade and tint into a few dozen meshes. The
## surface shader is triplanar in world space, so merging changes nothing.
static func _mass(b: LevelBuilder, plots: Array[Dictionary]) -> void:
	var holder := Node3D.new()
	holder.name = "Mass"
	b.attach(holder, b.group(ROOF_P))
	b.tag(holder, 1.5)
	var groups := {}
	for p in plots:
		(groups.get_or_add(int(p.style), []) as Array).append(p)
	for style in groups:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for p in groups[style]:
			var size := Vector3(float(p.x1) - float(p.x0) - 0.06, float(p.h) - GROUND, float(p.z1) - float(p.z0) - 0.06)
			var bm := BoxMesh.new()
			bm.size = size
			var c := Vector3((float(p.x0) + float(p.x1)) * 0.5, (GROUND + float(p.h)) * 0.5, (float(p.z0) + float(p.z1)) * 0.5)
			st.append_from(bm, 0, Transform3D(Basis.IDENTITY, c))
		var mi := MeshInstance3D.new()
		mi.name = "Buildings%02d" % int(style)
		mi.mesh = st.commit()
		var facade: String = BuildCity.FACADES[int(style) % BuildCity.FACADES.size()]
		mi.material_override = b.surface(facade, "tar")
		mi.set_instance_shader_parameter("tint", c8(BuildCity.FACADE_TINTS[(int(style) >> 2) % BuildCity.FACADE_TINTS.size()]))
		mi.set_instance_shader_parameter("uv_offset", _off_of(int(style)))
		mi.set_instance_shader_parameter("emission_scale", 0.6 + b.rand.randf() * 0.8)
		b.attach(mi, holder)


static func _off_of(style: int) -> Vector2:
	return Vector2(float(style % 6) / 6.0, float(floori(style / 6.0) % 2) / 2.0)


# ----------------------------------------------------------------------------- faces


## A face is dressed only where it looks onto open air wide enough to be seen
## from a roof: the boundary roads, the wider streets, the yamen's court.
## One-metre alleys stay what they were: dark slots.
static func _face_wide(p: Dictionary, face: String) -> bool:
	var x0: float = p.x0
	var x1: float = p.x1
	var z0: float = p.z0
	var z1: float = p.z1
	var samples := []
	match face:
		"n":
			for x in range(int(x0), int(x1)):
				samples.append([x + 0.5, z0 - 0.5, 0.0, -1.0])
		"s":
			for x in range(int(x0), int(x1)):
				samples.append([x + 0.5, z1 + 0.5, 0.0, 1.0])
		"e":
			for z in range(int(z0), int(z1)):
				samples.append([x1 + 0.5, z + 0.5, 1.0, 0.0])
		"w":
			for z in range(int(z0), int(z1)):
				samples.append([x0 - 0.5, z + 0.5, -1.0, 0.0])
	for s in samples:
		# open for at least two metres straight out
		for k in 2:
			if not _open_at(float(s[0]) + float(s[2]) * k, float(s[1]) + float(s[3]) * k):
				return false
	return true


static func _dress(b: LevelBuilder, plots: Array[Dictionary]) -> void:
	var holder := Node3D.new()
	holder.name = "Dressing"
	b.attach(holder, b.group(ROOF_P))
	b.tag(holder, 1.5)
	var cages := {}
	var acs := []
	var poles := []
	var cloths := [[], [], [], []]
	for p in plots:
		var facade: String = BuildCity.FACADES[int(p.style) % BuildCity.FACADES.size()]
		var off := _off_of(int(p.style))
		var faces := {"s": [p.z1, p.x0, p.x1], "n": [p.z0, p.x0, p.x1], "e": [p.x1, p.z0, p.z1], "w": [p.x0, p.z0, p.z1]}
		for face in faces:
			if not _face_wide(p, face):
				continue
			var f: Array = faces[face]
			for w in BuildCity.face_windows(facade, off, face, float(f[1]), float(f[2]), GROUND + 2.5, float(p.h)):
				var u: float = (float(w.u0) + float(w.u1)) * 0.5
				var ww: float = float(w.u1) - float(w.u0) + 0.2
				if b.rand.randf() < 0.6:
					var mesh := BuildCity.cage_mesh(snappedf(ww, 0.05), snappedf(float(w.y1) - float(w.y0) + 0.2, 0.05), 0.42, 8, b.rand.randi() % 3)
					(cages.get_or_add(mesh, []) as Array).append(BuildCity.face_xform(face, float(f[0]), u, float(w.y0) - 0.08))
				if b.rand.randf() < 0.35:
					acs.append(BuildCity.face_xform(face, float(f[0]), u + (b.rand.randf() - 0.5) * 0.6, float(w.y0) - 0.75))
				if b.rand.randf() < 0.2:
					poles.append(BuildCity.face_xform(face, float(f[0]), u - ww * 0.3, float(w.y0) + 0.05))
					poles.append(BuildCity.face_xform(face, float(f[0]), u + ww * 0.3, float(w.y0) + 0.05))
					for k in 2 + b.rand.randi() % 3:
						var xf := BuildCity.face_xform(face, float(f[0]), u + (k - 1.0) * 0.28, float(w.y0) - 0.4)
						(cloths[b.rand.randi() % 4] as Array).append(xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.55 + b.rand.randf() * 0.15)))
	var metal := b.surface("metal")
	var i := 0
	for mesh in cages:
		BuildCity.multimesh(b, mesh, cages[mesh], metal, c8(0x47443e) if i % 2 == 0 else c8(0x6a5a48), holder, "Cages%d" % i, false)
		i += 1
	BuildCity.multimesh(b, BuildCity.ac_mesh(), acs, metal, c8(0xc8c6be), holder, "AirCons", false)
	BuildCity.multimesh(b, BuildCity.pole_mesh(0.9), poles, metal, c8(0x5a5a55), holder, "Poles", false)
	var cm := BuildCity.merged("cloth", [[Vector3(0, 0.22, 0), Vector3(0.24, 0.44, 0.02)]])
	var cols := [c8(0xc9463a), c8(0x3f6fa8), c8(0xe8e2d4), c8(0xd8b040)]
	for g in 4:
		BuildCity.multimesh(b, cm, cloths[g], b.surface("fabric"), cols[g], holder, "Laundry%d" % g, false)


# ----------------------------------------------------------------------------- roofs


static func _aerial_mesh(h: float, arms: int) -> ArrayMesh:
	var boxes := [[Vector3(0, h / 2, 0), Vector3(0.06, h, 0.06)]]
	for k in arms:
		var y := h - 0.2 - k * 0.45
		var w := 0.7 - k * 0.12
		boxes.append([Vector3(0, y, 0), Vector3(2 * w, 0.03, 0.03)])
		for e in 4:
			boxes.append([Vector3(-w + e * (2 * w) / 3.0, y, 0.02), Vector3(0.02, 0.02, 0.55)])
	return BuildCity.merged("aerial_%.1f_%d" % [h, arms], boxes)


static func _tank_mesh() -> ArrayMesh:
	var key := "roof_tank"
	if BuildCity._mesh_cache.has(key):
		return BuildCity._mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.6
	cyl.height = 1.1
	cyl.radial_segments = 12
	st.append_from(cyl, 0, Transform3D(Basis.IDENTITY, Vector3(0, 1.35, 0)))
	for dx in [-0.4, 0.4]:
		for dz in [-0.4, 0.4]:
			var leg := BoxMesh.new()
			leg.size = Vector3(0.08, 0.8, 0.08)
			st.append_from(leg, 0, Transform3D(Basis.IDENTITY, Vector3(dx, 0.4, dz)))
	var m := st.commit()
	BuildCity._mesh_cache[key] = m
	return m


## The roofscape: parapets, the forest of aerials, tanks, huts and lofts,
## washing, and a few people up for the air and the planes.
static func _roofs(b: LevelBuilder, plots: Array[Dictionary]) -> void:
	var holder := Node3D.new()
	holder.name = "Roofs"
	b.attach(holder, b.group(ROOF_P))
	b.tag(holder, 1.5)
	var lips := SurfaceTool.new()
	lips.begin(Mesh.PRIMITIVE_TRIANGLES)
	var huts := SurfaceTool.new()
	huts.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hut_roofs := SurfaceTool.new()
	hut_roofs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lofts := SurfaceTool.new()
	lofts.begin(Mesh.PRIMITIVE_TRIANGLES)
	var aerials := {}
	var tanks := []
	var line_posts := []
	var washing := [[], [], [], [], []]
	var add_box := func(st: SurfaceTool, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> void:
		var bm := BoxMesh.new()
		bm.size = Vector3(x1 - x0, y1 - y0, z1 - z0)
		st.append_from(bm, 0, Transform3D(Basis.IDENTITY, Vector3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)))
	var people := 0
	for p in plots:
		var x0: float = float(p.x0) + 0.03
		var x1: float = float(p.x1) - 0.03
		var z0: float = float(p.z0) + 0.03
		var z1: float = float(p.z1) - 0.03
		var y: float = p.h
		var w := x1 - x0
		var d := z1 - z0
		add_box.call(lips, x0, x1, y, y + 0.35, z0, z0 + 0.12)
		add_box.call(lips, x0, x1, y, y + 0.35, z1 - 0.12, z1)
		add_box.call(lips, x0, x0 + 0.12, y, y + 0.35, z0, z1)
		add_box.call(lips, x1 - 0.12, x1, y, y + 0.35, z0, z1)
		var n_aer := int(w * d / 14.0) + b.rand.randi() % 2
		for k in n_aer:
			var h := [2.2, 3.0, 3.8][b.rand.randi() % 3] as float
			var arms := 2 + b.rand.randi() % 2
			var mesh := _aerial_mesh(h, arms)
			var pos := Vector3(x0 + 0.3 + b.rand.randf() * maxf(0.1, w - 0.6), y, z0 + 0.3 + b.rand.randf() * maxf(0.1, d - 0.6))
			(aerials.get_or_add(mesh, []) as Array).append(Transform3D(Basis(Vector3.UP, b.rand.randf() * PI), pos))
		var r := b.rand.randf()
		if r < 0.18 and w > 2.2 and d > 2.2:
			var hw := minf(w - 0.4, 1.6 + b.rand.randf())
			var hd := minf(d - 0.4, 1.4 + b.rand.randf())
			add_box.call(huts, x0 + 0.2, x0 + 0.2 + hw, y, y + 2.1, z0 + 0.2, z0 + 0.2 + hd)
			add_box.call(hut_roofs, x0 + 0.1, x0 + 0.3 + hw, y + 2.1, y + 2.16, z0 + 0.1, z0 + 0.3 + hd)
		elif r < 0.38:
			tanks.append(Transform3D(Basis.IDENTITY, Vector3(x0 + w * 0.5, y, z0 + d * 0.5)))
		elif r < 0.44 and w > 2.2:
			add_box.call(lofts, x0 + 0.3, x0 + 1.9, y, y + 1.3, z0 + 0.3, z0 + 1.2)
		if b.rand.randf() < 0.25 and w > 2.0:
			var lz := z0 + d * (0.3 + b.rand.randf() * 0.4)
			line_posts.append(Transform3D(Basis.IDENTITY, Vector3(x0 + 0.3, y, lz)))
			line_posts.append(Transform3D(Basis.IDENTITY, Vector3(x1 - 0.3, y, lz)))
			var cx := x0 + 0.5
			while cx < x1 - 0.7:
				var cw := 0.3 + b.rand.randf() * 0.35
				var ch := 0.4 + b.rand.randf() * 0.5
				var xf := Transform3D(Basis.IDENTITY.scaled(Vector3(cw, ch, 1.0)), Vector3(cx + cw / 2, y + 1.85 - ch / 2, lz))
				(washing[b.rand.randi() % 5] as Array).append(xf)
				cx += cw + 0.08
		# somebody up for the air, mostly within sight of Mei's roof
		var near_mei := Vector2((x0 + x1) / 2 - 4.0, (z0 + z1) / 2 + 15.0).length() < 75.0
		if people < 34 and b.rand.randf() < (0.08 if near_mei else 0.015) and w > 1.6 and d > 1.6:
			people += 1
			var who: String = BuildCity.EXTRAS[b.rand.randi() % BuildCity.EXTRAS.size()]
			var anim := "point" if who.begins_with("ext_kid") and b.rand.randf() < 0.6 else "work"
			var pos := Vector3(x0 + 0.6 + b.rand.randf() * (w - 1.2), y, z0 + 0.6 + b.rand.randf() * (d - 1.2))
			var res := b.resident("city_roof_%d" % people, who, pos, {"anim": anim, "collide": false, "story": false,
				"parent": "City/People", "facing": Vector3(b.rand.randf() - 0.5, 0, b.rand.randf() - 0.5).normalized()})
			b.tag(res, 1.5)
	_merged_piece(b, lips, b.surface("concrete"), c8(0x8a867c), holder, "Parapets")
	_merged_piece(b, huts, b.surface("plaster"), c8(0xa8a292), holder, "Huts")
	_merged_piece(b, hut_roofs, b.surface("rust"), c8(0x9aa0a0), holder, "HutRoofs")
	_merged_piece(b, lofts, b.surface("wood"), c8(0x6b4a30), holder, "PigeonLofts")
	var metal := b.surface("metal")
	var i := 0
	for mesh in aerials:
		BuildCity.multimesh(b, mesh, aerials[mesh], metal, c8(0x3a3a3a), holder, "Aerials%d" % i, false)
		i += 1
	BuildCity.multimesh(b, _tank_mesh(), tanks, b.surface("rust"), c8(0xa0a8a8), holder, "Tanks", true)
	BuildCity.multimesh(b, BuildCity.merged("line_post", [[Vector3(0, 0.95, 0), Vector3(0.05, 1.9, 0.05)]]), line_posts, metal, c8(0x5a5a55), holder, "LinePosts", false)
	var sheet := BuildCity.merged("unit_sheet", [[Vector3.ZERO, Vector3(1, 1, 0.02)]])
	var wcols := [c8(0xe8e2d4), c8(0xc9463a), c8(0x3f6fa8), c8(0xd8b040), c8(0xe0a0b0)]
	for g in 5:
		BuildCity.multimesh(b, sheet, washing[g], b.surface("fabric"), wcols[g], holder, "Washing%d" % g, false)


static func _merged_piece(b: LevelBuilder, st: SurfaceTool, mat: Material, tint: Color, parent: Node3D, pname: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = pname
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.set_instance_shader_parameter("tint", tint)
	b.attach(mi, parent)


# ----------------------------------------------------------------------------- the yamen


## The yamen: two single-storey halls of grey brick under grey tile, joined by
## side corridors round a small court, set in the one open space in the City.
static func _yamen(b: LevelBuilder) -> void:
	var P := ROOF_P + "/Yamen"
	var o := {"band": 1.5, "parent": P}
	var ct: Dictionary = YAMEN_COURT
	var paving := o.duplicate()
	paving.merge({"surface": "concrete", "name": "Courtyard", "cast_shadow": false})
	b.box(ct.x0, ct.x1, GROUND, GROUND + 0.06, ct.z0, ct.z1, c8(0x8a8478), paving)
	var brick := c8(0x8e8c84)
	var tile := c8(0x4a4c4a)
	for hall in [[-12.5, -7.5, "RearHall"], [-3.0, 2.0, "FrontHall"]]:
		var z0: float = hall[0]
		var z1: float = hall[1]
		var wall := o.duplicate()
		wall.merge({"surface": "plaster", "name": String(hall[2])})
		b.box(-48.0, -36.0, GROUND, GROUND + 3.4, z0, z1, brick, wall)
		# the pitched roof: a prism with its ridge running east-west, eaves overhanging
		var prism := PrismMesh.new()
		prism.size = Vector3(z1 - z0 + 1.2, 1.7, 13.0)
		var roof := b.piece(prism, Vector3(-42.0, GROUND + 3.4 + 0.85, (z0 + z1) / 2), b.surface("tiles"), {"band": 1.5, "parent": P, "name": "TileRoof", "tint": tile})
		roof.rotation.y = PI / 2
		var ridge := o.duplicate()
		ridge.merge({"surface": "concrete", "name": "Ridge"})
		b.box(-48.6, -35.4, GROUND + 5.05, GROUND + 5.3, (z0 + z1) / 2 - 0.15, (z0 + z1) / 2 + 0.15, c8(0x3a3c3a), ridge)
		# the doors on the courtyard side: red, with a plaque over the front one
		var door := o.duplicate()
		door.merge({"surface": "wood", "name": "Door"})
		b.box(-43.0, -41.0, GROUND, GROUND + 2.6, z1, z1 + 0.06, c8(0x8a2e24), door)
	for side in [[-48.0, -46.6], [-37.4, -36.0]]:
		var corridor := o.duplicate()
		corridor.merge({"surface": "plaster", "name": "SideCorridor"})
		b.box(side[0], side[1], GROUND, GROUND + 2.8, -7.5, -3.0, brick, corridor)
		var croof := o.duplicate()
		croof.merge({"surface": "tiles", "name": "CorridorRoof"})
		b.box(float(side[0]) - 0.2, float(side[1]) + 0.2, GROUND + 2.8, GROUND + 3.0, -7.7, -2.8, tile, croof)
	var plaque := o.duplicate()
	plaque.merge({"surface": "wood", "name": "Plaque"})
	b.box(-43.2, -40.8, GROUND + 2.75, GROUND + 3.25, 2.06, 2.12, c8(0x2a2420), plaque)
	# the old cannons and a bench in the court; residents of the home sitting out
	var bench := o.duplicate()
	bench.merge({"surface": "wood", "name": "Bench"})
	b.box(-47.0, -45.0, GROUND, GROUND + 0.45, 3.0, 3.5, c8(0x6b4a30), bench)
	for k in 2:
		var cannon := CylinderMesh.new()
		cannon.top_radius = 0.12
		cannon.bottom_radius = 0.2
		cannon.height = 1.6
		var cn := b.piece(cannon, Vector3(-39.0 + k * 1.6, GROUND + 0.25, 4.2), b.surface("rust"), {"band": 1.5, "parent": P, "name": "Cannon", "tint": c8(0x3a3632)})
		cn.rotation = Vector3(PI / 2, 0, 0)
	for k in 3:
		var who: String = ["ext_grandma_black", "ext_birdcage_man", "ext_fan_woman"][k]
		var res := b.resident("yamen_%d" % k, who, Vector3(-46.6 + k * 1.1, GROUND, 3.9 + (k % 2) * 0.3),
			{"anim": "work", "collide": false, "story": false, "parent": "City/People", "facing": Vector3(0, 0, -1)})
		b.tag(res, 1.5)


# ----------------------------------------------------------------------------- the dentists


## Tung Tau Tsuen Road: the City's north face, crowded with the boards of
## unlicensed dentists (the City's cheapest teeth) and a few shop lightboxes.
static func _dentists(b: LevelBuilder, plots: Array[Dictionary]) -> void:
	var holder := Node3D.new()
	holder.name = "TungTauTsuenRoadSigns"
	b.attach(holder, b.group(ROOF_P))
	b.tag(holder, 1.5)
	var frontage := plots.filter(func(p: Dictionary) -> bool: return is_equal_approx(float(p.z0), float(CITY.z0)) and float(p.h) > 8.0)
	var placed := 0
	for p in frontage:
		var x0: float = p.x0
		var x1: float = p.x1
		var x := x0 + 0.6
		while x < x1 - 0.6:
			if b.rand.randf() < 0.55:
				var dentist := b.rand.randf() < 0.7
				var tex := "res://assets/textures/props/%s.png" % (("sign_dentist_%d" % (placed % 6)) if dentist else ("neon_%d" % (placed % 12)))
				var h := 1.4 + b.rand.randf() * 0.8
				var y := 2.2 + b.rand.randf() * (float(p.h) - h - 3.0)
				var pos := Vector3(x, y + h / 2, float(CITY.z0) - 0.35)
				var box := b.box(pos.x - 0.03, pos.x + 0.03, pos.y - h / 2, pos.y + h / 2, pos.z - 0.25, pos.z + 0.25, c8(0x201418),
					{"surface": "metal", "parent_node": holder, "name": "SignBox", "cast_shadow": false})
				box.remove_meta("band")
				for sgn in [-1.0, 1.0]:
					var c := b.card(tex, pos, Vector2(0.5, h), Vector3(sgn, 0, 0),
						{"parent_node": holder, "untagged": true, "name": "SignFace", "emission": 0.0 if dentist else 1.6})
					c.position = pos + Vector3(sgn * 0.035, 0, 0)
				placed += 1
			x += 1.3 + b.rand.randf() * 1.2
