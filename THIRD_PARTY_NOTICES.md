# Third-party notices — Build Crew

Everything in this game that somebody else made, what its licence asks of us,
and where the text of that licence lives. Written 2026-09-16 (the improvement
plan's 6.4, part 5); every claim below was checked against the files, not
against a sibling project's copy of this file.

These texts ship inside the app as files (`licenses/*.txt` and this file) and
are **never shown on screen**. Nothing in this game shows words to a child, so
there is no in-game credits screen — and there must not be one.

---

## The engine

**Godot Engine 4.7.2-stable**, MIT. <https://godotengine.org>

| what | where |
|---|---|
| Godot's own MIT text and its copyright line | `licenses/Godot-MIT.txt` |
| the 102 third-party components Godot itself carries, and their 19 licence texts | `licenses/Godot-thirdparty.txt` |

Both files are generated from the running engine, never hand-written:

```
godot --headless --path . -s tools/make_engine_licenses.gd
```

Re-run it whenever the engine version changes; the version is written into the
first line of each file, so a stale copy is visible at a glance.

MIT asks one thing: ship the copyright notice and the permission notice with
the binary. Shipping these two files satisfies it for Godot and for everything
Godot bundles.

## 3D models

**All 33 of them (17 + 8 + 8) are built by scripts in this family, and not one
carries a texture** (every glTF chunk parses with zero `images` and zero `textures`).
There is no third-party model content in this project at all:

- **17 from the fleet** — 3 in `assets/models/machines` and 14 in
  `assets/models/street` — `big-little-jobs-fleet`, this author's own low-poly
  pack, built by its `tools/*.py`. Its README states there is no upstream
  licence obligation: the geometry is generated, not sourced. Twelve are
  byte-identical to that pack's own files; ConcreteTruck, DumpTruck, SkidSteer,
  DetachedGarage and StarterHome are local rebuilds from the same builders —
  same provenance, different bytes.
- **8 built here** (`assets/models/props`) — `tools/make_site_props.py` and
  `tools/make_blade.py` build the Jackhammer, Sledge, ScreedBoard, Jointer,
  Broom, ComeAlong, PlateCompactor and PushBlade from primitives.
- **8 from Car Garage** (`assets/models/props/HoseNozzle.glb`, `Towel.glb`, and
  the six vehicles in `assets/models/vehicles`) — that project's own
  `make_parts.py` / `make_vehicles.py` builds, byte-identical to their sources
  there, carried over with their `Equip_*` materials and no images.

**There is no Synty content in this project, and that is why this repository is
public.** The rule that keeps it that way, from `docs/HANDOFF.md`: a Synty
source file must never be committed here. The siblings that do use Synty packs
are private repositories for exactly that reason, and their EULA does not permit
redistributing source assets.

## Typefaces

Both under the SIL Open Font Licence 1.1, both shipped as `.woff2` in
`assets/fonts/` with their licence texts beside them:

| face | where it is used | licence text |
|---|---|---|
| Fredoka Bold | the child's face: the "YAY!", the parental gate's title | `licenses/OFL-Fredoka.txt` |
| Nunito Sans | the adult's face: the settings panel's privacy link, the gate's prose | `licenses/OFL-NunitoSans.txt` |

The OFL's condition 2 is the one with teeth: the fonts may be bundled and sold
inside a program, but they may not be sold on their own. Neither of these
families declares a Reserved Font Name, so no renaming is required.

Where each binary came from, per file, so the next auditor can re-check it:

| file | md5 | source |
|---|---|---|
| `assets/fonts/NunitoSans.woff2` (31,076 B) | `e010923d59d4999d2be60cae63416f8d` | byte-identical to the latin subset the marketing site serves (`dist/assets/nunito-sans-latin-wght-normal-BWQ3gi2K.woff2`) |
| `assets/fonts/Fredoka-Bold.woff2` (15,900 B) | `f67eddbc391c526a6f7848efd539e51f` | the static 700 instance from `@fontsource/fredoka`, `files/fredoka-latin-700-normal.woff2` |

The Fredoka is **not** among the files the site serves: the site's web bundle
ships `@fontsource-variable/fredoka`'s variable face instead (a different
binary, `9591efe1…`). Same family, same licence, different cut — and an earlier
draft of this file claimed byte-identity for both fonts, which was true of one
and false of the other.

## Sound effects

141 mp3 files in 69 groups under `assets/sfx/`, generated with **ElevenLabs
Sound Effects v2** on a paid plan. Where each group's generation record lives,
split the way the models are above:

- **44 groups are recorded in `docs/sfx.md`** — the clips made for this game,
  with the flow that made each one and what it is for.
- **25 groups (54 files) came across from Car Garage's library** —
  `airflow`, `breath`, `clink`, `crank`, `drip`, `engine_rough`, `engine_start`,
  `glug`, `heave`, `key`, `latch`, `paintspray`, `purr`, `ratchet`, `reel`,
  `roar`, `roll`, `sander`, `snap`, `sparkle`, `sputter`, `squeal`,
  `tirebounce`, `valveclick` and `wiper`. Same model, flow "Car Fixer SFX";
  their record is in `car-fixer/docs/sfx.md`, and **that repository is
  private**, so this public one cannot produce their dates on its own.

Seven `voice_*` groups (ambulance, firetruck, garbagetruck, racecar, schoolbus,
sportscar, towtruck) were carried over and could never be selected —
`SiteLook`'s car table is closed at six vehicles — so the export pass deleted
them rather than ship fourteen files of audio no child can ever hear.

ElevenLabs grants commercial use of generated audio to accounts on a paid plan,
and that grant hangs on the subscription having been live on the generation
dates — so keep the evidence of the plan (invoices, the account's generation
history) with the project's records, not only in the app.

## Music

One track, `assets/music/site.ogg`, generated with **Suno** on a Pro
subscription.

Named honestly: this file is byte-identical to `tree-chop/assets/music/
forward.ogg` and to `car-fixer/assets/music/garage.ogg`
(md5 `8c1a2eb0b5edc5ffd051bc47686c4c86`) — it is Tree Crew's forwarder track,
carried across and renamed for this game.

Two caveats worth writing down, because neither is a copyright question:
commercial rights granted by a generator's terms are contractual, not a transfer
of copyright; and the risk that a generated output resembles existing music sits
with the account holder, not the generator.

## Shipping this file

`export_presets.cfg` carries these files into the bundle through its include
filter, on both presets:

```
include_filter="licenses/*.txt,THIRD_PARTY_NOTICES.md"
exclude_filter="renders/*,scenes/dev/*,scripts/tools/*,tools/*,docs/*"
```

They ship as files. They are not shown, read out, or linked from anywhere inside
the game. `export_probe` holds the preset to both lines.

## The icon and the splash

Neither is a drawing. The **app icon** is the skid steer wearing its push blade,
rendered from `assets/models/machines/SkidSteer.glb` and
`assets/models/props/PushBlade.glb` by `tools/make_appicon.gd` — the same
`MachineIcons` spec the title row seats — orthographic, on the family cream
inside an orange band, with no words on it. Fifteen sizes, all reduced from one
2048 px master.

The **splash** is the Big Little Jobs wordmark, built by `tools/make_splash.gd`
from `tools/brand/bl_jobs_logo_primary.png`, which lives behind a `.gdignore` so
it is never imported or exported. It is the one picture in this product that
carries words: DESIGN 7g's rule governs what the GAME draws, and this is the
mark of who made it, shown before the game starts.
