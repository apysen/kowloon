extends SceneTree

## Plays The Blue Pipe from Grandfather's first line to the ending.
##
##   godot --path . --script res://tests/integration/playthrough.gd
##
## Drives the real slice scene: places Mei beside each person and object,
## triggers the interaction she would, reads every conversation through,
## takes both photographs, and waits out the Chan boy's errand. Checks the
## story stage after every beat and exits non-zero on the first failure.

const S := preload("res://src/core/models/quests/quest_stage.gd")

var slice: SliceRoot
var failures := 0


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/slice/slice.tscn")
	slice = scene.instantiate()
	slice.started = true
	root.add_child(slice)
	_run.call_deferred()


func frames(n := 1) -> void:
	for i in n:
		await process_frame


func secs(t: float) -> void:
	await create_timer(t).timeout


func expect(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		failures += 1
		print("  FAIL ", what, "   (stage ", S.name_of(slice.quests.stage), ")")


## Read the open conversation to the end.
func read_through() -> void:
	var guard := 0
	while slice.dialogue.is_open() and guard < 200:
		slice.dialogue.advance()
		await frames(2)
		guard += 1
	await secs(0.15)


func place(p: Vector3) -> void:
	slice.player.teleport(p)
	await frames(6)


## Put Mei beside something and use it, as pressing F would.
func use(id: String, at: Vector3) -> void:
	await place(at)
	var found := {}
	for it in slice.interaction._list:
		if it.id == id:
			found = it
	if found.is_empty():
		expect(false, "interaction exists: " + id)
		return
	if not (found.can_interact as Callable).call():
		expect(false, "can interact: " + id)
		return
	(found.interact as Callable).call()
	await frames(3)
	await read_through()


func photograph(id: String, from: Vector3) -> void:
	await place(from)
	var target: Resident = slice.world.residents[id]
	slice.photography.enter()
	await frames(2)
	# pan the frame onto the subject
	var tries := 0
	while slice.photography.subject.is_empty() and tries < 240:
		var to := target.global_position - slice.cam.focus
		to.y = 0
		slice.cam.pan_offset += to.normalized() * minf(0.15, to.length())
		await frames(1)
		tries += 1
	expect(not slice.photography.subject.is_empty(), "framed %s in the viewfinder" % id)
	slice.photography.capture()
	await secs(4.2)
	expect(slice.photography.dismiss(), "kept the Polaroid of " + id)
	await frames(4)
	await read_through()


func _run() -> void:
	await frames(5)
	slice.fade.set_black(false)
	var q := slice.quests
	var w := slice.world
	var A := LevelBuilder.LEVEL_A
	var B := LevelBuilder.LEVEL_B
	var R := LevelBuilder.LEVEL_ROOF

	print("-- the apartment")
	q.start_intro()
	await frames(3)
	await read_through()
	expect(q.stage == S.MEDICINE_RECEIVED, "Grandfather hands over the medicine and the camera")
	expect(slice.photography.has_camera, "Mei has the camera")

	print("-- the dead end and the service door")
	await place(Vector3(1.0, A, 0.0))
	var door := w.door("serviceDoor")
	expect(not door.discovered, "the door is not seen from the starting view")
	slice.cam.rotate_view(-1)
	await secs(0.6)
	expect(door.discovered, "turning the view reveals the service door")
	await use("serviceDoor", Vector3(1.2, A, 0.0))
	expect(door.open, "the door opens")
	slice.cam.rotate_view(1)
	await secs(0.6)

	print("-- Mr. Lau")
	await place(Vector3(3.0, A, -10.2))
	await frames(4)
	await read_through()
	expect(q.stage == S.REACHED_LAU, "Lau asks for a photograph")
	await photograph("lau", Vector3(4.0, A, -10.4))
	expect(q.stage == S.LAU_PHOTO, "Lau's photo is in the scrapbook")
	expect(slice.scrapbook.entries.has("lau"), "scrapbook has Lau")

	print("-- upstairs and the washing")
	await use("stairsUp", w.refs.stairsUpA)
	await secs(1.3)
	expect(slice.player.position.y > 4.0, "Mei climbs to Level B")
	await use("fabric", Vector3(14.6, B, -12.0))
	expect(q.stage == S.CATWALK_BLOCKED, "the washing blocks the catwalk")
	var blocked := slice.world.walk_space.slide(Vector3(15.0, B, -12.0), Vector2(2.0, 0.0), Player.RADIUS)
	expect(blocked.x < 15.8, "Mei can't walk through the wet washing")

	print("-- Mrs. Chan")
	await use("chan", Vector3(-3.4, B, -12.3))
	expect(q.stage == S.SEARCHING_FOR_SON, "Mrs. Chan sends Mei after her son")

	print("-- the airshaft")
	await use("shaftBase", w.refs.shaftBase)
	expect(q.stage == S.SEARCHING_FOR_SON, "no climbing before the handholds are seen")
	await place(Vector3(-5.0, B, -17.6))
	for dir in [3, 1, 2]:
		while slice.cam.direction != dir:
			slice.cam.rotate_view(1)
			await secs(0.55)
		await frames(3)
	for h in w.holds:
		expect(h.discovered, "handhold seen: " + String(h.id))
	await use("shaftBase", w.refs.shaftBase)
	var t := 0.0
	while slice.player.on_path() and t < 20.0:
		await secs(0.25)
		t += 0.25
	await frames(30)
	expect(slice.player.position.y > 12.0, "Mei climbs out onto the roof")
	await secs(1.0)

	print("-- the roof: the Chan boy and Mr. Ng")
	await use("son", Vector3(0.2, R, -18.3))
	expect(q.stage == S.FOUND_SON, "found Chan's son")
	await use("ng", Vector3(3.4, R, -19.5))
	expect(q.ng_briefed, "Mr. Ng explains the lost pigeon")
	# find her: she is behind the tank from the start view
	await place(Vector3(6.0, R, -19.0))
	while slice.cam.direction != 2:
		slice.cam.rotate_view(1)
		await secs(0.55)
	await frames(10)
	expect(q.flags.pigeon_found, "the lost pigeon is spotted behind the tank")
	await use("sheet", w.refs.sheetSpot)
	await secs(4.5)
	await read_through()
	expect(q.stage == S.HELPED_NG, "the pigeon flies home")
	while slice.cam.direction != 0:
		slice.cam.rotate_view(1)
		await secs(0.55)
	await photograph("ng", Vector3(3.6, R, -18.0))
	expect(q.stage == S.FABRIC_MOVED, "Mr. Ng's photo; the Chan boy goes for the washing")

	print("-- the washing moves")
	var son: Resident = w.residents.son
	t = 0.0
	while q.errand.get("step", "") in ["to_door", "downstairs"] and t < 25.0:
		await secs(0.25)
		t += 0.25
	expect(q.flags.roof_door_open, "the Chan boy opens the stuck roof door")
	await use("roofDoorTop", w.refs.roofDoorTop)
	await secs(1.5)
	expect(slice.player.position.y > 4.0 and slice.player.position.y < 12.0, "Mei takes the stairs down")
	await place(Vector3(12.8, B, -12.0))
	t = 0.0
	while w.fabric_state == "catwalk" and t < 30.0:
		await secs(0.25)
		t += 0.25
	expect(w.fabric_state != "catwalk", "the washing comes down in front of Mei")
	var fabric_blocks := false
	for o in slice.world.walk_space.obstacles:
		if o.name == "fabric" and o.is_active():
			fabric_blocks = true
	expect(not fabric_blocks, "the catwalk is clear of washing")

	print("-- Mrs. Wong")
	await use("wong", Vector3(27.4, B, -12.6))
	expect(q.stage == S.MEDICINE_DELIVERED, "the medicine is delivered")

	print("-- home")
	await use("stairsDown", w.refs.stairsDownB)
	await secs(1.3)
	await place(Vector3(-7.2, A, 0.0))
	await secs(1.0)
	await read_through()
	expect(q.stage == S.RETURNED_HOME, "Grandfather at home")
	await use("boxes", w.refs.boxes)
	await secs(1.0)
	expect(q.stage == S.COMPLETE, "the boxes, and the ending")
	t = 0.0
	while w.fabric_state != "roof" and t < 40.0:
		await secs(0.5)
		t += 0.5
	expect(w.fabric_state == "roof", "the washing ends up on the roof line")
	expect(son.position.y > 12.0, "the Chan boy is back on the roof")

	print("")
	print("playthrough: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
