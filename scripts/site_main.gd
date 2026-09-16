class_name SiteMain
extends Node3D
## The level: one suburban lot, one driveway job, and everything round it
## (DESIGN 1). It owns the world, the machines, the tools and the celebration;
## everything between "there is an old drive here" and "there is a new one" is
## `JobRunner` playing `data/jobs/new_driveway.tres`.
##
## The shape is Car Garage's `GarageMain`, much smaller: that level had fifteen
## jobs and a work order, this one has a single job, so what is left is the lot,
## the shots, the input and the payoff.
##
## ## Where everything is
##
## The drive runs up the RIGHT of the picture (`Driveway.CENTRE_X`), the house
## stands behind it, the street crosses in front at `STREET_Z`. The camera looks
## from the street's left, so the two round HUD buttons in the bottom-left corner
## are over grass and never over anything a child is asked to tap.
##
## ## Screenshot and test arguments
##
## Passed after `--` through `scenes/dev/shot.tscn` (`Engine.get_meta`):
##   --stage=poured   pose the world at the start of a phase, no play
##   --step=7         put the runner on step 7 (with --stage)
##   --shot=SURFACE   snap the camera to a named shot
##   --nohud          take the HUD off, for a clean picture of the lot
##   --done=2         with --stage, that many of the step's places done
##   --places=3,1     and WHICH ones (the rows a child takes in any order)
##   --seed=N         the visit's look (6.1); a harness with no seed gets 0,
##                    the legacy lot every earlier picture was taken of
##   --car=Pickup --paint=K --house=K --cracks=B   one field of the look, for
##                    a critic's frame of one car or one house

## The job is finished (the broom is done): the payoff is about to play.
signal job_done
## The payoff is over and NEXT is up.
signal ready_for_next
## NEXT was pressed inside a harness, where there is no scene to cut to.
signal next_requested

const JOB_DIR := "res://data/jobs/"
const STREET_MODELS := "res://assets/models/street/"
const VEHICLE_MODELS := "res://assets/models/vehicles/"

## Where the road's surface is: the kerb line in z, and how wide the carriageway
## is either side of its middle.
const STREET_Z := 8.6
const KERB_Z := 5.9
## The top of the footway either side of the drive (its box is 0.13 tall,
## centred at 0.03); the crossing between them is at grade.
const FOOTWAY_TOP := 0.095
## How far past the slab's end the cones stand for the cure: their 36 cm bases
## clear of the kerb board's trench (the crossing starts behind it since the
## plan's fifth session) and on the crossing and the road's edge beyond it, which
## is a centimetre higher - the crossing between the trench and the road is only
## 28 cm deep, measured, so no spot on it alone holds a cone.
const CONE_MOUTH_OUT := 0.40
## How far the grass reaches. Generous, because the camera sees a long way down
## the street in the WIDE and STREET shots and the first renders ended the world
## in open frame - a hard green edge against the sky behind the house.
const LOT_HALF_X := 60.0
const LOT_FRONT_Z := 48.0
const LOT_BACK_Z := -34.0

## Where each machine waits off-stage. A machine arrives from up the street
## (+X), because that is the side the picture is open on, and every journey it
## makes is a PATH it drives along nose-first (`Machine.follow`) rather than a
## pose lerped into another pose - the user's seventh note was that the vehicles
## float and turn into the driveway instead of rolling or backing up.
const OFF_STAGE := Vector3(17.0, 0.0, STREET_Z)
## Facing down the street (-X) while it travels along it.
const STREET_YAW := -90.0
## Where the MIXER stands to pour: on the road, tail to the drive, its rearmost
## tyre a hand's width past the kerb (DESIGN 2a). Never on the pad - the steel is
## down by then. Measured: the REARMOST axle (the third one, `WheelR2L`, which
## the contract never listed) is 2.66 m behind the origin and the tyre is 0.50 m
## in radius, so the tyre's back edge is 3.16 m behind the origin.
const MIXER_STAND_Z := KERB_Z + 0.16 + 2.66 + 0.50
## How many points a rounded corner in a machine's path is drawn with. A path is
## a polyline and the nose is read off it, so a corner has to be SAMPLED or the
## machine turns ninety degrees in one frame.
const CORNER_STEPS := 9

## The garage at the head of the drive, built out of boxes right here rather than
## dropped in as a GLB.
##
## The user asked for it: "it would be nice if that was an actual garage door that
## could open so the skid steer had room to push the rocks". The fleet's
## `DetachedGarage` is a single sealed mesh with a door painted on, so there was
## nowhere for a machine to be - and it stood 23 cm ON the driveway, which is what
## the skid steer was reversing into. Seven boxes and a roller door later there is
## a real opening, the machine drives through it, and the full nine metres of
## every column can be pushed in one pass from inside.
const GARAGE_WIDE := 5.36
const GARAGE_DEEP := 6.40
const GARAGE_WALL := 0.18
const GARAGE_EAVE := 2.50
const GARAGE_RIDGE := 3.50
const DOOR_WIDE := 3.40
const DOOR_HIGH := 2.30
## How many slats the roller door has. It rolls UP into its own drum, so the top
## slats leave the picture one at a time - which is what a garage door of this
## kind really does, and it means no 2.3 m panel has to be hidden anywhere.
const DOOR_SLATS := 9

## Which node on each machine is the working end a shot hangs off and the arrow
## points at. `MACHINE` is anchored to whatever the current step names, so one
## shot frames all three.
const WORKING_END := {
	"SkidSteer": "BucketTip",
	"DumpTruck": "Tailgate",
	"ConcreteTruck": "ChutePour",
}
## Where each tool rests when it is not in the child's hand: laid out on the
## grass beside the drive, in the order the job wants them, facing the work.
## Where each tool rests when it is not in the child's hand: laid out together on
## the grass on the far side of the drive, beside the site fence, where a crew
## would put its kit - rather than dropped one by one across the front lawn,
## where a single orange tool reads as litter someone has left on the grass.
const TOOL_REST := {
	# x 5.2, not 5.9: the site fence stands at 6.0 and the broom's handle went
	# straight through its mesh, in frame for all four finishing phases.
	"jackhammer": Vector3(5.2, 0.45, 4.2),
	"sledge": Vector3(5.2, 0.30, 3.6),
	# The screed is a 4.2 m board and `TOOL_REST` is its MIDDLE: at 5.2 its left
	# half lay across the fresh slab, which is the one place a groundworker would
	# never put it down.
	"screed": Vector3(7.6, 0.20, 2.6),
	"jointer": Vector3(5.2, 0.30, 1.8),
	"broom": Vector3(5.2, 0.30, 1.2),
	"hose": Vector3(5.2, 0.25, 0.6),
	"rake": Vector3(5.2, 0.30, 0.0),
	# The plate compactor never rests here in play: it stands on the base for its
	# phase (`hold_plate`) and is lifted off at the end. The rest is for the
	# frame before its first bay is armed.
	"plate": Vector3(5.4, 0.0, -0.6),
}

## Which step of the job each `--stage` poses at, so a screenshot of phase 8 does
## not mean playing phases 1 to 7: the VERB of that step and which of that
## verb's rows it is (`JobDef.index_of`), never a number. Numbers rotted every
## time a beat was added - the fifth session added seven rows (the trucks' held
## reverse, the compactor, the kerb board's own pair, the cure and the strip),
## and every `--step=11` in the docs meant a different beat overnight.
## A stage poses the step that PRODUCES it wherever there is a choice, because
## the step is what puts the controls on screen. `based` poses the rebar beat
## (the base is what it stands on); `rebar` poses the mixer button, and
## `--stage=rebar --step=pour_chute --shot=CHUTE --hold` is the pour; `banded`
## poses the rake. `tipped` is the compactor, `packed` the kerb board waiting,
## `kerbed` its two pegs, `cured` the strip. `done` and `parked` are past the
## last step (`stage_step` answers the step count for them); see `pose`.
const STAGE_STEP := {
	"old": ["jack_spot", 1], "broken": ["call_skid", 1], "cleared": ["form_set", 1],
	"formed": ["stake_drive", 1], "staked": ["call_dump", 1],
	"tipped": ["compact_base", 1], "packed": ["form_set", 2], "kerbed": ["stake_drive", 2],
	"based": ["rebar_lay", 1], "rebar": ["call_mixer", 1], "banded": ["rake_pull", 1],
	"poured": ["spray_water", 1], "sprayed": ["screed_pull", 1], "screeded": ["joint_cut", 1],
	"jointed": ["broom_finish", 1], "cured": ["form_strip", 1],
	"done": ["", 0], "parked": ["", 0],
}

@export var config: SiteConfig
## Which job to play, by file name in `data/jobs/`.
@export var job_name: String = "new_driveway"

@export_group("A backdrop, not a game")
## This lot is the picture BEHIND THE TITLE ROW (the improvement plan's 6.3),
## not a job: it poses itself and then stands there. No HUD, no music, no
## input, no runner beats - and it never reads or writes the child's save.
##
## Set on the instantiated root BEFORE `add_child`: `_enter_tree` runs on
## `add_child` and the driveway builds in its OWN `_ready`, so a flag set after
## is a flag that did nothing. It exists so the title never has to set
## `shot_args`, which is process-global and would follow the child into the job.
@export var dress_only: bool = false
## Which visit the backdrop shows, and where it stands (the same stage and shot
## names a screenshot uses).
@export var dress_seed: int = SiteLook.LEGACY_SEED
@export var dress_stage: String = "old"
@export var dress_shot: String = "WIDE"
## Pose the backdrop AT THE SAVE instead of at `dress_stage`, and let the title
## ask `resume_ready()` afterwards: the same `SiteMain` that would play the job
## judges the save, so the title can never offer to carry on a job the level
## would refuse.
@export var dress_from_save: bool = false
@export_group("")

var drive: Driveway
var camera: CameraShake
var sfx: Node
var hud: SiteHud
var runner: JobRunner
var verbs: SiteVerbs
var rig: CameraRig
var job: JobDef

var machines: Dictionary = {}
var tools: Dictionary = {}
## The homeowner's car, which only appears for the payoff.
## The homeowner's car. A `Machine` like the working three, for the reason the
## user gave twice: "a lot of the vehicles just float and turn into the
## driveway", and then "why does the car at the end just float and turn in?".
var car: Machine

var _sun: DirectionalLight3D
var _env: Environment
var _sky: ProceduralSkyMaterial
var _dust: GPUParticles3D
var _breaker: GPUParticles3D
var _chips: GPUParticles3D
## Dirt boiling up off the blade while it pushes.
var _push_dust: GPUParticles3D
var _gravel: GPUParticles3D
## The stream of concrete off the chute, while it pours: its segments and the
## splash where it lands.
var _stream: Node3D
var _stream_segs: Array[MeshInstance3D] = []
var _splash: MeshInstance3D
var _stream_mat: StandardMaterial3D
var _stream_mats: Array[StandardMaterial3D] = []
var _splash_rim: MeshInstance3D
var _splash_rim_mat: StandardMaterial3D
var _splash_mat: StandardMaterial3D
## Which way the stream leaves the chute, for the arc.
var _stream_dir: Vector3 = Vector3.DOWN
var _splat: GPUParticles3D
## The point the pour's camera hangs off, which follows the pour down the drive.
var _pour_view: Marker3D
## And the point the screed's camera hangs off, which walks with the board.
var _screed_view: Marker3D
## And the come-along's, which hops down the drive behind the concrete's front.
var _rake_view: Marker3D
## The cones and the site fence: the crew's own furniture, which leaves with
## them rather than standing in the finished picture.
var _site_kit: Array[Node3D] = []
## The roller door's slats, and how far open it is.
var _door_slats: Array[MeshInstance3D] = []
var _door_k: float = 0.0
## Where the child's finger last was on the screen, and whether it is down. The
## hose and the broom are DRAGGED over the slab now, so a beat needs to know
## where the finger is and not only that it is down.
var _touch_at: Vector2 = Vector2.INF
var _touch_down: bool = false
## Which finger owns the beat - its touch index - or -1 for none (and for the
## mouse, which has no index). The first finger whose press is ACCEPTED (a ring
## picked, a counted tap, a hold started) takes the work, and until it lifts no
## other finger moves the hose, starts a hold or ends one: a palm or a thumb
## holding the iPad neither steals the drag nor stops it when it lifts (the
## improvement plan's 0.3, 2026-09-15). Every finger still gets the white tap
## ring, which `ToyHud._input` draws before any of this decides.
var _finger: int = -1
## Where every finger on the glass last was, by index: a lift can be told from
## a bystander's, and the lot is forgotten when the app loses focus.
var _fingers: Dictionary = {}
## A ring a tap landed on while the last bite was still running. The runner
## KEEPS such a tap; this keeps WHICH ring it was, for the step it was on, so the
## kept bite goes where the finger went and not to the first open spot (the
## improvement plan's 0.4).
var _queued_pick: int = 0
var _queued_pick_step: int = -1
## Whether the press that is down was ACCEPTED as the work. Only an accepted
## press, its drags and its release wake the white idle arrow; a miss hurries it
## instead (the improvement plan's 1.2).
var _accepted: bool = false
## When a miss last made its sound, and when a machine last honked: one of
## each per gap, so a mashing finger hears a nudge, not a drum roll.
const MISS_SOUND_GAP := 0.25
const HONK_GAP := 0.6
var _miss_at_s: float = -10.0
var _honk_at_s: float = -10.0
## How long the parked car's last answered tap sounds for.
var _car_voice_len: float = 0.0
## A finger pressed on a truck still coming down the street, and still down: it
## backs the truck in the moment the truck stops (the plan's 1.8).
var _carry_back: bool = false
## Where the pour's band starts along the drive, written by the pour beat, so
## the level can say which pad would move the concrete toward the emptiest
## cell (the plan's 2.1).
var pour_band_from: float = -INF
## Where a DRAGGED tool - the board, the sled - is right now, written by its
## beat, so the arrow stands on it and a press is measured against it wherever
## it has got to (the plan's 2.5). INF when no such beat runs.
var drag_tool_at: Vector3 = Vector3.INF
## Where the plate compactor stands on the base (5.1), INF before its phase.
var _plate_at: Vector3 = Vector3.INF
var _plate_view: Marker3D
## How high the plate rides on loose stone before the patch under it is packed.
const PLATE_RIDE := 0.02
## The white idle arrow's wake rule: a finger that moves this far since it
## last woke the hint wakes it again; a resting finger's twitch does not.
const HINT_WAKE_PX := 6.0
var _woke_at: Vector2 = Vector2.INF
## A work point driven by something other than a finger - the sticks, the arrow
## keys, or a test - for the two beats that are worked by dragging.
var _cursor: Vector3 = Vector3.INF
## The gold rings that say where to tap, and which one the last tap chose.
var _rings: SpotRings
var _pointer: SpotRings
var _picked: int = 0
## Whether a STICK put the cursor there. A cursor somebody else set - a test, or
## one day a tutorial - is not the sticks' to take away again.
var _cursor_from_stick: bool = false
var _celebrating: bool = false
## The job's OPENING: the wide held for `opening_hold`, or until the first
## touch, before the eye eases down to the first slab (the plan's 3.1).
var _opening: bool = false
var _opening_left: float = 0.0
var _posed: bool = false
var _no_hud: bool = false
var _no_machine: bool = false

## The visit (the improvement plan's 6.1): one number, and the look drawn from
## it (`SiteLook.for_seed`) - the car, its paint and voice, the house and
## garage walls, the old drive's cracks. Resolved in `_enter_tree`, before the
## driveway child builds its panels in its own `_ready`.
var play_seed: int = SiteLook.LEGACY_SEED
var look: Dictionary = SiteLook.for_seed(SiteLook.LEGACY_SEED)
## Where the seed came from, for the log: next, save, arg, harness or fresh.
var seed_from: String = ""
## The next visit's seed, left for the site that opens next - by the title's
## seat, or by a harness. Process memory only, never a file (6.2's privacy line).
const NEXT_SEED_META := "bc_next_seed"
## What the title row chose: `{"job": String, "carry_on": bool}`. Read and
## removed by `_enter_tree`; process memory only.
const PICK_META := "bc_job_pick"
## The seed of the visit just FINISHED, left for the title so the reward is
## still standing behind the next choice (6.3). Read and removed by the title.
const LAST_SEED_META := "bc_last_seed"
## Where NEXT and the house go (6.3).
const TITLE_SCENE := "res://scenes/main.tscn"
## What NEXT calls once it has cleared the save: the cut back to the title row.
## Empty is a real scene change; the smoke puts a flag here, because a scene
## change from inside it would take the test's own scene away.
var leave_scene: Callable = Callable()
## Whether this run reads and writes the save (6.2): the child's game, or a test
## that pointed `SaveGame.path_override` at a scratch file. Never a posed run.
var _saves: bool = false
## The saved place this visit resumes at (`resume_point`), or {} for a fresh job.
var _resume: Dictionary = {}
## The job file this run plays, as the save names it.
var _job_file: String = ""
## Whether the title's seat said "carry on" (6.3). The save's own branch in
## `_enter_tree` does the real work; this is what the picker meant, for the log
## and for the tests.
var _carried_on: bool = false
var _entered: bool = false


## Before the children are ready: the driveway builds its panels in its OWN
## `_ready`, which runs before this node's, so the seed that picks its cracks
## has to be in place by now or the first build silently keeps the legacy drive.
##
## The seed, in order: a BACKDROP's own (`dress_only`, which takes neither meta
## and may read the save to pose at it), then the one NEXT drew (a new visit),
## the save's (a resumed job keeps its drive under its stakes), `--seed`, 0 for
## any other harness (the legacy lot every earlier picture was taken of), and
## otherwise a fresh draw.
func _enter_tree() -> void:
	if _entered:
		return
	_entered = true
	var args: Dictionary = Engine.get_meta("shot_args", {}) as Dictionary
	# What the title row chose, if the child came through one (6.3). Taken, so
	# the next site in this process starts from its own decision.
	var pick: Dictionary = {}
	if Engine.has_meta(PICK_META):
		pick = Engine.get_meta(PICK_META) as Dictionary
		Engine.remove_meta(PICK_META)
	_carried_on = bool(pick.get("carry_on", false))
	_job_file = String(pick.get("job", args.get("job", job_name)))
	job = _load_job(_job_file)
	_saves = saves_on(args)
	var seed := -1
	if dress_only:
		# NEITHER meta is taken: whichever `SiteMain` enters first CONSUMES
		# `bc_next_seed`, and a backdrop that ate it would hand the child a
		# different visit from the one they pressed.
		if dress_from_save and SaveGame.enabled:
			_resume = resume_point(SaveGame.load_data())
		seed = int(_resume["seed"]) if not _resume.is_empty() else dress_seed
		seed_from = "dress"
	if seed < 0 and not dress_only and Engine.has_meta(NEXT_SEED_META):
		seed = SiteLook.parse_seed(Engine.get_meta(NEXT_SEED_META))
		Engine.remove_meta(NEXT_SEED_META)
		seed_from = "next"
	if seed < 0 and not dress_only and _saves:
		_resume = resume_point(SaveGame.load_data())
		if not _resume.is_empty():
			seed = int(_resume["seed"])
			seed_from = "save"
	if seed < 0 and not dress_only and args.has("seed"):
		seed = SiteLook.parse_seed(args["seed"])
		seed_from = "arg"
		if seed < 0:
			push_warning("SiteMain: --seed=%s is not a seed 0..%d; the legacy lot" % [str(args["seed"]), SiteLook.SEED_MAX])
	if seed < 0 and not dress_only and Engine.has_meta("shot_args"):
		seed = SiteLook.LEGACY_SEED
		seed_from = "harness"
	if seed < 0:
		seed = SiteLook.draw_fresh({})
		seed_from = "fresh"
	play_seed = seed
	look = SiteLook.for_seed(seed)
	_look_overrides(args)
	var d := get_node_or_null("Driveway") as Driveway
	if d != null:
		d.crack_base = int(look["crack_base"])


## A critic's frame of one field of the look: `--car=Pickup` (and `--paint=K`,
## that car's K-th paint), `--house=K` (a swatch), `--cracks=B` (a base from
## `SiteLook.CRACK_BASES`). A harness never saves, so nothing unseeded persists.
func _look_overrides(args: Dictionary) -> void:
	if args.has("car"):
		var row := SiteLook.car_row(String(args["car"]))
		if row.is_empty():
			push_warning("SiteMain: no home car '%s'" % str(args["car"]))
		else:
			look["car"] = String(row["name"])
			look["voice"] = String(row["voice"])
			var paints: Array = row["paints"]
			look["paint"] = Color(0, 0, 0, 0) if paints.is_empty() \
				else paints[clampi(int(str(args.get("paint", "0"))), 0, paints.size() - 1)]
	if args.has("house"):
		var sw := clampi(int(str(args["house"])), 0, SiteLook.HOUSE_SWATCHES.size() - 1)
		look["house_swatch"] = sw
		look["house"] = SiteLook.HOUSE_SWATCHES[sw][0]
		look["garage_wall"] = SiteLook.HOUSE_SWATCHES[sw][1]
	if args.has("cracks") and str(args["cracks"]).is_valid_int():
		look["crack_base"] = int(str(args["cracks"]))


func _ready() -> void:
	var args: Dictionary = Engine.get_meta("shot_args", {}) as Dictionary
	_no_hud = args.has("nohud") or dress_only
	_no_machine = args.has("nomachine")
	if config == null:
		config = load("res://data/site_config.tres") as SiteConfig
	if config == null:
		config = SiteConfig.new()
	drive = get_node_or_null("Driveway") as Driveway
	camera = get_node_or_null("Camera3D") as CameraShake
	if camera != null:
		# KEEP THE WIDTH. Every shot is composed for 16:9 and asserted in it;
		# with Godot's default (the height is kept) a 4:3 iPad CROPS the sides
		# of that picture, which is where the rings on the long boards and the
		# far peg of a pair stand - "it wanted me to click something I couldn't
		# see" (the user, 2026-09-14). 79.3 degrees across is the same picture
		# as 50 degrees up at 16:9; a squarer screen simply sees more sky and
		# more foreground.
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = 79.3
	sfx = get_node_or_null("Sfx")
	hud = get_node_or_null("HUD") as SiteHud
	verbs = get_node_or_null("Verbs") as SiteVerbs
	runner = get_node_or_null("Runner") as JobRunner
	_build_world()
	if drive != null:
		drive.setup(config)
		drive.build()
	_build_machines()
	_build_tools()
	_build_effects()
	_rings = SpotRings.new()
	_rings.name = "Rings"
	add_child(_rings)
	# A second set, of one: the mark the JOB points with when a beat has a single
	# place. It is a 3D node and the HUD is a CanvasLayer, so the level owns it and
	# the HUD drives it - exactly as with the camera.
	_pointer = SpotRings.new()
	_pointer.name = "Pointer"
	add_child(_pointer)
	rig = CameraRig.new()
	rig.name = "Rig"
	add_child(rig)
	rig.setup(camera, config)
	_define_shots()
	# The first slab's weeds, planted against the opening wide's own picture so
	# none stands under its lit rings' gold (4.1, the session-4 verification pass).
	if drive != null:
		drive.replant_first_weeds(rig.shot_eye(CameraRig.WIDE), rig.shot_look(CameraRig.WIDE), config.ring_spot)
	if hud != null:
		hud.camera = camera
		hud.pointer = _pointer
		hud.visible = not _no_hud
		hud.go_pressed.connect(func() -> void:
			_woke()
			runner.press_button("call"))
		hud.next_pressed.connect(_on_next)
		hud.home_pressed.connect(_on_home)
	if job == null:
		job = _load_job(String(args.get("job", job_name)))
	runner.setup(self, hud, rig, config, verbs)
	runner.tools = tools
	runner.beat_done.connect(func(p: int) -> void:
		if hud != null:
			hud.set_step(p))
	runner.job_done.connect(_celebrate)
	runner.step_done.connect(_on_step_done)
	if hud != null and job != null:
		hud.set_total_steps(job.total_weight())
		hud.set_step(0)
	if sfx != null and sfx.has_method("start_music") and not dress_only:
		# A backdrop starts no song: the title owns the music, and two `Sfx`
		# nodes would play two (`Sfx.start_music` only refuses a second on the
		# SAME node).
		sfx.start_music("site")
	if Engine.has_meta("shot_args"):
		# Every harness log names the world it drew.
		print("SITE_LOOK seed %d (%s) car %s paint %s house %d cracks %d saves %s" % [play_seed, seed_from,
			String(look["car"]), str(look["paint"]), int(look["house_swatch"]), int(look["crack_base"]), str(_saves)])
	if dress_only:
		# Posed, then still: no beats are played, nothing is written, and a
		# finger on the picture belongs to the row in front of it.
		_start(_dress_args())
		_undress()
		# Nothing about a backdrop ticks: `_process` presses the pour's hold every
		# frame from the row it is posed on (the PAD branch calls `runner.hold`
		# with no finger at all), and a picture behind a menu must not work.
		set_process(false)
		set_process_unhandled_input(false)
		return
	_start(args)
	# AFTER the start: `runner.start` enters step 0, and connected before it that
	# entry would write (0, 0) over a job the child has not finished (6.2).
	runner.place_changed.connect(func(_i: int, _d: int) -> void: _write_progress())


