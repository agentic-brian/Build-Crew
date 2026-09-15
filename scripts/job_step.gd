class_name JobStep
extends Resource
## One beat of a job (DESIGN.md section 10): ONE thing to do, to ONE named
## target, with ONE tool, seen through ONE camera shot.
##
## A job is nothing but a list of these, so a new job is a `.tres` file rather
## than a new state machine. The tire change is `data/jobs/tire_change.tres`;
## `docs/JOBS.md` is the fourteen more the shape was designed for.
##
##   kind   TAP     the child taps `count` times; each tap runs `verb` once
##          BUTTON  a named HUD button waits (the arrow points at it); pressing
##                  it runs `verb` once
##          AUTO    `verb` runs with no input at all
##          HOLD    the child presses and holds; `verb` starts on the press,
##                  runs while the finger is down and ends when its work is
##                  done (airing a tire up) - DESIGN 12a
##   verb   the name of a handler on `JobVerbs` - `screw_out`, `pull_off`,
##          `lift_up`... Adding a job usually adds none.
##   target what the verb works on, as a name the runner looks up:
##            `NutFL_3`      a node on the vehicle
##            `NutFL_*`      the same, with `*` standing for which tap this is
##                           (tap 1 gets `NutFL_1`), so `count` 5 works five nuts
##            `Rack:TireSlot1`  a node inside one of the level's own props
##            (empty)        the verb needs no target (the lift buttons)
##   tool   `impact_wrench`, or `none`
##   shot   the camera shot this step is played in: `WIDE`, `WHEEL`, and later
##          `HOOD`, `UNDER`, `SIDE`, `FRONT`, `MACHINE`
##
## Every field is an `@export`, so a step is editable in the Inspector.

enum Kind {
	## The child taps: `count` taps, one `verb` each.
	TAP,
	## A HUD button waits. `verb`'s first word names it (`lift_up` -> `lift`).
	BUTTON,
	## No input: the verb runs as soon as the step is entered.
	AUTO,
	## The child presses and HOLDS (DESIGN 12a): the verb starts on the press
	## and runs while the finger is down, reading `JobRunner.held`; it ends
	## itself when its work is done (the tire full). `count` is 1.
	HOLD,
}

@export var kind: Kind = Kind.TAP
## The node the verb works on. `*` is the tap number (1-based); a `Prop:Node`
## name looks inside one of the level's own props instead of the vehicle.
@export var target: String = ""
## The handler on `JobVerbs` that plays this beat.
@export var verb: String = ""
## `impact_wrench`, or `none`.
@export var tool: String = "none"
## The camera shot the step is played in (`CameraRig`).
@export var shot: String = "WIDE"
## How many taps the step takes (1 for a BUTTON or an AUTO).
@export_range(1, 24) var count: int = 1
## An extra `Sfx` group played as the beat starts, on top of whatever the verb
## makes itself. Usually empty.
@export var sound: String = ""
## How many of the job's progress steps one tap of this is worth. 0 for a beat
## that is not the child's work (pressing the lift button is not a "step").
@export_range(0, 12) var progress_weight: int = 1


## Which HUD button a BUTTON step waits for: `lift_up` and `lift_down` are both
## the LIFT button, `start` is START. The runner matches this against the name
## the HUD sends when a button is pressed.
func button_id() -> String:
	if verb == "":
		return ""
	return verb.split("_")[0]


## The target for tap `n` (1-based): `NutFL_*` -> `NutFL_3`.
func target_for(n: int) -> String:
	if target.find("*") < 0:
		return target
	return target.replace("*", str(n))


## The wheel this step works on, read out of its target (`NutFL_*` -> `FL`), or
## "" when the target names nothing with a corner in it.
func corner() -> String:
	for prefix in ["Nut", "Wheel", "Hub"]:
		if target.begins_with(prefix):
			var rest := target.substr(prefix.length())
			if rest.length() >= 2:
				var c := rest.substr(0, 2)
				if c in ["FL", "FR", "RL", "RR"]:
					return c
	return ""
