class_name Driveway
extends Node3D
## The thing the whole job is about: one residential driveway, from the cracked
## old slab to a broomed new one (DESIGN 1, 2).
##
## It is built in code rather than modelled, because every phase CHANGES it:
## panels crack and come apart, chunks are pushed away, boards stand round the
## hole, gravel fills it, concrete is poured into a grid of cells that then gets
## flattened, grooved and brushed. A GLB cannot do any of that; a few hundred
## boxes can, and boxes are exactly the right shape for all of it.
##
## Everything here is GEOMETRY and STATE. How fast any of it happens is
## `SiteConfig`, and WHEN is `SiteVerbs`.
##
## ## The levels, all measured from finished grade (y = 0)
##
##      +0.00  the top of the new slab, and the top of the form boards, so the
##             screed board rides the forms - which is how the real job works
##      -0.10  the bottom of the new slab / the top of the gravel base
##      -0.20  the dirt the old slab was dug out to
##
## The old slab sat 0.12 thick with its top at grade, so breaking it out leaves
## a hole the base and the slab together fill back up. A child never sees a
## number, but they do see the forms standing a hand's width out of the dirt and
## the concrete coming up level with their tops.

## A panel has come apart (the jackhammer finished it).
signal panel_broken_up(index: int)
## Every chunk of the old drive has been pushed off the pad.
signal pad_cleared
## The form is full: every cell of the slab is up to grade.
signal form_full

# --- The lot --------------------------------------------------------------------------------

## The pad: 3.6 m across, 9.0 m from the garage apron down to the kerb.
static var WIDTH := 3.6
static var LENGTH := 9.0
## Where it sits: the middle of the pad in world x, and the z of its two ends.
## +Z is toward the street, so `Z_KERB` is the bottom of the drive.
static var CENTRE_X := 2.6
static var Z_APRON := -3.4
static var Z_KERB := 5.6

## The old slab: three panels up the drive by two across, each 1.8 x 3.0.
## Two by two, not two by three (the user, 2026-09-14: "this takes too long
## being 6 sections.. just make it 4 large sections"): twelve bites, not
## eighteen.
static var PANELS_X := 2
static var PANELS_Z := 2
const SLAB_T := 0.12
## How wide the saw-cut gap between two old panels reads, metres. Real joints,
## so the old drive is SLABS and not one painted rectangle.
const PANEL_GAP := 0.04

## The hole, the base and the new slab. These three are LEVELS, not the slab's
## rectangle, and they stay `const` on purpose: grade is 0.0 by definition, and
## a sidewalk flag is the same 100 mm slab on the same 100 mm base as a
## driveway. 183 of the references to this block are these three; none of them
## is a thing a job can differ in.
const DIG := 0.20
const BASE_TOP := -0.10
const GRADE := 0.0

## The new slab's fill grid. Six cells across by twelve up the drive: fine
## enough that a swept chute lays a band rather than filling a quarter of the
## drive at once, coarse enough that 72 boxes is nothing to draw.
static var CELLS_X := 6
static var CELLS_Z := 12

## How many loose stones are scattered over the finished base.
## 420 small ones rather than 300 big ones: at 0.23 m across and tilted 16 degrees
## they caught the sun on one face and read as scattered shards, not as a bed.
const STONES := 420
## How many chunks one broken panel becomes. Eight reads as "that slab came
## apart" while staying cheap enough to push around.
const CHUNKS_PER_PANEL := 12
## How many places on a panel the hammer is worked, and so how many cracks grow
## across it. THREE, in three different places, because one panel broken by
## tapping the same spot over and over was the user's second note: "make it 3
## clicks per section in three different spots". Each spot cracks its own third
## of the slab and the panel lets go when all three are done.
static var SPOTS_PER_PANEL := 3
## How many boxes one crack is drawn with. A crack in concrete does not run
## straight - it steps left and right round the aggregate - so every crack in this
## file is a ZIGZAG of this many short segments, revealed one at a time as the
## hammer works, so the crack visibly RUNS rather than appearing.
const CRACK_SEGMENTS := 7
## How far each joint of a zigzag kicks off the straight line, metres.
const CRACK_JAG := 0.085
## WEEDS in the old cracks (the improvement plan's 4.1): green on grey is the
## highest-contrast thing a child reads, and a weed growing out of a crack says
## "this is old and broken" from the wide, where ink lines and tint patches said
## nothing at tablet distance. A tuft is a few leaning blades on a flat rosette,
## at a joint of an old crack, clear of the hammer's spots. A value step darker
## than the slab as well as a hue step - the lawn's own green is the slab's value.
## 14 cm tall: 10.5 cm is six pixels at the far corner of the wide, 13 m away.
## Geometry, so consts: the drive is built before any SiteConfig reaches it.
const WEED := Color(0.34, 0.58, 0.18)
const WEED_DARK := Color(0.20, 0.40, 0.12)
const WEEDS_PER_PANEL := 4
const WEED_BLADES := 5
const WEED_H := 0.14
const WEED_W := 0.035
const WEED_CLEAR := 0.45
## And the first slab has SETTLED along the centre seam: the base washed out under
## the joint and its edge dropped a step below its neighbour's, so the seam beside
## the first rings is a STEP and not a line (4.1). Down, not heaved up: both working
## eyes stand on the lawn side at the kerb end, and a raised edge's riser faces away
## from them; a dropped edge shows the neighbour's shadowed face, the whole seam long.
const SETTLED_PANEL := 1
const SETTLE_STEP := 0.05

## Where the rubble ends up: a heap on the grass beside the kerb, off the pad,
## which is where a real crew drops it for the skip.
##
## Just off the drive's own right-hand edge at the kerb end, and not 2.8 m out on
## the lawn: the skid steer pushes each load down to the kerb and then makes one
## short right turn to shove it onto the heap, so the heap has to be within a
## turn of the end of the drive or the load has to teleport there.
const PILE_X := 6.6
const PILE_Z := 2.6

## The colours. Old concrete is greyer and dirtier than new; wet concrete is
## darker than dry, which is the whole reason a child can see the pour happen.
const OLD_CONCRETE := Color(0.60, 0.59, 0.56)
const OLD_CONCRETE_DARK := Color(0.44, 0.43, 0.41)
const CRACK_INK := Color(0.17, 0.17, 0.18)
const DIRT := Color(0.38, 0.29, 0.20)
## The lawn's green, for the trench that is turfed over when the forms come
## off. Matches `SiteMain._build_ground`.
const LAWN := Color(0.42, 0.62, 0.30)
## Crushed limestone, taken well down and warmer than the concrete that covers
## it. At 0.69 it sat between the fresh pour (0.72) and the footway (0.72) and
## the child's longest two phases changed the picture by three per cent: the base
## looked poured and the pour looked like the base.
## Warmer and paler than the wet concrete that goes over it, so the base and the
## pour are two different materials at a glance: crushed limestone is a warm
## tan-grey, fresh concrete a cool dark one.
const GRAVEL := Color(0.63, 0.56, 0.45)
## The same limestone PACKED by the plate (5.1): a luma step paler, the same hue
## - about +14% luma, which the water's -13% taught is the size of step a child
## reads as "this part is done".
const GRAVEL_PACKED := Color(0.70, 0.64, 0.54)
## A cell counts as packed, and takes the whole step, from here; below it the
## bed only warms toward the step, so the edge of the plate's path is an edge.
const PACK_STEP := 0.90
## How far a packed stone's own colour is taken toward white, for the same step.
const PACK_LIGHTEN := 0.14
## A packed stone lies with its top this far over the base: above the landing
## marks (+4 mm) and below the chairs' feet (+8 mm), so no two faces share a
## plane (the flicker rule).
const STONE_FLAT_PROUD := 0.006
## The packed bed's overlay, 2 mm over the base's top while the plate works.
const BED_Y := 0.002
## Half the plate's footprint (across, along), for keeping it inside the forms.
const PLATE_HALF := Vector2(0.28, 0.30)
## What a cell the come-along still has to fill is drawn toward: dark wet mud.
const SHORT_COL := Color(0.40, 0.37, 0.32)
## Fresh concrete is DARK. It rendered nearly white (round 3, every pour frame)
## because `wet_poured` was 0.35 - two thirds of the way to the dry colour -
## so the child's centrepiece looked like the finished slab from its first
## second. Cool and deep, a long way from the base under it.
## 0.50, not 0.40: at 0.40 it was 2% off the ROAD (0.38) in the same hue,
## and the whole second half of the game played on tarmac (round 7). Sampled
## against the three surfaces it is seen beside: the road (0.38) well below,
## the footway (0.64) and the cured slab (0.70) above, the warm base (0.63,
## 0.56, 0.45) across the hue from it.
const WET_CONCRETE := Color(0.50, 0.51, 0.55)
## Paler and warmer than the council's footway grey (0.72, 0.71, 0.67), because
## a new pour really is, and because the payoff of the whole job is the child
## seeing that this drive is NEW: at a shade off the footway the finished slab
## read as another piece of pavement.
## NEUTRAL, and only a step above the footway (0.64): warmed to 0.84 it was
## 65% brighter than the footway, within 8% of a painted wall, and read as
## decking for three rounds (round 6). New concrete is pale grey, not cream.
const DRY_CONCRETE := Color(0.70, 0.70, 0.69)
## Lighter than the earth it stands in, or a form board is a shadow on a bank.
const TIMBER := Color(0.80, 0.60, 0.34)
const TIMBER_DARK := Color(0.46, 0.32, 0.18)
## The expansion joint against the garage apron: fibreboard, dark.
const FIBRE := Color(0.24, 0.20, 0.17)
## A form stake is sawn timber a step paler than the board it pins, with its top
## dipped in survey PINK - the one hue nothing else on the site has: the board's
## edge beside it, the chairs and the cones are orange and the rings gold, so an
## orange cap read as one more chair (the improvement plan's 4.2). Grey, the
## ten stubs the child leaves down the boards were grey specks on the lawn line.
const STAKE_TIMBER := Color(0.86, 0.72, 0.52)
const STAKE_PINK := Color(0.95, 0.24, 0.62)
## The reinforcement (DESIGN 2d): rusty steel bars, grey plastic chairs that hold
## them up off the base, and the black tie wire at every crossing.
const REBAR := Color(0.50, 0.27, 0.16)
const REBAR_DARK := Color(0.36, 0.19, 0.11)
## Orange plastic, which nothing else on the base is: at tablet distance a grey
## 3 cm cube on tan stone read as litter (round 4).
const CHAIR := Color(0.93, 0.47, 0.14)
const TIE := Color(0.16, 0.16, 0.17)
## Four bars up the drive, eight across it, on chairs, tied where they cross.
## Sparser than a real 45 cm grid on purpose: twelve taps is a phase, forty is a
## chore, and a four-year-old cannot see a 16 mm bar from a metre away anyway.
static var BARS_ALONG := 4
static var BARS_ACROSS := 8
## Saw-cut joints across the finished slab; bays are joints + 1. How many groups
## the form boards are worked in. Stakes to a LONG board and to a SHORT one.
## All five come from the job's `SlabSpec` (6.5): a three-metre flag and a
## nine-metre drive disagree about every one of them.
static var JOINTS := 2
static var FORM_GROUPS := 3
static var STAKES_PER_LONG := 4
static var STAKES_PER_SHORT := 2
const BAR_T := 0.020
## How far a bar stops short of the form, either end (the cover).
const BAR_COVER := 0.16
## How far the long bars sit up off the base on their chairs. The bars end up
## in the MIDDLE of the slab, which is the whole reason for the chairs and the
## thing the phase teaches; the cross bars lie on top of the long ones.
## 45 mm, not 36: at the BARS eye a 36 mm chair was eight pixels of lift for
## a phase whose whole lesson is the lift (round 8). With 20 mm bars the cross
## bar's top still sits 15 mm under the finished surface.
const CHAIR_H := 0.045
## Bars closer than this along the drive are one group for the camera and the
## rings: the four long bars, then the cross bars in pairs.
const BAR_GROUP_Z := 1.3
## How tall a form stake is, how far it stands proud before it is driven, and
## how far it is left standing above the board once it is: a driven stake that
## finishes flush leaves no mark at all, and ten of the child's stops produced
## an unchanged picture (round 3). The stakes stand OUTSIDE the boards, so a
## stub there never meets the screed.
const STAKE_H := 0.46
const STAKE_PROUD := 0.30
const STAKE_STUB := 0.05
## The painted cap: a hand's width of pink at the top, so a driven stake's 5 cm
## stub is ALL cap - the ten bright dots down the boards in every later wide.
const STAKE_CAP := 0.06
## The cap's centre in the stake's own frame: 3 mm above the peg's top and 6 mm
## wider, so none of its faces is coplanar with the peg's (the flicker rule).
const STAKE_CAP_Y := STAKE_H * 0.5 - STAKE_CAP * 0.5 + 0.003
## A waiting bar's skew off its line: how far beside it, and how far its END
## swings off the line - a DISTANCE, so a long bar and a cross bar swing the
## same hand's width (round 13: 12 degrees on an 8.7 m bar was 0.9 m at the
## end, and two of the four long bars crossed in an X).
const BAR_SKEW_OFF := 0.24
const BAR_SKEW_END := 0.20
const BAR_SKEW_END_LONG := 0.35
## The two OUTER long bars swing less: 0.26 m of base lies between one and its
## form's inner face, and its far end swings outward (session 4).
const BAR_SKEW_END_LONG_OUTER := 0.20

var config: SiteConfig

## Panel index -> {node, marker, chunks, broken, jacked}
var _panels: Array = []
## Every loose chunk of old concrete still on the pad.
var _chunks: Array[Node3D] = []
## How far the heap has been hidden so far (0..1): `hide_rubble` never goes back.
var _rubble_hidden: float = 0.0
## The stakes, cut into groups across the drive (`_group_stakes`): 1-based stake
## numbers, in order from the garage end to the kerb.
var _stake_groups: Array[PackedInt32Array] = []
## The board across the street end (5.2): the trucks back through it, so it and
## its two pegs go in after the base.
const KERB_BOARD := 3
## The strip's schedule, as fractions of one board's beat (`strip_form`).
const STRIP_PULL_END := 0.25
const STRIP_PRY_END := 0.40
const STRIP_LIFT_END := 0.70
## How far a peg is drawn up: its foot to the trench floor, 9 cm down, so a
## pulled peg stands in the trench and does not float over it.
const STAKE_PULL := 0.32
## The crew's pile of stripped boards on the right lawn (5.3): the first board's
## middle, the step to the next, and how high a long board is lifted as it is
## carried there over the slab and the tools.
const STRIP_PILE_X := 6.8
const STRIP_PILE_GAP := 0.3
const STRIP_PILE_Z := -0.12
const STRIP_ARC := 0.45
var _last_form_group: int = -1
var _last_stake_group: int = -1
## A marker in the middle of each group, for the camera to hang off.
var _stake_group_marks: Array[Node3D] = []
var _cleared_emitted: bool = false
## How many chunks are on the heap, for stacking the next on top.
var _piled: int = 0
## Where each chunk lay before the crew started loading it out (`hide_rubble`).
var _pile_y: PackedFloat32Array = PackedFloat32Array()

var _dirt: MeshInstance3D
var _clods: Array[MeshInstance3D] = []
var _ruts: Array[MeshInstance3D] = []
## The four earth walls of the excavation, hidden until it IS one.
var _banks: Array[Node3D] = []
var _gravel: MeshInstance3D
var _gravel_k: float = 0.0
## The stones lying on the base. A flat box of one grey was the whole of the
## limestone before ("rock texture is very poor at the moment"); what makes a
## crushed base read as crushed is hundreds of separate lumps with their own
## shadows.
var _stones: Array[MeshInstance3D] = []
## Each stone as it was tipped (its tilt, height, colour and cell), so packing is
## a pure function of how packed its cell is, and the stones in each cell.
var _stone_rest: Array = []
var _cell_stones: Array[PackedInt32Array] = []
## How packed each base cell is, 0..1 (5.1), and the overlay that draws it.
var _packed: PackedFloat32Array = PackedFloat32Array()
var _bed: MeshInstance3D
var _bed_dirty: bool = false
var _packed_any: bool = false
var _pack_baked: bool = false

## The four form boards and their stakes.
var _forms: Array = []
var _stakes: Array = []

## The slab: a `CELLS_X * CELLS_Z` grid of fill heights above BASE_TOP, drawn as
## ONE continuous surface (`_slab`, rebuilt from `_fill` whenever it changes).
##
## It was seventy-two separate boxes, and in every frame of the pour they read
## as a floor of loose paving slabs at different heights with cracks between
## them - a heap of wet concrete has no edges inside it. A heightfield with the
## cell heights blended at the corners, smooth-shaded, coloured per vertex, is a
## surface: the pour is a mound that creeps, the screed leaves a plane, and the
## water and the broom are patches on it rather than a checkerboard.
var _slab: MeshInstance3D
var _slab_mat: StandardMaterial3D
var _slab_dirty: bool = false
var _fill: PackedFloat32Array = PackedFloat32Array()
## What each cell wants to look like RIGHT NOW: the slab's own wetness, then the
## water it has had, then the brushing. One colour per cell, blended at the
## corners when the surface is built, so a wet patch has a soft edge.
var _cell_col: PackedColorArray = PackedColorArray()
var _base_col: Color = Color(0.5, 0.5, 0.5)
## A multiplier on the slab's colour the cure sets, to take back the warmth
## the evening light adds: sampled at `done` the cured slab was neutral, and
## at the payoff it was light pine with brush lines - decking again (round 8).
var _cure_tint: Color = Color.WHITE
## Which cells the screed has been over. A poured cell is LUMPY - its middle
## stands a little proud or a little low, and its colour is mottled - until the
## board strikes it off, and then it is a plane. That is the whole picture of
## the screed phase, and without it (round 3) the board slid over a slab that
## looked finished already.
var _struck: PackedByteArray = PackedByteArray()
## How far the middle of an unstruck cell stands PROUD of its fill, metres -
## never below it, or the steel would poke through a full pour.
const LUMP := 0.06
## Noise at the CORNERS of unstruck cells - shared by every cell that meets at
## a corner, so it is continuous and survives the blend that averaged the
## centre lumps away (round 4, 5, 6: "a value step, not a shape").
const LUMP_C := 0.075
## The mound the pour heaps under the spout while it runs: a shape that says
## where the concrete is landing, which a flat pool never did.
const MOUND := 0.05
## A cell with less than this in it is not drawn: a trace of `_settle` spill
## painted a whole grey cell out in the gravel (round 7).
const MIN_DRAW := 0.012
## The screed's BOW WAVE: the roll of surplus that stands up in front of the
## board and travels with it. A shape, which is what the phase was missing at
## 1.8% of luma (round 4).
const WAVE := 0.08
## Where the board is right now, or -INF when it is not being pulled.
var _wave_z: float = -INF
## The roll of surplus drawn as its own ridge against the board's leading face:
## a crest with a shadow line, which a 6 cm rise blended into a 60 cm cell never
## had (round 5).
var _wave_mesh: MeshInstance3D
## The CREST of fresh concrete where the chute lands it: a faceted dome in
## the slab's material, a step lighter and warmer than the pool (round 14:
## the arriving material has to be the one lit, warm, moving shape at the
## pour; every value tuned against the pool was inside the surface's noise).
var _crest_mesh: MeshInstance3D
var _crest_mat: StandardMaterial3D
## Where the chute is landing concrete right now, or INF.
var _mound_at: Vector3 = Vector3.INF
var _wet: float = 0.0
## The reinforcement: twelve bars {node, marker, home, k, group}, thirty-two
## chairs under the long ones, and a tie at every crossing (DESIGN 2d).
var _bars: Array = []
var _bar_groups: Array[PackedInt32Array] = []
var _bar_group_marks: Array[Node3D] = []
var _chairs: Array[Node3D] = []
var _ties: Array = []
## How much of the hose and of the broom each cell has had, 0 to 1. These are
## what "get it all wet yourself" is measured against.
var _watered: PackedFloat32Array = PackedFloat32Array()
var _brushed: PackedFloat32Array = PackedFloat32Array()
## What a fully wetted cell looks like, and what a fully broomed one dries to.
var _wet_target: float = 0.60
var _dry_target: float = 0.25
var _full_emitted: bool = false
## The tooled joints and the broom's lines, built as they are made. The broom's
## are now per CELL - the child brushes the slab patch by patch - so this is an
## array of arrays, one slot per cell, empty until that cell is brushed.
var _joints: Array[Node3D] = []
var _joint_done: Dictionary = {}
var _broom_lines: Array[Node3D] = []
var _cell_lines: Array = []
## A puddle per cell: a small pool of sky held in a low spot of a cell the
## hose has wetted through, until the screed strikes it or the broom dries it
## (round 13: the water was the one beat carried by a tint with no shape).
var _puddles: Array[MeshInstance3D] = []
const PUDDLE := Color(0.60, 0.67, 0.75)
var _markers: Dictionary = {}
## Where the old drive's crack, stain and weed generators start (the plan's
## 6.1): `SiteLook.CRACK_BASES`, set by `SiteMain._enter_tree` before this
## node's own `_ready` builds the panels. 917 is the legacy drive. The spots,
## the settled slab, the chunks and the stones never read it: which old cracks
## a drive has changes per visit, where the child works it does not.
var crack_base: int = 917


func _ready() -> void:
	if _panels.is_empty():
		build()


func setup(cfg: SiteConfig) -> void:
	config = cfg


# --- Building the thing -----------------------------------------------------------------------

## Idempotent on purpose: this node's own `_ready` runs BEFORE the level's, so
## `SiteMain` calling `build()` after `setup()` must not lay a second driveway on
## top of the first one.
func build() -> void:
	if not _panels.is_empty():
		return
	_build_dirt()
	_build_panels()
	_build_forms()
	_build_rebar()
	_build_cells()
	_build_markers()


## The hole under the old slab, and the gravel bed that will fill it. Both exist
## from the start and are simply not seen until they are: the dirt is under the
## old concrete, and the gravel has no height yet.
func _build_dirt() -> void:
	# The FLOOR of the excavation, not a block filling it: its top is at -DIG, so
	# once the old slab is out there is a real hole to put a base into. (Built as
	# a block first time round, which quietly filled the hole to grade and buried
	# everything that followed.)
	# Under the boards' 8 cm slots too: the kerb board is not in until after the
	# base now (5.2), and its empty slot was a line of nothing from the road.
	_dirt = _box("Dirt", Vector3(WIDTH + 0.16, 0.4, LENGTH + 0.16), Vector3(CENTRE_X, -DIG - 0.2, _mid_z()), DIRT)
	add_child(_dirt)
	# Four earth banks lining the hole, so its sides are soil rather than a
	# cross-section of green lawn.
	# OUTSIDE the form boards, and their tops a centimetre BELOW grade.
	#
	# They used to straddle the board line and stand exactly at grade, which meant
	# each 0.14 m bank box wholly contained the 0.05 m board inside it: all four
	# boards rendered as a stippled dashed line that flickered as the camera moved,
	# all ten driven stakes vanished completely, and the finished drive was framed
	# by a trench of bare earth. Two of the child's phases - eight of the thirty
	# progress stops - left nothing at all on screen.
	# Their tops 9 cm BELOW grade and outside the 0.08 board, so the board shows
	# a face standing out of the earth: with the tops at -0.01 against the old
	# 0.05 board there was 1 cm of face to see, and from the kerb end the forms
	# were a line one pixel wide with eight stubs standing in grass beside it
	# (round 4).
	# The banks are TURF AT GRADE before the first panel comes out and again
	# after the forms come off, and the earth cut outside the boards in
	# between. Hidden before the cut, they left the 22 cm between the panels
	# and the lawn open to the dirt below - a ribbon of earth down the side of
	# an intact drive in the first frame of the game, and (the boards' 8 cm
	# slot, never backfilled) down the side of the finished one in the last
	# (round 10). `set_banks` is the one place their shape lives.
	var bank := 0.14
	var board := 0.08
	var out := WIDTH * 0.5 + board + bank * 0.5
	var deep := DIG - 0.09
	var bank_y := -0.09 - deep * 0.5
	for spec: Array in [
			[Vector3(WIDTH + out * 2.0, deep, bank), Vector3(CENTRE_X, bank_y, Z_APRON - board - bank * 0.5)],
			[Vector3(WIDTH + out * 2.0, deep, bank), Vector3(CENTRE_X, bank_y, Z_KERB + board + bank * 0.5)],
			[Vector3(bank, deep, LENGTH), Vector3(CENTRE_X - out, bank_y, _mid_z())],
			[Vector3(bank, deep, LENGTH), Vector3(CENTRE_X + out, bank_y, _mid_z())]]:
		var bank_box := _box("Bank", spec[0], spec[1], DIRT.darkened(0.08))
		_banks.append(bank_box)
		add_child(bank_box)
	set_banks(0.0)
	_gravel = _box("Gravel", Vector3(WIDTH, 0.001, LENGTH), Vector3(CENTRE_X, -DIG, _mid_z()), GRAVEL)
	_gravel.visible = false
	add_child(_gravel)
	_build_stones()
	# The floor of the hole is not one flat brown (round 6: 75% of the forms'
	# frame was a constant colour): clods of spoil the breaker left, revealed
	# with the banks, and the blade's RUTS down each lane, revealed when the pad
	# is cleared. All under the base once it is laid.
	var rng := RandomNumberGenerator.new()
	rng.seed = 6121
	for i in range(90):
		# Lumps, not cards: as tall as they are wide, and tipped (round 7).
		var h := rng.randf_range(0.05, 0.10)
		var shade := rng.randf_range(-0.12, 0.14)
		var clod := _box("Clod_%d" % (i + 1),
			Vector3(rng.randf_range(0.07, 0.15), h, rng.randf_range(0.07, 0.15)),
			Vector3(CENTRE_X + rng.randf_range(-0.48, 0.48) * WIDTH, -DIG + h * 0.3,
				Z_APRON + rng.randf_range(0.02, 0.98) * LENGTH),
			DIRT.lightened(shade) if shade > 0.0 else DIRT.darkened(-shade))
		clod.rotation = Vector3(deg_to_rad(rng.randf_range(-25.0, 25.0)), rng.randf_range(0.0, TAU),
			deg_to_rad(rng.randf_range(-25.0, 25.0)))
		clod.visible = false
		add_child(clod)
		_clods.append(clod)
	for lane in range(1, PANELS_X + 1):
		for side: float in [-1.0, 1.0]:
			var rut := _box("Rut_%d" % lane, Vector3(0.30, 0.004, LENGTH - 0.3),
				Vector3(lane_drive_x(lane) + side * 0.76, -DIG + 0.002, _mid_z()), DIRT.darkened(0.16))
			rut.visible = false
			add_child(rut)
			_ruts.append(rut)


