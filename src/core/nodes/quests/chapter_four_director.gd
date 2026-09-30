class_name ChapterFourDirector
extends ChapterDirector

## Chapter 4, Three Addresses. 12 days until we leave.
##
## The lane's gate is open now, and past it is the yamen: the one old building
## the City grew up around, and the only ground in it the sun reaches. Mrs.
## Cheung, packing up the old people's home, wants three addresses: Lau's,
## the Chans', Kit's. Where they're going. Beside her, Mr. Cheng of the housing
## department has a plan that says the storage room's cabinet goes out through
## its door, and movers who say it doesn't. The way out is there, but only
## seen by turning: a gap between two walls behind the shelves; a stair that
## seems to end at a wall and goes on sideways into the next building; the old
## classroom's balcony door, whose second leaf folds back (its bolts are on
## the balcony side). The addresses come in any order; Mrs. Wong is packing on
## the landing on the way up to the roof. Mrs. Cheung copies them into her book,
## and Mei's album learns a new word: AFTER.
##
## The day's photograph: Mrs. Cheung with her address book.

enum {
	START,
	GO_YAMEN,
	ADDRESSES,
	RETURN,
	PHOTO_CHEUNG,
	COMPLETE,
}

const NAMES := ["START", "GO_YAMEN", "ADDRESSES", "RETURN", "PHOTO_CHEUNG", "COMPLETE"]

const OBJECTIVES := {
	GO_YAMEN: ["c4.obj.yamen", "c4.obj.yamen.hint"],
	ADDRESSES: ["c4.obj.addresses", ""],
	RETURN: ["c4.obj.return", "c4.obj.return.hint"],
	PHOTO_CHEUNG: ["c4.obj.photo", "c4.obj.photo.hint"],
}

const DAYS_LEFT := 12

var flags := {
	"cheung_met": false, "cheng_met": false, "side_gap_found": false, "stair_found": false, "panel_seen": false,
	"panel_open": false, "cabinet_moved": false, "address_lau": false, "address_chan": false, "address_kit": false,
	"lau_talked": false, "wong_packing_seen": false, "payoff_lau_windows": false, "theme_line_somebody_shows_you": false,
	"cheng_respect_mei": false, "after_unlocked": false, "kit_lift": false,
}

var _stage_t := 0.0
var _arrived := false


func setup() -> void:
	_bind()
	_prepare_world()
	_register_shared()
	unregister("laneGate")
	_register_people()
	_register_route()
	_register_sounds()
	photography.add_target("cheung", world.residents.cheung, func() -> bool: return stage == PHOTO_CHEUNG and not scrapbook.entries.has("cheung"))
	photography.photo_kept.connect(_on_photo_kept)
	photography.has_camera = true
	for id in ["lau", "ng", "ho", "chiu"]:
		scrapbook.add(id)
		if Progress.carried_photos.has(id):
			photography.photos[id] = Progress.carried_photos[id]
		else:
			_reshoot(id)
	Progress.reach(4)


func _reshoot(id: String) -> void:
	photography.photos[id] = await photography.studio.shoot(id)


func is_complete() -> bool:
	return stage == COMPLETE


func stage_name() -> String:
	return NAMES[clampi(stage, 0, NAMES.size() - 1)]


func set_stage(s: int) -> void:
	stage = s
	_stage_t = 0.0
	var o: Array = OBJECTIVES.get(s, ["", ""])
	objective = o[0]
	hint = o[1]
	var live := _live_hint()
	if live != "":
		hint = live
	hud.set_objective(objective, hint)
	_sync_world()


func force_stage(s: int) -> void:
	s = clampi(s, START, COMPLETE)
	flags.cheung_met = s >= ADDRESSES
	flags.cheng_met = s >= ADDRESSES
	if s >= RETURN:
		for k in ["address_lau", "address_chan", "address_kit", "side_gap_found", "stair_found", "panel_seen"]:
			flags[k] = true
		_open_side_gap()
		_open_stair()
		_open_panel(true)
		_move_cabinet()
	flags.after_unlocked = s >= PHOTO_CHEUNG
	Progress.after_unlocked = flags.after_unlocked
	set_stage(s)


