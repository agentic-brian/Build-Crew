class_name SiteVerbs
extends Node
## The verbs a job step can ask for (DESIGN 2). One method per verb, named
## exactly as the step names it, and every one of them a coroutine that RETURNS
## WHEN ITS ANIMATION HAS FINISHED - that is the whole contract, and it is what
## lets `JobRunner` stay a small state machine no matter how baroque a beat
## looks on screen.
##
##     func <verb>(runner, subject, targets, tool, config) -> void
##
## What a handler needs from the lot it takes through `runner.level` (the
## machines, the noise, the dust); what it needs from the driveway it takes
## through `subject`. No handler reaches for a member by name on another verb.
##
## Ten of them build a driveway, and they come in three shapes:
##
##   `_hold`    work that runs while the finger is down and pauses where it is
##              when it lifts - the push, the tip, the screed, a joint
##   `_bite`    one tap, one decisive piece of work - a hammer spot, a board, a
##              stake. It runs to the end on its own once it is started.
##   `_scrub`   work the child DRAGS over the slab, which only happens where the
##              finger is and ends when they have been everywhere - the hose and
##              the broom. The user's ninth note: "player should have to move
##              water around and get it all wet them selves".

## Which pads a pad-driven beat listens to, for `SiteMain.arm_pads`. ONLY the
## pads the verb really reads: an arrow on screen that does nothing when a child
## presses it is a lie, and a four-year-old will press all of them.
##
## ONE beat, now. The push and the tip were both steered with the UP pad and both
## are plain press-and-hold on the picture instead ("dump truck should be a touch
## and hold and it drives out dropping rock"): the pads were a second control to
## learn for work that only ever went one way. The pour keeps all four, because
## aiming it IS the phase.
const PAD_VERBS := {
	"pour_chute": ["up", "down", "left", "right"],
}
## The beats worked by dragging a finger across the slab. `SiteMain` reads this
## to decide what a tap may land on and to give a stick a cursor.
const SCRUB_VERBS := {
	"rake_pull": true,
	"spray_water": true,
	"broom_finish": true,
	"screed_pull": true,
	"joint_cut": true,
	"compact_base": true,
}
## The beats where the child BACKS A TRUCK IN (the improvement plan's 1.8, the
## user's decision 4), and which machine: a press has to land on that truck.
const BACK_VERBS := {
	"back_dump": "DumpTruck",
	"back_mixer": "ConcreteTruck",
}
## The site's own noises (the user, 2026-09-12: "Correct all the sounds").
##
## Every one of these was a car-garage clip standing in for a thing it was not:
## the breaker was an impact wrench, the pour was a drain, the screed and the
## broom were both the same scrape, and the three diesel machines idled like a
## hatchback. They are twelve clips of the real work now
## (`assets/sfx/breaker_*`, `crumble_*`, ..., ElevenLabs, `docs/sfx.md`), and
## the ones that run while work is happening are LOOPS rather than a one-shot
## fired over and over.
##
## The breaker is the one that changes shape as well as sound: it used to play a
## one-shot on every blow of a 13-per-second hammer, which is thirteen clips a
## second piled on top of each other. It is one rattling loop that runs while
## the bite runs, and the blows are what the picture does - the kick, the puff
## of dust, the bit going in.
const SOUND_BREAK := "crumble"
const SOUND_BLOW := "breaker"
const SOUND_GRAVEL := "gravelpour"
const SOUND_CONCRETE := "wetpour"
const SOUND_WATER := "hosespray"
const SOUND_DRAG := "screeddrag"
const SOUND_BROOM := "broomdrag"
const SOUND_RUBBLE := "rubblepush"
const SOUND_IDLE := "dieselidle"
const SOUND_DRUM := "mixerdrum"
const SOUND_RAM := "hydraulic"
const SOUND_STAKE := "sledgehit"
const SOUND_BAR := "rebardrop"
## A tie wire twisted tight at a crossing (the improvement plan's 4.7): the
## garage library's dry torque-wrench click, pitched up a step per tie. Not
## `pop` (that is a miss) and not `clip` (the groover's end).
const SOUND_TIE := "click"
const SOUND_RAKE := "rakepull"
## The plate compactor's rattle (5.1, ElevenLabs flow "Build Crew site sounds 4").
const SOUND_PLATE := "platerattle"
const SOUND_BEEPER := "reversebeep"
## How far (on the ground) the plate may get from the child's hands within one
## stroke: its handle stretches 3.2 times its 0.96 m, and a little is kept back.
const PLATE_REACH := 2.8


## Is there a handler for this verb?
func has_verb(verb: String) -> bool:
	return verb != "" and has_method(verb)


