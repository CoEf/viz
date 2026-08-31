extends FireworksChapter
## 챕터 0 — 완성본과 지도. 셰이더는 전부 20줄 미만 — 쇼를 만드는 건 스폰 로직이다.

const STEPS: Array[Dictionary] = [
	{
		"title": "불꽃놀이 쇼 보기",
		"body": """셰이더 셋은 전부 20줄 미만인데 화면은 꽉 찬다.
차이를 만드는 건 [b]언제 무엇을 몇 개 스폰하는가[/b] —
GDScript 쪽이다.""",
		"chips": [
			{"icon": "script", "text": "fireworks_preview.gd"},
			{"icon": "resource", "text": "probability_curve"},
		],
		"try": "10초쯤 지켜보라 — 잔잔함과 절정이 반복된다",
	},
	{
		"title": "네 챕터로 나눠 보기",
		"body": """①확률 커브 — 쇼의 리듬.
②로켓 — 트윈과 sin 하나.
③폭발 주입 ④다섯 줄 셰이더.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 4"}],
	},
]


func get_chapter_title() -> String:
	return "개요 — 셰이더 밖에서 결정되는 쇼"


func get_steps() -> Array[Dictionary]:
	return STEPS
