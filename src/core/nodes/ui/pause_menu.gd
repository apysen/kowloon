class_name PauseMenu
extends Control

## Esc: the game stops, the city dims, and a small card offers Resume,
## the volume, the graphics setting and the way back to the title.
## Runs while the tree is paused; Esc again (or Resume) carries on.

signal closed
signal quit_requested

@export var audio_settings: AudioSettings
@export var display: DisplaySettings

@onready var resume_button: Button = %Resume
@onready var volume_slider: HSlider = %Volume
@onready var volume_value: Label = %VolumeValue
@onready var graphics_button: Button = %Graphics
@onready var quit_button: Button = %Quit
@onready var tick: AudioStreamPlayer = %Tick

var open := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(close)
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	graphics_button.pressed.connect(_toggle_graphics)
	volume_slider.value_changed.connect(_on_volume)
	volume_slider.drag_ended.connect(func(_changed: bool) -> void: tick.play())


func show_menu() -> void:
	if open:
		return
	open = true
	visible = true
	get_tree().paused = true
	volume_slider.set_value_no_signal(roundf(audio_settings.volume * 100.0))
	volume_value.text = "%d" % int(volume_slider.value)
	_label_graphics()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
	resume_button.grab_focus()


func close() -> void:
	if not open:
		return
	open = false
	visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not open or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action("graphics"):
		_toggle_graphics()
		get_viewport().set_input_as_handled()


func _on_volume(v: float) -> void:
	audio_settings.set_volume(v / 100.0)
	volume_value.text = "%d" % int(v)


func _toggle_graphics() -> void:
	display.toggle()
	_label_graphics()


func _label_graphics() -> void:
	graphics_button.text = "GRAPHICS: FULL" if display.high else "GRAPHICS: FAST"
