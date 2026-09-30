class_name PhotographyDirector
extends Node

## Camera mode, through Mei's eyes.
##
## Raising the camera: she lifts it in the diorama view, the view dips into her
## eyes, her hands bring it up in front of her, then closer and closer to her
## face until she is looking straight through the eyepiece, and the viewfinder
## opens. The mouse turns her head;
## WASD walks her, the view swaying with her steps. A ray from the centre of the
## frame finds the subject; only someone who matters, at the right moment, can
## be taken. The print is what she framed: flash, shutter, the camera comes
## down, the Polaroid develops, and it goes into the scrapbook.

signal photo_kept(id: String)
## The reticle has just found someone who can be photographed now.
signal subject_locked(id: String)

const LOOK_SENSITIVITY := 0.0022
const PAD_LOOK_SPEED := 2.2          # radians a second, the right stick held over
## Where her hands start (art pixels below where they are drawn) as she lifts
## the camera, and where they end up just before it reaches her eye.
const HANDS_LOW := 78.0
const HANDS_HIGH := -10.0

@export var locks: ControlLocks
@export var cam: CameraRig
@export var player: Player
@export var viewfinder: Viewfinder
@export var polaroid: PolaroidView
@export var fade: ScreenFade
@export var hud: Hud
@export var audio: AudioZones
@export var studio: PhotoStudio

## The camera is up, or on its way up or down.
var active := false
## At her eye and ready: looking, walking, framing.
var aiming := false
var showing_photo := false
var has_camera := false
var subject: Dictionary = {}
## id -> Texture2D, the prints Mei has kept
var photos: Dictionary = {}
var _targets: Array[Dictionary] = []
var _pending := ""
var _locked_id := ""
var _waiting := false
var _moving := false
## Whether the shutter may fire yet for a subject (the jet for Mr. Ng).
var shutter_ready: Callable


## A photo target: a resident and when a picture of them counts.
func add_target(id: String, resident: Resident, valid: Callable) -> void:
	_targets.append({"id": id, "resident": resident, "valid": valid})


func enter() -> bool:
	if active or locks.is_locked() or not has_camera:
		return false
	active = true
	_moving = true
	locks.lock("camera")
	hud.set_quiet(true)
	audio.click()
	_raise()
	return true


func exit() -> void:
	if not active or _moving:
		return
	_lower()


## Down and back to the diorama at once (a debug jump, a scene change).
func drop() -> void:
	if not active:
		return
	_set_first_person(false)
	viewfinder.close()
	viewfinder.iris = 0.0
	player.pose = ""
	active = false
	aiming = false
	_moving = false
	locks.unlock("camera")
	hud.set_quiet(false)


func _raise() -> void:
	# she lifts it in the diorama view...
	player.pose = "camera"
	await get_tree().create_timer(0.3).timeout
	await fade.fade_out(0.12)
	# ...and the view goes to her eyes, the camera still at her chest
	var f := player.facing
	cam.fp_yaw = atan2(-f.x, -f.z)
	cam.fp_pitch = 0.0
	cam.fp_walk = 0.0
	cam.fp_feet = player.position
	player.pose = ""
	_set_first_person(true)
	viewfinder.visible = true
	viewfinder.frame_alpha = 0.0
	viewfinder.iris = 0.0
	viewfinder.set_hands(Viewfinder.CARRY, Vector2(0, HANDS_LOW))
	await get_tree().create_timer(0.1).timeout      # the walls settle solid while it's dark
	fade.fade_in(0.14)
	await _tween_hands(HANDS_LOW, HANDS_HIGH, 0.32, Tween.EASE_OUT)
	# up to her face, until she is looking through the eyepiece: it goes dark
	# as the eyepiece closes over her eye
	await _tween_zoom(1.0, Viewfinder.ZOOM_IN, 0.42, Tween.EASE_IN, 1.0)
	viewfinder.set_hands(-1)
	viewfinder.frame_alpha = 1.0
	await _tween_iris(0.0, 0.16)
	_moving = false
	aiming = true


func _lower() -> void:
	_moving = true
	aiming = false
	subject = {}
	viewfinder.locked_on = false
	await _tween_iris(1.0, 0.08)
	viewfinder.frame_alpha = 0.0
	viewfinder.set_hands(Viewfinder.CARRY, Vector2(0, HANDS_HIGH), Viewfinder.ZOOM_IN)
	# away from her face (the dark lifting as the eyepiece leaves her eye), then down
	await _tween_zoom(Viewfinder.ZOOM_IN, 1.0, 0.34, Tween.EASE_OUT, 0.0)
	await _tween_hands(HANDS_HIGH, HANDS_LOW + 40.0, 0.24, Tween.EASE_IN)
	await fade.fade_out(0.1)
	# back in the diorama, facing the way she was looking
	player.facing = -ViewMath.back(cam.fp_yaw)
	_set_first_person(false)
	viewfinder.close()
	fade.fade_in(0.16)
	active = false
	_moving = false
	locks.unlock("camera")
	hud.set_quiet(false)


func _set_first_person(on: bool) -> void:
	cam.first_person = on
	studio.world.first_person = on
	player.first_person = on
	player.hidden = on
	if not on:
		cam.snap_next = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE


