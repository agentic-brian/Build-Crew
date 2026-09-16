# Build Crew — the contract

A Big Little Jobs game: the construction sibling of **Car Garage** (`car-fixer/`)
and **Tree Crew** (`tree-chop/`). A child does a real construction job, start to
finish, with a hand in every step.

The first job is **New Driveway**: a residential house with a cracked old
concrete drive, taken out and replaced. It is the job the whole level was built
around, exactly as the tire change is Car Garage's.

## 0. The pillars (inherited, not up for debate)

* **No words.** The player cannot read. No labels, no numbers, no tutorial text.
  The gold arrow says where to go; the picture says what is happening.
* **Nothing to buy, earn, unlock or beat.** No score, money, stars, timers,
  streaks or fail states. A miss is never punished — the arrow bounces harder.
* **The tap must land on the thing.** On or near whatever the arrow points at
  (`SiteConfig.tap_reach`, a fraction of the picture's shorter side, plus the
  target's own screen size, or anywhere on the arrow). Target is an iPad and a
  four-year-old's finger, so "near" is generous. Inherited from Car Garage
  DESIGN 12g — never "tap anywhere".
* **Holding IS the work.** If the real motion is continuous — a jackhammer, a
  screed, a broom — the beat is a press-and-HOLD that runs while the finger is
  down and pauses where it is when it lifts. A bare tap still does
  `hold_burst` seconds of work, so a tapper is never tapping at nothing.
* **Show the thing.** Every beat is framed on what the hand is doing, fitted to
  that thing, with whatever is in the way moved out of the picture.
* **Honest sequence.** The order is how the job is really done, with the real
  tool, and the fault is legible as SHAPE (a cracked slab, a gravel-less hole),
  never as tint alone.

## 1. The site

One suburban lot, seen three-quarter from the street side. World axes: **+X is
up the street to the right, +Z is toward the street (south), Y is up.** Metres.

```
      house            garage (built in code, roller door)
      (left of      ┌─────┴─────┐
       the drive)   │  6.4 deep │  the door opening is 3.4 x 2.3
      lawn          └─────┬─────┘  and the drive runs up to it
            lawn  ┌───────────────┐  lawn
                  │   driveway    │   from the garage apron (-Z)
                  │   9.0 x 3.6   │   down to the kerb (+Z)
            ────── kerb / sidewalk ──────
                   SuburbRoad tiles
```

* The **driveway pad** is `Driveway`, a procedural 9.0 x 3.6 m slab of FOUR
  panels (2 along x 2 across - it was six until the user's third playtest:
  "this takes too long being 6 sections"), each its own mesh so it can crack,
  break into rubble and be pushed away. Panel seams are real gaps, so the old drive reads
  as slabs rather than as one painted rectangle.
* The **forms** are three boards round the excavated pad plus an EXPANSION
  JOINT strip against the garage apron (there is nothing to stake a board to
  there, and the new slab must not be tied to the old one), and TEN stakes,
  one blow of the sledge each, each left standing a stub above its board on the
  outside - flush, ten of the child's stops left no mark on the picture. The
  KERB board and its two stakes go in after the base is packed (section 7d):
  both trucks back in through that end.
* The **base** is a gravel bed the dump truck lays inside the forms as a
  WINDROW - full depth, growing along the drive from the garage out, which is
  what a tipper pulling forward really leaves behind it - with three hundred
  loose stones lying on it, because one flat box of grey is a slab of mortar and
  not crushed limestone.
* The **garage** at the head of the drive is built out of boxes here, not
  dropped in as a GLB, because it needs a real opening for a machine to work
  through (section 2c).
* The **steel** is four bars up the drive on plastic chairs and eight across
  on top of them, tied where they cross (`Driveway._build_rebar`, section 2d).
  The chairs are the lesson: the bars sit UP, in the middle of the slab.
* The **concrete** is a fill grid (`Driveway.CELLS_X` x `CELLS_Z`) whose cell
  heights rise where the chute pours and where the rake pulls, then are
  flattened by the screed, grooved by the jointer and brushed by the broom. It
  is drawn as ONE surface (`Driveway._rebuild_slab`): a heightfield with the
  cell heights blended at the corners, smooth-shaded, coloured per vertex, with
  a skirt down to the base wherever a mound meets an empty cell. It was
  seventy-two separate boxes, and in every frame of the pour they read as a
  floor of loose paving slabs at different heights (round 3). A cell the screed
  has not been over is LUMPY and mottled; a struck one is a plane - that is the
  whole picture of the screed phase.

### 1a. The camera shots (`CameraRig`)

A shot is an eye, a look-at, and an ANCHOR — a marker on the site, so the same
numbers frame a panel at the kerb end and at the garage end.

| shot | what it is for |
|---|---|
| `WIDE` | the whole lot: house, drive, street, from 3 m up with a HORIZON - the sky a seventh of the frame, the lawn a third, the drive the subject. The opening and every payoff. |
| `PANEL` | close on ONE of the three places the hammer is worked on a panel. |
| `MACHINE` | low and close on the skid steer's push BLADE from the street side, riding with it down the drive: the board with the rubble piling against it, the machine behind. |
| `TIPPER` | from ABOVE and behind the tailgate, looking down, so the curtain of stone falls against the earth it is laying with the truck along the top of the frame. |
| `FORM` | from the near board's own lawn, low, looking ACROSS the drive, so the near board shows its FACE across the lower frame and the far one beyond; the kerb board and the strip get the same offsets face-on from the road and from inside the drive. |
| `STAKE` | close on a PAIR of pegs ALONG one board, from that board's lawn (mirrored for the far board; the kerb pair from the road's edge), the board carrying the bottom of the frame, and it steps down the board as each pair goes in. |
| `BARS` | on the group being laid - the four long bars, then each pair of cross bars - from the UNLAID side, close and a little above, so the pair being laid is the biggest thing in the picture and spans it, the chairs under it, the laid steel beyond. A waiting bar lies SKEWED beside its place on the grid, not up in the air. |
| `CHUTE` | from BESIDE the chute's line, above its rim and ahead of the pivot (2.2 m out, 3 m up), looking along it: the stream falls off the lip IN FRONT of the trough, into a lit crest of fresh concrete, while the truck is not drawn; it walks with the truck's creep along the road. |
| `PULL` | head height, looking DOWN the drive at the concrete's front with the street a strip along the top, anchored to `RakeView` which hops down the drive behind the front only while the finger is up: the concrete comes up the form toward the child as the rake pulls it, and the rake's handle runs off the bottom of the frame into the child's hands. |
| `SURFACE` | behind the screed board, low, anchored to `ScreedView` on the board's line: the board is DRAGGED down the drive by the finger, and the eye catches up with it only between strokes. |
| `HAND` | from where the person doing it STANDS - head height at the kerb end, looking up the drive - with the tool in the near corner of the picture. The hose. |
| `BROOM` | beside the BAY being brushed (one beat per concrete square between the joints), square to the drive: a stroke up and down the picture is a stroke across the drive, parallel to the joints, and the marks run the way the finger moved. |
| `JOINT` | on the joint's own middle, behind it down the drive, holding the whole width: the groover is PULLED across by the finger from the near form to the far one, the groove following the sled, the handle in the child's hands. |
| `STREET` | a vehicle arriving or leaving, fitted to the pair - and the child backing a truck in from the road (7d). |
| `PLATE` | the plate compactor: low, standing beyond the kerb edge of the BAY being packed, looking up the drive at the bays already done; still under the finger, it steps back to the next bay between beats. |
| `STRIP` | all three form boards and the kerb at once, from the road off the drive's left kerb corner, for the child stripping them after the cure. |
| `PAYOFF` | anchored to the slab, from the kerb corner 3.2 m up: the whole new drive with the car on it (over the first joint), the second joint, the garage and the house, in the evening light. The car's arrival is watched from `STREET` and the cut to `PAYOFF` comes as it turns in. |

