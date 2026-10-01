class_name ChapterSevenDirector
extends ChapterDirector

## Chapter 7, The Way Out. 0 days until we leave.
##
## The flat is nearly empty, and sounds it. Grandfather was meant to be
## downstairs and isn't. There is no arrow and no hint: the yamen is the
## middle of everything, and there are several ways there (the lane; past
## Kwok's shut stall and through the side passage beside the yamen hall; down
## Mr. Ng's old ladder from the roof). He is sitting in the courtyard. Not
## hiding, not refusing. "I don't want to go." "Neither do I."
##
## Then home, him half a step behind: once he turns the wrong way to see if she
## knows the right one, and on the way out he says "After Kwok", and she says
## where Kwok used to be. At the yamen's mouth Mei turns back and the camera
## comes up by itself; the City doesn't fit in it from any side. Grandfather
## takes the camera and photographs her. WE LEFT. The credits are the prints
## she actually took.

enum {
	START,
	FIND,
	YAMEN,
	GO_HOME,
	WAY_OUT,
	LOOK_BACK,
	PHOTO,
	END,
}

const NAMES := ["START", "FIND", "YAMEN", "GO_HOME", "WAY_OUT", "LOOK_BACK", "PHOTO", "END"]

const OBJECTIVES := {
	FIND: ["c7.obj.find", ""],
	GO_HOME: ["c7.obj.home", ""],
	WAY_OUT: ["c7.obj.home", ""],
}

const SEAT := Vector3(8.9, 0, 0.2)          # where he sits, in the courtyard
const MEI_STANDS := Vector3(8.6, 0, 3.0)    # where he has her stand
const GF_SHOOTS := Vector3(8.6, 0, 5.2)

var flags := {
	"found": false, "said_it": false, "payoff_grandfather_navigation": false, "payoff_kwok_landmark": false,
	"home": false, "looked_back": false, "payoff_perspective_theme": false, "final_photo_mei": false,
}
## the directions Mei has looked in from the yamen's mouth, camera up
var views: Dictionary = {}
## how many times Grandfather has said to try another angle
var nudges := 0

var _stage_t := 0.0
var _idle_t := 0.0
var _last_view := -1
var _following := false
var _wrong_turn := false
var _reverb := -1
var _credits: CanvasLayer


func setup() -> void:
	_bind()
	_prepare_world()
	_register_shared()
	for id in ["chair", "sign", "footbridge", "fongDoor", "laneGate", "workshopDoorShut", "oldPhoto", "radio", "bunk", "unitSink"]:
		unregister(id)
	interaction.add({"id": "radioGone", "position": world.refs.radio, "radius": 1.2, "priority": InteractionDirector.Priority.ENV,
		"verb": "verb.look", "interact": func() -> void: say("c7_radio_gone")})
	interaction.add({"id": "bluePipe", "position": Vector3(-3.6, 0, -0.55), "radius": 1.0, "priority": InteractionDirector.Priority.ENV,
		"verb": "verb.look", "interact": func() -> void: say("c7_pipe")})
	# Mr. Ng's old ladder, from the roof down into the strip beside the yamen hall
	var refs := world.refs
	interaction.add({"id": "ngLadderDown", "position": refs.ngLadderTop, "radius": 0.9, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.climb_down", "interact": func() -> void:
			audio.creak()
			transition(refs.ngLadderFoot, 16)})
	interaction.add({"id": "ngLadderUp", "position": refs.ngLadderFoot, "radius": 0.9, "priority": InteractionDirector.Priority.QUEST,
		"verb": "verb.climb", "interact": func() -> void:
			audio.creak()
			transition(refs.ngLadderTop, 16, on_enter_roof)})
	talk("mum", 1.4, func() -> void: say("c7_mum_wait"))
	photography.has_camera = true
	for id in ["lau", "ng", "ho", "chiu", "cheung", "line", "lau_clinic", "wong_room", "kit", "wong", "ng_birds", "old_photo"]:
		if id in ["lau_clinic", "wong_room"] and not Progress.carried_photos.has(id):
			continue
		scrapbook.add(id)
		if Progress.carried_photos.has(id):
			photography.photos[id] = Progress.carried_photos[id]
		elif ResidentCatalog.FIXED_PRINTS.has(id):
			photography.photos[id] = load(ResidentCatalog.FIXED_PRINTS[id])
		elif not ResidentCatalog.NOTE_PAGES.has(id):
			_reshoot(id)
	Progress.after_unlocked = true
	for id in ["ho", "wong_room", "lau_clinic", "ng", "kit", "wong_after"]:
		Progress.late_notes[id] = true
	_register_sounds()
	Progress.reach(7)


