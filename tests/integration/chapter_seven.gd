extends SceneTree

## Plays Chapter 7, The Way Out, from the empty flat to the credits.
##
##   KOWLOON_CHAPTER=7 godot --path . --script res://tests/integration/chapter_seven.gd
##
## Follows the spec's story gates (§50): at least two ways to the yamen; no
## waypoint; the scene with Grandfather is always reachable; the Kwok landmark
## exchange fires on the final walk; the last look back completes only after
## three views, and idling brings "Try another angle." but never finishes it;
## the ending gives Mei a page; the credits are only the prints she took.

const C := preload("res://src/core/nodes/quests/chapter_seven_director.gd")

var slice: SliceRoot
var q: ChapterSevenDirector
var failures := 0


func _initialize() -> void:
	Progress.chapter = 7
	Progress.late_notes = {}
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
		print("  FAIL ", what, "   (stage ", q.stage_name() if q else "?", ")")


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


func interact(id: String) -> bool:
	for it in slice.interaction._list:
		if it.id == id:
			if it.has("can_interact") and not (it.can_interact as Callable).call():
				return false
			(it.interact as Callable).call()
			await frames(3)
			await read_through()
			return true
	return false


func turn_to(dir: int) -> void:
	while slice.cam.direction != dir:
		slice.cam.rotate_view(1)
		await secs(0.6)
	await frames(6)


## Turn the view round until `flag` is set; returns the direction that showed it (-1 if none).
func turn_until(flag: String) -> int:
	for d in [1, 2, 3, 0]:
		await turn_to(d)
		await secs(0.4)
		await read_through()
		if q.flags[flag]:
			return d
	return -1


func wait_dialogue(limit := 10.0) -> void:
	var t := 0.0
	while not slice.dialogue.is_open() and t < limit:
		await secs(0.1)
		t += 0.1
	await read_through()


## Raise the camera at `from`, turn her head onto `at`, and take whatever the
## camera will take there: `id` is what it should be.
func photograph(id: String, from: Vector3, at: Vector3, expect_lock := true) -> void:
	await place(from)
	slice.photography.enter()
	var up := 0.0
	while not slice.photography.aiming and up < 5.0:
		await secs(0.1)
		up += 0.1
	var tries := 0
	while String(slice.photography.subject.get("id", "")) != id and tries < 240:
		var to := at - slice.cam.camera.global_position
		slice.cam.fp_yaw = lerp_angle(slice.cam.fp_yaw, atan2(-to.x, -to.z), 0.3)
		slice.cam.fp_pitch = lerpf(slice.cam.fp_pitch, atan2(to.y, Vector2(to.x, to.z).length()), 0.3)
		await frames(1)
		tries += 1
	expect(String(slice.photography.subject.get("id", "")) == id, "the camera will take %s" % id)
	expect(slice.photography.viewfinder.locked_on == expect_lock,
		"the viewfinder %s" % ("goes yellow" if expect_lock else "stays plain: nothing to lock on"))
	slice.photography.capture()
	var w8 := 0.0
	while not slice.scrapbook.open and w8 < 12.0:
		await secs(0.1)
		w8 += 0.1
	var t := 0.0
	while (slice.scrapbook.panel._filing or slice.scrapbook.panel.busy) and t < 20.0:
		await secs(0.25)
		t += 0.25
	await secs(1.0)
	await slice.scrapbook.toggle(false)
	await read_through()


