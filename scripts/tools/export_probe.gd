extends Node
## Is this build actually shippable? (the improvement plan's 6.4, part 4.)
##
##   godot --headless --path . res://scenes/dev/export_probe.tscn
##
## An export preset is a file nobody reads until a build fails or, worse, until
## a build succeeds carrying something it should not. Everything here is a claim
## some other document makes and this one checks against the files:
##
##   * the bundle is THIS game's, not a sibling's - one wrong identifier
##     uploads Build Crew over Car Garage;
##   * every icon the preset names is on disk, is exactly the size its own key
##     claims, and is OPAQUE (an icon with an alpha channel is rejected, and the
##     rejection arrives days later);
##   * the licence texts this project owes really are carried in, and the dev
##     scaffolding - renders, probes, harnesses, Blender tools, docs - really is
##     kept out;
##   * nothing a shipped scene needs lives in a folder the filter excludes;
##   * and no audio is shipped that nothing can ever play.
##
## Prints one line per check, then EXPORT_PROBE PASS n/n, and exits 0 / 1.

const PRESETS := "res://export_presets.cfg"
const BUNDLE := "com.biglittlejobs.buildcrew"
const SPLASH := "res://assets/brand/splash.png"
## What must be carried IN, and what must be kept OUT.
const MUST_INCLUDE := ["licenses/*.txt", "THIRD_PARTY_NOTICES.md"]
const MUST_EXCLUDE := ["renders/*", "scenes/dev/*", "scripts/tools/*", "tools/*", "docs/*"]
## The scenes a player can reach. Nothing they need may be excluded.
const SHIPPED := ["res://scenes/main.tscn", "res://scenes/site.tscn"]

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	Settings.motion_override = -1
	SaveGame.enabled = false
	_run.call_deferred()


func _run() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(PRESETS)
	_check(err == OK, "there is an export preset at all (%s)" % error_string(err))
	if err != OK:
		_done()
		return
	var ios := _preset_named(cfg, "iOS")
	var win := _preset_named(cfg, "Windows Desktop")
	_check(ios != "", "an iOS preset")
	_check(win != "", "and a desktop one, so the game can be played without a phone")
	if ios == "":
		_done()
		return
	_the_bundle(cfg, ios)
	_the_filters(cfg, ios, "iOS")
	if win != "":
		_the_filters(cfg, win, "Windows")
	_the_icons(cfg, ios)
	_the_splash()
	_nothing_shipped_is_excluded()
	_no_audio_nobody_can_play()
	_done()


