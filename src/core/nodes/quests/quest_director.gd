class_name QuestDirector
extends ChapterDirector

## Chapter 1, The Blue Pipe, start to finish. Linear narrative, spatial freedom.
##
## Owns the story stage and its flags, every conversation branch, the
## perspective discoveries (the service door, the airshaft handholds, the lost
## pigeon), Wai's errand with the washing, and the ending. Timed
## beats run on game time and pause while the player reads.

signal stage_changed(stage: int)
signal ending_started

const S := preload("res://src/core/models/quests/quest_stage.gd")

var flags := {
	"received_camera": false, "photographed_lau": false, "met_chan": false, "found_chan_son": false,
	"helped_ng": false, "fabric_moved": false, "delivered_medicine": false, "returned_home": false,
	"rooftop_visited": false, "roof_door_open": false, "pigeon_found": false,
	# setups the later chapters pay off
	"setup_old_photo_seen": false, "setup_lau_windows": false, "setup_ng_home_line": false, "setup_wong_bet": false,
	"setup_boxes": false, "setup_blue_pipe": false, "theme_rotation": false, "setup_mei_photographs": false,
	"setup_mei_not_subject": false, "mum_kit_mentioned": false,
}
var errand: Dictionary = {}
var sheet_down := false
var ng_briefed := false
var _hints := {"move": true, "rotate": false, "camera": false, "scrapbook": false}
var _moved := 0.0
var _last_pos := Vector3.ZERO
var _dead_end_t := 0.0
var _pigeon_anim: Dictionary = {}
var _pigeon_home := false
var _sheet_t := -1.0
var _homecoming := false
var _lau_intro_done := false
var crate_found := false
var crate_placed := false
var plane_flown := false
var _push: Array[Dictionary] = []          # the crate being dragged and pushed, step by step
var _tutorial := false


func setup() -> void:
	_bind()
	photography.photo_kept.connect(_on_photo_kept)
	photography.subject_locked.connect(_on_subject_locked)
	photography.shutter_ready = _shutter_ready
	dialogue.event_fired.connect(_on_dialogue_event)
	world.resident_blocked.connect(func(id: String) -> void:
		if id == "son":
			hud.notice("notice.wai_coming_through", 2.4))
	_register_shared()
	_register_interactions()
	_register_photo_targets()
	flags.setup_boxes = true      # the flat loads with Mum already packing


func is_complete() -> bool:
	return stage == S.COMPLETE


func stage_name() -> String:
	return QuestStage.name_of(stage)


func can_go_upstairs() -> bool:
	return stage >= S.LAU_PHOTO


func roof_door_open() -> bool:
	return flags.roof_door_open


func ladder_reachable() -> bool:
	return crate_placed


func ladder_found() -> bool:
	return crate_found


func _ladder_free() -> bool:
	return _push.is_empty()


func _look_at_old_photo() -> void:
	# the print itself, held up close while they talk about it; Grandfather has something to say about it once
	hud.show_photo(OLD_PHOTO)
	if flags.setup_old_photo_seen:
		say("old_photo_again", hud.hide_photo)
	else:
		say("old_photo", func() -> void:
			flags.setup_old_photo_seen = true
			hud.hide_photo())


# ----------------------------------------------------------------------------- stage


func set_stage(s: int) -> void:
	stage = s
	flags.merge(QuestStage.flags_for(s), true)
	var o: Array = QuestStage.OBJECTIVES.get(s, ["", ""])
	objective = o[0]
	hint = o[1]
	hud.set_objective(objective, hint)
	_sync_world()
	stage_changed.emit(s)


## Debug stage jumps: the world always matches the stage.
func force_stage(s: int) -> void:
	s = clampi(s, 0, S.COMPLETE)
	scrapbook.entries = QuestStage.scrapbook_for(s)
	photography.has_camera = s >= S.MEDICINE_RECEIVED
	_reset_errand(s >= S.FABRIC_MOVED)
	var door := world.door("serviceDoor")
	if s >= S.REACHED_LAU:
		door.discovered = true
		world.open_door(door)
	if s >= S.FOUND_SON:
		crate_found = true
		crate_placed = true
		world.move_crate(world.refs.crateEnd)
	_pigeon_home = s >= S.HELPED_NG
	if s >= S.HELPED_NG:
		flags.pigeon_found = true
		if not sheet_down:
			sheet_down = true
			world.sheet_blocking = false
			_sheet_t = 1.0
	set_stage(s)


