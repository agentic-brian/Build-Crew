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

**All 33 of them are built by scripts in this family, and not one carries a
texture** (every glTF chunk parses with zero `images` and zero `textures`).
There is no third-party model content in this project at all:

- **14 from the fleet** (`assets/models/machines`, `assets/models/street`) —
  `big-little-jobs-fleet`, this author's own low-poly pack, built by its
  `tools/*.py`. Its README states there is no upstream licence obligation: the
  geometry is generated, not sourced.
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
families declares a Reserved Font Name, so no renaming is required. The two
files are byte-identical to the ones the marketing site serves.

## Sound effects

155 mp3 files in 76 groups under `assets/sfx/`, generated with **ElevenLabs
Sound Effects v2** on a paid plan. `docs/sfx.md` records which flow made which
group and what each one is for.

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

When the iOS export preset lands (the plan's 6.4 part 4), its include filter
carries these files into the bundle:

```
include_filter="licenses/*.txt,THIRD_PARTY_NOTICES.md"
```

They ship as files. They are not shown, read out, or linked from anywhere inside
the game.
