class_name ControlLocks
extends Node

## Who is holding Mei still.
##
## Several things can stop movement at once: a conversation, the view turning,
## the camera raised, a climb, a fade between floors. Movement is allowed only
## when nothing holds a lock, so no system can accidentally release another's.

signal changed(locked: bool)

var _locks: Dictionary = {}


func lock(reason: String) -> void:
	var was := is_locked()
	_locks[reason] = true
	if not was:
		changed.emit(true)


func unlock(reason: String) -> void:
	var was := is_locked()
	_locks.erase(reason)
	if was and not is_locked():
		changed.emit(false)


func is_locked(reason := "") -> bool:
	if reason != "":
		return _locks.has(reason)
	return not _locks.is_empty()


func reasons() -> Array:
	return _locks.keys()


func clear() -> void:
	_locks.clear()
	changed.emit(false)
