extends SceneTree

## Plays Chapter 5, Rooms Going Quiet, from home to the end card.
##
##   KOWLOON_CHAPTER=5 godot --path . --script res://tests/integration/chapter_five.gd
##
## Follows the spec's story gates (§50): the footbridge is gone and the old
## route with it; the empty workshop's route is there, its stair seen only by
## turning the view; the dry wing has no water and no pipe hum; the rope is in
## the borrowed box and giving it back sets payoff_ng_rope; Mrs. Wong's note
## can't be had before her room has changed; Mum's argument waits for its
## prerequisites; the optional empty-room photograph never blocks the day.

const C := preload("res://src/core/nodes/quests/chapter_five_director.gd")

var slice: SliceRoot
var q: ChapterFiveDirector
var failures := 0


func _initialize() -> void:
	Progress.chapter = 5
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
	q = slice.director as ChapterFiveDirector
	expect(q != null, "the slice runs Chapter 5's director")
	if q == null:
		quit(1)
		return
	var w := slice.world
	var B := LevelBuilder.LEVEL_B
	var R := LevelBuilder.LEVEL_ROOF

	print("-- the day, changed")
	expect(w.level.get_node_or_null("ChapterProps/Ch5") != null and w.level.get_node_or_null("ChapterProps/Ch5-7") != null,
		"Chapter 5's things are in")
	expect(w.level.get_node_or_null("ChapterProps/Ch1-4") == null, "the footbridge, the mahjong table, Lau's certificate are gone")
	for id in ["lau", "chan", "son", "wong", "chopper", "mahjong3"]:
		expect(w.residents[id].gone, "%s has moved" % id)
	expect(not w.residents.ng.gone and not w.residents.fanman.gone and not w.residents.shopkeeper.gone, "Ng, Ho and Kwok are still here, packing")
	var bridge := w.walk_space.slide(Vector3(17.7, B, -12.3), Vector2(0, -2.5), Player.RADIUS)
	expect(bridge.z > -13.1, "the footbridge is gone: the old route across the well is unavailable")
	expect(w.level.get_node_or_null("ChapterProps/Ch5/Borrowed/Items/Rope") != null, "Mr. Ng's rope is in the borrowed-items box")
	expect(not await interact("wongTable"), "Mrs. Wong's envelope can't be had yet")
	for id in ["drill", "tv", "kids", "chop"]:
		expect(slice.audio.quiet.has(id), "no %s today" % id)

	q.start_intro()
	await secs(4.0)
	expect(not slice.dialogue.is_open(), "the day opens without any text")
	await wait_dialogue(10.0)
	expect(q.stage == C.RETURNS and q.flags.items_taken, "Mum: these need to go back")

	print("-- water, and where it isn't")
	expect(q.pipe_hum_at(Vector3(-2.0, 0, -0.8)) > 0.05, "the pipes still hum in the hall")
	expect(q.pipe_hum_at(Vector3(14.8, B, -16.8)) == 0.0 and q.in_dry_wing(Vector3(14.8, B, -16.8)),
		"on the far ledge, Mrs. Cheung's wing: no pipe hum")

	print("-- giving things back")
	await place(Vector3(-3.4, 0, -0.45))
	expect(await interact("fanman"), "Mr. Ho, packing his tools")
	expect(q.flags.returned_screwdriver, "'Your grandfather borrows permanently.'")
	expect(ResidentCatalog.entry("ho").later != "", "Ho's page: the pipes were still there after the water stopped")
	await place(Vector3(-2.1, 0, 1.9))
	expect(await interact("mahjong2"), "two of the mahjong four, packing")
	expect(q.flags.returned_tile, "'Another one?' The tile goes in the tin")
	await place(Vector3(-8.7, 0, -0.9))
	await secs(3.0)
	expect(q.stage == C.RETURNS and not q.flags.mei_mum_argument, "home early: no argument yet")

	print("-- on the side: the lost address (OQ06)")
	await place(Vector3(3.3, 0, -1.8))
	expect(await interact("leung"), "Mrs. Leung, whose sister's moved to Lok Fu")
	expect(q.flags.oq06_asked, "'Everybody left their new address with Kwok.'")
	await place(Vector3(3.3, 0, -6.9))
	expect(await interact("shopkeeper"), "Mr. Kwok: it's in the bundle, behind the counter")
	await place(Vector3(3.3, 0, -4.9))
	await turn_to(0)
	await secs(0.5)
	expect(not q.flags.oq06_seen and not await interact("stallGap"), "from the side the stall is just walls")
	var sd := await turn_until("oq06_seen")
	expect(sd == 1, "turned to face the stall's open front: the bundle under the shutter")
	await turn_to(0)
	expect(slice.interaction.current.get("id", "") == "stallGap", "Kwok leaves the bundle's reach prompt clear")
	expect(await interact("stallGap"), "Mei reaches under the shutter")
	expect(q.flags.oq06_note, "a note in Mrs. Wong's hand")
	await place(Vector3(3.3, 0, -1.8))
	expect(await interact("leung"), "back to Mrs. Leung")
	expect(q.flags.oq06_done, "'Five. I'd have guessed seven.'")
	await place(Vector3(3.4, R, -19.4))
	expect(await interact("ng"), "Mr. Ng, packing his cages")
	expect(q.flags.returned_ng and q.flags.payoff_ng_rope, "the birdseed and the rope: 'Twelve days is quickly.'")

	print("-- the catwalk")
	await place(Vector3(14.0, B, -12.0))
	await secs(0.5)
	expect(q.stage == C.PHOTO_LINE, "on the catwalk: photograph the Chans' clothesline")
	await secs(3.5)
	expect(q.flags.peg_fell, "one peg falls, unprompted")
	await place(Vector3(17.7, B, -12.4))
	await secs(0.3)
	expect(q.flags.footbridge_seen, "'The footbridge is gone.'")
	await photograph("line", Vector3(19.2, B, -12.2), Vector3(16.0, B + 2.3, -12.0))
	expect(slice.scrapbook.entries.has("line") and q.flags.line_photo, "the empty line goes in the album: nobody in it")
	expect(q.stage == C.RETURNS, "back to the returns")

	print("-- Mrs. Wong's room")
	await place(Vector3(25.6, B, -13.2))
	expect(await interact("wongTable"), "the bowl on her table")
	expect(q.flags.returned_bowl and q.flags.wong_note, "an envelope: FOR THE OLD FOOL")
	await photograph("wong_room", Vector3(25.0, B, -11.5), Vector3(28.0, B + 0.8, -14.0), false)
	expect(slice.scrapbook.entries.has("wong_room"), "the optional empty-room photograph, taken")
	expect(ResidentCatalog.entry("wong_room").note == "", "no caption on it yet")

	print("-- the way round to Mrs. Fong's")
	var into := w.walk_space.slide(Vector3(8.75, 0, -14.6), Vector2(0, -1.5), Player.RADIUS)
	expect(into.z < -15.4, "the metal shop behind the stairwell stands open")
	await place(Vector3(9.3, 0, -15.9))
	await turn_to(0)
	await secs(0.6)
	expect(q.flags.shop_seen and not q.flags.stair_found, "from the front: an empty shop, a pegboard")
	var d := await turn_until("stair_found")
	expect(d != -1 and d != 0, "turned: behind the pegboard, a narrow stair")
	await turn_to(0)
	await place(w.refs.backStairFoot)
	expect(await interact("backStairUp"), "up the narrow stair")
	await secs(1.4)
	expect(absf(slice.player.position.y - B) < 0.5 and slice.player.position.x > 10.9, "at the stair's head")
	var out := w.walk_space.slide(Vector3(11.4, B, -16.8), Vector2(1.5, 0), Player.RADIUS)
	expect(out.x > 12.3, "and through its door onto the ledge")
	await place(Vector3(14.8, B, -16.8))
	expect(q.pipe_hum_at(slice.player.position) == 0.0, "no pipe hum out here")
	expect(await interact("fongTap"), "Mrs. Fong's tap: nothing")
	expect(await interact("fongRoom"), "Mrs. Fong's open door")
	expect(q.flags.returned_stool_to_empty_room, "'Nobody is here.' The stool, left against the wall")
	var inside := w.walk_space.slide(Vector3(14.8, B, -16.8), Vector2(0, -1.5), Player.RADIUS)
	expect(inside.z < -17.8, "her empty room can be walked into")

	print("-- Grandfather, and the note")
	await place(Vector3(-11.9, 0, 0.8))
	expect(await interact("grandfather"), "the note, to Grandfather")
	expect(q.flags.payoff_wong_bet and q.flags.grandfather_keeps_note, "'Cheat.' It goes in his pocket, not a box")
	expect(ResidentCatalog.entry("wong_room").note != "", "the empty room's caption, written in later")
	expect(q.stage == C.HOME, "everything back: go home")

	print("-- Mum")
	await place(Vector3(-8.7, 0, -0.9))
	await wait_dialogue(6.0)
	expect(q.flags.mei_mum_argument and q.flags.mei_understands_mum_partial, "'I lived here too.'")
	expect(w.residents.mum.idle_anim == "sit", "Mum sits")
	expect(not slice.scrapbook.entries.has("lau_clinic"), "Lau's old clinic never photographed: it didn't matter")
	await secs(14.0)
	expect(q.is_complete() and slice.ending.visible, "6 days until we leave")
	expect(Progress.reached() >= 5, "Chapter 5 is remembered as reached")

	print("")
	print("chapter five: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
