class_name SettingsMenu
extends CanvasLayer
## The settings panel: how loud the game is, on every screen, with no reading -
## and the one link out of the game, behind a grown-up check.
##
## Brought over from Tree Crew's repository (origin/main bf29315) on 2026-09-11,
## when the user asked for its "settings gear, and volume, and privacy page".
## Everything here is Tree Crew's except three things: the season row (a Tree
## Crew thing - there is no year turning in a garage), the neighbours, which are
## duck-typed because ChopHud, TreeChopMain and StartMenu's Tree Crew API do not
## exist in this project, and the `--settings` shot arguments.
##
## A slate-blue disc wearing a COG sits in the TOP-LEFT corner - the same 92 px
## square on the title screen, the garage and the street, because a
## four-year-old learns one place once. It wore a pair of ear defenders until
## 2026-09-11 (Tree Crew's until 2026-09-08), on the argument that the picture
## should BE the state; Tree Crew's feel-tester answered that it did not read as
## a button you press to open something, which is the first thing it has to do.
## A cog does, to a child who has watched an adult tap one. The one piece of
## state worth keeping is kept: a silenced game wears a red bar across the cog,
## because a game deliberately muted a week ago otherwise looks exactly like an
## untouched one.
##
## Tapping it opens:
##
##  * a **volume SLIDER** - a fat track with a big round handle, eleven steps,
##    silent at the far left. It was a ladder of four discs and the reasoning
##    was "no slider, because a child who cannot read cannot aim at one". That
##    argument was about AIMING, and a slider does not ask you to aim: it asks
##    you to drag, which is a gesture a three-year-old already has. The handle
##    is a whole thumb wide and the track answers a tap anywhere along it, so
##    there is nothing to miss.
##  * one blue button that turns the SONG off and on by itself - the one thing
##    an adult in the room actually asks for, and a binary with an obvious
##    picture rather than a second scale to get wrong,
##  * a green tick that closes it. So does the dim, so does the button that
##    opened it, so does BACK.
##  * and, small and in words in the bottom-right corner, "Privacy Policy" -
##    for the adult, behind a sum (`ParentalGate`). See `_build_privacy_link`.
##
## Two things about what happens to the game while it is open, both deliberate:
##
##  * IT PAUSES. Polled input cannot be consumed by an overlay, and the garage
##    and the street both have held gestures (a wrench, a lever) - so without a
##    pause a child fiddling with the volume would still be working the car.
##    One `get_tree().paused = true` makes every HUD and every level deaf at
##    once, with no capture flag that could be left stuck true and no change to
##    a single level's script.
##  * IT KEEPS MAKING NOISE. A paused tree stops the audio dead, and a volume
##    control opened over a silent game is adjusting nothing. So `Sfx` is raised
##    to PROCESS_MODE_ALWAYS for as long as the panel is up: the song plays on
##    and every step the child moves the slider pings at the volume they just
##    chose, so the choice is always audible. The machines' LOOPS are frozen
##    with the picture (`Sfx.set_loops_paused`) rather than left running,
##    because a loop is stopped by its machine counting a tail down in
##    `_process` and a frozen `_process` never finishes counting - see that
##    function for the bug.
##
## The corner button is MOUSE_FILTER_IGNORE and picks its own taps out of
## `_input`, the same idiom Tree Crew's pull cord and machine pads use. That is
## what lets it sit over anything a level draws without either of them having
## to know about the other. It also insists, exactly as a real Button does, on
## a press AND a release inside itself, from the same finger: see
## `_opener_pointer`.

## The corner button: the size and margin of the HUD's other corner buttons, so
## it belongs to the same family.
@export var opener_size: float = 92.0
@export var opener_margin: float = 18.0
## Slate blue. Deliberately not the corner green (which means "do the thing")
## and not a machine's safety orange: this button is furniture.
@export var opener_color: Color = Color(0.34, 0.46, 0.58)
## The volume slider: how long the track is, how thick, and how big the handle
## a thumb drags along it is. The handle is deliberately bigger than the track
## is thick - it is the thing being grabbed, and it has to be findable without
## looking for it.
@export var slider_span: float = 620.0
@export var slider_thickness: float = 34.0
@export var slider_handle: float = 92.0
## Where the slider's row sits, as an offset from the middle of the screen.
## Tree Crew's sits at 0 with a row of season cards above it; this panel has no
## season row, so the picture comes down into that room and the row stays put.
@export var slider_y: float = 0.0
## The loudspeakers either side of the track: crossed out at the silent end,
## three waves at the loud end. They are what say the slider is a VOLUME.
@export var speaker_size: float = 74.0
@export var speaker_gap: float = 26.0
## The mushroom STOP red every machine has. The silent end of the slider is
## marked in it.
@export var off_color: Color = Color(0.80, 0.22, 0.18)
## Action Blue - the one cool colour in the palette, so the music switch can
## never be mistaken for part of the volume.
@export var music_color: Color = Brand.BLUE
@export var music_size: float = 120.0
## The tick that closes it, in the game's go-green.
@export var done_color: Color = Brand.GREEN
@export var done_size: float = 150.0
## The grown-up check's own dim, so the panel and the card over it read as the
## same room. Tree Crew uses its clearing's pause dim (0.55) here; over this
## game's title - three big saturated discs and a wordmark - that left the
## slider lying across the row like part of it (2026-09-11 render).
@export var dim_color: Color = Color(0.03, 0.08, 0.04, 0.72)
## The big pair of ear defenders at the top of the panel, which mirrors the
## choice: the waves grow and shrink and the red bar appears at OFF.
@export var picture_size: float = 190.0

@export_group("Privacy")
## Where the privacy link goes. Apple requires the policy to be reachable
## from inside the app as well as from the store listing, and the Kids
## Category requires a parental gate in front of anything that leaves - so
## this is the only URL in the game and it is behind `ParentalGate`.
@export var privacy_url: String = "https://biglittlejobs.com/privacy"
## Small, cornered, and in words: it is for the adult holding the tablet,
## like the "by" under the title, and a child has no business finding it.
@export var privacy_font_size: int = 20
@export var privacy_margin: Vector2 = Vector2(30.0, 24.0)