func _sync_world() -> void:
	flags.fabric_moved = world.fabric_state != "catwalk"
	if stage >= S.FABRIC_MOVED:
		flags.roof_door_open = not errand.is_empty() and errand.get("door_open", false)
	# Mum has gone out by the time Mei gets home ("Your mother saved you some rice")
	var mum: Resident = world.residents.get("mum")
	var mum_out := stage >= S.MEDICINE_DELIVERED
	if mum and mum.gone != mum_out:
		mum.gone = mum_out
		mum.visible = not mum_out
	var bird: Node3D = world.special.LostPigeon
	if _pigeon_anim.is_empty():
		var path := world.level_data.pigeon_path
		# home in the coop from the moment she lands, not only once Mr. Ng has finished talking
		bird.position = path[path.size() - 1] if (stage >= S.HELPED_NG or _pigeon_home) else path[0]


func on_enter_roof() -> void:
	flags.rooftop_visited = true
	super.on_enter_roof()


func _plane_over() -> void:
	world.play_plane()
	audio.plane()


# ----------------------------------------------------------------------------- interactions


func _register_interactions() -> void:
	var I := interaction
	var w := world

	talk("grandfather", 1.5, func() -> void:
		if stage == S.START:
			say("grandfather_intro", func() -> void: set_stage(S.MEDICINE_RECEIVED))
		elif stage >= S.RETURNED_HOME:
			say("grandfather_end")
		elif stage >= S.CATWALK_BLOCKED:
			say("grandfather_late")
		else:
			say("grandfather_idle"))

	talk("mum", 1.4, func() -> void:
		if not flags.mum_kit_mentioned:
			_mum_kit()
		else:
			say("mum_idle"))

	talk("lau", 2.0, func() -> void:
		if stage <= S.MEDICINE_RECEIVED:
			_lau_intro()
		elif stage == S.REACHED_LAU:
			say("lau_waiting")
		elif stage >= S.MEDICINE_DELIVERED:
			say("lau_return")
		elif not flags.setup_lau_windows:
			say("lau_windows", func() -> void: flags.setup_lau_windows = true)
		else:
			say("lau_idle"))

	talk("chan", 1.9, func() -> void:
		if stage < S.CATWALK_BLOCKED:
			say("chan_early")
		elif stage == S.CATWALK_BLOCKED:
			mark("chanReached")
			say("chan_quest", func() -> void:
				set_stage(S.MET_CHAN)
				set_stage(S.SEARCHING_FOR_SON))
		elif stage < S.FOUND_SON:
			say("chan_waiting")
		elif stage < S.FABRIC_MOVED:
			say("chan_told")
		elif w.fabric_state == "catwalk":
			say("chan_coming")
		else:
			say("chan_after"))

	talk("son", 1.6, func() -> void:
		var step: String = errand.get("step", "")
		if step == "waiting" or step == "unpinning":
			say("son_catwalk")
		elif stage >= S.FABRIC_MOVED:
			say("son_after")
		elif stage == S.HELPED_NG:
			say("son_photo")
		elif stage == S.FOUND_SON:
			say("son_waiting")
		elif stage == S.CATWALK_BLOCKED:
			say("son_found_nochan", func() -> void: set_stage(S.FOUND_SON))
		elif stage >= S.MET_CHAN:
			say("son_found", func() -> void: set_stage(S.FOUND_SON))
		else:
			say("son_shh"))

	talk("ng", 1.9, func() -> void:
		if stage < S.MET_CHAN:
			say("ng_stranger")
		elif stage < S.FOUND_SON:
			say("ng_early")
		elif stage == S.FOUND_SON:
			if ng_briefed:
				say("ng_waiting")
			else:
				say("ng_quest", func() -> void: ng_briefed = true)
		elif stage == S.HELPED_NG:
			say("ng_waiting_photo")
		else:
			say("ng_after"))

	talk("wong", 1.9, func() -> void:
		if stage >= S.MEDICINE_DELIVERED:
			say("wong_after")
			return
		mark("wongReached")
		say("wong_deliver", func() -> void: set_stage(S.MEDICINE_DELIVERED)))

	for amb in [["chopper", "chopper", 1.8], ["mahjong2", "mahjong", 1.9], ["fanman", "fanman", 1.3],
			["shopkeeper", "shopkeeper", 2.2], ["worker", "worker", 1.5], ["child", "child", 1.5]]:
		var line: String = amb[1]
		talk(amb[0], amb[2], func() -> void: say(line))

	var refs := w.refs
	I.add({"id": "fabric", "position": refs.fabricPos, "radius": 1.4, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.look",
		"can_interact": func() -> bool: return w.fabric_state == "catwalk" and not (errand.get("step", "") in ["waiting", "unpinning"]),
		"interact": func() -> void:
			if stage == S.LAU_PHOTO:
				say("fabric_first", func() -> void: set_stage(S.CATWALK_BLOCKED))
			else:
				say("fabric_again")})

	# the airshaft: the ladder's bottom rungs have rusted away. An old crate is
	# hidden behind a broken fridge; turn the view to find it, push it under the
	# ladder, and climb.
	I.add({"id": "crate", "radius": 1.2, "priority": InteractionDirector.Priority.QUEST, "verb": "verb.push",
		"position": func() -> Vector3: return (w.special.Crate as Node3D).global_position,
		"can_interact": func() -> bool: return crate_found and not crate_placed and _push.is_empty(),
		"interact": _push_crate})
	# the lost pigeon: find her first (the tank hides her from most sides),
	# then work out why she won't come down
	I.add({"id": "sheet", "position": refs.sheetSpot, "radius": 1.6, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.look", "can_interact": func() -> bool: return not sheet_down,
		"interact": func() -> void:
			if stage == S.FOUND_SON and flags.pigeon_found:
				once("sheet_unpin", _unpin_sheet)
			else:
				say("sheet_plain")})

	# the empty flat's back window: nothing to do with today
	look("unitWindowLook", refs.unitWindowOutside, "env.unit_window", 1.0)

	# the packing boxes: worth a look once Mei is home again
	I.add({"id": "boxes", "position": refs.boxes, "radius": 1.3, "priority": InteractionDirector.Priority.ENV,
		"verb": "verb.look", "can_interact": func() -> bool: return stage == S.RETURNED_HOME,
		"interact": func() -> void: say("boxes_end")})
	# the rice Mum saved her (Grandfather mentions it): the day ends as she sits down to eat
	I.add({"id": "rice", "position": refs.rice, "radius": 1.1, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.eat", "can_interact": func() -> bool: return stage == S.RETURNED_HOME,
		"interact": func() -> void: say("rice_end", _ending)})


