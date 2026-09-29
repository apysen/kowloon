class_name DisplaySettings
extends Node

## Graphics quality (G): full (shadows, bloom, SSAO, volumetric light,
## tilt-shift) or fast. Remembered between sessions.

signal quality_changed(high: bool)

const PATH := "user://settings.cfg"

@export var environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var screen_fx: ColorRect

var high := true


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		high = bool(cfg.get_value("display", "high_quality", true))
	apply()


func toggle() -> void:
	high = not high
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("display", "high_quality", high)
	cfg.save(PATH)
	apply()
	quality_changed.emit(high)


func apply() -> void:
	var env := environment.environment
	env.glow_enabled = high
	env.ssao_enabled = high
	env.ssil_enabled = high
	env.volumetric_fog_enabled = high
	sun.shadow_enabled = high
	get_viewport().msaa_3d = Viewport.MSAA_2X if high else Viewport.MSAA_DISABLED
	(screen_fx.material as ShaderMaterial).set_shader_parameter("tilt_shift", high)
