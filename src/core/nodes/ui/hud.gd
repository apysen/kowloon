class_name Hud
extends Control

## The quiet heads-up layer: the current objective (a reminder, never a
## solution), the one interaction prompt, short tutorial hints that disappear
## once used, and italic notices. It fades away entirely for the camera and
## for the first seconds on the roof.
##
## Everything it is given is a string key (data/i18n/strings.csv). Plain labels
## translate themselves; the keycap lines are drawn again if the language changes.

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
var _marker: Control
var _marker_icon: TextureRect
var _marker_kind := ""
var _icons: SpriteSheet
var _icon_textures: Dictionary = {}
var _tutorial: TutorialKeys
var _t := 0.0
var _hint_key := ""
var _photo: Control


func _ready() -> void:
	add_to_group("input_glyphs")
	objective.modulate.a = 0.0
	prompt_panel.modulate.a = 0.0
	hint_panel.modulate.a = 0.0
	notice_label.modulate.a = 0.0
	_build_marker()
	_tutorial = TutorialKeys.new()
	_tutorial.name = "TutorialKeys"
	_tutorial.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial.modulate.a = 0.0
	add_child(_tutorial)


# ----------------------------------------------------------------------------- the icon over what Mei can use


func _build_marker() -> void:
	_icons = SpriteSheet.load_sheet("icons")
	for kind in ["talk", "look", "use"]:
		var frames: Array = []
		for cell in _icons.track(kind, "front").cells:
			var at := AtlasTexture.new()
			at.atlas = _icons.texture
			at.region = Rect2(Vector2(cell) * Vector2(_icons.frame_size), Vector2(_icons.frame_size))
			frames.append(at)
		_icon_textures[kind] = frames
	_marker = Control.new()
	_marker.name = "InteractMarker"
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.modulate.a = 0.0
	add_child(_marker)
	_marker_icon = TextureRect.new()
	_marker_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_marker_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_marker_icon.size = Vector2(48, 48)
	_marker_icon.position = Vector2(-24, -48)
	_marker_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.add_child(_marker_icon)
	var key := Label.new()
	key.name = "Key"
	key.text = UIStyle.pad_name("F")
	key.add_theme_font_override("font", UIStyle.FONT_MONO)
	key.add_theme_font_size_override("font_size", 11)
	key.add_theme_color_override("font_color", UIStyle.CONCRETE)
	key.add_theme_stylebox_override("normal", UIStyle.panel(Color(0.07, 0.078, 0.09, 0.85), Color(UIStyle.CONCRETE, 0.5), 1, 3, Vector4(5, 0, 5, 1)))
	key.position = Vector2(-9, 0)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.add_child(key)


## Show the icon over what Mei can use (kind: talk, look, use), at a screen point.
func show_marker(kind: String, at: Vector2) -> void:
	if kind == "":
		if _marker_kind != "":
			_marker_kind = ""
			create_tween().tween_property(_marker, "modulate:a", 0.0, 0.15)
		return
	if _marker_kind == "":
		create_tween().tween_property(_marker, "modulate:a", 1.0, 0.2)
	_marker_kind = kind
	var frames: Array = _icon_textures[kind]
	_marker_icon.texture = frames[int(_t * 2.4) % frames.size()]
	_marker.position = at.round()


# ----------------------------------------------------------------------------- the perspective tutorial


func tutorial_show() -> void:
	_tutorial.your_turn = false
	create_tween().tween_property(_tutorial, "modulate:a", 1.0, 0.4)


func tutorial_press(dir: int) -> void:
	_tutorial.press(dir)


func tutorial_your_turn() -> void:
	_tutorial.your_turn = true


func tutorial_hide() -> void:
	create_tween().tween_property(_tutorial, "modulate:a", 0.0, 0.5)


func _process(delta: float) -> void:
	_t += delta


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


## text: already in the player's language (InteractionDirector formats it).
func show_prompt(text: String) -> void:
	if text != "":
		prompt_label.text = "[center]" + UIStyle.keycaps(text) + "[/center]"
	_fade(prompt_panel, text != "", 0.2)


func show_hint(key: String) -> void:
	_hint_key = key
	if key != "":
		hint_label.text = "[center]" + UIStyle.keycaps(tr(UIStyle.control_key(key))) + "[/center]"
	_fade(hint_panel, key != "", 0.25)


func notice(key: String, secs := 2.6) -> void:
	notice_label.text = key
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_property(notice_label, "modulate:a", 1.0, 0.4)
	_notice_tween.tween_interval(secs)
	_notice_tween.tween_property(notice_label, "modulate:a", 0.0, 0.4)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh_glyphs()


## The language or the device in hand changed: say the hint again.
func refresh_glyphs() -> void:
	if _hint_key != "":
		hint_label.text = "[center]" + UIStyle.keycaps(tr(UIStyle.control_key(_hint_key))) + "[/center]"
	if _marker:
		(_marker.get_node("Key") as Label).text = UIStyle.pad_name("F")


## A photograph held up close (Grandfather's old one): it fades in over a dimmed
## screen, above the dialogue box, until hide_photo().
func show_photo(tex: Texture2D) -> void:
	if _photo == null:
		_photo = Control.new()
		_photo.name = "PhotoLook"
		_photo.set_anchors_preset(Control.PRESET_FULL_RECT)
		_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.5)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_photo.add_child(dim)
		var shadow := ColorRect.new()
		shadow.name = "Shadow"
		shadow.color = Color(0, 0, 0, 0.45)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_photo.add_child(shadow)
		var pic := TextureRect.new()
		pic.name = "Print"
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_SCALE
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_photo.add_child(pic)
		add_child(_photo)
	var pic: TextureRect = _photo.get_node("Print")
	var shadow: ColorRect = _photo.get_node("Shadow")
	pic.texture = tex
	# as large as fits above the dialogue box, keeping the print's shape
	var view := get_viewport_rect().size
	var h := view.y * 0.56
	var sz := Vector2(h * float(tex.get_width()) / tex.get_height(), h)
	for c: Control in [pic, shadow]:
		c.size = sz
		c.pivot_offset = sz * 0.5
		c.rotation_degrees = -2.0
		c.position = Vector2(view.x * 0.5, view.y * 0.36) - sz * 0.5
	shadow.position += Vector2(8, 12)
	_photo.visible = true
	_photo.modulate.a = 0.0
	create_tween().tween_property(_photo, "modulate:a", 1.0, 0.3)


func hide_photo() -> void:
	if _photo == null or not _photo.visible:
		return
	var tw := create_tween()
	tw.tween_property(_photo, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: _photo.visible = false)


func photo_showing() -> bool:
	return _photo != null and _photo.visible


func set_quiet(q: bool) -> void:
	quiet = q
	create_tween().tween_property(self, "modulate:a", 0.0 if q else 1.0, 1.2)


func _fade(c: CanvasItem, on: bool, secs: float) -> void:
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", 1.0 if on else 0.0, secs)