## Everything a POSE puts on a working site that a picture behind a menu must
## not have: the gold rings and the arrow (they say "tap here", and the thing to
## tap is the disc in front), and the tools (the row is not a beat).
func _undress() -> void:
	if _rings != null:
		_rings.clear_rings()
	if _pointer != null:
		_pointer.clear_rings()
	if hud != null:
		hud.hide_arrow()
		# The pour's steering pads are ARMED by the pose, and a hidden pad still
		# eats the touch over it: `ToyHud._input` is a raw `_input` that a
		# CanvasLayer's `visible` does not gate, and its buttons answer by
		# `enabled`, not by being drawn. A job saved at the pour would have put
		# an invisible pad exactly where the title's corner disc stands.
		hud.show_pads([])
		hud.set_pads_enabled(false)
		hud.set_process_input(false)
		hud.set_process_unhandled_input(false)
		hud.visible = false
	for kind: String in tools:
		var t := tools[kind] as Node3D
		if t != null:
			t.visible = false
	# And nothing runs on under it: a pose at the come-along starts the drum and
	# the pour loops, which would idle under the title for as long as it stood.
	if sfx != null and sfx.has_method("stop_all"):
		sfx.stop_all()


## The pose a backdrop opens at: its stage, or - when the title asked it to read
## the save - the row and the places the child left, as PLAY leaves them.
func _dress_args() -> Dictionary:
	var a: Dictionary = {"stage": dress_stage, "shot": dress_shot, "nohud": true}
	if not _resume.is_empty():
		var at := int(_resume["step"])
		var ids := PackedStringArray()
		for v in (_resume["places"] as Array):
			ids.append(str(int(v)))
		a["stage"] = stage_for_step(at)
		a["step"] = str(at)
		a["done"] = int(_resume["done"])
		a["places"] = ",".join(ids)
		a["play"] = true
	return a


## Is there a job to carry on with? Asked by the title, of the backdrop, after
## it has read the save (`dress_from_save`).
func resume_ready() -> bool:
	return not _resume.is_empty()


## Either play the job from the top, or pose it for a screenshot or a test.
func _start(args: Dictionary) -> void:
	if job == null:
		push_error("SiteMain: no job loaded")
		return
	var stage := String(args.get("stage", ""))
	if stage != "":
		var places: Array = []
		for bit in String(args.get("places", "")).split(",", false):
			if bit.strip_edges().is_valid_int():
				places.append(int(bit))
		# `play` poses the world as PLAY leaves that row - no picture tricks -
		# which is what a resumed job and the title's backdrop want.
		pose(stage, step_arg(String(args.get("step", "")), stage), int(args.get("done", 0)), places, args.has("play"))
		if args.has("shot"):
			# `--eye=x,y,z` / `--look=x,y,z` try other offsets for the named shot
			# without an edit per render (the critic loop's camera work).
			var a := runner.shot_anchor(String(args["shot"]))
			if args.has("eye") or args.has("look"):
				var shot_name := String(args["shot"])
				# An anchor that carries its OWN offsets (the long bars' group, the
				# kerb stake pair) wins over the shot's in `CameraRig._own`, so a
				# `define` did nothing there: the override goes onto the anchor.
				if a != null and a.has_meta("shot_eye"):
					var eye_m := _vec_arg(args, "eye", Vector3(a.get_meta("shot_eye")))
					var look_m := _vec_arg(args, "look", Vector3(a.get_meta("shot_look", Vector3.FORWARD)))
					a.set_meta("shot_eye", eye_m)
					a.set_meta("shot_look", look_m)
					print("SHOT_OVERRIDE %s (anchor %s) eye %s look %s" % [shot_name, a.name, str(eye_m), str(look_m)])
				else:
					var eye_v := _vec_arg(args, "eye", rig.shot_eye(shot_name))
					var look_v := _vec_arg(args, "look", rig.shot_look(shot_name))
					rig.define(shot_name, rig.anchor_name(shot_name), eye_v, look_v)
					print("SHOT_OVERRIDE %s eye %s look %s" % [shot_name, str(eye_v), str(look_v)])
			rig.snap(String(args["shot"]), a)
			if OS.has_environment("BC_DEBUG"):
				print("HUD bar %.3f total %d progress %d job_total %d" % [hud.step_value(), hud.total_steps(),
					runner.progress, job.total_weight()])
				var mx := machine("ConcreteTruck")
				if mx != null:
					for n in mx.find_children("*", "MeshInstance3D", true, false):
						var mi := n as MeshInstance3D
						if not mi.is_visible_in_tree():
							continue
						var ab := mi.global_transform * mi.get_aabb()
						var ctr := ab.get_center()
						print("MIXER_MESH %s centre %s size %s screen %s behind %s" % [mi.get_path(), str(ctr),
							str(ab.size), str(camera.unproject_position(ctr)), str(camera.is_position_behind(ctr))])
			var mixer_m := machine("ConcreteTruck")
			if _stream != null and _stream.visible and mixer_m != null:
				print("CHUTE spout %s stream_colour %s pool_at %s" % [str(mixer_m.spout_world()),
					str(_stream_mat.albedo_color if _stream_mat != null else Color.BLACK),
					str(drive.pool_colour_at(mixer_m.spout_world()))])
			print("SHOT_ANCHOR %s -> %s at %s; eye %s fov %.1f keep %d" % [String(args["shot"]),
				a.name if a != null else "none", str(a.global_position) if a != null else "-",
				str(camera.global_position), camera.fov, camera.keep_aspect])
		# `--cursor=x,z` stands the work point somewhere on the slab, the way the
		# smoke test does, so a DRAGGED beat can be photographed at all: there is
		# no finger on a screenshot.
		if args.has("cursor"):
			var bits := String(args["cursor"]).split(",", false)
			if bits.size() >= 2:
				set_work_cursor(Vector3(float(bits[0]), Driveway.GRADE, float(bits[1])))
		# `--hold` presses and KEEPS pressing, so `--wait=S` catches a hold beat
		# half way through its work instead of at its first frame. Every picture
		# of a tipping bed or a running chute needs it.
		if args.has("hold"):
			runner.hold(true)
		# `--tap` plays one TAP beat, so a bite can be caught mid-swing.
		if args.has("tap"):
			runner.tap()
		# `--beacon=K` holds every machine's beacon at K (0..1), so two frames of
		# one pose differ only in the beacon: its pulse runs on the wall clock.
		if args.has("beacon"):
			for mk: String in machines:
				var bm := machine(mk)
				if bm != null:
					bm.pin_beacon(float(args["beacon"]))
		# `--hide=A,B` hides named nodes of the level, to find which box a
		# stray rectangle in a render belongs to.
		if args.has("hide"):
			for want in String(args["hide"]).split(",", false):
				for n in find_children(want, "", true, false):
					if n is Node3D:
						(n as Node3D).visible = false
		return
	if not _resume.is_empty():
		resume(_resume)
		return
	runner.start(job, drive, false)
	# The job OPENS on the wide - the house, the cracked drive, the tools, the
	# first slab's rings lit - and holds there before the eye comes down to
	# the slab (the plan's 3.1). It opened snapped on a grey close-up: the
	# child had never seen the house or that the drive was cracked, and DESIGN
	# 1a always said WIDE was "the opening and every payoff".
	rig.snap(CameraRig.WIDE, null)
	_opening = true
	_opening_left = config.opening_hold


## Poses the whole level at the start of a phase, with no animation: the world
## through `Driveway.pose_stage`, the machines where that phase has them, and the
## runner on the step that phase begins with.
##
## `places` names WHICH of the step's first `done` places are done, for the rows
## a child takes in any order (6.2); empty is the canonical order every earlier
## `--done` picture was taken with. (The jackhammer and the push had no `--done`
## pose before the sixth session; they have one now, the jackhammer's in that
## same first-open-place order.) `play` is a resumed job rather than a
## picture: none of the picture's tricks - the tool posed mid-work in its own
## shot, the truck hidden for the pour, the blade down - only the world as play
## leaves it when the row opens (`resume`).
func pose(stage: String, step: int = -1, done: int = 0, places: Array = [], play: bool = false) -> void:
	_posed = not play
	drive.pose_stage(stage)
	var at := step if step >= 0 else stage_step(stage)
	# The job is OVER in both end states: the bar full, no arrow, no tool.
	# Posed at the broom's step they showed 95.8% (round 10).
	if stage == "done" or stage == "parked":
		at = job.steps.size()
	# `--nomachine` leaves the site empty: the machine that works a phase parks
	# ON the driveway and hides the very thing the phase changed, so there is no
	# other way to photograph the gravel base or the fresh pour.
	# The payoff was the only part of the whole job no eye had ever been on: no
	# `--stage` ran it, so the broom finish, the cured light and the car parked on
	# the new drive were seen by the smoke test's assertions and by nothing else.
	if stage == "parked":
		drive.strip_forms(1.0)
		drive.hide_rubble(1.0)
		_cure(1.0)
		# What play does at the cut to the street (3.4) and through the cure
		# (3.3): the kit gone, the cones gone, the chrome gone.
		_clear_kit(true)
		if hud != null:
			hud.set_chrome_target(0.0, true)
		_place_car_on_drive()
	# Parked for the STEP being posed, not for the stage name. Posing a beat with
	# `--step` used to leave the street empty, because the machine was chosen off a
	# stage that knew nothing about the override - and round 1's own log told the
	# next critic to do exactly that.
	var posed: JobStep = job.steps[at] if at >= 0 and at < job.steps.size() else null
	if _no_machine:
		# The same door and the same tool as the machine path: this branch used
		# to return before either, so every `--nomachine` picture had the garage
		# shut and the tool on the lawn (round 3, the eighth pose/play drift).
		if at >= 2:
			set_garage_door(1.0)
		runner.start(job, drive, false)
		runner.pose_at(at, done)
		_pose_tool(posed)
		drive.refresh_now()
		return
	var wants := ""
	if posed != null:
		wants = {"push_rubble": "SkidSteer", "skid_leave": "SkidSteer",
			"tip_gravel": "DumpTruck", "dump_leave": "DumpTruck",
			"pour_chute": "ConcreteTruck", "rake_pull": "ConcreteTruck",
			"mixer_leave": "ConcreteTruck"}.get(posed.verb, "")
	if wants == "" and posed == null:
		# Only when there is no step to ask. A STEP knows whether its phase has a
		# machine on site; a stage name does not, and the fallback parked the mixer
		# on the drive for the water - a beat the job sends it away before.
		wants = {"cleared": "SkidSteer", "banded": "ConcreteTruck"}.get(stage, "")
	if wants != "":
		_park_machine(wants)
	# A truck waiting in the road to be backed in (1.8): where play's street leg
	# stops it and facing the way play turns it, from the same helpers, so a
	# `--hold` picture drives the route play drives.
	if posed != null and SiteVerbs.BACK_VERBS.has(posed.verb):
		_stage_at_street(String(SiteVerbs.BACK_VERBS[posed.verb]))
	# Open from the moment the skid steer is on site until the cure shuts it, which
	# is what play does: posing it shut put a closed garage door behind the pour,
	# the joints and the broom, in every picture anybody judged them from.
	if at >= 2:
		set_garage_door(1.0)
	runner.start(job, drive, false)
	runner.pose_at(at, done)
	if not play:
		_pose_tool(posed)
	# The pour's own trick has to be posed too, or every picture of the centrepiece
	# is of something the game never shows: the truck gone, the chute over the form,
	# and the camera's own point sitting under the spout.
	# A resumed POUR does none of it: its verb hides the truck itself once the eye
	# is still. A resumed RAKE opens where play leaves the pour - the truck
	# undrawn, the chute running, the drum turning - which the rake's own verb
	# only sets up on the first press.
	# ...but never for a BACKDROP: a menu standing in front of an undrawn truck
	# is a chute floating in the road, and the loops this branch starts would run
	# under the title for as long as it was up.
	if posed != null and not dress_only 			and (posed.verb == "rake_pull" or (posed.verb == "pour_chute" and not play)):
		var mixer := machine("ConcreteTruck")
		if mixer != null:
			mixer.set_chute(0.0, config.chute_fold_max)
			mixer.set_chute_mud(true)
			mixer.show_only(["Chute"])
			set_pour_view(mixer.pour_point_world(Driveway.GRADE).z, 1.0)
			set_pour(true)
			set_pour_point(mixer.spout_world(), mixer.pour_point_world(Driveway.GRADE), mixer.spout_dir())
			if args_shot_is(CameraRig.CHUTE):
				rig.snap(CameraRig.CHUTE, runner.shot_anchor(CameraRig.CHUTE))
			if play:
				mixer.spin_drum(config.drum_rps)
				mixer.set_beacon_on(true)
				if sfx != null:
					sfx.play_loop(SiteVerbs.SOUND_DRUM, "mixer")
					sfx.play_loop(SiteVerbs.SOUND_CONCRETE, "concrete")
	# A tap phase posed part-way (`--done=N`): the first N of its places are done,
	# so a picture of the second pair of cross bars has the long bars under them.
	if posed != null and done > 0:
		match posed.verb:
			# The hammer's spots, the boards, the pegs, the bars and the strip are
			# the child's to take in any order: the places named, where they are
			# still a legal pick (`_apply_places`).
			"jack_spot":
				_apply_places(posed.verb, places, done)
			"rebar_lay":
				drive.show_chairs(true)
				if not places.is_empty():
					_apply_places(posed.verb, places, done)
				else:
					for b in range(1, done + 1):
						drive.set_bar(b, 1.0)
			# By STATE, never "places 1..done": the kerb board's own row posed
			# with `--done=1` used to set board 1, which went in a phase ago (5.2).
			"form_set":
				if not places.is_empty():
					_apply_places(posed.verb, places, done)
				else:
					for b in drive.live_open_forms().slice(0, done):
						drive.set_form(b, 1.0)
			"stake_drive":
				if not places.is_empty():
					_apply_places(posed.verb, places, done)
				else:
					var pegs := PackedInt32Array()
					for g in range(drive.stake_group_count()):
						pegs.append_array(drive.open_stakes_in(g))
					for b in pegs.slice(0, done):
						drive.set_stake(b, 1.0)
			"push_rubble":
				# The first lane on the heap, and the machine lined up on the
				# second inside the garage with its blade down - where the first
				# pass leaves it.
				for lane in range(1, mini(done, drive.push_lanes()) + 1):
					drive.push_lane(lane, Driveway.Z_KERB, true)
				var skid_d := machine("SkidSteer")
				if skid_d != null and done < drive.push_lanes():
					skid_d.place(Vector3(drive.lane_drive_x(done + 1), 0.0, Driveway.Z_APRON - config.garage_stand), 0.0)
					skid_d.global_position.y = _ground_y(skid_d.global_position)
			"compact_base":
				for b in range(1, done + 1):
					drive.pack_bay(b)
			"form_strip":
				if not places.is_empty():
					_apply_places(posed.verb, places, done)
				else:
					for b in drive.open_strip_forms().slice(0, done):
						drive.strip_form(b, 1.0)
			"joint_cut":
				for j in range(1, done + 1):
					drive.cut_joint(j, 1.0)
			"broom_finish":
				for b in range(1, done + 1):
					drive.broom_bay(b)
		runner.pose_at(at, done)
		# Again, now the first N are down: the sledge was posed over stake 1,
		# which `--done` has just driven (4.2).
		if not play:
			_pose_tool(posed)
	# The push, posed: blade down on the dirt, as it is the moment the child holds.
	# Resumed, the machine is as play leaves it: carried high after the drive in,
	# down on the next lane after a pass.
	if posed != null and posed.verb == "push_rubble":
		var skid := machine("SkidSteer")
		if skid != null:
			if play and done == 0:
				skid.set_bucket(1.0, 0.30)
			else:
				skid.set_bucket(0.0, 0.0)
	# The rebar, posed: the chairs are down and the live group waits in the air.
	if posed != null and posed.verb == "rebar_lay":
		drive.show_chairs(true)
	# The surface is rebuilt on the next frame in play; a pose wants it NOW, so
	# the first frame a screenshot sees is the slab and not the gravel.
	drive.refresh_now()
	# The cure gets the LAST word. `pose_at` calls `present_tool` and `_pose_tool`,
	# which put the final beat's tool back at full strength - so a cure run before
	# them faded nothing and the broom lay on the lawn of a finished driveway.
	if stage == "parked" or stage == "cured" or stage == "done":
		_cure(1.0)
	if stage == "cured" or stage == "done":
		# The broom lying on the grass where its phase put it, as play leaves it
		# until the cut.
		var broom_t := tool_node("broom")
		if broom_t != null:
			broom_t.visible = true
			broom_t.hover_instant(TOOL_REST["broom"], Vector3.FORWARD, Vector3.UP)
		# The cure's shape (3.4), posed: the cones across the mouth of the
		# drive, where the cure beat slides them, through the strip.
		var posts := _cone_posts()
		for i in range(posts.size()):
			posts[i].global_position = _cone_mouth(i)
	if stage == "parked" or stage == "done":
		# The job is over in both of these, and `_finish` takes the arrow away
		# before the payoff runs: a posed reward with a gold wedge hanging over the
		# car is a picture of a state the game never reaches. And the broom is not
		# left lying on the slab (round 4).
		hud.hide_arrow()
		present_tool("none")


## Is the shot being asked for on the command line this one? Only `pose` needs to
## know, so that a posed beat can re-snap after it has moved what the shot hangs
## off.
func args_shot_is(shot_name: String) -> bool:
	var args: Dictionary = Engine.get_meta("shot_args", {}) as Dictionary
	return String(args.get("shot", "")) == shot_name


## The step a `--stage` poses, looked up by its verb (`STAGE_STEP`): the job's
## step count for `done` and `parked`, 0 for a stage nobody named.
func stage_step(stage: String) -> int:
	if job == null or not STAGE_STEP.has(stage):
		return 0
	var want: Array = STAGE_STEP[stage]
	if String(want[0]) == "":
		return job.steps.size()
	return maxi(job.index_of(String(want[0]), int(want[1])), 0)


## A `--step` argument: a number, a verb (`pour_chute`), or a verb and which of
## its rows (`form_set:2`). Empty asks the stage.
func step_arg(value: String, stage: String) -> int:
	if value == "":
		return stage_step(stage)
	if value.is_valid_int():
		return int(value)
	var bits := value.split(":", false)
	var nth := int(bits[1]) if bits.size() > 1 and bits[1].is_valid_int() else 1
	var i := job.index_of(bits[0], nth) if job != null else -1
	if i < 0:
		push_warning("SiteMain: no step plays '%s'" % value)
		return stage_step(stage)
	return i


## Puts the posed step's TOOL where its verb would hold it, instead of leaving it
## lying on the grass.
##
## This exists because of a fault this project has hit three times: the `--stage`
## path the screenshots are judged from drifts away from what the game really
## does, and then the EVIDENCE flatters the build. A posed picture of the stakes
## with the sledge parked forty feet away on the lawn cannot show whether the shot
## frames the blow, which is the one thing it was taken to show.
func _pose_tool(step: JobStep) -> void:
	if step == null or step.tool == "" or step.tool == "none":
		return
	var t := tool_node(step.tool)
	if t == null:
		return
	# A tool held in the child's HANDS (the hose, the broom, the rake) is only
	# there in that beat's own shot: posed into a WIDE it was a tenth-size hose
	# spraying in mid-air over the apron (round 5).
	if step.verb in ["spray_water", "broom_finish", "rake_pull", "compact_base"] and not args_shot_is(step.shot):
		t.visible = false
		return
	t.visible = true
	match step.verb:
		"jack_spot":
			# Over the first spot still to do (`--places` can have done spot 1).
			var spot := drive.spot_marker(maxi(drive.first_open_spot(drive.current_panel()), 1))
			if spot != null:
				t.hover_instant(spot.global_position, Vector3.DOWN, Vector3.FORWARD)
		"stake_drive":
			# Wound up over the painted cap of the first stake still standing,
			# as the verb holds it before the fall (4.2).
			var open_s := drive.open_stakes_in(drive.current_stake_group())
			var si: int = open_s[0] if not open_s.is_empty() else 1
			if not drive.stake_is_in(si):
				drive.set_stake(si, 0.0)
			var sh := drive.stake_home(si)
			t.hover_instant(Vector3(sh.x, drive.stake_cap(si).y + Driveway.STAKE_CAP * 0.5 + config.sledge_lift, sh.z),
				Vector3.DOWN, Vector3.FORWARD)
		"spray_water":
			# In the hands, aimed at the driest patch, through the verb's own
			# helper: it was parked in WORLD space over the far slab with a
			# vertical jet stub, which no play frame ever shows (4.3).
			t.spray(true)
			hold_hose(t, drive.driest_world())
		"rake_pull":
			var front := rake_hint()
			var rhead := Vector3(front.x, Driveway.GRADE + 0.012, front.z)
			var rhands := hand_hold(Vector3(0.20, -0.80, 0.55))
			t.hover_instant(rhead, Vector3.DOWN, (rhands - rhead).normalized())
			t.aim_handle_at(rhands)
			set_rake_view(drive.pour_front_z(), 3.0, 1.0, 1.0)
		"screed_pull":
			t.hover_instant(Vector3(Driveway.CENTRE_X, Driveway.GRADE + 0.002,
				drive.screed_line_z(0.45)), Vector3.FORWARD, Vector3.UP)
			set_screed_view(drive.screed_line_z(0.45))
		"joint_cut":
			var jn := clampi(runner.done_in_step + 1, 1, drive.joint_count())
			var jpt := Vector3(Driveway.CENTRE_X - Driveway.WIDTH * 0.5 + 0.9, Driveway.GRADE, drive.joint_z(jn))
			# The eye stands on the joint's middle: snap it there before the
			# handle is aimed at the hands, or the hands are where the eye was.
			rig.snap(CameraRig.JOINT, drive.joint_marker(jn))
			var jh := hand_hold(Vector3(0.20, -0.80, 0.55))
			t.hover_instant(jpt, Vector3.DOWN, (jh - jpt).normalized())
			t.aim_handle_at(jh)
			t.align_head(Vector3.RIGHT)
		"compact_base":
			var pbay := clampi(runner.done_in_step + 1, 1, drive.bay_count())
			set_plate_view(drive.plate_start(pbay))
			if args_shot_is(CameraRig.PLATE):
				rig.snap(CameraRig.PLATE, _plate_view)
			hold_plate(t, drive.plate_start(pbay), pbay, false)
		"broom_finish":
			var bay := clampi(runner.done_in_step + 1, 1, drive.bay_count())
			var band := drive.bay_range(bay)
			rig.snap(CameraRig.BROOM, drive.bay_marker(bay))
			var rough := drive.roughest_world_in(band.x, band.y)
			var head := Vector3(rough.x, Driveway.GRADE + 0.01, rough.z)
			var bhands := hand_hold(Vector3(0.20, -0.80, 0.55))
			t.hover_instant(head, Vector3.DOWN, (bhands - head).normalized())
			t.aim_handle_at(bhands)


# --- The lot ----------------------------------------------------------------------------------

func _build_world() -> void:
	_build_light()
	_build_ground()
	_build_street()
	_dress()


## One warm afternoon sun and a lot of sky, the way the whole family is lit: a
## low-poly scene wants flat bright light, not drama. The sun's angle is what the
## cure sweeps at the end of the job.
func _build_light() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var pan := ProceduralSkyMaterial.new()
	pan.sky_top_color = Color(0.38, 0.60, 0.90)
	pan.sky_horizon_color = Color(0.78, 0.86, 0.94)
	# The sky's GROUND half is what a wide sees past the end of the lawn: make
	# it lawn, hazed, so the world reads as grass to the horizon and not as a
	# grey-green murk with no sky (round 9).
	pan.ground_bottom_color = Color(0.40, 0.58, 0.30)
	pan.ground_horizon_color = Color(0.64, 0.76, 0.58)
	pan.sun_angle_max = 12.0
	sky.sky_material = pan
	env.sky = sky
	# A warm neutral fill, NOT the sky: sky-source ambient made every shadow on
	# pale concrete a saturated blue (round 3 measured B-R +77 in the pour's own
	# shadow, and the car's shadow on the finished slab read as a puddle).
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.84, 0.82, 0.78)
	env.ambient_light_energy = 0.60
	env.ssao_enabled = false
	var we := WorldEnvironment.new()
	we.name = "Env"
	we.environment = env
	add_child(we)
	_env = env
	_sky = pan
	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.light_energy = 1.25
	_sun.light_color = Color(1.0, 0.97, 0.90)
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 60.0
	# A soft edge: the map is under-resolved for a receiver as bright as a new
	# slab, and a hard stair-stepped shadow edge on it crawls under the orbit.
	_sun.shadow_blur = 1.1
	# Over the viewer's left shoulder, high: the drive and the machines both
	# catch light on the side the camera is on.
	_sun.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(34.0), 0.0)
	add_child(_sun)


