class_name ChapterSixDirector
extends ChapterDirector

## Chapter 6, The Last Roof. 1 day until we leave.
##
## No party: the people who are left come up to the roof with what they have
## left, and the bulbs Mr. Ho strung years ago are on. Mr. Ng is packing his
## birds, one basket at a time, and Mei photographs him at it: she is still
## keeping things. Mum comes up with a card from Mrs. Wong, her new address and
## nothing else; Grandfather puts it in the pocket with her note. Then the
## lights go out (Ho took the line down; "we haven't left"), and Mei follows the
## leads the way she followed the water: into the stair hut and out of its
## back; past the lead that only looks like the right one; round the tank and
## under the coop to the last board, by the spot where she photographed Mr. Ng
## on the first day. The bulbs come on across the roof. After that it's just
## the evening: whoever she talks to. Grandfather gives her the old photograph,
## and doesn't remember who took it. Later, everyone laughing, the camera is
## right there, and Mei doesn't take the picture. Then, one by one: see you.
##
## On the side (OQ07, Mr. Ng's Last Pigeon): the fat one gets out of her basket
## and goes where she went on the first day, behind the tank.

enum {
	START,
	PHOTO_NG,
	CARD,
	LIGHTS_OUT,
	EVENING,
	MOMENT,
	LEAVING,
	COMPLETE,
}

const NAMES := ["START", "PHOTO_NG", "CARD", "LIGHTS_OUT", "EVENING", "MOMENT", "LEAVING", "COMPLETE"]

const OBJECTIVES := {
	PHOTO_NG: ["c6.obj.ng", "c6.obj.ng.hint"],
	LIGHTS_OUT: ["c6.obj.lights", ""],
	EVENING: ["c6.obj.evening", "c6.obj.evening.hint"],
}

const DAYS_LEFT := 1
const R := LevelBuilder.LEVEL_ROOF
## where everyone is sitting
const GATHERING := Vector3(-4.2, R, -11.4)

var flags := {
	"ng_asked": false, "ng_photo": false, "payoff_wong_address": false, "lights_failed": false,
	"lead_hut": false, "lead_cross": false, "board_mast": false, "lead_tank": false, "roof_lights_restored": false,
	"payoff_ng_home_line": false, "payoff_old_photo_camera": false, "unknown_photographer_forgotten": false,
	"mei_chose_presence": false,
	"oq07_escaped": false, "oq07_seen": false, "oq07_home": false, "optional_ng_last_pigeon": false,
}
## the rooftop conversations had (ng, ho, mum_grandfather, mei_mum, kit, kwok)
var talks: Dictionary = {}

var _stage_t := 0.0
var _sections: Dictionary = {}       # name -> {"bulbs": [...], "glow": OmniLight3D}
var _bulb_on: StandardMaterial3D
var _bulb_off: StandardMaterial3D
var _tank_dirs: Dictionary = {}
var _escape_t := 0.0
var _dusk_target := 0.3


func setup() -> void:
	_bind()
	_prepare_world()
	_register_shared()
	# the day is up here: the roof door and the airshaft aren't the way tonight
	for id in ["roofDoorTop", "shaftTop"]:
		unregister(id)
	look("roofDoorTop", world.refs.roofDoorTop, "env.c6_not_yet", 1.1, InteractionDirector.Priority.QUEST)
	_register_people()
	_register_circuit()
	photography.add_target("ng_birds", world.residents.ng, func() -> bool: return stage == PHOTO_NG and not scrapbook.entries.has("ng_birds"))
	photography.photo_kept.connect(_on_photo_kept)
	photography.refused.connect(_on_refused)
	photography.has_camera = true
	for id in ["lau", "ng", "ho", "chiu", "cheung", "line", "lau_clinic", "wong_room"]:
		if id in ["lau_clinic", "wong_room"] and not Progress.carried_photos.has(id):
			continue
		scrapbook.add(id)
		if Progress.carried_photos.has(id):
			photography.photos[id] = Progress.carried_photos[id]
		else:
			_reshoot(id)
	# the pages with no print: Kit, and Mrs. Wong, in Mei's notes
	for id in ["kit", "wong"]:
		scrapbook.add(id)
	Progress.after_unlocked = true
	for id in ["ho", "wong_room", "lau_clinic"]:
		Progress.late_notes[id] = true
	audio.quiet["drill"] = true
	audio.quiet["tv"] = true
	audio.quiet["chop"] = true
	audio.quiet["mahjong"] = true
	Progress.reach(6)


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


