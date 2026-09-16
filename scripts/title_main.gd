class_name TitleMain
extends Node3D
## The title row (the improvement plan's 6.3): where the app opens, where NEXT
## and the house come back to, and where a child says which job to do - or
## whether to carry on the one they left.
##
## THE BACKDROP IS THE LOT ITSELF. `scenes/site.tscn` is instanced as this
## scene's first child with `dress_only` set, so it poses itself and then stands
## there: no HUD, no music of its own, no beats, no input, and never the save.
## Which picture it poses is the whole of this screen's honesty:
##
##   * nothing saved, nothing finished: a fresh visit's CRACKED drive, in the
##     morning, on the wide. It says what the job is, and promises no reward
##     that has not been earned.
##   * a job the child left: their own drive exactly as they left it, at the row
##     they left it on. The seat then carries on; the corner disc throws it away.
##   * a job just finished: the new drive with the car parked on it, in the
##     evening light of the payoff. The reward is still standing behind the next
##     choice, which is what the cut to a title screen usually throws away.
##
## There is no camera and no `Sfx` in `scenes/main.tscn` on purpose: the
## backdrop brings both. Godot makes the FIRST camera to enter the world
## current, so a camera declared here would quietly take the frame off the
## composed shot, and a second `Sfx` would play a second song.

## The job the seat asked for, when this scene is not the current one (a
## harness): there is no scene to cut to, so the ask is a signal instead.
signal job_requested(job: String, carry_on: bool)

const LEVEL_SCENE := "res://scenes/site.tscn"
## How long the press is seen and heard before the cut: the disc's own kick is
## 0.10 s, and the scene change takes the sound with it.
const CUT_DELAY := 0.22

var _lot: SiteMain
var _menu: StartMenu
## "carry_on" while there is a job the LEVEL agrees it can resume, else "fresh".
var _mode: String = "fresh"
## What the press decided, for the tests.
var _pick: Dictionary = {}
## One cut per screen: a second press while the first is still going would
## consume the metas again and take the scene out from under the first.
var _leaving: bool = false


func _ready() -> void:
	var args: Dictionary = Engine.get_meta("shot_args", {}) as Dictionary
	_menu = get_node_or_null("StartMenu") as StartMenu
	# The visit that was just finished, left by `SiteMain._on_next`. Taken, so
	# the reward is shown once and the next launch opens on a fresh drive.
	var last := -1
	if Engine.has_meta(SiteMain.LAST_SEED_META):
		last = SiteLook.parse_seed(Engine.get_meta(SiteMain.LAST_SEED_META))
		Engine.remove_meta(SiteMain.LAST_SEED_META)
	if args.has("last") and last < 0:
		# `--last` for a frame of the reward without playing a job.
		last = SiteLook.parse_seed(args.get("seed", "0"))
	var pinned := SiteLook.parse_seed(args.get("seed", "")) if args.has("seed") else -1
	_place_lot(last, pinned)
	_mode = "carry_on" if _lot != null and _lot.resume_ready() else "fresh"
	# A save the LEVEL would refuse (another job, a row count that moved, a verb
	# it has not got) is cleared here, where the child's choice is made, rather
	# than left to be silently ignored on the next launch.
	# Only when the LEVEL itself refused the save (there is a lot, and it says
	# there is nothing to resume). A lot that failed to build has judged nothing,
	# and a child's job must not be thrown away by a missing scene file.
	if _mode == "fresh" and _lot != null and SaveGame.enabled and SaveGame.exists():
		SaveGame.clear()
	if _lot != null and _lot.sfx != null and _lot.sfx.has_method("start_music"):
		_lot.sfx.start_music("site")
	# The settings panel (6.4) is a sibling of the row, and the `Sfx` it wants to
	# quieten belongs to the lot this screen instanced - so it is pushed in, not
	# looked up. Duck-typed: a harness may stand this screen up without a panel.
	var settings := get_node_or_null("Settings")
	if settings != null and settings.has_method("set_sfx"):
		settings.call("set_sfx", _lot.sfx if _lot != null else null)
	if _menu != null:
		_menu.set_sfx(_lot.sfx if _lot != null else null)
		_menu.set_mode(_mode == "carry_on")
		_menu.seat_pressed.connect(_on_seat)
		_menu.fresh_pressed.connect(_on_fresh)
	print("TITLE %s seed %d stage %s" % [_mode, _lot.play_seed if _lot != null else -1,
		_lot.dress_stage if _lot != null else "-"])


