extends SceneTree

## Lists geometry projected over the active room for cutaway debugging.
## godot --path . --script res://tools/capture/audit_room_view.gd -- x,y,z direction stage

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var xyz := args[0].split(",")
	var scene: PackedScene = load("res://scenes/slice/slice.tscn")
	var slice: SliceRoot = scene.instantiate()
	slice.started = true
	root.add_child(slice)
	for i in 3:
		await process_frame
	slice.director.force_stage(int(args[2]))
	slice.player.teleport(Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2])))
	while slice.cam.direction != int(args[1]):
		slice.cam.rotate_view(1)
		for i in 40:
			await process_frame
	for i in 60:
		await process_frame
	var w: World = slice.world
	var key := "%s:%d" % [w.current_room, slice.cam.direction]
	print("room view ", key)
	var blockers: Array = w._room_view_blockers.get(key, [])
	for it in blockers:
		print("  blocker ", w.level.get_path_to(it.node), " content=", it.content_of,
			" room=", it.room, " opacity=", it.view_opacity)
	print("nearby pipes/signs:")
	for it in w._items:
		var path := String(w.level.get_path_to(it.node))
		var lower := path.to_lower()
		if ("pipe" in lower or "sign" in lower) and int(float(it.band)) == PerspectiveRules.player_band(slice.player.position.y):
			print("  detail ", path, " content=", it.content_of, " room=", it.room,
				" aabb=", it.aabb, " view=", it.view_opacity)
	quit(0)