## The four banks round the pad: `cut` 0 is turf at grade filling the whole
## strip between the pad and the lawn (before the job, and after the forms
## come off); 1 is the earth trench outside the boards, cut 9 cm down.
func set_banks(cut: float) -> void:
	for n in range(_banks.size()):
		set_bank(n, cut)


## One bank (0 apron, 1 kerb, 2 left, 3 right): the strip backfills the one
## outside the board it has just taken off, not all four at once (5.3).
func set_bank(n: int, cut: float) -> void:
	if n < 0 or n >= _banks.size():
		return
	var k := clampf(cut, 0.0, 1.0)
	var board := 0.08
	var bank := 0.14
	var top := lerpf(-0.006, -0.09, k)
	var wide := lerpf(board + bank, bank, k)
	var off := lerpf((board + bank) * 0.5, board + bank * 0.5, k)
	var col := LAWN.lerp(DIRT.darkened(0.08), clampf(k * 1.6, 0.0, 1.0))
	# The kerb bank fills the crossing's 8 cm slot when it is not cut: it is
	# the crossing's own grey there, not turf across the drive's end.
	var kerb_col := Color(0.64, 0.64, 0.62).lerp(DIRT.darkened(0.08), clampf(k * 1.6, 0.0, 1.0))
	var mi := _banks[n] as MeshInstance3D
	if mi == null:
		return
	var bm := mi.mesh as BoxMesh
	var along_x := n >= 2
	var size := bm.size
	if along_x:
		size.x = wide
	else:
		size.z = wide
	size.y = top + DIG
	bm.size = size
	var sign := 1.0 if (n == 1 or n == 3) else -1.0
	if along_x:
		mi.position.x = CENTRE_X + sign * (WIDTH * 0.5 + off)
	else:
		mi.position.z = (Z_KERB if n == 1 else Z_APRON) + sign * off
		# The apron bank sits a centimetre INTO the garage, off the floor's
		# front face (it is never seen; this is hygiene against a z-fight).
		if n == 0:
			mi.position.z -= 0.01
	mi.position.y = -DIG + size.y * 0.5
	var mat := mi.get_active_material(0)
	if mat is StandardMaterial3D:
		(mat as StandardMaterial3D).albedo_color = kerb_col if n == 1 else col
	mi.visible = true


## How far bank `n` is cut, read off its box (1 the trench, 0 turfed).
func bank_cut(n: int) -> float:
	if n < 0 or n >= _banks.size():
		return 0.0
	var mi := _banks[n] as MeshInstance3D
	var top := mi.position.y + (mi.mesh as BoxMesh).size.y * 0.5
	return clampf((top - (-0.006)) / (-0.09 - (-0.006)), 0.0, 1.0)


## The loose stone lying on top of the base.
##
## "Rock texture is very poor at the moment" - it was one flat box of one grey,
## which is a slab of mortar, not a crushed limestone base. What makes crushed
## stone read as crushed is hundreds of separate lumps at every angle, each
## catching the light on one face and casting a shadow off another, so that is
## what this is: three hundred little boxes half buried in the top of the bed, in
## a spread of greys either side of `GRAVEL`. They are revealed with the windrow,
## so the base arrives as the truck lays it.
func _build_stones() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4471
	for i in range(STONES):
		# Lumps with a shaded side, half out of the bed and tipped: flat
		# parallelograms lying on the plane read as dropped cards (round 7).
		# Near-cubes tipped up to forty degrees, a third buried: at 22 degrees
		# and half buried the boxes still showed mostly their tops and read as
		# flat shards (round 8).
		var h := rng.randf_range(0.06, 0.10)
		var at := Vector3(
			CENTRE_X + rng.randf_range(-0.47, 0.47) * WIDTH,
			BASE_TOP - h * rng.randf_range(0.20, 0.38),
			Z_APRON + rng.randf_range(0.01, 0.99) * LENGTH)
		var shade := rng.randf_range(-0.14, 0.12)
		var grey := GRAVEL.lightened(shade) if shade > 0.0 else GRAVEL.darkened(-shade)
		var stone := _box("Stone_%d" % (i + 1),
			Vector3(rng.randf_range(0.06, 0.11), h, rng.randf_range(0.06, 0.11)), at, grey)
		stone.rotation = Vector3(deg_to_rad(rng.randf_range(-40.0, 40.0)),
			rng.randf_range(0.0, TAU), deg_to_rad(rng.randf_range(-40.0, 40.0)))
		stone.visible = false
		add_child(stone)
		_stones.append(stone)
	# What the plate needs to lay each one down (5.1), drawn from a generator of
	# its own AFTER the stones: from the stones' own seed every stone on the base
	# would have moved, and every frame of the base with it.
	var jit_rng := RandomNumberGenerator.new()
	jit_rng.seed = 4471 + 5100
	_cell_stones.clear()
	for c in range(CELLS_X * CELLS_Z):
		_cell_stones.append(PackedInt32Array())
	var cw := WIDTH / float(CELLS_X)
	var cl := LENGTH / float(CELLS_Z)
	for n in range(_stones.size()):
		var s := _stones[n]
		var ix := clampi(int(floor((s.position.x - (CENTRE_X - WIDTH * 0.5)) / cw)), 0, CELLS_X - 1)
		var iz := clampi(int(floor((s.position.z - Z_APRON) / cl)), 0, CELLS_Z - 1)
		var c := iz * CELLS_X + ix
		_cell_stones[c].append(n)
		var mat := s.get_active_material(0) as StandardMaterial3D
		_stone_rest.append({"q": s.quaternion, "yaw": s.rotation.y, "y": s.position.y,
			"h": (s.mesh as BoxMesh).size.y, "col": mat.albedo_color if mat != null else GRAVEL,
			"cell": c, "jit": jit_rng.randf_range(0.0, 0.4)})


func _build_panels() -> void:
	var pw := (WIDTH - PANEL_GAP * float(PANELS_X - 1)) / float(PANELS_X)
	var pl := (LENGTH - PANEL_GAP * float(PANELS_Z - 1)) / float(PANELS_Z)
	# Numbered from the KERB end: a crew breaks out the end it can get a machine
	# to, and it puts the first beat of the job at the street end of the drive
	# with the house behind it rather than filling the picture.
	for iz in range(PANELS_Z):
		for ix in range(PANELS_X):
			var centre := Vector3(
				CENTRE_X - WIDTH * 0.5 + pw * 0.5 + float(ix) * (pw + PANEL_GAP),
				-SLAB_T * 0.5,
				Z_KERB - pl * 0.5 - float(iz) * (pl + PANEL_GAP))
			var holder := Node3D.new()
			holder.name = "Panel_%d" % (_panels.size() + 1)
			holder.position = centre
			add_child(holder)
			# The slab itself, and a paler top face so the panel reads as a
			# surface seen from above rather than as a grey block.
			var slab := _box("Slab", Vector3(pw, SLAB_T, pl), Vector3.ZERO, OLD_CONCRETE_DARK)
			holder.add_child(slab)
			var top := _box("Top", Vector3(pw, 0.012, pl), Vector3(0.0, SLAB_T * 0.5, 0.0), OLD_CONCRETE)
			holder.add_child(top)
			# WHAT IS WRONG WITH THIS DRIVEWAY, visible before the first tap. The pillar
			# is that a fault reads as SHAPE rather than as a tint, and a flat grey
			# rectangle says nothing at all: this drive is cracked and stained the moment
			# the child sees it, and the hammer adds to what is already there.
			var rng := RandomNumberGenerator.new()
			rng.seed = crack_base + _panels.size()
			var y_crack := SLAB_T * 0.5 + 0.006
			# The joints of the old cracks, where the weeds grow (4.1). Read off the
			# segments, so not one more number is drawn from `rng`: every crack and
			# stain after this keeps its shape.
			var old_joints: Array[Vector3] = []
			# Three cracks it already has, each a zigzag running right across the
			# panel: it is the CRACKS that carry "broken" as shape, and a straight
			# one reads as a line somebody drew.
			for extra in range(2):
				var ca := Vector3(rng.randf_range(-0.50, -0.36) * pw, y_crack,
					rng.randf_range(-0.42, 0.42) * pl)
				var cb := Vector3(rng.randf_range(0.34, 0.50) * pw, y_crack,
					ca.z + rng.randf_range(-0.34, 0.34) * pl)
				var old := _zigzag(holder, ca, cb, CRACK_SEGMENTS, CRACK_JAG * 0.8, 0.028,
					CRACK_INK.lightened(0.20), rng, "OldCrack_%d" % (extra + 1))
				# Every joint but the last (it lands on the panel's edge), and the middle
				# of every segment: a weed grows anywhere along a crack, and the first
				# slab needs somewhere to grow that the wide's rings do not cover.
				for s in range(old.size()):
					var e: Vector3 = old[s].get_meta("end", Vector3.INF)
					if e == Vector3.INF:
						continue
					if s < old.size() - 1:
						old_joints.append(e)
					old_joints.append((old[s] as Node3D).position)
			# And the dirt. A stain is a BLOTCH, which takes three overlapping
			# boxes at three angles: one rotated rectangle reads as a tile.
			for st in range(2):
				var at := Vector3(rng.randf_range(-0.26, 0.26) * pw, SLAB_T * 0.5 + 0.003,
					rng.randf_range(-0.30, 0.30) * pl)
				var ink := OLD_CONCRETE.darkened(rng.randf_range(0.10, 0.18))
				for lump in range(3):
					var blob := _box("Stain_%d_%d" % [st + 1, lump + 1],
						Vector3(pw * rng.randf_range(0.14, 0.28), 0.008,
							pl * rng.randf_range(0.09, 0.18)),
						at + Vector3(rng.randf_range(-0.07, 0.07) * pw, 0.0,
							rng.randf_range(-0.07, 0.07) * pl), ink)
					blob.rotation.y = deg_to_rad(rng.randf_range(-80.0, 80.0))
					holder.add_child(blob)
			# The three places the hammer is worked, and the crack each one opens.
			# A spot is somewhere a child can aim at - a third of the slab - and its
			# crack runs right across the panel from there, revealed segment by
			# segment as the hammer bites, so the crack RUNS out of the bit.
			var spots: Array[Node3D] = []
			var cracks: Array = []
			var place := [Vector2(0.24, -0.30), Vector2(-0.22, 0.02), Vector2(0.20, 0.32)]
			for c in range(SPOTS_PER_PANEL):
				var off: Vector2 = place[c % place.size()]
				var at := Vector3(off.x * pw, SLAB_T * 0.5, off.y * pl)
				var spot := Marker3D.new()
				spot.name = "Spot_%d" % (c + 1)
				spot.position = at
				holder.add_child(spot)
				spots.append(spot)
				# Across the panel from the spot, and a little along it, so the
				# three cracks cross each other instead of lying in parallel.
				var away := -1.0 if off.x > 0.0 else 1.0
				var from := Vector3(at.x, y_crack, at.z)
				var to := Vector3(away * 0.52 * pw, y_crack,
					at.z + rng.randf_range(-0.22, 0.22) * pl)
				var segs := _zigzag(holder, from, to, CRACK_SEGMENTS, CRACK_JAG, 0.034,
					CRACK_INK, rng, "Crack_%d" % (c + 1))
				for seg in segs:
					seg.visible = false
				cracks.append(segs)
			var marker := Marker3D.new()
			marker.name = "At"
			marker.position = Vector3(0.0, SLAB_T * 0.5, 0.0)
			holder.add_child(marker)
			var weeds := _plant_weeds(holder, old_joints, spots, Vector2(pw, pl), _panels.size() + 1)
			# The settled slab (4.1): its seam edge a step down, its lawn edge still
			# at grade so no gap opens against the turf. Only an INTERIOR edge ever
			# drops. Its spot markers and its At marker are the holder's children,
			# so the rings, the breaker and the PANEL eye, which read them when they
			# are placed, land on the settled slab.
			var rest_dy := 0.0
			if _panels.size() + 1 == SETTLED_PANEL and ix < PANELS_X - 1:
				rest_dy = -SETTLE_STEP * 0.5
				holder.rotation.z = -asin(SETTLE_STEP / pw)
				holder.position.y = centre.y + rest_dy
			var hit: Array[bool] = []
			for c in range(SPOTS_PER_PANEL):
				hit.append(false)
			_panels.append({"node": holder, "marker": marker, "cracks": cracks,
				"spots": spots, "hit": hit, "chunks": [] as Array[Node3D],
				"broken": false, "jacked": 0.0,
				"size": Vector2(pw, pl), "home": centre,
				"weeds": weeds, "rest_dy": rest_dy, "joints": old_joints})


## Four boards round the pad - two long ones down the sides, two short across
## the ends - each with a stake. They start in the air above their homes and
## swing down as the child taps them in.
func _build_forms() -> void:
	# 0.05 rather than a scale 0.038 board: against dark earth a true-to-life
	# plank was a red thread one pixel wide in the wide shot, and the forms are
	# the thing the child has just spent four taps putting in.
	# 0.08, not 0.05: at 0.05 the boards resolved as a dotted line in every shot
	# taken from the kerb end and the left one vanished from three of them
	# (round 3).
	var t := 0.08
	# The board's top IS the finished surface - that is what a form is for, and it
	# is what the screed rides. At DIG + 0.02 the forms stood 2 cm proud of the
	# slab they were shuttering and the screed board floated over the concrete.
	var h := DIG
	# The fourth "form" is not a board: against the garage apron there is nothing
	# to stake a board to and no reason for one - the new slab butts against the
	# old with an EXPANSION JOINT between them, a strip of fibreboard that stays in
	# the slab. It is tapped in like a board, it takes no stakes, and it is not
	# stripped. (Its stakes used to be driven into the garage floor.)
	var specs := [
		{"name": "Form_1", "size": Vector3(t, h, LENGTH + t * 2.0), "color": TIMBER,
			"at": Vector3(CENTRE_X - WIDTH * 0.5 - t * 0.5, -DIG + h * 0.5, _mid_z())},
		{"name": "Form_2", "size": Vector3(t, h, LENGTH + t * 2.0), "color": TIMBER,
			"at": Vector3(CENTRE_X + WIDTH * 0.5 + t * 0.5, -DIG + h * 0.5, _mid_z())},
		{"name": "Form_3", "size": Vector3(WIDTH, h, t), "color": TIMBER,
			"at": Vector3(CENTRE_X, -DIG + h * 0.5, Z_KERB + t * 0.5)},
		# ON the pad, flush against the garage floor and 6 mm proud: buried in
		# the floor its front face was coplanar with the floor's and the two
		# z-fought as a flicker where the board meets the garage (fourth
		# playtest); proud, the screeded sheet passes through it instead of
		# lying on its top.
		{"name": "Form_4", "size": Vector3(WIDTH, h + 0.006, 0.05), "color": FIBRE,
			"at": Vector3(CENTRE_X, -DIG + (h + 0.006) * 0.5, Z_APRON + 0.025)},
	]
	for spec: Dictionary in specs:
		var board := _box(String(spec["name"]), spec["size"], spec["at"], spec["color"])
		add_child(board)
		# The marker the camera hangs off and the arrow points at is a FIXED point
		# on the edge of the hole, not a child of the board.
		#
		# The board waits 0.9 m up in the air until it is tapped in, so a marker
		# parented to it is 0.9 m up too: the shot framed the board in mid-air while
		# the arrow and the tap's target sat on the ground below the bottom of the
		# picture. "Unable to click some of the form placements because of camera"
		# was the user's note, and this is why.
		var marker := Marker3D.new()
		marker.name = "%sAt" % String(spec["name"])
		marker.position = Vector3(spec["at"]) + Vector3(0.0, Vector3(spec["size"]).y * 0.5, 0.0)
		add_child(marker)
		_forms.append({"node": board, "marker": marker, "home": Vector3(spec["at"]), "k": 0.0})
		board.visible = false
	# FOUR stakes to a long board and two to the kerb board, spaced along it. One
	# pin in the middle of a 9 m form is not what holds wet concrete back.
	#
	# TEN SEPARATE STAKES, one tap each, and not four sets driven together: "you
	# hammer one side and three go in, instead it should be one hammer hit per
	# stake". One swing of the sledge puts one stake in, which is both what the
	# user asked for and what a blow from a sledge that size really does.
	#
	# Driven, a stake stands `STAKE_STUB` proud, and that stub is its painted cap
	# (4.2): they stand OUTSIDE the boards, where the 3.70 m screed never reaches.
	var out := [Vector3(-0.09, 0.0, 0.0), Vector3(0.09, 0.0, 0.0),
		Vector3(0.0, 0.0, 0.09), Vector3(0.0, 0.0, -0.09)]
	var along: Array[Vector3] = [Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0),
		Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0)]
	# FOUR to a long board, 2.2 m apart, so they pair off ALONG the board
	# (round 10): a pair across the form is 3.6 m apart and can only be framed
	# on the gap between them; a pair along a board fits one close picture.
	var spacing := [LENGTH * 0.245, LENGTH * 0.245, WIDTH * 0.30, WIDTH * 0.30]
	# None on the expansion strip.
	var count := [STAKES_PER_LONG, STAKES_PER_LONG, STAKES_PER_SHORT, 0]
	for i in range(_forms.size()):
		var base: Vector3 = _forms[i]["home"] + out[i]
		var n: int = count[i]
		for s in range(n):
			var off := (float(s) - float(n - 1) * 0.5) * float(spacing[i])
			var home: Vector3 = base + along[i] * off \
				+ Vector3(0.0, GRADE - STAKE_H * 0.5 - base.y, 0.0)
			var stake := _box("Stake_%d_%d" % [i + 1, s + 1], Vector3(0.05, STAKE_H, 0.05),
				home + Vector3(0.0, STAKE_PROUD, 0.0), STAKE_TIMBER)
			# The cap is the stake's CHILD, so it rides down with every blow, hides
			# with the stake and comes off with the strip.
			stake.add_child(_box("Cap", Vector3(0.062, STAKE_CAP, 0.062),
				Vector3(0.0, STAKE_CAP_Y, 0.0), STAKE_PINK))
			add_child(stake)
			stake.visible = false
			# A FIXED marker at the head of the stake as it will be once driven,
			# for the same reason the boards have one: a marker parented to the
			# stake rides down with it as it is hit, and the camera rides with it.
			var marker := Marker3D.new()
			marker.name = "Stake_%d_%dAt" % [i + 1, s + 1]
			marker.position = home + Vector3(0.0, STAKE_H * 0.5, 0.0)
			add_child(marker)
			_stakes.append({"node": stake, "marker": marker, "home": home, "k": 0.0,
				"board": i + 1, "along": along[i]})
	_group_stakes()


## Which stakes stand together, for the camera (the user, 2026-09-12: "the
## stakes are a wide shot so you don't get the hammer feeling").
##
## Ten rings spread over nine metres can only be held in one picture by a camera
## up on the roof, and from there a 5 cm peg and a swung sledge are a smudge. So
## the ten are cut into GROUPS - consecutive pairs ALONG each board, 2.2 m
## apart, and the kerb board's two - and the phase is worked a group at a time:
## rings on that group only, the camera close on it, and the eye walking down the
## drive as each group goes in. Five groups of two.
func _group_stakes() -> void:
	# Pairs ALONG each board, garage end first (round 10: a pair across the
	# form was framed on the gap between two pegs 3.6 m apart). The stakes
	# were built board by board in order along it, so consecutive pairs are
	# neighbours on one board.
	_stake_groups.clear()
	var group := -1
	for i in range(_stakes.size()):
		if i % 2 == 0:
			group += 1
			_stake_groups.append(PackedInt32Array())
		_stakes[i]["group"] = group
		_stake_groups[group].append(i + 1)


## The reinforcement (DESIGN 2d). Four bars the length of the drive, on
## chairs, and eight across on top of them, tied where they cross. All of it
## is built now and shown as the child lays it: a bar waits in the air over its
## place while its ring is lit, and drops onto the chairs on the tap.
##
## Numbered 1..4 for the long bars (group 0) and 5..12 for the cross bars, which
## are grouped in PAIRS from the garage end so the camera can stand close on the
## pair being laid, the way the stakes are worked.
func _build_rebar() -> void:
	var y_long := BASE_TOP + CHAIR_H + BAR_T * 0.5
	var y_cross := y_long + BAR_T
	var xs: Array[float] = []
	for i in range(BARS_ALONG):
		xs.append(CENTRE_X + (float(i) - float(BARS_ALONG - 1) * 0.5) * (WIDTH - BAR_COVER * 2.0 - 0.2)
			/ float(BARS_ALONG - 1))
	var zs: Array[float] = []
	for k in range(BARS_ACROSS):
		zs.append(Z_APRON + LENGTH * (float(k) + 0.5) / float(BARS_ACROSS))
	# The long bars.
	for i in range(BARS_ALONG):
		var home := Vector3(xs[i], y_long, _mid_z())
		_add_bar("Bar_%d" % (i + 1), home, Vector3(0.0, 0.0, 1.0), LENGTH - BAR_COVER * 2.0, 0)
	# The cross bars, in pairs down the drive.
	for k in range(BARS_ACROSS):
		var home := Vector3(CENTRE_X, y_cross, zs[k])
		_add_bar("Bar_%d" % (BARS_ALONG + k + 1), home, Vector3(1.0, 0.0, 0.0),
			WIDTH - BAR_COVER * 2.0, 1 + k / 2)
	# Chairs under every long bar where a cross bar will lie over it, and at
	# both its ends, and a tie at each crossing once both bars are down.
	for i in range(BARS_ALONG):
		var stations: Array[float] = zs.duplicate()
		stations.append(Z_APRON + BAR_COVER + 0.08)
		stations.append(Z_KERB - BAR_COVER - 0.08)
		for k in range(stations.size()):
			# A CRADLE: a narrow post on a wide foot with a saddle across the top
			# the bar sits in, so from the low BARS eye there is open air either
			# side of the post and under the bar.
			var chair := _box("Chair_%d_%d" % [i + 1, k + 1], Vector3(0.024, CHAIR_H, 0.024),
				Vector3(xs[i], BASE_TOP + CHAIR_H * 0.5, stations[k]), CHAIR)
			var foot := _box("Foot", Vector3(0.11, 0.008, 0.11), Vector3(0.0, -CHAIR_H * 0.5 + 0.004, 0.0), CHAIR)
			chair.add_child(foot)
			var saddle := _box("Saddle", Vector3(0.07, 0.008, 0.045), Vector3(0.0, CHAIR_H * 0.5 - 0.004, 0.0), CHAIR)
			chair.add_child(saddle)
			chair.visible = false
			add_child(chair)
			_chairs.append(chair)
	for i in range(BARS_ALONG):
		for k in range(BARS_ACROSS):
			var tie := _box("Tie_%d_%d" % [i + 1, k + 1], Vector3(BAR_T + 0.014, BAR_T * 2.0 + 0.008, BAR_T + 0.014),
				Vector3(xs[i], y_long + BAR_T * 0.5, zs[k]), TIE)
			tie.visible = false
			add_child(tie)
			_ties.append({"node": tie, "cross": BARS_ALONG + k + 1, "long": i + 1})
	_bar_groups.clear()
	var groups := 1 + (BARS_ACROSS + 1) / 2
	for g in range(groups):
		_bar_groups.append(PackedInt32Array())
	for i in range(_bars.size()):
		var g: int = _bars[i]["group"]
		_bar_groups[g].append(i + 1)


