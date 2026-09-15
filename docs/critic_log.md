# Critic log

One section per round of `docs/CRITIC.md`. Newest at the bottom. Read the LAST
section first: it says what is already known and what was deliberately left.

## Round 0 — the build itself (2026-09-11)

Not a critic round: what the build found on its own, before any critic saw it.
Recorded because a critic should not spend a round re-finding these.

**Found by `scenes/dev/machine_probe.tscn`** (it prints every pivot's rest
transform and sweeps it):

- The skid steer's loader arm turns the OPPOSITE way to the guess: a positive
  turn about +X lowers it. At the guessed signs the bucket floated 1.8 m in the
  air at "on the ground" and went 0.85 m underground at "carried high".
- The dump truck's bed pivot is at the REAR of the body, so tipping does not
  raise the tailgate - it swings it down and back. The first probe asserted the
  tailgate rose and reported a wrong axis when the axis was right; the honest
  question is whether the FRONT of the bed rises.
- **The chute cannot aim.** Folding it moves the pour point 0.11 m, because the
  spout is already as far out as that arm reaches; swinging it sweeps 2.4 m.
  Against a 9 m x 3.6 m driveway that is not a control. This is what turned the
  pour into "swing the chute across, drive the TRUCK up and down the drive"
  (DESIGN 2a), which is also how a real residential pour is done.

**Found by reading the first renders** (`renders/first`, `renders/second`):

- The lawn was ONE box spanning the lot with its top at grade, so the driveway
  could never be a hole: the excavation was filled, the gravel base was buried
  inside it, and the pour shot showed a form 94% full of concrete with not a
  drop visible. The lawn is four boxes round the pad now.
- The old driveway did not look old. No cracks, no stains - the fault was not
  legible as shape before the first tap, which is a pillar violation. Every
  panel now arrives cracked and stained, and `site_smoke` counts the damage.
- Machines stood at grade over a 0.2 m excavation with daylight under their
  wheels (`Driveway.stand_y`).
- The broom finish was 5 mm ridges that caught their own shadow: the finished
  drive read as corrugated iron. Flat bands now.
- The first panel was at the garage end, so the opening shot of the whole game
  stared at a white wall. Panels are numbered from the kerb.
- The finished slab was within a shade of the council footway, so the payoff
  read as more pavement. New concrete is paler and warmer now.
- The rubble heap was still on the lawn in the final picture; the crew loads it
  out during the cure.

**Built and then CUT: "the mixer may not reverse over its own pour."**

Worth recording so nobody re-litigates it. It is honest - a driver really does
avoid it - but it was my idea, not the user's, and it went wrong three times:

1. Asked globally ("the furthest concrete anywhere"), it locked the truck out of
   the whole drive the moment the kerb end was laid, so the apron half could
   never be poured. The fill grid froze at 80%.
2. Measured from the SPOUT (4.5 m behind the truck) rather than from the rear
   tyres, the limit shoved the truck forward every frame until its chute hung off
   the end of the form and poured onto the grass. The form reached 19%.
3. Asked locally about the tyres' own spot, it still failed its own test, because
   concrete slumps under a stationary truck after it has stopped.

The mechanic the user asked for is aiming the chute and driving the truck. With
the rule gone the pour fills in 156 sweeps and the whole job passes 65/65. If it
returns it should be a visible consequence a child can see - tyre marks in the
slab - not an invisible limit on where the truck may go.

**Left deliberately, for a critic to judge rather than me:**

- The stains on the old slab are rotated rectangles and read as rectangles up
  close (`renders/third/old_panel.png`).
- The rubble heap is small for six broken panels.
- Sound is borrowed: the jackhammer is `impact`, the pour is `drain`, the screed
  and broom are `scrape`. No driveway noise has been generated yet.
- No title screen, settings or privacy gate - prototype.

## Round 1 (2026-09-12) — 18 findings, 4 of them S1

A fresh critic, evidence in `renders/critic/round1/` (25 shots it took itself).
Its own summary: "findings 1, 2, 3 and 6 are four edits that would carry most of
the rest", and it called phase 1 (the jackhammer) the part that already works.

**The four S1s.** The pour — the centrepiece — had NO camera that showed
concrete leaving the chute (framed from 15 m with the drum in the way). The form
boards and the stakes were created invisible and only appeared once the child had
already pressed, so the arrow spent the first press of two whole phases pointing
at bare earth. The road `Crossing` box reached 1.11 m onto the pad with its top
13 cm proud of the slab, swallowing the kerb-end form board and hiding the last
metre of the base, the pour and the finished drive. A tap on the picture during
the three "call the machine" beats was swallowed in silence.

**The systemic patterns, which were worth more than the list:**

- **A. Fixed world shots caused six findings.** `CHUTE`, `SURFACE`, `WIDE` and
  `STREET` were absolute eye/look pairs while `PANEL`, `MACHINE` and `FORM` were
  anchored to the step's own target — and the anchored ones are the best-composed
  pictures in the game. `CHUTE` and `SURFACE` are anchored now.
- **B. Every phase ends in a flat grey box and the greys are all within 0.1.**
  Old slab 0.60, crossing 0.66, gravel 0.69, footway 0.72, fresh pour 0.72, cured
  slab 0.81, broom line 0.815. The base looked poured and the pour looked like
  the base. The project already knew "a fault reads as SHAPE, never tint alone";
  it applies to PROGRESS just as much as to faults.
- **C. A thing is invisible until the child touches it.** Build things in their
  "before" pose and let the verb only MOVE them.
- **D. `pose_stage` and the real game had drifted, and the evidence flattered the
  build.** The posed `done` never dried the slab, so the broom read at four times
  the contrast it has in play; `pose_at` never set the bar; there was no posed
  payoff at all. Three findings were only visible by comparing the pose path
  against the play path.
- **E. A machine's height is sampled once and then it travels.** The mixer drove
  the length of the drive and out over the kerb at a frozen y, ending sunk in the
  road with its tyres 9 cm into its own fresh slab.

Everything above is fixed in this round bar the deferrals below. Also fixed:
the screed was pulled against the pour and floated 2 cm over the slab while
passing through both stakes (the form tops were 2 cm proud of the slab they were
shuttering); the joints were a strip standing ABOVE the surface; the rubble heap
sank bodily through the lawn during the cure; one lonely stake per 9 m board;
the excavation's earth banks were on show before the first tap; chunks lay flat
in tidy rows and the heap packed into one interpenetrating boulder.

**Deferred, with reasons:** the house button still reloads mid-job with no
confirmation (a prototype has nowhere else to go); the old slab's stains are
still rotated rectangles, but two more cracks per panel were added instead,
because it is the cracks that carry "broken" as SHAPE and the stains only read as
dirt; driveway-specific sound is still borrowed.

### What the fixes did, and what they broke

Verified after: `site_smoke` 65/65, `machine_probe` 12/12, evidence in
`renders/round1fix/`. The payoff exists as a picture for the first time
(`h_parked2.png`), the push is framed on the machine doing it (`f_push.png`),
the joints read as lines across the slab (`i_joints.png`), the base is plainly
crushed stone and not concrete (`c_base.png`), and the boards are in the air
over their places before the first tap (`b_forms.png`).

**The fix pass introduced five defects of its own.** Worth writing down, because
the ratio is the lesson - eighteen fixes, five new faults, four caught the same
hour:

1. Widening the rubble heap's spread pushed chunks back inside the "still on the
   pad" test box, and the smoke test failed 64/65. The test box was the wrong
   shape anyway (0.75 of the width, reaching 2.7 m either side of a 1.8 m pad).
2. Making the form boards visible fixed PLAY but not POSE, so a posed shot still
   showed the arrow over bare earth - and a critic judging from `--stage` shots
   would have re-found a fixed fault. `pose_stage` now raises them too.
3. `parked` was added to `STAGE_STEP` but not to `pose_stage`'s own list, and an
   unknown stage name poses NOTHING quietly: the first payoff render was a car
   sitting on the old cracked driveway.
4. The joints were sunk below the slab to stop them standing proud, which hid
   them under the very surface they are cut into. They sit a hair INTO it now,
   the same trick the broom lines use.
5. The CHUTE camera - below.

**The chute camera took five attempts, and the geometry is why.** The spout
hangs at the mixer's TAIL, the mixer is 8.6 m long, and it lies along the drive:
so every view *down* the drive (from the street, from above, from the garage end)
has the whole drum between the lens and the concrete. Across the drive there is
nothing in the way - but at the START of the pour the spout is hard against the
garage, so a low side-on eye looks straight into its wall. It ends out and up on
the drive's left: readable once the truck has pulled away from the garage
(`o_pour5_mid.png`), still cramped at the very first drop (`n_pour5.png`).

It stays on the LEFT deliberately, and that is not a taste call: the camera is
what decides which way "left" means, and the pads that swing the chute had only
just been made to agree with it (round 0).

**Open for round 2:**

- The CHUTE shot at the pour's first drop, above.
- The `FORM` shot is tight enough that two boards cross at an odd angle.
- Evidence note for the next critic: `--stage=cleared` means the pad is ALREADY
  clear, so posing the push beat there shows a machine with nothing to push. Use
  `--stage=broken --step=2`.
- Still deferred from round 0/1: the old slab's stains are rectangles (two more
  cracks per panel were added instead), the house button reloads mid-job with no
  confirmation, and all the sound is still borrowed from the garage's library.

## Round 2 (2026-09-12) — 12 findings, and a better idea than mine

A fresh critic, fed round 1's findings and asked specifically to hunt OVERSHOOTS.
41 shots in `renders/critic/round2/`. It found three that carry the list, and it
was right that all three are the same shape as each other.

**1. The pour camera was anchored to the CHUTE — the thing the child steers.**
Round 1 anchored it, which was the right instinct applied to the wrong node: eye
and look are both offsets from one anchor, so the basis never changes and
everything bolted to the truck lands on identical pixels forever. Holding UP slid
the *house* past a frozen truck; swinging the chute swung the camera with it, so
the TRUCK appeared to move instead of the concrete. **Both pads read backwards.**
The rule it extracted is now the rule: **anchor to the WORK, not the TOOL** — a
thing that stays put while the world moves across it, which is exactly why
`PANEL`, `MACHINE` and `FORM` have always worked. `CHUTE` anchors to `Slab`.

**2. The footway lay 1.10 m over the driveway, 12.5 cm proud of it.** The last
metre of *every phase* was under the pavement: the kerb-end form board was never
once visible, 37% of the first slab the child breaks was buried, and the
`Crossing` box round 1 added "so the drive reads as joining the road" was itself
entirely inside the footway and never drawn.

**3. The earth banks wholly contained all four form boards and all ten stakes.**
Each 0.14 m bank straddled the 0.05 m board line at exactly grade, so boards
rendered as a stippled dashed line that flickered as the camera eased, every
driven stake vanished, and the finished drive was framed by a trench of bare
earth. `formed` and `staked` were the same picture: eight of the child's thirty
progress stops left nothing on screen.

**The systemic pattern behind all three — and it is about ME, not the code:**
*round 1's fixes were applied to instances, not to classes.* `Crossing` was
pulled off the pad; `Footway`, the bigger box doing the identical thing behind
it, was not. The banks were made to appear at the right moment; their extents
were never looked at. The gravel was moved off the fresh pour and landed on the
wet slab instead. Every one is the same shape: the symptom named in the log was
cured at the exact spot it was seen. This is the same failure the fleet's
art-critic loop hit — fix the helper, then apply it to a hand-written list.