## The grass the lot stands on, with a DRIVE-SHAPED HOLE IN IT.
##
## This is four boxes and not one for a reason that cost a whole round of
## screenshots: one lawn box spanning the lot has its top at grade, and the
## driveway lives BELOW grade for most of the job - the excavation, the gravel
## base, and the slab itself until the moment it is struck off. With a solid lawn
## the hole could not be a hole, the base was buried inside it, and the pour shot
## showed a form 94% full of concrete with not a drop of it visible.
##
## So the grass stops at the edge of the pad on all four sides, and what is inside
## that rectangle belongs entirely to `Driveway`.
func _build_ground() -> void:
	# The grass stops at the OUTSIDE of the form's trench, not at the pad's
	# edge: with the lawn box running to the pad, the boards and the cut-back
	# banks were inside it, and every board vanished the moment the slab came up
	# to grade beside it (round 5).
	var trench := 0.08 + 0.14
	var x0 := Driveway.CENTRE_X - Driveway.WIDTH * 0.5 - trench
	var x1 := Driveway.CENTRE_X + Driveway.WIDTH * 0.5 + trench
	var z0 := Driveway.Z_APRON
	var z1 := Driveway.Z_KERB + trench
	var green := Color(0.42, 0.62, 0.30)
	# Each strip is a corner pair in the GROUND plane, so these are Vector2s of
	# (x, z) - not Vector3s with the height left off, which is not a constructor.
	var strips: Array[Rect2] = [
		# left of the drive, right of it, behind it, and the sliver to the kerb.
		Rect2(Vector2(-LOT_HALF_X, LOT_BACK_Z), Vector2(x0 + LOT_HALF_X, LOT_FRONT_Z - LOT_BACK_Z)),
		Rect2(Vector2(x1, LOT_BACK_Z), Vector2(LOT_HALF_X - x1, LOT_FRONT_Z - LOT_BACK_Z)),
		# ...stopping 0.3 m short of the apron: its front face was coplanar
		# with the garage floor's and the two z-fought as a green band across
		# the door opening from the stake eye (round 14).
		Rect2(Vector2(x0, LOT_BACK_Z), Vector2(x1 - x0, z0 - 0.3 - LOT_BACK_Z)),
	]
	# (No sliver of lawn between the pad and the kerb: the crossing covers it,
	# and the two z-fought along the kerb line - round 10.)
	for i in range(strips.size()):
		var r := strips[i]
		if r.size.x <= 0.001 or r.size.y <= 0.001:
			continue
		add_child(_box("Lawn_%d" % (i + 1), Vector3(r.size.x, 0.4, r.size.y),
			Vector3(r.get_center().x, -0.2, r.get_center().y), green))


## The road, its kerb and the footway across the front of the lot.
func _build_street() -> void:
	# The road's top is ABOVE the lawn's (0.0), or the lawn buries it and the
	# street shows as a 1.3 m strip of grass between the kerb and the carriageway.
	# From the back of the kerb out: there was a metre of lawn between the kerb
	# and the carriageway, a grass gutter in every wide shot (round 5).
	add_child(_box("Road", Vector3(LOT_HALF_X * 2.0 + 12.0, 0.3, 6.4),
		Vector3(0.0, -0.14, STREET_Z + 0.6), Color(0.34, 0.34, 0.36)))
	# The crown of the road is a shade paler, so it is not one flat grey band.
	add_child(_box("RoadCrown", Vector3(LOT_HALF_X * 2.0 + 12.0, 0.02, 5.6),
		Vector3(0.0, 0.015, STREET_Z + 0.6), Color(0.38, 0.38, 0.40)))
	# The kerb is DROPPED across the drive - two runs either side of it - and
	# the crossing's top is at GRADE, so the new drive meets the road without a
	# 9.5 cm step the car has to climb (round 9).
	var kx0 := Driveway.CENTRE_X - Driveway.WIDTH * 0.5
	var kx1 := Driveway.CENTRE_X + Driveway.WIDTH * 0.5
	var khalf := LOT_HALF_X + 6.0
	for kside: Vector2 in [Vector2(-khalf, kx0), Vector2(kx1, khalf)]:
		add_child(_box("Kerb", Vector3(kside.y - kside.x, 0.13, 0.18),
			Vector3((kside.x + kside.y) * 0.5, 0.035, KERB_Z + 0.09), Color(0.78, 0.77, 0.73)))
	# SPLIT either side of the drive, exactly as `_build_ground` splits the lawn.
	# One box 1.4 m deep lay 1.10 m ON the pad and 12.5 cm above it, so the last
	# metre of every single phase was underneath the pavement - the kerb-end form
	# board was never once visible, and a third of the first slab the child is
	# asked to break was buried. Round 1 pulled the `Crossing` box off the pad and
	# left the bigger box behind it doing the identical thing.
	var fx0 := Driveway.CENTRE_X - Driveway.WIDTH * 0.5
	var fx1 := Driveway.CENTRE_X + Driveway.WIDTH * 0.5
	var half := LOT_HALF_X + 6.0
	for side: Vector2 in [Vector2(-half, fx0), Vector2(fx1, half)]:
		add_child(_box("Footway", Vector3(side.y - side.x, 0.13, 1.4),
			Vector3((side.x + side.y) * 0.5, 0.03, KERB_Z - 0.7), Color(0.64, 0.64, 0.62)))
	# The drive's own crossing over the footway, in the new slab's colour, so the
	# drive reads as joining the road rather than stopping at a wall.
	# From the END of the drive to the kerb, and no further back. At 1.42 m deep
	# it reached 1.11 m ONTO the pad with its top 13 cm proud of the slab, so it
	# swallowed the kerb-end form board whole and hid the last metre of the base,
	# the pour and the finished slab underneath itself.
	# It starts BEHIND the kerb-end board (not around it): with the board
	# buried in the crossing their tops and faces z-fought.
	# ...and behind the kerb board's TRENCH since the plan's fifth session, the
	# way the lawn starts behind the side ones: the kerb board's two pegs are
	# driven in a close-up from the road now (5.2), and they stood in the
	# crossing's concrete. The kerb bank fills the gap at grade before the cut
	# and after the backfill, in the crossing's own grey.
	var cross_from := Driveway.Z_KERB + 0.22
	add_child(_box("Crossing", Vector3(Driveway.WIDTH, 0.13, KERB_Z + 0.20 - cross_from),
		Vector3(Driveway.CENTRE_X, -0.065, (cross_from + KERB_Z + 0.20) * 0.5),
		Color(0.64, 0.64, 0.62)))


## The house and the props round it, each seated on the ground by its own
## measured box rather than by a guess at where its origin is.
func _dress() -> void:
	# LEFT of the drive, not astride it. At x -1.6 the house's own footprint
	# overlapped the garage's by three metres, which is the "clips right into the
	# house" in the user's fourth note: there were two buildings in the same place
	# and a machine reversing into both of them.
	var house := _place(STREET_MODELS + "StarterHome.glb", "House", Vector3(-5.4, 0.0, -10.2), 180.0)
	# The visit's wall paint (6.1), on a copy: the imported material is cached
	# across NEXT and a paint written into it would stay on the next house.
	var wall_paint: Color = look.get("house", Color(0, 0, 0, 0))
	if house != null and wall_paint.a > 0.0:
		_paint_named(house, "Equip_Trim", wall_paint)
	_build_garage()
	# On the verge behind the footway, not standing in the middle of it.
	# Clear of the rubble heap (round 6: the heap grew to the size of the
	# drive it came off, and the mailbox was inside it).
	_place(STREET_MODELS + "Mailbox.glb", "Mailbox", Vector3(10.4, 0.0, 4.3), 200.0)
	_place(STREET_MODELS + "StreetTree.glb", "TreeL", Vector3(-8.4, 0.0, 3.2), 0.0)
	_place(STREET_MODELS + "StreetTree.glb", "TreeR", Vector3(9.8, 0.0, 1.4), 140.0)
	_place(STREET_MODELS + "Hedge.glb", "Hedge", Vector3(-6.6, 0.0, -1.0), 0.0)
	_place(STREET_MODELS + "PicketFence.glb", "FenceA", Vector3(-10.2, 0.0, 1.0), 0.0)
	_place(STREET_MODELS + "PicketFence.glb", "FenceB", Vector3(-10.2, 0.0, 5.2), 0.0)
	_place(STREET_MODELS + "StreetLight.glb", "Lamp", Vector3(-11.4, 0.0, 6.2), 90.0)
	# The job's own furniture: cones closing the drive off at the kerb, and the
	# site fence across the footway. A real crew does this first.
	# Kept hold of: this is the crew's own kit, and it goes away with the crew.
	# Wide of the drive, on the footway: at 2.3 m the left cone stood at the
	# bottom-centre of every wide shot, the most saturated thing in the
	# foreground (round 10).
	# ON the footway, whose top is 9.5 cm above grade (the Footway box: 0.13
	# tall, centred at 0.03): at y = 0 the cones stood buried to the first band.
	_site_kit.append(_place(STREET_MODELS + "TrafficCone.glb", "ConeL",
		Vector3(Driveway.CENTRE_X - 4.7, FOOTWAY_TOP, KERB_Z - 0.45), 0.0))
	_site_kit.append(_place(STREET_MODELS + "TrafficCone.glb", "ConeR",
		Vector3(Driveway.CENTRE_X + 2.6, FOOTWAY_TOP, KERB_Z - 0.55), 0.0))
	# Alongside the work, clear of the pad and clear of the swing the skid steer
	# makes off the end of the drive onto the heap.
	# Further out and further up than it was (3.4 m off the pad at z 0.6): there
	# it was the loudest thing in five consecutive working frames, right of every
	# picture taken from the kerb end (round 3).
	_site_kit.append(_place(STREET_MODELS + "ConstructionFence.glb", "Fence",
		Vector3(Driveway.CENTRE_X + 6.0, 0.0, -2.8), 90.0))


## The garage: a floor, three walls, a front wall with a hole in it, a gable roof
## and a roller door that opens.
##
## Its front face is exactly on `Driveway.Z_APRON`, so the drive runs up to the
## door and the excavation stops where the building starts. Inside is 6.4 m deep,
## which is what a 3.44 m skid steer needs to get its whole length in, turn round
## on the spot and push the full length of a column back out.
func _build_garage() -> void:
	var cx := Driveway.CENTRE_X
	var front := Driveway.Z_APRON
	var back := front - GARAGE_DEEP
	var mid := (front + back) * 0.5
	# The walls take the visit's swatch with the house (6.1): one property.
	var wall: Color = look.get("garage_wall", Color(0.88, 0.86, 0.80))
	var trim := Color(0.74, 0.72, 0.66)
	var roof := Color(0.42, 0.36, 0.34)
	var inside := Color(0.40, 0.35, 0.30)
	# The floor, and it is CONCRETE: the machine stands on it at grade, which is
	# 0.2 m above the dirt it has dug out in front of the door.
	#
	# Its top is 2 cm PROUD of the lawn, because the lawn's own top is exactly
	# grade: at the same height the two z-fought and the open door looked into a
	# garage with a green floor.
	add_child(_box("GarageFloor", Vector3(GARAGE_WIDE, 0.30, GARAGE_DEEP),
		Vector3(cx, -0.13, mid), Color(0.55, 0.52, 0.47)))
	var side_x := GARAGE_WIDE * 0.5 - GARAGE_WALL * 0.5
	# The walls and jambs stand ON the floor's top (0.02), not 2 cm into it:
	# sunk, their front faces shared the floor's front plane and z-fought.
	for sx: float in [-1.0, 1.0]:
		add_child(_box("GarageWall", Vector3(GARAGE_WALL, GARAGE_EAVE - 0.02, GARAGE_DEEP),
			Vector3(cx + sx * side_x, 0.02 + (GARAGE_EAVE - 0.02) * 0.5, mid), wall))
	add_child(_box("GarageBack", Vector3(GARAGE_WIDE, GARAGE_EAVE, GARAGE_WALL),
		Vector3(cx, GARAGE_EAVE * 0.5, back + GARAGE_WALL * 0.5), inside))
	# The front wall is two jambs and a lintel, which is what leaves a hole.
	var jamb := (GARAGE_WIDE - DOOR_WIDE) * 0.5
	for sx: float in [-1.0, 1.0]:
		add_child(_box("GarageJamb", Vector3(jamb, GARAGE_EAVE - 0.02, GARAGE_WALL),
			Vector3(cx + sx * (DOOR_WIDE + jamb) * 0.5, 0.02 + (GARAGE_EAVE - 0.02) * 0.5,
				front - GARAGE_WALL * 0.5), wall))
	add_child(_box("GarageLintel", Vector3(DOOR_WIDE, GARAGE_EAVE - DOOR_HIGH, GARAGE_WALL),
		Vector3(cx, (GARAGE_EAVE + DOOR_HIGH) * 0.5, front - GARAGE_WALL * 0.5), trim))
	# The gable ends, as real triangles: `PrismMesh` is the one primitive that is
	# one, and a box pretending to be a gable is a shed.
	var rise := GARAGE_RIDGE - GARAGE_EAVE
	for z: float in [front - GARAGE_WALL * 0.5, back + GARAGE_WALL * 0.5]:
		var gable := MeshInstance3D.new()
		gable.name = "GarageGable"
		var pm := PrismMesh.new()
		pm.size = Vector3(GARAGE_WIDE, rise, GARAGE_WALL)
		var gm := StandardMaterial3D.new()
		gm.albedo_color = wall
		gm.roughness = 0.9
		pm.material = gm
		gable.mesh = pm
		gable.position = Vector3(cx, GARAGE_EAVE + rise * 0.5, z)
		add_child(gable)
	# Two roof planes, tilted to meet at the ridge. Going +X rises on the left
	# half and falls on the right, which is the sign of the tilt about +Z.
	var half := GARAGE_WIDE * 0.5
	var slope := sqrt(half * half + rise * rise)
	var tilt := atan2(rise, half)
	for sx: float in [-1.0, 1.0]:
		var plane := _box("GarageRoof", Vector3(slope + 0.16, 0.09, GARAGE_DEEP + 0.34),
			Vector3(cx + sx * half * 0.5, GARAGE_EAVE + rise * 0.5, mid), roof)
		plane.rotation.z = -sx * tilt
		add_child(plane)
	# Something in it. An open door onto an empty white box is the least convincing
	# thing on the lot, and the door is open for nine of the job's ten phases: a
	# bench down the back wall, a shelf over it and a couple of tubs on the floor
	# are four boxes and they make it a garage.
	var timber := Color(0.56, 0.42, 0.28)
	add_child(_box("GarageBench", Vector3(GARAGE_WIDE - 0.6, 0.08, 0.62),
		Vector3(cx, 0.88, back + 0.55), timber))
	for sx: float in [-1.0, 1.0]:
		add_child(_box("GarageBenchLeg", Vector3(0.09, 0.86, 0.09),
			Vector3(cx + sx * (GARAGE_WIDE * 0.5 - 0.62), 0.43, back + 0.55), timber.darkened(0.2)))
	add_child(_box("GarageShelf", Vector3(GARAGE_WIDE - 0.6, 0.06, 0.36),
		Vector3(cx, 1.72, back + 0.42), timber))
	add_child(_box("GarageTub", Vector3(0.52, 0.44, 0.44),
		Vector3(cx - 1.65, 0.22, back + 1.5), Color(0.32, 0.44, 0.58)))
	add_child(_box("GarageTub", Vector3(0.46, 0.38, 0.40),
		Vector3(cx - 1.60, 0.61, back + 1.44), Color(0.60, 0.46, 0.30)))
	# The roller door, as slats. Closed it fills the opening; open it has rolled
	# up into its own drum and there is nothing in the way.
	var pitch := DOOR_HIGH / float(DOOR_SLATS)
	for j in range(DOOR_SLATS):
		var slat := _box("DoorSlat_%d" % (j + 1),
			Vector3(DOOR_WIDE - 0.05, pitch * 0.92, 0.06),
			Vector3(cx, pitch * (float(j) + 0.5), front - GARAGE_WALL - 0.05),
			trim.lightened(0.04) if j % 2 == 0 else trim)
		add_child(slat)
		_door_slats.append(slat)
	set_garage_door(0.0)


## The roller door: 0 shut, 1 right up. A slat that has reached the lintel has
## gone into the drum, so it stops being drawn.
func set_garage_door(k: float) -> void:
	_door_k = clampf(k, 0.0, 1.0)
	var pitch := DOOR_HIGH / float(DOOR_SLATS)
	for j in range(_door_slats.size()):
		var y := DOOR_HIGH * _door_k + pitch * (float(j) + 0.5)
		_door_slats[j].position.y = y
		_door_slats[j].visible = y + pitch * 0.46 <= DOOR_HIGH + 0.02


func garage_door_k() -> float:
	return _door_k


## Rolls the door to `k` over `seconds`, with the rattle.
func move_garage_door(k: float, seconds: float) -> void:
	if absf(k - _door_k) < 0.01:
		return
	if sfx != null:
		sfx.play_group("clunk")
	var from := _door_k
	await _tween_over(seconds, func(t: float) -> void: set_garage_door(lerpf(from, k, t)))


## Instances a GLB, faces it, and drops it so its lowest point sits on `y`.
## Measuring the instance is the only robust way: the fleet puts an origin on the
## ground under the centre, Synty props do not, and a prop that floats a hand's
## width over the grass is the first thing an art critic writes down.
func _place(path: String, node_name: String, at: Vector3, yaw_deg: float, y: float = 0.0) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var packed := ResourceLoader.load(path) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate() as Node3D
	if inst == null:
		return null
	inst.name = node_name
	add_child(inst)
	inst.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), at)
	var box := _world_box(inst)
	if box.size != Vector3.ZERO:
		inst.global_position.y += y - box.position.y
	return inst


## Every mesh in a node, merged, in world space.
func _world_box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var b := mi.global_transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return AABB() if first else box


# --- The machines and the tools --------------------------------------------------------------

func _build_machines() -> void:
	for kind: String in ["SkidSteer", "DumpTruck", "ConcreteTruck"]:
		var m := Machine.new()
		m.name = kind
		m.kind = kind
		add_child(m)
		m.setup(config)
		# Every machine asks the job what it is standing on, every frame of every
		# move, so none of them has to remember to. It is the RIDE height, not the
		# ground: a machine crossing the broken-out slab climbs over the lumps.
		m.ground = _ground_y
		# Off-stage, up the street, facing back down it.
		m.place(OFF_STAGE, 90.0)
		m.visible = false
		machines[kind] = m
		# The skid steer comes with the PUSH BLADE on (DESIGN 2c): the job is
		# shoving nine metres of broken slab, which a bucket is the wrong tool for.
		if kind == "SkidSteer":
			m.fit_blade()
		# And the mixer with an EXTENSION CHUTE clipped on (DESIGN 2a): from the
		# road, the main chute reaches nothing; with the extension it reaches the
		# kerb end of the form.
		if kind == "ConcreteTruck":
			m.fit_chute_extension()


func machine(kind: String) -> Machine:
	return machines.get(kind) as Machine


## Where a machine stands to work, and which way it faces. Every one of them
## faces +Z - down the drive toward the street - so the two trucks have REVERSED
## up it and pull forward as they work, which is how both jobs are really done
## and keeps their wheels off what they have just laid.
func _work_pose(kind: String) -> Array:
	match kind:
		"SkidSteer":
			# INSIDE THE GARAGE, nose toward the street, lined up on the first
			# column it will push. The whole nine metres of a column goes out in one
			# pass from here, which is why the garage had to become a building with a
			# door in it rather than a sealed lump of mesh.
			return [Vector3(drive.lane_drive_x(1), 0.0, Driveway.Z_APRON - 1.7), 0.0]
		"DumpTruck":
			# Backed the length of the drive, tailgate over the far end, so the
			# base is laid from the garage down as the truck pulls out.
			#
			# 3.9 and not 3.04: at 3.04 its rearmost axle sat 0.46 m PAST the apron,
			# on the ramp out of the excavation, so the truck rode 15 cm high with
			# daylight under its front wheels. Every machine is seated at its nose and
			# its tail now, which is what made that visible.
			return [_on_pad(Driveway.Z_APRON + 3.9), 0.0]
		_:
			# THE MIXER STAYS ON THE ROAD (DESIGN 2a, 2026-09-14): tail to the
			# drive, rearmost tyre just past the kerb, so its spout (4.5 m behind
			# it, measured) hangs over the kerb end of the form and no wheel ever
			# touches the steel the child has just laid. It creeps forward along
			# the road as it pours; the come-along brings the rest up the form.
			# In the MIDDLE of its creep along the road (`road_creep`), not at the
			# kerb end of it: UP takes the pour up the drive by creeping the truck
			# back toward the kerb, and a truck already at the kerb had nowhere to
			# go - the pad was dead until DOWN had been pressed (the improvement
			# plan's 2.1). `mixer_stand_z` is still the kerb end, the closest it
			# may come, and its rear tyre stays on the road throughout.
			return [Vector3(Driveway.CENTRE_X, 0.0, MIXER_STAND_Z + config.road_creep * 0.5), 0.0]


## A spot on the pad, at the height whatever is currently in the excavation puts
## a machine at - bare dirt, the gravel base, or the old slab before it comes
## out. A machine parked at grade over a 0.2 m hole has daylight under its wheels.
func _on_pad(z: float) -> Vector3:
	var at := Vector3(Driveway.CENTRE_X, 0.0, z)
	at.y = drive.stand_y(at) if drive != null else 0.0
	return at


## Where the mixer's origin stands to pour, in world z: the verbs clamp its
## creep from here.
func mixer_stand_z() -> float:
	return MIXER_STAND_Z


## Where the come-along's work is right now: the front of the concrete, with
## the chute's band worked out the way the verb works it out. The pre-beat
## ring, the posed rake and the live hint all stand on this one point.
func rake_hint() -> Vector3:
	var band := -INF
	var mx := machine("ConcreteTruck")
	if mx != null:
		var reach := mx.global_position.z - mx.pour_point_world(Driveway.GRADE).z
		band = mixer_stand_z() - reach - 0.45
	return drive.rake_front_world(config.rake_reach, band)


func _park_machine(kind: String) -> void:
	var m := machine(kind)
	if m == null:
		return
	var pose := _work_pose(kind)
	m.visible = true
	m.place(pose[0], pose[1])
	# Parked: its beacon is dark until a verb puts it to work (4.5).
	m.set_beacon_on(false)
	m.global_position.y = _ground_y(m.global_position)
	if kind == "DumpTruck":
		m.set_load(1.0)
	if kind == "SkidSteer":
		set_garage_door(1.0)
	if kind == "ConcreteTruck":
		m.set_chute(0.0, config.chute_fold_max)


## A truck posed where it waits in the road to be backed in (1.8), turned the way
## the reverse leg starts, engine and beacon on as play leaves them.
func _stage_at_street(kind: String) -> void:
	var m := machine(kind)
	if m == null:
		return
	m.visible = true
	var stop := street_stop(kind)
	var path := back_route(kind, stop)
	var yaw := STREET_YAW
	if path.size() >= 2:
		var dir := path[1] - path[0]
		dir.y = 0.0
		if dir.length_squared() > 0.0001:
			yaw = rad_to_deg(atan2(-dir.x, -dir.z))
	m.place(stop, yaw)
	m.global_position.y = _ground_y(m.global_position)
	m.set_beacon_on(true)
	if kind == "DumpTruck":
		m.set_load(1.0)


## A path through a list of corners, with every corner ROUNDED so a machine's
## nose can be read off it. Each corner becomes a quadratic Bezier, which is the
## cheapest curve whose tangent is never ambiguous.
## `corners` is a plain `Array` and not an `Array[Vector3]` on purpose: the verbs
## reach this through `runner.level`, which is a Variant, and a typed-array
## parameter refuses an untyped literal coming in that way ("the array of argument
## 2 does not have the same element type").
func _route(corners: Array, radius: float = 2.4) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for c in corners:
		pts.append(c as Vector3)
	if pts.size() < 3:
		return pts
	var out: Array[Vector3] = [pts[0]]
	for i in range(1, pts.size() - 1):
		var a: Vector3 = pts[i - 1]
		var b: Vector3 = pts[i]
		var c: Vector3 = pts[i + 1]
		var r := minf(radius, minf(a.distance_to(b), b.distance_to(c)) * 0.49)
		if r < 0.05:
			out.append(b)
			continue
		var from := b + (a - b).normalized() * r
		var to := b + (c - b).normalized() * r
		out.append(from)
		for step in range(1, CORNER_STEPS):
			var t := float(step) / float(CORNER_STEPS)
			out.append(from.lerp(b, t).lerp(b.lerp(to, t), t))
		out.append(to)
	out.append(pts[pts.size() - 1])
	return out


