class_name ToyHud
extends CanvasLayer
## Tree Chop's `GrindHud`, copied and renamed: touch controls for "the machine
## is the toy" levels, sized for small hands on an iPad:
##  * a two-button pad on the LEFT (up / down) and one on the RIGHT (left / right),
##    each a big round disc with a fat white arrow. They are press-and-hold and
##    handle real multi-touch themselves (a thumb on each pad at once), which
##    plain Buttons cannot do, and a thumb sliding off a pad lets go of it.
##  * the machine's own ignition key, big, in the bottom centre: the key IS the
##    button, standing on the grass with nothing painted behind it, and it turns
##    when tapped,
##  * a NEXT button (the universal "go on" triangle) once a stump is gone,
##  * a stump bar across the top that drains as the wood goes, and
##  * a YAY! banner. No words anywhere else, for pre-readers.

signal start_pressed
signal next_pressed
## The house in the top-right corner was tapped: back to the title screen.
signal home_pressed

## How far a controller stick has to lean along one axis before that pad lights
## up. `Pad.move()` has already thrown away a resting wobble, so this is only
## here so that a push straight up the screen does not also glow one of the
## sideways arrows on its way past.
const STICK_GLOW_POINT := 0.2

@export var pad_button_size: float = 150.0
@export var pad_margin: float = 44.0
@export var pad_gap: float = 18.0
@export var pad_color: Color = Color(0.24, 0.52, 0.92)
@export var start_size: float = 220.0
## The green of the NEXT disc and the house. The START control is NOT a disc:
## it is the machined key itself, so this colour no longer sits behind it.
@export var start_color: Color = Color(0.35, 0.75, 0.30)
## How much of the START button's LONGEST axis the machined key fills. It used
## to be held well back so that a ring of green showed all round it; with the
## disc gone there is nothing for the key to spill over, so it takes nearly the
## whole of that axis. Never above 1.0: past that the key's ink leaves the
## button's rect and there would be key on screen that a finger cannot press.
##
## The longest axis only, and there is no knob for the other one. Seen
## three-quarter on, the key is a good deal wider than it is tall, so inside a
## square button it fills the width and leaves a band of clear button above and
## below it. That band is the key's own shape and raising this will not close it
## - it only makes the key wider until it runs out of the rect. The band is not
## slack either: the button answers its whole square, so a thumb that lands
## above or below the key still turns it, which is exactly the forgiveness a
## four-year-old's aim needs.
@export var key_fill: float = 0.96
## How far the key sinks under a finger. The darkened disc used to be the answer
## to a press; this is. It is exactly what a steering pad does, so a thumb on the
## key and a thumb on an arrow get the same reply.
@export var key_press_scale: float = 0.92
## The key's own shadow: it stands above the clearing rather than being printed
## on it, the way every other button in the game does. All three are the round
## buttons' own shadow numbers (see `_round_style`), so the key carries the same
## weight as the NEXT button that takes its place in the same spot a moment
## later. Alpha 0 turns it off.
@export var key_shadow_offset: Vector2 = Vector2(0.0, 6.0)
@export var key_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.28)
## How far the shadow spreads past the key and fades out, pixels. This is the
## number that decides whether a shadow reads as a halo the thing is floating
## above or as a hard second copy of it printed behind: at 0 the key's shadow is
## its exact silhouette with a knife edge, which is what makes a control look
## flat beside its neighbours.
@export var key_shadow_size: float = 12.0
## Where the start / next button sits, as a fraction of the screen height.
@export var go_button_anchor_y: float = 0.80
@export var bar_size: Vector2 = Vector2(380.0, 26.0)
@export var flash_font_size: int = 96
@export var flash_top: float = 60.0
## The ring a tap leaves, the chop game's exactly, so a finger gets the same
## answer whichever of the toys it lands in.
@export var tap_ring_start_radius: float = 20.0
@export var tap_ring_end_radius: float = 70.0
@export var tap_ring_time: float = 0.18
@export var tap_ring_width: float = 7.0
@export var tap_ring_color: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var tap_ring_pool_size: int = 4
## The house: the same size, place and green as the chop game's corner buttons.
@export var corner_button_size: float = 92.0
@export var corner_button_margin: float = 18.0
@export var corner_button_color: Color = Color(0.36, 0.76, 0.32)

var _root: Control
var _pads: Dictionary = {}
var _pads_enabled: bool = false
var _rings: Array = []
var _ring_next: int = 0
var _rings_played: int = 0
var _start: Button
var _key: KeyIgnition
var _next: Button
var _home: Button
var _bar: ProgressBar
var _flash: Label
var _flash_tween: Tween
var _start_tween: Tween


func _ready() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_pads()
	_build_bar()
	_build_flash()
	_build_start()
	_build_next()
	_build_home()
	# Rings go in last, so a tap draws on top of everything else.
	_build_rings()
	set_pads_enabled(false)
	# Every corner control walks in off whatever the screen's own hardware takes
	# (6.4): a notch, an Island, a rounded corner, a home indicator. A phone
	# turned over, or a window resized, puts those edges somewhere else.
	place_in_safe_area()
	get_viewport().size_changed.connect(place_in_safe_area)


# --- Pads ----------------------------------------------------------------------------

func _build_pads() -> void:
	var s := pad_button_size
	var m := pad_margin
	var g := pad_gap
	# Left pad: up over down, in the bottom-left corner.
	_add_pad("up", PadButton.Arrow.UP, Vector4(0.0, 1.0, 0.0, 1.0), _pad_rect("up", m, m, m))
	_add_pad("down", PadButton.Arrow.DOWN, Vector4(0.0, 1.0, 0.0, 1.0), _pad_rect("down", m, m, m))
	# Right pad: left beside right, in the bottom-right corner.
	_add_pad("left", PadButton.Arrow.LEFT, Vector4(1.0, 1.0, 1.0, 1.0), _pad_rect("left", m, m, m))
	_add_pad("right", PadButton.Arrow.RIGHT, Vector4(1.0, 1.0, 1.0, 1.0), _pad_rect("right", m, m, m))


