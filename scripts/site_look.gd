class_name SiteLook
extends RefCounted
## What a visit to the lot LOOKS like, drawn from one number (the improvement
## plan's 6.1): the homeowner's car and its paint and voice, the house's and the
## garage's walls, and which old cracks, stains and weeds the drive has. The job
## never changes - the order, the panel count, the spots, the lot - only the
## thing the child does it for. Car Garage's rule: the job is the same, the car
## is different every time.
##
## A pure table, so a test can read every look without building a site.
##
## Seed 0 is TODAY'S lot to the number: the red hatchback in the GLB's own paint,
## the house untouched, the cream garage and crack base 917. Every harness that
## names no seed gets it, so every picture taken before the plan's sixth session
## is still reproducible. A real launch draws a fresh seed (`draw_fresh`); NEXT
## draws one that differs from the visit it follows in car, house and cracks.

const LEGACY_SEED := 0
## Seeds a launch draws are small on purpose: the number goes into the save
## (6.2), and a ten-digit one reads like a clock to anyone auditing that file.
## It never comes from the clock.
const SEED_MAX := 9999

## The homeowners' cars: the plan's six, all from Car Garage's own
## `tools/make_vehicles.py` (Equip_* materials, no textures - not Synty). A row
## with paints is recoloured on its `Equip_Paint` surfaces; an empty list is a
## livery with nothing to recolour (the police car, the taxi, the ice-cream van).
## Paints are Car Garage's rows (`data/vehicles.json`), sRGB, less the Van's
## cream: cream in front of a cream garage is the one thing the payoff must not
## be. Every car here is measured in by the smoke: it parks between the garage
## door and the kerb (the Pickup, 5.45 m, is the longest). A livery's `body` is
## the colour most of it is (its GLB's own `Equip_White` / `Equip_Yellow`), so
## the police car and the ice-cream van - white - are held to the same rule the
## Van's cream was dropped for (`stands_out`).
const HOME_CARS := [
	{"name": "Hatchback", "voice": "voice_hatchback",
		"paints": [Color(0.86, 0.16, 0.12), Color(0.09, 0.60, 0.58), Color(0.55, 0.78, 0.18)]},
	{"name": "Pickup", "voice": "voice_pickup",
		"paints": [Color(0.16, 0.36, 0.74), Color(0.15, 0.52, 0.26), Color(0.95, 0.50, 0.10)]},
	{"name": "Van", "voice": "voice_van",
		"paints": [Color(0.46, 0.28, 0.68), Color(0.10, 0.58, 0.60)]},
	{"name": "PoliceCar", "voice": "voice_policecar", "paints": [], "body": Color(0.93, 0.93, 0.90)},
	{"name": "Taxi", "voice": "voice_taxi", "paints": [], "body": Color(0.98, 0.78, 0.12)},
	{"name": "IceCreamVan", "voice": "voice_icecreamvan", "paints": [], "body": Color(0.93, 0.93, 0.90)},
]

## The house's wall paint (its `Equip_Trim`: walls, gables, siding and window
## trims; the white corner boards and sills stay) and the garage's walls, as
## one property. Low chroma, near the legacy value: no pink (the stake caps are
## the one pink on the lot, CRITIC.md), no tool orange, no ring gold. Swatch 0
## is the legacy pair - no override on the house at all. All three leaning
## COOL, because the payoff is lit by a warm evening sun: a first sage (0.80,
## 0.86, 0.74) went yellow in it and put the yellow taxi on a yellow house, and
## a warm grey could not be told from the legacy cream at any hour. The slate is
## a value step darker, so it reads as a different house under any light.
const HOUSE_SWATCHES := [
	[Color(0, 0, 0, 0), Color(0.88, 0.86, 0.80)],
	[Color(0.72, 0.84, 0.74), Color(0.65, 0.77, 0.67)],
	[Color(0.72, 0.86, 0.88), Color(0.64, 0.78, 0.80)],
	[Color(0.66, 0.70, 0.76), Color(0.58, 0.62, 0.68)],
]

## Where the old drive's crack generator starts (`Driveway.crack_base`): a
## VETTED list, never a free number. A free base can leave a slab with fewer
## than three weeds, or every weed on the first slab under the opening wide's
## rings; the smoke builds a drive from every entry and holds each to that.
## 917 is the legacy drive. Chosen from forty candidates (917 + 131k, 917 among
## them): twelve left a slab with fewer than three weeds; eleven of the rest were
## re-checked against every slab's tufts, and two of those put a tuft on a later
## slab under the first slab's gold; 917 and seven of the other nine are kept.
##
## Growing or shrinking any of these tables re-draws that field for every seed,
## a saved one too: a job saved before such an update resumes on the new look
## (its places are unaffected).
const CRACK_BASES := [917, 1441, 1703, 1965, 2096, 2358, 3275, 4978]


