extends Node
## Plays the WHOLE driveway job with no human at the keyboard, through the same
## public doors a finger comes in by, and asserts the WORLD at every phase.
##
##   godot --headless --path . res://scenes/dev/site_smoke.tscn
##
## Prints one line per check, then SITE_SMOKE PASS n/n, and exits 0 / 1.
##
## The point is not that the code runs: it is that the driveway really gets
## BUILT. Every phase is checked against the thing it is supposed to have
## changed - eighteen bites break six panels, the pad is cleared, four boards and
## ten stakes go in, the base fills, the form fills, the slab is struck off flat,
## all of it is wetted, two joints are cut, all of it is broomed - because a job
## that plays through with nothing happening to the concrete is exactly the bug a
## smoke test is for.
##
## It also asserts the things the user's ten playtest notes were about, because
## those are the ones that will rot first: that the machines never stand inside a
## building, that the skid steer never drives through the rubble at the height it
## started at, that the truck goes away during the pour and comes back, and that
## the hose and the broom do nothing at all where the finger has not been.
##
## Since the plan's sixth session it also plays the VISIT round the job: the
## first site is the legacy lot (a harness names no seed), NEXT is pressed for
## real into a second driveway that must be a different one, and the save is
## read off disk while the job plays - then the tablet is taken away from the
## second job and the job must come back. A scratch save file, never the child's.
##
## Timing note: a headless frame is about 7 ms of real time, so anything paced in
## SECONDS takes hundreds of frames. Nothing here counts frames to decide a beat
## is done; it waits on the runner's own step index, with a cap so a stall is a
## failure rather than a hang.

## How long a single wait may take before it is called a stall. A headless frame
## is about 7 ms, so this is a minute - far longer than any beat in the job, and
## short enough that two stalls do not eat the whole run's time budget and turn a
## clear list of failures into one useless timeout.
const FRAME_CAP := 9000

