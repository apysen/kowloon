extends SceneTree

## Finds surfaces in the baked level that would flicker: two boxes whose faces
## lie in the same plane, facing the same way, overlapping, and drawn
## differently (another surface or tint). The renderer cannot tell which is in
## front, so they fight as the view moves.
##
##   godot --headless --path . --script res://tools/level/check_coplanar.gd
##
## Prints each pair of node names with how many overlaps it has, worst first.

const EPS := 0.00003
const MIN_AREA := 0.0004       # 2 cm x 2 cm


func _initialize() -> void:
	var level: Node3D = (load("res://scenes/slice/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	_run.call_deferred(level)


func _run(level: Node3D) -> void:
	var faces := {}                 # [axis, sign, plane] -> Array of {rect, look, name}
	var boxes := 0
	for n in level.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.mesh is BoxMesh or not mi.is_visible_in_tree():
			continue
		var b := mi.global_transform.basis
		if not _axis_aligned(b):
			continue
		boxes += 1
		var aabb := mi.global_transform * mi.get_aabb()
		var look := "%s|%s" % [mi.material_override.resource_path if mi.material_override else "", str(mi.get_instance_shader_parameter("tint"))]
		for axis in 3:
			var u := (axis + 1) % 3
			var v := (axis + 2) % 3
			var rect := Rect2(aabb.position[u], aabb.position[v], aabb.size[u], aabb.size[v])
			for sgn in [-1, 1]:
				var plane: float = aabb.position[axis] + (aabb.size[axis] if sgn > 0 else 0.0)
				var key := "%d|%d|%d" % [axis, sgn, roundi(plane / EPS)]
				if not faces.has(key):
					faces[key] = []
				(faces[key] as Array).append({"rect": rect, "look": look, "name": String(level.get_path_to(mi))})
	var pairs := {}
	for key in faces:
		var list: Array = faces[key]
		for i in list.size():
			for j in range(i + 1, list.size()):
				var a: Dictionary = list[i]
				var c: Dictionary = list[j]
				if a.look == c.look:
					continue
				var o := (a.rect as Rect2).intersection(c.rect)
				if o.get_area() < MIN_AREA:
					continue
				var names := [_short(a.name), _short(c.name)]
				names.sort()
				var k := " <> ".join(names)
				pairs[k] = int(pairs.get(k, 0)) + 1
	var keys := pairs.keys()
	keys.sort_custom(func(x, y): return pairs[x] > pairs[y])
	print("coplanar check: %d boxes, %d fighting pairs" % [boxes, keys.size()])
	for k in keys.slice(0, 60):
		print("  %4d  %s" % [pairs[k], k])
	quit(0)


func _axis_aligned(b: Basis) -> bool:
	for c in [b.x, b.y, b.z]:
		var n := (c as Vector3).normalized().abs()
		if not (n.is_equal_approx(Vector3.RIGHT) or n.is_equal_approx(Vector3.UP) or n.is_equal_approx(Vector3.BACK)):
			return false
	return true


## The node's name and its parent's, without the numbering Godot adds.
func _short(path: String) -> String:
	var parts := path.split("/")
	var tail := parts.slice(maxi(0, parts.size() - 2))
	var out: Array[String] = []
	for p in tail:
		var s := String(p)
		while s.length() > 0 and (s[s.length() - 1] >= "0" and s[s.length() - 1] <= "9"):
			s = s.substr(0, s.length() - 1)
		out.append(s)
	return "/".join(out)
