class_name World
extends Node3D

## The city at runtime: cutaway, fading, closed rooms, doors, moving parts,
## residents, and the light changing between the corridors and the roof.
##
## Visibility bands: geometry above Mei's level is hidden (the cutaway), and
## on her level anything standing between her and the camera fades. A closed
## room keeps its lid on and hides its furniture and people until Mei walks
## in; its walls only fade where they stand directly in front of her.
## Nothing appears or disappears when the view turns.

signal resident_blocked(resident_id: String)

@export var level: Node3D
@export var level_data: LevelData
@export var environment: WorldEnvironment
@export var sun: DirectionalLight3D

var walk_space: WalkSpace
var roof_mix := 0.0
var current_room := ""
var fabric_state := "catwalk"     # "catwalk" -> "bundle" (in the Chan boy's arms) -> "roof"
var residents: Dictionary = {}    # id -> Resident (story and neighbours)
var doors: Array[Dictionary] = []
var holds: Array[Dictionary] = []
var refs: Dictionary = {}
var special: Dictionary = {}      # name -> Node3D ("Fabric", "Bundle", "Sheet", "LostPigeon", "Tank", "Plane", "Fan")
var sheet_blocking := true
## While a photograph renders, every card turns to the studio camera instead.
var sprite_yaw_override := NAN

var _items: Array[Dictionary] = []
var _sprites: Array[CharacterSprite] = []
var _cloths: Array[Node3D] = []
var _lights: Array[OmniLight3D] = []
var _time := 0.0
var _plane_t := -1.0
var _pb := -1
var _dust: GPUParticles3D


func _ready() -> void:
	walk_space = level_data.build_walk_space()
	refs = level_data.refs
	for name in ["Fabric", "Bundle", "Sheet", "LostPigeon", "Tank", "Plane", "Fan"]:
		var n := level.get_node_or_null("Special/" + name)
		if n:
			special[name] = n
	_build_obstacles()
	_collect(level)
	_build_doors()
	_build_holds()
	_build_dust()
	for r in residents.values():
		(r as Resident).blocked_by_mei.connect(func(id: String) -> void: resident_blocked.emit(id))


# ----------------------------------------------------------------------------- setup


func _build_obstacles() -> void:
	for o in level_data.obstacles:
		var key: String = o.key
		var active := Callable()
		if key.begins_with("door:"):
			var door_id := key.substr(5)
			active = func() -> bool: return not _door_open(door_id)
		elif key == "fabric":
			active = func() -> bool: return fabric_state == "catwalk"
		elif key == "sheet":
			active = func() -> bool: return sheet_blocking
		walk_space.add_obstacle(o.x0, o.x1, o.z0, o.z1, o.y, o.name, active)


func _collect(root: Node) -> void:
	for n in root.get_children():
		if n is Resident:
			var r := n as Resident
			residents[r.resident_id] = r
			if r.collides and r.story:
				var res_ref := r
				r.obstacle = walk_space.add_obstacle(0, 0, 0, 0, r.position.y, r.resident_id,
					func() -> bool: return res_ref.visible and not res_ref.gone and not res_ref.ghost)
			if not n.has_meta("band"):
				n.set_meta("band", PerspectiveRules.band_of(n.global_position.y + 0.5))
			_items.append(_item(n))
			continue
		if n is CharacterSprite:
			_sprites.append(n)
		if n is OmniLight3D and n.has_meta("band"):
			_lights.append(n)
			continue
		if n.has_meta("cloth"):
			_cloths.append(n)
		if n.has_meta("band"):
			_items.append(_item(n))
		_collect(n)


func _item(n: Node3D) -> Dictionary:
	var meshes: Array[GeometryInstance3D] = []
	_meshes_of(n, meshes)
	for m in meshes:
		if m.material_override is ShaderMaterial:
			var base: Variant = m.get_instance_shader_parameter("emission_scale")
			m.set_meta("emission_base", float(base) if base != null else 1.0)
	var aabb := AABB()
	var first := true
	for m in meshes:
		if m is VisualInstance3D:
			var b: AABB = m.global_transform * (m as VisualInstance3D).get_aabb()
			aabb = b if first else aabb.merge(b)
			first = false
	var it := {
		"node": n,
		"band": float(n.get_meta("band")),
		"fadeable": bool(n.get_meta("fadeable", false)),
		"room": String(n.get_meta("room", "")),
		"is_lid": n.has_meta("is_lid"),
		"is_floor": n.has_meta("is_floor"),
		"filler": n.has_meta("filler"),
		"dynamic": n.has_meta("dynamic") or (n is Resident and (n as Resident).story),
		"meshes": meshes,
		"aabb": aabb,
		"opacity": 1.0,
		"visible": true,
		"content_of": "",
	}
	if not it.room and not it.is_floor and not (n is Resident):
		it.content_of = room_at_point(aabb.get_center())
	return it