**Also fixed:** the broom lines were painted in the DRY slab colour while the
slab was wet, so they started 37% lighter than the concrete, matched it exactly
on the final frame of the stroke and only darkened during the cure — the child
watched their finish appear backwards and vanish as they completed it (they take
the slab's live colour now, and re-tint with it). The cones and the site fence
stood through the payoff, the most saturated things in the reward picture. The
road was buried under the lawn, leaving 1.3 m of grass in the carriageway. The
resting tools' handles passed through the site fence. The broom's duty cycle went
0.42 → 0.12 across rounds 1 and 2 — a textbook overshoot — and is now 0.20. The
payoff has a shot of its own instead of being the eighth outing of `WIDE`.

**And an evidence-integrity bug that had been quietly poisoning the loop:**
`STAGE_STEP` put `done` and `parked` at 16 against 16 steps, so the runner was
PAST the last step, there was no current step, an anchored shot resolved to a
null anchor, and `CameraRig` silently read the offset as a WORLD position and put
the camera out on the lawn. Every judgement made from `--stage=done --shot=SURFACE`
— including some of round 1's about the broom — was made through a camera the
game never uses. A missing anchor now warns and falls back to `WIDE`, the stages
clamp to 15, and machines are parked for the posed STEP rather than the stage
name (which is why round 1's own note to use `--stage=broken --step=2` rendered
an empty street).

**Judged and left alone:** the critic showed that `DRY_CONCRETE`'s "warmer"
renders 12 units BLUE because the sky-source ambient is blue, so the warmth claim
buys nothing and only the 14% value step does the work. True — but changing the
scene's ambient right after a large fix pass is exactly how the last two
overshoots happened, and the value step is doing its job. The claim is what is
wrong, not the picture; left for a round that has nothing better to do.

**Called correctly, per the critic:** the jackhammer and the rubble are the best
things in the game; the control joints read cleanly and are not lost in the
broom; the finished slab is clearly not the footway any more; the arrow is well
placed and sized and points at the board's HOME rather than the floating board;
the HUD never covered a subject in any of its 41 frames; the car parks after the
cure and not on green concrete.

### What the fixes did, and what they broke

Verified after: `site_smoke` 65/65, `machine_probe` 12/12, evidence in
`renders/round2fix/`. The pour camera now holds a steady frame of the whole
drive; the form boards and stakes are plainly visible with the brown trench gone
(`h_stakes.png`); the broom reads as a brushed finish in the slab's live colour
(`f_done.png`); the mixer has left by the water phase (`k_sprayed2.png`); and the
payoff is a clean car-on-new-drive with nothing of the crew left in it
(`o_payoff5.png`, `p_payoff_wide3.png`).

**Three more defects, found by checking the fixes rather than trusting them:**

1. `fade_node` did nothing to the site fence or the cones. Writing to
   `get_active_material` works for the boxes `driveway.gd` builds - each makes
   its own material - and does NOTHING for an imported GLB, whose materials are
   shared by every instance and need not be `StandardMaterial3D`. It takes a
   per-instance copy through a SURFACE OVERRIDE now.
2. The screed is a 4.2 m board and `TOOL_REST` is its MIDDLE, so resting it clear
   of the drive still laid half of it across the fresh pour - the one place a
   groundworker would never put it down.
3. **The pose/play drift caught a third time.** Fading the tools with the crew
   did nothing, because in the POSED path `_cure` runs before `pose_at`, and at
   that moment every tool is invisible (only `present_tool` shows one) - so the
   `visible` guard skipped them all and `pose_at` then put the broom back at full
   strength. It fades every tool regardless now, and the cure gets the last word
   after posing. In PLAY it had always worked, which is exactly why it needed a
   picture to find it.

**The lesson worth carrying out of rounds 1 and 2** is the one the round-2 critic
named about round 1: *fixes were applied to instances, not to classes.*
`Crossing` was pulled off the pad and `Footway` - the bigger box doing the
identical thing behind it - was not. The banks were made to appear at the right
moment and their extents were never looked at. The gravel was moved off the fresh
pour and onto the wet slab. Each time, the symptom was cured at the exact spot it
was seen. Round 3 should ask, of every round-2 fix: what ELSE is of this kind?

---

# The user's own playtest, 2026-09-12 — ten notes

The `/loop` was stopped for this. The critics had run two rounds; the user played
it and wrote down ten things, and a real playtest outranks a critic round every
time. Every note is actioned below, with what it cost.

Worth noticing before the list: **six of the ten are the same mistake.** The toy
kept answering a phase with ONE control applied to a WHOLE thing — one hold per
slab, one hold per set of stakes, one click for all the water, one click for all
the brushing, one pad for a truck that only goes one way. The child was being
asked to confirm a phase rather than to do it. That is the pillar this family
already has (*"a tap must land on or near the thing"* — `feedback-car-fixer-tap-on-target`)
applied one level up: **the unit of work has to be a PLACE, not a phase.**

| # | the note | what it was | what it is now |
|---|---|---|---|
| 1 | jackhammer too small | a 0.55 m demolition hammer, seen from 4.2 m | scaled 1.85 to a 1 m breaker (`HandTool.SCALE`), and `PANEL` came in to 2.6 m to meet it |
| 2 | 3 clicks per section, 3 different spots | ONE hold per panel, in the middle of it; a tapper needed eight taps to finish one | 18 TAPS: three marked places on each of six panels, the arrow walks to a new third each time, and the panel lets go on the third |
| 3 | cracks are perfectly straight | one rotated box per crack | every crack is a ZIGZAG of seven short boxes (`Driveway._zigzag`), and the hammer's runs OUT from under the bit a segment at a time |
| 4 | the skid steer goes through the rocks and clips into the house | it reversed BEHIND each band across the drive — through the rubble, and into a sealed garage GLB that stood 23 cm ON the driveway, which itself overlapped the house by 3 m | the garage is built in code with a real opening and a roller door; the house moved off it; passes are per COLUMN, nine metres in one go from inside the garage; the machine climbs OVER the rubble (`ride_y`, sampled at nose and tail so it tips) |
| 5 | can't click some form placements; one hit per stake | the `FORM` shot was anchored to the board waiting 0.9 m UP, so it framed the air while the tap target sat below the frame; and one hold drove a whole set of three stakes | the shot is anchored to a FIXED marker on the edge of the hole, the board waits 40 cm up instead of 90, and there are ten separate stakes, one tap and one blow each, with a `STAKE` shot right down on the peg |
| 6 | dump truck should be touch-and-hold; rock texture poor | the UP pad drove it, and the base was one flat box of grey that grew in HEIGHT | press-and-hold on the picture (no pad), and the base is a windrow at full depth growing along the drive with 300 loose stones revealed as the truck lays them |
| 7 | vehicles float and turn in instead of rolling or backing up | `drive_to` LERPED one pose into another, so a machine slid diagonally while its yaw turned independently — and the wheels roll by the component of that slide along its own nose, which is nearly zero when it crabs | `Machine.follow` drives a rounded polyline with the nose READ OFF the path; both trucks reverse in tail-first; the skid steer turns on the spot with its tracks counter-rotating; everything pitches to the ground under it |
| 8 | detach the chute, camera right up to it | the pour was watched from 9 m up with the whole truck in frame | `Machine.show_only(["Chute"])` stops drawing everything but the chute — the truck is still there and still moving — and `CHUTE` sits beside the spout, anchored to `PourView`, a point that follows the pour along the drive's length only |
| 9 | move the water and the broom yourself | a hold that swept itself up the drive on a timer | both are DRAGGED (`SiteVerbs._scrub`): per-cell coverage grids, the slab visibly undone where the finger has not been, and the beat ends on `water_coverage()` / `broom_coverage()` |
| 10 | camera couldn't see all the joints | `SURFACE` looked up the LENGTH of the slab, so the far end of a line running across it was off frame | its own `JOINT` shot, square on; the smoke test unprojects both ends of the line through the live camera and fails if either is outside the frame |

## What the fixes cost, and what they broke

* **A typed-array parameter cannot be reached through a Variant call.** The verbs
  dispatch on `runner.level`, which is deliberately untyped to avoid a class
  cycle, so `drive_route(m, corners: Array[Vector3], ...)` refused every literal
  the verbs passed it. Plain `Array`, converted inside.
* **Seating a machine at its nose AND its tail made an old fault visible.** The
  dump truck's rearmost axle sat 0.46 m past the apron, on the ramp out of the
  excavation, so it rode 15 cm high with daylight under its front wheels. It had
  always been there; one height for the whole machine had hidden it.
* **The smoke test's own sweep ran out of laps rather than out of slab**, and
  reported the new drag mechanic broken at 0.78 covered. A headless frame is a
  fraction of a millisecond, so work paced in SECONDS has to be tested in FRAMES.
* **Three pose/play drifts, the fourth, fifth and sixth of this project.** The
  posed garage door was shut for every picture from the push onward, though play
  opens it at `call_skid` and never shuts it until the cure. The stage→machine
  fallback parked the mixer on the drive for the WATER, a beat the job sends it
  away before. And a posed payoff still had the gold arrow over the car. All
  three were in the `--stage` path only. `SiteMain._pose_tool` now also puts the
  posed step's tool where its verb would hold it, so a posed picture of the
  stakes shows the sledge over the peg rather than on the lawn.

## Where it stands

`SITE_SMOKE PASS 102/102` (was 65 checks, now 102 — the new ones assert the notes:
that no two bites are asked for in the same place, that each panel goes on its
third, that the machine climbs the rubble and never sinks through the ground,
that the truck is not drawn during the pour and is whole again after it, that
holding the hose in one corner wets that corner and no more, and that both ends
of a joint are inside the frame). `MACHINE_PROBE PASS 12/12`. Renders in
`renders/notes4` and `renders/notes5`.

**Still open, and none of it is from these ten notes:** all the sound is still
the car garage's library (there is no breaker, no mixer drum, no screed drag);
the house button reloads mid-job with no confirmation; there is no title screen,
no settings and no privacy gate.

---

# The user's second playtest, 2026-09-12 — four notes

| the note | what it was | what it is now |
|---|---|---|
| still shots where I can't see where to click, the stakes worst | the gold ARROW pointed at one place, and the job decided which. The stakes shot was close on that one peg, so nine others were off screen and invisible | **gold rings** (`SpotRings`, Tree Crew's `FellHint` made plural) on EVERY place a beat will still take — three on a slab, four on the boards' homes, ten on the stakes — all on screen at once, all tappable, and the arrow stands down while they are up |
| the camera should move during things like the jackhammer | every shot was a fixed offset from its anchor, so the picture was frozen for the whole phase | `CameraRig.define` takes a drift: the eye swings slowly about what it is looking at and rises as it goes. Every shot but `CHUTE` and `SURFACE` orbits |
| the three jackhammer spots should be marked, any order | the three bites were numbered and taken in order; nothing on screen said where they were | rings on all three, and the slab lets go on whichever is last. `Driveway` keeps a per-spot flag instead of a count |
| the chute camera should be right by the back of the chute; the pour fills too fast; the tipper looks empty | the eye was 4 m out and side-on, the pour self-levelled across nine metres, and the bed was empty as it reversed in | the eye sits just behind and above the chute's own head with the truck behind it; `SLUMP` is up and `SLUMP_RATE` down so the form has to be filled patch by patch, like the hose and the broom; and the tipper arrives with a heaped load that sinks as it runs out |

## What it cost

* **`billboard_keep_scale` does not mean constant screen size.** It only stops a
  node's own scale being thrown away when it billboards. Ten rings spread over
  nine metres came out at 18 px at the far end and 60 px at the near one, so the
  distance is measured and the scale set from it (`SpotRings.NOMINAL_M`).
* **`global_position` on a node that is not in the tree is silently dropped.**
  Every ring was built, positioned, and then added — so every one of them landed
  at the origin, out in the road. Add first, then position.
* **A narrower stream is not what makes the pour a game.** Cutting `pour_spread`
  to 0.64 locked the outermost column out: the chute's swing only reaches 2.39 m
  of the 3.60 m width, so the spread has to cover the rest, and the pour stalled
  one cell short every single time. What makes it a game is the concrete not
  finding its own level (`SLUMP`) and the load taking longer to arrive
  (`pour_time`).
* **A test that photographs the camera has to wait for the camera.** The rig eases
  over `shot_time` and a headless frame is a fraction of a millisecond, so
  thirty frames is nowhere near the end of a move: two frame checks were failing
  against a camera still half way between two shots.
* **`is_position_behind` is a near-plane test, not a frustum test.** A camera
  pitched 30 degrees down says a point below and behind it is in FRONT. The
  honest assertion for "the truck is out of shot" was never that — it is that
  none of the truck is drawn, which the mesh counts already say.

`SITE_SMOKE PASS 138/138`, `MACHINE_PROBE PASS 12/12`. Renders in `renders/notes9`.

---

# The third playtest note, 2026-09-12 — the idle mark

> "the idle animation looks terrible. Not sure what it is.. is it a finger
> pointing? needs to be improved."

It was `SiteHud.ArrowMark`: a flat gold wedge drawn over the picture in 2D, a
stubby arrow with a 0.84-wide head on a 0.32-wide shaft and a thick dark rim.
Three separate faults, and the first one is the one that matters most - the user
could not tell what it was:

1. **The shape read as a hand**, not as an arrow.
2. **Its point dipped INTO the target and back out** every 0.77 s
   (`lead = reach - bob`). Travel toward a thing and back is a JAB. What says
   "this one" is a mark that sits ON the thing with something bobbing over it.
3. **It re-solved which of twelve directions to approach from every frame.** That
   was survivable while the shots were fixed; the moment they started to orbit,
   the wedge flicked from one side of its target to the other as the score
   changed.

Replaced with the mark the user had already asked for by name two notes earlier:
a gold ring in the WORLD with a fat arrow bobbing above it, which is `SpotRings`
showing one place instead of several. It cannot read as a hand, it cannot jab
(the arrow falls toward the ring and rises, and the ring never moves), and it has
no idea the edge of the screen exists. About 150 lines of wedge arithmetic -
`solve_arrow`, `aim_directions`, `arrow_rect`, `hud_obstacles`, `_aim_penalty` -
went with it.

One thing that came out in the wash: **a mark in the world cannot hide itself when
it is off frame, so what it points at has to be in the picture.** The push aimed
at the middle of nine metres of rubble while the camera watched the bucket at the
garage end, and half the ring was off the bottom of the screen. It aims at the
FIRST piece the blade will meet now, which is in front of the blade and stays
there.


## The camera playtest (2026-09-12) — five notes, four of them one note

Not a critic round: the user played it again. Four of the five are the same
sentence said four ways - **you are watching the job from across the street** -
and the fifth is the last thing on the lot that still floated.

- **A step's shot was chosen once.** Eighteen hammer bites are ONE step, so the
  eye stood on the first panel for the whole phase and the panels up by the
  garage got smaller and smaller. `JobRunner._play_beat` re-asks for the shot
  after every beat now. It is four lines, it costs nothing when the anchor has
  not moved (`CameraRig.go` returns early for the same shot on the same anchor),
  and it is what the whole note was about.
- **"Show me every place" and "get close" pull against each other, and the
  answer is GROUPS.** The second playtest asked for a ring on every live place,
  which is why the stakes were framed from up on the roof to hold all ten. This
  one asks for the hammer feeling, which is three metres away. Both are right:
  the stakes are worked as five PAIRS across the form, rings on the live pair
  only, and the eye steps down the drive as each pair goes in. Same shape as the
  hammer's three-bites-per-panel, which already worked.
- **A fallback that ignores the group is a blow nobody saw.** `stake_drive` took
  `done_in_step + 1` when no ring had been picked (GO, the keyboard, a posed
  screenshot) - which drove a stake nine metres from the camera while the
  picture sat on the pair. It takes the first open stake of the live group now.
  Found by photographing the beat, not by the smoke, which always picks a ring.
- **The hose had to go into the child's hands.** Lowering the camera alone was
  not enough: at any height that still lets a finger reach the far end of the
  slab, a nozzle out on the slab is small. It rides an arm's length in front of
  the eye now and only its AIM follows the finger - and the jet had to be thrown
  as far as the finger is aiming, or it dribbles out at the camera
  (`HandTool.set_spray_reach`).
- **The tipper's "pour" was the dust puff with a different colour.** Forty 5 cm
  quads thrown UPWARD out of a point. A tipper pours a curtain off the whole
  width of the tailgate: a box emitter turned with the truck, 220 stones, real
  gravity. And the camera has to be BEHIND the tailgate looking back at it -
  beside the truck, the body hides the one thing the beat is about. Three
  framings were rendered before that was obvious.
- **The car was the last float.** Everything else on the lot became a `Machine`
  in the first playtest; the homeowner's car was still two lerps and a yaw. It
  is a `Machine` now (`model_path` lets one load a GLB from the vehicles folder)
  and it drives the same rounded corner as the trucks.
- **Every tool was making a car-garage noise**, which the docs had said for a
  day and nobody had heard until the user did. Twelve ElevenLabs clips,
  `docs/sfx.md`. The breaker changed shape too: a one-shot per blow at 13 blows
  a second is thirteen clips a second landing on each other.

Frames: `renders/notes10/` - the before pictures (`stakes.png`, `water.png`,
`pour.png`, `gravel.png`) and the after ones (`jack_panel5.png`, `stakes5.png`,
`water2.png`, `pour3.png`, `gravel6.png`, `broom2.png`, `car.png`).
SITE_SMOKE 143/143, MACHINE_PROBE 12/12.

Two things left where they are, on purpose: the concrete cells still read pale
in bright sun (a material question, not a framing one), and the chute is still
one angle rather than something the child tilts - the user's reference clips
did not reach this session, so the eye level and the distance are built to
their description and the tilt is not.


---

# The user's third brief, 2026-09-14 - and critic round 3

> "Make a kids game where they learn how a concrete job is done. Prototype is
> Build Crew. Use Car Garage as a reference. Currently many issues, with camera,
> clipping, visuals, skid steer bucket should be more like a bulldozer push
> blade, missing rebar, etc... You have assets, eleven labs, and blender at your
> disposal." And: a harsh-critic `/loop` until the critic gives 9/10.

## What the brief itself changed, before any critic looked

- **The push blade** (DESIGN 2c). `tools/make_blade.py` builds a dozer-blade
  attachment in the bucket pin's frame; `Machine.fit_blade` hangs it off the
  `Bucket` pivot with the bucket hidden. The cutting edge is put exactly where
  the bucket's lip was, so nothing about the arm had to be retuned. A blade does
  not dump: at the heap the load is shoved on and the blade lifts. The `MACHINE`
  shot came in from 9.6 m to 5.6 and down to 2.4 m, riding with the blade.
- **The rebar** (DESIGN 2d). Twelve bars on chairs, tied where they cross, laid
  by the child: the four long bars, then the cross bars in pairs with the camera
  stepping down the drive (`BARS`). A bar waits in the air over its ring like a
  form board and drops on the tap. New sound `rebardrop` (ElevenLabs).
- **Which forced the pour to change** (DESIGN 2a). A mixer does not drive over
  rebar on chairs, and the old design reversed it the length of the base. Three
  honest alternatives were weighed: a pour in two halves (the fleet chute is too
  short - the rear tyre is 3.16 m behind the origin and the spout only 4.5, so
  no split leaves the wheels off the steel), a pump (throws away the chute game
  the user asked for twice), and the mixer ON THE ROAD with an extension chute
  and the crew pulling the mud up the form with a come-along. The third is what
  a real crew does when the truck cannot get onto the slab, and it keeps every
  control the user asked for: the pads swing the chute and creep the truck, the
  camera stands at the chute man's eye, and then the child DRAGS the rake and
  the concrete comes up the form to them - the "mini game like the water and
  broom lines" they asked for. `Machine.fit_chute_extension` builds the
  extension in code off the spout (1.4 m); `Driveway.rake_to` pulls from the
  fuller cells within a stroke's reach toward the kerb, a cell at a time, so it
  flows; `rake_front_world` is where the hint stands. New tool `ComeAlong.glb`
  (`tools/make_site_props.py`), new shot `PULL` from the garage door, new sound
  `rakepull`.
- **The concrete is one surface.** `Driveway._rebuild_slab` draws the fill grid
  as a heightfield - corner heights blended over the drawn cells, per-vertex
  colour, skirts where a mound meets an empty cell - instead of seventy-two
  boxes. Fresh concrete is a mid grey (`wet_poured` 0.35 -> 0.55; it rendered
  nearly white), the base is a warmer tan so the two are different materials,
  and the hosed patch is a clear step darker (`wet_sprayed` 0.95).

## What it cost

- **The mixer's third axle.** `machine_probe` printed only the contract's four
  wheels, and `WheelR2L` at z -2.66 was never in it - so the first "on the road"
  stand put the rearmost tyre 1.2 m onto the pad and the truck ended its reverse
  crooked. `rear_overhang()` had always known; the constant was written from the
  probe's list instead. The probe fits the extension now and asserts the reach.
- **Godot front faces are clockwise.** The first build of the surface drew
  nothing at all; every fan triangle was wound the other way.
- **Vertex colours are read as LINEAR unless told otherwise.** With
  `vertex_color_is_srgb` off the mid-grey concrete came out two stops lighter
  and, with a 0.3 roughness, mirrored the sky: a sheet of pale blue water.
- **A band that leaks cannot reach 99.5%.** The chute beat ended on
  `pour_done`; concrete crept out of the band into the row beyond as fast as the
  chute filled it and the beat never ended. `band_done` (0.88) is its own number.