**Where to tap is shown with GOLD RINGS IN THE WORLD** (`SpotRings`, Tree Crew's
`FellHint` made plural), and never with a flat mark drawn over the picture.

One place to press gets a ring with a fat arrow bobbing over it. Several live
places get a ring each and no arrows - three bites on a slab, four boards, ten
stakes - all lit at once, all tappable, in whatever order the child likes. Both
hold the same size on screen however far the camera is, which is what lets a
phase with ten places be framed wide enough to show all ten.

The flat gold WEDGE this replaced had three faults and the user could not even
tell what it was ("is it a finger pointing?"): its shape was a stubby arrow that
read as a hand, its point dipped INTO the thing it aimed at and back out, which
is a jab rather than pointing, and it re-chose which of twelve directions to come
from every frame - so the moment the cameras began to orbit it flicked from one
side of its target to the other. A mark that lives in the world can do none of
those things. Three phases have more than one live place at
once - three bites on a slab, four boards, ten stakes - and an arrow can only
point at one of them, so those phases light a ring on EVERY place still to be
done and the child takes them in whatever order they like. The rings hold the
same size on screen however far the camera is, which is what lets a phase with
ten places be framed wide enough to show all ten. While rings are up the arrow
stays off: two things pointing at two different places is worse than either.

**THE CAMERA WALKS WITH THE WORK.** A step's shot used to be chosen once, when
the step was entered - and the eighteen hammer bites, the ten stakes and the two
joints are each ONE step. So the eye stood on the first panel while the child
worked nine metres up the drive, and the thing they were hitting got smaller and
smaller (the user, 2026-09-12: "when you jackhammer the first section or 2 it
then moves to the background to slabs that are further away the camera needs to
move with it"). `JobRunner` re-asks for the step's shot after every beat now;
`CameraRig.go` returns at once when the shot and its anchor are unchanged, so
this costs nothing until the work moves, and eases the eye up the drive when it
does. It is what lets a many-place phase be framed CLOSE instead of wide enough
to hold every place at once.

**A phase with more places than one picture can hold is worked in GROUPS.** The
hammer's eighteen bites are three on a panel; the ten stakes are five pairs
across the form (`Driveway.stake_group`, cut by where they stand along the
drive, ordered garage-end first). The rings light the live group only, the shot
is anchored to that group, and both move on together. Ten rings in one picture
could only be held from up on the roof, and from there a 5 cm peg and a swung
sledge are a smudge: "the stakes are a wide shot so you don't get the hammer
feeling".

**Every shot but two used to ORBIT (off since the fourth playtest, `CameraRig.DRIFT`).** `CameraRig.define` takes a drift - degrees of
swing, seconds per swing, and a rise - which turns the eye slowly about the point
it is looking at while the look point stays put. The two exceptions are `CHUTE`
(the only beat steered with the pads, and the camera is what decides which way
"left" means) and `SURFACE` (the two beats worked by dragging a finger over the
slab: a moving camera moves the ground under the finger).

**The rule the shots are built on: anchor to the WORK, not to the TOOL.** A
shot's eye and look are both offsets from one anchor, so its basis never
changes — and anything rigidly attached to that anchor lands on the same pixels
forever. Anchoring the pour to the chute the child was steering froze the truck
on screen and slid the house past it instead, and both pads read backwards.
`CHUTE` is anchored to `PourView`, a point that follows the pour along the
drive's LENGTH only and never turns.

## 2. The job, beat by beat (`data/jobs/new_driveway.tres`)

The nine phases the user asked for, as rows of data. `kind` is TAP / HOLD /
BUTTON / AUTO; every HOLD runs only while the finger is down.

Twenty-five rows: the user's ten phases, the steel and the come-along
(2026-09-14: "missing rebar"), the beats that fetch each machine and send it
away, and since the plan's fifth session (2026-09-15) the child backing each
truck in, the plate compactor, the kerb board after the base, the cure and the
strip (section 7d). Eighty-three progress stops in all, weighted by the child's MINUTES rather than their taps (the improvement plan's 3.6, 2026-09-15: the holds and drags carry their share of the time, so the bar no longer reads three-quarters done at the mixer); a BUTTON or an AUTO beat is worth none,
because pressing a button is not a child's work.

