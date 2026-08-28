extends SnowChapter
## 챕터 2 — 눈 내림. UV 원리 비교 쿼드, 노이즈 필드 화살표와 그 필드를 따라
## 휘는 낙하 궤적, 이미터 박스 기즈모로 파티클의 속을 눈으로 보여준다.

const RAW_UV_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

void vertex() {
	mat4 basis = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * basis;
}

void fragment() {
	float dist = length(UV - vec2(0.5)) * 2.0;
	ALBEDO = vec3(1.0 - dist);
}
"""

const STEPS: Array[Dictionary] = [
	{
		"title": "GPU 파티클로 눈송이 뿌리기",
		"body": """노드 하나가 눈송이 [b]2,000장[/b]을 굴린다.
계산은 CPU가 아니라 GPU가 맡는다.""",
		"chips": [
			{"icon": "node3d", "text": "GPUParticles3D"},
			{"icon": "resource", "text": "ParticleProcessMaterial"},
		],
		"code": """amount = 2000
lifetime = 9.0
preprocess = 9.0   # 켜기 전에 미리 9초 돌림""",
	},
	{
		"title": "두 번째 층으로 공기 두껍게 하기",
		"body": """같은 노드를 한 겹 더 쌓는다.
더 멀리, 더 크게, 더 흐리게.""",
		"chips": [{"icon": "node3d", "text": "GPUParticles3D ×2"}],
		"code": """# FarHaze: 두 번째 층
amount = 2600
scale_max = 2.6    # 2배 크게
color.a = 0.3      # 흐리게""",
		"try": "이전 스텝과 오가며 공기 두께 비교",
	},
	{
		"title": "텍스처 없이 눈송이 모양 만들기",
		"body": """눈송이 그림 파일은 없다.
왼쪽 = UV 중심에서 잰 거리,
오른쪽 = 그 거리를 smoothstep으로 자른 결과.""",
		"chips": [
			{"icon": "resource", "text": "QuadMesh"},
			{"icon": "shader", "text": "snowflake.gdshader"},
		],
		"code": """float dist = length(UV - vec2(0.5)) * 2.0;
float mask = smoothstep(1.0, 0.25, dist);
ALPHA = mask * COLOR.a;""",
		"try": "카메라를 돌려도 정면 — 빌보드",
	},
	{
		"title": "눈송이를 밀 노이즈 필드 깔기",
		"body": """난류는 공간에 깔린 [b]흐름 필드[/b]다.
화살표 = 그 지점의 미는 방향,
길이 = 미는 세기.""",
		"chips": [{"icon": "resource", "text": "ParticleProcessMaterial"}],
		"code": """turbulence_enabled = true
turbulence_noise_scale = 1.4   # 무늬 크기""",
		"try": "세기 슬라이더 → 화살표 길이가 변한다",
	},
	{
		"title": "필드로 낙하 경로 휘게 하기",
		"body": """눈송이가 지나는 자리의 화살표만큼
옆으로 밀린다.
노란 선 = 그렇게 그려진 낙하 궤적.""",
		"chips": [{"icon": "resource", "text": "ParticleProcessMaterial"}],
		"try": "세기를 0으로 → 궤적이 곧은 직선이 된다",
	},
	{
		"title": "이미터를 카메라 위로 옮겨 계산 아끼기",
		"body": """파란 상자 안에서만 눈이 태어난다.
상자는 카메라 위 6m를 따라다닌다(지금은 정지).
파티클은 [b]월드 공간[/b] 시뮬이라 상자가 움직여도
떨어지던 눈은 흔들리지 않는다.""",
		"chips": [
			{"icon": "script", "text": "snowfall_follower.gd"},
			{"icon": "node3d", "text": "GPUParticles3D"},
		],
		"code": """var pos := camera.global_position
global_position = Vector3(
    pos.x, pos.y + 6.0, pos.z)  # 6m 위""",
		"try": "카메라를 빼기 — 박스 밖엔 눈이 없다",
	},
]

var _turbulence := 0.6
var _demo_flake: MeshInstance3D
var _demo_raw: MeshInstance3D
var _emitter_gizmo: MeshInstance3D
var _noise_demo: NoiseFieldDemo


func _ready() -> void:
	WinterWorld.set_global_cover(0.35)
	world.set_track_maker_enabled(false)
	world.set_fall_ratio(0.7)
	world.camera_rig.set_view(0.65, -0.25, 12.0)
	_build_demo_nodes()