func _run() -> void:
	await frames(5)
	q = slice.director as ChapterSevenDirector
	expect(q != null, "the slice runs Chapter 7's director")
	if q == null:
		quit(1)
		return
	var w := slice.world
	var R := LevelBuilder.LEVEL_ROOF

	print("-- the last day")
	expect(w.level.get_node_or_null("ChapterProps/Ch1-6") == null and w.level.get_node_or_null("ChapterProps/Ch7") != null,
		"the flat is nearly empty: his chair, a suitcase, a box")
	expect(w.residents.fanman.gone and w.residents.ng.gone and w.residents.shopkeeper.gone, "almost everyone has gone")
	q.start_intro()
	await wait_dialogue(15.0)
	expect(q.stage == C.FIND, "Mum: have you seen Grandpa?")
	expect(q.objective == "c7.obj.find" and q.hint == "", "Find Grandfather: no hint, no waypoint")

	print("-- the ways to the yamen")
	var gate := w.walk_space.slide(Vector3(1.0, 0, 5.1), Vector2(3.0, 0), Player.RADIUS)
	expect(gate.x > 3.5, "the lane, past the open gate")
	var turn := w.walk_space.slide(Vector3(3.0, 0, -7.0), Vector2(3.0, 0), Player.RADIUS)
	expect(turn.x > 5.6, "past Kwok's stall, the side passage stands open")
	var strip := w.walk_space.slide(Vector3(5.95, 0, -6.9), Vector2(0, 4.8), Player.RADIUS)
	expect(strip.z > -2.6, "down the strip beside the yamen hall into the courtyard")
	await place(w.refs.ngLadderTop)
	expect(await interact("ngLadderDown"), "or down Mr. Ng's old ladder from the roof")
	await secs(1.6)
	expect(slice.player.position.y < 0.5 and slice.player.position.x > 5.4 and slice.player.position.x < 6.5, "into the same strip")

	print("-- the yamen")
	await place(Vector3(8.9, 0, 2.2))
	await wait_dialogue(6.0)
	expect(q.flags.found, "he's sitting in the courtyard. 'I know.'")
	var t := 0.0
	while q.stage != C.GO_HOME and t < 20.0:
		if slice.dialogue.is_open():
			await read_through()
		await secs(0.2)
		t += 0.2
	expect(q.flags.said_it and q.stage == C.GO_HOME, "'I don't want to go.' 'Neither do I.'")
	expect(q.hint == "", "Go home: still no hint")

	print("-- the walk home")
	await place(Vector3(3.0, 0, -3.0))
	await secs(1.0)
	await place(Vector3(0.0, 0, 0.0))
	await wait_dialogue(6.0)
	expect(q.flags.payoff_grandfather_navigation, "'You're going the wrong way.' 'I was checking.' 'If you knew.'")
	await place(Vector3(-8.5, 0, 0.5))
	await wait_dialogue(6.0)
	expect(q.flags.home and q.stage == C.WAY_OUT, "Mum: the truck's on Lung Chun Road. Take the case")

	print("-- the way out")
	await place(Vector3(-3.0, 0, 0.0))
	await secs(0.5)
	await place(Vector3(0.6, 0, 0.0))
	await wait_dialogue(6.0)
	expect(q.flags.payoff_kwok_landmark, "'After Kwok.' 'Where Kwok used to be.'")
	await place(Vector3(8.6, 0, 5.5))
	await secs(0.5)
	expect(q.stage == C.LOOK_BACK, "at the yamen's mouth")
	slice.player.facing = Vector3(0, 0, -1)
	t = 0.0
	while not slice.photography.aiming and t < 6.0:
		await secs(0.1)
		t += 0.1
	expect(slice.photography.aiming and q.flags.looked_back, "she looks back, and the camera comes up by itself")
	slice.cam.fp_yaw = 0.0
	await secs(12.5)
	await read_through()
	expect(q.nudges >= 1 and q.stage == C.LOOK_BACK, "standing still: 'Try another angle.' And nothing finishes by itself")
	slice.photography.capture()
	await secs(0.5)
	expect(not slice.photography.showing_photo, "the shutter won't go: it's only framing")
	slice.cam.fp_yaw = PI / 2.0
	await secs(0.6)
	expect(q.stage == C.LOOK_BACK, "two sides: still doesn't fit")
	slice.cam.fp_yaw = PI
	await secs(0.6)
	await read_through()
	expect(q.flags.payoff_perspective_theme, "three sides: 'It doesn't fit.' 'Of course not.'")

	print("-- the last photograph")
	t = 0.0
	while not slice.scrapbook.open and t < 30.0:
		if slice.dialogue.is_open():
			await read_through()
		await secs(0.2)
		t += 0.2
	expect(q.flags.final_photo_mei and slice.scrapbook.entries.has("mei"), "Grandfather takes her picture: MEI, in the album")
	expect(ResidentCatalog.entry("mei").note != "", "'Knew every way home.' in his hand")
	t = 0.0
	while (slice.scrapbook.panel._filing or slice.scrapbook.panel.busy) and t < 20.0:
		await secs(0.25)
		t += 0.25
	await secs(1.0)
	await slice.scrapbook.toggle(false)

	print("-- we left")
	var credits := q.credit_ids()
	expect(credits.has("mei") and not credits.has("old_photo") and not credits.has("kit"), "the credits: only prints actually taken")
	for id in credits:
		expect(slice.photography.photos.has(id), "%s was taken" % id)
	t = 0.0
	while not q.is_complete() and t < 120.0:
		await secs(0.5)
		t += 0.5
	expect(q.is_complete(), "WE LEFT.")
	expect(Progress.reached() >= 7, "Chapter 7 is remembered as reached")
	var _r := R

	print("")
	print("chapter seven: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
