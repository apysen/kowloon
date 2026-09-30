class_name PhotoStudio
extends SubViewport

## The photographs Mei keeps. Each one is predetermined in its framing, as the
## design asks (Mr. Lau with the old chair, Mr. Ng with his birds against the
## sky), but it is taken of the actual scene: a second camera renders the
## moment into a square, and the Polaroid shader develops it.

const SHOTS := {
	"lau": {"eye": Vector3(7.55, 1.45, -9.45), "look": Vector3(5.1, 1.05, -12.2), "fov": 52.0, "face": Vector3(7.55, 0, -9.45),
		"stand": Vector3(5.0, 0, -11.0)},
	"ng": {"eye": Vector3(4.9, 13.75, -17.1), "look": Vector3(3.0, 14.9, -21.8), "fov": 58.0, "face": Vector3(4.9, 13, -17.1),
		"stand": Vector3(3.5, 13, -19.0)},
	# Mr. Ho at the bucket in the hall, washing the grease off his hands
	"ho": {"eye": Vector3(-3.7, 1.45, 0.2), "look": Vector3(-5.1, 1.0, 0.25), "fov": 55.0, "face": Vector3(-3.7, 0, 0.2),
		"stand": Vector3(-3.7, 0, 0.2), "resident": "fanman"},
	# Uncle Chiu's workshop: the hands round the table, one of them looking away
	"chiu": {"eye": Vector3(-2.4, 6.5, 3.3), "look": Vector3(-5.0, 5.9, 1.8), "fov": 60.0, "face": Vector3(-2.4, 5, 3.3),
		"stand": Vector3(-2.4, 5, 3.3)},
	# Mrs. Cheung at her table in the yamen, the address book open
	"cheung": {"eye": Vector3(9.6, 1.35, 1.0), "look": Vector3(9.6, 0.8, -1.5), "fov": 52.0, "face": Vector3(9.6, 0, 1.0),
		"stand": Vector3(9.6, 0, 1.0)},
	# the Chans' line over the catwalk, empty but for its pegs
	"line": {"eye": Vector3(19.2, 6.45, -12.3), "look": Vector3(16.0, 7.1, -12.0), "fov": 58.0, "face": Vector3(19.2, 5, -12.3),
		"stand": Vector3(19.2, 5, -12.3)},
	# Lau's clinic with nothing in it: the pale square on the wall
	"lau_clinic": {"eye": Vector3(6.8, 1.5, -9.8), "look": Vector3(0.2, 1.4, -12.2), "fov": 60.0, "face": Vector3(6.8, 0, -9.8),
		"stand": Vector3(6.8, 0, -9.8)},
	# Mrs. Wong's room: the stripped bed, the one small table
	"wong_room": {"eye": Vector3(24.8, 6.5, -11.6), "look": Vector3(27.5, 5.6, -13.8), "fov": 62.0, "face": Vector3(24.8, 5, -11.6),
		"stand": Vector3(24.8, 5, -11.6)},
}

@export var world: World

@onready var cam: Camera3D = $Camera3D

var _busy := false


func _ready() -> void:
	size = Vector2i(640, 640)
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	cam.current = true


## Renders exactly what Mei framed: the view from her eye, cut to the
## viewfinder's square (`fraction` of the screen's height). Her head's roll is
## left out; a print comes out level.
func shoot_view(eye: Camera3D, fraction: float, subject: Resident = null) -> Texture2D:
	await _wait_turn()
	cam.global_transform = eye.global_transform
	cam.global_rotation.z = 0.0
	cam.fov = rad_to_deg(2.0 * atan(fraction * tan(deg_to_rad(eye.fov) * 0.5)))
	if subject:
		subject.face_toward(eye.global_position, 8.0)
	var tex := await _render()
	_busy = false
	return tex


## Renders the shot for a resident and returns it as a texture.
func shoot(id: String) -> Texture2D:
	var shot: Dictionary = SHOTS.get(id, SHOTS.lau)
	await _wait_turn()
	cam.fov = shot.fov
	cam.global_position = shot.eye
	cam.look_at(shot.look, Vector3.UP)
	var r: Resident = world.residents.get(shot.get("resident", id))
	if r:
		r.face_toward(shot.face, 4.0)
	world.sprite_yaw_override = cam.global_rotation.y
	world.view_from = shot.stand
	var tex := await _render()
	world.sprite_yaw_override = NAN
	world.view_from = null
	_busy = false
	return tex


## One print at a time: two shots at once would share the camera (and the
## world's point of view), each spoiling the other.
func _wait_turn() -> void:
	while _busy:
		await get_tree().process_frame
	_busy = true


func _render() -> Texture2D:
	if DisplayServer.get_name() == "headless":
		# nothing is drawn without a display: a blank print, and no waiting on a
		# frame that never comes
		await get_tree().process_frame
		var blank := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
		return ImageTexture.create_from_image(blank)
	await get_tree().process_frame
	await get_tree().process_frame
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)      # a print is opaque: the sky renders with zero alpha
	return ImageTexture.create_from_image(img)
