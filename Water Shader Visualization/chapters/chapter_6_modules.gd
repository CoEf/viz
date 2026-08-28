extends WaterChapter
## 챕터 6 — 모듈 스위치 아키텍처. 이 프로젝트의 진짜 결론.
## 앞선 챕터가 "레이어가 뭐냐"였다면 여기는 "그걸 어떻게 조립하냐"다.

const STEPS: Array[Dictionary] = [
	{
		"title": "본문 하나에 스위치만 다르게 두기",
		"body": """프리셋 셰이더 파일은 [b]10줄도 안 된다.[/b]
계산은 전부 공용 본문에 있고,
각 파일은 어느 모듈을 켤지만 정한다.""",
		"chips": [
			{"icon": "shader", "text": "water_surface.gdshader"},
			{"icon": "shader", "text": "wt_surface_body.gdshaderinc"},
		],
		"code": """#define WAVE_GERSTNER
#define REFRACTION
#include "res://water/inc/wt_surface_body..." """,
		"try": "지금 화면이 Realistic 프리셋",
	},
	{
		"title": "스위치를 바꿔 Toon으로 갈아 끼우기",
		"body": """같은 본문, 다른 조합이다.
굴절을 빼고 STYLE_TOON을 켜면
[b]수심이 연속에서 3단 계단[/b]으로 바뀐다.""",
		"chips": [{"icon": "shader", "text": "water_toon.gdshader"}],
		"code": """#define STYLE_TOON
#define STYLE_OUTLINE
// REFRACTION 없음""",
		"try": "아래 토글로 두 프리셋을 오가기",
	},
	{
		"title": "런타임이 아니라 컴파일 타임에 자르기",
		"body": """`if (use_foam)` 같은 유니폼 분기를 쓰면
[b]안 쓰는 계산도 GPU에 실린다.[/b]
`#ifdef`는 명령어 자체가 안 들어간다.
프리셋마다 필요한 만큼만 무거운 셰이더가 나온다.""",
		"chips": [{"icon": "setting", "text": "전처리기 #ifdef"}],
		"code": """#ifdef REFRACTION
    // 이 블록은 꺼지면 컴파일조차 안 된다
#endif""",
		"try": "토글을 오가면 셰이더가 다시 컴파일된다",
	},
	{
		"title": "같은 뼈대로 다른 물 만들기",
		"body": """이 프로젝트가 노린 것: 물마다 셰이더를 새로 짜지 않는 것.

[b]강[/b] — FLOW + FLOW_NOISE 추가
[b]온천[/b] — DOMAIN_POLAR로 좌표계만 교체
[b]픽셀[/b] — STYLE_PIXELATE 하나 추가

L0(좌표계)만 바꿔도 완전히 다른 물이 된다는 게 핵심이다.""",
		"chips": [
			{"icon": "shader", "text": "water_river.gdshader"},
			{"icon": "shader", "text": "water_hotspring.gdshader"},
		],
		"try": "각 프리셋 전용 씬은 원본 프로젝트의 scenes/ 에 있다",
	},
]

var _toon := false
var _toggle: CheckButton


func get_chapter_title() -> String:
	return "모듈로 조립하기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	# 스텝 1은 "갈아 끼운다"가 요점이므로 들어가자마자 Toon을 보여준다.
	# 이후에는 토글이 상태를 쥔다. 토글 UI도 같이 맞춰 줘야 어긋나지 않는다.
	if index == 0:
		_toon = false
	elif index == 1:
		_toon = true
	if _toggle != null and _toggle.button_pressed != _toon:
		_toggle.set_pressed_no_signal(_toon)
	world.set_toon(_toon if index >= 1 else false)
	world.reset_layers()
	world.camera_rig.set_view(2.95, -0.32, 30.0)


func build_panel(parent: VBoxContainer) -> void:
	# 스텝 0은 Toon을 끈 기준 화면으로 고정한다 — 토글은 스텝 1부터 의미가 있다.
	_toggle = add_toggle(parent, "Toon 프리셋으로 전환", _toon, _on_toon_toggled, [1, 2, 3])
	add_caption(parent, "같은 본문 · 다른 #define 조합", [1, 2, 3])


func _on_toon_toggled(toon: bool) -> void:
	_toon = toon
	if current_step >= 1:
		world.set_toon(toon)
		world.reset_layers()
