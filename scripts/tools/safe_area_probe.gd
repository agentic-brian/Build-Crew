extends Node
## Is everything a finger needs out from under the notch? (the improvement
## plan's 6.4, part 3.)
##
## Headless, with the canvas named:
##
##   --headless --path . res://scenes/dev/safe_area_probe.tscn -- --canvas=1565x720
##   --headless --path . res://scenes/dev/safe_area_probe.tscn -- --canvas=1280x960 --device=ipad
##
## or in a WINDOW the shape of the device, which is what a person should look at:
##
##   --path . --resolution 1565x720 res://scenes/dev/safe_area_probe.tscn
##   --path . --resolution 1280x960 res://scenes/dev/safe_area_probe.tscn -- --device=ipad
##
## A desktop has no notch, so `SafeArea` is handed a real device's numbers
## instead: an iPhone 17 Pro in landscape (the Dynamic Island taking 62 pt off
## both sides, the home indicator 21 pt off the bottom) or, with
## `--device=ipad`, an 11-inch iPad Pro (no island, 20 pt of indicator). Then
## both screens are stood up and every control a finger reaches for is asked to
## lie inside the safe rectangle - the title row and its discs and cog, and the
## job's house, GO, NEXT, bar, four steering pads and cog. With no device
## standing in, every one of them has to be EXACTLY where it always was.
##
## GO and NEXT are measured with their halo (`PulseRing` grows the button by
## 0.22 of its size): the halo is drawn, so the halo is the control.
##
## What this probe cannot fix, and says so: the gold ring and the white arrow
## the job points with are 3D (`SpotRings`), not Controls. No inset moves them.
## If a beat's ring lands in the outer band on a phone, the camera shot is the
## only cure.
##
## Prints one line per check, then SAFE_AREA PASS n/n, and exits 0 / 1.

## iPhone 17 Pro, landscape, 3x: a 2622 x 1206 px window, the housing taking
## 186 px off each side and the home indicator 63 px off the bottom.
const PHONE_WIN := Vector2i(2622, 1206)
const PHONE_SAFE := Rect2i(186, 0, 2250, 1143)
## iPad Pro 11-inch, landscape, 2x: 2388 x 1668 px, 40 px of home indicator.
const IPAD_WIN := Vector2i(2388, 1668)
const IPAD_SAFE := Rect2i(0, 0, 2388, 1628)
## How much of its own size GO's halo adds all round (`SiteHud.PulseRing`).
const HALO := 0.22

var _checks: int = 0
var _failures: int = 0
var _device: String = "iphone"
var _canvas := Vector2i(1280, 720)
var _insets := Vector4.ZERO


func _ready() -> void:
	# The settings panel pauses the tree; the probe has to keep going.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--device="):
			_device = a.substr(9)
		elif a.begins_with("--canvas="):
			var bits := a.substr(9).split("x", false)
			if bits.size() == 2:
				_canvas = Vector2i(int(bits[0]), int(bits[1]))
	SaveGame.enabled = false
	Settings.motion_override = -1
	_run.call_deferred()


