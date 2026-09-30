class_name Progress
extends RefCounted

## Which chapter is being played, and how far the player has got (remembered).
##
## Each chapter is one day, loaded fresh: the slice reads `chapter` when it
## starts. The prints Mei kept come with her into the next day (`carried_photos`),
## and anything built into the level for only some days lives under
## ChapterProps/Ch<first>-<last> and is taken out on the other days.
## KOWLOON_CHAPTER picks the chapter for tests and captures.

const LAST := 6

static var chapter := 1
static var carried_photos: Dictionary = {}     # id -> Texture2D
## Mrs. Cheung's book, Chapter 4: from then on the album keeps where people went
static var after_unlocked := false
## Notes Mei writes into a page later on (Mr. Ho's addendum, the empty rooms'
## captions): the ids whose later note is in
static var late_notes: Dictionary = {}
static var _forced_read := false


## The chapter to play, once per run: KOWLOON_CHAPTER if set.
static func resolve() -> int:
	if not _forced_read:
		_forced_read = true
		var forced := OS.get_environment("KOWLOON_CHAPTER")
		if forced.is_valid_int():
			chapter = clampi(int(forced), 1, LAST)
	if chapter > 4:
		after_unlocked = true
	if chapter > 5:
		for id in ["ho", "wong_room", "lau_clinic"]:
			late_notes[id] = true
	if chapter > 6:
		for id in ["ng", "kit", "wong_after"]:
			late_notes[id] = true
	return chapter


static func reached() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SettingsFile.path()) == OK:
		return clampi(int(cfg.get_value("progress", "chapter", 1)), 1, LAST)
	return 1


static func reach(n: int) -> void:
	if n <= reached():
		return
	var cfg := ConfigFile.new()
	cfg.load(SettingsFile.path())
	cfg.set_value("progress", "chapter", n)
	cfg.save(SettingsFile.path())


## Does a ChapterProps group named "Ch2-4" (or "Ch2") belong in this chapter?
static func group_in_chapter(group_name: String, n: int) -> bool:
	var span := group_name.trim_prefix("Ch").split("-")
	var first := int(span[0])
	var last := int(span[1]) if span.size() > 1 else first
	return n >= first and n <= last
