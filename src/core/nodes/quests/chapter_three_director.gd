class_name ChapterThreeDirector
extends ChapterDirector

## Chapter 3, Last Batch. 18 days until we leave.
##
## The workshop upstairs is pounding. Kit comes for Mei with an empty crate:
## her uncle needs hands. Uncle Chiu's last shipment of fish balls has twelve
## crates and no way down: the stair is blocked and the loading route half
## gone. Crates used to go up: through the hatch to the roof, across the slot
## on a plank, along the neighbours' balcony to a platform on a pulley, and
## down to the lane. From the roof, turning to look south finds the pulley over
## the balcony (from the front it's cut away). Then it takes people: Mr. Ng's
## rope, the plank Wai is sitting on, Ho to say the pulley will hold, and Kit
## on the winch. The signboard in the way folds, but its hinges are round the
## back. The last crate goes down; Chiu writes where it's going; and later, up
## on the roof, Kit shows Mei the key to her new flat.
##
## Perspective shows what's possible; people make it usable.

## On the side (OQ05, Wai's Shortcut): once he's given up the plank, Wai says
## there's a way from Chiu's roof to the Chans' in thirty seconds, and goes
## to wait on the roof. It's three things seen by turning the view: steel steps
## behind Chiu's back parapet down onto the lower roof; from there, looking
## back from the north behind the washing, a ladder up to a balcony on the
## back of Mei's building; and from its side, two planks up onto the roof.

enum {
	START,
	GO_WITH_KIT,
	LOADING_ROUTE,
	FIND_PARTS,
	SET_UP,
	RUN_CRATE,
	FINAL_CRATE,
	PHOTO_WORKERS,
	KIT_LATER,
	COMPLETE,
}

const NAMES := ["START", "GO_WITH_KIT", "LOADING_ROUTE", "FIND_PARTS", "SET_UP", "RUN_CRATE", "FINAL_CRATE", "PHOTO_WORKERS", "KIT_LATER", "COMPLETE"]

const OBJECTIVES := {
	GO_WITH_KIT: ["c3.obj.kit", "c3.obj.kit.hint"],
	LOADING_ROUTE: ["c3.obj.route", "c3.obj.route.hint"],
	FIND_PARTS: ["c3.obj.route", "c3.obj.parts.hint"],
	SET_UP: ["c3.obj.setup", "c3.obj.setup.hint"],
	RUN_CRATE: ["c3.obj.kit_winch", ""],
	FINAL_CRATE: ["c3.obj.lane", "c3.obj.lane.hint"],
	PHOTO_WORKERS: ["c3.obj.photo", "c3.obj.photo.hint"],
	KIT_LATER: ["c3.obj.later", "c3.obj.later.hint"],
}

const DAYS_LEFT := 18

var flags := {
	"factory_route_pulley_found": false, "story_item_rope": false, "story_item_plank": false, "pulley_safe": false,
	"plank_laid": false, "sign_hinges_seen": false, "sign_folded": false, "rope_rigged": false, "crate_down": false,
	"oq05_asked": false, "oq05_stair": false, "oq05_ladder": false, "oq05_bridge": false, "oq05_done": false,
	"chiu_scene": false, "setup_kit_address": false, "setup_mei_fears_disconnection": false,
}

var _stage_t := 0.0
var _hinted: Dictionary = {}
var _plank: Node3D
var _rope: Node3D
var _rope_down: MeshInstance3D       # pulley to platform: it pays out as the platform goes down
var _crate: Node3D
var _run: Dictionary = {}          # the crate on its way down: path and progress
var _crate_carrier: Resident
var _sign_t := -1.0
var _kit_following_ladder := false
var _kit_on_roof := false


func setup() -> void:
	_bind()
	_prepare_world()
	_register_shared()
	unregister("workshopDoorShut")
	_register_people()
	_register_route()
	_register_shortcut()
	_register_sounds()
	# the day's photograph: the hands round the last worktable, the last time
	photography.add_target("chiu", world.residents.hand_a, func() -> bool: return stage == PHOTO_WORKERS and not scrapbook.entries.has("chiu"))
	photography.photo_kept.connect(_on_photo_kept)
	photography.has_camera = true
	for id in ["lau", "ng", "ho"]:
		if Progress.carried_photos.has(id):
			scrapbook.add(id)
			photography.photos[id] = Progress.carried_photos[id]
		elif id != "ho":
			scrapbook.add(id)
			_reshoot(id)
	Progress.reach(3)


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