## Drives a machine along a route and returns when it is there.
##
## It POINTS ITSELF THE WAY IT IS ABOUT TO GO first, on the spot, whenever that is
## more than a few degrees off: a vehicle that swaps its heading on the first
## frame of a journey reads as a toy being picked up and put down the other way
## round, which is most of what "the vehicles just float" was about.
func drive_route(m: Machine, corners: Array, seconds: float,
		reverse: bool = false, radius: float = 2.4) -> void:
	var path := _route(corners, radius)
	if path.size() < 2:
		return
	var dir := path[1] - path[0]
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		var facing := -dir if reverse else dir
		var want := rad_to_deg(atan2(facing.x, facing.z))
		var off := absf(wrapf(want - rad_to_deg(m.rotation.y), -180.0, 180.0))
		if off > 12.0:
			m.spin_to(want, config.spin_time * clampf(off / 90.0, 0.35, 1.5))
			await m.arrived
	m.follow(path, seconds, reverse)
	await m.arrived


## Brings a machine on. Both trucks REVERSE up the drive - down the street past
## the entrance, then back in, tail first - because that is how a tipper and a
## mixer really get onto a residential job and because it keeps their wheels off
## what they are about to lay. Since the plan's fifth session this brings a
## truck as far as the road only: backing it in is the child's (`back_route`).
## The skid steer drives in forward and turns round on the spot inside the
## garage, which is the one thing only a skid steer can do, all on its own.
func bring_machine(kind: String, seconds: float) -> void:
	var m := machine(kind)
	if m == null:
		return
	var pose := _work_pose(kind)
	m.visible = true
	m.place(OFF_STAGE, STREET_YAW)
	# A tipper turns up with something in it. It has to be loaded BEFORE it is
	# seen, which is here and not when the tipping starts.
	if kind == "DumpTruck":
		m.set_load(1.0)
	sfx.play_group("drive")
	sfx.play_loop(SiteVerbs.SOUND_IDLE, "arrive")
	# Its beacon turns from the street to the stop, with the engine (4.5).
	m.set_beacon_on(true)
	rig.go(CameraRig.STREET, null)
	if kind == "SkidSteer":
		# The door goes up before the machine gets there, because a crew opens the
		# garage before it needs it and because a door that opens under a machine
		# already standing in the opening is a door nobody saw open.
		move_garage_door(1.0, config.door_time)
		var x: float = Vector3(pose[0]).x
		# Bucket carried HIGH for the run up the drive: it is crossing broken
		# concrete, and `_ground_y` has it climb over the lumps rather than through
		# them - which is exactly what the user saw it fail to do.
		m.set_bucket(1.0, 0.30)
		await drive_route(m, [OFF_STAGE, Vector3(x + 2.6, 0.0, STREET_Z),
			Vector3(x, 0.0, Driveway.Z_KERB + 1.6), Vector3(pose[0])], seconds, false, 2.2)
		m.spin_to(float(pose[1]), config.spin_time * 1.6)
		await m.arrived
		finish_arrival(kind)
		return
	# A TRUCK comes past the drive and STOPS in the road, tail to it, lined up on
	# the way it will back in - engine ticking over, beacon turning - and waits
	# for the child to back it in (`SiteVerbs.back_dump`/`back_mixer`: the
	# improvement plan's 1.8, decision 4). It used to back straight in on its
	# own, beeping; the reverse is the child's hold now, and so is the beeper.
	await drive_route(m, [OFF_STAGE, street_stop(kind)], config.street_time, false, 2.4)
	await face_route(m, back_route(kind, m.global_position), true)


## Where a truck stops in the road to wait for the child to back it in.
func street_stop(_kind: String) -> Vector3:
	return Vector3(Driveway.CENTRE_X - 7.0, 0.0, STREET_Z)


## The reverse leg from `from` to where the truck works, its corners rounded
## (the same corners and radii both trucks always backed in on). The mixer
## swings its tail to the kerb and never leaves the road (DESIGN 2a); the
## tipper backs the length of the drive.
func back_route(kind: String, from: Vector3) -> Array[Vector3]:
	var cx := Driveway.CENTRE_X
	var pose := _work_pose(kind)
	if kind == "ConcreteTruck":
		return _route([from, Vector3(cx, 0.0, STREET_Z + 3.6), Vector3(pose[0])], 2.6)
	return _route([from, Vector3(cx, 0.0, STREET_Z - 0.8), Vector3(pose[0])], 2.8)


## Turns a machine on the spot to face the start of a path before it drives it,
## when it is more than a degree off: the first held frame of a backing truck
## must not snap its yaw (the mixer's corner starts 27 degrees round).
func face_route(m: Machine, path: Array[Vector3], reverse: bool) -> void:
	if m == null or path.size() < 2:
		return
	var dir := path[1] - path[0]
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	var facing := -dir if reverse else dir
	var want := rad_to_deg(atan2(facing.x, facing.z))
	var off := absf(wrapf(want - rad_to_deg(m.rotation.y), -180.0, 180.0))
	if off > 1.0:
		m.spin_to(want, config.spin_time * clampf(off / 90.0, 0.2, 1.5))
		await m.arrived


## The end of an arrival: the engine off, the beacon dark, and the stop - a
## truck's air brakes, the skid steer's old clunk (it has none).
func finish_arrival(kind: String) -> void:
	var m := machine(kind)
	sfx.stop_loop("arrive")
	if m != null:
		m.set_beacon_on(false)
	sfx.play_group("clunk" if kind == "SkidSteer" else "hiss")


## Where the gold ring and the white mime stand while a truck waits to be backed
## in, and follow it while it rolls: the tipper's tailgate - the place the tip's
## own ring stands, so the child touches the same spot twice - and the mixer's
## tail.
func arrival_hint(kind: String) -> Vector3:
	var m := machine(kind)
	if m == null:
		return Vector3.INF
	if kind == "DumpTruck":
		var tail := m.marker(String(WORKING_END.get(kind, "")))
		if tail != null:
			return tail.global_position
	return m.to_global(Vector3(0.0, 1.4, -(m.rear_overhang() + 0.4)))


## Is a screen point on the truck this back-in beat brings? Its box, grown by
## half a finger's reach but never by more than `tap_reach_m` of world at the
## truck, and never less than a finger: the tap-on-target rule, which the honk's
## plain half-reach (a metre and a half of road from the STREET eye) was not.
func on_backing_truck(at: Vector2) -> bool:
	var s := runner.current_step() if runner != null else null
	if s == null or not SiteVerbs.BACK_VERBS.has(s.verb):
		return false
	return _on_truck(machine(String(SiteVerbs.BACK_VERBS[s.verb])), at)


## Is a screen point on this machine by the tap-on-target rule: its box grown by
## half a finger's reach, capped at `tap_reach_m` of world, floored at a finger?
func _on_truck(m: Machine, at: Vector2) -> bool:
	if m == null or not m.visible or camera == null or hud == null:
		return false
	var frame := get_viewport().get_visible_rect().size
	var box := _world_box(m)
	var mid := hud.project_into(frame, box.get_center())
	if mid.z <= 0.0:
		return false
	var grow := clampf(config.tap_reach_m * hud.pixels_per_metre(frame, mid.z), _finger_px(), _reach_px() * 0.5)
	return _box_under(m, at, grow)


## Sends it away again: forward out of the drive and off up the street the way it
## came, which is the whole reason for reversing in.
func send_machine(kind: String, seconds: float) -> void:
	var m := machine(kind)
	if m == null:
		return
	# No camera move of its own: the leave step's shot is the WIDE already, and
	# the exit now runs on in the BACKGROUND under the next beat (the plan's
	# 3.2), whose shot this must not fight.
	sfx.play_loop(SiteVerbs.SOUND_IDLE, "leave")
	# Its beacon turns until it is gone (4.5).
	m.set_beacon_on(true)
	# The idle dies away up the street rather than droning at one level under
	# the child's next beat and then stopping dead: the exit runs in the
	# background now, out of the picture.
	var leaving: AudioStreamPlayer = sfx.loop_player("leave")
	if leaving != null:
		var tw := create_tween()
		tw.tween_property(leaving, "volume_db", leaving.volume_db - 18.0, seconds)
	if kind == "SkidSteer":
		m.set_bucket(1.0, 0.0)
	if kind == "ConcreteTruck":
		# Already on the road, nose to the far kerb: forward into the far lane
		# and round to the right, up the street.
		await drive_route(m, [m.global_position, Vector3(Driveway.CENTRE_X + 0.6, 0.0, STREET_Z + 4.0),
			Vector3(9.0, 0.0, STREET_Z + 3.4), Vector3(13.0, 0.0, STREET_Z), OFF_STAGE],
			seconds, false, 3.0)
	elif kind == "SkidSteer":
		# From the heap, down the VERGE to the street - never back through the
		# mouth of the excavation it just cleared: with the exit in the
		# background the eye is on the forms by then, and a wheel dipping into
		# the hole through the far board's end was in the frame.
		var verge_x := maxf(m.global_position.x, Driveway.CENTRE_X + Driveway.WIDTH * 0.5 + 1.6)
		await drive_route(m, [m.global_position, Vector3(verge_x, 0.0, STREET_Z + 0.3),
			Vector3(10.0, 0.0, STREET_Z), OFF_STAGE], seconds, false, 2.6)
	else:
		# The tipper: straight down the drive it has just laid, then up the street.
		await drive_route(m, [m.global_position, Vector3(Driveway.CENTRE_X, 0.0, STREET_Z + 0.3),
			Vector3(10.0, 0.0, STREET_Z), OFF_STAGE], seconds, false, 2.6)
	sfx.stop_loop("leave")
	m.set_beacon_on(false)
	m.visible = false


func _build_tools() -> void:
	for kind: String in TOOL_REST:
		var t := HandTool.new()
		t.name = kind.capitalize()
		t.kind = kind
		add_child(t)
		t.setup(config, sfx)
		t.visible = false
		tools[kind] = t
	_rest_tools()


## Every tool back on the grass, lying where it belongs, out of the picture.
func _rest_tools() -> void:
	for kind: String in tools:
		var t := tools[kind] as HandTool
		t.hover_instant(TOOL_REST[kind], Vector3.FORWARD, Vector3.UP)


## The one tool the current step wants is out; every other one is away. A tool
## left hanging in the picture for a beat that does not use it is the fault Car
## Garage's round 2 filed against a wrench floating over an empty bay.
func present_tool(want: String, instant: bool = false) -> void:
	# Past the job's last tool row (the cure, the strip), nothing is put away at
	# a step: the broom stays lying on the grass where it went back, and goes
	# with the rest of the kit at the cut to the street (`_clear_kit`). Hiding it
	# as the cure row opened blinked it out on the wide (the verification pass).
	var keep := ""
	if (want == "" or want == "none") and _past_last_tool():
		keep = _last_tool()
	for kind: String in tools:
		if kind == keep:
			continue
		var t := tools[kind] as HandTool
		if kind != want:
			t.visible = false
	if want == "" or want == "none" or not tools.has(want):
		return
	var t := tools[want] as HandTool
	t.visible = true
	if instant:
		t.hover_instant(TOOL_REST[want], Vector3.FORWARD, Vector3.UP)


## The tool of the job's last row that uses one ("" when none does).
func _last_tool() -> String:
	if job == null:
		return ""
	for i in range(job.steps.size() - 1, -1, -1):
		if job.steps[i].tool != "" and job.steps[i].tool != "none":
			return job.steps[i].tool
	return ""


## Is the runner past the last row of the job that uses a tool?
func _past_last_tool() -> bool:
	if job == null or runner == null:
		return false
	var last := -1
	for i in range(job.steps.size()):
		if job.steps[i].tool != "" and job.steps[i].tool != "none":
			last = i
	return last >= 0 and runner.index > last


func tool_node(want: String) -> HandTool:
	return tools.get(want) as HandTool


# --- The shots ------------------------------------------------------------------------------

## Every shot the job names (DESIGN 1a). The anchored ones use `*`, which the
## runner resolves to whatever the current step is working on, so one `PANEL`
## shot frames all six panels and one `MACHINE` shot all three machines.
func _define_shots() -> void:
	# Closer than it was (19.5 m off, with the driveway 2.3% of the frame and the
	# call button twice that - round 3). The child comes back to this picture
	# between every phase, and it has to show the STATE OF THE JOB: the drive
	# fills the middle third, the house and the garage still frame it.
	# The drive is the subject: closer and lower again, the look point on the
	# drive's own middle, so the pad runs the frame's diagonal and the empty
	# foreground grass falls out of the bottom (round 7: 40% lawn, 8% drive).
	# LOWER, with a horizon: the wides were steep top-down diorama shots, 42-49%
	# lawn and under 1% sky, and the pictures that breathed were the working-eye
	# ones (round 10). From 3 m the house, the garage and the street all stand
	# up, the sky is a seventh of the frame, and the drive is still the subject.
	rig.define(CameraRig.WIDE, "", Vector3(-1.8, 3.0, 8.4), Vector3(2.6, 0.3, 0.6), 3.0, 26.0)
	# ONE SPOT on a panel, not the whole panel. The phase is three bites per slab
	# in three different places now, so the picture has to be close enough that a
	# child can tell WHICH third of the slab the arrow is on - and close enough
	# that a breaker the size of a real breaker fills its share of the frame. "Jack
	# hammer too small. It either needs to be bigger or appear bigger via camera
	# perspective" - it is both: the tool grew and the camera came in.
	# The WHOLE slab, not one spot on it: all three gold rings are live at once and
	# the child may take them in any order, so all three have to be in the picture.
	# It ORBITS, slowly - "the camera should move around during things like jack
	# hammer vs staying stationary" - which also means a ring that is edge-on to
	# one side of the swing is square-on a moment later.
	# Nearer the drive's own line: 1.9 m out gave a third of the picture to
	# an empty green rectangle on the left (round 13, 43% lawn).
	rig.define(CameraRig.PANEL, "*", Vector3(-0.9, 2.35, 2.45), Vector3(0.45, -0.04, 0.05),
		9.0, 11.0, 0.30)
	# THE PUSH: low and close on the BLADE, from the street side and a little
	# ahead of it, so the picture is the board with the rubble piling against it
	# and the machine behind - and it rides with the blade down the drive. It was
	# 9.6 m off and 4 m up, and from there the bucket was a yellow line under the
	# cab (round 3: the child could not see the thing doing the work).
	# Ahead of the blade and to its left, low: the rubble it is shoving fills the
	# middle of the picture, the machine stands behind it, the garage behind
	# that. Round 4 measured the old framing at 52% lawn.
	rig.define(CameraRig.MACHINE, "*", Vector3(-2.0, 2.0, 3.2), Vector3(0.55, 0.2, -0.6),
		4.0, 17.0, 0.35)
	# THE TIP, close on the tailgate the stone is coming out of and low enough to
	# watch it land ("the dump truck needs a pour animation"). Anchored to the
	# machine's working end, so it rides forward with the truck as the load is
	# laid behind it. `MACHINE` stayed nine metres off because it is shared with
	# the skid steer's push, which needs the whole column of rubble in frame.
	# Back from 3.2 m to 5.6, and lower: at 3.2 the raised bed filled the whole
	# frame and the stone landing on the base - the thing the beat is about - was
	# under the bottom edge of the picture (round 3).
	# BESIDE the tailgate, not behind it: behind it is inside the garage (the
	# truck's tail starts a metre from the door), and the first reframe put the
	# eye in the roof. From the left of the truck's rear, low, looking across the
	# curtain of stone at the base being laid under it.
	# Square to the tailgate's width from behind and a little left, low: the
	# curtain falls across the picture and the base being laid is under it.
	# Beside the truck (round 4) the bed hid four fifths of the lip (round 5).
	# BELOW the bed's rail (the anchor is the tailgate, 2.2 m up), square
	# behind it, so the curtain falls against the earth and not against the
	# truck's own chassis (round 7).
	# From the rear QUARTER, not square behind: square behind and below, the
	# whole curtain projected onto the truck's chassis and the tipper read as
	# encrusted (round 12). From the quarter the stone falls between the eye
	# and the open earth.
	# From ABOVE and behind the tailgate since round 13: from the quarter 85%
	# of the falling stone lay over the chassis. Looking down, the curtain
	# falls against the earth it is laying, the truck along the top.
	# From the truck's SIDE, rear quarter, high enough to see over the form:
	# the bed up, the tailgate, the stone falling onto the base - nothing of
	# the truck between the eye and the tip (the fourth playtest: "pick a
	# camera angle that isn't blocked when you dump rock").
	rig.define(CameraRig.TIPPER, "*", Vector3(-4.4, 2.1, -1.0), Vector3(0.5, -2.0, 0.3),
		4.0, 14.0, 0.15)
	# The whole pad for both of these, because both are worked ALL ROUND it and the
	# child may take the places in any order: four rings on the boards' homes, ten
	# on the stakes' heads, every one of them tappable.
	#
	# This is the answer to "still a lot of camera shots where I can't see where I
	# am supposed to click - example on the stakes". A close shot on the one stake
	# the job had decided was next could show the peg perfectly and still not tell
	# a child there were nine others. The rings keep their size on screen however
	# far the camera is, so framing the work no longer costs the target.
	# ACROSS the form from the lawn, on the group of boards being set (round 4:
	# "the last phase watched from across the street"): the near board a stride
	# away, the far one across the hole, the drive running out of the picture.
	# DIAGONAL: from the kerb-side corner looking up the drive, so the boards
	# run from the near corner to the far one instead of lying along the top
	# and bottom edges of a frame of flat brown (round 6).
	# From the near board's own lawn, low, looking ACROSS the drive: a board
	# framed along its length is an 8 cm edge, a 5 px stick (round 11); from
	# the side the near board shows its face across the lower frame and the
	# far one beyond. For the kerb board and the strip, which lie across the
	# drive, the same offsets stand on the road and in the drive, face-on.
	rig.define(CameraRig.FORM, "*", Vector3(-3.0, 1.5, 2.2), Vector3(0.3, -0.5, -0.2),
		5.0, 19.0, 0.3)
	# RIGHT DOWN ON THE PAIR being driven, and the eye steps down the drive as
	# each pair goes in ("the stakes are a wide shot so you don't get the hammer
	# feeling"). Anchored to the group's own mark, so these numbers frame the
	# pair at the garage end and the pair at the kerb alike; the rings light that
	# group only, so nothing off the picture is asking to be tapped.
	# A little further back than it was (2.25 m): with no stakes on the apron
	# strip the first pair stands the full width of the form apart, and the old
	# framing cropped the left one.
	# The same picture for the pair of pegs: across the form from the lawn, the
	# near peg big, the far one across the hole - rather than both at the two
	# edges of the frame with a field of dirt between them (round 4).
	# From the corner: the near peg big in the lower left, the far one across
	# the hole, the board between them running diagonally out of the frame.
	# Close on a PAIR of pegs ALONG one board, from that board's lawn, the near
	# peg big at the lower right and the far one up the board (round 10: a pair
	# across the form was framed on the gap between them, half the frame lawn).
	# Mirrored for the far board (`flip_x` on its group mark).
	rig.define(CameraRig.STAKE, "*", Vector3(-1.1, 1.3, 1.9), Vector3(1.0, -0.5, -0.3),
		7.0, 13.0, 0.22)
	# THE STEEL (DESIGN 2d): on the group being laid - the four long bars, then
	# each pair of cross bars - close enough to see the chairs under them, and
	# it steps down the drive with the pairs the way the stakes do.
	# Low, along the bars: from down here the chairs have legs and the steel has
	# air under it, which is the whole lesson (round 5).
	# ...and from the unlaid side, close and a little above the pair, so the two
	# bars being laid are the BIGGEST thing in the picture and span it, the
	# chairs under them, the laid steel beyond (round 10: from down the drive
	# the pair being worked was the smallest thing in the frame).
	rig.define(CameraRig.BARS, "*", Vector3(-0.6, 1.25, 1.7), Vector3(0.1, -0.3, -0.25),
		7.0, 13.0, 0.2)
	# THE POUR (DESIGN 2a), and the user's own visual trick: "detach the chute from
	# the truck and move the camera right up to it, so the player feels like they
	# are pouring the cement and we don't have the truck in the way visually."
	#
	# The truck is still there and still driving - `Machine.show_only(["Chute"])`
	# simply stops drawing everything that is not the chute - and the camera sits
	# just off the spout. It is anchored to `PourView`, a marker that follows the
	# pour DOWN THE DRIVE but never sideways and never turns, so:
	#   * the chute's swing is fully legible, because the camera does not swing,
	#   * driving the truck is legible too, because the form boards run down both
	#     sides of the frame and slide past.
	# Anchoring it to `ChutePour` itself - the round-1 fix - was exactly wrong: eye
	# and look are both offsets from one anchor, so the basis never changes and
	# everything bolted to the chute lands on the same pixels forever. Both pads
	# read backwards. Anchor to the thing that stays put while the world moves.
	# RIGHT UP BY THE BACK OF THE CHUTE, on the truck's side of it, looking along it
	# at the spout and the form beyond: "camera should be right up by the back of
	# the chute so that we don't know as the player that it's been detached".
	#
	# The chute's own pivot stands 1.26 m toward the street from the spout and
	# 1.37 m above it, so an eye 2.35 m back and 2.35 m up sits just behind and
	# over its head - and the truck, 4.5 m back, is behind the camera and out of
	# the picture entirely. Nothing to notice is missing.
	#
	# It does NOT drift. Every other shot orbits; this one is the only beat steered
	# with the pads, and the camera is what decides which way "left" means.
	# THE POUR, from the eye of the man on the chute (the user, 2026-09-12, with
	# two reference clips: "imagine the camera at the eye level of the man holding
	# the chute and the chute angled in a way where he controls the pour then the
	# player has to pour it in the forms"). 1.62 m is a standing adult's eye; the
	# shot stands at the chute's near side, looks down its length at about 27
	# degrees, and holds the form it is filling in the bottom two thirds of the
	# picture. It was a 2.9 m crane shot looking down on the chute from behind -
	# the pour read as a machine part hanging in the air rather than as something
	# in the child's hands.
	# ABOVE the chute's rim and nearer its line, looking down INTO the trough
	# at the concrete running down it and off the end: from below and beside it
	# (1.74 m, with the pivot at 1.84) the child saw the chute's charcoal belly
	# and nothing inside it (round 10).
	# Higher and nearer since round 12, so it looks INTO the extension's trough
	# at the mud running down it, not at its outer wall.
	# BESIDE the chute's line since round 14, above the rim and ahead of the
	# pivot: from above the rim the stream fell behind the trough's own near
	# wall and the child watched an empty gutter. From here the stream falls
	# off the lip in front of the trough into the crest (five candidates
	# rendered side by side).
	rig.define(CameraRig.CHUTE, "PourView", Vector3(-2.2, 3.0, 2.6), Vector3(0.3, -0.8, -0.9))
	# The finishing. The hose and the broom are DRAGGED over the slab by hand now,
	# so this shot has one job it did not have before: hold the WHOLE slab, or a
	# child cannot reach the end they have not done yet. Up the drive from the kerb
	# end, high enough for all nine metres and close enough that the brush marks
	# nearest the camera are crisp.
	# THE SCREED walks with the board (DESIGN 1a): from the kerb side of it, a
	# little to the left, low enough that the board is a board and the lumps in
	# front of it are lumps. Anchored to `ScreedView`, which the verb moves down
	# the drive with the board. It does not orbit - it is already moving.
	# LOW - 1.1 m, a kneeling eye - so the roll of surplus ahead of the board
	# has a silhouette against the struck plane beyond it, which from 1.9 m up
	# it never had (rounds 4, 5, 6).
	rig.define(CameraRig.SURFACE, "ScreedView", Vector3(-2.0, 1.1, 2.4), Vector3(0.1, -0.15, -0.9))
	# THE COME-ALONG (DESIGN 2a): from the garage door, head height, looking down
	# the drive at the street - the concrete comes UP the form toward the child,
	# which is what pulling is. No orbit: a drag beat, and a moving camera moves
	# the ground under the finger.
	# Anchored to `RakeView`, which HOPS down the drive behind the concrete's
	# front between strokes (never while the finger is down), so the come-along
	# is in the child's hands rather than ninety pixels wide at the top of the
	# frame (round 5).
	rig.define(CameraRig.PULL, "RakeView", Vector3(-0.95, 2.1, -0.55), Vector3(0.35, -0.75, 3.4))
	# THE HOSE AND THE BROOM, from where the person doing it stands (the user:
	# "spraying water for example it looks tiny instead of having the camera
	# behind the water sprayer like you are the one spraying"). Down at the kerb
	# end of the drive at head height, looking up it - so the slab runs away from
	# the child and the tool is in the near corner of the picture, big.
	#
	# Not lower: the far end of the slab has to stay well below the horizon or a
	# finger cannot reach it (`work_point` drops the finger onto the slab's plane,
	# and near the horizon a pixel is worth metres). And it does not orbit, for
	# the same reason `SURFACE` does not: a moving camera moves the ground under
	# the finger.
	rig.define(CameraRig.HAND, "Slab", Vector3(-1.05, 2.60, 5.95), Vector3(0.0, 0.0, -2.05))
	# The broom from the OTHER side of the drive, a little lower: the hose and
	# the broom were the same photograph (round 9).
	# ...and from the SIDE of the drive since round 11: a broom finish is
	# pulled ACROSS the slab toward the one holding it, so the marks run
	# across the drive, square to the head, the way a crew leaves them.
	# ...and per BAY since the fourth playtest: beside the square being
	# brushed, square to the drive, so a stroke up and down the picture is a
	# stroke across the drive, parallel to the joints.
	rig.define(CameraRig.BROOM, "*", Vector3(-3.6, 2.3, 0.0), Vector3(0.5, -0.2, 0.0))
	# A joint runs the full 3.6 m ACROSS the drive and the tool travels the whole
	# way: "camera couldn't see all the joints being made". Square on to the line
	# and back far enough to hold both ends of it.
	# Closer than it was (2.55, 2.45, 2.05): the jointer was a matchstick and the
	# groove a line. It still holds both ends of the 3.6 m line - the smoke test
	# projects them through the live camera.
	# Anchored to the JOINTER itself since round 11, so the eye walks along
	# the joint behind the head with the groove running out from under it:
	# framed on the joint's middle, the head was a 35 px speck in the far
	# corner for most of the beat.
	# ...and from BEHIND the sled along the joint's own line, so the frame is
	# the groove running out from under the tool and the slab ahead, not 39%
	# of the far lawn (round 12).
	# ...from BEHIND the sled down the drive (round 12: along the joint's own
	# line the far lawn was 40% of every frame): the sled 2 m ahead with the
	# groove running through it, the garage beyond, the handle to the hands.
	# ...and since the fourth playtest the joint is PULLED across by the finger,
	# so the eye stands still on the JOINT'S OWN MIDDLE, behind it down the
	# drive, holding the whole width: a camera riding the sled would move the
	# ground under the dragging finger.
	rig.define(CameraRig.JOINT, "*", Vector3(0.0, 1.7, 2.8), Vector3(0.0, -0.45, -0.7))
	rig.define(CameraRig.STREET, "", Vector3(-6.4, 5.4, 17.2), Vector3(3.0, 0.6, 7.4))
	# THE PLATE COMPACTOR (the plan's 5.1): low, standing beyond the kerb edge of
	# the bay being packed, looking up the drive toward the garage - so the bays
	# already packed lie BEYOND the one being worked (before and after in one
	# picture, like the screed's flat behind and lumpy in front), and the cut
	# into the steel's first eye needs no half-turn. Anchored to the bay's own
	# marker; still under the finger, stepping to the next bay between beats.
	# From a little LEFT of the bay's line and tipped down onto it (four
	# candidates rendered): square behind, the plate was its own handle's end
	# and a garage filled the top half; from the rear quarter it is a machine -
	# plate, engine, orange cowl - with the whole bay under it.
	# ...and anchored to `PlateView`, which walks after the plate between
	# strokes (the verification pass: a still eye per bay left the far row four
	# metres from the hands, past what a handle can stretch).
	rig.define(CameraRig.PLATE, "PlateView", Vector3(-0.8, 1.45, 1.95), Vector3(0.3, -0.8, -0.8))
	# STRIPPING THE FORMS (5.3): from the road off the drive's left kerb corner,
	# high enough to hold both long boards to the garage and the kerb board
	# across the near end - all three rings in one still picture.
	rig.define(CameraRig.STRIP, "Kerb", Vector3(-2.4, 2.2, 3.3), Vector3(0.5, -0.5, -3.4))
	# The reward deserves its own picture. Without it the payoff was the eighth
	# time the child had seen the WIDE frame, with the car 130 px wide against a
	# white garage door: down at a child's height instead, on the car's wheels
	# standing on the new slab with the broom lines running under them.
	# Anchored to the CAR itself since round 12 - the shot was within a point
	# of the wide (the car 3% of the frame, the lawn 40%). Down at a child's
	# height at its rear quarter, the car on the new slab filling the frame.
	# SIDE-ON since round 14: from the rear quarter the hatch's interior stood
	# against the sky as a tan box and a black one.
	# PULLED BACK since the fourth playtest ("need a better shot zoomed out to
	# see finished work like we had previously"): the whole new drive from the
	# kerb corner - both joints, the car on it, the garage and the house.
	rig.define(CameraRig.PAYOFF, "Slab", Vector3(-5.8, 3.2, 7.0), Vector3(0.4, 0.3, -1.6))


