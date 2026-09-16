class_name Settings
extends RefCounted
## How loud the game is, and whether the song is on. Two numbers, their own
## little file, and the two audio buses they drive.
##
## It is a BUS PAIR and not a pile of volume_db writes, for one measured reason:
## Sfx's procedural fallback synth has its volume set once in `_ready` and never
## again, and it takes no group trim - so a volume knob that walked the players
## would leave the fallback roaring in a game the child had just turned off. A
## bus cannot miss a player. The per-group trims in `Sfx.group_gain_db` stay
## exactly as the author tuned them; the buses sit underneath as one hand on the
## whole mix.
##
## It is NOT a key in the game save. `SaveGame.enabled` is switched off by every
## harness and by `main.gd`, and only `main.gd` ever touches it - a setting
## living there would be invisible to the whole test suite and unreachable from
## five of the six screens. It would also be wiped by a save reset meant only to
## clear a child's chips.
##
## Brought over from Tree Crew's repository (origin/main bf29315) on 2026-09-11
## with the slider, the cog and the privacy link: everything below is Tree
## Crew's except the file name and the season pin, which is a Tree Crew thing
## (there is no year turning in a garage).

const FILE := "user://build_crew_settings.json"
## 2 since 2026-09-11, when the four-rung ladder became an eleven-step SLIDER
## (Tree Crew made the same change on 2026-09-08). A version 1 file holds a
## loudness of 0..3 and is rescaled on the way in; see `load_settings`. Without
## that a returning child's LOUD (3) would come back as a third of the way up
## the new scale.
const VERSION := 2

## Steps on the slider, loudest last: 0 is OFF, 1..10 climb to the mix the
## author tuned by hand.
##
## It was FOUR, drawn as a ladder of four fat discs, and the reasoning for that
## was explicitly "no slider, because a child who cannot read cannot aim at
## one". The feel-tester asked for a slider anyway, and they are right about the
## thing the argument missed: aiming is not what a slider asks of you. Dragging
## is, and dragging a big handle along a fat track is a gesture a three-year-old
## already has. Ten steps is fine enough to feel continuous under a thumb and
## coarse enough that every one of them is a different loudness.
const RUNGS := 11

## The loudness curve, in dB per step, built once from the anchors below.
##
## They are `static var` and not `const` because they are COMPUTED - and they
## are computed so that widening the slider could not quietly retune the mix.
## The three anchors are the old four-rung ladder's own values, and everything
## between them is interpolated, so the quietest audible step, the middle and
## the top are the numbers that were tuned by ear.
static var SFX_DB: Array[float] = []
static var MUSIC_DB: Array[float] = []

## Where the authored rungs sit on the new scale, and what they were worth.
## Step 10 is 0 dB on both buses, so a fresh install sounds EXACTLY like the
## game did before any of this existed: the slider only ever goes DOWN from the
## mix the author tuned, and nothing a child can drag makes it louder.
const ANCHOR_STEP: Array[int] = [1, 6, 10]
const ANCHOR_SFX: Array[float] = [-16.0, -7.0, 0.0]
## The song always ducks harder than the machines. In the middle the music is
## well back while the impact wrench still rattles, which is the split a
## four-year-old cannot be asked to make with two separate dials.
##
## But only a LITTLE harder, and here is the sum that fixes the size of it. The
## two players are already trimmed apart in `sfx.gd`: the song sits at -15 dB
## and the clips at -12, so the song starts 3 dB down before this table is
## touched at all. The quiet end was once -22 against the machines' -16, which
## put the song 9 dB under them and about 1.4% of the mix - inaudible on a
## tablet speaker, and doing the same job as the blue SONG-OFF button beside it.
## -19 leaves the song a steady 6-7 dB under the machines through the middle of
## the slider: plainly quieter, still plainly there.
const ANCHOR_MUSIC: Array[float] = [-19.0, -11.0, 0.0]


static func _static_init() -> void:
	SFX_DB = _ladder(ANCHOR_SFX)
	MUSIC_DB = _ladder(ANCHOR_MUSIC)


## One dB value per step, straight-line between the authored anchors. Step 0 is
## given the quiet end's value; it is muted anyway, and a bus that is about to
## be muted should not first jump.
static func _ladder(anchors: Array[float]) -> Array[float]:
	var out: Array[float] = []
	for step in range(RUNGS):
		out.append(_at(maxi(step, ANCHOR_STEP[0]), anchors))
	return out


