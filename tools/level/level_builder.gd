class_name LevelBuilder
extends RefCounted

## Builds the slice's level as a node tree plus its LevelData.
##
## Coordinates, rooms and routes are the Three.js slice's, unchanged, so the
## perspective puzzles and the pacing carry over exactly. What is new is the
## finish: every surface is an HD material, rooms have skirting, dados, frames
## and fixtures, furniture is built from parts, and the city around the route
## is dressed down to the window cages.
##
## Three stacked levels share one footprint:
##   Level A  y = 0   apartment, hall, hidden corridor, Lau's clinic
##   Level B  y = 5   landing, Chan's room, airshaft base, catwalk, Mrs. Wong
##   Roof     y = 13  Mr. Ng's pigeons, water tank, laundry lines
##
## Every drawn piece carries metadata the world reads at runtime:
##   band      which cutaway band it belongs to (0, 1, 1.5, 2)
##   fadeable  whether it fades when it stands between Mei and the camera
##   room      the closed room whose shell it is part of
##   is_lid / is_floor / filler

const RESIDENT_SCENE := preload("res://scenes/characters/resident.tscn")

const GRID := 2.0
const LEVEL_A := 0.0
const LEVEL_B := 5.0
const LEVEL_ROOF := 13.0

var root: Node3D
var data: LevelData
var rand := RandomNumberGenerator.new()
var _groups: Dictionary = {}
var _emissive_cache: Dictionary = {}
var _mesh_cache: Dictionary = {}
var filler_blocks: Array[Dictionary] = []
var _room_count := 0
var _box_count := 0


func _init() -> void:
	rand.seed = 1993
	root = Node3D.new()
	root.name = "Level"
	data = LevelData.new()


# ----------------------------------------------------------------------------- tree


## A grouping node at a slash path under the level ("Structure/LevelA/Hall").
func group(path: String) -> Node3D:
	if path == "":
		return root
	if _groups.has(path):
		return _groups[path]
	var parts := path.split("/")
	var parent := root
	var acc := ""
	for p in parts:
		acc = p if acc == "" else acc + "/" + p
		if not _groups.has(acc):
			var n := Node3D.new()
			n.name = p
			parent.add_child(n)
			n.owner = root
			_groups[acc] = n
		parent = _groups[acc]
	return parent


func attach(node: Node, parent: Node) -> void:
	parent.add_child(node, true)
	_own(node)


func _own(node: Node) -> void:
	if node != root:
		node.owner = root
	for c in node.get_children():
		_own(c)


static func c8(hex: int) -> Color:
	return Color.hex((hex << 8) | 0xff)


func band_of(y: float) -> float:
	return PerspectiveRules.band_of(y)


# ----------------------------------------------------------------------------- data


func add_floor(x0: float, x1: float, z0: float, z1: float, y: float, floor_name := "") -> void:
	data.floors.append({"x0": minf(x0, x1), "x1": maxf(x0, x1), "z0": minf(z0, z1), "z1": maxf(z0, z1), "y": y, "name": floor_name})


func add_obstacle(x0: float, x1: float, z0: float, z1: float, y: float, obstacle_name := "", key := "") -> void:
	data.obstacles.append({"x0": minf(x0, x1), "x1": maxf(x0, x1), "z0": minf(z0, z1), "z1": maxf(z0, z1),
		"y": y, "name": obstacle_name, "key": key})


func ref(ref_name: String, pos: Vector3) -> void:
	data.refs[ref_name] = pos
	var m := Marker3D.new()
	m.name = ref_name
	m.position = pos
	m.gizmo_extents = 0.4
	attach(m, group("Markers"))


# ----------------------------------------------------------------------------- materials


func surface(surface_name: String, top := "") -> Material:
	return SurfaceLibrary.get_material(surface_name, top)


