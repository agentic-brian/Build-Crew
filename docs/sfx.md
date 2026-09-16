# The site's sounds

Seventeen clips, one for each noise a driveway job really makes, in
`assets/sfx/` (twelve on 2026-09-12; the rebar and the come-along on
2026-09-14, flow "Build Crew site sounds 2", two takes each; the plate
compactor on 2026-09-15, flow "Build Crew site sounds 4"). Made 2026-09-12 with ElevenLabs (`eleven_text_to_sound_v2`,
flow "Build Crew site sounds") because the user played the level and said
**"correct all the sounds"**: every tool was borrowing a clip from Car
Garage's library, so the breaker was an impact wrench, the pour was a drain,
the screed and the broom were the same scrape, and three diesel machines
idled like a hatchback.

`Sfx` finds its groups by FILE NAME - `breaker_1.mp3` is the group `breaker`,
and a second take would be `breaker_2.mp3` and get picked at random - so
adding a clip is dropping a file in the folder. The names below are the
constants at the top of `site_verbs.gd`.

| group | seconds | loop | where it plays | prompt it was made from |
|---|---|---|---|---|
| `breaker` | 3 | · | `jack_spot`, running while the bite runs | a pneumatic jackhammer breaking a concrete driveway slab: fast dry percussive hammering, chisel chattering on concrete, compressed air rattle, grit and dust |
| `crumble` | 2 | | the slab letting go on its third bite (`SOUND_BREAK`) | a thick concrete slab cracking and breaking apart: a deep splitting crack, then heavy broken concrete chunks tumbling and settling onto dirt |
| `rubblepush` | 4 | ✓ | `push_rubble`, while the bucket is moving | a steel loader bucket scraping broken concrete rubble along dirt: heavy chunks grinding and tumbling over one another |
| `sledgehit` | 1 | | the moment a stake is struck | one heavy sledgehammer blow driving a wooden form stake into gravel: a single hard woody thwack with a steel ring, gravel crunching |
| `dieselidle` | 4 | ✓ | every machine arriving, working and leaving | a heavy construction diesel truck engine idling steadily at low revs |
| `hydraulic` | 2 | | the dump bed going up, the chute coming out | a hydraulic ram lifting a heavy dump truck bed: a rising pump whine under load, steel creaking |
| `gravelpour` | 4 | ✓ | `tip_gravel`, while the stone is running | crushed limestone gravel pouring out of a dump truck tailgate: a continuous heavy rush of small stones sliding over steel |
| `mixerdrum` | 4 | ✓ | the whole pour, under everything else | a concrete mixer truck drum slowly rotating: a deep hollow steel rumble with wet aggregate tumbling inside it |
| `wetpour` | 4 | ✓ | `pour_chute`, while concrete is leaving the spout | wet concrete sliding down a steel chute and slopping onto the ground: a thick heavy wet slurry, dull wet splats |
| `hosespray` | 4 | ✓ | `spray_water`, while the finger is on the slab | a garden hose nozzle spraying a fan of water onto a concrete slab: a steady hissing jet, water pattering on hard wet stone |
| `screeddrag` | 4 | ✓ | `screed_pull` | a long wooden screed board dragged and sawed across wet concrete: a gritty wet scraping rasp |
| `broomdrag` | 4 | ✓ | `broom_finish` | a stiff bristle broom dragged across fresh wet concrete: soft wet bristle swish and rasp |
| `rebardrop` | 1.5 | | a bar landing on its chairs (`rebar_lay`, 2026-09-14) | one long steel rebar bar dropped onto plastic rebar chairs on a crushed gravel base: a single bright metallic clang with a short ring, then a small settle of gravel |
| `rakepull` | 4 | ✓ | `rake_pull`, while the finger is on the slab (2026-09-14) | a steel concrete rake pulling wet concrete across a driveway form: a heavy wet gritty drag, thick slurry sloshing and settling, aggregate grinding softly under the blade, steady rhythm of strokes |
| `done` | 0.8 | | the moment a phase the bar counts is finished (`SiteMain._on_step_done`, 2026-09-15; not the machine beats, and not the last one, whose done is the tada) | a soft warm two-note wooden marimba tap, rising, short, gentle, a small friendly "done" chime for a children's game, no reverb tail |
| `reversebeep` | 4 | ✓ | the tipper's and the mixer's REVERSE leg into the site - only while the truck is moving under the child's hold, off as it comes to rest after a lift (`SiteVerbs._back_in`, the improvement plan's 1.8; the skid steer drives in forwards and has none) | a heavy truck reversing alarm: steady evenly spaced electronic beeps, beep beep beep, outdoors, no engine, no voices |
| `platerattle` | 4 | ✓ | `compact_base`, only while the plate is really packing under a finger on it (the improvement plan's 5.1, 2026-09-15). One take of four, picked by measurement: the steadiest envelope (cv 0.35), a 20 Hz rattle and half its energy at 1.2-4 kHz, so it carries on a tablet speaker; the model's own loop, seam checked | a vibrating plate compactor running on crushed gravel: a fast heavy thudding rattle of a steel plate pounding loose stones, small stones buzzing and chattering, a low small petrol engine drone underneath, steady and continuous, outdoors, dry, no voices |

The loops were generated with the model's own `loop` parameter on, so they
join seamlessly; the three one-shots (`crumble`, `hydraulic`, `sledgehit`)
were not.

**The one that changed shape as well as sound is the breaker.** It used to be
`play_group` on every blow of a 13-per-second hammer - thirteen clips a second
piling up on each other - and it is a loop that runs while the bite runs now,
with the picture doing the blows (the kick, the puff of dust, the bit going
in). A per-blow one-shot is right for a sledge, which hits once.

Still borrowed from the garage library, because they are not site noises and
sound right as they are: `whoosh` and `clunk` (a form board dropping in),
`thunk` (a bed coming back down, and the screed board coming up off the kerb form), `drive` (a vehicle pulling up), `hiss` (a truck's air brakes as it stops; the skid steer keeps its `clunk`, 2026-09-15), `voice_hatchback` (the homeowner's car saying thank-you twice when it parks, Car Garage's own voice for it, 2026-09-15) and, since the plan's sixth session, the other homeowners' cars' own voices - `voice_pickup` -6.5 dB, `voice_van` -6.5, `voice_policecar` -5, `voice_taxi` -5, `voice_icecreamvan` -1 (a 2.5 s jingle, quieter at the same peak), the hatchback staying at -4: each trimmed so the loudest 100 ms of its takes, averaged, is heard at the hatchback's level (measured off the decoded MP3s: hatchback -8.2 dB, pickup -5.8, van -5.9, police -7.4, taxi -7.0, ice-cream van -11.1), `horn` (a machine answering a tap on it while it arrives or leaves, 2026-09-15), `pop` (a miss - one quiet sound, never a buzzer, 2026-09-15), `click` (a rebar tie wire twisted tight at a crossing, popping on down a cross bar a step higher each tie, -6 dB, the improvement plan's 4.7, 2026-09-15), `chime`,
and `tada` (the celebration). `boing` is gone: it was the cartoon spring the
trucks made before every reverse leg, never the celebration's, and the
reversing beeper took its place (the improvement plan's 3.5); its two clips
were deleted from `assets/sfx/` in the session-3 verification pass.

## Making another one

```
creative_add_flow_node  node_type=sfx  model_id=eleven_text_to_sound_v2
    model_parameters={"duration_seconds": 4, "loop": true}
creative_run_flow_nodes generations_count=2
creative_get_flow_run_status  -> media[].url   (signed, two hours)
```

Then save it as `<group>_<n>.mp3` in `assets/sfx/` and run
`godot --headless --path . --import` so Godot writes its `.import` file.
Twelve clips at two takes each cost 800 credits (16 cents).
