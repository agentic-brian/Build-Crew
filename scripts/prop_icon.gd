class_name PropIcon
extends Control
## A real low-poly model standing in its own little lit world, inside a round
## button - Car Garage's `PropIcon` (its job cards, work order and title row,
## Tree Crew's title-row icon before that), brought over on 2026-09-14 for the
## call button: "make them low poly like the key in Garage Crew" (the fourth
## playtest). The flat side-on truck glyphs it replaces said the right words in
## a cartoon language the game itself never speaks.
##
## The picture is a SPEC, so every button that wants one says it as data:
##
##   parts    [{model, at, rot, scale, paint, emit, hide, keep, blend}], or
##            one `model` at the top level for a picture of one thing. Several
##            parts are placed relative to each other (a tire with its wrench);
##            `rot` is in DEGREES, `paint` is {material name: Color} for the
##            albedo, `emit` is {material name: Color} for a glow (a lit bulb),
##            `hide` names nodes to leave out, `keep` names the ONLY nodes to
##            draw (a car's brake disc and caliper, and nothing else of the
##            car), `blend` is {shape key: weight} (the dent pushed in).
##   yaw, pitch, roll   how the camera looks at them, radians. `roll` turns
##            the picture in the plane of the screen - a long thin tool laid
##            corner to corner fills its disc, stood upright it does not.
##   fill     how much of the disc's DIAMETER the picture may span, in the
##            direction it reaches furthest (it is fitted to a circle).
##   drop     slid down the button afterwards, as a fraction of it.
##   sun      the key light's rotation (radians), for a picture whose whole
##            point is a SHAPE the house light flattens - a dent is a hollow
##            only under light that rakes across the panel.
##   focus    {at: Vector3, radius: float}: a CLOSE-UP. The camera is fitted
##            to a ball round `at` (in the picture's own space) instead of to
##            the whole picture, and what spills past the disc is masked off
##            round, so the button is a porthole onto the thing - a dent in a
##            red door, which no fit of the whole car could show at 100 px.
##
## Orthographic, because this is an icon and not a photograph: at 100-200 px a
## model drawn in perspective LEANS, and the lean reads as a mistake.

## The picture. Set before `build()`.
var spec: Dictionary = {}

var _stage: Node3D
var _made: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Stands the models up in their own lit world and returns true. False - no
## file, a root that is not 3D, nothing drawable in it - and the caller puts
## its old drawn icon in its place, so a button is never a hole.
func build() -> bool:
	var parts := _parts_of(spec)
	if parts.is_empty():
		return false
	var stage := Node3D.new()
	stage.name = "Stage"
	for part: Dictionary in parts:
		var inst := _instance(str(part.get("model", "")))
		if inst == null:
			stage.free()
			return false
		inst.name = str(part.get("name", inst.name))
		var rot: Vector3 = part.get("rot", Vector3.ZERO)
		var basis := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
		var sc: Variant = part.get("scale", 1.0)
		var scale_v := Vector3.ONE * float(sc) if not (sc is Vector3) else sc as Vector3
		inst.transform = Transform3D(basis.scaled(scale_v), part.get("at", Vector3.ZERO))
		stage.add_child(inst)
		for hidden: Variant in (part.get("hide", []) as Array):
			var n := inst.find_child(str(hidden), true, false) as Node3D
			if n != null:
				n.visible = false
		var keep: Array = part.get("keep", [])
		if not keep.is_empty():
			_keep_only(inst, keep)
		var blend: Dictionary = part.get("blend", {})
		for shape: String in blend:
			for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
				var idx := mi.find_blend_shape_by_name(StringName(shape))
				if idx >= 0:
					mi.set_blend_shape_value(idx, float(blend[shape]))
		# `attach` [{under: pivot name, model: path}]: a prop hung under a named
		# node at identity - the fleet's push blade under the skid steer's
		# `Bucket` pin, as `Machine.fit_blade` does - with the pivot's OWN mesh
		# and everything under it taken off the render layers, `_keep_only`'s
		# way, so the bucket is not drawn behind the blade.
		for a: Dictionary in (part.get("attach", []) as Array):
			var pivot := inst.find_child(str(a.get("under", "")), true, false) as Node3D
			var prop := _instance(str(a.get("model", "")))
			if pivot == null or prop == null:
				if prop != null:
					prop.queue_free()
				continue
			var masks: Array[Node] = [pivot]
			masks.append_array(pivot.find_children("*", "MeshInstance3D", true, false))
			for n in masks:
				if n is MeshInstance3D:
					(n as MeshInstance3D).layers = 0
			pivot.add_child(prop)
			prop.transform = Transform3D.IDENTITY
		# `pose` {node name: Vector3 DEGREES}: a named node turned from its
		# modelled rest - a bed tipped, a chute swung out.
		var pose: Dictionary = part.get("pose", {})
		for node_name: String in pose:
			var pn := inst.find_child(node_name, true, false) as Node3D
			if pn == null:
				continue
			var d: Vector3 = pose[node_name]
			pn.transform = Transform3D(pn.transform.basis * Basis.from_euler(
				Vector3(deg_to_rad(d.x), deg_to_rad(d.y), deg_to_rad(d.z))), pn.transform.origin)
		var paint: Dictionary = part.get("paint", {})
		for mat_name: String in paint:
			_each_material(inst, mat_name, func(m: StandardMaterial3D) -> void:
				m.albedo_color = paint[mat_name])
		var emit: Dictionary = part.get("emit", {})
		for mat_name: String in emit:
			_each_material(inst, mat_name, func(m: StandardMaterial3D) -> void:
				m.emission_enabled = true
				m.emission = emit[mat_name]
				m.emission_energy_multiplier = 2.2)
	var pane := SubViewportContainer.new()
	pane.name = "View"
	pane.stretch = true
	# The button underneath is the thing being pressed. Nothing in here may
	# answer a finger, or the picture would swallow the tap it is a picture of.
	pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pane)
	var view := SubViewport.new()
	view.name = "Viewport"
	view.transparent_bg = true
	# Its own world, or the little camera would look into the garage behind.
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	# `render_target_update_mode` is deliberately not set: a SubViewportContainer
	# owns that property and rewrites it from its own visibility.
	pane.add_child(view)
	view.add_child(stage)
	_light(view)
	if spec.has("focus"):
		pane.material = _round_mask()
	if not _frame(view, stage):
		push_warning("PropIcon: %s has nothing to draw" % str(parts[0].get("model", "")))
		pane.queue_free()
		return false
	_stage = stage
	_made = true
	return true


