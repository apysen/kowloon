class_name SpriteSheet
extends RefCounted

## A character sheet exported from Aseprite: the PNG plus Aseprite's JSON.
##
## The .aseprite files in assets/sprites/aseprite/ are the source; the build
## (tools/aseprite/build_characters.lua) exports each as a sheet with one row
## per tag. Tags are named "<anim>_<view>", e.g. "walk_side", with views
## front (toward the camera), back, and side (facing right; cards mirror it
## for left). Frame durations come from Aseprite. Loaded once, shared.

const DIR := "res://assets/sprites/characters/"
## Adults are 42 px and 1.7 m tall; every character shares this density.
const METRES_PER_PIXEL := 1.7 / 42.0
const PIGEON_METRES_PER_PIXEL := 0.036
## Soles are outlined on the frame's second-to-last row.
const FEET_MARGIN_PX := 1

static var _cache: Dictionary = {}

var id: String
var texture: Texture2D
var frame_size: Vector2i
var grid: Vector2i
var metres_per_pixel: float
## anim -> view -> {"cells": Array[Vector2i], "durations": Array[float]}
var anims: Dictionary = {}


static func load_sheet(sheet_id: String) -> SpriteSheet:
	if _cache.has(sheet_id):
		return _cache[sheet_id]
	var s := SpriteSheet.new()
	s.id = sheet_id
	s.texture = load(DIR + sheet_id + ".png")
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + sheet_id + ".json"))
	var frames: Array = meta.frames
	var first: Dictionary = frames[0].frame
	s.frame_size = Vector2i(int(first.w), int(first.h))
	s.grid = Vector2i(s.texture.get_width() / s.frame_size.x, s.texture.get_height() / s.frame_size.y)
	s.metres_per_pixel = PIGEON_METRES_PER_PIXEL if sheet_id == "pigeon" else METRES_PER_PIXEL
	for tag in meta.meta.frameTags:
		var name: String = tag.name
		var cut := name.rfind("_")
		var anim := name.substr(0, cut)
		var view := name.substr(cut + 1)
		var cells: Array[Vector2i] = []
		var durations: Array[float] = []
		for i in range(int(tag.from), int(tag.to) + 1):
			var r: Dictionary = frames[i].frame
			cells.append(Vector2i(int(r.x) / s.frame_size.x, int(r.y) / s.frame_size.y))
			durations.append(float(frames[i].duration) / 1000.0)
		if not s.anims.has(anim):
			s.anims[anim] = {}
		s.anims[anim][view] = {"cells": cells, "durations": durations}
	_cache[sheet_id] = s
	return s


func has_anim(anim: String) -> bool:
	return anims.has(anim)


## Frames for an animation in a view, falling back to whatever view it has.
func track(anim: String, view: String) -> Dictionary:
	var a: Dictionary = anims.get(anim, anims.get("idle", {}))
	if a.has(view):
		return a[view]
	for v in ["side", "front", "back"]:
		if a.has(v):
			return a[v]
	return {"cells": [Vector2i.ZERO], "durations": [1.0]}


## Looping unless it is a one-shot pose (raising the camera).
func loops(anim: String) -> bool:
	return anim != "camera"


## Size of one frame in world metres.
func world_size() -> Vector2:
	return Vector2(frame_size) * metres_per_pixel


## How far the card's bottom edge sits below the feet, in metres.
func feet_offset() -> float:
	return FEET_MARGIN_PX * metres_per_pixel
