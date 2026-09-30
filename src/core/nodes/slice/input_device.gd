class_name InputDevice
extends Node

## Keyboard and mouse, or a controller: whichever was touched last. The
## on-screen prompts follow it ([F] becomes [A], [Q] becomes [LB]...). Nodes in
## the "input_glyphs" group are told when it changes, through refresh_glyphs().
##
## The title screen and the slice each add one; only one exists at a time.

static var using_pad := false


func _input(event: InputEvent) -> void:
	var pad := using_pad
	if event is InputEventJoypadButton:
		pad = true
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad = false
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 4.0:
		pad = false
	if pad != using_pad:
		using_pad = pad
		get_tree().call_group("input_glyphs", "refresh_glyphs")
