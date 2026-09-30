class_name DisplaySettings
extends Node

## Graphics quality (G): full (shadows, bloom, SSAO, volumetric light,
## tilt-shift) or fast; and fullscreen or windowed, from the title screen or
## the pause menu. Both remembered between sessions.

signal quality_changed(high: bool)

static var PATH := SettingsFile.path()

@export var environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var screen_fx: ColorRect

var high := true


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		high = bool(cfg.get_value("display", "high_quality", true))
	apply()


## The saved window mode, applied once at start (the title screen and the slice
## both call it; the second call changes nothing).
static func apply_saved_window() -> void:
	var cfg := ConfigFile.new()
	var on := cfg.load(PATH) == OK and bool(cfg.get_value("display", "fullscreen", false))
	if on != is_fullscreen():
		_set_window(on)


static func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## Fullscreen on or off, remembered. Returns the new state.
static func toggle_fullscreen() -> bool:
	var on := not is_fullscreen()
	_set_window(on)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("display", "fullscreen", on)
	cfg.save(PATH)
	return on


## The menu label for the current window mode (a string key).
static func fullscreen_label() -> String:
	return "ui.fullscreen_on" if is_fullscreen() else "ui.fullscreen_off"


static func _set_window(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


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
