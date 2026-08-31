extends FurChapter
## 챕터 3 — 테이퍼와 빗질. 밀어내기만으로는 양파고,
## "층마다 다른 알파 문턱"이 붙어야 털이 된다.

const STEPS: Array[Dictionary] = [
	{
		"title": "층마다 문턱을 올리기",
		"body": """살아남는 조건: [b]strand ≥ 0.5 / (1 − 셸 깊이)[/b].
안쪽 셸은 0.52, 가장 바깥은 정확히 1.0 —
보로노이 셀 정중앙만 남는다. 그게 털 한 올의 끝이다.""",
		"chips": [
			{"icon": "shader", "text": "ALPHA = curve(strand·(1-R)).y"},
			{"icon": "texture", "text": "Cellular invert 노이즈"},
		],
		"try": "테이퍼 0으로 → 문턱이 같아져 양파로 돌아간다",
	},
	{
		"title": "0.5에서 멈추는 이유",
		"body": """셸 깊이 R은 percent × 0.5 — [b]1.0이 아니라 0.5에서 끝난다[/b].
R이 1.0까지 갔다면 (1−R)이 0이 되어
가장 바깥 셸이 통째로 사라진다.""",
		"chips": [{"icon": "script", "text": "percent * 0.5"}],
		"code": """set_vertex_color(v_idx,
    Color(percent * 0.5, g, 0.0))""",
		"try": "strand 노이즈 보기 → 셀 중심이 흰(=살아남는) 곳",
	},
	{
		"title": "플로우맵으로 빗질하기",
		"body": """노이즈 좌표를 플로우맵으로 밀되 [b]COLOR.r을 곱한다[/b] —
바깥 셸일수록 많이 밀려 층이 어긋나고, 털이 눕는다.
결은 fur_flowmap.png에 그림으로 칠한다.""",
		"chips": [{"icon": "texture", "text": "fur_flowmap.png"}],
		"try": "세기를 키우면 → 털이 한 방향으로 눕는다",
	},
]

var _taper := 1.0
var _flow := 0.2
var _show_strand := false


func _ready() -> void:
	world.reset_fur_params()


func get_chapter_title() -> String:
	return "테이퍼 — 양파가 털이 되는 수학"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_fur_params()
	match index:
		0:
			world.set_fur_param("taper", _taper)
			update_code(_taper_code())
		1:
			world.set_fur_param("debug_mode", 3 if _show_strand else 0)
		2:
			world.set_fur_param("flow_strength", _flow)
			update_code(_flow_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "테이퍼 (1=원본, 0=양파)", 0.0, 1.0, _taper, _on_taper_changed, [0])
	add_toggle(parent, "strand 노이즈 보기", _show_strand, _on_strand_toggled, [1])
	add_slider(parent, "빗질 세기 (원본 0.2)", 0.0, 1.0, _flow, _on_flow_changed, [2])


func _on_taper_changed(value: float) -> void:
	_taper = value
	world.set_fur_param("taper", value)
	if current_step == 0:
		update_code(_taper_code())


func _on_strand_toggled(pressed: bool) -> void:
	_show_strand = pressed
	if current_step == 1:
		world.set_fur_param("debug_mode", 3 if pressed else 0)


func _on_flow_changed(value: float) -> void:
	_flow = value
	world.set_fur_param("flow_strength", value)
	if current_step == 2:
		update_code(_flow_code())


func _taper_code() -> String:
	return ("ALPHA = curve(strand\n"
			+ "    * (1.0 - R * %.2f)).y; ← 슬라이더" % _taper)


func _flow_code() -> String:
	return ("strand = tex(noise, UV*10.\n"
			+ "    - flow * %.2f); ← 슬라이더" % _flow)
