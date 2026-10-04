class_name MahjongKit
extends RefCounted

## Mahjong tiles as tiles: a bone-white face block bonded to a jade back,
## every edge rounded, a fine groove where the two layers meet, and the face
## carved and painted (scripts/make_mahjong.py paints the atlas).
##
## One mesh per face, built once and saved under assets/meshes/mahjong/ so
## the level scene points at them instead of carrying a copy each. Tiles are
## about one and a half times a real set's, so a hand still reads from the
## default camera.

## width, height, thickness; the face looks along +z
const SIZE := Vector3(0.044, 0.0592, 0.032)
const RADIUS := 0.0055
## how much of the thickness, from the face back, is bone
const BONE := 0.62
const GROOVE := 0.0005

const ATLAS := "res://assets/textures/props/mahjong_atlas.png"
const ATLAS_NORMAL := "res://assets/textures/props/mahjong_atlas_n.png"
const COLS := 8
const ROWS := 5
const CELL := Vector2(256, 336)
const PAD := 12.0

## The atlas's cells, in the order scripts/make_mahjong.py paints them.
const FACES := [
	"dot_1", "dot_2", "dot_3", "dot_4", "dot_5", "dot_6", "dot_7", "dot_8", "dot_9",
	"bamboo_1", "bamboo_2", "bamboo_3", "bamboo_4", "bamboo_5", "bamboo_6", "bamboo_7", "bamboo_8", "bamboo_9",
	"character_1", "character_2", "character_3", "character_4", "character_5", "character_6", "character_7", "character_8", "character_9",
	"east", "south", "west", "north", "red_dragon", "green_dragon", "white_dragon",
	"flower_plum", "flower_orchid", "flower_chrysanthemum", "flower_bamboo",
	"ivory", "jade",
]
## the 34 kinds a game is dealt from (the flowers are set aside as drawn)
const SUITED := 34

const MESH_DIR := "res://assets/meshes/mahjong"
const MATERIAL_PATH := "res://assets/materials/mahjong_tile.tres"

static var _meshes := {}
static var _material: StandardMaterial3D


# ----------------------------------------------------------------------------- placing


## A tile standing on its end, its face turned to `facing` (a player's hand).
static func standing(b: LevelBuilder, face: String, base: Vector3, facing: Vector3, parent: String, opts := {}) -> MeshInstance3D:
	var f := Vector3(facing.x, 0, facing.z).normalized()
	var basis := Basis.looking_at(-f, Vector3.UP)
	return _place(b, face, base + Vector3(0, SIZE.y * 0.5, 0), basis, parent, opts)


## A tile lying flat, its top edge pointing along `toward`. Face up for the
## discards, face down for the wall.
static func lying(b: LevelBuilder, face: String, base: Vector3, toward: Vector3, face_up: bool, parent: String, opts := {}) -> MeshInstance3D:
	var y := Vector3(toward.x, 0, toward.z).normalized()
	var z := Vector3.UP if face_up else Vector3.DOWN
	var basis := Basis(y.cross(z), y, z)
	return _place(b, face, base + Vector3(0, SIZE.z * 0.5, 0), basis, parent, opts)


static func _place(b: LevelBuilder, face: String, center: Vector3, basis: Basis, parent: String, opts: Dictionary) -> MeshInstance3D:
	var o := opts.duplicate()
	o["basis"] = basis
	o["parent"] = parent
	o["name"] = opts.get("name", "Tile")
	o["cast_shadow"] = opts.get("cast_shadow", true)
	return b.piece(mesh(face), center, material(), o)


# ----------------------------------------------------------------------------- the material


static func material() -> StandardMaterial3D:
	if _material:
		return _material
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(ATLAS)
	m.normal_enabled = true
	m.normal_texture = load(ATLAS_NORMAL)
	m.normal_scale = 1.0
	# polished bone under a lacquer of hands
	m.roughness = 0.32
	m.clearcoat_enabled = true
	m.clearcoat = 0.35
	m.clearcoat_roughness = 0.22
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	ResourceSaver.save(m, MATERIAL_PATH, ResourceSaver.FLAG_CHANGE_PATH)
	_material = m
	return m


