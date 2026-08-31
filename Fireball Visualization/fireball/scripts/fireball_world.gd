class_name FireballWorld
extends Node3D
## Fireball 이식본의 얇은 API 계층. 챕터들이 개별 노드 경로를 몰라도
## 정지 전시용 본체·발사대·임팩트·해부용 쿼드를 켜고 끄고 조절할 수 있게 한다.
## 씬 안의 머티리얼은 전부 resource_local_to_scene이라 챕터가 만져도 서로 안 샌다.

const PROJECTILE_SCENE := preload("res://fireball/scenes/simple_projectile.tscn")
const IMPACT_SCENE := preload("res://fireball/scenes/fireball_impact.tscn")

var camera_rig: OrbitCamera

## shoot()에 적용되는 비행 설정 — 챕터가 스텝마다 바꾼다.
var homing := true
var turn_rate := 4.0
var hard_kill := false
var record_trajectories := false

var _scrub_impact: Node3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var stationary_rig: Node3D = $StationaryRig
@onready var stationary: Node3D = $StationaryRig/Fireball
@onready var launcher: Marker3D = $Launcher
@onready var projectile_root: Node3D = $ProjectileRoot
@onready var target: Node3D = $Target
@onready var impact_anchor: Node3D = $ImpactAnchor
@onready var anatomy_quad: MeshInstance3D = $AnatomyQuad
@onready var flash_quad: MeshInstance3D = $FlashQuad
@onready var ribbons: TrajectoryRibbons = $TrajectoryRibbons
@onready var autofire_timer: Timer = $AutofireTimer


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
	camera_rig.position = Vector3(0.0, 1.4, 0.0)
	camera_rig.set_view(0.65, -0.3, 8.0)
	autofire_timer.timeout.connect(shoot)


func environment() -> Environment:
	return world_environment.environment


# --- 정지 전시용 본체 ------------------------------------------------------

func shell_mesh() -> MeshInstance3D:
	return stationary.get_node("%FireballShellMesh")


func shell_material() -> ShaderMaterial:
	return shell_mesh().material_override


func core_mesh() -> MeshInstance3D:
	return shell_mesh().get_node("Core")


func core_material() -> ShaderMaterial:
	return core_mesh().material_override


func trail_particles() -> GPUParticles3D:
	return stationary.get_node("%FireTrail")


func smoke_particles() -> GPUParticles3D:
	return stationary.get_node("%FireSmoke")


func set_stationary_visible(value: bool) -> void:
	stationary_rig.visible = value


