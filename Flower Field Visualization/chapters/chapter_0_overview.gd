extends FieldChapter
## 챕터 0 — 완성본과 지도. 자연스러움은 셰이더가 아니라 배치 알고리즘에서 나온다.

const STEPS: Array[Dictionary] = [
	{
		"title": "꽃밭 보기",
		"body": """900칸 격자에서 살아남은 풀과 꽃이 원형 섬을 이루고,
바람에 흔들리고, 나비가 난다.
[b]자연스러움의 대부분은 배치 알고리즘[/b]에서 나온다.""",
		"chips": [
			{"icon": "script", "text": "flower_field.gd generate()"},
			{"icon": "node3d", "text": "MultiMeshInstance3D ×2"},
		],
		"try": "드래그로 돌아보라 — 무성한 곳과 성긴 곳이 있다",
	},
	{
		"title": "네 챕터로 나눠 보기",
		"body": """①지터 그리드 ②노이즈 크기 — 심기.
③바람 — 회전행렬 셰이더.
④나비 — turbulence와 날갯짓.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 4"}],
	},
]


func get_chapter_title() -> String:
	return "개요 — 심는 알고리즘"


func get_steps() -> Array[Dictionary]:
	return STEPS
