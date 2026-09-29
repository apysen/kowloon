extends SceneTree

## A top-down orthographic view of the whole Walled City, as laid out from the
## 1985 survey map, for the docs.
##   godot --path . --resolution 1600x1000 --script res://tools/capture/capture_plan.gd -- <out.png>

var _slice: SliceRoot


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/slice/slice.tscn")
	_slice = scene.instantiate()
	_slice.started = true
	root.add_child(_slice)
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	for i in 3:
		await process_frame
	_slice.fade.set_black(false)
	_slice.quests.force_stage(9)
	_slice.player.teleport(Vector3(0, 13, -14))
	for i in 30:
		await process_frame
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 150.0
	cam.far = 600.0
	root.add_child(cam)
	cam.global_position = Vector3(-40, 300, -5)
	cam.look_at(Vector3(-40, 0, -5.01), Vector3(0, 0, -1))
	cam.current = true
	(_slice.screen_fx.material as ShaderMaterial).set_shader_parameter("tilt_shift", false)
	_slice.hud.visible = false
	var env := _slice.world.environment.environment
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	for i in 60:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out)
	print("captured ", out)
	quit(0)
