extends Node
## The whole trip, through the real doors (the improvement plan's 6.3):
##
##   title -> a seat -> the job -> NEXT -> title -> the seat again -> the job
##
## with `change_scene_to_file` doing every cut, which is the one thing no other
## harness can exercise: in the smoke and the probes the level is a CHILD, so
## `get_tree().current_scene == self` is false and the real branch of
## `TitleMain._leave` and `SiteMain._on_next` is never taken.
##
##   godot --headless --path . res://scenes/dev/switch_probe.tscn
##
## The runner parks itself under the tree's ROOT, not under the scene, because
## the scene it is driving is the thing being taken away. Car Garage's
## `switch_probe.gd` is the pattern, including its warning: repeated scene
## changes crash Godot 4.7.2 outright about one run in three, so a run that dies
## with no PASS/FAIL line is the engine, not the test - rerun it once before
## believing it. That is also why this is NOT in the ten-minute smoke.
##
## Prints one line per check, then SWITCH_PROBE PASS n/n, and exits 0 / 1.

const SCRATCH := "user://switch_probe_save.json"
const FRAME_CAP := 4000

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	# The scene this drives is the thing being taken away, so the driver parks
	# itself under the tree's ROOT and the scene node itself does nothing.
	if has_meta("driving"):
		_run.call_deferred()
		return
	var runner := Node.new()
	runner.name = "SwitchRunner"
	runner.set_meta("driving", true)
	runner.set_script(get_script())
	get_tree().root.add_child.call_deferred(runner)


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	# A probe decides the OS's reduce-motion for itself, or the picture it
	# measures is decided by the machine it runs on (6.4).
	Settings.motion_override = -1
	SaveGame.enabled = true
	SaveGame.path_override = SCRATCH
	SaveGame.clear()
	await _frames(2)
	# 1. The app opens on the title row.
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await _settled()
	var title := get_tree().current_scene as TitleMain
	_check(title != null, "the app opens on the title row")
	if title == null:
		return _finish()
	_check(title.mode() == "fresh" and not SaveGame.exists(), "with nothing saved and nothing to carry on")
	# 2. A press on the seat cuts into the job.
	var key := title.menu().seat_keys()[0]
	var want := title.backdrop().play_seed
	title.menu().simulate_seat(key)
	await _settled()
	var site := get_tree().current_scene as SiteMain
	_check(site != null, "the seat cuts into the job")
	if site == null:
		return _finish()
	_check(site.play_seed == want and site.seed_from == "next",
		"on the very lot the disc was standing in front of (%d, wanted %d)" % [site.play_seed, want])
	_check(not Engine.has_meta(SiteMain.PICK_META) and not Engine.has_meta(SiteMain.NEXT_SEED_META),
		"and the pick and the seed are taken, not left lying in the process")
	_check(site.saves_on({}) and site.dress_only == false, "the job saves: this one is the child's")
	# 3. One bite, so there is something to come back to.
	var rings := site.get_node_or_null("Rings") as SpotRings
	var id := rings.id_at(0)
	var at := site.camera.unproject_position(rings.point_at(0))
	site._press(at, true)
	site._press(at, false)
	await _until(func() -> bool: return site.drive.spot_done(id) and not site.runner.is_busy(), "the first bite")
	_check(SaveGame.exists(), "one bite and the job is on disk")
	var saved_seed := int(SaveGame.load_data().get("seed", -1))
	# 4. NEXT, by the handler the button's own signal calls: it clears the save,
	# leaves the FINISHED visit behind for the title and makes the cut itself.
	# This is the only place that branch is ever taken - every other harness has
	# the level as a child, where `current_scene == self` is false.
	var finished := site.play_seed
	site._on_next()
	await _settled()
	_check(get_tree().current_scene is TitleMain,
		"NEXT cuts back to the title row by itself")
	_check(not Engine.has_meta(SiteMain.LAST_SEED_META),
		"and the title took the finished visit it was left")
	var reward := get_tree().current_scene as TitleMain
	_check(reward != null and reward.backdrop().play_seed == finished and reward.backdrop().dress_stage == "parked",
		"so the drive that was just built is what stands behind the next choice (%d, wanted %d)"
		% [reward.backdrop().play_seed if reward != null else -1, finished])
	_check(not SaveGame.exists(), "with no half-built job left over")
	# 5. Back to a title with the job unfinished: it offers to carry on. (The
	# save was cleared by NEXT, so it is written again here.)
	SaveGame.save_data({"job": "new_driveway", "rows": 25, "verb": "jack_spot", "nth": 1,
		"done": 1, "places": [id], "seed": saved_seed})
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await _settled()
	title = get_tree().current_scene as TitleMain
	_check(title != null and title.mode() == "carry_on", "coming back to the title, it offers the job the child left")
	if title == null:
		return _finish()
	_check(title.backdrop().play_seed == saved_seed and title.menu().fresh_visible(),
		"standing on that very drive (%d), with the 'new drive' disc beside it" % title.backdrop().play_seed)
	# 6. Carry on: the job resumes where it was.
	title.menu().simulate_seat(key)
	await _settled()
	site = get_tree().current_scene as SiteMain
	_check(site != null, "the disc carries on")
	if site == null:
		return _finish()
	_check(site.play_seed == saved_seed and site.seed_from == "save" and site.drive.spot_done(id),
		"the same visit, the same place: the bite is still done (%d, spot %d)" % [site.play_seed, id])
	_check(site.runner.index == 0 and site.runner.done_in_step == 1, "and the runner is on that row")
	# 7. The new drive: the title throws the job away and starts another.
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await _settled()
	title = get_tree().current_scene as TitleMain
	title.menu().simulate_fresh()
	await _settled()
	site = get_tree().current_scene as SiteMain
	_check(site != null and not SaveGame.exists(), "held, the 'new drive' disc throws the saved job away")
	if site == null:
		return _finish()
	_check(site.play_seed != saved_seed and site.drive.panels_broken() == 0 and site.runner.index == 0,
		"and opens a different, untouched drive (%d, was %d)" % [site.play_seed, saved_seed])
	_finish()


func _finish() -> void:
	SaveGame.clear()
	SaveGame.path_override = ""
	print("SWITCH_PROBE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().unload_current_scene()
	await _frames(2)
	get_tree().quit(0 if _failures == 0 else 1)


## A scene change lands on the next frame at the earliest, the lot behind a
## title builds in its `_ready` and poses on the frame after that - and a seat
## press is seen and heard for `TitleMain.CUT_DELAY` before the cut it asks for.
func _settled() -> void:
	await get_tree().create_timer(TitleMain.CUT_DELAY + 0.15).timeout
	await _frames(6)


func _until(cond: Callable, what: String) -> bool:
	for i in range(FRAME_CAP):
		if bool(cond.call()):
			return true
		await get_tree().process_frame
	_check(false, "TIMED OUT waiting for %s" % what)
	return false


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])