## Where one pad sits, as anchored offsets, given how far its own edges must
## stand off the screen's. Written once so `place_in_safe_area` can lay the same
## four pads again off the hardware's insets - the pour is the one beat that
## shows all four, and two of them sit under a phone's Island untouched.
func _pad_rect(key: String, m_left: float, m_right: float, m_bottom: float) -> Rect2:
	var s := pad_button_size
	var g := pad_gap
	match key:
		"up":
			return Rect2(m_left, -(m_bottom + 2.0 * s + g), s, s)
		"down":
			return Rect2(m_left, -(m_bottom + s), s, s)
		"left":
			return Rect2(-(m_right + 2.0 * s + g), -(m_bottom + s), s, s)
	return Rect2(-(m_right + s), -(m_bottom + s), s, s)


## Walks every corner control in off the screen's own hardware. Overridden by
## `SiteHud` for the two controls it adds (GO and NEXT share the pads' corner).
func place_in_safe_area() -> void:
	var safe := SafeArea.insets(get_viewport())
	if _home != null:
		var s := corner_button_size
		var right := corner_button_margin + safe.z
		var top := corner_button_margin + safe.y
		_home.offset_right = -right
		_home.offset_left = -right - s
		_home.offset_top = top
		_home.offset_bottom = top + s
	if _bar != null:
		_bar.offset_top = 26.0 + safe.y
		_bar.offset_bottom = 26.0 + safe.y + bar_size.y
	for key: String in ["up", "down", "left", "right"]:
		var pad := _pads.get(key) as Control
		if pad == null:
			continue
		var r := _pad_rect(key, pad_margin + safe.x, pad_margin + safe.z, pad_margin + safe.w)
		pad.offset_left = r.position.x
		pad.offset_top = r.position.y
		pad.offset_right = r.position.x + r.size.x
		pad.offset_bottom = r.position.y + r.size.y


func _add_pad(pad_name: String, arrow: PadButton.Arrow, anchors: Vector4, rect: Rect2) -> void:
	var pad := PadButton.new()
	pad.name = pad_name.capitalize()
	pad.arrow = arrow
	pad.color = pad_color
	pad.anchor_left = anchors.x
	pad.anchor_top = anchors.y
	pad.anchor_right = anchors.z
	pad.anchor_bottom = anchors.w
	pad.offset_left = rect.position.x
	pad.offset_top = rect.position.y
	pad.offset_right = rect.position.x + rect.size.x
	pad.offset_bottom = rect.position.y + rect.size.y
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pad)
	_pads[pad_name] = pad


## Whether a pad ("up", "down", "left", "right") is held right now.
func held(pad_name: String) -> bool:
	var pad: PadButton = _pads.get(pad_name)
	return pad != null and pad.held


## Pads answer fingers only while the engine runs; before that they are dimmed.
func set_pads_enabled(on: bool) -> void:
	_pads_enabled = on
	for pad: PadButton in _pads.values():
		pad.enabled = on
		if not on:
			pad.release_all()
			# A stick still leaning when the machine stops must not leave an
			# arrow lit over a dimmed pad.
			pad.set_lit(false)
		pad.modulate = Color(1.0, 1.0, 1.0, 1.0 if on else 0.4)
		pad.queue_redraw()


func pads_enabled() -> bool:
	return _pads_enabled


## Lets go of every finger the pads still think is down, and does nothing else.
##
## The sound settings panel freezes the whole tree while it is up, and a frozen
## tree is deaf to RELEASES as well as to presses. A thumb resting on an arrow
## when the settings cog is tapped, lifted while the panel is open, is a
## release these pads never hear: `_pointers` still holds it, `held()` still
## answers true, and the machine drives off on its own as soon as the panel
## closes, with nothing on the screen touched.
##
## It has to be its own door. `set_pads_enabled(false)` then `(true)` does clear
## the pointers, but MillHud overrides that call to stop its breathing hint on
## the way down and never starts the hint again on the way up - so a trip to the
## settings would cost the sawmill its beckoning arrow for the rest of the pass.
## This lets go of the fingers and leaves every other state exactly as it was,
## which is all the panel ever wanted.
func release_pads() -> void:
	for pad: PadButton in _pads.values():
		pad.release_all()


## Lights whichever arrows a controller stick is pushing, and lights them only:
## the level adds the same stick into its own steering sum, so this must never
## change what `held()` answers or the machine would be driven twice over.
##
## A child on a controller is still looking at the screen, and these four arrows
## are the only thing on it telling them what they are doing, so a stick has to
## make them sink in exactly as a thumb does.
##
## `stick` is `Pad.move()`: -1..1 each way, already dead-zoned, with +Y pointing
## DOWN the screen the way the pads are drawn. Dimmed pads stay dark.
func set_stick_glow(stick: Vector2) -> void:
	var lean := stick if _pads_enabled else Vector2.ZERO
	_light_pad("right", lean.x > STICK_GLOW_POINT)
	_light_pad("left", lean.x < -STICK_GLOW_POINT)
	_light_pad("down", lean.y > STICK_GLOW_POINT)
	_light_pad("up", lean.y < -STICK_GLOW_POINT)


func _light_pad(pad_name: String, on: bool) -> void:
	var pad: PadButton = _pads.get(pad_name)
	if pad != null:
		pad.set_lit(on)


