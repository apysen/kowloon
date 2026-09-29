class_name TitleScreen
extends Control

## 九龍城寨. The last weeks before the move.

const SLICE_SCENE := "res://scenes/slice/slice.tscn"

@onready var begin_button: Button = %Begin

var _going := false


func _ready() -> void:
	begin_button.pressed.connect(_begin)
	begin_button.grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.2)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		_begin()


func _begin() -> void:
	if _going:
		return
	_going = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.2)
	await tw.finished
	get_tree().change_scene_to_file(SLICE_SCENE)