# --- Input ------------------------------------------------------------------------------------

## Every tap. `ToyHud` has already drawn the ring and taken any press that landed
## on a steering pad, so what reaches here is a finger on the PICTURE.
func _unhandled_input(event: InputEvent) -> void:
	if runner == null:
		return
	if runner.finished:
		# The payoff: nothing is the work, but a miss is never silent. A press
		# on the car it has watched drive in toots it; a press anywhere else
		# while NEXT is up kicks NEXT and hurries the white mime toward it.
		_payoff_press(event)
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_fingers[t.index] = t.position
			# ONE finger owns the beat: a second one landing while it is down is
			# not a press. It has its white ring already.
			if _finger >= 0 and t.index != _finger:
				return
			_touch_at = t.position
			_touch_down = true
			if _press(t.position, true):
				_finger = t.index
		else:
			_fingers.erase(t.index)
			# A bystander lifting - a palm, a thumb - is nothing to the beat.
			if _finger >= 0 and t.index != _finger:
				return
			_finger = -1
			_touch_at = t.position
			_touch_down = false
			_press(t.position, false)
	elif event is InputEventScreenDrag:
		# The finger MOVING matters now, not only the finger landing: the hose and
		# the broom are worked by dragging them over the slab. Only the finger
		# that owns the beat moves it.
		var d := event as InputEventScreenDrag
		_fingers[d.index] = d.position
		if _finger >= 0 and d.index != _finger:
			return
		_touch_at = d.position
		_drag_woke(_touch_at)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Fingers arrive as real touches above; skip the mouse Godot fakes.
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.device != InputEvent.DEVICE_ID_EMULATION:
			_touch_at = mb.position
			_touch_down = mb.pressed
			_press(mb.position, mb.pressed)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mm.device != InputEvent.DEVICE_ID_EMULATION:
			_touch_at = mm.position
			if _touch_down:
				_drag_woke(mm.position)
	elif Pad.go_event(event):
		_woke()
		_end_opening()
		# A controller or the keyboard has no pointer, so GO always counts.
		if runner.waiting_button() != "":
			hud.simulate_button(runner.waiting_button())
		elif runner.waiting_for_hold():
			runner.hold(true)
		else:
			runner.tap()


## A finger landing (`pressed`) or lifting. Returns whether a landing was
## ACCEPTED as the beat's work - a ring picked, a counted tap, a hold started -
## which is what lets `_unhandled_input` give that finger the beat, and what
## decides the white idle arrow's clock: an accepted press restarts it, a miss
## HURRIES it (the improvement plan's 1.2).
func _press(at: Vector2, pressed: bool) -> bool:
	# Asked BEFORE any wake, which takes the white arrow down: a finger on the
	# wedge that says "tap here" is a finger on what it points at.
	var on_wedge := pressed and hud != null and hud.arrow_hit(at)
	if not pressed:
		# A release after an accepted press is the child doing something; one
		# after a miss is not, and must not undo the hurry.
		if _accepted:
			_woke()
		_accepted = false
		_carry_back = false
		_woke_at = Vector2.INF
		_touch_down = false
		runner.hold(false)
		return false
	_touch_down = true
	# Any touch ends the opening look at the wide.
	_end_opening()
	var s := runner.current_step()
	# A MACHINE beat - one arriving on the child's call, or one leaving on its
	# own: nothing on the picture is the work, so a tap is answered by the thing
	# under it if that thing is a machine, with its horn (the plan's 1.8), and
	# by nothing at all otherwise. GO does not kick while the machine it called
	# is still on its way.
	if s != null and (s.kind == JobStep.Kind.AUTO \
			or (s.kind == JobStep.Kind.BUTTON and runner.is_busy())):
		var m := _machine_under(at)
		if m != null:
			_honk(m)
			# A finger that lands on a truck coming down the street and STAYS
			# there is already the banksman: when the truck stops, the finger
			# still on it backs it in, with no second press (the plan's 1.8).
			# By the same tap-on-target rule as a press on the waiting truck, not
			# the honk's wider grow (the verification pass).
			if s.kind == JobStep.Kind.BUTTON and m == _backed_by_next_row() and _on_truck(m, at):
				_carry_back = true
				return true
		return false
	# A BUTTON step is answered by the button, which is its own Control: a tap on
	# the picture is not a wrong answer, it just is not the answer.
	if runner.waiting_button() != "":
		# NOT silence. The pillar is that a miss is never punished but never
		# ignored either, and a child looking at a truck they can see will tap the
		# truck rather than the button: the button kicks to say "me, here".
		_miss()
		if hud != null:
			hud.nudge_button()
		return false
	# The pour is steered with the pads: a tap on the picture is answered by
	# the pad that would take the concrete to the emptiest cell (the plan's 2.1).
	if s != null and SiteVerbs.PAD_VERBS.has(s.verb):
		_miss()
		if hud != null:
			hud.nudge_pad(_pour_hint_pad())
		return false
	# A beat with rings is answered by pressing ONE of them, and which one is the
	# child's choice.
	if rings_up():
		var reach := _reach_px()
		var world_reach := config.tap_reach_m
		var min_reach := _finger_px()
		_picked = _rings.pick_nearest(camera, at, reach, false, world_reach, min_reach)
		# The white wedge stands over the first live ring: a press on the wedge
		# is a press on that ring (the improvement plan's 0.5).
		if _picked == 0 and on_wedge and _rings.count() > 0:
			_picked = _rings.id_at(0)
		# A form board is nine metres long and has one ring: a tap anywhere ON it
		# is a tap on it (5.3) - the thing under the finger answers.
		if _picked == 0 and s != null and s.verb == "form_strip":
			_picked = _board_under(at, drive.open_strip_forms())
		elif _picked == 0 and s != null and s.verb == "form_set":
			# The same for a board waiting in the air to be set: nine metres of
			# board with one ring in its middle (the verification pass).
			_picked = _board_under(at, drive.open_forms_in(drive.current_form_group()))
		if _picked == 0:
			# A finger on the ring already being worked - a mash - is not a
			# miss; it is simply not another bite.
			if _rings.pick_nearest(camera, at, reach, true, world_reach, min_reach) != 0:
				return false
			# ...and nor is a finger along a board already coming off or going in.
			if s != null and (s.verb == "form_strip" or s.verb == "form_set") \
					and _board_under(at, _taken_boards(), true) != 0:
				return false
			_miss()
			_rings.nudge_nearest(camera, at)
			if hud != null:
				hud.nudge_arrow()
			return false
		# A tap that lands while the last bite is still running is KEPT by the
		# runner. Keep WHICH ring it landed on with it, or the kept bite falls
		# back to the first open spot (the improvement plan's 0.4).
		if runner.is_busy():
			_queued_pick = _picked
			_queued_pick_step = runner.index
		# The ring the finger chose answers in the same frame: it snaps out,
		# and the others stay lit (the plan's 1.3).
		_rings.take(_picked)
		_accept(at)
		if runner.waiting_for_hold():
			runner.hold(true)
		else:
			runner.tap()
		return true
	if not (on_wedge or tap_counts(at)):
		_miss()
		if hud != null:
			hud.nudge_arrow()
		return false
	_accept(at)
	if runner.waiting_for_hold():
		runner.hold(true)
	else:
		runner.tap()
	return true


## A press during the payoff (the runner is finished): the car answers with its
## voice, and anything else while NEXT is up is a miss answered by NEXT.
func _payoff_press(event: InputEvent) -> void:
	var at := Vector2.INF
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		at = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.device != InputEvent.DEVICE_ID_EMULATION:
			at = mb.position
	if at == Vector2.INF or hud == null:
		return
	if car != null and car.visible and _box_under(car, at):
		# Not over itself: the ice-cream van's jingle is two and a half seconds,
		# and a mashing finger started four at once (the verification pass).
		if _now_s() - _honk_at_s >= maxf(HONK_GAP, _car_voice_len) and sfx != null:
			_honk_at_s = _now_s()
			sfx.play_group(car_voice())
			_car_voice_len = float(sfx.last_length)
		return
	if hud.next_visible() and not hud.next_rect().grow(_reach_px() * 0.5).has_point(at):
		_miss()
		hud.nudge_next()


## Is a screen point on this node's box (its world box projected, grown by
## half a finger's reach)?
func _box_under(node: Node3D, at: Vector2, grow: float = -1.0) -> bool:
	if camera == null or hud == null:
		return false
	var by := grow if grow >= 0.0 else _reach_px() * 0.5
	var frame := get_viewport().get_visible_rect().size
	var box := _world_box(node)
	if box.size.length_squared() < 0.01:
		return false
	var rect := Rect2()
	var first := true
	for c in range(8):
		var p := hud.project_into(frame, box.get_endpoint(c))
		if p.z <= 0.0:
			return false
		var sp := Vector2(p.x, p.y)
		rect = Rect2(sp, Vector2.ZERO) if first else rect.expand(sp)
		first = false
	return not first and rect.grow(by).has_point(at)


## The form board still to strip whose top edge runs nearest a screen point,
## within a finger - or `tap_reach_m` of world at the board, if that is more -
## or 0. Measured to the board's LINE, never its box: a long board's box seen
## from the kerb covers half the slab.
func _board_under(at: Vector2, boards: PackedInt32Array, include_taken: bool = false) -> int:
	if drive == null or hud == null:
		return 0
	var frame := get_viewport().get_visible_rect().size
	var best := 0
	var best_d := INF
	for i in boards:
		# A board whose ring is already taken is being worked: a press on it is a
		# mash, never a new pick - it used to overwrite a kept tap on another board.
		if not include_taken and _rings != null and _rings.is_taken(i):
			continue
		var line := drive.form_line_world(i)
		if line.size() < 2:
			continue
		var a := hud.project_into(frame, line[0])
		var b := hud.project_into(frame, line[1])
		if a.z <= 0.0 or b.z <= 0.0:
			continue
		var p := Geometry2D.get_closest_point_to_segment(at, Vector2(a.x, a.y), Vector2(b.x, b.y))
		var depth := lerpf(a.z, b.z, clampf(Vector2(a.x, a.y).distance_to(p) / maxf(Vector2(a.x, a.y).distance_to(Vector2(b.x, b.y)), 1.0), 0.0, 1.0))
		var reach := maxf(_finger_px(), minf(config.tap_reach_m * hud.pixels_per_metre(frame, depth), _reach_px()))
		var d := p.distance_to(at)
		if d <= reach and d < best_d:
			best_d = d
			best = i
	return best


## The boards whose rings are taken (being set or stripped right now).
func _taken_boards() -> PackedInt32Array:
	var out := PackedInt32Array()
	if _rings == null or drive == null:
		return out
	for i in range(1, drive.form_count() + 1):
		if _rings.index_of(i) >= 0 and _rings.is_taken(i):
			out.append(i)
	return out


## An accepted press: the idle arrow's clock starts again from here.
func _accept(at: Vector2) -> void:
	_accepted = true
	_woke_at = at
	_woke()


## A press that was not the work: one quiet sound - never a buzzer - and the
## white arrow's clock runs FORWARD rather than back. A miss is a question;
## the answer comes sooner, never later (the improvement plan's 1.2).
func _miss() -> void:
	_accepted = false
	_woke_at = Vector2.INF
	if sfx != null and _now_s() - _miss_at_s >= MISS_SOUND_GAP:
		_miss_at_s = _now_s()
		sfx.play_group("pop")
	if hud != null:
		hud.hint_hurry()


## A machine answers a tap on it with its horn and a wink of its beacon (the
## plan's 1.8): the one passive stretch of the job - three arrivals, three
## exits - answers a finger without becoming a control.
func _honk(m: Machine) -> void:
	if _now_s() - _honk_at_s < HONK_GAP:
		return
	_honk_at_s = _now_s()
	if sfx != null:
		sfx.play_group("horn")
	m.flash_beacon(0.6)


## The machine drawn under a screen point, or null. Its box on the screen is
## its world box's corners projected, grown by half a finger's reach.
func _machine_under(at: Vector2) -> Machine:
	if camera == null or hud == null:
		return null
	var frame := get_viewport().get_visible_rect().size
	var grow := _reach_px() * 0.5
	for m: Machine in machines.values():
		if m == null or not m.visible:
			continue
		var box := _world_box(m)
		if box.size.length_squared() < 0.01:
			continue
		var rect := Rect2()
		var first := true
		var behind := false
		for c in range(8):
			var p := hud.project_into(frame, box.get_endpoint(c))
			if p.z <= 0.0:
				behind = true
				break
			var sp := Vector2(p.x, p.y)
			rect = Rect2(sp, Vector2.ZERO) if first else rect.expand(sp)
			first = false
		if behind or first:
			continue
		if rect.grow(grow).has_point(at):
			return m
	return null


func _now_s() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


## Which pad would take the pour toward the emptiest cell of the band the
## chute can reach: the white mime stands on it, and a tap on the picture
## kicks it (the plan's 2.1). Sideways when the finger's answer is sideways,
## along the drive otherwise; with UP meaning UP the picture, the pour has to
## move toward the kerb (+Z) on DOWN.
func _pour_hint_pad() -> String:
	var m := machine("ConcreteTruck")
	if m == null or drive == null:
		return "up"
	var want := drive.emptiest_in_band(pour_band_from)
	var at := m.pour_point_world(Driveway.GRADE)
	var dx := want.x - at.x
	var dz := want.z - at.z
	if absf(dx) > 0.25 and absf(dx) >= absf(dz):
		return "left" if dx < 0.0 else "right"
	if absf(dz) > 0.35:
		return "down" if dz > 0.0 else "up"
	if absf(dx) > 0.1:
		return "left" if dx < 0.0 else "right"
	return "down" if dz > 0.0 else "up"


func _any_pad_held() -> bool:
	for key: String in ["up", "down", "left", "right"]:
		if pad_held(key):
			return true
	return false


## The pad the white mime stands on during the pour, as a screen rectangle;
## nothing on every other beat.
func _hint_rect() -> Rect2:
	var s := runner.current_step() if runner != null else null
	if s != null and hud != null and SiteVerbs.PAD_VERBS.has(s.verb) and runner.is_busy():
		return hud.pad_rect(_pour_hint_pad())
	return Rect2()


## A phase the child worked is done: one "done" note, the same every time, so
## the child learns in the first phase what finishing sounds like and hears it
## eleven more times (the plan's 1.6). Not for the machine beats, which are not
## their work, and not for the last one, whose done is the tada.
func _on_step_done(i: int) -> void:
	if sfx == null or job == null or i < 0 or i >= job.steps.size():
		return
	if job.steps[i].progress_weight > 0 and i < job.steps.size() - 1:
		sfx.play_group("done")


## The moment a phase is finished: the last thing the child did is SEEN done
## before the picture moves on (the plan's 1.6). The tool goes back to its
## rest - unless it is still in the child's hands with its hose, which stays
## there for the hold and is put away with the rest at the next beat - and the
## shot holds for `phase_hold`. Nothing for the beats that are not the child's
## work. (The material's own finish - the last dry corner wetting, the board
## lifting, the bay drying - is each verb's, at its end.)
func phase_done(step: JobStep) -> void:
	if step == null or step.progress_weight <= 0:
		return
	var t := tool_node(step.tool)
	# Flying the nozzle home dropped its hose in one frame, in a picture held
	# still on the hands - on a 4:3 iPad a fifth of the screen of hose (4.3).
	if t != null and TOOL_REST.has(step.tool) and not t.trail_visible():
		if step.tool == "plate":
			# Standing upright, the way every other tool goes back to the grass -
			# never faded out in the held picture (the verification pass).
			t.hover(TOOL_REST[step.tool], Vector3.DOWN, Vector3.BACK)
		else:
			t.hover(TOOL_REST[step.tool], Vector3.FORWARD, Vector3.UP)
	await get_tree().create_timer(config.phase_hold, false).timeout


func _notification(what: int) -> void:
	# A PAUSE is the settings panel taking the screen (6.4). The tree it freezes
	# never delivers the release of whatever finger was down, and this level
	# keeps its own finger state - so a child holding the screed when a parent
	# opens the panel would come back to a beat the level still thinks is held.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PAUSED:
		# The app went to the background with a finger down. That finger is
		# gone as far as the toy can tell, so the beat lets go of it now rather
		# than spraying on its own when the child comes back to it.
		_fingers.clear()
		_finger = -1
		_carry_back = false
		if _touch_down:
			_touch_down = false
			if runner != null and not runner.finished:
				runner.hold(false)
		if hud != null:
			hud.release_pads()


## Did a tap at `at` land on the thing the arrow is pointing at (DESIGN 0)?
##
## On it, or within a finger's reach of it, or anywhere on the arrow itself. The
## reach is a fraction of the picture's SHORTER side plus the target's own size
## on screen, so an iPad, a phone and a 720p window all get the same finger.
## How near a target a finger has to land, in pixels of THIS screen: a fraction
## of the picture's shorter side, so it is the same finger on an iPad, a phone and
## a 720p window.
func _reach_px() -> float:
	var frame := get_viewport().get_visible_rect().size
	return minf(frame.x, frame.y) * config.tap_reach


## The least a ring's reach may shrink to when the world cap (`tap_reach_m`)
## is small on the screen: a finger's own width.
func _finger_px() -> float:
	var frame := get_viewport().get_visible_rect().size
	return minf(frame.x, frame.y) * config.tap_reach_min


func tap_counts(at: Vector2) -> bool:
	if config.tap_anywhere:
		return true
	if hud == null:
		return true
	# A ring beat is measured against the rings, not against a step's own target.
	if rings_up():
		return _rings.pick_nearest(camera, at, _reach_px(), false, config.tap_reach_m, _finger_px()) != 0
	# A beat worked by DRAGGING is aimed at the whole slab, not at a point on it:
	# anywhere on the concrete is the right place to start, because the child is
	# about to cover all of it. Measuring such a beat against one marker in the
	# middle of a nine-metre slab would refuse a perfectly sensible first touch at
	# the far end.
	var step := runner.current_step()
	# Backing a truck in: the press has to land on the truck (1.8). Anywhere
	# else is a miss, answered with the pop and the arrow's nudge.
	if step != null and SiteVerbs.BACK_VERBS.has(step.verb):
		return on_backing_truck(at)
	# A DRAG beat is aimed at its TOOL - the board, the sled, the plate: a press
	# on it or within a finger of it picks it up; a press on the empty slab in
	# front of it is a miss, answered at once rather than with two seconds of
	# nothing (the improvement plan's 2.5).
	# The plate by its own one rule, shared with its grab (`plate_under`).
	if step != null and step.verb == "compact_base" and drag_tool_at != Vector3.INF:
		return plate_under(at)
	if step != null and step.verb in ["screed_pull", "joint_cut", "compact_base"]:
		var fr := get_viewport().get_visible_rect().size
		var tp := hud.project_into(fr, drag_hint(step.verb))
		if tp.z <= 0.0:
			return true
		var t_px := config.drag_grab * hud.pixels_per_metre(fr, tp.z)
		return Vector2(tp.x, tp.y).distance_to(at) <= _reach_px() + t_px
	if step != null and SiteVerbs.SCRUB_VERBS.has(step.verb):
		var on := _screen_to_plane(at, Driveway.GRADE)
		if on != Vector3.INF and absf(on.x - Driveway.CENTRE_X) < Driveway.WIDTH * 0.5 + 0.7 \
				and on.z > Driveway.Z_APRON - 0.7 and on.z < Driveway.Z_KERB + 0.7:
			return true
	var frame := get_viewport().get_visible_rect().size
	var reach := minf(frame.x, frame.y) * config.tap_reach
	if hud.arrow_hit(at, reach * 0.5):
		return true
	var world := runner.target_world()
	if world == Vector3.INF:
		# Nothing is being pointed at (the pour steers itself): any tap counts.
		return true
	var p := hud.project_into(frame, world)
	if p.z <= 0.0:
		return true
	var r_px := runner.target_radius() * hud.pixels_per_metre(frame, p.z)
	return Vector2(p.x, p.y).distance_to(at) <= reach + r_px


## The pads a beat uses, or none (`SiteVerbs.PAD_VERBS`). A pad on screen that
## does nothing is a lie, so only the ones this verb reads are shown.
func arm_pads(verb: String) -> void:
	if hud == null:
		return
	hud.show_pads(SiteVerbs.PAD_VERBS.get(verb, []))


