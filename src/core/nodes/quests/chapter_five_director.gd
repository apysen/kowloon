class_name ChapterFiveDirector
extends ChapterDirector

## Chapter 5, Rooms Going Quiet. 6 days until we leave.
##
## The day opens on silence: no drill, no pounding from the workshop, no TV,
## no children on the roofs. Mum has a small box of things that aren't theirs:
## Mrs. Fong's stool, Mr. Ho's screwdriver, Mr. Ng's birdseed and the rope Mei
## kept, Mrs. Wong's bowl, a mahjong tile out of Grandfather's drawer. They go
## back in any order. Mr. Ho and Mr. Ng are packing; two of the mahjong four
## are left. Mrs. Fong has gone, and the footbridge to her door with her; the
## way round is through the metal shop behind Lau's stairs, open and empty now,
## and the narrow stair behind its pegboard that only shows from the side.
## Mrs. Wong has gone too, early: on her table, an envelope for the old fool.
## Grandfather reads it and keeps it in his pocket. Then, at home, the red bowl
## is gone off the shelf, and Mei and Mum argue.
##
## The day's photograph is the Chans' clothesline over the catwalk, empty but
## for its pegs: the first with nobody in it. Mrs. Wong's room and Lau's
## clinic can be photographed too, if Mei wants; nothing asks her to.
##
## On the side (OQ06, The Lost Address): Mrs. Leung needs her sister's block
## number. Mrs. Wong knew it, and she's gone; she left it with Mr. Kwok, whose
## stall kept everyone's post. His shutter is half down while he packs, and the
## stall only ever shows from its open front: turned to face it, the bundle of
## notes is there on the floor under the shutter.

enum {
	START,
	RETURNS,
	PHOTO_LINE,
	HOME,
	ARGUMENT,
	COMPLETE,
}

const NAMES := ["START", "RETURNS", "PHOTO_LINE", "HOME", "ARGUMENT", "COMPLETE"]

const OBJECTIVES := {
	RETURNS: ["c5.obj.return", ""],
	PHOTO_LINE: ["c5.obj.photo", "c5.obj.photo.hint"],
	HOME: ["c5.obj.home", "c5.obj.home.hint"],
}

const DAYS_LEFT := 6
## Where the riser's been shut: the ledge beyond the well, and the rooms off it.
const DRY_WING := [11.7, 25.3, -21.6, -16.25]

var flags := {
	"items_taken": false, "footbridge_seen": false, "shop_seen": false, "stair_found": false,
	"returned_screwdriver": false, "returned_ng": false, "payoff_ng_rope": false, "returned_stool_to_empty_room": false,
	"returned_tile": false, "returned_bowl": false, "wong_note": false, "payoff_wong_bet": false,
	"grandfather_keeps_note": false, "line_photo": false, "peg_fell": false, "dry_tap": false,
	"mei_mum_argument": false, "mei_understands_mum_partial": false,
	"oq06_asked": false, "oq06_seen": false, "oq06_note": false, "oq06_done": false,
}

var _stage_t := 0.0
var _home_t := 0.0
var _pipes: Array[Dictionary] = []
var _mum_sat := false


func setup() -> void:
	_bind()
	_prepare_world()
	_register_shared()
	# what isn't there any more to look at
	for id in ["chair", "sign", "footbridge", "fongDoor", "unitSink", "laneGate", "workshopDoorShut"]:
		unregister(id)
	_register_people()
	_register_returns()
	_register_route()
	_register_sounds()
	photography.add_thing("line", AABB(Vector3(15.4, LevelBuilder.LEVEL_B + 1.4, -13.0), Vector3(1.2, 1.6, 2.0)),
		func() -> bool: return stage == PHOTO_LINE and not scrapbook.entries.has("line"))
	photography.add_place("wong_room", func() -> bool: return world.current_room == "wong" and not scrapbook.entries.has("wong_room"))
	photography.add_place("lau_clinic", func() -> bool: return _in_clinic() and not scrapbook.entries.has("lau_clinic"))
	photography.photo_kept.connect(_on_photo_kept)
	dialogue.event_fired.connect(_on_dialogue_event)
	photography.has_camera = true
	for id in ["lau", "ng", "ho", "chiu", "cheung"]:
		scrapbook.add(id)
		if Progress.carried_photos.has(id):
			photography.photos[id] = Progress.carried_photos[id]
		else:
			_reshoot(id)
	Progress.after_unlocked = true
	Progress.reach(5)


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
	if s >= RETURNS:
		_take_items()
	if s >= HOME:
		for k in ["returned_screwdriver", "returned_ng", "payoff_ng_rope", "returned_stool_to_empty_room", "returned_tile",
				"returned_bowl", "payoff_wong_bet", "grandfather_keeps_note", "line_photo", "stair_found", "footbridge_seen"]:
			flags[k] = true
		flags.wong_note = false
		scrapbook.add("line")
		for n in ["FongStool", "WongBowl"]:
			_show(n, true)
		_show("WongNote", false)
	set_stage(s)


