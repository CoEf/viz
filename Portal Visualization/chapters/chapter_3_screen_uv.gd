extends PortalChapter
## 챕터 3 — SCREEN_UV. 한 글자 차이가 포탈과 TV 화면을 가른다.

const STEPS: Array[Dictionary] = [
	{
		"title": "SCREEN_UV로 샘플링해야 창문이 된다",
		"body": """가상 카메라가 이미 "저쪽에서 보였을 그림"을 그려 놨다.
셰이더는 그걸 [b]화면의 같은 자리에[/b] 얹기만 한다.
UV로 붙이면 표면에 발린 [b]TV 화면[/b]이 된다.""",
		"chips": [{"icon": "shader", "text": "portal.gdshader"}],
		"code": """texture(viewport_sampler, SCREEN_UV)
// UV로 바꾸면 벽걸이 모니터""",
		"try": "TV 모드로 → 드래그하면 그림이 표면에 붙어 돈다",
	},
	{
		"title": "어둡게 눌러야 구멍이 된다",
		"body": """저쪽 풍경을 그대로 보여주면 그냥 뚫린 벽처럼 읽힌다.
[b]0.58을 곱해 어둡게[/b] 눌러야 "다른 장소"가 된다.
원형 컷은 step + 알파 시저 — 늘 나온 습관.""",
		"chips": [{"icon": "shader", "text": "ALPHA_SCISSOR_THRESHOLD"}],
		"try": "1.0으로 올리면 → 구멍이 아니라 뚫린 벽이 된다",
	},
]

var _screen_uv := true
var _darken := 0.58


func _ready() -> void:
	world.frame_portal()
	world.camera_rig.set_view(0.35, -0.1, 4.5)


func get_chapter_title() -> String:
	return "SCREEN_UV — 창문과 TV의 차이"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_portal_param("use_screen_uv", 1.0)
	world.set_portal_param("darken", 0.58)
	match index:
		0:
			world.set_portal_param("use_screen_uv", 1.0 if _screen_uv else 0.0)
		1:
			world.set_portal_param("darken", _darken)
			update_code(_darken_code())


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "TV 모드 (UV 샘플링)", not _screen_uv, _on_tv_toggled, [0])
	add_slider(parent, "darken (원본 0.58)", 0.0, 1.0, _darken, _on_darken_changed, [1])


func _on_tv_toggled(pressed: bool) -> void:
	_screen_uv = not pressed
	if current_step == 0:
		world.set_portal_param("use_screen_uv", 1.0 if _screen_uv else 0.0)


func _on_darken_changed(value: float) -> void:
	_darken = value
	world.set_portal_param("darken", value)
	if current_step == 1:
		update_code(_darken_code())


func _darken_code() -> String:
	return "ALBEDO = viewport_texture * %.2f;\n// ← 슬라이더" % _darken
