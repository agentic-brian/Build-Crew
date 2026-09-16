class_name StartMenu
extends CanvasLayer
## The title row (the improvement plan's 6.3): the lot idling behind a soft
## tint, and on it one big round disc per job in `data/jobs/jobs.json`, each
## carrying that job's own machine (`JobIcons`). Car Garage's `start_menu.gd`
## is the pattern - the same seat maths, the same breathing, the same full-rect
## root that keeps a stray finger off the world behind it.
##
## WHAT IS NOT HERE, and why: no words (a three-year-old cannot read one, and
## the game's name is 6.4's decision, not this row's); no maker's mark, trust
## ribbon or wordmark (they are words, and pictures of words - 6.4); no second
## word-card page (Tree Crew deleted its as a one-way door); no fade - the menu
## never dissolves, the cut to the job is the event; and no greyed-out seats for
## jobs that do not exist yet, which would read as "unlock" in a family that
## sells nothing.
##
## THE TAP IS ALWAYS THE SAFE THING. A press on a job's disc starts that drive,
## or carries on the one the child left. Throwing a half-built drive away is a
## second, smaller disc in the other corner, HELD (`HOLD_TIME`) with a ring
## filling round it - never the big one a child reaches for first, because in
## this game holding is how every piece of work is done.

## A job's disc was pressed: start (or carry on) that job.
signal seat_pressed(job: String)
## The "new drive" disc was held to the end: the saved job is to be thrown away.
signal fresh_pressed

## Where the row stands, as fractions of the screen. Car Garage centres its row
## at 0.52 with a title word above it; there is no word here, and the row must
## not stand ON the drive it is a picture of - the drive runs up the right of
## every shot this screen uses, so the row sits on the LEFT lawn, low.
const ROW_ANCHOR := 0.70
const ROW_X := 0.30
## How long the "new drive" disc is held: the family's own number for a
## press-and-hold that throws work away (the plan's 0.1).
const HOLD_TIME := 0.9
## A miss is heard, once per gap, never punished.
const MISS_GAP := 0.25

## How big a seat is at most, and how far apart they stand.
@export var button_size: float = 250.0
@export var button_gap: float = 56.0
## How far the corner disc stands off the edge, before the safe area is added.
@export var corner_margin: float = 44.0

var _root: Control
var _seats: Dictionary = {}
var _fresh: Button
var _fresh_ring: Control
var _keys: PackedStringArray = PackedStringArray()
var _sfx: Node
var _time: float = 0.0
var _hold: float = 0.0
var _holding: bool = false
var _spent: bool = false
var _miss_at: float = -10.0


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.name = "MenuRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Eats every stray tap, so none reaches the lot idling behind it.
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_root_input)
	add_child(_root)
	var tint := ColorRect.new()
	tint.name = "Tint"
	# Lighter than Car Garage's 0.34: there is no cream text to read over it,
	# and the lot IS the picture on this screen.
	tint.color = Color(0.04, 0.05, 0.07, 0.22)
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tint)
	_keys = JobIcons.keys()
	_build_row()
	_build_fresh()
	set_mode(false)
	# A phone turned over puts the hardware's edges somewhere else (6.4).
	get_viewport().size_changed.connect(place_in_safe_area)


func set_sfx(node: Node) -> void:
	_sfx = node


## Is there a job to carry on with? The "new drive" disc only exists then: with
## nothing saved, the one disc on the screen already starts a new drive.
func set_mode(carry_on: bool) -> void:
	if _fresh != null:
		_fresh.visible = carry_on
		# Only `visible` stops a `SubViewport` rendering its private 3D world.
		var icon := _fresh.get_node_or_null("Prop_fresh") as Control
		if icon != null:
			icon.visible = carry_on
	_hold = 0.0
	_holding = false
	_spent = false
	if _fresh_ring != null:
		_fresh_ring.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var i := 0
	for key: String in _keys:
		var b := _seats.get(key) as Button
		if b != null and not b.has_meta("pressing"):
			# They breathe out of step, so none reads as THE one. Never past
			# 1.05: a seat that grew into the gap would touch its neighbour.
			var k := 1.0 + 0.045 * sin(_time * 3.2 + float(i) * 1.9)
			b.scale = Vector2(k, k)
		i += 1
	if _holding and not _spent:
		_hold += delta
		if _fresh_ring != null:
			_fresh_ring.queue_redraw()
		if _hold >= HOLD_TIME:
			_spent = true
			_holding = false
			_play("breaker")
			fresh_pressed.emit()


