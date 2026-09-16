class_name SiteHud
extends ToyHud
## The site's controls: `ToyHud` with the ignition key hidden and three things
## added. Car Garage's `GarageHud` with the garage's own buttons taken out - the
## arrow arithmetic below is its, unchanged, because it is the part that took
## six critic rounds to get right.
##
##  * a bouncing gold ARROW over the next thing to tap, sized to how big that
##    thing is on screen and with its POINT inside the thing's own silhouette,
##    so a finger that goes where the point goes lands on the thing;
##  * one big round GO button in the bottom-left corner, which is how a machine
##    is called onto the site. NEXT takes the same slot when the job is done, so
##    the one spot a thumb has learned always answers;
##  * the progress bar across the top, with a little slab for its icon.
##
## The four steering PADS are `ToyHud`'s and are kept: this game drives machines
## with them (the skid steer's push, the dump truck's bed, and the chute). They
## are hidden until a beat wants them (`SiteMain.arm_pads`).

## The big green button under the child's thumb: bring the machine on.
signal go_pressed

## How many progress stops the driveway job has. Only the DEFAULT - the level
## tells the bar how long the job it loaded really is.
const STEPS := 30

@export var go_size: float = 190.0
## How far the round buttons in the bottom-LEFT corner stand off the edge.
## Bottom-left because the drive runs up the RIGHT of the picture: nothing the
## child ever taps is over there.
## 36, not 22: the gold halo round the call button was clipped by both screen
## edges (round 3).
@export var corner_margin: float = 44.0
## White, not green: a green disc over the lawn separated from it by hue
## alone (5% of luma), which is nothing to a red-green-blind child (round 6).
@export var go_color: Color = Color(0.97, 0.96, 0.92)
## How big the GO button is while it is asleep, as a fraction of itself.
@export_range(0.3, 1.0, 0.01) var go_sleep_scale: float = 0.50
## WHERE TO TAP is a gold RING on the thing, with a fat arrow bobbing over it -
## `SpotRings`, the same mark the phases with several places use, and Tree Crew's
## before that. The level hands the HUD one of those in `_ready`.
##
## It replaced a flat gold WEDGE drawn over the picture in 2D, which the user
## could not identify ("is it a finger pointing?") and which had two faults
## beyond its shape: its point dipped INTO the thing it was aiming at and back
## out, which reads as a jab rather than as pointing, and it re-chose which of
## twelve directions to come from every frame - so the moment the cameras started
## to orbit it flicked from one side of its target to the other.
##
## A mark in the WORLD cannot do either. It sits on the thing, it is the same
## gold ring the child already knows, and it needs no arithmetic about the edge
## of the screen at all.
@export var arrow_color: Color = Color(1.0, 0.84, 0.22)
## How big the ring is drawn over a target of a given size, in metres, and the
## smallest and largest it may be. A 5 cm stake and a 3 m slab both have to end
## up with a ring a child can see and hit.
@export_range(0.2, 3.0, 0.05) var hint_of_target: float = 1.30
## 0.36 to 0.62, not 0.34 to 1.10: the mark that means "touch here" varied
## three times over across the job (round 3), and a child learns one mark.
@export_range(0.1, 2.0, 0.05) var hint_min: float = 0.36
@export_range(0.2, 4.0, 0.05) var hint_max: float = 0.62
## A tap away from the thing: the mark swells and bounces harder for this long,
## so the finger is told where to go. A miss is never silent and never punished.
@export_range(0.1, 2.0, 0.05) var arrow_nudge_time: float = 0.7
## How near the mark a finger counts as having pressed IT rather than the thing
## under it, as a fraction of the picture's shorter side.
@export_range(0.02, 0.3, 0.01) var hint_touch: float = 0.09
## The ring that pulses on the round button when the button is the answer. A
## floating arrow over a button the child can already see is one thing too many.
@export var ring_color: Color = Color(1.0, 0.84, 0.22)
@export var ring_rate: float = 1.5
## THE WHITE IDLE ARROW (fourth playtest: "add idle white arrows"), Car
## Garage's: after `hint_delay` seconds of nothing, a white wedge with a dark
## rim stands over the thing to work and MIMES what to do - a tap comes in and
## out, a hold comes in and stays, a drag slides across - for `hint_cycle`,
## rests `hint_rest`, and goes the instant the child does anything. The gold
## RING stays under it (it is the WHERE); the pointer's own bobbing arrow steps
## aside while the white one is up (one arrow at a time).
@export_range(1.0, 20.0, 0.5) var hint_delay: float = 4.0
@export_range(0.6, 4.0, 0.1) var hint_cycle: float = 1.7
@export_range(0.0, 3.0, 0.1) var hint_rest: float = 0.7
@export_range(0.5, 2.0, 0.05) var hint_scale: float = 1.15
@export_range(0.02, 0.4, 0.01) var hint_swipe: float = 0.13
@export var hint_color: Color = Color(1.0, 1.0, 1.0)
## The wedge's base size in pixels, how far clear of the ring's rim its point
## rests, and how far inside the picture the thing has to be for it to show.
@export var hint_arrow_px: float = 62.0
@export var hint_gap: float = 12.0
@export var hint_margin: float = 44.0

enum Aim { NONE, WORLD, GO, NEXT }
enum Hint { NONE, TAP, HOLD, DRAG, WIGGLE }

