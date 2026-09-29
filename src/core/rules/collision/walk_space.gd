class_name WalkSpace
extends RefCounted

## Where people can stand: the union of floor rectangles, minus obstacles.
##
## The slice never needed a physics engine and neither does this. The city is
## rooms and corridors on three levels, so walkable space is a list of floor
## rectangles tagged with their height, and blocking is a list of boxes that
## can switch on and off (a door until it is opened, the wet washing until it
## moves, a resident standing in a corridor). Movement slides along walls one
## axis at a time.
##
## Mei's footprint is a square that must lie wholly on floor, so her centre
## always stays a radius away from the inside face of every wall. The sprite's
## anchor depth (see pixel_sprite.gdshaderinc) does the rest of the no-clipping
## work: the footprint keeps her out of the walls, the anchor keeps the card
## from being sliced by them.

const LEVEL_TOLERANCE := 1.0


class Floor:
	var x0: float
	var x1: float
	var z0: float
	var z1: float
	var y: float
	var name: String

	func contains(x: float, z: float) -> bool:
		return x >= x0 and x <= x1 and z >= z0 and z <= z1


class Obstacle:
	var x0: float
	var x1: float
	var z0: float
	var z1: float
	var y: float
	var name: String
	## Returns whether the obstacle currently blocks. Null means always.
	var active: Callable

	func is_active() -> bool:
		return not active.is_valid() or bool(active.call())

	func set_center(x: float, z: float, y_level: float, radius: float) -> void:
		x0 = x - radius
		x1 = x + radius
		z0 = z - radius
		z1 = z + radius
		y = y_level


var floors: Array[Floor] = []
var obstacles: Array[Obstacle] = []


func add_floor(x0: float, x1: float, z0: float, z1: float, y: float, floor_name := "") -> Floor:
	var f := Floor.new()
	f.x0 = minf(x0, x1)
	f.x1 = maxf(x0, x1)
	f.z0 = minf(z0, z1)
	f.z1 = maxf(z0, z1)
	f.y = y
	f.name = floor_name
	floors.append(f)
	return f


func add_obstacle(x0: float, x1: float, z0: float, z1: float, y: float, obstacle_name := "", active := Callable()) -> Obstacle:
	var o := Obstacle.new()
	o.x0 = minf(x0, x1)
	o.x1 = maxf(x0, x1)
	o.z0 = minf(z0, z1)
	o.z1 = maxf(z0, z1)
	o.y = y
	o.name = obstacle_name
	o.active = active
	obstacles.append(o)
	return o


func floor_at(x: float, z: float, y: float) -> Floor:
	for f in floors:
		if absf(f.y - y) > LEVEL_TOLERANCE:
			continue
		if f.contains(x, z):
			return f
	return null


func circle_hits_obstacle(x: float, z: float, y: float, r: float, ignore: Obstacle = null) -> Obstacle:
	for o in obstacles:
		if o == ignore or absf(o.y - y) > LEVEL_TOLERANCE or not o.is_active():
			continue
		var cx := clampf(x, o.x0, o.x1)
		var cz := clampf(z, o.z0, o.z1)
		var dx := x - cx
		var dz := z - cz
		if dx * dx + dz * dz < r * r:
			return o
	return null


## The footprint (a square of half-size r) must be on floor at every corner and
## the centre, and the circle must not touch an active obstacle.
func can_stand(x: float, z: float, y: float, r: float, ignore: Obstacle = null) -> bool:
	for p in [Vector2(x - r, z - r), Vector2(x + r, z - r), Vector2(x - r, z + r), Vector2(x + r, z + r), Vector2(x, z)]:
		if floor_at(p.x, p.y, y) == null:
			return false
	return circle_hits_obstacle(x, z, y, r, ignore) == null


## Axis-separated move so the mover slides along walls. Returns true if it moved.
func resolve_move(pos: Vector3, dx: float, dz: float, r: float, ignore: Obstacle = null) -> Vector3:
	var p := pos
	if dx != 0.0 and can_stand(p.x + dx, p.z, p.y, r, ignore):
		p.x += dx
	if dz != 0.0 and can_stand(p.x, p.z + dz, p.y, r, ignore):
		p.z += dz
	return p


## Moves in sub-steps so a slow frame can never carry anyone through a thin door.
func slide(pos: Vector3, delta_xz: Vector2, r: float, max_step := 0.12, ignore: Obstacle = null) -> Vector3:
	var steps := maxi(1, ceili(delta_xz.length() / max_step))
	var p := pos
	for i in steps:
		p = resolve_move(p, delta_xz.x / steps, delta_xz.y / steps, r, ignore)
	return p