var _shell: Control
var _opener: Button
var _opener_gear: Settings.GearIcon
## Every control laid out from the middle of the screen, and its box from there.
var _centred: Dictionary = {}
var _panel: Control
var _dim: ColorRect
var _picture: Settings.EarDefenderIcon
var _slider: VolumeSlider
## The slider's stand-in in the controller's focus row: a slider is not a
## button, and `Pad.Focus` rings buttons. GO on it steps the volume up one and
## wraps round to silence, which is the whole of the controller's volume story
## and is why there is no ring to drag with a stick.
var _slider_btn: Button
## The two loudspeakers either side of the slider.
var _quiet_icon: Settings.SpeakerIcon
var _loud_icon: Settings.SpeakerIcon
var _privacy_btn: Button
var _gate: ParentalGate
var _music_btn: Button
var _music_icon: MusicNoteIcon
var _done_btn: Button
var _focus: Pad.Focus
var _open: bool = false
var _fade: Tween
## The buttons' own scale tweens, killed before anything writes `scale`
## directly. Without this a bounce and a tap inside its 0.28 s fight over the
## same property and the older tween wins last.
var _bounce: Array[Tween] = []

## The neighbours, looked up once. `_chop_hud` is null unless the level's HUD
## node happens to implement the optional hooks below (Tree Crew's ChopHud
## does; this project's ToyHud/GarageHud does not, so every use of it is a
## harmless no-op here - see each call site).
var _sfx: Sfx
## Tree Crew types this `ChopHud`; that class does not exist in this project,
## so it is duck-typed as `CanvasLayer` (which both ChopHud and ToyHud extend)
## and every ChopHud-specific call below is guarded with has_method/has_signal.
var _chop_hud: CanvasLayer
## What the game looked like before the panel went up, so closing puts every one
## of them back exactly as it was.
var _sfx_mode: int = Node.PROCESS_MODE_INHERIT
var _was_tree_paused: bool = false
var _was_master_muted: bool = false
var _master_bus: int = 0
## Master has been borrowed back so a choice can be heard. Only ever set by
## `_preview_audible`, on the first thing the child actually changes.
var _borrowed_master: bool = false
## Every OTHER focus ring on this screen, put to sleep while the panel is up so
## there is never more than one. They keep their row and their place in it.
var _slept: Array[Pad.Focus] = []
## Which finger (touch index, or -1 for a real mouse) pressed the corner button.
## -2 is nobody. A release from any other finger is not this button's business.
var _opener_finger: int = -2


func _ready() -> void:
	# Above every HUD (layer 1) and the title screen (layer 20).
	layer = 40
	# The whole point: this panel has to answer while the tree is paused. It can
	# never lean on the HUD it sits over for that, because none of this game's
	# HUDs run while paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.ensure()
	_master_bus = AudioServer.get_bus_index("Master")
	_build_panel()
	_build_shell()
	_place_in_safe_area()
	# A phone turned over, or a window resized: the edges are somewhere else.
	get_viewport().size_changed.connect(_place_in_safe_area)
	# On the TITLE row this finds nothing, for good: that scene has no `Sfx` of
	# its own (`title_main.gd`: the instanced lot brings it), and the lot is
	# added inside `TitleMain._ready`, AFTER this node's. `TitleMain` pushes it
	# in with `set_sfx` instead. Every use below is null-guarded, so the failure
	# would have been silent: no ping under the slider, and the song stopping
	# dead the moment the panel paused the tree.
	_sfx = get_parent().get_node_or_null("Sfx") as Sfx
	# Tree Crew types this `as ChopHud`; duck-typed here (see the field's own
	# comment) so this compiles and runs over a ToyHud/GarageHud, which has
	# neither hook below, and over no HUD node at all.
	_chop_hud = get_parent().get_node_or_null("HUD") as CanvasLayer
	if _chop_hud != null and _chop_hud.has_signal("settings_pressed"):
		# Tree Crew's clearing reaches the settings from inside its pause screen:
		# PAUSE is already spoken for there.
		_chop_hud.connect("settings_pressed", open)
	if _chop_hud != null and _chop_hud.has_method("add_pointer_button"):
		# And a press on the corner button must never also be read as a press on
		# the level: a HUD that polls the raw mouse cannot be told the event was
		# handled, so it is told about the button's rect instead.
		_chop_hud.call("add_pointer_button", _opener)
	_sync_all()


# --- The corner button --------------------------------------------------------------

## The cog (top-left) and the privacy link (bottom-right), inset from the SAFE
## area rather than the screen's edge (DESIGN 32, `SafeArea`): on a phone in
## landscape both corners are the Dynamic Island's band, and the link's is the
## home indicator's too. Zero insets leave both exactly where they always were.
func _place_in_safe_area() -> void:
	var safe := SafeArea.insets(get_viewport())
	if _opener != null:
		_opener.offset_left = opener_margin + safe.x
		_opener.offset_top = opener_margin + safe.y
		_opener.offset_right = opener_margin + safe.x + opener_size
		_opener.offset_bottom = opener_margin + safe.y + opener_size
	var shift := _centre_shift()
	for c: Control in _centred:
		if is_instance_valid(c):
			_offset_centred(c, _centred[c], shift)
	if _privacy_btn != null:
		_privacy_btn.offset_left = -privacy_margin.x - safe.z - 220.0
		_privacy_btn.offset_right = -privacy_margin.x - safe.z
		_privacy_btn.offset_top = -privacy_margin.y - safe.w - 44.0
		_privacy_btn.offset_bottom = -privacy_margin.y - safe.w


func _build_shell() -> void:
	_shell = Control.new()
	_shell.name = "Shell"
	_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shell)

	_opener = _round_button("SettingsOpen", opener_size, opener_color)
	# It is a real Button so it can be styled and pressed like every other one,
	# but it does NOT use Godot's GUI picking: it hit-tests itself in `_input`,
	# which runs before any GUI processing and before anything the level owns.
	_opener.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opener.pressed.connect(toggle)
	_opener_gear = Settings.GearIcon.new()
	_opener_gear.setup(opener_size, Settings.is_muted())
	_opener.add_child(_opener_gear)
	_shell.add_child(_opener)
	# Storyboards, shots and marketing renders keep a clean screen. The panel
	# still opens from code, so the tests are unaffected.
	#
	# `--settings` asks for it BACK, so a shot can prove the cog is where the
	# contract says and that nothing on the HUD lands on top of it. (Round 1:
	# no screenshot had ever shown that button.)
	_opener.visible = not Engine.has_meta("shot_args") or _shot_wants_settings()
	# `--settings=open` opens the panel itself, for a picture of it, and
	# `--settings=gate` goes one further and puts the grown-up check up over it.
	var mode := _shot_settings_mode()
	if mode == "open" or mode == "gate":
		open.call_deferred()
	if mode == "gate":
		_ask_grown_up.call_deferred()