func force_stage(s: int) -> void:
	s = clampi(s, START, COMPLETE)
	if s >= CARD:
		flags.ng_photo = true
		scrapbook.add("ng_birds")
	if s >= LIGHTS_OUT:
		flags.payoff_wong_address = true
		Progress.late_notes["wong_after"] = true
		flags.lights_failed = true
		_lights(false)
	if s >= EVENING:
		for k in ["lead_hut", "lead_cross", "board_mast", "lead_tank", "roof_lights_restored"]:
			flags[k] = true
		_lights(true)
	set_stage(s)


## The next thing on the lead, in the objective's hint (and the fat one, once
## she has been gone a while).
func _live_hint() -> String:
	var lines: Array[String] = []
	if stage == LIGHTS_OUT:
		if not flags.lead_hut:
			lines.append(tr("c6.need.hut"))
		elif not flags.lead_cross:
			lines.append(tr("c6.need.cross"))
		elif not flags.board_mast:
			lines.append(tr("c6.need.board"))
		elif not flags.lead_tank:
			lines.append(tr("c6.need.tank"))
		else:
			lines.append(tr("c6.need.last"))
	if flags.oq07_escaped and not flags.oq07_home and _escape_t > 20.0 and stage >= LIGHTS_OUT and stage <= EVENING:
		if lines.is_empty():
			var o: Array = OBJECTIVES.get(stage, ["", ""])
			if String(o[1]) != "":
				lines.append(tr(o[1]))
		lines.append(tr("c6.need.pigeon"))
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
	(world.special.Fabric as Node3D).set_meta("gone", true)
	(world.special.Fabric as Node3D).visible = false
	world.sheet_blocking = false
	(world.special.Sheet as Node3D).rotation.x = -1.2
	var path := world.level_data.pigeon_path
	(world.special.LostPigeon as Node3D).position = path[path.size() - 1]
	for id in ["lau", "chan", "son", "wong", "chopper", "mahjong1", "mahjong2", "mahjong3", "worker", "child"]:
		var r: Resident = world.residents.get(id)
		if r:
			r.gone = true
			r.visible = false
	# everyone who's left, up here
	_pose(world.residents.grandfather, Vector3(-5.9, R, -11.6), Vector3(1, 0, 0.15), "sit")
	_pose(world.residents.mum, Vector3(-3.4, R, -12.2), Vector3(-1, 0, 0.3), "idle")
	_pose(world.residents.kit, world.residents.kit.home, Vector3(-0.5, 0, -1), "idle")
	_pose(world.residents.fanman, Vector3(-2.0, R, -12.8), Vector3(0, 0, 1), "work")
	_pose(world.residents.shopkeeper, Vector3(-7.3, R, -12.6), Vector3(1, 0, 0.2), "idle")
	_pose(world.residents.ng, Vector3(3.4, R, -20.6), Vector3(0, 0, -1), "work")
	# the bulbs: on, when the day begins
	_bulb_on = StandardMaterial3D.new()
	_bulb_on.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bulb_on.albedo_color = Color(1.0, 0.86, 0.58)
	_bulb_on.emission_enabled = true
	_bulb_on.emission = Color(1.0, 0.8, 0.5)
	_bulb_on.emission_energy_multiplier = 3.0
	_bulb_off = StandardMaterial3D.new()
	_bulb_off.albedo_color = Color(0.42, 0.4, 0.36)
	_bulb_off.roughness = 0.4
	for sec in BuildLastRoof.SECTIONS:
		var node := world.level.get_node_or_null("ChapterProps/Ch6/Bulbs/" + sec)
		if node == null:
			continue
		var bulbs: Array[MeshInstance3D] = []
		var glow: OmniLight3D = null
		for c in node.get_children():
			if c is MeshInstance3D and String(c.name).begins_with("Bulb"):
				bulbs.append(c)
			elif c is OmniLight3D:
				glow = c
		_sections[sec] = {"bulbs": bulbs, "glow": glow}
	_lights(true)
	world.dusk = _dusk_target


func _pose(r: Resident, at: Vector3, facing: Vector3, anim: String) -> void:
	if r.home.distance_to(at) > 0.01 or r.idle_anim != anim:
		r.place_at(at)
		r.facing = facing
		r.sprite.facing = facing
		r.idle_anim = anim
		r.sprite.play(anim)


