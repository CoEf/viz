class_name FFWorld
extends Node3D
## 포스필드 이식본의 얇은 API 계층. 원본 프리뷰는 스크립트가 없다 —
## 카메라, 셰이더 접근자, 그리고 교차선 시연용 막대만 더한다.

var camera_rig: OrbitCamera
var probe: MeshInstance3D

@onready var body: MeshInstance3D = $ForceField/ForceFieldBody
@onready var debris: GPUParticles3D = $ForceField/GPUParticles3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment


static func reset_globals() -> void:
	pass


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 1.2
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.position = Vector3(0.0, 0.9, 0.0)
	camera_rig.set_view(0.5, -0.25, 3.2)

	# 뎁스 교차선 시연용 막대 — 구를 관통시켜 교차 링을 보여준다.
	probe = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.0, 0.3, 0.3)
	probe.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.72)
	probe.material_override = material
	probe.position = Vector3(0.0, 1.0, 0.0)
	probe.visible = false
	add_child(probe)


func environment() -> Environment:
	return world_environment.environment


func field_material() -> ShaderMaterial:
	return body.material_override


func set_param(param: String, value: Variant) -> void:
	field_material().set_shader_parameter(param, value)


func reset_params() -> void:
	for entry: Array in [
			["show_edge", 1.0], ["show_hex_edge", 1.0], ["show_hex_fill", 1.0],
			["show_wave", 1.0], ["wave_amplitude", 0.01], ["debug_mode", 0]]:
		set_param(entry[0] as String, entry[1])


## 레이어 조합을 한 번에 지정한다 (레이어 스택 챕터용).
func set_layers(edge: bool, hex_edge: bool, hex_fill: bool, wave: bool) -> void:
	set_param("show_edge", 1.0 if edge else 0.0)
	set_param("show_hex_edge", 1.0 if hex_edge else 0.0)
	set_param("show_hex_fill", 1.0 if hex_fill else 0.0)
	set_param("show_wave", 1.0 if wave else 0.0)


func set_probe_visible(value: bool) -> void:
	probe.visible = value


func set_debris_visible(value: bool) -> void:
	debris.visible = value
