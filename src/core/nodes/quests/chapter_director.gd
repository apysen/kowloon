class_name ChapterDirector
extends Node

## What every chapter's story shares: the slice's components, conversations,
## timed beats, the ways around the building (stairs, the roof door, the
## service door, the airshaft ladder), and the things Mei can look at that
## don't change from day to day. Each chapter's director extends this with its
## own stages, people and puzzle.
##
## The slice talks to whichever director is running through: setup(),
## start_intro(), tick(), force_stage(), is_complete(), stage_name(),
## on_enter_roof(), and the stage / objective / timings it reads for the debug view.

const OLD_PHOTO := preload("res://assets/textures/props/old_photo.png")

@export var slice: SliceRoot

var stage := 0
var objective := ""
var hint := ""
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

var _tasks: Array[Dictionary] = []
var _seen: Dictionary = {}
var _roof_visited := false


func _bind() -> void:
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
	start_time = Time.get_ticks_msec() / 1000.0


func mark(name: String) -> void:
	if not timings.has(name):
		timings[name] = Time.get_ticks_msec() / 1000.0 - start_time


# ----------------------------------------------------------------------------- what each chapter provides


func setup() -> void:
	pass


## Does the day open on its title card over black (rather than on the scene)?
func opens_on_card() -> bool:
	return false


func start_intro() -> void:
	pass


func tick(delta: float, paused: bool) -> void:
	_run_tasks(delta, paused)


func force_stage(_s: int) -> void:
	pass


func is_complete() -> bool:
	return false


func stage_name() -> String:
	return str(stage)


## Keeps the world in step with the story (called after every change of stage and scene).
func _sync_world() -> void:
	pass


## May Mei go up from the clinic's stairwell yet?
func can_go_upstairs() -> bool:
	return true


func roof_door_open() -> bool:
	return true


## The airshaft ladder: can she reach its bottom rungs, and does she know how?
func ladder_reachable() -> bool:
	return true


func ladder_found() -> bool:
	return true


# ----------------------------------------------------------------------------- conversations and timing


func say(id: Variant, then := Callable()) -> void:
	var r := _speaker_resident(id)
	if r:
		r.face_toward(player.position, 4.0)
	dialogue.start(id, then)


func _speaker_resident(id: Variant) -> Resident:
	if not id is String:
		return null
	# a chapter's own conversations are "c3_kit_key": the speaker is what follows
	var rest := String(id)
	if rest.length() > 3 and rest[0] == "c" and rest[2] == "_" and rest[1].is_valid_int():
		rest = rest.substr(3)
	for r in world.residents:
		if rest.begins_with(String(r) + "_") or rest == String(r):
			if String(r) in ["hand_a", "hand_b", "kit", "chiu", "porter", "cheung", "cheng", "mover_a", "mover_b", "yamen_taichi", "yamen_bird", "leung"]:
				return world.residents.get(r)
	var key := rest.split("_")[0]
	var map := {"grandfather": "grandfather", "mum": "mum", "lau": "lau", "chan": "chan", "son": "son", "ng": "ng", "wong": "wong",
		"chopper": "chopper", "mahjong": "mahjong2", "fanman": "fanman", "ho": "fanman", "shopkeeper": "shopkeeper",
		"kwok": "shopkeeper", "worker": "worker", "child": "child", "wai": "son",
		"mover": "mover_a", "taichi": "yamen_taichi", "bird": "yamen_bird"}
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
	if _roof_visited:
		return
	_roof_visited = true
	mark("rooftopReached")
	# a few quiet seconds with no dialogue and no interface, then a jet comes over
	hud.set_quiet(true)
	later(_roof_quiet_over, 6.0)


func _roof_quiet_over() -> void:
	if not photography.active:
		hud.set_quiet(false)


# ----------------------------------------------------------------------------- interactions every chapter has


## Take away a shared interaction this chapter has no use for.
func unregister(id: String) -> void:
	interaction._list = interaction._list.filter(func(it: Dictionary) -> bool: return it.id != id)


