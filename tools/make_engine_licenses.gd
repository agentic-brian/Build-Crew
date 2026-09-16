extends SceneTree
## Writes the engine's own licence texts into `licenses/`, straight out of the
## Godot binary that runs this, so they ship inside the app with the fonts' OFL
## texts (`export_presets.cfg` includes `licenses/*.txt`):
##
##   godot --headless --path . -s tools/make_engine_licenses.gd
##
##   licenses/Godot-MIT.txt         Godot's MIT licence (`Engine.get_license_text`)
##   licenses/Godot-thirdparty.txt  every component the engine bundles, its
##                                  copyright lines and licence, then each
##                                  licence's full text (`get_copyright_info`,
##                                  `get_license_info`)
##
## Run it again whenever the engine version changes.

const MIT := "res://licenses/Godot-MIT.txt"
const THIRD := "res://licenses/Godot-thirdparty.txt"


func _initialize() -> void:
	var v := Engine.get_version_info()
	var ok := _write(MIT, "Godot Engine %s\n\n%s" % [v.get("string", ""), Engine.get_license_text()])
	var lines := PackedStringArray()
	lines.append("Third-party components bundled in Godot Engine %s, as the engine reports them." % v.get("string", ""))
	lines.append("")
	for info: Dictionary in Engine.get_copyright_info():
		lines.append("%s" % info.get("name", ""))
		for part: Dictionary in info.get("parts", []):
			for c in part.get("copyright", PackedStringArray()):
				lines.append("  Copyright %s" % c)
			lines.append("  License: %s" % part.get("license", ""))
		lines.append("")
	lines.append("")
	lines.append("Licence texts")
	lines.append("=============")
	var texts: Dictionary = Engine.get_license_info()
	var names := texts.keys()
	names.sort()
	for n in names:
		lines.append("")
		lines.append("----- %s -----" % n)
		lines.append("")
		lines.append(str(texts[n]))
	ok = _write(THIRD, "\n".join(lines) + "\n") and ok
	print("make_engine_licenses: %s, %d components, %d licence texts" % ["ok" if ok else "FAILED",
		Engine.get_copyright_info().size(), names.size()])
	quit(0 if ok else 1)


func _write(path: String, text: String) -> bool:
	var f := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if f == null:
		push_error("make_engine_licenses: cannot write %s" % path)
		return false
	f.store_string(text)
	f.close()
	return true
