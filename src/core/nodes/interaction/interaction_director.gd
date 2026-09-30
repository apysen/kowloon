class_name InteractionDirector
extends Node

## What Mei can interact with right now, and the one prompt that says so.
##
## Priority: NPC dialogue, then quest objects, then environmental
## descriptions, then decoration. Only one prompt shows at a time, and the
## same verb is used from every side.

enum Priority { NPC, QUEST, ENV, DECOR }

signal prompt_changed(text: String)

@export var player: Player
@export var locks: ControlLocks

var current: Dictionary = {}
var enabled := true
var _list: Array[Dictionary] = []
var _prompt := ""


## def: id, position (Vector3 or Callable), radius, priority, verb (a string key,
##      or a Callable returning one), can_interact (Callable), interact (Callable)
func add(def: Dictionary) -> Dictionary:
	var item := {"radius": 1.5, "priority": Priority.ENV, "verb": "verb.look",
		"can_interact": func() -> bool: return true}
	item.merge(def, true)
	_list.append(item)
	return item


func position_of(item: Dictionary) -> Variant:
	var p: Variant = item.position
	if p is Callable:
		return (p as Callable).call()
	return p


func _process(_delta: float) -> void:
	current = {}
	if not enabled or locks.is_locked():
		_set_prompt("")
		return
	var p := player.position
	var best: Dictionary = {}
	var best_pri := 99
	var best_d := INF
	for it in _list:
		if not (it.can_interact as Callable).call():
			continue
		var pos: Variant = position_of(it)
		if pos == null:
			continue
		var v := pos as Vector3
		if absf(v.y - p.y) > 1.5:
			continue
		var d := Vector2(v.x - p.x, v.z - p.z).length()
		if d > float(it.radius):
			continue
		var pri := int(it.priority)
		if pri < best_pri or (pri == best_pri and d < best_d):
			best = it
			best_pri = pri
			best_d = d
	current = best
	if best.is_empty():
		_set_prompt("")
	else:
		var verb: Variant = best.verb
		var key := String((verb as Callable).call()) if verb is Callable else String(verb)
		_set_prompt(tr("prompt.interact").format({"verb": tr(key)}))


func trigger() -> void:
	if current.is_empty() or locks.is_locked():
		return
	var it := current
	current = {}
	_set_prompt("")
	(it.interact as Callable).call()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_prompt = ""      # said again, in the new language, next frame


func _set_prompt(text: String) -> void:
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)