## The route's steps change as they're done: the hint says what's left, and
## who to ask for it.
func _live_hint() -> String:
	var lines: Array[String] = []
	match stage:
		LOADING_ROUTE:
			var on_roof := absf(player.position.y - BuildWorkshop.ROOF_Y) < 0.4
			lines.append(tr("c3.route.look" if on_roof else "c3.route.climb"))
		FIND_PARTS:
			if not flags.story_item_rope:
				lines.append(tr("c3.need.rope"))
			if not flags.story_item_plank:
				lines.append(tr("c3.need.plank"))
			if not flags.pulley_safe:
				lines.append(tr("c3.need.pulley"))
		SET_UP:
			if not flags.plank_laid:
				lines.append(tr("c3.do.plank"))
			if not flags.sign_folded:
				lines.append(tr("c3.do.sign_fold" if flags.sign_hinges_seen else "c3.do.sign_look"))
			if not flags.rope_rigged:
				lines.append(tr("c3.do.rope"))
			if lines.is_empty():
				lines.append(tr("c3.do.kit"))
	if flags.oq05_asked and not flags.oq05_done:
		if lines.is_empty():
			var o: Array = OBJECTIVES.get(stage, ["", ""])
			if String(o[1]) != "":
				lines.append(tr(o[1]))
		lines.append(tr("c3.need.wai"))
	return "\n".join(lines)


func _refresh_hint() -> void:
	var live := _live_hint()
	if live != "" and live != hint:
		hint = live
		hud.set_objective(objective, hint)


func force_stage(s: int) -> void:
	s = clampi(s, START, COMPLETE)
	flags.factory_route_pulley_found = s >= FIND_PARTS
	for k in ["story_item_rope", "story_item_plank", "pulley_safe"]:
		flags[k] = s >= SET_UP
	if s >= RUN_CRATE:
		_lay_plank()
		_fold_sign(true)
		_rig_rope()
	flags.crate_down = s >= FINAL_CRATE
	flags.chiu_scene = s >= PHOTO_WORKERS
	set_stage(s)


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
	var mum: Resident = world.residents.mum
	mum.place_at(Vector3(-10.05, 0, -2.4))
	mum.facing = Vector3(0, 0, -1)
	mum.idle_anim = "work"
	# Wai, sitting on the plank at home; Ho, up on the workshop roof looking at the old hoist
	_pose(world.residents.son, Vector3(-5.4, LevelBuilder.LEVEL_B, -10.6), Vector3(1, 0, 0), "sit")
	_pose(world.residents.fanman, Vector3(-3.4, BuildWorkshop.ROOF_Y, 3.3), Vector3(0, 0, 1), "idle")
	_sync_world()


func _sync_world() -> void:
	var kit: Resident = world.residents.kit
	var chiu: Resident = world.residents.chiu
	var R := BuildWorkshop.ROOF_Y
	# Once Ho has approved the pulley, he steps away from the gap. Otherwise
	# his higher-priority conversation masks the prompt for laying the plank.
	if flags.pulley_safe and stage < RUN_CRATE:
		_pose(world.residents.fanman, Vector3(-5.4, R, 2.8), Vector3(0, 0, 1), "idle")
	if stage >= FIND_PARTS and stage < SET_UP and not _kit_following_ladder:
		# Kit goes up to the roof with Mei once the old route is found
		_pose(kit, Vector3(-4.8, R, 1.2), Vector3(0, 0, 1), "idle")
	# Rigging the rope must not teleport Kit across the roof or pen Mei against
	# the winch. She stays at the hatch until Mei asks her to start the run.
	elif stage >= SET_UP and stage < RUN_CRATE and not _kit_following_ladder:
		_pose(kit, Vector3(-4.8, R, 1.2), Vector3(0, 0, 1), "idle")
	elif stage == FINAL_CRATE:
		_pose(kit, world.refs.lane + Vector3(-2.3, 0, 0.3), Vector3(1, 0, 0), "idle")
		_pose(chiu, world.refs.lane + Vector3(-3.2, 0, 0), Vector3(-1, 0, 0), "write")
	elif stage >= PHOTO_WORKERS:
		# later, up on the roof, where it's quiet
		_pose(kit, Vector3(-5.2, R, 3.2), Vector3(0, 0, 1), "idle")
		_pose(chiu, world.refs.chiu, Vector3(0, 0, -1), "work")
	var son: Resident = world.residents.son
	if flags.story_item_plank and son.idle_anim == "sit":
		_pose(son, Vector3(-5.4, LevelBuilder.LEVEL_B, -10.6), Vector3(1, 0, 0.3), "idle")


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
	await _title_card("c3.card.number", "c3.card.title")
	# the corridor outside the flat: the thumping from upstairs, and Kit
	player.teleport(Vector3(-4.6, 0, 0.1))
	player.facing = Vector3(1, 0, 0)
	cam.snap_next = true
	var kit: Resident = world.residents.kit
	kit.set_carrying(true)
	await fade.fade_in(1.0)
	locks.lock("kit_arrives")
	kit.walk([Vector3(-2.9, 0, 0.1)], _kit_arrived, 1.8)