- **The rake, not the chute, was the bottleneck** at 0.12 m of fill a second;
  the smoke test's 9000-frame cap ran out at 0.887 full. 0.40 now.
- **The tipper's camera "behind the tailgate" is inside the garage** - the
  truck's tail starts a metre from the door. It stands beside the tailgate now.

## Critic round 3 (the same day, on the pre-rebuild renders): 5/10

Found: the screed was a no-op (the pour ended with every cell already at grade
and the screed wrote the same number: 0.2% luma change - **S1**); the pour's
hint ring sat half on the lawn and borrowed the "tap here" ring for a beat
steered with pads; shadows on the pale concrete were saturated blue (sky-source
ambient, B-R +77); the stream was never visible; the form boards resolved as a
dotted line and vanished from three shots; the tipper's stone was three
materials and spawned inside the bumper; the lot's edge was in shot in nine
frames; `--nomachine` shut the garage door (the eighth pose/play drift); ten
stakes finished flush and left no mark; the garage-end stake pair was driven
into the garage floor; brooming bleached the slab 17%; the wet patch was a
plus sign (`scrub_radius` 0.95 against a 0.9605 m cell diagonal); the jet
landed a metre from the wetting; only the jackhammer had ever been scaled; the
`WIDE` shot made the driveway 2.3% of the frame and the call button twice that;
the fence was the loudest thing in five working frames; the "touch here" ring
varied 3.1x across the job; every particle was the same hard square.

Systemic, in the critic's words: **the fix still lands on the instance, not the
class** (four fresh cases), and **a beat's before-and-after is a number, not a
picture** (sixteen of fifty-two stops left the frame unchanged, all green in the
smoke test because it asserts the number).

## What was done with it (all of it, the same day)

- The surface: an unstruck cell is LUMPY (+-1.8 cm) and mottled; `screed()`
  marks cells struck and they become a plane. `is_flat` asks for both.
- The pour's hint is the arrow only (`SpotRings.show_one(..., with_ring=false)`)
  and is inset from the boards; a hint already up is MOVED, not rebuilt.
- Ambient is a warm neutral colour, not the sky; the sun's shadow edge is blurred.
- Boards are 0.08 thick; the garage-end board is an EXPANSION JOINT strip (no
  stakes, never stripped); eight stakes finish a 5 cm stub above the board on
  the outside; the screed is 3.7 m so it clears them, and a 2x6 so it reads.
- `--nomachine` sets the door and the tool before it returns.
- One aggregate colour for the load, the curtain and the base; the curtain is
  born behind the lip; soft round sprites for every particle (`SiteMain.soft_dot`).
- The lot is 120 x 82 m; the fence is 6 m off the pad and up by the garage.
- `WIDE` is 12 m off instead of 19.5; `JOINT` and `STAKE` came in; the button's
  halo has room; the bar icon has an outline.
- `scrub_radius` 1.05, the jet lobbed 9%, `broom_dry` 0.62 (a texture, not a
  bleach), rings 0.42-0.55 and the hint 0.36-0.62 (was 0.34-1.10).
- `HandTool.SCALE` covers the sledge, jointer, broom and rake.

Left where it was, on purpose: the `WIDE` shot is still the frame the child
comes back to between phases (it has a job now, but it is one shot doing seven);
brooming still lightens the cell (a smaller step) because coverage has to be
legible; the concrete's roughness is one number for the whole slab.


---

# Critic round 4 (2026-09-14, on `renders/critic/round4/`): 6/10

Thirteen of round 3's twenty-two findings fixed, three improved, three not,
one regressed (the broom had gone from bleaching 17% to 28% - `broom_dry` was
raised the wrong way for the new darker pour). Twenty new findings; the ones
that mattered, in the critic's order:

1. **The screed still had no picture.** 1.8% luma across the board's line
   (was 0.2%): an 18 mm lump over a 34 cm half-cell is a three-degree ramp,
   below what smooth shading shows, and the corner blend averaged the mottle
   away. *Fixed as SHAPE:* a bow wave of surplus (6 cm) stands up ahead of the
   board and travels with it (`Driveway.WAVE`, `_wave_z`), the lump is 3.5 cm
   and positive-only (so the steel never pokes through a full pour), and an
   unstruck cell is 12% darker than a struck one - the value step that reads
   from `WIDE`.
2. **Nothing left the chute.** The extension's end sat 0.2 m over the slab and
   the stream was a cube in the chute's own colour. *Fixed:* the chute folds out
   only a little (`chute_fold_max` 0.15), the extension pitches 8 degrees, so
   the discharge is ~0.6 m up; the stream is a shade lighter than the chute.
3. **One flatbed glyph called three different machines.** *Fixed:* the call
   button draws the machine the current step calls - blade, raised tipper bed,
   drum with a chute (`SiteHud.set_call_glyph`, driven from `arm_rings`).
4. **The rebar's rings named a place 0.4 m from the bar waiting over it**
   (parallax on a 0.34 m drop). *Fixed:* `bar_drop_height` 0.10.
5. **The form boards were 0-1 px wide from the kerb-end shots**, because the
   earth banks were still sized for the old 0.05 board with their tops at
   -0.01. *Fixed:* banks outside the 0.08 board with their tops at -0.09, so
   the board shows a face standing out of the earth (F4-20's drift, the same
   number in two places).
6. **`STAKE` and `FORM` were close but not composed** - 41% dirt with the pair
   at the two edges, and `FORM` still watched from across the street. *Fixed:*
   both shots now stand on the lawn and look ACROSS the form at the group, the
   near peg or board a stride away and the far one across the hole; the forms
   are set in three groups (long boards, kerb board, strip) with the camera
   stepping between them (`Driveway.form_group*`).
7. **The lawn was the largest thing in fifteen of seventeen frames.** *Partly:*
   `WIDE` is 2.4 m closer and lower, `MACHINE` stands ahead of the blade with
   the rubble in the middle of the picture.
8. **The chairs read as litter.** *Fixed:* orange plastic stools with a foot,
   under every crossing AND both ends of each long bar, 3.6 cm tall.
9. **The fill front was a staircase of squares.** *Fixed:* an empty neighbour
   counts (at nothing) when a corner's height is blended, so the front is a
   tongue running out over the base.
10. **The cured slab was brighter than the footway and read as decking.**
    *Partly:* `broom_dry` 0.72 (the brushed cell a smaller step), forty brush
    lines instead of twenty-six. The dry colour itself was left: round 1's
    finding was the opposite ("the finished slab read as more pavement").
11. **Every impact was twenty pixels of dust** - one shared emitter restarted
    thirteen times a second. *Fixed at the class:* the breaker has its own
    emitter that RUNS while the bite runs, with chips of concrete under
    gravity (`SiteMain.set_breaker_dust`); `dust_size` 0.22.
12. **The hose's water appeared 300 px from the nozzle.** *Fixed:* a thin jet
    from the nozzle to where it lands (`HandTool._jet`); the drops are its end.
13. **The joint was lighter than the slab.** *Fixed* (dark groove ink).
14. **The tipper's curtain was a ribbon.** *Fixed:* the emitter is the full lip
    and 720 stones.
15. **The cure read as a scene change, not evening.** *Fixed:* sun to 15
    degrees and warm, the sky and the ambient fill sweep with it.
16. **The bar's icon read as a floor drain.** *Fixed:* a yellow hard hat.
17. **The button's halo was still clipped**; the rubble vanished between `done`
    and the payoff; the broom lay on the slab at `done`. *Fixed:* margin 44 and
    a smaller halo; `done` no longer strips the forms or loads out the rubble
    (that is the payoff's); `done`/`parked` put every tool away.
18. **The mixer verb's own doc comment described the old design.** *Fixed.*

Left: the pads' asymmetric layout (it is the family's, shared with Car
Garage); the rake's head got a wear edge and ribs but the `PULL` camera still
stands at the door rather than walking with the front - a moving camera on a
drag beat moves the ground under the finger, and the hose and broom live with
the same trade.

Also this round: the job data still asked for TEN stake taps after the strip
took its two, so the stakes could never finish (`site_smoke` found it, once it
was given the shipped 16:9 frame - the headless window is not that shape, and
a pair of stakes the width of the form apart failed a frame check the real
screen passes). And the come-along could not relay concrete to the apron: a
donor cell gave only 60% of its level DIFFERENCE, which is diffusion, not a
rake. A rake scoops a real amount down to a thin raked-over layer
(`Driveway.RAKE_FLOOR`), the hint stands where a pull is most productive
(`rake_front_world`, which the smoke test follows like a smart child), the
stroke reaches three cells, and `pour_done` is 0.975 - the last few per cent
of a cell are the screed's.

