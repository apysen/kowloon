extends SceneTree

## Screenshots of the running game for review.
##
##   godot --path . --script res://tools/capture/capture.gd -- <out_dir> [shot ...]
##
## Each shot is name:x,y,z:direction[:stage], e.g. "hall:-4,0,0:0:1".
## Runs the real slice scene (windowed, full renderer), skips the intro,
## places Mei, turns the view, lets the light settle, and saves a PNG.

var _slice: SliceRoot
var _out := ""
var _shots: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://captures"
	for i in range(1, args.size()):
		_shots.append(args[i])
	if _shots.is_empty():
		_shots = ["start:-8.5,0,2:0:1"]
	DirAccess.make_dir_recursive_absolute(_out)
	var scene: PackedScene = load("res://scenes/slice/slice.tscn")
	_slice = scene.instantiate()
	_slice.started = true
	root.add_child(_slice)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	await _frames(3)
	_slice.fade.set_black(false)
	for shot in _shots:
		var parts: PackedStringArray = String(shot).split(":")
		var name := parts[0]
		var xyz := parts[1].split(",")
		var pos := Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
		var dir := int(parts[2]) if parts.size() > 2 else 0
		var stage := int(parts[3]) if parts.size() > 3 else 1
		if _slice.quests.stage != stage:
			_slice.quests.force_stage(stage)
		_slice.player.teleport(pos)
		while _slice.cam.direction != dir:
			_slice.cam.rotate_view(1)
			await _frames(40)
		_slice.cam.snap_next = true
		await _frames(60)
		# optional interface state: say=<dialogue id>, camera, photo=<id>, scrapbook, face=<x,z>
		var action := parts[4] if parts.size() > 4 else ""
		if action.begins_with("say="):
			_slice.dialogue.start(action.substr(4))
			for k in 3:
				_slice.dialogue.advance()
				await _frames(2)
			await _frames(40)
		elif action == "camera":
			_slice.photography.enter()
		elif action.begins_with("photo="):
			var tex: Texture2D = await _slice.photography.studio.shoot(action.substr(6))
			_slice.photography.polaroid.present(tex, ResidentCatalog.entry(action.substr(6)).get("name", ""))
			await _frames(260)
		elif action == "scrapbook":
			_slice.scrapbook.add("lau")
			_slice.scrapbook.add("ng")
			await _slice.scrapbook.toggle(true)
		elif action.begins_with("face="):
			var f := action.substr(5).split(",")
			_slice.player.facing = Vector3(float(f[0]), 0, float(f[1]))
		await _frames(30)
		var img := root.get_viewport().get_texture().get_image()
		var path := _out.path_join(name + ".png")
		img.save_png(path)
		print("captured ", path)
	quit(0)
