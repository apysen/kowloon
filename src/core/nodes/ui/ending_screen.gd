class_name EndingScreen
extends Control

## The end of a day: black, then the lines, one at a time. The countdown, the
## chapter's name, and either the way on into the next day or back to the title.

@onready var lines: VBoxContainer = %Lines
@onready var days: Label = lines.get_node("Days")
@onready var sub: Label = lines.get_node("Sub")
@onready var replay: RichTextLabel = %Replay

var can_continue := false
var _replay_key := ""


func _ready() -> void:
	visible = false
	add_to_group("input_glyphs")


## days: until the move; chapter_key: the chapter's name (a string key);
## continues: whether there is a next day to go on to.
func play(days_left: int, chapter_key: String, continues: bool) -> void:
	days.text = LocaleSettings.days_until(days_left)
	sub.text = chapter_key
	can_continue = continues
	_replay_key = "ending.continue" if continues else "ending.replay"
	refresh_glyphs()
	visible = true
	for l in lines.get_children():
		(l as CanvasItem).modulate.a = 0.0
	var first := true
	for l in lines.get_children():
		await get_tree().create_timer(0.8 if first else 2.6).timeout
		first = false
		create_tween().tween_property(l, "modulate:a", 1.0, 1.4)


func refresh_glyphs() -> void:
	if _replay_key != "":
		replay.text = "[center]" + UIStyle.keycaps(tr(UIStyle.control_key(_replay_key))) + "[/center]"


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh_glyphs()
