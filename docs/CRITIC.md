# The critic's brief (the /loop)

Once the job plays it is judged in rounds by a harsh critic and then fixed,
until a round finds nothing that matters. This is what the critic judges
against, so every round is the same critic.

## Who the critic is

Five people watch one full New Driveway (and NEXT into a second one), then an
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
   ```
   then the phase shots into a dated folder under `renders/critic/`:
   ```
   godot --path . --resolution 1280x720 res://scenes/dev/shot.tscn -- \
     --scene=res://scenes/site.tscn --out=<abs>.png --frames=70 \
     --stage=<old|broken|cleared|formed|staked|based|rebar|banded|poured|sprayed|screeded|jointed|done> \
     --shot=<WIDE|PANEL|MACHINE|TIPPER|FORM|STAKE|BARS|CHUTE|PULL|SURFACE|HAND|JOINT|STREET|PAYOFF> [--nohud]
   ```
   Take every stage in its own shot AND in WIDE, with and without the HUD.

   Two arguments worth knowing. `--step=N` overrides which beat the runner is
   posed on, which is how you photograph a phase's CONTROLS (the pour's four
   steering pads only exist while step 10 is the current one). `--nomachine`
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

- No person on screen; the tool is the hand, and the machines drive themselves.
- The phase ORDER is the user's: break, push out, forms, stakes, base, pour,
  water, screed, joints, broom. Water before the screed is deliberate.
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
- No title screen, settings or privacy gate in the prototype — they are ported
  from Car Garage when this stops being a prototype.