## What's left to do, in the objective's hint: the three addresses (and who
## has them), then Mr. Cheng's cabinet, one step at a time.
func _live_hint() -> String:
	if stage != ADDRESSES:
		return ""
	var lines: Array[String] = []
	if not flags.address_lau:
		lines.append(tr("c4.need.lau"))
	if not flags.address_chan:
		lines.append(tr("c4.need.chan"))
	if not flags.address_kit:
		lines.append(tr("c4.need.kit"))
	if flags.cheng_met and not flags.cabinet_moved:
		if not flags.side_gap_found:
			lines.append(tr("c4.cab.store"))
		elif not flags.stair_found:
			lines.append(tr("c4.cab.stair"))
		elif not flags.panel_open:
			lines.append(tr("c4.cab.panel_look" if not flags.panel_seen else "c4.cab.panel_open"))
		else:
			lines.append(tr("c4.cab.tell"))
	return "\n".join(lines)


func _refresh_hint() -> void:
	var live := _live_hint()
	if live != "" and live != hint:
		hint = live
		hud.set_objective(objective, hint)


# ----------------------------------------------------------------------------- the world on this day


func _prepare_world() -> void:
	var door := world.door("serviceDoor")
	door.discovered = true
	world.open_door(door)
	world.move_crate(world.refs.crateEnd)
	world.set_fabric_state("roof")
	world.sheet_blocking = false
	(world.special.Sheet as Node3D).rotation.x = -1.2
	var path := world.level_data.pigeon_path
	(world.special.LostPigeon as Node3D).position = path[path.size() - 1]
	# Mum packing the last of the kitchen; Grandfather in his chair
	_pose(world.residents.mum, Vector3(-10.05, 0, -2.4), Vector3(0, 0, -1), "work")
	# Lau packing up his instruments where the chair used to be
	_pose(world.residents.lau, world.refs.lauPacking, Vector3(0, 0, 1), "work")
	# Mrs. Wong on the landing, wrapping cups among her boxes
	_pose(world.residents.wong, world.refs.wongPacking, Vector3(0, 0, 1), "work")
	# Mrs. Chan and Wai up on the roof, taking the drying frame down
	_pose(world.residents.chan, world.refs.chanRoof, Vector3(0, 0, 1), "reach")
	_pose(world.residents.son, world.refs.chanRoof + Vector3(-1.2, 0, 0.1), Vector3(0.4, 0, 1), "work")
	# Kit, back for the workshop's keys, sweeping out the empty room
	_pose(world.residents.kit, world.refs.kitWorkshop, Vector3(0, 0, 1), "sweep")
	# Ho at his fans as ever; Ng up with his birds
	_pose(world.residents.fanman, Vector3(-3.4, 0, 0.35), Vector3(0, 0, 1), "work")
	_sync_world()


func _sync_world() -> void:
	var cheng: Resident = world.residents.cheng
	var mover_a: Resident = world.residents.mover_a
	if flags.cabinet_moved:
		_pose(cheng, world.refs.loadingArea + Vector3(1.1, 0, -0.9), Vector3(-0.6, 0, 1), "work")
		_pose(mover_a, world.refs.loadingArea + Vector3(-0.4, 0, -1.1), Vector3(0.3, 0, 1), "idle")
	var cheung: Resident = world.residents.cheung
	if stage >= RETURN:
		cheung.idle_anim = "write" if stage == PHOTO_CHEUNG else "sit"
		cheung.sprite.play(cheung.idle_anim)


func _pose(r: Resident, at: Vector3, facing: Vector3, anim: String) -> void:
	if r.home.distance_to(at) > 0.01 or r.idle_anim != anim:
		r.place_at(at)
		r.facing = facing
		r.sprite.facing = facing
		r.idle_anim = anim
		r.sprite.play(anim)


# ----------------------------------------------------------------------------- the day begins


