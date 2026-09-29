class_name TutorialKeys
extends Control

## The perspective lesson, without words: two keycaps, Q and E, each with the
## arrow of the way it turns the view. A key lights up when it is used; when
## it is the player's turn both keys breathe until each has been pressed.

var your_turn := false
var _lit := {-1: 0.0, 1: 0.0}
var _done := {-1: false, 1: false}
var _t := 0.0


func press(dir: int) -> void:
	_lit[dir] = 1.0
	if your_turn:
		_done[dir] = true


func _process(delta: float) -> void:
	_t += delta
	for k in _lit:
		_lit[k] = maxf(0.0, _lit[k] - delta * 1.6)
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.72)
	for dir in [-1, 1]:
		var center := c + Vector2(dir * 70.0, 0)
		var lit: float = _lit[dir]
		if your_turn and not _done[dir]:
			lit = maxf(lit, 0.35 + 0.35 * sin(_t * 4.0))
		var face := Color(0.07, 0.078, 0.09, 0.82).lerp(Color(UIStyle.SODIUM, 0.9), lit * 0.6)
		var edge := UIStyle.CONCRETE.lerp(UIStyle.SODIUM, lit)
		var r := Rect2(center - Vector2(26, 24), Vector2(52, 48))
		draw_rect(r.grow(1), Color(0, 0, 0, 0.35))
		draw_rect(r, face)
		draw_rect(r, Color(edge, 0.75), false, 1.5)
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), Color(edge, 0.35))
		var letter := "Q" if dir == -1 else "E"
		var font := UIStyle.FONT_MONO
		var fs := 22
		var tw := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, center + Vector2(-tw * 0.5, 8), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color("1a1410") if lit > 0.5 else UIStyle.CONCRETE)
		# the turn: an arc over the key, arrowhead the way the view goes
		var ac := center + Vector2(0, -44)
		var col := Color(UIStyle.CONCRETE, 0.8).lerp(UIStyle.SODIUM, lit)
		var a0 := PI * 1.15
		var a1 := PI * 1.85
		draw_arc(ac, 22.0, a0, a1, 24, col, 2.5, true)
		var tip_a := a0 if dir == -1 else a1
		var tip := ac + Vector2(cos(tip_a), sin(tip_a)) * 22.0
		var tangent := Vector2(-sin(tip_a), cos(tip_a)) * (1.0 if dir == -1 else -1.0)
		var normal := Vector2(cos(tip_a), sin(tip_a))
		draw_colored_polygon(PackedVector2Array([tip + tangent * 8.0, tip + normal * 6.0, tip - normal * 6.0]), col)