## Does this shot want the cog in the picture?
func _shot_wants_settings() -> bool:
	if not Engine.has_meta("shot_args"):
		return false
	var args: Dictionary = Engine.get_meta("shot_args")
	return args.has("settings") and str(args["settings"]) != "false"


## The value of a shot's `--settings=` argument, or "" when there is none.
func _shot_settings_mode() -> String:
	if not Engine.has_meta("shot_args"):
		return ""
	return str((Engine.get_meta("shot_args") as Dictionary).get("settings", ""))


# --- The panel ----------------------------------------------------------------------

func _build_panel() -> void:
	_panel = Control.new()
	_panel.name = "Panel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Eats every tap that misses a button, so none reach the frozen game.
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	add_child(_panel)

	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = dim_color
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	# A tap that misses everything is a way OUT, not a trap.
	_dim.gui_input.connect(_on_dim_input)
	_panel.add_child(_dim)

	_picture = Settings.EarDefenderIcon.new()
	_picture.name = "Picture"
	_picture.setup(picture_size, Settings.ear_level(Settings.loudness), Settings.is_muted(), Settings.song_off())
	var pic_bottom := slider_y - slider_handle * 0.5 - 40.0
	_centre(_picture, -picture_size * 0.5, picture_size * 0.5, pic_bottom - picture_size, pic_bottom)
	_panel.add_child(_picture)

	# The volume slider, where the ladder of four discs used to be.
	_slider = VolumeSlider.new()
	_slider.name = "Volume"
	_slider.track_color = opener_color
	_slider.silent_color = off_color
	_slider.setup(slider_span, slider_handle, slider_thickness, Settings.RUNGS)
	_slider.changed.connect(_choose)
	_centre(_slider, -slider_span * 0.5, slider_span * 0.5,
			slider_y - slider_handle * 0.5, slider_y + slider_handle * 0.5)
	_panel.add_child(_slider)
	# A button of exactly the slider's size, behind it and invisible, so the
	# controller's ring has something to sit on. It never sees a finger: the
	# slider in front of it takes those.
	_slider_btn = Button.new()
	_slider_btn.name = "VolumeStep"
	_slider_btn.focus_mode = Control.FOCUS_NONE
	_slider_btn.flat = true
	_slider_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slider_btn.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_centre(_slider_btn, -slider_span * 0.5, slider_span * 0.5,
			slider_y - slider_handle * 0.5, slider_y + slider_handle * 0.5)
	_slider_btn.pressed.connect(_step_volume)
	_panel.add_child(_slider_btn)
	# A speaker at each end. The one on the left is crossed out and the one on
	# the right has three waves, so which way is louder is a picture and not a
	# rule anyone has to be told.
	_quiet_icon = Settings.SpeakerIcon.new()
	_quiet_icon.name = "Quiet"
	_quiet_icon.setup(speaker_size, 0, true)
	_centre(_quiet_icon, -slider_span * 0.5 - speaker_gap - speaker_size,
			-slider_span * 0.5 - speaker_gap, slider_y - speaker_size * 0.5, slider_y + speaker_size * 0.5)
	_panel.add_child(_quiet_icon)
	_loud_icon = Settings.SpeakerIcon.new()
	_loud_icon.name = "Loud"
	_loud_icon.setup(speaker_size, 3)
	_centre(_loud_icon, slider_span * 0.5 + speaker_gap,
			slider_span * 0.5 + speaker_gap + speaker_size, slider_y - speaker_size * 0.5, slider_y + speaker_size * 0.5)
	_panel.add_child(_loud_icon)

	_music_btn = _round_button("MusicToggle", music_size, music_color)
	_centre(_music_btn, 436.0, 436.0 + music_size, slider_y + 10.0, slider_y + 10.0 + music_size)
	_music_btn.pivot_offset = Vector2(music_size, music_size) * 0.5
	_music_btn.pressed.connect(_toggle_music)
	_music_icon = MusicNoteIcon.new()
	_music_icon.setup(music_size, not Settings.music_on)
	_music_btn.add_child(_music_icon)
	_panel.add_child(_music_btn)

	_done_btn = _round_button("Done", done_size, done_color)
	_centre(_done_btn, -done_size * 0.5, done_size * 0.5, 180.0, 180.0 + done_size)
	_done_btn.pressed.connect(close)
	_draw_tick(_done_btn, done_size)
	_panel.add_child(_done_btn)

	_build_privacy_link()

	# The controller's finger, added last so its ring draws over the buttons it
	# rings. It is given buttons only while the panel is open (see open/close):
	# a ring left standing would swallow the GO meant for the game.
	_focus = Pad.Focus.new()
	_panel.add_child(_focus)