static func _at(step: int, anchors: Array[float]) -> float:
	if step <= ANCHOR_STEP[0]:
		return anchors[0]
	for i in range(1, ANCHOR_STEP.size()):
		if step <= ANCHOR_STEP[i]:
			var lo := ANCHOR_STEP[i - 1]
			var hi := ANCHOR_STEP[i]
			var t := float(step - lo) / float(maxi(hi - lo, 1))
			return lerpf(anchors[i - 1], anchors[i], t)
	return anchors[anchors.size() - 1]


## The four-level picture the ear defenders draw, from a step on the slider.
## The icon speaks in quarters and the slider in tenths; this is the one place
## that conversion is written down.
static func ear_level(step: int) -> int:
	if step <= 0:
		return 0
	return clampi(1 + int(round(float(step - 1) * 2.0 / float(RUNGS - 2))), 1, 3)

## Harnesses may switch this off, but they are asked to point `path_override` at
## a scratch file instead: a settings store nobody tests is a settings store
## that quietly stops working.
static var enabled: bool = true
static var path_override: String = ""

## The OS's "reduce animation" switch (6.4, part 7), read ONCE and kept: a
## DisplayServer query every frame is not free, and a flag that can change under
## a running test is a test decided by the developer's own Windows settings.
##
## `motion_override` is how a harness decides it instead - 0 unset, 1 on, -1 off
## - the same shape `SafeArea.probe_active` uses. EVERY probe sets -1: the
## smoke measures the camera's own shake in two places, and would otherwise go
## red on any machine whose owner has animations turned off.
static var motion_override: int = 0
static var _motion_known: bool = false
static var _motion: bool = false

## Which step of the slider the game is on, 0..RUNGS-1.
static var loudness: int = RUNGS - 1
## Is the song itself on? Separate from the slider, because "turn the music
## off, keep the machines" is the one thing an adult in the room actually asks
## for.
static var music_on: bool = true

static var _loaded: bool = false


static func file_path() -> String:
	return path_override if path_override != "" else FILE


## Is there a settings FILE for this run at all?
##
## `path_override` is the explicit yes: every harness that wants to exercise the
## real read/apply/write path points it at a scratch file, and those are the runs
## that test this class.
##
## Without one, the game save's own switch decides. `Sfx._ready` calls `ensure()`
## on every screen, so instantiating any level used to read the developer's own
## settings file and push it onto the buses - which made the smoke suites start
## from whatever volume the developer last left the real game on. A harness that
## has switched `SaveGame` off has already said "this is not the child's game";
## it now gets the defaults rather than their file. The real game never sets
## that flag false before `Sfx._ready`, so a child's chosen loudness still comes
## back on every launch.
## Is the picture to hold still for somebody who asked the OS for that? What
## stops is the CAMERA's shake; the work itself - the slab giving way, the bit's
## stroke, the rings saying where to tap, every answer to a finger - still moves,
## because a toy that stops answering is not an accessible toy.
static func motion_reduced() -> bool:
	if motion_override != 0:
		return motion_override > 0
	if not _motion_known:
		_motion_known = true
		_motion = DisplayServer.accessibility_should_reduce_animation()
	return _motion


static func persists() -> bool:
	return enabled and (path_override != "" or SaveGame.enabled)


## Everything, once, in the right order: buses, then the file, then apply.
## Idempotent and safe to call from anywhere - `Sfx._ready` calls it before it
## builds a single player, which is the one hook every screen and every headless
## harness passes through.
static func ensure() -> void:
	ensure_buses()
	if not _loaded:
		_loaded = true
		load_settings()
	apply()


const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"


## A Music bus and an SFX bus, both sending to Master. On a stock layout (Master
## alone) they land at 1 and 2, which is what the probes check.
##
## Built in code rather than from a checked-in `default_bus_layout.tres`,
## because this project has no bus-layout convention and the headless harnesses
## instantiate levels directly with no boot scene to load one. It matters that
## this cannot silently fail: a player handed a bus name that does not exist
## does NOT error, it just reports "Master" - so a missing layout would turn
## every volume control into a no-op with nothing on screen or in the log to say
## so. `settings_probe` asserts the names and the routing for that reason.
##
## Done BY NAME, and by ADDING rather than by counting and renaming. The obvious
## version - grow the layout to three and rename buses 1 and 2 - is a trap that
## only springs later: `set_bus_name` does not complain when the name is taken
## (it silently appends a number) and it will happily rename a bus somebody else
## made. The day a `default_bus_layout.tres` appears in this project with, say, a
## Voice bus in it, that version renames Voice to Music, the narration players
## fall back to Master, and it is the exact silent-routing failure the paragraph
## above is about. Looking the names up first removes the whole class.
static func ensure_buses() -> void:
	if music_bus() < 0:
		_add_bus(MUSIC_BUS)
	if sfx_bus() < 0:
		_add_bus(SFX_BUS)
	# Cheap, and the one thing that must be true however the layout was built.
	var m := music_bus()
	var s := sfx_bus()
	if m > 0 and AudioServer.get_bus_send(m) != "Master":
		AudioServer.set_bus_send(m, "Master")
	if s > 0 and AudioServer.get_bus_send(s) != "Master":
		AudioServer.set_bus_send(s, "Master")


