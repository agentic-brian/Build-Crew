class_name JobIcons
extends RefCounted
## The picture on a job's seat in the title row (the improvement plan's 6.3),
## and the disc it stands on. There are no words on this screen, so the picture
## IS the name of the job: the driveway's is the skid steer wearing its push
## blade - `MachineIcons.spec("skid")` itself, not a copy, so the machine on the
## title is the machine that answers the call button, and a pose tuned for one
## moves both.
##
## Which jobs the row seats is `data/jobs/jobs.json` (a bare array of the stems
## in `data/jobs/`, Car Garage's own shape). It holds no name, no price, no
## star, no difficulty and no "done" flag: there is nothing to buy, earn or
## unlock in this family, and a flag written back into that file would be the
## first brick of an economy.

const JOBS_FILE := "res://data/jobs/jobs.json"
const JOBS_DIR := "res://data/jobs/"
const PROPS := "res://assets/models/props/"

## The disc each job's seat stands on. Blue because everything else is spoken
## for: cream is the call button's, green is NEXT's and the house's, yellow is
## the machine standing in the disc, orange is the "new drive" disc below.
const COLORS := {"new_driveway": Brand.BLUE}
## Whose picture the seat carries, by `MachineIcons` key.
const HEROES := {"new_driveway": "skid"}

## The "start a new drive" disc: the jackhammer, the job's own first beat.
## Breaking the old drive up is what the press does and what the picture says.
const FRESH_SPEC := {"model": PROPS + "Jackhammer.glb", "yaw": 0.55, "pitch": 0.22,
	"roll": -0.35, "fill": 0.82}


## The jobs the row seats, in the file's own order. A key with no
## `data/jobs/<key>.tres` behind it is dropped rather than seated: a typo must
## not ship a dead button.
static func keys() -> PackedStringArray:
	var out := PackedStringArray()
	var text := ""
	if ResourceLoader.exists(JOBS_FILE) or FileAccess.file_exists(JOBS_FILE):
		var f := FileAccess.open(JOBS_FILE, FileAccess.READ)
		if f != null:
			text = f.get_as_text()
			f.close()
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	var want: Array = parsed if parsed is Array else ["new_driveway"]
	for k in want:
		var key := String(k)
		if ResourceLoader.exists(JOBS_DIR + key + ".tres"):
			out.append(key)
		else:
			push_warning("JobIcons: no job at %s%s.tres" % [JOBS_DIR, key])
	if out.is_empty():
		out.append("new_driveway")
	return out


static func hero(job: String) -> String:
	return String(HEROES.get(job, ""))


static func disc(job: String) -> Color:
	return COLORS.get(job, Brand.BLUE)


## Stands the job's machine up inside its seat. Returns the icon, or null when
## the model could not be drawn - the caller keeps a drawn glyph then, so a
## seat is never a hole.
static func dress(b: Button, job: String, s: float) -> PropIcon:
	return MachineIcons.dress(b, hero(job), s, disc(job))


## The same for the "new drive" disc, which belongs to no job.
static func dress_fresh(b: Button, s: float) -> PropIcon:
	Brand.dress_button(b, Brand.ORANGE, int(s * 0.5))
	var icon := PropIcon.new()
	icon.name = "Prop_fresh"
	icon.spec = FRESH_SPEC
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	if icon.build():
		return icon
	b.remove_child(icon)
	icon.queue_free()
	return null
