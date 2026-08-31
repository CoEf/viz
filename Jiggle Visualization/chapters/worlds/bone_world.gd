class_name BoneWorld
extends JiggleStage
## 챕터 2 월드 — 코드로 조립한 스킨드 몸 + JiggleBoneModifier3D 4개.
## 원본 demos/02_jiggle_bone/jiggle_bone_demo.gd 이식.
## 파란 반투명 몸(고스트)이 "흔들림이 없었다면 있었을 자세"다.

var frequency := 2.4
var damping_ratio := 0.22
var vertical_ratio := 1.0
var horizontal_ratio := 0.7
var gravity := 3.0
var motion_inherit := 0.0
var max_angle_degrees := 26.0
var keep_length := true
var squash := 0.25

var show_ghost := true
var show_weights := false
var show_gizmos := true
var jiggle_enabled := true

var body: JiggleBody
var _ghost: JiggleBody
var _modifiers: Array[JiggleBoneModifier3D] = []


func _build() -> void:
	stimulus.kind = Stimulus.Kind.WALK

	# 고스트를 먼저 넣어 실제 몸이 위에 그려지도록 한다.
	_ghost = JiggleBody.new()
	add_child(_ghost)
	_ghost.build(true)

	body = JiggleBody.new()
	add_child(body)
	body.build(false)

	# 모디파이어는 반드시 Skeleton3D 의 직속 자식이어야 한다.
	_modifiers.append(_add_modifier(JiggleBody.BREAST_L, JiggleBoneModifier3D.TipAxis.Z, 0.075))
	_modifiers.append(_add_modifier(JiggleBody.BREAST_R, JiggleBoneModifier3D.TipAxis.Z, 0.075))
	_modifiers.append(_add_modifier(JiggleBody.GLUTE_L, JiggleBoneModifier3D.TipAxis.NEG_Z, 0.080))
	_modifiers.append(_add_modifier(JiggleBody.GLUTE_R, JiggleBoneModifier3D.TipAxis.NEG_Z, 0.080))


func apply() -> void:
	stimulus.amount = 1.0
	_ghost.visible = show_ghost
	body.set_weight_view(show_weights)
	for modifier in _modifiers:
		modifier.frequency = frequency
		modifier.damping_ratio = damping_ratio
		modifier.vertical_ratio = vertical_ratio
		modifier.horizontal_ratio = horizontal_ratio
		modifier.gravity = gravity
		modifier.motion_inherit = motion_inherit
		modifier.max_angle_degrees = max_angle_degrees
		modifier.keep_length = keep_length
		modifier.squash = squash
		modifier.active = jiggle_enabled
	if not jiggle_enabled:
		# 모디파이어를 끄면 마지막 포즈가 그대로 남는다. 직접 되돌려 줘야 한다.
		body.reset_pose()


func reset_world() -> void:
	stimulus.reset()
	for modifier in _modifiers:
		modifier.reset_simulation()
	if body != null:
		body.reset_pose()
		body.transform = Transform3D.IDENTITY
		_ghost.transform = Transform3D.IDENTITY


func _frame_update(_delta: float) -> void:
	# 자극은 캐릭터 전체를 움직인다. 본을 직접 흔드는 게 아니다.
	# 흔들림은 그 이동을 파티클이 못 따라가면서 저절로 생긴다.
	var transform := Transform3D(Basis.from_euler(stimulus.euler), stimulus.offset)
	body.transform = transform
	_ghost.transform = transform


func _draw_debug() -> void:
	draw_grid(2.0)
	if not show_gizmos or not jiggle_enabled:
		return
	for modifier in _modifiers:
		# 본 자체(원점 → 파티클). 이 선이 곧 회전 결과다.
		debug.line(modifier.bone_origin, modifier.particle_position, Color(1.0, 1.0, 1.0, 0.95))
		debug.cross_mark(modifier.bone_origin, 0.018, Color(1.0, 1.0, 1.0, 0.95))
		debug.spring_gizmo(
			modifier.target_position,
			modifier.particle_position,
			modifier.particle_velocity,
			0.030,
			modifier.limit_radius
		)


## 그래프용: 가슴/엉덩이 파티클의 목표 대비 상하 변위.
func sample_plot() -> Dictionary:
	if _modifiers.is_empty():
		return {}
	var breast := _modifiers[0]
	var glute := _modifiers[2]
	return {
		"breast": breast.particle_position.y - breast.target_position.y,
		"glute": glute.particle_position.y - glute.target_position.y,
	}


func _add_modifier(
	bone_name: StringName, axis: JiggleBoneModifier3D.TipAxis, length: float
) -> JiggleBoneModifier3D:
	var modifier := JiggleBoneModifier3D.new()
	modifier.name = String(bone_name) + "Jiggle"
	modifier.bone_name = String(bone_name)
	modifier.tip_axis = axis
	modifier.tip_length = length
	body.skeleton.add_child(modifier)
	return modifier
