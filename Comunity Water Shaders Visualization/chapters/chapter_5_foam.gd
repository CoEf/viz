extends WaterChapter
## 챕터 5 — 포말 축. 경계선을 그리는 네 가지 방법. 뒤로 갈수록 셰이더 바깥에서
## 값을 받아온다.

const STEPS: Array[Dictionary] = [
	{
		"title": "원 일흔다섯 개를 코드에 박아 두기",
		"body": """11번은 텍스처가 [b]한 장도 없다.[/b]
포말 무늬가 소스에 좌표로 박힌 원 75개다.
프래그먼트마다 그 목록을 두 번 훑는다 —
가벼워 보여도 픽셀당 150번의 거리 계산이다.""",
		"chips": [{"icon": "shader", "text": "11_wind_waker_water waterlayer()"}],
		"code": """ret += circ(uv, vec2(0.373,0.277), 0.0268);
ret += circ(uv, vec2(0.031,0.540), 0.0193);
// 이런 줄이 75개 더 있다""",
		"try": "무늬가 UV 타일마다 정확히 똑같이 반복된다",
	},
	{
		"title": "위에서 내려본 마스크를 물려주기",
		"body": """1번은 포말을 스스로 못 만든다. [b]밖에서 받아야[/b] 한다.
FOAM_LAYER만 보는 직교 카메라가 무대를 한 번 더 그리면
검은 배경 위 흰 원반 — 오른쪽 패널 그림이 그 결과다.
그걸 foam_mask 샘플러에 그대로 물린다.""",
		"chips": [
			{"icon": "node3d", "text": "SubViewport → Camera3D 직교"},
			{"icon": "texture", "text": "foam_mask"},
		],
		"code": """cam.projection = PROJECTION_ORTHOGONAL
cam.cull_mask = 1 << (FOAM_LAYER - 1)
mat.set_shader_parameter("foam_mask", tex)""",
		"try": "프로브가 도는 자리와 패널 그림의 흰 점을 맞춰보기",
	},
	{
		"title": "프로브 위치를 유니폼으로 밀어 넣기",
		"body": """5번은 파문의 중심을 [b]uniform vec3로 받는다.[/b]
셰이더는 그 좌표에서의 거리로 링을 그릴 뿐이고,
매 프레임 값을 넣어주는 건 GDScript 쪽 일이다.
안 넣으면 파문이 원점에 붙박이로 선다.""",
		"chips": [
			{"icon": "shader", "text": "uniform vec3 boat_position"},
			{"icon": "script", "text": "water_plot.gd advance()"},
		],
		"code": """material.set_shader_parameter(
    "boat_position", probe.global_position)""",
		"try": "링의 중심이 주황 프로브를 따라다닌다",
	},
	{
		"title": "전역 셰이더 파라미터로 흘려보내기",
		"body": """10번은 유니폼이 아니라 [b]global uniform[/b]으로 받는다.
프로젝트 설정에 등록해 두면 어느 셰이더든 같은 값을 본다.
등록을 빼먹으면 에러 없이 [b]0이 들어온다.[/b]""",
		"chips": [
			{"icon": "setting", "text": "project.godot [shader_globals]"},
			{"icon": "shader", "text": "global uniform vec3 player_position"},
		],
		"code": """RenderingServer.global_shader_parameter_set(
    &"player_position", probe.global_position)""",
		"try": "영향 반경 슬라이더 — 프로브 둘레의 파문이 넓어진다",
	},
]

var _breakup := 0.8
var _influence := 4.0
var _mask_view: TextureRect


func get_chapter_title() -> String:
	return "포말 — 경계선을 어떻게 그리는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "링 찢김 (breakup_strength)", 0.0, 1.5, _breakup, _on_breakup, [2])
	add_slider(parent, "영향 반경 (influence_size)", 0.1, 4.0, _influence, _on_influence, [3])

	_mask_view = TextureRect.new()
	_mask_view.custom_minimum_size = Vector2(0.0, 230.0)
	_mask_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(_mask_view)
	bind_steps([_mask_view], [1])


func apply_step(index: int) -> void:
	world.set_dive(false)
	world.set_canvas(null)
	world.set_postfx(null)
	world.set_overlay(null)
	match index:
		0:
			world.show_plots([11])
		1:
			world.show_plots([1])
		2:
			world.show_plots([{"id": 5, "params": {"breakup_strength": _breakup}}])
		_:
			world.show_plots([{"id": 10, "params": {"influence_size": _influence}}])
	world.frame(0.25, -0.52, 0.98)
	# 마스크는 살아 있는 뷰포트 텍스처라, 붙여만 두면 매 프레임 갱신된다.
	# 보이고 숨는 건 bind_steps가 맡는다.
	if _mask_view != null and index == 1:
		_mask_view.texture = world.foam_texture()
	_push_code()


func _on_breakup(value: float) -> void:
	_breakup = value
	if current_step == 2:
		world.set_param(0, "breakup_strength", value)


func _on_influence(value: float) -> void:
	_influence = value
	if current_step == 3:
		world.set_param(0, "influence_size", value)
	_push_code()


func _push_code() -> void:
	if current_step == 3:
		update_code("""RenderingServer.global_shader_parameter_set(
    &"player_position", probe.global_position)
// 셰이더: influence_size = %.2f   <- 슬라이더""" % _influence)
