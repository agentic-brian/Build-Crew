class_name Sfx
extends Node
## Sound effects. Plays generated clips from res://assets/sfx/ (made with the
## ElevenLabs sound-effects model), picking a random variation each time so
## repeated chops never machine-gun. Any group with no clips on disk falls back
## to a tiny procedural synth, so the game is never silent.
##
## File naming: <group>_<n>.mp3 | .wav | .ogg, e.g. chop_1.mp3, chop_2.mp3.
## Groups the game uses: chop, thud, pop, whoosh.
##
## Loops are keyed by VOICE and clips by FILENAME, and the two need not be the
## same word: `play_loop(group, voice, gain_db, pitch)` gives one set of
## recordings as many running voices as a scene has machines, each with its own
## gain and pitch. The sawmill's truck and bandsaw are exactly that.
##
## Every AudioStreamPlayer in the whole game is built here and nowhere else, so
## this is also where the game is routed: the music player onto the "Music" bus,
## the clip pool, every looping voice and the procedural fallback synth onto
## "SFX". The settings menu drives those two buses, which is the only way a
## volume control can reach ALL of the noise - the fallback synth in particular
## has its own volume set once and never again, and no group trim, so anything
## that walked the players would miss it. `Settings.ensure()` runs on the first
## line of `_ready`, before a single player exists, because a player handed a
## bus name that is not there yet silently falls back to Master and says nothing.

const SFX_DIR := "res://assets/sfx"
const MUSIC_DIR := "res://assets/music"
const RATE := 22050.0
const POOL_SIZE := 6
## The two buses the settings menu turns down. Taken from Settings rather than
## spelled again here: two copies of a bus NAME is the one typo Godot answers by
## silently playing everything on Master.
const SFX_BUS := Settings.SFX_BUS
const MUSIC_BUS := Settings.MUSIC_BUS

## Master volume for the clip players. -12 dB: the whole game was asked down by
## half (2026-09-05); -6 dB is half the amplitude.
@export_range(-40.0, 12.0, 0.5) var volume_db: float = -12.0
## Random pitch spread per play, 1.0 = none. Cheap extra variety on top of the
## clip variations.
@export_range(1.0, 1.5, 0.01) var pitch_spread: float = 1.06
## Per-group gain trims in dB, so one loud clip never needs re-generating.
## The vehicle groups sit 9 dB under the tools since the fourth playtest
## ("vehicles too loud"): a diesel drone has far more power at the same peak
## than a sledge hit, and two of them ran under every machine beat.
@export var group_gain_db: Dictionary = {"chop": 0.0, "thud": 0.0, "pop": -4.0, "whoosh": -6.0, "chipper": 0.5, "tada": 0.0, "thunk": 0.0, "creak": -3.0, "timber": 2.0, "bark": 0.0, "crackle": -9.0, "rain": -6.0, "sparkle": 0.0, "ping": -2.0, "flutter": -3.0, "dieselidle": -9.0, "mixerdrum": -9.0, "idle": -9.0, "drive": -12.0, "hydraulic": -5.0, "rubblepush": -4.0, "gravelpour": -4.0, "wetpour": -4.0, "horn": -4.0, "done": -4.0, "reversebeep": -6.0, "hiss": -6.0, "voice_hatchback": -4.0, "click": -6.0}

## Name of the last group asked to play (clips or fallback). For tests.
var last_played: String = ""
## How long the clip `last_played` picked runs, seconds, or 0 when the group had
## no clip on disk and a synthesised fallback answered instead. The garage pulses
## a vehicle's light bar for exactly as long as its voice (`GarageMain._toot`),
## and a number measured off the take that is really playing is the only honest
## way to say "while it plays".
var last_length: float = 0.0
## How many times each group has been asked to play since the scene began. For
## tests: `last_played` is one name, and a run of four ties is four clicks.
var played_count: Dictionary = {}