## The privacy policy link, and the grown-up check in front of it.
##
## TWO App Store rules meet here and they pull opposite ways. Every app must
## make its privacy policy reachable from inside itself, not only from the store
## listing. And an app in the Kids Category must not let anyone link out without
## parental permission first. So the link has to exist, and it has to be hard to
## use - which is exactly a small line of text in a corner with a sum in front
## of it.
##
## Bottom-RIGHT of the panel, and set in Nunito Sans rather than Fredoka because
## this is the one control in the game addressed to the person holding the
## tablet. Tree Crew puts it bottom-left, "the only corner of this screen with
## nothing in it"; here that corner of the title screen is the trust ribbon,
## and the link sat on top of it (2026-09-11 render), while the bottom-right is
## empty on the panel and on every screen under it. It is also the ONLY thing in
## the whole game that opens anything outside it: the trust ribbon is a
## picture, not a button, and there is no other `OS.shell_open` anywhere in
## this project.
func _build_privacy_link() -> void:
	_gate = ParentalGate.new()
	_gate.passed.connect(_open_privacy)
	_gate.dismissed.connect(_on_gate_dismissed)
	_panel.add_child(_gate)

	_privacy_btn = Button.new()
	_privacy_btn.name = "Privacy"
	_privacy_btn.text = "Privacy Policy"
	_privacy_btn.flat = true
	_privacy_btn.focus_mode = Control.FOCUS_NONE
	_privacy_btn.add_theme_font_override("font", Brand.body(750))
	_privacy_btn.add_theme_font_size_override("font_size", privacy_font_size)
	for slot in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_privacy_btn.add_theme_color_override(slot, Color(1.0, 0.98, 0.94, 0.72))
	_privacy_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_privacy_btn.anchor_left = 1.0
	_privacy_btn.anchor_right = 1.0
	_privacy_btn.anchor_top = 1.0
	_privacy_btn.anchor_bottom = 1.0
	_privacy_btn.pressed.connect(_ask_grown_up)
	_panel.add_child(_privacy_btn)
	# The gate goes back to the END of the panel's children, so its own dim
	# is drawn over every control on the panel and takes every tap aimed at
	# one. That is also why nothing here touches the panel's mouse filter:
	# the gate covers the panel exactly the way the panel covers the game.
	_panel.move_child(_gate, -1)


## The link was tapped: put the sum up rather than the policy. Nothing leaves
## the app until `_open_privacy` runs.
##
## The controller's ring is handed its buttons back empty for the duration.
## The gate covers the panel for a FINGER - its dim is full-rect and takes
## every tap - but a ring is not a finger: it sits on a control by index and
## a GO press works whatever is drawn on top of it. Left alone, a gamepad A
## while the sum was up would toggle the music or move the volume behind the
## card. It cannot reach the policy either way (that needs the keypad), so
## this is tidiness rather than a hole - but a control that answers a button
## nobody can see is the kind of thing a reviewer finds.
func _ask_grown_up() -> void:
	if _gate == null:
		return
	_focus.set_buttons([])
	_gate.ask()


## The check came down without being answered: the panel is still open, so
## the controller's ring gets its buttons back.
func _on_gate_dismissed() -> void:
	_restore_focus()


## The sum was answered. This is the one line in the game that hands anything to
## the operating system, and it hands it a URL that is a constant - never
## anything a child typed, and never anything read off a file.
func _open_privacy() -> void:
	_restore_focus()
	OS.shell_open(privacy_url)


## Hands the ring the panel's buttons again, but only while the panel is
## actually open - `close()` takes the gate down too, and a ring holding
## buttons after the panel has gone eats every GO meant for the game.
func _restore_focus() -> void:
	if _open:
		_focus.set_buttons(_focus_row(), 0)


## Is the grown-up check up right now? For tests, and for the panel's own input
## handling, which must not treat a tap on the keypad as a tap on the dim.
func gate_is_open() -> bool:
	return _gate != null and _gate.is_asking()


## The gate itself, for tests.
func parental_gate() -> ParentalGate:
	return _gate


## Anchors a control to the middle of the screen and offsets it from there, so
## the panel keeps its shape whatever the window does. The middle is the SAFE
## area's (DESIGN 32): on a phone the home indicator takes the bottom edge, and
## the tick under the slider stood in it. `_place_in_safe_area` moves them all
## again when the insets change.
func _centre(c: Control, left: float, right: float, top: float, bottom: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	var box := Rect2(left, top, right - left, bottom - top)
	_centred[c] = box
	_offset_centred(c, box, _centre_shift())


## How far the safe area's middle is from the screen's.
func _centre_shift() -> Vector2:
	var safe := SafeArea.insets(get_viewport()) if is_inside_tree() else Vector4.ZERO
	return Vector2((safe.x - safe.z) * 0.5, (safe.y - safe.w) * 0.5)


func _offset_centred(c: Control, box: Rect2, shift: Vector2) -> void:
	c.offset_left = box.position.x + shift.x
	c.offset_right = box.end.x + shift.x
	c.offset_top = box.position.y + shift.y
	c.offset_bottom = box.end.y + shift.y


# --- Opening and closing -------------------------------------------------------------

func is_open() -> bool:
	return _open


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	if _open:
		return
	_open = true
	# Freeze the world. Everything the levels read - the pads, the levers, the
	# held wrenches - stops at this one line.
	_was_tree_paused = get_tree().paused
	get_tree().paused = true
	# ...but a frozen HUD is also a DEAF one, and ToyHud remembers which fingers
	# are down. See _release_pointers: this is the line that stops a machine
	# driving off on its own after the panel closes.
	_release_pointers()
	# Master's mute belongs to whatever screen set it (Tree Crew's pause screen
	# does), so it is only ever borrowed, and only when there is something to
	# hear - see _preview_audible. Merely REACHING for the volume control must
	# not make a game somebody deliberately silenced loud again.
	_master_bus = AudioServer.get_bus_index("Master")
	_was_master_muted = AudioServer.is_bus_mute(_master_bus)
	_borrowed_master = false
	# The song plays on over the frozen picture, and so does every ping, so the
	# child hears the change they are making. The machines' loops freeze with
	# the picture instead of running on.
	if _sfx != null:
		_sfx_mode = int(_sfx.process_mode)
		_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		_sfx.set_loops_paused(true)
	# Never two rings at once.
	_sleep_other_rings()
	_panel.visible = true
	_set_panel_takes_input(true)
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_sync_all()
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_panel, "modulate:a", 1.0, 0.18)
	# The ring opens on the SLIDER, which is what the panel is mostly opened
	# for; the song switch and the tick are one and two pushes to the right.
	_focus.set_buttons(_focus_row(), 0)


