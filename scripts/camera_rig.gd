class_name CameraRig
extends Node
## The site's named camera shots (DESIGN 1a). Car Garage's rig, with this job's
## shots in place of the garage's: the logic below is unchanged, because it is
## the part that was worth keeping.
##
## A shot is two points - where the eye stands and what it looks at - and an
## ANCHOR. A shot anchored to nothing is a fixed spot on the lot (`WIDE`, the
## whole front garden). A shot anchored to a node is measured FROM that node
## (`PANEL`, anchored to the slab panel being broken), so the first panel at the
## kerb and the last one up by the garage are framed by the same numbers instead
## of needing a shot each.
##
## `go()` eases between shots over `SiteConfig.shot_time`; `snap()` is there at
## once (a screenshot, a test, the start of the job). The rig re-reads its anchor
## every frame, so a shot on a bucket that is still moving rides with it.
##
## The camera is a `CameraShake`, which owns `transform.basis` while it is
## shaking: the rig writes the clean pose and calls `capture_base()`, and the
## shake adds its wobble on top. So the rig only writes when something has
## actually moved - otherwise the two would fight over the same basis and the
## shake would be erased in whichever order the two `_process` calls ran.

## The camera has arrived at a new shot.
signal shot_reached(shot_name: String)

## The whole lot: house, drive and street. The opening picture, and the one
## every payoff opens out to.
const WIDE := "WIDE"
## Low and close across ONE slab panel - the jackhammer breaking it, and the
## rubble it becomes. Anchored to that panel's own marker, so the picture slides
## up the drive panel by panel.
const PANEL := "PANEL"
## The machine at work: the skid steer's bucket in the rubble, the dump truck's
## bed going up. Anchored to the machine's own working end (`BucketTip`,
## `Tailgate`), which is the thing the child is watching.
const MACHINE := "MACHINE"
## Along the form boards, low, so a board's LINE reads as a straight edge
## against the dirt - which is the whole point of a form.
const FORM := "FORM"
## Close on the tipper's tailgate while the limestone runs out of it. `MACHINE`
## is shared with the skid steer's push and has to hold a whole column of
## rubble; a pour wants to be near enough to see the stone fall.
const TIPPER := "TIPPER"
## Right down on ONE stake. Ten of them go in, one blow each, and a stake is 5 cm
## across: `FORM` framed a whole board and the child could not see which peg the
## arrow was on.
const STAKE := "STAKE"
## The rebar: close on the group of bars being laid (DESIGN 2d).
const BARS := "BARS"
## The come-along: from the garage door, looking down the drive (DESIGN 2a).
const PULL := "PULL"
## The broom: the hose's picture from the other side of the drive.
const BROOM := "BROOM"
## Square on to a control joint, which runs the full width of the drive. `SURFACE`
## looked up the LENGTH of the slab, so the far end of every joint was off frame.
const JOINT := "JOINT"
## Over the concrete truck's chute and the form it is filling: high enough to
## see where the concrete has and has not reached, close enough that the spout
## is the thing in the middle. The one shot the child steers under.
const CHUTE := "CHUTE"
## Low across the wet slab - the screed and, before the rings, everything else
## that worked the surface.
const SURFACE := "SURFACE"
## From where the person doing it STANDS: down at the kerb end of the drive at
## head height, looking up it. The two beats a child drags a tool over - the
## hose and the broom - are played from here, with the tool in the near corner
## of the picture instead of six metres away and 30 px across.
const HAND := "HAND"
## A vehicle arriving or leaving, from up the street - and the child waving a
## truck back into the drive (the plan's 1.8, its reverse leg held).
const STREET := "STREET"
## Low behind the plate compactor, on the bay of base being packed, looking up
## the drive at the bays already done: still while the finger works (5.1).
const PLATE := "PLATE"
## All three form boards and the kerb at once, for the child stripping them
## after the cure (5.3).
const STRIP := "STRIP"
## The reward: down at a child's height on the car standing on the new slab.
const PAYOFF := "PAYOFF"

var camera: CameraShake
var config: SiteConfig

var _shots: Dictionary = {}
var _current: String = ""
var _anchor: Node3D
## 0 .. 1 across the move; 1 means "there".
var _t: float = 1.0
var _from_eye: Vector3 = Vector3.ZERO
var _from_look: Vector3 = Vector3.ZERO
var _eye: Vector3 = Vector3.ZERO
var _look: Vector3 = Vector3.ZERO
var _applied: bool = false
## How long THIS move takes; negative means `SiteConfig.shot_time`.
var _seconds: float = -1.0
## Wall clock for the drift, so every shot's orbit is continuous across a cut
## rather than snapping back to the middle of its swing.
var _clock: float = 0.0
## Whether a shot's slow orbit (its `drift_deg`) is applied at all. OFF since
## the fourth playtest ("stop the camera from swaying constantly"); the drift
## numbers on `define()` calls are kept for the record only.
const DRIFT := false