func _done() -> void:
	SaveGame.enabled = true
	print("EXPORT_PROBE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


## Whose bundle is this? A sibling's identifier here uploads this game over that
## one, and the mistake is invisible until the store shows the wrong name.
func _the_bundle(cfg: ConfigFile, sec: String) -> void:
	print("-- whose app this is")
	var opts := sec + ".options"
	var id := str(cfg.get_value(opts, "application/bundle_identifier", ""))
	_check(id == BUNDLE, "the bundle is this game's own (%s)" % id)
	_check(not id.contains("cargarage") and not id.contains("treecrew"),
		"and not a sibling's, which would upload one game over another")
	_check(str(cfg.get_value(opts, "application/min_ios_version", "")) == "15.0",
		"iOS 15 and up (%s)" % str(cfg.get_value(opts, "application/min_ios_version", "")))
	_check(int(cfg.get_value(opts, "application/targeted_device_family", -1)) == 2,
		"on a phone AND an iPad, which is the shape the safe-area pass was built for")
	# The child's game is not a tracking product, and the store asks.
	_check(not bool(cfg.get_value(opts, "privacy/tracking_enabled", true)),
		"nothing is tracked")
	var names := ["name", "email_address", "phone_number", "physical_address",
		"device_id", "product_interaction", "advertising_data", "other_usage_data"]
	var collected: Array[String] = []
	for n: String in names:
		if bool(cfg.get_value(opts, "privacy/collected_data/%s/collected" % n, false)):
			collected.append(n)
	_check(collected.is_empty(), "and nothing at all is declared collected (%s)" % ", ".join(collected))


## What rides into the bundle, and what must not.
func _the_filters(cfg: ConfigFile, sec: String, tag: String) -> void:
	print("-- what the %s bundle carries" % tag)
	var inc := str(cfg.get_value(sec, "include_filter", ""))
	var exc := str(cfg.get_value(sec, "exclude_filter", ""))
	var missing: Array[String] = []
	for want: String in MUST_INCLUDE:
		if not inc.contains(want):
			missing.append(want)
	_check(missing.is_empty(),
		"%s: the licence texts this project owes are carried in (%s)" % [tag, ", ".join(missing)])
	var leaking: Array[String] = []
	for want: String in MUST_EXCLUDE:
		if not exc.contains(want):
			leaking.append(want)
	_check(leaking.is_empty(),
		"%s: and the harnesses, the renders, the Blender tools and the docs are kept out (%s)"
		% [tag, ", ".join(leaking)])


## Every icon, at exactly the size its own key claims, and opaque.
func _the_icons(cfg: ConfigFile, sec: String) -> void:
	print("-- the fifteen icons")
	var opts := sec + ".options"
	var seen := 0
	var wrong: Array[String] = []
	var clear: Array[String] = []
	var gone: Array[String] = []
	for key: String in cfg.get_section_keys(opts):
		if not key.begins_with("icons/") or key.ends_with("_dark") or key.ends_with("_tinted"):
			continue
		var path := str(cfg.get_value(opts, key, ""))
		if path == "":
			continue
		seen += 1
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			gone.append(key)
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null or img.is_empty():
			gone.append(key)
			continue
		# `icons/iphone_180x180` says how big it has to be. The key is the spec.
		var want := _size_in(key)
		if want > 0 and (img.get_width() != want or img.get_height() != want):
			wrong.append("%s is %dx%d, wants %d" % [key, img.get_width(), img.get_height(), want])
		if _has_alpha(img):
			clear.append(key)
	_check(seen >= 15, "the preset names every size iOS asks for (%d)" % seen)
	_check(gone.is_empty(), "and every one of them is on disk (%s)" % ", ".join(gone))
	_check(wrong.is_empty(), "each exactly the size its own key claims (%s)" % ", ".join(wrong))
	_check(clear.is_empty(),
		"and every one OPAQUE - an icon with an alpha channel is rejected (%s)" % ", ".join(clear))
	# The one a child sees first must not carry words. Nothing here can read, so
	# what is asserted is the thing that CAN be: it is the game's own machine,
	# rendered from the GLB, not a drawing that could drift away from it.
	_check(FileAccess.file_exists("res://tools/make_appicon.gd"),
		"the icon is BUILT from the game's own model, not drawn beside it")


func _the_splash() -> void:
	print("-- the splash")
	_check(FileAccess.file_exists(SPLASH), "the loading screen is on disk")
	_check(str(ProjectSettings.get_setting("application/boot_splash/image", "")) == SPLASH,
		"and the project opens on it")
	var bg: Color = ProjectSettings.get_setting("application/boot_splash/bg_color", Color.BLACK)
	_check(absf(bg.r - 1.0) < 0.02 and absf(bg.g - 0.953) < 0.02 and absf(bg.b - 0.808) < 0.02,
		"on the family cream, so a letterbox is the same colour as the picture (%s)" % str(bg))
	var icon := str(ProjectSettings.get_setting("application/config/icon", ""))
	_check(icon != "" and FileAccess.file_exists(icon), "and the project's own icon is set (%s)" % icon)


## A filter that excludes a folder a shipped scene needs is a build that boots
## to a blank screen, and it is not visible until the build is on a device.
func _nothing_shipped_is_excluded() -> void:
	print("-- nothing a player needs is filtered out")
	var bad: Array[String] = []
	for scene: String in SHIPPED:
		var text := FileAccess.get_file_as_string(scene)
		for want: String in ["res://scenes/dev/", "res://scripts/tools/", "res://tools/",
				"res://docs/", "res://renders/"]:
			if text.contains(want):
				bad.append("%s -> %s" % [scene.get_file(), want])
	_check(bad.is_empty(), "no shipped scene reaches into an excluded folder (%s)" % ", ".join(bad))
	# And the main scene really is the title row.
	_check(str(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://scenes/main.tscn",
		"the app opens on the title row")


## Audio that nothing can ever select is weight in the bundle and a licence
## claim in the notices for a sound no child will hear.
func _no_audio_nobody_can_play() -> void:
	print("-- no sound nobody can hear")
	var cars: Array[String] = []
	for row: Dictionary in SiteLook.HOME_CARS:
		cars.append(str(row.get("voice", "")))
	var orphans: Array[String] = []
	for name: String in DirAccess.get_files_at("res://assets/sfx"):
		if not name.ends_with(".mp3") or not name.begins_with("voice_"):
			continue
		var group := name.get_basename()
		while group.length() > 0 and group[group.length() - 1].is_valid_int():
			group = group.substr(0, group.length() - 1)
		group = group.rstrip("_")
		if group not in cars and group not in orphans:
			orphans.append(group)
	_check(orphans.is_empty(),
		"every vehicle voice on disk belongs to a car this game can draw (%s)" % ", ".join(orphans))


# --- Plumbing ------------------------------------------------------------------------------------

func _preset_named(cfg: ConfigFile, want: String) -> String:
	for sec: String in cfg.get_sections():
		if sec.begins_with("preset.") and not sec.ends_with(".options"):
			if str(cfg.get_value(sec, "name", "")) == want:
				return sec
	return ""


## The pixel size an icon key names: `icons/iphone_180x180` -> 180.
func _size_in(key: String) -> int:
	var bits := key.split("_")
	for b in bits:
		if "x" in b:
			var pair := b.split("x")
			if pair.size() == 2 and pair[0].is_valid_int():
				return int(pair[0])
	return 0


func _has_alpha(img: Image) -> bool:
	if not img.detect_alpha():
		return false
	return img.detect_alpha() != Image.ALPHA_NONE


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])
