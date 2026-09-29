class_name Hud
extends Control

## The quiet heads-up layer: the current objective (a reminder, never a
## solution), the one interaction prompt, short tutorial hints that disappear
## once used, and italic notices. It fades away entirely for the camera and
## for the first seconds on the roof.

@onready var objective: Control = %Objective
@onready var obj_main: Label = %ObjMain
@onready var obj_hint: Label = %ObjHint
@onready var prompt_panel: PanelContainer = %PromptPanel
@onready var prompt_label: RichTextLabel = %Prompt
@onready var hint_panel: PanelContainer = %HintPanel
@onready var hint_label: RichTextLabel = %Hint
@onready var notice_label: Label = %Notice

var quiet := false
var _notice_tween: Tween
var _obj_tween: Tween


func _ready() -> void:
	objective.modulate.a = 0.0
	prompt_panel.modulate.a = 0.0
	hint_panel.modulate.a = 0.0
	notice_label.modulate.a = 0.0


func set_objective(main: String, hint: String) -> void:
	if _obj_tween:
		_obj_tween.kill()
	_obj_tween = create_tween()
	_obj_tween.tween_property(objective, "modulate:a", 0.0, 0.25)
	_obj_tween.tween_callback(func() -> void:
		obj_main.text = main
		obj_hint.text = hint
		obj_hint.visible = hint != "")
	_obj_tween.tween_property(objective, "modulate:a", 1.0 if main != "" else 0.0, 0.35)


func show_prompt(text: String) -> void:
	if text != "":
		prompt_label.text = "[center]" + UIStyle.keycaps(text) + "[/center]"
	_fade(prompt_panel, text != "", 0.2)


func show_hint(text: String) -> void:
	if text != "":
		hint_label.text = "[center]" + UIStyle.keycaps(text) + "[/center]"
	_fade(hint_panel, text != "", 0.25)


func notice(text: String, secs := 2.6) -> void:
	notice_label.text = text
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_property(notice_label, "modulate:a", 1.0, 0.4)
	_notice_tween.tween_interval(secs)
	_notice_tween.tween_property(notice_label, "modulate:a", 0.0, 0.4)


func set_quiet(q: bool) -> void:
	quiet = q
	create_tween().tween_property(self, "modulate:a", 0.0 if q else 1.0, 1.2)


func _fade(c: CanvasItem, on: bool, secs: float) -> void:
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", 1.0 if on else 0.0, secs)
