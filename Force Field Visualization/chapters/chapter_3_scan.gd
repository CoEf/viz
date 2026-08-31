extends FFChapter
## 챕터 3 — 스캔 밴드와 파편. 마지막 겹 둘과 합성식.

const STEPS: Array[Dictionary] = [
	{
		"title": "스캔 줄무늬",
		"body": """step(sin((UV.y + TIME)·8PI)) —
[b]가로 줄무늬가 천천히 흘러내린다[/b].
EMISSION에 0.4, ALPHA에 0.1만 보태는 미세한 겹.""",
		"chips": [{"icon": "shader", "text": "wave band"}],
		"code": """wave = step(sin((UV.y + TIME*0.04)
    * 8.0 * PI), 0.0);""",
		"try": "끄고 켜 보라 — 없으면 막이 정지해 보인다",
	},
	{
		"title": "합성식 읽기",
		"body": """EMISSION = 바탕색×2 + min(1, 항들의 합)×f,
ALPHA = clamp(항들의 합 + [b]0.02[/b])×f —
0.02가 아무 레이어도 없는 곳의 최소 존재감이다.""",
		"chips": [{"icon": "shader", "text": "EMISSION / ALPHA 합성"}],
		"code": """ALPHA = clamp(edge + fill*.4 + 0.02
    + wave*.1 + hex_edge, 0, 1) * f;""",
	},
	{
		"title": "떠다니는 파편",
		"body": """삼각형 메시 32개 — 위로 뜨는 중력, 강한 감쇠,
Y 회전, EMISSION 2.0. [b]막 주변의 에너지 부스러기[/b]가
정지한 구에 생동감을 준다.""",
		"chips": [{"icon": "node3d", "text": "GPUParticles3D + triangle_mesh"}],
		"try": "파편을 끄면 → 막이 박제처럼 굳는다",
	},
]

var _wave_on := true
var _debris := true


func _ready() -> void:
	world.reset_params()


func get_chapter_title() -> String:
	return "스캔과 파편 — 마무리 겹"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_params()
	world.set_debris_visible(index == 2 and _debris or index != 2)
	match index:
		0:
			world.set_layers(true, true, true, _wave_on)
		2:
			world.set_debris_visible(_debris)


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "스캔 밴드", _wave_on, _on_wave_toggled, [0])
	add_toggle(parent, "파편 파티클", _debris, _on_debris_toggled, [2])


func _on_wave_toggled(pressed: bool) -> void:
	_wave_on = pressed
	if current_step == 0:
		world.set_param("show_wave", 1.0 if pressed else 0.0)


func _on_debris_toggled(pressed: bool) -> void:
	_debris = pressed
	if current_step == 2:
		world.set_debris_visible(pressed)
