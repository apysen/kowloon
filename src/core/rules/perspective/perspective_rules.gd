class_name PerspectiveRules
extends RefCounted

## The perspective puzzle rules, free of nodes.
##
## Nothing appears or disappears when the view turns. Turning only changes
## what Mei can see, and she can only use what she has seen.

## Visibility bands for the cutaway: geometry above Mei's band is hidden.
static func band_of(y: float) -> float:
	if y < 4.9:
		return 0.0
	if y < 8.9:
		return 1.0
	if y < 12.4:
		return 1.5
	return 2.0


## Mei's own band (0 level A, 1 level B, 2 the roof).
static func player_band(y: float) -> int:
	if y < 4.0:
		return 0
	if y < 12.0:
		return 1
	return 2


## Is a band's geometry drawn while Mei is in `player_band`?
static func band_visible(band: float, pb: int) -> bool:
	if band == 1.5:
		return pb == 2
	return band <= pb


## A door counts as seen once the camera looks at it face-on (not edge-on) with
## Mei nearby on the same level. Either face counts: with the near walls cut
## away you can see a door from behind too, and what is on screen should count.
static func door_seen(door_pos: Vector3, door_normal: Vector3, mei: Vector3, yaw: float) -> bool:
	if absf(mei.y - door_pos.y) > 1.5:
		return false
	if Vector2(mei.x - door_pos.x, mei.z - door_pos.z).length() > 9.0:
		return false
	return absf(door_normal.dot(ViewMath.back(yaw))) > 0.6


## Mei is in the airshaft, or standing at its top.
static func in_shaft(p: Vector3) -> bool:
	var inside := p.y > 4.0 and p.y < 12.5 and p.x > -7.2 and p.x < -2.8 and p.z < -15.6 and p.z > -21.2
	var at_top := p.y > 12.0 and Vector2(p.x + 5.0, p.z + 15.4).length() < 2.5
	return inside or at_top


## A handhold is seen when its usable face points toward the camera.
## A null normal (the laundry pole) is visible from anywhere.
static func hold_seen(normal: Variant, yaw: float) -> bool:
	if normal == null:
		return true
	return (normal as Vector3).dot(ViewMath.back(yaw)) >= 0.5