## A glowing material for lamps, tubes, signs and embers.
func emissive(color: Color, energy := 2.0, unshaded := true) -> StandardMaterial3D:
	var k := "%s_%.2f_%s" % [color.to_html(), energy, unshaded]
	if _emissive_cache.has(k):
		return _emissive_cache[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_emissive_cache[k] = m
	return m


## A textured card material (signs, posters, calendars): lit, alpha-scissored.
func card_material(tex_path: String, emission := 0.0, unshaded := false) -> StandardMaterial3D:
	var k := tex_path + str(emission) + str(unshaded)
	if _emissive_cache.has(k):
		return _emissive_cache[k]
	var m := StandardMaterial3D.new()
	var t: Texture2D = load(tex_path)
	m.albedo_texture = t
	m.roughness = 0.85
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if emission > 0.0:
		m.emission_enabled = true
		m.emission_texture = t
		m.emission_energy_multiplier = emission
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_emissive_cache[k] = m
	return m


# ----------------------------------------------------------------------------- primitives


func _box_mesh(size: Vector3) -> BoxMesh:
	var k := "%.3f_%.3f_%.3f" % [size.x, size.y, size.z]
	if _mesh_cache.has(k):
		return _mesh_cache[k]
	var m := BoxMesh.new()
	m.size = size
	_mesh_cache[k] = m
	return m


## Axis-aligned box from extents, textured with a surface and tinted by colour.
##   opts: surface, top, top_tint, band, fadeable, room, collide, collide_y, name,
##         parent, cast_shadow, base_y, material, uv_random, key, filler
func box(x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, color: Color, opts := {}) -> MeshInstance3D:
	# Every box is a hair larger than asked, each by its own amount (one of 101
	# steps from 0.06 to 6 mm): boxes laid flush against each other (a leg
	# under an apron, a nosing on a step, two rooms' walls) then never share a
	# face exactly, which the renderer cannot order and draws as flicker when
	# the view moves. The depth buffer (reversed float) tells 0.06 mm apart
	# at any distance the game shows.
	var grow := 0.00006 * float((_box_count * 37) % 101 + 1)
	_box_count += 1
	var size := Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)) + Vector3.ONE * 2.0 * grow
	var mi := MeshInstance3D.new()
	mi.name = opts.get("name", "Box")
	mi.mesh = _box_mesh(size)
	mi.position = Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5)
	if opts.has("material"):
		mi.material_override = opts.material
	else:
		var s: String = opts.get("surface", "grain")
		if s == "":
			s = "grain"
		mi.material_override = surface(s, opts.get("top", ""))
		mi.set_instance_shader_parameter("tint", color)
		if opts.has("base_y"):
			mi.set_instance_shader_parameter("base_y", opts.base_y)
		if opts.get("uv_random", false):
			mi.set_instance_shader_parameter("uv_offset", Vector2(rand.randf(), rand.randf()))
		elif opts.has("uv_offset"):
			mi.set_instance_shader_parameter("uv_offset", opts.uv_offset)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if opts.get("cast_shadow", true) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var parent: Node = opts.get("parent_node", null)
	if parent == null:
		parent = group(opts.get("parent", "Structure/Misc"))
	attach(mi, parent)
	tag(mi, opts.get("band", band_of(minf(y0, y1) + 0.5)), opts.get("fadeable", false), opts)
	if opts.get("collide", false):
		add_obstacle(x0, x1, z0, z1, opts.get("collide_y", minf(y0, y1)), mi.name, opts.get("key", ""))
	return mi


## Tag a node as a level piece for the runtime cutaway.
func tag(node: Node3D, band: float, fadeable := false, opts := {}) -> void:
	node.set_meta("band", band)
	node.set_meta("fadeable", fadeable)
	if opts.get("room", "") != "":
		node.set_meta("room", opts.room)
	for k in ["is_lid", "is_floor", "filler", "dynamic"]:
		if opts.get(k, false):
			node.set_meta(k, true)


## A generic mesh piece (cylinder, sphere, quad) placed and tagged.
func piece(mesh: Mesh, pos: Vector3, mat: Material, opts := {}) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = opts.get("name", "Piece")
	mi.mesh = mesh
	mi.position = pos
	if opts.has("rotation"):
		mi.rotation = opts.rotation
	if opts.has("basis"):
		mi.basis = opts.basis
	mi.material_override = mat
	if opts.has("tint"):
		mi.set_instance_shader_parameter("tint", opts.tint)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if opts.get("cast_shadow", true) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var parent: Node = opts.get("parent_node", null)
	if parent == null:
		parent = group(opts.get("parent", "Structure/Misc"))
	attach(mi, parent)
	if not opts.get("untagged", false):
		tag(mi, opts.get("band", band_of(pos.y)), opts.get("fadeable", false), opts)
	return mi


