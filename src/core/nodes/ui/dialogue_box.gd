class_name DialogueBox
extends Control

## The dialogue box: a dark panel edged in sodium yellow, the speaker's name
## on a tag above it, narration in grey italic, a blinking SPACE when the
## line is fully out.

@onready var panel: PanelContainer = %Panel
@onready var speaker_tag: PanelContainer = %SpeakerTag
@onready var speaker: Label = %Speaker
@onready var text_label: Label = %Text
@onready var nudge: Label = %Nudge

var _style_speech: StyleBox
var _style_narration: StyleBox
var _t := 0.0


func _ready() -> void:
	_style_speech = panel.get_theme_stylebox("panel")
	_style_narration = _style_speech.duplicate()
	(_style_narration as StyleBoxFlat).border_color = Color(0.61, 0.59, 0.55, 0.5)
	visible = false
	modulate.a = 0.0


func show_box() -> void:
	visible = true
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)


func hide_box() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func() -> void: visible = false)


## who: the speaker's id ("" for narration); the tag shows their name.
func set_line(who: String, text: String) -> void:
	speaker.text = tr("speaker." + who).to_upper() if who != "" else ""
	speaker_tag.visible = who != ""
	panel.add_theme_stylebox_override("panel", _style_speech if who != "" else _style_narration)
	text_label.add_theme_font_override("font", UIStyle.FONT_UI_REGULAR if who != "" else UIStyle.FONT_UI_ITALIC)
	text_label.add_theme_color_override("font_color", UIStyle.CONCRETE if who != "" else Color("c9c3b4"))
	set_text(text)
	set_waiting(false)


func set_text(text: String) -> void:
	text_label.text = text


func set_waiting(w: bool) -> void:
	nudge.visible = w


func _process(delta: float) -> void:
	_t += delta
	if nudge.visible:
		nudge.modulate.a = 0.35 + 0.65 * (0.5 + 0.5 * cos(_t * TAU / 1.4))
