class_name JobRunner
extends Node
## Plays a `JobDef` (DESIGN 2). It is the whole of the game loop: the level owns
## the lot, the machines and the celebration, and everything between "there is
## an old driveway here" and "there is a new one" happens here.
##
## Car Garage's runner, with the car taken out of it. What is kept is everything
## that was hard to get right:
##   * the camera moves to the step's shot through `CameraRig`, anchored to a
##     node on the SUBJECT so every panel frames itself,
##   * the HUD's gold arrow goes over the step's target (or over the HUD button
##     a BUTTON step waits for),
##   * one tap, or one press of that button, dispatches the step's `verb` to the
##     handler of the same name on `SiteVerbs`,
##   * exactly ONE tap is kept while a verb is running and fired the moment the
##     verb ends - a child taps right through the BRRRT of a jackhammer and the
##     next panel has to answer, or the toy feels broken when it is busiest,
##   * a HOLD runs while the finger is down, pauses where it is when it lifts,
##     and carries into the next step when that is a hold on the same thing.
##
## What CHANGED is only how a target name is looked up: there are no nuts, hubs
## or bay parts, so `find_target` asks the driveway and the machines instead.
## Nothing here knows what a form board is.

## One beat finished. `progress` is how many of the job's progress steps are
## done now, which is what the HUD bar shows.
signal beat_done(progress: int)
## Step `i` of the job is finished, all of its taps.
signal step_done(i: int)
## The last step is finished: the driveway is built.
signal job_done
## Where the child is in the job changed: step `index` was entered, or a beat
## of it finished with `done` of its places done. What the save is written on
## (the plan's 6.2) - never `beat_done`, which fires mid-hold for the bar and
## never for a row the bar does not count (a call, a back-in, a leave).
signal place_changed(index: int, done: int)

## How big the things a step can aim at are, in metres, by the start of the
## target's name - so the HUD can size the arrow to its target instead of
## laying one fixed wedge over a 3 m slab and a 5 cm stake alike.
const TARGET_RADIUS := {
	"Panel": 0.85,
	# One of the three places the hammer is worked on a panel: a third of a slab,
	# not the whole thing, because aiming at the right third IS the phase now.
	"Jack": 0.40,
	"Rubble": 1.10,
	"Form": 0.22,
	"Stake": 0.07,
	"Bar": 0.30,
	"Joint": 0.70,
	"Slab": 1.40,
	"Machine": 0.80,
	# A truck the child is backing in (the plan's 1.8): its tail.
	"Back": 0.80,
	"Pile": 0.70,
}

var job: JobDef
## What the job is being done TO: the driveway. Deliberately a `Node3D` and not
## `Driveway`, so a second job in this game (a patio, a path) can hand the same
## runner its own subject without either class knowing about the other.
var subject: Node3D
var config: SiteConfig
var verbs: SiteVerbs
var hud: SiteHud
var rig: CameraRig
## The `SiteMain` that owns the lot - its machines, its tools, its noise.
## Deliberately UNTYPED: naming the type here would make `site_main.gd` and
## `site_verbs.gd` depend on each other, and a cycle between two `class_name`
## scripts is a parse error that says nothing about why.
var level: Variant = null
## The tools the level owns, by the name a step asks for: `jackhammer`.
var tools: Dictionary = {}

## Which step of the job we are on, and how many of its taps are done.
var index: int = -1
var done_in_step: int = 0
## Progress steps done, 0 .. `job.total_weight()`.
var progress: int = 0
## True while a verb is playing, so taps queue instead of overlapping.
var busy: bool = false
## No job is running (before `start`, and after the last step).
var finished: bool = true

var _queued_tap: bool = false
## A HOLD step's finger is down right now. The hold verb reads it every frame;
## letting go pauses the work exactly where it is.
var held: bool = false
## A point a VERB has taken the arrow to while it plays (`INF` when none has).
var _held_arrow: Vector3 = Vector3.INF
var _held_radius: float = 0.0
var _held_centre: Vector3 = Vector3.INF
var _held_ring: bool = true
## Nothing points anywhere until this moment on the clock (`mute_arrow`).
var _arrow_quiet_until: float = -1.0