var _checks: int = 0
var _failures: int = 0
var main: SiteMain
var hud: SiteHud
var runner: JobRunner
var drive: Driveway
var rings: SpotRings
var _job_done: int = 0
## How many frames the mixer's rearmost tyre stood on the pad while it was
## pouring: it must be zero, the steel is under there.
var _on_pad_frames: Array = [0]
var _watch_pad: bool = false
## What was heard the moment each step finished: [step index, last group].
var _done_notes: Array = []
## When each step finished, in msec (the strip's tada waits the phase hold).
var _step_done_ms: Dictionary = {}
## Frames the kerb board or its pegs were on site while the tipper was (5.2),
## and whether the tipper's body was really seen over the kerb end.
var _kerb_seen: Array = [0, false]
var _watch_kerb: bool = false
## The job's whole length in progress stops: the bar measures the child's
## minutes, not their taps (the plan's 3.6), and the three places that named
## this number (the .tres header, DESIGN 2, the code) had all disagreed.
const TOTAL_STOPS := 83
## How many rows the job has: the plan's fifth session added seven (the trucks'
## held reverse legs, the plate, the kerb board's board and pegs, the cure and
## the strip).
const STEP_COUNT := 25
## When the second push ended, so the forms' start can be timed against it.
var _push_ended_ms: int = 0
## The save this run reads and writes: never the child's own (6.2).
const SMOKE_SAVE := "user://site_smoke_save.json"
## The legacy drive's first old crack on the first slab, as the code built it
## before the plan's sixth session put a seed under it: seed 0 must still be
## this drive to the tenth of a millimetre.
const LEGACY_CRACK := Vector3(-0.559623, 0.066, -0.405239)
## The first visit's look and the save written after bars 3 and 1.
var _first_look: Dictionary = {}
var _first_rings: Array[Vector3] = []
var _rebar_doc: Dictionary = {}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# The headless window is not the shipped 16:9 picture (Tree Crew measured a
	# square), and every "is it inside the frame" check below projects through
	# the live camera - so give it the real frame first, or a pair of stakes the
	# full width of the form apart fails a check the real screen passes.
	get_window().size = Vector2i(1280, 720)
	# A probe decides the OS's reduce-motion for itself, or the picture it
	# measures is decided by the machine it runs on (6.4).
	Settings.motion_override = -1
	await get_tree().process_frame
	print("  frame %s" % str(get_viewport().get_visible_rect().size))
	# A harness: the legacy lot (no seed named), and a scratch save cleared
	# first - a killed run's half-done job must not open this one mid-job.
	Engine.set_meta("shot_args", {})
	SaveGame.enabled = true
	SaveGame.path_override = SMOKE_SAVE
	SaveGame.clear()
	var packed: PackedScene = load("res://scenes/site.tscn")
	main = packed.instantiate() as SiteMain
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	hud = main.hud
	runner = main.runner
	drive = main.drive
	rings = main.get_node_or_null("Rings") as SpotRings
	main.job_done.connect(func() -> void: _job_done += 1)
	# Connected AFTER the level's own handler, so what is heard here is what
	# the level played for the step's end (the plan's 1.6).
	# What is COUNTED, not what was played last: a beat that plays nothing at its
	# end (the cure) left the broom's note as "last played" and read as a done.
	runner.step_done.connect(func(i: int) -> void:
		_done_notes.append([i, int(main.sfx.played_count.get("done", 0))])
		_step_done_ms[i] = Time.get_ticks_msec())

	# Awaited: the setup waits real seconds for the idle arrow now, and without
	# the await the jackhammer phase ran underneath it.
	await _the_setup()
	await _phase_jackhammer()
	await _phase_push()
	# The stakes are the back half of `_phase_forms`: they are the same boards and
	# the same hole, so they are checked together.
	await _phase_forms()
	await _phase_base()
	await _phase_compact()
	await _phase_kerb()
	await _phase_rebar()
	await _phase_pour()
	await _phase_rake()
	await _phase_finishing()
	await _phase_strip()
	await _the_payoff()
	await _the_second_job()
	await _the_resume()

	SaveGame.clear()
	SaveGame.path_override = ""
	Engine.remove_meta("shot_args")
	for i in range(10):
		await get_tree().process_frame
	print("SITE_SMOKE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


# --- What the level is before anything is done to it -----------------------------------------

func _the_setup() -> void:
	_check(main.job != null, "the job loaded")
	# No AudioStreamGenerator anywhere in the site (the improvement plan's 0.2):
	# its playback keeps a raw pointer to it, and a site freed under one - which
	# is what NEXT and the house do - crashes the audio thread without a word.
	var players := 0
	var generators := 0
	for p in main.find_children("*", "AudioStreamPlayer", true, false):
		players += 1
		if (p as AudioStreamPlayer).stream is AudioStreamGenerator:
			generators += 1
	_check(players > 0 and generators == 0,
		"no sound in the site plays off an AudioStreamGenerator (%d players, %d generators)" % [players, generators])
	_check(runner.step_count() == STEP_COUNT, "it has all %d beats (%d)" % [STEP_COUNT, runner.step_count()])
	# Every `--stage` still poses the verb it names (they are looked up, not
	# numbered, since the fifth session): a stage that silently shifts is caught
	# here in a second, not in a frame nobody looks at.
	var stage_bad := 0
	for key: String in SiteMain.STAGE_STEP:
		var want: Array = SiteMain.STAGE_STEP[key]
		var at := main.stage_step(key)
		if String(want[0]) == "":
			stage_bad += 0 if at == main.job.steps.size() else 1
		elif at < 0 or at >= main.job.steps.size() or main.job.steps[at].verb != String(want[0]):
			stage_bad += 1
	_check(stage_bad == 0 and main.job.index_of("form_set", 2) > main.job.index_of("tip_gravel"),
		"every posed stage lands on the verb it names, the kerb board's row after the tip (%d wrong)" % stage_bad)
	_check(hud.total_steps() == main.job.total_weight(),
		"the bar is set to this job's %d stops (%d)" % [main.job.total_weight(), hud.total_steps()])
	_check(main.job.total_weight() == TOTAL_STOPS,
		"and the job is %d stops long, weighted by the child's minutes (%d)" % [TOTAL_STOPS, main.job.total_weight()])
	# The slab's rectangle comes from the JOB now (6.5), not from constants -
	# and `Driveway`'s fields are static, so they are process-global. What is
	# standing has to be THIS job's, not whatever level stood here before it.
	var spec0: SlabSpec = main.job.slab_spec()
	_check(spec0 != null and spec0.is_live(),
		"the slab standing is this job's own rectangle, %.1f x %.1f at x %.1f on a %d x %d grid (%s)"
		% [spec0.width, spec0.z_kerb - spec0.z_apron, spec0.centre_x, spec0.cells_x,
			spec0.cells_z, str(SlabSpec.live())])
	_check(absf(Driveway.WIDTH - 3.6) < 0.001 and absf(Driveway.LENGTH - 9.0) < 0.001 		and Driveway.CELLS_X == 6 and Driveway.CELLS_Z == 12,
		"and it is still the driveway's own 3.6 x 9.0 on 6 x 12, the numbers every earlier frame was taken at")
	# The job OPENS on the wide (the plan's 3.1): the house, the cracked drive,
	# the tools, and the first slab's three rings lit in it.
	_check(main.rig.current_shot() == CameraRig.WIDE, "the job opens on the WIDE")
	_check(rings != null and rings.count() == 3 and _all_rings_on_screen(),
		"with the first slab's three rings lit in it")
	_check(drive != null and drive.panel_count() == 4, "the old drive is four panels (%d)" % drive.panel_count())
	_check(drive.jack_spots() == 12, "worked at twelve places, three per panel (%d)" % drive.jack_spots())
	_check(drive.form_count() == 4, "four boards (%d)" % drive.form_count())
	_check(drive.stake_count() == 10, "and TEN stakes, one blow each - none on the expansion strip (%d)" % drive.stake_count())
	_check(drive.bar_count() == 12, "twelve bars of steel to lay (%d)" % drive.bar_count())
	_check(drive.bars_in() == 0 and not drive.chairs_shown(), "none of it down yet")
	var skid0 := main.machine("SkidSteer")
	_check(skid0 != null and skid0.has_blade(),
		"the skid steer has the PUSH BLADE on, not the bucket")
	# And the bucket is really gone from the picture: Godot imports the fleet's
	# `Bucket` as the mesh ITSELF, so the pin and every mesh under it (the blade's
	# own apart) must be off every render layer. A loop over the pin's
	# descendants alone hid nothing, and the bucket's floor hung out below the
	# blade in every frame (2026-09-15). Own flags, not `is_visible_in_tree`: the
	# machine is off-stage and hidden as a whole here.
	var bucket_drawn := 0
	var blade_drawn := 0
	var pin: Node3D = skid0.node_for("Bucket") if skid0 != null else null
	if pin != null:
		var pin_meshes: Array[Node] = [pin]
		pin_meshes.append_array(pin.find_children("*", "MeshInstance3D", true, false))
		for n in pin_meshes:
			if not (n is MeshInstance3D):
				continue
			var mi := n as MeshInstance3D
			var under_blade := false
			var at: Node = mi
			while at != null and at != pin:
				if String(at.name) == "PushBlade":
					under_blade = true
					break
				at = at.get_parent()
			var drawn := mi.layers != 0 and mi.visible
			if under_blade:
				blade_drawn += 1 if drawn else 0
			elif drawn:
				bucket_drawn += 1
	_check(pin != null and bucket_drawn == 0 and blade_drawn > 0,
		"and the bucket's own mesh is off the render layers under the blade (%d bucket meshes drawn, %d blade)" % [bucket_drawn, blade_drawn])
	_check(drive.fill_fraction() < 0.001, "and no concrete in it yet (%.3f)" % drive.fill_fraction())
	# The fault has to be visible BEFORE the first tap, as shape and not as tint -
	# and a crack has to be a crack, which means it is not a straight line.
	var damage := 0
	var straight := 0
	for i in range(1, drive.panel_count() + 1):
		var node := drive.panel_marker(i).get_parent()
		var angles: Dictionary = {}
		for child in node.get_children():
			var n := String(child.name)
			if n.begins_with("OldCrack") or n.begins_with("Stain"):
				damage += 1
			if n.begins_with("OldCrack"):
				angles[snappedf((child as Node3D).rotation.y, 0.01)] = true
		# A zigzag's segments point in several directions; one straight box points
		# in exactly one.
		if angles.size() < 3:
			straight += 1
	_check(damage >= drive.panel_count() * 3,
		"every panel arrives already cracked and stained (%d pieces of damage)" % damage)
	_check(straight == 0, "and every crack on it ZIGZAGS (%d panels with a straight one)" % straight)
	# The fault has a SHAPE from the wide (the improvement plan's 4.1): weeds in
	# the old cracks, measured in the opening WIDE's own pixels - and none of them
	# under a lit ring AS THE WIDE DRAWS IT, a billboard's gold band in pixels
	# round the ring's point at its largest pulse (a tuft 0.3 m past a spot on the
	# ground was under the gold: the session-4 verification pass) - and the first
	# slab settled a step below its neighbour.
	var fr0 := main.camera.get_viewport().get_visible_rect().size
	var cam0 := main.camera
	var bands: Array[Vector3] = []
	for rp in rings.points():
		var fit := clampf(cam0.global_position.distance_to(rp) / SpotRings.NOMINAL_M, 0.5, 3.0)
		var size_m: float = main.config.ring_spot * fit
		var c := cam0.unproject_position(rp)
		var right := cam0.global_transform.basis.x
		var r_in := c.distance_to(cam0.unproject_position(rp + right * 0.56 * 0.5 * size_m * 0.87))
		var r_out := c.distance_to(cam0.unproject_position(rp + right * 0.90 * 0.5 * size_m * 1.13))
		bands.append(Vector3(c.x, c.y, 0.0))
		bands.append(Vector3(r_in, r_out, 0.0))
	var few := 0
	var shortest := INF
	var under_gold := 0
	for i in range(1, drive.panel_count() + 1):
		var tufts := drive.panel_weeds(i)
		if tufts.size() < 3:
			few += 1
		for tuft in tufts:
			var tip_l: Vector3 = tuft.get_meta("tip", Vector3.UP * 0.14)
			var tip_w := tuft.global_transform * tip_l
			shortest = minf(shortest, _px_rows(tuft.global_position, tip_w) * 720.0 / fr0.y)
			for bi in range(0, bands.size(), 2):
				var centre := Vector2(bands[bi].x, bands[bi].y)
				for p_w: Vector3 in [tuft.global_position, tip_w]:
					var d := cam0.unproject_position(p_w).distance_to(centre)
					if d >= bands[bi + 1].x and d <= bands[bi + 1].y:
						under_gold += 1
	_check(few == 0 and shortest >= 6.0 and under_gold == 0 and bands.size() == 6,
		"every slab has weeds in its cracks, the shortest %.1f px tall on the wide, none under a lit ring's gold (%d thin slabs, %d under)"
		% [shortest, few, under_gold])
	var step0 := drive.panel_top_at(2, Vector2(-0.5, 0.0)) - drive.panel_top_at(1, Vector2(0.5, 0.0))
	var settled_spots := 0
	for s in range(1, Driveway.SPOTS_PER_PANEL + 1):
		if drive.spot_marker(s).global_position.y < -0.005:
			settled_spots += 1
	_check(step0 >= 0.045 and settled_spots == Driveway.SPOTS_PER_PANEL,
		"the first slab has settled a step below its neighbour at the seam (%.3f m), all its spots on the settled slab"
		% step0)
	# The spots the hammer works are three DIFFERENT places, not one spot thrice.
	var spread := 0.0
	for sp in range(1, 4):
		var a := drive.spot_marker(sp)
		for sq in range(sp + 1, 4):
			spread = maxf(spread, a.global_position.distance_to(drive.spot_marker(sq).global_position))
	_check(spread > 0.7, "the three spots on a panel are a tap apart (%.2f m)" % spread)
	# The white idle arrow (fourth playtest): nothing for a while and it stands
	# over the first ring, white, miming a tap; the first touch takes it away.
	var delay_was: float = hud.hint_delay
	hud.hint_delay = 0.3
	# Real seconds, not frames: the idle clock is wall time and a headless
	# frame is a fraction of a millisecond.
	await get_tree().create_timer(0.7).timeout
	_check(hud.hint_visible(), "after a pause the white idle arrow is up")
	var hp := hud.hint_position()
	var fr := main.camera.get_viewport().get_visible_rect().size
	_check(hp != Vector2.INF and hp.x > 0.0 and hp.y > 0.0 and hp.x < fr.x and hp.y < fr.y,
		"inside the picture (%s)" % str(hp))
	var hc := hud.hint_color_now()
	_check(hc.r > 0.95 and hc.g > 0.95 and hc.b > 0.95, "and it is WHITE")
	_check(hud.hint_kind() == SiteHud.Hint.TAP, "miming a tap")
	_check(rings.count() == 3, "with all three rings still up under it (%d)" % rings.count())
	var tip0 := hud.hint_tip_now()
	await get_tree().create_timer(0.4).timeout
	_check(hud.hint_tip_now().distance_to(tip0) > 3.0, "and it moves")
	# A MISS does not take it away: the child who taps the wrong thing is the
	# one it is for (the improvement plan's 1.2). An accepted tap does - that is
	# checked on the first bite, in the jackhammer phase.
	main._press(Vector2(fr.x * 0.5, fr.y * 0.98), true)
	main._press(Vector2(fr.x * 0.5, fr.y * 0.98), false)
	_check(hud.hint_visible(), "a miss leaves it up - it is still needed")
	hud.hint_wake()
	# And forget that miss: the jackhammer phase counts its own two, and this
	# one would make its first the second.
	hud._last_miss_s = -100.0
	hud.hint_delay = delay_was
	# The first touch ends the opening look: the eye comes down to the slab.
	_check(main.rig.current_shot() == CameraRig.PANEL and main.rig.is_moving(),
		"and the first touch sends the eye down to the first slab (3.1)")
	# The places to tap are MARKED, and there are three of them on the first slab.
	_check(rings != null and rings.count() == 3,
		"three gold rings are lit on the first slab (%d)" % (rings.count() if rings != null else -1))
	_check(main.rings_up() and not hud.arrow_visible(),
		"and the gold arrow stands down while they are")
	# The garage is a building with a hole in it, and the hole is shut.
	_check(main.garage_door_k() < 0.01, "the garage door starts shut (%.2f)" % main.garage_door_k())
	_check(main.get_node_or_null("GarageLintel") != null, "the garage has a real opening in it")
	# The three machines are off-stage and whole.
	for kind: String in ["SkidSteer", "DumpTruck", "ConcreteTruck"]:
		var m := main.machine(kind)
		_check(m != null and m.missing_nodes.is_empty(),
			"%s has every node its contract names (%s)" % [kind, _list(m.missing_nodes) if m != null else "no machine"])
		_check(m != null and not m.visible, "%s waits off-stage until it is called" % kind)
	_check(runner.current_step().verb == "jack_spot", "and the job opens on the jackhammer")
	# The app opens on the title row now (6.3), and a main scene that will not
	# instantiate is otherwise a launch that hangs with one line in the log.
	var title_packed: PackedScene = load("res://scenes/main.tscn")
	var title_root: Node = title_packed.instantiate() if title_packed != null else null
	_check(title_root is TitleMain and ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/main.tscn",
		"the app's main scene is the title row, and it builds")
	if title_root != null:
		title_root.free()
	await _the_visit()


# --- The visit: what this lot looks like, and what it never changes (6.1) ------------------------

func _the_visit() -> void:
	print("--- the visit ---")
	# A harness that names no seed gets the legacy lot, read off the WORLD: the
	# crack the code drew before there was a seed, the garage's own cream, the
	# house in its imported paint.
	_check(main.play_seed == SiteLook.LEGACY_SEED and main.seed_from == "harness",
		"a harness with no seed plays the legacy lot (seed %d from %s)" % [main.play_seed, main.seed_from])
	_check(drive.crack_base == 917 and _old_crack(main).distance_to(LEGACY_CRACK) < 0.0001,
		"its first old crack is the one drawn before the seed existed (%s)" % str(_old_crack(main)))
	_check(_garage_wall(main).is_equal_approx(Color(0.88, 0.86, 0.80)) and _house_overrides(main) == 0,
		"the cream garage and the house in its own paint (%s, %d overrides)" % [str(_garage_wall(main)), _house_overrides(main)])
	_check(main.car_voice() == "voice_hatchback" and String(main.look["car"]) == "Hatchback",
		"and the red hatchback's voice (%s)" % main.car_voice())
	_first_look = main.look.duplicate()
	# A COPY: `points()` hands back the rings' own array, which the next re-arm
	# rewrites under this reference.
	_first_rings = rings.points().duplicate()
	# Nothing on disk until the child has done something (6.2).
	_check(not SaveGame.exists(), "no save is written before the first beat")
	# The look table itself.
	var in_range := 0
	var repeats := 0
	for n in range(20):
		var sd := SiteLook.draw_fresh(_first_look)
		if sd >= 1 and sd <= SiteLook.SEED_MAX:
			in_range += 1
		if not SiteLook.differs(SiteLook.for_seed(sd), _first_look):
			repeats += 1
	_check(in_range == 20 and repeats == 0,
		"a fresh visit is a seed of 1..%d with a different car, house and cracks from the last (%d in range, %d repeats)"
		% [SiteLook.SEED_MAX, in_range, repeats])
	var colour_bad := 0
	var cap_h := Color(0.95, 0.35, 0.62).h
	for sw: Array in SiteLook.HOUSE_SWATCHES:
		for c: Color in sw:
			if c.a > 0.0 and (_hue_step(c.h, cap_h) < 0.12 and c.s > 0.12):
				colour_bad += 1
	for row: Dictionary in SiteLook.HOME_CARS:
		for c: Color in row["paints"]:
			if _hue_step(c.h, cap_h) < 0.08 and c.s > 0.3:
				colour_bad += 1
	_check(colour_bad == 0, "no house, garage or car swatch is the stake caps' pink (%d)" % colour_bad)
	await _every_crack_base()
	await _every_home_car()


## Every crack base a visit can draw builds an old drive that passes what the
## legacy one is held to above: four panels, every old crack a zigzag, three
## weeds a slab at least, none under the first slab's lit gold, the shortest
## six pixels tall on the WIDE - and its spots exactly where the legacy drive's
## are (the rings never move with the look).
func _every_crack_base() -> void:
	var cam := main.camera
	var bands: Array[Vector3] = []
	for rp in rings.points():
		var fit := clampf(cam.global_position.distance_to(rp) / SpotRings.NOMINAL_M, 0.5, 3.0)
		var size_m: float = main.config.ring_spot * fit
		var c := cam.unproject_position(rp)
		var right := cam.global_transform.basis.x
		bands.append(Vector3(c.x, c.y, 0.0))
		bands.append(Vector3(c.distance_to(cam.unproject_position(rp + right * 0.56 * 0.5 * size_m * 0.87)),
			c.distance_to(cam.unproject_position(rp + right * 0.90 * 0.5 * size_m * 1.13)), 0.0))
	var bad: Array[String] = []
	var fr := cam.get_viewport().get_visible_rect().size
	for base: int in SiteLook.CRACK_BASES:
		var d := Driveway.new()
		d.name = "VetDrive"
		d.crack_base = base
		d.setup(main.config)
		main.add_child(d)
		d.global_transform = drive.global_transform
		d.replant_first_weeds(main.rig.shot_eye(CameraRig.WIDE), main.rig.shot_look(CameraRig.WIDE), main.config.ring_spot)
		var why := ""
		if d.panel_count() != 4:
			why += " panels"
		var shortest := INF
		for i in range(1, d.panel_count() + 1):
			var tufts := d.panel_weeds(i)
			if tufts.size() < 3:
				why += " weeds%d=%d" % [i, tufts.size()]
			var angles := {}
			for child in d.panel_marker(i).get_parent().get_children():
				if String(child.name).begins_with("OldCrack"):
					angles[snappedf((child as Node3D).rotation.y, 0.01)] = true
			if angles.size() < 3:
				why += " straight%d" % i
			for tuft in tufts:
				var tip_w := tuft.global_transform * (tuft.get_meta("tip", Vector3.UP * 0.14) as Vector3)
				shortest = minf(shortest, _px_rows(tuft.global_position, tip_w) * 720.0 / fr.y)
				for bi in range(0, bands.size(), 2):
					for p_w: Vector3 in [tuft.global_position, tip_w]:
						var dd := cam.unproject_position(p_w).distance_to(Vector2(bands[bi].x, bands[bi].y))
						if dd >= bands[bi + 1].x and dd <= bands[bi + 1].y:
							why += " gold%d" % i
		if shortest < 6.0:
			why += " short%.1f" % shortest
		for n in range(1, 13):
			if d.spot_marker(n).global_position.distance_to(drive.spot_marker(n).global_position) > 0.0005:
				why += " spot%d" % n
				break
		if why != "":
			bad.append("%d:%s" % [base, why])
		d.free()
	_check(bad.is_empty(), "every crack base a visit can draw is a good old drive with the spots where they always are (%s)"
		% ("all %d" % SiteLook.CRACK_BASES.size() if bad.is_empty() else ", ".join(bad)))


## Every homeowner's car loads whole, parks by its nose between the garage and
## the kerb inside the drive's width, has its voice on disk, and is paintable
## exactly when its row has paints. Measured off the GLBs, not the table.
func _every_home_car() -> void:
	var bad: Array[String] = []
	for row: Dictionary in SiteLook.HOME_CARS:
		var name := String(row["name"])
		var c := Machine.new()
		c.kind = "Car"
		c.model_path = SiteMain.VEHICLE_MODELS + name + ".glb"
		main.add_child(c)
		c.setup(main.config)
		c.centre_model_x()
		var why := ""
		if not c.model_loaded or c.node_for("WheelFL") == null or c.node_for("WheelRR") == null:
			why += " model"
		c.place(drive.park_spot(c.nose_m()), 180.0)
		var box: AABB = main._world_box(c)
		if box.position.z < Driveway.Z_APRON + 0.30 or box.end.z > Driveway.Z_KERB - 0.5:
			why += " z %.2f..%.2f" % [box.position.z, box.end.z]
		if box.position.x < Driveway.CENTRE_X - Driveway.WIDTH * 0.5 or box.end.x > Driveway.CENTRE_X + Driveway.WIDTH * 0.5:
			why += " x %.2f..%.2f" % [box.position.x, box.end.x]
		if main.sfx.loaded_count(String(row["voice"])) < 1:
			why += " voice"
		var paint_surfaces := 0
		for mi: MeshInstance3D in c.find_children("*", "MeshInstance3D", true, false):
			for si in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
				var mat := mi.get_active_material(si)
				if mat != null and String(mat.resource_name).begins_with("Equip_Paint"):
					paint_surfaces += 1
		if (paint_surfaces > 0) != not (row["paints"] as Array).is_empty():
			why += " paint %d" % paint_surfaces
		# A livery's `body` is a colour its model really wears.
		if row.has("body"):
			var worn := false
			for mi: MeshInstance3D in c.find_children("*", "MeshInstance3D", true, false):
				for si in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
					var bm := mi.get_active_material(si) as BaseMaterial3D
					if bm != null and _colour_step(bm.albedo_color, row["body"]) < 0.02:
						worn = true
			if not worn:
				why += " body"
		if why != "":
			bad.append(name + ":" + why)
		c.free()
	_check(bad.is_empty(), "every homeowner's car loads, parks nose-in between the garage and the kerb, and has its voice (%s)"
		% ("all %d" % SiteLook.HOME_CARS.size() if bad.is_empty() else ", ".join(bad)))
	# No visit parks a car in front of a garage it disappears against - the cream
	# the Van's cream paint was dropped for, and the white liveries too - by this
	# test's own measure (a luma step or a colour distance), over three thousand
	# seeds.
	var lost: Array[String] = []
	for sd in range(1, 3001):
		var lk := SiteLook.for_seed(sd)
		var row2 := SiteLook.car_row(String(lk["car"]))
		var body: Color = lk["paint"] if Color(lk["paint"]).a > 0.0 else Color(row2.get("body", Color(0, 0, 0, 0)))
		var wall: Color = lk["garage_wall"]
		var luma_step := absf((0.2126 * body.r + 0.7152 * body.g + 0.0722 * body.b) - (0.2126 * wall.r + 0.7152 * wall.g + 0.0722 * wall.b))
		if body.a <= 0.0 or (luma_step < 0.1 and _colour_step(body, wall) < 0.25):
			if lost.size() < 5:
				lost.append("%d %s on %d" % [sd, String(lk["car"]), int(lk["house_swatch"])])
			else:
				lost.append(".")
	_check(lost.is_empty(), "no visit parks a car in front of a garage it disappears against (%s)" % ("none of 3000" if lost.is_empty() else str(lost.size()) + ": " + ", ".join(lost.slice(0, 5))))


func _colour_step(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _old_crack(m: SiteMain) -> Vector3:
	var oc := m.drive.panel_marker(1).get_parent().get_node_or_null("OldCrack_1_1") as Node3D
	return oc.position if oc != null else Vector3.INF


func _garage_wall(m: SiteMain) -> Color:
	var g := m.get_node_or_null("GarageWall") as MeshInstance3D
	if g == null or not (g.mesh is BoxMesh):
		return Color(0, 0, 0, 0)
	return ((g.mesh as BoxMesh).material as StandardMaterial3D).albedo_color


## The house's `Equip_Trim` surfaces: how many carry an override in the visit's
## swatch colour, and how many imported ones were written into.
func _house_paint(m: SiteMain) -> Vector2i:
	var right := 0
	var leaked := 0
	var want: Color = m.look["house"]
	var house := m.get_node_or_null("House")
	if house == null:
		return Vector2i(-1, -1)
	for mi: MeshInstance3D in house.find_children("*", "MeshInstance3D", true, false):
		for si in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
			var own := mi.mesh.surface_get_material(si) as BaseMaterial3D
			if own == null or not String(own.resource_name).begins_with("Equip_Trim"):
				continue
			var ov := mi.get_surface_override_material(si) as BaseMaterial3D
			if ov != null and want.a > 0.0 and ov.albedo_color.is_equal_approx(want):
				right += 1
			if _colour_step(own.albedo_color, Color(0.96, 0.95, 0.92)) > 0.005:
				leaked += 1
	return Vector2i(right, leaked)


func _house_overrides(m: SiteMain) -> int:
	var n := 0
	var house := m.get_node_or_null("House")
	if house == null:
		return -1
	for mi: MeshInstance3D in house.find_children("*", "MeshInstance3D", true, false):
		for si in range(mi.get_surface_override_material_count()):
			if mi.get_surface_override_material(si) != null:
				n += 1
	return n


func _hue_step(a: float, b: float) -> float:
	var d := absf(a - b)
	return minf(d, 1.0 - d)


## The save on disk names this row and these places, and nothing else.
func _save_is(verb: String, nth: int, done: int, places: Array, when: String) -> void:
	var d := SaveGame.load_data()
	var got: Array = []
	for v in d.get("places", []):
		got.append(int(v))
	got.sort()
	var keys := d.keys()
	keys.sort()
	_check(String(d.get("verb", "")) == verb and int(d.get("nth", 0)) == nth and int(d.get("done", -1)) == done \
		and got == places and int(d.get("seed", -1)) == main.play_seed \
		and keys == ["done", "job", "nth", "places", "rows", "seed", "verb", "version"],
		"%s the save says %s:%d done %d at %s, on seed %d (%s)" % [when, verb, nth, done, str(places), main.play_seed, str(d)])


# --- Phase 1: break the old drive out ---------------------------------------------------------

func _phase_jackhammer() -> void:
	print("--- 1. the jackhammer ---")
	# A tap MILES from the spot must not do the work (DESIGN 0, the tap rule).
	var before := runner.progress
	var away := Vector2(20.0, 20.0)
	_check(not main.tap_counts(away), "a tap in the corner of the screen does not count")
	main._press(away, true)
	main._press(away, false)
	await _frames(4)
	_check(runner.progress == before, "so nothing happened (%d)" % runner.progress)
	_check(hud.arrow_nudged(), "and the arrow bounced to say where to go")
	# A miss is HEARD, quietly, and answered by the nearest ring throbbing
	# once; and two misses inside three seconds bring the white mime at once
	# (the improvement plan's 1.2).
	_check(main.sfx.last_played == "pop", "and the miss was heard, quietly (%s)" % main.sfx.last_played)
	_check(rings.nudging(), "and the nearest ring throbbed")
	_check(not hud.hint_visible(), "the white mime is not up yet")
	await get_tree().create_timer(0.5).timeout
	main._press(away, true)
	main._press(away, false)
	await get_tree().create_timer(0.3).timeout
	_check(hud.hint_visible(), "a second miss half a second later brings the white mime at once")
	_check(runner.waiting_for_tap(), "the hammer is TAPPED, not held")
	# The three rings on a slab are three DIFFERENT places, and they may be taken
	# in any order the child likes: the first slab is worked middle, last, first.
	var lit := rings.points()
	var spread := 0.0
	for a in range(lit.size()):
		for b in range(a + 1, lit.size()):
			spread = maxf(spread, lit[a].distance_to(lit[b]))
	_check(spread > 0.7, "the three rings are a tap apart (%.2f m)" % spread)
	var order := [2, 3, 1]
	for step in range(3):
		var id: int = order[step]
		_check(_tap_ring(id), "ring %d can be pressed (out of order)" % id)
		if step == 0:
			# The tap is heard in the frame it lands (the plan's 1.1), it takes
			# the white mime away, and the ring it chose snaps out while the
			# other two stay lit (1.3).
			_check(main.sfx.last_played == "whoosh",
				"the tap is heard in the frame it lands (%s)" % main.sfx.last_played)
			_check(not hud.hint_visible(), "and an accepted tap takes the white mime away at once")
			await _frames(30)
			_check(rings.count() == 3 and rings.visible_count() == 2,
				"the ring pressed snapped out and the other two stay lit (%d drawn of %d)"
				% [rings.visible_count(), rings.count()])
			# And the HUD steps back while the bite runs (the plan's 3.7): real
			# seconds, since the ease is wall-clock.
			await get_tree().create_timer(0.25).timeout
			_check(hud.chrome_alpha() < 0.6, "the bar steps back while the bite runs (%.2f)" % hud.chrome_alpha())
		if step == 2:
			# The third bite: the slab lets go with a HOP, not in a cut (1.5).
			await _until(func() -> bool: return drive.panels_broken() == 1, "the slab to let go")
			var chunk := drive._chunks[0] as Node3D
			var y0 := chunk.global_position.y
			await get_tree().create_timer(main.config.chunk_hop_time + 0.15).timeout
			_check(y0 - chunk.global_position.y >= 0.08,
				"the rubble hopped and settled (%.2f m)" % (y0 - chunk.global_position.y))
			var weeds_left := 0
			for w in drive.panel_weeds(1):
				if w.is_visible_in_tree():
					weeds_left += 1
			_check(weeds_left == 0, "and its weeds went with it (%d still drawn)" % weeds_left)
		await _until(func() -> bool: return not runner.is_busy(), "bite on ring %d" % id)
		_check(drive.spot_done(id), "and spot %d is the one that got worked" % id)
		if step == 0:
			_save_is("jack_spot", 1, 1, [2], "after the first bite (ring 2)")
			# The bite sinks the settled slab FROM its step, never back up to
			# level first (4.1).
			var step1 := drive.panel_top_at(2, Vector2(-0.5, 0.0)) - drive.panel_top_at(1, Vector2(0.5, 0.0))
			_check(step1 >= Driveway.SETTLE_STEP + main.config.panel_sink / 3.0 - 0.005,
				"and a bite sinks the settled slab further, from its step (%.3f m)" % step1)
			await get_tree().create_timer(0.35).timeout
			_check(hud.chrome_alpha() > 0.9, "and the bar comes back between beats (%.2f)" % hud.chrome_alpha())
		var want := 3 - (step + 1)
		if step < 2:
			_check(rings.count() == want,
				"%d ring(s) left on the slab (%d)" % [want, rings.count()])
	_check(drive.panels_broken() == 1,
		"the slab let go on its third bite, whichever order they came in (%d)" % drive.panels_broken())
	# A tap that lands while a bite is running is KEPT, and it keeps the RING it
	# landed on (the improvement plan's 0.4): press the second slab's first ring,
	# then its LAST while the hammer is still going, and the hammer must walk to
	# that last one - not to the first open spot, which is the middle one.
	await _until(func() -> bool:
		return runner.waiting_for_tap() and not runner.is_busy() and rings.count() == 3,
		"the second slab's rings")
	var first := rings.id_at(0)
	var middle := rings.id_at(1)
	var last := rings.id_at(2)
	_check(_tap_ring(first), "the second slab's first ring can be pressed")
	await _frames(2)
	_check(runner.is_busy(), "the hammer is going")
	_check(_tap_ring(last), "and its last ring is pressed while it goes")
	await _until(func() -> bool: return not runner.is_busy() and drive.spot_done(first), "both bites")
	_check(drive.spot_done(last), "the kept tap worked the ring it landed on (spot %d)" % last)
	_check(not drive.spot_done(middle), "and not the first open spot (spot %d is still to do)" % middle)
	_check(rings.count() == 1, "one ring left on that slab (%d)" % rings.count())
	# The rest of them, nearest ring first, which is what a child mostly does.
	#
	# And the CAMERA WALKS WITH THEM (DESIGN 1a, 2026-09-12: "when you jackhammer
	# the first section or 2 it then moves to the background to slabs that are
	# further away the camera needs to move with it"). Eighteen bites are one
	# step, and a step's shot used to be chosen once when the step was entered -
	# so the eye stayed on the first panel for the whole phase. What is asked
	# here is that the eye is in a different place for every panel, and that it
	# is never further from the panel being worked than the first one was.
	await _settled()
	var eyes: Array[Vector3] = [main.camera.global_position]
	var panel_at := drive.panels_broken()
	var reach := main.camera.global_position.distance_to(
		drive.panel_marker(drive.spot_panel(runner.done_in_step + 1)).global_position)
	var worst := reach
	var bites := 5
	var wedge_done := false
	while drive.panels_broken() < drive.panel_count() and bites < 30:
		if not await _until(func() -> bool:
				return runner.waiting_for_tap() and not runner.is_busy() and rings.count() > 0,
				"the next ring"):
			break
		if not _tap_ring(rings.id_at(0)):
			break
		await _until(func() -> bool: return not runner.is_busy(), "bite %d" % (bites + 1))
		bites += 1
		if drive.panels_broken() != panel_at and drive.panels_broken() < drive.panel_count():
			panel_at = drive.panels_broken()
			await _settled()
			eyes.append(main.camera.global_position)
			var mark := drive.panel_marker(drive.spot_panel(runner.done_in_step + 1))
			if mark != null:
				worst = maxf(worst, main.camera.global_position.distance_to(mark.global_position))
			if drive.panels_broken() == 2 and not wedge_done:
				wedge_done = true
				await _the_wedge()
				bites += 1
	var stood := 0
	for i in range(1, eyes.size()):
		if eyes[i].distance_to(eyes[i - 1]) < 0.5:
			stood += 1
	_check(eyes.size() >= drive.panel_count() - 1 and stood == 0,
		"the eye moved to every panel as it came up (%d pictures, %d of them the same place)"
		% [eyes.size(), stood])
	_check(worst < reach + 0.6,
		"and never stood further off than it did on the first (%.1f m, first %.1f m)" % [worst, reach])
	_check(drive.panels_broken() == 4, "all four panels came apart (%d)" % drive.panels_broken())
	_check(bites == 12, "in twelve bites, three a slab (%d)" % bites)
	_check(drive.chunks_left() >= 40, "and it left rubble lying in the hole (%d chunks)" % drive.chunks_left())
	var moved := await _until(func() -> bool: return runner.waiting_button() == "call",
		"the job to reach the skid steer")
	_check(moved, "the job moved on to calling the skid steer")


# --- Phase 2: the skid steer --------------------------------------------------------------------

func _phase_push() -> void:
	print("--- 2. the skid steer ---")
	_check(runner.waiting_button() == "call", "the green button is the answer now")
	_check(hud.call_is_modelled(), "the call button shows the machine itself, low-poly, not a drawn glyph")
	_check(hud.button_enabled("call"), "and it is awake")
	await get_tree().create_timer(0.9).timeout
	_check(hud.aim_visible(), "and the ring is on the button once the last bite's mute lapses")
	var skid := main.machine("SkidSteer")
	# While it crawls up the drive it is crossing broken concrete, so it has to
	# ride OVER the lumps. "It looks like the skid steer goes through the rocks."
	var rode := [false]
	var sank := [0]
	# A one-element Array, not a bool: a lambda captures a local BY VALUE, so a
	# plain flag flipped below never reached the loop and it ran for the rest of
	# the test - and on into a freed site once the second driveway was built.
	var watching := [true]
	var watch := func() -> void:
		while watching[0]:
			if skid.visible and not skid.is_driving():
				pass
			if skid.visible:
				var floor_y := drive.stand_y(skid.global_position)
				var ride := drive.ride_y(skid.global_position)
				if ride > floor_y + 0.03 and skid.global_position.y > floor_y + 0.015:
					rode[0] = true
				# Through the FLOOR is a fault; below the floor at its own origin is
				# not. A machine is seated at its nose AND its tail, so one tipping
				# down into the excavation legitimately has its middle below the
				# garage slab its back wheels are still on - and one with its nose up
				# on a lump sits above the dirt its tail is on. The honest question is
				# whether any part of it is under the ground.
				var nose := drive.stand_y(skid.to_global(Vector3(0.0, 0.0, 1.4)))
				var tail := drive.stand_y(skid.to_global(Vector3(0.0, 0.0, -1.4)))
				if skid.global_position.y < minf(nose, tail) - 0.05:
					sank[0] += 1
			await get_tree().process_frame
	watch.call()
	hud.simulate_button("call")
	var came := await _until(func() -> bool:
		return skid.visible and not skid.is_driving(), "the skid steer arrives")
	_check(came, "the skid steer drove on when the button was pressed")
	_check(main.garage_door_k() > 0.9,
		"the garage door rolled up for it (%.2f)" % main.garage_door_k())
	_check(skid.global_position.z < Driveway.Z_APRON - 0.5,
		"and it is standing INSIDE the garage, lined up on the drive (z %.2f)" % skid.global_position.z)
	_check(absf(rad_to_deg(skid.rotation.y)) < 6.0,
		"facing back down it (%.0f deg)" % rad_to_deg(skid.rotation.y))
	# Its beacon turned on the way in and is dark now it has parked (the
	# improvement plan's 4.5).
	_check(not skid.beacon_on() and skid.beacon_level() < 0.01,
		"its beacon is dark once it has parked (%.2f)" % skid.beacon_level())
	# The pads are NOT the control any more: this is a finger on the picture.
	_check(not hud.pad_visible("up"), "the push is press-and-hold, so no pad is up for it")
	_check(runner.waiting_for_hold(), "and the runner is waiting to be held")
	var rolled := skid.rolled_m()
	runner.hold(true)
	# The engine LEANS INTO THE WORK under the finger and comes back up when
	# it lifts (the improvement plan's 1.7): read off the loop itself. And the
	# beacon FLASHES while it works (4.5): lit and dark, not a steady glow.
	var lit_hi := 0.0
	var lit_lo := 1.0
	var lit_t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - lit_t < 1600:
		lit_hi = maxf(lit_hi, skid.beacon_level())
		lit_lo = minf(lit_lo, skid.beacon_level())
		await get_tree().process_frame
	_check(skid.beacon_on() and lit_hi > 0.9 and lit_lo < 0.1,
		"its beacon flashes while it pushes (%.2f to %.2f)" % [lit_lo, lit_hi])
	var rep: Dictionary = main.sfx.loop_report()
	_check(rep.has("skid") and float(rep["skid"]["pitch"]) < 0.99,
		"the skid steer's engine drops a note under the finger (pitch %.2f)"
		% (float(rep["skid"]["pitch"]) if rep.has("skid") else -1.0))
	runner.hold(false)
	await get_tree().create_timer(1.0).timeout
	rep = main.sfx.loop_report()
	_check(rep.has("skid") and float(rep["skid"]["pitch"]) > 0.995,
		"and comes back up when the finger lifts (pitch %.2f)"
		% (float(rep["skid"]["pitch"]) if rep.has("skid") else -1.0))
	runner.hold(true)
	await _until(func() -> bool: return runner.done_in_step >= 1 or runner.current_step().verb != "push_rubble",
		"the first pass")
	_save_is("push_rubble", 1, 1, [], "after the first pass")
	var cleared := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb != "push_rubble", "two passes")
	runner.hold(false)
	watching[0] = false
	_check(cleared, "two passes cleared the pad")
	_push_ended_ms = Time.get_ticks_msec()
	_check(skid.edge_width() > 1.9, "with a blade wider than the lane it pushes (%.2f m)" % skid.edge_width())
	_check(drive.chunks_on_pad() == 0, "and no rubble is left on it (%d)" % drive.chunks_on_pad())
	_check(rode[0], "it climbed over the broken concrete rather than through it")
	_check(sank[0] == 0, "and never sank through the ground (%d frames under it)" % sank[0])
	_check(absf(skid.rolled_m() - rolled) > 8.0,
		"the wheels turned the distance it covered (%.1f m)" % absf(skid.rolled_m() - rolled))


# --- Phases 3 and 4: the forms ------------------------------------------------------------------

func _phase_forms() -> void:
	print("--- 3. the forms ---")
	var went := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "form_set", "the forms step")
	_check(went, "the skid steer left and the boards are next")
	# The exit is a two-second look, not a beat (the plan's 3.2): the boards'
	# rings are live within seconds of the second push, while the skid steer
	# is still trundling off up the street in the background.
	var since_push := float(Time.get_ticks_msec() - _push_ended_ms) / 1000.0
	_check(since_push < 4.0, "and they are live %.1f s after the second push ended" % since_push)
	var skid_out := main.machine("SkidSteer")
	_check(skid_out != null and skid_out.visible and skid_out.is_driving() and skid_out.beacon_on(),
		"while the skid steer is still on its way out in the background, beacon turning")
	# And it goes down the VERGE, never back through the mouth of the hole it
	# cleared (the session-3 verification pass): watched every frame until gone.
	var dipped := 0
	while skid_out != null and skid_out.visible and skid_out.is_driving():
		var sp := skid_out.global_position
		var over_pad := absf(sp.x - Driveway.CENTRE_X) < Driveway.WIDTH * 0.5 + 0.2 \
			and sp.z > Driveway.Z_APRON - 0.5 and sp.z < Driveway.Z_KERB + 0.3
		if over_pad and sp.y < -0.02:
			dipped += 1
		await get_tree().process_frame
	_check(dipped == 0, "and never dips into the excavation on its way (%d frames over the pad below grade)" % dipped)
	_check(skid_out != null and not skid_out.visible and not main.sfx.is_looping("leave") \
		and not skid_out.beacon_on(),
		"and is gone, its idle stopped and its beacon off, before the boards are done")
	# The house button is OFF the screen while the job runs (the improvement
	# plan's 0.1): one tap on it reloaded the whole site, and nothing said so.
	_check(not hud.home_visible(), "the house button is off the screen while the job runs")
	var idx := runner.index
	var boards := drive.forms_in()
	var prog := runner.progress
	hud.simulate_home()
	await _frames(3)
	_check(runner.index == idx and drive.forms_in() == boards and runner.progress == prog,
		"and its signal mid-job throws nothing away (step %d, %d boards, %d stops)"
		% [runner.index, drive.forms_in(), runner.progress])
	# The boards are set in GROUPS (round 4): the two long boards first, both
	# marked, in whichever order; then the strip. The kerb board is NOT on site:
	# the trucks back in through that end, so it goes in after the base (5.2).
	_check(rings.count() == 2, "two rings, one on each long board's place (%d)" % rings.count())
	_check(drive.form_shown(1) and drive.form_shown(2) and drive.form_shown(4) \
		and drive.form_k(1) < 0.01 and drive.form_k(2) < 0.01,
		"the boards wait in the air over their places BEFORE the first tap, not after it")
	_check(not drive.form_shown(Driveway.KERB_BOARD), "and the kerb board is not on site yet")
	await _settled()
	_check(_all_rings_on_screen(), "and every one of them is inside the frame")
	var seen_f: Array[Vector3] = []
	var set_n := 0
	while drive.forms_in() < 3 and set_n < 8 and runner.current_step().verb == "form_set":
		if not await _until(func() -> bool: return runner.waiting_for_tap() and not runner.is_busy(),
				"the next board"):
			break
		var g := drive.current_form_group()
		var open := drive.open_forms_in(g)
		if open.is_empty():
			break
		var i: int = open[open.size() - 1]
		_check(_tap_ring(i), "board %d's ring can be pressed" % i)
		await _until(func() -> bool: return not runner.is_busy(), "board %d lands" % i)
		_check(drive.form_is_in(i), "and board %d is the one that went in" % i)
		set_n += 1
		if drive.current_form_group() != g and drive.forms_in() < 3:
			await _settled()
			seen_f.append(main.camera.global_position)
			_check(_all_rings_on_screen(), "the next group's rings are inside the frame")
	_check(drive.forms_in() == 3 and not drive.form_is_in(Driveway.KERB_BOARD),
		"the long boards and the strip are in, the kerb end left open (%d)" % drive.forms_in())
	_check(seen_f.size() >= 1, "and the eye moved to the strip (%d moves)" % seen_f.size())
	print("--- 4. the stakes ---")
	var on_stakes := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "stake_drive", "the stakes step")
	_check(on_stakes, "the boards handed over to the stakes")
	_check(runner.current_step().shot == "STAKE", "the stakes have their own shot")
	_check(runner.waiting_for_tap(), "and ONE TAP is one stake")
	# A PAIR at a time, close (DESIGN 1a, 2026-09-12: "the stakes are a wide shot
	# so you don't get the hammer feeling"). Ten rings in one picture could only
	# be held from up on the roof, where a 5 cm peg and a swung sledge are a
	# smudge; the ten are worked in groups across the drive with the eye stepping
	# down it, and the rings are the live group's.
	_check(drive.stake_group_count() >= 4,
		"the ten stakes are cut into groups across the drive (%d)" % drive.stake_group_count())
	var group_open := drive.open_stakes_in(drive.current_stake_group()).size()
	_check(rings.count() == group_open and group_open >= 2,
		"a ring on each stake of the pair being driven, and only those (%d of %d)"
		% [rings.count(), group_open])
	await _settled()
	_check(_all_rings_on_screen(), "and every one of them is inside the frame")
	# The pegs are standing BEFORE the first blow, and each ring sits on its
	# painted cap (the improvement plan's 4.2): they used to appear on the first
	# blow, so the first pair's rings floated over bare earth.
	var capped_rings := 0
	var ring_pts: Array[Vector3] = rings.points().duplicate()
	var ring_open := drive.open_stakes_in(drive.current_stake_group())
	for r in range(mini(ring_pts.size(), ring_open.size())):
		var sid: int = ring_open[r]
		if drive.stake_shown(sid) and absf(ring_pts[r].y - drive.stake_cap(sid).y) < 0.035:
			capped_rings += 1
	_check(capped_rings == ring_open.size() and capped_rings >= 2,
		"the pair's pegs stand waiting before the first blow, a ring on each painted cap (%d of %d)"
		% [capped_rings, ring_open.size()])
	# And the SLEDGE is already wound up over the first of them, before a finger
	# has touched anything: the raised hammer is what says "hit this one"
	# (2026-09-16). It used to lie on the lawn until the tap and then fly in, so
	# the tap was answered by a tool arriving instead of by a blow - while every
	# posed screenshot showed it up, which is how the drift went unnoticed.
	var sledge_w := main.tool_node("sledge") as HandTool
	var peg_w: int = ring_open[0] if not ring_open.is_empty() else 1
	var cap_w := drive.stake_cap(peg_w).y + Driveway.STAKE_CAP * 0.5
	var home_w := drive.stake_home(peg_w)
	var rise_w := sledge_w.global_position.y - cap_w if sledge_w != null else -1.0
	var over_w := Vector2(sledge_w.global_position.x - home_w.x,
		sledge_w.global_position.z - home_w.z).length() if sledge_w != null else 99.0
	_check(sledge_w != null and sledge_w.visible and rise_w > main.config.sledge_lift * 0.5 and over_w < 0.9,
		"and the sledge WAITS wound up over the first of them (%.2f m up, %.2f m of it)" % [rise_w, over_w])
	_check(sledge_w != null and sledge_w.global_position.distance_to(SiteMain.TOOL_REST["sledge"]) > 1.0,
		"off the lawn before the tap, not flown in after it")
	var heads: Array[Vector3] = rings.points().duplicate()
	var same := 0
	for i in range(heads.size()):
		for j in range(i + 1, heads.size()):
			if heads[i].distance_to(heads[j]) < 0.1:
				same += 1
	_check(same == 0, "each in its own place (%d pairs on top of each other)" % same)
	# Close enough to feel the blow: the eye is within a few metres of the stake
	# it is watching, where the whole-pad shot stood eight and a half off.
	var mark := drive.stake_group_mark(drive.current_stake_group())
	var stand := main.camera.global_position.distance_to(mark.global_position) if mark != null else 99.0
	_check(stand < 4.5, "and the eye is right down on them (%.1f m)" % stand)
	# The LAST of each group first, so the order inside a group is still the
	# child's; the groups themselves come in the order the crew works them.
	var seen: Array[Vector3] = []
	var stakes := 0
	while drive.stakes_in() < 8 and stakes < 20 and runner.current_step().verb == "stake_drive":
		if not await _until(func() -> bool: return runner.waiting_for_tap() and not runner.is_busy(),
				"the next stake"):
			break
		var g := drive.current_stake_group()
		var open := drive.open_stakes_in(g)
		if open.is_empty():
			break
		var i: int = open[open.size() - 1]
		var was := drive.stakes_in()
		_check(_tap_ring(i), "stake %d's ring can be pressed" % i)
		if stakes == 0:
			# The blow KICKS the picture (the plan's 1.4), and it is still again
			# well inside a second: measured off the camera, not the number.
			var peak := 0.0
			# And the sledge's face never goes INSIDE the cap it hits: it used to
			# sink 25 cm into the proud peg before the strike (4.2). Measured only
			# while the head is over this stake, not on its flight in.
			var sledge_t := main.tool_node("sledge") as HandTool
			var sh := drive.stake_home(i)
			var deepest := INF
			var over := 0
			# It SWINGS now, so the head travels along the board as well as down:
			# a 2 cm window would have measured only the ride-down after the
			# strike and called it a landing. Anything within a swing's reach of
			# the peg counts, and the face must never be inside the cap in ANY
			# of those frames.
			var hi_y := -INF
			var lo_y := INF
			var turned := 0.0
			var b_first := sledge_t.global_basis.z if sledge_t != null else Vector3.ZERO
			while runner.is_busy():
				peak = maxf(peak, maxf(absf(main.camera.h_offset), absf(main.camera.v_offset)))
				if sledge_t != null:
					var fp := sledge_t.global_position
					hi_y = maxf(hi_y, fp.y)
					lo_y = minf(lo_y, fp.y)
					turned = maxf(turned, (sledge_t.global_basis.z - b_first).length())
					if Vector2(fp.x - sh.x, fp.z - sh.z).length() < 0.9:
						over += 1
						deepest = minf(deepest, fp.y - (drive.stake_cap(i).y + Driveway.STAKE_CAP * 0.5))
				await get_tree().process_frame
			_check(hi_y - lo_y > main.config.sledge_lift * 0.5,
				"the head really travels down onto the peg (%.0f cm)" % ((hi_y - lo_y) * 100.0))
			_check(turned > 0.05,
				"and it SWINGS on its handle - the tool turns, it is not lowered flat (%.3f)" % turned)
			print("      sledge blow: camera peak offset %.1f mm" % (peak * 1000.0))
			_check(peak >= 0.008, "the sledge blow kicks the picture (%.1f mm)" % (peak * 1000.0))
			_check(over > 3 and deepest >= -0.005,
				"and its face lands ON the cap, never inside the peg (%d frames over it, deepest %.3f m)"
				% [over, deepest])
			await get_tree().create_timer(0.6).timeout
			_check(absf(main.camera.h_offset) < 0.0005 and absf(main.camera.v_offset) < 0.0005,
				"and it is still again within 0.6 s")
		elif was + 1 >= 8:
			# The last stake: the picture HOLDS on it before moving on (1.6).
			await _until(func() -> bool: return drive.stake_is_in(i), "the last stake")
			_check(main.rig.current_shot() == CameraRig.STAKE, "the last stake goes in with the eye still on it")
			await get_tree().create_timer(0.5).timeout
			var held_on := main.camera.global_position.distance_to(drive.stake_group_mark(g).global_position)
			var kerb_off := main.camera.global_position.distance_to(drive.stake_group_mark(drive.stake_group_count() - 1).global_position)
			_check(main.rig.current_shot() == CameraRig.STAKE and held_on < 4.5 and kerb_off > 3.0,
				"and the picture holds on THAT pair before moving on, not on the kerb's (%.1f m from it, %.1f from the kerb pair)"
				% [held_on, kerb_off])
		await _until(func() -> bool: return not runner.is_busy(), "stake %d" % i)
		stakes += 1
		if drive.stakes_in() != was + 1 or not drive.stake_is_in(i):
			_check(false, "stake %d is the one that went in (%d -> %d)" % [i, was, drive.stakes_in()])
		if drive.current_stake_group() != g and drive.stakes_in() < 8:
			await _settled()
			seen.append(main.camera.global_position)
	_check(drive.stakes_in() == 8, "the long boards' eight stakes are driven (%d)" % drive.stakes_in())
	_check(not drive.stake_shown(9) and not drive.stake_shown(10),
		"and the kerb board's two are not standing in the road's edge")
	# And every one of them is left standing a stub above its board, so the
	# picture has changed (round 3: ten stops that left nothing on screen).
	var stub := drive.stake_home(1).y - Driveway.GRADE
	_check(stub > 0.03, "each finishing a stub above the board, where the screed never goes (%.2f m)" % stub)
	# The stub is the PINK cap: ten bright dots down the boards in every later
	# wide, in a hue nothing beside them has (4.2).
	# Read off the drawn cap itself - its box in the world and its own material -
	# not the numbers it was built from.
	var pink_stubs := 0
	var cap_colour := Color.BLACK
	for stake_n in drive.find_children("Stake_*", "MeshInstance3D", false, false):
		var cap := stake_n.find_child("Cap", false, false) as MeshInstance3D
		if cap == null or not cap.is_visible_in_tree():
			continue
		var box := cap.global_transform * cap.get_aabb()
		if box.end.y > Driveway.GRADE + 0.03 and box.position.y < Driveway.GRADE + 0.01:
			pink_stubs += 1
		var cm := cap.get_active_material(0) as BaseMaterial3D
		if cm != null:
			cap_colour = cm.albedo_color
	_check(pink_stubs == 8, "every driven stake's painted cap is the stub above its board (%d of 8)" % pink_stubs)
	var board_m := (drive.find_child("Form_1", false, false) as MeshInstance3D).get_active_material(0) as BaseMaterial3D
	var chair_m := (drive.find_child("Chair_1_1", false, false) as MeshInstance3D).get_active_material(0) as BaseMaterial3D
	var gap_t := _hue_gap(cap_colour, board_m.albedo_color) if board_m != null else 0.0
	var gap_c := _hue_gap(cap_colour, chair_m.albedo_color) if chair_m != null else 0.0
	var gap_g := _hue_gap(cap_colour, SpotRings.GOLD)
	_check(cap_colour.s > 0.5 and gap_t > 0.12 and gap_c > 0.12 and gap_g > 0.12,
		"and the cap is a hue apart from the board, the chairs and the rings (%.2f / %.2f / %.2f of the wheel)"
		% [gap_t, gap_c, gap_g])
	var stood_still := 0
	for i in range(1, seen.size()):
		if seen[i].distance_to(seen[i - 1]) < 0.5:
			stood_still += 1
	_check(seen.size() >= 3 and stood_still == 0,
		"and the eye stepped down the drive with them (%d pictures, %d the same place)"
		% [seen.size(), stood_still])


