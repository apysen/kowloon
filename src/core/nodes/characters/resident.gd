@tool
class_name Resident
extends Node3D

## A person who lives here: a character card plus the little they do.
##
## Story residents stand where they live, breathe, work at whatever they are
## doing, turn to face Mei when she talks to them, and can be walked along a
## path by the quest (the Chan boy's errand). Scripted walks pause while the
## player is reading, so nothing happens behind a menu. If Mei stands in a
## corridor in the way, a resident waits, says excuse me, then squeezes past
## (the corridors are two metres wide).

signal blocked_by_mei(resident_id: String)

@export var resident_id := ""
@export var sheet_id := "mei":
	set(v):
		sheet_id = v
		if sprite:
			sprite.sheet_id = v
@export var idle_anim := "idle"
@export var facing := Vector3(0, 0, 1)
@export var collides := true
## Story residents talk and walk; background residents just live.
@export var story := true

const RADIUS := 0.28

@onready var sprite: CharacterSprite = $Sprite

var home := Vector3.ZERO
var obstacle: WalkSpace.Obstacle
var gone := false
var ghost := false
var walk_speed := 2.4
var _path: Array[Vector3] = []
var _walk_to: Variant = null
var _on_arrive: Callable
var _yield_t := 0.0
var _barked := false
var _fade_dir := 0
var _on_faded: Callable
var _talk_face_t := 0.0
var _carrying := false


func _ready() -> void:
	sprite.sheet_id = sheet_id
	sprite.facing = facing
	sprite.phase = randf() * 5.0
	sprite.play(idle_anim)
	home = position


func is_walking() -> bool:
	return _walk_to != null


func walk(points: Array, on_done := Callable(), speed := 2.4) -> void:
	_path.clear()
	for p in points:
		_path.append(p if p is Vector3 else Vector3(p[0], p[1], p[2]))
	walk_speed = speed
	_walk_to = _path.pop_front()
	_on_arrive = on_done


func place_at(p: Vector3) -> void:
	position = p
	home = p
	_walk_to = null
	_path.clear()


func fade(dir: String, on_done := Callable()) -> void:
	_fade_dir = 1 if dir == "in" else -1
	if _fade_dir > 0:
		gone = false
		sprite.fade = 0.0
		visible = true
	_on_faded = on_done


func set_carrying(v: bool) -> void:
	_carrying = v


func face_toward(p: Vector3, hold := 3.0) -> void:
	var d := p - global_position
	d.y = 0
	if d.length_squared() > 0.01:
		sprite.facing = d.normalized()
		_talk_face_t = hold


func can_talk() -> bool:
	return visible and not gone and _walk_to == null


## Per-frame behaviour, driven by the world so it can pause with the menus.
func tick(delta: float, paused: bool, mei_pos: Vector3, cam_yaw: float) -> void:
	sprite.camera_yaw = cam_yaw
	if obstacle:
		obstacle.set_center(position.x, position.z, position.y, RADIUS)
	if _fade_dir != 0 and not paused:
		sprite.fade = sprite.fade + _fade_dir * delta / 0.45
		if sprite.fade >= 1.0 or sprite.fade <= 0.0:
			if _fade_dir < 0:
				gone = true
				visible = false
			_fade_dir = 0
			if _on_faded.is_valid():
				var f := _on_faded
				_on_faded = Callable()
				f.call()
	if _walk_to != null:
		if paused:
			sprite.speed_scale = 0.0
			return
		sprite.speed_scale = 1.0
		var to: Vector3 = (_walk_to as Vector3) - position
		var d := to.length()
		var to_mei := mei_pos - position
		var near := absf(to_mei.y) < 1.0 and Vector2(to_mei.x, to_mei.z).length() < 0.95
		var ahead := to_mei.x * to.x + to_mei.z * to.z > 0.0
		if Vector2(to.x, to.z).length() > 0.01:
			sprite.facing = Vector3(to.x, 0, to.z).normalized()
		sprite.play("carry" if _carrying else "walk")
		if ghost and (not near or Vector2(to_mei.x, to_mei.z).length() > 1.2):
			ghost = false
		if near and ahead and not ghost:
			_yield_t += delta
			sprite.play("carry_idle" if _carrying else "idle")
			if _yield_t > 0.6 and not _barked:
				_barked = true
				blocked_by_mei.emit(resident_id)
			if _yield_t < 1.6:
				return
			ghost = true
		if not near:
			_yield_t = 0.0
			_barked = false
		if d < 0.05:
			position = _walk_to
			_walk_to = _path.pop_front() if not _path.is_empty() else null
			if _walk_to == null:
				home = position
				sprite.play("carry_idle" if _carrying else idle_anim)
				if _on_arrive.is_valid():
					var cb := _on_arrive
					_on_arrive = Callable()
					cb.call()
		else:
			position += to * minf(1.0, delta * walk_speed / d)
		return
	sprite.speed_scale = 0.0 if paused else 1.0
	if _talk_face_t > 0.0:
		_talk_face_t -= delta
		if _talk_face_t <= 0.0:
			sprite.facing = facing