## Core가 껍질 메시의 자식이라 visible을 끄면 같이 사라진다.
## 껍질 지오메트리만 투명 처리해 코어를 단독으로 보여줄 수 있게 한다.
func set_shell_visible(value: bool) -> void:
	var mesh := shell_mesh()
	mesh.transparency = 0.0 if value else 1.0
	mesh.cast_shadow = (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if value
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func set_core_visible(value: bool) -> void:
	core_mesh().visible = value


func set_trail_emitting(value: bool) -> void:
	trail_particles().emitting = value


func set_smoke_emitting(value: bool) -> void:
	smoke_particles().emitting = value


## 두 파티클의 중력을 함께 뒤집는다 — 원본 값은 (0, 1, 0) 위쪽.
func set_particles_gravity_up(up: bool) -> void:
	var gravity := Vector3(0, 1, 0) if up else Vector3(0, -1, 0)
	(trail_particles().process_material as ParticleProcessMaterial).gravity = gravity
	(smoke_particles().process_material as ParticleProcessMaterial).gravity = gravity


## fireball.gd의 _process가 매 프레임 def_x/def_z를 덮어쓴다.
## 수동 슬라이더 스텝에서는 이걸 꺼야 값이 유지된다.
func set_stationary_inertia(enabled: bool) -> void:
	stationary.set_process(enabled)


func set_shell_param(param: String, value: Variant) -> void:
	shell_material().set_shader_parameter(param, value)


func set_core_param(param: String, value: Variant) -> void:
	core_material().set_shader_parameter(param, value)


## 스텝 전환용 일괄 초기화 — 셰이더를 원본 기본값으로 되돌린다.
func reset_shell_params() -> void:
	for entry: Array in [
			["wave_amplitude", 0.1], ["cut_offset", -0.15], ["cut_enabled", 1.0],
			["use_gradient", 1.0], ["rim_enabled", 1.0], ["debug_mode", 0],
			["def_x", 0.0], ["def_z", 0.0]]:
		set_shell_param(entry[0] as String, entry[1])


func reset_core_params() -> void:
	set_core_param("rim_threshold", 0.4)
	set_core_param("debug_mode", 0)


# --- 발사 -----------------------------------------------------------------

## 원본 fireball_preview.gd shoot()의 이식 — 산포 각을 만드는 회전 두 번과
## 0.4:0.6 혼합까지 그대로. turn_rate/hard_kill만 시각화용으로 주입한다.
func shoot() -> void:
	var projectile : SimpleProjectile = PROJECTILE_SCENE.instantiate()
	projectile.turn_rate = turn_rate
	projectile.hard_kill = hard_kill
	projectile_root.add_child(projectile)

	var speed = 0.2 * randfn(1.0, 0.1)
	projectile.speed = speed

	var base_x : Vector3 = launcher.transform.basis.x * speed
	var b_y = base_x.rotated(Vector3(0, 1, 0), randfn(0.0, PI * 0.5))
	var b_z = base_x.rotated(Vector3(0, 0, 1), randf() * PI * 0.5)
	base_x = (b_y * 0.4 + b_z * 0.6).normalized()

	if homing:
		projectile.launch(launcher.global_position, base_x * speed, target)
	else:
		# 유도 없는 직진 비교용 — 발사체에 붙인 유령 타깃이 항상 진행 방향
		# 100 유닛 앞에 있어 move_toward가 방향을 바꾸지 않는다.
		var ghost := Marker3D.new()
		projectile.add_child(ghost)
		projectile.launch(launcher.global_position, base_x * speed, ghost)
		ghost.global_position = launcher.global_position + base_x * 100.0
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			if is_instance_valid(projectile):
				projectile.queue_free())

	if record_trajectories:
		ribbons.track(projectile)


func set_autofire(enabled: bool, interval := 1.4) -> void:
	autofire_timer.wait_time = interval
	if enabled:
		autofire_timer.start()
	else:
		autofire_timer.stop()


func clear_projectiles() -> void:
	for child in projectile_root.get_children():
		child.queue_free()
	ribbons.clear()


func set_target_visible(value: bool) -> void:
	target.visible = value
	var hit_box: HitBox3D = get_node("%HitBox")
	hit_box.active = value


# --- 임팩트 ---------------------------------------------------------------

## 원본 흐름 그대로 자동 재생·4초 뒤 자멸하는 임팩트를 하나 터뜨린다.
func play_impact() -> void:
	var impact := IMPACT_SCENE.instantiate()
	impact_anchor.add_child(impact)


## 수동 스크럽용 임팩트 — 자동 재생을 끄고 default 애니메이션을 세워 둔다.
func make_scrub_impact() -> void:
	clear_impacts()
	_scrub_impact = IMPACT_SCENE.instantiate()
	_scrub_impact.autoplay = false
	impact_anchor.add_child(_scrub_impact)
	var player: AnimationPlayer = _scrub_impact.get_node("%AnimationPlayer")
	player.play("default")
	player.pause()
	player.seek(0.0, true)


func scrub_impact(time: float) -> void:
	if _scrub_impact == null:
		return
	var player: AnimationPlayer = _scrub_impact.get_node("%AnimationPlayer")
	player.seek(time, true)


## 스크럽 중인 임팩트의 플래시 머티리얼 — 트랙이 쓴 현재 값을 읽는 용도.
func scrub_flash_material() -> ShaderMaterial:
	if _scrub_impact == null:
		return null
	return _scrub_impact.get_node("%Flash").material_override


func clear_impacts() -> void:
	for child in impact_anchor.get_children():
		child.queue_free()
	_scrub_impact = null


# --- 해부용 쿼드 ----------------------------------------------------------

func set_anatomy_visible(value: bool) -> void:
	anatomy_quad.visible = value


func anatomy_material() -> ShaderMaterial:
	return anatomy_quad.material_override


func set_anatomy_param(param: String, value: Variant) -> void:
	anatomy_material().set_shader_parameter(param, value)


func set_flash_visible(value: bool) -> void:
	flash_quad.visible = value


func flash_material() -> ShaderMaterial:
	return flash_quad.material_override


func set_flash_param(param: String, value: Variant) -> void:
	flash_material().set_shader_parameter(param, value)
