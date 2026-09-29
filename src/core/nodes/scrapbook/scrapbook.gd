class_name Scrapbook
extends Node

## The people Mei has photographed, in the order she met them.

@export var locks: ControlLocks
@export var panel: ScrapbookPanel
@export var photography: PhotographyDirector
@export var studio: PhotoStudio

var entries: Array[String] = []
var open := false


func add(id: String) -> void:
	if not entries.has(id):
		entries.append(id)


func toggle(force: Variant = null) -> void:
	var next: bool = (not open) if force == null else bool(force)
	if next == open:
		return
	if next and locks.is_locked():
		return
	open = next
	if next:
		locks.lock("scrapbook")
		# prints made by a debug stage jump are taken now
		for id in entries:
			if not photography.photos.has(id):
				photography.photos[id] = await studio.shoot(id)
		panel.render(entries, photography.photos)
		panel.visible = true
		panel.modulate.a = 0.0
		create_tween().tween_property(panel, "modulate:a", 1.0, 0.25)
	else:
		panel.visible = false
		locks.unlock("scrapbook")
