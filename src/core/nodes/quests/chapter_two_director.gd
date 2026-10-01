class_name ChapterTwoDirector
extends ChapterDirector

## Chapter 2, The Water Line. 24 days until we leave.
##
## The pump labours and the flat has no water. Mr. Ho, listening to the pipe in
## the hall, says follow the blue branch until it stops being blue. It leaves the
## landing beside an old dead line and crosses the light well; turning the view
## shows which is which (the one that knocks with the pump), and then that it
## runs on behind the air-conditioners, past Mrs. Fong's tap, into the flat next
## door, whose family has already gone. Its door is chained; its back kitchen
## window only shows from the side. Inside, three valves: one floods a
## neighbour, one coughs rust into the old sink, one brings the water back.
## The walk home is heard filling up, and at home Mum is washing the red bowl.
## The day doesn't stop there: the kettle goes on at last, Mum brings
## Grandfather his tea, and Mei sits with him a while before it ends.
##
## Nothing is solved by the view turning; turning only shows what was there.
##
## On the side, two small things. OQ01, Mr. Kwok's Back Page: the wind had it
## out over the light well; from the catwalk it lies on an awning out of
## reach, but from the side it's on the little balcony under the awning, off
## a door halfway up the stairs by Lau's. OQ04, The Last Mahjong Tile: the
## white dragon went down the crack at the foot of the alcove's wall; out in
## the lane, only a side view shows it behind the crates, where the crack
## comes out.

enum {
	START,
	FIND_HO,
	TRACE,
	TRACED_BRANCH,
	TRACED_WELL,
	IN_UNIT,
	WATER_BACK,
	PHOTO_HO,
	GO_HOME,
	TEA,
	COMPLETE,
}

const NAMES := ["START", "FIND_HO", "TRACE", "TRACED_BRANCH", "TRACED_WELL", "IN_UNIT", "WATER_BACK", "PHOTO_HO", "GO_HOME", "TEA", "COMPLETE"]

## [objective, hint] as string keys
const OBJECTIVES := {
	FIND_HO: ["c2.obj.find_ho", "c2.obj.find_ho.hint"],
	TRACE: ["c2.obj.trace", "c2.obj.trace.hint"],
	TRACED_BRANCH: ["c2.obj.trace", "c2.obj.branch.hint"],
	TRACED_WELL: ["c2.obj.trace", "c2.obj.well.hint"],
	IN_UNIT: ["c2.obj.valve", "c2.obj.valve.hint"],
	WATER_BACK: ["c2.obj.tell_ho", "c2.obj.tell_ho.hint"],
	PHOTO_HO: ["c2.obj.photo_ho", "c2.obj.photo_ho.hint"],
	GO_HOME: ["c2.obj.home", ""],
	TEA: ["c2.obj.tea", ""],
}

const DAYS_LEFT := 24
const PUMP_CYCLE := 7.0          # seconds between the pump's attempts

var flags := {
	"setup_red_bowl": false, "water_trace_1": false, "water_trace_2": false, "window_found": false,
	"valve_neighbour": false, "valve_sink": false, "water_restored": false, "ho_restored_talk": false,
	"mum_after": false, "brochure_seen": false, "tea_served": false,
	"oq01_asked": false, "oq01_seen": false, "oq01_page": false, "oq01_done": false,
	"oq04_asked": false, "oq04_seen": false, "oq04_tile": false, "oq04_done": false,
}

var _stage_t := 0.0
var _pump_t := 2.0
var _pump_on := false
var _knock: Dictionary = {}
var _zone_t := 0.0
var _hinted: Dictionary = {}
var _window_t := 0.0
var _heard: Dictionary = {}
var _valve_busy := false
var _card: CanvasLayer
var _brown: MeshInstance3D
var _cup: Node3D

## where Mum brings the tea: the gap between the shelf and the table, at
## Grandfather's elbow; the cup goes down on the table's corner by him
const TEA_STAND := Vector3(-12.75, 0, -1.55)
const TEA_CUP := Vector3(-12.0, 0.8, -0.35)