## Whether a pad is lit by a stick right now. The mirror of `held()`, which
## stays the finger's own answer.
func pad_lit(pad_name: String) -> bool:
	var pad: PadButton = _pads.get(pad_name)
	return pad != null and pad.lit


## For tests: press or release a pad without a finger.
func press_pad(pad_name: String, down: bool) -> void:
	var pad: PadButton = _pads.get(pad_name)
	if pad == null:
		return
	if down:
		pad.press(-99)
	else:
		pad.release(-99)


## The pads take their own touches (they are press-and-hold and multi-touch,
## which plain Buttons cannot do). Every press also leaves a ring, whether it
## landed on a pad or on the grass, and whether or not the machine is running
## yet - the ring is not gated on `_pads_enabled`, because the minutes before
## the key is turned are exactly when a child pokes everything.
##
## Every event also goes past `Pad.saw`, which is how the game knows whether a
## controller or a finger is in charge. This screen has no focus ring to do that
## for it (the stick is busy driving the machine), and the title screen this
## level came from will want the honest answer when the child goes back.
func _input(event: InputEvent) -> void:
	Pad.saw(event)
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			tap_ring(t.position)
		if _pads_enabled and _pad_touch(t.index, t.position, t.pressed):
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _pads_enabled:
			var d := event as InputEventScreenDrag
			_pad_drag(d.index, d.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Fingers arrive as real touches above; skip the mouse Godot fakes from them.
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.device != InputEvent.DEVICE_ID_EMULATION:
			if mb.pressed:
				tap_ring(mb.position)
			if _pads_enabled and _pad_touch(-1, mb.position, mb.pressed):
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _pads_enabled and mm.device != InputEvent.DEVICE_ID_EMULATION and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_pad_drag(-1, mm.position)


func _pad_touch(index: int, pos: Vector2, pressed: bool) -> bool:
	var hit := false
	for pad: PadButton in _pads.values():
		if pressed:
			if pad.hit(pos):
				pad.press(index)
				hit = true
		else:
			if pad.release(index):
				hit = true
	return hit


func _pad_drag(index: int, pos: Vector2) -> void:
	for pad: PadButton in _pads.values():
		var inside := pad.hit(pos)
		var has := pad.has_pointer(index)
		if inside and not has:
			pad.press(index)
		elif has and not inside:
			pad.release(index)


# --- Every finger gets an answer -------------------------------------------------------

## A white ring blooms wherever a finger lands, whatever the level happens to
## be doing with that tap. "Nothing happened" is the one answer a small child
## cannot argue with, so the ring is drawn before any phase decides to ignore
## them. Pooled, so a flurry of taps all get one. The ring itself is the chop
## game's (`TapRing`, an inner class of this one - Tree Chop's own copy lives
## on `ChopHud.TapRing`) rather than a second copy of it.
func _build_rings() -> void:
	for i in range(maxi(tap_ring_pool_size, 1)):
		var ring := TapRing.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.ring_width = tap_ring_width
		ring.ring_color = tap_ring_color
		ring.visible = false
		_root.add_child(ring)
		_rings.append(ring)


func tap_ring(pos: Vector2) -> void:
	if _rings.is_empty():
		return
	var ring: TapRing = _rings[_ring_next]
	_ring_next = (_ring_next + 1) % _rings.size()
	ring.ring_width = tap_ring_width
	ring.ring_color = tap_ring_color
	ring.play(pos, tap_ring_start_radius, tap_ring_end_radius, tap_ring_time)
	_rings_played += 1


## How many rings have been played (for tests).
func rings_played() -> int:
	return _rings_played


# --- Start / next ----------------------------------------------------------------------

## The ignition. There is no coloured pill under the key: the child is aiming at
## a piece of the machine, and a disc behind it only made the machine look like a
## sticker somebody had stuck on the lawn. The button is still exactly as big and
## as forgiving as it was - a Button answers its whole rectangle, not its paint -
## it just has nothing of its own to show.
func _build_start() -> void:
	_start = _bare_button("Start", start_size)
	# Bottom centre, between the pads, so the stump itself is never covered.
	_start.anchor_left = 0.5
	_start.anchor_right = 0.5
	_start.anchor_top = go_button_anchor_y
	_start.anchor_bottom = go_button_anchor_y
	_start.offset_left = -start_size * 0.5
	_start.offset_right = start_size * 0.5
	_start.offset_top = -start_size * 0.5
	_start.offset_bottom = start_size * 0.5
	_start.pivot_offset = Vector2(start_size, start_size) * 0.5
	_start.pressed.connect(_on_start)
	# With no stylebox left to darken, the key itself has to answer the finger.
	_start.button_down.connect(func() -> void: _key.scale = Vector2(key_press_scale, key_press_scale))
	_start.button_up.connect(func() -> void: _key.scale = Vector2.ONE)
	_root.add_child(_start)
	_key = KeyIgnition.new()
	_key.name = "Key"
	# All of these must be set BEFORE the key enters the tree: `_start` is already
	# in it, so `add_child` runs `_ready` on the spot and frames the camera there
	# and then. Anything assigned afterwards would arrive too late to be seen.
	_key.fill = key_fill
	_key.shadow_offset = key_shadow_offset
	_key.shadow_color = key_shadow_color
	_key.shadow_size = key_shadow_size
	_key.size = Vector2(start_size, start_size)
	_key.pivot_offset = Vector2(start_size, start_size) * 0.5
	_start.add_child(_key)


func _build_next() -> void:
	_next = _round_button("Next", start_size * 0.8, start_color)
	var s := start_size * 0.8
	_next.anchor_left = 0.5
	_next.anchor_right = 0.5
	_next.anchor_top = go_button_anchor_y
	_next.anchor_bottom = go_button_anchor_y
	_next.offset_left = -s * 0.5
	_next.offset_right = s * 0.5
	_next.offset_top = -s * 0.5
	_next.offset_bottom = s * 0.5
	_next.pivot_offset = Vector2(s, s) * 0.5
	_next.pressed.connect(_on_next)
	var tri := Polygon2D.new()
	tri.name = "Triangle"
	tri.polygon = PackedVector2Array([Vector2(s * 0.36, s * 0.27), Vector2(s * 0.36, s * 0.73), Vector2(s * 0.76, s * 0.5)])
	tri.color = Color.WHITE
	_next.add_child(tri)
	_next.visible = false
	_root.add_child(_next)


func _on_start() -> void:
	if not _start.visible or _start.disabled:
		return
	_start.disabled = true
	if _start_tween != null and _start_tween.is_valid():
		_start_tween.kill()
	_start_tween = create_tween()
	_start_tween.tween_property(_key, "turn", PI * 0.5, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_start_tween.tween_interval(0.12)
	_start_tween.tween_property(_start, "scale", Vector2(0.01, 0.01), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_start_tween.tween_callback(func() -> void:
		_start.visible = false
		_start.scale = Vector2.ONE
		# Belt and braces on the press: a finger that lifted somewhere strange
		# must never leave the key stuck sunk with nothing on screen to say why.
		_key.scale = Vector2.ONE
		_key.turn = 0.0)
	start_pressed.emit()


func _on_next() -> void:
	if not _next.visible:
		return
	_next.visible = false
	next_pressed.emit()


## Brings the key back for the next stump.
func show_start() -> void:
	if _start_tween != null and _start_tween.is_valid():
		_start_tween.kill()
	_key.turn = 0.0
	_key.scale = Vector2.ONE
	_start.disabled = false
	_start.scale = Vector2(0.01, 0.01)
	_start.visible = true
	_start_tween = create_tween()
	_start_tween.tween_property(_start, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func start_visible() -> bool:
	return _start.visible and not _start.disabled


## Is the child looking at the fleet's machined key, or at the flat drawing that
## stands in when the GLB cannot be loaded? Worth a test of its own: the
## fallback is deliberately silent, so without one a missing model would just
## quietly put the old icon back and nobody would notice for weeks.
func key_is_modelled() -> bool:
	return _key != null and _key.is_modelled()


func show_next() -> void:
	_next.visible = true
	_next.scale = Vector2(0.01, 0.01)
	var tw := create_tween()
	tw.tween_property(_next, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_next() -> void:
	_next.visible = false


func next_visible() -> bool:
	return _next.visible


## For tests: tap the visible start / next button.
func simulate_start() -> void:
	_on_start()


func simulate_next() -> void:
	_on_next()


# --- Home ------------------------------------------------------------------------------

## A round green house in the top-right corner, like the chop game's: back to
## the title screen. It answers in every phase, pads or no pads.
func _build_home() -> void:
	var s := corner_button_size
	var m := corner_button_margin
	_home = _round_button("Home", s, corner_button_color)
	_home.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_home.offset_right = -m
	_home.offset_left = -m - s
	_home.offset_top = m
	_home.offset_bottom = m + s
	_home.pressed.connect(func() -> void: home_pressed.emit())
	_draw_house(_home, s, Color.WHITE)
	_root.add_child(_home)


## For tests: tap the house.
func simulate_home() -> void:
	home_pressed.emit()


## Roof, walls and a darker door, in the button's own pixels.
func _draw_house(host: Control, s: float, c: Color) -> void:
	var cx := s * 0.5
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(cx - s * 0.30, s * 0.50), Vector2(cx, s * 0.24), Vector2(cx + s * 0.30, s * 0.50),
	])
	roof.color = c
	host.add_child(roof)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(cx - s * 0.22, s * 0.50), Vector2(cx + s * 0.22, s * 0.50),
		Vector2(cx + s * 0.22, s * 0.76), Vector2(cx - s * 0.22, s * 0.76),
	])
	body.color = c
	host.add_child(body)
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([
		Vector2(cx - s * 0.06, s * 0.60), Vector2(cx + s * 0.06, s * 0.60),
		Vector2(cx + s * 0.06, s * 0.76), Vector2(cx - s * 0.06, s * 0.76),
	])
	door.color = c.darkened(0.55)
	host.add_child(door)


# --- Bar and banner ------------------------------------------------------------------

func _build_bar() -> void:
	_bar = ProgressBar.new()
	_bar.name = "StumpBar"
	_bar.show_percentage = false
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.value = 1.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.anchor_left = 0.5
	_bar.anchor_right = 0.5
	_bar.anchor_top = 0.0
	_bar.anchor_bottom = 0.0
	_bar.offset_left = -bar_size.x * 0.5 + 24.0
	_bar.offset_right = bar_size.x * 0.5 + 24.0
	_bar.offset_top = 26.0
	_bar.offset_bottom = 26.0 + bar_size.y
	var bg := StyleBoxFlat.new()
	# Near-opaque, not half-transparent: the track is what the fill is read
	# AGAINST, and at 0.55 a yellow bus or a red car showing through it turned
	# the whole bar into one warm smear with no line between done and to-do.
	bg.bg_color = Color(0.06, 0.05, 0.03, 0.85)
	bg.set_corner_radius_all(int(bar_size.y * 0.5))
	bg.set_border_width_all(3)
	bg.border_color = Color(1.0, 0.98, 0.9, 0.8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.78, 0.56, 0.30)
	fill.set_corner_radius_all(int(bar_size.y * 0.5))
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fill)
	_root.add_child(_bar)
	# A little stump icon at the bar's left end.
	var icon := StumpIcon.new()
	icon.name = "StumpIcon"
	icon.size = Vector2(46.0, 40.0)
	icon.position = Vector2(-58.0, -8.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(icon)


## How much of the stump is left, 0..1.
func set_progress(frac: float) -> void:
	_bar.value = clampf(frac, 0.0, 1.0)


func _build_flash() -> void:
	_flash = Label.new()
	_flash.text = "YAY!"
	# Fredoka in Safety Yellow, cut out in Workshop Charcoal: the banner is a
	# picture a child reads, set the way Tree Crew sets its TIMBER!.
	Brand.stamp(_flash, flash_font_size, Brand.YELLOW)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_flash.offset_left = 0.0
	_flash.offset_right = 0.0
	_flash.offset_top = flash_top
	_flash.offset_bottom = flash_top + flash_font_size + 30.0
	_flash.visible = false
	_root.add_child(_flash)


func flash(text: String, hold: float = 1.0) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.text = text
	_flash.pivot_offset = Vector2(_flash.size.x * 0.5, _flash.size.y * 0.5)
	_flash.visible = true
	_flash.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_flash.scale = Vector2(0.4, 0.4)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_interval(hold)
	_flash_tween.tween_property(_flash, "modulate:a", 0.0, 0.3)
	_flash_tween.tween_callback(func() -> void: _flash.visible = false)


func flash_text() -> String:
	return _flash.text if _flash.visible else ""


## One round button, cut out in the Big Little Jobs way (`Brand.round_style`,
## 2026-09-11): the job pictures on the garage's left edge are, and a house and
## a LIFT button in the old soft blur beside them were two sets of objects.
func _round_button(button_name: String, s: float, color: Color) -> Button:
	var b := Button.new()
	b.name = button_name
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(s, s)
	Brand.dress_button(b, color, int(s * 0.5))
	return b


## A button with no paint of its own: the thing standing INSIDE it is what the
## child aims at. All five slots have to be emptied, not just "normal" - Godot's
## default theme carries normal, hover, pressed, disabled and focus for Button,
## and any one left alone puts the engine's grey rounded box back the moment a
## finger lands or the button is disabled, which is exactly what a press does.
func _bare_button(button_name: String, s: float) -> Button:
	var b := Button.new()
	b.name = button_name
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(s, s)
	for slot in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(slot, StyleBoxEmpty.new())
	return b


func _round_style(color: Color, radius: int) -> StyleBoxFlat:
	return Brand.round_style(color, radius)


## One round press-and-hold arrow button that tracks its own fingers.
class PadButton extends Control:
	enum Arrow { UP, DOWN, LEFT, RIGHT }
	var arrow: Arrow = Arrow.UP
	var color: Color = Color(0.24, 0.52, 0.92)
	var held: bool = false
	## Pushed by a controller stick rather than by a finger. It is drawn exactly
	## like a press but is deliberately not `held`, because the level counts the
	## stick itself.
	var lit: bool = false
	var enabled: bool = true
	var _pointers: Dictionary = {}

	func hit(pos: Vector2) -> bool:
		if not enabled:
			return false
		var c := global_position + size * 0.5
		return pos.distance_to(c) <= size.x * 0.56

	func has_pointer(index: int) -> bool:
		return _pointers.has(index)

	func press(index: int) -> void:
		_pointers[index] = true
		_set_held(true)

	## Returns true if that pointer was holding this pad.
	func release(index: int) -> bool:
		if not _pointers.has(index):
			return false
		_pointers.erase(index)
		_set_held(not _pointers.is_empty())
		return true

	func release_all() -> void:
		_pointers.clear()
		_set_held(false)

	func _set_held(on: bool) -> void:
		if held == on:
			return
		held = on
		_refresh_look()

	## Lights the disc for a stick pushing this way, without laying a finger on
	## it. Cheap to call every frame: a stick held over changes nothing.
	func set_lit(on: bool) -> void:
		if lit == on:
			return
		lit = on
		_refresh_look()

	## A stick and a thumb sink the disc in the same way on purpose. "The arrow I
	## am pushing goes down" is the whole message, and it should not depend on
	## which hand the child happens to be playing with.
	func _refresh_look() -> void:
		pivot_offset = size * 0.5
		scale = Vector2(0.92, 0.92) if (held or lit) else Vector2.ONE
		queue_redraw()

	func _draw() -> void:
		var s := size.x
		var c := size * 0.5
		var r := s * 0.5
		var col := color.darkened(0.18) if (held or lit) else color
		draw_circle(c + Vector2(0.0, s * 0.045), r, Color(0.0, 0.0, 0.0, 0.25))
		draw_circle(c + Vector2(0.0, s * 0.03), r, col.darkened(0.3))
		draw_circle(c, r - s * 0.015, col)
		draw_colored_polygon(_arrow_points(s), Color.WHITE)

	func _arrow_points(s: float) -> PackedVector2Array:
		match arrow:
			Arrow.UP:
				return PackedVector2Array([Vector2(s * 0.5, s * 0.22), Vector2(s * 0.80, s * 0.64), Vector2(s * 0.20, s * 0.64)])
			Arrow.DOWN:
				return PackedVector2Array([Vector2(s * 0.5, s * 0.78), Vector2(s * 0.20, s * 0.36), Vector2(s * 0.80, s * 0.36)])
			Arrow.LEFT:
				return PackedVector2Array([Vector2(s * 0.22, s * 0.5), Vector2(s * 0.64, s * 0.20), Vector2(s * 0.64, s * 0.80)])
			_:
				return PackedVector2Array([Vector2(s * 0.78, s * 0.5), Vector2(s * 0.36, s * 0.80), Vector2(s * 0.36, s * 0.20)])


## The ignition the child turns: the fleet's own `Ignition.glb` - a key sitting
## in a barrel on a scrap of orange dash - rendered live in a little 3D viewport,
## so the thing under the finger is the same chunky low-poly machinery as the
## grinder standing behind it, not a flat drawing.
##
## It fills the START button and the button itself is invisible: the key is not a
## picture ON a control, it IS the control, a piece of the machine left lying in
## the grass for a child to reach out and turn. The orange plate and the red bow
## carry it against every ground this game has, summer or snow, and it drops its
## own shadow so it still reads as standing above the clearing.
##
## `turn` is the quarter turn, in radians, and the level tweens it; the key goes
## clockwise, the way a car's does. The camera is orthogonal and frames itself
## from the model's own bounds, so the key can be re-cut in Blender without
## anyone coming back here to re-tune numbers. If the GLB is ever missing, the
## drawn `KeyIcon` below takes over and `turn` spins that instead - the button
## works either way.
class KeyIgnition extends Control:
	const MODEL_PATH := "res://assets/models/props/Ignition.glb"
	## A real three-quarter, and not negotiable: a key points at the viewer, so
	## dead-on it is a stub. The hole in the bow and the notches in the blade -
	## the two things that say "key" rather than "dial" - only exist off the
	## axis, while the quarter turn only reads if the barrel face is in view at
	## all. This angle is the one that buys both. Radians.
	const VIEW_YAW := 0.58
	const VIEW_PITCH := 0.38
	## How much of the button's LONGEST axis the prop fills - the camera is fitted
	## to whichever way round the key measures widest from this view. Nothing sits
	## behind the key any more, so it may have very nearly the whole of that axis.
	## The last few per cent are held back only so the orthographic fit cannot
	## clip it by a pixel; above 1.0 there would be key outside the button, which
	## is worse than a small margin - visible, and untappable. The shorter axis
	## keeps the key's own proportions and this cannot change that.
	var fill: float = 0.96

	## The key's own drop shadow, spread from its silhouette rather than borrowed
	## from a disc behind it. `shadow_size` is how far it reaches past the key and
	## fades away, in pixels, and it is the number that decides whether this
	## reads as a halo or as a hard second copy of the key printed behind it.
	## Alpha 0 means no shadow.
	var shadow_offset: Vector2 = Vector2(0.0, 6.0)
	var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.28)
	var shadow_size: float = 12.0

	var turn: float = 0.0:
		set(value):
			turn = value
			if _key_node != null:
				_key_node.rotation.z = -value
			if _flat != null:
				_flat.rotation = value

	var _key_node: Node3D
	var _flat: KeyIcon


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not _build_model():
			_build_flat()


	## True once the GLB is standing in its own little world with a light and a
	## camera on it. Anything missing - the file, the `Key` node the turn needs -
	## and it says so rather than half-building something that cannot turn.
	func _build_model() -> bool:
		if not ResourceLoader.exists(MODEL_PATH):
			return false
		var packed := ResourceLoader.load(MODEL_PATH) as PackedScene
		if packed == null:
			return false
		var inst := packed.instantiate() as Node3D
		if inst == null:
			return false
		var key_node := inst.find_child("Key", true, false) as Node3D
		if key_node == null:
			push_warning("KeyIgnition: %s has no Key node to turn" % MODEL_PATH)
			inst.queue_free()
			return false
		var box := SubViewportContainer.new()
		box.name = "View"
		box.stretch = true
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(box)
		var view := SubViewport.new()
		view.name = "Viewport"
		view.transparent_bg = true
		# Its own world, or the little camera would look into the clearing.
		view.own_world_3d = true
		view.msaa_3d = Viewport.MSAA_4X
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		box.add_child(view)
		view.add_child(inst)
		_key_node = key_node
		_key_node.rotation.z = -turn
		_light(view)
		_frame(view, inst)
		_shade(view)
		return true


	## The key's own silhouette, laid behind it, nudged down, spread outward and
	## blurred away at its edge. There is no disc under the prop any longer to
	## lift it off the ground, and every other button in this game casts a
	## shadow, so without this one the key alone would look printed on the grass
	## instead of lying on it - and the NEXT disc appears in the exact spot the
	## key has just left, so the two are compared back to back.
	##
	## Matching that disc means matching all three of its shadow numbers. Offset
	## and colour are easy; the third, `shadow_size`, is the one that makes a
	## StyleBoxFlat shadow a soft halo rather than a hard copy, and a plain
	## tinted TextureRect has nothing like it. So the picture is grown by
	## `shadow_size` on every side - the outward spread - and blurred by the same
	## amount in the shader below, which is the fade. It is the little viewport's
	## own picture, so the shape is exactly the key's however the model is re-cut
	## in Blender.
	func _shade(view: SubViewport) -> void:
		if shadow_color.a <= 0.0:
			return
		var grow := maxf(shadow_size, 0.0)
		var shade := TextureRect.new()
		shade.name = "Shadow"
		shade.texture = view.get_texture()
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.offset_left += shadow_offset.x - grow
		shade.offset_right += shadow_offset.x + grow
		shade.offset_top += shadow_offset.y - grow
		shade.offset_bottom += shadow_offset.y + grow
		if grow > 0.0:
			var mat := ShaderMaterial.new()
			mat.shader = _blur_shader()
			# In UV, because that is what the shader steps in: the picture is
			# stretched over a rect `grow` wider on each side than the button.
			mat.set_shader_parameter("spread", grow / maxf(size.x + grow * 2.0, 1.0))
			mat.set_shader_parameter("ink", shadow_color)
			shade.material = mat
		else:
			shade.modulate = shadow_color
		add_child(shade)
		# First child, so the shadow is under the key and not over it.
		move_child(shade, 0)


	## Blurs the key's silhouette into a soft halo and paints it one flat colour.
	##
	## Only the ALPHA of the picture is blurred - the colour is `ink` everywhere -
	## so the metal of the key never bleeds into its own shadow. Samples that
	## fall outside the picture count as empty rather than smearing the edge
	## pixel outward, which is what a clamped read would do to a key that very
	## nearly touches the edge of its viewport.
	func _blur_shader() -> Shader:
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;

