class_name ShaderWorld
extends JiggleStage
## 챕터 5 월드 — 본 기반(왼쪽) vs 정점 셰이더(오른쪽, 본 0개).
## 원본 demos/08_shader_jiggle/shader_jiggle_demo.gd 이식.
## 오른쪽 몸은 스킨이 떼어져 있어 본이 움직여도 변형되지 않는다 —
## 셰이더가 화면에 그려지는 정점만 민다.

const SLOT_X := 0.34
const MARKER_RADIUS := 0.022

## 정점 셰이더 흔들림. COLOR.a 에 JiggleBody 가 구워 둔 Jiggle 가중치가 들어 있다.
const JIGGLE_SHADER := """
shader_type spatial;

uniform vec3 skin_color : source_color = vec3(0.84, 0.66, 0.58);
uniform vec3 jiggle_offset = vec3(0.0);
uniform float wobble_amplitude = 0.0;
uniform float wobble_frequency = 2.0;
uniform float weight_view = 0.0;

void vertex() {
	float weight = COLOR.a;

	// ① 유니폼 구동: CPU가 스프링 하나로 만든 오프셋을 가중치만큼 분배한다.
	vec3 offset = jiggle_offset * weight;

	// ② 시간 기반: 정점 위치로 위상을 흩어 파도를 만든다.
	float phase = VERTEX.x * 9.0 + VERTEX.y * 6.0 + VERTEX.z * 4.0;
	offset += vec3(
		sin(TIME * wobble_frequency + phase),
		sin(TIME * wobble_frequency * 1.3 + phase * 1.7),
		cos(TIME * wobble_frequency * 0.8 + phase)
	) * wobble_amplitude * weight;

	VERTEX += offset;
}

void fragment() {
	ALBEDO = mix(skin_color, COLOR.rgb, weight_view);
	ROUGHNESS = 0.55;
}
"""

var frequency := 2.4
var damping_ratio := 0.22
var gravity := 3.0
var max_angle_degrees := 26.0

## CPU 스프링 하나가 만든 오프셋을 정점 가중치만큼 분배한다. 몸의 움직임에 반응한다.
var uniform_gain := 1.0
## 시간만으로 만드는 출렁임. 상태가 없어서 가장 싸지만 몸이 뭘 하든 똑같이 움직인다.
var wobble_amplitude := 0.0
var wobble_frequency := 2.0

var show_weights := false
var show_markers := true

var _bone_body: JiggleBody
var _shader_body: JiggleBody
var _modifiers: Array[JiggleBoneModifier3D] = []
var _material := ShaderMaterial.new()
var _spring := JiggleSpring.new()
var _bone_marker: BoneAttachment3D
var _shader_marker: BoneAttachment3D
var _anchor_local := Vector3.ZERO
var _initialized := false


func _build() -> void:
	stimulus.kind = Stimulus.Kind.WALK

	# --- 왼쪽: 챕터 2와 같은 본 기반 ---
	_bone_body = JiggleBody.new()
	_bone_body.name = "BoneBody"
	add_child(_bone_body)
	_bone_body.build(false)
	_add_modifier(JiggleBody.BREAST_L, JiggleBoneModifier3D.TipAxis.Z, 0.075)
	_add_modifier(JiggleBody.BREAST_R, JiggleBoneModifier3D.TipAxis.Z, 0.075)
	_add_modifier(JiggleBody.GLUTE_L, JiggleBoneModifier3D.TipAxis.NEG_Z, 0.080)
	_add_modifier(JiggleBody.GLUTE_R, JiggleBoneModifier3D.TipAxis.NEG_Z, 0.080)

	# --- 오른쪽: 스킨을 떼고 셰이더만 ---
	_shader_body = JiggleBody.new()
	_shader_body.name = "ShaderBody"
	add_child(_shader_body)
	_shader_body.build(false)
	_shader_body.detach_skin()

	var shader := Shader.new()
	shader.code = JIGGLE_SHADER
	_material.shader = shader
	_material.set_shader_parameter("skin_color", JiggleBody.SKIN_COLOR)
	_shader_body.mesh_instance.material_override = _material

	# 가슴 본에 붙인 마커. 왼쪽은 따라 움직이고 오른쪽은 가만히 있는다.
	_bone_marker = _add_marker(_bone_body, Color(1.0, 0.55, 0.25))
	_shader_marker = _add_marker(_shader_body, Color(0.35, 0.65, 1.0))

	# 셰이더를 구동할 스프링 하나. 가슴 본 위치를 기준점으로 쓴다.
	_anchor_local = _bone_body.bone_rest_position(_bone_body.bone(JiggleBody.BREAST_L))


