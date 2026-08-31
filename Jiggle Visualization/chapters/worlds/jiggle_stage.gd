class_name JiggleStage
extends Node3D
## 모든 챕터 월드의 공통 무대 — 바닥 · 조명 · 궤도 카메라 · 자극 · 고정 서브스텝.
## 원본 common/jiggle_demo.gd 의 골격에서 허브 UI 연동(파라미터 자동 UI · 프리셋)을
## 덜어내고, 카메라를 pipeline_viz 의 OrbitCamera 로 바꾼 것.
##
## 하위 클래스가 채우는 것은 원본과 같다:
## _build() · _frame_update(delta) · _simulate(delta) · _post_simulate(delta) ·
## _draw_debug() · reset_world()

## 한 프레임에 허용할 최대 서브스텝. 이 이상 밀리면 따라잡기를 포기한다.
const MAX_SUBSTEPS := 8
const GROUND_COLOR := Color(0.10, 0.11, 0.13)

var stimulus := Stimulus.new()
var debug: JiggleDebugDraw
var camera_rig: OrbitCamera

var _ground: MeshInstance3D
var _accumulator := 0.0
var _substep_hz := 120.0


func _ready() -> void:
	debug = JiggleDebugDraw.new()
	add_child(debug)
	_build_stage()
	_build()
	reset_world()


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	stimulus.step(delta)
	_frame_update(delta)
	_advance(delta)
	_post_simulate(delta)
	debug.begin()
	_draw_debug()
	debug.end()


## 프레임 delta 를 고정 크기 서브스텝으로 쪼개 시뮬레이션한다.
## 60fps에서 튜닝한 흔들림이 144fps에서 달라지는 것을 막는, Jiggle 구현의 기본기.
func _advance(delta: float) -> void:
	var step := 1.0 / maxf(_substep_hz, 1.0)
	_accumulator += delta
	var steps := 0
	while _accumulator >= step and steps < MAX_SUBSTEPS:
		_simulate(step)
		_accumulator -= step
		steps += 1
	if steps >= MAX_SUBSTEPS:
		_accumulator = 0.0


func set_substep_hz(hz: float) -> void:
	_substep_hz = maxf(hz, 1.0)
	_accumulator = 0.0


func trigger_impulse() -> void:
	stimulus.trigger_impulse()


func set_stimulus(kind: Stimulus.Kind) -> void:
	stimulus.kind = kind
	stimulus.reset()


## 자극 위상을 앞으로 당긴다. 스텝을 막 넘어온 직후에도 목표가 이미 움직인 상태가
## 되어, 다음 몇 프레임 안에 흔들림이 눈에 보인다(autotour 스크린샷 대책이기도 하다).
func kick(seconds := 0.5) -> void:
	stimulus.step(seconds)


## 카메라를 스텝이 보여 주려는 곳에 맞춘다.
func set_view(focus: Vector3, yaw: float, pitch: float, dist: float) -> void:
	camera_rig.position = focus
	camera_rig.set_view(yaw, pitch, dist)


func set_ground_y(y: float) -> void:
	_ground.position.y = y


func _build_stage() -> void:
	_ground = MeshInstance3D.new()
	_ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	_ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = GROUND_COLOR
	ground_material.roughness = 0.95
	_ground.material_override = ground_material
	add_child(_ground)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-38.0), 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	# 형광 기즈모(초록 목표 · 노랑 파티클)가 주인공이라 배경은 어두운 단색으로 둔다.
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.055, 0.065, 0.085)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.62, 0.66, 0.74)
	settings.ambient_light_energy = 0.6
	environment.environment = settings
	add_child(environment)

	camera_rig = OrbitCamera.new()
	camera_rig.name = "CameraRig"
	camera_rig.min_distance = 0.25
	camera_rig.max_distance = 16.0
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera_rig.add_child(camera)
	add_child(camera_rig)


# --- 하위 클래스가 덮어쓰는 부분 -------------------------------------------------


func _build() -> void:
	pass


## 프레임당 정확히 한 번. 자극을 씬에 반영하는 일을 여기서 한다.
func _frame_update(_delta: float) -> void:
	pass


## 고정 timestep 서브스텝. 월드가 솔버를 직접 들고 있을 때만 쓴다.
## (SkeletonModifier3D 기반 월드는 모디파이어가 알아서 서브스텝을 돈다.)
func _simulate(_delta: float) -> void:
	pass


## 서브스텝을 다 돌린 뒤 프레임당 한 번. 메쉬 굽기 같은 일을 여기서 한다.
func _post_simulate(_delta: float) -> void:
	pass


func _draw_debug() -> void:
	pass


func reset_world() -> void:
	pass


## 바닥 위 옅은 격자. 자극이 몸을 얼마나 움직이는지 보이는 기준선이 된다.
func draw_grid(half := 2.0) -> void:
	var color := Color(1.0, 1.0, 1.0, 0.05)
	var count := int(half * 4.0)
	for i in range(-count, count + 1):
		var t := float(i) * 0.25
		debug.line(Vector3(t, 0.001, -half), Vector3(t, 0.001, half), color)
		debug.line(Vector3(-half, 0.001, t), Vector3(half, 0.001, t), color)