func talk(id: String, radius: float, fn: Callable) -> void:
	var r: Resident = world.residents[id]
	interaction.add({"id": id, "position": func() -> Vector3: return r.position, "radius": radius,
		"priority": InteractionDirector.Priority.NPC, "verb": "verb.talk",
		"can_interact": func() -> bool: return r.can_talk(), "interact": fn})


func look(id: String, pos: Vector3, key: String, radius := 1.3, pri := InteractionDirector.Priority.ENV) -> void:
	interaction.add({"id": id, "position": pos, "radius": radius, "priority": pri, "verb": "verb.look",
		"interact": func() -> void: say([{"speaker": "", "text": key}])})


## The stairs, the roof doors, the service door, the airshaft ladder, and the
## things in the building worth a look.
func _register_shared() -> void:
	var I := interaction
	var w := world
	var refs := w.refs
	I.add({"id": "stairsUp", "position": refs.stairsUpA, "radius": 1.3, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.upstairs", "interact": func() -> void:
			if not can_go_upstairs():
				say("stairs_blocked")
				return
			transition(Vector3(9.2, LevelBuilder.LEVEL_B, -12.4))})
	I.add({"id": "stairsDown", "position": refs.stairsDownB, "radius": 1.0, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.downstairs", "interact": func() -> void: transition(Vector3(9.3, LevelBuilder.LEVEL_A, -12.6))})
	I.add({"id": "roofDoorB", "position": refs.roofDoorB, "radius": 1.0, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.roof_door", "interact": func() -> void:
			if not roof_door_open():
				say("roofdoor_latched")
				return
			transition(Vector3(10.4, LevelBuilder.LEVEL_ROOF, -11.2), 14, on_enter_roof)})
	I.add({"id": "roofDoorTop", "position": refs.roofDoorTop, "radius": 1.1, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.stairwell_door", "interact": func() -> void:
			if not roof_door_open():
				say("roofdoor_top_stuck")
				return
			transition(Vector3(10.6, LevelBuilder.LEVEL_B, -13.2), 14)})

	# the service door at the end of the hall: no prompt, and it won't open,
	# until Mei has actually seen it
	var door := w.door("serviceDoor")
	I.add({"id": "serviceDoor", "radius": 1.3, "priority": InteractionDirector.Priority.QUEST, "verb": "verb.door",
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

	# the airshaft ladder, up to the roof and back
	I.add({"id": "shaftBase", "position": refs.shaftBase, "radius": 1.8, "priority": InteractionDirector.Priority.QUEST,
		"verb": func() -> String: return "verb.climb" if ladder_reachable() else "verb.look_up",
		"can_interact": func() -> bool: return _ladder_free(),
		"interact": func() -> void:
			if not ladder_reachable():
				say("shaft_look_found" if ladder_found() else "shaft_look")
				return
			once("shaft_climb", func() -> void:
				audio.creak()
				player.traverse(w.level_data.climb_nodes, 2.0, on_enter_roof, true, Vector3(-1, 0, 0)))})
	I.add({"id": "shaftTop", "position": refs.shaftTop, "radius": 1.2, "priority": InteractionDirector.Priority.QUEST,
		"verb": func() -> String: return "verb.climb_down" if ladder_reachable() else "verb.look_down",
		"interact": func() -> void:
			if not ladder_reachable():
				say("shaft_down_unknown")
				return
			audio.creak()
			var nodes := w.level_data.climb_nodes.duplicate()
			nodes.reverse()
			nodes.append(Vector3(-5, LevelBuilder.LEVEL_B, -17.6))
			player.traverse(nodes, 2.2, _sync_world, true, Vector3(-1, 0, 0))})

	# the second stair, off the hall's south side, up to the Chius' landing
	I.add({"id": "stairsCUp", "position": refs.stairsCUp, "radius": 1.0, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.upstairs", "interact": func() -> void: transition(refs.landingC)})
	I.add({"id": "stairsCDown", "position": refs.stairsCDown, "radius": 0.9, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.downstairs", "interact": func() -> void: transition(refs.stairsCUp + Vector3(0, 0, -0.1))})

	# the old photograph on the wall, held up close
	I.add({"id": "oldPhoto", "position": refs.oldPhoto, "radius": 1.1, "priority": InteractionDirector.Priority.ENV,
		"verb": "verb.look", "interact": _look_at_old_photo})

	look("radio", refs.radio, "env.radio", 1.2)
	look("chair", Vector3(4.9, 0, -11.0), "env.chair", 1.1)
	look("sign", refs.lauSign, "env.sign", 1.0, InteractionDirector.Priority.DECOR)
	look("notice", Vector3(-2.6, 0, -0.5), "env.notice", 1.0, InteractionDirector.Priority.DECOR)
	look("coop", refs.coop, "env.coop", 1.4, InteractionDirector.Priority.DECOR)
	look("dead-end", Vector3(1.2, 0, -0.5), "env.dead_end", 1.0, InteractionDirector.Priority.DECOR)
	look("well", Vector3(18, LevelBuilder.LEVEL_B, -12), "env.well", 1.0, InteractionDirector.Priority.DECOR)
	# how people lived: one room each, the stove, the bunks, the toilet down the corridor
	var B := LevelBuilder.LEVEL_B
	look("kitchen", Vector3(-8.8, 0, -3.1), "env.kitchen", 1.0)
	look("toiletNook", Vector3(-6.75, 0, -2.6), "env.toilet_nook", 0.9)
	look("bunk", Vector3(-11.7, 0, 3.0), "env.bunk", 1.0)
	look("cockloft", Vector3(-13.6, 0, -2.2), "env.cockloft", 0.8)
	look("chanKitchen", Vector3(-2.9, B, -14.4), "env.chan_kitchen", 1.0)
	look("chanBunk", Vector3(-6.7, B, -13.0), "env.chan_bunk", 0.9)
	look("sharedToilet", Vector3(2.6, B, -12.4), "env.shared_toilet", 0.9)
	look("wongKitchen", Vector3(27.6, B, -14.9), "env.wong_kitchen", 0.9)
	# the north side of the light well: Mrs. Fong's, the empty flat, the planks across
	look("fongDoor", refs.fongDoor, "env.fong_door", 1.0)
	look("unitDoor", refs.chainedDoor, "env.unit_door", 1.0)
	look("footbridge", refs.footbridge, "env.footbridge", 0.8, InteractionDirector.Priority.DECOR)
	look("unitMarks", Vector3(19.0, B, -20.6), "env.unit_marks", 0.9)
	look("unitCalendar", Vector3(19.0, B, -20.9), "env.unit_calendar", 0.7)
	look("unitStool", Vector3(19.4, B, -19.3), "env.unit_stool", 0.8)
	look("unitSink", Vector3(23.2, B, -20.2), "env.unit_sink", 0.8)
	# the lane behind the alcove, and the Chius' door
	look("laneGate", refs.laneGate, "env.lane_gate", 1.0)
	look("workshopDoorShut", refs.workshopDoor + Vector3(0.9, 0, 0), "env.workshop_shut", 0.8, InteractionDirector.Priority.DECOR)


## Hide (or show again) a piece of the level and everything under it: the
## world leaves anything marked gone out of sight.
func set_gone(n: Node, gone: bool) -> void:
	if n == null:
		return
	if n is Node3D:
		n.set_meta("gone", gone)
		(n as Node3D).visible = not gone
	for c in n.get_children():
		set_gone(c, gone)


## Nothing else in the way at the foot of the ladder (the crate being pushed).
func _ladder_free() -> bool:
	return true


func _look_at_old_photo() -> void:
	hud.show_photo(OLD_PHOTO)
	say("old_photo_again", hud.hide_photo)
