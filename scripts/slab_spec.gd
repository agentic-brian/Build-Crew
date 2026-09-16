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


## What `Driveway` is standing at right now, for a probe that wants to say "and
## nothing moved" without naming nine numbers.
static func live() -> Dictionary:
	return {"centre_x": Driveway.CENTRE_X, "z_apron": Driveway.Z_APRON,
		"z_kerb": Driveway.Z_KERB, "width": Driveway.WIDTH, "length": Driveway.LENGTH,
		"cells_x": Driveway.CELLS_X, "cells_z": Driveway.CELLS_Z,
		"panels_x": Driveway.PANELS_X, "panels_z": Driveway.PANELS_Z}


## Is what is standing in `Driveway` this spec?
func is_live() -> bool:
	var now := live()
	return absf(now["centre_x"] - centre_x) < 0.0001 \
		and absf(now["z_apron"] - z_apron) < 0.0001 \
		and absf(now["z_kerb"] - z_kerb) < 0.0001 \
		and absf(now["width"] - width) < 0.0001 \
		and int(now["cells_x"]) == cells_x and int(now["cells_z"]) == cells_z \
		and int(now["panels_x"]) == panels_x and int(now["panels_z"]) == panels_z
