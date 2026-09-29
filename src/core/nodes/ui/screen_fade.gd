class_name ScreenFade
extends ColorRect

## Fades to black and back (floor changes, the ending), and the camera flash.

@onready var flash: ColorRect = %Flash


func fade_out(secs := 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(self, "color:a", 1.0, secs)
	await tw.finished


func fade_in(secs := 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(self, "color:a", 0.0, secs)
	await tw.finished


func set_black(on: bool) -> void:
	color.a = 1.0 if on else 0.0


func camera_flash() -> void:
	flash.color.a = 1.0
	create_tween().tween_property(flash, "color:a", 0.0, 0.9).set_ease(Tween.EASE_OUT)
