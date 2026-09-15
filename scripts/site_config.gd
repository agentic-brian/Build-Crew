class_name SiteConfig
extends Resource
## Every feel-tunable number for the driveway job lives here (DESIGN 4).
## Edit res://data/site_config.tres (or the Inspector) - no code changes needed.
##
## Nothing in scripts/site_*.gd or driveway.gd may hold a feel number of its
## own. Layout positions are NOT here: those are consts in `SiteMain` and
## `Driveway`, because they are the WORLD the job happens in rather than how
## the job feels.
##
## The trap this inherits from Car Garage: a `.tres` stores its own values, so
## changing a default here does nothing until the resource is edited too. The
## smoke test asserts the numbers it cares about off the loaded resource.

@export_group("Camera")
## Seconds the camera takes to ease from one named shot to another. (DESIGN 1a)
@export_range(0.1, 3.0, 0.05) var shot_time: float = 0.8
## The job OPENS on the wide - the house, the cracked drive, the tools - for
## this long, or until the first touch, and then eases down to the first slab
## over `opening_ease` (the improvement plan's 3.1). A job opens and closes on
## the same wide picture, so the payoff is the child's own before-and-after.
@export_range(0.0, 5.0, 0.1) var opening_hold: float = 1.5
@export_range(0.2, 3.0, 0.05) var opening_ease: float = 1.2

@export_group("Taps")
## The finger has to land ON the thing the arrow points at, or near it, or on
## the arrow itself; a tap elsewhere only makes the arrow bounce harder
## (DESIGN 0, inherited from Car Garage 12g). On, a tap ANYWHERE works - the
## toddler version.
@export var tap_anywhere: bool = false
## How near the target a tap may land, as a fraction of the picture's SHORTER
## side - so it is the same finger on an iPad, a phone and a 720p window - on
## top of the target's own size on screen. Generous: a four-year-old aims at
## the middle of a slab, not at a crack.
@export_range(0.05, 0.5, 0.01) var tap_reach: float = 0.22
## And the most a ring's reach may cover in the WORLD, metres, whatever the
## shot: on the wide the 0.22 of the picture was a whole slab, so a tap on
## the far panel worked a ring on the first (the session-3 verification
## pass). On the close shots this never binds. Never under a finger's own
## width on the screen (`tap_reach_min`, a fraction of the shorter side).
@export_range(0.2, 2.0, 0.05) var tap_reach_m: float = 0.55
@export_range(0.02, 0.2, 0.01) var tap_reach_min: float = 0.07
## Seconds of work one press that is let go at once still gives, on any HOLD
## beat, so a child who taps instead of holding is never tapping at nothing.
@export_range(0.0, 1.5, 0.05) var hold_burst: float = 0.35

@export_group("Where to tap")
## How big the gold rings are that mark the places a beat will take, in metres.
## One per phase that has more than one place, because a ring on a 5 cm stake and
## a ring on a third of a concrete slab are not the same ring.
##
## They are drawn `billboard_keep_scale`, so these are the size the ring is at one
## metre and it stays that size on screen however far away the camera is - which
## is what lets a phase with ten places be framed wide enough to show all ten.
## Within a hair of each other on purpose: the mark that means "touch here"
## varied three times over across the job (round 3).
@export_range(0.1, 2.0, 0.05) var ring_spot: float = 0.55
@export_range(0.1, 2.0, 0.05) var ring_form: float = 0.50
@export_range(0.1, 2.0, 0.05) var ring_stake: float = 0.42
@export_range(0.1, 2.0, 0.05) var ring_bar: float = 0.46

