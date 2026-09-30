class_name ResidentCatalog
extends RefCounted

## Scrapbook entries. The personal note matters more than the facts.
##
## Each field is read from data/i18n/strings.csv as res.<id>.<field>.

const ENTRIES: Array[String] = ["lau", "ng", "ho", "chiu", "cheung"]
const FIELDS: Array[String] = ["name", "occupation", "location", "context", "note"]

## Speaking voices: the pitch of each speaker's dialogue blip, by speaker id.
const VOICE_PITCH := {
	"mei": 1.35, "grandfather": 0.65, "mum": 1.0, "lau": 0.92, "chan": 1.13, "wai": 1.52,
	"ng": 0.74, "wong": 1.04, "ho": 0.82, "neighbour": 0.9, "kit": 1.4, "chiu": 0.78, "hand_a": 1.1, "hand_b": 0.88, "porter": 0.85,
	"cheung": 0.96, "cheng": 1.08, "mover": 0.8, "taichi": 0.7, "bird": 0.72,
}


## A person's entry in the current language, or {} if they have none.
static func entry(id: String) -> Dictionary:
	if not ENTRIES.has(id):
		return {}
	var out := {}
	for f in FIELDS:
		out[f] = TranslationServer.translate("res.%s.%s" % [id, f])
	# where they went, once Mrs. Cheung's book has taught the album to ask
	out["after"] = ""
	if Progress.after_unlocked:
		var key := "res.%s.after" % id
		var after := TranslationServer.translate(key)
		if after != key:
			out["after"] = after
	return out