func _register_photo_targets() -> void:
	photography.add_target("lau", world.residents.lau, func() -> bool: return stage == S.REACHED_LAU and not scrapbook.entries.has("lau"))
	photography.add_target("ng", world.residents.ng, func() -> bool: return stage == S.HELPED_NG and not scrapbook.entries.has("ng"))


# ----------------------------------------------------------------------------- the washing
#
# After Mr. Ng's photo Wai opens the stuck stair door and goes down
# to the catwalk. He waits there until Mei arrives, takes the washing down in
# front of her, carries it back upstairs and hangs it on the roof line. The
# catwalk is on the only route to Mrs. Wong, so everyone sees the washing move.


func _start_son_errand() -> void:
	errand = {"step": "to_door", "door_open": false}
	var R := LevelBuilder.LEVEL_ROOF
	world.residents.son.walk([Vector3(7.5, R, -11.3), Vector3(10.4, R, -11.6)], _errand_at_roof_door)


func _errand_at_roof_door() -> void:
	audio.creak()
	errand.door_open = true
	errand.step = "downstairs"
	world.residents.son.fade("out")
	# comes out on the landing, but never right on top of Mei
	later(_errand_on_landing, 2.5, func() -> bool: return not mei_near(10.4, LevelBuilder.LEVEL_B, -14.1, 1.2))


func _errand_on_landing() -> void:
	var son: Resident = world.residents.son
	var B := LevelBuilder.LEVEL_B
	son.place_at(Vector3(10.4, B, -14.1))
	son.fade("in")
	errand.step = "to_catwalk"
	son.walk([Vector3(11.6, B, -12.3), Vector3(15.0, B, -11.55)], _errand_at_washing)


func _errand_at_washing() -> void:
	errand.step = "waiting"
	# waits by the washing until Mei is close enough to see
	later(_errand_unpin, 0.0, func() -> bool: return mei_near(15.0, LevelBuilder.LEVEL_B, -12, 5.5))