func _lights(on: bool, section := "") -> void:
	for sec in _sections:
		if section != "" and sec != section:
			continue
		for bulb in _sections[sec].bulbs:
			(bulb as MeshInstance3D).material_override = _bulb_on if on else _bulb_off
		var glow: OmniLight3D = _sections[sec].glow
		if glow:
			glow.visible = on


## Is this section of bulbs lit?
func lit(section: String) -> bool:
	var glow: OmniLight3D = _sections.get(section, {}).get("glow")
	return glow != null and glow.visible


# ----------------------------------------------------------------------------- the evening begins


func opens_on_card() -> bool:
	return true


func start_intro() -> void:
	await _title_card("c6.card.number", "c6.card.title")
	player.teleport(Vector3(-2.2, R, -9.9))
	player.facing = Vector3(-0.3, 0, -1)
	cam.snap_next = true
	await fade.fade_in(1.4)
	mark("open")
	say("c6_open", func() -> void: set_stage(PHOTO_NG))


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


func _on_photo_kept(id: String) -> void:
	await scrapbook.file_photo(id)
	if id == "ng_birds":
		flags.ng_photo = true
		mark("ngPhoto")
		say("c6_ng_photo", func() -> void:
			set_stage(CARD)
			# as he lifts the next basket, the fat one gets out (OQ07)
			later(func() -> void:
				flags.oq07_escaped = true
				mark("oq07Escaped")
				audio.flutter()
				(world.special.LostPigeon as Node3D).position = world.level_data.pigeon_path[0]
				say("c6_pigeon_escapes", func() -> void: later(_wong_card, 2.5)), 1.2))


# ----------------------------------------------------------------------------- Mrs. Wong's card; the lights


## Mum comes up the roof stairs with a card, and takes it to Grandfather.
func _wong_card() -> void:
	var mum: Resident = world.residents.mum
	mum.place_at(world.refs.roofDoorTop + Vector3(0, 0, 0.4))
	mum.walk([Vector3(6.0, R, -11.2), Vector3(-1.0, R, -11.2), Vector3(-4.9, R, -11.1)], func() -> void:
		mum.facing = Vector3(-1, 0, -0.2)
		say("c6_wong_card", func() -> void:
			flags.payoff_wong_address = true
			Progress.late_notes["wong_after"] = true
			mark("wongCard")
			hud.notice("notice.c6_wong_after", 3.2)
			later(_lights_fail, 3.5)), 2.6)


func _lights_fail() -> void:
	flags.lights_failed = true
	mark("lightsFail")
	_lights(false)
	_dusk_target = 0.78
	audio.play("chime", 0.25, 0.5)
	say("c6_lights_fail", func() -> void: set_stage(LIGHTS_OUT))


# ----------------------------------------------------------------------------- the last circuit


func _register_circuit() -> void:
	var I := interaction
	var refs := world.refs
	var Q := InteractionDirector.Priority.QUEST
	I.add({"id": "hutLead", "position": refs.hutLead, "radius": 1.1, "priority": InteractionDirector.Priority.ENV, "verb": "verb.look",
		"can_interact": func() -> bool: return stage == LIGHTS_OUT and not flags.lead_hut,
		"interact": func() -> void: say("c6_hut_lead")})
	for spec in [["wrongBoard", refs.wrongBoard, false], ["mastBoard", refs.mastBoard, true]]:
		var right: bool = spec[2]
		I.add({"id": spec[0], "position": spec[1], "radius": 0.9, "priority": Q,
			"verb": func() -> String: return "verb.plug_lead" if flags.lead_cross else "verb.look",
			"can_interact": func() -> bool: return stage == LIGHTS_OUT and flags.lead_hut and not flags.board_mast,
			"interact": func() -> void:
				if not flags.lead_cross:
					say("c6_leads_tangle")
				elif right:
					flags.board_mast = true
					mark("boardMast")
					audio.click()
					say("c6_board_mast", _refresh_hint)
				else:
					say("c6_board_wrong")})
	I.add({"id": "lastBoard", "position": refs.lastBoard, "radius": 0.9, "priority": Q, "verb": "verb.plug_lead",
		"can_interact": func() -> bool: return stage == LIGHTS_OUT and flags.lead_tank and not flags.roof_lights_restored,
		"interact": _last_plug})
	# OQ07: calling the fat one down, once she has been seen
	I.add({"id": "lastPigeon", "position": refs.tank + Vector3(0, 0, -2.2), "radius": 1.6, "priority": Q, "verb": "verb.call",
		"can_interact": func() -> bool: return flags.oq07_seen and not flags.oq07_home,
		"interact": _call_pigeon})