func _run() -> void:
	# A windowed run is given its shape on the command line and the engine eats
	# `--resolution` before a script sees it; only a headless run needs a stamp.
	if DisplayServer.get_name() == "headless":
		get_window().size = _canvas
	await get_tree().process_frame
	var frame := get_viewport().get_visible_rect().size
	print("SAFE_AREA start device=%s canvas=%dx%d" % [_device, int(frame.x), int(frame.y)])
	_check_maths(frame)
	# 1. With no device standing in, nothing has moved from where it always was.
	SafeArea.probe_active = false
	await _desktop_unchanged()
	# 2. And with one, everything a finger reaches for is inside the safe rect.
	var win := IPAD_WIN if _device == "ipad" else PHONE_WIN
	var safe_px := IPAD_SAFE if _device == "ipad" else PHONE_SAFE
	var k := frame.y / float(win.y)
	var right_px := float(win.x - safe_px.position.x - safe_px.size.x)
	var bottom_px := float(win.y - safe_px.position.y - safe_px.size.y)
	_insets = Vector4(float(safe_px.position.x) * k, float(safe_px.position.y) * k, right_px * k, bottom_px * k)
	print("  insets (left, top, right, bottom) = %s units" % _insets)
	SafeArea.probe_insets = _insets
	SafeArea.probe_active = true
	await _title_inside(frame)
	await _job_inside(frame)
	SafeArea.probe_active = false
	SaveGame.enabled = true
	print("SAFE_AREA %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


## The arithmetic on its own, against Apple's documented numbers, before any
## scene is built - and that a desktop really reports nothing.
func _check_maths(frame: Vector2) -> void:
	_check(SafeArea.insets(get_viewport()) == Vector4.ZERO,
		"a desktop has no notch: the insets are zero until a device stands in")
	var got := SafeArea.insets_for(frame, PHONE_WIN, PHONE_SAFE)
	var want_left := 186.0 * frame.x / float(PHONE_WIN.x)
	_check(absf(got.x - want_left) < 0.01 and absf(got.z - want_left) < 0.01 and got.y == 0.0,
		"an iPhone in landscape is inset the same on both sides (%.1f units, want %.1f)" % [got.x, want_left])
	var flat := SafeArea.insets_for(frame, IPAD_WIN, IPAD_SAFE)
	_check(flat.x == 0.0 and flat.z == 0.0 and flat.w > 0.0,
		"an iPad has no island and a home indicator (%s)" % str(flat))


# --- Nothing moved on a desktop -----------------------------------------------------------------

func _desktop_unchanged() -> void:
	var site := await _site()
	var hud := site.hud as SiteHud
	hud.show_home()
	hud.show_next()
	hud.show_pads(["up", "down", "left", "right"])
	await _frames(2)
	var margin: float = hud.corner_margin
	var go := _box(hud._go)
	var home := _box(hud._home)
	var up := _box(hud._pads.get("up"))
	var bar := _box(hud._bar)
	var frame := get_viewport().get_visible_rect().size
	_check(absf(go.position.x - margin) < 0.01, "with no notch GO is exactly where it always was (%.1f, want %.1f)" % [go.position.x, margin])
	_check(absf((frame.x - home.end.x) - hud.corner_button_margin) < 0.01,
		"and the house (%.1f from the right, want %.1f)" % [frame.x - home.end.x, hud.corner_button_margin])
	_check(absf(up.position.x - hud.pad_margin) < 0.01, "and the pads (%.1f, want %.1f)" % [up.position.x, hud.pad_margin])
	_check(absf(bar.position.y - 26.0) < 0.01, "and the bar (%.1f, want 26)" % bar.position.y)
	await _free(site)


# --- The title row --------------------------------------------------------------------------------

func _title_inside(frame: Vector2) -> void:
	var title := await _title()
	var menu := title.menu() as StartMenu
	menu.set_mode(true)
	await _frames(2)
	var safe := _safe_rect(frame)
	for i in range(menu.row_rects().size()):
		_inside(safe, menu.row_rects()[i], "the job's disc %d" % (i + 1))
	_inside(safe, menu.fresh_rect(), "the 'new drive' disc")
	var settings := title.get_node_or_null("Settings")
	if settings != null:
		_inside(safe, _box(settings.get("_opener")), "the settings cog on the title")
		settings.call("open")
		await _frames(3)
		for want: String in ["Volume", "MusicToggle", "Done", "Privacy"]:
			var c := settings.get("_panel").get_node_or_null(want) as Control
			if c != null:
				_inside(safe, _box(c), "the panel's %s" % want.to_lower())
		settings.call("close")
	await _free(title)


# --- The job ---------------------------------------------------------------------------------------

func _job_inside(frame: Vector2) -> void:
	var site := await _site()
	var hud := site.hud as SiteHud
	# Called up directly rather than played for: every one of these is on the
	# screen at some point in the job.
	hud.show_home()
	hud.show_next()
	hud.arm_button("call")
	hud.show_pads(["up", "down", "left", "right"])
	await _frames(3)
	var safe := _safe_rect(frame)
	_inside(safe, _box(hud._home), "the house")
	_inside(safe, _box(hud._bar), "the bar")
	for key: String in ["up", "down", "left", "right"]:
		_inside(safe, _box(hud._pads.get(key)), "the %s pad" % key)
	# GO and NEXT with the HALO they are drawn with.
	for pair in [[hud._go, "GO"], [hud._next, "NEXT"]]:
		var b := _box(pair[0] as Control)
		_inside(safe, b.grow(b.size.x * HALO), "%s, halo and all" % pair[1])
	var settings := site.get_node_or_null("Settings")
	if settings != null:
		_inside(safe, _box(settings.get("_opener")), "the settings cog in the job")
	await _free(site)


# --- Plumbing ------------------------------------------------------------------------------------

func _safe_rect(frame: Vector2) -> Rect2:
	var ins := SafeArea.insets(get_viewport())
	return Rect2(Vector2(ins.x, ins.y), frame - Vector2(ins.x + ins.z, ins.y + ins.w))


func _inside(safe: Rect2, box: Rect2, what: String) -> void:
	var over := ""
	if box.position.x < safe.position.x - 0.01:
		over = "%.1f off the left" % (safe.position.x - box.position.x)
	elif box.end.x > safe.end.x + 0.01:
		over = "%.1f off the right" % (box.end.x - safe.end.x)
	elif box.position.y < safe.position.y - 0.01:
		over = "%.1f off the top" % (safe.position.y - box.position.y)
	elif box.end.y > safe.end.y + 0.01:
		over = "%.1f off the bottom" % (box.end.y - safe.end.y)
	_check(over == "", "%s is clear of the hardware (%s)" % [what, over if over != "" else str(box)])


## A control's laid-out box, before any scale it is animating: GO sleeps at half
## size in the same place, and every button pops in from nothing.
func _box(c: Variant) -> Rect2:
	var ctl := c as Control
	if ctl == null:
		return Rect2()
	var origin := Vector2.ZERO
	var parent := ctl.get_parent() as Control
	if parent != null:
		origin = parent.get_global_rect().position
	return Rect2(origin + ctl.position, ctl.size)


func _title() -> TitleMain:
	var inst := (load("res://scenes/main.tscn") as PackedScene).instantiate() as TitleMain
	add_child(inst)
	await _frames(3)
	return inst


func _site() -> SiteMain:
	Engine.set_meta("shot_args", {"stage": "rebar"})
	var inst := (load("res://scenes/site.tscn") as PackedScene).instantiate() as SiteMain
	add_child(inst)
	await _frames(3)
	Engine.remove_meta("shot_args")
	return inst


func _free(n: Node) -> void:
	n.queue_free()
	await _frames(3)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])