## A flat card on a wall or hanging in the air (sign, poster, calendar).
## `normal` is the way its face points.
func card(tex_path: String, center: Vector3, size: Vector2, normal: Vector3, opts := {}) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var mat: Material = opts.get("material", card_material(tex_path, opts.get("emission", 0.0), opts.get("unshaded", false)))
	var yaw := atan2(normal.x, normal.z)
	var o := opts.duplicate()
	o["rotation"] = Vector3(0, yaw, 0)
	o["cast_shadow"] = opts.get("cast_shadow", false)
	return piece(q, center + normal * 0.012, mat, o)


func cylinder(a: Vector3, b: Vector3, radius: float, mat: Material, opts := {}) -> MeshInstance3D:
	var len := a.distance_to(b)
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = len
	m.radial_segments = opts.get("segments", 10)
	m.rings = 1
	var dir := (b - a).normalized()
	var basis := Basis.IDENTITY
	if absf(dir.dot(Vector3.UP)) < 0.999:
		var axis := Vector3.UP.cross(dir).normalized()
		basis = Basis(axis, acos(clampf(Vector3.UP.dot(dir), -1, 1)))
	elif dir.y < 0:
		basis = Basis(Vector3.RIGHT, PI)
	var o := opts.duplicate()
	o["basis"] = basis
	return piece(m, (a + b) * 0.5, mat, o)


# ----------------------------------------------------------------------------- rooms