static func _add_bus(bus_name: String) -> void:
	var at := AudioServer.bus_count
	AudioServer.add_bus(at)
	AudioServer.set_bus_name(at, bus_name)
	AudioServer.set_bus_send(at, "Master")


static func music_bus() -> int:
	return AudioServer.get_bus_index(MUSIC_BUS)


static func sfx_bus() -> int:
	return AudioServer.get_bus_index(SFX_BUS)


## Writes the two numbers onto the two buses.
##
## Volume is always taken from `max(loudness, 1)` and silence is always the MUTE
## FLAG, never a volume of zero: `linear_to_db(0.0)` is -inf, and a bus mute is
## independent of the bus volume, so un-muting comes back to exactly the step
## the child left it on and nothing anywhere has to be restarted. A muted player
## still reports `playing == true`, which is what keeps mute from being a trap.
##
## Master's own mute flag is deliberately untouched: in Tree Crew `main.gd` owns
## it for the clearing's pause screen, and the settings panel only ever borrows
## it (see `SettingsMenu._preview_audible`).
static func apply() -> void:
	ensure_buses()
	var m := music_bus()
	var s := sfx_bus()
	if m < 0 or s < 0:
		return
	var step := maxi(loudness, 1)
	AudioServer.set_bus_volume_db(m, MUSIC_DB[step])
	AudioServer.set_bus_volume_db(s, SFX_DB[step])
	AudioServer.set_bus_mute(s, loudness == 0)
	AudioServer.set_bus_mute(m, loudness == 0 or not music_on)


static func set_loudness(n: int) -> void:
	loudness = clampi(n, 0, RUNGS - 1)
	apply()
	save_settings()


static func set_music_on(on: bool) -> void:
	music_on = on
	apply()
	save_settings()


## True when everything is silent - what the red bar across the cog and the ear
## defenders means.
static func is_muted() -> bool:
	return loudness == 0


## True when the song alone has been switched off and the machines are still
## running. The panel's big ear defenders draw a crossed-out note for this,
## because otherwise the one state a parent most often chooses would be
## invisible: a game with the music deliberately killed a week ago looked
## exactly like an untouched one.
static func song_off() -> bool:
	return not music_on and loudness > 0


static func load_settings() -> void:
	if not persists():
		apply()
		return
	var path := file_path()
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return
	var d: Dictionary = parsed
	if int(d.get("version", 0)) > VERSION:
		return
	var was := int(d.get("version", 0))
	var raw := int(d.get("loudness", RUNGS - 1))
	if was < 2:
		# A version 1 file is on the old four-rung ladder. 0 stays off; 1, 2 and
		# 3 were the three audible rungs and land on the steps the new slider
		# borrowed their dB from, so a returning child's game is exactly as loud
		# as they left it.
		raw = [0, ANCHOR_STEP[0], ANCHOR_STEP[1], ANCHOR_STEP[2]][clampi(raw, 0, 3)]
	loudness = clampi(raw, 0, RUNGS - 1)
	music_on = bool(d.get("music_on", true))