## Lights a gold ring on every place this beat will still take, so a child can
## SEE where to press and may take them in whatever order they like.
##
## The user's note after the second playtest was that there were still shots where
## they could not tell where to click - the stakes worst of all - and that the
## three hammer spots should be marked and workable in any order. A ring on the
## thing itself answers both, and it answers them better than the gold arrow did,
## because the arrow can only point at ONE place and these phases have three, four
## and ten. `SpotRings` is Tree Crew's `FellHint` made plural.
##
## Called wherever `arm_pads` is: entering a step, finishing a beat, and posing.
func arm_rings(step: JobStep, done: int) -> void:
	if _rings == null:
		return
	# A tap kept while the last bite ran keeps the ring it landed on - for the
	# step it was on. A tap kept across into a NEW step was aimed at a ring of
	# the old one (a board's ring must not drive a stake), and a new step wants
	# a new press (the improvement plan's 0.4).
	var want := 0
	if _queued_pick > 0:
		if runner != null and runner.index == _queued_pick_step:
			want = _queued_pick
		elif runner != null:
			runner.drop_queued_tap()
	_queued_pick = 0
	_queued_pick_step = -1
	_picked = 0
	_rings.clear_rings()
	if step == null or drive == null:
		return
	# The green button's picture is the machine it brings (round 4: one flatbed
	# glyph promised the wrong thing three times).
	if hud != null:
		# The machine the NEXT call brings, whatever step this is: the sleeping
		# button shows what is coming.
		hud.set_call_glyph(_next_call_verb())
	# The screed's eye starts at the apron before the board is pressed, or it
	# jumped there on the press.
	if step.verb == "screed_pull":
		set_screed_view(Driveway.Z_APRON)
	# The plate stands on its bay's base from the frame its step opens, and again
	# after every beat at the point the beat walked it to - never on the lawn at
	# its rest, and never popping (5.1).
	if step.verb == "compact_base":
		var pbay := clampi(done + 1, 1, drive.bay_count())
		if done == 0 or _plate_at == Vector3.INF:
			set_plate_view(plate_at(pbay))
		hold_plate(tool_node("plate"), plate_at(pbay), pbay, false)
	var points: Array[Vector3] = []
	var ids := PackedInt32Array()
	var size := 0.0
	match step.verb:
		"jack_spot":
			# The three places on THIS panel - the first one still whole, by STATE
			# and not by counting beats (the user's 2026-09-14 playtest: a panel
			# that never broke). The three bites on it are in any order.
			var panel := drive.current_panel()
			for n in drive.open_spots(panel):
				var m := drive.spot_marker(n)
				if m != null:
					points.append(m.global_position + Vector3(0.0, 0.06, 0.0))
					ids.append(n)
			size = config.ring_spot
		"form_set":
			# The group being set: the two long boards, then the kerb board, then
			# the strip (round 4).
			# The ring rides ON the board waiting in the air, not on the grass
			# under it (round 5: "the child is asked to tap the lawn").
			# Every board the job can take now waits in the air over its place from
			# the moment the row opens (it used to appear only on the first tap, with
			# the rings floating over an empty trench). Only those: the kerb board is
			# not on site until the base is packed (5.2).
			for i in drive.live_open_forms():
				if not drive.form_shown(i):
					drive.set_form(i, 0.0)
			for i in drive.open_forms_in(drive.current_form_group()):
				points.append(drive.form_home(i) + Vector3(0.0, config.form_drop_height + 0.10, 0.0))
				ids.append(i)
			size = config.ring_form
		"stake_drive":
			# The pair being driven, not all ten: the camera is right down on
			# them now, and a ring on a stake nine metres up the drive would be
			# a ring on something off the picture.
			# The pegs stand waiting from the moment the phase opens, the way the
			# bars do: they used to appear only on the first blow, so the first
			# pair's rings floated over bare earth (4.2). Never a driven one.
			# Only pegs whose board is in: the kerb board's two wait for it (5.2),
			# or they stood in the road's edge while the tipper backed over them.
			for j in range(1, drive.stake_count() + 1):
				if not drive.stake_is_in(j) and not drive.stake_shown(j) and drive.stake_live(j):
					drive.set_stake(j, 0.0)
			for i in drive.open_stakes_in(drive.current_stake_group()):
				# ON the painted cap, which is what the sledge lands on (4.2).
				points.append(drive.stake_cap(i))
				ids.append(i)
			size = config.ring_stake
		"rebar_lay":
			# The group being laid: the four long bars, then a pair of cross bars.
			# Its bars wait in the air over their places while their rings are lit,
			# the way the form boards do.
			drive.show_chairs(true)
			for i in drive.open_bars_in(drive.current_bar_group()):
				if not drive.bar_is_in(i):
					drive.set_bar(i, 0.0)
				# ON the bar where it waits, so the drop can be a real drop again
				# without the ring and the bar parting company (round 5).
				# ON the bar's own height - no margin: six centimetres above it the
				# ring sat on the gravel behind the bar (round 9).
				points.append(drive.bar_wait_point(i))
				ids.append(i)
			size = config.ring_bar
		"form_strip":
			# All three boards at once, in any order (5.3): the child strips what
			# they set. Never the expansion strip, which stays in the slab.
			for i in drive.open_strip_forms():
				points.append(drive.strip_ring_point(i))
				ids.append(i)
			size = config.ring_form
		_:
			return
	if want > 0:
		if ids.has(want):
			_picked = want
		elif runner != null:
			# The ring the kept tap chose is done - the bite that was running
			# did it, or a mash on one ring - so there is nothing to spend it on.
			runner.drop_queued_tap()
	_rings.show_at(points, ids, size)


## Are the rings the way in to this beat? While they are, the gold arrow stays
## off: two things pointing at two different places is worse than either.
func rings_up() -> bool:
	return _rings != null and _rings.lit()


## Which ring the last tap chose (0 when none did). A verb reads this instead of
## counting beats, which is what lets the child take them in any order.
func picked() -> int:
	return _picked


## Where the child is working on the slab right now, or `INF` for nowhere.
##
## The hose and the broom are DRAGGED: their beats ask this every frame and wet or
## brush whatever they find under it. A finger is the first answer; a stick or the
## arrow keys drive a cursor instead, so the job is still playable with no touch
## screen; and a test can put the point wherever it likes.
## Where a tool the child is HOLDING sits: `off` is right, up and forward of the
## eye in the camera's own frame (DESIGN 1a, the `HAND` shot), so the thing stays
## in the same corner of the picture whatever it is aimed at.
## A `--name=x,y,z` argument as a Vector3, or `fallback` when absent.
func _vec_arg(args: Dictionary, key: String, fallback: Vector3) -> Vector3:
	if not args.has(key):
		return fallback
	var bits := String(args[key]).split(",", false)
	if bits.size() != 3:
		return fallback
	return Vector3(float(bits[0]), float(bits[1]), float(bits[2]))


## The white idle arrow: what the child should do NOW, for the HUD's mime.
## NONE while a verb is running, while the pads steer the pour, or while a
## finger is down on a hold.
func _hint_kind() -> SiteHud.Hint:
	if hud == null or runner == null:
		return SiteHud.Hint.NONE
	if _celebrating:
		return SiteHud.Hint.TAP if hud.next_visible() else SiteHud.Hint.NONE
	if runner.finished:
		return SiteHud.Hint.NONE
	var s := runner.current_step()
	if runner.waiting_for_hold():
		if s != null and SiteVerbs.PAD_VERBS.has(s.verb):
			# The pour: HOLD a pad - which one is `_pour_hint_pad`'s to say -
			# whenever no pad is held (the improvement plan's 2.1).
			return SiteHud.Hint.NONE if _any_pad_held() else SiteHud.Hint.HOLD
		if s != null and SiteVerbs.SCRUB_VERBS.has(s.verb):
			return SiteHud.Hint.DRAG
		return SiteHud.Hint.NONE if runner.held else SiteHud.Hint.HOLD
	if runner.is_busy():
		return SiteHud.Hint.NONE
	if runner.waiting_button() != "" or runner.waiting_for_tap():
		return SiteHud.Hint.TAP
	return SiteHud.Hint.NONE


## On a rings beat the white arrow stands over the first live ring (any of
## them is a right answer); otherwise over the pointer's own target.
func _hint_world() -> Vector3:
	if rings_up():
		return _rings.point_at(0)
	return Vector3.INF


func _woke() -> void:
	if hud != null:
		hud.hint_wake()


func _drag_woke(at: Vector2) -> void:
	# A finger that was not the work does not wake the mime by wandering.
	if not _accepted:
		return
	if _woke_at == Vector2.INF or at.distance_to(_woke_at) > HINT_WAKE_PX:
		_woke_at = at
		_woke()


## The machine the row after this one has the child back in, or null: a press
## on it while it comes down the street is kept for the back-in (1.8).
func _backed_by_next_row() -> Machine:
	if job == null or runner == null:
		return null
	var i := runner.index + 1
	if i < 0 or i >= job.steps.size():
		return null
	var nxt: JobStep = job.steps[i]
	if nxt == null or not SiteVerbs.BACK_VERBS.has(nxt.verb):
		return null
	return machine(String(SiteVerbs.BACK_VERBS[nxt.verb]))


## The verb of the next BUTTON step from the current one, or "".
func _next_call_verb() -> String:
	if job == null or runner == null:
		return ""
	# While a truck is being backed in, the sleeping button still shows THAT
	# truck: the next call is a whole phase away.
	var here := runner.current_step()
	if here != null and SiteVerbs.BACK_VERBS.has(here.verb) and runner.index > 0:
		return job.steps[runner.index - 1].verb
	for i in range(maxi(runner.index, 0), job.steps.size()):
		var s: JobStep = job.steps[i]
		if s != null and s.kind == JobStep.Kind.BUTTON:
			return s.verb
	return ""


## Where a DRAG beat's arrow stands before the first press: on the tool, where
## the pull begins - the board's line, the sled at the near form, the roughest
## cell of the bay - not on a marker in the slab's middle behind the eye.
func drag_hint(verb: String) -> Vector3:
	# A tool being dragged says where it is; the arrow stands on it and a press
	# is measured against it wherever it has got to (the plan's 2.5).
	if drag_tool_at != Vector3.INF and verb in ["screed_pull", "joint_cut", "compact_base"]:
		return drag_tool_at
	match verb:
		"compact_base":
			return plate_at(clampi(runner.done_in_step + 1, 1, drive.bay_count()))
		"screed_pull":
			var z := _screed_view.position.z if _screed_view != null else Driveway.Z_APRON
			return Vector3(Driveway.CENTRE_X, Driveway.GRADE, z + 0.35)
		"joint_cut":
			var jn := clampi(runner.done_in_step + 1, 1, drive.joint_count())
			return Vector3(Driveway.CENTRE_X - Driveway.WIDTH * 0.5 + 0.25, Driveway.GRADE, drive.joint_z(jn))
		"broom_finish":
			var band := drive.bay_range(clampi(runner.done_in_step + 1, 1, drive.bay_count()))
			return drive.roughest_world_in(band.x, band.y)
	return Vector3.INF


## Which way the white arrow's DRAG mime swipes, on the screen: down the
## picture for the screed and the broom (the stroke runs across the drive
## from the side eye, down the drive from the screed's), across for the rest.
func _hint_swipe_axis() -> Vector2:
	var s := runner.current_step() if runner != null else null
	if s != null and (s.verb == "screed_pull" or s.verb == "broom_finish"):
		return Vector2.DOWN
	if s != null and s.verb == "compact_base" and hud != null and drive != null and drag_tool_at != Vector3.INF:
		# From the plate toward the patch of its bay still loose.
		var band := drive.bay_range(clampi(runner.done_in_step + 1, 1, drive.bay_count()))
		var fr := get_viewport().get_visible_rect().size
		var a := hud.project_into(fr, drag_tool_at)
		var b := hud.project_into(fr, drive.least_packed_in(band.x, band.y))
		var d := Vector2(b.x - a.x, b.y - a.y)
		if a.z > 0.0 and b.z > 0.0 and d.length() > 4.0:
			return d.normalized()
		return Vector2.UP
	return Vector2.RIGHT


func hand_hold(off: Vector3) -> Vector3:
	if camera == null or not is_instance_valid(camera):
		return Vector3.ZERO
	var b := camera.global_transform.basis
	return camera.global_position + b.x * off.x + b.y * off.y - b.z * off.z


## The hose in the child's hands, aimed at `at` on the slab: the nozzle a fixed
## arm's length in front of the eye (`hose_hold`), lobbed so the jet lands there,
## and the hose running from its grip off the bottom of the picture
## (`hose_trail`, the improvement plan's 4.3). The water beat and its posed
## picture both come here, so the picture cannot drift from the play.
func hold_hose(t: HandTool, at: Vector3) -> void:
	if t == null or camera == null or at == Vector3.INF:
		return
	var hold := hand_hold(config.hose_hold)
	# Lobbed a little: aimed straight at the point, gravity dropped the jet a
	# metre short of where the slab was being wetted (round 3).
	var reach := hold.distance_to(at)
	t.hover_instant(hold, (at + Vector3.UP * reach * 0.09 - hold).normalized(), Vector3.UP)
	t.set_spray_reach(reach)
	t.trail_to(hand_hold(config.hose_trail))


## The plate compactor standing on the base at `at`, its handle running to the
## child's hands off the bottom of the PLATE picture (the plan's 5.1). One helper
## for the beat, the step's entry and the posed picture, like `hold_hose`. The
## hands are taken off the bay's own PLATE pose, not the live camera: the live
## one is still easing in when the step opens, and the rattle rolls it, and a
## handle aimed at either would swing.
func hold_plate(t: HandTool, at: Vector3, bay: int, working: bool) -> void:
	if drive == null or at == Vector3.INF:
		return
	_plate_at = Vector3(at.x, Driveway.BASE_TOP, at.z)
	drag_tool_at = _plate_at
	if t == null:
		return
	# It rides the loose stone and settles as the patch under it packs.
	var sole := Driveway.BASE_TOP + Driveway.STONE_FLAT_PROUD \
		+ PLATE_RIDE * (1.0 - clampf(drive.packed_at(_plate_at), 0.0, 1.0))
	var head := Vector3(at.x, sole, at.z)
	# The hands stand where the PLATE eye stands - its eye point walks after the
	# plate between strokes (`ease_plate_view`) - so the handle keeps about the
	# same length wherever the plate goes (the verification pass: aimed at one bay's
	# fixed hands it stretched past its limit at the bay's far row).
	var hands := plate_hands()
	t.hover_instant(head, Vector3.DOWN, (hands - head).normalized())
	t.aim_handle_at(hands)
	if working:
		t.set_bit(-config.plate_stroke * (0.5 + 0.5 * sin(TAU * config.plate_hz * _now_s())))
	else:
		t.set_bit(0.0)


## The child's hands on the plate's handle: `plate_hold` in the frame of the
## PLATE pose at `PlateView` (never the live, rattling camera).
func plate_hands() -> Vector3:
	var tr := rig.pose_for(CameraRig.PLATE, _plate_view)
	var o := config.plate_hold
	return tr.origin + tr.basis.x * o.x + tr.basis.y * o.y - tr.basis.z * o.z


## Where the plate stands for bay `b`: where the last beat left it if that is in
## this bay, else the bay's start.
func plate_at(b: int) -> Vector3:
	if drive == null:
		return Vector3.INF
	var band := drive.bay_range(b)
	if _plate_at != Vector3.INF and _plate_at.z >= band.x and _plate_at.z <= band.y:
		return _plate_at
	return drive.plate_start(b)


func work_point(plane_y: float = 0.0) -> Vector3:
	if _cursor != Vector3.INF:
		return Vector3(_cursor.x, plane_y, _cursor.z)
	if not _touch_down or _touch_at == Vector2.INF or camera == null:
		return Vector3.INF
	return _screen_to_plane(_touch_at, plane_y)


## A point on the screen dropped onto a horizontal plane, through the live camera.
func _screen_to_plane(at: Vector2, plane_y: float) -> Vector3:
	if camera == null:
		return Vector3.INF
	var from := camera.project_ray_origin(at)
	var dir := camera.project_ray_normal(at)
	if absf(dir.y) < 0.0001:
		return Vector3.INF
	var t := (plane_y - from.y) / dir.y
	if t < 0.0:
		return Vector3.INF
	return from + dir * t


## Puts the work point somewhere by hand: the sticks use it, and so does the
## smoke test, which has no finger at all.
## Is the work point a WORLD cursor (a stick, a test, a posed render) rather
## than a finger on the screen? A camera may follow the work under a world
## cursor; under a finger it must not, or the ground moves under the finger.
func drag_is_world() -> bool:
	return _cursor != Vector3.INF


func set_work_cursor(at: Vector3) -> void:
	_cursor = at
	_cursor_from_stick = false


func clear_work_cursor() -> void:
	_cursor = Vector3.INF
	_cursor_from_stick = false


## Is a pad held - by a thumb, or by a stick or the arrow keys?
func pad_held(key: String) -> bool:
	if hud != null and hud.held(key):
		return true
	var v := Pad.move()
	match key:
		"up":
			return v.y < -0.3
		"down":
			return v.y > 0.3
		"left":
			return v.x < -0.3
		_:
			return v.x > 0.3


## The pad-driven beats take their HOLD from the pads rather than from a finger
## on the picture, so the machine is the control. The pour is the exception: the
## concrete runs the whole time and the pads only AIM it, which is what the user
## asked for - "control it back and forth as concrete pours out".
func _process(delta: float) -> void:
	# The white idle arrow's clock, before anything returns early: NEXT's tap
	# hint has to tick while the site is celebrating.
	if hud != null and runner != null:
		hud.hint_tick(delta, _hint_kind(), _hint_world(), _hint_swipe_axis(), _hint_rect())
		# One arrow at a time on a rings beat too: the last ring of a set has
		# its own gold arrow, which stands aside while the white one is up.
		if _rings != null:
			_rings.set_arrow_shown(not hud.hint_visible())
		# A BUTTON beat whose arrow was muted at entry gets it back when the
		# mute lapses; NEXT is aimed at while the site celebrates.
		if not runner.finished and runner.waiting_button() != "" and not runner.is_busy() \
				and not hud.aiming_at_button() and not runner.arrow_muted():
			runner.update_arrow()
		if _celebrating and hud.next_visible() and not hud.aiming_at_button():
			hud.point_at_next()
		# The HUD steps back while a beat is live under the finger (3.7): the
		# finger that IS the beat, not one resting on the lawn.
		if not _celebrating:
			hud.set_working(runner.is_busy() or (_touch_down and _accepted))
	# The opening's clock (3.1): the wide is held, then the eye comes down.
	if _opening:
		_opening_left -= delta
		if _opening_left <= 0.0:
			_end_opening()
	if runner == null or runner.finished or _celebrating:
		return
	var s := runner.current_step()
	if s == null or s.kind != JobStep.Kind.HOLD:
		return
	if SiteVerbs.BACK_VERBS.has(s.verb):
		# The finger that was on the truck as it came down the street backs it
		# in the moment it stops (the plan's 1.8) - if it is still down.
		if _carry_back and _touch_down and not runner.held and not runner.is_busy():
			_carry_back = false
			_accept(_touch_at if _touch_at != Vector2.INF else Vector2.ZERO)
			runner.hold(true)
		# The ring stands on the truck, which moves: the HUD re-applies the point
		# it was last given, so it is given the truck's every frame until it is.
		if not runner.held and hud != null and hud.aiming_at_world() and not runner.arrow_muted():
			runner.update_arrow()
		return
	# A beat worked by dragging: a real stick or the arrow keys drive a cursor over
	# the slab, because a keyboard has no finger. A touch screen never comes
	# through here - `work_point` reads the finger straight off the screen.
	if SiteVerbs.SCRUB_VERBS.has(s.verb):
		var stick := Pad.move()
		if stick.length() > 0.3:
			_woke()
			# A stick ends the opening look as a finger does (`Pad.go_event`),
			# or the drag ran on the wide until the eye swooped in mid-stroke.
			_end_opening()
			if _cursor == Vector3.INF:
				match s.verb:
					"broom_finish":
						var bb := drive.bay_range(clampi(runner.done_in_step + 1, 1, drive.bay_count()))
						_cursor = drive.roughest_world_in(bb.x, bb.y)
					"rake_pull":
						_cursor = drive.rake_front_world(config.rake_reach)
					"screed_pull":
						_cursor = Vector3(Driveway.CENTRE_X, Driveway.GRADE,
							(_screed_view.position.z if _screed_view != null else Driveway.Z_APRON) + 0.3)
					"joint_cut":
						_cursor = Vector3(Driveway.CENTRE_X - Driveway.WIDTH * 0.5 + 0.25, Driveway.GRADE,
							drive.joint_z(clampi(runner.done_in_step + 1, 1, drive.joint_count())))
					"compact_base":
						# ON the plate, or a stick could never pick it up.
						_cursor = drag_tool_at if drag_tool_at != Vector3.INF \
							else drive.plate_start(clampi(runner.done_in_step + 1, 1, drive.bay_count()))
					_:
						_cursor = drive.driest_world()
				_cursor_from_stick = true
			_cursor += Vector3(stick.x, 0.0, stick.y) * config.scrub_speed * delta
			_cursor.x = clampf(_cursor.x, Driveway.CENTRE_X - Driveway.WIDTH * 0.5,
				Driveway.CENTRE_X + Driveway.WIDTH * 0.5)
			_cursor.z = clampf(_cursor.z, Driveway.Z_APRON, Driveway.Z_KERB)
			if s.verb == "compact_base" and drag_tool_at != Vector3.INF:
				# Kept a hand's width from the plate and inside its bay: a stick
				# cursor that ran ahead at 2.6 m/s lost the plate's grab, and one
				# left in the last bay never picked the plate up in the next.
				var off := Vector3(_cursor.x - drag_tool_at.x, 0.0, _cursor.z - drag_tool_at.z).limit_length(0.4)
				_cursor = drive.clamp_plate(Vector3(drag_tool_at.x + off.x, 0.0, drag_tool_at.z + off.z),
					clampi(runner.done_in_step + 1, 1, drive.bay_count()))
			runner.hold(true)
		elif _cursor_from_stick:
			# The stick let go: hand the beat back to the finger and stop working.
			_cursor = Vector3.INF
			_cursor_from_stick = false
			runner.hold(false)
		if hud != null:
			hud.set_stick_glow(stick)
		return
	if not SiteVerbs.PAD_VERBS.has(s.verb):
		return
	# The pour is the one beat the pads steer. The concrete runs the whole time and
	# the pads only AIM it, which is what the user asked for. A pad under a
	# thumb is the child doing something: the idle mime's clock starts again.
	if _any_pad_held():
		_woke()
	runner.hold(true)
	if hud != null:
		hud.set_stick_glow(Pad.move())


# --- Effects --------------------------------------------------------------------------------