func close() -> void:
	if not _open:
		return
	_open = false
	# The grown-up check goes with the panel. Left standing it would be up
	# again, mid-sum, the next time anybody opened the settings - and the
	# sum on it would be the one an adult had already half-answered.
	if _gate != null:
		_gate.visible = false
	# A ring holding buttons after the panel has gone eats every GO meant for
	# the game; hand them all back.
	_focus.set_buttons([])
	if _fade != null and _fade.is_valid():
		_fade.kill()
	# The panel STOPS taking input on this line, not when the fade finishes.
	# It is full-rect and MOUSE_FILTER_STOP, and a STOP control marks an event
	# handled, so leaving it live for the 0.12 s of the fade made the whole
	# screen an input blackout over a game that was already running again: the
	# next tap would vanish into a panel the child had just dismissed, with
	# nothing on screen to explain it.
	_set_panel_takes_input(false)
	_fade = create_tween()
	_fade.tween_property(_panel, "modulate:a", 0.0, 0.12)
	_fade.tween_callback(func() -> void: _panel.visible = false)
	_restore()
	# Tree Crew types this `as TreeChopMain` (its main.gd's class_name); that
	# class does not exist in this project, so it is duck-typed here too - a
	# no-op over GarageMain and TowMain, which have no such method.
	var m := get_parent()
	if m != null and m.has_method("suppress_hold_until_release"):
		m.call("suppress_hold_until_release")


## Puts the game back exactly as the panel found it. Also runs from _exit_tree,
## so a scene change fired from underneath an open panel can never leave the
## tree paused, Master unmuted or Sfx stuck on ALWAYS.
func _restore() -> void:
	if _sfx != null and is_instance_valid(_sfx):
		_sfx.set_loops_paused(false)
		_sfx.process_mode = _sfx_mode
	if _borrowed_master:
		AudioServer.set_bus_mute(_master_bus, _was_master_muted)
		_borrowed_master = false
	_opener_finger = -2
	var tree := get_tree()
	if tree != null:
		tree.paused = _was_tree_paused
	# The same fingers, released again on the way out: a press that landed while
	# the panel was up can leave the same stale state.
	_release_pointers()
	_wake_other_rings()


func _exit_tree() -> void:
	if _open:
		_open = false
		_restore()


## Borrows Master's mute, once, on the first thing the child actually CHANGES.
##
## A pause screen that mutes Master to silence the game hands this panel a
## silent room, and the adult who most reliably opens it is the one who just
## paused because the noise was the problem. Unmuting on `open()` meant that
## walking the ring one step and pressing GO filled the room with noise again,
## and that closing without choosing anything put the silence back - so the
## only outcome of the whole trip was a burst of noise. Now the silence lasts
## exactly as long as the child is only LOOKING; the first move of the slider,
## or the song switch, brings the sound back so they can hear what they picked.
## `_restore` puts the flag back either way.
func _preview_audible() -> void:
	if _borrowed_master or not _was_master_muted:
		return
	_borrowed_master = true
	AudioServer.set_bus_mute(_master_bus, false)


## Every other focus ring on this screen goes to sleep while the panel is up.
##
## Named ones first (Tree Crew's pause screen and the title row keep their own
## doc), then a sweep for the ones this class does not know about: every HUD
## that owns a ring and is PROCESS_MODE_INHERIT would otherwise leave it frozen
## and lit under the dim while the panel's own ring was live - two yellow rings
## on one screen.
##
## Asleep rather than emptied: `Pad.Focus.set_asleep` keeps the row and the step
## the child had walked to, so closing the panel gives the ring back where they
## left it instead of on the first button.
func _sleep_other_rings() -> void:
	# ChopHud-only (its pause screen owns a ring); duck-typed, see `_chop_hud`.
	if _chop_hud != null and is_instance_valid(_chop_hud) and _chop_hud.has_method("set_pause_focus_active"):
		_chop_hud.call("set_pause_focus_active", false)
	var menu := _start_menu()
	if menu != null and menu.has_method("set_focus_active"):
		menu.call("set_focus_active", false)
	_slept.clear()
	var p := get_parent()
	if p != null:
		_collect_rings(p)
	for f in _slept:
		f.set_asleep(true)


func _wake_other_rings() -> void:
	for f in _slept:
		if f != null and is_instance_valid(f):
			f.set_asleep(false)
	_slept.clear()
	# ChopHud-only; duck-typed, see `_chop_hud`.
	if _chop_hud != null and is_instance_valid(_chop_hud) and _chop_hud.has_method("set_pause_focus_active"):
		_chop_hud.call("set_pause_focus_active", true)
	var menu := _start_menu()
	if menu != null and menu.has_method("set_focus_active"):
		menu.call("set_focus_active", true)


## Rings already asleep are somebody else's business and are left alone, so a
## ring this panel did not send to sleep is never woken by it either.
func _collect_rings(n: Node) -> void:
	for c in n.get_children():
		var f := c as Pad.Focus
		if f != null and f != _focus and not f.is_asleep():
			_slept.append(f)
		_collect_rings(c)


## Lets go of every finger the neighbours think is still down.
##
## `get_tree().paused` is a wonderfully small way to make the whole game deaf,
## but it is deaf to RELEASES too. ToyHud CACHES its pointers -
## PadButton._pointers - and it is PROCESS_MODE_INHERIT, so while this panel
## holds the tree frozen its `_input` is never called and a finger lifted in
## that time is a release it never hears. Measured in Tree Crew: hold the
## grinder's left arrow with one thumb, tap the corner with the other hand, lift
## the thumb, close the panel - and the grinder drove left on its own, with
## nothing on the screen touched, until that pad happened to be pressed and
## released again.
##
## A HUD-level `release_pads()` is preferred the moment it exists; until then
## the pads are reached by hand. `cord` is Tree Crew's pull cord, which this
## project does not have - a no-op here.
func _release_pointers() -> void:
	var p := get_parent()
	if p == null:
		return
	var hud := p.get_node_or_null("HUD")
	if hud == null:
		return
	if hud.has_method("release_pads"):
		hud.call("release_pads")
	elif "_pads" in hud:
		var pads: Dictionary = hud.get("_pads")
		for pad in pads.values():
			if pad != null and pad.has_method("release_all"):
				pad.call("release_all")
	if hud.has_method("cord"):
		var cord: Object = hud.call("cord")
		if cord != null:
			if cord.has_method("release_grab"):
				cord.call("release_grab")
			elif "_grabbing" in cord:
				cord.set("_grabbing", false)
	# And the title row's own HELD control. A paused tree never delivers the
	# RELEASE, so a finger lifted off the "new drive" disc while this panel is up
	# would still be held when it closes - and the ring would fill to the end and
	# throw the child's saved drive away with nothing on the screen touched.
	var menu := _start_menu()
	if menu != null and menu.has_method("release_hold"):
		menu.call("release_hold")


