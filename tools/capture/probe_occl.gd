extends SceneTree

## Debug: what stands, unfaded, between the camera and Mei at a spot.
##   godot --path . --script res://tools/capture/probe_occl.gd -- x,y,z dir stage

var _slice: SliceRoot


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/slice/slice.tscn")
	_slice = scene.instantiate()
	_slice.started = true
	root.add_child(_slice)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var xyz := args[0].split(",")
	var pos := Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
	for i in 3:
		await process_frame
	_slice.quests.force_stage(int(args[2]))
	_slice.player.teleport(pos)
	while _slice.cam.direction != int(args[1]):
		_slice.cam.rotate_view(1)
		for i in 40:
			await process_frame
	for i in 90:
		await process_frame
	var w := _slice.world
	print("room: '", w.current_room, "'")
	var eye := _slice.cam.camera.global_position
	var mei := pos + Vector3(0, float(args[3]) if args.size() > 3 else 0.8, 0)
	for it in w._items:
		if not it.visible or it.opacity < 0.3:
			continue
		var b: AABB = it.aabb
		if b.intersects_segment(eye, mei) != null:
			print("  blocks: ", w.level.get_path_to(it.node), " fadeable=", it.fadeable, " room='", it.room,
				"' side='", it.get("room_side", ""), "' op=", it.opacity, " band=", it.band)
	quit(0)