# --- Phase 5: the base ---------------------------------------------------------------------------

func _phase_base() -> void:
	print("--- 5. the base ---")
	var waiting := await _until(func() -> bool: return runner.waiting_button() == "call", "the button")
	_check(waiting, "the green button asks for the dump truck")
	var skid_gone := main.machine("SkidSteer")
	_check(skid_gone != null and not skid_gone.visible and not skid_gone.is_driving(),
		"the skid steer is gone before the tipper is called")
	# 5.2's check: the kerb board and its pegs are nowhere while the tipper is on
	# site, watched every frame until it has gone.
	_kerb_seen = [0, false]
	_watch_kerb = true
	_watch_kerb_end(main.machine("DumpTruck"))
	hud.simulate_button("call")
	var truck := main.machine("DumpTruck")
	# A tap on the ARRIVING truck is answered by its horn; a tap on the lawn by
	# nothing, and GO does not kick (the improvement plan's 1.8).
	await _until(func() -> bool: return truck.visible \
		and _on_screen(truck.global_position + Vector3(0.0, 1.0, 0.0)), "the truck in the picture")
	await _frames(5)
	_check(runner.current_step().verb == "call_dump", "the tap lands on its own street leg")
	var truck_px := main.camera.unproject_position(truck.global_position + Vector3(0.0, 1.0, 0.0))
	main._press(truck_px, true)
	main._press(truck_px, false)
	_check(main.sfx.last_played == "horn", "a tap on the arriving truck honks it (%s)" % main.sfx.last_played)
	# And winks its beacon, on top of the flashing it does while it drives: the
	# wink was a silent no-op until 4.5 put the Beacon in the contract.
	_check(truck.beacon_on() and truck.beacon_flash_k() > 0.5 and truck.beacon_level() > 0.9,
		"and winks its beacon, which is turning as it comes (wink %.2f, lens %.2f)"
		% [truck.beacon_flash_k(), truck.beacon_level()])
	var lawn_px := main.camera.unproject_position(Vector3(Driveway.CENTRE_X - 6.0, 0.0, Driveway.Z_KERB - 2.0))
	main._press(lawn_px, true)
	main._press(lawn_px, false)
	_check(main.sfx.last_played == "horn" and not hud.arrow_nudged(),
		"and a tap on the lawn while it comes is answered by nothing")
	# It STOPS in the road and waits for the child to back it in (the plan's 1.8,
	# decision 4): the reverse leg is the child's hold now.
	var stopped := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "back_dump", "the truck stops in the road")
	_check(stopped, "the tipper comes down the street and stops, waiting to be backed in")
	_save_is("back_dump", 1, 0, [], "on entering the back-in, a row the bar does not count,")
	await _settled()
	var stop := main.street_stop("DumpTruck")
	_check(truck.visible and not truck.is_driving() \
		and Vector2(truck.global_position.x - stop.x, truck.global_position.z - stop.z).length() < 0.05,
		"it waits in the road where play stops it (%s)" % str(truck.global_position))
	_check(truck.beacon_on() and main.sfx.is_looping("arrive") and not main.sfx.is_looping("beeper"),
		"engine ticking over and beacon turning, no beeper while it stands")
	_check(runner.waiting_for_hold() and not runner.is_busy(), "and the beat is a HOLD waiting for a finger")
	var pointer := main.get_node_or_null("Pointer") as SpotRings
	var tail := main.arrival_hint("DumpTruck")
	_check(pointer != null and pointer.lit() and pointer.points().size() > 0 \
		and pointer.points()[0].distance_to(tail) < 0.2 and _hint_on_screen(),
		"the gold ring stands on its tailgate, in the picture")
	var p_wait := truck.global_position
	await get_tree().create_timer(1.0).timeout
	_check(truck.global_position.distance_to(p_wait) < 0.005, "and it waits: no finger, no movement")
	# The lawn to the RIGHT of the drive: the left lawn behind the waiting truck is
	# the truck on the screen (a press there did back it in, rightly).
	var lawn2 := main.camera.unproject_position(Vector3(Driveway.CENTRE_X + 5.0, 0.0, SiteMain.STREET_Z - 5.0))
	_check(not main.on_backing_truck(lawn2), "(the lawn point is off the truck on the screen)")
	var missed := main._press(lawn2, true)
	_check(not missed and main.sfx.last_played == "pop" and not runner.held,
		"a press on the lawn is a miss, heard (%s)" % main.sfx.last_played)
	main._press(lawn2, false)
	var truck_mid := main.camera.unproject_position(main._world_box(truck).get_center())
	var rolled_in := truck.rolled_m()
	var took := main._press(truck_mid, true)
	_check(took and runner.held, "a finger ON the truck backs it in")
	_check(main.sfx.is_looping("beeper"), "and it beeps from the frame it moves")
	await get_tree().create_timer(0.6).timeout
	_check(truck.path_k() > 0.0 and truck.rolled_m() < rolled_in - 0.05,
		"tail first, its wheels turning backwards (k %.2f, rolled %.2f m)" % [truck.path_k(), truck.rolled_m() - rolled_in])
	await _until(func() -> bool: return truck.path_k() > 0.35, "half way back")
	var k_lift := truck.path_k()
	main._press(truck_mid, false)
	await get_tree().create_timer(main.config.back_ramp + 0.25).timeout
	# Letting go STOPS it: only the ramp's short coast, never the tap's burst on
	# top of a real hold (the verification pass measured about two metres more).
	_check(truck.path_k() >= k_lift and truck.path_k() < k_lift + 0.08,
		"let go, it comes to rest within its short coast and never rolls back (k %.3f -> %.3f)" % [k_lift, truck.path_k()])
	var p_lift := truck.global_position
	await get_tree().create_timer(0.3).timeout
	_check(truck.global_position.distance_to(p_lift) < 0.005 and not main.sfx.is_looping("beeper") \
		and main.sfx.is_looping("arrive"),
		"let go, it rolls to a stop where it is and the beeper stops (%.3f m)" % truck.global_position.distance_to(p_lift))
	_check(runner.current_step().verb == "back_dump" and runner.is_busy(), "and waits there for the finger again")
	_check(pointer.lit() and pointer.points()[0].distance_to(main.arrival_hint("DumpTruck")) < 0.2,
		"the ring stands on the truck where it stopped, not where it was")
	var truck_now := main.camera.unproject_position(main._world_box(truck).get_center())
	var k_stop := truck.path_k()
	_check(main._press(truck_now, true), "a new press on it carries on")
	await get_tree().create_timer(0.5).timeout
	_check(truck.path_k() > k_stop and (not pointer.lit() or pointer.points()[0].distance_to(main.arrival_hint("DumpTruck")) < 0.2),
		"from where it stopped, and the ring does not hang where it was while it backs away (k %.2f -> %.2f)" % [k_stop, truck.path_k()])
	var tip_next := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "tip_gravel", "the tipper backed all the way in")
	_check(tip_next, "held, it backs all the way up the drive")
	_check(not runner.held, "and a finger still down at the stop does not start the tip on its own")
	_check(not main.sfx.is_looping("beeper") and main.sfx.last_played == "hiss",
		"and stops with a hiss of the brakes, the beeper off (%s)" % main.sfx.last_played)
	await get_tree().create_timer(0.5).timeout
	_check(drive.gravel_k() < 0.001 and truck.load_k() > 0.9, "nothing tips until a new press (base %.2f)" % drive.gravel_k())
	# And the tip has its ring with no further input - the finger never lifted
	# (the GO key's case): a mute across the step boundary used to leave it with
	# none (the verification pass).
	var tip_at := runner.target_world()
	_check(pointer.lit() and tip_at != Vector3.INF and pointer.points()[0].distance_to(tip_at) < 0.2,
		"and the tip's own ring is up on the tailgate, with no lift and no new press")
	main._press(truck_now, false)
	_check(not truck.beacon_on(), "and its beacon stops with it")
	_check(truck.global_position.z < Driveway.Z_APRON + 4.0,
		"it REVERSED up the drive, tail at the garage end (z %.2f)" % truck.global_position.z)
	_check(absf(rad_to_deg(truck.rotation.y)) < 8.0,
		"nose to the street, ready to pull out (%.0f deg)" % rad_to_deg(truck.rotation.y))
	_check(absf(truck.global_position.y - drive.stand_y(truck.global_position)) < 0.06,
		"and stands on the excavation rather than over it (y %.2f, ground %.2f)"
			% [truck.global_position.y, drive.stand_y(truck.global_position)])
	# Touch and hold, not a pad: "dump truck should be a touch and hold".
	_check(not hud.pad_visible("up"), "the tip is press-and-hold, so no pad is up for it")
	# And it turned up with something in it.
	_check(truck.load_k() > 0.9, "the tipper arrived LOADED (%.2f)" % truck.load_k())
	var from_z := truck.global_position.z
	var rolled := truck.rolled_m()
	runner.hold(true)
	await _frames(5)
	_check(truck.beacon_on(), "its beacon turns again while it tips")
	var based := await _until(func() -> bool: return drive.gravel_k() >= 0.999, "the base laid")
	runner.hold(false)
	_check(based, "the bed tipped and the limestone went in (%.2f)" % drive.gravel_k())
	_check(truck.global_position.z > from_z + 1.0,
		"and it DROVE OUT as it dropped the rock (%.2f -> %.2f)" % [from_z, truck.global_position.z])
	_check(absf(truck.rolled_m() - rolled) > 1.0,
		"rolling as it went (%.1f m)" % absf(truck.rolled_m() - rolled))
	_check(truck.load_k() < 0.05, "and emptied as it went (%.2f left)" % truck.load_k())
	_check(absf(drive.gravel_top() - Driveway.BASE_TOP) < 0.01,
		"to exactly the bottom of the slab (%.3f, want %.3f)" % [drive.gravel_top(), Driveway.BASE_TOP])
	# The base is STONE, not one flat box of grey.
	_check(drive.stones_down() > 200, "with loose stone lying all over it (%d)" % drive.stones_down())


