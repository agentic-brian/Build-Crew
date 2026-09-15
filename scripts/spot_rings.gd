class_name SpotRings
extends Node3D
## The little gold rings that say WHERE TO TAP — Tree Crew's `FellHint`, made
## plural.
##
## Tree Crew shows one ring at a time because a tree is felled in one place. A
## driveway is not: the hammer is worked at three places on a slab and the stakes
## go in at ten places round the form, and the user's note was that they could not
## tell where to press. So this holds a SET of rings, all lit at once, and the
## child may take them in any order they like.
##
## Each ring carries an `id` — which spot, which stake, which board — and
## `pick_nearest` turns a finger on the screen into that id. That is the whole
## interface: the level asks for a set of points, and gets back which one was
## tapped.
##
## They are drawn with `no_depth_test`, so a ring never disappears behind the
## thing it is marking, and `billboard_keep_scale` so one 20 cm ring is the same
## size on screen whether the camera is a metre away or eight.

## The gold everything in this family points with.
const GOLD := Color(1.0, 0.85, 0.3)
## The distance at which a ring is drawn at exactly the size it was asked for;
## nearer it shrinks and further it grows, so it covers the same part of the
## screen wherever it is.
const NOMINAL_M := 4.5
## The arrow over a single ring: how big it is against the ring, how high it
## rides, how far it falls on a bob, and how fast.
const ARROW_OF_RING := 0.84
const ARROW_LIFT := 1.30
const ARROW_DIP := 0.42
const BOB_HZ := 1.25
## How long a "no, over HERE" lasts.
const NUDGE_SECS := 0.7

var _rings: Array[MeshInstance3D] = []
## One bobbing arrow per ring, drawn only when there is exactly ONE: a single
## place wants to be unmistakable, and three arrows over three rings is clutter.
var _arrows: Array[MeshInstance3D] = []
var _ids: PackedInt32Array = PackedInt32Array()
var _points: Array[Vector3] = []
var _time: float = 0.0
## The ring a tap chose snaps OUT - bigger and gone in a blink - the frame the
## tap is accepted, while the others stay lit (the improvement plan's 1.3). It
## stays in the set, which is rebuilt after the bite anyway, but is not picked
## again. One entry per ring: seconds of snap left, or -1 for a ring not taken.
var _take_t: PackedFloat32Array = PackedFloat32Array()
const TAKE_SECS := 0.15
## The ring nearest a miss throbs ONCE: 1.45x and back over `THROB_SECS`, so
## a miss is answered by the right place rather than by the whole set
## wobbling faster (the plan's 1.2).
var _throb_i: int = -1
var _throb_t: float = 0.0
const THROB_SECS := 0.5
## Seconds of "no, over HERE" left: the hint swells and bounces harder after a
## tap that landed nowhere.
var _nudge: float = 0.0
var _ring_tex: GradientTexture2D
var _arrow_tex: ImageTexture


func _ready() -> void:
	_ring_tex = _ring_texture()
	_arrow_tex = _arrow_texture()


## Lights a ring of `size` metres at each point. `ids` is what `pick_nearest`
## gives back; pass the same number of ids as points.
func show_at(points: Array[Vector3], ids: PackedInt32Array, size: float) -> void:
	clear_rings()
	for i in range(points.size()):
		var mi := _billboard(size)
		# IN THE TREE FIRST. A `Node3D` that is not yet in the tree has no global
		# transform, so writing `global_position` on it is silently dropped and the
		# ring lands at the origin, out in the road.
		add_child(mi)
		mi.global_position = points[i]
		_rings.append(mi)
		var arrow := _billboard(size * ARROW_OF_RING, _arrow_tex)
		add_child(arrow)
		arrow.global_position = points[i]
		arrow.visible = points.size() == 1
		_arrows.append(arrow)
		_points.append(points[i])
		_ids.append(ids[i] if i < ids.size() else i + 1)
		_take_t.append(-1.0)
	visible = not _rings.is_empty()


func clear_rings() -> void:
	for mi in _rings:
		if is_instance_valid(mi):
			mi.queue_free()
	for mi in _arrows:
		if is_instance_valid(mi):
			mi.queue_free()
	_rings.clear()
	_arrows.clear()
	_points.clear()
	_ids = PackedInt32Array()
	_take_t = PackedFloat32Array()
	_throb_i = -1
	_throb_t = 0.0
	_nudge = 0.0
	visible = false


## The ring carrying `id` was pressed: it snaps out over `TAKE_SECS` and stays
## out. The others are untouched.
func take(id: int) -> void:
	var i := index_of(id)
	if i < 0 or i >= _take_t.size():
		return
	_take_t[i] = TAKE_SECS