func setup() -> void:
	_bind()
	_prepare_world()
	_register_shared()
	_register_people()
	_register_puzzle()
	_register_side()
	_register_sounds()
	photography.add_target("ho", world.residents.fanman, func() -> bool: return stage == PHOTO_HO and not scrapbook.entries.has("ho"))
	photography.photo_kept.connect(_on_photo_kept)
	dialogue.event_fired.connect(_on_dialogue_event)
	photography.has_camera = true
	# the prints she kept yesterday come with her
	for id in ["lau", "ng"]:
		scrapbook.add(id)
		if Progress.carried_photos.has(id):
			photography.photos[id] = Progress.carried_photos[id]
		else:
			_reshoot(id)
	flags.setup_red_bowl = true
	Progress.reach(2)


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
	hint = _with_side(o[1])
	hud.set_objective(objective, hint)
	_sync_world()


## The stage's hint, and under it whatever Mei has taken on for the neighbours.
func _with_side(base: String) -> String:
	var lines: Array[String] = []
	if base != "":
		lines.append(tr(base))
	if flags.oq01_asked and not flags.oq01_done:
		lines.append(tr("c2.need.page_back" if flags.oq01_page else ("c2.need.page_seen" if flags.oq01_seen else "c2.need.page")))
	if flags.oq04_asked and not flags.oq04_done:
		lines.append(tr("c2.need.tile_back" if flags.oq04_tile else "c2.need.tile"))
	return "\n".join(lines) if lines.size() > 1 else base


func _refresh_side() -> void:
	var o: Array = OBJECTIVES.get(stage, ["", ""])
	hint = _with_side(o[1])
	hud.set_objective(objective, hint)


func force_stage(s: int) -> void:
	s = clampi(s, START, COMPLETE)
	flags.water_trace_1 = s >= TRACED_BRANCH
	flags.water_trace_2 = s >= TRACED_WELL
	flags.window_found = s >= IN_UNIT
	flags.water_restored = s >= WATER_BACK
	flags.ho_restored_talk = s >= PHOTO_HO
	flags.mum_after = s >= TEA
	set_stage(s)
	if s >= TEA:
		_serve_tea(true)


# ----------------------------------------------------------------------------- the world on this day


## Yesterday's end: the service door open, the crate under the ladder, the
## washing on the roof, the pigeon home. Mum packing dishes.
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
	var son: Resident = world.residents.son
	son.place_at(Vector3(-4.4, LevelBuilder.LEVEL_ROOF, -9.6))
	son.facing = Vector3(0.6, 0, -1)
	var mum: Resident = world.residents.mum
	mum.place_at(Vector3(-10.05, 0, -2.4))
	mum.facing = Vector3(0, 0, -1)
	mum.idle_anim = "work"
	_sync_world()


func _sync_world() -> void:
	var ho: Resident = world.residents.fanman
	var mum: Resident = world.residents.mum
	var bowl: Node3D = world.level.get_node_or_null("ChapterProps/Ch2-4/RedBowl")
	if stage < WATER_BACK:
		# up on his stool in the hall, a screwdriver to the blue pipe
		_pose(ho, world.refs.hoListen, Vector3(-1, 0, -0.25), "listen")
	else:
		# washing the grease off his hands at the bucket by the door
		_pose(ho, world.refs.hoWash, Vector3(-0.6, 0, 0.8), "wash")
	if stage >= WATER_BACK and stage < TEA:
		# water again: Mum at the tap, the red bowl in her hands
		_pose(mum, world.refs.redBowl, Vector3(0, 0, -1), "wash")
		if bowl:
			bowl.visible = false


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
	# the day's title over black, then the flat with no water in it
	fade.set_black(true)
	_card = CanvasLayer.new()
	_card.layer = 50
	add_child(_card)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	_card.add_child(col)
	for spec in [["c2.card.number", UIStyle.FONT_MONO, 15, UIStyle.CONCRETE_DIM], ["c2.card.title", UIStyle.FONT_UI_BOLD, 40, UIStyle.CONCRETE]]:
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
	_card.queue_free()
	await fade.fade_in(1.2)
	say("c2_cold_open", func() -> void:
		mark("coldOpen")
		set_stage(FIND_HO))