## The look for a seed. Every field has its OWN generator (`"<seed>:car"`,
## `":paint"`, ...), so a field added later never moves another one.
static func for_seed(seed: int) -> Dictionary:
	if seed == LEGACY_SEED:
		return {"seed": LEGACY_SEED, "car": "Hatchback", "paint": Color(0, 0, 0, 0),
			"voice": "voice_hatchback", "house_swatch": 0, "house": HOUSE_SWATCHES[0][0],
			"garage_wall": HOUSE_SWATCHES[0][1], "crack_base": CRACK_BASES[0]}
	var row: Dictionary = HOME_CARS[_pick(seed, "car", HOME_CARS.size())]
	var paints: Array = row["paints"]
	var paint := Color(0, 0, 0, 0)
	if not paints.is_empty():
		paint = paints[_pick(seed, "paint", paints.size())]
	var sw := _pick(seed, "house", HOUSE_SWATCHES.size())
	# The car must stand out from the garage it parks in front of: a pairing that
	# does not is drawn again from the swatches that do, off its own generator.
	var body: Color = paint if paint.a > 0.0 else Color(row.get("body", Color(0, 0, 0, 0)))
	if body.a > 0.0 and not stands_out(body, HOUSE_SWATCHES[sw][1]):
		var ok: Array[int] = []
		for i in range(HOUSE_SWATCHES.size()):
			if stands_out(body, HOUSE_SWATCHES[i][1]):
				ok.append(i)
		if not ok.is_empty():
			sw = ok[_pick(seed, "house2", ok.size())]
	return {"seed": seed, "car": String(row["name"]), "paint": paint, "voice": String(row["voice"]),
		"house_swatch": sw, "house": HOUSE_SWATCHES[sw][0], "garage_wall": HOUSE_SWATCHES[sw][1],
		"crack_base": CRACK_BASES[_pick(seed, "cracks", CRACK_BASES.size())]}


## A fresh seed for a visit: a different car, house and cracks from `last` (the
## look of the visit before, or {} on a launch). The DRAWN number is what is
## kept - `randomize()` seeds the generator off the clock, and the generator's
## own seed must never reach the save.
static func draw_fresh(last: Dictionary) -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := rng.randi_range(1, SEED_MAX)
	for _i in range(400):
		if last.is_empty() or differs(for_seed(s), last):
			return s
		s = rng.randi_range(1, SEED_MAX)
	return s


## Is `a` a different visit from `b` - car, house and cracks all changed?
static func differs(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("car", "")) != String(b.get("car", "")) \
		and int(a.get("house_swatch", -1)) != int(b.get("house_swatch", -1)) \
		and int(a.get("crack_base", -1)) != int(b.get("crack_base", -1))


## Does a car's body stand out from a garage wall behind it? A luma step (the
## project's ~0.12), or a saturated car against a pale, low-chroma wall. Cream
## (0.92, 0.87, 0.72) or white on the cream garage is neither.
static func stands_out(body: Color, wall: Color) -> bool:
	return absf(_luma(body) - _luma(wall)) >= 0.12 or (body.s >= 0.4 and wall.s <= 0.25)


static func _luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


## The row of `HOME_CARS` named `car_name`, or {}.
static func car_row(car_name: String) -> Dictionary:
	for row: Dictionary in HOME_CARS:
		if String(row["name"]) == car_name:
			return row
	return {}


## A seed argument as an int: a `--seed=7` arrives as the string "7", a save's
## as a JSON float. -1 for anything that is not a whole number in range - never
## a silent 0, which is the legacy lot.
static func parse_seed(v: Variant) -> int:
	if v is int or v is float:
		var f := float(v)
		if f == floor(f) and f >= 0.0 and f <= float(SEED_MAX):
			return int(f)
		return -1
	var t := str(v)
	if t.is_valid_int() and int(t) >= 0 and int(t) <= SEED_MAX:
		return int(t)
	return -1


static func _pick(seed: int, field: String, n: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s" % [seed, field])
	return rng.randi_range(0, maxi(n - 1, 0))
