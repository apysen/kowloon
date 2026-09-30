class_name TitleScreen
extends Control

## 九龍城寨. The last weeks before the move.

const SLICE_SCENE := "res://scenes/slice/slice.tscn"

@onready var begin_button: Button = %Begin
@onready var continue_button: Button = %Continue
@onready var chapters: HBoxContainer = %Chapters
@onready var fullscreen_button: Button = %Fullscreen
@onready var language_button: Button = %Language
@onready var controls: RichTextLabel = %Controls

var _going := false


func _enter_tree() -> void:
	LocaleSettings.setup()
	DisplaySettings.apply_saved_window()
	var device := InputDevice.new()
	device.name = "InputDevice"
	add_child(device)
	add_to_group("input_glyphs")


func _ready() -> void:
	_label_controls()
	begin_button.pressed.connect(func() -> void: _begin(1))
	# on into the latest day reached, if the player has got past the first
	var reached := Progress.reached()
	continue_button.visible = reached > 1
	continue_button.pressed.connect(func() -> void: _begin(reached))
	_build_chapter_picker()
	fullscreen_button.text = DisplaySettings.fullscreen_label()
	fullscreen_button.pressed.connect(func() -> void:
		DisplaySettings.toggle_fullscreen()
		fullscreen_button.text = DisplaySettings.fullscreen_label())
	language_button.pressed.connect(LocaleSettings.cycle)
	begin_button.grab_focus()
	if continue_button.visible:
		continue_button.grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.2)


## Dev builds only: every chapter can be started directly, whatever has been reached.
func _build_chapter_picker() -> void:
	chapters.visible = OS.is_debug_build()
	if not chapters.visible:
		return
	var tag := Label.new()
	tag.text = "title.dev_chapters"
	tag.add_theme_font_override("font", UIStyle.FONT_MONO)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", UIStyle.CONCRETE_DIM)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chapters.add_child(tag)
	for n in range(1, Progress.LAST + 1):
		var b := Button.new()
		b.name = "Chapter%d" % n
		b.text = tr("title.chapter").format({"n": n})
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func() -> void: _begin(n))
		chapters.add_child(b)


func _label_controls() -> void:
	controls.text = UIStyle.keycaps(tr(UIStyle.control_key("title.controls")))


func refresh_glyphs() -> void:
	_label_controls()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_label_controls()
		for b in chapters.get_children():
			if b is Button:
				b.text = tr("title.chapter").format({"n": int(String(b.name).trim_prefix("Chapter"))})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		_begin(1)


func _begin(chapter: int) -> void:
	if _going:
		return
	_going = true
	Progress.chapter = chapter
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.2)
	await tw.finished
	get_tree().change_scene_to_file(SLICE_SCENE)
