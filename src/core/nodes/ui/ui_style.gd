class_name UIStyle
extends RefCounted

## The interface palette and type, from the slice's stylesheet: soot,
## concrete, pipe blue, sodium yellow, faded red, and scrapbook paper.

const SOOT := Color("121417")
const SOOT_2 := Color("1c1f23")
const CONCRETE := Color("d9d4c7")
const CONCRETE_DIM := Color("9c978b")
const PIPE := Color("3f86d1")
const SODIUM := Color("e8b04a")
const RED := Color("a8453a")
const PAPER := Color("efe6d2")
const PAPER_EDGE := Color("d8ccb0")
const INK := Color("2a2420")
const INK_SOFT := Color("5d5247")
const NOTE_INK := Color("2b3a66")

const FONT_UI := preload("res://assets/fonts/IBMPlexSansCondensed-Medium.ttf")
const FONT_UI_REGULAR := preload("res://assets/fonts/IBMPlexSansCondensed-Regular.ttf")
const FONT_UI_BOLD := preload("res://assets/fonts/IBMPlexSansCondensed-SemiBold.ttf")
const FONT_UI_ITALIC := preload("res://assets/fonts/IBMPlexSansCondensed-Italic.ttf")
const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-Regular.ttf")
const FONT_HAND := preload("res://assets/fonts/Caveat.ttf")
const FONT_SERIF := preload("res://assets/fonts/NotoSerifTC.ttf")


## "[F] Talk" -> BBCode with keycaps.
static func keycaps(text: String) -> String:
	var re := RegEx.new()
	re.compile("\\[(.+?)\\]")
	var out := ""
	var last := 0
	for m in re.search_all(text):
		out += text.substr(last, m.get_start() - last)
		out += "[font=res://assets/fonts/IBMPlexMono-Regular.ttf][font_size=13][bgcolor=#12141799][outline_size=0][color=#d9d4c7] %s [/color][/outline_size][/bgcolor][/font_size][/font] " % m.get_string(1)
		last = m.get_end()
	out += text.substr(last)
	return out


static func panel(bg: Color, border := Color(0, 0, 0, 0), border_w := 0, radius := 3, pad := Vector4(16, 8, 16, 8)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad.x
	s.content_margin_top = pad.y
	s.content_margin_right = pad.z
	s.content_margin_bottom = pad.w
	s.anti_aliasing = true
	return s
