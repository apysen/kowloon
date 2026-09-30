class_name CameraRig
extends Node3D

## The diorama camera: orthographic, low, locked to four orientations.
##
## Pitch is 18 degrees, lower than the design guide's 25-35, so walls hide
## more and turning the view actually shows you something new. The view turns
## in quarter steps over 380 ms with an ease in and out; nothing else moves
## while it turns. The focus sits a little past Mei so she stands below centre
## and the room behind her fills the frame, the foreground going soft in the
## tilt-shift.

signal rotation_started(direction: int)
signal rotation_finished(direction: int)

const PITCH := deg_to_rad(18.0)
const DISTANCE := 30.0
const ROTATION_TIME := 0.38
## Half-height of the view in metres at zoom 1 (close, like an HD-2D diorama).
const VIEW_SIZE := 7.0
## First person: through Mei's eyes, with the camera raised.
const FP_FOV := 62.0
const FP_EYE := 1.42
const FP_PITCH_MIN := deg_to_rad(-38.0)
const FP_PITCH_MAX := deg_to_rad(32.0)
## Her walk, felt through the view: a bob twice a stride, a sway and a slight roll once.
const FP_STRIDE := 1.25
const FP_BOB := 0.035
const FP_SWAY := 0.022
const FP_ROLL := deg_to_rad(0.7)

@export var locks: ControlLocks

@onready var camera: Camera3D = $Camera3D

var direction := 0
var current_yaw := 0.0
var rotating := false
var target := Vector3.ZERO
var focus := Vector3.ZERO
var pan_offset := Vector3.ZERO
var zoom_target := 1.0
var zoom := 1.0
var snap_next := true
var has_rotated := false
## First-person view: on, where she stands, and where she looks.
var first_person := false
var fp_feet := Vector3.ZERO
var fp_yaw := 0.0
var fp_pitch := 0.0
## 0..1: how much of her stride's sway shows (eases in and out as she starts and stops)
var fp_walk := 0.0
var fp_phase := 0.0

var _from_yaw := 0.0
var _to_yaw := 0.0
var _rot_t := 1.0


func _ready() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = VIEW_SIZE * 2.0
	camera.near = 0.1
	camera.far = 260.0
	camera.keep_aspect = Camera3D.KEEP_HEIGHT


## Starts a quarter turn (step = -1 or +1). Returns false while already turning.
func rotate_view(step: int) -> bool:
	if rotating:
		return false
	rotating = true
	if locks:
		locks.lock("rotation")
	direction = posmod(direction + step, 4)
	_from_yaw = current_yaw
	_to_yaw = current_yaw + step * PI / 2.0
	_rot_t = 0.0
	has_rotated = true
	rotation_started.emit(direction)
	return true


## Yaw of the settled orientation (used for camera-relative input).
func settled_yaw() -> float:
	return direction * PI / 2.0


func back_vector() -> Vector3:
	return ViewMath.back(current_yaw)


func right_vector() -> Vector3:
	return ViewMath.right(current_yaw)


func follow(p: Vector3) -> void:
	target = p


func _process(delta: float) -> void:
	if rotating:
		_rot_t = minf(1.0, _rot_t + delta / ROTATION_TIME)
		var t := _rot_t
		var eased := 4.0 * t * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0
		current_yaw = lerpf(_from_yaw, _to_yaw, eased)
		if _rot_t >= 1.0:
			current_yaw = _to_yaw
			rotating = false
			if locks:
				locks.unlock("rotation")
			rotation_finished.emit(direction)

	if first_person:
		_first_person(delta)
		return
	if camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.near = 0.1
		camera.rotation.z = 0.0
		snap_next = true

	var goal := target + pan_offset
	goal.y += 1.2
	goal += back_vector() * -2.4
	if snap_next:
		focus = goal
		snap_next = false
	else:
		focus = focus.lerp(goal, 1.0 - pow(0.001, delta))

	var horiz := cos(PITCH) * DISTANCE
	camera.global_position = Vector3(
		focus.x + sin(current_yaw) * horiz,
		focus.y + sin(PITCH) * DISTANCE,
		focus.z + cos(current_yaw) * horiz)
	camera.look_at(focus, Vector3.UP)

	zoom = lerpf(zoom, zoom_target, 1.0 - pow(0.2, delta))
	camera.size = VIEW_SIZE * 2.0 / zoom


## Advance her stride by the distance walked this frame (the sway follows her steps).
func fp_step(distance: float, delta: float) -> void:
	var walking := distance > 1e-4
	fp_walk = move_toward(fp_walk, 1.0 if walking else 0.0, delta * (5.0 if walking else 3.0))
	fp_phase = fmod(fp_phase + distance / FP_STRIDE * TAU, TAU * 8.0)


## The head's offset from standing still: [bob up, sway sideways, roll].
func fp_sway() -> Vector3:
	var w := fp_walk
	return Vector3(-absf(sin(fp_phase)) * FP_BOB * w + FP_BOB * 0.5 * w, sin(fp_phase) * FP_SWAY * w, sin(fp_phase) * FP_ROLL * w)


func _first_person(_delta: float) -> void:
	if camera.projection != Camera3D.PROJECTION_PERSPECTIVE:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = FP_FOV
		camera.near = 0.1         # not closer: depth precision goes to the first few centimetres
	var sw := fp_sway()
	var right := Vector3(cos(fp_yaw), 0.0, -sin(fp_yaw))
	camera.global_position = fp_feet + Vector3(0, FP_EYE + sw.x, 0) + right * sw.y
	camera.global_rotation = Vector3(fp_pitch, fp_yaw, sw.z)


## Is a world point inside the visible frame (with a small margin)?
func on_screen(p: Vector3) -> bool:
	if not camera.is_position_in_frustum(p):
		return false
	var s := camera.unproject_position(p)
	var vp := camera.get_viewport().get_visible_rect().size
	return s.x > vp.x * 0.025 and s.x < vp.x * 0.975 and s.y > vp.y * 0.025 and s.y < vp.y * 0.975