func _reshoot(id: String) -> void:
	photography.photos[id] = await photography.studio.shoot(id)


func _exit_tree() -> void:
	if _reverb >= 0 and _reverb < AudioServer.get_bus_effect_count(0):
		AudioServer.remove_bus_effect(0, _reverb)
	_reverb = -1


func is_complete() -> bool:
	return stage == END


func stage_name() -> String:
	return NAMES[clampi(stage, 0, NAMES.size() - 1)]


func set_stage(s: int) -> void:
	stage = s
	_stage_t = 0.0
	var o: Array = OBJECTIVES.get(s, ["", ""])
	objective = o[0]
	hint = o[1]
	hud.set_objective(objective, hint)


func force_stage(s: int) -> void:
	s = clampi(s, START, END)
	if s >= GO_HOME:
		flags.found = true
		flags.said_it = true
		_following = true
	if s >= WAY_OUT:
		flags.home = true
	set_stage(s)


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
	# almost everyone gone
	for id in ["lau", "chan", "son", "wong", "chopper", "mahjong1", "mahjong2", "mahjong3", "worker", "child", "fanman", "ng", "shopkeeper"]:
		var r: Resident = world.residents.get(id)
		if r:
			r.gone = true
			r.visible = false
	var k := 0
	for r in world.residents.values():
		var res := r as Resident
		if not res.story:
			if k % 8 != 0:
				res.gone = true
				res.visible = false
			k += 1
	_pose(world.residents.grandfather, SEAT, Vector3(0, 0, 1), "sit")
	_pose(world.residents.mum, Vector3(-9.4, 0, -1.2), Vector3(1, 0, 0.3), "idle")


func _pose(r: Resident, at: Vector3, facing: Vector3, anim: String) -> void:
	if r.home.distance_to(at) > 0.01 or r.idle_anim != anim:
		r.place_at(at)
		r.facing = facing
		r.sprite.facing = facing
		r.idle_anim = anim
		r.sprite.play(anim)


func _register_sounds() -> void:
	# the flat and the building gone quiet; what's left echoes
	for q in ["radio", "tv", "drill", "chop", "mahjong", "kids", "pigeons", "fabric_drip"]:
		audio.quiet[q] = true
	var verb := AudioEffectReverb.new()
	verb.room_size = 0.62
	verb.damping = 0.35
	verb.wet = 0.18
	verb.dry = 0.95
	AudioServer.add_bus_effect(0, verb)
	_reverb = AudioServer.get_bus_effect_count(0) - 1
	audio.add_shots("farSteps", ["step_0", "step_1", "step_2", "step_3"], Vector3(0, 0, -4), 30.0, 0.0, [5.0, 12.0], 0.2)


# ----------------------------------------------------------------------------- the day begins


func opens_on_card() -> bool:
	return true


func start_intro() -> void:
	await _title_card("c7.card.number", "c7.card.title")
	player.teleport(Vector3(-8.2, 0, 0.4))
	player.facing = Vector3(-1, 0, 0)
	cam.snap_next = true
	await fade.fade_in(1.6)
	mark("open")
	later(func() -> void:
		say("c7_open", func() -> void: set_stage(FIND)), 2.0)


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


# ----------------------------------------------------------------------------- the yamen


func _tick_find() -> void:
	if stage != FIND or dialogue.is_open() or locks.is_locked():
		return
	if mei_near(SEAT.x, SEAT.y, SEAT.z, 2.6):
		_yamen_scene()


## Not hiding, not refusing. Just sitting.
func _yamen_scene() -> void:
	flags.found = true
	set_stage(YAMEN)
	mark("found")
	var gf: Resident = world.residents.grandfather
	gf.face_toward(player.position, 30.0)
	say("c7_yamen", func() -> void:
		# she sits; nothing for a while but the City
		locks.lock("yamen")
		hud.set_quiet(true)
		await get_tree().create_timer(5.0).timeout
		say("c7_yamen_2", func() -> void:
			flags.said_it = true
			await get_tree().create_timer(3.0).timeout
			# he stands
			_pose(gf, gf.position, Vector3(0, 0, 1), "idle")
			locks.unlock("yamen")
			hud.set_quiet(false)
			_following = true
			set_stage(GO_HOME)))


