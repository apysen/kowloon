extends SceneTree

## Plays Chapter 4, Three Addresses, from home to the end card.
##
##   KOWLOON_CHAPTER=4 godot --path . --script res://tests/integration/chapter_four.gd
##
## Follows the spec's story gates (§50): the cabinet's way out needs perspective
## (the gap behind the shelves, the stair's way on, the leaf's bolts, each only
## from the right side); the three addresses come in any order; AFTER unlocks
## only when they are taken back to Mrs. Cheung; the day's photograph is hers.

const C := preload("res://src/core/nodes/quests/chapter_four_director.gd")

var slice: SliceRoot
var q: ChapterFourDirector
var failures := 0


func _initialize() -> void:
	Progress.chapter = 4
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
	q = slice.director as ChapterFourDirector
	expect(q != null, "the slice runs Chapter 4's director")
	if q == null:
		quit(1)
		return
	var w := slice.world
	var B := LevelBuilder.LEVEL_B
	var R := LevelBuilder.LEVEL_ROOF

	print("-- the day, changed")
	expect(w.level.get_node_or_null("ChapterProps/Ch4") != null, "Chapter 4's people and boxes are in")
	expect(w.level.get_node_or_null("ChapterProps/Ch1-3") == null, "Lau's chair, the workshop's tables and the locked gate are gone")
	expect(w.residents.has("cheung") and w.residents.has("cheng"), "Mrs. Cheung and Mr. Cheng are here today")
	q.start_intro()
	await wait_dialogue(15.0)
	expect(q.stage == C.GO_YAMEN, "Mum: Mrs. Cheung was asking for you")

	print("-- out to the yamen")
	var through := w.walk_space.slide(Vector3(1.0, 0, 5.1), Vector2(3.0, 0), Player.RADIUS)
	expect(through.x > 3.5, "the lane's gate is open: the lane goes on to the yamen")
	await place(Vector3(8.6, 0, 3.2))
	await wait_dialogue(8.0)
	expect(q.flags.cheung_met and q.stage == C.ADDRESSES, "in the open, Mrs. Cheung: three addresses")

	print("-- on the side: Mrs. Cheung's fan (OQ02)")
	await wait_dialogue(25.0)
	expect(q.flags.oq02_stopped, "the fan by her table clicks, slows and stops")
	await place(Vector3(-3.4, 0, -0.45))
	expect(await interact("fanman"), "Mr. Ho: the motor's fine, follow the cable")
	expect(q.flags.oq02_ho, "follow the cable")
	await place(w.refs.cordsPart)
	await turn_to(0)
	await secs(0.5)
	expect(not q.flags.oq02_traced, "from the front the two cords lie one over the other")
	var fd := await turn_until("oq02_traced")
	expect(fd == 1 or fd == 3, "from the side: one to the hall's radio, one under the storage room door")
	await turn_to(0)
	await place(Vector3(15.2, 0, -5.8))
	await secs(0.5)
	expect(not q.flags.oq02_plug_seen and not await interact("plug"), "from the front the shelves hide the socket")
	fd = await turn_until("oq02_plug_seen")
	expect(fd == 2, "from the far side: the plug, out, on the floor")
	await turn_to(0)
	expect(await interact("plug"), "plugged back in")
	expect(q.flags.oq02_fixed, "the fan turns again")
	await place(Vector3(9.6, 0, 0.2))
	expect(await interact("cheung"), "back to Mrs. Cheung")
	expect(q.flags.oq02_done and q.stage == C.ADDRESSES, "'Nobody ever looks at the plug.'")

	print("-- on the side: Auntie Fong's sign (OQ03)")
	await place(Vector3(13.9, B, -16.6))
	expect(await interact("fong"), "Auntie Fong, out on her ledge")
	expect(q.flags.oq03_asked, "'Two bolts at each end.'")
	await place(w.refs.ladderBase)
	expect(await interact("ladderUp"), "up through the workshop's hatch")
	await secs(1.2)
	await place(w.refs.fongBoltRoof)
	await turn_to(0)
	await secs(0.5)
	expect(not q.flags.oq03_slot_seen, "from the front the balcony looks joined to the roof")
	var sd := await turn_until("oq03_slot_seen")
	expect(sd == 1 or sd == 3, "from the side: a drop between them, and no plank")
	await turn_to(0)
	var across := w.walk_space.slide(w.refs.fongBoltRoof, Vector2(0, 2.8), Player.RADIUS)
	expect(across.z < 4.1, "the slot can't be crossed")
	expect(await interact("fongBoltRoof"), "the roof end's bolts undone")
	expect(q.flags.oq03_roof and not q.flags.oq03_down, "the board sags on the other post")
	await place(Vector3(-0.25, 0, 5.0))
	await secs(0.5)
	expect(not q.flags.oq03_ladder_seen and not await interact("laneLadderUp"), "from the front the lane's south wall is just a wall")
	sd = await turn_until("oq03_ladder_seen")
	expect(sd == 2, "looking back from the north: a steel ladder up it")
	await turn_to(0)
	await place(w.refs.laneLadder)
	expect(await interact("laneLadderUp"), "up the ladder")
	await secs(1.4)
	expect(absf(slice.player.position.y - BuildWorkshop.ROOF_Y) < 0.5 and slice.player.position.z > 6.0, "onto the neighbours' balcony")
	var landing_plant: Node3D = w.level.get_node("Structure/Workshop/Balcony/PlantPot")
	var landing_gap := Vector2(landing_plant.global_position.x - w.refs.ladderTop.x,
		landing_plant.global_position.z - w.refs.ladderTop.z).length()
	expect(landing_gap > 0.9, "the balcony plant leaves the ladder landing clear")
	await place(w.refs.fongBoltBalcony)
	expect(slice.interaction.current.get("id", "") == "fongBoltBalcony", "the bolt prompt is clear of the ladder")
	expect(await interact("fongBoltBalcony"), "the balcony end's bolts undone")
	expect(q.flags.oq03_down, "the sign swings down into the lane")
	expect(w.level.get_node("ChapterProps/Ch1-4/FongSign/SignBoard").get_meta("gone", false), "gone from over the slot")
	expect(await interact("laneLadderDown"), "back down the ladder")
	await secs(1.4)
	await place(Vector3(13.9, B, -16.6))
	expect(await interact("fong"), "back to Auntie Fong")
	expect(q.flags.oq03_done and q.stage == C.ADDRESSES, "'Leave the posts.'")

	print("-- Mr. Cheng's cabinet")
	var gap_seen_early: bool = q.flags.side_gap_found
	var store_threshold := Vector3(14.65, 0, -3.05)
	expect(w.residents.cheng.position.distance_to(store_threshold) > 1.0, "Mr. Cheng stands clear of the storage doorway")
	expect(w.residents.mover_a.position.distance_to(store_threshold) > 1.0 and w.residents.mover_b.position.distance_to(store_threshold) > 1.0, "both movers wait away from the storage doorway")
	await place(Vector3(14.2, 0, -1.2))
	expect(await interact("cheng"), "Mr. Cheng and his plan")
	expect(q.flags.cheng_met, "'There is on the plan.'")
	var out := w.walk_space.slide(Vector3(14.65, 0, -3.9), Vector2(0, 1.5), Player.RADIUS)
	expect(out.z > -3.0, "Mei can walk out of the storage room's door")
	await place(Vector3(15.2, 0, -4.2))
	await turn_to(0)
	await secs(0.6)
	var d := slice.cam.direction
	if gap_seen_early:
		expect(q.flags.side_gap_found, "the gap noticed while fixing the fan is remembered for Mr. Cheng")
	else:
		expect(not q.flags.side_gap_found, "from the front the storage room looks shut in")
		d = await turn_until("side_gap_found")
		expect(d == 1 or d == 3, "from the side: the gap behind the shelves")
	var gap := w.walk_space.slide(Vector3(16.6, 0, -5.95), Vector2(1.2, 0), Player.RADIUS)
	expect(gap.x > 17.2, "and a way into it")
	await turn_to(0)
	await place(w.refs.yamenStairUp)
	expect(await interact("yamenStairUp"), "up the landing's stair")
	await secs(1.2)
	expect(absf(slice.player.position.y - B) < 0.5, "at the stair's head")
	var stuck := w.walk_space.slide(Vector3(16.4, B, 3.5), Vector2(-1.5, 0), Player.RADIUS)
	expect(stuck.x > 15.9, "from the front the stair ends at a wall")
	d = await turn_until("stair_found")
	expect(d != -1 and d != 0, "looking east, it goes on into the next building")
	var on := w.walk_space.slide(Vector3(16.4, B, 3.5), Vector2(-1.5, 0), Player.RADIUS)
	expect(on.x < 15.5, "through into the old classroom")
	await turn_to(0)
	await place(Vector3(13.6, B, 0.05))
	await secs(0.5)
	expect(not q.flags.panel_seen, "from the front the door's other leaf is just a door")
	d = await turn_until("panel_seen")
	expect(d == 2, "from the balcony, looking back: bolts on the outside")
	await turn_to(0)
	expect(await interact("foldPanel"), "the second leaf unbolted")
	expect(q.flags.panel_open, "it folds back flat")
	await place(Vector3(14.2, 0, -1.2))
	expect(await interact("cheng"), "Mei shows Mr. Cheng the way")
	await secs(5.0)
	await read_through()
	expect(q.flags.cabinet_moved, "the cabinet comes out into the courtyard")
	expect(q.flags.theme_line_somebody_shows_you and q.flags.cheng_respect_mei, "'You know once somebody shows you.'")

	print("-- three addresses")
	await place(Vector3(4.8, 0, -11.6))
	expect(await interact("lau"), "Lau, packing up")
	expect(q.flags.payoff_lau_windows and not q.flags.address_lau, "'Two windows.' The card's by the door")
	await place(w.refs.lauCard)
	expect(await interact("lauCard"), "his card, taken from inside the door")
	expect(q.flags.address_lau, "Lau's address")
	await place(w.refs.wongPacking + Vector3(0.0, 0, 1.4))
	await wait_dialogue(4.0)
	expect(q.flags.wong_packing_seen, "Mrs. Wong packing on the landing, on the way up")
	await place(w.refs.chanRoof + Vector3(0.4, 0, 0.9))
	expect(await interact("chan"), "the Chans on the roof")
	expect(q.flags.address_chan, "the Chans' address")
	expect(q.stage == C.ADDRESSES, "two of three: not done yet")
	await place(w.refs.kitWorkshop + Vector3(0.5, 0, 0.8))
	expect(await interact("kit"), "Kit, sweeping out the workshop")
	expect(q.flags.address_kit, "Kit's address")
	expect(q.stage == C.RETURN, "three addresses and the cabinet out: back to Mrs. Cheung")
	expect(not Progress.after_unlocked and ResidentCatalog.entry("lau").after == "", "no AFTER in the album yet")

	print("-- back to Mrs. Cheung")
	await place(Vector3(9.6, 0, 0.2))
	expect(await interact("cheung"), "Mrs. Cheung copies them into her book")
	expect(q.flags.after_unlocked and q.stage == C.PHOTO_CHEUNG, "'Knowing where they went is better.'")
	expect(ResidentCatalog.entry("lau").after != "", "the album's pages gain AFTER: Lau's new clinic")
	await photograph("cheung", Vector3(9.6, 0, 1.0))
	expect(slice.scrapbook.entries.has("cheung"), "Mrs. Cheung and her book go in the album")
	await secs(9.0)
	expect(q.is_complete() and slice.ending.visible, "12 days until we leave")
	expect(Progress.reached() >= 4, "Chapter 4 is remembered as reached")
	var _r := R

	print("")
	print("chapter four: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
