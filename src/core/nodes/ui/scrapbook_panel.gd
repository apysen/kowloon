class_name ScrapbookPanel
extends Control

## Mei's scrapbook. No completion percentages, no empty slots: only the people
## she has actually photographed, taped onto ruled paper, each with the facts
## and, in her own handwriting, the note that matters more.

const TAPE := preload("res://assets/textures/props/tape.png")

@onready var entries: GridContainer = %Entries
@onready var empty_label: Label = %Empty


func _ready() -> void:
	visible = false


func render(ids: Array, photos: Dictionary) -> void:
	for c in entries.get_children():
		c.queue_free()
	empty_label.visible = ids.is_empty()
	for i in ids.size():
		var id: String = ids[i]
		var r := ResidentCatalog.entry(id)
		entries.add_child(_entry(r, photos.get(id), -1.8 if i % 2 == 0 else 2.2))


func _entry(r: Dictionary, tex: Texture2D, tilt: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.custom_minimum_size = Vector2(360, 0)
	# the photo, on a white border, taped down
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(150, 170)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIStyle.panel(Color("fbf8f1"), Color(0, 0, 0, 0), 0, 0, Vector4(8, 8, 8, 26)))
	frame.size = Vector2(150, 176)
	frame.pivot_offset = Vector2(75, 88)
	frame.rotation_degrees = tilt
	var pic := TextureRect.new()
	pic.texture = tex
	pic.custom_minimum_size = Vector2(134, 134)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(pic)
	holder.add_child(frame)
	var tape := TextureRect.new()
	tape.texture = TAPE
	tape.size = Vector2(64, 20)
	tape.position = Vector2(43, -10)
	tape.rotation_degrees = -4
	holder.add_child(tape)
	row.add_child(holder)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 6)
	text.add_child(_label(String(r.name).to_upper(), UIStyle.FONT_UI_BOLD, 15, UIStyle.INK))
	text.add_child(_label("%s\n%s" % [r.occupation, r.location], UIStyle.FONT_UI_REGULAR, 13, UIStyle.INK_SOFT))
	text.add_child(_label(r.note, UIStyle.FONT_HAND, 26, UIStyle.NOTE_INK))
	text.add_child(_label(r.context, UIStyle.FONT_UI_REGULAR, 12, UIStyle.INK_SOFT))
	row.add_child(text)
	return row


func _label(t: String, font: Font, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(190, 0)
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	return l
