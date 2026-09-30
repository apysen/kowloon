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
var fabric_state := "catwalk"     # "catwalk" -> "bundle" (in Wai's arms) -> "roof"
var residents: Dictionary = {}    # id -> Resident (story and neighbours)
var doors: Array[Dictionary] = []
var holds: Array[Dictionary] = []
var refs: Dictionary = {}
var special: Dictionary = {}      # name -> Node3D ("Fabric", "Bundle", "Sheet", "LostPigeon", "Tank", "Plane", "Fan")
var sheet_blocking := true
## Ways the story has opened (World.open_ways["plank"] = true): their obstacles give way.
var open_ways: Dictionary = {}
## Open-air floors below the roof: the sky comes in there too.
const OPEN_AIR := ["workshopRoof", "neighbourBalcony", "plankWay", "platformWay", "yamen", "yamenMouth", "yamenLane", "yamenBalcony"]
## While a photograph renders, every card turns to the studio camera instead.
var sprite_yaw_override := NAN
## While a photograph renders, the cutaway shows the world as if Mei stood here.
var view_from: Variant = null
## Looking through Mei's eyes: nothing is cut away. Every floor shows, every
## wall and ceiling stays solid, and people in other rooms are there to be seen.
var first_person := false
## How far into the evening it is (0 afternoon, 1 dusk): the sun lower, redder
## and weaker, the sky dimmer (Chapter 6's last evening).
var dusk := 0.0

var _items: Array[Dictionary] = []
## Pieces that fade, move or belong to a room: looked at every frame.
var _live: Array[Dictionary] = []
## Everything else (most of the city): only its band decides, so it is
## re-checked in full when Mei changes level and otherwise a slice per frame.
var _static: Array[Dictionary] = []
var _static_pb := -1
var _static_at := 0
var _sprites: Array[CharacterSprite] = []
var _cloths: Array[Node3D] = []
var _lights: Array[OmniLight3D] = []
var _time := 0.0
var crate_obstacle: WalkSpace.Obstacle
var _cloth_pivots: Array[Dictionary] = []
var _plane_t := -1.0
var _pb := -1
var _dust: GPUParticles3D


func _ready() -> void:
	walk_space = level_data.build_walk_space()
	refs = level_data.refs
	for name in ["Fabric", "Bundle", "Sheet", "LostPigeon", "Tank", "Plane", "Fan", "Crate", "Ladder", "CoopFlap"]:
		var n := level.get_node_or_null("Special/" + name)
		if n:
			special[name] = n
	_build_obstacles()
	_collect(level)
	_hang_cloths()
	for it in _items:
		var live: bool = it.fadeable or it.dynamic or it.content_of != "" or it.node is Resident or it.above != ""
		(_live if live else _static).append(it)
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
		elif key.begins_with("way:"):
			# a way that opens when the story opens it (the plank laid, the sign folded)
			var way := key.substr(4)
			active = func() -> bool: return not open_ways.has(way)
		elif key.begins_with("chapter:"):
			# built for only some days (ChapterProps): "chapter:Ch2-4"
			var span := key.substr(8)
			active = func() -> bool: return Progress.group_in_chapter(span, Progress.chapter)
		var ob := walk_space.add_obstacle(o.x0, o.x1, o.z0, o.z1, o.y, o.name, active)
		if key == "crate":
			crate_obstacle = ob


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
		# on top of a closed room: out of sight while Mei is in the room below
		"above": String(n.get_meta("above_room", "")),
		"is_lid": n.has_meta("is_lid"),
		"is_floor": n.has_meta("is_floor"),
		"filler": n.has_meta("filler"),
		"dynamic": n.has_meta("dynamic") or (n is Resident and (n as Resident).story),
		"meshes": meshes,
		"aabb": aabb,
		"opacity": 1.0,
		"visible": true,
		"content_of": "",
		"swings": false,
	}
	# doors stand in a room's boundary: they are never its hidden contents
	var in_doors := String(level.get_path_to(n)).begins_with("Doors")
	it.swings = in_doors and n.get_parent().name == "Doors"
	if not it.room and not it.is_floor and not (n is Resident) and not in_doors:
		it.content_of = room_at_point(aabb.get_center())
	return it


