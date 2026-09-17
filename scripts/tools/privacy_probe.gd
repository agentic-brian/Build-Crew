extends Node
## Is the published privacy policy TRUE of this build? (the improvement plan's
## 6.4, part 2.)
##
##   godot --headless --path . res://scenes/dev/privacy_probe.tscn
##
## The policy at <https://biglittlejobs.com/privacy> is a promise made to
## parents and to Apple's Kids Category reviewer. This probe holds the game to
## the parts of it that code can decide:
##
##   * the only way out of the app is that policy, and a grown-up has to answer
##     a sum to take it (Apple: the gate must be arithmetic, not a press-and-hold);
##   * nothing here talks to a network, ever;
##   * the two files it writes hold what the policy lists and nothing else - no
##     identifier, and NO HISTORY OF WHEN THE APP WAS USED;
##   * the licence texts the bundle owes are on disk.
##
## The save is the interesting one. Since the plan's 6.2 this game DOES write a
## save - where the child is in an unfinished job - so "nothing writes it" (Car
## Garage's check) would be a false assertion here. What replaces it is stricter:
## the document's keys are pinned, every value is scanned for anything that
## looks like a clock, and `SaveGame`'s own `saved_at` erase is exercised with a
## document that carries one.
##
## Prints one line per check, then PRIVACY_PROBE PASS n/n, and exits 0 / 1.

const SAVE_SCRATCH := "user://bc_privacy_save.json"
const SET_SCRATCH := "user://bc_privacy_settings.json"
## What the save may hold, and nothing else (`SiteMain.save_doc`).
const SAVE_KEYS := ["done", "job", "nth", "places", "rows", "seed", "verb", "version"]
## What the settings file may hold.
const SET_KEYS := ["loudness", "music_on", "version"]
## Where the one link out of the app goes. Pinned, not pattern-matched: a check
## that only asks `begins_with("https://")` is green for any address in the
## world, including one that does not mention this game.
const POLICY_URL := "https://biglittlejobs.com/privacy"
## The two files this game writes, which are the two files that policy has to
## describe. A third name appearing here is a policy change, not a code change.
const POLICY_FILES := ["user://build_crew_save.json", "user://build_crew_settings.json"]
## The licence texts the bundle owes (6.4 part 5).
const TEXTS := ["res://licenses/Godot-MIT.txt", "res://licenses/Godot-thirdparty.txt",
	"res://licenses/OFL-Fredoka.txt", "res://licenses/OFL-NunitoSans.txt",
	"res://THIRD_PARTY_NOTICES.md"]

