class_name MachineIcons
extends RefCounted
## The call button's pictures: the fleet's own machines, low-poly, standing in
## the button the way Car Garage's key stands in its start button (the fourth
## playtest: "make them low poly like the key in Garage Crew"). Each is a
## `PropIcon` spec, posed the way the game poses the machine when it works: the
## skid steer wearing its push blade, the tipper with its bed up, the mixer with
## its chute out.

const MACHINES := "res://assets/models/machines/"
const PROPS := "res://assets/models/props/"
const KEYS: Array[String] = ["skid", "dump", "mixer"]

const SPECS := {
	"skid": {"model": MACHINES + "SkidSteer.glb",
		"attach": [{"under": "Bucket", "model": PROPS + "PushBlade.glb"}],
		"pose": {"LiftArm": Vector3(6.6, 0.0, 0.0), "Bucket": Vector3(-6.0, 0.0, 0.0)},
		"yaw": -0.8, "pitch": 0.25, "fill": 0.86},
	"dump": {"model": MACHINES + "DumpTruck.glb",
		"pose": {"Bed": Vector3(-46.0, 0.0, 0.0), "Tailgate": Vector3(-62.0, 0.0, 0.0)},
		"yaw": 2.35, "pitch": 0.28, "fill": 0.9},
	"mixer": {"model": MACHINES + "ConcreteTruck.glb",
		"pose": {"ChuteFold": Vector3(-20.0, 0.0, 0.0)},
		# The mixer is white on a cream disc: its body a step darker for the icon.
		"paint": {"Equip_White": Color(0.72, 0.74, 0.78)},
		"yaw": 2.35, "pitch": 0.28, "fill": 0.9},
}


static func spec(key: String) -> Dictionary:
	return SPECS.get(key, {})


## Which picture a call verb wants.
static func kind_for(verb: String) -> String:
	return {"call_skid": "skid", "call_mixer": "mixer"}.get(verb, "dump")


## Stands the model up inside `b`. Returns the icon, or null when the model
## could not be drawn - the caller keeps its drawn glyph then, so a button is
## never a hole.
static func dress(b: Button, key: String, s: float, color: Color) -> PropIcon:
	Brand.dress_button(b, color, int(s * 0.5))
	var icon := PropIcon.new()
	icon.name = "Prop_" + key
	icon.spec = spec(key)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	if icon.build():
		return icon
	b.remove_child(icon)
	icon.queue_free()
	return null
