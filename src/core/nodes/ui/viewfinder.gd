class_name Viewfinder
extends Control

## Looking through Grandfather's camera: a darkened surround, square frame
## corners, a centre reticle that turns sodium yellow when someone who matters
## is framed, and the film counter in the corner.
##
## It also carries Mei's hands (pixel art, fp_hands.png, a sixth of 1080p): the
## camera held up in front of her as she lifts it, then brought to her face,
## growing until its eyepiece fills the view. The iris is the dark moment of
## her eye meeting the eyepiece; after it, only the viewfinder shows.

const HANDS := preload("res://assets/sprites/fp/fp_hands.png")
const ART := Vector2(320, 180)
## Each frame of the sheet runs this far below the screen (the sleeves go on down).
const ART_EXTRA := 40.0
## Frames of fp_hands.png, left to right.
const CARRY := 0
## The eyepiece window, in the art's pixels: the point the camera closes in on.
const EYEPIECE := Vector2(143.5, 99.5)
## How close the camera comes: the eyepiece and the camera's black back fill the screen.
const ZOOM_IN := 16.0

@onready var status: RichTextLabel = %Status

var _status_key := ""
var _status_pad := false
var locked_on := false:
	set(v):
		if v != locked_on:
			locked_on = v
			queue_redraw()
## How much of the frame (surround, corners, reticle, labels) shows.
var frame_alpha := 1.0:
	set(v):
		frame_alpha = v
		for c in get_children():
			if c != _hands and c != _iris:
				(c as CanvasItem).modulate.a = v
		queue_redraw()
## The dark moment of the camera coming to her eye, 0..1.
var iris := 0.0:
	set(v):
		iris = v
		if _iris:
			_iris.color.a = v
var _reticle := 18.0
var _hands: Control
var _iris: ColorRect
var _hand_frame := -1
var _hand_offset := Vector2.ZERO
var _hand_zoom := 1.0


func _ready() -> void:
	visible = false
	_hands = Control.new()
	_hands.name = "Hands"
	_hands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hands.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hands.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hands.draw.connect(_draw_hands)
	add_child(_hands)
	# over the surround and corners, under the film counter and status line
	move_child(_hands, 1)
	_iris = ColorRect.new()
	_iris.name = "Iris"
	_iris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_iris.color = Color(0.02, 0.02, 0.025, 0.0)
	_iris.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_iris)


func open() -> void:
	visible = true
	frame_alpha = 0.0
	create_tween().tween_property(self, "frame_alpha", 1.0, 0.2)


func close() -> void:
	visible = false
	set_hands(-1)


## Show a frame of her hands (CARRY, or -1 for none), `offset` in art pixels
## from where it was drawn (+y lower on the screen). `zoom` above 1 brings the
## camera toward her eye: it grows about its eyepiece, which slides to the
## middle of the screen, until at ZOOM_IN she is looking straight through it.
func set_hands(frame: int, offset := Vector2.ZERO, zoom := 1.0) -> void:
	offset = offset.round()
	if frame == _hand_frame and offset == _hand_offset and is_equal_approx(zoom, _hand_zoom):
		return
	_hand_frame = frame
	_hand_offset = offset
	_hand_zoom = zoom
	if _hands:
		_hands.queue_redraw()


## key: a string key; its [X] keys are drawn as keycaps.
func set_status(key: String) -> void:
	if key == _status_key and _status_pad == InputDevice.using_pad:
		return
	_status_key = key
	_status_pad = InputDevice.using_pad
	status.text = "[center]" + UIStyle.keycaps(tr(UIStyle.control_key(key))) + "[/center]"


func _process(delta: float) -> void:
	var goal := 30.0 if locked_on else 18.0
	if absf(_reticle - goal) > 0.1:
		_reticle = lerpf(_reticle, goal, minf(1.0, delta * 12.0))
		queue_redraw()


func _draw() -> void:
	if frame_alpha <= 0.0:
		return
	var s := size
	var side := minf(s.y * 0.56, s.x * 0.7)
	var c := s * 0.5
	var r := Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side))
	var col := UIStyle.SODIUM if locked_on else Color(0.94, 0.9, 0.82, 0.9)
	col.a *= frame_alpha
	var L := 34.0
	var w := 2.0
	for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var sx := 1.0 if corner.x == r.position.x else -1.0
		var sy := 1.0 if corner.y == r.position.y else -1.0
		draw_line(corner, corner + Vector2(L * sx, 0), col, w)
		draw_line(corner, corner + Vector2(0, L * sy), col, w)
	var ring := UIStyle.SODIUM if locked_on else Color(0.94, 0.9, 0.82, 0.8)
	ring.a *= frame_alpha
	draw_arc(c, _reticle * 0.5, 0, TAU, 40, ring, 1.5, true)


## The square the print is cut from, as a fraction of the screen's height.
func frame_fraction() -> float:
	var s := size
	return minf(s.y * 0.56, s.x * 0.7) / s.y


func _draw_hands() -> void:
	if _hand_frame < 0:
		return
	# a whole-number scale, so every art pixel is the same size on screen,
	# anchored to the bottom of the screen and snapped to whole pixels
	var k := maxf(1.0, floorf(size.y / ART.y))
	var at := (Vector2((size.x - ART.x * k) * 0.5, size.y - ART.y * k) + _hand_offset * k).round()
	var full := ART + Vector2(0, ART_EXTRA)
	if _hand_zoom > 1.0:
		# the eyepiece slides to the middle as the camera comes up to her eye
		var t := clampf(log(_hand_zoom) / log(ZOOM_IN), 0.0, 1.0)
		var eye := (at + EYEPIECE * k).lerp(size * 0.5, sqrt(t))
		at = eye - EYEPIECE * k * _hand_zoom
		k *= _hand_zoom
	_hands.draw_texture_rect_region(HANDS, Rect2(at, full * k), Rect2(Vector2(_hand_frame * ART.x, 0), full))
