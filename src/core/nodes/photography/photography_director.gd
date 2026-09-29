class_name PhotographyDirector
extends Node

## Camera mode. Movement locks, the interface fades, the viewfinder comes up
## and WASD frames the shot. A ray from the centre of the frame finds the
## subject; only someone who matters, at the right moment, can be taken.
## Then: flash, shutter, the Polaroid developing, and the scrapbook entry.

signal photo_kept(id: String)
## The reticle has just found someone who can be photographed now.
signal subject_locked(id: String)

const MAX_PAN := 6.0

@export var locks: ControlLocks
@export var cam: CameraRig
@export var player: Player
@export var viewfinder: Viewfinder
@export var polaroid: PolaroidView
@export var fade: ScreenFade
@export var hud: Hud
@export var audio: AudioZones
@export var studio: PhotoStudio

var active := false
var showing_photo := false
var has_camera := false
var subject: Dictionary = {}
## id -> Texture2D, the prints Mei has kept
var photos: Dictionary = {}
var _targets: Array[Dictionary] = []
var _pending := ""
var _locked_id := ""
var _waiting := false
## Whether the shutter may fire yet for a subject (the jet for Mr. Ng).
var shutter_ready: Callable


## A photo target: a resident and when a picture of them counts.
func add_target(id: String, resident: Resident, valid: Callable) -> void:
	_targets.append({"id": id, "resident": resident, "valid": valid})


func enter() -> bool:
	if active or locks.is_locked() or not has_camera:
		return false
	active = true
	locks.lock("camera")
	viewfinder.open()
	hud.set_quiet(true)
	cam.pan_offset = Vector3.ZERO
	player.hidden = true
	audio.click()
	return true


func exit() -> void:
	if not active:
		return
	active = false
	locks.unlock("camera")
	viewfinder.close()
	hud.set_quiet(false)
	cam.pan_offset = Vector3.ZERO
	player.hidden = false


func _process(delta: float) -> void:
	if not active:
		return
	var input := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	if input.length_squared() > 0.0:
		var m := ViewMath.camera_relative(input.normalized(), cam.settled_yaw()) * 6.0 * delta
		cam.pan_offset += Vector3(m.x, 0, m.y)
		if cam.pan_offset.length() > MAX_PAN:
			cam.pan_offset = cam.pan_offset.normalized() * MAX_PAN

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
		var box := AABB(c - Vector3(0.8, 1.1, 0.8), Vector3(1.6, 2.2, 1.6))
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
		viewfinder.set_status("Wait for it...")
	elif not subject.is_empty():
		viewfinder.set_status("[SPACE] Take photo")
	elif not hit.is_empty():
		viewfinder.set_status("Not now.")
	else:
		viewfinder.set_status("[WASD] frame    [C] lower camera")


func capture() -> void:
	if not active or showing_photo:
		return
	if subject.is_empty():
		hud.notice("Film is precious. Frame someone who matters.")
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
	await get_tree().create_timer(0.42).timeout
	exit()
	locks.lock("polaroid")
	var tex := await studio.shoot(id)
	photos[id] = tex
	_pending = id
	await polaroid.present(tex, ResidentCatalog.entry(id).name)


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
