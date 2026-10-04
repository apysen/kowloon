extends SceneTree

## Regression for the cutaway focus: people outside Mei's current room/area
## never bleed into it, regardless of the quarter-turn camera angle.

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


func room_shell_is_enclosed(w: World, room_id: String, direction: int) -> bool:
	var foreground_side: String = ["s", "e", "n", "w"][direction]
	var faded := 0
	var solid := 0
	for it in w._live:
		if it.room != room_id or not it.fadeable:
			continue
		# Door-frame pieces are tested visually and by the camera-to-Mei
		# obstruction probe; this helper verifies the four actual walls.
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


func room_view_is_clear(w: World, room_id: String, direction: int) -> bool:
	var blockers: Array = w._room_view_blockers.get("%s:%d" % [room_id, direction], [])
	for it in blockers:
		if float(it.view_opacity) > 0.01:
			return false
	return not blockers.is_empty()


func place(p: Vector3) -> void:
	slice.player.teleport(p)
	await frames(6)


func turn_to(direction: int) -> void:
	while slice.cam.direction != direction:
		slice.cam.rotate_view(1)
		await create_timer(0.5).timeout
	await frames(3)


func _run() -> void:
	await frames(6)
	var w := slice.world
	var ho: Resident = w.residents.fanman
	var kit: Resident = w.residents.kit
	var wai: Resident = w.residents.son
	var porter: Resident = w.residents.porter
	var roof_y := BuildWorkshop.ROOF_Y
	ho.place_at(Vector3(-3.4, roof_y, 3.3))
	kit.place_at(Vector3(-0.8, LevelBuilder.LEVEL_B, 2.0))
	wai.place_at(Vector3(-5.4, LevelBuilder.LEVEL_B, -10.6))

	await turn_to(3)
	await place(Vector3(-5.1, LevelBuilder.LEVEL_A, 0.0))
	await create_timer(0.55).timeout
	var apartment_parts := 0
	var apartment_parts_ready := 0
	var apartment_ceiling_fixtures := 0
	var apartment_ceiling_fixtures_hidden := 0
	var table_and_kitchen_parts := 0
	for it in w._items:
		var path := String(w.level.get_path_to(it.node))
		if not path.begins_with("ChapterProps/Ch1-6/Apartment") and not path.begins_with("Furniture/Apartment"):
			continue
		if String(it.ceiling_of) == "apartment":
			apartment_ceiling_fixtures += 1
			if float(it.room_opacity) < 0.01:
				apartment_ceiling_fixtures_hidden += 1
			continue
		apartment_parts += 1
		if it.content_of == "apartment" and it.visible and float(it.room_opacity) > 0.9:
			apartment_parts_ready += 1
		var part_name := String(it.node.name)
		if part_name.begins_with("RiceBowl") or part_name.begins_with("Chopsticks") \
				or part_name.begins_with("CupboardDoor") or part_name.begins_with("CupboardKnob"):
			table_and_kitchen_parts += 1
	expect(w.current_room == "" and apartment_parts > 20 and apartment_parts_ready == apartment_parts,
		"all of Grandpa's furnishings are rendered and revealed from the hall")
	expect(apartment_ceiling_fixtures >= 3 and apartment_ceiling_fixtures_hidden == apartment_ceiling_fixtures,
		"Grandpa's ceiling fixtures leave with the opening lid (%d/%d)" % [apartment_ceiling_fixtures_hidden, apartment_ceiling_fixtures])
	expect(table_and_kitchen_parts >= 6,
		"the table settings and cooking-counter doors belong to the room reveal")
	await place(Vector3(-2.0, LevelBuilder.LEVEL_A, 2.7))
	await frames(3)
	expect(porter.visible and porter.sprite.room_fade < 0.01,
		"the porter stays rendered but hidden inside the mahjong room")
	porter.tick(0.1, true, slice.player.position, slice.cam.current_yaw)
	expect(porter.sprite.speed_scale > 0.99,
		"resident animation continues while dialogue or a cutscene pauses movement")
	await place(Vector3(-2.0, LevelBuilder.LEVEL_A, 4.8))
	await frames(3)
	expect(porter.sprite.room_fade > 0.99,
		"the porter appears only after Mei crosses the mahjong exit")
	await place(Vector3(4.0, LevelBuilder.LEVEL_A, -12.0))
	await create_timer(0.55).timeout
	expect(w.current_room == "clinic", "the dentist's office is the active room")
	expect(w.residents.shopkeeper.sprite.room_fade < 0.01,
		"Mr. Kwok is hidden while Mei is inside the clinic")
	expect(w.residents.lau.sprite.room_fade > 0.99,
		"the dentist remains visible inside his own clinic")
	for direction in 4:
		await turn_to(direction)
		expect(room_shell_is_enclosed(w, "clinic", direction),
			"only the clinic roof and camera-facing wall fade at angle %d" % direction)
		expect(room_view_is_clear(w, "clinic", direction),
			"external details cannot project across the clinic at angle %d" % direction)

	await place(Vector3(3.0, LevelBuilder.LEVEL_A, -8.5))
	await frames(3)
	expect(w.current_room == "corridor" and w.residents.shopkeeper.sprite.room_fade > 0.99,
		"Mr. Kwok returns after Mei exits the clinic")

	await place(Vector3(2.7, LevelBuilder.LEVEL_B, 2.0))
	await create_timer(0.55).timeout
	expect(w.current_room == "" and kit.sprite.room_fade > 0.99,
		"the workshop contents stay fully rendered behind the closed shell")
	var workshop_contents := 0
	var workshop_contents_full := 0
	for it in w._items:
		if it.content_of == "workshop" and float(it.band) == 1.0 and not it.node.get_meta("gone", false):
			workshop_contents += 1
			if it.visible and float(it.room_opacity) > 0.99:
				workshop_contents_full += 1
	expect(workshop_contents > 10 and workshop_contents_full == workshop_contents,
		"every workshop prop is fully rendered while its shell is opaque (%d/%d)" % [workshop_contents_full, workshop_contents])
	await place(Vector3(1.5, LevelBuilder.LEVEL_B, 2.0))
	await create_timer(0.55).timeout
	expect(w.current_room == "" and kit.sprite.room_fade > 0.99,
		"the workshop contents remain fully rendered while its shell fades")
	expect(room_shell_is_enclosed(w, "workshop", slice.cam.direction),
		"the workshop keeps its back and side walls while its roof and foreground wall fade")
	kit.place_at(Vector3(-4.8, roof_y, 1.2))

	await place(Vector3(-2.5, LevelBuilder.LEVEL_B, 2.0))
	await create_timer(0.55).timeout
	expect(w.current_room == "workshop", "the workshop is the active room")
	for direction in 4:
		await turn_to(direction)
		expect(room_view_is_clear(w, "workshop", direction),
			"pipes and signs cannot project across Chiu's room at angle %d" % direction)
		expect(ho.visible and kit.visible and ho.sprite.room_fade < 0.01 and kit.sprite.room_fade < 0.01,
			"roof residents stay rendered but faded out above the workshop at angle %d" % direction)

	await place(Vector3(-5.4, LevelBuilder.LEVEL_B, -11.5))
	await create_timer(0.55).timeout
	expect(w.current_room == "chan" and wai.visible and wai.sprite.room_fade > 0.99, "Wai remains fully rendered inside his room")
	for direction in 4:
		await turn_to(direction)
		expect(ho.sprite.room_fade < 0.01 and kit.sprite.room_fade < 0.01,
			"roof residents remain faded out above Wai's room at angle %d" % direction)

	await place(Vector3(-3.4, roof_y, 2.7))
	await create_timer(0.55).timeout
	expect(w.current_room == "", "the workshop roof is outside the room below")
	expect(ho.visible and ho.sprite.room_fade > 0.99, "Mr. Ho fades in on the roof")
	expect(kit.visible and kit.sprite.room_fade > 0.99, "Kit fades in on the roof")
	expect(wai.visible and wai.sprite.room_fade < 0.01, "Wai stays rendered but faded out below the roof")

	await place(Vector3(3.4, 13.0, -20.6))
	await create_timer(0.55).timeout
	var surrounding_parts := 0
	var solid_surrounding_parts := 0
	for it in w._items:
		# Chapter-gated props deliberately remain hidden; verify every currently
		# active piece of lower-city scenery is opaque on the roof.
		if float(it.band) >= 2.0 or not it.visible or it.node.get_meta("gone", false):
			continue
		surrounding_parts += 1
		if float(it.band_opacity) > 0.99:
			solid_surrounding_parts += 1
	expect(surrounding_parts > 100 and solid_surrounding_parts == surrounding_parts,
		"the full city below the pigeon-cage roof stays solid (%d/%d)" % [solid_surrounding_parts, surrounding_parts])

	print("\nfocus visibility: %s" % ("PASS" if failures == 0 else "FAIL (%d failures)" % failures))
	quit(0 if failures == 0 else 1)