## The things still to take back, and to whom, in the objective's hint.
func _live_hint() -> String:
	if stage != RETURNS:
		return ""
	var lines: Array[String] = []
	if not flags.returned_screwdriver:
		lines.append(tr("c5.need.ho"))
	if not flags.returned_ng:
		lines.append(tr("c5.need.ng"))
	if not flags.returned_tile:
		lines.append(tr("c5.need.tile"))
	if not flags.returned_bowl:
		lines.append(tr("c5.need.wong"))
	if not flags.returned_stool_to_empty_room:
		if flags.stair_found:
			lines.append(tr("c5.need.fong_stair"))
		elif flags.shop_seen:
			lines.append(tr("c5.need.fong_shop"))
		elif flags.footbridge_seen:
			lines.append(tr("c5.need.fong_gone"))
		else:
			lines.append(tr("c5.need.fong"))
	if flags.wong_note:
		lines.append(tr("c5.need.note"))
	if flags.oq06_asked and not flags.oq06_done:
		lines.append(tr("c5.need.leung_give" if flags.oq06_note else "c5.need.leung"))
	return "\n".join(lines)


func _refresh_hint() -> void:
	var live := _live_hint()
	if live != "" and live != hint:
		hint = live
		hud.set_objective(objective, hint)


func returned_count() -> int:
	var n := 0
	for k in ["returned_screwdriver", "returned_ng", "returned_stool_to_empty_room", "returned_tile", "returned_bowl"]:
		n += int(flags[k])
	return n


func _all_back() -> bool:
	return returned_count() == 5


# ----------------------------------------------------------------------------- the world on this day


func _prepare_world() -> void:
	var door := world.door("serviceDoor")
	door.discovered = true
	world.open_door(door)
	world.move_crate(world.refs.crateEnd)
	# the Chans' washing is gone from the catwalk and the roof both
	world.set_fabric_state("roof")
	(world.special.Fabric as Node3D).set_meta("gone", true)
	(world.special.Fabric as Node3D).visible = false
	world.sheet_blocking = false
	(world.special.Sheet as Node3D).rotation.x = -1.2
	var path := world.level_data.pigeon_path
	(world.special.LostPigeon as Node3D).position = path[path.size() - 1]
	# gone: the Lau, the Chans, Mrs. Wong, the chopper, the third at mahjong, the
	# worker and the boy upstairs
	for id in ["lau", "chan", "son", "wong", "chopper", "mahjong3", "worker", "child"]:
		var r: Resident = world.residents.get(id)
		if r:
			r.gone = true
			r.visible = false
	# and a good many of the people on the roofs round about
	var k := 0
	for r in world.residents.values():
		var res := r as Resident
		if not res.story:
			if k % 5 != 0:
				res.gone = true
				res.visible = false
			k += 1
	# the ones still here, packing
	_pose(world.residents.mum, Vector3(-10.0, 0, -1.25), Vector3(-1, 0, -0.3), "work")
	_pose(world.residents.fanman, Vector3(-3.4, 0, 0.35), Vector3(0, 0, 1), "work")
	_pose(world.residents.mahjong2, Vector3(-2.7, 0, 2.55), Vector3(1, 0, 0.2), "idle")
	_pose(world.residents.mahjong1, Vector3(-1.55, 0, 2.75), Vector3(-1, 0, 0.2), "idle")
	_pose(world.residents.shopkeeper, world.refs.kwokPacking + Vector3(-0.8, 0, 0.2), Vector3(1, 0, 0), "work")
	# the envelope on Mrs. Wong's table; the bowl and the stool not back yet
	_show("WongNote", true)
	_show("WongBowl", false)
	_show("FongStool", false)
	_pose(world.residents.leung, world.residents.leung.home, Vector3(-0.4, 0, -1), "idle")
	_sync_world()


