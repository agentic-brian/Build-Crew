class_name Machine
extends Node3D
## One of the fleet's construction machines, driven by its own named nodes
## (DESIGN 3). The GLBs come from `big-little-jobs-fleet/models/construction`
## and their node contracts are that pack's, unchanged:
##
##   SkidSteer      WheelFL/FR/RL/RR, LiftArm(+Mesh), Bucket, BucketTip,
##                  LiftRam/Rod, TiltRam/Rod, Beacon
##   DumpTruck      six wheels, Bed(+Mesh), Tailgate(+Mesh), HoistRam/Rod, Beacon
##   ConcreteTruck  six wheels, Drum(+Mesh), Chute(+Mesh), ChuteFold(+Mesh),
##                  ChutePour, Beacon
##
## The fleet's conventions are what make this one script rather than three: a
## ROTATING assembly is an empty pivot with a `<Name>Mesh` child, so turning
## the pivot turns the part about the hinge the modeller chose; a MARKER empty's
## +Z is its meaningful direction; everything is Godot metres, Y up, facing +Z,
## with the origin on the ground under the centre.
##
## Which AXIS each pivot turns about is not in that contract, so every one of
## them is an export here rather than a number buried in a verb: the probe
## `scenes/dev/machine_probe.tscn` prints each pivot's rest transform and the
## world point its end lands at, and these are tuned against what it prints.
## A machine whose GLB is missing still loads - `missing_nodes` says what it
## could not find and a grey stand-in box takes its place - because a level
## that cannot open is a level nobody can look at.

## The machine finished a `drive_to`.
signal arrived

const MODEL_DIR := "res://assets/models/machines/"
## What each kind promises. Checked on load, reported in `missing_nodes`, and
## asserted by the smoke test: a silently absent `ChutePour` is a pour that
## lands at the machine's own origin, in the middle of the road.
##
## `Beacon` is on every list (the improvement plan's 4.5): the header above has
## always named it, and the lists did not, so `node_for("Beacon")` answered null
## and session 2's honk wink never lit anything.
const CONTRACT := {
	"SkidSteer": ["WheelFL", "WheelFR", "WheelRL", "WheelRR", "LiftArm", "Bucket", "BucketTip", "Beacon"],
	"DumpTruck": ["WheelFL", "WheelFR", "WheelRL", "WheelRR", "Bed", "Tailgate", "Beacon"],
	"ConcreteTruck": ["WheelFL", "WheelFR", "WheelRL", "WheelRR", "Drum", "Chute", "ChuteFold", "ChutePour", "Beacon"],
}
## Crushed limestone, the same family as the base the tipper is carrying.
const LOAD_GREY := Color(0.60, 0.54, 0.44)
## The beacon (4.5): the fleet's `beacon()` is a stalk, an amber LENS and a cap,
## three surfaces of one mesh; only the lens glows, found by its material's name
## (the tipper's whole body shares that material, so it is COPIED, never edited).
## Off, the lens is a dull amber; on, it flashes bright and throws a small warm
## light on the roof. There is no glow and no tonemapper, so the emission is a
## deep amber rather than yellow, or it clips to white on a yellow lens.
const BEACON_LENS := "Equip_Yellow"
const BEACON_AMBER := Color(1.0, 0.42, 0.02)
const BEACON_LENS_DIM := 0.35
## Every wheel name the three kinds use, so rolling does not need a per-kind list.
const WHEELS: Array[String] = ["WheelFL", "WheelFR", "WheelRL", "WheelRR", "WheelR2L", "WheelR2R"]
## The skid steer's PUSH BLADE (DESIGN 2c). The user, 2026-09-14: "skid steer
## bucket should be more like a bulldozer push blade" - a loader bucket scoops,
## and what the job asks of this machine is nine metres of SHOVING. A dozer-blade
## attachment is a real thing a crew bolts onto a skid steer for exactly that, so
## `tools/make_blade.py` builds one in the bucket pin's own frame and `fit_blade`
## hangs it off the `Bucket` pivot with the bucket's own meshes hidden: every
## lift the machine already knows about carries the blade instead.
const BLADE_MODEL := "res://assets/models/props/PushBlade.glb"
## A blade does not curl to dump the way a bucket does; `curl` only tilts it a
## little forward (a six-way blade really does), so a verb written for the
## bucket still reads sensibly.
const BLADE_TILT_DEG := 12.0
## The mixer's EXTENSION CHUTE (DESIGN 2a). A mixer carries two or three of
## these and clips them on when the pour is further from the truck than the
## main chute reaches - which it is here, because the truck stands on the road
## and never puts a wheel on the steel. Built in code off the spout, hung off
## the `Chute` pivot so it swings with it, pitched gently so the concrete still
## runs downhill to its end. `PourEnd` is where the concrete leaves it.
const CHUTE_EXT := 1.40
const CHUTE_EXT_PITCH_DEG := 8.0

## `SkidSteer`, `DumpTruck` or `ConcreteTruck`. Set BEFORE the node enters the tree.
@export var kind: String = "SkidSteer"
## A GLB somewhere other than `MODEL_DIR`. The homeowner's car is a `Machine`
## too - it has to arrive nose-first on a rounded path with its wheels turning,
## which is this class's whole job - and it lives in the vehicles folder with
## the rest of the fleet. Empty means `MODEL_DIR + kind + ".glb"`.
@export var model_path: String = ""