func _on_dialogue_event(e: String) -> void:
	match e:
		"pumpStart":
			audio.play("pump_start", 0.7)
		"pumpStop":
			audio.play("pump_stall", 0.7)
		"splash":
			audio.play("splash", 0.8)
		"sinkCough":
			audio.play("sink_cough", 0.9)
			_brown_water(true)
		"waterRush":
			audio.play("valve", 0.7)
			audio.play("water_rush", 0.9, 1.0, 0.5)
			audio.play("knock_0", 0.9, 0.9, 0.2)
			audio.play("knock_2", 0.8, 1.0, 0.9)


# ----------------------------------------------------------------------------- people


func _register_people() -> void:
	talk("grandfather", 1.5, func() -> void:
		if stage == TEA and flags.tea_served:
			_tea_with_grandfather()
		elif stage >= WATER_BACK:
			say("c2_grandfather_after")
		else:
			say("c2_grandfather_idle"))

	talk("mum", 1.4, func() -> void:
		if stage == TEA:
			say("c2_mum_tea")
		elif stage >= GO_HOME:
			_mum_after()
		elif stage >= WATER_BACK:
			say("c2_mum_water")
		else:
			say("c2_mum_idle"))

	talk("fanman", 1.6, _talk_ho)

	talk("chan", 1.9, func() -> void: say("c2_chan_wet" if flags.water_restored else "c2_chan_dry"))
	talk("son", 1.6, func() -> void: say("c2_wai"))
	talk("ng", 1.9, func() -> void: say("c2_ng"))
	talk("lau", 2.0, func() -> void: say("c2_lau"))
	talk("wong", 1.9, func() -> void: say("c2_wong"))
	talk("shopkeeper", 2.2, _talk_kwok)
	talk("chopper", 1.8, func() -> void: say("c2_chopper_wet" if flags.water_restored else "c2_chopper"))
	talk("mahjong2", 1.9, _talk_mahjong)
	talk("worker", 1.5, func() -> void: say("c2_worker"))
	talk("child", 1.5, func() -> void: say("c2_child_wet" if flags.water_restored else "c2_child"))


# ----------------------------------------------------------------------------- on the side


func _talk_kwok() -> void:
	if flags.oq01_done:
		say("c2_kwok_after")
	elif flags.oq01_page:
		flags.oq01_done = true
		mark("oq01Done")
		say("c2_kwok_page_back", _refresh_side)
	elif flags.oq01_asked:
		say("c2_kwok_page_wait")
	elif stage >= TRACE:
		flags.oq01_asked = true
		mark("oq01Asked")
		say("c2_kwok_page", _refresh_side)
	else:
		say("c2_kwok")


func _talk_mahjong() -> void:
	if flags.oq04_done:
		say("c2_tile_after")
	elif flags.oq04_tile:
		flags.oq04_done = true
		mark("oq04Done")
		say("c2_tile_back", _refresh_side)
	elif flags.oq04_asked:
		say("c2_tile_wait")
	elif stage >= TRACE:
		flags.oq04_asked = true
		mark("oq04Asked")
		say("c2_tile_lost", _refresh_side)
	else:
		say("c2_mahjong")


