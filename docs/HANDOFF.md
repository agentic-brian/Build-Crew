# Build Crew - hand-off (written 2026-09-16, after session 8 and the playtest)

For whichever session picks this up next. Everything below is true as of the
date above; the code and `docs/critic_log.md` outrank this file if they
disagree.

## Where things stand

- `docs/IMPROVEMENT_PLAN.md` is the work list. Its section 12 gives the
  session order. Sessions 1-6 are BUILT and marked **DONE** in the plan:
  Tier 0; Tier 1 with 2.1, 2.4, 2.5; Tier 3; Tier 4 (4.1-4.7; 4.8, the day
  passing, is optional and not taken); session 5, the user's decisions (1.8's
  held arrival, 5.1 the plate compactor, 5.2 the kerb board after the base, 5.3
  the child stripping the forms); and session 6, Tier 6's first two items: 6.1
  a different driveway per visit (`SiteLook`, one seed) and 6.2 the job
  surviving the app closing (`SaveGame`, `resume`). Each is a dated section at
  the end of `docs/critic_log.md`. Session 7 is Tier 6's 6.3, the title row that
  is the job picker; session 8 is 6.4, the Kids-category chrome - **parts 1, 2,
  3, 5 and 7 only. Part 4 (the export preset, the bundle id, the icons and the
  splash) is the one piece of 6.4 still open**, and the plan's 6.4 note says so.
  The last log section is "The improvement plan's eighth session" and its
  verification pass; read it first.
- The user answered decisions 2 (KEEP the word "YAY!"), 4 (yes, the hold), 5
  (yes) and 6 (yes) on 2026-09-15, and **decision 7 on 2026-09-16: the game is
  called BUILD CREW** (Big Little Jobs is the publisher, Build Crew is the
  game). They are recorded at the top of the plan's section 11. No decision is
  open.
- Green on 2026-09-16, after session 8's verification pass AND the playtest
  fixes: `SITE_SMOKE PASS 492/492`, `RESUME_PROBE PASS 315/315`,
  `TITLE_PROBE PASS 62/62`, `SWITCH_PROBE PASS 18/18`, `MACHINE_PROBE PASS
  20/20`, `SETTINGS_PROBE PASS 24/24`, `PRIVACY_PROBE PASS 31/31`,
  `SAFE_AREA PASS 23/23` (run twice, once per device shape) and `MOTION_PROBE
  PASS 16/16`. (The resume probe has six checks fewer than session 8's 321
  because the compaction is one beat now, not three.)
- **THE PLAYTEST OF 2026-09-16 IS BUILT** (the last section of
  `docs/critic_log.md`). Four notes, one of which was a WALL: the compaction
  could not be finished by anybody, and is a CLOCK now - `pack_seconds` 5.5,
  one beat over the whole base, anywhere, any path. Also: the sledge waits
  wound up over its peg and SWINGS down on the tap (`SiteMain.hold_sledge`);
  the skid steer's blade no longer jumps at the second push; the hose's solid
  stream is gone and the spray is the water. The job is still 25 rows and 83
  stops, so saves from before it still load.
- **There is a settings cog now, top-left of BOTH screens** (`SettingsMenu`, the
  last child of `main.tscn` and `site.tscn`), with a `ParentalGate` in front of
  the privacy link. Opening it pauses the tree AND lets go of every finger that
  was down. `SafeArea` now really lays the HUDs out, and `Settings.motion_reduced()`
  stops the shake. The WORDS RULE that governs all of it is `DESIGN.md` 7g:
  no word this game draws is for the child.
- **The app opens on the TITLE ROW now** (`scenes/main.tscn`, `run/main_scene`):
  one disc per job in `data/jobs/jobs.json`, the lot itself posed behind it, and
  a held orange disc to throw a saved job away. NEXT and the house cut back to
  it. Every harness still names its own scene, so nothing else moved.
- The job is 25 rows and 83 stops (`data/jobs/new_driveway.tres`). `compact_base`
  is ONE beat of weight 6 (it was three of weight 2), ended by
  `SiteConfig.pack_seconds`, not by coverage.
- The contract notes for the seven sessions are `docs/DESIGN.md` sections 7,
  7a-7f; `docs/CRITIC.md`'s decided list has a "since the plan's sixth
  session" bullet. `docs/sfx.md` has seventeen clips (`platerattle` the newest)
  and the six homeowners' voices with their trims.
