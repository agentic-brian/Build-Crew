class_name SaveGame
extends RefCounted
## The save file: where the child is in the job they have not finished, so
## closing the app, or the tablet being taken away, loses nothing (the
## improvement plan's 6.2). A small JSON document under user://, written by
## `SiteMain` every time a step is entered or a beat of it lands, and DELETED
## the moment the job is done.
##
## What is in it, and nothing else: `version`, `job`, `rows` (how many rows the
## job had - an update that adds a beat starts a saved job fresh rather than
## posing the wrong world), `verb` and `nth` (which row, by name), `done` (how
## many of its places), `places` (WHICH ones, for the rows a child takes in any
## order) and `seed` (the visit's look, 6.1 - a drawn number up to 9999, never
## the clock). No time of any kind: the privacy policy says there is no history
## of when the app was used.
##
## The class is also the switch every harness speaks: a run with `shot_args`
## never reads or writes the child's file unless it has pointed `path_override`
## at a scratch one (`SiteMain.saves_on`). `Settings.persists` reads the same
## `enabled`, so a harness that switches saving OFF (shot.gd, pour_probe) leaves
## the child's settings alone too; the smoke and the resume probe, which switch
## it on for a scratch save, still read the developer's settings file.
##
## On Windows the file lands in %APPDATA%/Godot/app_userdata/Build Crew/, on
## iPad in the app's own documents folder; `user://` is the same path on both.

const FILE := "user://build_crew_save.json"
const VERSION := 1

## Harnesses set this false: no file is read, written or deleted for the run.
static var enabled: bool = true
## Tests point this at a scratch file so they can exercise the real code path.
static var path_override: String = ""


static func file_path() -> String:
	return path_override if path_override != "" else FILE


static func exists() -> bool:
	return enabled and (FileAccess.file_exists(file_path()) or FileAccess.file_exists(file_path() + ".part"))


## The saved document, or an empty Dictionary when there is none (first launch,
## saving off, unreadable or from a newer version than this build understands).
static func load_data() -> Dictionary:
	if not enabled:
		return {}
	var path := file_path()
	if not FileAccess.file_exists(path):
		# Killed between removing the old save and renaming the new one over it:
		# the new one is whole in its `.part`.
		path += ".part"
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
##
## To a `.part` file first, renamed over the save only once it is whole: the
## app can be killed mid-write when a tablet is put to sleep, and a truncated
## save is a child's job silently gone.
static func save_data(d: Dictionary) -> bool:
	if not enabled:
		return false
	var copy := d.duplicate(true)
	copy["version"] = VERSION
	# No `saved_at`. The family's saves carried the wall-clock time of every save
	# until 2026-09-11: the policy the settings panel links to says "there is no
	# history of when the app was used", and nothing ever read the stamp back.
	copy.erase("saved_at")
	var path := file_path()
	var part := path + ".part"
	var f := FileAccess.open(part, FileAccess.WRITE)
	if f == null:
		push_warning("SaveGame: cannot write %s (%d)" % [part, FileAccess.get_open_error()])
		return false
	var text := JSON.stringify(copy, "\t")
	var stored := f.store_string(text)
	f.close()
	# Read back before the old save is touched: a full disk opens the file fine
	# and loses the bytes at the close, and an empty `.part` renamed over a good
	# save is the lost job this scheme exists to prevent.
	if not stored or FileAccess.get_file_as_string(part) != text:
		push_warning("SaveGame: %s did not write whole; the old save is kept" % part)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(part))
		return false
	# Windows will not rename onto an existing name (Tree Crew's measured port),
	# so the old one goes first; a kill in that instant leaves the whole `.part`,
	# which `load_data` reads. An old save that cannot be removed would win over
	# every newer `.part`, so that is a failed write too.
	if FileAccess.file_exists(path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
		push_warning("SaveGame: cannot replace %s" % path)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(part))
		return false
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(part), ProjectSettings.globalize_path(path))
	if err != OK:
		push_warning("SaveGame: cannot move %s over %s (%d)" % [part, path, err])
		return false
	return true


## Removes the save (the job is done, NEXT, or a test cleaning up after itself).
## Never while saving is off: a harness that switched it off must not delete the
## child's job.
static func clear() -> void:
	if not enabled:
		return
	for path: String in [file_path(), file_path() + ".part"]:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
			# Held by something (an indexer): blanked instead, so it can never
			# bring back a finished job.
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.store_string("{}")
				f.close()
