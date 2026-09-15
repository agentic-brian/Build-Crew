class_name Brand
extends RefCounted
## Big Little Jobs, in the one place every Car Fixer screen can ask.
##
## Brought over from Tree Crew (`../tree-chop/scripts/brand.gd`) on 2026-09-11,
## when the user asked for this game's icons to have "that look and style" -
## the title row of five real machines, each on a coloured disc that is cut out
## and laid on the screen. The source of truth is `Godot-Game1/BRAND_FOUNDATION.md`
## and the kit beside the website in `big-little-jobs-site/brand-assets/`.
##
## What is copied is what a running game needs: the palette, the two typefaces
## and the one drawn device the identity is built out of - taken from Tree
## Crew's REPOSITORY (origin/main), not its working folder, the user's own
## instruction on 2026-09-11 when the title screen and the loading screen came
## over too. The woff2 files are the website's own, byte for byte, and their
## SIL Open Font Licence texts travel with them in `licenses/`.
##
## ## The two faces
##
## Fredoka Bold for anything a child reads as a PICTURE - the title, the cars
## fixed, YAY! - and Nunito Sans for everything else. The project-wide default
## is Nunito Sans (`gui/theme/custom = assets/theme/car_fixer.tres`), so a
## Control that asks for nothing already speaks the brand's interface type;
## display type is asked for by name (`stamp`).
##
## ## The device
##
## Everything on the website is a thing CUT OUT and laid on the page: a solid
## charcoal keyline all the way round it, and a hard-edged charcoal shadow
## offset down and to the right with no blur at all. It reads as a sticker, or a
## workshop sign - sturdy, tactile, cut from something. The soft grey blur these
## buttons carried before (`shadow_size` 12 and a darker bottom lip) is the
## language of glass and depth, and no other Big Little Jobs surface has it.

# --- The palette ------------------------------------------------------------------------

## Worksite Orange `#F49A32`. The master brand's own colour.
const ORANGE := Color(0.957, 0.604, 0.196)
## Safety Yellow `#F8C744`.
const YELLOW := Color(0.973, 0.780, 0.267)
## Action Blue `#357FE8`.
const BLUE := Color(0.208, 0.498, 0.910)
## Result Green `#53B947`.
const GREEN := Color(0.325, 0.725, 0.278)
## Warm Cream `#FFF3CE`.
const CREAM := Color(1.0, 0.953, 0.808)
## Workshop Charcoal `#26323A`. Every keyline and every shadow in the identity
## is this one colour; nothing in the kit is drawn in black.
const INK := Color(0.149, 0.196, 0.227)
## The rust the website uses for a heading's emphasis, `#A84D08`.
const RUST := Color(0.659, 0.302, 0.031)
## Off-white `#FFFAF0`, the website's paper.
const PAPER := Color(1.0, 0.980, 0.941)


# --- Type -------------------------------------------------------------------------------

const DISPLAY_FONT := preload("res://assets/fonts/Fredoka-Bold.woff2")
const BODY_FONT := preload("res://assets/fonts/NunitoSans.woff2")

## How tight display type is set, as a fraction of its size: the website's game
## titles run at `letter-spacing: -.045em`, and Fredoka looks slack at zero.
## Godot tracks in whole pixels, so `display()` is told the size it is for.
const DISPLAY_TRACKING := -0.045


## Fredoka Bold: titles, counters, and anything a pre-reader takes in as a
## shape rather than as a word. `size` only tracks the face in.
static func display(size: int = 0) -> Font:
	if size <= 0:
		return DISPLAY_FONT
	var f := FontVariation.new()
	f.base_font = DISPLAY_FONT
	f.spacing_glyph = int(round(float(size) * DISPLAY_TRACKING))
	return f


## Nunito Sans at a weight on its own axis. 400 is text, 850 is the website's
## interface weight, 950 its loudest label.
static func body(weight: int = 850) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = BODY_FONT
	f.variation_opentype = {"wght": weight}
	return f


## Sets a Label in Fredoka at `size`, tracked in, with the brand's charcoal
## keyline round the letters.
static func stamp(l: Label, size: int, color: Color = CREAM, outline: int = -1) -> void:
	l.add_theme_font_override("font", display(size))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline if outline >= 0 else maxi(3, size / 6))

# --- The cut-out ------------------------------------------------------------------------

## How far the hard shadow is thrown, against the size of the thing throwing
## it: near a tenth of the radius everywhere on the website.
const SHADOW_RATIO := 0.105
## The keyline, likewise. A keyline that does not hold at a glance is the
## whole device failing quietly.
const BORDER_RATIO := 0.05
## How solid the shadow is. The big rounded picture objects on the website get
## a washed shadow; on a lit 3D scene (a garage, a street) a solid charcoal
## shadow butted against a solid charcoal keyline reads as one lumpy ring.
const SHADOW_ALPHA := 0.45


## One thing cut out and laid on the screen: charcoal keyline, hard charcoal
## shadow down and to the right, no blur.
##
## `radius` is the corner rounding and also what the keyline and the shadow are
## measured against, so a 300 px title button and a 92 px house wear the same
## device at their own weights.
##
## `press` slides the object down into its own shadow, the way the website's
## buttons do under a cursor: shrinking the left and top EXPAND margins by as
## much as the right and bottom grow slides the drawing without moving the
## Control, and the shadow gives up the same distance.
##
## `shadow_size` is a BLUR radius in Godot, not the size of the shadow: the
## hard-edged cut-out is `shadow_size = 1` and the whole throw is the offset.
static func round_style(color: Color, radius: int, press: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	var throw := maxf(3.0, float(radius) * SHADOW_RATIO)
	var sunk := throw * 0.45 if press else 0.0
	sb.shadow_size = 1
	sb.shadow_color = Color(INK, SHADOW_ALPHA)
	sb.shadow_offset = Vector2(throw - sunk, throw - sunk)
	sb.set_border_width_all(maxi(2, int(round(float(radius) * BORDER_RATIO))))
	sb.border_color = INK
	sb.anti_aliasing = true
	if sunk > 0.0:
		sb.expand_margin_left = -sunk
		sb.expand_margin_right = sunk
		sb.expand_margin_top = -sunk
		sb.expand_margin_bottom = sunk
	return sb


## The states of a round brand button: it lightens under a finger and presses
## into its shadow when held. `radius` is half the button for a disc.
static func dress_button(b: Button, color: Color, radius: int) -> void:
	b.add_theme_stylebox_override("normal", round_style(color, radius))
	b.add_theme_stylebox_override("hover", round_style(color.lightened(0.08), radius))
	b.add_theme_stylebox_override("pressed", round_style(color.darkened(0.12), radius, true))
	b.add_theme_stylebox_override("disabled", round_style(color, radius))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
