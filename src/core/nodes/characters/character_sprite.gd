@tool
class_name CharacterSprite
extends Node3D

## An HD-2D character: a painted pixel card that turns to the camera.
##
## Three meshes share one sheet. The card itself is lit by the scene and
## writes the depth of a single anchor point so it can never be sliced by a
## wall. A second card, visible only to shadow maps, turns toward the sun so
## the shadow stays a full silhouette at every camera angle. A third, optional,
## draws a silhouette wherever something hides the character (Mei only).
##
## The node's own position is the character's feet. `facing` is a world
## direction; the card picks the front, back or side row from it relative to
## the camera, and mirrors the side row for left.

const QUAD_SHADER := preload("res://assets/shaders/pixel_sprite.gdshader")
const SHADOW_SHADER := preload("res://assets/shaders/pixel_sprite_shadow.gdshader")
const SILHOUETTE_SHADER := preload("res://assets/shaders/pixel_sprite_silhouette.gdshader")
const BLOB := preload("res://assets/textures/props/contact_shadow.png")

## Sheet id under assets/sprites/characters (e.g. "mei", "lau").
@export var sheet_id := "mei":
	set(v):
		sheet_id = v
		if is_inside_tree():
			_build()
@export var anim := "idle"
## World direction the character faces.
@export var facing := Vector3(0, 0, 1)
@export var show_silhouette := false
@export var casts_shadow := true
@export var contact_shadow := true
## Offset into the animation so a crowd does not breathe in step.
@export var phase := 0.0
@export var speed_scale := 1.0

var sheet: SpriteSheet
var camera_yaw := 0.0
var sun_direction := Vector3(-0.5, -0.8, 0.4)
var fade := 1.0:
	set(v):
		fade = clampf(v, 0.0, 1.0)
		_apply("fade", fade)
var tint := Color.WHITE:
	set(v):
		tint = v
		_apply("tint", tint)

var _card: MeshInstance3D
var _shadow: MeshInstance3D
var _silhouette: MeshInstance3D
var _blob: Decal
var _time := 0.0
var _frame := Vector2(-1, -1)
var _flip := -1.0
var _once_done := false


func _ready() -> void:
	_build()


func _build() -> void:
	for c in [_card, _shadow, _silhouette, _blob]:
		if c and is_instance_valid(c):
			c.queue_free()
	sheet = SpriteSheet.load_sheet(sheet_id)
	var size := sheet.world_size()
	var quad := QuadMesh.new()
	quad.size = size
	quad.center_offset = Vector3(0, size.y * 0.5 - sheet.feet_offset(), 0)

	var grid := Vector2(sheet.grid)
	var mat := ShaderMaterial.new()
	mat.shader = QUAD_SHADER
	mat.set_shader_parameter("sheet", sheet.texture)
	mat.set_shader_parameter("sheet_grid", grid)
	mat.set_shader_parameter("anchor_height", minf(0.8, size.y * 0.4))
	_card = MeshInstance3D.new()
	_card.name = "Card"
	_card.mesh = quad
	_card.material_override = mat
	_card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_card, false, Node.INTERNAL_MODE_FRONT)

	if casts_shadow:
		var smat := ShaderMaterial.new()
		smat.shader = SHADOW_SHADER
		smat.set_shader_parameter("sheet", sheet.texture)
		smat.set_shader_parameter("sheet_grid", grid)
		_shadow = MeshInstance3D.new()
		_shadow.name = "ShadowCaster"
		_shadow.mesh = quad
		_shadow.material_override = smat
		_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		add_child(_shadow, false, Node.INTERNAL_MODE_FRONT)

	if show_silhouette:
		var gmat := ShaderMaterial.new()
		gmat.shader = SILHOUETTE_SHADER
		gmat.set_shader_parameter("sheet", sheet.texture)
		gmat.set_shader_parameter("sheet_grid", grid)
		gmat.set_shader_parameter("anchor_height", minf(0.8, size.y * 0.4))
		gmat.render_priority = 10
		_silhouette = MeshInstance3D.new()
		_silhouette.name = "Silhouette"
		_silhouette.mesh = quad
		_silhouette.material_override = gmat
		_silhouette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_silhouette, false, Node.INTERNAL_MODE_FRONT)

	if contact_shadow:
		_blob = Decal.new()
		_blob.name = "ContactShadow"
		_blob.texture_albedo = BLOB
		_blob.size = Vector3(size.x * 0.75, 0.6, size.x * 0.55)
		_blob.position = Vector3(0, 0.05, 0)
		_blob.albedo_mix = 0.55
		_blob.upper_fade = 0.2
		_blob.lower_fade = 0.2
		_blob.cull_mask = 1
		add_child(_blob, false, Node.INTERNAL_MODE_FRONT)

	_frame = Vector2(-1, -1)
	_flip = -1.0
	_apply("fade", fade)
	_apply("tint", tint)
	_refresh(true)


func _apply(param: String, value: Variant) -> void:
	for m in [_card, _shadow, _silhouette]:
		if m and is_instance_valid(m):
			m.set_instance_shader_parameter(param, value)


func play(new_anim: String, restart := false) -> void:
	if new_anim == anim and not restart:
		return
	if sheet and not sheet.has_anim(new_anim):
		new_anim = "idle"
	anim = new_anim
	_time = 0.0
	_once_done = false
	_refresh(true)


## True once a non-looping animation has shown its last frame.
func finished() -> bool:
	return _once_done


func set_visible_parts(v: bool) -> void:
	visible = v


func _process(delta: float) -> void:
	_time += delta * speed_scale
	_refresh(false)


func _refresh(force: bool) -> void:
	if not sheet or not _card:
		return
	# turn the card to the camera (yaw only, like HD-2D billboards)
	_card.global_rotation = Vector3(0, camera_yaw, 0)
	if _silhouette:
		_silhouette.global_rotation = Vector3(0, camera_yaw, 0)
	if _shadow:
		var s := Vector3(sun_direction.x, 0, sun_direction.z)
		var yaw := atan2(s.x, s.z) if s.length_squared() > 1e-4 else camera_yaw
		_shadow.global_rotation = Vector3(0, yaw, 0)

	var vf := ViewMath.sprite_view(facing, camera_yaw)
	var tr := sheet.track(anim, vf.view)
	var durations: Array = tr.durations
	var total := 0.0
	for d in durations:
		total += d
	var t := _time + phase
	var f := 0
	if sheet.loops(anim):
		t = fposmod(t, total)
	elif t >= total:
		_once_done = true
		t = total - 0.0001
	var acc := 0.0
	for i in durations.size():
		acc += durations[i]
		if t < acc:
			f = i
			break
	var cell: Vector2i = tr.cells[f]
	var fr := Vector2(cell)
	var fl := 1.0 if vf.flip else 0.0
	if force or fr != _frame or fl != _flip:
		_frame = fr
		_flip = fl
		_apply("frame", fr)
		_apply("flip", fl)
