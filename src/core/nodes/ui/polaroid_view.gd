class_name PolaroidView
extends Control

## The Polaroid: slides in tilted, the image develops over three seconds,
## the name is written underneath by hand, and a moment later it goes into the album.

@onready var card: Control = %Card
@onready var photo: TextureRect = %Photo
@onready var caption: Label = %Caption
@onready var keep: RichTextLabel = %Keep

var can_dismiss := false


func _ready() -> void:
	visible = false
	keep.text = ""      # it goes into the album by itself once developed


func present(tex: Texture2D, name_text: String) -> void:
	photo.texture = tex
	caption.text = name_text
	visible = true
	can_dismiss = false
	keep.modulate.a = 0.0
	card.pivot_offset = card.size * 0.5
	card.rotation_degrees = -2.5
	card.scale = Vector2(0.92, 0.92)
	card.modulate.a = 0.0
	var mat := photo.material as ShaderMaterial
	mat.set_shader_parameter("develop", 0.0)
	mat.set_shader_parameter("seed", randf() * 100.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(card, "modulate:a", 1.0, 0.4)
	tw.tween_property(card, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "rotation_degrees", -2.0, 0.7)
	var dev := create_tween()
	dev.tween_interval(0.1)
	dev.tween_method(func(v: float) -> void: mat.set_shader_parameter("develop", v), 0.0, 1.0, 3.0).set_ease(Tween.EASE_IN)
	await dev.finished
	can_dismiss = true
	create_tween().tween_property(keep, "modulate:a", 1.0, 0.6)


func dismiss() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		visible = false
		modulate.a = 1.0)
