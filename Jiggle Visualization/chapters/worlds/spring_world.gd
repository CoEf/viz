class_name SpringWorld
extends JiggleStage
## 챕터 1 월드 — 같은 목표를 쫓는 스프링-댐퍼 공.
## 원본 demos/01_spring_basics/spring_basics_demo.gd 이식.
## 공 세 개는 완전히 같은 목표를 쫓고 감쇠비만 다르다.

const BALL_RADIUS := 0.085
const BASE_HEIGHT := 1.15
const SPACING := 0.60
const COLORS: Array[Color] = [
	Color(1.00, 0.42, 0.42),
	Color(0.45, 0.95, 0.55),
	Color(0.45, 0.68, 1.00),
]

var frequency := 2.0
var zeta_left := 0.12
var zeta_middle := 1.0
var zeta_right := 2.2
var integrator := JiggleSpring.Integrator.SEMI_IMPLICIT
var simulation_rate := 120.0
var gravity_enabled := false
var max_distance := 0.0
## true 면 왼쪽 공 하나만 가운데에 둔다(스텝 1용).
var solo := false

var _springs: Array[JiggleSpring] = []
var _balls: Array[MeshInstance3D] = []
var _targets := PackedVector3Array()


func _build() -> void:
	stimulus.kind = Stimulus.Kind.BOUNCE
	for i in 3:
		var ball := MeshInstance3D.new()
		ball.name = "Ball%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = BALL_RADIUS
		sphere.height = BALL_RADIUS * 2.0
		ball.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = COLORS[i]
		material.roughness = 0.35
		ball.material_override = material
		add_child(ball)
		_balls.append(ball)

		var spring := JiggleSpring.new()
		spring.reset_to(_base_position(i))
		_springs.append(spring)
		_targets.append(_base_position(i))


func set_solo(value: bool) -> void:
	solo = value
	reset_world()


func apply() -> void:
	set_substep_hz(simulation_rate)
	_sync_springs()


func reset_world() -> void:
	for i in _springs.size():
		var base := _base_position(i)
		_springs[i].reset_to(base)
		_targets[i] = base
		_balls[i].position = base
		_balls[i].visible = i == 0 if solo else true
	stimulus.reset()


func _simulate(delta: float) -> void:
	_sync_springs()
	for i in _springs.size():
		if solo and i > 0:
			continue
		var target := _base_position(i) + stimulus.offset
		_targets[i] = target
		_balls[i].position = _springs[i].step(delta, target)


func _draw_debug() -> void:
	draw_grid(1.5)
	for i in _springs.size():
		if solo and i > 0:
			continue
		var spring := _springs[i]
		debug.spring_gizmo(
			_targets[i], spring.position, spring.velocity, BALL_RADIUS * 1.35, max_distance
		)
		# 흔들림이 전혀 없을 때의 기준선. 자극이 얼마나 크게 들어오는지 알 수 있다.
		var base := _base_position(i)
		debug.line(
			base - Vector3(0.12, 0.0, 0.0),
			base + Vector3(0.12, 0.0, 0.0),
			Color(1.0, 1.0, 1.0, 0.18)
		)


## 그래프용: 목표 대비 상하 변위.
func sample_plot() -> Dictionary:
	if solo:
		return {"left": _springs[0].position.y - _targets[0].y}
	return {
		"left": _springs[0].position.y - _targets[0].y,
		"middle": _springs[1].position.y - _targets[1].y,
		"right": _springs[2].position.y - _targets[2].y,
	}


## 진동수 → 강성 k. 코드 패널의 실시간 숫자에 쓴다.
func spring_k() -> float:
	return JiggleSpring.params_from_frequency(frequency, zeta_left).x


func _base_position(index: int) -> Vector3:
	if solo:
		return Vector3(0.0, BASE_HEIGHT, 0.0)
	return Vector3((float(index) - 1.0) * SPACING, BASE_HEIGHT, 0.0)


func _sync_springs() -> void:
	var zetas: Array[float] = [zeta_left, zeta_middle, zeta_right]
	for i in _springs.size():
		var spring := _springs[i]
		spring.configure(frequency, zetas[i])
		spring.integrator = integrator
		spring.gravity = Vector3.DOWN * 9.8 if gravity_enabled else Vector3.ZERO
		spring.max_distance = max_distance
