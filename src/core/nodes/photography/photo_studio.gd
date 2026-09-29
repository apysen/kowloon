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
}

@export var world: World

@onready var cam: Camera3D = $Camera3D


func _ready() -> void:
	size = Vector2i(640, 640)
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	cam.current = true


## Renders the shot for a resident and returns it as a texture.
func shoot(id: String) -> Texture2D:
	var shot: Dictionary = SHOTS.get(id, SHOTS.lau)
	cam.fov = shot.fov
	cam.global_position = shot.eye
	cam.look_at(shot.look, Vector3.UP)
	var r: Resident = world.residents.get(id)
	if r:
		r.face_toward(shot.face, 4.0)
	world.sprite_yaw_override = cam.global_rotation.y
	world.view_from = shot.stand
	await get_tree().process_frame
	await get_tree().process_frame
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)      # a print is opaque: the sky renders with zero alpha
	world.sprite_yaw_override = NAN
	world.view_from = null
	return ImageTexture.create_from_image(img)