func is_taken(id: int) -> bool:
	var i := index_of(id)
	return i >= 0 and i < _take_t.size() and _take_t[i] >= 0.0


## How many rings are still drawn (the taken ones are not, once snapped).
func visible_count() -> int:
	var n := 0
	for mi in _rings:
		if is_instance_valid(mi) and mi.visible:
			n += 1
	return n


## A miss: the live ring nearest the finger throbs once, so the child is told
## "not there - HERE" by the right place.
func nudge_nearest(camera: Camera3D, screen: Vector2) -> void:
	if camera == null or _rings.is_empty():
		return
	var best := -1
	var best_d := INF
	for i in range(_rings.size()):
		if (i < _take_t.size() and _take_t[i] >= 0.0) or camera.is_position_behind(_points[i]):
			continue
		var d := camera.unproject_position(_points[i]).distance_to(screen)
		if d < best_d:
			best_d = d
			best = i
	if best >= 0:
		_throb_i = best
		_throb_t = THROB_SECS


func _set_alpha(mi: MeshInstance3D, a: float) -> void:
	var quad := mi.mesh as QuadMesh
	if quad == null:
		return
	var mat := quad.material as StandardMaterial3D
	if mat != null:
		mat.albedo_color = Color(GOLD.r, GOLD.g, GOLD.b, clampf(a, 0.0, 1.0))


## Shows ONE place, with the arrow over it: what the job points at when a beat
## has a single thing to press.
## `with_ring` false draws the ARROW only: a ring has meant "put your finger
## here" for every tap in the job, and a beat steered with the pads must not
## borrow it (round 3, the pour's hint).
func show_one(point: Vector3, size: float, with_ring: bool = true) -> void:
	show_at([point] as Array[Vector3], PackedInt32Array([1]), size)
	if not with_ring and not _rings.is_empty():
		_rings[0].visible = false


func one_up() -> bool:
	return _rings.size() == 1


## The HUD's white idle arrow stands in for the gold one while it is up: hide
## only the ARROW, never the ring (`SiteHud.hint_tick`).
func set_arrow_shown(on: bool) -> void:
	for a in _arrows:
		if is_instance_valid(a):
			a.visible = on and _rings.size() == 1


## Moves the ONE mark that is up. For a target that travels while it is being
## pointed at - the rubble a blade is pushing down the drive, the emptiest corner
## of a form that is filling - rebuilding the ring every frame would restart its
## pulse and its bob on every one of them.
func move_one(point: Vector3) -> void:
	if _rings.size() != 1:
		return
	_points[0] = point
	_rings[0].global_position = point


## A tap that landed nowhere: the one mark that is up throbs once, so a miss
## is answered rather than ignored. (`seconds` is kept for the callers; the
## throb has its own length.)
func nudge(_seconds: float) -> void:
	if _rings.is_empty():
		return
	_throb_i = 0
	_throb_t = THROB_SECS


func nudging() -> bool:
	return _throb_t > 0.0


func count() -> int:
	return _rings.size()


func lit() -> bool:
	return not _rings.is_empty()


## Where ring `i` is, and which id it carries.
func point_at(i: int) -> Vector3:
	return _points[i] if i >= 0 and i < _points.size() else Vector3.INF


func id_at(i: int) -> int:
	return _ids[i] if i >= 0 and i < _ids.size() else 0


## Every ring's world point, for a caller that wants to project them itself.
func points() -> Array[Vector3]:
	return _points


## The id of the ring nearest `screen`, or 0 when the nearest is further than
## `reach` pixels from it. The camera is the live one, so this is the question the
## child's finger really asks.
## `include_taken` lets a caller ask whether a finger is on a ring that is
## already being worked (a mash), which is not a miss. `world_reach` (metres)
## caps the pixel reach at what that distance covers on the screen AT THE
## RING, floored at `min_reach` pixels: the same generous finger on every
## shot, but never a whole slab of it on the wide.
func pick_nearest(camera: Camera3D, screen: Vector2, reach: float, include_taken: bool = false,
		world_reach: float = 0.0, min_reach: float = 0.0) -> int:
	if camera == null:
		return 0
	var best := 0
	var best_d := reach
	for i in range(_points.size()):
		if camera.is_position_behind(_points[i]):
			continue
		if not include_taken and i < _take_t.size() and _take_t[i] >= 0.0:
			continue
		if world_reach > 0.0:
			var side := _points[i] + camera.global_transform.basis.x * world_reach
			var px := camera.unproject_position(_points[i]).distance_to(camera.unproject_position(side))
			var cap := maxf(px, min_reach)
			if camera.unproject_position(_points[i]).distance_to(screen) > cap:
				continue
		var d := camera.unproject_position(_points[i]).distance_to(screen)
		if d <= best_d:
			best_d = d
			best = _ids[i]
	return best