# --- Phase 5a: the plate compactor (the plan's 5.1) -----------------------------------------------

func _phase_compact() -> void:
	print("--- 5a. the plate compactor ---")
	var on := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "compact_base", "the plate")
	_check(on, "the tipper left and the plate compactor is next")
	var truck := main.machine("DumpTruck")
	_check(truck == null or not truck.visible \
		or truck.global_position.z - truck.rear_overhang() >= Driveway.Z_KERB + 0.6,
		"and the tipper's body is off the pad before the plate starts")
	_check(runner.current_step().shot == CameraRig.PLATE and runner.waiting_for_hold(),
		"the plate is held on its own low shot")
	# ONE beat over the whole base, ended by a clock, since the playtest of
	# 2026-09-16 ("it doesn't matter where you compact you just have to compact
	# for a few seconds"). The bar must not move: three beats of weight 2 became
	# one of weight 6, so the job still totals 83 stops over 25 rows.
	_check(runner.current_step().count == 1 and runner.current_step().progress_weight == 6,
		"one beat over the WHOLE base, worth the same six stops (count %d, weight %d)"
		% [runner.current_step().count, runner.current_step().progress_weight])
	# This suite spends seconds of the child's own clock on its assertions (a
	# finger held still, a real finger on the cowl) before it ever walks the
	# plate, so the budget is widened for the phase and put back after. The
	# SHIPPED default is asserted separately, below.
	var pack_default := main.config.pack_seconds
	_check(pack_default >= 5.0 and pack_default <= 6.0,
		"the base is packed by a CLOCK a child can keep: %.1f s of work, anywhere on it" % pack_default)
	main.config.pack_seconds = 9.0
	var plate := main.tool_node("plate")
	_check(plate != null and plate.model_loaded and plate.missing_nodes.is_empty(),
		"the plate compactor is the built GLB with its Body, Head, Grip and Tip (%s)"
		% (str(plate.missing_nodes) if plate != null else "none"))
	await _settled()
	var start := drive.plate_start(1)
	_check(plate.visible and Vector2(plate.global_position.x - start.x, plate.global_position.z - start.z).length() < 0.03 \
		and plate.global_position.y < Driveway.BASE_TOP + 0.04 and plate.global_position.y > Driveway.BASE_TOP - 0.01,
		"it stands ON the base at the start of the first bay, not on the lawn (%s)" % str(plate.global_position))
	var frame := main.camera.get_viewport().get_visible_rect().size
	_check(_on_screen(plate.global_position), "in the picture")
	var grip := plate.find_child("Grip", true, false) as Node3D
	var grip_off := grip != null and (main.camera.is_position_behind(_grip_point(grip)) \
		or main.camera.unproject_position(_grip_point(grip)).y > frame.y)
	_check(grip_off, "and its handle runs off the bottom of the picture, into the child's hands")
	var band1 := drive.bay_range(1)
	_check(drive.pack_coverage() < 0.001 and not drive.stones_flat(),
		"the base is LOOSE before it: nothing packed, the stone tipped every way")
	# The cowl is the family's tool orange, read off the drawn mesh.
	var cowl := Color.BLACK
	for n in plate.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for si in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
			var m := mi.get_active_material(si) as BaseMaterial3D
			if m != null and String(m.resource_name).contains("ToolOrange"):
				cowl = m.albedo_color
	_check(cowl.s > 0.8 and cowl.get_luminance() < Driveway.GRAVEL_PACKED.get_luminance() * 0.75,
		"its cowl is a saturated tool orange a step darker than the base (s %.2f, luma %.2f)" % [cowl.s, cowl.get_luminance()])
	# A finger resting on the base AWAY from the plate moves nothing.
	var still_at := plate.global_position
	main.set_work_cursor(start + Vector3(0.0, 0.0, -1.5))
	runner.hold(true)
	await get_tree().create_timer(0.6).timeout
	_check(drive.pack_coverage() < 0.001 and plate.global_position.distance_to(still_at) < 0.01 \
		and not main.sfx.is_looping("plate"),
		"a finger resting on the base away from the plate moves nothing and packs nothing")
	runner.hold(false)
	await _frames(3)
	# A finger held still ON the plate packs a plus sign and no more.
	main.set_work_cursor(start)
	runner.hold(true)
	var head := plate.find_child("Head", true, false) as Node3D
	var head_lo := INF
	var head_hi := -INF
	var peak := 0.0
	var pos_a := -1.0
	var pos_b := -1.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2000:
		peak = maxf(peak, maxf(absf(main.camera.h_offset), absf(main.camera.v_offset)))
		if head != null:
			head_lo = minf(head_lo, head.position.z)
			head_hi = maxf(head_hi, head.position.z)
		var lp: AudioStreamPlayer = main.sfx.loop_player("plate")
		var el := Time.get_ticks_msec() - t0
		if lp != null and el > 500 and pos_a < 0.0:
			pos_a = lp.get_playback_position()
		if lp != null and el > 800 and pos_b < 0.0:
			pos_b = lp.get_playback_position()
		await get_tree().process_frame
	var cx := int(floor((start.x - (Driveway.CENTRE_X - Driveway.WIDTH * 0.5)) / (Driveway.WIDTH / Driveway.CELLS_X)))
	var cz := int(floor((start.z - Driveway.Z_APRON) / (Driveway.LENGTH / Driveway.CELLS_Z)))
	var cell := cz * Driveway.CELLS_X + cx
	var packed := drive.packed_cells(0.9)
	var plus := [cell, cell - 1, cell + 1, cell - Driveway.CELLS_X, cell + Driveway.CELLS_X]
	var plus_ok := packed.size() == 5
	for c in plus:
		if not packed.has(c):
			plus_ok = false
	var diag := drive.packed_at(drive.cell_world(cx - 1, cz - 1)) + drive.packed_at(drive.cell_world(cx + 1, cz + 1))
	_check(plus_ok and diag < 0.05,
		"a finger held still on the plate packs a PLUS SIGN and nothing more (%s packed, diagonals %.2f)" % [str(packed), diag])
	_check(peak > 0.001, "the picture rattles while it works (%.1f mm)" % (peak * 1000.0))
	_check(head != null and head_hi - head_lo > 0.002, "its head buzzes on its mounts (%.1f mm)" % ((head_hi - head_lo) * 1000.0))
	_check(main.sfx.loaded_count("platerattle") > 0 and main.sfx.is_looping("plate") and pos_b > pos_a and pos_a >= 0.0,
		"and its rattle really plays (%d clips, %.2f -> %.2f s)" % [main.sfx.loaded_count("platerattle"), pos_a, pos_b])
	# Stones read off the stones: flat in the packed cell, still tipped on a diagonal.
	var flat_in := 0
	var in_cell := 0
	var tipped_diag := 0
	var in_diag := 0
	for st in drive.find_children("Stone_*", "MeshInstance3D", false, false):
		var sn := st as Node3D
		var sx := int(floor((sn.position.x - (Driveway.CENTRE_X - Driveway.WIDTH * 0.5)) / (Driveway.WIDTH / Driveway.CELLS_X)))
		var sz := int(floor((sn.position.z - Driveway.Z_APRON) / (Driveway.LENGTH / Driveway.CELLS_Z)))
		var up_dot := sn.global_basis.y.normalized().dot(Vector3.UP)
		if sz == cz and sx == cx:
			in_cell += 1
			if up_dot > cos(deg_to_rad(2.0)) and sn.global_position.y + 0.06 < Driveway.BASE_TOP + 0.06:
				flat_in += 1
		if sz == cz - 1 and sx == cx - 1:
			in_diag += 1
			if up_dot < cos(deg_to_rad(5.0)):
				tipped_diag += 1
	_check(in_cell > 0 and flat_in == in_cell, "every stone in the plate's cell lies flat (%d of %d)" % [flat_in, in_cell])
	_check(in_diag > 0 and float(tipped_diag) >= 0.8 * float(in_diag),
		"while a diagonal cell's stone is still tipped (%d of %d)" % [tipped_diag, in_diag])
	# The luma step, off the drawn bed: the packed cell's centre against a loose one.
	var bed := drive.find_child("PackedBed", false, false) as MeshInstance3D
	var luma_step := 0.0
	var hue_gap := 1.0
	if bed != null and bed.mesh != null and bed.mesh.get_surface_count() > 0:
		var arr := bed.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		var packed_c := Color.BLACK
		var loose_c := Color.BLACK
		var pw := drive.cell_world(cx, cz)
		var lw := drive.cell_world(0, cz - 2)
		for vi in range(verts.size()):
			if Vector2(verts[vi].x - pw.x, verts[vi].z - pw.z).length() < 0.01:
				packed_c = cols[vi]
			if Vector2(verts[vi].x - lw.x, verts[vi].z - lw.z).length() < 0.01:
				loose_c = cols[vi]
		luma_step = packed_c.get_luminance() / maxf(loose_c.get_luminance(), 0.01) - 1.0
		hue_gap = _hue_gap(packed_c, loose_c)
	_check(bed != null and bed.visible and luma_step >= 0.10 and hue_gap < 0.03,
		"and the packed cell is drawn a luma step paler, the same hue (+%.0f%%, hue %.3f)" % [luma_step * 100.0, hue_gap])
	runner.hold(false)
	await _frames(2)
	var pointer_p := main.get_node_or_null("Pointer") as SpotRings
	_check(pointer_p != null and pointer_p.lit() and pointer_p.points().size() == 1 \
		and Vector2(pointer_p.points()[0].x - main.drag_tool_at.x, pointer_p.points()[0].z - main.drag_tool_at.z).length() < 0.1 \
		and _hint_on_screen(),
		"let go, the gold ring stands on the plate, in the picture")
	await get_tree().create_timer(0.4).timeout
	_check(absf(main.camera.h_offset) < 0.0005 and absf(main.camera.v_offset) < 0.0005 and not main.sfx.is_looping("plate"),
		"and the rattle and the engine stop")
	# A REAL finger on the plate's orange cowl: through the input pipeline, no
	# world cursor. It lands a metre behind the plate on the base, and a press
	# there was accepted and never grabbed (the verification pass).
	main.clear_work_cursor()
	await _settled()
	var head_n := plate.find_child("Head", true, false) as MeshInstance3D
	var hb := head_n.global_transform * head_n.get_aabb()
	var cowl_px := main.camera.unproject_position(Vector3(hb.get_center().x, hb.end.y, hb.get_center().z))
	var p_cowl := plate.global_position
	_touch(0, cowl_px, true)
	await get_tree().create_timer(1.0).timeout
	_check(runner.held and main.sfx.is_looping("plate") and plate.global_position.distance_to(p_cowl) < 0.02,
		"a real finger on the orange cowl picks the plate up, and held still there the plate stands still (%.3f m)"
		% plate.global_position.distance_to(p_cowl))
	for f in range(60):
		_drag(0, cowl_px + Vector2(0.0, -90.0 * float(f) / 60.0))
		await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	_check(plate.global_position.z < p_cowl.z - 0.1, "and dragged up the picture it walks up the drive (z %.2f -> %.2f)"
		% [p_cowl.z, plate.global_position.z])
	var grip_far := grip != null and (main.camera.is_position_behind(_grip_point(grip)) \
		or main.camera.unproject_position(_grip_point(grip)).y > frame.y)
	_check(grip_far, "its handle still runs off the bottom of the picture")
	_touch(0, cowl_px + Vector2(0.0, -90.0), false)
	await _frames(3)
	# A press on the base far from the plate is a miss.
	var far := main.camera.unproject_position(Vector3(Driveway.CENTRE_X + 1.4, Driveway.BASE_TOP, band1.y - 0.3))
	var heard_n := int(main.sfx.played_count.get("pop", 0))
	_check(not main._press(far, true) and int(main.sfx.played_count.get("pop", 0)) > heard_n,
		"a press on the base away from the plate is a miss, heard")
	main._press(far, false)
	# One run, anywhere, for `pack_seconds` of real work - the child's own path,
	# not a boustrophedon. The smoke walks a single lane up the middle, which
	# under the OLD coverage rule could never have finished a bay, let alone
	# three: that is the point of the change.
	var t_pack := Time.get_ticks_msec()
	var lane_ok := await _walk_plate(0)
	_check(lane_ok, "running the plate up ONE lane finishes the phase (%.2f of the base packed on the way)"
		% drive.pack_coverage())
	await _until(func() -> bool: return runner.done_in_step >= 1 or runner.current_step().verb != "compact_base",
		"the base is packed")
	# Measured off the verb's OWN clock, not the wall: everything this suite did
	# on the plate before the walk counts, and none of the frames it spent
	# elsewhere do. That is the whole promise - seconds of WORK, not coverage.
	var worked: float = main.pack_worked
	_check(worked >= main.config.pack_seconds * 0.95 and worked <= main.config.pack_seconds + 0.5,
		"and it ended on its clock, at %.1f s of the %.1f s it asks for (wall %.1f s)"
		% [worked, main.config.pack_seconds, float(Time.get_ticks_msec() - t_pack) / 1000.0])
	main.config.pack_seconds = pack_default
	runner.hold(false)
	await get_tree().create_timer(main.config.pack_finish_time + 0.2).timeout
	_check(drive.pack_coverage() >= 0.999,
		"every bay the child never reached goes down with the one they did (%.3f)" % drive.pack_coverage())
	_check(drive.stones_flat(), "and every stone on the base is lying flat")
	# From the last bay's end until the plate is put away: never see-through, and
	# gone only once it is back on the grass (the verification pass: it faded out
	# in the held picture).
	var faded := 0
	var home_at_hide := -1.0
	var was_seen := plate.visible
	var watch := 0
	while watch < FRAME_CAP and (plate.visible or not was_seen):
		was_seen = was_seen or plate.visible
		for n in plate.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			for si in range(mi.get_surface_override_material_count()):
				var om := mi.get_surface_override_material(si) as BaseMaterial3D
				if om != null and (om.albedo_color.a < 0.999 or om.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
					faded += 1
		home_at_hide = plate.global_position.distance_to(SiteMain.TOOL_REST["plate"])
		watch += 1
		await get_tree().process_frame
	_check(faded == 0 and home_at_hide >= 0.0 and home_at_hide < 0.3,
		"the plate goes back to the grass whole and is put away there, never faded (%d see-through frames, %.2f m from its rest)"
		% [faded, home_at_hide])
	var off := await _until(func() -> bool: return runner.current_step() == null \
		or runner.current_step().verb != "compact_base", "the plate finishes")
	_check(off, "three bays and the plate is done")
	main.clear_work_cursor()
	_check(drive.pack_coverage() >= 0.999 and drive.stones_flat() and drive.pack_baked(),
		"the whole base is packed, every stone flat, the packed colour baked into it")
	var gravel_m := (drive.find_child("Gravel", false, false) as MeshInstance3D).get_active_material(0) as BaseMaterial3D
	_check(bed != null and not bed.visible and gravel_m != null and gravel_m.albedo_color.is_equal_approx(Driveway.GRAVEL_PACKED),
		"and no overlay is left 2 mm over the base to fight the pour")
	await _settled()
	_check(absf(main.camera.h_offset) < 0.0005 and not main.sfx.is_looping("plate"),
		"and nothing rattles the next picture")
	_watch_kerb = false
	await _frames(2)
	_check(_kerb_seen[1] and int(_kerb_seen[0]) == 0,
		"the kerb board and its pegs were never on site while the tipper was, and the tipper really crossed the kerb end (%d frames)"
		% int(_kerb_seen[0]))


## Where the plate's grip bar really is: the middle of the drawn bar's box. The
## Grip NODE's origin rides a handle-length short of it (the bar's vertices are
## built out at the handle's end), which is what an earlier check was reading.
func _grip_point(grip: Node3D) -> Vector3:
	var mi := grip as MeshInstance3D
	if mi == null or mi.mesh == null:
		return grip.global_position
	return (mi.global_transform * mi.get_aabb()).get_center()


## Walks the plate over one bay the way a finger does: the cursor always a
## hand's width ahead of the plate toward the next point of a serpentine over
## the bay, the finger down, until the bay's beat ends.
## Walks the plate over bay `b`, or - with `b = 0` - up ONE lane of the whole
## base and back, which is all the child is asked for now.
func _walk_plate(b: int) -> bool:
	var band := Vector2(Driveway.Z_APRON, Driveway.Z_KERB) if b <= 0 else drive.bay_range(b)
	var pts: Array[Vector3] = []
	var xs := [Driveway.CENTRE_X] if b <= 0 		else [Driveway.CENTRE_X - 1.25, Driveway.CENTRE_X - 0.4, Driveway.CENTRE_X + 0.4, Driveway.CENTRE_X + 1.25]
	for li in range(xs.size()):
		var za := band.x + 0.3
		var zb := band.y - 0.3
		pts.append(Vector3(xs[li], Driveway.BASE_TOP, za if li % 2 == 0 else zb))
		pts.append(Vector3(xs[li], Driveway.BASE_TOP, zb if li % 2 == 0 else za))
	var at := 0
	for frame in range(FRAME_CAP):
		if runner.done_in_step >= maxi(b, 1) or runner.current_step() == null 				or runner.current_step().verb != "compact_base":
			return true
		var plate_p := main.drag_tool_at
		if plate_p == Vector3.INF:
			return false
		var want := pts[at % pts.size()]
		var d := Vector3(want.x - plate_p.x, 0.0, want.z - plate_p.z)
		if d.length() < 0.15:
			at += 1
		main.set_work_cursor(plate_p + d.limit_length(0.4))
		runner.hold(true)
		await get_tree().process_frame
	return false


## Counts every frame the kerb board or its pegs are on site while the tipper
## is (5.2), and notes whether the tipper's tail was really seen over the kerb end.
func _watch_kerb_end(truck: Machine) -> void:
	while _watch_kerb:
		if truck != null and truck.visible:
			if drive.form_shown(Driveway.KERB_BOARD) or drive.stake_shown(9) or drive.stake_shown(10):
				_kerb_seen[0] = int(_kerb_seen[0]) + 1
			var box := main._world_box(truck)
			if box.position.z < Driveway.Z_KERB and box.end.z > Driveway.Z_KERB \
					and absf(truck.global_position.x - Driveway.CENTRE_X) < Driveway.WIDTH:
				_kerb_seen[1] = true
		await get_tree().process_frame


# --- Phase 5c: the kerb board, after the base (the plan's 5.2) ------------------------------------

func _phase_kerb() -> void:
	print("--- 5c. the kerb board ---")
	var tip_i := main.job.index_of("tip_gravel")
	var on := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "form_set" and runner.index > tip_i, "the kerb board")
	_check(on, "the base is packed and the kerb board is next")
	_check(rings.count() == 1 and rings.id_at(0) == Driveway.KERB_BOARD,
		"one ring, on the kerb board (%d)" % rings.count())
	_check(drive.form_shown(Driveway.KERB_BOARD) and drive.form_k(Driveway.KERB_BOARD) < 0.01,
		"the kerb board waits in the air over its slot")
	await _settled()
	_check(_all_rings_on_screen(), "and its ring is inside the frame")
	_check(main.camera.global_position.z > SiteMain.KERB_Z, "seen from the road (eye z %.1f)" % main.camera.global_position.z)
	var home_1 := (drive.find_child("Form_1", false, false) as Node3D).position
	_check(_tap_ring(Driveway.KERB_BOARD), "its ring can be pressed")
	await _until(func() -> bool: return not runner.is_busy(), "the kerb board lands")
	_check(drive.form_is_in(Driveway.KERB_BOARD) and drive.forms_in() == 4, "it goes in and closes the form (%d)" % drive.forms_in())
	_check(drive.form_k(1) >= 0.999 and drive.form_k(2) >= 0.999 and drive.form_k(4) >= 0.999 \
		and (drive.find_child("Form_1", false, false) as Node3D).position.is_equal_approx(home_1),
		"and the three boards already in STAY in (the old first beat lifted them all back up)")
	var pegs := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "stake_drive" and runner.index > tip_i, "the kerb pegs")
	_check(pegs, "then its two pegs")
	_check(rings.count() == 2 and rings.index_of(9) >= 0 and rings.index_of(10) >= 0 \
		and drive.stake_shown(9) and drive.stake_shown(10),
		"two rings, on the kerb board's own pegs standing ready (%d)" % rings.count())
	var capped := 0
	for r in range(rings.count()):
		var sid := rings.id_at(r)
		if absf(rings.point_at(r).y - drive.stake_cap(sid).y) < 0.035:
			capped += 1
	_check(capped == 2, "each ring on its painted cap (%d)" % capped)
	await _settled()
	_check(_all_rings_on_screen(), "both inside the frame")
	var kmark := drive.stake_group_mark(drive.stake_group_count() - 1)
	_check(main.camera.global_position.distance_to(kmark.global_position) < 4.5 \
		and main.camera.global_position.z > Driveway.Z_KERB + 0.5,
		"the eye is down on them from the road's edge (%.1f m)" % main.camera.global_position.distance_to(kmark.global_position))
	var crossing := main.get_node_or_null("Crossing") as MeshInstance3D
	var cbox := crossing.global_transform * crossing.get_aabb() if crossing != null else AABB()
	var in_concrete := 0
	for sid in [9, 10]:
		var sn := drive.find_child("Stake_3_%d" % (sid - 8), false, false) as MeshInstance3D
		var sb := sn.global_transform * sn.get_aabb()
		if sb.end.z > cbox.position.z + 0.001 and sb.position.z < cbox.end.z:
			in_concrete += 1
	_check(crossing != null and in_concrete == 0,
		"and they stand in the earth trench, not in the crossing's concrete (%d in it)" % in_concrete)
	_check(_tap_ring(10), "peg 10 can be pressed")
	await _until(func() -> bool: return not runner.is_busy(), "peg 10")
	_check(drive.stake_is_in(10) and not drive.stake_is_in(9), "and peg 10 is the one that went in")
	_check(_tap_ring(9), "and peg 9")
	await _until(func() -> bool: return drive.stake_is_in(9), "the last peg")
	await get_tree().create_timer(0.5).timeout
	_check(main.rig.current_shot() == CameraRig.STAKE \
		and main.camera.global_position.distance_to(kmark.global_position) < 4.5,
		"the picture holds on the kerb pegs before moving on")
	await _until(func() -> bool: return not runner.is_busy(), "the kerb pegs end")
	_check(drive.stakes_in() == 10 and drive.form_k(1) >= 0.999, "all ten stakes are driven now (%d)" % drive.stakes_in())
	var pink := 0
	for stake_n in drive.find_children("Stake_*", "MeshInstance3D", false, false):
		var cap := stake_n.find_child("Cap", false, false) as MeshInstance3D
		if cap == null or not cap.is_visible_in_tree():
			continue
		var box := cap.global_transform * cap.get_aabb()
		if box.end.y > Driveway.GRADE + 0.03 and box.position.y < Driveway.GRADE + 0.01:
			pink += 1
	_check(pink == 10, "ten painted caps, a stub above their boards (%d)" % pink)