## Room = floor slab + walls just outside the rectangle, with openings.
##   open: {n: [[a,b]], s:..., e:..., w:...} coordinates along each wall
##   skip: sides with no wall at all
##   id:   a closed room: a lid covers it and its contents stay hidden until Mei is inside
func room(r: Dictionary) -> void:
	var x0: float = r.x0
	var x1: float = r.x1
	var z0: float = r.z0
	var z1: float = r.z1
	var y: float = r.y
	var h: float = r.get("h", 4.2)
	var wall: Color = r.get("wall", c8(0x8a8c86))
	var floor_col: Color = r.get("floor", c8(0x55504a))
	var open: Dictionary = r.get("open", {})
	var skip: Array = r.get("skip", [])
	var room_name: String = r.get("name", "Room")
	var id: String = r.get("id", "")
	var band: float = r.get("band", band_of(y + 0.2))
	var wall_band: float = r.get("wall_band", band)
	var lintel: bool = r.get("lintel", true)
	var wall_surface: String = r.get("wall_surface", "plaster")
	var floor_surface: String = r.get("floor_surface", "floor")
	var dado: String = r.get("dado", "")
	var dado_col: Color = r.get("dado_color", c8(0xb9c6c0))
	var parent_path: String = r.get("parent", "Structure") + "/" + room_name.to_pascal_case()
	var T := 0.3
	add_floor(x0, x1, z0, z1, y, room_name)
	# Neighbouring rooms' slabs and lids overlap under and over their doorways
	# (each runs out under its walls). Each room's sits a few millimetres off
	# the last one's, so one surface always wins there instead of the two
	# flickering over each other. Walking uses the floor's true height.
	var lift := 0.003 * float(_room_count % 5)
	_room_count += 1
	var fo := {"band": band, "surface": floor_surface, "is_floor": true, "parent": parent_path, "name": "Floor"}
	if r.has("floor_hole"):
		# a stairwell opening: the slab is laid in pieces around it
		var hx0: float = r.floor_hole[0]
		var hx1: float = r.floor_hole[1]
		var hz0: float = r.floor_hole[2]
		var hz1: float = r.floor_hole[3]
		if hx0 > x0 - T:
			box(x0 - T, hx0, y - 0.3, y + lift, z0 - T, z1 + T, floor_col, fo)
		box(hx1, x1 + T, y - 0.3, y + lift, z0 - T, z1 + T, floor_col, fo)
		if hz0 > z0 - T:
			box(hx0, hx1, y - 0.3, y + lift, z0 - T, hz0, floor_col, fo)
		box(hx0, hx1, y - 0.3, y + lift, hz1, z1 + T, floor_col, fo)
	else:
		box(x0 - T, x1 + T, y - 0.3, y + lift, z0 - T, z1 + T, floor_col, fo)
	if id != "":
		closed_room(id, [x0, x1, z0, z1], y, h - lift, band, parent_path)

	var sides := {
		"n": {"a0": x0 - T, "a1": x1 + T, "fixed": z0 - T / 2, "axis": "x", "inner": Vector3(0, 0, 1)},
		"s": {"a0": x0 - T, "a1": x1 + T, "fixed": z1 + T / 2, "axis": "x", "inner": Vector3(0, 0, -1)},
		"w": {"a0": z0, "a1": z1, "fixed": x0 - T / 2, "axis": "z", "inner": Vector3(1, 0, 0)},
		"e": {"a0": z0, "a1": z1, "fixed": x1 + T / 2, "axis": "z", "inner": Vector3(-1, 0, 0)},
	}
	for side in sides:
		if side in skip:
			continue
		var s: Dictionary = sides[side]
		var gaps: Array = open.get(side, []).duplicate()
		gaps.sort_custom(func(a, b): return a[0] < b[0])
		var cursor: float = s.a0
		var segments: Array = []
		for g in gaps:
			if g[0] > cursor:
				segments.append([cursor, g[0]])
			cursor = maxf(cursor, g[1])
		if cursor < s.a1:
			segments.append([cursor, s.a1])
		var wall_opts := {"fadeable": not r.get("no_fade", false), "band": wall_band, "room": id, "surface": wall_surface,
			"parent": parent_path, "name": "Wall" + side.to_upper(), "base_y": y}
		for seg in segments:
			var m := _wall_segment(s, seg[0], seg[1], y, y + h, wall, wall_opts)
			_dress_wall(m, s, seg[0], seg[1], y, room_name, dado, dado_col, side, skip, wall_band, id, parent_path)
		for g in gaps:
			if lintel:
				var lo := wall_opts.duplicate()
				lo["name"] = "Lintel" + side.to_upper()
				_wall_segment(s, g[0], g[1], y + 2.7, y + h, wall, lo)
				_door_frame(s, g[0], g[1], y, wall_band, id, parent_path)


func _wall_segment(s: Dictionary, a: float, b: float, y0: float, y1: float, color: Color, opts: Dictionary) -> MeshInstance3D:
	var T := 0.3
	var m: MeshInstance3D
	if s.axis == "x":
		m = box(a, b, y0, y1, s.fixed - T / 2, s.fixed + T / 2, color, opts)
	else:
		m = box(s.fixed - T / 2, s.fixed + T / 2, y0, y1, a, b, color, opts)
	m.set_meta("side", s.get("side", ""))
	return m


## Skirting board and (optionally) a mosaic dado on the inside face of a wall.
## They are children of the wall so they fade with it.
func _dress_wall(wall: MeshInstance3D, s: Dictionary, a: float, b: float, y: float, _room_name: String,
		dado: String, dado_col: Color, _side: String, _skip: Array, _band: float, _id: String, _parent: String) -> void:
	var T := 0.3
	var inner: Vector3 = s.inner
	var face: float = s.fixed + (inner.x if s.axis == "z" else inner.z) * (T / 2)
	# trim the ends back from corners so trims do not poke through the next wall
	var a2 := a + 0.02
	var b2 := b - 0.02
	if b2 - a2 < 0.1:
		return
	var skirting := c8(0x3a3028)
	var d := 0.035
	var opts := {"parent_node": wall, "surface": "wood", "cast_shadow": false, "name": "Skirting"}
	var mi: MeshInstance3D
	if s.axis == "x":
		var zf: float = face + inner.z * d / 2
		mi = box(a2, b2, y, y + 0.14, zf - d / 2, zf + d / 2, skirting, opts)
	else:
		var xf: float = face + inner.x * d / 2
		mi = box(xf - d / 2, xf + d / 2, y, y + 0.14, a2, b2, skirting, opts)
	_localize(mi, wall)
	if dado != "":
		var dd := 0.02
		var o2 := {"parent_node": wall, "surface": dado, "cast_shadow": false, "name": "Dado"}
		if s.axis == "x":
			var zf2: float = face + inner.z * dd / 2
			mi = box(a2, b2, y + 0.14, y + 1.2, zf2 - dd / 2, zf2 + dd / 2, dado_col, o2)
		else:
			var xf2: float = face + inner.x * dd / 2
			mi = box(xf2 - dd / 2, xf2 + dd / 2, y + 0.14, y + 1.2, a2, b2, dado_col, o2)
		_localize(mi, wall)