@export_group("The jackhammer (phase 1)")
## Seconds ONE bite of the hammer lasts. Eighteen of them make the phase - three
## places on each of six panels - and each one is a TAP, not a hold: what the
## child is being asked to get right is WHERE, not how long.
@export_range(0.3, 4.0, 0.05) var jack_bite: float = 0.95
## How many times a second the bit hammers, and how far it travels on a blow.
@export_range(4.0, 30.0, 0.5) var jack_hz: float = 13.0
@export_range(0.005, 0.08, 0.005) var jack_stroke: float = 0.035
## How far the panel under the bit sinks as it comes apart, metres.
@export_range(0.0, 0.12, 0.005) var panel_sink: float = 0.035
## The dust off the bit: how long a puff lives and how big it is.
@export_range(0.1, 2.0, 0.05) var dust_life: float = 0.55
## 0.22, not 0.10: a 10 cm puff was twenty pale pixels at tablet distance.
@export_range(0.02, 0.4, 0.01) var dust_size: float = 0.22
## How far a chunk of broken concrete hops when the panel lets go, and how
## long that hop takes.
@export_range(0.0, 0.6, 0.01) var chunk_hop: float = 0.14
@export_range(0.1, 1.2, 0.05) var chunk_hop_time: float = 0.35
## The camera's kick on one hammer blow. Tiny: it happens a hundred times.
@export_range(0.0, 0.5, 0.005) var shake_jack: float = 0.02
## A FLOOR under the shake while a bite runs: the picture rattles steadily for
## as long as the bit is in the concrete, the way a breaker really is, and
## stops when it stops. Trauma, squared into the offset like `shake_*`.
## (The improvement plan's 1.4: thirteen blows a second of `shake_jack` never
## climbed above the decay, so the breaker moved nothing.)
@export_range(0.0, 0.6, 0.01) var shake_jack_floor: float = 0.28
## And the kick when a whole panel gives way.
## 0.60, not 0.22 (the plan's 1.4): the offset is trauma SQUARED, so 0.22 was
## a centimetre for a whole slab letting go.
@export_range(0.0, 1.0, 0.01) var shake_break: float = 0.60

@export_group("The skid steer (phase 2)")
## Seconds of held time for ONE push: the whole nine metres of one column of
## the old drive, from inside the garage out to the kerb.
@export_range(0.5, 12.0, 0.1) var push_time: float = 5.4
## Seconds of the swing off the end of the drive onto the heap, and how far back
## from the apron the machine stands inside the garage to start a push.
@export_range(0.5, 4.0, 0.1) var heap_time: float = 1.5
@export_range(0.8, 4.0, 0.1) var garage_stand: float = 1.8
## How fast the machine crawls while it pushes, metres a second, and how far
## its bucket lip rides above the dirt.
@export_range(0.2, 3.0, 0.1) var push_speed: float = 1.1
@export_range(0.0, 0.2, 0.005) var bucket_clear: float = 0.02
## Seconds it takes to back up for the next push, and how far back it goes
## past the first rubble it has to meet.
@export_range(0.5, 5.0, 0.1) var reverse_time: float = 1.6
@export_range(0.5, 4.0, 0.1) var reverse_pad: float = 1.8
## How far the bucket tips forward to shed its load at the pile, degrees, and
## how long that dump takes.
@export_range(10.0, 70.0, 1.0) var bucket_dump_deg: float = 42.0
@export_range(0.2, 2.0, 0.05) var bucket_dump_time: float = 0.7

@export_group("The forms (phases 3 and 4)")
## Seconds a form board takes to swing down into place, and how high it
## starts above its home.
@export_range(0.2, 2.5, 0.05) var form_drop_time: float = 0.65
## 0.40 and not 0.9: a board waiting most of a metre up was a plank lying right
## across the top of the picture with the bare strip of dirt it belongs on down in
## the middle, and nothing said the two had anything to do with each other. At 40
## cm the board hovers over its own line and the arrow, the board and the place
## all land together.
@export_range(0.2, 2.0, 0.05) var form_drop_height: float = 0.40
## Seconds ONE blow of the sledge takes, which is what puts one stake in. Ten
## stakes, ten taps: "one hammer hit per stake".
@export_range(0.2, 2.0, 0.05) var stake_time: float = 0.60
## How far the sledge lifts between blows, metres.
@export_range(0.05, 0.6, 0.01) var sledge_lift: float = 0.26
## 0.38, not 0.08 (the plan's 1.4): squared, 0.08 was under two millimetres of
## picture for a sledge blow the child caused. Gone again in a quarter second.
@export_range(0.0, 0.6, 0.01) var shake_stake: float = 0.38

