class_name Pad
extends RefCounted
## The gamepad, for all four toys at once.
##
## Tree Chop is a touch game first: every control on screen is a big round
## button meant for a thumb. A controller has to reach the same places with no
## pointer at all, so the whole game speaks through five ideas instead of raw
## keycodes - GO, BACK, PAUSE and a direction - and each one answers to a
## keyboard key, a D-pad, a stick and a trigger at the same time. Nothing in the
## levels has to know which of them a child is holding.
##
## GO is deliberately greedy: three of the four face buttons and the right
## trigger. A four-year-old mashes rather than aims, and the one button that is
## NOT go is B, so that going home stays possible. BACK never needs finding.
##
## The actions install themselves the first time anything touches this class
## (`_static_init`), so no scene, autoload or project setting has to remember to
## do it and the headless smoke tests get them for free.
##
## `Pad.Focus` is the other half of the problem. On a controller there is no
## finger, so one button on the screen has to be "the one you are about to
## press": Focus puts a fat ring round it, walks it with the stick, presses it
## with GO, and disappears the moment a real finger lands. A child on an iPad
## never sees it; a child on a controller never has to guess.

const GO := "tc_go"
const BACK := "tc_back"
const PAUSE := "tc_pause"
const LEFT := "tc_left"
const RIGHT := "tc_right"
const UP := "tc_up"
const DOWN := "tc_down"

const DIRECTIONS: Array[String] = [LEFT, RIGHT, UP, DOWN]

## Sticks drift. A grinder that creeps across the clearing on its own is a bug
## a small child cannot report, so this sits well past any resting wobble.
const STICK_DEADZONE := 0.35
## A trigger counts as a press once it is properly squeezed, not brushed.
const TRIGGER_POINT := 0.5

## Has a controller been used since the last time a finger touched the glass?
static var _gamepad: bool = false
## GO is held right now (see `go_event`). Game-wide, so the ring and the level
## underneath it can never both answer the same squeeze.
static var _go_down: bool = false


static func _static_init() -> void:
	install()


## Adds the game's actions to the InputMap. Idempotent, and safe to call from
## anywhere: the levels do not have to agree on who goes first.
static func install() -> void:
	if InputMap.has_action(GO):
		return
	_action(GO, [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER],
			[JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_Y], [], [JOY_AXIS_TRIGGER_RIGHT])
	_action(BACK, [KEY_ESCAPE], [JOY_BUTTON_B], [], [])
	_action(PAUSE, [KEY_P], [JOY_BUTTON_START], [], [])
	# Both sticks and the D-pad drive, so it does not matter which thumb finds
	# one first. WASD comes along because a laptop is how this gets tested.
	_action(LEFT, [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT],
			[[JOY_AXIS_LEFT_X, -1.0], [JOY_AXIS_RIGHT_X, -1.0]], [])
	_action(RIGHT, [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT],
			[[JOY_AXIS_LEFT_X, 1.0], [JOY_AXIS_RIGHT_X, 1.0]], [])
	_action(UP, [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP],
			[[JOY_AXIS_LEFT_Y, -1.0], [JOY_AXIS_RIGHT_Y, -1.0]], [])
	_action(DOWN, [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN],
			[[JOY_AXIS_LEFT_Y, 1.0], [JOY_AXIS_RIGHT_Y, 1.0]], [])
	for a in DIRECTIONS:
		InputMap.action_set_deadzone(a, STICK_DEADZONE)
	# GO answers to a trigger, which is an axis, so it needs a threshold of its
	# own: on Godot's default 0.2 a trigger merely rested on counts as a press.
	InputMap.action_set_deadzone(GO, TRIGGER_POINT)


