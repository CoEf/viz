class_name OrbitCamera
extends Node3D
## Left-drag orbit + wheel zoom rig; expects a Camera3D child on local +Z.
## 챕터가 스텝마다 시점을 지정할 수 있도록 set_view()를 제공한다.

@export var distance := 14.0
@export var min_distance := 4.0
@export var max_distance := 40.0
@export var orbit_speed := 0.006
@export var zoom_step := 1.12

var _yaw := 0.65
var _pitch := -0.38

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_apply_view()


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_yaw = wrapf(_yaw - motion.relative.x * orbit_speed, -TAU, TAU)
		_pitch = clampf(_pitch - motion.relative.y * orbit_speed, -1.35, -0.06)
		_apply_view()
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance / zoom_step, min_distance, max_distance)
			_apply_view()
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance * zoom_step, min_distance, max_distance)
			_apply_view()


func set_view(yaw: float, pitch: float, view_distance: float) -> void:
	_yaw = yaw
	_pitch = clampf(pitch, -1.35, -0.06)
	distance = clampf(view_distance, min_distance, max_distance)
	_apply_view()


func _apply_view() -> void:
	rotation = Vector3(_pitch, _yaw, 0.0)
	_camera.position = Vector3(0.0, 0.0, distance)
