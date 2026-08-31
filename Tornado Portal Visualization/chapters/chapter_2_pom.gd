extends TornadoChapter
## 챕터 2 — POM. 시선 방향으로 UV를 파고들며 높이와 비교하는 루프가
## 평평한 쿼드에 깊이의 실루엣을 만든다.

const STEPS: Array[Dictionary] = [
	{
		"title": "시선을 따라 UV 파고들기",
		"body": """시선을 [b]탄젠트 공간[/b]으로 바꾼 뒤, 그 방향으로
UV를 조금씩 밀며 "내려온 깊이 vs 그 UV의 높이"를 비교.
[b]깊이가 높이를 넘는 순간[/b]이 시선이 부딪힌 지점이다.""",
		"chips": [{"icon": "shader", "text": "portal_effect.gdshader"}],
		"code": """while (current_depth < depth) {
    ofs -= delta;
    depth = get_depth(ofs); }""",
		"try": "비스듬히 보면 → 가장자리가 안쪽으로 밀린다",
	},
	{
		"title": "각도에 따라 층수 조절하기",
		"body": """정면(dot≈1)이면 16층, 비스듬하면 64층.
비스듬할수록 UV가 많이 밀려 [b]스텝이 더 필요하다[/b].
품질 손실 없이 비용을 깎는 보간.""",
		"chips": [{"icon": "shader", "text": "heightmap_min/max_layers"}],
		"try": "최소 층수를 1로 → 정면에서 계단이 진다",
	},
	{
		"title": "깊이 과장 손잡이",
		"body": """heightmap_scale이 UV를 미는 거리(P)의 배율이다.
클수록 깊게 파인 것처럼 보이지만
너무 크면 [b]가장자리가 찢어진다[/b].""",
		"chips": [{"icon": "shader", "text": "heightmap_scale"}],
		"try": "64까지 올리면 → 깊어지다가 왜곡이 보인다",
	},
	{
		"title": "시차는 실루엣에만 걸려 있다",
		"body": """POM이 민 UV는 [b]마스크에만[/b] 쓰인다.
화면 텍스처는 원래 SCREEN_UV 그대로 —
구멍 가장자리는 밀리지만 안의 내용은 시차가 없다.""",
		"chips": [{"icon": "shader", "text": "hint_screen_texture"}],
		"code": """float mask = get_depth(base_uv); // 시차 O
texture(screen, SCREEN_UV);      // 시차 X""",
		"try": "마스크 보기 → POM이 바꾸는 건 이 실루엣뿐",
	},
]

var _min_layers := 16.0
var _max_layers := 64.0
var _scale := 32.0
var _show_mask := false


func _ready() -> void:
	world.stop()
	world.solo(true, false, false, false)
	world.camera_rig.position = Vector3(0.0, 0.4, 0.0)
	world.camera_rig.set_view(0.5, -0.22, 4.5)


func get_chapter_title() -> String:
	return "POM — 평면에 깊이 파기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.stop()
	world.solo(true, false, false, false)
	world.reset_hole_params(1.0)
	world.set_hole_param("heightmap_min_layers", int(_min_layers))
	world.set_hole_param("heightmap_max_layers", int(_max_layers))
	world.set_hole_param("heightmap_scale", _scale)
	match index:
		1:
			update_code(_layers_code())
		2:
			update_code(_scale_code())
		3:
			world.set_hole_param("debug_mode", 2 if _show_mask else 0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "최소 층수 (정면)", 1.0, 32.0, _min_layers, _on_min_changed, [1])
	add_slider(parent, "최대 층수 (비스듬)", 2.0, 64.0, _max_layers, _on_max_changed, [1])
	add_slider(parent, "heightmap_scale", 0.0, 64.0, _scale, _on_scale_changed, [2])
	add_toggle(parent, "POM 마스크 보기", _show_mask, _on_mask_toggled, [3])


func _on_min_changed(value: float) -> void:
	_min_layers = roundf(value)
	world.set_hole_param("heightmap_min_layers", int(_min_layers))
	if current_step == 1:
		update_code(_layers_code())


func _on_max_changed(value: float) -> void:
	_max_layers = roundf(value)
	world.set_hole_param("heightmap_max_layers", int(_max_layers))
	if current_step == 1:
		update_code(_layers_code())


func _on_scale_changed(value: float) -> void:
	_scale = value
	world.set_hole_param("heightmap_scale", value)
	if current_step == 2:
		update_code(_scale_code())


func _on_mask_toggled(pressed: bool) -> void:
	_show_mask = pressed
	if current_step == 3:
		world.set_hole_param("debug_mode", 2 if pressed else 0)


func _layers_code() -> String:
	return ("num_layers = mix(%.0f., %.0f.,\n" % [_max_layers, _min_layers]
			+ "    abs(dot(FRONT, view_dir))); ← 슬라이더")


func _scale_code() -> String:
	return ("P = view_dir.xy * %.0f. * 0.01;\n" % _scale
			+ "// UV를 미는 거리 ← 슬라이더")