func _meshes_of(n: Node, out: Array[GeometryInstance3D]) -> void:
	if n is GeometryInstance3D:
		out.append(n)
	for c in n.get_children():
		if c is Resident:
			continue
		_meshes_of(c, out)


func _build_doors() -> void:
	for d in level_data.doors:
		var entry := d.duplicate()
		entry["pivot"] = level.get_node(d.path)
		entry["spill"] = level.get_node_or_null(d.spill_path) if d.spill_path != "" else null
		entry["discovered"] = false
		entry["open"] = false
		entry["open_t"] = 0.0
		doors.append(entry)


func _build_holds() -> void:
	for h in level_data.holds:
		var entry := h.duplicate()
		entry["discovered"] = false
		holds.append(entry)


func _build_dust() -> void:
	_dust = GPUParticles3D.new()
	_dust.name = "Dust"
	_dust.amount = 220
	_dust.lifetime = 9.0
	_dust.preprocess = 9.0
	_dust.visibility_aabb = AABB(Vector3(-10, -2, -10), Vector3(20, 8, 20))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(8, 2.2, 8)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.08
	pm.gravity = Vector3(0, 0.01, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.4
	pm.turbulence_noise_scale = 2.0
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	_dust.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	var m := StandardMaterial3D.new()
	m.albedo_texture = preload("res://assets/textures/props/soft_dot.png")
	m.albedo_color = Color(1.0, 0.9, 0.72, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	q.material = m
	_dust.draw_pass_1 = q
	_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_dust)


# ----------------------------------------------------------------------------- queries


func room_at_point(c: Vector3) -> String:
	for r in level_data.closed_rooms:
		if c.y < r.y - 0.1 or c.y > r.y + 4.2:
			continue
		for rect in r.rects:
			if c.x > rect[0] and c.x < rect[1] and c.z > rect[2] and c.z < rect[3]:
				return r.id
	return ""


func room_at(p: Vector3) -> String:
	for r in level_data.closed_rooms:
		if absf(p.y - r.y) > 2.0:
			continue
		for rect in r.rects:
			if p.x > rect[0] and p.x < rect[1] and p.z > rect[2] and p.z < rect[3]:
				return r.id
	return ""


func door(id: String) -> Dictionary:
	for d in doors:
		if d.id == id:
			return d
	return {}


func _door_open(id: String) -> bool:
	var d := door(id)
	return not d.is_empty() and d.open


func hold(id: String) -> Dictionary:
	for h in holds:
		if h.id == id:
			return h
	return {}


func open_door(d: Dictionary) -> void:
	d.open = true
	if d.spill:
		(d.spill as Node3D).visible = false
		(d.spill as Node3D).set_meta("gone", true)


# ----------------------------------------------------------------------------- story changes


## The washing is moved, not deleted: the Chan boy takes it down from the
## catwalk, carries it upstairs and hangs it on the roof line.
func set_fabric_state(state: String) -> void:
	fabric_state = state
	var f: Node3D = special.Fabric
	var bundle: Node3D = special.Bundle
	if state == "catwalk":
		f.position = Vector3(16, LevelBuilder.LEVEL_B + 2.6, -12)
		f.rotation.y = 0.0
		f.visible = true
		f.set_meta("gone", false)
		residents.son.set_carrying(false)
	elif state == "roof":
		f.position = refs.roofFabricPos
		f.rotation.y = PI / 2.0
		f.visible = true
		f.set_meta("gone", false)
		residents.son.set_carrying(false)
	else:
		f.set_meta("gone", true)
		f.visible = false
		residents.son.set_carrying(true)
	bundle.visible = false


func play_plane() -> void:
	var p: Node3D = special.Plane
	p.visible = true
	p.position = Vector3(-110, 21, -31)
	_plane_t = 0.0


# ----------------------------------------------------------------------------- per frame


func update(delta: float, player: Player, cam: CameraRig, paused: bool) -> void:
	_time += delta
	var pb := player.band()
	var p := player.position
	var back := cam.back_vector()
	var right := cam.right_vector()
	current_room = room_at(p)

	for d in doors:
		var target := 1.0 if d.open else 0.0
		d.open_t = d.open_t + (target - d.open_t) * minf(1.0, delta * 6.0)
		(d.pivot as Node3D).rotation.y = d.base_yaw - d.open_t * PI * 0.55

	var yaw := cam.current_yaw if is_nan(sprite_yaw_override) else sprite_yaw_override
	for r in residents.values():
		var res := r as Resident
		if res.story:
			res.tick(delta, paused, p, yaw)
		else:
			res.sprite.camera_yaw = yaw

	for it in _items:
		var node: Node3D = it.node
		if it.dynamic:
			it.band = PerspectiveRules.band_of(node.global_position.y + 0.5)
			if node is Resident:
				it.content_of = room_at_point(node.global_position + Vector3(0, 0.5, 0))
		var vis := PerspectiveRules.band_visible(it.band, pb)
		if it.content_of != "" and it.content_of != current_room:
			vis = false
		if node.get_meta("gone", false):
			vis = false
		if node is Resident:
			var res2 := node as Resident
			if res2.gone:
				vis = false
		if vis != it.visible:
			it.visible = vis
			node.visible = vis
		if not vis or not it.fadeable:
			continue
		var target_op := 1.0
		var same_band: bool = it.band == pb or (pb == 2 and it.band == 1.5)
		if it.is_lid and it.room == current_room:
			target_op = 0.0
		elif same_band:
			var b: AABB = it.aabb
			var smin := INF
			var lmin := INF
			var lmax := -INF
			for x in [b.position.x, b.end.x]:
				for z in [b.position.z, b.end.z]:
					var dx: float = x - p.x
					var dz: float = z - p.z
					var s := dx * back.x + dz * back.z
					var l := dx * right.x + dz * right.z
					smin = minf(smin, s)
					lmin = minf(lmin, l)
					lmax = maxf(lmax, l)
			# a closed room Mei isn't in, and the city's buildings, only fade where they
			# actually stand in front of her; room shells fade across the view
			var reach := 15.0
			if it.room != "" and it.room != current_room:
				reach = 2.5
			elif it.filler:
				reach = 7.0
			if smin > 0.25 and lmax > -reach and lmin < reach and b.end.y > p.y + 0.9:
				target_op = 0.12 if it.filler else 0.06
		if absf(it.opacity - target_op) > 0.004:
			it.opacity = it.opacity + (target_op - it.opacity) * minf(1.0, delta * 10.0)
			if absf(it.opacity - target_op) <= 0.004:
				it.opacity = target_op
			var tr: float = 0.0 if it.opacity >= 0.995 else 1.0 - it.opacity
			for m in it.meshes:
				var gi := m as GeometryInstance3D
				gi.transparency = tr
				# lit windows on a faded building must not float in mid-air
				if gi.has_meta("emission_base"):
					gi.set_instance_shader_parameter("emission_scale", float(gi.get_meta("emission_base")) * it.opacity * it.opacity)

	# interior vs rooftop light
	var roof_target := 1.0 if pb == 2 else 0.0
	roof_mix += (roof_target - roof_mix) * minf(1.0, delta * 1.2)
	_apply_light_mix(p, pb)

	for c in _cloths:
		c.rotation.z = sin(_time * 1.7 + c.global_position.x * 2.0 + c.global_position.z) * (0.03 + roof_mix * 0.06)
	if special.has("Fan"):
		(special.Fan as Node3D).rotation.z += delta * 12.0

	var sun_dir := -sun.global_transform.basis.z
	for s in _sprites:
		s.camera_yaw = yaw
		s.sun_direction = sun_dir
	for r in residents.values():
		(r as Resident).sprite.sun_direction = sun_dir

	# the folded washing rides in the Chan boy's arms (drawn on his sprite)
	if _plane_t >= 0.0:
		_plane_t += delta
		var pl: Node3D = special.Plane
		pl.position.x += delta * 42.0
		pl.position.y -= delta * 0.9
		if pl.position.x > 150.0:
			pl.visible = false
			_plane_t = -1.0

	_dust.global_position = p + Vector3(0, 1.5, 0)
	_dust.visible = roof_mix < 0.9


func _apply_light_mix(p: Vector3, pb: int) -> void:
	var t := roof_mix
	var env := environment.environment
	env.fog_light_color = Color(0.125, 0.11, 0.1).lerp(Color(0.72, 0.8, 0.88), t)
	env.fog_depth_begin = lerpf(31.0, 60.0, t)
	env.fog_depth_end = lerpf(72.0, 200.0, t)
	env.fog_density = lerpf(1.0, 0.55, t)
	env.ambient_light_color = Color(0.58, 0.53, 0.48).lerp(Color(0.8, 0.85, 0.93), t)
	env.ambient_light_energy = lerpf(1.05, 1.1, t)
	env.background_energy_multiplier = lerpf(0.0, 1.0, t)
	env.volumetric_fog_density = lerpf(0.012, 0.003, t)
	env.glow_intensity = lerpf(0.9, 0.55, t)
	var sky_mat := env.sky.sky_material as ShaderMaterial
	if sky_mat:
		sky_mat.set_shader_parameter("roof_mix", t)
	sun.light_energy = lerpf(0.45, 2.4, t)
	sun.light_color = Color(1.0, 0.94, 0.85).lerp(Color(1.0, 0.8, 0.58), t)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = lerpf(34.0, 60.0, t)
	for l in _lights:
		var lb := int(l.get_meta("band"))
		l.visible = pb != 2 and lb == pb
		l.light_energy = float(l.get_meta("base_energy")) * (1.0 - 0.5 * t)
	if pb != _pb:
		_pb = pb