@export_group("Which way a pivot turns")
## Every number in this group was READ OFF `scenes/dev/machine_probe.tscn`, not
## guessed: it prints each pivot's rest transform and where the working end lands
## for a sweep of angles, which is the only way to know that on these models a
## POSITIVE turn about +X lowers the skid steer's arm and a NEGATIVE one lifts it.
##
## The loader arm: degrees about +X from its modelled rest to the bucket's edge
## on the dirt, and to carrying high. The arm's pivot is 2.8 m from the cutting
## edge and sits 1.58 m up, so these are small angles.
@export var arm_down_deg: float = 15.5
@export var arm_up_deg: float = -10.0
## The bucket's own curl: degrees about +X from rest to the cutting edge flat on
## the dirt, and to tipped right forward to shed the load. Positive drops the
## edge, so dumping is positive.
@export var bucket_flat_deg: float = -6.0
@export var bucket_dump_deg: float = 48.0
## The dump truck's bed. Its pivot is at the REAR of the bed (z -3.02), so a
## negative turn about +X lifts the FRONT and the load slides off the back -
## which is why the tailgate itself does not rise as it tips.
@export var bed_axis_sign: float = -1.0
## The concrete chute: the axis it swings about (Y, a yaw) and the axis it folds
## about (X, a pitch), as signs so a mirrored model needs no new code.
##
## The fold is deployment ONLY, never aiming: the probe measured 0.11 m of travel
## at the pour point across its whole range, because the spout is already as far
## out as that arm reaches. Fold 0 is stowed up against the truck, 1 is down over
## the form, so the sign that LOWERS it is the one that deploys it.
##
## NEGATIVE because the pads have to mean what they say. On this model a positive
## turn about +Y sends the stream to the viewer's RIGHT, so at +1 the LEFT pad
## poured to the right - and a four-year-old pressing left and watching the
## concrete go the other way has been told the controls are lying. The camera
## looks up the drive from its left, so screen-left is world -X.
@export var chute_swing_sign: float = -1.0
@export var chute_fold_sign: float = -1.0
## The drum turns about its own long axis, which is raked: this is the axis in
## the DRUM's own space.
@export var drum_axis: Vector3 = Vector3(0.0, 0.0, 1.0)

var model_loaded: bool = false
var missing_nodes: PackedStringArray = PackedStringArray()
var config: SiteConfig

var _model: Node3D
var _nodes: Dictionary = {}
## The hub and the nuts on each wheel's corner, which are the wheel's SIBLINGS
## on the fleet's vehicles (Car Garage screws them out along the studs), so
## rolling the wheel node leaves them dead still ("lug nuts aren't spinning",
## the user, 2026-09-14). They orbit the axle with it.
var _corner: Dictionary = {}
var _corner_rest: Dictionary = {}
## The push blade, when one is fitted, and the marker on its cutting edge.
var _blade: Node3D
var _blade_edge: Node3D
## The extension chute, when one is clipped on, and its end.
var _chute_ext: Node3D
var _pour_end: Node3D
var _chute_mud: MeshInstance3D
## The heap of stone in a tipper's bed, and the two numbers `set_load` moves it
## between - measured off the BED, once, the first time a load is asked for.
var _load: Node3D
var _load_floor: float = 0.0
var _load_high: float = 1.0
var _load_long: float = 1.0
var _load_centre_z: float = 0.0
## Each pivot's modelled rest transform, read once before anything is turned:
## every `set_*` writes `rest * rotation` rather than accumulating, so a beat
## that is replayed (a test posing the level twice) lands in the same place.
var _rest: Dictionary = {}
## Metres covered, not radians turned: each wheel's radius is its own axle
## height off the model (0.36 on the skid steer, 0.52 on the dump truck), so one
## angle for all of them would make the small wheels slip.
var _rolled_m: float = 0.0
## Metres one track has scrubbed AGAINST the other, turning on the spot.
var _spun: float = 0.0
var _drum_turn: float = 0.0
## The beacon (4.5): the lens's own material copy, its light, whether the
## machine is at work (arriving, working, leaving), where the pulse is, a honk's
## wink on top of it, a pin for posed pictures, and the level last written.
var _beacon_lens: BaseMaterial3D
var _beacon_light: OmniLight3D
var _working: bool = false
var _beacon_t: float = 0.0
var _beacon_flash: float = 0.0
var _beacon_flash_len: float = 0.6
var _beacon_pin: float = -1.0
var _beacon_shown: float = -1.0
## Where a `drive_to` is going, and how far along it is.
var _drive_from: Transform3D = Transform3D.IDENTITY
var _drive_to: Transform3D = Transform3D.IDENTITY
var _drive_t: float = 0.0
var _drive_time: float = 0.0
var _driving: bool = false
## A `follow` in progress: the polyline, the distance to each of its points, and
## whether the machine is travelling BACKWARDS along it.
var _path: Array[Vector3] = []
var _cum: PackedFloat32Array = PackedFloat32Array()
var _path_rev: bool = false
## A `spin_to` in progress: turning on the spot, which is what a skid steer does
## instead of a three-point turn.
var _spinning: bool = false
var _spin_from: float = 0.0
var _spin_want: float = 0.0
## Asked for the height of the ground under a point, every frame of every move.
## The job digs a hole and then fills it back up, so a machine's standing height
## changes under it as it drives: `SiteMain` hands this over, so no verb has to
## remember to reseat it and no machine drives across the job at the height it
## happened to spawn at.
var ground: Callable = Callable()


func _ready() -> void:
	if not _load_model():
		_build_placeholder()


func setup(cfg: SiteConfig) -> void:
	config = cfg


# --- Where it is -------------------------------------------------------------------------

## Puts the machine somewhere at once, facing `yaw` degrees about Y.
func place(at: Vector3, yaw_deg: float = 0.0) -> void:
	_driving = false
	_spinning = false
	_path.clear()
	global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), at)


## Drives to a pose over `seconds`, wheels turning the distance they really
## cover. `arrived` fires at the end.
func drive_to(at: Vector3, yaw_deg: float, seconds: float) -> void:
	_drive_from = global_transform
	_drive_to = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), at)
	_drive_time = maxf(seconds, 0.05)
	_drive_t = 0.0
	_driving = true


func is_driving() -> bool:
	return _driving or _spinning


## Metres this machine has covered since it was built, for a test that wants to
## know the wheels really turned rather than that the body really moved.
func rolled_m() -> float:
	return _rolled_m


## Rolls the wheels as if the machine had covered `metres` (negative reverses).
## Called by `drive_to` and by any verb that slides the machine itself.
##
## A wheel's RADIUS is the height of its own axle, which the fleet's models put
## the wheel node at: no table of radii to keep in step with the art, and a
## six-wheeler whose front wheels are a different size still rolls honestly.
func roll(metres: float) -> void:
	_rolled_m += metres
	_roll_sides(_rolled_m - _spun, _rolled_m + _spun)


