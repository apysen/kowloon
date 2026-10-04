class_name DialogueDirector
extends Node

## Runs a conversation: locks the controls, types each line out, advances on
## Space or F, fires a line's event when it appears, and releases the controls
## a moment after the last line so the key that closed it can't also trigger
## an interaction. Lines are string keys (data/i18n/strings.csv), read in the
## current language as they appear; a language change mid-line shows it again.

signal line_shown(speaker: String, text: String)
signal event_fired(event: String)
signal opened
signal closed

const CHARS_PER_SEC := 41.25
## a Chinese character carries about a word: typed at reading pace, not letter pace
const CHARS_PER_SEC_CJK := 18.0

@export var locks: ControlLocks
@export var box: DialogueBox
@export var audio: AudioZones

var history: Array[Dictionary] = []
var _lines: Array = []
var _index := -1
var _on_done: Callable
var _full := ""
var _speaker := ""
var _shown := 0.0
var _typing := false
var _open := false


func is_open() -> bool:
	return _open


## Start a conversation by id (see DialogueCatalog) or with explicit lines.
func start(id_or_lines: Variant, on_done := Callable()) -> void:
	var lines: Array = DialogueCatalog.lines(id_or_lines) if id_or_lines is String else id_or_lines
	if lines.is_empty():
		push_warning("missing dialogue: %s" % [id_or_lines])
		if on_done.is_valid():
			on_done.call()
		return
	locks.lock("dialogue")
	_lines = lines
	_index = -1
	_on_done = on_done
	_open = true
	box.show_box()
	opened.emit()
	_next()


func _next() -> void:
	_index += 1
	if _index >= _lines.size():
		_end()
		return
	var line: Dictionary = _lines[_index]
	var speaker: String = line.get("speaker", "")
	_speaker = speaker
	_full = tr(String(line.text))
	_shown = 0.0
	_typing = true
	box.set_line(speaker, "")
	history.append({"speaker": speaker, "text": _full})
	line_shown.emit(speaker, _full)
	if line.has("event"):
		event_fired.emit(String(line.event))
	if speaker != "" and audio:
		audio.blip(speaker)


func _process(delta: float) -> void:
	if not _open or not _typing:
		return
	_shown = minf(_full.length(), _shown + delta * (CHARS_PER_SEC_CJK if LocaleSettings.is_chinese() else CHARS_PER_SEC))
	box.set_text(_full.substr(0, int(_shown)))
	if _shown >= _full.length():
		_typing = false
		box.set_waiting(true)


func advance() -> void:
	if not _open:
		return
	if _typing:
		_shown = _full.length()
		box.set_text(_full)
		_typing = false
		box.set_waiting(true)
		return
	box.set_waiting(false)
	_next()


## The language changed with a line up (from the pause menu): show it again, whole.
func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or not _open or _index < 0 or _index >= _lines.size():
		return
	_full = tr(String((_lines[_index] as Dictionary).text))
	_shown = _full.length()
	_typing = false
	box.set_line(_speaker, _full)
	box.set_waiting(true)


func _end() -> void:
	_open = false
	box.hide_box()
	closed.emit()
	var done := _on_done
	_on_done = Callable()
	await get_tree().create_timer(0.06).timeout
	locks.unlock("dialogue")
	if done.is_valid():
		done.call()