## One bar: a box along `along`, with the deformation rings a real bar has so it
## reads as steel rather than as a stick, its own marker at its home, and its
## group for the camera.
func _add_bar(bar_name: String, home: Vector3, along: Vector3, length: float, group: int) -> void:
	var size := Vector3(BAR_T, BAR_T, length) if along.z > 0.5 else Vector3(length, BAR_T, BAR_T)
	var bar := _box(bar_name, size, home, REBAR)
	add_child(bar)
	# Its shadow on the base while it waits in the air: what says "it is going
	# to land HERE" (round 6: a raised bar read as misplaced, not as poised).
	# 2 mm thick under the chairs' feet (whose tops are at BASE_TOP + 8 mm): at 4 mm
	# its top was the feet's own plane, under the low eye that shows them.
	var mark := _box("Mark", Vector3(size.x + 0.02, 0.002, size.z + 0.02),
		Vector3(home.x, BASE_TOP + 0.003, home.z), Color(0.46, 0.40, 0.31))
	mark.visible = false
	add_child(mark)
	var pitch := 0.24
	var n := int(floor(length / pitch))
	for r in range(n):
		var off := (float(r) - float(n - 1) * 0.5) * pitch
		var rsize := Vector3(BAR_T + 0.01, BAR_T + 0.01, 0.014) if along.z > 0.5 \
			else Vector3(0.014, BAR_T + 0.01, BAR_T + 0.01)
		var ring := _box("Rib", rsize, along * off, REBAR_DARK)
		bar.add_child(ring)
	bar.visible = false
	var marker := Marker3D.new()
	marker.name = "%sAt" % bar_name
	marker.position = home
	add_child(marker)
	_bars.append({"node": bar, "marker": marker, "home": home, "k": 0.0, "group": group,
		"mark": mark})


func bar_count() -> int:
	return _bars.size()


func bar_marker(i: int) -> Node3D:
	var b := _at(_bars, i)
	return b["marker"] if not b.is_empty() else null


## Where bar `i` is being asked to go: its place on the chairs.
## How far a waiting bar lies beside its place: across the drive for a long
## bar, along it for a cross bar - toward the drive's MIDDLE, so no bar waits
## over a form board, and the long bars by less (round 13: alternating sides
## put the two middle long bars 0.55 m apart).
func _bar_skew_offset(i: int) -> Vector3:
	var home := bar_home(i)
	if bar_is_long(i):
		# In line: 0.14 m sideways on a 9 m bar read as uneven spacing, not as
		# waiting (round 14). A long bar's cue is its FAN (`_bar_skew_rad`)
		# and its lift.
		return Vector3.ZERO
	var sz := 1.0 if home.z < _mid_z() else -1.0
	return Vector3(0.0, 0.0, BAR_SKEW_OFF * sz)


## The yaw that swings a bar's end `BAR_SKEW_END` off its line, signed.
##
## A LONG bar swings its kerb end toward the drive's middle line, always (the
## session-4 verification pass): the low eye stands on that line at the kerb
## end, and an outer bar whose near half swung OUT lay against the form board's
## top from there. The outer two swing less, so their far ends stay inside the
## boards as well; the middle two keep the full swing that is their cue. Cross
## bars alternate as they always have.
func _bar_skew_rad(i: int) -> float:
	var b := _at(_bars, i)
	if b.is_empty():
		return 0.0
	var mi := b["node"] as MeshInstance3D
	var bm := mi.mesh as BoxMesh if mi != null else null
	var length := maxf(bm.size.x, bm.size.z) if bm != null else 3.0
	var end := BAR_SKEW_END
	var side := 1.0 if i % 2 == 0 else -1.0
	if bar_is_long(i):
		var dx := bar_home(i).x - CENTRE_X
		end = BAR_SKEW_END_LONG if absf(dx) < WIDTH * 0.25 else BAR_SKEW_END_LONG_OUTER
		# A positive yaw sends the +Z (kerb) end toward +X.
		side = 1.0 if dx < 0.0 else -1.0
	return asin(clampf(2.0 * end / maxf(length, 0.5), 0.0, 1.0)) * side


## How high bar `i` waits over its place. A long bar barely (`bar_long_lift`):
## the decided list's "no lift to be thrown by parallax", which the low eye made
## literal - at the cross bars' 6 cm the outer long bars were thrown onto the
## form boards (the session-4 verification pass).
func bar_lift(i: int) -> float:
	if bar_is_long(i):
		return config.bar_long_lift if config != null else 0.02
	return config.bar_drop_height if config != null else 0.06


## A bar's LANDING, one gravity for all of it (the improvement plan's 4.7, as
## the session-4 verification pass corrected it): the cross bar's bounce -
## `bar_bounce` high, then a third of it, in `bar_bounce_time` - fixes the
## gravity; the drop is a free fall under it over the last of `bar_drop_time`,
## and a bar that waits lower bounces lower in the same proportion, so every
## landing leaves the chairs at the same fraction (0.71) of the speed it hit
## them. (The first cut fell at a seventeenth of the hops' gravity and left the
## chairs 2.9 times faster than it had hit them: a kick, not a bounce.)
##   lift, fall_time, h1, t1, h2, t2
func bar_landing(i: int) -> Dictionary:
	var lift := bar_lift(i)
	var drop_h: float = config.bar_drop_height if config != null else 0.06
	var drop_t: float = config.bar_drop_time if config != null else 0.55
	var bb: float = config.bar_bounce if config != null else 0.03
	var bt: float = config.bar_bounce_time if config != null else 0.30
	var g := 9.8
	if bb > 0.0 and bt > 0.0:
		var t1c := bt * sqrt(bb) / (sqrt(bb) + sqrt(bb / 3.0))
		g = 8.0 * bb / (t1c * t1c)
	var h1 := bb * lift / maxf(drop_h, 0.001) if bb > 0.0 and bt > 0.0 else 0.0
	var h2 := h1 / 3.0
	return {"lift": lift, "fall_time": minf(sqrt(2.0 * lift / g), drop_t),
		"h1": h1, "t1": sqrt(8.0 * h1 / g), "h2": h2, "t2": sqrt(8.0 * h2 / g)}


## Where a bar's middle is while it waits: what its ring sits on.
func bar_wait_point(i: int) -> Vector3:
	var b := _at(_bars, i)
	if b.is_empty():
		return Vector3.ZERO
	return Vector3(b["home"]) + _bar_skew_offset(i) + Vector3(0.0, bar_lift(i), 0.0)


func bar_home(i: int) -> Vector3:
	var b := _at(_bars, i)
	return Vector3(b["home"]) if not b.is_empty() else Vector3.ZERO


## Which way bar `i` runs: true for a long bar (up the drive).
func bar_is_long(i: int) -> bool:
	var b := _at(_bars, i)
	return not b.is_empty() and int(b["group"]) == 0


## Lays bar `i`: `k` 0 is waiting in the air over its place, 1 is down on the
## chairs. The ties at its crossings appear as a CROSS bar lands - unless `ties`
## is false, which is the verb's landing: it pops them down the bar itself once
## the bounce has settled (the improvement plan's 4.7).
##
## `k` is LINEAR in time from the verb, and shaped here: the swing into line is
## a smoothstep over the whole drop; the drop itself is a free fall over its last
## `bar_landing(i).fall_time` under the bounce's own gravity, so the bar meets the
## chairs moving and leaves them slower than it came. Only 0 and 1 are ever
## passed by the poses, and those ends are unchanged.
func set_bar(i: int, k: float, ties: bool = true) -> void:
	var b := _at(_bars, i)
	if b.is_empty():
		return
	var kk := clampf(k, 0.0, 1.0)
	b["k"] = kk
	var node: Node3D = b["node"]
	node.visible = true
	# A waiting bar lies ON the grid a hand's width beside its place, SKEWED
	# off the grid's line and a little up, and swings into line as it goes in.
	# Lifted straight up it was either invisible (16 cm) or thrown out over
	# the lawn by the close eye's parallax (32 cm) - round 12: "waiting" is
	# carried by being out of LINE, which no eye can miss and no parallax can
	# move off the base.
	var w := 1.0 - kk * kk * (3.0 - 2.0 * kk)
	var land := bar_landing(i)
	var drop_t: float = config.bar_drop_time if config != null else 0.55
	var ft: float = land["fall_time"]
	var fall := clampf((kk * drop_t - (drop_t - ft)) / maxf(ft, 0.001), 0.0, 1.0)
	var up: float = float(land["lift"]) * (1.0 - fall * fall)
	node.position = Vector3(b["home"]) + _bar_skew_offset(i) * w + Vector3(0.0, up, 0.0)
	# The mark under THIS bar. Held in the bar's own record: found as "the
	# sibling named Mark" it was only ever bar 1's - Godot renames a second child
	# called Mark - so eleven bars waited with no mark under them.
	var m := b.get("mark") as Node3D
	if m != null:
		m.visible = kk < 0.98
	node.rotation.y = _bar_skew_rad(i) * w
	node.rotation.z = deg_to_rad(3.0 * w) if bar_is_long(i) else 0.0
	node.rotation.x = 0.0 if bar_is_long(i) else deg_to_rad(3.0 * w)
	if kk >= 0.999 and ties and not bar_is_long(i):
		for t: Dictionary in _ties:
			if int(t["cross"]) == i:
				var tn := t["node"] as Node3D
				tn.visible = true
				# Full size, whatever a pop was doing: a posed picture never has a
				# half-grown tie in it.
				tn.scale = Vector3.ONE


## A laid bar hopping `dy` metres off its chairs, for the bounce of its landing.
## It never touches the bar's `k` - the bar is IN throughout, so no ring comes
## back and no group query changes its mind mid-bounce.
func bounce_bar(i: int, dy: float) -> void:
	var b := _at(_bars, i)
	if b.is_empty() or not bar_is_in(i):
		return
	(b["node"] as Node3D).position = Vector3(b["home"]) + Vector3(0.0, maxf(dy, 0.0), 0.0)