## The two sides turned by different amounts, which is the only way a machine
## turns on the spot: one track forward, the other back. `left_m` and `right_m`
## are TOTAL metres covered by that side, not increments.
func _roll_sides(left_m: float, right_m: float) -> void:
	for w in WHEELS:
		var node := _nodes.get(w) as Node3D
		if node == null:
			continue
		var rest: Transform3D = _rest[w]
		var r := absf(rest.origin.y)
		if r < 0.05:
			r = config.wheel_radius if config != null else 0.46
		var m := left_m if rest.origin.x < 0.0 else right_m
		node.transform = Transform3D(rest.basis * Basis(Vector3.RIGHT, m / r), rest.origin)
		# The same turn, in the PARENT's frame, for everything bolted to this corner.
		if _corner.has(w):
			var spin_w := rest.basis * Basis(Vector3.RIGHT, m / r) * rest.basis.inverse()
			for extra: Node3D in _corner[w]:
				var er: Transform3D = _corner_rest[extra]
				extra.transform = Transform3D(spin_w * er.basis, rest.origin + spin_w * (er.origin - rest.origin))


## Half the distance between the two wheel tracks, off the model: the radius a
## wheel sweeps when the machine turns on the spot.
func _track_half() -> float:
	var half := 0.0
	for w in WHEELS:
		if _rest.has(w):
			half = maxf(half, absf((_rest[w] as Transform3D).origin.x))
	return maxf(half, 0.5)


# --- Travelling a PATH ------------------------------------------------------------------------

## Drives along a polyline, facing the way it is going the whole time - or facing
## exactly the other way, when `reverse`, which is how both trucks get up the
## drive and how the skid steer shuffles across it.
##
## This is what a journey that is not a straight line uses instead of `drive_to`.
## `drive_to` LERPS one pose into another, which slides a machine diagonally
## across the lawn while its yaw turns independently of where it is going - and
## the wheels then roll by the component of that slide along its own nose, so a
## machine crossing sideways barely rolls at all. "A lot of the vehicles just
## float and turn into the driveway instead of rolling or backing up" was the
## user's note, and this is the answer to it: the yaw is READ OFF the path, so
## the nose always points along the travel and the wheels always turn the
## distance really covered.
func follow(points: Array[Vector3], seconds: float, reverse: bool = false) -> void:
	if points.size() < 2:
		return
	_path = points.duplicate()
	_path_rev = reverse
	_cum = PackedFloat32Array()
	_cum.resize(_path.size())
	_cum[0] = 0.0
	for i in range(1, _path.size()):
		_cum[i] = _cum[i - 1] \
			+ Vector2(_path[i].x - _path[i - 1].x, _path[i].z - _path[i - 1].z).length()
	_drive_time = maxf(seconds, 0.05)
	_drive_t = 0.0
	_driving = true
	_spinning = false


## Turns on the spot to face `yaw_deg`, the two tracks going opposite ways. A
## skid steer really does this and nothing else in the fleet can, so it is the
## move that says which machine this is.
func spin_to(yaw_deg: float, seconds: float) -> void:
	_spin_from = rotation.y
	_spin_want = deg_to_rad(yaw_deg)
	# The short way round, always: a 10 degree turn must not go 350 the other way.
	while _spin_want - _spin_from > PI:
		_spin_want -= TAU
	while _spin_want - _spin_from < -PI:
		_spin_want += TAU
	_drive_time = maxf(seconds, 0.05)
	_drive_t = 0.0
	_spinning = true
	_driving = false
	_path.clear()


## Which meshes are drawn. `keep` empty shows the whole machine; otherwise only
## the named nodes and everything under them.
##
## This is the POUR's visual trick, in the user's own words: "detach the chute
## from the truck... so we don't have the truck in the way". Keeping only `Chute`
## leaves the chute, its fold and its spout hanging in the air exactly where the
## truck really holds them, with the drum, the cab and the wheels gone - so the
## camera can come right up to the one thing the child is steering. Nothing is
## duplicated and nothing is moved: the truck is still there, still creeping down
## the drive, still rolling its wheels, and `show_only([])` puts it back.
func show_only(keep: Array) -> void:
	if _model == null:
		return
	for n in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.visible = keep.is_empty() or _under(mi, keep)
		# And what is kept casts NO shadow while the rest is hidden: a four
		# metre chute over the slab threw a machine-sized shadow with no machine
		# on it, and it read as a stain (round 7).
		# What is kept casts NO shadow while the rest is hidden (round 7's
		# stain; round 12 tried the shadow back and round 13 measured it as
		# the highest-contrast shape on the fresh pool, 5x the stream).
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if keep.is_empty() \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_clip_hopper(not keep.is_empty() and "Chute" in keep)


## A wink of the amber beacon: a tap on a machine is answered by the machine
## (the improvement plan's 1.8). Full for the first half of `seconds`, then dying
## down - on top of the working pulse, so a honk on a machine already flashing
## still reads as an answer. `_tick_beacon` draws it; no tween fights the pulse.
func flash_beacon(seconds: float) -> void:
	_beacon_flash_len = maxf(seconds, 0.1)
	_beacon_flash = _beacon_flash_len
	# In the frame of the tap, not the next one.
	_tick_beacon(0.0)


## The machine is at work - arriving, pushing, tipping, pouring, leaving - and
## its beacon turns (the improvement plan's 4.5); off when it is parked or gone.
## Named for the machine, not `set_working`: `SiteHud.set_working` is the HUD.
func set_beacon_on(on: bool) -> void:
	if on and not _working:
		# The first frame of a turn is lit: a beacon that starts dark reads as
		# nothing having happened.
		_beacon_t = 0.0
	_working = on
	# Drawn in THIS frame: a machine that has stopped must not show one more
	# frame of a flash it is no longer making.
	_tick_beacon(0.0)


func beacon_on() -> bool:
	return _working


## How bright the lens is drawn right now, 0..1.
func beacon_level() -> float:
	return maxf(_beacon_shown, 0.0)


## How much of a honk's wink is left, 0..1.
func beacon_flash_k() -> float:
	return clampf(_beacon_flash / _beacon_flash_len, 0.0, 1.0)