## Each piece of washing hangs from its line: a pivot at the top edge, so the
## breeze swings it out and back instead of turning it about its middle.
func _hang_cloths() -> void:
	for c in _cloths:
		var mi := c as MeshInstance3D
		if mi == null or not (mi.mesh is BoxMesh):
			continue
		var size: Vector3 = (mi.mesh as BoxMesh).size
		var parent := mi.get_parent()
		var pivot := Node3D.new()
		pivot.name = mi.name + "Hanger"
		parent.add_child(pivot)
		pivot.transform = Transform3D(mi.transform.basis, mi.transform * Vector3(0, size.y * 0.5, 0))
		parent.remove_child(mi)
		pivot.add_child(mi)
		mi.transform = Transform3D(Basis.IDENTITY, Vector3(0, -size.y * 0.5, 0))
		# swing about the line: the cloth's long horizontal axis
		_cloth_pivots.append({"pivot": pivot, "axis_x": size.x >= size.z})


func move_crate(p: Vector3) -> void:
	(special.Crate as Node3D).position = p
	crate_obstacle.x0 = p.x - 0.35
	crate_obstacle.x1 = p.x + 0.35
	crate_obstacle.z0 = p.z - 0.35
	crate_obstacle.z1 = p.z + 0.35


func _static_visibility(it: Dictionary, pb: int) -> void:
	var node: Node3D = it.node
	var vis: bool = PerspectiveRules.band_visible(it.band, pb) and not node.get_meta("gone", false)
	if vis != it.visible:
		it.visible = vis
		node.visible = vis


func _aabb_of(meshes: Array[GeometryInstance3D]) -> AABB:
	var aabb := AABB()
	var first := true
	for m in meshes:
		var b: AABB = m.global_transform * m.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	return aabb


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


## The washing is moved, not deleted: Wai takes it down from the
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


## The jet on its approach, timed to cross above Mr. Ng about 1.7 s from now.
func play_plane() -> void:
	var p: Node3D = special.Plane
	p.visible = true
	p.position = Vector3(-68, 19.5, -30)
	_plane_t = 0.0


func plane_over_roof() -> bool:
	var p: Node3D = special.Plane
	return p.visible and p.position.x > -6.0 and p.position.x < 14.0


## Where the jet is along its approach (x), or INF when none is in the sky.
func plane_x() -> float:
	var p: Node3D = special.Plane
	return p.position.x if p.visible else INF


# ----------------------------------------------------------------------------- per frame


