class_name SliceRoot
extends Node3D

## The Blue Pipe: coordinates one playthrough of the vertical slice.
##
## Owns nothing it can hand to a component. It wires the components
## together, routes input (dialogue first, then the Polaroid, the camera,
## and interaction, as the slice did), and runs the frame in a fixed order:
## the world and the story tick after Mei and the camera have moved.

const TITLE_SCENE := "res://scenes/app/title_screen.tscn"

@export_group("Gameplay Components")
## Who is holding Mei still (dialogue, rotation, camera, climbs, fades).
@export var locks: ControlLocks
## Graphics quality toggle and its persistence.
@export var display: DisplaySettings
## The story: stages, conversations, discoveries, the washing, the ending.
@export var quests: QuestDirector
## Runs conversations through the dialogue box.
@export var dialogue: DialogueDirector
## What Mei can interact with, and the one prompt that says so.
@export var interaction: InteractionDirector
## Camera mode, the Polaroid, and the prints Mei keeps.
@export var photography: PhotographyDirector
## The people Mei has photographed.
@export var scrapbook: Scrapbook
## Ambient beds, wayfinding emitters, one-shots.
@export var audio: AudioZones

@export_group("World")
@export var world: World
@export var player: Player
@export var cam: CameraRig

@export_group("Interface")
@export var hud: Hud
@export var fade: ScreenFade
@export var ending: EndingScreen
@export var debug: DebugOverlay
@export var screen_fx: ColorRect

var started := false


func _ready() -> void:
	player.walk_space = world.walk_space
	player.teleport(Vector3(-8.5, 0, 2))
	player.facing = Vector3(-1, 0, 0)
	quests.setup()
	debug.slice = self
	cam.follow(player.position)
	fade.set_black(true)
	audio.start()
	begin()


func begin() -> void:
	if started:
		return
	started = true
	await get_tree().create_timer(0.4).timeout
	await fade.fade_in(1.4)
	await get_tree().create_timer(0.5).timeout
	quests.start_intro()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("debug_toggle"):
		debug.visible = not debug.visible
		return
	if debug.visible and _debug_key(event):
		return
	if quests.stage == QuestStage.COMPLETE:
		if event.is_action("restart"):
			get_tree().change_scene_to_file(TITLE_SCENE)
		return
	if event.is_action("advance"):
		if dialogue.is_open():
			dialogue.advance()
		elif photography.showing_photo:
			photography.dismiss()
		elif photography.active:
			photography.capture()
	elif event.is_action("interact"):
		if dialogue.is_open():
			dialogue.advance()
		elif photography.showing_photo:
			photography.dismiss()
		else:
			interaction.trigger()
	elif event.is_action("rotate_left"):
		if not locks.is_locked():
			cam.rotate_view(-1)
	elif event.is_action("rotate_right"):
		if not locks.is_locked():
			cam.rotate_view(1)
	elif event.is_action("camera"):
		if photography.active:
			photography.exit()
		else:
			photography.enter()
	elif event.is_action("scrapbook"):
		scrapbook.toggle()
	elif event.is_action("cancel"):
		if scrapbook.open:
			scrapbook.toggle(false)
		elif photography.active:
			photography.exit()
	elif event.is_action("graphics"):
		display.toggle()
		hud.notice("Graphics: full (shadows, bloom, depth of field)" if display.high else "Graphics: fast", 2.2)
	get_viewport().set_input_as_handled()


func _debug_key(event: InputEvent) -> bool:
	for n in range(1, 7):
		if event.is_action("teleport_%d" % n):
			var tp: Array = QuestStage.TELEPORTS[n]
			player.teleport(tp[1])
			if (tp[1] as Vector3).y > 12.0:
				quests.on_enter_roof()
			return true
	if event.is_action("debug_next"):
		quests.force_stage(quests.stage + 1)
		return true
	if event.is_action("debug_prev"):
		quests.force_stage(quests.stage - 1)
		return true
	return false


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	cam.follow(player.position)
	cam.zoom_target = 0.72 if player.band() == 2 else 1.0
	var paused := dialogue.is_open() or photography.showing_photo or scrapbook.open
	world.update(delta, player, cam, paused)
	audio.fabric_moved = world.fabric_state != "catwalk"
	quests.tick(delta, paused)
	audio.update(delta, player.position, world.roof_mix, quests.stage == QuestStage.COMPLETE)
	var fx := screen_fx.material as ShaderMaterial
	var t := world.roof_mix
	fx.set_shader_parameter("time", fmod(Time.get_ticks_msec() / 1000.0, 100.0))
	fx.set_shader_parameter("vignette", 0.48 - 0.16 * t)
	fx.set_shader_parameter("warmth", 1.0 - 0.4 * t)
	fx.set_shader_parameter("range", 0.2 + 0.05 * t)
	_update_marker()


## The small icon over whatever Mei can use right now.
func _update_marker() -> void:
	var cur := interaction.current
	if cur.is_empty() or locks.is_locked() or photography.active or dialogue.is_open():
		hud.show_marker("", Vector2.ZERO)
		return
	var pos: Vector3 = interaction.position_of(cur)
	var id: String = cur.id
	var kind := "use"
	var h := 1.3
	if int(cur.priority) == InteractionDirector.Priority.NPC:
		kind = "talk"
		h = 1.55 if id in ["son", "child"] else (1.25 if id.begins_with("mahjong") else 2.05)
		if world.residents.has(id):
			pos = (world.residents[id] as Resident).global_position
	else:
		var verb: Variant = cur.verb
		var v: String = String((verb as Callable).call()) if verb is Callable else String(verb)
		if v.begins_with("Look"):
			kind = "look"
	var world_pos := pos + Vector3(0, h, 0)
	if cam.camera.is_position_behind(world_pos):
		hud.show_marker("", Vector2.ZERO)
		return
	hud.show_marker(kind, cam.camera.unproject_position(world_pos))