func get_chapter_title() -> String:
	return "눈 내리기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	var field_step := index == 3 or index == 4
	world.far_haze.visible = index == 1 or index == 2
	_demo_flake.visible = index == 2
	_demo_raw.visible = index == 2
	_noise_demo.visible = field_step
	_noise_demo.set_show_flakes(index == 4)
	_emitter_gizmo.visible = index == 5
	world.set_snowfall_enabled(not field_step)
	# 도해 스텝에서는 글로우가 얇은 화살표를 뭉개므로 잠시 끈다.
	world.environment().glow_enabled = not field_step
	world.snowfall.set_process(index != 5)
	world.camera_rig.position = Vector3(0.0, 5.0 if field_step else 1.6, 0.0)
	match index:
		2:
			world.camera_rig.set_view(0.5, -0.08, 4.5)
		3, 4:
			world.camera_rig.set_view(0.0, -0.06, 13.0)
			update_code(_turbulence_code() if index == 4 else str(STEPS[3]["code"]))
		5:
			# 상자를 정지시켜 관찰할 수 있게 고정 위치에 두고 멀리서 본다.
			world.snowfall.global_position = Vector3(0.0, 8.0, 0.0)
			world.camera_rig.set_view(0.9, -0.5, 40.0)
		_:
			world.camera_rig.set_view(0.65, -0.25, 12.0)


func build_panel(parent: VBoxContainer) -> void:
	# 스텝 3·4는 눈을 끄고 필드 도해만 띄운다 — 그때 눈 내림은 손댈 게 없다.
	add_slider(parent, "눈 내림 (강도)", 0.0, 1.0, 0.7, _on_fall_changed, [0, 1, 2, 5])
	# 난류는 파티클과 화살표 도해 양쪽에 걸려 있어 모든 스텝에서 듣는다.
	add_slider(parent, "난류 세기 (바람)", 0.0, 2.0, 0.6, _on_turbulence_changed)


func _on_fall_changed(value: float) -> void:
	world.set_fall_ratio(value)


func _on_turbulence_changed(value: float) -> void:
	_turbulence = value
	for particles: GPUParticles3D in [world.near_flakes, world.far_haze]:
		var material := particles.process_material as ParticleProcessMaterial
		material.turbulence_noise_strength = value
	_noise_demo.set_strength(value)
	if current_step == 4:
		update_code(_turbulence_code())


func _turbulence_code() -> String:
	return ("turbulence_noise_strength = %.2f\n" % _turbulence
			+ "// ← 난류 세기 슬라이더\n"
			+ "turbulence_influence_max = 0.25")


func _build_demo_nodes() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)
	var flake_material := ShaderMaterial.new()
	flake_material.shader = preload("res://snow2/shaders/snowflake.gdshader")
	# 실물 크기의 수백 배라 원래 밝기면 글로우가 형태를 다 태워 버린다.
	flake_material.set_shader_parameter("brightness", 0.7)
	_demo_flake = MeshInstance3D.new()
	_demo_flake.mesh = quad
	_demo_flake.material_override = flake_material
	_demo_flake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_demo_flake.position = Vector3(0.85, 1.9, 0.0)
	_demo_flake.visible = false
	add_child(_demo_flake)

	var raw_shader := Shader.new()
	raw_shader.code = RAW_UV_SHADER
	var raw_material := ShaderMaterial.new()
	raw_material.shader = raw_shader
	_demo_raw = MeshInstance3D.new()
	_demo_raw.mesh = quad
	_demo_raw.material_override = raw_material
	_demo_raw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_demo_raw.position = Vector3(-0.85, 1.9, 0.0)
	_demo_raw.visible = false
	add_child(_demo_raw)

	var box := BoxMesh.new()
	box.size = Vector3(32.0, 16.0, 32.0)
	var box_material := StandardMaterial3D.new()
	box_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	box_material.albedo_color = Color(0.45, 0.75, 1.0, 0.18)
	_emitter_gizmo = MeshInstance3D.new()
	_emitter_gizmo.mesh = box
	_emitter_gizmo.material_override = box_material
	_emitter_gizmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_emitter_gizmo.visible = false
	world.snowfall.add_child(_emitter_gizmo)

	_noise_demo = NoiseFieldDemo.new()
	_noise_demo.visible = false
	add_child(_noise_demo)
	_noise_demo.set_strength(_turbulence)