## The camera the arrow projects through. The level sets it in `_ready`.
var camera: Camera3D

var _go: Button
## The drawn fallback glyph; the low-poly icons in `_icons` (kind -> PropIcon)
## are the picture when the models load.
var _glyph: TruckGlyph
var _icons: Dictionary = {}
var _go_enabled: bool = true
var _go_tween: Tween
## The gold ring-and-arrow that marks a single place. Owned by the LEVEL (it is
## a 3D node and this is a CanvasLayer), handed over in `SiteMain._ready`.
var pointer: SpotRings
var _ring: PulseRing
var _aim: Aim = Aim.NONE
var _aim_world: Vector3 = Vector3.ZERO
var _aim_radius: float = 0.0
var _aim_centre: Vector3 = Vector3.INF
var _aim_ring: bool = true
var _arrow_t: float = 0.0
var _nudge_left: float = 0.0
var _total_steps: int = STEPS
var _hint: HintArrow
var _hint_kind: Hint = Hint.NONE
var _hint_idle: float = 0.0
var _hint_t: float = 0.0
## Where the target landed on screen this frame, the unit direction from it OUT
## to the arrow, how far out the point rests, and how big the wedge is.
var _aim_at: Vector2 = Vector2.INF
var _aim_dir: Vector2 = Vector2.UP
var _aim_touch: float = 0.0
var _aim_size: float = 62.0
## The target the current `_aim_dir` was chosen for: chosen ONCE per target,
## never re-solved per frame (the 2026-09-12 fault).
var _hint_dir_for: Vector3 = Vector3.INF
## Which way the white wedge's BODY runs from its touch point, as it was last
## drawn. `_aim_at` is re-solved every frame and is INF between frames on a
## rings beat, so a press cannot read the wedge's direction off it.
var _hint_body: Vector2 = Vector2.UP
## When the last miss was, for `hint_hurry`: two inside three seconds bring
## the mime at once.
var _last_miss_s: float = -100.0
## How present the CHROME - the bar and its hat - is, 0..1, and where it is
## heading: full between beats, stepped back to `chrome_working` while a beat
## is live under the finger (the plan's 3.7), and gone for the payoff, where
## the picture carries nothing that is not the site (3.3). Eased over 0.2 s.
@export_range(0.0, 1.0, 0.05) var chrome_working: float = 0.35
var _chrome_target: float = 1.0
var _chrome_locked: bool = false


func _ready() -> void:
	super()
	_hide_borrowed_controls()
	_build_go()
	# NEXT takes the GO button's place, so the one spot a thumb has learned
	# answers with whatever the job wants next.
	_corner(_next, start_size * 0.8)
	_build_arrow()
	_swap_bar_icon()
	set_progress(0.0)
	set_process(true)


## The ignition key belongs to the machines that are started by hand. Nothing
## here is, so it is turned off and made invisible rather than cut out of the
## shared base class. The PADS stay: this game uses them.
func _hide_borrowed_controls() -> void:
	set_pads_enabled(false)
	for pad: Control in _pads.values():
		pad.visible = false
	if _start != null:
		_start.visible = false
		_start.disabled = true
	# And the HOUSE, until the payoff. In the prototype it can only start the
	# job again, and a child taps every round green thing on the screen: one
	# tap threw sixty stops of their work away (the improvement plan's 0.1).
	hide_home()