- **A visit is drawn now.** With no `--seed` every harness plays seed 0, the
  legacy lot (the red hatchback, the cream house, crack base 917) that every
  earlier frame shows; a real launch draws a fresh one and NEXT draws one that
  differs in car, house and cracks. The save sits in
  `%APPDATA%/Godot/app_userdata/Build Crew/build_crew_save.json` while a job is
  unfinished - delete it to start a dev run from the top.
- Frames: `renders/critic/tier0/`, `session2/` .. `session8/` (with
  `session6/baseline/`, the legacy frames taken before the seed went in). Each
  session's log section records every frame's args. `renders/` is ignored by git
  except `renders/.gdignore`, which keeps the editor from importing them.
- Session 5's prop: `assets/models/props/PlateCompactor.glb`, built by
  `tools/make_site_props.py --only PlateCompactor` (Blender 4.5). Session 6's
  vehicles: `PoliceCar`, `Taxi`, `Van`, `IceCreamVan` copied from
  `car-fixer/assets/models/vehicles` (Car Garage's `tools/make_vehicles.py`
  builds, not Synty) with fresh imports. Session 8 added no asset: it added
  `THIRD_PARTY_NOTICES.md` at the root and `licenses/*.txt`, which the export
  preset's include filter has to carry into the bundle.
- Git: https://github.com/agentic-brian/Build-Crew (PUBLIC), branch `main`.
  `renders/` and `.godot/` are not tracked. The repo can be public because
  nothing in it is Synty: every GLB comes from the project's own Blender
  builders. Keep it that way - a Synty source file must never be committed here.
  **Sessions 5, 6, 7 and 8 are not committed yet** unless the user has asked
  since - commit or push only when they ask.
- The plan is mirrored as a claude.ai artifact:
  https://claude.ai/artifact/9KMi86cKwKDvk31a56xSp7. From a new conversation
  you must `read` that URL with the Artifact tool before you can publish to it
  with `url`. It was republished at the end of session 8.

## What is next

1. **A playtest.** The user has not reported playing sessions 2-6. Worth their
   eyes most: backing the trucks in (is a held finger on a moving truck fun or
   a chore, and is 4.5 s of holding right); the plate compactor (three bays of
   dragging, about 10 s each in the smoke - is it too long, and does the packed
   base read as different); the kerb board's own little phase; stripping the
   boards; the rebar phase; NEXT into a second, different driveway; and closing
   the app mid-job and opening it again.
2. **6.4 part 4, the only piece of the chrome still open.** `export_presets.cfg`
   (there is none in this project yet), the bundle id
   `com.biglittlejobs.buildcrew`, the fifteen iOS icon sizes, the splash, and
   `application/config/icon`. Car Garage's preset and its
   `tools/tidy_ios_export.py` (already copied to `tools/`) are the pattern; the
   include filter must carry `licenses/*.txt,THIRD_PARTY_NOTICES.md`. The
   marketing site's policy page also needs its Build Crew rows
   (`big-little-jobs-site`) - and while you are in that file, line 193 of
   `src/PrivacyPolicy.tsx` prints two literal `\u2014` on the parental-gate
   bullet.
3. **6.5, the next jobs.** A second seat is a line in `jobs.json` plus a
   `JobIcons` row - but read the session-7 log first: the sidewalk flag's seat
   needs a two-part picture, and three of the four next jobs would seat a
   machine that looks like the driveway's at 250 px.
4. **Small passes found and not taken** (the logs' "Not taken"): the tool
   fly-in snap shared by the sledge, the jackhammer and the screed; a kept
   tap's ring coming back through the beat it plays; held tools waiting on the
   lawn until the first press; and session 5's own list (the log).

## The session ritual (every session ends this way)

1. Class cache, then the machine probe, the resume probe and the smoke - all green.
2. Frames re-taken into a new dated `renders/critic/<session>/` folder and
   LOOKED AT (Read the PNG).
3. A section appended to `docs/critic_log.md` in its voice: what changed, the
   measurements, what was NOT taken and why, then the green line.
4. The tier marked **DONE** in `docs/IMPROVEMENT_PLAN.md` with a dated note.
5. `docs/DESIGN.md` gets a numbered section for what the session adds to the
   contract; `docs/sfx.md` a row per new clip.
6. Memory updated (`project_build_crew_improvement_plan.md` and its line in
   `MEMORY.md`), the artifact republished at the same URL.
7. An adversarial verification pass over the session's own work (one reviewer
   per item, told to refute, and an independent skeptic per finding), and what
   it finds fixed before the session is called done.

## Commands

Godot is not on PATH. The binary:

