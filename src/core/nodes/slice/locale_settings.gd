class_name LocaleSettings
extends RefCounted

## The language: English or Traditional Chinese (Hong Kong). Every string
## lives in data/i18n/strings.csv, keyed; this picks which column is read.
##
## On first run it follows the system language (any Chinese locale gets the
## Traditional text), then remembers what the player chose on the title
## screen or in the pause menu. KOWLOON_LOCALE overrides both (tests, captures).

static var PATH := SettingsFile.path()
const LANGUAGES: Array[String] = ["en", "zh_HK"]

## Chinese faces behind each interface font, cut to the characters the game
## uses (scripts/make_cjk_fonts.py).
const CJK_REGULAR := preload("res://assets/fonts/cjk/NotoSansTC-Regular.ttf")
const CJK_MEDIUM := preload("res://assets/fonts/cjk/NotoSansTC-Medium.ttf")
const CJK_BOLD := preload("res://assets/fonts/cjk/NotoSansTC-Bold.ttf")
const CJK_HAND := preload("res://assets/fonts/cjk/LXGWWenKaiTC-Regular.ttf")

static var _ready := false


## Once per run, before any text is shown.
static func setup() -> void:
	if _ready:
		return
	_ready = true
	_add_fallback(UIStyle.FONT_UI, CJK_MEDIUM)
	_add_fallback(UIStyle.FONT_UI_REGULAR, CJK_REGULAR)
	_add_fallback(UIStyle.FONT_UI_BOLD, CJK_BOLD)
	_add_fallback(UIStyle.FONT_UI_ITALIC, CJK_REGULAR)
	_add_fallback(UIStyle.FONT_MONO, CJK_REGULAR)
	_add_fallback(UIStyle.FONT_HAND, CJK_HAND)
	TranslationServer.set_locale(_initial())


static func current() -> String:
	var loc := TranslationServer.get_locale()
	return "zh_HK" if loc.begins_with("zh") else "en"


static func is_chinese() -> bool:
	return current() == "zh_HK"


## The next language along, applied and remembered.
static func cycle() -> String:
	var next := LANGUAGES[(LANGUAGES.find(current()) + 1) % LANGUAGES.size()]
	TranslationServer.set_locale(next)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("locale", "language", next)
	cfg.save(PATH)
	return next


## "30 DAYS UNTIL WE LEAVE": one day is singular in English.
static func days_until(days: int) -> String:
	return TranslationServer.translate("ending.day" if days == 1 else "ending.days").format({"days": days})


static func _initial() -> String:
	var forced := OS.get_environment("KOWLOON_LOCALE")
	if forced != "":
		return "zh_HK" if forced.begins_with("zh") else "en"
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK and cfg.has_section_key("locale", "language"):
		return String(cfg.get_value("locale", "language"))
	return "zh_HK" if OS.get_locale().begins_with("zh") else "en"


static func _add_fallback(font: Font, fallback: Font) -> void:
	var list := font.fallbacks
	if not list.has(fallback):
		list.append(fallback)
		font.fallbacks = list
