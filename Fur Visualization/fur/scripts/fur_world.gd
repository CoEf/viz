class_name FurWorld
extends Node3D
## 이식본: fur_preview.gd 를 워크스루용으로 감싼 얇은 API 계층.
## 깜빡임 타이머 배선은 원본 그대로. 퍼 머티리얼·빌더·격자 접근자와
## light() 중복 가산 시연용 보조 라이트만 더했다.

var camera_rig: OrbitCamera

@onready var animation_tree = %AnimationTree
@onready var blink_timer = %BlinkTimer
@onready var fur: MeshInstance3D = $Fur
@onready var grid: MeshInstance3D = $GridMesh
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var second_light: OmniLight3D


static func reset_globals() -> void:
	pass # 이 프로젝트는 전역 셰이더 파라미터를 쓰지 않는다


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 0.4
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.position = Vector3(0.0, 0.45, 0.0)
	camera_rig.set_view(0.6, -0.25, 1.8)

	# light() 중복 가산 시연용 — 챕터 4에서만 켠다.
	second_light = OmniLight3D.new()
	second_light.light_color = Color(1.0, 0.9, 0.7)
	second_light.light_energy = 1.5
	second_light.omni_range = 6.0
	second_light.position = Vector3(-1.5, 1.2, -1.0)
	second_light.visible = false
	add_child(second_light)

	# --- 원본 fur_preview.gd _ready()의 깜빡임 배선 그대로 ---
	blink_timer.start(1.0)
	blink_timer.timeout.connect(_on_blink_timer)


func _on_blink_timer():
	blink_timer.start(randf_range(1.0, 4.0))
	animation_tree.set("parameters/BlinkShot/request", true)


func blink_now() -> void:
	animation_tree.set("parameters/BlinkShot/request", true)


func environment() -> Environment:
	return world_environment.environment


# --- 퍼 -----------------------------------------------------------------

func fur_material() -> ShaderMaterial:
	return fur.material_override


func set_fur_param(param: String, value: Variant) -> void:
	fur_material().set_shader_parameter(param, value)


func reset_fur_params() -> void:
	for entry: Array in [
			["_fur_length", 0.03], ["_fur_deformation", 0.0], ["_fur_gravity", 0.0],
			["_glossiness", 0.45], ["taper", 1.0], ["flow_strength", 0.2],
			["terminator_boost", 4.0], ["rim_gated", 1.0], ["debug_mode", 0]]:
		set_fur_param(entry[0] as String, entry[1])


## 셸 개수를 바꿔 다시 굽는다 — fur_builder.rebuild() 호출.
func rebuild_fur(resolution: int) -> void:
	fur.resolution = resolution
	fur.rebuild()


func set_fur_visible(value: bool) -> void:
	fur.visible = value


func set_second_light(value: bool) -> void:
	second_light.visible = value


# --- 격자 바닥 ----------------------------------------------------------

func grid_material() -> ShaderMaterial:
	return grid.material_override


func set_grid_param(param: String, value: Variant) -> void:
	grid_material().set_shader_parameter(param, value)