## Half a step behind her, not ahead.
func _tick_follow() -> void:
	if not _following or _wrong_turn:
		return
	var gf: Resident = world.residents.grandfather
	var p := player.position
	var d := Vector2(gf.position.x - p.x, gf.position.z - p.z).length()
	if absf(gf.position.y - p.y) > 1.5 or d > 9.0:
		# a stair or a ladder between them: he's there when she is
		var behind := p - player.facing.normalized() * 0.9
		behind.y = p.y
		if world.walk_space.floor_at(behind.x, behind.z, behind.y) == null:
			behind = p + Vector3(0.6, 0, 0.6)
		gf.place_at(behind)
		return
	if d > 1.7 and not gf.is_walking():
		var to := p - player.facing.normalized() * 0.9
		to.y = p.y
		gf.walk([to], Callable(), 2.3)


# ----------------------------------------------------------------------------- the walk home, and out


## Coming into the hall, he turns the wrong way to see if she knows the right one.
func _tick_home() -> void:
	if dialogue.is_open() or locks.is_locked():
		return
	var p := player.position
	var in_hall := p.y < 1.0 and p.x > -6.0 and p.x < 2.0 and p.z > -1.0 and p.z < 1.0
	if stage == GO_HOME and in_hall and not flags.payoff_grandfather_navigation and not _wrong_turn:
		_wrong_turn = true
		var gf: Resident = world.residents.grandfather
		gf.walk([Vector3(minf(p.x + 2.2, 1.8), 0, 0.0)], func() -> void:
			gf.face_toward(player.position, 6.0)
			say("c7_wrong_way", func() -> void:
				flags.payoff_grandfather_navigation = true
				mark("wrongWay")
				_wrong_turn = false), 1.6)
		return
	if stage == GO_HOME and world.current_room == "apartment":
		_home_scene()
		return
	# on the way out, crossing the hall to the east: "After Kwok."
	if stage == WAY_OUT and not flags.payoff_kwok_landmark and in_hall and p.x > -1.8:
		flags.payoff_kwok_landmark = true
		mark("kwok")
		say("c7_kwok")
		return
	if stage == WAY_OUT and p.y < 1.0 and p.x > 6.0 and p.x < 11.0 and p.z > 5.0:
		_at_the_mouth()


func _home_scene() -> void:
	flags.home = true
	set_stage(WAY_OUT)
	mark("home")
	var mum: Resident = world.residents.mum
	mum.face_toward(player.position, 20.0)
	say("c7_home", func() -> void:
		set_gone(world.level.get_node_or_null("ChapterProps/Ch7/Flat/Suitcase"), true)
		set_gone(world.level.get_node_or_null("ChapterProps/Ch7/Flat/Handle"), true)
		mum.fade("out"))


# ----------------------------------------------------------------------------- it doesn't fit


func _at_the_mouth() -> void:
	set_stage(LOOK_BACK)
	mark("mouth")
	# control is hers again: the camera comes up once she looks back
	photography.shutter_locked = true


## Which quarter she is looking toward, camera up (0 north, 1 west, 2 south, 3 east).
func view_quarter() -> int:
	return posmod(roundi(cam.fp_yaw / (PI / 2.0)), 4)


func _tick_look_back(delta: float) -> void:
	if stage != LOOK_BACK or dialogue.is_open():
		return
	if not photography.active:
		# looking back into the City: up it comes, by itself
		if player.facing.z < -0.4 and not locks.is_locked():
			flags.looked_back = true
			photography.enter()
		return
	if not photography.aiming:
		return
	var q := view_quarter()
	if q != _last_view:
		_last_view = q
		_idle_t = 0.0
		if not views.has(q):
			views[q] = true
			mark("view%d" % q)
	else:
		_idle_t += delta
	if views.size() >= 3:
		_doesnt_fit()
		return
	# standing still too long: a hint, never a finish
	if _idle_t > (10.0 if nudges == 0 else 14.0):
		_idle_t = 0.0
		nudges += 1
		say("c7_try_angle")


func _doesnt_fit() -> void:
	set_stage(PHOTO)
	flags.payoff_perspective_theme = true
	mark("doesntFit")
	say("c7_doesnt_fit", func() -> void:
		photography.exit()
		await get_tree().create_timer(1.6).timeout
		photography.shutter_locked = false
		_final_photo())


