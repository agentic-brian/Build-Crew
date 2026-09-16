extends Node
## The title row (the improvement plan's 6.3), held to what it promises.
##
##   godot --headless --path . res://scenes/dev/title_probe.tscn
##   godot --path . --resolution 1024x768 res://scenes/dev/title_probe.tscn
##
## The row is built as a CHILD of this probe, never as the current scene, so
## `TitleMain._leave` answers with `job_requested` instead of changing the
## scene - the same door `TitleMain` gives a harness, and the reason a press can
## be tested at all. Every press here is a REAL touch pushed through the
## viewport, because the thing under test is a finger landing on a disc.
##
## Prints one line per check, then TITLE_PROBE PASS n/n, and exits 0 / 1.

const SCRATCH := "user://title_probe_save.json"
## How many jobs the row seats today. A drift guard: a seat that appears or
## vanishes without this number moving is a seat nobody decided on.
const TITLE_SEATS_EXPECTED := 1

var _checks: int = 0
var _failures: int = 0
var _packed: PackedScene
var _asked: Array = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# A probe decides the OS's reduce-motion for itself, or the picture it
	# measures is decided by the machine it runs on (6.4).
	Settings.motion_override = -1
	# A headless viewport is a square and would measure nothing anyone sees, so
	# headless gets the shipped 1280x720. A WINDOWED run is given its shape on
	# the command line (`--resolution 1024x768`, `1565x720`), which the engine
	# eats before `OS.get_cmdline_args()` ever sees it - so the only honest test
	# is the server: stamping a size over a windowed run would measure one shape
	# three times.
	if DisplayServer.get_name() == "headless":
		get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	print("  frame %s" % str(get_viewport().get_visible_rect().size))
	_packed = load("res://scenes/main.tscn")
	SaveGame.enabled = true
	SaveGame.path_override = SCRATCH
	SaveGame.clear()
	await _the_row()
	await _the_press()
	await _the_modes()
	await _the_busy_rows()
	await _the_refusals()
	await _the_hold()
	await _the_backdrop()
	_the_backdrop_left_no_shape_behind()
	await _a_second_job_keeps_its_save()
	SaveGame.clear()
	SaveGame.path_override = ""
	SaveGame.enabled = true
	Engine.remove_meta("shot_args")
	for i in range(5):
		await get_tree().process_frame
	print("TITLE_PROBE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


# --- The row ------------------------------------------------------------------------------------

func _the_row() -> void:
	print("--- the row ---")
	var title := await _title()
	var menu := title.menu()
	var keys := menu.seat_keys()
	# The FILE, not the code's own reader: a row built from something else would
	# agree with `JobIcons.keys()` all day.
	var want: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/jobs.json"))
	_check(want is Array and Array(keys) == (want as Array) and keys.size() == TITLE_SEATS_EXPECTED,
		"the row is data/jobs/jobs.json itself, in its order (%s, file %s)" % [str(keys), str(want)])
	var frame := get_viewport().get_visible_rect()
	var bad := 0
	var smallest := INF
	var rects := menu.row_rects()
	for i in range(rects.size()):
		var r: Rect2 = rects[i]
		smallest = minf(smallest, minf(r.size.x, r.size.y))
		if not frame.encloses(r):
			bad += 1
		for j in range(i + 1, rects.size()):
			if r.intersects(rects[j]):
				bad += 1
	_check(bad == 0 and smallest >= 180.0,
		"every seat is whole on the screen and a hand wide (%.0f px), none overlapping (%d)" % [smallest, bad])
	var conns := 0
	for key: String in keys:
		var b := menu._root.get_node_or_null("Seat_" + key) as Button
		if b != null:
			conns += b.pressed.get_connections().size()
	_check(conns == keys.size(), "each seat answers exactly one listener - a fast double tap cannot start two jobs (%d)" % conns)
	# The corner disc, measured: whole on the screen, in the corner the work's
	# own buttons do NOT use, and never under the job's disc.
	menu.set_mode(true)
	await _frames(2)
	var fr := menu.fresh_rect()
	var seat := menu.seat_rect(keys[0])
	_check(frame.encloses(fr) and fr.get_center().x > frame.size.x * 0.6 and fr.get_center().y > frame.size.y * 0.6 \
		and not fr.intersects(seat) and minf(fr.size.x, fr.size.y) >= 120.0,
		"the 'new drive' disc is whole, in the bottom-right corner, clear of the job's disc (%s)" % str(fr))
	menu.set_mode(false)
	# The picture is the machine the job's own call button shows.
	var key0 := keys[0]
	_check(menu.is_modelled(key0), "the seat carries the real machine, not the drawn stand-in")
	_check(menu.seat_parts(key0) == 1,
		"one model in it: the blade is an ATTACHMENT on the skid steer, not a second machine (%d)" % menu.seat_parts(key0))
	var icon := menu._root.get_node_or_null("Seat_" + key0 + "/Prop_" + JobIcons.hero(key0)) as PropIcon
	var blade := 0
	var bucket_drawn := 0
	if icon != null:
		for n in icon.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			var under_blade := false
			var at: Node = mi
			while at != null:
				if String(at.name).begins_with("PushBlade"):
					under_blade = true
					break
				at = at.get_parent()
			if under_blade:
				blade += 1
			elif String(mi.name).begins_with("Bucket") and mi.layers != 0 and mi.visible:
				bucket_drawn += 1
	_check(blade > 0 and bucket_drawn == 0,
		"and it is wearing the PUSH BLADE, with the bucket's own mesh off the layers (%d blade, %d bucket)" % [blade, bucket_drawn])
	var style := (menu._root.get_node("Seat_" + key0) as Button).get_theme_stylebox("normal") as StyleBoxFlat
	_check(style != null and style.bg_color.is_equal_approx(JobIcons.disc(key0)) and JobIcons.disc(key0).is_equal_approx(Brand.BLUE),
		"on a blue disc - not the call button's cream, NEXT's green or the machine's own yellow")
	# No words anywhere on this screen (the pillar 6.4 will have to argue with).
	# Anything DRAWN: the backdrop's own HUD is in the tree, invisible, and it
	# carries the job's "YAY!" banner - a word the child never sees here.
	var words: Array[String] = []
	for n in title.find_children("*", "", true, false):
		var text := ""
		if n is Label:
			text = String((n as Label).text)
		elif n is RichTextLabel:
			text = String((n as RichTextLabel).text)
		if text.strip_edges() != "" and (n as CanvasItem).is_visible_in_tree():
			words.append("%s '%s'" % [n.name, text])
	_check(words.is_empty(), "there is not one word drawn on the title row (%s)" % str(words))
	# The settings cog (6.4) stands in the one corner nothing else uses, and
	# never on a disc a child is aiming at.
	var panel := title.get_node_or_null("Settings")
	var cog := panel.get("_opener") as Control if panel != null else null
	var cog_box := cog.get_global_rect() if cog != null else Rect2()
	var clashes := 0
	for r: Rect2 in menu.row_rects():
		clashes += 1 if r.intersects(cog_box) else 0
	clashes += 1 if menu.fresh_rect().intersects(cog_box) else 0
	_check(cog != null and cog.visible and cog_box.position.x < frame.size.x * 0.25 		and cog_box.position.y < frame.size.y * 0.25 and clashes == 0,
		"the settings cog is on the row, top-left, clear of every disc (%s)" % str(cog_box))
	await _free(title)


# --- A press, and a miss --------------------------------------------------------------------------

func _the_press() -> void:
	print("--- the press ---")
	var title := await _title()
	var menu := title.menu()
	var key := menu.seat_keys()[0]
	var heard := String(title.backdrop().sfx.last_played)
	# A finger on the lawn beside the disc: heard, and it does NOT reach the lot
	# behind the row (at the payoff pose every press there would toot the car).
	var honks := int(title.backdrop().sfx.played_count.get("horn", 0))
	# On nothing at all: the top-LEFT corner is the settings cog's since 6.4, so
	# a miss has to be somewhere that is really empty.
	await _touch(Vector2(get_viewport().get_visible_rect().size.x * 0.5, 120.0))
	_check(_asked.is_empty(), "a finger on nothing starts no job")
	_check(String(title.backdrop().sfx.last_played) == "pop" and heard != "pop", "the miss is heard, quietly")
	_check(int(title.backdrop().sfx.played_count.get("horn", 0)) == honks,
		"and it never reaches the lot behind the row")
	# The seat itself.
	await _touch(menu.seat_rect(key).get_center())
	_check(_asked.size() == 1 and String(_asked[0][0]) == key, "a real touch on the disc asks for that job (%s)" % str(_asked))
	_check(String(title.backdrop().sfx.last_played) == "crank", "and the diesel turns over (%s)" % String(title.backdrop().sfx.last_played))
	_check(not Engine.has_meta(SiteMain.PICK_META) and not Engine.has_meta(SiteMain.NEXT_SEED_META),
		"a press inside a harness leaves no pick behind for whatever runs next")
	_check(menu._root.modulate.a >= 0.999, "nothing fades: the row is whole in the frame the job is asked for")
	await _free(title)


# --- The three things the title can be looking at ---------------------------------------------------

func _the_modes() -> void:
	print("--- what is behind the row ---")
	# 1. Nothing saved, nothing finished: a fresh visit's cracked drive.
	SaveGame.clear()
	var title := await _title()
	var lot := title.backdrop()
	_check(title.mode() == "fresh" and lot.dress_stage == "old" and lot.seed_from == "dress",
		"with nothing saved the row stands on a cracked drive (%s, %s)" % [title.mode(), lot.dress_stage])
	_check(not title.menu().fresh_visible(), "and there is no 'new drive' disc: the one disc already starts one")
	var fresh_icon := title.menu()._fresh.get_node_or_null("Prop_fresh") as Control
	_check(fresh_icon != null and not fresh_icon.visible,
		"whose picture is not being rendered while it is down (only `visible` stops a SubViewport)")
	var standing := lot.play_seed
	var offered := title._fresh_seed()
	await _touch(title.menu().seat_rect(title.menu().seat_keys()[0]).get_center())
	_check(_asked.size() == 1 and not bool(_asked[0][1]) and int(title.pick().get("seed", -2)) == -2,
		"the press asks for a NEW drive")
	_check(offered == standing and standing > 0,
		"and it is the very lot the disc was standing in front of, not another one (%d)" % offered)
	await _free(title)
	# 2. A job the child left.
	var doc := {"job": "new_driveway", "rows": 25, "verb": "rebar_lay", "nth": 1, "done": 2, "places": [1, 3], "seed": 2096}
	SaveGame.save_data(doc)
	title = await _title()
	lot = title.backdrop()
	_check(title.mode() == "carry_on" and lot.play_seed == 2096 and lot.resume_ready(),
		"a job left behind: the row stands on the child's OWN drive, on its own visit (%d)" % lot.play_seed)
	_check(lot.drive.bar_is_in(1) and lot.drive.bar_is_in(3) and not lot.drive.bar_is_in(2),
		"at the row and the places they left it (bars 3 and 1 down)")
	_check(title.menu().fresh_visible(), "and the 'new drive' disc is up beside it")
	await _touch(title.menu().seat_rect(title.menu().seat_keys()[0]).get_center())
	_check(_asked.size() == 1 and bool(_asked[0][1]), "the disc CARRIES ON that job")
	_check(SaveGame.exists(), "and the save is still there for the level to resume from")
	await _free(title)
	# 3. A job just finished: the reward is still standing behind the choice.
	SaveGame.clear()
	Engine.set_meta(SiteMain.LAST_SEED_META, 61)
	title = await _title()
	lot = title.backdrop()
	# On THIS backdrop the job is over, so a press that reached the lot would
	# toot the car and kick NEXT (`SiteMain._payoff_press`). It must not.
	var honks := int(lot.sfx.played_count.get("horn", 0))
	lot._place_car_on_drive()
	await _frames(2)
	await _touch(lot.camera.unproject_position(lot.car.global_position))
	_check(int(lot.sfx.played_count.get("horn", 0)) == honks and _asked.is_empty(),
		"a finger on the car in the picture behind the row reaches nothing (%d honks)" % int(lot.sfx.played_count.get("horn", 0)))
	_check(not Engine.has_meta(SiteMain.LAST_SEED_META), "the finished visit's seed is taken once")
	_check(title.mode() == "fresh" and lot.dress_stage == "parked" and lot.play_seed == 61,
		"and the row stands on the drive that was just built, car and all (%s, %d)" % [lot.dress_stage, lot.play_seed])
	var same := 0
	for i in range(12):
		var seed_next: int = title._fresh_seed()
		if not SiteLook.differs(SiteLook.for_seed(seed_next), lot.look):
			same += 1
	_check(same == 0, "the next drive it offers is a different one - car, house and cracks (%d repeats of 12)" % same)
	await _free(title)


## The rows a pose leaves something RUNNING behind: the pour arms four steering
## pads (a hidden pad still eats the touch over it, and one of them stands where
## the corner disc does), and the come-along starts the drum and the pour loops.
func _the_busy_rows() -> void:
	print("--- the rows that leave something running ---")
	var docs := {
		"a job left at the pour": {"job": "new_driveway", "rows": 25, "verb": "pour_chute", "nth": 1, "done": 0, "places": [], "seed": 2096},
		"a job left at the come-along": {"job": "new_driveway", "rows": 25, "verb": "rake_pull", "nth": 1, "done": 0, "places": [], "seed": 2096},
	}
	for what: String in docs:
		SaveGame.clear()
		SaveGame.save_data(docs[what])
		var title := await _title()
		var lot := title.backdrop()
		var menu := title.menu()
		_check(title.mode() == "carry_on" and not lot.hud.pads_enabled() and not lot.hud.pad_visible("right"),
			"%s: the steering pads are down, so nothing invisible is left to eat a press" % what)
		_check(not lot.sfx.is_looping("mixer") and not lot.sfx.is_looping("concrete") and not lot.sfx.is_looping("arrive"),
			"%s: and no engine is left running under the menu" % what)
		# The press those pads used to swallow: a real finger, on the corner disc.
		var at := menu.fresh_rect().get_center()
		_touch_down(at)
		await get_tree().create_timer(1.1).timeout
		_touch_up(at)
		await _frames(2)
		_check(_asked.size() == 1 and not SaveGame.exists(),
			"%s: and a real hold on the corner disc still reaches it (%s)" % [what, str(_asked)])
		await _free(title)


# --- A save the level would refuse -------------------------------------------------------------------

func _the_refusals() -> void:
	print("--- a save the level would not take ---")
	var docs := {
		"another job": {"job": "patio", "rows": 25, "verb": "rebar_lay", "nth": 1, "done": 2, "places": [1, 3], "seed": 5},
		"a job with a row added since": {"job": "new_driveway", "rows": 26, "verb": "rebar_lay", "nth": 1, "done": 2, "places": [1, 3], "seed": 5},
		"a verb the job has not got": {"job": "new_driveway", "rows": 25, "verb": "edger", "nth": 1, "done": 0, "places": [], "seed": 5},
		"no seed": {"job": "new_driveway", "rows": 25, "verb": "rebar_lay", "nth": 1, "done": 2, "places": [1, 3]},
		"the last board stripped": {"job": "new_driveway", "rows": 25, "verb": "form_strip", "nth": 1, "done": 3, "places": [1, 2, 3], "seed": 5},
	}
	for what: String in docs:
		SaveGame.clear()
		SaveGame.save_data(docs[what])
		var title := await _title()
		_check(title.mode() == "fresh" and not title.menu().fresh_visible() and not SaveGame.exists(),
			"%s: the row offers a new drive only, and the stale file is cleared where the child chooses" % what)
		await _free(title)


# --- The hold that throws a drive away ----------------------------------------------------------------

func _the_hold() -> void:
	print("--- the new drive ---")
	var doc := {"job": "new_driveway", "rows": 25, "verb": "jack_spot", "nth": 1, "done": 2, "places": [2, 3], "seed": 2096}
	# Let go early: nothing happens.
	SaveGame.clear()
	SaveGame.save_data(doc)
	var title := await _title()
	var menu := title.menu()
	var at := menu.fresh_rect().get_center()
	_touch_down(at)
	await get_tree().create_timer(0.55).timeout
	var part := menu.fresh_fill()
	_touch_up(at)
	await _frames(2)
	_check(part > 0.4 and part < 0.95, "the ring fills while the disc is held (%.2f of the way round)" % part)
	_check(SaveGame.exists() and _asked.is_empty() and menu.fresh_fill() == 0.0,
		"let go early and the job is still there, the ring empty")
	_check(String(title.backdrop().sfx.last_played) == "pop", "and it says so (%s)" % String(title.backdrop().sfx.last_played))
	# Held to the end: the drive is thrown away, and a different one begins.
	_touch_down(at)
	await get_tree().create_timer(1.15).timeout
	_touch_up(at)
	await _frames(2)
	_check(not SaveGame.exists(), "held to the end, the saved drive is gone - decided on the title, not inside the level")
	_check(_asked.size() == 1 and not bool(_asked[0][1]), "and a NEW drive is asked for (%s)" % str(_asked))
	# Not the drive that was just thrown away: a child handed back the one they
	# binned has been told the disc does nothing.
	var same := 0
	for i in range(12):
		if not SiteLook.differs(SiteLook.for_seed(title._fresh_seed()), title.backdrop().look):
			same += 1
	_check(same == 0, "a DIFFERENT drive from the one thrown away, every time (%d repeats of 12)" % same)
	_check(String(title.backdrop().sfx.last_played) == "breaker", "the breaker answers it")
	await _free(title)
	# A finger that slides off the disc lets go of it.
	SaveGame.clear()
	SaveGame.save_data(doc)
	title = await _title()
	menu = title.menu()
	at = menu.fresh_rect().get_center()
	_touch_down(at)
	await get_tree().create_timer(0.35).timeout
	_drag(Vector2(at.x - menu.fresh_rect().size.x, at.y))
	await get_tree().create_timer(0.9).timeout
	_check(SaveGame.exists() and _asked.is_empty() and menu.fresh_fill() == 0.0,
		"a finger dragged off the disc lets go of it: the job is still there (%.2f)" % menu.fresh_fill())
	_touch_up(at)
	await _free(title)
	# With nothing saved there is nothing to throw away.
	SaveGame.clear()
	title = await _title()
	_check(not title.menu().fresh_visible(), "with nothing saved the disc is not on the screen at all")
	await _free(title)


# --- The backdrop is a backdrop -------------------------------------------------------------------------

func _the_backdrop() -> void:
	print("--- the lot behind the row ---")
	var doc := {"job": "new_driveway", "rows": 25, "verb": "rebar_lay", "nth": 1, "done": 2, "places": [1, 3], "seed": 2096}
	SaveGame.clear()
	SaveGame.save_data(doc)
	var before := FileAccess.get_file_as_string(SCRATCH)
	# A seed planted for the JOB must still be there after the title is built:
	# whichever SiteMain enters first would otherwise eat it.
	Engine.set_meta(SiteMain.NEXT_SEED_META, 777)
	var title := await _title()
	var lot := title.backdrop()
	_check(Engine.has_meta(SiteMain.NEXT_SEED_META) and int(Engine.get_meta(SiteMain.NEXT_SEED_META)) == 777,
		"the backdrop does not eat the seed the next job was given")
	Engine.remove_meta(SiteMain.NEXT_SEED_META)
	_check(not lot.saves_on({}), "it is nobody's game: it never saves")
	_check(lot.hud != null and not lot.hud.visible, "no bar, no buttons")
	var rings := lot.get_node_or_null("Rings") as SpotRings
	_check(rings != null and rings.count() == 0, "no gold rings saying tap here - the thing to tap is the disc")
	var tools_out := 0
	for kind: String in lot.tools:
		if (lot.tools[kind] as Node3D).visible:
			tools_out += 1
	_check(tools_out == 0, "and no tool standing out on the drive (%d)" % tools_out)
	_check(not lot.runner.is_busy() and lot.runner.index >= 0, "it plays no beats")
	var sites := 0
	for n in get_tree().root.find_children("*", "Node3D", true, false):
		if n is SiteMain:
			sites += 1
	_check(sites == 1, "there is exactly ONE lot in the process (%d)" % sites)
	var gens := 0
	for p in title.find_children("*", "AudioStreamPlayer", true, false):
		if (p as AudioStreamPlayer).stream is AudioStreamGenerator:
			gens += 1
	_check(gens == 0, "and nothing under the title plays off an AudioStreamGenerator (%d)" % gens)
	_check(not Engine.has_meta("shot_args"), "the title never sets shot_args, which would follow the child into the job")
	await _frames(30)
	_check(FileAccess.get_file_as_string(SCRATCH) == before, "the child's save is byte-identical after the row has stood there")
	_check(SaveGame.enabled and SaveGame.path_override == SCRATCH, "and the switch and the path are as they were")
	await _free(title)


# --- Plumbing -----------------------------------------------------------------------------------------

## A title row as a CHILD: `current_scene` is the probe, so the seat answers
## with `job_requested` instead of changing the scene.
func _title() -> TitleMain:
	_asked.clear()
	var title := _packed.instantiate() as TitleMain
	add_child(title)
	await _frames(3)
	title.job_requested.connect(func(job: String, carry_on: bool) -> void: _asked.append([job, carry_on]))
	return title


func _free(title: TitleMain) -> void:
	title.queue_free()
	await _frames(3)


func _touch(at: Vector2) -> void:
	_touch_down(at)
	await _frames(2)
	_touch_up(at)
	await _frames(2)


func _touch_down(at: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = at
	ev.pressed = true
	get_viewport().push_input(ev, true)


## A finger that moves without lifting.
func _drag(to: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = 0
	ev.position = to
	get_viewport().push_input(ev, true)


func _touch_up(at: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = at
	ev.pressed = false
	get_viewport().push_input(ev, true)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])


## The title's backdrop is a whole second level, and since 6.5 a level stands its
## job's rectangle up in `Driveway`'s STATIC fields. So a backdrop that has been
## and gone must leave the driveway's own numbers behind it, or the next level -
## the job the child just tapped - is poured into the shape of a picture.
func _the_backdrop_left_no_shape_behind() -> void:
	print("-- what the backdrop leaves behind")
	var job: JobDef = load("res://data/jobs/new_driveway.tres")
	var spec: SlabSpec = job.slab_spec() if job != null else null
	_check(spec != null and spec.is_live(),
		"after a backdrop has stood, the rectangle is still the driveway's (%s)" % str(SlabSpec.live()))


## A SECOND job's save must survive a relaunch (6.5).
##
## The backdrop loads `new_driveway` unless it is told otherwise, and
## `SiteMain.resume` refuses a document whose "job" is not the one it loaded. So
## a child who saved a sidewalk flag came back to a driveway backdrop that said
## "nothing to resume", `_mode` fell to "fresh", and `TitleMain` cleared the save
## - their job thrown away with nothing on the screen touched. It is the same
## shape as the held "new drive" disc that survived a pause (session 8).
##
## Nothing can test this without a second job on disk, so one is staged: the
## driveway's own file under another name, removed again at the end. It is
## deliberately named `zz_*` so an eye scanning `data/jobs/` sees it is not real.
func _a_second_job_keeps_its_save() -> void:
	print("-- a second job's save")
	const SECOND := "res://data/jobs/zz_probe_job.tres"
	const SCRATCH := "user://bc_title_second_job.json"
	var src := FileAccess.get_file_as_string("res://data/jobs/new_driveway.tres")
	var f := FileAccess.open(SECOND, FileAccess.WRITE)
	if f == null or src == "":
		_check(false, "a second job can be staged to test this at all")
		return
	f.store_string(src)
	f.close()
	await _frames(2)
	var was_enabled := SaveGame.enabled
	var was_path := SaveGame.path_override
	SaveGame.enabled = true
	SaveGame.path_override = SCRATCH
	SaveGame.clear()
	SaveGame.save_data({"job": "zz_probe_job", "rows": 25, "verb": "rebar_lay",
		"nth": 1, "done": 2, "places": [1, 3], "seed": 2096})
	var title := (load("res://scenes/main.tscn") as PackedScene).instantiate() as TitleMain
	add_child(title)
	await _frames(8)
	var lot: SiteMain = title.backdrop()
	var loaded := String(lot.get("_job_file")) if lot != null else ""
	_check(loaded == "zz_probe_job",
		"the backdrop stands the job the SAVE is for, not the one it loads by default (%s)" % loaded)
	_check(SaveGame.exists() and String(title.mode()) == "carry_on",
		"so a second job's save is carried on, never thrown away on the next launch (%s)" % title.mode())
	title.queue_free()
	await _frames(3)
	SaveGame.clear()
	SaveGame.path_override = was_path
	SaveGame.enabled = was_enabled
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SECOND))
	if FileAccess.file_exists(SECOND + ".import"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SECOND + ".import"))
	_check(not FileAccess.file_exists(SECOND), "and the staged job is cleaned up after itself")
