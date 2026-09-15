class_name HandTool
extends Node3D
## Every tool the child works the driveway with: the JACKHAMMER (phase 1), the
## SLEDGE that drives the form stakes (4), the SCREED BOARD (8), the JOINTER (9),
## the BROOM (10) and the HOSE NOZZLE that wets the slab (7).
##
## Car Garage's `HandTool`, with this job's tools in place of the garage's. One
## script, six kinds, because they are all the same thing to the level: a prop
## whose origin is the face that meets the work, with +Z pointing INTO the work,
## that flies, parks and hovers through `hover` / `hover_instant` / `fly_to`.
##
## What each one DOES while the finger is down - the hammering, the blows, the
## sawing, the brushing - is the verb's business (`SiteVerbs`); this node only
## offers `set_bit()`, `spin()` and `spray()` for the ones with a moving part.
##
## `tools/make_site_props.py` builds the five new GLBs; `HoseNozzle.glb` comes
## from Car Garage's own prop pass. A kind whose GLB is missing gets a box
## stand-in with the same frame, so the level always opens.

signal fly_done

const MODELS := {
	"jackhammer": "res://assets/models/props/Jackhammer.glb",
	"sledge": "res://assets/models/props/Sledge.glb",
	"screed": "res://assets/models/props/ScreedBoard.glb",
	"jointer": "res://assets/models/props/Jointer.glb",
	"broom": "res://assets/models/props/Broom.glb",
	"hose": "res://assets/models/props/HoseNozzle.glb",
	"rake": "res://assets/models/props/ComeAlong.glb",
}
## What each kind promises, so a silently half-exported GLB is reported rather
## than quietly making a tool with nothing to move.
const WANTED := {
	"jackhammer": ["Body", "Bit", "Tip"],
	"sledge": ["Body", "Head", "Tip"],
	"screed": ["Body", "Tip"],
	"jointer": ["Body", "Blade", "Tip"],
	"broom": ["Body", "Head", "Tip"],
	"hose": ["Body", "Tip"],
	"rake": ["Body", "Head", "Tip"],
}
## The kinds that throw something out of their nozzle.
const SPRAYERS: Array[String] = ["hose"]
## How big each tool is against the GLB it is built from.
##
## The jackhammer is the only one that is not 1: "jack hammer too small" was the
## user's first note, and it was right twice over. The model is a 0.55 m breaker,
## which is a light demolition hammer; the thing a crew brings to take a driveway
## out is a 90 lb pneumatic breaker a metre tall with handles you stand behind. So
## the tool grew to that, and `CameraRig.PANEL` came in to meet it.
## The others were never scaled - the note was applied to one dictionary entry
## (round 3): the sledge's head was 25 px and the jointer's blade 10.
const SCALE := {"jackhammer": 1.85, "sledge": 1.45, "jointer": 1.6, "broom": 1.2, "rake": 1.15}
## How many drops of water the hose throws.
const SPRAY_COUNT := 110
## The end of the hose stub the nozzle's GLB was built with, in the model's own
## frame, and the way it runs (car-fixer `tools/make_parts.py`
## `build_hose_nozzle`: a 12 mm tube from (0, -0.110, -0.155) to here, joined
## into Body). The hose itself leaves from it (the improvement plan's 4.3).
const STUB_END := Vector3(0.0, -0.180, -0.230)
const STUB_DIR := Vector3(0.0, -0.070, -0.075)
## The hose: the stub's own radius, so there is no step at the joint, and its
## own eight sides.
const TRAIL_R := 0.012
const TRAIL_RINGS := 10
const TRAIL_SIDES := 8
## (No sway. The plan asked for a slight swing when the aim moves; the hose leaves
## the picture within a few centimetres of the grip - none of it is on screen at
## 16:9, its top quarter on a 4:3 iPad - so a swing measured 0 px on the phone and
## a few on the iPad while the nozzle itself swings hundreds. The spring was
## taken out in session 4's verification pass rather than kept as a number.)
const HOSE_GREEN := Color(0.20, 0.62, 0.30)

