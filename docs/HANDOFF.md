# Build Crew - hand-off (written 2026-09-15, end of session 4)

For whichever session picks this up next. Everything below is true as of the
date above; the code and `docs/critic_log.md` outrank this file if they
disagree.

## Where things stand

- `docs/IMPROVEMENT_PLAN.md` is the work list. Its section 12 gives the
  session order. Sessions 1-4 are BUILT and marked **DONE** in the plan:
  Tier 0; Tier 1 with 2.1, 2.4, 2.5; Tier 3; Tier 4 (4.1-4.7; 4.8, the day
  passing, is optional and not taken). Each is a dated section at the end of
  `docs/critic_log.md`, the last one being "The improvement plan's fourth
  session: Tier 4 - show the thing" and its verification pass (eight findings
  from a twenty-agent adversarial pass, all fixed, plus a list of what was NOT
  taken and why - each older than the session, worth their own passes).
- Green on 2026-09-15: `SITE_SMOKE PASS 332/332`, `MACHINE_PROBE PASS 16/16`.
- The contract notes for the four sessions are `docs/DESIGN.md` sections 7,
  7a, 7b, 7c; `docs/CRITIC.md`'s decided list has a "since the plan's fourth
  session" bullet. `docs/sfx.md` has the sixteen clips; `click` (the tie wire)
  is borrowed from the garage.
- Frames: `renders/critic/tier0/`, `session2/`, `session3/`, `session4/`. The
  session-4 section of the log records every frame's args (a table).
- The groover's GLB was re-exported (`tools/make_site_props.py --only Jointer`,
  Blender 4.5 at `C:/Program Files/Blender Foundation/Blender 4.5/blender.exe`).
- Nothing is committed: `build-crew/` is not a git repository.
- The plan is mirrored as a claude.ai artifact:
  https://claude.ai/artifact/9KMi86cKwKDvk31a56xSp7. From a new conversation
  you must `read` that URL with the Artifact tool before you can publish to it
  with `url`. It was republished at the end of session 4.

## What is next

1. **A playtest.** The user has not reported playing sessions 2, 3 or 4. The
   feel changes worth their eyes: the rebar phase is about twice as long (each
   landing is a fall, two bounces and a run of ties); the beacons; the hose on
   an iPad; the weeds and the settled first slab.
2. **Decisions still the user's** (plan section 11): 2 the YAY! banner (word
   or picture), 4 the arrival's last leg as a hold, 5 the kerb board after
   the base, 6 a plate compactor phase, 7 the name (Build Crew or Build
   Site). Then Tier 5 as chosen, then Tier 6 (seed 6.1 first).
