extends SceneTree

## Every registered enclosed room keeps its shell and clears cached foreground
## blockers through all four quarter-turn camera views.

var slice: SliceRoot
var failures := 0


func _initialize() -> void:
	Progress.chapter = 3
	var scene: PackedScene = load("res://scenes/slice/slice.tscn")
	slice = scene.instantiate()
	slice.started = true
	root.add_child(slice)
	_run.call_deferred()


func frames(n := 1) -> void:
	for i in n:
		await process_frame


func expect(value: bool, label: String) -> void:
	if value:
		print("  ok   ", label)
	else:
		failures += 1
		print("  FAIL ", label)


func turn_to(direction: int) -> void:
	while slice.cam.direction != direction:
		slice.cam.rotate_view(1)
		await create_timer(0.5).timeout
	await frames(3)


func shell_is_enclosed(w: World, room_id: String, direction: int) -> bool:
	var foreground_side: String = ["s", "e", "n", "w"][direction]
	var faded := 0
	var solid := 0
	for it in w._live:
		if it.room != room_id or not it.fadeable:
			continue
		if String(it.node.get_parent().name) == "Frames":
			continue
		var should_fade: bool = it.is_lid or String(it.room_side) == foreground_side
		if should_fade:
			faded += 1
			if float(it.opacity) > 0.01:
				return false
		else:
			solid += 1
			if float(it.opacity) < 0.99:
				return false
	return faded > 0 and solid > 0


func view_is_clear(w: World, room_id: String, direction: int) -> bool:
	var key := "%s:%d" % [room_id, direction]
	if not w._room_view_blockers.has(key):
		return false
	for it in w._room_view_blockers[key]:
		if float(it.view_opacity) > 0.01:
			return false
	return true


func ceiling_fixture_counts(w: World, room_id: String) -> Vector2i:
	var total := 0
	var hidden := 0
	for it in w._live:
		if String(it.ceiling_of) != room_id:
			continue
		total += 1
		if float(it.room_opacity) < 0.01:
			hidden += 1
	return Vector2i(hidden, total)


func _run() -> void:
	await frames(6)
	var w: World = slice.world
	var fixture_rooms := 0
	for room in w.level_data.closed_rooms:
		var room_id := String(room.id)
		var rect: Array = room.rects[0]
		var centre := Vector3(
			(float(rect[0]) + float(rect[1])) * 0.5,
			float(room.y),
			(float(rect[2]) + float(rect[3])) * 0.5)
		slice.player.teleport(centre)
		await create_timer(0.55).timeout
		expect(w.current_room == room_id, "%s becomes the active room" % room_id)
		var fixture_counts := ceiling_fixture_counts(w, room_id)
		if fixture_counts.y > 0:
			fixture_rooms += 1
			expect(fixture_counts.x == fixture_counts.y,
				"%s hides all ceiling fixtures (%d/%d)" % [room_id, fixture_counts.x, fixture_counts.y])
		for direction in 4:
			await turn_to(direction)
			expect(shell_is_enclosed(w, room_id, direction),
				"%s remains enclosed at angle %d" % [room_id, direction])
			expect(view_is_clear(w, room_id, direction),
				"%s has no cached foreground obstruction at angle %d" % [room_id, direction])

	expect(fixture_rooms >= 8, "ceiling-fixture coverage spans the enclosed rooms")
	print("\nall room views: %s" % ("PASS" if failures == 0 else "FAIL (%d failures)" % failures))
	quit(0 if failures == 0 else 1)