## `jackhammer`, `sledge`, `screed`, `jointer`, `broom` or `hose`: set BEFORE
## the node enters the tree.
@export var kind: String = "jackhammer"

var model_loaded: bool = false
var missing_nodes: PackedStringArray = PackedStringArray()
var config: SiteConfig
## True while a verb has the tool on the work: `present_tool` leaves it there.
var attached: bool = false

var _sfx: Node
var _model: Node3D
## The jackhammer's moil point, which slides along +Z as it hammers.
var _bit: Node3D
var _bit_home: Vector3 = Vector3.ZERO
var _spray: GPUParticles3D
## The jet itself: four short segments on a shallow parabola from the nozzle
## toward where it lands, opening and fading as they go, so the water starts AT
## the nozzle and FALLS (round 4: drops in mid-air; round 6: a rigid rod).
var _jet: Node3D
var _jet_segs: Array[MeshInstance3D] = []
## The hose off the nozzle's butt, down to a point below the picture (4.3).
var _trail: MeshInstance3D
var _trail_end: Vector3 = Vector3.INF
var _trail_key: Vector3 = Vector3.INF
var _trail_centres: PackedVector3Array = PackedVector3Array()
var _spin_rps: float = 0.0
var _flying: bool = false
var _t: float = 0.0
var _time: float = 1.0
var _from: Transform3D = Transform3D.IDENTITY
var _to: Transform3D = Transform3D.IDENTITY
var _arc: float = 0.0


func _ready() -> void:
	if not _load_model():
		_build_placeholder()
	if kind in SPRAYERS:
		_build_spray()
		_build_trail()
	if _model != null:
		_model.scale = Vector3.ONE * float(SCALE.get(kind, 1.0))


func setup(cfg: SiteConfig, sfx: Node = null, _cam: Node = null) -> void:
	config = cfg
	_sfx = sfx


func is_busy() -> bool:
	return _flying


# --- Where it goes -----------------------------------------------------------------------

## Parks or hovers. The working face looks along `into`, the tool's up along `up`.
func hover(point: Vector3, into: Vector3 = Vector3.DOWN, up: Vector3 = Vector3.FORWARD) -> void:
	fly_to(pose(point, into, up), config.tool_fly_time if config != null else 0.5,
		config.tool_arc if config != null else 0.15)


func hover_instant(point: Vector3, into: Vector3 = Vector3.DOWN, up: Vector3 = Vector3.FORWARD) -> void:
	_flying = false
	global_transform = pose(point, into, up)


## Eased flight to a pose over `seconds`, with a lob of `arc` metres.
func fly_to(to: Transform3D, seconds: float, arc: float = 0.0) -> void:
	# A tool flying is not in anybody's hands: the hose goes with the hands.
	drop_trail()
	_from = global_transform
	_to = to
	_time = maxf(seconds, 0.01)
	_arc = arc
	_t = 0.0
	_flying = true


func snap_to(to: Transform3D) -> void:
	drop_trail()
	_flying = false
	global_transform = to


## A pose with the working face at `origin` looking along `into` (+Z) and the
## tool's up along `up` (+Y), square to it.
func pose(origin: Vector3, into: Vector3, up: Vector3 = Vector3.UP) -> Transform3D:
	var zb := into.normalized()
	if zb.length_squared() < 0.5:
		zb = Vector3.DOWN
	var yb := up - zb * up.dot(zb)
	if yb.length_squared() < 0.0001:
		yb = Vector3.UP - zb * Vector3.UP.dot(zb)
	if yb.length_squared() < 0.0001:
		yb = Vector3.FORWARD
	yb = yb.normalized()
	var xb := yb.cross(zb).normalized()
	return Transform3D(Basis(xb, yb, zb), origin)


# --- The moving parts ----------------------------------------------------------------------

## The kinds whose handle is stretched into the child's hands.
const HANDLED := ["rake", "broom", "jointer"]


