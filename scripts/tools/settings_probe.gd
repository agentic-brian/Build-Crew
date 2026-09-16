extends Node
## The settings panel (the improvement plan's 6.4, part 1): the one control a
## parent reaches for in the first two minutes.
##
##   godot --headless --path . res://scenes/dev/settings_probe.tscn
##
## The user's own "vehicles too loud" was a parent reaching for a control that
## was not there. This holds the one that is there to: being on BOTH screens and
## opening from a real press on its cog; freezing the job under it and LETTING
## GO of every finger that was down (a held hold that survives a pause is the
## most destructive thing this panel can do - it is how the title's "new drive"
## disc would throw a child's saved job away); an eleven-step slider driven by a
## real touch, which is the path the one-finger-two-events bug lives on; a music
## toggle; and a privacy link that opens nothing until a grown-up answers a sum.
##
## Prints one line per check, then SETTINGS_PROBE PASS n/n, and exits 0 / 1.

const SCRATCH := "user://bc_settings_probe.json"

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	# The panel pauses the tree; this probe has to keep running through it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.motion_override = -1
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	SaveGame.enabled = false
	Settings.path_override = SCRATCH
	Settings.clear()
	Settings.forget_load()
	await get_tree().process_frame
	_check(Settings.FILE == "user://build_crew_settings.json",
		"the child's settings live in this game's own file (%s)" % Settings.FILE)
	_check(Settings.RUNGS == 11, "the loudness ladder has eleven rungs (%d)" % Settings.RUNGS)
	await _on_the_title()
	await _in_the_job()
	Settings.clear()
	Settings.path_override = ""
	Settings.forget_load()
	SaveGame.enabled = true
	print("SETTINGS_PROBE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


# --- On the title row -------------------------------------------------------------------------

func _on_the_title() -> void:
	print("-- the cog on the title row")
	var title := (load("res://scenes/main.tscn") as PackedScene).instantiate() as TitleMain
	add_child(title)
	await _frames(3)
	var panel: Node = title.get_node_or_null("Settings")
	_check(panel != null, "the title row carries the panel")
	if panel == null:
		return
	# The Sfx the panel must quieten belongs to the lot this screen instanced,
	# and is pushed in: a sibling lookup finds nothing here, silently, forever.
	_check(panel.get("_sfx") != null, "and it was handed the lot's own Sfx, not left looking for a sibling")
	# A real finger on the cog, not a method call.
	var cog := panel.get("_opener") as Control
	_check(cog != null and cog.visible, "the cog is on the screen")
	await _touch(cog.get_global_rect().get_center())
	_check(bool(panel.get("_open")) and get_tree().paused, "a press on it opens the panel and freezes what is under it")
	# The slider, by a real touch PAIR: a finger reaches `_gui_input` twice (the
	# emulated mouse, then the touch), and both arrive in LOCAL coordinates.
	var slider := (panel.get("_panel") as Control).get_node_or_null("Volume") as Control
	_check(slider != null, "the slider is on the panel")
	if slider != null:
		var before := Settings.loudness
		var box := slider.get_global_rect()
		await _touch(Vector2(box.position.x + box.size.x * 0.25, box.get_center().y))
		_check(Settings.loudness != before and Settings.loudness >= 0 and Settings.loudness < Settings.RUNGS,
			"dragging it moves the loudness (%d -> %d of %d)" % [before, Settings.loudness, Settings.RUNGS - 1])
		_check(String(panel.get("_sfx").last_played) == "ping", "and each step is heard as it passes")
		var db := AudioServer.get_bus_volume_db(Settings.sfx_bus())
		_check(absf(db - Settings.SFX_DB[Settings.loudness]) < 0.01,
			"the bus really moved with it (%.1f dB)" % db)
	# The music toggle.
	var music := (panel.get("_panel") as Control).get_node_or_null("MusicToggle") as Control
	if music != null:
		var was := Settings.music_on
		await _touch(music.get_global_rect().get_center())
		_check(Settings.music_on != was, "the quaver turns the song off and on (%s -> %s)" % [was, Settings.music_on])
	# The privacy link opens the GATE, never the browser.
	var link := (panel.get("_panel") as Control).get_node_or_null("Privacy") as Control
	var gate := panel.get("_gate") as CanvasItem
	if link != null and gate != null:
		await _touch(link.get_global_rect().get_center())
		_check(gate.visible, "the privacy link puts a grown-up's sum in front of the policy")
		if gate.has_method("dismiss"):
			gate.call("dismiss")
			await _frames(2)
	# And the panel closes again.
	panel.call("close")
	await _frames(3)
	_check(not bool(panel.get("_open")) and not get_tree().paused, "the tick closes it and the screen runs again")
	# What a parent set is remembered.
	_check(FileAccess.file_exists(Settings.file_path()), "what they set is written down")
	title.queue_free()
	await _frames(3)


# --- In the job -------------------------------------------------------------------------------

func _in_the_job() -> void:
	print("-- the cog in the job")
	# The pose is a screenshot's pose, and a screenshot hides the cog unless it
	# is asked for (`SettingsMenu._shot_wants_settings`) - so ask for it.
	Engine.set_meta("shot_args", {"stage": "rebar", "settings": true})
	var site := (load("res://scenes/site.tscn") as PackedScene).instantiate() as SiteMain
	add_child(site)
	await _frames(3)
	Engine.remove_meta("shot_args")
	var panel: Node = site.get_node_or_null("Settings")
	_check(panel != null, "the job carries the same panel, in the same corner")
	if panel == null:
		return
	var cog := panel.get("_opener") as Control
	var hud := site.hud as SiteHud
	# A finger is DOWN on the work when the cog is tapped.
	hud.show_pads(["up", "down", "left", "right"])
	await _frames(2)
	site._press(Vector2(640.0, 400.0), true)
	site.runner.hold(true)
	await _frames(2)
	_check(site.runner.held or site._touch_down, "a finger is on the work")
	await _touch(cog.get_global_rect().get_center())
	_check(bool(panel.get("_open")) and get_tree().paused, "the cog opens over a running job and freezes it")
	_check(not site.runner.held and not site._touch_down,
		"and every finger that was down is LET GO: a beat cannot go on being held behind a panel")
	# The song keeps playing over a frozen picture, and the machines do not.
	var sfx := site.sfx
	_check(int(sfx.process_mode) == int(Node.PROCESS_MODE_ALWAYS),
		"the sound keeps its own clock, so a volume control is not set over silence")
	panel.call("close")
	await _frames(3)
	_check(not get_tree().paused, "and the job runs again when the panel goes")
	site.queue_free()
	await _frames(3)


# --- Plumbing ------------------------------------------------------------------------------------

## A finger: the emulated mouse AND the touch, in that order, the way Godot
## really delivers one.
func _touch(at: Vector2) -> void:
	for pressed in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.position = at
		mb.pressed = pressed
		get_viewport().push_input(mb, true)
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = at
		t.pressed = pressed
		get_viewport().push_input(t, true)
		await _frames(2)
	await _frames(4)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])
