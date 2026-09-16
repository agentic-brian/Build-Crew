class_name ParentalGate
extends Control
## "Ask a grown-up": the check that stands between a child and the one thing in
## this game that leaves it - the privacy policy link in the settings panel.
##
## It exists because of a rule, and the rule is right. An app in the App Store's
## Kids Category must get parental permission before letting anyone link out of
## it, and until this was written the game's honest claim was that there was
## nowhere to go: no network code, no store, no links. Apple ALSO requires the
## privacy policy to be reachable from inside the app, so the two rules together
## say "a way out, behind a door a four-year-old cannot open".
##
## WHY ARITHMETIC AND NOT A HELD BUTTON. A press-and-hold gate is the tempting
## one - it needs no reading and no keypad - and it is the one Apple has
## historically rejected, because holding a finger down is something a toddler
## does by accident every few minutes. Two single digits multiplied, typed into
## a keypad, is the pattern the category actually accepts: a child who cannot
## yet multiply cannot pass it, and an adult passes it in four seconds without
## thinking. The numbers are re-rolled on every open, so it cannot be learnt by
## rote and it cannot be got past by tapping the same place twice.
##
## Nothing about it is drawn for a child. It is the one screen in this game
## written in words, in the interface face, for the person holding the tablet -
## the same reasoning as the "by" under the title.

## The gate was passed. The caller opens whatever it was guarding.
signal passed
## The grown-up backed out, or got it wrong and gave up.
signal dismissed

## Both factors come from here, so the product is always two digits and never
## something an adult has to think about. 3..9 keeps 1x and 2x off the table -
## a five-year-old who can count can sometimes do those.
const LOW := 3
const HIGH := 9

## Sized to fit a 720-high viewport with room to spare, which is the
## shortest this game ever gets: `canvas_items` + `expand` keeps the
## smaller scale factor, so a screen wider than 16:9 leaves the height at
## the base 720 and a taller one only grows it. The first draft was 620
## tall with 96 px keys and put its bottom row - back, zero, OK - off the
## bottom of the screen on every phone and on the design size too.
@export var panel_size: Vector2 = Vector2(540.0, 630.0)
@export var key_size: float = 82.0
@export var key_gap: float = 12.0
@export var dim_color: Color = Color(0.03, 0.08, 0.04, 0.72)

var _a: int = 0
var _b: int = 0
var _typed: String = ""
var _question: Label
var _answer: Label
var _hint: Label
var _card: Control
var _shake: Tween

## How many wrong answers this opening has had. Nothing is locked out - a
## grown-up mistypes too - but the wording softens after the first.
var _wrong: int = 0


func _ready() -> void:
	name = "ParentalGate"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Swallows every tap that misses the card, so nothing behind the gate is
	# reachable while it is up.
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = dim_color
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if _is_release(e):
			dismiss())
	add_child(dim)

	_card = Control.new()
	_card.name = "Card"
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_centre(_card, -panel_size.x * 0.5, panel_size.x * 0.5,
			-panel_size.y * 0.5, panel_size.y * 0.5)
	add_child(_card)

	var bg := Panel.new()
	bg.name = "Card BG"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", Brand.round_style(Brand.PAPER, 34))
	_card.add_child(bg)

	var title := Label.new()
	title.name = "Title"
	title.text = "Ask a grown-up"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Brand.stamp(title, 38, Brand.INK, 0)
	_span(title, 20.0, 70.0)
	_card.add_child(title)

	_question = Label.new()
	_question.name = "Question"
	_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_question.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Brand.stamp(_question, 54, Brand.RUST, 0)
	_span(_question, 74.0, 136.0)
	_card.add_child(_question)

	# The typed digits sit in a sunken slot so it is obvious they are going
	# somewhere, rather than floating under the sum.
	var slot := Panel.new()
	slot.name = "Slot"
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Brand.INK, 0.07)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Color(Brand.INK, 0.35)
	slot.add_theme_stylebox_override("panel", sb)
	slot.anchor_left = 0.5
	slot.anchor_right = 0.5
	slot.offset_left = -102.0
	slot.offset_right = 102.0
	slot.offset_top = 142.0
	slot.offset_bottom = 200.0
	_card.add_child(slot)

	_answer = Label.new()
	_answer.name = "Answer"
	_answer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_answer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_answer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Brand.stamp(_answer, 40, Brand.INK, 0)
	_answer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(_answer)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Nunito Sans: this line is a caption for an adult, not a title for a child.
	_hint.add_theme_font_override("font", Brand.body(700))
	_hint.add_theme_font_size_override("font_size", 17)
	_hint.add_theme_color_override("font_color", Color(Brand.INK, 0.62))
	_span(_hint, 206.0, 234.0)
	_card.add_child(_hint)

	_build_keypad()