## box() places children in world coordinates; this re-expresses a child of
## another mesh in that mesh's local space, and drops the child's own tags
## (it fades with its parent).
func _localize(child: Node3D, parent: Node3D) -> void:
	child.position -= parent.position
	for k in ["band", "fadeable", "room"]:
		if child.has_meta(k):
			child.remove_meta(k)


## Timber frame around an opening: two posts and a head.
func _door_frame(s: Dictionary, a: float, b: float, y: float, band: float, id: String, parent_path: String) -> void:
	var T := 0.3
	var fw := 0.08
	var col := c8(0x4a3a2e)
	var o := {"band": band, "surface": "wood", "parent": parent_path + "/Frames", "name": "Frame", "room": id, "fadeable": true}
	if s.axis == "x":
		box(a, a + fw, y, y + 2.7, s.fixed - T / 2 - 0.02, s.fixed + T / 2 + 0.02, col, o)
		box(b - fw, b, y, y + 2.7, s.fixed - T / 2 - 0.02, s.fixed + T / 2 + 0.02, col, o)
		box(a, b, y + 2.62, y + 2.72, s.fixed - T / 2 - 0.02, s.fixed + T / 2 + 0.02, col, o)
	else:
		box(s.fixed - T / 2 - 0.02, s.fixed + T / 2 + 0.02, y, y + 2.7, a, a + fw, col, o)
		box(s.fixed - T / 2 - 0.02, s.fixed + T / 2 + 0.02, y, y + 2.7, b - fw, b, col, o)
		box(s.fixed - T / 2 - 0.02, s.fixed + T / 2 + 0.02, y + 2.62, y + 2.72, a, b, col, o)


## Register (or extend) a closed room and give that part of it a lid.
func closed_room(id: String, rect: Array, y: float, h: float, band: float, parent_path: String) -> void:
	var found := false
	for r in data.closed_rooms:
		if r.id == id:
			r.rects.append(rect)
			found = true
	if not found:
		data.closed_rooms.append({"id": id, "y": y, "rects": [rect]})
	box(rect[0] - 0.3, rect[1] + 0.3, y + h, y + h + 0.25, rect[2] - 0.3, rect[3] + 0.3, c8(0x8a857a),
		{"fadeable": true, "band": band, "room": id, "surface": "concrete", "top": "tar", "is_lid": true,
		"parent": parent_path, "name": "Lid"})


# ----------------------------------------------------------------------------- doors and holds