## Stretches the handle so its grip ends in the child's HANDS: the Body node
## (the handle, bracket and grip - its pivot is the tool's origin, at the
## head) is scaled along the tool's own Y (toward the hands) and Z (up off the
## slab) so the grip's tip lands on `hands`. A fixed 1.6 m handle aimed at
## hands three metres away ended in mid-air with a red cap and its own shadow
## (round 10). Where the handle ends is MEASURED off the mesh (its box's far
## corner), not typed: the jointer's asset was a build behind its builder and
## a typed end stretched it to half way (round 10, found in the frame).
func aim_handle_at(hands: Vector3) -> void:
	if _model == null or kind not in HANDLED:
		return
	var body := _model.find_child("Body", true, false) as MeshInstance3D
	if body == null:
		return
	var box := body.get_aabb()
	var end := Vector3(0.0, box.end.y, box.position.z)
	if end.y < 0.05 or end.z > -0.05:
		return
	var local := _model.to_local(hands)
	var sy := clampf(local.y / end.y, 0.6, 3.2)
	var sz := clampf(local.z / end.z, 0.6, 3.2)
	body.scale = Vector3(1.0, sy, sz)
	# A grip built as its own node rides to the handle's stretched end, its
	# own size.
	var grip := _model.find_child("Grip", true, false) as Node3D
	if grip != null:
		grip.position = Vector3(0.0, end.y * (sy - 1.0), end.z * (sz - 1.0))


## Turns the working head (the `Blade` or `Head` node, whose pivot is the
## tool's origin) about the tool's own Z so its long axis lies along
## `world_dir` on the ground, whatever way the handle points: the jointer's
## sled sits ON the line it cuts while the handle runs to the hands (round 12).
func align_head(world_dir: Vector3) -> void:
	if _model == null:
		return
	var head := _model.find_child("Blade", true, false) as Node3D
	if head == null:
		head = _model.find_child("Head", true, false) as Node3D
	if head == null:
		return
	var d := Vector3(world_dir.x, 0.0, world_dir.z)
	if d.length_squared() < 0.0001:
		return
	d = d.normalized()
	var b := global_transform.basis
	var lx := d.dot(b.x)
	var ly := d.dot(b.y)
	head.rotation = Vector3(0.0, 0.0, atan2(-lx, ly))


## The jackhammer's point, pushed `out` metres along its own +Z (0 is home).
## A hammer whose bit does not move is a hammer that is only making a noise.
func set_bit(out: float) -> void:
	if _bit == null:
		return
	_bit.position = _bit_home + Vector3(0.0, 0.0, out)


func bit_out() -> float:
	return (_bit.position - _bit_home).z if _bit != null else 0.0


## A head that turns about its own axis at `rps` turns a second (0 stops it).
func spin(rps: float) -> void:
	_spin_rps = rps


## The hose on or off. `color` is the water.
func spray(on: bool, color: Color = Color(0.62, 0.80, 0.95, 0.8)) -> void:
	if _spray == null:
		return
	if on:
		var m := _spray.process_material as ParticleProcessMaterial
		if m != null:
			m.color = color
	_spray.emitting = on
	if _jet != null:
		_jet.visible = on


func spraying() -> bool:
	return _spray != null and _spray.emitting


## The hose itself runs from the nozzle's butt to `end` - a point the level puts
## below the bottom of the picture - hanging (the improvement plan's 4.3). The
## rule the rake, the groover and the broom already obey: a held tool is
## connected to the bottom of the picture. Call it AFTER the nozzle has been
## placed this frame.
func trail_to(end: Vector3) -> void:
	if _trail == null:
		return
	# No camera gives ZERO; a hose two metres long means the eye is not on the
	# hands. Either way there is nothing honest to draw.
	if end == Vector3.ZERO or global_position.distance_to(end) > 2.0:
		drop_trail()
		return
	_trail_end = end
	_trail.visible = true
	_rebuild_trail()


func drop_trail() -> void:
	if _trail == null:
		return
	_trail.visible = false
	_trail_end = Vector3.INF
	_trail_key = Vector3.INF


func trail_visible() -> bool:
	return _trail != null and _trail.visible and is_visible_in_tree()


## The hose's centre line, nozzle end first, in world space.
func trail_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for c in _trail_centres:
		out.append(to_global(c))
	return out


## Where the nozzle's own hose stub ends, in world space.
func stub_world() -> Vector3:
	return to_global(_stub_local())