func _errand_unpin() -> void:
	var son: Resident = world.residents.son
	errand.step = "unpinning"
	son.face_toward(Vector3(16, LevelBuilder.LEVEL_B, -12), 3.5)
	son.idle_anim = "work"
	son.sprite.play("work")
	hud.notice("notice.wai_still_wet", 3.2)
	later(_errand_carry, 3.5)


func _errand_carry() -> void:
	var son: Resident = world.residents.son
	var B := LevelBuilder.LEVEL_B
	world.set_fabric_state("bundle")
	son.idle_anim = "idle"
	errand.step = "carrying"
	son.walk([Vector3(11.6, B, -12.3), Vector3(10.4, B, -14.1)], _errand_upstairs)


func _errand_upstairs() -> void:
	audio.creak()
	errand.step = "upstairs"
	world.residents.son.fade("out")
	later(_errand_on_roof, 2.5, func() -> bool: return not mei_near(10.4, LevelBuilder.LEVEL_ROOF, -11.6, 1.2))


func _errand_on_roof() -> void:
	var son: Resident = world.residents.son
	var R := LevelBuilder.LEVEL_ROOF
	son.place_at(Vector3(10.4, R, -11.6))
	son.fade("in")
	errand.step = "to_line"
	# along the roof, clear of the pots and the line poles
	son.walk([Vector3(4, R, -11), Vector3(-3, R, -11), Vector3(-4.4, R, -9.6)], _errand_done)


func _errand_done() -> void:
	# he reaches up and pegs the sheets out; then they hang and his arms are free
	var son: Resident = world.residents.son
	errand.step = "hanging"
	son.face_toward(Vector3(-4.4, LevelBuilder.LEVEL_ROOF, -8.54), 2.4)
	world.set_fabric_state("roof")
	son.idle_anim = "work"
	son.sprite.play("work")
	later(_errand_hung, 1.6)


func _errand_hung() -> void:
	var son: Resident = world.residents.son
	son.idle_anim = "idle"
	son.sprite.play("idle")
	errand.step = "done"


func _reset_errand(finished: bool) -> void:
	_tasks.clear()
	var son: Resident = world.residents.son
	son.gone = false
	son.visible = true
	son.sprite.fade = 1.0
	son.idle_anim = "idle"
	if finished:
		errand = {"step": "done", "door_open": true}
		world.set_fabric_state("roof")
		son.place_at(Vector3(-4.4, LevelBuilder.LEVEL_ROOF, -9.6))
	else:
		errand = {}
		world.set_fabric_state("catwalk")
		son.place_at(Vector3(0.2, LevelBuilder.LEVEL_ROOF, -19.4))


# ----------------------------------------------------------------------------- discovery
#
# Nothing appears or disappears when the view turns. Turning only changes
# what Mei can see, and she can only use what she has seen.


func _discover() -> void:
	if cam.rotating or (locks.is_locked() and not player.on_path()):
		return
	var p := player.position
	for d in world.doors:
		if d.discovered:
			continue
		if PerspectiveRules.door_seen(d.pos, d.normal, p, cam.current_yaw):
			d.discovered = true
			audio.chime()
			mark("found:" + String(d.id))

	if not crate_found and PerspectiveRules.in_shaft(p) and p.y < 7.0:
		var crate: Vector3 = (world.special.Crate as Node3D).global_position + Vector3(0, 0.45, 0)
		if cam.on_screen(crate) and not _hidden_by_fridge(crate):
			crate_found = true
			audio.chime()
			hud.notice("notice.crate_found", 3.2)

	# the pigeon: really hidden by the tank, checked with a ray
	if not flags.pigeon_found and p.y > 12.0 and stage < S.HELPED_NG:
		var bird: Vector3 = (world.special.LostPigeon as Node3D).global_position + Vector3(0, 0.2, 0)
		if bird.distance_to(p) < 16.0 and cam.on_screen(bird) and not _occluded_by_tank(bird):
			flags.pigeon_found = true
			audio.chime()
			hud.notice("notice.pigeon_found_known" if stage >= S.FOUND_SON else "notice.pigeon_found", 3.6)


