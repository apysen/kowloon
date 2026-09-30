class_name SettingsFile
extends RefCounted

## Where the player's choices (volume, graphics, fullscreen, language) are kept.
##
## When the game is driven by a script (tests, captures, bakes: `--script`) it
## keeps its own file, so those runs never read the player's settings (running
## fullscreen in Chinese because the player last played that way) and never
## overwrite them.

static func path() -> String:
	return "user://settings_script.cfg" if OS.get_cmdline_args().has("--script") else "user://settings.cfg"
