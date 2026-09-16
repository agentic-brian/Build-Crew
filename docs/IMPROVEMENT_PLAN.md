# Build Crew - improvement plan (2026-09-14)

What would make a three-to-six-year-old want to do the driveway, understand it,
feel they did it, and ask for it again - and what would make the prototype a
product. Written after fifteen critic rounds and four playtests, from a
ten-lens review (child play, pacing, feedback, learning, visuals, touch,
structure, robustness, audio, parent) whose seventy-six findings were checked
against the code and the `renders/critic/playtest4/` frames. Every claim below
names the file or the frame it comes from; the ones that push on
`docs/CRITIC.md`'s decided list say so and are yours to accept or refuse.

This is not another art-critic round. The pour's composition, the greys, the
crest and the chute's shadow are left exactly where round 15 left them.

Effort: **S** under an hour, **M** a session, **L** a day or more. Every item
ends with the check that proves it, because "all tests pass" has hidden two
real bugs in this project already.

---

## 0. The verdict

The doer beats are right and should not be touched: three bites and a crumble
on a slab, the blade heaping rubble under a held finger with the machine huge
in the frame, one sledge blow per stake down on the peg, the hose in the
child's own hands, the three finger-led drags with their done/not-done colour,
rings in the world in any order, the camera walking with the work. A full job
is four to four and a half minutes fluent and five to seven at a child's pace,
which is one sitting.

What limits engagement is not the count of beats. It is four things:

1. **The child is a spectator for about 45% of the job, and the toy goes deaf
   while they watch.** Three arrivals of 7 s, three exits of 6 s, the skid
   steer's shuffles and the 10.7 s payoff add up to roughly 120 s of a 260 s
   job in which a tap on the picture does nothing at all - and a tap on the
   truck, the most natural thing on the screen, either kicks the GO button in
   the corner or is swallowed in silence. The target for this age is a quarter
   of the job watching, with no unbroken watch over five seconds except the
   finale.
2. **The edges of every beat are dead.** A tap is silent for 0.33 s while the
   tool flies in; a miss is silent and only throbs a ring the child may not be
   looking at; a miss also RESETS the four-second clock that would bring the
   white mime, so the child who most needs the hint can never see it; and
   when a phase ends (the tenth stake, the full form, the last bay) the
   picture cuts away in the same frame with no sound and no rest. The runner
   emits `step_done` and nothing in the game listens to it.
3. **The centrepiece is the one beat with no teacher and a control that
   points the wrong way.** The pour is the only beat with an abstract control
   (four pads for an undrawn truck), the only beat whose white mime is
   switched off (`_hint_kind` returns NONE for pad verbs), the only beat where
   a tap on the thing is accepted and does nothing, and its UP pad moves the
   concrete DOWN the screen (the CHUTE eye looks up the drive; UP adds +Z,
   toward the camera).
4. **One button can destroy the whole job, and one button can crash the app.**
   The green house reloads the scene with no confirmation from any frame; NEXT
   (and the house) free a playing `AudioStreamGenerator`, the crash class that
   killed one Car Garage run in three until it was fixed there.

Fix those four and the toy is engaging. Everything else here is how to make
it a picture book, a lesson, and a product.

---

## 1. What NOT to change

Protect these; several are the result of the user's own playtest notes.

- The three verb shapes (bite / hold / scrub) and the rule that a resting
  finger moves nothing on a drag (`site_verbs.gd:_hold/_bite/_scrub`).
- Rings in the world, any order, groups the camera walks to; the gold ring as
  WHERE and the white mime as HOW.