func setup(cam: CameraShake, cfg: SiteConfig) -> void:
	camera = cam
	config = cfg


## Names a shot. `anchor_node` is "" for a shot in world coordinates, or the
## name the level looks an anchor up by.
##
## `drift_deg` swings the EYE round the thing it is looking at, `drift_secs` is
## how long one swing there and back takes, and `drift_rise` lifts it at the same
## time. The look point never moves, so this is a slow ORBIT and not a wobble:
## the work stays exactly where it is on screen while the world turns a little
## behind it.
##
## The user asked for it - "the camera should move around during things like jack
## hammer vs staying stationary" - and it is the difference between a photograph
## of a job and somebody watching one. The two beats worked by DRAGGING a finger
## across the slab are left still on purpose: a moving camera moves the ground
## under the finger.
func define(shot_name: String, anchor_node: String, eye: Vector3, look: Vector3,
		drift_deg: float = 0.0, drift_secs: float = 12.0, drift_rise: float = 0.0) -> void:
	_shots[shot_name] = {"anchor": anchor_node, "eye": eye, "look": look,
		"drift_deg": drift_deg, "drift_secs": maxf(drift_secs, 0.5), "drift_rise": drift_rise}


func shot_eye(shot_name: String) -> Vector3:
	return Vector3(_shots[shot_name]["eye"]) if _shots.has(shot_name) else Vector3.ZERO


func shot_look(shot_name: String) -> Vector3:
	return Vector3(_shots[shot_name]["look"]) if _shots.has(shot_name) else Vector3.ZERO


func has_shot(shot_name: String) -> bool:
	return _shots.has(shot_name)


## The name of the node a shot hangs off, or "" for a world shot.
func anchor_name(shot_name: String) -> String:
	if not _shots.has(shot_name):
		return ""
	return String(_shots[shot_name]["anchor"])


func current_shot() -> String:
	return _current


func is_moving() -> bool:
	return _t < 1.0


## Where the eye stands for a shot, given the node it is anchored to.
func eye_for(shot_name: String, anchor: Node3D = null) -> Vector3:
	if not _shots.has(shot_name):
		return Vector3.ZERO
	var s: Dictionary = _shots[shot_name]
	var e := _drifted(s)
	if String(s["anchor"]) != "":
		if anchor != null and is_instance_valid(anchor):
			return anchor.global_position + _flip(_own(e, anchor, "shot_eye"), anchor)
		return _lost(shot_name, "eye")
	return e


## The eye offset with this shot's slow orbit applied. Swung about the LOOK
## point, not about the anchor, so a shot that looks off to one side still turns
## about what it is looking at.
func _drifted(s: Dictionary) -> Vector3:
	var e: Vector3 = s["eye"]
	# OFF since the fourth playtest (2026-09-14): "stop the camera from swaying
	# constantly". The shots keep their drift numbers for the record; nothing
	# reads them while this is false.
	if not DRIFT:
		return e
	var deg: float = s.get("drift_deg", 0.0)
	if absf(deg) < 0.01:
		return e
	var secs: float = s.get("drift_secs", 12.0)
	var phase := sin(TAU * _clock / secs)
	var look: Vector3 = s["look"]
	var arm := e - look
	arm = Basis(Vector3.UP, deg_to_rad(deg * phase)) * arm
	arm.y += float(s.get("drift_rise", 0.0)) * phase
	return look + arm


## An ANCHORED shot asked for with no anchor. It used to read the offset as a
## world position and quietly put the camera wherever that landed - out on the
## lawn, in the case of a posed end state - so every picture taken that way was
## of a camera the game never uses. Say so, and fall back on the one shot that
## needs no anchor.
func _lost(shot_name: String, which: String) -> Vector3:
	push_warning("CameraRig: %s has no anchor; falling back to %s" % [shot_name, WIDE])
	if not _shots.has(WIDE):
		return Vector3.ZERO
	return _shots[WIDE]["eye"] if which == "eye" else _shots[WIDE]["look"]


