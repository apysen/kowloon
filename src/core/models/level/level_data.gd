class_name LevelData
extends Resource

## Everything about the level that is not drawn: where people can walk, what
## blocks them, which rooms stay shut, the doors and handholds, and the named
## points the story uses. Written by tools/level/bake_level.gd next to the
## baked level scene so the two never drift apart.

## {x0, x1, z0, z1, y, name}
@export var floors: Array[Dictionary] = []
## {x0, x1, z0, z1, y, name, key}. `key` names obstacles the world switches
## on and off (a door until opened, the washing until it moves).
@export var obstacles: Array[Dictionary] = []
## {id, y, rects: Array of [x0, x1, z0, z1]}
@export var closed_rooms: Array[Dictionary] = []
## {id, pos, normal, width, room, path, spill_path}
@export var doors: Array[Dictionary] = []
## {id, name, normal (Vector3 or null), point, path}
@export var holds: Array[Dictionary] = []
## Named points the story uses (stairs, the washing, the boxes...).
@export var refs: Dictionary = {}
## Mei's route up the airshaft, bottom to top.
@export var climb_nodes: Array[Vector3] = []
## The lost pigeon's flight home, perch to coop.
@export var pigeon_path: Array[Vector3] = []


func build_walk_space() -> WalkSpace:
	var ws := WalkSpace.new()
	for f in floors:
		ws.add_floor(f.x0, f.x1, f.z0, f.z1, f.y, f.name)
	return ws