func _sync_world() -> void:
	if _mum_sat:
		# at the table, across from Grandfather's chair
		_pose(world.residents.mum, Vector3(-10.4, 0, -0.45), Vector3(-1, 0, 0.1), "sit")


func _pose(r: Resident, at: Vector3, facing: Vector3, anim: String) -> void:
	if r.home.distance_to(at) > 0.01 or r.idle_anim != anim:
		r.place_at(at)
		r.facing = facing
		r.sprite.facing = facing
		r.idle_anim = anim
		r.sprite.play(anim)


## Something built for today that comes and goes: `name` under ChapterProps/Ch5.
func _show(name: String, on: bool) -> void:
	var n: Node3D = world.level.get_node_or_null("ChapterProps/Ch5/" + name)
	if n == null:
		return
	_set_gone(n, not on)


func _set_gone(n: Node, gone: bool) -> void:
	if n is Node3D:
		n.set_meta("gone", gone)
		(n as Node3D).visible = not gone
	for c in n.get_children():
		_set_gone(c, gone)


func _in_clinic() -> bool:
	var p := player.position
	return p.y < 1.0 and p.x > 0.0 and p.x < 8.0 and p.z > -15.0 and p.z < -9.0


# ----------------------------------------------------------------------------- the day begins


func opens_on_card() -> bool:
	return true


func start_intro() -> void:
	await _title_card("c5.card.number", "c5.card.title")
	player.teleport(Vector3(-8.7, 0, -0.9))
	player.facing = Vector3(-1, 0, -0.2)
	cam.snap_next = true
	# no text at first: just the flat, and how quiet it is
	hud.set_quiet(true)
	await fade.fade_in(1.6)
	mark("open")
	later(_mum_calls, 5.0)


func _mum_calls() -> void:
	hud.set_quiet(false)
	say("c5_open", func() -> void:
		_take_items()
		set_stage(RETURNS))


func _take_items() -> void:
	if flags.items_taken:
		return
	flags.items_taken = true
	mark("itemsTaken")
	var items: Node = world.level.get_node_or_null("ChapterProps/Ch5/Borrowed/Items")
	if items:
		_set_gone(items, true)


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


# ----------------------------------------------------------------------------- people


func _register_people() -> void:
	talk("grandfather", 1.5, _talk_grandfather)
	talk("mum", 1.4, _talk_mum)
	talk("fanman", 1.6, _talk_ho)
	talk("ng", 1.9, _talk_ng)
	talk("mahjong2", 1.7, _talk_mahjong)
	talk("mahjong1", 1.7, _talk_mahjong)
	talk("shopkeeper", 1.8, _talk_kwok)
	talk("leung", 1.6, _talk_leung)


func _talk_kwok() -> void:
	if flags.oq06_asked and not flags.oq06_note and not flags.oq06_done:
		say("c5_kwok_note", _refresh_hint)
	elif flags.oq06_done:
		say("c5_kwok_packing")
	else:
		say("c5_kwok")


func _talk_leung() -> void:
	if flags.oq06_done:
		say("c5_leung_after")
	elif flags.oq06_note:
		flags.oq06_done = true
		mark("oq06Done")
		say("c5_leung_done", _refresh_hint)
	elif flags.oq06_asked:
		say("c5_leung_wait")
	else:
		flags.oq06_asked = true
		mark("oq06Asked")
		say("c5_leung", _refresh_hint)


## The stall shows only from its front: with the view turned so the camera is
## east of it, and Mei near, the bundle is there under the half-down shutter.
func _sight_stall() -> void:
	if flags.oq06_seen or not flags.oq06_asked or cam.rotating or dialogue.is_open() or locks.is_locked():
		return
	var p := player.position
	if p.y > 1.0 or p.x < 2.0 or p.x > 4.2 or p.z < -7.0 or p.z > -3.0:
		return
	if ViewMath.back(cam.current_yaw).dot(Vector3(1, 0, 0)) > 0.6:
		flags.oq06_seen = true
		mark("oq06Seen")
		audio.chime()
		hud.notice("notice.c5_note_seen", 3.2)


func _take_leung_note() -> void:
	say("c5_under_shutter", func() -> void:
		hud.notice("notice.c5_leung_note", 2.8)
		_refresh_hint())


