extends SceneTree

## Every string the game shows, checked in both languages.
##
##   godot --headless --path . --script res://tests/localization/strings_check.gd
##
## Reads data/i18n/strings.csv and fails if: a key the code uses is missing; a
## Chinese entry is blank; the English and Chinese disagree on {placeholders}
## or [keycaps]; a Chinese character is missing from the subset fonts (rerun
## scripts/make_cjk_fonts.py); a key is shown untranslated in Chinese; or a
## script still carries English prose instead of a key.

const CSV := "res://data/i18n/strings.csv"
const KEY_PREFIXES := "dlg|speaker|env|verb|notice|hint|obj|res|scrapbook|camera|dialogue|ending|pause|ui|title|prompt"
const SCAN_DIRS: Array[String] = ["res://src", "res://tools/scenes"]
## scripts allowed to hold English: the developer's debug readout
const PROSE_ALLOWED: Array[String] = ["res://src/core/nodes/ui/debug_overlay.gd"]

var failures := 0
var en := {}
var zh := {}


func _initialize() -> void:
	_read_csv()
	_check_pairs()
	_check_used_keys()
	_check_fonts()
	_check_translation_server()
	_check_no_prose()
	print("")
	print("strings: %s (%d keys, %d failures)" % ["PASS" if failures == 0 else "FAIL", en.size(), failures])
	quit(0 if failures == 0 else 1)


func fail(what: String) -> void:
	failures += 1
	print("  FAIL ", what)


func _read_csv() -> void:
	var f := FileAccess.open(CSV, FileAccess.READ)
	var head := f.get_csv_line()
	var en_col := head.find("en")
	var zh_col := head.find("zh_HK")
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 3 or row[0] == "":
			continue
		if en.has(row[0]):
			fail("duplicate key " + row[0])
		en[row[0]] = row[en_col]
		zh[row[0]] = row[zh_col]


func _tokens(text: String, pattern: String) -> Array:
	var re := RegEx.create_from_string(pattern)
	var out := []
	for m in re.search_all(text):
		out.append(m.get_string())
	out.sort()
	return out


func _check_pairs() -> void:
	for key in en:
		var e: String = en[key]
		var z: String = zh[key]
		if z.strip_edges() == "":
			fail("no Chinese for " + key)
			continue
		if _tokens(e, "\\{\\w+\\}") != _tokens(z, "\\{\\w+\\}"):
			fail("placeholders differ in %s: %s / %s" % [key, e, z])
		if _tokens(e, "\\[[^\\]]+\\]") != _tokens(z, "\\[[^\\]]+\\]"):
			fail("keycaps differ in %s: %s / %s" % [key, e, z])
	print("  ok   every key has Chinese, with the same placeholders and keycaps")


func _check_used_keys() -> void:
	var used := {}
	for conv in DialogueCatalog.LINES:
		for line in DialogueCatalog.LINES[conv]:
			used[String(line.text)] = "dialogue " + String(conv)
			if String(line.speaker) != "":
				used["speaker." + String(line.speaker)] = "dialogue " + String(conv)
	for pair in QuestStage.OBJECTIVES.values():
		for k in pair:
			if String(k) != "":
				used[String(k)] = "objectives"
	for id in ResidentCatalog.ENTRIES:
		for field in ResidentCatalog.FIELDS:
			used["res.%s.%s" % [id, field]] = "resident catalog"
	var re := RegEx.create_from_string("\"((?:%s)\\.[a-z0-9_.]+)\"" % KEY_PREFIXES)
	for path in _scripts():
		var src := FileAccess.get_file_as_string(path)
		for m in re.search_all(src):
			used[m.get_string(1)] = path
	for scene in ["res://scenes/app/title_screen.tscn", "res://scenes/ui/menus/pause.tscn", "res://scenes/ui/menus/ending.tscn",
			"res://scenes/ui/dialogue/dialogue_box.tscn", "res://scenes/ui/photo/viewfinder.tscn"]:
		var src := FileAccess.get_file_as_string(scene)
		for m in RegEx.create_from_string("text = \"((?:%s)\\.[a-z0-9_.]+)\"" % KEY_PREFIXES).search_all(src):
			used[m.get_string(1)] = scene
	var missing := 0
	for k in used:
		if not en.has(k):
			fail("key used in %s is not in strings.csv: %s" % [used[k], k])
			missing += 1
	if missing == 0:
		print("  ok   all %d keys the game uses are in strings.csv" % used.size())


func _check_fonts() -> void:
	var fonts := {"Noto Sans TC Regular": LocaleSettings.CJK_REGULAR, "Noto Sans TC Medium": LocaleSettings.CJK_MEDIUM,
		"Noto Sans TC Bold": LocaleSettings.CJK_BOLD, "LXGW WenKai TC": LocaleSettings.CJK_HAND}
	var chars := {}
	for key in zh:
		for ch in String(zh[key]).replace("\\n", ""):
			if ch.unicode_at(0) > 0x2000:
				chars[ch] = true
	for fname in fonts:
		var font: Font = fonts[fname]
		var gaps := ""
		for ch in chars:
			if not font.has_char(ch.unicode_at(0)):
				gaps += ch
		if gaps != "":
			fail("%s is missing %s (run scripts/make_cjk_fonts.py)" % [fname, gaps])
	print("  ok   %d Chinese characters checked against the fonts" % chars.size())


func _check_translation_server() -> void:
	TranslationServer.set_locale("zh_HK")
	var bad := 0
	for key in zh:
		if TranslationServer.translate(key) == key:
			fail("the imported translation doesn't know %s (reimport strings.csv)" % key)
			bad += 1
			if bad > 5:
				break
	if TranslationServer.translate("dlg.grandfather_intro.07") != String(zh["dlg.grandfather_intro.07"]):
		fail("zh_HK doesn't read the Chinese column")
	# the remap loads the Chinese box under the English path: compare what is drawn
	var carton: Texture2D = load("res://assets/textures/props/carton_new_flat.png")
	var carton_zh: Texture2D = load("res://assets/textures/props/carton_new_flat_zh.png")
	if carton.get_image().get_data() != carton_zh.get_image().get_data():
		fail("the Chinese build doesn't swap in Mum's 新屋 carton")
	TranslationServer.set_locale("en")
	if TranslationServer.translate("title.name").find("\n") < 0:
		fail("\\n in strings.csv is not turned into a line break")
	if bad == 0:
		print("  ok   the imported translations match the table")


## English sentences left in scripts: a quoted literal with several words and
## no key, path, BBCode or format syntax.
func _check_no_prose() -> void:
	var re := RegEx.create_from_string("\"([A-Z][a-z']+(?: [A-Za-z',.!?]+){2,}[.!?]?)\"")
	var found := 0
	for path in _scripts():
		if PROSE_ALLOWED.has(path):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var line := lines[i].strip_edges()
			if line.begins_with("#") or line.begins_with("push_") or line.begins_with("print"):
				continue
			for m in re.search_all(line):
				fail("English in %s:%d: %s" % [path, i + 1, m.get_string(1)])
				found += 1
	if found == 0:
		print("  ok   no English prose left in the scripts")


func _scripts() -> Array[String]:
	var out: Array[String] = []
	for dir in SCAN_DIRS:
		_walk(dir, out)
	return out


func _walk(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_walk(dir.path_join(d), out)
