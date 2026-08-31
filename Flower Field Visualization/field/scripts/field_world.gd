class_name FieldWorld
extends Node3D
## 꽃밭 이식본의 얇은 API 계층. 원본 프리뷰는 스크립트 없이 FlowerField가
## 스스로 생성한다 — 여기서는 카메라와 배치 파라미터 접근자만 더한다.

var camera_rig: OrbitCamera

@onready var field = $FlowerField
@onready var flowers: MultiMeshInstance3D = $FlowerField/Flowers
@onready var grass: MultiMeshInstance3D = $FlowerField/Grass
@onready var butterfly: GPUParticles3D = $Butterfly
@onready var world_environment: WorldEnvironment = $WorldEnvironment


static func reset_globals() -> void:
	pass


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 1.0
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.position = Vector3(0.0, 0.6, 0.0)
	camera_rig.set_view(0.5, -0.35, 8.0)


func environment() -> Environment:
	return world_environment.environment


func regenerate(jitter: float, cut_radius: float, flower_ratio: float,
		use_noise: bool) -> void:
	field.jitter = jitter
	field.cut_radius = cut_radius
	field.flower_ratio = flower_ratio
	field.use_noise_scale = use_noise
	field.generate()


## 풀·꽃이 같은 머티리얼을 공유한다 (flower_mat.tres).
func field_material() -> ShaderMaterial:
	return grass.material_override


func set_field_param(param: String, value: Variant) -> void:
	field_material().set_shader_parameter(param, value)
	(flowers.material_override as ShaderMaterial).set_shader_parameter(param, value)


func reset_field_params() -> void:
	for entry: Array in [["intensity", 0.25], ["waviness", 1.0], ["wind_speed", 0.025]]:
		set_field_param(entry[0] as String, entry[1])


func butterfly_material() -> ShaderMaterial:
	return butterfly.material_override


func set_butterflies_visible(value: bool) -> void:
	butterfly.visible = value