func setup(site: Variant, hud_node: SiteHud, camera_rig: CameraRig, cfg: SiteConfig,
		verb_book: SiteVerbs) -> void:
	level = site
	hud = hud_node
	rig = camera_rig
	config = cfg
	verbs = verb_book


# --- Running a job -----------------------------------------------------------------------

## Starts `def` on `what`, from the first step. `animate` is only about the
## CAMERA: false snaps to the first step's shot (the level opening, a
## screenshot, a test), true eases to it.
func start(def: JobDef, what: Node3D, animate: bool = false) -> void:
	job = def
	subject = what
	index = -1
	done_in_step = 0
	progress = 0
	busy = false
	finished = false
	_queued_tap = false
	_held_arrow = Vector3.INF
	_arrow_quiet_until = -1.0
	_enter(0, animate)


## Nothing to play: before the job and after it.
func stop() -> void:
	finished = true
	busy = false
	_queued_tap = false
	_held_arrow = Vector3.INF
	_arrow_quiet_until = -1.0
	index = -1
	done_in_step = 0


func current_step() -> JobStep:
	if job == null or index < 0 or index >= job.steps.size():
		return null
	return job.steps[index]


func step_count() -> int:
	return job.steps.size() if job != null else 0


func total_weight() -> int:
	return job.total_weight() if job != null else 0


func is_busy() -> bool:
	return busy


## Is the child's next move a tap on the picture?
func waiting_for_tap() -> bool:
	var s := current_step()
	return not finished and s != null and s.kind == JobStep.Kind.TAP


## Is the current step one the child HOLDS - before the finger is down, and
## while the verb is running with it up or down?
func waiting_for_hold() -> bool:
	var s := current_step()
	return not finished and s != null and s.kind == JobStep.Kind.HOLD


## Which HUD button is waiting, or "" when none is.
func waiting_button() -> String:
	var s := current_step()
	if finished or s == null or s.kind != JobStep.Kind.BUTTON:
		return ""
	return s.button_id()


## A tap on the picture. Returns false when this step does not take taps.
func tap() -> bool:
	if finished or not waiting_for_tap():
		return false
	if busy:
		# KEPT, not dropped.
		_queued_tap = true
		return true
	_play_beat()
	return true


## Forgets a tap that was kept while a beat ran. The level calls it when the
## ring that tap landed on is no longer live - the step has moved on, or the
## spot was the one the running bite did - so a kept tap is never spent on a
## place the child did not choose (the improvement plan's 0.4).
func drop_queued_tap() -> void:
	_queued_tap = false


## The finger on a HOLD step, down (`true`) or up. The first press starts the
## verb; every press and release after that reaches the verb through `held`, so
## letting go pauses the work where it is and pressing again carries on.
func hold(on: bool) -> bool:
	if finished or not waiting_for_hold():
		held = false
		return false
	var was := held
	held = on
	if on and not busy:
		_play_beat()
	elif on and not was:
		# A re-press on a paused HOLD takes the resting ring down, as a first
		# press does (`_play_beat`): it was left hanging where a truck had stopped
		# while the truck backed away (the session-5 verification pass). On the
		# press EDGE only - the pads and the stick call this every frame.
		update_arrow()
	elif not on:
		# A hold paused mid-beat gets its arrow back (the resting-hold branch).
		update_arrow()
	return true


## A HOLD verb's progress inside its one beat, 0..1, for the bar: the beat's
## `progress_weight` stops are handed out as the work goes, not all at the end.
func partial(k: float) -> void:
	var s := current_step()
	if s == null or job == null:
		return
	var want := job.weight_before(index, done_in_step) \
		+ int(floor(clampf(k, 0.0, 1.0) * float(s.progress_weight) + 0.0001))
	if want != progress:
		progress = want
		beat_done.emit(progress)


## A HUD button was pressed. `id` is the button, not the verb.
func press_button(id: String) -> bool:
	if finished or busy or waiting_button() != id:
		return false
	_play_beat()
	return true