var _clips: Dictionary = {}
## Voice name -> the player singing it. Keyed by VOICE, not by clip group: two
## machines may run two voices off one set of recordings.
var _loops: Dictionary = {}
## Voice name -> {group, db, pitch}: the clips it was built from and the gain and
## pitch it rests at, so `set_loop_trim`/`set_loop_pitch` can bend it off its own
## resting point instead of off a number the caller has to remember for itself.
var _loop_voice: Dictionary = {}
var _last_pick: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _synth_player: AudioStreamPlayer
var _music: AudioStreamPlayer
## Which track is on: "menu", "chop", "grind", or "" for whatever was found.
var _music_track: String = ""


func _ready() -> void:
	# The buses have to exist before any player names one: a player pointed at a
	# missing bus reports "Master" without an error, and every volume control
	# would then be a silent no-op.
	Settings.ensure()
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_pool.append(p)
	# The procedural fallback plays a clip it builds on the spot (`_push`) on a
	# player of its own. It was an AudioStreamGenerator playing from here for
	# ever, and Godot 4.7's generator playback keeps only a RAW pointer to its
	# generator (servers/audio/effects/audio_stream_generator.h): when this node
	# was freed, the generator went with its player while the audio thread was
	# still mixing the playback, the mix read freed memory, and the process died
	# on that thread with no message. Car Garage's smoke did it one run in three
	# at the moment it freed its level and it was fixed there on 2026-09-13; here
	# NEXT and the house reload the whole site, which is the same free, on every
	# second driveway (the improvement plan's 0.2, 2026-09-15). A WAV's playback
	# holds a real reference to its stream.
	_synth_player = AudioStreamPlayer.new()
	_synth_player.volume_db = volume_db
	_synth_player.bus = SFX_BUS
	add_child(_synth_player)
	_load_clips()


## Stop every clip that is still playing. Tests call this before quitting.
##
## This FREES every loop player without telling whoever started it. A machine
## that remembers "my idle is running" in a bool of its own is therefore wrong
## for the rest of the process the moment anyone calls this, and - if it gates
## starting the loop on that bool - can never sing again. Machines should ask
## `is_looping(voice)`, which cannot go stale, and re-assert their loop while
## they run.
func stop_all() -> void:
	# The whole player has to go, not just its playback: `start_music` refuses to
	# do anything while `_music` is still around, so merely stopping it would
	# make the music unstartable for the rest of the process.
	stop_music()
	for p in _pool:
		p.stop()
	for g in _loops.keys():
		stop_loop(g)
	if _synth_player != null:
		_synth_player.stop()


## Success fanfare when a whole tree has been chipped.
func play_tada() -> void:
	_play("tada", _synth_pop)


## The log dropping into the hopper.
func play_thunk() -> void:
	_play("thunk", _synth_thud)


## The trunk groaning on the hit before the last one.
func play_creak() -> void:
	_play("creak", _synth_whoosh)


## The woodsman's yell as the tree starts to fall.
func play_timber() -> void:
	_play("timber", _synth_pop)