func _tween_hands(from: float, to: float, secs: float, easing: Tween.EaseType) -> void:
	var t := create_tween()
	t.tween_method(func(y: float) -> void: viewfinder.set_hands(Viewfinder.CARRY, Vector2(0, y) + _hand_bob()),
		from, to, secs).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	await t.finished


## The camera coming to (or leaving) her eye: it grows about the eyepiece.
## Zoom is eased in log space, so the approach reads as steady. The iris goes
## to `iris_to` over the closest stretch of it (the last 40% coming in, the
## first 40% going out), so the eyepiece's big pixels are never held on screen.
func _tween_zoom(from: float, to: float, secs: float, easing: Tween.EaseType, iris_to: float) -> void:
	var t := create_tween().set_parallel()
	t.tween_method(func(u: float) -> void:
			viewfinder.set_hands(Viewfinder.CARRY, Vector2(0, HANDS_HIGH), exp(u)),
		log(from), log(to), secs).set_trans(Tween.TRANS_QUAD).set_ease(easing)
	var closing := iris_to > viewfinder.iris
	t.tween_property(viewfinder, "iris", iris_to, secs * 0.4).set_delay(secs * 0.6 if closing else 0.0)
	await t.finished


func _tween_iris(to: float, secs: float) -> void:
	var t := create_tween()
	t.tween_property(viewfinder, "iris", to, secs)
	await t.finished


## Her hands move with her walk: they dip and swing a little against the view.
func _hand_bob() -> Vector2:
	var sw := cam.fp_sway()
	return Vector2(-sw.y * 110.0, -sw.x * 70.0)


func _unhandled_input(event: InputEvent) -> void:
	if not cam.first_person or showing_photo:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel := (event as InputEventMouseMotion).relative
		cam.fp_yaw = wrapf(cam.fp_yaw - rel.x * LOOK_SENSITIVITY, -PI, PI)
		cam.fp_pitch = clampf(cam.fp_pitch - rel.y * LOOK_SENSITIVITY, CameraRig.FP_PITCH_MIN, CameraRig.FP_PITCH_MAX)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not aiming:
		return
	if cam.first_person and not showing_photo:
		var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if look != Vector2.ZERO:
			cam.fp_yaw = wrapf(cam.fp_yaw - look.x * PAD_LOOK_SPEED * delta, -PI, PI)
			cam.fp_pitch = clampf(cam.fp_pitch - look.y * PAD_LOOK_SPEED * 0.7 * delta, CameraRig.FP_PITCH_MIN, CameraRig.FP_PITCH_MAX)

	var vp := cam.camera.get_viewport().get_visible_rect().size
	var origin := cam.camera.project_ray_origin(vp * 0.5)
	var dir := cam.camera.project_ray_normal(vp * 0.5)
	var hit: Dictionary = {}
	var best := INF
	for t in _targets:
		var r: Resident = t.resident
		if not r.visible or r.gone:
			continue
		var c := r.global_position + Vector3(0, 1.0, 0)
		var box := AABB(c - Vector3(0.6, 1.1, 0.6), Vector3(1.2, 2.2, 1.2))
		var d: Variant = box.intersects_ray(origin, dir)
		if d != null:
			var dist := origin.distance_to(d as Vector3)
			if dist < best:
				best = dist
				hit = t
	subject = hit if not hit.is_empty() and (hit.valid as Callable).call() else {}
	viewfinder.locked_on = not subject.is_empty()
	var sid: String = subject.get("id", "")
	if sid != _locked_id:
		_locked_id = sid
		if sid != "":
			subject_locked.emit(sid)
	if _waiting:
		viewfinder.set_status("camera.wait")
	elif not subject.is_empty():
		viewfinder.set_status("camera.take")
	elif not hit.is_empty():
		viewfinder.set_status("camera.not_now")
	else:
		viewfinder.set_status("camera.controls")


func capture() -> void:
	if not aiming or showing_photo:
		return
	if subject.is_empty():
		hud.notice("notice.film_precious")
		return
	var id: String = subject.id
	showing_photo = true
	# hold the shutter for the moment (the jet coming over Mr. Ng's roof)
	if shutter_ready.is_valid():
		var waited := 0.0
		_waiting = true
		while not shutter_ready.call(id) and waited < 6.0:
			await get_tree().process_frame
			waited += get_process_delta_time()
		_waiting = false
	audio.shutter()
	fade.camera_flash()
	# the print is what she framed, at the moment the shutter went
	var tex := await studio.shoot_view(cam.camera, viewfinder.frame_fraction(), subject.resident)
	photos[id] = tex
	await get_tree().create_timer(0.2).timeout
	locks.lock("polaroid")
	await _lower()
	_pending = id
	await polaroid.present(tex, ResidentCatalog.entry(id).name)
	# a moment to look at it, then it goes into the album on its own
	# (Space or F puts it in sooner)
	await get_tree().create_timer(1.2).timeout
	if showing_photo and _pending == id:
		dismiss()


func dismiss() -> bool:
	if not showing_photo or not polaroid.can_dismiss:
		return false
	polaroid.dismiss()
	showing_photo = false
	locks.unlock("polaroid")
	var id := _pending
	_pending = ""
	photo_kept.emit(id)
	return true