func apply() -> void:
	_bone_body.set_weight_view(show_weights)
	for modifier in _modifiers:
		modifier.frequency = frequency
		modifier.damping_ratio = damping_ratio
		modifier.gravity = gravity
		modifier.max_angle_degrees = max_angle_degrees


func reset_world() -> void:
	stimulus.reset()
	_initialized = false
	if _bone_body == null:
		return
	for body: JiggleBody in [_bone_body, _shader_body]:
		body.transform = Transform3D.IDENTITY
		body.reset_pose()
	for modifier in _modifiers:
		modifier.reset_simulation()


func _frame_update(delta: float) -> void:
	var basis := Basis.from_euler(stimulus.euler)
	_bone_body.transform = Transform3D(basis, stimulus.offset + Vector3(-SLOT_X, 0.0, 0.0))
	_shader_body.transform = Transform3D(basis, stimulus.offset + Vector3(SLOT_X, 0.0, 0.0))
	_bone_marker.visible = show_markers
	_shader_marker.visible = show_markers

	# CPU 스프링 하나로 "몸이 움직여서 생기는 관성"을 만든다.
	# 챕터 2와 완전히 같은 원리인데, 결과를 본 회전이 아니라 셰이더 유니폼으로 보낸다.
	var target := _shader_body.global_transform * _anchor_local
	if not _initialized:
		_spring.reset_to(target)
		_initialized = true
	var kc := JiggleSpring.params_from_frequency(frequency, damping_ratio)
	_spring.stiffness = Vector3.ONE * kc.x
	_spring.damping = Vector3.ONE * kc.y
	_spring.gravity = Vector3.DOWN * gravity
	_spring.max_distance = 0.12
	_spring.step(delta, target)

	# 월드 오프셋을 모델 공간으로 되돌린다. 셰이더의 VERTEX 는 모델 공간이기 때문.
	var world_offset := (_spring.position - target) * uniform_gain
	var local_offset := _shader_body.global_transform.basis.inverse() * world_offset
	_material.set_shader_parameter("jiggle_offset", local_offset)
	_material.set_shader_parameter("wobble_amplitude", wobble_amplitude)
	_material.set_shader_parameter("wobble_frequency", wobble_frequency)
	_material.set_shader_parameter("weight_view", 1.0 if show_weights else 0.0)


func _draw_debug() -> void:
	draw_grid(2.0)
	if not show_markers:
		return
	# 마커의 rest 위치. 여기서 얼마나 벗어났는지가 곧 "실제로 움직였는가"다.
	for body: JiggleBody in [_bone_body, _shader_body]:
		var rest: Vector3 = body.global_transform * (_anchor_local + Vector3(0.0, 0.0, 0.13))
		debug.sphere(rest, MARKER_RADIUS * 1.4, JiggleDebugDraw.COLOR_TARGET, 12)


## 그래프용: 두 마커가 rest 에서 벗어난 거리. 셰이더 쪽은 언제나 0이다.
func sample_plot() -> Dictionary:
	if _bone_marker == null:
		return {}
	var bone_rest: Vector3 = (
		_bone_body.global_transform * (_anchor_local + Vector3(0.0, 0.0, 0.13))
	)
	var shader_rest: Vector3 = (
		_shader_body.global_transform * (_anchor_local + Vector3(0.0, 0.0, 0.13))
	)
	return {
		"bone": _bone_marker.global_position.distance_to(bone_rest),
		"shader": _shader_marker.global_position.distance_to(shader_rest),
	}


func _add_modifier(
	bone_name: StringName, axis: JiggleBoneModifier3D.TipAxis, length: float
) -> void:
	var modifier := JiggleBoneModifier3D.new()
	modifier.name = String(bone_name) + "Jiggle"
	modifier.bone_name = String(bone_name)
	modifier.tip_axis = axis
	modifier.tip_length = length
	_bone_body.skeleton.add_child(modifier)
	_modifiers.append(modifier)


## 가슴 본에 붙는 작은 구. BoneAttachment3D 는 모디파이어 결과를 따라간다.
func _add_marker(body: JiggleBody, color: Color) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = "Marker"
	attachment.bone_name = String(JiggleBody.BREAST_L)
	body.skeleton.add_child(attachment)

	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = MARKER_RADIUS
	sphere.height = MARKER_RADIUS * 2.0
	marker.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	# 가슴 덩어리 앞쪽으로 조금 내밀어 눈에 띄게 한다.
	marker.position = Vector3(0.0, 0.0, 0.13)
	attachment.add_child(marker)
	return attachment