## Starts a looping clip group (e.g. "chipper"). No-op if already running.
## Silent (but harmless) when the group has no clips on disk.
##
## `group` names the CLIPS on disk; `voice` names the LOOP, and the two need not
## be the same word. Loops are keyed by voice, clips by filename, so two machines
## standing in one clearing can each have a running engine of their own off the
## same recordings - a low slow one for the truck, a higher busier one for the
## mill - instead of sharing a single player and passing it back and forth. That
## sharing was the whole reason the sawmill's truck could shut down without the
## room getting any quieter: the mill picked the group up a frame later at the
## same gain and the drone simply carried on.
##
## `gain_db` and `pitch` are that voice's own colour, on top of the group's trim.
## They are what makes two voices off one recording sound like two machines, so
## they are feel numbers and live on the callers' config resources.
func play_loop(group: String, voice: String = "", gain_db: float = 0.0, pitch: float = 1.0) -> void:
	var key := voice if voice != "" else group
	if _loops.has(key):
		return
	last_played = group
	var base_db := volume_db + float(group_gain_db.get(group, 0.0)) + gain_db
	var player := AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.volume_db = base_db
	player.pitch_scale = pitch
	add_child(player)
	_loops[key] = player
	_loop_voice[key] = {"group": group, "db": base_db, "pitch": pitch}
	var count := loaded_count(group)
	if count == 0:
		return
	var clips: Array = _clips[group]
	var stream: AudioStream = (clips[randi() % count] as AudioStream).duplicate()
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		# LOOP_FORWARD needs a REGION as well as a mode, and this is the bug that
		# made every cutting sound in the game silent from the day it was written.
		# A .wav imported with `edit/loop_mode=0` (which is what
		# assets/sfx/grind_1.wav.import says) carries loop_begin == loop_end == 0,
		# so a forward loop is nought frames long: it ends on the frame it starts,
		# the player reports playing = false at position 0.000 for ever, and not
		# one sample is heard. grind_1/grind_2 are the only .wav files in
		# assets/sfx and "grind" is the cutting voice of BOTH the sawmill and the
		# stump grinder, so those two machines have never once been heard cut.
		# Every other group is .mp3, which loops on a flag and was always fine.
		# Naming the whole clip as the region is safe on the duplicate above.
		var wav := stream as AudioStreamWAV
		if wav.loop_end <= wav.loop_begin:
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * float(wav.mix_rate))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream = stream
	player.play()


func stop_loop(voice: String) -> void:
	if not _loops.has(voice):
		return
	var p: AudioStreamPlayer = _loops[voice]
	p.stop()
	p.queue_free()
	_loops.erase(voice)
	_loop_voice.erase(voice)


func is_looping(voice: String) -> bool:
	return _loops.has(voice)


## The player behind a voice, or null. For the machines that colour their own
## loop and for the probes, which have to be able to ask what is ACTUALLY being
## made - a boolean flag saying "mine is playing" is what let the silent cut ship.
func loop_player(voice: String) -> AudioStreamPlayer:
	return _loops.get(voice) as AudioStreamPlayer


## Bends a live voice off its own resting pitch: 1.0 is however it was started,
## below that is an engine leaning into the work or dying. A no-op for a voice
## that is not running, so a machine may call it every frame without asking first.
func set_loop_pitch(voice: String, factor: float) -> void:
	var p := loop_player(voice)
	if p == null:
		return
	p.pitch_scale = float((_loop_voice[voice] as Dictionary).get("pitch", 1.0)) * factor


## Trims a live voice off its own resting gain, in dB: 0.0 is however it was
## started, negative is quieter. Same no-op rule as `set_loop_pitch`.
func set_loop_trim(voice: String, db: float) -> void:
	var p := loop_player(voice)
	if p == null:
		return
	p.volume_db = float((_loop_voice[voice] as Dictionary).get("db", volume_db)) + db


## Every live loop, for the probes: what it is, whether it is really making a
## sound, where its needle is, how loud, at what pitch and on which bus.
func loop_report() -> Dictionary:
	var out: Dictionary = {}
	for v in _loops.keys():
		var p := _loops[v] as AudioStreamPlayer
		out[v] = {
			"group": (_loop_voice.get(v, {}) as Dictionary).get("group", v),
			"playing": p.playing,
			"position": p.get_playback_position(),
			"volume_db": p.volume_db,
			"pitch": p.pitch_scale,
			"bus": p.bus,
			"paused": p.stream_paused,
		}
	return out


## How much noise all the running loops make together, in dB.
##
## The one number that answers "did the room get quieter?", which is the question
## a boolean about engine STATE cannot: when two machines shared one voice the
## truck could switch itself off, the flags could all read correctly, and the
## drone carried on at exactly the same level. Powers add, decibels do not, so
## they are summed as power and turned back. -120 dB stands for silence.
func loop_power_db() -> float:
	var power := 0.0
	for v in _loops.keys():
		var p := _loops[v] as AudioStreamPlayer
		if p.playing and not p.stream_paused:
			power += db_to_linear(p.volume_db) ** 2.0
	if power <= 0.0:
		return -120.0
	return 10.0 * (log(power) / log(10.0))


