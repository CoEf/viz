class_name ChainWorld
extends JiggleStage
## 챕터 3 월드 — 머리 + 머리카락 다발 리그 + JiggleChainModifier3D.
## 원본 demos/03_bone_chain/bone_chain_demo.gd 이식.
##
## 화면에 세 가지가 겹쳐 보인다.
## 초록 선 = rest 사슬 · 노랑 십자 = Verlet 파티클 · 흰 선 = 본이 만든 실제 사슬.
## 노랑과 흰 선이 어긋나는 정도가 곧 "제약이 얼마나 덜 풀렸는가"다.

const COLOR_CONTACT := Color(1.0, 0.25, 0.35)
const STRAND_COUNT := 8
const SEGMENT_COUNT := 6
const SEGMENT_LENGTH := 0.055

var iterations := 6
var constraint_stiffness := 1.0
var drag := 0.03
var gravity := 9.0
var restore_frequency := 0.9
var angle_limit_degrees := 35.0
var collision_enabled := true
var collision_response := JiggleVerletBody.CollisionResponse.STABLE
var collision_friction := 0.2

var show_bone_colors := false
var show_particles := true
var show_colliders := true

var rig: HairRig
var _modifiers: Array[JiggleChainModifier3D] = []
var _no_colliders: Array[JiggleVerletBody.Collider] = []


func _build() -> void:
	stimulus.kind = Stimulus.Kind.TWIST

	rig = HairRig.new()
	rig.name = "HairRig"
	add_child(rig)
	rig.build(STRAND_COUNT, SEGMENT_COUNT, SEGMENT_LENGTH)

	# 다발 하나에 모디파이어 하나. 모디파이어는 Skeleton3D 의 직속 자식이어야 한다.
	for strand in rig.strands:
		var modifier := JiggleChainModifier3D.new()
		modifier.name = "Chain_%s" % strand["root"]
		modifier.root_bone_name = String(strand["root"])
		modifier.end_bone_name = String(strand["end"])
		modifier.tip_axis = strand["tip_axis"]
		modifier.tip_length = strand["tip_length"]
		rig.skeleton.add_child(modifier)
		_modifiers.append(modifier)


func apply() -> void:
	rig.set_bone_color_view(show_bone_colors)
	# 복원력도 결국 챕터 1의 스프링이다. 진동수를 강성으로 환산해 넘긴다.
	var restore := 0.0
	if restore_frequency > 0.0:
		restore = JiggleSpring.params_from_frequency(restore_frequency, 1.0).x
	for modifier in _modifiers:
		var chain := modifier.chain
		chain.iterations = iterations
		chain.constraint_stiffness = constraint_stiffness
		chain.drag = drag
		chain.gravity = Vector3.DOWN * gravity
		chain.restore_stiffness = restore
		chain.angle_limit = deg_to_rad(angle_limit_degrees)
		chain.collision_response = collision_response
		chain.collision_friction = collision_friction
		chain.colliders = rig.colliders if collision_enabled else _no_colliders


func reset_world() -> void:
	stimulus.reset()
	if rig == null:
		return
	rig.transform = Transform3D.IDENTITY
	rig.refresh_colliders()
	rig.reset_pose()
	for modifier in _modifiers:
		modifier.reset_simulation()


func _frame_update(_delta: float) -> void:
	# 자극은 머리 전체를 움직인다. 머리카락은 관성 때문에 뒤처지면서 흔들린다.
	rig.transform = Transform3D(Basis.from_euler(stimulus.euler), stimulus.offset)
	# 충돌체도 같이 움직여야 머리카락이 머리를 통과하지 않는다.
	rig.refresh_colliders()


func _draw_debug() -> void:
	draw_grid(2.0)
	if show_colliders:
		for collider in rig.colliders:
			debug.capsule(
				collider.point_a, collider.point_b, collider.radius, Color(0.35, 0.75, 1.0, 0.22)
			)
	for modifier in _modifiers:
		# 실제로 본이 만들어 낸 사슬. 길이는 항상 rest 그대로다.
		debug.polyline(modifier.reconstructed, Color(1.0, 1.0, 1.0, 0.5))
		if not show_particles:
			continue
		debug.polyline(modifier.rest_points, JiggleDebugDraw.COLOR_TARGET)
		var chain := modifier.chain
		for i in chain.positions.size():
			var normal: Vector3 = chain.contact_normals[i]
			if normal.length_squared() < 0.000001:
				debug.cross_mark(chain.positions[i], 0.011, JiggleDebugDraw.COLOR_ACTUAL)
				continue
			# 지금 충돌 중인 입자. 어느 가닥이 표면에 끌리고 있는지 한눈에 보인다.
			debug.sphere(chain.positions[i], 0.016, COLOR_CONTACT, 10)
			debug.arrow(chain.positions[i], normal.normalized() * 0.05, COLOR_CONTACT)


## 가운데 다발의 총 길이 오차(m). "반복 횟수 = 뻣뻣함"을 숫자로 보여 준다.
func length_error() -> float:
	if _modifiers.is_empty():
		return 0.0
	return _modifiers[_modifiers.size() / 2].chain.length_error()


## 안전장치가 되돌린 횟수 합계. 0이 아니면 지금 폭주가 일어나고 있다는 뜻.
func safety_resets() -> int:
	var total := 0
	for modifier in _modifiers:
		total += modifier.chain.safety_resets
	return total


## 그래프용: 끝점 좌우 변위 + 길이 오차(cm).
func sample_plot() -> Dictionary:
	if _modifiers.is_empty():
		return {}
	var chain := _modifiers[_modifiers.size() / 2].chain
	var tip := chain.positions.size() - 1
	if tip < 0 or chain.rest_positions.size() <= tip:
		return {}
	return {
		"tip": chain.positions[tip].x - chain.rest_positions[tip].x,
		"stretch": chain.length_error() * 100.0,
	}