## Is this button showing the real models, or did they not load? For tests:
## the fallback drawing is deliberately silent, so without a check a missing
## GLB would quietly put the old pictogram back and nobody would notice.
func is_modelled() -> bool:
	return _made


## How many models the picture stands up (tests).
func part_count() -> int:
	return _stage.get_child_count() if _stage != null else 0


## Only `names` (and what hangs under them) are drawn; every other mesh of the
## model is taken off every render layer - not hidden, because a kept node may
## hang under a mesh that is not (a valve under its wheel), and hiding the
## parent would hide it too.
func _keep_only(inst: Node3D, names: Array) -> void:
	var kept: Array[Node] = []
	for want: Variant in names:
		var n := inst.find_child(str(want), true, false)
		if n != null:
			kept.append(n)
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		var inside := false
		for k in kept:
			if k == mi or k.is_ancestor_of(mi):
				inside = true
				break
		if not inside:
			mi.layers = 0


## A round window for a close-up: what the camera sees past the disc's
## keyline is faded out, so a porthole onto a car door stays a disc.
func _round_mask() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float radius = 0.476;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = distance(UV, vec2(0.5));
	c.a *= 1.0 - smoothstep(radius - 0.006, radius, d);
	COLOR = c;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func _parts_of(s: Dictionary) -> Array:
	if s.has("parts"):
		return s["parts"] as Array
	if s.has("model"):
		# One part: the spec itself (the camera's keys mean nothing to a part).
		return [s]
	return []


func _instance(path: String) -> Node3D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var packed := ResourceLoader.load(path) as PackedScene
	if packed == null:
		return null
	# The scene is BUILT by the time we can ask what its root is, so a root that
	# is not a Node3D has to be freed: `as` yielding null does not undo it.
	var made := packed.instantiate()
	var inst := made as Node3D
	if inst == null and made != null:
		made.queue_free()
	return inst


## Every surface of `want` under `host`, duplicated onto the mesh first so the
## imported material - shared with the same model out in the garage - is never
## touched. Car Garage's `Vehicle` does the same for the same reason.
func _each_material(host: Node, want: String, fn: Callable) -> void:
	var nodes: Array[Node] = [host]
	nodes.append_array(host.find_children("*", "MeshInstance3D", true, false))
	for node in nodes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var live := mi.get_active_material(s)
			if live == null:
				continue
			if not live.resource_name.begins_with(want):
				continue
			var dup := live.duplicate() as StandardMaterial3D
			if dup == null:
				continue
			dup.resource_name = live.resource_name
			mi.set_surface_override_material(s, dup)
			fn.call(dup)