## GO answers the first seat even before a controller has been touched: a bare
## keyboard press still has to work. Read as an EVENT, never polled.
func _unhandled_input(event: InputEvent) -> void:
	if Pad.go_event(event) and not _keys.is_empty():
		_press_seat(_keys[0])


## Where the finger holding the "new drive" disc has got to. A `Button` never
## sees a touch DRAG (it is not a gui event for it), so a finger that slides off
## the disc would go on filling the ring from the lawn; watched here, and the
## event is left alone for whoever else wants it.
func _input(event: InputEvent) -> void:
	if not _holding or _spent or _fresh == null:
		return
	var at := Vector2.INF
	if event is InputEventScreenDrag:
		at = (event as InputEventScreenDrag).position
	elif event is InputEventMouseMotion:
		at = (event as InputEventMouseMotion).position
	if at != Vector2.INF and not _fresh.get_global_rect().has_point(at):
		_on_fresh_up()


# --- The row -----------------------------------------------------------------------------

## How wide one seat is: the row fills 94% of the screen and every seat shrinks
## to fit, floored at 90 px (Car Garage's own rule, so a fourth job still fits).
func seat_size() -> float:
	var vw := get_viewport().get_visible_rect().size.x
	var seats := maxf(float(_keys.size()), 1.0)
	return minf(button_size, maxf((vw * 0.94 - (seats - 1.0) * button_gap) / seats, 90.0))


func _build_row() -> void:
	var s := seat_size()
	var step := s + button_gap
	var first := -step * (float(_keys.size()) - 1.0) * 0.5
	for i in range(_keys.size()):
		var key := _keys[i]
		var b := _seat(key, first + step * float(i), s)
		_seats[key] = b
		if JobIcons.dress(b, key, s) == null:
			# Never a hole: the HUD's own drawn machine stands in instead.
			var glyph := SiteHud.TruckGlyph.new()
			glyph.name = "Glyph"
			glyph.kind = JobIcons.hero(key)
			glyph.ink = Brand.CREAM
			glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(glyph)
		b.pressed.connect(_press_seat.bind(key))


## One big round disc of the row, centred `at` pixels from the middle.
func _seat(key: String, at: float, s: float) -> Button:
	var b := Button.new()
	b.name = "Seat_" + key
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(s, s)
	b.anchor_left = ROW_X
	b.anchor_right = ROW_X
	b.anchor_top = ROW_ANCHOR
	b.anchor_bottom = ROW_ANCHOR
	b.offset_left = at - s * 0.5
	b.offset_right = at + s * 0.5
	b.offset_top = -s * 0.5
	b.offset_bottom = s * 0.5
	b.pivot_offset = Vector2(s, s) * 0.5
	Brand.dress_button(b, JobIcons.disc(key), int(s * 0.5))
	_root.add_child(b)
	return b


## The "new drive" disc: the jackhammer, in the corner the work's own buttons do
## NOT use (GO and NEXT live bottom-left, and that corner must keep meaning "go
## on with it"). Only up while there is a job to throw away.
func _build_fresh() -> void:
	var s := seat_size() * 0.7
	var inset := SafeArea.insets(get_viewport())
	_fresh = Button.new()
	_fresh.name = "Fresh"
	_fresh.focus_mode = Control.FOCUS_NONE
	_fresh.custom_minimum_size = Vector2(s, s)
	_fresh.anchor_left = 1.0
	_fresh.anchor_right = 1.0
	_fresh.anchor_top = 1.0
	_fresh.anchor_bottom = 1.0
	_fresh.offset_left = -(s + corner_margin + inset.z)
	_fresh.offset_right = -(corner_margin + inset.z)
	_fresh.offset_top = -(s + corner_margin + inset.w)
	_fresh.offset_bottom = -(corner_margin + inset.w)
	_fresh.pivot_offset = Vector2(s, s) * 0.5
	JobIcons.dress_fresh(_fresh, s)
	_root.add_child(_fresh)
	_fresh.button_down.connect(_on_fresh_down)
	_fresh.button_up.connect(_on_fresh_up)
	var ring := HoldRing.new()
	ring.name = "HoldRing"
	ring.menu = self
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fresh.add_child(ring)
	_fresh_ring = ring


## Walks the corner disc in off the screen's own hardware, again.
func place_in_safe_area() -> void:
	if _fresh == null:
		return
	var s := _fresh.custom_minimum_size.x
	var inset := SafeArea.insets(get_viewport())
	_fresh.offset_left = -(s + corner_margin + inset.z)
	_fresh.offset_right = -(corner_margin + inset.z)
	_fresh.offset_top = -(s + corner_margin + inset.w)
	_fresh.offset_bottom = -(corner_margin + inset.w)


