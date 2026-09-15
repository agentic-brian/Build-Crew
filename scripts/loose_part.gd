class_name LoosePart
extends Node3D
## A part lying about the shop (DESIGN 11g): the new battery, bulb or filter
## standing on the parts cart before its job, or the worn one after. It is a
## GLB (or a stand-in) under a node the verbs can throw about: `arc_to` lobs
## it to a pose, `slide_to` moves it straight, and both say `move_done`.
##
## The same idea as `GarageMain.LooseTire`, cut down: a part has no roll, no
## wobble and no stages, it only goes from where it is to where it is wanted.

## Whatever move was running has finished.
signal move_done

## Which of the three this is (`Battery`, `Bulb`, `AirFilter`): the name of
## the GLB in `assets/models/props`, and the vehicle node it stands in for.
var kind: String = "Battery"
## The node the shop asks a step for (`Parts:NewBattery`).
var _model: Node3D
var _tween: Tween


## Loads `assets/models/props/<kind>.glb`, or a box the right size.
func setup(part_kind: String) -> void:
	kind = part_kind
	var path := "res://assets/models/props/%s.glb" % part_kind
	if ResourceLoader.exists(path):
		var packed := load(path) as PackedScene
		if packed != null:
			var inst := packed.instantiate() as Node3D
			if inst != null:
				inst.name = "Model"
				add_child(inst)
				_model = inst
				return
	_model = _placeholder(part_kind)
	add_child(_model)


func model() -> Node3D:
	return _model


## A little lob to a pose: eased, `height` metres over the straight line.
func arc_to(to: Transform3D, height: float, seconds: float) -> void:
	_kill()
	var from := global_transform
	_tween = create_tween()
	_tween.tween_method(func(k: float) -> void:
		var p := from.origin.lerp(to.origin, k)
		p.y += height * 4.0 * k * (1.0 - k)
		global_transform = Transform3D(from.basis.slerp(to.basis, k), p),
		0.0, 1.0, maxf(seconds, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(func() -> void:
		global_transform = to
		move_done.emit())


## Straight to a pose over `seconds`.
func slide_to(to: Transform3D, seconds: float) -> void:
	arc_to(to, 0.0, seconds)


## Everything this part draws, as one box in world space.
func world_box() -> AABB:
	var box := AABB()
	var first := true
	for child in find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var b := mi.global_transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _kill() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _placeholder(part_kind: String) -> Node3D:
	var host := Node3D.new()
	host.name = "Model"
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var m := StandardMaterial3D.new()
	m.roughness = 0.65
	match part_kind:
		"Battery":
			bm.size = Vector3(0.24, 0.16, 0.18)
			m.albedo_color = Color(0.08, 0.08, 0.09)
			mi.position = Vector3(0.0, 0.08, 0.0)
		"Bulb":
			bm.size = Vector3(0.048, 0.048, 0.077)
			m.albedo_color = Color(0.98, 0.95, 0.72)
			m.resource_name = "Equip_Light"
			mi.position = Vector3(0.0, 0.0, 0.0385)
		_:
			bm.size = Vector3(0.22, 0.05, 0.16)
			m.albedo_color = Color(0.90, 0.88, 0.78)
			m.resource_name = "Equip_Filter"
			mi.position = Vector3(0.0, 0.025, 0.0)
	bm.material = m
	mi.mesh = bm
	host.add_child(mi)
	return host
