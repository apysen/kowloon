class_name QuestDirector
extends Node

## The Blue Pipe, start to finish. Linear narrative, spatial freedom.
##
## Owns the story stage and its flags, every conversation branch, the
## perspective discoveries (the service door, the airshaft handholds, the lost
## pigeon), the Chan boy's errand with the washing, and the ending. Timed
## beats run on game time and pause while the player reads.

signal stage_changed(stage: int)
signal ending_started

const S := preload("res://src/core/models/quests/quest_stage.gd")

@export var slice: SliceRoot

var stage := QuestStage.START
var objective := ""
var hint := ""
var flags := {
	"received_camera": false, "photographed_lau": false, "met_chan": false, "found_chan_son": false,
	"helped_ng": false, "fabric_moved": false, "delivered_medicine": false, "returned_home": false,
	"rooftop_visited": false, "roof_door_open": false, "pigeon_found": false,
}
var timings: Dictionary = {}
var start_time := 0.0

var world: World
var player: Player
var cam: CameraRig
var dialogue: DialogueDirector
var interaction: InteractionDirector
var photography: PhotographyDirector
var scrapbook: Scrapbook
var audio: AudioZones
var hud: Hud
var fade: ScreenFade
var locks: ControlLocks

var errand: Dictionary = {}
var sheet_down := false
var ng_briefed := false
var _tasks: Array[Dictionary] = []
var _seen: Dictionary = {}
var _hints := {"move": true, "rotate": false, "camera": false, "scrapbook": false}
var _moved := 0.0
var _last_pos := Vector3.ZERO
var _dead_end_t := 0.0
var _pigeon_anim: Dictionary = {}
var _sheet_t := -1.0
var _homecoming := false
var _lau_intro_done := false
var crate_found := false
var crate_placed := false
var plane_flown := false
var _push: Array[Dictionary] = []          # the crate being dragged and pushed, step by step
var _tutorial := false


func setup() -> void:
	world = slice.world
	player = slice.player
	cam = slice.cam
	dialogue = slice.dialogue
	interaction = slice.interaction
	photography = slice.photography
	scrapbook = slice.scrapbook
	audio = slice.audio
	hud = slice.hud
	fade = slice.fade
	locks = slice.locks
	photography.photo_kept.connect(_on_photo_kept)
	photography.subject_locked.connect(_on_subject_locked)
	photography.shutter_ready = _shutter_ready
	dialogue.event_fired.connect(_on_dialogue_event)
	world.resident_blocked.connect(func(id: String) -> void:
		if id == "son":
			hud.notice("Chan's son: “Excuse me, Mei, coming through!”", 2.4))
	_register_interactions()
	_register_photo_targets()
	start_time = Time.get_ticks_msec() / 1000.0


func mark(name: String) -> void:
	if not timings.has(name):
		timings[name] = Time.get_ticks_msec() / 1000.0 - start_time


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
	var bird: Node3D = world.special.LostPigeon
	if _pigeon_anim.is_empty():
		var path := world.level_data.pigeon_path
		bird.position = path[path.size() - 1] if stage >= S.HELPED_NG else path[0]


# ----------------------------------------------------------------------------- helpers


func say(id: Variant, then := Callable()) -> void:
	var r := _speaker_resident(id)
	if r:
		r.face_toward(player.position, 4.0)
	dialogue.start(id, then)


func _speaker_resident(id: Variant) -> Resident:
	if not id is String:
		return null
	var key := String(id).split("_")[0]
	var map := {"grandfather": "grandfather", "lau": "lau", "chan": "chan", "son": "son", "ng": "ng", "wong": "wong",
		"chopper": "chopper", "mahjong": "mahjong2", "fanman": "fanman", "shopkeeper": "shopkeeper", "worker": "worker", "child": "child"}
	if map.has(key):
		return world.residents.get(map[key])
	return null


## A line the first time only; afterwards just do the action.
func once(id: String, then: Callable) -> void:
	if _seen.has(id):
		then.call()
		return
	_seen[id] = true
	say(id, then)


func later(fn: Callable, secs := 0.0, cond := Callable()) -> void:
	_tasks.append({"t": secs, "fn": fn, "cond": cond})