func play_chop() -> void:
	_play("chop", _synth_chop)


func play_thud() -> void:
	_play("thud", _synth_thud)


func play_pop() -> void:
	_play("pop", _synth_pop)


func play_whoosh() -> void:
	_play("whoosh", _synth_whoosh)


## How many clip variations were found on disk for a group.
func loaded_count(group: String) -> int:
	if not _clips.has(group):
		return 0
	return (_clips[group] as Array).size()


func _play(group: String, fallback: Callable, pitch: float = 1.0) -> void:
	last_played = group
	played_count[group] = int(played_count.get(group, 0)) + 1
	last_length = 0.0
	var count := loaded_count(group)
	if count == 0:
		fallback.call()
		return
	var clips: Array = _clips[group]
	var idx := randi() % count
	if count > 1 and idx == int(_last_pick.get(group, -1)):
		idx = (idx + 1) % count
	_last_pick[group] = idx
	var player := _free_player()
	player.stream = clips[idx]
	last_length = (clips[idx] as AudioStream).get_length()
	player.volume_db = volume_db + float(group_gain_db.get(group, 0.0))
	player.pitch_scale = randf_range(1.0 / pitch_spread, pitch_spread) * maxf(pitch, 0.05)
	player.play()


func _free_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	# All busy: steal the one that has been playing longest.
	var oldest := _pool[0]
	for p in _pool:
		if p.get_playback_position() > oldest.get_playback_position():
			oldest = p
	return oldest


func _load_clips() -> void:
	_clips.clear()
	var dir := DirAccess.open(SFX_DIR)
	if dir == null:
		return
	var seen := {}
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir():
			var base := fname
			# Exported builds list "x.mp3.import" / "x.mp3.remap"; strip to the real name.
			if base.ends_with(".import") or base.ends_with(".remap"):
				base = base.get_basename()
			var ext := base.get_extension().to_lower()
			if (ext == "mp3" or ext == "wav" or ext == "ogg") and not seen.has(base):
				seen[base] = true
				var stream := load(SFX_DIR.path_join(base)) as AudioStream
				if stream != null:
					var group := _group_of(base.get_basename())
					if not _clips.has(group):
						_clips[group] = []
					(_clips[group] as Array).append(stream)
		fname = dir.get_next()
	dir.list_dir_end()


## "chop_3" -> "chop"; "thud" -> "thud".
func _group_of(stem: String) -> String:
	var us := stem.rfind("_")
	if us > 0 and stem.substr(us + 1).is_valid_int():
		return stem.substr(0, us)
	return stem


# --- Procedural fallbacks -----------------------------------------------------

func _synth_chop() -> void:
	var n := int(RATE * 0.12)
	var buf := PackedVector2Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := i / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.35
		var crack := lp * exp(-t * 40.0)
		var thump := sin(TAU * 140.0 * t) * exp(-t * 18.0) * 0.7
		var s := clampf((crack * 0.9 + thump) * 0.8, -1.0, 1.0)
		buf[i] = Vector2(s, s)
	_push(buf)


func _synth_thud() -> void:
	var n := int(RATE * 0.55)
	var buf := PackedVector2Array()
	buf.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in range(n):
		var t := i / RATE
		var f := lerpf(95.0, 42.0, minf(t * 3.0, 1.0))
		phase += TAU * f / RATE
		var body := sin(phase) * exp(-t * 6.0)
		lp += (randf_range(-1.0, 1.0) - lp) * 0.2
		var crackle := lp * exp(-t * 14.0) * 0.5
		var s := clampf((body * 0.9 + crackle) * 0.9, -1.0, 1.0)
		buf[i] = Vector2(s, s)
	_push(buf)


