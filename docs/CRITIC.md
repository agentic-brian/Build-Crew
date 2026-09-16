# The critic's brief (the /loop)

Once the job plays it is judged in rounds by a harsh critic and then fixed,
until a round finds nothing that matters. This is what the critic judges
against, so every round is the same critic.

## Who the critic is

Five people watch one full New Driveway (and NEXT into a second one, which must
be a different driveway), then an
editor merges what they said and throws out what is wrong or already planned:

1. **A four-year-old** who cannot read. Where does the finger go? Did the tap
   do something? Was it boring? Did anything scare or confuse them? Could they
   tell what was wrong with the driveway before they touched it?
2. **A parent** watching. Is it calm, safe, honest? Is anything a trick to keep
   them tapping? (There must be nothing to buy, earn, unlock or beat.)
3. **A groundworker who pours concrete for a living.** Is this how the job is
   really done, in this order, with this tool, with the machine standing there?
   Would they wince? (Simplified is fine; wrong is not. They are the one who
   will notice a truck driving over green concrete, a screed pulled the wrong
   way, or a slab with no control joints.)
4. **An art director** for a low-poly cartoon. Composition, readability at
   tablet distance, colour steps, nothing floating, clipping, flickering,
   paper-thin, inside something else, or lit wrong.
5. **Someone trying to break it.** Tapping during animations, tapping the HUD
   and the world at once, holding two pads, letting go half way through a hold
   and pressing again, mashing the green button, NEXT twice, home mid-job,
   rotating the window, playing a second driveway.

## What they hunt for, in this order

1. **Broken mechanics** (the worst): a step that cannot complete, a tap that
   does nothing, an arrow pointing at nothing or off-screen, a panel that will
   not break, rubble that cannot be pushed, a form the concrete leaks past, a
   pour that cannot be finished, a machine that drives through the house, a
   camera inside a wall, HUD covering the subject, a sound at the wrong moment
   or not at all.
2. **Graphical artifacts**: z-fighting and flicker, clipping, floating parts
   (a machine standing over the excavation rather than in it), black or missing
   faces, shadow acne, jitter, pop-in, overlapping HUD, a placeholder in play.
3. **Learning fidelity**: the order of the ten phases, the tool used, what the
   child is shown (a cracked slab before the first tap, a bare hole, a base, a
   form filling, a slab going flat behind the screed), whether the payoff is
   the driveway being USED.
4. **Pillar violations**: anything that looks like money, score, upgrades,
   unlocks, timers, stars, streaks, fail states; any words on screen.
5. **Readability and feel**: too small, too fast, too slow, too dark, too loud,
   arrow not obvious, a beat with nothing to see, a phase that outstays its
   welcome.

## How a round runs

1. Rebuild the evidence:
   ```
   godot --headless --path . --editor --quit          # class cache
   godot --headless --path . res://scenes/dev/machine_probe.tscn
   godot --headless --path . res://scenes/dev/site_smoke.tscn
   godot --headless --path . res://scenes/dev/resume_probe.tscn
   ```
   then the phase shots into a dated folder under `renders/critic/`:
   ```
   godot --path . --resolution 1280x720 res://scenes/dev/shot.tscn -- \
     --scene=res://scenes/site.tscn --out=<abs>.png --frames=70 \
     --stage=<old|broken|cleared|formed|staked|tipped|packed|kerbed|based|rebar|banded|poured|sprayed|screeded|jointed|cured|done|parked> \
     --shot=<WIDE|PANEL|MACHINE|TIPPER|FORM|STAKE|PLATE|BARS|CHUTE|PULL|SURFACE|HAND|JOINT|BROOM|STRIP|STREET|PAYOFF> [--nohud] [--seed=N]
   ```
   Take every stage in its own shot AND in WIDE, with and without the HUD. With
   no `--seed` a frame is the legacy lot; take the old WIDE and the PAYOFF at two
   or three seeds as well (different cars, houses and cracks), since a visit is
   drawn now.

   Two arguments worth knowing. `--step=<verb>` (or `--step=form_set:2` for a
   verb's second row, or a bare number) overrides which beat the runner is
   posed on, which is how you photograph a phase's CONTROLS (the pour's four
   steering pads only exist while `--step=pour_chute` is the current one; a
   truck waiting to be backed in is `--step=back_dump`). `--nomachine`
   leaves the machines off-stage: the dump truck and the mixer park ON the
   driveway, so they hide the gravel base and the fresh concrete that are the
   whole point of those two phases.
