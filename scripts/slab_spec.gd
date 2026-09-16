class_name SlabSpec
extends Resource
## The rectangle a job is poured into (the improvement plan's 6.5): where it
## sits, how big it is, and how finely it fills.
##
## Until this existed the slab WAS the driveway - 3.6 m by 9.0 m at x 2.6 -
## written as constants in `Driveway` and read 599 times. A second job needs a
## different rectangle, and the plan's line is "the slab's rectangle becomes a
## Slab spec (centre, width, length, cells) instead of constants".
##
## WHAT IS NOT HERE, and will not be: `GRADE`, `BASE_TOP` and `DIG`. Those are
## LEVELS, not the rectangle - grade is 0.0 by definition of finished grade, and
## a sidewalk flag is the same 100 mm slab on the same 100 mm base as a
## driveway. They are 183 of those 599 references and not one of them is a thing
## a job can differ in, so they stay `const` in `Driveway`.
##
## HOW IT REACHES THE SLAB. `Driveway`'s rectangle is `static var` now rather
## than `const`, so all 782 existing reads - bare inside the class,
## `Driveway.WIDTH` outside it - keep working untouched while the numbers can be
## set at run time. `SiteMain._enter_tree` pushes the spec in beside
## `crack_base`, before the Driveway builds itself in its own `_ready`; that is
## the seam session 6 proved.
##
## THE PRICE, said out loud: static means PROCESS-GLOBAL, and this project has
## been bitten by that class of bug more than once (the hand-off's own bullet:
## "Process-global switches must be put back"). Two slabs of different shapes
## cannot exist in one process. Nothing today wants that - the title row's
## backdrop is the only second level, and it stands alone - and the defences are
## the two the project already knows: `apply()` is called UNCONDITIONALLY, never
## "if the job names a spec", so a job with no spec restores the defaults rather
## than inheriting whatever the last one left; and the smoke asserts the
## driveway's numbers are still the driveway's after a NEXT and after a title
## backdrop has stood.

## The middle of the slab in world x, and the z of its two ends. +Z is toward
## the street, so `z_kerb` is the end nearest the road.
@export var centre_x: float = 2.6
@export var z_apron: float = -3.4
@export var z_kerb: float = 5.6
## How wide it is across, metres. The length follows from the two ends and is
## kept as its own number only because `Driveway.LENGTH` is read 33 times.
@export var width: float = 3.6

## The fill grid: how many cells across, and how many up the slab. Fine enough
## that a swept chute lays a band rather than filling a quarter at once, coarse
## enough that the boxes are nothing to draw.
@export var cells_x: int = 6
@export var cells_z: int = 12

## The OLD slab that is broken up first: how many panels across and up.
@export var panels_x: int = 2
@export var panels_z: int = 2

## How many COUNTS, as against shapes.
##
## Every one of these used to be a literal in `Driveway` - `joint_count()`
## returning a hard 2, `BARS_ALONG` 4, a `count := [4, 4, 2, 0]` list - and
## every one is a number a three-metre flag and a nine-metre drive disagree
## about. They are here rather than derived from the rectangle on purpose: a
## driveway's four stakes to a board and twelve bites are pacing decisions the
## critic rounds argued about, not arithmetic ("twelve taps is a phase, forty is
## a chore"), and a formula would quietly overrule them.
##
## What is NOT here, and is the next session's work: the SHAPE of the form list
## itself. A driveway is two long boards, a kerb board and an expansion strip
## against the garage; a flag is two boards with the kerb face and a
## neighbouring flag for its other sides. That is a different structure, not a
## different number, and inventing the abstraction with only one case to check
## it against is how the wrong abstraction gets built.

## Saw-cut joints across the finished slab. Bays are joints + 1.
@export var joints: int = 2
## The steel: bars up the slab, and bars across it.
@export var bars_along: int = 4
@export var bars_across: int = 8
## Stakes to a LONG board and to a SHORT one.
@export var stakes_per_long: int = 4
@export var stakes_per_short: int = 2
## How many groups the form boards are worked in.
@export var form_groups: int = 3
## Places the hammer is worked on one old panel, and so how many cracks grow.
@export var spots_per_panel: int = 3


## The numbers the driveway has always had. A job that names no spec gets these,
## which is what makes the unconditional push safe: the defaults are written
## here as literals and never read back off `Driveway`, so a level cannot
## inherit the shape of the one before it.
static func driveway() -> SlabSpec:
	return SlabSpec.new()


## Stands this rectangle up in `Driveway`'s static fields. Called before the
## slab builds itself, and called for EVERY level, spec or no spec.
func apply() -> void:
	Driveway.CENTRE_X = centre_x
	Driveway.Z_APRON = z_apron
	Driveway.Z_KERB = z_kerb
	Driveway.WIDTH = width
	Driveway.LENGTH = maxf(z_kerb - z_apron, 0.1)
	Driveway.CELLS_X = maxi(cells_x, 1)
	Driveway.CELLS_Z = maxi(cells_z, 1)
	Driveway.PANELS_X = maxi(panels_x, 1)
	Driveway.PANELS_Z = maxi(panels_z, 1)
	Driveway.JOINTS = maxi(joints, 0)
	Driveway.BARS_ALONG = maxi(bars_along, 1)
	Driveway.BARS_ACROSS = maxi(bars_across, 1)
	Driveway.STAKES_PER_LONG = maxi(stakes_per_long, 0)
	Driveway.STAKES_PER_SHORT = maxi(stakes_per_short, 0)
	Driveway.FORM_GROUPS = maxi(form_groups, 1)
	Driveway.SPOTS_PER_PANEL = maxi(spots_per_panel, 1)


## What `Driveway` is standing at right now, for a probe that wants to say "and
## nothing moved" without naming nine numbers.
static func live() -> Dictionary:
	return {"centre_x": Driveway.CENTRE_X, "z_apron": Driveway.Z_APRON,
		"z_kerb": Driveway.Z_KERB, "width": Driveway.WIDTH, "length": Driveway.LENGTH,
		"cells_x": Driveway.CELLS_X, "cells_z": Driveway.CELLS_Z,
		"panels_x": Driveway.PANELS_X, "panels_z": Driveway.PANELS_Z,
		"joints": Driveway.JOINTS, "bars_along": Driveway.BARS_ALONG,
		"bars_across": Driveway.BARS_ACROSS, "stakes_per_long": Driveway.STAKES_PER_LONG,
		"stakes_per_short": Driveway.STAKES_PER_SHORT, "form_groups": Driveway.FORM_GROUPS,
		"spots_per_panel": Driveway.SPOTS_PER_PANEL}


## Is what is standing in `Driveway` this spec?
##
## Written as two loops rather than one long `and` chain: the chain needed a
## line continuation per field, and every field added to this resource would
## have to remember one.
func is_live() -> bool:
	var now := live()
	for k: String in ["cells_x", "cells_z", "panels_x", "panels_z", "joints",
			"bars_along", "bars_across", "stakes_per_long", "stakes_per_short",
			"form_groups", "spots_per_panel"]:
		if int(now[k]) != int(get(k)):
			return false
	for k: String in ["centre_x", "z_apron", "z_kerb", "width"]:
		if absf(float(now[k]) - float(get(k))) > 0.0001:
			return false
	return true
