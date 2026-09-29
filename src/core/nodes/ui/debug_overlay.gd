class_name DebugOverlay
extends Label

## F1 (or `) toggles it. While it is open: 1-6 teleport, F2 / ] next quest
## stage, F3 / [ previous. Also records the playtest timing marks.

var slice: SliceRoot
var _frames := 0
var _acc := 0.0
var _fps := 0


func _ready() -> void:
	visible = false


func _process(delta: float) -> void:
	_frames += 1
	_acc += delta
	if _acc >= 0.5:
		_fps = roundi(_frames / _acc)
		_frames = 0
		_acc = 0.0
	if not visible or slice == null:
		return
	var p := slice.player.position
	var q := slice.quests
	var cur: String = slice.interaction.current.get("id", "none")
	var t := ""
	for k in q.timings:
		var v: float = q.timings[k]
		t += "\n%-15s %d:%02d" % [k, int(v / 60.0), int(fmod(v, 60.0))]
	text = "X: %.1f\nY: %.1f\nZ: %.1f\n\nCamera: %s\nQuest: %s\nObjective: %s\nInteractable: %s\nLocks: %s\nFPS: %d\n\n1-6 teleport · F2/] next · F3/[ back%s" % [
		p.x, p.y, p.z, ViewMath.DIRECTION_NAMES[slice.cam.direction], QuestStage.name_of(q.stage),
		q.objective if q.objective != "" else "-", cur, ", ".join(slice.locks.reasons()) if not slice.locks.reasons().is_empty() else "none",
		_fps, ("\n\nTimings" + t) if t != "" else ""]