func _build_effects() -> void:
	_dust = _puff("Dust", Color(0.78, 0.74, 0.66, 0.85), 0.10, 26, 0.55, 1.1)
	# THE BREAKER'S OWN DUST (round 4): one shared puff restarted at thirteen
	# blows a second never grew past twenty pixels. This one RUNS while the bite
	# runs - a hold-shaped effect for a bite-shaped beat - with chips of concrete
	# thrown out under real gravity beside it.
	_breaker = _puff("BreakerDust", Color(0.80, 0.76, 0.68, 0.80), 0.22, 90, 0.80, 1.4)
	_breaker.one_shot = false
	_breaker.explosiveness = 0.0
	_breaker.emitting = false
	var bdm := _breaker.process_material as ParticleProcessMaterial
	bdm.spread = 55.0
	bdm.gravity = Vector3(0.0, -1.2, 0.0)
	bdm.scale_min = 0.5
	bdm.scale_max = 1.4
	# THE BLADE'S DUST: earth and grit rolling up off the cutting edge for as
	# long as it is pushing. Round 4 named it as the one change that would make
	# the push a beat you would show a friend.
	_push_dust = _puff("PushDust", Color(0.66, 0.54, 0.40, 0.62), 0.24, 110, 0.9, 1.1)
	# Thrown FORWARD and low off the cutting edge, so from the machine's eye
	# the cloud stays under the blade's top line instead of smearing across
	# the mouldboard (round 11, the third time).
	var push_pm := _push_dust.process_material as ParticleProcessMaterial
	push_pm.direction = Vector3(0.0, 0.5, 1.0)
	push_pm.spread = 32.0
	_push_dust.one_shot = false
	_push_dust.explosiveness = 0.0
	_push_dust.emitting = false
	var pdm := _push_dust.process_material as ParticleProcessMaterial
	pdm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pdm.emission_box_extents = Vector3(0.85, 0.05, 0.25)
	pdm.direction = Vector3(0.0, 0.75, 0.6)
	pdm.spread = 40.0
	pdm.gravity = Vector3(0.0, -1.6, 0.0)
	pdm.scale_min = 0.5
	pdm.scale_max = 1.5
	_chips = _puff("Chips", Color(0.60, 0.59, 0.56), 0.06, 70, 0.9, 3.6)
	_as_lumps(_chips, 0.05)
	_chips.one_shot = false
	_chips.explosiveness = 0.0
	_chips.emitting = false
	var cm := _chips.process_material as ParticleProcessMaterial
	cm.spread = 60.0
	cm.gravity = Vector3(0.0, -9.8, 0.0)
	cm.initial_velocity_min = 1.6
	cm.initial_velocity_max = 3.2
	# THE TIP'S OWN POUR (the user, 2026-09-12: "the dump truck needs a pour
	# animation"). It was the dust puff with a different colour - forty 5 cm
	# quads thrown UPWARD out of a point, which is what a bag of cement dropped
	# on the floor looks like. A tipper pours a CURTAIN: stone leaves the whole
	# width of the tailgate at once, falls, and keeps falling while the bed is
	# up. So: emitted along a box as wide as the lip, thrown down and back at
	# real speed, under real gravity, and never one-shot.
	# SHADED (round 8: unshaded full-albedo discs were the brightest thing in
	# the frame, drawn over the truck's tyres like soap bubbles), the base's own
	# colour, so what falls is what lands.
	_gravel = _puff("GravelFall", Color(0.63, 0.56, 0.45), 0.075, 720, 1.15, 1.7, true)
	# The curtain is LUMPS - the same angular stone that lies on the base -
	# tumbling, and lit like it: 720 soft brown dots read as mud sprayed on the
	# truck (round 10).
	_as_lumps(_gravel, 0.05)
	_gravel.one_shot = false
	_gravel.explosiveness = 0.0
	var gm := _gravel.process_material as ParticleProcessMaterial
	gm.direction = Vector3(0.0, -0.72, 0.70)
	gm.spread = 16.0
	gm.gravity = Vector3(0.0, -9.8, 0.0)
	gm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	gm.emission_box_extents = Vector3(1.05, 0.06, 0.08)
	gm.scale_min = 0.5
	gm.scale_max = 1.25
	_splat = _puff("Splat", Color(0.62, 0.63, 0.66), 0.045, 28, 0.45, 1.6, true)
	var spm := _splat.process_material as ParticleProcessMaterial
	spm.spread = 70.0
	spm.gravity = Vector3(0.0, -6.0, 0.0)
	# The concrete coming off the spout: FOUR segments, narrow at the lip and
	# wide where they land, each wobbling a little on its own, and a splash disc
	# where it hits. One stretched box was a grey post (round 5).
	_stream = Node3D.new()
	_stream.name = "Stream"
	_stream.visible = false
	add_child(_stream)
	# The MATERIAL's colour: the pool's own, a step lighter, set every frame
	# from `Driveway.pool_colour` (round 7: a fixed cream was 1.85x the pool
	# and read as a stone bollard). Round, overlapping, thrown along the chute
	# and falling.
	# UNSHADED, so the colour rule survives to the screen: lit, a solid
	# cylinder turned from the sun rendered a quarter DARKER than the pool it
	# was meant to be a step lighter than (round 8). And no shadow - the stream
	# cast a post's shadow on the slab.
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.60, 0.61, 0.64)
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_stream_mat = sm
	# One material per segment, each a shade lighter than the one above it, so
	# the four overlapping segments do not fuse into one flat card (round 10).
	for i in range(4):
		var seg := MeshInstance3D.new()
		seg.name = "Seg_%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.08
		cyl.height = 0.25
		cyl.radial_segments = 12
		var seg_mat := sm if i == 0 else sm.duplicate() as StandardMaterial3D
		_stream_mats.append(seg_mat)
		cyl.material = seg_mat
		seg.mesh = cyl
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stream.add_child(seg)
		_stream_segs.append(seg)
	_splash = MeshInstance3D.new()
	_splash.name = "Splash"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.36
	disc.bottom_radius = 0.36
	disc.height = 0.03
	disc.radial_segments = 14
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.60, 0.61, 0.64)
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material = dm
	_splash_mat = dm
	disc.top_radius = 0.20
	disc.bottom_radius = 0.20
	disc.height = 0.04
	_splash.mesh = disc
	_splash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stream.add_child(_splash)
	# The wet RIM round the landing: a wider, thinner disc a step darker,
	# under the tongue.
	_splash_rim = MeshInstance3D.new()
	_splash_rim.name = "SplashRim"
	var rim := CylinderMesh.new()
	rim.top_radius = 0.27
	rim.bottom_radius = 0.27
	rim.height = 0.02
	rim.radial_segments = 14
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.42, 0.43, 0.46)
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim.material = rm
	_splash_rim_mat = rm
	_splash_rim.mesh = rim
	_splash_rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Built, not drawn (round 14): it was the hole the chute's shadow had been.
	_splash_rim.visible = false
	_stream.add_child(_splash_rim)
	# What the pour's camera hangs off: a point on the drive that follows the pour
	# along its length and nothing else. See `_define_shots`.
	var view := Marker3D.new()
	view.name = "PourView"
	view.position = Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 1.4)
	add_child(view)
	_pour_view = view
	var sview := Marker3D.new()
	sview.name = "ScreedView"
	sview.position = Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON + 0.4)
	add_child(sview)
	_screed_view = sview
	var rview := Marker3D.new()
	rview.name = "RakeView"
	rview.position = Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON)
	add_child(rview)
	_rake_view = rview
	# The plate compactor's eye point (5.1): it walks after the plate between
	# strokes, never under a dragging finger.
	var pview := Marker3D.new()
	pview.name = "PlateView"
	pview.position = Vector3(Driveway.CENTRE_X, Driveway.GRADE, Driveway.Z_APRON)
	add_child(pview)
	_plate_view = pview


func _puff(puff_name: String, color: Color, size: float, amount: int, life: float,
		speed: float, matched: bool = false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = puff_name
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.9
	p.local_coords = false
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0.0, 1.0, 0.0)
	m.spread = 42.0
	m.initial_velocity_min = speed * 0.5
	m.initial_velocity_max = speed
	m.gravity = Vector3(0.0, -3.2, 0.0)
	m.scale_min = 0.6
	m.scale_max = 1.0
	m.color = color
	p.process_material = m
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	# A particle that IS a material already on screen (stone, splashed
	# concrete) is UNLIT and takes that material's colour as sRGB, so it renders
	# at the value the material's own lit surface does. Lit, as a sphere beside
	# a flat lit plane, it came out 30-50% darker (rounds 7, 8, 9: the stream,
	# then the curtain, then the splash - the same trap three times); unlit
	# with the colour read as LINEAR it came out a glowing disc (round 8). Dust,
	# water and sparkle keep the glow: it is what they do.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Converted ONCE. `ParticleProcessMaterial.color` is a source colour, so it
	# reaches the shader already linear; asking the surface to convert it a
	# second time (round 9) rendered the splash's dots at 0.25 grey on a 0.62
	# pool (round 10, measured in the frame). `matched` now only means unlit.
	mat.vertex_color_is_srgb = false
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# A soft dot, not a hard square: dust, water and stone were all the same
	# hard-edged quad at every size (round 3).
	mat.albedo_texture = soft_dot()
	quad.material = mat
	p.draw_pass_1 = quad
	add_child(p)
	return p


## One soft round sprite for every particle in the game: white in the middle,
## clear at the edge.
static var _soft: Texture2D


