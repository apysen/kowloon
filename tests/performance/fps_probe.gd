extends SceneTree

## Frame rate at the heaviest spots in the slice, full quality, vsync off.
##   godot --path . --script res://tests/performance/fps_probe.gd

const SPOTS := [
	["apartment", Vector3(-9, 0, 1), 0, 1],
	["hall", Vector3(-3, 0, 0), 0, 1],
	["clinic", Vector3(4, 0, -11), 0, 2],
	["corridor B", Vector3(2, 5, -12), 0, 5],
	["catwalk", Vector3(14, 5, -12), 0, 4],
	["roof", Vector3(0, 13, -12), 0, 7],
	["roof north", Vector3(2, 13, -18), 2, 7],
]

var slice: SliceRoot


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	slice = load("res://scenes/slice/slice.tscn").instantiate()
	slice.started = true
	root.add_child(slice)
	_run.call_deferred()


func _run() -> void:
	for i in 10:
		await process_frame
	slice.fade.set_black(false)
	var worst := INF
	for spot in SPOTS:
		if slice.quests.stage != spot[3]:
			slice.quests.force_stage(spot[3])
		slice.player.teleport(spot[1])
		while slice.cam.direction != spot[2]:
			slice.cam.rotate_view(1)
			for i in 30:
				await process_frame
		for i in 90:
			await process_frame
		var t0 := Time.get_ticks_usec()
		var n := 240
		for i in n:
			await process_frame
		var fps := n / ((Time.get_ticks_usec() - t0) / 1_000_000.0)
		worst = minf(worst, fps)
		print("%-12s %6.1f fps" % [spot[0], fps])
	print("worst: %.1f fps" % worst)
	quit(0)
