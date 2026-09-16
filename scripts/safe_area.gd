class_name SafeArea
extends RefCounted
## The part of the screen no notch, Dynamic Island, rounded corner or home
## indicator is sitting on, measured in the units a Control's offsets are
## written in (DESIGN 32).
##
## Tree Crew's (its commit 205b6e1), where it was found: every HUD put its
## corner buttons a flat 18-22 units from the edge of the VIEWPORT. On the
## 1280x720 design stretched to a phone in landscape, one unit is about 0.56 pt,
## so 18 units is 10 pt - and the sensor housing takes the outer 59 to 62 pt of
## the leading AND trailing edges (`orientation=4` is sensor-landscape, and iOS
## insets landscape symmetrically), with the home indicator taking about 21 pt
## off the bottom. Here that band held the house, the settings cog, the LIFT /
## NEXT / key corner, the work order's three discs and the privacy link.
##
## Everything placed against an edge asks here; it returns zero on anything
## without a notch - every desktop, the editor, a test - so a screen that asks
## unconditionally lays out exactly as it always did.

## A stand-in for a phone, so the screens can be measured on a desktop.
##
## `scenes/dev/safe_area_probe.tscn` sets this and nothing else ever does. A
## check that only runs on the hardware it is testing cannot gate anything, and
## this bug shipped in Tree Crew's first build precisely because no desktop run
## could see it.
static var probe_insets := Vector4.ZERO
static var probe_active := false


## The insets as (left, top, right, bottom), in viewport units.
static func insets(vp: Viewport) -> Vector4:
	if probe_active:
		return probe_insets
	if vp == null or not OS.has_feature("mobile"):
		return Vector4.ZERO
	return insets_for(vp.get_visible_rect().size, DisplayServer.window_get_size(),
			DisplayServer.get_display_safe_area())


## The arithmetic on its own, so the probe can hand it a phone's numbers from a
## desktop and check the answer.
static func insets_for(canvas: Vector2, win: Vector2i, safe: Rect2i) -> Vector4:
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	# The window is in pixels and the Control is in stretched canvas units; one
	# ratio per axis converts between them under `canvas_items` + `expand`.
	var k := Vector2(canvas.x / float(win.x), canvas.y / float(win.y))
	var left := maxf(0.0, float(safe.position.x))
	var top := maxf(0.0, float(safe.position.y))
	var right := maxf(0.0, float(win.x) - float(safe.position.x + safe.size.x))
	var bottom := maxf(0.0, float(win.y) - float(safe.position.y + safe.size.y))
	return Vector4(left * k.x, top * k.y, right * k.x, bottom * k.y)


## The frame with the insets taken off: the rectangle a control has to stay in.
static func rect(vp: Viewport) -> Rect2:
	if vp == null:
		return Rect2()
	var frame := vp.get_visible_rect().size
	var i := insets(vp)
	return Rect2(Vector2(i.x, i.y), frame - Vector2(i.x + i.z, i.y + i.w))