func _talk_grandfather() -> void:
	if flags.wong_note:
		_give_note()
	elif flags.payoff_wong_bet:
		say("c5_grandfather_after")
	else:
		say("c5_grandfather")


func _talk_mum() -> void:
	if not flags.items_taken:
		return
	if stage >= ARGUMENT:
		say("c5_mum_after")
	else:
		say("c5_mum")


func _talk_ho() -> void:
	if not flags.items_taken or flags.returned_screwdriver:
		say("c5_ho_after")
		return
	flags.returned_screwdriver = true
	mark("returnedScrewdriver")
	say("c5_ho", func() -> void:
		# and on his page, later, in the same hand
		Progress.late_notes["ho"] = true
		_returned("notice.c5_ho"))


func _talk_ng() -> void:
	if not flags.items_taken or flags.returned_ng:
		say("c5_ng_after")
		return
	flags.returned_ng = true
	flags.payoff_ng_rope = true
	mark("returnedNg")
	say("c5_ng", func() -> void: _returned("notice.c5_ng"))


func _talk_mahjong() -> void:
	if not flags.items_taken or flags.returned_tile:
		say("c5_mahjong_after")
		return
	flags.returned_tile = true
	mark("returnedTile")
	say("c5_mahjong", func() -> void: _returned("notice.c5_tile"))


func _on_dialogue_event(event: String) -> void:
	match event:
		"tileInTin":
			audio.play("tile_tin", 0.7)
		"paper":
			audio.play("paper", 0.8)
		"stoolDown":
			audio.play("crate_down", 0.35, 1.8)
			_show("FongStool", true)
		"noteTaken":
			flags.oq06_note = true
			_show("KwokNote/Note", false)
		"mumSits":
			_mum_sat = true
			_sync_world()
		"bowlDown":
			audio.play("crate_down", 0.25, 2.2)
			_show("WongBowl", true)
			_show("WongNote", false)


func _returned(notice_key: String) -> void:
	hud.notice(notice_key, 2.6)
	_refresh_hint()
	_check_home()


## Everything back and the note given: home, where Mum is.
func _check_home() -> void:
	if stage == RETURNS and _all_back() and flags.payoff_wong_bet and flags.line_photo:
		set_stage(HOME)


# ----------------------------------------------------------------------------- the returns that aren't to people


func _register_returns() -> void:
	var I := interaction
	var refs := world.refs
	var Q := InteractionDirector.Priority.QUEST
	# Mrs. Fong's: the door open, nobody here, a chalked address
	I.add({"id": "fongRoom", "position": refs.fongInside + Vector3(0, 0, 1.1), "radius": 1.3, "priority": Q,
		"verb": func() -> String: return "verb.leave" if _stool_pending() else "verb.look",
		"interact": func() -> void:
			if _stool_pending():
				flags.returned_stool_to_empty_room = true
				mark("returnedStool")
				say("c5_fong", func() -> void: _returned("notice.c5_stool"))
			else:
				say("c5_fong_again")})
	look("fongChalk", refs.fongChalk, "env.c5_chalk", 1.0)
	# Mrs. Wong's table: the bowl down, the envelope up
	I.add({"id": "wongTable", "position": refs.wongTable, "radius": 1.3, "priority": Q,
		"verb": func() -> String: return "verb.leave" if flags.items_taken and not flags.returned_bowl else "verb.look",
		"can_interact": func() -> bool: return flags.items_taken,
		"interact": func() -> void:
			if not flags.returned_bowl:
				flags.returned_bowl = true
				flags.wong_note = true
				mark("wongNote")
				say("c5_wong", func() -> void:
					hud.notice("notice.c5_note", 3.0)
					_refresh_hint())
			else:
				say("c5_wong_again")})


func _stool_pending() -> bool:
	return flags.items_taken and not flags.returned_stool_to_empty_room


## Mrs. Wong's note, to Grandfather. He keeps it.
func _give_note() -> void:
	flags.wong_note = false
	mark("noteGiven")
	say("c5_note", func() -> void:
		flags.payoff_wong_bet = true
		flags.grandfather_keeps_note = true
		Progress.late_notes["wong_room"] = true
		_refresh_hint()
		_check_home())


# ----------------------------------------------------------------------------- the way round