# --- Phase 11: the cure, and the child strips the forms (the plan's 5.3) --------------------------

func _phase_strip() -> void:
	print("--- 11. the cure and the strip ---")
	var cure := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "slab_cure", "the cure")
	_check(cure, "the broom hands over to the cure")
	var broom_t := main.tool_node("broom")
	_check(broom_t != null and broom_t.visible and broom_t.global_position.distance_to(SiteMain.TOOL_REST["broom"]) < 0.15,
		"and the broom stays lying on the grass where it went back, until the cut")
	_check(_job_done == 0 and int(main.sfx.played_count.get("tada", 0)) == 0 and hud.flash_text() == "",
		"and there is no tada before the child's last work")
	var heap_back := 0
	var frames := 0
	while runner.current_step() != null and runner.current_step().verb == "slab_cure" and frames < FRAME_CAP:
		if drive.chunks_left() > 0:
			heap_back += 1
		frames += 1
		await get_tree().process_frame
	_check(heap_back == 0, "the heap stays gone through the cure (%d frames with rubble shown)" % heap_back)
	var on_strip := runner.current_step() != null and runner.current_step().verb == "form_strip"
	_check(on_strip, "and the cure hands over to the strip")
	var cone_l := main.get_node_or_null("ConeL") as Node3D
	var cone_r := main.get_node_or_null("ConeR") as Node3D
	var mouth_z := Driveway.Z_KERB + SiteMain.CONE_MOUTH_OUT
	_check(cone_l != null and cone_r != null and cone_l.visible and cone_r.visible \
		and Vector2(cone_l.global_position.x - (Driveway.CENTRE_X - 1.1), cone_l.global_position.z - mouth_z).length() < 0.1 \
		and Vector2(cone_r.global_position.x - (Driveway.CENTRE_X + 1.1), cone_r.global_position.z - mouth_z).length() < 0.1,
		"the cones stand across the mouth of the drive")
	var crossing := main.get_node_or_null("Crossing") as MeshInstance3D
	var cbox := crossing.global_transform * crossing.get_aabb() if crossing != null else AABB()
	var cones_on := 0
	for cone in [cone_l, cone_r]:
		if cone == null:
			continue
		var kb := main._world_box(cone)
		# Its base clear of the kerb trench, starting on the crossing, and on the
		# concrete (or the road's edge a centimetre above it) - not floating.
		if kb.position.z >= cbox.position.z - 0.005 and kb.position.z < cbox.end.z \
				and kb.end.z <= SiteMain.KERB_Z + 0.40 and absf(kb.position.y - cbox.end.y) < 0.02:
			cones_on += 1
	_check(cones_on == 2, "standing on the crossing's concrete, not over the kerb trench (%d of 2)" % cones_on)
	_check(main.garage_door_k() < 0.05, "the garage shut for the evening (%.2f)" % main.garage_door_k())
	_check(hud.chrome_alpha() > 0.3, "and the bar still in the picture for the strip's stops (%.2f)" % hud.chrome_alpha())
	if not on_strip:
		return
	_check(runner.current_step().shot == CameraRig.STRIP and runner.waiting_for_tap(), "the strip is a tap beat on its own shot")
	await _settled()
	var ids: Array = []
	for r in range(rings.count()):
		ids.append(rings.id_at(r))
	ids.sort()
	_check(ids == [1, 2, 3] and _all_rings_on_screen(),
		"three rings, one on each board, never the expansion strip, all in the picture (%s)" % str(ids))
	_check(drive.forms_in() == 4 and drive.stakes_in() == 10 and not drive.forms_stripped(), "nothing is stripped yet")
	# A miss on the slab's middle is heard and moves nothing.
	var mid_px := main.camera.unproject_position(Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_KERB - 3.0))
	if rings.pick_nearest(main.camera, mid_px, main._reach_px()) == 0 and main._board_under(mid_px, drive.open_strip_forms()) == 0:
		var pops := int(main.sfx.played_count.get("pop", 0))
		_check(not main._press(mid_px, true) and int(main.sfx.played_count.get("pop", 0)) > pops and not runner.is_busy(),
			"a press on the slab between the boards is a miss, heard")
		main._press(mid_px, false)
	# The kerb board first, by its ring.
	var slab := drive.find_child("Slab", false, false) as MeshInstance3D
	var skirt_before := _kerb_skirt_verts(slab)
	var prog := runner.progress
	var form3 := drive.find_child("Form_3", false, false) as MeshInstance3D
	var stake9 := drive.find_child("Stake_3_1", false, false) as Node3D
	var peg_y0 := stake9.global_position.y
	_check(_tap_ring(3), "the kerb board's ring can be pressed")
	_check(main.sfx.last_played == "whoosh", "and the tap is heard in the frame it lands (%s)" % main.sfx.last_played)
	var home3 := form3.global_position
	var peg_first := true
	var tipped_out := false
	var into_slab := 0
	var skirt_open := 0
	while runner.is_busy() and drive.form_k(3) >= 0.999 and not drive.form_is_stripped(3):
		var rise := form3.global_position.y - home3.y
		if rise >= 0.01 and stake9.global_position.y - peg_y0 < 0.25:
			peg_first = false
		if form3.global_basis.y.z > 0.03:
			tipped_out = true
		var fb := form3.global_transform * form3.get_aabb()
		if fb.position.z < Driveway.Z_KERB - 0.003 and fb.position.y < Driveway.GRADE \
				and fb.end.x > Driveway.CENTRE_X - Driveway.WIDTH * 0.5 and fb.position.x < Driveway.CENTRE_X + Driveway.WIDTH * 0.5:
			into_slab += 1
		skirt_open = maxi(skirt_open, _kerb_skirt_verts(slab))
		await get_tree().process_frame
	await _until(func() -> bool: return not runner.is_busy() or drive.form_is_stripped(3), "the kerb board comes off")
	_check(peg_first, "its pegs are drawn up before the board lifts")
	_check(tipped_out and into_slab == 0, "the board is prised OUT from the slab's edge, never into it (%d frames in)" % into_slab)
	_check(skirt_before == 0 and skirt_open >= Driveway.CELLS_X * 2,
		"and the clean face of the new slab is drawn where it stood (%d -> %d skirt vertices)" % [skirt_before, skirt_open])
	await _until(func() -> bool: return not runner.is_busy(), "the kerb board's beat")
	_check(drive.bank_cut(1) < 0.05 and drive.bank_cut(2) > 0.9 and drive.bank_cut(3) > 0.9,
		"the earth goes back against that end only (%.2f, sides %.2f / %.2f)" % [drive.bank_cut(1), drive.bank_cut(2), drive.bank_cut(3)])
	var lay_box := form3.global_transform * form3.get_aabb()
	var flat := absf(form3.global_basis.y.normalized().dot(Vector3.UP)) < 0.1
	var off_pad := lay_box.end.x < Driveway.CENTRE_X - Driveway.WIDTH * 0.5 - 0.2 \
		or lay_box.position.x > Driveway.CENTRE_X + Driveway.WIDTH * 0.5 + 0.2 \
		or lay_box.position.z > Driveway.Z_KERB + 0.2
	var hits_cone := false
	for cone in [cone_l, cone_r]:
		if cone != null and main._world_box(cone).intersects(lay_box):
			hits_cone = true
	_check(form3.visible and flat and lay_box.position.y > -0.005 and lay_box.position.y < 0.02 and off_pad and not hits_cone,
		"and the board lies flat on the grass off the pad, clear of the cones (%s)" % str(lay_box))
	# Its pegs read off the pegs: over the laid board, lying down, on its top -
	# a peg left standing in the trench fails all three.
	var on_it := 0
	var peg_at := []
	var grown := lay_box.grow(0.3)
	for p in drive.stakes_of_form(3):
		var pn := drive.find_child("Stake_3_%d" % (p - 8), false, false) as Node3D
		if pn == null:
			continue
		var g := pn.global_transform
		peg_at.append(g.origin)
		var over := g.origin.x > grown.position.x and g.origin.x < grown.end.x \
			and g.origin.z > grown.position.z and g.origin.z < grown.end.z
		var lying := absf(g.basis.y.normalized().dot(Vector3.UP)) < 0.2
		var on_top := g.origin.y > lay_box.end.y and g.origin.y - lay_box.end.y < 0.06
		if pn.visible and over and lying and on_top:
			on_it += 1
	_check(on_it == 2, "its two pegs laid ON it, lying down (%d; %s)" % [on_it, str(peg_at)])
	var footway_hit := 0
	for n in main.find_children("Footway", "MeshInstance3D", false, false):
		if main._world_box(n as Node3D).intersects(lay_box):
			footway_hit += 1
	_check(footway_hit == 0, "and it lies on the grass, not inside the footway (%d)" % footway_hit)
	_check(runner.progress == prog + 1, "one stop on the bar (%d -> %d)" % [prog, runner.progress])
	# The left board by its LINE, far from its ring: the thing under the finger.
	var home1 := drive.form_home(1)
	var line_px := main.camera.unproject_position(Vector3(home1.x, Driveway.GRADE, Driveway.Z_APRON + 1.5))
	var ring_far := rings.pick_nearest(main.camera, line_px, main._reach_px(), false, main.config.tap_reach_m, main._finger_px()) == 0
	_check(ring_far and main._board_under(line_px, drive.open_strip_forms()) == 1, "a press on the left board far from its ring is a press on that board")
	main._press(line_px, true)
	main._press(line_px, false)
	var form1 := drive.find_child("Form_1", false, false) as MeshInstance3D
	var pad_left := Driveway.CENTRE_X - Driveway.WIDTH * 0.5
	var over_slab := 0
	var tip1 := false
	while runner.is_busy():
		var b1 := form1.global_transform * form1.get_aabb()
		if b1.end.x > pad_left + 0.003 and b1.position.y < Driveway.GRADE:
			over_slab += 1
		if form1.global_basis.y.x < -0.05:
			tip1 = true
		await get_tree().process_frame
	_check(drive.form_is_stripped(1) and tip1 and over_slab == 0,
		"and it comes off outward, never into the slab (%d frames in)" % over_slab)
	# The last board: the done note is the tada's, after the hold.
	var dones := int(main.sfx.played_count.get("done", 0))
	_check(_tap_ring(2), "the right board's ring can be pressed")
	var landed := await _until(func() -> bool: return drive.form_is_stripped(2), "the last board lands")
	await _frames(2)
	_check(landed and main.sfx.last_played == "thunk", "the last board lands with a knock (%s)" % main.sfx.last_played)
	var last_i := main.job.steps.size() - 1
	var done_seen := await _until(func() -> bool: return _job_done == 1, "the job reports done")
	_check(done_seen and int(main.sfx.played_count.get("done", 0)) == dones, "no done note on the last board: its done is the tada")
	var held_ms := Time.get_ticks_msec() - int(_step_done_ms.get(last_i, 0))
	_check(_step_done_ms.has(last_i) and held_ms >= int((main.config.phase_hold - 0.05) * 1000.0),
		"the picture holds on the stripped forms before the tada (%d ms)" % held_ms)
	await _frames(3)
	_check(main.sfx.last_played == "tada" and hud.flash_text() == "YAY!" and runner.progress == TOTAL_STOPS,
		"then the tada and the YAY!, the bar full (%s, %s, %d of %d)" % [main.sfx.last_played, hud.flash_text(), runner.progress, TOTAL_STOPS])
	_check(drive.forms_stripped() and drive.bank_cut(0) < 0.05 and drive.bank_cut(2) < 0.05 and drive.bank_cut(3) < 0.05,
		"every board off and every trench turfed over")
	# The three laid boards lie on the grass - none in the footway, none inside
	# another - read off their own boxes.
	var laid: Array[AABB] = []
	for bi in [1, 2, Driveway.KERB_BOARD]:
		var fb := drive.find_child("Form_%d" % bi, false, false) as MeshInstance3D
		laid.append(fb.global_transform * fb.get_aabb())
	var bad := 0
	for a in range(laid.size()):
		for n in main.find_children("Footway", "MeshInstance3D", false, false):
			if main._world_box(n as Node3D).intersects(laid[a]):
				bad += 1
		for c in range(a + 1, laid.size()):
			if laid[a].intersects(laid[c]):
				bad += 1
	_check(bad == 0, "the stripped boards lie side by side on the grass, clear of the footway and of each other (%d overlaps)" % bad)


## How many of the slab's vertices stand on the kerb edge below the top: the
## face drawn where the kerb board stood.
func _kerb_skirt_verts(slab: MeshInstance3D) -> int:
	if slab == null or slab.mesh == null or slab.mesh.get_surface_count() == 0:
		return 0
	var verts: PackedVector3Array = slab.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var n := 0
	for v in verts:
		if absf(v.z - Driveway.Z_KERB) < 0.005 and v.y < Driveway.BASE_TOP + 0.005:
			n += 1
	return n


# --- Phase 5b: the steel ----------------------------------------------------------------------------

func _phase_rebar() -> void:
	print("--- 5b. the rebar ---")
	var went := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "rebar_lay", "the rebar step")
	_check(went, "the form is closed and the steel is next")
	_check(runner.current_step().shot == "BARS", "the rebar has its own shot")
	_check(runner.waiting_for_tap(), "and one tap is one bar")
	_check(drive.chairs_shown(), "the chairs are down first, all of them")
	# The four long bars first, all four ringed, any order.
	_check(rings.count() == 4, "four rings, one on each long bar's place (%d)" % rings.count())
	await _settled()
	_check(_all_rings_on_screen(), "and every one of them is inside the frame")
	# From the LOW eye every WAITING long bar is still seen against the base,
	# inside the forms - at its ring and a stride nearer the eye (the session-4
	# verification pass: at a 6 cm lift, fanned outward, the outer two lay along
	# the form boards' tops in this picture). Where the eye's ray through the bar
	# meets the base.
	var inside_worst := INF
	var cam_p := main.camera.global_position
	for bi in range(1, 5):
		var bar_node := drive.find_child("Bar_%d" % bi, false, false) as Node3D
		if bar_node == null:
			inside_worst = -1.0
			continue
		for p: Vector3 in [drive.bar_wait_point(bi), bar_node.to_global(Vector3(0.0, 0.0, 1.7))]:
			var tr := (Driveway.BASE_TOP - cam_p.y) / minf(p.y - cam_p.y, -0.001)
			var hit_x := cam_p.x + (p.x - cam_p.x) * tr
			var margin := minf(hit_x - (Driveway.CENTRE_X - Driveway.WIDTH * 0.5),
				(Driveway.CENTRE_X + Driveway.WIDTH * 0.5) - hit_x)
			inside_worst = minf(inside_worst, margin)
	_check(inside_worst >= 0.05,
		"from the long bars' low eye every waiting bar is seen against the base, inside the forms (%.2f m to spare)"
		% inside_worst)
	for i in [3, 1, 4, 2]:
		_check(_tap_ring(i), "bar %d's ring can be pressed (out of order)" % i)
		if i == 3:
			# The landing is an event (4.7): the bar FALLS, clangs and bounces
			# twice on its chairs before it rests, and it leaves the chairs slower
			# than it hit them - one gravity. Watched every frame, wall-clock.
			var bar3 := drive.find_child("Bar_3", false, false) as Node3D
			var land := drive.bar_landing(3)
			var h1: float = land["h1"]
			var h2: float = land["h2"]
			var hop_hi := 0.0
			var rises := 0
			var was_up := false
			var samples: Array[Vector2] = []
			var contact_us := -1
			while runner.is_busy():
				if bar3 != null:
					var dy := bar3.position.y - drive.bar_home(3).y
					var now_us := Time.get_ticks_usec()
					samples.append(Vector2(float(now_us) / 1e6, dy))
					if drive.bar_is_in(3):
						if contact_us < 0:
							contact_us = now_us
						hop_hi = maxf(hop_hi, dy)
						if dy > h2 * 0.5 and not was_up:
							rises += 1
						was_up = dy > h2 * 0.5
				await get_tree().process_frame
			var rest_dy := (bar3.position.y - drive.bar_home(3).y) if bar3 != null else 1.0
			# The speed over at least 30 ms either side of contact: from the contact
			# sample to the first sample that far away. (A window that happened to
			# hold two samples a fraction of a millisecond apart after a frame hitch
			# read 15 m/s off a 1 cm hop in the fifth session's first run.)
			var impact := _slope(samples, float(contact_us) / 1e6 - 0.03, float(contact_us) / 1e6)
			var takeoff := _slope(samples, float(contact_us) / 1e6, float(contact_us) / 1e6 + 0.03)
			_check(rises == 2 and hop_hi > h1 * 0.7 and hop_hi < h1 * 1.2 and absf(rest_dy) < 0.0005,
				"a long bar lands with two bounces on its chairs and comes to rest (%d hops, %.1f cm high of %.1f, %.1f mm off)"
				% [rises, hop_hi * 100.0, h1 * 100.0, rest_dy * 1000.0])
			_check(impact < -0.05 and takeoff > 0.0 and takeoff <= -impact,
				"and it leaves the chairs slower than it hit them (down %.2f m/s, up %.2f m/s)" % [-impact, takeoff])
		await _until(func() -> bool: return not runner.is_busy(), "bar %d lands" % i)
		_check(drive.bar_is_in(i), "and bar %d is the one that went down" % i)
		if i == 1:
			_save_is("rebar_lay", 1, 2, [1, 3], "after bars 3 and 1")
			_rebar_doc = SaveGame.load_data()
		if i == 4:
			# Three long bars on their chairs, the eye still low on them: a chair
			# stands on a LEG, not a flat orange square, with daylight under the
			# laid bar (4.6) - bar 3's chair under the fifth cross bar's place.
			var ch := drive.find_child("Chair_3_5", false, false) as Node3D
			var post := 0.0
			var foot := 0.0
			var under := 0.0
			var fr_b := main.camera.get_viewport().get_visible_rect().size
			if ch != null:
				var cp := ch.global_position
				post = _px_rows(cp + Vector3(0.0, Driveway.CHAIR_H * 0.5 - 0.008, 0.0),
					cp + Vector3(0.0, -Driveway.CHAIR_H * 0.5 + 0.008, 0.0))
				foot = _px_rows(cp + Vector3(0.0, -Driveway.CHAIR_H * 0.5 + 0.008, 0.055),
					cp + Vector3(0.0, -Driveway.CHAIR_H * 0.5 + 0.008, -0.055))
				var bar3n := drive.find_child("Bar_3", false, false) as Node3D
				var under_at := Vector3(drive.bar_home(3).x, bar3n.global_position.y - Driveway.BAR_T * 0.5, cp.z)
				under = _px_rows(under_at, Vector3(under_at.x, Driveway.BASE_TOP, under_at.z))
			# In thousandths of the frame's height, so a 4:3 run measures the same.
			var post_k := post * 1000.0 / fr_b.y
			var under_k := under * 1000.0 / fr_b.y
			_check(ch != null and _on_screen(ch.global_position) and main.rig.current_shot() == CameraRig.BARS \
				and drive.current_bar_group() == 0 and post_k >= 12.0 and post >= 0.6 * foot and under_k >= 16.0,
				"from the long bars' low eye a laid bar's chair stands on a leg, daylight under the bar (post %.1f px, foot %.1f px, gap %.1f px)"
				% [post, foot, under])
	_check(drive.bars_in() == 4, "the four long bars are on their chairs (%d)" % drive.bars_in())
	# A bar on its chairs sits UP off the base - in the middle of the slab, not on
	# the ground. That is the lesson of the phase.
	var lift := drive.bar_home(1).y - Driveway.BASE_TOP
	_check(lift > 0.02 and lift < (Driveway.GRADE - Driveway.BASE_TOP) * 0.8,
		"and a long bar sits up off the base, inside the slab (%.3f m up)" % lift)
	# Then the cross bars in PAIRS, the eye stepping down the drive.
	var seen: Array[Vector3] = []
	var laid := 0
	while drive.bars_in() < 12 and laid < 20:
		if not await _until(func() -> bool: return runner.waiting_for_tap() and not runner.is_busy(),
				"the next bar"):
			break
		var g := drive.current_bar_group()
		var open := drive.open_bars_in(g)
		if open.is_empty():
			break
		_check(rings.count() == open.size(), "a ring on each bar of the pair (%d of %d)" % [rings.count(), open.size()])
		var i: int = open[open.size() - 1]
		_check(_tap_ring(i), "bar %d's ring can be pressed" % i)
		if laid == 0:
			# The first cross bar (4.7): clang at contact, its ties NOT yet on;
			# then, once it has bounced and settled, the four ties pop on one
			# after another down the bar, near end first, each with a click.
			var bar_n := drive.find_child("Bar_%d" % i, false, false) as Node3D
			var contact_ms := -1
			var ties_at_contact := 0
			var clang := false
			var last_hop_ms := -1
			var mine := drive.bar_ties(i)
			var popped_ms: Array[int] = []
			for t in mine:
				popped_ms.append(-1)
			var clicks0 := int(main.sfx.played_count.get("click", 0))
			while runner.is_busy():
				var now := Time.get_ticks_msec()
				# The clang within a frame or two of contact (`_ease` reports its
				# k = 1 one frame before it returns to the verb).
				if contact_ms >= 0 and not clang and main.sfx.last_played == "rebardrop" \
						and now - contact_ms <= 60:
					clang = true
				if drive.bar_is_in(i) and contact_ms < 0:
					contact_ms = now
					clang = main.sfx.last_played == "rebardrop"
					for t in drive.bar_ties(i):
						if t.visible and t.scale.x > 0.5:
							ties_at_contact += 1
					mine = drive.bar_ties(i)
					popped_ms.resize(mine.size())
					popped_ms.fill(-1)
				if contact_ms >= 0 and bar_n != null and bar_n.position.y - drive.bar_home(i).y > 0.004:
					last_hop_ms = now
				for k in range(mine.size()):
					if popped_ms[k] < 0 and mine[k].visible and mine[k].scale.x > 0.5:
						popped_ms[k] = now
				await get_tree().process_frame
			var in_turn := mine.size() == 4
			var gaps_ok := true
			for k in range(mine.size()):
				if popped_ms[k] < 0 or popped_ms[k] < last_hop_ms:
					in_turn = false
				if k > 0 and popped_ms[k] >= 0 and popped_ms[k - 1] >= 0:
					var gap := popped_ms[k] - popped_ms[k - 1]
					if gap < 20 or gap > 140:
						gaps_ok = false
					if (mine[k] as Node3D).global_position.x <= (mine[k - 1] as Node3D).global_position.x:
						in_turn = false
			_check(clang and ties_at_contact == 0,
				"a cross bar clangs on contact with its ties still to come (%d on at contact)" % ties_at_contact)
			var clicks := int(main.sfx.played_count.get("click", 0)) - clicks0
			_check(in_turn and gaps_ok and clicks == mine.size(),
				"then, settled, its four ties pop on in turn down the bar, each with a click (%s ms after contact, %d clicks)"
				% [str(popped_ms.map(func(v: int) -> int: return v - contact_ms)), clicks])
		await _until(func() -> bool: return not runner.is_busy(), "bar %d" % i)
		laid += 1
		if drive.current_bar_group() != g and drive.bars_in() < 12:
			await _settled()
			seen.append(main.camera.global_position)
	_check(drive.bars_in() == 12, "all twelve bars are down (%d)" % drive.bars_in())
	_check(drive.rebar_done(), "and the driveway calls its steel done")
	var stood := 0
	for i in range(1, seen.size()):
		if seen[i].distance_to(seen[i - 1]) < 0.4:
			stood += 1
	_check(seen.size() >= 3 and stood == 0,
		"the eye stepped down the drive with the pairs (%d pictures, %d the same place)" % [seen.size(), stood])
	# Tied where they cross: a tie is visible at every crossing once its cross bar is down.
	var ties := 0
	for n in drive.find_children("Tie_*", "MeshInstance3D", false, false):
		if (n as Node3D).visible and (n as Node3D).scale.is_equal_approx(Vector3.ONE):
			ties += 1
	_check(ties == 32, "and tied at every crossing, every tie whole (%d of 32)" % ties)