## Lit the way Tree Crew lights its title row: one sun over the viewer's
## shoulder, a cool fill from the other side, and a lot of sky. The facets ARE
## the picture - a low-poly thing lit flat collapses back into a silhouette.
func _light(view: SubViewport) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.80, 0.92)
	env.ambient_light_energy = 0.46
	var we := WorldEnvironment.new()
	we.name = "Env"
	we.environment = env
	view.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.75
	sun.rotation = spec.get("sun", Vector3(-0.80, 0.62, 0.0))
	view.add_child(sun)
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "Fill"
	fill_light.light_energy = 0.45
	fill_light.light_color = Color(0.84, 0.89, 1.0)
	fill_light.rotation = Vector3(-0.20, -2.20, 0.0)
	view.add_child(fill_light)


## Every corner of every triangle of every visible mesh, in the picture's own
## space. The fit is made on THESE and not on the box round the picture: a box
## round a long thing at an angle has corners nothing reaches, and paying for
## them hands a third of the disc to empty air.
##
## Worked out from the transforms down from `root` rather than from
## `global_transform`, so a button can be dressed before it is in the tree -
## the job picker builds its cards first and adds them to its grid after.
func _hull(root: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.layers == 0 or not _shown(mi, root):
			continue
		var xf := _down_to(mi, root)
		for v in mi.mesh.get_faces():
			out.append(xf * v)
	return out


## `n`'s transform in `top`'s space, multiplied down the tree by hand.
func _down_to(n: Node, top: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var at := n
	while at != null and at != top:
		if at is Node3D:
			t = (at as Node3D).transform * t
		at = at.get_parent()
	return t


## Is `n` drawn, as far as its own ancestors up to `top` say?
func _shown(n: Node, top: Node) -> bool:
	var at := n
	while at != null and at != top:
		if at is Node3D and not (at as Node3D).visible:
			return false
		at = at.get_parent()
	return true


## Aims an orthogonal camera at the picture and opens it just wide enough to
## hold it in a CIRCLE `fill` of the button across. The stage stands at the
## origin of the button's own world and the camera is a direct child of the
## viewport, so its local transform IS its place in that world.
func _frame(view: SubViewport, root: Node3D) -> bool:
	var hull := _hull(root)
	if hull.is_empty():
		return false
	var lo3 := hull[0]
	var hi3 := hull[0]
	for p in hull:
		lo3 = Vector3(minf(lo3.x, p.x), minf(lo3.y, p.y), minf(lo3.z, p.z))
		hi3 = Vector3(maxf(hi3.x, p.x), maxf(hi3.y, p.y), maxf(hi3.z, p.z))
	var aim := (lo3 + hi3) * 0.5
	var reach := maxf((hi3 - lo3).length(), 0.05)
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 0.01
	cam.far = reach * 6.0 + 10.0
	view.add_child(cam)
	var yaw := float(spec.get("yaw", 0.8))
	var pitch := float(spec.get("pitch", 0.3))
	var roll := float(spec.get("roll", 0.0))
	var away := Basis.from_euler(Vector3(-pitch, yaw, 0.0)) * Vector3(0.0, 0.0, 1.0)
	var focus: Dictionary = spec.get("focus", {})
	if not focus.is_empty():
		# A close-up: aimed at the spot, opened to the ball round it, and the
		# rest of the model is simply outside the window.
		var at: Vector3 = focus.get("at", aim)
		cam.transform = _aimed(at + away * (reach * 2.0 + 1.0), at, roll)
		cam.size = maxf(float(focus.get("radius", 0.3)) * 2.0, 0.02)
		return true
	cam.transform = _aimed(aim + away * (reach * 2.0 + 1.0), aim, roll)
	var to_cam := cam.transform.affine_inverse()
	var seen := PackedVector2Array()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in hull:
		var flat := to_cam * p
		var at := Vector2(flat.x, flat.y)
		seen.append(at)
		lo = Vector2(minf(lo.x, at.x), minf(lo.y, at.y))
		hi = Vector2(maxf(hi.x, at.x), maxf(hi.y, at.y))
	var middle := (lo + hi) * 0.5
	var b := cam.transform.basis
	cam.position += b.x * middle.x + b.y * middle.y
	var far := 0.0
	for at in seen:
		far = maxf(far, (at - middle).length())
	var fill := float(spec.get("fill", 0.9))
	cam.size = maxf(far * 2.0, 0.05) / maxf(fill, 0.05)
	var drop := float(spec.get("drop", 0.0))
	if not is_zero_approx(drop):
		cam.position += b.y * (cam.size * drop)
	return true


## A camera at `eye` looking at `at`, turned `roll` in the plane of the
## picture (applied after the aim, so the fit is made on what is drawn).
func _aimed(eye: Vector3, at: Vector3, roll: float) -> Transform3D:
	var basis := Basis.looking_at(at - eye, Vector3.UP)
	if not is_zero_approx(roll):
		basis = basis * Basis(Vector3.BACK, roll)
	return Transform3D(basis, eye)
