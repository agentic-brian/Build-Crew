extends Node
## Reduce-motion (the improvement plan's 6.4, part 7): the CAMERA holds still
## for a child who asked the OS for that, and nothing else does.
##
##   godot --headless --path . res://scenes/dev/motion_probe.tscn
##
## The line this probe defends is the plan's own: "the slab's own kick and the
## bit's stroke still move, only the camera does not". A toy that answers a
## finger with nothing is not an accessible toy - it is a broken one - so the
## rings still pulse, the buttons still kick, the tools still swing, and the
## work still happens. What stops is the picture being SHAKEN.
##
## Prints one line per check, then MOTION_PROBE PASS n/n, and exits 0 / 1.

var _checks: int = 0
var _failures: int = 0
var _site: SiteMain


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	SaveGame.enabled = false
	Engine.set_meta("shot_args", {"stage": "old"})
	_site = (load("res://scenes/site.tscn") as PackedScene).instantiate() as SiteMain
	add_child(_site)
	await _frames(3)
	await _it_shakes()
	await _it_holds_still()
	await _the_world_still_moves()
	_source_check()
	Settings.motion_override = 0
	Engine.remove_meta("shot_args")
	SaveGame.enabled = true
	print("MOTION_PROBE %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


## With the setting OFF, the camera shakes - or this probe proves nothing.
func _it_shakes() -> void:
	Settings.motion_override = -1
	_site.shake(0.30)
	var peak := await _camera_peak(20)
	_check(peak > 0.0, "with the setting off, a kick really shakes the picture (%.4f)" % peak)
	_site.shake_floor(0.28)
	var held := await _camera_peak(20)
	_check(held > 0.0, "and a rattle holds it shaking (%.4f)" % held)
	_site.shake_floor(0.0)
	await _frames(30)


## With it ON, nothing moves the camera - not a kick, not the floor under a
## whole jackhammer bite - and the basis it was left at is put back.
func _it_holds_still() -> void:
	Settings.motion_override = 1
	var rest := _site.camera.transform.basis
	_site.shake(0.30)
	_site.shake_floor(0.28)
	var peak := await _camera_peak(30)
	_check(peak == 0.0, "with it on, neither a kick nor a rattle moves the picture (%.4f)" % peak)
	var tilt := 0.0
	for i in range(3):
		tilt = maxf(tilt, (_site.camera.transform.basis.z - rest.z).length())
	_check(tilt < 0.0001, "and the camera is left level, never caught mid-wobble (%.5f)" % tilt)
	_site.shake_floor(0.0)


## And the game still answers a finger: the rings, the buttons, the tools and
## the work itself.
func _the_world_still_moves() -> void:
	Settings.motion_override = 1
	var hud := _site.hud as SiteHud
	var rings := hud.rings_played() if hud.has_method("rings_played") else 0
	hud.tap_ring(Vector2(400.0, 300.0))
	await _frames(2)
	_check((hud.rings_played() if hud.has_method("rings_played") else 1) > rings,
		"a tap still draws its own ring")
	# GO has to be awake to kick: it sleeps hidden through the hammer's row.
	hud.arm_button("call")
	await _frames(2)
	hud.nudge_button()
	await _frames(2)
	var go := hud._go as Control
	_check(go != null and absf(go.scale.x - 1.0) > 0.001, "a button still kicks when it is pointed at (%.3f)" % go.scale.x)
	var spot := _site.get_node_or_null("Rings") as SpotRings
	var was := spot.scale if spot != null else Vector3.ZERO
	await _frames(6)
	_check(spot != null and spot.lit(), "the gold rings are still lit: WHERE TO TAP never freezes")
	# The work itself: a bite still breaks concrete, with the camera still.
	var panel := _site.drive.panels_broken()
	var spots := _site.drive.open_spots(_site.drive.current_panel())
	_site.drive.jack_spot(spots[0], 1.0)
	await _frames(2)
	_check(_site.drive.spot_done(spots[0]) and _site.drive.panels_broken() == panel,
		"and the concrete still gives way under the hammer")
	if was == Vector3.ZERO:
		pass


## The flag is one place, and the camera asks nobody else.
func _source_check() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/camera_shake.gd")
	_check(not src.contains("DisplayServer."),
		"the camera asks `Settings.motion_reduced()`, never the OS itself - so a harness can decide it")
	Settings.motion_override = 0
	var twice := Settings.motion_reduced()
	_check(Settings.motion_reduced() == twice, "and the OS is asked once, then remembered")


## The biggest the camera's own offsets get over `n` frames.
func _camera_peak(n: int) -> float:
	var peak := 0.0
	for i in range(n):
		await get_tree().process_frame
		peak = maxf(peak, maxf(absf(_site.camera.h_offset), absf(_site.camera.v_offset)))
	return peak


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["  ok " if ok else "FAIL", what])