# --- Phase 6: the pour ----------------------------------------------------------------------------

func _phase_pour() -> void:
	print("--- 6. the pour ---")
	var waiting := await _until(func() -> bool: return runner.waiting_button() == "call", "the button")
	_check(waiting, "the green button asks for the mixer")
	var tipper_gone := main.machine("DumpTruck")
	_check(tipper_gone != null and not tipper_gone.visible and not tipper_gone.is_driving(),
		"the tipper is gone before the mixer is called")
	_check(drive.chunks_left() == 0 and not main.sfx.is_looping("leave"),
		"the heap went with it and its idle stopped (%d chunks shown)" % drive.chunks_left())
	hud.simulate_button("call")
	var mixer_in := main.machine("ConcreteTruck")
	await _until(func() -> bool: return mixer_in.visible \
		and _on_screen(main._world_box(mixer_in).get_center()) and mixer_in.is_driving(), "the mixer in the picture")
	await _frames(5)
	# A finger that lands on the mixer while it comes down the street and STAYS
	# there backs it in the moment it stops - no second press (the plan's 1.8).
	var mixer_px := main.camera.unproject_position(main._world_box(mixer_in).get_center())
	var kept_f := main._press(mixer_px, true)
	_check(kept_f and main.sfx.last_played == "horn",
		"a finger pressed on the coming mixer honks it and is kept (%s)" % main.sfx.last_played)
	var carried := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "back_mixer" and runner.held, "the finger backs the mixer in")
	_check(carried, "and the same finger, still down when it stops, backs it to the kerb")
	var mroute := main.back_route("ConcreteTruck", main.street_stop("ConcreteTruck"))
	var mdir := mroute[0] - mroute[1]
	var mwant := rad_to_deg(atan2(mdir.x, mdir.z))
	_check(absf(wrapf(rad_to_deg(mixer_in.rotation.y) - mwant, -180.0, 180.0)) < 2.0,
		"already turned the way it backs, so the first held frame does not snap it (%.1f vs %.1f deg)"
		% [rad_to_deg(mixer_in.rotation.y), mwant])
	await get_tree().create_timer(0.5).timeout
	_check(main.sfx.is_looping("beeper") and mixer_in.path_k() > 0.0, "the mixer beeps while it backs to the kerb")
	await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "pour_chute", "the pour beat")
	var mixer := main.machine("ConcreteTruck")
	var eye_moving := main.rig.is_moving()
	main._press(mixer_px, false)
	# The truck stays drawn while the eye flies down to the chute and goes only
	# once it has arrived (the improvement plan's 0.6): a truck that blinked out
	# of the wide picture left its chute hanging in the air, a teleport in front
	# of the child.
	_check(eye_moving, "the eye is still on its way down to the chute")
	_check(_drawn(mixer, "Drum") > 0, "and the truck is drawn until it gets there")
	_check(mixer.visible, "the mixer is on site")
	# ON THE ROAD, tail to the drive, and its rearmost tyre past the kerb: the
	# steel is down and no wheel goes over it (DESIGN 2a).
	_check(absf(rad_to_deg(mixer.rotation.y)) < 8.0,
		"nose to the far kerb, tail to the drive (%.0f deg)" % rad_to_deg(mixer.rotation.y))
	var tyre := mixer.global_position.z - mixer.rear_overhang()
	_check(tyre > SiteMain.KERB_Z - 0.02,
		"standing on the ROAD with its rear tyre past the kerb, never on the steel (tyre z %.2f, kerb %.2f)"
			% [tyre, SiteMain.KERB_Z])
	# And watched for the whole pour and the whole rake: no wheel on the pad.
	_on_pad_frames[0] = 0
	_watch_pad = true
	_watch_wheels(mixer)
	for key: String in ["up", "down", "left", "right"]:
		_check(hud.pad_visible(key), "the %s pad is up for the chute" % key)
	await _settled()
	# The user's visual trick: the truck is out of the way and the chute is not.
	_check(_drawn(mixer, "Drum") == 0, "the truck itself is not drawn during the pour")
	_check(_drawn(mixer, "Chute") > 0, "but the chute the child is steering is")
	# Nor its beacon, nor the light that hangs under it (4.5): an amber glow over
	# the chute with no truck would be a light from nowhere.
	var beacon_n := mixer.node_for("Beacon")
	var beacon_l := beacon_n.get_node_or_null("BeaconLight") as Node3D if beacon_n != null else null
	_check(beacon_n != null and beacon_l != null and not beacon_n.is_visible_in_tree() and not beacon_l.is_visible_in_tree(),
		"and neither is the mixer's beacon or its light")
	var view := main.get_node_or_null("PourView") as Node3D
	_check(view != null, "and the camera hangs off the pour, not off the chute")
	# Right up by the BACK of the chute, on the truck's side of it: the truck has
	# to be behind the camera, or the child can see that it is missing.
	var spout := mixer.spout_world()
	var eye := main.camera.global_position
	_check(eye.z > spout.z + 0.8,
		"the camera is behind the chute head (eye z %.2f, spout z %.2f)" % [eye.z, spout.z])
	var head := mixer.node_for("Chute")
	var gap := eye.distance_to(head.global_position) if head != null else 99.0
	# Within about two chute-lengths of its head. The number is a floor, not a
	# composition: it is what stops this drifting back out to the nine metres it
	# was watched from before, where the whole truck was in shot.
	_check(gap < 3.4, "right up at the chute's own head (%.2f m from it)" % gap)
	_check(_on_screen(spout), "with the spout itself in the picture")
	# Nothing of the truck is DRAWN, so nothing of it can be in shot - which is
	# the whole trick, and it is asserted above by the mesh counts.
	# Swinging the chute must not drag the camera sideways or shunt it along the
	# drive: the pads have to mean what they say.
	# The idle hint (round 7: it has to be INSIDE the picture; round 12: only on
	# a cell that LOOKS short, under half). Checked NOW, while the band is still
	# nearly empty: with the chute parked the whole band is over half within four
	# seconds of pouring, and after that the rule rightly shows nothing - which
	# is where this check used to stand, passing only when the frames happened
	# to run at the right speed. The delay is shortened for the test the way the
	# white arrow's is above; the beat reads it every frame.
	var pointer := main.get_node_or_null("Pointer") as SpotRings
	var hint_delay_was: float = main.config.chute_hint_delay
	main.config.chute_hint_delay = 0.8
	await get_tree().create_timer(1.3).timeout
	await _frames(3)
	_check(_hint_on_screen(), "after a pause the pour's hint stands on a short cell, inside the frame")
	main.config.chute_hint_delay = hint_delay_was
	# And the white MIME stands on the PAD that would take the pour there,
	# miming a hold (the plan's 2.1): the one beat that had no teacher.
	var mime_delay_was: float = hud.hint_delay
	hud.hint_delay = 0.3
	await get_tree().create_timer(0.7).timeout
	var pad_key: String = main._pour_hint_pad()
	var prect := hud.pad_rect(pad_key)
	_check(hud.hint_visible() and hud.hint_kind() == SiteHud.Hint.HOLD,
		"the white mime is up over a pad, miming a hold (%s)" % pad_key)
	_check(prect.has_area() and hud.hint_position().distance_to(prect.get_center()) < prect.size.x * 1.2,
		"on the %s pad, the one that takes the pour toward the emptiest cell" % pad_key)
	hud.hint_delay = mime_delay_was
	# A tap on the picture during the pour is answered by that pad kicking.
	var slab_px := main.camera.unproject_position(Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_KERB - 2.0))
	main._press(slab_px, true)
	main._press(slab_px, false)
	var pad_ctl: Control = hud._pads.get(pad_key)
	_check(main.sfx.last_played == "pop" and pad_ctl != null and pad_ctl.scale.x > 1.05,
		"and a tap on the picture is heard and kicks that pad")
	var was_view := view.position.z
	hud.press_pad("left", true)
	await _frames(10)
	_check(pointer != null and not pointer.lit(), "and a pad press takes it away")
	_check(not hud.hint_visible(), "the white mime too")
	await _frames(80)
	hud.press_pad("left", false)
	await _frames(20)
	_check(absf(view.position.z - was_view) < 0.25,
		"swinging the chute leaves the camera where it is (%.2f -> %.2f)"
			% [was_view, view.position.z])
	await _frames(90)
	_check(drive.fill_fraction() > 0.0, "concrete is going in (%.3f)" % drive.fill_fraction())
	_save_is("pour_chute", 1, 0, [], "part way through the pour, a hold is kept at its start:")
	# The control the user asked for: forward and backwards up the drive.
	var start_z := mixer.global_position.z
	var view_z := view.position.z if view != null else 0.0
	hud.press_pad("up", true)
	await _frames(200)
	hud.press_pad("up", false)
	var out_z := mixer.global_position.z
	# UP means UP the picture (the plan's 2.1): the truck creeps back toward
	# the kerb and the pour goes up the drive, toward the garage.
	_check(out_z < start_z - 0.2,
		"the UP pad takes the pour UP the drive, toward the garage (%.2f -> %.2f)" % [start_z, out_z])
	_check(view != null and view.position.z < view_z - 0.15,
		"and the camera walked up with it (%.2f -> %.2f)" % [view_z, view.position.z if view != null else 0.0])
	hud.press_pad("down", true)
	await _frames(200)
	hud.press_pad("down", false)
	_check(mixer.global_position.z > out_z + 0.2,
		"and DOWN brings it back toward the kerb (%.2f -> %.2f)" % [out_z, mixer.global_position.z])
	# Now fill the kerb end the way a competent pair would: look at where the
	# band the chute can reach is emptiest, swing the chute toward it and creep the
	# truck so the spout is over it. A blind sweep was not a test of anything - it
	# wasted most of the load on the grass past the kerb and then reported the
	# mechanic broken.
	var reach := mixer.global_position.z - mixer.pour_point_world(Driveway.GRADE).z
	var band_from := main.mixer_stand_z() - reach - 0.35
	var swept := 0
	while drive.band_fraction(band_from) < main.config.band_done and swept < 420:
		var want: Vector3 = drive.emptiest_in_band(band_from)
		var dx := want.x - Driveway.CENTRE_X
		var dz := want.z - mixer.pour_point_world(Driveway.GRADE).z
		if dx < -0.25:
			hud.press_pad("left", true)
		elif dx > 0.25:
			hud.press_pad("right", true)
		if dz > 0.35:
			hud.press_pad("down", true)
		elif dz < -0.35:
			hud.press_pad("up", true)
		await _frames(24)
		for key: String in ["up", "down", "left", "right"]:
			hud.press_pad(key, false)
		swept += 1
	var filled := drive.band_fraction(band_from) >= main.config.band_done
	_check(filled, "the kerb end of the form filled (%.3f after %d sweeps)" % [drive.band_fraction(band_from), swept])
	if not filled:
		# WHICH cells are dry, not just that some are.
		print(drive.fill_report())
	_check(drive.fill_fraction() < 0.75,
		"and the rest of the form is still waiting for the rake (%.2f of it full)" % drive.fill_fraction())
	await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb != "pour_chute", "the pour ends")
	_check(runner.current_step() != null and runner.current_step().verb == "rake_pull",
		"and the come-along is next")


# --- Phase 6b: the come-along ------------------------------------------------------------------------

func _phase_rake() -> void:
	print("--- 6b. the come-along ---")
	var mixer := main.machine("ConcreteTruck")
	_check(runner.current_step().shot == "PULL", "the rake has its own shot, from the garage door")
	_check(runner.waiting_for_hold(), "and it is dragged")
	await _settled()
	_check(_drawn(mixer, "Drum") == 0, "the truck is still not drawn")
	_check(main.camera.global_position.z < Driveway.Z_APRON + 0.5,
		"the eye stands at the garage end looking down the drive (z %.2f)" % main.camera.global_position.z)
	var apron_before := drive.cell_fill(2, 0)
	_check(apron_before < 0.02, "nothing has reached the apron end yet (%.3f)" % apron_before)
	# Dragging at the FAR end draws on the chute's heap at the kerb, from
	# anywhere (the user's third playtest: "it was hard to tell where I was
	# supposed to spread it"): the sandy apron cell goes grey under the finger.
	main.set_work_cursor(Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 0.4))
	runner.hold(true)
	await _frames(60)
	_check(drive.cell_fill(2, 0) > 0.01,
		"raking at the apron draws concrete up from the heap at the kerb (%.3f)" % drive.cell_fill(2, 0))
	# The finger up and still: the hint has to be inside this shot too.
	runner.hold(false)
	main.clear_work_cursor()
	await get_tree().create_timer(main.config.chute_hint_delay + 0.6).timeout
	await _settled()
	_check(_hint_on_screen(), "and after a pause the come-along's hint is inside the frame")
	# A competent child: keep the rake at the FRONT of the concrete and it comes
	# up the form a stroke at a time, as fast as the chute supplies it.
	var reach: int = main.config.rake_reach
	var pulled := false
	var pull_started := Time.get_ticks_msec()
	for frame in range(FRAME_CAP):
		var front := drive.rake_front_world(reach)
		main.set_work_cursor(Vector3(front.x, Driveway.GRADE, front.z - 0.2))
		runner.hold(true)
		await get_tree().process_frame
		if drive.fill_fraction() >= main.config.pour_done:
			pulled = true
			break
	_check(pulled, "pulling from the front fills the whole form (%.3f)" % drive.fill_fraction())
	if not pulled:
		print(drive.fill_report())
	# The finger is the only bottleneck (the plan's 2.4): the truck supplies
	# faster than the rake draws, so a competent pull is seconds, not a trickle.
	var pull_s := float(Time.get_ticks_msec() - pull_started) / 1000.0
	_check(pull_s < 25.0, "and it never waited on the truck (%.1f s of pulling)" % pull_s)
	_check(drive.cell_fill(2, 0) > (Driveway.GRADE - Driveway.BASE_TOP) * 0.9,
		"including the apron end (%.3f)" % drive.cell_fill(2, 0))
	runner.hold(false)
	main.clear_work_cursor()
	await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb != "rake_pull", "the rake ends")
	_watch_pad = false
	_check(_on_pad_frames[0] == 0,
		"and the mixer never put a wheel on the pad (%d frames)" % _on_pad_frames[0])
	# It comes back FADED IN over the eye's ease out to the wide (the improvement
	# plan's 0.6): drawn from the first frame of the leave but see-through until
	# the eye has arrived, never popped in whole.
	_check(main.rig.is_moving() and _drawn(mixer, "Drum") > 0 and _alpha_of(mixer, "Drum") < 0.5,
		"the truck fades in while the eye eases out to the wide (alpha %.2f)" % _alpha_of(mixer, "Drum"))
	await _settled()
	await _frames(4)
	_check(_drawn(mixer, "Drum") > 0 and _alpha_of(mixer, "Drum") > 0.99,
		"and is whole again once it has arrived, before it leaves (alpha %.2f)" % _alpha_of(mixer, "Drum"))


# --- Phases 7 to 10: the finishing -----------------------------------------------------------------

