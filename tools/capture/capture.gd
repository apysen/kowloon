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
		await _frames(90)
		var img := root.get_viewport().get_texture().get_image()
		var path := _out.path_join(name + ".png")
		img.save_png(path)
		print("captured ", path)
	quit(0)
