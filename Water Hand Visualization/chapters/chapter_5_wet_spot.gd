extends WaterChapter
## 챕터 5 — 젖은 자국. 여덟 줄짜리 셰이더의 핵심은
## "마름 = 알파 페이드가 아니라 노이즈 침식 증가".

const STEPS: Array[Dictionary] = [
	{
		"title": "얼룩 만들고 왼→오로 번지기",
		"body": """형태는 또 sin(UV.x·PI)×sin(UV.y·PI)다.
progress_mask는 인자를 [b]큰 값→작은 값[/b]으로 뒤집은
smoothstep — 왼쪽부터 오른쪽으로 번져나간다.""",
		"chips": [{"icon": "shader", "text": "wet_spot.gdshader"}],
		"try": "progress를 훑으면 → 팔이 지나간 방향으로 번진다",
	},
	{
		"title": "마름 = 침식 증가",
		"body": """mix_voronoi는 알파에서 [b]빼는 항[/b]의 계수다.
페이드 대신 이 값을 올리면 노이즈가 자국을 갉아
[b]얼룩덜룩 조각조각 끊기며[/b] 사라진다.""",
		"chips": [{"icon": "shader", "text": "mix_voronoi"}],
		"try": "1.0까지 올리면 → 마르는 물자국 그대로다",
	},
	{
		"title": "3트랙 타임라인",
		"body": """0~0.2초 mix_blend 0→1 (자국 생성),
1.5~1.6초 progress 0.3→1 (확 번짐),
2~3초 blend 빠지며 [b]voronoi 0.6→1 (침식 증발)[/b].""",
		"chips": [{"icon": "node3d", "text": "WetPlayer"}],
		"try": "2.5초 근처 → 흐려짐이 아니라 조각남이 보인다",
	},
]

var _progress := 0.5
var _blend := 1.0
var _voronoi := 0.3
var _scrub_t := 2.5


func _ready() -> void:
	world.solo(false, false, false, true, false)
	world.camera_rig.position = Vector3(-0.5, 0.3, 0.0)
	world.camera_rig.set_view(0.15, -1.1, 8.5)


func get_chapter_title() -> String:
	return "젖은 자국 — 증발을 노이즈로"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.wet_stop()
	world.set_wet_param("debug_mode", 0)
	match index:
		0:
			world.set_wet_param("mix_blend", _blend)
			world.set_wet_param("mix_voronoi", 0.3)
			world.set_wet_param("progress", _progress)
			update_code(_progress_code())
		1:
			world.set_wet_param("mix_blend", 1.0)
			world.set_wet_param("progress", 1.0)
			world.set_wet_param("mix_voronoi", _voronoi)
			update_code(_voronoi_code())
		2:
			world.wet_scrub(_scrub_t)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "progress (번짐)", 0.0, 1.0, _progress, _on_progress_changed, [0])
	add_slider(parent, "mix_blend (농도)", 0.0, 1.0, _blend, _on_blend_changed, [0])
	add_slider(parent, "mix_voronoi (침식)", 0.0, 1.0, _voronoi, _on_voronoi_changed, [1])
	var scrub := add_slider(parent, "타임라인 (초)", 0.0, 3.0, _scrub_t, _on_scrub_changed, [2])
	scrub.step = 0.01


func _on_progress_changed(value: float) -> void:
	_progress = value
	world.set_wet_param("progress", value)
	if current_step == 0:
		update_code(_progress_code())


func _on_blend_changed(value: float) -> void:
	_blend = value
	world.set_wet_param("mix_blend", value)


func _on_voronoi_changed(value: float) -> void:
	_voronoi = value
	world.set_wet_param("mix_voronoi", value)
	if current_step == 1:
		update_code(_voronoi_code())


func _on_scrub_changed(value: float) -> void:
	_scrub_t = value
	if current_step == 2:
		world.wet_scrub(value)


func _progress_code() -> String:
	return ("mask = smoothstep(%.2f + 0.2,\n" % _progress
			+ "    %.2f - 0.2, UV.x); // 반전 훑기" % _progress)


func _voronoi_code() -> String:
	return ("ALPHA = ...(dist\n"
			+ "    - voronoi * %.2f)...; ← 슬라이더" % _voronoi)