## Written on the tap that changed something, not on close: a four-year-old's
## session ends by the tablet being taken away, not by an orderly shutdown.
## Sixty bytes; there is no reason to defer it.
static func save_settings() -> bool:
	if not persists():
		return false
	var f := FileAccess.open(file_path(), FileAccess.WRITE)
	if f == null:
		push_warning("Settings: cannot write %s (%d)" % [file_path(), FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify({"version": VERSION, "loudness": loudness, "music_on": music_on}, "\t"))
	f.close()
	return true


## Removes the settings file (a parent's reset, or a test cleaning up).
static func clear() -> void:
	var path := file_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Forgets that the file has been read, so the next `ensure()` reads it again.
## Only the probes want this; the game reads its settings once per launch.
static func forget_load() -> void:
	_loaded = false


## What the buses actually say right now, for the probes. Nothing else should
## need this: the game asks the buses through `apply()`, never the other way.
static func bus_report() -> Dictionary:
	var m := maxi(music_bus(), 0)
	var s := maxi(sfx_bus(), 0)
	return {
		"count": AudioServer.bus_count,
		"music": music_bus(),
		"sfx": sfx_bus(),
		"music_db": AudioServer.get_bus_volume_db(m),
		"sfx_db": AudioServer.get_bus_volume_db(s),
		"music_mute": AudioServer.is_bus_mute(m),
		"sfx_mute": AudioServer.is_bus_mute(s),
		"master_mute": AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")),
	}


## The cog every menu button in every application the child's parents have ever
## used is drawn with. It is the corner button on all three screens.
##
## The corner button wore a pair of ear defenders until 2026-09-11 (Tree Crew's
## until 2026-09-08), on the argument that the picture should BE the state -
## three waves loud, one quiet, a red bar across it off. Tree Crew's feel-tester
## answered that it did not read as a button you press to open something, which
## is the first thing it has to do; a cog does, to a child who has watched an
## adult tap one, and to the adult.
##
## The one piece of state worth keeping is kept: a game with the sound off wears
## the same red bar, because a game deliberately silenced a week ago otherwise
## looks exactly like an untouched one.
class GearIcon extends Control:
	var muted: bool = false:
		set(value):
			muted = value
			queue_redraw()
	var color: Color = Color.WHITE:
		set(value):
			color = value
			queue_redraw()
	var bar_color: Color = Color(0.86, 0.24, 0.20)
	## Teeth round the rim. Eight reads as a cog at 92 px; more turns to fringe.
	var teeth: int = 8

	func setup(s: float, is_muted: bool) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(s, s)
		custom_minimum_size = size
		muted = is_muted

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size * 0.5
		var rim := s * 0.30
		var tooth_out := s * 0.40
		var half := PI / float(teeth) * 0.42
		# The body, then a tooth per spoke drawn as a fat trapezium standing on
		# the rim, then the hole punched through the middle.
		draw_circle(c, rim, color)
		for i in range(teeth):
			var a := TAU * float(i) / float(teeth)
			var pts := PackedVector2Array([
				c + Vector2(cos(a - half), sin(a - half)) * (rim * 0.92),
				c + Vector2(cos(a - half * 0.72), sin(a - half * 0.72)) * tooth_out,
				c + Vector2(cos(a + half * 0.72), sin(a + half * 0.72)) * tooth_out,
				c + Vector2(cos(a + half), sin(a + half)) * (rim * 0.92),
			])
			draw_colored_polygon(pts, color)
		# The hole is drawn as a darker disc, which is what a cog's shadowed bore
		# looks like anyway: a disc of a guessed background colour would be wrong
		# on a pressed button.
		draw_circle(c, s * 0.125, color.darkened(0.55))
		if muted:
			var r := s * 0.42
			var d := Vector2(cos(-PI * 0.25), sin(-PI * 0.25)) * r
			draw_line(c - d, c + d, bar_color, maxf(s * 0.10, 3.0))


## A loudspeaker with waves coming out of it - the glyph every volume control
## anywhere is drawn with. One sits at each end of the slider: crossed out at
## the silent end, three waves at the loud end.
##
## The panel already had a big pair of ear defenders at the top of it, and ear
## defenders mean "hearing protection", not "volume". With the ladder gone and a
## slider in its place, the slider needed to say what it was FOR - and a
## pre-reader who has watched an adult use a phone has seen this shape.
class SpeakerIcon extends Control:
	## How many arcs come off the cone. 0 draws the box alone (the quiet end).
	var waves: int = 3:
		set(value):
			waves = clampi(value, 0, 3)
			queue_redraw()
	## A bar through it: this end is silence.
	var crossed: bool = false:
		set(value):
			crossed = value
			queue_redraw()
	var color: Color = Color.WHITE:
		set(value):
			color = value
			queue_redraw()
	var bar_color: Color = Color(0.86, 0.24, 0.20)

	func setup(s: float, wave_count: int, is_crossed: bool = false) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(s, s)
		custom_minimum_size = size
		waves = wave_count
		crossed = is_crossed

	func _draw() -> void:
		var s := minf(size.x, size.y)
		if s <= 0.0:
			return
		# The cone: a small box at the back with a trumpet opening forward,
		# drawn as one polygon so it reads at 40 px.
		var cx := s * 0.30
		var cy := s * 0.5
		draw_colored_polygon(PackedVector2Array([
			Vector2(s * 0.10, cy - s * 0.11), Vector2(cx, cy - s * 0.11),
			Vector2(s * 0.46, cy - s * 0.30), Vector2(s * 0.46, cy + s * 0.30),
			Vector2(cx, cy + s * 0.11), Vector2(s * 0.10, cy + s * 0.11),
		]), color)
		# Three arcs, each further out and each a little wider, so the stack
		# reads as sound coming out rather than as a bracket.
		for i in range(waves):
			var r := s * (0.20 + 0.13 * float(i + 1))
			var spread := deg_to_rad(38.0 + 7.0 * float(i))
			draw_arc(Vector2(s * 0.44, cy), r, -spread, spread, 16, color, maxf(s * 0.07, 2.0), true)
		if crossed:
			var d := Vector2(1.0, 1.0).normalized() * (s * 0.30)
			var at := Vector2(s * 0.66, cy)
			draw_line(at - d, at + d, bar_color, maxf(s * 0.10, 3.0))


## A pair of ear defenders, drawn rather than textured, the way every other icon
## on the settings panel is. It is the big picture at the top of the panel,
## mirroring the choice: the waves grow and shrink with the slider and the red
## bar appears at OFF.
##
## It lives here, in the store rather than in the menu, so any HUD that wants
## one can draw it without depending on the menu to do it.
##
## `level` is how many little sound waves stand beside the right cup (0..3), and
## `muted` lays the red bar across the whole thing. Between them a child can see
## whether the game is loud, quiet or off without reading a word.
##
## `song_off` is the third thing it has to say: when the song alone is off a
## small crossed-out quaver sits in the top-right of the square, in the same red
## as the big bar, so "off" stays one idea in this game and not two.
class EarDefenderIcon extends Control:
	var level: int = 3:
		set(value):
			level = clampi(value, 0, 3)
			queue_redraw()
	var muted: bool = false:
		set(value):
			muted = value
			queue_redraw()
	## The song alone is off. Ignored while `muted`, which already says
	## everything is: two crossings-out on one disc is noise, not a state.
	var song_off: bool = false:
		set(value):
			song_off = value
			queue_redraw()
	var color: Color = Color.WHITE:
		set(value):
			color = value
			queue_redraw()
	var bar_color: Color = Color(0.86, 0.24, 0.20)

	## Sizes itself to a square of side `s` and never takes a tap: the button
	## underneath it is what a finger presses.
	func setup(s: float, lvl: int, is_muted: bool, no_song: bool = false) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(s, s)
		custom_minimum_size = size
		level = lvl
		muted = is_muted
		song_off = no_song

	## Everything the picture says, from the store, in one call. Every screen
	## that draws one of these uses it, so none of them can drift.
	func show_settings() -> void:
		# The icon speaks in quarters and the slider in tenths; `ear_level` is
		# the one place that conversion lives.
		level = Settings.ear_level(Settings.loudness)
		muted = Settings.is_muted()
		song_off = Settings.song_off()

	func _draw() -> void:
		var s := minf(size.x, size.y)
		if s <= 0.0:
			return
		var c := color if not muted else Color(0.62, 0.66, 0.68)
		# The headband, arching between the two cups.
		draw_arc(Vector2(s * 0.375, s * 0.58), s * 0.22, PI, TAU, 24, c, s * 0.085)
		# Two capsule cups hanging off its ends.
		_cup(s * 0.08, s, c)
		_cup(s * 0.52, s, c)
		# The waves: none when the game is off, three when it is loud.
		for i in range(level):
			draw_arc(Vector2(s * 0.70, s * 0.65), s * (0.07 + 0.06 * float(i)), -0.55, 0.55, 14, c, s * 0.05)
		if muted:
			draw_line(Vector2(s * 0.12, s * 0.86), Vector2(s * 0.88, s * 0.20), bar_color, s * 0.10)
		elif song_off:
			_crossed_note(s)

	## A little quaver with the red bar through it, tucked into the top-right
	## corner the headband and the waves both leave empty.
	func _crossed_note(s: float) -> void:
		var c := color
		draw_circle(Vector2(s * 0.70, s * 0.255), s * 0.055, c)
		draw_rect(Rect2(s * 0.745, s * 0.075, s * 0.026, s * 0.19), c)
		draw_colored_polygon(PackedVector2Array([
			Vector2(s * 0.771, s * 0.075), Vector2(s * 0.875, s * 0.125), Vector2(s * 0.771, s * 0.165),
		]), c)
		draw_line(Vector2(s * 0.60, s * 0.34), Vector2(s * 0.95, s * 0.03), bar_color, s * 0.055)

	func _cup(x: float, s: float, c: Color) -> void:
		var w := s * 0.15
		var top := s * 0.50
		var h := s * 0.30
		draw_circle(Vector2(x + w * 0.5, top + w * 0.5), w * 0.5, c)
		draw_circle(Vector2(x + w * 0.5, top + h - w * 0.5), w * 0.5, c)
		draw_rect(Rect2(x, top + w * 0.5, w, h - w), c)
