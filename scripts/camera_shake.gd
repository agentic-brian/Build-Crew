class_name CameraShake
extends Camera3D
## Trauma-based screen shake. shake(amount) adds trauma, which decays on its
## own; the visible offset scales with trauma squared so small hits stay subtle
## and the big fall really lands.

@export var max_offset: float = 0.25
@export var max_roll_deg: float = 2.5
## Trauma lost per second.
@export var decay: float = 1.6
## How fast the shake wobbles.
@export var frequency: float = 18.0

var _trauma: float = 0.0
## A floor under the trauma while something keeps on shaking - the breaker's
## bite: the picture rattles steadily for as long as the bit runs, and the
## floor is taken away when it stops (Build Crew's improvement plan, 1.4).
var _floor: float = 0.0
var _time: float = 0.0
var _base_basis: Basis
var _has_base: bool = false
var _noise := FastNoiseLite.new()


func _ready() -> void:
	_noise.seed = 7
	_noise.frequency = 1.0


## Remember the current orientation as the rest pose. Call after look_at().
func capture_base() -> void:
	_base_basis = transform.basis
	_has_base = true


func shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## Keeps the trauma at least `f` until called again with 0.
func hold_floor(f: float) -> void:
	_floor = clampf(f, 0.0, 1.0)


func _process(delta: float) -> void:
	if not _has_base:
		capture_base()
	_trauma = maxf(_trauma, _floor)
	if _trauma <= 0.0:
		h_offset = 0.0
		v_offset = 0.0
		transform.basis = _base_basis
		return
	_time += delta * frequency
	var s := _trauma * _trauma
	h_offset = max_offset * s * _noise.get_noise_1d(_time)
	v_offset = max_offset * s * _noise.get_noise_1d(_time + 100.0)
	var roll := deg_to_rad(max_roll_deg) * s * _noise.get_noise_1d(_time + 200.0)
	transform.basis = _base_basis * Basis(Vector3.FORWARD, roll)
	_trauma = maxf(_trauma - decay * delta, 0.0)