## The water's centre line - the nozzle, then each jet segment - in world space.
func jet_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	out.append(global_position)
	for seg in _jet_segs:
		out.append(seg.global_position)
	return out


func _stub_local() -> Vector3:
	return _model.transform * STUB_END if _model != null else Vector3.ZERO


func _stub_dir_local() -> Vector3:
	return (_model.transform.basis * STUB_DIR).normalized() if _model != null else Vector3.BACK


## How far the jet has to reach, metres. A hose held in the child's own hands
## (DESIGN 1a's `HAND` shot) is a metre from the eye and aimed at a slab that
## may be eight metres away, so the drops have to be thrown that far instead of
## dribbling out of the nozzle: the speed is set so a drop lands at about
## `metres` within its own lifetime, and the fan opens up a little with it.
func set_spray_reach(metres: float) -> void:
	if _spray == null:
		return
	var m := _spray.process_material as ParticleProcessMaterial
	if m == null:
		return
	var life := clampf(metres * 0.14, 0.35, 1.10)
	_spray.lifetime = life
	var v := clampf(metres / maxf(life, 0.05), 3.0, 16.0)
	m.initial_velocity_min = v * 0.88
	m.initial_velocity_max = v * 1.08
	m.spread = clampf(4.0 + metres * 0.5, 4.0, 9.0)
	if _jet != null:
		var len := maxf(metres * 0.78, 0.2)
		# y = -g z^2, dropping a tenth of the reach by the end.
		var g := 0.10 / len
		var n := _jet_segs.size()
		for i in range(n):
			var z0 := len * float(i) / float(n)
			var z1 := len * float(i + 1) / float(n)
			var y0 := -g * z0 * z0
			var y1 := -g * z1 * z1
			var seg := _jet_segs[i]
			var cm := seg.mesh as CylinderMesh
			cm.height = Vector2(z1 - z0, y1 - y0).length() + 0.01
			cm.bottom_radius = lerpf(0.012, 0.05, float(i) / float(n))
			cm.top_radius = lerpf(0.012, 0.05, float(i + 1) / float(n))
			seg.position = Vector3(0.0, (y0 + y1) * 0.5, (z0 + z1) * 0.5)
			seg.rotation.x = atan2(z1 - z0, y1 - y0)
			var mat := cm.material as StandardMaterial3D
			if mat != null:
				mat.albedo_color.a = lerpf(0.65, 0.25, float(i) / float(n - 1))


func _process(delta: float) -> void:
	if _spin_rps != 0.0 and _bit != null:
		_bit.rotate_object_local(Vector3.FORWARD, TAU * _spin_rps * delta)
	if _flying:
		_t += delta
		var k := clampf(_t / _time, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		var pose_now := _from.interpolate_with(_to, e)
		pose_now.origin.y += _arc * 4.0 * k * (1.0 - k)
		global_transform = pose_now
		if k >= 1.0:
			_flying = false
			global_transform = _to
			fly_done.emit()


## A jet of water out of the nozzle (+Z), short-lived: it lands on the slab a
## stride away and is gone, so what a child sees is the slab being WETTED rather
## than a cloud standing in the air.
func _build_spray() -> void:
	_spray = GPUParticles3D.new()
	_spray.name = "Water"
	_spray.amount = SPRAY_COUNT
	_spray.lifetime = 0.45
	_spray.explosiveness = 0.0
	_spray.emitting = false
	_spray.local_coords = false
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0.0, 0.0, 1.0)
	m.spread = 7.0
	m.initial_velocity_min = 3.0
	m.initial_velocity_max = 3.8
	m.gravity = Vector3(0.0, -4.0, 0.0)
	m.scale_min = 0.6
	m.scale_max = 1.0
	m.color = Color(0.62, 0.80, 0.95, 0.8)
	_spray.process_material = m
	var drop := QuadMesh.new()
	drop.size = Vector2(0.04, 0.04)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
	mat.albedo_texture = SiteMain.soft_dot()
	drop.material = mat
	_spray.draw_pass_1 = drop
	add_child(_spray)
	_jet = Node3D.new()
	_jet.name = "Jet"
	_jet.visible = false
	add_child(_jet)
	for i in range(4):
		var seg := MeshInstance3D.new()
		seg.name = "JetSeg_%d" % i
		var jb := CylinderMesh.new()
		jb.top_radius = 0.02
		jb.bottom_radius = 0.02
		jb.height = 0.25
		jb.radial_segments = 8
		var jm := StandardMaterial3D.new()
		jm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		jm.albedo_color = Color(0.74, 0.87, 0.98, 0.55)
		jm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		jb.material = jm
		seg.mesh = jb
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_jet.add_child(seg)
		_jet_segs.append(seg)