func _run_tasks(delta: float, paused: bool) -> void:
	if paused:
		return
	var due: Array[Callable] = []
	var keep: Array[Dictionary] = []
	for task in _tasks:
		task.t -= delta
		if task.t <= 0.0 and (not (task.cond as Callable).is_valid() or (task.cond as Callable).call()):
			due.append(task.fn)
		else:
			keep.append(task)
	_tasks = keep
	for fn in due:
		fn.call()


func mei_near(x: float, y: float, z: float, r: float) -> bool:
	var p := player.position
	return absf(p.y - y) < 1.0 and Vector2(p.x - x, p.z - z).length() < r


func transition(pos: Vector3, steps := 8, on_arrive := Callable()) -> void:
	locks.lock("transition")
	audio.footsteps(steps, 0.14)
	await fade.fade_out(0.38)
	player.teleport(pos)
	_sync_world()
	await get_tree().create_timer(0.25).timeout
	fade.fade_in(0.45)
	locks.unlock("transition")
	if on_arrive.is_valid():
		on_arrive.call()


func on_enter_roof() -> void:
	if flags.rooftop_visited:
		return
	flags.rooftop_visited = true
	mark("rooftopReached")
	# a few quiet seconds with no dialogue and no interface, then a jet comes over
	hud.set_quiet(true)
	later(_roof_quiet_over, 6.0)


func _plane_over() -> void:
	world.play_plane()
	audio.plane()


func _roof_quiet_over() -> void:
	if not photography.active:
		hud.set_quiet(false)


# ----------------------------------------------------------------------------- interactions