2. **Read every PNG.** Write the findings as a ranked list: `severity (S1 broken
   / S2 artifact / S3 fidelity / S4 pillar / S5 feel)`, where (phase, shot), the
   evidence (PNG path or probe line), the likely cause (file:function), and the
   proposed fix. A thumbnail is not evidence for a failing grade — open it.
3. Fix S1 and S2 first, then S3/S4, then S5 if cheap. Every fix is re-verified:
   a check added to the smoke test, or a shot re-taken and read. **The smoke
   test and the machine probe must be green at the end of every round.**
4. Append the round to `docs/critic_log.md`: date, findings, what was fixed,
   what was deferred and why. A round with no S1-S3 findings ends the loop.

## What the machines already check themselves

`machine_probe` asserts the fleet GLBs' node contracts and which way every pivot
turns (the bucket on the dirt at lift 0, the bed's FRONT rising, the chute's
swing wetting the full width). `site_smoke` plays the whole job and asserts the
world at every phase. So the critic should spend its whole score on what only an
eye can judge, and not re-derive those.

## Things already decided (do not re-litigate)

- No person on screen; the tool is the hand, and the machines drive themselves
  - except the last leg of a truck's arrival, which the child backs in with a
  held finger (the user's decision 4, 2026-09-15).
- The phase ORDER is the user's: break, push out, forms, stakes, base, pour,
  water, screed, joints, broom. Water before the screed is deliberate. Since
  2026-09-15 (the user's decisions 5 and 6) the kerb board and its two stakes
  go in after the base, the base is packed with a plate compactor before them,
  and the child strips the forms after the cure.
- Since 2026-09-14 the mixer STAYS ON THE ROAD with an extension chute clipped
  on, fills the kerb end of the form, and the child pulls the rest up with a
  come-along (DESIGN 2a, 2d). It never drives on the steel. The pour in two
  halves and the pump were considered and rejected: the fleet's chute is too
  short for the first and the second throws away the chute game the user asked
  for.
- The reinforcement is rebar on chairs, laid by the child, twelve bars: sparser
  than a real grid on purpose (DESIGN 2d).
- The skid steer pushes with a DOZER BLADE attachment, not its bucket (DESIGN 2c).
- The chute's fold is deployment only: it moves the pour point 0.11 m.
- You do not drive on green concrete: the payoff cures first, then the car parks.
- Since round 10 the stakes go in PAIRS ALONG a board (four to a long board,
  two on the kerb board, ten taps), because a pair across the form can only
  be framed on the gap between them.
- The wides are 3 m up with a horizon, not top-down; the drive is still the
  subject.
- A particle that IS a material on screen is unlit, converted once, and a
  STEP LIGHTER than the surface it lands on; loose material (stone, chips) is
  lumps. Feedback laid beside the heightfield is built out of the surface
  (the bow wave), not from a primitive.
- Since round 12 the pour and the come-along have SEPARATE cues in the
  slab's colour: a hard step (done / not done) for the come-along, a mild
  slope for the pour's fringe. A waiting rebar lies skewed BESIDE its place
  on the grid (no lift to be thrown by parallax); its skew is a DISTANCE at
  the bar's end, not an angle. The pour's hint only stands on a cell that
  looks short.
- Since round 13 the rubble heap is loaded out with the tipper (off screen),
  so the steel, the pour and the finishing are worked on a clear site; the
  chute casts no shadow while the truck is not drawn; the water leaves
  puddles in the low spots until the screed strikes them.
- Since round 14 the pour is composed, not tinted: the CHUTE eye stands
  beside the chute's line so the stream falls in front of the trough; the
  landing is a lit crest of concrete (no dark shape is ever drawn on the
  fresh pool); the joint has a groove and no pale lip; a cell the come-along
  still has to fill is DARK wet mud, a luma step, not a warmth.
- Since the fourth playtest (2026-09-14): the cameras do not drift; the screed
  and the joints are DRAGS (the board and the sled follow the finger, never
  back); the broom is three beats, one per bay, from the side; the call button
  shows the fleet's own machine (`PropIcon`); the white idle arrow mimes what
  to do after four seconds of nothing, with the gold ring still under it.
- Since the plan's fourth session (2026-09-15): the old drive's fault is
  SHAPE (weeds in its cracks, the first slab settled a step); form stakes are
  timber with a survey-PINK cap, the one hue nothing else on the site has; a
  held tool is connected to the bottom of the picture, the hose too; every hand
  tool worked on the slab carries one saturated colour at a value step under
  the slab; a machine's beacon turns while it arrives, works and leaves; the
  long bars are seen from low (a chair is a leg), and a waiting LONG bar is
  barely lifted and swings inward; a bar's landing is one gravity - fall,
  clang, two bounces, then the ties pop on down it.
- Since the plan's fifth session (2026-09-15): a truck stops in the road and
  the child backs it in, beeping only while it moves; the plate compactor is a
  DRAG, packing a plus sign under a still finger, the packed base a luma
  step paler with its stones flat - over the WHOLE base and ended by a clock
  since the playtest of 2026-09-16, because per-bay coverage was a phase the
  user could not finish; the kerb board and its pegs are live only once
  the base is packed (state, not a count), and its pegs stand in earth; the cure
  is a beat and the three boards are stripped by the child, carried to a pile on
  the right lawn and carried off at the cut; the tada answers the last board; the word YAY! stays
  (decision 2). Stages and `--step` name verbs, never numbers.
- Since the plan's sixth session (2026-09-15): the second driveway is a
  DIFFERENT driveway - the homeowner's car (six, in their own paint and voice),
  the house and garage walls and the old drive's cracks are drawn per visit, and
  NEXT never repeats the car, the house or the cracks; the job, its order, the
  panel count, the spots and the lot never change; no car parks in front of a
  garage it disappears against. Seed 0 is the legacy lot every
  earlier picture shows. Closing the app loses nothing: the job comes back at
  the row and the places the child left, a held beat at its start, and the save
  holds no time.
- Since 2026-09-16 (6.4): there is a SETTINGS COG, top-left, on both screens -
  the one control a parent reaches for. It pauses what is under it, lets go of
  every finger that was down, and carries an eleven-step loudness slider, a
  music toggle and a privacy link behind an arithmetic gate. THE WORDS RULE:
  none for the child, ever, except the kept "YAY!" (decision 2, which this
  bullet does not reopen); beyond it, words are allowed only inside a control a
  child cannot operate (the gate) or on a label addressed to the adult who
  opened a panel a child has no reason to open (the privacy link) - and every
  SENTENCE meant for an adult is set in Nunito Sans, while the gate's sum,
  answer and keys stay in Fredoka, which is read as digits, not prose. Every corner
  control keeps off the hardware's own insets, and a child whose OS asks for
  less motion gets a camera that never shakes, with everything they touch still
  moving.
- Since the plan's sixth session, part two (2026-09-15): THERE IS A TITLE ROW,
  and it is the job picker (6.3). The app opens on it, NEXT and the house come
  back to it, and the lot itself is what stands behind it - a fresh cracked
  drive, the drive the child left, or the drive they just finished with the car
  on it. One big disc per job, carrying that job's own machine; no words, no
  fade, no second page, no locked seats. The TAP is always the safe thing (it
  starts or carries on); throwing a half-built drive away is a smaller disc in
  the other corner, HELD for 0.9 s with a ring filling round it. Settings, the
  privacy gate, the brand, the splash and the icons are still to come, from Car
  Garage, in 6.4.
