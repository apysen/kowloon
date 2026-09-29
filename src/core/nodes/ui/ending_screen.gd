class_name EndingScreen
extends Control

## After the boxes: black, then the lines, one at a time.

@onready var lines: VBoxContainer = %Lines


func _ready() -> void:
	visible = false


func play() -> void:
	visible = true
	for l in lines.get_children():
		(l as CanvasItem).modulate.a = 0.0
	var first := true
	for l in lines.get_children():
		await get_tree().create_timer(0.8 if first else 2.6).timeout
		first = false
		create_tween().tween_property(l, "modulate:a", 1.0, 1.4)
