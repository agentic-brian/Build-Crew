extends SceneTree
## Builds `assets/brand/splash.png`, the loading screen (DESIGN 23c): the Big
## Little Jobs PRIMARY wordmark (the charcoal cut - the reversed one is drawn
## for dark ground and nearly vanishes on cream) centred on a Warm Cream 16:9
## canvas, half its width.
##
##   godot --headless --path . -s tools/make_splash.gd
##
## Tree Crew's repository shows the bare 1400 x 390 wordmark at its own size
## (`boot_splash/fullsize=false`, which Godot 4.7 reads as `stretch_mode` 0).
## Drawn in physical pixels, that is wider than a 1280 window and loses its
## ends on a desktop; padded into this canvas and scaled to fit
## (`stretch_mode` 1, Keep), it is the same picture on a desktop window, an
## iPad and a phone, and whatever letterbox a screen's shape leaves is the
## same cream (`boot_splash/bg_color`).
##
## The wordmark is this tool's input, not the game's: it lives under
## `tools/brand/` behind a `.gdignore`, so it is never imported or exported.

const LOGO := "res://tools/brand/bl_jobs_logo_primary.png"
const OUT := "res://assets/brand/splash.png"
const SIZE := Vector2i(2800, 1575)
const CREAM := Color(1.0, 0.953, 0.808)


func _initialize() -> void:
	var logo := Image.load_from_file(ProjectSettings.globalize_path(LOGO))
	if logo == null or logo.is_empty():
		push_error("make_splash: cannot read %s" % LOGO)
		quit(1)
		return
	logo.convert(Image.FORMAT_RGBA8)
	var canvas := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	canvas.fill(CREAM)
	# Half the canvas wide, a touch above the middle (the optical centre).
	var w := SIZE.x / 2
	var h := int(round(float(logo.get_height()) * float(w) / float(logo.get_width())))
	logo.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var at := Vector2i((SIZE.x - w) / 2, (SIZE.y - h) / 2 - SIZE.y / 40)
	canvas.blend_rect(logo, Rect2i(Vector2i.ZERO, logo.get_size()), at)
	var err := canvas.save_png(ProjectSettings.globalize_path(OUT))
	print("make_splash: %s %dx%d, the wordmark %dx%d at %s (err %d)" % [OUT, SIZE.x, SIZE.y, w, h, at, err])
	quit(0 if err == OK else 1)