## Turning the view: at the hut, from the side, the lead leaves by its back; at
## the crossing, from the north, the right lead climbs to the mast; at the
## tank, round it twice, the lead loops under the coop.
func _trace() -> void:
	if stage > LIGHTS_OUT or cam.rotating or locks.is_locked() or dialogue.is_open():
		return
	var refs := world.refs
	var side := cam.direction == 1 or cam.direction == 3
	if not flags.lead_hut:
		if mei_near(10.2, R, -13.7, 3.2) and side:
			flags.lead_hut = true
			mark("leadHut")
			audio.chime()
			if stage == LIGHTS_OUT:
				say("c6_hut_through", _refresh_hint)
		return
	if not flags.lead_cross:
		var at: Vector3 = refs.leadsCross
		if mei_near(at.x, at.y, at.z, 2.4) and cam.direction == 2:
			flags.lead_cross = true
			mark("leadCross")
			audio.chime()
			if stage == LIGHTS_OUT:
				say("c6_leads_seen", _refresh_hint)
		return
	if flags.board_mast and not flags.lead_tank:
		var tank: Vector3 = refs.tank
		if mei_near(tank.x, tank.y, tank.z, 3.4) and cam.direction != 0:
			_tank_dirs[cam.direction] = true
			if _tank_dirs.size() >= 2:
				flags.lead_tank = true
				mark("leadTank")
				audio.chime()
				say("c6_tank_loop", _refresh_hint)


## The last board: and the bulbs come on across the roofs, one string at a time.
func _last_plug() -> void:
	flags.roof_lights_restored = true
	mark("lightsOn")
	audio.click()
	locks.lock("lights")
	var t := 0.0
	for sec in ["NgCorner", "North", "Gathering"]:
		t += 0.7
		later(func() -> void:
			_lights(true, sec)
			audio.play("chime", 0.18, 1.6), t)
	later(func() -> void:
		locks.unlock("lights")
		_dusk_target = 0.9
		hud.notice("notice.c6_lights", 2.4)
		say("c6_lights_on", func() -> void: set_stage(EVENING)), t + 1.0)


# ----------------------------------------------------------------------------- OQ07, Mr. Ng's last pigeon


func _look_for_pigeon(delta: float) -> void:
	if not flags.oq07_escaped or flags.oq07_home:
		return
	_escape_t += delta
	if flags.oq07_seen or cam.rotating or locks.is_locked() or dialogue.is_open():
		return
	var tank: Vector3 = world.refs.tank
	if mei_near(tank.x, tank.y, tank.z, 4.0) and ViewMath.back(cam.current_yaw).dot(Vector3(0, 0, -1)) > 0.6:
		flags.oq07_seen = true
		mark("oq07Seen")
		audio.coo()
		say("c6_pigeon_found", _refresh_hint)


func _call_pigeon() -> void:
	flags.oq07_home = true
	mark("oq07Home")
	say("c6_pigeon_back", func() -> void:
		audio.flutter()
		var bird: Node3D = world.special.LostPigeon
		var t := create_tween()
		for p in world.level_data.pigeon_path:
			t.tween_property(bird, "position", p, 0.32)
		await t.finished
		audio.clack()
		_refresh_hint())


# ----------------------------------------------------------------------------- people


func _register_people() -> void:
	talk("grandfather", 1.6, _talk_grandfather)
	talk("mum", 1.5, _talk_mum)
	# The last electrical board is close to Ng's corner. A wider talk radius
	# masks that required board even while Mei is standing directly over it.
	talk("ng", 1.5, _talk_ng)
	talk("fanman", 1.6, func() -> void: _chat("ho", "c6_ho_talk", "c6_ho_after", "c6_ho_wait"))
	talk("kit", 1.6, func() -> void:
		_chat("kit", "c6_kit_talk", "c6_kit_after", "c6_kit_after", func() -> void: Progress.late_notes["kit"] = true))
	talk("shopkeeper", 1.7, func() -> void: _chat("kwok", "c6_kwok_talk", "c6_kwok_after", "c6_kwok_after"))