## A real door in a wall opening. `normal` points to the side Mei first
## approaches from. Solid until it has been discovered and opened.
func door(d: Dictionary) -> void:
	var id: String = d.id
	var x: float = d.x
	var z: float = d.z
	var y: float = d.y
	var n: Vector3 = d.normal
	var width: float = d.get("width", 1.4)
	var band: float = d.get("band", 0.0)
	var ax := absf(n.x) > 0.5
	var tangent := Vector3(-n.z, 0, n.x)
	var pivot := Node3D.new()
	pivot.name = id.to_pascal_case()
	pivot.position = Vector3(x, y, z) - tangent * (width / 2)
	var base_yaw := atan2(-tangent.z, tangent.x)
	pivot.rotation.y = base_yaw
	attach(pivot, group("Doors"))
	# a door swung open toward the camera must fade like the walls around it
	tag(pivot, band, true)
	var col: Color = d.get("color", c8(0x7a93a0))
	var panel := box(0, width, 0, 2.6, -0.05, 0.05, col, {"surface": "metal", "parent_node": pivot, "name": "Panel"})
	panel.remove_meta("band")
	# rails and a kick plate: an old service door
	for yy in [0.35, 1.3, 2.25]:
		var r := box(0.06, width - 0.06, yy, yy + 0.08, -0.07, 0.07, col.darkened(0.15), {"surface": "metal", "parent_node": pivot, "name": "Rail"})
		r.remove_meta("band")
	var knob := box(width - 0.22, width - 0.14, 1.16, 1.24, -0.11, 0.11, c8(0xc9a55a), {"surface": "metal", "parent_node": pivot, "name": "Knob"})
	knob.remove_meta("band")
	# the Hong Kong service-door plate (閒人免進), on the face that looks back down the hall
	var plate := card("res://assets/textures/props/sign_staff_only.png", Vector3(width / 2, 1.75, -0.06), Vector2(0.62, 0.31),
		Vector3(0, 0, -1), {"parent_node": pivot, "untagged": true, "name": "Plate"})
	plate.position = Vector3(width / 2, 1.75, -0.065)

	# frame, so the opening reads as a doorway from the side it faces
	var fw := 0.12
	var frame_col := c8(0x3a3632)
	var fo := {"band": band, "fadeable": true, "surface": "metal", "parent": "Doors/" + pivot.name + "Frame", "name": "Frame"}
	if ax:
		box(x - 0.2, x + 0.2, y, y + 2.75, z - width / 2 - fw, z - width / 2, frame_col, fo)
		box(x - 0.2, x + 0.2, y, y + 2.75, z + width / 2, z + width / 2 + fw, frame_col, fo)
		box(x - 0.2, x + 0.2, y + 2.62, y + 2.75, z - width / 2 - fw, z + width / 2 + fw, frame_col, fo)
	else:
		box(x - width / 2 - fw, x - width / 2, y, y + 2.75, z - 0.2, z + 0.2, frame_col, fo)
		box(x + width / 2, x + width / 2 + fw, y, y + 2.75, z - 0.2, z + 0.2, frame_col, fo)
		box(x - width / 2 - fw, x + width / 2 + fw, y + 2.62, y + 2.75, z - 0.2, z + 0.2, frame_col, fo)

	var half := width / 2 + 0.05
	add_obstacle(x - 0.18 if ax else x - half, x + 0.18 if ax else x + half,
		z - half if ax else z - 0.18, z + half if ax else z + 0.18, y, id, "door:" + id)

	var entry := {"id": id, "pos": Vector3(x, y, z), "normal": n, "width": width, "room": d.get("room", ""),
		"base_yaw": base_yaw, "path": "Doors/" + pivot.name, "spill_path": ""}
	if d.get("light_spill", false):
		# light spilling under the door onto the hall floor: visible from the
		# starting view even though the door itself is edge-on
		var spill_root := Node3D.new()
		spill_root.name = pivot.name + "Spill"
		attach(spill_root, group("Doors"))
		tag(spill_root, band)
		var q := QuadMesh.new()
		q.size = Vector2(1.5, width * 1.15)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(1.0, 0.85, 0.56, 0.6)
		sm.albedo_texture = load("res://assets/textures/props/contact_shadow.png")
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		var spill := MeshInstance3D.new()
		spill.name = "Spill"
		spill.mesh = q
		spill.material_override = sm
		spill.rotation = Vector3(-PI / 2, 0, 0 if ax else PI / 2)
		spill.position = Vector3(x + n.x * 0.75, y + 0.015, z + n.z * 0.75)
		spill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		attach(spill, spill_root)
		var glow := OmniLight3D.new()
		glow.name = "Glow"
		glow.light_color = c8(0xffc878)
		glow.light_energy = 1.4
		glow.omni_range = 3.5
		glow.omni_attenuation = 1.6
		glow.position = Vector3(x + n.x * 0.5, y + 0.35, z + n.z * 0.5)
		attach(glow, spill_root)
		entry.spill_path = "Doors/" + spill_root.name
	data.doors.append(entry)