func _on_fresh_down() -> void:
	_holding = true
	_spent = false
	_hold = 0.0


func _on_fresh_up() -> void:
	# Let go early and nothing happens: the ring empties and the miss is heard,
	# so a child who half-pressed it knows their job is still there.
	if _holding and not _spent:
		_play("pop")
	_holding = false
	_hold = 0.0
	if _fresh_ring != null:
		_fresh_ring.queue_redraw()


## The press on a job's disc: a kick, the diesel turning over, and the cut. No
## fade, ever - the menu is still whole in the frame the job arrives.
func _press_seat(key: String) -> void:
	var b := _seats.get(key) as Button
	if b != null:
		b.set_meta("pressing", true)
		var tw := create_tween()
		tw.tween_property(b, "scale", Vector2(1.12, 1.12), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_play("crank")
	seat_pressed.emit(key)


## A finger anywhere that is not a control: heard, and the row bounces to say
## where to go. Never a punishment, and never a start.
func _on_root_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if not pressed:
		return
	var now := float(Time.get_ticks_msec()) / 1000.0
	if now - _miss_at >= MISS_GAP:
		_miss_at = now
		_play("pop")
	for key: String in _keys:
		var b := _seats.get(key) as Button
		if b == null or b.has_meta("pressing"):
			continue
		var tw := create_tween()
		tw.tween_property(b, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2.ONE, 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play(group: String) -> void:
	if _sfx != null and _sfx.has_method("play_group"):
		_sfx.play_group(group)


# --- What the tests read -------------------------------------------------------------------

func seat_keys() -> PackedStringArray:
	return _keys


func seat_rect(key: String) -> Rect2:
	var b := _seats.get(key) as Button
	return b.get_global_rect() if b != null else Rect2()


func row_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for key: String in _keys:
		var b := _seats.get(key) as Button
		if b != null:
			out.append(b.get_global_rect())
	return out


## Is this seat showing the real machine, not the drawn stand-in?
func is_modelled(key: String) -> bool:
	var b := _seats.get(key) as Button
	if b == null:
		return false
	var icon := b.get_node_or_null("Prop_" + JobIcons.hero(key)) as PropIcon
	return icon != null and icon.is_modelled()


## How many models stand in the seat's picture. The blade is an ATTACHMENT on
## the skid steer, not a second model, so the driveway's seat is 1.
func seat_parts(key: String) -> int:
	var b := _seats.get(key) as Button
	if b == null:
		return 0
	var icon := b.get_node_or_null("Prop_" + JobIcons.hero(key)) as PropIcon
	return icon.part_count() if icon != null else 0


func fresh_visible() -> bool:
	return _fresh != null and _fresh.visible


func fresh_rect() -> Rect2:
	return _fresh.get_global_rect() if _fresh != null else Rect2()


## How far round the ring the hold has got, 0 to 1.
func fresh_fill() -> float:
	return clampf(_hold / HOLD_TIME, 0.0, 1.0)


## Presses a seat without a finger, the same path the button takes.
func simulate_seat(key: String) -> void:
	_press_seat(key)


## Holds the "new drive" disc to the end without a finger.
func simulate_fresh() -> void:
	_on_fresh_down()
	_hold = HOLD_TIME
	_spent = true
	_holding = false
	_play("breaker")
	fresh_pressed.emit()


## Lets go of the "new drive" disc, and does nothing else. The settings panel
## freezes the tree while it is up, and a frozen tree is deaf to RELEASES: a
## finger lifted off this disc behind the panel is a lift this menu never hears,
## and the ring would go on filling once the panel closed - throwing a saved
## drive away with nothing on the screen touched. `SettingsMenu` calls this by
## name when it takes the screen.
func release_hold() -> void:
	if _holding:
		_on_fresh_up()


## The controller's ring sleeps while a panel is over the row. A row of one has
## nothing to walk between, so there is no ring yet - but `SettingsMenu` calls
## this by name when it is ported (6.4), and the name is the seam.
func set_focus_active(_on: bool) -> void:
	pass


## The cream arc that fills round the "new drive" disc while it is held: the
## ring says how much longer, so a child never has to guess.
class HoldRing extends Control:
	var menu: StartMenu

	func _draw() -> void:
		if menu == null:
			return
		var k := menu.fresh_fill()
		if k <= 0.001:
			return
		var mid := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - maxf(size.x, 1.0) * 0.035
		draw_arc(mid, r, -PI * 0.5, -PI * 0.5 + TAU * k, 48, Brand.CREAM, maxf(size.x * 0.07, 3.0), true)
