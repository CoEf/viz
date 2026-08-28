class_name DiveRig
extends Node3D
## 수면 아래에서 위를 올려다보는 카메라.
##
## OrbitCamera는 pitch를 음수(내려다보기)로 잠가 둔다 — 워크스루의 거의 모든
## 스텝이 그래야 하기 때문이다. 23번(Snell's Window)만 예외라서, 그 스텝에서만
## 이 리그로 갈아탄다. 위에서 보면 23번은 그냥 거울이라 아무 의미가 없다.

const EYE_HEIGHT := -2.2
## 스넬의 창은 시선 축에서 반각 48.6도짜리 원이다. 기본 화각 75도로는 원이
## 프레임을 넘치므로, 이 카메라만 화각을 넓혀 경계선 전체를 화면에 넣는다.
const LOOK_PITCH := 1.05
const DIVE_FOV := 100.0

var _yaw := 0.0
var _camera: Camera3D


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.name = "DiveCamera"
	_camera.far = 900.0
	_camera.fov = DIVE_FOV
	_camera.cull_mask = 1
	add_child(_camera)
	_apply()


func set_active(on: bool) -> void:
	visible = on
	set_process_unhandled_input(on)
	if on:
		_camera.current = true


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_yaw = wrapf(_yaw - motion.relative.x * 0.006, -TAU, TAU)
		_apply()


func _apply() -> void:
	_camera.position = Vector3(0.0, EYE_HEIGHT, 0.0)
	_camera.rotation = Vector3(LOOK_PITCH, _yaw, 0.0)