func _build_trail() -> void:
	_trail = MeshInstance3D.new()
	_trail.name = "Trail"
	_trail.mesh = ArrayMesh.new()
	var m := _mat(HOSE_GREEN)
	m.roughness = 0.62
	_trail.material_override = m
	# No shadow: the hose ends in mid-air below the eye, and its shadow would be
	# a cut-off hose lying on the slab (the chute's stream turns its off too).
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_trail.visible = false
	add_child(_trail)


## Sweeps the hose along a bezier from inside the stub, leaving along the stub's
## own line, to `_trail_end`, arriving from above so it HANGS - all in this
## node's own space, so the joint at the nozzle cannot tear by a frame whatever
## moves the nozzle after this runs. Rebuilt only when something has moved.
func _rebuild_trail() -> void:
	if _trail == null or _trail_end == Vector3.INF:
		return
	var inv := global_transform.affine_inverse()
	var d := _stub_dir_local()
	var p0 := _stub_local() - d * 0.005
	var p3: Vector3 = inv * _trail_end
	var l := p0.distance_to(p3)
	# The far end is the only thing that moves in this node's space: nothing to
	# rebuild while it has not moved a millimetre.
	if p3.distance_to(_trail_key) < 0.001:
		return
	_trail_key = p3
	var p1 := p0 + d * l * 0.35
	var p2 := p3 + inv.basis * (Vector3.UP * l * 0.30)
	var rings: Array[PackedVector3Array] = []
	_trail_centres = PackedVector3Array()
	var n := Vector3.RIGHT
	for i in range(TRAIL_RINGS + 1):
		var t := float(i) / float(TRAIL_RINGS)
		var c := p0.bezier_interpolate(p1, p2, p3, t)
		var tng := p0.bezier_derivative(p1, p2, p3, t)
		tng = tng.normalized() if tng.length_squared() > 1e-10 else d
		# Parallel transport: each ring's frame is the last one's, squared to the
		# new tangent, so the tube never twists.
		n = n - tng * n.dot(tng)
		if n.length_squared() < 1e-8:
			n = tng.cross(Vector3.UP)
		n = n.normalized()
		var b := tng.cross(n)
		var ring := PackedVector3Array()
		for k in range(TRAIL_SIDES):
			var a := TAU * float(k) / float(TRAIL_SIDES)
			ring.append(c + (n * cos(a) + b * sin(a)) * TRAIL_R)
		rings.append(ring)
		_trail_centres.append(c)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(TRAIL_RINGS):
		var mid := (_trail_centres[i] + _trail_centres[i + 1]) * 0.5
		for k in range(TRAIL_SIDES):
			var k1 := (k + 1) % TRAIL_SIDES
			var va: Vector3 = rings[i][k]
			var vb: Vector3 = rings[i][k1]
			var vc: Vector3 = rings[i + 1][k1]
			var vd: Vector3 = rings[i + 1][k]
			var out := (va + vc) * 0.5 - mid
			_trail_tri(st, va, vb, vc, out)
			_trail_tri(st, va, vc, vd, out)
	var mesh := _trail.mesh as ArrayMesh
	mesh.clear_surfaces()
	st.commit(mesh)


## One face of the hose, wound to face `out` (Godot's front faces are clockwise;
## the intuitive order renders nothing) and flat-lit like the stub it joins.
func _trail_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, out: Vector3) -> void:
	var nrm := (b - a).cross(c - a)
	if nrm.length_squared() < 1e-14:
		return
	var flip := nrm.dot(out) > 0.0
	# The normal points OUT whichever order the corners go down in.
	var face := nrm.normalized()
	if face.dot(out) < 0.0:
		face = -face
	st.set_normal(face)
	if flip:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
	else:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)