## Ten digits in three rows of three with the zero under the middle, which is
## every keypad anyone has ever used, plus a back arrow and a tick either side
## of it.
func _build_keypad() -> void:
	var cols := 3.0
	var span := key_size * cols + key_gap * (cols - 1.0)
	var left := -span * 0.5
	# Four rows of keys end at `top + 4 * (key + gap) - gap`, which with the
	# numbers above is 244 + 364 = 608, inside a 630 card. Move any of the
	# three and check the bottom row is still on the screen.
	var top := 244.0
	for i in range(9):
		var d := i + 1
		var col := float(i % 3)
		var row := float(i / 3)
		_key(str(d), left + col * (key_size + key_gap), top + row * (key_size + key_gap),
				Brand.CREAM, func() -> void: _type(str(d)))
	var last := top + 3.0 * (key_size + key_gap)
	# Undo on the left, zero in the middle, go on the right.
	_key("<", left, last, Brand.YELLOW, _rub_out)
	_key("0", left + (key_size + key_gap), last, Brand.CREAM, func() -> void: _type("0"))
	_key("OK", left + 2.0 * (key_size + key_gap), last, Brand.GREEN, _submit)


func _key(text: String, x: float, y: float, color: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.name = "Key" + text
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(key_size, key_size)
	Brand.dress_button(b, color, int(key_size * 0.28))
	b.add_theme_font_override("font", Brand.display())
	b.add_theme_font_size_override("font_size", 34 if text.length() < 2 else 26)
	b.add_theme_color_override("font_color", Brand.INK)
	b.add_theme_color_override("font_hover_color", Brand.INK)
	b.add_theme_color_override("font_pressed_color", Brand.INK)
	b.anchor_left = 0.5
	b.anchor_right = 0.5
	b.offset_left = x
	b.offset_right = x + key_size
	b.offset_top = y
	b.offset_bottom = y + key_size
	b.pressed.connect(on_press)
	_card.add_child(b)
	return b


func _centre(c: Control, left: float, right: float, top: float, bottom: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.offset_left = left
	c.offset_right = right
	c.offset_top = top
	c.offset_bottom = bottom


## Full width of the card, between two heights.
func _span(c: Control, top: float, bottom: float) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 1.0
	c.offset_left = 0.0
	c.offset_right = 0.0
	c.offset_top = top
	c.offset_bottom = bottom


# --- Opening and closing ---------------------------------------------------------------

## Shows the gate with a fresh sum. Every opening re-rolls, so the answer cannot
## be learnt and a child cannot get through by repeating what they saw.
func ask() -> void:
	_a = randi_range(LOW, HIGH)
	_b = randi_range(LOW, HIGH)
	_typed = ""
	_wrong = 0
	_question.text = "%d  x  %d" % [_a, _b]
	_hint.text = "Type the answer to continue"
	_hint.add_theme_color_override("font_color", Color(Brand.INK, 0.62))
	_refresh()
	# Centred in the SAFE area (DESIGN 32): the home indicator takes a phone's
	# bottom edge.
	if _card != null:
		var safe := SafeArea.insets(get_viewport())
		var shift := Vector2((safe.x - safe.z) * 0.5, (safe.y - safe.w) * 0.5)
		_centre(_card, -panel_size.x * 0.5 + shift.x, panel_size.x * 0.5 + shift.x,
				-panel_size.y * 0.5 + shift.y, panel_size.y * 0.5 + shift.y)
	visible = true


func dismiss() -> void:
	if not visible:
		return
	visible = false
	dismissed.emit()


## Is the gate up? For the panel behind it, and for tests.
func is_asking() -> bool:
	return visible


## The sum being asked, for tests. Nothing in the game should need it.
func expected() -> int:
	return _a * _b


func typed() -> String:
	return _typed


# --- The keypad ------------------------------------------------------------------------

func _type(digit: String) -> void:
	# Two digits is always enough: 3..9 squared tops out at 81.
	if _typed.length() >= 2:
		return
	if _typed == "" and digit == "0":
		return
	_typed += digit
	_refresh()


func _rub_out() -> void:
	if _typed == "":
		# An empty slot and a back arrow is the way out, so a grown-up who
		# opened this by accident is never stuck behind it.
		dismiss()
		return
	_typed = _typed.substr(0, _typed.length() - 1)
	_refresh()


func _submit() -> void:
	if _typed == "":
		return
	if int(_typed) == expected():
		visible = false
		passed.emit()
		return
	_wrong += 1
	_typed = ""
	_refresh()
	_hint.text = "Not quite - try again" if _wrong < 2 else "Try again, or tap outside to go back"
	_hint.add_theme_color_override("font_color", Brand.RUST)
	_shake_card()


func _refresh() -> void:
	# A dash rather than an empty box: something is always in the slot, so it
	# never reads as broken.
	_answer.text = _typed if _typed != "" else "-"


func _shake_card() -> void:
	if _shake != null and _shake.is_valid():
		_shake.kill()
	_card.position.x = 0.0
	_shake = create_tween()
	for dx in [14.0, -12.0, 8.0, -5.0, 0.0]:
		_shake.tween_property(_card, "position:x", dx, 0.05).set_trans(Tween.TRANS_SINE)


func _is_release(e: InputEvent) -> bool:
	if e is InputEventScreenTouch:
		return not (e as InputEventScreenTouch).pressed
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		return mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed
	return false