func _kit_arrived() -> void:
	locks.unlock("kit_arrives")
	say("c3_open", func() -> void:
		mark("kitArrived")
		set_stage(GO_WITH_KIT)
		_kit_leads())


## Kit goes on ahead, up the second stair, and waits inside the workshop door.
func _kit_leads() -> void:
	var kit: Resident = world.residents.kit
	kit.walk([Vector3(1.0, 0, 0.2), world.refs.stairsCUp], func() -> void:
		kit.fade("out", func() -> void:
			kit.set_carrying(false)
			kit.place_at(world.refs.workshopDoor + Vector3(-0.6, 0, 0.3))
			kit.facing = Vector3(1, 0, 0)
			kit.fade("in")))


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
	talk("grandfather", 1.5, func() -> void: say("c3_grandfather"))
	talk("mum", 1.4, func() -> void: say("c3_mum"))
	talk("kit", 1.5, _talk_kit)
	talk("chiu", 1.6, _talk_chiu)
	talk("fanman", 1.6, _talk_ho)
	talk("ng", 1.9, _talk_ng)
	talk("chan", 1.9, _talk_chan)
	talk("son", 1.6, _talk_wai)
	talk("hand_a", 1.4, func() -> void: say("c3_hand_a"))
	talk("hand_b", 1.4, func() -> void: say("c3_hand_b"))
	talk("porter", 1.4, func() -> void: say("c3_porter"))
	talk("lau", 2.0, func() -> void: say("c3_lau"))
	talk("wong", 1.9, func() -> void: say("c3_wong"))
	talk("shopkeeper", 2.2, func() -> void: say("c3_kwok"))
	talk("chopper", 1.8, func() -> void: say("c3_chopper"))
	talk("mahjong2", 1.9, func() -> void: say("c3_mahjong"))
	talk("worker", 1.5, func() -> void: say("c3_worker"))
	talk("child", 1.5, func() -> void: say("c3_child"))


func _talk_kit() -> void:
	match stage:
		GO_WITH_KIT, LOADING_ROUTE:
			say("c3_kit_come")
		FIND_PARTS:
			say("c3_kit_parts")
		SET_UP:
			if _route_ready():
				_start_run()
			else:
				say("c3_kit_parts" if not _has_parts() else "c3_kit_not_yet")
		FINAL_CRATE:
			_final_crate()
		KIT_LATER:
			_kit_key()
		_:
			say("c3_kit_idle")


func _talk_chiu() -> void:
	if (stage == GO_WITH_KIT or stage == LOADING_ROUTE) and not _seen.has("c3_chiu"):
		_meet_chiu()
	elif stage == FINAL_CRATE:
		_final_crate()
	elif stage >= PHOTO_WORKERS:
		say("c3_chiu_after")
	else:
		say("c3_chiu_up")


func _meet_chiu() -> void:
	_seen["c3_chiu"] = true
	mark("chiuMet")
	say("c3_chiu", func() -> void:
		if stage < LOADING_ROUTE:
			set_stage(FIND_PARTS if flags.factory_route_pulley_found else LOADING_ROUTE))


func _talk_ho() -> void:
	if flags.pulley_safe:
		say("c3_ho_after")
	elif stage >= FIND_PARTS and flags.factory_route_pulley_found:
		say("c3_ho_pulley", func() -> void:
			flags.pulley_safe = true
			_parts_changed("notice.c3_pulley_safe"))
	else:
		say("c3_ho_early")


func _talk_ng() -> void:
	if flags.story_item_rope:
		say("c3_ng_after")
	elif stage >= FIND_PARTS and flags.factory_route_pulley_found:
		say("c3_ng_rope", func() -> void:
			flags.story_item_rope = true
			_parts_changed("notice.c3_rope"))
	else:
		say("c3_ng")


func _talk_chan() -> void:
	if flags.story_item_plank:
		say("c3_chan_after")
	elif stage >= FIND_PARTS and flags.factory_route_pulley_found:
		_plank_scene()
	else:
		say("c3_chan")


