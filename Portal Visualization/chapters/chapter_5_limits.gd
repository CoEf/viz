extends PortalChapter
## 챕터 5 — 한계와 수리. FOV 어긋남, 매 프레임 3회 렌더링, 미구현 순간이동.
## "뜯어보고 남은 것"이 실전에서는 제일 값지다.

const STEPS: Array[Dictionary] = [
	{
		"title": "FOV까지 복사해야 한다",
		"body": """원본은 트랜스폼만 복사한다 — 메인 60° vs 서브 75°.
SCREEN_UV 정합은 [b]두 카메라의 투영이 같다[/b]는 전제라
FOV가 다르면 포탈 경계에서 배율이 어긋난다.""",
		"chips": [{"icon": "script", "text": "copy_projection"}],
		"code": """local_camera.fov = world_camera.fov
local_camera.near = world_camera.near""",
		"try": "수리를 켜면 → 경계의 배율 차이가 사라진다",
	},
	{
		"title": "매 프레임 세 번 렌더링",
		"body": """포탈 둘 다 UPDATE_ALWAYS —
메인 + 서브뷰포트 2개를 [b]매 프레임 전부 그린다[/b].
안 보이면 끄고, 멀면 해상도를 낮추는 게 다음 단계.""",
		"chips": [{"icon": "setting", "text": "render_target_update_mode"}],
		"try": "B 갱신을 끄면 → A 속 그림이 얼어붙는다",
	},
	{
		"title": "순간이동은 미구현이다",
		"body": """루트가 Area3D고 콜리전도 붙어 있지만
[b]시그널이 하나도 연결돼 있지 않다[/b].
시각적 포탈까지 — 통과는 자리만 잡아 둔 상태.""",
		"chips": [{"icon": "node3d", "text": "Area3D + BoxShape3D"}],
		"code": """# body_entered → 없음
# 정석: 근평면을 포탈 평면에 맞추는
# oblique clipping도 다음 단계""",
	},
]

var _fixed := false
var _b_updating := true


func _ready() -> void:
	world.frame_portal()


func get_chapter_title() -> String:
	return "한계와 수리 — 남은 것"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_b_viewport_updating(true)
	world.set_copy_projection(false)
	world.set_main_camera_fov(75.0)
	match index:
		0:
			# 원본 상황 재현: 메인 카메라만 60° (turner의 fov)
			world.set_main_camera_fov(60.0)
			world.set_copy_projection(_fixed)
		1:
			world.set_b_viewport_updating(_b_updating)


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "투영 파라미터 복사 (수리)", _fixed, _on_fix_toggled, [0])
	add_toggle(parent, "B 서브뷰포트 갱신", _b_updating, _on_updating_toggled, [1])


func _on_fix_toggled(pressed: bool) -> void:
	_fixed = pressed
	if current_step == 0:
		world.set_copy_projection(pressed)


func _on_updating_toggled(pressed: bool) -> void:
	_b_updating = pressed
	if current_step == 1:
		world.set_b_viewport_updating(pressed)