func _occluded_by_tank(target: Vector3) -> bool:
	# a ray from the camera side to the bird, against the tank's cylinder
	var dir := -cam.camera.global_transform.basis.z
	var origin := target - dir * 40.0
	var tank: Vector3 = (world.special.Tank as Node3D).global_position
	var radius := 1.25
	var half_h := 1.0
	# 2D circle test in XZ, then the height at the closest approach
	var o2 := Vector2(origin.x - tank.x, origin.z - tank.z)
	var d2 := Vector2(dir.x, dir.z)
	var a := d2.dot(d2)
	var b := 2.0 * o2.dot(d2)
	var c := o2.dot(o2) - radius * radius
	var disc := b * b - 4.0 * a * c
	if disc < 0.0 or a < 1e-6:
		return false
	var t := (-b - sqrt(disc)) / (2.0 * a)
	if t < 0.0 or t > 39.7:
		return false
	var y := origin.y + dir.y * t
	return absf(y - tank.y) <= half_h


## Is the crate hidden from the camera by the fridge standing in front of it?
## The crate counts as seen only when most of it shows past the fridge
## (checked at its middle, its top and both top corners). The ladder's rungs
## cross it from one side but never hide it.
func _hidden_by_fridge(target: Vector3) -> bool:
	var toward_cam := cam.camera.global_transform.basis.z
	var blockers: Array[AABB] = [AABB(world.refs.fridgeMin, world.refs.fridgeMax - world.refs.fridgeMin)]
	var right := cam.right_vector()
	var probes: Array[Vector3] = [target, target + Vector3(0, 0.3, 0),
		target + Vector3(0, 0.3, 0) + right * 0.3, target + Vector3(0, 0.3, 0) - right * 0.3]
	var blocked := 0
	for q in probes:
		for bx in blockers:
			if bx.intersects_segment(q, q + toward_cam * 30.0) != null:
				blocked += 1
				break
	return blocked >= 2


## Drag the crate out from behind the fridge, step round it, shove it under the ladder.
func _push_crate() -> void:
	var Y := LevelBuilder.LEVEL_B
	var z := -19.95
	locks.lock("push")
	audio.creak()
	_push = [
		{"mei": Vector3(-4.35, Y, z), "crate": null, "speed": 2.4},
		{"mei": Vector3(-6.15, Y, z), "crate": Vector3(-5.35, Y, z), "speed": 1.1, "face": Vector3(1, 0, 0)},
		{"mei": Vector3(-6.15, Y, -20.66), "crate": null, "speed": 2.4},
		{"mei": Vector3(-4.35, Y, -20.66), "crate": null, "speed": 2.4},
		{"mei": Vector3(-4.35, Y, z), "crate": null, "speed": 2.4},
		{"mei": Vector3(-5.65, Y, z), "crate": world.refs.crateEnd, "speed": 1.1, "face": Vector3(-1, 0, 0)},
	]


func _tick_push(delta: float) -> void:
	if _push.is_empty():
		return
	var step: Dictionary = _push[0]
	var to: Vector3 = step.mei
	var d := to - player.position
	var move := float(step.speed) * delta
	var crate: Node3D = world.special.Crate
	if step.crate != null:
		var cto: Vector3 = step.crate
		var cd := cto - crate.position
		if cd.length() > 0.001:
			world.move_crate(crate.position + cd.normalized() * minf(move, cd.length()))
	if d.length() <= move:
		player.position = to
		_push.pop_front()
		if _push.is_empty():
			crate_placed = true
			player.pose = ""
			locks.unlock("push")
			audio.creak()
	else:
		player.position += d.normalized() * move
		player.facing = step.get("face", d.normalized())
		player.moving_override = true


func _unpin_sheet() -> void:
	sheet_down = true
	world.sheet_blocking = false
	_sheet_t = 0.0
	player.pose = "reach"
	later(_after_unpin, 0.6)


func _after_unpin() -> void:
	player.pose = ""
	_guide_pigeon()


# ----------------------------------------------------------------------------- story beats


func start_intro() -> void:
	say("grandfather_intro", func() -> void:
		set_stage(S.MEDICINE_RECEIVED)
		_perspective_tutorial())


## A near-wordless lesson: the keys appear, the view turns once by itself and
## back, then it is the player's turn. It clears after they have turned both ways.
func _perspective_tutorial() -> void:
	_tutorial = true
	locks.lock("tutorial")
	hud.tutorial_show()
	await get_tree().create_timer(1.1).timeout
	hud.tutorial_press(1)
	locks.unlock("tutorial")
	cam.rotate_view(1)
	locks.lock("tutorial")
	await get_tree().create_timer(1.3).timeout
	hud.tutorial_press(-1)
	locks.unlock("tutorial")
	cam.rotate_view(-1)
	locks.lock("tutorial")
	await get_tree().create_timer(0.8).timeout
	locks.unlock("tutorial")
	hud.tutorial_your_turn()
	var turned := {}
	var prev := cam.direction
	while turned.size() < 2:
		var now: int = await cam.rotation_started
		var step := 1 if posmod(now - prev, 4) == 1 else -1
		prev = now
		turned[step] = true
		hud.tutorial_press(step)
	await get_tree().create_timer(0.6).timeout
	hud.tutorial_hide()
	_tutorial = false
	flags.theme_rotation = true
	hud.show_hint("hint.move_interact")


