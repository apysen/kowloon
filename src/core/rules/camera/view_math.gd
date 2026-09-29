class_name ViewMath
extends RefCounted

## Directions derived from the camera's yaw, shared by movement, fading and discovery.
##
## Yaw 0 looks north (the camera sits south of Mei). Each quarter turn adds
## PI/2. "Back" points from the focus toward the camera, "right" is screen
## right; both lie flat in the XZ plane.

const DIRECTION_NAMES := ["NORTH", "WEST", "SOUTH", "EAST"]


static func back(yaw: float) -> Vector3:
	return Vector3(sin(yaw), 0.0, cos(yaw))


static func right(yaw: float) -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))


## Turns a screen-relative input (x right, y "into the screen") into a world XZ move.
## W always means deeper into the screen, whichever way the view faces.
static func camera_relative(input: Vector2, settled_yaw: float) -> Vector2:
	var fwd := -back(settled_yaw)
	var rt := right(settled_yaw)
	var v := rt * input.x + fwd * input.y
	return Vector2(v.x, v.z)


## Which sprite view a character facing `facing` shows to a camera at `yaw`,
## and whether the side view should be mirrored.
static func sprite_view(facing: Vector3, yaw: float) -> Dictionary:
	var f := Vector3(facing.x, 0.0, facing.z)
	if f.length_squared() < 1e-6:
		return {"view": "front", "flip": false}
	f = f.normalized()
	var toward_cam := f.dot(back(yaw))
	var side := f.dot(right(yaw))
	if toward_cam > 0.55:
		return {"view": "front", "flip": false}
	if toward_cam < -0.55:
		return {"view": "back", "flip": false}
	return {"view": "side", "flip": side < 0.0}
