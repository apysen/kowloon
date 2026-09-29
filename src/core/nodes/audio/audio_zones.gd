class_name AudioZones
extends Node

## The city heard before it is seen.
##
## Two beds cross-fade with the light: the building's hum inside, wind and
## far traffic on the roof. Important places are audible before they are
## visible: Grandfather's radio is home, the dental drill is Lau's, wind and
## pigeons are the roof. Each emitter fades with distance and falls away
## sharply through floors, the slice's own "level factor", rather than
## physically accurate falloff, because it is a wayfinding cue first.

const DIR := "res://assets/audio/"

var fabric_moved := false
var _beds: Dictionary = {}
var _emitters: Array[Dictionary] = []
var _one_shots: Array[AudioStreamPlayer] = []
var _started := false
var _master := 1.0
var _silence_t := -1.0
var _silence_len := 1.0


func _stream(name: String, loop := false) -> AudioStreamWAV:
	var s: AudioStreamWAV = load(DIR + name + ".wav")
	if loop:
		s = s.duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	return s


func _player(stream: AudioStream, db := -80.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	add_child(p)
	return p


func start() -> void:
	if _started:
		return
	_started = true
	_beds.interior = _player(_stream("interior_hum", true))
	_beds.roof = _player(_stream("roof_wind", true))
	for b in _beds.values():
		(b as AudioStreamPlayer).play()

	# places, looped
	_loop_emitter("radio", "radio_loop", Vector3(-13.7, 0, -1.3), 16.0, 0.0, 0.9)
	_loop_emitter("tv", "tv_loop", Vector3(3, 5, -12), 9.0, 5.0, 0.6)
	# places, as repeating one-shots
	_shot_emitter("drill", ["drill_0", "drill_1", "drill_2"], Vector3(5, 0, -12.5), 14.0, 0.0, [1.8, 5.0], 0.32)
	_shot_emitter("mahjong", ["mahjong_0", "mahjong_1", "mahjong_2", "mahjong_3"], Vector3(-2, 0, 2.7), 10.0, 0.0, [0.3, 1.9], 0.8)
	_shot_emitter("chop", ["chop_0", "chop_1", "chop_2"], Vector3(-3.4, 0, 2.1), 9.0, 0.0, [0.22, 0.3], 0.8, 0.15)
	_shot_emitter("drip", ["drip_0", "drip_1", "drip_2"], Vector3(-5, 5, -18.5), 8.0, 5.0, [0.5, 2.3], 0.6)
	var fd := _shot_emitter("fabric_drip", ["drip_1", "drip_2"], Vector3(16, 5, -12), 7.0, 5.0, [0.3, 1.3], 0.6)
	fd["enabled"] = func() -> bool: return not fabric_moved
	_shot_emitter("pigeons", ["coo_0", "coo_1", "coo_2"], Vector3(3, 13, -22), 22.0, 13.0, [0.8, 3.0], 0.7)
	_shot_emitter("kids", ["kids_0", "kids_1"], Vector3(-8, 13, -8), 30.0, 13.0, [3.0, 9.0], 0.5)
	for i in 6:
		_one_shots.append(_player(null, 0.0))


func _loop_emitter(name: String, file: String, pos: Vector3, radius: float, level: float, gain: float) -> Dictionary:
	var p := _player(_stream(file, true))
	p.play()
	var e := {"name": name, "pos": pos, "radius": radius, "level": level, "gain": gain, "player": p, "loop": true}
	_emitters.append(e)
	return e


func _shot_emitter(name: String, files: Array, pos: Vector3, radius: float, level: float, every: Array, gain: float, pause_chance := 0.0) -> Dictionary:
	var streams: Array[AudioStream] = []
	for f in files:
		streams.append(_stream(f))
	var p := _player(null)
	var e := {"name": name, "pos": pos, "radius": radius, "level": level, "gain": gain, "player": p, "loop": false,
		"streams": streams, "every": every, "timer": randf() * float(every[1]), "pause": pause_chance, "vol": 0.0}
	_emitters.append(e)
	return e


func update(delta: float, player_pos: Vector3, roof_mix: float, muted: bool) -> void:
	if not _started:
		return
	if _silence_t >= 0.0:
		_silence_t += delta
		_master = maxf(0.0, 1.0 - _silence_t / _silence_len)
	var m := 0.0 if muted else _master
	_set_gain(_beds.interior, 0.55 * (1.0 - roof_mix) * m, delta, 0.3)
	_set_gain(_beds.roof, 0.6 * roof_mix * m, delta, 0.5)
	for e in _emitters:
		var pos: Vector3 = e.pos
		var dy := absf(player_pos.y - pos.y)
		var level_factor := 1.0 if dy < 3.0 else (0.2 if dy < 9.0 else 0.05)
		var d := Vector2(player_pos.x - pos.x, player_pos.z - pos.z).length()
		var v := maxf(0.0, 1.0 - d / float(e.radius))
		v = v * v * level_factor * m * float(e.gain)
		if e.has("enabled") and not (e.enabled as Callable).call():
			v = 0.0
		if e.loop:
			_set_gain(e.player, v, delta, 0.15)
		else:
			e.vol = v
			e.timer = float(e.timer) - delta
			if float(e.timer) <= 0.0:
				var every: Array = e.every
				e.timer = randf_range(float(every[0]), float(every[1]))
				if randf() < float(e.pause):
					e.timer = float(e.timer) + 1.4
				if v > 0.005:
					var p: AudioStreamPlayer = e.player
					var streams: Array = e.streams
					p.stream = streams[randi() % streams.size()]
					p.volume_db = linear_to_db(v)
					p.pitch_scale = randf_range(0.94, 1.06)
					p.play()


func _set_gain(p: AudioStreamPlayer, linear: float, delta: float, tc: float) -> void:
	var cur := db_to_linear(p.volume_db)
	var next := cur + (linear - cur) * minf(1.0, delta / tc)
	p.volume_db = linear_to_db(maxf(next, 0.00001))


func _shot(file: String, gain := 1.0, pitch := 1.0, delay := 0.0) -> void:
	if not _started:
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	for p in _one_shots:
		if not p.playing:
			p.stream = _stream(file)
			p.volume_db = linear_to_db(gain * _master)
			p.pitch_scale = pitch
			p.play()
			return


func blip(speaker: String) -> void:
	_shot("blip", 0.5, ResidentCatalog.VOICE_PITCH.get(speaker, 1.0))


func shutter() -> void:
	_shot("shutter", 0.9)


func click() -> void:
	_shot("camera_up", 0.6)


func chime() -> void:
	_shot("chime", 0.6)


func footsteps(n := 8, interval := 0.16) -> void:
	for i in n:
		_shot("step_%d" % (i % 4), 0.5, randf_range(0.95, 1.05), i * interval)


func creak() -> void:
	_shot("creak", 0.6)


func flutter() -> void:
	_shot("flutter", 0.7)
	_shot("coo_1", 0.6, 1.0, 0.9)


func coo() -> void:
	_shot("coo_%d" % (randi() % 3), 0.7)


func plane() -> void:
	_shot("plane", 1.0)


## The ending: everything drains away.
func silence(secs := 2.5) -> void:
	_silence_len = secs
	_silence_t = 0.0