## A rooftop conversation: once the lights are back, the real one, then a line.
func _chat(who: String, first: String, after: String, before: String, then := Callable()) -> void:
	if stage < EVENING:
		say(before)
	elif not talks.has(who):
		talks[who] = true
		mark("talk_" + who)
		say(first, then)
	else:
		say(after)


func _talk_ng() -> void:
	if stage == PHOTO_NG and not flags.ng_asked:
		flags.ng_asked = true
		say("c6_ng_packing")
	elif flags.oq07_home and not flags.optional_ng_last_pigeon:
		flags.optional_ng_last_pigeon = true
		mark("oq07Done")
		say("c6_ng_pigeon_back")
	else:
		_chat("ng", "c6_ng_talk", "c6_ng_after", "c6_ng_after", func() -> void:
			flags.payoff_ng_home_line = true
			Progress.late_notes["ng"] = true)


func _talk_mum() -> void:
	if stage < EVENING:
		say("c6_mum_after")
	elif not talks.has("mum_grandfather"):
		_mum_and_grandfather()
	else:
		_chat("mei_mum", "c6_mei_mum", "c6_mum_after", "c6_mum_after")


func _talk_grandfather() -> void:
	if stage == LIGHTS_OUT:
		say("c6_dark")
	elif stage < EVENING:
		say("c6_grandfather_idle")
	elif not talks.has("mum_grandfather"):
		_mum_and_grandfather()
	elif talks.size() >= 2 and not flags.payoff_old_photo_camera:
		_old_photo()
	else:
		say("c6_grandfather_idle")


func _mum_and_grandfather() -> void:
	talks["mum_grandfather"] = true
	mark("talk_mum_grandfather")
	say("c6_mum_grandfather")


## He takes it out of his jacket. He doesn't remember who took it.
func _old_photo() -> void:
	mark("oldPhoto")
	hud.show_photo(OLD_PHOTO)
	say("c6_old_photo", func() -> void:
		hud.hide_photo()
		flags.payoff_old_photo_camera = true
		flags.unknown_photographer_forgotten = true
		photography.photos["old_photo"] = OLD_PHOTO
		scrapbook.add("old_photo")
		hud.notice("notice.c6_old_photo", 3.0)
		later(_moment, 12.0, _all_near))


func _all_near() -> bool:
	return mei_near(GATHERING.x, GATHERING.y, GATHERING.z, 6.0) and not dialogue.is_open() and not locks.is_locked() \
		and not photography.active


# ----------------------------------------------------------------------------- the moment she doesn't take


## Everyone laughing over nothing much. The camera's right there. Either she
## starts to raise it and lowers it herself, or she reaches for it and lets
## her hand fall: the shutter never fires.
func _moment() -> void:
	if stage != EVENING:
		return
	set_stage(MOMENT)
	mark("moment")
	hud.set_objective("", "")
	audio.flutter()
	audio.play("kids_0", 0.35, 1.2)
	for id in ["kit", "fanman", "grandfather"]:
		(world.residents[id] as Resident).face_toward(world.residents.grandfather.position, 4.0)
	photography.refusing = true
	hud.show_hint("hint.c6_camera")
	later(func() -> void:
		if photography.refusing:
			photography.reach_and_let_go(), 6.0)


func _on_refused() -> void:
	flags.mei_chose_presence = true
	mark("presence")
	hud.show_hint("")
	later(_leaving, 3.0, func() -> bool: return flags.mei_chose_presence)


## Test helper: the beat again from the start (to try the other path).
func restart_moment() -> void:
	flags.mei_chose_presence = false
	stage = EVENING
	_moment()


# ----------------------------------------------------------------------------- one by one


func _leaving() -> void:
	if stage >= LEAVING:
		return
	set_stage(LEAVING)
	mark("leaving")
	say("c6_leaving", func() -> void:
		var k := 0.0
		for id in ["fanman", "shopkeeper", "ng", "kit"]:
			var r: Resident = world.residents[id]
			later(func() -> void: r.fade("out"), k)
			k += 1.3
		later(_ending, k + 2.5))


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
	slice.ending.play(DAYS_LEFT, "ending.ch6", Progress.LAST > 6)


# ----------------------------------------------------------------------------- per frame


func tick(delta: float, paused: bool) -> void:
	_run_tasks(delta, paused)
	world.dusk = move_toward(world.dusk, _dusk_target, delta * 0.03)
	if paused:
		return
	_stage_t += delta
	_refresh_hint()
	_trace()
	_look_for_pigeon(delta)