## Mum, without looking up from the boxes, as Mei heads for the door.
func _mum_kit() -> void:
	flags.mum_kit_mentioned = true
	say("mum_kit")


func _lau_intro() -> void:
	if _lau_intro_done:
		return
	_lau_intro_done = true
	mark("lauReached")
	say("lau_intro", func() -> void:
		set_stage(S.REACHED_LAU)
		_hints.camera = true
		hud.show_hint("hint.raise_camera"))


func _guide_pigeon() -> void:
	locks.lock("pigeon")
	audio.flutter()
	var bird: CharacterSprite = world.special.LostPigeon
	bird.play("fly")
	var curve := Curve3D.new()
	for pt in world.level_data.pigeon_path:
		curve.add_point(pt)
	# smooth the flight through the points
	for i in curve.point_count:
		var prev := curve.get_point_position(maxi(0, i - 1))
		var next := curve.get_point_position(mini(curve.point_count - 1, i + 1))
		var tangent := (next - prev) * 0.25
		curve.set_point_in(i, -tangent)
		curve.set_point_out(i, tangent)
	_pigeon_anim = {"t": 0.0, "curve": curve, "duration": 3.2}


## The trap in the coop roof: it lifts as the bird comes down onto it, and
## drops shut with a clack once she is through.
func _tick_flap(delta: float) -> void:
	var flap: Node3D = world.special.get("CoopFlap")
	if flap == null:
		return
	var want := 0.0
	if not _pigeon_anim.is_empty():
		var bird: Node3D = world.special.LostPigeon
		var hole: Vector3 = world.refs.coopHole
		var d := Vector2(bird.position.x - hole.x, bird.position.z - hole.z).length()
		if d < 1.6 and bird.position.y > hole.y - 0.6 and bird.position.y < hole.y + 1.3:
			want = 1.9      # thrown right back, past upright, well clear of her
	var cur := flap.rotation.z
	if is_equal_approx(cur, want):
		return
	var next := move_toward(cur, want, delta * (11.0 if want > cur else 7.5))
	if next <= 0.0 and cur > 0.0:
		audio.clack()
	flap.rotation.z = next


func _on_pigeon_home() -> void:
	_pigeon_anim = {}
	_pigeon_home = true
	var bird: CharacterSprite = world.special.LostPigeon
	bird.play("idle")
	locks.unlock("pigeon")
	audio.coo()
	say("ng_helped", func() -> void:
		set_stage(S.HELPED_NG)
		hud.show_hint("hint.raise_camera")
		_hints.camera = true)


func _on_dialogue_event(e: String) -> void:
	if e == "receiveCamera":
		flags.received_camera = true
		photography.has_camera = true
	elif e == "planeApproaches":
		# a roar builds far off; the jet itself comes over for the photograph
		world.residents.ng.idle_anim = "proud"
		world.residents.ng.sprite.play("proud")


## The shutter fires just before the jet crosses Mr. Ng's roof, so it is in the
## print. If it has already gone, another comes in: Kai Tak's arrivals came
## over the City every few minutes.
func _shutter_ready(id: String) -> bool:
	if id != "ng":
		return true
	var x := world.plane_x()
	if x == INF or x > -8.0:
		world.play_plane()
		audio.plane()
		return false
	return x > -21.0


## Mr. Ng in the viewfinder: the jet comes in low over the roof, into the picture.
func _on_subject_locked(id: String) -> void:
	if id == "ng" and not plane_flown:
		plane_flown = true
		world.play_plane()
		audio.plane()


func _on_photo_kept(id: String) -> void:
	await scrapbook.file_photo(id)
	if id == "lau":
		say("lau_after_photo", func() -> void:
			set_stage(S.LAU_PHOTO)
			_hints.scrapbook = true
			hud.show_hint("hint.scrapbook")
			later(_clear_scrapbook_hint, 9.0))
	elif id == "ng":
		say("son_leaves", func() -> void:
			_start_son_errand()
			set_stage(S.FABRIC_MOVED))


