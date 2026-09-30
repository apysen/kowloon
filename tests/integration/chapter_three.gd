extends SceneTree

## Plays Chapter 3, Last Batch, from Kit at the door to the end card.
##
##   KOWLOON_CHAPTER=3 godot --path . --script res://tests/integration/chapter_three.gd
##
## Follows the spec's story gates (§50): the route can't be finished without
## the rope, the plank and Ho's word on the pulley; turning the view is what
## finds the pulley and the sign's hinges; the last crate travels the whole way
## down; Kit's scene comes after it.

const C := preload("res://src/core/nodes/quests/chapter_three_director.gd")

var slice: SliceRoot
var q: ChapterThreeDirector
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
	q = slice.director as ChapterThreeDirector
	expect(q != null, "the slice runs Chapter 3's director")
	if q == null:
		quit(1)
		return
	var w := slice.world
	var B := LevelBuilder.LEVEL_B
	var R := BuildWorkshop.ROOF_Y

	print("-- Kit at the door")
	expect(w.residents.has("kit") and w.residents.has("chiu"), "Kit and Uncle Chiu are here today")
	expect(w.level.get_node_or_null("ChapterProps/Ch1-2") == null, "the workshop door stands open")
	q.start_intro()
	var w8 := 0.0
	while not slice.dialogue.is_open() and w8 < 15.0:
		await secs(0.25)
		w8 += 0.25
	await read_through()
	expect(q.stage == C.GO_WITH_KIT, "Kit: Uncle needs hands")

	print("-- the workshop")
	expect(await interact("stairsCUp"), "the second stair goes up")
	await secs(1.5)
	expect(absf(slice.player.position.y - B) < 0.2, "up on the Chius' landing")
	await place(Vector3(-2.5, B, 2.0))
	await frames(10)
	await read_through()
	expect(q.stage == C.LOADING_ROUTE, "Chiu: final shipment, and crates used to go up")

	print("-- the old way")
	await place(w.refs.ladderBase + Vector3(0.2, 0, 0.3))
	expect(await interact("ladderUp"), "up the ladder through the hatch")
	await secs(1.5)
	expect(absf(slice.player.position.y - R) < 0.2, "on the workshop roof")
	await turn_to(0)
	await secs(0.5)
	expect(q.stage == C.LOADING_ROUTE, "from the front the neighbours' side is cut away")
	await turn_to(2)
	await secs(0.5)
	await read_through()
	expect(q.stage == C.FIND_PARTS and q.flags.factory_route_pulley_found, "looking back, the pulley over the balcony")
	await turn_to(0)
	await place(w.refs.plankGap)
	await interact("plankGap")
	expect(not q.flags.plank_laid, "no plank yet: just the drop")
	expect(w.walk_space.slide(w.refs.plankGap, Vector2(0, 2.0), Player.RADIUS).z < 4.3, "nobody walks across the gap")

	print("-- what it takes: people")
	await place(Vector3(-3.4, R, 2.7))
	expect(await interact("fanman"), "Ho is on the roof")
	expect(q.flags.pulley_safe, "Ho: it'll hold, because it hasn't fallen yet")
	await place(Vector3(3.4, 13, -19.5))
	expect(await interact("ng"), "Mr. Ng, up on Mei's roof")
	expect(q.flags.story_item_rope, "Mr. Ng's rope: bring it back quickly")
	await place(Vector3(-5.4, B, -11.5))
	expect(w.residents.son.idle_anim == "sit", "Wai is sitting on the plank")
	expect(await interact("son"), "Wai can be asked")
	expect(q.flags.story_item_plank and w.residents.son.idle_anim != "sit", "Mrs. Chan: get up. The plank")
	expect(q.stage == C.SET_UP, "everything the route needs")

	print("-- on the side: Wai's shortcut (OQ05)")
	expect(await interact("son"), "Wai: Chiu's roof to ours, thirty seconds")
	expect(q.flags.oq05_asked and w.residents.son.position.y > 12.0, "off he goes, to wait on the roof")
	await place(w.refs.shortcutStairTop)
	await turn_to(0)
	await secs(0.5)
	expect(not q.flags.oq05_stair and not await interact("shortcutStair"), "from the front, Chiu's back parapet is just a wall")
	var sd := await turn_until("oq05_stair")
	expect(sd == 1 or sd == 3, "from the side: steel steps down behind it")
	await turn_to(0)
	expect(await interact("shortcutStair"), "down onto the lower roof")
	await secs(1.2)
	sd = await turn_until("oq05_ladder")
	expect(sd == 2, "looking back from the north, behind the washing: a ladder")
	await turn_to(0)
	await place(w.refs.rearLadderFoot)
	expect(await interact("rearLadderUp"), "up to the balcony on the back of our building")
	await secs(1.2)
	expect(not await interact("waiBridge"), "from the front, no way on")
	sd = await turn_until("oq05_bridge")
	expect(sd == 1 or sd == 3, "from the side: two planks up onto the roof")
	await turn_to(0)
	await place(w.refs.waiBridgeFoot)
	expect(await interact("waiBridge"), "over the planks")
	await secs(1.4)
	await read_through()
	expect(slice.player.position.y > 12.0 and q.flags.oq05_done, "'Told you.' 'Than you.'")

	print("-- setting it up")
	await place(w.refs.plankGap)
	expect(await interact("plankGap"), "the plank goes across")
	expect(q.flags.plank_laid, "the plank is laid")
	expect(w.walk_space.slide(w.refs.plankGap, Vector2(0, 2.0), Player.RADIUS).z > 5.5, "and it can be walked across")
	await place(Vector3(-3.3, R, 6.5))
	expect(w.walk_space.slide(Vector3(-3.3, R, 6.5), Vector2(-2.0, 0), Player.RADIUS).x > BuildWorkshop.SIGN_X, "the signboard is in the way")
	await interact("signboard")
	expect(not q.flags.sign_folded, "from the front, no way to move it")
	await turn_to(3)
	await secs(0.5)
	expect(q.flags.sign_hinges_seen, "from the west, the hinges on its back")
	await turn_to(0)
	await place(Vector3(-3.3, R, 6.5))
	expect(await interact("signboard"), "the sign folds")
	await secs(1.6)
	expect(q.flags.sign_folded and w.walk_space.slide(Vector3(-3.3, R, 6.5), Vector2(-2.0, 0), Player.RADIUS).x < BuildWorkshop.SIGN_X, "and the way along the balcony is clear")
	await place(w.refs.winch)
	expect(await interact("winch"), "the rope goes over the pulley")
	expect(q.flags.rope_rigged, "the rope is rigged")

	print("-- the last batch")
	await place(w.refs.winch + Vector3(0.3, 0, 0))
	expect(await interact("kit"), "Kit on the winch")
	expect(q.stage == C.RUN_CRATE, "Uncle! Send it up!")
	var t := 0.0
	var reached_plank := false
	while q.stage == C.RUN_CRATE and t < 25.0:
		await secs(0.25)
		t += 0.25
		var cr: Node3D = q._crate
		if cr and absf(cr.global_position.z - 5.0) < 0.8 and cr.global_position.y > R - 0.2:
			reached_plank = true
		if slice.dialogue.is_open():
			await read_through()
	expect(reached_plank, "the crate crosses on the plank")
	expect(q.flags.crate_down and q.stage == C.FINAL_CRATE, "the platform goes down the slot to the lane")
	var plat: Node3D = w.level.get_node("Special/LoadingPlatform")
	expect(plat.global_position.y < 0.5, "the platform is down in the lane")

	print("-- the lane")
	await place(w.refs.lane + Vector3(-2.6, 0, 0))
	expect(await interact("chiu"), "Uncle Chiu at the last crate")
	expect(q.stage == C.PHOTO_WORKERS, "'Same fish balls.' 'Better drains.'")

	print("-- the last batch, photographed")
	await photograph("hand_a", Vector3(-2.4, LevelBuilder.LEVEL_B, 2.2))
	expect(slice.scrapbook.entries.has("chiu"), "the workers at the last worktable go in the album")
	expect(q.stage == C.KIT_LATER, "then Kit, on the roof")

	print("-- down the second stair")
	await place(w.refs.stairsCDown)
	expect(await interact("stairsCDown"), "down stair C from the landing")
	await secs(1.5)
	var foot := slice.player.position
	expect(foot.y < 0.5, "at the foot of the stair")
	var out := w.walk_space.slide(foot, Vector2(0, -1.5), Player.RADIUS)
	expect(out.distance_to(foot) > 1.0, "and free to walk out into the hall")

	print("-- later, on the roof")
	var kit: Resident = w.residents.kit
	await place(kit.position + Vector3(0.9, 0, 0))
	expect(await interact("kit"), "Kit, with the key to the new flat")
	expect(q.flags.setup_kit_address and q.flags.setup_mei_fears_disconnection, "Block seven, and it already sounds far away")
	await secs(5.5)
	expect(q.is_complete() and slice.ending.visible, "18 days until we leave")
	expect(Progress.reached() >= 3, "Chapter 3 is remembered as reached")

	print("")
	print("chapter three: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
