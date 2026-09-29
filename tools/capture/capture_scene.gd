extends SceneTree

## Screenshot of any scene after it settles.
##   godot --path . --script res://tools/capture/capture_scene.gd -- <scene> <out.png> [frames]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene: PackedScene = load(args[0])
	root.add_child(scene.instantiate())
	_shoot.call_deferred(args[1], int(args[2]) if args.size() > 2 else 120)


func _shoot(out: String, n: int) -> void:
	for i in n:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out)
	print("captured ", out)
	quit(0)