func _register_side() -> void:
	var I := interaction
	var refs := world.refs
	var Q := InteractionDirector.Priority.QUEST
	# OQ01: from the catwalk, the page on the awning; the door off the stairs; the page itself
	I.add({"id": "pageAwning", "position": refs.awningSeen, "radius": 1.6, "priority": InteractionDirector.Priority.ENV, "verb": "verb.look",
		"can_interact": func() -> bool: return flags.oq01_asked and not flags.oq01_seen,
		"interact": func() -> void: say("c2_page_awning")})
	# the door is halfway up the flight: Mei walks up to it
	I.add({"id": "wellBalconyDoor", "position": refs.wellBalconyDoor, "radius": 0.8, "priority": Q, "verb": "verb.stair_door",
		"can_interact": func() -> bool: return flags.oq01_seen,
		"interact": func() -> void:
			audio.creak()
			transition(refs.wellBalcony, 5)})
	I.add({"id": "wellBalconyBack", "position": refs.wellBalcony, "radius": 0.8, "priority": Q, "verb": "verb.door",
		"interact": func() -> void:
			audio.creak()
			# back on the tread she left from
			transition(refs.wellBalconyDoor, 5)})
	I.add({"id": "kwokPage", "position": refs.kwokPage, "radius": 0.9, "priority": Q, "verb": "verb.take",
		"can_interact": func() -> bool: return flags.oq01_asked and not flags.oq01_page,
		"interact": func() -> void:
			flags.oq01_page = true
			mark("oq01Page")
			set_gone(world.level.get_node_or_null("ChapterProps/Ch2/KwokPage"), true)
			say("c2_page_got", _refresh_side)})
	# OQ04: the crack in the alcove, and where it comes out in the lane
	I.add({"id": "tileCrack", "position": refs.tileCrack, "radius": 1.0, "priority": InteractionDirector.Priority.ENV, "verb": "verb.look",
		"can_interact": func() -> bool: return flags.oq04_asked and not flags.oq04_tile,
		"interact": func() -> void: say("c2_tile_crack")})
	I.add({"id": "tileHole", "position": refs.tileHole, "radius": 1.0, "priority": Q, "verb": "verb.take",
		"can_interact": func() -> bool: return flags.oq04_seen and not flags.oq04_tile,
		"interact": func() -> void:
			flags.oq04_tile = true
			mark("oq04Tile")
			set_gone(world.level.get_node_or_null("ChapterProps/Ch2/LostTile"), true)
			say("c2_tile_got", _refresh_side)})


## Only a side view shows where the page really is, and where the crack comes out.
func _side_discover() -> void:
	if cam.rotating or locks.is_locked() or dialogue.is_open() or not (cam.direction == 1 or cam.direction == 3):
		return
	var at: Vector3 = world.refs.awningSeen
	if flags.oq01_asked and not flags.oq01_seen and mei_near(at.x, at.y, at.z, 2.6):
		flags.oq01_seen = true
		mark("oq01Seen")
		audio.chime()
		say("c2_page_seen", _refresh_side)
		return
	var p := player.position
	if flags.oq04_asked and not flags.oq04_seen and p.y < 1.0 and p.x > -4.6 and p.x < -1.0 and p.z > 4.3 and p.z < 6.0:
		flags.oq04_seen = true
		mark("oq04Seen")
		audio.chime()
		say("c2_tile_seen", _refresh_side)


func _talk_ho() -> void:
	if stage <= FIND_HO:
		mark("hoFound")
		say("c2_ho_find", func() -> void: set_stage(TRACE))
	elif stage < WATER_BACK:
		say("c2_ho_trace")
	elif stage == WATER_BACK:
		mark("hoTold")
		say("c2_ho_restored", _ho_told)
	elif stage == PHOTO_HO:
		say("c2_ho_pose")
	else:
		say("c2_ho_after")


func _ho_told() -> void:
	flags.ho_restored_talk = true
	set_stage(PHOTO_HO)


func _mum_after() -> void:
	if flags.mum_after:
		say("c2_mum_done")
		return
	say("c2_mum_after", func() -> void:
		flags.mum_after = true
		mark("mumAfter")
		set_stage(TEA)
		later(_kettle_on, 0.8))


## The first kettle of the day. Mum puts it on, and takes the tea over to
## Grandfather when it's made.
func _kettle_on() -> void:
	audio.play_at("kettle", Vector3(-8.8, 1.0, -3.7), 9.0, 0.8)
	var mum: Resident = world.residents.mum
	mum.idle_anim = "idle"
	mum.sprite.play("idle")
	later(_mum_brings_tea, 3.2)


func _mum_brings_tea() -> void:
	var mum: Resident = world.residents.mum
	mum.walk([Vector3(-10.4, 0, -1.75), TEA_STAND], _serve_tea.bind(false), 1.6)