## The ties a cross bar owns at the crossings with the long bars already laid,
## in order across the drive (near end first from the eye).
func bar_ties(i: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for t: Dictionary in _ties:
		if int(t["cross"]) == i and bar_is_in(int(t.get("long", 0))):
			out.append(t["node"] as Node3D)
	return out


## One tie POPPING onto its crossing: grown from nothing with a small overshoot.
func pop_tie(tie: Node3D, seconds: float) -> void:
	if tie == null:
		return
	# Never a zero scale: its basis would be singular.
	tie.scale = Vector3.ONE * 0.01
	tie.visible = true
	var tw := create_tween()
	tw.tween_property(tie, "scale", Vector3.ONE, maxf(seconds, 0.02)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func bar_is_in(i: int) -> bool:
	var b := _at(_bars, i)
	return not b.is_empty() and float(b["k"]) >= 0.999


func open_bars() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in range(1, _bars.size() + 1):
		if not bar_is_in(i):
			out.append(i)
	return out


func bars_in() -> int:
	var n := 0
	for b: Dictionary in _bars:
		if float(b["k"]) >= 0.999:
			n += 1
	return n


func rebar_done() -> bool:
	return not _bars.is_empty() and bars_in() == _bars.size()


func bar_group_count() -> int:
	return _bar_groups.size()


func bar_group(i: int) -> int:
	var b := _at(_bars, i)
	return int(b.get("group", -1)) if not b.is_empty() else -1


func open_bars_in(g: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if g < 0 or g >= _bar_groups.size():
		return out
	for i in _bar_groups[g]:
		if not bar_is_in(i):
			out.append(i)
	return out


## The group being laid: the long bars first, then the cross pairs from the
## garage end. -1 when the steel is all down.
func current_bar_group() -> int:
	for g in range(_bar_groups.size()):
		if not open_bars_in(g).is_empty():
			return g
	return -1


## A marker in the middle of group `g`, for the camera to hang off.
func bar_group_mark(g: int) -> Node3D:
	if g < 0 or g >= _bar_groups.size():
		return null
	while _bar_group_marks.size() < _bar_groups.size():
		_bar_group_marks.append(null)
	if _bar_group_marks[g] != null and is_instance_valid(_bar_group_marks[g]):
		return _bar_group_marks[g]
	var mid := Vector3.ZERO
	for i in _bar_groups[g]:
		mid += bar_home(i)
	mid /= maxf(float(_bar_groups[g].size()), 1.0)
	var mark := Marker3D.new()
	mark.name = "BarGroup_%d" % (g + 1)
	add_child(mark)
	mark.global_position = mid
	# The FOUR LONG BARS span the drive's width and run its length: the close
	# picture of a pair cannot hold their four rings, so this group carries
	# its own offsets, square to the drive.
	# LOW (the improvement plan's 4.6): from 1.7 m up, looking 31 degrees down,
	# a chair was its 11 cm foot seen from above - a flat orange square - and
	# every bar lay on the gravel, in the phase whose whole lesson is that the
	# steel sits UP. From 0.62 m, 13 degrees down, the cradle's post stands as a
	# leg with gravel either side of it and daylight under the bar, and the four
	# rings still sit in one row across the frame, 150 px from every edge. (The
	# plan's oblique eye beside bar 2 put the first ring off the left edge.)
	if g == 0:
		mark.set_meta("shot_eye", Vector3(0.0, 0.62, 2.4))
		mark.set_meta("shot_look", Vector3(0.0, -0.16, -1.0))
	_bar_group_marks[g] = mark
	return mark


## The chairs go down first, all at once, when the phase opens: a crew sets its
## chairs before it lays a bar on them.
func show_chairs(on: bool) -> void:
	for c in _chairs:
		c.visible = on


func chairs_shown() -> bool:
	return not _chairs.is_empty() and _chairs[0].visible


## The slab: the fill grid, and the one mesh it is drawn as. A cell at 0 is not
## drawn at all, so before the pour the child sees gravel and steel.
func _build_cells() -> void:
	var n := CELLS_X * CELLS_Z
	_fill.resize(n)
	_watered.resize(n)
	_brushed.resize(n)
	_packed.resize(n)
	_packed.fill(0.0)
	_cell_lines.resize(n)
	_cell_col.resize(n)
	_struck.resize(n)
	for i in range(n):
		_cell_lines[i] = [] as Array[Node3D]
		_fill[i] = 0.0
		_watered[i] = 0.0
		_brushed[i] = 0.0
		_cell_col[i] = WET_CONCRETE
		_struck[i] = 0
	if _puddles.is_empty():
		for i in range(n):
			var ix := i % CELLS_X
			var iz := i / CELLS_X
			var jit := Vector3(0.22 * sin(float(i) * 2.9 + 0.7), 0.0, 0.18 * cos(float(i) * 1.7 + 0.3))
			var r := 0.09 + 0.05 * (0.5 + 0.5 * sin(float(i) * 3.3))
			var cyl := CylinderMesh.new()
			cyl.top_radius = r
			cyl.bottom_radius = r
			cyl.height = 0.004
			cyl.radial_segments = 10
			var pm := StandardMaterial3D.new()
			pm.albedo_color = PUDDLE
			pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cyl.material = pm
			var puddle := MeshInstance3D.new()
			puddle.name = "Puddle_%d" % i
			puddle.mesh = cyl
			puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			puddle.position = Vector3(_cell_x(ix), GRADE, _cell_z(iz)) + jit
			puddle.scale = Vector3(1.0, 1.0, 0.7 + 0.5 * (0.5 + 0.5 * cos(float(i) * 2.1)))
			puddle.visible = false
			add_child(puddle)
			_puddles.append(puddle)
	_base_col = WET_CONCRETE
	_slab_mat = StandardMaterial3D.new()
	_slab_mat.vertex_color_use_as_albedo = true
	# The colours are authored in sRGB like every material's albedo here; read
	# raw they came out two stops lighter and the pour rendered sky-blue.
	_slab_mat.vertex_color_is_srgb = true
	_slab_mat.albedo_color = Color.WHITE
	_slab_mat.roughness = 0.7
	# A sheen, not a mirror: at 0.3 roughness the flat slab reflected the whole
	# sky and read as a sheet of pale water.
	_slab_mat.metallic_specular = 0.25
	_slab = MeshInstance3D.new()
	_slab.name = "Slab"
	_slab.mesh = ArrayMesh.new()
	_slab.material_override = _slab_mat
	_slab.visible = false
	add_child(_slab)


func _process(_delta: float) -> void:
	if _slab_dirty:
		_rebuild_slab()
	if _bed_dirty:
		_rebuild_bed()


## Builds the surface from `_fill`: a fan of four triangles per drawn cell, the
## cell's own height in the middle and the neighbours' heights blended at the
## corners, so two cells a centimetre apart meet in a slope and not a step; a
## skirt down to the base wherever a drawn cell meets an empty one, so a mound
## has a side and never floats. Perimeter edges get no skirt: the form boards
## stand there.
func _rebuild_slab() -> void:
	_slab_dirty = false
	var mesh := _slab.mesh as ArrayMesh
	mesh.clear_surfaces()
	var any := false
	for i in range(_fill.size()):
		if _fill[i] > MIN_DRAW:
			any = true
			break
	_slab.visible = any
	if not any:
		return
	var cw := WIDTH / float(CELLS_X)
	var cl := LENGTH / float(CELLS_Z)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wet_sum := 0.0
	var wet_n := 0
	for iz in range(CELLS_Z):
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			if _fill[i] <= MIN_DRAW:
				continue
			wet_sum += _cell_wet(i)
			wet_n += 1
			var cx := _cell_x(ix)
			var cz := _cell_z(iz)
			# The centre vertex is OFF the lattice for an unstruck cell, so the
			# facet edges do not line up in rows and columns (round 9: "grid
			# alignment is itself a texture").
			var jog := Vector2.ZERO
			if _struck[i] == 0:
				jog = Vector2(0.18 * cw * sin(float(i) * 2.9 + 0.4), 0.18 * cl * cos(float(i) * 1.3 + 0.9))
			var centre := Vector3(cx + jog.x, BASE_TOP + _fill[i] + _lump(ix, iz, i), cz + jog.y)
			var ccol := _drawn_col(ix, iz, i)
			# The four corners, blended over the drawn cells that share them.
			var corners: Array[Vector3] = []
			var cols: Array[Color] = []
			for k in range(4):
				var sx := -1.0 if (k == 0 or k == 3) else 1.0
				var sz := -1.0 if (k == 0 or k == 1) else 1.0
				var h := 0.0
				var col := Color(0.0, 0.0, 0.0, 0.0)
				var m := 0
				var drawn := 0
				var unstruck := 0
				for dz in range(2):
					for dx in range(2):
						var jx := ix + (int(sx) if dx == 1 else 0)
						var jz := iz + (int(sz) if dz == 1 else 0)
						if jx < 0 or jx >= CELLS_X or jz < 0 or jz >= CELLS_Z:
							continue
						var j := jz * CELLS_X + jx
						# An EMPTY neighbour counts, at nothing: it pulls the
						# corner down, so the front of a pour is a tongue that
						# runs out over the base and not a row of missing tiles.
						m += 1
						if _fill[j] <= MIN_DRAW:
							continue
						drawn += 1
						if _struck[j] == 0:
							unstruck += 1
						h += _fill[j] + _lump(jx, jz, j) * 0.5
						col += _drawn_col(jx, jz, j)
				# An empty neighbour weighs double, so a corner on the front of a
				# pour is nearly down on the base: the edge cell is a ramp running
				# out, not a step.
				h /= float(maxi(drawn + 2 * (m - drawn), 1))
				if drawn == m and drawn > 0:
					h += _corner_lump(ix + (1 if sx > 0.0 else 0), iz + (1 if sz > 0.0 else 0),
						float(unstruck) / float(drawn))
				col /= float(maxi(drawn, 1))
				# And the colour runs out toward the base at a front, so the edge
				# of a pour is soft in value as well as in height.
				if drawn < m:
					col = col.lerp(gravel_colour(), 0.8 * float(m - drawn) / float(m))
				corners.append(Vector3(cx + sx * cw * 0.5, BASE_TOP + h, cz + sz * cl * 0.5))
				cols.append(col)
			# (An attempt to make every unstruck cell its own tilted facet with
			# steps between neighbours read as a floor of loose paving slabs -
			# round 3's fault back again. The surface stays CONTINUOUS; the mess
			# is in the corner noise, `LUMP_C`, which is shared by neighbours.)
			# Corners go 0 (-x,-z), 1 (+x,-z), 2 (+x,+z), 3 (-x,+z), which is
			# CLOCKWISE seen from above (+Y) - and Godot's front face is clockwise,
			# so each fan triangle is centre, a, b in that order. The other way
			# round draws nothing at all (the first build of this surface was
			# invisible for exactly that reason).
			for k in range(4):
				var a: Vector3 = corners[k]
				var b: Vector3 = corners[(k + 1) % 4]
				if _struck[i] == 0:
					# An unstruck cell's four facets each take a slightly different
					# shade, applied to the BLENDED corner colours - on the cell's
					# own colour alone the corners of neighbouring cells disagreed
					# and the pour was a floor of tiles in colour (round 9).
					var f := 0.965 + 0.035 * (0.5 + 0.5 * sin(float(i) * 3.3 + float(k) * 2.1)
						* cos(float(i) * 1.7 - float(k) * 5.3))
					var fm := Color(f, f, f, 1.0)
					st.set_color(ccol * fm)
					st.add_vertex(centre)
					st.set_color(cols[k] * fm)
					st.add_vertex(a)
					st.set_color(cols[(k + 1) % 4] * fm)
					st.add_vertex(b)
					continue
				st.set_color(ccol)
				st.add_vertex(centre)
				st.set_color(cols[k])
				st.add_vertex(a)
				st.set_color(cols[(k + 1) % 4])
				st.add_vertex(b)
			# Skirts: a wall down to the base on any INTERIOR edge facing an
			# empty cell - and on a PERIMETER edge once its board has been
			# stripped off, which is the clean face of the new slab the child
			# uncovers (5.3). Never while a board stands there.
			for k in range(4):
				var jx := ix + (1 if k == 1 else (-1 if k == 3 else 0))
				var jz := iz + (1 if k == 2 else (-1 if k == 0 else 0))
				if jx < 0 or jx >= CELLS_X or jz < 0 or jz >= CELLS_Z:
					if not _edge_open(k):
						continue
				elif _fill[jz * CELLS_X + jx] > MIN_DRAW:
					continue
				var a: Vector3 = corners[k]
				var b: Vector3 = corners[(k + 1) % 4]
				var a0 := Vector3(a.x, BASE_TOP, a.z)
				var b0 := Vector3(b.x, BASE_TOP, b.z)
				var scol := ccol.darkened(0.12)
				st.set_color(scol)
				st.add_vertex(a)
				st.add_vertex(b0)
				st.add_vertex(b)
				st.add_vertex(a)
				st.add_vertex(a0)
				st.add_vertex(b0)
	st.generate_normals()
	st.commit(mesh)
	if wet_n > 0:
		_slab_mat.roughness = lerpf(0.92, 0.66, wet_sum / float(wet_n))


## The points shots and the arrow hang off that are not a panel or a board.
func _build_markers() -> void:
	for spec: Array in [["Slab", Vector3(CENTRE_X, GRADE, _mid_z())],
			["Kerb", Vector3(CENTRE_X, GRADE, Z_KERB)],
			["Apron", Vector3(CENTRE_X, GRADE, Z_APRON)],
			["Pile", Vector3(PILE_X, 0.0, PILE_Z)]]:
		var m := Marker3D.new()
		m.name = String(spec[0])
		m.position = spec[1]
		add_child(m)
		_markers[String(spec[0])] = m


## A crack, drawn as a ZIGZAG of short boxes from `a` to `b` in `holder`'s own
## space, stepping `jag` metres off the straight line at every joint.
##
## The user's third note: "crack lines that appear are perfectly straight - they
## should zig zag". Every crack in this file comes through here, the old damage
## the drive arrives with as well as the ones the hammer opens, so there is one
## answer to it rather than one per place that draws a line.
##
## The segments are returned in order from `a`, so a caller that wants a crack to
## RUN - which is what the hammer wants - can reveal them one at a time.
func _zigzag(holder: Node3D, a: Vector3, b: Vector3, segs: int, jag: float,
		width: float, color: Color, rng: RandomNumberGenerator,
		prefix: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var run := b - a
	run.y = 0.0
	if run.length_squared() < 0.0001:
		return out
	# The direction a joint kicks in: square to the crack, in the ground plane.
	var side := Vector3(-run.z, 0.0, run.x).normalized()
	var prev := a
	for i in range(maxi(segs, 1)):
		var t := float(i + 1) / float(maxi(segs, 1))
		var mid := a.lerp(b, t)
		# The last joint lands exactly on `b`, so a crack ends where it is aimed.
		var kick := 0.0
		if i < segs - 1:
			kick = jag * rng.randf_range(0.40, 1.0) * (1.0 if i % 2 == 0 else -1.0)
		var at := mid + side * kick
		var leg := at - prev
		leg.y = 0.0
		var span := leg.length()
		if span < 0.0005:
			prev = at
			continue
		# Each segment overlaps the next a little, or a zigzag is a dotted line
		# with a gap at every corner.
		var seg := _box("%s_%d" % [prefix, i + 1], Vector3(span + width * 0.8, 0.016, width),
			(prev + at) * 0.5, color)
		# A box's long axis is its local +X, and `Basis(UP, y)` sends +X to
		# (cos y, 0, -sin y): the angle that aims it along `leg`.
		seg.rotation.y = atan2(-leg.z, leg.x)
		holder.add_child(seg)
		# The joint this segment ends on, in `holder`'s space: where a weed can
		# grow out of an old crack (4.1).
		seg.set_meta("end", at)
		out.append(seg)
		prev = at
	return out


## Up to `WEEDS_PER_PANEL` tufts at the joints of a panel's old cracks, clear of
## its three hammer spots and of each other (the improvement plan's 4.1). Its own
## generator, seeded off the panel, so a weed can never shift a crack or a stain.
##
## Given a `view` (the first slab, from `replant_first_weeds`), clear of every
## spot's ring AS THAT PICTURE DRAWS IT too: on the opening wide a ring is a
## billboard twice its size seen from low, and a tuft 0.3 m past a spot on the
## ground stood under its gold. The second pass only lets tufts stand closer to
## each other.
func _plant_weeds(holder: Node3D, joints: Array[Vector3], spots: Array[Node3D],
		size: Vector2, index: int, view: Dictionary = {}) -> Array[Node3D]:
	var rng := RandomNumberGenerator.new()
	rng.seed = crack_base + index + 5000
	var order: Array[Vector3] = joints.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	var out: Array[Node3D] = []
	for apart: float in [0.5, 0.32]:
		for j in order:
			if out.size() >= WEEDS_PER_PANEL:
				break
			if absf(j.x) > 0.44 * size.x or absf(j.z) > 0.46 * size.y:
				continue
			var ok := true
			for sp in spots:
				var dx := j.x - sp.position.x
				var dz := j.z - sp.position.z
				if Vector2(dx, dz).length() < WEED_CLEAR:
					ok = false
				if not view.is_empty():
					var root_w := holder.global_transform * Vector3(j.x, SLAB_T * 0.5 + 0.004, j.z)
					for pt: Vector3 in [root_w, root_w + Vector3(0.0, WEED_H, 0.0)]:
						if _under_ring_gold(view, sp.global_position, pt):
							ok = false
			for w in out:
				if Vector2(j.x - w.position.x, j.z - w.position.z).length() < apart:
					ok = false
			if ok:
				out.append(_weed_tuft(holder, Vector3(j.x, SLAB_T * 0.5 + 0.004, j.z), rng,
					"Weed_%d" % (out.size() + 1)))
		if out.size() >= 3:
			break
	return out


## Does a point stand under the GOLD of a lit ring on `view`'s picture? The ring
## on spot `spot` (world) is a billboard drawn at `SpotRings`' keep-scale, its
## gold band from 0.56 to 0.90 of its half-size at the smallest and largest of its
## pulse, with a little margin; the picture is a pinhole at `view.eye` looking
## along `view.basis`, so a band is a circle there whatever the screen's shape.
func _under_ring_gold(view: Dictionary, spot: Vector3, at: Vector3) -> bool:
	var eye: Vector3 = view["eye"]
	var inv: Basis = (view["basis"] as Basis).inverse()
	var ring := spot + Vector3(0.0, 0.06, 0.0)
	var rc := inv * (ring - eye)
	var pc := inv * (at - eye)
	if rc.z > -0.05 or pc.z > -0.05:
		return false
	var fit := clampf(eye.distance_to(ring) / SpotRings.NOMINAL_M, 0.5, 3.0)
	var half: float = float(view["ring_m"]) * fit * 0.5
	var r_in := 0.56 * half * 0.87 * 0.9 / -rc.z
	var r_out := 0.90 * half * 1.13 * 1.08 / -rc.z
	var d := Vector2(pc.x / -pc.z - rc.x / -rc.z, pc.y / -pc.z - rc.y / -rc.z).length()
	return d > r_in and d < r_out


## The first slab's weeds are planted again against the OPENING WIDE's own
## picture, which the level knows and this node does not: that slab's three rings
## are lit on it, and a tuft under their gold was a weed the child never saw
## (the session-4 verification pass). No other slab's rings are ever drawn on it.
func replant_first_weeds(eye: Vector3, look: Vector3, ring_m: float) -> void:
	var p := _panel(1)
	if p.is_empty():
		return
	for w in p.get("weeds", []):
		if is_instance_valid(w):
			(w as Node).free()
	var fwd := (look - eye).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd)
	var view := {"eye": eye, "basis": Basis(right, up, -fwd), "ring_m": ring_m}
	var joints: Array[Vector3] = []
	for j in p.get("joints", []):
		joints.append(j as Vector3)
	var spots: Array[Node3D] = p["spots"]
	var size: Vector2 = p["size"]
	p["weeds"] = _plant_weeds(p["node"], joints, spots, size, 1, view)


## One tuft: a tall stalk, a few shorter blades leaning out round it, and a flat
## dark rosette at its root whose top clears every face of the slab under it.
func _weed_tuft(holder: Node3D, at: Vector3, rng: RandomNumberGenerator, tuft_name: String) -> Node3D:
	var tuft := Node3D.new()
	tuft.name = tuft_name
	tuft.position = at
	tuft.rotation.y = rng.randf_range(0.0, TAU)
	holder.add_child(tuft)
	var tip := Vector3.UP * WEED_H
	for b in range(WEED_BLADES):
		var h := WEED_H if b == 0 else WEED_H * rng.randf_range(0.6, 0.9)
		var lean := deg_to_rad(8.0 if b == 0 else rng.randf_range(18.0, 35.0))
		var yaw := TAU * float(b) / float(WEED_BLADES) + rng.randf_range(-0.3, 0.3)
		var up := Basis.from_euler(Vector3(lean, yaw, 0.0)) * Vector3.UP
		var blade := _box("Blade_%d" % (b + 1), Vector3(WEED_W, h, WEED_W * 0.4), up * h * 0.5,
			WEED if b % 2 == 0 else WEED_DARK)
		blade.rotation = Vector3(lean, yaw, 0.0)
		tuft.add_child(blade)
		if b == 0:
			tip = up * h
	var rosette := _box("Rosette", Vector3(0.11, 0.016, 0.07), Vector3(0.0, 0.006, 0.0), WEED_DARK)
	rosette.rotation.y = rng.randf_range(0.0, TAU)
	tuft.add_child(rosette)
	# The stalk's tip in the tuft's own space, for the smoke's pixel measure.
	tuft.set_meta("tip", tip)
	return tuft


# --- Phase 1: the jackhammer ------------------------------------------------------------------

func panel_count() -> int:
	return _panels.size()


## The node a shot or the arrow hangs off for panel `i` (1-based).
func panel_marker(i: int) -> Node3D:
	var p := _panel(i)
	return p["marker"] if not p.is_empty() else null


func panel_centre(i: int) -> Vector3:
	var p := _panel(i)
	return Vector3(p["home"]) if not p.is_empty() else Vector3.ZERO


## The weed tufts growing in panel `i`'s old cracks (4.1).
func panel_weeds(i: int) -> Array[Node3D]:
	var p := _panel(i)
	var out: Array[Node3D] = []
	if not p.is_empty():
		for w in p.get("weeds", []):
			out.append(w as Node3D)
	return out


## The height of panel `i`'s top face at `u`, a point in -0.5..0.5 of its size
## across and along it, where the panel stands NOW (settled, sunk by the bites).
func panel_top_at(i: int, u: Vector2) -> float:
	var p := _panel(i)
	if p.is_empty():
		return 0.0
	var s: Vector2 = p["size"]
	var node: Node3D = p["node"]
	return (node.global_transform * Vector3(u.x * s.x, SLAB_T * 0.5 + 0.006, u.y * s.y)).y


## How big panel `i` is, for sizing the arrow to it.
func panel_radius(i: int) -> float:
	var p := _panel(i)
	if p.is_empty():
		return 0.9
	var s: Vector2 = p["size"]
	return minf(s.x, s.y) * 0.5


# --- The three spots on a panel ---------------------------------------------------------------
#
# The phase is eighteen taps, not six holds: three places on each of six panels
# ("3 clicks per section in three different spots"). A spot is addressed by ONE
# number from 1 to 18, because that is what a job step's `Jack_*` target counts
# up, and the panel and the spot within it are worked out from it here rather
# than by every caller.

## How many spots the whole phase has.
func jack_spots() -> int:
	return _panels.size() * SPOTS_PER_PANEL


## Which panel spot `n` (1-based, 1..18) belongs to, and which of its three it is.
func spot_panel(n: int) -> int:
	return (n - 1) / SPOTS_PER_PANEL + 1


func spot_index(n: int) -> int:
	return (n - 1) % SPOTS_PER_PANEL + 1


## The marker the camera hangs off and the arrow points at for spot `n`.
func spot_marker(n: int) -> Node3D:
	var p := _panel(spot_panel(n))
	if p.is_empty():
		return null
	var spots: Array[Node3D] = p["spots"]
	var at := spot_index(n) - 1
	return spots[at] if at >= 0 and at < spots.size() else null


## How big a spot is, for sizing the arrow and the tap's reach to it: a third of
## a panel, not the whole slab.
func spot_radius() -> float:
	return 0.40


## Has spot `n` been worked already?
func spot_done(n: int) -> bool:
	var p := _panel(spot_panel(n))
	if p.is_empty():
		return true
	var hit: Array[bool] = p["hit"]
	var at := spot_index(n) - 1
	return at < 0 or at >= hit.size() or hit[at]


## The panel being worked: the first one, from the kerb, that has not come
## apart. By STATE, never by counting beats: a beat that landed on a spot that
## was already done (a queued tap after the rings had been cleared) used to
## push the count past a panel with a spot still open, and that panel never
## broke (the user's 2026-09-14 playtest: "one of the cement driveway sections
## didn't break").
func current_panel() -> int:
	for i in range(1, _panels.size() + 1):
		if not panel_is_broken(i):
			return i
	return _panels.size()


## The first spot still open on panel `i`, or 0 when none is.
func first_open_spot(i: int) -> int:
	var open := open_spots(i)
	return open[0] if not open.is_empty() else 0


## The spots on panel `i` that are still to be worked, as GLOBAL spot numbers.
## What the gold rings are lit on, and what a tap is allowed to choose between.
func open_spots(i: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for s in range(1, SPOTS_PER_PANEL + 1):
		var n := (i - 1) * SPOTS_PER_PANEL + s
		if not spot_done(n):
			out.append(n)
	return out


## Has panel `i` had all three of its bites? Asked AFTER a bite lands, to decide
## whether that was the one that let the slab go - which, now that the three may
## be taken in any order, is not simply "the third one".
func panel_ready(i: int) -> bool:
	return panel_spots_done(i) >= SPOTS_PER_PANEL


## Works spot `n` with the hammer, `k` 0 to 1 through that one bite.
##
## Its crack runs out from under the bit a segment at a time, and the panel sinks
## by a third of its travel per spot - so what a child watches is concrete GIVING
## where they put the hammer, three times, and then letting go.
func jack_spot(n: int, k: float) -> void:
	var i := spot_panel(n)
	var p := _panel(i)
	if p.is_empty() or bool(p["broken"]):
		return
	var kk := clampf(k, 0.0, 1.0)
	var at := spot_index(n) - 1
	var cracks: Array = p["cracks"]
	if at >= 0 and at < cracks.size():
		var segs: Array = cracks[at]
		# The crack RUNS: one more segment of it for every step of the work.
		var show := int(ceil(float(segs.size()) * kk))
		for c in range(segs.size()):
			(segs[c] as Node3D).visible = c < show
	var hit: Array[bool] = p["hit"]
	if kk >= 0.999 and at >= 0 and at < hit.size():
		hit[at] = true
	var done := 0
	for h in hit:
		if h:
			done += 1
	# The panel sinks by a third for every bite it has had, wherever those bites
	# were taken: the three may be worked in any order.
	var through := clampf((float(done) + (0.0 if (at >= 0 and at < hit.size() and hit[at]) else kk))
		/ float(SPOTS_PER_PANEL), 0.0, 1.0)
	p["jacked"] = through
	var sink: float = config.panel_sink if config != null else 0.035
	var node: Node3D = p["node"]
	# From where it RESTS: the settled slab starts a step down (4.1), and a sink
	# written from the level home put it back up on the first frame of a bite.
	var rest: float = p.get("rest_dy", 0.0)
	node.position.y = Vector3(p["home"]).y + rest - sink * through


## How many of panel `i`'s three spots are finished.
func panel_spots_done(i: int) -> int:
	var p := _panel(i)
	if p.is_empty():
		return 0
	var n := 0
	for h: bool in p["hit"]:
		if h:
			n += 1
	return n


## The panel lets go: it becomes `CHUNKS_PER_PANEL` lumps of concrete lying in
## the hole, which the skid steer will push off.
func break_panel(i: int, animate: bool = true) -> void:
	var p := _panel(i)
	if p.is_empty() or bool(p["broken"]):
		return
	p["broken"] = true
	set_banks(1.0)
	for clod in _clods:
		clod.visible = true
	var node: Node3D = p["node"]
	node.visible = false
	var size: Vector2 = p["size"]
	var home := Vector3(p["home"])
	var rng := RandomNumberGenerator.new()
	# Seeded off the panel, so a replayed job breaks the same way twice - which
	# is what lets a screenshot be compared with the one before it.
	rng.seed = 2026 * 100 + i
	# Which push pass will clear these: the COLUMN the panel stood in, stamped on
	# every chunk now so that pushing them never loses track of them.
	#
	# The column, not the band across the drive. A pass that takes a band has to
	# start BEHIND that band, and the only ground behind the band at the garage end
	# is the garage - which is exactly what the user saw the machine reverse into,
	# through the rubble, on its way. A pass that takes a COLUMN starts once, at the
	# garage end, and pushes the full nine metres to the kerb; there are two of
	# them because the drive is two panels wide and a skid steer's bucket is one
	# panel wide. Nothing is ever driven over and nothing is ever driven through.
	var lane := (i - 1) % PANELS_X + 1
	var made: Array[Node3D] = []
	# The HOP (the improvement plan's 1.5): the panel does not turn into rubble
	# in a cut, it bursts - every chunk starts `chunk_hop` up (the outer ones
	# further, so it bursts outward from the bite) and bounces down over
	# `chunk_hop_time`, each a moment after the last. Its own numbers, so the
	# chunks themselves lie exactly where they always did.
	var hop_rng := RandomNumberGenerator.new()
	hop_rng.seed = 2026 * 100 + i + 777
	var hop: float = config.chunk_hop if config != null else 0.14
	var hop_time: float = config.chunk_hop_time if config != null else 0.35
	for c in range(CHUNKS_PER_PANEL):
		var cx := rng.randf_range(-0.34, 0.34) * size.x
		var cz := rng.randf_range(-0.38, 0.38) * size.y
		var w := size.x * rng.randf_range(0.26, 0.42)
		var l := size.y * rng.randf_range(0.20, 0.34)
		var chunk := _box("Chunk", Vector3(w, SLAB_T * rng.randf_range(0.9, 1.2), l),
			home + Vector3(cx, -SLAB_T * 0.45, cz), OLD_CONCRETE_DARK)
		# Enough tilt to stand a piece on its edge. At +-9 degrees forty-eight
		# slabs lay in tidy rows and read as paving somebody had laid, not as a
		# driveway somebody had broken.
		chunk.rotation = Vector3(deg_to_rad(rng.randf_range(-35.0, 35.0)),
			deg_to_rad(rng.randf_range(-180.0, 180.0)),
			deg_to_rad(rng.randf_range(-35.0, 35.0)))
		add_child(chunk)
		# A paler top, like the panel it came off: a chunk seen from above is
		# mostly its broken face, and all-dark chunks read as earth.
		var face := _box("Face", Vector3(w * 0.92, 0.01, l * 0.92),
			Vector3(0.0, SLAB_T * 0.5, 0.0), OLD_CONCRETE)
		chunk.add_child(face)
		chunk.set_meta("lane", lane)
		made.append(chunk)
		_chunks.append(chunk)
		if animate and hop > 0.0:
			var rest := chunk.position
			var outer := absf(cx) > 0.20 * size.x or absf(cz) > 0.24 * size.y
			chunk.position = rest + Vector3(0.0, hop * (1.3 if outer else 1.0), 0.0)
			var tw := create_tween()
			tw.tween_interval(hop_rng.randf_range(0.0, 0.08))
			tw.set_parallel(true)
			tw.tween_property(chunk, "position", rest, hop_time) \
				.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.tween_property(chunk, "rotation:y", chunk.rotation.y + hop_rng.randf_range(-0.35, 0.35), hop_time)
	p["chunks"] = made
	panel_broken_up.emit(i)


## The last of the slab wets itself at the water beat's end, `k` 0..1: the beat
## ends at `scrub_done`, and the dry corners come up while the hose is put away
## so the child sees the whole thing wet before the picture moves on (the
## improvement plan's 1.6).
func finish_water(k: float) -> void:
	var kk := clampf(k, 0.0, 1.0)
	for i in range(_watered.size()):
		if _watered[i] < kk:
			_watered[i] = kk
			_paint_cell(i)


## The last of bay `b` brushes itself at its beat's end, the same way.
func finish_bay(b: int, k: float) -> void:
	var band := bay_range(b)
	var kk := clampf(k, 0.0, 1.0)
	for iz in range(CELLS_Z):
		var z := _cell_z(iz)
		if z < band.x or z > band.y:
			continue
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			if _brushed[i] < kk:
				_brushed[i] = kk
				if (_cell_lines[i] as Array).is_empty() and _brushed[i] > 0.05:
					_brush_lines(i)
				_paint_cell(i)


func panel_is_broken(i: int) -> bool:
	var p := _panel(i)
	return not p.is_empty() and bool(p["broken"])


func panels_broken() -> int:
	var n := 0
	for p: Dictionary in _panels:
		if bool(p["broken"]):
			n += 1
	return n


func chunks_left() -> int:
	var n := 0
	for c in _chunks:
		if is_instance_valid(c) and c.visible:
			n += 1
	return n


# --- Phase 2: the skid steer pushes it out ----------------------------------------------------

## How many passes clear the pad: one per COLUMN of the old drive, each the full
## length of it, because that is the only way a machine can push without first
## driving over what it is about to push.
func push_lanes() -> int:
	return PANELS_X


## The middle of lane `lane` in x - the line the machine drives down.
func lane_x(lane: int) -> float:
	var pw := (WIDTH - PANEL_GAP * float(PANELS_X - 1)) / float(PANELS_X)
	return CENTRE_X - WIDTH * 0.5 + pw * 0.5 + float(lane - 1) * (pw + PANEL_GAP)


## Where the MACHINE drives for lane `lane`: the lane's middle pulled a little
## toward the drive's centre, so a 1.9 m skid steer keeps its outer wheels off
## the trench (round 5: they rode the pad's edge). The blade is 2.04 m wide and
## still covers the lane.
func lane_drive_x(lane: int) -> float:
	var x := lane_x(lane)
	return x + (CENTRE_X - x) * 0.18


## Where the gold mark goes during a push: the FIRST rubble the blade will meet
## in that lane, which is the piece nearest the garage end.
##
## Not the mean of what is left. The push is watched on the bucket, and the bucket
## starts inside the garage - so a mark on the middle of nine metres of rubble sat
## four metres from the middle of the picture, half off the bottom of the frame.
## The nearest piece is in front of the blade and stays in front of it, because
## that is what a blade does to it.
func lane_centre(lane: int) -> Vector3:
	var front := 9.0
	var any := false
	for c in lane_chunks(lane):
		front = minf(front, c.position.z)
		any = true
	return Vector3(lane_x(lane), GRADE, front + 0.4 if any else _mid_z())


## Every chunk that CAME OUT of lane `lane`, wherever it has since been shoved.
##
## By the lane it was born in, not the band it is standing in now: a chunk being
## pushed toward the kerb leaves its own lane's band within a second of the blade
## touching it, and filtering on live position quietly abandoned two thirds of
## the rubble half way down the drive (32 lumps left on a pad the job had already
## called clear).
func lane_chunks(lane: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for c in _chunks:
		if not is_instance_valid(c) or not c.visible:
			continue
		if int(c.get_meta("lane", 0)) == lane:
			out.append(c)
	return out


## Pushes a lane's rubble along with the bucket. `blade_z` is where the cutting
## edge is now: a chunk the blade has reached is carried in front of it, and
## chunks bunch up against each other rather than passing through.
func push_lane(lane: int, blade_z: float, to_pile: bool = false) -> void:
	var held := 0
	for c in lane_chunks(lane):
		if c.position.z < blade_z - 0.05:
			continue
		# In front of the blade, stacked back from it by how many are already there.
		var want := blade_z + 0.22 + 0.12 * float(held)
		if want > c.position.z:
			c.position.z = want
			# A pushed lump grinds round as it goes, which is what says it is
			# being shoved and not carried.
			c.rotation.y += 0.9 * get_process_delta_time()
			held += 1
	if to_pile:
		_tip_into_pile(lane)


## The bucket tips at the pile: whatever it was carrying lands on the heap.
func _tip_into_pile(lane: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + lane
	# A CONE of everything that has come off the drive so far - the first
	# pieces out at the foot, the last ones up on top - counted across both
	# passes, so the second load stacks on the first instead of in it. It ends
	# a stride wide and taller than the mailbox: a driveway came out (round 6).
	var total := float(maxi(_chunks.size(), 1))
	# Everything this pass was responsible for goes on the heap: the beat only
	# ends once the blade has swept the whole lane, so by here they have all been
	# shoved to the kerb whether or not the child dawdled on the way.
	for c in lane_chunks(lane):
		var k := float(_piled) / total
		var r := 1.15 * sqrt(maxf(1.0 - k, 0.02))
		var a := rng.randf_range(0.0, TAU)
		c.position = Vector3(PILE_X + cos(a) * r, 0.06 + 1.0 * k, PILE_Z + sin(a) * r)
		# On the heap a piece casts no shadow: stacked, every side was in the
		# shadow of the piece above and the heap rendered at half the value of
		# the same rubble on the drive - a hole in the corner of four working
		# frames (round 12).
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for ch in c.get_children():
			if ch is GeometryInstance3D:
				(ch as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Flatter: tipped to thirty degrees the heap showed the pieces' dark
		# sides and read as slate beside the pale rubble on the drive (round 11).
		c.rotation = Vector3(deg_to_rad(rng.randf_range(-12.0, 12.0)), a,
			deg_to_rad(rng.randf_range(-12.0, 12.0)))
		_piled += 1
	for rut in _ruts:
		rut.visible = true
	if chunks_on_pad() == 0 and not _cleared_emitted:
		_cleared_emitted = true
		pad_cleared.emit()


## Chunks still lying on the pad (as opposed to on the heap).
func chunks_on_pad() -> int:
	var n := 0
	for c in _chunks:
		if not is_instance_valid(c) or not c.visible:
			continue
		# The PAD's real footprint. At 0.75 of the width this box reached 2.7 m
		# either side of the drive and counted the heap on the lawn as rubble still
		# lying on the driveway as soon as the heap was allowed to spread.
		if c.position.z > Z_APRON - 0.2 and c.position.z < Z_KERB - 0.4 				and absf(c.position.x - CENTRE_X) < WIDTH * 0.5 + 0.2:
			n += 1
	return n


func pile_point() -> Vector3:
	return Vector3(PILE_X, 0.0, PILE_Z)


# --- Phases 3 and 4: the forms ----------------------------------------------------------------

func form_count() -> int:
	return _forms.size()


func form_marker(i: int) -> Node3D:
	var f := _at(_forms, i)
	return f["marker"] if not f.is_empty() else null


## Where a form board is being asked to go, while it is still in the air. The
## arrow points at the HOME, not at the board: the child is being asked to look
## at the edge of the hole the board belongs on.
func form_home(i: int) -> Vector3:
	var f := _at(_forms, i)
	return Vector3(f["home"]) if not f.is_empty() else Vector3.ZERO


## Drops board `i` into place: `k` 0 is up in the air, 1 is home.
func set_form(i: int, k: float) -> void:
	var f := _at(_forms, i)
	if f.is_empty():
		return
	var kk := clampf(k, 0.0, 1.0)
	if kk >= 0.999 and float(f["k"]) < 0.999:
		_last_form_group = form_group(i)
	f["k"] = kk
	var node: Node3D = f["node"]
	node.visible = true
	var up: float = config.form_drop_height if config != null else 0.9
	node.position = Vector3(f["home"]) + Vector3(0.0, up * (1.0 - kk), 0.0)
	# The board's shadow in the trench while it waits.
	var mark := f.get("mark") as Node3D
	if mark == null:
		var size: Vector3 = (node as MeshInstance3D).mesh.get_aabb().size
		mark = _box("FormMark", Vector3(size.x + 0.04, 0.004, size.z + 0.04),
			Vector3(f["home"]) - Vector3(0.0, size.y * 0.5 - 0.004, 0.0), Color(0.24, 0.18, 0.12))
		add_child(mark)
		f["mark"] = mark
	mark.visible = kk < 0.98
	# It comes down at a slight angle and settles square, the way a board is
	# dropped in by hand.
	node.rotation.z = deg_to_rad(7.0 * (1.0 - kk))


## Is board `i` already down, and which boards are still waiting? The gold rings
## are lit on the ones that are not, and the child may take them in any order.
func form_is_in(i: int) -> bool:
	var f := _at(_forms, i)
	return not f.is_empty() and float(f["k"]) >= 0.999


func open_forms() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in range(1, _forms.size() + 1):
		if not form_is_in(i):
			out.append(i)
	return out


func forms_in() -> int:
	var n := 0
	for f: Dictionary in _forms:
		if float(f["k"]) >= 0.999:
			n += 1
	return n


## The boards are set in three GROUPS, for the camera (round 4: the FORM shot
## was the last one watched from across the street): the two long boards, seen
## across the form from the lawn; then the kerb board; then the strip at the
## apron.
func form_group(i: int) -> int:
	if i <= 2:
		return 0
	return 1 if i == KERB_BOARD else 2


func form_group_count() -> int:
	return FORM_GROUPS


## Is board `i` one the job can take now? The KERB board is not, until the base
## is laid and packed: both trucks back in through that end, and a board pinned
## there would be driven over (the improvement plan's 5.2, the user's decision
## 5). Which places are live is STATE, not a count of taps - the job's second
## `form_set` row simply finds the kerb board is the only one left.
func form_live(i: int) -> bool:
	return i != KERB_BOARD or base_ready()


## The base is down and packed flat: the form's open end can be closed.
func base_ready() -> bool:
	return _gravel_k >= 0.999 and _pack_baked


## Is board `i` standing on the site (waiting in the air, or in)?
func form_shown(i: int) -> bool:
	var f := _at(_forms, i)
	return not f.is_empty() and (f["node"] as Node3D).visible


func form_k(i: int) -> float:
	var f := _at(_forms, i)
	return float(f["k"]) if not f.is_empty() else 0.0


func open_forms_in(g: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in range(1, _forms.size() + 1):
		if form_group(i) == g and not form_is_in(i) and form_live(i):
			out.append(i)
	return out


## Every board the job can take now and has not, group by group.
func live_open_forms() -> PackedInt32Array:
	var out := PackedInt32Array()
	for g in range(form_group_count()):
		out.append_array(open_forms_in(g))
	return out


func current_form_group() -> int:
	for g in range(form_group_count()):
		if not open_forms_in(g).is_empty():
			return g
	return -1


## The group whose last board went in most recently, for the camera to stay on
## once a row's boards are all in (-1 before any): the strip after the first
## row, the kerb board after its own. Staying on "the last group by number"
## put the picture 9 m away on the strip after the kerb board went in.
func last_form_group() -> int:
	return _last_form_group


func form_group_mark(g: int) -> Node3D:
	var key := "FormGroup_%d" % g
	if _markers.has(key):
		return _markers[key]
	if g < 0 or g >= form_group_count():
		return null
	var at := Vector3(CENTRE_X, GRADE, _mid_z())
	if g == 1:
		at = Vector3(form_home(3).x, GRADE, form_home(3).z)
	elif g == 2:
		at = Vector3(form_home(4).x, GRADE, form_home(4).z)
	var m := Marker3D.new()
	m.name = key
	add_child(m)
	m.global_position = at
	_markers[key] = m
	return m


func stake_count() -> int:
	return _stakes.size()


func stake_marker(i: int) -> Node3D:
	var s := _at(_stakes, i)
	return s["marker"] if not s.is_empty() else null


## Where stake `i` is being asked to go: the head of it once it is driven, which
## is a point that does not move while the stake does.
func stake_home(i: int) -> Vector3:
	var s := _at(_stakes, i)
	if s.is_empty():
		return Vector3.ZERO
	return Vector3(s["home"]) + Vector3(0.0, STAKE_H * 0.5 + STAKE_STUB, 0.0)


## The middle of stake `i`'s painted cap where it stands NOW: proud before its
## blow, a stub above the board after. The ring sits on it; the sledge lands on
## its top (`stake_cap(i).y + STAKE_CAP * 0.5`).
## Which way the board this peg stands against RUNS. The sledge swings in that
## plane, so the arc is across the STAKE picture rather than into it: a handle
## that always ran toward the garage was foreshortened to a bob at the kerb
## pair, whose camera stands in the road looking back.
func stake_along(i: int) -> Vector3:
	if i < 1 or i > _stakes.size():
		return Vector3.FORWARD
	return _stakes[i - 1].get("along", Vector3.FORWARD)


func stake_cap(i: int) -> Vector3:
	var s := _at(_stakes, i)
	if s.is_empty():
		return Vector3.ZERO
	return (s["node"] as Node3D).position + Vector3(0.0, STAKE_CAP_Y, 0.0)


## Is stake `i` standing on the site (waiting or driven)?
func stake_shown(i: int) -> bool:
	var s := _at(_stakes, i)
	return not s.is_empty() and (s["node"] as Node3D).visible


## Drives stake `i`: `k` 0 is standing proud, 1 is driven down to its stub,
## `STAKE_STUB` above the board.
func set_stake(i: int, k: float) -> void:
	var s := _at(_stakes, i)
	if s.is_empty():
		return
	var kk := clampf(k, 0.0, 1.0)
	if kk >= 0.999 and float(s["k"]) < 0.999:
		_last_stake_group = int(s.get("group", -1))
	s["k"] = kk
	var node: Node3D = s["node"]
	node.visible = true
	node.position = Vector3(s["home"]) + Vector3(0.0, STAKE_PROUD * (1.0 - kk) + STAKE_STUB * kk, 0.0)


func stake_is_in(i: int) -> bool:
	var s := _at(_stakes, i)
	return not s.is_empty() and float(s["k"]) >= 0.999


## The board stake `i` pins (1-based).
func stake_board(i: int) -> int:
	var s := _at(_stakes, i)
	return int(s.get("board", 0)) if not s.is_empty() else 0


## A peg is live once ITS board is in: the kerb board's two wait for the kerb
## board (5.2), and nothing pins a board that is not there.
func stake_live(i: int) -> bool:
	return form_is_in(stake_board(i))


## The pegs of board `i`, in order along it.
func stakes_of_form(i: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for n in range(1, _stakes.size() + 1):
		if stake_board(n) == i:
			out.append(n)
	return out


## The group whose last peg went in most recently (-1 before any).
func last_stake_group() -> int:
	return _last_stake_group


func open_stakes() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in range(1, _stakes.size() + 1):
		if not stake_is_in(i):
			out.append(i)
	return out


func stake_group_count() -> int:
	return _stake_groups.size()


## Which group stake `i` is in, or -1.
func stake_group(i: int) -> int:
	var s := _at(_stakes, i)
	return int(s.get("group", -1)) if not s.is_empty() else -1


## The stakes of group `g` that are still standing proud.
func open_stakes_in(g: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if g < 0 or g >= _stake_groups.size():
		return out
	for i in _stake_groups[g]:
		if not stake_is_in(i) and stake_live(i):
			out.append(i)
	return out


## The group being worked: the first one, from the garage end, with a stake
## still to go in. -1 when they are all driven.
func current_stake_group() -> int:
	for g in range(_stake_groups.size()):
		if not open_stakes_in(g).is_empty():
			return g
	return -1


## A marker in the middle of group `g`, at the height of a driven stake's head,
## for the `STAKE` shot to hang off. Built on demand and kept, because a shot
## re-reads its anchor every frame and a node made per frame would never settle.
func stake_group_mark(g: int) -> Node3D:
	if g < 0 or g >= _stake_groups.size():
		return null
	while _stake_group_marks.size() < _stake_groups.size():
		_stake_group_marks.append(null)
	if _stake_group_marks[g] != null and is_instance_valid(_stake_group_marks[g]):
		return _stake_group_marks[g]
	var mid := Vector3.ZERO
	for i in _stake_groups[g]:
		mid += stake_home(i)
	mid /= maxf(float(_stake_groups[g].size()), 1.0)
	var mark := Marker3D.new()
	mark.name = "StakeGroup_%d" % (g + 1)
	add_child(mark)
	mark.global_position = mid
	# A pair on the far (+X) board is looked at from the far lawn: the shot's
	# offsets are mirrored across the drive (`CameraRig` reads this meta).
	if mid.x > CENTRE_X + 0.3:
		mark.set_meta("flip_x", true)
	# The pair on the kerb-end board lies ACROSS the drive: the same close
	# picture turned a quarter, from the road's edge, the drive beyond.
	var ids := _stake_groups[g]
	if ids.size() >= 2 and absf(stake_home(ids[0]).x - stake_home(ids[1]).x) > 0.3:
		mark.set_meta("shot_eye", Vector3(-1.6, 1.4, 0.8))
		mark.set_meta("shot_look", Vector3(0.6, -0.55, -0.6))
	_stake_group_marks[g] = mark
	return mark


func stakes_in() -> int:
	var n := 0
	for s: Dictionary in _stakes:
		if float(s["k"]) >= 0.999:
			n += 1
	return n


# --- Phase 5: the gravel base -----------------------------------------------------------------

## Lays the base: `k` 0 is bare dirt, 1 is the whole pad bedded up to BASE_TOP.
##
## It grows ALONG the drive, at full depth, from the garage end out - because that
## is what a tipper does. It backs the length of the drive, lifts the bed and
## pulls forward, and what comes out is a windrow that gets longer. The base used
## to grow in HEIGHT instead, everywhere at once, which is a bath filling.
func gravel_fill(k: float) -> void:
	_gravel_k = clampf(k, 0.0, 1.0)
	var depth := BASE_TOP + DIG
	var run := maxf(LENGTH * _gravel_k, 0.001)
	var bm := _gravel.mesh as BoxMesh
	bm.size = Vector3(WIDTH, depth, run)
	_gravel.position = Vector3(CENTRE_X, -DIG + depth * 0.5, Z_APRON + run * 0.5)
	_gravel.visible = _gravel_k > 0.001
	var front := gravel_front_z()
	for stone in _stones:
		stone.visible = _gravel_k > 0.001 and stone.position.z <= front


func gravel_k() -> float:
	return _gravel_k


## How far down the drive the base has reached.
func gravel_front_z() -> float:
	return Z_APRON + LENGTH * _gravel_k


func gravel_top() -> float:
	return BASE_TOP if _gravel_k > 0.001 else -DIG


func stones_down() -> int:
	var n := 0
	for stone in _stones:
		if stone.visible:
			n += 1
	return n


# --- Phase 5a: the plate compactor ------------------------------------------------------------

## Packs the base under the plate (the improvement plan's 5.1, the user's
## decision 6): every cell whose middle is within `radius` of the plate rises
## toward packed, its stones lie down flat into the bed, and the bed goes a
## step PALER where it is packed - a luma step, not a warmth, which is what a
## child can see (the rule the water's dark and the broom's pale taught). With
## `radius` between a cell's along-drive neighbour (0.75 m) and its diagonal
## (0.96 m), a plate held still packs a plus sign and nothing more.
func paint_pack(world: Vector3, radius: float, rate: float, z_lo: float = -INF, z_hi: float = INF) -> void:
	var hits := _raise(_packed, world, radius, rate, z_lo, z_hi)
	if hits.is_empty():
		return
	_pack_cells(hits)


## One bay's last patches go down on their own as the plate lifts off it (the
## plan's 1.6); the last bay's end bakes the packed colour into the base.
func finish_pack_bay(b: int, k: float) -> void:
	var band := bay_range(b)
	var hits := PackedInt32Array()
	for iz in range(CELLS_Z):
		if _cell_z(iz) < band.x or _cell_z(iz) > band.y:
			continue
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			if _packed[i] < k:
				_packed[i] = maxf(_packed[i], clampf(k, 0.0, 1.0))
				hits.append(i)
	if not hits.is_empty():
		_pack_cells(hits)
	if k >= 0.999 and b >= bay_count():
		_bake_packed()


## A posed bay: packed flat, as the verb leaves it.
func pack_bay(b: int) -> void:
	finish_pack_bay(b, 1.0)


func pack_all() -> void:
	for b in range(1, bay_count() + 1):
		pack_bay(b)
	_bake_packed()


## How much of the base (or of one band of it) is packed, 0..1.
func pack_coverage() -> float:
	return _mean(_packed)


func pack_coverage_in(z_lo: float, z_hi: float) -> float:
	var sum := 0.0
	var n := 0
	for iz in range(CELLS_Z):
		if _cell_z(iz) < z_lo or _cell_z(iz) > z_hi:
			continue
		for ix in range(CELLS_X):
			sum += minf(_packed[iz * CELLS_X + ix], 1.0)
			n += 1
	return sum / float(maxi(n, 1))


## How packed the cell under a world point is.
func packed_at(world: Vector3) -> float:
	var cw := WIDTH / float(CELLS_X)
	var cl := LENGTH / float(CELLS_Z)
	var ix := int(floor((world.x - (CENTRE_X - WIDTH * 0.5)) / cw))
	var iz := int(floor((world.z - Z_APRON) / cl))
	if ix < 0 or ix >= CELLS_X or iz < 0 or iz >= CELLS_Z:
		return 0.0
	return _packed[iz * CELLS_X + ix]


## The cells packed past `threshold`, as indices (a test's plus sign).
func packed_cells(threshold: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in range(_packed.size()):
		if _packed[i] >= threshold:
			out.append(i)
	return out


## The least-packed cell's middle inside a band, on the base.
func least_packed_in(z_lo: float, z_hi: float) -> Vector3:
	var worst := -1
	var low := 9.0
	for iz in range(CELLS_Z):
		if _cell_z(iz) < z_lo or _cell_z(iz) > z_hi:
			continue
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			if _packed[i] < low:
				low = _packed[i]
				worst = i
	if worst < 0:
		return Vector3(CENTRE_X, BASE_TOP, (z_lo + z_hi) * 0.5)
	return Vector3(_cell_x(worst % CELLS_X), BASE_TOP, _cell_z(worst / CELLS_X))


## Where the plate waits to start bay `b`: on the middle of a cell with a
## neighbour on every side, at the NEAR (kerb) end of the bay - nearest the eye,
## which stands beyond that end - so the child pushes it away up the drive the
## way an operator walks behind one, and the plate is big in the picture.
func plate_start(b: int) -> Vector3:
	var band := bay_range(b)
	var cl := LENGTH / float(CELLS_Z)
	# `- 0.01`: a bay's range is a Vector2, 32-bit, so its ends are a hair off the
	# constants', and a bare floor on an exact row boundary lands a row out.
	var last := int(floor((band.y - Z_APRON) / cl - 0.01))
	var iz := clampi(last - 1, 0, CELLS_Z - 1)
	return Vector3(_cell_x(2), BASE_TOP, _cell_z(iz))


## A plate walked by a finger stays on the base, inside the forms and inside
## its own bay.
func clamp_plate(world: Vector3, b: int) -> Vector3:
	# `b <= 0` is THE WHOLE BASE, apron to kerb. `bay_range` clamps a 0 up to
	# bay 1, which would pen the plate at the garage end - and the whole point
	# of the 2026-09-16 playtest fix is that it does not matter where you pack.
	var band := Vector2(Z_APRON, Z_KERB) if b <= 0 else bay_range(b)
	return Vector3(
		clampf(world.x, CENTRE_X - WIDTH * 0.5 + PLATE_HALF.x, CENTRE_X + WIDTH * 0.5 - PLATE_HALF.x),
		BASE_TOP,
		clampf(world.z, band.x + PLATE_HALF.y, band.y - PLATE_HALF.y))


## Is every stone on the base lying flat, read off the stones themselves?
func stones_flat() -> bool:
	for stone in _stones:
		if not stone.visible:
			continue
		if stone.global_basis.y.normalized().dot(Vector3.UP) < cos(deg_to_rad(1.0)):
			return false
	return true


## Is the packed colour baked into the base (the plate has done all of it)?
func pack_baked() -> bool:
	return _pack_baked


## What colour the base is drawn now: loose limestone, or packed.
func gravel_colour() -> Color:
	return GRAVEL_PACKED if _pack_baked else GRAVEL


## The colour a cell of the bed is drawn at its packing.
func _pack_col(p: float) -> Color:
	if p >= PACK_STEP:
		return GRAVEL_PACKED
	return GRAVEL.lerp(GRAVEL_PACKED, 0.30 * p / PACK_STEP)


## Raises a coverage grid round a point without repainting any concrete: the
## plate works under the slab's cells, which `_paint` would redraw every frame.
func _raise(grid: PackedFloat32Array, world: Vector3, radius: float,
		rate: float, z_lo: float = -INF, z_hi: float = INF) -> PackedInt32Array:
	var hit := PackedInt32Array()
	var r := maxf(radius, 0.05)
	for iz in range(CELLS_Z):
		if _cell_z(iz) < z_lo or _cell_z(iz) > z_hi:
			continue
		for ix in range(CELLS_X):
			var d := Vector2(_cell_x(ix) - world.x, _cell_z(iz) - world.z).length()
			if d > r:
				continue
			var i := iz * CELLS_X + ix
			if grid[i] >= 1.0:
				continue
			grid[i] = minf(grid[i] + rate * (1.0 - 0.6 * d / r), 1.0)
			hit.append(i)
	return hit


## The stones of the packed cells lie down into the bed, a ragged front rather
## than a tile at a time (each stone has its own `jit`), and take the packed
## step of colour; the bed is redrawn.
func _pack_cells(cells: PackedInt32Array) -> void:
	_packed_any = true
	for c in cells:
		if c < 0 or c >= _cell_stones.size():
			continue
		for n in _cell_stones[c]:
			var rest: Dictionary = _stone_rest[n]
			var u := clampf((_packed[c] - float(rest["jit"])) / 0.5, 0.0, 1.0)
			var stone := _stones[n]
			var flat := Quaternion(Vector3.UP, float(rest["yaw"]))
			stone.quaternion = Quaternion(rest["q"]).slerp(flat, u)
			var h: float = rest["h"]
			stone.position.y = lerpf(float(rest["y"]), BASE_TOP - h * 0.5 + STONE_FLAT_PROUD, u)
			var mat := stone.get_active_material(0) as StandardMaterial3D
			if mat != null:
				var col: Color = rest["col"]
				mat.albedo_color = col.lightened(PACK_LIGHTEN) if _packed[c] >= PACK_STEP else col
	_bed_dirty = true
	if not is_processing():
		set_process(true)


## The packed colour becomes the base's own, and the overlay bed goes: once the
## plate is done there is no plane left 2 mm over the base to fight the pour's
## front, the landing marks or the chairs' feet.
func _bake_packed() -> void:
	_pack_baked = true
	_packed_any = true
	var mat := _gravel.get_active_material(0) as StandardMaterial3D
	if mat != null:
		mat.albedo_color = GRAVEL_PACKED
	if _bed != null:
		_bed.visible = false
	_bed_dirty = false


## The bed: one fan of four triangles per cell at `BASE_TOP + BED_Y`, coloured by
## how packed it is, the corners blended with the neighbours' so the step reads
## as the ground changing and not as tiles.
func _rebuild_bed() -> void:
	_bed_dirty = false
	if _pack_baked or not _packed_any:
		if _bed != null:
			_bed.visible = false
		return
	if _bed == null:
		_bed = MeshInstance3D.new()
		_bed.name = "PackedBed"
		_bed.mesh = ArrayMesh.new()
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.albedo_color = Color.WHITE
		mat.roughness = 0.9
		_bed.material_override = mat
		_bed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_bed)
	var mesh := _bed.mesh as ArrayMesh
	mesh.clear_surfaces()
	var cw := WIDTH / float(CELLS_X)
	var cl := LENGTH / float(CELLS_Z)
	var y := BASE_TOP + BED_Y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for iz in range(CELLS_Z):
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			var centre := Vector3(_cell_x(ix), y, _cell_z(iz))
			var ccol := _pack_col(_packed[i])
			var corners: Array[Vector3] = []
			var cols: Array[Color] = []
			for k in range(4):
				var sx := -1 if (k == 0 or k == 3) else 1
				var sz := -1 if (k == 0 or k == 1) else 1
				var col := Color(0.0, 0.0, 0.0, 0.0)
				var m := 0
				for dz in range(2):
					for dx in range(2):
						var jx := ix + (sx if dx == 1 else 0)
						var jz := iz + (sz if dz == 1 else 0)
						if jx < 0 or jx >= CELLS_X or jz < 0 or jz >= CELLS_Z:
							continue
						col += _pack_col(_packed[jz * CELLS_X + jx])
						m += 1
				corners.append(Vector3(centre.x + sx * cw * 0.5, y, centre.z + sz * cl * 0.5))
				cols.append(col / float(maxi(m, 1)))
			# Corners 0 (-x,-z), 1 (+x,-z), 2 (+x,+z), 3 (-x,+z): clockwise from
			# above, and Godot's front face is clockwise - centre, a, b.
			for k in range(4):
				st.set_color(ccol)
				st.add_vertex(centre)
				st.set_color(cols[k])
				st.add_vertex(corners[k])
				st.set_color(cols[(k + 1) % 4])
				st.add_vertex(corners[(k + 1) % 4])
	st.commit(mesh)
	_bed.visible = _gravel_k >= 0.999


## What a machine standing at `at` really stands ON, in world y.
##
## The pad spends most of the job BELOW grade - 0.20 m of hole, then the base
## filling it back up - and a machine parked at y 0 over an excavation floats
## over its own work with daylight under its wheels (which is exactly what the
## dump truck did in the first render of the base). Off the pad it is the lawn,
## on the pad it is whatever the job has put there so far.
func stand_y(at: Vector3) -> float:
	var ramp := 0.6
	var out_x := absf(at.x - CENTRE_X) - (WIDTH * 0.5 + ramp)
	if out_x > 0.0 or at.z < Z_APRON - ramp or at.z > Z_KERB + ramp:
		return 0.0
	var floor_y := GRADE
	if panels_broken() >= panel_count():
		# Only as far down the drive as the base has been laid: the tipper pulls
		# forward over bare dirt while it lays stone behind itself.
		floor_y = BASE_TOP if (_gravel_k > 0.001 and at.z <= gravel_front_z() + 0.2) else -DIG
		# ...and once there is CONCRETE here, the slab's own top is what anything
		# standing on it stands on. This branch was written for the tipper
		# crossing its own windrow and never heard of the pour, so from the tip
		# onward it answered BASE_TOP for the rest of the job and the payoff car
		# sank the slab's whole 100 mm ("tires clipping into driveway at the
		# end", the playtest of 2026-09-16). `-INF` where there is no slab, so
		# the tipper still crawls on the base ahead of its own stone.
		floor_y = maxf(floor_y, concrete_top(at))
	# The edge of the pad is a RAMP, not a cliff: a machine half on it is half way
	# down into it. Without this a seven-metre truck pops 20 cm on the frame its
	# nose crosses the line, which is the one thing that says "this is boxes".
	var edge := minf(minf(at.z - (Z_APRON - ramp), (Z_KERB + ramp) - at.z), -out_x)
	return lerpf(0.0, floor_y, clampf(edge / ramp, 0.0, 1.0))


## What a machine at `at` really rides on: the job's surface, plus whatever is
## lying loose on top of it.
##
## A skid steer crossing a slab it has just broken out climbs OVER the lumps -
## which is what "it looks like the skid steer goes through the rocks" was about.
## Asked at the machine's nose and its tail (`Machine._seat`), so the machine also
## TIPS as it climbs, which is most of what sells it.
func ride_y(at: Vector3, half: float = 0.95) -> float:
	var y := stand_y(at)
	for c in _chunks:
		if not is_instance_valid(c) or not c.visible:
			continue
		if absf(c.position.x - at.x) > half or absf(c.position.z - at.z) > half:
			continue
		y = maxf(y, c.position.y + SLAB_T * 0.55)
	return y


# --- Phase 6: the pour ------------------------------------------------------------------------

## Pours `amount` cubic-ish metres at a world point. The cell under the spout
## takes most of it and everything inside `pour_spread` takes the spill, so a
## swept chute lays a band instead of drilling a hole.
func pour_at(world: Vector3, amount: float, delta: float = 0.016) -> void:
	if amount <= 0.0:
		return
	var spread: float = config.pour_spread if config != null else 0.62
	var heap: float = config.pour_heap if config != null else 0.045
	var ceiling := (GRADE - BASE_TOP) + heap
	# WHOLE SQUARES, like the rake. The chute used to spread its load by weight
	# over the cells under the spout, which left a ring of part-filled ones round
	# every place it had poured - and a part-filled cell is a DEPTH, which is the
	# thing the playtest of 2026-09-16 took out of this phase. A cell the
	# concrete has reached is concrete.
	var full_p := (GRADE - BASE_TOP) + heap * 0.6
	var laid := 0
	for iz in range(CELLS_Z):
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			if _fill[i] >= full_p - 0.0001:
				continue
			if Vector2(_cell_x(ix) - world.x, _cell_z(iz) - world.z).length() > spread:
				continue
			_fill[i] = full_p
			laid += 1
	if laid > 0:
		_rebuild_slab()
	return


func _pour_at_unused(world: Vector3, amount: float, delta: float = 0.016) -> void:
	var spread: float = config.pour_spread if config != null else 0.62
	var heap: float = config.pour_heap if config != null else 0.045
	var ceiling := (GRADE - BASE_TOP) + heap
	var weights := PackedFloat32Array()
	var idx := PackedInt32Array()
	var total := 0.0
	for iz in range(CELLS_Z):
		for ix in range(CELLS_X):
			var d := Vector2(_cell_x(ix) - world.x, _cell_z(iz) - world.z).length()
			if d > spread:
				continue
			var w := 1.0 - d / spread
			w = w * w
			weights.append(w)
			idx.append(iz * CELLS_X + ix)
			total += w
	if total <= 0.0:
		# Aimed off the form altogether: the concrete is wasted on the dirt,
		# which is honest and costs the child nothing but time.
		return
	for n in range(idx.size()):
		var i := idx[n]
		_fill[i] = minf(_fill[i] + amount * weights[n] / total, ceiling)
	_settle(delta)
	_refresh_cells()
	if not _full_emitted and fill_fraction() >= 0.999:
		_full_emitted = true
		form_full.emit()


## How much higher one cell may stand than its neighbour before it slumps into
## it. Wet concrete is a thick liquid, not a powder: it will not stand in a pile,
## but it will hold a lumpy surface a centimetre or so out of level - which is
## exactly why the slab still needs screeding afterwards.
##
## It has to be read against the slab's DEPTH, which is 0.10. At 0.035 - a third
## of the slab - two neighbours were allowed to sit a third of the pour apart and
## call it level, so the outer columns the chute cannot quite reach never filled
## from their neighbours and the form could not be finished at all. The fill
## report showed it frozen solid: `0 26 61 86 52 17` all the way down the drive.
## At 0.012 the surface is still visibly lumpy (the screed has real work, and
## `is_flat()` wants 2 mm) but concrete always creeps into a hollow beside it.
## 0.022 and not 0.012. The user's note is that the pour "should be a mini game
## kind of like the water and broom lines where you have to fill in all the drive
## way" - and concrete that finds its own level across nine metres is not a game,
## it is a bath. At 0.022 (a fifth of the slab's depth) it still creeps into the
## hollow beside it, so no corner can be locked out and there is no way to fail,
## but the child has to take the chute to each part of the form.
const SLUMP := 0.022


## Concrete FLOWS, and it flows out of a cell that is merely FULL, not only out
## of one that is heaped above grade.
##
## That distinction is the whole of it. Shedding only the excess above grade
## meant a cell sitting at exactly grade had nothing to give, so the corners the
## chute's arc cannot quite reach stayed dry no matter how long the pour ran -
## the form stuck at 80% and the beat could never end. Levelling out to within
## `SLUMP` of its neighbours means concrete keeps creeping outward as long as any
## is arriving, so every corner fills eventually; and because it stops levelling
## at `SLUMP` rather than going glassy, the surface is still a few centimetres
## out of level when the pour ends and the screed has real work to do.
## How fast it slumps, per second. Paced by TIME and not by frames: a fixed
## fraction per frame levels the slab hundreds of times a second on a fast
## machine and reads as filling a bath rather than pouring concrete.
## And it creeps rather than runs: at 5.0 a second the form levelled itself
## faster than a child could sweep the chute across it.
const SLUMP_RATE := 1.8
## How much a raked-over cell keeps, as a fraction of a full one: the thin
## layer a come-along leaves behind it.
const RAKE_FLOOR := 0.35


func _settle(delta: float) -> void:
	var flow := clampf(delta * SLUMP_RATE, 0.0, 0.5)
	for _pass in range(2):
		for iz in range(CELLS_Z):
			for ix in range(CELLS_X):
				var i := iz * CELLS_X + ix
				if _fill[i] <= 0.001:
					continue
				for step: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var jx := ix + step.x
					var jz := iz + step.y
					if jx < 0 or jx >= CELLS_X or jz < 0 or jz >= CELLS_Z:
						continue
					var j := jz * CELLS_X + jx
					var diff := _fill[i] - _fill[j]
					if diff <= SLUMP:
						continue
					var give := (diff - SLUMP) * flow
					_fill[i] -= give
					_fill[j] += give


## How full the form is from `z_from` down to the kerb, 0 to 1 - the band the
## chute can reach with the mixer standing on the road (DESIGN 2a).
func band_fraction(z_from: float) -> float:
	var full := GRADE - BASE_TOP
	var sum := 0.0
	var n := 0
	for iz in range(CELLS_Z):
		if _cell_z(iz) < z_from:
			continue
		for ix in range(CELLS_X):
			sum += minf(_fill[iz * CELLS_X + ix] / full, 1.0)
			n += 1
	return sum / float(maxi(n, 1))


## The middle of the emptiest cell in that band, for the hint.
func emptiest_in_band(z_from: float) -> Vector3:
	var worst := -1
	var worst_fill := 9.0
	for iz in range(CELLS_Z):
		if _cell_z(iz) < z_from:
			continue
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			if _fill[i] < worst_fill:
				worst_fill = _fill[i]
				worst = i
	if worst < 0:
		return Vector3(CENTRE_X, GRADE, Z_KERB - 1.0)
	# Inset from the boards: an outer column's centre is 0.30 m from the form,
	# and a hint there drew its mark half on the lawn (round 3).
	var at := cell_world(worst % CELLS_X, worst / CELLS_X)
	at.x = clampf(at.x, CENTRE_X - WIDTH * 0.5 + 0.62, CENTRE_X + WIDTH * 0.5 - 0.62)
	return at


## The come-along (DESIGN 2a): PULLS concrete toward a world point from the
## kerb side of it. Everything inside `radius` of the point draws on the fuller
## cells up to `reach` cells toward the kerb - a rake's stroke is about a metre
## and a half - and never on anything further, so the child has to bring the
## concrete up the form a stroke at a time, from the heap the chute leaves at
## the kerb end. Returns how much moved, cubic-ish metres.
##
## What is pulled comes out of the donor a cell at a time, so the concrete
## visibly FLOWS toward the rake rather than appearing under it.
func rake_to(world: Vector3, radius: float, amount: float, reach: int = 2, band_z: float = -INF) -> float:
	if amount <= 0.0:
		return 0.0
	var full := GRADE - BASE_TOP
	var heap: float = config.pour_heap if config != null else 0.045
	var r := maxf(radius, 0.05)
	var moved := 0.0
	var targets: Array[Vector2i] = []
	for iz in range(CELLS_Z):
		for ix in range(CELLS_X):
			if Vector2(_cell_x(ix) - world.x, _cell_z(iz) - world.z).length() <= r:
				targets.append(Vector2i(ix, iz))
	if targets.is_empty():
		return 0.0
	var share := amount / float(targets.size())
	for t in targets:
		var i := t.y * CELLS_X + t.x
		var want := minf(share, full + heap * 0.4 - _fill[i])
		if want <= 0.0:
			continue
		for step in range(1, reach + 1):
			var jz := t.y + step
			if jz >= CELLS_Z:
				break
			# The same column first, then the two beside it: a stroke is a
			# rake's width, and a column whose kerb end the chute starved could
			# never be filled otherwise.
			for dx: int in [0, -1, 1]:
				var jx := t.x + dx
				if jx < 0 or jx >= CELLS_X:
					continue
				var j := jz * CELLS_X + jx
				# A rake SCOOPS: it takes a real amount off a donor down to a thin
				# raked-over layer, whatever the level difference. Taking only a
				# share of the difference turned the pull into diffusion, and the
				# relay from the kerb end to the apron never got there.
				#
				# But only from the chute's BAND (which the truck keeps refilling)
				# or from a cell's surplus above full: a cell already at grade is
				# never drained by a finger dragged over it (the user, 2026-09-14:
				# "once it's in place don't let me move any out").
				var floor_j := full * RAKE_FLOOR if _cell_z(jz) >= band_z else full
				var spare := _fill[j] - floor_j
				if spare <= 0.004:
					continue
				var give := minf(want, spare)
				_fill[j] -= give
				_fill[i] += give
				want -= give
				moved += give
				if want <= 0.0:
					break
			if want <= 0.0:
				break
	if moved > 0.0:
		_refresh_cells()
		if not _full_emitted and fill_fraction() >= 0.999:
			_full_emitted = true
			form_full.emit()
	return moved


## Where a pull does the MOST: the cell that wants concrete and has the most to
## draw on within a stroke's reach toward the kerb. Not the emptiest cell with
## anything at all behind it - a finger kept there starves, because the rake
## only reaches two or three cells and nothing relays the supply forward from
## the kerb end; the hint has to walk back to where the concrete is heaped and
## bring it on, the way a crew pulls in relays. (The smoke test follows this
## hint, and with the old one it stalled at 85% full.)
func rake_front_world(reach: int = 2, band_z: float = -INF) -> Vector3:
	var full := GRADE - BASE_TOP
	var best := -1
	var best_score := 0.0
	for iz in range(CELLS_Z):
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			var want := full - _fill[i]
			# 0.002, not 0.01: at a centimetre the hint skipped every cell within
			# a tenth of full, and a form of cells at 88-94% sat at 0.969 for ever
			# (smoke run 18).
			if want <= 0.002:
				continue
			var supply := 0.0
			for step in range(1, reach + 1):
				var jz := iz + step
				if jz >= CELLS_Z:
					break
				for dx: int in [0, -1, 1]:
					var jx := ix + dx
					if jx < 0 or jx >= CELLS_X:
						continue
					var floor_j := full * RAKE_FLOOR if _cell_z(jz) >= band_z else full
					supply += maxf(_fill[jz * CELLS_X + jx] - floor_j, 0.0)
			# Prefer the cell NEAREST THE CONCRETE'S FRONT: the child works at the
			# edge of what is there, and the come-along's camera stands behind that
			# edge - a hint at the far apron end was under the camera, outside
			# its own frame (smoke run 22).
			var front := pour_front_z()
			var score := minf(want, supply) / (1.0 + absf(_cell_z(iz) - front))
			if score > best_score:
				best_score = score
				best = i
	if best < 0:
		return emptiest_world()
	# Inset from the boards: the head is 0.56 m wide, and at an outer column's
	# centre it hung over the form and out of the frame (round 12).
	var at := cell_world(best % CELLS_X, best / CELLS_X)
	at.x = clampf(at.x, CENTRE_X - WIDTH * 0.5 + 0.62, CENTRE_X + WIDTH * 0.5 - 0.62)
	return at


## Where the work is: the KERB-MOST row that still has a cell under half -
## the edge of the unfilled part, measured from the heap the concrete comes
## from. (The apron-most row with a full cell was the old answer, and one
## cell raked at the apron pulled the "front" - and the camera behind it - to
## the apron, with the hint under the camera; smoke runs 22-23.)
func pour_front_z() -> float:
	var half := (GRADE - BASE_TOP) * 0.5
	for iz in range(CELLS_Z - 1, -1, -1):
		for ix in range(CELLS_X):
			if _fill[iz * CELLS_X + ix] < half:
				return _cell_z(iz)
	return Z_APRON


## How full the form is, 0 to 1, counting anything at or above grade as done.
## How full the cell under a world point is, 0..1.
func fill_frac_at(world: Vector3) -> float:
	var cw := WIDTH / float(CELLS_X)
	var cl := LENGTH / float(CELLS_Z)
	var ix := clampi(int(floor((world.x - (CENTRE_X - WIDTH * 0.5)) / cw)), 0, CELLS_X - 1)
	var iz := clampi(int(floor((world.z - Z_APRON) / cl)), 0, CELLS_Z - 1)
	return clampf(_fill[iz * CELLS_X + ix] / (GRADE - BASE_TOP), 0.0, 1.0)


## The concrete SETTLES: every cell still short of full comes up to it, `k`
## 0..1. The come-along's beat ends at 97.5% of the form and the last few per
## cent would otherwise sit as sandy patches under the hose.
func settle(k: float) -> void:
	var full := GRADE - BASE_TOP
	var kk := clampf(k, 0.0, 1.0)
	for i in range(_fill.size()):
		if _fill[i] < full - 0.0005:
			_fill[i] = lerpf(_fill[i], full, kk)
	_refresh_cells()


## Concrete wherever the rake's head goes: every cell whose middle is within
## `radius` of `world` goes straight to FULL. Returns how many were filled by
## this stroke, so the verb knows whether the tool did anything.
##
## This replaced a conservation model - `rake_to` moved concrete that already
## existed, only off a donor with surplus, and re-drained the cells under the
## chute to a floor every stroke. Three things came out of that and all three
## were the same complaint: dragging over slab already at grade did nothing at
## all (a dead tool under a moving finger), the part nearest the truck kept
## going BACK to dark mud while the child worked, and what was left to do was a
## DEPTH - a centimetre of missing fill under six centimetres of deliberate
## surface noise, which no eye can read. "Needs less physics.. when you drag
## over a sqare it puts the concreate there" (the playtest of 2026-09-16).
func rake_fill(world: Vector3, radius: float) -> int:
	var full := GRADE - BASE_TOP
	var did := 0
	var r2 := radius * radius
	for iz in range(CELLS_Z):
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			if _fill[i] >= full - 0.0001:
				continue
			var c := cell_world(ix, iz)
			if Vector2(c.x - world.x, c.z - world.z).length_squared() > r2:
				continue
			_fill[i] = full
			did += 1
	if did > 0:
		_rebuild_slab()
	return did


## How many cells have concrete in them at all.
func covered_cells() -> int:
	var full := GRADE - BASE_TOP
	var n := 0
	for i in range(_fill.size()):
		if _fill[i] >= full - 0.0001:
			n += 1
	return n


## 0..1 of the form that has concrete in it. THE rule the spread beat ends on -
## a COUNT of squares, not a mean depth, so what is left to do is a colour on
## the slab and never a thickness.
func covered_fraction() -> float:
	return float(covered_cells()) / float(maxi(_fill.size(), 1))


func fill_fraction() -> float:
	var full := GRADE - BASE_TOP
	var sum := 0.0
	for i in range(_fill.size()):
		sum += minf(_fill[i] / full, 1.0)
	return sum / float(maxi(_fill.size(), 1))


## The middle of the emptiest part of the form, for the hint arrow: the lowest
## cell, in world space, at grade.
func emptiest_world() -> Vector3:
	var worst := -1
	var worst_fill := 9.0
	for i in range(_fill.size()):
		if _fill[i] < worst_fill:
			worst_fill = _fill[i]
			worst = i
	if worst < 0:
		return Vector3(CENTRE_X, GRADE, _mid_z())
	return cell_world(worst % CELLS_X, worst / CELLS_X)


func cell_world(ix: int, iz: int) -> Vector3:
	return Vector3(_cell_x(ix), GRADE, _cell_z(iz))


## The fill grid as text, 0 to 99 per cell, kerb end at the bottom. For a test
## that has to say WHICH cells did not fill rather than only that the form did
## not - the difference between a finding and a shrug.
func fill_report() -> String:
	var full := GRADE - BASE_TOP
	var out := ""
	for iz in range(CELLS_Z):
		var row := ""
		for ix in range(CELLS_X):
			row += "%4d" % int(round(minf(_fill[iz * CELLS_X + ix] / full, 1.0) * 99.0))
		out += row + "\n"
	return out


func cell_fill(ix: int, iz: int) -> float:
	var i := iz * CELLS_X + ix
	if i < 0 or i >= _fill.size():
		return 0.0
	return _fill[i]


## How wet the WHOLE surface looks, 0 dry to 1 glistening, with no patchwork at
## all: the pour is damp everywhere, and the cure dries everything together.
##
## It resets both painting targets to the same number, so a slab set to one
## wetness really is that wetness everywhere - otherwise the cure could not dry a
## slab the broom had already said was 0.25.
func set_wet(w: float) -> void:
	_wet = clampf(w, 0.0, 1.0)
	_wet_target = _wet
	_dry_target = _wet
	_base_col = DRY_CONCRETE.lerp(WET_CONCRETE, _wet) * _cure_tint
	for i in range(_cell_col.size()):
		_paint_cell(i)
	_refresh_joint_lips()


## The cure's tint on the slab: what the evening light adds, taken back.
func set_cure_tint(t: Color) -> void:
	_cure_tint = t
	set_wet(_wet)


## How wet one cell looks: the slab's own wetness, carried toward soaked by the
## hose it has had, then carried toward dry by the brushing it has had.
func _cell_wet(i: int) -> float:
	var w := lerpf(_wet, _wet_target, clampf(_watered[i], 0.0, 1.0))
	return lerpf(w, _dry_target, clampf(_brushed[i], 0.0, 1.0))


## Writes one cell's look, and the look of any brush marks lying on it.
func _paint_cell(i: int) -> void:
	if i < 0 or i >= _cell_col.size():
		return
	var w := _cell_wet(i)
	_cell_col[i] = DRY_CONCRETE.lerp(WET_CONCRETE, w) * _cure_tint
	# A wet EDGE: where the water's coverage is part way - the rim of the
	# wetted patch, where the sheen ends - the cell is darker still, so the
	# patch has an outline the way a real wetted slab does, not just a tone
	# (round 13: the only beat still carried by tint alone).
	var cov := clampf(_watered[i], 0.0, 1.0)
	var edge := 1.0 - absf(2.0 * cov - 1.0)
	if _brushed[i] < 0.5 and edge > 0.0:
		_cell_col[i] = _cell_col[i].darkened(0.20 * edge)
	_update_puddle(i)
	_slab_dirty = true


## A cell's puddle shows while the cell is wetted through, unstruck and
## unbrushed - and only on the cells that have a low spot (three in five).
func _update_puddle(i: int) -> void:
	if i >= _puddles.size() or _puddles[i] == null:
		return
	var puddle := _puddles[i]
	var has_low := sin(float(i) * 3.3 + 0.9) > -0.2
	var wet_through := has_low and clampf(_watered[i], 0.0, 1.0) >= 0.85 and _struck[i] == 0 		and _brushed[i] < 0.3 and _fill[i] > MIN_DRAW
	puddle.visible = wet_through
	if wet_through:
		puddle.position.y = surface_y(puddle.position) + 0.004
		(puddle.mesh.surface_get_material(0) as StandardMaterial3D).albedo_color = PUDDLE * _cure_tint
	# The brush marks are a shade of whatever the slab is RIGHT NOW. Painted once
	# in the dry colour, they began 37% LIGHTER than the wet concrete under them,
	# matched it exactly on the last frame of the stroke and only went dark during
	# the cure - so a child watched their own broom finish appear inverted and then
	# vanish at the moment they finished it.
	# Feathered: a half-brushed cell has half-strength lines, so the brushed
	# area is a stroke and not a tile (round 6).
	var ink := _cell_col[i].darkened(0.085 * clampf(_brushed[i], 0.0, 1.0))
	for line: Node3D in _cell_lines[i]:
		if line == null or not is_instance_valid(line):
			continue
		var lm := (line as MeshInstance3D).get_active_material(0)
		if lm is StandardMaterial3D:
			(lm as StandardMaterial3D).albedo_color = ink


## A shade darker than the slab as it stands. Ten per cent of the LIVE colour,
## not of the dry one.
func _broom_ink() -> Color:
	return _base_col.darkened(0.085)


func wet() -> float:
	return _wet


# --- Working the surface by hand --------------------------------------------------------------
#
# The water and the broom are not a button any more. "Player should have to move
# water around and get it all wet them selves not just a basic click. Same for
# brushing" - so both of them are a finger DRAGGED over the slab, and what they
# leave behind is per-cell coverage. The beat ends when the child has been
# everywhere, and until then the part they have missed is plainly a different
# colour from the part they have done.

## Wets everything inside `radius` of a world point, `rate` of the way there.
## `to` is what soaked looks like.
func paint_water(world: Vector3, radius: float, rate: float, to: float) -> void:
	_wet_target = clampf(to, 0.0, 1.0)
	_paint(_watered, world, radius, rate)


## Brushes everything inside `radius`, and lays that cell's brush marks the first
## time it is touched. `to` is what a finished, dried cell looks like. `dir` is
## the STROKE on the ground - the way the handle runs, square to the head -
## and the marks run along it.
func paint_broom(world: Vector3, radius: float, rate: float, to: float,
		dir: Vector3 = Vector3.RIGHT, z_lo: float = -INF, z_hi: float = INF) -> void:
	_dry_target = clampf(to, 0.0, 1.0)
	var touched := _paint(_brushed, world, radius, rate, z_lo, z_hi)
	for i in touched:
		# Lines wait for a STROKE direction (ZERO until the finger has moved).
		if (_cell_lines[i] as Array).is_empty() and _brushed[i] > 0.05 and dir.length_squared() > 1e-6:
			_brush_lines(i, dir)


## The whole of bay `b` brushed, with no child involved: a posed picture of
## the bays already done.
func broom_bay(b: int) -> void:
	var band := bay_range(b)
	for iz in range(CELLS_Z):
		var z := _cell_z(iz)
		if z < band.x or z > band.y:
			continue
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			_brushed[i] = 1.0
			if (_cell_lines[i] as Array).is_empty():
				_brush_lines(i)
			_paint_cell(i)


## How much of the slab the screed has struck off, 0..1 (tests).
func struck_fraction() -> float:
	if _struck.is_empty():
		return 0.0
	var n := 0
	for s in _struck:
		if s != 0:
			n += 1
	return float(n) / float(_struck.size())


## How much of the band z_lo..z_hi has had the broom.
func broom_coverage_in(z_lo: float, z_hi: float) -> float:
	var sum := 0.0
	var n := 0
	for iz in range(CELLS_Z):
		var z := _cell_z(iz)
		if z < z_lo or z > z_hi:
			continue
		for ix in range(CELLS_X):
			sum += _brushed[iz * CELLS_X + ix]
			n += 1
	return sum / float(n) if n > 0 else 1.0


## The least-brushed cell inside the band.
func roughest_world_in(z_lo: float, z_hi: float) -> Vector3:
	var worst := -1
	var low := 9.0
	for iz in range(CELLS_Z):
		var z := _cell_z(iz)
		if z < z_lo or z > z_hi:
			continue
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			if _brushed[i] < low:
				low = _brushed[i]
				worst = i
	if worst < 0:
		return Vector3(CENTRE_X, GRADE, (z_lo + z_hi) * 0.5)
	return cell_world(worst % CELLS_X, worst / CELLS_X)


## Raises a coverage grid round a point and repaints what it touched. Returns the
## cells it reached, so a caller can do more to exactly those.
func _paint(grid: PackedFloat32Array, world: Vector3, radius: float,
		rate: float, z_lo: float = -INF, z_hi: float = INF) -> PackedInt32Array:
	var hit := PackedInt32Array()
	var r := maxf(radius, 0.05)
	for iz in range(CELLS_Z):
		# Only inside the band: the broom works one bay at a time and lifts
		# over the joint (fourth playtest).
		if _cell_z(iz) < z_lo or _cell_z(iz) > z_hi:
			continue
		for ix in range(CELLS_X):
			var d := Vector2(_cell_x(ix) - world.x, _cell_z(iz) - world.z).length()
			if d > r:
				continue
			var i := iz * CELLS_X + ix
			if grid[i] >= 1.0:
				continue
			# Hardest right under the finger, tailing off to the edge of it.
			grid[i] = minf(grid[i] + rate * (1.0 - 0.6 * d / r), 1.0)
			_paint_cell(i)
			hit.append(i)
	return hit


## How much of the slab has had the hose, and how much has had the broom.
func water_coverage() -> float:
	return _mean(_watered)


func broom_coverage() -> float:
	return _mean(_brushed)


func _mean(grid: PackedFloat32Array) -> float:
	if grid.is_empty():
		return 0.0
	var sum := 0.0
	for i in range(grid.size()):
		sum += minf(grid[i], 1.0)
	return sum / float(grid.size())


## The middle of the driest cell, and of the least brushed one: where the arrow
## goes when a child has gone still and does not know where to look.
func driest_world() -> Vector3:
	return _lowest_world(_watered)


func roughest_world() -> Vector3:
	return _lowest_world(_brushed)


func _lowest_world(grid: PackedFloat32Array) -> Vector3:
	var worst := -1
	var low := 9.0
	for i in range(grid.size()):
		if grid[i] < low:
			low = grid[i]
			worst = i
	if worst < 0:
		return Vector3(CENTRE_X, GRADE, _mid_z())
	return cell_world(worst % CELLS_X, worst / CELLS_X)


# --- Phases 8 to 10: screed, joints, broom ----------------------------------------------------

## Pulls the screed board up the drive: `k` 0 at the kerb end, 1 at the apron.
## Every cell the board has passed is cut back to exactly grade, so the slab
## goes flat BEHIND the board and is still lumpy in front of it.
func screed(k: float) -> void:
	var kk := clampf(k, 0.0, 1.0)
	var line := screed_line_z(kk)
	_wave_z = line if kk < 0.999 else -INF
	if _wave_mesh == null:
		# Tall enough to have a silhouette from a low eye: a roll of surplus
		# a hand high, leaning back against the board.
		# A capsule lying across the drive: a roll of surplus with ROUNDED ends,
		# which a box ended in a vertical cut face standing in the slab (round 9).
		# Built OUT OF THE SURFACE (round 10: a capsule in its own material was
		# a chrome pipe): a ridge in the slab's own material, its vertex colours
		# the unstruck mottle, its crest lumpy at the cell pitch so no highlight
		# can run the length of it.
		_wave_mesh = MeshInstance3D.new()
		_wave_mesh.name = "BowWave"
		_wave_mesh.mesh = _build_wave_mesh()
		# The slab's material, but it does not RECEIVE the board's shadow: the
		# ridge lies exactly where that shadow falls, and rendered 0.37 grey on
		# a 0.55 slab - a black slot, not a roll of mud (round 11).
		var wave_mat := _slab_mat.duplicate() as StandardMaterial3D
		wave_mat.disable_receive_shadows = true
		_wave_mesh.material_override = wave_mat
		_wave_mesh.position = Vector3(CENTRE_X, GRADE - 0.012, line + 0.22)
		add_child(_wave_mesh)
	_wave_mesh.visible = kk < 0.985
	_wave_mesh.position = Vector3(CENTRE_X, GRADE + 0.045, line + 0.22)
	var full := GRADE - BASE_TOP
	for iz in range(CELLS_Z):
		if _cell_z(iz) > line + 0.01:
			continue
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			# A screed fills a hollow from the concrete it is dragging as well
			# as cutting the high spots off - it is struck off LEVEL.
			_fill[i] = full
			_struck[i] = 1
	_refresh_cells()


## Where the board is now. It follows the POUR - which starts at the garage end
## and works out to the street - so the board is always on concrete that has just
## gone in, and the crew finishes at the kerb rather than shut in at the garage
## with the whole wet slab between them and the road.
func screed_line_z(k: float) -> float:
	return lerpf(Z_APRON, Z_KERB, clampf(k, 0.0, 1.0))


## Is every cell struck off level?
func is_flat() -> bool:
	var full := GRADE - BASE_TOP
	for i in range(_fill.size()):
		if absf(_fill[i] - full) > 0.002 or _struck[i] == 0:
			return false
	return true


## How many cells the board has been over.
func struck_count() -> int:
	var n := 0
	for i in range(_struck.size()):
		if _struck[i] != 0:
			n += 1
	return n


## Two control joints across the drive, at a third and two thirds of its length:
## a slab this long needs them or it cracks where it likes instead of where the
## joint is. That IS the lesson of the phase.
func joint_count() -> int:
	return JOINTS


## How far joint `i` has been cut, 0..1.
func joint_k(i: int) -> float:
	return float(_joint_done.get(i, 0.0))


## The concrete SQUARES between the control joints: one more than the joints.
## The broom is worked one bay at a time (fourth playtest).
func bay_count() -> int:
	return joint_count() + 1


## Bay `b` (1..bay_count) as (z_lo, z_hi).
func bay_range(b: int) -> Vector2:
	var bb := clampi(b, 1, bay_count())
	var lo := Z_APRON if bb == 1 else joint_z(bb - 1)
	var hi := Z_KERB if bb == bay_count() else joint_z(bb)
	return Vector2(lo, hi)


## A marker in the middle of bay `b`, for the camera to stand beside.
func bay_marker(b: int) -> Node3D:
	var bb := clampi(b, 1, bay_count())
	var key := "Bay_%d" % bb
	if _markers.has(key):
		return _markers[key]
	var r := bay_range(bb)
	var m := Marker3D.new()
	m.name = key
	m.position = Vector3(CENTRE_X, GRADE, (r.x + r.y) * 0.5)
	add_child(m)
	_markers[key] = m
	return m


func joint_z(i: int) -> float:
	return Z_APRON + LENGTH * (float(i) / float(joint_count() + 1))


func joint_marker(i: int) -> Node3D:
	var key := "Joint_%d" % i
	if _markers.has(key):
		return _markers[key]
	var m := Marker3D.new()
	m.name = key
	m.position = Vector3(CENTRE_X, GRADE, joint_z(i))
	add_child(m)
	_markers[key] = m
	return m


## Cuts joint `i` across the slab: `k` 0 to 1 from one side to the other.
func cut_joint(i: int, k: float) -> void:
	var kk := clampf(k, 0.0, 1.0)
	var depth: float = config.joint_depth if config != null else 0.022
	var width: float = config.joint_width if config != null else 0.035
	var node := _joint_node(i, depth, width)
	_joint_done[i] = kk
	var bm := node.mesh as BoxMesh
	bm.size = Vector3(maxf(WIDTH * kk, 0.001), depth, width)
	var lip := node.get_node_or_null("Lip") as MeshInstance3D
	if lip != null:
		(lip.mesh as BoxMesh).size.x = maxf(WIDTH * kk, 0.001)
	# Grows from the near side across, so the groove follows the tool.
	node.position.x = CENTRE_X - WIDTH * 0.5 + WIDTH * kk * 0.5
	node.visible = kk > 0.001


func _joint_node(i: int, depth: float, width: float) -> MeshInstance3D:
	while _joints.size() <= i:
		_joints.append(null)
	if _joints[i] != null and is_instance_valid(_joints[i]):
		return _joints[i] as MeshInstance3D
	# Its top a hair INTO the surface - the same trick the broom lines use. Proud
	# of the slab it was a raised strip, which is the opposite of a tooled joint;
	# sunk fully beneath it, it was hidden by the very slab it is cut into.
	# A groove is in its own shadow: dark, not the old slab's grey, which against
	# the mid-grey pour read as a tan stripe (round 4 frame 13).
	var mi := _box("Joint_%d" % i, Vector3(0.001, depth, width),
		Vector3(CENTRE_X, GRADE + 0.0008 - depth * 0.5, joint_z(i)), Color(0.22, 0.22, 0.24))
	mi.visible = false
	add_child(mi)
	# A groove, not a slot: a lighter lip along its near edge, where the tool
	# rounded the concrete over (round 5) - a tenth above the slab's LIVE
	# colour, refreshed with it, not a fixed near-white (round 6: it was the
	# brightest object in the world).
	# Kept as a node for the cut's length, but NOT DRAWN since round 14: a
	# lit flat face can never be signed off by its albedo - at +0.03 it
	# rendered 27% over the slab and read as tape. The groove's own dark is
	# the cut.
	var lip := _box("Lip", Vector3(1.0, 0.0014, width * 0.55),
		Vector3(0.0, depth * 0.5 + 0.0004, width * 0.75), _base_col.lightened(0.10))
	lip.visible = false
	mi.add_child(lip)
	_joints[i] = mi
	return mi


func _refresh_joint_lips() -> void:
	for j in _joints:
		if j == null or not is_instance_valid(j):
			continue
		var lip := j.get_node_or_null("Lip") as MeshInstance3D
		if lip == null:
			continue
		var lm := lip.get_active_material(0)
		if lm is StandardMaterial3D:
			# A hair above the live colour: at +0.10 the lit lip rendered 27%
			# over the slab and read as tape (round 13).
			(lm as StandardMaterial3D).albedo_color = _base_col.lightened(0.03)


func joints_cut() -> int:
	var n := 0
	for j in _joints:
		if j != null and is_instance_valid(j) and j.visible:
			n += 1
	return n


## The brush marks for one cell: a few long thin streaks ALONG the stroke
## (`dir`, on the ground), each longer than the cell and set off along its
## length at random, so the marks of neighbouring cells interleave and no end
## lands on a cell boundary. One wide band per cell, staggered row to row,
## tiled into running bond and the finished drive read as block paving
## (round 11). Clipped to the panel the cell is in: the broom lifts over a
## joint and stops at the boards. The band sits a hair above the surface so
## it never z-fights with the cell underneath.
func _brush_lines(i: int, dir: Vector3 = Vector3.RIGHT) -> void:
	var ix := i % CELLS_X
	var iz := i / CELLS_X
	var cw := WIDTH / float(CELLS_X)
	var cl := LENGTH / float(CELLS_Z)
	var d := Vector3(dir.x, 0.0, dir.z)
	if d.length_squared() < 0.0001:
		d = Vector3.RIGHT
	d = d.normalized()
	var side := Vector3(-d.z, 0.0, d.x)
	var per := _broom_per_cell() + 1
	var centre := Vector3(_cell_x(ix), GRADE + 0.0009, _cell_z(iz))
	# The panel this cell is in: between the boards, and between the joints
	# either side of it.
	var z_lo := Z_APRON + 0.03
	var z_hi := Z_KERB - 0.03
	for jn in range(1, joint_count() + 1):
		var jz := joint_z(jn)
		if jz <= centre.z and jz + 0.04 > z_lo:
			z_lo = jz + 0.04
		if jz > centre.z and jz - 0.04 < z_hi:
			z_hi = jz - 0.04
	var x_lo := CENTRE_X - WIDTH * 0.5 + 0.03
	var x_hi := CENTRE_X + WIDTH * 0.5 - 0.03
	var across := absf(side.x) * cw + absf(side.z) * cl
	var along := absf(d.x) * cw + absf(d.z) * cl
	var pitch := across / float(per)
	var lines: Array[Node3D] = []
	for j in range(per):
		var jit := sin(float(i) * 3.7 + float(j) * 2.9)
		var jit2 := cos(float(i) * 1.9 + float(j) * 4.1)
		var off_side := -across * 0.5 + pitch * (float(j) + 0.5 + 0.22 * jit)
		var off_along := along * 0.5 * jit2
		var half_len := along * (0.7 + 0.5 * absf(sin(float(i) * 2.3 + float(j) * 1.7)))
		var mid := centre + side * off_side + d * off_along
		var span := _clip_span(mid, d, -half_len, half_len, x_lo, x_hi, z_lo, z_hi)
		if span.y - span.x < 0.08:
			continue
		var c := mid + d * ((span.x + span.y) * 0.5)
		var line := _box("Broom_%d_%d" % [i, j + 1],
			Vector3(span.y - span.x, 0.0016, 0.028), c, _broom_ink())
		line.rotation.y = atan2(-d.z, d.x)
		add_child(line)
		lines.append(line)
		_broom_lines.append(line)
	_cell_lines[i] = lines
	_paint_cell(i)


## The part of the segment `mid + d * t`, t in [t0, t1], that lies inside the
## rectangle, as (t_lo, t_hi); (0, 0) when none of it does.
func _clip_span(mid: Vector3, d: Vector3, t0: float, t1: float,
		x_lo: float, x_hi: float, z_lo: float, z_hi: float) -> Vector2:
	var lo := t0
	var hi := t1
	for axis in range(2):
		var p := mid.x if axis == 0 else mid.z
		var v := d.x if axis == 0 else d.z
		var a_lo := x_lo if axis == 0 else z_lo
		var a_hi := x_hi if axis == 0 else z_hi
		if absf(v) < 0.0001:
			if p < a_lo or p > a_hi:
				return Vector2.ZERO
			continue
		var ta := (a_lo - p) / v
		var tb := (a_hi - p) / v
		lo = maxf(lo, minf(ta, tb))
		hi = minf(hi, maxf(ta, tb))
	if hi < lo:
		return Vector2.ZERO
	return Vector2(lo, hi)


func _broom_per_cell() -> int:
	return maxi(1, int(round(float(_broom_count()) / float(CELLS_Z))))


func _broom_duty() -> float:
	return config.broom_duty if config != null else 0.22


## The whole slab brushed up to `k` of its length, with no child involved: what a
## posed screenshot and the payoff want. The child's own broom goes through
## `paint_broom`, a patch at a time.
func broom(k: float) -> void:
	var kk := clampf(k, 0.0, 1.0)
	for iz in range(CELLS_Z):
		if (float(iz) + 0.5) / float(CELLS_Z) > kk:
			continue
		for ix in range(CELLS_X):
			var i := iz * CELLS_X + ix
			_brushed[i] = 1.0
			if (_cell_lines[i] as Array).is_empty():
				_brush_lines(i)
			_paint_cell(i)


func _broom_count() -> int:
	return config.broom_lines if config != null else 26


func broom_lines() -> int:
	return _broom_lines.size()


## Is the broom finish on? Measured against the SAME number the beat ends on, so
## the job cannot finish a phase the driveway then says is unfinished.
func broomed() -> bool:
	var want: float = config.scrub_done if config != null else 0.94
	return broom_coverage() >= want - 0.01


# --- The payoff -------------------------------------------------------------------------------

## Every board the child strips, at once: `k` 0 still standing, 1 laid on the
## grass. What a posed picture past the strip uses; play strips one board a
## tap (`strip_form`, the improvement plan's 5.3).
func strip_forms(k: float) -> void:
	for i in strip_boards():
		strip_form(i, k)


## The boards that come off: the two long ones and the kerb board. The
## expansion strip is part of the slab and stays.
func strip_boards() -> PackedInt32Array:
	return PackedInt32Array([1, 2, KERB_BOARD])


func form_strips(i: int) -> bool:
	return strip_boards().has(i)


func form_is_stripped(i: int) -> bool:
	var f := _at(_forms, i)
	return not f.is_empty() and float(f.get("strip", 0.0)) >= 0.999


## The boards still to strip, in the order the rings are lit.
func open_strip_forms() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in strip_boards():
		if not form_is_stripped(i):
			out.append(i)
	return out


## Which way board `i` comes away from the slab, in world space: outward.
func form_out(i: int) -> Vector3:
	match i:
		1:
			return Vector3.LEFT
		2:
			return Vector3.RIGHT
		KERB_BOARD:
			return Vector3.BACK
	return Vector3.FORWARD


## Which bank lies outside board `i` (the banks are apron, kerb, left, right).
func bank_of_form(i: int) -> int:
	match i:
		1:
			return 2
		2:
			return 3
		KERB_BOARD:
			return 1
	return 0


## Where the ring for stripping board `i` stands: on the board's top, near the
## kerb end for a long board (in every strip picture), in the middle of the kerb
## board.
func strip_ring_point(i: int) -> Vector3:
	var h := form_home(i)
	if i == KERB_BOARD:
		return Vector3(h.x, GRADE + 0.02, h.z)
	return Vector3(h.x, GRADE + 0.02, Z_KERB - 2.2)


## The two ends of board `i`'s top edge where it stands now, for a tap to be
## measured against the whole 9 m board and not only its ring.
func form_line_world(i: int) -> PackedVector3Array:
	var f := _at(_forms, i)
	if f.is_empty():
		return PackedVector3Array()
	var mi := f["node"] as MeshInstance3D
	var size: Vector3 = mi.mesh.get_aabb().size
	var along := Vector3(size.x * 0.5, size.y * 0.5, 0.0) if size.x > size.z else Vector3(0.0, size.y * 0.5, size.z * 0.5)
	var xf := mi.global_transform
	var top_a := Vector3(-along.x, along.y, -along.z)
	return PackedVector3Array([xf * top_a, xf * along])


## Board `i` coming off, as a PURE function of `k` from where it stood (so a
## posed picture and the tap agree):
##   0.00-0.25  its pegs are drawn up out of the ground, one after another
##   0.25-0.40  the board is prised OUT about its bottom outside edge, a few
##              degrees - the clean face of the new slab shows behind it
##   0.40-0.70  it lifts straight up, still tipped
##   0.70-1.00  it is swung down flat onto the grass beside its edge (the kerb
##              board over the cones to the left lawn), its pegs laid on it;
##              the trench outside it is backfilled as it goes
## Nothing fades: on a site things are carried, and they go at the cut.
func strip_form(i: int, k: float) -> void:
	var f := _at(_forms, i)
	if f.is_empty() or not form_strips(i):
		return
	var kk := clampf(k, 0.0, 1.0)
	f["strip"] = kk
	var mi := f["node"] as MeshInstance3D
	mi.visible = true
	var size: Vector3 = mi.mesh.get_aabb().size
	var home: Vector3 = f["home"]
	var out := form_out(i)
	var t := size.x if i != KERB_BOARD else size.z
	var h := size.y
	var pry_deg: float = config.strip_pry_deg if config != null else 6.0
	if i == KERB_BOARD:
		pry_deg *= 0.5
	var lift: float = config.strip_lift if config != null else 0.30
	var axis := Vector3.UP.cross(out).normalized()
	var pivot := home + out * (t * 0.5) + Vector3.DOWN * (h * 0.5)
	# Pry, then lift.
	var pry := _smooth01((kk - STRIP_PULL_END) / (STRIP_PRY_END - STRIP_PULL_END))
	var up := _smooth01((kk - STRIP_PRY_END) / (STRIP_LIFT_END - STRIP_PRY_END)) * lift
	var pr := Basis(axis, deg_to_rad(pry_deg) * pry)
	var raised := Transform3D(pr, pivot + pr * (home - pivot) + Vector3.UP * up)
	var lay := _strip_lay(i, size)
	var swing := _smooth01((kk - STRIP_LIFT_END) / (1.0 - STRIP_LIFT_END))
	var xf := raised
	if swing > 0.0:
		var q := raised.basis.get_rotation_quaternion().slerp(lay.basis.get_rotation_quaternion(), swing)
		var arc := (0.9 if i == KERB_BOARD else STRIP_ARC) * sin(PI * swing)
		# Across first, then down: the sideways travel is done by 80% of the
		# swing and the height follows the whole of it, so a board carried to the
		# pile never skims through the boards already lying there (the
		# verification pass: the kerb board swung through the laid left board).
		var hs := _smooth01(swing / 0.8)
		var at := raised.origin.lerp(lay.origin, hs)
		at.y = lerpf(raised.origin.y, lay.origin.y, swing) + arc
		xf = Transform3D(Basis(q), at)
	mi.transform = xf
	var mark := f.get("mark") as Node3D
	if mark != null:
		mark.visible = false
	# The pegs: drawn up first (staggered along the board), then carried onto it.
	var pegs := stakes_of_form(i)
	for p in range(pegs.size()):
		var s := _at(_stakes, pegs[p])
		var sn := s["node"] as Node3D
		if not sn.visible and float(s["k"]) < 0.999:
			continue
		sn.visible = true
		var delay := 0.04 * float(p)
		var pull := _smooth01((kk - delay) / maxf(STRIP_PULL_END - delay, 0.05))
		var standing := Vector3(s["home"]) + Vector3(0.0, STAKE_STUB + STAKE_PULL * pull, 0.0)
		var sxf := Transform3D(Basis.IDENTITY, standing)
		if swing > 0.0:
			var on_board := _peg_on_laid(i, pegs[p], lay, size)
			var sq := Quaternion.IDENTITY.slerp(on_board.basis.get_rotation_quaternion(), swing)
			sxf = Transform3D(Basis(sq), standing.lerp(on_board.origin, swing) + Vector3.UP * (0.25 * sin(PI * swing)))
		sn.transform = sxf
	# The slab's edge on this side is open to the eye from the moment the board
	# leaves it, so it gets its face (`_rebuild_slab`).
	var open := kk >= STRIP_PULL_END
	if bool(f.get("edge_open", false)) != open:
		f["edge_open"] = open
		_slab_dirty = true
	# The trench outside it goes back to turf once the board's bottom is out of it.
	set_bank(bank_of_form(i), 1.0 - _smooth01((kk - 0.55) / 0.35))
	# The apron's bank is never seen; it goes back with the last board, so the
	# finished lot is the one the payoff was always posed with.
	if open_strip_forms().is_empty():
		set_bank(0, 0.0)


## Where board `i` ends up: laid flat on the crew's PILE on the right lawn,
## side by side along the drive, old outer face down. A 9.16 m board has nowhere
## else to lie on this lot: between the garage's front and the footway there are
## 7.9 m, so "beside its own edge" put a metre of every long board inside the
## footway and the kerb board with it (the verification pass). Right of the
## garage, clear of the site fence, the tools' rest and the footway.
func _strip_lay(i: int, size: Vector3) -> Transform3D:
	var out := form_out(i)
	var axis := Vector3.UP.cross(out).normalized()
	var slot := {1: 0, 2: 1, KERB_BOARD: 2}.get(i, 0) as int
	var x := STRIP_PILE_X + STRIP_PILE_GAP * float(slot)
	if i == KERB_BOARD:
		var b := Basis(Vector3.UP, deg_to_rad(90.0)) * Basis(Vector3.RIGHT, deg_to_rad(90.0))
		return Transform3D(b, Vector3(x, size.z * 0.5 + 0.003, STRIP_PILE_Z + 1.1))
	return Transform3D(Basis(axis, deg_to_rad(90.0)), Vector3(x, size.x * 0.5 + 0.003, STRIP_PILE_Z))


## A pulled peg lying across its laid board, at its own place along it.
func _peg_on_laid(i: int, peg: int, lay: Transform3D, size: Vector3) -> Transform3D:
	var s := _at(_stakes, peg)
	var home: Vector3 = s["home"]
	var fh := form_home(i)
	var top := size.x * 0.5 if i != KERB_BOARD else size.z * 0.5
	if i == KERB_BOARD:
		# The kerb board lies along +Z on the left lawn: its pegs across it.
		var along_k := home.x - fh.x
		return Transform3D(Basis(Vector3.BACK, deg_to_rad(90.0)),
			Vector3(lay.origin.x, lay.origin.y + top + 0.026, lay.origin.z + along_k))
	var out := form_out(i)
	var along := home.z - fh.z
	return Transform3D(Basis(Vector3.UP.cross(out).normalized(), deg_to_rad(90.0)),
		Vector3(lay.origin.x, lay.origin.y + top + 0.026, lay.origin.z + along))


## The crew carries the stripped boards and their pegs off at the cut to the
## street, with the rest of the kit (`SiteMain._clear_kit`).
func carry_off_forms() -> void:
	for i in strip_boards():
		var f := _at(_forms, i)
		if f.is_empty() or float(f.get("strip", 0.0)) < 0.999:
			continue
		(f["node"] as Node3D).visible = false
		for p in stakes_of_form(i):
			(_at(_stakes, p)["node"] as Node3D).visible = false


## Is the slab's edge on side `k` of `_rebuild_slab`'s skirt loop (0 -z apron,
## 1 +x, 2 +z kerb, 3 -x) open to the eye - its board stripped away?
func _edge_open(k: int) -> bool:
	var board := {1: 2, 2: KERB_BOARD, 3: 1}.get(k, 0) as int
	if board == 0:
		return false
	var f := _at(_forms, board)
	return not f.is_empty() and bool(f.get("edge_open", false))


func _smooth01(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


## The crew takes the broken-out concrete away with them: `k` 0 the heap is still
## on the grass, 1 it is gone. A finished driveway with a pile of somebody's old
## one still sitting on the lawn beside it is only half a job, and it is the
## first thing in the final picture that is not about the new drive.
func hide_rubble(k: float) -> void:
	# MONOTONIC: once a chunk has gone it never comes back. A late caller
	# driving a fade from k = 0 (the cure once did) re-showed the whole heap
	# on the wide for a frame; now it simply finds nothing left to hide.
	var kk := maxf(clampf(k, 0.0, 1.0), _rubble_hidden)
	_rubble_hidden = kk
	# FADED, not sunk. Dropping them through the lawn was meant to read as being
	# loaded out, but there is no truck to load them into: it is forty-eight lumps
	# of concrete descending into somebody's grass in full view of the wide shot.
	for c in _chunks:
		if not is_instance_valid(c):
			continue
		_fade(c, 1.0 - kk)
		c.visible = kk < 0.995


## Takes a mesh and everything under it down to `alpha`. Public, because the
## level fades its own furniture (the cones and the site fence) with the same
## cure that fades the rubble, and there is no reason for two copies of this.
func fade_node(node: Node3D, alpha: float) -> void:
	_fade(node, alpha)


func _fade(node: Node3D, alpha: float) -> void:
	# Through a SURFACE OVERRIDE, taking its own copy of the material the first
	# time it fades one.
	#
	# Writing to `get_active_material` works for the boxes this file builds, since
	# each one makes its own material, and does NOTHING for an imported GLB: those
	# materials are shared by every instance of the scene and need not even be
	# StandardMaterial3D. That is why the site fence and the cones stood at full
	# strength through a cure that had faded all the rubble away.
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for n in meshes:
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var m := mi.get_surface_override_material(s)
			if m == null:
				var base := mi.mesh.surface_get_material(s)
				m = base.duplicate() if base != null else StandardMaterial3D.new()
				mi.set_surface_override_material(s, m)
			if m is BaseMaterial3D:
				var bm := m as BaseMaterial3D
				bm.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if alpha >= 0.999 					else BaseMaterial3D.TRANSPARENCY_ALPHA
				bm.albedo_color.a = alpha


func rubble_gone() -> bool:
	if _chunks.is_empty():
		return true
	for c in _chunks:
		if is_instance_valid(c) and c.visible:
			return false
	return true


## Is every board the child strips off? Read off the boards' own state, not a
## visibility: a stripped board lies on the grass, seen, until the cut.
func forms_stripped() -> bool:
	if _forms.is_empty():
		return false
	return open_strip_forms().is_empty()


## How far a parked car's nose stands off the garage's front (the plan's 6.1):
## the hatchback's gap since it first parked, now kept for every car. At one
## fixed spot a 5.45 m pickup's nose went through the shut door.
const PARK_NOSE_GAP := 0.385


## Where a car parks on the finished drive (it noses in toward the garage, yaw
## 180): its origin `nose_m` behind its nose (`Machine.nose_m`), so its nose
## stands `PARK_NOSE_GAP` off the garage whatever its length. The hatchback's
## 2.015 m is the legacy spot, z -1.0.
func park_spot(nose_m: float = 2.015) -> Vector3:
	return Vector3(CENTRE_X, GRADE, Z_APRON + PARK_NOSE_GAP + nose_m)


# --- Posing (tests and screenshots) -----------------------------------------------------------

## The stages a drive is posed at, in the order the job makes them. A resumed
## job (6.2) reads this to find the stage a saved step stands on.
const STAGE_ORDER := ["old", "broken", "cleared", "formed", "staked", "tipped", "packed", "kerbed",
	"based", "rebar", "banded", "poured", "sprayed", "screeded", "jointed", "cured", "done", "parked"]

## Puts the whole driveway into the state a given phase STARTS in, with no
## animation: the only honest way to take a screenshot of phase 8 without
## playing phases 1 to 7, and what the smoke test poses with.
func pose_stage(stage: String) -> void:
	# `parked` is `done` plus the car, which `SiteMain.pose` adds: without it here
	# the payoff shot posed a car on the OLD cracked driveway, because an unknown
	# stage name quietly poses nothing at all.
	# `rebar` is the steel down on the base; `banded` is the kerb end the chute can
	# reach filled and the rest still bare - the picture the rake starts from.
	# `tipped` is the base down and loose (the plate is next), `packed` the base
	# packed with the kerb board waiting over its slot, `kerbed` that board in and
	# its two pegs waiting; `cured` is the broomed slab gone off, forms still on;
	# `done` is the forms stripped (the fifth session, 2026-09-15).
	var order := STAGE_ORDER
	var at := order.find(stage)
	if at < 0:
		return
	# Every threshold by NAME: the fifth session inserted four stages and the
	# old magic numbers each meant a different picture overnight.
	var s := func(name: String) -> int: return order.find(name)
	var poured_at: int = s.call("poured")
	if at >= 1:
		for i in range(1, panel_count() + 1):
			for sp in range(1, SPOTS_PER_PANEL + 1):
				jack_spot((i - 1) * SPOTS_PER_PANEL + sp, 1.0)
			break_panel(i, false)
		set_banks(1.0)
	if at >= s.call("cleared"):
		# Through the same heap the push builds: posing every chunk at ONE
		# point made a heap a tenth the size of the drive in every wide shot
		# after it (round 6, and the ninth pose/play drift).
		for lane in range(1, PANELS_X + 1):
			_tip_into_pile(lane)
		_cleared_emitted = true
	# Waiting in the air over their places, which is how the forms phase OPENS -
	# a posed shot that hides them cannot show what the arrow is pointing at, and
	# a critic judging from poses would keep re-finding a fault that is fixed.
	# Not the KERB board: it is not on site until the base is packed (5.2).
	if at >= s.call("cleared"):
		for i in range(1, form_count() + 1):
			if i != KERB_BOARD:
				set_form(i, 0.0)
	if at >= s.call("formed"):
		for i in range(1, form_count() + 1):
			if i != KERB_BOARD:
				set_form(i, 1.0)
		for i in range(1, stake_count() + 1):
			if stake_board(i) != KERB_BOARD:
				set_stake(i, 0.0)
	if at >= s.call("staked"):
		for i in range(1, stake_count() + 1):
			if stake_board(i) != KERB_BOARD:
				set_stake(i, 1.0)
	if at >= s.call("tipped"):
		gravel_fill(1.0)
		# The heap is loaded out once the base is down (the muck-away lorry
		# takes it while the steel is being laid - off screen): it was the
		# busiest thing in the corner of six working frames (round 13).
		hide_rubble(1.0)
	if at >= s.call("packed"):
		pack_all()
		set_form(KERB_BOARD, 0.0)
	if at >= s.call("kerbed"):
		set_form(KERB_BOARD, 1.0)
		for i in stakes_of_form(KERB_BOARD):
			set_stake(i, 0.0)
	if at >= s.call("based"):
		for i in stakes_of_form(KERB_BOARD):
			set_stake(i, 1.0)
	if at >= s.call("rebar"):
		show_chairs(true)
		for i in range(1, bar_count() + 1):
			set_bar(i, 1.0)
	if at == s.call("banded"):
		# What the chute has put down by the time the child picks the rake up:
		# a short heap at the kerb end, FULL, and bare stone everywhere else.
		# There is no half-filled tier any more - a cell is bare or it is
		# concrete, because a depth is what the child could not read.
		var full_b := GRADE - BASE_TOP
		var heap_b: float = config.pour_heap if config != null else 0.045
		for iz in range(CELLS_Z):
			for ix in range(CELLS_X):
				var i := iz * CELLS_X + ix
				if _cell_z(iz) >= Z_KERB - 1.2:
					_fill[i] = full_b + heap_b * 0.6
		_refresh_cells()
		set_wet(config.wet_poured if config != null else 0.80)
	if at >= poured_at:
		var full := GRADE - BASE_TOP
		for i in range(_fill.size()):
			_fill[i] = full * 0.94
		_refresh_cells()
		set_wet(config.wet_poured if config != null else 0.80)
	if at >= s.call("sprayed"):
		# Wetted the way the child wets it - every cell soaked, through the same
		# coverage grid - rather than by one number written over the whole slab, or
		# a posed picture cannot show the patchwork that IS the phase.
		set_wet(config.wet_poured if config != null else 0.80)
		var soaked: float = config.wet_sprayed if config != null else 0.95
		for i in range(_watered.size()):
			_watered[i] = 1.0
		_wet_target = soaked
		for i in range(_cell_col.size()):
			_paint_cell(i)
	if at >= s.call("screeded"):
		screed(1.0)
	if at >= s.call("jointed"):
		for i in range(1, joint_count() + 1):
			cut_joint(i, 1.0)
	if at >= s.call("cured"):
		# Dried, as the cure leaves it in play. Without this the posed
		# screenshot showed the broom finish at four times the contrast it will
		# ever really have, and every judgement made off it was flattering.
		set_wet(0.06)
		broom(1.0)
	if at >= s.call("done"):
		# The child has stripped the forms by `done` now (5.3): laid on the grass
		# beside their edges; `parked` has them carried off (`SiteMain._clear_kit`).
		strip_forms(1.0)


# --- Plumbing ---------------------------------------------------------------------------------

func marker(want: String) -> Node3D:
	if _markers.has(want):
		return _markers[want]
	return null


## Panel `i` (1-based), or an EMPTY dictionary when there is no such panel.
## Typed `Dictionary` rather than `Variant` on purpose: a `Variant` return makes
## every `var p := _panel(i)` at the eleven call sites an inference off a Variant,
## which GDScript treats as a parse error, not a warning.
func _panel(i: int) -> Dictionary:
	if i < 1 or i > _panels.size():
		return {}
	return _panels[i - 1]


## The same for the boards and the stakes, 1-based, `{}` for "no such thing".
func _at(list: Array, i: int) -> Dictionary:
	if i < 1 or i > list.size():
		return {}
	return list[i - 1]


func _mid_z() -> float:
	return (Z_APRON + Z_KERB) * 0.5


func _cell_x(ix: int) -> float:
	var cw := WIDTH / float(CELLS_X)
	return CENTRE_X - WIDTH * 0.5 + cw * (float(ix) + 0.5)


func _cell_z(iz: int) -> float:
	var cl := LENGTH / float(CELLS_Z)
	return Z_APRON + cl * (float(iz) + 0.5)


## How far the middle of cell (ix, iz) stands off its fill: nothing once the
## screed has been over it, a fixed little wander before - so the lumps do not
## crawl while the child watches, and a fresh pour is not a billiard table.
func _lump(ix: int, iz: int, i: int) -> float:
	if _struck[i] != 0 or _fill[i] < 0.03:
		return 0.0
	var up := LUMP * (0.5 + 0.5 * (0.6 * sin(float(ix) * 2.3 + float(iz) * 1.9)
		+ 0.4 * cos(float(ix) * 1.1 - float(iz) * 2.7)))
	if _wave_z > -100.0:
		# Twice as lumpy while the screed is on the slab: from the screed's
		# kneeling eye one cell is a quarter of the frame and the unstruck
		# side measured 1.6% peak to peak - a plane (round 13). Only during
		# the screed, so it cannot leak into the water beat.
		up *= 2.4
		var ahead := _cell_z(iz) - _wave_z
		if ahead > -0.2 and ahead < 0.9:
			up += WAVE * maxf(1.0 - absf(ahead - 0.25) / 0.65, 0.0)
	if _mound_at != Vector3.INF:
		# Wide enough to span three cells and tall enough that a profile across
		# the landing MOVES (round 13: 5 cm over 0.7 m was a four-degree ramp
		# the shading never showed).
		var d := Vector2(_cell_x(ix) - _mound_at.x, _cell_z(iz) - _mound_at.z).length()
		up += MOUND * maxf(1.0 - d / 1.0, 0.0)
	return up


## What cell j is drawn as: its own colour, mottled, and TINTED TOWARD THE
## BASE by how far short of full it is - so depth has a colour, a thin pour
## reads as mud over limestone, and the come-along's "where is still to do"
## is a picture (round 9; the user: "it was hard to tell where I was supposed
## to spread it").
func _drawn_col(ix: int, iz: int, i: int) -> Color:
	var col := _cell_col[i] * _mottle(ix, iz, i)
	var full := GRADE - BASE_TOP
	var short := 1.0 - clampf(_fill[i] / full, 0.0, 1.0)
	# A cell still to fill is DARK WET MUD: a LUMA step (round 14: a lerp
	# toward the base's tan was a warmth step with no luma at all, and the
	# come-along's "still to do" vanished the moment the pool covered the
	# base; the water's -13% luma step is what reads). A hard edge at six per
	# cent short, a slope on top of it for how short. The pour's leading edge
	# is darker and wetter than the pool behind it, which is what wet
	# concrete spreading looks like.
	if short > 0.06:
		col = col.lerp(SHORT_COL, 0.40 + 0.30 * short)
	return col


## Is every cell round (ix, iz) drawn - so it is in the body of the pour,
## not at its front?
func _interior(ix: int, iz: int) -> bool:
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var jx := ix + dx
			var jz := iz + dz
			if jx < 0 or jx >= CELLS_X or jz < 0 or jz >= CELLS_Z:
				continue
			if _fill[jz * CELLS_X + jx] <= MIN_DRAW:
				return false
	return true


## The colour the concrete pool is right now: what a stream of the same
## material should be a step lighter than.
func pool_colour() -> Color:
	return _base_col


## The colour the pool is DRAWN under a world point - the depth tint included,
## which `pool_colour` is not: the stream took the material's colour while the
## pool under it was drawn sandy, and the two were 35 points apart in hue
## (round 10).
func pool_colour_at(world: Vector3) -> Color:
	var cw := WIDTH / float(CELLS_X)
	var cl := LENGTH / float(CELLS_Z)
	var ix := clampi(int(floor((world.x - (CENTRE_X - WIDTH * 0.5)) / cw)), 0, CELLS_X - 1)
	var iz := clampi(int(floor((world.z - Z_APRON) / cl)), 0, CELLS_Z - 1)
	var i := iz * CELLS_X + ix
	if _fill[i] <= MIN_DRAW:
		return gravel_colour().lerp(_base_col, 0.5)
	return _drawn_col(ix, iz, i)


## How high the concrete (or, where there is none, the base) stands under a
## world point: what a splash or a stream's foot has to sit ON.
func surface_y(world: Vector3) -> float:
	return maxf(concrete_top(world), BASE_TOP)


## The top of the CONCRETE under a world point, or -INF where there is none.
##
## `surface_y` answers "concrete, or the base underneath it", which is what a
## splash sits on. This answers "is there a slab here at all", which is what a
## WHEEL needs, and the two are not the same question: conflating them would
## float the tipper over bare dirt. One cell lookup serves both, so they cannot
## drift apart.
func concrete_top(world: Vector3) -> float:
	var cw := WIDTH / float(CELLS_X)
	var cl := LENGTH / float(CELLS_Z)
	var ix := int(floor((world.x - (CENTRE_X - WIDTH * 0.5)) / cw))
	var iz := int(floor((world.z - Z_APRON) / cl))
	if ix < 0 or ix >= CELLS_X or iz < 0 or iz >= CELLS_Z:
		return -INF
	var i := iz * CELLS_X + ix
	if _fill[i] <= MIN_DRAW:
		return -INF
	return BASE_TOP + _fill[i] + _lump(ix, iz, i)


## The corner noise: by corner index, so neighbours agree. Only where every
## cell round the corner is drawn and at least one is unstruck.
func _corner_lump(cx: int, cz: int, unstruck: float) -> float:
	if unstruck <= 0.0:
		return 0.0
	# Two frequencies, so no two corners in a row agree and the facets between
	# them tip every way.
	# Off pi in z (round 8: 3.1 put every other row in antiphase - a grid).
	var n := 0.5 + 0.5 * sin(float(cx) * 5.3 + float(cz) * 2.37) * cos(float(cx) * 1.7 - float(cz) * 1.81)
	n = 0.6 * n + 0.4 * (0.5 + 0.5 * sin(float(cx) * 2.1 - float(cz) * 5.9))
	return LUMP_C * n * unstruck * (2.4 if _wave_z > -100.0 else 1.0)


## Where the chute is landing concrete (INF when it is not).
func set_pour_mound(at: Vector3) -> void:
	_mound_at = at
	_slab_dirty = true
	if _crest_mesh == null:
		_crest_mesh = MeshInstance3D.new()
		_crest_mesh.name = "PourCrest"
		_crest_mesh.mesh = _build_dome_mesh()
		_crest_mat = _slab_mat.duplicate() as StandardMaterial3D
		_crest_mat.vertex_color_use_as_albedo = false
		_crest_mat.disable_receive_shadows = true
		_crest_mesh.material_override = _crest_mat
		_crest_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_crest_mesh)
	if at == Vector3.INF:
		_crest_mesh.visible = false
		return
	_crest_mesh.visible = true
	_crest_mesh.position = Vector3(at.x, surface_y(at) - 0.01, at.z)
	var pool := pool_colour_at(at)
	_crest_mat.albedo_color = Color(pool.r * 1.05, pool.g, pool.b * 0.94).lightened(0.10)


## How high the crest under the spout stands: what the stream lands ON.
const CREST_H := 0.12


func crest_top(at: Vector3) -> float:
	return surface_y(at) + CREST_H * 0.9


## A faceted dome, 0.55 m across and 0.12 high, lumpy round its rim: the heap
## of concrete under the spout. Normals lean up so it takes the surface's
## light and reads as the slab heaped, not as a ball on it.
func _build_dome_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spokes := 14
	var rings := 4
	var radius := 0.55
	var height := 0.12
	var pts: Array = []
	for r in range(rings + 1):
		var ring: Array = []
		var t := float(r) / float(rings)
		for k in range(spokes):
			var a := TAU * float(k) / float(spokes)
			var lump := 1.0 + 0.16 * sin(a * 3.0 + 0.4) + 0.10 * cos(a * 5.0 + 1.1)
			var rr := radius * t * lump
			var y := height * (1.0 - t * t) * (1.0 + 0.12 * sin(a * 4.0 + float(r)))
			ring.append(Vector3(cos(a) * rr, y, sin(a) * rr))
		pts.append(ring)
	var white := Color.WHITE
	for r in range(rings):
		for k in range(spokes):
			var k2 := (k + 1) % spokes
			var a: Vector3 = pts[r][k]
			var b: Vector3 = pts[r][k2]
			var c: Vector3 = pts[r + 1][k2]
			var d: Vector3 = pts[r + 1][k]
			var out := Vector3((a.x + c.x) * 0.5, height + 0.3, (a.z + c.z) * 0.5)
			if r == 0:
				_wave_tri(st, a, c, d, white, white, white, out, 0.5)
			else:
				_wave_tri(st, a, b, c, white, white, white, out, 0.5)
				_wave_tri(st, a, c, d, white, white, white, out, 0.5)
	return st.commit()


## The same for the colour: a fresh pour is mottled and a shade darker (wet
## mud); a struck cell is even and pale. The value step is what lets the
## struck band read from the WIDE shot.
## The roll of surplus in front of the screed board: a half-round ridge across
## the drive, lumpy along its length, in the surface's own colours.
func _build_wave_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := WIDTH * 0.47
	var cols := 26
	var rings := 7
	# TALLER than the board's top edge, so the crest breaks the board's line
	# against the struck plane behind it: a ridge below the board's top had no
	# silhouette from the screed's low eye (round 11).
	var rz := 0.12
	var ry := 0.14
	var pts: Array = []
	var cols_c: Array = []
	for cx in range(cols + 1):
		var u := float(cx) / float(cols)
		var x := lerpf(-half, half, u)
		# Lumps at the cell pitch and a finer jitter, and the ends taper.
		var lump := 1.0 + 0.22 * sin(x * TAU / (WIDTH / float(CELLS_X)) + 0.7) + 0.12 * sin(x * 7.3 + 1.9)
		var taper := clampf((half - absf(x)) / 0.25, 0.0, 1.0)
		var m := 0.90 + 0.03 * sin(float(cx) * 5.1) + 0.02 * cos(float(cx) * 2.9)
		# In the colour the unstruck cell under it is DRAWN - wet, mottled -
		# so the roll is the surface heaped up, not a paler drift on it.
		var cix := clampi(int(floor((x + WIDTH * 0.5) / (WIDTH / float(CELLS_X)))), 0, CELLS_X - 1)
		var ciz := clampi(int(floor((_wave_z + 0.22 - Z_APRON) / (LENGTH / float(CELLS_Z)))), 0, CELLS_Z - 1)
		var under: Color = _cell_col[ciz * CELLS_X + cix] if _cell_col.size() > ciz * CELLS_X + cix else _base_col
		cols_c.append(Color(m, m, m, 1.0) * under)
		var ring: Array = []
		for r in range(rings + 1):
			var a := PI * float(r) / float(rings)
			ring.append(Vector3(x, sin(a) * ry * lump * taper, -cos(a) * rz * (0.7 + 0.3 * taper)))
		pts.append(ring)
	for cx in range(cols):
		for r in range(rings):
			var a: Vector3 = pts[cx][r]
			var b: Vector3 = pts[cx + 1][r]
			var c: Vector3 = pts[cx + 1][r + 1]
			var d: Vector3 = pts[cx][r + 1]
			var ca: Color = cols_c[cx]
			var cb: Color = cols_c[cx + 1]
			var out := Vector3(0.0, (a.y + c.y) * 0.5 + 0.02, (a.z + c.z) * 0.5)
			_wave_tri(st, a, b, c, ca, cb, cb, out)
			_wave_tri(st, a, c, d, ca, cb, ca, out)
	return st.commit()


## One face of the ridge, wound so it faces `out` (Godot's front faces are
## clockwise; the intuitive order renders nothing).
func _wave_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		ca: Color, cb: Color, cc: Color, out: Vector3, up_lean: float = 0.7) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	var flip := n.dot(out) > 0.0
	# Normals leaning UP (`up_lean`): lit like the flat surface it is made of,
	# with only a little of its own rounding, so it is the slab's colour heaped
	# up and not a dark cylinder beside it. The crest under the spout leans
	# less: leaning 0.7 its flat top took 1.4x the slab's light and rendered
	# +40% where +12% was written (round 15).
	var nn := (n.normalized() * (-1.0 if flip else 1.0)).lerp(Vector3.UP, up_lean).normalized()
	var order: Array = [[a, ca], [c, cc], [b, cb]] if flip else [[a, ca], [b, cb], [c, cc]]
	for v in order:
		st.set_normal(nn)
		st.set_color(Color(v[1]))
		st.add_vertex(Vector3(v[0]))


func _mottle(ix: int, iz: int, i: int) -> Color:
	if _struck[i] != 0 or _fill[i] < 0.03:
		return Color.WHITE
	# The z coefficients are OFF pi: at 3.3 consecutive rows were in antiphase
	# and the whole wet slab was a chequerboard for four phases (round 8). And
	# a third of the amplitude - the mottle sits alongside the struck/unstruck
	# step, it does not compete with the water's coverage step.
	var m := 0.90 + 0.03 * sin(float(ix) * 5.1 + float(iz) * 2.37) + 0.02 * cos(float(ix) * 2.9 - float(iz) * 1.81)
	return Color(m, m, m, 1.0)


## The surface is out of date: rebuilt on the next frame (a pour touches it
## every frame, and a drag touches a dozen cells a frame).
func _refresh_cells() -> void:
	_slab_dirty = true
	# The screed strikes cells without repainting them: the puddles follow
	# the cell state here as well.
	for i in range(_puddles.size()):
		_update_puddle(i)


## Rebuilds the surface NOW, for a test or a pose that wants to look at it
## before the next frame.
func refresh_now() -> void:
	_rebuild_slab()


func _box(box_name: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	bm.material = mat
	mi.mesh = bm
	mi.position = at
	return mi