3. **Small passes found in session 4 and not taken** (the log's "Not taken"):
   the tool fly-in snap shared by the sledge, the jackhammer and the screed; a
   kept tap's ring coming back through the beat it plays (every ring phase);
   held tools waiting on the lawn until the first press; the kerb board's
   stakes standing in the footway crossing's concrete.

## The session ritual (every session ends this way)

1. Class cache, then probe, then the smoke - all green.
2. Frames re-taken into a new dated `renders/critic/<session>/` folder and
   LOOKED AT (Read the PNG).
3. A section appended to `docs/critic_log.md` in its voice: what changed, the
   measurements, what was NOT taken and why, then the green line.
4. The tier marked **DONE** in `docs/IMPROVEMENT_PLAN.md` with a dated note.
5. `docs/DESIGN.md` gets a numbered section for what the session adds to the
   contract; `docs/sfx.md` a row per new clip.
6. Memory updated (`project_build_crew_improvement_plan.md` and its line in
   `MEMORY.md`), the artifact republished at the same URL.
7. Session 3 also ran an adversarial verification pass over its own work (one
   agent per item, told to refute) and fixed what it found before calling the
   session done. Keep that: it found twelve real things.

## Commands

Godot is not on PATH. The binary:

```
C:/Users/faulk/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
```

Run everything from `build-crew/` (`--path .`).

- Class cache (after any script edit; it prints parse errors):
  `--headless --path . --editor --quit`
- Probe (about a minute): `--headless --path . res://scenes/dev/machine_probe.tscn`
- Smoke (eight to nine minutes; run in the background to a log file and
  grep it for `SITE_SMOKE` and `FAIL`):
  `--headless --path . res://scenes/dev/site_smoke.tscn`
- A thirty-second stand-in for the pour beat: `res://scenes/dev/pour_probe.tscn`
  with the environment variable `BC_DEBUG=1`.
- A parse check of one script (the class cache misses non-global ones):
  `--headless --path . --check-only --script res://scripts/<file>.gd`.
- A throwaway probe needs no file under `res://`: a `extends SceneTree` script in
  the scratchpad, run with `--headless --path . -s <absolute path>`, can load
  `res://scenes/site.tscn` and read anything (session 4 mapped the rings' gold
  on the wide this way).
- Frames (windowed - never while a headless run is going):
  `--path . --resolution 1280x720 res://scenes/dev/shot.tscn -- --scene=res://scenes/site.tscn --out=<absolute>.png --frames=70 --stage=<stage> --shot=<SHOT> [--step=N] [--hold]`
  Stages are the keys of `SiteMain.STAGE_STEP` (old, broken, cleared, formed,
  staked, based, rebar, banded, poured, sprayed, screeded, jointed, done,
  parked); shots are the constants in `scripts/camera_rig.gd` (WIDE, PANEL,
  MACHINE, FORM, TIPPER, STAKE, BARS, PULL, BROOM, JOINT, CHUTE, SURFACE,
  HAND, STREET, PAYOFF). The pour is `--stage=rebar --step=11 --shot=CHUTE
  --hold` ("poured" is the water step). `done` poses the cure with the cones
  across the mouth of the drive; `parked` is the payoff. `--beacon=K` pins every
  beacon (0..1) for a lit/dark pair; `--eye/--look` also work on an anchor with
  its own offsets (the long bars, the kerb stake pair). The harness takes no
  input now, so a stray click cannot spoil a frame.
- Importing a new clip: put `assets/sfx/<group>_<n>.mp3` in place, then
  `--headless --path . --import`. The ElevenLabs recipe is in memory
  (`reference_elevenlabs_creative_mcp.md`); the flow used was
  "Build Crew site sounds 3".

## Things that bit this session (do not rediscover them)

- **The smoke and wall clocks:** never wait a frame count for a rule that is
  in seconds; use `get_tree().create_timer(s)`. A lambda captures locals BY
  VALUE, so a `while flag` loop inside one never sees the callback's write -
  use a one-element Array.
- **Untyped autoloads:** a local inferred from `main.sfx.x` or `sfx.y` with
  `:=` fails to parse ("Cannot infer the type") because the autoload is a
  Variant. Type the local. The class cache only reports global classes, so
  the smoke's own parse errors show up when the smoke RUNS - check the log's
  first lines twenty seconds in, or a failed run hangs for nine minutes.
- A hung Godot is killed by PID only. A `Stop-Process` on a command-line
  match has killed the shell before.
- **Long Bash heredocs die** in this tool. For a big edit, Write a Python
  script to the scratchpad and run it.
- A check that accepts "still leaving OR gone" proves neither. Watch the
  frame a thing disappears and assert the state in that frame.
- The pour's idle mime only exists while a band cell is under half full
  (about the first four seconds of a parked pour); test it early.
- Another local Claude session was working in this folder on 2026-09-15
  ("Hide the skid steer bucket under the push blade": `scripts/machine.gd`,
  MachineIcons). Re-read a file before editing it.
- Multi-agent verification: keep a workflow under about thirty agents. A
  ninety-two-agent pass died on the session limit (the findings survived in
  its `journal.jsonl`).

- **Session 4's traps:** Godot RENAMES a second child with a taken name
  (`@Node3D@2`), so "the sibling named X" finds only the first - hold the node.
  A ground-distance rule cannot say what a billboard covers on a slanted
  picture: project it. A smoke check that recomputes the code's own constants
  proves nothing - read the drawn node. A windowed frame run takes real clicks
  unless input is disabled. A tube that leaves the picture cannot be seen to
  sway. Emission without glow or a tonemapper clips: a yellow lens glowing
  yellow goes white, so it glows a deep amber.

## The pillars, in one breath

No words on screen; nothing to buy or earn; a tap must land on or near the
thing the arrow points at (reach 0.22 of the short side, and never more than
about half a metre of world); holding is the work; show the thing; an honest
sequence a real crew would follow. The decided list is `docs/CRITIC.md`.
Read the last section of `docs/critic_log.md` before touching anything.
