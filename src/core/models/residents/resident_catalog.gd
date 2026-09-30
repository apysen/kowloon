class_name ResidentCatalog
extends RefCounted

## Scrapbook entries. The personal note matters more than the facts.
##
## Each field is read from data/i18n/strings.csv as res.<id>.<field>. From
## Chapter 5 some pages are of places, which have no occupation or location,
## and some notes are written in later.

const ENTRIES: Array[String] = ["lau", "ng", "ho", "chiu", "cheung", "line", "lau_clinic", "wong_room", "kit", "wong", "ng_birds", "old_photo"]
## Pages whose note is only written in later (Progress.late_notes): until then, none.
const NOTE_LATER: Array[String] = ["lau_clinic", "wong_room"]
const FIELDS: Array[String] = ["name", "occupation", "location", "context", "note"]
## Pages of places, not people: a name, a note and the history, no byline.
const PLACES: Array[String] = ["line", "lau_clinic", "wong_room", "ng_birds", "old_photo"]
const PLACE_FIELDS: Array[String] = ["name", "context", "note"]
## Pages with no print on them: just her notes, on a sheet taped in.
const NOTE_PAGES: Array[String] = ["kit", "wong"]
const NOTE_FIELDS: Array[String] = ["name", "note"]
## Prints that aren't hers: the picture itself, not a shot of the world.
const FIXED_PRINTS := {"old_photo": "res://assets/textures/props/old_photo.png"}
## Whose AFTER only comes when word of them does (Progress.late_notes).
const AFTER_LATER: Array[String] = ["wong"]

## Speaking voices: the pitch of each speaker's dialogue blip, by speaker id.
const VOICE_PITCH := {
	"mei": 1.35, "grandfather": 0.65, "mum": 1.0, "lau": 0.92, "chan": 1.13, "wai": 1.52,
	"ng": 0.74, "wong": 1.04, "ho": 0.82, "neighbour": 0.9, "kit": 1.4, "chiu": 0.78, "hand_a": 1.1, "hand_b": 0.88, "porter": 0.85,
	"cheung": 0.96, "cheng": 1.08, "mover": 0.8, "taichi": 0.7, "bird": 0.72, "leung": 1.18,
}


## A person's entry in the current language, or {} if they have none.
static func entry(id: String) -> Dictionary:
	if not ENTRIES.has(id):
		return {}
	var out := {"id": id}
	for f in FIELDS:
		out[f] = _field("res.%s.%s" % [id, f]) if fields_of(id).has(f) else ""
	if NOTE_LATER.has(id) and not Progress.late_notes.has(id):
		out["note"] = ""
	# an addendum, in the same hand, added on a later day
	out["later"] = _field("res.%s.later" % id) if Progress.late_notes.has(id) and not NOTE_LATER.has(id) else ""
	# where they went, once Mrs. Cheung's book has taught the album to ask
	out["after"] = ""
	if Progress.after_unlocked:
		var key := "res.%s.after" % id
		var after := TranslationServer.translate(key)
		if after != key and (not AFTER_LATER.has(id) or Progress.late_notes.has(id + "_after")):
			out["after"] = after
	return out


## The fields a page has in the string table.
static func fields_of(id: String) -> Array[String]:
	if NOTE_PAGES.has(id):
		return NOTE_FIELDS
	return PLACE_FIELDS if PLACES.has(id) else FIELDS


static func _field(key: String) -> String:
	var s := TranslationServer.translate(key)
	return "" if s == key else s