func _serve_tea(instant: bool) -> void:
	if flags.tea_served and _cup:
		return
	flags.tea_served = true
	var mum: Resident = world.residents.mum
	if instant:
		mum.place_at(TEA_STAND)
	mum.home = TEA_STAND
	mum.facing = Vector3(0.3, 0, 1)
	mum.sprite.facing = mum.facing
	mum.idle_anim = "idle"
	mum.sprite.play("idle")
	_cup = Node3D.new()
	_cup.name = "TeaCup"
	world.level.add_child(_cup)
	_cup.position = TEA_CUP
	for spec in [[0.045, 0.07, 0.035, "e8e2d0"], [0.038, 0.004, 0.068, "8a5a2a"]]:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = spec[0]
		cm.bottom_radius = float(spec[0]) * 0.8
		cm.height = spec[1]
		cm.radial_segments = 12
		mi.mesh = cm
		mi.material_override = SurfaceLibrary.get_material("grain")
		mi.set_instance_shader_parameter("tint", Color(spec[3]))
		mi.position.y = spec[2]
		_cup.add_child(mi)
	if not instant:
		audio.play_at("knock_0", TEA_CUP, 4.0, 0.25, 2.2)


## Sitting with him. The last thing in the day, and then it's evening.
func _tea_with_grandfather() -> void:
	mark("tea")
	var gf: Resident = world.residents.grandfather
	gf.face_toward(slice.player.global_position, 30.0)
	say("c2_tea", _ending)


func _on_photo_kept(id: String) -> void:
	await scrapbook.file_photo(id)
	if id == "ho":
		say("c2_ho_photo", func() -> void: set_stage(GO_HOME))


# ----------------------------------------------------------------------------- the water line


func _register_puzzle() -> void:
	var I := interaction
	var refs := world.refs
	var Q := InteractionDirector.Priority.QUEST
	# the tap at home: dry, then running
	I.add({"id": "tap", "position": Vector3(-8.0, 0, -3.05), "radius": 0.8, "priority": Q, "verb": "verb.look",
		"interact": func() -> void: say("c2_tap_wet" if flags.water_restored else "c2_tap_dry")})
	# the brochure for the new estate, on the table
	I.add({"id": "brochure", "position": refs.brochure, "radius": 0.9, "priority": Q, "verb": "verb.look",
		"interact": func() -> void:
			flags.brochure_seen = true
			say("c2_brochure")})
	# the chained door: the notice, and the chain
	I.add({"id": "chainedDoor", "position": refs.chainedDoor, "radius": 1.0, "priority": Q, "verb": "verb.door",
		"interact": func() -> void: say("c2_chained")})
	# the back kitchen window: no prompt until she has actually seen it
	I.add({"id": "unitWindow", "position": refs.unitWindowOutside, "radius": 1.1, "priority": Q, "verb": "verb.climb_in",
		"can_interact": func() -> bool: return flags.window_found,
		"interact": func() -> void:
			audio.creak()
			once("c2_climb_in", func() -> void:
				transition(refs.unitInside, 5, func() -> void:
					mark("inUnit")
					if stage < IN_UNIT:
						set_stage(IN_UNIT)))})
	I.add({"id": "unitWindowIn", "position": refs.unitInside, "radius": 0.9, "priority": Q, "verb": "verb.climb_out",
		"interact": func() -> void:
			audio.creak()
			transition(refs.unitWindowOutside, 5)})
	# the valves
	var vz := BuildLightWell.MANIFOLD_Z + 0.45
	for i in 3:
		var vx: float = BuildLightWell.VALVE_X[i]
		I.add({"id": "valve%d" % i, "position": Vector3(vx, LevelBuilder.LEVEL_B, vz), "radius": 0.45, "priority": Q, "verb": "verb.turn",
			"can_interact": func() -> bool: return not _valve_busy and not flags.water_restored,
			"interact": func() -> void: _turn_valve(i)})


func _turn_valve(i: int) -> void:
	_valve_busy = true
	audio.play("valve", 0.8)
	if i == 0:
		# water let loose into the neighbour's shower upstairs
		var again: bool = flags.valve_neighbour
		flags.valve_neighbour = true
		say("c2_valve_neighbour_again" if again else "c2_valve_neighbour", _valve_back)
	elif i == 1:
		# the old sink coughs up rust
		flags.valve_sink = true
		say("c2_valve_sink", func() -> void: later(_sink_drained, 1.2))
	else:
		say("c2_valve_right", _water_back)


func _valve_back() -> void:
	audio.play("valve", 0.5, 0.9)
	_valve_busy = false


func _water_back() -> void:
	flags.water_restored = true
	_valve_busy = false
	mark("waterBack")
	set_stage(WATER_BACK)