func _phase_finishing() -> void:
	print("--- 7-10. the finishing ---")
	var wet := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "spray_water", "the water")
	_check(wet, "the mixer left and the hose is next")
	var mixer_out := main.machine("ConcreteTruck")
	_check(mixer_out != null and mixer_out.visible and mixer_out.is_driving(),
		"with the mixer still leaving in the background (3.2)")
	# It must do NOTHING where the finger has not been. That is the whole of the
	# user's ninth note: "get it all wet them selves, not just a basic click".
	_check(drive.water_coverage() < 0.01, "the slab starts dry everywhere (%.2f)" % drive.water_coverage())
	main.set_work_cursor(Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 0.5))
	runner.hold(true)
	await _frames(60)
	var corner := drive.water_coverage()
	_check(corner > 0.01 and corner < 0.30,
		"holding in one corner wets that corner and no more (%.2f)" % corner)
	# The hose has a HOSE (the improvement plan's 4.3): off the nozzle's own
	# stub, off the bottom of the picture, never across the water on screen - at
	# the far aim, and the near-right one where the bare stub used to show.
	await _settled()
	var hose_t := main.tool_node("hose")
	var fr_h := main.camera.get_viewport().get_visible_rect().size
	var joined := 0
	var off_bottom := 0
	var water_pts := 0
	var water_on_screen := 0
	var crossings := 0
	var aims: Array[Vector3] = [Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 0.5),
		Vector3(4.1, Driveway.GRADE, 4.3), Vector3(1.0, Driveway.GRADE, 4.1)]
	# `STUB_END` is where the nozzle's OWN model ends its hose stub: the GLB's
	# Body mesh has the stub's end ring there (read off the mesh, not the const).
	var stub_ring := 0
	var body := hose_t.find_child("Body", true, false) as MeshInstance3D if hose_t != null else null
	var model := hose_t.find_child("Model", false, false) as Node3D if hose_t != null else null
	if body != null and model != null and body.mesh != null:
		var to_model := model.global_transform.affine_inverse() * body.global_transform
		for s in range(body.mesh.get_surface_count()):
			var verts: PackedVector3Array = body.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v in verts:
				if (to_model * v).distance_to(HandTool.STUB_END) < HandTool.TRAIL_R * 1.5:
					stub_ring += 1
	_check(stub_ring >= 6, "the nozzle's model ends its hose stub where the hose leaves from (%d vertices on that ring)" % stub_ring)
	for aim in aims:
		main.set_work_cursor(aim)
		await _frames(3)
		if hose_t == null or not hose_t.trail_visible():
			continue
		var pts := hose_t.trail_points()
		if pts.size() >= 2 and pts[0].distance_to(hose_t.stub_world()) < 0.01:
			joined += 1
		var last := pts[pts.size() - 1]
		if not main.camera.is_position_behind(last) and main.camera.unproject_position(last).y > fr_h.y + 8.0:
			off_bottom += 1
		# The water's own line, ballistic now that the solid rod down the middle
		# of the spray is gone (2026-09-16). Counted, because a line that came
		# back with one point would leave `_screen_crossings` iterating an empty
		# range - green while measuring nothing.
		var wl := hose_t.water_line()
		water_pts = maxi(water_pts, wl.size())
		for wp in wl:
			if not main.camera.is_position_behind(wp):
				var sp := main.camera.unproject_position(wp)
				if sp.x > 0.0 and sp.x < fr_h.x and sp.y > 0.0 and sp.y < fr_h.y:
					water_on_screen += 1
		crossings += _screen_crossings(pts, wl)
	_check(joined == aims.size(), "the hose runs from the nozzle's own stub at every aim (%d of %d)" % [joined, aims.size()])
	_check(off_bottom == aims.size(), "and off the bottom of the picture (%d of %d)" % [off_bottom, aims.size()])
	_check(water_pts >= 6 and water_on_screen >= 2,
		"the water is drawn as a thrown LINE of drops, in the picture (%d points, %d on screen)"
		% [water_pts, water_on_screen])
	_check(crossings == 0, "and never across the water on screen (%d crossings)" % crossings)
	# The solid rod is GONE: no cylinder is drawn inside the spray.
	var rods := 0
	for n in hose_t.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh is CylinderMesh and String(mi.name).begins_with("JetSeg"):
			rods += 1
	_check(rods == 0, "and it is SPRAY, not a solid stream: no rod is drawn down the middle of it (%d)" % rods)
	# ONE finger owns the beat (the improvement plan's 0.3): a second finger
	# landing and lifting - a palm, a thumb holding the iPad - must neither take
	# the hose nor end the hold. Through the real input pipeline, with touch
	# INDICES, because which finger it was is decided before `_press` ever runs.
	runner.hold(false)
	main.clear_work_cursor()
	await _frames(2)
	var slab_at := Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 2.5)
	var slab_px := main.camera.unproject_position(slab_at)
	var lawn_px := main.camera.unproject_position(Vector3(Driveway.CENTRE_X - 4.0, 0.0, Driveway.Z_KERB - 1.0))
	_touch(0, slab_px, true)
	await _frames(3)
	_check(runner.held, "a real finger (index 0) on the slab holds the hose")
	var wet0 := drive.water_coverage()
	_touch(1, lawn_px, true)
	await _frames(2)
	_touch(1, lawn_px, false)
	await _frames(3)
	_check(runner.held, "a second finger landing and lifting does not end the hold")
	var under := main.work_point(Driveway.GRADE)
	_check(under != Vector3.INF and under.distance_to(slab_at) < 0.6,
		"and the hose is still under the first finger (%s)" % str(under))
	for i in range(1, 11):
		_drag(0, main.camera.unproject_position(slab_at + Vector3(0.0, 0.0, 0.35 * float(i))))
		await _frames(8)
	_check(drive.water_coverage() > wet0 + 0.01,
		"and dragging that finger wets more of the slab (%.3f -> %.3f)" % [wet0, drive.water_coverage()])
	_touch(0, slab_px, false)
	await _frames(2)
	_check(not runner.held, "and the hose stops when the finger that held it lifts")
	var all_wet := await _sweep(func() -> float: return drive.water_coverage())
	_check(all_wet, "sweeping the whole slab wets all of it (%.2f)" % drive.water_coverage())
	# Through the finished beat's HOLD the hose stays in the hands, hose and all:
	# flying the nozzle home dropped its hose in one frame in a still picture,
	# which a 4:3 iPad shows (the session-4 verification pass).
	var hold_frames := 0
	var hose_dropped := 0
	while runner.current_step() != null and runner.current_step().verb == "spray_water" and hold_frames < 3000:
		if hose_t != null and hose_t.visible and not hose_t.trail_visible():
			hose_dropped += 1
		hold_frames += 1
		await get_tree().process_frame
	_check(hose_dropped == 0 and hold_frames > 1,
		"the hose stays in the hands through the finished beat's hold (%d frames, %d without its hose)"
		% [hold_frames, hose_dropped])
	var screed := await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "screed_pull", "the screed")
	_check(screed, "and the beat ended when it was covered")
	var hose_after := main.tool_node("hose")
	_check(hose_after != null and not hose_after.is_visible_in_tree(), "and the nozzle and its hose are put away with the next beat")
	_check(not drive.is_flat(), "the poured slab is NOT flat before the screed")
	# The board is DRAGGED down the drive (fourth playtest): a finger held still
	# does nothing, a finger walked from the apron to the kerb strikes it off.
	# A finger resting three metres down the slab has no hold of the board.
	main.set_work_cursor(Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 3.0))
	runner.hold(true)
	await _frames(40)
	_check(drive.struck_fraction() < 0.02,
		"a finger resting ahead of the board does not move it (%.2f struck)" % drive.struck_fraction())
	runner.hold(false)
	await _frames(2)
	# A fast flick does not strike the slab in a frame: the board is grabbed at
	# the press and WALKS after the finger (the plan's 2.5).
	main.set_work_cursor(Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 0.2))
	runner.hold(true)
	await _frames(3)
	main.set_work_cursor(Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_KERB + 0.4))
	await _frames(2)
	_check(drive.struck_fraction() < 0.08,
		"a finger flicked to the kerb leaves the board walking behind it (%.2f struck)" % drive.struck_fraction())
	runner.hold(false)
	await _frames(2)
	var dragged := await _drag_along(
		Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 0.2),
		Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_KERB + 0.4),
		func() -> bool: return runner.current_step() != null \
			and runner.current_step().verb == "joint_cut")
	_check(dragged, "dragging the board to the kerb strikes the slab off and ends the beat")
	_check(drive.is_flat(), "the screed struck it off level")
	# A joint runs right across the drive, and the camera has to hold both ends.
	_check(runner.current_step().shot == "JOINT", "the joints have their own shot")
	# The groover's sled carries a saturated tool colour at dark steel's value,
	# with the steel under it (the improvement plan's 4.4): a dark-grey sled on a
	# grey slab was the least visible tool in the game. Read off the live tool.
	var jt := main.tool_node("jointer")
	var blade := (jt.find_child("Blade", true, false) as MeshInstance3D) if jt != null else null
	var paint := Color.BLACK
	var paint_w := 0.0
	var steel_w := 0.0
	if blade != null and blade.mesh != null:
		for s in range(blade.mesh.get_surface_count()):
			var bmat := blade.get_active_material(s) as BaseMaterial3D
			if bmat == null:
				continue
			# How wide the surface is across the sled: the steel RIM is the one
			# dark surface wider than the orange plate (the bead and the trailing
			# bit are 2 cm, and a dark bit alone once passed this check).
			var verts: PackedVector3Array = blade.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			var xmin := INF
			var xmax := -INF
			for v in verts:
				xmin = minf(xmin, v.x)
				xmax = maxf(xmax, v.x)
			var c := bmat.albedo_color
			if c.s > paint.s:
				paint = c
				paint_w = xmax - xmin
			if c.s < 0.25 and c.get_luminance() < 0.40:
				steel_w = maxf(steel_w, xmax - xmin)
	var rim := paint_w > 0.0 and steel_w > paint_w
	var orange := paint.h > 0.03 and paint.h < 0.12
	print("      groover sled: %s (h %.3f, s %.2f, luma %.2f), %.3f m wide; steel %.3f m wide"
		% [str(paint), paint.h, paint.s, paint.get_luminance(), paint_w, steel_w])
	_check(paint.s > 0.8 and orange and paint.get_luminance() > 0.20 and paint.get_luminance() < 0.42 and rim,
		"the groover's sled wears tool orange at dark steel's value, a steel rim proud of it (h %.3f, luma %.2f, rim %.3f > %.3f m)"
		% [paint.h, paint.get_luminance(), steel_w, paint_w])
	await _settled()
	var seen := _both_ends_visible(drive.joint_z(1))
	_check(seen, "which holds the whole width of the line (%s)" % ("yes" if seen else "no"))
	# Each joint is PULLED across, near form to far form - and a finger held
	# still at the far form cuts nothing (the hold is lifted between joints).
	for jn in [1, 2]:
		runner.hold(false)
		main.set_work_cursor(Vector3(Driveway.CENTRE_X + Driveway.WIDTH * 0.5 - 0.2, Driveway.GRADE, drive.joint_z(jn)))
		runner.hold(true)
		await _frames(40)
		_check(drive.joint_k(jn) < 0.02, "a finger resting at the far form does not cut joint %d (%.2f)" % [jn, drive.joint_k(jn)])
		runner.hold(false)
		await _frames(2)
		if jn == 2:
			# Grabbed at the press, the sled follows a finger that wanders off
			# the line mid-pull (the plan's 2.5).
			var x0 := Driveway.CENTRE_X - Driveway.WIDTH * 0.5
			main.set_work_cursor(Vector3(x0 + 0.15, Driveway.GRADE, drive.joint_z(jn)))
			runner.hold(true)
			await _frames(3)
			main.set_work_cursor(Vector3(x0 + 1.6, Driveway.GRADE, drive.joint_z(jn) + 1.2))
			await _frames(40)
			_check(drive.joint_k(jn) > 0.05,
				"a finger that wanders off the line after the grab still pulls the sled (%.2f)" % drive.joint_k(jn))
			runner.hold(false)
			await _frames(2)
		var pulled := await _drag_along(
			Vector3(Driveway.CENTRE_X - Driveway.WIDTH * 0.5 - 0.1, Driveway.GRADE, drive.joint_z(jn)),
			Vector3(Driveway.CENTRE_X + Driveway.WIDTH * 0.5 + 0.3, Driveway.GRADE, drive.joint_z(jn)),
			func() -> bool: return drive.joint_k(jn) >= 0.999)
		_check(pulled, "pulling the groover across cuts joint %d (%.2f)" % [jn, drive.joint_k(jn)])
	await _until(func() -> bool: return runner.current_step() != null \
		and runner.current_step().verb == "broom_finish", "the broom")
	_check(drive.joints_cut() == 2, "two control joints are cut (%d)" % drive.joints_cut())
	_check(drive.broom_coverage() < 0.01,
		"and the slab is unbrushed everywhere (%.2f)" % drive.broom_coverage())
	# THREE bays, one beat each, the eye beside the bay being brushed.
	_check(runner.current_step().count == drive.bay_count(),
		"one broom beat per bay (%d)" % runner.current_step().count)
	for b in range(1, drive.bay_count() + 1):
		var band := drive.bay_range(b)
		await _settled()
		var eye := main.camera.global_position
		_check(absf(eye.z - (band.x + band.y) * 0.5) < 1.2 and eye.x < Driveway.CENTRE_X - Driveway.WIDTH * 0.5,
			"the eye stands beside bay %d (%.1f, %.1f)" % [b, eye.x, eye.z])
		runner.hold(false)
		var swept := await _sweep_range(band.x + 0.3, band.y - 0.3,
			func() -> float: return drive.broom_coverage_in(band.x, band.y))
		_check(swept, "sweeping bay %d brushes it (%.2f)" % [b, drive.broom_coverage_in(band.x, band.y)])
		if b < drive.bay_count():
			var next_band := drive.bay_range(b + 1)
			_check(drive.broom_coverage_in(next_band.x, next_band.y) < 0.05,
				"and bay %d is still unbrushed (%.2f)" % [b + 1, drive.broom_coverage_in(next_band.x, next_band.y)])
			await _until(func() -> bool: return runner.done_in_step >= b or runner.finished, "bay %d ends" % b)
	await _until(func() -> bool: return runner.current_step() == null \
		or runner.current_step().verb != "broom_finish", "the broom finishes")
	runner.hold(false)
	main.clear_work_cursor()
	_check(drive.broomed(), "and the broom finish is on (%d lines)" % drive.broom_lines())
	var mixer_gone := main.machine("ConcreteTruck")
	_check(mixer_gone != null and not mixer_gone.visible and not main.sfx.is_looping("leave"),
		"and the mixer's background exit finished long ago, its idle stopped")


# --- The payoff -------------------------------------------------------------------------------------

func _the_payoff() -> void:
	print("--- the payoff ---")
	_check(_job_done == 1, "the job reported itself done once (%d)" % _job_done)
	_check(not SaveGame.exists(), "and the save is gone: nothing left to come back to")
	# Every phase the bar counts ended on the one "done" note, and only those:
	# the machine beats stay silent, the last beat's done is the tada (1.6).
	var wrong := 0
	var counted := 0
	for e in _done_notes:
		var i: int = e[0]
		var want: bool = main.job.steps[i].progress_weight > 0 and i < main.job.steps.size() - 1
		var rose := int(e[1]) > counted
		counted = int(e[1])
		if rose != want:
			wrong += 1
	_check(_done_notes.size() == main.job.steps.size() and wrong == 0,
		"every phase the bar counts ended on the 'done' note and only those (%d steps, %d wrong)"
		% [_done_notes.size(), wrong])
	_check(runner.progress == main.job.total_weight(),
		"the bar is full (%d of %d)" % [runner.progress, main.job.total_weight()])
	# The full bar is SEEN full through the tada and the look at the finished drive.
	await get_tree().create_timer(0.3).timeout
	_check(hud.chrome_alpha() > 0.9, "and it is seen full through the tada (%.2f)" % hud.chrome_alpha())
	_check(main.rig.current_shot() == CameraRig.WIDE, "on the wide the job opened on")
	# The kit goes at the CUT to the street (the verification pass: an ease to
	# STREET had the fence blink out with the eye still turning). Watched
	# frame by frame: the frame the fence disappears, the rig is standing
	# still and the shot is STREET.
	var fence_watch := main.get_node_or_null("Fence") as Node3D
	var cut_ok := false
	var cut_seen := false
	while fence_watch != null and not cut_seen:
		if not fence_watch.visible:
			cut_seen = true
			cut_ok = not main.rig.is_moving() and main.rig.current_shot() == CameraRig.STREET
		elif hud.next_visible():
			break
		await get_tree().process_frame
	_check(cut_seen and cut_ok, "the fence went at the cut to the street, with the rig standing still (%s)"
		% (main.rig.current_shot() if main.rig != null else "?"))
	_check(hud.chrome_alpha() < 0.05, "and the bar and hat are out of the picture by the cut (%.2f)" % hud.chrome_alpha())
	var boards_left := 0
	for bi in [1, 2, Driveway.KERB_BOARD]:
		if drive.form_shown(bi):
			boards_left += 1
	for pi in range(1, drive.stake_count() + 1):
		if drive.stake_shown(pi):
			boards_left += 1
	_check(boards_left == 0, "and the stripped boards and their pegs were carried off with the kit (%d left)" % boards_left)
	var cone_l := main.get_node_or_null("ConeL") as Node3D
	var cone_r := main.get_node_or_null("ConeR") as Node3D
	var parked := await _until(func() -> bool: return hud.next_visible(), "NEXT appears")
	_check(parked, "the car parked and NEXT came up")
	_check(not hud.home_visible(), "and the house stays off the screen - NEXT is the way on")
	_check(main.sfx.last_played == main.car_voice() and main.car_voice() == String(main.look["voice"]),
		"the car said thank-you in its own voice when it parked (%s)" % main.sfx.last_played)
	_check(cone_l != null and cone_r != null and not cone_l.visible and not cone_r.visible,
		"the cones were lifted out before the car turned in")
	var fence := main.get_node_or_null("Fence") as Node3D
	var tools_out := 0
	for kind: String in main.tools:
		if (main.tools[kind] as Node3D).visible:
			tools_out += 1
	_check(fence != null and not fence.visible and tools_out == 0,
		"and the fence and the tools went at the cut, not in front of the child (%d tools left out)" % tools_out)
	_check(main.car != null and main.car.visible, "there is a car on the new drive")
	if main.car != null:
		_car_parked_right("")
	_check(main.garage_door_k() < 0.1,
		"the garage is shut up for the night (%.2f)" % main.garage_door_k())
	# NEXT is the one thing pointed at: the gold arrow is gone and NEXT wears
	# the ring (the old "nothing points at anything" passed on a one-frame
	# transient before the level had pointed at NEXT).
	await _frames(2)
	_check(not hud.arrow_visible(), "the gold arrow is gone")
	_check(hud.aiming_at_button() and hud.ring_visible(), "and NEXT is the thing pointed at")
	# A miss is never silent, even now: a press off NEXT kicks NEXT and is heard.
	var away_px := Vector2(fr_payoff().x * 0.5, fr_payoff().y * 0.15)
	var heard: String = main.sfx.last_played
	main._payoff_press(_fake_touch(away_px, true))
	_check(main.sfx.last_played == "pop" and heard != "pop", "a press off NEXT during the payoff is heard (%s)" % main.sfx.last_played)


## The car on the drive is the visit's, parked by its nose clear of the garage
## door and inside the drive, in its own paint on a copy.
func _car_parked_right(which: String) -> void:
	var c := main.car
	var spot := drive.park_spot(c.nose_m())
	var off := Vector2(c.global_position.x - spot.x, c.global_position.z - spot.z).length()
	var box: AABB = main._world_box(c)
	# The lintel's OWN mesh: `_world_box` merges a node's children, and the lintel
	# is a mesh with none (it read z 0 and failed every car).
	var lintel := main.get_node_or_null("GarageLintel") as MeshInstance3D
	var door_face: float = (lintel.global_transform * lintel.mesh.get_aabb()).end.z if lintel != null else INF
	if main.play_seed == SiteLook.LEGACY_SEED:
		# Seed 0 parks where the hatchback always parked, to the millimetre.
		_check(Vector2(c.global_position.x - 2.6, c.global_position.z + 1.0).length() < 0.001,
			"%sseed 0 parks the hatchback exactly where it always parked (%s)" % [which, str(c.global_position)])
	_check(off < 0.1 and box.position.z >= door_face + 0.30 and box.end.z <= Driveway.Z_KERB \
		and box.position.x >= Driveway.CENTRE_X - Driveway.WIDTH * 0.5 - 0.05 and box.end.x <= Driveway.CENTRE_X + Driveway.WIDTH * 0.5 + 0.05,
		"%sthe %s parked ON the drive by its nose, clear of the garage door (%.2f m off its spot, z %.2f..%.2f, door face %.2f)"
		% [which, String(main.look["car"]), off, box.position.z, box.end.z, door_face])
	var paint: Color = main.look["paint"]
	var painted := 0
	var wrong := 0
	for mi: MeshInstance3D in c.find_children("*", "MeshInstance3D", true, false):
		for si in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
			var live := mi.get_active_material(si) as BaseMaterial3D
			if live == null or not String(live.resource_name).begins_with("Equip_Paint"):
				continue
			if mi.get_surface_override_material(si) != null:
				painted += 1
				if not live.albedo_color.is_equal_approx(paint):
					wrong += 1
	var shared_hit := 0
	for mi: MeshInstance3D in c.find_children("*", "MeshInstance3D", true, false):
		for si in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
			var own := mi.mesh.surface_get_material(si) as BaseMaterial3D
			if own != null and String(own.resource_name).begins_with("Equip_Paint") and paint.a > 0.0 \
					and (own.albedo_color.is_equal_approx(paint) or own == mi.get_active_material(si)):
				shared_hit += 1
	_check(shared_hit == 0, "%sthe paint went on a copy: the imported material is untouched (%d)" % [which, shared_hit])
	_check(c.model_path.get_file() == String(main.look["car"]) + ".glb" and wrong == 0 \
		and (painted > 0) == (paint.a > 0.0),
		"%sin the visit's paint, on a copy (%s, %d surfaces painted, %d wrong)" % [which, c.model_path.get_file(), painted, wrong])


# --- Again -----------------------------------------------------------------------------------------------

## NEXT cuts to the title row now (6.3), which frees the whole site - its Sfx,
## its loops and the fallback synth's player - while the audio thread is still
## mixing. Freed under a playing AudioStreamGenerator, that is the crash that
## killed one Car Garage run in three (the improvement plan's 0.2). A real scene
## change from inside this test would take the test's own scene away (and
## repeated ones crash Godot 4.7.2 outright), so the cut is stood in for by
## freeing the site with its sounds running and building the next one here. The
## whole trip - site, title, seat, site - is `scenes/dev/switch_probe.tscn`.
func _the_second_job() -> void:
	print("--- again: a second driveway ---")
	# NEXT, pressed for real: it clears the save and leaves the FINISHED visit
	# behind for the title row to stand on (6.3), then asks for the cut - which
	# this test stands in for. The next visit is drawn at the title's seat.
	var asked := [false]
	main.leave_scene = func() -> void: asked[0] = true
	hud.simulate_next()
	await _until(func() -> bool: return bool(asked[0]), "NEXT to ask for the cut")
	_check(bool(asked[0]) and Engine.has_meta(SiteMain.LAST_SEED_META) 		and int(Engine.get_meta(SiteMain.LAST_SEED_META)) == int(_first_look["seed"]) and not SaveGame.exists(),
		"NEXT left the finished visit for the title row and no save behind")
	# What the title's seat does next, since there is no title in this test: the
	# finished visit is taken, and a different one is drawn for the new job.
	Engine.remove_meta(SiteMain.LAST_SEED_META)
	Engine.set_meta(SiteMain.NEXT_SEED_META, SiteLook.draw_fresh(main.look))
	if main.sfx != null:
		main.sfx.play_loop("dieselidle", "probe")
		main.sfx.play_group("tada")
	var old := main
	main.queue_free()
	await _frames(3)
	_check(not is_instance_valid(old), "the first site is freed with its sounds still playing")
	var packed: PackedScene = load("res://scenes/site.tscn")
	main = packed.instantiate() as SiteMain
	add_child(main)
	await _frames(2)
	hud = main.hud
	runner = main.runner
	drive = main.drive
	rings = main.get_node_or_null("Rings") as SpotRings
	_check(runner != null and not runner.finished and runner.index == 0,
		"a second driveway starts from the first bite")
	_check(drive.panels_broken() == 0 and drive.fill_fraction() < 0.001,
		"on a cracked old drive with nothing done to it")
	_check(rings != null and rings.count() == 3, "with three rings on the first slab (%d)" % rings.count())
	_check(not hud.home_visible(), "and the house off the screen again")
	# A DIFFERENT driveway (6.1): the next visit's seed, read off the world.
	print("  second visit: %s" % str(main.look))
	_check(main.seed_from == "next" and not Engine.has_meta(SiteMain.NEXT_SEED_META) and main.play_seed != _first_look["seed"],
		"on the seed NEXT drew, used up (%d from %s)" % [main.play_seed, main.seed_from])
	_check(SiteLook.differs(main.look, _first_look), "a different car, house and cracks (%s, swatch %d, cracks %d)"
		% [String(main.look["car"]), int(main.look["house_swatch"]), int(main.look["crack_base"])])
	_check(drive.crack_base == int(main.look["crack_base"]) and _old_crack(main).distance_to(LEGACY_CRACK) > 0.001,
		"its old cracks are not the first drive's (%s)" % str(_old_crack(main)))
	var sw := int(main.look["house_swatch"])
	_check(_garage_wall(main).is_equal_approx(SiteLook.HOUSE_SWATCHES[sw][1]) and not _garage_wall(main).is_equal_approx(Color(0.88, 0.86, 0.80)) \
		and (_house_overrides(main) > 0) == (sw != 0),
		"and the garage and the house in the visit's swatch (%s, %d house overrides)" % [str(_garage_wall(main)), _house_overrides(main)])
	var same_rings := rings.points().size() == _first_rings.size()
	for k in range(mini(rings.points().size(), _first_rings.size())):
		same_rings = same_rings and rings.points()[k].distance_to(_first_rings[k]) < 0.001
	_check(runner.step_count() == STEP_COUNT and main.job.total_weight() == TOTAL_STOPS and drive.panel_count() == 4 \
		and drive.jack_spots() == 12 and same_rings,
		"but the same job: %d rows, %d stops, four panels, the first slab's rings where they were" % [runner.step_count(), main.job.total_weight()])
	await _settled()
	var id := rings.id_at(0)
	_check(_tap_ring(id), "its first ring can be pressed")
	await _until(func() -> bool: return not runner.is_busy(), "the second job's first bite")
	_check(drive.spot_done(id), "and the bite lands (spot %d done)" % id)
	_save_is("jack_spot", 1, 1, [id], "and the second visit saves itself:")