func _synth_pop() -> void:
	var dur := 0.22
	var n := int(RATE * dur)
	var buf := PackedVector2Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := i / RATE
		var k := t / dur
		phase += TAU * lerpf(220.0, 660.0, k) / RATE
		var s := sin(phase) * (1.0 - k) * 0.35
		buf[i] = Vector2(s, s)
	_push(buf)


func _synth_whoosh() -> void:
	var dur := 0.25
	var n := int(RATE * dur)
	var buf := PackedVector2Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := i / RATE
		var k := t / dur
		lp += (randf_range(-1.0, 1.0) - lp) * lerpf(0.08, 0.4, k)
		var env := sin(k * PI)
		var s := clampf(lp * env * 0.5, -1.0, 1.0)
		buf[i] = Vector2(s, s)
	_push(buf)


## One synthesised sound, as a 16-bit stereo clip on the fallback player.
func _push(buf: PackedVector2Array) -> void:
	if _synth_player == null or buf.is_empty():
		return
	var data := PackedByteArray()
	data.resize(buf.size() * 4)
	for i in range(buf.size()):
		data.encode_s16(i * 4, int(clampf(buf[i].x, -1.0, 1.0) * 32767.0))
		data.encode_s16(i * 4 + 2, int(clampf(buf[i].y, -1.0, 1.0) * 32767.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = int(RATE)
	clip.stereo = true
	clip.data = data
	_synth_player.stream = clip
	_synth_player.play()


## Background music from res://assets/music/ (see docs/suno_prompt.md).
##
## `track` names the one this screen wants, and the FILE NAME is the whole
## wiring: assets/music/<track>.ogg. Five tracks exist, one per screen that asks
## for one - menu (title and season cards), chop (the clearing), grind, forward,
## mill. A screen that asks for a name with no file behind it gets the first
## .ogg/.mp3 in the folder instead, which is how the felling level is currently
## living on chop.ogg: it asks for nothing at all. Silent if the folder is empty.
##
## `music_db` is deliberately NOT the class's own `volume_db`: this player is
## trimmed on its own, and the settings menu turns the whole song up and down
## from the "Music" bus underneath it rather than from here.
func start_music(track: String = "", music_db: float = -15.0) -> void:
	if _music != null:
		return
	var stream := _find_music(track)
	if stream == null:
		return
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.stream = stream
	_music.volume_db = music_db
	_music.bus = MUSIC_BUS
	add_child(_music)
	_music.play()
	_music_track = track


## Brings the song down (or up) to `to_db` over `seconds`: the cure's "later
## that day" is the one moment the sound should say the day is ending (Build
## Crew's improvement plan, 3.3). A no-op with no song; the scene reload on
## NEXT brings the song back at its own level.
func fade_music(to_db: float, seconds: float) -> void:
	if _music == null:
		return
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", to_db, maxf(seconds, 0.05))


## Changes track without a gap in the silence either side of it. A no-op when
## the wanted track is the one already playing, which is what happens while
## only one file is on disk: the menu music simply carries on into the game.
func swap_music(track: String, music_db: float = -15.0) -> void:
	var stream := _find_music(track)
	if stream == null:
		return
	if _music != null and _music.stream == stream:
		_music_track = track
		return
	stop_music()
	start_music(track, music_db)


## The named track if `assets/music/<track>.ogg|mp3` exists, else the first
## file in the folder. Loops whatever it returns.
##
## Every .import in assets/music ships `loop=false`; the loop flag is set HERE,
## in code, which is why nobody should ever "fix" those import files. Note this
## sets it on the CACHED resource rather than on a duplicate, unlike play_loop:
## harmless, because every caller of a music track wants it looping, and
## swap_music's `_music.stream == stream` identity test depends on the cache.
func _find_music(track: String) -> AudioStream:
	var dir := DirAccess.open(MUSIC_DIR)
	if dir == null:
		return null
	var files := dir.get_files()
	files.sort()
	var wanted := ""
	var first := ""
	var seen := {}
	for listed in files:
		# An exported build lists "loop.ogg.import" / ".remap"; strip to the real
		# name, the same way _load_clips does, or the music goes silent in an
		# export while the sound effects are fine.
		var file_name := listed
		if file_name.ends_with(".import") or file_name.ends_with(".remap"):
			file_name = file_name.get_basename()
		if not (file_name.ends_with(".ogg") or file_name.ends_with(".mp3")):
			continue
		if seen.has(file_name):
			continue
		seen[file_name] = true
		if first == "":
			first = file_name
		if track != "" and file_name.get_basename() == track:
			wanted = file_name
	var pick := wanted if wanted != "" else first
	if pick == "":
		return null
	var stream := load(MUSIC_DIR + "/" + pick) as AudioStream
	if stream == null:
		return null
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream


func stop_music() -> void:
	if _music != null:
		_music.stop()
		# A queue_free'd node keeps its name until the frame ends, so the next
		# player to be called "Music" would silently get "@AudioStreamPlayer@12"
		# instead. Hand the name back now: get_node("Music") stays reliable
		# straight after a swap, which the probes and the settings code rely on.
		_music.name = "MusicOld"
		_music.queue_free()
		_music = null
		_music_track = ""


## True while a background track is playing (for tests).
func is_music_playing() -> bool:
	return _music != null and _music.playing


## Length in seconds of the loaded track, 0 if none.
func music_length() -> float:
	if _music == null or _music.stream == null:
		return 0.0
	return _music.stream.get_length()


## Freezes every looping machine noise where it stands, or lets it run again.
##
## The settings panel needs this because of a small, sharp bug. Opening it stops
## the tree but raises this node to PROCESS_MODE_ALWAYS, and a running loop is
## stopped by its machine COUNTING DOWN in `_process` - the sawmill's cut loop
## after `cut_loop_tail`, the grinder's after 0.2 s. Freeze that count and the
## tail never elapses: a child who taps the settings cog in the fraction of a
## second after finishing a cut gets the cutting loop roaring over a frozen
## picture, for as long as the panel is up, which is exactly the moment somebody
## reached for the volume.
##
## `stream_paused` rather than `stop()` on purpose: the machine's own bookkeeping
## is untouched, so when the panel closes its next frame still runs the tail it
## was in the middle of and stops the loop properly. The frozen world sounds
## frozen; the song plays on underneath, and every rung tap still pings, so
## there is plenty to judge the new volume by.
func set_loops_paused(on: bool) -> void:
	for g in _loops.keys():
		var p := _loops[g] as AudioStreamPlayer
		if p != null:
			p.stream_paused = on


## Which bus every live player is actually on, for the probes.
##
## This is the only way a routing mistake is ever visible: Godot does not
## complain about a player pointed at a bus that does not exist, it just plays
## it on Master at full volume while the settings menu turns down two buses
## nothing is on.
func audio_bus_report() -> Dictionary:
	var pool: Array[String] = []
	for p in _pool:
		pool.append(p.bus)
	var loops: Dictionary = {}
	for g in _loops.keys():
		loops[g] = (_loops[g] as AudioStreamPlayer).bus
	return {
		"pool": pool,
		"synth": _synth_player.bus if _synth_player != null else "",
		"loops": loops,
		"music": _music.bus if _music != null else "",
	}


## Plays any clip group by name (new groups need no code: drop
## assets/sfx/<group>_<n>.mp3 in). Falls back to a soft pop until then.
##
## `pitch` multiplies the group's own random spread, so a caller can pitch a
## borrowed recording: the rebar's tie wire is the garage's `click`, a step higher
## for each tie down a bar.
func play_group(group: String, pitch: float = 1.0) -> void:
	_play(group, _synth_pop, pitch)
