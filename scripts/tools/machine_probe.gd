extends Node
## What the fleet's GLBs actually contain, and which way their pivots turn.
##
##   godot --headless --path . res://scenes/dev/machine_probe.tscn
##
## The node CONTRACT is in the fleet's own catalogue, but which AXIS a pivot
## turns about - and which sign is "bucket down" or "chute left" - is not, and
## guessing it produces a machine whose bed tips into its own cab with nothing on
## screen to say why. So this prints, for each of the three machines:
##
##   * every contract node, whether it was found, and its rest transform;
##   * where its working end is in the world at rest;
##   * and where that end MOVES TO for each candidate rotation, so the sign and
##     the axis can be read off the numbers instead of guessed.
##
## It prints PASS only if every machine found every node it promises. The axis
## readings are for a human (or me) to read and tune `Machine`'s exports with.

const KINDS: Array[String] = ["SkidSteer", "DumpTruck", "ConcreteTruck"]

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# A probe decides the OS's reduce-motion for itself, or the picture it
	# measures is decided by the machine it runs on (6.4).
	Settings.motion_override = -1
	var cfg := load("res://data/site_config.tres") as SiteConfig
	if cfg == null:
		cfg = SiteConfig.new()
	for kind in KINDS:
		print("--- %s ---" % kind)
		var m := Machine.new()
		m.name = kind
		m.kind = kind
		add_child(m)
		m.setup(cfg)
		await get_tree().process_frame
		_check(m.missing_nodes.is_empty(),
			"%s: every contract node present (missing: %s)" % [kind, _list(m.missing_nodes)])
		for want: String in Machine.CONTRACT.get(kind, []):
			var node := m.node_for(want)
			if node == null:
				print("    %-12s MISSING" % want)
				continue
			print("    %-12s local %s  world %s" % [want, _v(node.position), _v(node.global_position)])
		await _beacon(m, kind)
		match kind:
			"SkidSteer":
				_sweep_skid(m)
			"DumpTruck":
				_sweep_dump(m)
				_held_path(m)
			"ConcreteTruck":
				_sweep_chute(m)
		m.queue_free()
		await get_tree().process_frame
	await _plate_prop(cfg)
	print("MACHINE_PROBE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


## The beacon (the improvement plan's 4.5): its lens glows on a COPY of the
## material, the shared imported one never lights (the tipper's whole body and
## the call button's picture use it), and a pinned lens reads full.
func _beacon(m: Machine, kind: String) -> void:
	var mi := m.node_for("Beacon") as MeshInstance3D
	var lens_s := -1
	if mi != null and mi.mesh != null:
		for s in range(mi.mesh.get_surface_count()):
			var base := mi.mesh.surface_get_material(s)
			if base != null and String(base.resource_name).begins_with(Machine.BEACON_LENS):
				lens_s = s
	var copy: Material = mi.get_surface_override_material(lens_s) if lens_s >= 0 else null
	var shared := mi.mesh.surface_get_material(lens_s) as BaseMaterial3D if lens_s >= 0 else null
	m.pin_beacon(1.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var lit := m.beacon_level()
	m.pin_beacon(-1.0)
	_check(copy != null and copy != shared and lit > 0.99 and shared != null and not shared.emission_enabled,
		"%s: the beacon's lens glows on its own copy (surface %d, lit %.2f), the shared material never lights"
			% [kind, lens_s, lit])


## The bucket at lift 0 and lift 1: the edge should DROP to about the ground at
## 0 and rise well clear at 1, and it should stay out in front of the machine.
func _sweep_skid(m: Machine) -> void:
	m.place(Vector3.ZERO, 0.0)
	for pair: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)]:
		m.set_bucket(pair.x, pair.y)
		print("    bucket lift %.0f curl %.0f -> edge %s" % [pair.x, pair.y, _v(m.bucket_edge_world())])
	m.set_bucket(0.0, 0.0)
	_check(m.bucket_edge_world().z > 0.3,
		"SkidSteer: the bucket edge is in FRONT of the machine (+Z) at rest (z %.2f)" % m.bucket_edge_world().z)
	_check(absf(m.bucket_edge_world().y) < 0.25,
		"SkidSteer: at lift 0 the cutting edge is ON the dirt (y %.2f)" % m.bucket_edge_world().y)
	m.set_bucket(1.0, 0.0)
	var high := m.bucket_edge_world().y
	m.set_bucket(0.0, 0.0)
	_check(high > m.bucket_edge_world().y + 0.3,
		"SkidSteer: lift 1 carries the bucket HIGHER than lift 0 (%.2f vs %.2f)" % [high, m.bucket_edge_world().y])
	m.set_bucket(0.0, 1.0)
	_check(m.bucket_edge_world().y < 0.25,
		"SkidSteer: curling to dump does not throw the edge into the air (y %.2f)" % m.bucket_edge_world().y)
	m.set_bucket(0.0, 0.0)


## The bed down and up. The thing that has to RISE is the FRONT of the bed: the
## pivot is at the rear, so the tailgate end stays put and the load slides off
## backwards past it. Asking about the tailgate is what made this read as a wrong
## axis when the axis was right.
func _sweep_dump(m: Machine) -> void:
	m.place(Vector3.ZERO, 0.0)
	m.set_bed(0.0)
	var front_down := m.bed_front_world()
	var lip_down := m.bed_lip_world()
	m.set_bed(1.0)
	var front_up := m.bed_front_world()
	var lip_up := m.bed_lip_world()
	print("    bed 0 -> front %s  lip %s" % [_v(front_down), _v(lip_down)])
	print("    bed 1 -> front %s  lip %s" % [_v(front_up), _v(lip_up)])
	_check(front_up.y > front_down.y + 0.5,
		"DumpTruck: tipping RAISES the front of the bed (%.2f -> %.2f)" % [front_down.y, front_up.y])
	_check(lip_up.distance_to(lip_down) < 0.05,
		"DumpTruck: the load leaves from a lip that stays STILL as the bed rises (%.3f moved)"
			% lip_up.distance_to(lip_down))
	m.set_bed(0.0)


