extends GrassChapter
## 챕터 0 — 열 개를 나란히 놓고, 비교할 축을 소개한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "열 개를 같은 조건에 놓기",
		"body": """godotshaders.com의 잔디 셰이더 [b]10개[/b]다.
조명·지면·노출·산포 시드가 전부 같다.
그래서 패치 사이의 차이는 [b]전부 셰이더 차이[/b]다.""",
		"chips": [{"icon": "script", "text": "shader_catalog.gd"}],
		"try": "드래그로 회전 · 휠로 줌 — 이름표는 저자",
	},
	{
		"title": "비교할 네 가지 축",
		"body": """열 개를 하나씩 훑는 대신, [b]갈리는 지점[/b]을 본다.

[b]기하[/b] — 잎을 무엇으로 놓는가 · 챕터 1
[b]바람[/b] — 무엇을 흔드는가 · 챕터 2
[b]밀림[/b] — 캐릭터 위치를 어떻게 아는가 · 챕터 3
[b]알파[/b] — 잎 모양을 어떻게 오리는가 · 챕터 4

마지막 챕터는 셰이더가 아니라, 이 10개를 4.7로 옮기며
반복해서 걸린 것들이다.""",
		"chips": [{"icon": "setting", "text": "README.md"}],
		"try": "아래 '다음 챕터'로 축별 비교 시작",
	},
]


func get_chapter_title() -> String:
	return "열 개 나란히 보기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(_index: int) -> void:
	world.show_patches([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	world.camera_rig.position = Vector3(0.0, 0.0, 0.0)
	world.camera_rig.set_view(0.0, -0.50, 74.0)