- The generous tap reach (0.22 of the short side plus the target's size), the
  queued tap, `hold_burst`, the hold that pauses where the finger lifts.
- The scrubs accepting a first press anywhere on the slab (hose, rake, broom).
- The cameras standing still (no drift), the KEEP_WIDTH framing, every shot
  composed and asserted at 16:9.
- The fourteen site sounds, the finger-as-throttle loops, the vehicle groups 9
  dB under the tools, the breaker as one loop.
- The honest spine: cracked slab, real hole, boards as the screed's rail,
  steel on chairs before any concrete, the mixer on the road, joints before
  the broom, the cure before the car.
- The pour's composition as of round 15. Do not reopen it.
- The wides as a picture book (house, tree, fence, cone, mailbox, sunset) and
  the fleet-model call button.

---

## 2. Tier 0 - stop the bleeding (one short session, all S except one M)

**DONE 2026-09-15.** All six built and green: `SITE_SMOKE PASS 252/252` (was
221) and `MACHINE_PROBE PASS 13/13`; the session is logged as the last section
of `docs/critic_log.md`. One departure from the text below: 0.6 came out as a
FADE on the way out (the truck's body fades in over the eye's ease to the
wide), because keeping it hidden until the wide had settled only moved the pop
to where the truck is biggest.

### 0.1 The house button must not throw the job away
- **Today:** `site_main.gd:_on_home` calls `_on_next`, which reloads the
  scene. A four-year-old taps every round green thing; at stop 60 of 63 the
  drive is the cracked slab again.
- **Change:** in the prototype hide the house while a job runs
  (`SiteHud._hide_borrowed_controls` already hides borrowed controls; add
  `_home`), and show it beside NEXT in the payoff where "again" is the only
  thing it can mean. When the title is ported (tier 6) it becomes a
  press-and-HOLD of 0.9 s with a ring filling round it, and it goes to the
  title with the job saved. Family rule: any control that throws work away is
  a hold, never a tap.
- **Half done 2026-09-15 (session 7).** The house's DESTINATION now exists (it
  reaches the title row through `_on_next`), the job it leaves is saved (6.2),
  and the 0.9 s hold-with-a-ring is built and tested - it is the title's own
  "new drive" disc (`StartMenu`'s `HOLD_TIME` and `HoldRing`). What is left of
  0.1 is the button itself: `SiteHud.show_home` still has no caller, so the
  house is off the screen in play, and putting it back means moving that hold
  onto `ToyHud`'s home button (a plain release edge today) and inverting the
  three smoke checks that hold it off the screen.
- **Files:** `scripts/site_hud.gd`, `scripts/toy_hud.gd`, `scripts/site_main.gd`.
- **Check:** smoke at step 5 calls `hud.simulate_home()` and asserts the
  runner's index and `drive.forms_in()` are unchanged.

### 0.2 Stop NEXT and the house freeing a playing generator (M)
- **Today:** `scripts/sfx.gd:84-91` streams an `AudioStreamGenerator` for the
  life of the node; a scene reload frees it while it mixes. The memory
  `reference_godot_audio_generator_crash` records exit 139 one run in three in
  Car Garage with the same pattern, fixed there and not here.
- **Change:** port Car Garage's fix: synthesise each fallback pop/thud/whoosh
  into an `AudioStreamWAV` once and play it from the pool; delete
  `_synth_player` and `_pb`.
- **Files:** `scripts/sfx.gd`.
- **Check:** smoke walks the tree and asserts no player's stream is a
  generator; after the payoff it presses NEXT, awaits the reload, plays the
  first bite of the second job, and the process exits 0.

### 0.3 One finger owns the beat
- **Today:** `_unhandled_input` reads every `InputEventScreenTouch` and
  `ScreenDrag` with no look at the index. A palm resting on the glass (every
  small child) steals the hose, and when it lifts the beat ends and the loop
  stops. Logged as "left as found" in the critic log.
- **Change:** `_touch_index`: the first accepted press adopts its index;
  other fingers are ignored while it is down (they still bloom the white tap
  ring); only its own release ends the hold; if another finger is still down
  when it lifts, adopt that one. Clear it on
  `NOTIFICATION_APPLICATION_FOCUS_OUT` so a backgrounded finger does not spray
  on resume.
- **Files:** `scripts/site_main.gd`, `scripts/tools/site_smoke.gd`.
- **Check:** push real touch events in window pixels via
  `get_final_transform` (the memory's rule): index 0 down on the slab, index 1
  down and up on the lawn, index 0 drags; `runner.held` stays true and
  `water_coverage()` keeps rising.

### 0.4 A queued tap keeps the ring it chose
- **Today:** tap ring A, tap ring C during the bite; `arm_rings` zeroes
  `_picked` before the queued tap fires, and the hammer walks to B, the first
  open spot. On a panel's last bite it lands on the next panel while the
  camera is still easing.
- **Change:** carry the pick with the queue (`_queued_pick`); `arm_rings`
  restores it if that ring is still live, else drops the queued tap.
- **Files:** `scripts/site_main.gd`, `scripts/job_runner.gd`.
- **Check:** `_tap_ring(2)` then `_tap_ring(3)` while busy; after both bites
  spot 3 is done and spot 1 is not.

### 0.5 A tap on the white wedge counts as a tap on its ring
- **Today:** the mime says "tap here"; the child taps the wedge; the rings
  branch in `_press` measures only ring centres and the wedge's body stands
  beyond reach on its out-swing. The toy refuses its own instruction.
- **Change:** in the rings branch, if `_picked == 0` and `hud.arrow_hit(at)`,
  pick the ring the hint stands over.
- **Files:** `scripts/site_main.gd`.
- **Check:** lower `hint_delay`, wait for the hint, press at
  `hint_tip_now()` plus the wedge's back offset, assert that spot is done.

### 0.6 Hide the mixer only after the eye has reached the chute
- **Today:** `pour_chute` runs `show_only(["Chute"])` on the frame the step is
  entered, while the rig is still easing from the wide; the truck blinks out
  in the wide picture and the chute hangs in the air before the cut.
  `mixer_leave` pops it back mid-ease.
- **Change:** `while site.rig.is_moving(): await process_frame` before the
  hide. On the way out (built 2026-09-15): the rake beat leaves the truck
  hidden and the leave beat FADES its body in over the eye's ease to the wide
  (`Machine.body_meshes` + `Driveway.fade_node`, the chute untouched) - a pop
  in a static wide is worse than a pop far off in the PULL frame, and a fade
  under a moving picture is better than either.
- **Files:** `scripts/site_verbs.gd`, `scripts/machine.gd`.
- **Check:** on the first frame after entering the pour `_drawn(mixer,
  "Drum") > 0` while the rig moves, `== 0` after it settles; on leave, drawn
  but under half alpha while the rig moves, opaque once it has settled.

---

## 3. Tier 1 - every touch answered (the feedback grammar)

**DONE 2026-09-15 (session 2), with 2.1, 2.4 and 2.5.** `SITE_SMOKE PASS
276/276`, `MACHINE_PROBE PASS 13/13`; the session is the last section of
`docs/critic_log.md`. Three numbers came out different from the text below:
the sledge blow moves the picture 10 mm at its peak, not the 0.02 m the check
in 1.4 asked for (the guess ignored the shake noise's own amplitude; the knob
is `shake_stake`); the pour's white mime waits `hint_delay` like every beat,
with the gold arrow at `chute_hint_delay` (2.1); and the mixer now parks in
the MIDDLE of its creep range, because with UP meaning up a truck parked at
the kerb end had nowhere to go (2.1). 1.8's optional hold on the arrival's
last leg was decision 4, and was built in session 5.

The rule under all of these: **the first 100 ms after a tap is where a small
child decides whether the toy heard them; the last second of a phase is where
they decide whether they did it.**

### 1.1 Voice the tap in the frame it lands (S)
- **Today:** the jackhammer waits `tool_fly_time * 0.6` = 0.33 s in silence
  before the breaker loop; the sledge lands about 0.6 s after the finger. All
  eighteen rows of `new_driveway.tres` have `sound = ""`, and
  `JobRunner._play_beat` already plays that field before the verb runs.
- **Change:** `sound = "whoosh"` on the `jack_spot` and `stake_drive` rows.
  No verb code.
- **Check:** after the first jack tap `sfx.last_played == "whoosh"` in the
  same frame.

### 1.2 A miss is heard, and it brings the mime sooner (S)
- **Today:** all three miss branches in `_press` are silent; the nudge goes to
  the pointer arrow, which is hidden while rings are up, so on 38 of the 63
  stops a miss throbs nothing. And `_woke()` runs at the top of `_press`
  before the miss branches, so every wrong tap restarts the 4 s idle clock:
  the confused child never sees the white mime.
- **Change:** (a) `_miss_sound()` at all three nudge sites: `pop` at -4 dB,
  rate-limited to one per 0.25 s, never a buzzer; (b)
  `SpotRings.nudge_nearest(camera, screen)`: the live ring nearest the finger
  swells to 1.45x and eases back over 0.5 s - one throb, not a faster
  wobble; (c) move `_woke()` into the branches that accept the press, and on
  a miss call `hud.hint_hurry()` which sets `_hint_idle = max(_hint_idle,
  hint_delay - 1.0)` so a second miss brings the mime at once, standing on the
  right place with the right gesture.
- **Files:** `scripts/site_main.gd`, `scripts/spot_rings.gd`,
  `scripts/site_hud.gd`.
- **Check:** an off-target press sets `last_played == "pop"` and
  `arrow_nudged()`; two off-target presses 0.5 s apart show the hint within
  0.3 s.

### 1.3 Take the picked ring; leave the others lit (S)
- **Today:** (corrected 2026-09-15 with the code open: `SiteHud.hide_arrow`
  clears the POINTER's single ring, not the level's set, so the three rings do
  stay lit through a bite.) The picked ring simply stays lit, unchanged, for
  the whole 0.95 s of the bite, and disappears only when `arm_rings` rebuilds
  the set afterwards: nothing at the ring answers the tap in the instant it
  lands.
- **Change:** `SpotRings.take(id)`: the picked ring snaps out (scale 1 to
  1.6, alpha to 0 over 0.15 s, the same snap the mime draws) the frame the tap
  is accepted; the others stay as they do now; `arm_rings` afterwards removes
  only the one that is done.
- **Files:** `scripts/spot_rings.gd`, `scripts/site_hud.gd`,
  `scripts/job_runner.gd`.
- **Check:** during a bite on spot 1, rings 2 and 3 are still visible.

### 1.4 Make the sledge and the breaker kick the camera (S, numbers only)
- **Today:** `camera_shake.gd` scales by trauma squared: `shake_stake` 0.08
  gives 1.6 mm; `shake_break` 0.22 gives 1.2 cm; `shake_jack` 0.02 at 13 Hz
  never climbs above decay. The user's "hammer feeling" is authored in three
  numbers and none reaches the screen.
- **Change:** `shake_stake` 0.08 to 0.38 (3.6 cm, gone in 0.24 s),
  `shake_break` 0.22 to 0.60 (9 cm); add `CameraShake.hold_floor(f)` so a
  running bite keeps trauma at 0.28 (a steady 2 cm rattle at the breaker's
  frequency), released at the bite's end. Keep decay at 1.6 so nothing
  lingers - these are impulses the child caused, the opposite of the drift
  the user turned off.
- **Files:** `scripts/site_config.gd`, `data/site_config.tres`,
  `scripts/camera_shake.gd`, `scripts/site_verbs.gd`.
- **Check:** smoke records the camera's peak offset during one stake blow
  (>= 0.02 m) and that it is back to 0 within 0.6 s.

### 1.5 Let the broken panel visibly break (S)
- **Today:** `Driveway.break_panel` hides the panel and builds the chunks at
  rest. `chunk_hop` (0.14) exists in the config and is never read.
- **Change:** spawn each chunk `chunk_hop` above its pose and tween it down
  over `chunk_hop_time` with a bounce, 0-80 ms random delay per chunk seeded
  off the panel, outer chunks 1.3x the hop so the panel bursts outward from
  the bite. `jack_spot` already waits `chunk_hop_time`.
- **Files:** `scripts/driveway.gd`.
- **Check:** a chunk's y at t=0 and t=`chunk_hop_time` differs by >= 0.08 m.

### 1.6 One "done" beat for every phase the bar counts (S sound + M hold)
- **Today:** `step_done` has no listener. The hose, screed and broom end with
  the loop stopping and a cut; the pour and rake end on an ad-hoc chime; the
  camera is already easing away on the frame the tenth stake lands. The last
  thing the child finished is never seen finished.
- **Change:** (a) connect `runner.step_done` in `SiteMain._ready` to play a
  new `done` clip (a soft rising two-note wood tap, two takes, -4 dB) only
  when `progress_weight > 0` and it is not the last step (whose done is the
  tada); remove the chimes at the pour's and rake's ends so the chime is only
  the parked car. Same clip every time, no escalation - a completion cue, not
  a score. (b) In `JobRunner._play_beat`, when a step completes, `await
  level.phase_done(s)`: rest the tool (`present_tool("none")`), hold the
  current shot `phase_hold` = 0.8 s, then ask for the next shot. Per-phase
  finishers so the material reads done at the hold: the last 15% of water
  wets itself over 0.6 s, the screed lifts off the kerb form with a thunk,
  the bay's `broom_dry` completes over 0.5 s and the broom lifts.
- **Files:** `scripts/site_main.gd`, `scripts/job_runner.gd`,
  `scripts/site_verbs.gd`, `scripts/site_config.gd`, `assets/sfx/`,
  `docs/sfx.md`.
- **Check:** after the spray beat `last_played == "done"`; after
  `skid_leave` it is not; after the tenth stake `rig.current_shot` is still
  STAKE 0.5 s later.
- **Touches the decided list:** "a beat ends with the next target in the
  picture" (third playtest). The 0.8 s hold comes first and the cut follows,
  so the next target still arrives.

### 1.7 Engines lean into the work under the finger (S)
- **Today:** `Sfx.set_loop_pitch` and `set_loop_trim` exist ("an engine
  leaning into the work") with no caller. The skid steer shoves nine metres at
  its parking idle.
- **Change:** `_hold` takes an optional `engine_voice`; while flowing, lerp
  the voice to `engine_lean_pitch` 0.90 and `engine_lean_db` +2 over 0.25 s,
  back to rest when the finger lifts. Pass "skid" from `push_rubble` and
  "dump" from `tip_gravel`. Not the mixer: the drum is not an engine under
  the child's load and the rake is a hand tool. The working engine still sits
  7 dB under the tools, so "vehicles too loud" stands.
- **Files:** `scripts/site_verbs.gd`, `scripts/site_config.gd`.
- **Check:** during `push_rubble` with the finger down 0.5 s,
  `loop_report()["skid"].pitch < 1.0`; back at rest after release plus
  `hold_burst` plus 0.25 s.

### 1.8 A tap on a machine honks it (S), and the arrival's last leg is a hold (M)

**DONE 2026-09-15: the S half in session 2, the M half in session 5** (the
user's decision 4). Built as two rows per truck - the street leg a BUTTON, the
reverse a weight-0 HOLD (`back_dump`, `back_mixer`, target `Back:` so a finger
still down at the stop does not start the tip or the pour) - walked by
`Machine.set_path`/`place_on_path` over `back_time` 4.5 s of holding with a
`back_ramp`; a finger pressed on the truck as it comes down the street and kept
down backs it in when it stops. The skid steer still drives itself.
- **Today:** while a machine arrives or leaves, `_press` either kicks GO
  (BUTTON step) or falls to `runner.tap()` which returns false (AUTO step).
  `horn_1/2.mp3` and `voice_hatchback_1/2.mp3` sit imported and unused.
- **Change (S):** on an AUTO beat or a busy BUTTON beat, raycast the tap; on
  a `Machine` or the car play its horn through the vehicle trim and flash its
  beacon (see 4.5); elsewhere nothing. GO does not kick while the runner is
  busy. The user's rule: a tap is answered by the thing under it, even when
  that thing is not the work.
- **Change (M, optional, touches "the machines drive themselves"):** the last
  3.9 s of each arrival (the reverse leg) only moves while the finger is on
  the truck - the child is the banksman waving it in, which is who stands
  there on a real job. The street leg stays automatic and slow.
- **Files:** `scripts/site_main.gd`, `scripts/machine.gd`, `scripts/sfx.gd`,
  `docs/sfx.md`.
- **Check:** a press on the tipper's screen box during `call_dump` sets
  `last_played == "horn"`; a press on the lawn plays nothing.

---

## 4. Tier 2 - the pour is the child's (the centrepiece)

### 2.1 UP means up, and the pour gets its mime (S)
- **Today:** UP adds +Z to the truck, which is toward the camera in the CHUTE
  frame; the concrete goes down the screen when the child presses the arrow
  that points at the garage. `_hint_kind` returns NONE for pad verbs, so a
  stuck child gets a gold arrow over an empty cell they cannot do anything
  about by touching it, and a tap on the chute or the pool is accepted and
  does nothing.
- **Change:** flip the up/down sign in `pour_chute` and the two smoke checks
  that assert it. After `chute_hint_delay` of no pad, `_hint_kind` returns
  HOLD and the mime stands on the PAD that moves the pour toward
  `emptiest_in_band` (the smoke already contains the rule: dx < -0.25 left,
  dx > 0.25 right, dz up/down); wake on any pad press. A tap on the picture
  nudges the nearest useful pad.
- **Files:** `scripts/site_verbs.gd`, `scripts/site_main.gd`,
  `scripts/site_hud.gd`, `scripts/tools/site_smoke.gd`.
- **Check:** enter the pour, wait `chute_hint_delay`, assert
  `hint_visible()` and `hint_position()` inside the named pad's rect.

### 2.2 A finger on the form steers the chute (L, pushes on the decided list)
- **Today:** the pads are the one abstract control in a game where every
  other tool goes where the finger goes. Aiming at a corner needs both thumbs
  on opposite corners of the tablet. The user's own picture was "the man
  holding the chute controls the pour" - and a man holds a chute by its end.
- **Change:** a finger held on the spout (within `drag_grab`, sticky) or on
  the form drops onto the slab plane; solve the machine from the landing
  point - swing from the target's x on the spout's arc (clamped to
  `chute_swing_deg`), truck z from the target's z plus reach (clamped to the
  road creep) - the inverse of `Machine.pour_point_world`, with the chute and
  the truck still limited to `chute_swing_rate` and `truck_creep_speed` so
  nothing teleports. The mime becomes DRAG on the spout; the gold arrow over
  the emptiest cell now points at something the finger can carry the stream
  to. The pads stay wired for a stick and the keyboard.
- **Why it is worth the conflict:** it keeps the whole chute game the user
  asked for (the real chute, the swing, the creep, the band, the come-along)
  and changes only the control to the grammar of the hose they loved. The
  pads were the implementation of the ask, not the ask.
- **Files:** `scripts/site_verbs.gd`, `scripts/site_main.gd`,
  `scripts/machine.gd`, `scripts/site_config.gd`, `docs/DESIGN.md`.
- **Check:** `set_work_cursor` on the far-left kerb cell and hold; swing goes
  negative and `band_fraction` rises in that column.

### 2.3 Give the steered pour more than ten seconds (M)
- **Today:** the band is about six seconds of ideal pouring; concrete pours
  every frame whether or not a pad is pressed; the beat ends on the band's
  AVERAGE reaching 0.88, which slump largely does alone. The one control the
  child has to learn is over before they have tried all four.
- **Change:** split `pour_time` 18 into `chute_pour_time` 30 (0.24
  cell-depths/s while steering) and `rake_pour_time` 9; end the chute beat on
  a coverage rule like the scrubs - every band cell >= 0.5 of full - so the
  corners have to be steered to. Expect 15-20 s of steering that uses the
  whole control, with the hint after 2.2 s on whatever corner is still sandy.
- **Files:** `scripts/site_verbs.gd`, `scripts/site_config.gd`,
  `scripts/driveway.gd`.
- **Check:** with no input the chute beat does not end inside 20 s; with the
  smoke's competent pair it ends inside 30 s.

### 2.4 The child's hand is the come-along's only bottleneck (S)
- **Today:** `rake_rate` 0.60/s draws faster than the chute supplies
  (0.10 x 72 / 18 = 0.40/s), and `rake_to` draws band cells only down to
  `RAKE_FLOOR` 0.35. After three seconds the kerb heap is drained and the
  remaining fill trickles at the truck's pace whatever the finger does. A
  tool that stops working under a moving finger reads as "I am doing it
  wrong".
- **Change:** treat the drum as a reservoir - while it spins, `rake_to` may
  draw from the band without waiting for `pour_at` to refill it (the drum
  holds far more than a driveway) - or run the chute at 0.80/s during the
  rake. Then the rake is about 8 s of ideal dragging, 15-20 for a child, and
  every stroke on sandy concrete moves mud. Family rule: the finger must be
  the only bottleneck; a hidden supply cap reads as a broken tool.
- **Files:** `scripts/site_verbs.gd`, `scripts/driveway.gd`,
  `scripts/site_config.gd`.
- **Check:** a stroke over a short cell always raises it while the drum spins.

### 2.5 Sticky grab and a walking speed that exists (S)
- **Today:** DESIGN 6.7 and the critic log say the board goes "no faster than
  a person walks it (`screed_drag_speed` 2.2 m/s)". No such export exists;
  `screed_pull` clamps the line to the finger's z with no rate, so one flick
  strikes nine metres in a third of a second. The grab test is re-run on
  every event, so a finger that drifts a hand's width off the line near the
  horizon silently drops the sled mid-groove.
- **Change:** add `screed_drag_speed` 1.2 m/s and `joint_drag_speed` 1.5 m/s
  to `SiteConfig` and `site_config.tres`; advance the tool by at most
  `speed * dt` toward the finger. Take the grab once at the press and keep it
  until release. For the screed and the joint, skip the whole-slab press
  shortcut in `tap_counts` and measure the press against `drag_hint(verb)`
  plus reach, so an off-tool press gets the nudge at once instead of 2.2 s of
  nothing. The hose, rake and broom keep the anywhere start.
- **Files:** `scripts/site_verbs.gd`, `scripts/site_config.gd`,
  `data/site_config.tres`, `scripts/site_main.gd`.
- **Check:** a cursor jumped apron-to-kerb in one frame leaves the board less
  than 0.1 m on; a cursor 1.5 m off the joint line after a grab still cuts.

---

## 5. Tier 3 - pacing and the story of the job

**DONE 2026-09-15 (session 3).** `SITE_SMOKE PASS 295/295`, `MACHINE_PROBE
PASS 13/13`; the session is logged in `docs/critic_log.md`. Built to the
plan's defaults where a decision was open: the machines leave in the
background (decision 3) and the YAY! banner stays (decision 2). One change to
0.1's text: the house does not come back beside NEXT at the payoff - NEXT
comes up alone, and the house waits for the title screen. Decision 1 was
closed by the user before this session: the pads stay, 2.2 is off the list.
An eight-agent adversarial pass over the session found twelve things (the
log's "verification pass" section): the cure re-showed the heap, the kit went
mid-swing, the cones stood ON the slab and buried in the footway, the skid
steer's exit clipped the pad, the full bar was never seen, a miss dimmed the
bar, the toots overlapped, the wide's finger reach was a slab, the payoff was
deaf, the leave idle stopped dead, five slack smoke checks, and two dead
clips. All twelve fixed; `SITE_SMOKE PASS 305/305` (was 295), `MACHINE_PROBE PASS 13/13`.

### 3.1 Open on the cracked driveway (S)
- **Today:** `runner.start(job, drive, false)` snaps to PANEL: the first frame
  of the game is a grey close-up with three rings and a floating tool. The
  child has never seen the house or that the drive is cracked. DESIGN 1a says
  WIDE is "the opening and every payoff"; nothing plays it.
- **Change:** snap WIDE with the rings lit on the first slab, hold 1.5 s or
  until the first touch, then ease to PANEL over 1.2 s. Rule: a job opens and
  closes on the same wide picture, so the payoff is the child's own
  before-and-after.
- **Files:** `scripts/site_main.gd`.
- **Check:** frame 0's shot is WIDE with rings visible.

### 3.2 Machines leave in the background after a two-second look (M)
- **Today:** the three AUTO leaves await `send_machine` in full: 6.0, 7.6 (plus
  the heap fade) and 7.0 s of a truck getting smaller, each placed right
  after the child's own effort.
- **Change:** the leave verb awaits 2.0 s of WIDE on the result, then returns
  while `send_machine` runs un-awaited; the runner enters forms / rebar /
  water while the truck is still trundling (FORM, BARS and HAND do not see
  the street, or see it harmlessly far off). The next `bring_machine` is
  always more than 6 s away. Keep `leave_time` 6.0 - the user's slow
  residential trucks. Raise `tip_time` 4.0 to 6.0 so the tipper's own hold
  outlasts its exit look. Saves about 15 s of dead air per job.
- **Files:** `scripts/site_verbs.gd`, `scripts/site_main.gd`,
  `scripts/site_config.gd`.
- **Check:** the forms' first ring is live within 3 s of the second push
  ending; no machine is mid-route when the next is called.

### 3.3 The payoff lands on the parked car (S)
- **Today:** the tada, the sparkles and the banner fire the instant the last
  broom stroke ends, over a slab with the forms still on; then 10.7 s of
  quiet (strip 1.0, cure 2.2, park 7.5) ending on a small chime. The
  emotional peak is spent ten seconds before the picture the user asked for.
  `next_min_time` is declared and never read. The 26 hand-sized sparkles are
  invisible from the 3 m wide (`15_done_wide.png`).
- **Change:** keep the tada at the last stroke (it answers the child's work,
  as in Car Garage) but hold BROOM 0.8 s first (1.6). Swap the two awaits so
  the light moves BEFORE the boards come off (boards do not come off a
  broomed slab a second later). Fade the HUD (bar, hat, house) out over the
  cure so STREET and PAYOFF are picture only; NEXT alone comes in after the
  park. At the park: the car's own voice (`voice_hatchback`, on disk; `horn`
  as fallback) twice, `horn_delay` 0.30 and `horn_gap` 0.45, brake lights
  if the GLB has them, then NEXT. Delete the sparkle emitter and its three
  numbers (furniture the toy does not need). Duck the song to -30 dB over the
  cure with a new `Sfx.fade_music`; the reload on NEXT restores it.
- **Files:** `scripts/site_main.gd`, `scripts/site_hud.gd`,
  `scripts/toy_hud.gd`, `scripts/sfx.gd`, `scripts/site_config.gd`.
- **Check:** `last_played` is the car's voice group after the park; the bar's
  modulate alpha is 0 during PAYOFF.
- **Open decision:** the "YAY!" banner is text on a screen that promises no
  words. It is a family convention (Tree Crew's TIMBER!). Keep it or make it a
  picture (the hard-hat badge growing into a gold ring that bursts) - your
  call, listed once here.

### 3.4 The cure is a shape, not a light (S)
- **Today:** the two cones stand wide of the drive on the footway and FADE
  during the cure; the lesson "you do not drive on new concrete" is carried by
  the sunset alone, which a child reads as "it got late". The tools, fence and
  heap also dissolve in front of the child on the WIDE - the only magic in an
  honest job.
- **Change:** after the strip, slide the cones to the mouth of the drive at
  the kerb (x = CENTRE_X +/- 1.1, z = kerb - 0.35) over 0.8 s and hold them
  through the light sweep; lift them out under STREET before the car turns
  in. Remove the tools, fence and heap at the cut to STREET, before the car
  enters frame, with one clunk (the crew's van door), never on camera. Rule:
  on a site things are carried off; nothing fades.
- **Files:** `scripts/site_main.gd`, `scripts/driveway.gd`.
- **Check:** both cones within 1.3 m of the mouth at cure k = 1.0; both gone
  and the kit hidden before the car's second route.

### 3.5 Reversing beeper and air brakes, not a boing (S)
- **Today:** `bring_machine` plays the celebration's cartoon `boing` before
  every reverse leg and `clunk` at the stop. The single most recognisable site
  sound to a three-year-old - beep-beep-beep - is absent; `hiss_1/2.mp3` sit
  unused.
- **Change:** generate `reversebeep` (4 s, loop, two takes, per the recipe
  in `docs/sfx.md`); play it as voice "beeper" at -6 dB for the tipper's and
  mixer's reverse legs only, stop at the stop; `hiss` at the stop for the two
  trucks, `clunk` for the skid steer's spin. Delete boing from the game and
  from `group_gain_db` (nothing else plays it; the sfx doc's "boing is the
  celebration" line is stale - `_celebrate` plays tada only).
- **Files:** `scripts/site_main.gd`, `scripts/sfx.gd`, `assets/sfx/`,
  `docs/sfx.md`.
- **Check:** after each truck's arrival `is_looping("beeper") == false` and
  `last_played == "hiss"`.

### 3.6 The bar measures the child's minutes, not their taps (S)
- **Today:** weights sum to 59 (the .tres header says 52, DESIGN says 63 -
  nobody looks at the number). 44 of 59 are spent before the pour, so the bar
  reads "nearly done" at the mixer and then barely moves through the ninety
  most hands-on seconds of the job.
- **Change:** pour 6, rake 8, water 4, screed 4, joints 1 each, broom 2 each
  (total 74; the mixer is called at 59%). Fix the header and DESIGN 2 to the
  computed total; smoke asserts `total_weight()` against one named constant.
- **Files:** `data/jobs/new_driveway.tres`, `docs/DESIGN.md`,
  `scripts/tools/site_smoke.gd`.

### 3.7 The HUD steps back while the finger is down (S)
- **Today:** the bar and hat sit on the breaker's handles, the skid steer's
  roof, the tipper's bed and the chute in six of twenty HUD frames. Round 14
  left it "as decided" - do not move it, it is shared with the siblings.
- **Change:** fade the bar and hat to 0.35 alpha while a beat is live (finger
  down, a bite or hold running), back to 1.0 on release, over 0.2 s, on the
  hooks that already wake `hint_tick`.
- **Files:** `scripts/site_hud.gd`.

---

## 6. Tier 4 - show the thing (visual, in the picture-book sense)

**DONE 2026-09-15 (4.1-4.7; 4.8 not taken).** Green: `SITE_SMOKE PASS 332/332`
(was 305) and `MACHINE_PROBE PASS 16/16` (was 13); logged as the last section of
`docs/critic_log.md`, contract in `docs/DESIGN.md` 7c, frames in
`renders/critic/session4/`. Where the build departs from the text below:
4.1's slab is SETTLED 5 cm down along the seam, not heaved (a raised edge's
riser faces away from both kerb-end eyes), and the stains were already there;
4.2's cap is survey PINK (orange read as a chair), and the sledge's blow was
made honest on it; 4.3's hose does not sway (it leaves the picture within a
few centimetres; the spring measured 0 px at 16:9) and it shows at a near aim
and on 4:3 only; 4.4's orange is a new darker `ToolOrange` (the breaker's renders
level with the slab), and the grip already existed; 4.5 found `flash_beacon`
had never lit anything (Beacon was not in `Machine.CONTRACT`) and the API is
`Machine.set_beacon_on`; 4.6's eye is (0, 0.62, 2.4) looking (0, -0.16, -1.0) on
group 0's own mark (it was (0, 1.7, 3.0), not the BARS define), and the long
bars wait 2 cm up with their kerb ends swung inward; 4.7 has one gravity for
fall and bounce, no pairs-per-tap and no chair flex.

### 4.1 The old drive looks BROKEN from the wide (M)
- **Today:** `02_old_wide.png` is a beige path with thin ink lines and tint
  patches; the critic brief's own first question ("could they tell what was
  wrong before they touched it?") is answered no at tablet distance. The fault
  has ink but no SHAPE.
- **Change:** in the panel builder next to the crack code: three or four
  low-poly weed tufts at crack vertices per panel (green on grey is the
  highest-contrast thing a child can read); the kerb-end panel heaved 2
  degrees with a corner 4 cm proud of its neighbour, so the seam is a step
  (the first ring stands on it); two dark stains per panel at 0.85 of the
  slab's value. All of it goes with the panel on break.
- **Files:** `scripts/driveway.gd`.
- **Check:** a crop of the wide at 1280x720: weeds >= 6 px tall.

### 4.2 Stakes are timber with a painted cap (S)
- **Today:** `STAKE_GREY` sticks against brown earth; the garage-end one
  nearly vanishes against the apron; the ten stubs DESIGN says are "left
  proud so the child's stops leave a mark" are grey specks.
- **Change:** pale sawn-timber body a step paler than the board, and a 6 cm
  safety-pink or orange cap, as real survey stakes have. The ring sits on the
  cap, the sledge hits it, the cap is what stays proud - ten bright dots down
  the boards in every later wide.
- **Files:** `scripts/driveway.gd`.

### 4.3 The hose has a hose (S)
- **Today:** `11_water_hand.png`: the green nozzle floats in the corner with
  a bare stub where the hose should be, in the beat the user singled out for
  "like you are the one spraying".
- **Change:** a 3 cm tube off the nozzle's butt that sags down and right and
  runs OFF the bottom edge of the frame in camera space (as `hose_hold`),
  with a slight sway when the aim moves. The rule the rake, groover and broom
  already obey: a held tool is connected to the bottom of the picture.
- **Files:** `scripts/hand_tool.gd`, `scripts/site_main.gd`.

### 4.4 The groover gets a tool colour (S)
- **Today:** `13_joint.png`: a dark-grey sled on a grey slab, the least
  visible tool in the game and the one the child has to find within
  `drag_grab`. Round 13 chose dark steel because pale metal rendered 58% over
  the slab.
- **Change:** a hue step, not a value step: the family's tool orange at the
  same 0.30-0.40 luma, dark steel only on the bottom edge, a bright grip on
  the handle's top. Rule: every hand tool worked on the slab carries one
  saturated brand colour, because the slab will always be grey.
- **Files:** `scripts/hand_tool.gd`, `tools/make_site_props.py`.
- **Touches round 13 F5:** keeps its measured luma, changes only hue.

### 4.5 Light the beacons (S)
- **Today:** `machine.gd`'s contract lists a Beacon on all three fleet
  machines; no code references it. A blinking amber light is the one bit of
  character a machine can have that is not a face and is honest.
- **Change:** `Machine.set_working(on)`: pulse the Beacon's emission (about
  1.2 Hz) and a small OmniLight while the machine arrives, works and leaves;
  off when parked or off-stage. Same call sites as the diesel idle. Pair with
  1.8's honk-on-tap flash.
- **Files:** `scripts/machine.gd`, `scripts/site_verbs.gd`.

### 4.6 A low eye for the long bars, so the chairs' lift shows (S)
- **Today:** the steel phase's stated lesson (DESIGN 2d) is that the bars sit
  UP on chairs; from the 1.25 m BARS eye (`09_based_bars.png`) the chairs are
  flat orange squares and every bar lies on the gravel. Round 15 left "the
  chairs' lift from the close eye" as found.
- **Change:** for bar group 0 only, an eye about (-0.6, 0.62, 1.7) looking
  (0.1, -0.16, -0.5) so the cradle posts stand against the far gravel with a
  dark gap under the bar; keep the current eye for the cross-bar pairs. If the
  four keep-scale rings overlap from the low eye, lay the long bars as two
  pairs, which also brings the eye closer.
- **Files:** `scripts/site_main.gd`, `scripts/driveway.gd`.
- **Check:** in the group-0 frame, >= 5 pixel rows between the first bar's
  underside and the gravel at its near end.

### 4.7 The rebar landing is an event (M)
- **Today:** twelve identical taps between the sledge and the pour: a 6 cm
  drop, a small swing, a clang. The picture before and after is the same grid.
  It is the longest tap-count in the job with the least on screen per tap.
- **Change:** the bar overshoots and bounces twice on the chairs (3 cm then 1
  cm over 0.3 s), the chairs flex, the clang on first contact; as a cross bar
  settles the black ties POP onto each crossing in sequence down the bar
  (four pops at 60 ms), so one tap plays a little run across the picture.
  Optionally the cross bars go in as a pair per tap (8 taps instead of 12) -
  still twelve bars laid by the child, still skewed beside their places.
- **Files:** `scripts/site_verbs.gd`, `scripts/driveway.gd`.
- **Touches the decided list:** "twelve bars" stays; only taps-per-pair and
  the landing animation change.

### 4.8 Later, if wanted: the day passes (M)
Sweep light colour and horizon only (never the sun's azimuth - every shadow
was tuned to it) from a cool morning through the afternoon to the existing
evening, and drift two or three low-poly clouds across the wide's seventh of
sky at 0.15 m/s. A child notices the world moving when nothing is being
touched. Not before the tiers above.

---

## 7. Tier 5 - learning beats worth adding (each is a PLACE the child works)

**DONE 2026-09-15 (session 5): 5.1, 5.2 and 5.3, with 1.8's hold** - the user
chose 5.1 and 5.2 (decisions 6 and 5); 5.3 needed no decision. Green:
`SITE_SMOKE PASS 446/446` (was 332) and `MACHINE_PROBE PASS 20/20` (was 16); logged as
the last section of `docs/critic_log.md`, contract in `docs/DESIGN.md` 7d, frames
in `renders/critic/session5/`. Where the build departs from the text below:
5.1's plate is a DRAG through `_scrub`, not `_hold` (a still finger must pack
only a plus sign), one beat per bay (count 3, 6 stops), the plate moved only by
a finger ON it; its eye is a new `PLATE` shot from the bay's kerb side, and the
rattle is a shake FLOOR (`shake_plate_floor`), because "0.012 every held frame"
never beats the decay; the packed colour is a luma step baked into the base at
the end. 5.2's groups were cut by INDEX, not position: which boards are live is
now state (`Driveway.form_live`/`stake_live`), and the old first `form_set` beat
that re-hung every board would have lifted the three in; the crossing now starts
behind the kerb trench, so the cones moved out to `CONE_MOUTH_OUT` 0.40. 5.3 has
a cure ROW before it (`slab_cure`, weight 0) so the boards come off a cured slab,
a new `STRIP` shot holding all three, a tap anywhere on a board counting, the
boards carried to a pile on the right lawn (never faded; a 9 m board has no room
beside its own edge on this lot) and carried off at the cut, and the tada moved
to the last board. The plate's eye walks after it between strokes (`PlateView`). The job is 25 rows and 83 stops; stages and `--step`
name verbs now.

Judged by three tests: is it honest, is it a place the finger covers, would a
four-year-old find it fun. Three pass; three were considered and rejected.

### 5.1 A plate compactor before the steel (L)
- **Today:** the tipper drops stone, drives off, and the child lays steel
  straight onto loose tipped rocks (`09_based_bars.png`). Nothing ever makes
  the base FIRM; the picture of a driveway is "concrete on pebbles". The
  stretch from the tip to the pour is the longest with no big-feel beat.
- **Change:** a new row between `dump_leave` and `rebar_lay`: HOLD on the
  slab, verb `compact_base`, tool `plate`, shot SURFACE (behind the plate,
  low, like the screed). Built on `_scrub`: a `_packed` value per cell rises
  under the plate; a packing cell's stones lerp flat and sink to `BASE_TOP`;
  the gravel goes a step lighter where packed (the luma-step rule); the camera
  rattles at 0.012 every held frame; a `platerattle` loop. A new
  `HandTool` kind and a prop from `make_site_props.py` with the handle
  running off the bottom of the frame like the rake's.
- **Why:** the loudest, most physical machine a child ever sees a person
  hold; holding IS the work; the ground visibly changes from lumps to a bed
  under the finger; and it carries the one base lesson a child can see.
- **Files:** `data/jobs/new_driveway.tres`, `scripts/site_verbs.gd`,
  `scripts/driveway.gd`, `scripts/hand_tool.gd`, `tools/make_site_props.py`,
  `scripts/site_main.gd`, `scripts/site_config.gd`, `docs/sfx.md`.
- **Check:** stones flat and coverage >= 0.85 before rebar; a still finger
  packs only a plus-sign.

### 5.2 The kerb board goes in after the base (M, touches the phase order)
- **Today:** the child stakes the kerb board, then watches an eighteen-tonne
  tipper reverse over it into the form (`08b_tipper_wide.png`, the truck
  inside the staked forms). The stakes' lesson - the boards are pinned so
  nothing moves them - is undone by the next beat.
- **Change:** keep the two long boards and the expansion strip where they
  are; give the kerb board its own short pair of rows after the tipper has
  gone (and after the compactor): `form_set` x1 from the road, `stake_drive`
  x2 from the road's edge - how a crew closes a form the trucks back through.
  `form_group` / `stake_group` already cut by position.
- **Files:** `data/jobs/new_driveway.tres`, `scripts/driveway.gd`,
  `scripts/site_main.gd`, `scripts/tools/site_smoke.gd`, `docs/DESIGN.md`.
- **Check:** the kerb board's k == 0 while the tipper is on the pad.
- **Touches the decided list:** "the phase order is the user's". The three
  sides keep it exactly; only the fourth board moves. Your call.

### 5.3 The child strips their own forms (M)
- **Today:** the boards the child set (four taps) and pinned (ten blows) lift
  and fade by themselves one second after the last broom stroke.
- **Change:** a TAP x3 row `form_strip` after the cure (the strip excluded,
  as `strip_forms` already does), all three ringed at once like `form_set`:
  the board hinges outward about its bottom outside edge and lifts, stakes
  with it, the bank backfills, and the clean concrete edge is the reveal.
  Then STREET and the car as now.
- **Why:** what the child put in, the child takes out - the same rule the
  user applied to the joints and the screed: do not let the toy do the
  child's action for them.
- **Files:** `scripts/site_main.gd`, `scripts/driveway.gd`,
  `data/jobs/new_driveway.tres`, `scripts/site_verbs.gd`.

### Rejected on purpose
The bull float (a second screed the child cannot tell from the first, in a
finish that already has eight drags), a curing-compound sprayer (the hose
again on a finished slab), and the edger (honest and fun, but a ninth drag is
a chore - hold it for a shorter second job where there is room).

---

## 8. Tier 6 - replay, shell, product

### 6.1 The second driveway is a different driveway (S to M)
**DONE 2026-09-15 (session 6), with 6.2.** `SiteLook` draws the car (six
homeowners', in Car Garage's paints and their own voices), the house and garage
swatch and a vetted crack base from one seed per visit; seed 0 is the legacy lot
and every harness with no seed plays it (the pre-change frames re-taken differ
only by their own wall-clock ring pulse, a mean of 0.03 of 255 at most); NEXT
draws a visit that differs in car, house and cracks. Two
corrections to the item below: the vehicles are NOT Synty - they are Car
Garage's own `tools/make_vehicles.py` builds, loaded by `Machine`, which is what
lets them sit in this PUBLIC repo - and only three of the six have a paint
surface (the police car, taxi and ice-cream van are liveries). A car now parks
by its nose (the pickup went through the shut garage door at the old spot).
- **Today:** NEXT reloads the identical scene: the same cracks (seeded off
  the panel number), the same cream house, the same red hatchback. Nothing
  about the second play is the child's to discover.
- **Change:** one `play_seed` per visit (`--seed=N` pins it for shots and
  the smoke, as the tow scene does; no seed keeps today's numbers so every
  existing render stays reproducible). Drawn from it: the homeowner's car
  (Hatchback, the unused Pickup, and PoliceCar / Taxi / Van / IceCreamVan
  from `car-fixer/assets/models/vehicles` - the same Synty pack the same
  loader already reads; the user's own Car Fixer taste) with its body swatch
  recoloured; the house and garage wall from four swatches; the crack and
  stain seeds; the car's own voice at the park. NOT varied: the order, the
  panel count, the lot. Car Garage's rule: the job is the same, the thing you
  do it for is different every time.
- **Files:** `scripts/driveway.gd`, `scripts/site_main.gd`,
  `scripts/tools/site_smoke.gd`, `scripts/tools/shot.gd`,
  `assets/models/vehicles/`.

### 6.2 The job survives the house and the tablet being taken away (M)
**DONE 2026-09-15 (session 6).** Built differently from the item below where the
item was wrong: the save is written on `JobRunner.place_changed` (a step
entered, a beat landed), not `beat_done`, which fires mid-hold and never for the
calls, back-ins and leaves; it names the row by verb and nth with the job's row
count and WHICH places are done (`places`), because a count cannot say the child
laid bars 3 and 1 - the item's own check would have passed on bars 1 and 2; and a
resume poses the world as play leaves the row (`pose(..., play = true)`), not
the screenshot pose, whose tricks hide the held tools and the pour's truck.
`RESUME_PROBE` resumes every row the child works at its start and one place
before its end.
- **Today:** `save_game.gd` is here and "NOTHING WRITES IT". Closing the app
  mid-job loses every stake, bar and the pour.
- **Change:** on `beat_done` write `{version, job, step, done}` (no
  timestamp - the privacy policy says no history of when the app was used);
  clear on `job_done`. On launch with a save, invert `STAGE_STEP` and call
  what already exists: `pose(stage, step, done)` parks the right machine,
  opens the door, sets the forms/stakes/bars/joints/bays by count; then let
  the runner run. A HOLD or SCRUB resumes at its own start.
- **Files:** `scripts/site_main.gd`, `scripts/save_game.gd`,
  `scripts/job_runner.gd`, `scripts/tools/site_smoke.gd`.
- **Check:** play to the rebar beat with 2 bars down, save, reload, assert the
  world equals `pose('based', job.index_of('rebar_lay'), 2)` and the bar reads the
  same stop. (Steps are looked up by verb since session 5.)

### 6.3 A title row that is the job picker (M, the deferred port)
**DONE 2026-09-15 (session 7).** Built as the item says, with three things it
did not foresee. The BACKDROP is `scenes/site.tscn` itself, instanced with a new
`SiteMain.dress_only` and posed - not a dressing scene, which would have split
the posed states across two files - so the row stands on a fresh cracked drive,
on the drive the child left (posed from the save, `dress_from_save`), or on the
one they have just finished with the car on it. There is no second word-card
page and no word anywhere on the screen, so the name (decision 7) is off this
item's critical path entirely. And "carry on / new drive" is TWO controls, not
one: a tap on the job's disc is always the safe thing (start it, or carry on),
while throwing a half-built drive away is a smaller disc in the other corner,
held 0.9 s with a ring filling round it - 0.1's own number, and the widget 0.1
will hang on the house.
- **Today:** the app boots straight onto the cracked drive; NEXT hard-cuts
  from the evening reward back to daylight.
- **Change:** port `title_main.gd` + `start_menu.gd` from car-fixer (PropIcon,
  Brand, the fonts and OFL texts are already here). One seat per job from a
  `data/jobs/jobs.json`, each seat a PropIcon of that job's hero (the
  driveway: the skid steer wearing its blade, exactly as `MachineIcons`
  builds it). No second word-card page (Tree Crew deleted its as a one-way
  door). The title's 3D dressing is the lot itself - after a finished job,
  the drive with the car still on it, so the reward lingers behind the next
  choice. NEXT and home go here.
- **Files:** `scenes/main.tscn`, `scripts/title_main.gd`,
  `scripts/start_menu.gd`, `data/jobs/jobs.json`, `project.godot`.
- **Touches the decided list:** "no title screen in the prototype" - deferred,
  not rejected. This is that port, needed because 0.1, 6.2 and 6.4 all need
  somewhere to stand.

### 6.4 The Kids-category chrome, in this order (L, the checklist)
**Parts 1, 2, 3, 5 and 7 DONE 2026-09-16 (session 8); 4 and 6 are what is
left.** The settings cog is on BOTH screens (a four-year-old learns one place
once, and "reachable from inside the app" cannot mean "from the one screen the
reviewer opened"); it pauses the job under it and lets go of every finger that
was down, including the title's held "new drive" disc, which would otherwise
have thrown a saved job away when the panel closed. The privacy link sits behind
the arithmetic gate. Every corner control now walks in off the hardware's own
insets - including the four steering pads and GO's halo, neither of which the
sibling's version covers - and `safe_area_probe` measures both screens at
1565x720 and 1280x960. Reduce-motion stops the CAMERA only: `Settings.motion_reduced()`
guards `shake()`, `hold_floor()` and the shake's own `_process`, while the
slab's kick, the bit's stroke, the rings and every answer to a finger keep
moving. The notices file, the two generated Godot licence texts and a
`.gdignore` on `renders/` are in. **Part 6, the name, is answered: Build Crew.**
Part 4 (export presets, the fifteen icons, the splash, the bundle id) is the
only piece left, and every place the name has to go is listed in the session-8
log.
1. The settings cog, the eleven-step slider and the music toggle
   (`settings_menu.gd`; `Settings` is already here, so this is UI only). It
   is the one thing a parent reaches for in the first two minutes, and the
   user's own "vehicles too loud" was a parent reaching for a control that
   is not there. Take this one before the rest.
2. The privacy link behind the arithmetic gate (`parental_gate.gd`,
   `privacy_probe`).
3. `safe_area.gd` for the house and the bar; run the safe-area probe at
   1565x720 and 1280x960.
4. `export_presets.cfg` from car-fixer (bundle id, device family 2, iOS 15,
   filters keeping `renders/`, `scenes/dev/`, `scripts/tools/`, `tools/`,
   `docs/` out and `licenses/*.txt` in), the fifteen icon sizes (the skid
   steer's blade on a cracked slab, the warm orange frame, no words), the
   splash through `make_splash.gd`.
5. `THIRD_PARTY_NOTICES.md` and the two Godot licence texts; a `.gdignore`
   on `renders/` (every critic round's PNGs import as textures on a fresh
   clone).
6. Decide the name once: "Build Crew" (the docs) or "Build Site" (the brand
   doc). The privacy policy on the site adds this app and its two files.
7. Reduce-motion: read `DisplayServer.accessibility_should_reduce_animation()`
   into a flag; `shake()` early-returns on it; the slab's own kick and the
   bit's stroke still move, only the camera does not.

### 6.5 The next jobs, judged (L each)
Judged by: reuses the verbs and machines already built, teaches something
new, is a place-based job a child can do. No town, no currency, no economy.

1. **The sidewalk flag** - the short job. One cracked flag at the kerb, about
   25 stops, every beat an existing verb: three bites, one short shove, TWO
   boards (the kerb face and the neighbouring flag are the other sides, which
   is honest and teaches it), four stakes, a short curtain of stone, a sheet
   of mesh instead of bars, the chute alone fills it (no come-along - the
   centrepiece with nothing to pull, which teaches by contrast why the
   driveway needed one), water, a 1.5 m screed, one joint, one broom. Payoff:
   the car drives over the crossing. The one real change unlocks every later
   job: the slab's rectangle becomes a Slab spec (centre, width, length,
   cells) instead of constants. A three-year-old finishes this one.
2. **The fence-post footing** - the smallest job, and the first beat where
   the child sets something STRAIGHT: pull the leaning post, auger the hole
   (a jackhammer-shaped hold with a new tool and a spoil heap), drop the new
   post, PLUMB it (a drag: the post tilts with the finger and a level's
   bubble settles between two lines - Car Garage's `match` verb), brace it
   (two stake-shaped taps), a small pour from a barrow, water, hang the
   panel. About 12 stops.
3. **The back patio** - the bucket comes back (the driveway keeps the blade):
   the skid steer DIGS turf in scoops, forms, stakes, base, and the pour by
   WHEELBARROW - load under the chute (held), push it round the house (the
   camera walking behind the handles), tip it into the form (the tipper's
   hold in a new shape), six runs. Then rake, water, screed, two crossing
   joints, four bays. Payoff: a table and two chairs land on it at evening.
   It answers the question the come-along raises - how does concrete get to
   a place no truck can reach - with the real answer.

Rejected: a kerb section (a tool nobody recognises, only reads from the
road), the garage floor (under a roof no shot can look into), front steps
(tiered forms are carpentry; every shot would be of plywood).

---

## 9. Tier 7 - the test debt these changes create

The smoke is green at 221 checks and does not hear, touch or replay:

- **Sound:** after each TAP beat `last_played` changed in that frame; during
  each HOLD/DRAG the voice's position advances and its power drops >= 6 dB
  within 0.2 s of release; `loop_report()` is empty at job end and after home
  mid-pour; the music player reaches the cure's faded value.
- **Real touch:** push `InputEventScreenTouch`/`Drag` with indices in window
  pixels (0.3), not `set_work_cursor` alone.
- **Replay:** NEXT into a second job and the first bite of it (0.2); home
  mid-job leaves progress unchanged (0.1); save, reload, resume (6.2).
- **The queue with a pick** (0.4), **the wedge as a target** (0.5), **the
  mid-ease frame** (0.6), **a fast stroke** (2.5), **a shake's peak** (1.4).
- **Drift guards:** `total_weight()` against a named constant (3.6); every
  knob the design doc names exists (`screed_drag_speed` did not).

---

## 10. The numbers, in one place

| Knob | Today | Proposed | Item |
|---|---|---|---|
| `shake_stake` | 0.08 | 0.38 | 1.4 |
| `shake_break` | 0.22 | 0.60 | 1.4 |
| breaker floor | none | trauma 0.28 while a bite runs | 1.4 |
| `engine_lean_pitch` / `_db` / `_time` | none | 0.90 / +2 dB / 0.25 s | 1.7 |
| `phase_hold` | none | 0.8 s | 1.6 |
| `pour_time` | 18 | `chute_pour_time` 30, `rake_pour_time` 9 | 2.3 |
| chute end rule | band average 0.88 | every band cell >= 0.5 | 2.3 |
| `screed_drag_speed` / `joint_drag_speed` | absent | 1.2 / 1.5 m/s | 2.5 |
| opening hold on WIDE | none | 1.5 s, ease 1.2 s | 3.1 |
| leave watched | 6.0-7.6 s | 2.0 s, rest in background | 3.2 |
| `tip_time` | 4.0 | 6.0 | 3.2 |
| `horn_delay` / `horn_gap` / toots | none | 0.30 / 0.45 / 2 | 3.3 |
| music during the cure | -15 dB | fade to -30 over `cure_time` | 3.3 |
| bar weights (pour/rake/water/screed/joint/broom) | 2/3/3/2/1/1 | 6/8/4/4/1/2 | 3.6 |
| HUD alpha while working | 1.0 | 0.35 | 3.7 |
| `reversebeep` trim | none | -6 dB | 3.5 |
| stake cap | none | 6 cm, safety orange or pink (built: pink) | 4.2 |
| BARS eye, group 0 | (0, 1.7, 3.0), its own mark | (0, 0.62, 2.4) looking (0, -0.16, -1.0) (built) | 4.6 |
| home button | tap = reload | hidden in play; later a 0.9 s hold | 0.1 |
| idle hint after a miss | clock reset | `hint_delay - 1.0`, mime on 2nd miss | 1.2 |

---

## 11. Decisions that are yours

Each of these pushes on `docs/CRITIC.md`'s decided list or on a family
convention. The plan is written so everything else can be built without them.

**Answered 2026-09-15 (before session 5):** 1 no steering (closed before
session 3); 2 KEEP the word "YAY!"; 3 background leaves (built to the default
in session 3); 4 YES, the arrival's reverse leg is a hold; 5 YES, the kerb
board goes in after the base; 6 YES, the plate compactor. **7 answered
2026-09-16: the name is BUILD CREW** - what every doc, the repo and
`project.godot` already said, and the family's own pattern (Tree Crew, Car
Garage): the CREW is the child. Nothing is left open.

1. **The pour's control:** flip the pads and mime them (2.1, inside the
   contract) - and then go on to steer with a finger on the form (2.2)?
2. **The "YAY!" banner:** keep the family's word, or make it a picture (3.3)?
3. **Machines leaving in the background** (3.2) versus watching the slow
   trucks go. If you want to watch them, keep the leave and take 1.8 (the
   honk) so the watch answers a finger.
4. **The last leg of an arrival as a hold** (1.8 M) - the banksman - or keep
   "the machines drive themselves".
5. **The kerb board after the base** (5.2) - a one-board change to the phase
   order you set.
6. **The plate compactor** (5.1) - a new machine phase and the largest
   single addition here.
7. **The name:** Build Crew or Build Site.

---

## 12. Suggested order of sessions

1. **Tier 0 in one session.** Six fixes, five of them S, and the smoke grows
   by six checks. Nothing here is a design decision.
2. **Tier 1, then 2.1 and 2.4 and 2.5.** This is the session that changes
   how the toy feels under a finger: every tap heard, every miss answered,
   the mime reachable, the shake real, the panel breaking, one done-beat
   grammar, the pour pointing the right way, the rake never starving, the
   board walking. Play it yourself after this one; it is the playtest that
   will tell you whether 2.2 is needed.
3. **Tier 3 (pacing and payoff) with 3.5 and 3.4.** Then the run is
   roughly: opening wide, about 25% watching instead of 45%, the same
   four-and-a-half minutes, ending on a car that beeps on a drive with cones
   that just came off it.
4. **Tier 4 visuals** in whatever order the frames bother you; 4.2, 4.3 and
   4.4 are an hour together. **DONE 2026-09-15.**
5. **Your decisions from section 11**, then tier 5 as chosen. **DONE
   2026-09-15** (decisions 2 and 4-6 answered; 1.8's hold, 5.1, 5.2, 5.3).
6. **Tier 6:** seed (6.1) first because it is cheap and it is the replay
   hook; then save (6.2), title (6.3), chrome (6.4), and the sidewalk flag
   (6.5) as the second job because it forces the Slab-spec refactor every
   later job needs. **6.1 and 6.2 DONE 2026-09-15 (session 6); 6.3 DONE
   2026-09-15 (session 7).**

Every session ends with `site_smoke` and `machine_probe` green and the
frames re-taken into a dated `renders/critic/` folder, as the brief already
says.