## Plays one beat and returns when it has finished. An unknown verb is a warning
## and a beat that does nothing, never a crash: a job definition with a typo in
## it must still be playable.
func run(verb: String, runner: JobRunner, subject: Node3D, targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	if not has_verb(verb):
		push_warning("SiteVerbs: no handler for verb '%s'" % verb)
		return
	await Callable(self, verb).call(runner, subject, targets, tool, config)


# --- The shared shapes ----------------------------------------------------------------------

## Runs `on_k(k)` from 0 to 1 over `seconds` of HELD time, once a frame.
##
## The finger is the throttle: while it is down the work flows, while it is up
## the work stands exactly where it is. A bare tap still buys `hold_burst`
## seconds, so a child who has not worked out the holding yet is never tapping
## at nothing. `loop_group` is a looped sound that plays only while it flows,
## and the bar fills through `runner.partial` as it goes.
func _hold(runner: JobRunner, seconds: float, config: SiteConfig, loop_group: String,
		on_k: Callable, voice: String = "work", engine_voice: String = "", ramp: float = 0.0,
		burst_from_press: bool = false) -> void:
	var site: Variant = runner.level
	var k := 0.0
	var burst_left: float = config.hold_burst
	var was_held := false
	var flowing_now := false
	# `engine_voice` names a machine's running idle: it LEANS INTO THE WORK
	# while the beat flows - a note lower and a shade louder - and settles back
	# when the finger lifts (the improvement plan's 1.7). A hand tool never
	# revs a machine, so most beats pass nothing.
	var lean := 0.0
	# `ramp` is how many seconds the work takes to come up to speed and to come
	# to rest, for a thing with weight: a truck backing in under a finger gathers
	# way and stops instead of lurching (1.8). 0 - every other beat - is the old
	# switch, bit for bit.
	var rate := 0.0
	while k < 1.0:
		var dt := _dt(runner)
		if runner.held and not was_held:
			burst_left = config.hold_burst
		was_held = runner.held
		var flowing := runner.held or burst_left > 0.0
		# `burst_from_press`: the burst is counted from the PRESS, so a tap still
		# buys its seconds but a real hold stops on the lift (with only `ramp`'s
		# coast) - a truck let go of must not roll on two metres at full speed.
		if not runner.held or burst_from_press:
			burst_left -= dt
		if engine_voice != "" and site != null:
			lean = move_toward(lean, 1.0 if flowing else 0.0, dt / maxf(config.engine_lean_time, 0.01))
			site.sfx.set_loop_pitch(engine_voice, lerpf(1.0, config.engine_lean_pitch, lean))
			site.sfx.set_loop_trim(engine_voice, lerpf(0.0, config.engine_lean_db, lean))
		if ramp > 0.0:
			rate = move_toward(rate, 1.0 if flowing else 0.0, dt / ramp)
		else:
			rate = 1.0 if flowing else 0.0
		if rate > 0.0:
			if not flowing_now:
				if loop_group != "" and site != null:
					site.sfx.play_loop(loop_group, voice)
				flowing_now = true
			k = minf(k + dt * rate / maxf(seconds, 0.05), 1.0)
			on_k.call(k)
			runner.partial(k)
		elif flowing_now:
			if site != null:
				site.sfx.stop_loop(voice)
			flowing_now = false
		await runner.get_tree().process_frame
	if flowing_now and site != null:
		site.sfx.stop_loop(voice)
	if engine_voice != "" and site != null:
		site.sfx.set_loop_pitch(engine_voice, 1.0)
		site.sfx.set_loop_trim(engine_voice, 0.0)


## One TAP's worth of work: `on_k(k)` from 0 to 1 over `seconds`, no finger
## needed once it has started.
##
## This is the shape of the hammer's three bites on a panel and of the one blow
## that puts a stake in. It is deliberately NOT a hold: a bite is a decision
## ("here"), and what the child is being asked to get right is WHERE, not how
## long. The bar still fills as it goes.
func _bite(runner: JobRunner, seconds: float, config: SiteConfig, loop_group: String,
		on_k: Callable, voice: String = "work") -> void:
	var site: Variant = runner.level
	if loop_group != "" and site != null:
		site.sfx.play_loop(loop_group, voice)
	var t := 0.0
	var total := maxf(seconds, 0.05)
	while t < total:
		t = minf(t + _dt(runner), total)
		var k := t / total
		on_k.call(k)
		runner.partial(k)
		await runner.get_tree().process_frame
	on_k.call(1.0)
	if loop_group != "" and site != null:
		site.sfx.stop_loop(voice)


## Work DRAGGED over the slab: `on_point(world, dt)` is called for wherever the
## child's finger is, every frame it is down, and the beat ends when `coverage()`
## says they have been everywhere.
##
## Nothing happens where the finger is not. That is the point of it - the slab
## that has not been done looks different from the slab that has - and it is why
## this cannot be `_hold`: holding still in one place must not finish the job.
## If the child goes quiet for `chute_hint_delay` the arrow goes and hangs over
## whichever patch they have missed.
func _scrub(runner: JobRunner, config: SiteConfig, loop_group: String,
		on_point: Callable, coverage: Callable, hint: Callable,
		voice: String = "work", each_frame: Callable = Callable(), done: float = -1.0,
		plane_y: float = Driveway.GRADE) -> void:
	var site: Variant = runner.level
	var flowing := false
	var idle := 0.0
	# `done` is how much coverage ends the beat: the scrubs' 85%, or all of it
	# for a DRAG that has a definite end (the board at the kerb, the groover at
	# the far form).
	var want_done: float = done if done > 0.0 else config.scrub_done
	while float(coverage.call()) < want_done:
		var dt := _dt(runner)
		if each_frame.is_valid():
			each_frame.call(dt)
		# The finger is dropped onto the plane the work is ON: the slab's top, or
		# the base 10 cm under it for the plate (5.1), where a finger read at grade
		# lands a hand's width off.
		var at: Vector3 = site.work_point(plane_y) if site != null else Vector3.INF
		var working := runner.held and at != Vector3.INF
		if working:
			# A DRAG's `on_point` answers false when the finger is not on the
			# tool: that is a resting finger, not work - the loop sound stops
			# and the idle hint may come.
			var did: Variant = on_point.call(at, dt)
			if did is bool and not bool(did):
				working = false
		if working:
			if not flowing:
				if loop_group != "" and site != null:
					site.sfx.play_loop(loop_group, voice)
				flowing = true
			runner.partial(clampf(float(coverage.call()) / want_done, 0.0, 1.0))
			idle = 0.0
			runner.release_arrow()
		else:
			if flowing and site != null:
				site.sfx.stop_loop(voice)
			flowing = false
			idle += dt
			if idle > config.chute_hint_delay:
				runner.hold_arrow(hint.call(), 0.5)
		await runner.get_tree().process_frame
	if flowing and site != null:
		site.sfx.stop_loop(voice)
	runner.release_arrow()


## Eases a value 0..1 over `seconds`, calling `on_k` every frame: a machine move
## that is not the child's work. `smooth` false hands over a LINEAR k, for a
## caller that shapes its own motion (a bar that falls rather than settles).
## One frame of a verb's own clock, in seconds - and 0.0 while the tree is paused.
##
## Every verb animates inside `while ...: await runner.get_tree().process_frame`,
## and `process_frame` is emitted whether or not the tree is paused: `paused`
## stops `_process`, not a coroutine. So the settings panel (6.4) froze the
## picture, the HUD and the cameras while the POUR went on pouring behind it -
## unsteered, into whichever cell the chute last sat over - drove the bar up
## behind the dim, wrote the save mid-pause, and handed the parent back a phase
## the child never did.
##
## A zero delta is the whole fix: every loop stays alive and exactly where it
## was, so there is nothing to unwind and nothing to restore when the panel
## closes. (`create_timer(..., false)` already waits out a pause, which is why
## the waits between beats never had this bug.)
func _dt(runner: JobRunner) -> float:
	if runner == null:
		return 0.0
	var tree := runner.get_tree()
	if tree == null or tree.paused:
		return 0.0
	return runner.get_process_delta_time()


func _ease(runner: JobRunner, seconds: float, on_k: Callable, smooth: bool = true) -> void:
	var t := 0.0
	var total := maxf(seconds, 0.02)
	while t < total:
		var dt := _dt(runner)
		t = minf(t + dt, total)
		var k := t / total
		on_k.call(k * k * (3.0 - 2.0 * k) if smooth else k)
		await runner.get_tree().process_frame
	on_k.call(1.0)


# --- Phase 1: break the old drive out -------------------------------------------------------

## ONE bite of the jackhammer, at one of the three places on a panel.
##
## Eighteen of these make the phase: three spots on each of six slabs, and the
## panel lets go on the third. The user's second note was that it was "just click
## repeated times in same spot, also too many times" - a hold that a tapper had to
## tap eight times, in the middle of the slab, six times over. Now the arrow walks
## to a different third of the panel each time, the tap has to land near it, the
## bit hammers there for `jack_bite` seconds, and a crack RUNS out from under it.
func jack_spot(runner: JobRunner, subject: Node3D, targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null or targets.is_empty():
		return
	# WHICH of the three places on this slab, chosen by the child's own finger on
	# one of the gold rings, and not by counting beats: the user asked to be able
	# to take them in any order.
	var n: int = site.picked()
	if n <= 0:
		# GO, the keyboard, or a tap queued while the rings were being
		# re-armed: the first OPEN spot of the panel being worked. Counting
		# beats (`done_in_step + 1`) could name a spot already done, and the
		# bite it spent there left a panel that never broke (the user's
		# 2026-09-14 playtest).
		n = drive.first_open_spot(drive.current_panel())
		if n <= 0:
			n = runner.done_in_step + 1
	var spot := drive.spot_marker(n)
	var at: Vector3 = spot.global_position if spot != null else targets[0].global_position
	var hammer := tool as HandTool
	var blows := [0]
	if hammer != null:
		# Standing on the spot, pointing straight down into it.
		hammer.hover(at, Vector3.DOWN, Vector3.FORWARD)
		await runner.get_tree().create_timer(config.tool_fly_time * 0.6, false).timeout
	site.set_breaker_dust(at, true)
	# The picture rattles for as long as the bit is in the concrete (the
	# improvement plan's 1.4): a floor under the shake, taken away at the end.
	site.shake_floor(config.shake_jack_floor)
	await _bite(runner, config.jack_bite, config, SOUND_BLOW, func(k: float) -> void:
		# The bit's own stroke, at its own rate, independent of the work's pace.
		var phase: float = fmod(float(Time.get_ticks_msec()) / 1000.0 * config.jack_hz, 1.0)
		var push: float = sin(phase * TAU) * 0.5 + 0.5
		if hammer != null:
			hammer.set_bit(push * config.jack_stroke)
			hammer.hover_instant(at + Vector3(0.0, config.jack_stroke * (1.0 - push), 0.0),
				Vector3.DOWN, Vector3.FORWARD)
		drive.jack_spot(n, k)
		# One kick, one puff and one bang per BLOW, not per frame.
		var blow := int(floor(float(Time.get_ticks_msec()) / 1000.0 * config.jack_hz))
		if blow != blows[0]:
			blows[0] = blow
			site.shake(config.shake_jack)
	, "jackhammer")
	site.set_breaker_dust(at, false)
	site.shake_floor(0.0)
	if hammer != null:
		hammer.set_bit(0.0)
	if not drive.panel_ready(drive.spot_panel(n)):
		site.dust_at(at, config.dust_size * 1.5)
		return
	# The last of this slab's three bites, wherever it was taken: it lets go.
	drive.break_panel(drive.spot_panel(n))
	site.shake(config.shake_break)
	site.sfx.play_group(SOUND_BREAK)
	site.dust_at(at, config.dust_size * 2.4)
	# The rubble is the only thing moving: let it settle before the gold wedge
	# moves on to the next panel.
	runner.mute_arrow(config.chunk_hop_time * 1.6)
	await runner.get_tree().create_timer(config.chunk_hop_time, false).timeout


# --- Phase 2: the skid steer pushes it out --------------------------------------------------

## The skid steer drives on, the child's own call (the big green button). The
## garage door goes up in front of it, because that is where it is going.
func call_skid(runner: JobRunner, _subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var site: Variant = runner.level
	await site.bring_machine("SkidSteer", config.arrive_time)


## ONE pass: the whole length of one column of the old drive, pushed out to the
## kerb and shoved onto the heap.
##
## This is the user's fourth note rebuilt from scratch. It used to take a BAND
## across the drive per pass, which meant reversing behind each band in turn -
## through the rubble it was about to push, and into the garage, which was a
## sealed mesh standing on the driveway. A COLUMN is pushed from one end in one
## pass, and the only place to start is inside the garage, which is now a building
## with a door that opens.
##
##   1. it crawls up the drive to the garage, bucket carried high, CLIMBING over
##      the broken concrete (`Driveway.ride_y` tips it as it goes)
##   2. it turns round on the spot inside the garage - the one move only a skid
##      steer can make
##   3. the child holds: nine metres of push, everything in that column in front
##      of the blade
##   4. it swings right off the end of the drive and shoves the load onto the heap
func push_rubble(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	var machine: Machine = site.machine("SkidSteer")
	if drive == null or machine == null:
		return
	# At work from the first move of the pass - lining up included - until it
	# is parked for the next one (4.5).
	machine.set_beacon_on(true)
	var lane := runner.done_in_step + 1
	var x := drive.lane_drive_x(lane)
	var start := Vector3(x, 0.0, Driveway.Z_APRON - config.garage_stand)
	var finish := Vector3(x, 0.0, Driveway.Z_KERB - 1.6)
	# Lined up on this column, inside the garage, facing back down the drive. The
	# first pass is already there - it drove in that way - so this only runs for
	# the passes after it, and it goes up the half of the drive it has CLEARED.
	if machine.global_position.distance_to(start) > 0.4:
		machine.set_bucket(1.0, 0.0)
		await site.drive_route(machine, [machine.global_position,
			Vector3(x, 0.0, Driveway.Z_KERB - 0.4), start], config.reverse_time, false, 1.5)
		machine.spin_to(0.0, config.spin_time * 1.6)
		await machine.arrived
	# Blade down on the dirt, and go - FROM WHERE IT IS. The end of a pass already
	# lines the machine up on the next lane and puts the blade DOWN (below), so a
	# lower that always started at "carried high" snapped the arm up 25 degrees
	# on the first frame of the second push and then spent `bucket_dump_time`
	# putting it back, with the machine standing still in the garage. Already
	# down: nothing to lower, and the crawl starts under the finger.
	var lift0 := machine.bucket_lift()
	var curl0 := machine.bucket_curl()
	if lift0 > 0.01 or curl0 > 0.01:
		await _ease(runner, config.bucket_dump_time, func(k: float) -> void:
			machine.set_bucket(lerpf(lift0, 0.0, k), lerpf(curl0, 0.0, k)))
	site.sfx.play_loop(SOUND_IDLE, "skid")
	var from := machine.global_position.z
	var to := finish.z
	# The wheels turn the distance really covered, so the z it stood at last
	# frame is kept in a ONE-ELEMENT ARRAY: a lambda captures a local by value,
	# and a plain float here would read back the same number every frame (the
	# GDScript trap that has cost this family a silent hang before).
	var was := [from]
	await _hold(runner, config.push_time, config, SOUND_RUBBLE, func(k: float) -> void:
		var at := lerpf(from, to, k)
		machine.global_position.z = at
		site.reseat(machine)
		machine.roll(at - was[0])
		was[0] = at
		# The blade is where the bucket's edge really is, so nothing has to
		# guess at an offset.
		drive.push_lane(lane, machine.bucket_edge_world().z)
		site.set_push_dust(machine.bucket_edge_world(), machine.global_transform.basis, runner.held)
	, "crawl", "skid")
	site.set_push_dust(machine.bucket_edge_world(), machine.global_transform.basis, false)
	# Off the end of the drive and round onto the heap, load still in front of it.
	# It stops a full machine-length clear of the pad's edge ramp whatever the
	# heap's distance: with the heap moved in (round 10) a stop measured from
	# the heap put its tail back over the excavation and it sank.
	var heap := drive.pile_point()
	var stop_x := maxf(heap.x - 2.2, Driveway.CENTRE_X + Driveway.WIDTH * 0.5 + 1.0)
	await site.drive_route(machine, [machine.global_position,
		Vector3(x, 0.0, Driveway.Z_KERB + 0.2), Vector3(stop_x, 0.0, heap.z)],
		config.heap_time, false, 1.8)
	drive.push_lane(lane, machine.bucket_edge_world().z, true)
	site.sfx.play_group("crumble")
	site.shake(config.shake_break * 0.6)
	# A blade does not dump: the load is SHOVED onto the heap and the blade lifts
	# clear of it. (The bucket used to curl and tip here; with the push blade
	# fitted - "skid steer bucket should be more like a bulldozer push blade" -
	# there is nothing to tip.)
	await _ease(runner, config.bucket_dump_time, func(k: float) -> void:
		machine.set_bucket(k, 0.0))
	# And it LINES UP ON THE NEXT LANE before the beat ends, so the next press
	# finds the machine inside the garage with the camera on it and the mark on
	# the rubble in front of its blade. Left at the heap, the camera stayed on
	# the heap and the mark was nine metres away off the picture ("it wanted me
	# to click something I couldn't see", the user, 2026-09-14).
	if lane < drive.push_lanes():
		var nx := drive.lane_drive_x(lane + 1)
		var next_start := Vector3(nx, 0.0, Driveway.Z_APRON - config.garage_stand)
		await site.drive_route(machine, [machine.global_position,
			Vector3(nx, 0.0, Driveway.Z_KERB - 0.4), next_start], config.reverse_time, false, 1.5)
		machine.spin_to(0.0, config.spin_time * 1.6)
		await machine.arrived
		await _ease(runner, config.bucket_dump_time, func(k: float) -> void:
			machine.set_bucket(1.0 - k, 0.0))
	site.sfx.stop_loop("skid")
	machine.set_beacon_on(false)


## The skid steer is done: it trundles off the way it came.
func skid_leave(runner: JobRunner, _subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var site: Variant = runner.level
	# A LOOK at the exit - the pad cleared, the machine pulling out - and the
	# job moves on while it trundles off up the street in the background (the
	# improvement plan's 3.2): the next place lights up while the picture is
	# still alive with a machine in it. `send_machine` hides it at its end on
	# its own; the next machine is never called inside its drive-out.
	site.send_machine("SkidSteer", config.leave_time)
	await runner.get_tree().create_timer(config.leave_look, false).timeout


# --- Phases 3 and 4: the forms --------------------------------------------------------------

## One form board swings down onto the edge of the hole. A TAP, not a hold:
## setting a board is one decisive move, and there are four of them.
func form_set(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null:
		return
	var i: int = site.picked()
	if i <= 0 or drive.form_is_in(i) or not drive.form_live(i):
		# Nothing picked (GO, the keyboard): the first board still waiting in the
		# group being set - by STATE, never "tap number n": in the kerb board's
		# own row the tap number is 1, and board 1 went in ten minutes ago.
		var open := drive.open_forms_in(drive.current_form_group())
		if open.is_empty():
			push_warning("SiteVerbs.form_set: no board is waiting")
			return
		i = open[0]
	# (The boards wait in the air over their places from the moment their row
	# opens - `SiteMain.arm_rings` hangs them. This verb used to hang ALL FOUR on
	# its first beat, which in the kerb board's own row lifted the three boards
	# already in back up into the air: 5.2's worst silent break.)
	site.sfx.play_group("whoosh")
	await _ease(runner, config.form_drop_time, func(k: float) -> void:
		drive.set_form(i, k))
	site.sfx.play_group("thunk")
	site.shake(config.shake_stake * 0.5)


## ONE stake, ONE blow of the sledge. Ten of them.
##
## "You hammer one side and three go in, instead it should be one hammer hit per
## stake." It was four beats of four held blows that drove a whole set of three at
## once; it is ten taps of one blow each now, and the camera is right down on the
## peg being hit (`CameraRig.STAKE`) so a child can see which one the arrow is on.
func stake_drive(runner: JobRunner, subject: Node3D, targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null or targets.is_empty():
		return
	var i: int = site.picked()
	if i <= 0 or drive.stake_is_in(i) or not drive.stake_live(i):
		# Nothing was picked, so this is GO or the keyboard: take the next stake
		# of the PAIR being worked (DESIGN 1a), not the next by number. The
		# camera is on that pair and the rings are on that pair; a blow landing
		# on a stake nine metres up the drive would be a blow nobody saw.
		var open := drive.open_stakes_in(drive.current_stake_group())
		if open.is_empty():
			push_warning("SiteVerbs.stake_drive: no peg is waiting")
			return
		i = open[0]
	# (The pegs stand waiting from the moment their row opens: `arm_rings`.)
	var head: Vector3 = drive.stake_home(i)
	var sledge := tool as HandTool
	var struck := [false]
	# The hammer is ALREADY UP over a peg of this pair - `arm_rings` stood it
	# there when the row opened, which is what says "hit this one" - so in the
	# common case there is nothing to do here and the swing starts in the frame
	# the finger lands. It used to `hover` in from the lawn and then sleep 0.33 s
	# on EVERY tap, so the child's press was answered by a tool arriving and the
	# blow landed 0.6 s late. If they took the OTHER peg of the pair, the head is
	# carried across AT THE TOP of its swing, which is what a person with a
	# sledge does, and still half the old wait.
	if sledge != null and not site.sledge_over(sledge, i):
		site.hold_sledge(sledge, i, 1.0, config.tool_fly_time * 0.5)
		await runner.get_tree().create_timer(config.tool_fly_time * 0.5, false).timeout
	var strike: float = clampf(config.sledge_strike, 0.05, 0.9)
	await _bite(runner, config.stake_time, config, "", func(k: float) -> void:
		# The stake moves FIRST in the frame, so the face below reads the cap
		# where it is now.
		drive.set_stake(i, clampf((k - strike) / maxf(0.85 - strike, 0.05), 0.0, 1.0))
		# The SWING: down from the wind-up it was already waiting at, on the
		# handle's own arc, accelerating into the cap at `sledge_strike`. Past
		# the strike `hold_sledge` reads the cap live, so the face rides the peg
		# down for free. It used to be a straight vertical translate with a fixed
		# basis - a lowering, not a swing - and the wind-up happened AFTER the
		# tap ("more like a swing of a sledge hammer", 2026-09-16).
		if sledge != null:
			var u := clampf(k / strike, 0.0, 1.0)
			site.hold_sledge(sledge, i, 1.0 - u * u, 0.0)
		if k >= strike and not struck[0]:
			struck[0] = true
			site.sfx.play_group(SOUND_STAKE)
			site.shake(config.shake_stake)
			site.dust_at(head, config.dust_size * 0.7, Driveway.DIRT.lightened(0.30))
	, "sledge")
	drive.set_stake(i, 1.0)


# --- Phase 5: the gravel base ---------------------------------------------------------------

func call_dump(runner: JobRunner, _subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var site: Variant = runner.level
	await site.bring_machine("DumpTruck", config.arrive_time)


## THE CHILD BACKS THE TRUCK IN (the improvement plan's 1.8, decision 4): the
## banksman's job. The tipper waits in the road, tail to the drive, engine
## ticking over and beacon turning; a finger on it and it backs up the drive,
## beeping, for as long as the finger holds - and stops where it is when it
## lifts. The street leg before it stays the machine's own.
func back_dump(runner: JobRunner, _subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	await _back_in(runner, "DumpTruck", config)


## The mixer, backed to the kerb and no further; then its chute comes out (the
## user's words), which is the picture that says "this is about to pour".
func back_mixer(runner: JobRunner, _subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	await _back_in(runner, "ConcreteTruck", config)
	var site: Variant = runner.level
	var mixer: Machine = site.machine("ConcreteTruck")
	if mixer == null:
		return
	# No gold ring over a parked truck with nothing left to hold while the chute
	# swings out.
	runner.mute_arrow(config.chute_out_time + 0.2)
	site.sfx.play_group(SOUND_RAM)
	await _ease(runner, config.chute_out_time, func(k: float) -> void:
		mixer.set_chute(0.0, k * config.chute_fold_max))


## The held reverse leg both trucks share.
func _back_in(runner: JobRunner, kind: String, config: SiteConfig) -> void:
	var site: Variant = runner.level
	var m: Machine = site.machine(kind)
	if m == null or site == null:
		return
	var path: Array[Vector3] = site.back_route(kind, m.global_position)
	# Already lined up in play (the street leg ends facing it); a posed stop gets
	# the same small turn here.
	await site.face_route(m, path, true)
	m.set_path(path, true)
	m.set_beacon_on(true)
	if not site.sfx.is_looping("arrive"):
		site.sfx.play_loop(SOUND_IDLE, "arrive")
	await _hold(runner, config.back_time, config, SOUND_BEEPER, func(k: float) -> void:
		m.place_on_path(k * k * (3.0 - 2.0 * k))
		# The ring follows a truck still rolling to a stop after the lift.
		if not runner.held:
			runner.update_arrow()
	, "beeper", "arrive", config.back_ramp, true)
	m.place_on_path(1.0)
	# (No mute here: the next step's own arrow takes the ring off the truck in
	# this same frame, and a mute across the step boundary left the tip with no
	# ring and no mime at all when the finger was already up - the session-5
	# verification pass.)
	site.finish_arrival(kind)


## The bed goes up while the finger is down and the limestone runs out of the
## tailgate, the truck driving out as it tips so the load is laid as a windrow
## rather than dropped in one heap - which is how a base really goes in, and is
## also the only way a child can see the whole pad fill.
##
## "Dump truck should be a touch and hold and it drives out dropping rock." It is
## the finger on the picture that does it now, not the UP pad: there is only one
## thing this beat can do, and a pad to do it with was a control to learn for
## nothing.
func tip_gravel(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	var truck: Machine = site.machine("DumpTruck")
	if drive == null or truck == null:
		return
	# It was reversed up the drive, tailgate at the far end: it pulls FORWARD as it
	# tips, laying the load behind it, so its wheels stay off the new base.
	var from := truck.global_position.z
	var to := from + config.tip_crawl
	var was := [from]
	site.sfx.play_loop(SOUND_IDLE, "dump")
	truck.set_beacon_on(true)
	site.sfx.play_group(SOUND_RAM)
	await _hold(runner, config.tip_time, config, SOUND_GRAVEL, func(k: float) -> void:
		# The bed rises over the first third and stays up: a tipper does not
		# creep its ram up and down as it goes.
		truck.set_bed(clampf(k * 3.0, 0.0, 1.0))
		# And it EMPTIES as it goes. "The dump truck itself looks empty as it pulls
		# up" - it was, and then stone appeared on the drive from nowhere.
		truck.set_load(1.0 - k)
		var at := lerpf(from, to, k)
		truck.global_position.z = at
		site.reseat(truck)
		truck.roll(at - was[0])
		was[0] = at
		drive.gravel_fill(k)
		site.gravel_at(truck.bed_lip_world(), truck.global_transform.basis, k)
	, "gravel", "dump")
	drive.gravel_fill(1.0)
	truck.set_load(0.0)
	site.stop_gravel()
	await _ease(runner, config.tip_time * 0.25, func(k: float) -> void:
		truck.set_bed(1.0 - k))
	site.sfx.stop_loop("dump")
	truck.set_beacon_on(false)
	site.sfx.play_group("thunk")


func dump_leave(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var site: Variant = runner.level
	# The exit and the heap's fade both run in the background under the steel
	# (the plan's 3.2), after a look at the tipper pulling out.
	site.send_machine("DumpTruck", config.leave_time)
	# And the heap goes with it: the muck-away is off screen, the heap fades
	# as the tipper leaves, and the steel is laid on a clear site (round 13).
	var drive := subject as Driveway
	if drive != null:
		_fade_heap(runner, drive)
	await runner.get_tree().create_timer(config.leave_look, false).timeout
	# And never the next beat while its body is still over the pad: the plate
	# starts on the base and the kerb board goes in behind it, and neither may
	# share the drive with an eighteen-tonne truck (5.2's own check). At today's
	# numbers it has cleared it by now and this costs nothing.
	var truck: Machine = site.machine("DumpTruck")
	var waited := 0.0
	while truck != null and truck.visible and waited < 6.0 \
			and truck.global_position.z - truck.rear_overhang() < Driveway.Z_KERB + 0.6:
		waited += _dt(runner)
		await runner.get_tree().process_frame


## The rubble heap fading out as the tipper leaves, on its own clock.
func _fade_heap(runner: JobRunner, drive: Driveway) -> void:
	await _ease(runner, 1.6, func(k: float) -> void:
		if is_instance_valid(drive):
			drive.hide_rubble(k))
	if is_instance_valid(drive):
		drive.hide_rubble(1.0)


# --- Phase 5b: the steel --------------------------------------------------------------------

## One bar of the reinforcement dropped onto its chairs (DESIGN 2d). Twelve
## taps: the four long bars, then the cross bars in pairs down the drive. Each
## falls, clangs and bounces twice on its chairs, and once a cross bar has
## settled its ties pop onto the crossings one after another down it (4.7).
##
## The user, 2026-09-14: "missing rebar". A slab with no steel in it is not how
## a driveway is built, and the steel is the one part of the job a child never
## sees again once the concrete is in - so it gets its own phase and its own
## close shot, and the chairs say the thing that matters: the bars sit UP, in
## the middle of the slab, not on the ground.
func rebar_lay(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null:
		return
	var i: int = site.picked()
	if i <= 0:
		# GO or the keyboard: the next bar of the group being laid, which is the
		# one the camera is on.
		var open := drive.open_bars_in(drive.current_bar_group())
		i = open[0] if not open.is_empty() else runner.done_in_step + 1
	drive.show_chairs(true)
	site.sfx.play_group("whoosh")
	# The landing is an EVENT (the improvement plan's 4.7). It FALLS onto the
	# chairs - linear time, shaped as a fall in `set_bar` - with its ties held
	# back, clangs on contact...
	await _ease(runner, config.bar_drop_time, func(k: float) -> void:
		drive.set_bar(i, k, false), false)
	site.sfx.play_group(SOUND_BAR)
	site.shake(config.shake_stake * 0.35)
	# ...bounces twice, each hop a parabola under the same gravity as the fall,
	# the second a third the height of the first (`Driveway.bar_landing`)...
	var land := drive.bar_landing(i)
	var h1: float = land["h1"]
	var h2: float = land["h2"]
	if h1 > 0.0:
		await _ease(runner, float(land["t1"]), func(k: float) -> void:
			drive.bounce_bar(i, 4.0 * h1 * k * (1.0 - k)), false)
		await _ease(runner, float(land["t2"]), func(k: float) -> void:
			drive.bounce_bar(i, 4.0 * h2 * k * (1.0 - k)), false)
	# ...and once it has settled - not before: a tie on a bar still a centimetre
	# in the air hangs off its crossing - the black ties pop onto each crossing
	# in turn down the bar, a twist of wire each, so one tap plays a little run
	# across the picture. The verb waits for all of it, so the phase's done note
	# never lands on a pop still to come.
	var ties: Array[Node3D] = drive.bar_ties(i)
	for j in range(ties.size()):
		if j > 0:
			await runner.get_tree().create_timer(config.tie_stagger, false).timeout
		drive.pop_tie(ties[j], config.tie_pop_time)
		site.sfx.play_group(SOUND_TIE, 1.15 + 0.10 * float(j))
	if not ties.is_empty():
		await runner.get_tree().create_timer(config.tie_pop_time, false).timeout
	# Exactly home, every tie whole.
	drive.set_bar(i, 1.0)


# --- Phase 6: the concrete, and the chute ----------------------------------------------------

## The mixer comes down the street and backs its tail to the KERB - and no
## further, because the steel is down (DESIGN 2a): it never puts a wheel on the
## pad. From the road the main chute reaches nothing, so the extension chute
## is on (`Machine.fit_chute_extension`) and the pour lands in the kerb end of
## the form; the come-along brings the rest up.
##
## It comes down the street and STOPS in the road, waiting for the child to
## back it in (`back_mixer`, the plan's 1.8); the chute comes out after that.
func call_mixer(runner: JobRunner, _subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var site: Variant = runner.level
	await site.bring_machine("ConcreteTruck", config.arrive_time)


## THE beat (DESIGN 2a), and the one the user asked for a visual trick on:
##
##   "I think we should detach the chute from the truck and move the camera right
##    up to it, so the player feels like they are pouring the cement and we don't
##    have the truck in the way visually. Just the player moving the chute back
##    and forth and forward / backwards."
##
## So the truck stops being DRAWN (`Machine.show_only(["Chute"])`) and the camera
## comes in beside the spout. Everything else about it is unchanged and honest:
## the truck is still there, still creeping down the drive under the child's
## thumb, still rolling its wheels and still standing on the base. Nothing is
## duplicated, nothing teleports, and when the beat ends the truck is drawn again
## exactly where it really got to, ready to drive itself out.
##
##   LEFT / RIGHT  swing the chute across the width of the form
##   UP / DOWN     walk the pour down the drive and back up it
##
## Both halves of that are measured rather than invented. The chute's own swing
## reaches about 3.1 m across - very nearly the 3.6 m width - and folding it makes
## almost no difference to WHERE it lands (0.11 m, `machine_probe`), because the
## spout is already as far back as that arm reaches. The length of the drive is
## the TRUCK's job, exactly as it is on a real pour.
##
## Concrete lands where the spout really points, heaps up where it lands, and
## runs downhill into the lower cells - so pouring into one spot still fills the
## form, just slowly. The beat ends when every cell is up to grade. There is no
## way to fail; if the child goes still for `chute_hint_delay`, the arrow goes and
## hangs over the emptiest corner.
func pour_chute(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	var mixer: Machine = site.machine("ConcreteTruck")
	if drive == null or mixer == null:
		return
	var swing := 0.0
	var idle := 0.0
	var z := mixer.global_position.z
	var was := [z]
	mixer.spin_drum(config.drum_rps)
	# At work while it pours (4.5) - undrawn for the pour, and the light hangs
	# under the beacon's own mesh, so it goes with the body.
	mixer.set_beacon_on(true)
	mixer.set_chute(swing, config.chute_fold_max)
	mixer.set_chute_mud(true)
	# Not until the eye is AT the chute. This beat starts on the frame its step
	# is entered, while the shot is still easing down from the wide, and a truck
	# that blinked out of the wide picture with its chute left hanging in the
	# air was a teleport in front of the child (the improvement plan's 0.6). The
	# drum is already turning, so the flight down shows a truck at work.
	while runner.rig != null and runner.rig.is_moving():
		await runner.get_tree().process_frame
	# The truck goes away and the chute stays: the whole trick, in one call.
	mixer.show_only(["Chute"])
	site.sfx.play_loop(SOUND_DRUM, "mixer")
	site.sfx.play_loop(SOUND_CONCRETE, "concrete")
	drive.set_wet(config.wet_poured)
	site.set_pour(true)
	# How much concrete a second fills the whole form, if it all landed in it.
	var rate := (Driveway.GRADE - Driveway.BASE_TOP) * float(Driveway.CELLS_X * Driveway.CELLS_Z) \
		/ maxf(config.pour_time, 0.5)
	# How far the spout stands behind the truck, measured off the model, so the
	# truck's travel limits are worked out from where it really POURS.
	var reach := mixer.global_position.z - mixer.pour_point_world(Driveway.GRADE).z
	# THE TRUCK STAYS ON THE ROAD (DESIGN 2a, 2026-09-14). The steel is down on
	# the base and a wheel on a rebar chair is a wince a groundworker never
	# forgets, so the mixer stands at the kerb with its tail to the drive and only
	# creeps forward along the road. The chute reaches the kerb end of the form;
	# the rest is the come-along's job (`rake_pull`).
	var z_min: float = site.mixer_stand_z()
	var z_max: float = z_min + config.road_creep
	var band_from := z_min - reach - 0.45
	site.pour_band_from = band_from
	# The camera starts where the pour starts, not where it was left. It is fed the
	# TRUCK's position less the spout's straight-back offset, never the live pour
	# point: swinging the chute pulls the stream 0.87 m nearer the truck, and a
	# camera that followed that lurched back and forth every time the child touched
	# a side pad.
	site.set_pour_view(z - reach, 1.0)
	while drive.band_fraction(band_from) < config.band_done:
		var dt := _dt(runner)
		var moved := false
		if site.pad_held("left"):
			swing -= config.chute_swing_rate * dt
			moved = true
		if site.pad_held("right"):
			swing += config.chute_swing_rate * dt
			moved = true
		# UP means UP the picture (the improvement plan's 2.1): the CHUTE eye
		# looks up the drive toward the garage, so the pour goes up the screen
		# when the truck creeps BACK toward the kerb (-Z) and comes down the
		# screen when it creeps away along the road. It read backwards for
		# four playtests - the arrow that pointed at the garage sent the
		# concrete toward the child.
		if site.pad_held("up"):
			z -= config.truck_creep_speed * dt
			moved = true
		if site.pad_held("down"):
			z += config.truck_creep_speed * dt
			moved = true
		swing = clampf(swing, -config.chute_swing_deg, config.chute_swing_deg)
		# Along the road only: from the kerb, forward as far as the chute still
		# lands on the form. Never a wheel on the pad.
		z = clampf(z, z_min, z_max)
		mixer.global_position.z = z
		site.reseat(mixer)
		mixer.roll(z - was[0])
		was[0] = z
		mixer.set_chute(swing, config.chute_fold_max)
		var at := mixer.pour_point_world(Driveway.GRADE)
		drive.pour_at(at, rate * dt, dt)
		site.set_pour_point(mixer.spout_world(), at, mixer.spout_dir())
		# The camera walks down the drive after the pour, along its length only.
		site.set_pour_view(z - reach, dt)
		runner.partial(clampf(drive.band_fraction(band_from) / config.band_done, 0.0, 1.0))
		# The hint: only after the child has been still for a while, and it goes
		# the moment they touch a pad again.
		idle = 0.0 if moved else idle + dt
		if OS.has_environment("BC_DEBUG") and Engine.get_process_frames() % 40 == 0:
			var e := drive.emptiest_in_band(band_from)
			print("POUR_HINT idle %.2f moved %s held u/d/l/r %s/%s/%s/%s stick %s emptiest %s frac %.2f band %.2f pointer_lit %s"
				% [idle, str(moved), str(site.pad_held("up")), str(site.pad_held("down")),
					str(site.pad_held("left")), str(site.pad_held("right")), str(Pad.move()), str(e),
					drive.fill_frac_at(e), drive.band_fraction(band_from),
					str(site.hud.pointer.lit() if site.hud != null and site.hud.pointer != null else "-")])
		if idle > config.chute_hint_delay:
			# The arrow only: a ring means "tap here", and this beat is steered
			# with the pads. And only on a cell that LOOKS short - under half -
			# never on concrete that is plainly there (round 12: the emptiest
			# cell of a nearly full band was at 80% and read as finished).
			var empty := drive.emptiest_in_band(band_from)
			if drive.fill_frac_at(empty) < 0.5:
				runner.hold_arrow(empty, 0.45, Vector3.INF, false)
			else:
				runner.release_arrow()
		elif moved:
			runner.release_arrow()
		await runner.get_tree().process_frame
	# The chute KEEPS RUNNING into the next beat - the rake pulls what it lays -
	# so nothing is stopped here. `mixer_leave` puts the truck back together.
	# (No chime of its own: every phase the bar counts ends on the one "done"
	# note, from `SiteMain._on_step_done` - the plan's 1.6.)
	runner.release_arrow()


## THE COME-ALONG (DESIGN 2a). The chute goes on pouring into the kerb end of
## the form on its own, sweeping slowly; the child DRAGS the rake over the slab
## and the concrete comes up the form to it, a stroke at a time, from the fuller
## cells toward the kerb. It ends when every cell is up to grade.
##
## This is the "mini game kind of like the water and broom lines where you have
## to fill in all the drive way" the user asked for, and it is also simply how a
## crew whose truck cannot get onto the slab does it: pull the mud.
func rake_pull(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	var mixer: Machine = site.machine("ConcreteTruck")
	if drive == null or mixer == null:
		return
	var rake := tool as HandTool
	var reach := mixer.global_position.z - mixer.pour_point_world(Driveway.GRADE).z
	var band_from: float = site.mixer_stand_z() - reach - 0.45
	# The truck supplies FASTER than the rake can draw (`rake_pour_time`, half
	# of `pour_time`): the finger is the only thing the pull waits on. At the
	# chute's own rate the heap was drained in three strokes and the tool then
	# trickled for ten seconds under a moving finger, which reads as "I am doing
	# it wrong" (the improvement plan's 2.4).
	var rate := (Driveway.GRADE - Driveway.BASE_TOP) * float(Driveway.CELLS_X * Driveway.CELLS_Z) \
		/ maxf(config.rake_pour_time, 0.5)
	# Still pouring, still not drawn, whatever beat came before this one (a posed
	# rake starts here cold).
	mixer.spin_drum(config.drum_rps)
	mixer.show_only(["Chute"])
	site.sfx.play_loop(SOUND_DRUM, "mixer")
	site.sfx.play_loop(SOUND_CONCRETE, "concrete")
	site.set_pour(true)
	var clock := [0.0]
	mixer.set_chute_mud(true)
	if rake != null:
		var first := drive.rake_front_world(config.rake_reach, band_from)
		var fhead := Vector3(first.x, Driveway.GRADE + 0.012, first.z)
		var fhands: Vector3 = site.hand_hold(Vector3(0.20, -0.80, 0.55))
		rake.hover_instant(fhead, Vector3.DOWN, (fhands - fhead).normalized())
		rake.aim_handle_at(fhands)
	await _scrub(runner, config, SOUND_RAKE, func(at: Vector3, dt: float) -> void:
		var moved := drive.rake_to(at, config.rake_radius, config.rake_rate * dt, config.rake_reach, band_from)
		if rake != null:
			# The blade on the slab under the finger, the handle rising toward the
			# child (the camera stands at the garage door, so +Y of the tool is up
			# the drive), rocking as it pulls.
			# The handle runs from the head to the child's HANDS, as the broom's
			# does (round 8: the rake receded to a sliver as the front advanced).
			var pull: float = sin(clock[0] * 7.0) * 0.06 * (1.0 if moved > 0.0 else 0.3)
			var rhead := Vector3(at.x, Driveway.GRADE + 0.012, at.z - pull)
			var hands: Vector3 = site.hand_hold(Vector3(0.20, -0.80, 0.55))
			rake.hover_instant(rhead, Vector3.DOWN, (hands - rhead).normalized())
			rake.aim_handle_at(hands)
	, func() -> float:
		return clampf(drive.fill_fraction() / config.pour_done, 0.0, 1.0) * config.scrub_done,
		func() -> Vector3: return drive.rake_front_world(config.rake_reach, band_from), "rake",
		func(dt: float) -> void:
			# Between strokes the rake rests at the HINT - the front of the work -
			# and follows it, so the tool is in the picture when the beat begins
			# and never half out of the frame over a board (round 12).
			if rake != null and not runner.held:
				var rest := drive.rake_front_world(config.rake_reach, band_from)
				var rest_head := Vector3(rest.x, Driveway.GRADE + 0.012, rest.z)
				if OS.has_environment("BC_DEBUG") and Engine.get_process_frames() % 20 == 0:
					print("RAKE_REST rest %s head %s arrow %s" % [str(rest), str(rake.global_position),
						str(runner.arrow_point() if runner.has_method("arrow_point") else Vector3.INF)])
				var eased := rake.global_position.lerp(rest_head, clampf(dt * 4.0, 0.0, 1.0))
				var rest_hands: Vector3 = site.hand_hold(Vector3(0.20, -0.80, 0.55))
				rake.hover_instant(eased, Vector3.DOWN, (rest_hands - eased).normalized())
				rake.aim_handle_at(rest_hands)
			# The chute, on its own: a slow sweep across the kerb end, laying the
			# heap the rake draws on.
			clock[0] += dt
			var swing: float = sin(clock[0] * 0.55) * config.chute_swing_deg * 0.85
			mixer.set_chute(swing, config.chute_fold_max)
			var at := mixer.pour_point_world(Driveway.GRADE)
			drive.pour_at(at, rate * dt, dt)
			site.set_pour_point(mixer.spout_world(), at, mixer.spout_dir())
			# The eye follows the concrete's front down the drive - only between
			# strokes, so the ground never moves under a finger.
			if not runner.held:
				site.set_rake_view(drive.pour_front_z(), 3.0, dt))
	mixer.spin_drum(0.0)
	mixer.set_beacon_on(false)
	mixer.set_chute_mud(false)
	# The truck stays undrawn: it comes back FADED IN over the eye's ease out to
	# the wide, in `mixer_leave` (the improvement plan's 0.6). Made whole here it
	# popped into the top of the PULL frame the moment the rake was done.
	site.set_pour(false)
	site.sfx.stop_loop("concrete")
	site.sfx.stop_loop("mixer")
	runner.release_arrow()
	# The last few per cent SETTLE to grade as the beat ends, so no sandy patch
	# is left under the hose (round 12).
	await _ease(runner, 0.8, func(k: float) -> void:
		drive.settle(k))
	drive.settle(1.0)


func mixer_leave(runner: JobRunner, _subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var site: Variant = runner.level
	var mixer: Machine = site.machine("ConcreteTruck")
	if mixer != null:
		# Whole again before it drives off, whatever the pour left it as - FADED
		# in over the eye's ease out to the wide, which this beat starts on. It
		# used to pop in whole at the rake's end, in the top of the PULL frame;
		# waiting for the wide to settle only moved the pop to where the truck
		# is biggest. A body coming up out of nothing while the picture is
		# moving is the gentlest the user's own trick can be (the improvement
		# plan's 0.6). The chute, which was never hidden, is left alone.
		var body := mixer.body_meshes(["Chute"])
		mixer.show_only([])
		# At work again from the moment it is seen: its beacon fades in with the
		# body and turns through the fold, as the others' do through their last
		# moves (4.5).
		mixer.set_beacon_on(true)
		for mi in body:
			site.drive.fade_node(mi, 0.0)
		await _ease(runner, config.shot_time, func(k: float) -> void:
			for mi in body:
				site.drive.fade_node(mi, k))
		for mi in body:
			site.drive.fade_node(mi, 1.0)
		await _ease(runner, config.chute_out_time * 0.7, func(k: float) -> void:
			mixer.set_chute(0.0, config.chute_fold_max * (1.0 - k)))
	# The fade-in and the fold were the look; the drive-out runs on in the
	# background under the hose (the plan's 3.2), seen starting.
	site.send_machine("ConcreteTruck", config.leave_time)
	await runner.get_tree().create_timer(config.leave_look * 0.5, false).timeout


# --- Phases 7 to 10: the finishing ----------------------------------------------------------

## The hose, DRAGGED over the slab until all of it is wet.
##
## "Player should have to move water around and get it all wet them selves not
## just a basic click." It was a hold that swept itself up the drive on a timer -
## the child's finger only decided when. Now the nozzle is wherever the finger is,
## the slab goes dark where the water has been and stays pale where it has not,
## and the beat ends when there is no pale left.
func spray_water(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null:
		return
	var hose := tool as HandTool
	if hose != null:
		hose.spray(true, Color(0.62, 0.80, 0.95, 0.8))
	# Where the finger last aimed it, for re-holding between strokes: a one-element
	# Array, because a lambda captures a plain local by value.
	var last_at := [Vector3.INF]
	await _scrub(runner, config, SOUND_WATER, func(at: Vector3, dt: float) -> void:
		if hose != null:
			# THE CHILD IS HOLDING IT (the user, 2026-09-12: "like you are the
			# one spraying"). The nozzle rides a fixed arm's length in front of
			# the eye, down and to the right the way a hose is held, and only
			# its AIM follows the finger - so it stays big in the near corner of
			# the picture however far up the drive the water is landing, and the
			# jet is thrown that far rather than dribbling out at the camera. The
			# hose runs from its grip off the bottom of the picture (4.3).
			site.hold_hose(hose, at)
			last_at[0] = at
		drive.paint_water(at, config.scrub_radius, config.water_rate * dt, config.wet_sprayed)
	, func() -> float: return drive.water_coverage(),
		func() -> Vector3: return drive.driest_world(), "water",
		# Between strokes the hose stays in the hands where the eye is NOW: a
		# press made during the ease into HAND must not leave the nozzle and its
		# hose where the old camera put them.
		func(_dt: float) -> void:
			# (With a finger down `on_point` holds it this frame anyway.)
			if hose != null and last_at[0] != Vector3.INF and not runner.held:
				site.hold_hose(hose, last_at[0]))
	# The dry corners the 85% left come up on their own as the hose is put
	# away: the child sees the whole slab wet (the improvement plan's 1.6).
	await _ease(runner, 0.6, func(k: float) -> void:
		drive.finish_water(k))
	if hose != null:
		hose.spray(false)


## The screed board is DRAGGED down the drive by the finger (fourth playtest:
## "improve drag board across touch" - it was a press-and-hold that walked the
## board itself). The board follows the finger toward the kerb, never back and
## no faster than a person walks it; the finger's sideways wander is the saw.
## The slab goes flat BEHIND the board and stays lumpy in front of it. The eye
## catches up with the board only between strokes, so the ground never moves
## under a finger.
func screed_pull(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null:
		return
	var board := tool as HandTool
	var line := [Driveway.Z_APRON]
	var place := func(z: float, x_off: float) -> void:
		if site != null:
			site.drag_tool_at = Vector3(Driveway.CENTRE_X + x_off, Driveway.GRADE, z)
		if board != null:
			# Laid across the drive, its own length spanning the forms: +Z is
			# the way it faces, so it looks down the drive at the concrete it
			# has not struck off yet.
			board.hover_instant(Vector3(Driveway.CENTRE_X + x_off, Driveway.GRADE + 0.002, z),
				Vector3.FORWARD, Vector3.UP)
	place.call(line[0], 0.0)
	if site != null:
		site.set_screed_view(line[0])
	# The grab is taken ONCE, at the press, by a finger ON the board (within
	# `drag_grab` of its line) and kept until the finger lifts; from then on the
	# board goes where that finger goes, toward the kerb, never back, and no
	# faster than `screed_drag_speed` - a fast flick lags and catches up, which
	# is what pulling feels like (the improvement plan's 2.5). A finger resting
	# further down the slab never has hold of it.
	var grab := [false]
	var pull := func(at: Vector3, dt: float) -> bool:
		if not grab[0]:
			if absf(at.z - line[0]) > config.drag_grab \
					or absf(at.x - Driveway.CENTRE_X) > Driveway.WIDTH * 0.5 + 0.6:
				return false
			grab[0] = true
		var want := clampf(at.z, line[0], Driveway.Z_KERB)
		line[0] = minf(want, line[0] + config.screed_drag_speed * dt)
		var saw := clampf(at.x - Driveway.CENTRE_X, -config.screed_saw, config.screed_saw)
		place.call(line[0], saw)
		drive.screed((line[0] - Driveway.Z_APRON) / Driveway.LENGTH)
		return true
	var progress := func() -> float:
		return (line[0] - Driveway.Z_APRON) / Driveway.LENGTH
	var hint := func() -> Vector3:
		return Vector3(Driveway.CENTRE_X, Driveway.GRADE, line[0] + 0.35)
	var follow := func(dt: float) -> void:
		if not runner.held:
			grab[0] = false
		if site != null and (not runner.held or site.drag_is_world()):
			site.ease_screed_view(line[0], dt)
	await _scrub(runner, config, SOUND_DRAG, pull, progress, hint, "screed", follow, 0.995)
	drive.screed(1.0)
	if site != null:
		site.drag_tool_at = Vector3.INF
	# The board comes up off the kerb form with a knock: the strike is done
	# (the plan's 1.6).
	if board != null and site != null:
		board.hover(board.global_position + Vector3(0.0, 0.3, 0.0), Vector3.FORWARD, Vector3.UP)
		await runner.get_tree().create_timer(config.tool_fly_time * 0.6, false).timeout
		site.sfx.play_group("thunk")


## One control joint PULLED across the slab by the finger (fourth playtest:
## "you should pull to make the joint lines, not just hold down"). The
## groover's sled follows the finger from the near form to the far one, never
## back, and the groove follows the sled. A slab this long cracks wherever it
## likes unless it is told where to - that IS the phase.
func joint_cut(runner: JobRunner, subject: Node3D, targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null:
		return
	# Joints are numbered from ONE, as the job's `Joint_*` rows are: joint 1 is a
	# third of the way up the drive and joint 2 two thirds.
	var i := runner.done_in_step + 1
	var z := drive.joint_z(i)
	if not targets.is_empty():
		z = targets[0].global_position.z
	var jointer := tool as HandTool
	var x0 := Driveway.CENTRE_X - Driveway.WIDTH * 0.5
	var sled := [x0]
	var place := func() -> void:
		if site != null:
			site.drag_tool_at = Vector3(sled[0], Driveway.GRADE, z)
		if jointer == null or site == null:
			return
		var jhands: Vector3 = site.hand_hold(Vector3(0.20, -0.80, 0.55))
		var jpt := Vector3(sled[0], Driveway.GRADE, z)
		jointer.hover_instant(jpt, Vector3.DOWN, (jhands - jpt).normalized())
		jointer.aim_handle_at(jhands)
		jointer.align_head(Vector3.RIGHT)
	place.call()
	# The grab is taken ONCE, at the press, by a finger ON the sled, and kept
	# until the finger lifts: from then on the sled goes where that finger
	# goes, across toward the far form, never back, and no faster than
	# `joint_drag_speed` (the improvement plan's 2.5). A finger that wanders a
	# hand's width off the line mid-pull no longer drops it.
	var grab := [false]
	var loosen := func(_dt: float) -> void:
		if not runner.held:
			grab[0] = false
	await _scrub(runner, config, SOUND_DRAG, func(at: Vector3, dt: float) -> bool:
		if not grab[0]:
			if absf(at.x - sled[0]) > config.drag_grab or absf(at.z - z) > config.drag_grab:
				return false
			grab[0] = true
		var want := clampf(at.x, sled[0], x0 + Driveway.WIDTH)
		sled[0] = minf(want, sled[0] + config.joint_drag_speed * dt)
		place.call()
		drive.cut_joint(i, (sled[0] - x0) / Driveway.WIDTH)
		return true
	, func() -> float: return (sled[0] - x0) / Driveway.WIDTH,
		func() -> Vector3: return Vector3(minf(sled[0] + 0.3, x0 + Driveway.WIDTH - 0.2), Driveway.GRADE, z),
		"joint", loosen, 0.995)
	drive.cut_joint(i, 1.0)
	if site != null:
		site.drag_tool_at = Vector3.INF
	site.sfx.play_group("clip")


## The broom, DRAGGED over ONE BAY of the slab per beat - the three concrete
## squares between the control joints, the eye lined up on the side of each
## (fourth playtest: "do it 3 times, once per concrete square, camera lined up
## on the side so you can have a chance at trying to get them parallel with
## the joint lines"). The brushed lines run the way the FINGER moves, so a
## stroke up and down the picture comes out parallel to the joints, and the
## slab dries pale where it has been finished.
func broom_finish(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null:
		return
	var broom := tool as HandTool
	var bay := clampi(runner.done_in_step + 1, 1, drive.bay_count())
	var band := drive.bay_range(bay)
	var last := [Vector3.INF]
	var dir := [Vector3.ZERO]
	await _scrub(runner, config, SOUND_BROOM, func(at: Vector3, dt: float) -> void:
		var hands: Vector3 = site.hand_hold(Vector3(0.20, -0.80, 0.55))
		if broom != null:
			# The handle runs from the head to the child's HANDS, so it comes
			# out of the bottom of the picture instead of ending in mid-air.
			var head := Vector3(at.x, Driveway.GRADE + 0.01, at.z)
			broom.hover_instant(head, Vector3.DOWN, (hands - head).normalized())
			broom.aim_handle_at(hands)
		# The stroke: the finger's own motion once it has moved a hand's width;
		# toward the hands until then.
		# No marks until the finger has moved a hand's width: laid on the first
		# touch they would run toward the hands, not the way the stroke goes.
		if last[0] == Vector3.INF:
			last[0] = at
			dir[0] = Vector3.ZERO
		elif (at - last[0]).length() > 0.04:
			dir[0] = at - last[0]
			last[0] = at
		drive.paint_broom(at, config.scrub_radius, config.broom_rate * dt, config.broom_dry,
			Vector3(dir[0].x, 0.0, dir[0].z), band.x, band.y)
	, func() -> float: return drive.broom_coverage_in(band.x, band.y),
		func() -> Vector3: return drive.roughest_world_in(band.x, band.y), "broom")
	# The bay finishes itself as the broom lifts: the last patches take their
	# lines and dry (the improvement plan's 1.6).
	await _ease(runner, 0.5, func(k: float) -> void:
		drive.finish_bay(bay, k))
	if broom != null and site != null:
		var lift_hands: Vector3 = site.hand_hold(Vector3(0.20, -0.80, 0.55))
		var head_now := broom.global_position
		broom.hover(head_now + Vector3(0.0, 0.25, 0.0), Vector3.DOWN, (lift_hands - head_now).normalized())


# --- Phase 5a: the plate compactor ----------------------------------------------------------

## PACK THE BASE (the improvement plan's 5.1, the user's decision 6): one bay of
## loose limestone per beat, DRAGGED. The plate is picked up by a finger ON it
## and walks where that finger goes, no faster than a person walks one, kept
## inside the forms and inside its bay; every cell round it packs, its stones lie
## down flat and the bed goes a step paler; the picture rattles while it works.
## A finger held still packs the plate's own patch - a plus sign - and nothing
## more, so this cannot be `_hold`; a finger resting on the base away from the
## plate moves nothing (the screed's rule: a tool moves only under the finger).
func compact_base(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null or site == null:
		return
	var plate := tool as HandTool
	# ONE beat over the WHOLE base, ended by a CLOCK and not by coverage (the
	# playtest of 2026-09-16: the child could not get past this phase). Bay 0
	# means "anywhere between the apron and the kerb" to `clamp_plate` and
	# `plate_at`; `secs` counts only the frames the plate is really working.
	var bay := 0
	var at := [site.plate_at(0)]
	var secs := [0.0]
	site.pack_worked = 0.0
	var grab := [false]
	# Where the finger took hold relative to the plate: a finger on the orange
	# cowl lands a metre behind the plate on the base, and without the offset a
	# still finger there walked the plate away (the verification pass).
	var off := [Vector3.ZERO]
	var work := func(finger: Vector3, dt: float) -> bool:
		var here: Vector3 = at[0]
		if not grab[0]:
			if site.drag_is_world():
				if Vector2(finger.x - here.x, finger.z - here.z).length() > config.drag_grab:
					return false
				off[0] = Vector3.ZERO
			else:
				# The press's own rule (`SiteMain.plate_under`): on the drawn
				# machine or within reach of it on the base.
				if not site.plate_under(site.touch_point()):
					return false
				off[0] = Vector3(finger.x - here.x, 0.0, finger.z - here.z)
			grab[0] = true
		var want: Vector3 = drive.clamp_plate(finger - off[0], bay)
		# No further from the child's hands in one stroke than the handle
		# reaches: past it the grip was left in the picture (the verification
		# pass). Lifting lets the eye, and the hands, walk after it.
		var hands: Vector3 = site.plate_hands()
		var reach := Vector2(want.x - hands.x, want.z - hands.z)
		if reach.length() > PLATE_REACH:
			reach = reach.normalized() * PLATE_REACH
			want = drive.clamp_plate(Vector3(hands.x + reach.x, 0.0, hands.z + reach.y), bay)
		var d := want - here
		d.y = 0.0
		at[0] = here + d.limit_length(config.plate_speed * dt)
		# No band: it packs wherever the child takes it.
		drive.paint_pack(at[0], config.plate_radius, config.pack_rate * dt)
		secs[0] += dt
		site.pack_worked = secs[0]
		site.shake_floor(config.shake_plate_floor)
		site.hold_plate(plate, at[0], bay, true)
		return true
	var hint := func() -> Vector3:
		return site.drag_tool_at
	var each := func(dt: float) -> void:
		# Every frame first: the rattle's floor drops and the head stops buzzing
		# unless `work` raises them again in this same frame.
		site.shake_floor(0.0)
		if not runner.held:
			grab[0] = false
		# The eye walks after the plate only between strokes (or under a world
		# cursor), never under a dragging finger.
		if not runner.held or site.drag_is_world():
			site.ease_plate_view(at[0], dt)
		site.hold_plate(plate, at[0], bay, false)
	# The gate is TIME, not coverage. `_scrub` still does everything else it does
	# - counts only working frames, fills the bar through `runner.partial`, hangs
	# the white mime after `chute_hint_delay` of nothing happening - it just asks
	# a clock how far along the child is instead of asking the ground.
	await _scrub(runner, config, SOUND_PLATE, work,
		func() -> float: return secs[0] / maxf(config.pack_seconds, 0.5),
		hint, "plate", each, 1.0, Driveway.BASE_TOP)
	site.shake_floor(0.0)
	site.hold_plate(plate, at[0], bay, false)
	# Everything the child did not reach goes down WITH what they did, as the
	# plate lifts (the plan's 1.6). The whole base settles, so the phase ends on
	# ground that is visibly, wholly packed - not on a switch being thrown.
	await _ease(runner, config.pack_finish_time, func(k: float) -> void:
		for b in range(1, drive.bay_count() + 1):
			drive.finish_pack_bay(b, k))
	# Done. It goes back to the grass with the rest of the kit in the phase's
	# hold (`SiteMain.phase_done`), upright and whole - never faded out in the
	# held picture (the verification pass).
	site.drag_tool_at = Vector3.INF


# --- The end of the job: the cure and the strip -----------------------------------------------

## LATER THAT DAY: the cones go across the mouth of the drive, the light goes to
## evening and the slab goes off. It is a beat of its own now, before the child
## strips the forms (5.3) - boards do not come off concrete broomed a second ago.
func slab_cure(runner: JobRunner, _subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var site: Variant = runner.level
	if site == null:
		return
	await site.cure_slab(config.cure_time)


## ONE FORM BOARD OFF (the improvement plan's 5.3): what the child put in, the
## child takes out. Its pegs are drawn, the board is prised off the clean edge of
## the new slab, lifted and laid on the grass, and the trench outside it is
## backfilled. The rings are on all three at once and a tap anywhere on a board
## counts (`SiteMain._board_under`).
func form_strip(runner: JobRunner, subject: Node3D, _targets: Array[Node3D],
		_tool: Node3D, config: SiteConfig) -> void:
	var drive := subject as Driveway
	var site: Variant = runner.level
	if drive == null or site == null:
		return
	var i: int = site.picked()
	if i <= 0 or not drive.form_strips(i) or drive.form_is_stripped(i):
		var open := drive.open_strip_forms()
		if open.is_empty():
			return
		i = open[0]
	var pried := [false]
	var landed := [false]
	await _bite(runner, config.strip_board_time, config, "", func(k: float) -> void:
		drive.strip_form(i, k)
		if k >= Driveway.STRIP_PULL_END and not pried[0]:
			# The board breaks free of the concrete.
			pried[0] = true
			site.sfx.play_group("thud")
		if k >= 0.999 and not landed[0]:
			landed[0] = true
			site.sfx.play_group("thunk")
			site.shake(config.shake_stake * 0.3)
	)
	drive.strip_form(i, 1.0)
