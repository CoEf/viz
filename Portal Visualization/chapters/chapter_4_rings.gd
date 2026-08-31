extends PortalChapter
## 챕터 4 — 테두리 링 3겹. 원통 UV의 shear 한 줄 나선, 커브 4개 프로파일,
## 굴절+RGB 분리, 그리고 실제 라이트.

const STEPS: Array[Dictionary] = [
	{
		"title": "나선은 shear 한 줄",
		"body": """원뿔 UV는 x=둘레 각도, y=반경.
[b]uv.x += uv.y × scale[/b] — 세로에 비례해 가로를 미는 전단이
원통 UV에서는 곧 나선이다. atan도 sin도 없다.""",
		"chips": [{"icon": "shader", "text": "sample_noise()"}],
		"try": "0으로 → 나선이 세로 줄무늬로 풀린다",
	},
	{
		"title": "커브 4개가 테두리의 전부",
		"body": """CurveXYZTexture의 세 채널이 반경(UV.y) 프로파일:
[b].x 임계값, .y 발광 배율, .z 경계 부드러움[/b].
안쪽 링은 좁은 띠, 바깥 링은 넓은 안개 — 커브 모양 차이다.""",
		"chips": [{"icon": "resource", "text": "CurveXYZTexture noise_edge"}],
		"code": """ALPHA = smoothstep(0., edge.z,
    max(0., edge.x - n)) * alpha_curve;
EMISSION = ALBEDO * edge.y * ...;""",
		"try": "안쪽만 / 바깥만 토글로 두 성격을 비교",
	},
	{
		"title": "굴절과 RGB 분리",
		"body": """소용돌이 노이즈로 SCREEN_UV를 왜곡하고,
R·G·B를 [b]각각 다른 방향으로[/b] 밀어 색수차를 만든다.
반경(UV.y)에 비례시켜 가장자리로 갈수록 심해진다.""",
		"chips": [{"icon": "shader", "text": "portal_deformation.gdshader"}],
		"try": "분리 배율을 키우면 → 무지갯빛 테두리가 넓어진다",
	},
	{
		"title": "발광 이펙트에는 진짜 라이트",
		"body": """포탈이 스스로 빛나는 것과, 그 빛이 [b]벽과 바닥에
실제로 떨어지는 것[/b]은 전혀 다른 인상이다.
SpotLight3D 하나(90°, 보랏빛)가 설득력을 만든다.""",
		"chips": [{"icon": "node3d", "text": "SpotLight3D energy 5"}],
		"try": "라이트를 끄면 → 주변이 죽고 스티커처럼 보인다",
	},
]

var _swirl := 0.6
var _split := 1.0
var _refract := 0.025
var _show_inner := true
var _show_outer := true


func _ready() -> void:
	world.frame_portal()
	world.camera_rig.set_view(0.3, -0.1, 5.0)


func get_chapter_title() -> String:
	return "테두리 링 — 나선·커브·색수차"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_ring_visible(true, true, true, true)
	world.set_spotlight_enabled(true)
	world.inner_edge_material().set_shader_parameter("swirl_scale", 0.6)
	world.deform_material().set_shader_parameter("refract_strength", 0.025)
	world.deform_material().set_shader_parameter("rgb_split_scale", 1.0)
	match index:
		0:
			world.inner_edge_material().set_shader_parameter("swirl_scale", _swirl)
			update_code(_swirl_code())
		1:
			world.set_ring_visible(true, _show_outer, _show_inner, true)
		2:
			world.deform_material().set_shader_parameter("refract_strength", _refract)
			world.deform_material().set_shader_parameter("rgb_split_scale", _split)
			update_code(_split_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "swirl_scale (안쪽 링)", 0.0, 1.2, _swirl, _on_swirl_changed, [0])
	add_toggle(parent, "안쪽 링 (좁은 띠)", _show_inner, _on_inner_toggled, [1])
	add_toggle(parent, "바깥 링 (넓은 안개)", _show_outer, _on_outer_toggled, [1])
	add_slider(parent, "굴절 강도", 0.0, 0.1, _refract, _on_refract_changed, [2])
	add_slider(parent, "RGB 분리 배율", 0.0, 4.0, _split, _on_split_changed, [2])
	add_toggle(parent, "SpotLight3D", true, _on_light_toggled, [3])


func _on_swirl_changed(value: float) -> void:
	_swirl = value
	world.inner_edge_material().set_shader_parameter("swirl_scale", value)
	if current_step == 0:
		update_code(_swirl_code())


func _on_inner_toggled(pressed: bool) -> void:
	_show_inner = pressed
	if current_step == 1:
		world.set_ring_visible(true, _show_outer, _show_inner, true)


func _on_outer_toggled(pressed: bool) -> void:
	_show_outer = pressed
	if current_step == 1:
		world.set_ring_visible(true, _show_outer, _show_inner, true)


func _on_refract_changed(value: float) -> void:
	_refract = value
	world.deform_material().set_shader_parameter("refract_strength", value)


func _on_split_changed(value: float) -> void:
	_split = value
	world.deform_material().set_shader_parameter("rgb_split_scale", value)
	if current_step == 2:
		update_code(_split_code())


func _on_light_toggled(pressed: bool) -> void:
	if current_step == 3:
		world.set_spotlight_enabled(pressed)


func _swirl_code() -> String:
	return ("uv.x += uv.y * %.2f; ← 슬라이더\n" % _swirl
			+ "// 원통 UV에서는 전단 = 나선")


func _split_code() -> String:
	return ("r = tex(screen, uv + R * %.1f * fade)\n" % _split
			+ "// R·G·B 세 방향으로 ← 슬라이더")