func _register_interactions() -> void:
	var I := interaction
	var w := world
	var npc := w.residents
	var talk := func(id: String, radius: float, fn: Callable) -> void:
		var r: Resident = npc[id]
		I.add({"id": id, "position": func() -> Vector3: return r.position, "radius": radius,
			"priority": InteractionDirector.Priority.NPC, "verb": "Talk",
			"can_interact": func() -> bool: return r.can_talk(), "interact": fn})

	talk.call("grandfather", 1.5, func() -> void:
		if stage == S.START:
			say("grandfather_intro", func() -> void: set_stage(S.MEDICINE_RECEIVED))
		elif stage >= S.RETURNED_HOME:
			say("grandfather_end")
		elif stage >= S.CATWALK_BLOCKED:
			say("grandfather_late")
		else:
			say("grandfather_idle"))

	talk.call("lau", 2.0, func() -> void:
		if stage <= S.MEDICINE_RECEIVED:
			_lau_intro()
		elif stage == S.REACHED_LAU:
			say("lau_waiting")
		elif stage >= S.MEDICINE_DELIVERED:
			say("lau_return")
		else:
			say("lau_idle"))

	talk.call("chan", 1.9, func() -> void:
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

	talk.call("son", 1.6, func() -> void:
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

	talk.call("ng", 1.9, func() -> void:
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

	talk.call("wong", 1.9, func() -> void:
		if stage >= S.MEDICINE_DELIVERED:
			say("wong_after")
			return
		mark("wongReached")
		say("wong_deliver", func() -> void: set_stage(S.MEDICINE_DELIVERED)))

	for amb in [["chopper", "chopper", 1.8], ["mahjong2", "mahjong", 1.9], ["fanman", "fanman", 1.3],
			["shopkeeper", "shopkeeper", 2.2], ["worker", "worker", 1.5], ["child", "child", 1.5]]:
		var line: String = amb[1]
		talk.call(amb[0], amb[2], func() -> void: say(line))

	var refs := w.refs
	I.add({"id": "stairsUp", "position": refs.stairsUpA, "radius": 1.3, "priority": InteractionDirector.Priority.QUEST,
		"verb": "Go upstairs", "interact": func() -> void:
			if stage < S.LAU_PHOTO:
				say("stairs_blocked")
				return
			transition(Vector3(9.2, LevelBuilder.LEVEL_B, -12.4))})
	I.add({"id": "stairsDown", "position": refs.stairsDownB, "radius": 1.0, "priority": InteractionDirector.Priority.QUEST,
		"verb": "Go downstairs", "interact": func() -> void: transition(Vector3(9.3, LevelBuilder.LEVEL_A, -12.6))})
	I.add({"id": "roofDoorB", "position": refs.roofDoorB, "radius": 1.0, "priority": InteractionDirector.Priority.QUEST,
		"verb": "Roof door", "interact": func() -> void:
			if not flags.roof_door_open:
				say("roofdoor_latched")
				return
			transition(Vector3(10.4, LevelBuilder.LEVEL_ROOF, -11.2), 14, on_enter_roof)})
	I.add({"id": "roofDoorTop", "position": refs.roofDoorTop, "radius": 1.1, "priority": InteractionDirector.Priority.QUEST,
		"verb": "Stairwell door", "interact": func() -> void:
			if not flags.roof_door_open:
				say("roofdoor_top_stuck")
				return
			transition(Vector3(10.6, LevelBuilder.LEVEL_B, -13.2), 14)})

	I.add({"id": "fabric", "position": refs.fabricPos, "radius": 1.4, "priority": InteractionDirector.Priority.QUEST,
		"verb": "Look",
		"can_interact": func() -> bool: return w.fabric_state == "catwalk" and not (errand.get("step", "") in ["waiting", "unpinning"]),
		"interact": func() -> void:
			if stage == S.LAU_PHOTO:
				say("fabric_first", func() -> void: set_stage(S.CATWALK_BLOCKED))
			else:
				say("fabric_again")})

	# the service door at the end of the hall: no prompt, and it won't open,
	# until Mei has actually seen it
	var door := w.door("serviceDoor")
	I.add({"id": "serviceDoor", "radius": 1.3, "priority": InteractionDirector.Priority.QUEST, "verb": "Door",
		"position": func() -> Vector3:
			var n: Vector3 = door.normal
			var side := signf((player.position - (door.pos as Vector3)).dot(n))
			if side == 0.0:
				side = 1.0
			return (door.pos as Vector3) + n * side * 0.7,
		"can_interact": func() -> bool: return door.discovered and not door.open,
		"interact": func() -> void:
			audio.creak()
			w.open_door(door)})

	# the airshaft: the ladder's bottom rungs have rusted away. An old crate is
	# hidden behind a broken fridge; turn the view to find it, push it under the
	# ladder, and climb.
	I.add({"id": "crate", "radius": 1.2, "priority": InteractionDirector.Priority.QUEST, "verb": "Push",
		"position": func() -> Vector3: return (w.special.Crate as Node3D).global_position,
		"can_interact": func() -> bool: return crate_found and not crate_placed and _push.is_empty(),
		"interact": _push_crate})
	I.add({"id": "shaftBase", "position": refs.shaftBase, "radius": 1.8, "priority": InteractionDirector.Priority.QUEST,
		"verb": func() -> String: return "Climb" if crate_placed else "Look up",
		"can_interact": func() -> bool: return _push.is_empty(),
		"interact": func() -> void:
			if not crate_placed:
				say("shaft_look_found" if crate_found else "shaft_look")
				return
			once("shaft_climb", func() -> void:
				audio.creak()
				player.traverse(w.level_data.climb_nodes, 2.0, on_enter_roof, true, Vector3(-1, 0, 0)))})
	I.add({"id": "shaftTop", "position": refs.shaftTop, "radius": 1.2, "priority": InteractionDirector.Priority.QUEST,
		"verb": func() -> String: return "Climb down" if crate_placed else "Look down",
		"interact": func() -> void:
			if not crate_placed:
				say("shaft_down_unknown")
				return
			audio.creak()
			var nodes := w.level_data.climb_nodes.duplicate()
			nodes.reverse()
			nodes.append(Vector3(-5, LevelBuilder.LEVEL_B, -17.6))
			player.traverse(nodes, 2.2, _sync_world, true, Vector3(-1, 0, 0))})

	# the lost pigeon: find her first (the tank hides her from most sides),
	# then work out why she won't come down
	I.add({"id": "sheet", "position": refs.sheetSpot, "radius": 1.6, "priority": InteractionDirector.Priority.QUEST,
		"verb": "Look", "can_interact": func() -> bool: return not sheet_down,
		"interact": func() -> void:
			if stage == S.FOUND_SON and flags.pigeon_found:
				once("sheet_unpin", _unpin_sheet)
			else:
				say("sheet_plain")})

	# the packing boxes: worth a look only once Mei is home again
	I.add({"id": "boxes", "position": refs.boxes, "radius": 1.3, "priority": InteractionDirector.Priority.QUEST,
		"verb": "Look", "can_interact": func() -> bool: return stage == S.RETURNED_HOME,
		"interact": func() -> void: say("boxes_end", _ending)})

	var env := func(id: String, pos: Vector3, text: String, radius := 1.3, pri := InteractionDirector.Priority.ENV) -> void:
		I.add({"id": id, "position": pos, "radius": radius, "priority": pri, "verb": "Look",
			"interact": func() -> void: say([{"speaker": "", "text": text}])})
	env.call("radio", refs.radio, "Grandfather's radio. Something cheerful, half lost in static.", 1.2)
	env.call("chair", Vector3(4.9, 0, -11.0), "The old dental chair. The vinyl is patched with tape in three places.", 1.1)
	env.call("sign", refs.lauSign, "劉牙科. Lau Dental. The paint on the sign is older than you are.", 1.0, InteractionDirector.Priority.DECOR)
	env.call("notice", Vector3(-2.6, 0, -0.5), "The Housing Department's notice. Everyone has read it. Nobody talks about it.", 1.0, InteractionDirector.Priority.DECOR)
	env.call("coop", refs.coop, "Mr. Ng's coop. Every bird has a name written on a strip of tape.", 1.4, InteractionDirector.Priority.DECOR)
	env.call("dead-end", Vector3(1.2, 0, -0.5), "The blue pipe runs straight into the wall.", 1.0, InteractionDirector.Priority.DECOR)
	env.call("well", Vector3(18, LevelBuilder.LEVEL_B, -12), "Far below, the alley is full of other people's rubbish.", 1.0, InteractionDirector.Priority.DECOR)


func _register_photo_targets() -> void:
	photography.add_target("lau", world.residents.lau, func() -> bool: return stage == S.REACHED_LAU and not scrapbook.entries.has("lau"))
	photography.add_target("ng", world.residents.ng, func() -> bool: return stage == S.HELPED_NG and not scrapbook.entries.has("ng"))


# ----------------------------------------------------------------------------- the washing
#
# After Mr. Ng's photo the Chan boy opens the stuck stair door and goes down
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
	hud.notice("Chan's son: “Hold on, they're still wet!”", 3.2)
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
			hud.notice("An old crate, hidden behind the broken fridge.", 3.2)

	# the pigeon: really hidden by the tank, checked with a ray
	if not flags.pigeon_found and p.y > 12.0 and stage < S.HELPED_NG:
		var bird: Vector3 = (world.special.LostPigeon as Node3D).global_position + Vector3(0, 0.2, 0)
		if bird.distance_to(p) < 16.0 and cam.on_screen(bird) and not _occluded_by_tank(bird):
			flags.pigeon_found = true
			audio.chime()
			hud.notice("There she is, tucked in behind the water tank." if stage >= S.FOUND_SON
				else "A pigeon, tucked in behind the water tank.", 3.6)


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
	hud.show_hint("[WASD] Move    [F] Interact")


func _lau_intro() -> void:
	if _lau_intro_done:
		return
	_lau_intro_done = true
	mark("lauReached")
	say("lau_intro", func() -> void:
		set_stage(S.REACHED_LAU)
		_hints.camera = true
		hud.show_hint("[C] Raise the camera"))


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


func _on_pigeon_home() -> void:
	_pigeon_anim = {}
	var bird: CharacterSprite = world.special.LostPigeon
	bird.play("idle")
	locks.unlock("pigeon")
	audio.coo()
	say("ng_helped", func() -> void:
		set_stage(S.HELPED_NG)
		hud.show_hint("[C] Raise the camera")
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
	scrapbook.add(id)
	if id == "lau":
		say("lau_after_photo", func() -> void:
			set_stage(S.LAU_PHOTO)
			_hints.scrapbook = true
			hud.show_hint("[TAB] Scrapbook")
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
	# the day ends only when the player chooses to look at the boxes
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
	slice.ending.play()


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
		hud.show_hint("[Q] [E] Turn the view")
	elif _hints.rotate and (door.discovered or not at_dead_end):
		_hints.rotate = false
		hud.show_hint("")

	if _hints.camera and photography.active:
		_hints.camera = false
		hud.show_hint("")
	if _hints.scrapbook and scrapbook.open:
		_hints.scrapbook = false
		hud.show_hint("")

	# walking into Lau's clinic
	if stage == S.MEDICINE_RECEIVED and p.y < 1.0 and p.x > 0.0 and p.x < 8.0 and p.z < -9.4 and p.z > -15.0 and not locks.is_locked():
		_lau_intro()

	# coming home
	if stage == S.MEDICINE_DELIVERED and p.y < 1.0 and p.x < -6.6 and not locks.is_locked() and not _homecoming:
		_homecoming = true
		_home_again()
