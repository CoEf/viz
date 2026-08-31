extends PortalChapter
## 챕터 0 — 완성본과 지도. 앞의 이펙트들이 전부 눈속임이었다면,
## 포탈 너머는 실제로 렌더링된 다른 공간이다.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 포탈 보기",
		"body": """포탈 너머 풍경은 그린 것도 캡처한 것도 아니다.
[b]카메라를 하나 더 두고 실제로 렌더링한[/b] 결과다.
드래그해 보면 시차까지 정확히 맞는다.""",
		"chips": [
			{"icon": "node3d", "text": "SubViewport + Camera3D"},
			{"icon": "shader", "text": "portal.gdshader"},
		],
		"try": "드래그로 좌우 이동 → 너머의 마네킹에 시차가 생긴다",
	},
	{
		"title": "다섯 챕터로 나눠 보기",
		"body": """①두 개의 세계 ②포탈 카메라 행렬 — 구조.
③SCREEN_UV 창문 ④테두리 링 3겹 — 그림.
⑤한계와 수리 — FOV·비용·미구현.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 5"}],
	},
]


func _ready() -> void:
	world.frame_portal()


func get_chapter_title() -> String:
	return "개요 — 진짜로 렌더링하는 포탈"


func get_steps() -> Array[Dictionary]:
	return STEPS
