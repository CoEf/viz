class_name Walker
extends Node3D
## The thing that pushes the grass around.
##
## Four of the ten shaders react to something moving through the field, and they do it in
## four different ways: 04 takes a world position uniform, 06 takes a per-instance one, 01
## reads the depth buffer and never gets told anything at all, and the other seven ignore
## it entirely. One shared pusher makes that difference legible - drive it into a patch and
## either the grass parts or it does not.
##
## It orbits on its own by default so a still render taken at two different times shows
## motion. WASD takes over the moment a key is pressed.

@export var auto_orbit: bool = true
@export var orbit_radius: float = 2.4
@export var orbit_period: float = 8.0
@export var move_speed: float = 4.5

var home: Vector3 = Vector3.ZERO

var _phase: float = 0.0
var _manual_offset: Vector3 = Vector3.ZERO
var _manual: bool = false


func _process(delta: float) -> void:
	var input := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		input.z += 1.0
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input.x += 1.0

	if input != Vector3.ZERO:
		_manual = true
		if auto_orbit:
			# Hand over from the orbit without a jump.
			_manual_offset = _orbit_offset()
			auto_orbit = false
		_manual_offset += input.normalized() * move_speed * delta
		_manual_offset.x = clampf(_manual_offset.x, -7.0, 7.0)
		_manual_offset.z = clampf(_manual_offset.z, -7.0, 7.0)

	if auto_orbit:
		_phase += delta / maxf(orbit_period, 0.01) * TAU
		global_position = home + _orbit_offset()
	else:
		global_position = home + _manual_offset


func _orbit_offset() -> Vector3:
	return Vector3(cos(_phase), 0.0, sin(_phase)) * orbit_radius


## Called by the gallery when the focused patch changes: the pusher follows the camera so
## interaction is always demonstrable in whatever plot you are looking at.
func move_home(to: Vector3) -> void:
	home = to
	if not auto_orbit:
		_manual_offset = Vector3.ZERO


func resume_orbit() -> void:
	auto_orbit = true
	_manual = false
	_manual_offset = Vector3.ZERO


func is_manual() -> bool:
	return _manual