## Hands this panel the `Sfx` a screen brought with it, for the screens where it
## is not a sibling (the title row's lives under the lot it instances). Safe at
## any time: if the panel is already open, the node is taken over and quietened
## exactly as `open()` would have.
func set_sfx(s: Sfx) -> void:
	_sfx = s
	if _open and _sfx != null:
		_sfx_mode = int(_sfx.process_mode)
		_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		_sfx.set_loops_paused(true)


## The panel eats taps only while it is really up. Both halves matter: the dim
## is a STOP control in its own right, so leaving IT live would blackout the
## screen just as thoroughly as the panel would.
func _set_panel_takes_input(on: bool) -> void:
	var f := Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	_panel.mouse_filter = f
	if _dim != null:
		_dim.mouse_filter = f


## Tree Crew types this `-> StartMenu`; duck-typed here to plain `Node` because
## this project's StartMenu is its own class with its own API. Both callers
## guard with has_method before calling into it, so a scene with no
## "StartMenu" node is a no-op.
func _start_menu() -> Node:
	var p := get_parent()
	return p.get_node_or_null("StartMenu") if p != null else null


## The controller's row: the slider's stand-in, the song switch, the tick. The
## privacy link is deliberately NOT in it - see `_build_privacy_link`.
func _focus_row() -> Array:
	return [_slider_btn, _music_btn, _done_btn]


# --- Choosing -------------------------------------------------------------------------

## A step on the slider: the buses move THIS INSTANT, the file is written, the
## picture and the corner button follow, and the panel stays open. Nothing is
## confirmed, nothing is applied later, there is no OK.
func _choose(i: int) -> void:
	if i == Settings.loudness:
		return
	_preview_audible()
	Settings.set_loudness(i)
	_sync_all()
	if _sfx != null and is_instance_valid(_sfx):
		_sfx.play_group("ping")


## The controller's volume: GO on the slider steps it up one and wraps round to
## silence. A stick cannot drag a handle without `Pad.Focus` learning what a
## slider is, and one wrapping button is a smaller thing to teach than that.
func _step_volume() -> void:
	_choose((Settings.loudness + 1) % Settings.RUNGS)


func _toggle_music() -> void:
	_preview_audible()
	Settings.set_music_on(not Settings.music_on)
	_sync_all()
	_pop(_music_btn)
	if _sfx != null and is_instance_valid(_sfx):
		_sfx.play_group("ping")


## The same bounce the pause screen's Resume button uses.
func _pop(b: Button) -> void:
	var to := b.scale
	b.scale = to * 1.15
	_bounce_to(b, to)


