extends SceneTree

## Builds and saves the game's scenes and the interface theme.
##
##   godot --headless --path . --script res://tools/scenes/build_scenes.gd
##
## Scenes are assembled here rather than hand-written so every node has the
## right owner, unique names and exported references wired. Rerun after
## changing a layout; the saved .tscn files are what the game loads and what
## the editor shows.

const S := preload("res://src/core/nodes/ui/ui_style.gd")

var _owner: Node


func _initialize() -> void:
	var theme := build_theme()
	_save_res(theme, "res://assets/ui/kowloon_theme.tres")
	_save_scene(build_hud(), "res://scenes/ui/hud/hud.tscn")
	_save_scene(build_dialogue_box(), "res://scenes/ui/dialogue/dialogue_box.tscn")
	_save_scene(build_viewfinder(), "res://scenes/ui/photo/viewfinder.tscn")
	_save_scene(build_polaroid(), "res://scenes/ui/photo/polaroid.tscn")
	_save_scene(build_scrapbook(), "res://scenes/ui/scrapbook/scrapbook.tscn")
	_save_scene(build_ending(), "res://scenes/ui/menus/ending.tscn")
	_save_scene(build_pause(), "res://scenes/ui/menus/pause.tscn")
	_save_scene(build_debug(), "res://scenes/ui/debug/debug_overlay.tscn")
	_save_scene(build_title(), "res://scenes/app/title_screen.tscn")
	_save_scene(build_slice(), "res://scenes/slice/slice.tscn")
	print("scenes built")
	quit(0)


# ----------------------------------------------------------------------------- helpers