func _sink_drained() -> void:
	_brown_water(false)
	audio.play("valve", 0.5, 0.9)
	_valve_busy = false


## Rust-brown water standing in the old sink, and draining away again.
func _brown_water(on: bool) -> void:
	if on and _brown == null:
		_brown = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.42, 0.02, 0.4)
		_brown.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("5a3a1e")
		m.roughness = 0.15
		_brown.material_override = m
		world.level.add_child(_brown)
		_brown.global_position = world.refs.unitSink + Vector3(0, 0.03, 0)
	elif not on and _brown:
		var dead := _brown
		_brown = null
		var tw := create_tween()
		tw.tween_property(dead, "scale", Vector3(1, 0.05, 1), 1.0)
		tw.tween_callback(dead.queue_free)


# ----------------------------------------------------------------------------- sounds


func _register_sounds() -> void:
	var refs := world.refs
	var B := LevelBuilder.LEVEL_B
	# the pump on the well floor: trying, stalling, trying (heard in the handler);
	# running steady once the water is back
	audio.add_loop("pumpRun", "pump_run", refs.pump, 22.0, 0.0, 0.5, func() -> bool: return flags.water_restored)
	# the branch knocking against the shut valve each time the pump tries
	_knock = audio.add_shots("knock", ["knock_0", "knock_1", "knock_2"], refs.knock, 11.0, B, [0.35, 0.9], 0.7,
		func() -> bool: return _pump_on and not flags.water_restored)
	# once it's back: taps running at home, at Mrs. Chan's, at Auntie Yip's
	for spot in [[Vector3(-8.0, 0, -3.6), 6.0], [Vector3(-3.7, B, -9.7), 7.0], [Vector3(-3.6, 0, 2.9), 5.0]]:
		audio.add_loop("tap", "tap_run", spot[0], spot[1], (spot[0] as Vector3).y, 0.5, func() -> bool: return flags.water_restored)
	audio.add_shots("wellDrip", ["drip_0", "drip_1", "drip_2"], Vector3(18, B - 1, -14), 9.0, B, [0.4, 1.6], 0.5,
		func() -> bool: return flags.water_restored)


## The pump tries every few seconds and stalls, until the valve is open.
func _tick_pump(delta: float) -> void:
	if flags.water_restored:
		_pump_on = false
		return
	_pump_t -= delta
	if _pump_t <= 0.0:
		_pump_on = not _pump_on
		if _pump_on:
			audio.play_at("pump_start", world.refs.pump, 24.0, 0.8)
			_pump_t = 2.6
		else:
			audio.play_at("pump_stall", world.refs.pump, 24.0, 0.8)
			_pump_t = PUMP_CYCLE - 2.6


## On the walk back: the building filling up, heard as she passes.
func _tick_walk_back() -> void:
	if not flags.water_restored or stage >= COMPLETE:
		return
	var B := LevelBuilder.LEVEL_B
	var spots := [
		["flush", Vector3(2.6, B, -13.3), 3.5, func() -> void: audio.play_at("flush", Vector3(2.6, B, -14.0), 8.0, 0.9)],
		["kettle", Vector3(27.0, B, -14.5), 4.0, func() -> void: audio.play_at("kettle", Vector3(27.5, B, -15.6), 8.0, 0.9)],
		["chan", Vector3(0.0, B, -12.0), 5.0, func() -> void: hud.notice("notice.chan_buckets", 3.2)],
		["landing", Vector3(10.0, B, -13.0), 3.0, func() -> void: audio.play_at("knock_1", Vector3(10.2, B + 3.3, -12.85), 8.0, 0.7)],
	]
	for s in spots:
		if _heard.has(s[0]):
			continue
		var at: Vector3 = s[1]
		if mei_near(at.x, at.y, at.z, float(s[2])):
			_heard[s[0]] = true
			(s[3] as Callable).call()


# ----------------------------------------------------------------------------- seeing it