## An airshaft handhold. normal = the way its usable face points (null: seen from anywhere).
func hold(id: String, hold_name: String, node: Node3D, normal: Variant, climb_point: Vector3) -> void:
	data.holds.append({"id": id, "name": hold_name, "normal": normal, "point": climb_point,
		"path": str(root.get_path_to(node))})


# ----------------------------------------------------------------------------- lights


func lamp(pos: Vector3, color: Color, energy: float, dist: float, opts := {}) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = opts.get("name", "Lamp")
	l.light_color = color
	l.light_energy = energy
	l.omni_range = dist
	l.omni_attenuation = opts.get("attenuation", 1.4)
	l.shadow_enabled = opts.get("shadow", false)
	l.shadow_bias = 0.06
	l.shadow_normal_bias = 1.2
	l.light_volumetric_fog_energy = opts.get("fog", 1.0)
	l.light_specular = 0.35
	l.position = pos
	attach(l, group("Lights"))
	l.set_meta("band", 0.0 if pos.y < 4.9 else 1.0)
	l.set_meta("base_energy", energy)
	return l


# ----------------------------------------------------------------------------- characters


func resident(id: String, sheet_id: String, pos: Vector3, opts := {}) -> Node3D:
	var r: Node3D = RESIDENT_SCENE.instantiate()
	r.name = id.to_pascal_case()
	r.set("resident_id", id)
	r.set("sheet_id", sheet_id)
	r.set("idle_anim", opts.get("anim", "idle"))
	r.set("collides", opts.get("collide", true))
	r.set("facing", opts.get("facing", Vector3(0, 0, 1)))
	r.set("story", opts.get("story", true))
	r.position = pos
	var parent: Node = group(opts.get("parent", "Residents"))
	parent.add_child(r, true)
	r.owner = root
	return r


# ----------------------------------------------------------------------------- output


func finish() -> void:
	SurfaceLibrary.save_all()


# ----------------------------------------------------------------------------- people, settled


## Everyone in the background stands somewhere real: on a surface, clear of
## huts, tanks, lofts, washing and walls. Each one is checked where the
## dressing put them; if their body would pass through anything, or there's
## nothing under their feet, they step to the nearest clear spot on the same
## level, and if there isn't one they aren't placed. Story residents are left
## exactly where the scenes put them. Returns [moved, removed].
func settle_people() -> Array:
	# the scenery as triangles (merged roofscapes have one huge box, so boxes
	# won't do), bucketed by 2 m column so each check only sees its neighbours
	var tris: Array[PackedVector3Array] = []
	_gather_solids(root, Transform3D.IDENTITY, tris)
	var grid := {}
	for i in tris.size():
		var t := tris[i]
		var bx := AABB(t[0], Vector3.ZERO).expand(t[1]).expand(t[2])
		for cell in _cells(bx):
			if not grid.has(cell):
				grid[cell] = []
			(grid[cell] as Array).append(i)
	var people: Array[Node3D] = []
	_gather_people(root, people)
	var moved := 0
	var removed := 0
	for r in people:
		var parent_xf := _world_xform(r.get_parent())
		var at: Vector3 = parent_xf * r.position
		if _stands_clear(at, tris, grid):
			continue
		var found := false
		for ring: float in [0.35, 0.7, 1.05, 1.4, 1.8, 2.3]:
			for k in 12:
				var a: float = TAU * k / 12.0 + ring
				var cand: Vector3 = at + Vector3(cos(a), 0, sin(a)) * ring
				if _stands_clear(cand, tris, grid):
					r.position = parent_xf.affine_inverse() * cand
					found = true
					break
			if found:
				break
		if found:
			moved += 1
		else:
			r.get_parent().remove_child(r)
			r.free()
			removed += 1
	return [moved, removed]


const _BODY_HALF := 0.2
const _FOOT := 0.12
const _CELL := 2.0
const _THIN := ["Cable", "Wire", "Line", "Antenna", "AerialArm", "Element", "SignLine", "SheetLine"]