func _talk_wai() -> void:
	if flags.story_item_plank and not flags.oq05_asked:
		flags.oq05_asked = true
		mark("oq05Asked")
		say("c3_wai_shortcut", func() -> void:
			# off he goes, to wait on the roof
			_pose(world.residents.son, Vector3(-6.4, LevelBuilder.LEVEL_ROOF, -7.8), Vector3(-0.3, 0, 1), "idle")
			_refresh_hint())
	elif flags.oq05_done:
		say("c3_wai_race_after")
	elif flags.oq05_asked:
		say("c3_wai_waiting")
	elif flags.story_item_plank:
		say("c3_wai_after")
	elif flags.factory_route_pulley_found:
		_plank_scene()
	else:
		say("c3_wai")


# ----------------------------------------------------------------------------- OQ05, Wai's shortcut


func _register_shortcut() -> void:
	var I := interaction
	var refs := world.refs
	var Q := InteractionDirector.Priority.QUEST
	var steps := [
		["shortcutStair", refs.shortcutStairTop, "verb.downstairs", "oq05_stair", refs.shortcutStairFoot],
		["shortcutStairBack", refs.shortcutStairFoot, "verb.upstairs", "oq05_stair", refs.shortcutStairTop],
		["rearLadderUp", refs.rearLadderFoot, "verb.climb", "oq05_ladder", refs.rearBalcony],
		["rearLadderDown", refs.rearBalcony, "verb.climb_down", "oq05_ladder", refs.rearLadderFoot],
		["waiBridgeBack", refs.waiBridgeTop, "verb.cross", "oq05_bridge", refs.waiBridgeFoot],
	]
	for st in steps:
		var flag: String = st[3]
		var to: Vector3 = st[4]
		I.add({"id": st[0], "position": st[1], "radius": 0.8, "priority": Q, "verb": st[2],
			"can_interact": func() -> bool: return flags[flag],
			"interact": func() -> void:
				audio.creak()
				transition(to, 6)})
	I.add({"id": "waiBridge", "position": refs.waiBridgeFoot, "radius": 0.7, "priority": Q, "verb": "verb.cross",
		"can_interact": func() -> bool: return flags.oq05_bridge,
		"interact": func() -> void:
			audio.creak()
			transition(refs.waiBridgeTop, 6, _over_the_planks)})


## Up the planks onto the roof, and there's Wai.
func _over_the_planks() -> void:
	on_enter_roof()
	if flags.oq05_asked and not flags.oq05_done:
		flags.oq05_done = true
		mark("oq05Done")
		say("c3_wai_race", _refresh_hint)


## The three things seen by turning: the steps, the ladder, the planks.
func _shortcut_discover() -> void:
	if flags.oq05_bridge or cam.rotating or locks.is_locked() or dialogue.is_open():
		return
	var p := player.position
	var side := cam.direction == 1 or cam.direction == 3
	if not flags.oq05_stair and absf(p.y - BuildWorkshop.ROOF_Y) < 0.4 and p.x < -4.6 and p.z < 1.8 and side:
		flags.oq05_stair = true
		mark("oq05Stair")
		audio.chime()
		if flags.oq05_asked:
			say("c3_short_stair")
	elif flags.oq05_stair and not flags.oq05_ladder and absf(p.y - BuildSideQuests.LOW_Y) < 0.4 and p.z < 0.0 and cam.direction == 2:
		flags.oq05_ladder = true
		mark("oq05Ladder")
		audio.chime()
		if flags.oq05_asked:
			say("c3_short_ladder")
	elif flags.oq05_ladder and not flags.oq05_bridge and absf(p.y - BuildSideQuests.REAR_Y) < 0.4 and side:
		flags.oq05_bridge = true
		mark("oq05Bridge")
		audio.chime()
		if flags.oq05_asked:
			say("c3_short_bridge")


func _plank_scene() -> void:
	say("c3_plank", func() -> void:
		flags.story_item_plank = true
		_sync_world()
		_parts_changed("notice.c3_plank"))


## Rope, plank, and the pulley passed: the route can be set up.
func _parts_changed(notice_key: String) -> void:
	hud.notice(notice_key, 3.0)
	_sync_world()
	if _has_parts() and stage == FIND_PARTS:
		set_stage(SET_UP)


func _has_parts() -> bool:
	return flags.story_item_rope and flags.story_item_plank and flags.pulley_safe


func _route_ready() -> bool:
	return flags.plank_laid and flags.sign_folded and flags.rope_rigged


# ----------------------------------------------------------------------------- the loading route