static func soft_dot() -> Texture2D:
	if _soft != null:
		return _soft
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.85),
		Color(1.0, 1.0, 1.0, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 32
	t.height = 32
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	_soft = t
	return t


## A puff of concrete dust where the hammer is biting.
func dust_at(at: Vector3, size: float = 0.10, color: Color = Color(0.78, 0.74, 0.66, 0.85)) -> void:
	if _dust == null:
		return
	var quad := _dust.draw_pass_1 as QuadMesh
	quad.size = Vector2(size, size)
	# The colour of what it comes off: concrete for the breaker, EARTH for a
	# stake driven into the trench (round 10: concrete dust in brown earth).
	(_dust.process_material as ParticleProcessMaterial).color = color
	_dust.global_position = at
	_dust.restart()
	_dust.emitting = true


## Turns a puff of soft dots into a shower of LUMPS: a small lit box per
## particle, tumbling, in the emitter's own colour. Stone and concrete chips.
func _as_lumps(p: GPUParticles3D, size: float) -> void:
	var bm := BoxMesh.new()
	bm.size = Vector3(size, size * 0.8, size * 1.2)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	bm.material = mat
	p.draw_pass_1 = bm
	var pm := p.process_material as ParticleProcessMaterial
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -220.0
	pm.angular_velocity_max = 220.0


## The blade's dust: a box the width of the cutting edge, turned with the
## machine, boiling while it pushes.
func set_push_dust(at: Vector3, facing: Basis, on: bool) -> void:
	if _push_dust == null:
		return
	# At the CUTTING EDGE and well ahead of it, thrown up and forward, so the
	# cloud breaks the blade's silhouette rather than crossing its face (round
	# 8: emitted at mid-blade a third of a metre ahead, it projected straight
	# onto the mouldboard from the MACHINE eye and read as mud on the blade).
	_push_dust.global_transform = Transform3D(facing, at + Vector3(0.0, 0.02, 0.0) + facing.z * 1.0)
	if on and not _push_dust.emitting:
		_push_dust.restart()
		_push_dust.emitting = true
	elif not on:
		_push_dust.emitting = false


## The breaker's dust and chips, on at the bit while a bite runs, off after.
func set_breaker_dust(at: Vector3, on: bool) -> void:
	for p in [_breaker, _chips]:
		if p == null:
			continue
		p.global_position = at
		if on and not p.emitting:
			p.restart()
			p.emitting = true
		elif not on:
			p.emitting = false


## Limestone running off the tailgate while the bed is up.
## The stone leaving the tailgate: `at` is the bed's lip and `facing` the
## truck's own basis, so the curtain lies ACROSS the tail and falls out behind
## it however the truck is parked.
func gravel_at(at: Vector3, facing: Basis, _k: float) -> void:
	if _gravel == null:
		return
	# Behind the lip, not on it: on the bed's own pivot the stones were born
	# inside the bumper (round 3).
	_gravel.global_transform = Transform3D(facing, at - facing.z * 0.75 - Vector3(0.0, 0.05, 0.0))
	if not _gravel.emitting:
		_gravel.one_shot = false
		_gravel.emitting = true


func stop_gravel() -> void:
	if _gravel != null:
		_gravel.emitting = false


## The concrete stream on or off.
func set_pour(on: bool) -> void:
	if _stream != null:
		_stream.visible = on
	if not on and drive != null:
		drive.set_pour_mound(Vector3.INF)
	if _splat != null:
		_splat.one_shot = not on
		_splat.emitting = on


## Walks the pour's camera down the drive after the concrete, easing so the
## picture is never yanked and clamped so the form never leaves the frame.
##
## Along the drive ONLY. It does not follow the chute sideways and it never turns,
## so the swing the child is steering is the only thing that moves sideways on
## screen - which is the whole reason the round-1 chute-anchored shot failed.
func set_pour_view(z: float, delta: float) -> void:
	if _pour_view == null:
		return
	var want := clampf(z, Driveway.Z_APRON + 2.4, Driveway.Z_KERB - 0.6)
	var rate := clampf(delta * config.pour_view_rate, 0.0, 1.0)
	_pour_view.position.z = lerpf(_pour_view.position.z, want, rate)


func pour_view_z() -> float:
	return _pour_view.position.z if _pour_view != null else 0.0


## The come-along's camera point: it stands `behind` metres up-drive of the
## concrete's front, eased there at `rate` per second. The verb only calls this
## while the finger is UP, so the ground never moves under a finger.
func set_rake_view(front_z: float, behind: float, delta: float, rate: float = 2.2) -> void:
	if _rake_view == null:
		return
	# It may back INTO the garage (the door is open, the floor is at grade), so
	# that when the last unfilled row is the apron's the hint is still three
	# metres ahead of the eye and not under it.
	var want := clampf(front_z - behind, Driveway.Z_APRON - 2.4, Driveway.Z_KERB - 3.0)
	_rake_view.position.z = lerpf(_rake_view.position.z, want, clampf(delta * rate, 0.0, 1.0))


func rake_view_z() -> float:
	return _rake_view.position.z if _rake_view != null else 0.0


## The screed's camera point: on the board's line, which the verb moves down the
## drive as the board is pulled.
func set_screed_view(z: float) -> void:
	if _screed_view != null:
		_screed_view.position.z = clampf(z, Driveway.Z_APRON, Driveway.Z_KERB)


## The plate's camera point, on the plate (x and z; its eye stands behind it).
func set_plate_view(at: Vector3) -> void:
	if _plate_view != null and at != Vector3.INF:
		_plate_view.position = Vector3(at.x, Driveway.GRADE, at.z)


## Eases the plate's camera point after the plate - only between strokes (or
## under a world cursor), like the screed's.
func ease_plate_view(at: Vector3, dt: float, rate: float = 2.5) -> void:
	if _plate_view == null or at == Vector3.INF:
		return
	var want := Vector3(at.x, Driveway.GRADE, at.z)
	_plate_view.position = _plate_view.position.lerp(want, clampf(dt * rate, 0.0, 1.0))


func plate_view() -> Node3D:
	return _plate_view


## Is a screen point on the plate compactor: on its drawn machine (the head's
## box on the screen, grown by a finger), or dropped onto the base within reach
## of the plate (its half-size plus `tap_reach_m`)? ONE rule for the press and
## the grab, so an accepted press always picks it up and a refused one is a heard
## miss (the session-5 verification pass: a press on the orange cowl lands a
## metre behind the plate on the base, and was accepted and then never grabbed).
func plate_under(at: Vector2) -> bool:
	if drag_tool_at == Vector3.INF or camera == null or hud == null or at == Vector2.INF:
		return false
	var on := _screen_to_plane(at, Driveway.BASE_TOP)
	if on != Vector3.INF and Vector2(on.x - drag_tool_at.x, on.z - drag_tool_at.z).length() \
			<= Driveway.PLATE_HALF.y + config.tap_reach_m:
		return true
	var t := tool_node("plate")
	var head := t.find_child("Head", true, false) as MeshInstance3D if t != null else null
	if head == null or not head.is_visible_in_tree():
		return false
	var frame := get_viewport().get_visible_rect().size
	var box := head.global_transform * head.get_aabb()
	var rect := Rect2()
	var first := true
	for c in range(8):
		var p := hud.project_into(frame, box.get_endpoint(c))
		if p.z <= 0.0:
			return false
		rect = Rect2(Vector2(p.x, p.y), Vector2.ZERO) if first else rect.expand(Vector2(p.x, p.y))
		first = false
	return rect.grow(_finger_px()).has_point(at)


## Where the finger is on the screen right now (INF when none is down).
func touch_point() -> Vector2:
	return _touch_at if _touch_down else Vector2.INF


## Eases the screed's camera point toward the board's line - called only
## between strokes, so the ground never moves under a dragging finger.
func ease_screed_view(z: float, dt: float, rate: float = 2.5) -> void:
	if _screed_view == null:
		return
	var want := clampf(z, Driveway.Z_APRON, Driveway.Z_KERB)
	_screed_view.position.z = lerpf(_screed_view.position.z, want, clampf(dt * rate, 0.0, 1.0))


## Aims the stream: from the spout, down to where it lands.
func set_pour_point(from: Vector3, to: Vector3, dir: Vector3 = Vector3.DOWN) -> void:
	if _stream == null or not _stream.visible:
		return
	if dir != Vector3.DOWN:
		_stream_dir = dir
	# The pool's DRAWN colour under the spout, a step lighter, for the stream
	# and the splash (round 10: the material's colour while the pool was drawn
	# sandy with the depth tint).
	if drive != null and _stream_mat != null:
		# The stream is DARKER than the pool - wet mud in the air against
		# concrete settling pale under the sky - and its landing has a dark wet
		# rim: an EDGE, not a value tuned a step off the pool (round 13: a
		# step lighter rendered +6%, inside the surface's own noise).
		# Warm wet mud a shade under the pool for the stream; the tongue at
		# the landing a step LIGHTER and warmer (round 14: nothing dark is
		# drawn on the fresh pool - the rim was the chute's shadow by hand).
		var pool := drive.pool_colour_at(to)
		var warm := Color(pool.r * 1.05, pool.g, pool.b * 0.94)
		for i in range(_stream_mats.size()):
			_stream_mats[i].albedo_color = warm.darkened(0.16 - 0.02 * float(i))
		if _splash_mat != null:
			_splash_mat.albedo_color = warm.lightened(0.14)
		var mx := machine("ConcreteTruck")
		if mx != null:
			mx.set_chute_mud_colour(warm.darkened(0.06))
	var t_now := float(Time.get_ticks_msec()) / 1000.0
	var n := _stream_segs.size()
	# The stream ends on the SURFACE - the base before any concrete has landed,
	# the pool once it has - not at finished grade a hand above the gravel.
	if drive != null:
		# ON the crest's top, not at the pool's surface inside it: the crest
		# swallowed the stream's last segment and its whole splash (round 15).
		to.y = drive.crest_top(to)
	# A quadratic arc: thrown along the chute for the first part of the drop,
	# then falling. The control point is out along the chute's own direction.
	var flat := Vector3(_stream_dir.x, 0.0, _stream_dir.z)
	if flat.length_squared() < 0.0001:
		flat = Vector3.FORWARD
	# Thrown well out along the chute before it falls (round 12: from above
	# the rim the arc read as a post): the control point two thirds of the way
	# out and level with the lip.
	var ctrl := from + flat.normalized() * from.distance_to(to) * 0.65 + Vector3(0.0, 0.02, 0.0)
	for i in range(n):
		var seg := _stream_segs[i]
		var t0 := float(i) / float(n)
		var t1 := float(i + 1) / float(n)
		var p0 := from.lerp(ctrl, t0).lerp(ctrl.lerp(to, t0), t0)
		var p1 := from.lerp(ctrl, t1).lerp(ctrl.lerp(to, t1), t1)
		var chord := p1 - p0
		var cyl := seg.mesh as CylinderMesh
		# THIN at the lip - a fifth of what it was - and fanning at the landing,
		# so a 0.6 m fall is many times the stream's thickness and it reads as
		# a fall, not a post (round 8).
		cyl.top_radius = lerpf(0.035, 0.15, t0 * t0)
		cyl.bottom_radius = lerpf(0.035, 0.15, t1 * t1)
		# Overlapping, so the four are one continuous falling shape.
		cyl.height = chord.length() * 1.35
		var wob := Vector3(sin(t_now * 9.0 + float(i) * 1.7), 0.0, cos(t_now * 7.0 + float(i) * 2.3)) \
			* (0.008 + 0.012 * t1)
		seg.global_position = (p0 + p1) * 0.5 + wob
		# A cylinder stands along its Y: aim that along the chord.
		if chord.length_squared() > 0.0001:
			var up := chord.normalized()
			var side := up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
			seg.global_basis = Basis(side, up, side.cross(up))
	if _splash != null:
		# A TONGUE spreading along the stream's line, not a ring of balls
		# (round 12): the landing pad is stretched the way the concrete runs.
		_splash.global_position = to + Vector3(0.0, 0.012, 0.0)
		var fwd := flat.normalized()
		_splash.global_basis = Basis(fwd.cross(Vector3.UP).normalized(), Vector3.UP, fwd)
		_splash.scale = Vector3(1.0, 1.0, 1.8) * (0.92 + 0.10 * sin(t_now * 6.0))
		if _splash_rim != null:
			_splash_rim.global_position = to + Vector3(0.0, 0.006, 0.0)
			_splash_rim.global_basis = _splash.global_basis
			_splash_rim.scale = _splash.scale
	if _splat != null:
		_splat.global_position = to
		if drive != null:
			# A step LIGHTER than the pool: droplets catch the light, and a splash
			# the pool's exact colour is no splash at all.
			(_splat.process_material as ParticleProcessMaterial).color = drive.pool_colour_at(to).lightened(0.24)
	if drive != null:
		drive.set_pour_mound(to)


## What a machine at `at` rides on: the job's own surface, plus anything loose
## lying on it. Handed to every machine as `Machine.ground` and asked at its nose
## and its tail every frame, so a machine both SITS on the job and tips as it
## climbs - which is what the broken-out slab needed. "It looks like the skid
## steer goes through the rocks" was the user's note.
func _ground_y(at: Vector3) -> float:
	return drive.ride_y(at) if drive != null else 0.0


## Re-seats a machine on whatever it is standing on NOW. Kept for a verb that
## moves a machine by writing its z directly; every journey through `follow` or
## `drive_to` seats itself.
func reseat(m: Machine) -> void:
	if m == null or drive == null:
		return
	m.global_position.y = _ground_y(m.global_position)


func shake(amount: float) -> void:
	if camera != null:
		camera.shake(amount)


## A steady rattle while something keeps on shaking (the breaker's bite);
## 0 lets it die down.
func shake_floor(f: float) -> void:
	if camera != null:
		camera.hold_floor(f)


# --- Targets the runner asks for -------------------------------------------------------------

## Anything with a colon in it, plus whatever the driveway does not answer for.
## `Machine:DumpTruck` is that machine's WORKING END, which is the thing the
## child is watching and the thing a shot should hang off.
## The node a shot should hang off when the step's own target is the wrong
## thing to look at. The push aims its ARROW at the lane of rubble, which is
## right, but the picture belongs on the machine shoving it - otherwise the
## `MACHINE` shot anchors to the middle of the pad and crops the skid steer at
## the edge of frame with the arrow drawn on its flank.
func shot_anchor_override(step: JobStep) -> Node3D:
	if step == null:
		return null
	if step.verb == "push_rubble":
		return named_target("Machine:SkidSteer")
	if step.verb == "joint_cut":
		return drive.joint_marker(clampi(runner.done_in_step + 1, 1, drive.joint_count()))
	if step.verb == "broom_finish":
		return drive.bay_marker(clampi(runner.done_in_step + 1, 1, drive.bay_count()))
	if step.verb == "jack_spot":
		# The whole slab, not the one spot: all three rings have to be in the
		# picture at once, because all three are live and any of them may be next.
		# The runner re-asks for this every beat, so the eye walks up the drive
		# panel by panel as the slabs come out.
		return drive.panel_marker(drive.current_panel())
	if step.verb == "stake_drive":
		# The pair being driven now. Same rule, one place smaller. After the last
		# one the group is -1 for a frame: stay on the pair just driven rather
		# than falling back to WIDE - the pair JUST DRIVEN, not the last by
		# number, which after the first row is the kerb pair 9 m away (5.2).
		var g := drive.current_stake_group()
		if g < 0:
			g = drive.last_stake_group()
		if g < 0:
			g = drive.stake_group_count() - 1
		return drive.stake_group_mark(g)
	if step.verb == "rebar_lay":
		return drive.bar_group_mark(drive.current_bar_group())
	if step.verb == "form_set":
		var fg := drive.current_form_group()
		if fg < 0:
			fg = drive.last_form_group()
		if fg < 0:
			fg = drive.form_group_count() - 1
		return drive.form_group_mark(fg)
	return null


func named_target(want: String) -> Node3D:
	# The truck being backed in (1.8): the machine itself, not its working end.
	if want.begins_with("Back:"):
		return machine(want.substr(5))
	if want.begins_with("Machine:"):
		var kind := want.substr(8)
		var m := machine(kind)
		if m == null:
			return null
		return m.marker(String(WORKING_END.get(kind, "")))
	if want.find(":") >= 0:
		var bits := want.split(":", true, 1)
		var host := get_node_or_null(NodePath(bits[0])) as Node3D
		if host == null:
			return null
		return host.find_child(bits[1], true, false) as Node3D
	return find_child(want, true, false) as Node3D


# --- The payoff ------------------------------------------------------------------------------

## The driveway is finished: the child has taken the last board off. The tada
## and the YAY! answer that last tap, the bar is seen full on the wide the job
## opened on, and then the homeowner's car pulls in and parks on it.
##
## The cure and the strip are not here any more. Since the plan's fifth session
## the cure is a beat of the job (`SiteVerbs.slab_cure`: the cones across the
## mouth, the light to evening, the song down) and the boards are the child's to
## strip after it (`form_strip`, 5.3): what the child put in, the child takes
## out, and the celebration follows the child's last work, not the broom's.
func _celebrate() -> void:
	if _celebrating:
		return
	_celebrating = true
	# The job is done: nothing left to come back to (6.2). A tablet put down
	# during the payoff opens on a new driveway.
	if _saves:
		SaveGame.clear()
	job_done.emit()
	if hud != null:
		hud.hide_buttons()
		hud.show_pads([])
		# The bar is seen FULL - it reached its end under the finger, stepped
		# back - through the tada and the look at the finished drive.
		hud.set_chrome_target(1.0)
		hud.flash("YAY!", config.celebrate_time * 0.5)
	if sfx != null:
		sfx.play_group("tada")
	rig.go(CameraRig.WIDE, null)
	# A look back at the whole thing: the new drive, the boards on the grass
	# beside it, the cones still across its mouth.
	await get_tree().create_timer(config.payoff_look, false).timeout
	# Then the HUD steps out of the picture (3.3) - its own 0.2 s ease - before
	# the cut.
	if hud != null:
		hud.set_chrome_target(0.0, true)
	await get_tree().create_timer(0.25, false).timeout
	# The crew's kit goes at the CUT to the street, never in front of the child
	# (3.4). The car's arrival is watched from the STREET eye; the pulled-back
	# PAYOFF picture comes as it turns in (`_park_car`), with the cones lifted
	# out on the way.
	# A CUT, not an ease: the kit goes in the frame the picture changes, never
	# in front of the child while the eye is still swinging round.
	rig.snap(CameraRig.STREET, null)
	_clear_kit()
	await _park_car()
	if hud != null:
		# NEXT alone, in the corner a thumb has learned. The house stays off:
		# with NEXT up it could only mean the same thing twice.
		hud.show_next()
	ready_for_next.emit()


## LATER THAT DAY, as a beat of the job (`SiteVerbs.slab_cure`, before the child
## strips the forms). The cure is a SHAPE, not a light (the plan's 3.4): the
## cones go across the mouth of the drive first - a crew's "keep off", which
## every child knows - and stand there through the light sweep and the strip;
## the song goes quiet with the light. The HUD stays: the strip's three stops
## are still to come, and a bar locked out now would fill them unseen.
func cure_slab(seconds: float) -> void:
	await _cones_to_mouth(0.8)
	if sfx != null:
		sfx.fade_music(-30.0, seconds)
	await _tween_over(seconds, func(k: float) -> void: _cure(k))


## The light sweeps round and down, and the slab dries pale: a few seconds that
## say "later that day".
func _cure(k: float) -> void:
	# The crew loads the old drive out while the new one goes off, so the last
	# picture is the house, the drive and nothing else.
	# (Not `hide_rubble(k)` here any more: the heap left with the tipper five
	# beats ago, and a fade driven from k = 0 RE-SHOWED all forty-eight chunks
	# on the wide for the cure's first frame and dissolved them a second time -
	# the session-3 verification pass's first finding.)
	if drive != null:
		drive.set_wet(lerpf(0.25, 0.06, k))
	# And the garage shuts up for the night, so the last picture is a house with a
	# closed door and a car on a new drive rather than an open shell with a light
	# on in it.
	set_garage_door(1.0 - k)
	# (The fence, the tools and the heap used to FADE here, in front of the
	# child, on the wide. They go at the cut to the street now - `_clear_kit`,
	# the plan's 3.4: on a site things are carried off, nothing dissolves. The
	# cones stay, across the mouth of the drive, until the car turns in.)
	# The slab does not go to pine: the warmth the evening light adds to it is
	# taken back off its own colour (round 8: R-B went from +15 to +60 and the
	# finished drive was decking again in the one frame that lingers).
	if drive != null:
		drive.set_cure_tint(Color.WHITE.lerp(Color(0.86, 0.93, 1.0), k))
	if _sun == null:
		return
	# Low, long and warm - and the SKY and the fill go with it, or the light gets
	# harder rather than later (round 4).
	# The light stays: a low sun puts a third of the light on the ground, so
	# the fill comes UP as the sun comes down and the warmth alone says evening
	# (round 6: the reward was the darkest of twenty-eight frames).
	_sun.rotation = Vector3(deg_to_rad(lerpf(-48.0, -20.0, k)), deg_to_rad(lerpf(34.0, 70.0, k)), 0.0)
	_sun.light_color = Color(1.0, 0.97, 0.90).lerp(Color(1.0, 0.84, 0.64), k)
	_sun.light_energy = lerpf(1.25, 1.55, k)
	if _env != null:
		_env.ambient_light_color = Color(0.84, 0.82, 0.78).lerp(Color(0.90, 0.78, 0.68), k)
		_env.ambient_light_energy = lerpf(0.60, 1.05, k)
	if _sky != null:
		_sky.sky_top_color = Color(0.38, 0.60, 0.90).lerp(Color(0.26, 0.36, 0.62), k)
		_sky.sky_horizon_color = Color(0.78, 0.86, 0.94).lerp(Color(0.98, 0.74, 0.56), k)
		# The band the WIDE sees above the far edge of the lawn is the sky's
		# GROUND half (the lot ends below the horizon); it stayed daytime pale
		# while the sky went pink (round 7).
		_sky.ground_horizon_color = Color(0.64, 0.76, 0.58).lerp(Color(0.80, 0.66, 0.50), k)
		_sky.ground_bottom_color = Color(0.40, 0.58, 0.30).lerp(Color(0.34, 0.40, 0.26), k)


## Builds the car the first time it is wanted, and hands it the same ground the
## machines stand on so it sits ON the new slab rather than at y 0.
func _car() -> Machine:
	if car != null and is_instance_valid(car):
		return car
	car = Machine.new()
	car.name = "Car"
	car.kind = "Car"
	# The visit's car (6.1), in its own paint.
	car.model_path = VEHICLE_MODELS + String(look.get("car", "Hatchback")) + ".glb"
	add_child(car)
	car.setup(config)
	car.ground = _ground_y
	car.visible = false
	# On the middle of its own wheels: the model's origin was off its centre
	# and the car parked with a rear corner over the grass (round 6).
	car.centre_model_x()
	var paint: Color = look.get("paint", Color(0, 0, 0, 0))
	if paint.a > 0.0:
		_paint_named(car, "Equip_Paint", paint)
	return car


## The homeowner's car's voice (6.1): its own, or the plain horn when that clip
## is not on disk.
func car_voice() -> String:
	var v := String(look.get("voice", "voice_hatchback"))
	return v if sfx != null and sfx.loaded_count(v) > 0 else "horn"


## Recolours every surface under `root` whose material's name starts with
## `prefix`, on a COPY put in the surface's override (Car Garage's
## `Vehicle.paint`). An imported material is shared by every instance of its
## scene and cached across NEXT: painted in place, the next visit's car or house
## would arrive in this one's colour. By prefix, because Godot renames a
## duplicate "Equip_Paint2". Returns how many surfaces it painted.
func _paint_named(root: Node3D, prefix: String, c: Color) -> int:
	var painted := 0
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	for n in meshes:
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var live := mi.get_active_material(s) as BaseMaterial3D
			if live == null or not String(live.resource_name).begins_with(prefix):
				continue
			var dup := live.duplicate() as BaseMaterial3D
			dup.resource_name = live.resource_name
			dup.albedo_color = c
			mi.set_surface_override_material(s, dup)
			painted += 1
	return painted


## Puts the homeowner's car where it ends up, with no drive-in: the posed
## payoff, and the thing `_park_car` drives to. Parked with `Machine.place`, the
## same call that ends the drive-in, so the posed picture and the played one are
## the same picture. By its NOSE (6.1): the pickup is 1.4 m longer than the
## hatchback and parked at the hatchback's spot it stood in the garage door.
func _place_car_on_drive() -> void:
	var c := _car()
	c.visible = true
	c.place(drive.park_spot(c.nose_m()), 180.0)


## The homeowner's car comes up the street and turns onto the new drive.
##
## It DRIVES: `drive_route` rounds the corner off the street, `Machine.follow`
## points the nose down the path it is on and rolls the wheels by the distance
## they really cover, and `_seat` stands it on whatever is under it - the road,
## then the kerb, then the new slab.
##
## It used to be a straight slide up the street lerped into a straight slide up
## the drive, with the yaw lerped 90 -> 180 across the middle of it and the wheels
## dead still: "a lot of the vehicles just float and turn into the driveway", and
## after the machines were fixed, "why does the car at the end just float and turn
## in?". It was the last thing on the lot still moving that way.
func _park_car() -> void:
	var c := _car()
	c.visible = true
	var spot := drive.park_spot(c.nose_m())
	# Far enough up the street to be off the picture when it starts, and to have
	# room to straighten before the turn.
	# Facing the way it drives (STREET_YAW), so it does not spin on the spot.
	c.place(Vector3(Driveway.CENTRE_X + config.park_distance, 0.0, STREET_Z), STREET_YAW)
	if sfx != null:
		sfx.play_group("drive")
		sfx.play_loop("idle", "car")
	# The crew comes back for the cones while the car is still up the street.
	_lift_cones()
	await drive_route(c, [c.global_position,
		Vector3(Driveway.CENTRE_X, 0.0, STREET_Z),
		Vector3(Driveway.CENTRE_X, 0.0, KERB_Z - 0.6)],
		config.park_time * 0.6, false, config.park_turn_r)
	rig.go(CameraRig.PAYOFF, drive.marker("Slab"))
	await drive_route(c, [c.global_position, spot], config.park_time * 0.4, false, config.park_turn_r)
	if sfx != null:
		sfx.stop_loop("car")
		# The car says thank-you in its OWN voice (the plan's 3.3), Car
		# Garage's way: a toot `horn_delay` after it stops and another
		# `horn_gap` later. It parked to the pour's chime before; a child
		# remembers the beep, and it is the same car the garage taught them.
		var voice := car_voice()
		for n in range(maxi(config.horn_toots, 1)):
			# The second toot waits for the first to SOUND OUT: at `horn_gap`
			# 0.45 s a 1.5 s voice clip was started twice inside itself.
			var gap := config.horn_delay if n == 0 else maxf(config.horn_gap, float(sfx.last_length))
			await get_tree().create_timer(gap, false).timeout
			sfx.play_group(voice)
			# A tap on the car while it toots waits for the toot, too.
			_honk_at_s = _now_s()
			_car_voice_len = float(sfx.last_length)
		# NEXT comes up after the last toot has SOUNDED, not after it has
		# started: the voice clips run a second and a half.
		await get_tree().create_timer(maxf(0.3, float(sfx.last_length)), false).timeout


## The two cones, which stand on the footway while the crew works and go
## ACROSS the mouth of the drive for the cure (the plan's 3.4).
func _cone_posts() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in ["ConeL", "ConeR"]:
		var c := get_node_or_null(n) as Node3D
		if c != null:
			out.append(c)
	return out


## Where cone `i` stands while the slab cures: in FRONT of the slab, on the
## kerb crossing (the slab ends at `Driveway.Z_KERB`; the crossing runs on to
## the road), one each side of the centre line, at grade. A cone standing on
## the wet concrete it is guarding says the opposite of the lesson, and the
## footway the cones came from is 9.5 cm proud of the crossing.
func _cone_mouth(i: int) -> Vector3:
	return Vector3(Driveway.CENTRE_X + (-1.1 if i == 0 else 1.1), 0.0, Driveway.Z_KERB + CONE_MOUTH_OUT)


## Slides the cones to the mouth of the drive at the kerb, one each side of its
## centre line: a crew's "keep off", a shape every child knows from the road.
func _cones_to_mouth(seconds: float) -> void:
	var cones := _cone_posts()
	if cones.is_empty():
		return
	var from: Array[Vector3] = []
	var to: Array[Vector3] = []
	for i in range(cones.size()):
		from.append(cones[i].global_position)
		to.append(_cone_mouth(i))
	await _tween_over(seconds, func(k: float) -> void:
		for i in range(cones.size()):
			if is_instance_valid(cones[i]):
				cones[i].global_position = from[i].lerp(to[i], k))


## The crew comes back for the cones as the car turns in: they lift out under
## the STREET eye, before the car reaches the turn. Runs alongside `_park_car`.
func _lift_cones() -> void:
	await get_tree().create_timer(1.2, false).timeout
	var cones := _cone_posts()
	if cones.is_empty():
		return
	var from: Array[Vector3] = []
	for c in cones:
		from.append(c.global_position)
	await _tween_over(0.6, func(k: float) -> void:
		for i in range(cones.size()):
			if is_instance_valid(cones[i]):
				cones[i].global_position = from[i] + Vector3(0.0, 0.6 * k, 0.0))
	for c in cones:
		if is_instance_valid(c):
			c.visible = false


## The crew's kit - the fence, the tools, whatever is left of the heap - goes at
## the CUT to the street, never in front of the child: on a site things are
## carried off, nothing fades (the plan's 3.4). One knock: the van's door. In
## play the cones stay for `_lift_cones`; a POSED payoff (the shot harness's
## `parked` stage) takes them too, silently, so the posed picture is the one
## the child sees at the end.
func _clear_kit(posed: bool = false) -> void:
	for prop in _site_kit:
		if prop == null or not is_instance_valid(prop):
			continue
		if not posed and String(prop.name) in ["ConeL", "ConeR"]:
			continue
		prop.visible = false
	for kind: String in tools:
		var t := tools[kind] as Node3D
		if t != null and is_instance_valid(t):
			t.visible = false
	if drive != null:
		drive.hide_rubble(1.0)
		# And the boards the child stripped, off the grass with their pegs (5.3).
		drive.carry_off_forms()
	if sfx != null and not posed:
		sfx.play_group("clunk")


## The opening look at the wide is over - its time ran out, or the child
## touched something: the eye eases down to the first slab (the plan's 3.1).
func _end_opening() -> void:
	if not _opening:
		return
	_opening = false
	var s := runner.current_step() if runner != null else null
	if s != null and rig != null:
		rig.go(s.shot, runner.shot_anchor(s.shot), config.opening_ease)


## Eases 0..1 over `seconds`, calling `on_k` every frame.
func _tween_over(seconds: float, on_k: Callable) -> void:
	var t := 0.0
	var total := maxf(seconds, 0.05)
	while t < total:
		t = minf(t + get_process_delta_time(), total)
		var k := t / total
		on_k.call(k * k * (3.0 - 2.0 * k))
		await get_tree().process_frame
	on_k.call(1.0)


## NEXT: back to the title row, where the next visit is chosen (6.3). The save
## is gone (the job it held is finished) and the finished visit's seed is left
## behind for the title's backdrop.
func _on_next() -> void:
	if hud != null:
		hud.clear_flash()
	if _saves:
		SaveGame.clear()
	# The finished visit is left for the title's backdrop, so the drive the
	# child just built - with the car on it - is what stands behind the next
	# choice (6.3). The NEXT VISIT is drawn at the seat's press, not here: a
	# seed drawn now would be one the title had already used for its picture.
	Engine.set_meta(LAST_SEED_META, play_seed)
	if sfx != null:
		sfx.stop_all()
	if leave_scene.is_valid():
		leave_scene.call()
	elif get_tree().current_scene == self and ResourceLoader.exists(TITLE_SCENE):
		get_tree().change_scene_to_file(TITLE_SCENE)
	else:
		next_requested.emit()


func _on_home() -> void:
	# The house goes to the title row now (6.3) - but never while a job is
	# running: one tap on the biggest green thing on the screen threw sixty
	# stops of a child's work away (the improvement plan's 0.1, 2026-09-15). The
	# button is still off the screen until the payoff (`SiteHud.hide_home`);
	# this guard is for the signal, so nothing reaches the cut from a running
	# job by any route. 0.1 will give it a press-and-hold - the widget the
	# title's own "new drive" disc already is - and the job is saved by then.
	if runner != null and not runner.finished:
		return
	_on_next()


# --- The save: the job survives the app closing (6.2) ------------------------------------------

## Does this run read and write the save? The child's game does. A harness
## (anything that set `shot_args`) does only if it pointed the save at a
## scratch file, and a POSED run never does: a picture must not resume a job,
## and must not write one.
func saves_on(args: Dictionary) -> bool:
	# A backdrop is nobody's game: it must not resume the child's job into the
	# picture behind a menu, and must never write over it.
	if dress_only:
		return false
	if not SaveGame.enabled or args.has("stage"):
		return false
	return SaveGame.path_override != "" or not Engine.has_meta("shot_args")


## Which of step `i`'s verb's rows it is (the second `form_set` is 2): the save
## names a row by verb and this, never by number (session 5's rule).
func row_nth(i: int) -> int:
	var n := 0
	for k in range(mini(i, job.steps.size() - 1) + 1):
		if job.steps[k].verb == job.steps[i].verb:
			n += 1
	return n


## The stage a resumed step stands on: of the stages, the last one posed at or
## before it (`STAGE_STEP`). Rebar's mixer call and its back-in stand on
## `rebar`, the tip on `staked`; the strip on `cured`.
func stage_for_step(i: int) -> String:
	var best := "old"
	var best_at := -1
	for st: String in Driveway.STAGE_ORDER:
		if st == "done" or st == "parked" or not STAGE_STEP.has(st):
			continue
		var at := stage_step(st)
		if at <= i and at > best_at:
			best = st
			best_at = at
	return best


## Which places of step `i`'s row are done, read off the world, as the save
## keeps them: the hammer's spots, the boards, the pegs, the bars and the
## stripped boards, for the rows a child takes in ANY order - a count cannot
## say the child laid bars 3 and 1. Ordered group by group, so posing them back
## in this order is always a legal pick (`_apply_places`). [] for every other row.
func done_places(i: int) -> Array:
	var out: Array = []
	if job == null or drive == null or i < 0 or i >= job.steps.size():
		return out
	var kerb_row := row_nth(i) > 1
	var keyed: Array = []
	match job.steps[i].verb:
		"jack_spot":
			for n in range(1, drive.jack_spots() + 1):
				if drive.spot_done(n):
					keyed.append([n, n])
		"form_set":
			for b in range(1, drive.form_count() + 1):
				if drive.form_is_in(b) and (b == Driveway.KERB_BOARD) == kerb_row:
					keyed.append([drive.form_group(b) * 100 + b, b])
		"stake_drive":
			for n in range(1, drive.stake_count() + 1):
				if drive.stake_is_in(n) and (drive.stake_board(n) == Driveway.KERB_BOARD) == kerb_row:
					keyed.append([drive.stake_group(n) * 100 + n, n])
		"rebar_lay":
			for n in range(1, drive.bar_count() + 1):
				if drive.bar_is_in(n):
					keyed.append([drive.bar_group(n) * 100 + n, n])
		"form_strip":
			for b in drive.strip_boards():
				if drive.form_is_stripped(b):
					keyed.append([b, b])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	for k in keyed:
		out.append(int(k[1]))
	return out


## The document the save holds for where the child is now. Nothing about when.
func save_doc() -> Dictionary:
	var i := runner.index
	return {"job": _job_file, "rows": job.steps.size(), "verb": job.steps[i].verb, "nth": row_nth(i),
		"done": runner.done_in_step, "places": done_places(i), "seed": play_seed}


## Writes where the child is (on every step entered and every beat landed,
## `JobRunner.place_changed`). Never once the job is over.
func _write_progress() -> bool:
	if not _saves or runner == null or job == null or drive == null or runner.finished or _celebrating:
		return false
	if runner.index < 0 or runner.index >= job.steps.size():
		return false
	return SaveGame.save_data(save_doc())


## Where a saved document resumes, or {} for a fresh driveway: `{step, done,
## places, seed}`. Refused whole when it is not this job, not this many rows
## (an update added a beat), names no row, or carries no seed. A row whose work
## was all done, or a row that plays by itself (a machine leaving, the cure),
## resumes at the next row the child works - the leave has already happened as
## far as the child is concerned. Past the last row there is nothing to resume.
## `places` that do not match `done` are dropped for the canonical order.
func resume_point(doc: Dictionary) -> Dictionary:
	if doc.is_empty() or job == null:
		return {}
	if String(doc.get("job", "")) != _job_file:
		return {}
	if not _whole(doc.get("rows")) or int(doc["rows"]) != job.steps.size():
		return {}
	if not _whole(doc.get("nth")) or not _whole(doc.get("done")):
		return {}
	var seed := SiteLook.parse_seed(doc["seed"]) if _whole(doc.get("seed")) else -1
	if seed < 0:
		return {}
	var i := job.index_of(String(doc.get("verb", "")), maxi(int(doc["nth"]), 1))
	if i < 0:
		return {}
	var done := clampi(int(doc["done"]), 0, job.steps[i].count)
	var places: Array = []
	var raw: Variant = doc.get("places", [])
	if raw is Array:
		for v in raw:
			if not _whole(v):
				places = []
				break
			places.append(int(v))
	while i < job.steps.size() and (done >= job.steps[i].count or job.steps[i].kind == JobStep.Kind.AUTO):
		i += 1
		done = 0
		places = []
	if i >= job.steps.size():
		return {}
	if places.size() != done:
		places = []
	return {"step": i, "done": done, "places": places, "seed": seed}


## A JSON number that is a whole number (the parser hands every number back as
## a float).
func _whole(v: Variant) -> bool:
	return (v is int or v is float) and float(v) == floor(float(v))


## Opens a saved job where it was left (6.2): the world posed as play leaves it
## when that row opens (`pose` with `play`), the places the child had done, and
## what play has running there that a pose does not start. It opens on the WIDE,
## as a fresh job does - the child sees their own site first - except where a
## wide is wrong: the pour and the come-along (the truck is undrawn: a chute
## hanging in the road), the drags (a press during the swoop moves the work
## under a still finger) and the back-ins (the truck waits off the wide's
## picture), which open on their own shots. A HOLD resumes at its own start: a
## half-poured band, a half-packed bay or a half-backed truck starts that beat
## again.
func resume(point: Dictionary) -> void:
	var i := int(point["step"])
	var done := int(point["done"])
	var s := job.steps[i]
	pose(stage_for_step(i), i, done, point.get("places", []) as Array, true)
	match s.verb:
		"back_dump", "back_mixer":
			# Waiting in the road with its engine ticking over, as the street leg
			# leaves it.
			if sfx != null:
				sfx.play_loop(SiteVerbs.SOUND_IDLE, "arrive")
		"form_strip":
			# The song is down for the evening, where the cure left it.
			if sfx != null:
				sfx.fade_music(-30.0, 0.05)
	# Mid-row, the hammer or the sledge stands wound up over the next place, as the
	# verb's own pose has it: left on the lawn, the next blow jumped it a metre
	# and a half in a frame (the session-6 verification pass).
	if done > 0 and (s.verb == "jack_spot" or s.verb == "stake_drive"):
		_pose_tool(s)
	# The pour, the come-along, every drag and the back-ins open on their OWN
	# shot. A finger pressed during the opening's swoop would be read through a
	# moving camera - a drag beat moves its work under a still finger - and a
	# truck waiting in the road is off the WIDE's picture.
	if s.verb == "pour_chute" or SiteVerbs.SCRUB_VERBS.has(s.verb) or SiteVerbs.BACK_VERBS.has(s.verb):
		runner.go_shot(s.shot, false)
	else:
		rig.snap(CameraRig.WIDE, null)
		_opening = true
		_opening_left = config.opening_hold
	print("RESUME step %d %s done %d places %s seed %d" % [i, s.verb, done, str(point.get("places", [])), play_seed])
	_write_progress()


## Lays `done` places of a row that takes them in any order: each one named in
## `want` while it is a legal pick now (on the panel being broken, in the group
## being set), and the first open place for the rest. A save that names places
## no child could have reached still resumes, on the canonical ones. Returns how
## many it laid.
func _apply_places(verb: String, want: Array, done: int) -> int:
	var left: Array = want.duplicate()
	var laid := 0
	while laid < done:
		var open := _open_picks(verb)
		if open.is_empty():
			break
		var pick := open[0]
		for w in left:
			if open.has(int(w)):
				pick = int(w)
				left.erase(w)
				break
		match verb:
			"jack_spot":
				drive.jack_spot(pick, 1.0)
				if drive.panel_ready(drive.spot_panel(pick)):
					drive.break_panel(drive.spot_panel(pick), false)
			"form_set":
				drive.set_form(pick, 1.0)
			"stake_drive":
				drive.set_stake(pick, 1.0)
			"rebar_lay":
				drive.show_chairs(true)
				drive.set_bar(pick, 1.0)
			"form_strip":
				drive.strip_form(pick, 1.0)
		laid += 1
	return laid


## The places a child may pick next on a row, by the world's state.
func _open_picks(verb: String) -> PackedInt32Array:
	match verb:
		"jack_spot":
			return drive.open_spots(drive.current_panel())
		"form_set":
			return drive.open_forms_in(drive.current_form_group())
		"stake_drive":
			return drive.open_stakes_in(drive.current_stake_group())
		"rebar_lay":
			return drive.open_bars_in(drive.current_bar_group())
		"form_strip":
			return drive.open_strip_forms()
	return PackedInt32Array()


# --- Plumbing -------------------------------------------------------------------------------

func _load_job(want: String) -> JobDef:
	var path := JOB_DIR + want + ".tres"
	if not ResourceLoader.exists(path):
		push_error("SiteMain: no job at %s" % path)
		return null
	return ResourceLoader.load(path) as JobDef


func job_steps() -> int:
	return job.steps.size() if job != null else 0


func is_celebrating() -> bool:
	return _celebrating


func _box(box_name: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	bm.material = mat
	mi.mesh = bm
	mi.position = at
	return mi