```
C:/Users/faulk/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
```

Run everything from `build-crew/` (`--path .`).

- Class cache (after any script edit; it prints parse errors):
  `--headless --path . --editor --quit`
- Importing a new clip or GLB: `--headless --path . --import`
- Probe (about a minute): `--headless --path . res://scenes/dev/machine_probe.tscn`
- Resume probe (about thirty seconds; every row the child works, saved and
  reopened): `--headless --path . res://scenes/dev/resume_probe.tscn`
- Title probe (about a minute; the row, its press, its three backdrops, the
  hold, and that the backdrop is nobody's game):
  `--headless --path . res://scenes/dev/title_probe.tscn`, and again WINDOWED at
  `--resolution 1024x768` and `1565x720`, which really do measure other shapes
  (1280x960 and 1565x720 in design units - the probe only stamps a size on a
  headless run, because the engine eats `--resolution` before a script sees it).
- Switch probe (about twenty seconds; the real trip title -> seat -> job ->
  NEXT -> title -> carry on, through `change_scene_to_file`):
  `--headless --path . res://scenes/dev/switch_probe.tscn`. It is NOT in the
  smoke: repeated scene changes crash Godot 4.7.2 about one run in three, so a
  run that dies with no PASS/FAIL line is the engine - rerun it once.
- The chrome's four probes (seconds each, and none of them touches the child's
  own save or settings file):
  `--headless --path . res://scenes/dev/settings_probe.tscn` (the cog, the
  pause, the slider by a real touch), `res://scenes/dev/privacy_probe.tscn` (is
  the published policy true of this build), `res://scenes/dev/motion_probe.tscn`
  (reduce-motion really stops the shake), and the safe area, which is run ONCE
  PER DEVICE SHAPE:
  `res://scenes/dev/safe_area_probe.tscn -- --canvas=1565x720` and
  `... -- --canvas=1280x960 --device=ipad`.