func _register_route() -> void:
	var I := interaction
	var refs := world.refs
	var Q := InteractionDirector.Priority.QUEST
	# up the ladder through the hatch, and back down
	I.add({"id": "ladderUp", "position": refs.ladderBase, "radius": 0.9, "priority": Q, "verb": "verb.climb",
		"can_interact": func() -> bool: return stage >= LOADING_ROUTE,
		"interact": func() -> void:
			audio.creak()
			_kit_heads_for_ladder()
			transition(refs.hatchTop, 6, _reached_workshop_roof)})
	I.add({"id": "ladderDown", "position": refs.hatchTop, "radius": 0.8, "priority": Q, "verb": "verb.climb_down",
		"interact": func() -> void:
			audio.creak()
			transition(refs.ladderBase + Vector3(0.3, 0, 0.6), 6)})
	# the plank across the slot
	I.add({"id": "plankGap", "position": refs.plankGap, "radius": 1.0, "priority": Q,
		"verb": func() -> String: return "verb.lay_plank" if flags.story_item_plank else "verb.look",
		"can_interact": func() -> bool: return not flags.plank_laid,
		"interact": func() -> void:
			if flags.story_item_plank and flags.pulley_safe:
				audio.play("crate_down", 0.7)
				_lay_plank()
				say("c3_plank_laid", _sync_world)
			else:
				say("c3_gap")})
	# the signboard in the way: its hinges are round the back
	var sign_at := Vector3(BuildWorkshop.SIGN_X + 0.45, BuildWorkshop.ROOF_Y, 6.5)
	I.add({"id": "signboard", "position": sign_at, "radius": 0.9, "priority": Q,
		"verb": func() -> String: return "verb.fold" if stage >= SET_UP and flags.sign_hinges_seen else "verb.look",
		"can_interact": func() -> bool: return not flags.sign_folded,
		"interact": func() -> void:
			if stage >= SET_UP and flags.sign_hinges_seen:
				audio.creak()
				_fold_sign(false)
				say("c3_sign_folded")
			else:
				say("c3_sign")})
	# the rope, through the pulley and down to the platform
	I.add({"id": "winch", "position": refs.winch, "radius": 1.0, "priority": Q,
		"verb": func() -> String: return "verb.rig_rope" if flags.story_item_rope and not flags.rope_rigged else "verb.look",
		"can_interact": func() -> bool: return not flags.rope_rigged or stage >= SET_UP,
		"interact": func() -> void:
			if flags.story_item_rope and flags.pulley_safe and not flags.rope_rigged:
				audio.play("ratchet", 0.6)
				_rig_rope()
				say("c3_rope_rigged")
			elif flags.rope_rigged:
				_talk_kit()
			else:
				say("c3_winch")})


## Mei goes first. Kit crosses the workshop while the screen is down, then
## climbs out of the same hatch a beat after Mei reaches the roof. Keeping this
## independent of the pulley discovery prevents a camera turn from spawning her.
func _kit_heads_for_ladder() -> void:
	var kit: Resident = world.residents.kit
	var R := BuildWorkshop.ROOF_Y
	if _kit_following_ladder or _kit_on_roof or absf(kit.position.y - R) < 0.4:
		_kit_on_roof = true
		return
	_kit_following_ladder = true
	kit.ghost = true
	kit.walk([world.refs.ladderBase + Vector3(0.32, 0, 0.0)], func() -> void:
		kit.fade("out"), 2.0)


func _reached_workshop_roof() -> void:
	mark("onWorkshopRoof")
	if _kit_following_ladder:
		later(_kit_climbs_out, 0.8)


func _kit_climbs_out() -> void:
	if not _kit_following_ladder:
		return
	var kit: Resident = world.residents.kit
	var R := BuildWorkshop.ROOF_Y
	# Start below the roof slab so the hatch masks her lower half as she rises.
	kit.place_at(Vector3(-1.8, R - 0.9, 0.72))
	kit.idle_anim = "idle"
	kit.ghost = true
	kit.fade("in")
	kit.walk([
		Vector3(-1.8, R, 0.72),
		Vector3(-4.8, R, 1.2),
	], func() -> void:
		kit.ghost = false
		kit.facing = Vector3(0, 0, 1)
		kit.sprite.facing = kit.facing
		_kit_following_ladder = false
		_kit_on_roof = true, 1.8)


func _lay_plank() -> void:
	if flags.plank_laid:
		return
	flags.plank_laid = true
	world.open_ways["plank"] = true
	_plank = Node3D.new()
	_plank.name = "TransferPlank"
	world.level.add_child(_plank)
	var R := BuildWorkshop.ROOF_Y
	var px: Array = BuildWorkshop.PLANK_X
	var sz: Array = BuildWorkshop.SLOT_Z
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(float(px[1]) - float(px[0]) - 0.2, 0.06, float(sz[1]) - float(sz[0]) + 0.5)
	mi.mesh = bm
	mi.material_override = SurfaceLibrary.get_material("wood")
	mi.set_instance_shader_parameter("tint", Color("8a6a48"))
	_plank.add_child(mi)
	mi.position = Vector3((float(px[0]) + float(px[1])) / 2, R - 0.03, (float(sz[0]) + float(sz[1])) / 2)


