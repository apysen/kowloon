class_name Player
extends Node3D

## Mei.
##
## Moves camera-relative (W is always into the screen), slides along walls,
## and climbs along authored paths with the controls locked. Her card picks
## its row from the way she faces relative to the camera, so walking toward
## the camera shows her front, away shows her back, across shows her side.

signal path_finished

const SPEED := 4.2
const RADIUS := 0.32

@export var locks: ControlLocks
@export var cam: CameraRig

@onready var sprite: CharacterSprite = $Sprite

var walk_space: WalkSpace
var facing := Vector3(0, 0, 1)
var hidden := false:
	set(v):
		hidden = v
		if sprite:
			sprite.visible = not v
var pose := ""                     # "camera", "reach": held poses set by other systems
var _path: Array[Vector3] = []
var _path_speed := 2.6
var _on_path_done: Callable
var _climbing := false
var moving := false
## Set for a frame by a scripted move (pushing the crate) so the walk plays.
var moving_override := false


func band() -> int:
	return PerspectiveRules.player_band(position.y)


func teleport(p: Vector3) -> void:
	position = p
	_path.clear()
	if cam:
		cam.snap_next = true


func on_path() -> bool:
	return not _path.is_empty()


## Walk or climb along authored points with the controls locked.
func traverse(points: Array, speed := 2.6, on_done := Callable(), climbing := true) -> void:
	_path.clear()
	for p in points:
		_path.append(p)
	_path_speed = speed
	_on_path_done = on_done
	_climbing = climbing
	locks.lock("traverse")


func _process(delta: float) -> void:
	moving = false
	if not _path.is_empty():
		var goal: Vector3 = _path[0]
		var to := goal - position
		var dist := to.length()
		var step := _path_speed * delta
		if Vector2(to.x, to.z).length() > 0.05:
			facing = Vector3(to.x, 0, to.z).normalized()
		if dist <= step:
			position = goal
			_path.pop_front()
			if _path.is_empty():
				locks.unlock("traverse")
				_climbing = false
				path_finished.emit()
				if _on_path_done.is_valid():
					var cb := _on_path_done
					_on_path_done = Callable()
					cb.call()
		else:
			position += to * (step / dist)
		moving = true
	elif not locks.is_locked():
		var input := Input.get_vector("move_left", "move_right", "move_down", "move_up")
		if input.length_squared() > 0.0:
			var world := ViewMath.camera_relative(input.normalized(), cam.settled_yaw()) * SPEED * delta
			facing = Vector3(world.x, 0, world.y).normalized()
			var before := position
			position = walk_space.slide(position, world, RADIUS)
			moving = before.distance_squared_to(position) > 1e-8

	sprite.camera_yaw = cam.current_yaw
	sprite.facing = facing
	if pose != "":
		sprite.play(pose)
	elif _climbing and not _path.is_empty() and absf((_path[0] - position).y) > 0.05:
		sprite.facing = -cam.back_vector()        # climbing faces the wall: we see her back
		sprite.play("climb")
	elif moving or moving_override:
		sprite.play("walk")
	else:
		sprite.play("idle")
	moving_override = false