@export_group("The rebar (phase 5b)")
## Seconds a bar takes to drop onto its chairs, and how high it waits over its
## place while its ring is lit (DESIGN 2d). Lower than a form board: a bar
## lying in the air a hand above a grid of chairs reads as "this goes here".
@export_range(0.2, 2.0, 0.05) var bar_drop_time: float = 0.55
## 0.10, not 0.34: a bar waiting a third of a metre up sat, from the BARS eye,
## 0.4 m to one side of the ring naming its place and out over the grass
## (round 4). A bar is not a board; it barely needs to be off the chairs.
## Back up to 0.32 (round 5): at 0.10 the drop was invisible and twelve taps
## changed nothing on screen. The ring rides on the BAR now, so parallax
## between the mark and the thing is gone by construction.
## A waiting bar lies skewed BESIDE its place (`Driveway.BAR_SKEW_OFF`); this
## is only how far it is lifted as well. Straight up it was invisible at 16 cm
## and thrown over the lawn by parallax at 32 (rounds 5, 11, 12).
@export_range(0.0, 1.5, 0.01) var bar_drop_height: float = 0.06
## How high a LONG bar waits: barely. From the long bars' low eye (4.6) a lift of
## 6 cm threw the two outer bars' pictures onto the form boards; they are cued by
## their fan and their ring. Their landing bounces in the same proportion.
@export_range(0.0, 0.1, 0.005) var bar_long_lift: float = 0.02
## The landing is an EVENT (the improvement plan's 4.7): the bar FALLS onto its
## chairs rather than settling, clangs, and bounces twice - a cross bar this high
## the first time and a third of it the second, over this long, which fixes the
## one gravity the fall runs under too (`Driveway.bar_landing`) - and then the
## black ties pop onto each crossing in turn down a cross bar, this far apart,
## each growing in this long. Twelve identical taps had been the longest
## tap-count in the job with the least on screen per tap.
@export_range(0.0, 0.1, 0.005) var bar_bounce: float = 0.03
@export_range(0.0, 1.0, 0.05) var bar_bounce_time: float = 0.30
@export_range(0.0, 0.3, 0.01) var tie_stagger: float = 0.06
@export_range(0.05, 0.6, 0.01) var tie_pop_time: float = 0.16

@export_group("The gravel base (phase 5)")
## Seconds of held time to tip the whole load out.
## 6.0, not 4.0 (the plan's 3.2): the tipper's own hold should outlast the
## two-second look at it leaving.
@export_range(1.0, 10.0, 0.1) var tip_time: float = 6.0
## How far the bed tips at full load-out, degrees.
@export_range(20.0, 60.0, 1.0) var bed_tip_deg: float = 46.0
## How long the truck takes to back up the drive before it tips, and how far
## along the pad it creeps while it pours (a truck lays a windrow, it does
## not drop one heap).
@export_range(1.0, 8.0, 0.1) var truck_back_time: float = 3.4
@export_range(0.0, 8.0, 0.1) var tip_crawl: float = 5.2
## How many stones a second come off the tailgate while it pours, and how big
## one is.
@export_range(10, 400) var gravel_rate: int = 150
@export_range(0.01, 0.12, 0.005) var gravel_size: float = 0.05