| # | phase | kind | verb | tool | shot | stops |
|---|---|---|---|---|---|---|
| 1 | break the old drive | TAP x12 | `jack_spot` | jackhammer | `PANEL` | 12 |
|   | *three rings per slab, any order; the slab goes on the last of the three* | | | | | |
| 2 | call the skid steer | BUTTON | `call_skid` | — | `WIDE` | 0 |
| 3 | push the rubble out | HOLD x2 | `push_rubble` | — | `MACHINE` | 4 |
| 4 | it leaves | AUTO | `skid_leave` | — | `WIDE` | 0 |
| 5 | forms go in (the long boards and the strip) | TAP x3 | `form_set` | — | `FORM` | 3 |
| 6 | stakes driven (the long boards') | TAP x8 | `stake_drive` | sledge | `STAKE` | 8 |
|   | *a PAIR at a time, both ringed, either order; the eye steps down the drive* | | | | | |
| 7 | call the dump truck (it stops in the road) | BUTTON | `call_dump` | — | `WIDE` | 0 |
| 7b | back it in | HOLD | `back_dump` | — | `STREET` | 0 |
| 8 | lay the limestone base | HOLD | `tip_gravel` | — | `TIPPER` | 2 |
| 9 | it leaves | AUTO | `dump_leave` | — | `WIDE` | 0 |
| 9a | **pack the base** | DRAG (a clock) | `compact_base` | plate compactor | `PLATE` | 6 |
| 9b | close the form: the kerb board | TAP | `form_set` | — | `FORM` | 1 |
| 9c | and its two pegs | TAP x2 | `stake_drive` | sledge | `STAKE` | 2 |
| 9d | **the steel** | TAP x12 | `rebar_lay` | — | `BARS` | 12 |
|   | *four long bars onto their chairs, any order; then the cross bars in pairs down the drive* | | | | | |
| 10 | call the mixer (it stops in the road) | BUTTON | `call_mixer` | — | `WIDE` | 0 |
| 10b | back it to the kerb; the chute comes out | HOLD | `back_mixer` | — | `STREET` | 0 |
| 11 | **the pour** | HOLD | `pour_chute` | pads (all four) | `CHUTE` | 6 |
| 11b | **pull it up** | SCRUB | `rake_pull` | come-along | `PULL` | 8 |
| 12 | it leaves | AUTO | `mixer_leave` | — | `WIDE` | 0 |
| 13 | spray with water | SCRUB | `spray_water` | hose nozzle | `HAND` | 4 |
| 14 | drag the board down the drive | DRAG | `screed_pull` | screed board | `SURFACE` | 4 |
| 15 | pull the joints across | DRAG x2 | `joint_cut` | jointer | `JOINT` | 2 |
| 16 | broom finish, one bay at a time | DRAG x3 | `broom_finish` | broom | `BROOM` | 6 |
| 17 | it cures: the cones across the mouth, the light to evening | AUTO | `slab_cure` | — | `WIDE` | 0 |
| 18 | **strip the forms** | TAP x3 | `form_strip` | — | `STRIP` | 3 |

### 2b. The three shapes a beat can have (`SiteVerbs`)

| shape | what the finger does | which beats |
|---|---|---|
| `_bite` | ONE tap, and the work runs to the end on its own | the hammer's three bites per panel, one blow per stake |
| `_hold` | press and hold; the work flows while the finger is down and stands still when it lifts | the push, the tip, the screed, a joint |
| `_scrub` | DRAG it over the slab; work only happens where the finger is, and the beat ends when the child has been everywhere | the come-along, the hose, the broom, the plate compactor (on the base, 10 cm down) |

A bite is a decision about WHERE — which is why the hammer and the sledge stopped
being holds. What the child is being asked to get right there is the place, not
the duration, and eighteen taps that each land somewhere new beat six holds that
all land in the middle of a slab.

A scrub is the opposite of a button: holding still in one place cannot finish it,
the part that has not been done is plainly a different colour from the part that
has, and `Driveway.water_coverage()` / `broom_coverage()` are what the beat ends
on. Both were "a basic click" and both are the user's ninth playtest note.

### 2c. Getting the old drive out (phase 3)

**With a PUSH BLADE, not a bucket** (the user, 2026-09-14: "skid steer bucket
should be more like a bulldozer push blade"). A loader bucket scoops; what this
job asks of the machine is nine metres of shoving, and a dozer-blade attachment
is what a real crew bolts onto a skid steer for exactly that. `tools/make_blade.py`
builds it in the BUCKET PIN's own frame - a concave mouldboard 2.04 m wide, a
polished cutting edge put exactly where the bucket's lip was, ribs, end plates,
the push frame - and `Machine.fit_blade` hangs it off the `Bucket` pivot with
the bucket's own meshes hidden, so every lift the machine already knows about
carries the blade and `arm_down_deg` still lands it on the dirt with no
retuning. A blade does not dump: at the heap the load is shoved on and the
blade lifts clear.

Two passes, one per COLUMN of the old drive, each the whole nine metres:

1. the skid steer crawls up the drive to the garage, bucket carried high,
   **climbing over** the broken concrete — `Driveway.ride_y` is sampled at its
   nose and its tail, so it rides up onto the lumps and tips as it goes;
2. it turns round on the spot inside the garage, which is the one move nothing
   else in the fleet can make;
3. the child holds: nine metres of push, everything in that column in front of
   the blade;
4. it swings off the end of the drive and shoves the load onto the heap.

It used to take a BAND across the drive per pass, which meant reversing behind
each band in turn — through the rubble it was about to push, and into the garage,
which was a sealed GLB standing 23 cm on the driveway. A column is pushed from
one end in one pass and nothing is ever driven over or driven through.

**The garage is built out of boxes here** (`SiteMain._build_garage`) rather than
dropped in as a model, because the user asked for "an actual garage door that
could open so the skid steer had room to push the rocks" and the fleet's
`DetachedGarage` is one sealed mesh with a door painted on it. It has a floor,
three walls, a front wall with a hole in it, a gable roof, a bench and a shelf,
and a roller door that goes up when the skid steer is called and comes down
during the cure.

Payoff `park_on_it`: the forms are stripped, the light sweeps from afternoon to
evening (the cure — you do not drive on green concrete, and a child should not
be taught that you do), and the homeowner's car pulls in and parks on the new
drive.

### 2d. The steel (phase 5b)

Twelve bars, one tap each (`rebar_lay`), between the base and the mixer: the
four long bars onto their chairs first, all four ringed, any order; then the
cross bars in PAIRS down the drive from the garage end, the camera stepping with
them the way it does for the stakes. A bar waits in the air over its place while
its ring is lit and drops onto the chairs on the tap, the way a form board does;
it falls, clangs and bounces twice, and once a cross bar has settled its ties
pop onto the crossings one after another down it (7c).

What the phase teaches is the CHAIRS: the bars sit up off the base so they end
in the middle of the slab, not on the ground. Sparser than a real 45 cm grid on
purpose - twelve taps is a phase, forty is a chore, and a four-year-old cannot
see a 16 mm bar from a metre away anyway.

And it changes the pour (2a): once the steel is down nothing with wheels goes
on the pad.

### 2a. The chute (phase 6) is the centrepiece

**The mixer stays on the road** (2026-09-14). It reverses along the street,
swings its tail to the kerb and stops with its rearmost tyre a hand's width
past the kerb line - `SiteMain.MIXER_STAND_Z`, measured off the model's THIRD
axle, which the fleet's contract never listed and which is 3.16 m behind the
origin with its tyre - and it never puts a wheel on the steel. From there the
main chute reaches nothing, so an EXTENSION CHUTE is clipped on
(`Machine.fit_chute_extension`, 1.4 m at ten degrees, built in code off the
spout and hung off the swing pivot), which is what a real mixer carries for
exactly this. With it the pour lands 5.9 m behind the truck: the kerb end of
the form, four rows of cells. LEFT and RIGHT swing the chute across the form
(46 degrees each way with the extension on, or it pours on the lawn); UP and
DOWN creep the truck a couple of metres along the road, which is what covers
the length the chute can reach. The beat ends when that band is `band_done`
full - not `pour_done`, because concrete keeps creeping out of the band into the
row beyond as fast as the chute fills it.

**Then the come-along** (`rake_pull`, DESIGN 2b's `_scrub`): the chute keeps
running into the kerb end on its own, sweeping slowly, and the child DRAGS the
rake over the slab. Concrete comes to the rake from the fuller cells within a
stroke's reach toward the kerb (`Driveway.rake_to`, `rake_reach` cells), a cell
at a time so it visibly flows rather than appearing under the blade, and never
from further - so the concrete has to be brought up the form a stroke at a time
from where the chute leaves it, which is how a crew whose truck cannot get onto
the slab does it: they pull the mud. Dragging nine metres from the concrete
pulls nothing; the idle hint stands at the FRONT of the concrete
(`rake_front_world`), not the emptiest corner of the form. The beat ends when
every cell is up to `pour_done`. This is the "mini game kind of like the water
and broom lines where you have to fill in all the drive way" the user asked
for. Seen from the garage door (`PULL`) so the concrete comes toward the child.

It used to reverse the length of the drive over the base and pull forward as it
poured. That is how it is done when there is no steel; with rebar on chairs it
is the one thing a groundworker would never do.

The user asked for this one to take longer and to be properly driven. It is the
only beat steered with the four pads rather than aimed with a finger:

* The drum turns and concrete pours **continuously** while the beat runs; the
  child's job is to AIM it, not to keep it running.
* **Left / right swing the chute** across the width of the form.
* **Up / down creep the TRUCK** along the road, which is what covers the
  length the chute can reach; the rake covers the rest.
* **The truck is not drawn, and the camera stands at the back of the chute.**
  `Machine.show_only(["Chute"])` leaves the chute, its fold and its spout hanging
  in the air exactly where the truck really holds them; the eye sits just behind
  and above the chute's own head, looking along it up the drive, so the truck -
  4.5 m further toward the street - is behind the camera and there is nothing
  missing to notice. The pour's camera point is fed the TRUCK's position, never
  the live pour point: swinging the chute pulls the stream 0.87 m nearer the
  truck, and a camera that followed that lurched every time a side pad was
  touched. This is the user's own idea:
  "detach the chute from the truck and move the camera right up to it, so the
  player feels like they are pouring the cement and we don't have the truck in
  the way visually". Nothing is duplicated and nothing teleports — the truck is
  still there, still creeping under the child's thumb, still rolling its wheels
  and still standing on the base, and it is drawn again before it drives out.
* Concrete lands where `ChutePour` really points. The cell under the spout
  fills and its neighbours take the spill, so a swept chute lays a band; what
  heaps above grade runs downhill (`Driveway._settle`), so pouring into one spot
  still fills the form, just slowly.
* The beat ends when `pour_done` of the form is up to grade. There is no way to
  fail: an unfilled corner simply waits, and the arrow hangs over the emptiest
  cell once the child has been still for `chute_hint_delay` seconds.
* **It is a FILLING GAME, not a bath.** `Driveway.SLUMP` is a fifth of the slab's
  depth and `SLUMP_RATE` is slow, so concrete creeps into the hollow beside it
  but does not find its own level across nine metres: the child has to take the
  chute to each part of the form, the same job the hose and the broom ask for.
  What cannot be cut is `pour_spread` - the swing only reaches 2.39 m of the
  3.60 m width, so a narrower stream locks the outer columns out and the pour
  stalls one cell short, for ever.

**Why the truck and not the chute reaches up the drive.** `scenes/dev/machine_probe.tscn`
measured the fleet's `ConcreteTruck`: swinging the chute moves the pour point
3.1 m across (against a 3.6 m width, and `pour_spread` covers the rest), but
**folding it moves that point 0.11 m** — the spout is already as far out as that
arm reaches. So the fold is deployment only (it "comes out" when the truck
arrives) and the length of the drive belongs to the truck, which is also how a
real residential pour works: the mixer reverses the length of the drive over the
new base and pulls forward as it fills.

**The truck is free to move between the two ends of the form, and that is the
only limit.** A rule stopping it reversing onto concrete it had already laid was
built and then cut: see `docs/critic_log.md` round 0. It is a real thing a real
driver avoids, but it is not what the user asked for, it cost three rounds of
debugging, and in the end it was the reason the apron half of the drive could
never be poured. If it comes back it should be a visual consequence — tyre marks
in a slab the child then has to trowel out — and not a control the child cannot
see the edges of.

## 3. What is shared with Car Garage, and what is this project's own

Copied and kept in step by hand (the two projects are separate repos, as Car
Garage and Tree Crew are): `job_def.gd`, `job_step.gd`, `job_runner.gd`,
`camera_rig.gd`, `camera_shake.gd`, `toy_hud.gd`, `pad.gd`, `brand.gd`,
`hand_tool.gd`, `loose_part.gd`, `sfx.gd`, `settings.gd`, `save_game.gd`,
`tools/shot.gd`. `job_runner.gd` is the one with real edits: the car-specific
target lookups (nuts, hubs, bay parts) are replaced by the site's own
(`Driveway` panels and cells, the machines), and everything that made the runner
worth keeping — the queued tap, the carried hold, partial progress, the muted
arrow — is untouched.

This project's own: `site_main.gd` (the level), `site_verbs.gd` (the ten verbs),
`site_hud.gd` (arrow + pads + bar), `driveway.gd` (the slab, rubble, gravel,
concrete grid), `machine.gd` (a fleet GLB driven by its named nodes),
`site_config.gd` (every feel number).

## 4. Feel numbers live in data

`data/site_config.tres` — nothing in `scripts/site_*.gd` may hold a feel number
of its own. Edit the resource, not the code. (The trap from Car Garage: a
`.tres` stores its own values, so changing a script default does nothing until
the resource is edited too.)


## 5. The playtest of 2026-09-12: closer, and with its own noise

Five notes, and four of them are the same note: **the child is watching the job
from across the street.** The fifth is the last thing on the lot that still
floated.

> "I don't mean camera just move back and forth - I mean when you jackhammer the
> first section or 2 it then moves to the background to slabs that are further
> away the camera needs to move with it. We have too many camera shots that are
> wide shots, you don't get a good feeling of doing the job. Spraying water for
> example it looks tiny instead of having the camera behind the water sprayer
> like you are the one spraying. Similar the stakes are a wide shot so you don't
> get the hammer feeling."
> "The dump truck needs a pour animation."
> "The chute concrete mini game still doesn't feel right ... imagine the camera
> at the eye level of the man holding the chute and the chute angled in a way
> where he controls the pour then the player has to pour it in the forms to
> continue on."
> "Correct all the sounds."
> "Why does the car at the end just float and turn in?"

### 5a. The camera follows the work (section 1a)

Three changes, in the order they matter: the runner re-asks for the shot after
every beat so the eye moves with the work; a phase with more live places than
one close picture can hold is worked in GROUPS, with the rings on the live group
only; and the two shots that were framed to hold everything at once (`STAKE`,
and the hose and broom's `SURFACE`) came in.

`HAND` is the new one and it is the user's own picture: the eye is where the
person doing it stands - 2.6 m up at the kerb end, looking up the drive - and the
HOSE IS IN THE CHILD'S HANDS. The nozzle rides a fixed arm's length in front of
the eye (`SiteMain.hand_hold`, `SiteConfig.hose_hold`), down and to the right the
way a hose is held, and only its AIM follows the finger; the water is thrown as
far as the finger is aiming (`HandTool.set_spray_reach`) instead of dribbling out
at the camera. It is SPRAY and only spray - a fan of drops on their own
ballistics. There used to be a solid rod of unshaded cylinders drawn down the
middle of it, and it read as a fire hose; it came out at the playtest of
2026-09-16 ("I just want the spray"), and the drop count doubled so the fan
carries the throw by itself. The broom stays on the slab under the finger - a broom is pushed, not
sprayed - and only the camera comes down.

Not lower than 2.6 m: `work_point` drops the finger onto the slab's plane, and
near the horizon a pixel is worth metres. The two dragged beats still do not
orbit, for the reason they never did.

### 5b. The tipper pours (`TIPPER`)

The bed always tipped and the tailgate always opened; what came out of it was
the dust puff with a different colour - forty 5 cm quads thrown UPWARD out of a
point. A tipper pours a CURTAIN: stone leaves the whole width of the tailgate at
once and keeps falling while the bed is up. So the emitter is a box as wide as
the lip, turned with the truck, throwing 220 stones down and back under real
gravity - and the shot stands 4.4 m behind the tailgate looking back at it,
where `MACHINE` (shared with the skid steer's push, which has to hold nine
metres of rubble) stood nine and a half off.

### 5c. The chute at eye level

`CHUTE` was a 2.9 m crane shot looking down on the chute from behind: the pour
read as a machine part hanging in the air. It is 1.74 m now - a standing adult's
eye - two metres behind the chute's head, looking down its length at the form it
is filling. Everything else about the beat is unchanged: the pads swing the
chute and creep the truck, the concrete lands where the spout really points, and
the beat ends when the form is up to grade.

### 5d. The sounds are the site's own (`docs/sfx.md`)

Twelve clips, generated with ElevenLabs, replacing the car-garage library every
tool was borrowing: a breaker, concrete breaking up, limestone pouring, wet
concrete on steel, a diesel idle, a hydraulic ram, a sledge on a stake, a screed
board, a broom, a hose, a mixer drum and rubble being shoved. The breaker also
changed SHAPE: it was a one-shot fired on every blow of a 13-per-second hammer -
thirteen clips a second landing on top of each other - and it is one rattling
loop that runs while the bite runs.

### 5e. The car drives in

`_park_car` was a straight slide up the street lerped into a straight slide up
the drive, with the yaw lerped 90 -> 180 across the middle of it and the wheels
dead still. The machines were fixed for this in the first playtest; the
homeowner's car was the one thing left doing it. It is a `Machine` now like the
other three (`Machine.model_path` lets one load a GLB out of the vehicles
folder), so it drives `drive_route`'s rounded corner nose-first, rolls its wheels
by the distance they really cover, and is seated on whatever is under it - the
road, then the kerb, then the new slab.


## 6. The fourth playtest of 2026-09-14: the child's own hands, and the site's own machines

Ten notes, after fifteen critic rounds (the loop was stopped at round 15 on the
user's word; `docs/critic_log.md` has every round). What each one changed:

1. **"Stop the camera from swaying constantly."** Every shot's slow orbit is
   OFF (`CameraRig.DRIFT` false). The drift numbers stay on the shots for the
   record; nothing reads them.
2. **"Video flashing where the form board meets the garage."** The expansion
   strip was buried in the garage floor with its front face on the floor's
   front plane; it stands ON the pad now, 6 mm proud, flush against the
   floor. The garage's walls and jambs stand on the floor's top instead of 2
   cm into it, and the kerb crossing starts behind the kerb board instead of
   around it. (No two same-facing faces share a plane at either end.)
3. **"Vehicles too loud."** `Sfx.group_gain_db` trims the vehicle groups
   (diesel idle, the drum, the car's idle, the pull-up, the hydraulics, the
   push and the gravel) 4-9 dB under the tools; the dead `idle_db` knob is
   gone.
4. **"Pick a camera angle that isn't blocked when you dump rock."** `TIPPER`
   stands at the truck's side, rear quarter, high enough to see over the
   form: the bed up, the tailgate, the stone falling onto the base.
5. **"Improve the bottom-left icons - low poly like the key in Garage Crew."**
   The call button shows the machine itself: `PropIcon` (Car Garage's) stands
   the fleet GLB in the button - the skid steer wearing its push blade, the
   tipper with its bed up, the mixer with its chute out (`MachineIcons`).
   The drawn `TruckGlyph` is only the fallback for a build without models.
6. **"Add idle white arrows."** Car Garage's white idle arrow: after
   `hint_delay` (4 s) of nothing, a white wedge with a dark rim stands over
   the thing to work and MIMES it - a tap comes in and out, a hold comes in
   and stays, a drag slides across - and goes the moment the child does
   anything (a press, a release, a drag of 6 px, a pad, GO). The gold ring is
   still the WHERE and stays under it; the pointer's own bobbing arrow
   stands aside while the white one is up. `SiteHud.hint_tick` keeps the
   clock, `SiteMain._hint_kind` says what to mime.
7. **"Improve drag board across touch."** The screed is a DRAG: the board
   follows the finger down the drive, never back and no faster than a person
   walks it (`screed_drag_speed`); the finger's sideways wander is the saw;
   the eye catches up with the board only between strokes (or under a world
   cursor - a stick, a test), so the ground never moves under a finger.
8. **"You should pull to make the joint lines, not just hold down."** The
   joint is a DRAG across: the groover's sled follows the finger from the
   near form to the far one and the groove follows the sled. `JOINT` stands
   still on the joint's own middle, behind it down the drive, holding the
   whole width.
9. **"Broom finish: do it 3 times, once per concrete square, camera lined up
   on the side so you can have a chance at trying to get them parallel with
   the joint lines."** Three beats, one per bay between the joints; the broom
   only brushes the bay being worked and lifts over the joint; `BROOM` stands
   beside that bay square to the drive, so a stroke up and down the picture
   is a stroke across the drive; the marks run the way the finger moved.
10. **"Final shot no good, need a better shot zoomed out to see finished work
    like we had previously."** `PAYOFF` is pulled back to the kerb corner: the
    whole new drive, the car on it over the first joint, the second joint,
    the garage and the house; the arrival is watched from `STREET` first.


## 7. The improvement plan's first session (2026-09-15)

`docs/IMPROVEMENT_PLAN.md` is the ten-lens review that followed the fourth
playtest; its Tier 0 is built (the log's last section has the detail). What it
adds to the contract:

- **The house is off the screen while a job runs** and comes back beside NEXT
  in the payoff. When the title screen is ported it becomes a press-and-HOLD:
  any control that throws work away is a hold, never a tap.
- **One finger owns the beat.** The first finger whose press is accepted keeps
  the work until it lifts; a palm or a thumb on the glass neither steals a
  drag nor ends a hold. The app losing focus lets go of everything.
- **A kept tap keeps its ring.** A tap that lands while a bite runs is spent
  on the ring it landed on, or dropped if that ring is gone or the step has
  moved on; never on the first open spot.
- **The white wedge is a target.** A press anywhere on its body is a press on
  what it points at; a live ring in reach of the finger still wins.
- **The truck never teleports.** It hides only once the eye has arrived at the
  chute, and fades back in over the eye's ease out to the wide.
- **The sound class plays no AudioStreamGenerator** (Car Garage's crash class):
  the fallback synth is a WAV per sound.
- Two smoke rules: waits for a wall-clock rule are `create_timer` seconds,
  never frame counts; and the pour's idle hint is checked while the band is
  still short, because the round-12 rule rightly shows nothing once the parked
  chute has brought every cell past half. `scenes/dev/pour_probe.tscn` is the
  thirty-second stand-in for the smoke on that beat.

### 7a. The second session (2026-09-15): every touch answered

Tier 1 of the plan and 2.1, 2.4, 2.5 (the log's last section has the
measurements). What it adds to the contract:

- **Every accepted tap is heard in the frame it lands** (the tool's own
  swing, via `JobStep.sound`), **every miss is heard** (one `pop`, never a
  buzzer) **and answered by the nearest right place throbbing once**; a miss
  does not restart the white mime's clock, it hurries it.
- **The ring pressed snaps out; the others stay lit.**
- **A blow the child caused moves the picture**, and the breaker rattles it
  for as long as the bit runs; the shake numbers live in `SiteConfig`.
- **The panel bursts** when it lets go; nothing turns into rubble in a cut.
- **Every phase the bar counts ends on the one `done` note, and the picture
  holds** (`phase_hold`) on the finished thing with the tool put away; each
  finishing verb finishes its own material first. The last phase's done is
  the tada.
- **A held machine's engine leans into the work** under the finger.
- **A machine answers a tap on it with its horn** while it arrives or leaves;
  nothing else does, and GO does not kick while the machine it called is on
  its way.
- **UP means up the picture** on the pour; the mixer parks mid-creep so both
  pads work from the first touch; the pour has its white mime, on the pad
  that would take the concrete to the emptiest cell.
- **The truck supplies the rake faster than the rake draws** (`rake_pour_time`).
- **A dragged tool is grabbed once at the press and walks** (`screed_drag_speed`,
  `joint_drag_speed`); a press on the slab in front of it is a miss, answered
  at once.

### 7b. The third session (2026-09-15): pacing and the story of the job

Tier 3 of the plan (the log has the measurements). What it adds to the
contract:

- **A job opens and closes on the same wide picture.** The opening holds on
  the wide (`opening_hold`) or until the first touch, then eases down to the
  first slab (`opening_ease`).
- **A machine's exit is a two-second look, never a beat** (`leave_look`): the
  drive-out runs on in the background under the next beat, and the next
  machine is only ever called once the last is gone.
- **The payoff, in this order:** the last stroke held; tada; the cones across
  the mouth of the drive; the light to evening with the song down and the HUD
  gone; the boards off; the cut to the street with the crew's kit cleared;
  the car in; its own voice, twice, when it stops; NEXT alone.
- **Nothing on the site fades.** Things are carried off at a cut.
- **A truck backing in beeps** (`reversebeep`) and stops with a hiss of its
  brakes; the skid steer keeps its clunk. No boing anywhere.
- **The bar measures the child's minutes, not their taps:** seventy-four
  stops, the holds and drags carrying their share of the time.
- **The HUD steps back while the finger works** (`chrome_working`) and is gone
  for the payoff.
- The user closed decision 1: the pour stays on the pads.

From the session's verification pass (the log has the twelve findings):

- **The cones guard the slab from in FRONT of it:** on the crossing at
  `Driveway.Z_KERB + 0.30`, at grade, never on the concrete; while the crew
  works they stand ON the footway (`FOOTWAY_TOP`, 9.5 cm), not in it.
- **The cut to the street is a cut** (`CameraRig.snap`), and the kit goes in
  that frame.
- **The heap never comes back** (`Driveway.hide_rubble` is monotonic).
- **A finger's reach is 0.22 of the short side on the close shots and never
  more than `tap_reach_m` 0.55 m of the world** (floored at `tap_reach_min`):
  on the wide, a tap on one slab cannot work a ring on another.
- **The payoff answers a finger too:** the car toots when tapped, and a tap
  off NEXT is a miss like any other, with NEXT kicking.
- **The bar is seen full at the tada** before the HUD goes for the cure; a
  miss does not dim it.
- **Two toots never overlap** (the gap is at least the clip's length) and
  NEXT waits for the second to sound out.

### 7c. The fourth session (2026-09-15): show the thing

Tier 4 of the plan, 4.1 to 4.7 (the log has the measurements). What it adds to
the contract:

- **The fault has a shape before the first tap.** Every old slab has weeds in
  its old cracks (`Driveway.WEEDS_PER_PANEL`, green a value step under the
  slab), never where the wide draws a lit ring; the first slab has settled a
  step down along the centre seam (`SETTLED_PANEL`, `SETTLE_STEP`), and a bite
  sinks it from there. Weeds and step go with the panel.
- **A form stake is sawn timber with a survey-pink cap** (`STAKE_TIMBER`,
  `STAKE_PINK`, `STAKE_CAP`): the cap is the driven stub, the ring sits on it,
  and the sledge stands WOUND UP over it from the moment the row opens, swings
  down onto it on the tap and rides it down. Pink is the one
  hue nothing else on the site has. The pegs stand waiting from the moment the
  phase opens, and are drawn up out of the ground before the boards at the
  payoff.
- **A held tool is connected to the bottom of the picture** - the hose too
  (`hose_trail`, `SiteMain.hold_hose`, one helper for play and pose). A tool
  still held with its hose stays in the hands through the phase's hold.
- **Every hand tool worked on the slab carries one saturated colour at a value
  step under the slab:** the broom's blue, the groover's `ToolOrange` with its
  steel only as the bottom edge.
- **A machine's beacon turns while it arrives, works and leaves**
  (`Machine.set_beacon_on`, `beacon_hz`), dark when parked; a tap winks it on
  top of that. The lens glows on its own material copy, never the shared
  imported one, and its light hangs under it, so it goes when the body does.
- **The long bars are seen from low, square up the drive** (group 0's own eye,
  (0, 0.62, 2.4) looking (0, -0.16, -1.0)), where a chair is a leg. A waiting
  long bar is barely lifted (`bar_long_lift`) and swings its kerb end toward
  the middle line, so from that eye no bar lies over a form board.
- **A bar's landing is one gravity** (`Driveway.bar_landing`): a free fall
  onto the chairs, a clang, two bounces - a third of the height the second time,
  in proportion to how high it waited - and then, settled, a cross bar's ties
  pop on in turn down it, each a `click` a step higher.
- **The render harness takes no input** (`shot.gd`), and `--eye/--look` write an
  anchor's own offsets when it carries them.

### 7d. The fifth session (2026-09-15): the user's decisions

The user's answers to decisions 2 and 4-6 of the plan, built: 1.8's held
arrival, 5.1, 5.2 and 5.3 (the log has the measurements). Decision 2 kept the
word "YAY!". What it adds to the contract:

- **A truck's arrival is two legs.** It comes down the street on its own and
  STOPS in the road, tail to the drive, engine ticking over, beacon turning, a
  gold ring on its tail - and waits. **Backing it in is the child's HOLD**
  (`back_dump`, `back_mixer`): a press on the truck (its box, grown by a finger
  but never more than `tap_reach_m`), and it backs in along its old route only
  while the finger is down, gathering way and coming to rest over `back_ramp`
  (a tap's `hold_burst` is counted from the press, so a real hold stops on the
  lift), beeping only while it moves; a press elsewhere is a miss. A finger
  that pressed the truck as it came down the street - by the same rule - and
  stayed down backs it in the moment it stops. A re-press takes the ring off
  the truck; the tip's ring is up the frame the truck stops. The skid steer still drives itself in forwards. The machine
  walks the path by `Machine.set_path` / `place_on_path`, never by the clock.
- **A finger still down when a truck stops does not start its work:** the back
  rows' targets are `Back:`, not `Machine:`, so the tip and the pour want their
  own press.
- **The kerb board and its two pegs go in after the base** (decision 5), from
  the road. Which boards and pegs are live is STATE (`Driveway.form_live`,
  `stake_live`: the kerb board once the base is packed, a peg once its board is
  in); the job repeats `form_set` and `stake_drive` with counts 3/8 then 1/2.
  The boards wait in the air over their places from the moment their row opens,
  and a beat never re-hangs a board already in.
- **The crossing starts behind the kerb board's trench**, so its pegs stand in
  earth; the cones' cure spot moved out with it (`SiteMain.CONE_MOUTH_OUT`).
- **The base is packed with a plate compactor** (decision 6): a DRAG over the
  WHOLE base, ended by a CLOCK - `SiteConfig.pack_seconds`, about five and a
  half seconds of real work, anywhere on it, by any path - and then every cell
  the child never reached goes down with the ones they did, as the plate lifts.
  It was one beat per bay ended by coverage until the playtest of 2026-09-16,
  where it stopped the user dead: the plate's footprint is a plus of five cells
  out of a bay's twenty-four, so `scrub_done` meant visiting seventeen cell
  centres in each of three bays, and nothing on the screen said so. A phase a
  competent adult cannot finish is a phase a four-year-old will never finish.
  Seconds are a promise a three-year-old can keep. Only frames where the finger
  is really on the plate count, so a rest, a miss or an open settings panel buys
  nothing. The eye is low behind the plate looking up the drive and walking after
  it only between strokes (`PlateView`). The plate moves only under a finger ON
  it - one rule for the press and the grab (`SiteMain.plate_under`: on the drawn
  machine, or within its half-size plus `tap_reach_m` on the base), held with
  the offset it was taken at, so a still finger is a still plate - no faster
  than `plate_speed`, inside the forms and its bay. It packs every cell within
  `plate_radius` - standing still it packs a plus sign and nothing more - and a
  packed cell's stones lie flat and its bed goes a luma step paler
  (`GRAVEL_PACKED`, +14%). The picture rattles and the `platerattle` loop runs
  only while it packs. At the end the packed colour is baked into the base and
  the overlay goes, and the plate goes back to the grass upright with the rest
  of the kit, whole. Its handle runs off the bottom of the picture, aimed at the
  PLATE pose, never at the live, rattling camera.
- **The cure is a beat, and the child strips the forms after it** (5.3): the
  cones across the mouth and the light to evening (`slab_cure`), then three
  taps, one board each in any order, a tap anywhere on a board counting. Each
  board's pegs are drawn, the board is prised OUT about its bottom outside edge
  and lifted - the slab's clean edge is drawn where it stood - then carried
  over the slab to the crew's pile on the right lawn and laid flat with its pegs
  on it (a 9 m board has no room beside its own edge: the garage and the
  footway are 7.9 m apart), and only its own trench is backfilled. Nothing
  fades; the boards go at the cut to the street with the kit, and the broom
  lies on the grass where it went back until then.
- **The payoff, in this order, superseding 7b's:** the last board held; tada and
  YAY! with the bar full, on the wide (`payoff_look`); the HUD gone; the cut to
  the street with the kit and the boards cleared; the car in; its own voice,
  twice; NEXT alone. The broom gets the ordinary done note.
- **Stages and `--step` name verbs, never numbers** (`SiteMain.STAGE_STEP`,
  `JobDef.index_of(verb, nth)`, `--step=pour_chute` or `--step=form_set:2`).
  New stages: `tipped` (the plate), `packed` (the kerb board), `kerbed` (its
  pegs), `cured` (the strip); `done` is after the strip now.

### 7e. The sixth session (2026-09-15): a different driveway, and a job that survives

Tier 6's first two items, 6.1 and 6.2 (the log has the measurements). What
they add to the contract:

- **One seed per visit** (`SiteMain.play_seed`), and the look drawn from it
  by a pure table (`SiteLook.for_seed`, each field its own generator): the
  homeowner's car - the Hatchback, Pickup and Van repainted from Car Garage's
  own paints (less the Van's cream, which is the garage's colour), the
  PoliceCar, Taxi and IceCreamVan as their liveries - and that car's own voice;
  the house's wall paint (`Equip_Trim`) and the garage's walls, one swatch of
  four for both (low chroma and leaning cool, since the payoff's evening light
  warms them: no pink, no tool orange, no ring gold), never one the car does
  not stand out from (`SiteLook.stands_out`: a luma step or a saturated car on
  a pale wall - the white police car and ice-cream van never get the cream
  garage); and the
  old drive's crack, stain and weed generators (`Driveway.crack_base`, from a
  list every entry of which the smoke builds and holds to the legacy drive's
  checks). **Never drawn:** the job, its order, the panel count, the spots, the
  settled slab, the chunks, the stones, the lot. The vehicles are Car Garage's
  `tools/make_vehicles.py` builds (Equip_* materials, no textures), copied in
  with their own imports.
- **Seed 0 is the legacy lot**, to the number, and every harness that names no
  seed plays it: every picture taken before this session is still the same
  picture. `--seed=N` pins a visit; `--car=` (with `--paint=K`, that car's K-th
  paint), `--house=` and `--cracks=` pin one field for a critic's frame.
- **Where the seed comes from, in order:** the one NEXT drew (a different car,
  house and cracks from the visit before, `SiteLook.draw_fresh`); the save's
  (a resumed job keeps its drive under its stakes); `--seed`; 0 for any other
  harness; a fresh draw of 1..9999 - never the clock, and never the
  generator's own clock-seeded state. It is resolved in `SiteMain._enter_tree`:
  the driveway child builds its panels in its own `_ready`, before the level's.
- **A car parks by its nose** (`Driveway.park_spot(nose_m)`: the nose 0.385 m
  off the garage, the hatchback's old gap), so the 5.45 m pickup stops short of
  the shut door. Only cars that fit between the garage and the kerb are
  homeowners'.
- **A recolour is a copy in the surface's override**, matched by name prefix,
  never a write into the imported material: that material is cached across NEXT.
- **The job survives the app closing** (6.2). The save
  (`user://build_crew_save.json`) is `{version, job, rows, verb, nth, done,
  places, seed}` and nothing about when. From the first beat on it is written
  every time a step is entered or a beat lands (`JobRunner.place_changed` -
  never `beat_done`, which fires mid-hold and never for the rows the bar does
  not count), to a `.part` that is read back whole before it is renamed over
  the old save (a write that fails keeps the old one); it is deleted when the
  job is done and on NEXT.
- **A resume** (`SiteMain.resume_point`, `resume`) opens the row the child was
  on with the places they had done. A save for another job, a job with a
  different number of rows, a row the job has not got, or no seed, is a fresh
  driveway. A row whose places were all done, or a row that plays itself (a
  machine leaving, the cure), resumes at the next row the child works; past the
  last row, a fresh driveway. The world is posed as PLAY leaves it when that
  row opens (`pose(..., play = true)`: none of the picture's tricks); the places
  a child takes in any order - the hammer's spots, boards, pegs, bars, stripped
  boards - are restored by name wherever each is still a legal pick, and the
  canonical ones otherwise; mid-row, the hammer or the sledge stands over the
  next place as its verb poses it. **A HOLD resumes at its own start.** It opens
  on the WIDE, as a fresh job does, except where a wide is wrong: the pour and
  the come-along (the truck undrawn), every drag (a press during the eye's swoop
  would move the work under a still finger) and the back-ins (the truck waits
  off the wide's picture) open on their own shots.
- **A harness never touches the child's save.** A run with `shot_args` reads and
  writes one only if it pointed `SaveGame.path_override` at a scratch file; a
  posed run never does; `shot.gd` and `pour_probe` switch saving off, and
  `SaveGame.clear()` does nothing while it is off.
- **`--done` poses:** every earlier `--done` picture poses the same canonical
  places it did; the jackhammer and the push, which had no `--done` pose, have
  one now; `--places=3,1` names which.
- **Not restored, on purpose:** the held beats' partial work (a half-poured band,
  a half-packed bay), where the plate stood in its bay, where the jointer and
  the broom lay between beats, the child's own broom strokes (redrawn by rule),
  and the pour's settled fill (the posed one).

### 7f. The sixth session, part two (2026-09-15): the title row

Tier 6's 6.3, the deferred port. What it adds to the contract:

- **The app opens on `scenes/main.tscn`,** a `TitleMain` with one `StartMenu`
  over it. NEXT and the house come back here (`SiteMain.TITLE_SCENE`); the
  house is still off the screen until a job is finished (0.1 owns the button).
- **The backdrop is the lot itself.** `scenes/site.tscn` is instanced as the
  title's first child with `dress_only` set BEFORE `add_child` - a `SiteMain`
  that poses itself and then stands there: no HUD, no rings, no tools, no
  pads (a hidden pad still eats the touch over it), no music of its own, no
  loops, no beats, no `_process` and no input. It READS the save, which is the
  whole point of `dress_from_save` - but `saves_on` is false for it, so it can
  never write one, and it takes neither of the two Engine metas. Which picture it poses is the screen's whole
  honesty:
  - nothing saved: a freshly drawn visit's CRACKED drive, on the WIDE. It says
    what the job is and promises no reward that has not been earned.
  - a job the child left: their own drive, posed from the save
    (`dress_from_save` -> `resume_point`, then the row, the places and
    `play = true`), so the title can never offer to carry on a job the level
    would refuse.
  - a job just finished: the drive with the car on it, in the payoff's evening
    light (`SiteMain.LAST_SEED_META`, left by NEXT and taken once). The reward
    is still standing behind the next choice.
  There is no `Camera3D` and no `Sfx` in `main.tscn`: the backdrop brings both,
  and Godot makes the FIRST camera to enter the world current whatever its
  `current` says.
- **One disc per job, from `data/jobs/jobs.json`** (a bare array of stems; a
  key with no `.tres` behind it is dropped, never seated). The picture is that
  job's own machine - the driveway's is `MachineIcons.spec("skid")` itself, the
  skid steer wearing its push blade, so the title and the call button can never
  drift apart. 250 px, on the left lawn (`ROW_ANCHOR` 0.70, `ROW_X` 0.30), never
  over the drive it is a picture of. The file holds no name, price, star,
  difficulty or "done" flag: there is nothing to buy, earn or unlock here.
- **The tap is always the safe thing.** A press on a job's disc starts that
  drive, or carries on the one the child left. THROWING A DRIVE AWAY IS A
  SEPARATE CONTROL: a smaller orange disc with the jackhammer on it, in the
  bottom-RIGHT corner (bottom-left is GO's and NEXT's, and that corner keeps
  meaning "go on with it"), shown only when there is something to throw away,
  and HELD for `StartMenu.HOLD_TIME` 0.9 s with a cream ring filling round it.
  Let go early - or slide the finger off the disc - and nothing happens. In this game holding is how every piece of
  work is done, so a hold that destroys work never goes on the big disc.
- **What the press leaves behind:** `SiteMain.PICK_META` (the job, and whether
  it is a carry-on) and, for a new drive, `NEXT_SEED_META`. Both are process
  memory, never a file. The lot behind the disc IS the lot you get - except
  when that lot is a reward already earned or a drive just thrown away, when
  the next one is drawn to differ from it in car, house and cracks.
- **Nothing fades and there are no words.** The menu is whole in the frame the
  job arrives; the cut is the event, `TitleMain.CUT_DELAY` after the press, so
  the disc's kick is seen and its sound heard before the scene (and the `Sfx`
  playing it) goes. A seat press is `crank` (a diesel turning
  over), the completed hold is `breaker`, a miss or an early release is `pop`.
  The song restarts at each cut in both directions: keeping one alive across a
  scene change needs an autoload this project does not have.
- **A harness drives the row through the same doors:** with the title as a
  child of a probe, `current_scene != self` and a press answers with
  `job_requested(job, carry_on)` and writes NO meta.
  `scenes/dev/title_probe.tscn` holds the row to all of the above;
  `scenes/dev/switch_probe.tscn` makes the real trip (title, seat, job, NEXT,
  title, carry on) through `change_scene_to_file`, which no other harness can
  reach - and is kept out of the smoke, because repeated scene changes crash
  Godot 4.7.2 about one run in three.

### 7g. The seventh session (2026-09-16): the chrome a parent reaches for

Item 6.4's parts 1, 2, 3, 5 and 7 (part 4, the export presets and icons, is
what remains; part 6, the name, is answered - **Build Crew**). What they add to
the contract:

- **THE WORDS RULE, stated once.** For the CHILD: none, ever, with ONE kept
  exception - the "YAY!" at the end of the job (decision 2, answered
  2026-09-15; DESIGN 7d, `site_main.gd`'s `hud.flash`, and a smoke check that
  pins the string). The title row and the job itself carry no word at all.
  Beyond that exception, words are allowed in exactly two places, both for the
  adult: inside a control a child cannot operate (the parental gate's sum and
  its prose) and on a label addressed to whoever opened a panel a child has no
  reason to open (the panel's one string, "Privacy Policy"). **The typeface
  sorts the PROSE**: every sentence an adult is meant to read - the gate's hint,
  the privacy link - is Nunito Sans, and Fredoka is never made to carry one. It
  is not a blanket rule about every glyph: the gate's title, its sum, the typed
  answer and its twelve keys are Fredoka, because they are read as shapes and
  digits, not as sentences, and at 34 px on an 82 px key the display face is the
  legible one. Everything else on the panel is drawn geometry - the cog, the
  slider, two speakers, ear defenders, a quaver, a green tick - so a
  three-year-old can open it, drag it and close it having read nothing.
- **The settings cog is on BOTH screens**, top-left, 92 px at margin 18 (the
  house button's own size and margin, so it reads as the same family). A
  four-year-old learns one place once; and "the privacy link is reachable from
  inside the app" cannot mean "reachable from the one screen a reviewer happened
  to open".
- **Opening it PAUSES, and lets go.** `get_tree().paused = true` is the only
  thing that can stop a game whose every beat is a polled hold. With it: the
  HUD's pads are released, the level's own fingers are dropped
  (`NOTIFICATION_PAUSED` joins the focus-out arm), and the title row's HELD
  "new drive" disc is let go (`StartMenu.release_hold`) - a frozen tree never
  delivers a release, so that ring would have gone on filling after the panel
  closed and thrown a saved job away. The `Sfx` keeps its own clock, so a
  loudness control is never set over silence, while the machines' loops freeze
  with the picture.
- **The privacy link opens a sum, not a browser.** `ParentalGate`: two factors
  of 3..9, re-rolled every time it is asked, twelve keys, a wrong answer clears
  the slot. Apple's Kids rule is that the gate is arithmetic, never a
  press-and-hold - which is also why the game's own destructive control (the
  "new drive" disc) may be a hold: it destroys a drive, not a child's privacy.
- **Every corner control keeps off the hardware.** `SafeArea` insets now move
  the house, the bar, GO, NEXT, the four steering pads and the title's corner
  disc, re-read whenever the viewport changes size. GO and NEXT are measured
  WITH their halo, which is drawn and so is part of the control. What no inset
  can move: the gold ring and the arrow the job points with are 3D, not
  Controls - if a beat's ring lands in a phone's outer band, only that beat's
  camera shot can fix it.
- **Reduce-motion stops the CAMERA, and nothing else.**
  `Settings.motion_reduced()` reads `DisplayServer.accessibility_should_reduce_animation()`
  once (a harness decides it with `motion_override`), and it guards
  `CameraShake.shake()`, `hold_floor()` AND the shake's own `_process` - a guard
  on the kick alone would leave the floor rattling the picture through a whole
  jackhammer bite. Still moving, deliberately: the slab's kick, the bit's
  stroke, the camera's shot travel (the eye walks with the work), the gold
  rings' pulse (that is WHERE TO TAP), and every answer to a finger. A toy that
  stops answering is not accessible; it is broken.
- **What ships with the bundle:** `THIRD_PARTY_NOTICES.md` and four licence
  texts (`licenses/`), the two Godot ones generated from the running engine by
  `tools/make_engine_licenses.gd`. They are files, never a screen: there is no
  credits page in this family and there must not be one here.
- **The tests:** `settings_probe` (the panel, by real touch pairs - a finger
  reaches a Control twice), `privacy_probe` (the policy's claims, including the
  save's `saved_at` erase, which nothing tested before), `safe_area_probe`
  (both screens at 1565x720 and 1280x960, against Apple's documented insets)
  and `motion_probe` (the camera stops, the world does not). Every probe sets
  `Settings.motion_override = -1`: a test decided by the developer's own OS
  settings is not a test.
