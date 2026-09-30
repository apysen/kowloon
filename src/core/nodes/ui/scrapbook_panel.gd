class_name ScrapbookPanel
extends Control

## Mei's scrapbook: a cloth-bound photo album. No completion percentages, no
## empty slots: only the people she has actually photographed, one to a page,
## each Polaroid taped down with the facts and, in her own handwriting, the
## note that matters more.
##
## The book opens on Tab: it rises into view shut, then the cover swings over
## onto the left. A / D (or Q / E, the arrows, or a click on either page)
## turn the pages. Tab or Esc closes it: the left-hand pages fold back under
## the cover and the book drops away. Every turning leaf is drawn by
## page_leaf.gdshader from textures of the pages, rendered here into
## sub-viewports at twice their on-screen size.

const PAGE := Vector2(400, 540)
const POLAROID_PIC := 196.0
const POLAROID_TOP := 26.0
## Mei's pencil, for what she jotted down after asking about it.
const PENCIL := Color("77716a")
const BOARD := Vector2(414, 568)
const RES := 2.0
const TAPE := preload("res://assets/textures/props/tape.png")
const PAGE_L := preload("res://assets/textures/props/album_page_left.png")
const PAGE_R := preload("res://assets/textures/props/album_page_right.png")
const CLOTH := preload("res://assets/textures/props/album_cloth.png")
const COVER := preload("res://assets/textures/props/album_cover.png")
const SND_FLIP := preload("res://assets/audio/page_flip.wav")
const SND_OPEN := preload("res://assets/audio/book_open.wav")
const SND_CLOSE := preload("res://assets/audio/book_close.wav")
const SND_TAPE := preload("res://assets/audio/tape_press.wav")
const SND_PEN := preload("res://assets/audio/pen_scribble.wav")

@onready var dim: ColorRect = %Dim
@onready var book: Control = %Book
@onready var board_left: Control = %BoardLeft
@onready var page_left: TextureRect = %PageLeft
@onready var page_right: TextureRect = %PageRight
@onready var page_leaf: ColorRect = %PageLeaf
@onready var cover_leaf: ColorRect = %CoverLeaf
@onready var viewports: Node = %Viewports
@onready var hint: RichTextLabel = %Hint
@onready var rustle: AudioStreamPlayer = %Rustle

## Opening, closing or turning: input waits.
var busy := false
## Which spread is open (0: the title page and the first person).
var spread := 0
var _pages: Array[SubViewport] = []
var _inside: SubViewport
var _inside_page: TextureRect
var _home := Vector2.ZERO
## While a new photograph is being filed: its page's parts, hidden until placed.
var _fresh := {}
var _filing := false
var _speed := 1.0
## Each photograph's page parts, by page index: {polaroid, pic, glass}.
var _photos := {}
var _hover := -1
## The photograph lifted off the page to look at: {page, dim, card}.
var _zoom := {}


func _ready() -> void:
	add_to_group("input_glyphs")
	visible = false
	_home = book.position
	_leaf(cover_leaf).set_shader_parameter("front_tex", COVER)


func _leaf(r: ColorRect) -> ShaderMaterial:
	return r.material as ShaderMaterial


func spreads() -> int:
	return _pages.size() >> 1


# ----------------------------------------------------------------------------- open and close