@export_group("The chute (phase 6)")
## Seconds of pouring to fill the whole form, if the chute is aimed well.
## The job's centrepiece, and the user asked for it to take longer than the
## rest: it is the only beat steered with the four pads.
## 26 and not 16, with `Driveway.SLUMP` raised and `SLUMP_RATE` dropped to
## match: "it's filling in the drive way too fast, this should be a mini game kind
## of like the water and broom lines where you have to fill in all the drive way".
## Concrete that finds its own level over nine metres is not a game.
@export_range(4.0, 40.0, 0.5) var pour_time: float = 18.0
## Seconds the chute would take to fill the whole form while the COME-ALONG
## runs: half of `pour_time`, so the truck always supplies faster than the
## rake (`rake_rate`) can draw, and the finger is the only thing the pull waits
## on. A hidden supply cap read as a broken tool (the improvement plan's 2.4).
@export_range(2.0, 40.0, 0.5) var rake_pour_time: float = 9.0
## How far the chute may swing either side of straight back, degrees, and how
## fast a held pad swings it.
##
## 72 rather than 46 because the swing is the only thing that reaches ACROSS the
## form: the spout stands 1.62 m behind its own pivot, so 72 degrees each way
## sweeps 3.1 m of the 3.6 m width and `pour_spread` covers the rest. Measured
## with `machine_probe`, not guessed.
## 46 with the extension chute on (DESIGN 2a): the end of the extension stands
## 2.6 m from the swing pivot, so 46 degrees each way sweeps 3.7 m - the form's
## width - and any more pours onto the lawn.
@export_range(10.0, 85.0, 1.0) var chute_swing_deg: float = 46.0
@export_range(5.0, 90.0, 1.0) var chute_swing_rate: float = 26.0
## How far the chute is folded out once it is deployed (0 stowed, 1 down over the
## form). Deployment only - folding moves the pour point 0.11 m, so it can never
## be an aim - and `chute_out_time` is how long it takes to come out when the
## truck arrives.
## 0.35 with the extension on: fully folded out the fleet's main chute pitches
## sixty degrees down and the extension has to break to near-level off the end
## of it, which reads as a bent straw. A third of the way out it is a gentler
## fall and the extension carries on from it.
@export_range(0.1, 1.0, 0.05) var chute_fold_max: float = 0.15
@export_range(0.3, 4.0, 0.05) var chute_out_time: float = 1.4
## How far the fold angle swings between stowed and deployed, degrees.
@export_range(5.0, 60.0, 1.0) var chute_fold_deg: float = 34.0
## How fast a held pad drives the mixer up or down the drive, metres a second.
## This is the control that covers the LENGTH of the form; the chute's own swing
## covers its width. The truck is held between the two ends of the form, so a pad
## held down cannot quietly pour the load onto the grass.
@export_range(0.2, 4.0, 0.1) var truck_creep_speed: float = 1.3
## The drum's turn while it pours, turns a second.
@export_range(0.1, 3.0, 0.05) var drum_rps: float = 0.35
## How wide the stream lands, metres: the cell under the spout takes the lot
## and everything inside this takes the spill, so a swept chute lays a band.
## How wide the stream lands, metres: the cell under the spout takes the lot
## and everything inside this takes the spill, so a swept chute lays a band.
##
## It cannot go much below 0.70. The swing reaches 2.39 m of the 3.60 m width and
## the spread has to cover the rest, so at 0.64 the outermost column of the form
## was only ever touched by the very tail of the stream, where the weight is
## almost nothing - and the pour stalled one cell short of finished, every time.
## What makes the pour a GAME is `pour_time` and `Driveway.SLUMP`, not a stream so
## narrow that a corner cannot be reached.
@export_range(0.2, 2.0, 0.05) var pour_spread: float = 0.70
## How high the pour may heap one cell above the finish grade, metres. The
## screed cuts it back; without it a child who holds in one place digs a
## tower instead of a slab.
@export_range(0.01, 0.2, 0.005) var pour_heap: float = 0.045
## Seconds of the child being still before the arrow goes and hangs over the
## emptiest corner of the form - or, on the hose and the broom, over the patch
## they have not done yet.
@export_range(0.5, 6.0, 0.1) var chute_hint_delay: float = 2.2
## How much of the form has to be up to grade before the pour is finished. Not
## 1.0, for the same reason `scrub_done` is not: the last tenth of one cell in a
## corner is not worth asking a four-year-old for, and the screed strikes the rest
## off level anyway.
## 0.975 since the come-along: the rake brings the form up cell by cell and
## the last few per cent of a cell are what the screed is for. At 0.995 the
## form sat at 0.991 for ever with the apron end full (smoke run 12).
@export_range(0.9, 1.0, 0.001) var pour_done: float = 0.975
## How full the kerb-end BAND the chute can reach has to be before the chute
## beat hands over to the rake. Lower than `pour_done`, because concrete keeps
## creeping out of the band into the row beyond it as fast as the chute fills it
## - the band hovered at 0.99 for ever - and because the rake finishes the whole
## form to `pour_done` anyway.
@export_range(0.5, 1.0, 0.01) var band_done: float = 0.88
## How fast the pour's camera walks down the drive after the concrete, as a
## fraction of the remaining distance per second. Low enough that the picture is
## never yanked, high enough that the spout never runs out of the front of it.
@export_range(0.5, 8.0, 0.1) var pour_view_rate: float = 2.4
## How far the mixer may creep FORWARD along the road while it pours, metres.
## It stands on the road at the kerb with its chute over the kerb end of the form
## and never puts a wheel on the steel (DESIGN 2a); the creep is what lets the
## chute cover the last couple of metres of the form's length.
@export_range(0.5, 6.0, 0.1) var road_creep: float = 2.2

