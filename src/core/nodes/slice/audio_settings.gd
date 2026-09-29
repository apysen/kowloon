class_name AudioSettings
extends Node

## Master volume, set from the pause menu. Remembered between sessions.

const PATH := "user://settings.cfg"

## 0..1, applied to the Master bus on a perceptual curve.
var volume := 0.8


func _ready() -> void:
	volume = saved_volume()
	apply(volume)


func set_volume(v: float, save := true) -> void:
	volume = clampf(v, 0.0, 1.0)
	apply(volume)
	if save:
		var cfg := ConfigFile.new()
		cfg.load(PATH)
		cfg.set_value("audio", "volume", volume)
		cfg.save(PATH)


static func saved_volume() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		return float(cfg.get_value("audio", "volume", 0.8))
	return 0.8


## Squared, so the slider's middle sounds like the middle.
static func apply(v: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, v <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v * v, 0.0001)))