func _register_route() -> void:
	var I := interaction
	var refs := world.refs
	var Q := InteractionDirector.Priority.QUEST
	I.add({"id": "backStairUp", "position": refs.backStairFoot, "radius": 1.0, "priority": Q, "verb": "verb.upstairs",
		"can_interact": func() -> bool: return flags.stair_found,
		"interact": func() -> void: transition(refs.backStairTop + Vector3(0.1, 0, 0), 12)})
	I.add({"id": "backStairDown", "position": refs.backStairTop, "radius": 0.9, "priority": Q, "verb": "verb.downstairs",
		"interact": func() -> void: transition(refs.backStairFoot + Vector3(0.05, 0, 0.3), 12)})
	look("pegboard", Vector3(9.2, 0, -16.2), "env.c5_pegboard", 1.1)
	look("paleSquare", refs.lauPale, "env.c5_pale", 1.3)
	look("lauBracket", refs.lauSign, "env.c5_bracket", 1.0, InteractionDirector.Priority.DECOR)
	look("stall", Vector3(2.4, 0, -5.0), "env.c5_stall", 1.0, InteractionDirector.Priority.DECOR)
	I.add({"id": "stallGap", "position": refs.stallGap, "radius": 1.0, "priority": Q, "verb": "verb.reach",
		"can_interact": func() -> bool: return flags.oq06_seen and not flags.oq06_note,
		"interact": _take_leung_note})
	look("fongTap", Vector3(15.9, LevelBuilder.LEVEL_B, -16.8), "env.c5_tap", 0.9)
	I.add({"id": "unitSinkDry", "position": Vector3(23.2, LevelBuilder.LEVEL_B, -20.2), "radius": 0.8,
		"priority": InteractionDirector.Priority.ENV, "verb": "verb.turn",
		"interact": func() -> void:
			flags.dry_tap = true
			say([{"speaker": "", "text": "env.c5_sink"}])})
	look("foldedTable", Vector3(-3.4, 0, 2.2), "env.c5_folded_table", 1.0)
	look("fongPosts", world.refs.fongBoltRoof, "env.c5_fong_posts", 1.0, InteractionDirector.Priority.DECOR)
	look("waiBridgeGone", world.refs.waiBridgeTop, "env.c5_wai_bridge", 1.0, InteractionDirector.Priority.DECOR)
	look("emptyLine", Vector3(16.0, LevelBuilder.LEVEL_B, -12.0), "env.c5_line", 1.0, InteractionDirector.Priority.DECOR)
	look("footbridgeGone", world.refs.footbridgeGap, "env.c5_footbridge", 0.9)


## Turning the view in the back shop: from the front the pegboard hides it;
## from the side, or from behind, the slot at its end shows a narrow stair.
func _discover() -> void:
	if cam.rotating or locks.is_locked() or dialogue.is_open() or not flags.items_taken:
		return
	var B := LevelBuilder.LEVEL_B
	if not flags.footbridge_seen and mei_near(world.refs.footbridgeGap.x, B, world.refs.footbridgeGap.z, 1.4):
		flags.footbridge_seen = true
		mark("footbridgeGone")
		hud.notice("notice.c5_footbridge", 3.2)
		_refresh_hint()
	if world.current_room == "backshop":
		if not flags.shop_seen:
			flags.shop_seen = true
			mark("shopSeen")
			_refresh_hint()
		if not flags.stair_found and cam.direction != 0:
			flags.stair_found = true
			mark("stairFound")
			audio.chime()
			say("c5_stair", _refresh_hint)


# ----------------------------------------------------------------------------- the clothesline, and the peg


func _tick_line() -> void:
	if flags.line_photo or not flags.items_taken or dialogue.is_open() or locks.is_locked():
		return
	if stage == RETURNS and _on_catwalk():
		mark("lineReached")
		set_stage(PHOTO_LINE)
		later(_drop_peg, 2.6)


func _on_catwalk() -> bool:
	var p := player.position
	return absf(p.y - LevelBuilder.LEVEL_B) < 0.5 and p.x > 12.4 and p.x < 23.6 and p.z > -13.0 and p.z < -11.0


