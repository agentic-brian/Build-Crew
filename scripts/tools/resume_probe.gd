extends Node
## The job survives the app closing (the improvement plan's 6.2), row by row.
##
##   godot --headless --path . res://scenes/dev/resume_probe.tscn
##
## For every row the child works - at its start, and one place before its end -
## a save is written to a scratch file and a site is opened on it, and the
## resumed site is held to what play has there: the runner on that row with
## that many places done and the bar at their stops, the machine on site, the
## tool out, the rings on the places still open, the eye on the WIDE (or on the
## pour's own shot), the save on disk naming the same place. Then one move - a
## tap, a press of the button, a hold - shows the job really runs from there.
## Then the places a child takes in any order, a save no child could have made,
## the saves that must start a fresh driveway, and the harness's own isolation.
##
## Prints one line per check, then RESUME_PROBE PASS n/n, and exits 0 / 1.

const SCRATCH := "user://resume_probe_save.json"
const FRAME_CAP := 6000

var _checks: int = 0
var _failures: int = 0
var _packed: PackedScene


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	# A probe decides the OS's reduce-motion for itself, or the picture it
	# measures is decided by the machine it runs on (6.4).
	Settings.motion_override = -1
	await get_tree().process_frame
	_packed = load("res://scenes/site.tscn")
	SaveGame.enabled = true
	SaveGame.path_override = SCRATCH
	SaveGame.clear()
	var job := load("res://data/jobs/new_driveway.tres") as JobDef
	await _every_row(job)
	await _any_order()
	await _refused(job)
	await _isolation()
	SaveGame.clear()
	SaveGame.path_override = ""
	Engine.remove_meta("shot_args")
	for i in range(5):
		await get_tree().process_frame
	print("RESUME_PROBE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


# --- Every row ----------------------------------------------------------------------------------

func _every_row(job: JobDef) -> void:
	var nth := {}
	for i in range(job.steps.size()):
		var s := job.steps[i]
		nth[s.verb] = int(nth.get(s.verb, 0)) + 1
		if s.kind == JobStep.Kind.AUTO:
			continue
		var dones := [0]
		if s.count > 1:
			dones.append(s.count - 1)
		for done: int in dones:
			await _resume_row(job, i, int(nth[s.verb]), done)


func _resume_row(job: JobDef, i: int, nth: int, done: int) -> void:
	var s := job.steps[i]
	var tag := "%s:%d done %d" % [s.verb, nth, done]
	print("--- %s ---" % tag)
	# The sentinel is a key `resume_point` ignores: gone from the file once the
	# resumed site has written its own save.
	var main := await _site(_with(_doc(s.verb, nth, done, [], 2096), "probe_sentinel", 1))
	var runner := main.runner
	_check(runner.index == i and runner.done_in_step == done and not runner.finished,
		"%s: the runner resumes on that row with that many done (%d, %d)" % [tag, runner.index, runner.done_in_step])
	# The bar's step is 0.01: a stop (1/83) rounded, never a stop off.
	var bar_ok := absf(main.hud.step_value() - float(job.weight_before(i, done)) / float(job.total_weight())) < 0.006
	_check(runner.progress == job.weight_before(i, done) and bar_ok,
		"%s: and the bar at their stops (%d of %d, bar %.3f)" % [tag, runner.progress, job.total_weight(), main.hud.step_value()])
	_check(main.play_seed == 2096 and main.seed_from == "save", "%s: on the saved visit's look (seed %d from %s)" % [tag, main.play_seed, main.seed_from])
	# Which machine is on site, as play has it when this row opens.
	var want: String = {"push_rubble": "SkidSteer", "back_dump": "DumpTruck", "tip_gravel": "DumpTruck",
		"back_mixer": "ConcreteTruck", "pour_chute": "ConcreteTruck", "rake_pull": "ConcreteTruck"}.get(s.verb, "")
	var shown: Array[String] = []
	for kind: String in ["SkidSteer", "DumpTruck", "ConcreteTruck"]:
		var m := main.machine(kind)
		if m != null and m.visible:
			shown.append(kind)
	_check(shown == ([want] if want != "" else []), "%s: machines on site %s (want %s)" % [tag, str(shown), want])
	if s.tool != "" and s.tool != "none":
		var t := main.tool_node(s.tool)
		_check(t != null and t.visible, "%s: the %s is out" % [tag, s.tool])
	if s.verb in ["jack_spot", "form_set", "stake_drive", "rebar_lay", "form_strip"]:
		var rings := main.get_node("Rings") as SpotRings
		var open := main._open_picks(s.verb)
		var ring_ids: Array = []
		for k in range(rings.count()):
			ring_ids.append(rings.id_at(k))
		ring_ids.sort()
		var open_ids: Array = Array(open)
		open_ids.sort()
		var on_done := 0
		for id in ring_ids:
			if main.done_places(i).has(id):
				on_done += 1
		_check(rings.count() > 0 and ring_ids == open_ids and on_done == 0,
			"%s: a ring on each place still open and none on a done one (%s, open %s)" % [tag, str(ring_ids), str(open_ids)])
		_check(main.done_places(i).size() == done, "%s: and %d places done in the world (%s)" % [tag, done, str(main.done_places(i))])
	if s.verb == "pour_chute" or SiteVerbs.SCRUB_VERBS.has(s.verb) or SiteVerbs.BACK_VERBS.has(s.verb):
		_check(main.rig.current_shot() == s.shot and not main._opening,
			"%s: opens on its own shot - no chute in the road, no drag under a moving eye, no truck off the picture (%s)" % [tag, main.rig.current_shot()])
	else:
		_check(main.rig.current_shot() == CameraRig.WIDE and main._opening, "%s: opens on the WIDE, the child's own site first (%s)" % [tag, main.rig.current_shot()])
	var disk := SaveGame.load_data()
	var disk_places: Array = []
	for v in disk.get("places", []):
		disk_places.append(int(v))
	_check(not disk.has("probe_sentinel") and String(disk.get("verb", "")) == s.verb and int(disk.get("nth", 0)) == nth \
		and int(disk.get("done", -1)) == done and disk_places == main.done_places(i),
		"%s: the resumed site wrote its own save, naming the same place (%s:%d done %d %s)" % [tag, str(disk.get("verb")),
			int(disk.get("nth", 0)), int(disk.get("done", -1)), str(disk_places)])
	match s.verb:
		"push_rubble":
			var skid := main.machine("SkidSteer")
			var start := Vector3(main.drive.lane_drive_x(done + 1), 0.0, Driveway.Z_APRON - main.config.garage_stand)
			_check(skid != null and Vector2(skid.global_position.x - start.x, skid.global_position.z - start.z).length() < 0.4,
				"%s: the skid steer lined up on lane %d in the garage" % [tag, done + 1])
			var off_pad := 0
			for c in main.drive.lane_chunks(1):
				if c.position.x > Driveway.CENTRE_X + Driveway.WIDTH * 0.5:
					off_pad += 1
			var lane1 := main.drive.lane_chunks(1).size()
			_check(lane1 > 0 and off_pad == (lane1 if done >= 1 else 0) and main.drive.chunks_on_pad() > 0,
				"%s: lane 1's rubble %s (%d of %d off the pad), lane 2's still on it" % [tag, "on the heap" if done >= 1 else "on the pad", off_pad, lane1])
			_check(main.garage_door_k() > 0.99, "%s: the garage door up" % tag)
		"back_dump", "back_mixer":
			_check(main.sfx.is_looping("arrive"), "%s: its engine ticking over in the road" % tag)
		"pour_chute":
			# Three frames in, the chute is already running (its pads are held from
			# the row's first frame): a band from empty, not the one left behind.
			_check(main.drive.fill_fraction() < 0.05, "%s: the pour starts again from an empty form (%.3f)" % [tag, main.drive.fill_fraction()])
		"rake_pull":
			_check(main.sfx.is_looping("mixer") and main.sfx.is_looping("concrete"), "%s: the drum and the chute running" % tag)
		"jack_spot":
			if done > 0:
				var t2 := main.tool_node(s.tool)
				_check(t2 != null and t2.global_position.distance_to(SiteMain.TOOL_REST[s.tool]) > 1.0,
					"%s: mid-row the %s stands over the work, not on the lawn" % [tag, s.tool])
		"stake_drive":
			# No `done > 0` here. The sledge is wound up over the next peg from
			# the moment the row OPENS, not just mid-row (2026-09-16): a resumed
			# row at done 0 must show the hammer up, the same as a fresh one.
			var t3 := main.tool_node(s.tool)
			_check(t3 != null and t3.global_position.distance_to(SiteMain.TOOL_REST[s.tool]) > 1.0,
				"%s: the sledge waits over the work at every done, never on the lawn" % tag)
		"form_strip":
			_check(main.garage_door_k() < 0.05, "%s: the garage shut for the evening" % tag)
			var cones := main._cone_posts()
			_check(cones.size() == 2 and cones[0].global_position.distance_to(main._cone_mouth(0)) < 0.01,
				"%s: the cones across the mouth" % tag)
	# One move, and the job answers it.
	var moved := false
	match s.kind:
		JobStep.Kind.TAP:
			runner.tap()
			for f in range(FRAME_CAP):
				if runner.done_in_step > done or runner.index != i:
					moved = true
					break
				await get_tree().process_frame
		JobStep.Kind.BUTTON:
			main.hud.simulate_button(s.button_id())
			await _frames(2)
			moved = runner.is_busy() and runner.index == i and runner.done_in_step == done
		JobStep.Kind.HOLD:
			runner.hold(true)
			await _frames(20)
			# Still inside the beat it resumed: a verb that bailed at once has
			# already counted its place (and usually entered the next row).
			moved = runner.is_busy() and runner.index == i and runner.done_in_step == done
			runner.hold(false)
	_check(moved, "%s: and one %s plays from there" % [tag, ["tap", "press of the button", "", "hold"][s.kind]])
	await _free(main)


# --- The places a child takes in any order -------------------------------------------------------

func _any_order() -> void:
	print("--- any order ---")
	var main := await _site(_doc("jack_spot", 1, 2, [3, 2], 0))
	_check(main.drive.spot_done(2) and main.drive.spot_done(3) and not main.drive.spot_done(1),
		"the hammer's spots 3 and 2 done, spot 1 still open")
	_check(main.done_places(0) == [2, 3] and (main.get_node("Rings") as SpotRings).count() == 1,
		"one ring left, on it (%s)" % str(main.done_places(0)))
	await _free(main)
	main = await _site(_doc("jack_spot", 1, 4, [1, 2, 3, 6], 0))
	_check(main.drive.panel_is_broken(1) and main.drive.spot_done(6) and not main.drive.spot_done(4),
		"a whole slab and one spot of the next: the first broken, spot 6 done, spot 4 open")
	await _free(main)
	main = await _site(_doc("rebar_lay", 1, 2, [3, 1], 0))
	var ri := main.runner.index
	_check(main.drive.bar_is_in(1) and main.drive.bar_is_in(3) and not main.drive.bar_is_in(2),
		"bars 3 and 1 down, bar 2 waiting - not bars 1 and 2 by count")
	_check(main.done_places(ri) == [1, 3], "and the save names them (%s)" % str(main.done_places(ri)))
	# The posed picture of the same place is the same world (the plan's check).
	await _free(main)
	main = await _site({}, {"stage": "based", "step": "rebar_lay", "done": "2", "places": "3,1"})
	_check(main.drive.bar_is_in(1) and main.drive.bar_is_in(3) and not main.drive.bar_is_in(2) and main.drive.chairs_shown(),
		"and `--places=3,1` poses the same bars")
	await _free(main)
	main = await _site(_doc("form_strip", 1, 2, [3, 1], 0))
	_check(main.drive.form_is_stripped(1) and main.drive.form_is_stripped(3) and not main.drive.form_is_stripped(2),
		"boards 3 and 1 stripped, board 2 still in")
	await _frames(20)
	var song: AudioStreamPlayer = main.sfx.get("_music")
	_check(song == null or absf(song.volume_db - (-30.0)) < 0.6,
		"the song down for the evening (%s)" % (str(song.volume_db) if song != null else "no song on disk"))
	await _free(main)
	main = await _site(_doc("stake_drive", 1, 7, [1, 2, 3, 4, 5, 6, 8], 0))
	var si := main.runner.index
	_check(main.drive.stake_is_in(8) and not main.drive.stake_is_in(7) and main.done_places(si) == [1, 2, 3, 4, 5, 6, 8]
		and (main.get_node("Rings") as SpotRings).id_at(0) == 7,
		"seven pegs with the eighth before the seventh: peg 7 still standing, its ring lit (%s)" % str(main.done_places(si)))
	await _free(main)
	main = await _site(_doc("stake_drive", 2, 1, [10], 0))
	si = main.runner.index
	_check(main.drive.stake_is_in(10) and not main.drive.stake_is_in(9) and main.done_places(si) == [10],
		"the kerb board's far peg in, its near one standing (%s)" % str(main.done_places(si)))
	await _free(main)
	main = await _site(_doc("form_set", 1, 1, [2], 0))
	_check(main.drive.form_is_in(2) and not main.drive.form_is_in(1), "the second long board in, the first still waiting")
	await _free(main)
	# A save no child could have made: a spot on the second slab while the first is whole.
	main = await _site(_doc("jack_spot", 1, 1, [5], 0))
	_check(main.runner.index == 0 and main.runner.done_in_step == 1 and main.drive.spot_done(1) and not main.drive.spot_done(5),
		"a save naming a spot no child could reach resumes on the first open one")
	await _free(main)


# --- Saves that start a fresh driveway -----------------------------------------------------------

func _refused(job: JobDef) -> void:
	print("--- refused ---")
	var main := await _site(_doc("jack_spot", 1, 0, [], 0))
	# Pure: the normalisation, read without building anything more.
	var cases := [
		[_doc("skid_leave", 1, 0, [], 5), job.index_of("form_set"), 0],
		[_doc("dump_leave", 1, 0, [], 5), job.index_of("compact_base"), 0],
		[_doc("mixer_leave", 1, 0, [], 5), job.index_of("spray_water"), 0],
		[_doc("slab_cure", 1, 0, [], 5), job.index_of("form_strip"), 0],
		[_doc("rebar_lay", 1, 12, [], 5), job.index_of("call_mixer"), 0],
		[_doc("jack_spot", 1, 12, [], 5), job.index_of("call_skid"), 0],
		[_doc("push_rubble", 1, 1, [], 5), job.index_of("push_rubble"), 1],
	]
	for c: Array in cases:
		var p := main.resume_point(c[0])
		_check(not p.is_empty() and int(p["step"]) == int(c[1]) and int(p["done"]) == int(c[2]),
			"%s done %d resumes at step %d done %d (%s)" % [c[0]["verb"], c[0]["done"], c[1], c[2], str(p)])
	var fresh := {
		"the last board stripped (the payoff)": _doc("form_strip", 1, 3, [1, 2, 3], 5),
		"another job": _with(_doc("jack_spot", 1, 1, [1], 5), "job", "patio"),
		"a job with a row added since": _with(_doc("jack_spot", 1, 1, [1], 5), "rows", 26.0),
		"a verb the job has not got": _with(_doc("jack_spot", 1, 1, [1], 5), "verb", "edger"),
		"no seed": _with(_doc("jack_spot", 1, 1, [1], 5), "seed", null),
		"a seed that is a string": _with(_doc("jack_spot", 1, 1, [1], 5), "seed", "7"),
		"a fractional done": _with(_doc("jack_spot", 1, 1, [1], 5), "done", 1.5),
	}
	for what: String in fresh:
		_check(main.resume_point(fresh[what]).is_empty(), "%s: a fresh driveway" % what)
	var p2 := main.resume_point(_doc("rebar_lay", 1, 2, [1, 2, 3], 5))
	_check(not p2.is_empty() and (p2["places"] as Array).is_empty(), "places that do not match the count are dropped for the canonical ones")
	var p3 := main.resume_point(_with(_doc("rebar_lay", 1, 2, [1, 3], 5), "places", "1,3"))
	_check(not p3.is_empty() and (p3["places"] as Array).is_empty(), "and places that are not a list")
	await _free(main)
	# On disk: garbage, a newer version, and a finished job each open a fresh job.
	for what: String in ["not json{", JSON.stringify(_with(_doc("rebar_lay", 1, 2, [1, 3], 5), "version", 99)),
			JSON.stringify(_with(_doc("form_strip", 1, 3, [1, 2, 3], 5), "version", 1))]:
		main = await _site(what)
		_check(main.runner.index == 0 and main.runner.done_in_step == 0 and main.drive.panels_broken() == 0 and main.seed_from != "save",
			"a save of %s opens a fresh driveway (seed from %s)" % [what.left(24), main.seed_from])
		_check(FileAccess.get_file_as_string(SCRATCH) == what, "and nothing is written before the child does something")
		main.runner.tap()
		await _until(func() -> bool: return main.runner.done_in_step >= 1)
		var d := SaveGame.load_data()
		_check(String(d.get("verb", "")) == "jack_spot" and int(d.get("done", 0)) == 1 and int(d.get("seed", -1)) == main.play_seed,
			"the first bite writes a whole save over it (%s)" % str(d))
		_privacy(JSON.parse_string(FileAccess.get_file_as_string(SCRATCH)), "the save the game wrote on that bite")
		await _free(main)


# --- A harness never touches the child's save ---------------------------------------------------

func _isolation() -> void:
	print("--- isolation ---")
	# A posed run with a save waiting: a pose, never a resume, and the file untouched.
	SaveGame.clear()
	SaveGame.save_data(_doc("rebar_lay", 1, 2, [1, 3], 2358))
	var before := FileAccess.get_file_as_string(SCRATCH)
	var main := await _site(null, {"stage": "based"})
	await _frames(60)
	_check(main.runner.current_step().verb == "rebar_lay" and main.runner.done_in_step == 0 and main.play_seed == 0,
		"a --stage run with a save on disk poses, on the legacy lot (seed %d)" % main.play_seed)
	_check(FileAccess.get_file_as_string(SCRATCH) == before, "and never writes the save")
	await _free(main)
	# A harness that did not point the save at a scratch file cannot read or write it.
	SaveGame.path_override = ""
	var args := {}
	Engine.set_meta("shot_args", args)
	var probe := _packed.instantiate() as SiteMain
	_check(not probe.saves_on(args), "a harness with no scratch file never saves")
	probe.free()
	SaveGame.enabled = false
	SaveGame.path_override = SCRATCH
	SaveGame.clear()
	_check(FileAccess.file_exists(SCRATCH), "and a harness with saving off cannot delete a save")
	_check(SaveGame.load_data().is_empty() and not SaveGame.save_data({"x": 1}), "or read or write one")
	SaveGame.enabled = true
	# A save that cannot be written says so, and leaves the one there alone.
	var before_bad := FileAccess.get_file_as_string(SCRATCH)
	SaveGame.path_override = "user://no_such_folder/save.json"
	var wrote := SaveGame.save_data(_doc("jack_spot", 1, 1, [1], 5))
	SaveGame.path_override = SCRATCH
	_check(not wrote and FileAccess.get_file_as_string(SCRATCH) == before_bad, "a save that cannot be written reports it and touches nothing")


## The document a game wrote: exactly its keys, and nothing that is a time -
## not in a key's name, not in any value (a date, a number the size of a clock).
func _privacy(doc: Variant, what: String) -> void:
	if not (doc is Dictionary):
		_check(false, "%s parses" % what)
		return
	var d: Dictionary = doc
	var keys := d.keys()
	keys.sort()
	var timey := 0
	for k in keys:
		var v := str(d[k])
		if String(k).contains("time") or String(k).contains("date") or String(k).ends_with("_at"):
			timey += 1
		if RegEx.create_from_string("\\d{4}-\\d{2}").search(v) != null or RegEx.create_from_string("\\d{2}:\\d{2}").search(v) != null:
			timey += 1
		if (d[k] is float) and float(d[k]) >= 1e5:
			timey += 1
	_check(keys == ["done", "job", "nth", "places", "rows", "seed", "verb", "version"] and timey == 0
		and String(d.get("job", "")) == "new_driveway" and int(d.get("rows", 0)) == 25,
		"%s: exactly its eight keys, and nothing in it is a time (%s, %d)" % [what, str(keys), timey])


# --- Plumbing ------------------------------------------------------------------------------------

func _doc(verb: String, nth: int, done: int, places: Array, seed: int) -> Dictionary:
	return {"job": "new_driveway", "rows": 25, "verb": verb, "nth": nth, "done": done, "places": places, "seed": seed}


func _with(d: Dictionary, key: String, value: Variant) -> Dictionary:
	var c := d.duplicate(true)
	if value == null:
		c.erase(key)
	else:
		c[key] = value
	return c


## A site opened on a save: a Dictionary is written through `SaveGame`, a
## String straight to the file (garbage, a newer version), null leaves the file
## as it is. `args` are its `shot_args`.
func _site(save: Variant, args: Dictionary = {}) -> SiteMain:
	if save is Dictionary:
		SaveGame.clear()
		if not (save as Dictionary).is_empty():
			SaveGame.save_data(save)
	elif save is String:
		SaveGame.clear()
		var f := FileAccess.open(SCRATCH, FileAccess.WRITE)
		f.store_string(save)
		f.close()
	Engine.set_meta("shot_args", args)
	var main := _packed.instantiate() as SiteMain
	add_child(main)
	await _frames(3)
	return main


func _free(main: SiteMain) -> void:
	main.queue_free()
	await _frames(3)


func _until(cond: Callable) -> bool:
	for i in range(FRAME_CAP):
		if bool(cond.call()):
			return true
		await get_tree().process_frame
	_check(false, "TIMED OUT")
	return false


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])