## The house button: off the screen while the job runs, back beside NEXT once
## the job is done, where "again" is the one thing it can mean. When the title
## screen is ported it becomes the way there - as a press-and-HOLD, because
## any control that throws work away is a hold and never a tap.
func show_home() -> void:
	if _home == null:
		return
	_home.visible = true
	_home.pivot_offset = _home.size * 0.5
	_home.scale = Vector2(0.01, 0.01)
	var tw := create_tween()
	tw.tween_property(_home, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_home() -> void:
	if _home != null:
		_home.visible = false


func home_visible() -> bool:
	return _home != null and _home.visible


# --- The pads ------------------------------------------------------------------------------

## Shows the pads a beat uses and hides the rest, so the only arrows on screen
## are ones that do something. `wanted` is a list of "up" / "down" / "left" /
## "right"; an empty list puts them all away.
func show_pads(wanted: Array) -> void:
	for key: String in _pads.keys():
		var pad: Control = _pads[key]
		pad.visible = key in wanted
	set_pads_enabled(not wanted.is_empty())


func pad_visible(key: String) -> bool:
	var pad: Control = _pads.get(key)
	return pad != null and pad.visible


# --- The GO button -------------------------------------------------------------------------

## A round button in the bottom-LEFT corner, `s` across. Both it and NEXT share
## ONE centre - the GO button's - however big each is.
## GO and NEXT stand in the same corner the "down" pad uses, so both walk in off
## the same insets (6.4) or the child's learned spot moves between beats.
func place_in_safe_area() -> void:
	super()
	if _go != null:
		_corner(_go, go_size)
	if _next != null:
		_corner(_next, start_size * 0.8)


func _corner(button: Button, s: float) -> void:
	var safe := SafeArea.insets(get_viewport())
	var left := corner_margin + safe.x
	var bottom := corner_margin + safe.w
	var c := left + go_size * 0.5
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = c - s * 0.5
	button.offset_right = c + s * 0.5
	button.offset_top = -go_size - bottom + (go_size - s) * 0.5
	button.offset_bottom = -bottom - (go_size - s) * 0.5
	button.pivot_offset = Vector2(s, s) * 0.5


func _build_go() -> void:
	var s := go_size
	_go = _round_button("Go", s, go_color)
	_corner(_go, s)
	_go.pressed.connect(_on_go)
	# The machine itself, low-poly, in the button (fourth playtest); the drawn
	# glyph only for a build that cannot find the models.
	for key: String in MachineIcons.KEYS:
		var icon := MachineIcons.dress(_go, key, s, go_color)
		if icon != null:
			icon.visible = false
			_icons[key] = icon
	if _icons.size() < MachineIcons.KEYS.size():
		var glyph := TruckGlyph.new()
		glyph.name = "Truck"
		glyph.ink = Color(0.16, 0.46, 0.22)
		glyph.detail = go_color
		_glyph = glyph
		glyph.size = Vector2(s, s)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_go.add_child(glyph)
	_go.visible = false
	_go.disabled = true
	_root.add_child(_go)


func _on_go() -> void:
	if not _go.visible or not _go_enabled:
		return
	if _go_tween != null and _go_tween.is_valid():
		_go_tween.kill()
	_go.scale = Vector2(0.86, 0.86)
	_go_tween = create_tween()
	_go_tween.tween_property(_go, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	go_pressed.emit()


func _set_go_enabled(on: bool) -> void:
	_go_enabled = on
	_go.disabled = not on
	# Faint AND small rather than merely dimmed, so it is clearly not the answer
	# yet while staying in exactly the spot the child has learned.
	_go.modulate = Color(1.0, 1.0, 1.0, 1.0 if on else 0.26)
	if _go_tween != null and _go_tween.is_valid():
		_go_tween.kill()
	_go_tween = create_tween()
	_go_tween.tween_property(_go, "scale",
		Vector2.ONE if on else Vector2(go_sleep_scale, go_sleep_scale), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_go() -> void:
	if _go_tween != null and _go_tween.is_valid():
		_go_tween.kill()
	_go.visible = true
	_go.scale = Vector2(0.01, 0.01)
	_go_tween = create_tween()
	_go_tween.tween_property(_go, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## One corner slot, one button at a time. The button a BUTTON step waits for is
## shown awake; "" sends it to sleep IN PLACE - dim and deaf, but still the
## button the child has learned.
## The picture on the call button: the machine the CURRENT step calls, by its
## verb - the skid steer's blade, the tipper's raised bed, the mixer's drum.
func set_call_glyph(verb: String) -> void:
	if verb == "":
		return
	var kind := MachineIcons.kind_for(verb)
	for k: String in _icons:
		(_icons[k] as Control).visible = k == kind
	if _glyph != null:
		# The drawn glyph only stands in for a model that did not load.
		_glyph.visible = not _icons.has(kind)
		if _glyph.kind != kind:
			_glyph.kind = kind
			_glyph.queue_redraw()


## Is the call button showing a real model (tests: the drawn fallback is
## silent by design, so a missing GLB would put the flat truck back unnoticed).
func call_is_modelled() -> bool:
	for k: String in _icons:
		var icon := _icons[k] as PropIcon
		if icon.visible and icon.is_modelled():
			return true
	return false


func arm_button(id: String) -> void:
	match id:
		"call":
			if not _go.visible:
				_show_go()
			_set_go_enabled(true)
		_:
			if _go.visible and _go_enabled:
				_set_go_enabled(false)


func hide_buttons() -> void:
	_go.visible = false
	_go_enabled = false


func button_enabled(id: String) -> bool:
	match id:
		"call":
			return _go.visible and _go_enabled
		"next":
			return next_visible()
		_:
			return false


## Where the named button really is on the screen, in viewport pixels: the play
## probe clicks these, which is the only way to prove that a tap on a button
## does what a call to `simulate_button` does.
func button_rect(id: String) -> Rect2:
	match id:
		"call":
			return _go.get_global_rect() if _go != null else Rect2()
		"next":
			return next_rect()
		_:
			return Rect2()


func simulate_button(id: String) -> void:
	match id:
		"call":
			_on_go()
		"next":
			simulate_next()
		_:
			pass


## The named button is the answer: a pulsing ring goes on it.
func point_at_button(id: String) -> void:
	match id:
		"call":
			_aim = Aim.GO
			if pointer != null:
				pointer.clear_rings()
		"next":
			point_at_next()
		_:
			hide_arrow()


## A tap that landed on the picture while a BUTTON beat is waiting: the button
## kicks, the way the arrow bounces harder for a miss in the world.
## A pad kicks, the way the call button does: the answer to a tap on the
## picture during the pour is "this one" (the improvement plan's 2.1).
func nudge_pad(key: String) -> void:
	var pad: Control = _pads.get(key)
	if pad == null or not pad.visible:
		return
	pad.pivot_offset = pad.size * 0.5
	pad.scale = Vector2(1.18, 1.18)
	var tw := create_tween()
	tw.tween_property(pad, "scale", Vector2.ONE, 0.34) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Where a pad is on the screen, in viewport pixels, or nothing when it is
## not up.
func pad_rect(key: String) -> Rect2:
	var pad: Control = _pads.get(key)
	if pad == null or not pad.visible:
		return Rect2()
	return pad.get_global_rect()


## NEXT kicks, the way GO does: a tap that missed it during the payoff is
## answered by the one thing there is to press.
func nudge_next() -> void:
	if _next == null or not _next.visible:
		return
	_next.pivot_offset = _next.size * 0.5
	_next.scale = Vector2(1.18, 1.18)
	var tw := create_tween()
	tw.tween_property(_next, "scale", Vector2.ONE, 0.34) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func nudge_button() -> void:
	if _go == null or not _go.visible:
		return
	if _go_tween != null and _go_tween.is_valid():
		_go_tween.kill()
	_go.scale = Vector2(1.18, 1.18)
	_go_tween = create_tween()
	_go_tween.tween_property(_go, "scale", Vector2.ONE, 0.34) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func go_rect() -> Rect2:
	return _go.get_global_rect() if _go != null else Rect2()


func next_rect() -> Rect2:
	return _next.get_global_rect() if _next != null else Rect2()


# --- The arrow ---------------------------------------------------------------------------

func _build_arrow() -> void:
	_ring = PulseRing.new()
	_ring.name = "ButtonRing"
	_ring.color = ring_color
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.visible = false
	_root.add_child(_ring)
	_hint = HintArrow.new()
	_hint.name = "IdleArrow"
	_hint.color = hint_color
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	_root.add_child(_hint)


## Bounce over a point in the world. `radius` is how big that thing is in
## metres, so the arrow is sized to it; `centre` is what it stands off FROM
## (`INF` means it simply hangs above the thing, which is right for everything
## on a flat slab).
func point_at(world: Vector3, radius: float = 0.0, centre: Vector3 = Vector3.INF,
		with_ring: bool = true) -> void:
	var same := _aim == Aim.WORLD and _aim_ring == with_ring and absf(_aim_radius - radius) < 0.001
	_aim = Aim.WORLD
	_aim_world = world
	_aim_radius = radius
	_aim_centre = centre
	_aim_ring = with_ring
	_ring.visible = false
	if pointer == null:
		return
	# A mark that is already up is MOVED, not rebuilt: rebuilding it every frame
	# restarts its bob on every one of them (the pour's hint is re-pointed every
	# frame the child is still).
	if same and pointer.one_up():
		pointer.move_one(world + Vector3(0.0, 0.06, 0.0))
		return
	pointer.show_one(world + Vector3(0.0, 0.06, 0.0), hint_size_for(radius), with_ring)


## How big the ring is over a target `radius` metres across.
func hint_size_for(radius: float) -> float:
	return clampf(radius * hint_of_target, hint_min, hint_max)


func point_at_next() -> void:
	_aim = Aim.NEXT
	if pointer != null:
		pointer.clear_rings()


func hide_arrow() -> void:
	_aim = Aim.NONE
	_ring.visible = false
	if pointer != null:
		pointer.clear_rings()


## Takes the YAY! banner off the screen NOW, rather than letting its own tween
## fade it out in its own time.
func clear_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.text = ""
	_flash.visible = false


func arrow_visible() -> bool:
	return pointer != null and pointer.lit()


## Is ANYTHING telling the child where to go - the arrow over a thing on the
## site, or the ring on a button? This is what a test should ask.
func aim_visible() -> bool:
	return arrow_visible() or _ring.visible


func ring_visible() -> bool:
	return _ring.visible


## Is the HUD being ASKED to point at a thing on the site right now?
##
## Not the same question as `arrow_visible()`: the arrow takes itself off the
## screen when its target is outside the picture, and a headless run's viewport
## is SQUARE, so a target plainly in frame on a 16:9 screen can be off the side
## of the one a test is looking at. This says what the RUNNER asked for.
func aiming_at_world() -> bool:
	return _aim == Aim.WORLD


func aiming_at_button() -> bool:
	return _aim == Aim.GO or _aim == Aim.NEXT


## A tap away from the thing: the arrow bounces harder for a moment, so the
## finger is told where to go. A miss is never silent and never punished.
func nudge_arrow() -> void:
	_nudge_left = arrow_nudge_time
	if pointer != null:
		pointer.nudge(arrow_nudge_time)


func arrow_nudged() -> bool:
	return _nudge_left > 0.0


## Did a finger land on the MARK itself, rather than on the thing under it? The
## ring and its arrow stand a little above the work, so pressing the gold has to
## count as pressing what it is pointing at.
func arrow_hit(screen: Vector2, margin: float = 0.0) -> bool:
	var frame := get_viewport().get_visible_rect().size
	var reach := minf(frame.x, frame.y) * hint_touch + margin
	# A finger on the white arrow counts as a finger on the thing it points at -
	# anywhere along its BODY, which runs away from the ring from the touch point
	# and swings further out on the mime, and not only round the touch point
	# itself (the improvement plan's 0.5: the wedge said "tap here", and a tap on
	# its far end was a miss).
	if hint_visible():
		var body := _hint.arrow_size * (HintArrow.BACK + HintArrow.BACK_OFF * 2.0)
		if _segment_distance(screen, _hint.position, _hint.position + _hint_body * body) \
				<= reach + _hint.arrow_size * 0.6:
			return true
	if _aim != Aim.WORLD or pointer == null or not pointer.lit() or camera == null:
		return false
	return pointer.pick_nearest(camera, screen, reach) != 0


## How far `p` is from the segment `a`-`b`.
static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## While a beat is live the HUD steps back and the picture is the tool.
func set_working(on: bool) -> void:
	if _chrome_locked:
		return
	_chrome_target = chrome_working if on else 1.0


## The chrome goes - and stays gone - for the payoff.
func set_chrome_target(a: float, lock: bool = false) -> void:
	_chrome_target = clampf(a, 0.0, 1.0)
	if lock:
		_chrome_locked = true


func chrome_alpha() -> float:
	return _bar.modulate.a if _bar != null else 1.0


func _process(delta: float) -> void:
	_arrow_t += delta
	_nudge_left = maxf(_nudge_left - delta, 0.0)
	if _bar != null:
		# The hat is the bar's child, so it takes the same modulate.
		_bar.modulate.a = move_toward(_bar.modulate.a, _chrome_target, delta / 0.2)
	_aim_at = Vector2.INF
	match _aim:
		Aim.NONE:
			pass
		Aim.GO:
			_pulse_on(_go)
		Aim.NEXT:
			_pulse_on(_next)
		Aim.WORLD:
			# The mark is a node in the world and moves itself; all that is left
			# here is keeping it on a target that moves (the rubble a blade is
			# pushing, the chute's emptiest corner).
			if pointer != null and pointer.lit():
				pointer.move_one(_aim_world + Vector3(0.0, 0.06, 0.0))
			_aim_screen(_aim_world)
	# One arrow at a time: the pointer's gold arrow stands aside while the white
	# one is up. The ring stays.
	if pointer != null:
		pointer.set_arrow_shown(not hint_visible())


## Where a world target is on the screen, for the white arrow: its point rests
## just clear of the ring's rim, from above unless the wedge would leave the
## top of the picture, then from below. Nothing when the target is outside the
## picture's margin.
func _aim_screen(world: Vector3) -> void:
	var frame := get_viewport().get_visible_rect().size
	var p := project_into(frame, world)
	if p.z <= 0.0:
		return
	var at := Vector2(p.x, p.y)
	# The band the hardware takes is not the picture (6.4): a mime drawn on a
	# phone's Island is a mime nobody sees.
	var ins := SafeArea.insets(get_viewport())
	var safe := Rect2(Vector2(ins.x, ins.y), frame - Vector2(ins.x + ins.z, ins.y + ins.w)).grow(-hint_margin)
	if not safe.has_point(at):
		return
	var fit := clampf(p.z / SpotRings.NOMINAL_M, 0.5, 3.0)
	var r_px := hint_size_for(_aim_radius) * 0.5 * fit * pixels_per_metre(frame, p.z)
	_aim_size = hint_arrow_px
	_aim_touch = r_px + hint_gap
	if _hint_dir_for != world or _aim_dir == Vector2.ZERO:
		_hint_dir_for = world
		_aim_dir = Vector2.UP
		var reach := _aim_touch + _aim_size * hint_scale * (HintArrow.BACK + HintArrow.BACK_OFF)
		if at.y - reach < safe.position.y + hint_margin:
			_aim_dir = Vector2.DOWN
	_aim_at = at


## The idle clock and the mime. `kind` is what the level says the child should
## do now; `world` is a rings beat's first live ring (INF for the pointer's
## own target). The clock runs while nothing is aimed, so on a drag beat the
## white arrow lands `hint_delay` after the finger lifts, not after the ring
## has also waited its own turn.
func hint_tick(delta: float, kind: Hint, world: Vector3 = Vector3.INF,
		swipe_axis: Vector2 = Vector2.RIGHT, rect: Rect2 = Rect2()) -> void:
	if _hint == null:
		return
	_hint.swipe_axis = swipe_axis
	if world != Vector3.INF:
		_aim_screen(world)
	elif rect.has_area():
		_aim_rect(rect)
	if kind != _hint_kind:
		_hint_kind = kind
		hint_wake()
	_hint_idle += delta
	if kind == Hint.NONE or _aim_at == Vector2.INF:
		_hint.visible = false
		return
	if _hint_idle < hint_delay:
		_hint.visible = false
		return
	_hint.alpha = clampf((_hint_idle - hint_delay) / 0.2, 0.0, 1.0)
	_hint_t = fmod(_hint_t + delta, maxf(hint_cycle + hint_rest, 0.1))
	var frame := get_viewport().get_visible_rect().size
	var d := _aim_dir.normalized() if _aim_dir.length_squared() > 0.0001 else Vector2.UP
	_hint.kind = kind
	_hint.color = hint_color
	_hint.arrow_size = _aim_size * hint_scale
	_hint.swipe = hint_swipe * minf(frame.x, frame.y)
	_hint.phase = _hint_t / maxf(hint_cycle, 0.1)
	_hint.position = _aim_at + d * _aim_touch
	_hint_body = d
	_hint.rotation = atan2(-d.y, -d.x) - PI * 0.5
	_hint.visible = true
	_hint.queue_redraw()


## The white arrow over a CONTROL - one of the pour's pads - rather than over a
## place in the world: it comes at a bottom-left pad from the upper right and at
## a bottom-right pad from the upper left, out of the picture's own middle.
func _aim_rect(r: Rect2) -> void:
	var frame := get_viewport().get_visible_rect().size
	_aim_at = r.get_center()
	_aim_dir = Vector2(0.6, -0.8) if _aim_at.x < frame.x * 0.5 else Vector2(-0.6, -0.8)
	_aim_touch = r.size.x * 0.5 + hint_gap
	_aim_size = hint_arrow_px
	_hint_dir_for = Vector3.INF


## A miss: the mime's clock runs FORWARD, never back. One miss brings it a
## second early; a second miss inside three seconds brings it at once. The
## child who most needs to be shown is the one tapping the wrong thing, and a
## clock that restarted on every wrong tap could never reach them (the
## improvement plan's 1.2).
func hint_hurry() -> void:
	var now := float(Time.get_ticks_msec()) / 1000.0
	if now - _last_miss_s < 3.0:
		_hint_idle = maxf(_hint_idle, hint_delay)
	else:
		_hint_idle = maxf(_hint_idle, hint_delay - 1.0)
	_last_miss_s = now


## The child did something: the clock starts again and the mime goes.
func hint_wake() -> void:
	_hint_idle = 0.0
	_hint_t = 0.0
	if _hint != null:
		_hint.visible = false


func hide_hint() -> void:
	_hint_kind = Hint.NONE
	hint_wake()


func hint_visible() -> bool:
	return _hint != null and _hint.visible


func hint_kind() -> Hint:
	return _hint_kind


## Where the white arrow's point touches, in viewport pixels (INF when down).
func hint_position() -> Vector2:
	return _hint.position if hint_visible() else Vector2.INF


## Where the wedge's tip is drawn right now, mime included.
func hint_tip_now() -> Vector2:
	if not hint_visible():
		return Vector2.INF
	return _hint.position + _hint.offset_now().rotated(_hint.rotation)


func hint_color_now() -> Color:
	return _hint.color if _hint != null else Color.BLACK


func hint_idle() -> float:
	return _hint_idle


## The ring, centred on a round button, or nothing when that button is not up.
func _pulse_on(button: Button) -> void:
	if button == null or not button.is_visible_in_tree():
		_ring.visible = false
		return
	var r := button.get_global_rect()
	# A little bigger than the button, so the ring reads as a halo around it and
	# never as a second control drawn on top of it.
	var pad := r.size.x * 0.22
	_ring.position = r.position - Vector2(pad, pad)
	_ring.size = r.size + Vector2(pad, pad) * 2.0
	_ring.phase = fmod(_arrow_t * ring_rate, 1.0)
	_ring.queue_redraw()
	_ring.visible = true
	# The white arrow comes at a bottom-left button from above-right.
	_aim_at = r.get_center()
	_aim_dir = Vector2(0.6, -0.8)
	_aim_touch = r.size.x * 0.5 + hint_gap
	_aim_size = hint_arrow_px


## Where a world point lands in a picture `frame` pixels across, and how far in
## front of the lens it is. `z` <= 0 means behind it (nothing to draw).
func project_into(frame: Vector2, world: Vector3) -> Vector3:
	if camera == null or not is_instance_valid(camera):
		return Vector3(0.0, 0.0, -1.0)
	var b := camera.global_transform.basis
	var v := world - camera.global_position
	var depth := v.dot(-b.z)
	if depth <= 0.01:
		return Vector3(0.0, 0.0, -1.0)
	# The camera keeps its WIDTH (`SiteMain._ready`): `fov` is the horizontal
	# angle and the vertical one follows the frame, so a 4:3 iPad sees more
	# above and below the same 16:9 picture rather than losing its sides.
	var tan_v := _tan_half_v(frame)
	var half := frame * 0.5
	return Vector3(
		half.x + (v.dot(b.x) / depth) / (tan_v * frame.x / frame.y) * half.x,
		half.y - (v.dot(b.y) / depth) / tan_v * half.y,
		depth)


## How many pixels of a `frame`-tall picture one metre covers at `depth`.
func pixels_per_metre(frame: Vector2, depth: float) -> float:
	if camera == null or not is_instance_valid(camera):
		return 0.0
	return (frame.y * 0.5) / (_tan_half_v(frame) * maxf(depth, 0.05))


## The tangent of half the VERTICAL field of view for this frame, whichever
## axis the camera keeps.
func _tan_half_v(frame: Vector2) -> float:
	var t := tan(deg_to_rad(camera.fov) * 0.5)
	if camera.keep_aspect == Camera3D.KEEP_WIDTH:
		return t * frame.y / maxf(frame.x, 1.0)
	return t


## The bar's stump becomes a slab with a broom finish.
func _swap_bar_icon() -> void:
	var old := _bar.get_node_or_null("StumpIcon")
	if old != null:
		old.queue_free()
	var icon := SlabIcon.new()
	icon.name = "SlabIcon"
	icon.size = Vector2(44.0, 40.0)
	icon.position = Vector2(-56.0, -7.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(icon)


## How long the job the level loaded is, in progress steps. The bar always fills
## exactly once per job, whatever job that is.
func set_total_steps(n: int) -> void:
	_total_steps = maxi(n, 1)


func total_steps() -> int:
	return _total_steps


func set_step(step: int) -> void:
	set_progress(float(clampi(step, 0, _total_steps)) / float(_total_steps))


func step_value() -> float:
	return _bar.value


# --- Drawn bits ----------------------------------------------------------------------------

## The GO button's picture: a dump truck, side on - a cab, a tipped body and two
## wheels. A machine, which is what the button brings.
class TruckGlyph extends Control:
	## `skid`, `dump` or `mixer`: which machine this button brings.
	var kind: String = "dump"
	## The glyph's colour, and the colour of the details cut into it.
	var ink: Color = Color.WHITE
	var detail: Color = Color(0.18, 0.34, 0.22)

	func _draw() -> void:
		var s := size.x
		var c := ink
		var dark := detail
		match kind:
			"skid":
				# A skid steer in profile: a boxy body on two wheels, then
				# DAYLIGHT, then an angled blade standing at the front on a thin
				# arm (rounds 6, 8, 9: a body joined to a block read as an H, then
				# as a locomotive).
				# ...and a CAB standing up at the back with a window in it, the
				# wheels apart with hubs, so it is a machine and not an "H"
				# (round 10).
				draw_rect(Rect2(s * 0.16, s * 0.46, s * 0.34, s * 0.16), c)
				var cab: PackedVector2Array = PackedVector2Array([
					Vector2(s * 0.19, s * 0.47), Vector2(s * 0.23, s * 0.27),
					Vector2(s * 0.43, s * 0.27), Vector2(s * 0.47, s * 0.47)])
				draw_colored_polygon(cab, c)
				draw_rect(Rect2(s * 0.26, s * 0.31, s * 0.13, s * 0.10), dark)
				draw_circle(Vector2(s * 0.24, s * 0.67), s * 0.075, c)
				draw_circle(Vector2(s * 0.42, s * 0.67), s * 0.075, c)
				draw_circle(Vector2(s * 0.24, s * 0.67), s * 0.028, dark)
				draw_circle(Vector2(s * 0.42, s * 0.67), s * 0.028, dark)
				draw_line(Vector2(s * 0.50, s * 0.53), Vector2(s * 0.66, s * 0.51), c, s * 0.04, true)
				var blade: PackedVector2Array = PackedVector2Array([
					Vector2(s * 0.64, s * 0.33), Vector2(s * 0.76, s * 0.36),
					Vector2(s * 0.73, s * 0.72), Vector2(s * 0.61, s * 0.69)])
				draw_colored_polygon(blade, c)
			"mixer":
				# A mixer: a cab, a ROUND drum (round 8: a slanted box was the
				# tipper's silhouette with a stick on it), a chute off the back.
				draw_rect(Rect2(s * 0.20, s * 0.46, s * 0.14, s * 0.15), c)
				draw_circle(Vector2(s * 0.54, s * 0.46), s * 0.16, c)
				draw_rect(Rect2(s * 0.34, s * 0.54, s * 0.40, s * 0.08), c)
				draw_line(Vector2(s * 0.68, s * 0.50), Vector2(s * 0.82, s * 0.66), c, s * 0.05, true)
				draw_circle(Vector2(s * 0.30, s * 0.66), s * 0.06, c)
				draw_circle(Vector2(s * 0.50, s * 0.66), s * 0.06, c)
				draw_circle(Vector2(s * 0.64, s * 0.66), s * 0.06, c)
			_:
				# A tipper with its bed UP, so it is unmistakably the one that dumps.
				var body: PackedVector2Array = PackedVector2Array([
					Vector2(s * 0.34, s * 0.60), Vector2(s * 0.44, s * 0.36),
					Vector2(s * 0.78, s * 0.30), Vector2(s * 0.74, s * 0.60)])
				draw_colored_polygon(body, c)
				draw_rect(Rect2(s * 0.20, s * 0.44, s * 0.13, s * 0.16), c)
				draw_rect(Rect2(s * 0.225, s * 0.47, s * 0.075, s * 0.06), dark)
				draw_circle(Vector2(s * 0.30, s * 0.64), s * 0.065, c)
				draw_circle(Vector2(s * 0.63, s * 0.64), s * 0.065, c)
				draw_circle(Vector2(s * 0.30, s * 0.64), s * 0.026, dark)
				draw_circle(Vector2(s * 0.63, s * 0.64), s * 0.026, dark)


## The white idle arrow: Car Garage's gold wedge drawn white with a dark rim,
## its tip at the Control's origin and its body along -Y; the HUD turns it so
## the wedge points back down at the thing. The motion IS the mime
## (`offset_now`): a tap comes in and out, a hold comes in and stays, a drag
## slides across.
class HintArrow extends Control:
	## The wedge in units of `arrow_size`, tip at the origin, body along -Y.
	const SHAPE: Array = [
		Vector2(0.0, 0.0), Vector2(-0.42, -0.52), Vector2(-0.16, -0.52),
		Vector2(-0.16, -1.02), Vector2(0.16, -1.02), Vector2(0.16, -0.52),
		Vector2(0.42, -0.52),
	]
	const CENTROID := Vector2(0.0, -0.588571)
	const RIM := 1.13
	const HALF_W := 0.4746
	const BACK := 1.0757
	const FRONT := 0.0766
	## How far off the thing the point stands before it comes in, in wedges.
	const BACK_OFF := 0.7

	var kind: Hint = Hint.TAP
	## How big the wedge is, pixels, and how far a swipe carries it either way.
	var arrow_size: float = 70.0
	var swipe: float = 90.0
	## Which way a DRAG mime slides, in the wedge's own frame (the HUD turns
	## the wedge only 0 or half a turn, so this is the screen axis too).
	var swipe_axis: Vector2 = Vector2.RIGHT
	var phase: float = 0.0
	var alpha: float = 1.0
	var color: Color = Color(1.0, 1.0, 1.0)
	var rim: Color = Color(0.14, 0.10, 0.03)

	## Where the point is at `phase`, in this Control's own frame (0,0 touching).
	func offset_now() -> Vector2:
		var work := clampf(phase, 0.0, 1.0)
		var out := arrow_size * BACK_OFF
		match kind:
			Hint.DRAG:
				return swipe_axis * (sin(work * TAU * 2.0) * swipe)
			Hint.WIGGLE:
				return Vector2(sin(work * TAU * 3.0) * swipe * 0.38, 0.0)
			Hint.HOLD:
				# In over the first third, held there, and back out at the end.
				var k := _ease_out(clampf(work / 0.33, 0.0, 1.0)) \
					* (1.0 - _ease_in(clampf((work - 0.82) / 0.18, 0.0, 1.0)))
				return Vector2(0.0, -out * (1.0 - k))
			_:
				# In, out, in, out: |cos| twice across the mime.
				return Vector2(0.0, -out * absf(cos(work * TAU)))

	func _draw() -> void:
		var fade := clampf(alpha, 0.0, 1.0)
		var off := offset_now()
		_draw_touch(off, fade)
		var s := arrow_size
		var head := PackedVector2Array()
		var edge := PackedVector2Array()
		for u: Vector2 in SHAPE:
			head.append(off + u * s)
			edge.append(off + (CENTROID + (u - CENTROID) * RIM) * s)
		var r := rim
		r.a *= fade
		var c := color
		c.a *= fade
		draw_colored_polygon(edge, r)
		draw_colored_polygon(head, c)

	## The ring at the point: a tap's snaps out of it as it touches, a hold's
	## closes on it and stays; a swipe and a wiggle draw none.
	func _draw_touch(off: Vector2, fade: float) -> void:
		var s := arrow_size
		var c := color
		var width := maxf(s * 0.06, 2.0)
		if kind == Hint.HOLD:
			var k := clampf(-off.y / maxf(s * BACK_OFF, 1.0), 0.0, 1.0)
			c.a = 0.75 * fade * (1.0 - k)
			draw_arc(Vector2(0.0, s * 0.12), lerpf(s * 0.18, s * 0.6, k), 0.0, TAU, 32, c, width, true)
		elif kind == Hint.TAP:
			var near := 1.0 - clampf(-off.y / maxf(s * BACK_OFF, 1.0), 0.0, 1.0)
			c.a = 0.75 * fade * near
			draw_arc(Vector2(0.0, s * 0.12), lerpf(s * 0.5, s * 0.15, near), 0.0, TAU, 32, c, width, true)

	static func _ease_out(k: float) -> float:
		return 1.0 - (1.0 - k) * (1.0 - k)

	static func _ease_in(k: float) -> float:
		return k * k


## The pulsing halo on the round button when it is the answer: two rings
## breathing out of its edge, so the button says "me" without anything being
## drawn on top of it.
class PulseRing extends Control:
	var color: Color = Color(1.0, 0.84, 0.22)
	## 0 .. 1, walked by the HUD.
	var phase: float = 0.0

	func _draw() -> void:
		var c := size * 0.5
		var r0 := minf(size.x, size.y) * 0.36
		var r1 := minf(size.x, size.y) * 0.5
		for i in range(2):
			var k := fmod(phase + 0.5 * float(i), 1.0)
			var r := lerpf(r0, r1, k)
			var a := (1.0 - k) * 0.85
			draw_arc(c, r, 0.0, TAU, 40, Color(color.r, color.g, color.b, a), 6.0, true)


## A slab of concrete with broom lines across it, seen in perspective: the thing
## the bar is filling up.
class SlabIcon extends Control:
	## A yellow HARD HAT: the one thing that says "building site" at any size.
	## (A slab in perspective read as a floor drain - round 4.)
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var yellow := Color(0.98, 0.78, 0.12)
		var rim := Color(0.26, 0.17, 0.09)
		var cx := w * 0.5
		var dome_r := w * 0.34
		var dome_c := Vector2(cx, h * 0.62)
		draw_circle(dome_c, dome_r + 2.0, rim)
		draw_circle(dome_c, dome_r, yellow)
		draw_rect(Rect2(cx - dome_r - 2.0, h * 0.62, dome_r * 2.0 + 4.0, h * 0.3), Color(0.0, 0.0, 0.0, 0.0))
		# Cut the dome to a half: paint the lower half back out with the brim.
		draw_rect(Rect2(w * 0.04, h * 0.60, w * 0.92, h * 0.16), rim)
		draw_rect(Rect2(w * 0.07, h * 0.63, w * 0.86, h * 0.10), yellow)
		# The ridge down the middle.
		draw_rect(Rect2(cx - w * 0.05, h * 0.30, w * 0.10, h * 0.32), Color(0.90, 0.68, 0.08))