- Smoke (about ten minutes; run it in the background to a log file and grep it
  for `SITE_SMOKE` and `FAIL`):
  `--headless --path . res://scenes/dev/site_smoke.tscn`
  (it plays the legacy lot, writes its save to `user://site_smoke_save.json`,
  never the child's, and deletes it at the end)
- A thirty-second stand-in for the pour beat: `res://scenes/dev/pour_probe.tscn`
  with the environment variable `BC_DEBUG=1` (it holds the mixer's back-in row
  through `runner.hold`, so it does not test the finger path of the back-in).
- A parse check of one script (the class cache misses non-global ones):
  `--headless --path . --check-only --script res://scripts/<file>.gd`.
- A throwaway probe needs no file under `res://`: a `extends SceneTree` script in
  the scratchpad, run with `--headless --path . -s <absolute path>`, can set
  `Engine.set_meta("shot_args", {...})`, load `res://scenes/site.tscn` and read
  anything (session 5 posed every new stage this way before the smoke). Setting
  `shot_args` switches the child's save off for it; to test the save, point
  `SaveGame.path_override` at a scratch file first.
- Frames (windowed - never while a headless run is going):
  `--path . --resolution 1280x720 res://scenes/dev/shot.tscn -- --scene=res://scenes/site.tscn --out=<absolute>.png --frames=70 --stage=<stage> --shot=<SHOT> [--step=<verb>] [--hold]`
  Stages are the keys of `SiteMain.STAGE_STEP`, looked up BY VERB: old, broken,
  cleared, formed, staked, tipped (the plate), packed (the kerb board), kerbed
  (its pegs), based (the steel), rebar (the mixer's call), banded (the rake),
  poured (the water), sprayed, screeded, jointed, cured (the strip), done (the
  forms off), parked (the payoff). Shots are the constants in
  `scripts/camera_rig.gd` (WIDE, PANEL, MACHINE, FORM, TIPPER, STAKE, PLATE,
  BARS, PULL, BROOM, JOINT, CHUTE, SURFACE, HAND, STRIP, STREET, PAYOFF).
  `--step` takes a verb (`--step=pour_chute`), a verb's nth row
  (`--step=form_set:2`) or a number. The pour is `--stage=rebar
  --step=pour_chute --shot=CHUTE --hold`; a truck waiting to be backed in is
  `--stage=staked --step=back_dump --shot=STREET` (add `--hold --wait=1.2` for
  it backing). `--cursor=x,z` places a drag's finger (the plate works on the
  base, so its cursor is dropped to `BASE_TOP`). `--beacon=K` pins every beacon;
  `--eye/--look` try other offsets for a shot. `--seed=N` is a visit (none is
  the legacy lot); `--car=Pickup [--paint=K]`, `--house=K`, `--cracks=B` pin one
  field of the look. `--done=N --places=3,1` poses WHICH places of a row are
  done. The harness takes no input and never saves.
  `--settings` puts the settings cog in the picture (a shot HIDES it unless it
  is asked for), `--settings=open` opens the panel and `--settings=gate` puts
  the grown-up's sum over it. `--safe=iphone` or `--safe=ipad` stands a real
  device's hardware in front of the screen, so a windowed frame shows the
  phone's layout and not the desktop's - take those at `--resolution 1565x720`
  and `1280x960` respectively.
  The TITLE takes its own two: `--scene=res://scenes/main.tscn` with `--seed=N`
  (which visit stands behind the row) and `--last` (show it as a finished drive
  with the car on it). `--stage`, `--step` and `--shot` mean nothing there. A
  frame of the row with a job SAVED behind it needs a scratch `SceneTree`
  script that writes the save first (`shot.gd` switches saving off), the way
  session 6 took its resumed frames.

## Things that bit these sessions (do not rediscover them)

- **The driveway builds in its own `_ready`, before the level's.** Anything that
  must reach its build (the crack seed) is set in `SiteMain._enter_tree`.
- **A free RNG seed is not a safe look.** Twelve of forty crack bases left a
  slab short of weeds; two more put a tuft on a LATER slab under the first
  slab's gold. Vet a list, and check every slab against every lit ring.
- **An imported material is shared and cached across NEXT**: a recolour is a
  duplicate in the surface override, matched by name prefix.
- **`beat_done` is the bar's signal, not the job's place**: it fires mid-hold and
  never for weight-0 rows. The save listens to `place_changed`.
- **A harness must not resume the developer's own save**: `shot_args` switches
  it off unless `SaveGame.path_override` names a scratch file.
- **A backdrop is nobody's game.** `SiteMain.dress_only` must be set BEFORE
  `add_child` (`_enter_tree` runs there, and the driveway builds in its own
  `_ready`), and it makes `saves_on` false; without that a second `SiteMain`
  resumes the child's job into the picture behind a menu and writes over it.
- **A `Camera3D` declared in a scene takes the frame** from one added at
  runtime, whatever `current` says. `main.tscn` ships none.
- **Only `visible = false` stops a `SubViewport` rendering** (`PropIcon`): a
  disc hidden by alpha or moved off screen keeps drawing its private 3D world.
- **`SiteMain._world_box(node)` merges the node's CHILDREN**: a bare
  MeshInstance3D (the garage's boxes) comes back as an empty AABB at z 0.
- **Look at the look under the payoff's evening light**: a pale sage went
  yellow in it. A resumed row opens on its own shot wherever a press during an
  eye swoop would move work (drags) or the subject is off the wide (back-ins).

- **A test that plays better than any child can will never find a phase a child
  cannot finish.** The smoke walked a flawless four-lane boustrophedon over every
  bay, so it passed the compaction the user could not get past. When a rule is a
  COVERAGE rule, ask what a still finger, or one lazy lane, actually reaches.
- **One helper, or the evidence flatters the build.** `_pose_tool` stood the
  sledge wound up for the screenshots while the verb flew it in after the tap:
  the posed picture was right and play was wrong for four sessions, and every
  critic round judged the pose. A tool that a pose helper AND a verb both
  position must be positioned by ONE function that both call.
- **Deleting geometry a check reads makes the check VACUOUS, not red.** Removing
  the hose's jet segments left `jet_points()` returning one point, so
  `_screen_crossings` iterated an empty range and the check went on passing. When
  a thing a test measures is deleted, re-arm the test in the same edit.
- **`get_tree().paused` stops `_process`, NOT a coroutine.** `process_frame` is
  emitted every frame whether or not the tree is paused, so every
  `while ...: await process_frame` verb ran straight through the settings panel
  - the pour went on pouring behind it. Deltas come from `SiteVerbs._dt`, which
  is 0.0 while paused. (`create_timer(..., false)` DOES wait out a pause, which
  is why the gaps between beats never had this bug.)
- **A parent at `MOUSE_FILTER_IGNORE` does not stop its CHILDREN being picked**,
  and Godot picks on `is_visible_in_tree()`, never on modulate - so a panel
  fading out goes on answering fingers unless every pickable child is flipped
  too.
- **`ProjectSettings.get_setting` does not apply feature tags.** The engine reads
  `get_setting_with_override`. The difference was a privacy claim: the base
  default for file logging is false and the `.pc` default is true, so a check
  read green while `user://logs/` filled with a timestamped file per launch.
- **A real-input probe's second tap must use a real second finger.** Only finger
  0 is mirrored as the emulated mouse, and a Button that took a press keeps the
  pointer until it is released ANYWHERE - so a second tap pushed on index 0
  releases whatever the first one was holding, and a test written that way lets
  go of the thing it is supposed to be proving somebody else lets go of.
- **Watch a regression test FAIL before trusting it green.** The check written
  for the held-disc bug passed against the bug on its first run, for exactly the
  reason above. A test that has never been seen red proves nothing.
- **The `HUD` is a sibling only in the JOB.** On the title row the panel's parent
  is `Title` and the HUD lives inside the lot it instances, so a
  `get_node_or_null("HUD")` that RETURNS on null makes everything after it dead
  code on that screen.
- **A hidden `CanvasLayer` does not stop a raw `_input`.** `ToyHud._input` ran
  under a backdrop nobody could see and swallowed presses meant for the menu on
  top of it. Hiding a HUD means `show_pads([])`, `set_pads_enabled(false)` and
  `set_process_input(false)`.
- **The engine eats `--resolution` before a script sees it**, so a probe that
  wants a window shape must stamp `get_window().size` ONLY when
  `DisplayServer.get_name() == "headless"` - otherwise every windowed run
  measures 1280x720 and three device shapes look identical.
- **Input is delivered LAST CHILD FIRST.** The settings cog only takes its own
  tap because `SettingsMenu` is the last child of both scenes.
- **A probe that runs through the settings panel needs
  `process_mode = PROCESS_MODE_ALWAYS`**, or it stops with the tree it froze.
- **Process-global switches must be put back.** `Settings.motion_override`,
  `SafeArea.probe_active/probe_insets`, `SaveGame.enabled/path_override` and
  `Engine`'s `shot_args` all outlive the scene that set them; a probe that
  leaves one set makes the NEXT thing in that process lie.
- **A reduce-motion guard must not return early from `_process`.** Zero the
  trauma and FALL THROUGH to the branch that restores the basis, or the camera
  keeps the last tilt it was given forever.
- **Git Bash heredocs eat `\` + newline** even when quoted, and long ones die
  ("unexpected EOF"). Write a Python script to the scratchpad with the Write
  tool and run it; for GDScript continuations build them in the script.
- **A Vector2 is 32-bit.** `bay_range(b).x` is a hair off `Z_APRON`, so a bare
  `floor` on an exact row boundary lands a row out (the plate started a cell
  back); and time samples stored in a Vector2 a few hundred seconds into the
  smoke are only good to tens of microseconds - never match them exactly.
- **A HOLD row's carry rule is by target string**: two HOLD rows with the same
  `target` carry a still-held finger into the next. The back-in rows use
  `Back:` so a finger at the stop does not start the tip.
- **Never re-hang boards by beat number.** `form_set`'s first beat used to set
  every board to "waiting", which in a second `form_set` row lifts the boards
  already in. Which places are live is state (`form_live`, `stake_live`).
- **A screen point "on the lawn" can be on a truck** from a low eye: the
  truck's box projects over it. Assert the point is off the thing first.
- **A shake applied every frame never beats the decay**; a rattle is a
  `shake_floor`, reset on every path out.
- **The cones' base is 36 cm**; the crossing between the kerb trench and the
  road is 28 cm. Measure a prop's box before placing it on a strip.
- Older traps (still true): wall-clock rules want `create_timer`, not frame
  counts; a lambda captures locals BY VALUE (one-element Array); untyped
  autoload locals need a type; a hung Godot is killed by PID only; Godot
  RENAMES a duplicate child name; emission without glow clips; a check that
  recomputes the code's constants, or accepts "A or gone", proves nothing.
- Keep a multi-agent verification pass under about thirty agents (the
  session limit killed a ninety-two-agent one).

## The pillars, in one breath

No words on screen (YAY! is the kept exception, decision 2); nothing to buy or
earn; a tap must land on or near the thing the arrow points at (reach 0.22 of
the short side, and never more than about half a metre of world); holding is
the work; show the thing; an honest sequence a real crew would follow; a tap is
answered by the thing under it; nothing fades - things are carried off at a
cut. The decided list is `docs/CRITIC.md`. Read the last section of
`docs/critic_log.md` before touching anything.
