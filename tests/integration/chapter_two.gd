extends SceneTree

## Plays Chapter 2, The Water Line, from the cold open to the end card.
##
##   KOWLOON_CHAPTER=2 godot --path . --script res://tests/integration/chapter_two.gd
##
## Follows the spec's story gates (§50): the right pipe can only be told apart
## by turning the view; the wrong valves recover by themselves; the water comes
## back; Ho's last word is said once; the photograph of him is optional.

const C := preload("res://src/core/nodes/quests/chapter_two_director.gd")

var slice: SliceRoot
var q: ChapterTwoDirector
var failures := 0


func _initialize() -> void:
	Progress.chapter = 2
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
			if not (it.can_interact as Callable).call():
				return false
			(it.interact as Callable).call()
			await frames(3)
			await read_through()
			return true
	return false


## Turn the view round until `flag` is set; returns the direction that showed it (-1 if none).
func turn_until(flag: String) -> int:
	for d in [1, 2, 3, 0]:
		await turn_to(d)
		await secs(0.4)
		await read_through()
		if q.flags[flag]:
			return d
	return -1


func turn_to(dir: int) -> void:
	while slice.cam.direction != dir:
		slice.cam.rotate_view(1)
		await secs(0.6)
	await frames(6)


## Raise the camera, turn her head onto `who`, and keep the print.
func photograph(who: String, from: Vector3) -> void:
	await place(from)
	var target: Resident = slice.world.residents[who]
	slice.photography.enter()
	var up := 0.0
	while not slice.photography.aiming and up < 5.0:
		await secs(0.1)
		up += 0.1
	var tries := 0
	while slice.photography.subject.is_empty() and tries < 240:
		var to := target.global_position + Vector3(0, 1.0, 0) - slice.cam.camera.global_position
		slice.cam.fp_yaw = lerp_angle(slice.cam.fp_yaw, atan2(-to.x, -to.z), 0.3)
		slice.cam.fp_pitch = lerpf(slice.cam.fp_pitch, atan2(to.y, Vector2(to.x, to.z).length()), 0.3)
		await frames(1)
		tries += 1
	expect(not slice.photography.subject.is_empty(), "framed %s in the viewfinder" % who)
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
	q = slice.director as ChapterTwoDirector
	expect(q != null, "the slice runs Chapter 2's director")
	if q == null:
		quit(1)
		return
	var w := slice.world
	var B := LevelBuilder.LEVEL_B

	print("-- the flat, no water")
	var boxes := w.level.get_node_or_null("ChapterProps/Ch2")
	expect(boxes != null, "more boxes packed than yesterday (Chapter 2's props are in)")
	expect(w.level.get_node_or_null("ChapterProps/Ch2-4/RedBowl") != null, "the red bowl is on the counter")
	expect(slice.scrapbook.entries.has("lau") and slice.scrapbook.entries.has("ng"), "yesterday's prints come along in the scrapbook")
	expect(w.door("serviceDoor").open and w.fabric_state == "roof", "the world is as yesterday left it")
	q.start_intro()
	await secs(5.5)
	await read_through()
	expect(q.stage == C.FIND_HO, "the cold open: the pump, and 'find Ho'")
	expect(q.flags.setup_red_bowl, "the red bowl is set up for later")
	var ho: Resident = w.residents.fanman
	expect(ho.idle_anim == "listen", "Ho is up on his stool, listening to the pipe")
	await place(Vector3(-8.2, 0, -2.6))
	expect(await interact("tap"), "the dry tap can be looked at")

	print("-- Mr. Ho")
	await place(Vector3(-3.0, 0, 0.35))
	expect(await interact("fanman"), "Ho can be talked to")
	expect(q.stage == C.TRACE, "Ho: follow the blue branch until it stops being blue")

	print("-- which pipe")
	await place(Vector3(13.0, B, -12.0))
	await turn_to(0)
	await secs(1.0)
	expect(q.stage == C.TRACE, "from the front the two pipes can't be told apart")
	await turn_to(1)
	await secs(0.5)
	await read_through()
	expect(q.stage == C.TRACED_BRANCH and q.flags.water_trace_1, "from the side, the blue one plainly crosses the well")

	print("-- across the well")
	await turn_to(0)
	await place(Vector3(17.7, B, -14.5))
	expect(slice.world.walk_space.slide(Vector3(17.7, B, -13.5), Vector2(0, -2.0), Player.RADIUS).z < -15.0, "the footbridge can be walked across")
	await place(Vector3(16.0, B, -16.8))
	await secs(0.5)
	expect(q.stage == C.TRACED_BRANCH, "from the front the air-conditioners hide where it goes")
	await turn_to(3)
	await secs(0.5)
	await read_through()
	expect(q.stage == C.TRACED_WELL, "from the side: past Mrs. Fong's tap, into the flat next door")

	print("-- the empty flat")
	await turn_to(0)
	await place(Vector3(20.9, B, -16.8))
	expect(await interact("chainedDoor"), "the chained door can be tried")
	expect(q.stage == C.TRACED_WELL, "the door stays shut")
	await place(Vector3(24.75, B, -19.2))
	await secs(0.5)
	expect(not q.flags.window_found, "the back window is edge-on from the front")
	var shown := false
	for it in slice.interaction._list:
		if it.id == "unitWindow" and (it.can_interact as Callable).call():
			shown = true
	expect(not shown, "no prompt for a window she hasn't seen")
	await secs(3.5)
	await turn_to(1)
	await secs(0.5)
	expect(q.flags.window_found, "from the side, the back kitchen window is open")
	await place(Vector3(24.75, B, -19.2))
	expect(await interact("unitWindow"), "she climbs in")
	await secs(1.5)
	await read_through()
	expect(q.stage == C.IN_UNIT and slice.player.position.x < 24.0, "inside the flat next door")

	print("-- the valves")
	await turn_to(0)
	var vz := BuildLightWell.MANIFOLD_Z + 0.45
	await place(Vector3(BuildLightWell.VALVE_X[0], B, vz))
	expect(await interact("valve0"), "the first valve turns")
	expect(not q.flags.water_restored, "...floods a neighbour's shower; not that one")
	await secs(0.5)
	await place(Vector3(BuildLightWell.VALVE_X[1], B, vz))
	expect(await interact("valve1"), "the second valve turns")
	await secs(1.8)
	expect(not q.flags.water_restored, "...brown water in the old sink; not that one either")
	await place(Vector3(BuildLightWell.VALVE_X[2], B, vz))
	expect(await interact("valve2"), "the third valve turns")
	expect(q.stage == C.WATER_BACK and q.flags.water_restored, "the water comes back")
	expect(ho.idle_anim == "wash", "Ho is washing his hands at the bucket")

	print("-- telling Ho")
	await place(Vector3(24.75, B, -19.2))
	await place(Vector3(-4.2, 0, 0.2))
	expect(await interact("fanman"), "Ho is told")
	expect(q.stage == C.PHOTO_HO and q.flags.ho_restored_talk, "'Won't be anybody here.'")
	await interact("fanman")
	expect(q.stage == C.PHOTO_HO, "his last word is said once")

	print("-- Mr. Ho's photograph")
	await photograph("fanman", Vector3(-3.7, 0, 0.2))
	expect(slice.scrapbook.entries.has("ho"), "Mr. Ho's print is in the album")
	expect(q.stage == C.GO_HOME, "'Then don't blink.' Then home")

	print("-- on the side: Mr. Kwok's back page (OQ01)")
	await place(Vector3(2.9, 0, -5.0))
	expect(await interact("shopkeeper"), "Mr. Kwok: 'Get that.'")
	expect(q.flags.oq01_asked, "'Still mine.'")
	await place(w.refs.awningSeen)
	var sd := slice.cam.direction
	if not q.flags.oq01_seen:
		await turn_to(0)
		await secs(0.5)
		expect(await interact("pageAwning") and not q.flags.oq01_seen, "from the catwalk it lies on an awning, out of reach")
		expect(not await interact("wellBalconyDoor"), "no way to it yet")
		sd = await turn_until("oq01_seen")
		expect(sd == 1 or sd == 3, "from the side: on a little balcony under the awning")
	else:
		expect(true, "the earlier side view of the awning is remembered when Kwok asks")
	await turn_to(0)
	await place(w.refs.wellBalconyDoor)
	expect(await interact("wellBalconyDoor"), "the door halfway up the stairs by Lau's")
	await secs(1.2)
	expect(absf(slice.player.position.y - BuildSideQuests.WELL_BALC_Y) < 0.3, "out on the balcony")
	expect(await interact("kwokPage"), "the back page: racing results, half a crossword")
	expect(await interact("wellBalconyBack"), "back through the door")
	await secs(1.2)
	expect(absf(slice.player.position.y - 1.73) < 0.2, "back on the tread beside the door, halfway up the flight")
	# the flight is walkable: down it, up it, and not into its side from the floor
	var ws: WalkSpace = slice.player.walk_space
	# the foot is against the stairwell's south wall (z -12): she comes and goes from the west
	var down := ws.slide(ws.slide(slice.player.position, Vector2(0, 2.6), 0.32), Vector2(-1.2, 0), 0.32)
	expect(down.x < 9.4 and absf(down.y) < 0.01, "she can walk down the stairs and off onto the floor")
	var up := ws.slide(ws.slide(Vector3(9.0, 0, -12.4), Vector2(1.15, 0), 0.32), Vector2(0, -2.8), 0.32)
	expect(up.y > 1.9, "and walk up them from the foot to the top step")
	var side := ws.slide(Vector3(9.4, 0, -13.6), Vector2(0.8, 0), 0.32)
	expect(side.x < 9.6 and side.y < 0.01, "from the floor beside the flight, its side is solid")
	await place(Vector3(2.9, 0, -5.0))
	expect(await interact("shopkeeper"), "back to Mr. Kwok")
	expect(q.flags.oq01_done, "'Poor judgment.'")

	print("-- on the side: the last mahjong tile (OQ04)")
	await place(Vector3(-2.0, 0, 1.6))
	expect(await interact("mahjong2"), "'Who's got the white dragon?'")
	expect(q.flags.oq04_asked, "everyone accuses everyone")
	await place(w.refs.tileCrack)
	expect(await interact("tileCrack"), "the crack at the foot of the wall: too thin for anybody's arm")
	await place(w.refs.tileHole)
	await turn_to(0)
	await secs(0.5)
	expect(not q.flags.oq04_seen and not await interact("tileHole"), "from the front, crates stacked against the lane wall")
	sd = await turn_until("oq04_seen")
	expect(sd == 1 or sd == 3, "from the side: the tile, where the crack comes out")
	await turn_to(0)
	expect(await interact("tileHole"), "the white dragon, grey with dust")
	await place(Vector3(-2.0, 0, 1.6))
	expect(await interact("mahjong2"), "back to the table")
	expect(q.flags.oq04_done, "they count the tiles three times")

	print("-- home")
	var mum: Resident = w.residents.mum
	expect(mum.idle_anim == "wash", "Mum is at the tap, washing the red bowl")
	await place(Vector3(-11.4, 0, -0.3))
	expect(await interact("brochure"), "the brochure for the new estate")
	await place(Vector3(-9.1, 0, -2.2))
	expect(await interact("mum"), "Mum can be talked to")
	expect(q.stage == C.TEA and not q.is_complete(), "the day doesn't end on Mum's line: the kettle goes on")
	var tea_t := 0.0
	while not q.flags.tea_served and tea_t < 16.0:
		await secs(0.25)
		tea_t += 0.25
	expect(q.flags.tea_served, "Mum brings Grandfather his tea")
	expect(w.level.get_node_or_null("TeaCup") != null, "the cup is on the table by him")
	await place(Vector3(-11.9, 0, 0.9))
	expect(await interact("grandfather"), "Mei sits with Grandfather")
	await secs(9.0)
	expect(q.is_complete(), "the day ends")
	expect(slice.ending.visible, "the end card: 24 days until we leave")
	expect(Progress.reached() >= 2, "Chapter 2 is remembered as reached")

	print("")
	print("chapter two: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
