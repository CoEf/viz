extends FurChapter
## 챕터 0 — 완성본과 지도. 이 저장소에서 파티클도 디졸브도 없는 유일한 이펙트.

const STEPS: Array[Dictionary] = [
	{
		"title": "걷는 고양이의 털 보기",
		"body": """파티클도, 디졸브도, AnimationPlayer 트랙도 없다.
런타임에 메시를 [b]15겹으로 구워[/b] 정점 셰이더로 밀어내는
고전적인 셸(shell) 퍼다.""",
		"chips": [
			{"icon": "script", "text": "fur_builder.gd"},
			{"icon": "shader", "text": "fur.gdshader"},
		],
		"try": "드래그로 실루엣 보기 — 뿌리 두껍고 끝 뾰족하다",
	},
	{
		"title": "다섯 챕터로 나눠 보기",
		"body": """①셸 굽기 ②정점 밀어내기 — 형태.
③테이퍼와 빗질 — 털이 되는 수학.
④light() 직접 짜기 ⑤곁가지 — 깜빡임·격자.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 5"}],
	},
]


func get_chapter_title() -> String:
	return "개요 — 메시 15겹의 털"


func get_steps() -> Array[Dictionary]:
	return STEPS
