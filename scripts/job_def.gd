class_name JobDef
extends Resource
## One whole job the garage can play (DESIGN.md section 10): what is wrong with
## the car when it drives in, the list of beats that put it right, and the
## payoff the child gets for finishing.
##
## The tire change is `data/jobs/tire_change.tres`. Adding one of the fourteen
## jobs in `docs/JOBS.md` is a second `.tres` plus whatever verb and prop it
## does not already have - never a change to `GarageMain`.

## What the child calls this job. Never shown: there are no words on screen.
@export var name: String = ""
## What is wrong with the car as it arrives, so the level can set it up:
## `flat_fl` (the front-left tire is flat), later `dead_battery`, `dark_lamp_l`.
@export var arrives_with: String = "flat_fl"
## What the child gets for finishing: `drive_out` (YAY!, horn, lights, the car
## drives away), later `vroom`, `lights`, `wipers`.
@export var payoff: String = "drive_out"
## The beats, in order.
@export var steps: Array[JobStep] = []


## The wheel this job is about, from `arrives_with` (`flat_fl` -> `FL`). Jobs
## that are not about a wheel still answer FL, which is the corner every camera
## shot and every stand-in is built around.
func corner() -> String:
	var tail := arrives_with.get_slice("_", arrives_with.get_slice_count("_") - 1).to_upper()
	if tail in ["FL", "FR", "RL", "RR"]:
		return tail
	for s in steps:
		var c := s.corner()
		if c != "":
			return c
	return "FL"


## Which step plays `verb` - the `nth` one that does, counting from 1 - or -1
## when none does. The screenshot poses steer by this rather than by a number,
## so a job that gains a beat in the middle does not silently pose every shot
## one step early. `nth` because a verb may come back later in a job: the kerb
## board is a second `form_set` after the base (Build Crew's plan, 5.2).
func index_of(verb: String, nth: int = 1) -> int:
	var seen := 0
	for i in range(steps.size()):
		if steps[i].verb == verb:
			seen += 1
			if seen >= nth:
				return i
	return -1


## How many progress steps the whole job is worth: the thirteen of the tire
## change (5 nuts + wheel off + wheel on + 5 nuts + the torque pass; the two
## lift presses count 0).
func total_weight() -> int:
	var n := 0
	for s in steps:
		n += s.count * s.progress_weight
	return n


## How many progress steps are done once `index` whole steps are behind us and
## `done` taps of the step at `index` have been made.
func weight_before(index: int, done: int) -> int:
	var n := 0
	for i in range(mini(index, steps.size())):
		n += steps[i].count * steps[i].progress_weight
	if index >= 0 and index < steps.size():
		n += mini(done, steps[index].count) * steps[index].progress_weight
	return n