uniform float spread = 0.05;
uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 0.28);

void fragment() {
	float sum = 0.0;
	float total = 0.0;
	for (int i = -3; i <= 3; i++) {
		for (int j = -3; j <= 3; j++) {
			vec2 step_uv = vec2(float(i), float(j)) / 3.0;
			float w = exp(-2.0 * dot(step_uv, step_uv));
			vec2 at = UV + step_uv * spread;
			float inside = step(0.0, at.x) * step(at.x, 1.0) * step(0.0, at.y) * step(at.y, 1.0);
			sum += texture(TEXTURE, clamp(at, vec2(0.0), vec2(1.0))).a * w * inside;
			total += w;
		}
	}
	// Thickened before it is clipped: a plain blur thins a shape as slender as
	// a key's shank to a ghost, while the shadow it has to match is a SOLID
	// expanded shape with a soft rim. This puts the solid core back and leaves
	// the softness where it belongs, at the edge.
	COLOR = vec4(ink.rgb, ink.a * clamp(sum / total * 2.4, 0.0, 1.0));
}
"""
		return sh


	## Flat and bright, the way the fleet's own previews are lit: one key light
	## over the viewer's shoulder and a lot of sky ambient, so every facet reads
	## and nothing on the far side of the barrel goes black.
	func _light(view: SubViewport) -> void:
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.72, 0.79, 0.90)
		# Enough sky to keep the far side of the barrel from going black, and no
		# more: flood it and the pale plug blows out into a white blob with the
		# keyway lost in it, which is the one shape that has to survive.
		env.ambient_light_energy = 0.55
		var we := WorldEnvironment.new()
		we.name = "Env"
		we.environment = env
		view.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.name = "Sun"
		sun.light_energy = 1.6
		sun.rotation = Vector3(-0.72, 0.55, 0.0)
		view.add_child(sun)


	## Aims an orthogonal camera at the barrel face and opens it just wide enough
	## to hold the whole prop. Orthogonal because this is an icon: a perspective
	## key would lean, and at 200 px a lean reads as a mistake.
	##
	## The framing is measured through the camera rather than off the model's
	## width and height, because from a three-quarter view the key's LENGTH -
	## which points at the viewer - swings out across the picture and would
	## otherwise hang off the edge of the button unseen. Doing it this way also
	## means the model can be re-cut in Blender, or given a longer key, without
	## anyone coming back here to re-tune a number.
	func _frame(view: SubViewport, inst: Node3D) -> void:
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			var b := mi.global_transform * mi.get_aabb()
			box = b if first else box.merge(b)
			first = false
		if first:
			box = AABB(Vector3(-0.1, -0.1, -0.1), Vector3(0.2, 0.2, 0.2))
		var face := inst.find_child("KeyFace", true, false) as Node3D
		var aim := face.global_position if face != null else box.get_center()
		var cam := Camera3D.new()
		cam.name = "Camera"
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.near = 0.01
		cam.far = 8.0
		view.add_child(cam)
		var away := Basis.from_euler(Vector3(-VIEW_PITCH, VIEW_YAW, 0.0)) * Vector3(0.0, 0.0, 1.0)
		cam.global_position = aim + away * 2.0
		cam.look_at(aim, Vector3.UP)
		# Every corner of the model's box, seen from where the camera now is.
		var to_cam := cam.global_transform.affine_inverse()
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for i in range(8):
			var flat := to_cam * box.get_endpoint(i)
			lo = Vector2(minf(lo.x, flat.x), minf(lo.y, flat.y))
			hi = Vector2(maxf(hi.x, flat.x), maxf(hi.y, flat.y))
		# Slide the camera sideways so the prop sits in the middle of the
		# button rather than wherever the model happens to hang off its origin.
		var middle := (lo + hi) * 0.5
		cam.global_position += cam.global_basis.x * middle.x + cam.global_basis.y * middle.y
		var span := hi - lo
		cam.size = maxf(maxf(span.x, span.y), 0.05) / maxf(fill, 0.05)


	## No model on disk: the old drawn key, turning exactly as it always did.
	func _build_flat() -> void:
		_flat = KeyIcon.new()
		_flat.name = "Flat"
		_flat.shadow_offset = shadow_offset
		_flat.shadow_color = shadow_color
		_flat.shadow_size = shadow_size
		_flat.size = size
		_flat.pivot_offset = size * 0.5
		_flat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flat.rotation = turn
		add_child(_flat)


	## For tests: is the child looking at the real machined key, or the drawing?
	func is_modelled() -> bool:
		return _key_node != null


## A chunky white key, drawn in the button's own pixels; turns when tapped.
## Kept as `KeyIgnition`'s fallback for when the GLB cannot be loaded.
##
## The hole in the bow is a real hole. It used to be a filled circle painted the
## green of the disc behind the button, which worked only for as long as there
## WAS a disc; with the disc gone that would have left a little green dot sitting
## on the grass - the very thing we are removing, in miniature. So the bow is a
## ring now and the clearing shows through it, as a hole in a key should.
class KeyIcon extends Control:
	## How many faint copies make the shadow's halo, spread evenly round it.
	const HALO_COPIES := 8
	## How much of the shadow's ink the halo is allowed to spend where every one
	## of its copies overlaps. The rest is the solid silhouette underneath. Low,
	## because the halo is only meant to be the soft rim: raise it and the key's
	## shadow turns into a cloud, lower it and it goes back to a knife edge.
	const HALO_SHARE := 0.35

	var shadow_offset: Vector2 = Vector2(0.0, 6.0)
	var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.28)
	var shadow_size: float = 12.0

	## The two alphas the shadow is painted with: x for one halo copy, y for the
	## solid silhouette under them all.
	##
	## `shadow_color.a` is a BUDGET, not a per-layer alpha, and this is what
	## solves it. Eight copies of a shape as slender as a key ring each other
	## closer than they are wide, so most of the key is under six or seven of
	## them at once and the alpha piles up: copies at a/8 with the solid on top
	## composited to about 0.46 where the knob asked for 0.28 - a shadow half
	## again as heavy as the NEXT disc this key hands over to, in the same spot,
	## a moment later. Layers stack as 1 - (1 - x)^n * (1 - y), so both alphas
	## come back out of that: the halo takes HALO_SHARE of the budget where all
	## of it overlaps, and the silhouette takes what is left, which lands the
	## deepest point of the stack exactly on the number in the knob and lets the
	## rim fade away from there.
	func shadow_alphas() -> Vector2:
		var ink := clampf(shadow_color.a, 0.0, 1.0)
		if shadow_size <= 0.0 or HALO_COPIES <= 0:
			return Vector2(0.0, ink)
		var halo := ink * HALO_SHARE
		var per := 1.0 - pow(1.0 - halo, 1.0 / float(HALO_COPIES))
		# What the solid still has to add under a halo that thick.
		var solid := 1.0 - (1.0 - ink) / maxf(1.0 - halo, 0.0001)
		return Vector2(per, clampf(solid, 0.0, 1.0))

	## The shadow first, then the key itself on top, so the flat stand-in sits on
	## the ground with the same weight as the modelled one - and as the round
	## buttons, whose shadows spread `shadow_size` past their edge and fade. This
	## has no shader to blur with, so the spread is faked by ringing the shape
	## with faint copies of itself, thinning out to nothing at the rim; what they
	## may cost between them is `shadow_alphas()`.
	func _draw() -> void:
		if shadow_color.a > 0.0:
			var ink := shadow_alphas()
			if ink.x > 0.0:
				var faint := Color(shadow_color.r, shadow_color.g, shadow_color.b, ink.x)
				for i in range(HALO_COPIES):
					var a := TAU * float(i) / float(HALO_COPIES)
					_key_shape(shadow_offset + Vector2(cos(a), sin(a)) * shadow_size, faint)
			_key_shape(shadow_offset, Color(shadow_color.r, shadow_color.g, shadow_color.b, ink.y))
		_key_shape(Vector2.ZERO, Color.WHITE)

	## Bow, shank and two notches. The ring's radius and width are the midpoint
	## and the difference of the two circles this used to stack, so the key's
	## outline is exactly the one a child has already learned.
	func _key_shape(at: Vector2, c: Color) -> void:
		var s := size.x
		draw_arc(at + Vector2(s * 0.34, s * 0.5), s * 0.1125, 0.0, TAU, 28, c, s * 0.095, true)
		draw_rect(Rect2(at.x + s * 0.44, at.y + s * 0.45, s * 0.34, s * 0.10), c)
		draw_rect(Rect2(at.x + s * 0.62, at.y + s * 0.55, s * 0.055, s * 0.09), c)
		draw_rect(Rect2(at.x + s * 0.71, at.y + s * 0.55, s * 0.055, s * 0.13), c)


## A little stump: a brown block with a paler top.
class StumpIcon extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(w * 0.15, h * 0.35, w * 0.7, h * 0.6), Color(0.42, 0.27, 0.15))
		draw_rect(Rect2(w * 0.1, h * 0.85, w * 0.8, h * 0.15), Color(0.34, 0.22, 0.12))
		var pts := PackedVector2Array()
		for i in range(14):
			var a := TAU * float(i) / 14.0
			pts.append(Vector2(w * 0.5 + cos(a) * w * 0.36, h * 0.35 + sin(a) * h * 0.16))
		draw_colored_polygon(pts, Color(0.86, 0.70, 0.42))
		var ring := PackedVector2Array()
		for i in range(14):
			var a := TAU * float(i) / 14.0
			ring.append(Vector2(w * 0.5 + cos(a) * w * 0.2, h * 0.35 + sin(a) * h * 0.09))
		draw_polyline(ring, Color(0.64, 0.46, 0.25), 2.0, true)


## A single expanding tap ring. Drawn rather than textured so it scales
## cleanly on any screen. Tree Chop's own copy of this is `ChopHud.TapRing`
## (in `hud.gd`); this one is pulled in here as an inner class so `_build_rings`
## and `tap_ring` above do not have to depend on `ChopHud`, which does not
## exist in this project.
class TapRing extends Control:
	var ring_width: float = 7.0
	var ring_color: Color = Color.WHITE
	var radius: float = 20.0:
		set(value):
			radius = value
			queue_redraw()
	var ring_alpha: float = 1.0:
		set(value):
			ring_alpha = value
			queue_redraw()

	var _tw: Tween

	func _draw() -> void:
		if ring_alpha <= 0.001:
			return
		var c := ring_color
		c.a = ring_color.a * ring_alpha
		draw_arc(Vector2.ZERO, maxf(radius, 0.5), 0.0, TAU, 48, c, ring_width, true)

	func play(p: Vector2, r0: float, r1: float, dur: float) -> void:
		position = p
		radius = r0
		ring_alpha = 1.0
		visible = true
		if _tw != null and _tw.is_valid():
			_tw.kill()
		_tw = create_tween()
		_tw.set_parallel(true)
		_tw.tween_property(self, "radius", r1, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tw.tween_property(self, "ring_alpha", 0.0, dur)
		_tw.chain().tween_callback(func() -> void: visible = false)