## One scale tween at a time, tracked so `_sync_all` can kill it. A four-year-old
## taps again well inside 0.28 s, and two tweens on one `scale` end with the
## older one winning last on a target nobody wants any more.
func _bounce_to(b: Button, to: Vector2) -> void:
	var tw := create_tween()
	tw.tween_property(b, "scale", to, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bounce.append(tw)


func _kill_bounces() -> void:
	for tw in _bounce:
		if tw != null and tw.is_valid():
			tw.kill()
	_bounce.clear()


## Everything on screen agrees with the two numbers in the store.
func _sync_all() -> void:
	var lv := Settings.loudness
	# Every scale below is written DIRECTLY, so nothing may still be tweening it.
	_kill_bounces()
	if _music_btn != null:
		_music_btn.scale = Vector2.ONE
	if _opener_gear != null:
		_opener_gear.muted = Settings.is_muted()
	if _picture != null:
		_picture.show_settings()
	if _slider != null:
		_slider.set_step(lv)
	# The loud end's waves count up with the slider, so the picture agrees with
	# the handle even out of the corner of an eye.
	if _loud_icon != null:
		_loud_icon.waves = 1 if lv <= 0 else Settings.ear_level(lv)
	if _quiet_icon != null:
		_quiet_icon.crossed = Settings.is_muted()
	if _music_icon != null:
		_music_icon.off = not Settings.music_on
	if _music_btn != null:
		_style(_music_btn, music_color if Settings.music_on else music_color.darkened(0.45), music_size)
	# ChopHud-only; duck-typed, see `_chop_hud`.
	if _chop_hud != null and is_instance_valid(_chop_hud) and _chop_hud.has_method("refresh_settings_icon"):
		_chop_hud.call("refresh_settings_icon")
	if _opener != null:
		# While the panel is up the corner button wears its pressed face, so the
		# most learnable exit there is - the button you just pressed - looks like
		# the way back out.
		_style(_opener, opener_color.darkened(0.15) if _open else opener_color, opener_size)


# --- Input -----------------------------------------------------------------------------

## Runs before any GUI processing, because this node is the LAST child of the
## scene root and `_input` walks last child first. Note the deliberate
## asymmetry: while the panel is CLOSED this consumes only events inside the
## corner button's own rect and the PAUSE key. Anything wider and the whole game
## would go deaf.
func _input(event: InputEvent) -> void:
	if _open:
		Pad.saw(event)
	var p := _point_of(event)
	if p.is_finite():
		if _opener_pointer(event, p):
			return
		if _open and _is_drag(event):
			# A finger that started on the slider keeps it however far it
			# wanders off the track - see `_drag_to`.
			_drag_to(p)
			return
	if _open and event.is_action_pressed(Pad.BACK):
		# Taken here, before anything still awake while paused can read it as
		# "go home".
		get_viewport().set_input_as_handled()
		close()
		return
	if event.is_action_pressed(Pad.PAUSE) and _wants_pause_key():
		get_viewport().set_input_as_handled()
		toggle()


## The corner button, hit-tested by hand, behaving like a real Button: it wants
## a PRESS inside itself and then a RELEASE inside itself, from the SAME finger.
## Returns true when the event was the button's own and has been consumed.
##
## Neither half of that is fussiness. Answering a bare release was two bugs at
## once in Tree Crew, and both of them were reachable by an ordinary
## four-year-old:
##
##  * A held gesture keeps a finger down. Sweep it up into the top-left square
##    and lift, and the game froze under a panel nobody opened. A thumb resting
##    in that corner of a tablet did it on every lift.
##  * This node's `_input` runs FIRST (it is the last child of the scene root).
##    A drag that ended in the corner had its release eaten here, so whatever
##    the drag belonged to never heard its finger lift and stayed latched to
##    the next one.
##
## And a press on the button belongs to the finger that made it: every other
## button in this game takes one finger only, and a second thumb landing in the
## corner must not toggle a panel the first one is still holding.
func _opener_pointer(event: InputEvent, p: Vector2) -> bool:
	if not _opener.visible:
		return false
	var inside := _opener.get_global_rect().has_point(p)
	var finger := _finger_of(event)
	if _is_press(event):
		if not inside:
			return false
		_opener_finger = finger
		get_viewport().set_input_as_handled()
		return true
	if _is_release(event):
		if _opener_finger != finger:
			# Somebody else's release. Never consumed, whether or not it happens
			# to land here: the control that owns it has to hear it.
			return false
		_opener_finger = -2
		get_viewport().set_input_as_handled()
		if inside:
			toggle()
		return true
	# A drag by the finger holding the button stays the button's, so it cannot
	# also work a machine underneath on its way past.
	if _opener_finger != -2 and _opener_finger == finger:
		get_viewport().set_input_as_handled()
		return true
	return false


## PAUSE (P, or Start on a controller) is unbound on every screen of this game,
## so it is the settings key everywhere. (On Tree Crew's clearing the HUD owns
## it for the pause screen, which is what the ChopHud check below is for.)
func _wants_pause_key() -> bool:
	if _open:
		return true
	if _chop_hud != null and is_instance_valid(_chop_hud) and _chop_hud.visible \
			and _chop_hud.has_signal("settings_pressed"):
		return false
	return true


## Where a finger or a real mouse is, or a non-finite vector for anything else.
## Godot fakes a click from every touch, so only a mouse event from a real mouse
## counts or one tap would be read twice.
func _point_of(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.device != InputEvent.DEVICE_ID_EMULATION:
			return mb.position
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mm.device != InputEvent.DEVICE_ID_EMULATION and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			return mm.position
	return Vector2(INF, INF)


func _is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	return false


func _is_release(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		return not (event as InputEventMouseButton).pressed
	return false


## Which finger this is: a touch index on glass, -1 for a real mouse. The corner
## button holds on to one of these so a second thumb cannot work it.
func _finger_of(event: InputEvent) -> int:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).index
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).index
	return -1


func _is_drag(event: InputEvent) -> bool:
	return event is InputEventScreenDrag or event is InputEventMouseMotion


## A finger dragged across the panel while it is down on the slider. The slider
## has its own `_gui_input`, but a finger that starts on the handle and wanders
## off the control's rect stops being its business - and letting go of the
## volume because your thumb strayed two pixels above the track is exactly the
## kind of thing a four-year-old does constantly.
func _drag_to(p: Vector2) -> void:
	if _slider != null and _slider.dragging():
		_slider.drag_to(p)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not (event as InputEventMouseButton).pressed:
		close()
	elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		close()


# --- For the probes -------------------------------------------------------------------

func opener_rect() -> Rect2:
	return _opener.get_global_rect()


func opener_visible() -> bool:
	return _opener != null and _opener.visible


## The picture on the corner button. Nothing outside the tests should read it -
## the point of the icon is that it is the state, not that it can be asked.
func corner_icon() -> Settings.GearIcon:
	return _opener_gear


## Redraws everything from the store. The panel writes the store itself, so it
## needs this only when something else does - a probe, or a future screen.
func refresh() -> void:
	_sync_all()


## The volume slider, for tests. There is no `rung_button` any more: the ladder
## of four discs it used to index became one slider on 2026-09-11.
func volume_slider() -> VolumeSlider:
	return _slider


## The big ear defenders at the top of the panel, for tests.
func picture() -> Settings.EarDefenderIcon:
	return _picture


func music_button() -> Button:
	return _music_btn


func done_button() -> Button:
	return _done_btn


func privacy_button() -> Button:
	return _privacy_btn


## How many buttons the panel's ring is holding: three while it is open, none
## while it is not (and none while the grown-up check is up).
func focus_button_count() -> int:
	return _focus.button_count() if _focus != null else -1


# --- Drawing --------------------------------------------------------------------------

## A local copy of the HUD's round button. Copied rather than borrowed because
## no HUD class this menu could depend on is guaranteed to exist on every
## screen, and this menu has to look the same on all of them.
func _round_button(button_name: String, s: float, color: Color) -> Button:
	var b := Button.new()
	b.name = button_name
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(s, s)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_style(b, color, s)
	return b


## The Big Little Jobs cut-out (`Brand.round_style`, 2026-09-11), the same as
## every other round button in the game now.
func _style(b: Button, color: Color, s: float) -> void:
	b.add_theme_stylebox_override("normal", Brand.round_style(color, int(s * 0.5)))
	b.add_theme_stylebox_override("hover", Brand.round_style(color.lightened(0.08), int(s * 0.5)))
	b.add_theme_stylebox_override("pressed", Brand.round_style(color.darkened(0.12), int(s * 0.5), true))


## A fat white tick, in two strokes.
func _draw_tick(host: Control, s: float) -> void:
	var a := Polygon2D.new()
	a.polygon = PackedVector2Array([
		Vector2(s * 0.28, s * 0.52), Vector2(s * 0.38, s * 0.42),
		Vector2(s * 0.47, s * 0.60), Vector2(s * 0.40, s * 0.68),
	])
	a.color = Color.WHITE
	host.add_child(a)
	var b := Polygon2D.new()
	b.polygon = PackedVector2Array([
		Vector2(s * 0.40, s * 0.68), Vector2(s * 0.36, s * 0.60),
		Vector2(s * 0.70, s * 0.30), Vector2(s * 0.76, s * 0.38),
	])
	b.color = Color.WHITE
	host.add_child(b)


## The volume control: a fat track with a big round handle.
##
## `steps` positions, 0 at the far left and silent. It answers a tap ANYWHERE
## along the track (not just on the handle) and it keeps following a finger that
## has wandered off it vertically, because a four-year-old dragging a thumb does
## not stay inside a 34 px band and losing the volume for that would be the
## control's fault, not theirs.
class VolumeSlider extends Control:
	signal changed(step: int)

	var track_color: Color = Color(0.34, 0.46, 0.58)
	var silent_color: Color = Color(0.80, 0.22, 0.18)
	var handle_color: Color = Color(1.0, 1.0, 1.0)
	var steps: int = 11
	var step: int = 10
	var span: float = 620.0
	var handle: float = 92.0
	var thickness: float = 34.0
	var _down: bool = false

	func setup(w: float, handle_size: float, thick: float, count: int) -> void:
		span = w
		handle = handle_size
		thickness = thick
		steps = maxi(count, 2)
		size = Vector2(w, handle_size)
		custom_minimum_size = size
		mouse_filter = Control.MOUSE_FILTER_STOP
		queue_redraw()

	func set_step(v: int) -> void:
		var was := step
		step = clampi(v, 0, steps - 1)
		if step != was:
			queue_redraw()

	func dragging() -> bool:
		return _down

	## Where along the track step `i` sits, in this control's own space.
	func step_x(i: int) -> float:
		var inset := handle * 0.5
		var run := maxf(size.x - handle, 1.0)
		return inset + run * float(clampi(i, 0, steps - 1)) / float(steps - 1)

	## The step nearest a point given in GLOBAL screen space.
	func step_at(global_point: Vector2) -> int:
		return _step_at_x(global_point.x - global_position.x)

	## The step nearest a distance along the track, in this control's own space.
	func _step_at_x(local_x: float) -> int:
		var inset := handle * 0.5
		var run := maxf(size.x - handle, 1.0)
		var t := clampf((local_x - inset) / run, 0.0, 1.0)
		return int(round(t * float(steps - 1)))

	## Follows a finger that is already down, wherever on the screen it has got
	## to. `SettingsMenu._drag_to` calls this for drags that have left the rect.
	func drag_to(global_point: Vector2) -> void:
		if not _down:
			return
		_set_to(step_at(global_point))

	func _set_to(want: int) -> void:
		if want == step:
			return
		set_step(want)
		changed.emit(step)

	## Every pointer event arrives here in THIS CONTROL'S OWN SPACE - a mouse
	## button's or a mouse motion's `position`, and a touch's or a drag's too -
	## so all four are read as local x along the track.
	##
	## Tree Crew's slider (and this one, as ported) took a touch's and a drag's
	## `position` for a SCREEN position, which it is not here. On glass Godot
	## hands every finger to this function twice - the mouse event it emulates
	## from the touch, then the touch itself, in that order - so the second one
	## of every tap moved the handle to the wrong step: measured by
	## `settings_probe`, a finger on step 8 left the game on step 2, and a drag
	## to step 3 left it silent. A mouse never showed it, which is why a desktop
	## never did. Read in one space, the second event of each pair asks for the
	## step the first already set, and does nothing.
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index != MOUSE_BUTTON_LEFT:
				return
			_down = mb.pressed
			if mb.pressed:
				_set_to(_step_at_x(mb.position.x))
			accept_event()
		elif event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			_down = st.pressed
			if st.pressed:
				_set_to(_step_at_x(st.position.x))
			accept_event()
		elif _down and event is InputEventMouseMotion:
			_set_to(_step_at_x((event as InputEventMouseMotion).position.x))
			accept_event()
		elif _down and event is InputEventScreenDrag:
			_set_to(_step_at_x((event as InputEventScreenDrag).position.x))
			accept_event()

	## Keylined and cast the way every button on this panel is - see
	## `Brand.round_style`. It is drawn by hand rather than styled, so the
	## device has to be drawn by hand too: the track gets a charcoal line
	## underneath it a keyline wider, and the handle gets a charcoal copy of
	## itself thrown down and to the right before the charcoal ring and the
	## white face go on top. Without this the one control on the panel that a
	## finger actually DRAGS was also the only one not cut out of the page.
	func _draw() -> void:
		var mid := size.y * 0.5
		var inset := handle * 0.5
		var left := Vector2(inset, mid)
		var right := Vector2(size.x - inset, mid)
		var r := handle * 0.5
		var edge := maxf(2.0, roundf(r * Brand.BORDER_RATIO))
		var throw := maxf(3.0, r * Brand.SHADOW_RATIO)
		var cast_color := Color(Brand.INK, Brand.SHADOW_ALPHA)
		# The track: its keyline, the whole of it, then the part that is filled.
		draw_line(left + Vector2(throw, throw), right + Vector2(throw, throw), cast_color, thickness, true)
		draw_line(left, right, Brand.INK, thickness + edge * 2.0, true)
		draw_line(left, right, track_color.darkened(0.35), thickness, true)
		var at := Vector2(step_x(step), mid)
		if step > 0:
			draw_line(left, at, track_color, thickness, true)
		# The silent end is marked in the machines' STOP red, so "all the way
		# left is off" is a colour and not a rule anyone has to be told.
		draw_circle(left, thickness * 0.62 + edge, Brand.INK)
		draw_circle(left, thickness * 0.62, silent_color)
		# The handle, last, so it is the thing on top of all of it.
		draw_circle(at + Vector2(throw, throw), r, cast_color)
		draw_circle(at, r, Brand.INK)
		draw_circle(at, r - edge, handle_color)


## A quaver, for the button that turns the song off on its own. Crossed out with
## the same red bar the cog and the ear defenders wear, so "off" is one idea in
## this game and not two.
class MusicNoteIcon extends Control:
	var off: bool = false:
		set(value):
			off = value
			queue_redraw()
	var color: Color = Color.WHITE
	var bar_color: Color = Color(0.86, 0.24, 0.20)

	func setup(s: float, is_off: bool) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(s, s)
		custom_minimum_size = size
		off = is_off

	func _draw() -> void:
		var s := minf(size.x, size.y)
		if s <= 0.0:
			return
		var c := color if not off else Color(0.74, 0.80, 0.88)
		draw_circle(Vector2(s * 0.38, s * 0.66), s * 0.13, c)
		draw_rect(Rect2(s * 0.47, s * 0.26, s * 0.055, s * 0.42), c)
		draw_colored_polygon(PackedVector2Array([
			Vector2(s * 0.525, s * 0.26), Vector2(s * 0.72, s * 0.36), Vector2(s * 0.525, s * 0.44),
		]), c)
		if off:
			draw_line(Vector2(s * 0.16, s * 0.84), Vector2(s * 0.84, s * 0.22), bar_color, s * 0.10)
