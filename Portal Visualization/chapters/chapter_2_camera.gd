extends PortalChapter
## 챕터 2 — 포탈 카메라. "이쪽에 대한 상대 위치를 뒤집힌 저쪽에 재현한다"
## — 행렬 세 줄이 전부다.

const STEPS: Array[Dictionary] = [
	{
		"title": "상대 위치를 저쪽에 재현하기",
		"body": """오른쪽부터 읽는다: 월드→[b]이쪽 포탈 로컬[/b]로,
그걸 [b]뒤집힌 저쪽 포탈[/b] 기준으로 되돌린다.
메인 카메라의 상대 위치·자세가 B 기준으로 재현된다.""",
		"chips": [{"icon": "script", "text": "portal.gd"}],
		"code": """other.global_transform
    .scaled_local(-1, 1, -1)
  * global_transform.inverse()
  * world_camera.global_transform""",
		"try": "드래그 → 포탈 안 그림이 정확히 따라온다",
	},
	{
		"title": "왜 뒤집는가 — Y축 180°",
		"body": """행렬식이 (-1)·1·(-1) = 1 — 거울이 아니라 [b]회전[/b]이다.
포탈은 창문: A를 들여다보면 B에서 [b]내다보는[/b] 그림.
안 뒤집으면 방향이 어긋난 그림이 나온다.""",
		"chips": [{"icon": "script", "text": "scaled_local(-1, 1, -1)"}],
		"try": "뒤집기를 끄면 → 너머 풍경의 방향이 틀어진다",
	},
	{
		"title": "월드로 제어하면 top_level",
		"body": """가상 카메라는 매 프레임 [b]월드 트랜스폼을 통째로 대입[/b]받는다.
top_level을 켜면 부모(포탈) 트랜스폼을 무시해
역행렬 재계산도, 한 프레임 지연도 없다.""",
		"chips": [{"icon": "node3d", "text": "Camera3D top_level = true"}],
		"code": """local_camera.global_transform =
    get_other_side_transform(...)""",
	},
]

var _flip := true


func _ready() -> void:
	world.frame_portal()


func get_chapter_title() -> String:
	return "포탈 카메라 — 행렬 세 줄"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_flip(true if index != 1 else _flip)


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "scaled_local 뒤집기", _flip, _on_flip_toggled, [1])


func _on_flip_toggled(pressed: bool) -> void:
	_flip = pressed
	if current_step == 1:
		world.set_flip(pressed)
