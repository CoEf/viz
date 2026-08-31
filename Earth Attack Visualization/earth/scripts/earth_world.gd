class_name EarthWorld
extends Node3D
## 이식본: earth_attack_preview.gd 를 워크스루용으로 감싼 얇은 API 계층.
## 완성 이펙트는 원본처럼 낳고-잊고(play), 해부는 autoplay를 끈 랩에서
## 파티클과 uniform을 직접 조작한다.

const EARTH_SPIKES := preload("res://earth/scenes/earth_spikes.tscn")

var camera_rig: OrbitCamera
var _lab: Node3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment


static func reset_globals() -> void:
	pass # 이 프로젝트는 전역 셰이더 파라미터를 쓰지 않는다


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 0.6
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.position = Vector3(0.0, 1.0, 0.0)
	camera_rig.set_view(0.45, -0.3, 11.0)


func environment() -> Environment:
	return world_environment.environment


## 원본 preview의 _launch() 이식 — 낳고 잊는다 (10초 뒤 스스로 사라짐).
func play() -> void:
	var earth_spikes := EARTH_SPIKES.instantiate()
	add_child(earth_spikes)


# --- 랩 (autoplay를 끈 해부용 인스턴스) ------------------------------------

func make_lab() -> void:
	clear_lab()
	_lab = EARTH_SPIKES.instantiate()
	_lab.autoplay = false
	add_child(_lab)


func clear_lab() -> void:
	if _lab != null and is_instance_valid(_lab):
		_lab.queue_free()
	_lab = null


func lab_rocks() -> GPUParticles3D:
	return _lab.get_node("RocksParticles")


func lab_smalls() -> GPUParticles3D:
	return _lab.get_node("SmallRocks")


func lab_dust() -> GPUParticles3D:
	return _lab.get_node("DustParticles")


## 커스텀 파티클 셰이더는 process_material 쪽이다.
func rocks_particle_material() -> ShaderMaterial:
	return lab_rocks().process_material


func dust_particle_material() -> ShaderMaterial:
	return lab_dust().process_material


## 바위의 렌더 셰이더 (rock_spikes.gdshader).
func rock_render_material() -> ShaderMaterial:
	return lab_rocks().material_override


func lab_replay(rocks: bool, dust: bool) -> void:
	lab_rocks().visible = rocks
	lab_smalls().visible = rocks
	lab_dust().visible = dust
	if rocks:
		# 시각화용: 첫 바위들이 이미 솟은 시점부터 보여준다
		lab_rocks().preprocess = 1.0
		lab_rocks().restart()
		lab_rocks().emitting = true
	else:
		lab_rocks().emitting = false
	if dust:
		lab_dust().preprocess = 1.0
		lab_dust().restart()
		lab_dust().emitting = true
	else:
		lab_dust().emitting = false


## 슬로 모션 — 배치·타이밍을 눈으로 따라가기 위한 것.
func set_lab_speed(value: float) -> void:
	for particles: GPUParticles3D in [lab_rocks(), lab_smalls(), lab_dust()]:
		particles.speed_scale = value