@export_group("The come-along (phase 6b)")
## The rake the concrete is PULLED up the form with, once the chute has filled
## the end it can reach. Worked like the hose and the broom: a finger dragged
## over the slab, and concrete comes to it from the fuller cells toward the kerb.
## How much concrete one second under the finger pulls, cubic-ish metres, and how
## wide the stroke is.
## 0.40: at 0.12 the rake, not the chute, was the bottleneck - seventy-two cells
## of 0.10 m took a minute to pull. The chute supplies the whole form in
## `pour_time`, and the rake has to keep up with it, not the other way round.
@export_range(0.01, 1.5, 0.005) var rake_rate: float = 0.60
@export_range(0.2, 1.6, 0.05) var rake_radius: float = 0.62
## How far a stroke reaches toward the kerb, in cells of the slab (0.75 m each):
## a rake's pull is about a metre and a half, so the concrete has to be brought up
## the form a stroke at a time from where the chute leaves it.
## The WHOLE form (12 cells) since the user's 2026-09-14 playtest ("it was
## hard to tell where I was supposed to spread it"): a drag anywhere on the
## unfilled part draws on the chute's heap at the kerb end, wherever the
## finger is, and only ever from that heap or from a cell's surplus - never
## out of a cell already at grade. What is still to do is the sandy part.
@export_range(1, 12) var rake_reach: int = 12

@export_group("Finishing (phases 7 to 10)")
## Seconds of held time for the screed and for ONE joint.
@export_range(1.0, 10.0, 0.1) var screed_time: float = 4.2
@export_range(0.5, 6.0, 0.1) var joint_time: float = 1.8

