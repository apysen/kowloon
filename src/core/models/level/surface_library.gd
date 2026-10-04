class_name SurfaceLibrary
extends RefCounted

## The world's surface materials, one per surface type (plus roof-topped variants).
##
## Every piece of the city uses one of these, tinted per instance, so the
## whole level runs on a dozen materials. The bake writes them to
## assets/materials/ so the scene references shared resources; at runtime the
## world asks for a piece's fading twin when it has to see through it.

const SHADER := preload("res://assets/shaders/world_surface.gdshader")
const FADE_SHADER := preload("res://assets/shaders/world_surface_fade.gdshader")
const TEX := "res://assets/textures/surfaces/"
const MAT_DIR := "res://assets/materials/"

## Metres per texture repeat (horizontal, vertical) and normal strength.
const SPECS := {
	"plaster": [Vector2(3, 3), 1.0],
	"tiles": [Vector2(1, 1), 1.0],
	"mosaic": [Vector2(1, 1), 0.8],
	"floor": [Vector2(2, 2), 1.0],
	"wood": [Vector2(2, 2), 1.0],
	"concrete": [Vector2(4, 4), 1.0],
	"tar": [Vector2(4, 4), 1.0],
	"rust": [Vector2(2, 2), 1.0],
	"metal": [Vector2(1.2, 1.2), 0.8],
	"fabric": [Vector2(0.6, 0.6), 0.8],
	"grain": [Vector2(2, 2), 0.7],
	"glaze": [Vector2(0.6, 0.6), 0.5],
	"timber": [Vector2(1.2, 1.2), 0.8],
	"facade_a": [Vector2(6, 5), 1.0],
	"facade_b": [Vector2(6, 5), 1.0],
	"facade_c": [Vector2(6, 5), 1.0],
	"facade_d": [Vector2(6, 5), 1.0],
	"facade_far": [Vector2(6, 5), 1.0],
}

static var _cache: Dictionary = {}
static var _fade_cache: Dictionary = {}


static func key(surface: String, top := "") -> String:
	return surface if top == "" else surface + "__" + top


static func get_material(surface: String, top := "") -> ShaderMaterial:
	var k := key(surface, top)
	if _cache.has(k):
		return _cache[k]
	var path := MAT_DIR + k + ".tres"
	var mat: ShaderMaterial
	if ResourceLoader.exists(path):
		mat = load(path)
	else:
		mat = build(surface, top)
	_cache[k] = mat
	return mat


static func build(surface: String, top := "") -> ShaderMaterial:
	var spec: Array = SPECS.get(surface, SPECS["grain"])
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("albedo_tex", load(TEX + surface + "_albedo.png"))
	m.set_shader_parameter("normal_tex", load(TEX + surface + "_normal.png"))
	m.set_shader_parameter("rough_tex", load(TEX + surface + "_rough.png"))
	m.set_shader_parameter("tile_size", spec[0])
	m.set_shader_parameter("normal_strength", spec[1])
	if ResourceLoader.exists(TEX + surface + "_emission.png"):
		m.set_shader_parameter("has_emission", true)
		m.set_shader_parameter("emission_tex", load(TEX + surface + "_emission.png"))
		m.set_shader_parameter("emission_energy", 2.4)
	if top != "":
		var tspec: Array = SPECS.get(top, SPECS["grain"])
		m.set_shader_parameter("has_top", true)
		m.set_shader_parameter("top_albedo_tex", load(TEX + top + "_albedo.png"))
		m.set_shader_parameter("top_normal_tex", load(TEX + top + "_normal.png"))
		m.set_shader_parameter("top_rough_tex", load(TEX + top + "_rough.png"))
		m.set_shader_parameter("top_tile", tspec[0].x)
	if surface.begins_with("facade"):
		m.set_shader_parameter("foot_grime", 0.0)
	return m


## Saves every material built so far (the bake calls this once at the end).
static func save_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAT_DIR))
	for k in _cache:
		var mat: ShaderMaterial = _cache[k]
		if mat.resource_path == "":
			ResourceSaver.save(mat, MAT_DIR + k + ".tres")
			mat.take_over_path(MAT_DIR + k + ".tres")


## The see-through twin of a world material, used only while a piece fades.
static func fade_variant(mat: Material) -> Material:
	if _fade_cache.has(mat):
		return _fade_cache[mat]
	var out: Material
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader == SHADER:
		var f := (mat as ShaderMaterial).duplicate() as ShaderMaterial
		f.shader = FADE_SHADER
		out = f
	elif mat is StandardMaterial3D:
		var s := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
		s.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		out = s
	else:
		out = mat
	_fade_cache[mat] = out
	return out
