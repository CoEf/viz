class_name WaterWorld
extends Node3D
## 이식본: water_hand_preview.gd 를 워크스루용으로 감싼 얇은 API 계층.
## 시그널 배선(raised/slaped)은 원본 그대로, 입력 대신 play_sequence()로 트리거한다.
## 팔·소용돌이·물보라·젖은 자국을 따로 세워 두고 만질 수 있는 접근자를 더했다.

var camera_rig: OrbitCamera
var camera: ShakeCamera

@onready var water_hand = %WaterHand
@onready var wet_player: AnimationPlayer = %WetPlayer
@onready var target = %Target
@onready var impact_splash = %ImpactSplash
@onready var arm_impact_droplet: GPUParticles3D = %ArmImpactDroplet
@onready var hand_splash = %HandSplash
@onready var cooldown_timer: Timer = %CooldownTimer
@onready var arm_spawn_effect = %ArmSpawnEffect
@onready var wet_spot: MeshInstance3D = $WetSpot
@onready var world_environment: WorldEnvironment = $WorldEnvironment


static func reset_globals() -> void:
	pass # 이 프로젝트는 전역 셰이더 파라미터를 쓰지 않는다


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 0.6
	camera = ShakeCamera.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.position = Vector3(-0.5, 2.0, 0.0)
	camera_rig.set_view(0.5, -0.3, 11.0)

	# --- 원본 water_hand_preview.gd _ready()의 배선 그대로 ---
	water_hand.raised.connect(func():
		hand_splash.splash()
		wet_player.stop(true)
		wet_player.play("default", 0.1)
		)
	water_hand.slaped.connect(func():
		target.hit()
		impact_splash.splash()
		camera.shake()
		arm_impact_droplet.emitting = true
		)


func environment() -> Environment:
	return world_environment.environment


## 원본 preview의 입력 처리 이식 — 소용돌이를 열고 0.15초 뒤 팔을 부른다.
func play_sequence() -> void:
	if cooldown_timer.time_left != 0:
		return
	arm_spawn_effect.play_effect()
	await get_tree().create_timer(0.15).timeout
	water_hand.play_default()
	cooldown_timer.start(3.0)


# --- 표시 토글 -------------------------------------------------------------

func set_arm_visible(value: bool) -> void:
	water_hand.visible = value


func set_target_visible(value: bool) -> void:
	target.visible = value


func set_whirlpool_visible(value: bool) -> void:
	arm_spawn_effect.visible = value


func set_wet_visible(value: bool) -> void:
	wet_spot.visible = value


func set_splashes_visible(value: bool) -> void:
	impact_splash.visible = value
	hand_splash.visible = value


## 챕터 솔로 표시용 — 전부 끄고 필요한 것만 켠다.
func solo(arm: bool, whirlpool: bool, splash: bool, wet: bool, show_target: bool) -> void:
	set_arm_visible(arm)
	set_whirlpool_visible(whirlpool)
	set_splashes_visible(splash)
	set_wet_visible(wet)
	set_target_visible(show_target)


# --- 팔 (트라이플래너 물 셰이더) -------------------------------------------

func arm_player() -> AnimationPlayer:
	return water_hand.get_node("AnimationPlayer")


func arm_tree() -> AnimationTree:
	return water_hand.get_node("AnimationTree")


## Slap 애니메이션의 t초 시점에 팔을 정지 포즈로 세운다.
func pose_arm(time: float) -> void:
	arm_tree().active = false
	var player := arm_player()
	player.play("Slap")
	player.pause()
	player.seek(time, true)


func release_arm() -> void:
	arm_player().stop()
	arm_tree().active = true


func water_material() -> ShaderMaterial:
	return water_hand.get_node("Armature/Skeleton3D/WaterHand").material_override


func set_water_param(param: String, value: Variant) -> void:
	water_material().set_shader_parameter(param, value)


func reset_water_params() -> void:
	for entry: Array in [
			["uv1_blend_sharpness", 0.1], ["noise_mix", 0.85],
			["wave_amplitude", 0.01], ["edge_small", 0.1], ["edge_big", 2.0],
			["foam_enabled", 1.0], ["debug_mode", 0]]:
		set_water_param(entry[0] as String, entry[1])


# --- 소용돌이 ---------------------------------------------------------------

func whirlpool_material() -> ShaderMaterial:
	return (arm_spawn_effect.get_node("Whirlpool") as MeshInstance3D).material_override


func set_whirlpool_param(param: String, value: Variant) -> void:
	whirlpool_material().set_shader_parameter(param, value)


func reset_whirlpool_params(opening: float, offset: float) -> void:
	for entry: Array in [
			["opening", opening], ["offset", offset],
			["swirl_size", 4.0], ["swirl_arms", 1], ["debug_mode", 0]]:
		set_whirlpool_param(entry[0] as String, entry[1])


func whirlpool_player() -> AnimationPlayer:
	return arm_spawn_effect.get_node("AnimationPlayer")


func whirlpool_scrub(time: float) -> void:
	var player := whirlpool_player()
	player.play("default")
	player.pause()
	player.seek(time, true)


func whirlpool_stop() -> void:
	whirlpool_player().stop()


# --- 물보라 (ImpactSplash 인스턴스를 해부용으로 쓴다) -----------------------

func splash_shell() -> MeshInstance3D:
	return impact_splash.get_node("SplashShell")


func splash_material() -> ShaderMaterial:
	return splash_shell().material_override


func set_splash_param(param: String, value: Variant) -> void:
	splash_material().set_shader_parameter(param, value)


func splash_player() -> AnimationPlayer:
	return impact_splash.get_node("SplashPlayer")


func splash_scrub(time: float) -> void:
	var player := splash_player()
	player.play("splash")
	player.pause()
	player.seek(time, true)


## 물보라 왕관을 중간 크기로 세워 두고 셰이더만 만질 수 있게 한다.
func splash_pose_static() -> void:
	splash_player().stop()
	splash_shell().scale = Vector3(3.0, 2.5, 3.0)


func replay_droplets() -> void:
	arm_impact_droplet.restart()
	arm_impact_droplet.emitting = true
	var droplet: GPUParticles3D = impact_splash.get_node("WaterDroplet")
	var small: GPUParticles3D = impact_splash.get_node("SplashParticles")
	droplet.restart()
	droplet.emitting = true
	small.restart()
	small.emitting = true


# --- 젖은 자국 --------------------------------------------------------------

func wet_material() -> ShaderMaterial:
	return wet_spot.material_override


func set_wet_param(param: String, value: Variant) -> void:
	wet_material().set_shader_parameter(param, value)


func wet_scrub(time: float) -> void:
	wet_player.play("default")
	wet_player.pause()
	wet_player.seek(time, true)


func wet_stop() -> void:
	wet_player.stop()