## Clear of everything from the ankles to the top of the head, and standing on
## flat floor at her feet under the whole of her footprint.
func _stands_clear(at: Vector3, tris: Array[PackedVector3Array], grid: Dictionary) -> bool:
	var body := AABB(at + Vector3(-_BODY_HALF, 0.08, -_BODY_HALF), Vector3(_BODY_HALF * 2, 1.52, _BODY_HALF * 2))
	var feet := [Vector2(at.x, at.z), Vector2(at.x - _FOOT, at.z - _FOOT), Vector2(at.x + _FOOT, at.z - _FOOT),
		Vector2(at.x - _FOOT, at.z + _FOOT), Vector2(at.x + _FOOT, at.z + _FOOT)]
	var held := [false, false, false, false, false]
	var seen := {}
	for cell in _cells(body.grow(0.2)):
		for i in grid.get(cell, []):
			if seen.has(i):
				continue
			seen[i] = true
			var t: PackedVector3Array = tris[i]
			var bx := AABB(t[0], Vector3.ZERO).expand(t[1]).expand(t[2])
			if bx.intersects(body) and _tri_meets_box(t, body):
				return false
			if absf(t[0].y - at.y) < 0.06 and absf(t[1].y - at.y) < 0.06 and absf(t[2].y - at.y) < 0.06:
				var a2 := Vector2(t[0].x, t[0].z)
				var b2 := Vector2(t[1].x, t[1].z)
				var c2 := Vector2(t[2].x, t[2].z)
				for k in feet.size():
					if not held[k] and Geometry2D.point_is_inside_triangle(feet[k], a2, b2, c2):
						held[k] = true
	return not held.has(false)


## Does the triangle actually cross the box (not just its bounding box)? Its
## plane has to pass between the box's corners.
func _tri_meets_box(t: PackedVector3Array, bx: AABB) -> bool:
	var n := (t[1] - t[0]).cross(t[2] - t[0])
	if n.length_squared() < 1e-12:
		return false
	var side := 0
	for k in 8:
		var d := n.dot(bx.get_endpoint(k) - t[0])
		var sgn := 1 if d > 0.0 else -1
		if side == 0:
			side = sgn
		elif sgn != side:
			return true
	return false


func _cells(bx: AABB) -> Array:
	var out := []
	for cx in range(floori(bx.position.x / _CELL), floori(bx.end.x / _CELL) + 1):
		for cz in range(floori(bx.position.z / _CELL), floori(bx.end.z / _CELL) + 1):
			out.append(Vector2i(cx, cz))
	return out


func _gather_solids(n: Node, xf: Transform3D, out: Array[PackedVector3Array]) -> void:
	for c in n.get_children():
		if c.get_script() != null and (c is CharacterSprite or c.get("resident_id") != null):
			continue          # people and birds are not scenery
		var cx := xf * (c as Node3D).transform if c is Node3D else xf
		var thin := false
		for t in _THIN:
			if String(c.name).begins_with(t):
				thin = true
		if not thin:
			if c is MeshInstance3D and (c as MeshInstance3D).mesh:
				_add_faces((c as MeshInstance3D).mesh.get_faces(), cx, out)
			elif c is MultiMeshInstance3D and (c as MultiMeshInstance3D).multimesh and (c as MultiMeshInstance3D).multimesh.mesh:
				var mm := (c as MultiMeshInstance3D).multimesh
				var faces := mm.mesh.get_faces()
				for i in mm.instance_count:
					_add_faces(faces, cx * mm.get_instance_transform(i), out)
		_gather_solids(c, cx, out)


func _add_faces(faces: PackedVector3Array, xf: Transform3D, out: Array[PackedVector3Array]) -> void:
	for i in range(0, faces.size(), 3):
		out.append(PackedVector3Array([xf * faces[i], xf * faces[i + 1], xf * faces[i + 2]]))


func _gather_people(n: Node, out: Array[Node3D]) -> void:
	for c in n.get_children():
		if c.get("resident_id") != null and c.get("story") == false:
			out.append(c)
		else:
			_gather_people(c, out)


func _world_xform(n: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	while n != null and n != root.get_parent():
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf
