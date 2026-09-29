class_name Scrapbook
extends Node

## The people Mei has photographed, in the order she met them.

@export var locks: ControlLocks
@export var panel: ScrapbookPanel
@export var photography: PhotographyDirector
@export var studio: PhotoStudio

signal closed

var entries: Array[String] = []
var open := false


func add(id: String) -> void:
	if not entries.has(id):
		entries.append(id)


## A photograph just kept: it goes straight into the album, taped onto its
## page while the player watches, and the album shuts again.
func file_photo(id: String) -> void:
	add(id)
	if open or panel.busy:
		return
	open = true
	locks.lock("scrapbook")
	var polaroid := photography.polaroid
	var from := polaroid.card.get_global_rect()
	polaroid.visible = false
	panel.visible = true
	await panel.file_photo(entries, photography.photos, id, from)
	# it stays open on the new page; the story goes on once the player shuts it
	if open:
		await closed


func toggle(force: Variant = null) -> void:
	var next: bool = (not open) if force == null else bool(force)
	if next == open or panel.busy:
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
		panel.visible = true
		await panel.open_book(entries, photography.photos)
	else:
		await panel.close_book()
		panel.visible = false
		locks.unlock("scrapbook")
		closed.emit()