# --- The step machine ---------------------------------------------------------------------

## Enters step `i`: the camera moves to its shot, the arrow finds its target,
## and an AUTO step starts playing at once.
func _enter(i: int, animate: bool = true) -> void:
	# A finger still DOWN from a HOLD step carries into the next step when that
	# is a HOLD on the SAME thing: a child who keeps holding keeps working. A
	# hold on a different thing wants a new press, on it.
	var carry := held and job != null and index >= 0 and index < job.steps.size() \
		and i < job.steps.size() and job.steps[i].kind == JobStep.Kind.HOLD \
		and job.steps[index].kind == JobStep.Kind.HOLD \
		and job.steps[i].target == job.steps[index].target
	index = i
	done_in_step = 0
	held = carry
	if job == null or i >= job.steps.size():
		_finish()
		return
	var s := job.steps[i]
	_go_to_shot(s, animate)
	if level != null:
		level.present_tool(s.tool, not animate)
		level.arm_pads(s.verb)
		level.arm_rings(s, done_in_step)
	_arm_button(s)
	update_arrow()
	place_changed.emit(index, done_in_step)
	if s.kind == JobStep.Kind.AUTO or carry:
		_play_beat()


func _finish() -> void:
	finished = true
	busy = false
	_queued_tap = false
	_held_arrow = Vector3.INF
	index = job.steps.size() if job != null else 0
	if hud != null:
		hud.hide_arrow()
	if level != null:
		level.arm_rings(null, 0)
	job_done.emit()


## The camera shot a step is played in, anchored to the node the rig wants.
func _go_to_shot(s: JobStep, animate: bool) -> void:
	if rig == null or s.shot == "" or not rig.has_shot(s.shot):
		return
	go_shot(s.shot, animate)


## Move the camera to a named shot NOW, from wherever the job is. A step names
## the shot it starts in, but a beat may be two pictures: `push_rubble` holds on
## the bucket and then opens out as the heap lands, which is one verb and two
## shots.
func go_shot(shot_name: String, animate: bool = true) -> void:
	if rig == null or not rig.has_shot(shot_name):
		return
	var anchor := shot_anchor(shot_name)
	if animate:
		rig.go(shot_name, anchor)
	else:
		rig.snap(shot_name, anchor)


## The node a shot is measured from. A shot whose anchor is `*` hangs off
## whatever the CURRENT STEP is working on, which is what makes one `PANEL` shot
## frame all six panels and one `MACHINE` shot frame all three machines.
func shot_anchor(shot_name: String) -> Node3D:
	if rig == null:
		return null
	var want := rig.anchor_name(shot_name)
	if want == "":
		return null
	if want == "*":
		var s := current_step()
		if s == null:
			return null
		# The level gets first refusal: a beat whose ARROW belongs on one thing
		# may want its PICTURE on another (the push points at the rubble and is
		# watched on the machine).
		if level != null and level.has_method("shot_anchor_override"):
			var override: Node3D = level.shot_anchor_override(s)
			if override != null:
				return override
		return find_target(s.target_for(done_in_step + 1))
	return find_target(want)


## The LIFT-button equivalent: this game has one round button in the corner, and
## a `call_*` step is the only thing that wakes it.
func _arm_button(s: JobStep) -> void:
	if hud == null:
		return
	var want := s.button_id() if s.kind == JobStep.Kind.BUTTON else ""
	hud.arm_button(want)


