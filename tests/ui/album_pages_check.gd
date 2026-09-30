extends SceneTree

## Every album page's writing stays on the page.
##
##   godot --headless --path . --script res://tests/ui/album_pages_check.gd
##
## Lays out each resident's page in every language, before and after the album
## learns where people went, and fails if the notes run past the bottom margin
## into the page number.

const BOTTOM := 540.0 - 44.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var book: Control = load("res://scenes/ui/scrapbook/scrapbook.tscn").instantiate()
	root.add_child(book)
	await process_frame
	var failures := 0
	var n := 0
	for loc in ["en", "zh_HK"]:
		TranslationServer.set_locale(loc)
		for after in [false, true]:
			Progress.after_unlocked = after
			book._build_pages(ResidentCatalog.ENTRIES, {}, "")
			await process_frame
			await process_frame
			for i in ResidentCatalog.ENTRIES.size():
				n += 1
				var page: Control = book._pages[i + 1].get_child(0)
				for c in page.get_children():
					if c is VBoxContainer:
						var bottom: float = c.position.y + c.get_combined_minimum_size().y
						if bottom > BOTTOM:
							failures += 1
							print("  FAIL %s, %s, after=%s: writing reaches y=%.0f, past %.0f" % [ResidentCatalog.ENTRIES[i], loc, after, bottom, BOTTOM])
	print("album pages: %s (%d pages, %d failures)" % ["PASS" if failures == 0 else "FAIL", n, failures])
	quit(0 if failures == 0 else 1)