func _save_res(r: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := ResourceSaver.save(r, path)
	if err != OK:
		push_error("save %s failed: %s" % [path, err])


func _save_scene(root: Node, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var p := PackedScene.new()
	var err := p.pack(root)
	if err != OK:
		push_error("pack %s failed: %s" % [path, err])
		return
	err = ResourceSaver.save(p, path)
	if err != OK:
		push_error("save %s failed: %s" % [path, err])
	else:
		print("saved ", path)
	root.free()


func add(parent: Node, n: Node, unique := false) -> Node:
	parent.add_child(n, true)
	n.owner = _owner
	if unique:
		n.unique_name_in_owner = true
	return n


func instance(parent: Node, path: String, node_name: String) -> Node:
	var n: Node = load(path).instantiate()
	n.name = node_name
	parent.add_child(n)
	n.owner = _owner
	return n


func full(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func label(text: String, font: Font, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func spaced(font: Font, spacing: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = font
	fv.spacing_glyph = spacing
	return fv


func rich(size_px: int, col: Color) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_override("normal_font", S.FONT_UI)
	r.add_theme_font_size_override("normal_font_size", size_px)
	r.add_theme_color_override("default_color", col)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func shadowed(l: Label, strength := 0.8) -> Label:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, strength))
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_constant_override("shadow_outline_size", 3)
	return l


# ----------------------------------------------------------------------------- theme


func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = S.FONT_UI
	t.default_font_size = 16
	t.set_color("font_color", "Label", S.CONCRETE)
	var btn := S.panel(Color(0, 0, 0, 0), S.SODIUM, 1, 3, Vector4(26, 10, 26, 10))
	var btn_hover := S.panel(Color(S.SODIUM, 0.14), S.SODIUM, 1, 3, Vector4(26, 10, 26, 10))
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_hover)
	t.set_stylebox("focus", "Button", btn_hover)
	t.set_color("font_color", "Button", S.SODIUM)
	t.set_color("font_hover_color", "Button", Color("f3d38e"))
	t.set_color("font_focus_color", "Button", Color("f3d38e"))
	t.set_font("font", "Button", spaced(S.FONT_UI_BOLD, 3))
	t.set_font_size("font_size", "Button", 15)
	# sliders: a thin concrete track that fills sodium yellow, a small square grabber
	var track := S.panel(Color(S.CONCRETE, 0.18), Color(0, 0, 0, 0), 0, 2, Vector4(0, 3, 0, 3))
	var fill := S.panel(S.SODIUM, Color(0, 0, 0, 0), 0, 2, Vector4(0, 3, 0, 3))
	var fill_focus := S.panel(Color("f3d38e"), Color(0, 0, 0, 0), 0, 2, Vector4(0, 3, 0, 3))
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill_focus)
	t.set_stylebox("focus", "HSlider", StyleBoxEmpty.new())
	t.set_icon("grabber", "HSlider", _grabber(S.CONCRETE))
	t.set_icon("grabber_highlight", "HSlider", _grabber(Color("f3d38e")))
	return t


func _grabber(col: Color) -> ImageTexture:
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(1, 13):
		for x in range(3, 11):
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


# ----------------------------------------------------------------------------- HUD


func build_hud() -> Control:
	var root := Hud.new()
	root.name = "Hud"
	_owner = root
	full(root)
	# objective, top left, with the pipe-blue rule beside it
	var obj := add(root, HBoxContainer.new(), true) as HBoxContainer
	obj.name = "Objective"
	obj.position = Vector2(24, 20)
	obj.add_theme_constant_override("separation", 14)
	obj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := add(obj, ColorRect.new()) as ColorRect
	bar.name = "PipeRule"
	bar.color = S.PIPE
	bar.custom_minimum_size = Vector2(3, 0)
	var col := add(obj, VBoxContainer.new()) as VBoxContainer
	col.name = "Text"
	col.add_theme_constant_override("separation", 4)
	var main := shadowed(label("", S.FONT_UI, 17, S.CONCRETE))
	main.name = "ObjMain"
	main.custom_minimum_size = Vector2(380, 0)
	main.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add(col, main, true)
	var h := shadowed(label("", S.FONT_UI_ITALIC, 14, S.CONCRETE_DIM))
	h.name = "ObjHint"
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add(col, h, true)
	# the prompt and the tutorial hint, bottom centre
	for spec in [["PromptPanel", "Prompt", 96.0, S.CONCRETE, Color(0, 0, 0, 0)], ["HintPanel", "Hint", 148.0, S.SODIUM, Color(S.SODIUM, 0.35)]]:
		var holder := add(root, CenterContainer.new()) as CenterContainer
		holder.name = String(spec[0]) + "Row"
		holder.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		holder.anchor_left = 0.0
		holder.anchor_right = 1.0
		holder.offset_left = 0
		holder.offset_right = 0
		holder.offset_top = -float(spec[2]) - 40
		holder.offset_bottom = -float(spec[2])
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pp := add(holder, PanelContainer.new(), true) as PanelContainer
		pp.name = spec[0]
		pp.add_theme_stylebox_override("panel", S.panel(Color(0.07, 0.078, 0.09, 0.72), spec[4], 1 if spec[4].a > 0 else 0, 3, Vector4(16, 7, 16, 7)))
		pp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r := rich(16, spec[3])
		r.name = spec[1]
		r.custom_minimum_size = Vector2(160, 0)
		add(pp, r, true)
	var notice := shadowed(label("", S.FONT_UI_ITALIC, 15, S.CONCRETE), 1.0)
	notice.name = "Notice"
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.set_anchors_preset(Control.PRESET_TOP_WIDE)
	notice.offset_top = 0
	notice.anchor_top = 0.36
	notice.anchor_bottom = 0.36
	add(root, notice, true)
	return root


# ----------------------------------------------------------------------------- dialogue


func build_dialogue_box() -> Control:
	var root := DialogueBox.new()
	root.name = "DialogueBox"
	_owner = root
	full(root)
	var box := add(root, Control.new()) as Control
	box.name = "Box"
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.offset_left = -360
	box.offset_right = 360
	box.offset_top = -150
	box.offset_bottom = -28
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := add(box, PanelContainer.new(), true) as PanelContainer
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := S.panel(Color(0.085, 0.078, 0.1, 0.95), Color(S.SODIUM, 0.6), 1, 6, Vector4(28, 24, 28, 30))
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 10)
	panel.add_theme_stylebox_override("panel", sb)
	var text := label("", S.FONT_UI_REGULAR, 19, S.CONCRETE)
	text.name = "Text"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text.add_theme_constant_override("line_spacing", 5)
	add(panel, text, true)
	var tag := add(box, PanelContainer.new(), true) as PanelContainer
	tag.name = "SpeakerTag"
	tag.position = Vector2(22, -14)
	var tsb := S.panel(S.SODIUM, Color(0, 0, 0, 0), 0, 3, Vector4(12, 3, 12, 3))
	tsb.shadow_color = Color(0, 0, 0, 0.5)
	tsb.shadow_size = 6
	tag.add_theme_stylebox_override("panel", tsb)
	var who := label("", spaced(S.FONT_UI_BOLD, 2), 13, Color("1a1410"))
	who.name = "Speaker"
	add(tag, who, true)
	var nudge := label("SPACE", spaced(S.FONT_MONO, 1), 11, S.CONCRETE_DIM)
	nudge.name = "Nudge"
	nudge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	nudge.offset_left = -64
	nudge.offset_top = -24
	nudge.offset_right = -18
	nudge.offset_bottom = -8
	add(box, nudge, true)
	return root


