extends WaterChapter
## 챕터 4 — 물보라와 물방울. 축별 스케일 분리가 왕관 실루엣을 만들고,
## 좁은 밴드 침식이 뜯기는 소멸을 만든다.

const STEPS: Array[Dictionary] = [
	{
		"title": "축별로 따로 키프레임하기",
		"body": """X/Z는 0.25→5.5로 [b]계속 퍼지기만[/b] 하고,
Y는 0.25→4.0→[b]0으로 주저앉는다[/b].
솟았다 옆으로 무너지는 왕관은 이 분리에서 나온다.""",
		"chips": [{"icon": "node3d", "text": "SplashPlayer"}],
		"code": """scale.x/z: 0.25 ──────→ 5.5 (0.8s)
scale.y  : 0.25 → 4.0 → 0.0""",
		"try": "0.4초 근처 → 세로로 가장 높이 솟은 순간",
	},
	{
		"title": "좁은 밴드로 뜯어내기",
		"body": """밴드 폭이 [b]0.02[/b] — 페이드가 아니라 날카로운 침식.
UV.y를 sin으로 휘어 샘플 좌표를 왜곡하면
둘레를 따라 높이가 들쭉날쭉해진다.""",
		"chips": [
			{"icon": "texture", "text": "splash_mask.png"},
			{"icon": "shader", "text": "splash.gdshader"},
		],
		"try": "왜곡을 0으로 → 가장자리가 밋밋해진다",
	},
	{
		"title": "포말은 mix가 아니라 덧셈",
		"body": """파란색에 1을 [b]더하면[/b] 채널이 넘쳐 흰색이 되고
원래 색조가 넘치지 않은 채널에 남는다.
밝은 부분이 하얗게 날아가는 물 재질의 요령.""",
		"chips": [{"icon": "shader", "text": "foam_mask"}],
		"code": "ALBEDO = base_color + foam_mask;",
		"try": "포말을 끄면 → 아랫단 흰 띠가 사라진다",
	},
	{
		"title": "물방울 두 종과 반짝임",
		"body": """큰 방울은 align 3 — [b]날아가는 방향으로 눕고[/b],
작은 방울은 align 1 — 방향 없는 점.
INSTANCE_ID를 sin 위상으로 써 제각각 반짝인다.""",
		"chips": [
			{"icon": "node3d", "text": "transform_align 3 / 1"},
			{"icon": "shader", "text": "INSTANCE_ID"},
		],
		"code": """EMISSION += smoothstep(0., .01,
    -sin(id * 0.2 + TIME * 10.0));""",
		"try": "재생 → 방울마다 다른 순간에 번쩍인다",
	},
]

var _scrub_t := 0.4
var _progress := 0.45
var _bend := 0.3
var _mask_debug := false
var _foam := true


func _ready() -> void:
	world.solo(false, false, true, false, false)
	world.hand_splash.visible = false
	world.camera_rig.position = Vector3(3.0, 1.5, 0.0)
	world.camera_rig.set_view(0.5, -0.25, 8.0)


func get_chapter_title() -> String:
	return "물보라 — 왕관과 침식"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	for entry: Array in [
			["progress", _progress], ["uv_bend", _bend],
			["foam_enabled", 1.0], ["debug_mode", 0]]:
		world.set_splash_param(entry[0] as String, entry[1])
	match index:
		0:
			world.splash_scrub(_scrub_t)
		1:
			world.splash_pose_static()
			world.set_splash_param("debug_mode", 1 if _mask_debug else 0)
			update_code(_progress_code())
		2:
			world.splash_pose_static()
			world.set_splash_param("progress", 0.3)
			world.set_splash_param("foam_enabled", 1.0 if _foam else 0.0)
		3:
			world.splash_pose_static()
			world.replay_droplets()


func build_panel(parent: VBoxContainer) -> void:
	var scrub := add_slider(parent, "타임라인 (초)", 0.0, 1.5, _scrub_t, _on_scrub_changed, [0])
	scrub.step = 0.01
	add_slider(parent, "progress (침식)", 0.1, 1.0, _progress, _on_progress_changed, [1])
	add_slider(parent, "UV 왜곡 (uv_bend)", 0.0, 0.6, _bend, _on_bend_changed, [1])
	add_toggle(parent, "마스크 텍스처 보기", _mask_debug, _on_mask_toggled, [1])
	add_toggle(parent, "포말", _foam, _on_foam_toggled, [2])

	var replay := Button.new()
	replay.text = "물방울 재생"
	replay.pressed.connect(func() -> void: world.replay_droplets())
	parent.add_child(replay)
	bind_steps([replay], [3])


func _on_scrub_changed(value: float) -> void:
	_scrub_t = value
	if current_step == 0:
		world.splash_scrub(value)


func _on_progress_changed(value: float) -> void:
	_progress = value
	world.set_splash_param("progress", value)
	if current_step == 1:
		update_code(_progress_code())


func _on_bend_changed(value: float) -> void:
	_bend = value
	world.set_splash_param("uv_bend", value)


func _on_mask_toggled(pressed: bool) -> void:
	_mask_debug = pressed
	if current_step == 1:
		world.set_splash_param("debug_mode", 1 if pressed else 0)


func _on_foam_toggled(pressed: bool) -> void:
	_foam = pressed
	if current_step == 2:
		world.set_splash_param("foam_enabled", 1.0 if pressed else 0.0)


func _progress_code() -> String:
	return ("ALPHA = smoothstep(%.2f, %.2f,\n" % [_progress, _progress + 0.02]
			+ "    mask); // 밴드 폭 0.02 ← 슬라이더")
