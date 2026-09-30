extends SceneTree

## Every character sheet is pixel art and must reach the screen pixel for pixel.
##
##   godot --headless --path . --script res://tests/assets/sprite_imports_check.gd
##
## Godot's default for a texture it sees used in 3D is VRAM compression with
## mipmaps: that blurs 4x4 blocks together, so a sleeve crossing a shirt turns
## muddy and colours flicker between frames. Fails on any sheet imported that way.

const DIR := "res://assets/sprites/characters/"


func _initialize() -> void:
	var failures := 0
	var n := 0
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".png.import"):
			continue
		n += 1
		var cfg := ConfigFile.new()
		cfg.load(DIR + f)
		var mode := int(cfg.get_value("params", "compress/mode", -1))
		var mips := bool(cfg.get_value("params", "mipmaps/generate", true))
		var to_3d := int(cfg.get_value("params", "detect_3d/compress_to", 1))
		if mode != 0 or mips or to_3d != 0:
			failures += 1
			print("  FAIL %s: compress/mode=%d mipmaps=%s detect_3d/compress_to=%d (want 0, false, 0)" % [f, mode, mips, to_3d])
	print("sprite imports: %s (%d sheets, %d failures)" % ["PASS" if failures == 0 else "FAIL", n, failures])
	quit(0 if failures == 0 else 1)
