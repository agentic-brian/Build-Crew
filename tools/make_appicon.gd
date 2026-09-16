extends SceneTree
## Builds the app icon at every size iOS asks for (the improvement plan's 6.4,
## part 4): `assets/brand/appicon/icon_<n>.png`.
##
##   godot --headless --path . -s tools/make_appicon.gd
##
## The picture is the SKID STEER WEARING ITS PUSH BLADE - `MachineIcons.spec`'s
## own "skid", the same machine the title row seats and the call button answers,
## rendered from the same GLB the game plays with. Not a drawing of a machine:
## a drawing would be the one picture in this family that the game itself cannot
## make, and it would drift the first time the model changed.
##
## No words, because nothing in this game shows a child words - and an icon is
## the first thing a child sees. The name is the App Store's job.
##
## It is drawn ORTHOGRAPHIC, like every other icon here: at 40 px a model in
## perspective LEANS, and the lean reads as a mistake. Full bleed, square, no
## alpha and no rounded corners - iOS rounds it itself, and an icon that rounds
## its own corners gets rounded twice.

const OUT_DIR := "res://assets/brand/appicon/"
## Every size the iOS preset names, plus the 1024 the App Store takes.
const SIZES: Array[int] = [40, 58, 60, 76, 80, 87, 114, 120, 128, 136, 152, 167,
	180, 192, 1024]
## Rendered once at four times the largest, then reduced with Lanczos: a 40 px
## icon drawn at 40 px is a mess of aliased edges.
const MASTER := 2048

## The ground the machine stands on: the family's cream, which every screen in
## this game already opens on.
const GROUND := Color(1.0, 0.953, 0.808)
## The frame, a band of the family's orange all round the square.
const FRAME := Color(0.957, 0.604, 0.196)
## How much of the square's side the frame band takes, each edge.
const FRAME_K := 0.055


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(MASTER, MASTER)
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.own_world_3d = true
	view.world_3d = World3D.new()
	root.add_child(view)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = GROUND
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.88, 0.95)
	env.ambient_light_energy = 0.55
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.environment = env
	view.add_child(cam)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.5
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(38.0), 0.0)
	view.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.rotation = Vector3(deg_to_rad(-18.0), deg_to_rad(-135.0), 0.0)
	view.add_child(fill)

	var spec: Dictionary = MachineIcons.spec("skid")
	var stage := Node3D.new()
	view.add_child(stage)
	var body := _instance(str(spec.get("model", "")))
	if body == null:
		push_error("make_appicon: cannot load %s" % str(spec.get("model", "")))
		quit(1)
		return
	stage.add_child(body)
	# The blade goes on the bucket's own mount, the way the machine wears it in
	# play - so a rebuilt SkidSteer.glb moves the icon with it.
	for a: Dictionary in (spec.get("attach", []) as Array):
		var host := body.find_child(str(a.get("under", "")), true, false) as Node3D
		var att := _instance(str(a.get("model", "")))
		if host != null and att != null:
			host.add_child(att)
	for node_name: String in (spec.get("pose", {}) as Dictionary):
		var n := body.find_child(node_name, true, false) as Node3D
		if n != null:
			var d: Vector3 = spec["pose"][node_name]
			n.rotation += Vector3(deg_to_rad(d.x), deg_to_rad(d.y), deg_to_rad(d.z))
	await process_frame
	await process_frame

	# Framed on the machine's own corners, turned the way the title row turns it.
	var box := _world_box(stage)
	var yaw: float = float(spec.get("yaw", -0.8))
	var pitch: float = float(spec.get("pitch", 0.25))
	var dir := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -pitch) * Vector3.BACK
	var centre := box.get_center()
	cam.global_transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), centre + dir * (box.size.length() + 4.0))
	# The picture fills the square inside the frame band, with a hair of air.
	var reach := 0.0
	for i in range(8):
		var c := box.get_endpoint(i)
		var local := cam.global_transform.affine_inverse() * c
		reach = maxf(reach, maxf(absf(local.x), absf(local.y)))
	cam.size = reach * 2.0 / (1.0 - FRAME_K * 2.0) * 1.06
	await process_frame
	await RenderingServer.frame_post_draw

	var shot := view.get_texture().get_image()
	shot.convert(Image.FORMAT_RGBA8)
	# The orange frame, painted over the render's edges rather than scaled into
	# it, so its width is exact at every size.
	var band := int(round(float(MASTER) * FRAME_K))
	_frame_edges(shot, band, FRAME)

	var dir_abs := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(dir_abs)
	var made := 0
	for s: int in SIZES:
		var out := shot.duplicate() as Image
		out.resize(s, s, Image.INTERPOLATE_LANCZOS)
		# Opaque, always: an icon with alpha is rejected.
		out.convert(Image.FORMAT_RGB8)
		var path := dir_abs.path_join("icon_%d.png" % s)
		if out.save_png(path) != OK:
			push_error("make_appicon: cannot write %s" % path)
			quit(2)
			return
		made += 1
	print("MAKE_APPICON wrote %d icons to %s (master %d, frame %d px)" % [made, OUT_DIR, MASTER, band])
	quit(0)


## Paints a band of `c` round all four edges of `img`.
func _frame_edges(img: Image, band: int, c: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		var edge_y := y < band or y >= h - band
		for x in range(w):
			if edge_y or x < band or x >= w - band:
				img.set_pixel(x, y, c)


func _instance(path: String) -> Node3D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path)
	return packed.instantiate() as Node3D if packed != null else null


## Every drawn vertex of `root`, in world space.
func _world_box(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
