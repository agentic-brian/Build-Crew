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
	# Pinned before the level is built, like every other probe: a scene raised on
	# a developer's machine with Reduce Motion on must not be a different scene.
	Settings.motion_override = -1
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
## whole jackhammer bite - and a camera caught MID-WOBBLE is put back level.
##
## That last half is the one `camera_shake.gd` is written a particular way for:
## its `_process` zeroes the trauma and FALLS THROUGH to the branch that restores
## the basis, instead of returning early. So this has to catch the camera while
## it is actually rolled, and the old check could not: it sampled the basis
## BEFORE any shake, and compared `basis.z` - the axis a roll about FORWARD
## leaves exactly where it was. It read 0.00000 whatever the camera did.
func _it_holds_still() -> void:
	Settings.motion_override = -1
	var clean: Basis = _site.camera._base_basis
	_site.shake(0.30)
	_site.shake_floor(0.28)
	# The precondition, established rather than hoped for: the noise is sampled
	# over twenty frames, because at any one instant it can pass through zero.
	var rolled := 0.0
	for i in range(20):
		await get_tree().process_frame
		rolled = maxf(rolled, (_site.camera.transform.basis.x - clean.x).length())
	_check(rolled > 0.0005, "the picture really is rolling before the switch is asked (%.5f)" % rolled)
	# Thrown mid-wobble, with the floor still held down.
	Settings.motion_override = 1
	var peak := await _camera_peak(30)
	_check(peak == 0.0, "with it on, neither a kick nor a rattle moves the picture (%.4f)" % peak)
	var tilt := (_site.camera.transform.basis.x - clean.x).length()
	_check(tilt < 0.0001 and _site.camera.h_offset == 0.0 and _site.camera.v_offset == 0.0,
		"and the camera it caught mid-wobble is put back level (%.5f, offsets %.4f/%.4f)"
			% [tilt, _site.camera.h_offset, _site.camera.v_offset])
	_site.shake_floor(0.0)


## And the game still answers a finger: the rings, the buttons, the tools and
## the work itself.
func _the_world_still_moves() -> void:
	Settings.motion_override = 1
	var hud := _site.hud as SiteHud
	# Called straight, not behind `has_method`: a fallback of 0 and 1 makes this
	# read `1 > 0` for a HUD that draws no ring at all, and a rename would pass.
	var rings := hud.rings_played()
	hud.tap_ring(Vector2(400.0, 300.0))
	await _frames(2)
	_check(hud.rings_played() > rings, "a tap still draws its own ring")
	# GO has to be awake to kick: it sleeps hidden through the hammer's row.
	hud.arm_button("call")
	await _frames(2)
	hud.nudge_button()
	await _frames(2)
	var go := hud._go as Control
	_check(go != null and absf(go.scale.x - 1.0) > 0.001, "a button still kicks when it is pointed at (%.3f)" % go.scale.x)
	# The gold rings BREATHE, and that is what has to be measured: the pulse is
	# written onto each ring CHILD (`_rings[i].scale`), so the container's own
	# scale - which the old check sampled, and then threw away - is a constant,
	# and `lit()` is a count of rings, not a motion. Put an early
	# `if Settings.motion_reduced(): return` at the top of `SpotRings._process`
	# and both of these go red, which is the whole point of the check.
	var spot := _site.get_node_or_null("Rings") as SpotRings
	_check(spot != null and spot.lit(), "there are gold rings up to measure")
	if spot != null and spot.lit():
		var ring := spot._rings[0] as MeshInstance3D
		var t0: float = spot._time
		var lo: float = ring.scale.x
		var hi := lo
		for i in range(60):
			await get_tree().process_frame
			lo = minf(lo, ring.scale.x)
			hi = maxf(hi, ring.scale.x)
		_check(spot._time > t0, "the rings' own clock is still running under the switch")
		_check(hi - lo > 0.000001,
			"and WHERE TO TAP never freezes: the ring is still breathing (%.6f)" % (hi - lo))
	# The work itself: a bite still breaks concrete, with the camera still.
	var panel := _site.drive.panels_broken()
	var spots := _site.drive.open_spots(_site.drive.current_panel())
	_site.drive.jack_spot(spots[0], 1.0)
	await _frames(2)
	_check(_site.drive.spot_done(spots[0]) and _site.drive.panels_broken() == panel,
		"and the concrete still gives way under the hammer")


## The flag is one place, and the camera asks nobody else.
func _source_check() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/camera_shake.gd")
	_check(not src.contains("DisplayServer."),
		"the camera asks `Settings.motion_reduced()`, never the OS itself - so a harness can decide it")
	# "Asked once, then remembered" cannot be tested by calling one pure function
	# twice - that is true whether the memo exists or not, and with an override
	# set neither call reaches the OS at all. The memo itself is the thing under
	# test, so the memo is what is poked.
	Settings.motion_override = 0
	Settings.forget_motion()
	var first := Settings.motion_reduced()
	_check(Settings._motion_known, "with no override, the OS is asked - and the answer is kept")
	_check(Settings._motion == first, "and what it answered is what was kept (%s)" % first)
	Settings._motion = not first
	_check(Settings.motion_reduced() == (not first),
		"the second ask is the memory, never the OS again")
	Settings.forget_motion()
	_check(not Settings._motion_known,
		"and `forget_motion()` is what makes it ask again - the hook a resumed app pulls")
	Settings.motion_override = -1


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
