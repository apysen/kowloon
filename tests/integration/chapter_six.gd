extends SceneTree

## Plays Chapter 6, The Last Roof, from the evening to the end card.
##
##   KOWLOON_CHAPTER=6 godot --path . --script res://tests/integration/chapter_six.gd
##
## Follows the spec's story gates (§50): the leads' crossing can't be solved
## from the default view alone; every section of roof lights comes on; Mrs.
## Wong's card fills her AFTER; the old photograph scene happens; the moment
## Mei doesn't photograph completes both ways (she raises the camera; she does
## nothing) and the shutter never fires; Mr. Ng's last pigeon stays optional.

const C := preload("res://src/core/nodes/quests/chapter_six_director.gd")

var slice: SliceRoot
var q: ChapterSixDirector
var failures := 0


func _initialize() -> void:
	Progress.chapter = 6
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


## Read through whatever comes up until the day reaches `s` (or `limit` runs out).
func until_stage(s: int, limit := 40.0) -> void:
	var t := 0.0
	while q.stage < s and t < limit:
		if slice.dialogue.is_open():
			await read_through()
		await secs(0.2)
		t += 0.2
	await read_through()


func _run() -> void:
	await frames(5)
	q = slice.director as ChapterSixDirector
	expect(q != null, "the slice runs Chapter 6's director")
	if q == null:
		quit(1)
		return
	var w := slice.world
	var R := LevelBuilder.LEVEL_ROOF

	print("-- the last evening")
	expect(w.level.get_node_or_null("ChapterProps/Ch6") != null, "the roof is set for the evening")
	expect(q.lit("Gathering") and q.lit("North") and q.lit("NgCorner"), "the bulbs are on")
	for id in ["grandfather", "mum", "kit", "fanman", "ng", "shopkeeper"]:
		expect(absf((w.residents[id] as Resident).position.y - R) < 0.5, "%s is up on the roof" % id)
	expect(slice.scrapbook.entries.has("kit") and slice.scrapbook.entries.has("wong"), "Kit's and Mrs. Wong's pages, in her notes")
	expect(ResidentCatalog.entry("wong").after == "", "no AFTER on Mrs. Wong's page yet")
	q.start_intro()
	await wait_dialogue(15.0)
	expect(q.stage == C.PHOTO_NG, "Mum: Mr. Ng's packing up his birds")

	print("-- Mr. Ng's birds")
	await place(Vector3(3.6, R, -19.3))
	expect(await interact("ng"), "'One at a time.'")
	await photograph("ng_birds", Vector3(4.6, R, -18.4), w.residents.ng.global_position + Vector3(0, 1.0, 0))
	expect(slice.scrapbook.entries.has("ng_birds"), "Mr. Ng and his birds go in the album")
	await until_stage(C.LIGHTS_OUT, 60.0)
	expect(q.flags.oq07_escaped, "one bird slips out and is gone over the tank")
	expect(q.flags.payoff_wong_address and ResidentCatalog.entry("wong").after != "", "Mrs. Wong's card: her page gains its AFTER")
	expect(q.stage == C.LIGHTS_OUT and not q.lit("Gathering") and not q.lit("North") and not q.lit("NgCorner"), "the lights go out")

	print("-- the last circuit")
	await place(Vector3(10.2, R, -11.2))
	await turn_to(0)
	await secs(0.5)
	expect(await interact("hutLead") and not q.flags.lead_hut, "from the front the lead just goes into the hut")
	var d := await turn_until("lead_hut")
	expect(d == 1 or d == 3, "from the side: out of the back of the hut")
	await turn_to(0)
	await place(w.refs.leadsCross)
	await secs(0.4)
	expect(await interact("mastBoard") and not q.flags.board_mast, "from the default view the crossing can't be told apart")
	d = await turn_until("lead_cross")
	expect(d == 2, "from the north: one climbs to the mast, one drops over the parapet")
	await turn_to(0)
	expect(await interact("wrongBoard") and not q.flags.board_mast, "not that one: it goes down to the Szetos'")
	expect(await interact("mastBoard") and q.flags.board_mast, "plugged in at the foot of the mast")
	await place(Vector3(9.2, R, -18.4))
	d = await turn_until("lead_tank")
	expect(q.flags.lead_tank, "round the tank twice: under the coop's frame")
	await turn_to(0)
	await place(w.refs.lastBoard)
	expect(await interact("lastBoard"), "the last board, by Mr. Ng's old spot")
	await until_stage(C.EVENING, 15.0)
	expect(q.lit("Gathering") and q.lit("North") and q.lit("NgCorner"), "every string of bulbs comes back on")
	expect(q.flags.roof_lights_restored and q.stage == C.EVENING, "'Don't encourage her.'")

	print("-- on the side: Mr. Ng's last pigeon (OQ07)")
	expect(not q.flags.oq07_home, "the lights came on without her: she's optional")
	await place(Vector3(9.2, R, -18.4))
	if not q.flags.oq07_seen:
		d = await turn_until("oq07_seen")
	expect(q.flags.oq07_seen, "behind the tank, on the same bracket as before")
	await turn_to(0)
	expect(await interact("lastPigeon"), "Mei holds out a hand")
	await secs(3.5)
	await place(Vector3(3.6, R, -19.3))
	expect(await interact("ng") and q.flags.optional_ng_last_pigeon, "'You're getting good at this.' 'So are you.'")

	print("-- the evening")
	expect(await interact("ng") and q.flags.payoff_ng_home_line, "Ng: they know this one")
	expect(ResidentCatalog.entry("ng").later != "", "Mr. Ng's page: they will have to learn another")
	await place(Vector3(-3.8, R, -9.9))
	expect(await interact("kit") and ResidentCatalog.entry("kit").later != "", "Kit: 'I'm not going to forget you.'")
	await place(Vector3(-3.3, R, -11.4))
	expect(await interact("mum") and q.talks.has("mum_grandfather"), "Mum and Grandfather: the lift")
	expect(await interact("mum") and q.talks.has("mei_mum"), "'I can miss it and still want to leave.'")
	await place(Vector3(-5.2, R, -10.9))
	expect(await interact("grandfather") and q.flags.payoff_old_photo_camera, "the old photograph: 'Does that bother you?' 'Yes.'")
	expect(q.flags.unknown_photographer_forgotten and slice.scrapbook.entries.has("old_photo"), "on a page of its own in the album")

	print("-- the moment she doesn't take")
	await place(Vector3(-3.0, R, -10.6))
	var t := 0.0
	while q.stage != C.MOMENT and t < 20.0:
		await secs(0.2)
		t += 0.2
	expect(q.stage == C.MOMENT, "everyone laughing, the camera right there")
	var kept := slice.photography.photos.size()
	var pages := slice.scrapbook.entries.size()
	slice.photography.enter()
	await secs(0.3)
	expect(not slice.photography.aiming, "she starts to raise it...")
	await secs(2.0)
	expect(q.flags.mei_chose_presence and not slice.photography.aiming, "...and lowers it herself")
	q.restart_moment()
	await secs(8.0)
	expect(q.flags.mei_chose_presence, "doing nothing: she reaches for it, and lets her hand fall")
	expect(slice.photography.photos.size() == kept and slice.scrapbook.entries.size() == pages, "the shutter never fired")

	print("-- see you")
	t = 0.0
	while not q.is_complete() and t < 40.0:
		if slice.dialogue.is_open():
			await read_through()
		await secs(0.25)
		t += 0.25
	await secs(6.0)
	expect(q.is_complete() and slice.ending.visible, "1 day until we leave")
	expect(Progress.reached() >= 6, "Chapter 6 is remembered as reached")

	print("")
	print("chapter six: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
