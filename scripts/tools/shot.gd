extends Node
## Screenshot harness for runs with no human at the keyboard.
## Usage: godot --path <proj> --resolution 1280x720 res://scenes/dev/shot.tscn -- \
##          --scene=res://scenes/main.tscn --out=C:/tmp/a.png --frames=30 [--wait=1.5]
##
## Loads the target scene, lets it settle for `frames` rendered frames (plus an
## optional real-time `wait`), grabs the viewport, writes a PNG, then quits.
## Extra `--key=value` args are forwarded to the loaded scene through
## Engine metadata "shot_args" so a shot can request a specific game state.

var _out: String = "shot.png"
var _frames: int = 30
var _wait: float = 0.0
var _scene_path: String = ""


func _ready() -> void:
	var argv := OS.get_cmdline_user_args()
	var extra := {}
	for a in argv:
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--frames="):
			_frames = int(a.substr(9))
		elif a.begins_with("--wait="):
			_wait = float(a.substr(7))
		elif a.begins_with("--scene="):
			_scene_path = a.substr(8)
		elif a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			extra[kv[0]] = kv[1] if kv.size() > 1 else true
	Engine.set_meta("shot_args", extra)
	# `--safe=iphone|ipad` stands a real device's hardware in front of the
	# screen, so a windowed frame shows the phone's layout and not the desktop's
	# (`SafeArea` reports nothing off a device). The numbers are the probe's.
	if extra.has("safe"):
		var frame := Vector2(get_viewport().get_visible_rect().size)
		var ipad := str(extra["safe"]) == "ipad"
		var win := Vector2i(2388, 1668) if ipad else Vector2i(2622, 1206)
		var safe := Rect2i(0, 0, 2388, 1628) if ipad else Rect2i(186, 0, 2250, 1143)
		SafeArea.probe_insets = SafeArea.insets_for(frame, win, safe)
		SafeArea.probe_active = true
	# Not the child's game: no save is read, written or deleted, and the child's
	# settings file is left alone (`Settings.persists`). A picture taken on a dev
	# machine with a job half done must not come out as that job (the plan's 6.2).
	SaveGame.enabled = false
	# Nor the developer's accessibility settings: with Reduce Motion on, every
	# frame this harness takes comes out of a game whose camera never shakes,
	# and the difference is invisible in the PNG. Pinned off, like the probes.
	Settings.motion_override = -1
	if _scene_path == "":
		push_error("shot.gd: no --scene= given")
		get_tree().quit(2)
		return
	var packed: PackedScene = load(_scene_path)
	if packed == null:
		push_error("shot.gd: could not load %s" % _scene_path)
		get_tree().quit(3)
		return
	add_child(packed.instantiate())
	# Nothing reaches the level but its own args: a stray click on the capture
	# window once played a blow on a posed stake, and the frame showed a state
	# the pose never makes (session 4's verification pass). `--tap` and `--hold`
	# call the runner directly, not through input.
	get_viewport().set_disable_input(true)
	_capture.call_deferred()


func _capture() -> void:
	for i in range(maxi(_frames, 2)):
		await RenderingServer.frame_post_draw
	if _wait > 0.0:
		await get_tree().create_timer(_wait).timeout
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := _out.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var err := img.save_png(_out)
	if err != OK:
		push_error("shot.gd: save_png failed %d -> %s" % [err, _out])
		get_tree().quit(4)
		return
	print("SHOT_OK %s %dx%d" % [_out, img.get_width(), img.get_height()])
	get_tree().quit(0)