## One peg lets go in the wind. No prompt, no music, nothing to press.
func _drop_peg() -> void:
	if flags.peg_fell:
		return
	flags.peg_fell = true
	var peg: Node3D = world.level.get_node_or_null("ChapterProps/Ch5/ChansLine/LoosePeg")
	if peg == null:
		return
	var land := Vector3(peg.position.x + 0.25, LevelBuilder.LEVEL_B + 0.02, peg.position.z + 0.3)
	var t := create_tween().set_parallel()
	t.tween_property(peg, "position", land, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(peg, "rotation", Vector3(1.4, 0.6, 1.57), 0.7)
	await t.finished
	audio.play_at("peg_drop", peg.global_position, 9.0, 0.8)


func _on_photo_kept(id: String) -> void:
	await scrapbook.file_photo(id)
	if id == "line":
		flags.line_photo = true
		mark("linePhoto")
		set_stage(RETURNS)
		_check_home()


# ----------------------------------------------------------------------------- home, and Mum


func _tick_home(delta: float) -> void:
	if stage != HOME or dialogue.is_open() or locks.is_locked():
		_home_t = 0.0
		return
	if world.current_room == "apartment":
		_home_t += delta
		if _home_t > 1.2:
			_argument()
	else:
		_home_t = 0.0


func _argument() -> void:
	if stage != HOME:
		return
	set_stage(ARGUMENT)
	mark("argument")
	hud.set_quiet(true)
	var mum: Resident = world.residents.mum
	mum.face_toward(player.position, 30.0)
	say("c5_argument", func() -> void:
		flags.mei_mum_argument = true
		flags.mei_understands_mum_partial = true
		# no hug and no apology: the controls come back
		hud.set_quiet(false)
		later(_ending, 7.0))


# ----------------------------------------------------------------------------- sounds


## Water still in the pipes everywhere but the wing whose riser was shut.
func _register_sounds() -> void:
	var B := LevelBuilder.LEVEL_B
	# what isn't heard today: the drill, the workshop, the TV, the children,
	# the chopping, the mahjong game
	for q in ["drill", "tv", "kids", "chop", "mahjong", "fabric_drip", "pigeons"]:
		audio.quiet[q] = true
	# the pipes: in the flat, the hall, up the stairwell, along the corridor
	for spot in [[Vector3(-9.0, 0, -3.3), 5.0, 0.0], [Vector3(-2.0, 0, -0.8), 7.0, 0.0], [Vector3(9.4, 0, -13.2), 5.0, 0.0],
			[Vector3(10.0, B, -13.0), 4.2, B], [Vector3(2.0, B, -12.0), 6.0, B]]:
		_pipes.append(audio.add_loop("pipes", "pipe_hum", spot[0], spot[1], spot[2], 0.45,
			func() -> bool: return not in_dry_wing(player.position)))
	# the birds farther off: Mr. Ng's are boxed; somebody else's, a roof or two away
	audio.add_shots("farPigeons", ["coo_0", "coo_1", "coo_2"], Vector3(-18, 13, -26), 30.0, 13.0, [2.5, 7.0], 0.35)
	# now and then somebody's footsteps, somewhere in the building
	audio.add_shots("farSteps", ["step_0", "step_1", "step_2", "step_3"], Vector3(6, 5, -12), 26.0, 5.0, [6.0, 16.0], 0.12)


func in_dry_wing(p: Vector3) -> bool:
	return absf(p.y - LevelBuilder.LEVEL_B) < 1.5 and p.x > DRY_WING[0] and p.x < DRY_WING[1] and p.z > DRY_WING[2] and p.z < DRY_WING[3]


## How loud the pipes are where `p` is (the falloff AudioZones uses).
func pipe_hum_at(p: Vector3) -> float:
	var total := 0.0
	for e in _pipes:
		if in_dry_wing(p):
			continue
		var pos: Vector3 = e.pos
		var dy := absf(p.y - pos.y)
		var lf := 1.0 if dy < 3.0 else (0.2 if dy < 9.0 else 0.05)
		var d := Vector2(p.x - pos.x, p.z - pos.z).length()
		var v := maxf(0.0, 1.0 - d / float(e.radius))
		total += v * v * lf * float(e.gain)
	return total


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
	slice.ending.play(DAYS_LEFT, "ending.ch5", Progress.LAST > 5)


# ----------------------------------------------------------------------------- per frame


func tick(delta: float, paused: bool) -> void:
	_run_tasks(delta, paused)
	if paused:
		return
	_stage_t += delta
	_refresh_hint()
	_discover()
	_sight_stall()
	_tick_line()
	_tick_home(delta)