## The tablet is taken away from the second job after its first bite, and given
## back: the site opens on the same visit and the same place (6.2), even with a
## different `--seed` named - the save's seed wins, or the resumed job would
## stand its stakes on another drive. Then the plan's own check, made honest:
## the first job's save after bars 3 and 1, resumed, against `--stage=based
## --step=rebar_lay --done=2 --places=3,1` posed.
func _the_resume() -> void:
	print("--- again: the tablet taken away ---")
	var saved := SaveGame.load_data()
	var look2 := main.look.duplicate()
	var crack2 := _old_crack(main)
	var wall2 := _garage_wall(main)
	var spot := int((saved.get("places", [0]) as Array)[0])
	main.queue_free()
	await _frames(3)
	Engine.set_meta("shot_args", {"seed": "7"})
	await _new_site()
	_check(main.seed_from == "save" and main.play_seed == int(look2["seed"]) and String(main.look["car"]) == String(look2["car"]) \
		and _old_crack(main).distance_to(crack2) < 0.0001 and _garage_wall(main).is_equal_approx(wall2),
		"it comes back on the same visit - car, house, cracks - whatever seed is named (%d from %s)" % [main.play_seed, main.seed_from])
	_check(runner.index == 0 and runner.done_in_step == 1 and drive.spot_done(spot) and rings.count() == 2 \
		and rings.index_of(spot) < 0,
		"at the same place: the first bite done on spot %d, two rings left (%d)" % [spot, rings.count()])
	# The bar's own step is 0.01, so its value is the stop rounded to a hundredth.
	_check(runner.progress == main.job.weight_before(0, 1) and absf(hud.step_value() - float(main.job.weight_before(0, 1)) / float(TOTAL_STOPS)) < 0.006,
		"the bar at that stop (%d of %d, bar %.3f)" % [runner.progress, TOTAL_STOPS, hud.step_value()])
	var machines_out := 0
	for kind: String in ["SkidSteer", "DumpTruck", "ConcreteTruck"]:
		machines_out += 1 if main.machine(kind).visible else 0
	_check(main.rig.current_shot() == CameraRig.WIDE and main._opening and machines_out == 0 and main.garage_door_k() < 0.1,
		"opening on the wide, the lot as the child left it (%s, %d machines, door %.2f)" % [main.rig.current_shot(), machines_out, main.garage_door_k()])
	var next_id := rings.id_at(0)
	_check(_tap_ring(next_id), "and a ring can be pressed")
	await _until(func() -> bool: return drive.spot_done(next_id) and not runner.is_busy(), "the resumed job's bite")
	_save_is("jack_spot", 1, 2, [mini(spot, next_id), maxi(spot, next_id)], "and the job runs on:")
	# The plan's check: resumed from real play against posed - on a DRAWN visit
	# (seed 5) named the same way to both, so the look is part of what must match.
	Engine.set_meta("shot_args", {})
	_rebar_doc["seed"] = 5
	SaveGame.save_data(_rebar_doc)
	main.queue_free()
	await _frames(3)
	await _new_site()
	var resumed := _world_print()
	main.queue_free()
	await _frames(3)
	Engine.set_meta("shot_args", {"stage": "based", "step": "rebar_lay", "done": "2", "places": "3,1", "seed": "5"})
	await _new_site()
	var posed := _world_print()
	var differ: Array[String] = []
	for k: String in resumed:
		if str(resumed[k]) != str(posed.get(k)):
			differ.append("%s %s vs %s" % [k, str(resumed[k]), str(posed.get(k))])
	_check(str(resumed["bars"]) == str([true, false, true, false, false, false, false, false, false, false, false, false]),
		"the first job's save after bars 3 and 1 resumes with bars 1 and 3 down - not 1 and 2 by count (%s)" % str(resumed["bars"]))
	_check(differ.is_empty() and main.play_seed == 5, "and its world - look, bars, rings, tools, bar - is the posed --places=3,1 world (%s)"
		% ("same" if differ.is_empty() else "; ".join(differ)))
	# A painted visit's payoff: the car in its paint on a copy, the house in its
	# swatch on a copy - and then the legacy lot, which must not have caught it.
	main.queue_free()
	await _frames(3)
	var painted_seed := 61
	Engine.set_meta("shot_args", {"stage": "parked", "seed": str(painted_seed)})
	await _new_site()
	_check(Color(main.look["paint"]).a > 0.0 and int(main.look["house_swatch"]) > 0,
		"a drawn visit with a painted car and a painted house (%s, swatch %d)" % [String(main.look["car"]), int(main.look["house_swatch"])])
	_car_parked_right("a painted visit: ")
	var hp := _house_paint(main)
	_check(hp.x > 0 and hp.y == 0, "and its house in the swatch, on a copy (%d surfaces, %d imported ones written)" % [hp.x, hp.y])
	main.queue_free()
	await _frames(3)
	Engine.set_meta("shot_args", {"stage": "parked"})
	await _new_site()
	var hp0 := _house_paint(main)
	var red := 0
	for mi: MeshInstance3D in main.car.find_children("*", "MeshInstance3D", true, false):
		for si in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
			var live := mi.get_active_material(si) as BaseMaterial3D
			if live != null and String(live.resource_name).begins_with("Equip_Paint") and _colour_step(live.albedo_color, Color(0.86, 0.16, 0.12)) < 0.005 \
					and mi.get_surface_override_material(si) == null:
				red += 1
	_check(_house_overrides(main) == 0 and hp0.y == 0 and red > 0,
		"and the legacy lot after it is untouched: no house override, the hatchback in its own red (%d red surfaces)" % red)
	_car_parked_right("the legacy lot after a painted one: ")
	Engine.set_meta("shot_args", {})


func _new_site() -> void:
	var packed: PackedScene = load("res://scenes/site.tscn")
	main = packed.instantiate() as SiteMain
	add_child(main)
	await _frames(3)
	hud = main.hud
	runner = main.runner
	drive = main.drive
	rings = main.get_node_or_null("Rings") as SpotRings


## What a resumed and a posed site must agree on: the job's place and the world.
func _world_print() -> Dictionary:
	var bars: Array = []
	for i in range(1, drive.bar_count() + 1):
		bars.append(drive.bar_is_in(i))
	var forms: Array = []
	for i in range(1, drive.form_count() + 1):
		forms.append(drive.form_is_in(i))
	var stakes: Array = []
	for i in range(1, drive.stake_count() + 1):
		stakes.append(drive.stake_is_in(i))
	var ids: Array = []
	for k in range(rings.count()):
		ids.append(rings.id_at(k))
	ids.sort()
	var shown: Array = []
	for kind: String in ["SkidSteer", "DumpTruck", "ConcreteTruck"]:
		shown.append(main.machine(kind).visible)
	var tools_out: Array = []
	for kind: String in main.tools:
		if (main.tools[kind] as Node3D).visible:
			tools_out.append(kind)
	tools_out.sort()
	var stripped: Array = []
	for b in drive.strip_boards():
		stripped.append(drive.form_is_stripped(b))
	return {"step": runner.index, "done": runner.done_in_step, "progress": runner.progress, "bars": bars,
		"chairs": drive.chairs_shown(), "forms": forms, "stakes": stakes, "rings": ids, "gravel": snappedf(drive.gravel_k(), 0.001),
		"packed": drive.pack_baked(), "pad": drive.chunks_on_pad(), "fill": snappedf(drive.fill_fraction(), 0.001),
		"door": snappedf(main.garage_door_k(), 0.01), "machines": shown, "crack": _old_crack(main),
		"tools": tools_out, "bar": snappedf(hud.step_value(), 0.001), "stripped": stripped,
		"look": "%s %s %d %d" % [String(main.look["car"]), str(main.look["paint"]), int(main.look["house_swatch"]), int(main.look["crack_base"])],
		"wall": _garage_wall(main)}


# --- Plumbing ------------------------------------------------------------------------------------------

## Drags the work point over the whole slab the way a finger would, lane by lane,
## and stops as soon as the beat says it has had enough.
## The cursor walked from `from` to `to` with the finger down, then held at
## `to` until `done` says so (or the cap). A DRAG beat's finger.
func _drag_along(from: Vector3, to: Vector3, done: Callable, frames: int = 300) -> bool:
	for frame in range(FRAME_CAP):
		var t := minf(float(frame) / float(frames), 1.0)
		main.set_work_cursor(from.lerp(to, t))
		runner.hold(true)
		await get_tree().process_frame
		if bool(done.call()):
			return true
	return false


## `_sweep` over one band of the drive only.
func _sweep_range(z0: float, z1: float, coverage: Callable) -> bool:
	var lanes := 5
	var steps := 7
	var at := 0
	for frame in range(FRAME_CAP):
		var lane := (at / steps) % lanes
		var step := at % steps
		var t := float(step) / float(steps - 1)
		main.set_work_cursor(Vector3(
			lerpf(Driveway.CENTRE_X - Driveway.WIDTH * 0.40,
				Driveway.CENTRE_X + Driveway.WIDTH * 0.40, float(lane) / float(lanes - 1)),
			Driveway.GRADE,
			lerpf(z0, z1, t if lane % 2 == 0 else 1.0 - t)))
		runner.hold(true)
		await get_tree().process_frame
		if float(coverage.call()) >= main.config.scrub_done:
			return true
		if frame % 4 == 3:
			at += 1
	return false


func _sweep(coverage: Callable) -> bool:
	var lanes := 5
	var steps := 13
	var at := 0
	# Paced in FRAMES, not in laps. The work is paced in seconds and a headless
	# frame is a fraction of a millisecond, so a fixed number of laps covers
	# whatever fraction of the slab the machine happened to be fast enough for -
	# which is how this first reported the mechanic broken at 0.78 covered.
	for frame in range(FRAME_CAP):
		var lane := (at / steps) % lanes
		var step := at % steps
		var t := float(step) / float(steps - 1)
		main.set_work_cursor(Vector3(
			lerpf(Driveway.CENTRE_X - Driveway.WIDTH * 0.40,
				Driveway.CENTRE_X + Driveway.WIDTH * 0.40, float(lane) / float(lanes - 1)),
			Driveway.GRADE,
			lerpf(Driveway.Z_APRON + 0.35, Driveway.Z_KERB - 0.35,
				t if lane % 2 == 0 else 1.0 - t)))
		runner.hold(true)
		await get_tree().process_frame
		if float(coverage.call()) >= main.config.scrub_done:
			return true
		if frame % 4 == 3:
			at += 1
	return false


## Waits for the camera to finish moving to the shot it has been sent to. The rig
## eases over `shot_time`; a headless frame is a fraction of a millisecond, so
## counting frames instead of asking is how a test ends up photographing a camera
## still half way between two shots.
func _settled() -> void:
	await _until(func() -> bool: return not main.rig.is_moving(), "the camera to arrive")
	await _frames(3)


## Watches a truck's rearmost tyre for as long as `_watch_pad` is up.
func _watch_wheels(m: Machine) -> void:
	while _watch_pad:
		if m.visible:
			var tyre := m.global_position.z - m.rear_overhang()
			if tyre < Driveway.Z_KERB + 0.05 and absf(m.global_position.x - Driveway.CENTRE_X) < Driveway.WIDTH:
				_on_pad_frames[0] += 1
		await get_tree().process_frame


## Presses the gold ring carrying `id`, through the SCREEN, the way a finger
## does - so the ring picking and the tap rule are both really exercised.
func _tap_ring(id: int) -> bool:
	if rings == null or main.camera == null:
		return false
	var i := rings.index_of(id)
	if i < 0:
		return false
	var at := main.camera.unproject_position(rings.point_at(i))
	main._press(at, true)
	main._press(at, false)
	return true


func fr_payoff() -> Vector2:
	return main.camera.get_viewport().get_visible_rect().size


func _fake_touch(at: Vector2, pressed: bool) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = at
	ev.pressed = pressed
	return ev


## A real finger, through the viewport's own input pipeline, WITH its index:
## `_press` is what a finger ends in, but which finger it was is decided before
## that, in `SiteMain._unhandled_input`. Local coordinates: the same pixels
## `unproject_position` speaks in.
func _touch(index: int, at: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = at
	ev.pressed = pressed
	get_viewport().push_input(ev, true)


func _drag(index: int, at: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = at
	get_viewport().push_input(ev, true)


## The white wedge is itself a target (the improvement plan's 0.5): a press on
## its BODY, out past the ring's own reach, works the ring it stands over. The
## mime said "tap here", and a tap there was a miss.
func _the_wedge() -> void:
	var delay_was: float = hud.hint_delay
	hud.hint_delay = 0.3
	await get_tree().create_timer(0.7).timeout
	_check(hud.hint_visible(), "on the third slab the white arrow comes back after a pause")
	if not hud.hint_visible():
		hud.hint_delay = delay_was
		return
	var over := rings.id_at(0)
	var ring_px := main.camera.unproject_position(rings.point_at(0))
	var hp := hud.hint_position()
	var d := (hp - ring_px).normalized()
	var body: float = hud._hint.arrow_size * (hud._hint.BACK + hud._hint.BACK_OFF)
	var far := hp + d * body
	var reach := main._reach_px()
	_check(hud.arrow_hit(far), "the far end of the wedge counts as the wedge (%s; ring at %s)" % [str(far), str(ring_px)])
	# A press on the wedge is answered by the nearest live ring when one is in
	# reach of the finger (any ring on the slab is a right answer), and by the
	# ring the wedge stands over when none is. Look for a point on the wedge's
	# body that no ring reaches; press the far end when there is none.
	var at := far
	var free := false
	for step in range(0, 14):
		var p := hp + d * (body * 0.5 + 10.0 * float(step))
		if rings.pick_nearest(main.camera, p, reach) == 0:
			at = p
			free = true
			break
	var near := rings.pick_nearest(main.camera, at, reach)
	var rings_before := rings.count()
	print("      pressing the wedge at %s (%s)" % [str(at),
		"no ring in reach" if free else "ring %d in reach" % near])
	main._press(at, true)
	main._press(at, false)
	await _frames(2)
	_check(runner.is_busy(), "a press on the wedge starts a bite")
	await _until(func() -> bool: return not runner.is_busy(), "the bite the wedge asked for")
	if free:
		_check(drive.spot_done(over), "and it works the ring the wedge stood over (spot %d)" % over)
	else:
		_check(drive.spot_done(near), "and it works the ring under the finger (spot %d)" % near)
	_check(rings.count() == rings_before - 1, "one ring fewer on the slab (%d)" % rings.count())
	hud.hint_delay = delay_was


## Is the single-place hint (the ring-and-arrow the runner points with) up,
## and inside the picture with a margin?
func _hint_on_screen() -> bool:
	var pointer := main.get_node_or_null("Pointer") as SpotRings
	if pointer == null or not pointer.lit():
		print("      no hint is up")
		return false
	var frame := main.camera.get_viewport().get_visible_rect().size
	for at in pointer.points():
		if main.camera.is_position_behind(at):
			print("      hint at %s is BEHIND the camera" % str(at))
			return false
		var p := main.camera.unproject_position(at)
		var margin := frame.y * 0.06
		if p.x < margin or p.y < margin or p.x > frame.x - margin or p.y > frame.y - margin:
			print("      hint at %s projects to %s, frame %s" % [str(at), str(p), str(frame)])
			return false
	return true


## The mean vertical speed over a wall-clock window of (seconds, height) samples:
## the slope between the first and last sample inside it. 0 with fewer than two.
func _speed_over(samples: Array[Vector2], t0: float, t1: float) -> float:
	var inside: Array[Vector2] = []
	for s in samples:
		if s.x >= t0 - 1e-6 and s.x <= t1 + 1e-6:
			inside.append(s)
	if inside.size() < 2 or inside[inside.size() - 1].x - inside[0].x < 1e-4:
		return 0.0
	return (inside[inside.size() - 1].y - inside[0].y) / (inside[inside.size() - 1].x - inside[0].x)


## The least-squares slope (height over seconds) of the samples inside a window:
## every frame in it counts, so one frame's jitter between the process delta
## that moves the bar and the wall clock that times the sample cannot swing it
## (the two-sample reads failed three different ways in the fifth session).
## 0 with fewer than three samples.
func _slope(samples: Array[Vector2], t0: float, t1: float) -> float:
	var xs: Array[float] = []
	var ys: Array[float] = []
	for smp in samples:
		if smp.x >= t0 - 0.002 and smp.x <= t1 + 0.002:
			xs.append(smp.x)
			ys.append(smp.y)
	if xs.size() < 3:
		return 0.0
	var mx := 0.0
	var my := 0.0
	for i in range(xs.size()):
		mx += xs[i]
		my += ys[i]
	mx /= float(xs.size())
	my /= float(xs.size())
	var num := 0.0
	var den := 0.0
	for i in range(xs.size()):
		num += (xs[i] - mx) * (ys[i] - my)
		den += (xs[i] - mx) * (xs[i] - mx)
	return num / den if den > 1e-12 else 0.0


## How many times two world polylines cross on the screen, through the live
## camera (points behind it are left out).
func _screen_crossings(a: PackedVector3Array, b: PackedVector3Array) -> int:
	var pa: Array[Vector2] = []
	var pb: Array[Vector2] = []
	for p in a:
		if not main.camera.is_position_behind(p):
			pa.append(main.camera.unproject_position(p))
	for p in b:
		if not main.camera.is_position_behind(p):
			pb.append(main.camera.unproject_position(p))
	var n := 0
	for i in range(pa.size() - 1):
		for j in range(pb.size() - 1):
			if Geometry2D.segment_intersects_segment(pa[i], pa[i + 1], pb[j], pb[j + 1]) != null:
				n += 1
	return n


## How far apart two colours sit round the hue wheel, 0 to 0.5.
func _hue_gap(a: Color, b: Color) -> float:
	var d := absf(a.h - b.h)
	return minf(d, 1.0 - d)


## How many pixel ROWS apart two world points land in the picture, through the
## live camera; 0 when either is behind it.
func _px_rows(a: Vector3, b: Vector3) -> float:
	if main.camera == null or main.camera.is_position_behind(a) or main.camera.is_position_behind(b):
		return 0.0
	return absf(main.camera.unproject_position(a).y - main.camera.unproject_position(b).y)


## Is one world point inside the picture?
func _on_screen(at: Vector3) -> bool:
	if main.camera == null or main.camera.is_position_behind(at):
		return false
	var frame := main.camera.get_viewport().get_visible_rect().size
	var p := main.camera.unproject_position(at)
	return p.x >= 0.0 and p.y >= 0.0 and p.x <= frame.x and p.y <= frame.y


## Is every lit ring inside the picture? A ring the camera cannot see is a place
## the child cannot tap, which is the whole of this round's first note.
func _all_rings_on_screen() -> bool:
	if rings == null or main.camera == null:
		return false
	var frame := main.camera.get_viewport().get_visible_rect().size
	var okay := true
	for at in rings.points():
		if main.camera.is_position_behind(at):
			print("      ring at %s is BEHIND the camera" % str(at))
			okay = false
			continue
		var p := main.camera.unproject_position(at)
		var margin := frame.y * 0.05
		if p.x < margin or p.y < margin or p.x > frame.x - margin or p.y > frame.y - margin:
			print("      ring at %s projects to %s, frame %s" % [str(at), str(p), str(frame)])
			okay = false
	return okay


## How many of a machine's meshes under `part` are being drawn.
func _drawn(m: Machine, part: String) -> int:
	var node := m.node_for(part)
	if node == null:
		return 0
	var n := 0
	if node is MeshInstance3D and (node as MeshInstance3D).visible:
		n += 1
	for child in node.find_children("*", "MeshInstance3D", true, false):
		if (child as MeshInstance3D).visible:
			n += 1
	return n


## The albedo alpha a machine's part is drawn at: 1 when nothing has faded it.
func _alpha_of(m: Machine, part: String) -> float:
	var node := m.node_for(part)
	if node == null:
		return 1.0
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for n in meshes:
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.mesh.get_surface_count() == 0:
			continue
		var mat := mi.get_surface_override_material(0)
		if mat is BaseMaterial3D:
			return (mat as BaseMaterial3D).albedo_color.a
	return 1.0


## Are both ends of a line across the drive inside the picture? The camera is
## where it really is, so this is the question the user asked: "camera couldn't
## see all the joints being made".
func _both_ends_visible(z: float) -> bool:
	var cam := main.camera
	if cam == null:
		return false
	var frame := cam.get_viewport().get_visible_rect().size
	for side: float in [-0.5, 0.5]:
		var at := Vector3(Driveway.CENTRE_X + Driveway.WIDTH * side, Driveway.GRADE, z)
		if cam.is_position_behind(at):
			return false
		var p := cam.unproject_position(at)
		if p.x < 0.0 or p.y < 0.0 or p.x > frame.x or p.y > frame.y:
			return false
	return true


## Waits for `cond` to come true, or fails when it never does. Never counts
## frames to decide a beat is DONE - only to give up.
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


func _list(a: PackedStringArray) -> String:
	return "none" if a.is_empty() else ", ".join(a)