## Turning the view only shows what was there: each reveal needs Mei in the
## right place, looking from the right side.
func _discover(delta: float) -> void:
	if cam.rotating or locks.is_locked():
		return
	var p := player.position
	var side_view := cam.direction == 1 or cam.direction == 3
	var B := LevelBuilder.LEVEL_B
	var on_b := absf(p.y - B) < 0.6
	# the branch and the dead line leave the landing together; from the side,
	# one plainly crosses the well and the other plainly goes down it
	var at_crossing := on_b and p.x > 9.5 and p.x < 15.5 and p.z > -13.3 and p.z < -10.8
	if stage == TRACE and at_crossing:
		_zone_t += delta
		if side_view:
			flags.water_trace_1 = true
			audio.chime()
			say("c2_branch_seen", func() -> void: set_stage(TRACED_BRANCH))
			return
		if _zone_t > 22.0 and not _hinted.has("blue"):
			_hinted["blue"] = true
			say("c2_blue_until", func() -> void: hud.show_hint("hint.turn_view"))
	# on the far side: behind the air-conditioners it keeps going, past Mrs. Fong's
	var on_ledge := on_b and p.z < -13.0 and p.z > -17.4 and p.x > 12.0 and p.x < 24.3
	if stage == TRACED_BRANCH and on_ledge and side_view:
		flags.water_trace_2 = true
		audio.chime()
		say("c2_well_seen", func() -> void: set_stage(TRACED_WELL))
		return
	# the back kitchen window, edge-on from the front: seen from the side
	if not flags.window_found and stage >= TRACE:
		var w: Vector3 = world.refs.unitWindow
		var near := on_b and Vector2(p.x - w.x, p.z - w.z).length() < 7.0
		if near and ViewMath.back(cam.current_yaw).dot(Vector3(1, 0, 0)) > 0.6:
			flags.window_found = true
			audio.chime()
			hud.notice("notice.window_found", 3.4)
			hud.show_hint("")
			if stage < TRACED_WELL:
				flags.water_trace_2 = true
				set_stage(TRACED_WELL)


## Standing at the end of the service ledge, not seeing the window: remind her
## the view turns (the control, never the answer), as at yesterday's dead end.
func _tick_dead_end(delta: float) -> void:
	var p := player.position
	var at_end: bool = not flags.window_found and absf(p.y - LevelBuilder.LEVEL_B) < 0.6 and p.x > 24.2 and p.z < -17.8
	_window_t = _window_t + delta if at_end else 0.0
	if _window_t > 3.0 and not _hinted.has("window"):
		_hinted["window"] = true
		hud.show_hint("hint.turn_view")


## Hints come from the place and the people, never an arrow: first the knocking
## gets louder, then Mei says where it is, then Ho calls up the well.
func _tick_hints() -> void:
	if dialogue.is_open() or locks.is_locked():
		return
	match stage:
		TRACE:
			if _stage_t > 45.0 and _knock:
				_knock.gain = 1.1
			if _stage_t > 95.0 and not _hinted.has("knock"):
				_hinted["knock"] = true
				say("c2_hint_knock")
			elif _stage_t > 150.0 and not _hinted.has("ho"):
				_hinted["ho"] = true
				say("c2_hint_ho")
		TRACED_BRANCH, TRACED_WELL:
			if _stage_t > 110.0 and not _hinted.has("ledge%d" % stage):
				_hinted["ledge%d" % stage] = true
				say("c2_hint_ledge" if stage == TRACED_BRANCH else "c2_hint_back")


# ----------------------------------------------------------------------------- the end of the day


func _ending() -> void:
	if stage == COMPLETE:
		return
	set_stage(COMPLETE)
	mark("ending")
	locks.lock("ending")
	hud.set_quiet(true)
	# a moment with nothing to do but sit: the fan, the radio, the tea
	await get_tree().create_timer(2.6).timeout
	audio.silence(4.8)
	await fade.fade_out(4.5)
	slice.ending.play(DAYS_LEFT, "ending.ch2", Progress.LAST > 2)


# ----------------------------------------------------------------------------- per frame


func tick(delta: float, paused: bool) -> void:
	_run_tasks(delta, paused)
	if paused:
		return
	_stage_t += delta
	_tick_pump(delta)
	_discover(delta)
	_side_discover()
	_tick_dead_end(delta)
	_tick_hints()
	_tick_walk_back()
	# the hint clears once she has turned the view
	if _hinted.get("window") == true and flags.window_found:
		_hinted["window"] = false
		hud.show_hint("")