## Plays one tap (or one button press) of the current step and moves on.
func _play_beat() -> void:
	var s := current_step()
	if s == null:
		return
	# The child has moved on, so whatever the last beat asked the arrow to wait
	# for does not matter any more.
	_arrow_quiet_until = -1.0
	busy = true
	if hud != null:
		hud.hide_arrow()
		hud.arm_button("")
	var n := done_in_step + 1
	if s.sound != "" and level != null:
		level.sfx.play_group(s.sound)
	await _run_verb(s, n)
	# Whatever the verb borrowed, it gives back here: a beat that ended holding
	# the arrow would leave it stuck over a thing nobody is being asked to tap.
	_held_arrow = Vector3.INF
	done_in_step = n
	place_changed.emit(index, done_in_step)
	if s.progress_weight > 0:
		progress = job.weight_before(index, done_in_step)
		beat_done.emit(progress)
	var whole := done_in_step >= s.count
	if whole:
		step_done.emit(index)
		# The finished thing is SEEN finished before the picture moves on: the
		# level puts the tool away and holds the shot for a moment (Build
		# Crew's improvement plan, 1.6). Still busy while it does.
		if level != null and level.has_method("phase_done"):
			await level.phase_done(s)
	busy = false
	if whole:
		_enter(index + 1)
	else:
		_arm_button(s)
		if level != null:
			level.arm_rings(s, done_in_step)
		# THE CAMERA WALKS WITH THE WORK (the user, 2026-09-12: "when you
		# jackhammer the first section or 2 it then moves to the background to
		# slabs that are further away the camera needs to move with it").
		#
		# A step's shot used to be chosen once, when the step was entered, and
		# eighteen hammer bites are ONE step - so the picture stayed on the first
		# panel while the child worked nine metres up the drive, and the thing
		# they were hitting got smaller and smaller. Re-asking for the same shot
		# every beat costs nothing when its anchor has not moved (`CameraRig.go`
		# returns at once for the same shot on the same anchor) and eases the eye
		# up the drive when it has.
		_go_to_shot(s, true)
		update_arrow()
	if _queued_tap:
		# The step may have changed under it, which is exactly what the child
		# asked for. A tap kept into a BUTTON step is dropped: the last panel
		# must not also call the skid steer.
		if not waiting_for_tap():
			_queued_tap = false
		elif not busy:
			_queued_tap = false
			_play_beat()
	elif not whole and s.kind == JobStep.Kind.HOLD and held and not busy:
		# A HOLD step with more beats in it (six panels, four stakes) carries on
		# while the finger is still down: the hammer walks to the next panel with
		# no new press. Lifting between them is a pause; pressing again is the
		# next one. A NEW step wants a new press.
		_play_beat()


## Hands the step to its verb handler and waits for the animation to end.
func _run_verb(s: JobStep, n: int) -> void:
	if verbs == null or s.verb == "":
		return
	var targets := resolve_targets(s, n)
	var tool_node: Node3D = tools.get(s.tool) as Node3D
	await verbs.run(s.verb, self, subject, targets, tool_node, config)


# --- Targets ------------------------------------------------------------------------------