## The hose and the broom are DRAGGED over the slab, so what they cost is not a
## number of seconds but how fast a patch comes up wet or brushed under the
## finger, and how wide that patch is.
##
## How far from the finger the work reaches, metres. Near enough to a cell
## (0.6 x 0.75) that a child has to go everywhere, wide enough that going
## everywhere takes a few sweeps rather than seventy-two dabs.
## 1.05, not 0.95: a cell's diagonal neighbour is 0.9605 m away, so at 0.95 a
## still finger could only ever wet a plus sign (round 3).
## 1.3 (the user, 2026-09-14: the water took too long and it was not obvious
## where was left): a few sweeps cover the slab.
@export_range(0.2, 1.6, 0.05) var scrub_radius: float = 1.30
## Where the hose sits in the child's hands, in the camera's own frame: right of
## the eye, below it, and this far in front (DESIGN 1a, the `HAND` shot).
@export var hose_hold: Vector3 = Vector3(0.40, -0.27, 0.98)
## Where the hose itself runs once it leaves the nozzle's grip: a point in the
## camera's own frame (as `hose_hold`) far enough below the picture that it is off
## the bottom on any landscape screen - a held tool is connected to the bottom of
## the picture, as the rake's and the broom's handles are (the improvement plan's
## 4.3). Not a point just under the frame's edge: at 16:9 that lies ABOVE the
## stub's end, and the hose would climb.
@export var hose_trail: Vector3 = Vector3(0.46, -0.85, 0.62)
## How much of the way to done one second under the finger gets a cell: the hose
## soaks fast, the broom takes a little longer because it is the last thing done.
@export_range(0.2, 8.0, 0.1) var water_rate: float = 6.0
@export_range(0.2, 8.0, 0.1) var broom_rate: float = 4.5
## How much of the slab has to be covered before the beat is finished. Not 1.0:
## the last half of one cell in a corner is not worth asking a four-year-old for.
## 0.85: the last stripe in a corner is not worth asking a four-year-old for
## (the user, 2026-09-14: "just progress player after spraying for so long").
@export_range(0.6, 1.0, 0.01) var scrub_done: float = 0.85
## What a broomed, finished cell dries to (0 dry, 1 glistening).
## 0.62, not 0.25: a broom finish is a texture, not a bleach - at 0.25 the
## brushed patch was 17% brighter than the slab and read as a mat laid down
## (round 3). The brush lines carry the change; the value step only says
## "done here".
## 0.45: the brushed cell's step was 8% and its range overlapped the
## unbrushed (round 8); the lines are right, the patch was not.
@export_range(0.0, 1.0, 0.05) var broom_dry: float = 0.45
## How fast a STICK or the arrow keys move the work point over the slab, metres
## a second, for a child playing without a touch screen.
@export_range(0.5, 8.0, 0.1) var scrub_speed: float = 2.6
## How far the screed board saws side to side as it is pulled, metres, and
## how many times a second. A screed is sawed, never dragged straight.
## Five centimetres: a 3.7 m board sawing 14 cm across a 3.76 m form left
## one end short of its board and the other out over the turf (round 12).
@export_range(0.0, 0.4, 0.01) var screed_saw: float = 0.05
## How near the board's line (or the groover's sled) a finger has to be to
## have hold of it, metres: a DRAG moves the tool the finger is ON, and a
## finger resting further along the slab moves nothing (fourth playtest:
## "pull, not just hold down"; a tool that chased any finger ahead of it was
## the hold again, further along).
@export_range(0.3, 2.0, 0.05) var drag_grab: float = 0.9
## How fast a dragged tool may follow the finger, metres a second: the board
## no faster than a person walks it, the groover a little quicker. A fast flick
## then lags and catches up, which is what pulling feels like; without a cap
## one flick struck nine metres in a third of a second (the plan's 2.5). The
## grab is taken ONCE at the press and kept until the finger lifts.
@export_range(0.3, 5.0, 0.1) var screed_drag_speed: float = 1.2
@export_range(0.3, 5.0, 0.1) var joint_drag_speed: float = 1.5
@export_range(0.5, 6.0, 0.1) var screed_saw_hz: float = 1.8
## How wet the slab looks when it is poured, and after the water (0 dry, 1
## glistening): the sheen the finishing tools work into it.
## 0.55: fresh concrete is a mid grey, a clear step darker than it will dry to
## (at 0.35 the pour rendered nearly white and the centrepiece looked finished
## from its first second) and a clear step LIGHTER than it goes once the hose
## has been over it, or the water phase leaves no mark.
## 0.45: the water's coverage step is what is left between this and
## `wet_sprayed`, and it has to beat the surface's own mottle (round 8).
@export_range(0.0, 1.0, 0.05) var wet_poured: float = 0.45
## 0.60 rather than 0.85. At 0.85 the sprayed slab rendered within 9% of the
## limestone base - so the water phase took the picture back to what it had
## looked like two phases earlier and held it there through the screed and the
## joints. Round 2's own version of "every phase is the same grey box".
@export_range(0.0, 1.0, 0.05) var wet_sprayed: float = 0.95
## How deep a tooled joint is and how wide, metres.
@export_range(0.005, 0.06, 0.005) var joint_depth: float = 0.022
@export_range(0.01, 0.12, 0.005) var joint_width: float = 0.06
## The broom's lines: how many across the whole slab, and how much of the gap
## between two of them is ink. They are FLAT - at 5 mm proud they caught their
## own shadow and the finished drive read as corrugated iron - so what makes them
## readable at tablet distance is the duty, not a relief.
@export_range(8, 80) var broom_lines: int = 40
@export_range(0.05, 0.6, 0.01) var broom_duty: float = 0.22

@export_group("Tools")
## Seconds a tool takes to fly from its rest to the work, and the lob on it.
@export_range(0.1, 2.0, 0.05) var tool_fly_time: float = 0.55
@export_range(0.0, 0.8, 0.02) var tool_arc: float = 0.18
## Seconds the picture HOLDS on a finished phase - the tenth stake in, the
## whole slab wet, the last bay brushed - before the next shot is asked for,
## with the tool going back to its rest. The child sees the thing they finished,
## finished (the improvement plan's 1.6).
@export_range(0.0, 3.0, 0.05) var phase_hold: float = 0.8