# ----------------------------------------------------------------------------- camera and photo


func build_viewfinder() -> Control:
	var root := Viewfinder.new()
	root.name = "Viewfinder"
	_owner = root
	full(root)
	var vig := add(root, TextureRect.new()) as TextureRect
	vig.name = "Surround"
	full(vig)
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.6))
	g.add_point(0.52, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 512
	gt.height = 512
	vig.texture = gt
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var film := shadowed(label("●  INSTANT FILM", spaced(S.FONT_MONO, 2), 12, Color(0.94, 0.9, 0.82, 0.75)))
	film.name = "FilmLabel"
	film.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	film.offset_left = -190
	film.offset_top = 22
	film.offset_right = -26
	film.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add(root, film)
	var row := add(root, CenterContainer.new()) as CenterContainer
	row.name = "StatusRow"
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -80
	row.offset_bottom = -40
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := rich(15, S.CONCRETE)
	st.name = "Status"
	st.custom_minimum_size = Vector2(400, 0)
	add(row, st, true)
	return root


func build_polaroid() -> Control:
	var root := PolaroidView.new()
	root.name = "Polaroid"
	_owner = root
	full(root)
	var center := add(root, CenterContainer.new()) as CenterContainer
	center.name = "Center"
	full(center)
	var col := add(center, VBoxContainer.new()) as VBoxContainer
	col.name = "Column"
	col.add_theme_constant_override("separation", 26)
	var card := add(col, PanelContainer.new(), true) as PanelContainer
	card.name = "Card"
	var sb := S.panel(Color("f7f3ea"), Color(0, 0, 0, 0), 0, 0, Vector4(16, 16, 16, 20))
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 30
	sb.shadow_offset = Vector2(0, 16)
	card.add_theme_stylebox_override("panel", sb)
	var inner := add(card, VBoxContainer.new()) as VBoxContainer
	inner.name = "Inner"
	inner.add_theme_constant_override("separation", 12)
	var photo := add(inner, TextureRect.new(), true) as TextureRect
	photo.name = "Photo"
	photo.custom_minimum_size = Vector2(308, 308)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/polaroid.gdshader")
	photo.material = mat
	var cap := label("", S.FONT_HAND, 32, S.INK)
	cap.name = "Caption"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add(inner, cap, true)
	var keep := rich(14, S.CONCRETE)
	keep.name = "Keep"
	add(col, keep, true)
	return root


# ----------------------------------------------------------------------------- scrapbook


func build_scrapbook() -> Control:
	## The album: a dim over the game, the book centred (spine at its origin),
	## its boards, spine and two pages, and the two turning leaves on top.
	var root := ScrapbookPanel.new()
	root.name = "Scrapbook"
	_owner = root
	full(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := add(root, ColorRect.new(), true) as ColorRect
	dim.name = "Dim"
	dim.color = Color(0.03, 0.035, 0.043, 0.8)
	full(dim)
	var book := add(root, Control.new(), true) as Control
	book.name = "Book"
	book.set_anchors_preset(Control.PRESET_CENTER)
	book.position = Vector2(0, -10)
	book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var P := ScrapbookPanel.PAGE
	var B := ScrapbookPanel.BOARD
	var cloth: Texture2D = load("res://assets/textures/props/album_cloth.png")
	# soft shadows the boards cast on the table
	for side in [-1.0, 1.0]:
		var sh := add(book, Panel.new()) as Panel
		sh.name = "ShadowLeft" if side < 0 else "ShadowRight"
		var sb := S.panel(Color(0.12, 0.03, 0.04), Color(0, 0, 0, 0), 0, 6)
		sb.shadow_color = Color(0, 0, 0, 0.55)
		sb.shadow_size = 28
		sb.shadow_offset = Vector2(0, 12)
		sh.add_theme_stylebox_override("panel", sb)
		sh.position = Vector2(-B.x if side < 0 else 0.0, -B.y * 0.5)
		sh.size = B
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var left := add(book, Control.new(), true) as Control
	left.name = "BoardLeft"
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for spec in [["ClothLeft", -B.x, left], ["ClothRight", 0.0, book]]:
		var c := add(spec[2], TextureRect.new()) as TextureRect
		c.name = spec[0]
		c.texture = cloth
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.position = Vector2(spec[1], -B.y * 0.5)
		c.size = B
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the ShadowLeft panel belongs with the left board: shown only when open
	var shl := book.get_node("ShadowLeft")
	book.remove_child(shl)
	left.add_child(shl)
	shl.owner = root
	left.move_child(shl, 0)
	var spine := add(book, ColorRect.new()) as ColorRect
	spine.name = "Spine"
	spine.color = Color(0.2, 0.05, 0.06)
	spine.position = Vector2(-4, -B.y * 0.5)
	spine.size = Vector2(8, B.y)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for spec in [["PageLeft", -P.x], ["PageRight", 0.0]]:
		var pg := add(book, TextureRect.new(), true) as TextureRect
		pg.name = spec[0]
		pg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pg.position = Vector2(spec[1], -P.y * 0.5)
		pg.size = P
		pg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# the edges of the pages beneath: part of the book, so they stay put while a leaf turns
		var stack := add(pg, TextureRect.new()) as TextureRect
		stack.name = "PageStack"
		stack.texture = load("res://assets/textures/props/album_page_stack.png")
		stack.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stack.stretch_mode = TextureRect.STRETCH_SCALE
		stack.flip_h = spec[0] == "PageRight"
		stack.position = Vector2(0.0 if spec[0] == "PageLeft" else P.x - 8.0, 0.0)
		stack.size = Vector2(8, P.y)
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var leaf_shader: Shader = load("res://assets/shaders/page_leaf.gdshader")
	for spec in [["PageLeaf", P], ["CoverLeaf", B]]:
		var size: Vector2 = spec[1]
		var rect := Vector2(size.x * 3.0, size.y * 1.6)
		var leaf := add(book, ColorRect.new(), true) as ColorRect
		leaf.name = spec[0]
		leaf.position = -rect * 0.5
		leaf.size = rect
		leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = leaf_shader
		m.set_shader_parameter("leaf_px", size)
		m.set_shader_parameter("rect_px", rect)
		leaf.material = m
		leaf.visible = false
	var vps := add(root, Node.new(), true) as Node
	vps.name = "Viewports"
	var hint := rich(14, S.CONCRETE_DIM)
	hint.name = "Hint"
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-360, -52)
	hint.custom_minimum_size = Vector2(720, 0)
	hint.size = Vector2(720, 24)
	add(root, hint, true)
	var rustle := add(root, AudioStreamPlayer.new(), true) as AudioStreamPlayer
	rustle.name = "Rustle"
	rustle.volume_db = -4.0
	return root


# ----------------------------------------------------------------------------- ending and debug


func build_ending() -> Control:
	var root := EndingScreen.new()
	root.name = "Ending"
	_owner = root
	full(root)
	var bg := add(root, ColorRect.new()) as ColorRect
	bg.name = "Black"
	bg.color = Color.BLACK
	full(bg)
	var center := add(root, CenterContainer.new()) as CenterContainer
	center.name = "Center"
	full(center)
	var lines := add(center, VBoxContainer.new(), true) as VBoxContainer
	lines.name = "Lines"
	lines.add_theme_constant_override("separation", 18)
	for spec in [["Days", "30 DAYS UNTIL WE LEAVE", spaced(S.FONT_MONO, 4), 15, S.CONCRETE_DIM],
			["Title", "PROJECT KOWLOON", spaced(S.FONT_UI_BOLD, 8), 44, S.CONCRETE],
			["Sub", "VERTICAL SLICE COMPLETE", spaced(S.FONT_UI, 5), 14, S.PIPE]]:
		var l := label(spec[1], spec[2], spec[3], spec[4])
		l.name = spec[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add(lines, l)
	var replay := rich(14, S.CONCRETE_DIM)
	replay.name = "Replay"
	replay.text = "[center]" + S.keycaps("Press [R] to play again") + "[/center]"
	replay.custom_minimum_size = Vector2(300, 0)
	add(lines, replay)
	return root


func build_pause() -> Control:
	var root := PauseMenu.new()
	root.name = "PauseMenu"
	_owner = root
	full(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = load("res://assets/ui/kowloon_theme.tres")
	var dim := add(root, ColorRect.new()) as ColorRect
	dim.name = "Dim"
	dim.color = Color(0.03, 0.035, 0.043, 0.72)
	full(dim)
	var center := add(root, CenterContainer.new()) as CenterContainer
	center.name = "Center"
	full(center)
	var card := add(center, PanelContainer.new()) as PanelContainer
	card.name = "Card"
	card.custom_minimum_size = Vector2(380, 0)
	card.add_theme_stylebox_override("panel", S.panel(Color(S.SOOT, 0.94), Color(S.CONCRETE, 0.16), 1, 4, Vector4(36, 28, 36, 30)))
	var col := add(card, VBoxContainer.new()) as VBoxContainer
	col.name = "Column"
	col.add_theme_constant_override("separation", 14)
	var head := add(col, HBoxContainer.new()) as HBoxContainer
	head.name = "Header"
	head.add_theme_constant_override("separation", 12)
	var rule := add(head, ColorRect.new()) as ColorRect
	rule.name = "PipeRule"
	rule.color = S.PIPE
	rule.custom_minimum_size = Vector2(3, 0)
	var title := label("PAUSED", spaced(S.FONT_UI_BOLD, 6), 22, S.CONCRETE)
	title.name = "Title"
	add(head, title)
	var gap := add(col, Control.new()) as Control
	gap.name = "Gap"
	gap.custom_minimum_size = Vector2(0, 4)
	var resume := add(col, Button.new(), true) as Button
	resume.name = "Resume"
	resume.text = "RESUME"
	# the volume: a label, the slider, and its number
	var vrow := add(col, HBoxContainer.new()) as HBoxContainer
	vrow.name = "VolumeRow"
	vrow.add_theme_constant_override("separation", 14)
	var vl := label("VOLUME", spaced(S.FONT_UI_BOLD, 3), 14, S.CONCRETE_DIM)
	vl.name = "VolumeLabel"
	vl.custom_minimum_size = Vector2(76, 0)
	add(vrow, vl)
	var slider := add(vrow, HSlider.new(), true) as HSlider
	slider.name = "Volume"
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(160, 20)
	var vv := label("80", S.FONT_MONO, 13, S.CONCRETE)
	vv.name = "VolumeValue"
	vv.custom_minimum_size = Vector2(30, 0)
	vv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add(vrow, vv, true)
	var gfx := add(col, Button.new(), true) as Button
	gfx.name = "Graphics"
	gfx.text = "GRAPHICS: FULL"
	var quit := add(col, Button.new(), true) as Button
	quit.name = "Quit"
	quit.text = "QUIT TO TITLE"
	var hint := rich(13, S.CONCRETE_DIM)
	hint.name = "Hint"
	hint.text = "[center]" + S.keycaps("[Esc] resume") + "[/center]"
	add(col, hint)
	var tick := add(root, AudioStreamPlayer.new(), true) as AudioStreamPlayer
	tick.name = "Tick"
	tick.stream = load("res://assets/audio/blip.wav")
	tick.volume_db = -8.0
	return root


func build_debug() -> Control:
	var root := DebugOverlay.new()
	root.name = "DebugOverlay"
	_owner = root
	root.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	root.offset_left = -300
	root.offset_top = 16
	root.offset_right = -16
	root.add_theme_font_override("font", S.FONT_MONO)
	root.add_theme_font_size_override("font_size", 12)
	root.add_theme_color_override("font_color", Color("b8e0c0"))
	root.add_theme_stylebox_override("normal", S.panel(Color(0.04, 0.05, 0.05, 0.82), Color(0, 0, 0, 0), 0, 3, Vector4(12, 10, 12, 10)))
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return root


# ----------------------------------------------------------------------------- title


func build_title() -> Control:
	var root := TitleScreen.new()
	root.name = "TitleScreen"
	_owner = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := add(root, ColorRect.new()) as ColorRect
	bg.name = "Soot"
	bg.color = S.SOOT
	full(bg)
	var backdrop := add(root, TextureRect.new()) as TextureRect
	backdrop.name = "Rooftops"
	full(backdrop)
	backdrop.texture = load("res://assets/ui/title_backdrop.jpg")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(1, 1, 1, 0.55)
	var glow := add(root, TextureRect.new()) as TextureRect
	glow.name = "SodiumGlow"
	full(glow)
	var g := Gradient.new()
	g.set_color(0, Color(S.SODIUM, 0.16))
	g.set_color(1, Color(S.SODIUM, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 1.2)
	gt.fill_to = Vector2(0.5, 0.35)
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var center := add(root, CenterContainer.new()) as CenterContainer
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var row := add(center, HBoxContainer.new()) as HBoxContainer
	row.name = "Row"
	row.add_theme_constant_override("separation", 34)
	var cjk := add(row, PanelContainer.new()) as PanelContainer
	cjk.name = "Seal"
	cjk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cjk.add_theme_stylebox_override("panel", S.panel(Color(0.07, 0.08, 0.09, 0.6), S.RED, 2, 0, Vector4(12, 10, 12, 10)))
	var chars := add(cjk, VBoxContainer.new()) as VBoxContainer
	chars.name = "Characters"
	chars.add_theme_constant_override("separation", 2)
	var serif_bold := FontVariation.new()
	serif_bold.base_font = S.FONT_SERIF
	serif_bold.variation_opentype = {"weight": 700}
	for ch in ["九", "龍", "城", "寨"]:
		var l := label(ch, serif_bold, 54, S.RED)
		l.name = "Char"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add(chars, l)
	var col := add(row, VBoxContainer.new()) as VBoxContainer
	col.name = "Copy"
	col.add_theme_constant_override("separation", 14)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_l := label("PROJECT\nKOWLOON", spaced(S.FONT_UI_BOLD, 5), 60, S.CONCRETE)
	name_l.name = "Name"
	name_l.add_theme_constant_override("line_spacing", -12)
	add(col, name_l)
	var slice_row := add(col, HBoxContainer.new()) as HBoxContainer
	slice_row.name = "SliceName"
	slice_row.add_theme_constant_override("separation", 12)
	var pipe := add(slice_row, ColorRect.new()) as ColorRect
	pipe.name = "Pipe"
	pipe.color = S.PIPE
	pipe.custom_minimum_size = Vector2(38, 6)
	pipe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add(slice_row, label("THE BLUE PIPE", spaced(S.FONT_UI_BOLD, 4), 15, S.PIPE))
	var copy := label("Kowloon Walled City, the last weeks before the move. Grandfather needs his medicine taken to Mrs. Wong. A vertical slice, about fifteen minutes. Headphones help.",
		S.FONT_UI_REGULAR, 15, S.CONCRETE_DIM)
	copy.name = "Blurb"
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.custom_minimum_size = Vector2(400, 0)
	add(col, copy)
	var btn := Button.new()
	btn.name = "Begin"
	btn.text = "BEGIN"
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add(col, btn, true)
	var ctl := rich(13, S.CONCRETE_DIM)
	ctl.name = "Controls"
	ctl.custom_minimum_size = Vector2(440, 0)
	ctl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ctl.text = S.keycaps("[WASD] move   [Q][E] rotate   [F] interact   [C] camera   [TAB] scrapbook   [G] graphics   [F1] debug")
	add(col, ctl)
	return root


# ----------------------------------------------------------------------------- the slice


func build_environment() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/shaders/sky.gdshader")
	sm.set_shader_parameter("panorama", load("res://assets/textures/props/sky_golden.png"))
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.46, 0.44, 0.42)
	e.ambient_light_energy = 0.55
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.25
	e.tonemap_white = 6.0
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_strength = 1.0
	e.glow_bloom = 0.06
	e.glow_hdr_threshold = 0.95
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.set_glow_level(0, 0.0)
	e.set_glow_level(2, 1.0)
	e.set_glow_level(3, 0.8)
	e.set_glow_level(4, 0.5)
	e.ssao_enabled = true
	e.ssao_radius = 1.1
	e.ssao_intensity = 1.8
	e.ssao_power = 1.4
	e.ssil_enabled = true
	e.ssil_radius = 3.0
	e.ssil_intensity = 0.6
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.125, 0.11, 0.1)
	e.fog_depth_begin = 27.0
	e.fog_depth_end = 55.0
	e.fog_depth_curve = 1.2
	e.fog_sky_affect = 0.0
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.018
	e.volumetric_fog_albedo = Color(0.92, 0.84, 0.74)
	e.volumetric_fog_anisotropy = 0.55
	e.volumetric_fog_length = 48.0
	e.volumetric_fog_sky_affect = 0.0
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.05
	e.adjustment_contrast = 1.03
	return e


func build_slice() -> Node3D:
	var root := SliceRoot.new()
	root.name = "SliceRoot"
	_owner = root

	var comps := add(root, Node.new()) as Node
	comps.name = "GameplayComponents"
	var locks := _comp(comps, ControlLocks.new(), "ControlLocks") as ControlLocks
	var display := _comp(comps, DisplaySettings.new(), "DisplaySettings") as DisplaySettings
	var audio_settings := _comp(comps, AudioSettings.new(), "AudioSettings") as AudioSettings
	var quests := _comp(comps, QuestDirector.new(), "QuestDirector") as QuestDirector
	var dialogue := _comp(comps, DialogueDirector.new(), "DialogueDirector") as DialogueDirector
	var interaction := _comp(comps, InteractionDirector.new(), "InteractionDirector") as InteractionDirector
	var photography := _comp(comps, PhotographyDirector.new(), "PhotographyDirector") as PhotographyDirector
	var scrapbook := _comp(comps, Scrapbook.new(), "Scrapbook") as Scrapbook
	var audio := _comp(comps, AudioZones.new(), "AudioZones") as AudioZones

	var env := add(root, WorldEnvironment.new()) as WorldEnvironment
	env.name = "WorldEnvironment"
	env.environment = build_environment()

	var sun := add(root, DirectionalLight3D.new()) as DirectionalLight3D
	sun.name = "Sun"
	sun.position = Vector3(-14, 22, 12)
	sun.look_at_from_position(Vector3(-14, 22, 12), Vector3.ZERO, Vector3.UP)
	sun.light_color = Color(1.0, 0.94, 0.85)
	sun.light_energy = 0.3
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.0
	sun.shadow_blur = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 34.0
	sun.light_angular_distance = 0.8
	sun.light_volumetric_fog_energy = 1.5

	var world := add(root, World.new()) as World
	world.name = "World"
	var level := instance(world, "res://scenes/slice/level.tscn", "Level") as Node3D
	world.level = level
	world.level_data = load("res://data/level/level_data.tres")
	world.environment = env
	world.sun = sun

	var player := add(root, Player.new()) as Player
	player.name = "Player"
	var mei := CharacterSprite.new()
	mei.name = "Sprite"
	mei.sheet_id = "mei"
	mei.show_silhouette = true
	add(player, mei)
	player.locks = locks

	var rig := add(root, CameraRig.new()) as CameraRig
	rig.name = "CameraRig"
	var cam3d := add(rig, Camera3D.new()) as Camera3D
	cam3d.name = "Camera3D"
	cam3d.current = true
	rig.locks = locks
	player.cam = rig

	var studio := add(root, PhotoStudio.new()) as PhotoStudio
	studio.name = "PhotoStudio"
	var scam := add(studio, Camera3D.new()) as Camera3D
	scam.name = "Camera3D"
	studio.world = world

	# the diorama finish, over the 3D view and under the interface
	var post := add(root, CanvasLayer.new()) as CanvasLayer
	post.name = "PostProcess"
	post.layer = 0
	var fx := add(post, ColorRect.new()) as ColorRect
	fx.name = "ScreenFX"
	full(fx)
	var fxm := ShaderMaterial.new()
	fxm.shader = load("res://assets/shaders/screen_fx.gdshader")
	fx.material = fxm

	var ui := add(root, CanvasLayer.new()) as CanvasLayer
	ui.name = "Interface"
	ui.layer = 1
	var hud := instance(ui, "res://scenes/ui/hud/hud.tscn", "Hud") as Hud
	var box := instance(ui, "res://scenes/ui/dialogue/dialogue_box.tscn", "DialogueBox") as DialogueBox
	var vf := instance(ui, "res://scenes/ui/photo/viewfinder.tscn", "Viewfinder") as Viewfinder
	var flash := add(ui, ColorRect.new(), true) as ColorRect
	flash.name = "Flash"
	flash.color = Color(1.0, 0.98, 0.94, 0.0)
	full(flash)
	var polaroid := instance(ui, "res://scenes/ui/photo/polaroid.tscn", "Polaroid") as PolaroidView
	var book := instance(ui, "res://scenes/ui/scrapbook/scrapbook.tscn", "Scrapbook") as ScrapbookPanel
	var fade := ScreenFade.new()
	fade.name = "Fade"
	fade.color = Color(0, 0, 0, 1)
	add(ui, fade)
	full(fade)
	var ending := instance(ui, "res://scenes/ui/menus/ending.tscn", "Ending") as EndingScreen
	var pause := instance(ui, "res://scenes/ui/menus/pause.tscn", "PauseMenu") as PauseMenu
	var debug := instance(ui, "res://scenes/ui/debug/debug_overlay.tscn", "DebugOverlay") as DebugOverlay

	# wiring
	display.environment = env
	display.sun = sun
	display.screen_fx = fx
	dialogue.locks = locks
	dialogue.box = box
	dialogue.audio = audio
	interaction.player = player
	interaction.locks = locks
	photography.locks = locks
	photography.cam = rig
	photography.player = player
	photography.viewfinder = vf
	photography.polaroid = polaroid
	photography.fade = fade
	photography.hud = hud
	photography.audio = audio
	photography.studio = studio
	scrapbook.locks = locks
	scrapbook.panel = book
	scrapbook.photography = photography
	scrapbook.studio = studio
	quests.slice = root
	root.locks = locks
	root.display = display
	root.quests = quests
	root.dialogue = dialogue
	root.interaction = interaction
	root.photography = photography
	root.scrapbook = scrapbook
	root.audio = audio
	root.world = world
	root.player = player
	root.cam = rig
	root.hud = hud
	root.fade = fade
	root.ending = ending
	root.debug = debug
	root.pause = pause
	root.audio_settings = audio_settings
	pause.audio_settings = audio_settings
	pause.display = display
	root.screen_fx = fx
	return root


func _comp(parent: Node, n: Node, node_name: String) -> Node:
	n.name = node_name
	add(parent, n)
	return n