# ----------------------------------------------------------------------------- the mesh


static func mesh(face: String) -> ArrayMesh:
	if _meshes.has(face):
		return _meshes[face]
	assert(FACES.has(face), "no mahjong face %s" % face)
	var m := _build(FACES.find(face))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	ResourceSaver.save(m, "%s/%s.res" % [MESH_DIR, face], ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_COMPRESS)
	_meshes[face] = m
	return m


## Sample lines across one axis: the flat middle as a single span, each
## rounded edge in `n` steps spaced so the arc's angle steps evenly.
static func _samples(half: float, n: int, extra: Array = []) -> PackedFloat32Array:
	var inner := half - RADIUS
	var out: Array[float] = []
	for k in range(n, 0, -1):
		var off := RADIUS * tan(k * PI * 0.25 / n)
		out.append(-inner - off)
		out.append(inner + off)
	out.append(-inner)
	out.append(inner)
	for e in extra:
		out.append(e)
	out.sort()
	return PackedFloat32Array(out)


static func _build(cell: int) -> ArrayMesh:
	var h := SIZE * 0.5
	var inner := h - Vector3.ONE * RADIUS
	var seam := h.z - SIZE.z * BONE
	var samples := [
		_samples(h.x, 3),
		_samples(h.y, 3),
		_samples(h.z, 3, [seam - GROOVE * 1.6, seam, seam + GROOVE * 1.6]),
	]
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
					for c in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
						var p := Vector3.ZERO
						p[axis] = sgn * h[axis]
						p[ua] = us[c[0]]
						p[va] = vs[c[1]]
						quad.append(p)
					_quad(st, quad, outward, h, inner, seam, cell)
	st.index()
	st.generate_tangents()
	return st.commit()


## Round a point on the box onto the tile: push it out from the inner box by
## the edge radius, and pinch it into the groove at the seam.
static func _shape(p: Vector3, inner: Vector3, outward: Vector3, seam: float) -> Array:
	var core := p.clamp(-inner, inner)
	var d := p - core
	var n := outward
	var q := p
	if d.length() > 0.000001:
		n = d.normalized()
		q = core + n * RADIUS
	if absf(p.z - seam) < GROOVE * 0.5 and absf(n.z) < 0.9:
		var pinch := Vector3(n.x, n.y, 0).normalized() * GROOVE
		q -= pinch
	return [q, n]


static func _quad(st: SurfaceTool, quad: Array[Vector3], outward: Vector3, h: Vector3, inner: Vector3, seam: float, cell: int) -> void:
	var centre := (quad[0] + quad[2]) * 0.5
	var shaped := []
	for p in quad:
		shaped.append(_shape(p, inner, outward, seam))
	# which part of the atlas this quad wears: the face (with its rounded
	# rim), or the plain bone or jade of the body
	var on_face := centre.z > h.z - RADIUS * 0.999
	var swatch := FACES.find("ivory") if centre.z > seam else FACES.find("jade")
	var uvs := []
	for k in 4:
		var q: Vector3 = shaped[k][0]
		if on_face:
			uvs.append(_face_uv(cell, Vector2((q.x + h.x) / SIZE.x, (h.y - q.y) / SIZE.y)))
		else:
			uvs.append(_face_uv(swatch, Vector2(0.5, 0.5)))
	# clockwise seen from outside is a front face in Godot
	var a: Vector3 = shaped[0][0]
	var b: Vector3 = shaped[1][0]
	var c: Vector3 = shaped[2][0]
	var order := [0, 1, 2, 0, 2, 3]
	if (b - a).cross(c - a).dot(outward) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for k in order:
		st.set_normal(shaped[k][1])
		st.set_uv(uvs[k])
		st.add_vertex(shaped[k][0])


static func _face_uv(cell: int, t: Vector2) -> Vector2:
	var atlas := Vector2(COLS * CELL.x, ROWS * CELL.y)
	var origin := Vector2((cell % COLS) * CELL.x, (cell / COLS) * CELL.y) + Vector2.ONE * PAD
	var span := CELL - Vector2.ONE * PAD * 2.0
	return (origin + t.clamp(Vector2.ZERO, Vector2.ONE) * span) / atlas