## A truck walked along a path by a FINGER, not a clock (the improvement plan's
## 1.8): standing it at the same place twice moves nothing and turns no wheel,
## and the end of the path is where it stops, facing away from the way it came.
func _held_path(m: Machine) -> void:
	m.place(Vector3(-7.0, 0.0, 8.6), -90.0)
	var pts: Array[Vector3] = [Vector3(-7.0, 0.0, 8.6), Vector3(-2.0, 0.0, 8.0), Vector3(0.0, 0.0, 3.0), Vector3(0.0, 0.0, 0.5)]
	m.set_path(pts, true)
	m.place_on_path(0.5)
	var at := m.global_position
	var rolled := m.rolled_m()
	m.place_on_path(0.5)
	_check(m.global_position.distance_to(at) < 0.0001 and absf(m.rolled_m() - rolled) < 0.0001 and not m.is_driving(),
		"DumpTruck: a held path stands still between presses (moved %.4f, rolled %.4f)"
			% [m.global_position.distance_to(at), m.rolled_m() - rolled])
	m.place_on_path(1.0)
	_check(Vector2(m.global_position.x, m.global_position.z).distance_to(Vector2(0.0, 0.5)) < 0.01 \
		and absf(wrapf(rad_to_deg(m.rotation.y) - m.path_facing_deg(1.0), -180.0, 180.0)) < 1.0 \
		and m.rolled_m() < rolled,
		"DumpTruck: at the end of it, backed in tail first, wheels turned backwards (%s, %.1f deg)"
			% [_v(m.global_position), rad_to_deg(m.rotation.y)])


## The plate compactor's GLB (5.1): the four nodes its tool contract names, the
## origin on the sole, and a handle rooted near that origin so stretching it to
## the hands does not pull it off the engine.
func _plate_prop(cfg: SiteConfig) -> void:
	print("--- PlateCompactor ---")
	var t := HandTool.new()
	t.kind = "plate"
	add_child(t)
	t.setup(cfg)
	await get_tree().process_frame
	var body := t.find_child("Body", true, false) as MeshInstance3D
	var box := body.get_aabb() if body != null else AABB()
	var grip := t.find_child("Grip", true, false) as Node3D
	_check(t.model_loaded and t.missing_nodes.is_empty() and body != null and grip != null,
		"PlateCompactor: the GLB has Body, Head, Grip and Tip (missing: %s)" % _list(t.missing_nodes))
	_check(box.position.y < 0.05 and box.end.z > -0.15 and box.end.y > 0.8,
		"PlateCompactor: its handle is rooted at the frame and reaches back to the hands (%s)" % str(box))
	t.queue_free()
	await get_tree().process_frame


## The chute swung either way, deployed. The SWING is the aim, so it has to reach
## across the form's full width; the FOLD is deployment only, and this says so in
## numbers rather than leaving someone to rediscover it.
func _sweep_chute(m: Machine) -> void:
	m.place(Vector3.ZERO, 0.0)
	# As the game uses it: with the extension chute clipped on (DESIGN 2a).
	m.fit_chute_extension()
	var cfg := load("res://data/site_config.tres") as SiteConfig
	var limit: float = cfg.chute_swing_deg if cfg != null else 72.0
	var seen: Array[Vector3] = []
	for pair: Vector2 in [Vector2(0.0, 1.0), Vector2(-limit, 1.0), Vector2(limit, 1.0),
			Vector2(0.0, 0.0)]:
		m.set_chute(pair.x, pair.y)
		var at := m.pour_point_world(0.0)
		seen.append(at)
		print("    chute swing %5.0f fold %.1f -> spout %s  lands %s"
			% [pair.x, pair.y, _v(m.spout_world()), _v(at)])
	# What has to cover the width is the WETTED span, not the span of the landing
	# point: the stream is `pour_spread` wide on each side of where it lands. The
	# chute's arm is only 1.26 m long, so its point sweeps 2.4 m - but it wets
	# 3.6 m, which is the question that matters. (Measuring the point alone is
	# what made this read as "the chute cannot reach" when it can.)
	var span := absf(seen[1].x - seen[2].x)
	var spread: float = cfg.pour_spread if cfg != null else 0.62
	_check(span + spread * 2.0 >= Driveway.WIDTH,
		"ConcreteTruck: the stream wets the whole width (%.2f point + 2 x %.2f spread vs %.2f m)"
			% [span, spread, Driveway.WIDTH])
	# Deploying has to LOWER the chute over the form, not fold it up in the air.
	m.set_chute(0.0, 0.0)
	var stowed := m.spout_world().y
	m.set_chute(0.0, 1.0)
	var out := m.spout_world().y
	_check(out < stowed,
		"ConcreteTruck: deploying the chute brings the spout DOWN (%.2f -> %.2f)" % [stowed, out])
	_check(m.spout_world().y > 0.15,
		"ConcreteTruck: the end of the extension is still off the ground when deployed (%.2f)" % m.spout_world().y)
	var reach := m.global_position.z - m.pour_point_world(0.0).z
	_check(reach > 5.0,
		"ConcreteTruck: with the extension on, the pour lands %.2f m behind the origin (rear tyre at 3.16)" % reach)
	m.set_chute(0.0, 1.0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])


func _v(v: Vector3) -> String:
	return "(%6.2f, %6.2f, %6.2f)" % [v.x, v.y, v.z]


func _list(a: PackedStringArray) -> String:
	return "none" if a.is_empty() else ", ".join(a)
