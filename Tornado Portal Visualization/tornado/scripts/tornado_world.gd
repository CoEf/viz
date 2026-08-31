class_name TornadoWorld
extends Node3D
## 이식본: portal_preview.gd 를 워크스루용으로 감싼 얇은 API 계층.
## 연출은 전부 4초짜리 default 애니메이션 — 스크립트는 재생·스크럽·솔로 표시만 한다.

var camera_rig: OrbitCamera

## true면 _process에서 상자를 계속 돌린다 — 흡입 변형이 월드 공간이라
## 회전과 무관하게 같은 곳으로 늘어나는 것을 보여주는 용도.
var spin_target := false

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hole: MeshInstance3D = $Hole
@onready var hole_body: MeshInstance3D = $Hole/HoleBody
@onready var target: MeshInstance3D = $Target
@onready var halo: MeshInstance3D = $HaloLight
@onready var trails: GPUParticles3D = $TrailsParticles
@onready var smalls: GPUParticles3D = $SmallParticles
@onready var attractor: GPUParticlesAttractorSphere3D = $GPUParticlesAttractorSphere3D
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
	camera_rig.set_view(0.5, -0.35, 9.0)


func _process(delta: float) -> void:
	if spin_target:
		target.rotate_y(delta * 1.2)


func environment() -> Environment:
	return world_environment.environment


## 원본 preview의 입력 처리 이식 — 재생 중이면 무시.
func play() -> void:
	if animation_player.is_playing():
		return
	animation_player.play("default")


func scrub(time: float) -> void:
	animation_player.play("default")
	animation_player.pause()
	animation_player.seek(time, true)


## stop()은 RESET을 적용한다 — opening 0, 파티클 꺼짐 등 시작 상태로 복귀.
func stop() -> void:
	animation_player.stop()


func solo(show_hole: bool, show_halo: bool, show_target: bool, show_particles: bool) -> void:
	hole.visible = show_hole
	halo.visible = show_halo
	target.visible = show_target
	trails.visible = show_particles
	smalls.visible = show_particles
	trails.emitting = show_particles
	smalls.emitting = show_particles


func hole_material() -> ShaderMaterial:
	return hole.material_override


func set_hole_param(param: String, value: Variant) -> void:
	hole_material().set_shader_parameter(param, value)


func reset_hole_params(opening: float) -> void:
	for entry: Array in [
			["opening", opening], ["time_offset", 0.0],
			["heightmap_scale", 32.0], ["heightmap_min_layers", 16],
			["heightmap_max_layers", 64], ["debug_mode", 0]]:
		set_hole_param(entry[0] as String, entry[1])


func light_material() -> ShaderMaterial:
	return hole_body.material_override


func halo_material() -> ShaderMaterial:
	return halo.material_override


func target_material() -> ShaderMaterial:
	return target.material_override


func set_pull(value: float) -> void:
	target_material().set_shader_parameter("pull_intensity", value)


func set_attractor_strength(value: float) -> void:
	attractor.strength = value