## Holds the lens at `k` for a posed picture (negative lets it go): a pulse on the
## wall clock would put the beacon at a random phase in every frame taken.
func pin_beacon(k: float) -> void:
	_beacon_pin = k
	_tick_beacon(0.0)


## The lens's surface material copy and its light, built once the model is in.
func _build_beacon() -> void:
	var mi := _nodes.get("Beacon") as MeshInstance3D
	if mi == null or mi.mesh == null:
		return
	for s in range(mi.mesh.get_surface_count()):
		var base := mi.mesh.surface_get_material(s)
		if base == null or not String(base.resource_name).begins_with(BEACON_LENS):
			continue
		var m := base.duplicate() as BaseMaterial3D
		if m == null:
			return
		m.resource_name = base.resource_name
		m.albedo_color = m.albedo_color.darkened(BEACON_LENS_DIM)
		# Enabled ONCE, here: toggling it later compiles a new shader variant
		# mid-play (a hitch, worst on a phone), which the old wink did on the
		# first honk.
		m.emission_enabled = true
		m.emission = BEACON_AMBER
		m.emission_energy_multiplier = 0.0
		mi.set_surface_override_material(s, m)
		_beacon_lens = m
		var aabb := mi.mesh.get_aabb()
		var l := OmniLight3D.new()
		l.name = "BeaconLight"
		l.light_color = Color(1.0, 0.55, 0.14)
		# The sun is the only shadow the site was tuned to.
		l.shadow_enabled = false
		l.light_specular = 0.25
		l.light_energy = 0.0
		l.omni_range = 2.0
		l.visible = false
		# UNDER the beacon's mesh, so it goes when the body does: the pour draws
		# only the chute, and an amber light hanging over it would be a light
		# with no truck.
		l.position = Vector3(0.0, aabb.position.y + aabb.size.y * 0.62, 0.0)
		mi.add_child(l)
		_beacon_light = l
		return


func _tick_beacon(delta: float) -> void:
	if _beacon_lens == null:
		return
	var hz: float = config.beacon_hz if config != null else 1.2
	var p := 0.0
	if _working:
		_beacon_t += delta
		# A clipped cos squared: a turning beacon seen from one side is a bright
		# sweep and a gap, which at twenty pixels reads as a blink.
		p = pow(maxf(cos(TAU * hz * _beacon_t), 0.0), 2.0)
	if _beacon_flash > 0.0:
		_beacon_flash = maxf(_beacon_flash - delta, 0.0)
		p = maxf(p, clampf(_beacon_flash / _beacon_flash_len * 2.0, 0.0, 1.0))
	if _beacon_pin >= 0.0:
		p = _beacon_pin
	if absf(p - _beacon_shown) < 0.002:
		return
	_beacon_shown = p
	_beacon_lens.emission_energy_multiplier = (config.beacon_glow if config != null else 1.6) * p
	if _beacon_light != null:
		_beacon_light.light_energy = (config.beacon_light_energy if config != null else 0.8) * p
		_beacon_light.omni_range = config.beacon_light_range if config != null else 2.0
		_beacon_light.visible = p > 0.01


## The meshes of the body: everything not under one of `keep`. For a fade of
## the truck that leaves its chute alone (`SiteVerbs.mixer_leave`).
func body_meshes(keep: Array) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if _model == null:
		return out
	for n in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not _under(mi, keep):
			out.append(mi)
	return out


## The chute's mesh carries the mixer's HOPPER above its pivot in the same
## surface as the trough's rails. With the truck not drawn, that hopper hung
## in the air beside the chute as a yellow slab with the chain over it
## (round 11). While only the chute is drawn, everything in that surface above
## the pivot is discarded; with the truck back, the surface is its own again.
func _clip_hopper(on: bool) -> void:
	var mi := _model.find_child("ChuteMesh", true, false) as MeshInstance3D
	if mi == null or mi.mesh == null:
		if OS.has_environment("BC_DEBUG"):
			var names := PackedStringArray()
			for n in _model.find_children("*", "MeshInstance3D", true, false):
				names.append(String(n.name))
			print("CLIP no ChuteMesh: ", names)
		return
	for si in range(mi.mesh.get_surface_count()):
		var base := mi.get_active_material(si) as StandardMaterial3D
		if OS.has_environment("BC_DEBUG"):
			print("CLIP surface %d mat %s name '%s' aabb %s" % [si, str(mi.get_active_material(si)),
				str(base.resource_name) if base != null else "-", str(mi.mesh.get_aabb())])
		if base == null:
			continue
		if not on:
			mi.set_surface_override_material(si, null)
			continue
		# Both surfaces: the hopper's yellow skin AND its steel liner sit above
		# the pivot; the trough hangs below it. The yellow surface also carries
		# the swing POST beside the pivot end, so that surface loses its last
		# 0.28 m toward the pivot as well (the steel liner stays, so the trough
		# still reaches the frame's edge).
		# BOTH surfaces end at the same plane toward the pivot - the liner ran
		# on past the skin and its end showed as a pale rounded face (round 12)
		# - and the dark liner is lifted to a wet-steel grey: at 0.31 beside a
		# 0.60 pool the trough was one flat slab.
		var cut := 0.05
		var cut_z := -0.28
		var alb := base.albedo_color
		if alb.get_luminance() < 0.3:
			alb = alb.lightened(0.62)
		var sh := Shader.new()
		sh.code = """shader_type spatial;
uniform vec4 albedo : source_color = vec4(1.0);
uniform float rough = 0.7;
uniform float cut_y = 0.08;
uniform float cut_z = 10.0;
varying vec3 lpos;
void vertex() { lpos = VERTEX; }
void fragment() {
	if (lpos.y > cut_y || lpos.z > cut_z) { discard; }
	ALBEDO = albedo.rgb;
	ROUGHNESS = rough;
	METALLIC = 0.0;
}
"""
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("albedo", alb)
		sm.set_shader_parameter("rough", base.roughness)
		sm.set_shader_parameter("cut_y", cut)
		sm.set_shader_parameter("cut_z", cut_z)
		mi.set_surface_override_material(si, sm)


func _under(node: Node, keep: Array) -> bool:
	var at: Node = node
	while at != null and at != _model:
		if String(at.name) in keep:
			return true
		at = at.get_parent()
	return false


