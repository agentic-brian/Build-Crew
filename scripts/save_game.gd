class_name SaveGame
extends RefCounted
## The save file: a small JSON document under user://. NOTHING WRITES IT since
## 2026-09-11. The only thing this game ever kept in it was the count of cars
## fixed, shown by the house, and the user took the count out ("it isn't used
## for anything"); `privacy_probe` holds the game to never calling `save_data`.
##
## The class stays for its switch. Every harness (smoke tests, shots,
## storyboards) turns `enabled` off to say "this is not the child's game", and
## `Settings.persists` reads that same switch to leave the child's settings
## file alone - so it is the one flag the whole test suite already speaks.
##
## On Windows the file lands in %APPDATA%/Godot/app_userdata/Tree Chop/, on
## iPad in the app's own documents folder; `user://` is the same path on both.

const FILE := "user://build_crew_save.json"
const VERSION := 1

## Harnesses set this false: no file is read or written for the whole run.
static var enabled: bool = true
## Tests point this at a scratch file so they can exercise the real code path.
static var path_override: String = ""


static func file_path() -> String:
	return path_override if path_override != "" else FILE


static func exists() -> bool:
	return enabled and FileAccess.file_exists(file_path())


## The saved document, or an empty Dictionary when there is none (first launch,
## saving off, unreadable or from a newer version than this build understands).
static func load_data() -> Dictionary:
	if not enabled:
		return {}
	var path := file_path()
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	var d: Dictionary = parsed
	if int(d.get("version", 0)) > VERSION:
		return {}
	return d


## Writes the document. Returns false when saving is off or the write failed.
static func save_data(d: Dictionary) -> bool:
	if not enabled:
		return false
	var copy := d.duplicate(true)
	copy["version"] = VERSION
	# No `saved_at`. The file carried the wall-clock time of every save until
	# 2026-09-11, when the settings panel got its privacy link: the policy that
	# link opens says "there is no history of when the app was used", nothing
	# here ever read the stamp back, and a policy is only worth linking to if
	# the game it describes makes it true. (`privacy_probe` holds it to that.)
	copy.erase("saved_at")
	var f := FileAccess.open(file_path(), FileAccess.WRITE)
	if f == null:
		push_warning("SaveGame: cannot write %s (%d)" % [file_path(), FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(copy, "\t"))
	f.close()
	return true


## Removes the save (a parent's reset, or a test cleaning up after itself).
static func clear() -> void:
	var path := file_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
