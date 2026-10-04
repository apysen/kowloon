extends SceneTree

## Frame rate at a few spots, indoors and out, from Mei's eye (the camera
## raised) and then from the usual view, with what the renderer draws.
##   godot --path . --script res://tests/performance/fp_probe.gd

const SPOTS := [
	["flat", Vector3(-10.5, 0, 1.2), Vector3(-1, 0, -0.6)],
	["alcove", Vector3(-1.0, 0, 1.6), Vector3(-0.6, 0, 1)],
	["clinic", Vector3(6.6, 0, -10.8), Vector3(-1, 0, -0.8)],
	["chan", Vector3(-4.0, 5, -11.0), Vector3(-1, 0, -0.5)],
	["workshop", Vector3(-2.0, 5, 1.6), Vector3(-1, 0, 0.3)],
	["roof", Vector3(2.0, 13, -10.0), Vector3(0, 0, -1)],
	["yamen court", Vector3(10.0, 0, 0.5), Vector3(-0.5, 0, -1)],
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
	var vp := root.get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	slice.photography.has_camera = true
	var worst := INF
	for fp in [true, false]:
		print("== ", "first person" if fp else "usual view")
		for spot in SPOTS:
			slice.photography.exit()
			for i in 30:
				await process_frame
			slice.player.teleport(spot[1])
			slice.player.facing = (spot[2] as Vector3).normalized()
			if fp:
				slice.photography.enter()
			for i in 90:
				await process_frame
			var n := 240
			var slowest := 0.0
			var cpu := 0.0
			var gpu := 0.0
			var t0 := Time.get_ticks_usec()
			var last := t0
			for i in n:
				await process_frame
				var now := Time.get_ticks_usec()
				slowest = maxf(slowest, (now - last) / 1000.0)
				last = now
				cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
				gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
			var frame := (Time.get_ticks_usec() - t0) / 1000.0 / n
			worst = minf(worst, 1000.0 / frame)
			print("%-12s %6.1f fps  frame %5.2f ms (slowest %5.1f)  render cpu %4.2f  gpu %4.2f  draws %5d  shadow draws %5d  in eye: %s" % [
				spot[0], 1000.0 / frame, frame, slowest, cpu / n, gpu / n,
				RenderingServer.viewport_get_render_info(vp, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
				RenderingServer.viewport_get_render_info(vp, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
				slice.world.first_person])
	print("worst: %.1f fps" % worst)
	quit(0)