**Green after round 4's fixes: `SITE_SMOKE PASS 194/194`, `MACHINE_PROBE
PASS 13/13`.** Evidence for round 5 in `renders/critic/round5/`.


---

# Critic round 5 (2026-09-14, on `renders/critic/round5/`): 6/10, "a stronger 6"

No S1 in any frame; thirteen of round 4's twenty fixed, five improved, two
not, nothing regressed. Sixteen findings, all visual, all actioned the same
day:

1. **The pour's stream was a grey box.** Now FOUR segments, narrow at the lip
   and wide where they land, each wobbling on its own, a splash disc where it
   hits, a pale lip plate on the extension so the eye sees where the concrete
   leaves (`SiteMain.set_pour_point`).
2. **The finished slab read as decking** (forty even ribs, the same value as
   the footway). Brush lines at a third of the contrast, jittered in place and
   width; the joint has a lighter lip along its near edge (a groove, not a
   slot); the footway and the crossing are a step darker and cooler than the
   new slab.
3. **The tipper's remaining load floated at the cab end** and overhung the rail.
   It slides to the tailgate and shortens as it empties; inset from the walls,
   not the skin (`Machine.set_load`).
4. **Twelve rebar taps changed nothing on screen** once the drop was 10 cm.
   The drop is 0.32 m again and the RING RIDES ON THE BAR (and on the waiting
   form board), so mark and object cannot part company; the drop is a picture.
5. **The forms vanished after the pour.** The lawn box ran to the pad's edge
   and buried the boards and their trench; the grass stops outside the trench
   now, and the trench is backfilled and TURFED as the forms come off, so the
   finished drive is not framed by a ditch (`Driveway.strip_forms`).
6. **Five shots still 40% lawn.** `TIPPER` stands square behind the tailgate
   (the curtain across the picture, the base under it); `FORM`, `STAKE` and
   `BARS` came down - the stakes from the corner with the near peg big and the
   far one across the hole; the bars low along the steel so the chairs have
   legs and the bars have air under them; `PULL` hangs off `RakeView`, which
   hops down the drive behind the concrete's front only while the finger is
   UP, so the come-along is in the child's hands.
7. **A pale rectangle in the road at the payoff, lit by "yesterday's sun".** It
   was the world's background showing through a HOLE in the ground: the road
   began a metre past the kerb and the lawn sliver stopped at the kerb, so in
   the drive's width there was nothing at all. The road starts at the kerb's
   back now (also the "grass gutter"). Found with a new `--hide=A,B` shot
   argument that hides named nodes - the way to ask "which box is that".
8. **The screed's bow wave was a value step, not a shape.** It is its own ridge
   against the board's face now, with the lumps at 5.5 cm.
9. **The fill front was still a staircase.** An empty neighbour now weighs
   double in the corner blend and the colour runs out toward the base, so the
   front of a pour is a ramp.
10. **The sledge was a mallet on a stick** in the same grey as the peg. Rebuilt
    with a dark steel head 2.5x the stake's width, bright chamfers, the handle
    through its SIDE (`make_site_props.py`, which needed the fleet's `Wear`
    palette entry).
11. **The water jet was a rigid bar.** A translucent cone now, thin at the
    nozzle, opening toward the landing.
12. **A tenth-size hose sprayed in mid-air in a machine-free WIDE.** A
    hand-held tool (hose, broom, rake) is only posed in its own beat's shot.
13. **The rubble heap was a wheelbarrow of chippings.** Tighter and taller.
14. **The skid steer's outer wheels rode the pad's edge.** `lane_drive_x` pulls
    the machine's line toward the centre; the 2.04 m blade still covers the lane.
15. The broom's handle leans toward the child; the skid glyph's arm is thicker.
16. The blade got its dust: earth boiling over the board while it pushes
    (`SiteMain.set_push_dust`), the one thing round 4 said would make the push
    a beat to show a friend.

Left: the pads' asymmetric layout (the family's).

**Green after round 5's fixes: `SITE_SMOKE PASS 194/194`, `MACHINE_PROBE
PASS 13/13`** (the first stake reframe put the near peg under the frame's
bottom edge and the smoke caught it; the corner framing passes). Evidence for
round 6 in `renders/critic/round6/`.


---

# Critic round 6 (2026-09-14, on `renders/critic/round6/`): 6/10, "top of the band"

No S1. Five of round 5's sixteen fixed, six improved, five not, one regression
(the joint's lip, a fixed near-white, had become the brightest object in the
world). The critic's systemic finding, and it is the right one: **the fix
lands in the number the fault was measured in, and the fault was never a
number** - the screed answered three times with a tint when it needed a
silhouette; the stream coloured "a shade lighter than the chute" grouped with
the machine; the cured slab warmed to differ from the footway stopped being
concrete. Eighteen findings, answered with SHAPES:

1. **The pour showed no concrete.** The stream is the MATERIAL's colour now -
   a step lighter and warmer than the pool, round segments, a pale splash -
   and the cell under the spout heaps into a MOUND while it pours
   (`Driveway.set_pour_mound`), which is the feedback an aiming game needs.
2. **The finished drive read as decking, 65% brighter than the footway.**
   `DRY_CONCRETE` is neutral pale grey (0.70) a step above the footway, not
   cream; the brush lines feather in with the cell's coverage and stop at the
   control joints.
3. **The payoff was the darkest frame in the game.** The fill comes UP as the
   sun comes down (ambient 0.6 -> 1.05, sun 1.25 -> 1.55 at 20 degrees), so the
   warmth alone says evening.
4. **Three phases played on a wall of flat brown.** The excavation has ninety
   clods of spoil (revealed with the banks) and the blade's ruts down each
   lane (revealed when the pad is cleared), all under the base once it is
   laid; `FORM` looks diagonally up the drive from the kerb corner.
5. **The call button was the lawn's colour.** White body, green glyph, gold
   halo; the skid steer's glyph is a solid blade proud of a body with no
   cut-outs (a window read as a slot, the wheel centres as eyes).
6. **Everything that waited in the air read as misplaced.** A dark ground mark
   under every waiting bar and board says "it lands HERE" (`Mark`, `FormMark`).
7. **The heap was a tenth of the driveway.** It was the pose: every chunk at
   ONE point (the ninth pose/play drift). The pose builds the heap through the
   same function as the push, which now stacks both passes into one cone,
   1.3 m in radius and a metre high. The mailbox moved clear of it.
8. **The screed's ridge had no silhouette.** The `SURFACE` eye is 1.1 m up - a
   kneeling eye - the ridge is a hand high, and the unstruck surface has noise
   at its CORNERS (shared, so it survives the blend) as well as its centres.
9. **The joint's lip** is a tenth above the slab's LIVE colour, refreshed with
   it (`_refresh_joint_lips`), never a fixed white.
10. **The jet was a rigid rod.** Four segments on a parabola, opening and
    fading toward the landing.
11. **The broom was a blue brick with a stub handle.** Eighteen tufts, a 1.7 m
    handle that runs from the head to the child's hands (`hand_hold`), so it
    comes out of the bottom of the picture.
12. **The sledge was a tin can.** A rectangular block head with chamfered
    faces, seen from the side.
13. The car is centred on its own wheels (`Machine.centre_model_x`: the
    hatchback's origin was off its middle); the shadow map is 4096 with the
    highest soft filter (the dithered wedge at the lawn's edge); the wet sheen
    is a touch flatter so a grazing eye does not mirror the sky.

Left where it was: the HUD bar across the top (the family's).

**Green after round 6's fixes: `SITE_SMOKE PASS 194/194`, `MACHINE_PROBE
PASS 13/13`.** Evidence for round 7 in `renders/critic/round7/`.


---

# Critic round 7 (2026-09-14, on `renders/critic/round7/`): 6.5/10

Eleven of round 6's eighteen fixed, five improved, one not, no regressions,
no S1 - and **five phases the critic would show a friend** (the break-out,
the push, the forms and stakes, the steel, the payoff), so the "delight"
half of a 9 is there. What holds it is the "nothing wrong" half, in one
phase and one constant. Their systemic finding this time: **colour is chosen
against ONE neighbour and shipped into a picture full of others** - wet
concrete was tuned against the footway and never against the road (2% apart);
the stream was made "lighter than the chute" and came out cream. Rule adopted:
a material is sampled against the three surfaces it is seen beside in its own
shot.

1. **The stream was a cream bollard.** It is the POOL's own colour a step
   lighter (`Driveway.pool_colour`, set every frame), four overlapping round
   segments on an arc thrown along the extension's own slope
   (`Machine.spout_dir`) and falling, ending on the SURFACE
   (`Driveway.surface_y`: the base before anything has landed, the pool after),
   with a splash half the size.
2. **Wet concrete was the road's colour.** `WET_CONCRETE` 0.40 -> 0.50, sampled
   against the road (0.38), the footway (0.64), the cured slab (0.70) and the
   warm base.
3. **A machine-sized shadow lay on the slab through the whole pour** - the
   chute of a truck that was not drawn. `show_only` turns the kept meshes'
   shadows OFF and back on with the body.
4. **A stray grey cell out in the gravel** from a trace of slump spill:
   `MIN_DRAW` (12% of a cell) below which nothing is drawn.
5. **The screed's "before" was a mirror.** Corner noise doubled and given two
   frequencies, and an unstruck cell's four facets each take ONE shade, so the
   lumps read as facets in colour as well as in light. (A first attempt made
   every unstruck cell its own tilted tile with steps between neighbours -
   round 3's loose paving slabs, back again - and was pulled the same hour.)
6. **The come-along's hint was off the bottom of its own shot**: `RakeView`
   hops 4.2 m behind the concrete's front now. **And the smoke test asserts
   it**: after `chute_hint_delay` with no finger, the pour's hint and the
   rake's hint must project inside the frame with a margin (`_hint_on_screen`).
7. **The heap stood behind the chute in the pour's wide** - moved a metre up
   the verge (the mailbox with it); the skid steer stops a little shorter of it.
8. **Every wide gave 40% to grass and 8% to the drive.** `WIDE` is closer and
   lower again with the look point on the drive's own middle.
9. **The tipper's eye was above the rail**, looking into the load: it is
   below the rail now, square behind, so the curtain falls against the earth.
10. **Loose material was flat cards.** Clods and base stones are lumps as tall
    as they are wide, tipped up to 25 degrees.
11. The bars' ground mark is a tint, not a second shadow; the evening reaches
    the sky's GROUND half, which is what the wide sees above the far lawn
    (`ground_horizon_color`); `broom_dry` 0.66 for a clearer coverage step.

Left: the HUD bar across the top; the opening WIDE's fused rings (that frame
is critic-only - play opens on PANEL, and WIDE never shows with rings up).

**And a real one the smoke test found on the re-run: the come-along could
plateau at 0.969.** The hint skipped any cell within a centimetre (10%) of
full, so a form of cells at 88-94% had no target and a child following the
arrow could never finish; the 0.975 pass in run 17 had been marginal. The
threshold is 2 mm now, and the rake draws from the two columns beside its own
as well (a stroke is a rake's width), so a column the chute starved is not a
column that can never fill. (`for dx in [0, -1, 1]` is an UNTYPED element in
GDScript and `var jx := ix + dx` is a parse error; `for dx: int in ...`.)

**Green after round 7's fixes: `SITE_SMOKE PASS 196/196`, `MACHINE_PROBE
PASS 13/13`.** Evidence for round 8 in `renders/critic/round8/`.


---

# Critic round 8 (2026-09-14, on `renders/critic/round8/`): 6.5/10, six phases to show a friend

No S1. Six of round 7's fixed, three improved, three not, one half. The
critic's headline was mine to own: **round 7's screed fix leaked into three
more phases as a CHEQUERBOARD.** The mottle's z coefficient (3.3) was within
0.16 of pi, so consecutive rows were in antiphase - not noise, a grid - and at
+-13% it swamped the water's 6% coverage step: the beat the design is proudest
of was scored on something the child could not see. Two systemic findings
worth keeping: *a fix aimed at one phase ships to every phase that shares the
surface* (the unit of a fix is "this cell state, in this beat"), and *the step
a beat is scored on must be at least twice the largest thing already varying
in the same picture* (round 7's colour rule, mirrored).

1. **The chequerboard.** Both z coefficients moved off pi (2.37, 1.81, 5.9),
   the colour mottle cut to +-4% about 0.90, the per-facet shade to +-3.5%.
   The height noise (the screed's mess) is kept; it is the colour that leaked.
2. **The water's step** is `wet_poured` 0.45 -> `wet_sprayed` 0.95 now, well
   above the surface's own noise; the broom's cell step is `broom_dry` 0.45.
3. **The stream was a lit grey post with a shadow.** UNSHADED (a lit solid
   turned from the sun rendered 26% darker than the pool it was a step lighter
   than), no shadow, 3.5 cm at the lip fanning to 11 at the landing, twelve
   sides; the splash disc halved and the landing made the event with sixty-four
   SHADED splat particles in the pool's colour.
4. **The tip threw three materials.** `_puff` takes `shaded`; the limestone
   curtain and the splat are lit like the ground they land on, in the base's
   own colour; dust, water and sparkle stay unshaded because they glow.
5. **The push dust was painted across the blade's face.** Emitted at the
   cutting edge 0.85 m ahead, thrown up and forward, so it breaks the blade's
   silhouette instead of crossing it.
6. **The chairs' lift was eight pixels.** 45 mm cradles (post, foot, saddle)
   under 20 mm bars, and `BARS` at a kneeling 0.95 m along the steel: air
   under every bar.
7. **Bars lying on placed concrete** - left as it is, on purpose: a cell at
   30% depth puts the pool below a bar on a 45 mm chair, and that IS the
   lesson (the concrete goes under the steel, then over it). The critic's
   "sink the bar with the pour" would draw the cheat the phase exists to
   correct.
8. **The payoff made the slab pine again.** `Driveway.set_cure_tint` takes the
   evening's warmth back off the slab's own colour as the sun sweeps.
9. **The rake receded to a sliver.** `RakeView` hops 3 m behind the front,
   the handle runs to `hand_hold` as the broom's does, and the head is a taller
   dark-steel blade.
10. **Two weak glyphs.** The skid steer's blade is joined to its body by a
    full-height push frame; the mixer has a ROUND drum.
11. Base stones are near-cubes tipped to forty degrees, a third buried; the
    bow wave stays inside the board's ends; the heap is a metre further from
    the mixer's chute (the mailbox with it).

Left: the opening WIDE's fused rings (critic-only frame); `08b`'s truck-filled
wide (the harness's `--nomachine` exists for exactly that).

**Green after round 8's fixes: `SITE_SMOKE PASS 196/196`, `MACHINE_PROBE
PASS 13/13`.** Evidence for round 9 in `renders/critic/round9/`.


---

# The user's third playtest, 2026-09-14 - five notes (and critic round 9: 6.5/10)

A real playtest outranks a critic round. The five notes, each with what it was
and what it is now:

| # | the note | what it was | what it is now |
|---|---|---|---|
| 1 | "one of the cement driveway sections didn't break... also this takes too long being 6 sections.. just make it 4 large sections" | a tap queued while the rings were being re-armed fell back to `done_in_step + 1` - a spot NUMBER counted from beats - which could name a spot already done; the bite was spent there, the count moved past the panel, its rings never lit again and it never broke | the panel being worked is `Driveway.current_panel()` - the first one still whole, by STATE - everywhere (the rings, the shot, the verb's fallback spot); and the drive is FOUR panels of 4.5 x 1.8 m (`PANELS_Z` 2), twelve bites |
| 2 | "the spread cement around took too long, it was hard to tell where I was supposed to spread it... make it obvious where to spread or once it's in place don't let me move any out" | the rake drew only from three cells toward the kerb, so the concrete had to be relayed up the form a stroke at a time; a full cell could be drained by a finger dragged over it; and depth had no colour | the rake draws from ANYWHERE in the chute's band (`rake_reach` 12) and only from that band or a cell's surplus - never out of a cell already at grade (`Driveway.rake_to`'s `band_z`); depth has a colour (`_drawn_col`: a shallow cell is tinted toward the base), so what is still to do is the sandy part; `rake_rate` 0.6, `pour_time` 18 |
| 3 | "same thing with spraying water... just progress player after spraying for so long, otherwise make it more obvious where they still need to spray" | a 94% coverage bar with a 1.05 m brush and a 3.6/s rate | `scrub_done` 0.85, `scrub_radius` 1.3, `water_rate` 6.0, `broom_rate` 4.5: a few sweeps cover the slab, and the wet step is 15% (round 8) |
| 4 | "camera issue after skid steer pushed 2nd rocks.. it wanted me to click something I couldn't see.. had to use space bar" | after the FIRST pass the machine stood at the heap, the `MACHINE` shot stayed on it, and the mark for the next pass sat on rubble nine metres away - off the picture. And the camera kept its HEIGHT, so a squarer window cropped the sides of every 16:9 composition | a pass ENDS with the machine lined up on the next lane inside the garage, camera on it and the mark on the rubble in front of its blade; and the camera keeps its WIDTH (`Camera3D.KEEP_WIDTH`, 79.3 degrees across = the same 16:9 picture as 50 up), so a 4:3 iPad sees more sky and foreground instead of losing the sides; the smoke test's ring checks want a 5% margin |
| 5 | "vehicles drive in too fast.. slow moving large trucks in a residential area... same with red car at end... and lug nuts aren't spinning" | `arrive_time` 3.6 s for fourteen metres; the car's wheels roll but its hub and five nuts are SIBLINGS of the wheel node on the fleet's vehicles (Car Garage screws them out along the studs), so they stood still | `arrive_time` 7.0, `leave_time` 6.0, `park_time` 7.5; `Machine` finds each corner's `Hub*` and `Nut*_*` and orbits them about the axle with the wheel (`_corner`) |

## Critic round 9 (on `renders/critic/round9/`): 6.5/10, five phases to show a friend

Their headline: **round 8 moved its two big faults rather than removing them**
- the chequerboard had left the mottle but was still in the FACET path (an
unstruck cell's facets took one flat colour, so neighbouring cells disagreed at
every edge), and the "lit solid beside a lit plane" trap round 8 diagnosed for
the stream was walked into again for the tip's curtain and the pour's splash
(both SHADED, both 30-50% dark). Two rules adopted: *a particle that IS a
material already on screen is unlit and takes that material's colour as sRGB*
(`_puff(matched)`, `vertex_color_is_srgb` - unlit with the colour read as
LINEAR was round 8's glowing disc), and *mess has to be OFF-GRID, not just
small* (the unstruck centre vertex is jogged inside its cell).

Fixed: F1 blended corner colours on unstruck facets + the off-lattice centre;
F2 depth tint (note 2); F3/F5 matched particles; F4 the curtain born further
behind the lip; F6 mud running down the extension while it pours
(`Machine.set_chute_mud`); F7 the bow wave is a capsule (rounded ends); F8 the
crossing's top at GRADE and the kerb DROPPED across the drive (no 9.5 cm step
for the car); F9 the ring threads the waiting bar (no +6 cm); F11 the push
dust inside the blade's width; F12 the skid glyph in profile with daylight
between body and blade, the sky's ground half is lawn-green (the wides had "no
sky"), and the broom has its own picture from the other side of the drive
(`BROOM`). F10 (the BARS camera not stepping in the posed frame) was checked
with a printed anchor: the eye IS at the pair's mark, 2.6 m off; the garage
merely looks close from a kneeling eye. Left as honest: bars standing proud of
a shallow pool.

Two things the smoke test found on the re-run, both from the rake redesign:
its old check that "raking nine metres from the concrete pulls nothing" is now
the opposite of the design (a drag anywhere draws on the heap), and the
"front" the rake's camera and hint stand on had to be redefined - it was the
apron-most row with a full cell, so one cell raked at the apron pulled the
camera to the apron with the hint under it; it is the KERB-most row with an
unfilled cell now (the edge of the work, measured from the heap), and the
camera may back into the open garage for the last row.

**Green after the third playtest's fixes and round 9's: `SITE_SMOKE PASS
196/196` (twelve bites, four panels), `MACHINE_PROBE PASS 13/13`.** Evidence
for round 10 in `renders/critic/round10/`.


---

# Critic round 10 (2026-09-14, on `renders/critic/round10/`): 6.5/10, SEVEN phases to show a friend

Their headline was the same systemic charge as round 3's, with three fresh
cases: **a fix is verified in the number it was written in, not in the pixel it
lands on** (the splash handed (140,143,152) and rendering 105; `pool_colour()`
reporting the material while `_drawn_col` draws something else; round 9's F10
cleared with a printed anchor while `09b` still framed the pair as the smallest
thing in the picture). Three more patterns behind what was left: a rule reaches
the instances that raised it and not the class (`_puff`/`dust_at` were still
"one soft dot for everything"); each round's fix reaches for a manufactured
primitive (capsule, cylinders, stools) when the one thing that looks like its
material is the heightfield itself; and cameras are placed against the work's
ANCHOR and never checked against its SILHOUETTE. Break-out, push, steel, water,
screed, joint and payoff were all "show a friend"; the pour and the come-along
were the least readable phases in the game.

What was done, in their order:

1. **The splash's rendered value (F1).** Measured in the frame, not the
   `Color`: the splat's dots rendered 0.25 grey on a 0.62 pool. Cause: a
   `ParticleProcessMaterial.color` is a source colour and reaches the shader
   already linear, and round 9's `vertex_color_is_srgb` converted it a second
   time. `_puff` converts once now (`matched` only means unlit), and the splash
   is a STEP LIGHTER than the pool (0.24) - a splash the pool's exact colour is
   no splash.
2. **The stream's colour (F2).** `Driveway.pool_colour_at(world)` is the
   pool's DRAWN colour under the spout, depth tint included; the stream and
   splash take it. Each of the four segments has its own material, a shade
   lighter down the stream, so they no longer fuse into one card.
3. **The pour's camera (F3).** `CHUTE` stands ABOVE the rim on the swing side
   (eye (-1.9, 2.5, 2.4) off `PourView`) and looks down INTO the trough: the
   concrete running off the end, the splash, and the form it fills. Three
   candidates were rendered side by side with a new `--eye=x,y,z --look=x,y,z`
   override on the shot harness; the side-and-above one read as a chute.
4. **The handle in the hands (F4).** `HandTool.aim_handle_at(hands)` scales
   the Body node (handle and bracket; its pivot is the head) along the tool's
   own Y and Z so the handle's end lands on `hand_hold` - rake, broom AND the
   jointer, posed and live. Where the handle ends is MEASURED off the mesh's
   box, not typed: the jointer's GLB was a build behind its builder, and a
   typed end stretched it to half way (found in the frame, not the number).
   The jointer is rebuilt with a 1.25 handle and its grip as its OWN node
   (`Grip`), which rides to the stretched end at its own size.
5. **The come-along's second half (F5).** The depth tint is square-rooted
   and stronger (`0.85 * sqrt(short)`), so a cell at 90% is plainly sandy and
   what is left to do has a colour to the end; `PULL` looks 3.4 m ahead
   instead of 4.6, so the road is a strip along the top and the pool is the
   picture.
6. **The bare-earth ribbon (F6).** The four banks are now turf AT GRADE
   before the cut and after the strip (`Driveway.set_banks(cut)`), filling the
   22 cm between the pad and the lawn's cut-out - the boards' 8 cm slot
   included, which the backfill never covered - and the earth trench outside
   the boards for the works. One function owns their shape.
7. **Stone and chips are lumps (F7, minor).** `_as_lumps` turns a puff into
   lit angular boxes, tumbling: the tipper's curtain (720 at 5 cm) and the
   bite's chips (70 at 6 cm).
8. **The verge and the footway (F8).** The lawn sliver between the pad's
   kerb end and the kerb line is gone; the crossing covers it.
9. **The bow wave out of the surface (F9).** `Driveway._build_wave_mesh`: a
   half-round ridge across the drive in the slab's OWN material
   (`material_override = _slab_mat`), vertex colours the unstruck mottle, the
   crest lumpy at the cell pitch so no highlight can run its length. The
   capsule is gone.
10. **Dust takes a colour (F10).** `dust_at(at, size, color)`: the sledge's
    dust is earth.
11. **Stakes in pairs ALONG a board (F11).** Ten stakes: four to each long
    board 2.2 m apart, two on the kerb board, none on the strip. `STAKE`
    is close from that board's lawn (eye 1.3 m out, 1.5 up, 1.9 along), the
    near peg big at the lower right and the far one up the board; the far
    board's pairs mirror the offsets (`flip_x` meta on the group mark, read by
    `CameraRig`), and the kerb pair carries its own offsets (`shot_eye` /
    `shot_look` meta) because it lies across the drive. Job data asks ten taps.
12. **The wides have a horizon (F12).** `WIDE` is 3 m up instead of 4.1,
    looking at the drive's middle at grade: the sky is a seventh of the frame,
    the house and garage stand up, the lawn is about a third.
13. **Minors.** The skid glyph has a cab with a window and wheels with hubs;
    the heap is 0.7 m further in (`PILE_X` 6.9) and in every wide; the left
    cone is on the footway well left of the drive and out of the wides'
    bottom-centre, the right one nearer the drive; the brush lines darken
    8.5%; the HUD bar is FULL at `done` and `parked` (the pose runs past the
    last step, so no arrow either); the render harness's `14_broom_hand` is
    the `BROOM` shot at last.
14. **Round 9's F10 as a picture.** `BARS` is from the UNLAID side, close and
    a little above the pair (eye (-0.6, 1.25, 1.7)), so the two bars being
    laid span the frame with the chairs under them and the laid steel beyond.

Left as decided: bars standing proud of a shallow pool; the mixer's cab in
`08b` (`--nomachine`).

**Checked in the frame before the smoke run:** the splash's dots light on the
pool, the stream a pale column, the rake and broom handles running off the
bottom of the frame, turf to the slab's edge in the first and last wides, the
skid glyph a machine, the bar full at the payoff, the ridge in front of the
screed board in the surface's colour.

Two things the smoke test found on the re-run: the push's stop at the heap
was measured from the heap, so moving the heap in put the machine's tail back
over the excavation and it sank (the stop is a machine-length clear of the
pad's ramp whatever the heap's distance); and the close BARS picture cannot
hold the four long bars' rings (that group carries its own offsets, further
back and square to the drive).

**Green after round 10's fixes: `SITE_SMOKE PASS 198/198` (ten stakes),
`MACHINE_PROBE PASS 13/13`.** Evidence for round 11 in
`renders/critic/round11/`.


---

# Critic round 11 (2026-09-14, on `renders/critic/round11/`): 6.5/10, five phases to show a friend

No S1, the strongest frame set yet, six of round 10's twelve findings cleanly
fixed (the splash's value, the handles into the hands, turf to the slab's
edge, lumps for stone and chips, earth dust, the stake pairs, the wides'
horizon, BARS close on the pair, the skid glyph, the cone) - and the score
held because **the come-along climbed out of the cellar and the pour fell
into it on the same fix**: round 10's square-rooted depth tint put a half-deep
cell 60% of the way to the base's own colour, so fresh concrete landed 1-3%
from the gravel it was poured on and the centrepiece had no picture. Their
systemic list: a fix scoped to one beat's symptom is applied to the shared
surface; verification still stops one step short of the eye (the bow wave was
cleared on an asset property - "same material" - and rendered 0.37 grey inside
the board's own shadow); a camera moved for one reason is never swept for what
else its frustum now holds (the new CHUTE eye found the mixer's hopper hanging
in the air; the close BARS eye threw waiting bars over the lawn; the JOINT eye
left the jointer's head a 35 px speck); everything the hand leaves is drawn on
the cell grid (the brush marks tiled into running bond and the finished drive
read as block paving); "waiting" is posed in metres and judged in world space.

What was done, in their order:

1. **The pour has a picture (F1).** The depth tint is linear and capped
   (`0.35 * short`): a half-deep cell is 17% toward the base, not 60%, and
   fresh concrete is grey against the tan it lands on. What is left to do is
   carried by shape as well - the base's loose stones stand proud of a thin
   skin until the pool rises over them.
2. **The bow wave tops the board and is lit (F2).** `_build_wave_mesh` is
   0.14 m high, its normals lean up so it takes the surface's light, its
   vertex colours are the DRAWN colour of the cells under it (wet, mottled),
   and its material is the slab's own with `disable_receive_shadows`, so the
   board's shadow no longer turns it into a slot. Checked in the frame: the
   roll is the slab's grey, heaped, with a crest above the board's line.
3. **Nothing floats beside the chute (F3).** Found by projecting every
   visible mixer mesh to the screen: the "yellow slab" was the chute's own
   mesh - the hopper above the pivot and the swing post beside it share a
   surface with the trough's rails. `Machine._clip_hopper`: while only the
   chute is drawn, a discard shader on `ChuteMesh` cuts both surfaces above
   the pivot and the yellow one within 0.28 m of it; with the truck back the
   surfaces are their own again.
4. **The broom finish is a broom finish (F4).** `Driveway._brush_lines(i,
   dir)`: a few long thin streaks per cell ALONG the stroke (the handle's
   direction, square to the head), each longer than the cell and set off
   along its length at random so neighbouring cells' marks interleave,
   clipped to the panel between the boards and the joints (`_clip_span`).
   `paint_broom` takes the stroke direction from the verb. And `BROOM` moved
   to the SIDE of the drive, so a stroke toward the child runs across the
   slab the way a crew leaves it.
5. **Waiting bars stay over the base (F5).** `bar_drop_height` 0.16 m: from
   the close BARS eye a 32 cm lift threw a waiting cross bar's image half a
   metre out over the lawn, ring and all.
6. **The jointer is a tool (F6).** Its head is a SLED - a 0.15 x 0.24 plate
   with both ends stepped up over a bead along the travel - rebuilt in
   Blender; the `JOINT` shot is anchored to the jointer itself
   (`shot_anchor_override`), so the eye walks along the joint behind the head
   with the groove running out from under it and the handle in the hands.
7. **The heap (F7).** `PILE_X` 6.6, `PILE_Z` 2.6 - beside the drive's middle,
   off the footway and the tree's planter, inside every wide - compact (r
   1.15) and its pieces tipped 12 degrees instead of 30 so the tops face up
   and it is the same pale rubble as on the drive. The CHUTE frame now sees it
   on the lawn behind the trough; that is honest.
8. **The forms show a face (F8).** `FORM` is from the near board's own lawn,
   low, looking across the drive: the near board's face runs across the lower
   frame, the far one beyond; the kerb board and the strip get the same
   offsets face-on from the road and from inside the drive.
9. **The stake pair (F9).** Eye 1.1 m out and 1.3 up, looking 1 m further
   onto the pad: lawn from 43% to about a third, the board carrying the
   bottom of the frame.
10. **The push dust (F10).** Thrown FORWARD and low off the cutting edge
    (direction (0, 0.5, 1), 1.0 m ahead, 2 cm up, smaller), so from the
    machine's eye it stays under the blade's top line.
11. **The bar is full at the payoff (F11).** The render harness posed `done`
    and `parked` at the broom's step by default; both end states now pose
    PAST the last step (`pose_at(steps.size())` credits the whole job and
    tells the bar).

Also: the mixer's machine key in two debug prints was wrong ("mixer" for
"ConcreteTruck"), which is why an earlier spout print never appeared.

**Green after round 11's fixes: `SITE_SMOKE PASS 198/198`, `MACHINE_PROBE
PASS 13/13`.** Evidence for round 12 in `renders/critic/round12/`.


---

# Critic round 12 (2026-09-14, on `renders/critic/round12/`): 6.5/10, six phases to show a friend

The cleanest clearance so far - seven of round 11's eleven fixed, four
improved, none regressed - and the score held because the faults left were
concentrated in one phase: the pour and its come-along, plus the jointer. Two
of them were pendulums of my own making, and they named the rule: **one number
serving two beats with opposite needs swings back every round** (the depth
tint: square-rooted for the rake, capped for the pour, each killing the other;
the bar lift: 0.32 for the picture, 0.16 for the parallax, the picture gone).
Their other patterns: a fix that removes geometry leaves a hole nobody looks at
(the clipped hopper's uncapped face; the chute with no shadow); value is still
chosen in the asset and read in the frame (the heap at half the rubble's value,
the sled at 0.92); a camera moved for one reason is never swept for what else
it holds (JOINT's 39% lawn, the heap in four working frames' corners, the rake
half out of its first frame).

What was done, in their order:

1. **The pour has an object (F1).** Both of the chute mesh's surfaces end at
   the same plane toward the pivot (the liner ran on and its end showed as a
   pale face), the dark liner is lifted to a wet-steel grey, the extension's
   trough likewise, its mud sits proud of the floor, and the truck's chute
   CASTS its shadow again (the hopper is clipped from the shadow pass too);
   the extension over the pool does not, or the shadow was a blob under the
   spout. `CHUTE` is higher and nearer (eye (-1.1, 3.1, 2.6)) so it looks INTO
   the extension's trough, not at its outer wall.
2. **The stream and its landing (F2).** Thrown two thirds of the way out
   along the chute before it falls, 0.15 m at the landing, and the landing is
   a TONGUE stretched along the stream's line (the splash disc, 0.20 m,
   scaled 1.8 along the flow) with a little spatter, not a ring of balls.
3. **The pour's hint (F3).** The arrow only stands on a cell under HALF full
   - one that looks short - never on concrete that is plainly there.
4. **Two cues (F4).** `_drawn_col`: a fixed sixth of the way to the base for
   any cell more than 6% short - a hard done/not-done edge, the same step the
   water has - plus a mild slope for how short. The come-along's last third
   has an edge again and the pour's fringe is a fringe. And the last few per
   cent SETTLE to grade as the come-along's beat ends (`Driveway.settle`), so
   no sandy patch is left under the hose.
5. **The rake in the frame (F5).** Between strokes the rake rests at the
   hint and follows it; the pre-beat ring, the posed rake and the live hint
   all stand on one point (`SiteMain.rake_hint`, which the runner's arrow
   uses for this verb); the target is inset from the boards.
6. **The jointer (F6, F7).** The sled is STEEL (0.42) with a dark bit standing
   out of the groove behind it; `HandTool.align_head` turns the sled about
   the tool's own axis to lie ON the line it cuts while the handle still runs
   to the hands; `JOINT` is anchored to the jointer from BEHIND it down the
   drive (eye (0.3, 1.5, 2.2)) - the sled 2 m ahead with the groove through
   it and the garage beyond, not the far lawn.
7. **The tip (F8).** `TIPPER` from the rear quarter (eye (-3.0, -0.5, -2.6)),
   so the stone falls between the eye and the open earth.
8. **The heap's value (F9).** A piece on the heap casts no shadow (stacked,
   every side was in the shadow of the piece above): 0.44 in the water frame
   against 0.29-0.35 before, the drive's rubble at 0.48-0.53.
9. **The screed bears on both forms (F10).** `screed_saw` 0.05: a 3.7 m
   board sawing 14 cm across a 3.76 m form left one end short of its board
   and the other over the turf.
10. **A waiting bar is out of LINE (F11).** It lies on the grid a hand's width
    beside its place, skewed 12 degrees and lifted 6 cm, and swings into line
    as it goes in (`Driveway.set_bar`, `bar_wait_point` for the ring) - a cue
    no eye can miss and no parallax can throw over the lawn.
11. **The payoff on the car (F14).** `PAYOFF` is anchored to the car, down at
    a child's height at its rear quarter.

Left: the close shots' lawn share in `01` and `04` (they read well, the
critic said); the chunks meeting the skid steer's tyre (F13, small).

**Green after round 12's fixes: `SITE_SMOKE PASS 198/198`, `MACHINE_PROBE
PASS 13/13`.** Evidence for round 13 in `renders/critic/round13/`.


---

# Critic round 13 (2026-09-14, on `renders/critic/round13/`): 6.5/10, seven phases to show a friend

Seven fixed, three improved, one moved, one regressed - and two of the four
faults left were regressions manufactured by round 12's own fixes. Their rule
this time: **a cue authored in ONE unit shipped to objects of another size** -
a 12-degree bar skew was 0.34 m at the end of a cross bar and 0.90 m at the end
of a long one, so two of the four long bars crossed in an X. And its cousin:
feedback authored at CELL scale photographed at TOOL scale (the screed's
unstruck side measured 1.6% peak to peak from the kneeling eye; the pour's
5 cm mound never moved a profile). The pour, for the fourth round, was the one
phase where a child could not see the material arrive: the stream a step
lighter rendered +6%, the tongue +1-4%, the mound 0.0%, and the chute's own
shadow -34% - the loudest shape on the pool was a hole.

What was done, in their order:

1. **The pour has a material (F1).** The chute casts NO shadow again while
   the truck is not drawn (round 12 put it back; round 13 measured it as the
   highest-contrast shape on the fresh pool). The stream is DARKER than the
   pool - wet mud in the air against concrete settling pale - a quarter
   down, and its landing has a dark wet RIM (a wider, thinner disc under the
   tongue): an edge, not a value tuned a step off the pool. The mound under
   the spout is 13 cm over a metre (was 5 over 0.7) so a profile across the
   landing moves.
2. **The bar skew is a distance (F2).** `BAR_SKEW_END` 0.20 m: the yaw is
   `asin(2 * end / length)` per bar, 2.6 degrees on a long bar and 7 on a
   cross bar. And a waiting bar lies toward the drive's MIDDLE (the long
   ones by 0.14 m, the cross ones by 0.24) so no bar waits over a form and no
   two neighbours move toward each other.
3. **The tip's curtain falls against the earth (F3).** `TIPPER` from ABOVE
   and behind the tailgate (eye (-0.8, 2.8, -3.0)), looking down: three
   candidates rendered side by side - the quarter, the side and the high
   eye - and only the high eye put the stone between the eye and the ground.
4. **The screed's unstruck side is lumpy (F4).** While the screed is on the
   slab (`_wave_z` set) the lump and the corner noise are 2.4x, and only
   then, so it cannot leak into the water beat: 1.6% peak to peak became
   5.9% in the same patch.
5. **The sled is dark steel (F5).** The "Disc" grey (0.30): plain Steel
   rendered 9% from the slab, pale Metal 58% over it. Measured in the frame:
   0.34 against a 0.58 slab.
6. **The joint's lip (F6).** A hair above the live colour (+0.03, not +0.10:
   the lit lip rendered 27% over the slab and read as tape).
7. **The water has a shape (F7).** A wet EDGE: where coverage is part way -
   the rim of the wetted patch - the cell is darker still, so the patch has
   an outline. And PUDDLES: a cell wetted through holds a small pool of sky
   in a low spot until the screed strikes it or the broom dries it.
8. **The heap is loaded out with the tipper (F8).** It fades as the dump
   truck leaves (the muck-away is off screen) and the steel, the pour and
   the finishing are worked on a clear site; the posed stages from `based`
   on have no heap.
9. **The close shots (F9).** `PANEL` is nearer the drive's line and looks
   further onto it (lawn 42.9% to 39%); `MACHINE` a shade nearer.

Left: the clipped chute's ragged bite at the pivot (F10, below tablet
visibility); the green sliver at the garage threshold from the stake eye
(F11); the form's waiting pose (F12, judged a motion cue).

**Green after round 13's fixes: `SITE_SMOKE PASS 198/198`, `MACHINE_PROBE
PASS 13/13`.** Evidence for round 14 in `renders/critic/round14/`.


---

# Critic round 14 (2026-09-14, on `renders/critic/round14/`): 6.5/10, seven phases to show a friend

Six fixed, one improved, no regressions - and the eighth 6.5 in a row, pinned
by one phase. Their headline was the sharpest yet: **the pour's fault has never
been a value, and it has been answered with a value seven times.** What the
child looked at while the chute ran was a 0.318 navy trough holding nothing,
with the falling material hidden behind its own near wall from the CHUTE eye
- and the dark wet rim round 13 drew by hand was the same hole the chute's
shadow had been. Their other patterns: colour is matched but light is not (the
joint's lip, `_base_col.lightened(0.03)` by the number, rendered +27% because a
flat up-facing face takes 1.4x the sun the tilted heightfield takes); a cue
with no LUMA is not a cue (the come-along's done/not-done was a warmth step
with zero luma and vanished once the base was covered; the water's -13% luma
step reads); a cue honest in world units can read as the wrong thing (0.14 m
of offset on a 9 m bar read as uneven spacing); a camera moved for a reason
is still not swept for what else it holds (PAYOFF on the car put the hatch's
interior against the sky).

What was done, in their order:

1. **The pour is composed (A1, A9).** `CHUTE` stands BESIDE the chute's
   line, above the rim and ahead of the pivot (eye (-2.2, 3.0, 2.6) off
   `PourView`), looking along it - five candidates rendered side by side -
   so the stream falls off the lip in front of the trough, not behind its
   near wall. The landing is a lit CREST: a faceted dome in the slab's
   material, a step lighter and warmer than the pool, that stands where the
   concrete lands (`Driveway._build_dome_mesh`); the dark wet rim is gone
   and nothing dark is drawn on the fresh pool again. The stream is warm
   wet mud a shade under the pool.
2. **The chute holds something (A1).** The extension's trough is lifted to
   0.52 and the truck's liner to a wet grey; the mud running down both takes
   the pool's own WARM colour every frame (`Machine.set_chute_mud_colour`).
3. **The come-along has a luma edge (A2).** A cell more than six per cent
   short is drawn toward DARK wet mud (`SHORT_COL`, 0.40/0.37/0.32), 40% of
   the way plus a slope: a rendered step of the water's size, not a warmth.
4. **The joint is a groove (A3).** The pale lip is gone: the groove's own
   dark at 0.30 on a 0.59 slab already reads as a cut, and a lit flat face
   can never be signed off by its albedo.
5. **The payoff is swept (A4).** `PAYOFF` side-on to the car (eye (-3.6,
   1.0, -0.4)): the whole car, the joint and the broom lines under its
   wheels, and no hatch interior against the sky.
6. **The long bars wait in line (A7).** No sideways offset for a long bar -
   0.14 m on a 9 m bar read as uneven spacing - and its end swings 0.35 m
   (4.6 degrees) so the four fan visibly; the cross bars keep their 0.24 m
   and 0.20.
7. **The garage threshold (A8).** The lawn strip behind the drive ends
   0.3 m short of the apron: its front face was coplanar with the garage
   floor's and the two z-fought as a green band across the door opening.

Left as decided: the tip's first 1.5 m of fall against the bed's underside
(A5 - the curtain is 85% clear of the truck, the moment of discharge is not);
the water's rim (A6 - the puddles carry it); the HUD bar over the breaker's
head; the kerb board's stake stubs on the crossing (honest).

**Green after round 14's fixes: `SITE_SMOKE PASS 198/198`, `MACHINE_PROBE
PASS 13/13`.** Evidence for round 15 in `renders/critic/round15/`.


---

# Critic round 15 (2026-09-14, on `renders/critic/round15/`): 6.5/10, six phases to show a friend - THE LAST CRITIC ROUND

Five of round 14's nine cleared with measurements (the joint's groove with no
lip, the threshold's green band, the CHUTE eye with the stream in front of the
trough, the payoff swept, the long bars in line); the come-along's luma edge
was not in its frame, and the pour swung again: round 14's crest under the
spout swallowed the stream's last segment and its splash (the stream landed
at the pool's surface INSIDE a 0.12 m dome), the crest rendered +40% where
+12% was written (its facets' normals leaned at the sky, the same trap round
14 had named for the joint's lip), and the eye on the swing side showed the
chute's outer wall with no mud in view. Their systemic read: the pour is a
compositional pendulum - nine rounds of fixes each correct in isolation, each
moving the fault one surface along - and no frame has yet held all four of an
open trough with mud, material falling, material arriving, and the form
filling at once.

**The user stopped the critic loop after this round** (2026-09-14) and sent a
fourth playtest instead - ten notes, logged in the next section. From round
15 only the cheap, certain pair was taken: the stream lands ON the crest
(`Driveway.crest_top`), and the crest's facets lean up 0.25 instead of 0.7 with
a +6% lift, so it is lit like the slab it is heaped from. Everything else in
the round-15 list (the chute's open side, the come-along's edge in its own
frame, the chairs' lift from the close eye, the tip's black underside, the
40% lawn, the minors F8-F15) is recorded here for whoever picks the loop up
again.


---

# The user's fourth playtest, 2026-09-14 - ten notes, and the critic loop stopped

After round 15 the user stopped the critic reviews and sent ten notes. Each,
with what it is now (the code, the shot or the number that answers it):

| # | the note | what it is now |
|---|---|---|
| 1 | "stop the camera from swaying constantly" | `CameraRig.DRIFT` false: no shot orbits; the drift numbers are kept on the shots, unread |
| 2 | "video flashing where form board meets garage" | the expansion strip (`Form_4`) stands ON the pad 6 mm proud, flush against the garage floor (it was buried in the floor with its front face on the floor's front plane - a same-facing coplanar pair); the garage's walls and jambs stand on the floor's top; the kerb crossing starts behind the kerb board; the apron bank sits 1 cm into the garage |
| 3 | "vehicles too loud" | `Sfx.group_gain_db`: dieselidle / mixerdrum / idle / drive -9 dB, hydraulic -5, rubblepush / gravelpour -4; the tools untouched; the dead `SiteConfig.idle_db` deleted so nothing can stack |
| 4 | "pick a camera angle that isn't blocked when you dump rock" | `TIPPER` from the truck's side, rear quarter, 2.1 m up (eye (-4.4, 2.1, -2.6) off the tailgate): bed, tailgate and falling stone, nothing of the truck between |
| 5 | "improve bottom left icons ... low poly like key in garage crew" | `PropIcon` ported from Car Garage (`scripts/prop_icon.gd`, with `attach` and `pose` keys added), `MachineIcons` specs: the skid steer with the push blade attached under its bucket pin (the bucket masked), the tipper bed -46 / tailgate -62, the mixer's chute folded out and its white body a step darker for the cream disc; `SiteHud._build_go` dresses the button with all three and `set_call_glyph` toggles them; `TruckGlyph` is the fallback; the smoke asserts `call_is_modelled()` |
| 6 | "add idle white arrows" | Car Garage's `HintArrow` ported into `SiteHud` (white, dark rim, mimes TAP / HOLD / DRAG), `hint_tick` clocked from `SiteMain._process` with `_hint_kind()`; wakes on press, release, a 6 px drag, GO, a pad or stick; the ring stays, the pointer's gold arrow steps aside (`SpotRings.set_arrow_shown`); the smoke asserts it appears white over a ring after the delay and goes on a touch |
| 7 | "improve drag board across touch" | `screed_pull` is a DRAG through `_scrub` with `done` 0.995: the board's line follows the finger's z, monotonic, at `screed_drag_speed` 2.2 m/s; the finger's x is the saw; the eye eases after the board between strokes (`ease_screed_view`) or under a world cursor (`drag_is_world`) |
| 8 | "you should pull to make the joint lines not just hold down" | `joint_cut` is a DRAG: the sled follows the finger's x from the near form, `cut_joint(i, k)` follows the sled; `JOINT` is anchored to the joint's marker (not the tool) so the ground never moves under the finger |
| 9 | "broom finish move camera so you do it 3 times, once per concrete square, camera lined up on the side" | broom step count 3; `broom_finish` scopes `paint_broom` and its coverage to `Driveway.bay_range(bay)`; `BROOM` anchored to `bay_marker(bay)` from the -X side square to the drive; the marks follow the finger's own motion (a hand's width at a time) |
| 10 | "final shot no good, need a better shot zoomed out" | `PAYOFF` off the slab from the kerb corner (eye (-5.8, 3.2, 7.0)): the whole drive with the car |

Also from round 15's list, the cheap certain pair: the stream lands on the
crest's top (`Driveway.crest_top`), and the crest's facets lean up 0.5 with a
+10% lift - measured in the frame at +12-15% over the pool at the same depth,
the stream a quarter darker.

The smoke test grew for the drags: a finger held still at the apron does not
move the board; `_drag_along` walks the cursor from the apron to the kerb and
the beat ends; each joint is pulled across with `joint_k`; three bays swept in
turn with `_sweep_range`, each bay unbrushed until its own beat.

**Green after the fourth playtest's ten changes: `SITE_SMOKE PASS 218/218`
(the idle arrow, the modelled call button, the two drags and the three bays
all asserted), `MACHINE_PROBE PASS 13/13`.** Frames for the record in
`renders/critic/playtest4/`.

## The verification pass (eleven reviewers, one per note plus a sweep)

An adversarial review of the ten changes against the code and the frames
found, and this batch fixed:

- **The drags chased a resting finger** (notes 7, 8): `want = clamp(finger,
  tool, end)` moved the board or the sled toward any finger ahead of it, so a
  still finger at the kerb struck the whole slab in four seconds - the hold
  again, further along. A tool moves only when the finger is ON it (within
  `drag_grab` 0.9 m), and it goes where that finger goes. `_scrub` treats an
  `on_point` that answers false (no hold of the tool) as a resting finger, so
  the loop sound stops and the idle hint can come. The hold carried from the
  previous beat (the runner keeps a HOLD step's finger) no longer cuts joint 2
  or walks the board during the camera's ease, because the finger is not on
  the tool. The smoke asserts a finger resting ahead of the board and at the
  far form moves nothing.
- **The DRAG beats' arrow stood on a marker behind the eye**: the runner's
  `target_world` asks the level for `drag_hint(verb)` - the board's line, the
  sled at the near form, the bay's roughest cell.
- **Two arrows over one ring** on a rings beat's last ring: the level's own
  rings stand their gold arrow aside while the white one is up.
- **The white DRAG mime swiped across the screen** for beats whose stroke runs
  down it (the screed, the broom from the side): `hint_tick` takes a swipe
  axis per verb.
- **The call button showed the wrong machine while asleep**: it shows the
  machine the NEXT call brings (`_next_call_verb`); a drawn glyph stands in
  per missing model, not only when all three are missing.
- **The GO ring was lost when the last bite's mute outlived the step change**;
  the level re-asks for the arrow when the mute lapses, and points at NEXT
  while celebrating. A hold paused mid-beat gets its arrow back.
- **The payoff's car arrived off-frame** from the pulled-back eye: the arrival
  is watched from `STREET`, the cut to `PAYOFF` comes as the car turns in, and
  the car starts facing the way it drives (no spin on the spot).
- **The kerb crossing's slot showed turf** across the drive's end in the old
  and parked stages once the crossing started behind the board: the kerb bank
  is the crossing's grey when it is not cut, and the crossing starts 1 cm
  behind the cut bank's face.
- **The broom was worth nine stops** (count 3 x weight 3): one per bay.
- Marks are not laid until the finger has moved (the first-touched cells took
  the hands' direction); the tipper eye moved 1.6 m toward the kerb so the
  garage roof does not cross the lip at the start of the tip; the posed
  second joint and later bays show the earlier ones done; "boing" and the
  concrete's pour loop joined the vehicle trims; the pull-up's clipped master
  sits at -12.

Left as found and recorded: the `Tailgate` anchor dips 0.33 m as the bed
lifts (anchor the tipper's eye to the bed pivot if it reads); a second finger
lifting ends a drag (`_unhandled_input` ignores touch index); the wedge can
land nearer another live ring when it flips below; a tap on the wedge on a
rings beat nudges instead of biting.

**Green after the verification pass: `SITE_SMOKE PASS 221/221`,
`MACHINE_PROBE PASS 13/13` (2026-09-14, the end of the session).**


---

# The improvement plan's first session: Tier 0 (2026-09-15)

`docs/IMPROVEMENT_PLAN.md` (the ten-lens review of 2026-09-14) is being built
in the order it suggests. This session is its Tier 0, "stop the bleeding":
six fixes, none of them a design decision, and the smoke grew by 31 checks.

1. **The house button is off the screen while a job runs (0.1).**
   `SiteHud._hide_borrowed_controls` hides it with the ignition key;
   `_celebrate` brings it back beside NEXT once the car has parked, where
   starting again is all it can mean; and `SiteMain._on_home` refuses the
   reload while `runner.finished` is false, so no route reaches it from a
   running job. One tap on the biggest green thing on the screen used to throw
   sixty stops away.
2. **NEXT no longer frees a playing AudioStreamGenerator (0.2).** Car Garage's
   2026-09-13 fix ported to `Sfx`: the fallback synth builds an
   `AudioStreamWAV` per sound and plays it from its own player; `_pb` and the
   generator are gone. The smoke walks the site's players and asserts none
   streams a generator, then frees the whole site with a loop and a one-shot
   running and builds a second driveway on top - the free NEXT does, stood in
   for because reloading the current scene from inside the test would reload
   the test.
3. **One finger owns the beat (0.3).** `SiteMain._unhandled_input` tracks the
   touch index: the first finger whose press is ACCEPTED takes the work; other
   fingers landing, dragging or lifting while it is down are ignored (they
   still get the white tap ring); only its own lift ends the hold; and
   `NOTIFICATION_APPLICATION_FOCUS_OUT` lets go of everything. `_press`
   returns whether it accepted the press. The smoke pushes real
   `InputEventScreenTouch` / `ScreenDrag` events with indices through
   `push_input(ev, true)` (local pixels, the ones `unproject_position`
   gives): a second finger lands on the lawn and lifts, and the hose keeps
   running under the first.
4. **A kept tap keeps its ring (0.4).** A tap that lands while a bite is
   running is queued by the runner; `SiteMain` now keeps WHICH ring it landed
   on (`_queued_pick`, for `_queued_pick_step`), `arm_rings` restores it if
   that ring is still live, and drops the queued tap
   (`JobRunner.drop_queued_tap`) when it is not - the ring was the one just
   worked, or the step moved on (a board's ring must not drive a stake). The
   smoke presses the second slab's first ring, then its last while the hammer
   runs: the hammer walks to the last, not to the first open spot in the
   middle.
5. **The white wedge is a target (0.5).** `SiteHud.arrow_hit` tests the
   wedge's whole BODY - a point-to-segment test from the touch point along the
   direction it was drawn (`_hint_body`, remembered at draw time because
   `_aim_at` is re-solved every frame and INF between frames on a rings beat)
   - and `_press` asks it BEFORE the wake that takes the wedge down. On a
   rings beat a press on the wedge with no ring in reach works the ring the
   wedge stands over; a ring in reach of the finger still wins, since any ring
   on the slab is a right answer. The smoke finds the wedge on the third slab
   and presses its far end.
6. **The truck does not teleport (0.6).** `pour_chute` waits for the eye to
   arrive at the chute before it hides the truck (the drum already turning
   during the flight down); `rake_pull` no longer makes it whole at its end,
   and `mixer_leave` FADES the body in over the eye's ease out to the wide
   (`Machine.body_meshes` + `Driveway.fade_node`, the chute left alone). The
   plan's wording was "keep it hidden until the wide has settled"; in the log
   that only moved the pop to where the truck is biggest, and a body coming up
   out of nothing while the picture is moving is the gentlest the user's own
   trick can be. The smoke asserts the drum drawn while the eye flies in and
   hidden once it has arrived; drawn but under half alpha while the eye eases
   out, and opaque once it has settled.

**What the smoke itself taught, three lessons:**

- **A frame count is not a wall clock.** The pour's hint check waited
  `chute_hint_delay / 0.006` frames; on a faster machine that is less than
  the delay, and the check had only ever passed by the frames happening to run
  at the right speed. Both hint waits are `create_timer` seconds now.
- **The pour's hint has a window.** It stands only on a cell under half full
  (round 12), and with the chute parked the whole kerb band is over half
  within about four seconds of pouring - so a check placed after seven
  seconds of pad tests was asking for something the rule rightly refuses. It
  is checked first now, with the delay shortened for the test (0.8 s) the
  way the white arrow's is, and a pad press is asserted to take it away.
  `scenes/dev/pour_probe.tscn` (`BC_DEBUG=1`, thirty seconds) is how this
  was found: it poses the site at the mixer call, presses GO for real and
  prints what the beat's rule sees every half second. Keep it for the pour.
- **A lambda's flag is a copy.** The push phase's ride-height watcher looped
  on `while watching` with `watching` a local bool; the flip to false never
  reached it and it ran for the rest of the test - and on into a freed site
  once a second driveway was built. A one-element Array now, the rule Car
  Garage already paid for.

Also corrected in the plan while reading the code: 1.3 claimed all three rings
vanish on a tap; `hide_arrow` clears the POINTER's single ring, not the
level's set, so the rings stay lit through a bite and what is missing is only
an answer at the ring that was pressed.

**Green: `SITE_SMOKE PASS 252/252` (was 221), `MACHINE_PROBE PASS 13/13`
(2026-09-15).** Frames in `renders/critic/tier0/`.


---

# The improvement plan's second session: Tier 1, and 2.1 / 2.4 / 2.5 (2026-09-15)

The plan's "session that changes how the toy feels under a finger". Eleven
items, one new sound, and the smoke grew from 252 to 276 checks.

**Tier 1 - every touch answered.**

1. **The tap is heard in the frame it lands (1.1).** `sound = "whoosh"` on
   the hammer's and the sledge's rows of `new_driveway.tres`; the runner
   already played that field before the verb, so the flying tool is heard at
   the tap and the breaker loop and the sledge blow land on top. No verb code.
2. **A miss is heard, and it hurries the mime (1.2).** `SiteMain._press`
   splits into accepted presses (`_accept`: the white arrow's clock restarts)
   and misses (`_miss`: one `pop`, at most one a quarter second, never a
   buzzer; `SiteHud.hint_hurry` runs the clock FORWARD - one miss brings the
   mime a second early, a second miss inside three seconds brings it at
   once). A release after a miss, and a miss finger's wandering, no longer
   wake it either. On a rings beat the nearest live ring throbs ONCE
   (`SpotRings.nudge_nearest`, 1.45x easing back over half a second) instead
   of the whole set wobbling faster; the pointer's single ring throbs the same
   way. A finger on the ring already being worked - a mash - is not a miss.
3. **The picked ring snaps out; the others stay (1.3).** `SpotRings.take(id)`:
   out to 1.6x and gone over 0.15 s the frame the tap is accepted, tracked
   per ring so two kept taps do not fight; `pick_nearest` skips taken rings
   unless asked. (The plan's claim that all three vanished was corrected on
   09-15: the pointer's ring is a separate set.)
4. **The sledge and the breaker kick the camera (1.4).** `shake_stake` 0.08
   -> 0.38, `shake_break` 0.22 -> 0.60, and a FLOOR under the trauma while a
   bite runs (`CameraShake.hold_floor`, `shake_jack_floor` 0.28) so the picture
   rattles for as long as the bit is in the concrete. Measured off the camera
   in the smoke: a sledge blow moves the picture 10 mm at its peak (it was
   under 2 mm) and is still again inside 0.6 s. The plan's 0.02 m guess
   ignored the noise's own amplitude; ten millimetres at the STAKE eye is a
   visible kick, and the number is in `site_config.gd` if it wants to be more.
5. **The panel bursts (1.5).** `Driveway.break_panel` starts every chunk
   `chunk_hop` up (the outer ones 1.3x, so it bursts outward from the bite),
   each a few milliseconds after the last, and bounces them down over
   `chunk_hop_time` with a little roll; the pose path passes `animate =
   false`. The chunks lie exactly where they always did (the hop has its own
   seeded numbers). Measured: 0.18 m of fall on the first slab.
6. **One "done" note, and the picture holds (1.6).** A fifteenth clip, `done`
   (ElevenLabs, two takes: a soft warm two-note wooden marimba tap), played
   from `SiteMain._on_step_done` for every step the bar counts except the
   last, whose done is the tada; the pour's and the rake's ad-hoc chimes are
   gone, so the chime is only the parked car. `JobRunner._play_beat` awaits
   `level.phase_done(step)` on a step's last beat: the tool flies back to its
   rest and the shot HOLDS for `phase_hold` (0.8 s) before the next is asked
   for. Each finishing verb finishes its own material first: the water's dry
   corners wet themselves over 0.6 s (`Driveway.finish_water`), the screed
   board comes up off the kerb form with a thunk, each broomed bay takes its
   last lines and dries over 0.5 s (`finish_bay`) as the broom lifts. The
   smoke records what was heard at every step's end: eighteen steps, none
   wrong.
7. **Engines lean into the work (1.7).** `SiteVerbs._hold` takes an
   `engine_voice`: while the beat flows the idle drops to `engine_lean_pitch`
   0.90 and comes up `engine_lean_db` 2 dB over 0.25 s, and settles back when
   the finger lifts. The skid steer's push and the tipper's tip; never the
   mixer (the drum is not an engine under the child's load, and the rake is
   a hand tool). Measured: pitch 0.90 under the finger, 1.00 a second after
   it lifts.
8. **A tap on a machine honks it (1.8).** On a machine beat - one arriving on
   the child's call, or leaving on its own - `_press` asks
   `_machine_under(at)` (the machine's world box projected onto the screen,
   grown by half a reach): a machine answers with `horn` and a wink of its
   `Beacon` (`Machine.flash_beacon`, emission on a surface-override copy);
   anything else is answered by nothing, and GO no longer kicks while the
   machine it called is on its way. The arrival's last leg as a HOLD (the
   plan's optional M) is not built: it is decision 4 on the user's list.

**Tier 2, the three cheap ones.**

9. **UP means up (2.1).** The pour's UP pad creeps the truck BACK toward the
   kerb (-Z), which takes the concrete up the drive and up the screen; DOWN
   takes it away. The first run of the smoke found the flip alone made UP a
   dead pad: the mixer stood at the kerb end of its creep range, so there was
   nowhere to go until DOWN had been pressed. `_work_pose` parks it in the
   MIDDLE of `road_creep` now (rear tyre still on the road: z 7.16 against
   the kerb's 5.90), so both pads work from the first touch. And the pour has
   its mime: `_hint_kind` answers HOLD for the pour whenever no pad is held,
   `_hint_rect` names the pad that would take the concrete to the emptiest
   cell (`_pour_hint_pad`: sideways when the answer is sideways, along the
   drive otherwise), `SiteHud.hint_tick` can aim at a screen rectangle
   (`_aim_rect`), a pad under a thumb wakes the clock, and a tap on the
   picture during the pour kicks that pad (`nudge_pad`) with the miss's pop.
   The white mime waits `hint_delay` like every other beat; the gold arrow
   (the WHERE) comes at `chute_hint_delay`.
10. **The rake never starves (2.4).** `rake_pour_time` 9 s (half `pour_time`):
    during the come-along the chute supplies faster than `rake_rate` can
    draw, so the finger is the only thing the pull waits on.
11. **Sticky grab, walking speed (2.5).** The screed and the groover take
    their grab ONCE at the press, by a finger within `drag_grab` of the tool,
    and keep it until the finger lifts; the tool then follows the finger at no
    more than `screed_drag_speed` 1.2 / `joint_drag_speed` 1.5 m/s (the knob
    DESIGN 6.7 named did not exist). The verbs publish where the tool is
    (`SiteMain.drag_tool_at`), so the arrow stands on it and `tap_counts`
    measures a press on those two beats against the TOOL rather than the
    whole slab: an off-tool press is a miss answered at once. Measured: a
    finger flicked apron-to-kerb in one frame leaves the board walking (0.00
    struck); a finger 1.2 m off the joint line after the grab still pulls the
    sled.

**Green: `SITE_SMOKE PASS 276/276` (was 252), `MACHINE_PROBE PASS 13/13`
(2026-09-15).** Frames in `renders/critic/session2/`. The user's playtest is
next: it is the one that says whether 2.2 (steering the pour with a finger
on the form) is needed.

---

# The bucket under the blade (2026-09-15, after the second session)

`Machine.fit_blade` hid "the bucket's own meshes" with a loop over the `Bucket`
pivot's DESCENDANTS - and Godot imports the fleet's `Bucket` as the
MeshInstance3D itself (three surfaces, `BucketTip` a bare Node3D under it), so
`find_children` answered nothing and the loop hid nothing. The bucket's floor
and back hung out below and behind the push blade in every frame since DESIGN
2c: a dark-yellow slab under the cutting edge in the garage doorway on the
WIDE, and a row of bucket teeth poking out under the blade's polished edge on
the MACHINE shot (`renders/critic/blade_fix/before_*.png`).

The pin itself is now on the list, taken off the render layers (`layers = 0`)
the way `PropIcon`'s attach already did it - not `visible = false`, because the
blade hangs UNDER that pivot and a hidden pivot hides its whole subtree.
`BucketTip` (the MACHINE shot's anchor and the bucket-edge fallback) is a
Node3D and is untouched; `show_only` / `body_meshes` only ever run on the
mixer. The smoke asserts the pin's meshes, the blade's own apart, are off every
render layer.

**Green: `SITE_SMOKE PASS 277/277` (was 276), `MACHINE_PROBE PASS 13/13`.**
Frames in `renders/critic/blade_fix/`.


---

# The improvement plan's third session: Tier 3 - pacing and the story of the job (2026-09-15)

The user's word before it: "steering the pour not needed" - decision 1 is
closed, the pads stay, and 2.2 comes off the list. Seven items, one new
sound, and the smoke grew from 276 to 295 checks. Two of the user's open
decisions touched this tier, and the plan's defaults were built: the machines
leave in the background (decision 3) and the YAY! banner stays (decision 2).

1. **The job opens on the wide (3.1).** `SiteMain._start` snaps `WIDE` after
   the runner starts - the house, the cracked drive, the tools, the first
   slab's three rings lit in it - and holds it `opening_hold` (1.5 s) or until
   the first touch (`_end_opening`, from `_press` and GO), then eases down to
   the slab over `opening_ease` (1.2 s). It used to open snapped on a grey
   close-up. The pose path is untouched.
2. **The machines leave in the background (3.2).** The three AUTO leave verbs
   start `send_machine` without awaiting it, watch the exit for `leave_look`
   (2.0 s; the mixer's fade-in and chute fold are its look, then half of it)
   and return, so the runner lights the next place while the truck still
   trundles off up the street. The heap's fade runs alongside (`_fade_heap`).
   `send_machine` no longer moves the camera (the leave step's shot is the
   wide already, and a camera move in the background would fight the next
   beat's). Measured: the boards' rings are live 2.0 s after the second push
   ends, with the skid steer still driving; each next machine is called with
   the last one gone. `tip_time` 4 -> 6 so the tipper's own hold outlasts its
   exit look. `leave_time` stays 6.0: the trucks are as slow as the user asked.
3. **The payoff lands on the parked car (3.3).** The tada stays at the last
   stroke (Car Garage's convention). Then, in order: the cones to the mouth;
   the song fades to -30 dB (`Sfx.fade_music`) and the bar and hat go to
   nothing and stay there (`SiteHud.set_chrome_target`, locked) while the
   light sweeps to evening; only THEN the boards come off - they came off a
   slab broomed a second earlier before; the cut to `STREET` with the kit
   cleared; the car in, and when it stops it says thank-you in its own voice
   (`voice_hatchback`, on disk since the garage; two toots at `horn_delay`
   0.30 / `horn_gap` 0.45), and NEXT comes up alone - the house stays off,
   since beside NEXT it could only mean the same thing twice (0.1's "beside
   NEXT" is superseded). The sparkle emitter and its three knobs are gone, and
   so is `next_min_time`, which nothing read.
4. **The cure is a shape (3.4).** `_cones_to_mouth` slides the two cones to
   the mouth of the drive at the kerb (x = centre +/- 1.1; z = `Driveway.Z_KERB`
   + 0.30 on the crossing, at grade - the first cut put them at kerb - 0.35,
   which is ON the slab, see the verification pass below)
   before the light sweep and they stand there through it - a crew's "keep
   off", the one shape every child knows from the road; `_lift_cones` takes
   them out under the `STREET` eye before the car reaches the turn. The
   fence, the tools and what was left of the heap no longer FADE on the wide
   in front of the child: `_clear_kit` removes them at the cut, with one
   clunk. On a site things are carried off; nothing dissolves.
5. **Beep-beep-beep (3.5).** A sixteenth clip, `reversebeep` (ElevenLabs, 4 s
   loop, two takes), plays as voice "beeper" through the tipper's and the
   mixer's reverse leg and stops when they stop; the stop is a `hiss` of air
   brakes for the trucks and the old `clunk` for the skid steer. Every `boing`
   is gone - it was the celebration's cartoon spring, borrowed for every
   reverse leg, and `docs/sfx.md` had it down as the celebration's. Trims -6
   dB, under the tools as the fourth playtest asked.
6. **The bar measures the child's minutes (3.6).** Pour 6, come-along 8,
   water 4, screed 4, a joint 1, a bay of broom 2: seventy-four stops, and the
   mixer is called at 59% of the bar rather than 75%. The .tres header, DESIGN
   2 and the code had said 52, 63 and 59; all three say 74 now and the smoke
   holds `TOTAL_STOPS` to it. `JobStep.progress_weight`'s inspector range is
   0..12.
7. **The HUD steps back (3.7).** While a beat is live - the runner busy or a
   finger down - the bar and its hat ease to `chrome_working` 0.35 over 0.2 s
   and come back between beats; the position is shared with the siblings and
   is not moved. Measured: 0.35 during a bite, 1.00 between.

**Green: `SITE_SMOKE PASS 295/295` (was 276), `MACHINE_PROBE PASS 13/13`
(2026-09-15).** Frames in `renders/critic/session3/`. An eight-agent
adversarial pass over the seven items and the new background coroutines
follows in the next section.

### The improvement plan's third session: the verification pass

Eight agents, one per item of Tier 3 and one for the new background
coroutines, each told to REFUTE its item against the code and the smoke
(2026-09-15; the ninety-two-agent version of this pass died on the session
limit and was not repeated). Twelve findings survived. What they were and
what changed:

1. **The cure re-showed the heap.** `_cure` still drove `drive.hide_rubble(k)`
   from k = 0, so the forty-eight chunks the tipper had carried off five beats
   earlier came back at full alpha on the first frame of the wide and
   dissolved a second time. The call is gone, and `Driveway.hide_rubble` is
   MONOTONIC (`_rubble_hidden`): once a chunk has gone no caller can bring it
   back. Smoke: not one frame with a chunk shown through the cure, and none
   left, the tipper's idle stopped, before the mixer is called.
2. **The kit blinked out in the middle of the swing to the street.**
   `_celebrate` eased to `STREET` over 0.8 s and cleared the kit on the next
   line, so the fence and the tools vanished with the eye still turning. It
   is a `snap` now: a cut, and the kit goes in the frame the picture changes.
   Smoke: the fence is hidden in a frame the rig is standing still on STREET.
3. **The cones stood ON the slab.** z = `KERB_Z - 0.35` = 5.55 is behind
   `Driveway.Z_KERB` = 5.6: the "keep off" was two cones standing in the wet
   concrete they were guarding. They go to `Driveway.Z_KERB + 0.30` = 5.90
   now, on the crossing in front of the kerb-end board, at grade (the
   crossing's top is 0.0). And they had stood BURIED since round 10: the
   footway's top is 9.5 cm above grade (`FOOTWAY_TOP`) and they were seated at
   0; they stand on it now and come down to grade as they slide.
4. **The skid steer's exit crossed the pad's corner.** With the drive-out in
   the background the FORM frame had a wheel dipping into the hole through
   the far board's end. Its first leg runs down the verge now
   (x >= centre + half the width + 1.6) to the street. Smoke: every frame of
   the exit, never below grade over the pad.
5. **The bar was never seen full.** `set_working` left it at 0.35 through the
   tada and the cones; `_celebrate` sets the chrome to 1.0 first now, so the
   child sees the bar they filled before it goes for the cure. Measured 1.00
   at the tada (was 0.35).
6. **A miss dimmed the bar.** Any finger down counted as work; only the finger
   the beat accepted does now (`_touch_down and _accepted`).
7. **The toots overlapped and NEXT landed mid-voice.** The hatchback's clip
   runs 1.54 s and `horn_gap` was 0.45: the second toot started inside the
   first and NEXT came up 0.3 s into the second. The gap is at least the
   clip's own length now (`Sfx.last_length`), and NEXT waits for the last
   toot to sound out.
8. **On the wide a finger's reach was a slab.** 0.22 of the short side is
   158 px, and on the opening `WIDE` that is a whole panel: a tap on the
   second slab worked a ring on the first. `SpotRings.pick_nearest` caps the
   reach at what `tap_reach_m` 0.55 m covers on the screen AT THE RING, never
   under `tap_reach_min` 0.07 of the short side (a finger's own width). On the
   close shots the cap never binds; the contract's 0.22 stands.
9. **The payoff was deaf.** `_unhandled_input` returned on `runner.finished`,
   so through the cure, the car and NEXT every tap was silent - the plan's
   own first fault, back for the last twelve seconds. `_payoff_press`: a tap
   on the car toots it in its own voice; a tap anywhere off NEXT while NEXT
   is up is a miss - the pop, the white mime hurried, and NEXT kicks
   (`SiteHud.nudge_next`).
10. **The leave idle droned at one level and stopped dead.** The exit runs
    out of the picture now, so the voice fades 18 dB over its route before
    it stops.
11. **Smoke tightening.** The chrome check waited thirty frames for a
    wall-clock ease (a seconds timer now); the "still leaving OR gone" exit
    checks accepted either and so proved neither (`visible and is_driving()`
    now); the mixer is checked hidden with its idle stopped before the cure;
    the beeper is checked on the mixer's reverse leg as well as the tipper's;
    the payoff's "nothing points at anything" passed on a one-frame transient
    before the level had pointed at NEXT (now: the gold arrow gone AND NEXT
    ringed).
12. **`boing_1/2.mp3` still shipped** with nothing playing them. Deleted.

Not taken: parking a leave-step machine at its work pose in the posed shots
(the pose harness shows a leave step without its machine, which is what the
child sees from the next beat on).

**Green: `SITE_SMOKE PASS 305/305` (was 295), `MACHINE_PROBE PASS 13/13`
(2026-09-15).** Ten checks added, one replaced. The payoff frame in
`renders/critic/session3/` is re-taken, and a cure frame added with the cones
on the crossing.


---

# The improvement plan's fourth session: Tier 4 - show the thing (2026-09-15)

Items 4.1 to 4.7 (4.8, the day passing, stays optional and was not taken). An
eight-reader scouting pass mapped every item against the current code first,
and it found the plan's "Today" stale in four places: the old slabs already had
their stains, the long bars were never seen from the 1.25 m BARS eye (group 0
carries its own eye), the beacon DID have code - `flash_beacon`, which had
never lit anything - and the hose's bare stub only shows at a near aim or on a
4:3 screen. The smoke grew from 305 to 332 checks and the probe from
13 to 16.

1. **The old drive looks broken from the wide (4.1).** Weeds grow out of every
   old crack: up to four tufts a slab (`WEEDS_PER_PANEL`), each a 14 cm
   stalk and four leaning blades on a flat rosette (`_plant_weeds`,
   `_weed_tuft`), in a green a value step under the slab as well as a hue step
   (the lawn's own green is the slab's value). Their own generator, so no crack
   or stain changed shape. Measured on the opening wide: 14 tufts in the
   picture, 7 to 19 px tall (the plan asked six), the smoke's shortest 7.8 px.
   And the first slab has SETTLED: its seam edge 5 cm down, its lawn edge still
   at grade (`SETTLED_PANEL`, `SETTLE_STEP`), so the seam beside the first rings
   is a shadowed step and not a hairline; a bite sinks it further FROM the step
   (`rest_dy`; the absolute write would have popped it back up), measured 0.050
   m at rest and 0.062 after the first bite. The weeds go with the panel. Not
   the plan's heave: both kerb-end eyes stand on the lawn side, and a raised
   edge's riser faces away from them - a dropped edge shows the neighbour's
   face the whole seam long. The plan's "two dark stains per panel" were
   already there.
2. **Stakes are timber with a painted cap (4.2).** `STAKE_TIMBER`, a step paler
   than the board, with a 6 cm `STAKE_PINK` cap, 3 mm proud and 6 mm wider so no
   face is coplanar, a CHILD of the stake, so it rides every blow. Pink, not
   orange: the board's edge beside it, the chairs and the cones are orange and
   the rings gold (hue gaps 0.18 / 0.16 / 0.22 of the wheel). The rings sit ON
   the cap (`Driveway.stake_cap`), the pegs stand waiting from the moment the
   phase opens (they used to appear on the first blow, rings over bare earth),
   and the sledge's blow is honest: it rests on the cap, winds up, falls onto its
   top at the strike and rides it down - it used to sink 25 cm into the proud
   peg before the strike (measured now: deepest -0.000 m over 78 frames). Ten
   pink blobs of 5 to 15 px down the boards in the staked wide. `_pose_tool` runs
   again after `--done`, so a posed second pair has the sledge over ITS stake.
3. **The hose has a hose (4.3).** A 12 mm tube - the stub's own radius and eight
   sides - swept on a bezier from inside the stub to `hose_trail`, a point in the
   camera's frame below the picture on any landscape screen, arriving from above
   so it hangs; built in the tool's own space so the joint cannot tear, no
   shadow. One helper, `SiteMain.hold_hose`, holds it for the beat, between
   strokes and in the posed picture (which had parked the nozzle in world space
   over the far slab with a vertical jet stub). Measured: its end off the bottom
   at every aim, never across the water on screen. The honest note: at 16:9 with
   the aim up the slab nothing changes - the stub already left the frame. The
   frames that show it are the near-right aim and the iPad's 4:3.
4. **The groover gets a tool colour (4.4).** `make_site_props.py` splits the sled:
   the plate and its stepped ends in a new `ToolOrange` (0.62, 0.27, 0.03), a
   steel sole 6 mm proud of its long sides as the dark bottom edge; re-exported
   with `--only Jointer` (`SITE_PROPS_OK 1`, Tip on the origin, every other
   primitive byte-identical). Not the breaker's orange, which renders level with
   the slab. Measured in the JOINT frame: the sled (184, 87, 54), luma 0.41
   against the slab's 0.58, 29% under it (the grey sled was 0.38; round 13's
   failed pale steel was 9%). The bright grip the plan asked for already
   existed, and is below the frame.
5. **The beacons are lit (4.5).** `Beacon` was never in `Machine.CONTRACT`, so
   `node_for("Beacon")` was null and session 2's honk wink had lit nothing. Now
   the lens surface (found by its material, `Equip_Yellow`, which the tipper's
   whole body shares) gets its own copy with emission enabled once, a small
   shadowless OmniLight hangs UNDER the beacon's mesh so it hides with the body
   for the pour, and `set_beacon_on` turns a clipped cos-squared flash at
   `beacon_hz` 1.2 while a machine arrives, works and leaves; dark when parked.
   The honk wink is composed on top (held full for its first half). Measured
   off a pinned lit/dark pair (`--beacon=1/0`): the tipper's lens luma 0.51 ->
   0.75, still orange (R 1.00, G 0.72), and a small warm patch on the cab roof
   (+0.08 over 1,300 px); no light reaches the slab.
6. **A low eye for the long bars (4.6).** Group 0's own eye goes from (0, 1.7,
   3.0) looking (0, -0.4, -0.5) to (0, 0.62, 2.4) looking (0, -0.16, -1.0): 13
   degrees down, square up the drive. A chair is a leg now, not its foot seen
   from above - post 11 px against a 15 px foot, 13.5 px of daylight under the
   bar (from the old eye 6.1 / 16.6 / 8.7; measured on a LAID bar after the
   verification pass, 17.0 px). The plan's oblique eye beside bar 2
   put ring 1 off the left edge of the frame; four candidates were rendered
   (`--eye/--look` now write an anchor's own offsets - they silently did nothing
   for this group before).
7. **The rebar landing is an event (4.7).** The bar falls, clangs, bounces twice
   (3 cm then 1 cm for a cross bar), and once it has settled the black ties pop
   onto the crossings one after another down it, 60 ms apart, each a `click`
   pitched a step higher (borrowed from the garage, -6 dB). Measured: first tie
   333 ms after contact, then 386, 449, 511, four clicks. A cross bar's beat is
   about 1.2 s (was 0.57), a long bar's about 0.75 s: the steel phase went from
   about 7 to about 12 seconds of busy time. Pairs-per-tap was not taken (a ring between
   two bars is a tap answered by the phase, and 74 stops would become 70); chair
   flex was not taken (5 mm is a pixel from either eye, and a rigid cradle
   squashing more is not honest).

**Green: `SITE_SMOKE PASS 328/328` (was 305), `MACHINE_PROBE PASS 16/16` (was
13).** An adversarial pass over the seven items followed.

### The improvement plan's fourth session: the verification pass

Eight reviewers, one per item and a sweep, each told to REFUTE it against the
code, the frames and the latest smoke log, then an independent skeptic on every
medium or high finding (twenty agents). Eight of twelve survived; the rest were
older than the session and are listed as not taken. What changed:

1. **A weed hid under a ring on the opening wide.** Planting kept tufts 0.45 m
   from a spot on the GROUND, relaxing to 0.32 - but a ring on the wide is a
   billboard twice its size seen from low, and its gold lies over the ground in
   sheared bands a metre long. A ground rule could not be honest (a probe mapped
   one against the real camera: it rejected the rings' clear middles and missed
   round the near ring), so the level hands the opening wide's own eye to the
   driveway and the first slab is replanted against a pinhole projection of its
   three rings' gold at their widest pulse (`Driveway.replant_first_weeds`,
   `_under_ring_gold`); a weed may grow at the middle of a crack's segment as
   well as at its joints, so that slab still gets three. The smoke measures the
   same thing through the live camera: no tuft's root or tip inside any lit
   ring's gold band, in pixels. (It failed once, on the first rule, with three
   points under the gold.)
2. **The groover's "steel under it" was passed by the dark bit alone.** The
   check now finds the steel by WIDTH - the one dark surface wider than the
   orange plate (0.162 against 0.150 m; the bead and the bit are 2 cm) - and
   wants an orange hue, so a red sled cannot pass as tool orange.
3. **The fall and the bounce ran under different gravities.** The bar sank
   slowly and left the chairs 2.9 times faster than it hit them: a kick, not a
   bounce. `Driveway.bar_landing` gives every landing one gravity, fixed by the
   cross bar's bounce: the last 0.135 s of the drop is a free fall under it, the
   bar leaves at 0.71 of its impact speed, and a bar that waits lower bounces
   lower in proportion (a long bar: 2 cm up, a 0.078 s fall, 1 cm then 3 mm).
   The smoke measures the speed either side of contact: a long bar down at 0.37
   m/s, up at 0.28 (averaged over 30 ms).
4. **From the low eye the two outer waiting long bars lay on the form boards.**
   Their 6 cm lift was thrown outward by the new eye's parallax, and their fan
   swung their near halves out. Long bars now wait barely lifted
   (`bar_long_lift` 0.02 - the decided list's "no lift to be thrown by
   parallax", made literal) and swing their kerb ends toward the middle line;
   the outer two swing 0.20 m (`BAR_SKEW_END_LONG_OUTER`) so their far ends stay
   inside the boards too. The smoke casts the eye's ray through each waiting
   bar, at its ring and a stride nearer, and wants the base inside the forms.
   The chair-and-daylight check moved to a LAID bar, in thousandths of the
   frame's height, so a 4:3 run measures the same picture.
5. **The hose vanished in one frame when the beat ended.** `phase_done` flew the
   nozzle home, and a flight drops the hose, in a picture held still on the
   hands - on an iPad a fifth of the screen of hose. A tool still held with its
   hose stays in the hands for the hold now and is put away with the next beat.
6. **The hose's sway could not be seen.** It moved the control point next to the
   far end, off the picture: 0 px at 16:9, a few on an iPad, while the smoke
   reported 296 mm of raw spring lag. The spring and `hose_sway` are gone rather
   than kept as a number, and the check with them.
7. **Three new checks recomputed the code's own numbers.** The pink stub is read
   off the Cap node's own box and material now, against the board's and a
   chair's materials; the hose joint is proved against the nozzle GLB's own
   stub ring (the mesh has its vertices at `STUB_END`), not against a point
   built 5 mm from it; the ties' click is counted, one per tie.
8. **A frame showed a blow nobody posed.** 06c had stake 4 driven: a stray click
   on the capture window. `shot.gd` disables input on the viewport now; every
   frame was re-taken.

Found in passing and fixed, because each was three lines: `set_bar` found a
bar's landing mark as "the sibling named Mark", and Godot renames a second
child called Mark (`@Node3D@2`), so for two sessions only bar 1 ever showed where
it would land - the mark is in the bar's own record now, and 2 mm thick so its
top is no longer the chair feet's plane; the mixer's beacon now turns as its
body fades back in and its chute folds, as the other two turn through their
last moves; the payoff draws the stakes up out of the ground before the boards,
where ten pink caps used to blink out on one frame; stale comments ("THREE
stakes", "FLUSH with the board", "the tie wire appears", the weeds' generator).

Not taken, each older than the session: the sledge still snaps the last third of
its flight in, since `hover` then `hover_instant` at 0.6 of the fly time is the
jackhammer's and the screed's pattern too, and is worth its own pass across all
three verbs; a KEPT tap re-lights its ring through the beat it plays (0.4's, in
every ring phase - 4.7 only made the rebar's beat as long as the jackhammer's
already was); a queued or GO blow's ring hangs over a driven stub until the
rings are rebuilt; a held tool waits on the lawn until the first press (the hose
and the broom alike); the hose trails the eye by a frame if pressed during the
ease into HAND; the settled slab's lawn edge shows a one-pixel line (honest -
it is tilted); the kerb board's two stakes stand in the footway crossing's
concrete, which the pink caps now show, and moving the crossing's edge touches
the cones and the mixer's stand; the posed tipper and water frames show
moments play reaches only mid-beat.

The frames, re-taken windowed at 1280x720 unless named, into
`renders/critic/session4/`, each with its args (after `--path . --resolution
<res> res://scenes/dev/shot.tscn -- --scene=res://scenes/site.tscn`):