func _fold_sign(instant: bool) -> void:
	if flags.sign_folded:
		return
	flags.sign_folded = true
	world.open_ways["sign"] = true
	_sync_world()
	var sign: Node3D = world.level.get_node("Special/Signboard")
	if instant:
		sign.rotation.y = -PI / 2
	else:
		create_tween().tween_property(sign, "rotation:y", -PI / 2, 1.4).set_trans(Tween.TRANS_SINE)


func _rig_rope() -> void:
	if flags.rope_rigged:
		return
	flags.rope_rigged = true
	_sync_world()
	var platform: Node3D = world.level.get_node("Special/LoadingPlatform")
	for child in platform.get_children():
		if child.name.begins_with("Chain"):
			child.visible = true
	_rope = Node3D.new()
	_rope.name = "RigRope"
	world.level.add_child(_rope)
	var pulley: Vector3 = world.refs.pulley
	var drum := Vector3(BuildWorkshop.PLATFORM.x, BuildWorkshop.ROOF_Y + 0.95, 6.55)
	_rope_segment(drum, pulley + Vector3(0, 0.1, 0.12))
	_rope_down = _rope_segment(pulley, platform.global_position + Vector3(0, 1.2, 0))
	# Tensioning the newly fitted rope draws the parked platform off the roof and
	# into its working position over the slot.  Keep the rope attached throughout.
	var parked := platform.global_position
	var move := create_tween()
	move.tween_method(func(t: float) -> void:
		platform.global_position = parked.lerp(BuildWorkshop.PLATFORM, t)
		_stretch(_rope_down, pulley, platform.global_position + Vector3(0, 1.2, 0)), 0.0, 1.0, 1.1
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# the coil of what's left over, hung on the gallows post
	var coil := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.1
	tm.outer_radius = 0.16
	coil.mesh = tm
	coil.material_override = _rope_material()
	_rope.add_child(coil)
	coil.global_position = drum + Vector3(0.0, 0.45, -0.1)
	coil.rotation.x = PI / 2


## Mr. Ng's rope: thick enough to read from the camera, pale against the concrete.
func _rope_segment(a: Vector3, b: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.032
	cm.bottom_radius = 0.032
	cm.height = 1.0
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = _rope_material()
	_rope.add_child(mi)
	_stretch(mi, a, b)
	return mi


func _stretch(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var y := b - a
	var len := maxf(y.length(), 0.01)
	y = y / len
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	mi.global_transform = Transform3D(Basis(x, y * len, x.cross(y)), (a + b) * 0.5)


func _rope_material() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("e0cf9a")
	m.roughness = 0.9
	return m


# ----------------------------------------------------------------------------- the last crate going down


func _start_run() -> void:
	say("c3_run", func() -> void:
		mark("crateRun")
		set_stage(RUN_CRATE)
		locks.lock("crate")
		_mei_steps_clear_of_winch()
		_kit_walks_to_winch()
		_begin_crate())


## Give the pulley operator a readable silhouette. If Mei starts the run from
## the winch prompt, she takes a couple of natural steps along the balcony so
## she cannot stand directly over Kit's cranking animation. When she starts it
## by speaking to Kit at the hatch, she instead steps back on the workshop roof.
func _mei_steps_clear_of_winch() -> void:
	var R := BuildWorkshop.ROOF_Y
	var target: Vector3
	if player.position.z >= float(BuildWorkshop.SLOT_Z[1]):
		target = world.refs.winch + Vector3(1.25, 0, 0.3)
	else:
		target = Vector3(-4.15, R, 0.85)
	player.traverse([target], 1.8, Callable(), false)


## Kit only crosses the roof once the run has begun. This keeps her out of
## Mei's way while the player is rigging and inspecting the winch.
func _kit_walks_to_winch() -> void:
	var kit: Resident = world.residents.kit
	var R := BuildWorkshop.ROOF_Y
	var px := (float(BuildWorkshop.PLANK_X[0]) + float(BuildWorkshop.PLANK_X[1])) / 2.0
	kit.ghost = true
	kit.walk([
		Vector3(px, R, 3.6),
		Vector3(px, R, 6.5),
		world.refs.winch,
	], func() -> void:
		kit.ghost = false
		kit.facing = Vector3(-1, 0, 0)
		kit.sprite.facing = kit.facing
		kit.idle_anim = "work"
		kit.sprite.play("work"), 1.8)


## The last crate is thrown up through the hatch. Ho collects it, carries it
## across the workshop roof to the near edge of the slot, then reaches it onto
## the platform. He never crosses to Kit's cramped pulley-side ledge. Only the
## suspended platform moves by itself after that, pulled by Kit's winch.
func _begin_crate() -> void:
	var R := BuildWorkshop.ROOF_Y
	var hatch := Vector3(-1.8, R, 0.62)
	_crate = Node3D.new()
	_crate.name = "LastCrate"
	world.level.add_child(_crate)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.44, 0.32, 0.46)
	body.mesh = bm
	body.material_override = SurfaceLibrary.get_material("grain")
	body.set_instance_shader_parameter("tint", Color("3f6fa8"))
	body.position = Vector3(0, 0.16, 0)
	_crate.add_child(body)
	_crate.global_position = hatch + Vector3(0.15, -1.0, -0.18)
	_start_crate_motion([
		{"to": hatch + Vector3(-0.15, 0, 0.58), "secs": 0.85, "sound": "", "arc": 0.58},
	], _ho_collects_crate)


func _start_crate_motion(legs: Array, on_done: Callable) -> void:
	_run = {"legs": legs, "i": 0, "t": 0.0, "from": _crate.global_position, "on_done": on_done}


func _ho_collects_crate() -> void:
	audio.play_at("crate_down", _crate.global_position, 18.0, 0.8)
	var ho: Resident = world.residents.fanman
	ho.ghost = true
	ho.walk([_crate.global_position], _ho_picks_up_crate, 2.0)


func _ho_picks_up_crate() -> void:
	var R := BuildWorkshop.ROOF_Y
	var plat: Vector3 = BuildWorkshop.PLATFORM
	var ho: Resident = world.residents.fanman
	ho.set_carrying(true)
	_crate_carrier = ho
	# Ho stays on the workshop side and approaches the platform from the circled
	# loading edge. Kit alone crosses the plank to operate the remote winch.
	ho.walk([
		Vector3(-4.4, R, 2.8),
		Vector3(plat.x, R, float(BuildWorkshop.SLOT_Z[0]) - 0.35),
	], _ho_places_crate, 1.8)


func _ho_places_crate() -> void:
	var ho: Resident = world.residents.fanman
	_crate_carrier = null
	ho.set_carrying(false)
	ho.ghost = false
	ho.facing = Vector3(0, 0, 1)
	ho.sprite.facing = ho.facing
	_start_crate_motion([
		{"to": BuildWorkshop.PLATFORM, "secs": 0.55, "sound": "crate_down"},
	], _lower_loaded_platform)


func _lower_loaded_platform() -> void:
	var plat: Vector3 = BuildWorkshop.PLATFORM
	_start_crate_motion([
		{"to": Vector3(plat.x, 0.05, plat.z), "secs": 5.0, "sound": "ratchet", "platform": true},
	], _crate_landed)


func _tick_crate(delta: float) -> void:
	if _run.is_empty():
		return
	var legs: Array = _run.legs
	var leg: Dictionary = legs[_run.i]
	if _run.t == 0.0 and leg.sound != "":
		audio.play_at(leg.sound, leg.to, 20.0, 0.9)
	_run.t = float(_run.t) + delta / float(leg.secs)
	var t := minf(1.0, float(_run.t))
	var at: Vector3 = (_run.from as Vector3).lerp(leg.to, t * t * (3.0 - 2.0 * t))
	if float(leg.get("arc", 0.0)) > 0.0:
		at.y += sin(t * PI) * float(leg.arc)
	_crate.global_position = at
	if leg.get("platform", false):
		var plat: Node3D = world.level.get_node("Special/LoadingPlatform")
		plat.global_position = at
		if _rope_down:
			_stretch(_rope_down, world.refs.pulley, at + Vector3(0, 1.2, 0))
	if t >= 1.0:
		_run.from = leg.to
		_run.i = int(_run.i) + 1
		_run.t = 0.0
		if int(_run.i) >= legs.size():
			var on_done: Callable = _run.get("on_done", Callable())
			_run = {}
			if on_done.is_valid():
				on_done.call()


func _crate_landed() -> void:
	audio.play_at("crate_down", world.refs.platformBottom, 30.0, 1.0)
	flags.crate_down = true
	locks.unlock("crate")
	mark("crateDown")
	say("c3_crate_down", func() -> void: set_stage(FINAL_CRATE))


func _final_crate() -> void:
	if flags.chiu_scene:
		say("c3_chiu_after")
		return
	say("c3_final", func() -> void:
		flags.chiu_scene = true
		if _crate:
			_crate.queue_free()
			_crate = null
		set_stage(PHOTO_WORKERS))


func _kit_key() -> void:
	say("c3_kit_key", func() -> void:
		flags.setup_kit_address = true
		flags.setup_mei_fears_disconnection = true
		mark("kitKey")
		later(_ending, 1.8))


func _on_photo_kept(id: String) -> void:
	await scrapbook.file_photo(id)
	if id == "chiu":
		say("c3_chiu_photo", func() -> void: set_stage(KIT_LATER))


# ----------------------------------------------------------------------------- seeing it


## From the roof the neighbours' side is between the camera and Mei, so it is
## cut away; looking back from the south shows the pulley over their balcony.
## On the balcony, the sign's hinges show only from the west.
func _discover() -> void:
	if cam.rotating or locks.is_locked() or dialogue.is_open():
		return
	var p := player.position
	var R := BuildWorkshop.ROOF_Y
	var on_roof := absf(p.y - R) < 0.4 and p.z < 4.05 and p.x > -7.1 and p.x < 0.1
	if not flags.factory_route_pulley_found and stage <= LOADING_ROUTE and on_roof and cam.direction == 2:
		flags.factory_route_pulley_found = true
		audio.chime()
		if stage == LOADING_ROUTE:
			say("c3_pulley_found", func() -> void: set_stage(FIND_PARTS))
		return
	var on_balcony := absf(p.y - R) < 0.4 and p.z > 5.9 and p.x > BuildWorkshop.SIGN_X
	if not flags.sign_hinges_seen and on_balcony \
			and ViewMath.back(cam.current_yaw).dot(Vector3(-1, 0, 0)) > 0.6:
		flags.sign_hinges_seen = true
		audio.chime()
		hud.notice("notice.c3_hinges", 3.4)


func _tick_hints() -> void:
	if dialogue.is_open() or locks.is_locked():
		return
	var p := player.position
	var on_roof := absf(p.y - BuildWorkshop.ROOF_Y) < 0.4 and p.z < 4.05
	if stage == LOADING_ROUTE and on_roof:
		_hinted["roof_t"] = float(_hinted.get("roof_t", 0.0)) + get_process_delta_time()
		if float(_hinted.roof_t) > 20.0 and not _hinted.has("turn"):
			_hinted["turn"] = true
			say("c3_hint_look_back", func() -> void: hud.show_hint("hint.turn_view"))
	if stage == SET_UP and _stage_t > 120.0 and not _hinted.has("setup"):
		_hinted["setup"] = true
		say("c3_hint_setup")


# ----------------------------------------------------------------------------- sounds


func _register_sounds() -> void:
	var B := LevelBuilder.LEVEL_B
	var work := Vector3(-4.6, B, 2.0)
	# the pounding, heard downstairs through the floor, until the last crate goes
	audio.add_shots("thump", ["thump_0", "thump_1", "thump_2"], work, 18.0, B, [0.45, 0.8], 0.9,
		func() -> bool: return not flags.crate_down)
	audio.add_loop("steam", "steam_loop", world.refs.steamer, 7.0, B, 0.5)


# ----------------------------------------------------------------------------- the end of the day


func _ending() -> void:
	if stage == COMPLETE:
		return
	set_stage(COMPLETE)
	mark("ending")
	locks.lock("ending")
	hud.set_quiet(true)
	audio.silence(3.2)
	await fade.fade_out(3.0)
	slice.ending.play(DAYS_LEFT, "ending.ch3", Progress.LAST > 3)


# ----------------------------------------------------------------------------- per frame


func tick(delta: float, paused: bool) -> void:
	_run_tasks(delta, paused)
	if paused:
		return
	_stage_t += delta
	_refresh_hint()
	if _crate_carrier and _crate:
		var carry_forward := _crate_carrier.sprite.facing
		carry_forward.y = 0
		_crate.global_position = _crate_carrier.global_position + Vector3(0, 0.66, 0) + carry_forward.normalized() * 0.22
	_tick_crate(delta)
	_discover()
	_shortcut_discover()
	_tick_hints()
	# walking into the workshop: Uncle Chiu
	var p := player.position
	if stage == GO_WITH_KIT and absf(p.y - LevelBuilder.LEVEL_B) < 0.5 and p.x < -0.3 and p.z > 0.0 and p.z < 4.0 \
			and not locks.is_locked() and not dialogue.is_open():
		_meet_chiu()
	if _hinted.get("turn") == true and flags.factory_route_pulley_found:
		_hinted["turn"] = false
		hud.show_hint("")