static func _action(name: String, keys: Array, buttons: Array, axes: Array, triggers: Array) -> void:
	InputMap.add_action(name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(name, ev)
	for b in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = b
		InputMap.action_add_event(name, ev)
	for pair in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = pair[0]
		ev.axis_value = pair[1]
		InputMap.action_add_event(name, ev)
	for t in triggers:
		var ev := InputEventJoypadMotion.new()
		ev.axis = t
		ev.axis_value = 1.0
		InputMap.action_add_event(name, ev)


# --- Asking ------------------------------------------------------------------------------

## GO was pressed this frame: chop, start, pull, pick up, choose, go on.
##
## Only for a level with no `Pad.Focus` over it, and only from `_process` -
## polling cannot be consumed, so a screen with a ring on it must use
## `go_event()` in `_unhandled_input` instead or one press does two things.
static func go() -> bool:
	return Input.is_action_just_pressed(GO)


## One press of GO, once - the only safe way to answer GO from an input handler.
##
## GO answers to the right trigger, and a trigger is an ANALOG axis: squeezing
## it sends an event for every value it passes through on the way down, and
## `InputEvent.is_action_pressed` has no idea which of them was the first. It
## says yes to all of them. Measured on a real ramp that is about ten yeses for
## one squeeze, which fed a whole log through the chipper on one pull and cut a
## felling tree twice.
##
## So the edge is latched here, once, for the whole game: true on the press,
## false until GO is genuinely let go again. `Pad.Focus` shares the same latch,
## which is what stops a GO that pressed a button on a ring leaking through to
## the level behind it as the trigger releases.
static func go_event(event: InputEvent) -> bool:
	if not event.is_action_pressed(GO):
		# Any event that is not a GO press is a chance to notice it was let go.
		if _go_down and not Input.is_action_pressed(GO):
			_go_down = false
		return false
	if _go_down:
		return false
	_go_down = true
	return true


## GO is being held: the chop game's hold-to-chop.
static func go_held() -> bool:
	return Input.is_action_pressed(GO)


## BACK was pressed this frame: home, or out of whatever page this is.
static func back() -> bool:
	return Input.is_action_just_pressed(BACK)


static func pause() -> bool:
	return Input.is_action_just_pressed(PAUSE)


## Where the stick or D-pad is pushed, -1..1 each way, already dead-zoned.
## +Y is DOWN the screen, so it matches the on-screen pads rather than 3D.
static func move() -> Vector2:
	return Input.get_vector(LEFT, RIGHT, UP, DOWN, STICK_DEADZONE)


## Is a controller what the child is using right now? False until one is
## actually touched, and false again the moment a finger lands on the glass -
## so the focus ring only ever appears for someone who needs it.
static func in_use() -> bool:
	return _gamepad


## Watches one event and decides whether we are on a controller. `Pad.Focus`
## calls this; a screen without a Focus can call it from its own `_input`.
static func saw(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed:
			_gamepad = true
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > STICK_DEADZONE:
			_gamepad = true
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_gamepad = false
	elif event is InputEventMouseButton:
		# Godot fakes a click from every finger; only a real mouse counts.
		if (event as InputEventMouseButton).device != InputEvent.DEVICE_ID_EMULATION:
			_gamepad = false


## For tests, and for a level that wants to start on the controller.
static func set_in_use(on: bool) -> void:
	_gamepad = on


# --- The ring ----------------------------------------------------------------------------

## The controller's finger: a fat ring around whichever button is next.
##
## It is a plain Control laid over a screen's buttons. Give it the buttons in
## the order they read left to right, add it last so it draws on top, and it
## does the rest: turns itself on when a controller is touched, walks the ring
## with the stick or D-pad, presses with GO, and vanishes when a finger lands.
##
## Godot's own focus would nearly do this, but its ring is a hairline meant for
## a form. This one is drawn the size of the game's other shapes and pulses, so
## it reads across a room from a sofa.
class Focus extends Control:
	## The ring's colour: the game's warm yellow, on everything.
	var ring_color: Color = Color(1.0, 0.93, 0.55)
	var ring_width: float = 8.0
	## How far outside the button the ring sits, pixels.
	var ring_pad: float = 12.0
	## The pulse, in ring widths.
	var pulse: float = 0.35
	var pulse_rate: float = 3.4

	## How far the stick has to go before it counts as a step.
	const NAV_POINT := 0.55
	## Hold a direction and the ring walks: the first wait, then the rest.
	const NAV_FIRST := 0.42
	const NAV_REPEAT := 0.19

	var _buttons: Array[Button] = []
	var _index: int = 0
	var _time: float = 0.0
	var _live: bool = false
	## A held stick keeps sending events the whole time it is over, so it would
	## sprint the ring along the row. GO has the same problem and worse, but its
	## latch lives in `Pad.go_event` where the levels share it.
	var _nav_dir: int = 0
	var _nav_wait: float = 0.0
	## Asleep: hidden, deaf to GO and to the stick, but still HOLDING its row and
	## still standing on the button the child had walked to. See `set_asleep`.
	var _asleep: bool = false


	func _ready() -> void:
		name = "PadFocus"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		visible = false
		set_process(true)


	## The buttons this screen offers, in reading order. Call it again whenever
	## the page changes (the title screen turns to the seasons, a NEXT appears);
	## the ring lands on the first one that is actually on screen.
	##
	## `start_index` puts it somewhere else instead, and exists because a row can
	## be a CHOICE the child is already standing in the middle of: the settings
	## ladder opens with the ring on the rung the sound is on, so one push of the
	## stick is one step quieter and not five steps back to where they were.
	func set_buttons(list: Array, start_index: int = -1) -> void:
		_buttons.clear()
		for b in list:
			if b is Button:
				_buttons.append(b as Button)
		_index = _first_usable()
		if start_index >= 0 and start_index < _buttons.size() and _usable(_buttons[start_index]):
			_index = start_index
		_sync()


	## How many buttons the ring is holding. Zero means it is empty and cannot
	## swallow anything, which is what the tests check for.
	func button_count() -> int:
		return _buttons.size()


	## Puts the ring to sleep, or wakes it. Asleep it is invisible and answers
	## nothing - no GO, no stick - so a panel laid over this screen is the only
	## ring live on it.
	##
	## Sleeping rather than emptying the row is the whole point: `set_buttons`
	## sends the ring back to the FIRST button, and a row is often a place the
	## child has walked to. Take the ring away from a pause screen the child had
	## stepped left along and give it back on Play, and their next GO resumes the
	## game instead of doing what they were about to do. Asleep, the row and the
	## step they were standing on are still there when it wakes.
	func set_asleep(on: bool) -> void:
		if _asleep == on:
			return
		_asleep = on
		_sync()


	func is_asleep() -> bool:
		return _asleep


	## Is the ring actually drawn right now? False when it is asleep, when the
	## row is empty and whenever a finger rather than a controller is in charge.
	func ring_visible() -> bool:
		return visible and _live


	## One step along the row, as a push of the stick would. Public so a test can
	## put the ring somewhere other than where it opens - which is the only way
	## to prove that taking the ring away and giving it back keeps the child's
	## place rather than quietly resetting it.
	func walk(dir: int) -> void:
		_step(dir)


	## The button the ring is sitting on, or null.
	func current() -> Button:
		if _index < 0 or _index >= _buttons.size():
			return null
		return _buttons[_index]


	func _first_usable() -> int:
		for i in range(_buttons.size()):
			if _usable(_buttons[i]):
				return i
		return -1


	func _usable(b: Button) -> bool:
		return b != null and is_instance_valid(b) and b.is_visible_in_tree() and not b.disabled


	## GO is taken here, in `_input`, rather than polled - and the event is eaten
	## even when the latch swallows the press, so the level underneath never sees
	## a GO the ring has already spoken for. Walking the row is done by polling
	## in `_process` instead, because a stick's events cannot be edge-detected.
	func _input(event: InputEvent) -> void:
		var was := Pad.in_use()
		Pad.saw(event)
		if Pad.in_use() != was:
			_sync()
		if _asleep or not Pad.in_use() or _buttons.is_empty():
			return
		if event.is_action_pressed(Pad.GO):
			# Eaten even when the latch swallows it, so the trailing events of a
			# releasing trigger cannot leak past the ring into the level behind.
			get_viewport().set_input_as_handled()
			if not Pad.go_event(event):
				return
			var b := current()
			if b != null:
				b.pressed.emit()


	## Walks to the next button that is on screen, wrapping, so a controller can
	## never get stuck on a page whose middle button has gone away.
	func _step(dir: int) -> void:
		if _buttons.is_empty():
			return
		var i := _index
		for _n in range(_buttons.size()):
			i = wrapi(i + dir, 0, _buttons.size())
			if _usable(_buttons[i]):
				_index = i
				_time = 0.0
				queue_redraw()
				return


	func _sync() -> void:
		if _asleep or not Pad.in_use():
			_live = false
			visible = false
			return
		if not _usable(current()):
			_index = _first_usable()
		_live = _index >= 0
		visible = _live
		queue_redraw()


	func _process(delta: float) -> void:
		if _asleep:
			if visible:
				_sync()
			return
		if not Pad.in_use():
			if visible:
				_sync()
			return
		# Buttons here bounce, appear and go away; follow them every frame.
		if not _usable(current()):
			_sync()
			return
		if not visible:
			_sync()
		_walk(delta)
		_time += delta
		queue_redraw()


	## The stick walks the row: one step when it is pushed, then a steady repeat
	## if it is held over, the way a held arrow key repeats. Either axis moves
	## along the row, because a child pushing "up" at a row of buttons means
	## "the next one", not "nothing happens".
	func _walk(delta: float) -> void:
		var v := Pad.move()
		var dir := 0
		if absf(v.x) > NAV_POINT or absf(v.y) > NAV_POINT:
			var along := v.x if absf(v.x) >= absf(v.y) else v.y
			dir = 1 if along > 0.0 else -1
		if dir == 0:
			_nav_dir = 0
			_nav_wait = 0.0
		elif dir != _nav_dir:
			_nav_dir = dir
			_nav_wait = NAV_FIRST
			_step(dir)
		else:
			_nav_wait -= delta
			if _nav_wait <= 0.0:
				_nav_wait = NAV_REPEAT
				_step(dir)


	func _draw() -> void:
		var b := current()
		if not _live or b == null:
			return
		var r := Rect2(b.get_global_rect())
		r.position -= global_position
		var breathe := ring_width * (1.0 + pulse * sin(_time * pulse_rate))
		r = r.grow(ring_pad + breathe * 0.5)
		# Round, because every button under it is.
		var c := r.get_center()
		var radius := maxf(r.size.x, r.size.y) * 0.5
		draw_arc(c, radius, 0.0, TAU, 48, ring_color, breathe, true)