@export_group("The payoff")
## Seconds the YAY! lasts.
@export_range(0.0, 8.0, 0.1) var celebrate_time: float = 2.6
## The car says thank-you in its own voice when it has parked (the plan's
## 3.3): `horn_toots` toots, the first `horn_delay` after it stops and the rest
## `horn_gap` apart - Car Garage's numbers, so the family's cars all speak the
## same way. NEXT comes up after the last one.
@export_range(1, 4) var horn_toots: int = 2
@export_range(0.0, 2.0, 0.05) var horn_delay: float = 0.30
@export_range(0.1, 2.0, 0.05) var horn_gap: float = 0.45
## Seconds the forms take to lift away when the slab is finished.
@export_range(0.2, 3.0, 0.05) var strip_time: float = 1.0
## The cure: seconds the light takes to sweep from afternoon to evening. You
## do not drive on green concrete, and a child should not be taught that you
## do, so the car only arrives after this.
@export_range(0.5, 6.0, 0.1) var cure_time: float = 2.2
## Seconds the homeowner's car takes to come up the street and park on it,
## and from how far.
@export_range(1.0, 12.0, 0.1) var park_time: float = 7.5
@export_range(4.0, 30.0, 0.5) var park_distance: float = 16.0
## How tightly the car rounds the corner off the street onto the drive. Wider
## than a machine's (2.4) because a car turning in has the whole road to swing
## through, and a tight corner reads as a pivot rather than a turn.
@export_range(1.0, 6.0, 0.1) var park_turn_r: float = 3.2
## (The sparkles are gone - the plan's 3.3: twenty-six hand-sized dots over a
## nine-metre slab from three metres up were never seen, and the forms coming
## off, the light going and the car turning in ARE the celebration.)

@export_group("Machines")
## Seconds a machine takes to drive on from off-stage, and how far off-stage
## that is.
## 7.0 (the user, 2026-09-14: "vehicles drive in too fast.. they are slow
## moving large trucks in a residential area").
@export_range(1.0, 12.0, 0.1) var arrive_time: float = 7.0
@export_range(4.0, 30.0, 0.5) var arrive_distance: float = 14.0
## Seconds it takes to leave again.
@export_range(1.0, 12.0, 0.1) var leave_time: float = 6.0
## Seconds the exit is WATCHED before the job moves on: the pad cleared, the
## machine pulling out - and then the next place lights up while the truck
## still trundles off up the street in the background (the plan's 3.2). Twenty
## seconds of a four-minute job were a truck getting smaller, each right after
## the child's own effort.
@export_range(0.0, 8.0, 0.1) var leave_look: float = 2.0
## Seconds a skid steer takes to turn ninety degrees on the spot. It is the one
## move nothing else in the fleet can make, so it is worth watching.
@export_range(0.2, 3.0, 0.05) var spin_time: float = 0.85
## Seconds the garage's roller door takes to go up or come down.
@export_range(0.3, 4.0, 0.1) var door_time: float = 1.6
## A machine's wheel radius, for rolling it the right amount per metre. Read
## off the fleet GLBs; a wheel that slips reads as a toy being slid.
@export_range(0.1, 1.0, 0.01) var wheel_radius: float = 0.46
## An engine LEANS INTO THE WORK under the finger: while a held beat flows the
## machine's idle drops to this pitch and comes up this much, over this long,
## and settles back when the finger lifts (the improvement plan's 1.7). Small:
## the contrast is the effect, and the vehicles stay under the tools.
@export_range(0.5, 1.0, 0.01) var engine_lean_pitch: float = 0.90
@export_range(0.0, 8.0, 0.5) var engine_lean_db: float = 2.0
@export_range(0.05, 1.0, 0.05) var engine_lean_time: float = 0.25
## (The engine gain lives in `Sfx.group_gain_db` - the dead `idle_db` knob that
## nothing read is gone, so the two can never stack.)
## The beacon turns while a machine is at work - arriving, working, leaving - and
## is dark when it is parked (the improvement plan's 4.5): the one bit of
## character a machine can have that is not a face and is honest. Flashes a
## second, how bright the lens glows at the top of a flash, and the small warm
## light it throws on the roof: kept short so it never reaches the slab.
@export_range(0.3, 3.0, 0.05) var beacon_hz: float = 1.2
@export_range(0.0, 6.0, 0.1) var beacon_glow: float = 1.6
@export_range(0.0, 4.0, 0.05) var beacon_light_energy: float = 0.8
@export_range(0.5, 5.0, 0.1) var beacon_light_range: float = 2.0