## The node (or nodes) tap `n` of a step works on. `Panel_*` on tap 3 is the
## driveway's third panel; `Machine:SkidSteer` is that machine's working end; an
## empty target is no node at all.
func resolve_targets(s: JobStep, n: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var want := s.target_for(n)
	if want == "":
		return out
	var found := find_target(want)
	if found != null:
		out.append(found)
	return out


## Looks a target name up. The level answers for anything with a colon in it
## (`Machine:DumpTruck`), the driveway for its own parts, and `find_child` is the
## last resort so a one-off prop can be aimed at without a new rule here.
func find_target(want: String) -> Node3D:
	if want == "":
		return null
	if want.find(":") >= 0 and level != null:
		return level.named_target(want)
	var on_subject := _subject_part(want)
	if on_subject != null:
		return on_subject
	if subject != null and is_instance_valid(subject):
		var found := subject.find_child(want, true, false) as Node3D
		if found != null:
			return found
	if level != null:
		return level.named_target(want)
	return null


## The driveway's own index of its panels, boards, stakes and joints, asked
## BEFORE `find_child`: a form board that is still up in the air, or a panel
## that has been broken into chunks, may not be findable by name any more, and
## that is exactly when a step comes looking for it.
func _subject_part(want: String) -> Node3D:
	var drive := subject as Driveway
	if drive == null:
		return null
	var bits := want.split("_")
	var i := int(bits[bits.size() - 1]) if bits.size() > 1 and bits[bits.size() - 1].is_valid_int() else 0
	if want.begins_with("Panel") and i > 0:
		return drive.panel_marker(i)
	if want.begins_with("Jack") and i > 0:
		return drive.spot_marker(i)
	if want.begins_with("Form") and i > 0:
		return drive.form_marker(i)
	if want.begins_with("Stake") and i > 0:
		return drive.stake_marker(i)
	if want.begins_with("Bar") and i > 0:
		return drive.bar_marker(i)
	if want.begins_with("Joint") and i > 0:
		return drive.joint_marker(i)
	if want.begins_with("Rubble") and i > 0:
		# A push lane has no node of its own: the arrow goes over the middle of
		# the rubble still in it, which is where the bucket is about to be.
		return drive.marker("Slab")
	return drive.marker(want)


## Where the arrow bounces, or `Vector3.INF` when the step points at a button.
##
## A form board is the one target that is not where its node is: the board is
## still up in the air and the child is being asked to look at the EDGE OF THE
## HOLE it goes on.
func target_world() -> Vector3:
	var s := current_step()
	if s == null or s.kind == JobStep.Kind.BUTTON:
		return Vector3.INF
	var n := done_in_step + 1
	var want := s.target_for(n)
	var drive := subject as Driveway
	if drive != null and want.begins_with("Form") and s.verb == "form_set":
		var bits := want.split("_")
		if bits.size() > 1 and bits[1].is_valid_int():
			return drive.form_home(int(bits[1]))
	# The same for a stake: the child is being asked to aim at the head of it where
	# it will END UP, and the stake itself sinks away from that point as it is hit.
	if drive != null and want.begins_with("Stake") and s.verb == "stake_drive":
		var sb := want.split("_")
		if sb.size() > 1 and sb[1].is_valid_int():
			return drive.stake_home(int(sb[1]))
	if drive != null and want.begins_with("Rubble"):
		# The middle of whatever is still lying in that column, which moves down the
		# drive as the blade pushes it: a fixed point on the pad would have the arrow
		# pointing at bare gravel half way through the pass.
		var bits2 := want.split("_")
		var lane := int(bits2[1]) if bits2.size() > 1 and bits2[1].is_valid_int() else 1
		return drive.lane_centre(lane)
	# The come-along's target is the FRONT of the work, which the level knows
	# (round 12: the pre-beat ring stood on the slab's middle while the posed
	# rake waited at the front, half a drive apart).
	if s.verb == "rake_pull" and level != null and level.has_method("rake_hint"):
		return level.rake_hint()
	# A DRAG beat's arrow stands on the tool where the pull begins (the
	# board's line, the sled, the bay), which the level knows.
	# A truck waiting to be backed in: its tail, wherever it has rolled to (1.8).
	if false and level != null and level.has_method("arrival_hint"):
		return level.arrival_hint(s.target.get_slice(":", 1))
	if level != null and level.has_method("drag_hint") \
			and (s.verb == "screed_pull" or s.verb == "joint_cut" or s.verb == "broom_finish" \
			or s.verb == "compact_base"):
		var dh: Vector3 = level.drag_hint(s.verb)
		if dh != Vector3.INF:
			return dh
	# The pour has no fixed target at all: the arrow is the level's business
	# there (it hangs over the emptiest corner, and only after a pause).
	var nodes := resolve_targets(s, n)
	if nodes.is_empty():
		return Vector3.INF
	return nodes[0].global_position


## How big the thing the arrow is over is, in metres.
func target_radius() -> float:
	var s := current_step()
	if s == null:
		return 0.0
	var want := s.target_for(done_in_step + 1)
	var drive := subject as Driveway
	if drive != null and want.begins_with("Panel"):
		var bits := want.split("_")
		if bits.size() > 1 and bits[1].is_valid_int():
			return drive.panel_radius(int(bits[1]))
	if drive != null and want.begins_with("Jack"):
		return drive.spot_radius()
	# The plate, not the whole base its step names.
	if s.verb == "compact_base":
		return 0.45
	if want.find(":") >= 0:
		want = want.get_slice(":", 0)
	for prefix: String in TARGET_RADIUS:
		if want.begins_with(prefix):
			return TARGET_RADIUS[prefix]
	return 0.25


## What the arrow stands off FROM, so it comes at its target from a direction
## with nothing in the way. `INF` means "hang above it", which is right for
## everything on a flat slab seen from above.
func target_centre() -> Vector3:
	return Vector3.INF


# --- The arrow ----------------------------------------------------------------------------

## The gold arrow: over the next thing to tap, or over the button that waits.
##
## A verb may TAKE the arrow while it plays (`hold_arrow`), which is how the
## pour keeps it over the emptiest corner while the child steers; it is given
## back with `release_arrow` when the beat ends.
func update_arrow() -> void:
	if hud == null:
		return
	if _held_arrow != Vector3.INF:
		hud.point_at(_held_arrow, _held_radius, _held_centre, _held_ring)
		return
	# A beat whose places are marked with gold RINGS does not also get the gold
	# arrow: the arrow can point at one place, and these phases have three, four or
	# ten of them, all live at once.
	if level != null and level.rings_up():
		hud.hide_arrow()
		return
	var s := current_step()
	# A HOLD beat with the finger lifted before its work is done: the arrow
	# comes back over the thing to hold, busy or not.
	var resting_hold := busy and s != null and s.kind == JobStep.Kind.HOLD and not held
	if (busy and not resting_hold) or finished or arrow_muted():
		hud.hide_arrow()
		return
	if s == null:
		hud.hide_arrow()
		return
	if s.kind == JobStep.Kind.BUTTON:
		hud.point_at_button(s.button_id())
		return
	var t := target_world()
	if t == Vector3.INF:
		hud.hide_arrow()
	else:
		hud.point_at(t, target_radius(), target_centre())


## A verb borrows the arrow for a point of its own.
func hold_arrow(world: Vector3, radius: float = 0.0, centre: Vector3 = Vector3.INF,
		with_ring: bool = true) -> void:
	_held_arrow = world
	_held_radius = radius
	_held_centre = centre
	_held_ring = with_ring
	update_arrow()


func release_arrow() -> void:
	_held_arrow = Vector3.INF
	if hud != null:
		hud.hide_arrow()


## Keeps the arrow off the screen for the next `seconds` without holding the job
## up: the moment a panel comes apart, the one thing on screen actually moving
## is the rubble, and a finger's worth of gold pointing away from it is worse
## than no arrow at all. The step still advances and a tap still counts.
func mute_arrow(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_arrow_quiet_until = _now() + seconds
	if hud != null:
		hud.hide_arrow()


func arrow_muted() -> bool:
	return _arrow_quiet_until > 0.0 and _now() < _arrow_quiet_until


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


# --- Posing (screenshots and tests) --------------------------------------------------------

## Puts the runner AT step `i` with `done` of its taps already made, with no
## animation and no verb. The LEVEL poses the world to match
## (`Driveway.pose_stage`); this is only the runner's own place in the job.
func pose_at(i: int, done: int) -> void:
	if job == null:
		return
	if i >= job.steps.size():
		index = job.steps.size()
		progress = job.total_weight()
		done_in_step = 0
		finished = true
		busy = false
		if hud != null:
			hud.hide_arrow()
			# And the bar is FULL: posed past the last step it still showed
			# the last stops uncredited (rounds 10 and 11, 95.7%).
			hud.set_step(progress)
		return
	finished = false
	busy = false
	_queued_tap = false
	_held_arrow = Vector3.INF
	index = i
	done_in_step = clampi(done, 0, job.steps[i].count)
	progress = job.weight_before(index, done_in_step)
	if hud != null:
		hud.set_step(progress)
	_go_to_shot(job.steps[i], false)
	if level != null:
		level.present_tool(job.steps[i].tool, true)
		level.arm_pads(job.steps[i].verb)
		level.arm_rings(job.steps[i], done_in_step)
	_arm_button(job.steps[i])
	update_arrow()
