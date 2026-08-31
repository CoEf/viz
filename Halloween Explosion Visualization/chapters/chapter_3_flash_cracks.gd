extends HalloweenChapter
## 챕터 3 — 섬광과 균열. 0~0.6초를 책임지는 짧고 밝은 요소 둘.
## 공통점: 텍스처 한 장의 두 채널에 "무늬"와 "실루엣"을 나눠 담는다.

const STEPS: Array[Dictionary] = [
	{
		"title": "Y축 고정 빌보드로 세우기",
		"body": """파이어볼 파티클은 카메라를 통째로 향했다.
섬광은 [b]Y축을 월드 업에 고정[/b]하고 X/Z만 돌린다.
땅에서 솟는 것은 위에서 봐도 누우면 안 된다.""",
		"chips": [
			{"icon": "node3d", "text": "Flash"},
			{"icon": "shader", "text": "flash.gdshader vertex()"},
		],
		"code": """// Y열이 카메라가 아니라 월드 업
vec4(0.0, 1.0, 0.0, 0.0)""",
		"try": "위에서 내려다보기 → 섬광이 눕지 않는다",
	},
	{
		"title": "한 장에 무늬와 실루엣 담기",
		"body": """아틀라스의 [b].r은 sin의 위상[/b](줄무늬),
[b].g는 형태 마스크[/b](실루엣).
progress가 주파수와 노출 문턱을 동시에 흔든다.""",
		"chips": [{"icon": "texture", "text": "flash_shape_atlas.png"}],
		"try": "offset을 올리면 → 줄무늬가 바깥으로 쓸려 나간다",
	},
	{
		"title": "균열 — 거리장을 훑는 빛",
		"body": """.r은 균열의 [b]거리장[/b], .g는 모양 마스크.
progress가 .r을 훑으며 어디까지 빛날지 정하고,
.g가 알파를 잡아 [b]모양은 그대로, 빛만 번진다[/b].""",
		"chips": [
			{"icon": "texture", "text": "ground_cracks.png"},
			{"icon": "shader", "text": "ground_cracks.gdshader"},
		],
		"code": """s = smoothstep(progress - 0.1,
    progress + 0.1, cracks.x)""",
		"try": "progress 훑기 → 0.4초의 절정이 이 슬라이더다",
	},
]

var _progress := 0.9 # 타임라인상 0.5→1.0으로 갈수록 밝다 — 0.5는 어두운 시작 상태
var _offset := 0.0
var _cracks_progress := 0.8
var _flash_debug := 0
var _cracks_debug := 0


func _ready() -> void:
	world.make_lab()


func get_chapter_title() -> String:
	return "섬광과 균열 — 2채널 텍스처 둘"


func get_steps() -> Array[Dictionary]:
	return STEPS


func _apply_flash() -> void:
	world.lab_stop()
	world.lab_solo(["Flash"])
	for entry: Array in [
			["alpha", 1.0], ["intensity", 2.0], ["progress", _progress],
			["offset", _offset], ["debug_mode", 0]]:
		world.lab_set_param("Flash", entry[0] as String, entry[1])
	world.camera_rig.position = Vector3(0.0, 2.8, 0.0)
	world.camera_rig.set_view(0.25, -0.12, 10.0)


func apply_step(index: int) -> void:
	match index:
		0:
			_apply_flash()
		1:
			_apply_flash()
			world.lab_set_param("Flash", "debug_mode", _flash_debug)
			update_code(_flash_code())
		2:
			world.lab_stop()
			world.lab_solo(["GroundCracks"])
			for entry: Array in [
					["alpha", 1.0], ["intensity", 3.0],
					["progress", _cracks_progress], ["debug_mode", _cracks_debug]]:
				world.lab_set_param("GroundCracks", entry[0] as String, entry[1])
			world.camera_rig.position = Vector3(0.0, 0.4, 0.0)
			world.camera_rig.set_view(0.35, -0.85, 7.0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "progress", 0.0, 1.0, _progress, _on_progress_changed, [1])
	add_slider(parent, "offset (무늬 밀기)", 0.0, 10.0, _offset, _on_offset_changed, [1])
	add_toggle(parent, ".r 무늬 위상 보기", false, _on_flash_r_toggled, [1])
	add_toggle(parent, ".g 형태 마스크 보기", false, _on_flash_g_toggled, [1])
	add_slider(parent, "균열 progress", 0.0, 1.0, _cracks_progress, _on_cracks_changed, [2])
	add_toggle(parent, ".r 거리장 보기", false, _on_cracks_r_toggled, [2])


func _on_progress_changed(value: float) -> void:
	_progress = value
	world.lab_set_param("Flash", "progress", value)
	if current_step == 1:
		update_code(_flash_code())


func _on_offset_changed(value: float) -> void:
	_offset = value
	world.lab_set_param("Flash", "offset", value)
	if current_step == 1:
		update_code(_flash_code())


func _on_flash_r_toggled(pressed: bool) -> void:
	_flash_debug = 1 if pressed else 0
	if current_step == 1:
		world.lab_set_param("Flash", "debug_mode", _flash_debug)


func _on_flash_g_toggled(pressed: bool) -> void:
	_flash_debug = 2 if pressed else 0
	if current_step == 1:
		world.lab_set_param("Flash", "debug_mode", _flash_debug)


func _on_cracks_changed(value: float) -> void:
	_cracks_progress = value
	world.lab_set_param("GroundCracks", "progress", value)


func _on_cracks_r_toggled(pressed: bool) -> void:
	_cracks_debug = 1 if pressed else 0
	if current_step == 2:
		world.lab_set_param("GroundCracks", "debug_mode", _cracks_debug)


func _flash_code() -> String:
	return ("dist = (sin(flash.r * %.2f * 10.0\n" % _progress
			+ "    + %.1f) + 1.0) * 0.5; ← 슬라이더" % _offset)