| frame | args |
|---|---|
| `01_old_wide_hud` | `--stage=old --shot=WIDE --frames=70` |
| `01b_old_wide` | `--stage=old --shot=WIDE --nohud --frames=70` |
| `01c_old_panel` | `--stage=old --shot=PANEL --nohud --frames=70` |
| `03_broken_wide` | `--stage=broken --shot=WIDE --nohud --frames=70` |
| `04_push_machine_beacon` | `--stage=broken --step=2 --shot=MACHINE --hold --wait=1.5 --beacon=1 --nohud --frames=70` |
| `04b_push_machine_dark` | `--stage=broken --step=2 --shot=MACHINE --hold --wait=1.5 --beacon=0 --nohud --frames=70` |
| `06_formed_stake` | `--stage=formed --shot=STAKE --nohud --frames=70` |
| `06b_stake_blow` | `--stage=formed --shot=STAKE --tap --frames=2 --wait=0.62 --nohud` |
| `06c_stake_pair2` | `--stage=formed --shot=STAKE --done=2 --nohud --frames=70` |
| `07_staked_wide_hud` | `--stage=staked --shot=WIDE --frames=70` |
| `08_tipper_wide_beacon_pinned_lit` | `--stage=staked --step=7 --shot=WIDE --beacon=1 --nohud --frames=70` |
| `08b_tipper_wide_beacon_pinned_dark` | `--stage=staked --step=7 --shot=WIDE --beacon=0 --nohud --frames=70` |
| `09_bars_low_hud` | `--stage=based --shot=BARS --frames=70` |
| `09b_bars_low_three_down` | `--stage=based --shot=BARS --done=3 --nohud --frames=70` |
| `09c_bars_pair` | `--stage=based --shot=BARS --done=4 --nohud --frames=70` |
| `09d_bar_landing_fall` | `--stage=based --shot=BARS --done=4 --tap --frames=2 --wait=0.40 --nohud` |
| `09e_bar_landing_first_ties` | `--stage=based --shot=BARS --done=4 --tap --frames=2 --wait=0.68 --nohud` |
| `09f_bar_landing_tied` | `--stage=based --shot=BARS --done=4 --tap --frames=2 --wait=1.0 --nohud` |
| `09g_rebar_wide` | `--stage=rebar --shot=WIDE --nohud --frames=70` |
| `10_pour_chute` | `--stage=rebar --step=11 --shot=CHUTE --hold --wait=1.0 --nohud --frames=70` |
| `11_water_hand_near_right` | `--stage=poured --shot=HAND --hold --cursor=4.1,4.3 --wait=1.0 --nohud --frames=70` |
| `11b_water_hand_ipad` (1024x768) | `--stage=poured --shot=HAND --hold --cursor=2.6,1.0 --wait=1.0 --nohud --frames=70` |
| `11c_water_hand_ipad_near_right` (1024x768) | `--stage=poured --shot=HAND --hold --cursor=4.1,4.6 --wait=1.0 --nohud --frames=70` |
| `11d_water_hand_posed` | `--stage=poured --shot=HAND --nohud --frames=70` |
| `13_joint` | `--stage=screeded --shot=JOINT --nohud --frames=70` |
| `15_done_wide` | `--stage=done --shot=WIDE --nohud --frames=70` |
| `16_parked_payoff_hud` | `--stage=parked --shot=PAYOFF --frames=70` |

**Green: `SITE_SMOKE PASS 332/332`, `MACHINE_PROBE PASS 16/16`
(2026-09-15).**
