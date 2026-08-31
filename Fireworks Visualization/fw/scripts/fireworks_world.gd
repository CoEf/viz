class_name FireworksWorld
extends Node3D
## 이식본: fireworks_preview.gd 를 워크스루용으로 감싼 얇은 API 계층.
## 확률 커브 스폰 루프는 원본 그대로. 포즈 로켓·커스텀 폭발 등 해부용 API를 더했다.

const FIREWORK_EXPLOSION_SCENE := preload("res://fw/explosion/firework_explosion.tscn")
const FIREWORK_ROCKET_SCENE := preload("res://fw/rocket/firework_rocket.tscn")

@export var colors : Gradient
@export var probability_curve : Curve
@onready var spawn_timer = %SpawnTimer

var camera_rig: OrbitCamera
var tick = 0
var tick_size = 100

## 시각화용 — 확률 전체에 곱하는 배율 (1 = 원본).
var probability_scale := 1.0

var _pose_rocket: MeshInstance3D


static func reset_globals() -> void:
	pass


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 2.0
	camera_rig.max_distance = 30.0
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.position = Vector3(0.0, -0.5, 0.0)
	camera_rig.set_view(0.4, -0.1, 17.0)

	# --- 원본 fireworks_preview.gd 의 스폰 루프 그대로 ---
	spawn_timer.timeout.connect(func():
		var progress : float = tick / float(tick_size)
		var probability : float = probability_curve.sample(progress)
		if randf() < probability * probability_scale:
			_spawn_random_firework()
		tick = (tick + 1) % tick_size
	)


func set_show_running(value: bool) -> void:
	spawn_timer.paused = not value


func current_progress() -> float:
	return tick / float(tick_size)


func current_probability() -> float:
	return probability_curve.sample(current_progress())


func _get_random_point(radius : float) -> Vector3:
	return Vector3(
		randfn(0.0, 1.0) * radius,
		randfn(0.0, 1.0) * radius,
		randfn(0.0, 1.0) * radius
	)


func _spawn_random_firework():
	launch_rocket(randf_range(8.0, 12.0))


## 원본 _spawn_random_firework 이식 — 속도만 밖에서 받는다.
func launch_rocket(speed: float) -> void:
	var end_position : Vector3 = _get_random_point(2.0)
	var start_position : Vector3 = end_position
	start_position.y = -8.0
	var rocket = FIREWORK_ROCKET_SCENE.instantiate()
	add_child(rocket)
	rocket.setup(start_position, end_position, speed)
	rocket.finished.connect(_spawn_explosion.bind(end_position))


func _spawn_explosion(at : Vector3 = Vector3.ZERO):
	var firework = FIREWORK_EXPLOSION_SCENE.instantiate()
	add_child(firework)
	firework.global_position = at
	firework.setup(colors.sample(randf()), randf_range(4.0, 6.0), randi_range(48, 64))


## 파라미터를 직접 주입한 폭발 — setup() 주입을 눈으로 확인하는 용도.
func spawn_custom_explosion(velocity: float, trails_count: int) -> void:
	var firework = FIREWORK_EXPLOSION_SCENE.instantiate()
	add_child(firework)
	firework.global_position = Vector3(0, 0, 0)
	firework.setup(colors.sample(randf()), velocity, trails_count)


# --- 포즈 로켓 (트윈 없이 세워 두고 lifetime 슬라이더로 만진다) --------------

func make_pose_rocket() -> void:
	clear_pose_rocket()
	_pose_rocket = FIREWORK_ROCKET_SCENE.instantiate()
	add_child(_pose_rocket)
	_pose_rocket.position = Vector3(0, -1, 0)
	set_pose_lifetime(0.5)


func clear_pose_rocket() -> void:
	if _pose_rocket != null and is_instance_valid(_pose_rocket):
		_pose_rocket.queue_free()
	_pose_rocket = null


func set_pose_lifetime(value: float) -> void:
	if _pose_rocket == null:
		return
	_pose_rocket.material_override.set_shader_parameter("lifetime", value)