## Puts the machine on the ground under it, and TIPS it to match, if anyone has
## said where the ground is.
##
## Sampled at the nose and at the tail, not at the origin, because a machine that
## only has a height is a machine sliding along a surface: a skid steer climbing
## the broken-out slab has to pitch up as its front wheels go over a lump and
## level off as its back wheels come down, or the rubble may as well not be there.
func _seat() -> void:
	if not ground.is_valid():
		return
	var half := maxf(_axle_half(), 0.4)
	var front := to_global(Vector3(0.0, 0.0, half))
	var back := to_global(Vector3(0.0, 0.0, -half))
	var yf := float(ground.call(front))
	var yb := float(ground.call(back))
	global_position.y = (yf + yb) * 0.5
	# `Basis(RIGHT, x)` sends +Z to (0, -sin x, cos x), so a NOSE-UP pitch is
	# negative.
	rotation.x = -atan2(yf - yb, half * 2.0)


## Half the wheelbase, off the model: how far apart the two ground samples are.
func _axle_half() -> float:
	var half := 0.0
	for w in WHEELS:
		if _rest.has(w):
			half = maxf(half, absf((_rest[w] as Transform3D).origin.z))
	return half


func _process(delta: float) -> void:
	# First, above the early returns: a push or a tip slides the machine by hand
	# rather than `drive_to`, and the beacon must turn through those too.
	_tick_beacon(delta)
	if _drum_turn != 0.0:
		var drum := _nodes.get("Drum") as Node3D
		if drum != null:
			drum.rotate_object_local(drum_axis.normalized(), TAU * _drum_turn * delta)
	if _spinning:
		_advance_spin(delta)
		return
	if not _driving:
		return
	_drive_t += delta
	var k := clampf(_drive_t / _drive_time, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	if _path.size() >= 2:
		_advance_path(e)
	else:
		var was := global_position
		global_transform = _drive_from.interpolate_with(_drive_to, e)
		roll(_forward().dot(global_position - was) if was.distance_to(global_position) > 0.0 else 0.0)
	_seat()
	if k >= 1.0:
		_driving = false
		_path.clear()
		arrived.emit()


## One frame of a `follow`: `e` is the eased 0..1 across the whole path.
func _advance_path(e: float) -> void:
	var total: float = _cum[_cum.size() - 1]
	var want := e * total
	var was := global_position
	var seg := 1
	while seg < _cum.size() - 1 and _cum[seg] < want:
		seg += 1
	var span: float = maxf(_cum[seg] - _cum[seg - 1], 0.0001)
	var f := clampf((want - _cum[seg - 1]) / span, 0.0, 1.0)
	var at: Vector3 = _path[seg - 1].lerp(_path[seg], f)
	var dir: Vector3 = _path[seg] - _path[seg - 1]
	dir.y = 0.0
	if dir.length_squared() < 0.000001:
		dir = Vector3.FORWARD
	var facing := dir.normalized()
	if _path_rev:
		facing = -facing
	global_position = Vector3(at.x, global_position.y, at.z)
	rotation.y = atan2(facing.x, facing.z)
	var moved := Vector2(global_position.x - was.x, global_position.z - was.z).length()
	roll(-moved if _path_rev else moved)


## One frame of a `spin_to`: the yaw turns and the two tracks scrub opposite ways.
func _advance_spin(delta: float) -> void:
	_drive_t += delta
	var k := clampf(_drive_t / _drive_time, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	var was := rotation.y
	rotation.y = lerpf(_spin_from, _spin_want, e)
	_spun += (rotation.y - was) * _track_half()
	_roll_sides(_rolled_m - _spun, _rolled_m + _spun)
	_seat()
	if k >= 1.0:
		_spinning = false
		arrived.emit()


## How far behind the machine's own origin its REARMOST TYRE reaches, measured
## off the model (the wheel node's own z, plus its axle height as the radius).
##
## This is what "the truck must not be standing on it" is measured from. Using
## the SPOUT's offset instead - which is 4.5 m behind the mixer, far further back
## than any wheel - made the no-reversing rule shove the truck forward a metre
## every frame until its chute hung off the end of the form.
func rear_overhang() -> float:
	var back := 0.0
	for w in WHEELS:
		if not _rest.has(w):
			continue
		var rest: Transform3D = _rest[w]
		back = maxf(back, -rest.origin.z + absf(rest.origin.y))
	return back


## The way the machine faces (+Z, the fleet's convention).
func _forward() -> Vector3:
	return global_basis.z.normalized()


func forward() -> Vector3:
	return _forward()


# --- The skid steer -----------------------------------------------------------------------

## The loader arm and the bucket. `lift` 0 is the bucket on the dirt, 1 is
## carried high; `curl` 0 is the cutting edge flat on the dirt and 1 is tipped
## right forward to shed the load.
func set_bucket(lift: float, curl: float) -> void:
	_turn("LiftArm", Vector3.RIGHT, deg_to_rad(lerpf(arm_down_deg, arm_up_deg, clampf(lift, 0.0, 1.0))))
	if _blade != null:
		_turn("Bucket", Vector3.RIGHT, deg_to_rad(lerpf(bucket_flat_deg, bucket_flat_deg + BLADE_TILT_DEG,
			clampf(curl, 0.0, 1.0))))
		return
	_turn("Bucket", Vector3.RIGHT, deg_to_rad(lerpf(bucket_flat_deg, bucket_dump_deg, clampf(curl, 0.0, 1.0))))


## Where the cutting edge is in the world - the thing that actually meets the
## rubble, so no verb has to guess at an offset. The blade's edge when a blade is
## fitted, the bucket's lip otherwise.
func bucket_edge_world() -> Vector3:
	if _blade_edge != null and is_instance_valid(_blade_edge):
		return _blade_edge.global_position
	var tip := _nodes.get("BucketTip") as Node3D
	if tip != null:
		return tip.global_position
	return global_position + _forward() * 1.6


## Swaps the loader bucket for the push blade: the blade GLB goes under the
## `Bucket` pivot, in the pivot's own frame (the pin is its origin), and the
## bucket's own meshes stop being drawn. Returns false when there is no bucket
## to hang it on or no blade to hang.
func fit_blade() -> bool:
	var pivot := _nodes.get("Bucket") as Node3D
	if pivot == null or _blade != null:
		return _blade != null
	if not ResourceLoader.exists(BLADE_MODEL):
		return false
	var packed := ResourceLoader.load(BLADE_MODEL) as PackedScene
	if packed == null:
		return false
	var inst := packed.instantiate() as Node3D
	if inst == null:
		return false
	inst.name = "PushBlade"
	# Take the bucket off the render layers first, so the blade's own meshes
	# (added after) stay drawn. The pivot ITSELF is on the list: Godot imports the
	# fleet's `Bucket` as the MeshInstance3D (three surfaces, with `BucketTip` a
	# bare Node3D under it) and `find_children` answers descendants only, so a
	# loop over the descendants hid nothing and the bucket's floor and back hung
	# out below and behind the blade in every frame (2026-09-15). And it is
	# `layers = 0`, not `visible = false`: the blade hangs UNDER the pivot, and a
	# hidden pivot hides its whole subtree. `PropIcon`'s attach does the same.
	var masks: Array[Node] = [pivot]
	masks.append_array(pivot.find_children("*", "MeshInstance3D", true, false))
	for n in masks:
		if n is MeshInstance3D:
			(n as MeshInstance3D).layers = 0
	pivot.add_child(inst)
	inst.transform = Transform3D.IDENTITY
	_blade = inst
	_blade_edge = inst.find_child("BladeEdge", true, false) as Node3D
	return true


func has_blade() -> bool:
	return _blade != null


## Shifts the model so the middle of its meshes is on the node's x. The fleet
## promises an origin under the centre; a vehicle from elsewhere may not.
func centre_model_x() -> void:
	if _model == null:
		return
	var box := AABB()
	var first := true
	for n in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var b := (_model.global_transform.affine_inverse() * mi.global_transform) * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if not first:
		_model.position.x -= box.get_center().x


## How wide the working edge is, metres: the blade's board or the bucket's lip.
func edge_width() -> float:
	return 2.04 if _blade != null else 1.58


# --- The dump truck ------------------------------------------------------------------------

## Tips the bed: 0 down, 1 fully up.
func set_bed(k: float) -> void:
	_turn("Bed", Vector3.RIGHT, deg_to_rad(bed_axis_sign * _bed_deg() * clampf(k, 0.0, 1.0)))
	# The tailgate swings open with the load behind it, pinned at its top.
	_turn("Tailgate", Vector3.RIGHT, deg_to_rad(-62.0 * clampf(k * 1.4, 0.0, 1.0)))


func _bed_deg() -> float:
	return config.bed_tip_deg if config != null else 46.0


## Where the load leaves the truck: the bed's own pivot, which is the bottom rear
## corner of the body and does not move as the bed tips - so the stream of stone
## stands still while the bed rises behind it, the way it really does.
##
## NOT the `Tailgate` node: that is hinged at the TOP of the same corner, and it
## swings down and back as the bed goes up (the probe's first reading, 2.24 ->
## 1.91, which looked like a wrong axis and was actually a wrong question).
func bed_lip_world() -> Vector3:
	var bed := _nodes.get("Bed") as Node3D
	if bed != null:
		return bed.global_position
	return global_position - _forward() * 3.0 + Vector3.UP * 1.2


## A point on the FRONT of the bed, for the probe: this is what has to rise when
## the bed tips, and the only honest way to assert the axis is right.
func bed_front_world(along: float = 3.0) -> Vector3:
	var bed := _nodes.get("Bed") as Node3D
	if bed == null:
		return global_position
	return bed.to_global(Vector3(0.0, 0.0, along))


## A heap of stone in the tipper's bed: 1 a full load, 0 empty.
##
## "The dump truck itself looks empty as it pulls up" - it was, and then stone
## appeared on the driveway out of nothing. The heap is built ONCE from the BED's
## own mesh bounds, so it fits the model rather than a guessed box, and it sinks
## as the load runs out of the back.
func set_load(k: float) -> void:
	if _load == null and not _build_load():
		return
	var kk := clampf(k, 0.0, 1.0)
	_load.visible = kk > 0.02
	if not _load.visible:
		return
	var h := maxf(_load_high * kk, 0.01)
	var heap := _load.get_node_or_null("Heap") as MeshInstance3D
	if heap != null:
		var bm := heap.mesh as BoxMesh
		# Shorter as it empties, and slid to the TAILGATE end: what is left of
		# a tipped load lies against the gate, not floating up at the cab end
		# (round 5).
		var long := _load_long * (0.35 + 0.65 * kk)
		bm.size = Vector3(bm.size.x, h, long)
		heap.position.y = _load_floor + h * 0.5
		heap.position.z = _load_centre_z - (_load_long - long) * 0.5
	var top := _load.get_node_or_null("Top") as Node3D
	if top != null:
		top.position.y = _load_floor + h
		top.position.z = _load_centre_z - (_load_long - _load_long * (0.35 + 0.65 * kk)) * 0.5


func load_k() -> float:
	if _load == null or not _load.visible:
		return 0.0
	var heap := _load.get_node_or_null("Heap") as MeshInstance3D
	if heap == null:
		return 0.0
	return clampf((heap.mesh as BoxMesh).size.y / maxf(_load_high, 0.001), 0.0, 1.0)


## Measures the bed and fills it. Returns false when there is no bed to fill.
func _build_load() -> bool:
	var bed := _nodes.get("Bed") as Node3D
	if bed == null:
		return false
	var box := AABB()
	var first := true
	var to_bed := bed.global_transform.affine_inverse()
	for n in bed.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var b := to_bed * (mi.global_transform * mi.mesh.get_aabb())
		box = b if first else box.merge(b)
		first = false
	if first or box.size.x < 0.2:
		return false
	# Inside the sides, sitting on the floor, heaped a little proud of them - which
	# is what a tipper that has just been loaded looks like.
	# Inside the WALLS, not the body's outer skin: at 0.16 the heap stuck out
	# past the side rail (round 5).
	var inset := 0.28
	var wide := maxf(box.size.x - inset * 2.0, 0.2)
	var long := maxf(box.size.z - inset * 2.0, 0.2)
	_load_floor = box.position.y + 0.05
	_load_high = maxf(box.size.y * 0.74, 0.2)
	_load_long = long
	_load_centre_z = box.get_center().z
	_load = Node3D.new()
	_load.name = "Load"
	bed.add_child(_load)
	var heap := MeshInstance3D.new()
	heap.name = "Heap"
	var bm := BoxMesh.new()
	bm.size = Vector3(wide, _load_high, long)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = LOAD_GREY
	mat.roughness = 0.95
	bm.material = mat
	heap.mesh = bm
	heap.position = Vector3(box.get_center().x, _load_floor + _load_high * 0.5, box.get_center().z)
	_load.add_child(heap)
	# Loose stone over the top of it, so the load reads as CRUSHED rather than as a
	# grey brick somebody put in the truck.
	var top := Node3D.new()
	top.name = "Top"
	top.position = Vector3(box.get_center().x, _load_floor + _load_high, box.get_center().z)
	_load.add_child(top)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8821
	for i in range(40):
		var h := rng.randf_range(0.06, 0.13)
		var stone := MeshInstance3D.new()
		stone.name = "Stone"
		var sm := BoxMesh.new()
		sm.size = Vector3(rng.randf_range(0.10, 0.26), h, rng.randf_range(0.10, 0.26))
		var shade := rng.randf_range(-0.14, 0.14)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = LOAD_GREY.lightened(shade) if shade > 0.0 else LOAD_GREY.darkened(-shade)
		smat.roughness = 0.95
		sm.material = smat
		stone.mesh = sm
		var sx := rng.randf_range(-0.46, 0.46)
		var sz := rng.randf_range(-0.46, 0.46)
		# Heaped toward the middle: a tipper that has just been loaded has a crown
		# on it, and a flat top reads as something poured into a mould.
		var crown := (1.0 - (sx * sx + sz * sz) / 0.42) * 0.16
		stone.position = Vector3(sx * wide, h * rng.randf_range(-0.1, 0.3) + maxf(crown, 0.0),
			sz * long)
		stone.rotation = Vector3(deg_to_rad(rng.randf_range(-14.0, 14.0)), rng.randf_range(0.0, TAU),
			deg_to_rad(rng.randf_range(-14.0, 14.0)))
		top.add_child(stone)
	return true


# --- The concrete truck --------------------------------------------------------------------

## The drum's turn, turns a second (0 stops it).
func spin_drum(rps: float) -> void:
	_drum_turn = rps


func drum_spinning() -> bool:
	return _drum_turn != 0.0


## Aims the chute. `swing` is degrees either side of straight back (negative is
## the machine's left); `fold` 0 is stowed and 1 is reaching out.
func set_chute(swing_deg: float, fold: float) -> void:
	_turn("Chute", Vector3.UP, deg_to_rad(chute_swing_sign * swing_deg))
	var f := clampf(fold, 0.0, 1.0)
	var deg: float = config.chute_fold_deg if config != null else 26.0
	_turn("ChuteFold", Vector3.RIGHT, deg_to_rad(chute_fold_sign * deg * f))
	# The extension hangs off wherever the spout is NOW, in the swing pivot's
	# own frame, and only once the chute is out: stowed, it rides on the truck.
	if _chute_ext != null:
		var chute := _nodes.get("Chute") as Node3D
		var spout := _nodes.get("ChutePour") as Node3D
		if chute != null and spout != null:
			_chute_ext.position = chute.to_local(spout.global_position)
		_chute_ext.visible = f > 0.5


## Clips the extension chute on: a trough `length` metres long running on from
## the spout, pitched `CHUTE_EXT_PITCH_DEG` below level, with `PourEnd` at its
## far end. Returns false when there is no chute to clip it to.
func fit_chute_extension(length: float = CHUTE_EXT) -> bool:
	var chute := _nodes.get("Chute") as Node3D
	var spout := _nodes.get("ChutePour") as Node3D
	if chute == null or spout == null:
		return false
	if _chute_ext != null:
		return true
	var ext := Node3D.new()
	ext.name = "ChuteExt"
	chute.add_child(ext)
	# Along the chute's own -Z (straight back from the truck at swing 0),
	# pitched down.
	var pitch := deg_to_rad(CHUTE_EXT_PITCH_DEG)
	var dir := Vector3(0.0, -sin(pitch), -cos(pitch))
	var body := Node3D.new()
	body.name = "ChuteExtBody"
	ext.add_child(body)
	body.position = dir * (length * 0.5)
	body.rotation.x = -pitch
	# Wet steel, not a black gutter: at 0.31 rendered the trough was the
	# darkest thing in the pour's frame and the eye went to it (round 14).
	var trough := Color(0.54, 0.55, 0.58)
	var rail := Color(0.95, 0.70, 0.09)
	body.add_child(_ext_box("Trough", Vector3(0.34, 0.05, length), Vector3(0.0, -0.02, 0.0), trough))
	for sx: float in [-1.0, 1.0]:
		body.add_child(_ext_box("Rail", Vector3(0.035, 0.13, length), Vector3(sx * 0.17, 0.045, 0.0), rail))
	body.add_child(_ext_box("Brace", Vector3(0.40, 0.03, 0.05), Vector3(0.0, -0.045, -length * 0.5 + 0.10), rail))
	# A pale lip at the end, so the eye can see where the concrete leaves.
	body.add_child(_ext_box("Lip", Vector3(0.36, 0.035, 0.09), Vector3(0.0, -0.005, -length * 0.5 + 0.03),
		Color(0.80, 0.82, 0.85)))
	# And MUD in the trough while it pours: a band of wet concrete running down
	# it, unshaded so it is the pool's colour (round 9: the pour's hero shot
	# showed the chute's blank back with the stream appearing from under it).
	var mud := _ext_box("Mud", Vector3(0.26, 0.06, length * 0.96), Vector3(0.0, 0.035, -0.01),
		Color(0.60, 0.61, 0.64))
	(mud.mesh as BoxMesh).material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mud.visible = false
	body.add_child(mud)
	_chute_mud = mud
	var end := Marker3D.new()
	end.name = "PourEnd"
	ext.add_child(end)
	end.position = dir * length
	_chute_ext = ext
	_pour_end = end
	return true


func has_chute_extension() -> bool:
	return _chute_ext != null


## Concrete running down the extension: on while it pours.
func set_chute_mud(on: bool) -> void:
	if _chute_mud != null:
		_chute_mud.visible = on


## The mud takes the pool's own colour, warm (round 14: a fixed cool grey
## read as a steel highlight in the trough).
func set_chute_mud_colour(c: Color) -> void:
	if _chute_mud == null:
		return
	var bm := _chute_mud.mesh as BoxMesh
	if bm != null and bm.material is StandardMaterial3D:
		(bm.material as StandardMaterial3D).albedo_color = c


func _ext_box(box_name: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	bm.material = mat
	mi.mesh = bm
	# The extension hangs right over the pool: its shadow was a dark blob
	# across the concrete under the spout (round 12). The truck's own chute,
	# further back and higher, keeps its shadow and grounds the whole thing.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at
	return mi


## Where the concrete lands: the spout's own marker, aimed down its +Z, carried
## onto the ground (y of `at_y`) so a verb can ask "which cell is under it".
func pour_point_world(at_y: float = 0.0) -> Vector3:
	# Off the end of the extension, straight down, when one is clipped on.
	if _pour_end != null and is_instance_valid(_pour_end) and _chute_ext.visible:
		var e := _pour_end.global_position
		return Vector3(e.x, at_y, e.z)
	var spout := _nodes.get("ChutePour") as Node3D
	if spout == null:
		return global_position - _forward() * 4.0
	var from := spout.global_position
	var down := -spout.global_basis.y.normalized()
	# Straight down if the marker's own aim is near level: a chute pours with
	# gravity, not along its own length.
	if down.y > -0.2:
		down = Vector3.DOWN
	var drop := from.y - at_y
	if drop <= 0.01 or absf(down.y) < 0.01:
		return Vector3(from.x, at_y, from.z)
	var hit := from + down * (drop / -down.y)
	return Vector3(hit.x, at_y, hit.z)


## The spout itself, for hanging the stream of concrete off.
func spout_world() -> Vector3:
	if _pour_end != null and is_instance_valid(_pour_end) and _chute_ext.visible:
		return _pour_end.global_position
	var spout := _nodes.get("ChutePour") as Node3D
	return spout.global_position if spout != null else global_position


## The direction the concrete LEAVES the chute, in the world: down the
## extension's own slope, so the stream can be thrown along it before it falls.
func spout_dir() -> Vector3:
	if _chute_ext != null and is_instance_valid(_chute_ext) and _pour_end != null:
		var d := _pour_end.global_position - _chute_ext.global_position
		return d.normalized() if d.length_squared() > 0.0001 else Vector3.DOWN
	var spout := _nodes.get("ChutePour") as Node3D
	if spout != null:
		return -spout.global_basis.y.normalized()
	return Vector3.DOWN


# --- Plumbing -----------------------------------------------------------------------------

## Turns a named pivot `radians` about `axis`, from its MODELLED rest.
func _turn(node_name: String, axis: Vector3, radians: float) -> void:
	var node := _nodes.get(node_name) as Node3D
	if node == null or not _rest.has(node_name):
		return
	var rest: Transform3D = _rest[node_name]
	node.transform = Transform3D(rest.basis * Basis(axis, radians), rest.origin)


func node_for(node_name: String) -> Node3D:
	return _nodes.get(node_name) as Node3D


## The node a camera shot or the arrow hangs off, by the name a job step uses.
func marker(node_name: String) -> Node3D:
	var node := _nodes.get(node_name) as Node3D
	return node if node != null else self


func _load_model() -> bool:
	var path := model_path if model_path != "" else MODEL_DIR + kind + ".glb"
	if not ResourceLoader.exists(path):
		missing_nodes.append(kind + ".glb")
		return false
	var packed := ResourceLoader.load(path) as PackedScene
	if packed == null:
		missing_nodes.append(kind + ".glb")
		return false
	_model = packed.instantiate() as Node3D
	if _model == null:
		return false
	_model.name = "Model"
	add_child(_model)
	# The fleet exports under a root empty named for the machine, so every node
	# is a grandchild rather than a child: find by name, recursively.
	for want: String in CONTRACT.get(kind, []):
		var node := _model.find_child(want, true, false) as Node3D
		if node == null:
			missing_nodes.append(want)
			continue
		_nodes[want] = node
		_rest[want] = node.transform
	for w in WHEELS:
		if _nodes.has(w):
			continue
		var node := _model.find_child(w, true, false) as Node3D
		if node != null:
			_nodes[w] = node
			_rest[w] = node.transform
	for w in WHEELS:
		if not _nodes.has(w):
			continue
		var tag := w.trim_prefix("Wheel")
		var extras: Array[Node3D] = []
		var hub := _model.find_child("Hub" + tag, true, false) as Node3D
		if hub != null and hub.get_parent() == (_nodes[w] as Node3D).get_parent():
			extras.append(hub)
		for n in _model.find_children("Nut" + tag + "_*", "", true, false):
			var nut := n as Node3D
			if nut != null and nut.get_parent() == (_nodes[w] as Node3D).get_parent():
				extras.append(nut)
		if not extras.is_empty():
			_corner[w] = extras
			for e in extras:
				_corner_rest[e] = e.transform
	_build_beacon()
	model_loaded = missing_nodes.is_empty()
	return true


## No GLB on disk: a grey box the size of the real machine, so the level still
## opens and a screenshot still says where the machine was standing.
func _build_placeholder() -> void:
	var size := {"SkidSteer": Vector3(1.92, 2.21, 3.44), "DumpTruck": Vector3(2.78, 2.79, 7.07),
		"ConcreteTruck": Vector3(2.82, 3.64, 8.58)}.get(kind, Vector3(2.0, 2.0, 4.0)) as Vector3
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.62, 0.64)
	bm.material = mat
	mi.mesh = bm
	mi.position = Vector3(0.0, size.y * 0.5, 0.0)
	_model.add_child(mi)