## How many rows the job really has. Never a literal: the day the job's row count
## changed, a typed one made every save in this suite be refused, and a refused
## save is a QUIET failure - the level simply starts fresh.
var _rows: int = JobDef.rows_of("new_driveway")

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.motion_override = -1
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	SaveGame.enabled = false
	await get_tree().process_frame
	_source_checks()
	_the_gate_is_arithmetic()
	await _the_link_is_gated()
	_the_save_holds_no_clock()
	_the_settings_file()
	_the_policy_knows_the_files()
	_the_texts_are_here()
	SaveGame.enabled = true
	SaveGame.path_override = ""
	Settings.path_override = ""
	print("PRIVACY_PROBE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


## "The only link out of the app is this policy, and it asks a grown-up first"
## is a claim about the WHOLE game, so it is checked against the whole game's
## source: exactly one `OS.shell_open`, in the settings panel, no networking
## class anywhere, no device identifier, and no clock read into anything that
## could be written down.
func _source_checks() -> void:
	print("-- the one way out is the only way out")
	var opens: Array[String] = []
	var network: Array[String] = []
	var clocks: Array[String] = []
	var banned := ["HTTPRequest", "HTTPClient", "StreamPeerTCP", "PacketPeerUDP", "WebSocketPeer",
		"TCPServer", "UDPServer", "ENetConnection", "WebRTCPeerConnection"]
	var identifiers := ["OS.get_unique_id", "Time.get_datetime", "Time.get_unix_time"]
	for path in _scripts("res://scripts"):
		if path.ends_with("privacy_probe.gd"):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in range(lines.size()):
			var line := lines[i].strip_edges()
			if line.begins_with("#"):
				continue
			if "OS.shell_open(" in line:
				opens.append("%s:%d" % [path.get_file(), i + 1])
			for word in banned:
				if (word + ".new(") in line or (": " + word) in line:
					network.append("%s:%d %s" % [path.get_file(), i + 1, word])
			for word in identifiers:
				if word in line:
					clocks.append("%s:%d %s" % [path.get_file(), i + 1, word])
	_check(opens.size() == 1 and opens[0].begins_with("settings_menu.gd:"),
		"exactly one OS.shell_open in the game, in the settings panel (%s)" % ", ".join(opens))
	_check(network.is_empty(), "and no networking class is ever made (%s)" % ", ".join(network))
	_check(clocks.is_empty(), "no device id and no wall clock is ever read (%s)" % ", ".join(clocks))
	# `get_setting` does NOT apply feature tags; `get_setting_with_override` is
	# what the ENGINE reads. The difference is not academic: the base default is
	# false and the `.pc` default is true, so this check was green on every
	# desktop run while `user://logs/` filled with a timestamped file per launch.
	_check(not bool(ProjectSettings.get_setting_with_override("debug/file_logging/enable_file_logging")),
		"and the engine writes no diagnostic log")
	# Said again as a fact about the disk, because a setting is a promise and a
	# directory is evidence. Nothing but the two files the policy names, and the
	# scratch files this probe is standing in for them, may be in `user://`.
	var strays: Array[String] = []
	for name: String in DirAccess.get_directories_at("user://"):
		if name in ["shader_cache", "vulkan", "objectdb_snapshots"]:
			continue
		strays.append(name + "/")
	_check(strays.is_empty(),
		"and nothing is writing a folder beside the child's two files (%s)" % ", ".join(strays))


## Apple's rule for the Kids Category: the gate in front of the link must be a
## question a small child cannot answer, and a press-and-hold is not one.
func _the_gate_is_arithmetic() -> void:
	print("-- the gate a grown-up answers")
	var gate: ParentalGate = ParentalGate.new()
	add_child(gate)
	gate.ask()
	var a := int(gate.get("_a"))
	var b := int(gate.get("_b"))
	_check(a >= 3 and a <= 9 and b >= 3 and b <= 9 and a * b >= 9,
		"the gate asks a multiplication a reader has to do (%d x %d)" % [a, b])
	var rolled := 0
	for i in range(12):
		gate.ask()
		if int(gate.get("_a")) != a or int(gate.get("_b")) != b:
			rolled += 1
	_check(rolled > 0, "and it is a different sum each time it is asked (%d of 12)" % rolled)
	var passed := [0]
	gate.passed.connect(func() -> void: passed[0] += 1)
	gate.ask()
	var want := int(gate.get("_a")) * int(gate.get("_b"))
	# A wrong answer, typed digit by digit the way a finger types it. `_submit`
	# empties the slot itself when it is wrong, so the right one starts clean.
	for d in str(maxi(want - 1, 1)):
		gate.call("_type", d)
	gate.call("_submit")
	_check(passed[0] == 0 and String(gate.get("_typed")) == "", "a wrong answer opens nothing, and clears the slot")
	for d in str(want):
		gate.call("_type", d)
	gate.call("_submit")
	_check(passed[0] == 1 and not gate.visible, "and only the right one does")
	gate.queue_free()
	await get_tree().process_frame


## The link is reachable from inside the app - on BOTH screens, because
## "reachable" cannot mean "reachable from the one screen a reviewer opened" -
## and it is behind the gate.
func _the_link_is_gated() -> void:
	print("-- the link, from inside the app")
	for scene: String in ["res://scenes/main.tscn", "res://scenes/site.tscn"]:
		if scene.ends_with("site.tscn"):
			Engine.set_meta("shot_args", {"stage": "rebar"})
		var root: Node = (load(scene) as PackedScene).instantiate()
		add_child(root)
		await _frames(3)
		Engine.remove_meta("shot_args")
		var panel: Node = root.get_node_or_null("Settings")
		_check(panel != null, "%s carries the settings panel" % scene.get_file())
		if panel != null:
			panel.call("open")
			await _frames(3)
			var link := (panel.get("_panel") as Control).get_node_or_null("Privacy") as Control
			_check(link != null and link.visible, "%s: the privacy link is on it" % scene.get_file())
			_check(String(panel.get("privacy_url")) == POLICY_URL,
				"%s: pointing at the published policy (%s)" % [scene.get_file(), str(panel.get("privacy_url"))])
			var gate: CanvasItem = panel.get("_gate")
			_check(gate != null and not gate.visible,
				"%s: with the grown-up's gate in front of it, down until it is needed" % scene.get_file())
			panel.call("close")
		root.queue_free()
		await _frames(3)


## The save holds where the child is in an unfinished job, and NOTHING that says
## when they played. This is the claim the policy's "no history of when the app
## was used" rests on.
func _the_save_holds_no_clock() -> void:
	print("-- the save, and the clock it must not hold")
	SaveGame.enabled = true
	SaveGame.path_override = SAVE_SCRATCH
	SaveGame.clear()
	var doc := {"job": "new_driveway", "rows": _rows, "verb": "rebar_lay", "nth": 1, "done": 2,
		"places": [1, 3], "seed": 2096}
	_check(SaveGame.save_data(doc), "a job saves")
	var back := SaveGame.load_data()
	var keys := back.keys()
	keys.sort()
	_check(keys == SAVE_KEYS, "and holds exactly its eight keys (%s)" % str(keys))
	_check(_no_clock(back), "with nothing in it that says when anybody played")
	var seed: int = int(back.get("seed", -1))
	_check(seed >= 0 and seed <= SiteLook.SEED_MAX,
		"the one number in it is a look, not a clock (%d, at most %d)" % [seed, SiteLook.SEED_MAX])
	# The erase itself: hand it a document that DOES carry a stamp.
	var stamped := doc.duplicate()
	stamped["saved_at"] = Time.get_datetime_string_from_system()
	SaveGame.save_data(stamped)
	var raw := FileAccess.get_file_as_string(SaveGame.file_path())
	_check(not raw.contains("saved_at") and not SaveGame.load_data().has("saved_at"),
		"a stamp handed to the store is thrown away, not written (the line this policy hangs on)")
	_check(_no_clock(JSON.parse_string(raw) as Dictionary), "so what lands on disk still holds no clock")
	_check(not FileAccess.file_exists(SaveGame.file_path() + ".part"),
		"a finished write leaves no half-written file behind")
	SaveGame.clear()
	_check(not FileAccess.file_exists(SaveGame.file_path()) and not FileAccess.file_exists(SaveGame.file_path() + ".part"),
		"and the job being over takes both away")
	SaveGame.path_override = ""
	SaveGame.enabled = false


## The other file: what a parent set, and nothing else.
func _the_settings_file() -> void:
	print("-- the settings file")
	Settings.path_override = SET_SCRATCH
	Settings.clear()
	Settings.loudness = 7
	Settings.music_on = false
	_check(Settings.save_settings(), "the settings save")
	var text := FileAccess.get_file_as_string(Settings.file_path())
	var parsed: Variant = JSON.parse_string(text)
	var keys: Array = (parsed as Dictionary).keys() if parsed is Dictionary else []
	keys.sort()
	_check(keys == SET_KEYS, "and hold exactly what a parent set (%s)" % str(keys))
	_check(_no_clock(parsed as Dictionary), "with no clock in them either")
	Settings.clear()
	_check(not FileAccess.file_exists(Settings.file_path()), "and they can be taken away")
	Settings.path_override = ""


## The policy names files by name. If this game starts writing a third one, the
## published document is wrong the moment it ships - so the list is pinned here,
## beside the keys, and a new file breaks this probe rather than the promise.
func _the_policy_knows_the_files() -> void:
	print("-- the files the policy has to describe")
	var names := [SaveGame.FILE, Settings.FILE]
	names.sort()
	var want := POLICY_FILES.duplicate()
	want.sort()
	_check(names == want, "the game writes exactly the two files the policy lists (%s)" % str(names))


func _the_texts_are_here() -> void:
	print("-- the licence texts the bundle owes")
	var missing: Array[String] = []
	for path: String in TEXTS:
		if not FileAccess.file_exists(path):
			missing.append(path.get_file())
	_check(missing.is_empty(), "every licence text and the notices file is on disk (%s)" % ", ".join(missing))


# --- Plumbing ------------------------------------------------------------------------------------

## Is there anything in this document that could say WHEN? A key that names a
## time, a value shaped like a date or a clock, or a number the size of a unix
## stamp. (`resume_probe` holds the save to the same rule at every row.)
func _no_clock(d: Dictionary) -> bool:
	for k in d.keys():
		var key := String(k)
		if key.contains("time") or key.contains("date") or key.ends_with("_at"):
			return false
		var v := str(d[k])
		if RegEx.create_from_string("\\d{4}-\\d{2}").search(v) != null:
			return false
		if RegEx.create_from_string("\\d{2}:\\d{2}").search(v) != null:
			return false
		if (d[k] is float or d[k] is int) and absf(float(d[k])) >= 1e5:
			return false
	return true


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for name in DirAccess.get_files_at(dir):
		if name.ends_with(".gd"):
			out.append(dir + "/" + name)
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir + "/" + sub))
	return out


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])