func open_book(ids: Array, photos: Dictionary, fresh := "") -> void:
	busy = true
	_build_pages(ids, photos, fresh)
	spread = 0
	page_left.texture = _pages[0].get_texture()
	page_right.texture = _pages[1].get_texture()
	_inside_page.texture = page_left.texture
	# shut, low, and faded out
	_set_left_visible(false)
	page_leaf.visible = false
	cover_leaf.visible = true
	_leaf(cover_leaf).set_shader_parameter("back_tex", _inside.get_texture())
	_leaf(cover_leaf).set_shader_parameter("angle", 0.0)
	hint.modulate.a = 0.0
	dim.modulate.a = 0.0
	book.modulate.a = 0.0
	book.position = _home + Vector2(-BOARD.x * 0.5, 70)
	await get_tree().process_frame      # let the pages render once
	var rise := create_tween().set_parallel()
	rise.tween_property(dim, "modulate:a", 1.0, 0.3)
	rise.tween_property(book, "modulate:a", 1.0, 0.25)
	rise.tween_property(book, "position:y", _home.y, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await rise.finished
	# the cover swings over; the book slides across to sit centred open
	_play(SND_OPEN)
	var swing := create_tween().set_parallel()
	swing.tween_method(_cover_angle, 0.0, PI, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(book, "position:x", _home.x, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await swing.finished
	_set_left_visible(true)
	cover_leaf.visible = false
	_update_hint()
	if not _filing:
		create_tween().tween_property(hint, "modulate:a", 1.0, 0.25)
	busy = false


func close_book() -> void:
	if not _zoom.is_empty():
		await unzoom()
	_set_hover(-1)
	busy = true
	create_tween().tween_property(hint, "modulate:a", 0.0, 0.15)
	# the left-hand pages and the cover fold back over as one
	_inside_page.texture = page_left.texture
	_leaf(cover_leaf).set_shader_parameter("back_tex", _inside.get_texture())
	_cover_angle(PI)
	cover_leaf.visible = true
	await get_tree().process_frame
	_set_left_visible(false)
	get_tree().create_timer(0.36).timeout.connect(_play.bind(SND_CLOSE))
	var shut := create_tween().set_parallel()
	shut.tween_method(_cover_angle, PI, 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	shut.tween_property(book, "position:x", _home.x - BOARD.x * 0.5, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await shut.finished
	var drop := create_tween().set_parallel()
	drop.tween_property(dim, "modulate:a", 0.0, 0.3)
	drop.tween_property(book, "modulate:a", 0.0, 0.25).set_delay(0.05)
	drop.tween_property(book, "position:y", _home.y + 70, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await drop.finished
	for vp in _pages:
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_inside.render_target_update_mode = SubViewport.UPDATE_DISABLED
	busy = false


func _set_left_visible(v: bool) -> void:
	board_left.visible = v
	page_left.visible = v


func _cover_angle(a: float) -> void:
	_leaf(cover_leaf).set_shader_parameter("angle", a)


func _page_angle(a: float) -> void:
	_leaf(page_leaf).set_shader_parameter("angle", a)


func _play(stream: AudioStream) -> void:
	rustle.stream = stream
	rustle.pitch_scale = randf_range(0.95, 1.05)
	rustle.play()


# ----------------------------------------------------------------------------- turning pages


func turn(dir: int) -> void:
	if busy or not visible:
		return
	await _turn(dir)


func _turn(dir: int, secs := 0.6) -> void:
	var target := spread + dir
	if target < 0 or target >= spreads():
		return
	busy = true
	_play(SND_FLIP)
	var m := _leaf(page_leaf)
	var from := 0.0
	var to := PI
	if dir > 0:
		# the right-hand page lifts and turns over; the next spread shows beneath it
		m.set_shader_parameter("front_tex", _pages[spread * 2 + 1].get_texture())
		m.set_shader_parameter("back_tex", _pages[target * 2].get_texture())
		page_right.texture = _pages[target * 2 + 1].get_texture()
	else:
		m.set_shader_parameter("front_tex", _pages[target * 2 + 1].get_texture())
		m.set_shader_parameter("back_tex", _pages[spread * 2].get_texture())
		page_left.texture = _pages[target * 2].get_texture()
		from = PI
		to = 0.0
	_page_angle(from)
	page_leaf.visible = true
	if not _filing:
		create_tween().tween_property(hint, "modulate:a", 0.4, 0.1)
	var t := create_tween()
	t.tween_method(_page_angle, from, to, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	if dir > 0:
		page_left.texture = _pages[target * 2].get_texture()
	else:
		page_right.texture = _pages[target * 2 + 1].get_texture()
	page_leaf.visible = false
	spread = target
	_set_hover(-1)
	_update_hint()
	if not _filing:
		create_tween().tween_property(hint, "modulate:a", 1.0, 0.15)
	busy = false


## The panel covers the screen and stops the mouse, so pointer events arrive
## here rather than as unhandled input. Keys still come through _unhandled_input.
func _gui_input(event: InputEvent) -> void:
	_handle(event)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	_handle(event)


func _handle(event: InputEvent) -> void:
	if not visible:
		return
	if _filing:
		# the player can hurry the filing along, never skip it outright
		if event.is_pressed() and not event.is_echo() and (event.is_action("advance") or event.is_action("interact") or event.is_action("scrapbook")):
			_speed = 3.0
		get_viewport().set_input_as_handled()
		return
	if not _zoom.is_empty():
		# looking at a print: a click, or any of the usual keys, puts it back
		var click := event is InputEventMouseButton and (event as InputEventMouseButton).pressed
		var key := event.is_pressed() and not event.is_echo() and (event.is_action("cancel") or event.is_action("scrapbook")
			or event.is_action("advance") or event.is_action("interact"))
		if click or key:
			unzoom()
		get_viewport().set_input_as_handled()
		return
	# gui events carry the pointer in the panel's own space
	var at := get_global_transform() * (event as InputEventMouse).position if event is InputEventMouse else Vector2.ZERO
	if event is InputEventMouseMotion:
		_set_hover(-1 if busy else _photo_at(at))
		return
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var hit := _photo_at(at)
		if hit >= 0 and not busy:
			zoom(hit)
		else:
			var x := at.x - book.global_position.x
			turn(1 if x > 0.0 else -1)
		get_viewport().set_input_as_handled()
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("move_right") or event.is_action("rotate_right") or event.is_action("ui_right"):
		turn(1)
		get_viewport().set_input_as_handled()
	elif event.is_action("move_left") or event.is_action("rotate_left") or event.is_action("ui_left"):
		turn(-1)
		get_viewport().set_input_as_handled()


func refresh_glyphs() -> void:
	if visible:
		_update_hint()


func _update_hint() -> void:
	# an arrow that can't be used stays, dimmed, so the page count doesn't jump about
	var back := UIStyle.keycaps("[A] ‹") if spread > 0 else "[color=#5a574f] A  ‹[/color]"
	var fwd := UIStyle.keycaps("› [D]") if spread < spreads() - 1 else "[color=#5a574f]›  D [/color]"
	var count := "   %s   " % tr("scrapbook.pages").format({"from": spread * 2 + 1, "to": spread * 2 + 2, "total": _pages.size()})
	hint.text = "[center]%s%s%s        %s[/center]" % [back, count, fwd, UIStyle.keycaps(tr("scrapbook.close"))]


# ----------------------------------------------------------------------------- the pages


## One page per person, after a title page; an even count, so the book ends
## on a full spread.
func _build_pages(ids: Array, photos: Dictionary, fresh := "") -> void:
	for c in viewports.get_children():
		c.queue_free()
	_pages.clear()
	_fresh = {}
	_photos = {}
	_hover = -1
	var kinds: Array[Dictionary] = [{"kind": "title"}]
	for id in ids:
		kinds.append({"kind": "entry", "id": String(id)})
	if ids.is_empty():
		kinds.append({"kind": "empty"})
	if kinds.size() % 2 == 1:
		kinds.append({"kind": "blank"})
	for i in kinds.size():
		var vp := _viewport(PAGE, "Page%d" % (i + 1))
		var root: Control = vp.get_child(0)
		var bg := TextureRect.new()
		bg.texture = PAGE_L if i % 2 == 0 else PAGE_R
		bg.size = PAGE
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		root.add_child(bg)
		var k: Dictionary = kinds[i]
		match String(k.kind):
			"title":
				_title_page(root)
			"entry":
				var parts := _entry_page(root, ResidentCatalog.entry(String(k.id)), photos.get(k.id), i)
				if String(k.id) == fresh:
					# not stuck in yet: the photo, its tape and her writing come in one by one
					parts["page"] = i
					(parts.polaroid as Control).modulate.a = 0.0
					for tape in parts.tapes:
						(tape as Control).modulate.a = 0.0
					for l in parts.labels:
						(l as Label).visible_ratio = 0.0
					_fresh = parts
			"empty":
				_note(root, "scrapbook.empty", Vector2(40, 200), 320, 30, UIStyle.NOTE_INK, HORIZONTAL_ALIGNMENT_CENTER)
		if i > 0:
			var num := _note(root, str(i + 1), Vector2(18 if i % 2 == 0 else PAGE.x - 58, PAGE.y - 36), 40, 20, UIStyle.INK_SOFT,
				HORIZONTAL_ALIGNMENT_LEFT if i % 2 == 0 else HORIZONTAL_ALIGNMENT_RIGHT)
			num.modulate.a = 0.8
		_pages.append(vp)
	# the inside of the front cover, as it swings: cloth, with the first
	# left-hand page mounted on it
	_inside = _viewport(BOARD, "InsideCover")
	var iroot: Control = _inside.get_child(0)
	var cloth := TextureRect.new()
	cloth.texture = CLOTH
	cloth.size = BOARD
	cloth.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iroot.add_child(cloth)
	_inside_page = TextureRect.new()
	_inside_page.position = Vector2(BOARD.x - PAGE.x, (BOARD.y - PAGE.y) * 0.5)
	_inside_page.size = PAGE
	_inside_page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iroot.add_child(_inside_page)


func _viewport(size_px: Vector2, vname: String) -> SubViewport:
	var vp := SubViewport.new()
	vp.name = vname
	vp.size = Vector2i(size_px * RES)
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var root := Control.new()
	root.size = size_px
	root.scale = Vector2(RES, RES)
	root.theme = theme
	vp.add_child(root)
	viewports.add_child(vp)
	return vp


func _note(parent: Control, text: String, pos: Vector2, width: float, size_px: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, font: Font = UIStyle.FONT_HAND) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _title_page(root: Control) -> void:
	_note(root, "scrapbook.title", Vector2(30, 56), 340, 50, UIStyle.NOTE_INK, HORIZONTAL_ALIGNMENT_CENTER)
	_note(root, "九龍城寨 · 一九九二", Vector2(30, 128), 340, 20, UIStyle.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, UIStyle.FONT_SERIF)
	_note(root, "scrapbook.place", Vector2(30, 154), 340, 22, UIStyle.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_note(root, "scrapbook.quote", Vector2(52, 236), 296, 32, UIStyle.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_note(root, "scrapbook.quote_by", Vector2(52, 330), 280, 24, UIStyle.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	# the blue pipe, doodled along the foot of the page
	var pipe := Line2D.new()
	pipe.width = 7.0
	pipe.default_color = UIStyle.PIPE.darkened(0.1)
	pipe.joint_mode = Line2D.LINE_JOINT_ROUND
	pipe.begin_cap_mode = Line2D.LINE_CAP_ROUND
	pipe.end_cap_mode = Line2D.LINE_CAP_ROUND
	for p in [Vector2(40, 482), Vector2(120, 482), Vector2(120, 446), Vector2(250, 446), Vector2(250, 490), Vector2(360, 490)]:
		pipe.add_point(p)
	root.add_child(pipe)
	_note(root, "scrapbook.doodle", Vector2(90, 408), 190, 20, UIStyle.PIPE.darkened(0.25), HORIZONTAL_ALIGNMENT_CENTER)


func _entry_page(root: Control, r: Dictionary, tex: Texture2D, index: int) -> Dictionary:
	var parts := {"polaroid": null, "tapes": [], "labels": []}
	var tilt := -2.4 if index % 2 == 1 else 2.0
	var text := VBoxContainer.new()
	var corners: Array[Vector2] = []
	if ResidentCatalog.NOTE_PAGES.has(String(r.get("id", ""))):
		# no print: a sheet of notepaper taped in, her notes written on it
		var sheet := ColorRect.new()
		sheet.color = Color(0.97, 0.95, 0.88)
		sheet.size = Vector2(PAGE.x - 56.0, 330.0)
		sheet.position = Vector2(28.0, POLAROID_TOP + 14.0)
		sheet.pivot_offset = sheet.size * 0.5
		sheet.rotation_degrees = tilt * 0.5
		root.add_child(sheet)
		for k in 9:
			var rule := ColorRect.new()
			rule.color = Color(0.55, 0.7, 0.85, 0.35)
			rule.size = Vector2(sheet.size.x - 24.0, 1.0)
			rule.position = Vector2(12.0, 58.0 + k * 30.0)
			sheet.add_child(rule)
		corners = [sheet.position + Vector2(18.0, 4.0), sheet.position + Vector2(sheet.size.x - 18.0, 4.0)]
		text.position = Vector2(40, sheet.position.y + 30.0)
	else:
		# the Polaroid, with its shadow on the page, taped at the top corners
		var polaroid := _polaroid_card(root, tex, String(r.name), false)
		polaroid.position = Vector2((PAGE.x - polaroid.size.x) * 0.5, POLAROID_TOP)
		polaroid.rotation_degrees = tilt
		parts.polaroid = polaroid
		var glass := Magnifier.new()
		glass.size = Vector2(48, 48)
		# on the print itself: the card is a container and would stretch it to fill
		glass.position = Vector2(POLAROID_PIC, POLAROID_PIC) * 0.5 - glass.size * 0.5
		glass.visible = false
		(polaroid.get_meta("pic") as Control).add_child(glass)
		_photos[index] = {"polaroid": polaroid, "pic": polaroid.get_meta("pic"), "glass": glass}
		corners = [polaroid.position + Vector2(14.0, 6.0), polaroid.position + Vector2(polaroid.size.x - 14.0, 6.0)]
		# the facts, then her note, then what it was about
		var reach := polaroid.size.x * 0.5 * absf(sin(deg_to_rad(tilt)))
		text.position = Vector2(40, polaroid.position.y + polaroid.size.y + reach + 16.0)
	for k in 2:
		var tape := TextureRect.new()
		tape.texture = TAPE
		tape.size = Vector2(70, 22)
		tape.pivot_offset = tape.size * 0.5
		tape.position = corners[k] - tape.size * 0.5
		tape.rotation_degrees = -38.0 if k == 0 else 36.0
		root.add_child(tape)
		(parts.tapes as Array).append(tape)
	text.size = Vector2(320, PAGE.y - 44.0 - text.position.y)
	text.add_theme_constant_override("separation", 0)
	root.add_child(text)
	# all in her hand: name and details in pen, her note, and the history in pencil
	var specs := [[String(r.name), 30, UIStyle.NOTE_INK, -8]]
	# a place has no occupation: no byline under its name
	if String(r.occupation) != "":
		specs.append([tr("scrapbook.byline").format({"occupation": r.occupation, "location": r.location}), 19, UIStyle.NOTE_INK, -6])
	# added later, in blue: where they went
	if String(r.get("after", "")) != "":
		specs.append([tr("scrapbook.after").format({"after": r.after}), 19, UIStyle.PIPE.darkened(0.25), -6])
	# her note, then anything she wrote under it on a later day; either may be blank for now
	for extra in [[String(r.note), 23], [String(r.get("later", "")), 20]]:
		if extra[0] != "":
			specs.append([extra[0], extra[1], UIStyle.NOTE_INK, -8])
	if String(r.context) != "":
		specs.append([String(r.context), 18, PENCIL, -8])
	for spec in specs:
		var l := Label.new()
		l.text = spec[0]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(320, 0)
		l.size = Vector2(320, 0)
		l.add_theme_font_override("font", UIStyle.FONT_HAND)
		l.add_theme_font_size_override("font_size", spec[1])
		l.add_theme_color_override("font_color", spec[2])
		l.add_theme_constant_override("line_spacing", spec[3])
		text.add_child(l)
		(parts.labels as Array).append(l)
	# a full page: she writes a little smaller rather than run off the bottom
	var fit := 1.0
	while fit > 0.8 and _written_height(parts.labels) > text.size.y:
		fit -= 0.04
		for i in specs.size():
			(parts.labels[i] as Label).add_theme_font_size_override("font_size", roundi(specs[i][1] * fit))
	return parts


## How tall the page's writing runs, wrapped as the labels wrap it.
func _written_height(labels: Array) -> float:
	var total := 0.0
	for l in labels:
		total += (l as Label).get_minimum_size().y
	return total


# ----------------------------------------------------------------------------- filing a new photograph


## A photograph Mei has just kept goes into the album: the Polaroid stays up
## while the book opens beneath it and turns to its page, then it drops into
## place, is taped down, and her notes are written in beside it. The album is
## left open there for the player to look through and close.
## `from` is where the kept Polaroid was on screen.
func file_photo(ids: Array, photos: Dictionary, id: String, from: Rect2) -> void:
	_filing = true
	_speed = 1.0
	var r := ResidentCatalog.entry(id)
	var flyer := _flyer(photos.get(id), String(r.name))
	flyer.scale = Vector2.ONE * (from.size.x / flyer.size.x)
	flyer.global_position = from.get_center() - flyer.size * 0.5
	# held up over the table while the album comes out
	var lift := create_tween().set_parallel()
	lift.tween_property(flyer, "scale", Vector2.ONE * 0.8, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lift.tween_property(flyer, "global_position:y", 40.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lift.tween_property(flyer, "rotation_degrees", -5.0, 0.5)
	await open_book(ids, photos, id)
	busy = true
	var page: int = _fresh.get("page", 1)
	while spread < (page >> 1):
		await _turn(1, 0.5 / _speed)
		busy = true
	# down onto the page, settling at the angle it will be stuck at
	var pol: Control = _fresh.polaroid
	var origin := Vector2(-PAGE.x if page % 2 == 0 else 0.0, -PAGE.y * 0.5)
	var target := book.global_position + origin + pol.position + pol.size * 0.5 - flyer.size * 0.5
	var fly := create_tween().set_parallel()
	fly.tween_property(flyer, "global_position", target, 0.6 / _speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fly.tween_property(flyer, "scale", Vector2.ONE * 1.04, 0.6 / _speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fly.tween_property(flyer, "rotation_degrees", pol.rotation_degrees, 0.6 / _speed)
	await fly.finished
	var press := create_tween()
	press.tween_property(flyer, "scale", Vector2.ONE, 0.1 / _speed)
	await press.finished
	pol.modulate.a = 1.0
	flyer.queue_free()
	# the tape, a strip at each top corner
	for tape in _fresh.tapes:
		var t := tape as Control
		_play(SND_TAPE)
		t.scale = Vector2.ONE * 1.5
		var pop := create_tween().set_parallel()
		pop.tween_property(t, "modulate:a", 1.0, 0.08 / _speed)
		pop.tween_property(t, "scale", Vector2.ONE, 0.16 / _speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.22 / _speed).timeout
	# and her writing, line by line
	for l in _fresh.labels:
		var label := l as Label
		var secs := clampf(label.text.length() * 0.028, 0.25, 1.3) / _speed
		_play(SND_PEN)
		var write := create_tween()
		write.tween_property(label, "visible_ratio", 1.0, secs)
		await write.finished
	# done: the album stays open on the new page until the player shuts it
	_filing = false
	busy = false
	_update_hint()
	create_tween().tween_property(hint, "modulate:a", 1.0, 0.3)
	_set_hover(_photo_at(get_global_mouse_position()))


func _flyer(tex: Texture2D, caption: String) -> Control:
	var card := _polaroid_card(self, tex, caption, true)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


## A Polaroid: the print on its white card, her caption on the strip. Sized
## to exactly what it holds, so the page's copy and the one that flies onto
## it are the same, and the notes can be laid out below it.
func _polaroid_card(parent: Control, tex: Texture2D, caption: String, lifted: bool, pic_px := POLAROID_PIC) -> PanelContainer:
	var k := pic_px / POLAROID_PIC
	var card := PanelContainer.new()
	var sb := UIStyle.panel(Color("fbf8f1"), Color(0, 0, 0, 0), 0, 1, Vector4(10, 10, 10, 6) * k)
	sb.shadow_color = Color(0, 0, 0, 0.4) if lifted else Color(0.2, 0.14, 0.08, 0.28)
	sb.shadow_size = 18 if lifted else 7
	sb.shadow_offset = Vector2(6, 16) if lifted else Vector2(2, 4)
	card.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)
	var pic := TextureRect.new()
	pic.texture = tex
	pic.custom_minimum_size = Vector2(pic_px, pic_px)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	col.add_child(pic)
	var cap := Label.new()
	cap.text = caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_override("font", UIStyle.FONT_HAND)
	cap.add_theme_font_size_override("font_size", roundi(24 * k))
	cap.add_theme_color_override("font_color", UIStyle.INK)
	col.add_child(cap)
	card.set_meta("pic", pic)
	parent.add_child(card)
	card.size = card.get_combined_minimum_size()
	card.pivot_offset = card.size * 0.5
	return card


# ----------------------------------------------------------------------------- looking closer


## Which page's photograph is under this screen point (-1 for none). The pages
## are drawn from sub-viewports, so this is worked out in page space, allowing
## for each Polaroid's tilt.
func _photo_at(p: Vector2) -> int:
	if busy or cover_leaf.visible or page_leaf.visible:
		return -1
	for i in [spread * 2, spread * 2 + 1]:
		if not _photos.has(i):
			continue
		var pol: Control = _photos[i].polaroid
		var origin := book.global_position + Vector2(-PAGE.x if i % 2 == 0 else 0.0, -PAGE.y * 0.5)
		var local := (p - origin - pol.position - pol.pivot_offset).rotated(-pol.rotation) + pol.pivot_offset
		if Rect2(Vector2.ZERO, pol.size).has_point(local):
			return i
	return -1


## Hovering a print dims it a little and shows the magnifying glass.
func _set_hover(i: int) -> void:
	if i == _hover:
		return
	if _photos.has(_hover):
		var old: Dictionary = _photos[_hover]
		(old.pic as CanvasItem).self_modulate = Color.WHITE
		(old.glass as CanvasItem).visible = false
	_hover = i
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	if _photos.has(i):
		var cur: Dictionary = _photos[i]
		(cur.pic as CanvasItem).self_modulate = Color(0.78, 0.78, 0.78)
		var glass := cur.glass as CanvasItem
		glass.visible = true
		glass.modulate.a = 0.0
		create_tween().tween_property(glass, "modulate:a", 0.5, 0.12)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Lift a print off the page and hold it up, straightened, filling the view.
func zoom(i: int) -> void:
	if not _photos.has(i) or not _zoom.is_empty():
		return
	var parts: Dictionary = _photos[i]
	var pol: Control = parts.polaroid
	var pic: TextureRect = parts.pic
	_set_hover(-1)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var caption := ""
	for c in (pic.get_parent() as Node).get_children():
		if c is Label:
			caption = (c as Label).text
	var card := _polaroid_card(self, pic.texture, caption, true, 520.0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# start exactly over the print on the page
	var origin := book.global_position + Vector2(-PAGE.x if i % 2 == 0 else 0.0, -PAGE.y * 0.5)
	var from_center := origin + pol.position + pol.pivot_offset
	var small := pol.size.x / card.size.x
	card.scale = Vector2.ONE * small
	card.rotation = pol.rotation
	card.global_position = from_center - card.size * 0.5
	pol.modulate.a = 0.0
	_zoom = {"page": i, "dim": dim, "card": card, "from": from_center, "small": small, "rot": pol.rotation}
	_play(SND_FLIP)
	var view := get_viewport_rect().size
	var fit := minf(1.0, (view.y - 90.0) / card.size.y)
	var t := create_tween().set_parallel()
	t.tween_property(dim, "color:a", 0.62, 0.3)
	t.tween_property(card, "global_position", view * 0.5 - card.size * 0.5, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale", Vector2.ONE * fit, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "rotation", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hint.visible = false


## Put the print back where it was stuck.
func unzoom() -> void:
	if _zoom.is_empty() or _zoom.has("closing"):
		return
	_zoom["closing"] = true
	var card: Control = _zoom.card
	var dim: ColorRect = _zoom.dim
	var t := create_tween().set_parallel()
	t.tween_property(dim, "color:a", 0.0, 0.25)
	t.tween_property(card, "global_position", (_zoom.from as Vector2) - card.size * 0.5, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(card, "scale", Vector2.ONE * float(_zoom.small), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(card, "rotation", float(_zoom.rot), 0.3)
	await t.finished
	var parts: Dictionary = _photos.get(int(_zoom.page), {})
	if parts.has("polaroid"):
		(parts.polaroid as CanvasItem).modulate.a = 1.0
	card.queue_free()
	dim.queue_free()
	_zoom = {}
	hint.visible = true
	_set_hover(_photo_at(get_global_mouse_position()))


func zoomed() -> bool:
	return not _zoom.is_empty()


## The magnifying glass shown over a print under the pointer: a lens ring with
## a plus in it and a handle, white with a soft shadow, drawn crisp at any size.
class Magnifier extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * Vector2(0.42, 0.42)
		var r := size.x * 0.28
		draw_circle(c, r * 0.95, Color(0.05, 0.05, 0.06, 0.45))
		for pass_i in 2:
			var off := Vector2(2, 3) if pass_i == 0 else Vector2.ZERO
			var col := Color(0, 0, 0, 0.35) if pass_i == 0 else Color(0.98, 0.97, 0.94)
			draw_line(c + off + Vector2(r, r) * 0.74, c + off + Vector2(r, r) * 1.6, col, size.x * 0.16, true)
			draw_arc(c + off, r, 0.0, TAU, 40, col, size.x * 0.11, true)
			var arm := r * 0.5
			draw_line(c + off - Vector2(arm, 0), c + off + Vector2(arm, 0), col, size.x * 0.09, true)
			draw_line(c + off - Vector2(0, arm), c + off + Vector2(0, arm), col, size.x * 0.09, true)