# --- The model ------------------------------------------------------------------------------

func _load_model() -> bool:
	var path: String = MODELS.get(kind, "")
	if path == "" or not ResourceLoader.exists(path):
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		return false
	_model = packed.instantiate() as Node3D
	if _model == null:
		return false
	_model.name = "Model"
	add_child(_model)
	for n in WANTED.get(kind, []):
		if _model.find_child(String(n), true, false) == null:
			missing_nodes.append(String(n))
	_bit = _model.find_child("Bit", true, false) as Node3D
	if _bit == null:
		_bit = _model.find_child("Head", true, false) as Node3D
	if _bit != null:
		_bit_home = _bit.position
	model_loaded = missing_nodes.is_empty()
	return true


## A stand-in with the same frame as each GLB: the working face at the origin,
## +Z into the work, so a level with no props built yet still plays and still
## shows where the tool is.
func _build_placeholder() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	match kind:
		"jackhammer":
			var bit := _box("Bit", Vector3(0.028, 0.028, 0.11), Vector3(0.0, 0.0, -0.055),
				Color(0.80, 0.82, 0.85))
			_model.add_child(bit)
			_bit = bit
			_bit_home = bit.position
			_model.add_child(_box("Body", Vector3(0.10, 0.10, 0.30), Vector3(0.0, 0.0, -0.28),
				Color(0.95, 0.45, 0.08)))
			_model.add_child(_box("Handles", Vector3(0.38, 0.035, 0.035), Vector3(0.0, 0.0, -0.45),
				Color(0.20, 0.21, 0.24)))
		"sledge":
			var head := _box("Head", Vector3(0.084, 0.084, 0.11), Vector3(0.0, 0.0, -0.055),
				Color(0.58, 0.60, 0.64))
			_model.add_child(head)
			_bit = head
			_bit_home = head.position
			_model.add_child(_box("Body", Vector3(0.038, 0.30, 0.038), Vector3(0.0, 0.15, -0.19),
				Color(0.67, 0.48, 0.28)))
		"screed":
			_model.add_child(_box("Body", Vector3(4.20, 0.09, 0.04), Vector3(0.0, 0.045, 0.0),
				Color(0.67, 0.48, 0.28)))
		"jointer":
			# The GLB's tool orange (4.4), not the pale metal that was the round-12
			# trap: a missing asset must not bring back the brightest sled on the lot.
			_model.add_child(_box("Blade", Vector3(0.12, 0.03, 0.03), Vector3(0.0, 0.01, -0.015),
				Color(0.62, 0.27, 0.03)))
			_model.add_child(_box("Body", Vector3(0.03, 0.46, 0.03), Vector3(0.0, 0.24, -0.18),
				Color(0.67, 0.48, 0.28)))
		"broom":
			var brush := _box("Head", Vector3(0.90, 0.02, 0.084), Vector3(0.0, 0.0, -0.042),
				Color(0.18, 0.30, 0.62))
			_model.add_child(brush)
			_model.add_child(_box("Body", Vector3(0.034, 0.72, 0.034), Vector3(0.0, 0.36, -0.34),
				Color(0.62, 0.44, 0.26)))
		"rake":
			_model.add_child(_box("Head", Vector3(0.52, 0.022, 0.14), Vector3(0.0, 0.0, -0.07),
				Color(0.80, 0.82, 0.85)))
			_model.add_child(_box("Body", Vector3(0.034, 1.5, 0.034), Vector3(0.0, 0.78, -0.52),
				Color(0.62, 0.44, 0.26)))
		_:
			_model.add_child(_box("Body", Vector3(0.035, 0.035, 0.14), Vector3(0.0, 0.0, -0.07),
				Color(0.20, 0.62, 0.30)))
	missing_nodes.append("Tip")


func _box(box_name: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = _mat(color)
	mi.mesh = bm
	mi.position = at
	return mi


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.7
	return m
