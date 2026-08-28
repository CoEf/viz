extends WaterChapter
## 챕터 5 — L6 Foam. 두 출처(물체 교차, 파도 마루)를 따로 켜 본다.

const STEPS: Array[Dictionary] = [
	{
		"title": "폼 없이 보기",
		"body": """물과 물체가 만나는 선이 [b]칼로 자른 듯[/b] 날카롭다.
물이 판때기처럼 보이는 마지막 이유다.""",
		"chips": [{"icon": "shader", "text": "wt_surface_body L6"}],
		"try": "기둥 밑동과 물가를 보기",
	},
	{
		"title": "물체 교차선에 거품 두르기",
		"body": """시선 두께가 얇은 곳 = 물체가 코앞에 있는 곳.
그 띠를 하얗게 칠하면 [b]기둥마다 거품 링[/b]이 생긴다.""",
		"chips": [{"icon": "shader", "text": "foam_edge_distance"}],
		"code": """float shore_ray = 1.0 - clamp(
    thickness / foam_edge_distance, 0.0, 1.0);""",
		"try": "엣지 폼 슬라이더 → 링이 굵어진다",
	},
	{
		"title": "마루가 부서지는 곳 찾기",
		"body": """Gerstner 파는 마루에서 정점이 [b]서로 겹친다.[/b]
그 겹침 정도(야코비안)가 낮은 곳이 곧 부서지는 마루다.
파고를 재는 게 아니라 압축을 재는 게 요점.""",
		"chips": [{"icon": "shader", "text": "varying float v_jacobian"}],
		"code": """float crest = 1.0 - smoothstep(
    foam_crest_start, foam_crest_end, v_jacobian);""",
		"try": "크레스트 폼 슬라이더 → 마루만 하얘진다",
	},
	{
		"title": "폼 마스크만 보기",
		"body": """두 출처가 합쳐진 최종 마스크다.
[b]물가의 넓은 띠[/b]와 [b]파도 마루의 줄무늬[/b]가
서로 다른 계산에서 왔다는 게 보인다.""",
		"chips": [{"icon": "shader", "text": "debug_view = 3"}],
		"try": "두 슬라이더를 각각 0으로 → 어느 쪽이 사라지는지",
	},
]

var _edge := 1.6
var _crest := 1.25


func get_chapter_title() -> String:
	return "L6 — 거품 얹기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_layers()
	world.set_debug_view(3 if index == 3 else 0)
	# 엣지는 스텝 1부터, 크레스트는 스텝 2부터. 하나씩 얹어야 출처가 구분된다.
	world.set_param(&"foam_edge_distance", _edge if index >= 1 else 0.05)
	world.set_param(&"foam_shore_depth", 0.8 if index >= 1 else 0.05)
	world.set_param(&"foam_crest_gain", _crest if index >= 2 else 0.0)
	world.camera_rig.set_view(2.95, -0.38, 26.0)
	if index >= 1:
		update_code(_foam_code())


func build_panel(parent: VBoxContainer) -> void:
	# 엣지는 스텝 1부터, 크레스트는 스텝 2부터 얹힌다 — 패널도 같은 순서로 는다.
	add_slider(parent, "엣지 폼 (foam_edge_distance)", 0.05, 6.0, 1.6, _on_edge_changed, [1, 2, 3])
	add_slider(parent, "크레스트 폼 (foam_crest_gain)", 0.0, 3.0, 1.25, _on_crest_changed, [2, 3])
	add_caption(parent, "엣지는 물체가, 크레스트는 파도가 만든다", [2, 3])


func _on_edge_changed(value: float) -> void:
	_edge = value
	if current_step >= 1:
		world.set_param(&"foam_edge_distance", value)
		update_code(_foam_code())


func _on_crest_changed(value: float) -> void:
	_crest = value
	if current_step >= 2:
		world.set_param(&"foam_crest_gain", value)
		update_code(_foam_code())


func _foam_code() -> String:
	return ("foam_edge_distance = %.2f\n" % _edge
			+ "foam_crest_gain    = %.2f\n" % _crest
			+ "foam = max(엣지, 크레스트);")