## What the eye looks at for a shot.
func look_for(shot_name: String, anchor: Node3D = null) -> Vector3:
	if not _shots.has(shot_name):
		return Vector3.ZERO
	var s: Dictionary = _shots[shot_name]
	var l: Vector3 = s["look"]
	if String(s["anchor"]) != "":
		if anchor != null and is_instance_valid(anchor):
			return anchor.global_position + _flip(_own(l, anchor, "shot_look"), anchor)
		return _lost(shot_name, "look")
	return l


## The whole camera pose for a shot. The smoke test compares the live camera
## against this.
func pose_for(shot_name: String, anchor: Node3D = null) -> Transform3D:
	var e := eye_for(shot_name, anchor)
	var l := look_for(shot_name, anchor)
	var t := Transform3D(Basis.IDENTITY, e)
	return t.looking_at(l, Vector3.UP)


## Moves a shot's offsets after the fact: the level fits `STREET` and `CHUTE` to
## the thing they have to hold, which is not known until the job loads.
func refit(shot_name: String, eye: Vector3, look: Vector3) -> void:
	if not _shots.has(shot_name):
		return
	_shots[shot_name]["eye"] = eye
	_shots[shot_name]["look"] = look


## Eases to a shot over `shot_time`, or over `seconds` when a caller has a
## reason to be quicker. Asking for the shot it is already playing (on the same
## anchor) does nothing, so a step that keeps the shot does not restart the move.
func go(shot_name: String, anchor: Node3D = null, seconds: float = -1.0) -> void:
	if not _shots.has(shot_name):
		push_warning("CameraRig: no shot called %s" % shot_name)
		return
	if _current == shot_name and _anchor == anchor and _applied:
		return
	_from_eye = _eye
	_from_look = _look
	_current = shot_name
	_anchor = anchor
	_seconds = seconds
	if not _applied:
		_snap_now()
		return
	_t = 0.0


## Straight there: no move at all.
func snap(shot_name: String, anchor: Node3D = null) -> void:
	if not _shots.has(shot_name):
		push_warning("CameraRig: no shot called %s" % shot_name)
		return
	_current = shot_name
	_anchor = anchor
	_snap_now()


func _snap_now() -> void:
	_t = 1.0
	_seconds = -1.0
	_eye = eye_for(_current, _anchor)
	_look = look_for(_current, _anchor)
	_from_eye = _eye
	_from_look = _look
	_apply(_eye, _look)
	shot_reached.emit(_current)


func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera) or _current == "":
		return
	_clock += delta
	var was_moving := _t < 1.0
	if was_moving:
		var seconds := _seconds if _seconds > 0.0 else (config.shot_time if config != null else 0.8)
		seconds = maxf(seconds, 0.001)
		_t = minf(_t + delta / seconds, 1.0)
	var k := _ease(_t)
	var eye := _from_eye.lerp(eye_for(_current, _anchor), k)
	var look := _from_look.lerp(look_for(_current, _anchor), k)
	# Nothing has changed and the shake owns the basis: leave it alone.
	if not was_moving and _applied and eye.is_equal_approx(_eye) and look.is_equal_approx(_look):
		return
	_apply(eye, look)
	if was_moving and _t >= 1.0:
		shot_reached.emit(_current)


## Smooth at both ends, so a shot leaves and arrives instead of sliding.
func _ease(k: float) -> float:
	var c := clampf(k, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


func _apply(eye: Vector3, look: Vector3) -> void:
	_eye = eye
	_look = look
	_applied = true
	if (look - eye).length_squared() < 0.000001:
		return
	camera.look_at_from_position(eye, look, Vector3.UP)
	# The clean pose is the shake's rest pose, so its wobble is added to THIS
	# frame's shot rather than to whatever the camera was doing a shot ago.
	camera.capture_base()


## A shot's offsets, mirrored across the drive when the anchor asks for it
## (`flip_x` meta): the same close picture of a pair of stakes on the far board,
## from the far lawn.
func _flip(offset: Vector3, anchor: Node3D) -> Vector3:
	if anchor != null and is_instance_valid(anchor) and anchor.has_meta("flip_x"):
		return Vector3(-offset.x, offset.y, offset.z)
	return offset


## An anchor may carry its OWN offsets (`shot_eye` / `shot_look` meta) for a
## place the shot's one composition cannot fit - the pair of pegs along the
## kerb-end board lies across the drive, not along it - and those win.
func _own(offset: Vector3, anchor: Node3D, which: String) -> Vector3:
	if anchor != null and is_instance_valid(anchor) and anchor.has_meta(which):
		return Vector3(anchor.get_meta(which))
	return offset
