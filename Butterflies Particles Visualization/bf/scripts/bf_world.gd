class_name BFWorld
extends Node3D
## 나비 파티클 이식본의 얇은 API 계층. 원본은 스크립트가 없는 상시 이펙트 —
## 카메라와 파티클 접근자만 더한다.

var camera_rig: OrbitCamera

@onready var butterfly: GPUParticles3D = $Butterfly
@onready var sparks: GPUParticles3D = $Sparks
@onready var world_environment: WorldEnvironment = $WorldEnvironment


static func reset_globals() -> void:
	pass


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 2.0
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.position = Vector3(0.0, 2.5, 0.0)
	camera_rig.set_view(0.5, -0.25, 7.0)


func environment() -> Environment:
	return world_environment.environment


func butterfly_process() -> ParticleProcessMaterial:
	return butterfly.process_material


func butterfly_material() -> ShaderMaterial:
	return butterfly.material_override


func set_butterfly_amount(value: int) -> void:
	butterfly.amount = value
	butterfly.preprocess = 5.0
	butterfly.restart()


func set_spark_frequency(value: float) -> void:
	butterfly_process().sub_emitter_frequency = value


func set_sparks_visible(value: bool) -> void:
	sparks.visible = value