## Which ring carries `id`, or -1.
func index_of(id: int) -> int:
	for i in range(_ids.size()):
		if _ids[i] == id:
			return i
	return -1


func _process(delta: float) -> void:
	if _rings.is_empty():
		return
	_time += delta
	# Held at the same size on SCREEN however far away it is. A phase with ten
	# places has to be framed wide enough to show all ten, and the far end of a
	# nine-metre drive is three times the distance of the near end: without this
	# the stakes by the garage were eighteen pixels across and the ones at the kerb
	# were sixty. `billboard_keep_scale` does not do this - it only stops a node's
	# own scale being thrown away - so the distance has to be measured.
	_throb_t = maxf(_throb_t - delta, 0.0)
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	for i in range(_rings.size()):
		# Each ring breathes a little out of step with its neighbours, so a set of
		# three reads as three things rather than as one flashing shape.
		var pulse := 1.0 + 0.13 * sin(_time * 5.0 + float(i) * 1.7)
		var fit := 1.0
		if cam != null:
			fit = clampf(cam.global_position.distance_to(_points[i]) / NOMINAL_M, 0.5, 3.0)
		var extra := 1.0
		if i == _throb_i and _throb_t > 0.0:
			# One throb: out to 1.45x at the miss, easing back over the half second.
			var u := _throb_t / THROB_SECS
			extra = 1.0 + 0.45 * u * u
		if i < _take_t.size() and _take_t[i] >= 0.0:
			# Taken: out and gone in a blink, then not drawn.
			_take_t[i] = maxf(_take_t[i] - delta, 0.0)
			var u := 1.0 - _take_t[i] / TAKE_SECS
			extra = 1.0 + 0.6 * u
			_set_alpha(_rings[i], 1.0 - u)
			if _take_t[i] <= 0.0:
				_rings[i].visible = false
				if i < _arrows.size():
					_arrows[i].visible = false
		_rings[i].scale = Vector3.ONE * pulse * fit * extra
		if i >= _arrows.size() or not _arrows[i].visible:
			continue
		# The arrow hangs over the ring and bobs DOWN toward it and back - it is
		# saying "this one", so its travel has to be toward the thing, not across
		# it. One smooth fall and rise, never a jab.
		var bob := 0.5 - 0.5 * cos(_time * BOB_HZ * TAU)
		var lift := (ARROW_LIFT - ARROW_DIP * bob) * fit * RING_SIZE_AT(_rings[i])
		_arrows[i].global_position = _points[i] + Vector3(0.0, lift, 0.0)
		_arrows[i].scale = Vector3.ONE * fit * (1.0 + 0.4 * (extra - 1.0))


## The ring's own drawn size, which the arrow's lift is measured in - so the
## arrow rides the same height over a big ring as over a small one.
static func RING_SIZE_AT(ring: MeshInstance3D) -> float:
	var quad := ring.mesh as QuadMesh
	return quad.size.y if quad != null else 0.5


func _billboard(size: float, tex: Texture2D = null) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Never hidden by the thing it is marking: a ring on a stake head behind a
	# form board is exactly when a child needs to see it.
	mat.no_depth_test = true
	mat.disable_receive_shadows = true
	mat.albedo_texture = tex if tex != null else _ring_tex
	mat.albedo_color = GOLD
	quad.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Ring"
	mi.mesh = quad
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A fat arrow pointing DOWN, in the alpha channel - the same shape Tree Crew
## points with. Drawn here rather than kept as a file so the two games cannot
## drift apart, and so there is no import to go stale.
func _arrow_texture() -> ImageTexture:
	var size := 96
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 0.0))
	var s := float(size)
	for y in range(size):
		for x in range(size):
			var px := (float(x) + 0.5) / s
			var py := (float(y) + 0.5) / s
			var shaft := absf(px - 0.5) < 0.14 and py > 0.06 and py < 0.56
			# The head: a triangle from y 0.52 (widest) down to the point at 0.96.
			var k := (py - 0.52) / 0.44
			var head := py >= 0.52 and py <= 0.96 and absf(px - 0.5) < 0.37 * (1.0 - k)
			if shaft or head:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(img)


## A soft ring in the alpha channel: transparent in the middle, so what is being
## pointed at is not covered up by the thing pointing at it.
func _ring_texture() -> GradientTexture2D:
	var tex := GradientTexture2D.new()
	tex.width = 96
	tex.height = 96
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.56, 0.64, 0.80, 0.90, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0),
	])
	tex.gradient = grad
	return tex