func update(delta: float, player: Player, cam: CameraRig, paused: bool) -> void:
	_time += delta
	var p := player.position if view_from == null else (view_from as Vector3)
	var pb := PerspectiveRules.player_band(p.y)
	var back := cam.back_vector()
	var right := cam.right_vector()
	current_room = room_at(p)

	for d in doors:
		var target := 1.0 if d.open else 0.0
		d.open_t = d.open_t + (target - d.open_t) * minf(1.0, delta * 6.0)
		(d.pivot as Node3D).rotation.y = d.base_yaw - d.open_t * PI * 0.55

	var yaw := cam.current_yaw if is_nan(sprite_yaw_override) else sprite_yaw_override
	if first_person:
		yaw = cam.fp_yaw
	# which bands show: all of them from her eye
	var vb := 2 if first_person else pb
	for r in residents.values():
		var res := r as Resident
		if res.story:
			res.tick(delta, paused, p, yaw)
		else:
			res.sprite.camera_yaw = yaw

	if vb != _static_pb:
		_static_pb = vb
		for it in _static:
			_static_visibility(it, vb)
	elif not _static.is_empty():
		var n := ceili(_static.size() / 8.0)
		for k in n:
			_static_visibility(_static[_static_at], vb)
			_static_at = (_static_at + 1) % _static.size()

	for it in _live:
		var node: Node3D = it.node
		if it.dynamic:
			# people are on whichever level they stand on, as Mei is: up on a
			# low roof between floors they're with her, not with the rooftops
			if node is Resident:
				it.band = float(PerspectiveRules.player_band(node.global_position.y))
			else:
				it.band = PerspectiveRules.band_of(node.global_position.y + 0.5)
			if node is Resident:
				it.content_of = room_at_point(node.global_position + Vector3(0, 0.5, 0))
		var vis := PerspectiveRules.band_visible(it.band, vb)
		if it.content_of != "" and it.content_of != current_room and not first_person:
			vis = false
		if current_room != "" and it.above == current_room:
			vis = false
		elif current_room != "" and node is Resident and room_at_point(node.global_position - Vector3(0, 3.8, 0)) == current_room:
			# someone up on the roof of the room she's in: through the ceiling
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
		if it.swings:
			it.aabb = _aabb_of(it.meshes)
		var target_op := 1.0
		var same_band: bool = it.band == pb or (pb == 2 and it.band == 1.5)
		if first_person:
			pass
		elif it.is_lid and it.room == current_room:
			target_op = 0.0
		elif same_band:
			var b: AABB = it.aabb
			var smin := INF
			var smax := -INF
			var lmin := INF
			var lmax := -INF
			for x in [b.position.x, b.end.x]:
				for z in [b.position.z, b.end.z]:
					var dx: float = x - p.x
					var dz: float = z - p.z
					var s := dx * back.x + dz * back.z
					var l := dx * right.x + dz * right.z
					smin = minf(smin, s)
					smax = maxf(smax, s)
					lmin = minf(lmin, l)
					lmax = maxf(lmax, l)
			# a closed room Mei isn't in, and the city's buildings, only fade where they
			# actually stand in front of her; room shells fade across the view
			var reach := 15.0
			if it.filler:
				reach = 7.0
			elif it.room != "" and it.room != current_room:
				# another room stays closed: only the wall right across the line to Mei gives way
				reach = 1.4
			# a ceiling is overhead: if any of it reaches toward the camera it covers
			# her, even when its edge overhangs just behind her (a doorway)
			var in_front := smax > 0.25 if it.is_lid else smin > 0.25
			if in_front and lmax > -reach and lmin < reach and b.end.y > p.y + 0.9:
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
	var under := walk_space.floor_at(p.x, p.z, p.y)
	var roof_target := 1.0 if pb == 2 or (under != null and OPEN_AIR.has(under.name)) else 0.0
	roof_mix += (roof_target - roof_mix) * minf(1.0, delta * 1.2)
	_apply_light_mix(p, pb)

	var amp := 0.05 + roof_mix * 0.1
	for cp in _cloth_pivots:
		var pivot: Node3D = cp.pivot
		if not pivot.is_visible_in_tree():
			continue
		var gp := pivot.global_position
		if absf(gp.x - p.x) > 30.0 or absf(gp.z - p.z) > 30.0:
			continue
		var a := sin(_time * 1.7 + gp.x * 2.0 + gp.z) * amp
		if cp.axis_x:
			pivot.rotation.x = a
		else:
			pivot.rotation.z = a
	if special.has("Fan"):
		(special.Fan as Node3D).rotation.z += delta * 12.0

	var sun_dir := -sun.global_transform.basis.z
	for s in _sprites:
		s.camera_yaw = yaw
		s.sun_direction = sun_dir
	for r in residents.values():
		(r as Resident).sprite.sun_direction = sun_dir

	# the folded washing rides in Wai's arms (drawn on his sprite)
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
	sun.light_energy = lerpf(0.45, 2.4, t) * (1.0 - 0.72 * dusk)
	sun.light_color = Color(1.0, 0.94, 0.85).lerp(Color(1.0, 0.8, 0.58), t).lerp(Color(1.0, 0.52, 0.32), dusk)
	if dusk > 0.0:
		env.ambient_light_energy *= 1.0 - 0.45 * dusk
		env.ambient_light_color = env.ambient_light_color.lerp(Color(0.46, 0.44, 0.62), dusk * 0.8)
		env.background_energy_multiplier *= 1.0 - 0.6 * dusk
		env.fog_light_color = env.fog_light_color.lerp(Color(0.5, 0.38, 0.42), dusk * t)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = lerpf(34.0, 60.0, t)
	for l in _lights:
		var lb := int(l.get_meta("band"))
		l.visible = pb != 2 and lb == pb
		l.light_energy = float(l.get_meta("base_energy")) * (1.0 - 0.5 * t)
	if pb != _pb:
		_pb = pb