func opens_on_card() -> bool:
	return true


func start_intro() -> void:
	await _title_card("c4.card.number", "c4.card.title")
	# home: Mum with a message
	player.teleport(Vector3(-9.3, 0, -1.6))
	player.facing = Vector3(0, 0, -1)
	cam.snap_next = true
	await fade.fade_in(1.2)
	say("c4_open", func() -> void:
		mark("open")
		set_stage(GO_YAMEN))


func _title_card(number_key: String, title_key: String) -> void:
	fade.set_black(true)
	var card := CanvasLayer.new()
	card.layer = 50
	add_child(card)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	for spec in [[number_key, UIStyle.FONT_MONO, 15, UIStyle.CONCRETE_DIM], [title_key, UIStyle.FONT_UI_BOLD, 40, UIStyle.CONCRETE]]:
		var l := Label.new()
		l.text = spec[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", spec[1])
		l.add_theme_font_size_override("font_size", spec[2])
		l.add_theme_color_override("font_color", spec[3])
		col.add_child(l)
	col.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(col, "modulate:a", 1.0, 1.0)
	tw.tween_interval(1.8)
	tw.tween_property(col, "modulate:a", 0.0, 0.8)
	await tw.finished
	card.queue_free()


## Out of the lanes into the open: the sound opens up, the light comes down,
## and Mrs. Cheung is waiting.
func _arrive() -> void:
	_arrived = true
	mark("yamenArrival")
	audio.play("chime", 0.2)
	hud.set_quiet(true)
	later(_cheung_calls, 2.4)


func _cheung_calls() -> void:
	hud.set_quiet(false)
	_meet_cheung()


func _meet_cheung() -> void:
	flags.cheung_met = true
	mark("cheungMet")
	say("c4_cheung", func() -> void:
		if stage < ADDRESSES:
			set_stage(ADDRESSES))


# ----------------------------------------------------------------------------- people


func _register_people() -> void:
	talk("grandfather", 1.5, func() -> void: say("c4_grandfather"))
	talk("mum", 1.4, func() -> void: say("c4_mum"))
	talk("cheung", 1.7, _talk_cheung)
	talk("cheng", 1.7, _talk_cheng)
	talk("mover_a", 1.5, func() -> void: say("c4_mover_a" if not flags.cabinet_moved else "c4_mover_after"))
	talk("mover_b", 1.5, func() -> void: say("c4_mover_b"))
	talk("yamen_taichi", 1.5, func() -> void: say("c4_taichi"))
	talk("yamen_bird", 1.5, func() -> void: say("c4_bird"))
	talk("lau", 2.0, _talk_lau)
	talk("wong", 1.9, _talk_wong)
	talk("chan", 1.9, _talk_chans)
	talk("son", 1.6, _talk_chans)
	talk("kit", 1.6, _talk_kit)
	talk("fanman", 1.6, func() -> void: say("c4_ho"))
	talk("ng", 1.9, func() -> void: say("c4_ng"))
	talk("shopkeeper", 2.2, func() -> void: say("c4_kwok"))
	talk("chopper", 1.8, func() -> void: say("c4_chopper"))
	talk("mahjong2", 1.9, func() -> void: say("c4_mahjong"))
	talk("worker", 1.5, func() -> void: say("c4_worker"))
	talk("child", 1.5, func() -> void: say("c4_child"))


func _talk_cheung() -> void:
	if not flags.cheung_met:
		_meet_cheung()
	elif stage == RETURN:
		_return_addresses()
	elif stage == PHOTO_CHEUNG:
		say("c4_cheung_pose")
	elif stage >= COMPLETE:
		say("c4_cheung_pose")
	else:
		var n := int(flags.address_lau) + int(flags.address_chan) + int(flags.address_kit)
		say("c4_cheung_wait" if n < 3 else "c4_cheung_cabinet")


func _talk_cheng() -> void:
	if not flags.cheng_met:
		_meet_cheng()
	elif flags.cabinet_moved:
		say("c4_cheng_after")
	elif _route_found():
		_cabinet_goes()
	else:
		say("c4_cheng_wait")


func _meet_cheng() -> void:
	flags.cheng_met = true
	mark("chengMet")
	say("c4_cheng", _refresh_hint)


func _talk_lau() -> void:
	if not flags.lau_talked:
		flags.lau_talked = true
		flags.payoff_lau_windows = true
		mark("lauTalked")
		say("c4_lau", _refresh_hint)
	else:
		say("c4_lau_after" if flags.address_lau else "c4_lau_card")


func _take_card() -> void:
	if flags.address_lau:
		say("c4_card_again")
		return
	flags.address_lau = true
	mark("addressLau")
	say("c4_card", func() -> void: _address_got("notice.c4_lau"))


func _talk_wong() -> void:
	if not flags.wong_packing_seen:
		_wong_packing()
	else:
		say("c4_wong_after")


## Mrs. Wong packing, on the landing on the way up to the roof: a short scene,
## no objective. She hasn't been seen since the first day.
func _wong_packing() -> void:
	if flags.wong_packing_seen:
		return
	flags.wong_packing_seen = true
	mark("wongPacking")
	say("c4_wong")


func _talk_chans() -> void:
	if flags.address_chan:
		say("c4_chan_after")
		return
	flags.address_chan = true
	mark("addressChan")
	say("c4_chan", func() -> void: _address_got("notice.c4_chan"))


func _talk_kit() -> void:
	if not flags.address_kit:
		flags.address_kit = true
		mark("addressKit")
		say("c4_kit", func() -> void: _address_got("notice.c4_kit"))
	elif not flags.kit_lift:
		flags.kit_lift = true
		say("c4_kit_lift")
	else:
		say("c4_kit_after")


func _address_got(notice_key: String) -> void:
	hud.notice(notice_key, 3.0)
	_check_done()


func _check_done() -> void:
	_refresh_hint()
	if stage == ADDRESSES and flags.address_lau and flags.address_chan and flags.address_kit and flags.cabinet_moved:
		set_stage(RETURN)


func _return_addresses() -> void:
	mark("returned")
	say("c4_return", func() -> void:
		flags.after_unlocked = true
		Progress.after_unlocked = true
		audio.play("pen_scribble", 0.5)
		hud.notice("notice.c4_after", 4.0)
		set_stage(PHOTO_CHEUNG))


func _on_photo_kept(id: String) -> void:
	await scrapbook.file_photo(id)
	if id == "cheung":
		say("c4_cheung_photo", func() -> void: later(_ending, 1.4))


# ----------------------------------------------------------------------------- Mr. Cheng's cabinet


func _register_route() -> void:
	var I := interaction
	var refs := world.refs
	var Q := InteractionDirector.Priority.QUEST
	# the landing's stair, up and down
	I.add({"id": "yamenStairUp", "position": refs.yamenStairUp, "radius": 0.9, "priority": Q, "verb": "verb.upstairs",
		"interact": func() -> void: transition(refs.yamenTop)})
	I.add({"id": "yamenStairDown", "position": refs.yamenStairDown, "radius": 0.8, "priority": Q, "verb": "verb.downstairs",
		"interact": func() -> void: transition(refs.yamenStairUp + Vector3(0, 0, -0.5))})
	# the balcony's stair, down into the courtyard and back up
	I.add({"id": "rearDown", "position": refs.rearStairTop, "radius": 0.8, "priority": Q, "verb": "verb.downstairs",
		"interact": func() -> void: transition(refs.rearStairFoot)})
	I.add({"id": "rearUp", "position": refs.rearStairFoot, "radius": 0.9, "priority": Q, "verb": "verb.upstairs",
		"interact": func() -> void: transition(refs.rearStairTop + Vector3(0.3, 0, 0))})
	# the cabinet itself, and the door it won't go through
	I.add({"id": "cabinet", "position": refs.cabinet, "radius": 1.0, "priority": InteractionDirector.Priority.ENV, "verb": "verb.look",
		"can_interact": func() -> bool: return not flags.cabinet_moved,
		"interact": func() -> void: say("c4_cabinet")})
	I.add({"id": "storeDoor", "position": refs.storeDoor, "radius": 0.8, "priority": InteractionDirector.Priority.DECOR, "verb": "verb.look",
		"can_interact": func() -> bool: return not flags.cabinet_moved,
		"interact": func() -> void: say("c4_store_door")})
	# the balcony door's other leaf: bolted, and only from outside
	I.add({"id": "foldPanel", "position": refs.foldPanel, "radius": 0.9, "priority": Q,
		"verb": func() -> String: return "verb.unbolt" if flags.panel_seen else "verb.look",
		"can_interact": func() -> bool: return not flags.panel_open,
		"interact": func() -> void:
			if flags.panel_seen:
				audio.creak()
				_open_panel(false)
				say("c4_panel_open", _refresh_hint)
			else:
				say("c4_panel")})
	# the yamen, its cannons, its tree, the blackboard upstairs
	look("hallDoor", refs.hallDoor, "env.c4_hall", 1.3)
	look("cannons", refs.cannons, "env.c4_cannons", 1.2)
	look("yamenTree", refs.yamenTree, "env.c4_tree", 1.1, InteractionDirector.Priority.DECOR)
	look("blackboard", refs.blackboard, "env.c4_blackboard", 1.0)
	I.add({"id": "lauCard", "position": refs.lauCard, "radius": 0.9, "priority": Q,
		"verb": func() -> String: return "verb.take" if not flags.address_lau else "verb.look",
		"interact": _take_card})


func _route_found() -> bool:
	return flags.side_gap_found and flags.stair_found and flags.panel_open


func _open_side_gap() -> void:
	world.open_ways["sidegap"] = true


func _open_stair() -> void:
	world.open_ways["stairgap"] = true
	var stack: Node3D = world.level.get_node_or_null("Special/DeskStack")
	if stack and stack.position.z > 3.0:
		create_tween().tween_property(stack, "position:z", 2.05, 0.8).set_trans(Tween.TRANS_SINE)


func _open_panel(instant: bool) -> void:
	if flags.panel_open:
		return
	flags.panel_open = true
	var leaf: Node3D = world.level.get_node("Special/FoldPanel")
	if instant:
		leaf.rotation.y = -PI
	else:
		create_tween().tween_property(leaf, "rotation:y", -PI, 1.2).set_trans(Tween.TRANS_SINE)


## Mei shows them the way; the movers take it out. Then it's in the courtyard.
func _cabinet_goes() -> void:
	say("c4_route", func() -> void:
		locks.lock("cabinet")
		mark("cabinetRun")
		_carry_out())


func _carry_out() -> void:
	audio.play("tape_gun", 0.4)
	await fade.fade_out(0.8)
	audio.footsteps(14, 0.16)
	await get_tree().create_timer(2.2).timeout
	_move_cabinet()
	_sync_world()
	player.teleport(world.refs.loadingArea + Vector3(1.6, 0, 0.1))
	player.facing = Vector3(-1, 0, -0.3)
	cam.snap_next = true
	audio.play("cabinet_down", 0.9)
	await fade.fade_in(0.8)
	locks.unlock("cabinet")
	say("c4_cheng_exit", func() -> void:
		flags.theme_line_somebody_shows_you = true
		flags.cheng_respect_mei = true
		_check_done())


func _move_cabinet() -> void:
	if flags.cabinet_moved:
		return
	flags.cabinet_moved = true
	world.open_ways["cabinet"] = true
	var cab: Node3D = world.level.get_node_or_null("ChapterProps/Ch1-4/Cabinet")
	if cab:
		cab.global_position = world.refs.loadingArea + Vector3(0.4, 0, -0.8)
		cab.rotation.y = 0.2


# ----------------------------------------------------------------------------- seeing it


## Turning the view shows what the plan doesn't: from the side, the gap behind
## the storage room's shelves; looking east from the stair's head, the way on
## into the next building; from the balcony, looking back at the door, the
## bolts on its folded leaf.
func _discover() -> void:
	if cam.rotating or locks.is_locked() or dialogue.is_open() or not flags.cheng_met or flags.cabinet_moved:
		return
	var p := player.position
	var B := LevelBuilder.LEVEL_B
	var back := ViewMath.back(cam.current_yaw)
	var in_store := p.y < 1.0 and p.x > 14.0 and p.x < 17.0 and p.z > -6.5 and p.z < -3.5
	if not flags.side_gap_found and in_store and (cam.direction == 1 or cam.direction == 3):
		flags.side_gap_found = true
		_open_side_gap()
		audio.chime()
		say("c4_gap_found", _refresh_hint)
		return
	var on_top := absf(p.y - B) < 0.5 and p.x > 16.0 and p.z > 3.0 and p.z < 4.4
	if flags.side_gap_found and not flags.stair_found and on_top and back.dot(Vector3(-1, 0, 0)) > 0.6:
		flags.stair_found = true
		_open_stair()
		audio.chime()
		say("c4_stair_found", _refresh_hint)
		return
	var on_balcony := absf(p.y - B) < 0.5 and p.x > 11.0 and p.x < 15.7 and p.z < 0.5 and p.z > -0.5
	if not flags.panel_seen and on_balcony and back.dot(Vector3(0, 0, -1)) > 0.6:
		flags.panel_seen = true
		audio.chime()
		hud.notice("notice.c4_bolts", 3.4)
		_refresh_hint()


func _tick_arrival() -> void:
	if _arrived or stage != GO_YAMEN or locks.is_locked() or dialogue.is_open():
		return
	var p := player.position
	if p.y < 1.0 and p.x > 6.4 and p.x < 15.5 and p.z > -3.0 and p.z < 6.0:
		_arrive()


func _tick_wong() -> void:
	if flags.wong_packing_seen or stage != ADDRESSES or locks.is_locked() or dialogue.is_open():
		return
	var at: Vector3 = world.refs.wongPacking
	if mei_near(at.x, at.y, at.z, 2.3):
		_wong_packing()


func _tick_hints() -> void:
	if dialogue.is_open() or locks.is_locked():
		return
	# a nudge to turn the view, once, if Mei stands in the storage room a while
	var p := player.position
	if flags.cheng_met and not flags.side_gap_found and p.y < 1.0 and p.x > 14.0 and p.x < 17.0 and p.z > -6.5 and p.z < -3.5:
		_seen["store_t"] = float(_seen.get("store_t", 0.0)) + get_process_delta_time()
		if float(_seen.store_t) > 14.0 and not _seen.has("store_hint"):
			_seen["store_hint"] = true
			hud.show_hint("hint.turn_view")
			later(func() -> void: hud.show_hint(""), 6.0)


# ----------------------------------------------------------------------------- sounds


func _register_sounds() -> void:
	# the chair's gone and the drill with it; the TV upstairs has moved out
	audio.quiet["drill"] = true
	audio.quiet["tv"] = true
	# out in the open: wind over the walls, the traffic outside, sparrows in the tree
	audio.add_loop("yamen", "yamen_air", Vector3(10.0, 0, 1.0), 9.0, 0.0, 0.7)


# ----------------------------------------------------------------------------- the end of the day


func _ending() -> void:
	if stage == COMPLETE:
		return
	set_stage(COMPLETE)
	mark("ending")
	locks.lock("ending")
	hud.set_quiet(true)
	await get_tree().create_timer(1.6).timeout
	audio.silence(4.0)
	await fade.fade_out(3.6)
	slice.ending.play(DAYS_LEFT, "ending.ch4", Progress.LAST > 4)


# ----------------------------------------------------------------------------- per frame


func tick(delta: float, paused: bool) -> void:
	_run_tasks(delta, paused)
	if paused:
		return
	_stage_t += delta
	_refresh_hint()
	_tick_arrival()
	_tick_wong()
	_discover()
	_tick_hints()
