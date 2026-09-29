class_name Viewfinder
extends Control

## Looking through Grandfather's camera: a darkened surround, square frame
## corners, a centre reticle that turns sodium yellow when someone who matters
## is framed, and the film counter in the corner.

@onready var status: RichTextLabel = %Status

var locked_on := false:
	set(v):
		if v != locked_on:
			locked_on = v
			queue_redraw()
var _reticle := 18.0


func _ready() -> void:
	visible = false


func open() -> void:
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func close() -> void:
	visible = false


func set_status(bbcode: String) -> void:
	status.text = "[center]" + UIStyle.keycaps(bbcode) + "[/center]"


func _process(delta: float) -> void:
	var goal := 30.0 if locked_on else 18.0
	if absf(_reticle - goal) > 0.1:
		_reticle = lerpf(_reticle, goal, minf(1.0, delta * 12.0))
		queue_redraw()


func _draw() -> void:
	var s := size
	var side := minf(s.y * 0.56, s.x * 0.7)
	var c := s * 0.5
	var r := Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side))
	var col := UIStyle.SODIUM if locked_on else Color(0.94, 0.9, 0.82, 0.9)
	var L := 34.0
	var w := 2.0
	for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var sx := 1.0 if corner.x == r.position.x else -1.0
		var sy := 1.0 if corner.y == r.position.y else -1.0
		draw_line(corner, corner + Vector2(L * sx, 0), col, w)
		draw_line(corner, corner + Vector2(0, L * sy), col, w)
	draw_arc(c, _reticle * 0.5, 0, TAU, 40, UIStyle.SODIUM if locked_on else Color(0.94, 0.9, 0.82, 0.8), 1.5, true)