## The lot, idling. Every `dress_*` property is set BEFORE `add_child`:
## `_enter_tree` runs on `add_child` and the driveway builds its panels in its
## own `_ready`, so a flag set afterwards is a flag that did nothing.
func _notification(what: int) -> void:
	# The same reason `SiteMain` has one: an iOS app is suspended, not killed, so
	# a parent who turned Reduce Motion on while they were away comes back to a
	# process holding the answer it read at launch. Ask again on the way in.
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_UNPAUSED:
		Settings.forget_motion()


func _place_lot(last: int, pinned: int) -> void:
	if not ResourceLoader.exists(LEVEL_SCENE):
		# Never a placeholder box behind a title: an empty sky reads better.
		var cam := Camera3D.new()
		cam.name = "Camera3D"
		add_child(cam)
		return
	var packed := load(LEVEL_SCENE) as PackedScene
	var inst := packed.instantiate() as SiteMain if packed != null else null
	if inst == null:
		return
	inst.name = "Lot"
	inst.dress_only = true
	if last >= 0:
		inst.dress_seed = last
		inst.dress_stage = "parked"
		inst.dress_shot = "PAYOFF"
		inst.dress_from_save = false
	else:
		inst.dress_seed = pinned if pinned >= 0 else SiteLook.draw_fresh({})
		inst.dress_stage = "old"
		inst.dress_shot = "WIDE"
		inst.dress_from_save = SaveGame.enabled and SaveGame.exists()
	add_child(inst)
	move_child(inst, 0)
	_lot = inst


## A job's disc: start the drive the child is looking at, or carry on the one
## they left. The tap is always the safe thing.
func _on_seat(job: String) -> void:
	await _leave(job, _mode == "carry_on")


## The corner disc, held to the end: the saved drive is thrown away HERE, by the
## child, and a brand new visit begins.
func _on_fresh() -> void:
	SaveGame.clear()
	var keys := _menu.seat_keys() if _menu != null else PackedStringArray()
	await _leave(keys[0] if not keys.is_empty() else "new_driveway", false)


## The cut into the job. The pick is written to process memory ONLY on the real
## path: a harness driving this screen must not leave one behind for whatever
## runs next in its process.
func _leave(job: String, carry_on: bool) -> void:
	if _leaving:
		return
	_leaving = true
	_pick = {"job": job, "carry_on": carry_on}
	if get_tree().current_scene != self or not ResourceLoader.exists(LEVEL_SCENE):
		job_requested.emit(job, carry_on)
		_leaving = false
		return
	Engine.set_meta(SiteMain.PICK_META, _pick)
	if not carry_on:
		Engine.set_meta(SiteMain.NEXT_SEED_META, _fresh_seed())
	# The disc's kick and its sound are given their moment before the cut: the
	# scene change frees the `Sfx` playing them, and a press answered by nothing
	# at all is the fault every session of this plan has been fixing.
	await get_tree().create_timer(CUT_DELAY, false).timeout
	get_tree().change_scene_to_file(LEVEL_SCENE)


## THE LOT BEHIND THE DISC IS THE LOT YOU GET - but only when that lot is a
## fresh cracked drive. When it is a reward already earned, or the drive the
## child has just thrown away, the next one is drawn to DIFFER from it in car,
## house and cracks: a child who asks for a new drive and is handed the one they
## just binned has been told the button does nothing.
func _fresh_seed() -> int:
	if _lot == null:
		return SiteLook.draw_fresh({})
	if _lot.dress_stage == "parked" or _lot.resume_ready():
		return SiteLook.draw_fresh(_lot.look)
	return _lot.play_seed


# --- What the tests read -------------------------------------------------------------------

func mode() -> String:
	return _mode


func backdrop() -> SiteMain:
	return _lot


func menu() -> StartMenu:
	return _menu


func pick() -> Dictionary:
	return _pick
