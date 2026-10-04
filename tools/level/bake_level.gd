extends SceneTree

## Bakes the level: builds the node tree and its LevelData and saves both.
##
##   godot --headless --path . --script res://tools/level/bake_level.gd
##
## Writes scenes/slice/level.tscn, data/level/level_data.tres and the shared
## surface materials in assets/materials/. Rerun after changing any builder.

const LEVEL_SCENE := "res://scenes/slice/level.tscn"
const LEVEL_DATA := "res://data/level/level_data.tres"


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var b := LevelBuilder.new()
	BuildInteriors.build(b)
	BuildCity.build(b)
	var settled := b.settle_people()
	print("background people: %d moved clear of the scenery, %d with nowhere to stand left out" % settled)
	b.finish()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/level"))
	var err := ResourceSaver.save(b.data, LEVEL_DATA)
	if err != OK:
		push_error("could not save level data: %s" % err)

	var packed := PackedScene.new()
	err = packed.pack(b.root)
	if err != OK:
		push_error("could not pack level: %s" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, LEVEL_SCENE)
	if err != OK:
		push_error("could not save level: %s" % err)
		quit(1)
		return
	var count := _count(b.root)
	print("%d prop boxes rounded off, %d occluders, %d small pieces cast no shadow" % [b.soft_boxes, b.occluders, b.shadowless])
	print("baked level: %d nodes, %d floors, %d obstacles, %d filler blocks in %d ms" % [
		count, b.data.floors.size(), b.data.obstacles.size(), b.filler_blocks.size(), Time.get_ticks_msec() - t0])
	b.root.free()
	quit(0)


func _count(n: Node) -> int:
	var c := 1
	for k in n.get_children():
		c += _count(k)
	return c