func _clear_scrapbook_hint() -> void:
	if _hints.scrapbook:
		_hints.scrapbook = false
		hud.show_hint("")


func _home_again() -> void:
	mark("homeReached")
	locks.lock("homecoming")
	await get_tree().create_timer(0.4).timeout
	locks.unlock("homecoming")
	# the day ends only when the player chooses to sit down and eat
	say("grandfather_return", func() -> void: set_stage(S.RETURNED_HOME))


func _ending() -> void:
	if stage == S.COMPLETE:
		return
	set_stage(S.COMPLETE)
	mark("ending")
	locks.lock("ending")
	hud.set_quiet(true)
	audio.silence(3.2)
	ending_started.emit()
	await fade.fade_out(3.0)
	slice.ending.play(30, "ending.ch1", Progress.LAST > 1)


# ----------------------------------------------------------------------------- per frame


func tick(delta: float, paused: bool) -> void:
	var p := player.position
	_run_tasks(delta, paused)
	_tick_push(delta)
	_discover()
	if _sheet_t >= 0.0 and _sheet_t < 1.0:
		_sheet_t = minf(1.0, _sheet_t + delta * 2.0)
	if _sheet_t >= 0.0:
		(world.special.Sheet as Node3D).rotation.x = -_sheet_t * 1.2   # one corner unpinned, swung aside
	_sync_world()

	if not _pigeon_anim.is_empty():
		_pigeon_anim.t += delta / float(_pigeon_anim.duration)
		var t := minf(1.0, float(_pigeon_anim.t))
		var curve: Curve3D = _pigeon_anim.curve
		var bird: Node3D = world.special.LostPigeon
		var pos := curve.sample_baked(t * curve.get_baked_length())
		var ahead := curve.sample_baked(minf(1.0, t + 0.02) * curve.get_baked_length())
		bird.position = pos
		(bird as CharacterSprite).facing = (ahead - pos).normalized()
		if t >= 1.0:
			_on_pigeon_home()
	_tick_flap(delta)

	if _hints.move and stage >= S.MEDICINE_RECEIVED:
		_moved += p.distance_to(_last_pos)
		if _moved > 6.0:
			_hints.move = false
			if not _hints.camera and not _hints.scrapbook:
				hud.show_hint("")
	_last_pos = p

	if stage >= S.MEDICINE_RECEIVED and p.x > -5.8 and p.y < 1.0:
		mark("apartmentExit")

	# at the dead end, remind the player that the view turns (the control, not the answer)
	var door := world.door("serviceDoor")
	var at_dead_end := stage >= S.MEDICINE_RECEIVED and p.y < 1.0 and p.x > 0.0 and p.x < 2.0 and absf(p.z) < 1.2
	_dead_end_t = _dead_end_t + delta if (at_dead_end and not door.discovered) else 0.0
	if _dead_end_t > 2.5 and not _hints.rotate:
		_hints.rotate = true
		hud.show_hint("hint.turn_view")
	elif _hints.rotate and (door.discovered or not at_dead_end):
		_hints.rotate = false
		hud.show_hint("")

	if _hints.camera and photography.active:
		_hints.camera = false
		hud.show_hint("")
	if _hints.scrapbook and scrapbook.open:
		_hints.scrapbook = false
		hud.show_hint("")
	# the album's first pages: everyone Mei has seen, and never Mei
	if scrapbook.open and not flags.setup_mei_not_subject:
		flags.setup_mei_not_subject = true

	# getting ready to leave: Mum mentions Kit on Mei's way to the door
	if stage == S.MEDICINE_RECEIVED and not flags.mum_kit_mentioned and not _tutorial and not locks.is_locked() \
			and p.y < 1.0 and p.x > -8.2 and p.x < -6.0 and absf(p.z) < 1.6:
		_mum_kit()

	# walking into Lau's clinic
	if stage == S.MEDICINE_RECEIVED and p.y < 1.0 and p.x > 0.0 and p.x < 8.0 and p.z < -9.4 and p.z > -15.0 and not locks.is_locked():
		_lau_intro()

	# coming home
	if stage == S.MEDICINE_DELIVERED and p.y < 1.0 and p.x < -6.6 and not locks.is_locked() and not _homecoming:
		_homecoming = true
		_home_again()