# ----------------------------------------------------------------------------- the last photograph


func _final_photo() -> void:
	var gf: Resident = world.residents.grandfather
	_following = false
	gf.face_toward(player.position, 20.0)
	say("c7_give_me", func() -> void:
		locks.lock("final")
		await fade.fade_out(0.4)
		player.teleport(MEI_STANDS)
		player.facing = Vector3(0, 0, 1)
		_pose(gf, GF_SHOOTS, Vector3(0, 0, -1), "idle")
		cam.snap_next = true
		await fade.fade_in(0.5)
		await get_tree().create_timer(1.6).timeout
		# flash: and the white holds longer than any of hers did
		audio.shutter()
		var white := CanvasLayer.new()
		white.layer = 40
		add_child(white)
		var rect := ColorRect.new()
		rect.color = Color(1, 1, 1, 1)
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		white.add_child(rect)
		var tex := await photography.studio.shoot("mei")
		photography.photos["mei"] = tex
		await get_tree().create_timer(1.6).timeout
		var tw := create_tween()
		tw.tween_property(rect, "color:a", 0.0, 1.2)
		await tw.finished
		white.queue_free()
		flags.final_photo_mei = true
		mark("finalPhoto")
		await photography.polaroid.present(tex, ResidentCatalog.entry("mei").name)
		await get_tree().create_timer(1.6).timeout
		photography.polaroid.dismiss()
		locks.unlock("final")
		await scrapbook.file_photo("mei")
		_ending())


# ----------------------------------------------------------------------------- we left


## The prints she actually took, in the order she took them (not the old
## photograph, which somebody else took, and nothing for the pages without one).
func credit_ids() -> Array[String]:
	var out: Array[String] = []
	for id in scrapbook.entries:
		if photography.photos.has(id) and not ResidentCatalog.FIXED_PRINTS.has(id) and not ResidentCatalog.NOTE_PAGES.has(id):
			out.append(id)
	return out


func _ending() -> void:
	if stage == END:
		return
	locks.lock("ending")
	hud.set_quiet(true)
	audio.silence(4.0)
	await fade.fade_out(2.4)
	_credits = CanvasLayer.new()
	_credits.layer = 60
	add_child(_credits)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_credits.add_child(bg)
	await _card_line("c7.we_left", 40, 5.0)
	for id in credit_ids():
		await _credit_print(id)
	await _card_line("c7.credits.title", 30, 2.6)
	await _card_line("c7.credits.thanks", 20, 2.6)
	var replay := RichTextLabel.new()
	replay.bbcode_enabled = true
	replay.fit_content = true
	replay.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	replay.position = Vector2(-260, -90)
	replay.size = Vector2(520, 40)
	replay.text = "[center]" + UIStyle.keycaps(tr("c7.credits.replay")) + "[/center]"
	_credits.add_child(replay)
	set_stage(END)
	mark("end")


func _card_line(key: String, size: int, hold: float) -> void:
	var l := Label.new()
	l.text = key
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UIStyle.FONT_UI_BOLD)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UIStyle.CONCRETE)
	l.modulate.a = 0.0
	_credits.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 1.2)
	tw.tween_interval(hold)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	await tw.finished
	l.queue_free()


func _credit_print(id: String) -> void:
	var tex: Texture2D = photography.photos[id]
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var pic := TextureRect.new()
	pic.texture = tex
	pic.custom_minimum_size = Vector2(300, 300)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(pic)
	var cap := Label.new()
	cap.text = ResidentCatalog.entry(id).name
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_override("font", UIStyle.FONT_HAND)
	cap.add_theme_font_size_override("font_size", 26)
	cap.add_theme_color_override("font_color", UIStyle.CONCRETE)
	box.add_child(cap)
	box.position = Vector2(-150, -180)
	box.modulate.a = 0.0
	_credits.add_child(box)
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.8)
	tw.tween_interval(1.6)
	tw.tween_property(box, "modulate:a", 0.0, 0.6)
	await tw.finished
	box.queue_free()


# ----------------------------------------------------------------------------- per frame


func tick(delta: float, paused: bool) -> void:
	_run_tasks(delta, paused)
	if paused:
		return
	_stage_t += delta
	_tick_find()
	_tick_follow()
	_tick_home()
	_tick_look_back(delta)
